#include "cpu/cpu.h"
#include "memory/pmem.h"
#include "include/mydpi.h"
#include "include/macro.h"
#include "include/autoconf.h"
#include "include/debug.h"
#define ANSI_FG_GREEN "\e[1;32m"
#define ANSI_FG_RED "\e[1;31m"
#define ANSI_NONE "\e[0m"
#define MAX_INST_TO_PRINT 10

TOP_NAME* dut=NULL;
VerilatedContext*contextp=NULL;
VerilatedVcdC* tfp=NULL;
NPC_state npc_state={NPC_RUNNING,0,FLASH_START};
CPU_state cpu_dut={{0},FLASH_START};
uint32_t cpu_pc=0,cpu_dnpc=0;
static char logbuf[128]={};
static bool g_print_step=false;
static char ftrace_buf[1024][128]={};
static int ftrace_cnt=0;
static int depth=0;
void get_cpu_state(CPU_state *cpu_dut){
    int i;
    for(i=0;i<32;i++){
        cpu_dut->gpr[i]=cpu_gpr(i);
    }
    cpu_dut->pc=cpu_pc;
}
static void trace_and_difftest(uint32_t pc){
    
    if(g_print_step){IFDEF(CONFIG_ITRACE,puts(logbuf));}
    IFDEF(CONFIG_DIFFTEST, difftest_step(pc, cpu_pc));

}
extern "C" void npc_trap(){
    difftest_skip_ref(); 
    npc_state.state=NPC_END;
    npc_state.halt_pc=cpu_pc;//?
    npc_state.halt_ret=cpu_gpr(10);
    printf("ret=%d\n",npc_state.halt_ret);
}
int is_exit_status_bad() {
    int good=(npc_state.state==NPC_END&&npc_state.halt_ret==0)||
        (npc_state.state==NPC_QUIT);
    return !good;
}

void single_cycle(){
    dut->clock=1;dut->eval();
    IFDEF(CONFIG_VCD_TRACE,
            if(contextp->time()<=300000){tfp->dump(contextp->time());}
            contextp->timeInc(1);)
    dut->clock=0;dut->eval();
    IFDEF(CONFIG_VCD_TRACE,
            if(contextp->time()<=300000){tfp->dump(contextp->time());}
            contextp->timeInc(1);)
}
void reset(int n){
    dut->reset=1;
    dut->clock=0;dut->eval();
    while(n-->0)single_cycle();
    dut->reset=0;
}
static void itrace_record(uint32_t pc,uint32_t inst){
#ifdef CONFIG_ITRACE
    char *p=logbuf;
    p+=snprintf(p,sizeof(logbuf),"0x%08x %08x",pc,inst);
    memset(p,' ',1);
    p+=1;
    void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
    disassemble(p,logbuf+sizeof(logbuf)-p,pc,(uint8_t *)(&inst),4);

#endif
}
static void ftrace_record(uint32_t pc,uint32_t dnpc,int is_return){
    int i;int index1=-1,index2=-1;
    char space[32];
    if(!is_return) depth++;
    int space_len=depth>31?31:depth;
    if(is_return) {depth--; if(depth<0) depth=0;}
    memset(space,' ',space_len);
    space[space_len]='\0';
    for(i=0;i<func_cnt;i++){
        if(pc>=func_list[i].low&&pc<=func_list[i].high){
            index1=i;break;
        }
    }
    for(i=0;i<func_cnt;i++){
        if(dnpc>=func_list[i].low&&dnpc<=func_list[i].high){
            index2=i;break;
        }
    }
    if(is_return){
        sprintf(ftrace_buf[ftrace_cnt],"0x%08x:%sret [%s] to [%s]",pc,space,index1>=0?func_list[index1].name:"???",index2>=0?func_list[index2].name:"???"); 
    }else{
        sprintf(ftrace_buf[ftrace_cnt],"0x%08x:%scall [%s@0x%08x], from [%s]",pc,space,index2>=0?func_list[index2].name:"???",dnpc,index1>=0?func_list[index1].name:"???");  
    }
    ftrace_cnt=(ftrace_cnt+1)%1024;
}
static void ftrace_call(uint32_t pc,uint32_t inst,uint32_t dnpc){
    int opcode=BITS(inst,6,0);
    int funct3=BITS(inst,14,12);
    int rd=BITS(inst,11,7);
    if(opcode==0b01101111){
       if(rd==1)ftrace_record(pc,dnpc,0); 
    }else if(opcode==0b01100111&&funct3==0){
        if(rd==1)ftrace_record(pc,dnpc,0);
        else if(BITS(inst,19,15)==1) ftrace_record(pc,dnpc,1);
    }

}

void ftrace_print(){
    int i;
    printf("print ftrace\n");
    for(i=0;i<ftrace_cnt;i++){
        printf("id:%s\n",ftrace_buf[i]);
    }
}
static void execute(uint64_t n){
    for(;n>0;n--){
        while(dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__IFU1__DOT__WBU_IFU_fire==0){
        single_cycle();
        if(npc_state.state!=NPC_RUNNING)return;
        }
        cpu_pc=dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__WBU1__DOT__pc_reg;
        cpu_dnpc=dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__IFU1__DOT__dnpc;
        uint32_t inst=dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__IDU1__DOT__inst_reg;
        IFDEF(CONFIG_FTRACE,ftrace_call(cpu_pc,inst,cpu_dnpc);)
        IFDEF(CONFIG_ITRACE,itrace_record(cpu_pc,inst);)

        int trap_ctrl=dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__WBU1__DOT__trap_ctrl_reg;
        int csr_addr=dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__WBU1__DOT__imm_reg&0xfff;
        if(trap_ctrl==1&&(csr_addr==0xf11||csr_addr==0xf12||csr_addr==0xb00||csr_addr==0xb80)){
            difftest_skip_ref();
        }
        single_cycle();
        uint32_t old_cpu_pc=cpu_pc;
        cpu_pc=dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu_idu_pc;
        if(npc_state.state!=NPC_RUNNING)return;
        get_cpu_state(&cpu_dut);
        trace_and_difftest(old_cpu_pc);
    }
}
void cpu_exec(uint64_t n){
    g_print_step=(n<MAX_INST_TO_PRINT);
    switch (npc_state.state) {
        case NPC_END:case NPC_QUIT:case NPC_ABORT:
            printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
            return;
        default:npc_state.state=NPC_RUNNING;
    }
    execute(n);
    switch(npc_state.state){
        case NPC_RUNNING:npc_state.state=NPC_STOP;break;
        case NPC_END:case NPC_ABORT: 
            Log("npc: %s at pc = 0x%08x \n%s\n",
                (npc_state.state==NPC_ABORT? ANSI_FG_RED "ABORT" ANSI_NONE:
                (npc_state.halt_ret==0?ANSI_FG_GREEN"HIT GOOD TRAP" ANSI_NONE:
                ANSI_FG_RED "HITBAD TRAP" ANSI_NONE)),
                npc_state.halt_pc,logbuf);
    }
}

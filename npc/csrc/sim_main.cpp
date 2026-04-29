#include<stdlib.h>
#include<assert.h>
//#include<Vysyx_bshifter.h>
#include<verilated.h>
#include"verilated_vcd_c.h"
#include<nvboard.h>
#include "pmem.h"
#define _MKSTR(s) #s
#define MKSTR(s) _MKSTR(s)
#include MKSTR(TOP_NAME.h)
#define USE_NVBOARD 1
#define ANSI_FG_GREEN "\e[1;32m"
#define ANSI_FG_RED "\e[1;31m"
#define ANSI_NONE "\e[0m"
static TOP_NAME* dut;
static VerilatedContext*contextp;
static VerilatedVcdC* tfp;
enum NPC_STATE{NPC_RUNNING,NPC_END
};
static struct{
    enum NPC_STATE state;
    int halt_ret;
}npc_state={NPC_RUNNING,0};

uint32_t pmem[MAX_LENGTH];

extern "C" void npc_trap(){
    npc_state.state=NPC_END;
    svScope scope=svGetScopeFromName("TOP.ysyx_26040117_top.Register1");
    if(scope){
        svSetScope(scope);
        npc_state.halt_ret=get_a0();
        printf("ret=%d\n",npc_state.halt_ret);
    }else{
        printf("get incorrect name\n");
    }
}
int is_exit_status_bad() {
    int good=(npc_state.state==NPC_END&&npc_state.halt_ret==0);
    return !good;
}
void nvboard_bind_all_pins(TOP_NAME*top);
void single_cycle(){
    dut->clk=0;dut->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
    dut->clk=1;dut->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
}
void single_cycle0(){
    dut->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
}
void reset(int n){
    dut->rst=1;
    while(n-->0)single_cycle();
    dut->rst=0;
}
int main(int argc,char**argv){
    FILE*fp;
    assert((fp=fopen(argv[1],"rb"))!=NULL);
    fseek(fp,0,SEEK_END);
    long fpsize=ftell(fp);
    fseek(fp,0,SEEK_SET);
    fread(pmem,1,fpsize,fp);
    contextp=new VerilatedContext;
    contextp->commandArgs(argc,argv);
    dut=new TOP_NAME(contextp);
    contextp->traceEverOn(true);
    tfp=new VerilatedVcdC;
    dut->trace(tfp,300);
    tfp->open("simx.vcd");
    int sim_time=300;
    //nvboard_bind_all_pins(dut);
    //nvboard_init();
    reset(10);
    int i=0;
    //while((USE_NVBOARD||!contextp->gotFinish()&&contextp->time()<sim_time)&&npc_state==1){
    while(npc_state.state==NPC_RUNNING){
        //nvboard_update();
        single_cycle();
    }
    if(npc_state.state==NPC_END){
        if(npc_state.halt_ret==0){
            printf(ANSI_FG_GREEN"HIT GOOD TRAP" ANSI_NONE "\n");
        }else{
            printf(ANSI_FG_RED "HIT BAD TRAP" ANSI_NONE "\n");
        }
    }
    tfp->close();
    fclose(fp);
    delete dut;
    delete contextp;
    delete tfp;
    return is_exit_status_bad();

}

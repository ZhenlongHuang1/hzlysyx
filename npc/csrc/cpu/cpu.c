#include "cpu/cpu.h"
#include "include/mydpi.h"

#define ANSI_FG_GREEN "\e[1;32m"
#define ANSI_FG_RED "\e[1;31m"
#define ANSI_NONE "\e[0m"

TOP_NAME* dut;
VerilatedContext*contextp;
//VerilatedVcdC* tfp;
NPC_state npc_state={NPC_RUNNING,0};

extern "C" int get_a0();
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
    int good=(npc_state.state==NPC_END&&npc_state.halt_ret==0)||
        (npc_state.state==NPC_QUIT);
    return !good;
}

void single_cycle(){
    dut->clk=0;dut->eval();
    //tfp->dump(contextp->time());
    //contextp->timeInc(1);
    dut->clk=1;dut->eval();
    //tfp->dump(contextp->time());
    //contextp->timeInc(1);
}
void reset(int n){
    dut->rst=1;
    while(n-->0)single_cycle();
    dut->rst=0;
}
static void execute(uint64_t n){
    for(;n>0;n--){
        single_cycle();
        if(npc_state.state!=NPC_RUNNING)break;
    }
}
void cpu_exec(uint64_t n){
    switch (npc_state.state) {
        case NPC_END:case NPC_QUIT:
            printf("Program execution has ended. To restart the program, exit NEMU and run again.\n");
            return;
        default:npc_state.state=NPC_RUNNING;
    }
    execute(n);
    switch(npc_state.state){
        case NPC_RUNNING:npc_state.state=NPC_STOP;break;
        case NPC_END: 
            if(npc_state.halt_ret==0){
                printf(ANSI_FG_GREEN"HIT GOOD TRAP" ANSI_NONE "\n");
            }else{
                printf(ANSI_FG_RED "HITBAD TRAP" ANSI_NONE "\n");
            }

    }
}

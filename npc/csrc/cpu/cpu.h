#ifndef __CPU_H__
#define __CPU_H__
#include<verilated.h>
#include"verilated_vcd_c.h"
#define _MKSTR(s) #s
#define MKSTR(s) _MKSTR(s)
#include MKSTR(TOP_NAME.h)
extern TOP_NAME* dut;
extern VerilatedContext*contextp; 
extern VerilatedVcdC* tfp;
enum NPC_STATE{NPC_RUNNING,NPC_END,NPC_STOP,NPC_QUIT};
typedef struct{
    enum NPC_STATE state;
    int halt_ret;
}NPC_state;
extern NPC_state npc_state;

extern "C" void npc_trap();
int is_exit_status_bad();
void reset(int n);
void cpu_exec(uint64_t n); 

#endif

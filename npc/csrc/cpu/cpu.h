#ifndef __CPU_H__
#define __CPU_H__
#include<verilated.h>
#include"verilated_vcd_c.h"
#include "include/macro.h"
#define _MKSTR(s) #s
#define MKSTR(s) _MKSTR(s)
#include MKSTR(TOP_NAME.h)
#include MKSTR(concat(TOP_NAME,___024root.h))
extern TOP_NAME* dut;
extern VerilatedContext*contextp; 
extern VerilatedVcdC* tfp;

#define cpu_pc dut->rootp->ysyx_26040117_top__DOT__pc
#define cpu_gpr(i) dut->rootp->ysyx_26040117_top__DOT__Register1__DOT__rf[i]

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

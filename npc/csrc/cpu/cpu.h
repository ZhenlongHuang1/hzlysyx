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

//#define cpu_pc dut->rootp->ysyx_26040117_top__DOT__pc
#define cpu_gpr(i) dut->rootp->ysyx_26040117_top__DOT__Register1__DOT__rf[i]
//#define cpu_dnpc dut->rootp->ysyx_26040117_top__DOT__WBU1__DOT__dnpc
extern uint32_t cpu_pc,cpu_dnpc;
enum NPC_STATE{NPC_RUNNING,NPC_END,NPC_STOP,NPC_QUIT,NPC_ABORT};
typedef struct{
    enum NPC_STATE state;
    int halt_ret;
    uint32_t halt_pc;
}NPC_state;
extern NPC_state npc_state;

typedef struct {           
    uint32_t gpr[32];
    uint32_t pc;
}CPU_state;
extern CPU_state cpu_dut;
void get_cpu_state(CPU_state *cpu_dut);
#define cpu cpu_dut
void difftest_skip_ref(int skip_ref);
void init_difftest(const char *ref_so_file, long img_size);
void difftest_step(uint32_t pc, uint32_t npc);
#define MAX_FUNC_CNT 1024
typedef struct{
    char name[32];
    uint32_t low;
    uint32_t high;
}Func_list;
extern Func_list func_list[MAX_FUNC_CNT];
extern int func_cnt;


extern "C" void npc_trap();
int is_exit_status_bad();
void reset(int n);
void cpu_exec(uint64_t n); 
void ftrace_print();
#endif

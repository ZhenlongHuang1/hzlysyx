#include "isa/reg.h"
#include "include/macro.h"
#include "cpu/cpu.h"
#include MKSTR(concat(TOP_NAME,___024root.h))
const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};
void isa_reg_display() {
    int i;
    for(i=0;i<32;i++){
        printf("%-4s 0x%08X\n",regs[i],dut->rootp->ysyx_26040117_top__DOT__Register1__DOT__rf[i]);
    }
    printf("pc   0x%08X\n",dut->rootp->ysyx_26040117_top__DOT__pc);
}


#include<stdlib.h>
#include<assert.h>
//#include<Vysyx_bshifter.h>
#include<verilated.h>
#include"verilated_vcd_c.h"
#include<nvboard.h>
#include "svdpi.h"
#include "Vysyx_26040117_top__Dpi.h"
#define _MKSTR(s) #s
#define MKSTR(s) _MKSTR(s)
#include MKSTR(TOP_NAME.h)
#define USE_NVBOARD 0
static TOP_NAME* dut;
static VerilatedContext*contextp;
static VerilatedVcdC* tfp;
extern "C" void npc_trap(){
    printf("\ntest over\n");
    exit(0);
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
//uint32_t pmem[36]={0x01400513,0x010000e7,0x00c000e7,0x00c00067,0x00a50513,0x00008067};
uint32_t pmem[36]={0x01400513,0x014000e7,0x00c000e7,0x00c00067,0x00100073,0xFF750513,0xFF750513,0xFF750513,0x00008067};
uint32_t pmem_read(uint32_t pc){
    
    return pmem[pc/4];
}
int main(int argc,char**argv){
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
    while(USE_NVBOARD||!contextp->gotFinish()&&contextp->time()<sim_time){
        //nvboard_update();
        dut->inst = pmem_read(dut->pc);
        single_cycle();
    }
    delete dut;
    delete contextp;
    tfp->close();
    delete tfp;
    return 0;

}

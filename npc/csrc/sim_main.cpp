#include<stdio.h>
#include<stdlib.h>
#include<assert.h>
//#include<Vysyx_bshifter.h>
#include<verilated.h>
#include"verilated_vcd_c.h"
#include<nvboard.h>
#define _MKSTR(s) #s
#define MKSTR(s) _MKSTR(s)
#include MKSTR(TOP_NAME.h)
#define USE_NVBOARD 1
static TOP_NAME* dut;
static VerilatedContext*contextp;
static VerilatedVcdC* tfp;
void nvboard_bind_all_pins(TOP_NAME*top);
void single_cycle(){
//    dut->clk=0;dut->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
//    dut->clk=1;dut->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
}
void single_cycle0(){
    dut->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
}
void reset(int n){
//    dut->rst=1;
    while(n-->0)single_cycle();
//    dut->rst=0;
}
int main(int argc,char**argv){
    contextp=new VerilatedContext;
    contextp->commandArgs(argc,argv);
    dut=new TOP_NAME(contextp);
    contextp->traceEverOn(true);
    tfp=new VerilatedVcdC;
    dut->trace(tfp,100);
    tfp->open("simx.vcd");
    int sim_time=100;
    nvboard_bind_all_pins(dut);
    nvboard_init();
//    reset(10);
    int i=0;
    while(USE_NVBOARD||!contextp->gotFinish()&&contextp->time()<sim_time){
        nvboard_update();
        single_cycle0();
    }
    delete dut;
    delete contextp;
    tfp->close();
    delete tfp;
    return 0;

}

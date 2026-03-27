#include<stdio.h>
#include<stdlib.h>
#include<assert.h>
#include<Vtop.h>
#include<verilated.h>
#include"verilated_vcd_c.h"
#include<nvboard.h>
static TOP_NAME* dut;
static VerilatedContext*contextp;
static VerilatedVcdC* tfp;
void nvboard_bind_all_pins(TOP_NAME*top);

int main(int argc,char**argv){
    contextp=new VerilatedContext;
    contextp->commandArgs(argc,argv);
    dut=new TOP_NAME(contextp);
    contextp->traceEverOn(true);
    tfp=new VerilatedVcdC;
    dut->trace(tfp,99);
    tfp->open("simx.vcd");
    int sim_time=9900000;
    nvboard_bind_all_pins(dut);
    nvboard_init();
    while(1||!contextp->gotFinish()&&contextp->time()<sim_time){
        nvboard_update();
        contextp->timeInc(1);
        dut->eval();
        //tfp->dump(contextp->time());
        //assert(dut->f==a^b);
    }
    delete dut;
    delete contextp;
    tfp->close();
    delete tfp;
    return 0;

}

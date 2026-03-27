#include<stdio.h>
#include<stdlib.h>
#include<assert.h>
#include<Vtop.h>
#include<verilated.h>
#include"verilated_vcd_c.h"
int main(int argc,char**argv){
    VerilatedContext*contextp=new VerilatedContext;
    contextp->commandArgs(argc,argv);
    Vtop *top=new Vtop(contextp);
    contextp->traceEverOn(true);
    VerilatedVcdC* tfp=new VerilatedVcdC;
    top->trace(tfp,99);
    tfp->open("simx.vcd");
    int sim_time=99;
    while(!contextp->gotFinish()&&contextp->time()<sim_time){
        int a=rand()&1;
        int b=rand()&1;
        top->a=a;
        top->b=b;
        contextp->timeInc(1);
        top->eval();
        tfp->dump(contextp->time());
        printf("a=%d,b=%d,g=%d\n",a,b,top->f);
        assert(top->f==a^b);
    }
    delete top;
    delete contextp;
    tfp->close();
    delete tfp;
    return 0;

}

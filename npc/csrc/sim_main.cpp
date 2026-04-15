#include <cstdint>
#include<stdlib.h>
#include<stdio.h>
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
#define USE_NVBOARD 1
#define MAX_LENGTH 16777216
static TOP_NAME* dut;
static VerilatedContext*contextp;
static VerilatedVcdC* tfp;
static int npc_state=1;
//uint32_t pmem[36]={0x01400513,0x010000e7,0x00c000e7,0x00c00067,0x00a50513,0x00008067};
//uint32_t pmem[36]={0x01400513,0x010000e7,0x00c000e7,0x00100073,0xFF750513,0xFF750513,0xFF750513,0x00008067};
uint32_t pmem[MAX_LENGTH];
extern "C" int pmem_read(int raddr){
    uint32_t index=(uint32_t)raddr;
    return pmem[index>>2];
}
extern "C" void pmem_write(int waddr, int wdata, char wmask) {
    uint32_t index=(uint32_t)waddr;
    int addr_shift=index%4;
    int wdata1,wdata2,mask;
    if(wmask==1){
        mask=0x000000ff;
    }else if(wmask==3){
        mask=0x0000ffff;
    }else{
        mask=0xffffffff;
    }
    wdata1=wdata&mask;
    wdata1=wdata1<<(addr_shift*8);
    wdata2=pmem[index>>2]&~(mask<<(addr_shift*8));
    pmem[index>>2]=wdata1|wdata2;
}
extern "C" void npc_trap(){
    printf("\ntest over\n");
//    exit(0);
    npc_state=0;
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
    char binname[]="resource/sum.bin";
    assert((fp=fopen(binname,"r"))!=NULL);
    fread(pmem,4,MAX_LENGTH,fp);
    //pmem[0x224/4]=0x00100073;//sum
    pmem[0x1218/4]=0x00100073;
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
    while((USE_NVBOARD||!contextp->gotFinish()&&contextp->time()<sim_time)&&npc_state==1){
        //nvboard_update();
        single_cycle();
    }
    tfp->close();
    fclose(fp);
    delete dut;
    delete contextp;
    delete tfp;
    return 0;

}

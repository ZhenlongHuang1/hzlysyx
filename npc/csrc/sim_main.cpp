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
enum NPC_STATE{NPC_RUNNING,NPC_END
};
static struct{
    enum NPC_STATE state;
    int halt_ret;
}npc_state={NPC_RUNNING,0};
//uint32_t pmem[36]={0x01400513,0x010000e7,0x00c000e7,0x00c00067,0x00a50513,0x00008067};
//uint32_t pmem[36]={0x01400513,0x010000e7,0x00c000e7,0x00100073,0xFF750513,0xFF750513,0xFF750513,0x00008067};
uint32_t pmem[MAX_LENGTH];
extern "C" int pmem_read(int raddr){
    uint32_t index=(uint32_t)raddr;
    if(index<0x80000000u){
        return 0;
    }else {
        index-=0x80000000u;
    }
    return pmem[index>>2];
}
extern "C" void pmem_write(int waddr, int wdata, char wmask) {
    uint32_t index=(uint32_t)waddr;
    if(index<0x80000000u){
        return ;
    }else {
        index-=0x80000000u;
    }
    int addr_shift=index%4;
    uint32_t wdata1,wdata2,mask;
    if(wmask==1){
        mask=0x000000ff;
    }else if(wmask==3){
        mask=0x0000ffff;
    }else{
        mask=0xffffffff;
    }
    wdata1=(uint32_t)wdata&mask;
    wdata1=wdata1<<(addr_shift*8);
    wdata2=pmem[index>>2]&~(mask<<(addr_shift*8));
    pmem[index>>2]=wdata1|wdata2;
}
extern "C" void npc_trap(){
    npc_state.state=NPC_END;
    svScope scope=svGetScopeFromName("TOP.ysyx_26040117_top.Register1");
    if(scope){
        svSetScope(scope);
        npc_state.halt_ret=get_a0();
    }else{
        printf("get incorrect name\n");
    }
}
int is_exit_status_bad() {
    int good=(npc_state.state==NPC_END&&npc_state.halt_ret==0);
    return !good;
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
    assert((fp=fopen(argv[1],"rb"))!=NULL);
    fseek(fp,0,SEEK_END);
    long fpsize=ftell(fp);
    fseek(fp,0,SEEK_SET);
    fread(pmem,1,fpsize,fp);
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
    //while((USE_NVBOARD||!contextp->gotFinish()&&contextp->time()<sim_time)&&npc_state==1){
    while((!contextp->gotFinish()&&contextp->time()<sim_time)&&npc_state.state==NPC_RUNNING){
        //nvboard_update();
        single_cycle();
    }
    if(npc_state.state==NPC_END){
        if(npc_state.halt_ret==0){
            printf("HIT GOOD TRAP\n");
        }else{
            printf("HIT BAD TRAP\n");
        }
    }
    tfp->close();
    fclose(fp);
    delete dut;
    delete contextp;
    delete tfp;
    return is_exit_status_bad();

}

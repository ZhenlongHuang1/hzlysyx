#include<stdlib.h>
#include<assert.h>
//#include<nvboard.h>
#include "cpu/cpu.h"
#include "monitor/sdb.h"
#include "memory/pmem.h"

#define USE_NVBOARD 1

void nvboard_bind_all_pins(TOP_NAME*top);
int main(int argc,char**argv){
    FILE*fp;
    fp=fopen(argv[1],"rb");
    assert(fp!=NULL);
    fseek(fp,0,SEEK_END);
    long fpsize=ftell(fp);
    fseek(fp,0,SEEK_SET);
    int ret=fread(pmem,1,fpsize,fp);
    assert(ret==fpsize);
    contextp=new VerilatedContext;
    contextp->commandArgs(argc,argv);
    dut=new TOP_NAME(contextp);
    //contextp->traceEverOn(true);
    //tfp=new VerilatedVcdC;
    //dut->trace(tfp,300);
    //tfp->open("simx.vcd");
    //int sim_time=300;
    //nvboard_bind_all_pins(dut);
    //nvboard_init();
    reset(10);
    int i=0;
    //while((USE_NVBOARD||!contextp->gotFinish()&&contextp->time()<sim_time)&&npc_state==1){
    sdb_main_loop();
    //nvboard_update();
    //tfp->close();
    fclose(fp);
    delete dut;
    delete contextp;
    //delete tfp;
    return is_exit_status_bad();

}

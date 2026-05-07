#include<stdio.h>
#include<assert.h>
#include "include/macro.h"
#include "memory/pmem.h"
#include "cpu/cpu.h"

void init_disasm();
void init_monitor(int argc,char*argv[]){
    //read pmem of IMG file
    FILE*fp;
    fp=fopen(argv[1],"rb");
    assert(fp!=NULL);
    fseek(fp,0,SEEK_END);
    long fpsize=ftell(fp);
    fseek(fp,0,SEEK_SET);
    int ret=fread(pmem,1,fpsize,fp);
    fclose(fp);
    assert(ret==fpsize);
    //initial verilator
    contextp=new VerilatedContext;
    contextp->commandArgs(argc,argv);
    dut=new TOP_NAME(contextp);
    //reset
    reset(10);

    IFDEF(CONFIG_ITRACE,init_disasm());
}
void free_monitor(){
    delete dut;
    delete contextp;

}

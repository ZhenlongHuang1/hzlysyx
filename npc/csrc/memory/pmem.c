#include<stdio.h>
#include "include/mydpi.h"
#include "include/debug.h"
#include "include/macro.h"
#include "memory/pmem.h"
#include "cpu/cpu.h"
#include "include/autoconf.h"
void difftest_skip_ref();
uint32_t pmrom[MAX_LENGTH]={0};

extern "C" void flash_read(int32_t addr, int32_t *data) {
    assert(0);
}
extern "C" void mrom_read(int32_t addr, int32_t *data){
    uint32_t raddr=(addr-PMEM_START)>>2;
    data[0]=pmrom[raddr];
    data[0]=0x00100073;
#ifdef CONFIG_MTRACE
    if(addr>=CONFIG_MTRACE_START&&addr<=CONFIG_MTRACE_END)
        Log("Read memory at addr=0x%08x,data=%08x",addr,data[0]);
#endif
}
static void pmem_write(uint32_t addr,uint32_t data,uint32_t mask){
    uint32_t addr_shift=addr%4;
    uint32_t raddr=(addr-PMEM_START)>>2;
    uint32_t wdata1=data<<(addr_shift*8);
    uint32_t wdata2=pmrom[raddr]&~(mask<<(addr_shift*8));
    pmrom[raddr]=wdata1|wdata2; 
#ifdef CONFIG_MTRACE
    if(addr>=CONFIG_MTRACE_START&&addr<=CONFIG_MTRACE_END)
        Log("Write memory at addr=0x%08x,data=%08x",addr,data);
#endif


}
uint64_t get_time(){
    static struct timeval tv;
    static uint64_t bool_time=0;
    if(bool_time==0){
        gettimeofday(&tv, NULL);
        bool_time=(uint64_t)tv.tv_sec * 1000000 + tv.tv_usec;
    }
    gettimeofday(&tv,NULL);
    uint64_t now=(uint64_t)tv.tv_sec * 1000000 + tv.tv_usec;

    return now-bool_time;
}
extern "C" uint32_t paddr_read(uint32_t raddr){
    static uint64_t us=0;
    uint32_t tmp;
    if(likely(in_pmrom(raddr))){mrom_read(raddr,(int32_t*)(&tmp));return tmp;}
    return 0;
}
extern "C" void paddr_write(uint32_t waddr, uint32_t wdata, char wmask) {
    uint32_t data,mask;
    if(wmask==1){
        mask=0x000000ff;
    }else if(wmask==3){
        mask=0x0000ffff;
    }else{
        mask=0xffffffff;
    }
    data=(uint32_t)wdata&mask;
    if(likely(in_pmrom(waddr))){pmem_write(waddr,data,mask);return ;}
}

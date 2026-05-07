#include<stdio.h>
#include "include/mydpi.h"
#include "include/debug.h"
#include "include/macro.h"
#include "memory/pmem.h"

uint32_t pmem[MAX_LENGTH];
static uint32_t pmem_read(uint32_t addr){
    addr=(addr-PMEM_START)>>2;
    return pmem[addr];
}
static void pmem_write(uint32_t addr,uint32_t data,uint32_t mask){
    uint32_t addr_shift=addr%4;
    addr=(addr-PMEM_START)>>2;
    uint32_t wdata1=data<<(addr_shift*8);
    uint32_t wdata2=pmem[addr]&~(mask<<(addr_shift*8));
    pmem[addr]=wdata1|wdata2; 
}
static uint64_t get_time(){
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
    if(likely(in_pmem(raddr)))return pmem_read(raddr);
    if(raddr>=RTC_ADDR&&raddr<=RTC_ADDR+4){
        if(raddr==RTC_ADDR+4){
            us=get_time();
            return us>>32;
        }else {
            return (uint32_t)us;
        }
    }
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
    if(likely(in_pmem(waddr))){pmem_write(waddr,data,mask);return ;}
    if(waddr==SERIAL_PORT){
        putc(data,stdout);
    }
}

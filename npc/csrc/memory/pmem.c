#include<stdio.h>
#include "include/mydpi.h"
#include "memory/pmem.h"

#define SERIAL_PORT 0x10000000u
#define PEME_START 0x80000000u
#define RTC_ADDR 0x10000048u
uint32_t pmem[MAX_LENGTH];
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
extern "C" uint32_t pmem_read(uint32_t raddr){
    uint32_t index=(uint32_t)raddr;
    static uint64_t us=0;
    if(index>=RTC_ADDR&&index<=RTC_ADDR+4){
        if(index==RTC_ADDR+4){
            us=get_time();
            return us>>32;
        }else {
            return (uint32_t)us;
        }
    }else if(index>=PEME_START){
        index=(index-PEME_START)>>2;
        return pmem[index];
    }
    return 0;
}
extern "C" void pmem_write(uint32_t waddr, uint32_t wdata, char wmask) {
    uint32_t index=(uint32_t)waddr;
    int addr_shift;
    uint32_t wdata1,wdata2,mask;
    if(wmask==1){
        mask=0x000000ff;
    }else if(wmask==3){
        mask=0x0000ffff;
    }else{
        mask=0xffffffff;
    }
    wdata1=(uint32_t)wdata&mask;
    if(index==SERIAL_PORT){
        putc(wdata1,stdout);
    }else if(index>=PEME_START){
        addr_shift=index%4;
        index=(index-PEME_START)>>2;
        wdata1=wdata1<<(addr_shift*8);
        wdata2=pmem[index]&~(mask<<(addr_shift*8));
        pmem[index]=wdata1|wdata2;
    }
}

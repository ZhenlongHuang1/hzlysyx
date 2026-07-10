#include<stdio.h>
#include "include/mydpi.h"
#include "include/debug.h"
#include "include/macro.h"
#include "memory/pmem.h"
#include "cpu/cpu.h"
#include "include/autoconf.h"
void difftest_skip_ref();
uint32_t mrom[MROM_SIZE]={0};
uint32_t flash[FLASH_SIZE]={0};
extern "C" void flash_read(int32_t addr, int32_t *data) {
    printf("flash%x\n",addr);
    uint32_t raddr=((uint32_t)addr)>>2;
    if(raddr>=FLASH_SIZE){
        data[0]=0;
        return ;
    }
    data[0]=flash[raddr];
#ifdef CONFIG_MTRACE
    if(raddr>=CONFIG_MTRACE_START&&raddr<=CONFIG_MTRACE_END)
        Log("Read flash at addr=0x%08x,data=%08x",raddr,data[0]);
#endif
}
extern "C" void mrom_read(int32_t addr, int32_t *data){
    printf("mrom%x\n",addr);
    uint32_t raddr=(addr-MROM_START)>>2;
    if(raddr>=MROM_SIZE){
        data[0]=0;
        return ;
    }
    data[0]=mrom[raddr];
#ifdef CONFIG_MTRACE
    if(addr>=CONFIG_MTRACE_START&&addr<=CONFIG_MTRACE_END)
        Log("Read mrom at addr=0x%08x,data=%08x",addr,data[0]);
#endif
}
static void pmem_write(uint32_t addr,uint32_t data,uint32_t mask){
    uint32_t addr_shift=addr%4;
    uint32_t raddr=(addr-MROM_START)>>2;
    uint32_t wdata1=data<<(addr_shift*8);
    uint32_t wdata2=mrom[raddr]&~(mask<<(addr_shift*8));
    mrom[raddr]=wdata1|wdata2; 
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

#include "svdpi.h"
#include "Vysyx_26040117_top__Dpi.h"
#define MAX_LENGTH 16777216

extern uint32_t pmem[MAX_LENGTH];
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

#ifndef __PMEM_H__
#define __PMEM_H__
#include <sys/time.h>
#include <stdint.h>
#define MAX_LENGTH 134217728

#define SERIAL_PORT 0x10000000u
#define PMEM_START 0x80000000u
#define PMEM_SIZE  0x08000000u
#define RTC_ADDR 0x10000048u
extern uint32_t pmem[MAX_LENGTH];

static inline int in_pmem(uint32_t addr){
    return (addr-PMEM_START<PMEM_SIZE)&&(addr>=PMEM_START);
}
extern "C" uint32_t paddr_read(uint32_t raddr);
extern "C" void paddr_write(uint32_t waddr, uint32_t wdata, char wmask);

#endif

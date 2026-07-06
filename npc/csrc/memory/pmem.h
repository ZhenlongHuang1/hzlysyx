#ifndef __PMEM_H__
#define __PMEM_H__
#include <sys/time.h>
#include <stdint.h>

#define PMROM_START 0x20000000u
#define PMROM_SIZE  0x00001000u
extern uint32_t pmrom[PMROM_SIZE];

static inline int in_pmrom(uint32_t addr){
    return (addr-PMROM_START<PMROM_SIZE)&&(addr>=PMROM_START);
}
extern "C" void flash_read(int32_t addr, int32_t *data);
extern "C" void mrom_read(int32_t addr, int32_t *data);

extern "C" uint32_t paddr_read(uint32_t raddr);
extern "C" void paddr_write(uint32_t waddr, uint32_t wdata, char wmask);
uint64_t get_time();
#endif

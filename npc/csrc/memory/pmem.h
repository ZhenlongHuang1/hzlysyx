#ifndef __PMEM_H__
#define __PMEM_H__
#include <sys/time.h>
#include <stdint.h>
#define MAX_LENGTH 134217728

extern uint32_t pmem[MAX_LENGTH];

extern "C" uint32_t pmem_read(uint32_t raddr);
extern "C" void pmem_write(uint32_t waddr, uint32_t wdata, char wmask);

#endif

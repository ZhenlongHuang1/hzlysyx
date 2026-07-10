#ifndef __PMEM_H__
#define __PMEM_H__
#include <sys/time.h>
#include <stdint.h>

#define MROM_START 0x20000000u
#define MROM_SIZE  0x00001000u
#define FLASH_START 0x30000000u
#define FLASH_SIZE  0x1000000u
extern uint32_t mrom[MROM_SIZE];
extern uint32_t flash[FLASH_SIZE];

extern "C" void flash_read(int32_t addr, int32_t *data);
extern "C" void mrom_read(int32_t addr, int32_t *data);

uint64_t get_time();
#endif

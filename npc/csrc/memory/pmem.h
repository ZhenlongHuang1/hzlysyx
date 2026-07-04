#ifndef __PMEM_H__
#define __PMEM_H__
#include <stdint.h>
#include <sys/time.h>
#define PMEM_START 0x20000000u
uint64_t get_time();
#endif

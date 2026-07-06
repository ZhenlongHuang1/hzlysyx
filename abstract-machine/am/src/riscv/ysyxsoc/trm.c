#include <am.h>
#include <klib-macros.h>
#include "riscv/riscv.h"
#include "klib.h"
extern char _heap_start;
extern char _heap_end;
extern char _data_lma_start;
extern char _data_vma_start;
extern char _data_vma_end;
extern char _bss_start;
extern char _bss_end;
int main(const char *args);

# define nemu_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))
Area heap = RANGE(&_heap_start, &_heap_end);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

void putch(char ch) {
    outb(0x10000000, ch);
}

void halt(int code) {
    nemu_trap(code);
    while (1);
}

static void test_mcycle(){
    uint32_t low,high;
    asm volatile("csrr %0, mcycle" :"=r"(low));
    asm volatile("csrr %0, mcycleh" :"=r"(high));
    printf("Number of operating cycles=%lld\n",((uint64_t)high<<32)|low);

}
void _trm_init() {
    memcpy(&_data_vma_start,&_data_lma_start,(&_data_vma_end-&_data_vma_start));
    memset(&_bss_start,0,(&_bss_end-&_bss_start));
    uint32_t project,id;
    asm volatile("csrr %0, mvendorid":"=r"(project));
    asm volatile("csrr %0, marchid":"=r"(id));
    printf("student number:%c%c%c%c_%d\n",(project&0xff000000)>>24,(project&0xff0000)>>16,(project&0xff00)>>8,(project&0xff),id);
    int ret = main(mainargs);
    test_mcycle();
    halt(ret);
}

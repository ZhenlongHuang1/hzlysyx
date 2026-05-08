#ifndef __REG_H__
#define __REG_H__
#include<stdbool.h>
#include "cpu/cpu.h"
void isa_reg_display();
bool isa_difftest_checkregs(CPU_state *ref_r);
#endif

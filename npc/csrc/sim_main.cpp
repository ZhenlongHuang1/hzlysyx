#include<stdlib.h>
#include<assert.h>
//#include<nvboard.h>
#include "cpu/cpu.h"
#include "monitor/sdb.h"

#define USE_NVBOARD 1

void nvboard_bind_all_pins(TOP_NAME*top);
void init_monitor(int, char *[]);
void free_monitor();
int main(int argc,char**argv){
    //nvboard_bind_all_pins(dut);
    //nvboard_init();
    //while((USE_NVBOARD||!contextp->gotFinish()&&contextp->time()<sim_time)&&npc_state==1)
    init_monitor(argc,argv);
    sdb_main_loop();
    free_monitor();
    //nvboard_update();
    return is_exit_status_bad();

}

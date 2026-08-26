#include <stdint.h>
#include <stdio.h>
#include<stdlib.h>
#include <time.h>
#define CACHE_SIZE 128

int main(int argc,char *argv[]) {
    if(argc!=5){
        printf("argc error\n");
        return 0;
    }
    int offset_width,index_width,w,total_count,algorithm;
    algorithm=atoi(argv[4]);//1:FIFO,2:LRU,3:random
    total_count=atoi(argv[1]);
    offset_width=atoi(argv[2]);
    index_width=atoi(argv[3]);
    w=total_count/(1<<index_width);
    printf("total_count=%d,offset_width=%d,index_width=%d,w=%d,algorithm=%d\n",total_count,offset_width,index_width,w,algorithm);
    uint32_t set_count = 1u << index_width;
    FILE *fp = fopen("../build/icache_record.txt", "r");
    if (fp == NULL) {
        perror("open icache_record.txt");
        return 1;
    }
    uint32_t tag_array[CACHE_SIZE] = {0};
    uint8_t valid_array[CACHE_SIZE] = {0};
    uint64_t access = 0;
    uint64_t hit = 0;
    uint64_t miss = 0;
    uint32_t pc;
    uint64_t last_used[CACHE_SIZE] = {0};
    int i,hit_flag;
    while (fscanf(fp, "%x", &pc) == 1) {
        uint32_t index = (pc >> offset_width) & (set_count-1);
        uint32_t tag = pc >> (offset_width+index_width);
        access++;
        hit_flag=0;
        for(i=0;i<w;i++){
            uint32_t addr=index+i*set_count;
            if(valid_array[addr] && tag_array[addr] == tag){
                hit++;
                hit_flag=1;
                if (algorithm == 2) {
                    last_used[addr] = access;
                }
                break;
            }
        }
        if(!hit_flag){
            miss++;
            if(algorithm==1){//FIFO
                uint32_t addr1,addr2;
                for(i=0;i<w-1;i++){
                    addr1=index+i*set_count;
                    addr2=index+(i+1)*set_count;
                    valid_array[addr1]=valid_array[addr2];
                    tag_array[addr1]=tag_array[addr2];
                }
                addr2=index+(w-1)*set_count;
                valid_array[addr2]=1;
                tag_array[addr2]=tag;
            }else if(algorithm==3){//random
                uint32_t addr=index+set_count*(rand()%w);
                valid_array[addr]=1;
                tag_array[addr]=tag;
            }else if (algorithm == 2) {      /* LRU */
                uint32_t victim = index;
                uint64_t oldest_time = UINT64_MAX;
                for (i = 0; i < w; i++) {
                    uint32_t addr = index + i * set_count;
                    if (!valid_array[addr]) {
                        victim = addr;
                        break;
                    }
                    if (last_used[addr] < oldest_time) {
                        oldest_time = last_used[addr];
                        victim = addr;
                    }
                }
                valid_array[victim] = 1;
                tag_array[victim] = tag;
                last_used[victim] = access;
            }

        }
    }

    if (ferror(fp)) {
        perror("read icache_record.txt");
        fclose(fp);
        return 1;
    }
    fclose(fp);
    printf("capacity=%dbyte,access count = %lu, hit count = %lu, hit rate =%.6f\n",total_count*(1<<offset_width), access,hit,(double)hit/access);
    return 0;
}

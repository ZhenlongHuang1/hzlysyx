#include <stdint.h>
#include <stdio.h>
#include<stdlib.h>
#include <time.h>
#define CACHE_SIZE 128

int main(int argc,char *argv[]) {
    int offset_width,index_width;
    offset_width=atoi(argv[1]);
    index_width=atoi(argv[2]);
    printf("offset_width=%d,index_width=%d\n",offset_width,index_width);
    uint32_t set_count = 1u << index_width;
    FILE *fp = fopen("../build/dcache_record.txt", "r");
    if (fp == NULL) {
        perror("open dcache_record.txt");
        return 1;
    }
    uint32_t tag_array[CACHE_SIZE] = {0};
    uint8_t valid_array[CACHE_SIZE] = {0};
    uint64_t access = 0,ra=0,wa=0;
    uint64_t hit = 0,rhit=0,whit=0;
    uint32_t pc;
    int hit_flag;
    char operation[16];
    int isread;
    while (fscanf(fp, "%15s %x", operation,&pc) == 2) {
        isread=operation[0]=='r';
        uint32_t index = (pc >> offset_width) & (set_count-1);
        uint32_t tag = pc >> (offset_width+index_width);
        access++;
        if(isread)
            ra++;
        else 
            wa++;
        hit_flag=0;
        if(valid_array[index] && tag_array[index] == tag){
            hit++;
            if(isread)
                rhit++;
            else 
                whit++;
            hit_flag=1;
        }
        if(!hit_flag){
            valid_array[index]=1;
            tag_array[index]=tag;
        }
    }

    if (ferror(fp)) {
        perror("read dcache_record.txt");
        fclose(fp);
        return 1;
    }
    fclose(fp);
    printf("access count=%lu,hit count=%lu,hit rate=%.4f,ra=%lu,rhit=%lu,rhitrate=%.4f,wa=%lu,whit=%lu,whitrate=%.4f\n", access,hit,(double)hit/access,ra,rhit,(double)rhit/ra,wa,whit,(double)whit/wa);
    return 0;
}

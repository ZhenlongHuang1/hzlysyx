#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#define BTB_SIZE 128

int main(int argc,char *argv[]){
    if(argc!=2) return 1;
    int index_width=atoi(argv[1]);
    if(index_width<0||index_width>7) return 1;

    uint32_t set_count=1u<<index_width;
    uint32_t tag_array[BTB_SIZE]={0};
    uint32_t target_array[BTB_SIZE]={0};
    uint8_t valid_array[BTB_SIZE]={0};

    uint64_t count[3]={0},correct[3]={0};
    uint64_t hit=0,replace=0;

    FILE *fp=fopen("../build/btrace.txt","r");
    if(fp==NULL){
        perror("open btrace.txt");
        return 1;
    }

    uint64_t btb_hit_wrong=0,btb_miss_wrong=0;
    uint32_t pc,inst,dnpc;
    while(fscanf(fp,"%" SCNx32 " %" SCNx32 " %" SCNx32,&pc,&inst,&dnpc)==3){
        uint32_t opcode=inst&0x7f;
        int type;
        if(opcode==0x63) type=0;
        else if(opcode==0x6f) type=1;
        else if(opcode==0x67) type=2;
        else continue;

        uint32_t index=(pc>>2)&(set_count-1);
        uint32_t tag=pc>>(index_width+2);
        int btb_hit=valid_array[index]&&tag_array[index]==tag;
        uint32_t pred_npc=btb_hit?target_array[index]:pc+4;
        //uint32_t pred_npc=pc+4;

        count[type]++;
        correct[type]+=pred_npc==dnpc;
        hit+=btb_hit;
        btb_miss_wrong += !btb_hit && pred_npc!=dnpc;
        btb_hit_wrong += btb_hit && pred_npc!=dnpc;

        uint32_t imm=0;
        int allocate=0;

        if(type==0){
            imm=((inst>>31)<<12)|(((inst>>7)&1)<<11)|(((inst>>25)&0x3f)<<5)|(((inst>>8)&0xf)<<1);
            if(imm&0x1000) imm|=0xffffe000u;

            int backward=inst>>31;
            allocate=backward;
        }else if(type==1){
            imm=((inst>>31)<<20)|(((inst>>12)&0xff)<<12)|(((inst>>20)&1)<<11)|(((inst>>21)&0x3ff)<<1);
            if(imm&0x100000) imm|=0xffe00000u;
            allocate=1;
        }

        if(allocate){
            replace+=valid_array[index]&&tag_array[index]!=tag;
            valid_array[index]=1;
            tag_array[index]=tag;
            target_array[index]=pc+imm;
        }
    }

    if(ferror(fp)){
        perror("read btrace.txt");
        fclose(fp);
        return 1;
    }
    fclose(fp);

    uint64_t total=count[0]+count[1]+count[2];
    uint64_t total_correct=correct[0]+correct[1]+correct[2];

    printf("BTB entries        = %u\n",set_count);
    printf("control count      = %" PRIu64 "\n",total);
    printf("BTB hit            = %" PRIu64 "\n",hit);
    printf("BTB hit rate       = %.3f%%\n",100.0*hit/total);
    printf("BTB hit wrong      = %.3f%%\n",100.0*btb_hit_wrong/total);
    printf("BTB miss wrong     = %.3f%%\n",100.0*btb_miss_wrong/total);
    printf("BTB replacements   = %" PRIu64 "\n",replace);
    printf("branch count       = %" PRIu64 "\n",count[0]);
    printf("branch NPC correct = %.3f%%\n",100.0*correct[0]/count[0]);
    printf("jal count          = %" PRIu64 "\n",count[1]);
    printf("jal NPC correct    = %.3f%%\n",100.0*correct[1]/count[1]);
    printf("jalr count         = %" PRIu64 "\n",count[2]);
    printf("jalr NPC correct   = %.3f%%\n",100.0*correct[2]/count[2]);
    printf("total NPC correct  = %.3f%%\n",100.0*total_correct/total);
    printf("total NPC wrong    = %" PRIu64 "\n",total-total_correct);

    return 0;
}

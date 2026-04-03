/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "common.h"
#include "sdb.h"

#define NR_WP 32

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;
WP* new_wp(char * args,word_t result);
void free_wp(WP *wp);
void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }
  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
WP* new_wp(char *args,word_t result){
    if(free_==NULL){
        assert(0);
    }
    WP* wptr=free_;
    free_=free_->next;
    wptr->next=head;
    head=wptr;
    wptr->result=result;
    strncpy(wptr->args,args,NR_WP_ARGS);
    wptr->args[NR_WP_ARGS-1]='\0';
    printf("watchpoint %d:%s\n",wptr->NO,wptr->args);
    return wptr;
}
void free_wp(WP *wp){
    if(wp==NULL||head==NULL)
        return ;
    WP * tmp=head;
    if(wp==tmp){
        head=head->next;
        wp->next=free_;
        free_=wp;
    }else 
        while(tmp->next){
            if(tmp->next==wp){
                tmp->next=wp->next;
                wp->next=free_;
                free_=wp;
                return ;
            }
        }
    return ;
}

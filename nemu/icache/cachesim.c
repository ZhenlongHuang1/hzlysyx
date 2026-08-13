#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
  FILE *fp = fopen("../build/icache_record.txt", "r");
  if (fp == NULL) {
    perror("open icache_record.txt");
    return 1;
  }

  uint32_t tag_array[16] = {0};
  uint8_t valid_array[16] = {0};
  uint64_t access = 0;
  uint64_t hit = 0;
  uint64_t miss = 0;
  uint32_t pc;

  while (fscanf(fp, "%x", &pc) == 1) {
    uint32_t index = (pc >> 2) & ((uint32_t)(1<<4)-1);
    uint32_t tag = pc >> 6;

    access++;

    if (valid_array[index] && tag_array[index] == tag) {
      hit++;
    } else {
      miss++;
      valid_array[index] = 1;
      tag_array[index] = tag;
    }
  }

  if (ferror(fp)) {
    perror("read icache_record.txt");
    fclose(fp);
    return 1;
  }

  fclose(fp);

  printf("access count = %lu\n", access);
  printf("hit count    = %lu\n", hit);
  printf("miss count   = %lu\n", miss);
  printf("hit rate     = %.6f\n", (double)hit/access);
  printf("miss rate    = %.6f\n", (double)miss/access);

  return 0;
}

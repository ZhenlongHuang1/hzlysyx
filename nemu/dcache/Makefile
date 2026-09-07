CFLAGS := -O3 -Wall -Wextra
CC := gcc
.PHONY: run clean


a:cachesim.c
	$(CC) $(CFLAGS) $^ -o $@

run:a
	bash run.sh params.txt
clean:
	rm -f a
	rm -rf results

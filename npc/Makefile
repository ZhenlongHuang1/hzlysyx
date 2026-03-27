all:
	
sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	verilator --cc --exe --build -j 0 -Wall sim_main.cpp top.v
clean:
	rm -rf build obj_dir
include ../Makefile

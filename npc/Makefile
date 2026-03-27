all:
	
sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	verilator --cc --exe --build -j 0 -Wall csrc/sim_main.cpp vsrc/top.v
clean:
	rm -rf build obj_dir
include ../Makefile

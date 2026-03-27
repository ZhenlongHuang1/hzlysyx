all:
	obj_dir/Vtop
sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	verilator --cc --exe --build --trace-vcd -j 0 -Wall csrc/sim_main.cpp vsrc/top.v
clean:
	rm -rf build obj_dir
include ../Makefile

SIM_ENV ?=ysyxsoc
YSYXSOC_HOME := $(abspath ../ysyxSoc)
VSRCS := $(shell find $(abspath ./vsrc/minirv) -name "*.v")
ifeq ($(SIM_ENV),ysyxsoc)
TOPNAME=ysyxSoCFull
VSRCS += $(shell find $(YSYXSOC_HOME)/perip -name "*.v")
VSRCS += $(YSYXSOC_HOME)/build/ysyxSoCFull.v
VERILATOR_FLAGS += -I$(YSYXSOC_HOME)/perip/uart16550/rtl -I$(YSYXSOC_HOME)/perip/spi/rtl
CXXFLAGS +=-DUSE_NVBOARD
else ifeq ($(SIM_ENV),npc)
TOPNAME=ysyx_26040117_SIM
VSRCS += $(shell find $(abspath ./vsrc/riscv32e_npc) -name "*.v")
CXXFLAGS+=-DRISCV32E_NPC
endif

INC_PATH +=$(abspath ./csrc)
AUTOCONF_H = $(abspath ./csrc/include/autoconf.h)
IMG ?=
ARGS ?=
VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc \
					-O3 --x-assign fast --x-initial fast --noassert
VERILATOR_FLAGS += --trace-vcd
VERILATOR_FLAGS += -I$(abspath ./vsrc/minirv)
VERILATOR_FLAGS += --timescale "1ns/1ns" --no-timing --autoflush#uart flush
VERILATOR_FLAGS += -DPERF_COUNTER

BUILD_DIR =./build
OBJ_DIR = $(BUILD_DIR)/sim/$(SIM_ENV)/obj_dir
BIN = $(BUILD_DIR)/sim/$(SIM_ENV)/$(TOPNAME)
default: $(BIN)

CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
ifeq ($(SIM_ENV),ysyxsoc)
NXDC_FILES=constr/$(TOPNAME).nxdc
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	@mkdir -p $(dir $@)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@
CSRCS += $(SRC_AUTO_BIND)
include $(NVBOARD_HOME)/scripts/nvboard.mk
endif

INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="V$(TOPNAME)" -g -O3 #-flto
LDFLAGS += -lreadline #-flto

#CXXFLAGS += -Wall -Wextra -fsanitize=address,undefined
#LDFLAGS  += -fsanitize=address,undefined

ifneq ($(shell grep '^\s*\#define\s\+CONFIG_DIFFTEST' $(AUTOCONF_H)),)
CXXFLAGS += -DNEMU_HOME_STR=$(NEMU_HOME)
endif
ifneq ($(shell grep '^\s*\#define\s\+CONFIG_ITRACE' $(AUTOCONF_H)),)
LIBCAPSTONE = $(NEMU_HOME)/tools/capstone/repo/libcapstone.so.5
CXXFLAGS += -DNEMU_HOME_STR=$(NEMU_HOME)
CXXFLAGS += -I$(NEMU_HOME)/tools/capstone/repo/include 
CXXFLAGS += -I$(NEMU_HOME)/src/utils
CXXFLAGS += -I$(NEMU_HOME)/include
CXXFLAGS += -fpermissive -DCONFIG_ISA_riscv
CSRCS+=$(NEMU_HOME)/src/utils/disasm.c
$(NEMU_HOME)/src/utils/disasm.c: $(LIBCAPSTONE)
$(LIBCAPSTONE):
	$(MAKE) -C $(NEMU_HOME)/tools/capstone
endif

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	@mkdir -p $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) $(VERILATOR_FLAGS)\
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

lint:
	$(VERILATOR) --lint-only -Wall -Wno-DECLFILENAME --top-module $(TOPNAME) $(VSRCS)
all: default
sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$(BIN) $(ARGS) $(IMG)
sim_ysyxsoc: 
	$(MAKE) sim SIM_ENV=ysyxsoc
sim_npc: 
	$(MAKE) sim SIM_ENV=npc
gdb: $(BIN)
	gdb --args $(BIN) $(ARGS) $(IMG)

clean:
	rm -rf $(BUILD_DIR)
include ../Makefile
SYN_TOP = ysyx_26040117_IFU
STA_FREQ_MHZ ?= 728
SYN_DIR=$(abspath $(BUILD_DIR)/syn)
YOSYS_HOME=$(HOME)/Desktop/yosys-sta
SYN_VSRCS = $(shell find $(abspath ./vsrc/minirv) -name "*.v")
CLK_PORT_NAME=clk
sta:
	@mkdir -p $(SYN_DIR)
	$(MAKE) -C $(YOSYS_HOME) sta DESIGN=$(SYN_TOP) \
		RTL_FILES="$(SYN_VSRCS)" CLK_FREQ_MHZ=$(STA_FREQ_MHZ) CLK_PORT_NAME=$(CLK_PORT_NAME) O=$(SYN_DIR) \
		2>&1 | tee sta.log
syn:
	@mkdir -p $(SYN_DIR)
	$(MAKE) -C $(YOSYS_HOME) syn DESIGN=$(SYN_TOP) \
		RTL_FILES="$(SYN_VSRCS)" CLK_FREQ_MHZ=$(STA_FREQ_MHZ) CLK_PORT_NAME=$(CLK_PORT_NAME) O=$(SYN_DIR)

MICROBENCH_HOME ?= $(abspath ../am-kernels/benchmarks/microbench)
.PHONY: default all sim sim_ysyxsoc sim_npc lint gdb clean sta syn perf
perf:
	$(MAKE) -C $(MICROBENCH_HOME) \
		ARCH=riscv32e-ysyxsoc  \
		mainargs=train \
		run

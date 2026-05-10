TOPNAME=ysyx_26040117_top
NXDC_FILES=constr/$(TOPNAME).nxdc
INC_PATH +=$(abspath ./csrc)
AUTOCONF_H = $(abspath ./csrc/include/autoconf.h)
IMG ?=
ARGS ?=
VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc \
					-O3 --x-assign fast --x-initial fast --noassert
#VERILATOR_FLAGS += --trace-vcd
VERILATOR_FLAGS +=

BUILD_DIR =./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
SYN_DIR=$(abspath $(BUILD_DIR)/syn)
YOSYS_HOME=$(HOME)/Desktop/yosys-sta
BIN = $(BUILD_DIR)/$(TOPNAME)
default: $(BIN)
$(shell mkdir -p $(BUILD_DIR))
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)
include $(NVBOARD_HOME)/scripts/nvboard.mk
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="V$(TOPNAME)" -g -O3 -flto
LDFLAGS += -lreadline -flto

ifneq ($(shell grep '^\s*\#define\s\+CONFIG_ITRACE' $(AUTOCONF_H)),)
LIBCAPSTONE = $(NEMU_HOME)/tools/capstone/repo/libcapstone.so.5
CXXFLAGS += -I$(NEMU_HOME)/tools/capstone/repo/include 
CXXFLAGS += -I$(NEMU_HOME)/src/utils
CXXFLAGS += -I$(NEMU_HOME)/include
CXXFLAGS += -fpermissive -DCONFIG_ISA_riscv
CXXFLAGS += -DNEMU_HOME_STR=$(NEMU_HOME)
CSRCS+=$(NEMU_HOME)/src/utils/disasm.c
$(NEMU_HOME)/src/utils/disasm.c: $(LIBCAPSTONE)
$(LIBCAPSTONE):
	$(MAKE) -C $(NEMU_HOME)/tools/capstone
endif

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
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
gdb: $(BIN)
	gdb --args $(BIN) $(ARGS) $(IMG)

clean:
	rm -rf $(BUILD_DIR)
include ../Makefile
sta:
	@mkdir -p $(SYN_DIR)
	$(MAKE) -C $(YOSYS_HOME) sta DESIGN=$(TOPNAME) \
		RTL_FILES="$(VSRCS)" O=$(SYN_DIR)
syn:
	@mkdir -p $(SYN_DIR)
	$(MAKE) -C $(YOSYS_HOME) syn DESIGN=$(TOPNAME) \
		RTL_FILES="$(VSRCS)" O=$(SYN_DIR)


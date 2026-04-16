TOPNAME=ysyx_26040117_top
NXDC_FILES=constr/$(TOPNAME).nxdc
INC_PATH ?=
IMG ?=
VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc \
					-O3 --x-assign fast --x-initial fast --noassert --trace-vcd
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
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

lint:
	$(VERILATOR) --lint-only -Wall -Wno-DECLFILENAME --top-module $(TOPNAME) $(VSRCS)
all: default
sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$(BIN) $(IMG)

clean:
	rm -rf $(BUILD_DIR)
include ../Makefile
sta:
	@mkdir -p $(SYN_DIR)
	$(MAKE) -C $(YOSYS_HOME) sta DESIGN=$(TOPNAME) \
		RTL_FILES=$(VSRCS) O=$(SYN_DIR)
syn:
	@mkdir -p $(SYN_DIR)
	$(MAKE) -C $(YOSYS_HOME) syn DESIGN=$(TOPNAME) \
		RTL_FILES="$(VSRCS)" O=$(SYN_DIR)


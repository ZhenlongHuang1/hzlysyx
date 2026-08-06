`include "ysyx_26040117__defines.vh"
module ysyx_26040117(
    input  wire         clock,
    input  wire         reset,          
    input  wire         io_interrupt,
    //Master
    input  wire         io_master_awready,
    output wire         io_master_awvalid,
    output wire [31:0]  io_master_awaddr,
    output wire [3:0]   io_master_awid,
    output wire [7:0]   io_master_awlen,
    output wire [2:0]   io_master_awsize,
    output wire [1:0]   io_master_awburst,

    input  wire         io_master_wready,
    output wire         io_master_wvalid,
    output wire [31:0]  io_master_wdata,
    output wire [3:0]   io_master_wstrb,
    output wire         io_master_wlast,

    output wire         io_master_bready,
    input  wire         io_master_bvalid,
    input  wire [1:0]   io_master_bresp,
    input  wire [3:0]   io_master_bid,

    input  wire         io_master_arready,
    output wire         io_master_arvalid,
    output wire [31:0]  io_master_araddr,
    output wire [3:0]   io_master_arid,
    output wire [7:0]   io_master_arlen,
    output wire [2:0]   io_master_arsize,
    output wire [1:0]   io_master_arburst,

    output wire         io_master_rready,
    input  wire         io_master_rvalid,
    input  wire [1:0]   io_master_rresp,
    input  wire [31:0]  io_master_rdata,
    input  wire         io_master_rlast,
    input  wire [3:0]   io_master_rid,
    //Slave
    output wire         io_slave_awready,
    input  wire         io_slave_awvalid,
    input  wire [31:0]  io_slave_awaddr,
    input  wire [3:0]   io_slave_awid,
    input  wire [7:0]   io_slave_awlen,
    input  wire [2:0]   io_slave_awsize,
    input  wire [1:0]   io_slave_awburst,

    output wire         io_slave_wready,
    input  wire         io_slave_wvalid,
    input  wire [31:0]  io_slave_wdata,
    input  wire [3:0]   io_slave_wstrb,
    input  wire         io_slave_wlast,

    input  wire         io_slave_bready,
    output wire         io_slave_bvalid,
    output wire [1:0]   io_slave_bresp,
    output wire [3:0]   io_slave_bid,

    output wire         io_slave_arready,
    input  wire         io_slave_arvalid,
    input  wire [31:0]  io_slave_araddr,
    input  wire [3:0]   io_slave_arid,
    input  wire [7:0]   io_slave_arlen,
    input  wire [2:0]   io_slave_arsize,
    input  wire [1:0]   io_slave_arburst,

    input  wire         io_slave_rready,
    output wire         io_slave_rvalid,
    output wire [1:0]   io_slave_rresp,
    output wire [31:0]  io_slave_rdata,
    output wire         io_slave_rlast,
    output wire [3:0]   io_slave_rid
);
    //Master
    wire[139:0] master_wrapper_out;
    wire[49:0] master_wrapper_in;
    assign master_wrapper_in={io_master_awready,io_master_wready,io_master_bvalid,io_master_bresp,io_master_bid,io_master_arready,
        io_master_rvalid,io_master_rresp,io_master_rdata,io_master_rlast,io_master_rid};
    assign {io_master_awvalid,io_master_awaddr,io_master_awid,io_master_awlen,io_master_awsize,io_master_awburst,
        io_master_wvalid,io_master_wdata,io_master_wstrb,io_master_wlast,io_master_bready,io_master_arvalid,
        io_master_araddr,io_master_arid,io_master_arlen,io_master_arsize,io_master_arburst,io_master_rready}=master_wrapper_out;
    //Slave
    assign io_slave_awready=1'b0;
    assign io_slave_wready=1'b0;
    assign io_slave_bvalid=1'b0;
    assign io_slave_bresp=2'b0;
    assign io_slave_bid=4'b0;
    assign io_slave_arready=1'b0;
    assign io_slave_rvalid=1'b0;
    assign io_slave_rresp=2'b0;
    assign io_slave_rdata=32'd0;
    assign io_slave_rlast=1'b0;
    assign io_slave_rid=4'b0;

    //WBU-data
    wire[31:0]dnpc,srcd;//result:ALU结果
    wire jump,jalr;
    //Instruction Fetch Unit
    wire IFU_IDU_ready,IFU_IDU_valid;
    wire[31:0]ifu_idu_pc,ifu_idu_snpc;
    wire[31:0]inst;
    wire WBU_IFU_valid,WBU_IFU_ready;
    wire [40:0]MEM_IFU_wrapper;
    wire [107:0]IFU_MEM_wrapper;
    ysyx_26040117_IFU IFU1(.clk(clock),.rst(reset),
        .WBU_IFU_valid(WBU_IFU_valid),.WBU_IFU_ready(WBU_IFU_ready),.jalr(jalr),.jump(jump),.dnpc(dnpc),.lsu_error(lsu_error),
        //.dummy_ifu_wen(dummy_ifu_wen),.dummy_ifu_wdata(dummy_ifu_wdata),.dummy_ifu_waddr(dummy_ifu_waddr),
        .IFU_IDU_ready(IFU_IDU_ready),.IFU_IDU_valid(IFU_IDU_valid),.inst(inst),.pc(ifu_idu_pc),.snpc(ifu_idu_snpc),
        .MEM_IFU_wrapper(MEM_IFU_wrapper),.IFU_MEM_wrapper(IFU_MEM_wrapper)
    );
    
    //Instruction Decode Unit
    wire IDU_EXU_ready,IDU_EXU_valid;
    wire[31:0]imm;
    wire[4:0]op;
    wire[8:0]mytype;//0:lui;    1:auipc;    2:jal;  3:jalr;  4:跳转;  5:load;  6:store;  7:立即数计算;  8:寄存器计算

    wire[77:0]IDU_wrapper;
    wire[4:0] rs1,rs2;
    ysyx_26040117_IDU IDU1(.clk(clock),.rst(reset),
        .IFU_IDU_ready(IFU_IDU_ready),.IFU_IDU_valid(IFU_IDU_valid),.inst(inst),
        .pc(ifu_idu_pc),.snpc(ifu_idu_snpc),
        .IDU_EXU_ready(IDU_EXU_ready),.IDU_EXU_valid(IDU_EXU_valid),.imm(imm),.op(op),.mytype(mytype),
        .IDU_wrapper(IDU_wrapper),
        .rs1(rs1),.rs2(rs2)
    );
    //Register block
    wire[31:0]src1,src2;
    wire [4:0] wbu_register_rd;
    wire wbu_register_wen;
    ysyx_26040117_RegisterFile Register1(.clk(clock),.rst(reset),
        .raddr1(rs1),.raddr2(rs2),.rdata1(src1),.rdata2(src2),
        .wdata(srcd),.waddr(wbu_register_rd),.wen(wbu_register_wen)
    );
    //Execution Unit
    wire EXU_WBU_ready,EXU_WBU_valid;
    wire [31:0]result;
    wire [31:0] exu_wbu_src1,exu_wbu_src2,exu_wbu_imm;
    wire [8:0] exu_wbu_mytype;
    wire [4:0] exu_wbu_op;
    wire[77:0]EXU_wrapper; 
    ysyx_26040117_EXU EXU1(.clk(clock),.rst(reset),
        .IDU_EXU_ready(IDU_EXU_ready),.IDU_EXU_valid(IDU_EXU_valid),.src1(src1),.src2(src2),.imm(imm),.op(op),.mytype(mytype),
        .IDU_wrapper(IDU_wrapper),
        .EXU_WBU_ready(EXU_WBU_ready),.EXU_WBU_valid(EXU_WBU_valid),.result(result),
        .IDU_wrapper_out(EXU_wrapper),.src1_out(exu_wbu_src1),.src2_out(exu_wbu_src2),.imm_out(exu_wbu_imm),.op_out(exu_wbu_op),.mytype_out(exu_wbu_mytype)
    );

    //WriteBack Unit
    wire lsu_reqValid,lsu_respValid,lsu_respReady,lsu_wen;
    wire [31:0]lsu_addr,lsu_wdata,lsu_rdata;
    wire [3:0]lsu_size;
    wire ifsigned_out;
    wire[1:0] lsu_rresp,lsu_bresp;
    wire lsu_error;
    ysyx_26040117_WBU WBU1(.clk(clock),.rst(reset),
        .EXU_WBU_ready(EXU_WBU_ready),.EXU_WBU_valid(EXU_WBU_valid),.EXU_wrapper(EXU_wrapper),.src1(exu_wbu_src1),.src2(exu_wbu_src2),.imm(exu_wbu_imm),.op(exu_wbu_op),.mytype(exu_wbu_mytype),.result(result),
        .WBU_IFU_valid(WBU_IFU_valid),.WBU_IFU_ready(WBU_IFU_ready),.srcd(srcd),.jump(jump),.dnpc(dnpc),.jalr(jalr),.rd_out(wbu_register_rd),.register_wen(wbu_register_wen),.lsu_error(lsu_error),
        .reqValid(lsu_reqValid),.respReady(lsu_respReady),.respValid(lsu_respValid),.lsu_wen(lsu_wen),.result_out(lsu_addr),.src2_out(lsu_wdata),.wmask_out(lsu_size),.ifsigned_out(ifsigned_out),.ramdata(lsu_rdata),.lsu_rresp(lsu_rresp),.lsu_bresp(lsu_bresp)
    );
    //Load-Store Unit
    wire [40:0]MEM_LSU_wrapper;
    wire [110:0]LSU_MEM_wrapper;
    ysyx_26040117_LSU LSU1(.clk(clock),.rst(reset),
        .reqValid(lsu_reqValid),.respValid(lsu_respValid),.respReady(lsu_respReady),.wen(lsu_wen),.addr(lsu_addr),.wdata_in(lsu_wdata),.size(lsu_size[2:0]),.ifsigned(ifsigned_out),
        .rdata_out2(lsu_rdata),.rresp_out(lsu_rresp),.bresp_out(lsu_bresp),
        .MEM_LSU_wrapper(MEM_LSU_wrapper),.LSU_MEM_wrapper(LSU_MEM_wrapper)
    );
    ysyx_26040117_arbiter arbiter1(.clk(clock),.rst(reset),
        .MEM_IFU_wrapper(MEM_IFU_wrapper),.IFU_MEM_wrapper(IFU_MEM_wrapper),
        .MEM_LSU_wrapper(MEM_LSU_wrapper),.LSU_MEM_wrapper(LSU_MEM_wrapper),
        .master_wrapper_in(master_wrapper_in),.master_wrapper_out(master_wrapper_out)
    );
`ifdef PERF_COUNTER
    wire perf_done;
    assign perf_done=WBU1.ebreak_out&&WBU1.WBU_IFU_fire;
    always @(posedge clock) begin
        if(!reset&&perf_done)begin
            $strobe("Performance Counters");
            $strobe("IFU fetch cycle    = %0d",IFU1.ifu_fetch_inst_count);
            $strobe("IFU no fetch cycle = %0d",IFU1.ifu_no_fetch_count);
            $strobe("IFU wait wbu cycle = %0d",IFU1.ifu_wait_wbu_count);
            $strobe("IFU AR wait        = %0d",IFU1.ifu_arwait_count);
            $strobe("IFU protocol wait  = %0d",IFU1.ifu_protocol_count);
            $strobe("IFU R wait         = %0d",IFU1.ifu_rwait_count);
            $strobe("IFU idu wait       = %0d",IFU1.ifu_idublock_count);
            $strobe("");

            $strobe("LSU LOAD         = %0d",LSU1.lsu_load_count);
            $strobe("LSU R wait       = %0d",LSU1.lsu_rwait_count);
            $strobe("LSU LOAD latency = %0d",LSU1.lsu_load_latency_sum);
            $strobe("LSU STORE        = %0d",LSU1.lsu_store_count);
            $strobe("LSU B wait       = %0d",LSU1.lsu_bwait_count);
            $strobe("LSU STORE latency= %0d",LSU1.lsu_store_latency_sum);
            $strobe("");

            $strobe("IDU decode      = %0d",IDU1.idu_decode_count);
            $strobe("IDU LUI         = %0d",IDU1.idu_lui_count);
            $strobe("IDU LUI cycle   = %0d",perf_lui_cycle);
            $strobe("IDU LUI CPI     = %.2f",perf_lui_cycle/IDU1.idu_lui_count);
            $strobe("IDU AUIPC       = %0d",IDU1.idu_auipc_count);
            $strobe("IDU AUIPC cycle = %0d",perf_auipc_cycle);
            $strobe("IDU AUIPC CPI   = %.2f",perf_auipc_cycle/IDU1.idu_auipc_count);
            $strobe("IDU JUMP        = %0d",IDU1.idu_jump_count);
            $strobe("IDU JUMP cycle  = %0d",perf_jump_cycle);
            $strobe("IDU JUMP CPI    = %.2f",perf_jump_cycle/IDU1.idu_jump_count);
            $strobe("IDU LOAD        = %0d",IDU1.idu_load_count);
            $strobe("IDU LOAD cycle  = %0d",perf_load_cycle);
            $strobe("IDU LOAD CPI    = %.2f",perf_load_cycle/IDU1.idu_load_count);
            $strobe("IDU STORE       = %0d",IDU1.idu_store_count);
            $strobe("IDU STORE cycle = %0d",perf_store_cycle);
            $strobe("IDU STORE CPI   = %.2f",perf_store_cycle/IDU1.idu_store_count);
            $strobe("IDU BRANCH      = %0d",IDU1.idu_branch_count);
            $strobe("IDU BRANCH cycle= %0d",perf_branch_cycle);
            $strobe("IDU BRANCH CPI  = %.2f",perf_branch_cycle/IDU1.idu_branch_count);
            $strobe("IDU ALU         = %0d",IDU1.idu_alu_count);
            $strobe("IDU ALU cycle   = %0d",perf_alu_cycle);
            $strobe("IDU ALU CPI     = %.2f",perf_alu_cycle/IDU1.idu_alu_count);
            $strobe("IDU ALUI        = %0d",IDU1.idu_alui_count);
            $strobe("IDU ALUI cycle  = %0d",perf_alui_cycle);
            $strobe("IDU ALUI CPI    = %.2f",perf_alui_cycle/IDU1.idu_alui_count);
            $strobe("IDU SYSTEM      = %0d",IDU1.idu_system_count);
            $strobe("IDU SYSTEM cycle= %0d",perf_system_cycle);
            $strobe("IDU SYSTEM CPI  = %.2f",perf_system_cycle/IDU1.idu_system_count);
            $strobe("IDU FENCE       = %0d",IDU1.idu_fence_count);
            $strobe("IDU FENCE cycle = %0d",perf_fence_cycle);
            $strobe("IDU FENCE CPI   = %.2f",perf_fence_cycle/IDU1.idu_fence_count);
            $strobe("IDU OTHER       = %0d",IDU1.idu_other_count);
            $strobe("IDU OTHER cycle = %0d",perf_other_cycle);
            $strobe("IDU OTHER CPI   = %.2f",perf_other_cycle/IDU1.idu_other_count);
        end
    end 

    localparam PERF_LUI    = 4'd0;
    localparam PERF_AUIPC  = 4'd1;
    localparam PERF_JUMP   = 4'd2;
    localparam PERF_LOAD   = 4'd3;
    localparam PERF_STORE  = 4'd4;
    localparam PERF_BRANCH = 4'd5;
    localparam PERF_ALU    = 4'd6;
    localparam PERF_ALUI   = 4'd7;
    localparam PERF_SYSTEM = 4'd8;
    localparam PERF_FENCE  = 4'd9;
    localparam PERF_OTHER  = 4'd10;
    wire perf_idu_exu_fire;
    wire perf_exu_ifu_fire;
    assign perf_idu_exu_fire = IDU_EXU_valid && IDU_EXU_ready;
    assign perf_exu_ifu_fire = WBU_IFU_valid && WBU_IFU_ready;
    reg [3:0] perf_inst_type;
    reg [63:0] perf_inst_cycle;
    reg [63:0] perf_alu_cycle;
    reg [63:0] perf_alui_cycle;
    reg [63:0] perf_lui_cycle;
    reg [63:0] perf_auipc_cycle;
    reg [63:0] perf_load_cycle;
    reg [63:0] perf_store_cycle;
    reg [63:0] perf_branch_cycle;
    reg [63:0] perf_jump_cycle;
    reg [63:0] perf_system_cycle;
    reg [63:0] perf_fence_cycle;
    reg [63:0] perf_other_cycle;
    always @(posedge clock) begin
        if (reset) begin
            perf_inst_type    <= PERF_OTHER;
            perf_inst_cycle   <= 64'd0;
            perf_alu_cycle    <= 64'd0;
            perf_alui_cycle   <= 64'd0;
            perf_lui_cycle    <= 64'd0;
            perf_auipc_cycle  <= 64'd0;
            perf_load_cycle   <= 64'd0;
            perf_store_cycle  <= 64'd0;
            perf_branch_cycle <= 64'd0;
            perf_jump_cycle   <= 64'd0;
            perf_system_cycle <= 64'd0;
            perf_fence_cycle  <= 64'd0;
            perf_other_cycle  <= 64'd0;
        end else begin
            perf_inst_cycle <= perf_inst_cycle + 64'd1;
            if (perf_idu_exu_fire) begin
                case (IDU1.opcode)
                    7'b0110011: perf_inst_type <= PERF_ALU;
                    7'b0010011: perf_inst_type <= PERF_ALUI;
                    7'b0110111: perf_inst_type <= PERF_LUI;
                    7'b0010111: perf_inst_type <= PERF_AUIPC;
                    7'b0000011: perf_inst_type <= PERF_LOAD;
                    7'b0100011: perf_inst_type <= PERF_STORE;
                    7'b1100011: perf_inst_type <= PERF_BRANCH;
                    7'b1101111,
                    7'b1100111: perf_inst_type <= PERF_JUMP;
                    7'b1110011: perf_inst_type <= PERF_SYSTEM;
                    7'b0001111: perf_inst_type <= PERF_FENCE;
                    default: perf_inst_type <= PERF_OTHER;
                endcase
            end
            if (perf_exu_ifu_fire) begin
                case (perf_inst_type)
                    PERF_ALU:   perf_alu_cycle   <=perf_alu_cycle    + perf_inst_cycle + 64'd1;
                    PERF_ALUI:  perf_alui_cycle  <=perf_alui_cycle   + perf_inst_cycle + 64'd1;
                    PERF_LUI:   perf_lui_cycle   <=perf_lui_cycle    + perf_inst_cycle + 64'd1;
                    PERF_AUIPC: perf_auipc_cycle <=perf_auipc_cycle  + perf_inst_cycle + 64'd1;
                    PERF_LOAD:  perf_load_cycle  <=perf_load_cycle   + perf_inst_cycle + 64'd1;
                    PERF_STORE: perf_store_cycle <=perf_store_cycle  + perf_inst_cycle + 64'd1;
                    PERF_BRANCH:perf_branch_cycle<=perf_branch_cycle + perf_inst_cycle + 64'd1;
                    PERF_JUMP:  perf_jump_cycle  <=perf_jump_cycle   + perf_inst_cycle + 64'd1;
                    PERF_SYSTEM:perf_system_cycle<=perf_system_cycle + perf_inst_cycle + 64'd1;
                    PERF_FENCE: perf_fence_cycle <=perf_fence_cycle  + perf_inst_cycle + 64'd1;
                    default:    perf_other_cycle <=perf_other_cycle  + perf_inst_cycle + 64'd1;
                endcase
                perf_inst_cycle <= 64'd0;
            end
        end
    end

`endif
endmodule

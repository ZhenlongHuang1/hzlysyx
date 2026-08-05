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
    always @(negedge clock) begin
        if(!reset&&perf_done)begin
            $display("Performance Counters");
            $display("IFU fetch       = %0d",IFU1.ifu_fetch_inst_count);
            $display("IFU AR wait     = %0d",IFU1.ifu_arwait_count);
            $display("IFU R wait      = %0d",IFU1.ifu_rwait_count);
        end
    end 
`endif
endmodule

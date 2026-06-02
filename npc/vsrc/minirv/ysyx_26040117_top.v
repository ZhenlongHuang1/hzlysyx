module ysyx_26040117_top(clk,rst
    //srcd,inst,mytype,result,
    //dummy_ifu_wen,dummy_ifu_waddr,dummy_ifu_wdata
);
//    //dummy test
//    input [7:0] dummy_ifu_waddr;
//    input [31:0] dummy_ifu_wdata;
//    input dummy_ifu_wen;
//    //dummy test
//    output[31:0]srcd,inst,result;
//    output [8:0]mytype;


    input clk,rst;
    //WBU-data
    wire[31:0]dnpc,srcd;//result:ALU结果
    wire jump,jalr;
    //Instruction Fetch Unit
    wire IFU_IDU_ready,IFU_IDU_valid;
    wire[31:0]ifu_idu_pc,ifu_idu_snpc;
    wire[31:0]inst;
    wire WBU_IFU_valid,WBU_IFU_ready;
    ysyx_26040117_IFU IFU1(.clk(clk),.rst(rst),
        .WBU_IFU_valid(WBU_IFU_valid),.WBU_IFU_ready(WBU_IFU_ready),.jalr(jalr),.jump(jump),.dnpc(dnpc),
        //.dummy_ifu_wen(dummy_ifu_wen),.dummy_ifu_wdata(dummy_ifu_wdata),.dummy_ifu_waddr(dummy_ifu_waddr),
        .IFU_IDU_ready(IFU_IDU_ready),.IFU_IDU_valid(IFU_IDU_valid),.inst(inst),.pc(ifu_idu_pc),.snpc(ifu_idu_snpc)
    );
    
    //Instruction Decode Unit
    wire IDU_EXU_ready,IDU_EXU_valid;
    wire[31:0]imm;
    wire[4:0]op;
    wire[8:0]mytype;//0:lui;    1:auipc;    2:jal;  3:jalr;  4:跳转;  5:load;  6:store;  7:立即数计算;  8:寄存器计算

    wire[81:0]IDU_wrapper;
    wire[4:0] rs1,rs2;
    ysyx_26040117_IDU IDU1(.clk(clk),.rst(rst),
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
    ysyx_26040117_RegisterFile Register1(.clk(clk),.rst(rst),
        .raddr1(rs1),.raddr2(rs2),.rdata1(src1),.rdata2(src2),
        .wdata(srcd),.waddr(wbu_register_rd),.wen(wbu_register_wen)
    );
    //Execution Unit
    wire EXU_WBU_ready,EXU_WBU_valid;
    wire [31:0]result;
    wire [31:0] exu_wbu_src1,exu_wbu_src2,exu_wbu_imm;
    wire [8:0] exu_wbu_mytype;
    wire [4:0] exu_wbu_op;
    wire[81:0]EXU_wrapper; 
    ysyx_26040117_EXU EXU1(.clk(clk),.rst(rst),
        .IDU_EXU_ready(IDU_EXU_ready),.IDU_EXU_valid(IDU_EXU_valid),.src1(src1),.src2(src2),.imm(imm),.op(op),.mytype(mytype),
        .IDU_wrapper(IDU_wrapper),
        .EXU_WBU_ready(EXU_WBU_ready),.EXU_WBU_valid(EXU_WBU_valid),.result(result),
        .IDU_wrapper_out(EXU_wrapper),.src1_out(exu_wbu_src1),.src2_out(exu_wbu_src2),.imm_out(exu_wbu_imm),.op_out(exu_wbu_op),.mytype_out(exu_wbu_mytype)
    );

    //WriteBack Unit
    ysyx_26040117_WBU WBU1(.clk(clk),.rst(rst),
        .EXU_WBU_ready(EXU_WBU_ready),.EXU_WBU_valid(EXU_WBU_valid),.EXU_wrapper(EXU_wrapper),.src1(exu_wbu_src1),.src2(exu_wbu_src2),.imm(exu_wbu_imm),.op(exu_wbu_op),.mytype(exu_wbu_mytype),.result(result),
        .WBU_IFU_valid(WBU_IFU_valid),.WBU_IFU_ready(WBU_IFU_ready),.srcd(srcd),.jump(jump),.dnpc(dnpc),.jalr(jalr),.rd_out(wbu_register_rd),.register_wen(wbu_register_wen)
    );
endmodule

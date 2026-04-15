module ysyx_26040117_top(clk,rst,inst,pc
);
    input clk,rst;
    input [31:0]inst;
    output wire [31:0]pc;
    wire ebreak;
    wire[4:0] rs1,rs2,rd;
    wire[31:0]imm,src1,src2,srcd,num2,result,snpc,dnpc;
    wire[3:0]op;
    wire[8:0]mytype;
    //Instruction Fetch Unit
//    ysyx_26040117_IFU IFU1();
    
    //Instruction Decode Unit
    ysyx_26040117_IDU IDU1(.inst(inst),.ebreak(ebreak),.rs1(rs1),.rs2(rs2),.rd(rd),.imm(imm),.op(op),.mytype(mytype));
    //WriteBack Unit
    assign snpc=pc+32'd4;
    assign dnpc= imm+(mytype[3]?src1:pc);
    ysyx_26040117_WBU WBU1(.clk(clk),.rst(rst),.br_token(1'b0),.ebreak(ebreak),.snpc(snpc),.dnpc(dnpc),.result(mytype[0]?imm:result),.ramdata(32'd0),.mytype(mytype),.srcd(srcd),.pc(pc));
    //Register block
    ysyx_26040117_RegisterFile Register1(.clk(clk),.wdata(srcd),.waddr(rd),.wen((~rst)&&((|mytype[3:0])||mytype[5]||(|mytype[8:7]))),.raddr1(rs1),.raddr2(rs2),.rdata1(src1),.rdata2(src2));
    //EXecution Unit
    assign num2= ({32{mytype[8]||mytype[4]}}&src2)|
                 ({32{|mytype[7:5]}}&imm);
    ysyx_26040117_EXU EXU1(.num1(src1),.num2(num2),.op(op),.result(result));
endmodule

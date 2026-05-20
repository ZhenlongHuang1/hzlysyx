module ysyx_26040117_top(clk,rst
);
    input clk,rst;
    wire ebreak;
    wire[4:0] rs1,rs2,rd;
    wire[31:0]imm,src1,src2,srcd,num2,result,pc,inst,ramdata,csr_rdata;//num2:ALU第二个操作数;  result:ALU结果; ramdata:寄存器读取值
    wire[4:0]op;
    wire[8:0]mytype;//0:lui;    1:auipc;    2:jal;  3:jalr;  4:跳转;  5:load;  6:store;  7:立即数计算;  8:寄存器计算
    wire[2:0]trap_ctrl;//0:csrr,1:ecall,2:mret
    wire[7:0]wmask;//存储器掩码
    wire ifsigned;//LB,LH,LW,SB,SH,SW
    //Instruction Fetch Unit
    ysyx_26040117_IFU IFU1(.pc(pc),.inst(inst));
    
    //Instruction Decode Unit
    ysyx_26040117_IDU IDU1(.inst(inst),.ebreak(ebreak),.rs1(rs1),.rs2(rs2),.rd(rd),.imm(imm),.op(op),.mytype(mytype),.trap_ctrl(trap_ctrl),.wmask(wmask),.ifsigned(ifsigned));
    //Control Status Register 
    ysyx_26040117_CSR CSR1(.clk(clk),.rst(rst),.trap_ctrl(trap_ctrl),.funct3(op[2:0]),.csr_addr(imm[11:0]),.src1(src1),.pc(pc),.rdata(csr_rdata));

    //WriteBack Unit
    ysyx_26040117_WBU WBU1(.clk(clk),.rst(rst),.br_token(result[0]),.ebreak(ebreak),.imm(imm),.src1(src1),.result(result),.ramdata(ramdata),.csr_rdata(csr_rdata),.trap_ctrl(trap_ctrl),.mytype(mytype),.srcd(srcd),.pc(pc));
    //Register block
    ysyx_26040117_RegisterFile Register1(.clk(clk),.wdata(srcd),.waddr(rd),.wen((~rst)&&((|mytype[3:0])||mytype[5]||(|mytype[8:7])||(trap_ctrl[0]))),.raddr1(rs1),.raddr2(rs2),.rdata1(src1),.rdata2(src2));
    //EXecution Unit
    assign num2= ({32{mytype[8]||mytype[4]}}&src2)|
                 ({32{|mytype[7:5]}}&imm);
    ysyx_26040117_EXU EXU1(.num1(src1),.num2(num2),.op(op),.result(result));
    //Load-Store Unit
    ysyx_26040117_LSU LSU1(.clk(clk),.valid(mytype[5]),.wen(mytype[6]),.raddr(result),.waddr(result),.wdata(src2),.wmask(wmask),.ifsigned(ifsigned),.rdata(ramdata));
endmodule

module ysyx_sCPU(clk,rst,h2,h1);
    input clk,rst;
    output[7:0] h2,h1;
    wire[7:0] inst,Rrd,Rrs1,Rrs2,R0,bcd_show;
    wire[1:0] opcode,rd,rs1,rs2;
    wire[3:0] imm,addr,onehot_instruct,PC_next,PC;
    assign opcode=inst[7:6];
    assign rd=inst[5:4];
    assign rs1=inst[3:2];
    assign rs2=inst[1:0];
    assign imm=inst[3:0];
    assign addr=inst[5:2];
    assign PC_next=(onehot_instruct[3]&R0!=Rrs2)?addr:PC+4'b1;
    assign onehot_instruct={opcode[1]&opcode[0],opcode[1]&~opcode[0],~opcode[1]&opcode[0],~opcode[1]&~opcode[0]};//指令译码
    ysyx_MuxKey #(2,2,8) Mux1(Rrd,opcode,{
    2'b00,Rrs1+Rrs2,
    2'b10,{4'b0,imm}
    });
    ysyx_sCPU_ROM #(4) iROM1(PC,inst);//PC指令ROM读取
    ysyx_RegFile_sCPU #(4,2,8) iReg1(.clk(clk),.rst(rst),.wen(onehot_instruct[2]|onehot_instruct[0]),.rd(rd),.rs1(rs1),.rs2(rs2),.r0(2'b0),.wdata(Rrd),.rdata1(Rrs1),.rdata2(Rrs2),.rdata0(R0));
    ysyx_Reg #(4,0) icounter(.clk(clk),.rst(rst),.din(PC_next),.dout(PC),.wen(1'b1)); 
    ysyx_Reg #(8,0) ibcd_reg(.clk(clk),.rst(rst),.din(Rrs2),.dout(bcd_show),.wen(onehot_instruct[1])); 
    ysyx_bcd7seg bcd1(bcd_show[7:4],h2,1'b0);
    ysyx_bcd7seg bcd2(bcd_show[3:0],h1,1'b0);
endmodule

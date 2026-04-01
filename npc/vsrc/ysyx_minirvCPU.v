module ysyx_minirvCPU #(ADDR_LENGTH=12)(clk,rst,Rrs2,addr2);
    input clk,rst;
    output[31:0] Rrs2,addr2;
    wire[31:0] PC,PC_next,PC_plus4,inst,addr1,ram_out,
        ram_in_shift,ram_in,Rrd,Rrs1;
    wire[7:0] ram_out_shifter;
    wire[4:0] rd,rs1,rs2;
    wire[11:0] imm1,imm3;
    wire[19:0] imm2;
    wire[2:0] funct3;wire[6:0]opcode,funct7;
    wire[3:0] instruct;
    wire[15:0] onehot_instruct;
    wire ram_wen;
    wire[3:0] byte_en;
    assign rd=inst[11:7];
    assign opcode=inst[6:0];
    assign funct3=inst[14:12];
    assign rs1=inst[19:15];
    assign rs2=inst[24:20];
    assign funct7=inst[31:25];
    assign imm1=inst[31:20];
    assign imm2=inst[31:12];
    assign imm3={funct7,rd};
    assign addr2=Rrs1+addr1;
    assign PC_plus4=PC+32'd4;
    assign PC_next=onehot_instruct[1]?{addr2[31:1],1'b0}:PC_plus4;
    assign ram_in=onehot_instruct[6]?Rrs2:ram_in_shift;
    ysyx_MuxKey #(6,4,32) iMux1(Rrd,instruct,{//执行指令
    4'd0, addr2,//ADDI
    4'd1, PC_plus4,//JALR
    4'd2, Rrs1+Rrs2,//ADD
    4'd3, {imm2,12'b0},//LUI
    4'd4, ram_out,//LW
    4'd5, {24'b0,ram_out_shifter}//LBU
    });
    ysyx_sCPU_ROM #(ADDR_LENGTH) rom1(PC[ADDR_LENGTH+1:2],inst);//PC指令ROM
    ysyx_sCPU_RAM #(ADDR_LENGTH) ram1(.clk(clk),.a(addr2[ADDR_LENGTH+1:2]),.d(ram_in),.byte_en(byte_en|{4{onehot_instruct[6]}}),.wen(ram_wen),.q(ram_out));//访存RAM存储器
    ysyx_Reg #(.WIDTH(32)) icounter1(clk,rst,PC_next,PC,1'b1);//PC计数
    ysyx_instru_decoder instru_decoder1(.opcode(opcode),.funct3(funct3),.funct7(funct7),.out(instruct),.onehot_out(onehot_instruct));//指令译码
    ysyx_RegFile iReg1(.clk(clk),.rst(rst),.wen(|onehot_instruct[5:0]),.rd(rd),.rs1(rs1),.rs2(rs2),.wdata(Rrd),.rdata1(Rrs1),.rdata2(Rrs2));//写回和读取寄存器
    ysyx_MuxKey #(4,2,32) iMux5(ram_in_shift,addr2[1:0],{//SB移位存储器输入，寄存器输出
    2'b00,Rrs2,
    2'b01,Rrs2<<8,
    2'b10,Rrs2<<16,
    2'b11,Rrs2<<24
    });
    ysyx_MuxKey #(4,2,4) iMux6(byte_en,addr2[1:0],{//SB字节控制
    2'b00,4'b0001,
    2'b01,4'b0010,
    2'b10,4'b0100,
    2'b11,4'b1000
    });
    ysyx_MuxKey #(2,2,32) iMux2(addr1,{(|onehot_instruct[1:0])|(|onehot_instruct[5:4]),(|onehot_instruct[7:6])},{//I和S type指令立即数符号拓展
    2'b10,{{20{imm1[11]}},imm1},//LW,LBU
    2'b01,{{20{imm3[11]}},imm3} //SW,SB
    });
    ysyx_MuxKey #(4,2,8) iMux3(ram_out_shifter,addr2[1:0],{//LBU指令寄存器输入
    2'b00,ram_out[7:0],
    2'b01,ram_out[15:8],
    2'b10,ram_out[23:16],
    2'b11,ram_out[31:24]
    });
    ysyx_MuxKey #(2,4,1) iMux4(ram_wen,instruct,{//存储器写使能
    4'd6,1'b1,//SW
    4'd7,1'b1 //SB
    });
endmodule

module ysyx_sCPU_RAM #(ADDR_LENGTH=12)(clk,a,d,wen,q,byte_en);
    input[ADDR_LENGTH-1:0] a;
    input clk,wen;
    input[3:0] byte_en;
    input[31:0] d;
    output [31:0] q;
    wire[3:0] byte_en_w;
    (*synthesis, ram_block*)reg[31:0] mem[(1<<(ADDR_LENGTH))-1:0];
    assign byte_en_w=byte_en&({4{wen}});
    assign q=mem[a];
    always@(posedge clk)begin
        if(byte_en_w[0])mem[a][7:0]<=d[7:0];
        if(byte_en_w[1])mem[a][15:8]<=d[15:8];
        if(byte_en_w[2])mem[a][23:16]<=d[23:16];
        if(byte_en_w[3])mem[a][31:24]<=d[31:24];
    end
endmodule

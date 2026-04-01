module ysyx_instru_decoder(opcode,funct3,funct7,onehot_out,out);
    input [6:0] opcode,funct7;
    input [2:0]funct3;
    output [15:0] onehot_out;
    output [3:0] out;
    assign onehot_out = {
    8'b0, // 高位补零
    (opcode==7'b0100011)&&(funct3==3'b000), // 8: SB
    (opcode==7'b0100011)&&(funct3==3'b010), // 7: SW
    (opcode==7'b0000011)&&(funct3==3'b100), // 6: LBU
    (opcode==7'b0000011)&&(funct3==3'b010), // 5: LW
    (opcode==7'b0110111),                   // 4: LUI
    (opcode==7'b0110011)&&(funct3==3'b000)&&(funct7==7'b00000000), // 3: ADD
    (opcode==7'b1100111)&&(funct3==3'b000), // 2: JALR
    (opcode==7'b0010011)&&(funct3==3'b000) // 1: ADDI
};
    ysyx_encode164 decoder1(onehot_out,out);
endmodule

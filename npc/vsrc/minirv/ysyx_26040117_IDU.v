module ysyx_26040117_IDU(inst,ebreak,rs1,rs2,rd,imm,op,mytype,wmask,ifsigned);
    input [31:0] inst;
    output ebreak;
    output [4:0] op;
    output [4:0] rs1,rs2,rd;
    output[31:0] imm;
    output [8:0] mytype;
    output [7:0]wmask;
    output ifsigned;
    wire type_I,type_S,type_B,type_U,type_J,type_R,type_I_compute,type_U_LUI,type_U_AUIPC,type_I_JALR,type_I_LOAD;
    wire [6:0]opcode;
    wire [2:0]funct3;
    wire [31:0]immI,immS,immB,immU,immJ;
    assign ebreak=inst==32'b00000000000100000000000001110011;
    assign opcode=inst[6:0];
    assign rd=inst[11:7];
    assign rs1=inst[19:15];
    assign rs2=inst[24:20];
    assign mytype={type_R,type_I_compute,type_S,type_I_LOAD,type_B,type_I_JALR,type_J,type_U_AUIPC,type_U_LUI};
    assign type_I_compute=(opcode==7'b0010011);//ADDI~SRAI
    assign type_I_JALR=(opcode==7'b1100111);//JALR
    assign type_I_LOAD=(opcode==7'b0000011);//LB~LHU
    assign type_U_LUI=opcode==7'b0110111;//LUI
    assign type_U_AUIPC=opcode==7'b0010111;//AUIPC
    assign type_R=(opcode==7'b0110011);//ADD~AND
    assign type_I=(type_I_JALR)||(type_I_LOAD)||(type_I_compute);
    assign type_S=(opcode==7'b0100011);//SB~SW
    assign type_B=(opcode==7'b1100011);//BEQ~BGEU
    assign type_U=type_U_LUI||type_U_AUIPC;
    assign type_J=(opcode==7'b1101111);//JAL
    
    assign immI={{20{inst[31]}},inst[31:20]};
    assign immS={{20{inst[31]}},inst[31:25],inst[11:7]};
    assign immB={{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0};
    assign immU={inst[31:12],12'b0};
    assign immJ={{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0};
    assign imm= (immI&{32{type_I}})|
                (immS&{32{type_S}})|
                (immB&{32{type_B}})|
                (immU&{32{type_U}})|
                (immJ&{32{type_J}});
    assign funct3=inst[14:12];
    assign op = {1'b1,inst[30],funct3}&{type_B,type_R||(type_I_compute&&(funct3==3'b101)),{3{type_R||type_I_compute||type_B}}};//srai,srli?
    
    assign wmask={4'b0000,{3{funct3[1]}}|{2'b0,funct3[0]} ,1'b1};//存储器掩码
    assign ifsigned=~funct3[2];
endmodule

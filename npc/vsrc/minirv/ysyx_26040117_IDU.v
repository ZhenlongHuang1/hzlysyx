module ysyx_26040117_IDU(clk,rst,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,snpc,ifu_rresp,
    IDU_EXU_ready,IDU_EXU_valid,imm,op,mytype,
    IDU_wrapper,
    rs1,rs2
);
    input clk,rst;
    //IFU_IDU
    input IFU_IDU_valid;
    output IFU_IDU_ready;
    input [31:0] inst;
    input [31:0] pc,snpc;
    input[1:0] ifu_rresp;
    //IDU_EXU
    input IDU_EXU_ready;
    output IDU_EXU_valid;
    output [4:0] op;
    output[31:0] imm;
    output [8:0] mytype;
    output[79:0]IDU_wrapper;
    assign IDU_wrapper={trap_ctrl,wmask,ifsigned,ebreak,rd,pc_out,snpc_out,ifu_rresp_out};
    //IDU-REGISTERS
    output [4:0] rs1,rs2;

    wire [2:0]trap_ctrl;
    wire [3:0]wmask;
    wire ifsigned;
    wire ebreak;
    wire [4:0] rd;
    //state machine
    wire IFU_IDU_fire,IDU_EXU_fire;
    reg state,next_state;
    localparam IDLE=1'b0,WAIT=1'b1;
    assign IFU_IDU_fire=IFU_IDU_ready&&IFU_IDU_valid;//IDU is empty,IFU pop->IDU push
    assign IDU_EXU_fire=IDU_EXU_ready&&IDU_EXU_valid;//EXU is empty,IDU pop->EXU push
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else
            state<=next_state;
    end
    always @(*) begin
        next_state=state;
        case(state)
            IDLE:if(IFU_IDU_fire)next_state=WAIT;//valid?
            WAIT:if(IDU_EXU_fire)next_state=IDLE;//ready?
        endcase
    end 
    assign IFU_IDU_ready=state==IDLE;
    assign IDU_EXU_valid=state==WAIT; 
    //FIFO
    reg[31:0] inst_reg,pc_reg,snpc_reg;//FIFO
    reg[1:0] ifu_rresp_reg;
    wire [31:0] inst_out,pc_out,snpc_out;
    wire[1:0] ifu_rresp_out;
    always @(posedge clk) begin
        if(rst)begin
            {inst_reg,pc_reg,snpc_reg,ifu_rresp_reg}<=98'h0;
        end
        else if(IFU_IDU_fire)begin
            {inst_reg,pc_reg,snpc_reg,ifu_rresp_reg}<={inst,pc,snpc,ifu_rresp};
        end
    end
    assign {inst_out,pc_out,snpc_out,ifu_rresp_out}={inst_reg,pc_reg,snpc_reg,ifu_rresp_reg};
    //function logic
    wire type_I,type_S,type_B,type_U,type_J,type_R,type_I_compute,type_U_LUI,type_U_AUIPC,type_I_JALR,type_I_LOAD,type_I_privil;
    wire [6:0]opcode;
    wire [2:0]funct3;
    wire funct3_zero;
    wire [31:0]immI,immS,immB,immU,immJ;
    assign funct3_zero=~(|funct3);
    assign ebreak=inst_out==32'b00000000000100000000000001110011;
    assign opcode=inst_out[6:0];
    assign rd=inst_out[11:7];
    assign rs1=inst_out[19:15];
    assign rs2=inst_out[24:20];
    assign trap_ctrl = {funct3_zero&(immI[11:0]==12'b001100000010),
                        funct3_zero&(immI[11:0]==12'b0),
                        ~funct3_zero}&{3{type_I_privil}};
    assign mytype={type_R,type_I_compute,type_S,type_I_LOAD,type_B,type_I_JALR,type_J,type_U_AUIPC,type_U_LUI};
    assign type_I_compute=(opcode==7'b0010011);//ADDI~SRAI
    assign type_I_JALR=(opcode==7'b1100111);//JALR
    assign type_I_LOAD=(opcode==7'b0000011);//LB~LHU
    assign type_I_privil=(opcode==7'b1110011);//CSRR,ECALL,MRET 
    assign type_U_LUI=opcode==7'b0110111;//LUI
    assign type_U_AUIPC=opcode==7'b0010111;//AUIPC
    assign type_R=(opcode==7'b0110011);//ADD~AND
    assign type_I=(type_I_JALR)||(type_I_LOAD)||(type_I_compute)||type_I_privil;
    assign type_S=(opcode==7'b0100011);//SB~SW
    assign type_B=(opcode==7'b1100011);//BEQ~BGEU
    assign type_U=type_U_LUI||type_U_AUIPC;
    assign type_J=(opcode==7'b1101111);//JAL
    
    assign immI={{20{inst_out[31]}},inst_out[31:20]};
    assign immS={{20{inst_out[31]}},inst_out[31:25],inst_out[11:7]};
    assign immB={{20{inst_out[31]}},inst_out[7],inst_out[30:25],inst_out[11:8],1'b0};
    assign immU={inst_out[31:12],12'b0};
    assign immJ={{12{inst_out[31]}},inst_out[19:12],inst_out[20],inst_out[30:21],1'b0};
    assign imm= (immI&{32{type_I}})|
                (immS&{32{type_S}})|
                (immB&{32{type_B}})|
                (immU&{32{type_U}})|
                (immJ&{32{type_J}});
    assign funct3=inst_out[14:12];
    assign op = {1'b1,inst_out[30],funct3}&{type_B,type_R||(type_I_compute&&(funct3==3'b101)),{3{type_R||type_I_compute||type_B||trap_ctrl[0]}}};//srai,srli?
    
    //assign wmask={{3{funct3[1]}}|{2'b0,funct3[0]} ,1'b1};//存储器掩码
    assign wmask={2'b0,funct3[1:0]};
    assign ifsigned=~funct3[2];
endmodule

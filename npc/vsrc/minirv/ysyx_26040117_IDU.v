module ysyx_26040117_IDU(clk,rst,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,
    IDU_EXU_ready,IDU_EXU_valid,imm,funct,mytype,
    IDU_wrapper,
    rs1,rs2
);
    input clk,rst;
    //IFU_IDU
    input IFU_IDU_valid;
    output IFU_IDU_ready;
    input [31:0] inst;
    input [31:0] pc;
    //IDU_EXU
    input IDU_EXU_ready;
    output IDU_EXU_valid;
    output [3:0] funct;
    output[31:0] imm;
    output [8:0] mytype;
    output[40:0]IDU_wrapper;
    assign IDU_wrapper={trap_ctrl,ebreak,rd,pc_out};
    assign funct={inst_out[30],inst_out[14:12]};
    //IDU-REGISTERS
    output [4:0] rs1,rs2;

    wire [2:0]trap_ctrl;
    wire ebreak;
    wire [4:0] rd;
    //state machine
    wire IFU_IDU_fire,IDU_EXU_fire;
    reg state;
    localparam IDLE=1'b0,WAIT=1'b1;
    assign IFU_IDU_fire=IFU_IDU_ready&&IFU_IDU_valid;//IDU is empty,IFU pop->IDU push
    assign IDU_EXU_fire=IDU_EXU_ready&&IDU_EXU_valid;//EXU is empty,IDU pop->EXU push
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else if(IFU_IDU_fire)
            state<=WAIT;
        else if(IDU_EXU_fire)
            state<=IDLE;
    end
    assign IFU_IDU_ready=state==IDLE;
    assign IDU_EXU_valid=state==WAIT; 
    //FIFO
    reg[31:0] inst_reg,pc_reg;//FIFO
    wire [31:0] inst_out,pc_out;
    always @(posedge clk) begin
        if(IFU_IDU_fire)begin
            {inst_reg,pc_reg}<={inst,pc};
        end
    end
    assign {inst_out,pc_out}={inst_reg,pc_reg};
    //function logic
    wire type_I,type_S,type_B,type_U,type_J,type_R,type_I_compute,type_U_LUI,type_U_AUIPC,type_I_JALR,type_I_LOAD,type_I_privil;
    wire [6:0]opcode;
    wire [2:0]funct3;
    wire funct3_zero;
    wire [31:0]immI,immS,immB,immU,immJ;
    assign funct3_zero=~(|funct3);
    assign ebreak=type_I_privil&&funct3_zero&&(immI[11:0]==12'b1);
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

`ifdef PERF_COUNTER

    reg [63:0] idu_decode_count;

    reg [63:0] idu_alu_count;
    reg [63:0] idu_alui_count;
    reg [63:0] idu_lui_count;
    reg [63:0] idu_auipc_count;
    reg [63:0] idu_load_count;
    reg [63:0] idu_store_count;
    reg [63:0] idu_branch_count;
    reg [63:0] idu_jump_count;
    reg [63:0] idu_system_count;
    reg [63:0] idu_fence_count;
    reg [63:0] idu_other_count;

    always @(posedge clk) begin
        if (rst) begin
            idu_decode_count   <= 64'd0;

            idu_alu_count      <= 64'd0;
            idu_alui_count     <= 64'd0;
            idu_lui_count      <= 64'd0;
            idu_auipc_count    <= 64'd0;
            idu_load_count     <= 64'd0;
            idu_store_count    <= 64'd0;
            idu_branch_count   <= 64'd0;
            idu_jump_count     <= 64'd0;
            idu_system_count   <= 64'd0;
            idu_fence_count    <= 64'd0;
            idu_other_count    <= 64'd0;
        end else begin
            if (IDU_EXU_fire) begin
                idu_decode_count <= idu_decode_count + 64'd1;

                case (opcode)
                    // R型、I型计算、LUI、AUIPC
                    7'b0110011://ADD~AND
                        idu_alu_count <= idu_alu_count + 64'd1;
                    7'b0010011://ADDI~SRAI
                        idu_alui_count <= idu_alui_count + 64'd1;
                    7'b0110111://LUI
                        idu_lui_count <= idu_lui_count+64'd1;
                    7'b0010111://AUIPC
                        idu_auipc_count <= idu_auipc_count + 64'd1;
                    7'b0000011://LB~LHU
                        idu_load_count <= idu_load_count + 64'd1;
                    7'b0100011://SB~SW
                        idu_store_count <= idu_store_count + 64'd1;
                    7'b1100011://BEQ~BGEU
                        idu_branch_count <= idu_branch_count + 64'd1;
                    7'b1101111,// JAL和JALR
                    7'b1100111:
                        idu_jump_count <= idu_jump_count + 64'd1;
                    7'b1110011:// CSR、ECALL、EBREAK、MRET
                        idu_system_count <= idu_system_count + 64'd1;
                    7'b0001111:// FENCE、FENCE.I
                        idu_fence_count <= idu_fence_count + 64'd1;

                    default:
                        idu_other_count <= idu_other_count + 64'd1;
                endcase
            end
        end
    end

`endif
endmodule

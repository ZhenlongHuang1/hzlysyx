module ysyx_26040117_IDU(clk,rst,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,fence_done,
    redirect_valid,EXU_IDU_wrapper,LSU_IDU_wrapper,WBU_IDU_wrapper,
    IDU_EXU_ready,IDU_EXU_valid,IDU_wrapper,
    rs1,rs2,src1,src2
);
    input clk,rst;
    //IFU_IDU
    input IFU_IDU_valid;
    output IFU_IDU_ready;
    input [31:0] inst;
    input [31:0] pc;
    input fence_done;
    //EXU/LSU/WBU-IDU
    input redirect_valid;//control risk
    input[5:0] EXU_IDU_wrapper,LSU_IDU_wrapper,WBU_IDU_wrapper;//data risk
    //IDU_EXU
    input IDU_EXU_ready;
    output IDU_EXU_valid;
    output[155:0]IDU_wrapper;

    wire [3:0] funct;
    wire [8:0] mytype;
    wire [31:0] num1,num2;
    wire [31:0] aux_num1,aux_num2;
    wire sub;
    assign IDU_wrapper={register_wen,type_fence_i,trap_info,rd,funct,mytype,num1,num2,aux_num1,aux_num2,sub};
    assign funct={inst_out[30],inst_out[14:12]};
    //IDU-REGISTERS
    input [31:0] src1,src2;
    output [4:0] rs1,rs2;
    wire [4:0] rd;
    //state machine
    wire IFU_IDU_fire,IDU_EXU_fire/* verilator public_flat_rd */;
    reg [1:0] state,next_state;
    localparam IDLE=2'b0,WAIT=2'b1,FENCE_PAUSE=2'd2,TRAP_PAUSE=2'd3;
    assign IFU_IDU_fire=IFU_IDU_ready&&IFU_IDU_valid;//IDU is empty,IFU pop->IDU push
    assign IDU_EXU_fire=IDU_EXU_ready&&IDU_EXU_valid;//EXU is empty,IDU pop->EXU push
    always @(posedge clk) begin
        if(rst||redirect_valid)
            state<=IDLE;
        else 
            state<=next_state;
    end
    always @(*) begin
        next_state=state;
        case(state)
            IDLE:if(IFU_IDU_fire) next_state=WAIT;
            WAIT:if(IDU_EXU_fire) begin
                    if(type_fence_i)
                        next_state=FENCE_PAUSE;
                    else if(type_mret||exception_valid)
                        next_state=TRAP_PAUSE;
                    else
                        next_state=IDLE;
                end
            FENCE_PAUSE:if(fence_done) next_state=IDLE;
            TRAP_PAUSE:if(redirect_valid) next_state=IDLE;//no need?
            default:next_state=IDLE;
        endcase
    end
    assign IFU_IDU_ready=state==IDLE&&!redirect_valid;
    assign IDU_EXU_valid=state==WAIT&&!redirect_valid&&!raw; 
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
    wire type_I,type_S,type_B,type_U,type_J,type_R,type_I_compute,type_U_LUI,type_U_AUIPC,type_I_JALR,type_I_LOAD,type_I_privil,type_fence_i;
    wire [6:0]opcode;
    wire [2:0]funct3;
    wire funct3_zero;
    wire [31:0]immI,immS,immB,immU,immJ,imm;
    assign funct3_zero=~(|funct3);
    assign opcode=inst_out[6:0];
    assign rd=inst_out[11:7];
    assign rs1=inst_out[19:15];
    assign rs2=inst_out[24:20];

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
    assign type_fence_i=(opcode==7'b0001111)&&(funct3==3'b001);//fence.i
    
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

    assign num1=({32{(|mytype[8:4]) ||type_csr}} & src1)|//alu,alui,load,store,branch,csrr
                 ({32{(|mytype[3:1]) || exception_valid}} & pc_out);//jalr,jal,auipc,ecall
    assign num2= ({32{mytype[8]||mytype[4]}}&src2)|//branch,alu
                 ({32{(|mytype[1:0])||(|mytype[7:5])}}&imm)|//lui,auipc,load,store,alui
                 ({29'd0,|mytype[3:2],2'd0});//jal,jalr
    assign aux_num1=({32{mytype[2]||mytype[4]}}&pc_out)|
                    ({32{mytype[3]}}&src1);
    assign aux_num2=({32{mytype[6]}}&src2)|
                     ({32{(|mytype[4:2])||type_csr}}&imm);
    wire is_slt =(~funct[2])&&funct[1];
    assign sub  =(mytype[8]&&funct[3])||((mytype[8]||mytype[7])&&is_slt);
    wire register_wen=(type_csr||(|mytype[3:0])||mytype[5]||(|mytype[8:7]))&&(rd!=5'd0);
    //Data adventure
    wire rs1_use,rs2_use;
    assign rs1_use=(|mytype[8:3])||type_csr;
    assign rs2_use=mytype[8]||mytype[6]||mytype[4];
    wire raw_exu,raw_lsu,raw_wbu;
    wire exu_rd_valid,lsu_rd_valid,wbu_rd_valid;
    wire[4:0] exu_rd,lsu_rd,wbu_rd;
    assign {exu_rd_valid,exu_rd}=EXU_IDU_wrapper;
    assign {lsu_rd_valid,lsu_rd}=LSU_IDU_wrapper;
    assign {wbu_rd_valid,wbu_rd}=WBU_IDU_wrapper;
    assign raw_exu=exu_rd_valid&&((rs1_use&&(rs1==exu_rd))|(rs2_use&&(rs2==exu_rd)));
    assign raw_lsu=lsu_rd_valid&&((rs1_use&&(rs1==lsu_rd))|(rs2_use&&(rs2==lsu_rd)));
    assign raw_wbu=wbu_rd_valid&&((rs1_use&&(rs1==wbu_rd))|(rs2_use&&(rs2==wbu_rd)));
    wire raw=(state==WAIT)&&(raw_exu||raw_lsu||raw_wbu);
    //Exception interrupt
    wire type_trap=type_I_privil&&funct3_zero;

    wire exception_illegal=1'b0;
    wire exception_breakpoint=type_trap&&(immI[11:0]==12'b1);
    wire exception_ecall=type_trap&&(immI[11:0]==12'b0);
    wire exception_valid=exception_illegal||exception_ecall||exception_breakpoint;
    wire type_mret=type_trap&&(immI[11:0]==12'b001100000010);
    wire type_csr=~funct3_zero&type_I_privil;

    wire [6:0] trap_info={exception_cause,exception_valid,type_mret,type_csr};
    reg [3:0] exception_cause;
    always @(*) begin
        exception_cause=4'd0;
        if(exception_illegal)
            exception_cause=4'd2;
        else if(exception_breakpoint)
            exception_cause=4'd3;
        else if(exception_ecall)
            exception_cause=4'd11;
    end
`ifdef PERF_COUNTER
    reg [63:0] idu_empty_count,idu_raw_count,idu_exublock_count;
    reg [63:0] idu_fence_count,idu_trap_count,idu_redirect_count;
    reg [63:0] idu_recv_count,idu_issue_count;
    always @(posedge clk)begin
        if(rst)begin
            idu_empty_count<=0;
            idu_raw_count<=0;
            idu_exublock_count<=0;
            idu_fence_count<=0;
            idu_trap_count<=0;
            idu_redirect_count<=0;
            idu_recv_count<=0;
            idu_issue_count<=0;
        end else if(redirect_valid)
            idu_redirect_count<=idu_redirect_count+1'b1;
        else begin
            case(state)
                IDLE:begin
                    if(IFU_IDU_fire)
                        idu_recv_count<=idu_recv_count+1'b1;
                    else
                        idu_empty_count<=idu_empty_count+1'b1;
                end
                WAIT:begin
                    if(raw)
                        idu_raw_count<=idu_raw_count+1'b1;
                    else if(!IDU_EXU_ready)
                        idu_exublock_count<=idu_exublock_count+1'b1;
                    else
                        idu_issue_count<=idu_issue_count+1'b1;
                end
                FENCE_PAUSE:
                    idu_fence_count<=idu_fence_count+1'b1;
                TRAP_PAUSE:
                    idu_trap_count<=idu_trap_count+1'b1;
            endcase
        end
    end
    reg [63:0] idu_raw_exu_count;
    reg [63:0] idu_raw_lsu_count;
    reg [63:0] idu_raw_wbu_count;
    always @(posedge clk)begin
        if(rst)begin
            idu_raw_exu_count<=0;
            idu_raw_lsu_count<=0;
            idu_raw_wbu_count<=0;
        end else if(state==WAIT&&!redirect_valid)begin
            if(raw_exu)
                idu_raw_exu_count<=idu_raw_exu_count+1'b1;
            if(raw_lsu)
                idu_raw_lsu_count<=idu_raw_lsu_count+1'b1;
            if(raw_wbu)
                idu_raw_wbu_count<=idu_raw_wbu_count+1'b1;
        end
    end


`endif
endmodule

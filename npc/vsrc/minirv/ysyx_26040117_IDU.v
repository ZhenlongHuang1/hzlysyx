module ysyx_26040117_IDU(clk,rst,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,fence_done,pred_taken,
    redirect_valid,EXU_IDU_wrapper,LSU_IDU_wrapper,WBU_IDU_wrapper,
    pc_out,
    IDU_EXU_ready,IDU_EXU_valid,IDU_wrapper,
    rs1,rs2,src1,src2
);
    input clk,rst;
    //IFU_IDU
    input IFU_IDU_valid;
    output IFU_IDU_ready;
    input [31:0] inst;
    input [31:0] pc;
    input fence_done,pred_taken;
    //EXU/LSU/WBU-IDU
    input redirect_valid;//control risk
    input[38:0] EXU_IDU_wrapper,LSU_IDU_wrapper;
    input[37:0] WBU_IDU_wrapper;//data risk
    //IDU-IFU
    output[31:0] pc_out/* verilator public_flat_rd */;
    //IDU_EXU
    input IDU_EXU_ready;
    output IDU_EXU_valid;
    output[158:0]IDU_wrapper;

    wire [3:0] funct;
    wire [8:0] mytype;
    wire [31:0] num1,num2;
    wire [31:0] aux_num1,aux_num2;
    wire sub;
    assign IDU_wrapper={pred_taken_out,register_wen_load,register_wen_ok,register_wen,type_fence_i,trap_info,rd,funct,mytype,num1,num2,aux_num1,aux_num2,sub};
    assign funct={inst_out[30],inst_out[14:12]};
    //IDU-REGISTERS
    input [31:0] src1,src2;
    output [4:0] rs1,rs2;
    wire [4:0] rd;
    //state machine
    wire IFU_IDU_fire,IDU_EXU_fire/* verilator public_flat_rd */;
    reg [1:0] state,next_state;
    localparam IDLE=2'b0,FENCE_PAUSE=2'd2,TRAP_PAUSE=2'd3;
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
            IDLE:if(IDU_EXU_fire) begin
                    if(type_fence_i)
                        next_state=FENCE_PAUSE;
                    else if(type_mret||exception_valid)
                        next_state=TRAP_PAUSE;
                end
            FENCE_PAUSE:if(fence_done) next_state=IDLE;
            TRAP_PAUSE:;
            default:next_state=IDLE;
        endcase
    end
    wire issue_pause=type_fence_i||type_mret||exception_valid;
    assign IFU_IDU_ready=(state==IDLE)&&(buf_count!=2'd2);
    assign IDU_EXU_valid=(state==IDLE)&&(buf_count!=2'd0)&&!raw; 
    //FIFO
    reg[62:0] idu_buf[1:0];
    wire [31:0] inst_out/* verilator public_flat_rd */;
    wire [29:0]pc_word;
    wire pred_taken_out;
    reg[1:0] buf_count;
    always @(posedge clk) begin
        if(rst||redirect_valid)begin
            buf_count<=2'd0;
        end else if((IDU_EXU_fire&&issue_pause))begin
            buf_count<=2'd0;
        end else begin
            case({IFU_IDU_fire,IDU_EXU_fire})
                2'b10:begin 
                    if(buf_count==2'd0)
                        idu_buf[0]<={pred_taken,inst,pc[31:2]};
                    else 
                        idu_buf[1]<={pred_taken,inst,pc[31:2]};
                    buf_count<=buf_count+2'd1;
                end
                2'b01:begin 
                    if(buf_count==2'd2)
                        idu_buf[0]<=idu_buf[1];
                    buf_count<=buf_count-2'd1;
                end
                2'b11:idu_buf[0]<={pred_taken,inst,pc[31:2]};
                default:;
            endcase
        end
    end
    assign {pred_taken_out,inst_out,pc_word}=idu_buf[0];
    assign pc_out={pc_word,2'b00};
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

    assign num1=({32{(|mytype[8:4]) ||type_csr}} & src1_forward)|//alu,alui,load,store,branch,csrr
                 ({32{(|mytype[3:1]) || exception_valid}} & pc_out);//jalr,jal,auipc,ecall
    assign num2= ({32{mytype[8]||mytype[4]}}&src2_forward)|//branch,alu
                 ({32{(|mytype[1:0])||(|mytype[7:5])}}&imm)|//lui,auipc,load,store,alui
                 ({29'd0,|mytype[3:2],2'd0});//jal,jalr
    assign aux_num1=({32{mytype[2]||mytype[4]}}&pc_out)|
                    ({32{mytype[3]}}&src1_forward);
    assign aux_num2=({32{mytype[6]}}&src2_forward)|
                     ({32{(|mytype[4:2])||type_csr}}&imm);
    wire is_slt =(~funct[2])&&funct[1];
    assign sub  =(mytype[8]&&funct[3])||((mytype[8]||mytype[7])&&is_slt);
    wire rd_valid=rd!=5'd0;
    wire register_wen_ok=((|mytype[3:0])||(|mytype[8:7]))&&(rd_valid);
    wire register_wen_load=rd_valid&&(mytype[5]);
    wire register_wen=register_wen_ok||register_wen_load||(rd_valid&&type_csr);
    //Data adventure
    wire rs1_use,rs2_use;
    assign rs1_use=(|mytype[8:3])||type_csr;
    assign rs2_use=mytype[8]||mytype[6]||mytype[4];
    wire exu_pending,exu_ready,lsu_pending,lsu_ready,wbu_ready;
    wire [31:0] exu_data,lsu_data,wbu_data;
    wire[4:0] exu_rd,lsu_rd,wbu_rd;
    assign {exu_data,exu_pending,exu_ready,exu_rd}=EXU_IDU_wrapper;
    assign {lsu_data,lsu_pending,lsu_ready,lsu_rd}=LSU_IDU_wrapper;
    assign {wbu_data,wbu_ready,wbu_rd}=WBU_IDU_wrapper;
    wire rs1_exu=rs1_use&&exu_pending&&(exu_rd==rs1);
    wire rs1_lsu=rs1_use&&lsu_pending&&(lsu_rd==rs1);
    wire rs1_wbu=rs1_use&&wbu_ready&&(wbu_rd==rs1);
    wire rs2_exu=rs2_use&&exu_pending&&(exu_rd==rs2);
    wire rs2_lsu=rs2_use&&lsu_pending&&(lsu_rd==rs2);
    wire rs2_wbu=rs2_use&&wbu_ready&&(wbu_rd==rs2);

    wire rs1_wait=rs1_exu?!exu_ready:rs1_lsu?!lsu_ready:1'b0;
    wire rs2_wait=rs2_exu?!exu_ready:rs2_lsu?!lsu_ready:1'b0;
    wire raw=rs1_wait||rs2_wait;

    wire rs1_sel_exu=rs1_exu;
    wire rs1_sel_lsu=!rs1_exu&&rs1_lsu;
    wire rs1_sel_wbu=!rs1_exu&&!rs1_lsu&&rs1_wbu;
    wire rs1_sel_rf =!rs1_exu&&!rs1_lsu&&!rs1_wbu;
    wire [31:0] src1_forward=
        ({32{rs1_sel_exu}}&exu_data)|
        ({32{rs1_sel_lsu}}&lsu_data)|
        ({32{rs1_sel_wbu}}&wbu_data)|
        ({32{rs1_sel_rf }}&src1);
    wire rs2_sel_exu=rs2_exu;
    wire rs2_sel_lsu=!rs2_exu&&rs2_lsu;
    wire rs2_sel_wbu=!rs2_exu&&!rs2_lsu&&rs2_wbu;
    wire rs2_sel_rf =!rs2_exu&&!rs2_lsu&&!rs2_wbu;
    wire [31:0] src2_forward=
        ({32{rs2_sel_exu}}&exu_data)|
        ({32{rs2_sel_lsu}}&lsu_data)|
        ({32{rs2_sel_wbu}}&wbu_data)|
        ({32{rs2_sel_rf }}&src2);
    
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
    reg [63:0] idu_occupied_cycles;
    reg [63:0] idu_entry_cycles;
    reg [63:0] idu_full_block_cycles;

    reg [63:0] idu_flush_cycles;
    reg [63:0] idu_pause_cycles;
    reg [63:0] idu_empty_cycles;
    reg [63:0] idu_raw_cycles;
    reg [63:0] idu_exu_block_cycles;
    reg [63:0] idu_issue_count;

    reg [63:0] idu_raw_exu_cycles;
    reg [63:0] idu_raw_lsu_cycles;
    reg [63:0] idu_raw_wbu_cycles;

    wire raw_exu=(rs1_exu||rs2_exu)&&!exu_ready;
    wire raw_lsu=((!rs1_exu&&rs1_lsu)||(!rs2_exu&&rs2_lsu))&&!lsu_ready;
    wire raw_wbu=1'b0;
    always @(posedge clk)begin
        if(rst)begin
            idu_occupied_cycles<=64'd0;
            idu_entry_cycles<=64'd0;
            idu_full_block_cycles<=64'd0;
            idu_flush_cycles<=64'd0;
            idu_pause_cycles<=64'd0;
            idu_empty_cycles<=64'd0;
            idu_raw_cycles<=64'd0;
            idu_exu_block_cycles<=64'd0;
            idu_issue_count<=64'd0;
            idu_raw_exu_cycles<=64'd0;
            idu_raw_lsu_cycles<=64'd0;
            idu_raw_wbu_cycles<=64'd0;
        end else begin
            //队列占用
            idu_entry_cycles<=idu_entry_cycles+{62'd0,buf_count};

            if(buf_count!=0)
                idu_occupied_cycles<=idu_occupied_cycles+64'd1;

            //每拍只归入一类
            if(redirect_valid)
                idu_flush_cycles<=idu_flush_cycles+64'd1;
            else if(state!=IDLE)
                idu_pause_cycles<=idu_pause_cycles+64'd1;
            else if(buf_count==0)
                idu_empty_cycles<=idu_empty_cycles+64'd1;
            else if(raw)
                idu_raw_cycles<=idu_raw_cycles+64'd1;
            else if(!IDU_EXU_ready)
                idu_exu_block_cycles<=idu_exu_block_cycles+64'd1;
            else
                idu_issue_count<=idu_issue_count+64'd1;

            //RAW来源，允许重叠
            if(!redirect_valid&&(state==IDLE)&&(buf_count!=0))begin
                if(raw_exu)
                    idu_raw_exu_cycles<=idu_raw_exu_cycles+64'd1;
                if(raw_lsu)
                    idu_raw_lsu_cycles<=idu_raw_lsu_cycles+64'd1;
                if(raw_wbu)
                    idu_raw_wbu_cycles<=idu_raw_wbu_cycles+64'd1;
            end
        end
    end
`endif
endmodule

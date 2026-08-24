module ysyx_26040117_EXU(clk,rst,
    IDU_EXU_ready,IDU_EXU_valid,src1,src2,imm,mytype,funct,
    IDU_wrapper,
    EXU_LSU_ready,EXU_LSU_valid,result,aux,IDU_wrapper_out,mytype_out,funct3,branch_decision
);
    input clk,rst;
    //IDU-EXU
    input IDU_EXU_valid;
    output IDU_EXU_ready;
    input[31:0]src1,src2,imm;
    input [8:0]mytype;
    input [3:0]funct;
    input[39:0]IDU_wrapper;
    
    //EXU-LSU
    input EXU_LSU_ready;
    output EXU_LSU_valid;
    output reg [31:0]result;
    output [31:0] aux;
    output [7:0] IDU_wrapper_out;
    output [8:0]mytype_out;
    output [2:0]funct3;
    output reg branch_decision;
    assign funct3=funct_out[2:0];

    //state machine
    wire IDU_EXU_fire,EXU_LSU_fire;
    reg state;
    localparam IDLE=0,WAIT=1;
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else if(IDU_EXU_fire)
            state<=WAIT;
        else if(EXU_LSU_fire)
            state<=IDLE;
    end
    assign IDU_EXU_ready=state==IDLE;
    assign EXU_LSU_valid=state==WAIT;
    assign IDU_EXU_fire=IDU_EXU_ready&&IDU_EXU_valid;
    assign EXU_LSU_fire=EXU_LSU_ready&&EXU_LSU_valid;
    //FIFO
    reg[7:0] IDU_wrapper_reg;
    reg [8:0] mytype_reg;
    reg [3:0] funct_reg;
    wire [3:0]funct_out;
    
    reg[31:0] num1_reg,num2_reg;
    wire[31:0] pc_in=IDU_wrapper[31:0];
    wire[2:0]trap_ctrl_in=IDU_wrapper[39:37];
    wire [31:0] num1_in,num2_in;
    assign num1_in=({32{(|mytype[8:4]) || trap_ctrl_in[0]}} & src1)|//alu,alui,load,store,branch,csrr
                 ({32{(|mytype[3:1]) || trap_ctrl_in[1]}} & pc_in);//jalr,jal,auipc,ecall
    assign num2_in= ({32{mytype[8]||mytype[4]}}&src2)|//alu,branch
                 ({32{(|mytype[7:5])||(|mytype[1:0])}}&imm)|//alui,load,store,lui,auipc
                 {29'd0,|mytype[3:2],2'd0};//jal,jalr,4
    reg [31:0] aux_num1_reg,aux_num2_reg;
    wire[31:0] aux_num1_in,aux_num2_in;
    assign aux_num1_in=({32{mytype[2]||mytype[4]}}&pc_in)|
                     ({32{mytype[3]}}&src1);
    assign aux_num2_in=({32{mytype[6]}}&src2)|
                     ({32{(|mytype[4:2])||trap_ctrl_in[0]}}&imm);
    reg sub_reg;
    wire is_slt =(~funct[2])&&funct[1];
    wire sub_in =mytype[4]||(mytype[8]&&funct[3])||((mytype[8]||mytype[7])&&is_slt);
    always @(posedge clk) begin
        if(IDU_EXU_fire)begin
            {IDU_wrapper_reg,mytype_reg,funct_reg}<={IDU_wrapper[39:32],mytype,funct};
            {num1_reg,num2_reg}<={num1_in,num2_in};
            {aux_num1_reg,aux_num2_reg}<={aux_num1_in,aux_num2_in};
            sub_reg<=sub_in;
        end
    end
    assign {IDU_wrapper_out,mytype_out,funct_out}={IDU_wrapper_reg,mytype_reg,funct_reg};
    //function 
    wire [31:0] num1,num2;
    assign num1=num1_reg;
    assign num2=num2_reg;
    wire sub,carry,zero,sless,less;
    wire[31:0] t_no_cin,result0;
    assign sub =sub_reg;
    assign t_no_cin={32{sub}}^num2;
    assign {carry,result0}={1'b0,num1}+{1'b0,t_no_cin}+sub;//adder
    assign zero=~(|result0);
    assign sless=(num1[31]^num2[31])?num1[31]:result0[31];
    assign less=~carry;
    always@(*)begin
        branch_decision=1'b0;
        case(funct_out[2:0])
            3'b000:branch_decision=zero;//BEQ
            3'b001:branch_decision=~zero;//BNE
            3'b100:branch_decision=sless;//BLT
            3'b101:branch_decision=~sless;//BGE
            3'b110:branch_decision=less;//BLTU
            3'b111:branch_decision=~less;//BGEU 
            default:branch_decision=1'd0;
        endcase
    end
    always @(*) begin
        result=result0;//load,store,jal,jalr
        if(mytype_out[8]||mytype_out[7])begin
            case(funct_out[2:0])
                3'b000:result=result0;//ADDI,ADD
                3'b010:result={31'd0,sless};//SLTI,SLT
                3'b011:result={31'd0,less};//SLTIU,SLTU
                3'b100:result=num1^num2;//XORI,XOR
                3'b110:result=num1|num2;//ORI,OR
                3'b111:result=num1&num2;//ANDI,AND
                3'b001:result=num1<<(num2[4:0]);//SLLI,SLL
                3'b101:begin 
                    if(funct_out[3])
                        result=$signed(num1)>>>(num2[4:0]);//SRAI,SRA
                    else
                        result=num1>>(num2[4:0]);//SRLI,SRL
                end
                default:result=32'd0;
            endcase
        end
    end

    wire[31:0] aux_num1,aux_num2,aux0;
    assign aux_num1=aux_num1_reg;
    assign aux_num2=aux_num2_reg;
    assign aux0=aux_num1+aux_num2;
    assign aux={aux0[31:1],aux0[0]&&~mytype_out[3]};
endmodule

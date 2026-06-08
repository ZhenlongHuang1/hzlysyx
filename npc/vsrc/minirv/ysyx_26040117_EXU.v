module ysyx_26040117_EXU(clk,rst,
    IDU_EXU_ready,IDU_EXU_valid,src1,src2,imm,mytype,op,
    IDU_wrapper,
    EXU_WBU_ready,EXU_WBU_valid,result,IDU_wrapper_out,src1_out,src2_out,imm_out,mytype_out,op_out
);
    input clk,rst;
    //IDU-EXU
    input IDU_EXU_valid;
    output IDU_EXU_ready;
    input[31:0]src1,src2,imm;
    input [8:0]mytype;
    input [4:0]op;
    input[78:0]IDU_wrapper;
    
    //EXU-WBU
    input EXU_WBU_ready;
    output EXU_WBU_valid;
    output reg [31:0]result;
    output[78:0] IDU_wrapper_out;
    output[31:0]src1_out,src2_out,imm_out;
    output [8:0]mytype_out;
    output [4:0]op_out;


    //state machine
    wire IDU_EXU_fire,EXU_WBU_fire;
    reg state,next_state;
    localparam IDLE=0,WAIT=1;
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else
            state<=next_state;
    end
    always @(*) begin
        next_state=state;
        case(state)
            IDLE:if(IDU_EXU_fire)next_state=WAIT;
            WAIT:if(EXU_WBU_fire)next_state=IDLE;
        endcase
    end
    assign IDU_EXU_ready=state==IDLE;
    assign EXU_WBU_valid=state==WAIT;
    assign IDU_EXU_fire=IDU_EXU_ready&&IDU_EXU_valid;
    assign EXU_WBU_fire=EXU_WBU_ready&&EXU_WBU_valid;
    //FIFO
    reg[78:0] IDU_wrapper_reg;
    reg [31:0] src1_reg,src2_reg,imm_reg;
    reg [8:0] mytype_reg;
    reg [4:0] op_reg;
    always @(posedge clk) begin
        if(rst)begin
            {IDU_wrapper_reg,src1_reg,src2_reg,imm_reg,mytype_reg,op_reg}<=189'h0;
        end else if(IDU_EXU_fire)begin
            {IDU_wrapper_reg,src1_reg,src2_reg,imm_reg,mytype_reg,op_reg}<={IDU_wrapper,src1,src2,imm,mytype,op};
        end
    end
    assign {IDU_wrapper_out,src1_out,src2_out,imm_out,mytype_out,op_out}={IDU_wrapper_reg,src1_reg,src2_reg,imm_reg,mytype_reg,op_reg};
    //function 
    wire [31:0] num1,num2;
    assign num1=src1_out;
    assign num2= ({32{mytype_out[8]||mytype_out[4]}}&src2_out)|
                 ({32{|mytype_out[7:5]}}&imm_out);
    wire cin,carry,overflow,zero,sless,less;
    wire[31:0] t_no_cin,result0;
    assign cin=(op_out==5'b00010)||(op_out==5'b00011)||op_out[4]||op_out[3];//SLTI,SLT||SLTIU,SLTU
    assign t_no_cin={32{cin}}^num2;
    assign {carry,result0}=num1+t_no_cin+cin;//adder
    assign overflow=(num1[31]==t_no_cin[31])&&(result0[31]!=num1[31]);
    assign zero=~(|result0);
    assign sless=overflow^result0[31];
    assign less=~carry;
    always@(*)begin
        case(op_out)
            5'b10000:result={31'd0,zero};//BEQ
            5'b10001:result={31'd0,~zero};//BNE
            5'b10100:result={31'd0,sless};//BLT
            5'b10101:result={31'd0,~sless};//BGE
            5'b10110:result={31'd0,less};//BLTU
            5'b10111:result={31'd0,~less};//BGEU 
            5'b00000,5'b01000:result=result0;//ADDI,ADD,all other not ALU/condition commands
            5'b00010:result={31'd0,sless};//SLTI,SLT
            5'b00011:result={31'd0,less};//SLTIU,SLTU
            5'b00100:result=num1^num2;//XORI,XOR
            5'b00110:result=num1|num2;//ORI,OR
            5'b00111:result=num1&num2;//ANDI,AND
            5'b00001:result=num1<<(num2[4:0]);//SLLI,SLL
            5'b00101:result=num1>>(num2[4:0]);//SRLI,SRL
            5'b01101:result=$signed(num1)>>>(num2[4:0]);//SRAI
            default:result=32'd0;
        endcase
    end
endmodule

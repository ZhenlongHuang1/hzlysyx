module ysyx_26040117_EXU(clk,rst,
    IDU_EXU_ready,IDU_EXU_valid,src1,src2,imm,mytype,funct,
    IDU_wrapper,
    EXU_WBU_ready,EXU_WBU_valid,result,IDU_wrapper_out,src1_out,src2_out,imm_out,mytype_out,funct_out
);
    input clk,rst;
    //IDU-EXU
    input IDU_EXU_valid;
    output IDU_EXU_ready;
    input[31:0]src1,src2,imm;
    input [8:0]mytype;
    input [3:0]funct;
    input[40:0]IDU_wrapper;
    
    //EXU-WBU
    input EXU_WBU_ready;
    output EXU_WBU_valid;
    output reg [31:0]result;
    output[40:0] IDU_wrapper_out;
    output[31:0]src1_out,src2_out,imm_out;
    output [8:0]mytype_out;
    output [3:0]funct_out;

    //state machine
    wire IDU_EXU_fire,EXU_WBU_fire;
    reg state;
    localparam IDLE=0,WAIT=1;
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else if(IDU_EXU_fire)
            state<=WAIT;
        else if(EXU_WBU_fire)
            state<=IDLE;
    end
    assign IDU_EXU_ready=state==IDLE;
    assign EXU_WBU_valid=state==WAIT;
    assign IDU_EXU_fire=IDU_EXU_ready&&IDU_EXU_valid;
    assign EXU_WBU_fire=EXU_WBU_ready&&EXU_WBU_valid;
    //FIFO
    reg[40:0] IDU_wrapper_reg;
    reg [31:0] src1_reg,src2_reg,imm_reg;
    reg [8:0] mytype_reg;
    reg [3:0] funct_reg;
    wire [31:0] pc_out;
    always @(posedge clk) begin
        if(IDU_EXU_fire)begin
            {IDU_wrapper_reg,src1_reg,src2_reg,imm_reg,mytype_reg,funct_reg}<={IDU_wrapper,src1,src2,imm,mytype,funct};
        end
    end
    assign {IDU_wrapper_out,src1_out,src2_out,imm_out,mytype_out,funct_out}={IDU_wrapper_reg,src1_reg,src2_reg,imm_reg,mytype_reg,funct_reg};
    assign pc_out=IDU_wrapper_reg[31:0];
    //function 
    wire [31:0] num1,num2,normal_num2;
    wire is_link = mytype_out[3]||mytype_out[2];//jal,jalr
    wire is_slt  =(~funct_out[2])&&funct_out[1];
    assign num1=is_link?pc_out:src1_out;
    assign num2=is_link?32'd4:normal_num2;
    assign normal_num2= ({32{mytype_out[8]||mytype_out[4]}}&src2_out)|
                 ({32{|mytype_out[7:5]}}&imm_out);

    wire sub,carry,overflow,zero,sless,less;
    wire[31:0] t_no_cin,result0;
    assign sub =mytype_out[4]||(mytype_out[8]&&funct_out[3])||((mytype_out[8]||mytype_out[7])&&is_slt);
    assign t_no_cin={32{sub}}^num2;
    assign {carry,result0}=num1+t_no_cin+sub;//adder
    assign overflow=(num1[31]==t_no_cin[31])&&(result0[31]!=num1[31]);
    assign zero=~(|result0);
    assign sless=overflow^result0[31];
    assign less=~carry;
    always@(*)begin
        result=result0;//load,store,jal,jalr
        if(mytype_out[4])begin
            case(funct_out[2:0])
                3'b000:result={31'd0,zero};//BEQ
                3'b001:result={31'd0,~zero};//BNE
                3'b100:result={31'd0,sless};//BLT
                3'b101:result={31'd0,~sless};//BGE
                3'b110:result={31'd0,less};//BLTU
                3'b111:result={31'd0,~less};//BGEU 
                default:result=32'd0;
            endcase
        end else if(mytype_out[8]||mytype_out[7])begin
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
endmodule

module ysyx_26040117_EXU(clk,rst,
    IDU_EXU_ready,IDU_EXU_valid,mytype,funct,num1,num2,aux_num1,aux_num2,IDU_wrapper,sub,
    EXU_LSU_ready,EXU_LSU_valid,result,aux,IDU_wrapper_out,mytype_out,funct3,branch_decision
);
    input clk,rst;
    //IDU-EXU
    input IDU_EXU_valid;
    output IDU_EXU_ready;
    input [8:0]mytype;
    input [3:0]funct;
    input [7:0]IDU_wrapper;
    input[31:0] num1,num2,aux_num1,aux_num2;
    input sub;
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
    reg [31:0] aux_num1_reg,aux_num2_reg;
    reg sub_reg;
    always @(posedge clk) begin
        if(IDU_EXU_fire)begin
            {IDU_wrapper_reg,mytype_reg,funct_reg}<={IDU_wrapper,mytype,funct};
            {num1_reg,num2_reg}<={num1,num2};
            {aux_num1_reg,aux_num2_reg}<={aux_num1,aux_num2};
            sub_reg<=sub;
        end
    end
    assign {IDU_wrapper_out,mytype_out,funct_out}={IDU_wrapper_reg,mytype_reg,funct_reg};
    wire sub_out;
    assign sub_out =sub_reg;
    wire [31:0] num1_out,num2_out;
    assign num1_out=num1_reg;
    assign num2_out=num2_reg;
    //result function
    wire carry,sless,less;
    wire[31:0] t_no_cin,result0;
    assign t_no_cin={32{sub_out}}^num2_out;
    assign {carry,result0}={1'b0,num1_out}+{1'b0,t_no_cin}+sub_out;//adder
    assign sless=(num1_out[31]^num2_out[31])?num1_out[31]:result0[31];
    assign less=~carry;
    
    wire signed [32:0] shift_src={funct_out[3]&num1_out[31],num1_out};
    wire [32:0] shift_tmp=$signed(shift_src)>>>num2_out[4:0];
    always @(*) begin
        result=result0;//load,store,jal,jalr
        if(mytype_out[8]||mytype_out[7])begin
            case(funct_out[2:0])
                3'b000:result=result0;//ADDI,ADD
                3'b010:result={31'd0,sless};//SLTI,SLT
                3'b011:result={31'd0,less};//SLTIU,SLTU
                3'b100:result=num1_out^num2_out;//XORI,XOR
                3'b110:result=num1_out|num2_out;//ORI,OR
                3'b111:result=num1_out&num2_out;//ANDI,AND
                3'b001:result=num1_out<<(num2_out[4:0]);//SLLI,SLL
                3'b101:result=shift_tmp[31:0];//1:SRAI,SRA;0:SRLI,SRL
                default:result=32'd0;
            endcase
        end
    end
    //branch function
    wire cmp_eq=num1_out==num2_out;
    wire cmp_lts=$signed(num1_out)<$signed(num2_out);
    wire cmp_ltu=num1_out<num2_out;
    reg branch_decision0;
    always@(*)begin
        branch_decision0=1'b0;
        case(funct_out[2:1])
            2'b00:branch_decision0=cmp_eq;//BEQ,BNE
            2'b10:branch_decision0=cmp_lts;//BLT,BGE
            2'b11:branch_decision0=cmp_ltu;//BLTU,BGEU
            default:branch_decision0=1'd0;
        endcase
    end
    assign branch_decision=funct_out[0]^branch_decision0;
    //aux function
    wire[31:0] aux_num1_out,aux_num2_out,aux0;
    assign aux_num1_out=aux_num1_reg;
    assign aux_num2_out=aux_num2_reg;
    assign aux0=aux_num1_out+aux_num2_out;
    assign aux={aux0[31:1],aux0[0]&&~mytype_out[3]};
endmodule

module ysyx_26040117_EXU(num1,num2,op,result);
    input [31:0] num1,num2;
    input [4:0]op;
    output reg [31:0]result;
    wire cin,carry,overflow,zero;
    wire[31:0] t_no_cin,result0;
    assign cin=(op==5'b00010)||(op==5'b00011)||op[4];//SLTI,SLT||SLTIU,SLTU
    assign t_no_cin={32{cin}}^num2;
    assign {carry,result0}=num1+t_no_cin+cin;//adder
    assign overflow=(num1[31]==t_no_cin[31])&&(result0[31]!=num1[31]);
    assign zero=~(|result0);
    always@(*)begin
        case(op)
            5'b10000:result={31'd0,zero};//BEQ
            5'b10001:result={31'd0,~zero};//BNE
            5'b00000:result=result0;//ADDI,ADD,all other not ALU/condition commands
            5'b00010:result={31'd0,overflow^result0[31]};//SLTI,SLT
            5'b00011:result={31'd0,~carry};//SLTIU,SLTU
            5'b00100:result=num1^num2;//XORI,XOR
            5'b00110:result=num1|num2;//ORI,OR
            5'b00111:result=num1&num2;//ANDI,AND
            5'b00001:result=num1<<(num2[4:0]);//SLLI,SLL
            5'b00101:result=num1>>(num2[4:0]);//SRLI,SRL
            5'b01101:result=num1>>>(num2[4:0]);//SRAI,SRA
            default:result=32'd0;
        endcase
    end
endmodule

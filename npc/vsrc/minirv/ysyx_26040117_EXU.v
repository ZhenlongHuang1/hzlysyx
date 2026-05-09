module ysyx_26040117_EXU(num1,num2,op,result);
    input [31:0] num1,num2;
    input [3:0]op;
    output reg [31:0]result;
    wire cin,carry,overflow;
    wire[31:0] t_no_cin,result0;
    assign cin=(op==4'b0010)||(op==4'b0011);//SLTI,SLT||SLTIU,SLTU
    assign t_no_cin={32{cin}}^num2;
    assign {carry,result0}=num1+t_no_cin+cin;
    assign overflow=(num1[31]==t_no_cin[31])&&(result0[31]!=num1[31]);

    always@(*)begin
        case(op)
            4'b0000:result=result0;//ADDI,ADD,all other not ALU/condition commands
            4'b0010:result={31'd0,overflow^result0[31]};//SLTI,SLT
            4'b0011:result={31'd0,~carry};//SLTIU,SLTU
            default:result=32'd0;
        endcase
    end
endmodule

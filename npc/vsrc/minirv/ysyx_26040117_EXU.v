module ysyx_26040117_EXU(num1,num2,op,result);
    input [31:0] num1,num2;
    input [3:0]op;
    output[31:0]result;
    ysyx_26040117_MuxKey #(1,4,32) i1(result,op,{
    4'b0000,num1+num2//ADD
    });
endmodule

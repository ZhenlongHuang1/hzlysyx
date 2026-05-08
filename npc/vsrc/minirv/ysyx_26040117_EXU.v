module ysyx_26040117_EXU(num1,num2,op,result);
    input [31:0] num1,num2;
    input [3:0]op;
    output reg [31:0]result;
    always@(*)begin
        case(op)
            4'b0000:result=num1-num2;
            default:result=32'd0;
        endcase
    end
endmodule

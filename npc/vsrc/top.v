module top(input clk, input rst, input in, output out);
    wire t0;
    reg t1;
    ysyx_26040117_Reg r1(clk, rst, in, t0, 1'b1);
    always@(negedge clk)begin
        if(rst)
            t1<=0;
        else
            t1<=t0;
    end
    ysyx_26040117_Reg r3(clk, rst, t1, out, 1'b1);
endmodule

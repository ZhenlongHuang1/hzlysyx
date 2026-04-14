module ysyx_26040117_LFshifter(
    input clk,
    input rst,
    output[15:0] h
);
    wire[2:0] sel;
    wire[7:0] Q;
    assign sel=rst?3'b001:3'b101;
    ysyx_26040117_shifter #(8) i0(clk,1'b0,Q[0]^Q[2]^Q[3]^Q[4],sel,8'b00000001,Q);
    ysyx_26040117_bcd7seg i1(Q[3:0],h[7:0],0);
    ysyx_26040117_bcd7seg i2(Q[7:4],h[15:8],0);

endmodule

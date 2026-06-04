module ysyx_26040117_LFshifter(clk,rst,
    outQ
);
    input clk,rst;
    output reg [7:0] outQ;
    always @(posedge clk) begin
        if(rst)
            outQ<=8'd1;
        else 
            outQ<={outQ[0]^outQ[2]^outQ[3]^outQ[4],outQ[7:1]};
    end
endmodule

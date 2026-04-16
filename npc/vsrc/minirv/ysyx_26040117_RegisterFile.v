module ysyx_26040117_RegisterFile #(ADDR_WIDTH = 5, DATA_WIDTH = 32) (
    clk,wdata,waddr,wen,raddr1,raddr2,rdata1,rdata2
);
    input clk,wen;
    input [ADDR_WIDTH-1:0] waddr,raddr1,raddr2;
    input [DATA_WIDTH-1:0] wdata;
    output [DATA_WIDTH-1:0] rdata1,rdata2;
    wire nequal0,nequal1,nequal2;
    assign nequal0=(|waddr);
    assign nequal1=(|raddr1);
    assign nequal2=(|raddr2);
    reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
    always @(posedge clk) begin
        if (wen&&nequal0) rf[waddr] <= wdata;
    end
    assign rdata1=nequal1?rf[raddr1]:{DATA_WIDTH{1'b0}};
    assign rdata2=nequal2?rf[raddr2]:{DATA_WIDTH{1'b0}};
    export "DPI-C" function get_a0;
    function int get_a0;
        return rf[10];
    endfunction
endmodule

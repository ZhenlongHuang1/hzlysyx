module ysyx_26040117_RegisterFile #(ADDR_WIDTH = 4, DATA_WIDTH = 32) (clk,rst,
    raddr1,raddr2,rdata1,rdata2,
    wdata,waddr,wen
);
    input clk,rst;
    input wen;
    input [ADDR_WIDTH-1:0] waddr,raddr1,raddr2;
    input [DATA_WIDTH-1:0] wdata;
    output [DATA_WIDTH-1:0] rdata1,rdata2;
    wire nequal0,nequal1,nequal2;
    assign nequal0=(|waddr);
    assign nequal1=(|raddr1);
    assign nequal2=(|raddr2);
    reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
    integer i;
    always @(posedge clk) begin
        if(rst)begin
            for(i=0;i<2**ADDR_WIDTH;i=i+1)begin
                rf[i]<={DATA_WIDTH{1'b0}};
            end
        end
        else if (wen&&nequal0)begin
            rf[waddr] <= wdata;
        end
    end
    assign rdata1=nequal1?rf[raddr1]:{DATA_WIDTH{1'b0}};
    assign rdata2=nequal2?rf[raddr2]:{DATA_WIDTH{1'b0}};
endmodule

`include "ysyx_26040117__defines.vh"
module ysyx_26040117_CLINT(clk,rst,
    arvalid,arready,araddr,
    rvalid,rready,rdata,rresp,
    awvalid,awready,awaddr,
    wvalid,wready,wdata,wstrb,
    bvalid,bready,bresp
);
    input clk,rst;
    //read
    input arvalid;
    output arready;
    input[31:0]araddr;

    output reg rvalid;
    input rready;
    output reg [31:0]rdata;
    output[1:0] rresp;
    //write
    input awvalid;
    output awready;
    input [31:0] awaddr;

    input wvalid;
    output wready;
    input [31:0]wdata;
    input [3:0]wstrb;

    output bvalid;
    input bready;
    output[1:0] bresp;
    //read
    wire arfire,rfire;
    assign arfire=arvalid&&arready;
    assign rfire=rvalid&&rready;
    assign arready=!rvalid;
    assign rresp=2'b00;
    //write
    assign awready=1'b0;
    assign wready=1'b0;
    assign bvalid=1'b0;
    assign bresp=2'b0;
    always @(posedge clk) begin
        if(rst) rvalid<=1'b0;
        else if(rfire) 
            rvalid<=1'b0;
        else if(arfire) begin
            rvalid<=1'b1;
            if(araddr==32'h0200bff8)
                rdata<=mtime[31:0];
            else if(araddr==32'h0200bffc)
                rdata<=mtime[63:32];
        end
    end
    //function
    reg [63:0]mtime;
    always @(posedge clk) begin
        if(rst)mtime<=64'd0;
        else begin
            mtime<=mtime+64'd1;
        end
    end
endmodule

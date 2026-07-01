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

    output reg bvalid;
    input bready;
    output[1:0] bresp;
    //read
    reg ar_done;
    wire ar_ok;
    wire arfire,rfire;
    assign arfire=arvalid&&arready;
    assign rfire=rvalid&&rready;
    always @(posedge clk) begin
        if(rst) ar_done<=1'd0;
        else begin
            if(rfire) ar_done<=1'd0;
            else if(arfire) ar_done<=1'b1;
        end
    end
    assign ar_ok=arfire?1'b1:ar_done;
    assign arready=!rvalid;
    //read FIFO
    reg [31:0] araddr_reg;
    wire [31:0] araddr_out;
    always @(posedge clk) begin
        if(rst) araddr_reg<=32'd0;
        else if(arfire) araddr_reg<=araddr;
    end
    assign araddr_out=arfire?araddr:araddr_reg;
    always @(posedge clk) begin
        if(rst) rvalid<=1'b0;
        else begin
            if(rfire) rvalid<=1'b0;
            else if(ar_ok&&!rvalid) rvalid<=1'b1;
        end
    end
    assign rresp=2'b00;
    //function
    reg [63:0]mtime;
    always @(posedge clk) begin
        if(rst)mtime<=64'd0;
        else mtime<=mtime+64'd1;
    end
    always @(posedge clk) begin
        if(rst)begin
        end else if(ar_ok&&!rvalid)begin
            if(araddr_out[2]==1'b0)rdata<=mtime[31:0];
            else rdata<=mtime[63:32];
        end
    end
endmodule

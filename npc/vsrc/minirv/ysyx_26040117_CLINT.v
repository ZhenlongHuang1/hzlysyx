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
                rdata<=mtime_lo;
            else if(araddr==32'h0200bffc)
                rdata<=mtime_hi;
        end
    end
    //function
    reg [31:0]mtime_lo,mtime_hi;
    wire [63:0] mtime_next;

    ysyx_26040117_Incrementer #(.WIDTH(64)) mtime_inc(
        .data({mtime_hi,mtime_lo}),
        .result(mtime_next)
    );
    always @(posedge clk)begin
        if(rst)
            {mtime_hi,mtime_lo}<=64'd0;
        else
            {mtime_hi,mtime_lo}<=mtime_next;
    end
    /*
    wire [31:0] lo_inc=mtime_lo+32'd1;
    wire [31:0] hi_inc=mtime_hi+32'd1;
    wire lo_wrap=&mtime_lo;
    always @(posedge clk) begin
        if(rst)begin
            mtime_lo<=32'd0;
            mtime_hi<=32'd0;
        end else begin
            mtime_lo<=lo_inc;
            if(lo_wrap)
                mtime_hi<=hi_inc;
        end
    end
    /*
    always @(posedge clk) begin
        if(rst)
            {mtime_hi,mtime_lo}<=64'd0;
        else 
            {mtime_hi,mtime_lo}<={mtime_hi,mtime_lo}+64'd1;
    end
    */
endmodule

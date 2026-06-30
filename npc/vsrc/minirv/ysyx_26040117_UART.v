`include "ysyx_26040117__defines.vh"
module ysyx_26040117_UART(clk,rst,
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

    output rvalid;
    input rready;
    output [31:0]rdata;
    output rresp;
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
    output bresp;
    //write
    reg aw_done,w_done;
    wire aw_ok,w_ok,write_ok;
    wire awfire,wfire,bfire;
    assign awfire=awvalid&&awready;
    assign wfire=wvalid&&wready;
    assign bfire=bvalid&&bready;
    always @(posedge clk) begin
        if(rst) {aw_done,w_done}<=2'd0;
        else begin
            if(bfire) {aw_done,w_done}<=2'd0;
            else begin
                if(awfire) aw_done<=1'b1;
                if(wfire) w_done<=1'b1;
            end
        end
    end
    assign aw_ok=awfire?1'b1:aw_done;
    assign w_ok=wfire?1'b1:w_done;
    assign write_ok=w_ok&&aw_ok;
    assign awready=awvalid;
    assign wready=wvalid;
    //write FIFO
    reg [31:0] wdata_reg,awaddr_reg;
    reg [3:0] wstrb_reg;
    wire [31:0] wdata_out,awaddr_out;
    wire [3:0] wstrb_out;
    //aw
    always @(posedge clk) begin
        if(rst) awaddr_reg<=32'd0;
        else if(awfire) awaddr_reg<=awaddr;
    end
    assign awaddr_out=awfire?awaddr:awaddr_reg;
    //w
    always @(posedge clk) begin
        if(rst) {wdata_reg,wstrb_reg}<=36'd0;
        else if(wfire) {wdata_reg,wstrb_reg}<={wdata,wstrb};
    end
    assign {wdata_out,wstrb_out}=wfire?{wdata,wstrb}:{wdata_reg,wstrb_reg};
    always @(posedge clk) begin
        if(rst)begin
        end else if(write_ok&&!bvalid)begin
            $write("%c",wdata_out[7:0]);            
        end
    end
    always @(posedge clk) begin
        if(rst) bvalid<=1'b0;
        else begin
            if(bfire) bvalid<=1'b0;
            else if(write_ok&&!bvalid) bvalid<=1'b1;
        end
    end
    assign bresp=(awaddr_out>=32'h10000000&&awaddr_out<=32'h10000004);
endmodule

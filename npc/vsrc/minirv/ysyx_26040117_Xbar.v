`include "ysyx_26040117__defines.vh"
module ysyx_26040117_Xbar(clk,rst,
    arvalid,arready,araddr,
    rvalid,rready,rdata,rresp,
    awvalid,awready,awaddr,
    wvalid,wready,wdata,wstrb,
    bvalid,bready,bresp
`ifdef STA_MODE
    ,dummy_wen,dummy_waddr,dummy_wdata
`endif
);
`ifdef STA_MODE
    //dummy
    input dummy_wen;
    input [31:0] dummy_wdata;
    input [7:0] dummy_waddr;
`endif
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

    output bvalid;
    input bready;
    output bresp;
    //choose
    wire dec_uart,dec_mem_w,sel_uart,sel_mem_w,sel_mtime;
    reg reg_uart,reg_mem_w,w_routed;
    assign dec_uart=(awaddr>=32'h10000000&&awaddr<=32'h10000004)&&awvalid;
    assign dec_mem_w=(awaddr>=32'h80000000&&awaddr<=32'h88000000&&awvalid);
    wire awfire,wfire;
    assign awfire=awvalid&&awready;
    assign wfire=wvalid&&wready;
    always @(posedge clk) begin
        if(rst)begin
            reg_uart<=0;
            reg_mem_w<=0;
            w_routed<=0;
        end else if(awfire&&~wfire)begin
            reg_uart<=dec_uart;
            reg_mem_w<=dec_mem_w;
            w_routed<=1;
        end else if(wfire)begin
            reg_uart<=0;
            reg_mem_w<=0;
            w_routed<=0;
        end
    end
    assign sel_uart=w_routed?reg_uart:dec_uart;
    assign sel_mem_w=w_routed?reg_mem_w:dec_mem_w;
    //uart    
    wire uart_arready_dummy,uart_rvalid_dummy,uart_rresp_dummy;
    wire[31:0] uart_rdata_dummy;
    wire uart_awvalid,uart_awready,uart_wvalid,uart_wready,uart_bvalid,uart_bresp;
    assign uart_awvalid=dec_uart;
    assign uart_wvalid=sel_uart&&wvalid;
    
    ysyx_26040117_UART uart1(.clk(clk),.rst(rst),
        .arvalid(1'b0),.arready(uart_arready_dummy),.araddr(32'd0),
        .rvalid(uart_rvalid_dummy),.rready(1'b0),.rdata(uart_rdata_dummy),.rresp(uart_rresp_dummy),
        .awvalid(uart_awvalid),.awready(uart_awready),.awaddr(awaddr),
        .wvalid(uart_wvalid),.wready(uart_wready),.wdata(wdata),.wstrb(wstrb),
        .bvalid(uart_bvalid),.bready(bready),.bresp(uart_bresp)
);
    //mem
    wire mem_awvalid,mem_awready,mem_wvalid,mem_wready,mem_bvalid,mem_bresp;
    assign mem_awvalid=dec_mem_w;
    assign mem_wvalid=sel_mem_w&&wvalid;
    ysyx_26040117_MEM mem1(.clk(clk),.rst(rst),
        .arvalid(arvalid),.arready(arready),.araddr(araddr),
        .rvalid(rvalid),.rready(rready),.rdata(rdata),.rresp(rresp),
        .awvalid(mem_awvalid),.awready(mem_awready),.awaddr(awaddr),
        .wvalid(mem_wvalid),.wready(mem_wready),.wdata(wdata),.wstrb(wstrb),
        .bvalid(mem_bvalid),.bready(bready),.bresp(mem_bresp)
`ifdef STA_MODE
        ,.dummy_wen(dummy_wen),.dummy_wdata(dummy_wdata),.dummy_waddr(dummy_waddr)
`endif
);
    //output
    assign awready=(dec_uart&&uart_awready)||(dec_mem_w&&mem_awready);    
    assign wready=(sel_uart&&uart_wready)||(sel_mem_w&&mem_wready); 
    assign bvalid=uart_bvalid||mem_bvalid;
    assign bresp=(uart_bvalid&&uart_bresp)|(mem_bvalid&&mem_bresp);

endmodule

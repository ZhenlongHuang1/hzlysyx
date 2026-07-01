`include "ysyx_26040117__defines.vh"
module ysyx_26040117_MEM(clk,rst,
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
    wire arfire,rfire;
    assign rfire=rvalid&&rready;
    assign arfire=arvalid&&arready;
    //read FIFO
    reg [31:0] araddr_reg;
    wire [31:0] araddr_out;
    always @(posedge clk) begin
        if(rst) araddr_reg<=32'd0;
        else if(arfire) araddr_reg<=araddr;
    end
    assign araddr_out=arfire?araddr:araddr_reg;
    //read function
    wire r_notbusy;
    ysyx_26040117_counter counter1(.clk(clk),.rst(rst),.wen(arvalid),.delay_over(arready));
    ysyx_26040117_counter counter2(.clk(clk),.rst(rst),.wen(arfire),.delay_over(r_notbusy));
`ifdef STA_MODE

`else
    import "DPI-C" function int unsigned paddr_read(input int unsigned raddr);
    always @(posedge clk) begin
        if(rst)begin
            rdata<=32'h0;
        end else if(r_notbusy&&!rvalid)begin  //只在读取有效时改变
            rdata<= paddr_read(araddr_out);
        end
    end
`endif
    always @(posedge clk) begin
        if(rst)begin
            rvalid<=1'b0;
        end else begin
            if(rfire)
                rvalid<=1'b0;
            else if(r_notbusy&&!rvalid)
                rvalid<=1'b1;
        end
    end
    assign rresp=2'b00;
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
            if(bfire)begin
                aw_done<=1'b0;
                w_done<=1'b0;
            end else begin
                if(awfire) aw_done<=1'b1;
                if(wfire) w_done<=1'b1;
            end
        end
    end
    assign aw_ok=awfire?1'b1:aw_done;
    assign w_ok=wfire?1'b1:w_done;
    assign write_ok=w_ok&&aw_ok;
    //write FIFO
    reg [31:0] awaddr_reg,wdata_reg;
    reg [3:0] wstrb_reg;
    wire [31:0] awaddr_out,wdata_out;
    wire [3:0] wstrb_out;
    //aw
    always @(posedge clk) begin
        if(rst) awaddr_reg<=32'd0;
        else if(awfire) awaddr_reg<=awaddr;
    end
    assign awaddr_out=awfire?awaddr:awaddr_reg;
    //w
    always @(posedge clk) begin
        if(rst){wdata_reg,wstrb_reg}<=36'd0;
        else if(wfire){wdata_reg,wstrb_reg}<={wdata,wstrb};
    end
    assign {wdata_out,wstrb_out}=wfire?{wdata,wstrb}:{wdata_reg,wstrb_reg};
    //function
    wire b_notbusy;
    ysyx_26040117_counter counter3(.clk(clk),.rst(rst),.wen(awvalid),.delay_over(awready));
    ysyx_26040117_counter counter4(.clk(clk),.rst(rst),.wen(wvalid),.delay_over(wready));
    ysyx_26040117_counter counter5(.clk(clk),.rst(rst),.wen(write_ok),.delay_over(b_notbusy));
`ifdef STA_MODE
    wire [31:0]dummy_src2;
    ysyx_26040117_RegisterFile #(.ADDR_WIDTH(8)) Register2(.clk(clk),.rst(rst),
        .raddr1(araddr_out[7:0]),.raddr2(8'd0),.rdata1(rdata),.rdata2(dummy_src2),
        .wdata(dummy_wdata),.waddr(dummy_waddr),.wen(dummy_wen)
    );
`else
    import "DPI-C" function void paddr_write(input int unsigned waddr, input int unsigned wdata, input byte wmask);
    always @(posedge clk) begin
        if(rst)begin
        end else if(b_notbusy&&!bvalid)begin  //?
            paddr_write(awaddr_out,wdata_out,{4'd0,wstrb_out});
        end
    end
`endif
    always @(posedge clk) begin
        if(rst)begin
            bvalid<=1'b0;
        end else begin
            if(bfire)
                bvalid<=1'b0;
            else if(b_notbusy&&!bvalid)
                bvalid<=1'b1;
        end
    end
    assign bresp=2'b00;
endmodule

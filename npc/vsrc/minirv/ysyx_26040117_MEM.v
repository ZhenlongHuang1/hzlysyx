module ysyx_26040117_MEM(clk,rst,
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
    //read
    wire arfire;
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
    import "DPI-C" function int unsigned paddr_read(input int unsigned raddr);
    wire r_notbusy;
    ysyx_26040117_counter counter1(.clk(clk),.rst(rst),.wen(arvalid),.delay_over(arready));
    ysyx_26040117_counter counter2(.clk(clk),.rst(rst),.wen(arfire),.delay_over(r_notbusy));
    always @(posedge clk) begin
        if(rst)begin
            rdata<=32'h0;
        end else if(r_notbusy&&!rvalid)begin  //只在读取有效时改变
            rdata<= paddr_read(araddr_out);
        end
    end
    always @(posedge clk) begin
        if(rst)begin
            rvalid<=1'b0;
        end else begin
            if(r_notbusy)
                rvalid<=1'b1;
            else if(rready)
                rvalid<=1'b0;
        end
    end
    assign rresp=(araddr_out>=32'h10000000)&&(araddr_out<=32'h88000000);
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
    import "DPI-C" function void paddr_write(input int unsigned waddr, input int unsigned wdata, input byte wmask);
    wire b_notbusy;
    ysyx_26040117_counter counter3(.clk(clk),.rst(rst),.wen(awvalid),.delay_over(awready));
    ysyx_26040117_counter counter4(.clk(clk),.rst(rst),.wen(wvalid),.delay_over(wready));
    ysyx_26040117_counter counter5(.clk(clk),.rst(rst),.wen(write_ok),.delay_over(b_notbusy));
    always @(posedge clk) begin
        if(rst)begin
        end else if(b_notbusy&&!bvalid)begin  //?
            paddr_write(awaddr_out,wdata_out,{4'd0,wstrb_out});
        end
    end
    always @(posedge clk) begin
        if(rst)begin
            bvalid<=1'b0;
        end else begin
            if(b_notbusy)
                bvalid<=1'b1;
            else if(bready)
                bvalid<=1'b0;
        end
    end
    assign bresp=(awaddr_out>=32'h10000000)&&(awaddr_out<=32'h88000000);
endmodule

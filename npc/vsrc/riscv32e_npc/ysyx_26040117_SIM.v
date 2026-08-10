module ysyx_26040117_SIM(
    input clock,
    input reset
);
    wire         io_master_awready;
    wire         io_master_awvalid;
    wire [31:0]  io_master_awaddr;
    wire [3:0]   io_master_awid;
    wire [7:0]   io_master_awlen;
    wire [2:0]   io_master_awsize;
    wire [1:0]   io_master_awburst;

    wire         io_master_wready;
    wire         io_master_wvalid;
    wire [31:0]  io_master_wdata;
    wire [3:0]   io_master_wstrb;
    wire         io_master_wlast;

    wire         io_master_bready;
    reg          io_master_bvalid;
    wire [1:0]   io_master_bresp;
    wire [3:0]   io_master_bid;

    wire         io_master_arready;
    wire         io_master_arvalid;
    wire [31:0]  io_master_araddr;
    wire [3:0]   io_master_arid;
    wire [7:0]   io_master_arlen;
    wire [2:0]   io_master_arsize;
    wire [1:0]   io_master_arburst;

    wire         io_master_rready;
    reg          io_master_rvalid;
    wire [1:0]   io_master_rresp;
    reg  [31:0]  io_master_rdata;
    wire         io_master_rlast;
    wire [3:0]   io_master_rid;
    
    assign io_master_awready=1'b1;
    assign io_master_wready=1'b1;
    assign io_master_arready=1'b1;
    assign io_master_bresp=2'b0;
    assign io_master_bid=4'b0;
    assign io_master_rresp=2'b0;
    assign io_master_rid=4'b0;
    assign io_master_rlast=(io_master_arlen==8'd0);
    always @(posedge clock) begin
        if(reset)begin
            io_master_bvalid<=1'b0;
            io_master_rvalid<=1'b0;
            io_master_rdata<=32'd0;
        end else begin
            io_master_bvalid<=io_master_awvalid&&io_master_wvalid;
            io_master_rvalid<=io_master_arvalid;
        end
        
    end
    always @(posedge clock) begin
        if(reset)begin
        end else begin
            
        end
    end

    ysyx_26040117 cpu (
    .clock                   (clock),
    .reset                   (reset),
    .io_interrupt            (1'h0),	
    .io_master_awready      (io_master_awready),
    .io_master_awvalid      (io_master_awvalid),
    .io_master_awid    (io_master_awid),
    .io_master_awaddr  (io_master_awaddr),
    .io_master_awlen   (io_master_awlen),
    .io_master_awsize  (io_master_awsize),
    .io_master_awburst (io_master_awburst),
    .io_master_wready       (io_master_wready),
    .io_master_wvalid       (io_master_wvalid),
    .io_master_wdata   (io_master_wdata),
    .io_master_wstrb   (io_master_wstrb),
    .io_master_wlast   (io_master_wlast),
    .io_master_bready       (io_master_bready),
    .io_master_bvalid       (io_master_bvalid),
    .io_master_bid     (io_master_bid),
    .io_master_bresp   (io_master_bresp),
    .io_master_arready      (io_master_arready),
    .io_master_arvalid      (io_master_arvalid),
    .io_master_arid    (io_master_arid),
    .io_master_araddr  (io_master_araddr),
    .io_master_arlen   (io_master_arlen),
    .io_master_arsize  (io_master_arsize),
    .io_master_arburst (io_master_arburst),
    .io_master_rready       (io_master_rready),
    .io_master_rvalid       (io_master_rvalid),
    .io_master_rid     (io_master_rid),
    .io_master_rdata   (io_master_rdata),
    .io_master_rresp   (io_master_rresp),
    .io_master_rlast   (io_master_rlast),
    .io_slave_awready       (/* unused */),
    .io_slave_awvalid       (1'h0),	
    .io_slave_awid     (4'h0),
    .io_slave_awaddr   (32'h0),	
    .io_slave_awlen    (8'h0),	
    .io_slave_awsize   (3'h0),	
    .io_slave_awburst  (2'h0),	
    .io_slave_wready        (/* unused */),
    .io_slave_wvalid        (1'h0),	
    .io_slave_wdata    (32'h0),	
    .io_slave_wstrb    (4'h0),	
    .io_slave_wlast    (1'h0),	
    .io_slave_bready        (1'h0),	
    .io_slave_bvalid        (/* unused */),
    .io_slave_bid      (/* unused */),
    .io_slave_bresp    (/* unused */),
    .io_slave_arready       (/* unused */),
    .io_slave_arvalid       (1'h0),	
    .io_slave_arid     (4'h0),	
    .io_slave_araddr   (32'h0),	
    .io_slave_arlen    (8'h0),	
    .io_slave_arsize   (3'h0),	
    .io_slave_arburst  (2'h0),	
    .io_slave_rready        (1'h0),	
    .io_slave_rvalid        (/* unused */),
    .io_slave_rid      (/* unused */),
    .io_slave_rdata    (/* unused */),
    .io_slave_rresp    (/* unused */),
    .io_slave_rlast    (/* unused */)
  );


endmodule

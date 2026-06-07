module ysyx_26040117_LSU (clk,rst,
    reqValid,respReady,wen,addr,wdata_in,wmask,ifsigned,
    respValid,rdata_out,rresp,bresp
);
    input clk,rst;
    input reqValid,respReady,wen;
    input[31:0] addr,wdata_in;
    input[3:0]wmask;
    input ifsigned;

    output respValid;
    output [31:0]rdata_out;
    output rresp,bresp;

    //read
    wire[31:0] rdata;
    wire arvalid,arready,rvalid,rready;
    wire [31:0] araddr;
    wire rIDLE_reqvalid,rfire,arfire;
    reg[1:0] rstate,rnext_state;
    localparam IDLE=2'd0,WAIT_READY=2'd1,WAIT_VALID=2'd2;
    always @(posedge clk) begin
        if(rst) rstate<=IDLE;
        else rstate<=rnext_state;
    end
    always @(*) begin
        rnext_state=rstate;
        case(rstate)
            IDLE:begin
                if(arfire)rnext_state=WAIT_VALID;
                else if(arvalid)rnext_state=WAIT_READY;
            end
            WAIT_READY:if(arfire)rnext_state=WAIT_VALID;
            WAIT_VALID:if(rfire)rnext_state=IDLE;
            default:rnext_state=rstate;
        endcase
    end
    assign rfire=rvalid&&rready;
    assign arfire=arvalid&&arready;
    assign rIDLE_reqvalid=rstate==IDLE&&reqValid&&!wen;
    assign arvalid=rstate==WAIT_READY||(rIDLE_reqvalid);
    assign rready=rstate==WAIT_VALID&&respReady;
    reg[31:0] addr_reg;
    reg[3:0] wmask_reg;
    reg ifsigned_reg;
    wire[3:0] ar_wmask;
    wire ar_ifsigned;
    always@(posedge clk)begin
        if(rst)begin
            {addr_reg,wmask_reg,ifsigned_reg}<=37'h0;
        end else if(rIDLE_reqvalid)begin
            {addr_reg,wmask_reg,ifsigned_reg}<={addr,wmask,ifsigned};
        end
    end
    assign {araddr,ar_wmask,ar_ifsigned}=rIDLE_reqvalid?{addr,wmask,ifsigned}:{addr_reg,wmask_reg,ifsigned_reg};
    //write
    wire awvalid,awready,wvalid,wready,bvalid,bready;
    wire aw_w_valid;
    wire [31:0] awaddr,wdata;
    wire [3:0] wstrb;
    wire awIDLE_reqvalid,wIDLE_reqvalid,wfire,awfire,bfire;
    reg[1:0] awstate,awnext_state,wstate,wnext_state,bstate,bnext_state;
    always @(posedge clk) begin
        if(rst) {awstate,wstate,bstate}<={IDLE,IDLE,IDLE};
        else {awstate,wstate,bstate}<={awnext_state,wnext_state,bnext_state};
    end
    //aw
    always @(*) begin
        awnext_state=awstate;
        case(awstate)
            IDLE:begin
                if(awfire)awnext_state=WAIT_VALID;
                else if(awvalid)awnext_state=WAIT_READY;
            end
            WAIT_READY:if(awfire)awnext_state=WAIT_VALID;
            WAIT_VALID:if(bfire)awnext_state=IDLE;
            default:awnext_state=awstate;
        endcase
    end
    assign awfire=awvalid&&awready;
    assign awIDLE_reqvalid=awstate==IDLE&&reqValid&&wen;//modify?
    assign awvalid=awstate==WAIT_READY||(awIDLE_reqvalid);
    //w
    always @(*) begin
        wnext_state=wstate;
        case(wstate)
            IDLE:begin
                if(wfire)wnext_state=WAIT_VALID;
                else if(wvalid)wnext_state=WAIT_READY;
            end
            WAIT_READY:if(wfire)wnext_state=WAIT_VALID;
            WAIT_VALID:if(bfire)wnext_state=IDLE;
            default:wnext_state=wstate;
        endcase
    end
    assign wfire=wvalid&&wready;
    assign wIDLE_reqvalid=wstate==IDLE&&reqValid&&wen;//modify?
    assign wvalid=wstate==WAIT_READY||(wIDLE_reqvalid);
    //b
    always @(*) begin
        bnext_state=bstate;
        case(bstate)
            IDLE:if(aw_w_valid)bnext_state=WAIT_VALID;
            WAIT_VALID:if(bfire)bnext_state=IDLE;
            default:bnext_state=bstate;
        endcase
    end
    assign aw_w_valid=awstate==WAIT_VALID&&wstate==WAIT_VALID;
    assign bfire=bready&&bvalid;
    assign bready=bstate==WAIT_VALID&&respReady;//modify?

    reg[31:0] awaddr_reg,wdata_reg;
    reg[3:0] wstrb_reg;
    always @(posedge clk) begin
        if(rst) awaddr_reg<=32'h0;
        else if(awIDLE_reqvalid) awaddr_reg<=addr;
    end
    always@(posedge clk)begin
        if(rst) {wdata_reg,wstrb_reg}<=36'h0;
        else if(wIDLE_reqvalid) {wdata_reg,wstrb_reg}<={wdata_in,wmask};
    end
    assign {wdata,wstrb}=wIDLE_reqvalid?{wdata_in,wmask}:{wdata_reg,wstrb_reg};
    assign awaddr=awIDLE_reqvalid?addr:awaddr_reg;

    ysyx_26040117_MEM mem1(.clk(clk),.rst(rst),
        .arvalid(arvalid),.arready(arready),.araddr(araddr),
        .rvalid(rvalid),.rready(rready),.rdata(rdata),.rresp(rresp),
        .awvalid(awvalid),.awready(awready),.awaddr(awaddr),
        .wvalid(wvalid),.wready(wready),.wdata(wdata),.wstrb(wstrb),
        .bvalid(bvalid),.bready(bready),.bresp(bresp)
);
    assign respValid=rfire||bfire;

    //read function
    reg[31:0] rdata2;
    wire[31:0] bitmask,bitnmask;
    wire[1:0] raddr_shift;
    wire signbit;
    assign bitmask={{8{ar_wmask[3]}},{8{ar_wmask[2]}},{8{ar_wmask[1]}},{8{ar_wmask[0]}}};
    assign bitnmask={{8{~ar_wmask[3]&&ar_ifsigned}},{8{~ar_wmask[2]&&ar_ifsigned}},{8{~ar_wmask[1]&&ar_ifsigned}},{8{~ar_wmask[0]&&ar_ifsigned}}};
    assign raddr_shift=araddr[1:0];
    assign rdata_out=(rdata2&bitmask)|(bitnmask&{32{signbit}});//符号拓展or 0拓展
    assign signbit=(~ar_wmask[3]&&ar_wmask[1]&&rdata2[15])||(~(|ar_wmask[3:1])&&rdata2[7]);
    always @(*) begin
        case (raddr_shift)
            2'b00: rdata2=rdata;
            2'b01: rdata2={8'h0,rdata[31:8]}; 
            2'b10: rdata2={16'h0,rdata[31:16]};
            2'b11: rdata2={24'h0,rdata[31:24]};
            default:rdata2=rdata;
        endcase
    end
endmodule

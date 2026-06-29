`include "ysyx_26040117__defines.vh"
module ysyx_26040117_arbiter(clk,rst,
    MEM_IFU_wrapper,IFU_MEM_wrapper,
    MEM_LSU_wrapper,LSU_MEM_wrapper
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
    input [104:0] IFU_MEM_wrapper,LSU_MEM_wrapper;
    output [38:0] MEM_IFU_wrapper,MEM_LSU_wrapper;
    //unpack
    wire ifu_arvalid,ifu_rready,lsu_arvalid,lsu_rready;
    wire [31:0] ifu_araddr,lsu_araddr;
    wire ifu_arready,ifu_rvalid,lsu_arready,lsu_rvalid;
    wire [31:0] ifu_rdata,lsu_rdata;
    wire ifu_rresp,lsu_rresp;
    assign {ifu_arvalid,ifu_araddr,ifu_rready}=IFU_MEM_wrapper[104:71];
    assign {lsu_arvalid,lsu_araddr,lsu_rready}=LSU_MEM_wrapper[104:71];
    assign MEM_IFU_wrapper[38:4]={ifu_arready,ifu_rvalid,ifu_rdata,ifu_rresp};
    assign MEM_LSU_wrapper[38:4]={lsu_arready,lsu_rvalid,lsu_rdata,lsu_rresp};
    //state machine
    reg [1:0] state,next_state;
    localparam IDLE=2'd0,WAIT_LSU=2'd1,WAIT_IFU=2'd2;
    always @(posedge clk) begin
        if(rst) state<=IDLE;
        else state<=next_state;
    end
    always @(*) begin
        next_state=state;
        case(state)
            IDLE: begin
                if(lsu_arvalid)next_state=WAIT_LSU;//0延迟会死锁
                else if(ifu_arvalid)next_state=WAIT_IFU;
            end
            WAIT_LSU:if(lsu_rvalid&&lsu_rready) next_state=IDLE;
            WAIT_IFU:if(ifu_rvalid&&ifu_rready) next_state=IDLE;
            default:next_state=state;
        endcase
    end
    wire lsu_fire,ifu_fire;
    assign lsu_fire=(state==IDLE&&lsu_arvalid)||state==WAIT_LSU;
    assign ifu_fire=(state==IDLE&&ifu_arvalid&&!lsu_arvalid)||state==WAIT_IFU;
    //read
    wire arvalid,rready;
    wire [31:0] araddr;
    wire arready,rvalid;
    wire [31:0] rdata;
    wire rresp;
    assign {arvalid,rready,araddr}=({34{lsu_fire}}&{lsu_arvalid,lsu_rready,lsu_araddr})|
                                    ({34{ifu_fire}}&{ifu_arvalid,ifu_rready,ifu_araddr});
    assign {lsu_arready,lsu_rvalid,lsu_rdata,lsu_rresp}=lsu_fire?{arready,rvalid,rdata,rresp}:35'd0;
    assign {ifu_arready,ifu_rvalid,ifu_rdata,ifu_rresp}=ifu_fire?{arready,rvalid,rdata,rresp}:35'd0;

    //write
    wire awvalid,wvalid,bready;
    wire [31:0] awaddr,wdata;
    wire [3:0] wstrb;
    wire awready,wready,bvalid;
    wire bresp;
    assign {awvalid,awaddr,wvalid,wdata,wstrb,bready}=LSU_MEM_wrapper[70:0];
    assign MEM_LSU_wrapper[3:0]={awready,wready,bvalid,bresp};

    ysyx_26040117_Xbar xbar1(.clk(clk),.rst(rst),
        .arvalid(arvalid),.arready(arready),.araddr(araddr),
        .rvalid(rvalid),.rready(rready),.rdata(rdata),.rresp(rresp),
        .awvalid(awvalid),.awready(awready),.awaddr(awaddr),
        .wvalid(wvalid),.wready(wready),.wdata(wdata),.wstrb(wstrb),
        .bvalid(bvalid),.bready(bready),.bresp(bresp)
`ifdef STA_MODE
        ,.dummy_wen(dummy_wen),.dummy_wdata(dummy_wdata),.dummy_waddr(dummy_waddr)
`endif
);

endmodule

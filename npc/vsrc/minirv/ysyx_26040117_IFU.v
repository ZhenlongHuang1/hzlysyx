module ysyx_26040117_IFU(clk,rst,
    WBU_IFU_valid,WBU_IFU_ready,jalr,jump,dnpc,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,snpc,ifu_rresp,
    MEM_IFU_wrapper,IFU_MEM_wrapper
);
    input clk,rst;

    //WBU-IFU
    input WBU_IFU_valid;
    output WBU_IFU_ready;
    input jump,jalr;
    input[31:0]dnpc/* verilator public_flat_rd */;
    //IFU-IDU
    input IFU_IDU_ready;
    output IFU_IDU_valid;
    output [31:0]inst;
    output reg[31:0]pc;
    output[31:0] snpc;
    output[1:0] ifu_rresp;
    //IFU-MEM
    input [40:0]MEM_IFU_wrapper;
    output[104:0] IFU_MEM_wrapper;

    //state machine 
    wire WBU_IFU_fire,IFU_IDU_fire;
    wire arvalid,arready,rvalid,rready;
    wire rfire,arfire;
    wire[31:0]pc_next;
    reg[1:0] state,next_state;
    localparam IDLE=2'd0,WAIT_READY=2'd1,WAIT_VALID=2'd2;
    always@(posedge clk)begin
        if(rst)
            state<=WAIT_READY;
        else
            state<=next_state;
    end
    assign WBU_IFU_fire=WBU_IFU_ready&&WBU_IFU_valid;
    assign IFU_IDU_fire=IFU_IDU_ready&&IFU_IDU_valid;
    assign rfire=rvalid&&rready;
    assign arfire=arvalid&&arready;
    always@(*)begin
        next_state=state;
        case (state)
            IDLE:begin
                if(arfire)next_state=WAIT_VALID;
                else if(arvalid)next_state=WAIT_READY;
            end
            WAIT_READY:if(arfire)next_state=WAIT_VALID;
            WAIT_VALID:if(rfire)next_state=IDLE;
            default:next_state=state;
        endcase
    end
    wire IDLE_fire;
    assign IDLE_fire=state==IDLE&&WBU_IFU_fire;
    assign arvalid=IDLE_fire||state==WAIT_READY;
    assign rready=state==WAIT_VALID&&IFU_IDU_ready;
    assign IFU_IDU_valid=state==WAIT_VALID&&(rvalid);
    assign WBU_IFU_ready=state==IDLE;



    //pc_next计算
    assign snpc=pc+32'd4;
    assign pc_next=({32{~jump}}&snpc)|                    //FIFO
                    ({{31{jump}},jump&(~jalr)}&dnpc);//jump:JAL||JALR||跳转
    always@(posedge clk)begin
        if(rst)
            pc<=32'h80000000;
        else if(IDLE_fire)begin
            pc<=pc_next;
        end
    end
    //取指
    wire [31:0] ifu_rdata;
    wire [31:0] ifu_araddr;
    assign ifu_araddr=IDLE_fire?pc_next:pc;
    wire ifu_awready,ifu_wready,ifu_bvalid;
    wire[1:0] ifu_bresp;

    assign IFU_MEM_wrapper={arvalid,ifu_araddr,rready,1'b0,32'd0,1'b0,32'd0,4'd0,1'b0};
    assign {arready,rvalid,ifu_rdata,ifu_rresp,ifu_awready,ifu_wready,ifu_bvalid,ifu_bresp}=MEM_IFU_wrapper;
//    ysyx_26040117_MEM mem1(.clk(clk),.rst(rst),
//        .arvalid(arvalid),.arready(arready),.araddr(ifu_araddr),
//        .rvalid(rvalid),.rready(rready),.rdata(ifu_rdata),.rresp(ifu_rresp),
//        .awvalid(1'b0),.awready(ifu_awready),.awaddr(32'd0),
//        .wvalid(1'b0),.wready(ifu_wready),.wdata(32'd0),.wstrb(4'd0),
//        .bvalid(ifu_bvalid),.bready(1'b0),.bresp(ifu_bresp)
//);

    assign inst=ifu_rdata; 
    
endmodule

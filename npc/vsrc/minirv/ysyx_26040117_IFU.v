module ysyx_26040117_IFU(clk,rst,
    WBU_IFU_valid,WBU_IFU_ready,jalr,jump,dnpc,lsu_error,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,snpc,
    MEM_IFU_wrapper,IFU_MEM_wrapper
);
    input clk,rst;

    //WBU-IFU
    input WBU_IFU_valid;
    output WBU_IFU_ready;
    input jump,jalr;
    input[31:0]dnpc/* verilator public_flat_rd */;
    input lsu_error;
    //IFU-IDU
    input IFU_IDU_ready;
    output IFU_IDU_valid;
    output [31:0]inst;
    output reg[31:0]pc;
    output[31:0] snpc;
    //IFU-MEM
    input [40:0]MEM_IFU_wrapper;
    output[107:0] IFU_MEM_wrapper;

    //state machine 
    wire WBU_IFU_fire,IFU_IDU_fire;
    reg arvalid;
    wire arready,rvalid,rready;
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
    always @(posedge clk) begin
        if(rst)arvalid<=1'b0;
        else begin
            if(arfire) arvalid<=1'b0;
            else if(IDLE_fire||state==WAIT_READY) arvalid<=1'b1;//need change? slow one clk
        end
    end
    assign rready=state==WAIT_VALID&&!inst_valid;
    assign IFU_IDU_valid=(state==WAIT_VALID&&(rvalid))||inst_valid;
    assign WBU_IFU_ready=state==IDLE;
    //pc_next计算
    wire[1:0] ifu_rresp;
    assign snpc=pc+32'd4;
    assign pc_next=({32{~jump}}&snpc)|                    //FIFO
                    ({{31{jump}},jump&(~jalr)}&dnpc);//jump:JAL||JALR||跳转
    always@(posedge clk)begin
        if(rst)
            pc<=32'h30000000;
        else begin
            if(ifu_rresp[1]||lsu_error)
                pc<=32'h00000000;
            if(IDLE_fire)
                pc<=pc_next;
        end
    end
    //取指
    wire [31:0] rdata;
    wire [31:0] araddr;
    wire awready,wready,bvalid;
    wire[1:0] rresp,bresp;

    assign araddr=pc;
    assign IFU_MEM_wrapper={3'b010,arvalid,araddr,rready,1'b0,32'd0,1'b0,32'd0,4'd0,1'b0};
    assign {arready,rvalid,rdata,rresp,awready,wready,bvalid,bresp}=MEM_IFU_wrapper;
    //FIFO
    reg[31:0] inst_reg;
    reg[1:0] rresp_reg;
    reg inst_valid;
    always @(posedge clk) begin
        if(rst)begin
            inst_reg<=32'd0;
            inst_valid<=1'b0;
            rresp_reg<=2'd0;
        end else begin
            if(IFU_IDU_ready)
                inst_valid<=1'b0;
            else if(rfire&&!IFU_IDU_ready)begin
                inst_reg<=rdata;
                rresp_reg<=rresp;
                inst_valid<=1'b1;
            end
        end
    end
    assign inst=inst_valid?inst_reg:rdata; //save?
    assign ifu_rresp=inst_valid?rresp_reg:rresp; 
endmodule

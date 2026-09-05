module ysyx_26040117_IFU #(
    parameter [31:0] RESET_VECTOR=32'h3000_0000
)(clk,rst,
    WBU_IFU_valid,WBU_IFU_ready,jump,dnpc,fence_i,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,fence_done,
    MEM_IFU_wrapper,IFU_MEM_wrapper
);
    input clk,rst;

    //WBU-IFU
    input WBU_IFU_valid;
    output WBU_IFU_ready;
    input jump;
    input[31:0]dnpc/* verilator public_flat_rd */;
    input fence_i;
    //IFU-IDU
    input IFU_IDU_ready;
    output IFU_IDU_valid;
    output [31:0]inst;
    output reg [31:0]pc;
    output fence_done;
    //IFU-MEM
    input [34:0] MEM_IFU_wrapper;
    output[34:0] IFU_MEM_wrapper;

    //state machine 
    wire WBU_IFU_fire;
    wire arvalid;
    wire arready,rvalid,rready;
    wire rfire,arfire;
    reg[1:0] state,next_state;
    localparam IDLE=2'd0,WAIT_READY=2'd1,WAIT_VALID=2'd2;
    always@(posedge clk)begin
        if(rst)
            state<=WAIT_READY;
        else
            state<=next_state;
    end
    assign WBU_IFU_fire=WBU_IFU_ready&&WBU_IFU_valid;
    assign rfire=rvalid&&rready;
    assign arfire=arvalid&&arready;
    always@(*)begin
        next_state=state;
        case (state)
            IDLE:if(WBU_IFU_fire)next_state=WAIT_READY;
            WAIT_READY:if(arfire)next_state=WAIT_VALID;
            WAIT_VALID:if(rfire)next_state=IDLE;
            default:next_state=state;
        endcase
    end
    wire IDLE_fire;
    assign IDLE_fire=state==IDLE&&WBU_IFU_fire;
    assign arvalid=state==WAIT_READY&&!rst;
    assign rready=state==WAIT_VALID&&IFU_IDU_ready;
    assign IFU_IDU_valid=(state==WAIT_VALID)&&rvalid;
    assign WBU_IFU_ready=state==IDLE;
    //pc_next计算
    wire[31:0]pc_next,snpc;
    assign snpc=pc+32'd4;
    assign pc_next=jump?dnpc:snpc_reg;//jump:JAL||JALR||跳转
    always@(posedge clk)begin
        if(rst)pc<=RESET_VECTOR;
        else if(IDLE_fire)pc<=pc_next;
    end
    //取指
    wire [31:0] rdata;
    wire [31:0] araddr;

    assign araddr=pc;
    assign IFU_MEM_wrapper={fence_i,arvalid,araddr,rready};
    assign {fence_done,arready,rvalid,rdata}=MEM_IFU_wrapper;
    assign inst=rdata;
    //FIFO
    reg[31:0] snpc_reg;
    always @(posedge clk) begin
        if(arfire)
            snpc_reg<=snpc;
    end
`ifdef PERF_COUNTER
    reg [63:0] ifu_fetch_inst_count;
    reg [63:0] ifu_no_fetch_count;
    reg [63:0] ifu_wait_wbu_count;
    reg [63:0] ifu_arwait_count;
    reg [63:0] ifu_rwait_count;
    reg [63:0] ifu_idublock_count;
    reg [63:0] ifu_protocol_count;
    always @(posedge clk) begin
        if(rst)begin
            ifu_fetch_inst_count<=64'd0;
            ifu_no_fetch_count     <= 64'd0;
            ifu_wait_wbu_count <= 64'd0;
            ifu_arwait_count       <= 64'd0;
            ifu_rwait_count        <= 64'd0;
            ifu_idublock_count       <= 64'd0;
            ifu_protocol_count     <= 64'd0;
        end else begin
            if(rfire)
                ifu_fetch_inst_count<=ifu_fetch_inst_count+64'd1;
            if(!rfire)begin
                ifu_no_fetch_count <= ifu_no_fetch_count + 64'd1;
                if ((state == IDLE) && !arvalid)
                    ifu_wait_wbu_count <=ifu_wait_wbu_count + 64'd1;
                else if(arvalid&&!arready)
                    ifu_arwait_count<=ifu_arwait_count+64'd1;
                else if((state==WAIT_VALID)&&!rvalid)
                    ifu_rwait_count<=ifu_rwait_count+64'd1;
                else if ((state == WAIT_VALID) &&rvalid && !rready)
                    ifu_idublock_count <=ifu_idublock_count + 64'd1;
                else 
                    ifu_protocol_count<=ifu_protocol_count+64'd1;
            end
        end
    end

`endif
endmodule

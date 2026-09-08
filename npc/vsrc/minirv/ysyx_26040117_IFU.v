module ysyx_26040117_IFU #(
    parameter [31:0] RESET_VECTOR=32'h3000_0000
)(clk,rst,
    WBU_IFU_valid,WBU_IFU_ready,redirect_valid,dnpc,fence_i,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,fence_done,
    MEM_IFU_wrapper,IFU_MEM_wrapper
);
    input clk,rst;

    //WBU-IFU
    input WBU_IFU_valid;
    output WBU_IFU_ready;
    input redirect_valid;
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
    wire arvalid;
    wire arready,rvalid,rready;
    wire rfire,arfire;
    reg state,next_state;
    localparam WAIT_READY=1'd0,WAIT_VALID=1'd1;
    always@(posedge clk)begin
        if(rst||fence_done)//icache rvalid may alway equal 0;fence old than redirect
            state<=WAIT_READY;
        else
            state<=next_state;
    end
    assign rfire=rvalid&&rready;
    assign arfire=arvalid&&arready;
    always@(*)begin
        next_state=state;
        case (state)
            WAIT_READY:if(arfire)next_state=WAIT_VALID;
            WAIT_VALID:if(rfire)next_state=WAIT_READY;
            default:next_state=WAIT_READY;
        endcase
    end
    assign arvalid=state==WAIT_READY&&!rst;
    assign rready=state==WAIT_VALID&&(IFU_IDU_ready||redirect_valid||redirect_pending);
    assign IFU_IDU_valid=(state==WAIT_VALID)&&rvalid&&!redirect_valid&&!redirect_pending;
    assign WBU_IFU_ready=1'b1;
    //pc_next计算
    wire[31:0]snpc;
    assign snpc=pc+32'd4;
    always@(posedge clk)begin
        if(rst)pc<=RESET_VECTOR;
        else if(rfire)begin 
            if(redirect_valid)
                pc<=dnpc;
            else if(redirect_pending)
                pc<=redirect_pc;
            else 
                pc<=snpc;
        end
    end
    //取指
    wire [31:0] rdata;
    wire [31:0] araddr;

    assign araddr=pc;
    assign IFU_MEM_wrapper={fence_i,arvalid,araddr,rready};
    assign {fence_done,arready,rvalid,rdata}=MEM_IFU_wrapper;
    assign inst=rdata;
    //FIFO
    reg redirect_pending;
    reg[31:0] redirect_pc;
    always @(posedge clk) begin
        if(rst||fence_done)
            redirect_pending<=1'b0;
        else if(redirect_valid)begin
            redirect_pc<=dnpc;
            if(rfire)
                redirect_pending<=1'b0;
            else 
                redirect_pending<=1'b1;
        end else if(rfire&&redirect_pending)begin
            redirect_pending<=1'b0;
        end
    end

`ifdef PERF_COUNTER
    reg [63:0] ifu_fetch_inst_count;
    reg [63:0] ifu_no_fetch_count;
    reg [63:0] ifu_arwait_count;
    reg [63:0] ifu_rwait_count;
    reg [63:0] ifu_idublock_count;
    reg [63:0] ifu_protocol_count;
    wire IFU_IDU_fire=IFU_IDU_valid&&IFU_IDU_ready;
    always @(posedge clk) begin
        if(rst)begin
            ifu_fetch_inst_count<=64'd0;
            ifu_no_fetch_count     <= 64'd0;
            ifu_arwait_count       <= 64'd0;
            ifu_rwait_count        <= 64'd0;
            ifu_idublock_count       <= 64'd0;
            ifu_protocol_count     <= 64'd0;
        end else begin
            if(IFU_IDU_fire)
                ifu_fetch_inst_count<=ifu_fetch_inst_count+64'd1;
            if(!rfire)begin
                ifu_no_fetch_count <= ifu_no_fetch_count + 64'd1;
                if(arvalid&&!arready)
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

module ysyx_26040117_IFU #(
    parameter [31:0] RESET_VECTOR=32'h3000_0000
)(clk,rst,
    WBU_IFU_valid,WBU_IFU_ready,redirect_valid,dnpc,fence_i,
    IFU_IDU_valid,IFU_IDU_ready,inst,rpc,fence_done,
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
    output [31:0]rpc;
    output fence_done;
    //IFU-MEM
    input [66:0] MEM_IFU_wrapper;
    output[35:0] IFU_MEM_wrapper;

    //state machine 
    wire arvalid;
    wire arready,rvalid,rready;
    wire rfire,arfire;
    assign rfire=rvalid&&rready;
    assign arfire=arvalid&&arready;
    reg[31:0] resume_pc;
    assign arvalid=1;
    assign rready=IFU_IDU_ready;
    assign IFU_IDU_valid=rvalid;
    assign WBU_IFU_ready=1'b1;
    //pc_next计算
    reg[31:0] fetch_pc;
    wire[31:0]snpc;
    assign snpc=fetch_pc+32'd4;
    always@(posedge clk)begin
        if(rst)fetch_pc<=RESET_VECTOR;
        else if(redirect_valid) fetch_pc<=dnpc;
        else if(fence_done) fetch_pc<=resume_pc;
        else if(arfire)fetch_pc<=snpc;
    end
    //取指
    wire [31:0] rdata;
    wire [31:0] araddr;
    assign araddr=fetch_pc;
    assign IFU_MEM_wrapper={fence_i,redirect_valid,arvalid,araddr,rready};
    assign {fence_done,arready,rvalid,rpc,rdata}=MEM_IFU_wrapper;
    assign inst=rdata;
    //FIFO
    always @(posedge clk) begin
        if(rst)
            resume_pc<=RESET_VECTOR;
        else if(rfire)
            resume_pc<=rpc+32'd4;
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
            else 
                ifu_no_fetch_count <= ifu_no_fetch_count + 64'd1;
            if(!rfire)begin
                if(arvalid&&!arready)
                    ifu_arwait_count<=ifu_arwait_count+64'd1;
                else if(!rvalid)
                    ifu_rwait_count<=ifu_rwait_count+64'd1;
                else if (rvalid && !rready)
                    ifu_idublock_count <=ifu_idublock_count + 64'd1;
                else 
                    ifu_protocol_count<=ifu_protocol_count+64'd1;
            end
        end
    end

`endif
endmodule

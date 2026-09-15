module ysyx_26040117_IFU (clk,rst,
    WBU_IFU_valid,WBU_IFU_ready,redirect_valid,dnpc,fence_i,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,fence_done,idu_pc,pred_taken,
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
    output [31:0]pc;
    output fence_done,pred_taken;
    //IDU-IFU
    input [31:0] idu_pc;
    //IFU-MEM
    input [66:0] MEM_IFU_wrapper;
    output[66:0] IFU_MEM_wrapper;

    //state machine 
    wire rvalid,rready;
    assign rready=IFU_IDU_ready;
    assign IFU_IDU_valid=rvalid;
    assign WBU_IFU_ready=1'b1;
    //取指
    wire [31:0] rpc,rdata;
    assign IFU_MEM_wrapper={fence_i,redirect_valid,dnpc,idu_pc,rready};
    assign {pred_taken,fence_done,rvalid,rpc,rdata}=MEM_IFU_wrapper;
    assign inst=rdata;
    assign pc=rpc;
endmodule

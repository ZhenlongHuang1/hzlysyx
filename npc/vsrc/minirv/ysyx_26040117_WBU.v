`include "ysyx_26040117__defines.vh"
module ysyx_26040117_WBU(clk,rst,
    LSU_WBU_ready,LSU_WBU_valid,result,csr_addr,LSU_wrapper,funct3,
    WBU_IFU_ready,WBU_IFU_valid,trap_dnpc,trap_redirect_valid,fence_i,srcd,rd_out,register_wen
);
    input clk,rst;
    //LSU-WBU
    input LSU_WBU_valid;
    output LSU_WBU_ready;
    input [31:0] result;
    input [3:0] csr_addr;
    input [2:0] funct3;
    input [9:0]LSU_wrapper;
    //WBU-IFU
    input WBU_IFU_ready;
    output WBU_IFU_valid;
    output[31:0] srcd;
    output[31:0] trap_dnpc;
    output trap_redirect_valid;
    output fence_i;
    output [4:0]rd_out;
    output register_wen;

    //state machine
    wire LSU_WBU_fire,WBU_IFU_fire/* verilator public_flat_rd */;
    reg state;
    localparam IDLE=1'd0,WAIT=1'd1;
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else if(LSU_WBU_fire)
            state<=WAIT;
        else if(WBU_IFU_fire)
            state<=IDLE;
    end
    assign LSU_WBU_fire=LSU_WBU_ready&&LSU_WBU_valid;
    assign WBU_IFU_fire=WBU_IFU_ready&&WBU_IFU_valid;
    assign LSU_WBU_ready=state==IDLE;
    assign WBU_IFU_valid=state==WAIT;
    //FIFO
    reg [31:0] result_reg;
    reg [3:0] csr_addr_reg;
    reg [2:0] funct3_reg;
    reg register_wen_reg;
    reg fence_i_reg;
    reg [2:0]trap_ctrl_reg;//0:csrr,1:ecall,2:mret,
    reg [4:0]rd_reg;
    wire [31:0] result_out;
    wire [2:0] funct3_out;
    wire register_wen_out;
    wire [2:0]trap_ctrl_out;//0:csrr,1:ecall,2:mret,
    always @(posedge clk) begin
        if(LSU_WBU_fire)begin
            {result_reg,funct3_reg,register_wen_reg,fence_i_reg,trap_ctrl_reg,rd_reg}<={result,funct3[2:0],LSU_wrapper};
            csr_addr_reg<=csr_addr;
        end
    end
    assign {result_out,funct3_out,trap_ctrl_out,rd_out}={result_reg,funct3_reg,trap_ctrl_reg,rd_reg};
    assign {register_wen_out}={register_wen_reg};
    assign fence_i=fence_i_reg&&(WBU_IFU_fire);

    //function
    wire [31:0] csr_rdata;
    assign register_wen=register_wen_out&&(WBU_IFU_fire);
    assign trap_redirect_valid=|trap_ctrl_out[2:1];
    assign srcd=trap_ctrl_out[0]?csr_rdata:result_out;
    //Control Status Register
    ysyx_26040117_CSR CSR1(.clk(clk),.rst(rst),
        .wen(WBU_IFU_fire),.trap_ctrl(trap_ctrl_out),.funct3(funct3_out[2:0]),.csr_addr(csr_addr_reg),.result(result_out),
        .rdata(csr_rdata),.trap_dnpc(trap_dnpc)
    );
endmodule

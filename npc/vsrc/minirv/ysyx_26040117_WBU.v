`include "ysyx_26040117__defines.vh"
module ysyx_26040117_WBU(clk,rst,
    LSU_WBU_ready,LSU_WBU_valid,result,aux,LSU_wrapper,mytype,funct3,branch_decision,
    WBU_IFU_ready,WBU_IFU_valid,srcd,dnpc,jump,jalr,rd_out,register_wen
);
    input clk,rst;
    //LSU-WBU
    input LSU_WBU_valid;
    output LSU_WBU_ready;
    input [31:0] result,aux;
    input [8:0] mytype;
    input [2:0] funct3;
    input [7:0]LSU_wrapper;
    input branch_decision;
    //WBU-IFU
    input WBU_IFU_ready;
    output WBU_IFU_valid;
    output[31:0] srcd;
    output[31:0] dnpc ;
    output jump,jalr;
    output [4:0]rd_out;
    output register_wen;

    //decompression
    wire [2:0]trap_ctrl;//0:csrr,1:ecall,2:mret,
    wire [4:0]rd;
    assign {trap_ctrl,rd}=LSU_wrapper;

    //state machine
    wire LSU_WBU_fire,WBU_IFU_fire;
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
    reg [31:0] result_reg,aux_reg;
    reg [8:0] mytype_reg;
    reg [2:0] funct3_reg;
    reg [2:0]trap_ctrl_reg;//0:csrr,1:ecall,2:mret,
    reg [4:0]rd_reg;
    reg branch_decision_reg;
    wire [8:0] mytype_out;
    wire [2:0] funct3_out;
    wire [2:0]trap_ctrl_out;//0:csrr,1:ecall,2:mret,
    wire [31:0] result_out,aux_out;
    wire branch_decision_out;
    always @(posedge clk) begin
        if(LSU_WBU_fire)begin
            {result_reg,aux_reg,mytype_reg,funct3_reg,trap_ctrl_reg,rd_reg}<={result,aux,mytype,funct3[2:0],trap_ctrl,rd};
            branch_decision_reg<=branch_decision;
        end
    end
    assign {result_out,aux_out,mytype_out,funct3_out,trap_ctrl_out,rd_out}={
        result_reg,aux_reg,mytype_reg,funct3_reg,trap_ctrl_reg,rd_reg};
    assign branch_decision_out=branch_decision_reg;

    //function
    wire [31:0] csr_rdata;
    wire privil;
    assign jalr=mytype_out[3];
    assign register_wen=((|mytype_out[3:0])||mytype_out[5]||(|mytype_out[8:7])||(trap_ctrl_out[0]))&&(WBU_IFU_fire);
    assign privil=|trap_ctrl_out[2:1];
    assign dnpc=privil?csr_rdata:aux_out;
    assign srcd=trap_ctrl_out[0]?csr_rdata:result_out;
    assign jump=(mytype_out[3]||mytype_out[2]||privil||(mytype_out[4]&&branch_decision_out));
    //Control Status Register

    ysyx_26040117_CSR CSR1(.clk(clk),.rst(rst),
        .wen(WBU_IFU_fire),.trap_ctrl(trap_ctrl_out),.funct3(funct3_out[2:0]),.csr_addr(aux_out[11:0]),.src1(result_out),.pc(result_out),
        .rdata(csr_rdata)
    );
endmodule

`include "ysyx_26040117__defines.vh"
module ysyx_26040117_WBU(clk,rst,
    EXU_WBU_ready,EXU_WBU_valid,result,EXU_wrapper,imm,src1,src2,mytype,op,
    WBU_IFU_ready,WBU_IFU_valid,srcd,dnpc,jump,jalr,rd_out,register_wen,
    reqValid,respReady,respValid,lsu_wen,result_out,src2_out,wmask_out,ifsigned_out,ramdata
);
    input clk,rst;
    //EXU-WBU
    input EXU_WBU_valid;
    output EXU_WBU_ready;
    input [31:0] result,imm,src1,src2;
    input [8:0] mytype;
    input [4:0] op;
    input [79:0]EXU_wrapper;
    //WBU-IFU
    input WBU_IFU_ready;
    output WBU_IFU_valid;
    output[31:0] srcd;
    output[31:0] dnpc ;
    output jump,jalr;
    output [4:0]rd_out;
    output register_wen;
    //WBU-LSU
    input respValid;
    input [31:0]ramdata;
    output reqValid,respReady,lsu_wen;
    output ifsigned_out;
    output [31:0] result_out,src2_out;
    output[3:0] wmask_out;
    //decompression
    wire [2:0]trap_ctrl;//0:csrr,1:ecall,2:mret,
    wire [3:0]wmask;
    wire [4:0]rd;
    wire ifsigned,ebreak;
    wire [31:0] pc,snpc;
    wire[1:0] ifu_error;
    assign {trap_ctrl,wmask,ifsigned,ebreak,rd,pc,snpc,ifu_error}=EXU_wrapper;
    //WBU-LSU
    assign lsu_wen=mytype_out[6]&&(state==WAIT);
    assign reqValid=lsu_wen||(mytype_out[5]&&(state==WAIT));
    assign respReady=WBU_IFU_ready;

    //state machine
    wire EXU_WBU_fire,WBU_IFU_fire;
    reg state,next_state;
    localparam IDLE=1'd0,WAIT=1'd1;
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else
            state<=next_state;
    end
    assign EXU_WBU_fire=EXU_WBU_ready&&EXU_WBU_valid;
    assign WBU_IFU_fire=WBU_IFU_ready&&WBU_IFU_valid;
    always @(*) begin
        next_state=state;
        case(state)
            IDLE:if(EXU_WBU_fire)next_state=WAIT;
            WAIT:if(WBU_IFU_fire)next_state=IDLE;
            default:next_state=state;
        endcase
    end
    assign EXU_WBU_ready=state==IDLE;
    assign WBU_IFU_valid=(state==WAIT&&(respValid||!reqValid));
    //FIFO
    reg [31:0] result_reg,imm_reg,src1_reg,src2_reg;
    reg [8:0] mytype_reg;
    reg [4:0] op_reg;
    reg [2:0]trap_ctrl_reg;//0:csrr,1:ecall,2:mret,
    reg [3:0]wmask_reg;
    reg [4:0]rd_reg;
    reg ifsigned_reg,ebreak_reg;
    reg [31:0] pc_reg,snpc_reg;
    
    wire [31:0] imm_out,src1_out;
    wire [8:0] mytype_out;
    wire [4:0] op_out;
    wire [2:0]trap_ctrl_out;//0:csrr,1:ecall,2:mret,
    wire ebreak_out;
    wire [31:0] pc_out,snpc_out;
    always @(posedge clk) begin
        if(rst)begin
            {result_reg,imm_reg,src1_reg,src2_reg,mytype_reg,op_reg,trap_ctrl_reg,wmask_reg,rd_reg,ifsigned_reg,ebreak_reg,pc_reg,snpc_reg}<=220'h0;
        end else if(EXU_WBU_fire)begin
            {result_reg,imm_reg,src1_reg,src2_reg,mytype_reg,op_reg,trap_ctrl_reg,wmask_reg,rd_reg,ifsigned_reg,ebreak_reg,pc_reg,snpc_reg}<={
                result,imm,src1,src2,mytype,op,trap_ctrl,wmask,rd,ifsigned,ebreak,pc,snpc};
        end
    end
    assign {result_out,imm_out,src1_out,src2_out,mytype_out,op_out,trap_ctrl_out,wmask_out,rd_out,ifsigned_out,ebreak_out,pc_out,snpc_out}={
        result_reg,imm_reg,src1_reg,src2_reg,mytype_reg,op_reg,trap_ctrl_reg,wmask_reg,rd_reg,ifsigned_reg,ebreak_reg,pc_reg,snpc_reg};

    //function
    wire [31:0] csr_rdata;
    wire [31:0] dnpc_unprivil;
    wire privil,br_token;
    assign jalr=mytype_out[3];
    assign register_wen=((|mytype_out[3:0])||mytype_out[5]||(|mytype_out[8:7])||(trap_ctrl_out[0]))&&(WBU_IFU_fire);
    assign br_token=result_out[0];
    assign privil=|trap_ctrl_out[2:1];
    assign dnpc_unprivil= imm_out+(mytype_out[3]?src1_out:pc_out);//JALR:other
    assign dnpc=privil?csr_rdata:dnpc_unprivil;
    assign srcd=({32{mytype_out[5]}}&ramdata)|
                ({32{(|mytype_out[8:7])}}&result_out)|
                ({32{|mytype_out[3:2]}}&snpc_out)|
                ({32{mytype_out[0]}}&imm_out)|
                ({32{mytype_out[1]}}&dnpc)|
                ({32{trap_ctrl_out[0]}}&csr_rdata);
    assign jump=(mytype_out[3]||mytype_out[2]||privil||(mytype_out[4]&&br_token));
`ifndef STA_MODE
    import "DPI-C" function void npc_trap();
    always@(posedge clk)begin
        if(ebreak_out&&!rst&&WBU_IFU_fire)begin
            npc_trap();
        end
    end
`endif
    //Control Status Register

    ysyx_26040117_CSR CSR1(.clk(clk),.rst(rst),
        .wen(WBU_IFU_fire),.trap_ctrl(trap_ctrl_out),.funct3(op_out[2:0]),.csr_addr(imm_out[11:0]),.src1(src1_out),.pc(pc_out),
        .rdata(csr_rdata)
    );
endmodule

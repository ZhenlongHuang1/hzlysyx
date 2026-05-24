module ysyx_26040117_WBU(clk,rst,
    EXU_WBU_ready,EXU_WBU_valid,result,EXU_wrapper,imm,src1,src2,mytype,op,
    WBU_IFU_ready,WBU_IFU_valid,srcd,dnpc,jump,jalr,rd_out,register_wen
);
    input clk,rst;
    //EXU-WBU
    input EXU_WBU_valid;
    output EXU_WBU_ready;
    input [31:0] result,imm,src1,src2;
    input [8:0] mytype;
    input [4:0] op;
    input [81:0]EXU_wrapper;
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
    wire [7:0]wmask;
    wire [4:0]rd;
    wire ifsigned,ebreak;
    wire [31:0] pc,snpc;
    assign {trap_ctrl,wmask,ifsigned,ebreak,rd,pc,snpc}=EXU_wrapper;
    //state machine
    wire EXU_WBU_fire,WBU_IFU_fire;
    reg[1:0] state,next_state;
    localparam IDLE=2'd0,MEM=2'd1,WAIT=2'd2;
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else
            state<=next_state;
    end
    assign EXU_WBU_fire=EXU_WBU_ready&&EXU_WBU_valid;
    assign WBU_IFU_fire=WBU_IFU_ready&&WBU_IFU_valid;
    always @(*) begin
        case(state)
            IDLE:if(EXU_WBU_fire)next_state=WAIT;
            MEM: next_state=WAIT;
            WAIT:if(WBU_IFU_fire)next_state=IDLE;
            default:next_state=state;
        endcase
    end
    assign EXU_WBU_ready=state==IDLE;
    assign WBU_IFU_valid=state==WAIT;
    //FIFO
    reg [31:0] result_reg,imm_reg,src1_reg,src2_reg;
    reg [8:0] mytype_reg;
    reg [4:0] op_reg;
    reg [2:0]trap_ctrl_reg;//0:csrr,1:ecall,2:mret,
    reg [7:0]wmask_reg;
    reg [4:0]rd_reg;
    reg ifsigned_reg,ebreak_reg;
    reg [31:0] pc_reg,snpc_reg;
    
    wire [31:0] result_out,imm_out,src1_out,src2_out;
    wire [8:0] mytype_out;
    wire [4:0] op_out;
    wire [2:0]trap_ctrl_out;//0:csrr,1:ecall,2:mret,
    wire [7:0]wmask_out;
    wire ifsigned_out,ebreak_out;
    wire [31:0] pc_out,snpc_out;
    always @(posedge clk) begin
        if(rst)begin
            result_reg<=32'h0;imm_reg<=32'h0;src1_reg<=32'h0;src2_reg<=32'h0;
            mytype_reg<=9'h0;op_reg<=5'h0;trap_ctrl_reg<=3'h0;
            wmask_reg<=8'h0;rd_reg<=5'h0;
            ifsigned_reg<=1'h0;ebreak_reg<=1'h0;
            pc_reg<=32'h0;snpc_reg<=32'h0;
        end else if(EXU_WBU_fire)begin
            result_reg<=result;imm_reg<=imm;src1_reg<=src1;src2_reg<=src2;
            mytype_reg<=mytype;op_reg<=op;trap_ctrl_reg<=trap_ctrl;
            wmask_reg<=wmask;rd_reg<=rd;
            ifsigned_reg<=ifsigned;ebreak_reg<=ebreak;
            pc_reg<=pc;snpc_reg<=snpc;
        end
    end
    assign result_out=result_reg;
    assign imm_out=imm_reg;
    assign src1_out=src1_reg;
    assign src2_out=src2_reg;
    assign mytype_out=mytype_reg;
    assign op_out=op_reg;
    assign trap_ctrl_out=trap_ctrl_reg;
    assign wmask_out=wmask_reg;
    assign rd_out=rd_reg;
    assign ifsigned_out=ifsigned_reg;
    assign ebreak_out=ebreak_reg;
    assign pc_out=pc_reg;
    assign snpc_out=snpc_reg;

    //function
    wire [31:0] ramdata,csr_rdata;
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
    import "DPI-C" function void npc_trap();
    always@(posedge clk)begin
        if(ebreak_out&&!rst&&WBU_IFU_fire)begin
            npc_trap();
        end
    end
    //Control Status Register

    ysyx_26040117_CSR CSR1(.clk(clk),.rst(rst),
        .wen(WBU_IFU_fire),.trap_ctrl(trap_ctrl_out),.funct3(op_out[2:0]),.csr_addr(imm_out[11:0]),.src1(src1_out),.pc(pc_out),
        .rdata(csr_rdata)
    );
    //Load-Store Unit
    ysyx_26040117_LSU LSU1(.clk(clk),.rst(rst),
        .valid(mytype_out[5]&&(state==WAIT)),.wen(mytype_out[6]&&WBU_IFU_fire),.raddr(result_out),.waddr(result_out),.wdata(src2_out),.wmask(wmask_out),.ifsigned(ifsigned_out),
        .rdata(ramdata)
    );
endmodule

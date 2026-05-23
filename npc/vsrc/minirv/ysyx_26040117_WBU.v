module ysyx_26040117_WBU(clk,rst,
    EXU_WBU_ready,EXU_WBU_valid,result,EXU_wrapper,imm,src1,src2,mytype,op,
    WBU_IFU_ready,WBU_IFU_valid,srcd,dnpc,jump,rd_out,register_wen
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
    output[31:0] srcd,dnpc;
    output jump;
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
    reg state,next_state;
    localparam IDLE=0,WAIT=1;
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

    //function
    wire [31:0] ramdata,csr_rdata;
    wire [31:0] dnpc_unprivil;
    wire privil,br_token;
    assign rd_out=rd_reg;
    assign register_wen=((|mytype_reg[3:0])||mytype_reg[5]||(|mytype_reg[8:7])||(trap_ctrl_reg[0]))&&(WBU_IFU_fire);
    assign br_token=result_reg[0];
    assign privil=|trap_ctrl_reg[2:1];
    assign dnpc_unprivil= imm_reg+(mytype_reg[3]?src1_reg:pc_reg);//JALR:other
    assign dnpc=privil?csr_rdata:dnpc_unprivil;
    assign srcd=({32{mytype_reg[5]}}&ramdata)|
                ({32{(|mytype_reg[8:7])}}&result_reg)|
                ({32{|mytype_reg[3:2]}}&snpc_reg)|
                ({32{mytype_reg[0]}}&imm_reg)|
                ({32{mytype_reg[1]}}&dnpc)|
                ({32{trap_ctrl_reg[0]}}&csr_rdata);
    assign jump=((mytype_reg[3])||(mytype_reg[2]||privil)||(mytype_reg[4]&&br_token));
    import "DPI-C" function void npc_trap();
    always@(posedge clk)begin
        if(ebreak_reg&&!rst&&WBU_IFU_fire)begin
            npc_trap();
        end
    end
    //Control Status Register
    ysyx_26040117_CSR CSR1(.clk(clk),.rst(rst),
        .wen(WBU_IFU_fire),.trap_ctrl(trap_ctrl_reg),.funct3(op_reg[2:0]),.csr_addr(imm_reg[11:0]),.src1(src1_reg),.pc(pc_reg),
        .rdata(csr_rdata)
    );
    //Load-Store Unit
    ysyx_26040117_LSU LSU1(.clk(clk),.rst(rst),
        .valid(mytype_reg[5]&&(state==WAIT)),.wen(mytype_reg[6]&&WBU_IFU_fire),.raddr(result_reg),.waddr(result_reg),.wdata(src2_reg),.wmask(wmask_reg),.ifsigned(ifsigned_reg),
        .rdata(ramdata)
    );
endmodule

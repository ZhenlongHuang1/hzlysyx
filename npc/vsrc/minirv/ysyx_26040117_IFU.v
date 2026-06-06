module ysyx_26040117_IFU(clk,rst,
    WBU_IFU_valid,WBU_IFU_ready,jalr,jump,dnpc,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,snpc,ifu_error
);
    input clk,rst;

    //WBU-IFU
    input WBU_IFU_valid;
    output WBU_IFU_ready;
    input jump,jalr;
    input[31:0]dnpc/* verilator public_flat_rd */;
    //IFU-IDU
    input IFU_IDU_ready;
    output IFU_IDU_valid;
    output [31:0]inst;
    output reg[31:0]pc;
    output[31:0] snpc;
    output ifu_error;
    //counter1
    wire reqValid,reqReady,respValid,respReady;

    //state machine 
    wire WBU_IFU_fire,IFU_IDU_fire;
    wire[31:0]pc_next;
    reg[1:0] state,next_state;
    localparam IDLE=2'd0,WAIT_REQ=2'd1,WAIT_RESP=2'd2;
    always@(posedge clk)begin
        if(rst)
            state<=WAIT_REQ;
        else
            state<=next_state;
    end
    assign WBU_IFU_fire=WBU_IFU_ready&&WBU_IFU_valid;
    assign IFU_IDU_fire=IFU_IDU_ready&&IFU_IDU_valid;
    always@(*)begin
        next_state=state;
        case (state)
            IDLE:if(WBU_IFU_fire)begin
                if(reqReady)next_state=WAIT_RESP;
                else next_state=WAIT_REQ;
            end
            WAIT_REQ:if(reqReady)next_state=WAIT_RESP;
            WAIT_RESP:if(IFU_IDU_fire)next_state=IDLE;
            default:next_state=state;
        endcase
    end
    wire IDLE_fire;
    assign IDLE_fire=state==IDLE&&WBU_IFU_fire;
    assign reqValid=IDLE_fire||state==WAIT_REQ;
    assign respReady=state==WAIT_RESP&&IFU_IDU_ready;
    assign IFU_IDU_valid=state==WAIT_RESP&&(respValid);
    assign WBU_IFU_ready=state==IDLE;


    //pc_next计算
    assign snpc=pc+32'd4;
    assign pc_next=({32{~jump}}&snpc)|                    //FIFO
                    ({{31{jump}},jump&(~jalr)}&dnpc);//jump:JAL||JALR||跳转
    always@(posedge clk)begin
        if(rst)
            pc<=32'h80000000;
        else if(IDLE_fire)begin
            pc<=pc_next;
        end
    end
    //取指
    reg [31:0] ifu_rdata;
    wire [31:0] ifu_raddr;
    assign ifu_raddr=IDLE_fire?pc_next:pc;
    ysyx_26040117_MEM mem2(.clk(clk),.rst(rst),
        .lsu_reqValid(reqValid),.lsu_reqReady(reqReady),.lsu_wen(1'b0),.lsu_addr(ifu_raddr),.lsu_wdata(32'h0),.lsu_wmask(4'b1111),
        .lsu_respValid(respValid),.lsu_respReady(respReady),.lsu_rdata(ifu_rdata),.error(ifu_error)
);

    assign inst=ifu_rdata; 
    
endmodule

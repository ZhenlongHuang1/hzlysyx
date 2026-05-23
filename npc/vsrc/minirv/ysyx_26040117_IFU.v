module ysyx_26040117_IFU(clk,rst,
    WBU_IFU_valid,WBU_IFU_ready,mytype,jump,dnpc,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,snpc
);
    input clk,rst;
    //WBU-IFU
    input WBU_IFU_valid;
    output WBU_IFU_ready;
    input jump;
    input[31:0]dnpc;
    input [8:0]mytype;
    //IFU-IDU
    input IFU_IDU_ready;
    output IFU_IDU_valid;
    output reg[31:0]inst;
    output reg[31:0]pc;
    output[31:0] snpc;

    wire WBU_IFU_fire;
    //state machine 
    wire[31:0]pc_next;
    reg state,next_state;
    localparam IDLE=1'b0,WAIT=1'b1;
    always@(posedge clk)begin
        if(rst)
            state<=WAIT;
        else
            state<=next_state;
    end
    always@(*)begin
        next_state=state;
        case (state)
            IDLE:if(WBU_IFU_valid)next_state=WAIT;
            WAIT:if(IFU_IDU_ready)next_state=IDLE;
        endcase
    end
    assign IFU_IDU_valid=state==WAIT;
    assign WBU_IFU_ready=state==IDLE;
    //pc_next计算
    assign snpc=pc+32'd4;
    assign pc_next=({32{~jump}}&snpc)|                    //FIFO
                    ({{31{jump}},jump&(~mytype[3])}&dnpc);//jump:JAL||JALR||跳转，mytype[3]:JALR
    assign WBU_IFU_fire=WBU_IFU_ready&&WBU_IFU_valid;
    always@(posedge clk)begin
        if(rst)
            pc<=32'h80000000;
        else if(WBU_IFU_fire)begin
            pc<=pc_next;
        end
    end
    //取指
    import "DPI-C" function int unsigned paddr_read(input int unsigned raddr);
    always@(*)begin
        if(pc<=32'h80000000)
            inst=32'h0;
        else
            inst=paddr_read(pc);
    end
endmodule

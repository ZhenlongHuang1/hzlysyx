module ysyx_26040117_IFU(clk,rst,
    WBU_IFU_valid,WBU_IFU_ready,jalr,jump,dnpc,
    //dummy_ifu_wen,dummy_ifu_waddr,dummy_ifu_wdata,
    IFU_IDU_valid,IFU_IDU_ready,inst,pc,snpc
);
    input clk,rst;
    //dummy test
//    input dummy_ifu_wen;
//    input[31:0] dummy_ifu_wdata;
//    input[7:0]dummy_ifu_waddr;

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
    //counter1
    wire reg_notbusy;
    wire reqValid=state==WAIT;
    wire [7:0]delay_val;
    ysyx_26040117_LFshifter lfshifter2(.clk(rst?clk:(!reqValid)),.rst(rst),.outQ(delay_val));
    ysyx_26040117_counter counter2(.clk(clk),.rst(rst),.wen(reqValid),.delay_over(reg_notbusy),.delay_val({4'd0,delay_val[3:0]}));

    //state machine 
    wire WBU_IFU_fire,IFU_IDU_fire;
    wire[31:0]pc_next;
    reg[1:0] state,next_state;
    localparam IDLE=2'd0,FETCH=2'd1,WAIT=2'd2;
    always@(posedge clk)begin
        if(rst)
            state<=WAIT;
        else
            state<=next_state;
    end
    assign WBU_IFU_fire=WBU_IFU_ready&&WBU_IFU_valid;
    assign IFU_IDU_fire=IFU_IDU_ready&&IFU_IDU_valid;
    always@(*)begin
        next_state=state;
        case (state)
            IDLE:if(WBU_IFU_fire)next_state=WAIT;
            WAIT:if(IFU_IDU_fire)next_state=IDLE;
            default:next_state=state;
        endcase
    end
    assign IFU_IDU_valid=state==WAIT&&(reg_notbusy);
    assign WBU_IFU_ready=state==IDLE;
    //pc_next计算
    assign snpc=pc+32'd4;
    assign pc_next=({32{~jump}}&snpc)|                    //FIFO
                    ({{31{jump}},jump&(~jalr)}&dnpc);//jump:JAL||JALR||跳转
    assign WBU_IFU_fire=WBU_IFU_ready&&WBU_IFU_valid;
    always@(posedge clk)begin
        if(rst)
            pc<=32'h80000000;
        else if(WBU_IFU_fire)begin
            pc<=pc_next;
        end
    end
    //取指
    reg [31:0] ifu_rdata;

    import "DPI-C" function int unsigned paddr_read(input int unsigned raddr);
    always@(posedge clk)begin
        if(rst||pc<32'h80000000)
            ifu_rdata<=32'h0;
        else if(state==FETCH)
            ifu_rdata<=paddr_read(pc);
    end
    assign inst=ifu_rdata; 
//    wire [31:0] unused_rdata2;
//    ysyx_26040117_RegisterFile #(.ADDR_WIDTH(8)) Register2(.clk(clk),.rst(rst),
//        .raddr1(pc[7:0]),.raddr2(8'h0),.rdata1(inst),.rdata2(unused_rdata2),
//        .wdata(dummy_ifu_wdata),.waddr(dummy_ifu_waddr),.wen(dummy_ifu_wen)
//
//    );
    
endmodule

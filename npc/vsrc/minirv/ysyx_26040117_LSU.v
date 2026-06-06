module ysyx_26040117_LSU (clk,rst,
    reqValid,lsu_respReady,wen,addr,wdata,wmask,ifsigned,
    lsu_respValid,rdata,lsu_error
);
    input clk,rst;
    input reqValid,lsu_respReady,wen;
    input[31:0] addr,wdata;
    input[3:0]wmask;
    input ifsigned;

    output lsu_respValid;
    output [31:0]rdata;
    output lsu_error;

    wire[31:0] rdata0;
    wire lsu_reqReady;
    wire lsu_reqValid;
    reg[1:0] state,next_state;
    localparam IDLE=2'd0,WAIT_REQ=2'd1,WAIT_RESP=2'd2;
    always @(posedge clk) begin
        if(rst) state<=IDLE;
        else state<=next_state;
    end
    always @(*) begin
        next_state=state;
        case(state)
            IDLE:if(reqValid)begin
                if(lsu_reqReady)next_state=WAIT_RESP;
                else next_state=WAIT_REQ;
            end
            WAIT_REQ:if(lsu_reqReady)next_state=WAIT_RESP;
            WAIT_RESP:if(lsu_respValid)next_state=IDLE;
            default:next_state=state;
        endcase
    end
    assign lsu_reqValid=state==WAIT_REQ||(state==IDLE&&reqValid);
    reg[31:0] addr_reg,wdata_reg;
    reg[3:0] wmask_reg;
    reg wen_reg,ifsigned_reg;
    wire[31:0] lsu_addr,lsu_wdata;
    wire[3:0] lsu_wmask;
    wire lsu_wen,lsu_ifsigned;
    always@(posedge clk)begin
        if(rst)begin
            addr_reg<=32'h0;
            wdata_reg<=32'h0;
            wmask_reg<=4'h0;
            wen_reg<=1'b0;
            ifsigned_reg<=1'b0;
        end else if(state==IDLE&&reqValid)begin
            addr_reg<=addr;
            wdata_reg<=wdata;
            wmask_reg<=wmask;
            wen_reg<=wen;
            ifsigned_reg<=ifsigned;
        end
    end
    assign lsu_addr=state==IDLE?addr:addr_reg;
    assign lsu_wdata=state==IDLE?wdata:wdata_reg;
    assign lsu_wmask=state==IDLE?wmask:wmask_reg;
    assign lsu_wen=state==IDLE?wen:wen_reg;
    assign lsu_ifsigned=state==IDLE?ifsigned:ifsigned_reg;

    ysyx_26040117_MEM mem1(.clk(clk),.rst(rst),
        .lsu_reqValid(lsu_reqValid),.lsu_reqReady(lsu_reqReady),.lsu_wen(lsu_wen),.lsu_addr(lsu_addr),.lsu_wdata(lsu_wdata),.lsu_wmask(lsu_wmask),
        .lsu_respValid(lsu_respValid),.lsu_respReady(lsu_respReady),.lsu_rdata(rdata0),.error(lsu_error)
);

    reg[31:0] rdata2;
    wire[31:0] bitmask,bitnmask;
    wire[1:0] raddr_shift;
    wire signbit;

    assign bitmask={{8{lsu_wmask[3]}},{8{lsu_wmask[2]}},{8{lsu_wmask[1]}},{8{lsu_wmask[0]}}};
    assign bitnmask={{8{~lsu_wmask[3]&&lsu_ifsigned}},{8{~lsu_wmask[2]&&lsu_ifsigned}},{8{~lsu_wmask[1]&&lsu_ifsigned}},{8{~lsu_wmask[0]&&lsu_ifsigned}}};
    assign raddr_shift=lsu_addr[1:0];
    assign rdata=(rdata2&bitmask)|(bitnmask&{32{signbit}});//符号拓展or 0拓展
    assign signbit=(~lsu_wmask[3]&&lsu_wmask[1]&&rdata2[15])||(~(|lsu_wmask[3:1])&&rdata2[7]);
    always @(*) begin
        case (raddr_shift)
            2'b00: rdata2=rdata0;
            2'b01: rdata2={8'h0,rdata0[31:8]}; 
            2'b10: rdata2={16'h0,rdata0[31:16]};
            2'b11: rdata2={24'h0,rdata0[31:24]};
            default:rdata2=rdata0;
        endcase
    end
endmodule

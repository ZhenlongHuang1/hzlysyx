module ysyx_26040117_LSU (clk,rst,reqValid,respValid,wen,addr,wdata,wmask,ifsigned,rdata);
    input clk,rst,reqValid,wen,ifsigned;
    input[31:0] addr,wdata;
    input[3:0]wmask;
    output respValid;
    output [31:0]rdata;
    wire[31:0] rdata0;
    reg[31:0] rdata1;
    wire[31:0] bitmask,bitnmask;
    wire[1:0] raddr_shift;
    wire signbit;

    assign bitmask={{8{wmask[3]}},{8{wmask[2]}},{8{wmask[1]}},{8{wmask[0]}}};
    assign bitnmask={{8{~wmask[3]&&ifsigned}},{8{~wmask[2]&&ifsigned}},{8{~wmask[1]&&ifsigned}},{8{~wmask[0]&&ifsigned}}};
    assign raddr_shift=addr[1:0];
    assign rdata=(rdata1&bitmask)|(bitnmask&{32{signbit}});//符号拓展or 0拓展
    assign signbit=(~wmask[3]&&wmask[1]&&rdata1[15])||(~(|wmask[3:1])&&rdata1[7]);
    always @(*) begin
        case (raddr_shift)
            2'b00: rdata1=rdata0;
            2'b01: rdata1={8'h0,rdata0[31:8]}; 
            2'b10: rdata1={16'h0,rdata0[31:16]};
            2'b11: rdata1={24'h0,rdata0[31:24]};
            default:rdata1=rdata0;
        endcase
    end
    ysyx_26040117_MEM mem1(.clk(clk),.rst(rst),
        .lsu_reqValid(reqValid),.lsu_wen(wen),.lsu_addr(addr),.lsu_wdata(wdata),.lsu_wmask(wmask),
        .lsu_respValid(respValid),.lsu_rdata(rdata0)
);
endmodule

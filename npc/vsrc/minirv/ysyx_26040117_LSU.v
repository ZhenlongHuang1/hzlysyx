module ysyx_26040117_LSU (clk,rst,valid,wen,raddr,waddr,wdata,wmask,ifsigned,rdata);
    input clk,rst,valid,wen,ifsigned;
    input[31:0] raddr,waddr,wdata;
    input[7:0]wmask;
    output [31:0]rdata;
    reg[31:0]rdata0,rdata1;
    wire[31:0] bitmask,bitnmask;
    wire[1:0] raddr_shift;
    wire signbit;



    import "DPI-C" function int unsigned paddr_read(input int unsigned raddr);
    import "DPI-C" function void paddr_write(
        input int unsigned waddr, input int unsigned wdata, input byte wmask);
    assign bitmask={{8{wmask[3]}},{8{wmask[2]}},{8{wmask[1]}},{8{wmask[0]}}};
    assign bitnmask={{8{~wmask[3]&&ifsigned}},{8{~wmask[2]&&ifsigned}},{8{~wmask[1]&&ifsigned}},{8{~wmask[0]&&ifsigned}}};
    assign raddr_shift=raddr[1:0];
    assign rdata=(rdata1&bitmask)|(bitnmask&{32{signbit}});//符号拓展or 0拓展
    assign signbit=(~wmask[3]&&wmask[1]&&rdata1[15])||(~(|wmask[3:1])&&rdata1[7]);
    always @(*) begin
        case (raddr_shift)
            2'b00: rdata1=rdata0;
            2'b01: rdata1=(rdata0>>8); 
            2'b10: rdata1=rdata0>>16;
            2'b11: rdata1=rdata0>>24;
            default:rdata1=rdata0;
        endcase
    end
    always @(*) begin
        if (valid) begin // 有读写请求时
            rdata0 = paddr_read(raddr);
        end
        else begin
            rdata0 = 0;
        end
    end
    always @(posedge clk) begin
        if (wen) begin
            paddr_write(waddr,wdata,wmask);
        end
    end
endmodule

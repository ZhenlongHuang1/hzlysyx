module ysyx_26040117_LSU (clk,rst,reqValid,respValid,wen,raddr,waddr,wdata,wmask,ifsigned,rdata);
    input clk,rst,reqValid,wen,ifsigned;
    input[31:0] raddr,waddr,wdata;
    input[7:0]wmask;
    output reg respValid;
    output [31:0]rdata;
    reg[31:0] rdata0;
    reg[31:0] rdata1;
    wire[31:0] bitmask,bitnmask;
    wire[1:0] raddr_shift;
    wire signbit;

    assign bitmask={{8{wmask[3]}},{8{wmask[2]}},{8{wmask[1]}},{8{wmask[0]}}};
    assign bitnmask={{8{~wmask[3]&&ifsigned}},{8{~wmask[2]&&ifsigned}},{8{~wmask[1]&&ifsigned}},{8{~wmask[0]&&ifsigned}}};
    assign raddr_shift=raddr[1:0];
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

    import "DPI-C" function int unsigned paddr_read(input int unsigned raddr);
    import "DPI-C" function void paddr_write(
        input int unsigned waddr, input int unsigned wdata, input byte wmask);
    wire reg_notbusy;
    wire [7:0]delay_val;
    ysyx_26040117_LFshifter lfshifter1(.clk(clk),.rst(rst),.wen(!reqValid),.outQ(delay_val));
    ysyx_26040117_counter counter1(.clk(clk),.rst(rst),.wen(reqValid),.delay_over(reg_notbusy),.delay_val({4'd0,delay_val[3:0]}));
    always @(posedge clk) begin
        if(rst)begin
            rdata0<=32'h0;
        end else if(reg_notbusy)begin  //有读写请求时
            rdata0<= (reqValid&&(!wen))?paddr_read(raddr):32'h0;
            if (reqValid&&wen) begin
                paddr_write(waddr,wdata,wmask);
            end
        end
    end
    always @(posedge clk) begin
        if(rst)begin
            respValid<=1'b0;
        end else begin
            respValid<=reg_notbusy?reqValid:0;
        end
    end

//    wire[31:0] unused_rdata2;
//    ysyx_26040117_RegisterFile #(.ADDR_WIDTH(8)) Register3(.clk(clk),.rst(rst),
//        .raddr1(raddr[7:0]),.raddr2(8'h0),.rdata1(rdata0),.rdata2(unused_rdata2),
//        .wdata(wdata),.waddr(waddr[7:0]),.wen(wen)
//    );
endmodule

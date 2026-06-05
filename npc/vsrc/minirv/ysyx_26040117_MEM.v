module ysyx_26040117_MEM(clk,rst,
    lsu_reqValid,lsu_wen,lsu_addr,lsu_wdata,lsu_wmask,
    lsu_respValid,lsu_rdata
);
    input clk,rst;
    input lsu_reqValid,lsu_wen;
    input [31:0]lsu_addr,lsu_wdata;
    input [3:0]lsu_wmask;
    output reg lsu_respValid;
    output reg[31:0]lsu_rdata;

    import "DPI-C" function int unsigned paddr_read(input int unsigned raddr);
    import "DPI-C" function void paddr_write(
        input int unsigned waddr, input int unsigned wdata, input byte wmask);
    wire reg_notbusy;
    ysyx_26040117_counter counter1(.clk(clk),.rst(rst),.wen(lsu_reqValid),.delay_over(reg_notbusy));
    always @(posedge clk) begin
        if(rst)begin
            lsu_rdata<=32'h0;
        end else if(reg_notbusy)begin  //有读写请求时
            lsu_rdata<= (lsu_reqValid&&(!lsu_wen))?paddr_read(lsu_addr):32'h0;
            if (lsu_reqValid&&lsu_wen) begin
                paddr_write(lsu_addr,lsu_wdata,{4'd0,lsu_wmask});
            end
        end
    end
    always @(posedge clk) begin
        if(rst)begin
            lsu_respValid<=1'b0;
        end else begin
            lsu_respValid<=reg_notbusy?lsu_reqValid:0;
        end
    end
endmodule

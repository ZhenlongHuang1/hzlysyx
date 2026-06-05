module ysyx_26040117_MEM(clk,rst,
    lsu_reqValid,lsu_respReady,lsu_wen,lsu_addr,lsu_wdata,lsu_wmask,
    lsu_respValid,lsu_reqReady,lsu_rdata
);
    input clk,rst;
    input lsu_reqValid,lsu_respReady,lsu_wen;
    input [31:0]lsu_addr,lsu_wdata;
    input [3:0]lsu_wmask;
    output reg lsu_respValid,lsu_reqReady;
    output reg[31:0]lsu_rdata;

    wire lsu_reqfire;
    assign lsu_reqfire=lsu_reqValid&&lsu_reqReady;
    reg [31:0] addr_reg,wdata_reg;
    reg [3:0] wmask_reg;
    reg wen_reg;
    always @(posedge clk) begin
        if(rst)
            {addr_reg,wdata_reg,wmask_reg,wen_reg}<=69'd0;
        else if(lsu_reqfire)
            {addr_reg,wdata_reg,wmask_reg,wen_reg}<={lsu_addr,lsu_wdata,lsu_wmask,lsu_wen};
    end
    wire [31:0] addr_out,wdata_out;
    wire [3:0] wmask_out;
    wire wen_out;
    assign {addr_out,wdata_out,wmask_out,wen_out}=lsu_reqfire?{lsu_addr,lsu_wdata,lsu_wmask,lsu_wen}:{addr_reg,wdata_reg,wmask_reg,wen_reg};

    import "DPI-C" function int unsigned paddr_read(input int unsigned raddr);
    import "DPI-C" function void paddr_write(
        input int unsigned waddr, input int unsigned wdata, input byte wmask);
    wire reg_notbusy;
    ysyx_26040117_counter counter1(.clk(clk),.rst(rst),.wen(lsu_reqValid),.delay_over(lsu_reqReady));
    ysyx_26040117_counter counter2(.clk(clk),.rst(rst),.wen(lsu_reqReady),.delay_over(reg_notbusy));
    always @(posedge clk) begin
        if(rst)begin
            lsu_rdata<=32'h0;
        end else if(reg_notbusy)begin  //有读写请求时
            lsu_rdata<= (!wen_out)?paddr_read(addr_out):32'h0;
            if (wen_out) begin
                paddr_write(addr_out,wdata_out,{4'd0,wmask_out});
            end
        end
    end
    always @(posedge clk) begin
        if(rst)begin
            lsu_respValid<=1'b0;
        end else begin
            if(reg_notbusy)
                lsu_respValid<=1'b1;
            else if(lsu_respReady)
                lsu_respValid<=1'b0;
        end
    end
endmodule

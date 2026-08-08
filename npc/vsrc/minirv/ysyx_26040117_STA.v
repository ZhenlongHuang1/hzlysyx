module ysyx_26040117_STA (
    input         clock,
    input         reset,
    input [31:0]  in_a,
    input [31:0]  in_b,
    output[31:0]  out_data
);
    reg [31:0]a_reg,b_reg,out_reg;
    always @(posedge clock) begin
        if(reset)begin
            a_reg<=32'd0;
            b_reg<=32'd0;
            out_reg<=32'd0;
        end else begin
            a_reg<=in_a;
            b_reg<=in_b;
            out_reg<=a_reg+b_reg;
        end
    end
    assign out_data=out_reg;

endmodule
/*
module ysyx_26040117_STA (
    input         clock,
    input         reset,

    input  [4:0]  in_raddr1,
    input  [4:0]  in_raddr2,

    input         in_wen,
    input  [4:0]  in_waddr,
    input  [31:0] in_wdata,

    output [31:0] out_rdata1,
    output [31:0] out_rdata2
);

    reg [4:0]  raddr1_reg;
    reg [4:0]  raddr2_reg;
    reg        wen_reg;
    reg [4:0]  waddr_reg;
    reg [31:0] wdata_reg;

    reg [31:0] rdata1_reg;
    reg [31:0] rdata2_reg;

    wire [31:0] rf_rdata1;
    wire [31:0] rf_rdata2;

    always @(posedge clock) begin
        if (reset) begin
            raddr1_reg <= 5'd0;
            raddr2_reg <= 5'd0;
            wen_reg    <= 1'b0;
            waddr_reg  <= 5'd0;
            wdata_reg  <= 32'd0;
            rdata1_reg <= 32'd0;
            rdata2_reg <= 32'd0;
        end else begin
            raddr1_reg <= in_raddr1;
            raddr2_reg <= in_raddr2;
            wen_reg    <= in_wen;
            waddr_reg  <= in_waddr;
            wdata_reg  <= in_wdata;

            rdata1_reg <= rf_rdata1;
            rdata2_reg <= rf_rdata2;
        end
    end

    ysyx_26040117_RegisterFile u_RegisterFile (
        .clk    (clock),
        .rst    (reset),
        .raddr1 (raddr1_reg),
        .raddr2 (raddr2_reg),
        .rdata1 (rf_rdata1),
        .rdata2 (rf_rdata2),
        .wen    (wen_reg),
        .waddr  (waddr_reg),
        .wdata  (wdata_reg)
    );

    assign out_rdata1 = rdata1_reg;
    assign out_rdata2 = rdata2_reg;

endmodule
*/

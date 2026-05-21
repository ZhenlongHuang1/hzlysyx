module ysyx_26040117_IFU(clk,rst,mytype,jump,dnpc,pc,snpc,inst);
    input clk,rst;
    
    input [8:0]mytype;
    input jump;
    input[31:0]dnpc;
    output reg[31:0]inst,pc,snpc;
    wire[31:0]pc_next;

    //pc_next计算
    assign snpc=pc+32'd4;
    assign pc_next=({32{~jump}}&snpc)|
                    ({{31{jump}},jump&(~mytype[3])}&dnpc);//jump:JAL||JALR||跳转，mytype[3]:JALR
    always@(posedge clk)begin
        if(rst)
            pc<=32'h80000000;
        else begin
            pc<=pc_next;
        end
    end
    







    import "DPI-C" function int unsigned paddr_read(input int unsigned raddr);
    always@(*)begin
        inst=paddr_read(pc);
    end
endmodule

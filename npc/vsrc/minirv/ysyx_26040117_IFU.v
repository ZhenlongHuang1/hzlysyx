module ysyx_26040117_IFU(pc,inst);
    input[31:0] pc;
    output reg [31:0]inst;
    import "DPI-C" function int unsigned pmem_read(input int unsigned raddr);
    always@(*)begin
        inst=pmem_read(pc);
    end
endmodule

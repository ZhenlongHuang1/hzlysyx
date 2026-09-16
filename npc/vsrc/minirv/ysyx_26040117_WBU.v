`include "ysyx_26040117__defines.vh"
module ysyx_26040117_WBU(clk,rst,
    LSU_WBU_ready,LSU_WBU_valid,LSU_wrapper,
    WBU_IFU_ready,WBU_IFU_valid,trap_dnpc,trap_redirect_valid,fence_i,srcd,rd,register_wen_out,
    WBU_IDU_wrapper
);
    input clk,rst;
    //LSU-WBU
    input LSU_WBU_valid;
    output LSU_WBU_ready;
    input [51:0]LSU_wrapper;
    //WBU-IFU
    input WBU_IFU_ready;
    output WBU_IFU_valid;
    output[31:0] srcd;
    output[31:0] trap_dnpc/* verilator public_flat_rd */;
    output trap_redirect_valid;
    output fence_i;
    output [4:0]rd;
    output register_wen_out;
    //WBU-IDU
    output[37:0] WBU_IDU_wrapper;
    assign WBU_IDU_wrapper={srcd,WBU_IFU_valid&&register_wen,rd};
    //state machine
    wire LSU_WBU_fire,WBU_IFU_fire/* verilator public_flat_rd */;
    reg state;
    localparam IDLE=1'd0,WAIT=1'd1;
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else if(LSU_WBU_fire)
            state<=WAIT;
        else if(WBU_IFU_fire)
            state<=IDLE;
    end
    assign LSU_WBU_fire=LSU_WBU_ready&&LSU_WBU_valid;
    assign WBU_IFU_fire=WBU_IFU_ready&&WBU_IFU_valid;
    assign LSU_WBU_ready=1;
    assign WBU_IFU_valid=state==WAIT;
    //FIFO
    reg [51:0] LSU_wrapper_reg;
    wire [31:0] result;
    wire [2:0] funct3;
    wire register_wen,type_fence_i;
    wire [6:0]trap_info/* verilator public_flat_rd */;//0:csrr,1:ecall,2:mret,
    wire [2:0] csr_addr/* verilator public_flat_rd */;
    always @(posedge clk) begin
        LSU_wrapper_reg<=LSU_wrapper;
    end
    assign {register_wen,type_fence_i,trap_info,rd,result,csr_addr,funct3}=LSU_wrapper_reg;

    //function
    wire [31:0] csr_rdata;
    assign register_wen_out=register_wen&&(WBU_IFU_fire);
    assign srcd=trap_info[0]?csr_rdata:result;
    assign trap_redirect_valid=(|trap_info[2:1])&&WBU_IFU_fire;
    assign fence_i=type_fence_i&&(WBU_IFU_fire);
    //Control Status Register
    ysyx_26040117_CSR CSR1(.clk(clk),.rst(rst),
        .wen(WBU_IFU_fire),.trap_info(trap_info),.funct3(funct3),.csr_addr(csr_addr),.result(result),
        .rdata(csr_rdata),.trap_dnpc(trap_dnpc)
    );
    //ebreak
`ifndef STA_MODE
    wire ebreak=trap_info[2]&&(trap_info[6:3]==4'd3);
    import "DPI-C" function void npc_trap();
    always@(posedge clk)begin
        if(ebreak&&!rst&&WBU_IFU_fire)begin
            npc_trap();
        end
    end
`endif
`ifdef PERF_COUNTER
    reg [63:0] wbu_occupied_cycles;
    reg [63:0] wbu_out_count;

    always @(posedge clk)begin
        if(rst)begin
            wbu_occupied_cycles<=64'd0;
            wbu_out_count<=64'd0;
        end else begin
            if(WBU_IFU_valid)
                wbu_occupied_cycles<=wbu_occupied_cycles+64'd1;
            if(WBU_IFU_fire)
                wbu_out_count<=wbu_out_count+64'd1;
        end
    end
`endif
endmodule

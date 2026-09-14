module ysyx_26040117_LSU (clk,rst,
    EXU_LSU_ready,EXU_LSU_valid,aux_in,EXU_wrapper,
    LSU_WBU_ready,LSU_WBU_valid,LSU_wrapper,
    LSU_IDU_wrapper,
    MEM_LSU_wrapper,LSU_MEM_wrapper
);
    input clk,rst;
    //EXU-LSU
    input EXU_LSU_valid;
    output EXU_LSU_ready;
    input [59:0]EXU_wrapper;
    input [31:0]aux_in;
    //LSU-WBU
    input LSU_WBU_ready;
    output LSU_WBU_valid;
    output [52:0]LSU_wrapper;
    assign LSU_wrapper={register_wen,type_fence_i,trap_info,rd,result_out,csr_addr,funct3};
    //LSU-IDU
    output [38:0] LSU_IDU_wrapper;
    wire load_ready=register_wen_load&&!arvalid&&rvalid;
    assign LSU_IDU_wrapper={result_out,lsu_valid&&register_wen,lsu_valid&&(register_wen_ok||load_ready),rd};
    //LSU-MEM
    input [40:0]MEM_LSU_wrapper;
    output[110:0] LSU_MEM_wrapper;

    reg lsu_valid;
    wire wen,ren;
    wire EXU_LSU_fire,LSU_WBU_fire/* verilator public_flat_rd */;
    wire [8:0]mytype_in=EXU_wrapper[11:3];
    assign wen=mytype_in[6]&&EXU_LSU_fire;//right now
    assign ren=mytype_in[5]&&EXU_LSU_fire;
    assign EXU_LSU_fire=EXU_LSU_ready&&EXU_LSU_valid;
    assign LSU_WBU_fire=LSU_WBU_ready&&LSU_WBU_valid;
    assign EXU_LSU_ready=!lsu_valid||LSU_WBU_fire;
    assign LSU_WBU_valid=lsu_valid&&(!(|mytype[6:5])|| 
            (mytype[5]&&!arvalid&&rvalid)||
            (mytype[6]&&!awvalid&&!wvalid&&bvalid)
    );
    always @(posedge clk) begin
        if(rst)
            lsu_valid<=1'b0;
        else if(EXU_LSU_fire)
            lsu_valid<=1'b1;
        else if(LSU_WBU_fire)
            lsu_valid<=1'b0;
    end
    //read
    wire[31:0] rdata;
    wire[1:0] rresp;
    wire arready,rvalid,rready;
    reg arvalid;
    wire [31:0] araddr;
    wire [2:0] arsize;
    wire arfire;
    assign arfire=arvalid&&arready;
    always @(posedge clk) begin
        if(rst) arvalid<=1'b0;
        else if(arfire)
            arvalid<=1'b0;
        else if(ren)
            arvalid<=1'b1;
    end
    assign rready=lsu_valid&&mytype[5]&&!arvalid&&LSU_WBU_ready;
    assign {araddr,arsize}={result,{1'b0,funct3[1:0]}};
    //read function
    reg[31:0] rdata_out;
    wire[1:0] raddr_shift;
    assign raddr_shift=araddr[1:0];
    reg[7:0] load_byte;
    wire[15:0]load_half=raddr_shift[1]?rdata[31:16]:rdata[15:0];
    always @(*) begin
        case(raddr_shift)
            2'b00:load_byte=rdata[7:0];
            2'b01:load_byte=rdata[15:8];
            2'b10:load_byte=rdata[23:16];
            2'b11:load_byte=rdata[31:24];
        endcase
    end
    always @(*) begin
        case(funct3)
            3'b000:rdata_out={{24{load_byte[7]}},load_byte};
            3'b001:rdata_out={{16{load_half[15]}},load_half};
            3'b010:rdata_out=rdata;
            3'b100:rdata_out={24'd0,load_byte};
            3'b101:rdata_out={16'd0,load_half};
            default:rdata_out=32'd0;
        endcase
    end
    //write
    wire awready,wready,bvalid,bready;
    reg awvalid,wvalid;
    wire[1:0] bresp;
    wire [2:0] awsize;
    wire [31:0] awaddr,wdata;
    wire [3:0] wstrb;
    wire wfire,awfire;
    //aw
    assign awfire=awvalid&&awready;
    always @(posedge clk) begin
        if(rst) awvalid<=1'b0;
        else if(awfire)
            awvalid<=1'b0;
        else if(wen)
            awvalid<=1'b1;
    end
    //w
    assign wfire=wvalid&&wready;
    always @(posedge clk) begin
        if(rst) wvalid<=1'b0;
        else if(wfire)
            wvalid<=1'b0;
        else if(wen)
            wvalid<=1'b1;
    end
    //b
    assign bready=lsu_valid&&mytype[6]&&!wvalid&&!awvalid&&LSU_WBU_ready;
    //write function
    wire[3:0] aw_mask;
    assign wdata=(funct3[1:0] == 2'b00) ? {4{aux[7:0]}} :   // sb
                        (funct3[1:0] == 2'b01) ? {2{aux[15:0]}} :  // sh
                        aux;//sw
    assign {awaddr,awsize}={result,{1'b0,funct3[1:0]}};
    assign aw_mask={awsize[1],awsize[1],awsize[1]|awsize[0],1'b1};
    assign wstrb=aw_mask<<awaddr[1:0];
    //interface
    assign LSU_MEM_wrapper={arsize,awsize,arvalid,araddr,rready,awvalid,awaddr,wvalid,wdata,wstrb,bready};
    assign {arready,rvalid,rdata,rresp,awready,wready,bvalid,bresp}=MEM_LSU_wrapper;//save rdata?

    //FIFO
    reg [59:0] wrapper_reg;
    reg [31:0]aux_reg;
    wire register_wen_ok,register_wen_load,register_wen,type_fence_i;
    wire[31:0] aux,result;
    wire [8:0]mytype;
    wire [2:0]funct3;
    wire [6:0]trap_info;
    wire [4:0]rd;
    always @(posedge clk) begin
        if(EXU_LSU_fire)begin
            wrapper_reg<=EXU_wrapper;
            aux_reg<=aux_in;
        end
    end
    assign {register_wen_load,register_wen_ok,register_wen,type_fence_i,trap_info,rd,result,mytype,funct3}=wrapper_reg;
    assign aux=aux_reg;
    wire [31:0] result_out;
    assign result_out=mytype[5]?rdata_out:result;
    localparam CSR_MCYCLE_LO = 4'd0;
    localparam CSR_MCYCLE_HI = 4'd1;
    localparam CSR_MEPC      = 4'd2;
    localparam CSR_MSTATUS   = 4'd3;
    localparam CSR_MCAUSE    = 4'd4;
    localparam CSR_MTVEC     = 4'd5;
    localparam CSR_MVENDORID = 4'd6;
    localparam CSR_MARCHID   = 4'd7;
    reg[3:0] csr_addr;
    always @(*) begin
        csr_addr=4'd0;
        if(trap_info[0])begin
            case(aux[11:0])
                12'hb00:csr_addr={CSR_MCYCLE_LO};
                12'hb80:csr_addr={CSR_MCYCLE_HI};
                12'h341:csr_addr={CSR_MEPC};
                12'h300:csr_addr={CSR_MSTATUS};
                12'h342:csr_addr={CSR_MCAUSE};
                12'h305:csr_addr={CSR_MTVEC};
                12'hf11:csr_addr={CSR_MVENDORID};
                12'hf12:csr_addr={CSR_MARCHID};
                default:csr_addr=4'd0;
            endcase
        end
    end
`ifndef STA_MODE
    //difftest
    import "DPI-C" function void difftest_skip_ref();
    wire[31:0] addr=result;
    wire is_mimo/* verilator public_flat_rd */;
    wire is_mrom,is_sram,is_flash,is_psram,is_sdram;
    assign is_sdram=addr >= 32'ha0000000 && addr <= 32'hbfffffff;
    assign is_psram=addr >= 32'h80000000 && addr <= 32'h9fffffff;
    assign is_flash=addr >= 32'h30000000 && addr <= 32'h3fffffff;
    assign is_mrom =addr >= 32'h20000000 && addr <= 32'h20000fff;
    assign is_sram =addr >= 32'h0f000000 && addr <= 32'h0f001fff;
    assign is_mimo =(|mytype[6:5])&&!(is_mrom||is_sram||is_flash||is_psram||is_sdram);
`endif
`ifdef PERF_COUNTER
    reg [63:0] lsu_occupied_cycles;
    reg [63:0] lsu_out_count;
    reg [63:0] lsu_mem_wait_cycles;
    reg [63:0] lsu_wbu_block_cycles;

    reg [63:0] lsu_load_count;
    reg [63:0] lsu_store_count;
    reg [63:0] lsu_load_latency_sum;
    reg [63:0] lsu_store_latency_sum;
    reg [63:0] lsu_age;

    always @(posedge clk)begin
        if(rst)begin
            lsu_occupied_cycles<=64'd0;
            lsu_out_count<=64'd0;
            lsu_mem_wait_cycles<=64'd0;
            lsu_wbu_block_cycles<=64'd0;
            lsu_load_count<=64'd0;
            lsu_store_count<=64'd0;
            lsu_load_latency_sum<=64'd0;
            lsu_store_latency_sum<=64'd0;
            lsu_age<=64'd0;
        end else begin
            //阶段效率
            if(lsu_valid)
                lsu_occupied_cycles<=lsu_occupied_cycles+64'd1;
            if(LSU_WBU_fire)
                lsu_out_count<=lsu_out_count+64'd1;
            if(lsu_valid&&!LSU_WBU_valid)
                lsu_mem_wait_cycles<=lsu_mem_wait_cycles+64'd1;
            if(LSU_WBU_valid&&!LSU_WBU_ready)
                lsu_wbu_block_cycles<=lsu_wbu_block_cycles+64'd1;

            //当前指令的驻留周期，接收后下一拍输出记1
            if(EXU_LSU_fire)
                lsu_age<=64'd1;
            else if(lsu_valid)
                lsu_age<=lsu_age+64'd1;

            //完成时统计，使用当前指令的类型和驻留周期
            if(LSU_WBU_fire)begin
                if(mytype[5])begin
                    lsu_load_count<=lsu_load_count+64'd1;
                    lsu_load_latency_sum<=lsu_load_latency_sum+lsu_age;
                end else if(mytype[6])begin
                    lsu_store_count<=lsu_store_count+64'd1;
                    lsu_store_latency_sum<=lsu_store_latency_sum+lsu_age;
                end
            end
        end
    end
`endif
endmodule

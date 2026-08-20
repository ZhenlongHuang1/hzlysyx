module ysyx_26040117_LSU (clk,rst,
    EXU_LSU_ready,EXU_LSU_valid,result,aux,EXU_wrapper,mytype,funct,
    LSU_WBU_ready,LSU_WBU_valid,result_out,aux_out,LSU_wrapper,mytype_out,funct_out,rdata_out2,
    MEM_LSU_wrapper,LSU_MEM_wrapper
);
    input clk,rst;
    //EXU-LSU
    input EXU_LSU_valid;
    output EXU_LSU_ready;
    input [31:0]result,aux;
    input [7:0]EXU_wrapper;
    input [8:0]mytype;
    input [3:0]funct;
    //LSU-WBU
    input LSU_WBU_ready;
    output LSU_WBU_valid;
    output [31:0]result_out,aux_out;
    output [7:0]LSU_wrapper;
    output [8:0]mytype_out;
    output [3:0]funct_out;
    output [31:0]rdata_out2;
    //LSU-MEM
    input [40:0]MEM_LSU_wrapper;
    output[110:0] LSU_MEM_wrapper;

    reg lsu_valid;
    wire wen,ren;
    wire EXU_LSU_fire,LSU_WBU_fire;
    assign wen=mytype[6]&&EXU_LSU_fire;
    assign ren=mytype[5]&&EXU_LSU_fire;
    assign EXU_LSU_fire=EXU_LSU_ready&&EXU_LSU_valid;
    assign LSU_WBU_fire=LSU_WBU_ready&&LSU_WBU_valid;
    assign EXU_LSU_ready=!lsu_valid;
    assign LSU_WBU_valid=lsu_valid&&(!(|mytype_out[6:5])|| 
            (mytype_out[5]&&!arvalid&&rvalid)||
            (mytype_out[6]&&!awvalid&&!wvalid&&bvalid)
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
    wire arifsigned;
    assign rready=lsu_valid&&mytype_out[5]&&!arvalid&&LSU_WBU_ready;
    assign {araddr,arsize,arifsigned}={result_out,{1'b0,funct_out[1:0]},~funct_out[2]};
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
    assign bready=lsu_valid&&mytype_out[6]&&!wvalid&&!awvalid&&LSU_WBU_ready;
    //write function
    wire[3:0] aw_mask;
    assign wdata=(funct_out[1:0] == 2'b00) ? {4{aux_out[7:0]}} :   // sb
                        (funct_out[1:0] == 2'b01) ? {2{aux_out[15:0]}} :  // sh
                        aux_out;//sw
    assign {awaddr,awsize}={result_out,{1'b0,funct_out[1:0]}};
    assign aw_mask={awsize[1],awsize[1],awsize[1]|awsize[0],1'b1};
    assign wstrb=aw_mask<<awaddr[1:0];
    //interface
    assign LSU_MEM_wrapper={arsize,awsize,arvalid,araddr,rready,awvalid,awaddr,wvalid,wdata,wstrb,bready};
    assign {arready,rvalid,rdata,rresp,awready,wready,bvalid,bresp}=MEM_LSU_wrapper;//save rdata?

    wire [31:0] rdata_out;
    assign rdata_out=rdata;
    //read function
    reg[31:0] rdata2;
    wire[31:0] bitmask,bitnmask;
    wire[1:0] raddr_shift;
    wire [3:0] ar_mask;
    wire signbit;
    assign ar_mask={arsize[1],arsize[1],arsize[1]|arsize[0],1'b1};
    assign bitmask={{8{ar_mask[3]}},{8{ar_mask[2]}},{8{ar_mask[1]}},{8{ar_mask[0]}}};
    assign bitnmask={{8{~ar_mask[3]&&arifsigned}},{8{~ar_mask[2]&&arifsigned}},{8{~ar_mask[1]&&arifsigned}},{8{~ar_mask[0]&&arifsigned}}};
    assign raddr_shift=araddr[1:0];
    assign rdata_out2=(rdata2&bitmask)|(bitnmask&{32{signbit}});//符号拓展or 0拓展
    assign signbit=(~ar_mask[3]&&ar_mask[1]&&rdata2[15])||(~(|ar_mask[3:1])&&rdata2[7]);
    always @(*) begin
        case (raddr_shift)
            2'b00: rdata2=rdata_out;
            2'b01: rdata2={8'h0,rdata_out[31:8]}; 
            2'b10: rdata2={16'h0,rdata_out[31:16]};
            2'b11: rdata2={24'h0,rdata_out[31:24]};
            default:rdata2=rdata_out;
        endcase
    end
    //FIFO
    reg [31:0]result_reg,aux_reg;
    reg [7:0]wrapper_reg;
    reg [8:0]mytype_reg;
    reg [3:0]funct_reg;
    always @(posedge clk) begin
        if(EXU_LSU_fire)begin
            {result_reg,aux_reg,wrapper_reg,mytype_reg,funct_reg}<={result,aux,EXU_wrapper,mytype,funct};
        end
    end
    assign {result_out,aux_out,LSU_wrapper,mytype_out,funct_out}={result_reg,aux_reg,wrapper_reg,mytype_reg,funct_reg};
`ifndef STA_MODE
    //difftest
    import "DPI-C" function void difftest_skip_ref();
    wire[31:0] addr=result_out;
    wire is_mimo,is_mrom,is_sram,is_flash,is_psram,is_sdram;
    assign is_sdram=addr >= 32'ha0000000 && addr <= 32'hbfffffff;
    assign is_psram=addr >= 32'h80000000 && addr <= 32'h9fffffff;
    assign is_flash=addr >= 32'h30000000 && addr <= 32'h3fffffff;
    assign is_mrom =addr >= 32'h20000000 && addr <= 32'h20000fff;
    assign is_sram =addr >= 32'h0f000000 && addr <= 32'h0f001fff;
    assign is_mimo =(|mytype_out[6:5])&&!(is_mrom||is_sram||is_flash||is_psram||is_sdram);
    always @(posedge clk) begin
       if(is_mimo&&LSU_WBU_fire)
           difftest_skip_ref();
    end
`endif
`ifdef PERF_COUNTER
    reg [63:0] lsu_load_count,lsu_rwait_count,lsu_store_count,lsu_bwait_count;
    wire rfire,bfire;
    assign rfire=rvalid&&rready;
    assign bfire=bvalid&&bready;
    always @(posedge clk) begin
        if(rst)begin
            lsu_load_count<=64'd0;
            lsu_rwait_count<=64'd0;
            lsu_store_count<=64'd0;
            lsu_bwait_count<=64'd0;
        end else begin
            if(rfire)
                lsu_load_count<=lsu_load_count+64'd1;
            if(lsu_valid&&mytype_out[5]&&!arvalid&&!rvalid)
                lsu_rwait_count<=lsu_rwait_count+64'd1;
            if(bfire)
                lsu_store_count<=lsu_store_count+64'd1;
            if(lsu_valid&&mytype_out[6]&&!awvalid&&!wvalid&&!bvalid)
                lsu_bwait_count<=lsu_bwait_count+64'd1;
        end
    end
    reg [63:0] lsu_cycle;
    reg [63:0] lsu_start_cycle;
    reg [63:0] lsu_load_latency_sum;
    reg [63:0] lsu_store_latency_sum;
    reg        lsu_pending;
    reg        lsu_pending_wen;

    always @(posedge clk) begin
        if (rst) begin
            lsu_cycle             <= 64'd0;
            lsu_start_cycle       <= 64'd0;
            lsu_load_latency_sum  <= 64'd0;
            lsu_store_latency_sum <= 64'd0;
            lsu_pending           <= 1'b0;
            lsu_pending_wen       <= 1'b0;
        end else begin
            lsu_cycle <= lsu_cycle + 64'd1;
            if (!lsu_pending&&(ren||wen))begin
                lsu_start_cycle <= lsu_cycle;
                lsu_pending     <= 1'b1;
                lsu_pending_wen <= wen;
            end
            if (lsu_pending && !lsu_pending_wen && rfire) begin
                lsu_load_latency_sum <=lsu_load_latency_sum +(lsu_cycle - lsu_start_cycle);
                lsu_pending <= 1'b0;
            end
            if (lsu_pending && lsu_pending_wen && bfire) begin
                lsu_store_latency_sum <=lsu_store_latency_sum +(lsu_cycle - lsu_start_cycle);
                lsu_pending <= 1'b0;
            end
        end
    end

`endif
endmodule

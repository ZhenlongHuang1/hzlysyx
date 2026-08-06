module ysyx_26040117_LSU (clk,rst,
    reqValid,respReady,wen,addr,wdata_in,size,ifsigned,
    respValid,rdata_out2,rresp_out,bresp_out,
    MEM_LSU_wrapper,LSU_MEM_wrapper
);
    input clk,rst;
    input reqValid,respReady,wen;
    input[31:0] addr,wdata_in;
    input[2:0]size;
    input ifsigned;

    output respValid;
    output [31:0]rdata_out2;
    output [1:0]rresp_out,bresp_out;
    //LSU-MEM
    input [40:0]MEM_LSU_wrapper;
    output[110:0] LSU_MEM_wrapper;


    //read
    wire[31:0] rdata;
    wire[1:0] rresp;
    wire arready,rvalid,rready;
    reg arvalid;
    wire [31:0] araddr;
    wire [2:0] arsize;
    wire rIDLE_reqvalid,rfire,arfire;
    reg[1:0] rstate,rnext_state;
    localparam IDLE=2'd0,WAIT_READY=2'd1,WAIT_VALID=2'd2;
    always @(posedge clk) begin
        if(rst) rstate<=IDLE;
        else rstate<=rnext_state;
    end
    always @(*) begin
        rnext_state=rstate;
        case(rstate)
            IDLE:begin
                if(arfire)rnext_state=WAIT_VALID;
                else if(arvalid)rnext_state=WAIT_READY;
            end
            WAIT_READY:if(arfire)rnext_state=WAIT_VALID;
            WAIT_VALID:if(rfire)rnext_state=IDLE;
            default:rnext_state=rstate;
        endcase
    end
    assign rfire=rvalid&&rready;
    assign arfire=arvalid&&arready;
    assign rIDLE_reqvalid=rstate==IDLE&&reqValid&&!wen;
    always @(posedge clk) begin
        if(rst) arvalid<=1'b0;
        else begin
            if(arfire)arvalid<=1'b0;
            else if(rstate==WAIT_READY||rIDLE_reqvalid)arvalid<=1'b1;
        end
    end
    assign rready=rstate==WAIT_VALID&&!lsu_buf_valid;
    reg[31:0] araddr_reg;
    reg[2:0] arsize_reg;
    reg arifsigned_reg;
    wire arifsigned;
    always@(posedge clk)begin
        if(rst)begin
            {araddr_reg,arsize_reg,arifsigned_reg}<=36'h0;
        end else if(rIDLE_reqvalid)begin
            {araddr_reg,arsize_reg,arifsigned_reg}<={addr,size[2:0],ifsigned};
        end
    end
    assign {araddr,arsize,arifsigned}=rIDLE_reqvalid?{addr,size[2:0],ifsigned}:{araddr_reg,arsize_reg,arifsigned_reg};
    //write
    wire awready,wready,bvalid,bready;
    reg awvalid,wvalid;
    wire[1:0] bresp;
    wire [2:0] awsize;
    wire aw_w_valid;
    wire [31:0] awaddr,wdata;
    wire [3:0] wstrb;
    wire awIDLE_reqvalid,wIDLE_reqvalid,wfire,awfire,bfire;
    reg[1:0] awstate,awnext_state,wstate,wnext_state,bstate,bnext_state;
    always @(posedge clk) begin
        if(rst) {awstate,wstate,bstate}<={IDLE,IDLE,IDLE};
        else {awstate,wstate,bstate}<={awnext_state,wnext_state,bnext_state};
    end
    //aw
    always @(*) begin
        awnext_state=awstate;
        case(awstate)
            IDLE:begin
                if(awfire)awnext_state=WAIT_VALID;
                else if(awvalid)awnext_state=WAIT_READY;
            end
            WAIT_READY:if(awfire)awnext_state=WAIT_VALID;
            WAIT_VALID:if(bfire)awnext_state=IDLE;
            default:awnext_state=awstate;
        endcase
    end
    assign awfire=awvalid&&awready;
    assign awIDLE_reqvalid=awstate==IDLE&&reqValid&&wen;//modify?
    always @(posedge clk) begin
        if(rst) awvalid<=1'b0;
        else begin
            if(awfire)awvalid<=1'b0;
            else if(awstate==WAIT_READY||awIDLE_reqvalid)awvalid<=1'b1;
        end
    end
    //w
    always @(*) begin
        wnext_state=wstate;
        case(wstate)
            IDLE:begin
                if(wfire)wnext_state=WAIT_VALID;
                else if(wvalid)wnext_state=WAIT_READY;
            end
            WAIT_READY:if(wfire)wnext_state=WAIT_VALID;
            WAIT_VALID:if(bfire)wnext_state=IDLE;
            default:wnext_state=wstate;
        endcase
    end
    assign wfire=wvalid&&wready;
    assign wIDLE_reqvalid=wstate==IDLE&&reqValid&&wen;//modify?
    always @(posedge clk) begin
        if(rst) wvalid<=1'b0;
        else begin
            if(wfire)wvalid<=1'b0;
            else if(wstate==WAIT_READY||wIDLE_reqvalid)wvalid<=1'b1;
        end
    end
    //b
    always @(*) begin
        bnext_state=bstate;
        case(bstate)
            IDLE:if(aw_w_valid)bnext_state=WAIT_VALID;
            WAIT_VALID:if(bfire)bnext_state=IDLE;
            default:bnext_state=bstate;
        endcase
    end
    assign aw_w_valid=awstate==WAIT_VALID&&wstate==WAIT_VALID;
    assign bfire=bready&&bvalid;
    assign bready=bstate==WAIT_VALID&&!lsu_buf_valid;//modify?
    //write function
    wire[31:0] wdata_fomatted;
    reg[31:0] awaddr_reg,wdata_reg;
    reg[2:0] awsize_reg;
    wire[3:0] aw_mask;
    wire[1:0] awaddr_shift;

    always @(posedge clk) begin
        if(rst) {awaddr_reg,awsize_reg}<=35'h0;
        else if(awIDLE_reqvalid) {awaddr_reg,awsize_reg}<={addr,size[2:0]};
    end
    assign wdata_fomatted=(size[1:0] == 2'b00) ? {4{wdata_in[7:0]}} :   // sb
                        (size[1:0] == 2'b01) ? {2{wdata_in[15:0]}} :  // sh
                        wdata_in;//sw
    always@(posedge clk)begin
        if(rst) {wdata_reg}<=32'h0;
        else if(wIDLE_reqvalid) {wdata_reg}<={wdata_fomatted};
    end
    assign {wdata}=wIDLE_reqvalid?{wdata_fomatted}:{wdata_reg};
    assign {awaddr,awsize}=awIDLE_reqvalid?{addr,size[2:0]}:{awaddr_reg,awsize_reg};
    assign awaddr_shift=awaddr[1:0];
    assign aw_mask={awsize[1],awsize[1],awsize[1]|awsize[0],1'b1};
    assign wstrb=aw_mask<<awaddr_shift;
    //FIFO
    assign LSU_MEM_wrapper={arsize,awsize,arvalid,araddr,rready,awvalid,awaddr,wvalid,wdata,wstrb,bready};
    assign {arready,rvalid,rdata,rresp,awready,wready,bvalid,bresp}=MEM_LSU_wrapper;//save rdata?

    reg[31:0] rdata_reg;
    reg[1:0] rresp_reg,bresp_reg;
    reg lsu_buf_valid,is_read;
    wire[31:0] rdata_out;
    always @(posedge clk) begin
        if(rst)begin
            {rdata_reg,rresp_reg,bresp_reg,lsu_buf_valid,is_read}<=38'd0;
        end else begin
            if(respValid&&respReady)
               lsu_buf_valid<=1'b0;
            else if(rfire)begin
                rdata_reg<=rdata;
                rresp_reg<=rresp;
                lsu_buf_valid<=1'b1;
                is_read<=1'b1;
            end else if(bfire)begin
                bresp_reg<=bresp;
                lsu_buf_valid<=1'b1;
                is_read<=1'b0;
            end
        end
    end
    assign respValid=lsu_buf_valid||rfire||bfire;
    assign rdata_out=lsu_buf_valid&&is_read?rdata_reg:rdata;
    assign rresp_out=lsu_buf_valid&&is_read?rresp_reg:rresp;
    assign bresp_out=lsu_buf_valid&&!is_read?bresp_reg:bresp;
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
    //difftest
    import "DPI-C" function void difftest_skip_ref();
    wire is_mimo,is_mrom,is_sram,is_flash,is_psram,is_sdram;
    assign is_sdram=addr >= 32'ha0000000 && addr <= 32'hbfffffff;
    assign is_psram=addr >= 32'h80000000 && addr <= 32'h9fffffff;
    assign is_flash=addr >= 32'h30000000 && addr <= 32'h3fffffff;
    assign is_mrom =addr >= 32'h20000000 && addr <= 32'h20000fff;
    assign is_sram =addr >= 32'h0f000000 && addr <= 32'h0f001fff;
    assign is_mimo =reqValid&&!is_mrom&&!is_sram&&!is_flash&&!is_psram&&!is_sdram;
`ifndef STA_MODE
    always @(posedge clk) begin
       if(is_mimo&&respReady&&respValid)
           difftest_skip_ref();
    end
`endif
`ifdef PERF_COUNTER
    reg [63:0] lsu_load_count,lsu_rwait_count,lsu_store_count,lsu_bwait_count;
    always @(posedge clk) begin
        if(rst)begin
            lsu_load_count<=64'd0;
            lsu_rwait_count<=64'd0;
            lsu_store_count<=64'd0;
            lsu_bwait_count<=64'd0;
        end else begin
            if(rfire)
                lsu_load_count<=lsu_load_count+64'd1;
            if((rstate==WAIT_VALID)&&!rvalid)
                lsu_rwait_count<=lsu_rwait_count+64'd1;
            if(bfire)
                lsu_store_count<=lsu_store_count+64'd1;
            if((bstate==WAIT_VALID)&&!bvalid)
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
            if (!lsu_pending&&(rIDLE_reqvalid||(awIDLE_reqvalid&&wIDLE_reqvalid)))begin
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

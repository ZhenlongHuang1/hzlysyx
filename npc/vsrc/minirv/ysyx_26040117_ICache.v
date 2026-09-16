module ysyx_26040117_ICache#(RESET_VECTOR=32'h30000000)(
    input wire clk,
    input wire rst,
    input [66:0]IFU_ICACHE_wrapper,
    output[66:0]ICACHE_IFU_wrapper,
    input [34:0]MEM_ICACHE_wrapper,
    output[44:0]ICACHE_MEM_wrapper,
    output [31:0]btb_araddr,
    input [31:0]btb_target,
    input btb_hit
);
    parameter OFFSET_WIDTH=4,INDEX_WIDTH=2;
    localparam DATA_DEPTH=2**(OFFSET_WIDTH+INDEX_WIDTH-2);
    localparam WORD_NUM=2**(OFFSET_WIDTH-2);
    localparam BURST_LEN=WORD_NUM-1;
    localparam [29:0] RESET_PC=RESET_VECTOR[31:2];
    wire rready,rfire;
    wire fence_i,redirect_valid;
    wire [31:0] dnpc,idu_pc;
    assign rfire=rvalid&&rready;

    assign {fence_i,redirect_valid,dnpc,idu_pc,rready}=IFU_ICACHE_wrapper;
    assign ICACHE_IFU_wrapper={s1_btb_valid,fence_done,rvalid,araddr_reg,rdata};
    wire fence_clear=rst||fence_i||flush_pending||fence_done;
    wire pipe_clear=redirect_valid||fence_clear;
    //S1-FIFO 
    reg s1_valid,s1_redirect,s1_btb_valid;
    reg[29:0] s1_snpc,s1_dnpc;
    always @(posedge clk) begin
        if(redirect_valid)
            s1_dnpc<=dnpc[31:2];
        else if(btb_hit&&arfire)
            s1_dnpc<=btb_target[31:2];
    end
    wire[29:0] snpc_next=fence_done?idu_pc[31:2]:araddr[31:2];
    always @(posedge clk) begin
        if(rst)
            s1_snpc<=RESET_PC;
        else if(fence_done||arfire)
            s1_snpc<=snpc_next+30'd1;
    end
    wire [31:0] araddr={(s1_redirect||s1_btb_valid)?s1_dnpc:s1_snpc,2'b00};
    always @(posedge clk) begin
        if(rst)
            s1_valid<=1'b1;
        else if(fence_i||flush_pending)
            s1_valid<=1'b0;
        else if(fence_done)
            s1_valid<=1'b1;
    end
    always @(posedge clk) begin
        if(fence_clear)begin
            s1_redirect<=1'b0;
        end else if(redirect_valid)begin 
            s1_redirect<=1'b1;
        end else if(arfire)begin
            s1_redirect<=1'b0;
        end
    end
    wire is_sdram =araddr[31:29]==3'b101;//SDRAM
    wire [OFFSET_WIDTH-3:0] req_offset;
    wire[INDEX_WIDTH-1:0] req_index;
    wire[31-OFFSET_WIDTH-INDEX_WIDTH:0] req_tag;
    wire hit;
    assign req_offset=araddr[OFFSET_WIDTH-1:2];
    assign req_index=araddr[OFFSET_WIDTH +: INDEX_WIDTH];
    assign req_tag=araddr[31:OFFSET_WIDTH+INDEX_WIDTH];
    wire req_tag_match=tag_array[req_index]==req_tag;
    assign hit=valid_array[{req_index,req_offset}]&&req_tag_match;
    wire arvalid=s1_valid&&!pipe_clear;
    //BTB
    assign btb_araddr=araddr;
    always @(posedge clk) begin
        if(pipe_clear)
            s1_btb_valid<=1'b0;
        else if(arfire)
            s1_btb_valid<=btb_hit;
    end
    //S2
    wire out_ready=!rvalid||rready;
    wire arready=out_ready&&((state==IDLE)||((state==MISS_DATA)&&!miss_pending&&hit));
    wire arfire=arvalid&&arready;
    reg is_sdram_reg;

    reg rvalid;
    reg [31:0] rdata;
    wire refill_data_en=rfire_MEM&&((offset_count==offset_reg)||!is_sdram_reg);
    always @(posedge clk) begin
        if(out_ready)
            rdata<=miss_pending?rdata_MEM:data_array[{req_index,req_offset}];
    end
    always @(posedge clk) begin
        if(pipe_clear)begin
            rvalid<=1'd0;
        end else begin
            if(hit&&arfire)begin 
                rvalid<=1'b1;
            end else if(refill_data_en&&miss_pending)begin
                rvalid<=1'b1;//delay rfire -fence_i
            end else if(rfire)begin
                rvalid<=1'b0;
            end
        end
    end
    //ICache
    reg[31:0] data_array[0:DATA_DEPTH-1];
    reg[31-OFFSET_WIDTH-INDEX_WIDTH:0] tag_array[0:(2**INDEX_WIDTH)-1];
    reg[DATA_DEPTH-1:0] valid_array;

    wire  [OFFSET_WIDTH-3:0] offset_reg;
    reg  [OFFSET_WIDTH-3:0] offset_count;
    wire[INDEX_WIDTH-1:0] index_reg;
    wire [31-OFFSET_WIDTH-INDEX_WIDTH:0] tag_reg;
    reg[29:0]araddr_word_reg;
    wire[31:0] araddr_reg={araddr_word_reg,2'b00};
    reg [INDEX_WIDTH+OFFSET_WIDTH-3:0] miss_pos;
    reg miss_pending;
    reg req_tag_match_reg;

    assign tag_reg=araddr_reg[31:OFFSET_WIDTH+INDEX_WIDTH];
    assign {index_reg,offset_reg}=miss_pos;
    wire miss_fire=arfire&&!hit;
    always @(posedge clk) begin
        if(arfire)begin 
            araddr_word_reg<=araddr[31:2];
        end
        if(miss_fire)begin
            req_tag_match_reg<=req_tag_match;
            miss_pos<=araddr[INDEX_WIDTH+OFFSET_WIDTH-1:2];
        end
    end
    always @(posedge clk) begin
        if(pipe_clear)
            miss_pending<=1'b0;
        else if(miss_fire)
            miss_pending<=1'b1;
        else if(refill_data_en)
            miss_pending<=1'b0;
    end
    wire [OFFSET_WIDTH-3:0] refill_offset=is_sdram_reg?offset_count:offset_reg;
    always @(posedge clk) begin
        if(rst||fence_i||flush_pending) begin
            valid_array<=0;
        end else begin
            case(state)
                IDLE:if(miss_fire)begin
                        is_sdram_reg<=is_sdram;
                        offset_count<=req_offset;
                end
                MISS_AR:begin
                    tag_array[index_reg]<=tag_reg;
                    if(!req_tag_match_reg)
                        valid_array[index_reg*WORD_NUM +: WORD_NUM]<=0;
                end
                MISS_DATA:if(rfire_MEM)begin
                            data_array[{index_reg,refill_offset}]<=rdata_MEM;
                            valid_array[{index_reg,refill_offset}]<=1'b1;
                            if(is_sdram_reg&&!rlast)
                                offset_count<=offset_count+1'b1;
                        end
                default:;
            endcase
        end
    end
    //state machine
    localparam IDLE=0,MISS_AR=1,MISS_DATA=2;
    reg[1:0] state,next_state;
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else 
            state<=next_state;
    end
    always @(*) begin
        next_state=state;
        case(state)
            IDLE:if(miss_fire)next_state=MISS_AR;
            MISS_AR:if(arfire_MEM)next_state=MISS_DATA;
            MISS_DATA:if(rfire_MEM&&rlast)next_state=IDLE;
            default:next_state=IDLE;
        endcase
    end
    wire refill_done=(state==MISS_DATA)&&rfire_MEM&&rlast;
    reg flush_pending,fence_done;
    always @(posedge clk) begin
        if(rst)
            {flush_pending,fence_done}<=2'b0;
        else begin
            fence_done<=1'b0;
            if(fence_i)begin
                if((state==IDLE)||refill_done)begin
                    flush_pending<=1'b0;
                    fence_done<=1'b1;
                end else begin
                    flush_pending<=1'b1;
                end
            end else if(flush_pending&&refill_done)begin
                flush_pending<=1'b0;
                fence_done<=1'b1;
            end
        end
    end
    //ICache-arbiter
    wire arvalid_MEM,arready_MEM;
    wire arfire_MEM=arvalid_MEM&&arready_MEM;
    wire rvalid_MEM,rready_MEM;
    wire rfire_MEM=rvalid_MEM&&rready_MEM;
    wire [31:0] rdata_MEM,araddr_MEM;
    wire [7:0]arlen;
    wire rlast;
    assign arlen=is_sdram_reg?BURST_LEN:8'd0;
    assign araddr_MEM=araddr_reg;
    assign arvalid_MEM=state==MISS_AR;
    assign rready_MEM=state==MISS_DATA;
    assign ICACHE_MEM_wrapper={3'b010,arvalid_MEM,araddr_MEM,arlen,rready_MEM};
    assign {arready_MEM,rvalid_MEM,rdata_MEM,rlast}=MEM_ICACHE_wrapper;

`ifdef PERF_COUNTER
    reg [63:0] ifu_cycles;
    reg [63:0] ifu_occupied_cycles;
    reg [63:0] ifu_blocked_cycles;
    reg [63:0] ifu_out_count;

    reg [63:0] icache_access_count;
    reg [63:0] icache_hit_count;
    reg [63:0] icache_miss_done_count;
    reg [63:0] icache_miss_latency;
    reg [63:0] miss_start;

    always @(posedge clk)begin
        if(rst)begin
            ifu_cycles<=64'd0;
            ifu_occupied_cycles<=64'd0;
            ifu_blocked_cycles<=64'd0;
            ifu_out_count<=64'd0;
            icache_access_count<=64'd0;
            icache_hit_count<=64'd0;
            icache_miss_done_count<=64'd0;
            icache_miss_latency<=64'd0;
            miss_start<=64'd0;
        end else begin
            ifu_cycles<=ifu_cycles+64'd1;

            if(rvalid)
                ifu_occupied_cycles<=ifu_occupied_cycles+64'd1;
            if(rvalid&&!rready&&!pipe_clear)
                ifu_blocked_cycles<=ifu_blocked_cycles+64'd1;
            if(rfire)
                ifu_out_count<=ifu_out_count+64'd1;

            if(arfire)begin
                icache_access_count<=icache_access_count+64'd1;
                if(hit)
                    icache_hit_count<=icache_hit_count+64'd1;
                else begin
                    miss_start<=ifu_cycles;
                end
            end

            if(refill_data_en)begin
                icache_miss_done_count<=icache_miss_done_count+64'd1;
                icache_miss_latency<=icache_miss_latency+(ifu_cycles-miss_start+64'd1);
            end
        end
    end
`endif
endmodule

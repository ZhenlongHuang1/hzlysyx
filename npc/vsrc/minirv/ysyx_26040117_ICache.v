module ysyx_26040117_ICache(
    input wire clk,
    input wire rst,
    input [34:0]IFU_ICACHE_wrapper,
    output[34:0]ICACHE_IFU_wrapper,
    input [34:0]MEM_ICACHE_wrapper,
    output[44:0]ICACHE_MEM_wrapper
);
    parameter OFFSET_WIDTH=4,INDEX_WIDTH=2;
    localparam DATA_DEPTH=2**(OFFSET_WIDTH+INDEX_WIDTH-2);
    localparam WORD_NUM=2**(OFFSET_WIDTH-2);
    localparam BURST_LEN=WORD_NUM-1;
    wire arvalid,arready,rready;
    wire [31:0] araddr;
    wire rlast;
    reg rvalid;
    reg [31:0] rdata;
    wire rfire,arfire,rfire_MEM;
    wire fence_i;
    assign arfire=arvalid&&arready;
    assign rfire=rvalid&&rready;
    assign rfire_MEM=rvalid_MEM&&rready_MEM;
    wire is_sdram;
    reg is_sdram_reg;
    reg flush_pending,fence_done;
    assign is_sdram =araddr[31:29]==3'b101;//SDRAM
    //IFU-ICache
    assign arready=(state==IDLE)&&(!rvalid||rready)&&!flush_pending&&!fence_i;
    assign {fence_i,arvalid,araddr,rready}=IFU_ICACHE_wrapper;
    assign ICACHE_IFU_wrapper={fence_done,arready,rvalid,rdata};

    always @(posedge clk) begin
        if(rst||fence_i||flush_pending)begin
            rvalid<=1'd0;
        end else begin
            if((state==IDLE)&&hit&&arfire)begin 
                rdata<=data_array[{req_index,req_offset}];
                rvalid<=1'b1;
            end else if((state==MISS_DATA)&&rfire_MEM&&(offset_count==offset_reg||!is_sdram_reg))begin
                rdata<=rdata_MEM;
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

    wire [OFFSET_WIDTH-3:0] req_offset;
    reg  [OFFSET_WIDTH-3:0] offset_reg;
    reg  [OFFSET_WIDTH-3:0] offset_count;

    wire[INDEX_WIDTH-1:0] req_index;
    reg[INDEX_WIDTH-1:0] index_reg;
    wire[31-OFFSET_WIDTH-INDEX_WIDTH:0] req_tag;
    wire hit;
    reg[31:0]araddr_reg;
    assign req_offset=araddr[OFFSET_WIDTH-1:2];
    assign req_index=araddr[OFFSET_WIDTH +: INDEX_WIDTH];
    assign req_tag=araddr[31:OFFSET_WIDTH+INDEX_WIDTH];
    assign hit=valid_array[{req_index,req_offset}]&&(tag_array[req_index]==req_tag);
    always @(posedge clk) begin
        if(rst||fence_i||flush_pending) begin
            valid_array<=0;
        end else begin
            case(state)
                IDLE:if(arfire&&!hit)begin
                        araddr_reg<={araddr[31:OFFSET_WIDTH],is_sdram?{OFFSET_WIDTH{1'b0}}:araddr[OFFSET_WIDTH-1:0]};
                        is_sdram_reg<=is_sdram;
                        index_reg<=req_index;
                        offset_reg<=req_offset;
                        offset_count<=0;
                        tag_array[req_index]<=req_tag;
                        if(tag_array[req_index]!=req_tag)
                            valid_array[req_index*WORD_NUM +: WORD_NUM]<=0;
                end
                MISS_DATA:if(rfire_MEM)begin
                        if(is_sdram_reg)begin
                            data_array[{index_reg,offset_count}]<=rdata_MEM;
                            valid_array[{index_reg,offset_count}]<=1'b1;
                            if(!rlast)
                                offset_count<=offset_count+1'b1;
                        end else begin
                            data_array[{index_reg,offset_reg}]<=rdata_MEM;
                            valid_array[{index_reg,offset_reg}]<=1'b1;
                        end
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
            IDLE:if(!hit&&arfire)next_state=MISS_AR;
            MISS_AR:if(arfire_MEM)next_state=MISS_DATA;
            MISS_DATA:if(rfire_MEM&&rlast)next_state=IDLE;
            default:next_state=IDLE;
        endcase
    end
    wire refill_done=(state==MISS_DATA)&&rfire_MEM&&rlast;
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
    wire arfire_MEM;
    assign arfire_MEM=arvalid_MEM&&arready_MEM;
    wire rvalid_MEM,rready_MEM;
    wire [31:0] rdata_MEM,araddr_MEM;
    wire [7:0]arlen;
    assign arlen=is_sdram_reg?BURST_LEN:8'd0;
    assign araddr_MEM=araddr_reg;
    assign arvalid_MEM=state==MISS_AR;
    assign rready_MEM=state==MISS_DATA;
    assign ICACHE_MEM_wrapper={3'b010,arvalid_MEM,araddr_MEM,arlen,rready_MEM};
    assign {arready_MEM,rvalid_MEM,rdata_MEM,rlast}=MEM_ICACHE_wrapper;

`ifdef PERF_COUNTER
    reg [63:0] icache_access_count;
    reg [63:0] icache_hit_count;
    reg [63:0] icache_miss_count;
    reg [63:0] icache_total_latency;
    reg [63:0] icache_hit_latency;
    reg [63:0] icache_miss_latency;
    reg icache_access,icache_ifhit;
    wire icache_done;
    assign icache_done=icache_ifhit?rvalid:(rfire_MEM&&rlast);
    always @(posedge clk) begin
        if(rst)begin
            icache_hit_count<=64'd0;
            icache_miss_count<=64'd0;
            icache_access_count<=64'd0;
            icache_total_latency<=64'd0;
            icache_hit_latency<=64'd0;
            icache_miss_latency<=64'd0;
        end else begin
            if(arfire)begin
                icache_access_count<=icache_access_count+64'd1;
                if(hit) icache_hit_count<=icache_hit_count+64'd1;
                else icache_miss_count<=icache_miss_count+64'd1;
            end
            if(icache_access)begin
                icache_total_latency<=icache_total_latency+64'd1;
                if(icache_ifhit)icache_hit_latency<=icache_hit_latency+64'd1;
                else icache_miss_latency<=icache_miss_latency+64'd1;
            end
        end
    end
    always @(posedge clk) begin
        if(rst)begin
            icache_access<=1'b0;
            icache_ifhit<=1'b0;
        end else begin
            if(arfire)begin
                icache_access<=1'b1; 
                icache_ifhit<=hit;
            end else if(icache_done)begin
                icache_access<=1'b0;
            end

        end
    end

`endif

endmodule

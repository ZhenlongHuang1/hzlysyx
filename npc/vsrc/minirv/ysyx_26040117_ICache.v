module ysyx_26040117_ICache(
    input wire clk,
    input wire rst,
    input [35:0]IFU_ICACHE_wrapper,
    output[66:0]ICACHE_IFU_wrapper,
    input [34:0]MEM_ICACHE_wrapper,
    output[44:0]ICACHE_MEM_wrapper
);
    parameter OFFSET_WIDTH=4,INDEX_WIDTH=2;
    localparam DATA_DEPTH=2**(OFFSET_WIDTH+INDEX_WIDTH-2);
    localparam WORD_NUM=2**(OFFSET_WIDTH-2);
    localparam BURST_LEN=WORD_NUM-1;
    wire arvalid,arready,rready,rvalid;
    wire [31:0] araddr;
    wire rlast;
    reg [31:0] rdata;
    wire rfire,arfire,rfire_MEM;
    wire fence_i;
    assign arfire=arvalid&&arready;
    assign rfire=rvalid&&rready;
    assign rfire_MEM=rvalid_MEM&&rready_MEM;
    reg flush_pending,fence_done;

    //IFU-ICache
    wire redirect_valid;
    assign arready=!pipe_clear&&(state==IDLE)&&(!s1_valid||(s1_s2_fire&&s1_hit));
    assign {fence_i,redirect_valid,arvalid,araddr,rready}=IFU_ICACHE_wrapper;
    assign ICACHE_IFU_wrapper={fence_done,arready,rvalid,s2_araddr,rdata};
    wire pipe_clear=rst||redirect_valid||fence_i||flush_pending||fence_done;
    wire s1_s2_ready,s1_s2_valid;
    assign s1_s2_valid=s1_valid&&!pipe_clear;
    assign s1_s2_ready=(state==IDLE)&&(!s2_valid||rfire);
    
    //ICache
    reg[31:0] data_array[0:DATA_DEPTH-1];
    reg[31-OFFSET_WIDTH-INDEX_WIDTH:0] tag_array[0:(2**INDEX_WIDTH)-1];
    reg[DATA_DEPTH-1:0] valid_array;
    reg  [OFFSET_WIDTH-3:0] offset_count;
    //S1 
    wire [OFFSET_WIDTH-3:0] req_offset;
    wire[INDEX_WIDTH-1:0] req_index;
    wire[31-OFFSET_WIDTH-INDEX_WIDTH:0] req_tag;
    reg s1_valid,s2_valid;
    wire s1_s2_fire=s1_s2_valid&&s1_s2_ready;
    assign req_offset=araddr[OFFSET_WIDTH-1:2];
    assign req_index=araddr[OFFSET_WIDTH +: INDEX_WIDTH];
    assign req_tag=araddr[31:OFFSET_WIDTH+INDEX_WIDTH];
    wire is_sdram =araddr[31:29]==3'b101;//SDRAM
    wire hit=valid_array[{req_index,req_offset}]&&(tag_array[req_index]==req_tag);

    reg[31:0]s1_araddr;
    reg s1_is_sdram,s1_hit;
    always @(posedge clk) begin
        if(arfire)begin
            s1_hit<=hit;
            s1_is_sdram<=is_sdram;
            s1_araddr<=araddr;
        end
    end
    wire [OFFSET_WIDTH-3:0] s1_offset;
    wire[INDEX_WIDTH-1:0] s1_index;
    wire[31-OFFSET_WIDTH-INDEX_WIDTH:0] s1_tag;
    assign s1_offset=s1_araddr[OFFSET_WIDTH-1:2];
    assign s1_index=s1_araddr[OFFSET_WIDTH +: INDEX_WIDTH];
    assign s1_tag=s1_araddr[31:OFFSET_WIDTH+INDEX_WIDTH];
    always @(posedge clk) begin
        if(pipe_clear)
            s1_valid<=1'b0;
        else if(arfire)
            s1_valid<=1'b1;
        else if(s1_s2_fire)
            s1_valid<=1'b0;
    end
    //S2
    reg [31:0] s2_araddr;
    reg s2_is_sdram;
    wire [OFFSET_WIDTH-3:0] s2_offset;
    wire[INDEX_WIDTH-1:0] s2_index;
    assign s2_offset=s2_araddr[OFFSET_WIDTH-1:2];
    assign s2_index=s2_araddr[OFFSET_WIDTH +: INDEX_WIDTH];
    always @(posedge clk)begin
        if(s1_s2_fire)begin
            s2_araddr<=s1_araddr;
            s2_is_sdram<=s1_is_sdram;
        end
    end
    always @(posedge clk) begin
        if(rst||fence_i||flush_pending) begin
            valid_array<=0;
        end else begin
            case(state)
                IDLE:if(s1_s2_fire&&!s1_hit)begin
                        offset_count<=0;
                        tag_array[s1_index]<=s1_tag;
                        if(tag_array[s1_index]!=s1_tag)
                            valid_array[s1_index*WORD_NUM +: WORD_NUM]<=0;
                end
                MISS_DATA:if(rfire_MEM)begin
                        if(s2_is_sdram)begin
                            data_array[{s2_index,offset_count}]<=rdata_MEM;
                            valid_array[{s2_index,offset_count}]<=1'b1;
                            if(!rlast)
                                offset_count<=offset_count+1'b1;
                        end else begin
                            data_array[{s2_index,s2_offset}]<=rdata_MEM;
                            valid_array[{s2_index,s2_offset}]<=1'b1;
                        end
                    end
                default:;
            endcase
        end
    end
    reg data_valid;
    assign rvalid=data_valid&&s2_valid&&!pipe_clear;
    always @(posedge clk) begin
        if(rst)
            data_valid<=1'b0;
        else if(s1_s2_fire)
            data_valid<=s1_hit;
        else if(rfire_MEM&&(offset_count==s2_offset||!s2_is_sdram))
            data_valid<=1'b1;
        else if(rfire)
            data_valid<=1'b0;
    end
    always @(posedge clk) begin
        if(s1_s2_fire&&s1_hit)begin 
            rdata<=data_array[{s1_index,s1_offset}];
        end else if(rfire_MEM&&(offset_count==s2_offset||!s2_is_sdram))begin
            rdata<=rdata_MEM;
        end
    end
    always @(posedge clk) begin
        if(pipe_clear)
            s2_valid<=1'b0;
        else if(s1_s2_fire)
            s2_valid<=1'b1;
        else if(rfire)
            s2_valid<=1'b0;
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
            IDLE:if(!s1_hit&&s1_s2_fire)next_state=MISS_AR;
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
    assign arlen=s2_is_sdram?BURST_LEN:8'd0;
    assign araddr_MEM={s2_araddr[31:OFFSET_WIDTH],s2_is_sdram?{OFFSET_WIDTH{1'b0}}:s2_araddr[OFFSET_WIDTH-1:0]};
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
            if(s1_s2_fire)begin
                icache_access_count<=icache_access_count+64'd1;
                if(s1_hit) icache_hit_count<=icache_hit_count+64'd1;
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
        if(rst||pipe_clear)begin
            icache_access<=1'b0;
            icache_ifhit<=1'b0;
        end else begin
            if(s1_s2_fire)begin
                icache_access<=1'b1; 
                icache_ifhit<=s1_hit;
            end else if(icache_done)begin
                icache_access<=1'b0;
            end

        end
    end

`endif

endmodule

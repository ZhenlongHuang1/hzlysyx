module ysyx_26040117_ICache(
    input wire clk,
    input wire rst,
    input [33:0]IFU_ICACHE_wrapper,
    output[33:0]ICACHE_IFU_wrapper,
    input [34:0]MEM_ICACHE_wrapper,
    output[44:0]ICACHE_MEM_wrapper
);
    parameter OFFSET_WIDTH=4,INDEX_WIDTH=2;
    localparam DATA_DEPTH=2**(OFFSET_WIDTH+INDEX_WIDTH-2);
    localparam BURST_LEN=(2**(OFFSET_WIDTH-2))-1;
    localparam WORD_NUM=2**(OFFSET_WIDTH-2);
    wire arvalid,arready,rready;
    wire [31:0] araddr;
    wire rvalid,rlast;
    wire [31:0] rdata;
    wire rfire,arfire,rfire_MEM;
    assign arfire=arvalid&&arready;
    assign rfire=rvalid&&rready;
    assign rfire_MEM=rvalid_MEM&&rready_MEM;
    wire ar_in_sdram;
    reg in_sdram_reg;
    assign ar_in_sdram =araddr>=32'ha0000000&&araddr<=32'hbfffffff;//SDRAM
    //IFU-ICache
    assign arready=(state==IDLE)&&!rvalid_hit&&(hit||arready_MEM);
    assign rvalid=rvalid_hit;
    assign rdata= rdata_hit;
    assign {arvalid,araddr,rready}=IFU_ICACHE_wrapper;
    assign ICACHE_IFU_wrapper={arready,rvalid,rdata};

    reg rvalid_hit;
    reg [31:0] rdata_hit;
    always @(posedge clk) begin
        if(rst)begin
            rdata_hit<=32'd0;
            rvalid_hit<=1'd0;
        end else begin
            if(rfire)begin
                rvalid_hit<=1'b0;
            end else if((state==IDLE)&&hit&&arfire)begin 
                rdata_hit<=data_array[{req_index,req_offset}];
                rvalid_hit<=1'b1;
            end else if((state==MISS)&&rfire_MEM)begin
                if(offset_count==offset_reg||!in_sdram_reg)begin
                    rdata_hit<=rdata_MEM;
                    rvalid_hit<=1'b1;
                end
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
    reg[31-OFFSET_WIDTH-INDEX_WIDTH:0] tag_reg;
    wire hit;
    assign req_offset=araddr[OFFSET_WIDTH-1:2];
    assign req_index=araddr[OFFSET_WIDTH +: INDEX_WIDTH];
    assign req_tag=araddr[31:OFFSET_WIDTH+INDEX_WIDTH];
    assign hit=valid_array[{req_index,req_offset}]&&(tag_array[req_index]==req_tag);
    always @(posedge clk) begin
        if(rst) begin
            valid_array<=0;
        end else begin
            case(state)
                IDLE:if(arfire&&!hit)begin
                        in_sdram_reg<=ar_in_sdram;
                        index_reg<=req_index;
                        tag_reg<=req_tag;
                        offset_reg<=req_offset;
                        offset_count<=0;
                        if(tag_array[req_index]!=req_tag)
                            valid_array[req_index*WORD_NUM +: WORD_NUM]<=0;
                end
                MISS:if(rfire_MEM)begin
                        if(in_sdram_reg)begin
                            data_array[{index_reg,offset_count}]<=rdata_MEM;
                            valid_array[{index_reg,offset_count}]<=1'b1;
                            if(!rlast)
                                offset_count<=offset_count+1'b1;
                        end else begin
                            data_array[{index_reg,offset_reg}]<=rdata_MEM;
                            valid_array[{index_reg,offset_reg}]<=1'b1;
                        end
                        if(rlast)
                            tag_array[index_reg]<=tag_reg;
                    end
                default:;
            endcase
        end
    end
    //state machine
    localparam IDLE=0,MISS=1;
    reg state,next_state;
    always @(posedge clk) begin
        if(rst)
            state<=IDLE;
        else 
            state<=next_state;
    end
    always @(*) begin
        next_state=state;
        case(state)
            IDLE:if(!hit&&arfire)next_state=MISS;
            MISS:if(rfire_MEM&&rlast)next_state=IDLE;
            default:next_state=IDLE;
        endcase
    end
    //ICache-arbiter
    wire arvalid_MEM,arready_MEM;
    wire rvalid_MEM,rready_MEM;
    wire [31:0] rdata_MEM,araddr_MEM;
    wire [7:0]arlen;
    assign arlen=ar_in_sdram?BURST_LEN:8'd0;
    assign araddr_MEM={araddr[31:OFFSET_WIDTH],ar_in_sdram?{OFFSET_WIDTH{1'b0}}:araddr[OFFSET_WIDTH-1:0]};
    assign arvalid_MEM=(state==IDLE)&&!rvalid_hit&&arvalid&&!hit;
    assign rready_MEM=state==MISS;
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
            if(arvalid)begin
                icache_access<=1'b1; 
                icache_ifhit<=hit;
            end else if(icache_done)begin
                icache_access<=1'b0;
            end

        end
    end

`endif

endmodule

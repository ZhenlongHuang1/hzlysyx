module ysyx_26040117_ICache(
    input wire clk,
    input wire rst,
    input [33:0]IFU_ICACHE_wrapper,
    output[33:0]ICACHE_IFU_wrapper,
    input [40:0]MEM_ICACHE_wrapper,
    output[107:0] ICACHE_MEM_wrapper
);
    parameter OFFSET_WIDTH=2,INDEX_WIDTH=4;
    wire arvalid,arready,rready;
    wire [31:0] araddr;
    wire rvalid;
    wire [31:0] rdata;
    wire rfire,arfire;
    assign arfire=arvalid&&arready;
    assign rfire=rvalid&&rready;
    //IFU-ICache
    assign arready=(state==IDLE)&&!rvalid_hit&&(hit||arready_MEM);
    assign rvalid=(state==IDLE)?rvalid_hit:rvalid_MEM;
    assign rdata= (state==IDLE)?rdata_hit:rdata_MEM;
    assign {arvalid,araddr,rready}=IFU_ICACHE_wrapper;
    assign ICACHE_IFU_wrapper={arready,rvalid,rdata};

    reg rvalid_hit;
    reg [31:0] rdata_hit;
    always @(posedge clk) begin
        if(rst)begin
            rdata_hit<=32'd0;
            rvalid_hit<=1'd0;
        end else begin
            case(state)
                IDLE:if(rfire)begin
                    rdata_hit<=32'd0;
                    rvalid_hit<=1'b0;
                end else if(hit&&arfire)begin 
                    rdata_hit<=data_array[req_index];
                    rvalid_hit<=1'b1;
                end
                MISS:if(rfire)begin
                    rdata_hit<=32'd0;
                    rvalid_hit<=1'b0;
                end
                default:rdata_hit<=32'd0;
            endcase
        end
    end
    //ICache
    reg[31:0] data_array[0:(2**INDEX_WIDTH)-1];
    reg[31-OFFSET_WIDTH-INDEX_WIDTH:0] tag_array[0:(2**INDEX_WIDTH)-1];
    reg[(2**INDEX_WIDTH)-1:0] valid_array;
    wire[INDEX_WIDTH-1:0] req_index;
    reg[INDEX_WIDTH-1:0] index_reg;
    wire[31-OFFSET_WIDTH-INDEX_WIDTH:0] req_tag;
    reg[31-OFFSET_WIDTH-INDEX_WIDTH:0] tag_reg;
    wire hit;
    assign req_index=araddr[OFFSET_WIDTH +: INDEX_WIDTH];
    assign req_tag=araddr[31:OFFSET_WIDTH+INDEX_WIDTH];
    assign hit=valid_array[req_index]&&(tag_array[req_index]==req_tag);
    always @(posedge clk) begin
        if(rst) begin
            valid_array<=0;
        end else begin
            case(state)
                IDLE:if(arfire&&!hit)begin
                        index_reg<=req_index;
                        tag_reg<=req_tag;
                end
                MISS:if(rfire)begin
                        valid_array[index_reg]<=1'b1;
                        data_array[index_reg]<=rdata_MEM;
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
            IDLE:if(arvalid&&!hit&&arfire)next_state=MISS;
            MISS:if(rfire)next_state=IDLE;
            default:next_state=IDLE;
        endcase
    end
    //ICache-arbiter
    wire arvalid_MEM,arready_MEM;
    wire rvalid_MEM;
    wire [31:0] rdata_MEM;
    assign arvalid_MEM=(state==IDLE)&&!rvalid_hit&&arvalid&&!hit;
    assign ICACHE_MEM_wrapper={3'b010,arvalid_MEM,araddr,rready,1'b0,32'd0,1'b0,32'd0,4'd0,1'b0};
    assign {arready_MEM,rvalid_MEM,rdata_MEM}=MEM_ICACHE_wrapper[40:7];

`ifdef PERF_COUNTER
    reg [63:0] icache_access_count;
    reg [63:0] icache_hit_count;
    reg [63:0] icache_miss_count;
    reg [63:0] icache_total_latency;
    reg [63:0] icache_hit_latency;
    reg [63:0] icache_miss_latency;
    reg icache_access,icache_ifhit;
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
            end else if(rvalid)begin
                icache_access<=1'b0;
            end

        end
    end

`endif

endmodule

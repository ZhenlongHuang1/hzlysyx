module ysyx_26040117_counter #(DELAY_VAL=5)(clk,rst,
    wen,delay_over
);
    input clk,rst;
    input wen;
    output reg delay_over;
    reg[7:0] delay_cnt;
    reg running,clear;
    always@(posedge clk)begin
        if(rst)begin
            delay_cnt<=DELAY_VAL-1;
            running<=0;
            delay_over<=0;
            clear<=0;
        end else begin
            delay_over<=0;
            if(wen&&!running&&!clear)begin
                delay_cnt<=DELAY_VAL-1;
                running<=1;
                delay_over<=0;
                clear<=1;
            end
            if(!wen)
                clear<=0;
            if(running)begin
                if(delay_cnt>1)begin
                    delay_cnt<=delay_cnt-8'd1;
                end else begin
                    running<=0;
                    delay_over<=1;
                end
            end
        end
    end

endmodule

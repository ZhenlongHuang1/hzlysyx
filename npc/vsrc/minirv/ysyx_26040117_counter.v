module ysyx_26040117_counter (clk,rst,
    wen,delay_over
);
    input clk,rst;
    input wen;
    output delay_over;
    wire [7:0] delay_val;
    wire [7:0] delay_val0;
    reg[7:0] delay_cnt;
    reg running,clear;
    ysyx_26040117_LFshifter lfshifter1(.clk(clk),.rst(rst),.wen(delay_over),.outQ(delay_val0));
    //assign delay_val={4'd0,delay_val0[3:0]};
    assign delay_val={8'd0};
    always@(posedge clk)begin
        if(rst)begin
            delay_cnt<=delay_val;
            running<=0;
            clear<=0;
        end else begin
            if(wen&&!running&&!clear)begin
                delay_cnt<=delay_val;
                running<=1;
                clear<=1;
            end
            if(!wen)
                clear<=0;
            if(running)begin
                if(delay_cnt>1)begin
                    delay_cnt<=delay_cnt-8'd1;
                end else begin
                    running<=0;
                end
            end
        end
    end
    assign delay_over=(delay_val==0&&wen==1)||(delay_cnt==1&&running==1);

endmodule

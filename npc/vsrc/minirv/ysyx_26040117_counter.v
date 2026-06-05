module ysyx_26040117_counter (clk,rst,
    wen,delay_over,ptemp
);
    input clk,rst;
    input wen,ptemp;
    output delay_over;
    wire [7:0] delay_val;
    wire [7:0] delay_val0;
    reg[7:0] delay_cnt;
    reg running,clear;
    reg wen_q1;
    always @(posedge clk) begin
        wen_q1<=wen;
    end
    ysyx_26040117_LFshifter lfshifter1(.clk(clk),.rst(rst),.wen(!wen&&wen_q1),.outQ(delay_val0));
    assign delay_val={5'd0,delay_val0[1:0],ptemp};
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
    assign delay_over=(delay_val==0)||(delay_cnt==1&&running==1);

endmodule

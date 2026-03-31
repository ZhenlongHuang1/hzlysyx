module ysyx_keyboard(clk,rst,ps2_clk,ps2_data,h8,h7,h4,h3,h2,h1,overflow);
    input clk,rst,ps2_clk,ps2_data;
    output overflow;
    output[7:0] h4,h3,h2,h1,h8,h7;
    wire nextdata_n,ready;
    wire[7:0]data0,data1,data2,data_output;
    wire read_flag;
    wire[7:0] count;
    ysyx_ps2_keyboard i0(.clk(clk),.rst(rst),.ps2_clk(ps2_clk),.ps2_data(ps2_data),.nextdata_n(nextdata_n),.data(data0),.ready(ready),.overflow(overflow));
    ysyx_Reg reg1(.clk(clk),.rst(rst),.din(~ready),.dout(nextdata_n),.wen(1'b1));//show right away
    assign read_flag=ready&(~nextdata_n);
    ysyx_Reg #(.WIDTH(8)) reg3 (.clk(clk),.rst(rst),.din(data0),.dout(data1),.wen(read_flag));     
    ysyx_Reg #(.WIDTH(8),.RESET_VAL(8'hf0)) reg4 (.clk(clk),.rst(rst),.din(data1),.dout(data2),.wen(read_flag)); 
    ysyx_Reg #(.WIDTH(8)) icount1(.clk(clk),.rst(rst),.din(count+8'd1),.dout(count),.wen(data2==8'hf0&&read_flag));    
    assign data_output=data1&{8{read_flag}};
    ysyx_bcd7seg bcd1(data_output[7:4],h2);    
    ysyx_bcd7seg bcd2(data_output[3:0],h1);
    ysyx_bcd7seg bcd3(count[7:4],h8);
    ysyx_bcd7seg bcd4(count[3:0],h7);
endmodule

module ysyx_keyboard(clk,rst,ps2_clk,ps2_data,h8,h7,h4,h3,h2,h1,overflow);
    input clk,rst,ps2_clk,ps2_data;
    output overflow;
    output[7:0] h4,h3,h2,h1,h8,h7;
    wire nextdata_n,ready;
    wire[7:0]data0,data1,data2,data_output,ascii_out;
    wire read_flag,key_down,key_up;
    wire[7:0] count;
    ysyx_ps2_keyboard i0(.clk(clk),.rst(rst),.ps2_clk(ps2_clk),.ps2_data(ps2_data),.nextdata_n(nextdata_n),.data(data0),.ready(ready),.overflow(overflow));
    ysyx_Reg reg1(.clk(clk),.rst(rst),.din(~ready),.dout(nextdata_n),.wen(1'b1));//show right away
    assign read_flag=ready&(~nextdata_n);
    assign key_down=read_flag&(data0!=8'hf0)&(data1!=8'hf0)&((data0!=data1)|data2==8'hf0);
    ysyx_Reg reg2(.clk(clk),.rst(data1==8'hf0),.din(1'b1),.dout(key_up),.wen(key_down));
    ysyx_Reg #(.WIDTH(8)) reg3 (.clk(clk),.rst(rst),.din(data0),.dout(data1),.wen(read_flag));     
    ysyx_Reg #(.WIDTH(8),.RESET_VAL(8'hf0)) reg4 (.clk(clk),.rst(rst),.din(data1),.dout(data2),.wen(read_flag)); 
    ysyx_Reg #(.WIDTH(8)) icount1(.clk(clk),.rst(rst),.din(count+8'd1),.dout(count),.wen(key_down));    
    ysyx_ascii_rom ascii1(data_output,ascii_out);
    assign data_output=data0&{8{key_up}};
    ysyx_bcd7seg bcd1(data_output[7:4],h2,~key_up);    
    ysyx_bcd7seg bcd2(data_output[3:0],h1,~key_up);
    ysyx_bcd7seg bcd3(count[7:4],h8,0);
    ysyx_bcd7seg bcd4(count[3:0],h7,0);
    ysyx_bcd7seg bcd5(ascii_out[7:4],h4,~key_up); 
    ysyx_bcd7seg bcd6(ascii_out[3:0],h3,~key_up);
endmodule

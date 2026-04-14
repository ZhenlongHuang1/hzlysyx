module ex2(input[7:0]x,input en,output[7:0] h,output[2:0]y,output flag 
);
    ysyx_26040117_encode83 encode83_1(.x(x),.en(en),.y(y),.flag(flag));
    ysyx_26040117_bcd7seg bcd7seg(.b({1'b0,y}),.h(h),.rst(0));
endmodule

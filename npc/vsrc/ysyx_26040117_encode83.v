module ysyx_26040117_encode83(
    input [7:0] x,
    input en,
    output [2:0] y,
    output flag
);
    assign y[2]=en&(|x[7:4]);
    assign y[1]=en&(x[7]|x[6]|(~x[5]&~x[4]&(x[3]|x[2])));
    assign y[0]=en&(x[7]|(~x[6]&x[5])|(~y[2]&(x[3]|(~x[2]&x[1]))));
    assign flag=en&((|y)|x[0]);

endmodule

module ysyx_26040117_encode164(in,out);
    input[15:0] in;
    output [3:0] out;
    assign out[3]=|in[15:8];
    assign out[2]=(|in[15:12])|(|in[7:4]);
    assign out[1]=(|in[15:14])|(|in[11:10])|(|in[7:6])|(|in[3:2]);
    assign out[0]=in[15]|in[13]|in[11]|in[9]|in[7]|in[5]|in[3]|in[1];
endmodule

module ysyx_26040117_bcd7seg(
  input  [3:0] b,
  output [7:0] h,
  input rst
);
    assign h[7]=rst|~((b==4'h0)|(b==4'h2)|(b==4'h3)|(b==4'h5)|(b==4'h6)|(b==4'h7)|(b==4'h8)|(b==4'h9)|(b==4'ha)|(b==4'hc)|(b==4'he)|(b==4'hf));
    assign h[6]=rst|~((b==4'h0)|(b==4'h1)|(b==4'h2)|(b==4'h3)|(b==4'h4)|(b==4'h7)|(b==4'h8)|(b==4'h9)|(b==4'ha)|(b==4'hd));
    assign h[5]=rst|~((b==4'h0)|(b==4'h1)|(b==4'h3)|(b==4'h4)|(b==4'h5)|(b==4'h6)|(b==4'h7)|(b==4'h8)|(b==4'h9)|(b==4'ha)|(b==4'hb)|(b==4'hd));
    assign h[4]=rst|~((b==4'h0)|(b==4'h2)|(b==4'h3)|(b==4'h5)|(b==4'h6)|(b==4'h8)|(b==4'h9)|(b==4'hb)|(b==4'hc)|(b==4'hd)|(b==4'he));
    assign h[3]=rst|~((b==4'h0)|(b==4'h2)|(b==4'h6)|(b==4'h8)|(b==4'ha)|(b==4'hb)|(b==4'hc)|(b==4'hd)|(b==4'he)|(b==4'hf));
    assign h[2]=rst|~((b==4'h0)|(b==4'h4)|(b==4'h5)|(b==4'h6)|(b==4'h8)|(b==4'h9)|(b==4'ha)|(b==4'hb)|(b==4'hc)|(b==4'he)|(b==4'hf));
    assign h[1]=rst|~((b==4'h2)|(b==4'h3)|(b==4'h4)|(b==4'h5)|(b==4'h6)|(b==4'h8)|(b==4'h9)|(b==4'ha)|(b==4'hb)|(b==4'hd)|(b==4'he)|(b==4'hf));
    assign h[0]=1;
endmodule

module ysyx_26040117_bshifter #(DATA_LENGTH=8)(
    input[DATA_LENGTH-1:0] din,
    input[2:0] shamt,
    input LR,
    input AL,
    output[DATA_LENGTH-1:0] dout
);
    wire[DATA_LENGTH-1:0] q1,q2;
    wire high;
    assign high=AL&din[DATA_LENGTH-1];
    ysyx_26040117_MuxKey #(4,2,DATA_LENGTH) mux1(q1,{LR,shamt[0]},{
    2'b00,din,
    2'b01,{high,din[DATA_LENGTH-1:1]},
    2'b10,din,
    2'b11,{din[DATA_LENGTH-2:0],1'b0}
    });

    ysyx_26040117_MuxKey #(4,2,DATA_LENGTH) mux2(q2,{LR,shamt[1]},{
    2'b00,q1,
    2'b01,{{2{high}},q1[DATA_LENGTH-1:2]},
    2'b10,q1,
    2'b11,{q1[DATA_LENGTH-3:0],2'b0}
    });

    ysyx_26040117_MuxKey #(4,2,DATA_LENGTH) mux3(dout,{LR,shamt[2]},{
    2'b00,q2,
    2'b01,{{4{high}},q2[DATA_LENGTH-1:4]},
    2'b10,q2,
    2'b11,{q2[DATA_LENGTH-5:0],4'b0}
    });
endmodule

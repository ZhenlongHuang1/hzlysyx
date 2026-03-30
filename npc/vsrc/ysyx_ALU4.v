module ysyx_ALU4 #(SEL_LENGTH=3,DATA_LENGTH=4)(
    input[SEL_LENGTH-1:0] sel,
    input[DATA_LENGTH-1:0] A,
    input[DATA_LENGTH-1:0] B,
    output[DATA_LENGTH-1:0] out,
    output zero,
    output overflow,
    output carry
);
    wire cin,less;
    wire[DATA_LENGTH-1:0] result,t_no_cin;
    assign cin=sel[0]|sel[1];//change if encode change
    assign t_no_cin={DATA_LENGTH{cin}}^B;
    assign {carry,result}=A+t_no_cin+cin;
    assign overflow=(A[DATA_LENGTH-1]==t_no_cin[DATA_LENGTH-1])&&(result[DATA_LENGTH-1]!=A[DATA_LENGTH-1]);
    assign zero=~(|result);
    assign less=overflow^result[DATA_LENGTH-1];//unsigned less=~carry
    ysyx_MuxKey #(8,SEL_LENGTH,DATA_LENGTH) i0(out,sel,{
    3'b000,result,
    3'b001,result,
    3'b010,~A,
    3'b011,A&B,
    3'b100,A|B,
    3'b101,A^B,
    3'b110,{{(DATA_LENGTH-1){1'b0}},less},
    3'b111,{{(DATA_LENGTH-1){1'b0}},zero}
    });


endmodule

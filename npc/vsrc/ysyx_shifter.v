module ysyx_shifter #(DATA_LENGTH=8)(
    input clk,
    input rst,
    input in,
    input[2:0] sel,
    input[DATA_LENGTH-1:0] din,
    output reg[DATA_LENGTH-1:0] Q
);
    wire[DATA_LENGTH-1:0] Q_next;
    ysyx_MuxKey #(8,3,DATA_LENGTH) i0(Q_next,sel,{
    3'b000,{(DATA_LENGTH){1'b0}},
    3'b001,din,
    3'b010,{1'b0,Q[DATA_LENGTH-1:1]},
    3'b011,{Q[DATA_LENGTH-2:0],1'b0},
    3'b100,{Q[DATA_LENGTH-1],Q[DATA_LENGTH-1:1]},
    3'b101,{in,Q[DATA_LENGTH-1:1]},
    3'b110,{Q[0],Q[DATA_LENGTH-1:1]},
    3'b111,{Q[DATA_LENGTH-2:0],Q[DATA_LENGTH-1]}
    }); 
    always@(posedge clk)begin
        if(rst)
            Q<={(DATA_LENGTH){1'b0}};
        else begin
            Q<=Q_next;
        end
    end

endmodule

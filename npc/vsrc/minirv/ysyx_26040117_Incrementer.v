module ysyx_26040117_Incrementer #(
    parameter WIDTH=64
)(
    input  [WIDTH-1:0] data,
    output [WIDTH-1:0] result
);

    localparam LEVELS=$clog2(WIDTH);

    wire [WIDTH-1:0] prefix[0:LEVELS];

    assign prefix[0]=data;

    genvar level,bit_index;
    generate
        for(level=0;level<LEVELS;level=level+1)begin:GEN_LEVEL
            for(bit_index=0;bit_index<WIDTH;
                bit_index=bit_index+1)begin:GEN_BIT

                if(bit_index>=(1<<level))begin:MERGE
                    assign prefix[level+1][bit_index]=
                        prefix[level][bit_index]&
                        prefix[level][bit_index-(1<<level)];
                end else begin:PASS
                    assign prefix[level+1][bit_index]=
                        prefix[level][bit_index];
                end
            end
        end

        for(bit_index=1;bit_index<WIDTH;
            bit_index=bit_index+1)begin:GEN_RESULT
            assign result[bit_index]=
                data[bit_index]^prefix[LEVELS][bit_index-1];
        end
    endgenerate

    assign result[0]=~data[0];

endmodule

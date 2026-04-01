module ysyx_RegFile #(REG_LENGTH=32,REG_INDEX_LENGTH=5,DATA_LENGTH=32)(clk,rst,wen,rd,rs1,rs2,wdata,rdata1,rdata2);
    input clk,rst,wen;
    input[REG_INDEX_LENGTH-1:0] rd,rs1,rs2;
    input[DATA_LENGTH-1:0] wdata;
    output[DATA_LENGTH-1:0]rdata1,rdata2;
    reg[DATA_LENGTH-1:0] mem[REG_LENGTH-1:0];
    assign rdata1=(rs1=={REG_INDEX_LENGTH{1'b0}})?{DATA_LENGTH{1'b0}}:mem[rs1];
    assign rdata2=(rs2=={REG_INDEX_LENGTH{1'b0}})?{DATA_LENGTH{1'b0}}:mem[rs2];
    integer i;
    always@(posedge clk)begin
        if(rst)begin
            for(i=0;i<REG_LENGTH;i=i+1)begin
                mem[i]<={DATA_LENGTH{1'b0}};
            end
        end
        else if(wen&&rd!=0)
            mem[rd]<=wdata;
    end
endmodule



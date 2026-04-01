module ysyx_RegFile_sCPU #(REG_LENGTH=32,REG_INDEX_LENGTH=5,DATA_LENGTH=32)(clk,rst,wen,rd,rs1,rs2,r0,wdata,rdata1,rdata2,rdata0);
    input clk,rst,wen;
    input[REG_INDEX_LENGTH-1:0] rd,rs1,rs2,r0;
    input[DATA_LENGTH-1:0] wdata;
    output[DATA_LENGTH-1:0]rdata1,rdata2,rdata0;
    reg[DATA_LENGTH-1:0] mem[REG_LENGTH-1:0];
    assign rdata1=mem[rs1];
    assign rdata2=mem[rs2];
    assign rdata0=mem[r0];
    integer i;
    always@(posedge clk)begin
        if(rst)begin
            for(i=0;i<REG_LENGTH;i=i+1)begin
                mem[i]<={DATA_LENGTH{1'b0}};
            end
        end
        else if(wen)
            mem[rd]<=wdata;
    end
endmodule


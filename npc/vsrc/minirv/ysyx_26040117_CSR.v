module ysyx_26040117_CSR(clk,rst,
    wen,trap_ctrl,funct3,csr_addr,src1,pc,
    rdata
);
    input clk,rst;
    input wen;
    input [2:0] trap_ctrl,funct3;//0:csrr,1:ecall,2:mret
    input [11:0]csr_addr;
    input [31:0]src1,pc;
    output reg[31:0]rdata;

    reg[63:0]mcycle;
    reg[31:0]wdata,mepc,mstatus,mcause,mtvec;
    always @(*)begin
        if(trap_ctrl[1])begin
            rdata=mtvec;
        end else if(trap_ctrl[2])begin
            rdata=mepc;
        end else begin
            case(csr_addr)
                12'hb00:rdata=mcycle[31:0];
                12'hb80:rdata=mcycle[63:32];
                12'h341:rdata=mepc;
                12'h300:rdata=mstatus;
                12'h342:rdata=mcause;
                12'h305:rdata=mtvec;
                12'hf11:rdata=32'h79737978;
                12'hf12:rdata=32'h18d5735;
                default:rdata=32'h0;
            endcase
        end
    end
    always @(*)begin
        case(funct3)
            3'b001:wdata=src1;
            3'b010:wdata=src1|rdata;
            default:wdata=0;
        endcase
    end
    always @(posedge clk) begin
        if(rst)begin
            mcycle<=64'h0;
            mepc<=32'h80000000;
            mstatus<=32'h1800;
            mcause<=32'h0;
            mtvec<=32'h0;
        end else begin
            mcycle<=mcycle+64'h1;
            if(wen)begin
                if(trap_ctrl[1])begin
                    mepc<=pc;
                    mcause<=32'd11;
                end else if(trap_ctrl[0])begin
                    case(csr_addr)
                        12'hb00:mcycle[31:0]<=wdata;
                        12'hb80:mcycle[63:32]<=wdata;
                        12'h341:mepc<=wdata;
                        12'h300:mstatus<=wdata;
                        12'h342:mcause<=wdata;
                        12'h305:mtvec<=wdata;
                        default:;
                    endcase
                end
            end
        end
    end
endmodule

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
    reg[31:0]mcycle_lo,mcycle_hi;
    reg[31:0]wdata,mepc,mstatus,mcause,mtvec;
    always @(*)begin
        if(trap_ctrl[1])begin
            rdata=mtvec;
        end else if(trap_ctrl[2])begin
            rdata=mepc;
        end else begin
            case(csr_addr)
                12'hb00:rdata=mcycle_lo;
                12'hb80:rdata=mcycle_hi;
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
    wire [31:0] lo_inc=mcycle_lo+32'd1;
    wire [31:0] hi_inc=mcycle_hi+32'd1;
    wire lo_wrap=&mcycle_lo;
    always @(posedge clk) begin
        if(rst)begin
            mstatus<=32'h1800;
            mcause<=32'h0;
        end else begin
            mcycle_lo<=lo_inc;
            if(lo_wrap)
                mcycle_hi<=hi_inc;
            if(wen)begin
                if(trap_ctrl[1])begin
                    mepc<=pc;
                    mcause<=32'd11;
                end else if(trap_ctrl[0])begin
                    case(csr_addr)
                        12'hb00:mcycle_lo<=wdata;
                        12'hb80:mcycle_hi<=wdata;
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

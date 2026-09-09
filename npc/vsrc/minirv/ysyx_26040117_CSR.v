module ysyx_26040117_CSR(clk,rst,
    wen,trap_info,funct3,csr_addr,result,
    rdata,trap_dnpc
);
    localparam CSR_MCYCLE_LO = 4'd0;
    localparam CSR_MCYCLE_HI = 4'd1;
    localparam CSR_MEPC      = 4'd2;
    localparam CSR_MSTATUS   = 4'd3;
    localparam CSR_MCAUSE    = 4'd4;
    localparam CSR_MTVEC     = 4'd5;
    localparam CSR_MVENDORID = 4'd6;
    localparam CSR_MARCHID   = 4'd7;
    input clk,rst;
    input wen;
    input [2:0]funct3;//0:csrr,1:ecall,2:mret
    input [6:0] trap_info;
    input [3:0]csr_addr;
    input [31:0]result;
    output reg[31:0]rdata;
    output [31:0] trap_dnpc;
    reg[31:0]mcycle_lo,mcycle_hi;
    reg[31:0]wdata,mepc,mstatus,mcause,mtvec;
    //read
    assign trap_dnpc=trap_info[2]?{mtvec[31:2],2'd0}:mepc;
    always @(*)begin
        case(csr_addr)
            CSR_MCYCLE_LO:rdata=mcycle_lo;
            CSR_MCYCLE_HI:rdata=mcycle_hi;
            CSR_MEPC:     rdata=mepc;
            CSR_MSTATUS:  rdata=mstatus;
            CSR_MCAUSE:   rdata=mcause;
            CSR_MTVEC:    rdata=mtvec;
            CSR_MVENDORID:rdata=32'h79737978;
            CSR_MARCHID:  rdata=32'h18d5735;
            default:rdata=32'h0;
        endcase
    end
    always @(*)begin
        case(funct3)//src1
            3'b001:wdata=result;
            3'b010:wdata=result|rdata;
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
            mcycle_lo<=32'h0;
            mcycle_hi<=32'h0;
        end else begin
            mcycle_lo<=lo_inc;
            if(lo_wrap)
                mcycle_hi<=hi_inc;
            if(wen)begin
                if(trap_info[2])begin//trap entry
                    mstatus[7]<=mstatus[3];//mpie=mie
                    mstatus[3]<=1'b0;
                    mstatus[12:11]<=2'b11;//MPP=3 from M mode
                    mepc<={result[31:2],2'd0};//pc
                    mcause<={28'd0,trap_info[6:3]};
                end if(trap_info[1])begin//trap return meret
                    mstatus[3]<=mstatus[7];
                    mstatus[7]<=1'b1;
                    mstatus[12:11]<=2'b11;
                end else if(trap_info[0])begin
                    case(csr_addr)
                        CSR_MCYCLE_LO:mcycle_lo<=wdata;
                        CSR_MCYCLE_HI:mcycle_hi<=wdata;
                        CSR_MEPC:     mepc<={wdata[31:2],2'd0};
                        CSR_MSTATUS:  mstatus<=wdata;
                        CSR_MCAUSE:   mcause<=wdata;
                        CSR_MTVEC:    mtvec<=wdata;
                        default:;
                    endcase
                end
            end
        end
    end
endmodule

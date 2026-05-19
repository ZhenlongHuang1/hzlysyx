module ysyx_26040117_WBU(clk,rst,br_token,ebreak,imm,src1,result,ramdata,csr_rdata,mytype,trap_ctrl,srcd,pc);
    input clk,rst,br_token,ebreak;
    input [2:0]trap_ctrl;//0:csrr,1:ecall,2:mret,
    input[8:0]mytype;
    input[31:0] imm,result,ramdata,src1,csr_rdata;
    output[31:0] srcd;
    output reg[31:0] pc;
    wire[31:0]pc_next,snpc,dnpc,dnpc_unprivil;
    wire notjump,privil;
    assign privil=|trap_ctrl[2:1];
    assign snpc=pc+32'd4;
    assign dnpc_unprivil= imm+(mytype[3]?src1:pc);//JALR:other
    assign dnpc=privil?csr_rdata:dnpc_unprivil;
    assign srcd=({32{mytype[5]}}&ramdata)|
                ({32{(|mytype[8:7])}}&result)|
                ({32{|mytype[3:2]}}&snpc)|
                ({32{mytype[0]}}&imm)|
                ({32{mytype[1]}}&dnpc)|
                ({32{trap_ctrl[0]}}&csr_rdata);
    assign notjump=~((mytype[3])||(mytype[2]||privil)||(mytype[4]&&br_token));
    assign pc_next=({32{notjump}}&snpc)|
                    ({32{mytype[2]||privil||(mytype[4]&&br_token)}}&dnpc)|//JAL||跳转
                    ({{31{mytype[3]}},1'b0}&dnpc);//JALR
    always@(posedge clk)begin
        if(rst)
            pc<=32'h80000000;
        else begin
            pc<=pc_next;
        end
    end
    import "DPI-C" function void npc_trap();
    always@(posedge clk)begin
        if(ebreak&&!rst)begin
            npc_trap();
        end
    end
endmodule

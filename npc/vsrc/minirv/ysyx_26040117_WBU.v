module ysyx_26040117_WBU(clk,rst,br_token,ebreak,imm,snpc,src1,result,ramdata,csr_rdata,mytype,trap_ctrl,srcd,dnpc,pc,jump);
    input clk,rst,br_token,ebreak;
    input [2:0]trap_ctrl;//0:csrr,1:ecall,2:mret,
    input[8:0]mytype;
    input[31:0] imm,pc,snpc,result,ramdata,src1,csr_rdata;
    output[31:0] srcd,dnpc;
    output jump;
    wire[31:0]dnpc_unprivil;
    wire privil;
    assign privil=|trap_ctrl[2:1];
    assign dnpc_unprivil= imm+(mytype[3]?src1:pc);//JALR:other
    assign dnpc=privil?csr_rdata:dnpc_unprivil;
    assign srcd=({32{mytype[5]}}&ramdata)|
                ({32{(|mytype[8:7])}}&result)|
                ({32{|mytype[3:2]}}&snpc)|
                ({32{mytype[0]}}&imm)|
                ({32{mytype[1]}}&dnpc)|
                ({32{trap_ctrl[0]}}&csr_rdata);
    assign jump=((mytype[3])||(mytype[2]||privil)||(mytype[4]&&br_token));
    import "DPI-C" function void npc_trap();
    always@(posedge clk)begin
        if(ebreak&&!rst)begin
            npc_trap();
        end
    end
endmodule

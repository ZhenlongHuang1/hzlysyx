module ysyx_26040117_WBU(clk,rst,br_token,ebreak,imm,snpc,dnpc,result,ramdata,mytype,srcd,pc);
    input clk,rst,br_token,ebreak;
    input[8:0]mytype;
    input[31:0] imm,dnpc,snpc,result,ramdata;
    output[31:0] srcd;
    output reg[31:0] pc;
    wire[31:0]pc_next;
    wire notjump;
    assign srcd=({32{mytype[5]}}&ramdata)|
                ({32{(|mytype[8:7])}}&result)|
                ({32{|mytype[3:2]}}&snpc)|
                ({32{mytype[0]}}&imm)|
                ({32{mytype[1]}}&dnpc);
    assign notjump=~((|mytype[3:2])||(mytype[4]&&br_token));
    assign pc_next=({32{notjump}}&snpc)|
                    ({32{mytype[2]||(mytype[4]&&br_token)}}&dnpc)|//JAL||跳转
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

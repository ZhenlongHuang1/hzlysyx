module ysyx_26040117_EXU(clk,rst,
    IDU_EXU_ready,IDU_EXU_valid,IDU_wrapper,
    EXU_LSU_ready,EXU_LSU_valid,aux,EXU_wrapper,
    redirect_valid,EXU_IDU_wrapper
);
    input clk,rst;
    //IDU-EXU
    input IDU_EXU_valid;
    output IDU_EXU_ready;
    input [155:0]IDU_wrapper;
    //EXU-LSU
    input EXU_LSU_ready;
    output EXU_LSU_valid;
    output [31:0] aux/* verilator public_flat_rd */;
    output [57:0] EXU_wrapper;

    assign EXU_wrapper={register_wen,type_fence_i,trap_info,rd,result,mytype,funct[2:0]};
    //EXU-IFU/IDU
    output redirect_valid/* verilator public_flat_rd */;
    output[5:0] EXU_IDU_wrapper;
    assign EXU_IDU_wrapper={EXU_LSU_valid&&register_wen,rd};
    //state machine
    wire IDU_EXU_fire,EXU_LSU_fire/* verilator public_flat_rd */;
    reg state;
    localparam IDLE=0,WAIT=1;
    always @(posedge clk) begin
        if(rst||redirect_valid)
            state<=IDLE;
        else if(IDU_EXU_fire)
            state<=WAIT;
        else if(EXU_LSU_fire)
            state<=IDLE;
    end
    assign IDU_EXU_ready=(state==IDLE)||EXU_LSU_fire;
    assign EXU_LSU_valid=state==WAIT;
    assign IDU_EXU_fire=IDU_EXU_ready&&IDU_EXU_valid;
    assign EXU_LSU_fire=EXU_LSU_ready&&EXU_LSU_valid;
    //FIFO
    reg[155:0] IDU_wrapper_reg;
    wire [8:0]mytype;
    wire [3:0]funct;
    wire [31:0] num1,num2,aux_num1,aux_num2;
    wire sub,type_fence_i,register_wen;
    wire[6:0] trap_info;
    wire [4:0] rd;
    always @(posedge clk) begin
        if(IDU_EXU_fire)begin
            IDU_wrapper_reg<=IDU_wrapper;
        end
    end
    assign {register_wen,type_fence_i,trap_info,rd,funct,mytype,num1,num2,aux_num1,aux_num2,sub}=IDU_wrapper_reg;
    //result function
    wire carry,sless,less;
    wire[31:0] t_no_cin,result0;
    assign t_no_cin={32{sub}}^num2;
    assign {carry,result0}=num1+t_no_cin+sub;//adder
    assign sless=(num1[31]^num2[31])?num1[31]:result0[31];
    assign less=~carry;
    
    wire signed [32:0] shift_src={funct[3]&num1[31],num1};
    wire [32:0] shift_tmp=$signed(shift_src)>>>num2[4:0];
    reg [31:0]result;
    always @(*) begin
        result=result0;//load,store,jal,jalr
        if(mytype[8]||mytype[7])begin
            case(funct[2:0])
                3'b000:result=result0;//ADDI,ADD
                3'b010:result={31'd0,sless};//SLTI,SLT
                3'b011:result={31'd0,less};//SLTIU,SLTU
                3'b100:result=num1^num2;//XORI,XOR
                3'b110:result=num1|num2;//ORI,OR
                3'b111:result=num1&num2;//ANDI,AND
                3'b001:result=num1<<(num2[4:0]);//SLLI,SLL
                3'b101:result=shift_tmp[31:0];//1:SRAI,SRA;0:SRLI,SRL
                default:result=32'd0;
            endcase
        end
    end
    //branch function
    wire cmp_eq=num1==num2;
    wire cmp_lts=$signed(num1)<$signed(num2);
    wire cmp_ltu=num1<num2;
    reg branch_decision0;
    wire branch_decision;
    always@(*)begin
        branch_decision0=1'b0;
        case(funct[2:1])
            2'b00:branch_decision0=cmp_eq;//BEQ,BNE
            2'b10:branch_decision0=cmp_lts;//BLT,BGE
            2'b11:branch_decision0=cmp_ltu;//BLTU,BGEU
            default:branch_decision0=1'd0;
        endcase
    end
    assign branch_decision=funct[0]^branch_decision0;
    //aux
    wire[31:0] aux0;
    assign aux0=aux_num1+aux_num2;
    assign aux={aux0[31:1],aux0[0]&&~mytype[3]};
    assign redirect_valid=(|mytype[3:2]||(mytype[4]&&branch_decision))&&EXU_LSU_fire;
`ifdef PERF_COUNTER
    reg [63:0] exu_occupied_cycles;
    reg [63:0] exu_out_count;

    always @(posedge clk)begin
        if(rst)begin
            exu_occupied_cycles<=64'd0;
            exu_out_count<=64'd0;
        end else begin
            if(EXU_LSU_valid)
                exu_occupied_cycles<=exu_occupied_cycles+64'd1;
            if(EXU_LSU_fire)
                exu_out_count<=exu_out_count+64'd1;
        end
    end
`endif
endmodule

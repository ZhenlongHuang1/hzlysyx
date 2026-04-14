module ysyx_26040117_ascii_rom(a,z);
    input[7:0] a;
    output reg[7:0] z;
    always@(*)
        case(a)
            8'h1c:z=8'h61;
            8'h32:z=8'h62;
            8'h21:z=8'h63;
            8'h23:z=8'h64;
            8'h24:z=8'h65;
            8'h2b:z=8'h66;
            8'h34:z=8'h67;
            8'h33:z=8'h68;
            8'h43:z=8'h69;
            8'h3b:z=8'h6a;
            8'h42:z=8'h6b;
            8'h4b:z=8'h6c;
            8'h3a:z=8'h6d;
            8'h31:z=8'h6e;
            8'h44:z=8'h6f;
            8'h4d:z=8'h70;
            8'h15:z=8'h71;
            8'h2d:z=8'h72;
            8'h1b:z=8'h73;
            8'h2c:z=8'h74;
            8'h3c:z=8'h75;
            8'h2a:z=8'h76;
            8'h1d:z=8'h77;
            8'h22:z=8'h78;
            8'h35:z=8'h79;
            8'h1a:z=8'h7a;

            8'h45:z=8'h30;
            8'h16:z=8'h31;
            8'h1e:z=8'h32;
            8'h26:z=8'h33;
            8'h25:z=8'h34;
            8'h2e:z=8'h35;
            8'h36:z=8'h36;
            8'h3d:z=8'h37;
            8'h3e:z=8'h38;
            8'h46:z=8'h39;
            default:z=8'h0;
        endcase
endmodule

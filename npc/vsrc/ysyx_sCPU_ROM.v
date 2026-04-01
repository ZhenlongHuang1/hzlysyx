module ysyx_sCPU_ROM #(ADDR_LENGTH=12)(a,z);
    input[ADDR_LENGTH-1:0] a;
    output[7:0] z;
    (*synthesis, rom_block*) reg[7:0] rom[(1<<(ADDR_LENGTH))-1:0];
//    initial $readmemb("resource/rom.data",rom);
    initial begin
        rom[0]=8'b10010000;
        rom[1]=8'b10100000;
        rom[2]=8'b10110001;
        rom[3]=8'b00010111;
        rom[4]=8'b00101001;
        rom[5]=8'b11001101;
        rom[6]=8'b01000010;
        rom[7]=8'b11011111;
    end
    assign z=rom[a[ADDR_LENGTH-1:0]];
endmodule

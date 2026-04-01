module ysyx_sCPU_ROM #(ADDR_LENGTH=12)(a,z);
    input[ADDR_LENGTH-1:0] a;
    output[7:0] z;
    (*synthesis, rom_block*) reg[7:0] rom[(1<<(ADDR_LENGTH))-1:0];
//    initial $readmemb("resource/rom.data",rom);
//    10001010,0b10010000,0b10100000,0b10110001,0b00010111,0b00101001,0b11010001,0b11011111
    initial begin
        rom[0]=8'b10001010;
        rom[1]=8'b10010000;
        rom[2]=8'b10100000;
        rom[3]=8'b10110001;
        rom[4]=8'b00010111;
        rom[5]=8'b00101001;
        rom[6]=8'b11010001;
        rom[7]=8'b01000010;
        rom[8]=8'b11100011;
    end
    assign z=rom[a[ADDR_LENGTH-1:0]];
endmodule

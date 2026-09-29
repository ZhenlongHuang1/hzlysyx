`timescale 1ns/1ps
module ysyx_26040117_iverilog_tb;
    reg clock=0;
    reg reset=1;

    always #5 clock=~clock;

    initial begin
        repeat(10) @(negedge clock);
        reset=0;
    end

    ysyx_26040117_iverilog dut(
        .clock(clock),
        .reset(reset)
    );
    localparam integer PRINT_INTERVAL = 100000;
    localparam integer MAX_CYCLES     = 3000000;
    integer cycles = 0;
    always @(posedge clock) begin
        if (reset) begin
            cycles <= 0;
        end else begin
            cycles <= cycles + 1;

            if ((cycles + 1) % PRINT_INTERVAL == 0) begin
                $display(
                    "cycle=%0d AR=%b/%b addr=%08h R=%b/%b AW=%b/%b W=%b/%b B=%b/%b",
                    cycles + 1,
                    dut.io_master_arvalid, dut.io_master_arready,
                    dut.io_master_araddr,
                    dut.io_master_rvalid, dut.io_master_rready,
                    dut.io_master_awvalid, dut.io_master_awready,
                    dut.io_master_wvalid, dut.io_master_wready,
                    dut.io_master_bvalid, dut.io_master_bready
                );
                $fflush();
            end

            if (cycles + 1 >= MAX_CYCLES)
                $fatal(1, "Icarus timeout after %0d cycles", MAX_CYCLES);
        end
    end
endmodule

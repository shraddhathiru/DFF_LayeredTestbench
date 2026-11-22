`timescale 1ns/1ps

module tb;
    import dff_tb_pkg::*;

    localparam int unsigned NUM_ITEMS = 20;

    logic clk = 1'b0;
    always #5 clk = ~clk;

    dff_if bus(clk);
    dff dut(.clk(clk), .d(bus.d), .q(bus.q));

    mailbox #(dff_item) gen2drv = new();
    mailbox #(dff_observation) mon2scb = new();

    dff_generator  gen;
    dff_driver     drv;
    dff_monitor    mon;
    dff_scoreboard scb;

    initial begin
        gen = new(gen2drv);
        drv = new(bus, gen2drv);
        mon = new(bus, mon2scb);
        scb = new(mon2scb);

        fork
            gen.run(NUM_ITEMS);
            drv.run(NUM_ITEMS);
            mon.run(NUM_ITEMS + 1);
            scb.run(NUM_ITEMS + 1);
        join

        $display("Test completed.");
        $finish;
    end
endmodule

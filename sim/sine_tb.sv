`timescale 1ns / 1ps
`default_nettype none

module sine_tb();

  logic clk_in;
  logic rst_in;
  logic [23:0] audio;

  sine uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .phase_incr_in(24'h1001_0110_0011_0000),
    .val_out(audio)
  );

  always begin
    #2600; // ~192 kHz
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("sine_tb.vcd");
    $dumpvars(0, sine_tb);
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    #5200;
    rst_in = 1;
    #5200;
    rst_in = 0;

    #5000000;

    $display("Finishing");
    $finish;
  end

endmodule

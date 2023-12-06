`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module sine_tb();

  logic clk_in;
  logic rst_in;
  logic [23:0] audio;

  sine uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .phase_incr_in(24'd5),
    .val_out(audio)
  );

  always begin
    #10; // ~192 kHz
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("sine_tb.vcd");
    $dumpvars(0, sine_tb);
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;

    #50000000;

    $display("Finishing");
    $finish;
  end

endmodule

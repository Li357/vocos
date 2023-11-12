`timescale 1ns / 1ps
`default_nettype none

module synthesizer_tb();

  logic clk_in;
  logic rst_in;
  logic [10:0] audio;

  synthesizer uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .phase_incr_in(32'b0100101100011000),
    .audio_out(audio)
  );

  always begin
    #10;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("synthesizer_tb.vcd");
    $dumpvars(0, synthesizer_tb);
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;

    #5000000;

    $display("Finishing");
    $finish;
  end

endmodule

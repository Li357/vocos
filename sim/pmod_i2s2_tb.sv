`timescale 1ns / 1ps
`default_nettype none

module pmod_i2s2_tb();

  logic clk_in;
  logic rst_in;
  logic [23:0] sample_in;

  pmod_i2s2 uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sample_in(sample_in)
  );

  always begin
    #10;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("pmod_i2s2_tb.vcd");
    $dumpvars(0, pmod_i2s2_tb);
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;
    #20;

    for (int i = 0; i < 32; i++) begin
      sample_in = i;
      #15360; // new sample every 192 cycles of mclk
    end

    #4000;

    $display("Finishing");
    $finish;
  end

endmodule

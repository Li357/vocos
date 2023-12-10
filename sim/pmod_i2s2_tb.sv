`timescale 1ns / 1ps
`default_nettype none

module pmod_i2s2_tb();

  logic clk_in;
  logic rst_in;
  logic lin_sdout_in;
  logic [23:0] data_in = 24'b111100001010101000010001;

  pmod_i2s2 uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .lin_sdout_in(lin_sdout_in),
    .valid_in(1'b1)
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
    #10;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;
    #7780;

    for (int i = 0; i < 64; i++) begin
      lin_sdout_in = data_in[i % 32];
      #240; // new sample every 12 cycles of mclk
    end

    #4000;

    $display("Finishing");
    $finish;
  end

endmodule

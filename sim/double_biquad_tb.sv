`timescale 1ns / 1ps
`default_nettype none

module double_biquad_tb();

  logic clk_in;
  logic rst_in;
  logic [23:0] sample;
  logic [63:0] b1_out;
  logic [23:0] b2_out;

  double_biquad uut(
    .coeffs({
      32'd75467, 32'd0, -32'd75467, -32'd1237071, 32'd937178,
      32'd75467, 32'd0, -32'd75467, -32'd1403483, 32'd946853
    }),
    .x_n(3 << 20),
    .x_n1(2 << 20),
    .x_n2(1 << 20),
  );

  initial begin
    $dumpfile("biquad_tb.vcd");
    $dumpvars(0, biquad_tb);
    $display("Starting");

    #20;
    
    #20;

    $display("Finishing");
    $finish;
  end

endmodule

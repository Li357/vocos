`timescale 1ns / 1ps
`default_nettype none

module biquad_tb();

  logic clk_in;
  logic rst_in;
  logic [23:0] sample;
  logic [63:0] b1_out;
  logic [23:0] b2_out;

  biquad #(
    .b0(32'd75467), 
    .b1(32'd0), 
    .b2(-32'd75467),
    .a1(-32'd1237071), 
    .a2(32'd937178)
  ) uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sample_in(sample),
    .sample_out(b1_out)
  );

  biquad #(
    .b0(32'd75467), 
    .b1(32'd0), 
    .b2(-32'd75467),
    .a1(-32'd1403483), 
    .a2(32'd946853)
  ) uut2(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sample_in(b1_out),
    .sample_out(b2_out)
  );

  always begin
    #10;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("biquad_tb.vcd");
    $dumpvars(0, biquad_tb);
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;
    sample = 32'h00020000;
    #20;
    sample = 32'h00030000;
    #20;
    sample = 32'h00038000;
    #20;
    sample = 32'h0003C000;
    #20;
    sample = 32'h0003E000;
    #400;

    $display("Finishing");
    $finish;
  end

endmodule

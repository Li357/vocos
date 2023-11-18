`timescale 1ns / 1ps
`default_nettype none

module double_biquad #(
  parameter WIDTH = 24,
  parameter SHIFT = 20,

  // [b0, b1, b2, a1, a2] where a0 = 1
  parameter signed [31:0] coeffs1 [4:0],
  parameter signed [31:0] coeffs2 [4:0]
)
(
  input wire clk_in,
  input wire rst_in,
  input wire signed [WIDTH-1:0] sample_in,
  output logic signed [WIDTH-1:0] sample_out
);

  logic signed [63:0] b1_out;
  biquad #(
    .WIDTH(WIDTH), .DEPTH(DEPTH),
    .b0(coeffs1[0]), .b1(coeffs1[1]), .b2(coeffs1[2]),
    .a1(coeffs1[3]), .a2(coeffs1[4])
  ) b1(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sample_in(sample_in),
    .sample_out(b1_out)
  );

  biquad #(
    .WIDTH(WIDTH), .DEPTH(DEPTH),
    .b0(coeffs2[0]), .b1(coeffs2[1]), .b2(coeffs2[2]),
    .a1(coeffs2[3]), .a2(coeffs2[4])
  ) b2(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sample_in(b1_out),
    .sample_out(sample_out)
  );

endmodule

`default_nettype wire
`timescale 1ns / 1ps
`default_nettype none

module double_biquad #(
  parameter SHIFT = 20,

  // [b0, b1, b2, a1, a2] where a0 = 1
  parameter signed [31:0] coeffs1 [4:0],
  parameter signed [31:0] coeffs2 [4:0]
)
(
  input wire clk_in,
  input wire rst_in,
  input wire valid_in,
  input wire signed [31:0] sample_in,
  output logic signed [31:0] sample_out,
  output logic valid_out
);

  logic signed [31:0] b1_out;
  logic b1_valid_out;
  biquad #(
    .SHIFT(SHIFT),
    .b0(coeffs1[0]), .b1(coeffs1[1]), .b2(coeffs1[2]),
    .a1(coeffs1[3]), .a2(coeffs1[4])
  ) b1(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .valid_in(valid_in),
    .sample_in(sample_in),
    .sample_out(b1_out),
    .valid_out(b1_valid_out)
  );

  biquad #(
    .SHIFT(SHIFT),
    .b0(coeffs2[0]), .b1(coeffs2[1]), .b2(coeffs2[2]),
    .a1(coeffs2[3]), .a2(coeffs2[4])
  ) b2(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .valid_in(b1_valid_out),
    .sample_in(b1_out),
    .sample_out(sample_out),
    .valid_out(valid_out)
  );

endmodule

`default_nettype wire
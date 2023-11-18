`timescale 1ns / 1ps
`default_nettype none

module biquad #(
  parameter SHIFT = 20,
  parameter signed [31:0] a1,
  parameter signed [31:0] a2,
  parameter signed [31:0] b0,
  parameter signed [31:0] b1,
  parameter signed [31:0] b2
)
(
  input wire clk_in,
  input wire rst_in,
  input wire valid_in,
  input wire signed [31:0] sample_in,
  output logic signed [31:0] sample_out,
  output logic valid_out
);

  // Direct Form I
  // y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]

  logic signed [31:0] x_n;
  logic signed [31:0] x_n1;
  logic signed [31:0] x_n2;

  logic signed [31:0] y_n;
  logic signed [31:0] y_n1;
  logic signed [31:0] y_n2;

  logic signed [63:0] temp1, temp2, temp3, temp4, temp5;
  always_comb begin
    temp1 = (b0 * x_n) >>> SHIFT;
    temp2 = (b1 * x_n1) >>> SHIFT;
    temp3 = (b2 * x_n2) >>> SHIFT;
    temp4 = (a1 * y_n1) >>> SHIFT;
    temp5 = (a2 * y_n2) >>> SHIFT;
    y_n = temp1 + temp2 + temp3 - temp4 - temp5;
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      y_n1 <= 0;
      y_n2 <= 0;
      x_n <= 0;
      x_n1 <= 0;
      x_n2 <= 0;
    end else if (valid_in) begin
      x_n <= sample_in;

      x_n1 <= x_n;
      x_n2 <= x_n1;

      y_n1 <= y_n;
      y_n2 <= y_n1;
      valid_out <= 1;
    end else if (valid_out) valid_out <= 0;
  end

  assign sample_out = y_n;

endmodule

`default_nettype wire
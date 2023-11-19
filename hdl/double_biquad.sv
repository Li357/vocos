`timescale 1ns / 1ps
`default_nettype none

module double_biquad #(parameter SHIFT = 20)
(
  // [a1_0, a2_0, b0_0, b1_0, b2_0, a1_1, a2_1, b0_1, b1_1, b2_1]
  //input wire signed [31:0] coeffs [9:0],

  input wire signed [31:0] b0_0,
  input wire signed [31:0] b1_0,
  input wire signed [31:0] b2_0,
  input wire signed [31:0] a1_0,
  input wire signed [31:0] a2_0,

  input wire signed [31:0] b0_1,
  input wire signed [31:0] b1_1,
  input wire signed [31:0] b2_1,
  input wire signed [31:0] a1_1,
  input wire signed [31:0] a2_1,

  input wire signed [31:0] x_n,
  input wire signed [31:0] x_n1,
  input wire signed [31:0] x_n2,
  input wire signed [31:0] i_n1,
  input wire signed [31:0] i_n2,
  input wire signed [31:0] y_n1,
  input wire signed [31:0] y_n2,
  output logic signed [31:0] i_n,
  output logic signed [31:0] y_n
);

  // Direct Form I
  // i[n] = b0_0*x[n] + b1_0*x[n-1] + b2_0*x[n-2] - a1_0*i[n-1] - a2_0*i[n-2]
  // y[n] = b0_1*i[n] + b1_1*i[n-1] + b2_1*i[n-2] - a1_1*y[n-1] - a2_0*y[n-2]
  logic signed [63:0] temp1, temp2, temp3, temp4, temp5;
  logic signed [63:0] temp6, temp7, temp8, temp9, temp10;
  always_comb begin
    temp1 = (b0_0 * x_n)  >>> SHIFT;
    temp2 = (b1_0 * x_n1) >>> SHIFT;
    temp3 = (b2_0 * x_n2) >>> SHIFT;
    temp4 = (a1_0 * i_n1) >>> SHIFT;
    temp5 = (a2_0 * i_n2) >>> SHIFT;
    i_n = temp1 + temp2 + temp3 - temp4 - temp5;

    temp6  = (b0_1 * i_n)  >>> SHIFT;
    temp7  = (b1_1 * i_n1) >>> SHIFT;
    temp8  = (b2_1 * i_n2) >>> SHIFT;
    temp9  = (a1_1 * y_n1) >>> SHIFT;
    temp10 = (a2_1 * y_n2) >>> SHIFT;
    y_n = temp6 + temp7 + temp8 - temp9 - temp10;
  end

endmodule

`default_nettype wire
`timescale 1ns / 1ps
`default_nettype none

module envelope #(
  parameter WIDTH = 24,
  parameter SHIFT = 20
)
(
  input wire clk_in,
  input wire rst_in,
  input wire signed [WIDTH-1:0] sample_in,
  output logic signed [WIDTH-1:0] sample_out
);

  // 100 Hz cutoff
  localparam logic [31:0] COEFFS1 [4:0] = '{32'd45, 32'd89, 32'd45, -32'd2086521, 32'd1038123};
  localparam logic [31:0] COEFFS2 [4:0] = '{32'd44, 32'd89, 32'd44, -32'd2071916, 32'd1023518};

  logic signed [63:0] rectified;
  assign rectified = sample_in[63] ? -rectified : rectified;

  double_biquad #(
    .WIDTH(WIDTH), .DEPTH(DEPTH),
    .coeffs1(COEFFS1),
    .coeffs2(COEFFS2)
  ) b1(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sample_in(rectified),
    .sample_out(sample_out)
  );

endmodule

`default_nettype wire
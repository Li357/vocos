`timescale 1ns / 1ps
`default_nettype none

module triangle
  import constants::*;
(
  input wire clk_in,
  input wire rst_in,
  input wire [SYNTH_PHASE_ACC_BITS-1:0] phase_incr_in,
  output logic signed [SYNTH_WIDTH-1:0] val_out
);

  logic [SYNTH_PHASE_ACC_BITS-1:0] phase_acc;
  always_ff @(posedge clk_in) begin
    if (rst_in) phase_acc <= 0;
    else phase_acc <= phase_acc + phase_incr_in;
  end

  logic [SYNTH_WIDTH-2:0] tri_val_quarter;
  assign tri_val_quarter = phase_acc[SYNTH_WIDTH-2:0];
  logic [SYNTH_WIDTH-2:0] tri_val_half;
  assign tri_val_half = phase_acc[SYNTH_WIDTH-2] ? ~tri_val_quarter : tri_val_quarter;
  logic signed [SYNTH_WIDTH-1:0] tri_val;
  assign tri_val = phase_acc[SYNTH_WIDTH-1] ? -tri_val_half : tri_val_half;

  logic [SYNTH_WIDTH-1:0] tri_val_out;
  pipeline #(
    .DEPTH(2), // to match sine BRAM latency
    .WIDTH(SYNTH_WIDTH)
  ) val_pipe(
    .clk_in(clk_in),
    .data_in(tri_val),
    .data_out(tri_val_out)
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) val_out <= 0;
    else val_out <= tri_val_out;
  end

endmodule

`default_nettype wire
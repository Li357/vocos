`timescale 1ns / 1ps
`default_nettype none

module square
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

  logic [SYNTH_WIDTH-1:0] square_val;
  // to match sine RMS which is +-(2^23)/sqrt(2), we're scaling the square wave too
  assign square_val = phase_acc[SYNTH_PHASE_ACC_BITS-1] ? 24'h5A8279 : 24'hA57D86;

  logic [SYNTH_WIDTH-1:0] square_val_out;
  pipeline #(
    .DEPTH(2), // to match sine BRAM latency
    .WIDTH(SYNTH_WIDTH)
  ) val_pipe(
    .clk_in(clk_in),
    .data_in(square_val),
    .data_out(square_val_out)
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) val_out <= 0;
    else val_out <= square_val_out;
  end

endmodule

`default_nettype wire
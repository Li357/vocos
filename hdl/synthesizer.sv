`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module synthesizer
  import constants::*;
(
  input wire clk_in,
  input wire rst_in,
  input wire [SYNTH_PHASE_ACC_BITS-1:0] phase_incr_in,
  output logic signed [SYNTH_WIDTH-1:0] synth_out
);

  sine s(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .phase_incr_in(phase_incr_in),
    .val_out(synth_out)
  );

endmodule

`default_nettype wire
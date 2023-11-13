`timescale 1ns / 1ps
`default_nettype none

module pmod_i2s2
  import constants::*;
(
  input wire clk_in,
  input wire [SYNTH_WIDTH-1:0] sample_in,
  output logic mclk_out,
  output logic lrck_out,
  output logic sclk_out,
  output logic sdin_out
);

  localparam MCLK_CYCLES = 256;

  logic [$clog2(MCLK_CYCLES)-1:0] mclk_count;
  assign mclk_out = mclk_count[$clog2(MCLK_CYCLES)-1] == 0;
  always_ff @(posedge clk_in) begin
    mclk_count <= mclk_count + 1;
  end

endmodule

`default_nettype wire
`timescale 1ns / 1ps
`default_nettype none

module pmod_i2s2
  import constants::*;
(
  input wire clk_in,
  input wire rst_in,
  input wire [SYNTH_WIDTH-1:0] sample_in,
  output logic mclk_out,
  output logic lrck_out,
  output logic sclk_out,
  output logic sdin_out
);

  // run mclk at ~36.864MHz
  assign mclk_out = clk_in;

  // run sclk at mclk / 16 = 24-bit * 2 channels * 48kHz
  localparam SCLK_CYCLES = 16;
  localparam LRCK_CYCLES = 16 * 48;

  logic [$clog2(SCLK_CYCLES)-1:0] sclk_count;
  assign sclk_out = sclk_count[$clog2(SCLK_CYCLES)-1] == 0;
  always_ff @(posedge clk_in) begin
    if (rst_in) sclk_count <= 0;
    else sclk_count <= sclk_count + 1;
  end

  logic [$clog2(SYNTH_WIDTH)-1:0] prev_sample_index;
  logic [$clog2(SYNTH_WIDTH)-1:0] sample_index;

  logic [$clog2(LRCK_CYCLES)-1:0] lrck_count;
  assign lrck_out = lrck_count >= 384;
  always_ff @(posedge sclk_out) begin
    if (rst_in) begin
      lrck_count <= 0;
      sample_index <= 0;
      prev_sample_index <= 0;
    end else begin
      lrck_count <= lrck_count + 1;
      sample_index <= sample_index == 23 ? 0 : sample_index + 1;
      prev_sample_index <= sample_index;
    end
  end

  always_ff @(negedge sclk_out) begin
    sdin_out <= sample_in[prev_sample_index];
  end

endmodule

`default_nettype wire
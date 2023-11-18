`timescale 1ns / 1ps
`default_nettype none

module pmod_mic
  import constants::*;
(
  input wire clk_in,
  input wire rst_in,
  input wire data_in,
  output logic signed [SYNTH_WIDTH-1:0] sample_out,
  output logic valid_out,
  output logic bclk_out,
  output logic ws_out
);

  // run bclk at 98.3MHz / 32 = 3.072MHz
  localparam BCLK_CYCLES = 32;
  logic [$clog2(BCLK_CYCLES)-1:0] bclk_count;
  assign bclk_out = bclk_count[$clog2(BCLK_CYCLES)-1] == 0;
  always_ff @(posedge clk_in) begin
    if (rst_in) bclk_count <= 0;
    else bclk_count <= bclk_count + 1;
  end

  // WS = bclk / 64 = 48kHz
  localparam WS_CYCLES = 64;
  logic [$clog2(WS_CYCLES)-1:0] ws_count;
  assign ws_out = ws_count[$clog2(WS_CYCLES)-1] == 1;

  // WS is toggled on negedge of bclk and data is clocked out
  // on the next positive edge
  always_ff @(negedge bclk_out or posedge rst_in) begin
    if (rst_in) ws_count <= 63;
    else ws_count <= ws_count + 1;
  end

  localparam MIC_WIDTH = 24;
  logic [SYNTH_WIDTH-1:0] sample;
  always_ff @(posedge bclk_out) begin
    if (rst_in) begin
      sample <= 0;
      sample_out <= 0;
      valid_out <= 0;
    end else begin
      if (valid_out) valid_out <= 0;

      if (ws_count <= MIC_WIDTH - 1) begin
        sample[MIC_WIDTH - 1 - ws_count] <= data_in;
        if (ws_count == MIC_WIDTH - 1) begin
          valid_out <= 1;
          sample_out <= sample << 6; // extend up to 24 bits
        end
      end
    end
  end 

endmodule

`default_nettype wire
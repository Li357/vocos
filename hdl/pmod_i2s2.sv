`timescale 1ns / 1ps
`default_nettype none

module pmod_i2s2
  import constants::*;
(
  input wire clk_in,
  input wire rst_in,
  input wire valid_in,
  input wire lin_sdout_in,
  input wire [SYNTH_WIDTH-1:0] sample_in,
  output logic lout_mclk_out,
  output logic lout_lrck_out,
  output logic lout_sclk_out,
  output logic lout_sdin_out,

  output logic valid_out,
  output logic lin_mclk_out,
  output logic lin_lrck_out,
  output logic lin_sclk_out,
  output logic [SYNTH_WIDTH-1:0] sample_out
);

  typedef enum { WAITING, TXING } state_t;
  state_t state;

  // LINE OUT

  // run line out mclk at ~36.864MHz
  assign lout_mclk_out = clk_in;

  // run line out sclk at mclk / 16 = 24-bit * 2 channels * 48kHz
  localparam LOUT_SCLK_CYCLES = 16;
  logic [$clog2(LOUT_SCLK_CYCLES)-1:0] lout_sclk_count;
  assign lout_sclk_out = lout_sclk_count[$clog2(LOUT_SCLK_CYCLES)-1] == 0;
  always_ff @(posedge clk_in) begin
    if (rst_in) lout_sclk_count <= 0;
    else lout_sclk_count <= lout_sclk_count + 1;
  end

  logic [$clog2(SYNTH_WIDTH)-1:0] sample_index;

  localparam LOUT_LRCK_CYCLES = 48;
  logic [$clog2(LOUT_LRCK_CYCLES)-1:0] lout_lrck_count;
  assign lout_lrck_out = lout_lrck_count >= 24;
  always_ff @(posedge lout_sclk_out) begin
    if (rst_in) begin
      lout_lrck_count <= 0;
      sample_index <= 0;
      state <= WAITING;
    end else begin
      case (state)
        WAITING: begin
          if (valid_in) state <= TXING;
        end
        TXING: begin
          lout_lrck_count <= lout_lrck_count == 47 ? 0 : lout_lrck_count + 1;
          sample_index <= sample_index == 23 ? 0 : sample_index + 1;
        end
      endcase
    end
  end

  always_ff @(negedge lout_sclk_out) begin
    if (state == TXING) lout_sdin_out <= sample_in[SYNTH_WIDTH - 1 - sample_index];
  end

  // LINE IN

  logic [$clog2(SYNTH_WIDTH)-1:0] sample_out_index;

  // run line in mclk at 36.864MHz / 2 = 384 * 48kHz
  always_ff @(posedge clk_in) begin
    lin_mclk_out <= rst_in ? 0 : !lin_mclk_out;
  end

  // run sclk at 36.864MHz / 12 = 64 * 48kHz
  localparam LIN_SCLK_CYCLES = 12;
  logic [$clog2(LIN_SCLK_CYCLES)-1:0] lin_sclk_count;
  assign lin_sclk_out = lin_sclk_count < 6;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      lin_sclk_count <= 0;
      sample_out_index <= 0;
    end else lin_sclk_count <= lin_sclk_count < 11 ? lin_sclk_count + 1 : 0;
  end

  // run lrck at 48kHz
  localparam LIN_LRCK_CYCLES = 64;
  logic [$clog2(LIN_LRCK_CYCLES)-1:0] lin_lrck_count;
  assign lin_lrck_out = lin_lrck_count[$clog2(LIN_LRCK_CYCLES)-1] == 0;
  always_ff @(negedge lin_sclk_out) begin
    lin_lrck_count <= rst_in ? 0 : lin_lrck_count + 1;
    sample_out_index <= lin_lrck_count == 0 || lin_lrck_count == 32 ? 0 : sample_out_index + 1;
  end

  always_ff @(posedge lin_sclk_out) begin
    if (valid_out) valid_out <= 0;
    if (sample_out_index < SYNTH_WIDTH) begin
      sample_out[SYNTH_WIDTH - 1 - sample_out_index] <= lin_sdout_in;
      if (sample_out_index == SYNTH_WIDTH - 1) valid_out <= 1;
    end
  end

endmodule

`default_nettype wire
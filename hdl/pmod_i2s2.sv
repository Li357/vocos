`timescale 1ns / 1ps
`default_nettype none

module pmod_i2s2
  import constants::*;
(
  input wire clk_in,
  input wire rst_in,
  input wire valid_in,
  input wire lin_sdout_in,
  input wire signed [SYNTH_WIDTH-1:0] sample_in,
  output logic lout_mclk_out,
  output logic lout_lrck_out,
  output logic lout_sclk_out,
  output logic lout_sdin_out,

  output logic valid_out,
  output logic lin_mclk_out,
  output logic lin_lrck_out,
  output logic lin_sclk_out,
  output logic signed [SYNTH_WIDTH-1:0] sample_out
);

  typedef enum { WAITING, TXING } state_t;
  state_t state;

  // LINE OUT

  logic signed [SYNTH_WIDTH-1:0] sample_in_reg;

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
          if (valid_in) begin
            state <= TXING;
            sample_in_reg <= sample_in;
          end
        end
        TXING: begin
          lout_lrck_count <= lout_lrck_count == 47 ? 0 : lout_lrck_count + 1;
          sample_index <= sample_index == 23 ? 0 : sample_index + 1;
          if (lout_lrck_count == 47) sample_in_reg <= sample_in;
        end
      endcase
    end
  end

  always_ff @(negedge lout_sclk_out) begin
    if (state == TXING) lout_sdin_out <= sample_in_reg[SYNTH_WIDTH - 1 - sample_index];
  end

  // LINE IN

  logic [$clog2(SYNTH_WIDTH)-1:0] sample_out_index;
  assign lin_mclk_out = lout_mclk_out;
  assign lin_sclk_out = lout_sclk_out;

  logic signed [SYNTH_WIDTH-1:0] left_sample_out;
  logic signed [SYNTH_WIDTH-1:0] right_sample_out;

  logic [$clog2(LOUT_LRCK_CYCLES)-1:0] lin_lrck_count;
  assign lin_lrck_out = lin_lrck_count >= 24;
  always_ff @(negedge lin_sclk_out or posedge rst_in) begin
    if (rst_in) begin
      lin_lrck_count <= 0;
      sample_out_index <= 23;
    end else begin
      lin_lrck_count <= lin_lrck_count == 47 ? 0 : lin_lrck_count + 1;
      sample_out_index <= sample_out_index == 23 ? 0 : sample_out_index + 1;
    end
  end

  always_ff @(negedge lin_sclk_out) begin
    if (valid_out) valid_out <= 0;
    if (rst_in) begin
      sample_out <= 0;
      valid_out <= 0;
    end else begin
      // R is when lin_lrck_out is HIGH
      if (lin_lrck_out)
        right_sample_out[SYNTH_WIDTH - 1 - sample_out_index] <= lin_sdout_in;
      else
        left_sample_out[SYNTH_WIDTH - 1 - sample_out_index] <= lin_sdout_in;

      if (sample_out_index == SYNTH_WIDTH - 1 && lin_lrck_out) begin
        valid_out <= 1;
        sample_out <= left_sample_out;
      end
    end
  end

endmodule

`default_nettype wire
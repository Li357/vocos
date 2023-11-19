`timescale 1ns / 1ps
`default_nettype none

function [31:0] abs(input [31:0] x);
  abs = x[31] ? -x : x;
endfunction

module filterbank #(parameter N_FILTERS = 9)
(
  input wire clk_in,
  input wire rst_in,
  input wire valid_in,
  input wire signed [31:0] carrier_sample_in,
  input wire signed [31:0] modulator_sample_in,
  output logic signed [31:0] carrier_out  [N_FILTERS-1:0],
  output logic signed [31:0] envelope_out [N_FILTERS-1:0],
  output logic valid_out
);

  logic signed [31:0] COEFFS [N_FILTERS:0] [9:0];
  initial $readmemh(`FPATH(coeffs.mem), COEFFS);

  logic signed [31:0] modulator_past_samples       [1:0];
  logic signed [31:0] modulator_past_intermediates [N_FILTERS-1:0] [1:0];
  logic signed [31:0] modulator_past_outputs       [N_FILTERS-1:0] [1:0];

  logic signed [31:0] envelope_past_intermediates  [N_FILTERS-1:0] [1:0];
  logic signed [31:0] envelope_past_outputs        [N_FILTERS-1:0] [1:0];

  // needs to hold the newest sample since carrier signal is valid a few cycles early
  logic signed [31:0] carrier_past_samples         [2:0]; 
  logic signed [31:0] carrier_past_intermediates   [N_FILTERS-1:0] [1:0];
  logic signed [31:0] carrier_past_outputs         [N_FILTERS-1:0] [1:0];

  typedef enum { WAITING, MODULATOR, ENVELOPE, CARRIER } state_t;
  state_t state;

  // generate (up to 12-ish) double-biquads, which takes up most of the DSP slices of the S7-50
  // we're going to pipeline these biquads to get the most bang for our buck
  // first we're going to filter modulator input, then envelope detect that, then filter 
  // carrier input

  // current inputs/outputs for the N_FILTERS double biquads
  logic signed [31:0] coeffs [N_FILTERS-1:0] [9:0];
  logic signed [31:0] x_n    [N_FILTERS-1:0];
  logic signed [31:0] x_n1   [N_FILTERS-1:0];
  logic signed [31:0] x_n2   [N_FILTERS-1:0];
  logic signed [31:0] i_n1   [N_FILTERS-1:0];
  logic signed [31:0] i_n2   [N_FILTERS-1:0];
  logic signed [31:0] y_n1   [N_FILTERS-1:0];
  logic signed [31:0] y_n2   [N_FILTERS-1:0];
  logic signed [31:0] i_n    [N_FILTERS-1:0];
  logic signed [31:0] y_n    [N_FILTERS-1:0];

  generate
    for (genvar i = 0; i < N_FILTERS; i++) begin
      double_biquad bq(
        .b0_0(coeffs[i][0]),
        .b1_0(coeffs[i][1]),
        .b2_0(coeffs[i][2]),
        .a1_0(coeffs[i][3]),
        .a2_0(coeffs[i][4]),
        .b0_1(coeffs[i][5]),
        .b1_1(coeffs[i][6]),
        .b2_1(coeffs[i][7]),
        .a1_1(coeffs[i][8]),
        .a2_1(coeffs[i][9]),
        .x_n(x_n[i]),
        .x_n1(x_n1[i]),
        .x_n2(x_n2[i]),
        .i_n1(i_n1[i]),
        .i_n2(i_n2[i]),
        .y_n1(y_n1[i]),
        .y_n2(y_n2[i]),
        .i_n(i_n[i]),
        .y_n(y_n[i])
      );
    end
  endgenerate

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= WAITING;

      for (int i = 0; i < 2; i++) begin
        modulator_past_samples[i] <= 0;
        carrier_past_samples[i] <= 0;
        for (int j = 0; j < N_FILTERS; j++) begin
          modulator_past_intermediates[j][i] <= 0;
          modulator_past_outputs[j][i] <= 0;
          envelope_past_intermediates[j][i] <= 0;
          envelope_past_outputs[j][i] <= 0;
          carrier_past_intermediates[j][i] <= 0;
          carrier_past_outputs[j][i] <= 0;
          carrier_out[j] <= 0;
          envelope_out[j] <= 0;
        end
      end
      carrier_past_samples[2] <= 0;
    end else begin
      case (state)
        WAITING: begin
          valid_out <= 0;
          if (valid_in) begin
            state <= MODULATOR;
            
            // set inputs to filter modulator signal
            for (int i = 0; i < N_FILTERS; i++) begin
              for (int j = 0; j < 10; j++) coeffs[i][j] <= COEFFS[i][j];
              // all filters receive the same modulator input
              x_n[i] <= modulator_sample_in;
              x_n1[i] <= modulator_past_samples[0];
              x_n2[i] <= modulator_past_samples[1];
              // intermediates and outputs vary by filter
              i_n1[i] <= modulator_past_intermediates[i][0];
              i_n2[i] <= modulator_past_intermediates[i][1];
              y_n1[i] <= modulator_past_outputs[i][0];
              y_n2[i] <= modulator_past_outputs[i][1];
            end

            // update all past sample values for modulator and carrier
            modulator_past_samples[0] <= modulator_sample_in;
            modulator_past_samples[1] <= modulator_past_samples[0];

            carrier_past_samples[0] <= carrier_sample_in;
            carrier_past_samples[1] <= carrier_past_samples[0];
            carrier_past_samples[2] <= carrier_past_samples[1];
          end
        end
        MODULATOR: begin
          for (int i = 0; i < N_FILTERS; i++) begin
            // set inputs for envelope detector
            for (int j = 0; j < 10; j++) coeffs[i][j] <= COEFFS[9][j];
            x_n[i] <= abs(y_n[i]);
            x_n1[i] <= abs(modulator_past_outputs[i][0]);
            x_n2[i] <= abs(modulator_past_outputs[i][1]);
            i_n1[i] <= envelope_past_intermediates[i][0];
            i_n2[i] <= envelope_past_intermediates[i][1];
            y_n1[i] <= envelope_past_outputs[i][0];
            y_n2[i] <= envelope_past_outputs[i][1];

            // filtered results already available since combinational
            // update all past intermediate/output values for modulator
            modulator_past_intermediates[i][0] <= i_n[i];
            modulator_past_intermediates[i][1] <= modulator_past_intermediates[i][0];
            modulator_past_outputs[i][0] <= y_n[i];
            modulator_past_outputs[i][1] <= modulator_past_outputs[i][0];
          end
          state <= ENVELOPE;
        end
        ENVELOPE: begin
          for (int i = 0; i < N_FILTERS; i++) begin
            // set inputs to filter carrier signal
            for (int j = 0; j < 10; j++) coeffs[i][j] <= COEFFS[i][j];
            x_n[i] <= carrier_past_samples[0];
            x_n1[i] <= carrier_past_samples[1];
            x_n2[i] <= carrier_past_samples[2];
            i_n1[i] <= carrier_past_intermediates[i][0];
            i_n2[i] <= carrier_past_intermediates[i][1];
            y_n1[i] <= carrier_past_outputs[i][0];
            y_n2[i] <= carrier_past_outputs[i][1];
            
            // update past results
            envelope_past_intermediates[i][0] <= i_n[i];
            envelope_past_intermediates[i][1] <= envelope_past_intermediates[i][0];
            envelope_past_outputs[i][0] <= y_n[i];
            envelope_past_outputs[i][1] <= envelope_past_outputs[i][0];

            envelope_out[i] <= y_n[i];
          end
          state <= CARRIER;
        end
        CARRIER: begin
          for (int i = 0; i < N_FILTERS; i++) begin
            carrier_past_intermediates[i][0] <= i_n[i];
            carrier_past_intermediates[i][1] <= carrier_past_intermediates[i][0];
            carrier_past_outputs[i][0] <= y_n[i];
            carrier_past_outputs[i][1] <= carrier_past_outputs[i][0];

            carrier_out[i] <= y_n[i];
          end

          valid_out <= 1;
          state <= WAITING;
        end
      endcase
    end
  end 

endmodule

`default_nettype wire
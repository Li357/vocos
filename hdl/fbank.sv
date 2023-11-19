`timescale 1ns / 1ps
`default_nettype none

module fbank #(parameter N_FILTERS = 8)
(
  input wire clk_in,
  input wire rst_in,
  input wire valid_in,

  input wire signed [31:0] modulator_sample_in,
  output logic signed [31:0] carrier_out,
  output logic valid_out
);

  logic signed [31:0] COEFFS [N_FILTERS:0] [9:0];
  initial $readmemh(`FPATH(coeffs.mem), COEFFS);

  logic signed [31:0] modulator_past_samples       [1:0];
  logic signed [31:0] modulator_past_intermediates [1:0];
  logic signed [31:0] modulator_past_outputs       [1:0];

  typedef enum { WAITING, MODULATOR } state_t;
  state_t state;

  // generate (up to 12-ish) double-biquads, which takes up most of the DSP slices of the S7-50
  // we're going to pipeline these biquads to get the most bang for our buck
  // first we're going to filter modulator input, then envelope detect that, then filter 
  // carrier input

  // current inputs/outputs for the N_FILTERS double biquads
  logic signed [31:0] coeffs [9:0];
  logic signed [31:0] x_n  ;
  logic signed [31:0] x_n1 ;
  logic signed [31:0] x_n2 ;
  logic signed [31:0] i_n1 ;
  logic signed [31:0] i_n2 ;
  logic signed [31:0] y_n1 ;
  logic signed [31:0] y_n2 ;
  logic signed [31:0] i_n  ;
  logic signed [31:0] y_n  ;

logic f_valid_in;
logic f_valid_out;
      double_biquad bq(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .valid_in(f_valid_in),
        .b0_0(coeffs[0]),
        .b1_0(coeffs[1]),
        .b2_0(coeffs[2]),
        .a1_0(coeffs[3]),
        .a2_0(coeffs[4]),
        .b0_1(coeffs[5]),
        .b1_1(coeffs[6]),
        .b2_1(coeffs[7]),
        .a1_1(coeffs[8]),
        .a2_1(coeffs[9]),
        .x_n(x_n),
        .x_n1(x_n1),
        .x_n2(x_n2),
        .i_n1(i_n1),
        .i_n2(i_n2),
        .y_n1(y_n1),
        .y_n2(y_n2),
        .i_n(i_n),
        .y_n(y_n),
        .valid_out(f_valid_out)
      );

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= WAITING;

      carrier_out <= 0;

      for (int i = 0; i < 2; i++) begin
        modulator_past_samples[i] <= 0;
        modulator_past_intermediates[i] <= 0;
        modulator_past_outputs[i] <= 0;
      end
    end else begin
      case (state)
        WAITING: begin
          valid_out <= 0;
          if (valid_in) begin
            state <= MODULATOR;
            
            // set inputs to filter modulator signal
            for (int j = 0; j < 10; j++) coeffs[j] <= COEFFS[3][j];
            // all filters receive the same modulator input
            x_n <= modulator_sample_in;
            x_n1 <= modulator_past_samples[0];
            x_n2 <= modulator_past_samples[1];
            // intermediates and outputs vary by filter
            i_n1 <= modulator_past_intermediates[0];
            i_n2 <= modulator_past_intermediates[1];
            y_n1 <= modulator_past_outputs[0];
            y_n2 <= modulator_past_outputs[1];
            f_valid_in <= 1;

            // update all past sample values for modulator and carrier
            modulator_past_samples[0] <= modulator_sample_in;
            modulator_past_samples[1] <= modulator_past_samples[0];
          end
        end
        MODULATOR: begin
            f_valid_in <= 0;
            // set inputs for envelope detector
            // for (int j = 0; j < 10; j++) coeffs[i][j] <= COEFFS[8][j];
            // x_n[i] <= abs(y_n[i]);
            // x_n1[i] <= abs(modulator_past_outputs[i][0]);
            // x_n2[i] <= abs(modulator_past_outputs[i][1]);
            // i_n1[i] <= envelope_past_intermediates[i][0];
            // i_n2[i] <= envelope_past_intermediates[i][1];
            // y_n1[i] <= envelope_past_outputs[i][0];
            // y_n2[i] <= envelope_past_outputs[i][1];

            // filtered results already available since combinational
            // update all past intermediate/output values for modulator
            if (f_valid_out) begin
              modulator_past_intermediates[0] <= i_n;
              modulator_past_intermediates[1] <= modulator_past_intermediates[0];
              modulator_past_outputs[0] <= y_n;
              modulator_past_outputs[1] <= modulator_past_outputs[0];

          

            carrier_out <= y_n;
            valid_out <= 1;
            state <= WAITING; //ENVELOPE
            end
        end
      endcase
    end
  end 

endmodule

`default_nettype wire
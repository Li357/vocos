`timescale 1ns / 1ps
`default_nettype none

module mixer #(parameter N_FILTERS = 8) (
  input wire clk_in,
  input wire rst_in,
  input wire valid_in,
  input wire signed [31:0] carrier_channels [N_FILTERS-1:0],
  input wire signed [31:0] envelope_channels [N_FILTERS-1:0],
  output logic signed [23:0] mixed_out,
  output logic valid_out
);

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      mixed_out <= 0;
    end else begin
      if (valid_in) begin
        mixed_out <= (
          carrier_channels[0] +//* envelope_channels[0] + 
          carrier_channels[1] +//* envelope_channels[1] + 
          carrier_channels[2] +//* envelope_channels[2] + 
          carrier_channels[3] +//* envelope_channels[3] + 
          carrier_channels[4] +//* envelope_channels[4] + 
          carrier_channels[5] +//* envelope_channels[5] + 
          carrier_channels[6] +//* envelope_channels[6] + 
          carrier_channels[7] //* envelope_channels[7]
        );
        valid_out <= 1;
      end else valid_out <= 0;
    end
  end

endmodule

`default_nettype wire
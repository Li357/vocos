`timescale 1ns / 1ps
`default_nettype none

module filterbank #(
  parameter FILTERS = 9
)
(
  input wire clk_in,
  input wire rst_in,
  input wire valid_in,
  input wire signed [31:0] sample_in,
  output logic signed [31:0] sample_out,
  output logic valid_out
);

  localparam logic signed [31:0] COEFFS [FILTERS-1:0] [9:0] = '{
    '{32'd2692, 32'd0, -32'd2692, -32'd2092475, 32'd1044037, 32'd2692, 32'd0, -32'd2692, -32'd2094015, 32'd1045502},
    '{32'd4609, 32'd0, -32'd4609, -32'd2088978, 32'd1040805, 32'd4609, 32'd0, -32'd4609, -32'd2091702, 32'd1043311},
    '{32'd7885, 32'd0, -32'd7885, -32'd2082683, 32'd1035289, 32'd7885, 32'd0, -32'd7885, -32'd2087598, 32'd1039565},
    '{32'd13468, 32'd0, -32'd13468, -32'd2071018, 32'd1025900, 32'd13468, 32'd0, -32'd13468, -32'd2080158, 32'd1033172},
    '{32'd22943, 32'd0, -32'd22943, -32'd2048500, 32'd1010008, 32'd22943, 32'd0, -32'd22943, -32'd2066225, 32'd1022297},
    '{32'd38909, 32'd0, -32'd38909, -32'd2002721, 32'd983362, 32'd38909, 32'd0, -32'd38909, -32'd2038930, 32'd1003885},
    '{32'd65498, 32'd0, -32'd65498, -32'd1904345, 32'd939458, 32'd65498, 32'd0, -32'd65498, -32'd1982403, 32'd972929},
    '{32'd108948, 32'd0, -32'd108948, -32'd1683483, 32'd869436, 32'd108948, 32'd0, -32'd108948, -32'd1858478, 32'd921291},
    '{32'd177925, 32'd0, -32'd177925, -32'd1575797, 32'd835325, 32'd177925, 32'd0, -32'd177925, -32'd1184298, 32'd764906}
  };

  logic signed [31:0] filtered [FILTERS-1:0];
  logic signed [FILTERS-1:0] filtered_valid;

  generate
    for (genvar i = 0; i < FILTERS; i++) begin
      double_biquad #(
        .coeffs1(COEFFS[i][4:0]),
        .coeffs2(COEFFS[i][9:5])
      ) b1(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .valid_in(valid_in),
        .sample_in(sample_in),
        .sample_out(filtered[i]),
        .valid_out(filtered_valid[i])
      );
    end
  endgenerate

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      sample_out <= 0;
      valid_out <= 0;
    end else begin
      if (&filtered_valid) begin
        valid_out <= 1;
        sample_out <= filtered[0] + filtered[1] + filtered[2] + filtered[3] + filtered[4] + filtered[5] + filtered[6] + filtered[7] + filtered[8];
      end else if (valid_out) valid_out <= 0;
    end
  end

endmodule

`default_nettype wire
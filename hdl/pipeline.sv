`timescale 1ns / 1ps
`default_nettype none

module pipeline #(
  parameter DEPTH = 2,
  parameter WIDTH = 16
) (
  input wire clk_in,
  input wire [WIDTH-1:0] data_in,
  output logic [WIDTH-1:0] data_out
);

  logic [WIDTH-1:0] pipeline [DEPTH-1:0];
  assign data_out = pipeline[DEPTH-1];

  always_ff @(posedge clk_in) begin
    pipeline[0] <= data_in;
    for (int i = 1; i < DEPTH; i++) begin
      pipeline[i] <= pipeline[i-1];
    end
  end

endmodule

`default_nettype wire
`timescale 1 ns / 1 ps
`default_nettype none

module pdm #(parameter WIDTH = 16)
(
  input wire clk_in,
  input wire [WIDTH-1:0] data_in,
  input wire rst_in,
  output logic data_out
);

  localparam MAX = 2 ** WIDTH - 1;
  logic [WIDTH-1:0] error_0;
  logic [WIDTH-1:0] error_1;
  logic [WIDTH-1:0] error;

  always @(posedge clk_in) begin
    error_1 <= error + MAX - data_in;
    error_0 <= error - data_in;
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      data_out <= 0;
      error <= 0;
    end else if (data_in >= error) begin
      data_out <= 1;
      error <= error_1;
    end else begin
      data_out <= 0;
      error <= error_0;
    end
  end

endmodule

`default_nettype wire
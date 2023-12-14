`timescale 1ns / 1ps
`default_nettype none

module maxbit(
  input wire clk_in,
  input wire rst_in,
  input wire signed [23:0] data,
  output logic [7:0] max
);

  logic [7:0] out;
  always_comb begin
    casex (data[23:16])
      8'b00000001: out = 8'h16;
      8'b0000001x: out = 8'h17;
      8'b000001xx: out = 8'h18;
      8'b00001xxx: out = 8'h19;
      8'b0001xxxx: out = 8'h20; 
      8'b001xxxxx: out = 8'h21; 
      8'b01xxxxxx: out = 8'h22; 
      8'b1xxxxxxx: out = 8'h23; 
    endcase
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      max <= 0;
    end else begin
      if (out > max && data > 0) max <= out;
    end
  end

endmodule
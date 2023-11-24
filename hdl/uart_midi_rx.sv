`timescale 1ns / 1ps
`default_nettype none

module uart_midi_rx
  import constants::*;
(
  input wire clk_in,
  input wire rst_in,

  input wire rx_in,

  output logic valid_out,
  output logic [MIDI_BYTES-1:0] midi_bytes
);

  logic byte_valid;
  logic [7:0] byte_out;
  logic [MIDI_BYTES-1:0] midi_bytes;
  logic [1:0] index;
  
  uart_rx #(.CLOCKS_PER_BAUD(32)) u(
    .clk(clk_in),
    .rx(rx_in),
    .data_o(byte_out),
    .valid_o(byte_valid)
  );

  always_ff @(posedge clk_in) begin
    if (byte_valid) begin
      midi_bytes <= {midi_bytes[MIDI_BYTES-9:0], byte_out};
    end
  end

endmodule
`timescale 1ns / 1ps
`default_nettype none

function [7:0] flip8(input [7:0] data);
  for (int i = 0; i < 8; i = i + 1) begin
    flip8[7 - i] = data[i];
  end
endfunction

module max3421_spi_tb();

  logic clk_in;
  logic rst_in;
  logic rst_out;
  logic n_ss_out;
  logic mosi_out;
  logic miso_in;
  logic clk_out;

  logic [7:0] bytes_in [63:0];
  logic [7:0] bytes_out [63:0];
  logic [6:0] byte_count;
  logic txing;
  logic has_byte;

  logic [23:0] miso_in_fake = 24'b000000001111111101010101;

  max3421_spi uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .bytes_in_count(byte_count),
    .bytes_in(bytes_in),
    .valid_in(txing),
    .n_ss_out(n_ss_out),
    .mosi_out(mosi_out),
    .miso_in(miso_in),
    .clk_out(clk_out),
    .valid_out(has_byte),
    .bytes_out(bytes_out)
  );

  always begin
    #20;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("max3421_spi_tb.vcd");
    $dumpvars(0, max3421_spi_tb);
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    miso_in = 0;
    #40;
    rst_in = 1;
    #40;
    rst_in = 0;

    #80;

    $display("Testing multi-byte WRITE");
    // write on reg 17
    bytes_in[0] = flip8({5'd17, 3'b010});
    bytes_in[1] = flip8(8'b00010100);
    bytes_in[2] = flip8(8'b11111111);
    byte_count = 3;
    txing = 1;
    #960
    #200;
    txing = 0;

    #80;

    $display("Testing multi-byte READ");

    // read on reg 18
    bytes_in[0] = flip8({5'd18, 3'b000});
    txing = 1;
    #20;
    for (int i = 0; i < 24; i++) begin
      #20;
      // miso-in is clocked on negedge
      miso_in = miso_in_fake[i];
      #20;
    end
    txing = 0;

    #80;

    #480;

    $display("Finishing");
    $finish;
  end

endmodule

`timescale 1ns / 1ps
`default_nettype none

module usb_controller_tb();

  logic clk_in;
  logic rst_in;
  logic n_rst_out;
  logic n_ss_out;
  logic mosi_out;
  logic [15:0] byte_out;

  usb_controller uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .int_in(1'b0),
    .miso_in(1'b0),
    .n_rst_out(n_rst_out),
    .n_ss_out(n_ss_out),
    .mosi_out(mosi_out),
    .bytes_out(byte_out)
  );

  always begin
    #20;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("usb_controller_tb.vcd");
    $dumpvars(0, usb_controller_tb);
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    #40;
    rst_in = 1;
    #40;
    rst_in = 0;

    #40000;

    $display("Finishing");
    $finish;
  end

endmodule

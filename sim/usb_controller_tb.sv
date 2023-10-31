`timescale 1ns / 1ps
`default_nettype none

module usb_controller_tb();

  logic clk_in;
  logic rst_in;
  logic rst_out;
  logic ss_out;
  logic mosi;
  logic [7:0] data;
  assign data = 8'b10010001;

  usb_controller uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .int_in(1'b0),
    .miso_in(1'b0),
    .rst_out(rst_out),
    .ss_out(ss_out),
    .mosi_out(mosi)
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

    #360;
    for (int i = 7; i >= 0; i--) begin
      mosi = data[i];
      #40;
    end
    #400

    $display("Finishing");
    $finish;
  end

endmodule

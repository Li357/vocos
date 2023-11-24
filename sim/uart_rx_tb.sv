`timescale 1ns / 1ps
`default_nettype none

module uart_rx_tb();

  logic clk_in;
  logic rst_in;
  logic [7:0] rx;
  logic rx_in;

  uart_rx uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rx_in(rx_in)
  );

  always begin
    #10;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("uart_rx_tb.vcd");
    $dumpvars(0, uart_rx_tb);
    $display("Starting");

    #20;
    clk_in = 0;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;
    rx_in = 1;
    rx = 8'b01010011;
    #200;
    rx_in = 0;
    #320;
    for (int i = 0; i < 8; i++) begin
      #640;
      rx_in = rx[i];
    end
    #500;

    $display("Finishing");
    $finish;
  end

endmodule

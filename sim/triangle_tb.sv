`timescale 1ns / 1ps
`default_nettype none

module triangle_tb();

  logic clk_in;
  logic rst_in;
  logic [23:0] audio;

  triangle uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .phase_incr_in(24'h1FFFFF),
    .val_out(audio)
  );

  always begin
    #10;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("triangle_tb.vcd");
    $dumpvars(0, triangle_tb);
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;

    #5000000;

    $display("Finishing");
    $finish;
  end

endmodule

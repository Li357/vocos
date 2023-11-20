`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

function [31:0] abs(input [31:0] x);
  abs = x[31] ? -x : x;
endfunction

module envelope_tb();

  logic clk_in;
  logic rst_in;
  logic valid_in;
  logic valid_out;

  logic [31:0] COEFFS [8:0] [9:0];
  initial $readmemh(`FPATH(coeffs.mem), COEFFS);

  logic [31:0] coeffs [9:0];
  logic [31:0] x_n, x_n1, x_n2, i_n1, i_n2, y_n1, y_n2, i_n, y_n;
  logic [4:0] shift;

  double_biquad bq(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .valid_in(valid_in),
    .b0_0(coeffs[0]),
    .b1_0(coeffs[1]),
    .b2_0(coeffs[2]),
    .a1_0(coeffs[3]),
    .a2_0(coeffs[4]),
    .b0_1(coeffs[5]),
    .b1_1(coeffs[6]),
    .b2_1(coeffs[7]),
    .a1_1(coeffs[8]),
    .a2_1(coeffs[9]),
    .x_n(x_n),
    .x_n1(x_n1),
    .x_n2(x_n2),
    .i_n1(i_n1),
    .i_n2(i_n2),
    .y_n1(y_n1),
    .y_n2(y_n2),
    .i_n(i_n),
    .y_n(y_n),
    .shift(shift),
    .valid_out(valid_out)
  );

  always begin
    #10;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("envelope_tb.vcd");
    $dumpvars(0, envelope_tb);
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    valid_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;
    #40;

    // BPF
    valid_in = 1;
    shift = 20;
    for (int i = 0; i < 10; i++) coeffs[i] = COEFFS[7][i];
    x_n2 = 0;
    x_n1 = 0;
    x_n  = 10000 << 20;
    i_n2 = 0;
    i_n1 = 0;
    y_n2 = 0;
    y_n1 = 0;
    #20;
    valid_in = 0;
    #20;

    // LPF
    valid_in = 1;
    shift = 8;
    for (int i = 0; i < 10; i++) coeffs[i] = COEFFS[8][i];
    x_n2 = abs(y_n2);
    x_n1 = abs(y_n1);
    x_n  = abs(y_n);
    i_n2 = 0;
    i_n1 = 0;
    y_n2 = 0;
    y_n1 = 0;
    #20;

    #400;

    $display("Finishing");
    $finish;
  end

endmodule

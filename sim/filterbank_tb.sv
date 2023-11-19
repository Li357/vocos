`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module filterbank_tb();

  logic clk_in;
  logic rst_in;
  logic valid_in;
  logic signed [31:0] carrier_sample_in;
  logic signed [31:0] modulator_sample_in;
  logic signed [31:0] carrier_out [8:0];
  logic signed [31:0] envelope_out [8:0];

  filterbank uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .valid_in(valid_in),
    .carrier_sample_in(carrier_sample_in),
    .modulator_sample_in(modulator_sample_in),
    .carrier_out(carrier_out),
    .envelope_out(envelope_out)
  );

  always begin
    #10;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("filterbank_tb.vcd");
    $dumpvars(0, filterbank_tb);
    for (int i = 0; i < 9; i++) begin
      $dumpvars(0, carrier_out[i]);
      $dumpvars(0, envelope_out[i]);
    end
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;
    #120;

    for (int i = 1; i < 5; i++) begin
      valid_in = 1;
      carrier_sample_in = i << 20;
      modulator_sample_in = i << 20;
      #20;
      valid_in = 0;
      #620;
    end
    #5000;

    $display("Finishing");
    $finish;
  end

endmodule

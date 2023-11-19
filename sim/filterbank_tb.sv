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
  logic signed [31:0] carrier_out [7:0];
  logic signed [31:0] envelope_out [7:0];

  logic fb_valid;
  filterbank uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .valid_in(valid_in),
    .carrier_sample_in(carrier_sample_in),
    .modulator_sample_in(modulator_sample_in),
    .carrier_out1(carrier_out[0]),
    .carrier_out2(carrier_out[1]),
    .carrier_out3(carrier_out[2]),
    .carrier_out4(carrier_out[3]),
    .carrier_out5(carrier_out[4]),
    .carrier_out6(carrier_out[5]),
    .carrier_out7(carrier_out[6]),
    .carrier_out8(carrier_out[7]),
    .envelope_out(envelope_out),
    .valid_out(fb_valid)
  );

  logic mixed_valid;
  mixer uut2(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .valid_in(fb_valid),
    .carrier_channel1(carrier_out[0]),
    .carrier_channel2(carrier_out[1]),
    .carrier_channel3(carrier_out[2]),
    .carrier_channel4(carrier_out[3]),
    .carrier_channel5(carrier_out[4]),
    .carrier_channel6(carrier_out[5]),
    .carrier_channel7(carrier_out[6]),
    .carrier_channel8(carrier_out[7]),
    .envelope_channels(envelope_out),
    .valid_out(mixed_valid)
  );

  always begin
    #10;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("filterbank_tb.vcd");
    $dumpvars(0, filterbank_tb);
    // for (int i = 0; i < 8; i++) begin
    //   $dumpvars(0, carrier_out[i]);
    //   $dumpvars(0, envelope_out[i]);
    // end
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;
    #120;

    for (int i = -5; i < 5; i++) begin
      valid_in = 1;
      carrier_sample_in = i << 24;
      modulator_sample_in = i << 24;
      #20;
      valid_in = 0;
      #620;
    end
    #5000;

    $display("Finishing");
    $finish;
  end

endmodule

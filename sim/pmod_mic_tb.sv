`timescale 1ns / 1ps
`default_nettype none

module pmod_mic_tb();

  logic clk_in;
  logic rst_in;
  logic data_in;
  logic [31:0] data [2:0]; // 18 bit mic data but clocked out in 32-bit chunks

  assign data[0] = 32'hFF_EE_EE;
  assign data[1] = 32'hBB_AA_CC;
  assign data[2] = 32'hDD_88_11;

  pmod_mic uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .data_in(data_in)
  );

  always begin
    #10;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("pmod_mic_tb.vcd");
    $dumpvars(0, pmod_mic_tb);
    $display("Starting");

    clk_in = 0;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;
    #310;
    #320;

    for (int k = 0; k < 3; k++) begin
      for (int i = 0; i < 32; i++) begin
        data_in = data[k][23 - i];
        #640;
      end
      #20480;
    end

    #4000;

    $display("Finishing");
    $finish;
  end

endmodule

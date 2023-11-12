`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module synthesizer(
  input wire clk_in,
  input wire rst_in,
  input wire [31:0] phase_incr_in,
  output logic signed [10:0] audio_out,
);

  localparam SAMPLES = 4096;
  localparam SAMPLE_WIDTH = 11;
  localparam SAMPLE_ADDR_BITS = $clog2(SAMPLES);

  logic signed [10:0] sine_lut_out;
  logic [31:0] phase_acc;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SAMPLE_WIDTH),
    .RAM_DEPTH(SAMPLES),
    .INIT_FILE(`FPATH(sine.mem))
  ) sine_lut(
    .addra(phase_acc[31 -: SAMPLE_ADDR_BITS]),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(rst_in),
    .regcea(1'b1),
    .douta(sine_lut_out)
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) phase_acc <= 0;
    else phase_acc <= phase_acc + phase_incr_in; 
  end

  assign audio_out = sine_lut_out >>> 32;

endmodule

`default_nettype wire
`timescale 1ns / 1ps
`default_nettype none

module sine
  import constants::*;
(
  input wire clk_in,
  input wire rst_in,
  input wire [SYNTH_PHASE_ACC_BITS-1:0] phase_incr_in,
  output logic signed [SYNTH_WIDTH-1:0] val_out
);

  localparam SAMPLES = 16384; // 2^14 samples of 23-bit values

  // value in the LUT is not signed
  logic [SYNTH_WIDTH-2:0] sine_lut_curr;
  logic [SYNTH_PHASE_ACC_BITS-1:0] phase_acc_curr;

  always_ff @(posedge clk_in) begin
    if (rst_in) phase_acc_curr <= 0;
    else phase_acc_curr <= phase_acc_curr + phase_incr_in;
  end

  // We'll use MSBs of the phase accumulator to index into the 2^14-sample
  // LUT and use the top 2 bits to exploit the symmetry
  logic [$clog2(SAMPLES)-1:0] addr_curr;
  assign addr_curr = phase_acc_curr[SYNTH_PHASE_ACC_BITS-3 -: $clog2(SAMPLES)];

  // we'll use the MSB for symmetry
  logic phase_msb_curr;
  pipeline #(
    .DEPTH(2), // since BRAM has 2-clock latency
    .WIDTH(1)
  ) addr_pipe_curr(
    .clk_in(clk_in),
    .data_in(phase_acc_curr[SYNTH_PHASE_ACC_BITS-1]),
    .data_out(phase_msb_curr)
  );

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SYNTH_WIDTH - 1),
    .RAM_DEPTH(SAMPLES),
    .INIT_FILE(`FPATH(sine.mem))
  ) sine_lut(
    .addra(phase_acc_curr[SYNTH_PHASE_ACC_BITS-2] ? ~addr_curr : addr_curr),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(rst_in),
    .regcea(1'b1),
    .douta(sine_lut_curr),
    .enb(1'b0)
  );

  logic signed [SYNTH_WIDTH-1:0] sine_val_curr;
  assign sine_val_curr = phase_msb_curr ? -sine_lut_curr : sine_lut_curr;

  always_ff @(posedge clk_in) begin
    if (rst_in) val_out <= 0;
    else val_out <= sine_val_curr;
  end

endmodule

`default_nettype wire
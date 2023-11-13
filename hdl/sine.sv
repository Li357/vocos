`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module sine
  import constants::*;
(
  input wire clk_in,
  input wire rst_in,
  input wire [SYNTH_PHASE_ACC_BITS-1:0] phase_incr_in,
  output logic signed [SYNTH_WIDTH-1:0] val_out
);

  localparam SAMPLES = 16384; // 2^14

  logic signed [SYNTH_WIDTH-1:0] sine_lut_curr;
  logic signed [SYNTH_WIDTH-1:0] sine_lut_next;
  logic [SYNTH_PHASE_ACC_BITS-1:0] phase_acc_curr;
  logic [SYNTH_PHASE_ACC_BITS-1:0] phase_acc_next;

  assign phase_acc_next = phase_acc_curr + 1;
  always_ff @(posedge clk_in) begin
    if (rst_in) phase_acc_curr <= 0;
    else phase_acc_curr <= phase_acc_curr + phase_incr_in;
  end

  // We'll use MSBs of the phase accumulator to index into the 2^14-sample
  // LUT and use the top 2 bits to exploit the symmetry, then use the 4 LSBs
  // to linearly interpolate and get 2^(14 + 2 + 4) resolution
  logic [$clog2(SAMPLES)-1:0] addr_curr;
  logic [$clog2(SAMPLES)-1:0] addr_next;
  assign addr_curr = phase_acc_curr[SYNTH_PHASE_ACC_BITS-2 -: $clog2(SAMPLES)];
  assign addr_next = phase_acc_next[SYNTH_PHASE_ACC_BITS-2 -: $clog2(SAMPLES)];

  // we'll use the MSB for symmetry and LSBs for interpolation
  logic [4:0] phase_msb_lsbs_curr;
  pipeline #(
    .DEPTH(2), // since BRAM has 2-clock latency
    .WIDTH(5)
  ) addr_pipe_curr(
    .clk_in(clk_in),
    .data_in({phase_acc_curr[SYNTH_PHASE_ACC_BITS-1], phase_acc_curr[3:0]}),
    .data_out(phase_msb_lsbs_curr)
  );

  logic [4:0] phase_msb_lsbs_next;
  pipeline #(
    .DEPTH(2),
    .WIDTH(5)
  ) addr_pipe_next(
    .clk_in(clk_in),
    .data_in({phase_acc_next[SYNTH_PHASE_ACC_BITS-1], phase_acc_next[3:0]}),
    .data_out(phase_msb_lsbs_next)
  );

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SYNTH_WIDTH),
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
    .addrb(phase_acc_next[SYNTH_PHASE_ACC_BITS-2] ? ~addr_next : addr_next),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb(sine_lut_next)
  );

  logic signed [SYNTH_WIDTH-1:0] sine_val_curr;
  logic signed [SYNTH_WIDTH-1:0] sine_val_next;
  assign sine_val_curr = phase_msb_lsbs_curr[4] ? {1'b0, -sine_lut_curr} : {1'b1, sine_lut_curr};
  assign sine_val_next = phase_msb_lsbs_next[4] ? {1'b0, -sine_lut_next} : {1'b1, sine_lut_next};

  always_ff @(posedge clk_in) begin
    val_out <= (5'b10000 - phase_msb_lsbs_curr[4:0]) * sine_val_curr + phase_msb_lsbs_curr[4:0] * sine_val_next;
  end

endmodule

`default_nettype wire
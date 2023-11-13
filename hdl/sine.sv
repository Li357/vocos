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

  logic signed [SYNTH_WIDTH-1:0] sine_val;
  logic signed [SYNTH_WIDTH-1:0] sine_val_next;
  logic [SYNTH_PHASE_ACC_BITS-1:0] phase_acc;

  // We'll use MSBs of the phase accumulator to index into the 2^14-sample
  // LUT and use the top 2 bits to exploit the symmetry and get 2^16 phase
  // resolution
  logic [$clog2(SAMPLES)-1:0] addr;
  logic [$clog2(SAMPLES)-1:0] addr_sym1;
  assign addr = phase_acc[SYNTH_PHASE_ACC_BITS-2 -: $clog2(SAMPLES)];
  assign addr_sym1 = phase_acc[SYNTH_PHASE_ACC_BITS-2] ? ~addr : addr;

  logic phase_msb;
  pipeline #(
    .DEPTH(2), // since BRAM has 2-clock latency
    .WIDTH(1)
  ) addr_pipe(
    .clk_in(clk_in),
    .data_in(phase_acc[SYNTH_PHASE_ACC_BITS-1]),
    .data_out(phase_msb)
  );

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SYNTH_WIDTH),
    .RAM_DEPTH(SAMPLES),
    .INIT_FILE(`FPATH(sine.mem))
  ) sine_lut(
    .addra(addr_sym1),
    .clka(clk_in),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(rst_in),
    .regcea(1'b1),
    .douta(sine_val),
    .addrb(addr_sym1 + 1),
    .clkb(clk_in),
    .web(1'b0),
    .enb(1'b1),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb(sine_val_next)
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) phase_acc <= 0;
    else phase_acc <= phase_acc + phase_incr_in;
  end

  assign val_out = phase_msb ? {1'b0, -sine_val} : {1'b1, sine_val};

endmodule

`default_nettype wire
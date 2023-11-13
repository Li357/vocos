`timescale 1ns / 1ps
`default_nettype none

package constants;

  parameter SYNTH_CYCLES = 512;
  parameter PDM_CYCLES = 8;

  parameter SYNTH_WIDTH = 24;

  // Using 24 bits allows us to achieve 192kHz / 2^24 = 0.012Hz
  // frequency resolution, which is a cent of a half step
  parameter SYNTH_PHASE_ACC_BITS = 24;

endpackage

`default_nettype wire
package constants;

  parameter SYNTH_CYCLES = 512;
  parameter PDM_CYCLES = 8;

  parameter SYNTH_WIDTH = 24;

  // Using 24 bits allows us to achieve 192kHz / 2^24 = 0.012Hz
  // frequency resolution, which is a cent of a half step
  parameter SYNTH_PHASE_ACC_BITS = 24;

  parameter N_FILTERS = 16;

  parameter MIDI_BYTES = 24;

endpackage
`timescale 1ns / 1ps
`default_nettype none

module midi
  import constants::*;
(
  input wire clk_in,
  input wire rst_in,
  input wire [MIDI_BYTES-1:0] midi_event,

  output logic [SYNTH_PHASE_ACC_BITS-1:0] phase_incr_out,
  output logic [4:0] vol_out
);

  // All MIDI messages are on channel 0
  localparam NOTE_ON    = 8'h90;
  localparam NOTE_OFF   = 8'h80;
  localparam PITCH_BEND = 8'hE0;
  localparam CC         = 8'hB0;

  logic [SYNTH_PHASE_ACC_BITS-1:0] NOTES [107:0];
  initial $readmemb(`FPATH(notes.mem), NOTES);

  logic [3:0] notes_on;
  logic [7:0] pitch; // just support one voice at a time
  logic [7:0] velocity;
  assign phase_incr_out = pitch ? NOTES[pitch - 12] : 0; // since index 0 is B0, which is MIDI note 12

  logic [MIDI_BYTES-1:0] prev_event;
  logic new_event;
  assign new_event = midi_event != prev_event;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      pitch <= 0;
      notes_on <= 0;
    end else if (new_event) begin
      case (midi_event[23:16])
        NOTE_ON: begin
          pitch <= midi_event[15:8];
          velocity <= midi_event[7:0];
          notes_on <= notes_on + 1;
        end
        NOTE_OFF: begin
          notes_on <= notes_on - 1;
          // only turn off synth when last note is release
          if (notes_on == 1) begin
            pitch <= 0;
            velocity <= 0;
          end
        end
      endcase
    end

    prev_event <= midi_event;
  end

endmodule

`default_nettype wire
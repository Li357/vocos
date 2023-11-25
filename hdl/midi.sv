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

  localparam MOD_WHEEL     = 8'h01;
  // MPK mini 3 wheels
  localparam ATTACK_TIME   = 8'h46;
  localparam DECAY_TIME    = 8'h47;
  localparam SUSTAIN_LEVEL = 8'h48;
  localparam RELEASE_TIME  = 8'h49;

  logic [SYNTH_PHASE_ACC_BITS-1:0] NOTES [107:0];
  initial $readmemb(`FPATH(notes.mem), NOTES);

  logic [31:0] PITCH_BEND_FACTORS [127:0];
  initial $readmemb(`FPATH(pitchbends.mem), PITCH_BEND_FACTORS);

  logic [SYNTH_PHASE_ACC_BITS-1:0] MOD_PHASES [127:0];
  initial $readmemb(`FPATH(modphases.mem), MOD_PHASES);

  logic [7:0] pitch; // just support one voice at a time
  logic [7:0] pitchbend;
  logic [7:0] velocity;
  logic [7:0] mod;

  // logic [SYNTH_PHASE_ACC_BITS-1:0] lfo_phase_incr;
  // assign lfo_phase_incr = MOD_PHASES[mod];

  // logic signed [SYNTH_WIDTH-1:0] lfo_out;

  // sine lfo(
  //   .clk_in(clk_in),
  //   .rst_in(rst_in),
  //   .phase_incr_in(lfo_phase_incr),
  //   .val_out(lfo_out)
  // );

  logic [63:0] temp;
  assign temp = NOTES[pitch - 12] * PITCH_BEND_FACTORS[pitchbend];
  assign phase_incr_out = pitch ? (temp >>> 20) : 0;//+ $signed(lfo_out >>> 19) : 0; // since index 0 is B0, which is MIDI note 12

  logic [MIDI_BYTES-1:0] prev_event;
  logic new_event;
  assign new_event = midi_event != prev_event;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      pitch <= 0;
      pitchbend <= 64;
    end else if (new_event) begin
      case (midi_event[23:16])
        NOTE_ON: begin
          pitch <= midi_event[15:8];
          velocity <= midi_event[7:0];
        end
        NOTE_OFF: begin
          // only turn off synth when current note is released
          if (midi_event[15:8] == pitch) begin
            pitch <= 0;
            velocity <= midi_event[7:0];
          end
        end
        PITCH_BEND: begin
          // Use MSBs of pitchbend event
          pitchbend <= midi_event[6:0];
        end
        CC: begin
          case (midi_event[15:8])
            MOD_WHEEL: begin
              mod <= midi_event[6:0];
            end
            ATTACK_TIME: begin

            end
            RELEASE_TIME: begin

            end
          endcase
        end
      endcase
    end

    prev_event <= midi_event;
  end

endmodule

`default_nettype wire
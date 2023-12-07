`timescale 1ns / 1ps
`default_nettype none

module midi
  import constants::*;
#(
  parameter ADSR_BITS = 20 // bits for ADSR counter
)
(
  input wire clk_in,
  input wire rst_in,
  input wire [MIDI_BYTES-1:0] midi_event,

  output logic [SYNTH_PHASE_ACC_BITS-1:0] phase_incr_out,
  output logic [8:0] vol_out
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
  logic [7:0] mod;

  logic [7:0] attack_time;
  logic [7:0] decay_time;
  logic [7:0] sustain_level;
  logic [7:0] release_time;

  typedef enum { WAITING, ATTACK, DECAY, SUSTAIN, RELEASE } state_t;
  state_t state;

  logic [SYNTH_PHASE_ACC_BITS-1:0] lfo_phase_incr;
  assign lfo_phase_incr = MOD_PHASES[mod];

  logic signed [SYNTH_WIDTH-1:0] lfo_out;

  // Run LFO at 192kHz like synth, aka 98.3MHz / 512
  logic [8:0] clk_lfo_count;
  always_ff @(posedge clk_in) begin
    clk_lfo_count <= rst_in ? 0 : clk_lfo_count + 1;
  end
  sine lfo(
    .clk_in(clk_lfo_count[8]),
    .rst_in(rst_in),
    .phase_incr_in(lfo_phase_incr),
    .val_out(lfo_out)
  );

  // LFO has range of [-2^23, 2^23-1], remap it onto [-2^4, 2^4]
  logic signed [4:0] lfo_scaled;
  assign lfo_scaled = lfo_out >>> 19;

  logic signed [63:0] pitchbent;
  logic signed [63:0] moded;
  assign pitchbent = NOTES[pitch - 12] * PITCH_BEND_FACTORS[pitchbend]; // since index 0 is B0, which is MIDI note 12
  // Map [-2^4, 2^4] to [32, 96] since 64 is no pitchbend, and index into pitchbends
  assign moded = mod ? (pitchbent >>> 20) * PITCH_BEND_FACTORS[{~lfo_scaled[4], lfo_scaled[3:0]} + 7'd32] : pitchbent;
  assign phase_incr_out = pitch ? (moded >>> 20) : 0;

  // Run ADSR at 98.3MHz / 2^20 so that maximum attack time is, 128 times that, or ~1.4s
  logic [ADSR_BITS-1:0] adsr_count;
  logic clk_adsr;
  assign clk_adsr = adsr_count == 0;
  always_ff @(posedge clk_in) begin
    adsr_count <= rst_in ? 0 : adsr_count + 1;
  end

  logic [MIDI_BYTES-1:0] prev_event;
  logic new_event;
  assign new_event = midi_event != prev_event;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      pitch <= 12;
      mod <= 0;
      pitchbend <= 64;
      vol_out <= 0;
      state <= WAITING;
      attack_time <= 0;
      decay_time <= 0;
      sustain_level <= 127;
      release_time <= 0;
    end else if (new_event) begin
      case (midi_event[23:16])
        NOTE_ON: begin
          pitch <= midi_event[15:8];
          state <= ATTACK;
        end
        NOTE_OFF: begin
          // only turn off synth when current note is released
          if (midi_event[15:8] == pitch) begin
            state <= RELEASE;
          end
        end
        PITCH_BEND: begin
          // Use MSBs of pitchbend event
          pitchbend <= midi_event[6:0];
        end
        CC: begin
          case (midi_event[15:8])
            MOD_WHEEL: mod <= midi_event[6:0];
            ATTACK_TIME: attack_time <= midi_event[6:0];
            DECAY_TIME: decay_time <= midi_event[6:0];
            SUSTAIN_LEVEL: sustain_level <= midi_event[6:0];
            RELEASE_TIME: release_time <= midi_event[6:0];
          endcase
        end
      endcase
    // Otherwise, update the envelope according the ADSR clock which is REALLY slow to allow for
    // envelope times of up to 1 second
    end else if (clk_adsr) begin
      case (state)
        ATTACK: begin
          if (vol_out >= 127) begin
            vol_out <= 127;
            state <= DECAY;
          end else vol_out <= vol_out + (128 - attack_time);
        end
        DECAY: begin
          if (vol_out <= sustain_level) begin
            vol_out <= sustain_level;
            state <= SUSTAIN;
          end else vol_out <= vol_out - (128 - decay_time);
        end
        RELEASE: begin
          if (vol_out <= 128 - release_time) begin
            vol_out <= 0;
            pitch <= 0;
            state <= WAITING;
          end else vol_out <= vol_out - (128 - release_time);
        end
      endcase
    end

    prev_event <= midi_event;
  end

endmodule

`default_nettype wire
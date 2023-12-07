`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module midi_tb();

  logic clk_in;
  logic rst_in;
  logic [23:0] midi_event;

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

  midi #(.ADSR_BITS(5)) uut(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .midi_event(midi_event)
  );

  always begin
    #10;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("midi_tb.vcd");
    $dumpvars(0, midi_tb);
    $display("Starting");

    midi_event <= 0;
    clk_in = 0;
    #10;
    rst_in = 0;
    #20;
    rst_in = 1;
    #20;
    rst_in = 0;
    #10240; // allow 512 clock cycles to pass
    midi_event <= {CC, ATTACK_TIME, 8'd6};
    #200;
    midi_event <= {CC, MOD_WHEEL, 8'd25};
    #20_000;
    midi_event <= {NOTE_ON, 8'd75, 8'd0};
    #640; // at least 2^5 cycles to see ADSR increment/decrement
    #640;
    #640;
    #640;
    #640;
    midi_event <= {NOTE_OFF, 8'd75, 8'd0};
    #1000;


    $display("Finishing");
    $finish;
  end

endmodule

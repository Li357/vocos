`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module top_level(
  input wire          clk_100mhz,
  input wire [3:0]    btn,
  input wire          usb_int,
  input wire          usb_miso,
  input wire          uart_rxd,
  input wire [15:0]   sw,
  input wire          pmodb_dout,
  input wire          pmoda_lin_sdout,
  output logic        usb_n_rst,
  output logic        usb_n_ss,
  output logic        usb_mosi,
  output logic        usb_clk,
  output logic [15:0] led,

  output logic        pmoda_lout_mclk,
  output logic        pmoda_lout_lrck,
  output logic        pmoda_lout_sclk,
  output logic        pmoda_lout_sdin,
  output logic        pmoda_lin_mclk,
  output logic        pmoda_lin_lrck,
  output logic        pmoda_lin_sclk,

  output logic        pmodb_ws,
  output logic        pmodb_bclk,
  output logic        pmodb_sel,
  output logic        uart_txd,
  output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
  output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
  output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits
  output logic [6:0]  ss1_c, //cathod controls for the segments of lower four digits
  output logic [2:0]  rgb0, //rgb led
  output logic [2:0]  rgb1, //rgb led
  output logic spkl, 
  output logic spkr //speaker outputs
);

  import constants::*;

  logic clk_98_3mhz; // 98.333MHz
  logic clk_i2s;     // 36.875MHz
  clk_wiz wiz (
    .clk_in1(clk_100mhz),
    .clk_audio(clk_98_3mhz),
    .clk_i2s(clk_i2s)
  );

  logic sys_rst;
  assign sys_rst = btn[0];

  assign rgb1 = 0;
  assign rgb0 = 0;

  logic midi_valid;
  logic [MIDI_BYTES-1:0] midi_event;
  uart_midi_rx midi(
    .clk_in(clk_98_3mhz),
    .rst_in(sys_rst),
    .rx_in(uart_rxd),
    .valid_out(midi_valid),
    .midi_bytes(midi_event)
  );

  // the onboard MAX3421E USB chip can be clocked up to 26MHz
  // this is around 3MHz
  // logic clk_25mhz;
  // logic [3:0] clk_25mhz_count;
  // always_ff @(posedge clk_100mhz) begin
  //   if (sys_rst) clk_25mhz_count <= 0;
  //   else begin
  //     if (clk_25mhz_count == 7) clk_25mhz <= ~clk_25mhz;
  //     clk_25mhz_count <= clk_25mhz_count + 1;
  //   end
  // end

  // assign pmoda[0] = usb_miso;
  // assign pmoda[1] = usb_mosi;
  // assign pmoda[2] = usb_clk;
  // assign pmoda[3] = usb_n_ss;
  // assign pmoda[4] = usb_int;

  // logic [15:0] out;
  // logic [31:0] midi_out;

  // usb_controller usbc(
  //   .clk_in(clk_25mhz),
  //   .rst_in(sys_rst),
  //   .int_in(usb_int),
  //   .miso_in(usb_miso),
  //   .n_rst_out(usb_n_rst),
  //   .n_ss_out(usb_n_ss),
  //   .mosi_out(usb_mosi),
  //   .clk_out(usb_clk),
  //   .bytes_out(out),

  //   .rxd_in(uart_rxd),
  //   .txd_out(uart_txd),

  //   .midi_out(midi_out)
  // );

  // logic [6:0] ss_c;

  // seven_segment_controller mssc(
  //   .clk_in(clk_98_3mhz),
  //   .rst_in(sys_rst),
  //   .val_in(midi_out),
  //   .cat_out(ss_c),
  //   .an_out({ss0_an, ss1_an})
  // );
  // assign ss0_c = ss_c;
  // assign ss1_c = ss_c;

  // assign led[15:0] = out;

  // Synthesizer DDS clocked at 98.3MHz / 512 = 48kHz * 4 = 192kHz
  logic [$clog2(SYNTH_CYCLES)-1:0] clk_synth_count;
  logic clk_synth;
  assign clk_synth = clk_synth_count[$clog2(SYNTH_CYCLES)-1] == 0;
  always_ff @(posedge clk_98_3mhz) begin
    clk_synth_count <= clk_synth_count + 1;
  end

  // logic [SYNTH_PHASE_ACC_BITS-1:0] phase_acc;
  // switch_keyboard keyboard(
  //   .sw_in(sw[10:3]),
  //   .phase_acc_out(phase_acc)
  // );

  logic [7:0] midi_vol;

  logic [SYNTH_PHASE_ACC_BITS-1:0] phase_acc;
  midi miface(
    .clk_in(clk_98_3mhz),
    .rst_in(sys_rst),
    .midi_event(midi_event),
    .phase_incr_out(phase_acc),
    .vol_out(midi_vol)
  );

  logic signed [SYNTH_WIDTH-1:0] synth_out;
  synthesizer synth(
    .clk_in(clk_synth),
    .rst_in(sys_rst),
    .phase_incr_in(phase_acc),
    .wave_type_in(sw[2:0]),
    .synth_out(synth_out)
  );

  logic signed [30:0] noise;
  lsfr31 ngen(
    .clk_in(clk_synth),
    .rst_in(sys_rst),
    .data_out(noise)
  );

  logic signed [SYNTH_WIDTH-1:0] lin_out;

  logic signed [SYNTH_WIDTH-1:0] carrier;
  assign carrier = sw[10] ? lin_out : synth_out;

  logic signed [23:0] mic_sample;
  logic mic_sample_valid;
  assign pmodb_sel = 0;
  pmod_mic mic(
    .clk_in(clk_98_3mhz),
    .ws_out(pmodb_ws),
    .data_in(pmodb_dout),
    .bclk_out(pmodb_bclk),
    .sample_out(mic_sample),
    .valid_out(mic_sample_valid)
  );

  //logic signed [23:0] mic_sample_thresholded;
  //assign mic_sample_thresholded = mic_sample > (1<<18) ? mic_sample : (mic_sample < -(1<<18) ? mic_sample : 0);

  // We're going to run the filterbank at 98.3MHz / 2 = 48kHz * 1024
  // Our pipelined filterbank and mixer takes a variable number of cycles:
  // - filterbank: N_FILTERS * (30 cycles / filter) * 3 filter stages (modulator, env, carrier)
  // - mixed: N_FILTERS * 3 arithmetic stages (mult, shift, add)
  // So we need ~(N_FILTERS * 35) clock cycles at least

  //logic clk_fb;
  // always_ff @(posedge clk_98_3mhz) begin
  //   clk_fb <= clk_fb + 1;
  // end

  // logic signed [31:0] carrier_channels  [N_FILTERS-1:0];
  // logic signed [31:0] envelope_channels [N_FILTERS-1:0];
  // logic filtered_valid;
  // filterbank fb(
  //   .clk_in(clk_fb),
  //   .rst_in(sys_rst),
  //   .valid_in(mic_sample_valid),
  //   .carrier_sample_in(carrier),
  //   .modulator_sample_in(mic_sample),
  //   .carrier_out(carrier_channels),
  //   .envelope_out(envelope_channels),
  //   .valid_out(filtered_valid)
  // );

  // logic mixed_valid;
  // logic [23:0] mixed;
  // mixer mix(
  //   .clk_in(clk_fb),
  //   .rst_in(sys_rst),
  //   .valid_in(filtered_valid),
  //   .carrier_channels(carrier_channels),
  //   .envelope_channels(envelope_channels),
  //   .mixed_out(mixed),
  //   .valid_out(mixed_valid),
  //   .shift(sw[15:11])
  // );

  logic signed [SYNTH_WIDTH-1:0] synth_adsr;
  assign synth_adsr = (synth_out * midi_vol) >>> 8;


  // I2S2, generates an internal SCLK at 48 = 24 bits * 2 channels times
  // the sampling rate by running LRCK = 192kHz and MCLK = 96 * LRCK
  logic lin_valid;
  
  pmod_i2s2 iface(
    .clk_in(clk_i2s),
    //.valid_in(mixed_valid),
    //.sample_in(mixed << 2),
    .valid_in(clk_synth),
    .sample_in(synth_adsr),

    .lout_mclk_out(pmoda_lout_mclk),
    .lout_lrck_out(pmoda_lout_lrck),
    .lout_sclk_out(pmoda_lout_sclk),
    .lout_sdin_out(pmoda_lout_sdin),

    .lin_sdout_in(pmoda_lin_sdout),
    .lin_mclk_out(pmoda_lin_mclk),
    .lin_lrck_out(pmoda_lin_lrck),
    .lin_sclk_out(pmoda_lin_sclk),
    .sample_out(lin_out),
    .valid_out(lin_valid)
  );

  // manta m(
  //   .clk(clk_98_3mhz),
  //   .rx(uart_rxd),
  //   .tx(uart_txd),
  //   .mic_level($signed(mic_sample)),
  //   .filtered(filtered[31:0]),
  //   .temp1(temp1),
  //   .temp2(temp2),
  //   .temp3(temp3),
  //   .temp4(temp4),
  //   .temp5(temp5)
  // );

  // PDM clocked at 98.3MHz / 8 = 48kHz * 256 = 12.3MHz
  // for 256-times downsampling
  // logic [$clog2(PDM_CYCLES)-1:0] clk_pdm_count;
  // logic clk_pdm;
  // assign clk_pdm = clk_pdm_count[$clog2(PDM_CYCLES)-1] == 0;
  // always_ff @(posedge clk_98_3mhz) begin
  //   clk_pdm_count <= clk_pdm_count + 1;
  // end

  // logic [23:0] s;
  // always_ff @(posedge clk_98_3mhz) begin
  //   if (mic_sample_valid) s <= mic_sample;
  // end

  // // delta-sigma modulator for DAC
  // logic audio_out;
  // pdm #(.WIDTH(18)) p(
  //   .clk_in(clk_pdm_count),
  //   .rst_in(sys_rst),
  //   .data_in(mic_sample[17:0]),
  //   .data_out(audio_out)
  // );

  // assign spkl = audio_out;
  // assign spkr = audio_out;

  logic [6:0] ss_c;
  seven_segment_controller mssc(
    .clk_in(clk_98_3mhz),
    .rst_in(sys_rst),
    .val_in(synth_out),
    .cat_out(ss_c),
    .an_out({ss0_an, ss1_an})
  );
  assign ss0_c = ss_c;
  assign ss1_c = ss_c;


endmodule

`default_nettype wire

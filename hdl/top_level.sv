`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire          clk_100mhz,
  input wire [3:0]    btn,
  input wire          usb_int,
  input wire          usb_miso,
  input wire          uart_rxd,
  input wire [15:0]   sw,
  output logic        usb_n_rst,
  output logic        usb_n_ss,
  output logic        usb_mosi,
  output logic        usb_clk,
  output logic [15:0] led,
  output logic [7:0]  pmoda,
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

  logic [SYNTH_PHASE_ACC_BITS-1:0] phase_acc;
  switch_keyboard keyboard(
    .sw_in(sw[15:3]),
    .phase_acc_out(phase_acc)
  );

  logic signed [SYNTH_WIDTH-1:0] synth_out;
  synthesizer synth(
    .clk_in(clk_synth),
    .rst_in(sys_rst),
    .phase_incr_in(phase_acc),
    .wave_type_in(sw[2:0]),
    .synth_out(synth_out)
  );

  // // PDM clocked at 98.3MHz / 8 = 48kHz * 256 = 12.3MHz
  // // for 256-times downsampling
  // logic [$clog2(PDM_CYCLES)-1:0] clk_pdm_count;
  // logic clk_pdm;
  // assign clk_pdm = clk_pdm_count[$clog2(PDM_CYCLES)-1] == 0;
  // always_ff @(posedge clk_98_3mhz) begin
  //   clk_pdm_count <= clk_pdm_count + 1;
  // end

  // // delta-sigma modulator for DAC
  // logic audio_out;
  // pdm #(.WIDTH(SYNTH_WIDTH)) p(
  //   .clk_in(clk_pdm_count),
  //   .rst_in(sys_rst),
  //   .data_in(synth_out),
  //   .data_out(audio_out)
  // );

  // assign spkl = audio_out;
  // assign spkr = audio_out;

  // I2S2, generates an internal SCLK at 48 = 24 bits * 2 channels times
  // the sampling rate by running LRCK = 192kHz and MCLK = 96 * LRCK
  pmod_i2s2 iface(
    .clk_in(clk_i2s),
    .sample_in(synth_out),
    .mclk_out(pmoda[0]),
    .lrck_out(pmoda[1]),
    .sclk_out(pmoda[2]),
    .sdin_out(pmoda[3])
  );

endmodule

`default_nettype wire

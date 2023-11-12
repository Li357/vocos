`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire          clk_100mhz,
  input wire [3:0]    btn,
  input wire          usb_int,
  input wire          usb_miso,
  input wire          uart_rxd,
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

  logic clk_98_3mhz;
  audio_clk_wiz wiz (.clk_in(clk_100mhz), .clk_out(clk_98_3mhz));

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

  assign pmoda[0] = usb_miso;
  assign pmoda[1] = usb_mosi;
  assign pmoda[2] = usb_clk;
  assign pmoda[3] = usb_n_ss;
  assign pmoda[4] = usb_int;

  logic [15:0] out;
  logic [31:0] midi_out;

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

  logic [6:0] ss_c;

  seven_segment_controller mssc(
    .clk_in(clk_98_3mhz),
    .rst_in(sys_rst),
    .val_in(midi_out),
    .cat_out(ss_c),
    .an_out({ss0_an, ss1_an})
  );
  assign ss0_c = ss_c;
  assign ss1_c = ss_c;

  assign led[15:0] = out;

  localparam PHASE_INCR = 32'b0100101100011000;

  logic pdm_tick;
  logic [10:0] pdm_count;
  assign pdm_tick = pdm_count[10] == 0;
  always_ff @(posedge clk_98_3mhz) begin
    pdm_count <= pdm_count + 1;
  end

  logic signed [10:0] synth_out;
  synthesizer synth(
    .clk_in(clk_98_3mhz),
    .rst_in(sys_rst),
    .phase_incr_in(PHASE_INCR),
    .audio_out(synth_out)
  );

  // delta-sigma modulator for DAC
  logic audio_out;
  pdm #(.WIDTH(11)) p(
    .clk_in(clk_98_3mhz),
    .rst_in(sys_rst),
    .data_in(synth_out),
    .data_out(audio_out)
  );

  assign spkl = audio_out;
  assign spkr = audio_out;
endmodule

`default_nettype wire

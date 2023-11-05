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
  output logic        uart_txd
);

  logic sys_rst;
  assign sys_rst = btn[0];

  // the onboard MAX3421E USB chip can be clocked up to 26MHz
  // this is around 3MHz
  logic clk_25mhz;
  logic [5:0] clk_25mhz_count;
  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) clk_25mhz_count <= 0;
    else begin
      if (clk_25mhz_count == 15) clk_25mhz <= ~clk_25mhz;
      clk_25mhz_count <= clk_25mhz_count + 1;
    end
  end

  assign pmoda[0] = usb_miso;
  assign pmoda[1] = usb_mosi;
  assign pmoda[2] = usb_clk;
  assign pmoda[3] = usb_n_ss;
  assign pmoda[4] = usb_int;

  logic [7:0] out;

  usb_controller usbc(
    .clk_in(clk_25mhz),
    .rst_in(sys_rst),
    .int_in(usb_int),
    .miso_in(usb_miso),
    .n_rst_out(usb_n_rst),
    .n_ss_out(usb_n_ss),
    .mosi_out(usb_mosi),
    .clk_out(usb_clk),
    .byte_out(out)
  );

  assign led[7:0] = out;
endmodule

`default_nettype wire

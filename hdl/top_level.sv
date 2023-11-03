`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire          clk_100mhz,
  input wire [3:0]    btn,
  input wire          usb_int,
  input wire          usb_miso,
  output logic        usb_rst,
  output logic        usb_ss,
  output logic        usb_mosi,
  output logic        usb_clk,
  output logic [15:0] led,
  output logic [7:0]  pmoda
);

  logic sys_rst;
  assign sys_rst = btn[0];

  // the onboard MAX3421E USB chip can be clocked up to 26MHz
  // so we'll use a 25MHz clock here
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
  assign pmoda[3] = usb_ss;
  assign pmoda[4] = usb_int;

  logic [15:0] out;

  usb_controller usbc(
    .clk_in(clk_25mhz),
    .rst_in(sys_rst),
    .int_in(usb_int),
    .miso_in(usb_miso),
    .rst_out(usb_rst),
    .ss_out(usb_ss),
    .mosi_out(usb_mosi),
    .clk_out(usb_clk),
    .bytes_out(out)
  );

  assign led[15:0] = out;
endmodule

`default_nettype wire

`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire [3:0] btn,
  input wire usb_int,
  input wire usb_miso,
  output logic usb_rst,
  output logic usb_ss,
  output logic usb_mosi,
  output logic usb_clk,
  output logic [15:0] led
);
  logic sys_rst;
  assign sys_rst = btn[0];
  assign usb_rst = btn[0];

  logic clk_25mhz;
  logic [1:0] clk_25mhz_count;
  assign clk_25mhz = clk_25mhz_count == 0;
  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) clk_25mhz_count <= 0;
    else clk_25mhz_count <= (clk_25mhz_count == 3 ? 0 : clk_25mhz_count + 1);
  end
  assign usb_clk = clk_25mhz;

  logic [1:0] state;

  logic [15:0] msg;
  assign msg = 16'b1010_0010_0000_0001;

  logic [4:0] sent_index;
  assign led[0] = sent_index == 0;

  always_ff @(posedge usb_clk) begin
    if (sys_rst) begin
      state <= 0;
      sent_index <= 15;
    end else begin
      case (state)
        0: begin
          usb_ss <= 0;
          usb_mosi <= msg[sent_index];
          if (sent_index == 0) begin
            usb_ss <= 1;
            state <= 1;
          end else begin
            sent_index <= sent_index - 1;
          end
        end
      endcase
    end
  end
endmodule

`default_nettype wire

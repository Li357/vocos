`timescale 1ns / 1ps
`default_nettype none

module max3421_spi(
  input wire clk_in,
  input wire rst_in,
  input wire miso_in,
  input wire [7:0] bytes_in [63:0],
  input wire [6:0] bytes_in_count,
  input wire valid_in,
  output logic n_ss_out,
  output logic mosi_out,
  output logic clk_out,
  output logic valid_out,
  output logic [7:0] bytes_out [63:0],
  output logic [6:0] byte_count,
  output logic finished_out
);
  // the max3421 can be driven up to 26MHz, and needs >=200ns between commands
  localparam HOLD_CYCLES = 5;

  typedef enum {WAITING, TXING, HOLDING} state_t;
  state_t state;

  logic [2:0] hold_count;
  logic [3:0] byte_index;
  logic clk_on;
  assign clk_out = clk_on ? clk_in : 0;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= WAITING;
      byte_index <= 0;
      clk_on <= 0;
      n_ss_out <= 1;
      valid_out <= 0;
      byte_count <= 0;
      finished_out <= 0;
    end else begin
      if (valid_out) valid_out <= 0;
  
      case (state)
        WAITING: begin
          finished_out <= 0;
          if (valid_in) begin
            state <= TXING;
            byte_index <= 0;
            clk_on <= 0;
            n_ss_out <= 0;
            byte_count <= 0;
          end
        end
        TXING: begin
          // The MAX3421 allows for full-duplex more where
          // if we're performing a WRITE:
          // - MOSI: first byte is register, write bit
          //         subsequent bytes are written to current register
          //         or subsequent registers depending on register freeze
          // - MISO: first byte is 8 USB interrupt status bits
          //         subsequent bytes are old contents from register written
          //
          // For READS:
          // - MOSI: first byte is register, read bit, subsequent don't case
          // - MISO: first byte is 8 status bits
          //         subsequent bytes are from current register if it's a FIFO
          //         or reads from subsequent registers depending on register freeze

          if (byte_count == bytes_in_count) begin
            state <= HOLDING;
            // Here we can stop the clock and drive nSS high at the same time
            // because we need 40ns from the *leading* edge of the clock, not
            // trailing edge
            clk_on <= 0;
            n_ss_out <= 1;
            hold_count <= 0;
            byte_count <= 0;
          end else begin
            // We don't start the clock until one cycle after nSS goes low
            // since we require 40ns lead time
            clk_on <= 1;
            bytes_out[byte_count][7 - byte_index] <= miso_in;
            if (byte_index == 7) begin
              byte_index <= 0;
              valid_out <= 1;
              byte_count <= byte_count + 1;
            end else byte_index <= byte_index + 1;
          end
        end
        HOLDING: begin
          if (hold_count == HOLD_CYCLES) begin
            state <= WAITING;
            finished_out <= 1;
          end else hold_count <= hold_count + 1;
        end
      endcase
    end
  end

  // IMPORTANT: outputs on MISO and inputs on MOSI need to be
  // changed on the negative edge of the clock to allow for enough
  // time to correctly sample the value on the clk_out edge
  always_ff @(negedge clk_in) begin
    if (rst_in) begin
      mosi_out <= 0;
    end else if (state == TXING) begin
      mosi_out <= bytes_in[byte_count][byte_index];
    end
  end
endmodule

`default_nettype wire
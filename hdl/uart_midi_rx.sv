// `timescale 1ns / 1ps
// `default_nettype none

// module uart_rx
//   import constants::*;
// (
//   input wire clk_in,
//   input wire rst_in,

//   input wire rx_in,

//   output logic valid_out,
//   output logic [31:0] midi_out
// );

//   typedef enum { WAITING, PREAMBLE, RXING } state_t;
//   state_t state;

//   logic [5:0] count;
//   logic [4:0] index;

//   always_ff @(posedge clk_in) begin
//     if (rst_in) begin
//       state <= WAITING;
//       index <= 0;
//       midi_out <= 0;
//       count <= 0;
//     end else begin
//       case (state)
//         WAITING: begin
//           valid_out <= 0;
//           if (!rx_in) begin
//             state <= PREAMBLE;
//             count <= 0;
//           end
//         end
//         PREAMBLE: begin
//           if (count == CLOCKS_PER_BAUD + CLOCKS_PER_BAUD / 2) begin
//             state <= RXING;
//             count <= CLOCKS_PER_BAUD - 1;
//           end else count <= count + 1;
//         end
//         RXING: begin
//           if (index == 8) begin
//             state <= WAITING;
//             index <= 0;
//             valid_out <= 1;
//           end else if (count == CLOCKS_PER_BAUD - 1) begin
//             count <= 0;
//             index <= index + 1;
//             midi_out[index] <= rx_in;
//           end else count <= count + 1;
//         end
//       endcase
//     end
//   end

// endmodule
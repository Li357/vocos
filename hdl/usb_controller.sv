`timescale 1ns / 1ps
`default_nettype none

function [15:0] flip16(input [15:0] data);
  for (int i = 0; i < 16; i = i + 1) begin
    flip16[15 - i] = data[i];
  end
endfunction

function [7:0] flip8(input [7:0] data);
  for (int i = 0; i < 8; i = i + 1) begin
    flip8[7 - i] = data[i];
  end
endfunction

module max3421_write(
  input wire clk_in,
  input wire rst_in,
  input wire [15:0] msg_in,
  input wire valid_in,
  output logic n_ss_out,
  output logic mosi_out,
  output logic clk_out,
  output logic done_out
);
  localparam HOLD_CYCLES = 5; // the max3421 can be driven up to 26MHz, and needs >=200ns between commands

  typedef enum {WRITING, HOLDING, WAITING} state_t;
  state_t state;

  logic [2:0] hold_count;
  logic [4:0] msg_index;
  logic clk_on;
  assign clk_out = clk_on ? clk_in : 0;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= WAITING;
      done_out <= 0;
      n_ss_out <= 1;
      clk_on <= 0;
      msg_index <= 0;
    end else begin
      case (state)
        WAITING: begin
          done_out <= 0;
          if (valid_in && !done_out) begin
            state <= WRITING;
            msg_index <= 0;
            clk_on <= 0;
            n_ss_out <= 0;
          end
        end
        WRITING: begin
          if (msg_index == 16) begin
            state <= HOLDING;
            clk_on <= 0;
            n_ss_out <= 1;
          end else begin
            clk_on <= 1;
            msg_index <= msg_index + 1;
          end
        end
        HOLDING: begin
          if (hold_count == HOLD_CYCLES) begin
            done_out <= 1;
            state <= WAITING;
          end else hold_count <= hold_count + 1;
        end
      endcase
    end
  end

  always_ff @(negedge clk_in) begin
    if (rst_in) begin
      mosi_out <= 0;
    end else if (state == WRITING) begin
      mosi_out <= msg_in[msg_index];
    end
  end
endmodule

// module max3421_read(
//   input wire clk_in,
//   input wire rst_in,
//   input wire mosi_in,
//   input wire [8:0] msg_in,
//   input wire valid_in,
//   output logic n_ss_out,
//   output logic mosi_out,
//   output logic clk_out,
//   output logic valid_out,
//   output logic [7:0]
// );
//   typedef enum {WRITING, READING, WAITING} state_t;
//   state_t state; 

//   logic [3:0] msg_index;
//   logic clk_on;
//   assign clk_out = clk_on ? clk_in : 0;

//   always_ff @(posedge clk_in) begin
//     if (rst_in) begin
//       state <= WAITING;
//     end else begin
//       case (state)
//         WAITING: begin
//           if (valid_in) begin
//             state <= WRITING;
//             msg_index <= 0;
//             clk_on <= 0;
//             n_ss_out <= 0;
//           end
//         end
//         WRITING: begin
//           if (msg_index == 16) begin
//             state <= WAITING;
//             clk_on <= 0;
//             n_ss_out <= 1;
//           end else begin
//             clk_on <= 1;
//             msg_index <= msg_index + 1;
//             mosi_out <= msg_in[msg_index];
//           end
//         end
//       endcase
//     end
//   end
// module

module usb_controller(
  input wire   clk_in,
  input wire   rst_in,
  input wire   int_in,
  input wire   miso_in,
  output logic rst_out,
  output logic ss_out,
  output logic mosi_out,
  output logic clk_out,
  output logic [15:0] bytes_out
);

  // Based off of https://github.com/calvinlclee3/fpga_soc/blob/master/software/text_mode_vga/usb_kb/MAX3421E.c

  typedef enum {
    INIT,
    INIT_SET_FULLDUPLEX,
    INIT_SET_FULLDUPLEX_FINISH,
    INIT_SET_POWER,
    INIT_SET_POWER_FINISH,
    INIT_SET_HOSTMODE,
    INIT_SET_HOSTMODE_FINISH,
    INIT_SET_CONNDETECT,
    INIT_SET_CONNDETECT_FINISH,
    INIT_SET_SAMPLEBUS,
    INIT_SET_SAMPLEBUS_FINISH,
    READ_RCV_FIFO,
    READ_RCV_FIFO_FINISH,
    WAITING
  } state_t;
  state_t state;

  // the MAX3421E expects MSB first
  localparam FULLDUPLEX_MSG     = flip16({5'd17, 3'b010, 8'b00011010});
  localparam POWER_MSG          = flip16({5'd20, 3'b010, 8'b00000001});
  localparam HOSTMODE_MSG       = flip16({5'd27, 3'b010, 8'b11010001});
  localparam CONNDETECT_MSG     = flip16({5'd26, 3'b010, 8'b00100000});
  localparam SAMPLEBUS_MSG      = flip16({5'd29, 3'b010, 8'b00000100});
  localparam READ_RCV_FIFO_MSG  = flip8({5'd1, 3'b000});

  logic [15:0] msg;
  logic [15:0] msg_index;
  logic [31:0] wait_count;
  logic clk_on;

  logic writing;
  logic writer_done;
  logic writer_clk;
  logic writer_mosi;
  logic writer_n_ss;

  max3421_write writer(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .msg_in(msg),
    .valid_in(writing),
    .n_ss_out(writer_n_ss),
    .mosi_out(writer_mosi),
    .clk_out(writer_clk),
    .done_out(writer_done)
  );

  assign clk_out = writing ? writer_clk : 0;
  assign mosi_out = writing ? writer_mosi : 0;
  assign ss_out = writing ? writer_n_ss : 1;

  always_comb begin
    case (state)
      INIT_SET_FULLDUPLEX: msg = FULLDUPLEX_MSG;
      INIT_SET_POWER:      msg = POWER_MSG;
      INIT_SET_CONNDETECT: msg = CONNDETECT_MSG;
      INIT_SET_HOSTMODE:   msg = HOSTMODE_MSG;
      INIT_SET_SAMPLEBUS:  msg = SAMPLEBUS_MSG;
      default:             msg = 16'b0;
    endcase
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= INIT;
      writing <= 0;
      rst_out <= 0;
    end else begin
      case (state)
        INIT: begin
          rst_out <= 1;
          wait_count <= 0;
          state <= INIT_SET_FULLDUPLEX;
          writing <= 1;
        end

        // Step 1: set full-duplex mode, interrupt level and GPXB for bus activity
        INIT_SET_FULLDUPLEX: begin
          if (writer_done) begin
            state <= INIT_SET_POWER;
          end
        end

        // Step 2: set GPOUT0 which is connected to PRT_CTL and enables USB 5V
        INIT_SET_POWER: begin
          if (writer_done) begin
            state <= INIT_SET_HOSTMODE;
          end
        end

        // Step 3: set HOST mode bit, pulldowns, GPIN IRQ on GPX
        INIT_SET_HOSTMODE: begin
          if (writer_done) begin
            state <= INIT_SET_CONNDETECT;
          end
        end

        // Step 4: set connection detection
        INIT_SET_CONNDETECT: begin
          if (writer_done) begin
            state <= INIT_SET_SAMPLEBUS;
          end
        end

        // Step 5: set JSTATUS and KSTATUS bits
        INIT_SET_SAMPLEBUS: begin
          if (writer_done) begin
            state <= WAITING;
          end
        end
        

        // // Step 6: read the receive buffer
        // READ_RCV_FIFO: begin
        //   if (msg_index == 8 + 2 * 8) begin
        //     state <= READ_RCV_FIFO_FINISH;
        //     clk_on <= 0;
        //     ss_out <= 1;
        //   end else if (msg_index < 8) begin
        //     clk_on <= 1;
        //     mosi_out <= msg[msg_index];
        //   end else begin
        //     bytes_out[msg_index - 8] <= miso_in;
        //   end
        //   msg_index <= msg_index + 1;
        // end

        // READ_RCV_FIFO_FINISH: begin
        //   if (wait_count == 500000) begin
        //     state <= READ_RCV_FIFO;
        //     ss_out <= 0;
        //     msg_index <= 0;
        //     wait_count <= 0;
        //   end else begin
        //     wait_count <= wait_count + 1;
        //   end
        // end

        WAITING: begin

        end
      endcase
    end
  end

endmodule

`default_nettype wire
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

// module max3421_write(
//   input wire clk_in,
//   input wire rst_in,
//   input wire [15:0] msg,
//   output logic ss_out,
//   output logic mosi_out
// );

//   logic [3:0] msg_index;



// endmodule

// module max3421_read()

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

  always_comb begin
    case (state)
      INIT_SET_FULLDUPLEX: msg = FULLDUPLEX_MSG;
      INIT_SET_POWER:      msg = POWER_MSG;
      INIT_SET_CONNDETECT: msg = CONNDETECT_MSG;
      INIT_SET_HOSTMODE:   msg = HOSTMODE_MSG;
      INIT_SET_SAMPLEBUS:  msg = SAMPLEBUS_MSG;
      READ_RCV_FIFO:       msg = READ_RCV_FIFO_MSG;
      default:             msg = 16'b0;
    endcase
  end
  assign clk_out = clk_on ? clk_in : 0;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= INIT;
      ss_out <= 1;
      msg_index <= 0;
      mosi_out <= 0;
      rst_out <= 0;
      clk_on <= 0;
    end else begin
      case (state)
        INIT: begin
          rst_out <= 1;
          ss_out <= 0;
          state <= INIT_SET_POWER;
          msg_index <= 0;
          wait_count <= 0;
        end

        // Step 1: set GPOUT0 which is connected to PRT_CTL and enables USB 5V
        INIT_SET_POWER: begin
          if (msg_index == 16) begin
            state <= INIT_SET_POWER_FINISH;
            clk_on <= 0;
            ss_out <= 1;
          end else begin
            clk_on <= 1;
            msg_index <= msg_index + 1;
            mosi_out <= msg[msg_index];
          end
        end

        INIT_SET_POWER_FINISH: begin
          // we need at least 200ns of time between commands
          if (wait_count == 100) begin
            state <= INIT;
            ss_out <= 0;
            msg_index <= 0;
            wait_count <= 0;
          end else begin
            wait_count <= wait_count + 1;
          end
        end

        // Step 2: set full-duplex mode, interrupt level and GPXB for bus activity
        INIT_SET_FULLDUPLEX: begin
          if (msg_index == 16) begin
            state <= INIT_SET_FULLDUPLEX_FINISH;
            clk_on <= 0;
            ss_out <= 1;
          end else begin
            clk_on <= 1;
            msg_index <= msg_index + 1;
            mosi_out <= msg[msg_index];
          end
        end

        INIT_SET_FULLDUPLEX_FINISH: begin
          if (wait_count == 100) begin
            state <= INIT_SET_HOSTMODE;
            ss_out <= 0;
            msg_index <= 0;
            wait_count <= 0;
          end else begin
            wait_count <= wait_count + 1;
          end
        end

        // // READ_FDUP: begin
        // //   if (msg_index == 16) begin
        // //     clk_on <= 0;
        // //     ss_out <= 1;
        // //     state <= READ_FDUP_F;
        // //   end else if (msg_index < 8) begin
        // //     clk_on <= 1;
        // //     mosi_out <= msg[msg_index];
        // //   end
        // //   msg_index <= msg_index + 1;
        // // end

        // // READ_FDUP_F: begin
        // //   // if (wait_count == 9) begin
        // //   //   ss_out <= 0;
        // //   // end
        // //   // if (wait_count == 10) begin
        // //   //   clk_on <= 1;
        // //   // end
        // //   // if (wait_count == 18) begin
        // //   //   clk_on <= 0;
        // //   //   ss_out <= 1;
        // //   // end
        // //   if (wait_count == 100) begin
        // //     ss_out <= 0;
        // //     msg_index <= 0;
        // //     state <= INIT_SET_FULLDUPLEX;
        // //     wait_count <= 0;
        // //   end else wait_count <= wait_count + 1;
        // end

        // Step 3: set HOST mode bit, pulldowns, GPIN IRQ on GPX
        INIT_SET_HOSTMODE: begin
          if (msg_index == 16) begin
            state <= INIT_SET_HOSTMODE_FINISH;
            clk_on <= 0;
            ss_out <= 1;
          end else begin
            clk_on <= 1;
            msg_index <= msg_index + 1;
            mosi_out <= msg[msg_index];
          end
        end

        INIT_SET_HOSTMODE_FINISH: begin
          if (wait_count == 100) begin
            state <= INIT_SET_CONNDETECT;
            ss_out <= 0;
            wait_count <= 0;
            msg_index <= 0;
          end else begin
            wait_count <= wait_count + 1;
          end
        end

        // Step 4: set connection detection
        INIT_SET_CONNDETECT: begin
          if (msg_index == 16) begin
            state <= INIT_SET_CONNDETECT_FINISH;
            clk_on <= 0;
            ss_out <= 1;
          end else begin
            clk_on <= 1;
            msg_index <= msg_index + 1;
            mosi_out <= msg[msg_index];
          end
        end

        INIT_SET_CONNDETECT_FINISH: begin
          if (wait_count == 100) begin
            state <= INIT_SET_SAMPLEBUS;
            ss_out <= 0;
            msg_index <= 0;
            wait_count <= 0;
          end else begin
            wait_count <= wait_count + 1;
          end
        end

        // Step 5: set JSTATUS and KSTATUS bits
        INIT_SET_SAMPLEBUS: begin
          if (msg_index == 16) begin
            state <= INIT_SET_SAMPLEBUS_FINISH;
            clk_on <= 0;
            ss_out <= 1;
          end else begin
            clk_on <= 1;
            msg_index <= msg_index + 1;
            mosi_out <= msg[msg_index];
          end
        end
        
        INIT_SET_SAMPLEBUS_FINISH: begin
          if (wait_count == 100) begin
            state <= READ_RCV_FIFO;
            ss_out <= 0;
            msg_index <= 0;
            wait_count <= 0;
          end else begin
            wait_count <= wait_count + 1;
          end
        end

        // Step 6: read the receive buffer
        READ_RCV_FIFO: begin
          if (msg_index == 8 + 2 * 8) begin
            state <= READ_RCV_FIFO_FINISH;
            clk_on <= 0;
            ss_out <= 1;
          end else if (msg_index < 8) begin
            clk_on <= 1;
            mosi_out <= msg[msg_index];
          end else begin
            bytes_out[msg_index - 8] <= miso_in;
          end
          msg_index <= msg_index + 1;
        end

        READ_RCV_FIFO_FINISH: begin
          if (wait_count == 500000) begin
            state <= READ_RCV_FIFO;
            ss_out <= 0;
            msg_index <= 0;
            wait_count <= 0;
          end else begin
            wait_count <= wait_count + 1;
          end
        end

        WAITING: begin

        end
      endcase
    end
  end

endmodule

`default_nettype wire
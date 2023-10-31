`timescale 1ns / 1ps
`default_nettype none

module usb_controller(
  input wire   clk_in,
  input wire   rst_in,
  input wire   int_in,
  input wire   miso_in,
  output logic rst_out,
  output logic ss_out,
  output logic mosi_out,
  output logic clk_out,
  output logic [7:0] byte_out
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
    WAITING,
    NOOP
  } state_t;
  state_t state;

  // the MAX3421E expects MSB first
  localparam logic [15:0] FULLDUPLEX_MSG = 16'b01011000_010_10001;
  localparam logic [15:0] POWER_MSG      = 16'b10000000_010_00101;  
  localparam logic [15:0] HOSTMODE_MSG   = 16'b10001011_010_11011;
  localparam logic [15:0] CONNDETECT_MSG = 16'b00000100_010_01011;
  localparam logic [15:0] SAMPLEBUS_MSG  = 16'b00000011_010_11111;

  logic [15:0] msg;
  logic [4:0] msg_index;
  logic [10:0] wait_count;
  logic [3:0] init_count;

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
  assign clk_out = msg_index >= 1 ? clk_in : 0;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= INIT;
      ss_out <= 1;
      msg_index <= 0;
      mosi_out <= 0;
      rst_out <= 1;
      init_count <= 0;
    end else begin
      case (state)
        // Step 1: set full-duplex mode, interrupt level and GPXB for bus activity
        INIT: begin
          rst_out <= 0;
          ss_out <= 0;
          state <= INIT_SET_POWER;
          msg_index <= 0;
          wait_count <= 0;
        end

        INIT_SET_FULLDUPLEX: begin
          if (msg_index == 16) begin
            state <= INIT_SET_FULLDUPLEX_FINISH;
            msg_index <= 1;
          end else begin
            msg_index <= msg_index + 1;
            mosi_out <= msg[msg_index];
          end
        end

        INIT_SET_FULLDUPLEX_FINISH: begin
          msg_index <= 0;
          // We need at least 200ns between commands
          if (wait_count == 10) begin
            state <= INIT_SET_POWER;
            wait_count <= 0;
            ss_out <= 0;
          end else begin
            wait_count <= wait_count + 1;
            ss_out <= 1;
          end
        end

        // Step 2: set GPOUT0 which is connected to PRT_CTL and enables USB 5V
        INIT_SET_POWER: begin
          if (msg_index == 16) begin
            state <= INIT_SET_POWER_FINISH;
            msg_index <= 1;
          end else begin
            msg_index <= msg_index + 1;
            mosi_out <= msg[msg_index];
          end
        end

        INIT_SET_POWER_FINISH: begin
          if (wait_count < 8)
            byte_out[wait_count] <= miso_in;
          else begin
            msg_index <= 0;
            ss_out <= 1;
          end
          if (wait_count == 100) begin
            state <= INIT;
            wait_count <= 0;
            init_count <= init_count + 1;
          end else begin
            wait_count <= wait_count + 1;
          end
        end

        // Step 3: set HOST mode bit, pulldowns, GPIN IRQ on GPX
        // INIT_SET_HOSTMODE: begin
        //   if (msg_index == 16) begin
        //     state <= INIT_SET_HOSTMODE_FINISH;
        //     msg_index <= 1;
        //   end else begin
        //     msg_index <= msg_index + 1;
        //     mosi_out <= msg[msg_index];
        //   end
        // end

        // INIT_SET_HOSTMODE_FINISH: begin
        //   msg_index <= 0;
        //   if (wait_count == 10) begin
        //     state <= INIT_SET_CONNDETECT;
        //     wait_count <= 0;
        //     ss_out <= 0;
        //   end else begin
        //     ss_out <= 1;
        //     wait_count <= wait_count + 1;
        //   end
        // end

        // Step 4: set connection detection
        // INIT_SET_CONNDETECT: begin
        //   if (msg_index == 16) begin
        //     state <= INIT_SET_CONNDETECT_FINISH;
        //     msg_index <= 1;
        //   end else begin
        //     msg_index <= msg_index + 1;
        //     mosi_out <= msg[msg_index];
        //   end
        // end

        // INIT_SET_CONNDETECT_FINISH: begin
        //   msg_index <= 0;
        //   if (wait_count == 10) begin
        //     state <= INIT_SET_SAMPLEBUS;
        //     wait_count <= 0;
        //     ss_out <= 0;
        //   end else begin
        //     ss_out <= 1;
        //     wait_count <= wait_count + 1;
        //   end
        // end

        // Step 5: set JSTATUS and KSTATUS bits
        // INIT_SET_SAMPLEBUS: begin
        //   if (msg_index == 16) begin
        //     state <= INIT_SET_SAMPLEBUS_FINISH;
        //     msg_index <= 1;
        //   end else begin
        //     msg_index <= msg_index + 1;
        //     mosi_out <= msg[msg_index];
        //   end
        // end
        
        // INIT_SET_SAMPLEBUS_FINISH: begin
        //   msg_index <= 0;
        //   if (wait_count == 10) begin
        //     state <= WAITING;
        //     wait_count <= 0;
        //   end else begin
        //     ss_out <= 1;
        //     wait_count <= wait_count + 1;
        //   end
        // end

        WAITING: begin
          if (wait_count < 8)
            byte_out[wait_count] <= miso_in;
          else begin
            msg_index <= 0;
            ss_out <= 1;
          end
          if (wait_count == 100) begin
            state <= INIT;
            wait_count <= 0;
            init_count <= init_count + 1;
          end else begin
            wait_count <= wait_count + 1;
          end
        end
      endcase
    end
  end

endmodule

`default_nettype wire
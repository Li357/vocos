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

module usb_controller(
  input wire   clk_in,
  input wire   rst_in,
  input wire   int_in,
  input wire   miso_in,
  output logic n_rst_out,
  output logic n_ss_out,
  output logic mosi_out,
  output logic clk_out,
  output logic [7:0] byte_out
);

  // Based off of https://github.com/calvinlclee3/fpga_soc/blob/master/software/text_mode_vga/usb_kb/MAX3421E.c

  typedef enum {
    INIT,
    INIT_SET_FULLDUPLEX,
    INIT_SET_POWER,
    INIT_SET_HOSTMODE,
    INIT_SET_CONNDETECT,
    INIT_SET_SAMPLEBUS,

    READ_JK,

    WAITING
  } state_t;
  state_t state;

  // the MAX3421E expects MSB first
  localparam FULLDUPLEX_MSG     = flip16({5'd17, 3'b010, 8'b00011010});
  localparam POWER_MSG          = flip16({5'd20, 3'b010, 8'b00000001});
  localparam HOSTMODE_MSG       = flip16({5'd27, 3'b010, 8'b11010001});
  localparam CONNDETECT_MSG     = flip16({5'd26, 3'b010, 8'b00100000});
  localparam SAMPLEBUS_MSG      = flip16({5'd29, 3'b010, 8'b00000100});
  
  localparam READ_JK_MSG = flip8({5'd18, 3'b000});

  logic [15:0] write_msg;
  logic [7:0]  read_msg;

  logic writing;
  logic writer_done;
  logic writer_clk;
  logic writer_mosi;
  logic writer_n_ss;

  max3421_write writer(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .msg_in(write_msg),
    .valid_in(writing),
    .n_ss_out(writer_n_ss),
    .mosi_out(writer_mosi),
    .clk_out(writer_clk),
    .done_out(writer_done)
  );

  logic reading;
  logic reader_clk;
  logic reader_mosi;
  logic reader_n_ss;
  logic reader_valid;
  logic [7:0] reader_byte;

  max3421_read reader(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .miso_in(miso_in),
    .msg_in(read_msg),
    .valid_in(reading),
    .n_ss_out(reader_n_ss),
    .mosi_out(reader_mosi),
    .clk_out(reader_clk),
    .valid_out(reader_valid),
    .byte_out(reader_byte)
  );

  assign clk_out = writing ? writer_clk : (reading ? reader_clk : 0);
  assign mosi_out = writing ? writer_mosi : (reading ? reader_mosi : 0);
  assign n_ss_out = writing ? writer_n_ss : (reading ? reader_n_ss : 1);

  always_comb begin
    case (state)
      INIT_SET_FULLDUPLEX: write_msg = FULLDUPLEX_MSG;
      INIT_SET_POWER:      write_msg = POWER_MSG;
      INIT_SET_CONNDETECT: write_msg = CONNDETECT_MSG;
      INIT_SET_HOSTMODE:   write_msg = HOSTMODE_MSG;
      INIT_SET_SAMPLEBUS:  write_msg = SAMPLEBUS_MSG;
      default:             write_msg = 16'b0;
    endcase
  end

  always_comb begin
    case (state)
      READ_JK: read_msg = READ_JK_MSG;
      default: read_msg = 8'b0;
    endcase
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= INIT;
      n_rst_out <= 0;
    end else begin
      case (state)
        INIT: begin
          n_rst_out <= 1;
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
            writing <= 0;
            state <= READ_JK;
            reading <= 1;
          end
        end

        READ_JK: begin
          if (reader_valid) begin
            byte_out <= reader_byte;
            reading <= 0;
            state <= WAITING;
          end
        end

        WAITING: begin
          state <= READ_JK;
          reading <= 1;
        end
      endcase
    end
  end

endmodule

`default_nettype wire
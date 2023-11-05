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
    INIT_ENABLE_INTERRUPTS,

    SETUP_SET_PERADDR_SUDFIFO,
    SETUP_SET_PERADDR_HXFR,
    SETUP_SET_PERADDR_WAIT,
    SETUP_SET_PERADDR_READ,
    SETUP_SET_PERADDR_CLEAR,
    SETUP_SET_PERADDR_STATUS,
    SETUP_SET_PERADDR_FINISH,

    SETUP_SET_CONFIG_SUDFIFO,
    SETUP_SET_CONFIG_HXFR,
    SETUP_SET_CONFIG_WAIT,
    SETUP_SET_CONFIG_READ,
    SETUP_SET_CONFIG_CLEAR,
    SETUP_SET_CONFIG_STATUS,
    SETUP_SET_CONFIG_FINISH,

    POLL_BULK_IN_HXFR,

    POLL_BULK_IN,
    DEENCAPSULATE_MIDI,

    WAITING
  } state_t;
  state_t state;

  localparam READ  = 3'b000;
  localparam WRITE = 3'b010;

  // the MAX3421E expects MSB first so we'll flip the bits
  // PINCTL  FDUPSPI | POSINT
  localparam logic [7:0] FULLDUPLEX_MSG        [63:0] = '{0: flip8({5'd17, WRITE}), 1: flip8(8'b00010100), default: '0};
  // IOPINS1 GPOUT0
  localparam logic [7:0] POWER_MSG             [63:0] = '{0: flip8({5'd20, WRITE}), 1: flip8(8'b00000001), default: '0};
  // MODE    SEPIRQ | HOST
  localparam logic [7:0] HOSTMODE_MSG          [63:0] = '{0: flip8({5'd27, WRITE}), 1: flip8(8'b00010001), default: '0};
  // HIEN    HXFRDNIE | SNDBAVIE | RCVDAVIE
  localparam logic [7:0] ENABLE_INTERRUPTS_MSG [63:0] = '{0: flip8({5'd26, WRITE}), 1: flip8(8'b10001100), default: '0};
  // CPUCTL  IE
  // localparam ENABLE_INTERRUPT_PIN_MSG = flip16({5'd16, 3'b010, 8'b00000001});
  
  localparam logic [7:0] SET_PERADDR_SUDFIFO [63:0] = '{
    0: flip8({5'd2, WRITE}),
    1: 8'h00,
    2: flip8(8'h05),
    3: 8'h00, 4: flip8(8'h01),
    5: 8'h00, 6: 8'h00,
    7: 8'h00, 8: 8'h00,
    default: '0
  };
  localparam logic [7:0] SET_PERADDR_HXFR    [63:0] = '{0: flip8({5'd30, WRITE}), 1: flip8(8'b00010000), default: '0};
  localparam logic [7:0] SET_PERADDR_READ    [63:0] = '{0: flip8({5'd31, READ}), default: '0};
  localparam logic [7:0] SET_PERADDR_CLEAR   [63:0] = '{0: flip8({5'd25, WRITE}), 1: flip8(8'b10000000), default: '0};
  localparam logic [7:0] SET_PERADDR_STATUS  [63:0] = '{0: flip8({5'd30, WRITE}), 1: flip8(8'b10000000), default: '0};

  localparam logic [7:0] SET_CONFIG_SUDFIFO [63:0] = '{
    0: flip8({5'd2, WRITE}),
    1: 8'h00,
    2: flip8(8'h09),
    3: 8'h00, 4: flip8(8'h01),
    5: 8'h00, 6: 8'h00,
    7: 8'h00, 8: 8'h00,
    default: '0
  };

  logic txing;
  logic [7:0] tx_snd_bytes [63:0];
  logic [6:0] tx_snd_byte_count;
  logic tx_n_ss;
  logic tx_mosi;
  logic tx_clk;
  logic tx_rcv_byte_valid;
  logic [7:0] tx_rcv_bytes [63:0];
  logic [6:0] tx_byte_count;
  logic tx_finished;

  logic [7:0] wait_count;

  max3421_spi spi(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .miso_in(miso_in),
    .bytes_in(tx_snd_bytes),
    .bytes_in_count(tx_snd_byte_count),
    .valid_in(txing),
    .n_ss_out(tx_n_ss),
    .mosi_out(tx_mosi),
    .clk_out(tx_clk),
    .valid_out(tx_rcv_byte_valid),
    .bytes_out(tx_rcv_bytes),
    .byte_count(tx_byte_count),
    .finished_out(tx_finished)
  );

  assign clk_out  = txing ? tx_clk  : 0;
  assign mosi_out = txing ? tx_mosi : 0;
  assign n_ss_out = txing ? tx_n_ss : 1;

  always_comb begin
    case (state)
      INIT_SET_FULLDUPLEX: begin
        tx_snd_bytes = FULLDUPLEX_MSG;
        tx_snd_byte_count = 2;
      end
      INIT_SET_POWER: begin
        tx_snd_bytes = POWER_MSG;
        tx_snd_byte_count = 2;
      end
      INIT_SET_HOSTMODE: begin
        tx_snd_bytes = HOSTMODE_MSG;
        tx_snd_byte_count = 2;
      end
      INIT_ENABLE_INTERRUPTS: begin
        tx_snd_bytes = ENABLE_INTERRUPTS_MSG;
        tx_snd_byte_count = 2;
      end
      SETUP_SET_PERADDR_SUDFIFO: begin
        tx_snd_bytes = SET_PERADDR_SUDFIFO;
        tx_snd_byte_count = 9;
      end
      SETUP_SET_PERADDR_HXFR,
      SETUP_SET_CONFIG_HXFR: begin
        tx_snd_bytes = SET_PERADDR_HXFR;
        tx_snd_byte_count = 2;
      end
      SETUP_SET_PERADDR_READ,
      SETUP_SET_CONFIG_READ: begin
        tx_snd_bytes = SET_PERADDR_READ;
        tx_snd_byte_count = 2;
      end
      SETUP_SET_PERADDR_CLEAR,
      SETUP_SET_CONFIG_CLEAR: begin
        tx_snd_bytes = SET_PERADDR_CLEAR;
        tx_snd_byte_count = 2;
      end
      SETUP_SET_CONFIG_SUDFIFO: begin
        tx_snd_bytes = SET_CONFIG_SUDFIFO;
        tx_snd_byte_count = 9;
      end
      default: begin
        tx_snd_bytes = {default: '0};
        tx_snd_byte_count = 0;
      end
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
          wait_count <= 0;
          txing <= 1;
        end

        // Step 0.1: set full-duplex mode and POSINT
        INIT_SET_FULLDUPLEX: begin
          if (tx_finished) begin
            state <= INIT_SET_POWER;
          end
        end

        // Step 0.2: set GPOUT0 which is connected to PRT_CTL and enables USB 5V
        INIT_SET_POWER: begin
          if (tx_finished) begin
            state <= INIT_SET_HOSTMODE;
          end
        end

        // Step 0.3: set HOST mode and SEPIRQ (no GPIN interrupts on int_in)
        INIT_SET_HOSTMODE: begin
          if (tx_finished) begin
            state <= INIT_ENABLE_INTERRUPTS;
          end
        end

        // Step 0.4: enable interrupts for sends and receives
        INIT_ENABLE_INTERRUPTS: begin
          if (tx_finished) begin
            state <= SETUP_SET_PERADDR_SUDFIFO;
          end
        end

        // Step 0.4.5: enable interrupt pin (int_in)
        // NOTE because the RealDigital Urbana board doesn't have a pullup resistor connected to
        // the MAX3421E's V_L, this is edge-active and I've set POSINT=1. See Figure 12 in the datasheet
        // INIT_ENABLE_INTERRUPT_PIN: begin
        //   if (writer_done) begin
        //     writing <= 0;
        //     state <= WAITING;
        //   end
        // end

        // Next, we would usually also set DPPULLDP/N pulldown bits to allow for peripheral connection detection
        // and then set CONDETIE (connection interrupt enable). Then we'd sample the bus (set SAMPLEBUS bit) and
        // check the J/K status bit to see if it was a connect/disconnect and if it's a high/low speed peripheral.
        // Then we would start sending SETUP packets to identify the peripheral type (i.e. MIDI controller brand and
        // model) but I'm going to keep that as part of the stretch goal.

        // Let's start setting up USB!
        
        // Step 1.1: set peripheral address. We need to clock in 8 bytes into SUDFIFO:
        // bmRequestType  SET_ADDRESS  Device Address  wIndex  wLength
        // 0x00           0x05         0x0001          0x0000  0x0000
        // Then clock in 0x10 to HXFR to send the SETUP packet
        // Then clock in 0x80 to HXFR to send the STATUS HS-IN packet
        // Then we'll check for HXFRDNIRQ on finish and clear
        SETUP_SET_PERADDR_SUDFIFO: begin
          if (tx_finished) begin
            state <= SETUP_SET_PERADDR_HXFR;
          end
        end

        SETUP_SET_PERADDR_HXFR: begin
          if (tx_finished) begin
            state <= SETUP_SET_PERADDR_WAIT;
            txing <= 0;
          end
        end

        SETUP_SET_PERADDR_WAIT: begin
          if (wait_count == 18) begin
            txing <= 1;
            state <= SETUP_SET_PERADDR_READ;
            wait_count <= 0;
          end else wait_count <= wait_count + 1;
        end

        SETUP_SET_PERADDR_READ: begin
          if (tx_rcv_byte_valid) begin
            // If the transfer completed successfully
            if (tx_rcv_bytes[1][3:0] == 0) begin
              state <= SETUP_SET_PERADDR_CLEAR;
            end
          end
        end

        SETUP_SET_PERADDR_CLEAR: begin
          if (tx_finished) begin
            state <= SETUP_SET_PERADDR_STATUS;
          end
        end

        SETUP_SET_PERADDR_STATUS: begin
          if (tx_finished) begin
            state <= SETUP_SET_PERADDR_FINISH;
            txing <= 0;
          end
        end

        SETUP_SET_PERADDR_FINISH: begin
          if (wait_count == 100) begin
            txing <= 1;
            state <= SETUP_SET_CONFIG;
            wait_count <= 0;
          end wait_count <= wait_count + 1;
        end

        // Step 1.2 set configuration descriptor. I'm just guessing its configuration 1 from
        // running Wireshark on my AKAI MK3. Maybe in the future I'll do a GET_CONFIGURATION
        // bmRequestType  SET_CONFIGURATION  Config Value  wIndex  wLength
        // 0x00           0x09               0x0001        0x0000  0x0000
        // Then clock in 0x10 to HXFR
        // Then 0x80
        // Then check for HXFRDNIRQ and clear
        SETUP_SET_CONFIG_SUDFIFO: begin
          if (tx_finished) begin
            state <= SETUP_SET_CONFIG_HXFR;
          end
        end

        SETUP_SET_CONFIG_HXFR: begin
          if (tx_finished) begin
            state <= SETUP_SET_CONFIG_WAIT;
            txing <= 0;
          end
        end

        SETUP_SET_CONFIG_WAIT: begin
          if (wait_count == 18) begin
            txing <= 1;
            state <= SETUP_SET_CONFIG_READ;
            wait_count <= 0;
          end else wait_count <= wait_count + 1;
        end

        SETUP_SET_CONFIG_READ: begin
          if (tx_rcv_byte_valid) begin
            // If the transfer completed successfully
            if (tx_rcv_bytes[1][3:0] == 0) begin
              state <= SETUP_SET_CONFIG_CLEAR;
            end
          end
        end

        SETUP_SET_CONFIG_CLEAR: begin
          if (tx_finished) begin
            state <= SETUP_SET_CONFIG_STATUS;
          end
        end

        SETUP_SET_CONFIG_STATUS: begin
          if (tx_finished) begin
            state <= SETUP_SET_CONFIG_FINISH;
            txing <= 0;
          end
        end

        SETUP_SET_CONFIG_FINISH: begin
          if (wait_count == 100) begin
            txing <= 1;
            state <= POLL_BULK_IN_HXFR;
            wait_count <= 0;
          end wait_count <= wait_count + 1;
        end

        // Step 2.1: send BULK IN packet to ask for data every so often
        // Clock in 0x01 (device address is last 4 bits) to HXFR
        // Check for HXFRDNIRQ and HSLRT for errors
        // If none, read RCVBC for byte count and read that many bytes from RCVFIFO
        // Clear RCVDAVIRQ
        POLL_BULK_IN_HXFR: begin

        end

        // Step 2.2: de-encapsulate MIDI data!!!
        // send 4-byte MIDI packets downstream!!!
        DEENCAPSULATE_MIDI: begin

        end

        WAITING: ;
      endcase
    end
  end

endmodule

`default_nettype wire
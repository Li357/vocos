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

  typedef enum {WAITING, WRITING, HOLDING} state_t;
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
            hold_count <= 0;
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

module max3421_read(
  input wire clk_in,
  input wire rst_in,
  input wire miso_in,
  input wire [8:0] msg_in,
  input wire valid_in,
  output logic n_ss_out,
  output logic mosi_out,
  output logic clk_out,
  output logic valid_out,
  output logic [7:0] byte_out
);
  localparam HOLD_CYCLES = 5; // the max3421 can be driven up to 26MHz, and needs >=200ns between commands

  typedef enum {WAITING, WRITING, READING, HOLDING} state_t;
  state_t state;

  logic [2:0] hold_count;
  logic [3:0] msg_index;
  logic [2:0] bit_count;
  logic clk_on;
  assign clk_out = clk_on ? clk_in : 0;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= WAITING;
      n_ss_out <= 1;
      clk_on <= 0;
      msg_index <= 0;
      bit_count <= 0;
    end else begin
      case (state)
        WAITING: begin
          if (valid_in) begin
            state <= WRITING;
            msg_index <= 0;
            clk_on <= 0;
            n_ss_out <= 0;
          end
        end
        WRITING: begin
          // Keep nSS low and clock on to get bits out on MISO
          if (msg_index == 8) begin
            state <= READING;
            bit_count <= 0;
          end else begin
            clk_on <= 1;
            msg_index <= msg_index + 1;
          end
        end
        READING: begin
          if (valid_out) valid_out <= 0;

          // We stop reading as soon as valid_in is deasserted
          if (!valid_in) begin
            clk_on <= 0;
            n_ss_out <= 1;
            state <= HOLDING;
            hold_count <= 0;
          end else begin
            if (bit_count == 7) begin
              valid_out <= 1;
              bit_count <= 0;
            end else begin
              bit_count <= bit_count + 1;
            end
          end
        end
        HOLDING: begin
          if (hold_count == HOLD_CYCLES) begin
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
    end else if (state == READING) begin
      byte_out[7 - bit_count] <= miso_in;
    end
  end
endmodule
`default_nettype none
`timescale 1ns / 1ps

module lsfr31(
    input wire clk_in,
    input wire rst_in,
    output logic [30:0] data_out
);

    // Implementing 31-bit maximal-length LSFR with taps 0x4000002A

    logic feedback;
    assign feedback = data_out[30] ^ data_out[5] ^ data_out[3] ^ data_out[1];

    always_ff @(posedge clk_in) begin
        if (rst_in) data_out <= ~31'b0;
        else data_out <= {data_out[29:0], feedback};
    end

endmodule

`default_nettype wire
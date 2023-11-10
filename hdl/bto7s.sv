module bto7s(
  input wire [3:0]   x_in,
  output logic [6:0] s_out
);

  logic [15:0] num;
  assign num[0] = x_in == 4'd0;
  assign num[1] = x_in == 4'd1; 
  assign num[2] = x_in == 4'd2;
  assign num[3] = x_in == 4'd3;
  assign num[4] = x_in == 4'd4;
  assign num[5] = x_in == 4'd5;
  assign num[6] = x_in == 4'd6;
  assign num[7] = x_in == 4'd7;
  assign num[8] = x_in == 4'd8;
  assign num[9] = x_in == 4'd9;
  assign num[10] = x_in == 4'd10;
  assign num[11] = x_in == 4'd11;
  assign num[12] = x_in == 4'd12;
  assign num[13] = x_in == 4'd13;
  assign num[14] = x_in == 4'd14;
  assign num[15] = x_in == 4'd15;

  assign s_out[0] = ~(num[1] || num[4] || num[11] || num[13]);
  assign s_out[1] = ~(num[5] || num[6] || num[11] || num[12] || num[14] || num[15]);
  assign s_out[2] = ~(num[2] || num[12] || num[14] || num[15]);
  assign s_out[3] = ~(num[1] || num[4] || num[7] || num[10] || num[15]);
  assign s_out[4] = ~(num[1] || num[3] || num[4] || num[5] || num[7] || num[9]);
  assign s_out[5] = ~(num[1] || num[2] || num[3] || num[7] || num[13]);
  assign s_out[6] = ~(num[0] || num[1] || num[7] || num[12]);

endmodule


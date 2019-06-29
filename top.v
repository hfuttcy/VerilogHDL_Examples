`timescale 1ns/1ns
`include "sigdata.v"
`include "ptosda.v"
`include "out16hi.v"

module top;
wire [3:0] data;
wire sclk;
wire scl;
wire sda;
wire rst;
wire [15:0] outhigh;

sigdata m0 (.rst(rst), .sclk(sclk), .data(data), .ask_for_data(ack));
ptosda m1(.rst(rst), .sclk(sclk), .ack(ack), .scl(scl), .sda(sda), .data(data));
out16hi m2 (.scl(scl), .sda(sda), .outhigh(outhigh));
endmodule

//`include "./Signal.v"
//`include "./EEPROM.v"
//`include "./EEPROM_WR.v" //It could be alternetived by spice
`timescale 1ns/1ns
`define timeslice 200

module Top;
wire RESET;
wire CLK;
wire RD, WR;
wire ACK;
wire [10:0] ADDR;
wire [7:0] DATA;
wire SCL;
wire SDA;
parameter test_numbers = 10;
initial #(`timeslice * 180 * test_numbers) $stop;
/*
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0,Top);
end
*/
// redefine test_number
Signal #(test_numbers) signal(.RESET(RESET), .CLK(CLK), .RD(RD), .WR(WR), .ADDR(ADDR), .ACK(ACK), .DATA(DATA));
EEPROM_WR eeprom_wr(.RESET(RESET), .SDA(SDA), .SCL(SCL), .ACK(ACK), .CLK(CLK), .WR(WR), .RD(RD), .ADDR(ADDR), .DATA(DATA));
EEPROM eeprom (.sda(SDA), .scl(SCL));
endmodule
// Top.v end

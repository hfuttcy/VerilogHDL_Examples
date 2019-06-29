// verilogHDL Eg15.2 
// testbench 
// 
`timescale 1ns/1ns
`define halfperiod 50
module sigdata(
input ask_for_data,
output reg rst,
output reg [3:0] data,
output reg sclk
);
//reg rst;
//reg sclk;
//reg [3:0] data;
initial begin
    rst = 1;
    #10 rst = 0;
    #(`halfperiod * 2 + 3) rst = 1;
end

initial begin
    sclk = 0;
    data = 0;
    #(`halfperiod * 1000) $stop;
end
always #`halfperiod sclk =  ~sclk;
always@(posedge ask_for_data)
begin
    #(`halfperiod/2 + 3) data = data + 1;
end
endmodule



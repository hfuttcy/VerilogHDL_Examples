`timescale 1ns/1ns
`define timeslice 200
module Signal(RESET, CLK, RD, WR, ADDR, ACK, DATA);
output RESET;
output CLK;
output RD,WR;
output[10:0] ADDR;
input ACK;
input [7:0] DATA;

reg RESET;
reg CLK;
reg RD, WR;
reg W_R;
reg [10:0] ADDR;
reg [7:0] data_to_eeprom;
reg [10:0] addr_mem[0:255];
reg [7:0] data_mem[0:255];
reg [7:0] ROM[0:2047]; // 2^11
integer i,j;
integer OUTFILE; // this usage, integer
parameter test_number = 2;
assign DATA = (W_R) ? 8'bz : data_to_eeprom;
//-----CLK input--------
always # (`timeslice/2)
    CLK = ~CLK;
//--------Read and Write input--------
initial begin
    RESET = 1;
    i = 0;
    j = 0;
    W_R = 0;
    CLK = 0;
    RD = 0;
    WR = 0;
    #1000;
    RESET = 0;
	repeat(test_number)
    begin
        #(5 * `timeslice);
        WR = 1;
        # (`timeslice);
        WR = 0;
        @ (posedge ACK);
    end
        #(10 * `timeslice);
        W_R = 1;
		repeat(test_number)
            begin
                #(5 * `timeslice);
                RD = 1;
                #(`timeslice);
                RD = 0;
                @(posedge ACK);
            end
        end
//-------write--------------
initial begin
    $display("writing----writing------writing-writing");
    #(2 * `timeslice);
    for(i = 0; i <= test_number; i = i+1)
    begin
    ADDR = addr_mem[i]; // addr_mem read from .dat file
    data_to_eeprom = data_mem[i]; // read from .dat file
    $fdisplay(OUTFILE,"@%0h  %0h", ADDR, data_to_eeprom); //@, record data to OUTFILE(eeprom.dat) 
    //$fdisplay(OUTFILE,"%0h  %0h", ADDR, data_to_eeprom);
    @(posedge ACK); // wait until ACK signal, means W/R consruction has been done
end
end
//--------read---------------
initial
    @(posedge W_R)
    begin
        ADDR = addr_mem[0];
        $fclose (OUTFILE);
        $readmemh("./eeprom.dat",ROM);// eeprom.dat data write to ROM
        
        $display(" Begin READING--READDR---READING----READING");
        for(j = 0; j < test_number; j=j+1)
        begin
            ADDR = addr_mem[j];
            @(posedge ACK);
            if(DATA == ROM[ADDR])
                $display("DATA %0h == ROM[%0h]---READ RIGHT",DATA,ADDR);
            else
                $display("DATA %0h ! = ROM[%0h]---READ WRONG",DATA, ADDR);
        end
    end

    initial begin
        OUTFILE = $fopen("./eeprom.dat"); // open a file named eeprom.dat for backup
        $readmemh("./addr.dat",addr_mem);
        $readmemh("./addr.dat",data_mem);
    end
    endmodule







//serial EEPROM 1-byte read-write
// 1-byte write and specify-addr read
// EEPROM AT24C02/4/8/16
//Verilog 2001
//module function: simulate EEPROM random R/D, can't be synthesize 
`timescale 1ns/1ns
`define timeslice 100
module EEPROM(
inout sda,
input scl
); 
reg out_flag;// decide the connection of sda and sdabuf
reg [7:0] memory[2047:0]; // ROM,2^11 is 2048, 11-bit address ranges from 0-2048
reg [10:0] address; 
reg [7:0] memory_buf;
reg [7:0] sda_buf;   //sda output reg
reg [7:0] shift;     //sda input reg
reg [7:0] addr_byte; // addr_word 8-bit
reg [7:0] ctrl_byte;
reg [1:0] state;
integer i;
// eight EEPROM linked in sda
parameter r7 = 8'b10101111, w7 = 8'b10101110, //main7
r6 = 8'b10101101, w6 = 8'b10101100, //main6
r5 = 8'b10101011, w5 = 8'b10101010, //main5
r4 = 8'b10101001, w4 = 8'b10101000, //main4
r3 = 8'b10100111, w3 = 8'b10100110, //main3
r2 = 8'b10100101, w2 = 8'b10100100, //main2
r1 = 8'b10100011, w1 = 8'b10100010, //main1
r0 = 8'b10100001, w0 = 8'b10100000; //main0


assign sda = (out_flag == 1) ? sda_buf[7]:1'bz;
initial begin
    addr_byte = 0;
    ctrl_byte = 0;
    out_flag = 0;
    sda_buf = 0;
    state = 0;
    memory_buf = 0; 
    address = 0; //[10:0]
    shift = 0;
for(i = 0; i <= 2047; i=i+1)
    memory[i] = 0;
end
//-------------start signal------------
always@(negedge sda) // 'bz to 'b1 is negedge
    if(scl == 1)
    begin 
        state = state + 1; // start
        if(state == 2'b11) //means read state
            disable write_to_eeprm; //quit from this task, because read_state don't need write data
    end
//-------------main state machine----------
always@(posedge sda)
    if (scl == 1)
        stop_W_R; // stop signal
    else
    begin
        casex(state)
            2'b01: // read in ctrl_byte, address_byte, write_to memoty all in 1 clk?, in my opinion, shift_in task need sensitive signal, and it is internal. So it won't detect sda sensitive siganl
            begin
                read_in;// shift in ctrl_byte, ctrl_byte and addr_byte assigned by sda 
                if(ctrl_byte == w7 || ctrl_byte == w6 || ctrl_byte == w5 ||ctrl_byte == w4 ||ctrl_byte == w3 ||ctrl_byte == w2 ||ctrl_byte == w1 ||ctrl_byte == w0 ) begin
                    state = 2'b10; // next start signal means Read
                    write_to_eeprm;
                end
                else
                    state = 2'b00; // start when state = state + 1,wait until next start siganl
            end
            2'b11:
                read_from_eeprm;
            default:
                state = 2'b00;
        endcase
    end
//------------stop construction-----------
task stop_W_R;
    begin state = 2'b00; // return to initial state
    addr_byte = 0;
    ctrl_byte = 0;
    out_flag = 0;
    sda_buf = 0;
end
endtask

task read_in;
    begin
        shift_in(ctrl_byte);
        shift_in(addr_byte);
    end
endtask
//--------EEPROM write--------------
task write_to_eeprm;
    begin
        shift_in(memory_buf);
        address = {ctrl_byte[3:1],addr_byte};// EEPROM address and data address
        memory[address] = memory_buf;
        $display("eeprm------memory[%0h]=%0h",address,memory[address]);
        state = 2'b00;
    end
endtask
//-------EEPROM read-----------------
task read_from_eeprm;
    begin
        shift_in(ctrl_byte);
        if(ctrl_byte == r7 || ctrl_byte == r6 || ctrl_byte == r5 ||ctrl_byte == r4 ||ctrl_byte == r3 ||ctrl_byte == r2 ||ctrl_byte == r1 ||ctrl_byte == r0 ) begin
            address = {ctrl_byte[3:1],addr_byte};
            sda_buf = memory[address];
            shift_out;
            state = 2'b00;
        end
        end
    endtask


task shift_in;
    output[7:0] shift;
    begin
        @(posedge scl) shift[7] = sda;
        @(posedge scl) shift[6] = sda;
        @(posedge scl) shift[5] = sda;
        @(posedge scl) shift[4] = sda;
        @(posedge scl) shift[3] = sda;
        @(posedge scl) shift[2] = sda;
        @(posedge scl) shift[1] = sda;
        @(posedge scl) shift[0] = sda;
        @(negedge scl)
        begin
            # `timeslice; // answer signal, slave(EEPROM) is receiving data, when done, it should output a answer signal
            out_flag = 1; //slave(EEPROM) will output an answer siganl 
            sda_buf = 0;// I think <= will be better?
        end
        @(negedge scl)
        # `timeslice out_flag = 0; // set to 'hz, in order to  input data next time
    end
endtask
//------------EEPROM data output from sda-----
task shift_out;
    begin
        out_flag = 1; // output state, this state will output sda_buf[7]
        for(i = 6;i >= 0;i=i-1)
        begin
            @(negedge scl) // data change at negedge scl
            # `timeslice; // neccessary delay
            sda_buf = sda_buf << 1;
        end
        @(negedge scl) # `timeslice sda_buf[7] = 1; // no-answer signal output, no.9 answer bit, Read state 
        @(negedge scl) # `timeslice out_flag = 0;
    end
endtask
endmodule

//


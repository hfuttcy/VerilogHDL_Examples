//-------------module EEPROM_WR-----------------------
//according to MCU parallel data, address data and W/R control wire, can read
//data or write data from/to EERPOM
//It's a nesting state machine,actual there are five state machine, and can be synthetical
module EEPROM_WR(SDA,SCL,ACK,RESET,CLK,WR,RD,ADDR,DATA);
output SCL;
output ACK;// W/R one cyle answer signal
input RESET;
input CLK;
input WR,RD;// W/R input signal
input [10:0] ADDR; // 2^11 ranges address
inout SDA; // input and output singal
inout [7:0] DATA; // related to Signal.v , inout type
reg ACK;
reg SCL;
reg WF,RF;
reg FF; // main state machine and nesting state machine flag register
reg [1:0] head_buf; // start signal register
reg [1:0] stop_buf; // stop signal register
reg [7:0] sh8out_buf; // EEPROM write register
reg [8:0] sh8out_state; // EEPROM write state register
reg [9:0] sh8in_state; // EEPROM read state
reg [2:0] head_state; // start state 
reg [2:0] stop_state;
reg [10:0] main_state;
reg [7:0] data_from_rm; // sh8in_buf, read register
reg link_sda; // control SDA
reg link_read; // read constrution swith, input, and link_sda must be turn off
reg link_head; // start construction swith, output
reg link_write; // write constrution swith, output
reg link_stop;  //stop construction swith, output
wire sda1, sda2, sda3, sda4; // 
//-------serial dadta controled by signals----------
assign sda1 = (link_head)? head_buf[1] : 1'b0;
assign sda2 = (link_write)? sh8out_buf[7] : 1'b0;
assign sda3 = (link_stop)? stop_buf[1] : 1'b0;
assign sda4 = (sda1 || sda2 || sda3);
assign SDA = (link_sda)? sda4 : 1'bz; // set to 'hz in order to receive data
assign DATA = (link_read)? data_from_rm : 8'bzz;
//-------main state machine---------
parameter Idle = 11'b0000_0000_001;
parameter Ready = 11'b0000_0000_010;
parameter Write_start = 11'b0000_0000_100;
parameter Ctrl_write = 11'b0000_0001_000;
parameter Addr_write = 11'b0000_0010_000;
parameter Data_write = 11'b0000_0100_000;
parameter Read_start = 11'b0000_1000_000;
parameter Ctrl_read = 11'b0001_0000_000;
parameter Data_read = 11'b0010_0000_000;
parameter Stop = 11'b0100_0000_000;
parameter Ackn = 11'b1000_0000_000;
//-----------parallel data serial output state--------
parameter sh8out_bit7 = 9'b0000_0000_1;
parameter sh8out_bit6 = 9'b0000_0001_0;
parameter sh8out_bit5 = 9'b0000_0010_0;
parameter sh8out_bit4 = 9'b0000_0100_0;
parameter sh8out_bit3 = 9'b0000_1000_0;
parameter sh8out_bit2 = 9'b0001_0000_0;
parameter sh8out_bit1 = 9'b0010_0000_0;
parameter sh8out_bit0 = 9'b0100_0000_0;
parameter sh8out_end = 9'b1000_0000_0;
//-------serial data parallel output state--------
parameter sh8in_begin = 10'b0000_0000_01;
parameter sh8in_bit7 = 10'b0000_0000_10;
parameter sh8in_bit6 = 10'b0000_0001_00;
parameter sh8in_bit5 = 10'b0000_0010_00;
parameter sh8in_bit4 = 10'b0000_0100_00;
parameter sh8in_bit3 = 10'b0000_1000_00;
parameter sh8in_bit2 = 10'b0001_0000_00;
parameter sh8in_bit1 = 10'b0010_0000_00;
parameter sh8in_bit0 = 10'b0100_0000_00;
parameter sh8in_end = 10'b1000_0000_00;
//-------start state----------------
parameter head_begin = 3'b001;
parameter head_bit = 3'b010;
parameter head_end = 3'b100;
//-------stop state---------------
parameter stop_begin = 3'b001;
parameter stop_bit = 3'b010;
parameter stop_end = 3'b100;

parameter YES = 1;
parameter NO = 0;

//-----generate serial clock----
always@(negedge CLK) // negedge
    if(RESET)
        SCL <= 0;
    else 
        SCL <= ~SCL;
//-------main state machine-----
always@(posedge CLK)
    if(RESET)
    begin
        link_read <= NO; // all swiths turn off
        link_write <= NO; 
        link_head <= NO;
        link_stop <= NO;
        link_sda <= NO;
        ACK = 0;
        RF <= 0;
        WF <=0;
        FF <= 0;
        main_state <= Idle;
    end
    else
    begin
        casex(main_state)
            Idle:
            begin
                link_read <= NO;
                link_write <= NO;
                link_head <= NO;
                link_stop <= NO;
                link_sda <= NO;
                if(WR) // wait until WR/RD signal input
                begin
                    WF <= 1;
                    main_state <= Ready;
                end
                else if(RD)
                begin
                    RF <= 1;
                    main_state <= Ready;
                end
                else
                begin
                    WF <= 0;
                    RF <= 0;
                    main_state <= Idle;
                end
            end
            Ready: // no-block assignment
            begin
                link_read <= NO; // DATA = 8'hzz
                link_write <= NO;
                link_head <= YES; // start signal output
                link_stop <= NO;
                link_sda <= YES; // output open,SDA = 1
                head_buf[1:0] <= 2'b10;
                stop_buf[1:0] <= 2'b01;
                head_state <= head_begin;// set start_state_machine state in the front
                FF <= 0; // nesting state_machine
                ACK <= 0;
                main_state <= Write_start;
                end
            Write_start: // 3 clk
                if(FF == 0)
                    shift_head; //generate start signal, link_sda always open,this task 2 clk
                else // 1 clk, generate SDA = 1
                begin
                    sh8out_buf[7:0] <= {1'b1, 1'b0, 1'b1, 1'b0, ADDR[10:8],1'b0}; //write ctrl_byte
                    link_head <= NO;
                    link_write <= YES; // SDA = 1
                    FF <= 0;
                    sh8out_state <= sh8out_bit6; // have generate bit7 in "link_write  = YES"
                    main_state <= Ctrl_write;
                end
            Ctrl_write:
                if(FF == 0)
                    shift8_out; // write ctrl_byte{1010,ADDR[10:8],0}
                else
                    begin
                        sh8out_state <= sh8out_bit7; // reset shift8_out machine
                        sh8out_buf[7:0] <= ADDR[7:0]; // EEPROM in_chip address
                        FF <= 0;
                        main_state <= Addr_write;
                    end
            Addr_write:
                if(FF == 0)
                    shift8_out; // write address
                else
                begin
                    FF <= 0;
                    if(WF) // W
                    begin
                        sh8out_state <= sh8out_bit7;
                        sh8out_buf[7:0] <= DATA;
                        main_state <= Data_write;
                    end
                    if(RF) // R
                    begin
                        head_buf <= 2'b10;
                        head_state <= head_begin; // need generate start siganl
                        main_state <= Read_start;
                    end
                end
                Data_write:
                    if(FF == 0)
                        shift8_out;// link_sda controled in this task, link_sda = NO lasts 2 clk
                    else begin
                        stop_state <= stop_begin;
                        main_state <= Stop;
                        link_write <= NO; // close write
                        FF <= 0;
                    end
                Read_start:
                    if(FF == 0)
                        shift_head;
                    else begin
                        sh8out_buf <= {1'b1,1'b0,1'b1,1'b0,ADDR[10:8],1'b1}; // read_ctrl_byte
                        link_head <= NO; 
                        link_sda <= YES;
                        link_write <= YES; // SDA = 1, sh8out_buf[7]
                        FF <= 0;
                        sh8out_state <= sh8out_bit6; // already set SDA = sh8out_buf[7]
                        main_state <= Ctrl_read;
                    end
                Ctrl_read: // I think it is still write read_ctrl_byte
                    if(FF == 0)
                        shift8_out;// 8 clk, (state begin at sh8out_bit6)
                    else begin
                        link_sda <= NO; // set SDA = 'bz, in order read data( receive SDA from EEPROM)
                        link_write <= NO;
                        FF <= 0;
                        sh8in_state <= sh8in_begin;
                        main_state <= Data_read;
                    end
                Data_read:
                    if(FF == 0)
                        shift8in; // SDA set by EEPROM, 10 clk
                    else begin
                        link_stop <= YES; // SDA output mode
                        link_sda <= YES; //SDA = 0, stop signal needed
                        stop_state <= stop_bit; // not stop_begin,bacause have set SDA = 0
                        FF <= 0;
                        main_state <= Stop;
                    end
                Stop:
                    if(FF == 0)
                        shift_stop;
                    else
                    begin
                        ACK <= 1; // after 3 clk, Ack = 1
                        FF <= 0;
                        //RF <= 1;
                        main_state <= Ackn;
                    end
				Ackn:
					begin
					ACK <= 0;
					WF <= 0;
					RF <= 0;
					main_state <= Idle;
					end
                default: main_state <= Idle;
                endcase
            end
//-------serial data to parallel data----------
task shift8in; // EEPROM set SDA, EEPROM_WR get SDA
    begin
        casex(sh8in_state)
            sh8in_begin:
                sh8in_state <= sh8in_bit7;
        sh8in_bit7: if(SCL)
        begin
            data_from_rm[7] <= SDA;
            sh8in_state <= sh8in_bit6;
        end
        else
            sh8in_state <= sh8in_bit7;
        sh8in_bit6:
            if(SCL)
            begin
                data_from_rm[6] <= SDA;
                    sh8in_state <= sh8in_bit5;
            end
        else
            sh8in_state <= sh8in_bit6;
        sh8in_bit5:
            if(SCL)
            begin
                data_from_rm[5] <= SDA;
                    sh8in_state <= sh8in_bit4;
            end
        else
            sh8in_state <= sh8in_bit5;
        sh8in_bit4:
            if(SCL)
            begin
                data_from_rm[4] <= SDA;
                    sh8in_state <= sh8in_bit3;
            end
        else
            sh8in_state <= sh8in_bit4;
        sh8in_bit3:
            if(SCL)
            begin
                data_from_rm[3] <= SDA;
                    sh8in_state <= sh8in_bit2;
            end
        else
            sh8in_state <= sh8in_bit3;
        sh8in_bit2:
            if(SCL)
            begin
                data_from_rm[2] <= SDA;
                    sh8in_state <= sh8in_bit1;
            end
        else
            sh8in_state <= sh8in_bit2;
        sh8in_bit1:
            if(SCL)
            begin
                data_from_rm[1] <= SDA;
                    sh8in_state <= sh8in_bit0;
            end
        else
            sh8in_state <= sh8in_bit1;
        sh8in_bit0:
            if(SCL)
            begin
                data_from_rm[0] <= SDA;
                    sh8in_state <= sh8in_end;
            end
        else
            sh8in_state <= sh8in_bit0;
        sh8in_end:
            if(SCL)
            begin
                link_read <= YES; // all SDA are set, then assign value to DATA
                FF  <= 1;
                sh8in_state <= sh8in_bit7;// reset shift8_in state_machine
            end
            else
                sh8in_state <= sh8in_end;
            default: begin
                link_read <= NO;
                sh8in_state <= sh8in_bit7;
            end
        endcase
        end
    endtask
//-------parallel to serial------------
task shift8_out;
    begin
        casex(sh8out_state)
            sh8out_bit7:
                if(! SCL)
                begin
                    link_sda <= YES;
                    link_write <= YES;
                    sh8out_state <= sh8out_bit6;
                end
                else
                    sh8out_state <= sh8out_bit7;
            sh8out_bit6:
                if( !SCL)
                begin
                    link_sda <= YES;
                    link_write <= YES;
                    sh8out_state <= sh8out_bit5;
                    sh8out_buf <= sh8out_buf << 1;
                end
                else
                    sh8out_state <= sh8out_bit6;
            sh8out_bit5:
                if(! SCL)
                begin
                    sh8out_state <= sh8out_bit4;
                    sh8out_buf <= sh8out_buf << 1;
                end
                else
                    sh8out_state <= sh8out_bit5;
            sh8out_bit4:
                if(! SCL)
                begin
                    sh8out_state <= sh8out_bit3;
                    sh8out_buf <= sh8out_buf << 1;
                end
                else
                    sh8out_state <= sh8out_bit4;
            sh8out_bit3:
                if(! SCL)
                begin
                    sh8out_state <= sh8out_bit2;
                    sh8out_buf <= sh8out_buf << 1;
                end
                else
                    sh8out_state <= sh8out_bit3;
            sh8out_bit2:
                if(! SCL)
                begin
                    sh8out_state <= sh8out_bit1;
                    sh8out_buf <= sh8out_buf << 1;
                end
                else
                    sh8out_state <= sh8out_bit2;
            sh8out_bit1:
                if(! SCL)
                begin
                    sh8out_state <= sh8out_bit0;
                    sh8out_buf <= sh8out_buf << 1;
                end
                else
                    sh8out_state <= sh8out_bit1;
            sh8out_bit0:
                if(! SCL)
                begin
                    sh8out_state <= sh8out_end;
                    sh8out_buf <= sh8out_buf << 1;
                end
                else
                    sh8out_state <= sh8out_bit0;
            sh8out_end:
                if(! SCL)
                begin
                    link_sda <= NO;
                    link_write <= NO;
                    FF <= 1;
                end
                else
                    sh8out_state <= sh8out_end;
            endcase
        end
    endtask
//---------output start----------------
task shift_head;
    begin
        casex(head_state)
            head_begin:
                if(! SCL)
                begin
                head_state <= head_bit;
                link_write <= NO;
                link_head <= YES;
                link_sda <= YES;
            end
            else
                head_state <= head_begin;
            head_bit:
                if(SCL)
                begin
                    FF <= 1;
                    head_buf <= head_buf << 1;
                    //head_state <= head_end;
					head_state <= head_begin;
                end
                else
                    head_state <= head_bit;
					/* 
					//can't be in head_end state, because FF <= 1 in the last state
                head_end:
                    if(! SCL)
                    begin
						//FF <= 1;
                        link_head <= NO;
                        link_write <= YES;
                    end
                    else
                        head_state <= head_end;
						*/
                endcase
            end
        endtask
//---------output stop signal--------------
task shift_stop;
    begin
        casex(stop_state)
            stop_begin: if(!SCL)
        begin
            link_sda <= YES;
            link_write <= NO;
            link_stop <= YES;
            stop_state <= stop_bit;
        end
        else
            stop_state <= stop_begin;
        stop_bit:
            if(SCL)
            begin
                stop_buf <= stop_buf << 1;
                stop_state <= stop_end;
            end
            else
                stop_state <= stop_bit;
        stop_end: if(!SCL)
        begin
            link_head <= NO;
            link_stop <= NO;
            link_sda <= NO;
            FF <= 1;
        end
        else
            stop_state <= stop_end;
    endcase
end
endtask
endmodule
                    
                


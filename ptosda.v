// verilogHDL Eg15.2 
// parallel to serial 
// module ptosda: 4-bit parallel data transfe
module ptosda(
    input rst, 
    input sclk,
    input [3:0] data,
    output reg scl,
    output sda,
    output reg ack
);
reg link_sda, sdabuf;
reg [3:0] databuf;
reg [7:0] state;
assign sda = link_sda ? sdabuf:1'b0;
parameter ready = 8'b00000000;
parameter start = 8'b00000001;
parameter bit1 = 8'b00000010;
parameter bit2 = 8'b00000100;
parameter bit3 = 8'b00001000;
parameter bit4 = 8'b00010000;
parameter bit5 = 8'b00100000;
parameter stop = 8'b01000000;
parameter idle = 8'b10000000;

always@(posedge sclk or negedge rst)
    if(!rst)
        scl <= 1;
    else
        scl <= ~scl;
// ack is output, when ack change from 0 to 1, means ask for input data
always@(posedge ack)
    databuf <= data;
    
// main Mealy-state machine
// how to arrange ack is a problem
// ack/scl is output, but can still be a control var
always@(negedge sclk or negedge rst)
    if(! rst)
    begin
        link_sda <= 'd0;
        sdabuf <= 'd1;
        ack <= 'd0;
        state <= ready;
    end
    else begin
        case(state)
            ready: if (ack)
            begin
                link_sda <= 1;
                state <= start;
            end
            else begin
                link_sda <= 'd0;
                ack <= 'd1;
                state <= ready;
            end
            start: if (scl && ack)
            begin
                sdabuf <= 'd0;
                state <= bit1;
            end
            else
                state <= start;
            bit1: if (!scl)
            begin
                sdabuf <= databuf[3];
                state <= bit2;
                ack <= 'd0;
            end
            else
                state <= bit1;
            bit2: if (!scl)
            begin
                sdabuf <= databuf[2];
                state <= bit3;
            end
            else
                state <= bit2;
            bit3: if (!scl)
            begin
                sdabuf <= databuf[1];
                state <= bit4;
            end
            else
                state <= bit3;
            bit4: if (!scl)
            begin
                sdabuf <= databuf[0];
                state <= bit5;
            end
            else
                state <= bit4;
            bit5: if (!scl)
            begin
                sdabuf <= 'd0;
                state <= stop;
            end
            else
                state <= bit5;
            stop: if(scl)
            begin
                sdabuf <= 'd1;
                state <= idle;
            end
            else
                state <= stop;
           idle:
           begin 
                link_sda <= 'd0;
                state <= ready;
            end
            default: begin
               link_sda <= 0;
               sdabuf <= 'd1;
               state <= ready;
               end
           endcase
       end
       endmodule

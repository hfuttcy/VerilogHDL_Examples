// verilogHDL Eg15.2 
// serial to parallel 
// module ptosda: serial signal transform into 16-bit parallel signal
//don't have a rst, so initial need to be considered
module out16hi(
    input scl,
    input sda,
    output reg [15:0] outhigh
);
reg [3:0] pdata, pdatabuf;
reg [5:0] mstate /* synthesis preserve*/;
//reg[15:0] outhigh;
reg StartFlag, EndFlag;

always@(negedge sda)
    if (scl)
        StartFlag <= 'd1;
    else if(EndFlag) // ?
        StartFlag <= 'd0;


always@(posedge sda)
    if(scl)
    begin
        EndFlag <= 'd1;
        pdatabuf <= pdata;
    end
    else
        EndFlag <= 'd0;

parameter ready = 6'b000000;
parameter sbit0 = 6'b000001;
parameter sbit1 = 6'b000010;
parameter sbit2 = 6'b000100;
parameter sbit3 = 6'b001000;
parameter sbit4 = 6'b010000;

always@(pdatabuf)
begin
    case(pdatabuf)
        4'b0001: outhigh = 16'b0000_0000_0000_0001;
        4'b0010: outhigh = 16'b0000_0000_0000_0010;
        4'b0011: outhigh = 16'b0000_0000_0000_0100;
        4'b0100: outhigh = 16'b0000_0000_0000_1000;
        4'b0101: outhigh = 16'b0000_0000_0001_0000;
        4'b0110: outhigh = 16'b0000_0000_0010_0000;
        4'b0111: outhigh = 16'b0000_0000_0100_0000;
        4'b1000: outhigh = 16'b0000_0000_1000_0000;
        4'b1001: outhigh = 16'b0000_0001_0000_0000;
        4'b1010: outhigh = 16'b0000_0010_0000_0000;
        4'b1011: outhigh = 16'b0000_0100_0000_0000;
        4'b1100: outhigh = 16'b0000_1000_0000_0000;
        4'b1101: outhigh = 16'b0001_0000_0000_0000;
        4'b1110: outhigh = 16'b0010_0000_0000_0000;
        4'b1111: outhigh = 16'b0100_0000_0000_0000;
        4'b0000: outhigh = 16'b1000_0000_0000_0000;
    endcase
end

always@(posedge scl)
    if(StartFlag)
        case(mstate)
            sbit0: begin
                mstate <= sbit1;
                pdata[3] <= sda;
                $display("I am in sbit0");
            end
            sbit1: begin
                mstate <= sbit2;
                pdata[2] <= sda;
                $display("I am in sdabit1");
            end
            sbit2: begin
                mstate <= sbit3;
                pdata[1] <= sda;
                $display("I am in sdabit1");
            end
            sbit3: begin
                mstate <= sbit4;
                pdata[0] <= sda;
                $display("I am in sdabit1");
            end
            sbit4: begin
                mstate <= sbit0;
                $display("I am in sdastop");
            end
            default:
            mstate <= sbit0;
        endcase
        else mstate <= sbit0; // initial mstate
        endmodule



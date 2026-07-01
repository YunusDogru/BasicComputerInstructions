`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: Register16bit
//////////////////////////////////////////////////////////////////////////////////

module Register16bit(
    input  wire        Clock,
    input  wire        Enable,
    input  wire [2:0]  FunSel,
    input  wire [15:0] I,
    output reg  [15:0] Q
);
    // FunSel encoding:
    // 000: Clear            (Q <- 0)
    // 001: Decrement        (Q <- Q - 1)
    // 010: Increment        (Q <- Q + 1)
    // 011: Load full 16-bit (Q <- I)
    // 100: Load LSB,  clear MSB        (Q <- {8'h00, I[7:0]})
    // 101: Load LSB,  keep  MSB        (Q <- {Q[15:8], I[7:0]})
    // 110: Load MSB,  keep  LSB        (Q <- {I[7:0], Q[7:0]})
    // 111: Load LSB,  sign extend MSB

    initial Q = 16'h0000;

    always @(posedge Clock) begin
        if (Enable) begin
            case (FunSel)
                3'b000: Q <= 16'h0000;
                3'b001: Q <= Q - 16'd1;
                3'b010: Q <= Q + 16'd1;
                3'b011: Q <= I;
                3'b100: Q <= {8'h00, I[7:0]};
                3'b101: Q <= {Q[15:8], I[7:0]};
                3'b110: Q <= {I[7:0], Q[7:0]};
                3'b111: Q <= {{8{I[7]}}, I[7:0]};
            endcase
        end
    end
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: DataRegister (16-bit, byte-wise load from data memory)
//////////////////////////////////////////////////////////////////////////////////

module DataRegister(
    input  wire        Clock,
    input  wire [1:0]  FunSel,
    input  wire [7:0]  I,
    output reg  [15:0] DROut
);
    // FunSel:
    // 00: hold
    // 01: load LSB, clear MSB           ({8'h00, I})
    // 10: load LSB, keep  MSB           ({DROut[15:8], I})
    // 11: load MSB, keep  LSB           ({I, DROut[7:0]})
    initial DROut = 16'h0000;

    always @(posedge Clock) begin
        case (FunSel)
            2'b00: DROut <= DROut;
            2'b01: DROut <= {8'h00, I};
            2'b10: DROut <= {DROut[15:8], I};
            2'b11: DROut <= {I, DROut[7:0]};
        endcase
    end
endmodule

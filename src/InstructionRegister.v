`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: InstructionRegister (16-bit, byte-wise load from instruction memory)
//////////////////////////////////////////////////////////////////////////////////

module InstructionRegister(
    input  wire        Clock,
    input  wire        Enable,
    input  wire        LH,        // 0: load LSB, 1: load MSB
    input  wire [7:0]  I,
    output reg  [15:0] IROut
);
    initial IROut = 16'h0000;

    always @(posedge Clock) begin
        if (Enable) begin
            if (LH == 1'b0)
                IROut[7:0]  <= I;
            else
                IROut[15:8] <= I;
        end
    end
endmodule

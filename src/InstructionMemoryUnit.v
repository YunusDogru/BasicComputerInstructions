`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: InstructionMemoryUnit (IM + IR)
//////////////////////////////////////////////////////////////////////////////////

module InstructionMemoryUnit(
    input  wire        Clock,
    input  wire [15:0] Address,
    input  wire        CS,            // active-low chip select for IM
    input  wire        IR_Enable,
    input  wire        IR_LH,         // 0: load LSB, 1: load MSB
    output wire [15:0] IROut
);
    wire [7:0] memOut;

    InstructionMemory IM(
        .Address(Address),
        .CS(CS),
        .MemOut(memOut)
    );

    InstructionRegister IR(
        .Clock(Clock),
        .Enable(IR_Enable),
        .LH(IR_LH),
        .I(memOut),
        .IROut(IROut)
    );
endmodule

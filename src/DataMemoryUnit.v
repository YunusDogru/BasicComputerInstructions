`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: DataMemoryUnit (DM + DR)
//////////////////////////////////////////////////////////////////////////////////

module DataMemoryUnit(
    input  wire        Clock,
    input  wire [15:0] Address,
    input  wire [7:0]  Data,
    input  wire        WR,             // 0: read, 1: write
    input  wire        CS,             // active-low chip select for DM
    input  wire [1:0]  DR_FunSel,
    output wire [15:0] DROut,
    output wire [7:0]  MemOut
);
    wire [7:0] dmOut;

    DataMemory DM(
        .Clock(Clock),
        .Address(Address),
        .Data(Data),
        .WR(WR),
        .CS(CS),
        .MemOut(dmOut)
    );

    DataRegister DR(
        .Clock(Clock),
        .FunSel(DR_FunSel),
        .I(dmOut),
        .DROut(DROut)
    );

    assign MemOut = dmOut;
endmodule

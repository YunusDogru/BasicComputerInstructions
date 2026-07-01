`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: InstructionMemory (ROM, reads from ROM.mem)
//////////////////////////////////////////////////////////////////////////////////

module InstructionMemory(
    input  wire [15:0] Address,
    input  wire        CS,           // active-low chip select (0 = enabled)
    output reg  [7:0]  MemOut
);
    reg [7:0] ROM_DATA [0:65535];

    initial $readmemh("ROM.mem", ROM_DATA);

    always @(*) begin
        if (~CS)
            MemOut = ROM_DATA[Address];
        else
            MemOut = 8'hZ;
    end
endmodule

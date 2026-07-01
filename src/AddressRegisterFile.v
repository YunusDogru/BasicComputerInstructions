`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: AddressRegisterFile (PC, AR, SP)
//////////////////////////////////////////////////////////////////////////////////

module AddressRegisterFile(
    input  wire        Clock,
    input  wire [15:0] I,
    input  wire [2:0]  FunSel,
    input  wire [2:0]  RegSel,   // active-low enables: bit0=PC, bit1=AR, bit2=SP
    input  wire [1:0]  OutCSel,
    input  wire [1:0]  OutDSel,
    output reg  [15:0] OutC,
    output reg  [15:0] OutD
);
    wire [15:0] PCQ, ARQ, SPQ;

    Register16bit PC(.Clock(Clock), .Enable(~RegSel[0]), .FunSel(FunSel), .I(I), .Q(PCQ));
    Register16bit AR(.Clock(Clock), .Enable(~RegSel[1]), .FunSel(FunSel), .I(I), .Q(ARQ));
    Register16bit SP(.Clock(Clock), .Enable(~RegSel[2]), .FunSel(FunSel), .I(I), .Q(SPQ));

    // Out{C,D}Sel: 00 -> PC, 01 -> PC, 10 -> AR, 11 -> SP
    always @(*) begin
        case (OutCSel)
            2'b00: OutC = PCQ;
            2'b01: OutC = PCQ;
            2'b10: OutC = ARQ;
            2'b11: OutC = SPQ;
        endcase
        case (OutDSel)
            2'b00: OutD = PCQ;
            2'b01: OutD = PCQ;
            2'b10: OutD = ARQ;
            2'b11: OutD = SPQ;
        endcase
    end
endmodule

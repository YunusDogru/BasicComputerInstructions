`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: RegisterFile (R1..R4 + S1..S4 scratch)
//////////////////////////////////////////////////////////////////////////////////

module RegisterFile(
    input  wire        Clock,
    input  wire [15:0] I,
    input  wire [2:0]  FunSel,
    input  wire [3:0]  RegSel,   // active-low enables for R1..R4 (bit0=R1)
    input  wire [3:0]  ScrSel,   // active-low enables for S1..S4 (bit0=S1)
    input  wire [2:0]  OutASel,
    input  wire [2:0]  OutBSel,
    output reg  [15:0] OutA,
    output reg  [15:0] OutB
);
    wire [15:0] R1Q, R2Q, R3Q, R4Q;
    wire [15:0] S1Q, S2Q, S3Q, S4Q;

    Register16bit R1(.Clock(Clock), .Enable(~RegSel[0]), .FunSel(FunSel), .I(I), .Q(R1Q));
    Register16bit R2(.Clock(Clock), .Enable(~RegSel[1]), .FunSel(FunSel), .I(I), .Q(R2Q));
    Register16bit R3(.Clock(Clock), .Enable(~RegSel[2]), .FunSel(FunSel), .I(I), .Q(R3Q));
    Register16bit R4(.Clock(Clock), .Enable(~RegSel[3]), .FunSel(FunSel), .I(I), .Q(R4Q));
    Register16bit S1(.Clock(Clock), .Enable(~ScrSel[0]), .FunSel(FunSel), .I(I), .Q(S1Q));
    Register16bit S2(.Clock(Clock), .Enable(~ScrSel[1]), .FunSel(FunSel), .I(I), .Q(S2Q));
    Register16bit S3(.Clock(Clock), .Enable(~ScrSel[2]), .FunSel(FunSel), .I(I), .Q(S3Q));
    Register16bit S4(.Clock(Clock), .Enable(~ScrSel[3]), .FunSel(FunSel), .I(I), .Q(S4Q));

    // OutA / OutB select:
    // 000: R1, 001: R2, 010: R3, 011: R4
    // 100: S1, 101: S2, 110: S3, 111: S4
    always @(*) begin
        case (OutASel)
            3'b000: OutA = R1Q;
            3'b001: OutA = R2Q;
            3'b010: OutA = R3Q;
            3'b011: OutA = R4Q;
            3'b100: OutA = S1Q;
            3'b101: OutA = S2Q;
            3'b110: OutA = S3Q;
            3'b111: OutA = S4Q;
        endcase
        case (OutBSel)
            3'b000: OutB = R1Q;
            3'b001: OutB = R2Q;
            3'b010: OutB = R3Q;
            3'b011: OutB = R4Q;
            3'b100: OutB = S1Q;
            3'b101: OutB = S2Q;
            3'b110: OutB = S3Q;
            3'b111: OutB = S4Q;
        endcase
    end
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: ArithmeticLogicUnit
//
// FlagsOut bit assignment: [3]=Z, [2]=C, [1]=N, [0]=O
//////////////////////////////////////////////////////////////////////////////////

module ArithmeticLogicUnit(
    input  wire        Clock,
    input  wire [15:0] A,
    input  wire [15:0] B,
    input  wire [4:0]  FunSel,
    input  wire        WF,
    output reg  [15:0] ALUOut,
    output reg  [3:0]  FlagsOut
);
    // FunSel encoding:
    // 5'h00: A
    // 5'h01: B
    // 5'h02: A + 1   (INC)
    // 5'h03: A - 1   (DEC)
    // 5'h04: LSL A
    // 5'h05: LSR A
    // 5'h06: ASR A
    // 5'h07: CSL A   (rotate left through carry)
    // 5'h08: CSR A   (rotate right through carry)
    // 5'h09: NOT A
    // 5'h0A: A & B   (AND)
    // 5'h0B: A | B   (ORR)
    // 5'h0C: A ^ B   (XOR)
    // 5'h0D: ~(A & B) (NAND)
    // 5'h0E: A + B
    // 5'h0F: A + B + C
    // 5'h10: A - B

    reg [16:0] tmp;
    reg [15:0] result;
    reg        nC, nZ, nN, nO;

    initial FlagsOut = 4'b0000;

    always @(*) begin
        // defaults: keep flags
        nZ = FlagsOut[3];
        nC = FlagsOut[2];
        nN = FlagsOut[1];
        nO = FlagsOut[0];
        tmp = 17'h0;
        result = 16'h0;

        case (FunSel)
            5'h00: begin
                result = A;
                nZ = (A == 16'h0000);
                nN = A[15];
            end
            5'h01: begin
                result = B;
                nZ = (B == 16'h0000);
                nN = B[15];
            end
            5'h02: begin // A+1
                tmp = {1'b0, A} + 17'd1;
                result = tmp[15:0];
                nC = tmp[16];
                nZ = (result == 16'h0000);
                nN = result[15];
                nO = (~A[15]) & result[15];
            end
            5'h03: begin // A-1
                tmp = {1'b0, A} - 17'd1;
                result = tmp[15:0];
                nC = tmp[16];
                nZ = (result == 16'h0000);
                nN = result[15];
                nO = A[15] & (~result[15]);
            end
            5'h04: begin // LSL
                result = {A[14:0], 1'b0};
                nC = A[15];
                nZ = (result == 16'h0000);
                nN = result[15];
                nO = A[15] ^ result[15];
            end
            5'h05: begin // LSR
                result = {1'b0, A[15:1]};
                nC = A[0];
                nZ = (result == 16'h0000);
                nN = 1'b0;
                nO = A[15];
            end
            5'h06: begin // ASR
                result = {A[15], A[15:1]};
                nC = A[0];
                nZ = (result == 16'h0000);
                nN = result[15];
                nO = 1'b0;
            end
            5'h07: begin // CSL: rotate left through carry
                result = {A[14:0], FlagsOut[2]};
                nC = A[15];
                nZ = (result == 16'h0000);
                nN = result[15];
                nO = A[15] ^ result[15];
            end
            5'h08: begin // CSR: rotate right through carry
                result = {FlagsOut[2], A[15:1]};
                nC = A[0];
                nZ = (result == 16'h0000);
                nN = result[15];
                nO = A[15];
            end
            5'h09: begin // NOT A
                result = ~A;
                nZ = (result == 16'h0000);
                nN = result[15];
            end
            5'h0A: begin // AND
                result = A & B;
                nZ = (result == 16'h0000);
                nN = result[15];
            end
            5'h0B: begin // ORR
                result = A | B;
                nZ = (result == 16'h0000);
                nN = result[15];
            end
            5'h0C: begin // XOR
                result = A ^ B;
                nZ = (result == 16'h0000);
                nN = result[15];
            end
            5'h0D: begin // NAND
                result = ~(A & B);
                nZ = (result == 16'h0000);
                nN = result[15];
            end
            5'h0E: begin // ADD
                tmp = {1'b0, A} + {1'b0, B};
                result = tmp[15:0];
                nC = tmp[16];
                nZ = (result == 16'h0000);
                nN = result[15];
                nO = (A[15] ~^ B[15]) & (A[15] ^ result[15]);
            end
            5'h0F: begin // ADC: A + B + C
                tmp = {1'b0, A} + {1'b0, B} + {16'd0, FlagsOut[2]};
                result = tmp[15:0];
                nC = tmp[16];
                nZ = (result == 16'h0000);
                nN = result[15];
                nO = (A[15] ~^ B[15]) & (A[15] ^ result[15]);
            end
            5'h10: begin // SUB
                tmp = {1'b0, A} - {1'b0, B};
                result = tmp[15:0];
                nC = tmp[16];
                nZ = (result == 16'h0000);
                nN = result[15];
                nO = (A[15] ^ B[15]) & (A[15] ^ result[15]);
            end
            default: result = 16'h0000;
        endcase

        ALUOut = result;
    end

    always @(posedge Clock) begin
        if (WF) begin
            FlagsOut <= {nZ, nC, nN, nO};
        end
    end
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: CPUSystem (hardwired control unit + datapath)
//////////////////////////////////////////////////////////////////////////////////

module CPUSystem(
    input  wire        Clock,
    input  wire        Reset,
    output reg  [11:0] T
);
    // ---------------------------------------------------------------
    //  Internal control signals
    // ---------------------------------------------------------------
    reg [2:0] RF_FunSel;
    reg [3:0] RF_RegSel;
    reg [3:0] RF_ScrSel;
    reg [2:0] RF_OutASel;
    reg [2:0] RF_OutBSel;

    reg [2:0] ARF_FunSel;
    reg [2:0] ARF_RegSel;
    reg [1:0] ARF_OutCSel;
    reg [1:0] ARF_OutDSel;

    reg [4:0] ALU_FunSel;
    reg       ALU_WF;

    reg [1:0] MuxASel;
    reg [1:0] MuxBSel;
    reg       MuxA_ALU;
    reg [1:0] MuxB_ALU;
    reg       DMU_DataSel;

    reg       IR_Enable;
    reg       IR_LH;
    reg       IMU_CS;
    reg       DMU_CS;
    reg       DMU_WR;
    reg [1:0] DR_FunSel;

    reg       T_Reset;

    // ---------------------------------------------------------------
    //  Data path
    // ---------------------------------------------------------------
    wire [15:0] IROut;
    wire [15:0] ALUOut_w;
    wire [3:0]  Flags;

    ArithmeticLogicUnitSystem ALUSys(
        .Clock(Clock),
        .RF_FunSel(RF_FunSel),
        .RF_RegSel(RF_RegSel),
        .RF_ScrSel(RF_ScrSel),
        .RF_OutASel(RF_OutASel),
        .RF_OutBSel(RF_OutBSel),
        .ARF_FunSel(ARF_FunSel),
        .ARF_RegSel(ARF_RegSel),
        .ARF_OutCSel(ARF_OutCSel),
        .ARF_OutDSel(ARF_OutDSel),
        .ALU_FunSel(ALU_FunSel),
        .ALU_WF(ALU_WF),
        .MuxASel(MuxASel),
        .MuxBSel(MuxBSel),
        .MuxA_ALU(MuxA_ALU),
        .MuxB_ALU(MuxB_ALU),
        .DMU_DataSel(DMU_DataSel),
        .IR_Enable(IR_Enable),
        .IR_LH(IR_LH),
        .IMU_CS(IMU_CS),
        .DMU_CS(DMU_CS),
        .DMU_WR(DMU_WR),
        .DR_FunSel(DR_FunSel),
        .IROut(IROut),
        .ALUOut(ALUOut_w),
        .Flags(Flags)
    );

    // ---------------------------------------------------------------
    //  Instruction-field decoders (visible to the test bench)
    // ---------------------------------------------------------------
    wire [5:0] Opcode  = IROut[15:10];
    wire [1:0] RegSel  = IROut[9:8];
    wire [7:0] Address = IROut[7:0];
    wire [2:0] DestReg = IROut[9:7];
    wire [2:0] SrcReg1 = IROut[6:4];
    wire [2:0] SrcReg2 = IROut[3:1];

    // ---------------------------------------------------------------
    //  Time counter (one-hot, 12 bits).  Power-on state: T0 (12'h001).
    // ---------------------------------------------------------------
    initial T = 12'h001;

    always @(posedge Clock) begin
        if (T_Reset)
            T <= 12'h001;
        else
            T <= {T[10:0], 1'b0};
    end

    // ---------------------------------------------------------------
    //  Helpers
    // ---------------------------------------------------------------
    function [3:0] rsel_to_regsel;
        input [1:0] rsel;
        begin
            case (rsel)
                2'b00: rsel_to_regsel = 4'b1110; // R1
                2'b01: rsel_to_regsel = 4'b1101; // R2
                2'b10: rsel_to_regsel = 4'b1011; // R3
                2'b11: rsel_to_regsel = 4'b0111; // R4
            endcase
        end
    endfunction

    function [2:0] rsel_to_outsel;
        input [1:0] rsel;
        begin
            rsel_to_outsel = {1'b0, rsel};
        end
    endfunction

    function [2:0] dst_to_arf_regsel;
        input [2:0] dst;
        begin
            if (dst[2] == 1'b0) begin
                case (dst[1:0])
                    2'b00, 2'b01: dst_to_arf_regsel = 3'b110; // PC
                    2'b10:        dst_to_arf_regsel = 3'b101; // AR
                    2'b11:        dst_to_arf_regsel = 3'b011; // SP
                endcase
            end else begin
                dst_to_arf_regsel = 3'b111;
            end
        end
    endfunction

    function [3:0] dst_to_rf_regsel;
        input [2:0] dst;
        begin
            if (dst[2] == 1'b1) begin
                case (dst[1:0])
                    2'b00: dst_to_rf_regsel = 4'b1110; // R1
                    2'b01: dst_to_rf_regsel = 4'b1101; // R2
                    2'b10: dst_to_rf_regsel = 4'b1011; // R3
                    2'b11: dst_to_rf_regsel = 4'b0111; // R4
                endcase
            end else begin
                dst_to_rf_regsel = 4'b1111;
            end
        end
    endfunction

    function [1:0] src_to_arf_outsel;
        input [2:0] src;
        begin
            case (src[1:0])
                2'b00, 2'b01: src_to_arf_outsel = 2'b00; // PC
                2'b10:        src_to_arf_outsel = 2'b10; // AR
                2'b11:        src_to_arf_outsel = 2'b11; // SP
            endcase
        end
    endfunction

    // ---------------------------------------------------------------
    //  Branch condition resolver.  Flags = {Z, C, N, O}
    // ---------------------------------------------------------------
    reg branch_taken;
    always @(*) begin
        case (Opcode)
            6'h00: branch_taken = 1'b1;
            6'h01: branch_taken = (Flags[3] == 1'b0);
            6'h02: branch_taken = (Flags[3] == 1'b1);
            6'h03: branch_taken = (Flags[1] != Flags[0]);
            6'h04: branch_taken = (Flags[1] == Flags[0]) && (Flags[3] == 1'b0);
            6'h05: branch_taken = (Flags[1] != Flags[0]) || (Flags[3] == 1'b1);
            6'h06: branch_taken = (Flags[1] == Flags[0]);
            default: branch_taken = 1'b0;
        endcase
    end

    // ---------------------------------------------------------------
    //  Main control unit (combinational)
    // ---------------------------------------------------------------
    always @(*) begin
        // ---- defaults ----
        RF_FunSel   = 3'b011;
        RF_RegSel   = 4'b1111;
        RF_ScrSel   = 4'b1111;
        RF_OutASel  = 3'b000;
        RF_OutBSel  = 3'b000;

        ARF_FunSel  = 3'b011;
        ARF_RegSel  = 3'b111;
        ARF_OutCSel = 2'b00;
        ARF_OutDSel = 2'b11;

        ALU_FunSel  = 5'h00;
        ALU_WF      = 1'b0;

        MuxASel     = 2'b00;
        MuxBSel     = 2'b00;
        MuxA_ALU    = 1'b0;
        MuxB_ALU    = 2'b00;
        DMU_DataSel = 1'b0;

        IR_Enable   = 1'b0;
        IR_LH       = 1'b0;
        IMU_CS      = 1'b1;
        DMU_CS      = 1'b1;
        DMU_WR      = 1'b0;
        DR_FunSel   = 2'b00;

        T_Reset     = 1'b0;

        if (T[0]) begin
            // ---- T0 : IR LSB <- M[PC] ; PC <- PC + 1 ----
            ARF_OutCSel = 2'b00;
            IMU_CS      = 1'b0;
            IR_Enable   = 1'b1;
            IR_LH       = 1'b0;
            ARF_RegSel  = 3'b110;
            ARF_FunSel  = 3'b010;
        end
        else if (T[1]) begin
            // ---- T1 : IR MSB <- M[PC] ; PC <- PC + 1 ----
            ARF_OutCSel = 2'b00;
            IMU_CS      = 1'b0;
            IR_Enable   = 1'b1;
            IR_LH       = 1'b1;
            ARF_RegSel  = 3'b110;
            ARF_FunSel  = 3'b010;
        end
        else begin
            case (Opcode)
                // ----- Branches (0x00 .. 0x06) -----
                6'h00, 6'h01, 6'h02, 6'h03, 6'h04, 6'h05, 6'h06: begin
                    if (T[2]) begin
                        if (branch_taken) begin
                            ARF_RegSel = 3'b110;
                            ARF_FunSel = 3'b011;
                            MuxBSel    = 2'b10;
                        end
                        T_Reset = 1'b1;
                    end
                end

                // ----- Single-source ALU ops (0x07 .. 0x0E) -----
                6'h07, 6'h08, 6'h09, 6'h0A, 6'h0B, 6'h0C, 6'h0D, 6'h0E: begin
                    if (T[2]) begin
                        ALU_FunSel = Opcode[4:0] - 5'h05;
                        ALU_WF     = 1'b1;

                        if (SrcReg1[2] == 1'b0) begin
                            MuxA_ALU    = 1'b1;
                            ARF_OutCSel = src_to_arf_outsel(SrcReg1);
                        end else begin
                            MuxA_ALU    = 1'b0;
                            RF_OutASel  = rsel_to_outsel(SrcReg1[1:0]);
                        end

                        if (DestReg[2] == 1'b0) begin
                            ARF_RegSel = dst_to_arf_regsel(DestReg);
                            ARF_FunSel = 3'b011;
                            MuxBSel    = 2'b00;
                        end else begin
                            RF_RegSel  = dst_to_rf_regsel(DestReg);
                            RF_FunSel  = 3'b011;
                            MuxASel    = 2'b00;
                        end

                        T_Reset = 1'b1;
                    end
                end

                // ----- Two-source ALU ops (0x0F .. 0x15) -----
                6'h0F, 6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15: begin
                    if (T[2]) begin
                        ALU_FunSel = Opcode[4:0] - 5'h05;
                        ALU_WF     = 1'b1;

                        if (SrcReg1[2] == 1'b0) begin
                            MuxA_ALU    = 1'b1;
                            ARF_OutCSel = src_to_arf_outsel(SrcReg1);
                        end else begin
                            MuxA_ALU    = 1'b0;
                            RF_OutASel  = rsel_to_outsel(SrcReg1[1:0]);
                        end

                        RF_OutBSel = rsel_to_outsel(SrcReg2[1:0]);
                        MuxB_ALU   = 2'b00;

                        if (DestReg[2] == 1'b0) begin
                            ARF_RegSel = dst_to_arf_regsel(DestReg);
                            ARF_FunSel = 3'b011;
                            MuxBSel    = 2'b00;
                        end else begin
                            RF_RegSel  = dst_to_rf_regsel(DestReg);
                            RF_FunSel  = 3'b011;
                            MuxASel    = 2'b00;
                        end

                        T_Reset = 1'b1;
                    end
                end

                // ----- MOV (0x16) -----
                6'h16: begin
                    if (T[2]) begin
                        ALU_FunSel = 5'h00;
                        ALU_WF     = 1'b0;

                        if (SrcReg1[2] == 1'b0) begin
                            MuxA_ALU    = 1'b1;
                            ARF_OutCSel = src_to_arf_outsel(SrcReg1);
                        end else begin
                            MuxA_ALU    = 1'b0;
                            RF_OutASel  = rsel_to_outsel(SrcReg1[1:0]);
                        end

                        if (DestReg[2] == 1'b0) begin
                            ARF_RegSel = dst_to_arf_regsel(DestReg);
                            ARF_FunSel = 3'b011;
                            MuxBSel    = 2'b00;
                        end else begin
                            RF_RegSel  = dst_to_rf_regsel(DestReg);
                            RF_FunSel  = 3'b011;
                            MuxASel    = 2'b00;
                        end

                        T_Reset = 1'b1;
                    end
                end

                // ----- IMM (0x17) -----
                6'h17: begin
                    if (T[2]) begin
                        RF_RegSel = rsel_to_regsel(RegSel);
                        RF_FunSel = 3'b011;
                        MuxASel   = 2'b10;
                        T_Reset   = 1'b1;
                    end
                end

                // ----- POP (0x18) -----
                6'h18: begin
                    if (T[2]) begin
                        ARF_RegSel = 3'b011;
                        ARF_FunSel = 3'b010;
                    end
                    else if (T[3]) begin
                        ARF_OutDSel = 2'b11;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b0;
                        RF_RegSel   = rsel_to_regsel(RegSel);
                        RF_FunSel   = 3'b100;
                        MuxASel     = 2'b01;
                        ARF_RegSel  = 3'b011;
                        ARF_FunSel  = 3'b010;
                    end
                    else if (T[4]) begin
                        ARF_OutDSel = 2'b11;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b0;
                        RF_RegSel   = rsel_to_regsel(RegSel);
                        RF_FunSel   = 3'b110;
                        MuxASel     = 2'b01;
                        T_Reset     = 1'b1;
                    end
                end

                // ----- PSH (0x19) -----
                6'h19: begin
                    if (T[2]) begin
                        RF_OutASel  = rsel_to_outsel(RegSel);
                        MuxA_ALU    = 1'b0;
                        ALU_FunSel  = 5'h00;
                        ARF_OutDSel = 2'b11;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b1;
                        DMU_DataSel = 1'b1;
                        ARF_RegSel  = 3'b011;
                        ARF_FunSel  = 3'b001;
                    end
                    else if (T[3]) begin
                        RF_OutASel  = rsel_to_outsel(RegSel);
                        MuxA_ALU    = 1'b0;
                        ALU_FunSel  = 5'h00;
                        ARF_OutDSel = 2'b11;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b1;
                        DMU_DataSel = 1'b0;
                        ARF_RegSel  = 3'b011;
                        ARF_FunSel  = 3'b001;
                        T_Reset     = 1'b1;
                    end
                end

                // ----- CALL (0x1A) -----
                6'h1A: begin
                    if (T[2]) begin
                        ARF_OutCSel = 2'b00;
                        MuxA_ALU    = 1'b1;
                        ALU_FunSel  = 5'h00;
                        ARF_OutDSel = 2'b11;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b1;
                        DMU_DataSel = 1'b1;
                        ARF_RegSel  = 3'b011;
                        ARF_FunSel  = 3'b001;
                    end
                    else if (T[3]) begin
                        ARF_OutCSel = 2'b00;
                        MuxA_ALU    = 1'b1;
                        ALU_FunSel  = 5'h00;
                        ARF_OutDSel = 2'b11;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b1;
                        DMU_DataSel = 1'b0;
                        ARF_RegSel  = 3'b011;
                        ARF_FunSel  = 3'b001;
                    end
                    else if (T[4]) begin
                        ARF_RegSel = 3'b110;
                        ARF_FunSel = 3'b011;
                        MuxBSel    = 2'b10;
                        T_Reset    = 1'b1;
                    end
                end

                // ----- RET (0x1B) -----
                6'h1B: begin
                    if (T[2]) begin
                        ARF_RegSel = 3'b011;
                        ARF_FunSel = 3'b010;
                    end
                    else if (T[3]) begin
                        ARF_OutDSel = 2'b11;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b0;
                        ARF_RegSel  = 3'b110;
                        ARF_FunSel  = 3'b101;
                        MuxBSel     = 2'b01;
                    end
                    else if (T[4]) begin
                        ARF_RegSel = 3'b011;
                        ARF_FunSel = 3'b010;
                    end
                    else if (T[5]) begin
                        ARF_OutDSel = 2'b11;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b0;
                        ARF_RegSel  = 3'b110;
                        ARF_FunSel  = 3'b110;
                        MuxBSel     = 2'b01;
                        T_Reset     = 1'b1;
                    end
                end

                // ----- LDR (0x1C) -----
                6'h1C: begin
                    if (T[2]) begin
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b0;
                        // Destination assumed to be in RF (tests only use Rx)
                        RF_RegSel   = dst_to_rf_regsel(DestReg);
                        RF_FunSel   = 3'b100;       // load LSB, clear MSB
                        MuxASel     = 2'b01;
                        ARF_RegSel  = 3'b101;       // AR++
                        ARF_FunSel  = 3'b010;
                    end
                    else if (T[3]) begin
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b0;
                        RF_RegSel   = dst_to_rf_regsel(DestReg);
                        RF_FunSel   = 3'b110;
                        MuxASel     = 2'b01;
                        T_Reset     = 1'b1;
                    end
                end

                // ----- STR (0x1D) -----
                6'h1D: begin
                    if (T[2]) begin
                        if (SrcReg1[2] == 1'b0) begin
                            MuxA_ALU    = 1'b1;
                            ARF_OutCSel = src_to_arf_outsel(SrcReg1);
                        end else begin
                            MuxA_ALU    = 1'b0;
                            RF_OutASel  = rsel_to_outsel(SrcReg1[1:0]);
                        end
                        ALU_FunSel  = 5'h00;
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b1;
                        DMU_DataSel = 1'b0;
                        ARF_RegSel  = 3'b101;
                        ARF_FunSel  = 3'b010;
                    end
                    else if (T[3]) begin
                        if (SrcReg1[2] == 1'b0) begin
                            MuxA_ALU    = 1'b1;
                            ARF_OutCSel = src_to_arf_outsel(SrcReg1);
                        end else begin
                            MuxA_ALU    = 1'b0;
                            RF_OutASel  = rsel_to_outsel(SrcReg1[1:0]);
                        end
                        ALU_FunSel  = 5'h00;
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b1;
                        DMU_DataSel = 1'b1;
                        T_Reset     = 1'b1;
                    end
                end

                // ----- LDA (0x1E) -----
                6'h1E: begin
                    if (T[2]) begin
                        ARF_RegSel = 3'b101;
                        ARF_FunSel = 3'b011;
                        MuxBSel    = 2'b10;
                    end
                    else if (T[3]) begin
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b0;
                        RF_RegSel   = rsel_to_regsel(RegSel);
                        RF_FunSel   = 3'b100;
                        MuxASel     = 2'b01;
                        ARF_RegSel  = 3'b101;
                        ARF_FunSel  = 3'b010;
                    end
                    else if (T[4]) begin
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b0;
                        RF_RegSel   = rsel_to_regsel(RegSel);
                        RF_FunSel   = 3'b110;
                        MuxASel     = 2'b01;
                        T_Reset     = 1'b1;
                    end
                end

                // ----- STA (0x1F) -----
                6'h1F: begin
                    if (T[2]) begin
                        ARF_RegSel = 3'b101;
                        ARF_FunSel = 3'b011;
                        MuxBSel    = 2'b10;
                    end
                    else if (T[3]) begin
                        RF_OutASel  = rsel_to_outsel(RegSel);
                        MuxA_ALU    = 1'b0;
                        ALU_FunSel  = 5'h00;
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b1;
                        DMU_DataSel = 1'b0;
                        ARF_RegSel  = 3'b101;
                        ARF_FunSel  = 3'b010;
                    end
                    else if (T[4]) begin
                        RF_OutASel  = rsel_to_outsel(RegSel);
                        MuxA_ALU    = 1'b0;
                        ALU_FunSel  = 5'h00;
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b1;
                        DMU_DataSel = 1'b1;
                        T_Reset     = 1'b1;
                    end
                end

                // ----- LDT (0x20) -----
                //   T2 : AR <- AR + IR[7:0]
                //   T3 : Rx.LSB <- M[AR] ; AR++
                //   T4 : Rx.MSB <- M[AR] ; T_Reset
                6'h20: begin
                    if (T[2]) begin
                        ARF_OutCSel = 2'b10;          // AR -> ALU.A
                        MuxA_ALU    = 1'b1;
                        MuxB_ALU    = 2'b01;          // {0, IR[7:0]} -> ALU.B
                        ALU_FunSel  = 5'h0E;          // A + B
                        ARF_RegSel  = 3'b101;         // AR
                        ARF_FunSel  = 3'b011;         // load
                        MuxBSel     = 2'b00;          // ALUOut
                    end
                    else if (T[3]) begin
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b0;
                        RF_RegSel   = rsel_to_regsel(RegSel);
                        RF_FunSel   = 3'b100;
                        MuxASel     = 2'b01;
                        ARF_RegSel  = 3'b101;
                        ARF_FunSel  = 3'b010;
                    end
                    else if (T[4]) begin
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b0;
                        RF_RegSel   = rsel_to_regsel(RegSel);
                        RF_FunSel   = 3'b110;
                        MuxASel     = 2'b01;
                        T_Reset     = 1'b1;
                    end
                end

                // ----- STT (0x21) -----
                //   T2 : AR <- AR + IR[7:0]
                //   T3 : M[AR] <- LSB(Rx) ; AR++
                //   T4 : M[AR] <- MSB(Rx) ; T_Reset
                6'h21: begin
                    if (T[2]) begin
                        ARF_OutCSel = 2'b10;
                        MuxA_ALU    = 1'b1;
                        MuxB_ALU    = 2'b01;
                        ALU_FunSel  = 5'h0E;
                        ARF_RegSel  = 3'b101;
                        ARF_FunSel  = 3'b011;
                        MuxBSel     = 2'b00;
                    end
                    else if (T[3]) begin
                        RF_OutASel  = rsel_to_outsel(RegSel);
                        MuxA_ALU    = 1'b0;
                        ALU_FunSel  = 5'h00;
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b1;
                        DMU_DataSel = 1'b0;
                        ARF_RegSel  = 3'b101;
                        ARF_FunSel  = 3'b010;
                    end
                    else if (T[4]) begin
                        RF_OutASel  = rsel_to_outsel(RegSel);
                        MuxA_ALU    = 1'b0;
                        ALU_FunSel  = 5'h00;
                        ARF_OutDSel = 2'b10;
                        DMU_CS      = 1'b0;
                        DMU_WR      = 1'b1;
                        DMU_DataSel = 1'b1;
                        T_Reset     = 1'b1;
                    end
                end

                default: T_Reset = 1'b1;
            endcase
        end
    end
endmodule

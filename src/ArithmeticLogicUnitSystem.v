`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Project Name: BLG222E Project 3
// Module: ArithmeticLogicUnitSystem
//
// Top-level data-path: RF + ARF + ALU + IMU + DMU.
// ARF.OutC feeds the instruction memory address (used for PC during fetch).
// ARF.OutD feeds the data memory address (used for AR/SP during data ops).
//////////////////////////////////////////////////////////////////////////////////

module ArithmeticLogicUnitSystem(
    input  wire        Clock,

    // Register File controls
    input  wire [2:0]  RF_FunSel,
    input  wire [3:0]  RF_RegSel,
    input  wire [3:0]  RF_ScrSel,
    input  wire [2:0]  RF_OutASel,
    input  wire [2:0]  RF_OutBSel,

    // Address Register File controls
    input  wire [2:0]  ARF_FunSel,
    input  wire [2:0]  ARF_RegSel,
    input  wire [1:0]  ARF_OutCSel,
    input  wire [1:0]  ARF_OutDSel,

    // ALU controls
    input  wire [4:0]  ALU_FunSel,
    input  wire        ALU_WF,

    // Mux controls
    input  wire [1:0]  MuxASel,    // RF input source
    input  wire [1:0]  MuxBSel,    // ARF input source
    input  wire        MuxA_ALU,   // ALU A source: 0=RF.OutA, 1=ARF.OutC
    input  wire [1:0]  MuxB_ALU,   // ALU B source: 00=RF.OutB, 01={0,IR[7:0]}, 10=ARF.OutD, 11=16'h0001
    input  wire        DMU_DataSel,// 0=LSB(ALUOut), 1=MSB(ALUOut)

    // IMU / DMU controls
    input  wire        IR_Enable,
    input  wire        IR_LH,
    input  wire        IMU_CS,
    input  wire        DMU_CS,
    input  wire        DMU_WR,
    input  wire [1:0]  DR_FunSel,

    output wire [15:0] IROut,
    output wire [15:0] ALUOut,
    output wire [3:0]  Flags
);
    // Internal RF/ARF outputs
    wire [15:0] RF_OutA, RF_OutB;
    wire [15:0] ARF_OutC, ARF_OutD;

    // Internal data signals
    wire [7:0]  DM_MemOut;
    wire [15:0] DR_Out;
    wire [15:0] ir_internal;
    wire [15:0] alu_out_internal;
    wire [3:0]  flags_internal;

    reg  [15:0] RF_I;
    reg  [15:0] ARF_I;
    reg  [7:0]  DMU_Data;
    wire [15:0] alu_a_in;
    wire [15:0] alu_b_in;

    assign IROut  = ir_internal;
    assign ALUOut = alu_out_internal;
    assign Flags  = flags_internal;

    // Register File
    RegisterFile RF(
        .Clock(Clock),
        .I(RF_I),
        .FunSel(RF_FunSel),
        .RegSel(RF_RegSel),
        .ScrSel(RF_ScrSel),
        .OutASel(RF_OutASel),
        .OutBSel(RF_OutBSel),
        .OutA(RF_OutA),
        .OutB(RF_OutB)
    );

    // Address Register File
    AddressRegisterFile ARF(
        .Clock(Clock),
        .I(ARF_I),
        .FunSel(ARF_FunSel),
        .RegSel(ARF_RegSel),
        .OutCSel(ARF_OutCSel),
        .OutDSel(ARF_OutDSel),
        .OutC(ARF_OutC),
        .OutD(ARF_OutD)
    );

    // ALU inputs
    assign alu_a_in = MuxA_ALU ? ARF_OutC : RF_OutA;
    assign alu_b_in = (MuxB_ALU == 2'b00) ? RF_OutB :
                      (MuxB_ALU == 2'b01) ? {8'h00, ir_internal[7:0]} :
                      (MuxB_ALU == 2'b10) ? ARF_OutD :
                                            16'h0001;

    ArithmeticLogicUnit ALU(
        .Clock(Clock),
        .A(alu_a_in),
        .B(alu_b_in),
        .FunSel(ALU_FunSel),
        .WF(ALU_WF),
        .ALUOut(alu_out_internal),
        .FlagsOut(flags_internal)
    );

    // Instruction Memory Unit (address = ARF.OutC, usually PC)
    InstructionMemoryUnit IMU(
        .Clock(Clock),
        .Address(ARF_OutC),
        .CS(IMU_CS),
        .IR_Enable(IR_Enable),
        .IR_LH(IR_LH),
        .IROut(ir_internal)
    );

    // Data Memory Unit (address = ARF.OutD, usually AR/SP)
    DataMemoryUnit DMU(
        .Clock(Clock),
        .Address(ARF_OutD),
        .Data(DMU_Data),
        .WR(DMU_WR),
        .CS(DMU_CS),
        .DR_FunSel(DR_FunSel),
        .DROut(DR_Out),
        .MemOut(DM_MemOut)
    );

    // Input muxes
    always @(*) begin
        case (MuxASel)
            2'b00: RF_I = alu_out_internal;
            2'b01: RF_I = {8'h00, DM_MemOut};
            2'b10: RF_I = {8'h00, ir_internal[7:0]};
            2'b11: RF_I = DR_Out;
        endcase
        case (MuxBSel)
            2'b00: ARF_I = alu_out_internal;
            2'b01: ARF_I = {8'h00, DM_MemOut};
            2'b10: ARF_I = {8'h00, ir_internal[7:0]};
            2'b11: ARF_I = DR_Out;
        endcase
        case (DMU_DataSel)
            1'b0: DMU_Data = alu_out_internal[7:0];
            1'b1: DMU_Data = alu_out_internal[15:8];
        endcase
    end
endmodule

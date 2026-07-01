`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Engineer:
// Project Name: BLG222E Project 2 Simulation
//////////////////////////////////////////////////////////////////////////////////


module CPUSystemSimulationFactorial();
    wire [11:0] T;
    integer test_no;
    integer clock_count;
    wire clock;
    wire reset;

    wire[5:0] Opcode;
    wire[1:0] RegSel;
    wire[7:0] Address;
    wire[2:0] DestReg;
    wire[2:0] SrcReg1;
    wire[2:0] SrcReg2;

    CrystalOscillator clk();
    ResetGenerator rg();

    CPUSystem CPUSys(
        .Clock(clk.clock),
        .Reset(rg.reset),
        .T(T) 
    ); 
    FileOperation F();
    
    assign clock = clk.clock;
    assign reset = rg.reset;
    
    task ClearRegisters;
        begin
            clock_count = 0;
            CPUSys.ALUSys.RF.R1.Q = 32'h0;
            CPUSys.ALUSys.RF.R2.Q = 32'h0;
            CPUSys.ALUSys.RF.R3.Q = 32'h0;
            CPUSys.ALUSys.RF.R4.Q = 32'h0;
            CPUSys.ALUSys.RF.S1.Q = 32'h0;
            CPUSys.ALUSys.RF.S2.Q = 32'h0;
            CPUSys.ALUSys.RF.S3.Q = 32'h0;
            CPUSys.ALUSys.RF.S4.Q = 32'h0;
            CPUSys.ALUSys.ARF.PC.Q = 16'h0;
            CPUSys.ALUSys.ARF.AR.Q = 16'h0;
            CPUSys.ALUSys.ARF.SP.Q = 16'h00FF;
            CPUSys.ALUSys.DMU.DR.DROut = 16'h0;
            CPUSys.ALUSys.IMU.IR.IROut = 16'h0;
            CPUSys.ALUSys.ALU.FlagsOut = 4'b0000;
        end
    endtask

    task DisableAll;
        begin
            CPUSys.RF_RegSel = 4'b1111;
            CPUSys.RF_ScrSel = 4'b1111;
            CPUSys.ARF_RegSel = 3'b111;
            CPUSys.ALU_WF = 0;
            CPUSys.IMU_CS = 0;
            CPUSys.DMU_CS = 0;
            CPUSys.T_Reset = 1;
        end
    endtask

    task ResetT;
        begin
            CPUSys.T_Reset = 1;
        end
    endtask
    
    assign Opcode = CPUSys.Opcode;
    assign RegSel = CPUSys.RegSel;
    assign Address = CPUSys.Address;
    assign DestReg = CPUSys.DestReg;
    assign SrcReg1 = CPUSys.SrcReg1;
    assign SrcReg2 = CPUSys.SrcReg2;
    
    initial begin
        F.SimulationName ="CPUSystemSimulationFactorial";
        F.InitializeSimulation(0);
        clk.clock = 0;

        test_no = 1;
        DisableAll();
        ClearRegisters();
        
        // Code to calculate Factorial
        //              IMM     R2, 0x01    # AA 0x5D01     # R2 is used for the result (Initialize to 1)
        //              IMM     R1, 0x04    # AC 0x5C04     # R1 is used for iteration number (Calculate 4!)
        //              IMM     R3, 0x00    # AE 0x5E00     # R3 is used to update flags
        //              ADD     R1, R1, R3  # B0 0x4E4C     # to pass R1 through ALU
        //              CALL    FACTORIAL   # B2 0x68B8
        //              STA     R2, 0x54 	# B4 0x7D54     # M[ADDRESS] ← R2
        //              BRA     FINISH      # B6 0x00D8
        // FACTORIAL    BEQ     END_F       # B8 0x08CA     # If R1 == 0, return
        //              IMM     R3, 0x01    # BA 0x5E01
        //              SUB     R3, R1, R3  # BC 0x574C     # R3 <- R1 - 1
        //              BEQ     END_F       # BE 0x08CA     # If R1 == 1, return
        //              PSH     R1          # C0 0x6400     # Save current R1 to stack
        //              DEC     R1, R1      # C2 0x2240     # R1 <- R1 - 1
        //              CALL    FACTORIAL   # C4 0x68B8     # recursive
        //              POP     R4          # C6 0x6300     # Restore previous R1 from stack
        //              CALL    MULTIPLY    # C8 0x68CC
        // END_F		RET                 # CA 0x6C00
        // MULTIPLY	    MOV     R3, R2      # CC 0x5B50     # for R2 ← R2*R4
        //              DEC     R4, R4      # CE 0x23F0
        // M_LOOP	    ADD     R2, R2, R3  # D0 0x4EDC     # R4 times R2 ← R2 + R3
        //              DEC     R4, R4      # D2 0x23F0
        //              BNE     M_LOOP      # D4 0x04D0
        //              RET	                # D6 0x6C00
        // FINISH                           # D8 NOOP

        CPUSys.ALUSys.ARF.PC.Q = 16'h00AA;
        CPUSys.T = 12'b0000_0000_0001;
        
        while (test_no <= 69 && clock_count <= 1500) begin
            clk.Clock();
            clock_count = clock_count + 1;
            if (CPUSys.T == 12'b0000_0000_0001)
                test_no = test_no + 1;
        end
        
        test_no = 70;
        F.CheckValues(CPUSys.ALUSys.IROut,16'h00D8, test_no, "IROut");

        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h00D8, test_no, "PC");
        F.CheckValues(CPUSys.ALUSys.ARF.SP.Q, 16'h00FF, test_no, "SP");
        F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'h0055, test_no, "AR");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'h54],8'h18, test_no, "MEM[ADDRESS]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'h55],8'h00, test_no, "MEM[ADDRESS]");

        F.CheckValues(CPUSys.ALUSys.RF.R1.Q,16'h0001, test_no, "R1");
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q,16'h0018, test_no, "R2");
        F.CheckValues(CPUSys.ALUSys.RF.R3.Q,16'h0006, test_no, "R3");
        F.CheckValues(CPUSys.ALUSys.RF.R4.Q,16'h0000, test_no, "R4");

        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hF2],8'hC6, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hF3],8'h00, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hF4],8'hCA, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hF5],8'h00, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hF6],8'hC6, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hF7],8'h00, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hF8],8'hCA, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hF9],8'h00, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFA],8'hC6, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFB],8'h00, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFC],8'hCA, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFD],8'h00, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFE],8'hB4, test_no, "MEM[SP]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFF],8'h00, test_no, "MEM[SP]");

        F.FinishSimulation();
    end

endmodule
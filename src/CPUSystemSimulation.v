`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ITU Computer Engineering Department
// Engineer:
// Project Name: BLG222E Project 2 Simulation
//////////////////////////////////////////////////////////////////////////////////


module CPUSystemSimulation();
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
            CPUSys.ALUSys.RF.R1.Q = 16'h0;
            CPUSys.ALUSys.RF.R2.Q = 16'h0;
            CPUSys.ALUSys.RF.R3.Q = 16'h0;
            CPUSys.ALUSys.RF.R4.Q = 16'h0;
            CPUSys.ALUSys.RF.S1.Q = 16'h0;
            CPUSys.ALUSys.RF.S2.Q = 16'h0;
            CPUSys.ALUSys.RF.S3.Q = 16'h0;
            CPUSys.ALUSys.RF.S4.Q = 16'h0;
            CPUSys.ALUSys.ARF.PC.Q = 16'h0;
            CPUSys.ALUSys.ARF.AR.Q = 16'h0;
            CPUSys.ALUSys.ARF.SP.Q = 16'h00FF;
            CPUSys.ALUSys.ALU.FlagsOut = 4'b0000;
            CPUSys.ALUSys.DMU.DR.DROut = 16'h0;
            CPUSys.ALUSys.IMU.IR.IROut = 16'h0;

        end
    endtask
        
    task SetRegisters;
        input [15:0] value;
        begin
            CPUSys.ALUSys.ARF.PC.Q = value;
            CPUSys.ALUSys.ARF.AR.Q = value;
            CPUSys.ALUSys.ARF.SP.Q = value;
            CPUSys.ALUSys.RF.R1.Q = value;
            CPUSys.ALUSys.RF.R2.Q = value;
            CPUSys.ALUSys.RF.R3.Q = value;
            CPUSys.ALUSys.RF.R4.Q = value;
            CPUSys.ALUSys.RF.S1.Q = value;
            CPUSys.ALUSys.RF.S2.Q = value;
            CPUSys.ALUSys.RF.S3.Q = value;
            CPUSys.ALUSys.RF.S4.Q = value;
            CPUSys.ALUSys.DMU.DR.DROut = 16'h0;
            CPUSys.ALUSys.IMU.IR.IROut = 16'h0;
        end
    endtask

    task SetALUFlags;
        input [3:0] value;
        begin
            CPUSys.ALUSys.ALU.FlagsOut = value;
        end
    endtask

    task SetRegistersRx;
        begin
            CPUSys.ALUSys.RF.R1.Q = 16'h2312;
            CPUSys.ALUSys.RF.R2.Q = 16'h6789;
            CPUSys.ALUSys.RF.R3.Q = 16'h8894;
            CPUSys.ALUSys.RF.R4.Q = 16'hF210;
        end
    endtask

    task SetPC;
        input [15:0] value;
        begin
            CPUSys.ALUSys.ARF.PC.Q = value;
        end
    endtask	

    task SetSP;
        input [15:0] value;
        begin
            CPUSys.ALUSys.ARF.SP.Q = value;
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
        F.SimulationName ="CPUSystemSimulation";
        F.InitializeSimulation(0);
        clk.clock = 0;

        //Test 1 PUSH R1
        test_no = 1;
        ClearRegisters();
        SetRegistersRx();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h6400;
        CPUSys.T = 12'b0000_0000_0100; // Set T to 4
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFE],8'h12, test_no, "MEM[SP, FE]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFF],8'h23, test_no, "MEM[SP, FF]");
        F.CheckValues(CPUSys.ALUSys.ARF.SP.Q, 16'h00FD, test_no, "SP");

        //Test 2 POP R2
        test_no = 2;
        ClearRegisters();
        SetRegistersRx();
        CPUSys.ALUSys.ARF.SP.Q = 16'h00FD;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h6100;
        CPUSys.T = 12'b0000_0000_0100; // Set T to 4
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFE],8'h12, test_no, "MEM[SP,FE]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFF],8'h23, test_no, "MEM[SP,FF]");
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h2312, test_no, "R1");
        F.CheckValues(CPUSys.ALUSys.ARF.SP.Q, 16'h00FF, test_no, "SP"); 
        
        //Test 3 CALL 0x36
        test_no = 3;
        ClearRegisters();
        SetPC(16'h006E);
        SetSP(16'h00FD);
        clk.Clock();
        while (CPUSys.T != 11'h1 && clock_count <= 15)  
        begin
			clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0036, test_no, "PC");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFC],8'h70, test_no, "MEM[SP,FC]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hFD],8'h00, test_no, "MEM[SP,FD]");
        F.CheckValues(CPUSys.ALUSys.ARF.SP.Q, 16'h00FB, test_no, "SP");

        //Test 4 RET
        test_no = 4;
        ClearRegisters();
        SetPC(16'h0070);
        SetSP(16'h00FB);
        clk.Clock();
        while (CPUSys.T != 11'h1 && clock_count <= 15)  
        begin
			clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0070, test_no, "PC");
        F.CheckValues(CPUSys.ALUSys.ARF.SP.Q, 16'h00FD, test_no, "SP");

        //Test 5 LDR R2
        test_no = 5;
        ClearRegisters();
        CPUSys.ALUSys.ARF.AR.Q = 16'h0006;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h7280;                
        CPUSys.T = 12'b0000_0000_0100;
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'h0007, test_no, "AR");
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0703, test_no, "R2");
        
        //Test 6 STR PC
        test_no = 6;
        ClearRegisters();
        SetRegistersRx();
        CPUSys.ALUSys.ARF.PC.Q = 16'h1122;
        CPUSys.ALUSys.ARF.AR.Q = 16'h0014;
        CPUSys.ALUSys.IMU.IR.IROut = 16'h7400;
        CPUSys.T = 12'b0000_0000_0100;
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'h0015, test_no, "AR");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'h14],8'h22, test_no, "MEM[AR,14]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'h15],8'h11, test_no, "MEM[AR,15]");

        //Test 7 LDA R4 0x20
        test_no = 7;
        ClearRegisters();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h7B20;
        CPUSys.T = 12'b0000_0000_0100;
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'h0021, test_no, "AR");
        F.CheckValues(CPUSys.ALUSys.RF.R4.Q, 16'h1405, test_no, "R4");

        //Test 8 STA R2 0xA8
        test_no = 8;
        ClearRegisters();
        SetRegistersRx();
        CPUSys.ALUSys.IMU.IR.IROut = 16'h7DA8;
        CPUSys.T = 12'b0000_0000_0100;
        while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
            clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'h00A9, test_no, "AR");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hA8],8'h89, test_no, "MEM[AR,A8]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hA9],8'h67, test_no, "MEM[AR,A9]");

        //Test 9 LDT R2 0x10
        test_no = 9;
        ClearRegisters();
        SetPC(16'h0084);
        CPUSys.ALUSys.RF.R2.Q = 16'h0000;
        CPUSys.ALUSys.ARF.AR.Q = 16'h0006;
        clk.Clock();
        while (CPUSys.T != 11'h1 && clock_count <= 15)  
        begin
			clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'h0017, test_no, "AR");
        F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0703, test_no, "R2");
        
        //Test 10 STT R1 0x01
        test_no = 10;
        ClearRegisters();
        SetPC(16'h008A);
        CPUSys.ALUSys.ARF.AR.Q = 16'h00C0;
        CPUSys.ALUSys.RF.R1.Q = 16'h0011;
        clk.Clock();
        while (CPUSys.T != 11'h1 && clock_count <= 15)  
        begin
			clk.Clock();
            clock_count = clock_count + 1;
        end
        F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'h00C2, test_no, "AR");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hC1],8'h11, test_no, "MEM[AR,C1]");
        F.CheckValues(CPUSys.ALUSys.DMU.DM.RAM_DATA[8'hC2],8'h00, test_no, "MEM[AR,C2]");

        F.FinishSimulation();
    end

endmodule
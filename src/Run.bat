call C:\Xilinx\Vivado\2017.4\settings64.bat

set folder=Simulation_Files
mkdir %folder%
copy "RAM.mem" "%folder%/RAM.mem"
copy "ROM.mem" "%folder%/ROM.mem"
cd "%folder%

::CPU System Simulation
call xvlog ../Register16bit.v  
call xvlog ../RegisterFile.v
call xvlog ../AddressRegisterFile.v  
call xvlog ../InstructionRegister.v
call xvlog ../DataRegister.v  
call xvlog ../ArithmeticLogicUnit.v
call xvlog ../InstructionMemory.v
call xvlog ../InstructionMemoryUnit.v
call xvlog ../DataMemory.v
call xvlog ../DataMemoryUnit.v
call xvlog ../ArithmeticLogicUnitSystem.v  
call xvlog ../CPUSystem.v
call xvlog ../CPUSystemSimulation.v
call xvlog ../Helper.v

call xelab -top CPUSystemSimulation -snapshot cpusyssim -debug typical
call xsim cpusyssim -R

::CPU System Simulation Factorial
call xvlog ../Register16bit.v  
call xvlog ../RegisterFile.v
call xvlog ../AddressRegisterFile.v  
call xvlog ../InstructionRegister.v
call xvlog ../DataRegister.v  
call xvlog ../ArithmeticLogicUnit.v
call xvlog ../InstructionMemory.v
call xvlog ../InstructionMemoryUnit.v
call xvlog ../DataMemory.v
call xvlog ../DataMemoryUnit.v
call xvlog ../ArithmeticLogicUnitSystem.v  
call xvlog ../CPUSystem.v
call xvlog ../CPUSystemSimulationFactorial.v
call xvlog ../Helper.v

call xelab -top CPUSystemSimulationFactorial -snapshot cpusyssimfact -debug typical
call xsim cpusyssimfact -R

cd ..
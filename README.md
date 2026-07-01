# Basic Computer (CPU) — Design & Simulation in Verilog

> ITU **BLG222E – Computer Organization**, Homework 3

This project is a simple computer (CPU) designed from scratch using the **Verilog
Hardware Description Language (HDL)**. Instead of manufacturing a physical chip, the
processor's digital circuit is described in code and run in a simulator to verify that
the **fetch → decode → execute** cycle works correctly.

In short: a microprocessor is built at the circuit level and tested by running it virtually.

---

## Architecture

The design is layered: the control unit sits on top, the datapath below it, and the
building blocks beneath that.

| Component | Role |
|---|---|
| `Register16bit.v` | Basic 16-bit register (load / increment / decrement) |
| `RegisterFile.v` | General-purpose registers: R1–R4 and scratch S1–S4 |
| `AddressRegisterFile.v` | Address registers: PC (Program Counter), AR (Address Register), SP (Stack Pointer) |
| `ArithmeticLogicUnit.v` | Arithmetic/logic operations + flags (Z, C, N, O) |
| `InstructionRegister.v` / `InstructionMemory.v` / `InstructionMemoryUnit.v` | Instruction register and instruction memory (ROM) |
| `DataRegister.v` / `DataMemory.v` / `DataMemoryUnit.v` | Data register and data memory (RAM) |
| `ArithmeticLogicUnitSystem.v` | Datapath: combines RF + ARF + ALU + IMU + DMU through muxes |
| `CPUSystem.v` | Hardwired control unit — decodes instructions and drives micro-steps via the time counter (T) |
| `Helper.v` | Testbench helpers (clock generator, reset generator, file/report operations) |

### Supported instructions (ISA)
- **Branches:** BRA, BNE, BEQ, BGT, BGE, BLT, BLE (conditional / unconditional)
- **Arithmetic/Logic:** ADD, SUB, AND, OR, XOR, NOT, LSL, LSR, etc.
- **Data movement:** MOV, LD (load), ST (store), LDR/STR, LDA/STA, LDT/STT
- **Stack / function:** PUSH, POP, CALL, RET

The instruction memory (`ROM.mem`) and data memory (`RAM.mem`) are loaded from hex-format `.mem` files.

---

## Simulations (Tests)

There are two independent testbenches:

1. **`CPUSystemSimulation.v`** — Verifies instructions one by one
   (PUSH, POP, CALL, RET, LDR, STR, LDA, STA, LDT, STT).
   → **28 checks**

2. **`CPUSystemSimulationFactorial.v`** — Runs a real **factorial program** loaded into
   ROM from start to finish (using recursive CALL/RET) and verifies the result `4! = 24 (0x18)`.
   → **24 checks**

Each testbench prints results as `[PASS]/[FAIL]` to the console and produces
`evaluation.csv` and `debug.txt`. The `expected-output/` folder contains the expected
reference output.

### What is `evaluation.csv`?
It is the **machine-readable test report** produced by the simulation (written by
[Helper.v](src/Helper.v)). Each line represents one check; the semicolon-separated columns are:

```
module_name ; testno ; test_name ; passed ; actual_value ; expected_value
```

- **passed** → `1` = passed, `0` = failed
- **actual_value** → value produced by the design, **expected_value** → the expected value

Example line: `CPUSystemSimulation;1;SP;1;0x00fd;0x00fd`
(In test 1, the SP register produced the expected `0x00fd` → passed.) This file lets you
see the pass/fail status of every test at a glance and enables automated grading.

---

## Requirements

The project can be run in one of two ways:

### A) Icarus Verilog (recommended, cross-platform)
- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog` + `vvp`)

macOS: `brew install icarus-verilog`
Ubuntu/Debian: `sudo apt install iverilog`

### B) Xilinx Vivado (Windows)
- Vivado 2017.4 (xvlog / xelab / xsim), via the ready-made `src/Run.bat` script.

---

## Running / Testing

### With Icarus Verilog

The source files are in the `src/` folder. The `.mem` files must be in the working
directory, so the simulation is run from inside that folder.
The commands below work in both `bash` and `zsh`:

```bash
cd src

# 1) Instruction tests
iverilog -g2012 -o sim1 \
  Register16bit.v RegisterFile.v AddressRegisterFile.v InstructionRegister.v \
  DataRegister.v ArithmeticLogicUnit.v InstructionMemory.v InstructionMemoryUnit.v \
  DataMemory.v DataMemoryUnit.v ArithmeticLogicUnitSystem.v CPUSystem.v Helper.v \
  CPUSystemSimulation.v
vvp sim1

# 2) Factorial program test
iverilog -g2012 -o sim2 \
  Register16bit.v RegisterFile.v AddressRegisterFile.v InstructionRegister.v \
  DataRegister.v ArithmeticLogicUnit.v InstructionMemory.v InstructionMemoryUnit.v \
  DataMemory.v DataMemoryUnit.v ArithmeticLogicUnitSystem.v CPUSystem.v Helper.v \
  CPUSystemSimulationFactorial.v
vvp sim2
```

Expected output (example):

```
CPUSystemSimulation Simulation Finished
0 Test Failed
28 Test Passed
```

```
CPUSystemSimulationFactorial Simulation Finished
0 Test Failed
24 Test Passed
```

> Note: The `$readmemh ... Not enough words in the file` warning is normal — the memory
> files do not fill the entire address space; the unused addresses are irrelevant and do
> not affect the tests.

### With Xilinx Vivado (Windows)

```bat
cd src
Run.bat
```

---

## Directory Structure

```
.
├── src/                    # All Verilog sources + memory files
│   ├── *.v                 # Design and testbench modules
│   ├── ROM.mem / RAM.mem   # Instruction and data memory contents
│   └── Run.bat             # Run script for Vivado
├── expected-output/        # Expected reference output (debug.txt, evaluation.csv)
└── README.md
```

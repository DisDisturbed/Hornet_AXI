# 🐝 Hornet SoC (AXI4-Full Experimental Branch)



>  **ACADEMIC / LEARNING PROJECT**  

> This repository represents a **work in progress** developed by a 3rd-year undergraduate student.  

> It is an experimental attempt to integrate the **Hornet RISC-V core** with an **AXI4-Full interconnect**.  

> The code is **unstable** and provided strictly for **educational and feedback purposes**.



---



## 📌 Project Overview



The **Hornet SoC** is a 32-bit RISC-V SoC design targeting FPGA implementation.  

The primary objective of this experimental branch is to replace the original Hornet core’s simple wishbone bus interface with a standards-compliant **AXI4-Full interconnect**. This enables higher bandwidth memory access, DMA-style transactions, and standardized communication with modern IP cores.





---

## 🏗️ System Architecture



```mermaid

graph TD

    subgraph Masters

        Core_I[Hornet Core (Instruction)] --> Crossbar

        Core_D[Hornet Core (Data)] --> Crossbar

    end



    subgraph Interconnect

        Crossbar[AXI4-Full Crossbar]

    end



    subgraph Slaves

        Crossbar --> BRAM[Block RAM]

        Crossbar --> UART[UART Controller]

        Crossbar --> GPIO[GPIO]

    end

```



---



## 🚧 Current Status & Known Issues



**Current State:** ❌ **DEBUGGING / UNSTABLE**



This is an active development branch. The following issues are currently known:



| Component     | Status        | Notes                                                                 |

|---------------|---------------|-----------------------------------------------------------------------|

| CSR Unit      | 🔴 Critical   | Data_req_o is breaking the fsm on back to back transmitions           |

| Bubble Sort   | 🟠 Failing    | Basic load/store works; complex benchmarks fail                       |

| UART          | 🟡 Untested   | Integrated but not fully verified against AXI master                  |



---



## 📂 Repository Structure



```text

.

├── RTL/                       # Hardware Description (SystemVerilog)

│   ├── core/                  # Hornet core (pipeline, control, CSR)

│   ├── fpu/                   # Floating-point unit

│   ├── axi/                   # AXI crossbar, interconnects, wrappers

│   └── peripherals/           # UART, GPIO, memory controllers

│

└── Test_codes/                # Software build chain

    ├── main.c                 # C test programs and benchmarks

    ├── crt0.s                 # Startup assembly (stack initialization)

    ├── linksc.ld              # Linker script (memory map)

    └── Makefile               # RISC-V GNU toolchain build script

```



---



## 🚀 Getting Started



### Prerequisites



- **Simulation:** Vivado Simulator (XSim) or Verilator  

- **Toolchain:** `riscv32-unknown-elf-gcc` (with RV32 support via `-march=rv32imf`)



### 1. Compile the Software



```bash

cd Test_codes

make

```



This generates `.hex` files used by the Verilog `$readmemh` mechanism.



### 2. Run the Simulation



The SystemVerilog testbench `Wrapper_test_sv_tb.sv` expects the firmware hex file to be present in the simulation directory.



---



## 🤝 Acknowledgements & Credits



- **Hornet RISC-V Core:**  

  Originally developed by the **Istanbul Technical University Embedded Systems Laboratory**.  

  This repository contains an experimental modification of the bus/interconnect layer only.



- **Verilog AXI:**  

  AXI infrastructure based on the open-source library by **Alex Forencich**.



---



## 📜 License



MIT License.  

See the `LICENSE` file for details.

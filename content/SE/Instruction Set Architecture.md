---
title: "Instruction Set Architecture"
date: 2021-08-29T10:40:38+02:00
draft: false
weight: 60
categories:
  - "SE"
tags:
  - "SE"
---
## Instruction Set Architecture
Around 1950, as the demand for more powerful, faster processors was growing, one engineer, faced with the increasingly complex and error-prone task of designing new processors, had a great thought: create a simple, more reliable 'CPU' which simulates more complex processors.

How can chip manufacturers continue to innovate complex CPU's while computer designers, operating system vendors and compiler developers continue to use and expand upon existing software for the 'older' CPU's? 

* An Instruction Set Architecture is an abstract model of a CPU. Software can be written for the abstract model, and any actual CPU that implements the model will be able to execute the code.
* A microarchitecture is the most complex digital logic component. Its purpose is to simulate the ISA. You may know some microarchitectures by name: Intel: Nehalem, Haswell, Skylake, Kaby Lake, Snapdragon:Kryo, Nvidea:Denver.

In order to understand the microarchitecture, it is necessary to understand its context: the ISA it must emulate.

Two well known ISA models are **x86** and **ARM**.

**x86** is a family of models dating back to 1978, when it was taken from the then advanced microprocessor 8086.

Since then, the model has been extended, but always remained backward compatible to this day. All attempts to bring out a CPU which isn't backward-compatible with x86 have been rejected by the market.

**ARM** dates back to the 1980's to the British Acorn computer and was based on the 6502 prrocessor. ARM has been used by Apple and many other mobile vendors and is used still because of its low energy requirements.

### von Neumann

Every ISA is modelled after the Von Neumann model: a computer has memory, where data is stored, and a CPU, which controls the system and which performs calculations.

Memory isn't part of the physical CPU (which isn't big enough) but usually consists of separate chips located near the CPU (single chip computers exist for embedded applications).

In principle, memory is straightforward: it is capable of storing a large number of bytes. Every byte stored, has a unique location called an **address**. If a laptop has 16GB of memory, the memory can hold 16\*1024\*1024 bytes. To address that many bytes there must be that many distinct addresses, so every address is (at least) a 24-bit number.

### Memory

A register is made from flip flops or latches, each of which consists of at least four transistors.

Dynamic Ram is an improvement which requires only 1 transistor per bit. The downside is that every bit must be read and written frequently, or it would dagrade.

DRAM chips have a circuit that refreshes all bits as long as they are powered. That is why the memory in your computer is emptied when you turn off the power.

Memory has three inputs and one output.

* One input is the **control**. It determines if we want to store data or fetch stored data
* The second input is an **address** where to fetch data from or where to store data (depending on the control)
* If the control says 'store', the third input is the byte to be stored. Otherwise this input isn't used.
* If the control says 'fetch', the output will be the byte that was last stored at the given address. Otherwise the output isn't used.

Note: in practice, bytes aren't fetched or stored one at a time, but in larger chunks (2, 4, 8 or much more).

#### Fetch

The CPU is connected to memory chips by one or more buses. To fetch data

* the CPU computes an (integer) address
* puts the address on the **address bus**
* sets a control line to indicate if it wants to **fetch** the data or **store** it
* store: the CPU puts the appropriate value on the **data bus**
* fetch: the CPU must *wait awhile* before it can read the value from the data bus

A lot of engineering concerns optimizing this naive approach. Nobody likes CPU's to just wait.

#### Address ≠ Data

It is important to understand that an address is 'just data' until it is put on an address bus. Computing an address is just an integer computation.

For instance, if *A* is an array in a program in which each cell contains a 64-bit integer, then in order to execute *A[5]=1024* we must

* get the current location of the first cell *&A*
* add to that the size of cells times the number of cells to skip
* so the location of field *A[5]* is address `&A + 4 \* 8`

#### Registers

Although memory is fast, it is still too slow compared to the ALU and core operations. To achieve the best speed, **registers** are used. *From a programmer's perspective, memory resembles an array and registers resemble local variables.*

There are two categories of registers: **special purpose** and **general purpose registers**. General purpose registers are used to compute and hold various results relevant to a program; special purpose registers hold specific values relevant for the CPU. For instance, the flag-register holds all status flags resulting from computations in the ALU (including Negative, Zero, Carry).

### Fetch-Decode-Execute

An ISA program is stored in memory as a sequence of instructions. An ISA performs a fetch-decode-execute cycle:

* fetch instruction from memory  
* decode to see which operation should be performed on which operands
* execute

[A 6 minute overview can be found here)](https://www.youtube.com/embed/urqPobwPOzs)

### Program Counter + Instruction Register

When we explain programs, we point at the code and say 'here it does this, and here it does that'. An executing program has what is called a **locus of execution**: a point in the program which describes what should happen at some point in time.

The ISA model keeps the address of the next instruction (its 'locus of execution') in a register traditionally called the **program counter** (PC -- note that it doesn't count anything).

*Instruction fetch* means:

* get the byte or bytes (many instructions require multiple bytes) pointed to by PC
* put the instruction is a special **Instruction Register** or Opcode register (IR, OPC)
* advance PC (ready for the next cycle)

General purpose registers allow for many different kinds of computations. For instance, the ARM instruction `SUBS R8, R8, #240` takes the contents of register R8 and subtracts the value 240 from that, storing the result in register R8.

Treating the PC as a general purpose register makes no sense, **but some operations are nevertheless meaningful**. 

For instance, what is the effect of the operation above? If the instruction is fetched from location *here*, then the next instruction will be fetched from location *here-236* (next instruction after *here* minus240).

In ARM this is the **Branch** instruction, in this case with a negative offset. *The result is a loop*.

### Autoincrement

When an instruction is fetched, the PC is immediately incremented. This doesn't take additional time; it is done by hardware in the same machine cycle.

This is an example of autoincrements, which are used very frequently. For example when processing all values in an array.

* a register contains the address of (the first element of) the array. **This is called 'points to' by the way**.
* when the value is fetched, the register is autoincremented to point to the next element
* rinse-and-repeat

### Stack

Functions are an important concept in programming. When we call a function, the current locus of execution is suspended, and we continue execution (point the locus) in the function body. When it is done, the previous locus is restored, and execution continues.

The same concept is used in a CPU: a **call** instruction stores the current PC and then loads a new value into it (the location of the function body).

The PC is stored in a chunk of memory called the **stack** which is pointed to by a register (sometimes called SP). Storing the PC uses autoincrement (or -decrement) on SP, and the **return** instruction does the reverse.

Functions have parameters and local variables. Where are they stored? Maybe in registers, but what if I call another function? Then my local variables must be stored in memory so that they can be retrieved when the second function returns.

A stack is also used for this. All parameters and local variables are stored in what is called a **stack frame**, and the stack pointer is advanced to empty space beyond the stack frame. 

A special register (frame pointer) and pointer trickery is used so that the CPU (which doesn't realy know functions) can find the beginning of each stack frame.

### Instructions

Earlier we mentioned Intel's programmer's manual ([Intel® 64 and IA-32 Architectures
Software Developer’s Manual](https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-1-manual.pdf)) which lists all instructions including data transfer, arithmetic, logic, control transfer (affecting the program counter) and much much more. 

#### x86 registers
{{< figure "x86 Registers" "/images/Table_of_x86_Registers_svg.svg.png" right 100 >}}

<span style="font-size:smaller;">Source: 'Immage - Own work, CC BY-SA 3.0, https://commons.wikimedia.org/w/index.php?curid=32745525'</span>

#### x86 instructions
[A listing of x86 instructions can be found here](https://en.wikipedia.org/wiki/X86_instruction_listings)

---
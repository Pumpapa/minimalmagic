---
title: "Bigger Things"
date: 2021-09-04T20:55:58+02:00
draft: false
weight: 70
categories:
  - "SE"
tags:
  - "Data Path"
  - "ALU"
  - "Boolean Logic"
  - "Arithmetic"
  - "Shift"
  - "Barrel Shifter"
---
So far we've looked at the lowest level of Bits & Gates, but now we're off to bigger things.

Designing a CPU in terms of billions of transistors or gates as logical units would be like designing a city in terms of sand, wood and glue: it doesn't work that way. 

We use transistors and gates to design bigger and bigger functional components, which, together, form the functional parts of a CPU.

# Data Path
{{<figure `Data Path` `/images/SE/SE1.datapath0.png` right 20 >}}

A ***data path*** is the  part of the µarchitecture concerned with data and computation. It consists of registers, buses and the ALU. During every cycle, controls determine which registers output data on buses A and B, which function the ALU should perform, and to which registers the result will be stored through bus C.

# ALU

Probably the most complex component part of a CPU is the ALU: the ***arithmetic and logic unit***, i.e. the unit that does all the computations.

We have already seen many parts: 

{{<figure `Multiplexer` `/images/SE/SE1.2-1-mux.png` right 20 >}}

* Adders for integer addition (and as we've discussed two's-complement it is clear this is also subtraction)
* Other gates for logic functions
* Decoders for register selection
* Multiplexers for input selection
* Multiplexers for function selection (see image) 

An important system engineering method: a control bit alters the function of the circuit. This is the smallest possible interpreter! We will look at the ALU later on.

According to the *von Neumann model* a CPU consists of two aspects: control and ALU. An ALU computes: integers, other numbers, logic: AND, OR, etcetera. In principle, an ALU has three (multi-bit) inputs and two outputs:

* Input: The desired operation. ALU's can do many, so control lines make the ALU work this or that way.
* Inputs: The operands. Often two (+, \*,&, ...) but sometimes one (!, -) 
* Output: the result of the operation.
* Output: Flags. In addition to the result, the ALU will offer more information about the operation. This information can subsequently be used (by the control unit) to perform additional action. These include =>
    * ***Zero***. Whether or not the result of a computation is 0 is important to decide subsequent action. For instance, we loop through an array from end to start, which is index zero.
    * ***Negative***. Likewise, whether the result of an addition or multiplication is positive or negative is an important decider.
    * ***Overflow***. When two positive 32-bit integers are multiplied the result must be positive.  If it comes out negative (i.e. the left-most bit is 1) the product is clearly too large to represent in 32 bits two's complement. This is called *overflow*, and an error handler must be activated. 
    * ***Carry***. The carry is relevant output, for instance when considering what is called 'high precision arithmetic'.  If 32 or 64-bit operations aren't sufficient, higher precision addition can be achieved using multiple additions in series, making sure that the carry of the lower order is passed on to the higher order.

{{<figure `Boolean Logic (1st try)` `/images/SE/SE1.ALU0.png` right 30 >}}

In the next few sections we will create a simplistic ALU using components we've seen so far.

## Boolean Logic

* We'll start with Boolean logic, and let's say we need at least the common operators: AND, OR, XOR. We've already seen these.
* Adding components for NAND etcetera is extravagant but actually we only need a NOT behind the AND which we can turn on or off.
* After that we select the result we need (MUX).

*Oh wait, we forgot the operator NOT. We can NOT the result of the binary operators, but we can't currently compute NOT A*

{{<figure `Boolean Logic` `/images/SE/SE1.ALU1.png` right 30 >}}

Since we already have the inverter pattern and since we're not using one of the four selection inputs, the solution is straightforward. Add an 'operator' which just copies A and ignores B:

That's our logic unit. With three control bits we compute the relevant functions AND, OR, XOR and NOT and throw in NAND, NOR, NXOR almost for free (and "Copy A" (A,B) => A, which isn't particularly useful).

## Arithmetic

We've already seen a binary adder (consisting of a half adder and a row of full adders).
As mentioned, two's complement allows us to add unsigned/positive and negative numbers using the same circuit.

{{<figure `Add/Subtract Integers` `/images/SE/SE1.AU.png` right 50 >}}

Creating a separate circuit to perform subtraction is in fact not necessary: *subtraction is the same as addition of the negative of that value: a - b = a + (-b)*.

Computing the negative of a number is easy: flip the bits and add one. Adding one may seem to require a separate cycle, but ***it is in fact very much like an additional carry***. By changing the half-adder to a full adder, we can add one or not depending on the operation. Our arithmetic unit (shown only for 8 bits) now looks like this.

## Shifters

Shift is an important operation on binary values. Use cases include processing each bit in a value, for instance for transmission (Networking Layer 0), or very fast multiply/divide by powers of two. Shift left = times 2. Also, many cryptography algorithms use shifts. Common operations are:

{{<figure `Logical Shift Right` `/images/SE/SE1.LSR.png` right 50 >}}

* LSR: Logical shift right, copying the rightmost bit into the carry (to be tested and used).  

* {{<figure `Logical Shift Left` `/images/SE/SE1.LSL.png` left 30 >}} LSL: Logical shift left (also ASL). This is times 2 for unsigned numbers.
* {{<figure `Arithmetic Shift Right` `/images/SE/SE1.ASR.png` right 30 >}}  Arithmetic shift right keeping the sign-bit in place so that divide by 2 is valid (rounds down towards negative infinity).
* {{<figure `Rotate Left` `/images/SE/SE1.ROL.png` left 30 >}} Rotate left.  
* {{<figure `Rotate Right` `/images/SE/SE1.RORC.png` right 30 >}} 
Rotate right through carry.

## Barrel Shifter

{{<figure `Barrel Shifter` `/images/SE/SE1.barrel.png` right 40 >}}

Shifting is a very much used operation, for instance in the context of address calculations. Usually we need to shift more than once, and sequential shifts (i.e. in a loop) take many cycles.

A ***barrel shifter*** is a component that can shift an arbitrary number of times in a single cycle. The diagram shows an 8-bit (logarithmic) barrel shifter. It uses three-bit input B to determine how many positions we must shift (000-111, zero to seven in an 8-bit shifter). 

Note how the MSB of B (B2) controls the top row of demuxers, connecting the output either vertically down, or 4 places to the left. And note that when rotating, to the left of A7 is A0, and so on.

The lesser significant bit B1 controls the second row, where each bit is transported either down or two places to the left. And finally the LSB B0 controls the last one or zero shift.

For instance, to shift A five positions, B2 and B0 are set, so first the bits are shifted four to the left and then they are shifted once more, each time rotating them from the left (MSB) to the right (LSB) as necessary.

{{<figure `ALU Symbol` `/images/SE/SE1.ALUsymbol.png` right 20 >}}

We've now seen all major components in an ALU and we've seen the mechanisms to join them into one large component (of less than one millionth of a millimeter squared).

The components we've seen consist of

* A Logic unit offering NOT, AND, OR, XOR, NAND, NOR, NXOR
* An arithmetic unit offering ADD and SUB
* We've shown a barrel shifter offering ROL. A barrel shifter which performs ROL, LSL, ROR, LSR and ASR is an extension of what we have already seen.

**A 'real' ALU does much more, including multiplication and division.
See the [Intel® 64 and IA-32 Architectures Software Developer’s Manual](https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-1-manual.pdf) to be astounded**. 




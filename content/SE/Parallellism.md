---
title: "Parallelism"
date: 2021-09-05T09:30:58+02:00
draft: false
weight: 110
categories:
  - "SE"
tags:
  - "Pipeline"
  - "Branch Prediction"
  - "Superscalar"
  - "SIMD"
---
Users don't like to wait, and while a single ALU is fast, it can only do so much. System engineers have developed many ways to speed up processors. The most important idea is ***parallelism***. We've already seen some parallelism in the ALU. It computes several functions at the same time, then a multiplexer picks the result of interest.

Many different sections of a CPU can and do work in parallel. We'll only discuss a small number of aspects to give an overview.

# Multiple Cores

Today, the largest desktop CPUs offer many cores: Intel i9: 18 cores; AMD Naples: 32 cores. For typical household use including gaming, about 16 cores is sufficient.

For servers, larger CPU's exist: Intel Xeon Phi: 72 cores. Ampere releases a 128-core ARM processor aimed at servers. Since designing chips becomes more and more automated and accessible, more and more companies (offering more and more jobs to System Engineers) are creating novel solutions.

Just adding cores is easy, but engineering the cache architecture and supporting hardware to keep many cores running effectively (using a single memory and network connection) is very difficult. In particular given the fact that **all software is aimed at the singular x86 or ARM model** (although software may be written to make use of multiple cores if they're there).

# Pipeline

A core executes the fetch-decode-execute cycle. Naively, this would mean the fetch and decode circuitry is idle while the ALU is executing, but processors are somewhat predictable. When an instruction is executed, the next instruction is usually the one immediately following. That instruction can already be fetched and decoded while the first is executing.

Around 1980 the 5-stage pipeline was introduced, executing five aspects in parallel: instruction fetch, instruction decode, execute, memory access, register writeback.

However, the next instruction isn't always the one following. If the current instruction is a jump, the next instruction is at the place we are jumping to. This situation becomes known in the decode stage. Then, the fetch stage can be restarted to fetch the right instruction.

## Conditional Branches

The situation becomes more complex for conditional branches, because the branch may or may not be taken *and the condition which decides this hasn't yet been computed*. Because any improvement is better than waiting, an entire field of engineering involves **branch prediction**.

Let's assume about 20% of instructions are conditional branches. An ideal 6-stage pipeline without prediction must therefore wait 20% of the time. This implies that instead of 1 cycle per instruction, it requires 0.8+0.2*6 cycles per instruction which is 2 cycles: the cpu runs at only half the best possible speed!

## Branch prediction

Branch prediction heuristics include:<small>*(source https://danluu.com/branch-prediction/)*</small>

* *The branch will always be taken*. This is correct in perhaps 70% of the time. Already a big improvement
* *Backwards taken forward not*. Loops are executed more than once on average, so backward branches (in repeat..until) are usually taken, but forward branches (in if..., for... or while...) usually aren't because programmers tend to handle the likely case first
* *One bit*: maintain a table per branch with one bit indicating whether the branch was taken last time. This also works for branches based on locally stable conditions such as in sorting algorithms.
* *Two bit*: maintain a two-bit counter per branch. Works also for sequences of branches such as in a switch-statement.

Most of these heuristics were developed between 1990 and 2000. Current performance is in the area of 5% off 'always right' prediction!

# Superscalar

Many instructions require more than one cycle to execute. Some common examples are floating point operations, and instructions that must fetch or store results in memory. During the execution of such an instruction, the pipeline and other hardware shouldn't be idle.

A **superscalar** is an extension on the pipeline, which allows multiple ALU functions to be executed at the same time. The ALU might for instance contain an additional integer arithmetic unit and a floating point unit. In that way, even though the instructions in isolation might take more than one cycle, a new operation can be started almost every cycle.

# Simultaneous multithreading & Hyperthreading

Many processors advertise on the box: *n cores, m threads* (where m=2n). What's that about?

Every core has to wait less than a microsecond every now and then, when data or instructions aren't in a cache and must be fetched from memory. If the wait were longer, say for disk access, the OS could allow another process to run, but a process swap takes a few microseconds, so it isn't suitable in this case.

**Simultaneous multithreading** adds a second (or further) set of registers to a core. Intel's proprietary comparable solution (Hyperthreading) calls this a virtual core.

Whenever one thread needs to wait briefly, another set of registers is used to advance another thread. Obviously the pipeline and superscalar must be integrated for this to work. 

## Thread vs Process

We will look at processes and threads later on, but for the moment it is relevant to note that by definition threads always share memory, so simultaneous multithreading doesn't introduce global issues around shared resources.

To introduce 'hyper-processes', many issues around shared-resource contention and security would ensue. Far too complex to solve by hardware within microseconds.

But simultaneous multithreading doesn't introduce these issues. In desktop CPUs the maximum is 2 logical cores per real core, but server CPU's exist with more than that.

# SIMD

Our processor model might be called SISD: a single instruction processes a few single data values. Consider that your favorite first-person shooter game generating 60 fps at, say, 1920x1080 resolution is performing roughly 120 million computations per second. Every second the same (or similar) instructions need to be fetched and decoded to perform the same calculations (on different data).

In an SIMD processor, a single pipeline drives multiple processing units (which implement some ALU functions). The array of processing units is often called the ***vector unit*** and SIMD is also called vector processing.

The key use-cases for this are graphics and crypto.

Today, the x86 has 32 512-bit vector registers supporting many floating point and integer SIMD operations. 

Browser vendors were working on SIMD.js, platform-independent JavaScript access to vector instructions, but those activities have ceased in favor of:

WebAssembly: the ability to load and use assembler-like code in a browser. Supported on many different platforms. Yeah! [http://webassembly.org/demo/Tanks/](http://webassembly.org/demo/Tanks/)




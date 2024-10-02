---
title: "Processes"
date: 2021-09-10T10:13:58+02:00
draft: false
weight: 140
categories:
  - "SE"
tags:
  - "Process Table"
  - "Memory Management"
  - "Scheduling"
  - "9-State"
  - "Dispatch"
---
A process is

* An executable program (i.e. ISA instructions)
* data used by that program (variables, stack, buffers, etcetera)
* an execution context = *current state*

The OS maintains administration of many aspects including:

* pending I/O
* resources sharing or exclusively using

# Resource & Process Management

{{<figure `Process Table` `/images/SE/SE1.procestab.png` right 100 >}}

* Memory tables 
(partly discussed for VM)
* I/O tables used to keep track 
of all ongoing I/O activity
* File tables contain information of
the location and other properties
of the hierarchical file system
* The process table contains information 
(state etc) on all known processes

## Process Table

* User Program + Data (e.g. Stack)
* Process Control Block
    * ID’s (this, parent, user)
    * Processor State
        * User-Visible Registers inc Stack Pointers
        * Control & Status (PC, Flags, Interrupt masks)
    * Process State
        * State, Prio, Scheduling Info, Blocking Event
    * Data structures e.g. all waiting
    * Interprocess Communications e.g. semaphores
    * Privileges e.g. root, quota
    * Memory Mngmnt
    * Resource ownership & Utilization (files, CPU use statistics)

## Memory Management

OS responsibilities:

* **Process isolation**: programs should not be able to inspect or alter data from other programs (unless they are sharing data)
* **Access control protection**: mechanisms are in place to allow programs to share memory (in the entire hierarchy)
* **Automatic allocation and management**: Allocation in the hierarchy should be automatic and transparent to the programmer
* **Process relocation**: processes may need to be relocated (e.g. for swapping)
    * *Question: how is that possible?*
* **Modular programming support**: creation, destruction and change of program modules
* **Persistance**: access to long term storage

## Information Protection

* **Availability**: an information service must be accessible for intended use (think of DDOS)
* **Confidentiality**: information must be accessible to intended parties and not to others (think of phishing)
* **Integrity**: information should only be altered by intended processes (e.g. XSS)
* **Authenticity**: information sources (when intended to be accessible) should be true (think of spoofing)
* **Accountability**: all changes can be traced to identities

# Scheduling

which process gets access to the two main resources: CPU and memory?

* **Long term scheduling**: add to the pool of ready or suspended processes (allow into virtual memory)
* **Medium term scheduling**: add to the pool of ready or blocked processes from 
suspend (allow into memory)
* **Short term scheduling**:
add to the pool of running processes (allow into CPU)
* **I/O**: management sleep/wakeup for I/O


## Scheduling Goals

* **Fairness**: the current Linux scheduler is called *'Completely Fair Scheduler'*, which uses a **red-black-tree** (a *self-balancing binary search tree*) to maintain a timeline for every process adding real or virtual (when waiting) nanoseconds towards priority.
* **Differential Responsiveness**: individual applications may need priority (phone=>real-time scheduler, first-person shooter=> works better in windows)
* **Efficiency**: max throughput, min response time, min overhead

These goals are often conflicting

## Short-term scheduling aka Dispatch

which ready process to execute next?

* invoked very frequently:
    * clock interrupts
    * I/O interrupts
    * OS calls (traps)
    * Signals (e.g. semaphores)
* criteria
    * priorities
    * responsiveness
    * throughput
    * qualitative criteria such as predictability

{{<figure `Source: Richard Stallings, Operating Systems: Internals and Design Principles` `/images/SE/SE1.dispatch.png` right 100 >}}

<small>
*Source: Richard Stallings, Operating Systems: Internals and Design Principles*
</small>

* first come first serve
* shortest process next
* shortest remaining time
* highest response ratio next (user info or past experience)
* feedback: give lower priority to long-running processes


## Process State

{{<figure `9 State Transition Diagram` `/images/SE/SE1.9state.png` right 100 >}}

Represents whether a process can run (or possibly why not). The book builds up to the seven state model, but we've added two here for run-level and preemption state.

* New: process has just been created
* Ready/Suspended: ready process is moved to disk to free up memory
* Ready: process is ready in memory waiting for CPU and not for I/O
* Running: process is currently active in the CPU
    * User state
    * System state
    * Preempted
* Blocked: process is waiting for I/O
* Blocked/Suspended: has been moved from memory to disk
* Zombie: finished, no resources but still in table (for parent)

## Termination

* Normal completion
* Time limit exceeded
* No memory
* Bounds violation
* protection violation
* Arithmetic error
* Time overrun
* I/O error
* Invalid instruction
* Privileged instruction
* Data type error
* Intervention (e.g. deadlock)
* Parent terminated
* Parent request

# Processes vs Threads

Process:

* 'Owns' resources
* Scheduling/Execution

But these are independent!

* Just execution: Thread
* Also resources: Process

Process has

* Virtual address space (& mem)
* Processor-time
* Access to other processes, files, I/O

Thread has

* State (PC, registers)
* Stack with local variables
* (Shared) access to process resources

Threads are 'light', Processes are 'heavy'

## Thread Uses

* Foreground (UI) / Background (Logic, Data)
* Async
* Modularity
* Parallelism

## Thread Types

* User-level threads  
the application manages (using a thread library). The kernel doesn’t ‘see’ threads (only the entire process has a state).

advantages: no mode switch, application specific scheduling, OS indep.  
disadvantages: one blocks all, no multiprocessing, 

* Kernel level threads: the kernel does management  

main disadvantage: mode switch (can result in a factor 10 penalty)

Some OS’s combine ULT & KLT 

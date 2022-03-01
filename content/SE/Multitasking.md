---
title: "Multitasking"
date: 2021-09-04T20:55:58+02:00
draft: false
weight: 130
categories:
  - "SE"
tags:
  - "Parallelism"
  - "Concurrency"
  - "Multitasking"
  - "Non-determinism"
  - "Deadlock"
  - "Mutual Exclusion"
---
Although Multi-tasking, Concurrency and Parallelism all refer to the same concept, more than one thing happening at once, they are entirely different ideas.

**Parallelism** as we have discussed it, considers running a single, sequential ISA program, and aims to maximize execution speed by parallelizing activities to improve the speed of single program steps.

**Concurrency** considers multiple programs running at the same time on one system, possibly exchanging information. In English, the word concurrency primarily means 'at the same time'. In Dutch, and in Computer Science, the focus is on the fact that often only one program at a time can use some resource, so the parties are vying for that use!

**Multi-tasking** refers to the broad concept of computers seemingly doing many things at once. *Seemingly*, because actual parallelism isn't needed.

# Multitasking

Early single-CPU computers allowed multiple users to use that CPU by giving every user in turn a (fixed) small amount of time on the CPU. The OS would allow user A's process to run for a tenth of a second, and then that process was interrupted and user B's process could run, and so on. When the only interaction is by keyboard, this kind of task switching is hardly noticeable.

Interrupting one process to allow another process to run is called **preempting** the first process. Obviously preemption isn't the only reason to suspend a process: when a process is waiting, for instance on disk access, it can also  be suspended to allow another process to run.

The mechanism used to preempt is an **interrupt**. We already mentioned interrupts: the CPU  quickly stores the PC and some relevant registers on the stack. The CPU state is elevated to get system rights, and the scheduler determines which process can now execute. 

## Concurrency issues

* running many programs in parallel, all using many different I/O devices with different speeds and properties, requires a complex *system of signals* being sent around. Subtle bugs (such as buffer overflow) may occur in rare circumstances 
* mechanisms must ensure that only one program at a time may use certain resources (e.g. write to a file), but it is very difficult to ensure that *mutual exclusion* is correct in all circumstances
* when run in isolation the result of a program depends on the input, but if concurrent programs communicate or share a resource the result may depend on the way they are interleaved: *non-determinism*
* a program needs two resources. It obtains (exclusive rights to) the first and then waits until the second becomes available. Another program needs the same two resources and has obtained (exclusive rights to) the second and is waiting for the first resource to become available: *deadlock*

## Non-Determinism

Ordinary programs are deterministic: given the same input they will do the same thing and produce the same output. Parallel programs sharing a resource such as memory can be non-deterministic. *(Note: despite the definitions given above, the terms 'parallel' and 'concurrent' are used interchangeably. Most people don't consider our technical interpretation of the term concurrent.)*

Consider for example two programs that share one variable `x`. Program P1 will just execute the statement `x = x + 3;`. Program P2 will just execute the statement `x = x * 4;`.

If `x` has the value `2` in the beginning, what is the value of `x` at the end?

```
x = 2;
P1: x = x + 3;
P2:`x = x * 4;
```

If P1 runs first, `2` becomes `5`, then P2 runs and `5` becomes `20`

However, if P2 runs first, `2` becomes `8`, then when P1 runs `8` becomes `11`

So there are two possible outcomes? No wait: there are more

To compute `x = x + 3` P1 first fetches the value of `x`, then adds `3` and then stores the value in `x`. Likewise, P2 fetches `x`, multiplies by `4` and stores.

But what if P1 and P2 fetch the value of `x` at the same time?

P1 fetches `2` and stores `5`, and P2 fetches `2` and stores `8`. What is the value at the end?

It depends: who writes last? Possible outcomes are 5, 8, 11 and 20

And that is only true if reading/writing a value is one operation. What if values are 64 bits but there is only a 32 -bit data bus. The number of possible outcomes would be even bigger.

This is the wonderful world of **Non-determinism**, in this instance as a consequence of sharing a single variable.

Note: non-determinism isn't like a bug. Each of the possible outcomes is correct. *(This makes our earlier comment about a telephone exchange with 99.9999999% uptime written in Erlang, consisting of thousands of parallel processes all the more astounding)*

Writing correct concurrent software, which is deterministic or at least where the non-determinism doesn't harm the intended outcome, is **very difficult**. 

There have been attempts to automate this, by writing compilers that take a sequential program and parallelize it. But the results aren't very good. At the moment, writing reliable concurrent software is still something only humans can do.

# Mutual Exclusion 

The problem in our P1|P2 example stems from the fact that both programs have unlimited access to the shared variable. What we want is **Mutual Exclusion**: while one program has access to `x`, the other doesn't.

## Semaphores

A basic programming mechanism to offer this is a **Semaphore**: an OS-level mechanism which can limit access to a shared resource (such as variable `x`). Using a semaphore, the statement `x=x+3` can be made into a critical region. While one program has access the other will be suspended if it tries to access `x`.

At the heart a semaphore is made possible by an atomic Test-and-Set instruction: a hardware instruction which sets a flag and returns the value of the flag before it was set.

A program wishing to enter the critical region 'Test-and-Sets' the flag and then checks the result. Only if the return value indicates that no other program was 'using' `x` (the flag was not already set) will it proceed.

Semaphores allow us to manage non-determinism but not necessarily to prevent it entirely. Our earlier example still has two possible outcomes, depending on which program runs first.

And there is still room for deadlock

# Deadlock

Suppose you are editing a huge photo of the Moon using the Gimp (an open-source Photoshop-like program). To do that, the Gimp needs a very large chunk of memory and it needs access to the photo file on your hard disk. Your OS swaps out as many processes as possible and is barely able to free the amount of memory needed. 

So now the Gimp tries to access the file, but just at that moment your automatic disk compression program has started to compress this huge Moon photo file, **and has acquired unique access to it**. For such a large file the compressor needs more memory, and now it also asks the OS for a large chunk.  
...

This is deadlock: process *A* has exclusive access right to resource *a* and needs access rights to resource *b*, but must wait on process *B* which holds exclusive access right to resource *b* but is waiting for access to resource *a*.

The primary task of an operating system (the kernel) is to manage resources - that is, to allow processes to make the most efficient use of resources.

Resources include:

* CPU time
* Memory
* Disk access (fine grained, e.g. per file)
* Network
* ...

Sometimes a resource can be shared (e.g. multiple processes reading one file), but sometimes access must be unique (e.g. writing to a file).

The problem with deadlock is that it is almost impossible to predict and not always easy to recognize. In our Moon-photo example, some other process might terminate, freeing its memory and thus resolving the deadlock.

In general, OSes try to detect deadlock by using many timers on all sorts of expectations. In the network-stack a timeout might simply indicate packet loss; in resource management it might indicate deadlock.

In some OSs deadlock might be prevented by requiring all programs to claim all resources beforehand. That way, when a program starts it is guaranteed to be able to finish.

Other OSs simply kill one program if they suspect it is part of a group of programs in deadlock.




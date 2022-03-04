---
title: "TRAM.1"
date: 2021-09-30
draft: false
weight: 300
categories:
  - "TRS"
tags:
  - "Tagged Values"
  - "Data"
  - "Symbol"
  - "Variable"
  - "Memory Management"
  - "Memory"
  - "Garbage Collector"
  - "Scanner"
  - "Parser"
  - "Printer"
  - "Rewrite Engine"
  - "Engine"
  - "TRAM.1"
  - "Formats"
  - "Syntax"
  - "Semantics"
---
TRAM.1 is an implementation of term rewriting systems.  TRAM.1 is written in standard C using only a few standard libraries. TRAM.1 is small (~650 lines of code). The memory manager and garbage collector are in a certain sense efficient. TRAM.1 contains a naive, handcrafted sunny-day parser (i.e., almost without error handling). The rewriting engine is naive: rules are attempted sequentially without much compilation or optimization.

TRAM.1 is available at [Github](https://github.com/BabelfishNL/Tram.git)

This section contains a rationale and explanation of TRAM.1, followed by a detailed user manual.

# Rationale
TRAM.1 consists of the following parts (lines of code per part):

* The definition of `struct node` and some auxiliary macros (\~30 loc)
* Declaration of global variables (\~10 loc)
* Initialisation, in which memory is formatted (\~10 loc)
* Garbage collector (\~50 loc)
* Memory manager(\~15 loc)
* The parser (\~140 loc)
* Term printer ( (\~90 loc))
* Rewrite engine (\~150 loc)
* CLI argument processor (\~100 loc)

## Tagged Values
{{<figure `Tagged Values` `/images/TRS/TaggedValues.png` right 60 >}}

TRAM.1 uses 32-bit ints to represent values (symbols, variables, references). The set of symbols is divided into a set 'Data', for which the engine assumes no rewrite rules exist, and other symbols. This means there are over 1 billion proper function symbols and as many constants to represent characters, (30 bit) integers, tiny floats, etcetera. Note that separating the set of symbols doesn't introduce magic. There are no built-in functions for integers, floats, etcetera.

TRAM.1 is intended to be self-contained, i.e., able to process term rewriting systems in source format (without a compiler) and to reduce terms either in term-notation or as textual or binary data.

The conflict of the limitation to 32-bit ints and the need to read and write identifiers is solved by encoding short identifiers. TRAM.1 encodes symbol names five characters maximum and variable names of four characters maximum in a 32-bit int. Data-symbols can be input as characters, integers, or hexadecimal numbers, but are represented as binary numbers (this means, `'A'`, `#65` and `#0x41` represent the same value and are output as `#0x41`,  or `A` when using the appropriate CLI flag).

* `[@$a-z][A-Za-z0-9.]+ => Symbol`  
Only the first five characters are significant, so `abcdef` and `abcdefg` are considered identical. Identifiers shorter than 6 characters and identifiers longer than 5 characters are distinguished, so `abcde` and `abcdef` differ, but `abcdef` and `abcdeg` are identical and are output as `abcde...`
* `[*&A-Z][A-Za-z0-9.]+ => Variable`  
Only the first four characters are significant, using a similar mechanism as symbols
* `'#''0''x'[0-9a-fA-F]+  |  '#''-'?[0-9]+  |  ['].['] => Symbol`  
Data can be any decimal integer, hexadecimal number, or character. 


## Memory
Memory is allocated as a single block for a fixed number of nodes. This number has a default but can be set with a CLI argument.

On initialization, all nodes are pushed on the list of free nodes (linked through the `nxt` field). Creating a `new` node pops one off the free-list and pushes it on the `nxt`-linked list of used nodes, ready for garbage collection.

## Garbage Collector
When a new node is created, but the list of free nodes is empty, the garbage collector is activated.

* First, all global variables are marked (marking uses an unused bit in the `nxt` field)
* Then, all used nodes are traversed. 
    * If a node is marked, its children are marked, the node itself is unmarked and remains on the list of used nodes
    * if a node is unmarked, it is unused and is moved to the list of free nodes
If the list of free nodes is still empty, memory has overflowed, and TRAM.1 exits.
Otherwise, a new node can be created.

There are only a few global variables (called the **registers** of TRAM.1) that the garbage collector needs to be aware of:

* `P`, the current rewrite system 'program' (pointer to node)
* `S`, the stack (pointer to node)
* `X`, an auxiliary register (pointer to node)
* `T`, the register which holds a subject term
* `V`, the register which holds the current reduced value

In principle, local variables can be used to hold values or pointers to nodes, but: if a node `N` is pointed to by a local variable, and a new node is created, a garbage collection might be triggered, and `N` wouldn't be recognized as a used node. For this reason, care is taken to store nodes only in the registers when `new` might be called (and to reset the registers to avoid floating garbage).

## Scanner / Parser
The scanner/parser is a straightforward scanner for values. The following tokens deserve description:

* `(`: a symbol has been seen (the ofs of a term), and a term without arguments is pushed on the stack
* `,`: if a symbol has just been seen, it is apparently a term without sub-terms, and that term is added to the top-of-stack. Otherwise, the compound term just seen is added
* `)`: if a symbol has just been seen, it is apparently a term without sub-terms, and that term is added to the top-of-stack. Otherwise, the compound term just seen is added. Then, the top-of-stack is popped
* `=`: this means the *lhs* of a rule has just been seen; it is left on the stack.
* `;`: this means the *rhs* of a rule has just been seen. The pair of this rhs and the corresponding lhs is left on the stack. Note that this means the stack now holds nodes, which do not represent meta-terms. Representing a TRS as a meta-term at run-time wastes time and space
* `EOF`: either a term has been read (which is then returned), or the stack contains a linked list of pairs lhs/rhs in reversed textual order. Then this is returned.

## Printers
TRAM.1 has three printers

* to print a value
* to print a term (uses X as a stack)
* to print a program (TRS). As mentioned, programs are stored in a more compact form than meta-terms, so they need their own printer

## Rewrite Engine
The rewriting engine is closely related to the meta-interpreter in [Section Term Rewriting](https://www.minimalmagic.blog/trs/termrewriting/), but as mentioned, there, the recursion and pattern matching must be implemented differently in C.

The engine can be described as a push-down automaton. It uses states to keep track of where it is in the algorithm. Each state 'knows' which variables are stored on the stack when it is entered.

Some states are:

* `BUDONECDR`: bottom-up rewriting, after the cdr has been normalized
* `TOPRED`: top-reduce, after all, sub-terms have been normalized 
* `FORRULES`: iterate over the list of all rules

## CLI Argument Processor
The argument processor is straightforward.

* Program (TRSs) and terms each can be read in one go (one file) or in chunks.
* flag `-P` (upper-case) reads the TRS at once, while repeated `-p` (lower-case) reads program fragments (\= set of rules), after which `-C` joins the fragments. This allows programs to be maintained as a set of modules.
* flag `-T` (upper-case) reads a term at once, while repeated `-t` (lower-case) reads sub-terms, after which `-M` reads a meta-term. This is a term that may contain meta-variables `%n`, where `n` is the index of the n-th read sub-term. This way (for instance), a function can be applied to an input term
* in addition to terms, TRAM.1 can also read text files. Flag `-s` reads a text file and produces its term-representation (`str(...eos)`).
* flag `-I` prints the program (TRS) read
* flag -i print the subject term read
* flag `-r` reduces the term read using the program read
* flag `-O` prints the result after reduction. Note that debug settings influence how that term is represented (i.e., flattened or not)

# User Manual
## Tram.1 Syntax
Characters `*` and `&` in variables, and `$` and `@` in symbols have no special significance other than to express the special status of variables or symbols from the perspective of the programmer.

## Tram.1 Semantics
Tram's semantics is described in [Section Term Rewriting](https://www.minimalmagic.blog/trs/termrewriting/). Tram follows the right-most innermost reduction strategy. That is, 

* given a term, first its right-most innermost sub-term is considered for reduction
* then the left-hand sides of all rules are matched against that sub-term
* rules are attempted in the order in which they have been read, either using the `-P` flag or in the order of modules (`-p` flag) followed by the order within that module
* if a match is found and the substitution is established, the corresponding right-hand side is instantiated using that substitution
    * TRAM.1 assumes no variables occur multiple times on the left-hand side. If this occurs, the value matched against the last (right-most) occurrence is used
    * TRAM assumes that for every variable on the right-hand side, a value has been matched on the left-hand side. This isn't checked; using an unmatched variable leads to erroneous results
    * The result of this instantiation is further normalized
    * Then, the next right-most innermost term is attempted
* if no match is found, the sub-term is built, and the next right-most, innermost sub-term is considered
* this process continues until the entire subject term has been processed. The result is the now normalized subject term
## TRAM.1 CLI 
TRAM.1 accepts the following CLI arguments
```
    Note that D and X must appear as 1st/2nd cli argument when used
-D n         generate level n (1..3) debugging info
             Level 0: none
    		 Level 1: only I/O (flat string repr.)
    		 Level 2: Garbage Collection
    		 Level 3: Reduction step information
    		 Level 4: Engine cycle information
-X nnn       set memory size to nnn

-P <fname>   Load program
-p <fname>   Load program segment
-C           Compile all segments into one program
      Note that either -P or -p...-p -C should be used
-T <fname>   Read term as subject
-t <fname>   Read sub-term
-s <fname>   Read string sub-term
-b <fname> <todo> Read binary sub-term
-M <fname>   Read meta-term as subject
-m <fname> <todo> Read meta term as sub-term
-I <fname>   dump program
-i <fname>   dump subject term
-r           reduce subject using program
-O <fname>   dump result term
-S <fname> <todo> print result as text
-B <fname> <todo> print result as binary
```

## Formats 
TRAM.1 accepts these input formats:

* Source  
The TRAM.1 source language for terms and term rewriting systems;
* Text  
Any text stream (arbitrary text terminated by EOF). The text "ccccc...", where 'c' are arbitrary characters, is rendered as the term `str('c', str('c', ...str('c',eos)...))`;
* Meta-Source  
This language is the same as the source language with one extension: meta-variables `'%' [0-9]+`. As input is read, each source, text or binary stream is rendered as a sub-term and is kept in a cache. As a meta-source input is read and the corresponding term is built, each meta-variable `%n` is immediately replaced by the `n`-th previously read term. Example: to transform a text file using some function, TRAM.1 might be called with arguments 
`-P <transformationProgram> -s <textToTransform> -M <meta>`, where the meta-text is `transform(%1)`.

## Examples
The TRAM.1 distribution contains a large number of examples.

## Distribution
The TRAM.1 distribution at  [Github](https://github.com/BabelfishNL/Tram.git) contains the following files:

* `TRAM.1.c`  
The single C source file. There are no headers; TRAM.1 only includes `stdio.h`,  `stdlib.h` and `stdint.h`.
* `test`  
A **bash** shell script containing many tests. The script
    * creates test files
    * executes TRAM
    * compares the output with the expected output
* `Makefile`  
The Makefile handles three commands:
    * `make TRAM` compiles and is dependent on TRAM.1.c
    * `make test`
​ executes the test , which creates many test files and executes TRAM, and compares the output with pre-defined output
    * `make clean` removes all files generated by the test script

## Installation
Requirements: `gcc`, `sh`

Execute: `make test`


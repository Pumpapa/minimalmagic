# <small>System Engineering 1, 17/18</small>

Version 1.7

This factsheet offers relevant information about System Engineering 1

*Note. This factsheet and the slides and handouts are in active development, so refresh your copy on a weekly basis at least.*



Please also read relevant information about this course on these important sources:

* [VLO](https://vlo.informatica.hva.nl)
* [Rooster](https://rooster.hva.nl/)
* [Studiegids](https://studiegids.hva.nl)

## Content

This course looks at the following aspects of System Engineering:

How computer hardware (and to some degree software) are structured. Which challenges and opportunities are taken up how. We will look at a functional breakdown of computer systems in parts, large (CPU, disk) and small (transistor, logic gate). We will see how data are represented both in hardware and in the context of programming languages, and we will see what choices are made to maintain vast amounts of data both expediently and inexpensively. Then we will look at how an operating system manages its resources and the processes that use them, and how the security of these systems can be maintained.

## Methods
Full-time:

* a lecture per week
* a practicum per week
* a quiz per week about the previous week's topics
* self-study
* one final exam at the end of the term

Part-time:

* a session per week for lectures and practicum
* a quiz per week about the previous week's topics
* self-study
* one final exam at the end of the term

### Materials
* [SCO]  
Structured Computer Organization, A.S. Tanenbaum, Pearson
* [OSIDP]  
Operating Systems: Internals and Design Principles, W. Stallings, Pearson
* [SH]  
Slides & Handouts are made available on VLO
* [QZ]  
Quizzes

## Examination

### Final Exam

* Your grade for this course is based on an individual Moodle exam (100%), that will take place in the exam week following the lectures
* The Moodle exam consists of questions on all treated subjects. 
* To be allowed to take part in the exam, you need to show your active participation in the lectures and practical labs, by scoring at least 35/100 in the quizzes.
* Upon passing the exam with an end grade of 5,5 or higher, 3 ECTS will be awarded. 

### Practice tests
* Every week from week 2 onwards you take a test which will cover the material of the previous lecture and practical labs. 
* The questions in the practice tests will be very similar to the questions in the final exam, so they are a great way to help you prepare for the exam.
* There are 7 practice tests, which will be scored like the exam. 
* You need a minimal grade of 35/100 for the practice tests to be allowed to take the exam.
* Each test has a time limit appropriate for the complexity of the questions.
* At the end of the course there will be an opportunity to retry practice tests if you want to improve your score or if you missed some of the tests

## Teachers

* Pum Walters, <h.r.walters@hva.nl> (module coordinator)
* Emeri Koenen, <e.p.koenen@hva.nl> 
* James Watson <j.a.watson@hva.nl>

## VLO & Moodle

VLO will be used as a communication medium and storage of materials. It is necessary to subscribe to the VLO course in order to receive important notices during the course.

Moodle will be used exclusively for tests and exams. You need to register in Moodle using the appropriate key:

* sE1_1718_101
* sE1_1718_102
* sE1_1718_103
* sE1_1718_104
* sE1_1718_DN1

## Reading List

Reading the books line by line will not help you to do the exam. You need to understand the concepts, understand which problems engineers solve and how we solve them. And you need to acquire the techniques a cybersecurity specialist uses to analyse systems & networks. 

Trying to memorize the material is useless. Our focus is on **understanding**, so glancing through the text **but asking yourself many questions and answering them** may be much more useful.

The handouts contain material from the book and other sources to give you a self contained narrative of the material.

The pages shown in bold below explain aspects directly relevant to the exam. You can glance through the other pages to get a general understanding of the subjects.

Computer History, Bits & Bytes: SCO 1 Introduction, Apendix A.1 Finite Precision Numbers, **A.2-A.5 Radix Number Systems/Radix Conversion/Negative Binary Numbers/Binary Arithmetic**, **Appendix B Floating Point Numbers**, **2.1 Processors**,  **3.4 CPU Chips and Buses**, 3.5-3.7 Example CPU Chips/Example Buses/Interfacing
Gates and Boolean Algebra: SCO 2.2 Primary Memory, 3.1-3.2 Gates and Boolean Algebra/Basic Digital Logic Circuits,
Computer Organization, the Layered Model: SCO 1.1 Structured Computer Organization, **4.1 Example Microarchitecture**, 4.2-4.6 Example ISA/Example Implementation/Design of the Microsarchitecture/Improving Performance/Examples of Microarchitecture Level, **5.1 ISA Overview**, 5.2-5.7 Data Types/Instruction Formats/Addressing/Instruction Types/Flow Control/Example: Towers of Hanoi
Memory, Storage and Assembly Language: SCO **2.3 Secondary Memory**, **6.1-6.2 Virtual Memory/Hardware Virtualization**, 6.3-6.4 OSM I/O Instructions/OSM Parallel Processing Instructions, **7.1 Introduction to Assembly Language**, **7.4 Linking and Loading**

Processes and Threads: OSIDP **2.3 OS Major Achievements**, 2.4-2.5 OS Develpments/Fault Tolerance, **3.1-3.2 Processes/States**, 3.4-3.5 Process Control/OS Execution, **3.6 Unix Process Management**, **4.1-4.3 Processes and Threads/Types of Threads/Multicore and Multithreading**, **5.1-5.2 Mutual Exclusion/Principles of Concurrency**
Concurrency, Parallelism and Virtual Memory: OSIDP **7.1-7.5 Memory Management/Partitioning/Paging/Segmentation**, 8.1 VM Hardware and Control Structures, **9.1-9.2 Types of Process Scheduling/Scheduling Algorithms**, 10 Multiprocessor, Multicore and Real-Time Scheduling
Security: OSIDP **15.1-15.7 Operating System Security/Intruders and Malicious Software/Buffer Overflow/Access Control/Hardening/Security Maintenance/Windows Security**

## Subjects

Subjects to be covered in the practicum:

* week 1: 
    * Bin <=> Dec
    * Bin addition
    * Boolean operators AND OR NOT XOR NAND NOR NXOR
    * Truth tables for complex Booelan expressions
    * Transistor: determine input/output for 2-4 AND/OR combo's
    * Gates: AND OR NOT XOR NAND NOR NXOR
    * Determine input/output for three gate combo's 
    * 3 bit adder
* week 2: 
    * Bin <=> Hex <=> Dec
    * Dec <=> 2's complement
    * Float <=> hex
    * ISA intro (= a loose collection of relevant mechanisms)
    * ALU => not realy covered in class, so should be covered in practicum
    * Microarchitecture => briefly covered in class, so should be covered in practicum
* week 3:
    * ISA + data types 
        * (bytes, words, pointers etc and endian)
        * struct, array, stack, queue, linked list, tree
    * RPN
    * Memory Pyramid
    * Caching
    * Raid
    * Assembly (+ object code)
    * Compilation phases
* week 4:
    * parallelism/Concurrency/Multitasking
    * forms of parallelism
        * cores, pipeline (branch prediction), superscalar, multithreading, SIMD
    * thread/process (brief)
    * Virtual Memory
        * paging
        * MMU, TLB, PTE, CR3
        * segmentation
    * Concurrency
        * mutual exclusion
        * non-determinism
        * semaphore
    * deadlock
    
    

## Week by week

<img src="https://www.dropbox.com/s/72ugr9u6crc0r0a/Screenshot%202018-02-13%2013.33.16.png?raw=1">

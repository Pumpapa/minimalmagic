---
title: "Memory Management"
date: 2021-09-03 15:23:00
draft: false
weight: 1000
categories:
  - "TRS"
tags:
  - "Memory Management"
  - "Garbage"
  - "Garbage Collection"
  - "Fragmentation"
  - "Mark"
  - "Sweep"
---
Software uses memory to store data objects. An object may contain data such as strings or numbers, but it may also contain references to other nodes. The collection of all nodes is called a **heap**.

The lifetime of an object is from the moment it is created to the first moment after which it will never be accessed. After its lifetime, the memory an object occupies could be reclaimed for reuse.

When software isn't overly complex, an object's end of life follows from the logic. At that time, a handler can be called to reclaim the memory. This is called **Explicit** memory management. For instance, most operating systems use this approach with the simple C API `malloc`, `realloc`, `calloc`, and `free`.

But in more complex situations, it is impossible to determine the moment after which an object is no longer needed (the question of whether a program will use some object in the future is [undecidable](https://wikipedia.org/wiki/Decidability_(logic)) in general). 

**Automatic** memory managers use conservative approximations of the end-of-life: some moment at which it is certain the object will not be accessed anymore. Many approaches are based on the observation that *if a program no longer has access to an object, it is safe to reclaim it*.  

Actually, 'automatic' is a misnomer: software libraries are used to govern access and administer state, hiding management from the programmer; it's only automatic from the programmer's perspective. This is impossible in general but effective in specific cases such as abstract machines (which follow predictable engineered patterns) or circumstances where the programmer can be required to follow such patterns. 

One example of memory management is **reference counting**: a hidden field is maintained in every object, which counts the number of references to that object. Once the counter hits zero, the memory can be reclaimed. This approach is useful and efficient when:

* the moment an additional reference is created or deleted can be easily captured;
* data structure cycles are prevented or detected;
* the additional memory used by the hidden field, and the computational overhead, are small compared to the user-task.

However, this approach only makes sense in a relatively small number of cases.

# Mark and Sweep
Most memory managers use accessibility criteria in a two-phased approach called **Mark and Sweep**:

* in the mark-phase, all objects accessible to a program are marked
* in the sweep-phase all unmarked objects are reclaimed

This approach is complex in general (we will describe issues below), but under certain circumstances (i.e., restrictions), that complexity can be reduced. Two criteria to look at are:

* storage space: most systems require some additional storage for bookkeeping. For example, the reference counter mentioned above requires an integer field in every object;
* execution time: the mark and sweep algorithm takes time and (depending on the details) may need to block the operation of the user program while it is executing.

Before describing issues and restrictions which mediate those issues, let's discuss common overhead.

* **time overhead**  
There is no absolute acceptable time-overhead for memory management, including garbage collection. Many systems perform at about 3-5% (i.e., 3-5% of overall execution time is spent in garbage collection). In addition, if garbage collection blocks the user program, an absolute maximum of 0.5 seconds or so is accepted in interactive programs. Note that memory management often entails some bookkeeping overhead in addition to garbage collection itself, which is difficult to measure.
* **space overhead**  
There is no absolute acceptable space-overhead for memory management, including garbage collection. Many systems perform at about 30-50% overhead (i.e., 23-33% of overall space is allocated to implement memory management). 
* Space and time overhead cannot be separated. If speed is an issue, more storage can be allocated for a faster algorithm and vice versa. Additionally, as memory in use approaches total available memory, many approaches deteriorate in efficiency. [Quantifying the Performance of Garbage Collection vs. Explicit Memory Management, Herz & Berger](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.61.9682&rep=rep1&type=pdf) shows (among other things) that a memory overhead of 500% can reduce the time overhead to almost 0.
* acceptable time and space overhead is also influenced by the average size of nodes and the frequency with which they are allocated and reclaimed. Some languages use nodes essentially in their execution model (e.g., functional languages), whereas others use them only to build persistent data structures. In any event, if small nodes are used frequently, space and time overhead must be kept to a minimum.

# Mark
The mark phase generally consists of two steps:

* Mark all directly accessible objects (*global mark step*)
* For every marked object that contains references to other objects, mark those (*recursive mark step*)

Note that *'directly accessible objects'* includes objects in (referenced by) global variables, but also those in local variables stored in stack frames and possibly other places.

We will discuss several issues.

## Identify global objects (*global mark step*)
Can global objects be identified by garbage collector code that is unaware of the logic of the user program? In general, this is impossible. The garbage collector is activated when a new node is to be created, and no memory is available, but other than that, no information about the process state is available.

* Which global variables contain (a reference to) objects?
* How is the stack structured in which local variables can be found?
* Which CPU registers contain such references?
* How are other intermediate results stored?

Approaches to solving this can be readily imagined.

### Compilers, Libraries
If the compiler being used is aware of memory management and garbage collection, it can handle access to objects (for instance, based on type information) in a special manner.

All object creation and access are compiled with additional code using a  library to implement memory management and safeguard consistency.

This situation is most appropriate in languages that include memory management, such as the **go** programming language. This situation may introduce some space and time overhead but is generally regarded as the most efficient approach. However, it is only suitable in specific cases.

Using this approach doesn't say how memory management is technically implemented. It can be based on reference counting or on any of the methods discussed below.

### Handles
{{<figure `Handles` `/images/TRS/Handles.png` right 70 >}}

Instead of direct pointers to objects, pointers to handles could be used. A **handle** is a small object which contains only a pointer to the actual underlying object. Handles can be made known to the garbage collector (using a subscription mechanism or memory layout). Handles can also play a role in the sweep phase, as we will see.

This solution introduces overhead both in 

* **time**  
An additional memory access is needed almost for every object access. In addition, no intermediate pointers within the objects are allowed. For instance, if the object is an array, the common C practice to process all elements using a pointer within the array would be complicated with additional control mechanisms to safeguard the integrity, such as a locking mechanism.
* **space**  
One additional pointer per object would be acceptable in most memory management implementations. 

If the client program is an abstract machine such as a bytecode interpreter, its entire state can be known, and handles could be used.

Note that the time overhead of using handles can be very significant. Handles are most commonly used for larger objects or where some form of locking isn't prohibitive.

Also, note that not only the space used by proper objects should be garbage-collected, but also the space used by handles. However, this can be very efficiently done (see Section 'Sweep' below)

## Mark indirectly referenced objects (*recursive mark step*)
How can indirectly referenced objects be identified?

A naive description is a recursive algorithm:
```Prolog {linenos=false}
(1) for each marked object o
(2)    mark children of o
```

There is quite some complexity hidden here:

### How to visit all objects
If objects are laid out adjacently in memory, one might visit all objects by walking linearly through memory. But given an object in memory, it is not necessarily possible to find the next object in use in memory. It might be at the next word boundary or some other boundary. But if the next fragment of memory is unused, it may not be formatted as an object, and it is impossible (in general) to find the next used object. At the price of some overhead, this could be solved.

But even if line (2) in the algorithm introduces a problem because it extends the set of '*used*' objects. An object which seems unused at the first sequential pass may turn out to be in use after all. Multiple passes over the entire memory would lead to too much time overhead.

Another way to look at the algorithm is as a recursive function. But the worse case behavior of such a function is to recurse across all objects in memory (cycles are not a problem because we recurse only on unmarked objects). The problem is that the garbage collector is called only when memory is scarce, so there may not be enough stack memory to implement this recursive function.

**Queues** offer an alternative mechanism: 

* in step one, all directly accessible objects are queued
* repeatedly, an object is dequeued, flagged, and all its unflagged children are queued
* this is repeated until the queue is empty

{{<figure `Queue` `/images/TRS/Queue.png` right 60  >}}

The worst-case behavior of this implementation is also to queue all objects, but that is limited and could be implemented using one additional pointer per node and no additional time overhead other than garbage collection. This approach is used fairly often.

### Link Inversion
Heap traversal when memory is scarce is an area of research by itself. Over the years, many approaches have been developed. One such approach uses link inversion: when one traverses a tree, two pointers keep track of one parent and one child, and the pointer in the parent to the child is inverted to point to the parent's parent (the inverted links form a stack of parents). No extra memory is needed, and no information is lost. An index in the parent may be needed to identify which of its child-pointers has been inverted.

### Conclusion
No ultimate conclusion is reached: mark and sweep are somewhat intertwined, so a holistic approach must be taken.
# Sweep
Two situations must be distinguished:

* nodes have equal size
* nodes have variable size

If nodes have equal size and if that size is big enough to hold bookkeeping overhead (e.g., a pointer), the world is simple: after the mark phase, all unused nodes are linked in a list to be reused. If nodes have equal size, but that size is too small for linking, a bitmap can be set aside to identify unused nodes.

## Fragmentation
If nodes have different sizes, fragmentation lurks: memory consists of many differently sized, used nodes interspersed with unused nodes and other unused fragments. There are two challenges:

* how to combine adjacent unused fragments into bigger (unused) chunks?
* how to combine unused chunks which are separated by used nodes?

{{<figure `Fragmentation` `/images/TRS/Fragmentation.png` right 60 >}}

Combining adjacent unused fragments may seem simple, but if no special care is taken, it involves looping through the entire memory: a significant time overhead. Even if unused nodes are kept in a linked list, finding adjacent ones is problematic: it may involve ordering that list, which is time overhead.
But: systems exist which employ this approach (e.g. [buddy memory allocation](https://en.wikipedia.org/wiki/Buddy_memory_allocation)). Especially if sorting is only local, the overhead can be limited.

Unused chunks separated by used nodes are the tougher problem. If they are not joined, a request for a big node might be unfulfillable even when enough unused memory is available (albeit fragmented). In time, performance would degrade significantly.

The most common solution is **compactification**: moving used nodes together to end up with one (or a few) unused chunks. Compactification may seem like an extravagant overhead, but it is worthwhile in many relevant cases. And the overhead can be limited using several techniques:

* In **generational** approaches, the lifetime of used nodes is noted. If a node has survived (i.e., continues to be in use) after many garbage collection cycles, it is unnecessary to be considered for compactification every cycle. It is put together with other older-generation nodes, which are compactified only occasionally.
* **Size pools** are used if nodes have one of a few sizes (or if all nodes fit within such a container). In this case, it makes sense to pool all equally-sized nodes/containers together, using techniques for memory management of equal-sized nodes. Obviously, This introduces the concern of disproportionally grown pools, which must then be solved.
* **Roving** refers to a technique to analyze or execute garbage collection functionality in parallel to user program execution. That way, when the garbage collector is called, (partial) compactification can be executed immediately without time overhead. Note that overall overhead isn't reduced, only overhead for the garbage collector itself.

The biggest concern of compactification is the question of whether used nodes can easily be moved. If a node is moved, all references to (and within) that node must be updated. This means all global and local variables and all other places where an intermediate result might point to/in an object (e.g., some CPU register) should be updated. 

In general, this is all but impossible. In specific situations such as abstract machines, this may be possible. A common solution is the use of **handles**because then only the handle needs to be updated. But, as mentioned, this is only suitable in some situations and does require every node access to go through the handle every time, which constitutes significant overhead in general.

# TRAM
The Term Rewriting Abstract Machine (TRAM) implements memory management as follows.

## Fixed-sized Nodes
Terms can have any arity (immediate sub-terms) and would therefore require variable-sized nodes. This requires compactification, which would lead to significant overhead.

In TRAM, a transformation is used, which maps a term with `n` sub-terms to a tree with `n+1` binary nodes. Since all nodes are now binary, no compactification is needed.

## Persistence
Term rewriting is a functional paradigm: there is no assignment. This means when a binary node is created, both sub-trees already exist, and that node will never be changed.

We will use this property in the mark phase, in the recursive mark step, by traversing all nodes from youngest to oldest. **If a recent node isn't marked, it can not become marked by considering older nodes!**

To visit all nodes in order of creation (young to old) requires bookkeeping. In TRAM, every node has a hidden pointer to the next less recent node.

## TRAM Garbage Collector
The TRAM garbage collector can be described as follows
```Prolog {linenos=false}
mark stacks and registers
for all nodes from recent to old
    if the node is marked, 
    	mark its two children 
    	and keep the node in the 'in use' list
    or else
    	move the node to the 'unused' list
```

The TRAM garbage collector uses a single pass in which Recursive Mark and Sweep are combined.

The space overhead is limited to a factor less than three:

* One pointer per binary node for ordering nodes from young to old 
* Less than one pointer per term per sub-term to represent nodes in a binary tree

The time overhead is very small.

The source code of the garbage collector is less than 50 lines of (C) code.

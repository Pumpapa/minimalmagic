---
title: "Memory Management"
date: 2021-09-03 15:23:00
draft: false
weight: 100
categories:
  - "TRS"
tags:
  - "Memory Management"
  - "Garbage"
  - "Garbage Collection"
---
Software uses memory to store data objects. The lifetime of an object is from the moment it is created to the first moment after which it will never be accessed. After its lifetime, the memory an object occupies could be reclaimed for reuse.

When software isn't overly complex, an object's end of life follows from the logic. At that time, a handler can be called to reclaim the memory. This is called **explicit** memory management. For instance, most opereating systems use this approach with the simple C API `malloc`, `realloc`, `calloc` and `free`.

But in more complex situations it is impossible to determine the moment after which an object is no longer needed (the question whether a program will use some object in the future is [undecidable](https://wikipedia.org/wiki/Decidability_(logic)) in general). 

**Automatic** memory managers use conservative approximations of the end-of-life: some moment at which it is certain the object will not be accessed anymore. Many approaches are based on the observation that *if a program no longer has access to an object, it is safe to reclaim it*.  

Actually 'automatic' is a misnomer: software libraries are used to govern access and administer state, hiding management from the programmer; it's only automatic from the programmer. This is impossible in general, but effective in specific cases such as abstract machines(which follow predictable engineered patterns) or circumstances where  the programmer can be required to follow such patterns. 

One example of memory management is **reference counting**: a hidden field is maintained in every object which counts the number of references to that object. Once the counter hits zero, the memory can be reclaimed. This approach is useful and efficient when:
* the moment an additional reference is created or deleted can be easily captured 
* data structure cycles are prevented or detected
* the additional memory used by the hidden field, and the computational overhead, are small compared to the user-task

However, this approach only makes sense in a relatively small number of cases

Most memory managers use accessibility-criteria in a two-phased approach called **Mark and Sweep**:

* in the mark-phase all objects accessible to a program are marked
* in the sweep-phase all unmarked objects are reclaimed

Jomtidom

* fragmentation
* recursion
* freeze, rovers

Often, the memory manager can broadly be described as follows:
* The manager maintains a set of unused memory
* When an object must be created, the space is taken from this set.
* If that set is exhausted, the mark phase is activated.
	* first, all objects immediately accessible through abstract machine registers are marked
	* then, any object accessible from a marked object is also marked
* Then the sweep-phase is activated
	* all unmarked objects are added to the 'unused' set
*  Now, memory is available **or** all memory is exhausted

hohoho
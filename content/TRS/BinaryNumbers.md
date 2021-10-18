---
title: "Minimal Magic"
date: 2021-10-18
draft: false
weight: 1100
categories:
  - "TRS"
tags:
  - "Binary Numbers"
---
Tram does not offer built-in integers, which may seem an omission, but being unopinionated is at odds with built-in data types.  However, numbers are part and parcel with computing, so they can't be missed. [Elsewhere](https://www.beginnings.blog/trs/termrewriting/) we have seen how sets can represent numbers (Peano numbers), and how terms can also be used to represent numbers. For instance, addition on `s-z` numbers is defined in the TRS
```
a(s(X),Y) = s(a(X,Y));
a(z,X) = X;
```

This TRS isn't suitable in practice. Imagine a compiler which needs to handle 32-bit values. A single term representing an average value has a depth in excess of two bilion and requires (in TRAM) about 24 GB of memory to represent. Furthermore, adding two such values requires a number of rewrite steps in the order of the depth, i.e. `2^31`=`2*10^9` steps. 

In day-to-day life, the common solution to this is a [positional numbering system](https://en.wikipedia.org/wiki/Positional_notation) as used in computers and in our dayly lives. A positional numbering system uses a fixed set of digits (humans use ten, 0-9, and computers use two, 0-1). A number is then represented by a string of digits, where the position of each digit, from right to left (usually) signifies its magnitude (each order of magnitude coincides with the number of digits). For instance, in `123` the magnitude of `2` is ten times that of `3` and a tenth of that of `1`. 

The same principle can be used in Tram, for instance to define binary numbers. We can use two constants `#0` and `#1` to represent binary digits, and we can use the function `bin` to represent strings of bits. Now, a number such as 163 can be represented as `bin(#1,bin(#0,bin(#1,bin(#0,bin(#0,bin(#0,bin(#1,#1)))))))`. 

This may still seem like a significant overhead, but the size of a term representing a number is the [same order](https://en.wikipedia.org/wiki/Big_O_notation) (Big-O) as the number of bits. There exists no representation that improves upon that!

Before proceeding we need to sanitize this specification, because currently different values can be represented which we regard equal. For instance, `bin(#0,#0)`, the number 00, is really the same as `#0`. Secondly, we set out to define strings of bits but so far we defined trees of bits, which isn't the same. For instance, the number `101` could be represented with two trees: `bin(#1,bin(#0,#1))` or `bin(bin(#1,#0),#1)`. One might say '*they are different notations of the same number*', but we aimed to define a positional numbering system. In such a system the first notation (`bin(#1,bin(#0,#1))`) equals `3` (since `bin(#0,#1)` is `#1`) but `bin(bin(#1,#0),#1)` is `5`.  

The rules to 'fix' (i.e. reduce) spurious terms are:

```
bin(#0,X) = X;
bin(X,bin(Y,Z)) = bin(add(X,Y),Z);
```

Note that the second rule is intuitively obvious if one takes `bin(A,B)` in a binary positional numbering system to mean `2*A+B`. Then `bin(X,bin(Y,Z))` is `2*X+(2*Y+Z)`, which is `2*(X+Y)+Z`

How can one be certain these these are the only spurious terms that might occur. There are two answers:
* The TRS described here also appears in [(Walters & Zantema, 1995)](https://www.beginnings.blog/references/). That article prooves that the TRS is confluent and terminating (which implies every term has a unique normal form), and that the normal forms coincide with the non-negative integers.
* A more intuitive answer is based on the following observation: every `bin`-term corresponds to a parenthesised binary number, i.e. a binary number in which as many balanced meaningful parentheses have been inserted as possible (here, we call the outer parentheses in `1((01))` meaningless because they do not define the shape).  For three bits this results in the two strings `(10)1` and `1(01)`.  
If every right-associated string is reduced, only left-associated strings remain, and they coincide trivially with binary numbers

This TRS requires the definition of addition:
```
add(#1,#1) = bin(#1,#0);
add(#0,X) = X;
add(bin(X,Y),Z) = bin(X,add(Y,Z));
```

In five rules we have now defined binary numbers with addition. The number of bits required to store a number are the same order (differing only a constant factor) as the term representation. The complexity of addition using this TRS is the same as that of adding binary numbers, although, admittedly, [adding integeres in a CPU](https://www.beginnings.blog/se/bigger-things/) takes a single clock cycle whereas it takes `O(N)` steps for a `N`-bit number.

To finalize this module, we add multiplication, which is entirely trivial.
```
mul(#0,N) = #0;
mul(#1,N) = N;
mul(bin(A,B),C) = bin(mul(A,C),mul(B,C));
```
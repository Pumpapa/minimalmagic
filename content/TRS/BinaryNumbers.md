---
title: "Binary Numbers"
date: 2021-10-18
draft: false
weight: 1100
categories:
  - "TRS"
tags:
  - "Binary Numbers"
  - "Positional Numbering System"
  - "Addition"
  - "Multiplication"
---
Tram does not offer built-in integers, which may seem an omission, but being unopinionated is at odds with built-in data types. However, numbers are part and parcel of computing, so they can't be missed. [Elsewhere](https://www.minimalmagic.blog/trs/termrewriting/) we have seen how sets can represent numbers (Peano numbers) and how terms can also be used to represent numbers. For instance, addition on `s-z` numbers is defined in the TRS
```Prolog {linenos=false}
a(s(X),Y) = s(a(X,Y));
a(z,X) = X;
```

This TRS isn't suitable in practice. Imagine a system that needs to handle 32-bit values. A single term representing a large value has a depth in excess of that number and requires (in TRAM) many gigabytes of memory to represent. Furthermore, adding two such values requires a number of rewrite steps in the order of the depth. 

The common solution to this is a [positional numbering system](https://en.wikipedia.org/wiki/Positional_notation) as used in computers and in our daily lives. A positional numbering system uses a fixed set of digits (humans use ten, 0-9, and computers use two, 0-1). A number is then represented by a string of digits, where the position of each digit, usually from right to left, signifies its magnitude (each order of magnitude coincides with the number of digits). For instance, in `123`, the magnitude of `2` is ten times that of `3` and a tenth of that of `1`. 

The same principle can be used in Tram, for instance to define binary numbers. We can use two constants `#0` and `#1` to represent binary digits, and we can use the function `bin` to represent strings of bits. Now, a number such as 163 (decimal, which is binary 10100011) can be represented as `bin(#1, bin(#0, bin(#1, bin(#0, bin(#0, bin(#0, bin(#1, #1)))))))`. 

This may still seem like a significant overhead, but the size of a term representing a number is the same order [(Big-O)](https://en.wikipedia.org/wiki/Big_O_notation) as the number of bits. There exists no representation that improves upon this!

Before proceeding, we need to sanitize this specification because currently distinct values can be represented, which we regard as equal. For instance, `bin(#0,#0)`, the number 00, is really the same as `#0`. Secondly, we set out to define strings of bits, but so far, we defined trees of bits, which isn't the same. For instance, the number `101` could be represented with two trees: `bin(#1,bin(#0,#1))` or `bin(bin(#1,#0),#1)`. One might say '*they are different notations of the same value*,' but we aimed to define a positional numbering system. In such a system the first notation, `bin(#1,bin(#0,#1))`, equals `3` (since `bin(#0,#1)` is `#1`) but `bin(bin(#1,#0),#1)` is `5`.  

The rules to 'fix' (i.e. reduce) such spurious terms are:

```Prolog {linenos=false}
bin(#0,X) = X;
bin(X,bin(Y,Z)) = bin(add(X,Y),Z);
```

Note that the second rule is intuitively obvious if one takes `bin(A, B)` in a binary positional numbering system to mean `2*A+B`. Then `bin(X,bin(Y,Z))` is `2*X+(2*Y+Z)`, which is `2*(X+Y)+Z`

How can one be certain these are the only spurious terms that might occur? There are two answers:

* The TRS described here also appears in [(Walters & Zantema, 1995)](https://www.minimalmagic.blog/references/). That article proves that the TRS is confluent and terminating (which implies every term has a unique normal form) and that the normal forms coincide with the non-negative integers.
* A more intuitive answer is based on the following observation: every `bin`-term corresponds to a parenthesized binary number, i.e., a binary number in which as many balanced, meaningful parentheses have been inserted as possible (here, we call the outer parentheses in `1((01))` meaningless because they do not alter the tree-shape).  For three bits, this results in the two strings `(10)1` and `1(01)`.  
If every right-associated string is reduced, only left-associated strings remain, and they coincide trivially with binary numbers.

This TRS requires the definition of addition:
```Prolog {linenos=false}
add(#0,X) = X;
add(#1,#1) = bin(#1,#0);
add(bin(X,Y),Z) = bin(X,add(Y,Z));
```

Completeness of these rules (proven in [(Walters & Zantema, 1995)](https://www.minimalmagic.blog/references/)) is intuitively clear when one considers

* The normal forms of this system are `#0`, `#1` and `bin(P, Q)`, for normal forms `P` and `Q`.
* `add` applied to a normal form can always be reduced.
* When it is reduced, the first argument of `add` is smaller (`Y` is smaller than `bin(X, Y)`)
* For any term, an innermost `add` can be reduced until it disappears
* By induction, any term containing `add` can be reduced until it is a normal form not containing `add`.

> *This blog is about implementation and not proof, but it makes sense to sketch how a programmer might avoid bugs leading to divergence or non-termination. The pattern is:*
> 
> * *Determine the set of normal forms (i.e., intended irreducible terms)*
> * *For every function which isn't a constructor of normal forms, ensure a rule exists for that function applied to all possible normal forms and that the term it is reduced to only contains the function applied to smaller terms*
> * *More broadly, ensure a rule exists that reduces any non-normal form to some smaller form*
> 
> *This formulation is a useful rule of thumb, but it is somewhat vague (what does 'smaller' mean), and it is incomplete in any event (bug-free systems exist which do not meet this property). If this were not the case, the study of confluence and termination mentioned in [here](https://www.minimalmagic.blog/trs/termrewriting/) would be straightforward.*

In five rules, we have now defined binary numbers with addition. The number of bits required to store a value are the same order (differing only by a constant factor) as the term representation. The complexity of addition using this TRS is the same as that of adding binary numbers, although, admittedly, adding an `N`-bit number using this TRS takes `O(N)` steps whereas [adding integers in a CPU](https://www.minimalmagic.blog/se/bigger-things/) takes a single clock cycle. However, that feat is only possible due to the massive level of parallelism in a CPU. Adding 64-bit numbers takes 64 small components to work in unison. It is a truism that everything in a computer is O[1].

To finalize this module, we add multiplication, which is entirely trivial.
```Prolog {linenos=false}
mul(#0,N) = #0;
mul(#1,N) = N;
mul(bin(A,B),C) = bin(mul(A,C),mul(B,C));
```

The module `BinaryNumbers` in TRAM.1's test suite has a few additional rules:

* Generic function `eqn` is defined elsewhere
* Equality of data `#0` and `#1` is defined elsewhere
* Symmetrical rules for `add` are added for speed
* The more complex form of `mul` is used for speed
* `succ` is a short-hand 

```Prolog {linenos=false}
bin(#0,X) = X;
bin(X,bin(Y,Z)) = bin(add(X,Y),Z);

eq(bin(N,M),bin(P,Q)) = eqn(eq(N,P),M,Q);

add(#1,#1) = bin(#1,#0);
add(#0,X) = X;
add(X,#0) = X;
add(X,bin(Y,Z)) = bin(Y,add(X,Z));
add(bin(X,Y),Z) = bin(X,add(Y,Z));

mul(#0,N) = #0;      mul(N,#0) = #0;
mul(#1,N) = N;      mul(N,#1) = N;
mul(bin(A,B),bin(C,D))
   = bin(bin(mul(A,C),add(mul(A,D),mul(B,C))),mul(B,D));

succ(N) = add(N,#1);
```




---
title: "Patterns: Writing an Encoding-Checker from Scratch"
date: 2021-11-12
draft: false
weight: 1300
categories:
  - "TRS"
tags:
  - "Patterns"
  - "Type-checking"
  - "Encoding"
---
In Tram.1, only the first five characters in a function name are significant (plus the fact whether they are longer or not; four in variables). But TRAM.1 doesn't check this: if two distinct function names are used, the first five characters of which are equal, then they are encoded to the same value.

To avoid bugs, a checker is needed, which checks if this occurs in an input TRS. Program `EncChecker` checks all variables and functions and warns if unequal identifiers will be encoded the same.

`EncChecker` uses the scanner/parser we have described in [Section Converting from C to Tram (Scanner/Parser)](/trs/convertingctotram/) and auxiliary modules `Strings`, `Lists`. All code can be found in the [TRAM.1 Github repository](https://github.com/BabelfishNL/Tram.git).

Our purpose in describing `EncChecker` is not only to document that tool but mostly to discuss a few term rewriting programming patterns.

Given a TRS, function `encchk` should indicate which functions or variables are used which differ and yet are encoded the same. We do not focus on generating nice user-oriented output. Instead, `encchk` will output a list of all identifiers used in a program and will place unequal identifiers that lead to the same value (encoding) next to each other, preceded by `$$` (which is not a legal identifier and therefore easily recognized).

That is, given a text file, the term `encchk(scan(%1))` would produce such a list.

# Pattern: Initializing Local Variables
Tram has no local variables, and yet, some functions need auxiliary data structures, which must be initialized. Inside module `EncChecker`, a list of all identifiers must be maintained, which is initialized to the empty list.

```Prolog
encchk(T) = ck(T,eol);
```

The meta-term representation produced by `scan` generates four types:

1. `trm(F,As)` for symbol `F` and argument list `As`
1. `arg(A,As)` for argument (term) `A` and argument list `As`
1. `eoa` the empty argument list
1. `var(N)` variable with name `N`

# Pattern: Function Name or Extra Parameter
The checker could maintain two lists: one for functions and one for variables, but for simplicity, a single list is used. However, encoding rules for functions and variables differ, so processing `F` in Case 1 above and `N` in Case 4 must be distinguished. 

The **function name pattern** might distinguish these cases as follows:

```Prolog {linenos=false}
ck(trm(F,As),L) = ck(As,mpqf(F,L));
...
ck(var(N),L) = mpqv(N,L);
```

But the rules for `mpqf` and `mpqv` are likely to be very similar.

The **extra parameter pattern** encodes the distinction in a data value. In this case the character class of the first character in the identifier is used: `low` for functions, and `cap` for variables:

```Prolog {linenos=false}
ck(trm(F,As),L) = ck(As,mpq(low,F,L));
...
ck(var(N),L) = mpq(cap,N,L);
```

The extra parameter pattern is used if further processing is similar, possibly diverging further along the way. We have seen this pattern being used in the function `sccc` in the scanner. The function name pattern is more common and is also used in function `sccc`.

The purpose of function `ck` is to visit all identifiers in a TRS and process them into the growing list of identifiers:

```Prolog
ck(trm(F,As),L) = ck(As,mpq(low,F,L));
ck(arg(A,As),L) = ck(As,ck(A,L));
ck(eoa,L) = L;
ck(var(N),L) = mpq(cap,N,L);
```

Function `mpq` (mnemonic: *map-query*) maps the subject identifier to the entire list of stored identifiers, querying each if it leads to the same encoding. It creates a new list if there are no further identifiers to compare or passes the subject's character class and the character class of the first stored identifier to the auxiliary function `mpqc`.

```Prolog
mpq(Cc,Id,eol) = lst(Id,eol);
mpq(Cc,Id1,lst(Id2,L)) = mpqc(Cc,cc(first(Id2)),Id1,Id2,L);
```

# Pattern: Have Your Cake
Ordinarily, sub-terms of arguments are accessed by matching the argument against a pattern. Function `mpq` could have been defined by

```Prolog
mpq(Cc,Id,eol) = lst(Id,eol);
mpq(Cc,Id1,lst(str(C,S),L)) = mpqc(Cc,cc(C),Id1,str(C,S),L);
```

Where the earlier definition passes `Id2`, the latter definition passes `str(C, S)`, which is indeed the same argument. But in an implementation, a new term will then be built, which happens to be an equal term. This might be a small concern, but the earlier definition (to me) seems clearer.

The pattern leaves an argument as-is and uses an accessor (`first`, in this case) to access a sub-term. The pattern might be called *'have your cake and eat it'*. Note that there is an implementational disadvantage here as well: an additional reduction to reduce `first`. In most cases, clarity should prevail.

The next function, `mpqc`, should distinguish two situations: the subject and the first identifier in the list have the same type or not. If they are the same type, `four` and `five` are used to identify the number of characters that should coincide. We could also use values `#4` and `#5`, but since no built-in operators exist for data values, they offer little added value.

```Prolog {linenos=false}
mpqc(low,low,Id1,Id2,L)
  = eqnc(five,eq(first(Id1),first(Id2)),rest(Id1),rest(Id2),
         low,Id1,Id2,L);
mpqc(cap,cap,Id1,Id2,L)
  = eqnc(four,eq(first(Id1),first(Id2)),rest(Id1),rest(Id2),
         cap,Id1,Id2,L);
mpqc(Cc1,Cc2,Id1,Id2,L) = lst(Id2,mpq(Cc1,Id1,L));
```

Note that the 'have-your-cake-pattern' is used again. Without it the specification would have been almost as clear:

```Prolog {linenos=false}
mpqc(low,low,str(C1,S1),str(C2,S2),L)
  = eqnc(five,eq(C2,C2),S1,S2,low,str(C1,S1),str(C2,S2),L);
mpqc(cap,cap,str(C1,S1),str(C2,S2),L)
  = eqnc(four,eq(C2,C2),S1,S2,cap,str(C1,S1),str(C2,S2),L);
mpqc(Cc1,Cc2,Id1,Id2,L) = lst(Id2,mpq(Cc1,Id1,L));
```

Finally, the heart of the checker (the function `eqnc`, for *equal encoding*) should distinguish these situations:
1. the identifiers have been entirely compared and are equal. The first identifier can be ignored
2. the characters relevant for the encoding are equal. Now the remaining characters must be compared
3. all characters are equal so far, but more characters must be compared within the encoding
4. an inequality is found beyond the length of the encoding: two different identifiers will be encoded the same
5. an inequality is found within the encoding length. These are simply distinct identifiers

```Prolog {linenos=false}
1 eqnc(N,ok,eos,eos,Cc,Id1,Id2,L) = lst(Id2,L);
2 eqnc(zero,ok,str(C1,S2),str(C2,S2),Cc,Id1,Id2,L)
  = eqnc(zero,eq(C1,C2),S1,S2,Cc,Id1,Id2,L);
3 eqnc(N,ok,str(C1,S2),str(C2,S2),Cc,Id1,Id2,L)
  = eqnc(prev(N),eq(C1,C2),S1,S2,Cc,Id1,Id2,L);
4 eqnc(zero,P,Q,R,Cc,Id1,Id2,L) 
  = lst(str('$',str('$',eos)),lst(Id1,lst(Id2,L)));
5 eqnc(N,P,Q,R,Cc,Id1,Id2,L) = lst(Id2,mpq(Cc,Id1,L));
```

Finally, auxiliary function `prev` is defined:

```Prolog
prev(five) = four; prev(four) = three; prev(three) = two; prev(two) = one; prev(one) = zero;
```

In the repository at  [TRAM.1 Github repository](https://github.com/BabelfishNL/Tram.git) a single rule is added to file `EncChecker` to test it on itself:

```Prolog
badfn1(Badv1,Badv2) = badfn2;
```
 Both functions and variables should flag an error. The output of `encchk(scan(%1))` on `EncChecker` itself:
  
```Prolog
lst("rl",lst("encchk",lst("T",lst("ck",lst("eol",lst("trm",
lst("As",lst("mpq",lst("low",lst("arg",lst("eoa",lst("var",
lst("cap",lst("Cc",lst("Id",lst("lst",lst("Id1",lst("Id2",
lst("mpqc",lst("cc",lst("first",lst("str",lst("C1",lst("C2",
lst("eqnc",lst("five",lst("eq",lst("four",lst("Cc1",
lst("Cc2",lst("eos",lst("zero",lst("Idr1",lst("Idr2",
lst("rest",lst("prev",lst(#0x24,lst(#0x24,lst("three",
lst("two",lst("one",lst("$$",lst("badfn2",lst("badfn1",
lst("$$",lst("Badv2",lst("Badv1",lst("eor",
eol))))))))))))))))))))))))))))))))))))))))))))))))
```




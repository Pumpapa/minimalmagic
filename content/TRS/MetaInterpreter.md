---
title: "Meta Interpreter and Tram"
date: 2021-09-12
draft: false
weight: 150
categories:
  - "TRS"
tags:
  - "Meta"
  - "Meta-Terms"
  - "Meta-Interpreter"
---
# The Meta-Representation of Terms
Earlier, we saw that a term is either a variable or a tuple `<f,t1, …,tk>` (for `k ≥ 1`) where `f` is a symbol and each `ti` is a term. 

When describing terms (and term rewriting systems) **within** a term rewriting system, it is necessary to have a meta-representation of terms. In the meta-representation:

* A term is represented as
    * `trm(F,Args)` for symbol `F` and terms `Args`, or
    * `var(N)` for variable named `N`
* Arguments `Args` are
    * `arg(Term, Args)` for some Term
    * `eoa` end-of-arguments, the empty list
* For now, we ignore the inner structure of function symbols or variables in this meta-interpreter. We merely state that a function `eq` exists, which returns `ok` when applied to equal function symbols or variables.

For example, the term 

```Prolog {linenos=false}
add(succ(succ(zero)),succ(zero))
```

is represented by: 

```Prolog {linenos=false}
trm(add, arg(trm(succ, arg(trm(succ, arg(trm(zero, eoa), eoa), eoa), eoa)), arg(trm(succ, arg(trm(zero, eoa), eoa), eoa), eoa)))
```

## Rewrite Systems
A term rewriting system (i.e., a list of rules) is represented as 

* `rl(Lhs,Rhs,Rules)` for terms `Lhs` and `Rhs`
* `eor`  (end-of-rules) 

Note that in many places, the meta-representation of terms is used for rules. For instance, the Scanner / Parser produces a meta-representation of a term rewriting system. That is, `rl` and `eor` are considered (pre-) defined function symbols but have no special significance in the meta-representation of terms; the meta-representation of a TRS is that of a term.

```Prolog {linenos=false}
trm("rl",
  arg(trm(... Lhs ...),
  arg(trm(... Rhs ...),
  arg(trm(...Rules...),
  eor
)
```

# The Meta-Interpreter
In this section, we present a TRS which implements term rewriting using an innermost strategy (rules 1&2, below) interpreting rules in textual order (rule 13). 


## Rewriting

* Rule 1 states: after all sub-terms have been reduced, try to reduce at the root level.  
* Rules 2 and 3 attempt to reduce innermost sub-terms.  
* Rule 4 attempts each rule at the top level. A copy of the list of rules is kept because there are no global variables. Once a reduction takes place, the entire TRS must be applied again to the reduced term.
* Rule 5 attempts to match (which will instantiate if a match is found)
* Rule 6 terminates the entire rewrite process: the term is a normal form.

```Prolog {linenos=false}
1 burewr(trm(F,As),Rs) = toprewr(trm(F,burewr(As,Rs)),Rs);
2 burewr(arg(A,As),Rs) = arg(burewr(A,Rs),burewr(As,Rs));
3 burewr(eoa,Rs) = eoa;

4 toprewr(T,Rs) = toprewrRule(T,Rs,Rs);

5 toprewrRule(T,trm("rl",arg(L,arg(R,arg(Rs,eoa)))),TRS)
    = match(L,T,eol,eoa,eoa,R,T,Rs,TRS);
6 toprewrRule(T,trm("eor",eoa),Rs) = T;
```

## Matching
Function `match` has nine arguments: 

* pattern being matched,
* term being matched,
* list of variables seen so far
* remainder of the pattern to be matched
* remainder of the term to be matched
* right-hand-side of the rule being considered
* entire term (needed if this match fails)
* remaining list of rules (needed if this match fails)
* entire TRS, needed if a match succeeds, and we need to continue after this rewrite step

The rules are straightforward:

* Rule 7 adds a variable-value pair to the list of variables seen so far. Note that this rule assumes that every variable occurs at most once on the left-hand side
* Rule 8 checks if the corresponding function symbols are equal
* Rule 9 attempts to match sub-terms
* When one subterm (and sub-pattern) has been successfully matched, the list of remaining sub-terms (and sub-patterns) are considered 
    * (10) if there are none, matching has succeeded, and instantiation should take place
    * (11) otherwise, matching continues
* Auxiliary function `matchq` either (12) continues matching (if sub-term and pattern have the same corresponding function symbol), or (13) attempts to apply the remainder list of rules if the match failed.
```Prolog {linenos=false}
7 match(var(N),ST,E,As,Bs,R,T,Rs,TRS)
    = match(As,Bs,tab(N,ST,E),eoa,eoa,R,T,Rs,TRS);
8 match(trm(F,Fs),trm(G,Gs),E,As,Bs,R,T,Rs,TRS)
    = matchq(eq(F,G),Fs,Gs,E,As,Bs,R,T,Rs,TRS);
9 match(arg(P,Ps),arg(Q,Qs),E,As,Bs,R,T,Rs,TRS)
    = match(P,Q,E,arg(Ps,As),arg(Qs,Bs),R,T,Rs,TRS);
10 match(eoa,eoa,E,eoa,eoa,R,T,Rs,TRS) =  inst(R,E,TRS);
11 match(eoa,eoa,E,arg(A,As),arg(B,Bs),R,T,Rs,TRS)
    = match(A,B,E,As,Bs,R,T,Rs,TRS);
    
12 matchq(true,Fs,Gs,E,As,Bs,R,T,Rs,TRS) 
    = match(Fs,Gs,E,As,Bs,R,T,Rs,TRS);
13 matchq(X,Fs,Gs,E,As,Bs,R,T,Rs,TRS) = toprewrRule(T,Rs,TRS);
```
## Instantiation
Instantiation is straightforward:

* (14) a variable is instantiated with the value with which it was matched. Note that every variable on the right-hand side must have been matched, so there is no check for the reverse
* (15-17) all compound terms are recursively instantiated
* (18-20) simple table lookup of a matched variable
```Prolog {linenos=false}
14 inst(var(N),E,TRS) = get(N,E);
15 inst(trm(F,As),E,TRS) = toprewr(trm(F,inst(As,E,TRS)),TRS);
16 inst(eoa,E,TRS) = eoa;
17 inst(arg(A,As),E,TRS) = arg(inst(A,E,TRS),inst(As,E,TRS));

18 get(N,tab(M,T,E)) = getq(eq(N,M),N,T,E);

19 getq(ok,N,T,E) = T;
20 getq(X,N,T,E) = get(N,E);
```
# Conclusion
The upside of a meta-interpreter is that it offers a precise (correct, complete, clear, and concise) definition of innermost term rewriting. So far, we have been informal, sketching rather than formally detailing term rewriting, but the meta-interpreter changes that.



## TRAM.1
A downside of a meta-interpreter is that it doesn't directly bring us closer to an implementation -- it only offers an implementation if one already has an implementation.

TRAM.1 is an implementation written in C, which nonetheless follows the structure of the meta-interpreter. The key difference is that the meta-interpreter uses recursion heavily, while recursion in C is usually limited to tens of thousands of levels. That may sound like a lot but consider: `match` is attempted recursively through all rules (Rule 13), and when a match is found, `inst` is called (Rule 10), which recursively continues reduction (Rule 15). This means the depth of the recursion is the length of the rewrite sequence, which can be anything. This recursion must be transformed to iteration in C.

TRAM.1 is presented further in [TRAM.1](/trs/TRAM.1)

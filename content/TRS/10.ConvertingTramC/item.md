---
title: "Converting from Tram to C (Rewrite Engine)"
date: 2021-10-18
hero_classes: text-light title-h1h2 overlay-dark-gradient hero-large parallax
hero_image: pexels-toa-heftiba-şinca-1194420.jpg
blog_url: /trs
show_sidebar: true
show_breadcrumbs: true
show_pagination: true
categories: 
- "TRS"
tag:
- "Rewrite Engine"
- "C"
---
Section [Tram -- A Meta-Interpreter](https://www.minimalmagic.blog/trs/termrewriting/) describes a rewrite engine on meta-terms. That specification is used as the basis for the C implementation in TRAM.1.

## States
A big difference between term rewriting and the C programmers' model is the limited availability of recursion in C. [Section Converting a Scanner from C to Tram](https://www.minimalmagic.blog/trs/convertingctotram/) uses an explicit stack to avoid recursion in C, in a way transforming a recursive descent parser to a push-down automaton.

But the simple parser has only a single state in which recursion is initiated (after reading a `(`), and only a single state after which it is returned from (after `)`). In the rewrite engine, more states exist. Consider the first two rules in the meta-interpreter:

```Prolog
burewr(trm(F,As),Rs) = toprewr(trm(F,burewr(As,Rs)),Rs);
burewr(arg(A,As),Rs) = arg(burewr(A,Rs),burewr(As,Rs));
```
In Rule 1, after `burewr`  returns a result, `toprewr` must be called. That pattern, *after this do that,* suggests a state, which is either maintained explicitly or returned by `burewr` (in this case). In Rule 2, there are two recursive calls to `burewr`, so these are (at least) two additional states.

## Nodes
A second difference between the meta-terms and the rewrite engine has been discussed in [Section Nodes](https://www.minimalmagic.blog/trs/tram/): TRAM represents terms as nodes (structures with two fields: `car` and `cdr`) (ignoring memory management for the moment). This means 

* there is no distinction (in TRAM) between `trm(...)` and `arg(...)`. A `trm(...)` head-node is recognized by the fact that the `car` is a symbol
* a variable in the meta-term representation (`var(name)`) is a base value in TRAM (a 32-bit value with least significant byte binary 00000011)

## Basics
The entire implementation of TRAM.1 is [discussed in this section](https://www.minimalmagic.blog/trs/annotated-tram.1/), so here we only mention a few primitives used in the rewrite engine.

* predicates to discern values  
```C
#define isREF(t) (((t)&1)==0)  
#define isNREF(t) (((t)&1)==1)  
#define isVAR(t) (((t)&0xff)==3)  
#define isFUN(t) (((t)&3==3)&&((t)&0xff)>3)  
```
* Conversion pointer <==> reference value
```C
#define ref(t) (mem+(t)/2)  
#define idx(r) ((r-mem)*2)  
```
* Node structure and function to create a new node
```C
typedef struct _node {  
    tval car, cdr, nxt;  
} node;  
typedef node *ref;  
  
ref new(tval x,tval y);  
```
* Stack manipulation
```C
#define Push(X,a) X=new(a,idx(X));  
#define Pop(X) X->car; X=ref(X->cdr);  
#define PopRef(X) ref(X->car); X=ref(X->cdr);  
```

# TRAM.1's Rewrite Engine

The meta-interpreter discussed in [Section Term Rewriting](https://www.minimalmagic.blog/trs/termrewriting/#a-meta-interpreter).

The rewrite engine is a push-down automaton where the main loop branches based on the current state. The initial state is `BURED` to invoke bottom-up reduction given a term in register `T` using 'program' (TRS) in register `P`. 

```C
ref reduce (/*tval T, ref P*/) {  
    S = nil;  
    int state=BURED;  
    tval f, t, pat;  
    ref p, sub;  
    Push(S,asDTA(ALLDONE));    
    for (;;) {  
    if (Dbg >= DCycles) fprintf(stdout, "%s ", prstates[state - 1000]);  
    switch (state) { // T is subject term, V is result
```

## `burewr`
```Prolog {linenos=false}
 1   burewr(trm(F,As),Rs) = toprewr(trm(F,burewr(As,Rs)),Rs);
 2   burewr(arg(A,As),Rs) = arg(burewr(A,Rs),burewr(As,Rs));
 3   burewr(eoa,Rs) = eoa;
```

Note that in TRAM, there is no structural distinction between `trm(...)` and `arg(...)`.

Rules 1-3 of the meta-interpreter define bottom-up rewriting. An imperative description of rules 1-3 is:

* Rules 1-2 push down `burewr` through an entire tree, such that `burewr` is applied to each node in that tree, which replaces that node with its `burewr` image
* Rule 3 states that an empty tree isn't changed by `burewr`;
* Rule 1 states that once a proper sub-term has been normalized, `topred` should be applied.

Four states can be distinguished:

* `BURED`, the initial state
* `BUDONECDR`. TRAM implements the right-most innermost strategy, so the sub-term `burewr(As, Rs)` is reduced first (in rules 1 and 2). The result will be captured by the state at which the `cdr` of the `arg(...)` or `trm(...)` node has been handled (`BUDONECDR` for bottom-up, done cdr)
* `BUDONEBOTH` is self-described. In the case of Rule 2, `burewr` has been applied to the entire tree; in the case of Rule 1, the next state should now be visited:
* `TOPRED`, try to reduce a term at root level

Lines

* 2-4: A base value or the null pointer is irreducible (as in Rule 3). Pop the next state
* 7-9: Otherwise, save the `car`, push the subsequent state, and continue with the `cdr`
* 12-15: Pop the `car`, push the normalized `cdr` and the subsequent state, and recurse
* 18-21: If the car is a node, this is an `arg(...)` node; create the new node (as in Rule 2)
* 24-26: Otherwise, this is a normalized `trm(...)`. Apply `TOPRED`


```C
case BURED: //T is term
    if (isNREF(T) || T == 0) {
        V = T;
        state = PopDTA(S);
        break;
    }
    Push(S, ref(T)->car);
    Push(S, asDTA(BUDONECDR));
    T = ref(T)->cdr;
    break;
case BUDONECDR: //V is cdr, tos is car-to-do
    T = Pop(S);
    Push(S, V);
    Push(S, asDTA(BUDONEBOTH));
    state = BURED;
    break;
case BUDONEBOTH: //(V is car), tos is cdr
    if (isREF(V)) {
        T = Pop(S);
        V = idx(new(V, T));
        state = PopDTA(S);
        break;
    }
    f = V;
    T = Pop(S);
    state = TOPRED;
    break;
```


## `toprewr`
```Prolog {linenos=false}
4   toprewr(T,Rs) = toprewrRule(T,Rs,Rs);
5   toprewrRule(T,trm("rl",arg(L,arg(R,arg(Rs,eoa)))),TRS)
    = match(L,T,eol,eoa,eoa,R,T,Rs,TRS);
6   toprewrRule(T,trm("eor",eoa),Rs) = T;
. . .
10  match(eoa,eoa,E,eoa,eoa,R,T,Rs,TRS) =  inst(R,E,TRS);
. . .
13  matchq(X,Fs,Gs,E,As,Bs,R,T,Rs,TRS) = toprewrRule(T,Rs,TRS);
```


Function `toprewr` sets up for `toprewrRule` to attempt each rule in the program/TRS in function `match` . If this succeeds, the right-hand side is instantiated (Rule 10); if it fails, function `match` should attempt the next alternative (Rule 13).

Five states can be distinguished:

* `TOPRED`, as mentioned, sets up the loop at root level
* `FORRULES`, a 'for' loop over all rules
* `MATCH`, the state in which a term is matched
* `MATCHDONE`: matching can fail deep in the recursion. The token `MATCHDONE` is pushed to be able to clear the stack when matching fails, or it is encountered on the stack when all work-to-do has been done
* `BUILD`. There is a significant difference between the meta-interpreter and the C implementation if matching fails. In the meta-interpreter, the term being reduced has already been built and can be passed on as-is (term T in Rule 13). In the C implementation the term hasn't yet been built and exists as a separate symbol `F` and arguments `T` (See Lines 24-25 in the C code above).
```C
case TOPRED: //(f is fun,T = args)  
    if (Dbg >= DStepDump) pval(f, 1);  
    p = P;  
    t = T;  
    state = FORRULES;  
    if (Dbg >= DSteps) Drulei = 0;  
    break;  
case FORRULES: //(f,t,p, T, P)  
    if (p == nil) { // eor  
        state = BUILD;  
        break;  
    }  
    if (Dbg >= DSteps) Drulei++;  
    if (ref(ref(p->car)->car)->car != f) {  
        p = ref(p->cdr);  
        break;  
    }  
    sub = nil;  
    Push(S, asDTA(MATCHDONE));  
    state = MATCH;  
    pat = ref(ref(p->car)->car)->cdr;  
    break;  
case MATCH: //(t,pat,sub,p, T, P)
```
Lines

* 3-5: set up loop
* 9-10: no match; build the term
* 14-15: the outermost function symbol of the subject term and that of the left-hand side of the rule **differ**; the next rule is attempted
* 18-21: the outermost function symbol of the subject term and that of the left-hand side of the rule **are the same**; matching is set up with an as-yet empty substitution

## `match`
The arguments in `match(X,ST,E,As,Bs,R,T,Rs,TRS)` are:

* `X`: the current pattern (sub-term of the left-hand side of the rule)
* `ST`: the current sub-term being matched
* `E`: the substitution in the form of `tab(<variable-name>, <value>, <rest-of-substitution>)`. No check is done to see if the variable was already defined. That would constitute a non-linear TRS
* `As`, `Bs`: the sub-terms of the subject term and pattern that still need to be matched. Note that constructor `arg(...)` is used to string together sub-terms that need to be inspected. In this sense, `As` and `Bs` could also be described as stacks of work-yet-to-be-done
* `R`: the right-hand side of the current rule
* `T`: the entire subject-term, to be used if matching fails
* `Rs`: the remaining rules, to be used if matching fails
* `TRS`: the entire rewrite system, to be used after the current subject term is reduced

```Prolog {linenos=false}
7   match(var(N),ST,E,As,Bs,R,T,Rs,TRS)
    = match(As,Bs,tab(N,ST,E),eoa,eoa,R,T,Rs,TRS);
8   match(trm(F,Fs),trm(G,Gs),E,As,Bs,R,T,Rs,TRS)
    = matchq(eq(F,G),Fs,Gs,E,As,Bs,R,T,Rs,TRS);
9   match(arg(P,Ps),arg(Q,Qs),E,As,Bs,R,T,Rs,TRS)
    = match(P,Q,E,arg(Ps,As),arg(Qs,Bs),R,T,Rs,TRS);
10  match(eoa,eoa,E,eoa,eoa,R,T,Rs,TRS) =  inst(R,E,TRS);
11  match(eoa,eoa,E,arg(A,As),arg(B,Bs),R,T,Rs,TRS)
    = match(A,B,E,As,Bs,R,T,Rs,TRS);
12  matchq(true,Fs,Gs,E,As,Bs,R,T,Rs,TRS) 
    = match(Fs,Gs,E,As,Bs,R,T,Rs,TRS);
13  matchq(X,Fs,Gs,E,As,Bs,R,T,Rs,TRS) = toprewrRule(T,Rs,TRS);
```

The logic is straightforward:

* Rule 7-11 match different forms of a pattern
* Rule 7 matches a variable, which always succeeds, and which results in substitution being extended
* Rules 8-9 match term-trees. Note that matching a `trm(...)`  against an `arg(...)` would signify a syntactical error in the subject term or TRS
* Rule 8: if the sub-term and pattern have the shape of a symbol applied to arguments, compare the symbols
* Rule 9: continue matching in the first sub-term, and push the remainder to be done
* Rule 10:If the sub-term has been checked, and if the work yet to be done is exhausted, all matches have succeeded, and the rule can be applied
* Rule 11: otherwise, the next sub-term to be done is matched against
* Rules 12-13: auxiliary function `matchq` proceeds or fails, according to (in) equality of symbols

Five states can be distinguished:

* `MATCH`, `MATCHDONE`: as mentioned
* `fail` is not a state but a label to be jumped to when matching fails
*  `MATCHDONECAR`: the `car` has been verified; continue with the `cdr`
*  `INST`: match succeeded; instantiate the right-hand side
```C
case MATCH: //(t,pat,sub,p, T, P)
    if (isREF(pat) && pat != 0) { // compound
        if (isNREF(t)) goto fail;
        Push(S, ref(t)->cdr);
        Push(S, ref(pat)->cdr);
        Push(S, asDTA(MATCHDONECAR));
        pat = ref(pat)->car;
        t = ref(t)->car;
        break;
    }
    if (isVAR(pat)) {
        sub = new(idx(new(pat, t)), idx(sub));
        state = PopDTA(S);
        break;
    }
    if (pat == t) {
        state = PopDTA(S);
        break;
    }
    //fallthrough intended
fail:
    p = ref(p->cdr);
    t = T;
    do {
        state = PopDTA(S);
    } while (state != MATCHDONE);
    state = FORRULES;
    break;
case MATCHDONECAR://(sub,p) tos is pat.cdr, 2nd is trm.cdr
    pat = Pop(S);
    t = Pop(S);
    state = MATCH;
    break;
case MATCHDONE://(sub,p)
    pat = ref(p->car)->cdr; //rhs
    state = INST;
    if (Dbg >= DSteps) Drewrcnt++;
    if (Dbg >= DSteps) printf("Rule %d, Steps %d\n", Drulei, Drewrcnt);
    break;
case INST: //(pat,sub)
```
Lines

* 3: if the pattern is a node, and the sub-term is not, matching fails
* 4-8: otherwise, push the `cdr`'s and continue with the `car` (i.e., recurse)
* 11-13: add a variable and value to the substitution
* 16-17: otherwise, pattern and term are base values. They only match if they are equal
* 22-27: failure to match sets the program to the next rule; sets the current term to the initial term; clears the stack; and continues the loop
* 30-32: pop the cdr and continue matching
* 35-36: get and instantiate the right-hand side

## `inst`
Function `inst` is trivial; no additional states ensue.

```Prolog {linenos=false}
14  inst(var(N),E,TRS) = get(N,E);
15  inst(trm(F,As),E,TRS) = toprewr(trm(F,inst(As,E,TRS)),TRS);
16  inst(eoa,E,TRS) = eoa;
17  inst(arg(A,As),E,TRS) = arg(inst(A,E,TRS),inst(As,E,TRS));
18  get(N,tab(M,T,E)) = getq(eq(N,M),N,T,E);
19  getq(ok,N,T,E) = T;
20  getq(X,N,T,E) = get(N,E);
```

* Rule 14, 18-20: for every variable, get its associated value
* Rules 15-17: recursively instantiate all sub-terms of the right-hand side
* Rule 15: for every compound subterm, reduce it at the top level. Since an innermost strategy is followed, the values of variables have already been normalized

```C
case INST: //(pat,sub)
    if (isREF(pat) && pat != 0) {
        Push(S, ref(pat)->cdr);
        pat = ref(pat)->car;
        Push(S, asDTA(INSTDONECAR));
        break;
    }
    if (isVAR(pat)) {// use p as tmp in sub
        p = sub;
        while (ref(p->car)->car != pat) {
            p = ref(p->cdr);
        }
        V = ref(p->car)->cdr;
        state = PopDTA(S);
        break;
    }
    V = pat;
    state = PopDTA(S);
    break;
case INSTDONECAR: // V is car
    pat = Pop(S);
    Push(S, V);
    Push(S, asDTA(INSTDONEBOTH));
    state = INST;
    break;
case INSTDONEBOTH: // V is cdr, ToS = car
    t = Pop(S);
    if (isFUN(t)) {
        f = t;
        T = V;
        Push(S, pat);
        Push(S, idx(sub));
        Push(S, asDTA(INSTCONT));
        state = TOPRED;
        break;
    }
    V = idx(new(t, V));
    state = PopDTA(S);
    break;
case INSTCONT: {// V is car
    sub = PopRef(S);
    pat = Pop(S);
    state = PopDTA(S);
    break;
    }
```

Lines

* 2-5: for a compound, push the `cdr` and continue with the `car`
* 9-14: for a variable, fetch the corresponding value. This implements Rules 14, 18-20
* 17-18: done; continue
* 21-24: save the `car`, continue with the `cdr`
* 27-28: is this a `trm(...)` node or an `arg(...)` node?
* 29-34: topreduce entire `trm(...)`. Note that the current state of instantiation is saved in lines 31-33. Executing `TOPRED` is deep recursion that may require many rewrite steps
* 37-38: otherwise, build the `arg(...)` node and continue
* 41-43: a saved instantiation is continued after intermediate `TOPRED` of proper sub-term of the right-hand side

## `ALLDONE`
The final segment is trivial.

* 2-3: as mentioned, build a node if no rule is applicable
* 6-7: if all seems well, return the normal form

```C
case BUILD:
    V = idx(new(f, T));
    state = PopDTA(S);
    break;
case ALLDONE: 
    if (S != nil) error("Stack should be empty!");
    return ref(V);
default: error("Bad state!");
}
```




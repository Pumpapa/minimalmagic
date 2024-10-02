---
title: "Converting from C to Tram (Scanner/Parser)"
date: 2021-10-18
hero_classes: text-light title-h1h2 overlay-dark-gradient hero-large parallax
hero_image: pexels-isabella-mariana-1988681.jpg
blog_url: /trs
show_sidebar: true
show_breadcrumbs: true
show_pagination: true
categories: 
- "TRS"
tag:
- "Parser"
- "C"
---
This section describes how TRAM's scanner / parser written in C was used as a basis to implement the scanner / parser in Tram.

## Annotated Scanner / Parser in C

The scanner is a loop which processes input characters and terminates when EOF is read. Inside the loop a `switch` branches based on the current character under consideration.

Variables:

* `v` holds the currently value being read
* `num` and `sgn` are auxiliary variable used to read numbers
* `len` is an auxiliary variable used to read identifiers 
* `in` and `nm` are file name and descriptor
* `S` is used as a stack and has been initialized in the context
* register `V` is used as an auxiliary register to safeguard terms from garbage collection
* register `T` contains a list of sub-terms read so far using `-s`

Note: a term can be a variable, a compound term (`tram(...)`), or a sole function symbol `f` which represents a term with zero arguments. In various places where the parser expects a term, but where the scanner has seen a symbol, that symbol must be coerced to a term (by replacing `f` with `new(f,0)`). Wherever the text mentions a (possibly coerced) term, this mechanism is intended without further explanation (the code is self-evident).

```C
tval readTerm(char *nm) { 
    tval num, v;  
    int sgn, len;  
    if ((in = fopen(nm, "r"))==NULL) {  
        error("unknown file %s",nm);  
    };  
    c = fgetc(in);  
    for (;;) {  
 switch (c) {  
```

Note: immediately after the switch statement is the single statement:

```C
    }
    c = fgetc(in);
    }
```

This means that the `break` statement results in the next character being read and the loop restarted, whereas `continue` restarts the loop without reading a character (i.e., when the next character has already been read).

Whitespace and comments are simply skipped. 

```C
    case ' ': case '\n': case '\r': case '\t': 
    case '\v': case '\f':  
    break;  
    case '!': // comment  
    while ((c=fgetc(in))!='\n') {}  
    break;  
```

A quoted character is immediately encoded to a corresponding data value.

```C
    case '\'': //data (char)  
    v = (fgetc(in)<<2)|1;  
    if ((c=fgetc(in))!='\'') 
    error("expected ' got character %c (%d)",c,c);  
    break;  
```
A `#` can be followed by 

* `0x` followed by a hexadecimal value, or 
* a decimal value. A `0` not followed by `x` is the beginning of a decimal value (`goto` is used to jump into the decimal handler). 
The encoding data value is computed on the fly.

```C
case '#': // data (hex or dec)  
    if ((c=fgetc(in))=='0') {  
       if ((c=fgetc(in))=='x') {  
       num = 0;  
       while ((c = fgetc(in)) >= '0' && c <= '9' 
               || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F') {  
       num = 16 * num + 
             (c <= '9' ? c - '0' 
                : c <= 'F' ? 10 + c - 'A' : 10 + c - 'a');  
       }  
       v = (num << 2) | 1;  
       continue;  
       } else if (c>='0'&&c<='9') {  
       sgn = 1;  
       num = c-'0';  
       goto decimal;  
       } else {  
       v = 1;  
       continue;  
       }  
    } else {  
       if (c=='-') {  
       sgn = -1;  
       num = 0;  
       } else {  
       sgn = 1;  
       num = c-'0';  
       }  
     decimal:  
       while ((c=fgetc(in))>='0'&&c<='9') {  
       num = 10*num+c-'0';  
       }  
       v = ((sgn*num)<<2)|1;  
       continue;  
    }
```

Meta variables contain a decimal number identifying the n-th element (in reverse order) from the list in `T`. This value is returned as the value just read.

```C
case '%': // dec (meta-variable)
    num = 0;  
    while ((c=fgetc(in))>='0'&&c<='9') {  
    num = 10*num+c-'0';  
    }  
    for (v=T, len=0; v!=0; v=ref(v)->cdr) len++;  
    num = len-num;  
    for (v=T; num--; v=ref(v)->cdr) {}  
    v = ref(v)->car;  
    continue;  
```


A Tram variable consists of `*`, `&` or an upper-case letter, followed by between zero and three letters, digits or `.`. Only the first four characters are significant, although variables shorter than 5 characters and variables longer than 4 characters are distinguished, so `Abcd` and `Abcde` differ, but `Abcde` and `Abcdf` are considered identical.

<img src="https://www.minimalmagic.blog/user/pages/01.TRS/images/TaggedValues.png" alt="Tagged Values" style="float:right; width:60%;">

A symbol consists of `$`, `@` or a lower-case letter, followed by between zero and four letters, digits or `.`. Only the first five characters are significant, although symbols shorter than 6 characters and symbols longer than 5 characters are distinguished, so `abcde` and `abcdef` differ, but `abcdef` and `abcdeg` are considered identical.

Only the first five characters are significant, so `abcde` and `abcdef` differ, but `abcdef` and `abcdeg` are considered identical.

* In a variable or symbol the L bit signifies whether the identifier is longer than the max (4 for variables, 5 for symbols)
* `AAAAA` in a variable, or `FFFFF` in a symbol encode the first character
* `aaaaaa`, `bbbbbb`, etcetera encode subsequent characters.

```C
case '*': case '&': // Var  
case 'A': case 'B': case 'C': case 'D': case 'E': case 'F': case 'G':  
case 'H': case 'I': case 'J': case 'K': case 'L': case 'M': case 'N':  
case 'O': case 'P': case 'Q': case 'R': case 'S': case 'T': case 'U':  
case 'V': case 'W': case 'X': case 'Y': case 'Z':  
    len = 1;  
    num = c=='*'?1:c=='&'?2:c-'A'+3;  
    while ((c=fgetc(in))=='.'||c>='0'&&c<='9'
           ||c>='a'&&c<='z'||c>='A'&&c<='Z') {  
        if (++len<=4) {  
            num = num << 6 | (c == '^' ? 1 
      : c - (c <= '9' ? '0'-2 : (c <= 'Z' ? 'A'-12 : 'a'-38)));  
        }  
    }  
    sgn = len>4?1<<31:0;  
    while (++len<=4) {  
        num <<= 6;  
    }  
    v = (num<<8)|sgn|3;  
    continue;  
case '@': case '$': // Id  
case 'a': case 'b': case 'c': case 'd': case 'e': case 'f': case 'g':  
case 'h': case 'i': case 'j': case 'k': case 'l': case 'm': case 'n':  
case 'o': case 'p': case 'q': case 'r': case 's': case 't': case 'u':  
case 'v': case 'w': case 'x': case 'y': case 'z':  
    len = 1;  
    num = c=='@'?1:c=='$'?2:c-'a'+3;  
    while ((c=fgetc(in))=='.'||c>='0'&&c<='9'
           ||c>='a'&&c<='z'||c>='A'&&c<='Z') {  
        if (++len<=5) {  
            num = num << 6 | (c == '^' ? 1 
    : c - (c <= '9' ? '0'-2 : (c <= 'Z' ? 'A'-12 : 'a'-38)));  
        }  
    }  
    sgn = len>5?4:0;  
    while (++len<=5) {  
        num <<= 6;  
    }  
    v = (num<<8) | (num>>21)&0xf8 | sgn | 3;  
    continue;
```
So far, we have seen a scanner and not a parser. The only feature in Tram that isn't lexical and is context free are parentheses. The scanner / parser is a push-down automaton which uses a stack (`S`) to hold partial results.

When a `(` is encountered, a symbol must just have been seen. The current value is kept in variable `v`, so a term with `v` as outermost function symbol is pushed on the stack (`new(v,0)`). This term will be extended as arguments are parsed.
```C
case '(':  
    Push(S, idx(new(v,0)));  
    v=0;  
    break;  
```
A `,` means a (possibly coerced) term has just been read. That term is pushed on whatever partial term is on the stack. These pushed sub-terms therefore occur in the wrong order. We will fix this at the closing `)`. Note that `V` is cleared to avoid floating garbage, and that `v` is cleared because there is no current read object.
```C
case ',':  
    if (isFUN(v)) v=idx(new(v,0));  
    V = Pop(S);  
    Push(S, idx(new(v,V)));  
    V=v=0;  
    break;  
```
Just like a `,`, a  `)` immediately follows a (possibly coerced) term. However, that structure is in the wrong order: The last argument is on top, and the function symbols are deepest. A new object is created in which all parts occur in the right order.
```C
case ')':  
    if (isFUN(v)) v=idx(new(v,0));  
    v=idx(new(v,0));  
    V = Pop(S);  
    while (V!=0) {  
    v=idx(new(ref(V)->car,v));  
    V = ref(V)->cdr;  
    }  
    break;  
```
`=` occurs in a rule, but otherwise behaves as a `,`.
```C
case '=':  
    if (isFUN(v)) v=idx(new(v,0));  
    Push(S,v);  
    v=0;  
    break;  
```
Similarly, `;` terminates a rule, and behaves somewhat as a `)`. However, no term-structure with an outermost function symbol is created for rules, because a linked list with pairs is more efficient. That list is needed in reverse textual order, so the pair of the left- and right-hand sides is left on the stack.
```C
case ';':  
    if (isFUN(v)) v=idx(new(v,0));  
    V = Pop(S);  
    Push(S, idx(new(V,v)));  
    v=0; V=0;  
    break;  
```
Finally, two situations might occur:

* A term is read (`S==nil`)  
The (possibly coerced) term is returned.
* A TRS is read  (`S!=nil`)  
The stack contains the pairs of left- and right-hand sides in reverse order. It is returned (`S` is reset)
```C
    case EOF:  
    if (S!=nil) {  
    v=idx(S);  
    S=nil;  
    }  
    if (isFUN(v)) v=idx(new(v,0));  
    return v;  
    default:  
    error("unexpected character %c (%d)",c,c);  
    };  
    c = fgetc(in);  
    }  
}
```

# Scanner / Parser in Tram
The main loop is implemented in the function `sccc`, short for 'scan with character class'. This function implements the `switch` statement of the automaton and has these arguments `sccc(Cc, C, S, V, Stck)`

* `C` is the character currently being considered
* `Cc` is its character class
* `S` is the remainder of the input (string)
* `V` is the current value 
* `Stck` is the current stack

Several aspects merit explanation:

* Character class `spec` concerns data-values, which start with `'` or `#`
* Identifiers are scanned by `scsym`; the character class of the first character (`low` or `cap` identifies symbols and variables, respectively)
* The last rule for `sccc` 'catches' all tokens which follow a term: `,`, `;`, `=` and `)`.  They are processed by `scaffix` (scan affix).
* `first` is a function (defined in module `Lists.trm`) which returns the first element of a list or string (`first(lst(X,L)) = X; first(str(C,S)) = C;`). The function is partial: `first(eos)` is a normal form. In the context of the scanner, `first(eos)` means: '*we have attempted to read a character when the input was already exhausted*'. That is, `first(eos)` has the same meaning as  `EOF` in C. This situation is handled by `scfinalize`  (scan finalize)

Function `sccomm` scans and further ignores a comment.

```Prolog
scan(str(C,S)) = sccc(cc(C),C,S,null,eol);

sccc(ws,C,S,V,Stck) = sccc(cc(first(S)),first(S),rest(S),V,Stck);
sccc(comm,C,S,V,Stck) = sccomm(S,V,Stck);
sccc(spec,C,S,V,Stck) = scspec(C,S,Stck);
sccc(cap,C,str(B,S),V,Stck) = scsym(cc(B),B,S,cap,str(C,eos),Stck);
sccc(low,C,str(B,S),V,Stck) = scsym(cc(B),B,S,low,str(C,eos),Stck);
sccc(lpar,C,S,V,Stck)
  = sccc(cc(first(S)),first(S),
          rest(S),null,lst(trm(V,eoa),Stck));
sccc(cc(first(eos)),C,S,V,Stck) = scfinalize(C,S,V,Stck);
sccc(CC,C,S,V,Stck) = scaffix(CC,S,V,Stck);

sccomm(str(#0xA,S),V,Stck) = sccc(cc(first(S)),first(S),rest(S),V,Stck);
sccomm(str(C,S),V,Stck) = sccomm(S,V,Stck);
```
Tram does not have a notation for character classes, so all characters are shown explicitly. The function `cc` determines the character class of every valid input character
```Prolog
cc('*') = low;  cc('&') = low;  cc('a') = low;  cc('b') = low;  
cc('c') = low;  cc('d') = low;  cc('e') = low;  cc('f') = low;  
cc('g') = low;  cc('h') = low;  cc('i') = low;  cc('j') = low;
cc('k') = low;  cc('l') = low;  cc('m') = low;  cc('n') = low;  
cc('o') = low;  cc('p') = low;  cc('q') = low;  cc('r') = low;  
cc('s') = low;  cc('t') = low;  cc('u') = low;  cc('v') = low;  
cc('w') = low;  cc('x') = low;  cc('y') = low;  cc('z') = low;

cc('@') = cap;  cc('$') = cap;  cc('A') = cap;  cc('B') = cap;  
cc('C') = cap;  cc('D') = cap;  cc('E') = cap;  cc('F') = cap;  
cc('G') = cap;  cc('H') = cap;  cc('I') = cap;  cc('J') = cap;
cc('K') = cap;  cc('L') = cap;  cc('M') = cap;  cc('N') = cap;  
cc('O') = cap;  cc('P') = cap;  cc('Q') = cap;  cc('R') = cap;  
cc('S') = cap;  cc('T') = cap;  cc('U') = cap;  cc('V') = cap;  
cc('W') = cap;  cc('X') = cap;  cc('Y') = cap;  cc('Z') = cap;

cc('0') = num;  cc('1') = num;  cc('2') = num;  cc('3') = num;  
cc('4') = num;  cc('5') = num;  cc('6') = num;  cc('7') = num;  
cc('8') = num;  cc('9') = num;

cc('(') = lpar; cc(')') = rpar; cc(',') = sepa;
cc('=') = equ;  cc(';') = sepa; cc(':') = colon; ! cc('.') = period;
cc(#0x27) = spec; cc('#') = spec;
cc('!') = comm; cc('"') = quot;

cc(#0x20) = ws;  cc(#0xA) = ws;  cc(#0xD) = ws;  cc(#0x9) = ws;
```

Note: this scanner doesn't treat `.` correctly => ToDo.

## `scaffix`
Function `scaffix` processes a symbol immediately following a term (i.e., `,`, `=`, `;` and `)`). 

An `=` only occurs after the (possibly coerced) left-hand side of a rule. A partial rule is pushed with only the left-hand side as argument.

Otherwise, the top of the stack is a partial term, and the current value ((possibly coerced) term or variable) is added as the last argument in the top of the stack.

```Prolog {linenos=false}
scaffix(equ,S,trm(F,As),Stck)
= sclini(equ,S,lst(trm(str('r',str('l',eos)),
                       arg(trm(F,As),eoa)),Stck));
scaffix(equ,S,F,Stck)
= sclini(equ,S,lst(trm(str('r',str('l',eos)),
                       arg(trm(F,eoa),eoa)),Stck));
scaffix(Cc,S,var(V),lst(T,Stck))
= sclini(Cc,S,lst(append(var(V),T),Stck));
scaffix(Cc,S,str(F,Fs),lst(T,Stck))
= sclini(Cc,S,lst(append(trm(str(F,Fs),eoa),T),Stck));
scaffix(Cc,S,trm(F,As),lst(T,Stck))
= sclini(Cc,S,lst(append(trm(F,As),T),Stck));
scaffix(Cc,S,F,lst(T,Stck))
= sclini(Cc,S,lst(append(trm(F,eoa),T),Stck));
```

## `sclini`
Function `sclini` accepts a `)` or any of (`,`, `=` and `;`). In the first case (done; the last term is complete), the top-of-stack is popped and set as current value; in the second case (not yet done, the last term is incomplete and remains on the stack to be extended). 

```Prolog
sclini(rpar,S,lst(T,Stck)) = sccc(cc(first(S)),first(S),rest(S),T,Stck);
sclini(Cc,S,Stck) = sccc(cc(first(S)),first(S),rest(S),null,Stck);
```

## `scfinalize` and `scancollrls`
Function `scfinalize` processes EOF. yielding either the list of pairs of left- and right-hand sides, or a term (possibly an extended symbol).

Note that whereas the C implementation needs the rules in reverse order (because thay need to be joined by the `-C` option), the Tram version can at this moment only process a single module. But: rules have been pushed in reverse order, so function `scancollrls` reverses the order of the rules.

```Prolog {linenos=false}
scfinalize(first(eos),rest(eos),trm(F,As),eol) = trm(F,As);
scfinalize(first(eos),rest(eos),F,eol) = trm(F,eoa);
scfinalize(first(eos),rest(eos),null,Stck) = sccollrls(eol,Stck);

sccollrls(Rs,lst(trm(str('r',str('l',eos)),arg(L,arg(R,eoa))),Stck))
 = sccollrls(trm(str('r',str('l',eos)),
                 arg(L,arg(R,arg(Rs,eoa)))),Stck);
sccollrls(V,eol) = V;
```

## `scsym`, `scspec`, `scdec` and `schx`
Function `scsym` parses an id and returns a symbol (string) or a variable. 

Function `scspec` parses a data value. Unlike C, Tram doesn't need the 32-bit version of data, so all data values are represented as strings.

Since Tram doesn't have character classes, auxiliary functions `scdec` and `schx` scan decimal and hexadecimal numbers.

```Prolog
scsym(low,C,str(B,S),CC,V,Stck) = scsym(cc(B),B,S,CC,cat(C,V),Stck);
scsym(cap,C,str(B,S),CC,V,Stck) = scsym(cc(B),B,S,CC,cat(C,V),Stck);
scsym(num,C,str(B,S),CC,V,Stck) = scsym(cc(B),B,S,CC,cat(C,V),Stck);
scsym(X,C,S,low,V,Stck) = sccc(X,C,S,reverse(V),Stck);
scsym(X,C,S,cap,V,Stck) = sccc(X,C,S,var(reverse(V)),Stck);

scspec('#',str('0',str('x',S)),Stck) = schx(S,eos,Stck);
scspec('#',str('0',S),Stck) = scdec(S,str('0',eos),Stck);
scspec('#',str('-',S),Stck) = scdec(S,str('-',eos),Stck);
scspec('#',S,Stck) = scdec(S,eos,Stck);
scspec(#0x27,str(C,str(#0x27,S)),Stck) 
 = sccc(cc(first(S)),first(S),rest(S),C,Stck);

scdec(str('0',S),V,Stck) = scdec(S,str('0',V),Stck);
scdec(str('1',S),V,Stck) = scdec(S,str('1',V),Stck);
scdec(str('2',S),V,Stck) = scdec(S,str('2',V),Stck);
scdec(str('3',S),V,Stck) = scdec(S,str('3',V),Stck);
scdec(str('4',S),V,Stck) = scdec(S,str('4',V),Stck);
scdec(str('5',S),V,Stck) = scdec(S,str('5',V),Stck);
scdec(str('6',S),V,Stck) = scdec(S,str('6',V),Stck);
scdec(str('7',S),V,Stck) = scdec(S,str('7',V),Stck);
scdec(str('8',S),V,Stck) = scdec(S,str('8',V),Stck);
scdec(str('9',S),V,Stck) = scdec(S,str('9',V),Stck);
scdec(S,V,Stck) = sccc(cc(first(S)),first(S),rest(S),reverse(V),Stck);

schx(str('a',S),V,Stck) = schx(S,str('A',V),Stck);
schx(str('b',S),V,Stck) = schx(S,str('B',V),Stck);
schx(str('c',S),V,Stck) = schx(S,str('C',V),Stck);
schx(str('d',S),V,Stck) = schx(S,str('D',V),Stck);
schx(str('e',S),V,Stck) = schx(S,str('E',V),Stck);
schx(str('f',S),V,Stck) = schx(S,str('F',V),Stck);
schx(str('A',S),V,Stck) = schx(S,str('A',V),Stck);
schx(str('B',S),V,Stck) = schx(S,str('B',V),Stck);
schx(str('C',S),V,Stck) = schx(S,str('C',V),Stck);
schx(str('D',S),V,Stck) = schx(S,str('D',V),Stck);
schx(str('E',S),V,Stck) = schx(S,str('E',V),Stck);
schx(str('F',S),V,Stck) = schx(S,str('F',V),Stck);
schx(str('0',S),V,Stck) = schx(S,str('0',V),Stck);
schx(str('1',S),V,Stck) = schx(S,str('1',V),Stck);
schx(str('2',S),V,Stck) = schx(S,str('2',V),Stck);
schx(str('3',S),V,Stck) = schx(S,str('3',V),Stck);
schx(str('4',S),V,Stck) = schx(S,str('4',V),Stck);
schx(str('5',S),V,Stck) = schx(S,str('5',V),Stck);
schx(str('6',S),V,Stck) = schx(S,str('6',V),Stck);
schx(str('7',S),V,Stck) = schx(S,str('7',V),Stck);
schx(str('8',S),V,Stck) = schx(S,str('8',V),Stck);
schx(str('9',S),V,Stck) = schx(S,str('9',V),Stck);
schx(S,V,Stck) = sccc(cc(first(S)),first(S),rest(S),reverse(V),Stck);
```




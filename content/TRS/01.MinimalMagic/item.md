---
title: "Minimal Magic"
subtitle: "Ex Principiis Omnia"
date: 2021-10-01
hero_classes: text-dark title-h1h2 overlay-light hero-large parallax
hero_image: pexels-toa-heftiba-şinca-1194420.jpg
blog_url: /trs
show_sidebar: true
show_breadcrumbs: true
show_pagination: true
categories:
  - "TRS"
tag:
  - "Magic"
  - "Minimal Magic"
---
Programming languages aim to balance performance and expressive power (among many other attributes) in the context of a consistent, intuitive programming model. Although these aims are no different for Tram, the focus differs from general programming languages:

* Performance:  
Tram is intended to test specifications and make prototypes. As such, practical performance is required, but if great speed is important, Tram may not be the ideal platform. 
* Expressive Power:  
As this text illustrates, term rewriting systems are both austere and expressive: the underlying framework offers few features, but the language is highly extendable. While most languages support extension through class and function definition, term rewriting systems force one to think through the most appropriate control and data structure for a given problem. This trait is shared with other functional and logic languages. Worth mentioning are **Lisp macros**, which allow the definition of situation-specific language constructs, thereby turning Lisp into a **domain-specific language**;
* Programming model:  
Tram's programming model is part of its strength: terms and their equality may take some getting used to, but after that, there is no room for unclarity!

There is an apparent contradiction between high expressive power and the simplicity of the programming model. Expressive power requires the existence of powerful primitives, but the more primitives, or the more those primitives require deep understanding, the more complex the model becomes.

For instance, the Python documentation (version 3.9.1) introduces the list data type as follows:

> **Lists**  
> Lists are mutable sequences, typically used to store collections of homogeneous items (where the precise degree of similarity will vary by application).

This description leans on a significant amount of tacit knowledge or at least knowledge that is explained elsewhere. For instance, 'sequences' are a built-in type that is defined in terms of an API that uses concepts of the underlying implementation language (macros, pointers).

Seemingly, to fully understand Python lists, one needs to dive deep into the implementation and into other languages. In fact, this is not the case. Most programmers are highly effective using a much less refined mental model and only turn to the nitty details of the specs when they observe unexpected behavior.

This has been the situation for almost all programming languages, and it is the way of the world.

By choice, in Tram, the strength and simplicity outweigh other concerns, which is formulated in the adage: 'minimal magic'.

# Magic
'*Magic*' refers to built-in concepts that do not follow from the underlying theoretical framework, and '**minimal magic**' refers to the desire to minimize the level of concepts thus introduced.

Tram is [based on set theory](https://www.minimalmagic.blog/trs/termrewriting/) and therefore has the concepts of symbols, variables, terms, rules, and rewrite systems. One might say this mental structure is part of our minimal magic. Common prerequisites of programming languages such as data types, operations, data structures, control structures, modularity, etcetera are absent.

Unfortunately, one further bit of magic is inescapable, and in light of the above, it is fitting to characterize why.

## The Black Box
Imagine a black box that implements a term rewriting system. In order to be of any practical or theoretical use, a user must have the ability to '*introduce*' a term in the unit and '*extract*' the normal form after it has been normalized. In addition, assuming the unit has finite memory, status information must be exchanged, such as '*out of memory*', when that situation occurs.

How could this introduction/extraction take place?

As we have seen, symbols are really sets of sets, and relations (functions, terms) are also sets of sets. How is a term outside the black box to be related to a set of sets (which may be represented as a number or not) in the black box? Without going into implementational details, one might state that a map and mechanism must exist between the external representation of terms and their internal representation. 

It is reasonable to postulate that this necessitates one to identify at least two constants and a structuring element because:

* Information theory considers sequences of bits (0 and 1). This means that at least two constant and one structuring mechanism is defined;
* The Turing complete minimalistic language **Iota** considers sequences of two symbols: `i` and `*`, leading to the same conclusion;
* The Turing complete language **Jot**, closely related to Iota, considers possibly empty sequences of 0 and 1, again leading to the same conclusion.

Note that in all cases, two constants suffice and one structuring element. A structuring element is at least one function symbol (in the case of a binary operator).

Iota and Jot are full-fledged albeit minimal languages. It would be conceivable to compile term rewriting systems to Iota or Jot programs, and if minimalism were the only concern, it would be a very interesting approach. Clearly, just compiling to Iota or Jot isn't the whole story. One would then also have to implement that language, and one would still have to develop reversible mappings between symbols (identifiers) and Iota/Jot expressions. 

Exchanging bits of information is another conceivable approach. One could imagine (for instance) data structures and control information encoded in bit patterns.

In any event, the interface between the term rewriting black box and its outside user must be unambiguous (and is considered magic because it doesn't follow from the theoretical term rewriting framework).

# Minimal Magic
In the previous section, we have seen that the interface of the term rewriting black box should (at least) identify three symbols: two to *carry meaning* and one to *structure* the other two. But since most term rewriting systems define more than three symbols, it follows that aggregates must be used to identify symbols. 

A naive approach suggests numbering all symbols in the term rewriting system and using those numbers (encoded in aggregates of the meaning-carrying constants) in the interface. 

But there's a snag: the term rewriting system might not include all symbols that subject terms might contain. Consider, for example, a compiler implemented in a term rewriting system and assume variables in the subject language occur as symbols in terms representing programs. For instance, the statement `x=x+1` (in this imaginary language) might be represented as  `let(x, plus(x,1))` (note that `x` is a variable in the language but obviously not in the term rewriting system). This observation is true for **every variable in the subject language**. But a compiler does not '*know*' all possible variables. The term rewriting system must be able to process terms containing symbols that are unknown beforehand. The only way to proceed is the ability to encode *all possible symbols*.

## Interfaces
Using only three symbols may seem minimal, but if aggregates are 
then used to encode infinitely many further symbols that 'three symbol' minimalism becomes less meaningful. Not only the number of interface symbols should be considered, but also the encoding of other symbols. We will refer to these as **explicit** and **implicit** interface definitions. The explicit interface is the set of symbols used; the implicit interface is the set of symbols that is encoded in the explicit interface.

Tram  uses the following **explicit interface** definition:

* The implementation defines 128 or 256 constants coinciding with the 7-bit ASCII characters or 8-bit bytes
* Implicitly, the sequence-operation strings characters or bytes together

Fewer symbols could be used. An alternative might have been to define only constants 0 and 1 and expect the implementation to process binary data. But (as discussed), that doesn't substantially 'minimize magic'; the choice to be able to process ASCII or binary files is practical and still minimal.

The **implicit interface** uses numbers to encode symbols and variables. The encoding differs per version of TRAM. TRAM.1, for instance, reversibly converts human-readable identifiers to 32-bit ints.
As long as all occurrences of a symbol consistently use the same number to encode it, the semantics are sound. 

# Summary
To summarize, 

* Tram is based on term rewriting, which is based on naive sets
* Tram uses an explicit interface of sequences of 7- or 8-bit data
* Each TRAM version uses an appropriate encoding as its implicit interface
 




---
title: "Conclusions"
date: 2022-03-01
draft: false
weight: 9999
categories:
  - "TRS"
tags:
  - "Conclusion"
---
# Conclusions
MinimalMagic.blog/trs was created with several purposes in mind:

* As an informal though complete and entirely self-contained introduction to term rewriting systems.
* As an illustration of the principle of *minimal magic*: develop complex systems out of (trivial) first principles
* As documentation for Tram: the *Term Rewriting Abstract Machine*
* As a guide to writing term rewriting systems from scratch or given a C implementation, and to writing a C implementation given a term rewriting system

Chapter 5 offers such an introduction, which (informally) sketches set theory and defines the theory of term rewriting systems based thereon. Chapter 6 defines the meta-notation of terms, which is the key to compilers and higher-order transformation (in Tram's first-order theory). But Chapter 6 also (formally) defines the right-most innermost term rewriting, finalizing a correct and complete characterization of term rewriting.

Part II chapters 7-11, offer documentation for Tram, and in particular for the implementation TRAM.1, by explaining key algorithms and annotating key components.

Part III, chapters 12-14 illustrate the programming process by discussing how to create term rewriting systems given a C implementation of an algorithm, and the reverse: creating a C implementation given an abstract term rewriting specification. Also, a few design patterns specific to term rewriting are discussed.

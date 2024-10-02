---
title: "Transistors & Gates"
date: 2021-08-28T12:00:47+02:00
draft: false
weight: 20
categories:
  - "SE"
tags:
  - "SE"
  - "Gates"
---
# Semiconductors

{{<figure `Transistors` `/images/SE/SE1.transistors.png` right 40 >}}

A semiconductor is a material which conducts electricity, but not too well. Worse than conductors such as most metals, but much better than insulators such as most plastics.

There are two types of semiconductor:

* N-type, which has an abundance of loosely coupled electrons
* P-type, which has an abundance of 'holes' where electrons could bind

The P-type substrate prevents current from flowing from the source (left) to the drain (right). When voltage is applied to the gate, the positive charge in the dielectric layer induces a field in the P-type substrate which allows electrons to flow to the drain.

{{<figure `Transistor Symbol` `/images/SE/SE1.transistor.png` right 20 >}}

Visit [Veritasium's explanation of transistors on YouTube](https://www.youtube.com/embed/IcrBqCFLHIY).

Simply put: no voltage on the gate means no voltage on the drain, whatever the voltage on the source; and a voltage on the gate means that the drain has a voltage precisely when the source has one. Simpler still: the gate determines if the drain copies the source or is zero.

{{<figure `MOSFET` `/images/SE/SE1.MOSFET.png` right 40 >}}

There are many types of transistors based on these same principles. BJT-type transistors amplify current and are used in audio amplifiers. MOSFET-type transistors operate on voltage with very little current and are more suitable in computer switching. We have shown enhancement-mode N-channel MOSFETS, which is CMOS technology as used in current computers.

In this blog we are interested in (logical) system engineering rather than electronic engineering, so we use simplified a design.

# Digital Computers

{{<figure `AND-Gate` `/images/SE/SE1.AND-gate.png` right 40 >}}

As mentioned, in a digital computer the presence or absence of voltage (rather than the precise voltage) can be interpreted as binary data. A line with a (near) zero voltage represents 0; a line with a higher voltage represents 1. So, anything between 0 and, say, 0.8 volt is interpreted as 0, and anything from 2 to 5 volts as 1. Circuitry is designed such that voltages in the area between are avoided (and would lead to ambiguous results). Also, designers chose whether positive or negative voltages are used to represent non-zero values. Often -5v represents 1.

Based on this, transistors can be used to compute values. For instance, two (TTL-type) transistors in series compute the Boolean **AND** function: electricity can only flow if both transistors allow it.

# Gates
A Logic **Gate** is a component consisting of a few transistors (with supporting elements such as diodes or resistors) computing some Boolean function.  
Logic gates exist for all primitive Boolean operators, but

* depending upon the specific technology, one gate needs more transistors than another, and
* as we will learn, all Boolean operators can be computed using others. For instance, the NAND can compute *all other Boolean operators*

Because of this, different types of technology (TTL, NMOS, CMOS) favor specific gates which use  less space or time.

<span style="font-size:smaller;">*Note: confusingly, the part in a transistor that controls flow is called a **gate** and a component made of a few transistors is also called a **gate**.*</span>

{{<figure `Different Gates` `/images/SE/SE1-gates.png` right 40 >}}

&osol;  
Gates form the unit of design for digital electronics (although larger modules and modularization techniques exist).  For example, visit [https://hackaday.io/project/9795-nedonand-homebrew-computer](https://hackaday.io/project/9795-nedonand-homebrew-computer) for a project in which an 8-bit processor is created out of 74F00-chips, each containing two NAND-gates.

Exercise:

* Create an inverter (that is a NOT operator) using only NAND gates.
* Create an OR gate using only NAND gates

{{<figure `Inverter + OR using AND` `/images/SE/SE1.usingNAND.png` right 40 >}}




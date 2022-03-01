---
title: "System Engineering - Introduction"
date: 2021-08-26T10:21:06+02:00
draft: false
weight: 10
categories:
  - "SE"
tags:
  - "SE"
  - "Gates"
  - "Numbers"
  - "Components"
---
A current phone has more sensors (15+) and substantially more computing power (8+ 64-bit cores)  than NASA had  in the 60s to land on the moon.
It can video a year of your life, non-stop, easily. It weighs about 150 grams.

How is that possible? It is a cutting edge of System Engineering.

# Engineering
Engineering is about 

* finding solutions to problems and
* making use of opportunities

&odot;**Example**  
A candle-snuffer is a small pair of scissors with a tiny box attached, used to cut a candle's wick before it starts producing black smoke due to bad combustion. *Most are antique because modern candles don't need them.*

One thread in a modern wick is pulled taut when the candle is made, resulting in the wick curling when it is released from the wax. The curling wick sticks out of the flame, where it burns entirely, preventing it from becoming too long and resulting in incomplete combustion of wax. Pulling one wire taut is an engineering solution.  

&odot;**Example**  
An inventor created 'bad glue' which did not work well on paper, and not at all on other materials. For six years, it was considered useless. *Today PostIt is a multi-billion product and is used around the world!*.

&odot;**Example**  
Analog computers use voltage to represent values.
But voltages can change based upon temperature, humidity, earth magnetism.
Imagine that your salary depends on the weather.
Engineers solved this problem by *understanding that precise voltages change, but the absence or presence of voltage within bounds does not*.  

Today a phone has > 1.000.000.000 transistors switching (determining the presence or absence of voltage) > 1.000.000.000 times per second.

# Layers
In order to understand systems with thousands of millions of parts, humans need to apply structure. Just as the TCP/IP stack is used to understand computer networks, another layered model is used to understand systems. 

Whereas the TCP/IP stack is (part of) an international (ISO) standard, the 6-level structured computer organization is not. **Why not?**

&rArr;  
Participants in a network must agree on a standard before they can communicate; an individual system could be structured in many different ways. Standardization only follows after commoditization in parts and services.

Nevertheless, most autonomous digital systems can be viewed in this layered model.

* Problem Oriented Language Level  
Most programs and languages we use day to day exist at this level. Programs such as browsers, word processors, editors, etcetera, and languages such as Java, JavaScript, HTML and SQL exist solely at this level.
* Assembly Language Level  
Languages such as Java are called 'high' because they deal with abstract concepts suitable for humans to work on. Other languages deal with simpler concepts (e.g. numbers) more suitable for processing directly by hardware.
* Operating System Machine Level  
The primary role of an OS is to manage all resources. The OS has drivers (specialized software to manage specific hardware), and it has many algorithms (programs) to allow processes access to these resources.
* Instruction Set Architecture Level  
How is it possible that the same software (such as a web browser) runs on different hardware (e.g. i3, i5, i9, AMD)? The hardware simulates one particular processor, which is called an Instruction Set Architecture (ISA).
* Microarchitecture Level  
It follows that a level must exist below ISA. This is called the microarchitecture.
* Digital Logic Level  
The lowest level consists of: transistors and other primitive electronic parts. Transistors are used to build larger components. For instance, two transistors are used to create one AND-gate: a component which computes the Boolean function AND. Hence the name **Digital Logic**.







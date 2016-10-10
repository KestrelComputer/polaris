# Programming Model

![Programming model](prg-model.svg)

## General Purpose Registers

X0 is hardwired to the value of zero,
allowing a simplification of the processor instruction set.
X1 through X31 may be used for any purpose,
either holding data
or referring to other data as a pointer.

The processor does not support a hardware-managed stack.
Typically,
one of the general purpose registers
is reserved for this purpose and the stack itself emulated in software.
It is beyond the scope of this text to indicate the preferred register for this task;
consult an appropriate Application Binary Interface specification for more details.

## Core Specific Registers

Eighteen CSRs contain status or configuration information for the processor.
Most of the contents of the CSRs are read-only,
as the KCP53000 does not offer the complete runtime environment of a multi-mode RISC-V processor.

Notice that the KCP53000 only offers machine mode;
thus, only M-mode CSRs are supported.

Each CSR will be described in detail in a later section of this data sheet.

## Program Counter

The program counter points to the instruction to be fetched next.
Although all 32-bits of the program counter are implemented,
it should always be loaded so that bits 0 and 1 are clear
(e.g., it always refers to an aligned 32-bit word in memory).
If this is not the case,
it is up to an external I-port bus bridge to determine the semantics.
Typically, this is an error condition,
and will raise a fault.
However, it's possible an external bridge can support unaligned memory accesses
and allow instructions to appear on non-aligned boundaries.


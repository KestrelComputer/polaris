# Features

* Flat 16 EiB instruction address space.
* Flat 16 EiB data address space.
* Supports Von Neumann or Harvard architecture configurations.[^1]
* 8, 16, 32, and 64-bit signed and unsigned memory accessors.
* 64-bit internal architecture.
* Most instructions complete within 4 clock cycles.
* Conforms to RISC-V User-Level ISA Specification v2.1.
* Conforms to RISC-V Draft Privilege ISA Specification v1.9.
* Machine-mode only design for minimum learning curve.
* Supports RV64IS instruction sets.
* 25MHz clock supports between 4 and 6 MIPS throughput, depending on instruction mix.

# Introduction

The KCP53000 core is
a RISC-V instruction set compatible
processor.
It is designed for easy integration
into most projects which require
a relatively powerful processor,
but which cannot justify the complexity
often found with such processors, such as
caches,
complex interconnects or buses,
deep interconnect or bus hierarchies requiring bridges,
large numbers of processor-specific configuration registers or settings,
etc.
The KCP53000 is ideal for projects
where you often long for the simplicity
of an 8-bit microprocessor,
but you want the expressive simplicity
that wider data paths can afford.

# Applications

* Deep-embedded microprocessor for application-specific control functions.
* CPU for neo-retro home computer or game console design.
* CPU upgrade or replacement for Z-80, 6502, 6809, 68000/68010, or similar platforms.[^1],[^2]

[^1]: With suitable bus bridge circuitry to the target bus.
[^2]: With suitable replacement of the legacy firmware to support RISC-V instruction sets.


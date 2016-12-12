Polaris used to be the name of a simple, 64-bit RISC-V ISA CPU.
However, before I could actually complete the project,
I discovered that AMD had a line of GPUs by that name.

So, I've decided to rename the Polaris CPU to the KCP53000.
In so doing, I've also decided that there ought to be a family of useful modules built to work with this CPU.
Just as one considers the "m68K" a complete *family* of products built around the Motorola 68000 (and later, CPU32) ISA,
so too should people regard the KCP53000 as the first member of a *family* of cores.

The following cores exist so far in this repository:

|ID|Description|Datasheet?|
|:-:|:--|:-:|
|KCP53000|64-bit processor built on the RISC-V 64-bit integer instruction set.|Yes|
|KCP53001|64-bit Furcula interconnect arbiter.|Not yet (note 1)|
|KCP53002|64-bit Wishbone interconnect bridge.|Not yet (note 1)|

**Notes**

1. A prototype of these cores are documented in the [Example Application](docs/example.md) chapter of the KCP53000's datasheet.


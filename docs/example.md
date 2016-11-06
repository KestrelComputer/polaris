# Example Application

This chapter includes a functioning Verilog example
of a working (simulated!) computer using the KCP53000 processor core.
The purpose of this example is not to illustrate
a complete design;
rather, it aims to show one method you can use to integrate the KCP53000 into your own designs.

By the end of this chapter,
you will have a computer:

* with a bank of ROM 256 bytes in size, arranged as 64 words by 32 bits,
* with a memory bridge that supports byte, half-word, word, and double-word transfers, and,
* with a custom I/O register implemented as a custom CSR.

This computer is aware that it's running inside a Verilog simulation,
and thus provides a means to terminate the simulation via its custom I/O register.

## Requirements

The computer needs to provide the following output facilities.
We arbitrarily decide on CSR address 255 ($0FF) for the output register.

### OUTPUT CSR ($0FF)

|63:nn|11   |10:3|2   |1   |0   |
|:---:|:-:  |:--:|:-: |:-: |:-: |
|  0  |START|CHAR|STOP|EXIT|FAIL|

#### Displaying Text

Software can write characters to the Verilog console
by sending 8-bit characters in `CHAR`.
To do this, `START` *must* be 1, and `STOP` *must* be 0.
For example, to display the letter A to the console:

    addi t0, x0, $141           ; ASCII code for A, with start bit prefixed
    slli t0, t0, 3              ; Shift into position
    csrrw x0, t0, output        ; Send/display the character.
    
Our example computer is aware it's running in Verilog, and so
we don't bother implementing a proper UART.
However, for completeness, we will emulate an instantaneous baud rate,
so that *reads* from the `OUTPUT` CSR will report a fully transmitted byte:
`START` and `CHAR` will read as 0, while
`STOP` is 1.

#### Terminating the Simulation

When the program completes, we would like the simulation to finish with a success or failure indication.
This facilitates using this logic in automated testing environments, such as [Travis CI](https://travis-ci.org/).

Software can accomplish this by setting the `EXIT` bit in `OUTPUT`.
Note that this *terminates* the simulation completely;
*no* instructions thereafter will execute.

The `FAIL` bit makes sense only when exiting.
If set, it means that some test has failed, and Verilog will produce a failure message.
This message can be sought using "grep" and, if found, cause a CI/CD pipeline to fail.
If clear, no such output is generated, and thus a successful outcome is assumed.

    csrrwi x0, 3, output        ; Something went wrong; fail immediately.
    csrrwi x0, 2, output        ; Everything went swimmingly; success!

Note that writing the `OUTPUT` register this way sets `START` to 0;
thus, no spurious nul-character will be produced.

To minimize example complexity,
both `EXIT` and `FAIL` will read back as 0.

### Sample Software

We need a demonstration program to run on this computer, to illustrate that it works.
We'll use the traditional "Hello world" program.
It's requirements are trivial:
print a greeting, then terminate simulation with a successful result.

                    adv     $F00, 0         ; Move to $...F00 in image.

    _start:         jal     1, main         ; Call our main program, setting
                                            ; X1 to point at our string.
                    byte    "Hello world!",13,10,0
                    align   4
    main:           jal     2, writeStr     ; Write the string the console.
                    csrrwi  0, 2, $0FF      ; End the simulation successfully.

    writeStr:       lb      3, 0(1)         ; Get next byte to transmit
                    beq     3, 0, done      ; If we're done, return.
                    ori     3, 0, $100      ; Set start bit.
                    slli    3, 3, 3         ; Send it via OUTPUT.
                    csrrw   0, 3, $0FF
                    addi    1, 1, 1         ; Advance to the next byte.
                    jal     0, writeStr     ; Repeat as often as necessary.
    done:           jalr    0, 0(2)

                    adv     $1000, 0        ; Fill unused remainder of image with 0s.


To assemble the software and convert it to a hex-dump file suitable for use in Verilog,
we use `xxd` to produce a listing of 32-bit words, and `awk` to extract those words and
perform the little-endian byte-swap we need for Verilog to load memory correctly:

    a from example.asm to example.bin
    xxd -g 4 -c 4 example.bin | \
    awk -e '{print substr($2,7,2)substr($2,5,2)substr($2,3,2)substr($2,1,2);}' >example.hex

The result is a file, example.hex, which contains a hex dump of the 4KB ROM image.

**NOTE.** Some versions of `xxd` support a `-e` option to perform endian conversion.
If yours supports this flag, you can replace that `substr`-mishmash above with a
simple reference `$2`, like so:

    a from example.asm to example.bin
    xxd -e -g 4 -c 4 example.bin | awk -e '{print $2;}' >example.hex

### Modeling the ROM

Once we have our example program, we need to place it in memory.
So, we create a Verilog file named "rom.v" to hold our ROM model.

    `timescale 1ns / 1ps

    module rom_module(
        input   [11:2]  A,  // Address
        output  [31:0]  Q,  // Data output
        input   STB     // True if ROM is being accessed.
    );
        reg [31:0] contents[0:1023];
        reg [31:0] results;

        assign Q = STB ? results : 0;
        always @(*) begin
            results <= contents[A];
        end

        initial begin
            $readmemh("example.hex", contents);
        end
    endmodule

### Modeling the OUTPUT CSR

The following model implements the desired Verilog-related behavior while the program is running.

    `timescale 1ns / 1ps

    module output_csr(
            input   [11:0]  cadr_i,
            output          cvalid_o,
            output  [63:0]  cdat_o,
            input   [63:0]  cdat_i,
            input           coe_i,
            input           cwe_i,

            input           clk_i
    );
            // Decode our CSR address, and report back to the CPU
            // whether or not we're selected.  This *MUST* happen
            // during the *first* clock cycle of any CSR-instruction.
            // For this reason, we make sure to do this asynchronously.
            wire csrv_output = (cadr_i == 12'h0FF);
            assign cvalid_o = csrv_output;

            // When reading, all bits are 0 except for STOP bit.
            // Note that we must do this regardless of the state of
            // the coe_i input.  coe_i *only* controls whether or not
            // read-triggered side-effects happen.
            wire [63:0] csrd_output = {64'h0000_0000_0000_0004};
            assign cdat_o = (csrv_output ? csrd_output : 0);

            // Discover whether or not write-effects are to happen.
            wire write = csrv_output & cwe_i;

            // Assuming they are, let's discover the inputs to the
            // register so we can act upon them.
            //
            // Historically, these signals are suffixed with _mux
            // because they are intended to be multiplexors into
            // stateful registers.  Since we don't have state,
            // it's a bit redundant in this example.
            wire startBit_mux = write ? cdat_i[11] : 1'b0;
            wire charByte_mux = write ? cdat_i[10:3] : 8'b0000_0000;
            wire stopBit_mux = write ? cdat_i[2] : 1'b0;
            wire exitBit_mux = write ? cdat_i[1] : 1'b0;
            wire failBit_mux = write ? cdat_i[0] : 1'b0;

            // IF you had state, you'd maintain it like so:
            //
            // always @(posedge clk_i) begin
            //      startBit <= startBit_mux;
            //      charByte <= charByte_mux;
            //      stopBit <= stopBit_mux;
            //      exitBit <= exitBit_mux;
            //      failBit <= failBit_mux;
            // end

            // Recognize, and act upon, the desired write effects
            // when they happen.
            always @(posedge clk_i) begin
                    if((startBit_mux === 1) && (stopBit_mux === 0)) begin
                            $display("%c", charByte_mux);
                    end

                    if(exitBit_mux === 1) begin
                            if(failBit_mux === 1) begin
                                    $display("@ FAIL");
                            end
                            $stop;
                    end
            end
    endmodule

### Address Decode Logic

All computers need some flavor of address decoding.

    `timescale 1ns / 1ps

    module address_decode(
        // Processor-side control
        input   iadr_i,
        input   istb_i,
        output  iack_o,

        // ROM-side control
        output  STB_o
    );

        // For our example, we're just going to decode address bit A12.
        // If it's high, then we assume we're accessing ROM.
        // The ROM is asynchronous, so we just tie iack_o directly to the
        // the strobe pin.
        assign STB_o = iadr_i & istb_i;
        assign iack_o = STB_o;

        // We don't have any RAM resources to access, but if we did,
        // we would decode them here as well.
    endmodule

### The Computer Top-Level

The computer module wraps everything together into a single circuit.

    `timescale 1ns / 1ps

    module computer();
            reg clk, reset;

            wire iack;
            wire [63:0] iadr;
            wire istb;
            wire [11:0] cadr;
            wire coe, cwe;
            wire cvalid;
            wire [63:0] cdato, cdati;
            wire STB;
            wire [31:0] romQ;

            always begin
                    #20 clk <= ~clk;
            end

            initial begin
                    clk <= 0;
                    reset <= 1;
                    wait(clk); wait(~clk);
                    wait(clk); wait(~clk);
                    wait(clk); wait(~clk);
                    reset <= 0;
            end

            PolarisCPU cpu(
                    .irq_i(1'b0),
                    .iack_i(iack),
                    .idat_i(romQ),
                    .iadr_o(iadr),
                    .istb_o(istb),
                    .dack_i(1'b1),
                    .ddat_i(64'hFFFF_FFFF_FFFF_FFFF),
                    .cadr_o(cadr),
                    .coe_o(coe),
                    .cwe_o(cwe),
                    .cvalid_i(cvalid),
                    .cdat_o(cdato),
                    .cdat_i(cdati),
                    .clk_i(clk),
                    .reset_i(reset)
            );

            rom_module rom(
                    .A(iadr[11:2]),
                    .Q(romQ),
                    .STB(STB)
            );

            address_decode ad(
                    .iadr_i(iadr[12]),
                    .istb_i(istb),
                    .iack_o(iack),
                    .STB_o(STB)
            );

            output_csr outcsr(
                    .cadr_i(cadr),
                    .cvalid_o(cvalid),
                    .cdat_o(cdati),
                    .cdat_i(cdato),
                    .coe_i(coe),
                    .cwe_i(cwe),
                    .clk_i(clk)
            );
    endmodule

### Simulating the Computer

To simulate the computer,
I use Icarus Verilog to compile everything:

    iverilog computer.v address_decode.v output.v rom.v \
             ../../rtl/verilog/polaris.v ../../rtl/verilog/xrs.v \
             ../../rtl/verilog/seq.v ../../rtl/verilog/alu.v
    vvp -n a.out

You should see the computer print `Hello world!` to the console,
and then the simulation should quit back to shell prompt.


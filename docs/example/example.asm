		adv	$F00, $CC

		jal	1, main		; Call our main program, setting
					; X1 to point at our string.
		byte	"Hello world!",13,10,0
		align	4
main:		jal	2, writeStr	; Write the string the console.
		csrrwi	0, 2, $0FF	; End the simulation successfully.

writeStr:	lb	3, 0(1)		; Get next byte to transmit
		beq	3, 0, done	; If we're done, return.
		ori	3, 3, $100	; Set start bit.
		slli	3, 3, 2		; Send it via OUTPUT.
		csrrw	0, 3, $0FF
		addi	1, 1, 1		; Advance to the next byte.
		jal	0, writeStr	; Repeat as often as necessary.
done:		jalr	0, 0(2)

		adv	$1000, 0

* Test output using OUTSTR (NetBSD method)
	ORG	$401000

* 167-Bug TRAP #15 function codes
OUTSTR	EQU	$0021
INCHR	EQU	$0000

START:
	* Set stack
	MOVE.L	#$600000,SP

	* Output "HELLO\r\n" using OUTSTR
	* Arguments: start pointer, end pointer (on stack)
	PEA	MSG_END		* Push end pointer
	PEA	MSG		* Push start pointer
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP		* Clean up stack

	* Done - infinite loop
DONE:
	BRA.S	DONE

MSG:
	DC.B	'H','E','L','L','O'
	DC.B	13,10
MSG_END:

	END	START

* Test INSTAT and INCHR
	ORG	$401000

* 167-Bug TRAP #15 function codes
OUTSTR	EQU	$0021
INSTAT	EQU	$0001
INCHR	EQU	$0000

START:
	* Set stack
	MOVE.L	#$600000,SP

	* Output prompt
	PEA	PROMPT_END
	PEA	PROMPT
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* Poll for input using INSTAT
WAIT_CHAR:
	CLR.L	-(SP)		* Push dummy argument
	TRAP	#15
	DC.W	INSTAT		* Check if char ready
	ADDQ.L	#4,SP

	* Test Z flag (should be clear when char ready)
	BEQ.S	WAIT_CHAR	* Z=1 means no char, keep waiting

	* Character ready! Get it with INCHR
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INCHR
	ADDQ.L	#4,SP

	* Output success message
	PEA	GOT_END
	PEA	GOT
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* Done
DONE:
	BRA.S	DONE

PROMPT:
	DC.B	'Type a character: '
PROMPT_END:

GOT:
	DC.B	'Got it!',13,10
GOT_END:

	END	START

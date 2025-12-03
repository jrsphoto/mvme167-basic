* Test that mimics BASIC's exact input flow
* But output a DOT like test_multi_input4 which works
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

INPUT_LOOP:
	* Call INSTAT
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INSTAT
	ADDQ.L	#4,SP

	* If Z=1, no character - loop back
	BEQ.S	INPUT_LOOP

	* Character ready - call INCHR
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INCHR
	ADDQ.L	#4,SP

	* Output a DOT (like test_multi_input4)
	PEA	DOT_END
	PEA	DOT
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* Extract character from high byte using LSR
	LSR.L	#8,D0
	LSR.L	#8,D0
	LSR.L	#8,D0

	* Check if CR
	CMP.B	#13,D0
	BEQ.S	GOT_CR

	* Not CR - loop back
	BRA.S	INPUT_LOOP

GOT_CR:
	* Output success
	PEA	SUCCESS_END
	PEA	SUCCESS
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

DONE:
	BRA.S	DONE

PROMPT:
	DC.B	'Type something: '
PROMPT_END:

DOT:
	DC.B	'.'
DOT_END:

SUCCESS:
	DC.B	13,10,'Success!',13,10
SUCCESS_END:

	END	START

* Test that mimics BASIC's exact input flow
* Check INSTAT/INCHR, then output, then loop
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

	* Extract character from high byte FIRST
	LSR.L	#8,D0
	LSR.L	#8,D0
	LSR.L	#8,D0

	* Check if CR
	CMP.B	#13,D0
	BEQ.S	GOT_CR

	* Not CR - echo it back using OUTSTR
	* Save character and A0
	MOVE.L	A0,-(SP)

	* Create buffer on stack with the extracted character
	MOVE.B	D0,-(SP)
	MOVE.L	SP,A0
	PEA	1(SP)
	PEA	(A0)
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP
	ADDQ.L	#2,SP

	* Restore and loop
	MOVE.L	(SP)+,A0
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

SUCCESS:
	DC.B	13,10,'Success!',13,10
SUCCESS_END:

	END	START

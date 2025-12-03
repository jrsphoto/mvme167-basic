* Test: Extract to D1, OUTSTR immediately, then move to D0
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

	* Extract character to D1 (leave D0 untouched for now)
	MOVE.L	D0,D1
	LSR.L	#8,D1
	LSR.L	#8,D1
	LSR.L	#8,D1

	* Check if CR
	CMP.B	#13,D1
	BEQ.S	GOT_CR

	* CRITICAL: Call OUTSTR with extracted character in D1
	* Save D0 (still has original INCHR result)
	MOVE.L	D0,-(SP)
	MOVE.L	A0,-(SP)

	* Create buffer on stack with extracted character from D1
	MOVE.B	D1,-(SP)
	MOVE.L	SP,A0
	PEA	1(SP)
	PEA	(A0)
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP
	ADDQ.L	#2,SP

	* Restore
	MOVE.L	(SP)+,A0
	MOVE.L	(SP)+,D0

	* Loop back
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

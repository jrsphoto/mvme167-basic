* Test if INCHR consumes the character
* Try to read the same character twice
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

	* Wait for first character
WAIT1:
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INSTAT
	ADDQ.L	#4,SP
	BEQ.S	WAIT1

	* Get first character with INCHR
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INCHR
	ADDQ.L	#4,SP

	* Output "Got first char"
	PEA	MSG1_END
	PEA	MSG1
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* NOW CHECK: Is character still available?
	* If INCHR consumed it, INSTAT should say no char ready
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INSTAT
	ADDQ.L	#4,SP

	* If Z=1 (no char), INCHR consumed it correctly
	BEQ.S	CONSUMED

	* If Z=0 (char ready), INCHR did NOT consume it!
	PEA	NOTCONSUMED_END
	PEA	NOTCONSUMED
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP
	BRA.S	DONE

CONSUMED:
	* INCHR consumed the character correctly
	PEA	CONSUMED_MSG_END
	PEA	CONSUMED_MSG
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

DONE:
	BRA.S	DONE

PROMPT:
	DC.B	'Press a key: '
PROMPT_END:

MSG1:
	DC.B	'Got first char',13,10
MSG1_END:

NOTCONSUMED:
	DC.B	'ERROR: INCHR did NOT consume character!',13,10
NOTCONSUMED_END:

CONSUMED_MSG:
	DC.B	'OK: INCHR consumed character',13,10
CONSUMED_MSG_END:

	END	START

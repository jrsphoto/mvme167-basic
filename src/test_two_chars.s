* Test getting exactly TWO characters
* This will tell us if the loop can work at all
	ORG	$401000

* 167-Bug TRAP #15 function codes
OUTSTR	EQU	$0021
INSTAT	EQU	$0001
INCHR	EQU	$0000

START:
	* Set stack
	MOVE.L	#$600000,SP

	* Output prompt for first char
	PEA	PROMPT1_END
	PEA	PROMPT1
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

	* Get first character
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INCHR
	ADDQ.L	#4,SP

	* Output "Got first"
	PEA	GOT1_END
	PEA	GOT1
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* NOW try to get second character
	* Output prompt for second char
	PEA	PROMPT2_END
	PEA	PROMPT2
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* Wait for second character
WAIT2:
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INSTAT
	ADDQ.L	#4,SP
	BEQ.S	WAIT2

	* Get second character
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INCHR
	ADDQ.L	#4,SP

	* Output "Got second"
	PEA	GOT2_END
	PEA	GOT2
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* Success!
	PEA	SUCCESS_END
	PEA	SUCCESS
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

DONE:
	BRA.S	DONE

PROMPT1:
	DC.B	'Press first key: '
PROMPT1_END:

GOT1:
	DC.B	'Got it!',13,10
GOT1_END:

PROMPT2:
	DC.B	'Press second key: '
PROMPT2_END:

GOT2:
	DC.B	'Got it!',13,10
GOT2_END:

SUCCESS:
	DC.B	'SUCCESS: Got two characters!',13,10
SUCCESS_END:

	END	START

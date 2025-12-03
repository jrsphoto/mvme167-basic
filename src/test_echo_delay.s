* Test echo program with delay between polls
* Polls for input and echoes characters back
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

	* Main loop - poll for input and echo
MAIN_LOOP:
	* Add a small delay between polls
	MOVE.W	#1000,D7
DELAY:
	SUBQ.W	#1,D7
	BNE.S	DELAY

	* Check if character ready using INSTAT
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INSTAT
	ADDQ.L	#4,SP

	* Z=1 means no char, keep looping
	BEQ.S	MAIN_LOOP

	* Character ready! Get it with INCHR
	CLR.L	-(SP)
	TRAP	#15
	DC.W	INCHR
	ADDQ.L	#4,SP

	* Character is in high byte of D0
	LSR.L	#8,D0
	LSR.L	#8,D0
	LSR.L	#8,D0

	* Check if it's CR (end of line)
	CMP.B	#13,D0
	BEQ.S	GOT_CR

	* Not CR - echo the character back
	MOVE.B	D0,-(SP)
	CLR.B	-(SP)
	MOVE.L	SP,A0
	ADDQ.L	#1,A0
	LEA	1(A0),A1
	MOVE.L	A1,-(SP)
	MOVE.L	A0,-(SP)
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP
	ADDQ.L	#2,SP

	* Loop for next character
	BRA.S	MAIN_LOOP

GOT_CR:
	* Got CR - output CRLF and success message
	PEA	CRLF_END
	PEA	CRLF
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	PEA	SUCCESS_END
	PEA	SUCCESS
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* Done
DONE:
	BRA.S	DONE

PROMPT:
	DC.B	'Type something and press ENTER:',13,10
PROMPT_END:

CRLF:
	DC.B	13,10
CRLF_END:

SUCCESS:
	DC.B	'OK! Input/Output working!',13,10
SUCCESS_END:

	END	START

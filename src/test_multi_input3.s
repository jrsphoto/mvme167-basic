* Test getting multiple characters with dummy OUTSTR after each char
* This should "reset" 167-Bug state between INCHR and next INSTAT
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

	* Initialize character counter
	MOVEQ	#0,D6

	* Main loop - poll for input and count
MAIN_LOOP:
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

	* CRITICAL: Call OUTSTR with empty string to reset 167-Bug state
	* This allows next INSTAT to work properly
	PEA	EMPTY_END
	PEA	EMPTY_END	* Start=End means empty string
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* Character is in high byte of D0
	LSR.L	#8,D0
	LSR.L	#8,D0
	LSR.L	#8,D0

	* Increment counter
	ADDQ.L	#1,D6

	* Check if it's CR (end of line)
	CMP.B	#13,D0
	BEQ.S	GOT_CR

	* Not CR - loop for next character
	BRA.S	MAIN_LOOP

GOT_CR:
	* Got CR - output success message
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

EMPTY_END:
	* Empty string for dummy OUTSTR call

SUCCESS:
	DC.B	13,10,'Got your input!',13,10
SUCCESS_END:

	END	START

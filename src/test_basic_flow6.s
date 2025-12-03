* Test: OUTSTR immediately after INCHR using static buffer
* Update buffer AFTER OUTSTR for next iteration
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

	* IMMEDIATELY call OUTSTR (echo previous character from buffer)
	PEA	CHARBUF_END
	PEA	CHARBUF
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* NOW extract current character
	LSR.L	#8,D0
	LSR.L	#8,D0
	LSR.L	#8,D0

	* Check if CR
	CMP.B	#13,D0
	BEQ.S	GOT_CR

	* Update buffer for next iteration
	LEA	CHARBUF,A0
	MOVE.B	D0,(A0)

	* Loop back
	BRA.S	INPUT_LOOP

GOT_CR:
	* Output final character (CR)
	LEA	CHARBUF,A0
	MOVE.B	D0,(A0)
	PEA	CHARBUF_END
	PEA	CHARBUF
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

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

CHARBUF:
	DC.B	' '		* Start with space so first char echoes as space
CHARBUF_END:

SUCCESS:
	DC.B	13,10,'Success!',13,10
SUCCESS_END:

	END	START

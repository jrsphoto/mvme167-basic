* Test using OUTCHR instead of OUTSTR
* Based on Denis's code snippet from forum
	ORG	$401000

* 167-Bug TRAP #15 function codes
OUTSTR	EQU	$0021
OUTCHR	EQU	$0020	* Single character output!
INSTAT	EQU	$0001
INCHR	EQU	$0000

START:
	* Initialize stack
	MOVE.L	#$600000,SP

	* Output prompt using OUTSTR
	PEA	PROMPT_END
	PEA	PROMPT
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

INPUT_LOOP:
	* Check if character ready
	TRAP	#15
	DC.W	INSTAT
	BEQ.S	INPUT_LOOP	* Loop if no character

	* Get character (Denis's method: reserve stack space)
	SUBQ.L	#2,SP		* Reserve 2 bytes on stack
	TRAP	#15
	DC.W	INCHR
	MOVE.B	(SP)+,D0	* Pop character to D0

	* Check if CR
	CMP.B	#13,D0
	BEQ.S	GOT_CR

	* Echo character using OUTCHR
	MOVE.B	D0,-(SP)	* Push character
	TRAP	#15
	DC.W	OUTCHR		* Output single character
	ADDQ.L	#2,SP		* Clean up stack

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

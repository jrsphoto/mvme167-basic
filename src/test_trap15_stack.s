* Test TRAP #15 stack preservation with register-based calling
	ORG	$401000

* 167-Bug TRAP #15 function codes
OUTCHR	EQU	$0020

START:
	* Set stack
	MOVE.L	#$600000,SP

	* Output test message
	LEA	MSG,A0
LOOP:
	MOVE.B	(A0)+,D1
	BEQ.S	DONE

	* Call TRAP #15 with function in D0, char in D1
	MOVE.W	#OUTCHR,D0
	TRAP	#15

	BRA.S	LOOP

DONE:
	* Success - infinite loop
	BRA.S	DONE

MSG:
	DC.B	'Hello from register mode!',13,10,0
	EVEN

	END	START

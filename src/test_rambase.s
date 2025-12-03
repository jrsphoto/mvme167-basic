* Test writing to ram_base at $500000
	ORG	$401000

START:
	* Set stack
	MOVE.L	#$600000,SP

	* Try to write to $500000
	MOVE.L	#$500000,A0
	MOVE.L	#$12345678,D0
	MOVE.L	D0,(A0)

	* Try to read it back
	MOVE.L	(A0),D1

	* Output "OK" if it worked
	MOVEQ	#'O',D0
	MOVEQ	#6,D7
	TRAP	#15

	MOVEQ	#'K',D0
	MOVEQ	#6,D7
	TRAP	#15

	* Infinite loop
DONE:
	BRA.S	DONE

	END	START

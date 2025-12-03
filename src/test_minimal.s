* Minimal test - just set registers and loop
	ORG	$401000

START:
	* Set some registers to known values
	MOVE.L	#$11111111,D0
	MOVE.L	#$22222222,D1
	MOVE.L	#$33333333,D2
	MOVE.L	#$600000,SP

	* Infinite loop
LOOP:
	NOP
	NOP
	NOP
	BRA.S	LOOP

	END	START

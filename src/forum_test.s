* MVME167 Input Echo Test - Demonstrates 167-Bug TRAP #15 Issue
*
* COMPILE:
*   vasmm68k_mot -m68040 -Felf -quiet -o forum_test.o forum_test.s
*   m68k-elf-objcopy -O srec --change-section-address seg401000=0x401000 \
*     forum_test.o forum_test.srec
*
* LOAD TO 167-Bug:
*   167-Bug> lo 0
*   [paste contents of forum_test.srec]
*   167-Bug> go 401000
*
* EXPECTED BEHAVIOR:
*   Program should display "Type something: " prompt, then echo each
*   character you type. Press ENTER to display "Success!" and exit.
*
* ACTUAL BEHAVIOR:
*   Displays prompt, but does not accept keyboard input (hangs at prompt).
*   Single-character test (test_input.s) works fine, but multi-character
*   input loop fails.
*
* BACKGROUND:
*   - test_input.s (single char): WORKS - waits for one keypress, outputs "Got it!"
*   - This program (multi char loop): FAILS - won't accept any input
*   - The ONLY working multi-char approach outputs a CONSTANT string (like ".")
*     after each INCHR, but echoing the ACTUAL typed character fails
*
* 167-Bug TRAP #15 Functions Used:
*   OUTSTR ($0021) - Output string (start ptr, end ptr on stack)
*   INSTAT ($0001) - Check input status (Z=1 no char, Z=0 char ready)
*   INCHR  ($0000) - Input character (returns in D0 bits 24-31)

	ORG	$401000

* 167-Bug TRAP #15 function codes
OUTSTR	EQU	$0021
INSTAT	EQU	$0001
INCHR	EQU	$0000

START:
	* Initialize stack
	MOVE.L	#$600000,SP

	* Output prompt
	PEA	PROMPT_END
	PEA	PROMPT
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

INPUT_LOOP:
	* Check if character is ready using INSTAT
	CLR.L	-(SP)		* Push dummy argument
	TRAP	#15
	DC.W	INSTAT		* Check if char ready
	ADDQ.L	#4,SP		* Clean up stack

	* If Z=1, no character available - keep polling
	BEQ.S	INPUT_LOOP

	* Character is ready - get it with INCHR
	CLR.L	-(SP)		* Push dummy argument
	TRAP	#15
	DC.W	INCHR		* Get character
	ADDQ.L	#4,SP		* Clean up stack

	* Extract character from high byte (bits 24-31) to low byte
	LSR.L	#8,D0
	LSR.L	#8,D0
	LSR.L	#8,D0

	* Check if it's CR (carriage return)
	CMP.B	#13,D0
	BEQ.S	GOT_CR

	* Not CR - echo the character back to screen
	* Save A0 register
	MOVE.L	A0,-(SP)

	* Create 1-byte buffer on stack with character
	MOVE.B	D0,-(SP)	* Push character as buffer
	MOVE.L	SP,A0		* A0 = start pointer
	PEA	1(SP)		* Push end pointer (start+1)
	PEA	(A0)		* Push start pointer
	TRAP	#15
	DC.W	OUTSTR		* Output the character
	ADDQ.L	#8,SP		* Clean up OUTSTR arguments
	ADDQ.L	#2,SP		* Clean up character buffer

	* Restore A0 and loop for next character
	MOVE.L	(SP)+,A0
	BRA.S	INPUT_LOOP

GOT_CR:
	* Got CR - output newline and success message
	PEA	SUCCESS_END
	PEA	SUCCESS
	TRAP	#15
	DC.W	OUTSTR
	ADDQ.L	#8,SP

	* Infinite loop (done)
DONE:
	BRA.S	DONE

* Data section
PROMPT:
	DC.B	'Type something: '
PROMPT_END:

SUCCESS:
	DC.B	13,10,'Success!',13,10
SUCCESS_END:

	END	START

* CD2401 Serial Output Test Program for MVME167
* Tests various output methods to find what works
*
* Load at 0x400400, entry point at start

	ORG	$00400400

* CD2401 Register definitions from Linux serial167 driver
CD2401_BASE EQU $FFF45000
CyGFRCR     EQU $81        * Global Firmware Revision Code Register
CyCCR       EQU $13        * Channel Command Register
CyCAR       EQU $EE        * Channel Access Register
CyIER       EQU $11        * Interrupt Enable Register
CyTISR      EQU $8A        * Transmit Interrupt Status Register
CyTDR       EQU $F8        * Transmit Data Register
CyRDR       EQU $F8        * Receive Data Register
CySCHR4     EQU $1C        * Special Character Register 4
CySTCR      EQU $0C        * Special Transmit Command Register

START:
	* Set up stack
	MOVE.L	#$00420000,SP

	* Test 1: Print banner using Special Character method
	LEA	MSG_HELLO(PC),A1
	BSR	PRINT_STRING

	* Infinite loop
HANG:
	BRA.S	HANG

* ============================================================================
* PRINT_STRING - Print null-terminated string
* Input: A1 = pointer to string
* ============================================================================
PRINT_STRING:
	MOVEM.L	D0/A1,-(SP)
.LOOP:
	MOVE.B	(A1)+,D0	* Get character
	BEQ.S	.DONE		* Stop at null
	BSR	PUTCHAR		* Output it
	BRA.S	.LOOP
.DONE:
	MOVEM.L	(SP)+,D0/A1
	RTS

* ============================================================================
* PUTCHAR - Output single character using Special Character method
* Input: D0.B = character to output
* ============================================================================
PUTCHAR:
	MOVEM.L	D1/A0,-(SP)
	LEA	CD2401_BASE,A0

	* Select channel 0
	MOVE.B	#0,(CyCAR,A0)

	* Write character to Special Character Register 4
	MOVE.B	D0,(CySCHR4,A0)

	* Send Special Character 4 command (0x98)
	MOVE.B	#$98,(CySTCR,A0)

.WAIT:
	* Wait for command to complete (STCR clears to 0)
	TST.B	(CySTCR,A0)
	BNE.S	.WAIT

	MOVEM.L	(SP)+,D1/A0
	RTS

* ============================================================================
* Test Messages
* ============================================================================
MSG_HELLO:
	DC.B	'Hello World from CD2401!',13,10,0

	EVEN

* ============================================================================
* Alternative test using TDR directly
* ============================================================================
PUTCHAR_TDR:
	MOVEM.L	A0,-(SP)
	LEA	CD2401_BASE,A0

	* Select channel 0
	MOVE.B	#0,(CyCAR,A0)

	* Write directly to TDR
	MOVE.B	D0,(CyTDR,A0)

	* Small delay
	MOVE.W	#$1000,D1
.DELAY:
	SUBQ.W	#1,D1
	BNE.S	.DELAY

	MOVEM.L	(SP)+,A0
	RTS

END

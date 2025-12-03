*----------------------------------------------------------------------
* ANSI_CLS - Clear Screen and Home Cursor
* Sequence: ESC [ 2 J  then  ESC [ H
*----------------------------------------------------------------------
ANSI_CLS
    LEA     STR_CLS,A0
    BRA.S   PRINT_STR

*----------------------------------------------------------------------
* ANSI_LOCATE - Move Cursor to Row/Col
* Input: D1 = Column (X) (0-based in BASIC, converted to 1-based for ANSI)
* D0 = Row (Y)    (0-based in BASIC, converted to 1-based for ANSI)
* Sequence: ESC [ <Row> ; <Col> H
*----------------------------------------------------------------------
ANSI_LOCATE
    MOVEM.L D0-D2/A0,-(SP)  * Save regs
    
    MOVE.L  D0,D2           * Save Row for later
    
    * 1. Print "ESC ["
    MOVEQ   #27,D0          * ESC
    BSR     VEC_OUT
    MOVEQ   #'[',D0
    BSR     VEC_OUT

    * 2. Print ROW (Y) + 1
    MOVE.L  D2,D0           * Restore Row
    ADDQ.L  #1,D0           * ANSI is 1-based
    BSR.S   PRT_DEC         * Print number

    * 3. Print ";"
    MOVEQ   #';',D0
    BSR     VEC_OUT

    * 4. Print COL (X) + 1
    MOVE.L  D1,D0           * Get Col
    ADDQ.L  #1,D0           * ANSI is 1-based
    BSR.S   PRT_DEC         * Print number

    * 5. Print "H" (Command terminator)
    MOVEQ   #'H',D0
    BSR     VEC_OUT

    MOVEM.L (SP)+,D0-D2/A0
    RTS

*----------------------------------------------------------------------
* PRT_DEC - Print value in D0 as ASCII Decimal
* Trashes: D0
*----------------------------------------------------------------------
PRT_DEC
    MOVEM.L D1-D2/A0,-(SP)  * Save work regs
    
    * Handle special case 0
    TST.B   D0
    BNE.S   .NOT_ZERO
    MOVEQ   #'0',D0
    BSR     VEC_OUT
    BRA.S   .DONE

.NOT_ZERO
    LEA     DEC_BUF,A0      * Buffer to store digits
    ADDQ.L  #4,A0           * Point to end
    CLR.B   -(A0)           * Null terminate
    
    ANDI.L  #$FF,D0         * Ensure byte only
.LOOP
    DIVU    #10,D0          * Divide by 10
    SWAP    D0              * Get remainder (digit) in lower word
    ADDI.B  #'0',D0         * Convert to ASCII
    MOVE.B  D0,-(A0)        * Store digit
    CLR.W   D0              * Clear remainder
    SWAP    D0              * Get quotient back
    TST.W   D0              * Zero?
    BNE.S   .LOOP

    * Now print the string
    BSR.S   PRINT_STR
.DONE
    MOVEM.L (SP)+,D1-D2/A0
    RTS

*----------------------------------------------------------------------
* PRINT_STR - Print null-terminated string at (A0)
*----------------------------------------------------------------------
PRINT_STR
    MOVEM.L D0/A0,-(SP)
.P_LOOP
    MOVE.B  (A0)+,D0
    BEQ.S   .P_EXIT
    BSR     VEC_OUT
    BRA.S   .P_LOOP
.P_EXIT
    MOVEM.L (SP)+,D0/A0
    RTS

* Data strings for ANSI
STR_CLS:    DC.B    27,'[2J',27,'[H',0
            EVEN
DEC_BUF:    DS.B    6       * Buffer for number conversion
            EVEN
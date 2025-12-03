* Test fresh keypress detection
* Drains FIFO first, then waits for NEW keypress

* PCC2 Registers
PCC2CHIP    EQU $FFF42000
PCCSCCTICR  EQU PCC2CHIP+$1E
PCCTPIACKR  EQU PCC2CHIP+$25

* CD2401 Registers
CD2401_BASE EQU $FFF45000
CyCAR       EQU $EE
CyCCR       EQU $13
CyIER       EQU $11
CyRFOC      EQU $30
CyRDR       EQU $F8
CyTDR       EQU $F8
CyLICR      EQU $26
CyTEOIR     EQU $85

* Commands
CyENB_XMTR  EQU $08
CyENB_RCVR  EQU $02
CyTxMpty    EQU $02
CyNOTRANS   EQU $08

        ORG    $400400

START:
        MOVE.L  #$420000,SP

        * Initialize CD2401 (includes FIFO drain)
        BSR     INIT_CD2401

        * Show we're ready
        LEA     READY_MSG(PC),A2
        BSR     PRINT_STRING

        * Now wait for FRESH keypress
        MOVE.L  #$10000000,D7   * Very long timeout
.POLL_LOOP:
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)

        * Check RFOC
        MOVE.B  (CyRFOC,A0),D1
        BNE.S   .GOT_DATA

        SUBQ.L  #1,D7
        BNE.S   .POLL_LOOP

        * Timeout
        LEA     TIMEOUT_MSG(PC),A2
        BSR     PRINT_STRING
        BRA.S   .EXIT

.GOT_DATA:
        * Show we got data
        LEA     GOT_MSG(PC),A2
        BSR     PRINT_STRING

        * Show RFOC value
        MOVE.B  D1,D0
        BSR     PRINT_HEX_BYTE

        MOVEQ   #' ',D0
        BSR     PUTCHAR

        * Read and show character
        MOVE.B  (CyRDR,A0),D0
        BSR     PRINT_HEX_BYTE

        MOVEQ   #' ',D0
        BSR     PUTCHAR

        * Echo if printable
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
        MOVE.B  (CyRDR,A0),D0  * Re-read for echo (this will be wrong, just for test)
        CMPI.B  #$20,D0
        BLT.S   .DONE
        CMPI.B  #$7E,D0
        BGT.S   .DONE
        BSR     PUTCHAR

.DONE:
        LEA     CRLF(PC),A2
        BSR     PRINT_STRING

.EXIT:
        TRAP    #14

* Initialize CD2401 and drain FIFO
INIT_CD2401:
        MOVEM.L D0-D1/A0,-(SP)
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
.WAIT1:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT1
        MOVE.B  #CyENB_XMTR+CyENB_RCVR,(CyCCR,A0)
.WAIT2:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT2

        * Drain FIFO
        MOVEQ   #20,D1
.DRAIN:
        TST.B   (CyRFOC,A0)
        BEQ.S   .DRAINED
        MOVE.B  (CyRDR,A0),D0
        SUBQ.B  #1,D1
        BNE.S   .DRAIN

.DRAINED:
        * Clear transmit pending
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .NO_TX
        MOVE.B  PCCTPIACKR.L,D1
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)
.NO_TX:
        MOVEM.L (SP)+,D0-D1/A0
        RTS

* Print string pointed to by A2
PRINT_STRING:
        MOVEM.L D0/A2,-(SP)
.LOOP:
        MOVE.B  (A2)+,D0
        BEQ.S   .DONE
        BSR     PUTCHAR
        BRA.S   .LOOP
.DONE:
        MOVEM.L (SP)+,D0/A2
        RTS

* Print D0.B as hex
PRINT_HEX_BYTE:
        MOVEM.L D0-D2,-(SP)
        MOVE.B  D0,D2
        LSR.B   #4,D0
        BSR.S   .PRINT_NIB
        MOVE.B  D2,D0
        BSR.S   .PRINT_NIB
        MOVEM.L (SP)+,D0-D2
        RTS
.PRINT_NIB:
        ANDI.B  #$0F,D0
        CMPI.B  #9,D0
        BLS.S   .DIGIT
        ADDI.B  #'A'-10,D0
        BRA.S   PUTCHAR
.DIGIT:
        ADDI.B  #'0',D0
        BRA.S   PUTCHAR

* Output character (working method)
PUTCHAR:
        MOVEM.L D0-D2/A0,-(SP)
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
        MOVE.B  (CyIER,A0),D2
        MOVE.B  #CyTxMpty,(CyIER,A0)
.WAIT_INT:
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .WAIT_INT
        MOVE.B  PCCTPIACKR.L,D1
        MOVE.B  (CyLICR,A0),D1
        LSR.B   #2,D1
        BNE.S   .NOT_OURS
        MOVE.B  D0,(CyTDR,A0)
        CLR.B   (CyTEOIR,A0)
        BRA.S   .RESTORE
.NOT_OURS:
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)
        BRA.S   .WAIT_INT
.RESTORE:
        MOVE.B  D2,(CyIER,A0)
        MOVEM.L (SP)+,D0-D2/A0
        RTS

READY_MSG:    DC.B    'FIFO drained. Press a key...',13,10,0
GOT_MSG:      DC.B    'Got key! RFOC=',0
TIMEOUT_MSG:  DC.B    'TIMEOUT - no fresh keypress detected',13,10,0
CRLF:         DC.B    13,10,0
              EVEN

        END

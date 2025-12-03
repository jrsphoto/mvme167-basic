* Test to verify IER is cleared and input works
* Shows IER value before/after and tests input

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

        * Show IER before init
        LEA     MSG_BEFORE(PC),A2
        BSR     PRINT_STR
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
        MOVE.B  (CyIER,A0),D0
        BSR     PRINT_HEX

        * Init (disables IER)
        BSR     INIT_CD2401

        * Show IER after init
        LEA     MSG_AFTER(PC),A2
        BSR     PRINT_STR
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
        MOVE.B  (CyIER,A0),D0
        BSR     PRINT_HEX

        * Prompt
        LEA     MSG_PROMPT(PC),A2
        BSR     PRINT_STR

        * Simple poll loop
        MOVEQ   #5,D7
.LOOP:
        BSR     VEC_IN
        BCC.S   .LOOP
        BSR     VEC_OUT
        SUBQ.B  #1,D7
        BNE.S   .LOOP

        LEA     MSG_DONE(PC),A2
        BSR     PRINT_STR

        TRAP    #14

INIT_CD2401:
        MOVEM.L D0-D1/A0,-(SP)
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
        CLR.B   (CyIER,A0)      * Disable interrupts!
.WAIT1:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT1
        MOVE.B  #CyENB_XMTR+CyENB_RCVR,(CyCCR,A0)
.WAIT2:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT2
        MOVEQ   #20,D1
.DRAIN:
        TST.B   (CyRFOC,A0)
        BEQ.S   .DONE
        MOVE.B  (CyRDR,A0),D0
        SUBQ.B  #1,D1
        BNE.S   .DRAIN
.DONE:
        MOVEM.L (SP)+,D0-D1/A0
        RTS

VEC_OUT:
        MOVEM.L D0-D2/A0,-(SP)
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
        MOVE.B  #CyTxMpty,(CyIER,A0)
.WAIT:
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .WAIT
        MOVE.B  PCCTPIACKR.L,D1
        MOVE.B  (CyLICR,A0),D1
        LSR.B   #2,D1
        BNE.S   .NOT_OURS
        MOVE.B  D0,(CyTDR,A0)
        CLR.B   (CyTEOIR,A0)
        BRA.S   .RESTORE
.NOT_OURS:
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)
        BRA.S   .WAIT
.RESTORE:
        CLR.B   (CyIER,A0)      * Disable again
        MOVEM.L (SP)+,D0-D2/A0
        RTS

VEC_IN:
        MOVEM.L D1/A0,-(SP)
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
        MOVE.B  (CyRFOC,A0),D1
        BEQ.S   .NO_DATA
        MOVE.B  (CyRDR,A0),D0
        ORI.B   #1,CCR
        MOVEM.L (SP)+,D1/A0
        RTS
.NO_DATA:
        MOVEQ   #0,D0
        ANDI.B  #$FE,CCR
        MOVEM.L (SP)+,D1/A0
        RTS

PRINT_STR:
        MOVEM.L D0/A2,-(SP)
.L:     MOVE.B  (A2)+,D0
        BEQ.S   .D
        BSR     VEC_OUT
        BRA.S   .L
.D:     MOVEM.L (SP)+,D0/A2
        RTS

PRINT_HEX:
        MOVEM.L D0-D2,-(SP)
        MOVE.B  D0,D2
        LSR.B   #4,D0
        BSR.S   .NIB
        MOVE.B  D2,D0
        BSR.S   .NIB
        MOVEQ   #13,D0
        BSR     VEC_OUT
        MOVEQ   #10,D0
        BSR     VEC_OUT
        MOVEM.L (SP)+,D0-D2
        RTS
.NIB:   ANDI.B  #$0F,D0
        CMPI.B  #9,D0
        BLS.S   .DIG
        ADDI.B  #'A'-10,D0
        BSR     VEC_OUT
        RTS
.DIG:   ADDI.B  #'0',D0
        BSR     VEC_OUT
        RTS

MSG_BEFORE: DC.B 'IER before: ',0
MSG_AFTER:  DC.B 'IER after: ',0
MSG_PROMPT: DC.B 'Type 5 chars: ',0
MSG_DONE:   DC.B 13,10,'Done!',13,10,0
            EVEN
        END

* Test echo using exact VEC_IN and VEC_OUT from BASIC
* This mimics what BASIC does

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

        * Initialize exactly like BASIC does
        BSR     INIT_CD2401

        * Print prompt using VEC_OUT
        LEA     PROMPT(PC),A2
.PROMPT_LOOP:
        MOVE.B  (A2)+,D0
        BEQ.S   .PROMPT_DONE
        BSR     VEC_OUT
        BRA.S   .PROMPT_LOOP

.PROMPT_DONE:
        * Echo loop - exactly like BASIC input loop
        MOVEQ   #10,D7          * Echo 10 characters then exit
.ECHO_LOOP:
        BSR     VEC_IN
        BCC.S   .ECHO_LOOP      * Loop if no data (carry clear)

        * Got character - echo it
        BSR     VEC_OUT

        * Check if done
        SUBQ.B  #1,D7
        BNE.S   .ECHO_LOOP

        * Print done message
        LEA     DONE_MSG(PC),A2
.DONE_LOOP:
        MOVE.B  (A2)+,D0
        BEQ.S   .EXIT
        BSR     VEC_OUT
        BRA.S   .DONE_LOOP

.EXIT:
        TRAP    #14

*----------------------------------------------------------------------
* INIT_CD2401 - Exact copy from BASIC
*----------------------------------------------------------------------
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
.DRAIN_LOOP:
        TST.B   (CyRFOC,A0)
        BEQ.S   .FIFO_EMPTY
        MOVE.B  (CyRDR,A0),D0
        SUBQ.B  #1,D1
        BNE.S   .DRAIN_LOOP

.FIFO_EMPTY:
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .NO_TX_PENDING

        MOVE.B  PCCTPIACKR.L,D1
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)

.NO_TX_PENDING:
        MOVEM.L (SP)+,D0-D1/A0
        RTS

*----------------------------------------------------------------------
* VEC_OUT - Exact copy from BASIC
*----------------------------------------------------------------------
VEC_OUT:
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

*----------------------------------------------------------------------
* VEC_IN - Exact copy from BASIC
*----------------------------------------------------------------------
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

PROMPT:   DC.B    'Echo test - type 10 chars: ',0
DONE_MSG: DC.B    13,10,'Done!',13,10,0
          EVEN

        END

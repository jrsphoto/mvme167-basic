* Test INIT_CD2401 then send "Hello"
* This will verify the init routine doesn't hang

* PCC2 Registers
PCC2CHIP    EQU $FFF42000
PCCSCCTICR  EQU PCC2CHIP+$1E
PCCTPIACKR  EQU PCC2CHIP+$25

* CD2401 Registers
CD2401_BASE EQU $FFF45000
CyCAR       EQU $EE
CyCCR       EQU $13
CyIER       EQU $11
CyLICR      EQU $26
CyTDR       EQU $F8
CyTEOIR     EQU $85

* Commands
CyENB_XMTR  EQU $08
CyTxMpty    EQU $02
CyNOTRANS   EQU $08

        ORG    $400400

START:
        MOVE.L  #$420000,SP

        * Call init routine
        BSR     INIT_CD2401

        * Send message
        LEA     MESSAGE(PC),A2
LOOP:
        MOVE.B  (A2)+,D0
        BEQ.S   DONE
        BSR     PUTCHAR
        BRA.S   LOOP

DONE:
        TRAP    #14

* Initialize CD2401
INIT_CD2401:
        MOVEM.L D0-D1/A0,-(SP)
        LEA     CD2401_BASE,A0

        CLR.B   (CyCAR,A0)

.WAIT1:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT1

        MOVE.B  #CyENB_XMTR,(CyCCR,A0)

.WAIT2:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT2

        * Clear pending interrupt
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .NO_PENDING

        MOVE.B  PCCTPIACKR.L,D1
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)

.NO_PENDING:
        MOVEM.L (SP)+,D0-D1/A0
        RTS

* Output character
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

MESSAGE:
        DC.B    'Init OK!',13,10,0
        EVEN

        END

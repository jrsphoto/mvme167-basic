* Absolute minimal test - output one character and halt
* No loops, no complexity

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

        * Enable transmitter ONCE
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
.WAIT1:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT1
        MOVE.B  #CyENB_XMTR,(CyCCR,A0)
.WAIT2:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT2

        * Clear pending
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .NO_PEND
        MOVE.B  PCCTPIACKR.L,D1
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)
.NO_PEND:

        * Send ONE character
        MOVEQ   #'X',D0

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
        BRA.S   .DONE

.NOT_OURS:
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)
        BRA.S   .WAIT_INT

.DONE:
        MOVE.B  D2,(CyIER,A0)

        * HALT - return to Bug
        TRAP    #14

        END

* Check LICR to ensure it's actually our channel's interrupt
* Loop back if it's not for us

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
        MOVE.L  #$420000,SP         * Set stack properly

        * Initialize: Enable transmitter on channel 0 once
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)          * Select channel 0

        * Wait for CCR clear
.WAIT1:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT1

        * Enable transmitter
        MOVE.B  #CyENB_XMTR,(CyCCR,A0)

        * Wait for CCR to complete
.WAIT2:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT2

        * Set IER once for TxEmpty interrupts
        MOVE.B  #CyTxMpty,(CyIER,A0)

        * Now send message
        LEA     MESSAGE(PC),A2
LOOP:
        MOVE.B  (A2)+,D0
        BEQ.S   DONE
        BSR     PUTCHAR
        BRA.S   LOOP

DONE:
        TRAP    #14

* Output one character in D0
PUTCHAR:
        MOVEM.L D0-D1/A0,-(SP)
        LEA     CD2401_BASE,A0

        CLR.B   (CyCAR,A0)          * Select channel 0

        * Wait for interrupt and verify it's for us
.WAIT_INT:
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .WAIT_INT

        * Acknowledge interrupt (Read PIACK)
        MOVE.B  PCCTPIACKR.L,D1

        * Check LICR - is this interrupt for channel 0?
        MOVE.B  (CyLICR,A0),D1
        LSR.B   #2,D1               * Channel number in bits 2-4
        BNE.S   .NOT_OURS           * Not channel 0, skip

        * It's for us - write character
        MOVE.B  D0,(CyTDR,A0)

        * Signal End of Interrupt
        CLR.B   (CyTEOIR,A0)
        BRA.S   .DONE

.NOT_OURS:
        * Not our interrupt - signal NOTRANS and loop back
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)
        BRA.S   .WAIT_INT           * Try again

.DONE:
        MOVEM.L (SP)+,D0-D1/A0
        RTS

MESSAGE:
        DC.B    'Hello World!',13,10,0
        EVEN

        END

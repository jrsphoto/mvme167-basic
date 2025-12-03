* Wait for transmitter to actually finish sending before next char
* Check TISR (Transmit Interrupt Status Register) for buffer empty

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
CyTISR      EQU $8A

* Commands and bits
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
        MOVEM.L D0-D2/A0,-(SP)
        LEA     CD2401_BASE,A0

        CLR.B   (CyCAR,A0)

        * Save and set IER
        MOVE.B  (CyIER,A0),D2
        MOVE.B  #CyTxMpty,(CyIER,A0)

        * Wait for interrupt
.WAIT_INT:
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .WAIT_INT

        * Read PIACK
        MOVE.B  PCCTPIACKR.L,D1

        * Write character
        MOVE.B  D0,(CyTDR,A0)

        * Signal EOI
        CLR.B   (CyTEOIR,A0)

        * NEW: Wait for transmitter to finish sending this character
        * Poll TISR until TxMpty bit is set again
.WAIT_SENT:
        MOVE.B  (CyTISR,A0),D1
        ANDI.B  #CyTxMpty,D1        * Check TxMpty bit
        BEQ.S   .WAIT_SENT          * Loop until buffer empty

        * Restore IER
        MOVE.B  D2,(CyIER,A0)

        MOVEM.L (SP)+,D0-D2/A0
        RTS

MESSAGE:
        DC.B    'Hello World!',13,10,0
        EVEN

        END

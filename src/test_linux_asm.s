* CD2401 Serial Output using Linux kernel method (Assembly version)
* Based on arch/m68k/mvme16x/config.c

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

        LEA     MESSAGE(PC),A2       * Load message address
LOOP:
        MOVE.B  (A2)+,D0            * Get character
        BEQ.S   DONE                * Exit if null
        BSR     PUTCHAR             * Output character
        BRA.S   LOOP

DONE:
        TRAP    #14                 * Return to Bug

* Output one character in D0
PUTCHAR:
        MOVEM.L D0-D2/A0,-(SP)      * Save registers
        LEA     CD2401_BASE,A0

        * Select channel 0
        CLR.B   (CyCAR,A0)

        * Wait for CCR clear
.WAIT_CCR:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT_CCR

        * Enable transmitter
        MOVE.B  #CyENB_XMTR,(CyCCR,A0)

        * Wait for CCR to clear after command
.WAIT_CCR2:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT_CCR2

        * Save and set IER
        MOVE.B  (CyIER,A0),D2       * Save IER
        MOVE.B  #CyTxMpty,(CyIER,A0)

        * Wait for interrupt
.WAIT_INT:
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .WAIT_INT

        * Read PIACK (triggers interrupt ack)
        MOVE.B  PCCTPIACKR.L,D1

        * Check if our channel
        MOVE.B  (CyLICR,A0),D1
        LSR.B   #2,D1
        BNE.S   .NOT_OURS

        * Write character
        MOVE.B  D0,(CyTDR,A0)

        * Signal EOI
        CLR.B   (CyTEOIR,A0)
        BRA.S   .RESTORE

.NOT_OURS:
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)

.RESTORE:
        * Restore IER
        MOVE.B  D2,(CyIER,A0)

        MOVEM.L (SP)+,D0-D2/A0
        RTS

MESSAGE:
        DC.B    'Hello from Linux method!',13,10,0
        EVEN

        END

* Debug version - stores status info at 0x400300 for inspection
* This will help us see what's happening in the interrupt handler

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

* Commands
CyENB_XMTR  EQU $08
CyTxMpty    EQU $02
CyNOTRANS   EQU $08

DEBUG_AREA  EQU $400300

        ORG    $400400

START:
        MOVE.L  #$420000,SP         * Set stack properly

        * Clear debug area
        LEA     DEBUG_AREA,A3
        MOVE.L  #0,(A3)+
        MOVE.L  #0,(A3)+
        MOVE.L  #0,(A3)+
        MOVE.L  #0,(A3)+

        * Try to send just one character 'A'
        MOVE.B  #'A',D0
        BSR     PUTCHAR

DONE:
        TRAP    #14                 * Return to Bug

* Output one character in D0
PUTCHAR:
        MOVEM.L D0-D3/A0-A1,-(SP)   * Save registers
        LEA     CD2401_BASE,A0
        LEA     DEBUG_AREA,A1

        * Select channel 0
        CLR.B   (CyCAR,A0)
        MOVE.B  #$01,(A1)+          * Mark: selected channel

        * Wait for CCR clear
.WAIT_CCR:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT_CCR
        MOVE.B  #$02,(A1)+          * Mark: CCR cleared

        * Enable transmitter
        MOVE.B  #CyENB_XMTR,(CyCCR,A0)

        * Wait for CCR to clear after command
.WAIT_CCR2:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT_CCR2
        MOVE.B  #$03,(A1)+          * Mark: TX enabled

        * Save and set IER
        MOVE.B  (CyIER,A0),D2       * Save IER
        MOVE.B  D2,(A1)+            * Store old IER value
        MOVE.B  #CyTxMpty,(CyIER,A0)

        * Check TISR before waiting
        MOVE.B  (CyTISR,A0),D3
        MOVE.B  D3,(A1)+            * Store TISR value

        * Wait for interrupt (with timeout)
        MOVE.W  #1000,D3            * Timeout counter
.WAIT_INT:
        MOVE.B  PCCSCCTICR.L,D1
        MOVE.B  D1,(A1)             * Store PCC2 int status (will overwrite)
        ANDI.B  #$20,D1
        BNE.S   .GOT_INT
        DBRA    D3,.WAIT_INT

        * Timeout!
        MOVE.B  #$FF,(A1)+          * Mark: timeout
        BRA.S   .RESTORE

.GOT_INT:
        MOVE.B  #$04,(A1)+          * Mark: got interrupt

        * Read PIACK (triggers interrupt ack)
        MOVE.B  PCCTPIACKR.L,D1
        MOVE.B  D1,(A1)+            * Store PIACK value

        * Check if our channel
        MOVE.B  (CyLICR,A0),D1
        MOVE.B  D1,(A1)+            * Store LICR value
        LSR.B   #2,D1
        BNE.S   .NOT_OURS

        * Write character
        MOVE.B  #$05,(A1)+          * Mark: writing char
        MOVE.B  D0,(CyTDR,A0)

        * Signal EOI
        CLR.B   (CyTEOIR,A0)
        MOVE.B  #$06,(A1)+          * Mark: sent EOI
        BRA.S   .RESTORE

.NOT_OURS:
        MOVE.B  #$FE,(A1)+          * Mark: not our channel
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)

.RESTORE:
        * Restore IER
        MOVE.B  D2,(CyIER,A0)

        MOVEM.L (SP)+,D0-D3/A0-A1
        RTS

        END

* CD2401 Serial Output Routine for MVME167
* Working implementation using PCC2 PIACK interrupt acknowledge
*
* This routine sends one character via the CD2401 serial controller
* on channel 0 at the settings configured by 167-Bug (9600/8/N/1)
*
* Entry: D0.B = character to output
* Exit:  All registers preserved
*
* Key points:
* - Uses PCC2 PIACK (Pseudo Interrupt Acknowledge) mechanism
* - Enables TxMpty interrupt only when ready to send
* - Restores IER after sending to avoid spurious interrupts
* - Checks LICR to ensure interrupt is for our channel

* PCC2 Registers
PCC2CHIP    EQU $FFF42000
PCCSCCTICR  EQU PCC2CHIP+$1E    * SCC Transmit Interrupt Control
PCCTPIACKR  EQU PCC2CHIP+$25    * Transmit Pseudo IACK Register

* CD2401 Registers (base address = $FFF45000)
CD2401_BASE EQU $FFF45000
CyCAR       EQU $EE             * Channel Access Register
CyCCR       EQU $13             * Channel Command Register
CyIER       EQU $11             * Interrupt Enable Register
CyLICR      EQU $26             * Local Interrupting Channel Register
CyTDR       EQU $F8             * Transmit Data Register
CyTEOIR     EQU $85             * Transmit End of Interrupt Register

* Commands and bits
CyENB_XMTR  EQU $08             * Enable Transmitter command
CyTxMpty    EQU $02             * Transmit Buffer Empty interrupt bit
CyNOTRANS   EQU $08             * No Transfer (EOI without data)

*----------------------------------------------------------------------
* VEC_OUT - Output one character to CD2401 serial port
*
* Call with:
*   D0.B = character to output
*
* Returns:
*   All registers preserved
*----------------------------------------------------------------------
VEC_OUT:
        MOVEM.L D0-D2/A0,-(SP)      * Save registers
        LEA     CD2401_BASE,A0

        * Select channel 0
        CLR.B   (CyCAR,A0)

        * Save current IER and enable TxMpty interrupt
        MOVE.B  (CyIER,A0),D2
        MOVE.B  #CyTxMpty,(CyIER,A0)

.WAIT_INT:
        * Wait for transmit interrupt from PCC2
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .WAIT_INT

        * Acknowledge interrupt (triggers PIACK to CD2401)
        MOVE.B  PCCTPIACKR.L,D1

        * Check if interrupt is for channel 0
        MOVE.B  (CyLICR,A0),D1
        LSR.B   #2,D1               * Channel number in bits 2-4
        BNE.S   .NOT_OURS

        * It's for us - write character to transmit data register
        MOVE.B  D0,(CyTDR,A0)

        * Signal end of interrupt
        CLR.B   (CyTEOIR,A0)
        BRA.S   .RESTORE

.NOT_OURS:
        * Not our channel - signal NOTRANS and wait for next interrupt
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)
        BRA.S   .WAIT_INT

.RESTORE:
        * Restore original IER
        MOVE.B  D2,(CyIER,A0)

        MOVEM.L (SP)+,D0-D2/A0
        RTS

*----------------------------------------------------------------------
* INIT_CD2401 - Initialize CD2401 for output
*
* Call once at startup to enable transmitter
* Clears any pending interrupt state
*----------------------------------------------------------------------
INIT_CD2401:
        MOVEM.L D0-D1/A0,-(SP)
        LEA     CD2401_BASE,A0

        * Select channel 0
        CLR.B   (CyCAR,A0)

        * Wait for CCR to be ready
.WAIT1:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT1

        * Enable transmitter
        MOVE.B  #CyENB_XMTR,(CyCCR,A0)

        * Wait for command to complete
.WAIT2:
        TST.B   (CyCCR,A0)
        BNE.S   .WAIT2

        * Clear any pending interrupt
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .NO_PENDING

        * Acknowledge and discard
        MOVE.B  PCCTPIACKR.L,D1
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)

.NO_PENDING:
        MOVEM.L (SP)+,D0-D1/A0
        RTS

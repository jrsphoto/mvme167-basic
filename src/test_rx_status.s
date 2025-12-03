* Test receive interrupt status
* Display PCC2 receive interrupt register before and after keypress

* PCC2 Registers
PCC2CHIP    EQU $FFF42000
PCCSCCTICR  EQU PCC2CHIP+$1E
PCCSCCRICR  EQU PCC2CHIP+$1F
PCCTPIACKR  EQU PCC2CHIP+$25
PCCRPIACKR  EQU PCC2CHIP+$27

* CD2401 Registers
CD2401_BASE EQU $FFF45000
CyCAR       EQU $EE
CyCCR       EQU $13
CyIER       EQU $11
CyLICR      EQU $26
CyRFOC      EQU $30
CyRDR       EQU $F8
CyTDR       EQU $F8
CyTEOIR     EQU $85
CyREOIR     EQU $84

* Commands
CyENB_XMTR  EQU $08
CyENB_RCVR  EQU $02
CyTxMpty    EQU $02
CyRxData    EQU $08
CyNOTRANS   EQU $08

        ORG    $400400

START:
        MOVE.L  #$420000,SP

        * Initialize CD2401
        BSR     INIT_CD2401

        * Show initial status
        LEA     MSG1(PC),A2
        BSR     PRINT_STRING

        * Read and display PCCSCCRICR
        MOVE.B  PCCSCCRICR.L,D0
        BSR     PRINT_HEX_BYTE

        * Show IER value
        LEA     MSG2(PC),A2
        BSR     PRINT_STRING
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
        MOVE.B  (CyIER,A0),D0
        BSR     PRINT_HEX_BYTE

        * Show RFOC value
        LEA     MSG3(PC),A2
        BSR     PRINT_STRING
        MOVE.B  (CyRFOC,A0),D0
        BSR     PRINT_HEX_BYTE

        * Enable RxData interrupt
        LEA     MSG4(PC),A2
        BSR     PRINT_STRING
        MOVE.B  #CyRxData,(CyIER,A0)

        * Wait a bit for keypress
        LEA     MSG5(PC),A2
        BSR     PRINT_STRING

        MOVE.L  #$100000,D7
.WAIT_LOOP:
        * Check PCCSCCRICR status
        MOVE.B  PCCSCCRICR.L,D1
        ANDI.B  #$20,D1
        BNE.S   .GOT_INT

        SUBQ.L  #1,D7
        BNE.S   .WAIT_LOOP

        * Timeout
        LEA     MSG_TIMEOUT(PC),A2
        BSR     PRINT_STRING
        BRA.S   .SHOW_FINAL

.GOT_INT:
        * Got interrupt!
        LEA     MSG_INT(PC),A2
        BSR     PRINT_STRING

        * Show RFOC
        LEA     MSG3(PC),A2
        BSR     PRINT_STRING
        LEA     CD2401_BASE,A0
        CLR.B   (CyCAR,A0)
        MOVE.B  (CyRFOC,A0),D0
        BSR     PRINT_HEX_BYTE

        * Acknowledge interrupt
        MOVE.B  PCCRPIACKR.L,D1

        * Check LICR
        LEA     MSG6(PC),A2
        BSR     PRINT_STRING
        MOVE.B  (CyLICR,A0),D0
        BSR     PRINT_HEX_BYTE

        * Read character if available
        MOVE.B  (CyRFOC,A0),D1
        BEQ.S   .NO_CHAR

        MOVE.B  (CyRDR,A0),D0
        LEA     MSG7(PC),A2
        BSR     PRINT_STRING
        BSR     PRINT_HEX_BYTE

        * EOI
        CLR.B   (CyREOIR,A0)
        BRA.S   .SHOW_FINAL

.NO_CHAR:
        LEA     MSG8(PC),A2
        BSR     PRINT_STRING
        MOVE.B  #CyNOTRANS,(CyREOIR,A0)

.SHOW_FINAL:
        * Show final PCCSCCRICR
        LEA     MSG9(PC),A2
        BSR     PRINT_STRING
        MOVE.B  PCCSCCRICR.L,D0
        BSR     PRINT_HEX_BYTE

        LEA     CRLF(PC),A2
        BSR     PRINT_STRING

        TRAP    #14

* Initialize CD2401
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
        * Clear transmit pending
        MOVE.B  PCCSCCTICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .NO_TX
        MOVE.B  PCCTPIACKR.L,D1
        MOVE.B  #CyNOTRANS,(CyTEOIR,A0)
.NO_TX:
        * Clear receive pending
        MOVE.B  PCCSCCRICR.L,D1
        ANDI.B  #$20,D1
        BEQ.S   .NO_RX
        MOVE.B  PCCRPIACKR.L,D1
        MOVE.B  #CyNOTRANS,(CyREOIR,A0)
.NO_RX:
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

MSG1:       DC.B    'PCCSCCRICR: ',0
MSG2:       DC.B    ' IER: ',0
MSG3:       DC.B    ' RFOC: ',0
MSG4:       DC.B    13,10,'RxData enabled',13,10,0
MSG5:       DC.B    'Press a key...',13,10,0
MSG6:       DC.B    13,10,'LICR: ',0
MSG7:       DC.B    ' CHAR: ',0
MSG8:       DC.B    ' (no char in FIFO)',0
MSG9:       DC.B    13,10,'Final RICR: ',0
MSG_TIMEOUT: DC.B   'TIMEOUT - no interrupt',0
MSG_INT:    DC.B    'INTERRUPT!',0
CRLF:       DC.B    13,10,0
            EVEN

        END

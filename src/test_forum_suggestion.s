* Test forum suggestion for calling 167-Bug .OUTCHR
* Based on forum response but with corrected address

OUTCHAR_VECTOR EQU $FFE00AD0  ; Corrected address (was $FFE000D0)

        ORG    $400400
START:
        MOVE.L #$420000,SP    ; Set stack
        MOVE.B #'A',D0        ; Load character 'A' into D0 low byte
        BSR    OUT_CHAR_CALL  ; Call the routine
        MOVE.B #13,D0         ; CR
        BSR    OUT_CHAR_CALL
        MOVE.B #10,D0         ; LF
        BSR    OUT_CHAR_CALL

HANG:
        BRA.S  HANG           ; Hang here

OUT_CHAR_CALL:
        JSR    OUTCHAR_VECTOR ; Jump to the bug's .OUTCHR handler
        RTS                   ; Return from subroutine

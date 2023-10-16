
.set USDir, DDRB
.set USOut, PORTB
.set USIn,  PINB
.set USTrig, 1
.set USEcho, 2
.set USErr, 0

; Configure GPIO for the Ultrasonic sensor pins
; ---------------------------------------------------------
UltrasonicInit:

    sbi	    USDir, USTrig       ; set trigger output
    cbi	    USOut, USTrig       ; set trigger off (low)

    cbi	    USDir, USEcho       ; set echo input
    cbi	    USOut, USEcho	; high-impedance

    sbi	    USDir, USErr	; set error pin output
    cbi	    USOut, USErr

    ret

; Start a new measurement cycle
; @return R0 - measurement in inches
; ---------------------------------------------------------
UltrasonicCycle:
     clr  r0			; inch counter
     
    call    UltrasonicTrigger

USCycleStart:			; wait for echo pin to go high
    sbis    USIn, USEcho
    rjmp    USCycleStart	; cycles started


USCycleEcho:			; while (echo high) {
    sbis    USIn, USEcho	; if (echo low) 
    rjmp    USCycleRet		; break
				; else
    call    UltrasonicTimer	; wait 148us
    inc	    r0                  ; add 1 inch
							
    breq    USCycleErr          ; if (overflow)
				; break
    rjmp    USCycleEcho         ; } 

USCycleErr:
    sbi	    USOut, USErr	; set error LED on

USCycleRet:
    ret				; R0


; Send a 10us pulse on the trigger pin to start a new 
; timing cycle
; 10us / (1/16MHz) / 5cycles = 32
; ---------------------------------------------------------
UltrasonicTrigger:
     sbi  USOut, USTrig       ; set trigger pin high

     ldi  r16, 32             ; 32 * 5
USTriggerWait:
     nop                      ; 1 cycle
     nop                      ; 1 cycle
     dec  r16                 ; 1 cycle
     brne USTriggerWait       ; 2 cycles

     cbi  USOut, USTrig       ; clear trigger pin low

     ret     

; Measurement timer 148us/inch
; ---------------------------------------------------------
UltrasonicTimer:
     clr  r20
     sts  TCNT2, r20          ; clear counter

     ldi  r20, 36
     sts  OCR2A, r20          ; 148us @ clk/64

     ldi  r20, (1<<WGM21)
     sts  TCCR2A, r20         ; ctc mode

     ldi  r20, (1<<CS22)
     sts  TCCR2B, r20         ; clk/64

USTimerWait:
     sbis TIFR2,OCF2A         ; wait for match
     rjmp USTimerWait
     
     sbi  TIFR2,OCF2A         ; reset flag

     clr  r20
     sts  TCCR2B, r20         ; stop timer

     ret
     
     
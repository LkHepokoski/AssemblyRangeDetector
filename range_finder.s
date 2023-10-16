; range_finder.s
; class: CDA 3104, Fall 2022
; devs: Luke Hepokoski, Tayler Rae Bachmann, Jose Suarez
; desc: range finder lab program to calc distance
; ------------------------------------------------------------------------------

#define __SFR_OFFSET 0
#include <avr/io.h>

#include "vectortable.inc"
#include "Ultrasonic.inc"


setup:

          ; port setups
          ; ---------------------------------------------------------
          ; alarm setup
          sbi       DDRD, DDD1          ; set D1 to be output
          cbi       PORTD, PORTD1       ; set D1 low - alarm off
          ; button setup
          cbi       DDRD, DDD2          ; set D2 to input
          sbi       PORTD, PORTD2       ; set D2 to low
          ; green light setup
          sbi       DDRD, DDD5          ; set D5 to be output
          cbi       PORTD, PORTD5       ; set D5 low - green light off
          ; yellow light setup
          sbi       DDRD, DDD6          ; set D6 to be output
          cbi       PORTD, PORTD6       ; set D6 low - yellow light off
          ; red light setup
          sbi       DDRD, DDD7          ; set D7 to be output
          cbi       PORTD, PORTD7       ; set D7 low - red light off
          ; ultrasonic setup
          call UltrasonicInit
       

          ; constants
          ; ---------------------------------------------------------
          ; green light (r31) is 9 feet (108 inches) away
          ldi       r31, 108            
          ; yellow light (r30) is 6 feet (72 inches) away
          ldi       r30, 72
          ; red light (r29) is 3 feet (36 inches) away
          ldi       r29, 36

          ; interrupt setups
          ; ---------------------------------------------------------
          ; button interrupt setup
          sbi       EIMSK, INT0         ; enable INT0 for button interrupt
          ldi       r21, 0b00000010     ; 
          sts       EICRA, r21          ; set falling edge

          sei                           ; enable interrupts
    

; main loop that calls the range detector and evaluates the lights
; ---------------------------------------------------------
main_loop:    

          cbi       PORTD, PORTD5       ; turn off green light
          cbi       PORTD, PORTD6       ; turn off yellow light
          cbi       PORTD, PORTD7       ; turn off red light

          call UltrasonicCycle          ; start measuring (R0 = 0)

          call evaluate_lights          ; turn on needed lights / alarm

          call Delay1s                  ; wait one second before taking next 
                                        ; measurement     
                         
          rjmp      main_loop           ; return to main_loop             


; interrupt for when button is pressed
; ---------------------------------------------------------
button_isr:                             
          
          cbi       PORTD, PORTD1       ; sets D1 to low, turns off alarm
          reti                          ; end interrupt


; evaluates the distance (r0) and which lights to turn on 
; ---------------------------------------------------------
evaluate_lights:                        
          
          ; if r0 < r31 (green/108 inches) turn on green light
          cp r0, r31                    ; if r0 smaller than r31, carry flag = 1
          brsh      lights_return       ; if r0 is bigger than r31 (C = 0),
                                        ; return to main_loop
          sbi       PORTD, PORTD5       ; turn on green light

          ; if r0 < 30 (yellow/72 inches) turn on yellow light
          cp r0, r30                    ; if r0 smaller than r30, carry flag = 1
          brsh      lights_return       ; if r0 is bigger than r30 (C = 0),
                                        ; return to main_loop
          sbi       PORTD, PORTD6       ; turn on yellow light

          ; if r0 < 29 (red/36 inches)  turn on red light and alarm
          cp r0, r29                    ; if r0 smaller than r29, carry flag = 1
          brsh      lights_return        ; if r0 is bigger than r29 (C = 0),
                                        ; return to main_loop
          sbi       PORTD, PORTD7       ; turn on red light
          sbi       PORTD, PORTD1       ; turn on alarm 

lights_return:
          ret

; sleep for 1s between measurement cycles 
; ---------------------------------------------------------
Delay1s:
     clr  r23                 ; clear counter
     sts  TCNT1H, r23
     sts  TCNT1L, r23
     ldi  r23, 0x3D           ; match at 15624
     sts  OCR1AH, r23
     ldi  r23, 0x08
     sts  OCR1AL, r23
     clr  r23
     sts  TCCR1A, r23         ; ctc mode
     ldi  r23, (1<<WGM12) | (1<<CS12)
     sts  TCCR1B, r23         ; ctc, clk/256
Delay1sWait:
     sbis TIFR1, OCF1A        ; wait for flag
     rjmp Delay1sWait
     clr  r23
     sts  TCCR1B, r23         ; stop timer
     sbi  TIFR1, OCF1A        ; clear flag
     ret


; end loop
; ---------------------------------------------------------
end_main:

          rjmp      end_main


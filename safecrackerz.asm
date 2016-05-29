.include "m2560def.inc"
;http://www.avrfreaks.net/forum/tutasmcode-morons-guide-avr-adc

.equ SCREEN_TIMEOUT = 3

; global vars
.dseg
RightBtnStatus:                 ; button debouncing status
    .byte 1
LeftBtnStatus:
    .byte 1
RightBtnCounter:                ; counters for debouncing
    .byte 2
LeftBtnCounter:
    .byte 2
TimerCounter:                   ; Number of ticks from Timer 1
    .byte 2
SecondCounter:                  ; Number of Seconds that have passed
    .byte 1
CounterDirection:               ; Boolean to determine if should countup or countdown
    .byte 1
LoseState:                      ; Boolean to determine if game is lost
    .byte 1
StartedState:                   ; Boolean to determine if game has been started
    .byte 1


.cseg
.org 0
    jmp RESET
    jmp pushbutton_right        ; PB0 to INT0 (RDX4), right button
    jmp pushbutton_left         ; PB1 to INT1 (RDX3), left button
.org OVF0addr
    jmp timer0_interrupt       ; Timer interrupts
.org OVF1addr
    jmp timer1_interrupt
.org 0x0072
DEFAULT:
    reti                        ; Interrupts that aren't handled

.include "macros.asm"
.include "sleep.asm"
.include "lcd.asm"
.include "timer.asm"
.include "pushbutton.asm"
.include "interrupt.asm"
.include "pot.asm"

RESET:
    ; clear variables
    clear8 RightBtnStatus
    clear8 LeftBtnStatus
    clear16 RightBtnCounter
    clear16 LeftBtnCounter
    clear16 TimerCounter

SOFT_RESET:
    ; init stack
    ldi r16, low(RAMEND)
    out SPL, r16
    ldi r16, high(RAMEND)
    out SPH, r16

    clear8 SecondCounter
    clear8 CounterDirection
    clear8 LoseState
    clear8 StartedState
    clr r16
    clr r17



    ; TODO remove this (or make it useful?)
       ser r16
       out DDRC, r16           ; set LED bar

    ; init devices
    call lcd_init
    call pushbutton_init
    call interrupt_init
    call timer_init
    ;call pot_init


START_SCREEN:
    lcd_printstr "2121 16s1"
    lcd_set_line 1
    lcd_printstr "Safe Cracker"

    rjmp HALT       ; wait for button press

START_COUNTDOWN_SCREEN:
    load_X StartedState
    ldi r16, 1
    st X, r16

    ;inc8 StartedState   ; set game as 'Started'

    lcd_clear
    lcd_printstr "2121 16s1"
    lcd_set_line 1

    ldi r16, SCREEN_TIMEOUT
    rcall timer_reset_countdown

START_COUNTDOWN_SCREEN_loop:
    ; check countdown 
    load_val8_reg r16, SecondCounter
    cpi r16, 0
    breq RESET_POT_SCREEN

    lcd_printstr "Starting in "
    lcd_print8 r16
    lcd_printstr "..."
    lcd_set_line 1

    rjmp START_COUNTDOWN_SCREEN_loop

RESET_POT_SCREEN:
    lcd_clear
    lcd_printstr "Reset POT to 0"
    lcd_set_line_1

    ldi r16, SCREEN_TIMEOUT
    rcall timer_reset_countdown


RESET_POT_SCREEN_loop:
    ; check pot
    ;rcall pot_read

    ; check countdown 
    load_val8_reg r16, SecondCounter
    cpi r16, 0
    breq TIMEOUT_SCREEN

    lcd_printstr "Remaining : "
    lcd_print8 r16
    lcd_set_line_1

    rjmp RESET_POT_SCREEN_loop

FIND_POT_SCREEN:
    lcd_clear

TIMEOUT_SCREEN:
    lcd_clear
    lcd_printstr "Game over"
    lcd_set_line 1
    lcd_printstr "You Lose!"

    ; set LoseState to True
    inc8 LoseState

TIMEOUT_SCREEN_loop:
    rjmp TIMEOUT_SCREEN_loop
    
HALT:
    rjmp HALT


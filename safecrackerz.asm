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
TimerCounter2:                  ; Also the number of ticks from Timer 1, but reset independently
    .byte 2
RandomNum:                      ; Random num between 0 - 1024, generated from timer0 ticks
    .byte 2
FindPotNum:                     ; Desired POT setting for user to find
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

.include "avr200.asm"
.include "macros.asm"
.include "math.asm"
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
    clear16 RandomNum
    clear16 FindPotNum
    clr r16
    clr r17

    ; TODO move to function
    ser r16
    out DDRC, r16           ; set LED bar
    out DDRG, r16           ; set LED bar

    ; init devices
    call lcd_init
    call pushbutton_init
    call interrupt_init
    call timer_init
    call pot_init


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

    ; reset counter if pot is not zero
    rcall timer_reset_countup_2


RESET_POT_SCREEN_loop:
    ; check countdown 
    load_val8_reg r16, SecondCounter
    cpi r16, 0
    breq RESET_POT_SCREEN_exit

    lcd_printstr "Remaining : "
    lcd_print8 r16
    lcd_set_line_1

    ; check pot is zero
    rcall pot_read
    cpi r24, 0
    ldi r16, 0
    cpc r25, r16
    breq RESET_POT_SCREEN_wait

    ; reset counter if pot is not zero
    rcall timer_reset_countup_2

    rjmp RESET_POT_SCREEN_loop

RESET_POT_SCREEN_wait:
    load_val16_X TimerCounter2
    cpi XL, LOW(ONE_SEC_16*0.5)
    ldi r16, HIGH(ONE_SEC_16*0.5)
    cpc XH, r16
    breq FIND_POT_SCREEN

    rjmp RESET_POT_SCREEN_loop

RESET_POT_SCREEN_exit:
    jmp TIMEOUT_SCREEN

FIND_POT_SCREEN:
    lcd_clear
    lcd_printstr "Find POT Pos"
    lcd_set_line_1
    load_val16_X RandomNum
    store16_X FindPotNum
    load_val16_X FindPotNum
    jmp FIND_POT_SCREEN_loop

FIND_POT_SCREEN_exit:
    jmp TIMEOUT_SCREEN

FIND_POT_SCREEN_loop:
    ; check countdown 
    ;load_val8_reg r16, SecondCounter
    ;cpi r16, 0
    ;breq FIND_POT_SCREEN_exit

    rcall FIND_POT_SCREEN_readpot

    ;rcall FIND_POT_SCREEN_setlightbar

    lcd_set_line_1
    lcd_printstr "Remaining : "
    lcd_print8 r18       ; yl should be 0 - 63 inclusive

    rjmp FIND_POT_SCREEN_loop
    ; check if pot has gone past target
    ;cpi r16, 0
    ;brlt TEST_TEST
    ;brlt_long TEST_TEST

    ;cpi r16, 0
    ;brne FIND_POT_SCREEN_loop

    ;lcd_printstr "Remaining : "
    ;lcd_print8 r16
    ;lcd_set_line_1

    jmp FIND_CODE_SCREEN

TEST_TEST:
    lcd_clear
    lcd_printstr "rekt"
    rjmp HALT

FIND_CODE_SCREEN:
    lcd_clear
    rjmp HALT

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


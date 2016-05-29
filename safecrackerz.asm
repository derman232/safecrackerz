.include "m2560def.inc"
;http://www.avrfreaks.net/forum/tutasmcode-morons-guide-avr-adc

.equ SCREEN_TIMEOUT_START = 1
.equ SCREEN_TIMEOUT = 19

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
RandNums:                       ; 3 random numbers
    .byte 3
RoundNum:                       ; Current round
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
CharacterMap: .db "0123456789*#ABCD"

.include "avr200.asm"
.include "macros.asm"
.include "math.asm"
.include "sleep.asm"
.include "lcd.asm"
.include "timer.asm"
.include "pushbutton.asm"
.include "interrupt.asm"
.include "pot.asm"
.include "lightbar.asm"
.include "keypad.asm"

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
    clear8 RandNums
    clear8 RandNums+1
    clear8 RandNums+2
    clear8 RoundNum
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
    call keypad_init


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

    ldi r16, SCREEN_TIMEOUT_START
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
    ldi r16, SCREEN_TIMEOUT
    rcall timer_reset_countdown
RESET_POT_SCREEN_softreset:
    rcall lightbar_clear

    lcd_clear
    lcd_printstr "Reset POT to 0"
    lcd_set_line_1

    ; reset counter for if pot is not zero
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

    ; reset counter for checking whether pot is at zero for 500milli
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
    ; counter for checking whether pot is at target for 1sec
    rcall timer_reset_countup_2

    lcd_clear
    lcd_printstr "Find POT Pos"
    lcd_set_line_1
    load_val16_X RandomNum
    store16_X FindPotNum

    jmp FIND_POT_SCREEN_loop


FIND_POT_SCREEN_exit:
    jmp TIMEOUT_SCREEN

FIND_POT_SCREEN_loop:

    ; check countdown 
    load_val8_reg r19, SecondCounter
    cpi r19, 0
    breq FIND_POT_SCREEN_exit

    lcd_set_line_1
    lcd_printstr "Remaining : "
    lcd_print8 r19       ; yl should be 0 - 63 inclusive
    lcd_printstr " "     ; clear trailing character

    load_val16_X FindPotNum
    rcall FIND_POT_SCREEN_readpot

    rcall FIND_POT_SCREEN_setlightbar

    ; check if pot has gone past target
    cpi r18, 0
    brlt_long RESET_POT_SCREEN_softreset

    cpi r18, 0
    breq FIND_POT_SCREEN_wait

    ; reset counter for if pot is not on target and try again
    rcall timer_reset_countup_2
    jmp FIND_POT_SCREEN_loop


FIND_POT_SCREEN_wait:
    load_val16_X TimerCounter2
    cpi XL, LOW(ONE_SEC_16*1)
    ldi r18, HIGH(ONE_SEC_16*1)
    cpc XH, r18
    breq FIND_CODE_SCREEN

    jmp FIND_POT_SCREEN_loop

FIND_CODE_SCREEN:
    rcall lightbar_clear
    lcd_clear

    lcd_printstr "Position found!"
    lcd_set_line 1
    lcd_printstr "Scan for number"

    rjmp HALT

TEST_TEST:
    lcd_clear
    lcd_printstr "rekt"
    lcd_set_line_1
    lcd_print8 r18
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


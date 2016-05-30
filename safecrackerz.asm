.include "m2560def.inc"
;http://www.avrfreaks.net/forum/tutasmcode-morons-guide-avr-adc

.equ SCREEN_TIMEOUT_START = 1
.equ SCREEN_TIMEOUT = 19
.equ MAX_ROUNDS = 2
.equ STROBE_LIGHT = 0b00000010

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
RandomNum8:                     ; Random num between 0 - 255 inclusive, generated from timer0 ticks
    .byte 1
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
RandNums:                       ; random number for each round
    .byte 10
RoundNum:                       ; Current round
    .byte 1
KeypadCurval:
    .byte 1
KeypadUpdates:
    .byte 1
RandChar:
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
.include "pwm.asm"
.include "speaker.asm"

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

    ; init variables
    clear8 SecondCounter
    clear8 CounterDirection
    clear8 LoseState
    clear8 StartedState
    clear8 RandNums
    clear8 RandNums+1
    clear8 RandNums+2
    clear8 RoundNum
    clear8 RandomNum8
    clear16 RandomNum
    clear16 FindPotNum
    clear8 KeypadCurval
    clear8 KeypadUpdates

    ; init devices
    call lcd_init
    call lightbar_init
    call pushbutton_init
    call interrupt_init
    call timer_init
    call pot_init
    call keypad_init
    call pwm_init
    call speaker_init


START_SCREEN:
    lcd_printstr "2121 16s1"
    lcd_set_line 1
    lcd_printstr "Safe Cracker"

START_SCREEN_wait:
    ; wait until the game has been started
    load_val8_reg r16, StartedState
    cpi r16, 1
    breq START_COUNTDOWN_SCREEN

    rjmp START_SCREEN_wait

;loop_test:
;    rcall keypad_getkey
;    rcall keypad_getval
;    cpi r18, 0
;    breq_long loop_test
;    lcd_printchar_reg r18
;
;    rjmp loop_test
;
;
;    rjmp HALT       ; wait for button press

START_COUNTDOWN_SCREEN:
    ;loop:
    ;lcd_set_line 0
    ;load_16 RandomNum
    ;lcd_print16 xh, xl
    ;jmp loop

    ;load_X StartedState
    ;ldi r16, 1
    ;st X, r16

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
    breq_long TIMEOUT_SCREEN

    RESET_POT_SCREEN_loop_continue:
    lcd_printstr "Remaining : "
    lcd_print8 r16
    lcd_printstr " "
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
    brlt_long RESET_POT_SCREEN_loop

    rjmp FIND_POT_SCREEN

FIND_POT_SCREEN:
    ; counter for checking whether pot is at target for 1sec
    rcall timer_reset_countup_2

    lcd_set_line 0
    lcd_printstr "Find POT Pos  "
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
    brlt_long FIND_POT_SCREEN_loop

    jmp FIND_CODE_SCREEN

FIND_CODE_SCREEN:
    rcall timer_off
    rcall lightbar_clear
    lcd_clear

    lcd_printstr "Position found!"
    lcd_set_line 1
    lcd_printstr "Scan for number"

    rcall set_rand_char
    lcd_set_line 1

    rcall timer_reset_countup_2     ; restart the timer 

    rjmp FIND_CODE_SCREEN_loop

FIND_CODE_SCREEN_loop:
    rcall keypad_getkey
    rcall keypad_getval_motor
    cpi r18, 1
    breq_long FIND_CODE_SCREEN_end

    rjmp FIND_CODE_SCREEN_loop

FIND_CODE_SCREEN_end:
    inc8 RoundNum           ; increment the round number
    lds r16, RoundNum
    cpi r16, MAX_ROUNDS
    brge ENTER_CODE_SCREEN
    jmp RESET_POT_SCREEN

ENTER_CODE_SCREEN:
    clear8 KeypadCurval
    clear8 KeypadUpdates
    rcall keypad_getkey
    rcall keypad_getval

ENTER_CODE_SCREEN_reset:
    lcd_clear
    lcd_printstr "Enter Code"
    lcd_set_line_1
    clr r20

ENTER_CODE_SCREEN_loop:
    ; retrieve random number for round number in r20
    mov r16, r20
    load_Z RandNums
    add zl, r16
    clr r16
    adc zh, r16
    ld r17, Z

    rcall keypad_getkey
    rcall keypad_getval
    cp r18, r17
    breq ENTER_CODE_SCREEN_correct

    cpi r18, 0
    breq ENTER_CODE_SCREEN_loop

    ; incorrect digit entered
    ; start code screen again
    rjmp ENTER_CODE_SCREEN_reset

ENTER_CODE_SCREEN_correct:
    inc r20
    lcd_printstr "*"

    cpi r20, MAX_ROUNDS
    brge GAME_COMPLETE_SCREEN
    jmp ENTER_CODE_SCREEN_loop

GAME_COMPLETE_SCREEN:
    lcd_clear
    lcd_printstr "Game complete"
    lcd_set_line 1
    lcd_printstr "You Win!"

    ; set LoseState to True
    inc8 LoseState

GAME_COMPLETE_SCREEN_loop:
    ;ldi r16, STROBE_LIGHT
    ;out PORTA, r16
    rcall pwm_end_game_start
    ;rjmp GAME_COMPLETE_SCREEN_loop


TIMEOUT_SCREEN:
    rcall timer_off
    lcd_clear
    lcd_printstr "Game over"
    lcd_set_line 1
    lcd_printstr "You Lose!"

    ; set LoseState to True
    inc8 LoseState

TIMEOUT_SCREEN_loop:
    rcall keypad_getkey
    rcall keypad_getval
    cpi r18, 0
    brne_long SOFT_RESET

    rjmp TIMEOUT_SCREEN_loop
    
HALT:
    rjmp HALT


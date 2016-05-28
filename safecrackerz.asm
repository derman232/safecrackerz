.include "m2560def.inc"

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

.cseg
.org 0
    jmp RESET
    jmp pushbutton_right        ; PB0 to INT0 (RDX4), right button
    jmp pushbutton_left         ; PB1 to INT1 (RDX3), left button
.org OVF0addr
    jmp timer0_interrupt       ; Timer interrupts
.org OVF1addr
    jmp DEFAULT
.org 0x0072
DEFAULT:
    reti                        ; Interrupts that aren't handled

.include "macros.asm"
.include "sleep.asm"
.include "lcd.asm"
.include "pushbutton.asm"
.include "timer.asm"
.include "interrupt.asm"

RESET:
    ; init stack
    ldi r16, low(RAMEND)
    out SPL, r16
    ldi r16, high(RAMEND)
    out SPH, r16

    ; init devices
    call lcd_init
    call pushbutton_init
    call interrupt_init
    call timer_init

START_SCREEN:
    lcd_printstr "2121 16s1"
    lcd_set_line 1
    lcd_printstr "Safe Cracker"

    rjmp halt       ; wait for button press

HALT:
    rjmp HALT



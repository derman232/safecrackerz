.include "m2560def.inc"

; global vars
.dseg


.cseg
.org 0
    jmp RESET
    jmp RIGHT_BUTTON            ; PB0 to INT0 (RDX4), right button
    jmp LEFT_BUTTON             ; PB1 to INT1 (RDX3), left button
;.org OVF0addr
;    jmp TIMER0OVF               ; Timer interrupts
;.org OVF1addr
;    jmp TIMER1OVF
.org 0x0072
DEFAULT:
    reti                        ; Interrupts that aren't handled

.include "macros.asm"
.include "sleep.asm"
.include "lcd.asm"
.include "pushbutton.asm"
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

START_SCREEN:
    lcd_printstr "2121 16s1"
    lcd_set_line 1
    lcd_printstr "Safe Cracker"

    rjmp halt       ; wait for button press

RIGHT_BUTTON:
    lcd_clear

LEFT_BUTTON:
    lcd_clear

HALT:
    rjmp HALT



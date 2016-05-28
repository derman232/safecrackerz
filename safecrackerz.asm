.include "m2560def.inc"

; global vars
.dseg


.cseg
.org 0
    jmp RESET

.include "macros.asm"
.include "sleep.asm"
.include "lcd.asm"

RESET:
    ; init stack
    ldi r16, low(RAMEND)
    out SPL, r16
    ldi r16, high(RAMEND)
    out SPH, r16

    ; init devices
    call lcd_init

    lcd_printstr "2121 16s1"
    lcd_set_line 1
    lcd_printstr "Safe Cracker"

halt:
    rjmp halt


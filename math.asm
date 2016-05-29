Divide:
    ; input: r16 and r17
    ; output r16 = r16 % r17
    ; output r17 = r16 / r17 (integer result)
    push r18
    ldi r18, 0

Divide_loop:
    cp r16, r17
    brlo Divide_end
    inc r18
    sub r16, r17
    rjmp Divide_loop

Divide_end:
    ; r16 contains the mod already
    mov r17, r18 ; move division result to r17

    pop r18
    reti

; divide 16-bit Y/Z
; division result in Y
Divide16:
    push drem16uL
    push drem16uH
    push dres16uL
    push dres16uH
    push dd16uL
    push dd16uH
    push dv16uL
    push dv16uH
    push dcnt16u

    mov dd16uL, YL
    mov dd16uH, YH
    mov dv16uL, ZL
    mov dv16uH, ZH

    rcall div16u

    mov YL, dres16uL
    mov YH, dres16uH

    pop dcnt16u
    pop dv16uH
    pop dv16uL
    pop dd16uH
    pop dd16uL
    pop dres16uH
    pop dres16uL
    pop drem16uH
    pop drem16uL

    reti


Multiply:
    ; input r16 and r17 
    ; out r16 = r16 * r17
    push r17
    push r18
    mov r18, r16

Multiply_loop:
    cpi r17, 1
    breq Multiply_end
    add r16, r18
    dec r17
    rjmp Multiply_loop
    
Multiply_end:
    pop r17
    pop r18
    reti

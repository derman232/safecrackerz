lightbar_clear:
    push r16
    ; clear lightbar
    clr r16
    out PORTC, r16
    out PORTG, r16

    pop r16
    reti


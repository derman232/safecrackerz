lightbar_init:
    push r16
    ; TODO move to function
    ser r16
    out DDRC, r16           ; set LED bar
    out DDRG, r16           ; set LED bar

    rcall lightbar_clear

    pop r16
    ret

lightbar_clear:
    push r16
    ; clear lightbar
    clr r16
    out PORTC, r16
    out PORTG, r16

    pop r16
    ret


pushbutton_init:
    push r16

    clr r16
    out DDRD, r16           ; set PORT D as input

    pop r16
    ret

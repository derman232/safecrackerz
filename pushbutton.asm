pushbutton_init:
    push r16

    clr r16
    out DDRD, r16           ; set PORT D as input

    pop r16
    reti

pushbutton_left:
    push XL
    push XH
    push r16
    load8_reg r16, RightBtnStatus
    cpi r16, 1
    breq pushbutton_left_end      ; skip if debouncing

    ldi r16, 1
    sts RightBtnStatus, r16     ; set as pressed

    lcd_clear


pushbutton_left_end:
    pop r16
    pop XH
    pop XL

    reti

pushbutton_right:
    reti


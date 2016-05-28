.set DEBOUNCE_TIME = 780*1.5    ; ~150milliseconds

timer_init:
    push r16

    ldi r16, (2 << CS00)   ; set prescaler to 8
    out TCCR0B, r16
    ldi r16, (1 << TOIE0)  ; enable timer 0
    sts TIMSK0, r16

    ldi r16, (2 << CS00)   ; set prescaler to 8
    sts TCCR1B, r16
    ldi r16, (1 << TOIE1)  ; enable timer 1
    sts TIMSK1, r16

    pop r16
    reti


timer0_interrupt:                  ; interrupt subroutine for Timer0
    timer0_prologue:
        push r16
        push XH
        push XL

    right_btn_debouncer:
        load8_reg r16, RightBtnStatus
        cpi r16, 0
        breq left_btn_debouncer       ; Skip to left button

        inc16 RightBtnCounter

        load_16 RightBtnCounter
        cpi XL, low(DEBOUNCE_TIME)
        ldi r16, high(DEBOUNCE_TIME)
        cpc XH, r16
        brne left_btn_debouncer

    right_finish_debounce:
        clear8 RightBtnStatus        ; set button status back to ready (0)
        clear16 RightBtnCounter

    left_btn_debouncer:
        load8_reg r16, LeftBtnStatus
        cpi r16, 0
        breq timer0_epilogue      ; skip to end 

        inc16 LeftBtnCounter

        load_16 LeftBtnCounter
        cpi XL, low(DEBOUNCE_TIME)
        ldi r16, high(DEBOUNCE_TIME)
        cpc XH, r16
        brne timer0_epilogue

    left_finish_debounce:
        clear8 LeftBtnStatus        ; set button status back to ready (0)
        clear16 LeftBtnCounter

    timer0_epilogue:
        pop r16
        pop XH
        pop XL

        reti

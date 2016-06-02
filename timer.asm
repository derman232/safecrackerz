.set DEBOUNCE_TIME = 780*5    ; ~150milliseconds
.set ONE_SEC_16 = 30*0.8      ; Adjusted for things (beeping)
.set MAX_RAND = 1024

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
    ret


timer0_interrupt:                  ; interrupt subroutine for Timer0
    timer0_prologue:
        push r16
        push XH
        push XL
        in r16, SREG
        push r16

    random_num:
        inc8 RandomNum8
        inc16 RandomNum
        load_16 RandomNum
        cpi XL, low(MAX_RAND)
        ldi r16, high(MAX_RAND)
        cpc XH, r16
        brlt right_btn_debouncer

        random_num_clear:
            clear16 RandomNum

    right_btn_debouncer:
        load_val8_reg r16, RightBtnStatus
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
        load_val8_reg r16, LeftBtnStatus
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
        out SREG, r16
        pop XL
        pop XH
        pop r16
        reti


timer1_interrupt:
    timer1_prologue:
        push r16
        push XH
        push XL
        in r16, SREG
        push r16


    ser r16
    out PORTD, r16
    rcall sleep_5ms
    clr r16
    out PORTD, r16


    timer1_main:
        inc16 TimerCounter
        inc16 TimerCounter2

        load_16 TimerCounter
        cpi XL, low(ONE_SEC_16)
        ldi r16, high(ONE_SEC_16)
        cpc XH, r16
        brlo timer1_epilogue              ; if (count < ONE_SEC) then NotSecond

        clear16 TimerCounter

        ; increment or decrement counter, per counter direction
        load_val8_reg r16, CounterDirection
        cpi r16, 2
        breq timer1_epilogue        ; timer off
        cpi r16, 0
        breq timer1_countUP
        timer1_countDOWN:
            dec8 SecondCounter
            lds r16, SecondCounter
            cpi r16, 0
            brlt timer1_epilogue

            rcall speaker250
            rjmp timer1_epilogue
        timer1_countUP:
            inc8 SecondCounter

    timer1_epilogue:
        pop r16
        out SREG, r16
        pop XL
        pop XH
        pop r16

        reti

timer_reset_countup:
    push r16
    push XH
    push XL
    clear16 TimerCounter
    clear8 SecondCounter

    ; set counter to count UP
    ldi r16, 0
    load_X CounterDirection
    st X, r16

    pop XL
    pop XH
    pop r16
    ret

timer_reset_countup_2:
    clear16 TimerCounter2

    ret


timer_reset_countdown:
    push r16
    push XH
    push XL

    clear16 TimerCounter
    load_X SecondCounter
    st X, r16

    ; set counter to count DOWN
    ldi r16, 1
    load_X CounterDirection
    st X, r16

    pop XL
    pop XH
    pop r16
    ret

timer_off:
    push r16
    push XH
    push XL

    clear16 TimerCounter
    load_X SecondCounter
    st X, r16

    ; set counter to stop counting
    ldi r16, 2
    load_X CounterDirection
    st X, r16

    pop XL
    pop XH
    pop r16
    ret



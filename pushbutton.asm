pushbutton_init:
    push r16

    clr r16
    out DDRD, r16           ; set PORT D as input

    pop r16
    ret

pushbutton_left:
    push XL
    push XH
    push r16
    in r16, SREG
    push r16

    load_val8_reg r16, RightBtnStatus
    cpi r16, 1
    breq pushbutton_left_end      ; skip if debouncing

    ldi r16, 1
    sts RightBtnStatus, r16     ; set as pressed

    ; test if game is over and reset
    rcall check_game_over
    cpi r16, 1
    breq RESET_GAME

    ; set game as started
    ldi r16, 1
    sts StartedState, r16
    ;inc8 StartedState
    ;cpi r16, 1
    ;breq pushbutton_left_end

    ; go to start countdown
    ;rjmp START_COUNTDOWN_SCREEN

    ;rjmp pushbutton_left_end

    pushbutton_left_end:
        pop r16
        out SREG, r16
        pop r16
        pop XH
        pop XL

        reti

pushbutton_right:
    push r16
    in r16, SREG
    push r16

    ; test if game is over and reset
    rcall check_game_over
    cpi r16, 1
    breq RESET_GAME

    pop r16
    out SREG, r16
    pop r16
    reti


; check if game is lost
check_game_over:
    load_val8_reg r16, LoseState
    cpi r16, 0
    breq game_ongoing
    game_lost:
        ldi r16, 1
        ret

    game_ongoing:
        clr r16
        ret

; check if game is started
check_game_started:
    load_val8_reg r16, StartedState
    ret

RESET_GAME:
    rjmp SOFT_RESET


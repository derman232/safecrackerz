;http://www.avrfreaks.net/forum/tutasmcode-morons-guide-avr-adc

pot_init:
    push r16

    ldi r16, (1 << REFS0) | (0 << ADLAR) | (0 << MUX0)
    sts ADMUX,r16

    ldi r16, (1 << MUX5)
    sts ADCSRB,r16

    ldi r16,  (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0) | (1 << ADATE)
    sts ADCSRA,r16

    pop r16
    ret


pot_read:
    push r16
    clr r16

    pot_read_wait:  
        lds  r16, ADCSRA        ; read the status
        andi r16, (1 << ADIF)   ; check that value is available 
        breq pot_read_wait      ; wait for value

    lds r24,ADCL        ; must read ADCL first!
    lds r25,ADCH

    ; sleep a bit for consistent POT readings
    rcall sleep_5ms
    rcall sleep_5ms

    pop r16
    ret

FIND_POT_SCREEN_readpot:
    push xh
    push xl
    push yh
    push yl

    rcall pot_read

    ; store the difference between the desired value and current POT value
    movw Y, r25:r24

    sub Xl, yl
    sbc Xh, yh
    ; ensure the result is positive
    cpi xl, 0
    ldi r18, 0
    cpc xh, r18
    brge FIND_POT_SCREEN_positive

    ; if the result is negative, exit
    ldi r18, -1
    rjmp FIND_POT_SCREEN_readpot_end

    FIND_POT_SCREEN_positive:
    load_Z 16
    movw Y, X
    rcall Divide16

    ; store the result in r18
    mov r18, yl


FIND_POT_SCREEN_readpot_end:
    pop yl
    pop yh
    pop xl
    pop xh
    ret


; set the lightbar according to the value in yl
FIND_POT_SCREEN_setlightbar:
    push r16
    push r17
    push r18

    ser r16
    
    ; set top one light
    FIND_POT_SCREEN_setlightbar_one_light:
        cpi r18, 11
        brge FIND_POT_SCREEN_setlightbar_loop_clear
        ldi r17, 0b00000010
        out PORTG, r17
        rjmp FIND_POT_SCREEN_setlightbar_two_light

    ; set top two lights
    FIND_POT_SCREEN_setlightbar_two_light:
        cpi r18, 10
        brge FIND_POT_SCREEN_setlightbar_loop
        ldi r17, 0b00000011
        out PORTG, r17
        rjmp FIND_POT_SCREEN_setlightbar_loop

    FIND_POT_SCREEN_setlightbar_loop_clear:
        clr r17
        out PORTG, r17

    FIND_POT_SCREEN_setlightbar_loop:
        cpi r18, 0
        breq FIND_POT_SCREEN_setlightbar_done
        dec r18
        lsl r16
        rjmp FIND_POT_SCREEN_setlightbar_loop

    FIND_POT_SCREEN_setlightbar_done:
    out PORTC, r16
    
    pop r18
    pop r17
    pop r16
    ret





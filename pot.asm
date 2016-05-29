pot_init:
    push r16

    ldi r16, (3 << REFS0) | (0 << ADLAR) | (0 << MUX0)
    sts ADMUX,r16

    ldi r16, (1 << MUX5)
    sts ADCSRB,r16

    ldi r16,  (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0) | (1 << ADATE)
    sts ADCSRA,r16

    pop r16
    reti


pot_read:
    pot_read_wait:  
        lds  r16, ADCSRA        ; read the status
        andi r16, (1 << ADIF)   ; check that value is available 
        breq pot_read_wait      ; wait for value

    lds r16,ADCL        ; must read ADCL first!
    lds r17,ADCH

    reti

;    cpi r16, 0
;    ldi r16, 0
;    cpc r17, r16
;    breq CLEAR
;
;    ;lcd_print8 r18
;    ;lcd_set_line 0
;    rjmp INTERRUPT

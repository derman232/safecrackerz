pot_init:
    push r16

    ldi r16, (1 << REFS0) | (0 << ADLAR) | (0 << MUX0)
    sts ADMUX,r16

    ldi r16, (1 << MUX5)
    sts ADCSRB,r16

    ldi r16,  (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0) | (1 << ADATE)
    sts ADCSRA,r16

    pop r16
    reti


; reads ADCL and ADCH and stores
; the result in r25:r24
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
    reti

;    cpi r16, 0
;    ldi r16, 0
;    cpc r17, r16
;    breq CLEAR
;
;    ;lcd_print8 r18
;    ;lcd_set_line 0
;    rjmp INTERRUPT

; paramters: X, contins the target pot reading
FIND_POT_SCREEN_readpot:
    push xh
    push xl
    push yh
    push yl

    rcall pot_read
    ; store the difference between the desired value and current POT value

    movw Y, r25:r24

    ; current pot pos
    ;lcd_print16 yh, yl
    ;lcd_printstr " "
    ; target pot pos
    ;lcd_print16 xh, xl
    ;lcd_printstr " "
    ;lcd_set_line 0

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
    ;com yl
    ;com yh
    ;subi yl, -1
    ;sbci yh, -1

    FIND_POT_SCREEN_positive:
    ; distance to target
    ;lcd_set_line_1
    ;lcd_print16 yh, yl
    ; lcd_set_line_1
    ;lcd_print16 yh, yl
    ;lcd_printstr "  "

    ; move the result into Y
    ; and divide the result by 16
    load_Z 16
    movw Y, X
    rcall Divide16

   ; lcd_clear
   ; lcd_print16 yh, yl
   ; jmp halt

    ; store the result in r18
    mov r18, yl

    ; lcd_clear
    ; lcd_print8 r18
    ; lcd_printstr "    "
    ; lcd_print8 yl
    ; jmp halt


FIND_POT_SCREEN_readpot_end:
    pop yl
    pop yh
    pop xl
    pop xh
    reti


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
    reti





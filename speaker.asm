speaker_init:
    push r16
    ser r16
    out DDRB, r16       ; set port B to output
    pop r16
    ret


speaker250:
    push r16

	clr r16
	speaker250_loop:
		inc r16
		cpi r16, 127
		breq speaker250_end

		sbi PORTB, 0
		rcall sleep_1ms
		cbi PORTB, 0
		rcall sleep_1ms
		rjmp speaker250_loop

    speaker250_end:
        pop r16
        ret


speaker500:
    cli
    push r16

	clr r16
	speaker500_loop:
		inc r16
		cpi r16, 255
		breq speaker500_end

		sbi PORTB, 0
		rcall sleep_1ms
		cbi PORTB, 0
		rcall sleep_1ms
		rjmp speaker500_loop

    speaker500_end:
        pop r16
        sei
        ret

speaker1000:
    cli
    push r24
    push r25

	clr r24
	clr r25
	speaker1000_loop:
        adiw r24:r25, 1
		cpi r24, LOW(500)
        ldi r16, HIGH(500)
		cpc r25, r16
		breq speaker1000_end

		sbi PORTB, 0
		rcall sleep_1ms
		cbi PORTB, 0
		rcall sleep_1ms
		rjmp speaker1000_loop

    speaker1000_end:
        pop r25
        pop r24
        sei
        ret



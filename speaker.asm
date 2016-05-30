speaker_init:
    push r16
    ser r16
    out DDRB, r16       ; set port b to output
    pop r16
    ret


speaker250:
    push r16

	clr r16 										; initialise keypress counter
	speaker250_loop:
		inc r16
		cpi r16, 127
		breq speaker250_end

		sbi PORTB, 0  								; make sound
		rcall sleep_1ms
		cbi PORTB, 0
		rcall sleep_1ms
		rjmp speaker250_loop

    speaker250_end:
        pop r16
        ret


speaker500:
    push r16

	clr r16 										; initialise keypress counter
	speaker500_loop:
		inc r16
		cpi r16, 255
		breq speaker500_end

		sbi PORTB, 0  								; make sound
		rcall sleep_1ms
		cbi PORTB, 0
		rcall sleep_1ms
		rjmp speaker500_loop

    speaker500_end:
        pop r16
        ret



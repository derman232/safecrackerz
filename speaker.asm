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
		cpi r16, 124
		breq speaker250_end

		sbi PORTB, 0  								; make sound
		rcall sleep_1ms
		cbi PORTB, 0
		rcall sleep_1ms
		rjmp speaker250_loop

    speaker250_end:
        pop r16
        ret




.include "m2560def.inc"

.equ phase_period = 2000	; 2 seconds - the period of the wave (time from crest to crest of wave)
.equ sleep_period = 5		; 5 ms - The amount of sleep you use in between brightness adjustments
.equ max_brightness = phase_period/(2 * sleep_period)

.def temp = r16
.def brightness = r17


pwm_init:
    push temp
    push brightness
	;ldi temp, 0b00010000 		; set PE4 (connected to PE2...) (OC3A) to output
	;out DDRE, temp

    clr temp
	sts OCR3BL, temp
	sts OCR3BH, temp

	ldi brightness, max_brightness

	ldi temp, (1 << CS30) 		; set the Timer3 to Phase Correct PWM mode, *no prescaling*
	sts TCCR3B, temp
	;ldi temp, (1 << WGM31)|(1<< WGM30)|(1<<COM3B1)|(1<<COM3A1)		; Set Phase Correct PWM, 10bit, Clear OC0A on Compare Match when up-counting. Set OC0A on Compare Match when down-counting
	;sts TCCR3A, temp
	ldi temp, (1<< WGM30)|(1<<COM3B1)|(0<<COM3A1)		
	sts TCCR3A, temp

    pop brightness
    pop temp 
    ret

pwm_start:
    clr temp
	sts OCR3BL, temp
	sts OCR3BH, temp

    duller:	
        dec brightness

        sts OCR3BL, brightness

        //clr r20
        //lcd_write_number r20, brightness
        rcall sleep_5ms

        cpi brightness, 0 			; if brightness = 0 start increasing brightness
        brne duller

    brighter:
        inc brightness

        sts OCR3BL, brightness 		; connected to PE2 (internally PE4 per datasheet)
        rcall sleep_5ms

        cpi brightness, max_brightness 		; if brightness = max_brightness start decreasing brightness
        brne brighter
        rjmp duller

.undef temp
.undef brightness


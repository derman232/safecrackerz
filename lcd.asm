; Functions to control the LCD 

.macro do_lcd_command
    push r16
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
    pop r16
.endmacro
.macro do_lcd_data
    push r16
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
    pop r16
.endmacro

; print line from next String
.macro lcd_printstr
    .set T = PC     
    .db @0, 0       ; add null terminator to string

    push ZH
    push ZL

    load_Z (T << 1)
    rcall lcd_show_str

    pop ZL
    pop ZH
.endmacro

; print one character from a specified register
.macro lcd_printchar_reg
    push r16
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
    pop r16
.endmacro

; set lcd line using @0
.macro lcd_set_line
    do_lcd_command (0b10000000 | (@0 * 0x40))
.endmacro

.macro lcd_set_line_1
    do_lcd_command 0b11000000
.endmacro

; set cursor location using @0, @1
.macro lcd_set_cursor
    do_lcd_command (0b10000000 | (@0 * 0x40) | (@1 & 0x3F))
.endmacro


.macro lcd_clear
	do_lcd_command 0b00000001 ; clear display
    do_lcd_command 0b10000000 ; set cursor to top corner
.endmacro

lcd_init:
    push r16
	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
    do_lcd_command 0b00001100 ; Cursor off, bar, no blink

    ; turn on the LCD backlight (PE5)
    ldi r16, 0b00001000
    out DDRE, r16
    out PORTE, r16

    pop r16
    ret

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

; Send a command to the LCD (r16)
lcd_command:
	out PORTF, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

lcd_show_str:
    push r16
lcd_show_str_LOOP:
    lpm r16, Z+     ; get next char
    cpi r16, 0      ; check if end of line
    breq lcd_show_str_END
    rcall lcd_data
    rcall lcd_wait
    rjmp lcd_show_str_LOOP
lcd_show_str_END:
    pop r16
    ret


.macro lcd_print8
    push r16
    push r17
	mov r16, @0

	lcd_print8_10s:
		cpi r16, 10
		brlo lcd_print8_1s
		clr r17
		lcd_print8_loop_10s:
			cpi r16, 10
			brlo display8_10s

			inc r17
			subi r16, 10

			rjmp lcd_print8_loop_10s

		display8_10s:
            subi r17, -'0'
			lcd_printchar_reg r17
			rjmp lcd_print8_1s

	lcd_print8_1s:
		subi r16, -'0'
        lcd_printchar_reg r16
		
    pop r17
    pop r16
.endmacro

.macro lcd_print16
    push xh
    push xl
    push yh
    push yl
    push r16
    push r17
	mov xh, @0
	mov xl, @1
    clr yh
    clr yl
    clr r16

	lcd_print16_10000s:
        clr r17
		cpi xl, LOW(10000)
        ldi r16, HIGH(10000)
        cpc xh, r16
		brlo display16_10000s

		lcd_print16_loop_10000s:

            cpi xl, LOW(10000)
            ldi r16, HIGH(10000)
            cpc xh, r16
			brlo display16_10000s

			inc r17

            mov r16, XL                     ; decrement parameter by 10000
            subi r16, low(10000)
            mov XL, r16
            mov r16, XH
            sbci r16, high(10000)
            mov XH, r16

			rjmp lcd_print16_loop_10000s

		display16_10000s:
            subi r17, -'0'
			lcd_printchar_reg r17
			rjmp lcd_print16_1000s

	lcd_print16_1000s:
        clr r17
		cpi xl, LOW(1000)
        ldi r16, HIGH(1000)
        cpc xh, r16
		brlo display16_1000s

		lcd_print16_loop_1000s:

            cpi xl, LOW(1000)
            ldi r16, HIGH(1000)
            cpc xh, r16
			brlo display16_1000s

			inc r17

            mov r16, XL                     ; decrement parameter by 1000
            subi r16, low(1000)
            mov XL, r16
            mov r16, XH
            sbci r16, high(1000)
            mov XH, r16

			rjmp lcd_print16_loop_1000s

		display16_1000s:
            subi r17, -'0'
			lcd_printchar_reg r17
			rjmp lcd_print16_100s

	lcd_print16_100s:
        clr r17
		cpi xl, LOW(100)
        ldi r16, HIGH(100)
        cpc xh, r16
		brlo display16_100s

		lcd_print16_loop_100s:
            cpi xl, LOW(100)
            ldi r16, HIGH(100)
            cpc xh, r16
			brlo display16_100s

			inc r17

            mov r16, XL                     ; decrement parameter by 1000
            subi r16, low(100)
            mov XL, r16
            mov r16, XH
            sbci r16, high(100)
            mov XH, r16

			rjmp lcd_print16_loop_100s

		display16_100s:
            subi r17, -'0'
			lcd_printchar_reg r17
			rjmp lcd_print16_10s


	lcd_print16_10s:
        clr r17
		cpi xl, 10
		brlo display16_10s
		lcd_print16_loop_10s:
			cpi xl, 10
			brlo display16_10s

			inc r17
			subi xl, 10

			rjmp lcd_print16_loop_10s

		display16_10s:
            subi r17, -'0'
			lcd_printchar_reg r17
			rjmp lcd_print16_1s

	lcd_print16_1s:
		subi xl, -'0'
        lcd_printchar_reg xl
		
    pop r17
    pop r16
    pop yl
    pop yh
    pop xl
    pop xh

.endmacro

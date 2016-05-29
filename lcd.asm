; Functions to control the LCD 

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

; print line from next String
.macro lcd_printstr
    .set T = PC     
    .db @0, 0       ; add null terminator to string

    push ZH
    push ZL

    load_Z (T << 1)
    rcall lcd_show_str

    pop ZH
    pop ZL
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

	lcd_print_10s:
		cpi r16, 10
		brlo lcd_print_1s
		clr r17
		lcd_print_loop_10s:
			cpi r16, 10
			brlo display_10s

			inc r17
			subi r16, 10

			rjmp lcd_print_loop_10s

		display_10s:
            subi r17, -'0'
			lcd_printchar_reg r17
			rjmp lcd_print_1s

	lcd_print_1s:
		subi r16, -'0'
        lcd_printchar_reg r16
		
    pop r17
    pop r16
.endmacro

; The program gets input from keypad and displays its ascii value on the ; LED bar
; Adapted form Lectures, Week 7 - input / output devices
.include "m2560def.inc"

.equ PORTLDIR = 0xF0 
.equ INITCOLMASK = 0xEF 
.equ INITROWMASK = 0x01 
.equ ROWMASK = 0x0F
.equ KEY_CLEAR = 0

.equ BL_ONLY = 0b00001000
.equ MOT_AND_BL = 0b00011000

.equ MOTOR = 0b00000100     ; motor on PG1
.equ MOTOR_CLEAR = 0b11111011     ; motor on PG1

.def row = r16 
.def col = r17 
.def rmask = r18 
.def cmask = r19 
.def temp1 = r20 
.def temp2 = r21

keypad_init:
    push r16
    ldi r16, PORTLDIR   ; PB7:4/PB3:0, out/in
    sts DDRL, r16

    pop r16
    ret

keypad_getkey:
    push row
    push col
    push rmask
    push cmask
    push temp1
    push temp2
    push r22

keypad_getkey_mainloop:
    ldi cmask, INITCOLMASK          ; init column mask
    clr col                         ; init col

keypad_getkey_colloop:
    cpi col, 4
    brne keypad_getkey_scan_col
    rjmp keypad_getkey_end          ; If all keys are scanned, exit.

keypad_getkey_scan_col:
    sts PORTL, cmask                ; Otherwise, scan a column.
    ldi temp1, 0xFF                 ; Slow down the scan operation.

keypad_getkey_delay:
    dec temp1
    brne keypad_getkey_delay
    lds temp1, PINL                 ; Read PORTL
    andi temp1, ROWMASK             ; Get the keypad output value
    cpi temp1, 0xF                  ; Check if any row is low
    breq keypad_getkey_nextcol
                                    ; If yes, find which row is low
    ldi rmask, INITROWMASK          ; Initialize for row check
    clr row

keypad_getkey_rowloop:
    cpi row, 4                      
    breq keypad_getkey_nextcol                    ; the row scan is over.
    mov temp2, temp1                
    and temp2, rmask                ; check un-masked bit
    breq keypad_getkey_convert      ; if bit is clear, the key is pressed
    inc row                         ; else move to the next row
    lsl rmask
    jmp keypad_getkey_rowloop
keypad_getkey_nextcol:              ; if row scan is over
    lsl cmask
    inc col                         ; increase column value
    jmp keypad_getkey_colloop       ; go to the next column

keypad_getkey_convert:
    cpi col, 3                      ; If the pressed key is in col.3
    breq keypad_getkey_letters      ; we have a letter
 
                                    ; If the key is not in col.3 and

    cpi row, 3                      ; If the key is in row3,    
    breq keypad_getkey_symbols      ; we have a symbol or 0

    mov temp1, row                  ; Otherwise we have a number in 1-9
    lsl temp1
    add temp1, row
    add temp1, col                  ; temp1 = row*3 + col
    subi temp1, -'1'                ; Add the value of character ‘1’
    jmp keypad_getkey_convert_end

keypad_getkey_letters:
    ldi temp1, 'A'                  
    add temp1, row                  ; Get the ASCII value for the key
    jmp keypad_getkey_convert_end

keypad_getkey_symbols:
    cpi col, 0                      ; Check if we have a star
    breq keypad_getkey_star
    cpi col, 1                      ; or if we have zero
    breq keypad_getkey_zero
    ldi temp1, '#'                  ; if not we have hash
    jmp keypad_getkey_convert_end
keypad_getkey_star:
    ldi temp1, '*'                  ; Set to star
    jmp keypad_getkey_convert_end
keypad_getkey_zero:
    ldi temp1, '0'                  ; Set to zero
keypad_getkey_convert_end:
    ;lcd_clear
    mov r22, temp1
    ; store the currently pressed key, and mark it as readable
    sts KeypadCurval, r22
    ldi r22, 1
    sts KeypadUpdates, r22

keypad_getkey_end:
    pop r22
    pop temp2
    pop temp1
    pop cmask
    pop rmask
    pop col
    pop row
    ret

keypad_getval:
    push r23
    push r22

    lds r18, KeypadUpdates
    cpi r18, 0
    breq keypad_getval_end

    ; wait for all keypad buttons to be high
    keypad_getval_debouncer:
        clr r23
        lds r23, PINL                 ; Read PORTL
        andi r23, ROWMASK             ; Get the keypad output value

        cpi r23, ROWMASK               ; Check if any row is low
        brne keypad_getval_debouncer

    clr r18
    sts KeypadUpdates, r18
    lds r18, KeypadCurval


keypad_getval_end:
    pop r22
    pop r23
    ret

; returns 1 in r18 if the correct button
; has been held for one second
keypad_getval_motor:
    push r23
    push r22
    push zh
    push zl
    push r16
    push r17
    push xh
    push xl

    lds r18, KeypadUpdates
    cpi r18, 0
    breq_long keypad_getval_motor_false

    ; wait for all keypad buttons to be high
    keypad_getval_motor_debouncer:

        clr r23
        lds r23, PINL                 ; Read PORTL
        andi r23, ROWMASK             ; Get the keypad output value

        ; retrieve random number for this round
        load_Z RandNums
        lds r16, RoundNum
        add zl, r16
        clr r16
        adc zh, r16
        ld r17, Z

        lds r22, KeypadCurval
        cp r17, r22
        brne_long kepad_getval_motor_debouncer_continue

    clr r22
    in r22, PORTG
    ori r22, MOTOR  
    out PORTG, r22


    ;    ldi r22, MOTOR                ; turn on the motor
    ;    out PORTG, r22

        load_val16_X TimerCounter2   ; check if motor has been on for one second
        cpi XL, LOW(ONE_SEC_16*1)
        ldi r18, HIGH(ONE_SEC_16*1)
        cpc XH, r18
        brge_long keypad_getval_motor_true

        kepad_getval_motor_debouncer_continue:
        cpi r23, ROWMASK               ; Check if any row is low
        brne_long keypad_getval_motor_debouncer

    keypad_getval_motor_false:
        clr r18
        sts KeypadUpdates, r18
        rcall timer_reset_countup_2     ; restart the timer if released
        rjmp keypad_getval_motor_end

    keypad_getval_motor_true:
        ldi r18, 1

keypad_getval_motor_end:
    in r22, PORTG
    andi r22, MOTOR_CLEAR
    out PORTG, r22

    pop xl
    pop xh
    pop r17
    pop r16
    pop zl
    pop zh
    pop r22
    pop r23
    ret


set_rand_char:
    push r16
    push r17
	push zh
	push zl
	
    lds r16, RandomNum8
    ldi r17, 16
    rcall Divide

	ldi zh, HIGH(CharacterMap<<1)
	ldi zl, LOW(CharacterMap<<1)
	add zl, r16
	clr r16
	adc zh, r16

	lpm r17, z

    ; store result in RandNums + RoundNum
    load_Z RandNums
    lds r16, RoundNum
	add zl, r16
	clr r16
	adc zh, r16
    st Z, r17

    ; print random number generated to lcd
    lcd_set_line 0
    lcd_printchar_reg r17

	
set_rand_char_end:
    pop zl
	pop zh
	pop r17
	pop r16
	ret

.undef row
.undef col
.undef rmask
.undef cmask
.undef temp1 
.undef temp2

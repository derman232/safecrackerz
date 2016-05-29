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

.def row = r16 
.def col = r17 
.def rmask = r18 
.def cmask = r19 
.def temp1 = r20 
.def temp2 = r21

.dseg KeypadCurval:
    .byte 1
.dseg KeypadUpdates:
    .byte 1
.dseg RandChar:
    .byte 1

.cseg

;RESET:
;    ldi temp1, low(RAMEND)          ; init the stack
;    out SPL, temp1
;    ldi temp1, high(RAMEND) 
;    out SPH, temp1
;
;    rcall lcd_init
;    rcall keypad_init
;
;	ldi r16, 15
;	rcall set_rand_char
;
;    ser r16             ; PORTC is output
;    out DDRC, r16
;    out DDRE, r16
;
;    out DDRE, r16
;
;main:
;    ;rcall keypad_getkey
;    ;lds r16, KeypadCurval
;    ;lcd_clear
;    rcall keypad_getkey
;    rcall keypad_get_val_motor
;    cpi r16, 0
;    breq main
;
;    lcd_printchar_reg r16
;    jmp main

keypad_init:
    push r16
    ldi r16, PORTLDIR   ; PB7:4/PB3:0, out/in
    sts DDRL, r16

    clear8 KeypadCurval
    clear8 KeypadUpdates

    pop r16
    reti

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
    ;out PORTC, temp1                ; Write value to PORTC
    mov r22, temp1
    sts KeypadCurval, r22
    ldi r22, 1
    sts KeypadUpdates, r22
    ;lcd_clear
    ;lcd_printchar_reg temp1
    jmp keypad_getkey_end

keypad_getkey_end:
    pop r22
    pop temp2
    pop temp1
    pop cmask
    pop rmask
    pop col
    pop row
    reti

; returns the last pressed value in r16 in ASCII
; or 0 if no value is available
keypad_get_val:
    keypad_get_val_debouncer: 
        lds r16, PINL                 ; Read PORTL
        andi r16, ROWMASK             ; Get the keypad output value
        cpi r16, 0xF                  ; Check if any row is low
        brne keypad_get_val_debouncer

    ldi r16, BL_ONLY
    out PORTE, r16
    lds r16, KeypadUpdates
    cpi r16, 1
    brne keypad_get_val_end
    clear8 KeypadUpdates

    lds r16, KeypadCurval
    reti
    
keypad_get_val_end:
    clr r16
    reti

keypad_get_val_motor:
    keypad_get_val_motor_debouncer: 
        lds r16, RandChar
        lds r17, KeypadCurval
        cp r16, r17
        brne kepad_get_val_motor_debouncer_continue
        ldi r16, MOT_AND_BL           ; turn on the motor
        out PORTE, r16

        kepad_get_val_motor_debouncer_continue:
            lds r16, PINL                 ; Read PORTL
            andi r16, ROWMASK             ; Get the keypad output value
            cpi r16, 0xF                  ; Check if any row is low
            brne keypad_get_val_motor_debouncer

    ;lcd_printchar_reg r16
    ldi r16, BL_ONLY
    out PORTE, r16
    lds r16, KeypadUpdates
    cpi r16, 1
    brne keypad_get_val_end
    clear8 KeypadUpdates

    lds r16, KeypadCurval
    reti
    
keypad_get_val_motor_end:
    clr r16
    reti

set_rand_char:
    push r16
    push r17
	push zh
	push zl
	
	ldi zh, HIGH(CharacterMap<<1)
	ldi zl, LOW(CharacterMap<<1)
	add zl, r16
	clr r16
	adc zh, r16

	lpm r17, z

    load_Z RandNums
    lds r16, RoundNum
	add zl, r16
	clr r16
	adc zh, r16

    lcd_clear
    lcd_printchar_reg r17

    st Z, r17
	
set_rand_char_end:
    pop zl
	pop zh
	pop r17
	pop r16
	reti

.undef row
.undef col
.undef rmask
.undef cmask
.undef temp1 
.undef temp2


.macro load_Z
    ldi ZH, HIGH(@0)
    ldi ZL, LOW(@0)
.endmacro

.macro load_X
    ldi XH, HIGH(@0)
    ldi XL, LOW(@0)
.endmacro

; Clear a 2-byte word in memory
.macro clear16
    push ZL
    push ZH
    push r16

    load_Z @0
    clr r16
    st Z+, r16
    st Z, r16

    pop r16
    pop ZH
    pop ZL
.endmacro

; Clear a 1-byte word in memory
.macro clear8
    push ZH
    push ZL
    push r16

    load_Z @0
    clr r16
    st Z, r16

    pop r16
    pop ZL
    pop ZH
.endmacro

; Increment a 2-byte word in memory
.macro inc16
    push ZL
    push ZH
    push r16

    load_Z @0
    st Z+, r16
    st Z, r16
    adiw z, 1

    pop r16
    pop ZH
    pop ZL
.endmacro

; Store into Register value from Data
.macro load8_reg
    ;push ZH
    ;push ZL

    lds @0, @1
;
;    pop ZL
;    pop ZH
.endmacro

; load @0 into X
.macro load_16
    lds XL, @0
    lds XH, @0+1
.endmacro



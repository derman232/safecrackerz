.macro load_Z
    ldi ZH, HIGH(@0)
    ldi ZL, LOW(@0)
.endmacro

.macro load_X
    ldi XH, HIGH(@0)
    ldi XL, LOW(@0)
.endmacro

.macro load_val16_X
    lds XL, @0
    lds XH, @0+1
.endmacro

.macro load_val8_reg
    lds @0, @1
    ;push XL
    ;push XH

    ;load_X @1
    ;ld @0, X
    ;st X, @0

    ;pop XH
    ;pop XL
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
    push XL
    push XH

    load_val16_X @0
    adiw X, 1
    store16_X @0

    pop XH
    pop XL
.endmacro

; Increment a 1-byte word in memory
.macro inc8
    push XL
    push XH
    push r16

    load_X @0
    ld r16, X
    inc r16
    st X, r16

    pop r16
    pop XH
    pop XL
.endmacro

; Increment a 1-byte word in memory
.macro dec8
    push XL
    push XH
    push r16

    load_X @0
    ld r16, X
    dec r16
    st X, r16

    pop r16
    pop XH
    pop XL
.endmacro


; Store value in X to a specified 2-byte var
.macro store16_X
    push ZH
    push ZL

    load_Z @0
    st Z+, XL
    st Z, XH

    pop ZL
    pop ZH
.endmacro


; load @0 into X
.macro load_16
    lds XL, @0
    lds XH, @0+1
.endmacro

.macro store_16_Z
    push XH
    push XL

    loadX @0
    st X+, ZL
    st X, ZH

    pop XL
    pop XH
.endmacro


.macro breq_long
    brne FALSE
    rjmp @0
FALSE:
.endmacro

.macro brlt_long
    brlt FALSE
    rjmp @0
FALSE:
.endmacro

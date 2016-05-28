.macro load_Z
    ldi ZH, HIGH(@0)
    ldi ZL, LOW(@0)
.endmacro



interrupt_init:
    ; Setup interrupts to trigger on falling edge
    ldi r16, (2 << ISC00)|(2 << ISC10)
    sts EICRA, r16

    ; Enable INT0 and INT1
    ldi r16, (1 << INT0)|(1 << INT1)
    out EIMSK, r16

    sei         ; enable interrupts

    ret


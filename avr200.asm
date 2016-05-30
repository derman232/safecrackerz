;**** A P P L I C A T I O N   N O T E   A V R 2 0 0 ************************
;*
;* Title:		Multiply and Divide Routines
;* Version:		1.1
;* Last updated:	97.07.04
;* Target:		AT90Sxxxx (All AVR Devices)
;*
;* Support E-mail:	avr@atmel.com
;* 

;* DESCRIPTION
;* This Application Note lists subroutines for the following
;* Muliply/Divide applications:
;*
;* 8x8 bit unsigned
;* 8x8 bit signed
;* 16x16 bit unsigned
;* 16x16 bit signed
;* 8/8 bit unsigned
;* 8/8 bit signed
;* 16/16 bit unsigned
;* 16/16 bit signed
;*
;* All routines are Code Size optimized implementations
;*

;***************************************************************************


;***************************************************************************
;*
;* "div16u" - 16/16 Bit Unsigned Division
;*
;* This subroutine divides the two 16-bit numbers 
;* "dd8uH:dd8uL" (dividend) and "dv16uH:dv16uL" (divisor). 
;* The result is placed in "dres16uH:dres16uL" and the remainder in
;* "drem16uH:drem16uL".
;*  
;* Number of words	:19
;* Number of cycles	:235/251 (Min/Max)
;* Low registers used	:2 (drem16uL,drem16uH)
;* High registers used  :5 (dres16uL/dd16uL,dres16uH/dd16uH,dv16uL,dv16uH,
;*			    dcnt16u)
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	drem16uL=r14
.def	drem16uH=r15
.def	dres16uL=r16
.def	dres16uH=r17
.def	dd16uL	=r16
.def	dd16uH	=r17
.def	dv16uL	=r18
.def	dv16uH	=r19
.def	dcnt16u	=r20

;***** Code

div16u:	clr	drem16uL	;clear remainder Low byte
	sub	drem16uH,drem16uH;clear remainder High byte and carry
	ldi	dcnt16u,17	;init loop counter
d16u_1:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	dec	dcnt16u		;decrement counter
	brne	d16u_2		;if done
	ret			;    return
d16u_2:	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_3		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_1		;else
d16u_3:	sec			;    set carry to be shifted into result
	rjmp	d16u_1
	
	

;***************************************************************************
;*
;* "div16s" - 16/16 Bit Signed Division
;*
;* This subroutine divides signed the two 16 bit numbers 
;* "dd16sH:dd16sL" (dividend) and "dv16sH:dv16sL" (divisor). 
;* The result is placed in "dres16sH:dres16sL" and the remainder in
;* "drem16sH:drem16sL".
;*  
;* Number of words	:39
;* Number of cycles	:247/263 (Min/Max)
;* Low registers used	:3 (d16s,drem16sL,drem16sH)
;* High registers used  :7 (dres16sL/dd16sL,dres16sH/dd16sH,dv16sL,dv16sH,
;*			    dcnt16sH)
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	d16s	=r13		;sign register
.def	drem16sL=r14		;remainder low byte		
.def	drem16sH=r15		;remainder high byte
.def	dres16sL=r16		;result low byte
.def	dres16sH=r17		;result high byte
.def	dd16sL	=r16		;dividend low byte
.def	dd16sH	=r17		;dividend high byte
.def	dv16sL	=r18		;divisor low byte
.def	dv16sH	=r19		;divisor high byte
.def	dcnt16s	=r20		;loop counter

;***** Code

div16s:	mov	d16s,dd16sH	;move dividend High to sign register
	eor	d16s,dv16sH	;xor divisor High with sign register
	sbrs	dd16sH,7	;if MSB in dividend set
	rjmp	d16s_1
	com	dd16sH		;    change sign of dividend
	com	dd16sL		
	subi	dd16sL,low(-1)
	sbci	dd16sL,high(-1)
d16s_1:	sbrs	dv16sH,7	;if MSB in divisor set
	rjmp	d16s_2
	com	dv16sH		;    change sign of divisor
	com	dv16sL		
	subi	dv16sL,low(-1)
	sbci	dv16sL,high(-1)
d16s_2:	clr	drem16sL	;clear remainder Low byte
	sub	drem16sH,drem16sH;clear remainder High byte and carry
	ldi	dcnt16s,17	;init loop counter

d16s_3:	rol	dd16sL		;shift left dividend
	rol	dd16sH
	dec	dcnt16s		;decrement counter
	brne	d16s_5		;if done
	sbrs	d16s,7		;    if MSB in sign register set
	rjmp	d16s_4
	com	dres16sH	;        change sign of result
	com	dres16sL
	subi	dres16sL,low(-1)
	sbci	dres16sH,high(-1)
d16s_4:	ret			;    return
d16s_5:	rol	drem16sL	;shift dividend into remainder
	rol	drem16sH
	sub	drem16sL,dv16sL	;remainder = remainder - divisor
	sbc	drem16sH,dv16sH	;
	brcc	d16s_6		;if result negative
	add	drem16sL,dv16sL	;    restore remainder
	adc	drem16sH,dv16sH
	clc			;    clear carry to be shifted into result
	rjmp	d16s_3		;else
d16s_6:	sec			;    set carry to be shifted into result
	rjmp	d16s_3



;****************************************************************************
;*
;* Test Program
;*
;* This program calls all the subroutines as an example of usage and to 
;* verify correct verification.
;*
;****************************************************************************

;***** Main Program Register variables

.def	temp	=r16		;temporary storage variable

;;***** Code
;RESET:
;;---------------------------------------------------------------
;;Include these lines for devices with SRAM
;;	ldi	temp,low(RAMEND)
;;	out	SPL,temp	
;;	ldi	temp,high(RAMEND)
;;	out	SPH,temp	;init Stack Pointer
;;---------------------------------------------------------------
;
;;***** Multiply Two Unsigned 8-Bit Numbers (250 * 4)
;
;	ldi	mc8u,250
;	ldi	mp8u,4
;	rcall	mpy8u		;result: m8uH:m8uL = $03e8 (1000)
;
;;***** Multiply Two Signed 8-Bit Numbers (-99 * 88)
;	ldi	mc8s,-99
;	ldi	mp8s,88
;	rcall	mpy8s		;result: m8sH:m8sL = $ddf8 (-8712)
;
;;***** Multiply Two Unsigned 16-Bit Numbers (5050 * 10,000)
;	ldi	mc16uL,low(5050)
;	ldi	mc16uH,high(5050)
;	ldi	mp16uL,low(10000)
;	ldi	mp16uH,high(10000)
;	rcall	mpy16u		;result: m16u3:m16u2:m16u1:m16u0
;				;=030291a0 (50,500,000)
;	
;;***** Multiply Two Signed 16-Bit Numbers (-12345*(-4321))
;	ldi	mc16sL,low(-12345)
;	ldi	mc16sH,high(-12345)
;	ldi	mp16sL,low(-4321)
;	ldi	mp16sH,high(-4321)
;	rcall	mpy16s		;result: m16s3:m16s2:m16s1:m16s0
;				;=$032df219 (53,342,745)
;
;;***** Divide Two Unsigned 8-Bit Numbers (100/3)
;	ldi	dd8u,100
;	ldi	dv8u,3
;	rcall	div8u		;result: 	$21 (33)
;				;remainder:	$01 (1)
;
;;***** Divide Two Signed 8-Bit Numbers (-110/-11)
;	ldi	dd8s,-110
;	ldi	dv8s,-11
;	rcall	div8s		;result:	$0a (10)
;				;remainder	$00 (0)
;
;
;;***** Divide Two Unsigned 16-Bit Numbers (50,000/60,000)
;	ldi	dd16uL,low(50000)
;	ldi	dd16uH,high(50000)
;	ldi	dv16uL,low(60000)
;	ldi	dv16uH,high(60000)
;	rcall	div16u		;result:	$0000 (0)
;				;remainder:	$c350 (50,000)
;
;
;;***** Divide Two Signed 16-Bit Numbers (-22,222/10)
;	ldi	dd16sL,low(-22222)
;	ldi	dd16sH,high(-22222)
;	ldi	dv16sL,low(10)
;	ldi	dv16sH,high(10)
;	rcall	div16s		;result:	$f752 (-2222)
;				;remainder:	$0002 (2)
;
;forever:rjmp	forever


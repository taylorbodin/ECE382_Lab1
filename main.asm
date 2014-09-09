;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Coded by C2C Taylor Bodin
; Written for ECE 382- Embedded Systems
;
; This code acts as a simple calculator on a stiring of bits. For most operations
; the result of one operation becomes an operator for the next operation allowing
; this code to perform multiple operations on a "running" operator. The reults are
; stored to memory after execution starting at 0x0200
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section

ts: 		.byte	0x22, 0x11, 0x22, 0x22, 0x33, 0x33, 0x08, 0x44, 0x08, 0x22, 0x09, 0x44, 0xff, 0x11, 0xff, 0x44, 0xcc, 0x33, 0x02, 0x33, 0x00, 0x44, 0x33, 0x33, 0x08, 0x55
			.bss	store, 0x40
;clr_bit    	.equ 	#0x0000
;word_size   .equ	#0x0008
;min_val		.equ	#0x0000
;max_val		.equ	#0x00FF
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
                                            ; Main loop here
;-------------------------------------------------------------------------------
main:
	mov.w   #__STACK_END,SP				; BOILERPLATE	Initialize stackpointer
	mov.w   #WDTPW|WDTHOLD,&WDTCTL 		; BOILERPLATE	Stop watchdog timer

	mov.w	#store, R10					; Register 10 is a pointer to RAM

	mov.w	#ts,  R5					; Register 5 is a pointer to the case test string
	mov.b	@R5+, R6					; R6 = value @ M[R5-1] and holds the first operator (usually the result)
	mov.b	@R5,  R7					; R7 = value @ M[R5] and holds the operation
	mov.b	1(R5),R8					; R8 = value @ M[R5+1] and holds the second operator

check11:								; The following blocks just check for operations and then
	cmp.b	#0x11, R7					;jump to the next check or the appropriate operation
	jnz		check22
	jmp     add_op

check22:
	cmp.b	#0x22, R7
	jnz		check33
	jmp     sub_op

check33:
	cmp.b	#0x33, R7
	jnz		check44
	jmp		mul_op

check44:
	cmp.b  #0x44, R7
	jnz	   next
	jmp    clr_op

next:
	cmp.b	#0x55, R8
	jz		end
	incd.w	R5
	mov.b	@R5, R7					; Double increment keeps R7 on 1,3,5... which is the operation
	mov.b	1(R5), R8				; One past @R5 is always the second operand
	jmp		check11

add_op:								; Adds the second operand (R8) from the result (R6)
	mov.b	R6, R9
	add		R8, R9
	mov		R9, R6
	call	#min_max
	mov.b	R6, 0(R10)
	inc.w	R10
	jmp		next

sub_op:								; Subtracts the second operand (R8) from the result (R6)
	mov.b	R8, R9
	sub		R9, R6
	call	#min_max
	mov.b	R6, 0(R10)
	inc.w	R10
	jmp		next

mul_op:								; Multiplies using the shift/addition algorithm
	mov.b	R6, R9					; R9  = multiplicand
	mov.b	R8, R11					; R11 = multiplier
	clr.b	R12  					; R12 = result
	mov.b   #0x08, R13			    ; R13 = loop counter initialized to the word size
checkbit:
    rra 	R11						; Deterimines if the LSB of a rotated multiplier is 1
    jnc		mul_loop
    add		R9, R12					; If so it adds the multiplicand to the result (A x 1 = A)
mul_loop:
	rla		R9						; Shift the multiplicand as the place value of the multiplier goes up
	dec		R13
	jnz		checkbit
mul_finished:
	mov		R12, R6					; R6 is our result
	call	#min_max
	mov.b   R6, 0(R10)
	inc.w	R10
	jmp		next

clr_op:								; Stores 0x00 to memory
	mov.b	#0x00, 0(R10)
	mov.b   R8, R6					; moves the second operand into the first operand (R6) for next op
	inc.w	R10
	jmp		next

min_max:							; Checks to see if R6 higher than max or lower than min
	tst		R6						; If R6 is negative (less than 0x0000 which is the min) jump to min
	jn		min
	cmp		#0x00FF, R6				; If R6 higher or the same as max jump to max
	jhs		max
	ret
max:
	mov.b	#0xFF, R6
	ret
min:
	mov.b	#0x00, R6
	ret

end:
	jmp	    end


;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack

;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET

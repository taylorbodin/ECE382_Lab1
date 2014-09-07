;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
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
clr_bit:	.equ	#0x00
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

	mov.w	#ts, R5						; Register 5 is a pointer to the test string
	mov.b	@R5+,R6						; R6 = value @ M[R5-1] and holds the caboose
	mov.b	@R5+,R7						; R7 = value @ M[R5] and holds the middle
	mov.b	@R5+,R8						; R8 = value @ M[R5+1] and holds the engine

check11:								;The following blocks just check for operations and then
	cmp.b	#0x11, R7					;jump to the next check or the appropriate operation
	jnz		check22
	jmp     add_op

check22:
	cmp.b	#0x22, R7
	jnz		check33
	jmp     sub_op

check33:
	cmp.b	#0x33, R7
	jnz		next
	jmp		mul_op

check44:
	cmp.b  #0x44, R7
	jnz	   next
	jmp    clr_op

next:
	cmp.b	#0x55, R8
	jz		end						; if 0x55 is found jump to end
	mov.b	R7, R6					; else load up the next set of values into the train
	mov.b	R8, R7
	mov.b	@R5+, R8
	jmp		check11

add_op:								; adds the caboose to the engine and writes to memory
	mov.b	R6, R9
	add.b	R8, R9
	mov.b	R9, @R10
	inc.w	R10
	jmp		next

sub_op:								; subtracts the caboose from the engine and writes to memory
	mov.b	R8, R9
	sub.b	R6, R9
	mov.b	R9, @R10
	inc.w	R10
	jmp		next

mul_op:								; multiplies the caboose and engine using the following algorithm
	mov.b	R6, R9					; Shift the multiplier to the right, if the carry flag is set add
	xor.b	R8, R9					; the multiplicand to the result, shift the multiplicand to the right
	mov.b	R9, @R10				; rinse and repeat
	inc.w	R10
	jmp		next

clr_op:								; stores 0x00 to memory
	mov.b	clr_bit, @R10
	inc.w	R10
	jmp		next

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

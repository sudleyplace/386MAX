;' $Header:   P:/PVCS/MAX/ASQENG/TIMER.ASV   1.1   30 May 1997 14:58:44   BOB  $
	 title	 TIMER -- Memory Timer Routines
	 page	 58,122
	 name	 TIMER

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE.

Link requirements:  None.

Program derived from:  TIMER.ASM for 386MAX.

Original code by:  Bob Smith, January, 1987.

Modifications by:  Alan C. Lindsay, August 1990.


|

	.MODEL LARGE,PASCAL

.xlist
	 include MASM.INC
	 include PTR.INC
	 include 8253.INC

.list

	.CODE

TIME_MEM PROC	TIMER_DS:WORD, CPU_FLAG:WORD

COMMENT|

Time memory accesses to the specified data segment

On entry:

TIMER_DS =	 segment or selector of location to test
CPU_FLAG =	 0 for pre-386, > 0 for 386 and above.

On exit:

AX	 =	 timer value (guaranteed to be non-zero)

|

@TIME_SIZE equ	 4		; # kilobytes to time

	 cld			; String ops forwardly
	 cli			; Disable interrupts

	 REGSAVE <si,ds>	; Save register

	 cmp	 CPU_FLAG,0	; Check type of CPU
	 je	 NOT_386	; Skip flush if less than 386

	 ; This is supposed to flush the cache on machines that have one

	 mov	 ax,TIMER_DS	; Get segment to time
	 add	 ax,6000h	; Skip to a segment we won't read
	 cmp	 ax,9000h	; Izit in high DOS?
	 jbe	 short @F	; Jump if not

	 sub	 ax,ax		; Don't piss on persnickety IBM Token Ring
@@:
	 mov	 ds,ax
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si
	 mov	 cx,4000h
.386
	 push	 eax		; Save for a moment
	rep lodsd
	 pop	 eax		; Restore
.8086

	 mov	 ds,TIMER_DS	; Get segment to time
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; Offset zero

	 mov	 cx,@TIME_SIZE*1024/4 ; # iterations in units of dwords

	 call	 TIMER_SETUP	; Initialize timer channel 2

.386
	 push	 eax		; Save for a moment
	rep lodsd
	 pop	 eax		; Restore
.8086

	 call	 TIMER_READ	; Latch and read timer 2 value into AX
	 call	 TIMER_RESTORE	; Restore timer channel 2

	 jmp	 TIME_DONE	; Join common code

NOT_386:
	 mov	 ds,TIMER_DS	; Get segment to time
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; Offset zero

	 mov	 cx,@TIME_SIZE*1024/2 ; # iterations in units of dwords

	 call	 TIMER_SETUP	; Initialize timer channel 2

	 push	 ax		; Save for a moment
	rep lodsw
	 pop	 ax		; Restore

	 call	 TIMER_READ	; Latch and read timer 2 value into AX
	 call	 TIMER_RESTORE	; Restore timer channel 2

TIME_DONE:
	 REGREST <ds,si>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 sti			; Start interrupts
	 ret			; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,ss:nothing

TIME_MEM endp			; End TIME_MEM procedure

;;;;;;;TIME_CPU PROC	COUNT:WORD
;;;;;;;
;;;;;;;COMMENT|
;;;;;;;
;;;;;;;Time CPU operations
;;;;;;;
;;;;;;;On exit:
;;;;;;;
;;;;;;;AX	 =	 timer value
;;;;;;;
;;;;;;;|
;;;;;;;
;;;;;;;  REGSAVE <di>		; Save register
;;;;;;;  cli			; Clear Interrupts
;;;;;;;  call	 TIMER_SETUP	; Initialize timer channel 2
;;;;;;;;
;;;;;;;  mov	 di,08000h	; Set DI
;;;;;;;  mov	 ax,COUNT	; Get count argument
;;;;;;;  add	 ax,99		; Round up
;;;;;;;  mov	 cx,100 	; Divide by 100 =
;;;;;;;  div	 cl		;  Number of instructions
;;;;;;;  mov	 cl,al		;  per pass
;;;;;;;;
;;;;;;;;	 Timing loop begins here
;;;;;;;;
;;;;;;;  EVEN			; Ensure word alignment
;;;;;;;HERE:	 REPT	 100		; Do 100 multiplies
;;;;;;;  mul	 di		;
;;;;;;;  ENDM			; End macro
;;;;;;;
;;;;;;;  dec	 cx		; Count this pass
;;;;;;;  jz	 @F		; Jump if complete
;;;;;;;  jmp	 HERE		; Loop back if not done
;;;;;;;@@:
;;;;;;;;
;;;;;;;  call	 TIMER_READ	; Latch and read timer 2 value into AX
;;;;;;;  call	 TIMER_RESTORE	; Restore timer channel 2
;;;;;;;  sti			; Start interrupts
;;;;;;;
;;;;;;;  assume  ds:nothing	; Tell the assembler about it
;;;;;;;
;;;;;;;  REGREST <di>		; Restore
;;;;;;;  ret			; Return to caller, popping argument
;;;;;;;
;;;;;;;  assume  ds:nothing,es:nothing,ss:nothing
;;;;;;;
;;;;;;;TIME_CPU endp			; End TIME_CPU procedure
;;;;;;;
	 NPPROC  TIMER_SETUP	; -- Setup Timer
	 assume  ds:nothing,es:nothing,ss:nothing

SPEED	 equ	 8		; Assume worst case of 8MHz CPU

DELAY1US macro			; Delay for 1 miscrosecond

	 push	 cx		; Save for a moment
	 mov	 cx,1+1000/(11*SPEED) ; Account for CPU speed
	 loop	 $		; Wait for completion
	 pop	 cx		; Restore

	 endm

TIMER_SET equ	 (0*@TIMER_CH) or @TIMER_LMSB or (2*@TIMER_MODE) or @TIMER_BIN

	 REGSAVE <ax>		; Save register

	 mov	 al,TIMER_SET	; Setup counter 0, mode 2
	 out	 @8253_CTL,al
	 DELAY1US		; Wait for 1 microsecond

	 xor	 al,al		; Zero gives full count of 65536
	 out	 @8253_CH0,al	; Load low-order byte
	 DELAY1US		; Wait for 1 microsecond

	 out	 @8253_CH0,al	; Load high-order byte
	 DELAY1US		; Wait for 1 microsecond

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

TIMER_SETUP endp		; End TIMER_SETUP procedure
	 NPPROC  TIMER_RESTORE	; -- Restore Timer
	 assume  ds:nothing,es:nothing,ss:nothing

TIMER_RESET equ  (0*@TIMER_CH) or @TIMER_LMSB or (3*@TIMER_MODE) or @TIMER_BIN

	 REGSAVE <ax>		; Save register

	 mov	 al,TIMER_RESET ; Setup counter 0, mode 3
	 out	 @8253_CTL,al
	 DELAY1US		; Wait for 1 microsecond

	 xor	 al,al		; Zero gives full count of 65536
	 out	 @8253_CH0,al	; Load low-order byte
	 DELAY1US		; Wait for 1 microsecond

	 out	 @8253_CH0,al	; Load high-order byte
	 DELAY1US		; Wait for 1 microsecond

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

TIMER_RESTORE endp		; End TIMER_RESTORE procedure
	 NPPROC  TIMER_READ	; -- Read Timer
	 assume  ds:nothing,es:nothing,ss:nothing

TIMER_LATCH equ  @TIMER_LATCH or (0*@TIMER_CH)

	 mov	 al,TIMER_LATCH ; Tell 8253 to latch channel 0

	 out	 @8253_CTL,al	; Latch current contents
	 DELAY1US		; Wait for 1 microsecond

	 in	 al,@8253_CH0	; Read in low-order byte
	 DELAY1US		; Wait for 1 microsecond

	 mov	 ah,al		; Copy
	 in	 al,@8253_CH0	; Read in high-order byte
	 DELAY1US		; Wait for 1 microsecond

	 xchg	 al,ah		; Swap for comparisons
	 neg	 ax		; Convert count down to count up
				; Note that we counted down from 0, so
				; FFFF (-1) should be 1 and 0, 0

	 cmp	 ax,1		; Izit 0?
	 adc	 ax,0		; 0 is a reserved value - convert to 1,
				; since this timing was either extremely
				; fast or ridiculously slow.

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

TIMER_READ endp 		; End TIMER_READ procedure

	 end

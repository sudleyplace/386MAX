;' $Header:   P:/PVCS/MAX/STATUTIL/STKINFO.ASV   1.1   30 May 1997 12:17:46   BOB  $
	 title	 STKINFO -- Stack usage reporting
	 page	 58,122
	 name	 STKINFO

COMMENT|		Module Specifications

Copyright:  Copyright (C) 1996-7 Qualitas, Inc.  All rights reserved.

Link requirements:  Link with any C-runtime app.

Program derived from:  none.

Original code by:  Henry Groover, Mar 1996.

C usage:
	 extern "C" void __far FillStack( char __far *lpPattern );

	 Fills stack using any specified pattern (e.g. "StcK").
	 Should be called at start of application, or at any
	 time to reset stack as "untouched."

	 extern "C" unsigned int __far VirginStack( void );

	 Returns number of bytes remaining untouched in stack.

|

.model large,c

.xlist
include MASM.INC
.list

.data
	 extrn		STKHQQ:word		; DGROUP offset of stack bottom

	 dwFiller	dd	 0	; Filler pattern to use

.code

.386
FillStack  proc  lpPattern:dword ; Far pointer to filler pattern

	 REGSAVE <edi>

	 les	 bx,lpPattern ; Address filler pattern
;;;; assume	 es:DGROUP

	 mov	 eax,es:[dword ptr bx] ; Get filler dword
	 mov	 dwFiller,eax ; Save for later

	 mov	 bx,ss		; Get stack segment
	 mov	 es,bx		; Address for scan
;;;; assume	 es:DGROUP

	 movzx	 edi,STKHQQ	; Get start of stack
	 movzx	 ecx,sp 	; Get current top of stack
	 sub	 ecx,4		; Back off by one dword
	 sub	 ecx,edi	; Get total count
	 jc		 short FillStk_Exit ; Jump if nothing left

	 shr	 ecx,2-0	; Convert to dword count
	 cld				; Set forward direction

rep	 stosd				; Fill 'er up

FillStk_Exit:
	 REGREST <edi>

	 ret				; Return to caller

FillStack	endp		; End FillStack procedure

VirginStack proc

	 REGSAVE <edi>

	 mov	 bx,ss		; Get stack segment
	 mov	 es,bx		; Address for scan
;;;; assume	 es:DGROUP

	 movzx	 edi,STKHQQ	; Address start of stack
	 mov	 eax,dwFiller ; What to look for
	 mov	 ecx,10000h / 4 ; Maximum dwords to scan

	 cld				; Set forward direction

repe scasd				; ES:EDI ==> first mismatch

	 sub	 di,STKHQQ	; DI = bytes skipped
	 movzx	 eax,di 	; Prepare to return

	 REGREST <edi>

	 ret				; Return to caller

VirginStack endp

.8086
	 end			; End of module


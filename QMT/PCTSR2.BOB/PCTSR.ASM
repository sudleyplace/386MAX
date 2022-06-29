;' $Header$
	title	PCTSR -- PCTSR Main Routines
	page	58,122
	name	PCTSR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1999-2001 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  dword-aligned, public, class 'prog'
	       Tail    segment NCODE, byte-aligned,  public, class 'prog'

Program derived from:  None.

Original code by:  Bob Smith, February, 1999.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC
.list

PGROUP	group	STACK,CODE,NCODE


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKers need to have
; a stack segment.

STACK	segment use16 byte stack 'prog' ; Start STACK segment
STACK	ends			; End STACK segment


CODE	segment use16 dword public 'prog' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP,es:PGROUP
.xlist
	include PSP.INC 	; Define & skip over PSP area for .COM program
.list

INITIAL:
	jmp	PCTSR		; Join initialization code

	align	4

; Define resident data here

	public	OLDINT2F_VEC,OLDINT19_VEC
OLDINT2F_VEC dd ?		; Save area for pointer to old INT 2Fh handler
OLDINT19_VEC dd ?		; ...				   19h

	public	PCTSR_SIG
PCTSR_SIG db	'PCTEST TSR API, Version 2',0 ; Signature
PCTSR_SIGLEN equ $-PCTSR_SIG	; Length of ...

; Define resident code here

	FPPROC	INT2F -- Extended Memory Size
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	pushf			; Save caller's flags

	cmp	ax,168Ah	; Izit vendor API check?
	jne	short INT2F_ORIG ; Jump if not

COMMENT|

On entry:

DS:SI	==>	PCTSR signature

On exit:

AL	=	0
ES:DI	==>	API entry point

|

	REGSAVE <cx,si,di,es>	; Save registers

	cld			; String ops forwardly

	push	cs		; Copy out segment
	pop	es		; ...to ES
	assume	es:PGROUP	; Tell the assembler about it

	lea	di,PCTSR_SIG	; ES:DI ==> PCTSR signature
	mov	cx,PCTSR_SIGLEN ; Get length of ...
   repe cmps	ds:[si].LO,PCTSR_SIG[di] ; Compare 'em
				; Return with ZF significant
	REGREST <es,di,si,cx>	; Restore
	assume	es:nothing	; Tell the assembler about it
	jne	short INT2F_ORIG ; Jump if no match

	push	cs		; Copy out segment
	pop	es		; ...to ES
;;;;;;; assume	es:PGROUP	; Tell the assembler about it

	lea	di,PCTSR_API	; ES:DI ==> our entry point
	mov	al,0		; Mark as successful

	popf			; Restore caller's flags

	iret			; Return to caller

INT2F_ORIG:
	popf			; Restore caller's flags

	jmp	OLDINT2F_VEC	; Continue on to next handler

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT2F	endp			; End INT2F procedure
	FPPROC	INT19 -- Bootstrap Loader Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	mov	al,2Fh		; Return this one
	lds	dx,OLDINT2F_VEC ; DS:DX ==> old INT 2Fh handler
	assume	ds:nothing	; Tell the assembler about it
	DOSCALL @SETINT 	; Return it

	mov	al,19h		; Return this one
	lds	dx,OLDINT19_VEC ; DS:DX ==> old INT 19h handler
	assume	ds:nothing	; Tell the assembler about it
	DOSCALL @SETINT 	; Return it

	jmp	OLDINT19_VEC	; Continue on

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT19	endp			; End INT19 procedure
	FPPROC	PCTSR_API -- PC TSR API
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

On exit:

|

	REGSAVE <>		; Save registers

	int	01h		; Call our debugger

	REGREST <>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PCTSR_API endp			; End PCTSR_API procedure

CODE	ends			; End CODE segment


NCODE	segment use16 byte public 'prog' ; Start NCODE segment
	assume	cs:PGROUP

	public	ZTAIL
ZTAIL	label	byte

; Define non-resident data here

	public	MSG_COPY
MSG_COPY db	'PCTSR   -- Version 1.10 ',CR,LF
	db	'   (C) Copyright 1999-2001 Qualitas, Inc. '
	db	' All rights reserved.',CR,LF,EOS

	public	MSG_PREV
MSG_PREV db	'ออ> PC TSR already resident.',CR,LF,EOS

; Define non-resident code here

	NPPROC	PCTSR -- PC TSR API
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

On exit:

|

	DOSCALL @STROUT,MSG_COPY ; Display our copyright

; See if there's an existing PC TSR

	lea	si,PCTSR_SIG	; DS:SI ==> PC TSR signature

	mov	ax,168Ah	; Function code to get API entry point
	int	2Fh		; Request multiplex service
	assume	es:nothing	; Tell the assembler about it
				; If present, return with AL = 0, ES:DI ==> API
	cmp	al,0		; Izit present?
	je	short PCTSR_PREV ; Jump if so

; Hook interrupts and go resident

	push	es		; Save for a moment

	mov	al,2Fh		; Install this handler
	DOSCALL @GETINT 	; Return with ES:BX ==> old handler
	assume	es:nothing	; Tell the assembler about it

	mov	OLDINT2F_VEC.VOFF,bx ; Save for later use
	mov	OLDINT2F_VEC.VSEG,es ; ...

	mov	al,19h		; Install this handler
	DOSCALL @GETINT 	; Return with ES:BX ==> old handler
	assume	es:nothing	; Tell the assembler about it

	mov	OLDINT19_VEC.VOFF,bx ; Save for later use
	mov	OLDINT19_VEC.VSEG,es ; ...

	pop	es		; Restore
	assume	es:PGROUP	; Tell the assembler about it

	mov	al,2Fh		; Install this handler
	DOSCALL @SETINT,INT2F

	mov	al,19h		; Install this handler
	DOSCALL @SETINT,INT19

	lea	dx,ZTAIL	; DS:DX ==> next address
	int	27h		; Return to DOS as resident program

PCTSR_PREV:
	DOSCALL @STROUT,MSG_PREV ; Tell 'em we're already resident

	mov	al,-1		; Exit code
	DOSCALL @EXITRC 	; Exit back to DOS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PCTSR	endp			; End PCTSR procedure

NCODE	ends			; End NCODE segment

	MEND	INITIAL 	; End PCTSR module

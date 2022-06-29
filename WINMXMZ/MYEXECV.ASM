; $Header:   P:/PVCS/MAX/WINMXMZ/MYEXECV.ASV   1.2   28 Dec 1995 17:04:40   HENRY  $
;
; MYEXECV.ASM - Function to overlay-execute another program
;
; Copyright (C) 1995 Qualitas, Inc.  All rights reserved.
;

.model small,c

; Includes
include <masm.inc>
include <ptr.inc>
include <mac.inc>
include <doscall.inc>
include <exec.inc>
include <opcodes.inc>

TermPtr	equ	(VECTOR ptr	 es:[0ah])	; PSP terminate vector (int 22)
CtrlCPtr equ (VECTOR ptr es:[0eh])	; PSP Ctrl-C handler (int 23)
CErrPtr equ (VECTOR ptr  es:[12h])	; PSP critical error handler (int 24)
CtrlPtr equ (word ptr	 es:[16h])	; PSP parent segment
EnvPtr	equ (word ptr	 es:[2ch])	; PSP environment segment
FileTabPtr equ (VECTOR ptr es:[34h]) ; PSP file handle table pointer
;StackPtr equ (VECTOR ptr es:[2eh])	; PSP return stack

MacPtr  equ (MAC_STR ptr es:[0])

; This little section of __HI* code and data will net us some linker
; bitching about group-relative fixups.  Who cares?

__HIGROUP group	 __LOCODE,__HIDATA,__HICODE,__HISTAK,__HIZEND

__LOCODE segment use16 byte public '__prog' ; Start __LOCODE segment
__LOCODE ends			; End __LOCODE segment

__HICODE segment use16 byte public '__prog' ; Start __HICODE segment
__HICODE ends			; End __HICODE segment

__HIDATA segment use16 byte public '__data' ; Start __HIDATA segment
__HIDATA ends			; End __HIDATA segment

__HICODE segment use16 byte public '__prog' ; Start __HICODE segment
__HICODE ends			; End __HICODE segment

__HISTAK segment use16 dword public 'stack' ; Start __HISTAK segment
	assume	ds:__HIGROUP

	public	HighStack,HighStackEnd
HighStack dw 512 dup ('TS')
HighStackEnd label word

__HISTAK ends			; End __HISTAK segment

__HIZEND segment use16 para public '__zzend' ; Start __HIZEND segment
	assume	ds:__HIGROUP

	public EndHigh
EndHigh	label dword

__HIZEND ends			; End __HIZEND segment

__HIDATA segment
	assume	ds:__HIGROUP

;LOADDBG_ENV dw	 ?		; Segment of environment
;LOADDBG_CMD dd	 ?		; Seg:off of command line
;LOADDBG_FCB1 dd  ?		; ...	     FCB #1
;LOADDBG_FCB2 dd  ?		; ...		 #2
;LOADDBG_SSSP dd  ?		; SS:SP of loaded program (filled in by DOS)
;LOADDBG_CSIP dd  ?		; CS:IP ...

	public LoadDbg
LoadDbg LOADDBG_STR <>

	public File,Tail
File db 128 dup (?)		; File we're to execute (e.g. c:\windows\win.com)
Tail db 128 dup (?)		; Command tail (length byte, ' options', 0dh)

	public TerminateVec,TargetPSP,OurSeg,OurPSP,LowSeg,OurParentPSP,EntryStack
TerminateVec VECTOR <>	; Our terminate vector
TargetPSP dw	?		; PSP of target program
OurSeg	dw		?		; High segment
OurPSP	dw		?		; High PSP
LowSeg	dw		?		; Low segment - owned by target program
OurParentPSP dw	?		; Our parent PSP
EntryStack VECTOR <>	; Stack on entry

__HIDATA ends

__LOCODE segment
	assume	cs:__HIGROUP,ds:nothing,es:nothing,ss:nothing

	public	LCCSIP
LCCSIP VECTOR <>		; Initial CS:IP

	public	LCStart
LCStart::

;;;; Set PSP to client
	mov		ax,cs		; Prepare to address data segment
	mov		ds,ax		; Address it
	assume	ds:__HIGROUP ; Tell the assembler

	mov		bx,0		; Fill in value

	org		$-2			; Back up to overlay immediate value
	public	LCPSP
LCPSP dw	?			; Low client's PSP

	mov		es,bx		; Address it for program entry
	assume	es:nothing	; Tell the assembler

;;;	DOSCALL	@SETPSP		; Make it the current PSP

; Load stack
	mov		ax,0		; Fill in value

	org		$-2			; Back up to overlay immediate value
	public	LCSS
LCSS dw		?			; Low client's starting SS

	mov		bx,0		; Fill in value

	org		$-2			; Back up to overlay immediate value
	public	LCSP
LCSP dw		?			; Low client's starting SP

	cli					; Nobody move

	mov		ss,ax		; Address segment
	assume	ss:nothing	; Tell the assembler
	mov		sp,bx		; Address offset

	sti					; Interrupts OK

; Push a 0 word
	sub		ax,ax		; Get a zero value
	push	ax

	dec		ax			; FFFF - both FCBs are invalid

; Make DS = CS 'cause that's what DOS does
	mov		ds,LCCSIP.VSEG ; Get code segment
	assume	ds:nothing	; Tell the assembler

; Jump to starting CSIP
	jmp		LCCSIP		; Go do it to it

	public	LCEnd
LCEnd label word

__LOCODE ends

__HICODE segment
	assume	cs:__HIGROUP,ds:nothing,es:nothing,ss:nothing

	public HighProc
HighProc:
; First set up a stack

	cli					; Nobody move
	mov		ax,cs		; Prepare to address stack segment
	lea		dx,__HIGROUP:HighStackEnd ; Address top of stack
	mov		ss,ax		; Address stack
	mov		sp,dx
	assume	ss:nothing	; Tell the assembler
	sti					; Enable interrupts

	mov		ds,ax		; Address __HIGROUP
	assume	ds:__HIGROUP ; Tell the assembler

	mov		es,ax		; Also using ES
	assume	es:__HIGROUP ; Tell the assembler


; Allocate short segment in low memory (hopefully in a hole)

	lea		bx,LCEnd[ 16-1 ] ; Number of bytes rounded up to next para
	mov		cl,4-0		; Convert bytes to paras
	shr		bx,cl		; Get paras needed
	DOSCALL	@GETMEM		; AX = segment
	jnc		short @F	; Jump if OK
	
	jmp		HighProc_Exit ; Failed (!!!)

@@:
	mov		LowSeg,ax	; Save low segment

; 5. Use 4B01 to load target program
	lea		dx,File		; DS:DX ==> path of file to execute
	lea		bx,LoadDbg	; ES:BX ==> Parameter block
	mov		ax,4B01h	; Load for execution, don't execute
	DOSCALL				; CF=1 if failed
	jnc		short @F	; Jump if OK

	mov		ax,4cffh	; Return exit code -1
	DOSCALL				; Terminate program

@@:
; *** PSP is now set to the client program ***

; 6. Set the PSP terminate vector for the target program to ours (previously
;    that of the current PSP).
	DOSCALL	@GETPS0		; BX = target program's PSP
	mov		TargetPSP,bx ; Save for later

	mov		es,bx		; Address it
	assume	es:nothing	; Tell the assembler

	mov		bx,TerminateVec.VSEG ; Get segment
	mov		TermPtr.VSEG,bx ; Set it
	mov		bx,TerminateVec.VOFF ; Get offset
	mov		TermPtr.VOFF,bx ; Set it
	mov		bx,OurParentPSP ; Get our parent's PSP
	mov		CtrlPtr,bx	; Set it

; 6c. Copy LCEnd bytes there
	mov		es,LowSeg	; Address low segment
	assume	es:nothing	; Tell the assembler

	lea		bx,LCEnd[ 2-1 ] ; Number of bytes rounded up to next word
	shr		bx,1		; Number of words to move
	mov		cx,bx		; Set up for move

	sub		si,si		; Start of source
	mov		di,si		; Destination

rep movsw				; Move CX words from DS:SI (high) to ES:DI (low)

	mov		bx,OurPSP	; Get our PSP
	DOSCALL	@SETPSP		; Make it current

;*** Current PSP is now HighGroup ***

; 7. Set our PSP terminate vector to LCStart
; Also link the target PSP in the chain as our parent, so we have:
; COMMAND.COM owns
; WIN.COM owns
; us
	mov		es,OurPSP	; Address our PSP
	assume	es:nothing	; Tell the assembler

	mov		ax,TargetPSP ; Get target PSP
	mov		CtrlPtr,ax	; Put it in the chain
	lea		bx,__HIGROUP:LCStart ; Get offset
	mov		TermPtr.VOFF,bx ; Set it
	mov		bx,LowSeg	; Get segment
	mov		TermPtr.VSEG,bx ; Set it

; Make LCStart owned by the target program
;;;	mov		bx,LowSeg	; Get segment
	dec		bx			; Back off to MAC segment
	mov		es,bx		; Address it
	assume	es:nothing	; Tell the assembler

;;;	mov		ax,TargetPSP ; Get target PSP
	mov		MacPtr.MAC_OWNR,ax ; Make it the proud owner

; Now set up needed values in low segment
	mov		es,LowSeg	; Address low segment
	assume	es:nothing	; Tell the assembler

	assume	ds:__HIGROUP,es:nothing ; Get from high segment
	mov		bx,(VECTOR ptr LoadDbg.LOADDBG_SSSP).VSEG ; Get segment
	assume	ds:nothing,es:__HIGROUP ; Put in low
	mov		LCSS,bx		; Set it
	assume	ds:__HIGROUP,es:nothing ; Get from high segment
	mov		bx,(VECTOR ptr LoadDbg.LOADDBG_SSSP).VOFF ; Get offset
	assume	ds:nothing,es:__HIGROUP ; Put in low
	mov		LCSP,bx		; Set it

	assume	ds:__HIGROUP,es:nothing ; Get from high segment
	mov		bx,TargetPSP ; Get target PSP
	assume	ds:nothing,es:__HIGROUP ; Put in low
	mov		LCPSP,bx	; Set immediate register move

	assume	ds:__HIGROUP,es:nothing ; Get from high segment
	mov		bx,(VECTOR ptr LoadDbg.LOADDBG_CSIP).VSEG ; Get segment
	assume	ds:nothing,es:__HIGROUP ; Put in low
	mov		LCCSIP.VSEG,bx ; Set it
	assume	ds:__HIGROUP,es:nothing ; Get from high segment
	mov		bx,(VECTOR ptr LoadDbg.LOADDBG_CSIP).VOFF ; Get offset
	assume	ds:nothing,es:__HIGROUP ; Put in low
	mov		LCCSIP.VOFF,bx ; Set it

	assume	ds:__HIGROUP,es:nothing ; Back to reality

; Finally, set up target PSP's stack pointer to its initial SS:SP
; We can't do this directly.  We need to load the initial SS:SP
; then make a stack-switching DOS call.
	mov		bx,TargetPSP ; PSP to make active
	DOSCALL @SETPSP		; Make it active

	mov		bx,(VECTOR ptr LoadDbg.LOADDBG_SSSP).VSEG ; Get segment
	mov		ax,(VECTOR ptr LoadDbg.LOADDBG_SSSP).VOFF ; Get offset

	cli					; Nobody move
	mov		ss,bx		; Set up stack segment:offset
	mov		sp,ax
	sti					; Enable interrupts

	DOSCALL @DRESET		; Disk reset - should make it down to DOS

	mov		bx,OurPSP	; PSP to make active so we can terminate
	DOSCALL	@SETPSP		; Make it active

	cli					; Nobody move
	mov		ax,cs		; Prepare to address stack segment
	lea		dx,__HIGROUP:HighStackEnd ; Address top of stack
	mov		ss,ax		; Address stack
	mov		sp,dx
	assume	ss:nothing	; Tell the assembler
	sti					; Enable interrupts

;;;	mov		es,TargetPSP ; Address target
;;;	assume	es:nothing	; Tell the assembler
;;;
;;;	mov		bx,(VECTOR ptr LoadDbg.LOADDBG_SSSP).VSEG ; Get segment
;;;	mov		StackPtr.VSEG,bx ; Set it
;;;	mov		bx,(VECTOR ptr LoadDbg.LOADDBG_SSSP).VOFF ; Get offset
;;;	mov		StackPtr.VOFF,bx

; 8 <defunct>

; 9. Terminate via 4C00.
HighProc_Exit:
	mov		ax,4c00h	; Terminate
	DOSCALL				; Call DOS

	assume	cs:nothing,ds:nothing,es:nothing,ss:nothing

__HICODE ends


; End group-relative fixup bitching section



.data

extern _psp:word		; Current PSP segment

	public HighSeg,HighGroup,CurPSPTerm,ParentPSP
HighSeg dw	?			; PSP segment at high end of low DOS
HighGroup dw ?			; High code segment (PSP + 10h)
CurPSPTerm VECTOR <>	; Current PSP's terminate address
ParentPSP dw ?			; Parent PSP of caller (WINLNCH.EXE from WINMAXIM.EXE)

	public Parent23,Parent24
Parent23 VECTOR <>		; Parent's int 23 (Ctrl-C)
Parent24 VECTOR <>		; Parent's int 24 (Critical error handler)


.code

extern _exit:proc

MyExecv PROC Cmd:dword, CmdTail:dword

	push	ds			; Save
	push	si
	push	di

	mov		ax,seg __HIGROUP ; Get data segment
	mov		es,ax	; Address it
	assume	es:__HIGROUP ; Tell the assembler

; Copy actual data passed in, as it will soon be evaporated

	lds		si,Cmd		; Address command
	assume	ds:nothing	; Tell the assembler

	lea		di,__HIGROUP:File ; Address our copy
	mov		cx,(size File) - 1 ; Maximum bytes
@@:
	lodsb				; Get a byte
	stosb				; Store and increment pointer

	or		al,al		; Izit the end?
	loopnz	@B			; Go around again if not

; Make sure it's terminated in case we had to truncate
	sub		al,al		; Null character
	stosb				; Terminate it

	lds		si,CmdTail	; Address command tail
	assume	ds:nothing	; Tell the assembler

	lea		di,__HIGROUP:Tail ; Address our copy

	lodsb				; Get length byte
	stosb				; Save it

	cbw					; AX = length
	inc		ax			; Include trailing CR

	mov		cx,ax		; Set up for rep
rep movsb				; Copy CX bytes from DS:SI to ES:DI

	mov		ax,seg DGROUP ; Get data segment
	mov		ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler

; Here's what we need to do:
; 1. Allocate a chunk of memory at the high end of low DOS
; 2. Create a PSP there, with the terminate address set to the current PSP's
; 3. Copy ourselves up there
; 4. Transfer control by:
;  a Setting the current PSP's terminate address to our offset in the new PSP
;  b Call the _exit function to terminate
; 5. Use 4B01 to load target program
; 6. Set the PSP terminate vector for the target program to ours (previously
;    that of the current PSP).
; 7. Set our PSP terminate vector to the starting address of the target
; 8. Terminate via 4C00.
; 

; 1. Allocate a chunk of memory at the high end of low DOS
	mov		bx,-1		; An impossible allocation request
	DOSCALL	@GETMEM		; Returns with BX = maximum
	lea		dx,__HIGROUP:EndHigh[ 16 - 1 ] ; Address end of our segment
	mov		cl,4-0		; Convert bytes to paras
	shr		dx,cl		; DX = paras needed
	add		dx,10h + 1	; Add PSP and MAC entry
	sub		bx,dx		; BX = size to allocate
	jnc		short @F	; Jump if no underflow

	jmp		MyExecv_exit ; Not enough space

@@:
	push	dx			; Save size to allocate at high end
	DOSCALL @GETMEM		; AX = segment
	pop		bx			; Restore size
	jnc		short @F 	; Jump if allocated OK

	jmp		MyExecv_exit ; Failed

@@:
	mov		es,ax		; Save for RELMEM
	assume	es:nothing	; Tell the assembler

	dec		bx			; Subtract MAC entry from allocation request
	DOSCALL @GETMEM		; AX = segment of actual high segment
	cmc					; CF=1 if OK
	sbb		bx,bx		; BX=0 if error, FFFF if OK
	and		ax,bx		; AX=0 if error, else segment
	mov		HighSeg,ax	; Save it
	add		ax,10h		; Get high code segment (meaningless if allocate failed)
	mov		HighGroup,ax ; Save it

	DOSCALL	@RELMEM		; Release ES, creating a big hole

	mov		dx,HighSeg	; Get high segment
	or		dx,dx		; Did we succeed?
	jnz		short @F	; Jump if so

	jmp		MyExecv_exit ; Error

@@:
; 2. Create a PSP there, with the terminate address and parent PSP values
;    set to the current PSP's
; The caller's CS is expected to be the same as the PSP.
; To work around this, we'll build a CD 21 CB (INT 21; RETF) and
; simulate a far call to it.

;;; DOSCALL	@BLDPSP		; Create a PSP at DX:0
	push	cs			; Return segment
	lea		bx,BLDPSP_RETURN ; Return offset
	push	bx			; Ready to return from far call

; We could just blast away at 80h, but no need to destroy the
; command line although we don't really need it any more.
	mov		es,_psp		; Address PSP
	assume	es:nothing	; Tell the assembler

	push	es			; Segment to jump to
	mov		bx,100h-4	; Address 4 bytes near end of PSP
	push	bx			; Offset to jump to

; Now construct the call
	mov		ah,@BLDPSP	; Set up for DOS function
	mov		byte ptr es:[bx+0],@OPCOD_INT ; CDh
	mov		byte ptr es:[bx+1],21h ; 21h
	mov		byte ptr es:[bx+2],@OPCOD_RETF ; CBh

; Go to it...
	retf				; Go to PSP:FC

	public	BLDPSP_RETURN
BLDPSP_RETURN::

	mov		es,_psp		; Address our PSP
	assume	es:nothing	; Tell the assembler

	mov		dx,TermPtr.VSEG ; Get segment
	mov		ax,TermPtr.VOFF ; Get offset
	mov		bx,CtrlPtr	; Get parent

	mov		ParentPSP,bx ; Save for later

	mov		CurPSPTerm.VSEG,dx ; Save locally
	mov		CurPSPTerm.VOFF,ax

	mov		es,HighSeg	; Address new PSP
	assume	es:nothing	; Tell the assembler

	mov		TermPtr.VSEG,dx ; Set segment and offset
	mov		TermPtr.VOFF,ax

	mov		CtrlPtr,bx	; Save parent

; Duplicate first 5 file handles into new PSP (stdin, stdout, stderr, aux, prn)
	mov		es,_psp		; Address our PSP
	assume	es:nothing	; Tell the assembler

	lds		si,FileTabPtr ; Address file table pointer
	assume	ds:nothing,ss:DGROUP ; Tell the assembler

	mov		es,HighSeg	; Address new PSP
	assume	es:nothing	; Tell the assembler

	les		di,FileTabPtr ; Address destination file table pointer
	assume	es:nothing	; Tell the assembler

	mov		cx,5		; How many to copy
rep movsb				; Copy CX bytes from DS:SI => ES:DI

	mov		ax,seg DGROUP ; Prepare to address data seg
	mov		ds,ax		; Address it
	assume	ds:DGROUP,ss:nothing ; Tell the assembler

; Patch some values in new PSP, specifically Int 23 and Int 24h
; Use our parent's values (usually command.com).
	mov		es,ParentPSP ; Address parent PSP (usually command.com)
	assume	es:nothing	; Tell the assembler

	mov		dx,CtrlCPtr.VSEG ; Get segment
	mov		ax,CtrlCPtr.VOFF ; Get offset
	mov		Parent23.VSEG,dx ; Save
	mov		Parent23.VOFF,ax

	mov		dx,CErrPtr.VSEG ; Get critical error handler
	mov		ax,CErrPtr.VOFF
	mov		Parent24.VSEG,dx ; Save it
	mov		Parent24.VOFF,ax

	mov		es,HighSeg	; Address new PSP
	assume	es:nothing	; Tell the assembler

;;;	mov		dx,Parent24.VSEG ; Get critical error handler
;;;	mov		ax,Parent24.VOFF
	mov		CErrPtr.VSEG,dx ; Set in new PSP
	mov		CErrPtr.VOFF,ax

	mov		dx,Parent23.VSEG ; Get Ctrl-C handler
	mov		ax,Parent23.VOFF
	mov		CtrlCPtr.VSEG,dx ; Set in new PSP
	mov		CtrlCPtr.VOFF,ax

	mov		dx,TermPtr.VSEG ; Get terminate segment (again)
	mov		ax,TermPtr.VOFF ; ... address ...

; Save values in segment we're about to move high

	mov		bx,seg __HIGROUP ; Prepare to address segment we're moving high
	mov		es,bx		; Address it
	assume	es:__HIGROUP ; Tell the assembler

	mov		TerminateVec.VSEG,dx ; Save it in high segment
	mov		TerminateVec.VOFF,ax

	mov		bx,HighSeg	; Get high PSP
	mov		OurPSP,bx	; Save in segment we're moving high
	mov		bx,HighGroup ; Get high segment
	mov		OurSeg,bx	; Save in segment we're moving high
	mov		bx,ParentPSP ; Get our parent PSP
	mov		OurParentPSP,bx ; Save in segment we're moving high

; 2a. Set the owner of the new PSP's MAC entry to itself so it doesn't
;     get freed when the current program terminates.
	mov		ax,HighSeg	; Get PSP segment
	dec		ax			; Back off to MAC entry
	mov		es,ax		; Address MAC entry
	assume	es:nothing	; Tell the assembler

	inc		ax			; Address PSP
	mov		MacPtr.MAC_OWNR,ax ; Set owner

; 3. Copy ourselves up there
	mov		ax,HighGroup ; Get code segment
	mov		es,ax		; Address it
	assume	es:__HIGROUP ; Tell the assembler

	lea		dx,EndHigh[ 2-1 ] ; Address end, rounding up to word boundary
	shr		dx,1		; Convert to word count
	mov		cx,dx		; Set up count for block move

	mov		ax,seg __HIGROUP ; Prepare to address group
	mov		ds,ax		; Address it
	assume	ds:__HIGROUP ; Tell the assembler

	sub		si,si		; Start at offset 0
	sub		di,di

rep movsw				; Move CX words from DS:SI to ES:DI

	mov		ax,seg DGROUP ; Prepare to address data segment
	mov		ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler

; Set up LoadDbg structure.  Get parent's environment (keep looking till
; we find one that's not empty)

	mov		ax,ParentPSP ; Get parent PSP
@@:
	mov		es,ax		; Address parent PSP
	assume	es:nothing	; Tell the assembler

	mov		bx,EnvPtr	; Get environment
	or		bx,bx		; Izit valid?
	jnz		short @F	; Jump if so

	mov		bx,CtrlPtr	; Get parent PSP
	cmp		bx,ax		; Izit the same (means we're at the top)?
	mov		ax,bx		; Prepare to address previous entry in chain
	jne		short @B	; Go around again if not the top-level PSP

	sub		bx,bx		; Zero it, let WIN.COM take its chances with DOS
@@:
	mov		es,HighGroup ; Address __HIGROUP in high memory
	assume	es:__HIGROUP ; Tell the assembler

	mov		LoadDbg.LOADDBG_ENV,bx ; Environment to use
	mov		(VECTOR ptr LoadDbg.LOADDBG_CMD).VSEG,es ; Segment of command line
	mov		(VECTOR ptr LoadDbg.LOADDBG_CMD).VOFF,offset __HIGROUP:Tail

	mov		ax,HighSeg	; High PSP address
	mov		(VECTOR ptr LoadDbg.LOADDBG_FCB1).VSEG,ax ; Segment of FCB1
	mov		(VECTOR ptr LoadDbg.LOADDBG_FCB1).VOFF,5Ch
	mov		(VECTOR ptr LoadDbg.LOADDBG_FCB2).VSEG,ax ; Segment of FCB2
	mov		(VECTOR ptr LoadDbg.LOADDBG_FCB2).VOFF,6Ch

; 4. Transfer control by:
;  a Setting the current PSP's terminate address to our offset in the new PSP
	mov		es,_psp		; Address our PSP
	assume	es:nothing	; Tell the assembler

; N.B. This will cause the stack pointer to get restored from the parent's
; PSP, but that's OK as we'll immediately switch stacks.

;;;	mov		ax,HighSeg	; Get high PSP
	mov		CtrlPtr,ax	; Set parent PSP segment

	lea		dx,__HIGROUP:HighProc ; Offset to gain control at
	mov		ax,HighGroup ; Get start of code/data seg
	mov		TermPtr.VOFF,dx ; Save in current PSP
	mov		TermPtr.VSEG,ax ; Save segment at high end of low DOS

;  b Call the _exit function to terminate
	mov		ax,0		; Exit code
	push	ax
	call	_exit		; No return
	add		sp,2		; Clean up cdecl stack

; N.B. We should never end up here...

MyExecv_exit:
	pop		di
	pop		si
	pop		ds			; Restore
	assume	ds:nothing	; Tell the assembler

	ret					; Return

MyExecv ENDP

end						; Module MyExecv.asm


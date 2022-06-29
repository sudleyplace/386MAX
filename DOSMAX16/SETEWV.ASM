;' $Header:   P:/PVCS/MAX/DOSMAX16/SETEWV.ASV   1.0   25 Oct 1995 13:01:06   BOB  $
;SETEWV.ASM --> SETEWV.EXE  Set Expected Windows Version

.386
	include MASM.INC
	include ASCII.INC
	include 386.INC
	include PTR.INC
	include WINSTR.INC

DGROUP	group	_DATA

	extrn	GetCurrentTask:far

;..............................................
_DATA	segment use16 dword public 'DATA' ; Start _DATA segment
	assume	ds:DGROUP

	public	pModName,wVersion
pModName dd	?		; Pointer to module name
wVersion dw	?		; Windows verion # to set

	public	CON16
CON16	dw	16		; Constant word 16

	public	NUMBERS_LO
NUMBERS_LO db	'0123456789abcdef' ; Conversion table for BASE2BIN

_DATA	ends			; End _DATA segment

;..............................................................
_TEXT	segment use16 byte public 'CODE' ; Start _TEXT segment
	assume	cs:_TEXT

STK_STR struc

	dw	?		; 00:  Caller's BP
	dw	?		; 02:  ...	IP
nCmdShow dw	?		; 04:  nCmdShow
lpCmdLine dd	?		; 06:  lpCmdLine
hPrevInstance dw ?		; 0A:  hPrevInstance
hInstance dw	?		; 0C:  hInstance

STK_STR ends

	NPPROC	WINMAIN -- Main Windows Procedure
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Entry point from Windows.

On entry:

SS:SP	 ==>	 STK_STR (after we PUSH BP)

|

	push	bp	       ; Save BP so can use to access params
	mov	bp,sp	       ; BP will now point to top-of-stack

	cmp	[bp].lpCmdLine,0 ; Is the command line valid?
	je	short WINMAIN_ERR ; Jump if not

; Parse the command line for the module name and version #

	les	di,[bp].lpCmdLine ; ES:DI ==> command line
	assume	es:nothing	; Tell the assembler about it

	call	SkipWhite	; Skip over white space at ES:DI

	cmp	es:[di].LO,0	; Izit end of the line?
	je	short WINMAIN_ERR ; Jump if so (that's an error)

	mov	pModName.VOFF,di ; Save as pointer to module name
	mov	pModName.VSEG,es ; ...

	call	SkipBlack	; Skip over non-white space at ES:DI

	cmp	es:[di].LO,0	; Izit end of the line?
	je	short WINMAIN_ERR ; Jump if so (that's an error)

	mov	es:[di].LO,0	; Ensure properly terminated
	inc	di		; Skip over it

	call	SkipWhite	; Skip over white space at ES:DI

	cmp	es:[di].LO,0	; Izit end of the line?
	je	short WINMAIN_ERR ; Jump if so (that's an error)

	mov	cx,16		; Use base 16 to convert
	call	BASE2BIN	; Convert the number at ES:DI to binary in AX

	mov	wVersion,ax	; Save for later use

	cmp	ax,0300h	; Too small?
	jb	short WINMAIN_ERR ; Jump if so (that's an error)

	call	GetCurrentTask	; Return AX = handle of current task
				; ...	 DX = handle of 1st task in chain
WINMAIN1:
	and	dx,dx		; Izit valid?
	jz	short WINMAIN_ERR ; Jump if not

	push	pModName	; Pass a ptr to the module name
	push	dx		; ...  segment of new task name
	push	offset TDB_MODNAME ; ...offset ...
	push	size TDB_MODNAME ; ... length ...
	call	STRCMPNI	; Compare the strings, case-insensitive, length
	jz	short WINMAIN2	; Jump if it's a match

	mov	es,dx		; Address the TDB
	assume	es:nothing	; Tell the assembler about it

	mov	dx,es:[0].TDB_NEXT ; Get selector of next task

	jmp	short WINMAIN1	; Go around again

WINMAIN2:
	mov	es,dx		; Address it
	assume	es:nothing	; Tell the assembler about it

	mov	es,es:[0].TDB_MOD ; Get module handle
	assume	es:nothing	; Tell the assembler about it

; Change the version # to the requested value

	mov	ax,wVersion	; Get the requested version #
	mov	es:[0].MOD_EXPWV,ax ; Set it
WINMAIN_ERR:
	xor	ax,ax		; Return value

	mov	sp,bp		; Strip the stack
	pop	bp		; Restore

	ret	10		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WINMAIN endp			; End WINMAIN procedure
	NPPROC	SkipWhite -- Skip Over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space

On entry:

ES:DI	==>	text

On exit:

ES:DI	==>	(updated)

|

	REGSAVE <ax>		; Save register
@@:
	mov	al,es:[di]	; Get the next char
	inc	di		; Skip over it

	cmp	al,' '          ; Wuzit white space?
	je	short @B	; Jump if so

	cmp	al,TAB		; Wuzit the other white meat?
	je	short @B	; Jump if so

	dec	di		; Back off to first non-white space char

	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SkipWhite endp			; End SkipWhite procedure
	NPPROC	SkipBlack -- Skip Over Non-White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over non-white space

On entry:

ES:DI	==>	text

On exit:

ES:DI	==>	(updated)

|

	REGSAVE <ax>		; Save register
@@:
	mov	al,es:[di]	; Get the next char
	inc	di		; Skip over it

	cmp	al,0		; Wuzit terminator?
	je	short @F	; Jump if so

	cmp	al,' '          ; Wuzit white space?
	je	short @F	; Jump if so

	cmp	al,TAB		; Wuzit the other white meat?
	jne	short @B	; Jump if not
@@:
	dec	di		; Back off to first white space char

	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SkipBlack endp			; End SkipBlack procedure
	NPPROC	LOWERCASE -- Convert AL to Lowercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	cmp	al,40h		; Test for conversion of alpha to lower case
	jb	short LOWERCASE_EXIT ; Not this time

	or	al,20h		; Convert alpha to lower case
LOWERCASE_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	NPPROC	BASE2BIN -- Convert From Specified Base to Binary
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BASE2BIN -- Convert the number at ES:DI in base CX to binary.
The converted # is returned in AX.

On entry:

CX	 =	 number base
DS:SI	 ==>	 input save area

On exit:

CF	 =	 1 if overflow
	 =	 0 if OK
AX	 =	 converted #

|

	REGSAVE <bx,dx,si>	; Save registers

	call	SkipWhite	; Skip over more white space

	mov	al,es:[di]	; Get first digit
	xor	bx,bx		; Zero accumulator
BASE2BIN_LOOP:
	call	LOWERCASE	; Convert AL to lowercase

	push	cx		; Save number base (and table length)

	xor	si,si		; Initialize index into conversion table
@@:
	cmp	al,NUMBERS_LO[si] ; Duzit match?
	je	short @F	; Jump if so (note ZF=1)

	inc	si		; Skip to next char (note ZF=0)
	loop	@B		; Jump if more chars
@@:
	pop	cx		; Restore number base
	jnz	short BASE2BIN_DONE ; Jump if not one of ours

	mov	ax,bx		; Copy old to multiply by base

	mul	cx		; Shift over accumulated #
	jc	short BASE2BIN_EXIT ; Jump if not within range (note CF=1)

	mov	bx,ax		; Copy back
	add	bx,si		; Add in new #
	jc	short BASE2BIN_EXIT ; Jump if out of range (note CF=1)

	mov	al,es:[di]	; Get next digit
	inc	di		; Skip over it

	jmp	BASE2BIN_LOOP	; Go around again

BASE2BIN_DONE:
	dec	di		; Back off to previous character
	mov	ax,bx		; Place result in accumulator

	clc			; Indicate all went well
BASE2BIN_EXIT:
	REGREST <si,dx,bx>	; Restore registers

	ret			; Return to caller with number in AX

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BASE2BIN endp			; End BASE2BIN procedure
	NPPROC	STRCMPNI -- String Compare Fixed Length Case Insensitive
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

String compare, fixed length, case insensitive

On entry:

SS:SP	==>	STRCMPNI_STR

On exit:

ZF	=	1 if the strings compare
	=	0 otherwise

|

STRCMPNI_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
STRCMPNI_LEN dw ?		; Length
STRCMPNI_SRC dd ?		; Source string
STRCMPNI_DST dd ?		; Destin string

STRCMPNI_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,cx,si,di,ds,es> ; Save registers

	lds	si,[bp].STRCMPNI_SRC ; DS:SI ==> source string
	assume	ds:nothing	; Tell the assembler about it

	les	di,[bp].STRCMPNI_DST ; ES:DI ==> source string
	assume	es:nothing	; Tell the assembler about it

	mov	cx,[bp].STRCMPNI_LEN ; CX = length
STRCMPNI_NEXT:
	cmp	al,al		; Ensure ZF=1 in case CX=0
   repe cmps	ds:[si].LO,es:[di].LO ; Are they the same?
	je	short STRCMPNI_EXIT ; Jump if so (note ZF=1)

; Check for case-sensitivity

	mov	al,ds:[si-1]	; Get the last source char
	call	LOWERCASE	; Convert AL to lowercase

	mov	ah,es:[di-1]	; ...	       destin ...
	xchg	al,ah		; Swap 'em
	call	LOWERCASE	; Convert AL to lowercase

	cmp	al,ah		; Izit the same?
	je	short STRCMPNI_NEXT ; Jump if so
				; Fall through with ZF=0
STRCMPNI_EXIT:
	REGREST <es,ds,di,si,cx,ax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	pop	bp		; Restore

	ret	4+4+2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STRCMPNI endp			; End STRCMPNI procedure

_TEXT	ends			; End _TEXT segment

	END	WINMAIN 	; End SETEWV Module

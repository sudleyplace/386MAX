;' $Header$
	title	DPMIMEM -- Display DPMI Memory
	page	58,122
	name	DPMIMEM
	include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1994-2002 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'

Program derived from:  None.

Original code by:  Bob Smith, MONTH, 1994.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include DOSCALL.INC
	include ASCII.INC
	include PTR.INC
	include DPMI.INC
.list

PGROUP	group	STACK,CODE,DATA,DTAIL


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	segment use16 byte stack 'prog' ; Start STACK segment
STACK	ends			; End STACK segment


DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:PGROUP

	public	VM2PM_VEC
VM2PM_VEC dd	?		; DPMI PM entry point

GETMEMI_STR struc

GETMEMI_TOTUSEPMSRV dd ?	; 00:  Total used physical memory per server
GETMEMI_TOTUSEVMSRV dd ?	; 04:  Total used virtual  memory per server
GETMEMI_TOTAVLVMSRV dd ?	; 08:  Total avl  virtual  memory per server
GETMEMI_TOTUSEVMVM  dd ?	; 0C:  Total used virtual  memory per VM
GETMEMI_TOTAVLVMVM  dd ?	; 10:  Total avl  virtual  memory per VM
GETMEMI_TOTUSEVMCLI dd ?	; 14:  Total used virtual  memory per client
GETMEMI_TOTAVLVMCLI dd ?	; 18:  Total avl  virtual  memory per client
GETMEMI_TOTLOCKMCLI dd ?	; 1C:  Total locked	   memory per client
GETMEMI_MAXLOCKMCLI dd ?	; 20:  Max   locked	   memory per client
GETMEMI_HILINADDCLI dd ?	; 24:  Highest linear address	  per client
GETMEMI_MAXAVLMEM   dd ?	; 28:  Max   avl	   memory
GETMEMI_MINALLUNIT  dd ?	; 2C:  Min   allocation unit
GETMEMI_ALIGNUNIT   dd ?	; 30:  Allocation alignment unit
	db	(80h-34h) dup (?) ; 34-7F:  Reserved

GETMEMI_STR ends

	public	GETMEMI
GETMEMI GETMEMI_STR <>		; Get memory information struc

	public	PGETMEMI
PGETMEMI dw	offset PGROUP:TXT_GETMEMI_TOTUSEPMSRV
	dw	offset PGROUP:TXT_GETMEMI_TOTUSEVMSRV
	dw	offset PGROUP:TXT_GETMEMI_TOTAVLVMSRV
	dw	offset PGROUP:TXT_GETMEMI_TOTUSEVMVM
	dw	offset PGROUP:TXT_GETMEMI_TOTAVLVMVM
	dw	offset PGROUP:TXT_GETMEMI_TOTUSEVMCLI
	dw	offset PGROUP:TXT_GETMEMI_TOTAVLVMCLI
	dw	offset PGROUP:TXT_GETMEMI_TOTLOCKMCLI
	dw	offset PGROUP:TXT_GETMEMI_MAXLOCKMCLI
	dw	offset PGROUP:TXT_GETMEMI_HILINADDCLI
	dw	offset PGROUP:TXT_GETMEMI_MAXAVLMEM
	dw	offset PGROUP:TXT_GETMEMI_MINALLUNIT
	dw	offset PGROUP:TXT_GETMEMI_ALIGNUNIT
GETMEMI_LEN equ ($-PGETMEMI)/(type PGETMEMI) ; # entries

TXT_GETMEMI_TOTUSEPMSRV db 'Total used physical memory per server = ',EOS
TXT_GETMEMI_TOTUSEVMSRV db 'Total used virtual  memory per server = ',EOS
TXT_GETMEMI_TOTAVLVMSRV db 'Total avl  virtual  memory per server = ',EOS
TXT_GETMEMI_TOTUSEVMVM	db 'Total used virtual  memory per VM     = ',EOS
TXT_GETMEMI_TOTAVLVMVM	db 'Total avl  virtual  memory per VM     = ',EOS
TXT_GETMEMI_TOTUSEVMCLI db 'Total used virtual  memory per client = ',EOS
TXT_GETMEMI_TOTAVLVMCLI db 'Total avl  virtual  memory per client = ',EOS
TXT_GETMEMI_TOTLOCKMCLI db 'Total locked        memory per client = ',EOS
TXT_GETMEMI_MAXLOCKMCLI db 'Max   locked        memory per client = ',EOS
TXT_GETMEMI_HILINADDCLI db 'Highest linear address     per client = ',EOS
TXT_GETMEMI_MAXAVLMEM	db 'Max   avl           memory            = ',EOS
TXT_GETMEMI_MINALLUNIT	db 'Min   allocation unit                 = ',EOS
TXT_GETMEMI_ALIGNUNIT	db 'Allocation alignment unit             = ',EOS

	public	BUFFER
BUFFER	db	'________',CR,LF,EOS

	public	NUMBERS_HI
NUMBERS_HI db	'0123456789ABCDEF' ; Conversion table for BIN2BASE

	public	ERR_NODPMI,ERR_EPM
ERR_NODPMI db	'No DPMI support available.',CR,LF,EOS
ERR_EPM db	'DPMI Enter Protected Mode call failed',CR,LF,EOS

	public	ERRCODE
ERRCODE db	0		; Return code

DATA	ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	segment use16 dword public 'data' ; Start DTAIL segment
	assume	ds:PGROUP

	public	LCLSTK,LCLSTKZ
LCLSTK	label	word		; Local stack
	org	LCLSTK[100h*(type LCLSTK)] ; The stack
LCLSTKZ label	word		; Top of stack

	public	ZTAIL
ZTAIL	label	byte

DTAIL	ends			; End DTAIL segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP
.xlist
	include PSP.INC 	; Define & skip over PSP area for .COM program
.list
	NPPROC	DPMIMEM -- DPMI Memory Display
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	lea	sp,LCLSTKZ	; Switch to local stack

	mov	ax,1687h	; DPMI VM to PM function
	int	2Fh		; Request DOS service
	assume	es:nothing	; Tell the assembler about it
				; AX = 0 if successful
				; BX = flags:  Bit 0:  1 if 32-bit progs OK
				; CL = processor type
				; DH = major version #
				; DL = minor ...
				; SI = # paras needed for DPMI host data area
				; ES:DI ==> enter PM entry point
	and	ax,ax		; Izit successful?
	jz	short @F	; Skip error if so

	DOSCALL @STROUT,ERR_NODPMI ; Tell 'em there's no DPMI

	jmp	DPMIMEM_ERR	; Join common exit code


@@:
	mov	VM2PM_VEC.VOFF,di ; Save for later use
	mov	VM2PM_VEC.VSEG,es ; ...

	lea	ax,ZTAIL[16-1]	; Get next available byte
	shr	ax,4-0		; Convert from bytes to paras
	mov	bx,ds		; Copy data segment
	add	ax,bx		; Add to get next available segment
	mov	es,ax		; Address it for the HPDA
	assume	es:nothing	; Tell the assembler about it

	mov	ax,1		; Enter as 32-bit client
	call	VM2PM_VEC	; Request entry to PM
	assume	ds:PGROUP,es:nothing ; Tell the assembler about it
				; If carry clear
				; CS = USE16 selector with base of RM CS
				; DS = Selector of real mode DS w/ 64K limit
				; SS = Selector of real mode SS w/ 64K limit
				; ES = Selector to PSP with 256 byte limit
				; FS = GS = 0 if 386 or 486
				; All other registers preserved
	jnc	short @F	; Skip error if it worked

	DOSCALL @STROUT,ERR_EPM ; Tell 'em the DPMI EPM failed

	jmp	DPMIMEM_ERR	; Join common exit code


@@:
	mov	ax,ds		; Get data selector
	mov	es,ax		; Address it
	assume	es:PGROUP	; Tell the assembler about it

; Check on DPMI memory information

	lea	edi,GETMEMI	; ES:EDI ==> Get Memory Information struc
	DPMICALL @DPMI_GETMEMI	; Request DPMI service
;;;;;;; jc	short ???	; Ignore error return

; Display the data

	mov	cx,GETMEMI_LEN	; # entries to display
	xor	ebx,ebx 	; Initialize index
DPMIMEM_NEXT:
	movzx	edx,PGETMEMI[ebx*(type PGETMEMI)] ; Get offset in PGROUP of text
	DOSCALL @STROUT 	; Display the text line

	mov	eax,GETMEMI.EDD[ebx*(type EDD)] ; Get the value
	lea	di,BUFFER	; ES:DI ==> buffer
	call	DD2HEX		; Convert EAX from binary to hex at ES:DI

	xor	edx,edx 	; Clear high word
	DOSCALL @STROUT,BUFFER	; Display the value

	inc	ebx		; Skip to next entry

	loop	DPMIMEM_NEXT	; Jump if more entries to display
DPMIMEM_ERR:
	mov	al,ERRCODE	; Get return code
	DOSCALL @EXITRC 	; Return to DOS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIMEM endp			; End DPMIMEM procedure
	NPPROC	DD2HEX -- Convert EAX to Hex At ES:DI
	assume	ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert EAX to hex at ES:DI

On entry:

EAX	=	value to convert
ES:DI	==>	output save area

On exit:

ES:DI	==>	byte to right of converted number

|


	push	cx		; Save for a moment
	mov	cx,8		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	cx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	endp			; End DD2HEX procedure
	NPPROC	BIN2HEX_SUB
	assume	ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL/AX/EAX to hex at ES:DI

On entry:

AL/AX/EAX=	 value to convert
CX	=	# hex digits to convert
ES:DI	==>	output save area

On exit:

ES:DI	==>	byte to right of converted number

|


	REGSAVE <ax,bx,edx>	; Save registers

	pushf			; Save flags
	std			; Store backwards

	mov	edx,eax 	; Copy to secondary register
	lea	bx,NUMBERS_HI	; XLAT table
	add	di,cx		; Skip to the end+1
	push	di		; Save to return
	dec	di		; Now the last digit
BIN2HEX_MORE:
	mov	al,dl		; Copy to XLAT register
	and	al,0Fh		; Isolate low-order digit
	xlat	NUMBERS_HI	; Convert to ASCII hex
	stos	es:[di].LO	; Save in output area

	shr	edx,4		; Shift next digit down to low-order

	loop	BIN2HEX_MORE	; Jump if more digits to format

	pop	di		; Restore

	popf			; Restore flags

	REGREST <edx,bx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure

CODE	ends			; End CODE segment

	MEND	DPMIMEM 	; End DPMIMEM module

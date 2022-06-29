;' $Header$
	title	XMSBLK -- Allocate An XMS Block
	page	58,122
	name	XMSBLK

COMMENT|		Module Specifications

Copyright:  (C) Copyright 2000-2003 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  para-aligned, public, class 'prog'
	       Stack   segment STACK, byte-aligned, stack,  class 'prog'

Program derived from:  None.

Original code by:  Bob Smith, July, 2000.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include DOSCALL.INC
	include ASCII.INC
	include XMS.INC
	include PTR.INC
.list

PGROUP	group	CODE
DGROUP	group	DATA,STACK
PSPGRP	group	PSP_SEG


PSP_SEG segment use16 para at 0 ; Start PSP_SEG segment
	assume	cs:PSPGRP
.xlist
	include PSP.INC 	; Define PSP area
.list

PSP_SEG ends			; End PSP_SEG segment


; The following segment positions the CODE segment before the DATA segment
; so that we can define DATA segment values before they are used in
; the CODE segment to avoid forward references.

CODE	segment use16 byte public 'code' ; Start CODE segment
CODE	ends			; End CODE segment


DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	OLDXMS_VEC
OLDXMS_VEC dd	?		; Save area for address of XMS driver

	public	MEM_BEG,MEM_END
MEM_BEG dd	?		; Beginning of memory range
MEM_END dd	?		; End of ...

	public	TOTMEM,MAXMEM
TOTMEM	dd	?		; Total amount of memory
MAXMEM	dd	?		; Maximum contiguous block

	public	XMSADDR1,XMSADDR2,XMSADDR3
XMSADDR1 dd	?		; Linear address of XMS handle #1
XMSADDR2 dd	?		; ...			       #2
XMSADDR3 dd	?		; ...			       #3

	public	XMSHNDL1,XMSHNDL2,XMSHNDL3
XMSHNDL1 dw	?		; XMS handle #1
XMSHNDL2 dw	?		; ...	     #2
XMSHNDL3 dw	?		; ...	     #3

	public	PSPSEG
PSPSEG	dw	?		; PSP segment

	public	ERRCODE
ERRCODE db	-1		; Error code return to DOS

	public	XMS_QRYXMB,XMS_GETXMB,XMS_MODXMB
XMS_QRYXMB db	@XMS_QRYXMB	; Function code to query XMS memory
XMS_GETXMB db	@XMS_GETXMB	; ...		   get	 ...
XMS_MODXMB db	@XMS_MODXMB	; ...		   modify ...

	public	MSG_COPY
MSG_COPY db	'XMSBLK   -- Version 1.01 -- An XMS Block Allocator',CR,LF
	db	'   (C) Copyright 2000-2003 Qualitas, Inc. '
	db	' All rights reserved.',CR,LF
	db	'Evaluation copy -- For testing purposes only.',CR,LF
	db	EOS

	public	MSG_MEMERR
MSG_MEMERR db	'様> Invalid Memory range.',CR,LF
	db	EOS

	public	MSG_UNKSW
MSG_UNKSW db	'様> Unknown switch.',CR,LF
	db	EOS

	public	MSG_HELP
MSG_HELP db	CR,LF
	db	'This program allocates XMS memory such that the specified',CR,LF
	db	'memory range is the only XMS memory available.',CR,LF
	db	CR,LF
	db	'Syntax:  XMSBLK xx - yy',CR,LF
	db	CR,LF
	db	'where xx and yy are decimal values with xx >= 1 MB and xx < yy.',CR,LF
	db	CR,LF
	db	'Either argument may be in units of kilobytes if followed by K,',CR,LF
	db	'or in megabytes if followed by M, however both arguments must be',CR,LF
	db	'on a kilobyte boundary.',CR,LF
	db	CR,LF
	db	'All free XMS memory must be contiguous.',CR,LF
	db	CR,LF
	db	'For example, to specify a range of 12 MB to 15 MB, use',CR,LF
	db	CR,LF
	db	'  12M - 15M',CR,LF
	db	CR,LF
	db	'The dash between the numbers is optional.',CR,LF
	db	EOS

	public	NUMBERS_LO
NUMBERS_LO db	'0123456789abcdef' ; Conversion table for BASE2BIN

	public	NUMBERS_HI
NUMBERS_HI db	'0123456789ABCDEF' ; Conversion table for BIND2BASE

	public	MSG_XMSSIZE
MSG_XMSSIZE  db DLE,' XMS largest free size is %,.7lu KB',CR,LF
	     db    '  XMS total free size is   %,.7lu KB',CR,LF,0
;;;_XMSSIZE  db DLE,' XMS largest free size is                '
;;;_XMSSIZE1 db '_ KB',CR,LF
;;;	     db '  XMS total free size is                  '
;;;_XMSSIZE2 db '_ KB'
;;;	db	CR,LF
;;;	db	EOS

	public	MSG_XMSHNDL
MSG_XMSHNDL db	DLE,' Allocated XMS handle #%u = %04X.',CR,LF,0
;;;_XMSHNDL db	DLE,' Allocated XMS handle #'
;;;_XMSHNDL1 db 'n = '
;;;_XMSHNDL2 db '000_',CR,LF
	db	EOS

	public	MSG_XMSREL
MSG_XMSREL db	DLE,' Releasing XMS handle #%u = %04X.',CR,LF,0
;;;_XMSREL db	DLE,' Releasing XMS handle #'
;;;_XMSREL1 db	'n = '
;;;_XMSREL2 db	'000_',CR,LF
	db	EOS

	public	MSG_NONCONTIG
	public	MSG_NONALLOC1, MSG_NONLOCK1, MSG_NONUNLK1
	public	MSG_NONINTER1, MSG_NONMOD1
	public	MSG_NONALLOC2, MSG_NONLOCK2, MSG_NONUNLK2
	public	MSG_NONINTER2, MSG_NONMOD2
	public	MSG_NONALLOC3, MSG_NONLOCK3, MSG_NONUNLK3
	public	MSG_NONINTER3, MSG_NONREL2
MSG_NONCONTIG db '様> All of the free memory must be contiguous.',CR,LF
	db	EOS
MSG_NONALLOC1 db '様> Unable to allocate memory (handle #1).',CR,LF
	db	EOS
MSG_NONLOCK1  db '様> Unable to lock memory (handle #1).',CR,LF
	db	EOS
MSG_NONUNLK1  db '様> Unable to unlock memory (handle #1).',CR,LF
	db	EOS
MSG_NONINTER1 db '様> Start of Memory to be tested is below the start of XMS handle #1.',CR,LF
	db	EOS
MSG_NONMOD1   db '様> Unable to reallocate down memory (handle #1).',CR,LF
	db	EOS
MSG_NONALLOC2 db '様> Unable to allocate memory (handle #2).',CR,LF
	db	EOS
MSG_NONLOCK2  db '様> Unable to lock memory (handle #2).',CR,LF
	db	EOS
MSG_NONUNLK2  db '様> Unable to unlock memory (handle #2).',CR,LF
	db	EOS
MSG_NONINTER2 db '様> Start of Memory to be tested is not at the start of XMS handle #2.',CR,LF
	db	EOS
MSG_NONMOD2   db '様> Unable to reallocate down memory (handle #2).',CR,LF
	db	EOS
MSG_NONALLOC3 db '様> Unable to allocate memory (handle #3).',CR,LF
	db	EOS
MSG_NONLOCK3  db '様> Unable to lock memory (handle #3).',CR,LF
	db	EOS
MSG_NONUNLK3  db '様> Unable to unlock memory (handle #3).',CR,LF
	db	EOS
MSG_NONINTER3 db '様> End of Memory to be tested is not at the start of XMS handle #2.',CR,LF
	db	EOS
MSG_NONREL2   db '様> Unable to release memory (handle $2).',CR,LF
	db	EOS

DATA	ends			; End DATA segment


STACK	segment use16 para stack 'data' ; Start STACK segment
	assume	ds:DGROUP

	dd	400h dup (?)	; Default stack

STACK	ends			; End STACK segment


CODE	segment use16 byte public 'code' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	extrn	PRINTF16:near

	public	DATASEG
DATASEG dw	seg DGROUP	; Segment of DGROUP

	NPPROC	XMSBLK -- Allocate An XMS Block
	assume	ds:nothing,es:PSPGRP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate a specific memory range via XMS.

* Allocate all of extended memory (XMS Handle #1).
* Re-allocate handle #1 down to the start of the Memory-to-be-Tested (MTBT).
* Allocate all of (the remaining) extended memory (XMS Handle #2)
* Re-allocate handle #2 down to the end of the MTBT.
* Allocate all of (the remaining) extended memory (XMS Handle #3).
* Release XMS handle #2.

On entry:

ES	=	PSP segment

|

	mov	ds,DATASEG	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

	mov	PSPSEG,es	; Save segment of PSP

	mov	es,DATASEG	; Address it
	assume	es:DGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_COPY ; Display our copyright

	call	CheckArgs	; Check for command line arguments
	jc	near ptr XMSBLK_EXIT ; Jump if something went wrong

	call	CheckXMS	; Ensure there's an XMS driver present
	jc	near ptr XMSBLK_EXIT ; Jump if something went wrong

; Determine amount of memory and confirm that it's contiguous

	call	QueryMem	; Query amount of extmem
	jc	near ptr XMSBLK_EXIT ; Jump if something went wrong

; * Allocate all of extended memory (XMS Handle #1).

	mov	si,1		; Mark as handle #1
	call	AllocMem	; Allocate memory
				; Return with DX = XMS handle
	jc	near ptr XMSBLK_ERR1A ; Jump if something went wrong

	mov	XMSHNDL1,dx	; Save for later use

; Get base of handle #1 and ensure it's at or below the MTBT

;;;;;;; mov	dx,XMSHNDL1	; Get XMS handle #1
	mov	ah,@XMS_LCKXMB	; Function code to lock extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      DX:BX = linear address
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
	jne	near ptr XMSBLK_ERR1B ; Jump if not

	mov	XMSADDR1.ELO,bx ; Save for later use
	mov	XMSADDR1.EHI,dx ; ...

	mov	dx,XMSHNDL1	; Get XMS handle #1
	mov	ah,@XMS_UNLXMB	; Function code to unlock extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
	jne	near ptr XMSBLK_ERR1C ; Jump if not

	mov	eax,XMSADDR1	; Get linear address of XMS handle #1

	cmp	eax,MEM_BEG	; Izit at or below start of MTBT?
	ja	near ptr XMSBLK_ERR1D ; Jump if not

; * Re-allocate handle #1 down to the start of the Memory-to-be-Tested (MTBT).

;;;;;;; mov	dx,XMSHNDL1	; Get XMS handle #1
	mov	ebx,MEM_BEG	; Get linear address of start of MTBT
	sub	ebx,XMSADDR1	; Less start of XMS handle #1
	call	ModifyMem	; Re-allocate memory downwards
	jc	near ptr XMSBLK_ERR1E ; Jump if something went wrong

; Determine amount of remaining memory and confirm that it's contiguous

	call	QueryMem	; Query amount of extmem
	jc	near ptr XMSBLK_EXIT ; Jump if something went wrong

; * Allocate all of (the remaining) extended memory (XMS Handle #2)

	mov	si,2		; Mark as handle #2
	call	AllocMem	; Allocate memory
				; Return with DX = XMS handle
	jc	near ptr XMSBLK_ERR2A ; Jump if something went wrong

	mov	XMSHNDL2,dx	; Save for later use

; Get base of handle #2 and ensure it's at the start of the MTBT

;;;;;;; mov	dx,XMSHNDL2	; Get XMS handle #2
	mov	ah,@XMS_LCKXMB	; Function code to lock extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      DX:BX = linear address
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
	jne	near ptr XMSBLK_ERR2B ; Jump if not

	mov	XMSADDR2.ELO,bx ; Save for later use
	mov	XMSADDR2.EHI,dx ; ...

	mov	dx,XMSHNDL2	; Get XMS handle #2
	mov	ah,@XMS_UNLXMB	; Function code to unlock extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
	jne	near ptr XMSBLK_ERR2C ; Jump if not

	mov	eax,XMSADDR2	; Get linear address of XMS handle #2

	cmp	eax,MEM_BEG	; Izit at start of MTBT?
	jne	near ptr XMSBLK_ERR2D ; Jump if not

; * Re-allocate handle #2 down to the end of the MTBT.

;;;;;;; mov	dx,XMSHNDL2	; Get XMS handle #2
	mov	ebx,MEM_END	; Get linear address of end of MTBT
	sub	ebx,XMSADDR2	; Less start of XMS handle #2
	call	ModifyMem	; Re-allocate memory downwards
	jc	near ptr XMSBLK_ERR2E ; Jump if something went wrong

; Determine amount of remaining memory and confirm that it's contiguous

	call	QueryMem	; Query amount of extmem
	jc	near ptr XMSBLK_EXIT ; Jump if something went wrong

; * Allocate all of (the remaining) extended memory (XMS Handle #3)

	mov	si,3		; Mark as handle #3
	call	AllocMem	; Allocate memory
				; Return with DX = XMS handle
	jc	near ptr XMSBLK_ERR3A ; Jump if something went wrong

	mov	XMSHNDL3,dx	; Save for later use

; Get base of handle #3 and ensure it's at the end of the MTBT

;;;;;;; mov	dx,XMSHNDL3	; Get XMS handle #3
	mov	ah,@XMS_LCKXMB	; Function code to lock extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      DX:BX = linear address
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
	jne	near ptr XMSBLK_ERR3B ; Jump if not

	mov	XMSADDR3.ELO,bx ; Save for later use
	mov	XMSADDR3.EHI,dx ; ...

	mov	dx,XMSHNDL3	; Get XMS handle #3
	mov	ah,@XMS_UNLXMB	; Function code to unlock extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
	jne	near ptr XMSBLK_ERR3C ; Jump if not

	mov	eax,XMSADDR3	; Get linear address of XMS handle #3

	cmp	eax,MEM_END	; Izit at end of MTBT?
	jne	near ptr XMSBLK_ERR3D ; Jump if not

; * Release XMS handle #2.

	mov	dx,XMSHNDL2	; Get XMS handle #2
	mov	ah,@XMS_RELXMB	; Function code to release extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
	jne	near ptr XMSBLK_ERR4 ; Jump if not

;;;;;;; mov	MSG_XMSREL1[0],'2' ; Mark as XMS handle #2
;;;;;;; lea	di,MSG_XMSREL2[3] ; ES:DI ==> output save area
;;;;;;; movzx	eax,dx		; Copy XMS handle, zero to use as dword
;;;;;;; mov	cx,16		; Convert as Hexadecimal
;;;;;;; call	BIND2BASE	; Convert EAX to ASCII at ES:DI
;;;;;;;
;;;;;;; DOSCALL @STROUT,MSG_XMSREL ; Display the message
;;;;;;;
	push	dx		; Pass XMS handle
	push	2		; ...  handle count
	push	ds		; ...  segment of format string
	push	offset ds:MSG_XMSREL ; ... offset ...
	call	PRINTF16	; Print format
	add	sp,4+2+2	; Strip arguments from stack

	mov	ERRCODE,0	; Mark as successful

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR1A:
	DOSCALL @STROUT,MSG_NONALLOC1 ; Tell 'em the bad news

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR1B:
	DOSCALL @STROUT,MSG_NONLOCK1 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR1C:
	DOSCALL @STROUT,MSG_NONUNLK1 ; Tell 'em the bad news

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR1D:
	DOSCALL @STROUT,MSG_NONINTER1 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR1E:
	DOSCALL @STROUT,MSG_NONMOD1 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR2A:
	DOSCALL @STROUT,MSG_NONALLOC2 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR2B:
	DOSCALL @STROUT,MSG_NONLOCK2 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

; Free XMS handle #2

	mov	dx,XMSHNDL2	; Get XMS handle #2
	call	FreeMem 	; Free it

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR2C:
	DOSCALL @STROUT,MSG_NONUNLK2 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR2D:
	DOSCALL @STROUT,MSG_NONINTER2 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

; Free XMS handle #2

	mov	dx,XMSHNDL2	; Get XMS handle #2
	call	FreeMem 	; Free it

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR2E:
	DOSCALL @STROUT,MSG_NONMOD2 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

; Free XMS handle #2

	mov	dx,XMSHNDL2	; Get XMS handle #2
	call	FreeMem 	; Free it

	jmp	XMSBLK_EXIT	; Join common exit code


XMSBLK_ERR3A:
	DOSCALL @STROUT,MSG_NONALLOC3 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

; Free XMS handle #2

	mov	dx,XMSHNDL2	; Get XMS handle #2
	call	FreeMem 	; Free it

	jmp	short XMSBLK_EXIT ; Join common exit code


XMSBLK_ERR3B:
	DOSCALL @STROUT,MSG_NONLOCK3 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

; Free XMS handle #2

	mov	dx,XMSHNDL2	; Get XMS handle #2
	call	FreeMem 	; Free it

; Free XMS handle #3

	mov	dx,XMSHNDL3	; Get XMS handle #3
	call	FreeMem 	; Free it

	jmp	short XMSBLK_EXIT ; Join common exit code


XMSBLK_ERR3C:
	DOSCALL @STROUT,MSG_NONUNLK3 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

; Free XMS handle #2

	mov	dx,XMSHNDL2	; Get XMS handle #2
	call	FreeMem 	; Free it

	jmp	short XMSBLK_EXIT ; Join common exit code


XMSBLK_ERR3D:
	DOSCALL @STROUT,MSG_NONINTER3 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

; Free XMS handle #2

	mov	dx,XMSHNDL2	; Get XMS handle #2
	call	FreeMem 	; Free it

; Free XMS handle #3

	mov	dx,XMSHNDL3	; Get XMS handle #3
	call	FreeMem 	; Free it

	jmp	short XMSBLK_EXIT ; Join common exit code


XMSBLK_ERR4:
	DOSCALL @STROUT,MSG_NONREL2 ; Tell 'em the bad news

; Free XMS handle #1

	mov	dx,XMSHNDL1	; Get XMS handle #1
	call	FreeMem 	; Free it

; Free XMS handle #2

	mov	dx,XMSHNDL2	; Get XMS handle #2
	call	FreeMem 	; Free it

; Free XMS handle #3

	mov	dx,XMSHNDL3	; Get XMS handle #3
	call	FreeMem 	; Free it

	jmp	short XMSBLK_EXIT ; Join common exit code


XMSBLK_EXIT:
	mov	al,ERRCODE	; Exit code
	DOSCALL @EXITRC 	; Return to DOS

XMSBLK	endp			; End XMSBLK procedure
	NPPROC	CheckArgs -- Check Arguments
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check arguments

Arguments:

nn-nn	=	Allocate memory in range nn to nn
/?	=	Display help message

On exit:

CF	=	0 if OK
	=	1 if we're done

|

	push	ds		; Save register
	pushad			; Save all EGP registers

	mov	ds,PSPSEG	; Address the PSP
	assume	ds:PSPGRP	; Tell the assembler about it

	lea	si,PSP_PARM_STRING ; DS:SI ==> arguments
	movzx	bx,PSP_PARM_COUNT ; BX = # characters in argument
	mov	PSPGRP:[bx+si].LO,0 ; Terminate the argument list
CheckArgsNext:
	call	SKIP_WHITE	; Skip over more white space

	cmp	al,0		; Izit EOL?
	je	short CheckArgsHelp ; Jump if so (note CF=0)

	cmp	al,'/'          ; Izit switch separator?
	jne	short CheckArgsRange ; Jump if not (must be memory range)

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,'?'          ; Izit a request for help?
	je	short CheckArgsHelp ; Jump if so

; Unrecognized switch character

	mov	ds,DATASEG	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it
	DOSCALL @STROUT,MSG_UNKSW ; Tell the bad news
	assume	ds:nothing	; Tell the assembler about it

	jmp	short CheckArgsErr ; Join common error code


CheckArgsRange:
	dec	si		; Back up to last char
	call	Convert 	; Convert DS:SI to binary

	mov	MEM_BEG,ebx	; Save for later use

	cmp	al,'-'          ; Izit separator?
	jne	short @F	; Jump if not

	inc	si		; Skip over separator
	call	SKIP_WHITE	; Skip over more white space
	dec	si		; Back up to last char
@@:
	call	Convert 	; Convert DS:SI

	mov	MEM_END,ebx	; Save for later use

; Ensure arguments are valid

CheckArgsValid:
	mov	eax,MEM_BEG	; Get beginning address

	cmp	eax,1024*1024	; Izit at or above 1MB minimum?
	jb	short CheckArgsMemErr ; Jump if not

	cmp	eax,MEM_END	; Is beginning below ending?
	jae	short CheckArgsMemErr ; Jump if not

; Ensure arguments are on kilobyte boundary

	test	MEM_BEG,(1 shl 10)-1 ; Izit on KB boundary?
	jnz	short CheckArgsErr ; Jump if not

	test	MEM_END,(1 shl 10)-1 ; Izit on KB boundary?
	jnz	short CheckArgsErr ; Jump if not

	clc			; Mark as successful

	jmp	short CheckArgsExit ; Join common exit code


CheckArgsMemErr:
	mov	ds,DATASEG	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it
	DOSCALL @STROUT,MSG_MEMERR ; Tell the bad news
	assume	ds:nothing	; Tell the assembler about it
CheckArgsHelp:
	mov	ds,DATASEG	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it
	DOSCALL @STROUT,MSG_HELP ; Give 'em a hand
	assume	ds:nothing	; Tell the assembler about it
CheckArgsErr:
	stc			; Mark as unsuccessful
CheckArgsExit:
	popad			; Restore
	pop	ds		; ...
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckArgs endp			; End CheckArgs procedure
	NPPROC	Convert -- Convert ASCII
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert ASCII to binary handling K or M suffix.

On entry:

DS:SI	==>	ASCII text

On exit:

AL	=	next char
DS:SI	==>	(updated)
EBX	=	converted value

|

	REGSAVE <cx>		; Save register

	mov	cx,10		; Convert as decimal
	call	BASE2BIND	; Convert DS:SI from ASCII to binary in EAX
	mov	ebx,eax 	; Save for later use

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,'k'          ; Isi it in units of kilobytes?
	jne	short @F	; Jump if not

	shl	ebx,10-0	; Convert from bytes to kilobytes
	call	SKIP_WHITE	; Skip over more white space
@@:
	cmp	al,'m'          ; Isi it in units of megabytes?
	jne	short @F	; Jump if not

	shl	ebx,20-0	; Convert from bytes to megabytes
	call	SKIP_WHITE	; Skip over more white space
@@:
	dec	si		; Back off to last char

	REGREST <cx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

Convert endp			; End Convert procedure
	NPPROC	LOWERCASE -- Convert AL to Lowercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	cmp	al,40h		; Test for conversion of alpha to lower case
	jb	short LOWERCASE_EXIT ; Not this time

	or	al,20h		; Convert alpha to lower case
LOWERCASE_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	NPPROC	SKIP_WHITE -- Skip over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	lods	ds:[si].LO	; Get the next byte

	cmp	al,' '          ; Check for blank
	je	SKIP_WHITE	; Go around again

	cmp	al,TAB		; Check for TAB
	je	SKIP_WHITE	; Go around again

	call	LOWERCASE	; Convert to lowercase

	ret			; Return to caller with next byte in AL

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	NPPROC	BASE2BIND -- Convert From Specified Base to Binary
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BASE2BIND -- Convert the number at DS:SI in base CX to binary.
The converted # is returned in EAX.

|

	REGSAVE <ebx,ecx,edx,edi> ; Save registers

	call	SKIP_WHITE	; Skip over more white space

	xor	ebx,ebx 	; Zero accumulator
	movzx	ecx,cx		; Zero to use as dword
BASE2BIND_LOOP:
	lea	edi,NUMBERS_LO	; Get address of number conversion table
	push	cx		; Save number base (and table length)
  repne scas	es:[di].LO	; Look for the character
	pop	cx		; Restore number base
	jne	short BASE2BIND_EXIT ; Not one of ours

	sub	edi,1+offset es:NUMBERS_LO ; Convert to origin 0
	mov	eax,ebx 	; Copy old to multiply by base
	mul	ecx		; Shift over accumulated #
	mov	ebx,eax 	; Copy back
	add	ebx,edi 	; Add in new #

	lods	ds:[si].LO	; Get next digit
	call	LOWERCASE	; Convert to lowercase

	jmp	BASE2BIND_LOOP	; Go around again

BASE2BIND_EXIT:
	dec	si		; Back off to previous character
	mov	eax,ebx 	; Place result in accumulator

	REGREST <edi,edx,ecx,ebx> ; Restore registers

	ret			; Return to caller with number in AX

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BASE2BIND endp			; End BASE2BIND procedure
	NPPROC	BIND2BASE -- Convert From Binary to Specified Base
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIND2BASE -- Convert the number in EAX to ASCII in base CX storing the
low-order digit of the # at ES:DI.

On exit:

ES:DI	==>	next byte below last one stored

|

	REGSAVE <eax,ecx,edx,si> ; Save registers

	pushf			; Save all flags
	std			; Direction backwards for MOVSB

	movzx	ecx,cx		; Zero to use as dword
BIND2BASE_LOOP:
	xor	edx,edx 	; Zero high-order dword for division
	div	ecx		; Divide by number base
				; EDX has remainder, EAX has quotient
	lea	si,NUMBERS_HI[edx] ; Get address of table + offset
	movs	es:[di].LO,NUMBERS_HI[si] ; Store in result

	and	eax,eax 	; Check for zero quotient
	jnz	short BIND2BASE_LOOP ; Jump if more to do
BIND2BASE_EXIT:
	popf			; Restore flags

	REGREST <si,edx,ecx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIND2BASE endp			; End BIND2BASE procedure
	NPPROC	CheckXMS -- Check On XMS Presence
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on XMS presence

On exit:

CF	=	0 if present
	=	1 if not

|

	pushad			; Save all EGP registers

	mov	ax,4300h	; Function code to check on presence
	int	2Fh		; Request redirector service

	cmp	al,80h		; Izit installed?
	jne	short CheckXMSErr ; Jump if not present

	push	es		; Save for a moment

	mov	ax,4310h	; Function code to obtain address of handler
	int	2Fh		; Request redirector service
	assume	es:nothing	; Tell the assembler about it

	mov	OLDXMS_VEC.VOFF,bx ; Save for later use
	mov	OLDXMS_VEC.VSEG,es ; ...

	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it

; If there's an XMS 3.0 handler present, use the extended services

	mov	ah,@XMS_VERS	; Function code to get XMS version #
	call	OLDXMS_VEC	; Request XMS service
				; AX = XMS version
				; BX = MAX version
	cmp	ax,0300h	; Izit version 3.0 or above?
	jb	short @F	; Jump if so

	mov	XMS_QRYXMB,@XMS_QRY2XMB ; Use extended services
	mov	XMS_GETXMB,@XMS_GET2XMB ; ...
	mov	XMS_MODXMB,@XMS_MOD2XMB ; ...
@@:
	clc			; Mark as present

	jmp	short CheckXMSExit ; Join common exit code


CheckXMSErr:
	stc			; Mark as not present
CheckXMSExit:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckXMS endp			; End CheckXMS procedure
	NPPROC	QueryMem -- Query Amount Of XMS Memory
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Query amount of XMS memory

On exit:

MAXMEM	=	filled in
TOTMEM	=	filled in

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save all EGP registers

	xor	eax,eax 	; Zero to use as dword
	xor	edx,edx 	; ...
	mov	ah,XMS_QRYXMB	; Function code to query free extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with eAX = size of largest free
				;	      eDX = total amount
				;	      eCX = highest ending address of
				;		    any memory block (if XMS 3.0)
				; ...	      BL = error code if error
	cmp	eax,0		; Check for error
	jne	short @F	; Jump if there's something

	cmp	bl,0A0h 	; Check for insufficient extmem
	je	short @F	; Jump if so

	cmp	bl,0		; Check for other error
	jne	short QueryMemErr ; Jump if so *FIXME* -- handle w/error msg
@@:
	mov	TOTMEM,edx	; Save for later use
	mov	MAXMEM,eax	; ...

;;;;;;; lea	di,MSG_XMSSIZE1 ; ES:DI ==> units digit in message
;;;;;;; mov	cx,10		; Use base 10 to convert
;;;;;;; call	BIND2BASE	; Convert EAX to ASCII ending at ES:DI
;;;;;;;
;;;;;;; mov	eax,edx 	; Copy size of total
;;;;;;; lea	di,MSG_XMSSIZE2 ; ES:DI ==> units digit in message
;;;;;;; mov	cx,10		; Use base 10 to convert
;;;;;;; call	BIND2BASE	; Convert EAX to ASCII ending at ES:DI
;;;;;;;
;;;;;;; DOSCALL @STROUT,MSG_XMSSIZE ; Display the current size
;;;;;;;
	push	edx		; Pass total amount
	push	eax		; ...  size of largest
	push	ds		; ...  segment of format string
	push	offset ds:MSG_XMSSIZE ; ... offset ...
	call	PRINTF16	; Print format
	add	sp,4+4+4	; Strip arguments from stack

	mov	eax,TOTMEM	; Get total amount of memory

	cmp	eax,MAXMEM	; Ensure same as we don't deal with fragmentation
	je	short QueryMemExit ; Jump if so (note CF=0)

	DOSCALL @STROUT,MSG_NONCONTIG ; Tell 'em the bad news
QueryMemErr:
	stc			; Mark as in error
QueryMemExit:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

QueryMem endp			; End QueryMem procedure
	NPPROC	AllocMem -- Allocate All Remaining XMS Memory
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate all remaining XMS mmeory

On entry:

SI	=	handle count

On exit:

DX	=	XMS handle
CF	=	0 if successful
	=	1 if not

|

	REGSAVE <eax,bx,cx,di>	; Save registers

	mov	edx,TOTMEM	; Get amount to allocate
	mov	ah,XMS_GETXMB	; Function code to allocate extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      DX = handle
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
	jne	short AllocMemExit ; Jump if not (note CF=1)

;;;;;;; push	dx		; Save XMS handle
;;;;;;;
;;;;;;; lea	di,MSG_XMSHNDL2[3] ; ES:DI ==> output save area
;;;;;;; movzx	eax,dx		; Copy XMS handle, zero to use as dword
;;;;;;; mov	cx,16		; Convert as Hexadecimal
;;;;;;; call	BIND2BASE	; Convert EAX to ASCII at ES:DI
;;;;;;;
;;;;;;; DOSCALL @STROUT,MSG_XMSHNDL ; Display the message
;;;;;;;
	push	dx		; Pass XMS handle #
	push	si		; ...  handle count
	push	ds		; ...  segment of format string
	push	offset ds:MSG_XMSHNDL ; ... offset ...
	call	PRINTF16	; Print format
	add	sp,4+2+2	; Strip arguments from stack
;;;;;;;
;;;;;;; pop	dx		; Restore
AllocMemExit:
	REGREST <di,cx,bx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

AllocMem endp			; End AllocMem procedure
	NPPROC	ModifyMem -- Modify XMS Memory
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Re-allocate XMS memory downwards

On entry:

DX	=	XMS memory handle
EBX	=	new size for XMS handle in bytes

On exit:

CF	=	0 if successful
	=	1 if not

|

	REGSAVE <ax,ebx>	; Save registers

	shr	ebx,10-0	; Convert from bytes to KB
	mov	ah,XMS_MODXMB	; Function code to modify extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
				; Return with CF = 0 if successful
				; ...		   1 if not
	REGREST <ebx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ModifyMem endp			; End ModifyMem procedure
	NPPROC	FreeMem -- Free XMS Memory
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Free XMS memory

On entry:

DX	=	XMS memory handle

On exit:

CF	=	0 if successful
	=	1 if not

|

	pusha			; Save all GP registers

	mov	ah,@XMS_RELXMB	; Function code to releae extmem
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if succesful, 0 if not
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
				; Return with CF = 0 if successful
				; ...		   1 if not
FreeMemExit:
	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FreeMem endp		; End FreeMem procedure

CODE	ends			; End CODE segment

	MEND	XMSBLK		; End XMSBLK module

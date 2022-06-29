;' $Header$
	title	XMSLIST -- List XMS Memory Usage
	page	58,122
	name	XMSLIST

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
	include 386.INC
.list

PGROUP	group	CODE
DGROUP	group	DATA,STACK


; The following segment positions the CODE segment before the DATA segment
; so that we can define DATA segment values before they are used in
; the CODE segment to avoid forward references.

CODE	segment use16 byte public 'code' ; Start CODE segment
CODE	ends			; End CODE segment


DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	public	OLDXMS_VEC
OLDXMS_VEC dd	?		; Save area for address of XMS driver

	public	XMSLEN,XMSADDR,XMSHNDL,XMSVER,XMSLOCK,XMSFLAG
XMSLEN	dd	?		; XMS block length in KB
XMSADDR dd	?		; XMS block starting address
XMSHNDL dw	0		; Initial XMS handle
XMSVER	dw	?		; XMS version #
XMSLOCK dw	0		; XMS block count count
XMSFLAG db	0,?		; Flag:  1 = header displayed, 0 = not

	public	STACKARR
STACKARR dw	?		; Offset of top of stack array

	public	MSG_COPY
MSG_COPY db	'XMSLIST  -- Version 1.02 -- An XMS Memory Lister',CR,LF
	db	'   (C) Copyright 2000-2003 Qualitas, Inc. '
	db	' All rights reserved.',CR,LF
	db	EOS

	public	MSG_NOXMS
MSG_NOXMS db	BEL,ARROW,ARROW,'> No XMS driver present.',CR,LF,EOS

	public	MSG_HDR,MSG_LIST
MSG_HDR db	'The XMS (version %tX.%02tX) driver reports that there are %,u free XMS handles.',CR,LF
	db	'Handle   Address                 Length                Lock',CR,LF,0
;		' ____h  ________h (___,___ KB)  ________h (___,___ KB)  __',CR,LF,0
MSG_LIST db	' %04Xh  %08lXh (%,.7lu KB)  %08lXh (%,.7lu KB)  %u',CR,LF,0

	public	MSG_AVAIL
;		' Avail  ________h (___,___ KB)  ________h (___,___ KB)  __',CR,LF,0
MSG_AVAIL db	' -Avl-  %08lXh (%,.7lu KB)  %08lXh (%,.7lu KB)  %u',CR,LF,0

	public	XMS_QRYXMB,XMS_GETXMB,XMS_MODXMB,XMS_GETINF
XMS_QRYXMB db	@XMS_QRYXMB	; Function code to query XMS memory
XMS_GETXMB db	@XMS_GETXMB	; ...		   get	 ...
XMS_MODXMB db	@XMS_MODXMB	; ...		   modify ...
XMS_GETINF db	@XMS_GETINF	; ...		   get XMS handle info

	public	NUMBERS_HI
NUMBERS_HI db	'0123456789ABCDEF' ; Conversion table for BIND2BASE

DATA	ends			; End DATA segment


STACK	segment use16 para stack 'data' ; Start STACK segment
	assume	ds:DGROUP

	dd	400h dup (?)	; Default stack

STACK	ends			; End STACK segment


CODE	segment use16 byte public 'code' ; Start CODE segment
	assume	cs:PGROUP,ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	extrn	PRINTF16:near

	public	DATASEG
DATASEG dw	seg DGROUP	; Segment of DGROUP

	NPPROC	XMSLIST -- List XMS Memory Usage
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

List XMS memory usage

On entry:

ES	=	PSP segment

|

	mov	ds,DATASEG	; Address DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

;;;;;;; mov	PSPSEG,es	; Save segment of PSP

	mov	es,DATASEG	; Address it
	assume	es:DGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_COPY ; Display our copyright

	call	CheckXMS	; Ensure there's an XMS driver present
	jc	near ptr XMSLIST_EXIT ; Jump if something went wrong

; Loop through all possible XMS handles

	mov	ecx,10000h	; # XMS handles
XMSLIST_NEXT1:
	mov	dx,XMSHNDL	; Get next XMS handle #

	call	DispXMSInfo	; Display XMS info about handle in DX
	jc	short XMSLIST_LOOP1 ; Jump if bad handle

	push	XMSLOCK 	; Pass XMS lock count

	mov	eax,XMSLEN	; Get length in bytes
	push	eax		; ...  XMS block length in KB
	shl	eax,10-0	; Convert from KB to bytes
	push	eax		; ...  XMS block length in bytes

	mov	eax,XMSADDR	; ...  XMS starting address in bytes
	shr	eax,10-0	; Convert from bytes to KB
	push	eax		; ...  XMS starting address in KB
	push	XMSADDR 	; ...  XMS starting address in bytes

	push	XMSHNDL 	; ...  XMS handle #
	push	ds		; ...  segment of format string
	push	offset ds:MSG_LIST ; ... offset ...
	call	PRINTF16	; Print format
	add	sp,4+2+4+4+4+4+2 ; Strip arguments from stack
XMSLIST_LOOP1:
	inc	XMSHNDL 	; Skip to next XMS handle

	LOOPD	XMSLIST_NEXT1	; Jump if more XMS handles

; Allocate the largest available block until all memory is exhausted
; unless we're running under Windows in which case it'll attempt to
; use the swap file.

	call	CheckWin	; Izit running under Windows?
	jc	near ptr XMSLIST_EXIT ; Jump if so

	mov	STACKARR,sp	; Save offset of top of the stack array
XMSLIST_NEXT2:
	xor	eax,eax 	; Zero to use as dword
	xor	edx,edx 	; ...
	mov	ah,XMS_QRYXMB	; Function code to Query XMS Memory
	call	OLDXMS_VEC	; Request XMS service
				; Return with eAX = size of largest free block
				; ...	      BL  = 0 if successful, != 0 if not
				; ...	      eCX = highest ending address
				; ...	      eDX = total amount of free memory
				; ...	      BL = error code if error
	cmp	bl,0		; Izit successful?
	jne	short XMSLIST_DISP2 ; Jump if not (time to display)

	mov	edx,eax 	; Copy size of largest free block
	mov	ah,XMS_GETXMB	; Function code to Allocate XMS Memory
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      DX = handle
				; ...	      BL = error code if error
	push	dx		; Save the handle

	jmp	XMSLIST_NEXT2	; Go around again


XMSLIST_DISP2:
	cmp	sp,STACKARR	; Izit done?
	je	short XMSLIST_EXIT ; Jump if so

	pop	XMSHNDL 	; Get XMS handle

	call	DispXMSInfo	; Display XMS info about handle in XMSHNDL
;;;;;;; jc	short XMSLIST_LOOP2 ; Jump if bad handle???

	push	XMSLOCK 	; Pass XMS lock count

	mov	eax,XMSLEN	; Get length in bytes
	push	eax		; ...  XMS block length in KB
	shl	eax,10-0	; Convert from KB to bytes
	push	eax		; ...  XMS block length in bytes

	mov	eax,XMSADDR	; ...  XMS starting address in bytes
	shr	eax,10-0	; Convert from bytes to KB
	push	eax		; ...  XMS starting address in KB
	push	XMSADDR 	; ...  XMS starting address in bytes

	push	ds		; ...  segment of format string
	push	offset ds:MSG_AVAIL ; ... offset ...
	call	PRINTF16	; Print format
	add	sp,4+4+4+4+4+2	; Strip arguments from stack

; Free the memory

	mov	dx,XMSHNDL	; Get next XMS handle #
	mov	ah,@XMS_RELXMB	; Function code to release XMS block
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      BL = error code if error
;;;;;;; cmp	ax,1		; Did it work?
;;;;;;; jne	short ???	; Jump if not

	jmp	XMSLIST_DISP2	; Go around again


XMSLIST_EXIT:
	mov	al,0		; Exit code
	DOSCALL @EXITRC 	; Return to DOS

XMSLIST endp			; End XMSLIST procedure
	NPPROC	DispXMSInfo -- Display XMS Info
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display XMS info

On entry:

DX	=	XMS handle

On exit:

CF	=	0 if successful
	=	1 if not

|

	pushad			; Save all EGP registers

	xor	edx,edx 	; Zero to use as dword (in case ver 3.0+)
	mov	dx,XMSHNDL	; Get next XMS handle #
	mov	ah,XMS_GETINF	; Function code to Get XMS Information
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      BH = lock count
				; ...	      BL = free handles (if XMS 2)
				; ...	      CX = free handles (if XMS 3)
				; ...	      eDX = length in KB
				; ...	      BL = error code if error
	cmp	ax,1		; Did it work?
	jb	short DispXMSInfoExit ; Jump if not (note CF=1)

	mov	XMSLOCK.LO,bh	; Save for later use

	cmp	XMSVER,0300h	; Izit XMS 3?
	jae	short @F	; Jump if so

	movzx	cx,bl		; Copy # free XMS handles
@@:
	mov	XMSLEN,edx	; Save for later use

; Lock the block so we can get its starting address

	mov	dx,XMSHNDL	; Get next XMS handle #
	mov	ah,@XMS_LCKXMB	; Function code to lock XMS block
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      DX:BX = starting linear address
				; ...	      BL = error code if error
;;;;;;; cmp	ax,1		; Did it work?
;;;;;;; jne	short ???	; Jump if not

	mov	XMSADDR.ELO,bx	; Save for later use
	mov	XMSADDR.EHI,dx	; ...

; Unlock the block

	mov	dx,XMSHNDL	; Get next XMS handle #
	mov	ah,@XMS_UNLXMB	; Function code to unlock XMS block
	call	OLDXMS_VEC	; Request XMS service
				; Return with AX = 1 if successful, 0 if not
				; ...	      BL = error code if error
;;;;;;; cmp	ax,1		; Did it work?
;;;;;;; jne	short ???	; Jump if not

	bts	XMSFLAG,0	; Has the header been displayed?
	jc	short @F	; Jump if so

	mov	ax,XMSVER	; Get version #
	xchg	al,ah		; Swap to printing order

	push	cx		; Pass # free XMS handles
	push	ax		; ...  version #
	push	ds		; ...  segment of format string
	push	offset ds:MSG_HDR ; ... offset ...
	call	PRINTF16	; Print format
	add	sp,4+2*2	; Strip arguments from stack
@@:
	clc			; Mark as successful
DispXMSInfoExit:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DispXMSInfo endp		; End DispXMSInfo procedure
	NPPROC	BIND2BASE -- Convert From Binary to Specified Base
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
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

	pusha			; Save all GP registers

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
	mov	XMSVER,ax	; Save for later use

	cmp	ax,0300h	; Izit version 3.0 or above?
	jb	short @F	; Jump if so

	mov	XMS_QRYXMB,@XMS_QRY2XMB ; Use extended services
	mov	XMS_GETXMB,@XMS_GET2XMB ; ...
	mov	XMS_MODXMB,@XMS_MOD2XMB ; ...
	mov	XMS_GETINF,@XMS_GET2INF ; ...
@@:
	clc			; Mark as present

	jmp	short CheckXMSExit ; Join common exit code


CheckXMSErr:
	DOSCALL @STROUT,MSG_NOXMS ; Tell 'em the bad news

	stc			; Mark as not present
CheckXMSExit:
	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckXMS endp			; End CheckXMS procedure
	NPPROC	CheckWin -- See If Windows Is Active
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if Windows is active.

On exit:

CF	=	 1 if Windows is active
	=	 0 if not

|

	pusha			; Save registers

	mov	ax,3306h	; Code for Get True DOS Version #
	int	21h		; Request DOS service
				; BH = minor version
				; BL = major ...
				; DH = version flags
				; AL = FF if true DOS version is < 5.0
	jc	short @F	; Jump if not supported

	xchg	bh,bl		; Swap to comparison order

	cmp	al,0FFh 	; Is true DOS version # < 5.0?
	je	short @F	; Jump if so

	cmp	bx,0532h	; Izit 5.50 from Win NT/2000?
	jne	short @F	; Jump if not

	mov	ax,bx		; Copy to common register

	jmp	short CheckWinCom ; Join common code


@@:
	mov	ax,160Ah	; Code for Get Windows Version & Type
	int	2Fh		; Request multiplexor service
				; AX = 0000h if supported
				; BX = version # (BH=major, BL=minor)
				; CX = mode (0002h = standard, 0003h = enhanced)
	and	ax,ax		; Izit supported?
	jz	short CheckWinCom ; Jump if so

	mov	ax,1600h	; Code for Windows/386 Installation Check
	int	2Fh		; Request multiplexor service
				; AL = 00h if not running
				; AL = 80h if not running
				; AL = 01h if Version 2.xx running
				; AL = FFh if Version 2.xx running
				; AL = Major version #, AH = Minor ...

	test	al,7Fh		; Test for 00h and 80h
	jz	short CheckWinExit ; Jump if not running (note CF=0)

	cmp	al,01h		; Izit 2.xx?
	je	short CheckWinExit ; Jump if so (note CF=0)

	cmp	al,0FFh 	; Izit the other 2.xx?
	je	short CheckWinExit ; Jump if so (note CF=0)

;;;;;;; xchg	al,ah		; Swap to comparison order
CheckWinCom:
;;;;;;; cmp	ax,0400h	; Izit Win95 or later?
;;;;;;; jb	short @F	; Jump if not
;;;;;;;
;;;;;;; or	LCL_FLAG,@LCL_WIN95 ; Mark as running under Win95
;;;@@:
	stc			; Mark as active
CheckWinExit:
	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CheckWin endp			; End CheckWin procedure

CODE	ends			; End CODE segment

	MEND	XMSLIST 	; End XMSLIST module

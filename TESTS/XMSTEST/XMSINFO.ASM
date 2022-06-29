;' $Header:   P:/PVCS/MISC/XMSTEST/XMSINFO.ASV   1.2   22 Feb 1994 12:48:12   HENRY  $

	PAGE	60,132
	TITLE	xmsinfo
;
	.MODEL	LARGE,PASCAL
;
;	Local data
;
	.DATA
	ASSUME	DS: DGROUP
XMSControl dd ? 	; XMS Control address
;
;------------------------------------------------------------------------
;
	.CODE
comment|
/*-asm-*/  int pascal far xmsparm(XMSPARM far *parm);
|
;=======================================================================
;
;	xmsparm - Get general XMS parameters.
;
;	Copyright (c) 1990 ACL Engineering
;
;	#include <xmsinfo.h>
;
;	int pascal far xmsparm(XMSPARM far *parm);
;
;	returns:	 0 if successful
;			 1 if not installed
;			-1 if error
;
;=======================================================================
;
XMS_PARM STRUC
INSTALLED dw	?	; 1 if XMS installed, 0 if not, -1 if error
VERSION  dw	?	; XMS version number
DRIVER	dw	?	; Driver version number
HMAEXIST dw	?	; HMA exists flag
HMAAVAIL dw	?	; HMA available flag
A20STATE dw	?	; Current state of A20 line
EMBHAND  dw	?	; EMB handles
EMBTOTAL dw	?	; Total free EMB memory
EMBAVAIL dw	?	; Largest free EMB memory block
UMBTOTAL dw	?	; Total free UMB memory
UMBAVAIL dw	?	; Largest free UMB memory block
XMS_PARM ENDS


XMSPARM PROC parm:dword
	push	di
;
	mov	ax,4300h	; Check for driver installed
	int	2fh		; Do it
	cmp	al,80h		; Test for this value
	jz	@F
	jmp	NOT_INST	; If not installed
@@:
	mov	ax,4310h	; Get address of driver control function
	int	2fh		; Do it
	mov	word ptr [XMSControl],bx ; Store it
	mov	word ptr [XMSControl+2],es
;
	les	di,parm 	; Point to parameter block
;
	mov	ah,00h		; Get XMS version number
	call	[XMSControl]
	mov	es:[di].VERSION,ax	; XMS version number
	mov	es:[di].DRIVER,bx	; Driver revision number
	mov	es:[di].HMAEXIST,dx	; HMA exists flag
	mov	ax,1
	mov	es:[di].INSTALLED,ax	; Flag installed
;
	mov	ax,0			; Assume HMA not available
	mov	es:[di].HMAAVAIL,ax	; HMA available flag
;
	cmp	dx,1			; Does HMA exist
	jne	NO_HMA			; ...nope
;
	mov	ah,01h			; HMA exists, ask for it
	mov	dx,0ffffh		; ...application program
	call	[XMSControl]
	or	ax,ax
	jz	NO_HMA
;
	mov	ah,02h			; We got it, release it
	call	[XMSControl]
	mov	ax,1			; Flag HMA available
	mov	es:[di].HMAAVAIL,ax	; HMA available flag
NO_HMA:
	mov	ah,07h		; Query A20
	call	[XMSControl]
	mov	es:[di].A20STATE,ax	; Total free
;
	mov	ah,08h		; Query free extended memory
	call	[XMSControl]
	mov	es:[di].EMBTOTAL,dx	; Total free
	mov	es:[di].EMBAVAIL,ax	; Largest available
;
	mov	ah,09h		; Allocate EMB Handle
	mov	dx,1h		; Smallest we can ask for
	call	[XMSControl]
	or	ax,ax		; Check return status
	jnz	@F		; If ok
	mov	ax,0
	mov	es:[di].EMBHAND,ax
	jmp	NO_HANDLE
@@:
	mov	ah,0Eh		; Get EMB Handle information
				; DX = handle
	push	dx		; Save handle
	call	[XMSControl]	; On return, DX=block's length in K
	pop	dx		; Restore handle (ignore size, we know it)
	mov	ah,0
	mov	al,bl
	inc	ax		; Factor in our handle
	mov	es:[di].EMBHAND,ax ; Handles free
;
	mov	ah,0Ah		; Free our EMB Block
				; DX = handle
	call	[XMSControl]
NO_HANDLE:
	mov	ah,10h		; Try to allocate a UMB
	mov	dx,0ffffh	; Ask for the world
	call	[XMSControl]
	mov	es:[di].UMBAVAIL,dx	; Largest available
	mov	es:[di].UMBTOTAL,dx	; This is a lie...
;
	mov	ax,0
	jmp	ALL_DONE
;
NOT_INST:
	les	di,parm 	; Point to parameter block
	mov	ax,0
	mov	es:[di].INSTALLED,ax	; Flag installed
;
	jmp	ALL_DONE
;
ALL_DONE:
	pop	di
	ret

XMSPARM ENDP
;
comment|
/*-asm-*/  unsigned short pascal far umballoc(int npara);
|
;=======================================================================
;
;	umballoc - Allocate an Upper Memory Block.
;
;	Copyright (c) 1990 ACL Engineering
;
;	#include <xmsinfo.h>
;
;	unsigned short pascal far umballoc(int npara);
;
;	returns:	 Segment address if successful
;			 0 otherwise
;
;=======================================================================
;

UMBALLOC PROC npara:word
	mov	ah,10h		; Request Upper Memory Block
	mov	dx,npara	; How much
	call	[XMSControl]
	or	ax,ax		; Status check
	jnz	@F		; If ok
	mov	bx,0		; else, flag error
@@:
	mov	ax,bx		; Return segment addr
	ret
UMBALLOC ENDP
;
comment|
/*-asm-*/  int pascal far umbfree(unsigned short umbseg);
|
;=======================================================================
;
;	umbfree - Free an Upper Memory Block.
;
;	Copyright (c) 1990 ACL Engineering
;
;	#include <xmsinfo.h>
;
;	int pascal far umbfree(unsigned short umbseg);
;
;	returns:	 1 if successful
;			 0 otherwise
;
;=======================================================================
;

UMBFREE PROC umbseg:word
	mov	ah,11h		; Request Upper Memory Block
	mov	dx,umbseg	; Segment address
	call	[XMSControl]
				; AX = status
	ret
UMBFREE ENDP
;
	end

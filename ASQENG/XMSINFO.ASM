;' $Header:   P:/PVCS/MAX/ASQENG/XMSINFO.ASV   1.1   30 May 1997 14:58:44   BOB  $
	 TITLE	 XMSINFO
	 page	 58,122
	 name	 XMSINFO

COMMENT|		Module Specifications

Copyright:  Copyright (c) 1990-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE.

Link requirements:  None.

Original Code by:  Alan C. Lindsay, August 1990

Modifications by:  Henry Groover, June 1993.

|
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
;	#include <xmsinfo.h>
;
;	int pascal far xmsparm(XMSPARM far *parm);
;
;	returns:	 0 if successful
;		      0x80 if not installed
;		      0x81 if VDISK (or Weitek) running
;
;=======================================================================
;
XMS_PARM STRUC
FLAG	 dw	?	; 0 if XMS installed, 80h if not, 81h if VDISK
VERSION  dw	?	; XMS version number
DRIVER	 dw	?	; Driver version number
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
	les	di,parm 	; Point to parameter block
	mov	ax,0
	mov	cx,size XMS_PARM
	rep	stosb		; Clear the entire parameter block
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
	les	di,parm 	; Point to parameter block again
;
;	Version
;
	mov	ah,00h		; Get XMS version number
	call	[XMSControl]
	mov	es:[di].VERSION,ax	; XMS version number
	mov	es:[di].DRIVER,bx	; Driver revision number
	mov	es:[di].HMAEXIST,dx	; HMA exists flag
;
;	HMA
;
	cmp	dx,1			; Does HMA exist
	jne	NO_HMA			; ...nope
;
	mov	ah,01h			; HMA exists, ask for it
	mov	dx,0ffffh		; ...application program
	call	[XMSControl]
	or	ax,ax			; Check return
	jnz	GOT_HMA
	cmp	bl,81h			; VDISK present
	jnz	NO_HMA
	jmp	ERR_VDISK		; ..bag it
;
GOT_HMA:
	mov	ah,02h			; We got it, release it
	call	[XMSControl]
	mov	ax,1			; Flag HMA available
	mov	es:[di].HMAAVAIL,ax	; HMA available flag
NO_HMA:
;
;	A20 line
;
	mov	ah,07h		; Query A20
	call	[XMSControl]
	cmp	bl,0		; Function succeded?
	jz	A20_OK		; ..yes
;
	cmp	bl,81h		; VDISK present?
	jnz	A20_OK
	jmp	ERR_VDISK	; ..bag it
A20_OK:
	mov	es:[di].A20STATE,ax	; A20 state
;
;	EMB's
;
	mov	ah,08h		; Query free extended memory
	call	[XMSControl]
	or	ax,ax		; Check return
	jnz	@F		; != 0, must be ok
;
	test	bl,80h		; == 0, check for error
	jnz	@F		; ..no error
	cmp	bl,81h		; VDISK present?
	jz	ERR_VDISK	; ..bag it
@@:
	mov	es:[di].EMBTOTAL,dx	; Total free
	mov	es:[di].EMBAVAIL,ax	; Largest available
;
	mov	ah,09h		; Allocate EMB Handle
	mov	dx,0		; Smallest we can ask for
	call	[XMSControl]
	or	ax,ax		; Check return status
	jnz	@F		; If ok
;
	cmp	bl,81h		; VDISK present?
	jz	ERR_VDISK	; ..bag it
	jmp	NO_HANDLE
@@:
	mov	ah,0Eh		; Get EMB Handle information
	push	dx		; DX = handle
	call	[XMSControl]
	pop	dx		; # kb came back in dx.
	or	ax,ax		; Check for errors
	jnz	@F
	cmp	bl,81h		; VDISK present?
	jz	ERR_VDISK	; ..bag it
	jmp	NO_EMBHAND
@@:
	mov	ah,0
	mov	al,bl		; BL = number of free handles
	inc	ax		; Factor in our handle
	mov	es:[di].EMBHAND,ax ; Handles free
NO_EMBHAND:
	mov	ah,0Ah		; Free our EMB Block
				; DX = handle
	call	[XMSControl]
NO_HANDLE:
;
;	UMB's
;
	mov	ah,10h		; Try to allocate a UMB
	mov	dx,0ffffh	; Ask for the world
	call	[XMSControl]
	cmp	bl,0B0h 	; We should always get this error
	jnz	@F		; if not, assume no UMB memory
	mov	es:[di].UMBAVAIL,dx	; Largest available
	mov	es:[di].UMBTOTAL,dx	; This is a lie...
@@:
	mov	ax,0		; Flag success
	jmp	ALL_DONE
;
NOT_INST:
	les	di,parm 	; Point to parameter block
	mov	ax,80h		; Return not installed
	mov	es:[di].FLAG,ax ; Flag not installed
;
	jmp	ALL_DONE
;
ERR_VDISK:
	les	di,parm 	; Point to parameter block
	mov	ax,81h		; Flag VDISK present
	mov	es:[di].FLAG,ax ; Flag not installed
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
/*-asm-*/  unsigned short pascal far umbtavail(void);
|
;=======================================================================
;
;	umbtavail - Determine total available XMS UMB space.
;
;	Copyright (c) 1993 Qualitas, Inc.
;
;	#include <xmsinfo.h>
;
;	unsigned short pascal far umbtavail(void);
;
;	returns:	 total free paragraphs
;
;=======================================================================
;

UMBTAVAIL PROC uses di
; Note that we can have only 8 high DOS regions, but UMB loaders that
; free their environments (like SMARTDRV) can make Swiss cheese...
Local	UMBPara[32]:WORD	; UMBs allocated to determine total free
Local	UMBTPara:WORD		; Total paras
Local	UMBCount:WORD		; Total allocated

	sub	di,di		; Initialize UMBPara index
	mov	UMBTPara,di	; Initialize total available
	mov	UMBCount,di	; Initialize allocation count

; In case we're in an environment where UMBs are not supported (such
; as HIMEM.SYS), try to allocate a 1-paragraph UMB.  If it fails, we
; can assume 1. there are no UMBs available, or 2. UMBs are not supported.
; In either case we're correct to return 0.
	mov	ah,10h		; Request Upper Memory Block
	mov	dx,1		; Smallest possible request
	call	[XMSControl]	; Return AX=1 if supported, BX=segment
	cmp	ax,1		; Is the function supported, and are there any?
	jne	short UTA_EXIT	; Jump if not

	mov	ah,11h		; Free UMB
	mov	dx,bx		; Get segment of UMB to free
	call	[XMSControl]	; Ignore result in AX
UTA_GETMAX:
	mov	ah,10h		; Request Upper Memory Block
	mov	dx,-1		; Get largest available in DX
	call	[XMSControl]	; Return AX=0, DX=largest block
	add	UMBTPara,dx	; Update total available

	or	dx,dx		; Is there any left?
	jz	short UTA_FREE	; Jump if not

	mov	ah,10h		; Request UMB (again) - DX contains paras
	call	[XMSControl]	; Return BX = segment
	or	ax,ax		; AX=0 if error (???)
	jz	short UTA_FREE	; Something's wrong - bail out

	mov	UMBPara[di],bx	; Save segment
	inc	UMBCount	; Update count of allocated segments
	add	di,type UMBPara ; Skip to next
	cmp	UMBCount,32	; Have we exceeded the limit?
	jb	short UTA_GETMAX ; Go around again if not

UTA_FREE:
; Now that we've figured out what's available, free 'em.
	mov	cx,UMBCount	; Get number of blocks allocated
	jcxz	UTA_EXIT	; Jump if none

	sub	di,di		; Starting index into UMBPara
UTA_FREENEXT:
	mov	ah,11h		; Free UMB
	mov	dx,UMBPara[di]	; Get segment of UMB to free
	call	[XMSControl]	; Ignore result in AX
	add	di,type UMBPara ; Skip to next
	loop	UTA_FREENEXT	; Go around again

UTA_EXIT:
	mov	ax,UMBTPara	; Return total paras available

	ret			; Return to caller

UMBTAVAIL ENDP
;
comment|
/*-asm-*/  int pascal far umbfree(unsigned short umbseg);
|
;=======================================================================
;
;	umbfree - Free an Upper Memory Block.
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
	mov	ah,11h		; Free Upper Memory Block
	mov	dx,umbseg	; Segment address
	call	[XMSControl]
				; AX = status
	ret
UMBFREE ENDP
;
;
comment|
/*-asm-*/  unsigned short pascal far emballoc(int npara);
|
;=======================================================================
;
;	emballoc - Allocate an Extended Memory Block.
;
;	#include <xmsinfo.h>
;
;	unsigned short pascal far emballoc(int npara);
;
;	returns:	 EMB handle if successful
;			 0 otherwise
;
;=======================================================================
;

EMBALLOC PROC npara:word
	mov	ah,09h		; Allocate Extended Memory Block
	mov	dx,npara	; How much
	call	[XMSControl]
	or	ax,ax		; Status check
	jnz	@F		; If ok
	mov	dx,0		; else, flag error
@@:
	mov	ax,dx		; Return segment addr
	ret
EMBALLOC ENDP
;
comment|
/*-asm-*/  int pascal far embfree(unsigned short embh);
|
;=======================================================================
;
;	embfree - Free an Upper Memory Block.
;
;	#include <xmsinfo.h>
;
;	int pascal far embfree(unsigned short embh);
;
;	returns:	 1 if successful
;			 0 otherwise
;
;=======================================================================
;

EMBFREE PROC embh:word
	mov	ah,0Ah		; Free Extended Memory Block
	mov	dx,embh 	; Segment handle
	call	[XMSControl]
				; AX = status
	ret
EMBFREE ENDP
;
comment|
/*-asm-*/  int pascal far setA20(unsigned short onoff);
|
;=======================================================================
;
;	seta20 - Set the A20 line, return previous state
;
;	#include <xmsinfo.h>
;
;	int pascal far setA20(unsigned short onoff);
;
;	onoff - 1 to enable, 0 to disable
;
;	returns: Previous state of A20 line
;
;=======================================================================
;

SETA20	PROC onoff:word
;
	mov	ah,07h		; Query A20
	call	[XMSControl]
;
	mov	cx,ax		; Save previous = A20 state
;
	mov	ax,onoff	; Fetch on/off flag
	or	ax,ax		; == 0?
	mov	ah,5		; Local Enable A20
	jnz	@F		; Jump if not zero
	mov	ah,6		; Local Disable A20
@@:
	call	[XMSControl]	; Do it
	mov	ax,cx		; Return previous state
	ret
SETA20	ENDP
;
	end

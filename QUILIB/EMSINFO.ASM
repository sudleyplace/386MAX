;' $Header:   P:/PVCS/MAX/QUILIB/EMSINFO.ASV   1.1   30 May 1997 12:09:00   BOB  $
	 TITLE	 EMSINFO - Return assorted EMS information
	 page	 58,122
	 name	 BIOSID

COMMENT|		Module Specifications

Copyright:  Copyright (c) 1990-7 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE.

Link requirements:  None.

Program derived from:  "Advanced MS-DOS Programming",
			Ray Duncan pp. 204-2?? and pp. 615-646

Modifications by:  None.

|
	.MODEL	LARGE,PASCAL
;
;	Local data
;
	.DATA
	ASSUME	DS: DGROUP
DEVNAME DB	'EMMXXXX0',0    ; Guranteed EMS driver name
;
;------------------------------------------------------------------------
;
	.CODE
comment|
/*-asm-*/  int pascal far emsparm(EMSPARM far *parm);
|
;=======================================================================
;
;	emsparm - Get general EMS parameters.
;
;	#include <emsinfo.h>
;
;	int pascal far emsparm(EMSPARM far *parm);
;
;	returns:	 0 if successful
;			 1 if not installed
;			-1 if error
;
;=======================================================================
;
EMS_PARM STRUC
VERSION dw	?	; EMS version number
FRAME	dw	?	; EMS page frame
AVAIL	dw	?	; Available (16k) pages
TOTAL	dw	?	; Total (16k) pages
MPAGES	dw	?	; Mappable physical pages
TOTHAND dw	?	; Total handles supported
ACTHAND dw	?	; Number of active handles
			; Hardware configuration:
RAWSIZE dw	?	; Size of raw pages in paragraphs
AMRS	dw	?	; Number of alternate map register sets
MCSIZE	dw	?	; Size of mapping-context save area in bytes
DMARS	dw	?	; Number of register sets that can be assigned to DMA
DMATYPE dw	?	; DMA operation type
EMS_PARM ENDS


EMSPARM PROC parm:dword
	push	di
;
;	Part I:  Attempt to open EMS driver
;
	lea	dx,DEVNAME
	mov	ax,3d00h	; DOS open file function
	int	21h		; Do it
	jnc	@F
	jmp	NOT_INST	; Error here means not installed
@@:
	; Make sure it's not a file.
	mov	bx,ax		; Handle returned from open
	mov	ax,4400h	; IOCTL, subfunc 00
	int	21h		; Do it
	jnc	@F
	jmp	ERROR1		; Error
@@:
	and	dx,80h		; Bit 7 means char device
	jnz	@F
	jmp	NOT_INST	; else, not installed
@@:
	mov	ax,4407h	; Make sure it's available
	int	21h		; Do it
	or	al,al		; Test device output status
	jnz	@F
	jmp	ERROR1		; If not available
@@:
	mov	ah,3eh		; OK so far, close handle
	int	21h
;
;	Part II:  It's there and it's alive, get version.
;
	mov	ah,40h		; Test EMM status
	int	67h		; Do it
	or	ah,ah
	jnz	ERROR2		; Bailout if bad status
;
	mov	ah,46h		; Get EMM version
	int	67h
	or	ah,ah
	jnz	ERROR2		; Bail out if error
;
	les	di,parm ; Pointer to info struct
	mov	es:[di].VERSION,ax	; Store version number

	mov	ah,41h		; Get page frame segment
	int	67h
	or	ah,ah
	jz	short @F	; Jump if OK

	sub	bx,bx		; EMS services but no page frame (NOFRAME)
@@:
;
	mov	es:[di].FRAME,bx ; Frame seg returned in bx

	mov	ah,42h		; Get number of pages
	int	67h
	or	ah,ah
	jnz	ERROR2		; If error
;
	mov	es:[di].AVAIL,bx ; Available pages returned in bx
	mov	es:[di].TOTAL,dx ; Total pages returned in dx
;
	mov	ah,4bh		; Get handle count
	int	67h
	or	ah,ah
	jnz	ERROR2		; If error
;
	mov	es:[di].ACTHAND,bx ; Frame seg returned in bx
;
;	!!! EMS 4.0+ Only !!!
	mov	ax,0
	mov	es:[di].TOTHAND,ax	; number of handles
	mov	es:[di].MPAGES,ax	; number of pages
;
	cmp	es:[di].VERSION,40h	; Check version number
	jl	NOT_40
;
	mov	ax,5402h	; Get total handles count
	int	67h
	or	ah,ah
	jnz	ERROR2		; If error
	mov	es:[di].TOTHAND,bx ; BX = number of handles
;
;	!!! EMS 4.0+ Only !!!
	mov	ax,5801h	; Get mappable pages count
	int	67h
	or	ah,ah
	jnz	ERROR2		; If error
	mov	es:[di].MPAGES,cx ; CX = number of pages
;
;	!!! EMS 4.0+ Only !!!
	mov	ax,5900h	; Get hardware configuration
	add	di,RAWSIZE	; ES:DI = pointer to buffer
	int	67h
	or	ah,ah
	jnz	ERROR2		; If error
NOT_40:
	mov	ax,0		; Flag installed
	jmp	ALL_DONE
;
NOT_INST:
	mov	ax,1		; Flag not installed
	jmp	ALL_DONE
;
ERROR1:
	mov	ah,3eh		; Close handle
	int	21h
ERROR2:
	mov	ax,-1		; Flag (unknown) error
	jmp	ALL_DONE
;
ALL_DONE:
	pop	di
	ret

EMSPARM ENDP
;
comment|
/*-asm-*/  int pascal far emshand(EMSHAND far *hand);
|
;=======================================================================
;
;	emshand - Get EMS handle information.
;
;	#include <emsinfo.h>
;
;	int pascal far emshand(EMSHAND far *hand);
;
;	returns:	 Number of handles if successful
;			-1 if error
;
;	!!! EMS 4.0+ Only !!!
;=======================================================================
;
EMSHAND PROC hand:dword
;
	push	di		; Preserve di
;
	mov	ax,5400h	; Get all handle names
	les	di,hand 	; ES:DI = pointer to buffer
	int	67h
	or	ah,ah
	jz	@F		; If no error
	mov	ax,-1
@@:
	pop	di		; Restore di
	ret
;
EMSHAND ENDP
;
comment|
/*-asm-*/  int pascal far emsmap(EMSMAP far *map);
|
;=======================================================================
;
;	emsmap - Get EMS mapping information.
;
;	#include <emsinfo.h>
;
;	int pascal far emshand(EMSMAP far *map);
;
;	returns:	 Number of handles if successful
;			-1 if error
;
;	!!! EMS 4.0+ Only !!!
;=======================================================================
;
EMSMAP	PROC map:dword
;
	push	di		; Preserve di
;
	mov	ax,5800h	; Get addresses of mappable pages
	les	di,map		; ES:DI = pointer to buffer
	int	67h
	or	ah,ah
	jz	@F		; If no error
	mov	cx,-1
@@:
	mov	ax,cx		; CX = page count
	pop	di		; Restore di
	ret
;
EMSMAP	ENDP
;
comment|
/*-asm-*/  int pascal far emshsize(int handle);
|
;=======================================================================
;
;	emshsize - Get number of pages allocated to an EMS handle.
;
;	#include <emsinfo.h>
;
;	int pascal far emshsize(int handle);
;
;	returns:	 Number of pages if successful
;			-1 if error
;
;=======================================================================
;
EMSHSIZE PROC handle:word
;
	push	di		; Preserve di
;
	mov	ax,4c00h	; Get handle pages
	mov	dx,handle
	int	67h
	or	ah,ah
	jz	@F		; If no error
	mov	bx,-1
@@:
	mov	ax,bx		; CX = page count
	pop	di		; Restore di
	ret
;
EMSHSIZE ENDP
;
comment|
/*-asm-*/  int pascal far emsalloc(unsigned npages);
|
;=======================================================================
;
;	emsalloc - Allocate EMS pages.
;
;	#include <emsinfo.h>
;
;	int pascal far emsalloc(unsigned npages);
;
;	returns:	 EMS handle if successful
;			 0 if error
;
;=======================================================================
;
EMSALLOC PROC npages:word
;
	mov	ax,4300h	; Allocate handle and pages
	mov	bx,npages
	int	67h
	or	ah,ah
	jz	@F		; If no error
	mov	dx,0
@@:
	mov	ax,dx		; DX = handle
	ret
;
EMSALLOC ENDP
;
comment|
/*-asm-*/  int pascal far emsfree(int handle);
|
;=======================================================================
;
;	emsfree - Free EMS pages.
;
;	#include <emsinfo.h>
;
;	int pascal far emsfree(int handle);
;
;	returns:	 0 if successful
;
;=======================================================================
;
EMSFREE PROC handle:word
;
	mov	ax,4500h	; Free handle and pages
	mov	dx,handle
	int	67h
	or	ah,ah
	jz	@F		; If no error
	mov	al,ah
	mov	ah,0
@@:
	ret
;
EMSFREE ENDP
;
	end

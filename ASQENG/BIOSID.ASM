;' $Header:   P:/PVCS/MAX/ASQENG/BIOSID.ASV   1.1   30 May 1997 14:58:38   BOB  $
	 title	 BIOSID -- Get BIOS Identification
	 page	 58,122
	 name	 BIOSID

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1989-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE.

Link requirements:  None.

Program derived from:  CAPTURE.ASM.

Original code by:  John E. Swanke, 1989.

Modifications by:  Alan C. Lindsay, 1990.

|

	 .MODEL  LARGE,PASCAL
.xlist
	 include MASM.INC
	 include BIOSCONF.INC
	 include BITFLAGS.INC
.list

	 .DATA

ID_BLOCK STRUC
; This is the parameter block that's passed back to the caller.
; So don't mess with it.
;
; (!):	These fields USED to be set by bios_id, and now are set by other
;	code.
;
BIOMODEL db	 ?		; BIOS model #
SUBMODEL db	 ?		; ...  submodel #
REVISION db	 ?		; ...  revision #
BITDEF	 db	 ?		; ...  bit definitions
BUS_FLAG db	 ?		; (!) Bus / 'Real IBM' flag
N_CRC	 db	 ?		; (!) 64 or 128
BIOS_CRC dw	 ?		; (!) CRC of BIOS
SYS_ID	 dw	 ?		; System Board ID for MCA's
XB_SEG	 dw	 ?		; XBIOS segment, if any */
XB_SIZE  dw	 ?		; XBIOS segment, if any */
ROMDATE  db	10 dup (?)	; Rev date from BIOS ROM
I15_PTR  dd	 ?		; Pointer to raw INT 15h data
; That's the end of the parameter block
ID_BLOCK ENDS

IDBLK	 ID_BLOCK <>

; Where to check for EISA bus signature (i.e. 'EISA' @ F000:0FFD9)
EISASIGN equ	0FFD9h
EISATEXT db	'EISA'
EISATEXT_LEN equ $-EISATEXT

	 .CODE
BIOS_ID  proc	 parms:dword	; Far pointer to parameter block

COMMENT|

	This routine collects:

	BIOS model and submodel codes
	Flag to indicate EISA bus
|

	 push	 si		; Make compiler happy
	 push	 di		; Since it uses these for register variables

	 push	 ds
	 pop	 es		; ES = DS
	 mov	 di,offset IDBLK ; Point to ID block
	 xor	 ax,ax
	 mov	 cx,SIZE IDBLK
	 rep	 stosb

	 assume  es:nothing	; Tell the assembler to forget it

; Check for EISA (i.e. 'EISA' @ F000:0FFD9)

	 mov	 ax,0F000h
	 mov	 es,ax		; Where to look
	 mov	 di,EISASIGN	; ES:DI ==> place where signature should be

	 lea	 si,EISATEXT	; DS:SI ==> local copy of it
	 mov	 cx,EISATEXT_LEN ; # bytes in signature
    repe cmpsb			; Compare 'em
	 jne	 short @F	; Jump if not EISA
	 or	 IDBLK.BUS_FLAG,02h
@@:

; Obtain configuration data

	 xor	 ax,ax		; Init int 15 pointer
	 mov	 word ptr IDBLK.I15_PTR,ax
	 mov	 word ptr IDBLK.I15_PTR+2,ax

	 mov	 ah,0C0h	; Function to get BIOS configuration data
	 int	 15h		; Request system services
	MJ c,	 NO_INT15	; Jump if not supported

	 mov	 word ptr IDBLK.I15_PTR,bx
	 mov	 ax,es		; Save pointer to int 15 param block
	 mov	 word ptr IDBLK.I15_PTR+2,ax

	 mov	 al,es:[bx].CFG_MODEL ; Get the major model #
	 mov	 IDBLK.BIOMODEL,al	; Save for later use

	 mov	 al,es:[bx].CFG_TYPE	; Get the submodel #
	 mov	 IDBLK.SUBMODEL,al	; Save for later use

	 mov	 al,es:[bx].CFG_LEVEL	; Get the revision #
	 mov	 IDBLK.REVISION,al	; Save for later use

	 mov	 al,es:[bx].CFG_PARMS	; Get the bit definitions
	 mov	 IDBLK.BITDEF,al	; Save for later use
	 jmp	 GET_XBSEG	; Join common code
;
NO_INT15:			; No support for INT 15, do what we can.
	 mov	 ax,0F000h
	 mov	 es,ax
	 mov	 bx,0FFFEh
	 mov	 al,es:[bx]	; Grab model code direct from ROM
	 mov	 IDBLK.BIOMODEL,al	; Save for later use

	 xor	 ax,ax			; Zero out everything else
	 mov	 IDBLK.SUBMODEL,al	; Save for later use
	 mov	 IDBLK.REVISION,al	; Save for later use
	 mov	 IDBLK.BITDEF,al	; Save for later use

;
;	Get XBIOS segment
;
GET_XBSEG:
	 xor	 ax,ax
	 mov	 IDBLK.XB_SEG,ax	; Assume there's none
	 mov	 IDBLK.XB_SIZE,ax	; Assume there's none
	 mov	 ah,0C1h		; Get Extended BIOS Data Area
	 int	 15h			; Do it
	 jc	 GET_DATE		; ...didn't work.
	 mov	 ax,es			; Segment returned in ES
	 mov	 dx,es:[0]		; If seg is good, this is XBIOS size
	 mov	 bx,40h
	 mov	 es,bx
	 cmp	 es:[0Eh],ax		; Compare with value in BIOS data area
	 jnz	 GET_DATE		; If no match, assume bogus
	 mov	 IDBLK.XB_SEG,ax	; Otherwise, store it.
	 mov	 IDBLK.XB_SIZE,dx	; ..and it's size.
;
; Get BIOS date
;
GET_DATE:
	 push	 ds		; Copy 10 bytes from F000:FFF5
	 pop	 es		; (that's 2 bytes extra on purpose)
	 mov	 ax,0F000h
	 mov	 ds,ax
	 mov	 si,0FFF5h
	 mov	 di,offset IDBLK.ROMDATE
	 mov	 cx,5
	 rep	 movsw
	 push	 es
	 pop	 ds

; If it's MCA, get the system board ID

	 mov	 IDBLK.SYS_ID,0 ; Assume not MCA
	 test	 IDBLK.BITDEF,@CFG_MCA ; Izit MCA?
	 jz	 short NOTMCA	; Jump if not

;	 call	 GET_SYSID	; Return with system board ID in AX

NOTMCA:
	 les	 di,parms		; Get pointer to parameter block
	 lea	 si,IDBLK		; First variable in block
	 mov	 cx,size ID_BLOCK	; How much to move
	 rep	 movsb			; Do it.

	 pop	 di			; Restore things for C
	 pop	 si

	 ret

BIOS_ID endp			; End BIOS_ID procedure

GET_SYSID proc near	; Get System Board ID
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Get system board ID

On exit:

AX	 =	 system board ID

|

	 REGSAVE <dx>		; Save register

	 cli			; Disallow interrupts

; Put system board into setup mode

	 in	 al,94h 	; Get current system board setup register
	 jmp	 short $+2	; I/O delay

	 and	 al,not @BIT7	; Clear enable bit
	 out	 94h,al 	; Put system board into setup mode
	 jmp	 short $+2	; I/O delay

; Read system board ID

	 mov	 dx,101h	; Adapter ID MSB register
	 in	 al,dx		; Get MSB of adapter ID
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Save for later use
	 dec	 dx		; Skip to adapter LSB register

	 in	 al,dx		; Get LSB of adapter ID
	 jmp	 short $+2	; I/O delay

; Put system board into enable mode

	 push	 ax		; Save for a moment

	 in	 al,94h 	; Get current system board setup register
	 jmp	 short $+2	; I/O delay

	 or	 al,@BIT7	; Set enable bit
	 out	 94h,al 	; Put system board into setup mode
;;;;;;;; jmp	 short $+2	; I/O delay

	 pop	 ax		; Restore

	 sti			; Allow interrupts

	 REGREST <dx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GET_SYSID endp			; End GET_SYSID procedure
;
	 end			; End of module

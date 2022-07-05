;' $Header:   P:/PVCS/MAX/ASQENG/FLEXROMS.ASV   1.1   30 May 1997 14:58:38   BOB  $
	 title	 FLEXROM -- Get Flexxed ROM information
	 page	 58,122
	 name	 FLEXROM

COMMENT|		Module Specifications

int pascal far get_flexroms(void far *stuff);

Copyright:  (C) Copyright 1991-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE.

Link requirements:  None.

Program derived from:  Code fragments from Marc.

Modifications by:  Alan C. Lindsay, 1991.

|

	 .MODEL  LARGE,PASCAL
.xlist
	 include MASM.INC
;	 include BIOSCONF.INC
;	 include BITFLAGS.INC
	 include PTR.INC
	 include DOSCALL.INC
	 include IOCTL.INC
.386p
	 include DTE.INC
.8086

	 include EMM2CALL.INC
	 include QMAX_CTL.INC
	 include QMAX_FLX.INC
	 include QMAX_DBG.INC
.list

	 .DATA


LDTBUF	 MDTE_STR <0,0,0,0,0,0> ; block move descriptor table


COMMENT |

Data needed for detection of 386MAX

|

	 public  DEVNAME_MAX
DEVNAME_MAX  db  '386MAX$$',0   ; Our device driver name

; The lowest version of 386max we can tolerate
MAXVERS_H equ '5'       ; High version # ?
MAXVERS_T equ '1'       ; Mid-digit of version #
MAXVERS_U equ '3'       ; Low-digit of version #

	 public DEV_HNDL
DEV_HNDL dw	?	; Handle to above device

	public	PORT67
PORT67	 dw	 ?		; I/O port for backdoor functions


	 public  INFO_CTL,INFO,INFOSIZE
	 include QMAXINFO.INC
	 db	 ?		; Force even alignment for INFO_STR
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR


	 .CODE

GET_FLEXROMS proc stuff:dword	; Far pointer to parameter block

	LOCAL retax:word	; Return value

COMMENT|

Get @EMM2_FLEXINFO data into far pointer and return number of
records returned.  Return -3 if none or MAX not present.

|

	 mov	 retax,-3	; Assume failure

	 call	 MAX_PRESENT	; Is anybody home?
	MJ c	 FLEX_ERR	; Jump if not

	 ; Get MAX's FLEXROM table.
.386
	 pushad 		; Save

	 EMMOUT @EMM2_FLEXINFO	; Get FLEXINFO physical address
				; BX = FLEXROM_FLAG (bits in QMAX_FLX.INC)
				; CX = number of records
				; EDX = physical address (?)

	 or	 ah,ah		; Did the call fail?
	 jnz	 near ptr FLEX_NOTSUPP ; Jump if so

	 test	 bx,@FR_ACTIVE	; Is there any flexing of ROMS?
	 jz	 near ptr FLEX_NOTSUPP ; Jump if not

	 or	 cx,cx		; Are there any FLEXROM records?
	 jz	 near ptr FLEX_NOTSUPP ; Jump if not

;;;;	 mov	 edx,edx	; Physical address already in edx
	 EMMOUT @EMM2_PHYS2LIN	; Get linear address into edx

	 or	 ah,ah		; Did the call succeed?
	 jnz	 near ptr FLEX_NOTSUPP ; Jump if not

; Get state of DEBUG=XR bit.  Set if needed.

	 test	 INFO.INFO_DBG,@DBG_XR ; Are block moves to pgm region allowed?
	 jnz	 short @F	; Yes, so skip the EMM2CALL

	 mov	 bx,@DBG_XR	; Bit we want to toggle (set) in DBGFLAG
	 EMMOUT  @EMM2_DBGFLAG	; Toggle the bit
@@:
; Set up block move GDT using EDX.
	 mov	 LDTBUF.MDTE_DS.DESC_BASE01,dx ; Set bytes 0-1 of base
	 shr	 edx,16 	; Get high word of base
	 mov	 LDTBUF.MDTE_DS.DESC_BASE2,dl ; Set byte 2 of base
	 mov	 LDTBUF.MDTE_DS.DESC_BASE3,dh ; Set high byte of base
	 imul	 ax,cx,@FLEXROM_STRLEN ; AX = bytes to copy
	 dec	 ax		; Convert to limit
	 mov	 LDTBUF.MDTE_DS.DESC_SEGLM0,ax ; Set low word of limit
;;;;;;;  mov	 LDTBUF.MDTE_DS.DESC_SEGLM1,0 ; Clear high word ...
	 mov	 LDTBUF.MDTE_DS.DESC_ACCESS,CPL0_DRO ; Read only data

	 sub	 ebx,ebx	; Clear high word of offset
	 les	 bx,stuff	; Address buffer
	 assume  es:nothing	; Tell the assembler

	 sub	 edx,edx	; Clear high order word of segment
	 mov	 dx,es		; Get destination segment
	 shl	 edx,4-0	; Convert paras to bytes
	 add	 edx,ebx	; Get linear address of destination
	 mov	 LDTBUF.MDTE_ES.DESC_BASE01,dx ; Set bytes 0-1 of base
	 shr	 edx,16 	; Get high word of base
	 mov	 LDTBUF.MDTE_ES.DESC_BASE2,dl ; Set byte 2 of base
	 mov	 LDTBUF.MDTE_ES.DESC_BASE3,dh ; Set high byte of base (0)
	 mov	 LDTBUF.MDTE_ES.DESC_SEGLM0,ax ; Set low word of limit
;;;;;;;  mov	 LDTBUF.MDTE_ES.DESC_SEGLM1,0 ; Clear high word ...
	 mov	 LDTBUF.MDTE_ES.DESC_ACCESS,CPL0_DATA ; Read/write data

;;;;;;;
;;;;;;;  mov	 ax,seg DGROUP:LDTBUF ; Pointer to LDT buffer
;;;;;;;  mov	 es,ax
;;;;;;;  mov	 si,offset LDTBUF
;;;;;;;
;;;;;;;  ; It's important to do this first, since it writes one more
;;;;;;;  ; byte than it's supposed to.
;;;;;;;  mov	 es:[si+12h],edx; Store source extended memory address
;;;;;;;
;;;;;;;  mov	 ax,word ptr (stuff+2) ; Pick up destination segment
;;;;;;;  mov	 dx,16		; Convert to linear address
;;;;;;;  mul	 dx
;;;;;;;  add	 ax,word ptr (stuff)
;;;;;;;  adc	 dx,0
;;;;;;;
;;;;;;;  mov	 es:[si+1ah],ax ; store destination address
;;;;;;;  mov	 es:[si+1ch],dl
;;;;;;;
;;;;;;;  ; Store access rights bytes
;;;;;;;  ; This will overwrite the extra byte mentioned above
;;;;;;;  mov	 byte ptr es:[si+15h],93h
;;;;;;;  mov	 byte ptr es:[si+1dh],93h
;;;;;;;
;;;;;;;  mov	 ax,cx		; Calculate byte count for transfer
;;;;;;;  mov	 dx,@FLEXROM_STRLEN
;;;;;;;  mul	 dx
;;;;;;;  mov	 es:[si+10h],ax ; Store byte count into descriptors
;;;;;;;  mov	 es:[si+18h],ax
;;;;;;;
	 REGSAVE <cx,fs,gs>	; Hold count for return

	 push	 ds		; Prepare to address DGROUP
	 pop	 es		; Address for block move
	 assume  es:DGROUP	; Tell the assembler

	 lea	 si,LDTBUF	; ES:SI ==> block move GDT
	 mov	 cx,ax		; Limit in bytes
	 add	 cx,2		; Convert to count and round up for conversion
	 shr	 cx,1-0 	; Convert bytes to words
	 mov	 ah,87h 	; Int 15H Fxn 87h = block move
	 int	 15h		; Just Do It

	 assume  fs:nothing,gs:nothing ; This is not necessarily true since
				; the BIOS won't see this call...

	 REGREST <gs,fs,cx>	; Restore
	 assume  fs:nothing,gs:nothing ; Tell the assembler

	 push	 ax		; Save result in AH

; Clear the DEBUG=XR bit if we set it earlier

	 test	 INFO.INFO_DBG,@DBG_XR	; Was it already set?
	 jnz	 short @F	; Yes, so don't clear it

	 mov	 bx,@DBG_XR	; Bit we want to toggle (clear) in DBGFLAG
	 EMMOUT  @EMM2_DBGFLAG	; Toggle the bit
@@:
	 pop	 ax		; Restore result of BIOS block move

	 or	 ah,ah		; Did the call succeed?
	 jnz	 short FLEX_NOTSUPP ; Jump if not

	 mov	 retax,cx	; Prepare to return record count
;;;;;;;  jmp	 FLEX_EXIT386	; Join common exit

FLEX_NOTSUPP:
FLEX_EXIT386:
	 popad			; Restore
.8086
FLEX_ERR:
	 mov	 ax,retax	; Get return value

	 ret			; Return to caller

GET_FLEXROMS endp


	 NPPROC  MAX_PRESENT -- Check for 386MAX device presence
	 assume  ds:DGROUP,es:nothing,ss:nothing

COMMENT |

Determine if MAX is present.
Also check against minimum version number, and get PORT67 address.

|

	 REGSAVE <ax,bx,cx,dx>	; Save caller's registers

	 mov	 al,02h 	; R/W access
	 DOSCALL @OPENF2,DEVNAME_MAX ; Attempt to open 386MAX device driver
	 jnc	 short MP_OK1	; Skip error code if open

MP_NOMAX:
	 mov	 ax,-1		; Signal 386MAX.SYS is not present

	 jmp	 near ptr MP_ERRXIT ; Join common error exit code

MP_BADVER:
	 mov	 ax,-2		; Signal 386MAX.SYS is too old
	 jmp	 near ptr MP_ERRXIT ; Join common error exit code
MP_OK1:

; Ensure it's a device

	 mov	 DEV_HNDL,ax	; Save for later use
	 mov	 bx,ax		; Move handle to proper register

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 short MP_NOMAX ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short MP_NOMAX ; No???

; Get QMAXINFO structure

	 mov	 al,02h 	; Read from device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

; Make sure its us and versions are in order

	 cmp	 INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short MP_NOMAX ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short MP_NOMAX ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short MP_NOMAX ; Not this time

	 cmp	 INFO.INFO_VER[0],MAXVERS_H ; Ok high version # ?
	 jl	 short MP_BADVER ; Not this time

	 mov	 al,MAXVERS_T	; Get mid-digit of version #
	 mov	 ah,MAXVERS_U	; Get low-digit of version #

	 cmp	 ax,INFO.INFO_VER.ELO[2] ; Ok low numbers?
	 jl	 short MP_BADVER ; Not this time

	 mov	 ax,INFO.INFO_P67 ; I/O port number for EMM2 functions
	 mov	 PORT67,ax	; Save for EMMOUT macro

	 clc			; Indicate all went well
MP_XIT:
	 REGREST <dx,cx,bx,ax>	; Restore caller's registers

	 ret			; ... to caller

MP_ERRXIT:
	 stc			; Indicate something failed
	 jmp	 short MP_XIT	; Join common return code


	 assume  ds:nothing,es:nothing,ss:nothing
MAX_PRESENT endp		; End of MAX_PRESENT routine

	 MEND

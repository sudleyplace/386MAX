;' $Header:   P:/PVCS/MAX/QUILIB/MCA_POS.ASV   1.1   30 May 1997 12:09:04   BOB  $
	 title	 POS -- Programmable Option Select Display
	 page	 58,122
	 name	 POS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1990-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Microsoft conventions using .MODEL, .DATA and .CODE

Link requirements:  None

Program derived from:  POS.ASM.

Original code by:  Bob Smith, February, 1990.

Modifications by:  Alan C. Lindway, August 1990.

|

	 .MODEL LARGE,PASCAL

.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include BIOSCONF.INC
	 include BITFLAGS.INC
	 include ASCII.INC
	 ;include VERSION.INC

	 include QMAX_POS.INC
.list

	 .DATA

	 public  MCAID
MCAID	 MCA_STR @MAXPOSDEV dup (<?>) ; MCA adapter IDs

	 public  POSBASE
POSBASE  dw	 ?		; POS base address

	 .CODE

	 extrn	 _Is_MCA:proc

MCA_POS  PROC	 PARMS:DWORD	; Pointer to parameter block
				; Function returns:  0 if successful.

	 push	 si		; Preserve SI and DI
	 push	 di
	 push	 ds		; Make sure ES == DS
	 pop	 es

; Ensure this is an MCA

	 call	 _Is_MCA	; Izit an MCA?
	 mov	 ax,1		; Prep for negative return
	 jc	 short POS_EXIT ; Jump if not

; Read in the adapter IDs and POS values

	 call	 READID 	; Read 'em in
	 jnc	 short @F	; Jump if no error

	 mov	 ax,1		; Indicate failure
	 jmp	 short POS_EXIT ; Join common exit code

@@:
; Display the adapter IDs and POS values

	 les	 di,parms		; Get pointer to parameter block
	 lea	 si,MCAID		; First variable in block
	 mov	 cx,@MAXPOSDEV * (size MCA_STR / 2) ; How much to move
	 rep	 movsw			; Do it.
	 mov	 ax,0			; Flag success

POS_EXIT:
	 pop	 di		; Restore DI and SI
	 pop	 si
	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,ss:nothing

MCA_POS  endp			; End POS procedure
	 NPPROC  READID 	; -- Read System And Adapter IDs And POS Values
	 assume  ds:DGROUP,es:DGROUP,ss:nothing
COMMENT|

Read in system board and adapter IDs and POS values

On exit:
CF=0	 Success
CF=1	 Failure (call to get POS base address failed)

|

	 REGSAVE <ax,bx,cx,dx,di> ; Save registers

	 mov	 ax,0C400h	; Get POS base address
	 int	 15h		; Request BIOS services
	 jc	 short READID_EXIT ; Jump if error

	 mov	 POSBASE,dx	; Save for later use

; Read in system board ID

	 mov	 cx,@MAXPOSDEV	; Get # slots
	 mov	 bl,0		; Start with slot #0
	 lea	 di,MCAID	; ES:DI ==> adapter ID save area
READID_NEXT:
	 cli			; Disallow interrupts

	 cmp	 bl,0		; Izit system board?
	 jne	 short READID_XSYS1 ; Jump if not

; Put system board into setup mode

	 in	 al,94h 	; Get current system board setup register
	 jmp	 short $+2	; I/O delay

	 and	 al,not @BIT7	; Clear enable bit
	 out	 94h,al 	; Put system board into setup mode
;;;;;;;; jmp	 short $+2	; I/O delay

	 jmp	 short READID_COM1 ; Join common code

; Put adapter into setup mode

READID_XSYS1:
	 mov	 al,bl		; Copy to I/O register
	 dec	 al		; Convert to origin-0
	 or	 al,@BIT3	; Select channel setup
	 out	 96h,al 	; Put into setup mode
	 jmp	 short $+2	; I/O delay

; Read adapter/system board ID

READID_COM1:
	 mov	 dx,POSBASE	; Adapter ID LSB register
	 in	 al,dx		; Get LSB of adapter ID
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Save for later use
	 inc	 dx		; Skip to adapter MSB register

	 in	 al,dx		; Get MSB of adapter ID
	 jmp	 short $+2	; I/O delay

	 xchg	 al,ah		; Swap to comparison order
	 stos	 MCAID.MCA_AID	; Save as adapter ID

; Read in the POS values

	 push	 cx		; Save outer count value

	 mov	 cx,4		; Get # POS values
@@:
	 inc	 dx		; Skip to POS[n]
	 in	 al,dx		; Get POS[n]
;;;;;;;; jmp	 short $+2	; I/O delay

	 stos	 MCAID.MCA_POS0 ; Save as POS[n] value

	 loop	 @B		; Jump if more POS values to read

	 pop	 cx		; Restore

; Read in subaddress extension

	 inc	 dx		; Skip to subaddress extension low-byte
	 in	 al,dx		; Get the value
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Save for later use
	 inc	 dx		; Skip to subaddress extension high-byte
	 in	 al,dx		; Get the value
	 jmp	 short $+2	; I/O delay

	 xchg	 al,ah		; Swap to comparison order
	 stos	 MCAID.MCA_SUBA ; Save as subaddress extension

	 cmp	 bl,0		; Izit system board?
	 jne	 short READID_XSYS2 ; Jump if not

; Put system board into enable mode

	 in	 al,94h 	; Get current system board setup register
	 jmp	 short $+2	; I/O delay

	 or	 al,@BIT7	; Set enable bit
	 out	 94h,al 	; Put system board into setup mode
;;;;;;;; jmp	 short $+2	; I/O delay

	 jmp	 short READID_COM2 ; Join common code

; Put adapter into enable mode

READID_XSYS2:
	 mov	 al,0		; Disable channel setup
	 out	 96h,al 	; No position selected
;;;;;;;; jmp	 short $+2	; I/O delay
READID_COM2:
	 sti			; Allow interrupts

	 inc	 bl		; Skip to next slot #

	 loop	 READID_NEXT	; Jump if more adapters to check

READID_EXIT:
	 REGREST <di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

READID	 endp			; End READID procedure

	 end			; End of module

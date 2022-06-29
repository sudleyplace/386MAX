;' $Header:   P:/PVCS/MAX/QUILIB/C_TLOAD.ASV   1.1   30 May 1997 12:09:00   BOB  $
	 title	 C$TLOAD -- CHIPSet Subroutines
	 page	 58,122
	 name	 C$TLOAD

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE

Link requirements:  None.

Program derived from:  Itself.

Original code by:  Bob Smith, March 1988.

Modifications by:  Alan C. Lindsay, August 1990.

|

	 .MODEL LARGE,PASCAL
.xlist
	 include MASM.INC
	 include 8259.INC
	 include BITFLAGS.INC
.list

	 .CODE

CHECK_CHIPSET PROC	; Check on C and T CHIPSets

COMMENT|

Attempt to determine whether or not this system supports the 82C302,
82C307, or 82C212 by writing to I/O port 21h and checking to see if
the same value appears at I/O port 23h.

On exit:

CF	 =	 0 either 82C302, 82C307, or 82C212 appears to be present
	 =	 1 neither is present
If CF = 0,
CX	 =	 0 if 82C302 or 82C307
	 =	 1 if 82C212
If CF = 1,
CX	 =	 0 if no compatible CHIPSet present
	 =	 1 if NEAT CHIPSet with < 1MB
	 =	 2 if VLSI

Fixes for calling from C language:  Add 100h to return value if carry
bit not set.  --ACL.

|

	 REGSAVE <ax,bx>	; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

; First ensure that I/O ports 22h and 23h are not decoded as
; I/O ports 20h and 21h.

; Register usage:
;
; AL	 =	 scratch
; BL	 =	 original value from I/O port 21h
; BH	 =	 original value from I/O port 23h
; AH	 =	 second   value from I/O port 23h

	 in	 al,@IMR	; Get and save the I/O port
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 mov	 bl,al		; Save to restore later

	 in	 al,@CT_DATA	; Get the I/O port
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 not	 al		; Complement the value so it's different
	 mov	 bh,al		; Save to compare

	 out	 @IMR,al	; Change the IMR
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CT_DATA	; Get and save the I/O port
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Save to compare
	 mov	 al,bl		; Get original value of IMR

	 out	 @IMR,al	; Restore it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 popf			; Restore flags

	 cmp	 ah,bh		; Compare original and second values
	 je	 short CHECK_CHIPSET_ERR0 ; Jump if same (thus same I/O ports)

; Note we must check for NEAT first because some systems (like the
; Packard-Bell laptop RJB brought in) responds to both register
; 64h and 08h, but it's a NEAT CHIPSet.

; If it's the 82C212, then Register 64h has bit 7 = 0

	 mov	 al,64h 	; 82C212 register
	 call	 READ_CHIPSET	; Read data from CHIPSet into AH

; The VLSI CHIPSet (as on the NEC SX Plus) returns all zeros for out of bound
; AT/386 registers so we must weed them out here

	 cmp	 ah,0		; Ensure some bits set
	 je	 short CHECK_CHIPSET_VLSI ; Jump if VLSI

	 test	 ah,@BIT7	; Ensure it's clear
	 jz	 short CHECK_CHIPSET_NEAT ; Jump if it is

; If it's the 82C302 or 82C307, then Register 08h has bit 7 = 0

CHECK_CHIPSET_XNEAT:
	 mov	 al,08h 	; 82C302/82C307 register
	 call	 READ_CHIPSET	; Read data from CHIPSet into AH

	 xor	 cx,cx		; Assume it's the 82C302/82C307

	 test	 ah,@BIT7	; Ensure it's clear
	 jz	 short CHECK_CHIPSET_CLC ; Jump if so

; The 82C307 can be distinguished by reading registers 14h-17h;
; at least one of them should be non-FF

	 mov	 bl,-1		; Initialize to identity element for AND
	 mov	 cx,17h-14h+1	; # registers to read
	 mov	 al,14h 	; First 82C307 bank register
@@:
	 call	 READ_CHIPSET	; Read data from CHIPSet into AH

	 and	 bl,ah		; Include in accumulator

	 inc	 al		; Skip to next register

	 loop	 @B		; Jump if more registers to read

	 cmp	 bl,-1		; Izit unchanged?
	 je	 short CHECK_CHIPSET_ERR0 ; Jump if so, hence no CHIPSet present

;;;;;;;; xor	 cx,cx		; It's the 82C307 (CX already zero)

	 jmp	 short CHECK_CHIPSET_CLC ; Join common OK code

CHECK_CHIPSET_NEAT:
	 mov	 cx,1		; It's the 82C212

; Ensure there's a full 1MB available

	 mov	 al,6Ah 	; 82C212 bank 0/1 enable register
	 call	 READ_CHIPSET	; Read data from CHIPSet into AH

	 and	 ah,@BIT5 or @BIT6 or @BIT7 ; Isolate relevant bits

	 cmp	 ah,000b shl 5	; Check for one bank, disabled
	 je	 short CHECK_CHIPSET_ERR1 ; Jump if so

	 cmp	 ah,001b shl 5	; Check for two banks, disabled
	 je	 short CHECK_CHIPSET_ERR1 ; Jump if so

	 cmp	 ah,010b shl 5	; Check for one bank, 256K and 64K
	 je	 short CHECK_CHIPSET_ERR1 ; Jump if so

	 cmp	 ah,011b shl 5	; Check for two banks, 256K and 64K
	 je	 short CHECK_CHIPSET_ERR1 ; Jump if so

	 cmp	 ah,100b shl 5	; Check for one bank, 256K only
	 je	 short CHECK_CHIPSET_ERR1 ; Jump if so
CHECK_CHIPSET_CLC:
	 clc			; Assume it's present

	 jmp	 short CHECK_CHIPSET_EXIT ; Join common exit code

CHECK_CHIPSET_ERR0:
	 xor	 cx,cx		; Indicate no CHIPSet present

	 jmp	 short CHECK_CHIPSET_ERR ; Join common error code

CHECK_CHIPSET_ERR1:
	 mov	 cx,1		; Indicate NEAT with < 1MB present

	 jmp	 short CHECK_CHIPSET_ERR ; Join common error code

CHECK_CHIPSET_VLSI:
	 mov	 cx,2		; It's a VLSI CHIPSet
CHECK_CHIPSET_ERR:
	 stc			; Indicate not supported
CHECK_CHIPSET_EXIT:
	 REGREST <bx,ax>	; Restore

	 mov	ax,cx		; Fix for return to C language
	 jc	@F
	 add	ax,100h 	; Fix for C language
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_CHIPSET endp		; End CHECK_CHIPSET procedure

	 NPPROC  READ_CHIPSET	; -- Read Command/Data from CHIPSet
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Read data into AH from command register in AL in the CHIPSet.

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 out	 @CT_INDX,al	; Send command to CHIPSet
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Copy value

	 in	 al,@CT_DATA	; Read data from CHIPSet
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 xchg	 al,ah		; Return in data in AH, original command in AL

	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

READ_CHIPSET endp		; End READ_CHIPSET procedure

	 end			; End C$TLOAD module

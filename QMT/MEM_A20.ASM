;' $Header:   P:/PVCS/MAX/QMT/MEM_A20.ASV   1.1   29 Jun 1998 13:05:00   BOB  $
	 title	 MEM_A20 -- MEMCHK A20 Gating Routines
	 page	 58,122
	 name	 MEM_A20

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include HMA.INC
	 include 8255.INC
	 include 8259.INC
	 include BITFLAGS.INC
	 include XMS.INC
	 include A20.INC
	 include ALLMEM.INC
	 
	include MEM_SEGS.INC
.list

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 GL3_FLAG:word
	 include MEM_GL3.INC

	 extrn	 MAPSEG_NXT:word

	 public  A20SUP
A20SUP	 dw	 mask $A20_8042 ; Assume we're using an 8042

	 public  I78DATA
I78DATA  db	 0E4h,78h	; in	  al,78h
	 db	  0Ch, 04h	; or	  al,04h
	 db	 0E6h,78h	; out	  78h,al
I78DATA_LEN equ  $-I78DATA	; Length of I78DATA

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 XMSDRV_VEC:dword

	 extrn	 SRCHSTR:near
	 extrn	 WAITIBUF_CLR:near
	 extrn	 PPI_S2C:near
	 extrn	 DRAINPIQ:near

@WAIT8042 equ	 12		; Wait counter for 8042 timeout

	 public  ACTA20_COMSUB
ACTA20_COMSUB dw PGROUP:A20COM_ISA ; Default A20 handler

	 public  ACTA20_ENA
	 include MEM_A20.INC
ACTA20_ENA ACTA20_STR <PGROUP:A20ENA_I92, \
		       PGROUP:A20ENA_QUD, \
		       PGROUP:A20ENA_XT,  \
		       PGROUP:A20ENA_ISA, \
		       PGROUP:A20ENA_I78, \
		       PGROUP:A20ENA_XMS>

	 public  ACTA20_DIS
ACTA20_DIS ACTA20_STR <PGROUP:A20DIS_I92, \
		       PGROUP:A20DIS_QUD, \
		       PGROUP:A20DIS_XT,  \
		       PGROUP:A20DIS_ISA, \
		       PGROUP:A20DIS_I78, \
		       PGROUP:A20DIS_XMS>

; Default Output Port byte

	 public  DEFOUT
DEFOUT	 db	 (mask $S2O_DATA)  or \
		 (mask $S2O_CLOCK) or \
		 (mask $S2O_OBFUL) or \
		 (mask $S2O_UNDEF) or \
		 (mask $S2O_RESET)

	 NPPROC  PPI_S2C_S2K -- PPI System to Controller, System to Keyboard
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller, System to Keyboard.

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Send the command to the 8042.
2.  Send the data to the 8042.

On entry:

AH	 =	 S2C command
AL	 =	 byte to send
IF	 =	 0

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short @F	; Jump if something went wrong (note CF=1)

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short @F	; Error, controller not reading data (note CF=1)

	 out	 @8255_A,al	; Send data AL to 8042
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2C_S2K endp		; End PPI_S2C_S2K procedure
	 NPPROC  PULSE8042 -- Pulse 8042
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Pulse the 8042 to ensure the last command has been accepted.
Typically, this is necssary after toggling A20.

|

;;;;;;;; test	 GL3_FLAG,@GL3_XPULS ; Should we pulse the controller?
;;;;;;;; jnz	 short PULSE8042_EXIT ; Not this time (note CF=0)

; Pulse the controller to ensure the last 8042 command has been processed

	 push	 ax		; Save for a moment
	 mov	 ah,@S2C_RESET	; Ensure in a stable state
	 call	 PPI_S2C	; Send command AH to 8042
	 pop	 ax		; Restore
	 jc	 short PULSE8042_EXIT ; Jump if something went wrong (note CF=1)

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
				; Return with CF significant
PULSE8042_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PULSE8042 endp			; End PULSE8042 procedure
	 NPPROC  READ_IRR -- Read Master 8259 Interrupt Request Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read master 8259 Interrupt Request Register (IRR)

On exit:

AL	 =	 IRR

|

	 mov	 al,@GETIRR	; Command to get IRR
	 out	 @ICR,al	; Tell the master 8259 about it
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@ICR	; Get the master IRR
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_IRR endp			; End READ_IRR procedure
	 NPPROC  A20DIS_I92 -- A20 Disable for I/O Port 92h Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for I/O port 92h systems

On entry:

AL	 =	 @PS2_A port value

On exit:

AL	 =	 (updated to disable A20)

|

	 and	 al,not (mask $PS2_GATE) ; Disable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_I92 endp 		; End A20DIS_I92 procedure
	 NPPROC  A20DIS_QUD -- A20 Disable for Quadram 386/XT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for Quadram 386/XT

On entry:

AL	 =	 1F8h port value

On exit:

AL	 =	 (updated to disable A20)

|

	 and	 al,not @BIT0	; Mark as disabling

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_QUD endp 		; End A20DIS_QUD procedure
	 NPPROC  A20DIS_XT -- A20 Disable for Inboard/PC
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for Inboard/PC

On exit:

AL	 =	 value to disable A20

|

	 mov	 al,@S2O_D20	; Tell it to disable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_XT endp			; End A20DIS_XT procedure
	 NPPROC  A20DIS_I78 -- A20 Disable for I78 Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for I78 systems

On entry:

AL	 =	 port 78h byte

On exit:

AL	 =	 (updated to disable A20)

|

	 and	 al,not @BIT2	; Disable A20 gate

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_I78 endp 		; End A20DIS_I78 procedure
	 NPPROC  A20DIS_ISA -- A20 Disable for ISA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for ISA

On entry:

AL	 =	 output port byte

On exit:

AL	 =	 (updated to disable A20)

|

;;;;;;;; or	 al,(mask $S2O_DATA ) or \
;;;;;;;;	    (mask $S2O_OBFUL) or \
;;;;;;;;	    (mask $S2O_IBFMT)
;;;;;;;;			; Ensure 6805 data line high,
;;;;;;;;			; output buffer full,
;;;;;;;;			; input buffer empty
	 or	 al,mask $S2O_OBFUL ; Ensure output buffer marked as full
	 and	 al,not (mask $S2O_GATE) ; Disable A20 gate

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_ISA endp 		; End A20DIS_ISA procedure
	 NPPROC  A20DIS_XMS -- A20 Disable for XMS Driver Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for XMS driver systems

On exit:

AX	 =	 XMS function #

|

	 mov	 ah,@XMS_LCLDIS ; XMS function code to disable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_XMS endp 		; End A20DIS_XMS procedure
	 NPPROC  DEGATEA20 -- Disable Address Line A20
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable address line A20.

On exit:

CF	 =	 0 if all went well
	 =	 1 if we couldn't disable A20

|

	 push	 bx		; Save register

	 lea	 bx,ACTA20_DIS	; CS:BX ==> disable A20 actions

	 jmp	 ACTA20_COM	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEGATEA20 endp			; End DEGATEA20 procedure
	 NPPROC  GATEA20 -- Enable Address Line A20
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable address line A20.

On exit:

CF	 =	 0 if all went well
	 =	 1 if we couldn't enable A20

|

	 push	 bx		; Save register

	 lea	 bx,ACTA20_ENA	; CS:BX ==> enable A20 actions

	 jmp	 short ACTA20_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GATEA20  endp			; End GATEA20 procedure
	 NPPROC  ACTA20_COM -- A20 Enable/Disable Common Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable/disable common routine

On entry:

BX	 pushed onto stack
CS:BX	 ==>	 enable/disable action structure

|

	 push	 ax		; Save register

	 clc			; Assume all goes well
	 lahf			; Load AH with flags

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 call	 ACTA20_COMSUB	; Call the appropriate subroutine

	 popf			; Restore flags

	 sahf			; Store AH into flags

	 pop	 ax		; Restore

	 pop	 bx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACTA20_COM endp 		; End ACTA20_COM procedure
	 NPPROC  A20ENA_I92 -- A20 Enable for I/O Port 92 Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for I/O port 92 systems

On entry:

AL	 =	 @PS2_A port value

On exit:

AL	 =	 (updated to enable A20)

|

	 or	 al,mask $PS2_GATE ; Enable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_I92 endp 		; End A20ENA_I92 procedure
	 NPPROC  A20ENA_QUD -- A20 Enable for Quadram 386/XT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for Quadram 386/XT

On entry:

AL	 =	 1F8h port value

On exit:

AL	 =	 (updated to enable A20)

|

	 or	 al,@BIT0	; Mark as enabling

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_QUD endp 		; End A20ENA_QUD procedure
	 NPPROC  A20ENA_XT -- A20 Enable for Inboard/PC
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for Inboard/PC

On exit:

AL	 =	 value to enable A20

|

	 mov	 al,@S2O_E20	; Tell it to enable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_XT endp			; End A20ENA_XT procedure
	 NPPROC  A20ENA_I78 -- A20 Enable for I/O Port 78h Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for I/O port 78h systems

On entry:

AL	 =	 port 78h byte

On exit:

AL	 =	 (updated to enable A20)

|

	 or	 al,@BIT2	; Enable A20 gate

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_I78 endp 		; End A20ENA_I78 procedure
	 NPPROC  A20ENA_ISA -- A20 Enable for ISA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for ISA

On entry:

AL	 =	 output port byte

On exit:

AL	 =	 (updated to enable A20)

|

;;;;;;;; or	 al,(mask $S2O_DATA ) or \
;;;;;;;;	    (mask $S2O_OBFUL) or \
;;;;;;;;	    (mask $S2O_IBFMT) or \
;;;;;;;;	    (mask $S2O_GATE )
;;;;;;;;			; Ensure 6805 data line high,
;;;;;;;;			; output buffer full,
;;;;;;;;			; input buffer empty
;;;;;;;;			; gate A20 enabled
	 or	 al,mask $S2O_OBFUL ; Ensure output buffer marked as full
	 or	 al,mask $S2O_GATE ; Enable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_ISA endp 		; End A20ENA_ISA procedure
	 NPPROC  A20ENA_XMS -- A20 Enable for XMS Driver Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for XMS driver systems

On exit:

AX	 =	 XMS function #

|

	 mov	 ah,@XMS_LCLENA ; XMS function code to enable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_XMS endp 		; End A20ENA_XMS procedure
	 NPPROC  A20COM_I92 -- Common A20 I/O Port 92h Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 I/O port 92h routine

On entry:

CS:BX	 ==>	 enable/disable routine

On exit:

AL	 =	 clobbered
AH	 =	 preserved

|

	 in	 al,@PS2_A	; Get system control port A
	 call	 PGROUP:[bx].ACTA20_I92 ; Call common I92 action
	 out	 @PS2_A,al	; Tell the system about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_I92 endp 		; End A20COM_I92 procedure
	 NPPROC  A20COM_QUD -- Common A20 Quadram 386/XT Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 Quadram 386/XT routine

On entry:

CS:BX	 ==>	 enable/disable routine

On exit:

AL	 =	 clobbered
AH	 =	 preserved

|

	 push	 dx		; Save for a moment

	 mov	 dx,01F8h	; Get A20 gate/degate I/O port
	 in	 al,dx		; Get the current value
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 call	 PGROUP:[bx].ACTA20_QUD ; Call common Quadram 386/XT action
	 out	 dx,al		; Tell the board about it
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 pop	 dx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_QUD endp 		; End A20COM_QUD procedure
	 NPPROC  A20COM_XT -- Common A20 Inboard/PC Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 Inboard/PC routine

On entry:

CS:BX	 ==>	 enable/disable routine

On exit:

AL	 =	 clobbered
AH	 =	 preserved

|

	 call	 PGROUP:[bx].ACTA20_XT ; Call common Inboard/PC action
;;;;;;;; or	 al,10010000b	; Ensure 6805 data line high,
				; output buffer full
	 out	 @8255_A,al	; Issue the command
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_XT endp			; End A20COM_XT procedure
	 NPPROC  A20COM_I78 -- Common A20 I/O Port 78h Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 I/O port 78h routine

On entry:

CS:BX	 ==>	 enable/disable routine

On exit:

AL	 =	 clobbered
AH	 =	 preserved

|

	 in	 al,78h 	; Get current value
	 call	 PGROUP:[bx].ACTA20_I78 ; Call common I78 action
	 out	 78h,al 	; Send back

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_I78 endp 		; End A20COM_I78 procedure
	 NPPROC  A20COM_ISA -- Common A20 ISA Bus Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 ISA Bus routine

On entry:

CS:BX	 ==>	 enable/disable routine

On exit:

AL	 =	 clobbered
AH	 =	 preserved

|

	 REGSAVE <ax>		; Save for a moment

	 mov	 al,DEFOUT	; Get the default Output Port byte
	 call	 PGROUP:[bx].ACTA20_ISA ; Call common ISA action

	 mov	 ah,@S2C_WOUT	; Write output port byte
	 call	 PPI_S2C_S2K	; Write command AH, data AL to 8042
	 jc	 short @F	; Jump if error (note CF=1)

	 call	 PULSE8042	; Pulse the 8042 to ensure A20 toggle done
				; Return with CF significant
@@:
	 REGREST <ax>		; Restore

	 adc	 ah,0		; Set CF in AH image of flags as necessary

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_ISA endp 		; End A20COM_ISA procedure
	 NPPROC  A20COM_XMS -- Common A20 XMS Driver Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 XMS driver routine

On entry:

CS:BX	 ==>	 enable/disable routine

|

; Some XMS drivers have been known to clobber registers it shouldn't
; so we save 'em all

	 pushad 		; Save all EGP registers
	 call	 PGROUP:[bx].ACTA20_XMS ; Call common XMS action
	 call	 XMSDRV_VEC	; Request XMS service
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_XMS endp 		; End A20COM_XMS procedure
	 NPPROC  CHECK_I92 -- Check For I/O Port 92h A20 Gating
	 assume  ds:DGROUP,es:DGROUP,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check for I/O port 92h A20 gating

|

	 REGSAVE <ax,cx,si,di,ds,es> ; Save registers

; See if this system supports I/O port 92h to gate A20

COMMENT|

Alas, from the no-good-deed-goes-unpunished file, it turns out that on
some systems the very act of writing to I/O port 92h (the actual value
doesn't matter) gates A20 on, but then that's all she wrote.  No
further writes to 92h or to the 8042 for that matter have any effect.

As this causes us some problems, we need to recognize this situation
and avoid it.  On the system I encountered with this hardware bug, the
input value of I/O port 92h is 0C0h, so the test used below checks for
the two high-order bits on.  If that's a valid I/O port (at least in
MCA parlance), that would mean that both Fixed Disk lights are on,
which is, I trust, an unlikely event.  This also catches the case
where the I/O port has no effect and a read returns 0FFh.

|

@FD01	 equ	 ((mask $PS2_FD0) or (mask $PS2_FD1)) ; Both fixed disk lights

	 in	 al,@PS2_A	; Get current state
	 and	 al,@FD01	; Idolate Fixed Disk lights

	 cmp	 al,@FD01	; Izit valid?
	 je	 short CHECK_I92_EXIT ; Jump if so

	 mov	 es,MAPSEG_NXT	; Get next available segment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> local buffer

	 mov	 ax,seg HMASEG	; Get segment of HMA
	 mov	 ds,ax		; Address it
	 assume  ds:HMASEG	; Tell the assembler about it

	 lea	 si,HMASTART	; DS:SI ==> start of HMA

	 mov	 cx,100h	; # bytes to copy and compare
	 cld			; String ops forwardly

	 cli			; Disable interrupts in case
				; the contents of the HMA can change
	 REGSAVE <cx,si,di>	; Save for a moment

S16  rep movs	 <es:[di].LO,HMASTART[si]> ; Copy to local buffer

	 REGREST <di,si,cx>	; Restore

; Toggle the I/O port 92h state

	 in	 al,@PS2_A	; Get current state
	 xor	 al,mask $PS2_GATE ; Toggle the state
	 out	 @PS2_A,al	; Write it back out

; Compare the data (we might get fooled by a memory cache)

    repe cmps	 HMASTART[si],es:[di].LO ; Compare with the local buffer
	 pushf			; Save ZF and IF for a moment

; Toggle the I/O port 92h state back

	 in	 al,@PS2_A	; Get current state
	 xor	 al,mask $PS2_GATE ; Toggle the state
	 out	 @PS2_A,al	; Write it back out

	 popf			; Restore ZF and IF
	 sti			; Enable interrupts again
	 je	 short CHECK_I92_EXIT ; Jump if the same (not I/O port 92 system)

	 push	 seg DGROUP	; Setup DS for data references
	 pop	 ds
	 assume  ds:DGROUP	; Tell the assembler about it

	 bts	 GL3_FLAG,$GL3_A20SET ; Izit already set?
	 jc	 short @F	; Jump if so

	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_I92 ; Save routine addr
@@:
	 mov	 A20SUP,mask $A20_I92 ; Mark as A20 support value
CHECK_I92_EXIT:
	 REGREST <es,ds,di,si,cx,ax> ; Restore
	 assume  ds:DGROUP,es:DGROUP ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_I92 endp			; End CHECK_I92 procedure
	 NPPROC  CHECK_I78 -- Check for I/O Port 78h A20 Toggle
	 assume  ds:DGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check for I/O port 78h to toggle A20

In certain systems I/O port 78h is used to toggle A20.	This routine
detects those BIOSs and marks it as such.

|

	 push	 di		; Save register

; Search for the I78DATA string in F000:0 to FFFF

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset DGROUP:I78DATA ; Get offset of source string
	 push	 I78DATA_LEN	; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short CHECK_I78_EXIT ; Jump if not found
				; Return with DI = offset of match in ROM

	 bts	 GL3_FLAG,$GL3_A20SET ; Izit already set?
	 jc	 short @F	; Jump if so

	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_I78 ; Save routine addr
@@:
CHECK_I78_EXIT:
	 pop	 di		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_I78 endp			; End CHECK_I78 procedure

CODE	 ends			; End CODE segment

	 MEND			; End MEM_A20 module

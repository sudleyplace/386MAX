;' $Header:   P:/PVCS/MAX/QMT/MEM_KEY.ASV   1.0   05 Sep 1995 16:55:38   HENRY  $
	title	MEM_KEY -- MEMCHK Keyboard Routines
	page	58,122
	name	MEM_KEY

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include 8255.INC
	 include KEYCALL.INC
	 include 8253.INC
	 include 8259.INC
	 include BITFLAGS.INC

	 include MAXDEV.INC
	include MEM_SEGS.INC
.list

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 GLB_FLAG:word
	 include MEM_GLB.INC

	 public  OLDIMR1,OLDIMR2
OLDIMR1  db	 ?		; Save area for original master IMR
OLDIMR2  db	 ?		; ...			 slave	IMR

	 public  FNGETKST,FNGETKEY
FNGETKST db	 @GETKST	; Function code to get keyboard buffer status
FNGETKEY db	 @GETKEY	; ...				       keystroke

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 MD_FLAG:dword

	 NPPROC  ENABLE8255 -- Enable XT Keyboard
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable keyboard on XT through the 8255.

|

	 REGSAVE <ax>		; Save register

	 in	 al,@8255_B	; Get the control port
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 and	 al,not @BIT2	; Ensure reset to read key

	 mov	 ah,al		; Save the value
	 or	 al,mask $KEYB	; Reset bit for keyboard
	 out	 @8255_B,al	; Tell the 8255 about it
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

;;;;;;;; and	 al,not (mask $KEYB) ; Enable keyboard
	 mov	 al,ah		; Restore original value
	 out	 @8255_B,al	; Tell the 8255 about it
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE8255 endp 		; End ENABLE8255 procedure
	 NPPROC  PPI_S2C -- PPI System to Controller
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller.
Send a command to the controller (8042).

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Wait for the input buffer to clear to avoid overrun.
2.  Send the command in AH to the keyboard controller port 64h.
    There is no acknowledgement of this command.

On entry:

AH	 =	 command
IF	 =	 0

On exit:

CF	 =	 1 if keyboard controller not responding
	 =	 0 otherwise

|

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short @F	; Error, controller not reading data (note CF=1)

	 xchg	 al,ah		; Swap to put command in AL
	 out	 @8042_ST,al	; Send the command
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue
	 xchg	 al,ah		; Restore
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2C  endp			; End PPI_S2C procedure
	 NPPROC  PPI_S2C_K2S -- PPI System to Controller, Keyboard to System
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller, Keyboard to System
Send a command to the controller (8042), wait for a response.

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Send the command to the 8042.
2.  Wait for the output buffer to fill.
3.  Read the response.

Note that resend does not occur with the controller (8042)
(although it can with the keyboard (6805)).

On entry:

AH	 =	 S2C command
IF	 =	 0

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

AL	 =	 byte read (if CF=0)

|

	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short @F	; Jump if something went wrong (note CF=1)

	 call	 PPI_K2S	; Wait for a response, returned in AL
				; Return with CF significant
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2C_K2S endp		; End PPI_S2C_K2S procedure
	 NPPROC  PPI_S2K -- PPI System to Keyboard
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Keyboard.
Send command to keyboard.

1.  Wait for the input buffer to clear to avoid overrun.
2.  Send the command in AH to the keyboard port 60h.
    There is no acknowledgement of this command.

On entry:

AH	 =	 command to send
IF	 =	 0

On exit:

CF	 =	 1 if timeout
	 =	 0 otherwise

AL	 =	 keyboard response if CF=0

|

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short @F	; Error, controller not reading data (note CF=1)

	 xchg	 al,ah		; Swap to put command in AL
	 out	 @8255_A,al	; Issue the command
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue
	 xchg	 al,ah		; Restore
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2K  endp			; End PPI_S2K procedure
	 NPPROC  PPI_K2S -- PPI Keyboard to System
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI Keyboard to System.
Wait for a response from the keyboard or its controller.

On entry:

IF	 =	 0

On exit:

CF	 =	 1 if no response
	 =	 0 otherwise

AL	 =	 response if CF=0

|

	 call	 WAITOBUF_SET	; Wait for the output buffer to fill
	 jc	 short @F	; Jump if no timely response (note CF=1)

	 in	 al,@8255_A	; Read in the code
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_K2S  endp			; End PPI_K2S procedure
	 NPPROC  PPI_S2K_K2S -- PPI System to Keyboard, Keyboard to System
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Keyboard, Keyboard to System.
Send command to keyboard (6805), wait for its response.

Note that it's the caller's responsibility to ensure that
the 6805 output buffer is clear.

1.  Send the command to the 6805.
2.  Wait for the output buffer to fill.
3.  Read the response.
4.  Check for resend.

On entry:

AH	 =	 command to send
IF	 =	 0

On exit:

CF	 =	 1 if timeout
	 =	 0 otherwise

AL	 =	 keyboard response if CF=0

|

	 push	 cx		; Save for a moment

	 mov	 cx,6		; # retries of resend (arbitrary value)
PPI_S2K_K2S_AGAIN:
	 call	 PPI_S2K	; Send command AH to 6805
	 jc	 short PPI_S2K_K2S_EXIT ; Jump if something went wrong (note CF=1)

	 call	 PPI_K2S	; Wait for a response, returned in AL
	 jc	 short PPI_S2K_K2S_EXIT ; Jump if something went wrong (note CF=1)

	 cmp	 al,@K2S_RESEND ; Izit a resend?
	 clc			; In case not
	 jne	 short PPI_S2K_K2S_EXIT ; Jump if not (note CF=0)

	 loop	 PPI_S2K_K2S_AGAIN ; Jump if more retries

	 stc			; Indicate something went wrong
PPI_S2K_K2S_EXIT:
	 pop	 cx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2K_K2S endp		; End PPI_S2K_K2S procedure
	 NPPROC  WAITIBUF_CLR -- Wait For The Input Buffer To Clear
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait for the one-byte input buffer to clear.

On entry:

IF	 =	 0

On exit:

CF	 =	 0 if buffer empty
	 =	 1 otherwise

|


	 REGSAVE <ax,bx,cx>	; Save registers

	 mov	 bx,6		; Outer loop counter (arbitrary value)
	 xor	 cx,cx		; Inner loop counter (arbitrary value)
	 in	 al,@8255_B	; Get port B value
	 and	 al,mask $REFRESH ; Isolate refresh bit
	 mov	 ah,al		; Save for later use
WAITIBUF_CLR1:
	 test	 MD_FLAG,@MD_MCA ; Izit an MCA-compatible?
	 jz	 short WAITIBUF_CLR2 ; Jump if not

; Wait for next refresh

@@:
	 in	 al,@8255_B	; Get port B value
	 and	 al,mask $REFRESH ; Isolate refresh bit

	 cmp	 al,ah		; Izit the same as last time?
	 je	 short @B	; Jump if so

	 mov	 ah,al		; Save for next time
WAITIBUF_CLR2:
	 in	 al,@8042_ST	; Get status from keyboard
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 and	 al,mask $INPFULL ; Check Input Buffer Full flag
	 loopnz  WAITIBUF_CLR1	; Last char not read as yet
	 jz	 short WAITIBUF_CLR_EXIT ; Jump if buffer clear (note CF=0)

	 dec	 bx		; One fewer time
	 jnz	 short WAITIBUF_CLR1 ; Go around again

	 stc			; Indicate something went wrong
WAITIBUF_CLR_EXIT:
	 REGREST <cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WAITIBUF_CLR endp		; End WAITIBUF_CLR procedure
	 NPPROC  WAITOBUF_SET -- Wait for Output Buffer Full
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait for the output buffer to fill.

On entry:

IF	 =	 0

On exit:

CF	 =	 1 if no response
	 =	 0 otherwise

|

	 REGSAVE <ax,cx>	; Save registers

; Wait for a response

	 mov	 ah,6		; Outer loop counter (arbitrary value)
	 xor	 cx,cx		; Inner loop counter (arbitrary value)
WAITOBUF_SET1:
	 in	 al,@8042_ST	; Get status from keyboard
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 and	 al,mask $OUTFULL ; Check Output Buffer Full flag
	 loopz	 WAITOBUF_SET1	; Jump if no response as yet
	 jnz	 short WAITOBUF_SET_EXIT ; Join common exit code (note CF=0)

	 dec	 ah		; One fewer time
	 jnz	 short WAITOBUF_SET1 ; Jump if more tries available

	 stc			; Indicate something went wrong
WAITOBUF_SET_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WAITOBUF_SET endp		; End WAITOBUF_SET procedure
	 NPPROC  WAITOBUF_CLR -- Wait For The Output Buffer To Clear
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

IF	 =	 0

Wait for the one-byte output buffer to clear.

|

	 push	 ax		; Save for a moment
WAITOBUF_CLR1:
	 in	 al,@8042_ST	; Get status from keyboard
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 and	 al,mask $OUTFULL ; Check Output Buffer Full flag
	 jz	 short WAITOBUF_CLR_EXIT ; Jump if buffer clear before

	 in	 al,@8255_A	; Purge the character
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 jmp	 short WAITOBUF_CLR1 ; Go around again

WAITOBUF_CLR_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WAITOBUF_CLR endp		; End WAITOBUF_CLR procedure
	 NPPROC  SEND_OUT -- Write The Output Port Byte
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Write the output port byte.

On entry:

AL	 =	 byte to send

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short SEND_OUT_EXIT ; Jump if something went wrong (note CF=1)

	 push	 ax		; Save for a moment

	 mov	 al,@S2C_WOUT	; Write output port byte
	 out	 @8042_ST,al	; Tell the controller about it
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ

	 pop	 ax		; Restore

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short SEND_OUT_EXIT ; Jump if something went wrong (note CF=1)

	 out	 @8255_A,al	; Issue the command
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ

	 test	 GLB_FLAG,@GLB_XPULS ; Should we pulse the controller?
	 jnz	 short SEND_OUT_CLR ; Not this time

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short SEND_OUT_EXIT ; Jump if something went wrong (note CF=1)

	 push	 ax		; Save for a moment

	 mov	 al,@S2C_RESET	; Ensure in a stable state
	 out	 @8042_ST,al	; Pulse the 8042
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ

	 pop	 ax		; Restore
SEND_OUT_CLR:
	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short SEND_OUT_EXIT ; Jump if something went wrong (note CF=1)

	 clc			; Indicate all went well
SEND_OUT_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEND_OUT endp			; End SEND_OUT procedure
	 NPPROC  ENABLE_IRQS -- Enable The IRQs We Need
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable the IRQs we need.
In particular, we need IRQ0, IRQ1, and (if slave PIC present) IRQ2 and IRQ12.
Note that to test for IRQ12 in the slave PIC, we use IRQ4 (=12-8).
Ensure IRQ0 and IRQ1 are clear.

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 REGSAVE <ax>		; Save register

	 test	 MD_FLAG,@MD_XT ; Running on an XT?
	 jnz	 short ENABLE_IRQS1 ; Yes, no 8042

; Ensure the keyboard is in a stable state

;;;;;;;; mov	 ah,@S2C_PULSE or @BIT0 or @BIT1 or @BIT2 ; Pulse nothing
;;;;;;;; call	 PPI_S2C	; Send command AH to 8042
				; Ignore return code

; Ensure the keyboard is enabled

	 mov	 ah,@S2C_ENA	; Enable the keyboard interface
	 call	 PPI_S2C	; Send command AH to 8042
				; Ignore return code
	 jmp	 short ENABLE_IRQS2 ; Join common code

ENABLE_IRQS1:
	 call	 ENABLE8255	; Enable XT keyboard
ENABLE_IRQS2:

; Re-establish the IMR values upon entry (they were each set to FF by
; the EPM mechanism, probably the BIOS).

	 call	 REST_IMR	; Restore 'em

	 REGREST <ax>		; Restore

	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_IRQS endp		; End ENABLE_IRQS procedure
	 NPPROC  SAVE_IMR -- Save The IMR
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save the original master and slave IMRs.

|

	 REGSAVE <ax>		; Save register

	 in	 al,@IMR	; Get current master interrupt mask register
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 mov	 OLDIMR1,al	; Save to restore later

	 test	 MD_FLAG,@MD_XT ; Running on an XT?
	 jnz	 short SAVE_IMR_NOXT1 ; Yes, so there's no slave controller

	 in	 al,@IMR2	; Get current slave IMR
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 mov	 OLDIMR2,al	; Save to restore later
SAVE_IMR_NOXT1:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_IMR endp			; End SAVE_IMR procedure
	 NPPROC  REST_IMR -- Restore IMR to Original Value
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore IMR to original value.

|

	 REGSAVE <ax>		; Save register

	 mov	 al,OLDIMR1	; Copy original master IMR value
	 and	 al,not ((mask $IRQ1) or (mask $IRQ0)) ; Ensure IRQ0 and IRQ1 are enabled
	 out	 @IMR,al	; Tell the PIC about it
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 test	 MD_FLAG,@MD_XT ; Running on an XT?
	 jnz	 short REST_IMR_EXIT ; Yes, no second controller

	 mov	 al,OLDIMR2	; Copy original slave IMR value
	 out	 @IMR2,al	; Tell the PIC about it
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue
REST_IMR_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_IMR endp			; End REST_IMR procedure
	 NPPROC  DRAINPIQ -- Drain The Prefetch Instruction Queue
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Drain the Prefetch Instruction Queue.

If we're on a Micro Channel system, write to I/O port 4Fh.
Otherwise, just jump a few times.

Flags are saved and restored over this routine to allow it
to be used with impunity.

|

	 pushf			; Save flags

	 test	 MD_FLAG,@MD_MCA ; Izit an MCA-compatible?
	 jz	 short @F	; Not this time

	 out	 @8253_XCIO,al	; Write to (presumably uncached) port
@@:
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAINPIQ endp			; End DRAINPIQ procedure
	 NPPROC  PURGE_KBUFF -- Purge The Keyboard Buffer
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Purge the keyboard buffer

On entry:

SS:EBP	 ==>	 FORW_STR

|

	 push	 ax		; Save for a moment
PURGE_KBUFF_DPMI:
	 mov	 ah,FNGETKST	; Function code to get keyboard buffer status
	 KEYCALL		; Return with ZF significant, AX=key
	 jz	 short PURGE_KBUFF_EXIT ; Jump if the buffer is empty

	 mov	 ah,FNGETKEY	; Function code to get keyboard buffer keystroke
	 KEYCALL		; Purge the keystroke

	 jmp	 PURGE_KBUFF_DPMI ; Go around again

PURGE_KBUFF_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PURGE_KBUFF endp		; End PURGE_KBUFF procedure
	 NPPROC  CHKNDKEY -- Check for Keystroke Non-destructively
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for a keystroke non-destructively

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

ZF	 =	 1 if no keystroke available
	 =	 0 otherwise
AX	 =	 keyboard code if ZF=0

|

	 mov	 ah,FNGETKST	; Function code to get keyboard buffer status
	 KEYCALL		; Return with ZF significant, AX=key

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHKNDKEY endp			; End CHKNDKEY procedure
	 NPPROC  GETKEY -- Wait for Keystroke
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return the next keystroke, wait if necessary.
This routine behaves like AH=10h, INT 16h.

On entry:

SS:EBP	 ==>	 FORW_STR

On exit:

AX	 =	 keyboard code

|

	 mov	 ah,FNGETKEY	; Function code to get keyboard buffer keystroke
	 KEYCALL		; Purge the keystroke

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETKEY	 endp			; End GETKEY procedure

CODE	 ends			; End CODE segment

	 MEND			; End MEM_KEY module

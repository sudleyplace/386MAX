;' $Header:   P:/PVCS/MAX/386MAX/QMAX_KEY.ASV   1.2   30 May 1997 10:45:24   BOB  $
	 title	 QMAX_KEY -- 386MAX Keyboard Routines
	 page	 58,122
	 name	 QMAX_KEY

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment BLINK, byte-aligned,  public, class 'blink'
	       Data    segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'

Link requirements:  Final routine should have extension .SYS.

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include 8255.INC
	 include 8253.INC
	 include 386.INC
	 include PTR.INC
.list

PGROUP	 group	 CODE,BLINK,ECODE,EDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 WAITIBUF_CLR:near
	 extrn	 WAITOBUF_CLR:near
	 extrn	 PPI_S2C_K2S:near
	 extrn	 PPI_S2C_S2K:near
	 extrn	 PPI_S2C:near
	 extrn	 PPI_K2S:near

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  cs:PGROUP

	 public  SHRT_DUR,SHRT_FRQ
SHRT_DUR dw	 300		; Duration
SHRT_FRQ dw	 800		; Frequency

	 public  UNITS_DUR,UNITS_FRQ
UNITS_DUR dw	 -1		; Duration
UNITS_FRQ dw	 800		; Frequency

	 public  FIVES_DUR,FIVES_FRQ
FIVES_DUR dw	 -1		; Duration
FIVES_FRQ dw	 400		; Frequency

	 public  TENS_DUR,TENS_FRQ
TENS_DUR dw	 -1		; Duration
TENS_FRQ dw	 200		; Frequency

	 public  FREQ
FREQ	 dd	 1193182	; Fundamental frequency

	 public  DIVISOR
DIVISOR  db	 5		; High/low sound divisor

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_KEY_ECODE
@QMAX_KEY_ECODE:		; Mark module start in .MAP file

	 NPPROC  RESET_KEYB -- Reset The Keyboard
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure the keyboard and its controller is clear and enabled.

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 REGSAVE <ax>		; Save register

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jz	 short RESET_KEYB_NOXT ; Not this time

	 in	 al,@8255_B	; Get the control port
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 or	 al,mask $KEYB	; Toggle bit for keyboard
	 out	 @8255_B,al	; Send back to 8255
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 and	 al,not mask $KEYB ; Enable keyboard
	 out	 @8255_B,al	; Send back to 8255
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 jmp	 short RESET_KEYB_EXIT ; Join common exit code

RESET_KEYB_NOXT:
	 test	 CM2_FLAG,@CM2_SELFT ; Should we reset the 8042?
	 jz	 short RESET_KEYB_6805 ; No, just the 6805

; Tell the 8042 to perform self-test (this command resets the controller
; so we have to reprogram it afterwards)

	 call	 WAITOBUF_CLR	; Wait for the output buffer to clear

	 mov	 ah,@S2C_SELF	; Perform self-test of controller
	 call	 PPI_S2C_K2S	; Send AH to 8042, return with AL = response
	 jc	 short ERR_SELF1 ; Something went wrong

	 cmp	 al,@C2S_SELF	; Izit expected response?
	 jne	 short ERR_SELF2 ; Jump if not

; Write the command byte

	 mov	 ah,@S2C_WCMD	; Write command byte
	 mov	 al,45h 	; Use default command byte
	 call	 PPI_S2C_S2K	; Write command AH, data AL to 8042
	 jc	 short ERR_WCMD1 ; Jump if something went wrong

; Write the output port byte

	 mov	 ah,@S2C_WOUT	; Write output port byte
	 mov	 al,0DFh	; Send it the default value
;;;;;;;; or	 al,10010000b	; Ensure 6805 data line high,
				; output buffer full
	 call	 PPI_S2C_S2K	; Write command AH, data AL to 8042
	 jc	 short ERR_WCMD2 ; Jump if something went wrong

; Send the 6805 an Enable and wait for a response

RESET_KEYB_6805:
	 test	 SYS_FLAG,@SYS_HPRS or @SYS_AST386 ; Izit an HP or AST system?
	 jnz	 short @F	; Yes, skip this

	 mov	 ah,@S2K_ENABLE ; Enable command
	 call	 PPI_S2K_K2S	; Send command AH to keyboard, response in AL
	 jc	 short ERR_ENAB ; Something went wrong
@@:
	 jmp	 short RESET_KEYB_EXIT ; Join common exit code

ERR_SELF1:
;;;;;;;; int	 03h		; Call debugger
ERR_SELF2:
;;;;;;;; int	 03h		; Call debugger
ERR_WCMD1:
;;;;;;;; int	 03h		; Call debugger
ERR_WCMD2:
;;;;;;;; int	 03h		; Call debugger
ERR_ENAB:
;;;;;;;; int	 03h		; Call debugger
RESET_KEYB_EXIT:
	 REGREST <ax>		; Restore

	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESET_KEYB endp 		; End RESET_KEYB procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment


BLINK	 segment use16 byte public 'blink' ; Start BLINK segment
	 assume  cs:PGROUP

	 public  @QMAX_KEY_BLINK
@QMAX_KEY_BLINK:nop		; Mark module start in .MAP file

	 NPPROC  CHECKPOINT -- Mark Checkpoint Number
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark the checkpoint number passed on the stack.

|

CHKPT_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's return address
CHKPT_VAL dw	 ?		; The checkpoint #

CHKPT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 test	 DBG_FLAG,@DBG_LED ; Blink 'em?
	 jz	 short CHKPT_XBLINK ; Not this time

	 REGSAVE <ax,bx>	; Save registers

	 mov	 ax,[ebp].CHKPT_VAL ; Get the checkpoint #

	 push	 ax		; Pass as argument
	 call	 BLINK_LED	; Blink the LEDs for a moment

	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 div	 DIVISOR	; Split into high and low part
	 assume  ds:nothing	; Retract nose
				; AL = quotient, AH = remainder
	 mov	 bl,al		; Copy quotient
	 shr	 bl,1		; BL = # tens notes
	 and	 al,1		; AL = # fives notes
				; AH = # units notes
CHKPT_TENS:
	 dec	 bl		; Check for more tens notes
	 js	 short CHKPT_FIVES ; No more, do fives notes now

	 push	 TENS_DUR	; Duration
	 push	 TENS_FRQ	; Frequency
	 call	 BEEP		; Beep the speaker

	 call	 PAUSE		; Pause between notes

	 jmp	 short CHKPT_TENS ; Go around again

CHKPT_FIVES:
	 dec	 al		; Check for no more fives notes
	 js	 short CHKPT_UNITS ; No more, do units notes

	 push	 FIVES_DUR	; Duration
	 push	 FIVES_FRQ	; Frequency
	 call	 BEEP		; Beep the speaker

	 call	 PAUSE		; Pause between notes

	 jmp	 short CHKPT_FIVES ; Go around again

CHKPT_UNITS:
	 dec	 ah		; Check for no more units notes
	 js	 short CHKPT_XNOTES ; No more

	 push	 UNITS_DUR	; Duration
	 push	 UNITS_FRQ	; Frequency
	 call	 BEEP		; Beep the speaker

	 call	 PAUSE		; Pause between notes

	 jmp	 short CHKPT_UNITS ; Go around again

CHKPT_XNOTES:
	 REGREST <bx,ax>	; Restore
CHKPT_XBLINK:
	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECKPOINT endp 		; End CHECKPOINT procedure
	 NPPROC  BLINK_LED -- Blink LEDs
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Blink LED indicator(s) according to the byte on the stack.
The value may range from 1 to 26.

Base 3 arithmetic is used to display the value.
That is, represent the value in AL in base 3 with digits 0, 1, 2.

A digit of 0 means the corresponding light is off
	   1				      on
	   2				      blinking

Note the stack might have its B-bit set, so all
implicit stack references *MUST* be 32-bit.

|

BLINK_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's return address
BLINK_VAL db	 ?,?		; LED byte

BLINK_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx>	; Save registers

COMMENT|

Convert the value as follows:

Represent it in base 3 with digits 0, 1, 2.

For each of the three digits,
  put into BL the constant states,
       and BH the blinking states
as follows:

	 Corresponding
	    Bit in
   Digit    BH	 BL
     0	    0	 0
     1	    0	 1
     2	    1	 0

Note that this corresponds to putting the high-order bit of the digit
into BH and the low-order bit into BL.

|

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jnz	 short BLINK_LED_EXIT ; Yes, so there are no LEDs

	 mov	 al,[ebp].BLINK_VAL ; Get the value
	 mov	 cx,3		; # digits to convert
	 xor	 bx,bx		; Zero BH and BL
	 mov	 dl,3		; Divisor
BLINK_CONV:
	 xor	 ah,ah		; Zero to use as word
	 div	 dl		; Strip off a digit into AH
				; with quotient in AL
	 shr	 ah,1		; Pick off bit 0
	 rcr	 bl,1		; Put into high-order of BL

	 shr	 ah,1		; Pick off bit 1
	 rcr	 bh,1		; Put into high-order of BH

	 loop	 BLINK_CONV	; Jump if more digits

	 shr	 bx,8-3 	; Shift to low-order

	 mov	 cx,30		; # times to blink the LEDs
	 cli			; Ensure interrupts off

	 call	 WAITOBUF_CLR	; Wait for the output buffer to clear

	 mov	 ah,@S2C_DIS	; Disable the keyboard interface
	 call	 PPI_S2C	; Send command AH to 8042
;;;;;;;; jc	 short ERR_BLINK1 ; Not programmable???
BLINK_NEXT:
	 mov	 ah,@S2K_LED	; Set/reset LED Indicators
	 call	 PPI_S2K_K2S	; Send command AH to keyboard, response in AL
	 jc	 short ERR_BLINK1 ; Jump if controller not responding

	 cmp	 al,@K2S_ACK	; Izit an ACK?
	 jne	 short ERR_BLINK1 ; Jump if something went wrong

	 mov	 ah,bl		; Set LED indicator(s)
	 call	 PPI_S2K_K2S	; Send command AH to keyboard, response in AL
	 jc	 short ERR_BLINK1 ; Jump if controller not responding

	 cmp	 al,@K2S_ACK	; Izit an ACK?
	 jne	 short ERR_BLINK1 ; Something went wrong
ERR_BLINK1:
	 push	 cx		; Save for a moment
	 xor	 cx,cx		; Loop for a while
@@:
	 loop	 @B
	 pop	 cx		; Restore

	 xor	 bl,bh		; Complement the bit(s)

	 loop	 BLINK_NEXT	; Jump if more to do
ERR_BLINK2:

; Finally, turn off all indicators

	 mov	 ah,@S2K_LED	; Set/reset LED Indicators
	 call	 PPI_S2K_K2S	; Send command AH to keyboard, response in AL
				; Ignore error return

	 mov	 ah,0		; Set LED indicator(s)
	 call	 PPI_S2K_K2S	; Send command AH to keyboard, response in AL
				; Ignore error return

	 mov	 ah,@S2C_ENA	; Enable the keyboard interface
	 call	 PPI_S2C	; Send command AH to 8042
				; Ignore return code

	 call	 WAITOBUF_CLR	; Wait for the output buffer to clear
				; in case there are any keystrokes left over
BLINK_LED_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BLINK_LED endp			; End BLINK_LED procedure
	 NPPROC  PPI_S2K -- PPI System to Keyboard
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Keyboard.
Send command to keyboard.

1.  Wait for the output buffer to clear to avoid overrun.
2.  Wait for the input buffer to clear to avoid overrun.
3.  Send the command in AH to the keyboard port 60h.
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

	 call	 WAITOBUF_CLR	; Wait for output buffer to clear
	 jc	 short @F	; Error, controller not reading data (note CF=1)

	 xchg	 al,ah		; Swap to put command in AL
	 out	 @8255_A,al	; Issue the command
	 xchg	 al,ah		; Restore
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2K  endp			; End PPI_S2K procedure
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
	 NPPROC  BEEP -- Beep On Key
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BEEP_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
BEEP_FRQ dw	 ?		; Frequency
BEEP_DUR dw	 ?		; Duration

BEEP_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ax,ecx,dx>	; Save registers

; Program timer 2 to generate square wave

	 mov	 al,(2*@TIMER_CH) or @TIMER_LMSB or (3*@TIMER_MODE) or @TIMER_BIN
;;;;;;;; mov	 al,10110110b	; 10xxxxxx = Timer 2,
				; xx11xxxx = Read/write LSB, then MSB
				; xxxx011x = Mode 3
				; xxxxxxx0 = Binary
	 out	 @8253_CTL,al	; Send to control register

	 mov	 dx,FREQ.EHI	; Hi part of fundamental frequency
	 mov	 ax,FREQ.ELO	; Lo part ...
	 mov	 cx,[ebp].BEEP_FRQ ; CX = frequency

	 cmp	 cx,dx		; Ensure above high-order word
	 ja	 short BEEP1	; It's OK

	 mov	 cx,dx		; Use minimum to avoid divide overflow
	 inc	 cx
BEEP1:
	 div	 cx		; AX = 8253 counter value, DX ignored

	 out	 @8253_CH2,al	; Send LSB to timer 2
	 mov	 al,ah		; Copy MSB of value
	 jmp	 $+2		; I/O delay for AT
	 out	 @8253_CH2,al	; Send MSB to timer 2

; Read and save current state of 8255, port B

	 in	 al,@8255_B	; Read it in
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 push	 ax		; Save it

	 or	 al,(mask $SPKR) or (mask $TIMER2) ; Turn on Spkr & Timer2
	 out	 @8255_B,al	; Tell 8255 about it
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 movzx	 ecx,[ebp].BEEP_DUR ; Get duration
	 shl	 ecx,1		; Increase the duration
	 loop	 dword ptr $	; Wait for a moment

	 pop	 ax		; Restore initial state of 8255, port B

	 out	 @8255_B,al	; Restore it
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 REGREST <dx,ecx,ax>	; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BEEP	 endp			; End BEEP procedure
	 NPPROC  PAUSE -- Pause Between Notes
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Pause between notes

|

	 REGSAVE <cx>		; Save register

	 xor	 cx,cx		; Start with a full loop

	 loop	 $		; Wait for a moment
	 loop	 $		; Wait for a moment

	 REGREST <cx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PAUSE	 endp			; End PAUSE procedure

BLINK	 ends			; End BLINK segment

	 MEND			; End QMAX_KEY module

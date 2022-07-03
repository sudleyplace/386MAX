;' $Header:   P:/PVCS/MAX/QUILIB/GAMEPORT.ASV   1.1   30 May 1997 12:09:02   BOB  $
	 title	 GAMEPORT -- Game port test
	 page	 58,122
	 name	 GamePort

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-7 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Ungrouped:
	       Program segment xxx_TEXT, word-aligned,	public, class 'code'
	       Group DGROUP:
	       Data    segment _DATA,	 word-aligned,	public, class 'data'

Link requirements:  Callable from MSC 6.

Program derived from:  None.

Original code by:  Henry Groover, August 1992.

Modifications by:  None.

|

.8086
.xlist
	 include MASM.INC
	 include PTR.INC
	 include INTVEC.INC
.list

%.model &MODEL,c

.code

	 public  GP_PrevInt08,GP_CountDown
GP_PrevInt08 dd  ?		; Previous Int 8 handler
GP_CountDown dw  ?		; Timeout value for port test

	 FPPROC  GP_Int08 -- Timer tick handler for GAMEPORT module
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Decrement count down timer.

|
	 pushf			; Simulate interrupt
	 call	 GP_PrevInt08	; Call previous handler

	 cmp	 GP_CountDown,0 ; Izit already timed out?
	 je	 short GP_Int08_IRET ; Jump if so

	 dec	 GP_CountDown	; Adjust counter
GP_Int08_IRET:
	 iret			; Return to caller, popping flags

	 assume  ds:nothing,es:nothing,ss:nothing

GP_Int08 endp			; End GP_Int08 procedure

	 NPPROC  GameCount_sub -- Test for valid resistive input values
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

On entry:
BL = mask for input(s) to be tested

On exit:
CF=1	 Bits specified in BL were never cleared.
CF=0	 Bits in BL were cleared within the specified time limit.

|

	 REGSAVE <ax,dx,ds,es>	; Save

	 mov	 ax,seg INTVEC	; Segment of real mode IDT
	 mov	 es,ax		; Address it
	 assume  es:INTVEC	; Tell the assembler

	 lds	 dx,INT00_VEC[(type INT00_VEC)*08h] ; Get previous vector
	 assume  ds:nothing	; Tell the assembler

	 mov	 GP_PrevInt08.VOFF,dx ; Save offset
	 mov	 GP_PrevInt08.VSEG,ds ; Save segment

	 cli			; Nobody move
	 mov	 INT00_VEC[(type INT00_VEC)*08h].VOFF,offset cs:GP_Int08 ; Set offset
	 mov	 INT00_VEC[(type INT00_VEC)*08h].VSEG,cs ; ...segment
	 sti			; Enable interrupts

	 mov	 dx,0201h	; Joystick I/O port
	 mov	 al,0C8h	; Random value to trigger pots
	 out	 dx,al		; Start'em ticking down
	 jmp	 short $+2	; Wait for I/O to settle
	 jmp	 short $+2	; Wait for I/O to settle
	 jmp	 short $+2	; Wait for I/O to settle

	 mov	 GP_CountDown,6 ; Timeout is about 1/3 second
GCSUB_LOOP:
	 in	 al,dx		; Get value from port
	 jmp	 short $+2	; Wait for I/O to settle

	 not	 al		; Invert all bits in result
	 test	 al,bl		; Were any bits cleared?
	 jnz	 short GCSUB_EXIT ; Jump if so (note CF=0)

	 cmp	 GP_CountDown,1 ; Did we time out?
	 jnc	 GCSUB_LOOP	; Go around again if not
				; (Note CF=1 if timeout occurred)

GCSUB_EXIT:
	 lds	 dx,GP_PrevInt08 ; Address previous holder
	 assume  ds:nothing	; Tell the assembler

	 cli			; Disable interrupts (note CF significant)
	 mov	 INT00_VEC[(type INT00_VEC)*08h].VOFF,dx ; Set offset
	 mov	 INT00_VEC[(type INT00_VEC)*08h].VSEG,ds ; ...segment
	 sti			; Enable interrupts (note CF significant)

	 REGREST <es,ds,dx,ax>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GameCount_sub endp		; End GameCount_sub procedure

	 PPROC	 GameCount -- Determine number of game ports connected
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT |
; int GameCount (void)

Return 0, 1, or 2 depending on number of game ports detected.
BX is destroyed.

|

	 sub	 ax,ax		; Assume no game adapter present
	 mov	 bl,0fh 	; Mask for all pot inputs
	 call	 GameCount_sub	; Return with CF=1 if bits were never cleared
	 jc	 short GameCount_exit ; Jump if test failed

	 inc	 al		; We know there's at least 1 joystick connected
	 mov	 bl,0Ch 	; Mask for pot inputs B(x) and B(y)
	 call	 GameCount_sub	; Return with CF=1 if bits were never cleared
	 cmc			; Clear CF if test failed
	 adc	 al,0		; Add result to count
GameCount_exit:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GameCount  endp 		; End GameCount procedure

	 MEND			; End GAMEPORT module


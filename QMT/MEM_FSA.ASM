;' $Header$
	title	MEM_FSA -- MEMCHK Finite State Automata Routines
	page	58,122
	name	MEM_FSA

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, June, 1998.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 8253.INC
	include 8255.INC

	include MEM_OEM.INC
	include PTR.INC
	include MEM_SEGS.INC
	include MEM_TONE.INC
.list

ifdef @RAMEXAM
DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	include MEM_CM2.INC
	extrn	CM2_FLAG:word

ifdef @LIGHTS
	extrn	LIGHTS_PORT:word
endif ; if @LIGHTS
	
	public	FUND_FREQ
FUND_FREQ dd	1193182 	; Fundamental frequency

ifdef @LIGHTS
	public	FSA_LITE
FSA_LITE label	word
	dw	offset PGROUP:INIRP_LITE ; Initialize one-time RPT variables
FSA_LITE_NXTRP label word
	dw	offset PGROUP:INIFD_LITE ; Initialize one-time FD variables
FSA_LITE_NXTFD label word
	dw	offset PGROUP:ON_LITE	 ; Turn on the lights
	dw	offset PGROUP:SDI_LITE	 ; Set duration interval
	dw	offset PGROUP:PAUSE_LITE ; Wait with lights on
	dw	offset PGROUP:SPI_LITE	 ; Set pause interval
	dw	offset PGROUP:RESET_LITE ; Turn off the lights
	dw	offset PGROUP:PAUSE_LITE ; Wait with lights off
FSA_LITE_NOPAUSE label word
	dw	offset PGROUP:NXTFD_LITE ; Try next FD value
	dw	offset PGROUP:NXTRP_LITE ; Try repeat count
	dw	offset PGROUP:STOP_LITE  ; Stop the action

	public	FSA_TAB_LITE,FSA_FD_LITE
FSA_TAB_LITE dw ?		; Offset in DGROUP of current TONETAB_STR
FSA_FD_LITE  dw ?		; Offset in DGROUP of current TONEFD_STR

	public	FSA_RPT_LITE,FSA_CNT_LITE,FSA_WAIT_LITE
FSA_RPT_LITE dw ?		; Repeat count
FSA_CNT_LITE dw ?		; # valid (freq, dur, pause) values
FSA_WAIT_LITE dw ?		; Amount to wait

	public	FSA_ACT_LITE
FSA_ACT_LITE dw 0		; Action offset for lights (0=none)
endif ; if @LIGHTS

	public	FSA_TONE
FSA_TONE label	word
	dw	offset PGROUP:INIRP_TONE ; Initialize one-time RPT variables
FSA_TONE_NXTRP label word
	dw	offset PGROUP:INIFD_TONE ; Initialize one-time FD variables
FSA_TONE_NXTFD label word
	dw	offset PGROUP:ON_TONE	 ; Turn on the tone
	dw	offset PGROUP:SDI_TONE	 ; Set duration interval
	dw	offset PGROUP:PAUSE_TONE ; Wait with tone on
	dw	offset PGROUP:SPI_TONE	 ; Set pause interval
	dw	offset PGROUP:RESET_TONE ; Turn off the tone
	dw	offset PGROUP:PAUSE_TONE ; Wait with tone off
FSA_TONE_NOPAUSE label word
	dw	offset PGROUP:NXTFD_TONE ; Try next FD value
	dw	offset PGROUP:NXTRP_TONE ; Try repeat count
	dw	offset PGROUP:STOP_TONE  ; Stop the action

	public	FSA_TAB_TONE,FSA_FD_TONE
FSA_TAB_TONE dw ?		; Offset in DGROUP of current TONETAB_STR
FSA_FD_TONE  dw ?		; ...			      TONEFD_STR

	public	FSA_RPT_TONE,FSA_CNT_TONE,FSA_WAIT_TONE
FSA_RPT_TONE dw ?		; Repeat count
FSA_CNT_TONE dw ?		; # valid (freq, dur, pause) values
FSA_WAIT_TONE dw ?		; Amount to wait

	public	FSA_ACT_TONE
FSA_ACT_TONE dw 0		; Action offset for tones (0=none)

DATA	ends			; End DATA segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	DRAINPIQ:near

	NPPROC	CHECK_FSA -- Check On FSA Activity
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on FSA activity

|

	REGSAVE <ax,si> 	; Save registers

	cld			; String ops forwardly
	
ifdef @LIGHTS
	mov	si,FSA_ACT_LITE ; Get offset of next action
	
	and	si,si		; Izit valid?
	jz	short CHECK_FSA1 ; Jump if so
@@:
	lods	DGROUP:[si].ELO ; Get offset of next routine
	
	mov	FSA_ACT_LITE,si ; Save for next time
	call	ax		; Call next routine
	jc	short @B	; Jump if we're to go around again
CHECK_FSA1:
endif ; if @LIGHTS
	mov	si,FSA_ACT_TONE ; Get offset of next action
	
	and	si,si		; Izit valid?
	jz	short CHECK_FSA2 ; Jump if so
@@:
	lods	DGROUP:[si].ELO ; Get offset of next routine
	mov	FSA_ACT_TONE,si ; Save for next time
	call	ax		; Call next routine
	jc	short @B	; Jump if we're to go around again
CHECK_FSA2:
	REGREST <si,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_FSA endp			; End CHECK_FSA procedure
ifdef @LIGHTS
	NPPROC	PLAY_LIGHTS -- Play The Lights
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Play the lights, if defined

|

PL_STR	struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
PL_OFF	dw	?		; Offset in DGROUP of TONETAB_STR

PL_STR	ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <si>		; Save register

	test	CM2_FLAG,@CM2_LIGHTS ; Izit defined?
	jz	short PLAY_LIGHTS_EXIT ; Jump if not

	mov	si,[bp].PT_OFF	; Get offset in DGROUP of TONETAB_STR

	cmp	DGROUP:[si].TONETAB_CNT,0 ; Is count zero?
	je	short PLAY_LIGHTS_END ; Jump if so

; Set variables into effect with interrupts disabled so there's
; no confusion in the underground.

	pushf			; Save flags
	cli			; Disable interrupts

	mov	FSA_TAB_LITE,si ; Save for later use
	mov	FSA_ACT_LITE,offset DGROUP:FSA_LITE ; Start at the beginning
	
	popf			; Restore flags
	
	jmp	short PLAY_LIGHTS_EXIT ; Join common exit code


; No action defined, so turn off the lights
	
PLAY_LIGHTS_END:
	call	STOP_LITE	; Stop the lights
PLAY_LIGHTS_EXIT:
	REGREST <si>		; Restore

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PLAY_LIGHTS endp		; End PLAY_LIGHTS procedure
endif ; ifdef @LIGHTS
ifdef @LIGHTS
	NPPROC	INIRP_LITE -- Initialize Repeat Value
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize repeat value

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <si>		; Save register

	mov	si,FSA_TAB_LITE ; Get offset in DGROUP of TONETAB_STR

	mov	si,DGROUP:[si].TONETAB_RPT ; Get the repeat count
	mov	FSA_RPT_LITE,si ; Save for later use
	
	stc			; Mark as continuing to next action

	REGREST <si>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIRP_LITE endp 		; End INIRP_LITE procedure
endif ; ifdef @LIGHTS
ifdef @LIGHTS
	NPPROC	INIFD_LITE -- Initialize FD Values
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize FD values

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <ax,si> 	; Save registers

	mov	si,FSA_TAB_LITE ; Get offset in DGROUP of TONETAB_STR

	mov	ax,DGROUP:[si].TONETAB_CNT ; Get # valid (freq, dur, pause) values
	mov	FSA_CNT_LITE,ax ; Save for later use
	
	lea	ax,DGROUP:[si].TONETAB_FD ; Skip to FD values
	mov	FSA_FD_LITE,ax ; Save for later use

	stc			; Mark as continuing to next action

	REGREST <si,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIFD_LITE endp 		; End INIFD_LITE procedure
endif ; ifdef @LIGHTS
ifdef @LIGHTS
	NPPROC	ON_LITE -- Turn On The Lights
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Turn on the lights

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <ax,dx,si>	; Save registers

	mov	si,FSA_FD_LITE	; Get current offset of FD struc

	mov	dx,LIGHTS_PORT	; Get the port # to use
	mov	ax,DGROUP:[si].TONEFD_FRQ ; Get the frequency
	out	dx,al		; Play the lights
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue
	
	stc			; Mark as continuing to next action

	REGREST <si,dx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ON_LITE endp			; End ON_LITE procedure
endif ; ifdef @LIGHTS
ifdef @LIGHTS
	NPPROC	SDI_LITE -- Set Duration Interval
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set duration interval

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <si>		; Save register

	mov	si,FSA_FD_LITE	; Get current offset of FD struc

	mov	si,DGROUP:[si].TONEFD_DUR ; Get the duration
	mov	FSA_WAIT_LITE,si ; Save for later use
	
	stc			; Mark as continuing to next action

	REGREST <si>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SDI_LITE endp			; End SDI_LITE procedure
endif ; ifdef @LIGHTS
ifdef @LIGHTS
	NPPROC	PAUSE_LITE -- Pause Lights
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Pause lights

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	cmp	FSA_WAIT_LITE,0 ; Izit the end?
	je	short PAUSE_LITE_EXIT ; Jump if so

	dec	FSA_WAIT_LITE	; Count out one tick

	sub	FSA_ACT_LITE,type FSA_ACT_LITE ; Restart this action
PAUSE_LITE_EXIT:
	clc			; Mark as not continuing to next action

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PAUSE_LITE endp 		; End PAUSE_LITE procedure
endif ; ifdef @LIGHTS
ifdef @LIGHTS
	NPPROC	RESET_LITE -- Reset Lights
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Reset lights

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <ax,dx> 	; Save registers

	mov	dx,LIGHTS_PORT	; Get the port # to use
	mov	al,0		; Initialization value
	out	dx,al		; Initialize the port
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	stc			; Mark as continuing to next action

	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESET_LITE endp 		; End RESET_LITE procedure
endif ; ifdef @LIGHTS
ifdef @LIGHTS
	NPPROC	SPI_LITE -- Set Pause Interval
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set pause interval

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <bx>		; Save register

	mov	bx,FSA_FD_LITE	; Get current offset of FD struc

	mov	bx,DGROUP:[bx].TONEFD_PAU ; Get the pause
	mov	FSA_WAIT_LITE,bx ; Save for later use
	
	and	bx,bx		; Izit no pause?
	jnz	short @F	; Jump if not
	
	lea	si,FSA_LITE_NOPAUSE ; Start again here
	mov	FSA_ACT_LITE,si ; Save for later use
@@:
	stc			; Mark as continuing to next action

	REGREST <bx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SPI_LITE endp			; End SPI_LITE procedure
endif ; ifdef @LIGHTS
ifdef @LIGHTS
	NPPROC	NXTFD_LITE -- Next FD Value
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Next FD value

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	cmp	FSA_CNT_LITE,1 ; Any more FD values?
	jbe	short NXTFD_LITE_EXIT ; Jump if not

	dec	FSA_CNT_LITE	; Count out another FD value

	add	FSA_FD_LITE,type TONEFD_STR ; Skip to next FD value
	lea	si,FSA_LITE_NXTFD ; Start again here
	mov	FSA_ACT_LITE,si ; Save for later use
NXTFD_LITE_EXIT:
	stc			; Mark as continuing to next action

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NXTFD_LITE endp 		; End NXTFD_LITE procedure
endif ; ifdef @LIGHTS
ifdef @LIGHTS
	NPPROC	NXTRP_LITE -- Next RPT Value
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Next RPT value

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	cmp	FSA_RPT_LITE,0 ; Any more RPT values?
	je	short NXTRP_LITE_EXIT ; Jump if not

	dec	FSA_RPT_LITE	; Count out another FD value

	lea	si,FSA_LITE_NXTRP ; Start again here
	mov	FSA_ACT_LITE,si ; Save for later use
NXTRP_LITE_EXIT:
	stc			; Mark as continuing to next action

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NXTRP_LITE endp 		; End NXTRP_LITE procedure
endif ; ifdef @LIGHTS
ifdef @LIGHTS
	NPPROC	STOP_LITE -- Stop The Lights
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Stop the lights

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	mov	FSA_ACT_LITE,0	; Mark as no more
	call	RESET_LITE	; Turn off the lights

	clc			; Mark as not continuing to next action

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STOP_LITE endp			; End STOP_LITE procedure
endif ; ifdef @LIGHTS
	NPPROC	PLAY_TONE -- Play A Tone
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Play a tone, if defined

|

PT_STR	struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
PT_OFF	dw	?		; Offset in DGROUP of TONETAB_STR

PT_STR	ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <si>		; Save register

	test	CM2_FLAG,@CM2_TONE ; Izit defined?
	jz	short PLAY_TONE_EXIT ; Jump if not

	mov	si,[bp].PT_OFF	; Get offset in DGROUP of TONETAB_STR

	cmp	DGROUP:[si].TONETAB_CNT,0 ; Is count zero?
	je	short PLAY_TONE_END ; Jump if so

; Set variables into effect with interrupts disabled so there's
; no confusion in the underground.

	pushf			; Save flags
	cli			; Disable interrupts

	mov	FSA_TAB_TONE,si ; Save for later use
	mov	FSA_ACT_TONE,offset DGROUP:FSA_TONE ; Start at the beginning
	
	popf			; Restore flags
	
	jmp	short PLAY_TONE_EXIT ; Join common exit code


; No action defined, so turn off the tone
	
PLAY_TONE_END:
	call	STOP_TONE	; Stop the tone
PLAY_TONE_EXIT:
	REGREST <si>		; Restore

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PLAY_TONE endp			; End PLAY_TONE procedure
	NPPROC	INIRP_TONE -- Initialize Repeat Value
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize repeat value

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <si>		; Save register

	mov	si,FSA_TAB_TONE ; Get offset in DGROUP of TONETAB_STR

	mov	si,DGROUP:[si].TONETAB_RPT ; Get the repeat count
	mov	FSA_RPT_TONE,si ; Save for later use
	
	stc			; Mark as continuing to next action

	REGREST <si>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIRP_TONE endp 		; End INIRP_TONE procedure
	NPPROC	INIFD_TONE -- Initialize FD Values
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize FD values

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <ax,si> 	; Save registers

	mov	si,FSA_TAB_TONE ; Get offset in DGROUP of TONETAB_STR

	mov	ax,DGROUP:[si].TONETAB_CNT ; Get # valid (freq, dur, pause) values
	mov	FSA_CNT_TONE,ax ; Save for later use
	
	lea	ax,DGROUP:[si].TONETAB_FD ; Skip to FD values
	mov	FSA_FD_TONE,ax ; Save for later use

	stc			; Mark as continuing to next action

	REGREST <si,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIFD_TONE endp 		; End INIFD_TONE procedure
	NPPROC	ON_TONE -- Turn On The Tone
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Turn on the tone

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <si>		; Save register

	mov	si,FSA_FD_TONE	; Get current offset of FD struc

	push	DGROUP:[si].TONEFD_FRQ ; Pass the frequency
	call	BEEP		; Beep the speaker

	stc			; Mark as continuing to next action

	REGREST <si>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ON_TONE endp			; End ON_TONE procedure
	NPPROC	SDI_TONE -- Set Duration Interval
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set duration interval

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <si>		; Save register

	mov	si,FSA_FD_TONE	; Get current offset of FD struc

	mov	si,DGROUP:[si].TONEFD_DUR ; Get the duration
	mov	FSA_WAIT_TONE,si ; Save for later use
	
	stc			; Mark as continuing to next action

	REGREST <si>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SDI_TONE endp			; End SDI_TONE procedure
	NPPROC	PAUSE_TONE -- Pause Tone
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Pause tone

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	cmp	FSA_WAIT_TONE,0 ; Izit the end?
	je	short PAUSE_TONE_EXIT ; Jump if so

	dec	FSA_WAIT_TONE	; Count out one tick

	sub	FSA_ACT_TONE,type FSA_ACT_TONE ; Restart this action
PAUSE_TONE_EXIT:
	clc			; Mark as not continuing to next action

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PAUSE_TONE endp 		; End PAUSE_TONE procedure
	NPPROC	RESET_TONE -- Reset Tones
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Reset tones

|

	REGSAVE <ax>		; Save registers

	in	al,@8255_B	; Read it in
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	and	al,not ((mask $SPKR) or (mask $TIMER2)) ; Turn off Spkr & Timer2
	out	@8255_B,al	; Tell 8255 about it
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	stc			; Mark as continuing to next action

	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESET_TONE endp 		; End RESET_TONE procedure
	NPPROC	SPI_TONE -- Set Pause Interval
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set pause interval

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	REGSAVE <bx>		; Save register

	mov	bx,FSA_FD_TONE	; Get current offset of FD struc

	mov	bx,DGROUP:[bx].TONEFD_PAU ; Get the pause
	mov	FSA_WAIT_TONE,bx ; Save for later use
	
	and	bx,bx		; Izit no pause?
	jnz	short @F	; Jump if not
	
	lea	si,FSA_TONE_NOPAUSE ; Start again here
	mov	FSA_ACT_TONE,si ; Save for later use
@@:
	stc			; Mark as continuing to next action

	REGREST <bx>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SPI_TONE endp			; End SPI_TONE procedure
	NPPROC	NXTFD_TONE -- Next FD Value
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Next FD value

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	cmp	FSA_CNT_TONE,1 ; Any more FD values?
	jbe	short NXTFD_TONE_EXIT ; Jump if not

	dec	FSA_CNT_TONE	; Count out another FD value

	add	FSA_FD_TONE,type TONEFD_STR ; Skip to next FD value
	lea	si,FSA_TONE_NXTFD ; Start again here
	mov	FSA_ACT_TONE,si ; Save for later use
NXTFD_TONE_EXIT:
	stc			; Mark as continuing to next action

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NXTFD_TONE endp 		; End NXTFD_TONE procedure
	NPPROC	NXTRP_TONE -- Next RPT Value
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Next RPT value

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	cmp	FSA_RPT_TONE,0 ; Any more RPT values?
	je	short NXTRP_TONE_EXIT ; Jump if not

	dec	FSA_RPT_TONE	; Count out another FD value

	lea	si,FSA_TONE_NXTRP ; Start again here
	mov	FSA_ACT_TONE,si ; Save for later use
NXTRP_TONE_EXIT:
	stc			; Mark as continuing to next action

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NXTRP_TONE endp 		; End NXTRP_TONE procedure
	NPPROC	STOP_TONE -- Stop The Tone
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Stop the tone

On exit:

CF	=	1 to continue with next action now
	=	0 not

|

	mov	FSA_ACT_TONE,0	; Mark as no more
	call	RESET_TONE	; Turn off the tone

	clc			; Mark as not continuing to next action

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STOP_TONE endp			; End STOP_TONE procedure
	NPPROC	BEEP -- Beep On Key
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

BEEP_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
BEEP_FRQ dw	?		; Frequency

BEEP_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,cx,dx>	; Save registers

; Program timer 2 to generate square wave

	mov	al,(2*@TIMER_CH) or @TIMER_LMSB or (3*@TIMER_MODE) or @TIMER_BIN
;;;;;;; mov	al,10110110b	; 10xxxxxx = Timer 2,
				; xx11xxxx = Read/write LSB, then MSB
				; xxxx011x = Mode 3
				; xxxxxxx0 = Binary
	out	@8253_CTL,al	; Send to control register
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	dx,FUND_FREQ.EHI ; Hi part of fundamental frequency
	mov	ax,FUND_FREQ.ELO ; Lo part ...
	mov	cx,[bp].BEEP_FRQ ; CX = frequency

	cmp	cx,dx		; Ensure above high-order word
	ja	short BEEP1	; It's OK

	mov	cx,dx		; Use minimum to avoid divide overflow
	inc	cx
BEEP1:
	div	cx		; AX = 8253 counter value, DX ignored

	out	@8253_CH2,al	; Send LSB to timer 2
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	mov	al,ah		; Copy MSB of value
	out	@8253_CH2,al	; Send MSB to timer 2
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

; Read current state of 8255, port B

	in	al,@8255_B	; Read it in
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	or	al,(mask $SPKR) or (mask $TIMER2) ; Turn on Spkr & Timer2
	out	@8255_B,al	; Tell 8255 about it
	call	DRAINPIQ	; Drain the Prefetch Instruction Queue

	REGREST <dx,cx,ax>	; Restore

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BEEP	endp			; End BEEP procedure

CODE	ends			; End CODE segment
endif ; ifdef @RAMEXAM

	MEND			; End MEM_FSA module

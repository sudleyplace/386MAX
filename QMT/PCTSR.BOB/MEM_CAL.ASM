;' $Header:   P:/PVCS/MAX/QMT/MEM_CAL.ASV   1.0   05 Sep 1995 16:55:38   HENRY  $
	title	MEM_CAL -- MEMCHK Calibration Routines
	page	58,122
	name	MEM_CAL

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
	include 386.INC
	include PTR.INC
	include 8253.INC
	include ALLMEM.INC

	include MEM_COM.MAC
	include MEM_SEGS.INC
.list

DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	SEL_4GB:word

	extrn	TIMETAB:tbyte,TIMECNT:word
	include MEM_TIME.INC

	extrn	BPU:dword

	extrn	ZAPOFF:word
	
	extrn	REG0UP:dword
	extrn	REG0DN:dword
	extrn	REG1UP:dword
	extrn	REG1DN:dword

	public	CALIB_W0
	public	CALIB_R0DN
	public	CALIB_R0W1
	public	CALIB_R0W1DN
	public	CALIB_R0W1W0DN
	public	CALIB_R0W1R1
	public	CALIB_R0W1R1W0R0W1
	public	CALIB_R1W0
	public	CALIB_R1W0DN
	public	CALIB_R1W0R0DN
	public	CALIB_R1W0W1
	public	CALIB_R1W0W1W0DN
CALIB_W0	    CALIB_STR <>
CALIB_R0DN	    CALIB_STR <>
CALIB_R0W1	    CALIB_STR <>
CALIB_R0W1DN	    CALIB_STR <>
CALIB_R0W1W0DN	    CALIB_STR <>
CALIB_R0W1R1	    CALIB_STR <>
CALIB_R0W1R1W0R0W1  CALIB_STR <>
CALIB_R1W0	    CALIB_STR <>
CALIB_R1W0DN	    CALIB_STR <>
CALIB_R1W0R0DN	    CALIB_STR <>
CALIB_R1W0W1	    CALIB_STR <>
CALIB_R1W0W1W0DN    CALIB_STR <>

	public	CALIB_SIZ,CALIB_IND
CALIB_SIZ dd	1024*128	; Size in bytes of calibration
CALIB_IND dw	?		; Index into TIMETAB of 1st available entry

DATA	ends			; End DATA segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP

	extrn	CHECK_HALT:near
	extrn	ZAPREST:near

	NPPROC	CALIBRATE -- Calibrate Macros For ETA Timings
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calibrate macros for ETA timings

On entry:

TIMETAB has been filled in.

|

	push	es		; Save selector

	pushad			; Save all EGP registers

	mov	es,SEL_4GB	; Get AGROUP selector
	assume	es:AGROUP	; Tell the assembler about it

; Search through TIMETAB for the first available entry >= 1KB
; which we can use for calibrations.  We need some memory on which
; we can execute each of the macros.

	 mov	 cx,TIMECNT	; Get # entries
	 xor	 bx,bx		; Initialize index into TIMETAB
	 mov	 edx,CALIB_SIZ	; Get calibration size in bytes
CALIB_NEXT1:
	 test	 TIMETAB[bx].TT_FLAG,@TT_UNALL ; Izit unallocated?
	 jnz	 short CALIB_LOOP1 ; Jump if so

	 cmp	 edx,TIMETAB[bx].TT_LEN ; Izit big enough?
	 jbe	 short CALIB1	; Jump if so
CALIB_LOOP1:
	 add	 bx,size TT_STR ; Skip to next entry

	 loop	 CALIB_NEXT1	; Jump if more entries to check

	 jmp	 CALIB_EXIT	; Jump if no entries to time????

CALIB1:
	 mov	 CALIB_IND,bx	; Save for later use

;===============================================================================

;;;;;;;; movzx	 eax,TIMETAB[bx].TT_WIDTH ; Get the data width (8, 16, or 32)
	 mov	 eax,32 	; Use 32 as we're doing DWORD tests only
	 shr	 eax,3-0	; Convert from bits per byte to bytes
	 mov	 BPU,eax	; Save as bytes per unit

; Execute each of the macros under control of our timing mechanism
; and save the timings for later use.  Note we test for dword width only
; as there shouldn't be any difference (except possibly for the string
; instructions).

	 xor	 edx,edx	; Store zero times to get overhead
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 W0_MAC 	   CALIB,2,EDD,eax,D,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_W0.CALIB_OVHD,eax ; Save for later use

; Do it again in case there's a caching issue which artifically
; inflates the initial timing

	 xor	 edx,edx	; Store zero times to get overhead
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 W0_MAC 	   CALIB,2,EDD,eax,D,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_W0.CALIB_OVHD,eax ; Save for later use

	 mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 W0_MAC 	   CALIB,2,EDD,eax,D,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX

; Somehow the timing for zero can exceed the timing for CALIB_SIZ,
; so we check for that here and avoid a negative number.

	 sub	 eax,CALIB_W0.CALIB_OVHD ; Less overhead to get per iteration time
	 jae	 short @F	; Jump if non-negative

	 xor	 eax,eax	; Use overhead of zero
@@:
	 mov	 CALIB_W0.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

	mov	edx,CALIB_SIZ	; Get calibration size in bytes
	call	TIMER_SETUP	; Initialize timer channel 2
	R0DN_MAC	   CALIB,2,EDD,eax,D,CAL
	call	TIMER_READ	; Latch and read timer 2 value into EAX
	mov	CALIB_R0DN.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

;;;;;;;; mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 R0W1_MAC	   CALIB,2,EDD,eax,D,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_R0W1.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

;;;;;;;; mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 R0W1DN_MAC	   CALIB,2,EDD,eax,D,REG0UP,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_R0W1DN.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

;;;;;;;; mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 R0W1W0DN_MAC	   CALIB,2,EDD,eax,D,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_R0W1W0DN.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

;;;;;;;; mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 R0W1R1_MAC	   CALIB,2,EDD,eax,D,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_R0W1R1.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

;;;;;;;; mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 R0W1R1W0R0W1_MAC  CALIB,2,EDD,eax,D,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_R0W1R1W0R0W1.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

;;;;;;;; mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 R1W0_MAC	   CALIB,2,EDD,eax,D,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_R1W0.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

;;;;;;;; mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 R1W0DN_MAC	   CALIB,2,EDD,eax,D,REG0UP,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_R1W0DN.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

;;;;;;;; mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 R1W0R0DN_MAC	   CALIB,2,EDD,eax,D,REG1DN,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_R1W0R0DN.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

;;;;;;;; mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 R1W0W1_MAC	   CALIB,2,EDD,eax,D,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_R1W0W1.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

;;;;;;;; mov	 edx,CALIB_SIZ	; Get calibration size in bytes
	 call	 TIMER_SETUP	; Initialize timer channel 2
	 R1W0W1W0DN_MAC    CALIB,2,EDD,eax,D,REG1UP,CAL
	 call	 TIMER_READ	; Latch and read timer 2 value into EAX
	 mov	 CALIB_R1W0W1W0DN.CALIB_PERIT,eax ; Save as per iteration time

;===============================================================================

	 call	 TIMER_RESTORE	; Restore timer channel 2
CALIB_EXIT:
	 popad			; Restore all EGP registers

	 pop	 es		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALIBRATE endp			; End CALIBRATE procedure
	 NPPROC  TIMER_SETUP -- Setup Timer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SPEED	 equ	 8		; Assume worst case of 8MHz CPU

DELAY1US macro			; Delay for 1 miscrosecond

	 push	 cx		; Save for a moment
	 mov	 cx,1+1000/(11*SPEED) ; Account for CPU speed
	 loop	 $		; Wait for completion
	 pop	 cx		; Restore

	 endm

TIMER_SET equ	 (0*@TIMER_CH) or @TIMER_LMSB or (2*@TIMER_MODE) or @TIMER_BIN

	 REGSAVE <ax>		; Save register

	 mov	 al,TIMER_SET	; Setup counter 0, mode 2
	 out	 @8253_CTL,al
	 DELAY1US		; Wait for 1 microsecond

	 xor	 al,al		; Zero gives full count of 65536
	 out	 @8253_CH0,al	; Load low-order byte
	 DELAY1US		; Wait for 1 microsecond

	 out	 @8253_CH0,al	; Load high-order byte
	 DELAY1US		; Wait for 1 microsecond

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIMER_SETUP endp		; End TIMER_SETUP procedure
	 NPPROC  TIMER_RESTORE -- Restore Timer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIMER_RESET equ  (0*@TIMER_CH) or @TIMER_LMSB or (3*@TIMER_MODE) or @TIMER_BIN

	 REGSAVE <ax>		; Save register

	 mov	 al,TIMER_RESET ; Setup counter 0, mode 3
	 out	 @8253_CTL,al
	 DELAY1US		; Wait for 1 microsecond

	 xor	 al,al		; Zero gives full count of 65536
	 out	 @8253_CH0,al	; Load low-order byte
	 DELAY1US		; Wait for 1 microsecond

	 out	 @8253_CH0,al	; Load high-order byte
	 DELAY1US		; Wait for 1 microsecond

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIMER_RESTORE endp		; End TIMER_RESTORE procedure
	 NPPROC  TIMER_READ -- Read Timer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIMER_LATCH equ  @TIMER_LATCH or (0*@TIMER_CH)

	 xor	 eax,eax	; Zero to use as dword

	 mov	 al,TIMER_LATCH ; Tell 8253 to latch channel 0

	 out	 @8253_CTL,al	; Latch current contents
	 DELAY1US		; Wait for 1 microsecond

	 in	 al,@8253_CH0	; Read in low-order byte
	 DELAY1US		; Wait for 1 microsecond

	 mov	 ah,al		; Copy
	 in	 al,@8253_CH0	; Read in high-order byte
	 DELAY1US		; Wait for 1 microsecond

	 xchg	 al,ah		; Swap for comparisons
	 neg	 ax		; Convert count down to count up

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIMER_READ endp 		; End TIMER_READ procedure

CODE	 ends			; End CODE segment

	 MEND			; End MEM_CAL module

;' $Header:   P:/PVCS/MAX/QUILIB/DCACHE.ASV   1.1   30 May 1997 12:09:00   BOB  $
	 title	 DCACHE -- Disk cache detection routines
	 page	 58,122
	 name	 DCACHE

COMMENT |		Module Specifications

Copyright:  (C) Copyright 1991-97 Qualitas, Inc.  All rights reserved.

Segmentation:  MASM 5.1 simplified segmentation

Link requirements:  Meant to be called from MSC 6.0

Program derived from:  None.

Original code by:  Henry Groover, September, 1991.

Modifications by:  None.

|

%.model  &MODEL,c

.xlist
include MASM.INC
include PTR.INC
include DOSCALL.INC
include KEYCALL.INC
include VIDCALL.INC
.list

.data

	 public  Fhandle,Memhandle,dcache_dly
	 public  dcache_spin,dcache_spinptr,Orig_page,Orig_csr,Orig_chr
	 public  Save_csr,Save_page,Twirly_active,InWindows,Twirly_page
	 public  Twirly_csr
Fhandle  dw	?		; File handle
Memhandle dw	?		; Segment of memory block
dcache_dly dw	?		; Delay in timer tics if DCACHE_WRITEDLY
dcache_spin db	'-\|/'          ; Animated display for cache test
dcache_spinptr dw 0		; Offset in dcache_spin of current character
Orig_page db	?		; Active page on entry (should be 0)
Orig_chr db	?		; Original contents of spinning cursor box
Orig_csr dw	?		; Cursor coordinates on entry
Save_csr dw	?		; Saved cursor during Int 8
Save_page db	?		; Saved display page during Int 8
Twirly_active db 0		; 1 if helicopter active
InWindows db	?		; Set if in Win386
Twirly_page db	 ?		; Page to display helicopter in
Twirly_csr dw	 ?		; Cursor position to display helicopter in

.code

	 public  Oldint8,Oldint13,Oldboot13,Oldint23,Oldint24,Int13hit,Result
	 public  dcache_cnt,dcache_spincnt,last_i13_drv
Oldint8  dd	?		; Previous Int 8 handler
Oldint13 dd	?		; Int 13 vector returned by 2f fn 13
Oldboot13 dd	?		; Reboot int 13 vector ...
Oldint23 dd	?		; Previous Int 23 handler
Oldint24 dd	?		; Previous Int 24 handler
Int13hit dw	?		; Int 13 hit flag
Result	dw	?		; Result to return
dcache_cnt dw	?		; Elapsed timer tics waiting for write
dcache_spincnt db ?		; Current spin count (modulo @SPINTICKS)
@SPINTICKS equ	4		; Timer ticks between spin update (~0.25 sec)
last_i13_drv db ?		; Last drive for Int 13 functions 0-4

SET_OUR_INT macro intnum

	 mov	 al,0&intnum&h		; Interrupt vector to get
	 DOSCALL @GETINT		; ES:BX ==> current handler
	 assume  es:nothing		; Tell the assembler

	 mov	 Oldint&intnum.VSEG,es	; Save original interrupt handler
	 mov	 Oldint&intnum.VOFF,bx	; ...

	 push	 cs			; Segment of our handler
	 pop	 ds			; Prepare for @SETINT call
	 assume  ds:nothing		; Tell the assembler

	 mov	 al,0&intnum&h		; Interrupt vector to set
	 DOSCALL @SETINT,our_int&intnum ; Install our handler

	 endm				; End SET_OUR_INT macro

REST_OUR_INT macro intnum

	 lds	 dx,Oldint&intnum	; Get original Int 8 handler
	 assume  ds:nothing		; Tell the assembler

	 mov	 al,0&intnum&h		; Interrupt vector to restore
	 DOSCALL @SETINT		; Restore original Int 8 handler

	 endm				; End REST_OUR_INT macro

	 NPPROC  GET_CVID -- Get current video contents
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Get current video info and cursor position/contents.

On exit:
AL	 Character under cursor
BH	 Active display page
CX	 Destroyed
DH	 Cursor row
DL	 Cursor column

|

	 VIDCALL @GETINF	; Get mode, BH = current page
	 push	 bx		; Save
	 VIDCALL @GETPOS	; Get cursor position for page BH
	 pop	 bx		; Restore
	 push	 bx		; Save page
	 push	 dx		; Save cursor row,col
	 VIDCALL @GETCAT	; AL = character under cursor
	 pop	 dx		; Restore cursor position
	 pop	 bx		; Restore active page

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GET_CVID endp			; End GET_CVID procedure

	 NPPROC  SET_CVID -- Set current video contents
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Set current video page and cursor position/contents.

On entry:
AL	 Character to restore (if 0, ignore)
BH	 New active display page
DH	 Cursor row
DL	 Cursor column

On exit:
All GP registers destroyed.

|

	 push	 ax		; Save character to restore

	 push	 bx		; Save new page number
	 push	 dx		; Save new cursor position
	 mov	 al,bh		; Get display page
	 VIDCALL @SETPAG	; Set current display page to AL
	 pop	 dx		; Get new cursor row,col
	 pop	 bx		; Get current page

	 push	 bx		; Save it
	 VIDCALL @SETPOS	; Set cursor for page BH to DH,DL
	 pop	 bx		; Get current page

	 pop	 ax		; Get character to restore

	 mov	 cx,1		; Number of reps
	 or	 al,al		; Should we ignore it?
	 jz	 short @F	; Jump if so

	 VIDCALL @SETCHR	; Write AL to page BH CX times
@@:

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SET_CVID endp			; End SET_CVID procedure

	 FPPROC  our_int13 -- Local Int 13 intercept routine
	 assume  ds:nothing,es:nothing,ss:nothing

	 pushf			; Save flags
	 inc	 Int13hit	; Keep track of number of calls
	 cmp	 ah,4		; Izit in the 0-4 range?
	 ja	 short @F	; Jump if not

	 mov	 last_i13_drv,dl ; Save drive accessed
@@:
	 popf			; Restore
	 jmp	 Oldint13	; Join previous handler

	 assume  ds:nothing,es:nothing,ss:nothing
our_int13	endp		; End our_int13

	 FPPROC  our_boot13 -- Local int 13 boot-time intercept routine
	 assume  ds:nothing,es:nothing,ss:nothing

	 inc	 Int13hit	; Count this as a hit, too
	 jmp	 Oldboot13	; Join boot-time int 13 code

	 assume  ds:nothing,es:nothing,ss:nothing
our_boot13	 endp		; End our_boot13

	 FPPROC  our_int8 -- Local Int 8 intercept routine
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT&

Keep track of write delays.
Write a spinning character to the screen every 9 ticks, or
at about every half second (/-\|).

&

	 inc	 dcache_cnt	; Bump counter
	 dec	 dcache_spincnt ; Adjust spin counter
	 jz	 short @F	; Jump if time to update screen

	 jmp	 Oldint8	; Join previous int 8 code

@@:
	 pushf			; Simulate interrupt
	 call	 Oldint8	; Call previous handler, sending EOI to PIC

	 sti			; Re-enable interrupts
	 REGSAVE <ax,bx,cx,dx,si,di,bp,ds,es> ; Save

	 mov	 ax,seg DGROUP	; Get data segment
	 mov	 ds,ax		; Prepare to address it
	 assume  ds:DGROUP	; Tell the assembler

; Save cursor position
	 call	 GET_CVID	; AL=char, BH=page, DX=cursor
	 mov	 Save_page,bh	; Save current page
	 mov	 Save_csr,dx	; Save cursor position

; Display spin character
	 mov	 bx,dcache_spinptr ; Get index of next character
	 mov	 al,dcache_spin[bx] ; Get spin character
	 inc	 bx		; Advance to next
	 and	 bx,4-1 	; ...modulo 4
	 mov	 dcache_spinptr,bx ; Save index

	 mov	 bh,Twirly_page ; Get page on entry
	 mov	 dx,Twirly_csr	; Get cursor slot
	 call	 SET_CVID	; Write AL to cursor DH,DL in page BH

; Restore cursor position
	 sub	 al,al		; Don't write character
	 mov	 bh,Save_page	; Get previous current page
	 mov	 dx,Save_csr	; Get previous cursor position
	 call	 SET_CVID	; Restore current page and cursor position

	 REGREST <es,ds,bp,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler

	 cli			; Nobody move
	 mov	 dcache_spincnt,@SPINTICKS ; Reset display countdown

	 iret			; Return to point of interruption

	 assume  ds:nothing,es:nothing,ss:nothing
our_int8	 endp		; End our_int8

	 FPPROC  our_int23 -- Local Int 23 intercept routine
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Ignore Ctrl-C and Ctrl-Break completely.

|

	 iret			; Return to caller (ignore)

	 assume  ds:nothing,es:nothing,ss:nothing
our_int23	 endp		; End our_int23

	 FPPROC  our_int24 -- Local Int 24 intercept routine
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Fail all critical errors.

|

	 mov	 al,3		; Fail
	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
our_int24	 endp		; End our_int24

	 NPPROC  READ_BUFF -- Seek to beginning, and read data from file
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Clear hit flag, seek to beginning of test file,
read into buffer, and check test flag.

The caller needs to call DOS function 0D (flush buffers) before
calling this procedure if read caching is being tested.  When
testing write caching, we avoid the flush buffers function, because
this also causes SMARTDRV.EXE to reset.  DOS' BUFFERS will not
buffer writes, so this will not cause false positives.

On entry:
SS:BP ==>	ARG_STR

On exit:
CF	=	0 if OK
		1 if error occurred
ZF	=	1 if no calls to original Int 13 occurred
		0 if one or more calls to Int 13
AX,BX,CX,DX	Contents lost

|

; Clear hit flag
	 mov	 Int13hit,0		; Clear flag

; Seek to beginning of file
	 mov	 bx,Fhandle		; Get file handle
	 sub	 dx,dx			; 0 offset
	 mov	 cx,dx			; High word of position
	 sub	 al,al			; Seek from beginning
	 DOSCALL @MOVFP2		; Move read/write pointer to CX:DX
	 jc	 short Readbuff_err	; Jump if it failed

; Read it in
	 push	 ds			; Save for a moment

	 mov	 bx,Fhandle		; Get file handle
	 mov	 cx,[bp].blksiz 	; Number of bytes to read
	 sub	 dx,dx			; Starting offset
	 mov	 ds,Memhandle		; Get memory block
	 assume  ds:nothing		; Tell the assembler

	 DOSCALL @READF2		; Read CX bytes from file BX at DS:DX

	 pop	 ds			; Restore DS
	 assume  ds:DGROUP		; Tell the assembler

	 jc	 short Readbuff_err	; Jump if it failed

	 cmp	 Int13hit,0		; Did any calls to Int 13 occur?
					; Return with ZF significant
Readbuff_err:				; Return with CF significant
	 ret		; Return
	 assume ds:nothing,es:nothing,ss:nothing

READ_BUFF	endp		; End READ_BUFF

ARG_STR struc
		dw	?	; BP saved locally on stack
if @codesize
		dd	?	; caller's far return address
else
		dw	?	; near return address
endif
if @datasize
	fname	dd	?	; far ptr to filename for testing
else
	fname	dw	?	; near ptr to  filename for testing
endif
	blksiz	dw	?	; Size of block to test in bytes
	max_dly dw	?	; Maximum delay in timer tics
ARG_STR ends

	 PPROC	save_dcvid -- Save video prior to calling dcache_active
	 assume ds:DGROUP,es:nothing,ss:nothing
COMMENT|

The baton twirling exhibition staged by dcache_active clobbers
one character at the cursor position on entry.	Here's where we
save it.

On exit:
AX,BX,CX,DX trashed.

|

; Get cursor position and active page on entry and save the character there.
	 call	 GET_CVID	; AL=char, BH=page, DX=cursor row/col
	 mov	 Orig_chr,al	; Save for later
	 mov	 Orig_page,bh	; Save page
	 mov	 Orig_csr,dx	; DH,DL = cursor row,col

	 ret			; Return to caller

	 assume ds:nothing,es:nothing,ss:nothing

save_dcvid endp 		; End save_dcvid procedure

	 PPROC	rest_dcvid -- Restore video after calling dcache_active
	 assume ds:DGROUP,es:nothing,ss:nothing
COMMENT|

The baton twirling exhibition staged by dcache_active clobbers
one character at the cursor position on entry.	Here's where we
restore it.

On exit:
AX,BX,CX,DX trashed.

|

	 mov	 al,Orig_chr		; Original character
	 mov	 bh,Orig_page		; Current page
	 mov	 dx,Orig_csr		; Get original cursor row,col in DH,DL
	 call	 SET_CVID		; Restore page, cursor and character

	 ret			; Return to caller

	 assume ds:nothing,es:nothing,ss:nothing

rest_dcvid endp 		; End rest_dcvid procedure

	 PPROC	start_twirly -- Begin helicopter display at cursor position
	 assume ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Beginning spinning helicopter blade display at current cursor
location.

On exit:
AX,BX,CX,DX trashed.

|

	 REGSAVE <ds,es>		; Save registers trashed by SET_OUR_INT

	 cmp	 Twirly_active,0	; Are we already displaying it?
	 jne	 short STWIRL_EXIT	; Jump if so

	 mov	 Twirly_active,1	; Mark as active

; Get cursor position and active page on entry and save for display.
	 call	 GET_CVID		; AL=char, BH=page, DX=cursor row/col
	 mov	 Twirly_page,bh 	; Save page
	 mov	 Twirly_csr,dx		; DH,DL = cursor row,col

	 mov	 dcache_spincnt,@SPINTICKS ; Reset spin countdown timer

	 SET_OUR_INT <8>		; Install Int 8 handler

STWIRL_EXIT:
	 REGREST <es,ds>		; Restore
	 assume  ds:nothing,es:nothing	; Tell the assembler

	 ret				; Return to caller

	 assume ds:nothing,es:nothing,ss:nothing

start_twirly endp		; End start_twirly procedure

	 PPROC	end_twirly -- End helicopter display
	 assume ds:nothing,es:nothing,ss:nothing
COMMENT|

End spinning helicopter blade display and restore previous contents
of screen at cursor location.

On exit:
AX,BX,CX,DX trashed.

|

	 REGSAVE <ds>			; Save

	 mov	 ax,seg DGROUP		; Prepare to address data segment
	 mov	 ds,ax			; Address DGROUP
	 assume  ds:DGROUP		; Tell the assembler

	 cmp	 Twirly_active,0	; Are we currently displaying it?
	 je	 short ETWIRL_EXIT	; Jump if not (nothing to do)

	 REST_OUR_INT <8>		; Restore original Int 8

; Restore the character at the cursor position on entry.
	 mov	 ax,seg DGROUP		; Prepare to address data segment
	 mov	 ds,ax			; Address DGROUP
	 assume  ds:DGROUP		; Tell the assembler

	 sub	 al,al			; Restore page and cursor only
	 mov	 bh,Twirly_page 	; Current page
	 mov	 dx,Twirly_csr		; Get original cursor row,col in DH,DL
	 call	 SET_CVID		; Restore page, cursor and character

	 mov	 Twirly_active,0	; Mark as inactive
ETWIRL_EXIT:
	 REGREST <ds>			; Restore
	 assume  ds:nothing		; Tell the assembler

	 ret				; Return to caller

	 assume ds:nothing,es:nothing,ss:nothing

end_twirly endp 		; End end_twirly procedure

	 PPROC	dcache_active -- Test whether disk caching is active
	 assume ds:DGROUP,es:nothing,ss:nothing
COMMENT|

int dcache_active (char *fname, unsigned int max_dly);
Test whether disk caching is active for the drive specified by the temporary
file name (which it is assumed we can read and write to).  If delayed write
caching is in effect, wait a maximum of max_dly timer tics to find out how
long the delay is.

On entry:
Stack contains ASCIIZ pointer to filename

On exit:
AX	=	-1 if unable to determine (DOS version < 3.30 or other failure
		0 if not
		1 if disk cache appears to be active
		2 if write-through caching is active
		4 if delayed write caching is active; dcache_dly contains
		  effective delay in timer tics.
		5 if device does not appear to be a regular Int 13h device
last_i13_drv =	last DL value on an Int 13 function 0-4 call

|

	 push	 bp			; save bp
	 mov	 bp, sp 		; get stack frame

	 REGSAVE <bx,cx,dx,si,di,ds,es> ; save registers

	 mov	 Result,-1		; Assume failure

	 DOSCALL @DOSVER		; Get DOS version: AH=minor, AL=major
	 cmp	 al,3			; Izit DOS 3?
	MJ b	 dca_err		; Can't determine anything

	 ja	 short @F		; 2F fn 13 is OK

	 cmp	 ah,30			; Izit 3.30?
	 jnb	 short @F		; 2F fn 13 is OK

	 jmp	 dca_no2f		; No 2F call available

@@:
; Flush any pending delayed writes
	 DOSCALL @DRESET		; Reset disk

	 mov	 Int13hit,0		; Clear flag
	 mov	 last_i13_drv,0ffh	; Set last drive to known bogus value
	 mov	 Fhandle,-1		; Mark file as closed
	 mov	 Memhandle,-1		; Mark segment as unallocated
	 mov	 InWindows,0		; Assume we're not in Win386

	 mov	 ax,1600h		; Win386 installation check
	 int	 2fh			; Call Windows-DOS API
	 test	 al,7fh 		; Izit 80h or 00h?
	 jz	 short @F		; Jump if so (Windows not running)

	 cmp	 al,1			; Izit Windows 2.x?
	 je	 short @F		; Jump if so

	 cmp	 al,-1			; Izit (also) Windows 2.x?
	 je	 short @F		; Jump if so

	 mov	 InWindows,1		; Set local flag
	 mov	 ax,1681h		; Enter critical section
	 int	 2fh			; Call Windows-DOS API

@@:
;	 ========== Begin critical section ============
	 call	 start_twirly		; Set up helicopter display
	 SET_OUR_INT <23>		; Install Ctrl-C/Ctrl-Break handler
	 SET_OUR_INT <24>		; Install critical error handler

	 mov	 ax,cs			; Get segment for interrupt handlers
	 mov	 ds,ax			; Segment for Int 13 handler
	 mov	 es,ax			; Segment for boot-time int 13
	 assume  ds:nothing,es:nothing	; Tell the assembler

	 mov	 dx,offset Our_int13	; Offset of int 13 handler
	 mov	 bx,offset Our_boot13	; Offset of boot-time int 13
	 mov	 ah,13h 		; Set disk handler
	 int	 2fh			; Call multiplex function
	 assume  ds:nothing,es:nothing	; DS:DX and ES:BX are original handlers

	 cli				; Nobody move...
	 mov	 Oldint13.VSEG,ds	; Save original int 13 handler
	 mov	 Oldint13.VOFF,dx	; Save offset...
	 mov	 Oldboot13.VSEG,es	; Save boot-time int 13 handler
	 mov	 Oldboot13.VOFF,bx	; Save offset...
	 sti				; Enable interrupts

	 mov	 ax,seg DGROUP		; Get data segment
	 mov	 ds,ax			; Prepare to address DGROUP
	 mov	 es,ax			; Load ES
	 assume  ds:DGROUP,es:DGROUP	; Tell the assembler

	 mov	 bx,[bp].blksiz 	; Number of bytes to allocate
	 mov	 cl,4-0 		; Convert bytes to paras
	 shr	 bx,cl			; BX = paras to allocate
	 adc	 bx,0			; Round up
	 DOSCALL @GETMEM		; Get handle to BX paras in AX
	MJ c	 DCA_CLEANUP		; Jump if we failed

	 mov	 Memhandle,ax		; Save allocated block

	 push	 ds			; Save for a moment

if @datasize
	 lds	 dx,[bp].fname		; Get pointer to filename
	 assume  ds:nothing		; Tell the assembler about it
else
	 mov	 dx,[bp].fname		; Get near ptr to filename
endif
	 sub	 cx,cx			; No attributes (normal)
	 DOSCALL @CREAF2		; Create file

	 pop	 ds			; Restore our data segment
	 assume  ds:nothing		; Tell the assembler

	MJ c	 DCA_CLEANUP		; If we failed, bail out

	 mov	 Fhandle,ax		; Save file handle

; Fill our memory block with random data
	 push	 es			; Save for a moment

	 mov	 es,Memhandle		; Get segment
	 assume  es:nothing		; Tell the assembler

	 mov	 cx,[bp].blksiz 	; Number of bytes to fill
	 shr	 cx,1			; Convert to word count
	 sub	 di,di			; Point to beginning
	 mov	 ax,di			; Start with 0

DCA_FILL_BLK:
	 stos	 es:[di].ELO		; Store AX
	 dec	 al			; Change low byte
	 inc	 ah			; Change high byte
	 jnz	 short @F		; Jump if not zero

	 inc	 ah			; Skip 0 in high byte
@@:
	 loop	 DCA_FILL_BLK		; Fill it in

	 pop	 es			; Restore es
	 assume  es:DGROUP		; Tell the assembler

	 push	 ds			; Save for a moment
	 mov	 ds,Memhandle		; Get segment
	 assume  ds:nothing		; Tell the assembler

; Write to file
	 mov	 bx,Fhandle		; Get file handle
	 mov	 cx,[bp].blksiz 	; Number of bytes to write
	 sub	 dx,dx			; Starting offset
	 DOSCALL @WRITF2		; Write to file in BX

	 pop	 ds			; Restore our DS
	 assume  ds:DGROUP		; Tell the assembler

	MJ c	 DCA_CLEANUP		; Jump if we failed

; Duplicate file handle
	 mov	 bx,Fhandle		; Get file handle
	 DOSCALL @FHCOPY		; Duplicate it
	MJ c	 DCA_CLEANUP		; Jump if we failed

; Close duplicate to flush file
	 mov	 bx,ax			; Get duplicate handle
	 DOSCALL @CLOSF2		; Close it
	MJ c	 DCA_CLEANUP		; Jump if we failed

	 mov	 Int13hit,0		; Clear hit flag

	 mov	 dcache_cnt,1		; Set minimum value for counter
	 sub	 bx,bx			; Record last write occurrence
DCA_WRITEDLY_TEST:
	 mov	 ax,dcache_cnt		; Get current value of counter

	 cmp	 Int13hit,0		; Did a write occur?
	 jz	 short @F		; Jump if not

	 mov	 bx,ax			; Save occurrence of last write
	 mov	 Int13hit,0		; Clear flag
	 jmp	 short DCA_WRITEDLY_TEST ; Go around again

@@:
; Since we've shut off Ctrl-C/Ctrl-Break, we allow antsy users to
; press any key to cut the disk cache test short after the first half
; second.  This still allows us to detect write-delayed caches,
; although the delay value will be inaccurate, when the user has stuffed
; a keystroke into the buffer before entry to this routine.
	 cmp	 ax,1+9 		; Did minimum delay expire?
	 jb	 short DCA_CHECKDLY	; Jump if not

	 REGSAVE <ax>			; Save
	 KEYCALL @GETKST		; AX=scan code, ZF=0 if key pressed
	 jz	 short @F		; Jump if no key pressed

	 pushf				; Save flags from get status
	 KEYCALL @GETKEY		; Flush keystroke from buffer
	 popf				; Restore flags (ZF significant)
@@:
	 REGREST <ax>			; Restore
	 jnz	 short DCA_KEYPRESSED	; Jump if user pressed a key

DCA_CHECKDLY:
	 sub	 ax,bx			; Get time elapsed since last activity
	 cmp	 ax,[bp].max_dly	; Did we exceed maximum delay?
	 jb	 short DCA_WRITEDLY_TEST ; Go around again if not

DCA_KEYPRESSED:
; If no writes occurred, assume no write delays
	 or	 bx,bx			; Did we get any delayed writes?
	 jnz	 short DCA_WRITEDLY	; Jump if so

; In case it's holding out on us (like SMARTDRV.EXE might) and responds
; to DOS function 0Dh (like SMARTDRV.EXE will), poke it and see if it jumps...
	 push	 dcache_cnt		; Save current timer count
	 DOSCALL @DRESET		; Reset disk
	 pop	 bx			; Save it in case something happened

	 cmp	 Int13hit,0		; Did it twitch?
	 jne	 short DCA_WRITEDLY	; Jump if so

; If Int 13 never got hit with a valid request, it's probably a RAM drive
	 cmp	 last_i13_drv,0ffh	; Izit the original bogus value?
	 jne	 short DCA_NOWRITEDLY	; Jump if not (test for write-through)

	 mov	 Result,5		; Device is not a hard disk
	 jmp	 short DCA_CLEANUP	; Join common exit code

DCA_WRITEDLY:
	 mov	 dcache_dly,bx		; Save elapsed timer tics
	 mov	 Result,4		; Delayed write caching is active
	 jmp	 short DCA_CLEANUP	; Join common exit code

DCA_NOWRITEDLY:
	 call	 READ_BUFF		; Read from file
	 jc	 short DCA_CLEANUP	; Jump if we failed

	 jnz	 short @F		; Try again - writes may not be buffered

	 mov	 Result,2		; Writes are buffered
	 jmp	 short DCA_CLEANUP	; Join common exit code

@@:
; Tell DOS to reset disk (flushing buffers)
; This will also reset SMARTDRV.EXE's buffers, so we cannot detect
; it unless write-through caching is enabled.
	 DOSCALL @DRESET		; Reset disk

	 call	 READ_BUFF		; Try reading a second time
	 jc	 short DCA_CLEANUP	; Jump if we failed

	 jnz	 short @F		; Failed again - hopeless

	 mov	 Result,1		; Reads are buffered
	 jmp	 short DCA_CLEANUP	; Join common exit code

@@:
	 mov	 Result,0		; No buffering at all

	 Public  DCA_CLEANUP
DCA_CLEANUP:

	 lds	 dx,Oldint13		; Get original int 13 handler
	 assume  ds:nothing		; Tell the assembler
	 les	 bx,Oldboot13		; Get original boot-time int 13
	 assume  es:nothing		; Tell the assembler

	 mov	 ah,13h 		; Set disk handler (this time, restore)
	 int	 2fh			; Call multiplex function
	 assume  ds:nothing,es:nothing	; Disregard return

	 REST_OUR_INT <24>		; Restore critical error handler
	 REST_OUR_INT <23>		; Restore Ctrl-C/Ctrl-break handler
	 call	 end_twirly		; Stop helicopter
;	 ========== (end critical section) ============

	 mov	 ax,seg DGROUP		; Prepare to address data segment
	 mov	 ds,ax			; Address DGROUP
	 assume  ds:DGROUP		; Tell the assembler

	 mov	 bx,Fhandle		; Get file handle
	 cmp	 bx,-1			; Izit closed?
	 je	 short @F		; Jump if so

	 DOSCALL @CLOSF2		; Close file handle in BX
	 mov	 Fhandle,-1		; Mark as closed
@@:
	 cmp	 Memhandle,-1		; Izit de-allocated?
	 je	 short @F		; Jump if so

	 mov	 es,Memhandle		; Get memory segment
	 assume  es:nothing		; Tell the assembler
	 DOSCALL @RELMEM		; Free block at ES
	 mov	 Memhandle,-1		; Mark as freed

@@:
	 cmp	 InWindows,1		; Are we in Windows?
	 jne	 short @F		; Jump if not

	 mov	 ax,1682h		; End critical section
	 int	 2fh			; Call Windows-DOS API

@@:
dca_no2f:
dca_err:
	 mov	 ax,Result		; Get return value

	 REGREST <es,ds,di,si,dx,cx,bx> ; restore caller's registers
	 assume  ds:nothing,es:nothing	; Tell the assembler

	 pop	 bp			; restore bp

	 ret			; return to caller (caller pops arguments)

	 assume ds:nothing,es:nothing,ss:nothing

dcache_active	ENDP			; End dcache_active

	END				; DCACHE module


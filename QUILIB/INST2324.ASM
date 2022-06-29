;' $Header:   P:/PVCS/MAX/QUILIB/INST2324.ASV   1.1   30 May 1997 12:09:02   BOB  $
	 title	 INST2324 -- Subroutines to handle INTh 23 and 24h
	 page	 58,122
	 name	 INST2324

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1985-97 Qualitas, Inc.  All rights reserved.

Segmentation:  per .MODEL directive

Link requirements:  None, standalone subroutine.

Program derived from:  PD_SUB.ASM

Original code by:  Bob Smith, July, 1986.

Modifications by:  Patrick Devlin, December, 1990

Modifications by:  Alan C. Lindsay, June 1991, August 1991

	This module contains 3 functions:

void _cdecl inst2324(void);

	Installs the INT 23 and INT 24 handlers.

void _cdecl done2324(void);

	De-Installs the INT 23 and INT 24 handlers.

void _cdecl enable23(void);

	Enables INT 23 processing.

void _cdecl disable23(void);

	Disables INT 23 processing.

void _cdecl set24_resp (int resp);

	Sets action for critical error or 0 to call display_criterr


	This module also has 3 externals, all of which must be provided by
the caller:

int _cdecl chkabort(void);		/* Confirm abort request */

	Asks user if he want's to abort, returns 1 if yes, 0 if no.

int _cdecl display_criterr (	/* Display critical error window */
	int flag,		/* 0 = device error, 1 = disk error */
	char *aritxt);		/* Error message to display */

	(Typically) makes a pop-up window to display the specified
error message.	Reads and returns one character, which should be
'A', 'R', or 'F' (defined in \include\intrnatl.inc)

void _cdecl abortprep(		/* Prepare to exit program */
	int flag);		/* 0 if called thru ctrl-break */
				/* 1 if called thru critical error */

	Does any cleanup needed by the program prior to aborting.

	This version also has additional code to hook ints 1Bh and 29h to
prevent the "^C" from popping up on the screen.

|
.xlist
	 include MASM.INC
	 include PTR.INC
	 include ASCII.INC
	 include DOSCALL.INC
	 include DEVDRV.INC
	 include 386.INC	; .. to get CSOVR macro

.list

%.model  &MODEL

	 .data

ifdef C700
	 extrn _STKHQQ:word	; Thanks, Microsoft
STKHQQ	 equ	_STKHQQ
else
	 extrn STKHQQ:word	; Lowest safe stack value (used by _chkstk)
endif				; IFDEF C7

INT23_FLAG dw	 0		; INT 23 enabled flag
INT1B_FLAG dw	 0		; INT 1B occurred flag
INT1B_SKIP dw	 0		; INT 1B disable flag

	 public  DEVHDR_VEC,DEVDRVNO
DEVHDR_VEC dd	 ?		; Device driver header address for INT 24h
DEVDRVNO db	 ?		; Drive # if block device

; Maximum length 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
ifdef LANG_GR
INT24_ERR0 db	 'Schreibschutz-Fehler',0
INT24_ERR1 db	 'Fehler, ungÅltige Einheit',0
INT24_ERR2 db	 'Fehler, nicht bereit',0
INT24_ERR3 db	 'Unpassender Befehl fÅr',0
INT24_ERR4 db	 'Datenfehler',0
INT24_ERR5 db	 'Unpassender Aufruf fÅr',0
INT24_ERR6 db	 'Suchfehler auf',0
INT24_ERR7 db	 'Fehler, keine DOS-Platte',0
INT24_ERR8 db	 'Sektor nicht gefunden auf',0
INT24_ERR9 db	 'Offline oder Papier-Ende an',0
INT24_ERRA db	 'Schreib-Fehler auf',0
INT24_ERRB db	 'Lese-Fehler auf',0
INT24_ERRC db	 'Allgemeiner Fehler auf',0
else
INT24_ERR0 db	 'Write protect error on',0
INT24_ERR1 db	 'Bad unit error on',0
INT24_ERR2 db	 'Not ready error on',0
INT24_ERR3 db	 'Bad command to',0
INT24_ERR4 db	 'Data error on',0
INT24_ERR5 db	 'Bad call format to',0
INT24_ERR6 db	 'Seek error on',0
INT24_ERR7 db	 'Non-DOS disk error on',0
INT24_ERR8 db	 'Sector not found on',0
INT24_ERR9 db	 'Offline or no paper on',0
INT24_ERRA db	 'Write fault error on',0
INT24_ERRB db	 'Read fault error on',0
INT24_ERRC db	 'General Failure on',0
endif				; IFDEF LANG_GR

	 public  DRVMSG
; Maximum length 'XXXXXXXXXXX'
ifdef LANG_GR
DRVMSG	 db	 'Laufwerk: '       ; Text for INT 24h message
else
DRVMSG	 db	 'drive '       ; Text for INT 24h message
endif				; IFDEF LANG_GR
DRVMSGLEN equ	 $-DRVMSG

	 align	 2
	 public  INT24_MSGS
INT24_MSGS dw	 DGROUP:INT24_ERR0
	 dw	 DGROUP:INT24_ERR1
	 dw	 DGROUP:INT24_ERR2
	 dw	 DGROUP:INT24_ERR3
	 dw	 DGROUP:INT24_ERR4
	 dw	 DGROUP:INT24_ERR5
	 dw	 DGROUP:INT24_ERR6
	 dw	 DGROUP:INT24_ERR7
	 dw	 DGROUP:INT24_ERR8
	 dw	 DGROUP:INT24_ERR9
	 dw	 DGROUP:INT24_ERRA
	 dw	 DGROUP:INT24_ERRB
	 dw	 DGROUP:INT24_ERRC
INT24_MSGS_LEN equ ($-INT24_MSGS) ; # entries

	 public  CALLER_STACK,ARIMSG
CALLER_STACK	 dd	?		; SS:SP on entry to INT24, INT23
ARIMSG	 db	 48 dup(0)		; INT24_ERRx message + device name or
					; 'drive d'

	 public  INT24_RESP
INT24_RESP	 db	0		; Default is to call display_criterr

;
;  This stuff is for debugging.  It puts trace characters out to the
; mono screen, if you've got one.
;
;;XPTR	 dw	 0,0b000h
;;
;;DOIT	 MACRO	 xc
;;	 push	 es
;;	 push	 di
;;	 push	 ax
;;	 les	 di,dword ptr XPTR
;;	 mov	 al,xc
;;	 mov	 ah,0fh
;;	 stosw
;;	 mov	 XPTR,di
;;	 pop	 ax
;;	 pop	 di
;;	 pop	 es
;;	 ENDM

	 .code

if @codesize
	 extrn	 _display_criterr:far
	 extrn	 _chkabort:far
	 extrn	 _abortprep:far
else
	 extrn	 _display_criterr:near
	 extrn	 _chkabort:near
	 extrn	 _abortprep:near
endif

OLDINT23_VEC dd  ?		; ...			23h
OLDINT24_VEC dd  ?		; ...			24h
OLDINT1B_VEC dd  ?		; ...			1Bh
OLDINT29_VEC dd  ?		; ...			29h

	 public  IDATASEG
IDATASEG  dw	 seg DGROUP	; Segment of our data group

SETUP_STACK	macro	stacksize
	 ; Set up a safe stack -- many C functions assume SS == DS
	 mov	 CALLER_STACK.VSEG,ss ; Save SS
	 mov	 CALLER_STACK.VOFF,sp ; Save SP
	 mov	 bx,STKHQQ	; Get minimum stack value
	 add	 bx,stacksize	; Add bytes requested
	 cli			; Disable interrupts
	 mov	 ss,IDATASEG	; Get stack segment
	 assume  ss:nothing	; Tell the assembler
	 mov	 sp,bx		; Get stack pointer
	 sti			; Enable interrupts
	 endm			; Macro SETUP_STACK

RESTORE_STACK	 macro
	 cli			; Nobody move
	 mov	 ss,CALLER_STACK.VSEG ; Restore SS
	 mov	 sp,CALLER_STACK.VOFF ; Restore SP
	 sti			; Enable interrupts
	 endm			; Macro RESTORE_STACK

	 PPROC	 _inst2324 -- Install INTs 23h and 24h
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Install INTs 23h and 24h

|

	 REGSAVE <ax,bx,dx,ds,es> ; Save registers

; Intercept old handlers

	 mov	 al,23h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT23_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT23_VEC.VSEG,es

	 mov	 al,24h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT24_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT24_VEC.VSEG,es

	 mov	 al,1Bh 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT1B_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT1B_VEC.VSEG,es

	 mov	 al,29h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT29_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT29_VEC.VSEG,es

	 mov	 INT23_FLAG,1	; Mark as INT 23h enabled

; Install our own handlers

	 push	 cs		; Get our code segment
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,23h 	; Install this one
	 DOSCALL @SETINT,INT23	; Install it

	 mov	 al,24h 	; Install this one
	 DOSCALL @SETINT,INT24	; Install it

	 mov	 al,1Bh 	; Install this one
	 DOSCALL @SETINT,INT1B	; Install it

	 mov	 al,29h 	; Install this one
	 DOSCALL @SETINT,INT29	; Install it

	 REGREST <es,ds,dx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_inst2324 endp			; End _INST2324 procedure

	 PPROC	 _done2324 -- De-Install INTs 23h and 24h
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

De-Install INTs 23h and 24h

|

	 REGSAVE <ax,bx,dx,ds,es> ; Save registers

; Put the old handlers back

	 push	 ds
	 pop	 es		; Set ES = DS
	 assume  ds:nothing,es:DGROUP ; Tell the assembler about it

	 mov	 al,23h 	; Install this one
	 lds	 dx,OLDINT23_VEC
	 DOSCALL @SETINT	; Install it

	 mov	 al,24h 	; Install this one
	 lds	 dx,OLDINT24_VEC
	 DOSCALL @SETINT	; Install it

	 mov	 al,1Bh 	; Install this one
	 lds	 dx,OLDINT1B_VEC
	 DOSCALL @SETINT	; Install it

	 mov	 al,29h 	; Install this one
	 lds	 dx,OLDINT29_VEC
	 DOSCALL @SETINT	; Install it

	 REGREST <es,ds,dx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_done2324 endp			; End _DONE2324 procedure

	 PPROC	 _enable23 -- Enable INT 23h Handler
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Enable INT 23h handler.

|

	 REGSAVE <ax,ds>	; save registers

	 mov	 INT23_FLAG,1 ; Enable INT 23h handler

	 REGREST <ds,ax>	; restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_enable23 endp			; End _ENABLE23 procedure

	 PPROC	 _disable23 -- Disable INT 23h Handler
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Disable INT 23h handler.

|

	 REGSAVE <ax,ds>	; save registers

	 mov	 INT23_FLAG,0	; Disable INT 23h handler

	 REGREST <ds,ax>	; restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_disable23 endp 		; End _DISABLE23 procedure

	 FPPROC  INT23 -- Control-Break Interrupt Handler
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Control-break interrupt handler

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save registers

	 mov	 ds,IDATASEG	; Get our data segment
	 assume  ds:DGROUP	; Tell the assembler about it

;;	 DOIT	 '3'

	 mov	 INT1B_FLAG,0	; Clear the int 1B flag

	 cmp	 INT23_FLAG,1	; Izit enabled?
	 jne	 short INT23_NOSTACK ; No, ignore it (note ZF=0)

	 ; Set up a safe stack -- many C functions assume SS == DS
	 SETUP_STACK	1024	; Allocate 1024 bytes on C stack

; Ensure this is what the user wants to do

	 mov	 INT1B_SKIP,1
	 call	 _chkabort	; Check on it, returning 1 if abort, 0 if not
	 mov	 INT1B_SKIP,0

	 cmp	 ax,1		; Should we abort?

	 RESTORE_STACK		; Restore caller's SS:SP
INT23_NOSTACK:
; ZF=1	 Abort
; ZF=0	 Continue
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 jne	 short INT23_IGNORE ; Jump if not aborting

	 stc			; Mark as aborting
	 ret			; Return to caller via RETF

INT23_IGNORE:
	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INT23	 endp			; End INT23 procedure

	 FPPROC  INT24 -- Critical Error Interrupt Handler
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Critical error interrupt handler

Handle "Abort, Retry, Ignore?" choices.

On entry:

AL	 =	 drive # if block
AH	 =	 flags
DI	 =	 low-order half has error code
BP:SI	 ==>	 device header

|

INT24_STR struc

INT24_BP dw	 ?		; Caller's BP
INT24_IP dw	 ?		; ...	   IP
INT24_CS dw	 ?		; ...	   CS
INT24_FL dw	 ?		; ...	   FL

INT24_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <bx,cx,dx,si,di,ds,es> ; Save registers

	 sti			; Allow other interrupts
	 cld

	 mov	 ds,IDATASEG	; Get our data segment
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,IDATASEG	; Get our data segment
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 DEVDRVNO,al	; Save drive #
	 mov	 DEVHDR_VEC.VOFF,si ; Save address of device header
	 mov	 si,[bp].INT24_BP ; Get caller's BP
	 mov	 DEVHDR_VEC.VSEG,si  ; Save

	 mov	 INT1B_SKIP,1	; Disable INT 1B till finished

	 ; Set up a safe stack -- many C functions assume SS == DS
	 SETUP_STACK	1024	; Set up valid stack for C code

	 and	 di,0FFh	; Zero upper half to use as word
	 shl	 di,1		; Times two to index table of words

	 cmp	 di,2*0Ch	; Check against maximum
	 jbe	 short INT24_MOVE ; It's within range

	 mov	 di,2*0Ch	; Call it a "General failure error"
INT24_MOVE:
	 mov	 si,INT24_MSGS[di] ; DS:SI ==> error message

	 lea	 di,ARIMSG	; ES:DI ==> message buffer
@@:
	 cmp	 ds:[si].LO,0	; Izit the end-of-the-string?
	 movsb			; Move one byte
	 jne	 short @B	; Jump if not

	 mov	 es:[di-1].LO,' ' ; Blast terminating zero

	 push	 ds		; Save for a moment

	 lds	 si,DEVHDR_VEC	; DS:SI ==> device header
	 assume  ds:nothing	; Tell the assembler about it

	 test	 [si].DD_ATTR,DRV_ATTR_CHAR ; Check for block vs. char device
	 jz	 short INT24_BLK ; It's block, so we'll use drive in AL

	 lea	 si,[si].DD_NAME ; Point to actual character device name
	 mov	 cx,8		; # bytes in device name to move

     rep movsb			; Move the device name to output area

	 pop	 ds		; Restore
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 bx,0		; Flag device error
	 jmp	 short INT24_COM ; Join common code

	 assume  ds:nothing	; Tell the assembler about it

INT24_BLK:
	 pop	 ds		; Restore
	 assume  ds:DGROUP	; Tell the assembler about it

	 lea	 si,DRVMSG	; DS:SI ==> "drive "
	 mov	 cx,DRVMSGLEN	; CX = length of message
     rep movsb			; Move the text to output area
	 mov	 al,DEVDRVNO	; AL = drive # (origin-0)
	 add	 al,'A'         ; Convert to drive letter
	 stosb			; Store in output area
	 mov	 bx,1		; Flag disk error

INT24_COM:
	 ; Terminate the string
	 mov	 al,LF		; '\n'
	 stosb
	 mov	 al,LF		; '\n'
	 stosb
	 mov	 al,0		; '\0'
	 stosb

; Display the error message
; Registers may be clobbered after calling the C programs

INT24_UNK:
	 push	 bp		; Save for a moment
	 mov	 bp,sp		; Capture current stack pointer
if @datasize
	 mov	 ax,seg DGROUP	   ; Pass segment of window descriptor
	 push	 ax
endif
	 lea	 ax,ARIMSG	; Pass offset of text to display
	 push	 ax

	 push	 bx		; Pass device/disk flag

	 mov	 al,INT24_RESP	; Get default response
	 or	 al,al		; Izit set?
	 jnz	 short @F	; Jump if so

	 call	 _display_criterr ; Call C program to display the window
				; returning uppercase key value in AX
	 assume  es:nothing	; Tell the assembler about it

@@:
	 mov	 sp,bp		; Restore previous stack pointer
	 pop	 bp		; Restore


;;;;;;	 cmp	 al,@NATL_IGNORE ; Check for Ignore action
;;;;;;	 je	 short INT24_IGNORE ; Jump if so

	 cmp	 al,@NATL_FAIL	; Check for Fail action
	 je	 short INT24_FAIL ; Jump if so

	 cmp	 al,@NATL_RETRY ; Check for Retry action
	 je	 short INT24_RETRY ; Jump if so

	 cmp	 al,@NATL_ABORT ; Check for Abort action
	 jne	 short INT24_UNK ; Not this time, try again

	 DOSCALL @DOSVER	; Get DOS version # done to ensure DOS
				; is in a stable state

	 push	 bp		; Save for a moment
	 mov	 bp,sp		; Capture current stack pointer

	 mov	 ax,1		; Flag call thru critical error handler
	 push	 ax

	 call	 _abortprep

	 mov	 sp,bp		; Restore previous stack pointer
	 pop	 bp		; Restore

	 mov	 al,2		; Return code for abort

	 jmp	 short INT24_EXIT ; Join common exit code

INT24_FAIL:
	 mov	 al,3		; Return code for fail

	 jmp	 short INT24_EXIT ; Join common exit code

INT24_RETRY:
	 mov	 al,1		; Return code for retry

	 jmp	 short INT24_EXIT ; Join common exit code

INT24_IGNORE:
	 mov	 al,0		; Return code for ignore
INT24_EXIT:
	 RESTORE_STACK		; Restore caller's SS:SP

	 mov	 INT1B_SKIP,0	; Enable INT 1B again

	 REGREST <es,ds,di,si,dx,cx,bx> ; Restore registers
	 assume  ds:nothing,es:nothing

	 pop	 bp		; Restore

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INT24	 endp			; End INT24 procedure


	 PPROC	 _enable29 -- Enable INT 29h Handler
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Enable INT 29h handler.

|

	 mov	 INT1B_FLAG,0	; Clear int 1B flag
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_enable29 endp			; End _ENABLE29 procedure


	 PPROC	 _disable29 -- Disable INT 29h Handler
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Disable INT 29h handler.

|

	 mov	 INT1B_FLAG,1	; Make like an INT 1B happened
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_disable29 endp 		; End _DISABLE29 procedure



	 FPPROC  INT1B -- Lower level Control-Break Interrupt Handler
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Lower level Control-break interrupt handler

|

	 REGSAVE <ax,ds> ; Save registers

	 mov	 ds,IDATASEG	; Get our data segment
	 assume  ds:DGROUP	; Tell the assembler about it

;;	 DOIT	 'B'

	 test	 INT1B_SKIP,1	; Should we ignore this interrupt?
	 jnz	 INT1B_IGNORE

	 mov	 INT1B_FLAG,1	; Set flag

	 pushf
	 call	 OLDINT1B_VEC	; Call the 'real' 1B handler to set DOS flag

INT1B_IGNORE:
	 REGREST <ds,ax> ; Restore
	 assume  ds:nothing,es:nothing,ss:nothing

	 iret			; ...and return to caller

INT1B	 endp			; End INT1B procedure


	 FPPROC  INT29 -- Device output Interrupt Handler
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Device output interrupt handler

|

	 REGSAVE <ds>		; Save registers

	 mov	 ds,IDATASEG	; Get our data segment
	 assume  ds:DGROUP	; Tell the assembler about it

;;	 DOIT	 '9'

	 test	 INT1B_FLAG,1	; Izit disabled?
	 jnz	 short INT29_IGNORE ; Yes, ignore it


	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 OLDINT29_VEC	; Go on to next handler

INT29_IGNORE:
	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INT29	 endp			; End INT29 procedure


	 PPROC	 _set24_resp -- Set default response for Int 24 handler
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

If a default response (such as 'F') is set, that value will be
processed in lieu of a response from display_criterr().  If the
default is 0 (the initial value), display_criterr() will be called
on all critical errors.

|

setresp_str struc

	 dw	 ?		; Caller's BP
	 dw	 (1+@codesize) dup (?) ; Caller's IP or CS:IP
response dw	 ?		; Default response
setresp_str ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 mov	 ax,[bp].response ; Get new value
	 mov	 INT24_RESP,al	; Save for use in INT24

	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_set24_resp endp		; End _SET24_RESP procedure

	 MEND			; End of module


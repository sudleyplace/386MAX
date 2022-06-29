;	TITLE	RVMX		R:base Virtual Memory eXtender.
	PAGE	60,132
;=======================================================================
;
;	RVMX - R:base Virtual Memory eXtender.
;
;	Assembly Instructions:
;
comment |

masm rvmxtsr,,rvmxtsr;
link rvmxtsr;
del rvmxtsr.obj
exe2bin rvmxtsr.exe rvmx.com
del rvmxtsr.exe

masm rvmxdev,,rvmxdev;
link rvmxdev;
del rvmxdev.obj
exe2bin rvmxdev.exe rvmx.sys
del rvmxdev.exe

|
;=======================================================================
;
;DEV_DRIV	equ	1		; Enables device driver version
MDA_TEST	EQU	1		; Enables test for monochrome adapter
;
;	Locations in BIOS data segment
;
DATA		SEGMENT AT 40H			; AT 40H

		ORG	13H
MEMORY_SIZE	DW	?		; 640

		ORG	49H

CRT_MODE	DB	?		; 3
CRT_COLS	DW	?		; 80
CRT_LEN		DW	?		; 16384
CRT_START	DW	?		; 0
CURSOR_POSN	DW	8 DUP(?)	; 0

CURSOR_MODE	DW	?		; 0
ACTIVE_PAGE	DB	?		; 0
ADDR_6845	DW	?		; 03D4H
CRT_MODE_SET	DB	?		; 29H
CRT_PALETTE	DB	?		; 0

DATA		ENDS
;
;	General Equates
;
VID_INT   equ 10h	; Which interrupt we're messing with
VIDEO_RAM equ 0b800h	; Where the video RAM is
SET_TEST  equ 3fh	; Our secret code to talk to installed driver
;
;=======================================================================
;
;	The first section is the resident part of the program.	It
;  contains ONLY the interrupt handler.  Everything else, including
;  the code for hardware changeovers, lives only in the non-resident
;  copy of the program.
;
;=======================================================================
;
code	segment para
	assume cs:code,ds:code,ss:code,es:code
	ifdef	DEV_DRIV
;
;	This is actually a dummy device driver.  It acts like a
; null device, eating any data sent to it, and never returning
; data if asked.  Its only purpose is to hold the resident RVMX
; code that's been hooked into INT 10.
;
	ORG	0		;Starts at an offset of zero.
;
;-----------------------------------------------+
;     DWORD pointer to next device              |
;         (-1,-1 if last device)                |
;-----------------------------------------------+
;     Device attribute WORD                     ;
;       Bit 15 = 1 for chacter devices.         ;
;                0 for Block devices.           ;
;                                               ;
;       Charcter devices. (Bit 15=1)            ;
;         Bit 0 = 1  current sti device.        ;
;         Bit 1 = 1  current sto device.        ;
;         Bit 2 = 1  current NUL device.        ;
;         Bit 3 = 1  current Clock device.      ;
;                                               ;
;         Bit 13 = 1 for non IBM machines.      ;
;                  0 for IBM machines only.     ;
;         Bit 14 = 1 IOCTL control bit.         ;
;-----------------------------------------------+
;     Device strategy pointer.                  ;
;-----------------------------------------------+
;     Device interrupt pointer.                 ;
;-----------------------------------------------+
;     Device name field.                        ;
;       Character devices are any valid name    ;
;         left justified, in a space filled     ;
;         field.                                ;
;       Block devices contain # of units in     ;
;         the first byte.                       ;
;-----------------------------------------------+
;
;	Header for device
;
RVMXDEV	DW	-1,-1
	DW	8000H
	DW	STRATEGY
	DW	INTERRUPT
	DB	"RVMXDRVR"
;
RVMXTBL	DW	INIT		;0  - Init. Inter. 3 board
	DW	DEVEXIT		;1  - Media check (Not used)
	DW	DEVEXIT		;2  - Get Bios Parameter Block (Not used)
	DW	CMDERR		;3  - Reserved. (Returns an error)
	DW	DEVEXIT		;4  - Character read. (Destructive)
	DW	DEVEXIT		;5  - Character read. (Non-destructive)
	DW	DEVEXIT		;6  - Return status. (Not used)
	DW	DEVEXIT		;7  - Flush Input buffer.
	DW	DEVEXIT		;8  - Character write.
	DW	DEVEXIT		;9  - Character write with verify.
	DW	DEVEXIT		;10 - Character write status.
	DW	DEVEXIT		;11 - Flush output buffer. (Not used.)
	DW	DEVEXIT		;12 - IO Control.
;
;Define offsets for io data packet
;
IODAT	STRUC
CMDLEN	DB	?		;LENGTH OF THIS COMMAND
DUNIT	DB	?		;SUB UNIT SPECIFIER
CMD	DB	?		;COMMAND CODE
STATUS	DW	?		;STATUS
	DB	8 DUP (?)
MEDIA	DB	?		;MEDIA DESCRIPTOR
TRANS	DD	?		;TRANSFER ADDRESS
COUNT	DW	?		;COUNT OF BLOCKS OR CHARS
START	DW	?		;FIRST BLOCK TO TRANSFER
IODAT	ENDS
;
PTRSAV	DD	0		;Strategy pointer save.
;
; Simplistic Strategy routine for non-multi-Tasking system.
;   Currently just saves I/O packet pointers in PTRSAV for
;   later processing by the individual interrupt routines.
;
STRATP	PROC	FAR
STRATEGY:
	MOV	WORD PTR CS:[PTRSAV],BX
	MOV	WORD PTR CS:[PTRSAV+2],ES
	RET
STRATP	ENDP
;
; Auxilary interrupt routine for processing I/O packets.
;
INTERRUPT: PUSH	SI
	MOV	SI,OFFSET RVMXTBL
;
; Common program for handling the simplistic I/O packet
;   processing scheme in MSDOS 2.0
;
ENTRY:	PUSH	AX		;Save all nessacary registers.
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	BP
	PUSH	DS
	PUSH	ES
	PUSH	BX
;
	LDS	BX,CS:[PTRSAV]	;Retrieve pointer to I/O Packet.
;
	MOV	AL,[BX.DUNIT]	;AL = Unit code.
	MOV	AH,[BX.MEDIA]	;AH = Media descriptor.
	MOV	CX,[BX.COUNT]	;CX = Contains byte/sector count.
	MOV	DX,[BX.START]	;DX = Starting Logical sector.
;
	XCHG	DI,AX		;Move Unit & Media into DI temporarily.
	MOV	AL,[BX.CMD]	;Retrieve Command type. (1 => 11)
	XOR	AH,AH		;Clear upper half of AX for calculation.
	ADD	SI,AX		;Compute entry pointer in dispatch table.
	ADD	SI,AX
	CMP	AL,11		;Verify that not more than 11 commands.
	JA	CMDERR		;Ah, well, error out.
	XCHG	AX,DI		;Move Unit & Media back where they belong.
	LES	DI,[BX.TRANS]	;ES:DI contains Transfer address.
	PUSH	CS
	POP	DS		;Data segment same as Code segment.
	JMP	WORD PTR [SI]	;Perform I/O packet command.
;
	PAGE
;
CMDERR:	MOV	AL,3		;Set unknown command error #.
;
;  Common error processing routine.
;   AL contains actual error code.
;
;   Error # 0 = Write Protect violation.
;           1 = Unkown unit.
;           2 = Drive not ready.
;           3 = Unknown command in I/O packet.
;           4 = CRC error.
;           5 = Bad drive request structure length.
;           6 = Seek error.
;           7 = Unknown media discovered.
;           8 = Sector not found.
;           9 = Printer out of paper.
;          10 = Write fault.
;          11 = Read fault.
;          12 = General failure.
;
ERREXIT:
	MOV	AH,10000001B	;Set error and done bits.
	STC			;Set carry bit also.
	JMP	SHORT EXIT1	;Quick way out.
;
EXITP	PROC	FAR		;Normal exit for device drivers.
;
DEVEXIT:	MOV	AH,00000001B	;Set done bit for MSDOS.
EXIT1:	LDS	BX,CS:[PTRSAV]
	MOV	[BX.STATUS],AX	;Save operation compete and status.
;
	POP	BX		;Restore registers.
	POP	ES
	POP	DS
	POP	BP
	POP	DI
	POP	DX
	POP	CX
	POP	AX
	POP	SI
	RET		;RESTORE REGS AND RETURN
EXITP	ENDP
;
	else
SEGST	EQU	$

	org	5ch
FCB	db	?		; Default fcb in PSP

	org	100h
main:				; Main program starts here.
	jmp	main1		; ..but jumps over the resident code.
	endif	;DEV_DRIV
;
;	Data for the resident portion
;
VIDEO_INT   DD	?		; Address of the ROM routines
CURR_STATE  DB	0		; Current state:  Are we on or off?
	public end_seg
end_seg dw	0b800h

;
	page
;========================================================================
;
;	INT 10 dispatcher.
;
;	What we do here is:
;
;	1.  Intercept AH=0, and ignore any attempt to change video modes.
;	2.  Intercept AH=2, and use our own code to position the cursor.
;	3.  Pass everything else on to the real INT 10h handler.
;
;========================================================================
;
OUR_INT10 PROC	FAR
	ASSUME	CS:CODE,DS:NOTHING,ES:NOTHING,SS:NOTHING
;
	cmp	ah,SET_TEST	; special case - set/test installed
	je	i10_test
;
	push	ax		; save AX.
	mov	al,CURR_STATE
	cmp	al,'E'		; enabled
	pop	ax		; restore AX.
	jne	i10_nix 	; if not enabled.
;
	cmp	ah,0
	je	our_code	; ignore AH=0.
	cmp	ah,2
	je	our_code	; process AH=2.
	cmp	ah,12h
	je	our_code	; ignore AH=12.
	cmp	ah,1ah
	je	our_code	; ignore AH=1a.
	cmp	ah,1bh
	je	our_code	; ignore AH=1b.
	cmp	ah,5
	je	our_code	; process AH=5.
	cmp	ah,14		; and AH=14.
	jne	i10_nix
	cmp	al,7
	jne	our_code	; process AH=14, if AL <> 7
;
i10_nix: JMP	CS:VIDEO_INT	; else, go on to "real" interrupt handler
;
i10_test:
	cmp	al,0		; special case - test state
	jne	i10_setflag
	mov	al,CURR_STATE	; This is our hook to signal installed/enabled/disabled
	IRET
;
;	This is all we do here to enable or disable.
;	The hardware changeover is handled by the non-TSR code.
;
i10_setflag:
	mov	CURR_STATE,al
	IRET
;

;---- INT 10 ------------------------------------------------------------
; VIDEO I/O								;
;	JUST LIKE MOM'S, ONLY WITH A FEW TWISTS				;
;------------------------------------------------------------------------
;
	ASSUME	CS:CODE,DS:DATA,ES:NOTHING,SS:CODE

M1	 LABEL	 WORD
	DW	OFFSET VIDEO_RETURN	; 0
	DW	OFFSET VIDEO_RETURN	; 1
	DW	OFFSET SET_CPOS 	; 2
	DW	OFFSET VIDEO_RETURN	; 3
	DW	OFFSET VIDEO_RETURN	; 4
	DW	OFFSET ACT_DISP_PAGE	; 5
	DW	OFFSET VIDEO_RETURN	; 6
	DW	OFFSET VIDEO_RETURN	; 7
	DW	OFFSET VIDEO_RETURN	; 8
	DW	OFFSET VIDEO_RETURN	; 9
	DW	OFFSET VIDEO_RETURN	; 10
	DW	OFFSET VIDEO_RETURN	; 11
	DW	OFFSET VIDEO_RETURN	; 12
	DW	OFFSET VIDEO_RETURN	; 13
	DW	OFFSET WRITE_TTY	; 14
M1L	EQU	$-M1			; that's all

our_code:
	STI			; interrupts back on
	CLD			; set direction forward
	PUSH	ES
	PUSH	DS
	PUSH	DX
	PUSH	CX
	PUSH	BX
	PUSH	SI
	PUSH	DI
	PUSH	AX		; save ax value
	MOV	AL,AH		; get into low byte
	XOR	AH,AH		; zero to high byte
	SAL	AX,1		; *2 for table lookup
	MOV	SI,AX		; put into si for branch
	CMP	AX,M1L		; test for within range
	JB	M2		; branch around branch
	POP	AX		; throw away the parameter
	JMP	VIDEO_RETURN	; do nothing if not in range
M2:
	CALL	DDS
	MOV	AX,0b800h	; = VIDEO_RAM
M3:
	MOV	ES,AX		; setup segment register
	POP	AX		; recover value
	MOV	AH,CRT_MODE	; current crt mode
	JMP	WORD PTR CS:[SI+OFFSET M1]

VIDEO_RETURN:
	POP	DI
	POP	SI
	POP	BX
M15:
	POP	CX
	POP	DX
	POP	DS
	POP	ES
	IRET

DDS	PROC	NEAR
	PUSH	AX
	MOV	AX,40H			; set up DS as BIOS data segment
	MOV	DS,AX
	POP	AX
	RET
DDS	ENDP

;------------------------------------------------------------------------
; SET_CPOS								;
;									;
;------------------------------------------------------------------------

SET_CPOS PROC	NEAR
	MOV	CL,BH
	XOR	CH,CH			; established loop count
	SAL	CX,1
	MOV	SI,CX
	MOV	[SI+OFFSET CURSOR_POSN],DX
	CMP	ACTIVE_PAGE,BH
	JNZ	M17
	MOV	AX,DX
	CALL	M18
M17:
	JMP	VIDEO_RETURN
SET_CPOS	ENDP

M18	PROC	NEAR
	CALL	POSITION
	MOV	CX,AX
	ADD	CX,CRT_START
	SAR	CX,1
	ADD	CX,NEW_OFFSET		; TWEEK:  add in our fudge factor
	MOV	AH,14
	CALL	M16
	RET
M18	ENDP

M16	PROC	NEAR
	MOV	DX,ADDR_6845
	MOV	AL,AH
	OUT	DX,AL
	INC	DX
	MOV	AL,CH
	OUT	DX,AL
	DEC	DX
	MOV	AL,AH
	INC	AL
	OUT	DX,AL
	INC	DX
	MOV	AL,CL
	OUT	DX,AL
	RET
M16	ENDP

;------------------------------------------------------------------------
; POSITION								;
;									;
;------------------------------------------------------------------------

POSITION PROC	NEAR
	PUSH	BX			; save register
	MOV	BX,AX
	MOV	AL,AH			; rows to AL
	MUL	BYTE PTR CRT_COLS	; determine bytes to row
	XOR	BH,BH
	ADD	AX,BX			; add in column value
	SAL	AX,1			; * 2 for attribute bytes
	POP	BX
	RET
POSITION ENDP

;------------------------------------------------------------------------
; ACT_DISP_PAGE							        ;
;								        ;
;------------------------------------------------------------------------

ACT_DISP_PAGE   PROC    NEAR
        MOV     ACTIVE_PAGE,AL
        MOV     CX,CRT_LEN
        CBW
        PUSH    AX
        MUL     CX
        MOV     CRT_START,AX
        MOV     CX,AX
	SAR	CX,1
	add	cx,new_offset
        MOV     AH,12
        CALL    M16
        POP     BX
        SAL     BX,1
        MOV     AX,[BX + OFFSET CURSOR_POSN]
        CALL    M18
        JMP     VIDEO_RETURN
ACT_DISP_PAGE   ENDP

;------------------------------------------------------------------------
; WRITE_TTY							        ;
;								        ;
;------------------------------------------------------------------------

WRITE_TTY       PROC    NEAR
        PUSH    AX
        PUSH    AX
        MOV     AH,3
        MOV     BH,ACTIVE_PAGE
        INT     10H
        POP     AX

;       DX now has the current cursor position

        CMP     AL,8
        JE      U8
        CMP     AL,0DH
        JE      U9
        CMP     AL,0AH
        JE      U10
        CMP     AL,07H
        JE      U11

        MOV     AH,10
        MOV     CX,1
        INT     10H


        INC     DL
        CMP     DL,BYTE PTR CRT_COLS
        JNZ     U7
        MOV     DL,0
        CMP     DH,24
        JNZ     U6

U1:
        MOV     AH,2
        INT     10H

        MOV     AL,CRT_MODE
        CMP     AL,4
        JC      U2
        CMP     AL,7
        MOV     BH,0
        JNE     U3
U2:
        MOV     AH,8
        INT     10H
        MOV     BH,AH
U3:
        MOV     AX,601H
        SUB     CX,CX
        MOV     DH,24
        MOV     DL,BYTE PTR CRT_COLS
        DEC     DL
U4:
        INT     10H
U5:
        POP     AX
        JMP     VIDEO_RETURN
U6:
        INC     DH
U7:
        MOV     AH,2
        JMP     U4
U8:
        CMP     DL,0
        JE      U7
        DEC     DL
        JMP     U7

U9:
        MOV     DL,0
        JMP     U7

U10:
        CMP     DH,24
        JNE     U6
        JMP     U1

U11:
        JMP     U5
WRITE_TTY       ENDP

OUR_INT10 ENDP
;
;	Init for device driver version
;
	ifdef	DEV_DRIV
	assume cs:code,ds:code,ss:code,es:nothing
INIT:
	mov	dx,offset signon
	call	do_msg		; Do sign-on message
;
	mov	CMD_ARG,'N'	; Set 'ON' in local variable
	call	walk_alloc	; walk DOS allocation chain
	mov	ASEG,ax 	; save seg value for end of mem
	mov	ZSEG,dx 	; save seg value of last block
	or	ax,ax
	jnz	init2		; ..if allocation chain found.
;
	mov	dx,offset no_chain ; error message
	call	do_msg
	jmp	init88
init2:
	call	tst_installed	; Test if we're already installed
	mov	ah,al		; Will need this later
	cmp	ah,'U'		; Check return
	jnz	init3		; Jump if already installed
;
;	Not installed yet
;
	call	check		; Check if installable
	or	ax,ax
	jnz	init88		; Bail out if not
;
	call	install 	; Install our drivers
	call	enable		; Enable hardware
	call	do_status	; Show status
	jmp	init77		; and exit
;
;	Already installed
;
init3:
	call	do_status	; show status
	jmp	init88
;
init77:
	mov	ax,OFFSET INIT
	jmp	init99
;
init88:
	mov	ax,0
init99:
	LDS	BX,CS:[PTRSAV]	;SET END OF DRIVER LOCATION
	MOV	WORD PTR [BX].TRANS,ax
	MOV	WORD PTR [BX].TRANS+2,CS
	JMP	DEVEXIT
;
	else
;
;This is where the non-resident portion gets chopped off.
;
	ORG	($-SEGST)+16-(($-SEGST) MOD 16)
KEEP	EQU	($-SEGST)/16
	endif	;DEV_DRIV
;
;========================================================================
;
;	Main program begins here
;
;========================================================================
;
;	Equates
;
EGA_GRC	equ 3ceh		; Port address of EGA graphics controller
NEW_OFFSET equ 0C000h		; New offset for video buffer
CR	equ	13
LF	equ	10
;
CMD_ARG	    DB	0		; Argument flag parsed from command line
;

signon	     db 'MAXVRAM - Version 1.00.00 - Video RAM utility',CR,LF
             db '     Copyright (c) Qualitas, Inc. 1992.',CR,LF,'$'
syntax	     db	'Usage:  MAXVRAM ON   to install and enable',CR,LF
	     db	'        MAXVRAM OFF  to disable',CR,LF
	     db	'        MAXVRAM OV   to override install check',CR,LF,'$'
no_chain     db	'Could not find allocation chain.',CR,LF,'$'
not_ega	     db 'Video adapter is not EGA or VGA.',CR,LF,'$'
ega_64k	     db 'Video adapter has insufficient memory.',CR,LF,'$'
wrong_mode   db	'Video adapter in wrong mode.',CR,LF,'$'
mda_pres     db 'Monochrome adapter present.',CR,LF,'$'
ram_a000     db 'RAM already exists at A000.',CR,LF,'$'
ram_b000     db 'RAM already exists at B000.',CR,LF,'$'
not_a000     db 'DOS memory does not reach A000.',CR,LF,'$'
not_640      db 'DOS memory does not reach 640k.',CR,LF,'$'
driver_is    db 'Driver is ','$'
not_inst     db 'not installed.',CR,LF,'$'
enabled      db 'enabled, graphics not available.',CR,LF,'$'
disabled     db 'disabled, graphics available.',CR,LF,'$'
unknown      db 'in an unknown state.',CR,LF,'$'
;
ASEG	dw	0	; A segment value from DOS alloc chain
ZSEG	dw	0	; Z segment value from DOS alloc chain
;
;
;========================================================================
;
;	Main program starts here.
;	Get args from command line, and test for already installed.
;
;	Inst	Arg	Action
;	----	----	--------
;	N	ON	Install and enable
;	N	OFF	Report status:	not installed
;	N	none	Report status:	not installed
;	Y	ON	Enable if not already so.
;	Y	OFF	Disable if not already so.
;	Y	none	Report status:	enabled/disabled
;
;========================================================================
;
	assume cs:code,ds:code,ss:code,es:nothing
	ifndef	DEV_DRIV
main1	proc	near
;
	mov	dx,offset signon
	call	do_msg		; Do sign-on message
;
	call	get_cmdline	; Process args from command line
	mov	CMD_ARG,al	; Save in local variable
	cmp	al,'X'		; Syntax error?
	jnz	main2		; if not
	mov	dx,offset syntax
	call	do_msg		; Do syntax error message
	jmp	comexit		; and exit
main2:
	call	walk_alloc	; walk DOS allocation chain
	mov	ASEG,ax 	; save seg value for end of mem
	mov	ZSEG,dx 	; save seg value of last block
	or	ax,ax
	jnz	main2a		; ..if allocation chain found.
;
	mov	dx,offset no_chain ; error message
	call	do_msg
	jmp	comexit
main2a:
	call	tst_installed	; Test if we're already installed
	mov	ah,al		; Will need this later
	cmp	ah,'U'		; Check return
	jnz	main3		; Jump if already installed
;
;	Not installed yet
;
	mov	al,CMD_ARG	; Get command line arg flag
	cmp	al,'V'		; OV?
	je	main2b		; Skip install test if so.
	cmp	al,'N'		; ON?
	jne	main5		; Jump if not
	call	check		; Check if installable
	or	ax,ax
	jnz	comexit
main2b:
	call	install 	; Install our drivers
	call	enable		; Enable hardware
	call	do_status	; Show status
	jmp	tsr		; Terminate and stay resident
;
;	Already installed
;
main3:
	mov	al,CMD_ARG	; Get command line arg flag
	cmp	al,'N'		; ON?
	jne	main4		; ..no
	cmp	ah,'E'		; Enabled already?
	je	main5		; if so, then nothing to do.
	call	enable		; Enable hardware
	jmp	main5
main4:
	cmp	al,'F'		; OFF?
	jne	main5
	cmp	ah,'D'		; Disabled already?
	je	main5		; if so, then nothing to do.
	call	disable		; Disable hardware
main5:
	call	do_status	; else, show status
comexit:
	mov	ax,4C00h	; Exit with return code 0
	int	21h
	jmp	comexit		; should never get here
;
main1	endp			; End of main program
;
;========================================================================
;
;	get_cmdline - translate command line into command line flag
;
get_cmdline proc near
	mov	al,FCB+1	; Grab first char from default FCB.
	cmp	al,' '		; Space means no args
	je	get_cmd_99	; if so...

	cmp	al,'O'		; First char must be 'O'
	jne	get_cmd_88	; if not so...

	mov	al,FCB+2	; Grab second char from default FCB.
	cmp	al,'N'		; Only ON and OF(F) are valid
	je	get_cmd_99	; if so...

	cmp	al,'F'		; Only ON and OF(F) are valid
	je	get_cmd_99	; if so...

	cmp	al,'V'		; Well, OV is legal too.
	je	get_cmd_99	; if so...
get_cmd_88:
	mov	al,'X'		; Error return
get_cmd_99:
	ret			; Normal return
;
get_cmdline endp
	endif	;NOT DEV_DRIV
;
;========================================================================
;
;	tst_installed - Test if we're already installed
;
tst_installed proc near
	mov	ah,SET_TEST	; Set up a bogus interrupt call
	mov	al,0
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	VID_INT 	; Do it
;
	mov	ah,0		; Neatness counts.
	cmp	al,'E'		; If we are already installed
	jz	tst_inst99	; ..then 'E'nabled or 'D'isabled comes back
	cmp	al,'D'
	jz	tst_inst99
	mov	al,'U'		; else, we're not installed
tst_inst99:
	ret			; all done
tst_installed endp
;
;========================================================================
;
;	do_status - report current status
;
do_status proc near
	mov	dx,offset driver_is
	call	do_msg			; "driver is "
;
	call	tst_installed		; check if we're installed/enabled/disabled
	cmp	al,'U'
	mov	dx,offset not_inst
	je	status1
	cmp	al,'E'
	mov	dx,offset enabled
	je	status1
	cmp	al,'D'
	mov	dx,offset disabled
	je	status1
	mov	dx,offset unknown
status1:
	call	do_msg
	ret
do_status endp
;
;========================================================================
;
;	check - check if possible to install driver
;
;  What to do.
;
;  1.	Test for EGA/VGA.
;  2.	Test for video mode 2 or 3.
;  3.	Test for no memory from A000:0 to B000:7FFF.
;  4.	Test for end of memory at 640k exactly.
;
;  If any of these tests fail, return AX <> 0.
;
check	proc near
;
;	Check for EGA/VGA adapter.
;
	mov	ah,12h		; Video subsystem configuration
	mov	bl,10h
	int	VID_INT
;
	mov	dx,offset not_ega ; Prep message
	cmp	bl,10h		; If this is still 10h
	je	check88		; It's not an EGA
;
	mov	dx,offset ega_64k ; Prep message
	cmp	bl,0		; Check how much adapter memory
	je	check88		; ..if only 64k
;
;	Check for mode 2 or 3.
;
	mov	ah,15		; Get current video state
	int	VID_INT
	mov	dx,offset wrong_mode ; Prep with error message
	cmp	al,2		; mode 2?
	je	check1		; if so..
	cmp	al,3		; mode 2?
	je	check1		; if so..
	jmp	check88 	; else, error
check1:
;
;	check for mono adapter
;
	if	MDA_TEST
	call	mda_check
	or	al,al
	mov	dx,offset mda_pres
	jnz	check88		; mono is present
	endif
;
;	check for no memory from A000:0 to B000:7fff
;
	mov	cx,8000h	; 32k words = 64k bytes
	mov	bx,0		; offset 0
	mov	ax,0a000h	; from A000
	call	ram_check
	mov	dx,offset ram_a000 ; error message
	or	ax,ax
	jnz	check88 	; if error
;
	mov	cx,4000h	; 16k words = 32k bytes
	mov	bx,0		; offset 0
	mov	ax,0b000h	; from B000
	call	ram_check
	mov	dx,offset ram_b000 ; error message
	or	ax,ax
	jz	short @F 	; default is OK error

	mov	end_seg,0b000h	; End here
@@:
;
	mov	dx,offset not_a000 ; prep with error message
	mov	ax,ASEG
	cmp	ax,0a000h	; memory must end at 640k exactly.
	jnz	check88 	; ..if not so
;
	mov	dx,offset not_640 ; prep with error message
	mov	ax,seg DATA	; Bios data segment
	mov	es,ax
	mov	ax,es:MEMORY_SIZE ; check BIOS memory size too.
	cmp	ax,640		; must be 640.
	jz	check99		; ..if so
;
check88:
	call	do_msg		; print error message
	mov	ax,1
	ret			; and return
check99:
	mov	ax,0
	ret			; all done
check	endp

;
;========================================================================
;
;	mda_check - check for mono adapter
;
mda_check proc near
	mov	dx,3b4h 	; base port
	mov	al,0fh		; cursor register
	out	dx,al
	inc	dx
	jmp	mda1		; waste some time
mda1:	jmp	mda2
mda2:	jmp	mda3		; bob smith said to do this
mda3:	jmp	mda4
mda4:
	in	al,dx		; read current value
	push	ax		; save it
	not	ax		; complement it
	out	dx,al		; write it
mda5:	jmp	mda6
mda6:	jmp	mda7
mda7:
	mov	ch,al
	in	al,dx		; read it back
	mov	cl,al
	pop	ax
	out	dx,al		; write original value back
	xor	ax,ax
	cmp	cl,ch
	jne	mda99
	inc	ax
mda99:	ret
mda_check endp	
;
;========================================================================
;
;	install - install our driver in the video interrupt
;
install	proc near
;
	mov	ah,35h		;get current vector
	mov	al,VID_INT	;..for int 10
	int	21h		;(comes back in ES:BX)
	mov	word ptr VIDEO_INT,bx	;store it
	mov	word ptr VIDEO_INT+2,es
;
	mov	ah,25h		;substitute our own.
	mov	al,VID_INT
	mov	dx,offset OUR_INT10 ;Set INT 10H to point here
	int	21h
	ret
install	endp
;
;========================================================================
;
;	enable - enable hardware and driver
;
enable	proc near
;
;	Switch the video buffer to A000:0 for 128k
;
	mov	dx,EGA_GRC	; Graphics controller port
	mov	al,06h		; Miscelleanous register
	mov	ah,2		; A000:0 for 128kb
	call	write_ega	; do it
;
;	Copy display contents to new location
;
	push	ds
	mov	ax,0a000h	; what used to be at b800:0 is now at a000:0
	mov	ds,ax
	mov	si,0
	mov	ax,0b800h	; so we have to move it back to b800:0
	mov	es,ax
	mov	di,0
	mov	cx,4000h	; all 8 pages of video memory
	rep	movsw		; two bytes at a time
	pop	ds
;
;	fetch CRTC address
;
	mov	ax,seg DATA	; Bios data segment
	mov	es,ax
	mov	dx,es:ADDR_6845
;
;	Change the buffer start address to A000:0 plus 96k
;	(i.e. B800:0)
;
	mov	al,0ch		; start address hi register
	mov	ah,(NEW_OFFSET SHR 8)
	call	write_ega
;
;	Adjust the cursor position similarly
;
	mov	al,0eh		; cursor address hi register
	call	read_ega	; read it
	mov	ch,al		; save it
	mov	al,0fh		; cursor address lo register
	call	read_ega	; read it
	mov	ah,ch
	add	ax,NEW_OFFSET	; add in fudge factor
	mov	cx,ax

	mov	al,0eh		; cursor address hi register
;	(mov ah,ch)		; new value
	call	write_ega	; write it
	mov	al,0fh		; cursor address lo register
	mov	ah,cl		; new value
	call	write_ega	; write it
;
	mov	ah,SET_TEST 	; use our special function
	mov	al,'E'		; to enable the driver
	int	VID_INT
;
	mov	ax,ZSEG 	; tell DOS about the extra memory
	mov	es,ax
	add	word ptr es:[3],1800h ; add 96k in paragraphs
	mov	ax,seg DATA	; Bios data segment
	mov	es,ax
	mov	es:MEMORY_SIZE,736 ; tell BIOS total mem is 736k
	ret
enable	endp

;
;========================================================================
;
;	disable - disable hardware and driver
;
disable	proc near
;
	mov	ax,ZSEG 	; tell DOS to forget about the extra memory
	mov	es,ax
	sub	word ptr es:[3],1800h ; subtract 96k in paragraphs
	mov	ax,seg DATA	; Bios data segment
	mov	es,ax
	mov	es:MEMORY_SIZE,640 ; tell BIOS total mem is 640k
;
	mov	ah,SET_TEST 	; use our special function
	mov	al,'D'		; to disable the driver
	int	VID_INT
;
;	fetch CRTC address
;
	mov	ax,seg DATA	; Bios data segment
	mov	es,ax
	mov	dx,es:ADDR_6845
;
;	Adjust the cursor position
;
	mov	al,0eh		; cursor address hi register
	call	read_ega	; read it
	mov	ch,al		; save it
	mov	al,0fh		; cursor address lo register
	call	read_ega	; read it
	mov	ah,ch
	sub	ax,NEW_OFFSET	; subtract fudge factor
	mov	cx,ax

	mov	al,0eh		; cursor address hi register
;	(mov ah,ch)		; new value
	call	write_ega	; write it
	mov	al,0fh		; cursor address lo register
	mov	ah,cl		; new value
	call	write_ega	; write it
;
;	Copy display contents to proper location
;
	push	ds
	mov	ax,0b800h	; what is now at a000:0 will be at b800:0
	mov	ds,ax
	mov	si,0
	mov	ax,0a000h	; so we have to move it back to b800:0
	mov	es,ax
	mov	di,0
	mov	cx,4000h	; all 8 pages of video memory
	rep	movsw		; two bytes at a time
	pop	ds
;
;	Change the buffer start address back to 0
;	(i.e. B800:0)
;
	mov	al,0ch		; start address hi register
	mov	ah,0
	call	write_ega
;
;	Switch the video buffer to B800:0 for 32k
;
	mov	dx,EGA_GRC	; Graphics controller port
	mov	al,06h		; Miscelleanous register
	mov	ah,0eh		; b800:0 for 32k
	call	write_ega	; do it
;
	ret
disable	endp
;
;========================================================================
;  Support functions.
;========================================================================
;
;	walk_alloc - walk the DOS allocation chain
;
;	PC Tech Journal, Oct '87, p.45
;
;	Returns:
;	AX = segment for end of memory + 1 (i.e. A000)
;	AX = 0 if unable to find the chain.
;	DX = segment of last memory block (i.e. the 'Z' block)
;
walk_alloc proc	near
;
	mov	ah,52h		; secret dos function
	int	21h
	mov	ax,es:[bx-2]	; seg of first block of allocation chain
;
	mov	es,ax
	mov	bx,0
walk2:
	cmp	byte ptr es:[bx],'M' ; Normal block?
	jne	walk3		; ..nope
	mov	ax,es
	add	ax,es:[bx+3]	; length of block in paragraphs
	inc	ax		; plus 1
	mov	es,ax
	jmp	walk2		; ..and loop
walk3:
	cmp	byte ptr es:[bx],'Z' ; End block?
	jne	walk88		; this is very bad
;
	mov	dx,es		; dx = Z segment
	mov	ax,dx
	add	ax,es:[bx+3]	; ax = Z seg plus size of last block
	inc	ax		; ...plus 1
	jmp	walk99		; done
;
walk88:
	mov	ax,0
	mov	dx,0
walk99:
	ret
walk_alloc endp
;
;========================================================================
;
;	ram_check - check for RAM in specified address range
;
;	AX = start segment
;	BX = start offset
;	CX = count in words
;
;	returns AX <> 0 if any ram found.
;
ram_check proc	near
	push	ds		; save ds
	mov	ds,ax
ram1:
	mov	ax,[bx]		; pick up value
	mov	dx,ax		; save a copy
	not	ax		; complement it
	mov	[bx],ax		; put it back
	jmp	ram2		; wait awhile
ram2:	jmp	ram3
ram3:	jmp	ram4
ram4:	jmp	ram5
ram5:
	cmp	ax,[bx]		; compare with original
	je	ram88		; there be RAM here if they match
	add	bx,2
	loop	ram1		; otherwise loop
	mov	ax,0		; NO ram
	jmp	ram99
ram88:
	mov	[bx],dx		; put back original value in case it matters
	mov	ax,1
ram99:
	pop	ds		; restore ds
	ret
ram_check endp
;
;========================================================================
;
;	read_ega - read an EGA control register.
;
;	AL = register number
;	DX = address of control port
;
;	result returned in AL.
;
read_ega proc	near
;
	out	dx,al		; select register
	inc	dx		; switch to data port
	in	al,dx		; read value
	dec	dx		; switch back to control port
	ret
;
read_ega endp
;
;========================================================================
;
;	write_ega - write an EGA control register.
;
;	AL = register number
;	AH = value to write
;	DX = address of control port
;
write_ega proc	near
;
	out	dx,al		; select register
	inc	dx		; switch to data port
	mov	al,ah		; put value in AL
	out	dx,al		; write value
	dec	dx		; switch back to control port
	ret			; all done
write_ega endp
;
;
;========================================================================
;
;	do_msg - write string to console
;
;	DX = offset of message
;
do_msg	proc	near
;
	mov	ah,9
	int	21h		; pretty simple, huh?
	ret			; all done
;
do_msg endp
;
;========================================================================
;
;	Terminate and stay resident.
;
;========================================================================
;
	ifndef	DEV_DRIV
tsr:
	mov	ax,3100h	;do terminate and stay resident function
	mov	dx,KEEP		;set number of paragraphs to keep
	int	21H		;do it
here:
	int	20h		;(and never come back...)
	jmp	here		; don't never get here
	endif	;DEV_DRIV
;
code	ends
;
;	end		;end of program
;	end	main	;end of program

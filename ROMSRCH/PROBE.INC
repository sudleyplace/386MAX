;' $Header:   P:/PVCS/MAX/ROMSRCH/PROBE.INV   1.2   02 Jan 1996 17:36:04   BOB  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	GNU General Public License version 3.
;
; PROBE.INC
;
; ROMSRCH.COM equates
;

; LCL_FLAG

@LCL_INT02	equ    20000h	; INT 02h handler installed
@LCL_PnP	equ    10000h	; PnP present
@LCL_NDP	equ	8000h	; NDP present
@LCL_MOUSE	equ	4000h	; Mouse present
@LCL_FILE_ERR	equ	2000h	; Error during file I/O
@LCL_ABORT	equ	1000h	; User requested an abort
@LCL_XBDA	equ	0800h	; We supplied temp XBDA
@LCL_F000BUFFER equ	0400h	; Tandy 4000 style disk buffer at F000 present
@LCL_VGAPRES	equ	0200h	; System is VGA (or above)
@LCL_VESA	equ	0100h	; System has VESA compliant video
@LCL_VIDSAVE	equ	0080h	; Save/Restore video information in effect
@LCL_EISA	equ	0040h	; EISA machine present
@LCL_SKIP1C	equ	0020h	; Skip Interrupt 10 function 1C
@LCL_XBDA_PRES	equ	0010h	; Assume XBDA is already present
@LCL_NOWIN3	equ	0008h	; MAX is running with NOWIN3 option
@LCL_XTCLASS	equ	0004h	; We're running on an XT class machine
@LCL_ALLPAGES	equ	0002h	; Recover USE= pages (already recovered)
@LCL_HDISK	equ	0001h	; A hard disk is present


; CMD_FLAG

;;@CMD_PTECLEAR equ	8000h	; Clear all PTEs first
@CMD_SKIPPCI	equ	4000h	; Skip PCI functions
@CMD_DEBUG13	equ	2000h	; Debug on INT 13h
@CMD_DEBUG40	equ	1000h	; Debug on INT 40h
@CMD_DEBUG1A	equ	0800h	; Debug on INT 1Ah
@CMD_DEBUG15	equ	0400h	; Debug on INT 15h
@CMD_DEBUG10	equ	0200h	; Debug on INT 10h
@CMD_DEBUG42	equ	0100h	; Trap INT 42h calls
@CMD_DEBUG99	equ	0080h	; Debug on INT Misc.
@CMD_AMIBIOS	equ	0040h	; Use AMI debugging feature
@CMD_DEBUGBEEP	equ	0020h	; Beep as a means of debugging
@CMD_DEBUGWRITE equ	0010h	; Display function number on screen
@CMD_SKIP42	equ	0008h	; Skip INT 42 call
@CMD_SKIPRES	equ	0004h	; Skip all 'Reserved' interrupts
@CMD_SKIPABIOS	equ	0002h	; Skip ABIOS functions
@CMD_SKIPEISA	equ	0001h	; Skip EISA functions

; DBG_FLAG

; Structure used to obtain IRQ's BIOS entry points

OLDIRQ_STR struc

OLDIRQ_NUM	db	?	; Interrupt number
OLDIRQ_VEC	dd	?	; BIOS entry point for vector

OLDIRQ_STR ends


; Macro to display to STD_ERR

DISP_STDERR macro MESSAGE

	 mov	 cx,@&MESSAGE&_LEN	; Length of particular message
	 mov	 bx,@STD_ERR		; Ensure output gets to user
	 DOSCALL @WRITF2,&MESSAGE	; Display message

	endm

; Macro to display to STD_OUT

DISP_STDOUT macro MESSAGE

	 mov	 cx,@&MESSAGE&_LEN	; Length of particular message
	 mov	 bx,@STD_OUT		; Send output to Screen (or MAXIMIZE)
	 DOSCALL @WRITF2,&MESSAGE	; Display message

	endm

@PROGNAME	equ	'ROMSRCH'       ; What we call this program

; Structure defining how each interrupt behaves

INT_STR struc			; Data structure for each interrupt
	P_AX	dw	0	; Value to place in AX
	P_BX	dw	0	; ...		    BX
	P_CX	dw	0	; ...		    CX
	P_DX	dw	0	; ...		    DX
	P_FLAG	dw	0	; Flags for specific interrupt
	P_INTNO dw	0	; Interrupt Number
INT_STR ends			; End of INT_STR structure

STRUCT_LEN	equ	size INT_STR ; Size of above strucutre

; Bit flags for INT_STR.P_FLAG

@AX	equ	8000h	; Use result of last operation for AX
@BX	equ	4000h	; ...				   BX
@CX	equ	2000h	; ...				   CX
@DX	equ	1000h	; ...				   DX
@IRQ	equ	0010h	; IRQs are handled specailly
@RES	equ	0008h	; This interrupt is "IBM RESERVED" (special code)
@SKIP	equ	0004h	; Skip this interrupt
@MISC	equ	0002h	; Is part of misc interrupts
;;@INT3 equ	0001h	; Signal INT 3 before interrupt

@PASS1 equ	 0001h	; First pass through command line parser
@PASS2 equ	 0001h	; Second ...


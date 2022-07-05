;' $Header:   P:/PVCS/MAX/INCLUDE/PSPSTR.INV   1.0   05 Sep 1995 13:30:18   HENRY  $
;
; (C) Copyright 1992 Qualitas, Inc.  GNU General Public License version 3.
;
; PSPSTR.INC
;
; Program Segment Prefix Structure
;

;
; This was derived from PSP.INC, and should be identical except that
; it defines the PSP as a STRUC instead of as a data area.
;
PSP	 STRUC			; Program Segment Prefix for DOS 2.x and 3.x.

				; Valid for DOS 1.10 except for fields
				; ...flagged below as DOS 2.x or 3.x only.

				; This is a dummy -- the actual PSP
				; ...is created by DOS when a program is
				; ...invoked and appears in this spot.

PSP_EXIT dw	 1 dup (?)	;					00-01
;;;;;;;; int	 20h		; Program termination

PSP_STOR_MAX dw  1 dup (?)	; Top of DOS-known storage		02-03

	 db	 1 dup (?)	; IOCTL???				04

PSP_DOSCALL db	 1 dup (?)	;					05
;;;;PSP_DOSVEC label dword
PSP_BYTES_INSEG dw 1 dup (?)	; # bytes remaining in this 64k segment 06-07
	 dw	 1 dup (?)	; Segment of above			08-09

PSP_TERMINATE	dd 1 dup (?)	; Terminate address			0A-0D
PSP_CTRL_BREAK	dd 1 dup (?)	; CTRL-BREAK address			0E-11
PSP_CRIT_ERROR	dd 1 dup (?)	; Critical error address		12-15
PSP_CTRL_PSP	dw 1 dup (?)	; Control PSP segment			16-17
PSP_FILE_TAB_IND db 20 dup (?)	; Table of file indices 		18-2B
PSP_ENVIR_PTR	dw 1 dup (?)	; *2*Environment pointer		2C-2D
	 dw	 2 dup (?)	; Reserved for DOS			2E-31
PSP_FILE_TAB_SIZ dw 1 dup (?)	; *3*Size of FILE_TABLE_IND		32-33
PSP_FILE_TAB_PTR dd 1 dup (?)	; *3*Pointer to FILE_TABLE_IND		34-37

	 dd	 1 dup (?)	; Reserved for DOS			38-3B
	 db	 20 dup (?)	; Unused				3C-4F

PSP_DOS_FCN db	 3 dup (?)	;					50-52
;;;;;;;; int	 21h		; *2*Function call
;;;;;;;; ret			; *2*and return

	 db	 9 dup (?)	; Unused				53-5B

PSP_FCB1 db	 16 dup (?)	; File Control Block 1			5C-6B
PSP_FCB2 db	 16 dup (?)	; File Control Block 2			6C-7B

	 db	 4 dup (?)	; Unused				7C-7F

;;;;PSP_DTA  label byte 	; Default Disk Transfer Area		80-7F
PSP_PARM_COUNT	db 1 dup (?)	; Length of invocation parameter string 80
PSP_PARM_STRING db 127 dup (?)	; Start of	"          "        "   81-7F

;;;;PSP_DIR  equ	 byte ptr PSP_DTA+1 ; DIR entries start here when filled
;;;;				; in using a normal FCB
;;;;PSP_XDIR equ	 byte ptr PSP_DTA+1+7 ; *2*DIR entries start here when filled
;;;;				; in using an extended FCB

				; *2* DOS 2.x only.
				; *3* DOS 2.x only.
PSP	ENDS

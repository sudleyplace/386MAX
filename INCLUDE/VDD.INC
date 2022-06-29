;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp., 1988-1990
;
;   Title:	vdd.inc - VDD definitions for other VxD's and multiple VDD's
;
;   Version:	1.00
;
;   Date:
;
;   Author: AR, MDW
;
;------------------------------------------------------------------------------
;
;   Change log:
;
;      DATE	REV		    DESCRIPTION
;   ----------- --- -----------------------------------------------------------
;   24-Jan-1989 MDW Added service definitions
;==============================================================================


Begin_Service_Table VDD

;***************
;VDD protect mode services for other devices and VMM(Get_Version must be first)
;
VDD_Service	VDD_Get_Version 	; Get version number and ID string ptr
VDD_Service	VDD_PIF_State		; Pass video PIF bits to VDD
VDD_Service	VDD_Get_GrabRtn 	; Get routine addr for video grab
VDD_Service	VDD_Hide_Cursor 	; Hide cursor when display is windowed
VDD_Service	VDD_Set_VMType		; Set VM type(windowed, bckgrnd, excl)
VDD_Service	VDD_Get_ModTime 	; Return system time of last mod
VDD_Service	VDD_Set_HCurTrk 	; Track horiz cursor movement in window
VDD_Service	VDD_Msg_ClrScrn 	; Clear screen for sysmodal message
VDD_Service	VDD_Msg_ForColor	; Set Msg_TextOut forground color
VDD_Service	VDD_Msg_BakColor	; Set Msg_TextOut background color
VDD_Service	VDD_Msg_TextOut 	; Output a string
VDD_Service	VDD_Msg_SetCursPos	; Set cursor position
VDD_Service	VDD_Query_Access	; Is it OK to access video now?

; New services for 3.1	Not supported for 3.0 VDD's
;
VDD_Service	VDD_Check_Update_Soon,,VGA31 ; User action may update screen

End_Service_Table VDD

IFDEF VGA31
VDD_VerNum	EQU	030Ah		; version 3, 10
ELSE
VDD_VerNum	=	0300h

IFDEF DEBUG
IFNDEF VGA
IFNDEF EGA
VDD_VerNum = VDD_VerNum + 0FFh
ENDIF ;EGA
ENDIF ;VGA
ENDIF ;DEBUG

ENDIF	;VGA31

;***************
; PIF_State service definitions
;
; These definitions cannot change without changing the PIF editor!!!
;
fVidTxtEmulate	EQU	0001h		; Do INT 10h TTY and cursor emulation
fVidNoTrpTxt	EQU	0002h		; Do not trap text mode apps
fVidNoTrpLRGrfx EQU	0004h		; Do not trap lo res graphics mode apps
fVidNoTrpHRGrfx EQU	0008h		; Do not trap hi res graphics mode apps
fVidTextMd	EQU	0010h		; Allocate text mode mem
fVidLowRsGrfxMd EQU	0020h		; Allocate lo res graphics mode mem
fVidHghRsGrfxMd EQU	0040h		; Allocate hi res graphics mode mem
fVidRetainAllo	EQU	0080h		; Never deallocate once allocated

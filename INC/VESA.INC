;' $Header:   P:/PVCS/MAX/INC/VESA.INV   1.0   05 Sep 1995 13:27:42   HENRY  $
;
; (C) Copyright 1992 Qualitas, Inc.  All rights reserved.
;
; VESA.INC
;
; VESA functions and data structures
;

COMMENT |

Original code by: Henry Groover, January 1992

|

; The following VESA functions are accessed via Int 10h
; Return code in AH=0 if successful, AL=4fh if supported
; Valid window values (passed in BL for MemWindowCtl functions)
; are 0 for Window A and 1 for Window B.

.xcref @VESA_GetInfo,@VESA_GetModeInfo,@VESA_SetMode,@VESA_GetMode
.xcref @VESA_SaveRestore,@VESA_SRBuffSize,@VESA_SRSave,@VESA_SRRestore
.xcref @VESA_MemWindowCtl
@VESA_GetInfo	equ	4f00h	; Fill in VESA_Info_str at ES:DI for 256 bytes
@VESA_GetModeInfo equ	4f01h	; Read mode CX info into VESA_Mode_str at ES:DI
@VESA_SetMode	equ	4f02h	; Set SVGA mode to BX
@VESA_GetMode	equ	4f03h	; Get current SVGA mode in BX
@VESA_SaveRestore equ	4f04h	; Perform subfunction in DL with CX=state mask:
 @VESA_SRBuffSize equ	0	; Get 64-byte blocks needed in BX
 @VESA_SRSave	equ	1	; Save state(s) into buffer at ES:BX
 @VESA_SRRestore equ	2	; Restore state(s) from buffer at ES:BX
@VESA_MemWindowCtl equ	4f05h	; Perform subfunction in BH
 @VESA_MWSelect equ	0	; Set display page start in DX for window in BL
 @VESA_MWQuery	equ	1	; Return start of page BL in DX

.xcref VESA_States,$VHDWR,$VBIOS,$VDAC,$VSVGA,$VRSVD
VESA_States record $VRSVD:12,$VSVGA:1,$VDAC:1,$VBIOS:1,$VHDWR:1

VESA_Info_str	struc		; VESA info structure returned by @VESA_GetInfo
VESA_Info_Sig	db 4 dup (?)	; 'VESA'
VESA_Info_Vmin	db	?	; Minor version number
VESA_Info_Vmaj	db	?	; Major version number
VESA_Info_OEM	dd	?	; OEM StringPtr; far ptr to ASCIIZ string
VESA_Info_Cap	dd	?	; Capabilities; unused
VESA_Info_Modes dd	?	; Far ptr to list of supported modes, -1 ends
VESA_Info_str	ends

VESA_Mode_str	struc		; Structure filled in by @VESA_GetModeInfo
VESA_Mode_Attr	dw	?	; Mode attributes
VESA_Mode_WinA_Attr db	?	; Window A attributes
VESA_Mode_WinB_Attr db	?	; Window B attributes
VESA_Mode_Gran	dw	?	; Window start granularity in KB
VESA_Mode_Size	dw	?	; Size in K of display page
VESA_Mode_WinA_Seg dw	?	; Segment of Window A
VESA_Mode_WinB_Seg dw	?	; Segment of Window B
VESA_Mode_WinFunc dd	?	; Far entry to MemWindowCtl
VESA_Mode_BPScan dw	?	; Bytes per scan line
;--------- Optional information- valid only if Mode_Attr has bit 1 set -------
VESA_Mode_XRes	dw	?	; Horizontal resolution
VESA_Mode_YRes	dw	?	; Vertical resolution
VESA_Mode_CWid	db	?	; Character cell width
VESA_Mode_CHeight db	?	; Character cell height
VESA_Mode_NumPlanes db	?	; Number of planes
VESA_Mode_BPPix db	?	; Bits per pixel
VESA_Mode_NumBanks db	?	; Number of banks
VESA_Mode_MemModel db	?	; Memory model (0=txt,1=CGA gr,2=Herc gr,
				; 3=4pln gr,4=packed pix gr,5=nonchain 4/256 gr,
				; 6-0f=reserved, 10h-ffh OEM defined)
VESA_Mode_BankSize db	?	; Bank size in K
VESA_Mode_str	ends

.xcref	VMAttr,$VMASUP,$VMAOPT,$VMABIO,$VMACLR,$VMAGRA,$VMARSVD
VMAttr	record	$VMARSVD:11,$VMAGRA:1,$VMACLR:1,$VMABIO:1,$VMAOPT:1,$VMASUP:1

.xcref	VWAttr,$VWASUP,$VWARD,$VWAWR,$VWARSVD
VWAttr	record	$VWARSVD:5,$VWAWR:1,$VWARD:1,$VWASUP:1


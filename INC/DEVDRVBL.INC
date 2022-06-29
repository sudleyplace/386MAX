;' $Header:   P:/PVCS/MAX/INC/DEVDRVBL.INV   1.0   05 Sep 1995 13:27:10   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; DEVDRVBL.INC
;
; Block device driver equates and structures
;

;  M E D I A   D E S C R I P T O R   B Y T E S

MD_DS	 equ	  00000001b	; Double sided
MD_8SEC  equ	  00000010b	; 8 sectors/side
MD_REM	 equ	  00000100b	; Removable
MD_	 equ	  11111000b	; Remaining bits MUST be set to 1

MD_FD	 equ	  MD_		; Fixed disk
MD_SS9	 equ	  MD_+MD_REM	; Single-sided 9 sectors/track
MD_DS9	 equ	  MD_+MD_REM+MD_DS ; Double-sided 9 sectors/track
MD_SS8	 equ	  MD_+MD_REM+MD_8SEC ; Single-sided 8 sectors/track
MD_DS8	 equ	  MD_+MD_REM+MD_8SEC+MD_DS ; Double-sided 8 sectors/track

; M E D I A   C H E C K

MEDIA_CHECK_STR  struc

		db	(size SRH_STR) dup (?) ; Static request header
MC_MD	 db	 ?		; Media descriptor byte
MC_RET	 db	 ?		; Byte returned from driver

MEDIA_CHECK_STR  ends


; B U I L D   B P B

BUILD_STR struc

	 db	 (size SRH_STR) dup (?) ; Static request header
BUILD_MD db	 ?		; Media descriptor byte
BUILD_DTA_VEC dd ?		; Disk transfer address
BUILD_BPB_VEC dd ?		; Pointer to BPB

BUILD_STR ends


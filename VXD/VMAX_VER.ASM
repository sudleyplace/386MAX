BETAVERSION	equ	010

;' $Header:   P:/PVCS/MAX/VXD/VMAX_VER.ASV   1.12   15 Jun 1998 23:56:12   BOB  $
;
; (C) Copyright 1990-96 Qualitas, Inc.	All rights reserved.
;
; VMAX_VER.ASM
;
; Version number for 386MAX.VXD
;

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group _IGROUP:
	       Program segment _ITEXT,	dword-aligned,	use32,	public, 'ICODE'
	       Data    segment _IDATA,	dword-aligned,	use32,	public, 'ICODE'

	       Group _LGROUP:
	       Program segment _LTEXT,	dword-aligned,	use32,	public, 'CODE'
	       Data    segment _LDATA,	dword-aligned,	use32,	public, 'CODE'

	       Group _PGROUP:
	       Program segment _TEXT,	dword-aligned,	use32,	public, 'PCODE'
	       Data    segment _DATA,	dword-aligned,	use32,	public, 'PCODE'

	       Segment	       _RCODE,	word-aligned,	use16,	public, 'RCODE'

Program derived from:  None.

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

.386p
.xlist
	 include VMM.INC		; Fixed version of file from DDK

	 include ASCII.INC
	 include DEVMAC.INC

	 include QMAX_OEM.INC
.list
	 extrn	 VERS_H:abs,VERS_T:abs,VERS_U:abs,VER:abs,VERS_HTU:abs

	 public  BETA_H, BETA_T, BETA_U
BETA	 equ	 BETAVERSION mod 1000
BETA_H	 equ	'0'+BETA/100
BETA_T	 equ	'0'+(BETA-(BETA_H-'0')*100)/10
BETA_U	 equ	'0'+BETA-(BETA_H-'0')*100-(BETA_T-'0')*10


VxD_REAL_INIT_SEG			; Begin _RCODE segment
	 assume  es:nothing		; Tell the assembler

	 public  DEVNAME_MAX
	 DEVMAC  @OEM_IOCTL
DEVNAME_MAX	 db	@DEVNAME, 0	; Name for OPEN and IOCTL

	 public  MSG_RMI
MSG_RMI  db	 BEL, CR, LF, @OEM_TEXT, ' VxD -- Version '
	 db	 VERS_H, '.', VERS_T, VERS_U, '.', BETA_H, BETA_T, BETA_U
	 db	 ' -- ', @OEM_SUBT, CR, LF
ifdef LANG_GR
	 db	 '    (C) Copyright 1990-97 Qualitas, Inc.  Alle Rechte vorbehalten.', CR, LF
else
	 db	 '    (C) Copyright 1990-97 Qualitas, Inc.  All rights reserved.', CR, LF
endif					; IFDEF LANG_GR
	 db	 CR, LF, EOS

VxD_REAL_INIT_ENDS			; End _RCODE segment

	 end

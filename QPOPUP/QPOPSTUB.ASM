;'$Header:   P:/PVCS/MAX/QPOPUP/QPOPSTUB.ASV   1.1   30 May 1997 11:57:52   BOB  $
	 title	 QPOPSTUB -- MZ Stub for QPOPUP
	 NAME	 QPOPSTUB

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-7 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:	Small model using simplified directives
		Assembled using MASM 6.0b or 6.1.
		Linked directly by the assembler.

Original code by:  William R. Lewis, Octobber, 1992.

Modifications by:  None.

|

	 include DOSCALL.INC
	 include ASCII.INC

	 .model  small

	 .data
	 public  MSG_COPY
ifdef LANG_GR
MSG_COPY db	 'QPOPUP muá unter Microsoft Windows 3.1 oder h”her ablaufen'
else
MSG_COPY db	 'QPOPUP must be run in Microsoft Windows 3.1 or later'
endif				; IFDEF LANG_GR
	 db	 CR, LF, EOS

	 .stack  512

	 .code

QPOPSTUB proc	 far public
	 assume  ds:nothing, es:nothing, ss:nothing

	 mov	 ax,DGROUP	; Establish addressibility to DGROUP
	 mov	 ds,ax		; ... via DS
	 assume  ds:DGROUP	; Tell the assembler

	 mov	 ah,@STROUT	; Function 09h
	 lea	 dx,MSG_COPY	; DS:DX ==> '$' terminated string
	 int	 21h		; DOS services

	 mov	 ax,(@EXITRC shl 8) or 0 ; Terminate process with errorcode 0
	 int	 21h		; DOS services

	 assume  ds:nothing, es:nothing, ss:nothing
QPOPSTUB endp			; End QPOPSTUB procedure

	 end	 QPOPSTUB	; End QPOPSTUB module, defining start address

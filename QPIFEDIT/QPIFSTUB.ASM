;'$Header:   P:/PVCS/MAX/QPIFEDIT/QPIFSTUB.ASV   1.1   30 May 1997 11:56:20   BOB  $
	 title	 QPIFSTUB -- MZ Stub for QPIFEDIT
	 name	 QPIFSTUB

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:	Small model using simplified directives
		Assembled using MASM 6.0b or 6.1.
		Linked directly by the assembler.

Original code by:  William R. Lewis, October, 1992.

Modifications by:  None.

|

	 include DOSCALL.INC
	 include ASCII.INC

	 .model  small

	 .data
	 public  MSG_COPY
ifdef LANG_GR
MSG_COPY db 'Qualitas PIF Editor muá unter Microsoft Windows 3.1 oder h”her ablaufen'
else
MSG_COPY db 'Qualitas PIF Editor must be run in Microsoft Windows 3.1 or later'
endif				; IFDEF LANG_GR
	 db	 CR, LF, EOS

	 .stack  512

	 .code

QPIFSTUB proc	 far public
	 assume  ds:nothing, es:nothing, ss:nothing

	 mov	 ax,DGROUP	; Establish addressibility to DGROUP
	 mov	 ds,ax		; ... via DS
	 assume  ds:DGROUP	; Tell the assembler

	 mov	 ah,@STROUT	; Display '$'-terminated string
	 lea	 dx,MSG_COPY	; DS:DX ==> '$' terminated string
	 int	 21h		; DOS services

	 mov	 ax,(@EXITRC shl 8) or 0 ; Terminate process with errorcode 0
	 int	 21h			; DOS services

	 assume  ds:nothing, es:nothing, ss:nothing
QPIFSTUB endp			; End QPIFSTUB procedure

	 end	 QPIFSTUB	; End QPIFSTUB module, defining start address

;' $Header:   P:/PVCS/MAX/386MAX/QMAX_CMD.INV   1.0   11 Aug 1995 10:55:10   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_CMD.INC
;
;  Local flags for command line arguments for CMD_FLAG
;

@CMD_EMS   equ	 8000h		; Flag for EMS=nnnn
@CMD_EXT   equ	 4000h		;	   EXT=nnnn
@CMD_FRM   equ	 2000h		;	   FRAME=xxxx
@CMD_XLO   equ	 1000h		;	   NOLOW
@CMD_XHI   equ	 0800h		;	   NOHIGH
@CMD_PRO   equ	 0400h		;	   PRO=d:\path\filename.ext
@CMD_OVR16 equ	 0200h		;	   High DOS memory at or above 16MB
@CMD_IGNFLEX equ 0100h		;	   IGNOREFLEXFRAME
@CMD_FORCEBCF equ 0080h 	;	   Force BCF to continue (ignore errors)
@CMD_XPARITY equ 0040h		;	   NOPARITY
@CMD_XRM   equ	 0020h		;	   NOROM
@CMD_TERSE equ	 0010h		;	   TERSE
@CMD_XDM   equ	 0008h		;	   NODMA
@CMD_XDPMI equ	 0004h		;	   NODPMI
@CMD_WTK   equ	 0002h		;	   WEITEK=ON or OFF
@CMD_INI   equ	 0001h		;	   ON, OFF, or AUTO


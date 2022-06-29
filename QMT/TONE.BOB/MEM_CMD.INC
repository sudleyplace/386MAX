;' $Header:   P:/PVCS/MAX/QMT/MEM_CMD.INV   1.1   05 Jun 1998 14:04:34   BOB  $
;
; (C) Copyright 1988-98 Qualitas, Inc.	All rights reserved.
;
; MEM_CMD.INC
;
; Equates for CMD_FLAG.
;

@CMD_TONE   equ 10000h		; TONE[=d:\path\filename.ext]
@CMD_XSCRB  equ  8000h		; NOSCRUB
@CMD_X384   equ  4000h		; NOXRAM
@CMD_SHD    equ  2000h		; SHADOWRAM
@CMD_TOP    equ  1000h		; TOP384
@CMD_BW     equ  0800h		; BW or /B (Black & white display)
@CMD_DSET   equ  0400h		; Display type set
@CMD_EPM   equ	 0200h		; Use our own EPM routine
@CMD_SPASS  equ  0100h		; One or more scheduling tests passed
@CMD_SFAIL  equ  0080h		; One or more scheduling tests failed
@CMD_ASK    equ  0040h		; Ask the user when it's time to run the test
@CMD_BWDEF  equ  0020h		; If unsure, assume B&W display
@CMD_LOG    equ  0010h		; Update log file
@CMD_LOGDEL equ  0008h		; Overwrite log file
@CMD_STDOUT equ  0004h		; STDOUT not redirected
@CMD_NODPMI equ  0002h		; NODPMI
@CMD_NOVCPI equ  0001h		; NOVCPI


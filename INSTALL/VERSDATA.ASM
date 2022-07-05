;' $Header:   P:/PVCS/MAX/INSTALL/VERSDATA.ASV   1.3   30 May 1997 11:27:44   BOB  $
	 TITLE	 VERSDATA -- Version-dependent data
	 page	 58,122
	 name	 VERSDATA

COMMENT|		Module Specifications

Version-dependent data for INSTALL.

Copyright:  (C) Copyright 1992-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Ungrouped:
	       Group DGROUP:
	       Data    segment _DATA,	 word-aligned,	public, class 'data'

Link requirements: Data to be referenced from MS C.

Program derived from:  None.

Original code by:  Henry Groover, January, 1992.

 ÚÄ 5.M„rz 1992 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
 ³see modification remarks in all other files (transferred to GERMAN) ³
 ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

|

.8086
.xlist
	 include ASCII.INC
	 extrn	 BETA_H:abs
	 extrn	 BETA_T:abs
	 extrn	 BETA_U:abs
.list

%.model  &MODEL

.data

; ASYS constant values for different builds
MAX		equ	0	; 386MAX INSTALL
BLUEMAX 	equ	1	; BlueMAX INSTALL
MOVEM		equ	2	; Move'em (only used in MAXIMIZE)
MAXU		equ	10	; 386MAX UPDATE
BLUEMAXU	equ	11	; BlueMAX UPDATE
MOVEMU		equ	12	; Move'EM UPDATE

; PROGTYPE values
INSTALL 	equ	0	; INSTALL
UPDATE		equ	1	; UPDATE

if (ASYS EQ MAX) or (ASYS EQ MAXU)
PRODUCTNAME	equ	'Qualitas MAX'
elseif (ASYS EQ BLUEMAX) or (ASYS EQ BLUEMAXU)
PRODUCTNAME	equ	'BlueMAX'
elseif (ASYS EQ MOVEM) or (ASYS EQ MOVEMU)
PRODUCTNAME	equ	'Move''Em'
else
	 .err	 <ASYS not specified or invalid>
endif	 ; case ASYS ...

if (ASYS EQ MAX) or (ASYS EQ BLUEMAX) or (ASYS EQ MOVEM)
PROGNAME	equ	'SETUP'
ULCPROGNAME	equ	'Setup'
PROGTYPE	equ	INSTALL
elseif (ASYS EQ MAXU) or (ASYS EQ BLUEMAXU) or (ASYS EQ MOVEMU)
PROGNAME	equ	'SETUP'
ULCPROGNAME	equ	'Setup'
PROGTYPE	equ	UPDATE
else
	 .err	 <ASYS not specified or invalid>
endif	 ; case ASYS ...

if (ASYS EQ MOVEM) or (ASYS EQ MOVEMU)
.err <Need a title>
else
@OEM_HARPO	equ	1

	 include QMAX_OEM.ALL

PRODTITLE	catstr	<>,@OEM_SUBT,<>

endif

; 386MAX versions linked in from \386max\versret.asm
	 extrn	 VER:abs,VERS_H:abs,VERS_T:abs,VERS_U:abs,VERSLTR1:abs

if BETA
PROGVERSION equ <VERS_H,'.',VERS_T,VERS_U,'.',BETA_H,BETA_T,BETA_U,'á'>
else
; This will usually have a trailing space
PROGVERSION equ <VERS_H,'.',VERS_T,VERS_U,VERSLTR1>
endif		; BETA

; From SCRN.C
	 public  _ProgramName
_ProgramName  db  ' ',PRODUCTNAME,' ',VERS_H,' ',0       ; " 386MAX 6 "

	 public  _MsgLogoText
MsgLogoText_1 db PRODUCTNAME,' ',VERS_H,'.',VERS_T,0
MsgLogoText_2 db PRODTITLE,0
MsgLogoText_3 db PROGNAME,0		; Balance leading space
MsgLogoText_4 db 'Version ',PROGVERSION,0
MsgLogoText_5 db 0
if @datasize
_MsgLogoText dd  DGROUP:MsgLogoText_1,DGROUP:MsgLogoText_2
	 dd	 DGROUP:MsgLogoText_3,DGROUP:MsgLogoText_4
	 dd	 DGROUP:MsgLogoText_5,0
else
_MsgLogoText dw  MsgLogoText_1,MsgLogoText_2,MsgLogoText_3,MsgLogoText_4
	 dw	 MsgLogoText_5,0
endif		; Far/near pointers

; From INSTALL.C (formerly ProgramName)
	 public  _PrintName
_PrintName db	 ' ',ULCPROGNAME,0

	 public  _HelpString
_HelpString label byte
ifdef LANG_GR
if (PROGTYPE eq UPDATE)
 db	'Erneuert vorhandene(s) Qualitas-Programm(e) mittels UPDATE-Diskette.',LF
else
 db	'Installiert Qualitas-Programm(e) von Diskette auf Festplatte.',LF
endif				; IF PROGTYPE eq UPDATE
 db	 LF
 db	 PROGNAME,' [Schalter]',LF
 db	 LF
 db	 '  /B  ',PROGNAME,' l„uft in Monochrom (SW).',LF
 db	 '  /C  ',PROGNAME,' l„uft in Farbe.',LF
 db	 '  /K  erlaubt Laufwerks-Tausch (Drive Swapping).',LF
if (ASYS eq BLUEMAX) or (ASYS eq BLUEMAXU)
 db	 '  /M  Extrahiert alle BCF-Dateien.',LF
endif
 db	 '  /N  Installiert fr neues System, Motherboard oder BIOS',LF
 db	 '  /O  berschreibt „ltere Version und ersetzt ggf. fehlende Teile.',LF
 db	 '  /P  ersetzt nur vorhandene Dateien mit abweichendem Datum/Zeit.',LF
 db	 '  /R  bringt vorhandene Installation auf neuesten Stand.',LF
 db	 '  /S  erlaubt Belegung des Monochrom-Bereiches.',LF
 db	 '  /U  verhindert Belegung des Monochrom-Bereiches der Video-Karte.',LF
 db	 '  /V  startet ohne grafisches Begráungs-Logo.',LF
;;;;;;; db	 '  /2  installiert NUR Untersttzung fr 286-er Maschinen.',LF
 db	 '  /lw: verwendet Laufwerk lw: als Boot-Laufwerk',LF
 db	 LF
 db	 PROGNAME,' ',PROGVERSION,LF
 db	 '(C) Copyright 1987-96 Qualitas, Inc.   Alle Rechte vorbehalten.',LF,0
else
if (PROGTYPE eq UPDATE)
 db	'Update installed Qualitas product(s) from new floppy disk.',LF
else
 db	'Install Qualitas product(s) from floppy to hard disk.',LF
endif				; IF PROGTYPE eq UPDATE
 db	 LF
 db	 PROGNAME,' [switches]',LF
 db	 LF
 db	 '  /B  Start ',PROGNAME,' in monochrome (B&W) mode',LF
 db	 '  /C  Start ',PROGNAME,' in color mode',LF
 db	 '  /K  Enable swapped-drive support',LF
if (ASYS eq BLUEMAX) or (ASYS eq BLUEMAXU)
 db	 '  /M  Extract all BCF files.',LF
endif
 db	 '  /N  Install for new machine, motherboard or BIOS',LF
 db	 '  /O  Overwrite only older or missing files',LF
 db	 '  /P  Overwrite only existing files with different time/date',LF
 db	 '  /R  Refresh installation',LF
 db	 '  /S  Allow recovery of monochrome display area',LF
 db	 '  /U  Inhibit use of monochrome display area',LF
 db	 '  /V  Inhibit graphic introduction logo',LF
;;;;;;; db	 '  /2  Install 286 support only',LF
 db	 '  /d: Use drive letter specified for boot drive',LF
 db	 LF
 db	 PROGNAME,' ',PROGVERSION,LF
 db	 '(C) Copyright 1987-96 Qualitas, Inc.   GNU General Public License version 3.',LF,0
endif				; IFDEF LANG_GR

	 end

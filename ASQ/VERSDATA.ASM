;' $Header:   P:/PVCS/MAX/ASQ/VERSDATA.ASV   1.2   30 May 1997 10:48:18   BOB  $
	 TITLE	 VERSDATA -- Version-dependent data
	 page	 58,122
	 name	 VERSDATA

COMMENT|		Module Specifications

Version-dependent data for ASQ.

Copyright:  (C) Copyright 1992-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Ungrouped:
	       Group DGROUP:
	       Data    segment _DATA,	 word-aligned,	public, class 'data'

Link requirements: Data to be referenced from MS C.

Program derived from:  None.

Original code by:  Henry Groover, January, 1992.

modified by: Herbert Reibe c/o Klaus Albrecht MÅnchen
	     tranferred to GERMAN; see remarks in asqtext.h file!
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
MAX		equ	0	; 386MAX
BLUEMAX 	equ	1	; BlueMAX
MOVEM		equ	2	; Move'em

PROGNAME	equ	'ASQ'
ifdef LANG_GR
PROGTITLE	equ	'Analyse-Werkzeug und Lernhilfe'
else
PROGTITLE	equ	'Analysis and Training Utility'
endif			; IFDEF LANG_??

; 386MAX versions linked in from \386max\versret.asm
	 extrn	 VER:abs,VERS_H:abs,VERS_T:abs,VERS_U:abs,VERSLTR1:abs
	 extrn	 BINVERS_H:abs,BINVERS_TU:abs

; This string will normally have a trailing space
ASQMAJVERTEXT equ <VERS_H,'.',VERS_T,VERS_U,VERSLTR1>
if BETA
ASQVERTEXT equ	<ASQMAJVERTEXT,'.',BETA_H,BETA_T,BETA_U,'·'>
else
ASQVERTEXT equ	<ASQMAJVERTEXT>
endif		; BETA

; Referenced in ASQ engine and in SNAPSHOT
	 public  _ASQVER_MAJOR,_ASQVER_MINOR
_ASQVER_MAJOR	 db	 BINVERS_H
_ASQVER_MINOR	 db	 BINVERS_TU

ife SNAPSHOT
; Data from ASQTEXT.H
	 public  _AsqName
_AsqName  db	 ' ',PROGNAME,' ',ASQMAJVERTEXT,0    ; " ASQ 2.01 "

	 public  _MsgLogoText
MsgLogoText_1 db PROGNAME,' ',ASQVERTEXT,0
MsgLogoText_2 db PROGTITLE,0
MsgLogoText_3 db PROGNAME,0
MsgLogoText_4 db 'Version ',ASQVERTEXT,0
MsgLogoText_5 db 0
if @datasize
_MsgLogoText dd  DGROUP:MsgLogoText_1,DGROUP:MsgLogoText_2
	 dd	 DGROUP:MsgLogoText_3,DGROUP:MsgLogoText_4
	 dd	 DGROUP:MsgLogoText_5,0
else
_MsgLogoText dw  MsgLogoText_1,MsgLogoText_2,MsgLogoText_3,MsgLogoText_4
	 dw	 MsgLogoText_5,0
endif		; Far/near pointers

	 public  _HelpString
_HelpString label byte
ifdef LANG_GR
 db	LF
 db	'Dient zur System-Analyse und gibt Hilfe in der Speicher-Verwaltung.',LF
 db	 LF
 db	 ' %s %s[Schalter]',LF
 db	 LF
 db	 '  /B                       ',PROGNAME,' lÑuft in Monochrom (SW)',LF
 db	 '  /C                       ',PROGNAME,' lÑuft in Farbe',LF
 db	 '  /F laufw:                liest CONFIG.SYS und AUTOEXEC.BAT von ''laufw:''',LF
 db	 '  /G [dateiname][,L][,H]   sichert Speicher-Plan in eine Datei (''dateiname''',LF
 db	 '                           Ihrer Wahl), andernfalls in Datei MEMIMAGE.ASQ;',LF
 db	 '                           ,L = nur unterer Bereich (0:0 bis Anfang von ASQ);',LF
 db	 '                           ,H = nur oberer Bereich (A000:0 bis 10000:0);',LF
 db	 '                           ohne L oder H gesamter Speicher (0:0 bis 10000:0).',LF
 db	 '  /L [dateiname]           startet ',PROGNAME,', lÑdt vorhandenen Snapshot;',LF
 db	 '                           ohne Snapshot-Namen nehme ich SNAPSHOT.ASQ.',LF
 db	 '  %s[dateiname][/D "bes"] startet ',PROGNAME,', schreibt System-Konfiguration',LF
 db	 '                           in einen Snapshot; fÅgt ''.ASQ''-Erweiterung zum',LF
 db	 '                           ',PROGNAME,'-LademenÅ; ohne ''dateiname'' verwende',LF
 db	 '                           ich SNAPSHOT.ASQ; /D fÅgt die Beschreibung "bes"',LF
 db	 '                           zur Snapshot-Datei hinzu, nur nach /S verwendbar.',LF
 db	 '  /V                       startet ohne grafisches BegrÅ·ungs-Logo',LF
 db	 '  /X                       autom. RÅckkehr zum DOS, geht nur nach /G oder /S',LF
 db	 LF
 db	 '%s ',ASQVERTEXT,', '
 db	 '(C) Copyright 1987-96 Qualitas, Inc.   Alle Rechte vorbehalten.',LF,0
else
 db	LF
 db	'Provides system analysis and memory management training.',LF
 db	 LF
 db	 ' %s %s[switches]',LF
 db	 LF
 db	 '  /B                           Start ',PROGNAME,' in monochrome (B&W) mode',LF
 db	 '  /C                           Start ',PROGNAME,' in color mode',LF
 db	 '  /F drive:                    Read CONFIG.SYS and AUTOEXEC.BAT from ''drive:''',LF
 db	 '  /G [filename][,L][,H]        Save memory image to a file; if no filename is',LF
 db	 '                               entered, MEMIMAGE.ASQ is used;',LF
 db	 '                               ,L saves only low memory (0:0 to start of ASQ);',LF
 db	 '                               ,H saves only high memory (A000:0 to 10000:0);',LF
 db	 '                               the default is all memory (0:0 to 10000:0)',LF
 db	 '  /L [filename]                Start ',PROGNAME,' and load a saved snapshot file; if',LF
 db	 '                               no filename is entered, SNAPSHOT.ASQ is used',LF
 db	 '  %s[filename] [/D "descrip"] Start ',PROGNAME,' and save system configuration to a',LF
 db	 '                               snapshot file; use .ASQ extension to add to the',LF
 db	 '                               ',PROGNAME,' Load menu; if no filename is entered,',LF
 db	 '                               SNAPSHOT.ASQ is used; /D adds the description',LF
 db	 '                               to the snapshot file, use after /S only',LF
 db	 '  /V                           Inhibit graphic introduction logo',LF
 db	 '  /X                           Automatic exit to DOS, use after /G or /S only',LF
 db	 LF
 db	 '%s ',ASQVERTEXT,', '
 db	 '(C) Copyright 1987-96 Qualitas, Inc.   GNU General Public License version 3.',LF,0
endif			; IFDEF LANG_??
endif			; IFE SNAPSHOT
	 end

;' $Header:   P:/PVCS/MAX/MAXIMIZE/VERSDATA.ASV   1.5   30 May 1997 11:45:44   BOB  $
	 TITLE	 VERSDATA -- Version-dependent data
	 page	 58,122
	 name	 VERSDATA

COMMENT|		Module Specifications

Version-dependent data for MAXIMIZE.

Copyright:  (C) Copyright 1990-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Ungrouped:
	       Group DGROUP:
	       Data    segment _DATA,	 word-aligned,	public, class 'data'

Program derived from:  None.

Original code by:  Henry Groover, January, 1992.

/*ÚÄ 5.M„rz 1992 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿*/
/*³see modification remarks in all other files (transferred to GERMAN) ³*/
/*ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/

|

.8086
.xlist
	 include ASCII.INC

.list
	 extrn	 BETA_H:abs
	 extrn	 BETA_T:abs
	 extrn	 BETA_U:abs

%.model  &MODEL

.data

; Turn on STACKER support (affects /? message only)
STACKER 	equ	1	; 1 if STACKER enabled, 0 if disabled

; ASYS constant values for different builds
MAX		equ	0	; 386MAX
BLUEMAX 	equ	1	; BlueMAX
MOVEM		equ	2	; Move'em

if (ASYS EQ MOVEM)
ifdef LANG_GR
MIZTITLE	equ	'Ein Program-Lader fr PCs'
else
MIZTITLE	equ	'A Program Loader for PCs'
endif	; ifdef LANG_GR
else
@OEM_HARPO	equ	1

	 include QMAX_OEM.ALL

MIZTITLE	catstr	<>,@OEM_SUBT,<>

endif	; if !MOVEM


if (ASYS EQ MAX)
PRODUCTNAME	equ	'Qualitas MAX'
elseif (ASYS EQ BLUEMAX)
PRODUCTNAME	equ	'BLUEMAX'
elseif (ASYS EQ MOVEM)
PRODUCTNAME	equ	'MOVE''EM'
else
	 .err	 <ASYS not specified>
endif	 ; case ASYS ...

; 386MAX versions linked in from \386max\versret.asm
; Move'em versions linked in from \move'em\version.asm
	 extrn	 VER:abs,VERS_H:abs,VERS_T:abs,VERS_U:abs,VERSLTR1:abs

if BETA
MIZVERSION equ	<VERS_H,'.',VERS_T,VERS_U,'.',BETA_H,BETA_T,BETA_U,'á'>
else
; This string will normally have a trailing space
MIZVERSION equ	<VERS_H,'.',VERS_T,VERS_U,VERSLTR1>
endif		; BETA

; Referenced in SCREENS.C
	 public  _Prodname
_Prodname db	 ' ',PRODUCTNAME,' ',VERS_H,' ',0       ; " 386MAX 6 "

	 public  _MsgLogoText
MsgLogoText_1 db PRODUCTNAME,' ',VERS_H,'.',VERS_T,0
MsgLogoText_2 db MIZTITLE,0
MsgLogoText_3 db 'MAXIMIZE',0
MsgLogoText_4 db 'Version ',MIZVERSION,0
MsgLogoText_5 db 0
if @datasize
_MsgLogoText dd  DGROUP:MsgLogoText_1,DGROUP:MsgLogoText_2
	 dd	 DGROUP:MsgLogoText_3,DGROUP:MsgLogoText_4
	 dd	 DGROUP:MsgLogoText_5,0
else
_MsgLogoText dw  MsgLogoText_1,MsgLogoText_2,MsgLogoText_3,MsgLogoText_4
	 dw	 MsgLogoText_5,0
endif		; Far/near pointers

; Referenced in DOREBOOT.C
	public	 _BatchHdr
ifdef LANG_GR
_BatchHdr db	 PRODUCTNAME,' ',VERS_H,'.',VERS_T,'      MAXIMIZE      Phase ?',0
else
_BatchHdr db	 PRODUCTNAME,' ',VERS_H,'.',VERS_T,'      MAXIMIZE      Phase ?',0
endif		; ifdef LANG_GR

; Referenced in MAXIMIZE.C
	 public  _HelpString,_HelpString6,_HelpStringB
_HelpString label byte
ifdef LANG_GR
 db	'Vergr”áert nutzbaren Speicherplatz durch Hochladen von TSR-Programmen',LF
 db	 'in den HiDOS Speicher-Bereich.',LF
 db	 LF
 db	 ' MAXIMIZE [Schalter]',LF
 db	 LF,0
_HelpString6 label byte 	; FIXME Remove after DOS 6 ships
 db	 '  /A config w„hlt aktiven DOS 6 MultiBoot-Abschnitt',LF,0
_HelpStringB label byte 	; FIXME Remove after DOS 6 ships
 db	 '  /B        MAXIMIZE l„uft in Monochrom (SW)',LF
 db	 '  /C        MAXIMIZE l„uft in Farbe',LF
 db  '  /U        MAXIMIZE l„uft im angepaáten Modus (/U fr engl. CUSTOM)',LF
 db	 '  /E        MAXIMIZE l„uft im Expreá-Modus',LF
 db	 '  /N        vermeidet Pause vor dem Aufruf von AUTOEXEC.BAT beim Neustart',LF
 db	 '  /I        Ignoriere EMS Seiten-Rahmen w„hrend der Optimierung',LF
if STACKER
 db	 '  /K        erlaubt Laufwerks-Tausch (Drive Swapping).',LF
endif				; IF STACKER
 db	 '  /T        f„hrt ohne Anwenderaktion nach vorgegebener Zeit fort',LF
 db	 '  /V        startet ohne grafisches Begráungs-Logo',LF
 db	 '  /lw:      verwendet angegebenes Laufwerk als Boot-Laufwerk',LF
 db	 LF
 db	 'MAXIMIZE ',MIZVERSION,LF
 db	 '(C) Copyright 1987-96 Qualitas, Inc.   Alle Rechte vorbehalten.',LF,0
else
 db	'Increases usable memory by loading memory resident programs into the high',LF
 db	 'DOS memory region.',LF
 db	 LF
 db	 ' MAXIMIZE [switches]',LF
 db	 LF,0
_HelpString6 label byte 	; FIXME Remove after DOS 6 ships
 db	 '  /A config Select Active DOS 6 MultiBoot section',LF,0
_HelpStringB label byte 	; FIXME Remove after DOS 6 ships
 db	 '  /B        Start MAXIMIZE in monochrome (B&W) mode',LF
 db	 '  /C        Start MAXIMIZE in color mode',LF
 db	 '  /U        Force Custom MAXIMIZE option',LF
 db	 '  /E        Force Express MAXIMIZE option',LF
 db	 '  /N        Inhibit pause before processing AUTOEXEC.BAT on reboot',LF
;;;;;;;     /D	      Debug mode (debug version only)
;;;;;;;     /O b1[[,b2],...] Process one or more additional batch files
;;;;;;;     /P	      Run PREMAXIM.BAT and reboot
;;;;;;;     /R	      Reboot if not in real mode
;;;;;;;     /W	      Enable CGA snow control
;;;;;;;     /X	      Started from Windows
;;;;;;;     /Z prog   Recall program (such as c:\qmax\max.exe)
;;;;;;;     /à	      Obsolete - does nothing
 db	 '  /I        Ignore EMS page frame until optimization is complete',LF
if STACKER
 db	 '  /K        Enable swapped-drive support',LF
;;;;;;;     /Kacm12   (a)ctual, (c)opy boot, (m)ax config, copy max (1), ...(2)
endif				; IF STACKER
 db	 '  /T        Set response timeout for automatic execution',LF
 db	 '  /V        Inhibit graphic introduction logo',LF
 db	 '  /d:       Use drive letter specified for boot drive',LF
 db	 LF
 db	 'MAXIMIZE ',MIZVERSION,LF
 db	 '(C) Copyright 1987-96 Qualitas, Inc.   All rights reserved.',LF,0
endif		; ifdef LANG_GR

	 end

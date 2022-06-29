;' $Header:   P:/PVCS/MAX/386MAX/UTIL_ARG.ASV   1.3   30 May 1997 10:46:20   BOB  $
	 title	 UTIL_ARG -- 386MAX Utility Program
	 page	 58,122
	 name	 UTIL_ARG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	word-aligned,  public, class 'prog'
	       Data    segment SEG_TXT, byte-aligned,  public, class 'data'
	       Data    segment SEG_LEN, word-aligned,  public, class 'data'
	       Data    segment SEG_TAB, word-aligned,  public, class 'data'
	       Data    segment SEG_ACT, word-aligned,  public, class 'data'
	       Data    segment SEG_DSP, byte-aligned,  public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include VERSION.INC

	 include QMAX_OEM.INC
.list

PGROUP	 group	 CODE,SEG_TXT,SEG_LEN,SEG_TAB,SEG_ACT,SEG_DSP


CMDMAC	 macro	 TXT,ACT,DSP
	 local	 L1,L2

SEG_TXT  segment use16 byte public 'data' ; Start SEG_TXT segment
	 assume  ds:PGROUP

L1	 db	 TXT
L2	 equ	 $-L1

SEG_TXT  ends			; End SEG_TXT segment


SEG_TAB  segment use16 word public 'data' ; Start SEG_TAB segment
	 assume  ds:PGROUP

	 dw	 PGROUP:L1

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use16 word public 'data' ; Start SEG_LEN segment
	 assume  ds:PGROUP

	 dw	 L2

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use16 word public 'data' ; Start SEG_ACT segment
	 assume  ds:PGROUP

	 dw	 PGROUP:ACT

SEG_ACT  ends			; End SEG_ACT segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 ACT:near

CODE	 ends			; End CODE segment


SEG_DSP  segment use16 byte public 'data' ; Start SEG_DSP segment
	 assume  ds:PGROUP

	 db	 DSP

SEG_DSP  ends			; End SEG_DSP segment

	 endm			; CMDMAC


SEG_TAB  segment use16 word public 'data' ; Start SEG_TAB segment
	 assume  ds:PGROUP

	 public  ARG_TAB
ARG_TAB  label	 word

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use16 word public 'data' ; Start SEG_LEN segment
	 assume  ds:PGROUP

	 public  ARG_LEN
ARG_LEN  label	 word

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use16 word public 'data' ; Start SEG_ACT segment
	 assume  ds:PGROUP

	 public  ARG_ACT
ARG_ACT  label	 word

SEG_ACT  ends			; End SEG_ACT segment


SEG_DSP  segment use16 byte public 'data' ; Start SEG_DSP segment
	 assume  ds:PGROUP

	 public  ARG_DSP
ARG_DSP  label	 byte

SEG_DSP  ends			; End SEG_DSP segment


; Note the longer name comes first in two equivalent forms so we
; don't mistake the trailing characters in the long name as erroneous

if @OEM_AUTO and @OEM_SYS ne @OEMSYS_LHY
	 CMDMAC  'on',       ACT_DEFUNCT, 1
	 CMDMAC  'off',      ACT_DEFUNCT, 1
	 CMDMAC  'auto',     ACT_DEFUNCT, 1
endif				; IF @OEM_AUTO and @OEM_SYS ne @OEMSYS_LHY

if @OEM_HILOAD
	 CMDMAC  'loadhigh', ACT_LOADHI,1
	 CMDMAC  'high',     ACT_LOADHI,0

	 CMDMAC  'loadlow',  ACT_LOADLO,1
	 CMDMAC  'low',      ACT_LOADLO,0

	 CMDMAC  'closehigh',ACT_LOADLO,1
	 CMDMAC  'close',    ACT_LOADLO,0
	 CMDMAC  'openhigh', ACT_OPENHI,1
	 CMDMAC  'open',     ACT_OPENHI,0
endif				; IF @OEM_HILOAD

if @OEM_ROMSCAN
	 CMDMAC  'ramscan',  ACT_ROM,   0
	 CMDMAC  'romscan',  ACT_ROM,   1
	 CMDMAC  '/r',       ACT_ROM,   0
endif				; IF @OEM_ROMSCAN

if @OEM_MAPEMS
	 CMDMAC  'mapems',   ACT_EMS,   1
	 CMDMAC  '/e',       ACT_EMS,   0
endif				; IF @OEM_MAPEMS

if @OEM_MAPMEM
	 CMDMAC  'mapmem',   ACT_MAP,   1
	 CMDMAC  '/m',       ACT_MAP,   0
endif				; IF @OEM_MAPMEM

if @OEM_WTK
if @OEM_SYS eq @OEMSYS_HPRS
	 CMDMAC  'w=on',     ACT_WTK1,  1
	 CMDMAC  'w=off',    ACT_WTK0,  1
else
	 CMDMAC  'weitek=on',  ACT_WTK1,1
	 CMDMAC  'weitek=off', ACT_WTK0,1
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
endif				; IF @OEM_WTK

if @OEM_LIST and @OEM_SYS ne @OEMSYS_AST386
	 CMDMAC  'list',     ACT_LIST,  1
	 CMDMAC  '/l',       ACT_LIST,  0
endif				; IF @OEM_LIST and @OEM_SYS ne @OEMSYS_AST386

if @OEM_TIMEMEM
	 CMDMAC  'timemem',  ACT_TIME,  1
	 CMDMAC  '/t',       ACT_TIME,  0
endif				; IF @OEM_TIMEMEM

if @OEM_SYS eq @OEMSYS_RET
	 CMDMAC  'ver',      ACT_VER,   0
	 CMDMAC  '/v',       ACT_VER,   0
endif				; IF @OEM_SYS eq @OEMSYS_RET

	 CMDMAC  'help',     ACT_HELP,  81h
	 CMDMAC  '/h',       ACT_HELP,  80h
	 CMDMAC  '/?',       ACT_HELP,  80h

SEG_TAB  segment use16 word public 'data' ; Start SEG_TAB segment
	 assume  ds:PGROUP

	 public  NARGS
NARGS	 equ	 ($-ARG_TAB)/(type ARG_TAB) ; # different arguments

	 public  SWITCH_HELP,SWHELP_LEN
SWITCH_HELP label byte
ifdef LANG_GR
	db	CR,LF,'Befehlszeilen-Steuerung fÅr'' ',@OEM_TEXT,CR,LF
	db	CR,LF
	db	' ',@OEM_FILE,' [Schalter]',CR,LF
	db	CR,LF
else
	db	CR,LF,'Provide command-line access to'' ',@OEM_TEXT,CR,LF
	db	CR,LF
	db	' ',@OEM_FILE,' [switches]',CR,LF
	db	CR,LF
endif				; IFDEF LANG_GR
if @OEM_LIST and @OEM_SYS ne @OEMSYS_AST386
ifdef LANG_GR
	db	'  LIST     (/L)    Gesamt-Anzeige der Speicherverwaltung',CR,LF
else
	db	'  LIST     (/L)    Display summary of how memory is managed',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_LIST and @OEM_SYS ne @OEMSYS_AST386
if @OEM_MAPEMS
ifdef LANG_GR
	db	'  MAPEMS   (/E)    zeigt EMS-Speicherbelegung',CR,LF
else
	db	'  MAPEMS   (/E)    Display EMS memory usage',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_MAPEMS
if @OEM_MAPMEM
ifdef LANG_GR
	db	'  MAPMEM   (/M)    zeigt Info Åber geladene residente Programme',CR,LF
else
	db	'  MAPMEM   (/M)    Display resident program loading information',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_MAPMEM
if @OEM_ROMSCAN
ifdef LANG_GR
	db	'  RAMSCAN  (/R)    zeigt Info Åber Speicherbelegung oberhalb von 640 KB',CR,LF
else
	db	'  RAMSCAN  (/R)    Display information on memory usage above 640K',CR,LF
endif				; IFDEF LANG_GR
endif				; If @OEM_ROMSCAN
if @OEM_TIMEMEM
ifdef LANG_GR
	db	'  TIMEMEM  (/T)    zeigt Info Åber Zeitverhalten des Speichers',CR,LF
else
	db	'  TIMEMEM  (/T)    Display information on memory timing',CR,LF
endif				; IFDEF LANG_GR
endif				; If @OEM_TIMEMEM
	db	CR,LF
SWHELP_LEN equ	$-SWITCH_HELP

SEG_TAB  ends			; End SEG_TAB segment

	 MEND			; End UTIL_ARG module

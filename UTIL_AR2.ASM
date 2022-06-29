;' $Header:   P:/PVCS/MAX/386MAX/UTIL_AR2.ASV   1.4   08 Jul 1998 12:30:04   BOB  $
	 title	 UTIL_ARG -- 386MAX Utility Program
	 page	 58,122
	 name	 UTIL_ARG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	word-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Data    segment SEG_TXT, byte-aligned,  public, class 'data'
	       Data    segment SEG_LEN, word-aligned,  public, class 'data'
	       Data    segment SEG_TAB, word-aligned,  public, class 'data'
	       Data    segment SEG_ACT, word-aligned,  public, class 'data'
	       Data    segment SEG_DSP, byte-aligned,  public, class 'data'
	       Program segment DATZ,	para-aligned,  public, class 'data'

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include 386.INC
	 include PTR.INC
	 include BITFLAGS.INC
	 include ASCII.INC

	 include QMAX_FMT.INC
	 include QMAX_OEM.INC
.list

PGROUP	 group	 CODE,DATA,SEG_TXT,SEG_LEN,SEG_TAB,SEG_ACT,SEG_DSP,DATZ


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


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

;;;	     public  STD_FILES
;;; STD_FILES dw     @STD_INP,@STD_OUT,@STD_ERR,@STD_AUX,@STD_PRT

DATA	 ends			; End DATA segment


DATZ	 segment use16 para public 'data' ; Start DATZ segment
	 assume  ds:PGROUP

	 public  EMMDEV
EMMDEV	 db	 'EMMXXXX0',0   ; EMM device name

DATZ	 ends			; End DATZ segment


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

	 CMDMAC  'inorder',  INORDER,   0
	 CMDMAC  '/sid',     INORDER_DBG, 0
	 CMDMAC  '/si',      INORDER,   0
	 CMDMAC  'reorder',  REORDER,   0
	 CMDMAC  '/srd',     REORDER_DBG, 0
	 CMDMAC  '/sr',      REORDER,   0
	 CMDMAC  'summary',  SUMMARY,   1
	 CMDMAC  '/s',       SUMMARY,   0

if @OEM_AUTO and @OEM_SYS ne @OEMSYS_LHY
	 CMDMAC  'on',       ACT_DEFUNCT, 1
	 CMDMAC  'off',      ACT_DEFUNCT, 1
	 CMDMAC  'auto',     ACT_DEFUNCT, 1
endif				; IF @OEM_AUTO and @OEM_SYS ne @OEMSYS_LHY

if @OEM_ROMSCAN
	 CMDMAC  'ramscan',  ACT_ROM,   0
	 CMDMAC  'romscan',  ACT_ROM,   1
	 CMDMAC  '/rd',      ACT_ROMDBG,0
	 CMDMAC  '/r',       ACT_ROM,   0
endif				; IF @OEM_ROMSCAN

if @OEM_MAPDEV
	 CMDMAC  'mapdev',   ACT_DDD,   1
	 CMDMAC  '/d',       ACT_DDD,   0
endif				; IF @OEM_MAPDEV

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
	 CMDMAC  'pos',      ACT_POS,   0
	 CMDMAC  '/p',       ACT_POS,   0
	 CMDMAC  'stacks=on',ACT_STACKS_ON,1
	 CMDMAC  'stacks=off',ACT_STACKS_OFF,1
	 CMDMAC  'stacks',   ACT_STACKS,1
	 CMDMAC  '/k',       ACT_STACKS,0
	 CMDMAC  'pte1',     ACT_PTE1,  0
	 CMDMAC  'pte0',     ACT_PTE,   0
	 CMDMAC  'pte',      ACT_PTE,   0
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
	db	CR,LF,'Erstellt Berichte Åber ',@OEM_TEXT,' Speicherverwaltung',CR,LF
	db	CR,LF
	db	' 386UTIL [Schalter]',CR,LF
	db	CR,LF
else
	db	CR,LF,'Display reports on how ',@OEM_TEXT,' manages memory',CR,LF
	db	CR,LF
	db	' 386UTIL [switches]',CR,LF
	db	CR,LF
endif				; IFDEF LANG_GR
if @OEM_LIST and @OEM_SYS ne @OEMSYS_AST386
ifdef LANG_GR
	db	'  LIST     (/L)    Gesamt-Anzeige der Speicherverwaltung',CR,LF
else
	db	'  LIST     (/L)    Display summary of how memory is managed',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_LIST and @OEM_SYS ne @OEMSYS_AST386
if @OEM_MAPDEV
ifdef LANG_GR
	db	'  MAPDEV   (/D)    zeigt Speicherbelegung der Einheiten-Treiber im LoDOS',CR,LF
else
	db	'  MAPDEV   (/D)    Display memory map of device drivers in low DOS',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_MAPDEV
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
	db	'  RAMSCAN  (/R)    zeigt Info Åber Speicherbelegung oberhalb 640 KB',CR,LF
else
	db	'  RAMSCAN  (/R)    Display information on memory usage above 640K',CR,LF
endif				; IFDEF LANG_GR
endif				; If @OEM_ROMSCAN
ifdef LANG_GR
	db	 '  STACKS   (/K)    zeigt DOS Stacks information',CR,LF
	db	 '  STACKS=ON        aktiviert DOS Stacks',CR,LF
	db	 '  STACKS=OFF       deaktiviert DOS Stacks',CR,LF
else
	db	'  STACKS   (/K)    Display DOS stacks information',CR,LF
	db	'  STACKS=ON        Enable DOS stacks',CR,LF
	db	'  STACKS=OFF       Disable DOS stacks',CR,LF
endif				; IFDEF LANG_GR
ifdef LANG_GR
	db	'  SUMMARY  (/S)    zeigt Lade-Verhalten der residenten Programme',CR,LF
else
	db	'  SUMMARY  (/S)    Display summary information on resident programs',CR,LF
endif				; IFDEF LANG_GR
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


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 NPPROC  DISP_ASCIIZ -- Display ASCIIZ String To Handle
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Write string to specified handle.

|

DISP_AZS_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DISP_AZS_OFF dw  ?		; Offset of ASCIIZ string
DISP_AZS_HNDL dw ?		; Handle to use

DISP_AZS_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx,di,ds,es> ; Save registers

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

; Calculate message length for @WRITF2

	 cld			; String ops forwardly
	 mov	 di,[bp].DISP_AZS_OFF; ES:DI ==> AZS message to display
	 mov	 al,0		; ASCIIZ string terminator
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
	 inc	 cx		; Back up
	 inc	 cx
	 neg	 cx		; Negate to get length

	 mov	 bx,[bp].DISP_AZS_HNDL ; Get specified handle
	 mov	 dx,[bp].DISP_AZS_OFF; DS:DX ==> error message
	 DOSCALL @WRITF2	; Write it out

	 REGREST <es,ds,di,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ASCIIZ endp		; End DISP_ASCIIZ procedure
	 NPPROC  PAR2BYT -- Convert from Paras to Bytes
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert from paras to bytes

On entry:

AX	 =	 # paras

On exit:

(DX,AX)  =	 corresponding # bytes

|

	 REGSAVE <cx>		; Save register

	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 rol	 ax,cl		; Rotate upwards
	 mov	 dx,ax		; Copy to result register
	 and	 dx,@NIB0	; Isolate low-order nibble
	 and	 ax,not @NIB0	; Isolate other nibbles

	 REGREST <cx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

PAR2BYT  endp			; End PAR2BYT procedure

CODE	 ends			; End CODE segment

	 MEND			; End UTIL_ARG module

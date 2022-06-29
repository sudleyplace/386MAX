;' $Header:   P:/PVCS/MAX/ROMSRCH/PROBE.ASV   1.6   30 May 1997 12:14:56   BOB  $
	 title	 probe -- The probe .COM program
	 page	 58,122
	 name	 probe

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, word-aligned,  stack,  class 'prog'
	       Program segment CODE,  word-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'

Program derived from:  None.

Original code by:

Modifications by:

Who		 When		What
--------------------------------------------------------------------------------
Marc Alexander	 June 1991	Inital code.
Herbert Reibe	 march 1992	transferred to GERMAN

|

.386p
.xlist
	  include MASM.INC
	  include DOSCALL.INC
	  include ASCII.INC
	  include BIOSDATA.INC
	  include CPUFLAGS.INC
	  include BITFLAGS.INC
	  include OPCODES.INC
	  include PTR.INC
	  include 386.INC
	  include MAC.INC
	  include DEVDRV.INC
	  include VERSION.INC
	  include VCPI.INC
	  include IOCTL.INC
	  include I11.INC
	  include NDP.INC
	  include VIDCALL.INC
	  include CPUID.INC
	include PNP.INC

	  include QMAX_CTL.INC
	  include QMAX_GLB.INC
	  include QMAX_CM3.INC
	  include QMAX_DBG.INC
	  include EMM2CALL.INC
	  include QMAX_LCL.INC
	  include LOAD_SEG.INC

	  include PROBE.INC
.list

PGROUP	 group	 STACK,CODE,DATA,XBDASEG,DTAIL
CGROUP	 group	 CPUID_SEG


;***************************************************************************

; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 word stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


;***************************************************************************
DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

BETA_VER	equ	1	; This is a Beta version

@SYSROM_DEFAULT equ	1234h	; Default value for SYSROM_START
@MONOSEG	equ	0B000h	; Monochrome video segment
@COLORSEG	equ	0B800h	; Color ...
@BEEP_DELAY	equ	0012h	; Delay after beep has been sound
				; 00fh is quick        (25Mhz)
				; 03fh is pretty slow  (...)
				; 0ffh is very slow    (...)

	public	OLDINT00_VEC
OLDINT00_VEC dd ?		; Save area for old INT 00h handler

	 public LCL_FLAG,CMD_FLAG,ERR_CODE
LCL_FLAG	dd	0	; Local flags
CMD_FLAG	dw	0	; Command line arguments
ERR_CODE	db	0	; Assume no error

	align	2
	public	PnP_SEG
PnP_SEG dw	?		; Segment of PnP struc

	public	SYSROM_START, PTE_COUNT
SYSROM_START	dw	@SYSROM_DEFAULT ; Start of System ROM in paras
PTE_COUNT	dw	?	; Number of PTE entries for BIOS

extrn	 BETA_H:abs		; Hundreds unit of Beta version number
extrn	 BETA_T:abs		; Tens ...
extrn	 BETA_U:abs		; Units ...

;----------------- 386MAX specific variables ---------------------

	 public  DEVNAME_MAX,DEV_HNDL
DEVNAME_MAX  db  '386MAX$$',0   ; Our device driver name
DEV_HNDL     dw  ?		; Handle to above device

	 public MAXVERS_H,MAXVERS_T,MAXVERS_U
MAXVERS_H	equ	'6'
MAXVERS_T	equ	'0'
MAXVERS_U	equ	'0'

	 public  INFO_CTL, INFO, INFOSIZE
	 public  DBG_FLAG
	 include QMAXINFO.INC
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR
DBG_FLAG equ	INFO.INFO_DBG

	public	PORT67,MAXLO_SEG,MAX_LSEG
PORT67	 dw	 ?		; I/O port for backdoor functions
MAXLO_SEG dw	 ?		; MAX's low DOS segment
MAX_LSEG  dw	 ?		; MAX's LSEG

;----------------- Messages --------------------------------------

	 public  MSG_COPY
MSG_COPY db	 @PROGNAME, ' -- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
if BETA_VER
	 db	 '.',BETA_H,BETA_T,BETA_U
endif					; if BETA_VER
ifdef LANG_GR
	 db	 ' -- Ein ROM-Sondierungsprogramm'
else
	 db	 ' -- A ROM Searching Program'
endif					; IFDEF LANG_GR
	 db	 CR,LF
	 db	 '   (C) Copyright 1991-96 Qualitas, Inc. '
ifdef LANG_GR
	 db	 ' Alle Rechte vorbehalten.',CR,LF
ifdef DEBUG
	 db	 BEL,'Dieses ist eine spezielle Debugger-Version; '
	 db	 'ignorieren Sie ALLE angebotenen Empfehlungen.',CR,LF
endif					; ifdef DEBUG
else
	 db	 ' All rights reserved.',CR,LF
ifdef DEBUG
	 db	 BEL,'This is a special debugging version, '
	 db	 'Disregard any suggestions it may offer.',CR,LF
endif					; ifdef DEBUG
endif					; ifdef LANG_GR
@MSG_COPY_LEN	equ	$-MSG_COPY

	 public  MSG_HELP
MSG_HELP db	CR,LF
ifdef LANG_GR
	 db	'Ermittelt unbenutzte Speicherbereiche im BIOS.'     ,CR,LF
	 db	'/xF600  legt eine Start-Adresse fest'               ,CR,LF
;;;;;;;; db	'/r      Åbergeht alle ''IBM Reserved'' Interrupts'  ,CR,LF
;;;;;;;; db	'/v      Åbergeht SekundÑr-Video'                    ,CR,LF
	 db	'/a      Åbergeht ABIOS-Funktionen'                  ,CR,LF
	 db	'/e      Åbergeht EISA-Funktionen'                   ,CR,LF
	 db	'/pci    Åbergeht PCI-Funktionen'                    ,CR,LF
	 db	'/inn    Åbergeht Interrupt nn'                     ,CR,LF
	 db	'/innxx  Åbergeht Interrupt nn, Funktion xx'        ,CR,LF
	 db	'/n      Åbergeht Interrupt 02 und Interrupt 06'    ,CR,LF
	 db	'/snn    Åbergeht Einsprung nn'                      ,CR,LF
;;;;;;;; db	'/q      setzt voraus, da· XBDA existiert'           ,CR,LF
;;;;;;;; db	'/d10    ruft Debugger bei INT 10'                   ,CR,LF
;;;;;;;; db	'/d13    ruft Debugger bei INT 13'                   ,CR,LF
;;;;;;;; db	'/d15    ruft Debugger bei INT 15'                   ,CR,LF
;;;;;;;; db	'/d1A    ruft Debugger bei INT 1A'                   ,CR,LF
;;;;;;;; db	'/d40    ruft Debugger bei INT 40'                   ,CR,LF
;;;;;;;; db	'/d42    ruft Debugger bei INT 42'                   ,CR,LF
;;;;;;;; db	'/d99    ruft Debugger bei INT Misc'                 ,CR,LF
	 db	'/u      stellt USE= Speicher-Seiten wieder her'     ,CR,LF
	 db	'/w      DEBUG Åber Bildschirm-Anzeige'              ,CR,LF
	 db	'/b      DEBUG Åber Piepser'                         ,CR,LF
;;;;;;;; db	'/p      DEBUG Åber PTE-öberwachungs-Option'         ,CR,LF
	 db	'/?      zeigt diesen Hilfe-Bildschirm'              ,CR,LF
	 db	CR,LF
else
	 db	'Determines unused portions of the BIOS.'       ,CR,LF
	 db	'/xF600  Specify a starting address'            ,CR,LF
;;;;;;;; db	'/r      Skip all ''IBM Reserved'' interrupts'  ,CR,LF
;;;;;;;; db	'/v      Skip secondary Video'                  ,CR,LF
	 db	'/a      Skip ABIOS functions'                  ,CR,LF
	 db	'/e      Skip EISA functions'                   ,CR,LF
	 db	'/pci    Skip PCI functions'                    ,CR,LF
	 db	'/inn    Skip interrupt nn'                     ,CR,LF
	 db	'/innxx  Skip interrupt nn, function xx'        ,CR,LF
	 db	'/n      Skip Interrupt 02 and Interrupt 06'    ,CR,LF
	 db	'/snn    Skip entry nn'                         ,CR,LF
;;;;;;;; db	'/q      Assume XBDA exists'                    ,CR,LF
;;;;;;;; db	'/d10    Call debugger on INT 10'               ,CR,LF
;;;;;;;; db	'/d13    Call debugger on INT 13'               ,CR,LF
;;;;;;;; db	'/d15    Call debugger on INT 15'               ,CR,LF
;;;;;;;; db	'/d1A    Call debugger on INT 1A'               ,CR,LF
;;;;;;;; db	'/d40    Call debugger on INT 40'               ,CR,LF
;;;;;;;; db	'/d42    Call debugger on INT 42'               ,CR,LF
;;;;;;;; db	'/d99    Call debugger on INT Misc'             ,CR,LF
	 db	'/u      Recover USE= pages'                    ,CR,LF
	 db	'/w      DEBUG via Writes to screen'            ,CR,LF
	 db	'/b      DEBUG via Beeps'                       ,CR,LF
;;;;;;;; db	'/p      DEBUG via PTE supervisor option'       ,CR,LF
	 db	'/?      Display this help screen'              ,CR,LF
	 db	CR,LF
endif						; ifdef LANG_GR
@MSG_HELP_LEN	 equ	$-MSG_HELP

	public	MSG_EOL
MSG_EOL  db	 CR,LF			; Carriage Return / Line Feed
@MSG_EOL_LEN	 equ	$-MSG_EOL	; Size of above string

	 public  MSG_FINI
ifdef LANG_GR
MSG_FINI	db	@PROGNAME, ' empfiehlt Ihnen, folgende Zeile(n) '
		db	'in Ihrer Qualitas MAX- oder ',CR,LF
		db	'BlueMAX.PROfil-Datei einzufÅgen...',CR,LF
else
MSG_FINI	db	@PROGNAME, ' would like to suggest that you add the '
		db	'following line(s) ',CR,LF
		db	'to your Qualitas MAX or BlueMAX profile...',CR,LF
endif						; ifdef LANG_GR
@MSG_FINI_LEN	equ	$-MSG_FINI

	 public  MSG_USEQUAL,MSG_USEQUAL1,MSG_USEQUAL2
MSG_USEQUAL	db	'USE='
MSG_USEQUAL1	db	'____-'
ifdef LANG_GR
MSG_USEQUAL2	db	'____         ; ', @PROGNAME, ' entdeckt '
else
MSG_USEQUAL2	db	'____         ; ', @PROGNAME, ' recovers '
endif
MSG_USEQUAL3	db	'000'
MSG_USEQUAL4	db	'_ KB.',CR,LF
@MSG_USEQUAL_LEN	 equ	$-MSG_USEQUAL

; Note: MSG_USEQUAL1 must be initialized to '_'
; We check this value against '_' to determine if any ROM holes were found

	 public  MSG_NOHOLES
ifdef LANG_GR
MSG_NOHOLES	db	@PROGNAME, ' hat keine ungenutzten '
		db	'Speicherbereiche in Ihrem BIOS gefunden.',CR,LF
else
MSG_NOHOLES	db	'Sorry, ', @PROGNAME, ' has not detected any unused '
		db	'portions of your BIOS.',CR,LF
endif							; ifdef LANG_GR
@MSG_NOHOLES_LEN	equ	$-MSG_NOHOLES

	public	MSG_NOMAX
ifdef LANG_GR
MSG_NOMAX db	 'Qualitas MAX ist nicht installiert.',CR,LF
else
MSG_NOMAX db	 'Sorry. Qualitas MAX is not installed.',CR,LF
endif							; ifdef LANG_GR
@MSG_NOMAX_LEN	 equ	$-MSG_NOMAX

	public	MSG_BADVER
ifdef LANG_GR
MSG_BADVER db	 'falsche Qualitas MAX Version.',CR,LF
else
MSG_BADVER db	 'Sorry. Wrong version of Qualitas MAX.',CR,LF
endif							; ifdef LANG_GR
@MSG_BADVER_LEN  equ	$-MSG_BADVER

	public	MSG_WIN3
ifdef LANG_GR
MSG_WIN3   db	 'Sie mÅssen zuerst WINDOWS verlassen.',CR,LF
else
MSG_WIN3   db	 'Sorry. You must first exit Windows.',CR,LF
endif							; ifdef LANG_GR
@MSG_WIN3_LEN	 equ	$-MSG_WIN3

	public	MSG_ABORT
ifdef LANG_GR
MSG_ABORT  db	 CR,LF,BEL,'Achtung: Sie haben einen Abbruch eingeleitet.  '
else
MSG_ABORT  db	 CR,LF,BEL,'Warning: User ABORT.  '
endif							; ifdef LANG_GR
@MSG_ABORT_LEN	 equ	$-MSG_ABORT

	public	MSG_NOT386
ifdef LANG_GR
MSG_NOT386 db	 'Wir benîtigen hier einen 386-er (oder etwas besseres).'
else
MSG_NOT386 db	 'Sorry. Must run on a 386 (or greater).'
endif							; ifdef LANG_GR
	   db	 CR,LF
@MSG_NOT386_LEN  equ	$-MSG_NOT386

	public	 MSG_PTE_ERR
ifdef LANG_GR
MSG_PTE_ERR db	 'Fehler aufgetaucht beim Einlesen von PTEs aus MAX.'
else
MSG_PTE_ERR db	 'Error getting PTEs from MAX.'
endif							; ifdef LANG_GR
	    db	 CR,LF
@MSG_PTE_ERR_LEN  equ	$-MSG_PTE_ERR

	public	MSG_CAVEAT
ifdef LANG_GR
MSG_CAVEAT db	'Es wurden Ergebnisse angezeigt, diese kînnen aber falsch sein.',CR,LF
	   db	'Bitte wiederholen Sie die Tests.'
else
MSG_CAVEAT db	'Results are displayed, but may not be valid.',CR,LF
	   db	'Please rerun tests.'
endif							; ifdef LANG_GR
	   db	CR,LF
@MSG_CAVEAT_LEN  equ	$-MSG_CAVEAT

	public	 MSG_COMPROM
ifdef LANG_GR
MSG_COMPROM db	 'BIOS-Komprimierung ist bereits wirksam.',CR,LF
	    db	 'Es wÑre unnÅtz, ',@PROGNAME,' laufen zu lassen.'
else
MSG_COMPROM db	 'BIOS compression is already in effect.',CR,LF
	    db	 'There is no need to run ',@PROGNAME,'.'
endif							; ifdef LANG_GR
	    db	 CR,LF
@MSG_COMPROM_LEN  equ	$-MSG_COMPROM

	 public  MSG_GETIRQ_ERR
ifdef LANG_GR
MSG_GETIRQ_ERR	 db	 'Fehler beim Einlesen der BIOS-Einsprungspunkte aufgetaucht.',CR,LF
else
MSG_GETIRQ_ERR	 db	 'Error getting BIOS entry points.',CR,LF
endif							; ifdef LANG_GR
@MSG_GETIRQ_ERR_LEN equ  $-MSG_GETIRQ_ERR

	 public  MSG_STOREPTE_ERR
ifdef LANG_GR
MSG_STOREPTE_ERR db	 'Fehler beim Laden der PTEs aufgetaucht.',CR,LF
else
MSG_STOREPTE_ERR db	 'Error Storing PTEs.',CR,LF
endif							; ifdef LANG_GR
@MSG_STOREPTE_ERR_LEN equ $-MSG_STOREPTE_ERR

	 public  MSG_GETPTE_ERR
ifdef LANG_GR
MSG_GETPTE_ERR	 db	 'Fehler beim Wiederherstellen der PTEs aufgetaucht.',CR,LF
else
MSG_GETPTE_ERR	 db	 'Error Retrieving PTEs.',CR,LF
endif							; ifdef LANG_GR
@MSG_GETPTE_ERR_LEN equ  $-MSG_GETPTE_ERR

	 public  MSG_PRESS_ANY_KEY
MSG_PRESS_ANY_KEY label  byte
	db	CR,LF
ifdef LANG_GR
	db	'ROMSRCH mu· Ihre Maus kennenlernen.',CR,LF
	db	'Falls eine solche angeschlossen ist, diese bitte etwas bewegen,',CR,LF
	db	'dann eine beliebige Maustaste betÑtigen.',CR,LF
	db	CR,LF
	db	'weiter im ROMSRCH mit beliebiger Taste auf Ihrer Tastatur ',CR,LF
	db	'(oder ESC zum Abbrechen)... '
else
	db	'ROMSRCH needs to identify your mouse.',CR,LF
	db	'If you have a mouse connected to your machine,',CR,LF
	db	'move the mouse slightly, then press any mouse button.',CR,LF
	db	CR,LF
	db	'Press any key on the keyboard to continue ROMSRCH '
	db	'(or ESC to abort)... '
endif							; ifdef LANG_GR
@MSG_PRESS_ANY_KEY_LEN	equ	$-MSG_PRESS_ANY_KEY

	public	MSG_SYSROM_START, MSG_SYSROM_START1, MSG_SYSROM_START2
ifdef LANG_GR
MSG_SYSROM_START db	'Das BIOS beginnt bei '
MSG_SYSROM_START1 db	'____ und ist '
MSG_SYSROM_START2 db	'____ Seiten lang',CR,LF
else
MSG_SYSROM_START db	'The BIOS starts at '
MSG_SYSROM_START1 db	'____ and is '
MSG_SYSROM_START2 db	'____ pages long',CR,LF
endif							; ifdef LANG_GR
@MSG_SYSROM_START_LEN	 equ	$-MSG_SYSROM_START

;---------------- Misc. Variables ---------------------------

	 public  LCLSTK,LCLSTKZ
	 align	 2
LCLSTK	 db	 2048+100 dup (?) ; Local stack (EISA needs 2KB, PCI 1KB)
LCLSTKZ  dw	 0		; Top of stack

	public	PTE_BUFFER
PTE_BUFFER dd	1024 DUP (3)	; Buffer to hold 1MB of PTE entries

	 public  TEMP_PTE
TEMP_PTE	 dd	 ?	; Temporary storage for single PTE

	 public  VIDEO_MODE, VIDEO_SEG
VIDEO_MODE	db	?	; Initial video mode
VIDEO_SEG	dw	?	; Segment of video buffer

	 public  PRN_TIMEOUT,XBIOS_SEG,XBDA_TMP
PRN_TIMEOUT	db	?	; Time out value for LPT1
XBIOS_SEG	dw	0	; Segment of XBIOS (0 if none)
XBDA_TMP	dw	?	; Temp storage holder

	 public  DOSVER
DOSVER	 dw	 ?		; DOS version number

	 public  CTL387
CTL387	 dw	 ?		; Save area for 387 control word

	 public HEXTABLE, NUMBERS_HI
HEXTABLE   db	 '0123456789ABCDEF'
NUMBERS_HI db	 '0123456789ABCDEF'

	 public  OLDINT05_VEC,OLDINT10_VEC,OLDINT1F_VEC
	 public  OLDINT17_VEC,OLDINT42_VEC,OLDINT43_VEC
OLDINT05_VEC	dd	?	; Save the Int 05 pointer here
OLDINT10_VEC	dd	?	; Save the Int 10 pointer here
OLDINT1F_VEC	dd	?	; Save the Int 1F pointer here
OLDINT17_VEC	dd	?	; Save the Int 17 pointer here
OLDINT42_VEC	dd	?	; Save the Int 42 pointer here
OLDINT43_VEC	dd	?	; Save the Int 43 pointer here

;------------------- IRQ interrupts --------------------------

; The following is a list of all interrupts that we want to call
; via the BIOS entry point, skipping any TSR that grabbed it.

	 public  OLDIRQ_TBL,OLDIRQ_05
OLDIRQ_TBL	label	 byte
	OLDIRQ_STR <02h,?>	; NMI
OLDIRQ_05 OLDIRQ_STR <05h,?>	; Print Screen
	OLDIRQ_STR <06h,?>	; Invalid interrupt
	OLDIRQ_STR <0Ah,?>	; Miscellaneous IRQ
	OLDIRQ_STR <0Bh,?>	; COM2
	OLDIRQ_STR <0Ch,?>	; COM1
	OLDIRQ_STR <0Dh,?>	; LPT2
	OLDIRQ_STR <0Eh,?>	; Diskette
	OLDIRQ_STR <0Fh,?>	; Printer
	OLDIRQ_STR <70h,?>	; Real-time clock
	OLDIRQ_STR <71h,?>	; Redirect to IRQ2
	OLDIRQ_STR <72h,?>	; Reserved
	OLDIRQ_STR <73h,?>	; Reserved
	OLDIRQ_STR <74h,?>	; Pointing device
	OLDIRQ_STR <75h,?>	; 80287
	OLDIRQ_STR <76h,?>	; HD controller
	OLDIRQ_STR <77h,?>	; Reserved

	public @OLDIRQ_NUM
@OLDIRQ_NUM	equ	($-OLDIRQ_TBL)/size OLDIRQ_STR ; Number of IRQs

;------------- Search strings (machine specific) -------------

	 public  EISA_ID
EISA_ID  db	 'EISA'
EISA_IDLEN	 equ	 $-EISA_ID ; Length of above search string

;------------------- Video Save/Restore variables -----------

	 public  VID_ROWS
VID_ROWS	 db	 ?	; Number of video rows on screen

@VID_SAVE_PARA	 equ 40h	; Save area is 40h paras
				; Note: Provide plenty of space, some
				; video adapters don't report the
				; correct save area size required.

	 public  VIDEO_SAVE_AREA
VIDEO_SAVE_AREA  db (@VID_SAVE_PARA*10h) dup (?) ; Reserve space for
				; video Save/Restore states

;------------------- Externs to FUNCS.ASM -------------------

extrn	 MSG_FILE_ERR:byte	; File I/O error message
extrn	 @MSG_FILE_ERR_LEN:abs	; Length of abve error message
extrn	 INT13_BIOS:dword	; Interrupt 13h BIOS entry point
extrn	 @STAT_COMPLETED:abs	; Message number for "Completed" string
extrn	 SAVED_STACK:dword	; New stack for jump to FATAL_ERR_RETUN
extrn	 PORT21_TEMP:byte	; Saved IMR value (master)
extrn	 PORTA1_TEMP:byte	; Saved IMR value (slave)

DATA	 ends			; End DATA segment


;***************************************************************************

XBDASEG  segment use16 para public 'data' ; Start XBDASEG segment

COMMENT |

If the system does not have an XBDA, we use this one.
The AMI Enterprise II BIOS uses the XBDA w/o checking for it's existence.

|

XBDA	 db	1		; Size of Temporary XBDA
	 db	1024-1 DUP (?)	; Rest ...

XBDASEG  ends			; End XBDASEG segment

;***************************************************************************

; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	 segment use16 para public 'data' ; Start DTAIL segment
	 assume  ds:PGROUP

	 public  ZTAIL
ZTAIL	 label	 dword		; Note we're on a para boundary

DTAIL	 ends			; End DTAIL segment


;***************************************************************************

CODE	 segment use16 word public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

extrn	 INT_XX:proc		; Int processing
extrn	 FATAL_ERR_RETURN:proc	; Used by fatal error hook (Int 10)
extrn	 PRESS_ANY_KEY:proc	; Get suer input (check IRQ1)
extrn	 PATCH_INTS:proc	; Patches any interrupts
extrn	 DEBUG_MISC:proc	; Spits out debugging messages
extrn	 MISC_CODE:proc 	; Miscellaneous code
extrn	 READ_WRITE:proc	; FILE I/O tests
extrn	 CHECK_DISKTABLES:proc	; Read in both disk tables
extrn	 CHECK_VIDEOTABLES:proc ; Read in all video tables
extrn	 CHECK_PRTSCR:proc	; Process PRTSCR
extrn	 CHECK_PnP:proc 	; Process Plug 'n Play calls
extrn	 CHECK_ABIOS:proc	; Process both ABIOS calls
extrn	 CHECK_EISA:proc	; Process the EISA calls
extrn	 CHECK_PCI:proc 	; Process the PCI local bus calls
extrn	 CHECK_ALTKEYS:proc	; Process alternate key strokes
extrn	 FIRST_FUNC:byte	; Pointer to the first function
extrn	 I02:byte		; Pointer to interrupt 02 table entry
extrn	 I06:byte		; Pointer to interrupt 06 table entry
extrn	 I75:byte		; Pointer to interrupt 75 table entry

extrn	 FUNC10_TBL:byte	; List of Video function calls
extrn	 FUNC10_TBL_LEN:abs

extrn	 FUNC13_TBL:byte	; List of Diskette function calls
extrn	 FUNC13_TBL_LEN:abs

extrn	 FUNC14_TBL:byte	; List of Serial Port function calls
extrn	 FUNC14_TBL_LEN:abs

extrn	 FUNC15_TBL:byte	; List of System Services function calls
extrn	 FUNC15_TBL_LEN:abs

extrn	 FUNC16_TBL:byte	; List of Keyboard function calls
extrn	 FUNC16_TBL_LEN:abs

extrn	 FUNC17_TBL:byte	; List of Keyboard function calls
extrn	 FUNC17_TBL_LEN:abs

extrn	 FUNC1A_TBL:byte	; List of Time of Day function calls
extrn	 FUNC1A_TBL_LEN:abs

extrn	 FUNC40_TBL:byte	; List of Hard Disk function calls
extrn	 FUNC40_TBL_LEN:abs

extrn	 FUNC_MISC_TBL:byte	; List of Miscellaneous function calls
extrn	 FUNC_MISC_TBL_LEN:abs

extrn	 FUNC_TOTAL:abs 	; Total number of functions to be tested

extrn	 PNETB_CCB:dword	; Interrupt 5C Control Block pointer
extrn	 NETB_CCB_VEC:dword	; Interrupt 5C Control Block pointer

.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list

;***************************************************************************

	 NPPROC  PROBE -- The probe Program
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP

COMMENT|

Probe the BIOS to detect all unused portions.

On exit:
CF	=	0 Program was successfyl
		1 Program was not successful,
		  All recomendations are unreliable

|

.8086

; Display the opening mesage

	 lea	 sp,LCLSTKZ	; Switch to local stack
	 DISP_STDERR MSG_COPY	; Display the flag

	 call	 CHECK_CPUID	; We need 386 or greater
	 jnc	 short @F	; Skip if 386+

	 jmp	 near ptr PROBE_EXIT ; Join common exit code

; N.B. We cannot use any 386 instrucutions before this point

CODE	 ends
.386p
CODE	 segment		; Ensure @WordSize = 2

; Do any initialization
@@:
	 mov	 al,0		; Init function code
	 call	 INITIALIZE	; Init ...

	 call	 CHECK_NDP	; Check for coprocessor

	 call	 CHECK_XT	; Check for XT-class machine

; Parse the command line

	 push	 @PASS1 	; Indicate first pass through parser
	 call	 CHECK_PARMS	; Read the command line
	 jc	 near ptr PROBE_EXIT ; Join common exit code

; Free all our unused memory

	 mov	 bx,(64*1024)/16 ; The MAX size for a .COM program in paras
	 mov	 ah,04Ah	; Modify memory block ES to BX paras
	 int	 21h		; Call DOS services

; Determine if we are running under Windows enhanced mode

	 call	 CHECK_WIN3	; Check it
	 jc	 near ptr PROBE_EXIT_STC ; Win3 present, abort

; Destermine if 386MAX is present (and get info structure)

	 call	 MAX_PRESENT	; Is MAX present?
	 jc	 near ptr PROBE_EXIT_STC ; Nope

; Create an XBDA (if appropriate) - (this has to be done after MAX check)

	 call	 SIMULATE_XBDA	; Create an XBDA (if needed)

; Calculate and display the starting address of the System BIOS

	 call	 CALC_SYSROMSTART ; Calculate PTEs needed for BIOS

; Get the origial PTE's for the BIOS region

	 call	 GET_PTE	; Get the BIOS PTEs
	 jc	 near ptr PROBE_EXIT_STC ; Jump if error

; Turn off any disk caches or screen acclerators here.


; Handle IRQs as special cases

	 call	 GET_OLDIRQS	; Get BIOS entry points for IRQs
	 jc	 near ptr PROBE_GETIRQ_ERROR ; Jump if error

	 call	 IZIT_VGA	; Determine VGA availability

	 call	 IZIT_VESA	; Determine VESA availability

	call	IZIT_PnP	; Determine Plug 'n Play availability

	 call	 PATCH_INTS	; Patch any interrupts
				; This must be done before STORE_PTE

	 call	 SAVE_VIDEO	; Save all video parameters

; Parse the command line

	 push	 @PASS2 	; Indicate second pass through parser
	 call	 CHECK_PARMS	; Read the command line
	 jc	 near ptr PROBE_EXIT ; Join common exit code

; Clear accessed bits for all PTEs (if user requested)

	 call	 STORE_PTE	; Clear and Save all PTEs (back to MAX)
	 jc	 near ptr PROBE_SETPTE_ERROR ; Jump if error

	 call	 CHECK_F000BUFFER ; Set F000-F800 pages if
				  ; ... Tandy 4000 style disk buffer present

; Process the interrupts

	 DISP_STDERR MSG_PRESS_ANY_KEY ; Display Prompt

	 call	PRESS_ANY_KEY	; Envoke user input to begin
	 jc	near ptr PROBE_EXIT_STC ; User requested abort

	 nop			; A debugging tool (start of tests)

	call	CHECK_PnP	; Exercise Plug 'n Play functions if present

; Because of a bug in the Matrox/Millenium VGA/VBE BIOS (V1.5),
; we need to install a Divide Overflow handler to catch a divide
; by zero.

	call	INST_DIVOVF	; Install it

	 lea	si,FUNC10_TBL	; Point to beginning of function table
	 mov	cx,FUNC10_TBL_LEN ; # of entries in table
	 call	INT_XX		; Process Interrupt 10
	pushf			; Save return CF
	call	REST_DIVOVF	; Restore it
	popf			; Restore
	 jc	near ptr PROBE_ABORT ; Jump if user ABORT

	 lea	si,FUNC13_TBL	; Point to beginning of function table
	 mov	cx,FUNC13_TBL_LEN ; # of entries in table
	 call	INT_XX		; Process Interrupt 13
	 jc	short PROBE_ABORT ; Jump if user ABORT

	 lea	si,FUNC14_TBL	; Point to beginning of function table
	 mov	cx,FUNC14_TBL_LEN ; # of entries in table
	 call	INT_XX		; Process Interrupt 14
	 jc	short PROBE_ABORT ; Jump if user ABORT

	 lea	si,FUNC15_TBL	; Point to beginning of function table
	 mov	cx,FUNC15_TBL_LEN ; # of entries in table
	 call	INT_XX		; Process Interrupt 15
	 jc	short PROBE_ABORT; Jump if user ABORT

	 lea	si,FUNC16_TBL	; Point to beginning of function table
	 mov	cx,FUNC16_TBL_LEN ; # of entries in table
	 call	INT_XX		; Process Interrupt 16
	 jc	short PROBE_ABORT ; Jump if user ABORT

	 lea	si,FUNC17_TBL	; Point to beginning of function table
	 mov	cx,FUNC17_TBL_LEN ; # of entries in table
	 call	INT_XX		; Process Interrupt 17
	 jc	short PROBE_ABORT ; Jump if user ABORT

	 lea	si,FUNC1A_TBL	; Point to beginning of function table
	 mov	cx,FUNC1A_TBL_LEN ; # of entries in table
	 call	INT_XX		; Process Interrupt 1A
	 jc	short PROBE_ABORT ; Jump if user ABORT

	 lea	si,FUNC40_TBL	; Point to beginning of function table
	 mov	cx,FUNC40_TBL_LEN ; # of entries in table
	 call	INT_XX		; Process Interrupt 40
	 jc	short PROBE_ABORT ; Jump if user ABORT

	 lea	si,FUNC_MISC_TBL	; Point to beginning of function table
	 mov	cx,FUNC_MISC_TBL_LEN ; # of entries in table
	 call	INT_XX		; Process Miscellaneous Interrupts
	 jc	short PROBE_ABORT ; Jump if user ABORT

; Read all ROM data tables and miscellaneous code

	 call	 MISC_CODE	; Perform misc. code
	 jc	short PROBE_ABORT ; Jump if user ABORT

	 call	 CHECK_ABIOS	; Check the ABIOS routines

	 call	 CHECK_EISA	; Check the EISA routines

	 call	 CHECK_PCI	; Check the PCI local bus routines

	 call	 CHECK_DISKTABLES ; Read in both fixed disk tables

	 call	 CHECK_VIDEOTABLES ; Read in all Video Tables

	 call	 CHECK_ALTKEYS	; Simulate Alternate key strokes

	 call	 CHECK_PRTSCR	; Check PRTSCR and ALT_PRTSCR

	 nop			; A debugging tool (end of tests)

	 mov	 bx,@STAT_COMPLETED ; Tell 'em we've completed
	 call	 DEBUG_MISC	; Spit out debugging string

	 jmp	 short PROBE_CONT ; Skip abort message

PROBE_ABORT:

	 or	 LCL_FLAG,@LCL_ABORT ; Mark as User requesting ABORT

PROBE_CONT:

; Set special AMI debugging bits (for debugging, only)

	 call	 STORE_AMI_PTE	; Set AMI pages as supervisor
	 jc	 near ptr PROBE_SETPTE_ERROR ; Jump if error

; Get the current PTE's for the BIOS region

	 call	 GET_PTE	; Get the BIOS PTEs
	 jc	 near ptr PROBE_GETPTE_ERROR ; Jump if error

	 call	 REST_VIDEO	; Restore all the video variables

; Display all the current BIOS's PTEs

	 DISP_STDOUT MSG_EOL	; CR,LF
	 DISP_STDOUT MSG_COPY	; Display the flag (again)
	 DISP_STDOUT MSG_EOL	; CR,LF
	 DISP_STDOUT MSG_FINI	; Display the fini message

	 call	 SUGGEST_USE	; Suggest any USE= statements

; Display any caveats (and set error flag if needed)

	 test	 LCL_FLAG,@LCL_FILE_ERR ; Was there a file I/O error?
	 jz	 short @F	; Jump if not

	 DISP_STDOUT MSG_FILE_ERR ; Display I/O error message
	 DISP_STDOUT MSG_CAVEAT ; Display Caveat
	 mov	 ERR_CODE,1	; Report error to calling program (if any)
@@:

	 test	 LCL_FLAG,@LCL_ABORT ; Did the user ABORT prematurely?
	 jz	 short @F	; Jump if not

	 DISP_STDOUT MSG_ABORT ; Display ABORT message
	 DISP_STDOUT MSG_CAVEAT ; Display Caveat
	 mov	 ERR_CODE,1	; Report error to calling program (if any)
@@:

	 jmp	 PROBE_EXIT	; Exit

PROBE_GETIRQ_ERROR:
	 DISP_STDOUT MSG_GETIRQ_ERR
	 jmp	 short PROBE_EXIT_STC ; Join common exit code

PROBE_SETPTE_ERROR:
	 DISP_STDOUT MSG_STOREPTE_ERR
	 jmp	 short PROBE_EXIT_STC ; Join common exit code

PROBE_GETPTE_ERROR:
	 DISP_STDOUT MSG_GETPTE_ERR
;;;;;;;; jmp	 short PROBE_EXIT_STC ; Join common exit code

PROBE_EXIT_STC:

	 mov	 ERR_CODE,1	; Report error to calling program (if any)

PROBE_EXIT:

; Do any un-initialization

	 mov	 al,1		; Un-Init function code
	 call	 INITIALIZE	; Un-Init ...

	 mov	 ah,4Ch 	; Return to DOS function code
	 mov	 al,ERR_CODE	; Return code
	 int	 21h		; Good Bye...

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROBE	 endp			; End PROBE procedure


;***************************************************************************

	NPPROC	INST_DIVOVF -- Install Divide Overflow Handler
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Install Divide Overflow handler

|

	REGSAVE <ax,bx,dx,es>	; Save registers

	mov	al,00h		; Divide Overflow interrupt #
	DOSCALL @GETINT 	; Return with ES:BX ==> old handler
	assume	es:nothing	; Tell the assembler about it

	mov	OLDINT00_VEC.VOFF,bx ; Save to restore later
	mov	OLDINT00_VEC.VSEG,es ; ...

;;;;;;; mov	al,00h		; Divide Overflow interrupt #
	DOSCALL @SETINT,LCL_INT00 ; Install our own handler

	REGREST <es,dx,bx,ax>	; Restore
	assume	es:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_DIVOVF endp		; End INST_DIVOVF procedure

;***************************************************************************

	NPPROC	REST_DIVOVF -- Restore Divide Overflow Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore Divide Overflow handler

Note no segment register assumes so we can call it from LCL_INT00.

|

	REGSAVE <ax,dx,ds>	; Save registers

	lds	dx,OLDINT00_VEC ; DS:DX ==> old handler
	assume	ds:nothing	; Tell the assembler about it

	mov	al,00h		; Divide Overflow interrupt #
	DOSCALL @SETINT 	; Restore old handler

	REGREST <ds,dx,ax>	; Restore
	assume	ds:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_DIVOVF endp		; End REST_DIVOVF procedure

;***************************************************************************

	FPPROC	LCL_INT00 -- Local Divide Overflow Interrupt Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local Divide Overflow interrupt handler

Because of a bug in the Matrox/Millenium VGA/VBE BIOS (V1.5),
we need to install a Divide Overflow handler to catch a divide
by zero.

* If the byte at 40:85 is zero, set it to a non-zero value (8 is good).
* Restore the original handler in case this isn't the problem/solution.

|

	REGSAVE <ax,ds> 	; Save registers

	mov	ax,seg BIOSDATA ; Get segment of BIOS data area
	mov	ds,ax		; Address it
	assume	ds:BIOSDATA	; Tell the assembler about it

	cmp	EGA_PNTS.LO,00h ; Is this the possible divisor?
	jne	short @F	; Jump if not

	mov	EGA_PNTS.LO,08h ; Tell 'em to use a bigger divisor
@@:
	call	REST_DIVOVF	; Restore it

	REGREST <ds,ax> 	; Restore
	assume	ds:nothing	; Tell the assembler about it

	iret			; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT00 endp			; End LCL_INT00 procedure

;***************************************************************************

	 NPPROC  CHECK_CPUID -- Check On CPU Identifier
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're running on an 80386 or later processor.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

N.B.:  Use only 8088 instructions!!!!

|
.8086

	 REGSAVE <ax>		; Save register

	 push	 sp		; First test for earlier than a 286
	 pop	 ax

	 cmp	 ax,sp		; Same?
	 jne	 short CHECK_CPUID_ERR ; No, it's too early

; Now distinguish 286 from 386
.286
	 pushf			; Save flags for a moment

	 push	 mask $IOPL	; Try to set IOPL bits in flag register
	 popf

	 pushf			; Get flags back into AX
	 pop	 ax

	 popf			; Restore original flags

	 test	 ax,mask $IOPL	; Any bits set?
	 jz	 short CHECK_CPUID_ERR ; No, so it's a 286

	 clc			; Assume 386 or greater
	 jmp	 short CHECK_CPUID_EXIT ; Join common exit code

CHECK_CPUID_ERR:
	 DISP_STDOUT MSG_NOT386 ; Tell 'em the bad news
	 stc			; Indicate we have a problem

CHECK_CPUID_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPUID endp		; End CHECK_CPUID procedure

CODE	 ends
.386p
CODE	 segment		; Ensure @WordSize = 2

;***************************************************************************

	 NPPROC  CHECK_PARMS -- CHECK_PARMS Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Read command line parameters

|

PARM_STR struc

	 dw	 ?		; Caller's IP
	 dw	 ?		; ...	   BP
PARM_FLG dw	 ?		; @PASS1 if pass #1 (we should not mark skip values)
				; @PASS2 if pass #2 (we should ...)
PARM_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,si>	; Save registers

	 lea	 si,PSP_PARM_STRING ; DS:SI ==> parameter string

SKIPWHITE:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 short SKIPWHITE ; Jump if so

	 cmp	 al,TAB 	; Izit white space?
	 je	 short SKIPWHITE ; Jump if so

	 cmp	 al,'?'         ; Izit a request for help?
	 je	 short PROBE_HELP ; Jump if so

	 cmp	 al,CR		; Izit end of parms?
	 je	 short CHECK_PARMS_CLC ; Jump if so

	 cmp	 al,'/'         ; Izit switch character?
	 jne	 short PROBE_HELP ; Jump if not

	 call	 SWPROC 	; Process switch character at DS:SI
	 jnc	 short SKIPWHITE ; Jump if it's valid
PROBE_HELP:
	 DISP_STDOUT MSG_HELP ; Display Help message
	 stc			; Mark as All Done
	 jmp	 short CHECK_PARMS_EXIT

CHECK_PARMS_CLC:
	 clc			; Mark as successful

CHECK_PARMS_EXIT:
	 REGREST <si,ax>	; Restore registers

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PARMS	 endp			; End CHECK_PARMS_PROC procedure

;*************************************************************************

	 NPPROC  SWPROC -- Process Switch Character
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

COMMENT |

Process switch character

On entry:

DS:SI	 ==>	 switch character
SS:BP	 ==>	 PARM_STR

On exit:

CF	 =	 1 if valid switch character
	 =	 0 otherwise

DS:SI	 ==>	 (updated)

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 lodsb			; Get switch character
	 call	 LOWERCASE	; Convert to common case

	 cmp	 al,'x'         ; Izit SYSROM start address?
	 jne	 short @F	; Jump if not

	 call	 HEX2BIN	; Convert ASCII hex at DS:SI to binary in AX

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 and	 ax,not((4*1024/(16-0))-1) ; Round down to 4KB (in paras)
	 mov	 SYSROM_START,ax ; Store as start of System BIOS

	 clc			; Mark as successful

	 jmp	 near ptr SWPROC_EXIT ; Join common exit code
@@:

	 cmp	 al,'p'         ; Izit the PTE supervisory option or PCI skip?
	 jne	 short SWPROC_XP ; Jump if not

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 mov	 ax,PGROUP:[si].ELO ; Get next 2 characters
	 call	 LOWERCASE	; Convert to lowercase
	 xchg	 ah,al		; Swap 'em
	 call	 LOWERCASE	; Convert 2nd character to lowercase
				; Leave AX big-endian

	 cmp	 ax,'ci'        ; Izit 'Skip PCI'?
	 jne	 short @F	; Jump if not (assume PTE)

	 lodsw			; Discard 'CI'

	 or	 CMD_FLAG,@CMD_SKIPPCI ; Skip PCI local bus BIOS functions

	 clc			; Mark as successful

	 jmp	 near ptr SWPROC_EXIT ; Join common exit code

@@:
	 or	 CMD_FLAG,@CMD_AMIBIOS ; Mark as AMI version

	 clc			; Mark as successful

	 jmp	 near ptr SWPROC_EXIT ; Join common exit code
SWPROC_XP:
	 cmp	 al,'d'         ; Izit call debugger on interrupt?
	 jne	 short @F	; Jump if not

	 lodsw			; Get next two characters (int number)

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 call	 PROC_DEBUG	; Process debugging switch
	 jc	 near ptr SWPROC_ERR ; jump if error

	 jmp	 near ptr SWPROC_EXIT ; Join common exit code
@@:
	 cmp	 al,'r'         ; Izit skip all IBM reserved ints?
	 jne	 short @F	; Jump if not

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 or	 CMD_FLAG,@CMD_SKIPRES ; Set to skip 'em all

	 clc			; Mark as successful

	 jmp	 SWPROC_EXIT	; Join common exit code
@@:
	 cmp	 al,'u'         ; Izit Recover USE= pages?
	 jne	 short @F	; Jump if not

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 or	 LCL_FLAG,@LCL_ALLPAGES ; Mark as recovering all valid pages

	 clc			; Mark as successful

	 jmp	 SWPROC_EXIT	; Join common exit code
@@:
	 cmp	 al,'b'         ; Izit Beep as a debugging tool?
	 jne	 short @F	; Jump if not

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 or	 CMD_FLAG,@CMD_DEBUGBEEP ; Set Debug Beep flag

	 clc			; Mark as successful

	 jmp	 SWPROC_EXIT	; Join common exit code
@@:
	 cmp	 al,'w'         ; Izit write debugging info
	 jne	 short @F	; Jump if not

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 or	 CMD_FLAG,@CMD_DEBUGWRITE ; Mark as needing debugging info

	 clc			; Mark as successful

	 jmp	 SWPROC_EXIT	; Join common exit code
@@:
	 cmp	 al,'a'         ; Izit 'Skip ABIOS' request?
	 jne	 short @F	; Jump if not

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 or	 CMD_FLAG,@CMD_SKIPABIOS ; Set Skip ABIOS flag

	 clc			; Mark as successful

	 jmp	 SWPROC_EXIT	; Join common exit code
@@:
	 cmp	 al,'e'         ; Izit 'Skip EISA' request?
	 jne	 short @F	; Jump if not

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 or	 CMD_FLAG,@CMD_SKIPEISA ; Set Skip EISA flag

	 clc			; Mark as successful

	 jmp	 SWPROC_EXIT	; Join common exit code
@@:
	 cmp	 al,'n'         ; Izit 'Skip Int02 and Int06' request?
	 jne	 short @F	; Jump if not

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 or	 I02.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I06.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I75.P_FLAG,@SKIP ; Skip this interrupt (chained to Int 02)

	 clc			; Mark as successful

	 jmp	 SWPROC_EXIT	; Join common exit code
@@:
	 cmp	 al,'v'         ; Izit skip secondary video call?
	 jne	 short @F	; Jump if not

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 or	 CMD_FLAG,@CMD_SKIP42 ; Skip INT 42 checking

	 clc			; Mark as successful

	 jmp	 SWPROC_EXIT	; Join common exit code
@@:

	 cmp	 al,'s'         ; Izit Skip interrupt nn?
	 jne	 short @F	; Jump if not

	 call	 HEX2BIN	; Convert ASCII hex at DS:SI to binary in AX

	 cmp	 [bp].PARM_FLG,@PASS2 ; Izit pass #2?
	 jne	 near ptr SWPROC_CLC ; Jump if not

	 mov	 bx,STRUCT_LEN	; Size of each element
	 mul	 bx		; Mulitply (AX*BX=DX:AX)

	 mov	 bx,ax		; Move to offset index register
	 or	 FIRST_FUNC[bx].P_FLAG,@SKIP ; Skip this interrupt

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'q'         ; Izit 'Assume XBDA exists'?
	 jne	 short @F	; Jump if not

	 cmp	 [bp].PARM_FLG,@PASS1 ; Izit pass #1?
	 jne	 short SWPROC_CLC ; Jump if not

	 or	 LCL_FLAG,@LCL_XBDA_PRES ; Assume present

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code
@@:
	 cmp	 al,'i'         ; Izit skip interrupt with optional function?
	 jne	 short SWPROC_XI ; Jump if not

; If there's two following digits only, skip all functions for the
; corresponding interrupt #.  If there's four following digits, skip
; the interrupt #/function # (AH) pair only.

	 mov	 dh,ds:[si+2]	; Check for more than two hex digits
	 call	 HEX2BIN	; Convert ASCII hex at DS:SI to binary in AX
				; If both, AH = int #,	AL = fn #
				; else	   AH = 00,	AL = int #

	 cmp	 [bp].PARM_FLG,@PASS2 ; Izit pass #2?
	 jne	 short SWPROC_CLC ; Jump if not

	 mov	 dl,0		; Assume interrupt only

	 cmp	 dh,'/'         ; Izit switch character?
	 je	 short @F	; Jump if so

	 cmp	 dh,CR		; Izit end of the list?
	 je	 short @F	; Jump if so

	 cmp	 dh,' '         ; Izit white space?
	 je	 short @F	; Jump if so

	 cmp	 dh,TAB 	; Izit white space?
	 je	 short @F	; Jump if so

	 mov	 dl,1		; Mark as interrupt #/function #
	 xchg	 al,ah		; Swap to counter next XCHG
				;	   AH = fn #,	AL = int #
@@:
	 xchg	 al,ah		; Swap to put int # into common register
				; If both, AH = int #,	AL = fn #
				; else	   AH = int #	AL = 00
	 mov	 cx,FUNC_TOTAL	; Get total # functions in FIRST_FUNC table
	 xor	 bx,bx		; Initialize index into FIRST_FUNC
SWPROC_INEXT:
	 cmp	 ah,FIRST_FUNC[bx].P_INTNO.LO ; Izit same interrupt #?
	 jne	 short SWPROC_ILOOP ; Jump if not

	 cmp	 dl,1		; Is the function # specified?
	 jne	 short @F	; Jump if not

	 cmp	 al,FIRST_FUNC[bx].P_AX.HI ; Izit the same function #?
	 jne	 short SWPROC_ILOOP ; Jump if not
@@:
	 or	 FIRST_FUNC[bx].P_FLAG,@SKIP ; Mark as to be skipped
SWPROC_ILOOP:
	 add	 bx,STRUCT_LEN	; Skip to next structure entry

	 loop	 SWPROC_INEXT	; Jump if more entries to check

SWPROC_ICLC:
	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code

SWPROC_XI:

SWPROC_ERR:
	 stc			; Mark as invalid

	 jmp	 short SWPROC_EXIT ; Join common exit code

SWPROC_CLC:
	 clc			; Mark as successful

SWPROC_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SWPROC	 endp			; End SWPROC procedure

;***************************************************************************

	 NPPROC  PROC_DEBUG -- Process Debug command line options
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Process debugging switches

On entry :	AX	=	Debugging number

On exit :	CF	=	0 if all went well
				1 if error

|

SET_DEBUG macro NUM, ASCII_NUM

	 cmp	 ax,&ASCII_NUM	; Izit special number
	 jne	 short @F	; Jump if not

	 or	 CMD_FLAG,@CMD_DEBUG&NUM ; Mark as Debugguing spec interrupt

	 jmp	 short PROC_DEBUG_CLC ; Join common exit ocde
@@:

endm			; End of SET_DEBUG macro

	 REGSAVE <ax>	; Save registers

	 SET_DEBUG	10, '01' ; Debug all Interrupt 10s
	 SET_DEBUG	13, '31' ; Debug all Interrupt 13s
	 SET_DEBUG	15, '51' ; Debug all Interrupt 15s
	 SET_DEBUG	1A, 'A1' ; Debug all Interrupt 1As
	 SET_DEBUG	1A, 'a1' ; Debug all Interrupt 1As
	 SET_DEBUG	40, '04' ; Debug all Interrupt 40s
	 SET_DEBUG	42, '24' ; Debug all Interrupt 42s
	 SET_DEBUG	99, '99' ; Debug all Interrupt Misc

@@:
PROC_DEBUG_STC:
	 stc			; Mark as error
	 jmp	 short PROC_DEBUG_EXIT ; Join common exit code

PROC_DEBUG_CLC:
	 clc			; Mark as option set

PROC_DEBUG_EXIT:

	 REGREST <ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_DEBUG	 endp			; End PROC_DEBUG procedure

;***************************************************************************

	 NPPROC  CHECK_WIN3 -- CHECK_WIN3 Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

On exit: CF set if Win3 / enhanced mode is present

|

	 REGSAVE <ax,dx>	; Save registers

	 mov	 ax,1600h	; Enhanced Windows installation check
	 int	 2Fh		; Windows API

	 test	 al,7Fh 	; Check for enhanced Windows
	 jz	 short CHECK_WIN3_CLC ; Enhanced Windows is not running

	 cmp	 al,1		; Is it Windows/386 version 2.xx?
	 je	 short CHECK_WIN3_CLC ; Yes, so skip it

	 cmp	 al,0FFh	; Is it Windows/386 version 2.xx?
	 je	 short CHECK_WIN3_CLC ; Yes, so skip it

; Enhanced Windows/386 is running.  AL = major version #, AH = minor version #

	 DISP_STDOUT MSG_WIN3 ; Display Windows 3.0 problem
	 stc			; Mark as Win3 present
	 jmp	 short CHECK_WIN3_EXIT ; Exit

; Enhanced Windows/386 is NOT running, continue on.

CHECK_WIN3_CLC:
	 clc			; Mark as Win3 not present

CHECK_WIN3_EXIT:

	 REGREST <dx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_WIN3	 endp			; End CHECK_WIN3 procedure

;***************************************************************************

	 NPPROC  CHECK_XT -- CHECK_XT Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Check to see if the machine is an XT class

|

	 REGSAVE <ax,es>	; Save registers

	 mov	 ax,seg CGROUP	; Address the system BIOS
	 mov	 es,ax		; ... via ES
	 assume  es:CGROUP	; Tell the assembler about it

	 mov	 al,BIOSCPUID	; Get the machine ID byte

	 cmp	 al,@CPU_PC	; Check for PC
	 je	 short CHECK_XT_FOUND ; Jump if present

	 cmp	 al,@CPU_XT	; Check for XT
	 je	 short CHECK_XT_FOUND ; Jump if present

	 cmp	 al,@CPU_XT2	; Check for XT2
	 je	 short CHECK_XT_FOUND ; Jump if present

	 cmp	 al,@CPU_CNV	; Check for Convertible
	 je	 short CHECK_XT_FOUND ; Jump if present

	 cmp	 al,@CPU_JR	; Check for Jr
	 je	 short CHECK_XT_FOUND ; Jump if present

	 jmp	 short CHECK_XT_EXIT ; Jpoin common exit code

CHECK_XT_FOUND:
	 or	 LCL_FLAG,@LCL_XTCLASS ; Indicate we're on an XT-class machine

CHECK_XT_EXIT:
	 REGREST <es,ax>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XT	 endp			; End CHECK_XT procedure

;*************************************************************************

	 NPPROC  MAX_PRESENT -- Check for 386MAX device presence
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

This routine taken from Bill's VMAX_RMI

Fill in SYSROM_START and EMM2 I/O Port Number

|

	 REGSAVE <ax,bx,cx,dx>	; Save caller's registers

	 mov	 al,02h 	; R/W access
	 DOSCALL @OPENF2,DEVNAME_MAX ; Attempt to open 386MAX device driver
	 jnc	 short MP_OK1	; Skip error code if open

MP_NOMAX:
	 DISP_STDOUT MSG_NOMAX ; Tell 'em 386MAX.SYS is not present

	 jmp	 near ptr MP_ERRXIT ; Join common error exit code

MP_BADVER:
	 DISP_STDOUT MSG_BADVER ; Tell 'em 386MAX.SYS is not present

	 jmp	 near ptr MP_ERRXIT ; Join common error exit code
MP_OK1:

; Ensure it's a device

	 mov	 DEV_HNDL,ax	; Save for later use
	 mov	 bx,ax		; Move handle to proper register

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 short MP_NOMAX ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short MP_NOMAX ; No???

; Get QMAXINFO structure

	 mov	 al,02h 	; Read from device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

; Make sure its us and versions are in order

	 cmp	 INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short MP_NOMAX ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short MP_NOMAX ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short MP_NOMAX ; Not this time

	 cmp	 INFO.INFO_VER[0],MAXVERS_H ; Compare high version #
	 jl	 short MP_BADVER ; Jump if below our minimum

	 mov	 ax,INFO.INFO_P67 ; I/O port number for EMM2 functions
	 mov	 PORT67,ax	; Save for EMMOUT macro

	 mov	 ax,INFO.INFO_QMAX ; Get low DOS segment
	 mov	 MAXLO_SEG,ax	; ... and save for later

	 mov	 ax,INFO.INFO_LSEG ; Get LSEG entry
	 mov	 MAX_LSEG,ax	; ... and save for later

	 test	 INFO.INFO_CM3,@CM3_NOWIN3 ; Is NOWIN3 in effect?
	 jz	 short @F	; Jump if not

	 or	 LCL_FLAG,@LCL_NOWIN3 ; Set our local NOWIN3 flag
@@:

	 test	 INFO.INFO_LCL,(@LCL_BCF or @LCL_CROM) ; Is ROM compressed?
	 jnz	 short MP_COMPROM ; Jump if so

	 cmp	 SYSROM_START,@SYSROM_DEFAULT ; Izit still the default
	 jne	 short @F	; Skip if user defined SYSROM_START

	 mov	 ax,INFO.INFO_SROM ; Start of system ROM
	 mov	 SYSROM_START,ax ; Save for other calculations
@@:

	 clc			; Indicate all went well
MP_XIT:
	 REGREST <dx,cx,bx,ax>	; Restore caller's registers

	 ret			; ... to caller

MP_COMPROM:
	 DISP_STDOUT MSG_COMPROM ; Tell 'em the ROM is already compressed

MP_ERRXIT:
	 stc			; Indicate something failed
	 jmp	 short MP_XIT	; Join common return code


	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
MAX_PRESENT endp		; End of MAX_PRESENT routine

;***************************************************************************

	 NPPROC  CALC_SYSROMSTART -- Calculate # of PTEs in System ROM
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Format and display System ROM start string.
Calculate number of PTEs used in ROM

|

	 REGSAVE <ax,bx,dx,di>	; Save registers

; Get and format System ROM start

	 mov	 ax,SYSROM_START ; Address of start of ROM
	 lea	 di, MSG_SYSROM_START1 ;
	 call	 FMT_WORD	; Format AX -> ES:DI

; Get the number of pages we are analyzing

	 mov	 bx,SYSROM_START ; Address of start of ROM (paras)
	 mov	 ax,0000h	; Top of the BIOS
	 sub	 ax,bx		; Get length of BIOS
	 shr	 ax,(12-4)	; Convert paras -> 4KB increments

; Handle entrire MB as special case

	 cmp	 ax,0		; Izit 0?
	 jnz	 short @F	; Jump if not

	 mov	 ax,1024/4	; Set PTE_COUNT to maximum (1MB/4KB)
@@:

; Save and display the number of pages we are interested in

	 mov	 PTE_COUNT,ax	; Save # of PTEs that are of interest to us
	 lea	 di, MSG_SYSROM_START2 ;
	 call	 FMT_WORD	; Format AX -> ES:DI

	 test	 CMD_FLAG,@CMD_DEBUGWRITE or @CMD_DEBUGBEEP ; Debugging today?
	 jz	 short @F	; Jump if not

	 DISP_STDOUT MSG_EOL  ; CR, LF, EOS
	 DISP_STDOUT MSG_SYSROM_START ; Display the address and size of ROM
@@:

	 REGREST <di,dx,bx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_SYSROMSTART	 endp			; End CALC_SYSROMSTART procedure

;***************************************************************************

	 NPPROC  GET_PTE -- GET_PTE Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Gets the PTEs for the BIOS region.

On exit:
CF	=	0 if sucessfull
		1 if error

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 mov	 cx,SYSROM_START ; Get start of system ROM
	 neg	 cx		; Get size of BIOS (or BIOSes)
	 shr	 cx,(10-4)	; Convert paras to PTE entries

	 lea	 di,PTE_BUFFER	; Buffer to hold PTE entries
	 mov	 si,SYSROM_START ; Starting address of BIOS
	 shr	 si,(10-4)	; Convert from Paras to KB

	 mov	 al,0		; Disable 1MB wrap (0 or 1 is valid)
	 EMMOUT  @EMM2_GETPTE	; Get PTE function

	 cmp	 ah,8Fh 	; Error?
	 je	 short GET_PTE_ERR ; Yep

	 cmp	 ah,87h 	; Error?
	 je	 short GET_PTE_ERR ; Yep

	 clc			; Mark as successful
	 jmp	 short GET_PTE_EXIT ; Exit

GET_PTE_ERR:
	 DISP_STDOUT MSG_PTE_ERR ; Tell 'em the bad news

	 stc			; Mark as unsuccessful

GET_PTE_EXIT:

	 REGREST <di,si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_PTE  endp			; End GET_PTE procedure

;***************************************************************************

	 NPPROC  STORE_PTE -- STORE_PTE Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

This code taken from VMAX.ASM (Bill's VXD code)

On entry:	BX  =	PTE index (offset from from PTE_BUFFER)

On exit:
CF	=	0 if sucessfull
		1 if error

|

	 REGSAVE <ax,ebx,cx,edx,esi,edi> ; Save registers

	 xor	 edi,edi	; Start at first PTE
	 mov	 cx,PTE_COUNT	; Set counter

STORE_PTE_NEXT:

	 mov	 edx,[edi*4].PTE_BUFFER ; Get next PTE

; Mask PTE entry as desired

	 and	 edx,not (mask $PTE_A) ; Mask off Accessed bit
;;;;;;;; and	 edx,not (mask $PTE_RW) ; Mask off Read/Write bit

; Calculate linear address of page in the BIOS

	 movzx	 esi,SYSROM_START ; Get the start of the BIOS (paras)
	 shl	 esi,(4-0)	; Convert paras to bytes
	 mov	 ebx,edi	; Get PTE index
	 shl	 ebx,(12-0)	; Convert PTE index to bytes
	 add	 esi,ebx	; Add in BIOS start to BIOS offset

	 EMMOUT  @EMM2_SETPTE	; Set single PTE (result in AH)
				; ESI=Linear Address
				; EDX=New PTE value

	 cmp	 ah,0		; Success?
	 jne	 short STORE_PTE_ERR ; No

	 inc	 edi		; Next PTE

	 loop	 STORE_PTE_NEXT ; Do again, if more PTEs are left

STORE_PTE_CLC:

; Unfortunately, early implementations (6.00 and 6.01) of EMM2_SETPTE
; do not flush the TLB as they are supposed to.  We take care of this
; by flipping the Flush TLB flag, which will flush the TLB upon exit
; from the very same EMM2 call that flips the bit.  We do this twice
; just to ensure that by flipping the bit, we're setting it, not
; clearing it.

	 mov	 bx,@GLB_TLB	; Flip the flush TLB flag
	 EMMOUT  @EMM2_GLBFLAG	; Flip bits in GLB_FLAG

	 mov	 bx,@GLB_TLB	; Flip the flush TLB flag
	 EMMOUT  @EMM2_GLBFLAG	; Flip bits in GLB_FLAG

	 clc			; Mark as successful

	 jmp	 short STORE_PTE_EXIT ; All Done

STORE_PTE_ERR:
	 stc			; Mark as unsuccessful

STORE_PTE_EXIT:

	 REGREST <edi,esi,edx,cx,ebx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STORE_PTE	 endp			; End STORE_PTE procedure

;***************************************************************************

	 NPPROC  STORE_AMI_PTE -- AMI Voyager debugging
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Mark all unused pages as 'Supervisor'.
This routine is called after all of PROBE has been processed.

This routine is used to debug the case when we think we might be
recovering valid BIOS code.  If so, then SWAT will pop-up when
the BIOS tries to execute from the recovered pages.


On exit:
CF	=	0 if sucessfull
		1 if error

|

	 REGSAVE <ax,ebx,cx,edx,esi,edi> ; Save registers

	 test	 CMD_FLAG,@CMD_AMIBIOS ; Are we to do AMI debugging?
	 jz	 short STORE_AMI_PTE_CLC ; Jump if not

; Get first PTE

	 movzx	 esi,SYSROM_START ; Get the start of the BIOS (paras)
	 mov	 cx,PTE_COUNT	; Number of PTEs we are interested in

STORE_AMI_NEXT:

	 REGSAVE <cx>		; Save PTE counter

	 lea	 di,ZTAIL	; Buffer to hold PTE entry
	 mov	 cx,4		; 1 PTE
	 shr	 si,(10-4)	; Convert from Paras to KB

	 mov	 al,0		; Disable 1MB wrap (0 or 1 is valid)
	 EMMOUT  @EMM2_GETPTE	; Get PTE function

	 cmp	 ah,8Fh 	; Error?
	 je	 short STORE_AMI_PTE_ERR ; Yep

	 cmp	 ah,87h 	; Error?
	 je	 short STORE_AMI_PTE_ERR ; Yep

; Is the current entry unused?

	 mov	 edx,ZTAIL	; Get PTE

	 test	 edx,mask $PTE_A ; Is accessed bit set?
	 jnz	 short @F	; Jump if accessed

; Modify PTE as 'Supervisor' (if it was unused)

	 and	 edx,not (mask $PTE_US) ; Mask off User status
@@:

; Store new PTE back in the Page Table

	 shl	 esi,(10-0)	; Convert from KB to bytes

	 EMMOUT  @EMM2_SETPTE	; Set single PTE (result in AH)
				; ESI=Linear Address
				; EDX=New PTE value

	 cmp	 ah,0		; Success?
	 jne	 short STORE_AMI_PTE_ERR ; Jump if not

	 REGREST <cx>		; Restore counter

	 add	 esi,4096	; Next 4KB block
	 shr	 esi,(4-0)	; Convert from byte to paras
	 loop	 short STORE_AMI_NEXT ; Do for next PTE

STORE_AMI_PTE_CLC:
	 clc			; Mark as successful
	 jmp	 short STORE_AMI_PTE_EXIT ; All Done

STORE_AMI_PTE_ERR:
	 REGREST <cx>		; Restore counter (called from a few places)
	 stc			; Mark as unsuccessful

STORE_AMI_PTE_EXIT:

	 REGREST <edi,esi,edx,cx,ebx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STORE_AMI_PTE	 endp			; End STORE_AMI_PTE procedure

;***************************************************************************

	 NPPROC  GET_OLDIRQS -- GET_OLDIRQS Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Get the BIOS entry Points for all IRQs directly from MAX.

By using the BIOS entry point for these interrupts, we avoid software
drivers that hook these interrupts, but get confused when they are
called from software (as opposed to being called by the 8259).

On exit :
CF	=	0 if all went well.
		1 if error.

|

	 REGSAVE <eax,bx,cx,edx> ; Save registers

	 mov	 cx,@OLDIRQ_NUM ; Get number of IRQs to process
	 lea	 bx,OLDIRQ_TBL	; Start of our table

OLDIRQ_NEXT:

	 mov	 al,[bx].OLDIRQ_NUM ; Get interrupt number

	 EMMOUT  @EMM2_GETOLDINT ; Get OLDINT (AL) vector in EDX

	 cmp	 ah,84h 	; Failure?
	 je	 short GET_OLDIRQS_ERR ; Jump if so

	 cmp	 ah,8Bh 	; Failure?
	 je	 short GET_OLDIRQS_ERR ; Jump if so

	 mov	 [bx].OLDIRQ_VEC,edx ; Store vector

	 add	 bx,size OLDIRQ_STR ; Next item in list
	 loop	 short OLDIRQ_NEXT ; Process next vector

	 clc			; Mark as successful
	 jmp	 short GET_OLDIRQS_EXIT ; join common exit code

GET_OLDIRQS_ERR:
	 stc			; Mark as error

GET_OLDIRQS_EXIT:

	 REGREST <edx,cx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_OLDIRQS	 endp			; End GET_OLDIRQS procedure

;***************************************************************************

	 NPPROC  SUGGEST_USE -- SUGGEST_USE Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

This is where we calculate which areas are free to be USE= by MAX.

Scan through the Page Table Entries in question, looking at the
accessed bits.	When we cross a transition from accessed to not accessed
(or visa-versa), then an action has to be taken.

There are 4 possibilities as we scan through the Page Table entries...

1) Scanning unused portion, coming from same.
   Action: Increment number of free memory by 4KB.

2) Scanning unused portion, previous portion is used.
   Action: Set starting address of USE= statement.
	   Adjust flag to reflect new scan area is of type 'unused'.
	   Initialize free memory counter at 4KB.

3) Scanning used portion of the BIOS, coming from same.
   Action: None.

4) Scanning used portion, previous portion is unused.
   Action: Format ending address of USE= statement.
	   Format memory count for USE= comment
	   Display USE= statement.
	   Adjust flag to reflect new scan area is of type 'used'.

Local variables:
BP = Amount of unused memory in current block.
DX = 1 if the page in question has the accessed bit clear
   = 0 otherwise.

|

	 pushad 		; Save all EGP registers

	 DISP_STDOUT MSG_EOL	; CR, LF, EOS

	 mov	 bp,4		; Start out with 4KB saved
	 xor	 dx,dx		; Mark as not in unaccessed portion of BIOS
	 mov	 bx,0		; Index to PTE Buffer
	 mov	 cx,PTE_COUNT	; Number of PTEs to display
	 mov	 si,SYSROM_START ; Start of System ROM

SUGGEST_NEXT_PTE:
	 push	 cx		; Save counter

COMMENT |

The following case should cover all possible uses of all page table entries
in system ROM address space.

TYPE:	       R/W  1:1  $PTE_CD  $PTE_AV0  Recover?  Comments
-----	       ---  ---  -------  --------  --------  --------
1) USE= 	Y    N	    N	      N        N
2) INCLUDE=	Y   Y/N     N	      Y        N
3) RAM= 	Y    Y	    Y	      N        N
4) ROM= 	N    Y	    N	      N        Y      Cached C&T ROM
5) ROM= 	N    N	    N	      N        Y      Cached non C&T ROM
6) Unspecified	Y    Y	    N	      N        Y

|

; If ACCESSED, do not recover this page

	 test	 PTE_BUFFER[bx],(mask $PTE_A) ;
	 jnz	 short SU_XRECOVER ; Jump if page is Accessed

; If EMS mappable (case 2) or Explicit RAM= (case 3),
; then do not recover this page

	 test	 PTE_BUFFER[bx],(mask $PTE_AV0 or mask $PTE_CD) ;
	 jnz	 short SU_XRECOVER ; Jump if page EMS mappable or explicit RAM=

; If 1:1 (case 4 or case 6), then recover this page

	 mov	 eax,PTE_BUFFER[bx] ; Pick up entry
	 and	 ax,mask $PTE_FRM ; Isolate the physical address

	 movzx	 edi,SYSROM_START ; Get start of ROM in paras
	 shl	 edi,(4-0)	; Convert from paras to bytes
	 sub	 eax,edi	; Convert to origin F000 (or E000 or ...)
	 shr	 eax,(12-2)	; Convert from bytes to 4KB in dwords

	 cmp	 ax,bx		; Is this entry 1:1 ?
	 je	 short SU_RECOVER ; Jump if so

; If R/W (case 1) then it is already recovered

	 test	 LCL_FLAG,@LCL_ALLPAGES ; Should we recover USE= pages?
	 jnz	 short SU_RECOVER ; Jump if so

	 test	 PTE_BUFFER[bx],(mask $PTE_RW) ;
	 jnz	 short SU_XRECOVER ; Jump if page Read/Write

SU_RECOVER:

	 ; Scanning Unused portion (1)

	 cmp	 dx,1		; Are we already in un-used portion?
	 jne	 short SU1	; Jump if not

	 ; Current page is unused, previous page is unused. (1,1)

	 add	 bp,4		; Increment free KB in current block

	 jmp	 short SUGGEST_LOOP ; Continue

SU1:	 ; Current page is used, previous page is unused (0,1)

	 mov	 ax,si		; Get starting address
	 lea	 di,MSG_USEQUAL1 ; Address to format to (1)
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 dx,1		; Mark as in unused area

	 jmp	 short SUGGEST_LOOP ; Continue

SU_XRECOVER:

	 ; Scanning Used portion (0)

	 cmp	 dx,1		; Are we already in un-accessed portion?
	 jne	 short SUGGEST_LOOP ; Jump if not

	 ; Current page is unused, previous page is used (1,0)

	 mov	 ax,si		; Get ending address
	 lea	 di,MSG_USEQUAL2 ; Address to format to (2)
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 al,' '         ; Initialize value with spaces
	 mov	 cx,3		; Byte count
	 lea	 di,MSG_USEQUAL3 ; Address of string
     rep stosb			; Store them

	 mov	 ax,bp		; Get freed KB count
	 lea	 di,MSG_USEQUAL4 ; Address to format to
	 mov	 cx,10		; Use base 10 for conversion
	 call	 BIN2BASE	; Format AX in base 10 ==> ES:DI

	 REGSAVE <bx,cx>	; Save registers
	 DISP_STDOUT MSG_USEQUAL ; Print USE= message
	 REGREST <cx,bx>	; Restore registers

	 xor	 dx,dx		; mark as in used area.
	 mov	 bp,4		; Start over with 4KB saved

	 jmp	 short SUGGEST_LOOP ; Continue

SUGGEST_LOOP:

	 pop	 cx		; Restore counter

	 add	 bx,4		; Point to next PTE entry
	 add	 si,4*40h	; Point to next 4K block

;;;;;;;; loop	 short SUGGEST_NEXT_PTE ; Try next PTE
	 dec	 cx		; Count in another PTE
	 jnz	 near ptr SUGGEST_NEXT_PTE ; Jump if nore PTEs to evaluate

; Print bad luck message (if appropriate)

	 cmp	 MSG_USEQUAL1,'_' ; Did we find at least one hole?
	 jne	 short SUGGEST_EXIT ; Jump if so

	 REGSAVE <bx,cx>	; Save registers
	 DISP_STDOUT MSG_NOHOLES ; Inform user of the bad news
	 REGREST <cx,bx>	; Restore registers

SUGGEST_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SUGGEST_USE	 endp			; End SUGGEST_USE procedure

;***************************************************************************

	 NPPROC  INITIALIZE -- INITIALIZE Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Initialize or un-initialize all data

1) Hook (and release) INT 42 handler
2) Set up Interrupt 5C Control Block vectors
3) Save (and Restore) INTs 1F and 43
4) Save (and Restore) INT 05h
5) Get video mode.
6) Modify (and then Restore) the printer timeout value for LPT1 to 1.
7) See if there is a mouse attached.
8) Check for EISA machine
9) Get DOS version number
10) If DOS 3.0 - 3.2, then indicate Disk buffer at F000 present
11) Get INT 13h BIOS entry point (via INT 2F function 13h call) (DOS 3.30+)
12) Determine if there is a hard drive on this system

On entry:

AL	=	0 : Initialize PROBE
AL	=	1 : Un-initialize PROBE

|

	 REGSAVE <ax,bx,dx,ds,es> ; Save registers

	 cmp	 al,1		; Un-initialize function?
	 je	 near ptr UN_INIT ; jump if so

; Intercept INT 42 for debugging

	 push	 es		; Save for a moment

	 mov	 al,42h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT 29h handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT42_VEC.VOFF,bx ; Save to restore later
	 mov	 OLDINT42_VEC.VSEG,es

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 al,42h 	; Intercept this one
	 DOSCALL @SETINT,NEWINT42 ; Install our own one


; Initialize dword pointers for NETBIOS call

	 mov	 ax,cs		; Get PGROUP
	 mov	 PNETB_CCB.VSEG,ax ; And place in Control Block
	 mov	 NETB_CCB_VEC.VSEG,ax ; And place in Control Block

; Save INTs 1F and 43h

	 push	 es		; Save for a moment

	 mov	 al,1Fh 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> pointer
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT1F_VEC.VOFF,bx ; Save to restore later
	 mov	 OLDINT1F_VEC.VSEG,es

	 mov	 al,43h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> pointer
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT43_VEC.VOFF,bx ; Save to restore later
	 mov	 OLDINT43_VEC.VSEG,es

; Save INT 10h

	 mov	 al,10h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> pointer
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT10_VEC.VOFF,bx ; Save to restore later
	 mov	 OLDINT10_VEC.VSEG,es

; Save INT 05h

	 mov	 al,05h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> pointer
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT05_VEC.VOFF,bx ; Save to restore later
	 mov	 OLDINT05_VEC.VSEG,es

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

; Get video mode

	 push	 es		; Save

	 mov	 ax,seg BIOSDATA ; Get segment of BIOS data area
	 mov	 es,ax		; ... the BIOS Data Area
	 assume es:BIOSDATA	; Tell the assembler about it

	 mov	 al,es:[CRT_MODE] ; Get the video mode
	 mov	 VIDEO_MODE,al	; Save initial video mode

	 mov	 VIDEO_SEG,@MONOSEG ; Assume monochrome mode

	 cmp	 al,07h 	; Izit monochrome mode?
	 je	 short @F	; Jump if so

	 mov	 VIDEO_SEG,@COLORSEG ; Must be color mode
@@:

; Set the printer timeout value to a respectable number

	 mov	 al,PRINT_TIM_OUT[0] ; Get timeout value
	 mov	 PRN_TIMEOUT,al ; Store it away for later

	 mov	 PRINT_TIM_OUT[0],1 ; Store new timeout value

; Look for a Mouse

	 mov	 ax,00h 	; MS Mouse installation check
	 int	 33h		; MS Mouse interface

	 cmp	 ax,-1		; Izit installed?
	 jne	 short NO_MOUSE ; Jump if not

	 mov	 ax,0024h	; Get mouse version and type function
	 int	 33h		; MS Mouse interface

	 cmp	 ax,-1		; Was there an error?
	 je	 short NO_MOUSE ; Jump if so

	 cmp	 ch,4		; Izit a PS/2 style mouse?
	 jne	 short NO_MOUSE ; Jump if not

	 or	 LCL_FLAG,@LCL_MOUSE ; We found a PS/2 style mouse
NO_MOUSE:

; Check for EISA machine

; Because some early EISA machines don't follow the spec and put their
; signature at FFD9, we must search through the entire BIOS for the string

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset PGROUP:EISA_ID ; Get offset of source string
	 push	 EISA_IDLEN	; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short @F	; Jump if not found
				; Return with DI = offset of match in ROM

	 or	 LCL_FLAG,@LCL_EISA ; Indicate EISA machine present
@@:

	 pop	 es		; Restore pointer to PGROUP
	 assume es:PGROUP

; Get DOS version number

	 DOSCALL @DOSVER	; Get DOS version number into into AX
	 xchg	 al,ah		; Switch major and minor numbers
	 mov	 DOSVER,ax	; Store for later

; If We're running on DOS 3.0-3.2, then we can't use Interrupt 2Fh,
; function 13h.  If this is the case, then we can't check for a disk
; buffer at F000-F800 and will simply have to assume that there is a
; disk buffer at F000 (we're playing it conservative here, to avoid
; trashed disks).

	 cmp	 ax,031Eh	; Compare against DOS 3.30
	 jae	 short @F	; Jump if INT 2Fh function 13h present

	 or	 LCL_FLAG,@LCL_F000BUFFER ; Assume Tandy 4000 style disk buffer

	 jmp	 short SKIP_INT2F13 ; Skip over DOS 3.30+ code
@@:

; Get INT 13h BIOS entry point (via INT 2F function 13h call)

	 REGSAVE <ds,es>	; Save registers

	 lea	 bx,LOCAL_INT13 ; Offset of temporary INT 13h handler
	 mov	 dx,bx		; ...

	 cli			; Make the unlikely interrupt window smaller

	 mov	 ah,13h 	; Swap INT 13h vector in IO.SYS
	 int	 2Fh		; DOS multiplex services
	 assume  ds:nothing, es:nothing ; Tell the assembler

	 cli			; Make the unlikely interrupt window smaller

	 assume  ds:PGROUP	; Tell a little white lie
CSOVR	 mov	 <INT13_BIOS.VSEG,ds> ; Save Interrupt 13h BIOS entry point
CSOVR	 mov	 <INT13_BIOS.VOFF,dx> ; Save Interrupt 13h BIOS entry point
	 assume  ds:nothing	; Retract nose

	 mov	 ah,13h 	; Swap INT 13h vector in IO.SYS
	 int	 2Fh		; DOS multiplex services
	 assume  ds:nothing, es:nothing ; Tell the assembler

	 REGREST <es,ds>	; Restore registers
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

SKIP_INT2F13:

; Determine if there is a hard drive on this system

	 REGSAVE <es>		; Save register

	 mov	 ax,seg BIOSDATA ; Get segment of BIOS data area
	 mov	 es,ax		; ... the BIOS Data Area
	 assume  es:BIOSDATA	; Tell the assembler about it

	 cmp	 HF_NUM,0	; Are there any fixed disks?
	 je	 short @F	; Jump if not

	 or	 LCL_FLAG,@LCL_HDISK ; Mark as hard disk being present
@@:
	 REGREST <es>		; Restore register
	 assume  es:PGROUP	; Tell the assembler about it

	 jmp	 short INITIALIZE_EXIT ; join common exit code
	 assume ds:nothing, es:nothing

;====== UN-INIT =======

	 assume ds:PGROUP, es:PGROUP
UN_INIT:

; Restore the original INT 42 handler

	 pushf			; Save for a moment

	 mov	 al,42h 	; Restore this one
	 lds	 dx,OLDINT42_VEC ; DS:DX ==> original handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Install our own one

; Restore the original INT 1F and 43 handlers

	 mov	 al,1Fh 	; Restore this one
	 lds	 dx,OLDINT1F_VEC ; DS:DX ==> original handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Install our own one

	 mov	 al,43h 	; Restore this one
	 lds	 dx,OLDINT43_VEC ; DS:DX ==> original handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Install our own one

; Restore the original INT 05h

	 mov	 al,05h 	; Restore this one
	 lds	 dx,OLDINT05_VEC ; DS:DX ==> original handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Install our own one

	 popf			; Restore

; Restore the printer timeout value

	 mov	 ax,seg BIOSDATA ; Get segment of BIOS data area
	 mov	 ds,ax		; ... the BIOS data area
	 assume ds:BIOSDATA	; Tell the assembler about it

	 mov	 al,PRN_TIMEOUT ; Get previous timeout value
	 mov	 PRINT_TIM_OUT[0],al ; And restore it to BDA

; Restore the XBDA (if we used a temporary one)

	 test	 LCL_FLAG,@LCL_XBDA ; Did we use a temp XBDA?
	 jz	 short @F	; Jump if not

	 mov	 ax,XBDA_TMP	; Get our saved value
	 mov	 XBDA_SEG,ax	; Store back in BIOS data area
@@:

INITIALIZE_EXIT:

	 REGREST <es,ds,dx,bx,ax> ; Restore registers
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INITIALIZE	 endp			; End INITIALIZE procedure

;***************************************************************************

	 NPPROC  CHECK_NDP -- Check on NDP Status
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine if there is an NDP (either a 287 or 387) in the system.
If there is, set @NRD_NDPIN, otherwise leave it clear.

Because some IBM PC/ATs and 3270/ATs without an NDP don't handle
floating-point instructions correctly, we rely upon the equipment
flags to tell us if there's an NDP installed.

This behavior is also present on some 386s. (The P70, for example)

|

	 REGSAVE <eax>		; Save register

	 xor	 eax,eax	; Zero entire register
	 int	 11h		; Get equipment flags into EAX

	 test	 ax,mask $I11_NDP ; Check NDP-installed bit
	 jz	 short CHECK_NDP_EXIT ; Jump if not installed

	 smsw	 ax		; Get machine status word

	 test	 ax,mask $ET	; Check for 287 vs. 387
	 jz	 short CHECK_NDP_FOUND ; Jump if it's a 287

; Check for EMC87 from Cyrix
; If the high-order bit of 387 control word sticks at 1,
; then an EMC87 is present

	 fninit 		; Set NDP to a known state
	 fnstcw  CTL387 	; Save control word

; Unfortunately, some systems don't handle NDP instructions well
; even without the WAIT opcode if there's no NDP installed.  Thus
; if the system board switch is mis-set, we could lockup the system
; with the FLDCW instruction if we attempt it.	Instead, we'll
; validate the value stored in CTL387 and proceed only if it looks OK.

	 mov	 ax,CTL387	; Get the control word
	 and	 ax,@CWMASK	; Isolate selected parts

	 cmp	 ax,@CWVALID	; Check for valid value
	 jne	 short CHECK_NDP_EXIT ; Join common exit code

CHECK_NDP_FOUND:
	 or	 LCL_FLAG,@LCL_NDP ; Mark as 8X87 installed

CHECK_NDP_EXIT:

	 REGREST <eax>		; Restore register

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_NDP endp			; End CHECK_NDP procedure

;***************************************************************************

	 NPPROC  SRCHSTR -- Search For A String
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search for a string.

On entry:
Parameters are pushed onto the stack.

On exit:
DI	 =	 offset of match in ROM
CF	 =	 0 if found
	 =	 1 if not

|

SRCHSTR_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
SRCHSTR_LEN1 dw  ?		; Length of string
SRCHSTR_OFF1 dw  ?		; Offset of string
SRCHSTR_LEN2 dw  ?		; Length of search area
SRCHSTR_VEC2 dd  ?		; Ptr to area to search

SRCHSTR_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,si,es>	; Save registers

	 les	 di,[bp].SRCHSTR_VEC2 ; ES:DI ==> start of search area
	 assume  es:nothing	; Tell the assembler about it

	 mov	 si,[bp].SRCHSTR_OFF1 ; DS:SI ==> source string
	 mov	 cx,[bp].SRCHSTR_LEN2 ; Get length of search area
	 sub	 cx,[bp].SRCHSTR_LEN1 ; Less length of the string
	 dec	 cx		; Less one to not fall off the end
	 mov	 al,PGROUP:[si] ; Get the first byte
SRCHSTR_NEXT:
	 jcxz	 SRCHSTR_ERR	; Jump if no more bytes to check
   repne scas	 es:[di].LO	; Search for the 1st byte
	 jne	 short SRCHSTR_ERR ; Jump if no match

	 REGSAVE <cx,di>	; Save registers
	 mov	 si,[bp].SRCHSTR_OFF1 ; DS:SI ==> source string
	 inc	 si		; Plus one to account for the first match
	 mov	 cx,[bp].SRCHSTR_LEN1 ; Get length of the string
	 dec	 cx		; Less one to account for the first match
    repe cmps	 PGROUP:[si].LO,es:[di].LO ; Check the rest
	 REGREST <di,cx>	; Restore
	 jne	 short SRCHSTR_NEXT ; Jump if no match

	 dec	 di		; Back off to start of match

	 clc			; Mark as found

	 jmp	 short SRCHSTR_EXIT ; Join common exit code

SRCHSTR_ERR:
	 stc			; Mark as not found
SRCHSTR_EXIT:
	 REGREST <es,si,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2+2+4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCHSTR  endp			; End SRCHSTR procedure

;***************************************************************************

	 NPPROC  SRCHSTRI -- Search For A String
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search for a string.

On entry:
Parameters are pushed onto the stack.

On exit:
DI	 =	 offset of match in ROM
CF	 =	 0 if found
	 =	 1 if not

|

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,si,es>	; Save registers

	 les	 di,[bp].SRCHSTR_VEC2 ; ES:DI ==> start of search area
	 assume  es:nothing	; Tell the assembler about it

	 mov	 si,[bp].SRCHSTR_OFF1 ; PGROUP:SI ==> source string
	 mov	 cx,[bp].SRCHSTR_LEN2 ; Get length of search area
	 sub	 cx,[bp].SRCHSTR_LEN1 ; Less length of the string
	 dec	 cx		; Less one to not fall off the end
SRCHSTRI_NEXT:
	 mov	 al,PGROUP:[si] ; Get the first byte
	 jcxz	 SRCHSTRI_ERR	; Jump if no more bytes to check
   repne scas	 es:[di].LO	; Search for the 1st byte
	 jne	 short SRCHSTRI_ERR ; Jump if no match

	 REGSAVE <cx,si,di>	; Save registers
	 inc	 si		; Plus one to account for the first match
	 mov	 cx,[bp].SRCHSTR_LEN1 ; Get length of the string
	 dec	 cx		; Less one to account for the first match

SRCHSTRI_NEXT_CHAR:
    repe cmps	 PGROUP:[si].LO,ES:[di].LO ; Compare bytes till mismatch
	 je	 short SRCHSTRI_LOOP ; Jump if entire string matched (ZF=1)

	 cmp	 PGROUP:[si-1].LO,-1 ; Izit a don't-care byte?
	 je	 short SRCHSTRI_NEXT_CHAR ; Jump if so (continue cmpsb)
				; Jump with ZF=1 (in case CX=0)
				; Fall through with ZF=0

SRCHSTRI_LOOP:
	 REGREST <di,si,cx>	; Restore registers
	 jne	 short SRCHSTRI_NEXT ; Jump if no match (scan for next match)

	 dec	 di		; Back off to start of match

	 clc			; Mark as found

	 jmp	 short SRCHSTRI_EXIT ; Join common exit code

SRCHSTRI_ERR:
	 stc			; Mark as not found
SRCHSTRI_EXIT:
	 REGREST <es,si,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2+2+4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCHSTRI  endp			; End SRCHSTRI procedure

;***************************************************************************

	 FPPROC  NEWINT17 -- INT 17 handler for faster PRTSCR's
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Since we test the INT 17 code, we don't have to
exercise it again during PRTSCR.

So, we use this INT17 handler during PRTSCR testing.

[FIXME] - Verify return codes are correct.

|

	 REGSAVE <>		; Save registers
	 pushf			; Save flags accross interrupt

	 cmp	 ah,00		; Output character?
	 je	 short INT17_00 ; Jump if so

	 cmp	 ah,01h 	; Initialize?
	 je	 short INT17_01 ; Jump if so

	 cmp	 ah,02h 	; Get status?
	 je	 short INT17_02 ; Jump if so

	 popf			;Restore flags
	 jmp	 OLDINT17_VEC	; Try real INT 17 handler

INT17_00:
	 mov	 ah,90h 	; Return OK status code
	 jmp	 short INT17_EXIT ; Join common exit code

INT17_01:
	 mov	 ah,90h 	; Return OK status code
	 jmp	 short INT17_EXIT ; Join common exit code

INT17_02:
	 mov	 ah,90h 	; Return OK status code
	 jmp	 short INT17_EXIT ; Join common exit code

INT17_EXIT:

	 popf			; Restore flags
	 REGREST <>		; Restore

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NEWINT17	 endp			; End NEWINT17 procedure

;***************************************************************************

	 NPPROC  NEWINT0A -- INT 0A handler for debugging
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT|

This is the temporary INT 0A handler used during INT 71 testing.

We do this because the real owner of INT 0A would get confused by
INT 71 calling it w/o a pending hardware interrupt.  This usually
ends in a lock-up.

|

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NEWINT0A	 endp			; End NEWINT0A procedure

;***************************************************************************

	 FPPROC  LOCAL_INT10 -- Local INT 10h handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 10h handler to catch fatal errors being written to the screen
during testing of Interrupt 06 and Interrupt 0D

If we do see a BIOS trying to display a fatal error message, we will
simply return to the caller (ROMSRCH, that is).

|

; Determine if we should be trapping this function call

	 cmp	 ah,@SETCHR	; Is it 'Set char' function?
	 je	 short LCLI10_TRAP ; Jump if so

	 cmp	 ah,@SETCAT	; Is it 'Set char/attr' function?
	 je	 short LCLI10_TRAP ; Jump if so

	 cmp	 ah,@SETTTY	; Is it 'Write TTY' function?
	 je	 short LCLI10_TRAP ; Jump if so

	 cmp	 ah,@SETSTR	; Is it 'Write String' function?
	 je	 short LCLI10_TRAP ; Jump if so

	 jmp	 OLDINT10_VEC	; Chain to original handler

; We have found a function that is writing to the screen
; Return to ROMSRCH before the caller terminates us

LCLI10_TRAP:

	 lss	 sp,SAVED_STACK ; Restore SS and SP from 'good' values
	 assume  ss:nothing	; Tell the assembler about it

	 mov	 al,PORT21_TEMP ; Get saved port 21 value
	 out	 021h,al	; ... and send to PIC

	 test	 LCL_FLAG,@LCL_XTCLASS ; Izit an XT class machine?
	 jnz	 short @F	; Jump if so (no secondary PIC)

	 mov	 al,PORTA1_TEMP ; Get saved port A1 value
	 out	 0A1h,al	; ... and send to slave PIC
@@:

	 jmp	 FATAL_ERR_RETURN ; Jump back to ROMSRCH's control

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOCAL_INT10 endp		; End LOCAL_INT10 procedure

;***************************************************************************

	 FPPROC  LOCAL_INT13 -- Local INT 13h handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 13h handler while we diddle with INT 2F func 13h

|

LI13_STR struc			; Structure to access IRET frame

LI13_BP  dw	 ?		; Caller's BP
LI13_IP  dw	 ?		; ...	   IP
LI13_CS  dw	 ?		; ...	   CS
LI13_FL  dw	 ?		; ...	   flags

LI13_STR ends			; End LI13_STR structure

	 push	 bp		; Save previous stack frame
	 mov	 bp,sp		; Access our local stack frame

	 or	 [bp].LI13_FL,(mask $CF) ; Set carry flag in IRET frame

	 pop	 bp		; Restore previous stack frame

	 mov	 ah,80h 	; Time-out error indicator

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOCAL_INT13 endp		; End LOCAL_INT13 procedure

;***************************************************************************

	 NPPROC  NEWINT42 -- INT 42 handler for debugging
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Int 42 is the system board video handler if a EGA (or above) is present.
We issue an out-of-range video interrupt request to recover the system
board video handler because many programs also make these bogus requests.
If the /v command line option is present, this handler will be hooked in,
causing us to recover the system board video handler.  This is not
recomended because there is software that makes these calls.  Two examples
of programs that make these calls are TALLSCRN and Norton's SI.

Note: Loading an interrupt 42 handler that does an IRET would get around
this problem.

|

	 REGSAVE <>		; Save registers

	 test	 CMD_FLAG,@CMD_DEBUG42 ; trap int 42?
	 jz	 short @F	; Jump if not

	 int	 01h		; #################
@@:
	 jmp	 OLDINT42_VEC	; Jump to System INT 42 handler now

	 REGREST <>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NEWINT42	 endp			; End NEWINT42 procedure

;***************************************************************************

	 NPPROC  CHECK_F000BUFFER -- Check for F000-F800 disk buffer
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If the system has a Tandy 4000 style disk buffer,
then access F000-F800 to be sure these pages are not recovered.

|

	 REGSAVE <ax,cx,si,es>	; Save registers

	 test	 LCL_FLAG,@LCL_F000BUFFER ; Izit present?
	 jz	 short CHECK_F000BUFFER_EXIT ; Jump if not

	 push	 0F000h 	; Address the System BIOS
	 pop	 es		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,8		; # of pages to touch
	 xor	 si,si		; Start at Offset 0 in BIOS
@@:
	 mov	 al,es:[si]	; Get one byte from page to set accessed bit
	 add	 si,1000h	; Bump up to next page

	 loop	 short @B	; Access next page

CHECK_F000BUFFER_EXIT:

	 REGREST <es,si,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_F000BUFFER endp		; End CHECK_F000BUFFER procedure

;***************************************************************************

	 NPPROC  SAVE_VIDEO -- SAVE_VIDEO Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Save all video parameters for later restoration.

Note: This routine must be executed after PATCH_INTS because
      PATCH_INTS contains the check for buggy function 1C code.

|

	 pusha			; Save all GP registers (thanks to AHEAD bug)

; Save the Row size

	 REGSAVE <es>		; Save register

	 mov	 ax,seg BIOSDATA ; Address the BDA
	 mov	 es,ax		; ... via es
	 assume  es:BIOSDATA	; tell the assembler about it

	 mov	 al,EGA_ROWS	; Get number of rows
	 mov	 VID_ROWS,al	; ... and save for later

	 REGREST <es>		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 test	 LCL_FLAG,@LCL_SKIP1C ; Should we skip function 1C
	 jnz	 short SAVE_VIDEO_EXIT ; Jump if so

; Ask the video BIOS for the bufer size needed for screen save

	 REGSAVE <es>		; Save temporarily (thanks to AHEAD bug)

	 mov	 ax,1C00h	; Return State Buffer Size function
	 mov	 cx,(@BIT0 or @BIT1 or @BIT2) ; Requested States (all 3)
	 int	 10h		; Video interrupt
				; Returns AL = success code
				;	  BX = buffer size
				; Note: AHEAD trashes CX,DX,SI,DI,BP,ES
	 assume  es:nothing	; Tell the assembler about it

	 REGREST <es>		; Retore segment register (to avoid AHEAD bug)
	 assume  es:PGROUP	; Tell the assembler about it

	 cmp	 al,1Ch 	; Success?
	 jne	 short SAVE_VIDEO_EXIT ; Jump if not

	 cmp	 bx,@VID_SAVE_PARA ; Enough room?
	 ja	 short SAVE_VIDEO_EXIT ; Jump if not enough room

; Save the video information

	 REGSAVE <es>		; Save segment register

	 mov	 ax,1C01h	; Save State Buffer function
	 lea	 bx,VIDEO_SAVE_AREA ; Offset of our storage area
	 mov	 cx,(@BIT0 or @BIT1 or @BIT2) ; Requested States (all 3)
	 int	 10h		; Save to ES:BX
				; Returns AL = success code
	 assume  es:nothing	; Tell the assembler about it

	 REGREST <es>		; Restore segment register
	 assume  es:PGROUP	; Tell the assembler about it

	 cmp	 al,1Ch 	; Success?
	 jne	 short SAVE_VIDEO_EXIT ; Jump if not

COMMENT|

The documentation (IBM BIOS Interface Technical Reference) says that
the video state is altered by the save state function.	To maintain
the current video state, we should restore the video information.

By doing so, we overcome a problem encountered with the Diamond Viper
card where if we don't make this call, the video is in a disabled
(screen blank, no cursor) state.

|

	 REGSAVE <es>		; Save segment register

	 mov	 ax,1C02h	; Restore State Buffer function
	 lea	 bx,VIDEO_SAVE_AREA ; Offset of our storage area
	 mov	 cx,(@BIT0 or @BIT1 or @BIT2) ; Requested States (all 3)
	 int	 10h		; Save to ES:BX
				; Returns AL = success code
	 assume  es:nothing	; Tell the assembler about it

	 REGREST <es>		; Restore segment register
	 assume  es:PGROUP	; Tell the assembler about it

	 or	 LCL_FLAG,@LCL_VIDSAVE ; Video area has been saved

SAVE_VIDEO_EXIT:
	 popa			; Restore GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_VIDEO	 endp		; End SAVE_VIDEO procedure

;***************************************************************************

	 NPPROC  REST_VIDEO -- REST_VIDEO Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Restore all video parameters from their saved state.

Note: We have to restore via function 1C before we restore the fonts.
      This is because some VGA boards (IBM's XGA comes to mind) reset
      the font to 25 lines with a 1C restore call.

|

	 pusha			; Save all GP registers

	 test	 LCL_FLAG,@LCL_VIDSAVE ; Restore the video area?
	 jz	 short REST_VIDEO_FONT	; Jump if not

	 test	 LCL_FLAG,@LCL_SKIP1C ; Should we skip function 1C
	 jnz	 short REST_VIDEO_FONT ; Jump if so

; Restore all variables from video state buffer

	 REGSAVE <es>		; Save segment register

	 mov	 ax,1C02h	; Restore State Buffer function
	 lea	 bx,VIDEO_SAVE_AREA ; Offset of our storage area
	 mov	 cx,(@BIT0 or @BIT1 or @BIT2) ; Requested States (all 3)
	 int	 10h		; Restore from ES:BX
				; Returns AL = success code
	 assume  es:nothing	; Tell the assembler about it

	 REGREST <es>		; Restore segment register
	 assume  es:PGROUP	; Tell the assembler about it

;;;;;;;; cmp	 al,1Ch 	; Success?
;;;;;;;; jne	 short REST_VIDEO_EXIT ; Jump if not

REST_VIDEO_FONT:

	 mov	 al,VID_ROWS	; Get previous row count

; Restore video Row count

	 cmp	 al,18h 	; Was it 25 row mode?
	 je	 short REST_VIDEO_CONT ; Join common code

	 cmp	 al,2Ah 	; Was it 43 row mode?
	 jne	 short NOT_43	; Jump if not

; Restore 43 line mode

	 mov	 ax,1112h	; Use ROM double dot font
	 mov	 bl,0		; Use block 0
	 int	 10h		; Set new font

	 jmp	 short REST_VIDEO_CONT ; Join common code

NOT_43:
	 cmp	 al,31h 	; Was it 50 line mode?
	 jne	 short REST_VIDEO_CONT ; Join common code

; Restore 50 line mode

	 mov	 ax,1112h	; Use ROM double dot font
	 mov	 bl,0		; Use block 0
	 int	 10h		; Set new font

REST_VIDEO_CONT:

REST_VIDEO_EXIT:
	 popa			; Restore GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_VIDEO	 endp		; End REST_VIDEO procedure

;***************************************************************************

	 NPPROC  IZIT_VGA -- Check For Presence of VGA
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return AX = -1 if VGA not present
	  =  1 if present and in mono mode
	  =  2		      in enhanced color mode

|

	 REGSAVE <bx>		; Save register

	 mov	 al,00h 	; Subfunction to get DCC
	 VIDCALL @GSTDCC	; Get display combination code
				; Return with
				; AL = 1Ah means function supported
				; BL = Active display DCC
				; BH = Alternate ...

	 cmp	 al,@GSTDCC	; Izit supported?
	 jne	 short IZITVGA_XPRES ; Jump if not

	 or	 LCL_FLAG,@LCL_VGAPRES ; Indicate VGA is present

	 mov	 ax,01h 	; Assume monochrome

	 cmp	 bl,07h 	; Izit active analog mono?
	 je	 short IZITVGA_EXIT ; Yes, use code in AX

	 cmp	 bh,07h 	; Izit alternate ...
	 je	 short IZITVGA_EXIT ; Yes, use code in AX

	 mov	 ax,02h 	; Assume enhanced color

	 cmp	 bl,08h 	; Izit active analog color?
	 je	 short IZITVGA_EXIT ; Yes, use code in AX

	 cmp	 bh,08h 	; Izit alternate ...
	 je	 short IZITVGA_EXIT ; Yes, use code in AX
IZITVGA_XPRES:
	 mov	 ax,-1		; Mark as not present
IZITVGA_EXIT:
	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_VGA  endp			; End IZIT_VGA procedure

;***************************************************************************

	 NPPROC  IZIT_VESA -- IZIT_VESA Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Check for VESA BIOS
We can't make Mode switch to VESA mode unless VESA is present

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save segment registers

	 mov	 ax,4F00h	; Get VESA info function
	 lea	 di,ZTAIL	; 64 byte buffer to hold VESA info
	 mov	 es:[di].EDD,0	; Initialize to avoid false positive
	 int	 10h		; Get VESA info (if available)

	 cmp	 al,4Fh 	; Successful?
	 jne	 short IZIT_VESA_EXIT ; Jump if not

	 cmp	 es:[di].EDD,'ASEV' ; Izit expected signature?
	 jne	 short IZIT_VESA_EXIT ; Jump if not

	 or	 LCL_FLAG,@LCL_VESA ; Indicate a VESA is present

IZIT_VESA_EXIT:
	 REGREST <es,ds>	; Restore segment registers
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_VESA	 endp			; End IZIT_VESA procedure

;***************************************************************************

	NPPROC	IZIT_PnP -- Determine Plug 'n Play Availability
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine Plug 'n Play availability

If this is a PnP BIOS, somewhere in the BIOS on a para boundary
is the PnP structure with a matching checksum.

|

	REGSAVE <ax,cx,si,ds>	; Save registers

	mov	cx,SYSROM_START ; Segment of start of ROM (paras)
	mov	ds,cx		; Address it
	assume	ds:nothing	; Tell the assembler about it

	neg	cx		; Get length of BIOS in paras
	xor	si,si		; Initialize index into BIOS
@@:
	cmp	ds:[si].EDD,@PnP_SIGREV ; Duzit have the right signature?
	je	short IZIT_PnP_SUM ; Jump if so
IZIT_PnP_SKIP:
	add	si,16		; Skip to next para

	loop	@B		; Jump if more paras to check

	jmp	short IZIT_PnP_EXIT ; Join common exit code

IZIT_PnP_SUM:

; Validate the checksum

	REGSAVE <cx,si> 	; Save for a moment

	movzx	cx,ds:[si].PnP_LEN ; Get the structure's byte length
	mov	ah,0		; Initialize the checksum accumulator
@@:
	lods	ds:[si].LO	; Get the next byte
	add	ah,al		; Add into accumulator
	loop	@B		; Jump if more bytes to checksum

	REGREST <si,cx> 	; Restore

	cmp	ah,0		; Duzit match?
	jne	short IZIT_PnP_SKIP ; Jump if not

; Ensure it's a version 1.0 struc

	cmp	ds:[si].PnP_VER,10h ; Izit version 1.0?
	jne	short IZIT_PnP_SKIP ; Jump if not

; Ensure it's one of the two type strucs we support

	cmp	ds:[si].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F	; Jump if so

	cmp	ds:[si].PnP_LEN,size PnP2_STR ; Izit old struc?
	jne	short IZIT_PnP_SKIP ; Jump if not
@@:
	or	LCL_FLAG,@LCL_PnP ; Mark as present

	mov	ax,ds		; Copy the segment
	shr	si,4-0		; Convert from bytes to paras
	add	ax,si		; Add to get the segment
	mov	PnP_SEG,ax	; Save for later use
IZIT_PnP_EXIT:
	REGREST <ds,si,cx,ax>	; Restore
	assume	ds:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_PnP endp			; End IZIT_PnP procedure

;***************************************************************************

	 NPPROC  SIMULATE_XBDA -- SIMULATE_XBDA Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT|

If there is no XBDA, create one

1) Check INT 15, function C0 - First check
2) Check other means	     - Second check

On exit:
XBDA_SEG =	Segment of XBDA

|

	 REGSAVE <ax,bx,di,es,fs> ; Save registers

; Get XBIOS segment (via BIOS call)

	 mov	 ah,0C0h	; Return System Configuration function
	 int	 15h		; System services (returns in ES:BX)
	 assume  es:nothing	; Tell the assembler
	 jc	 short @F	; Jump if error

	 cmp	 ah,86h 	; Error?
	 je	 short @F	; Jump if error

	 test	 es:[bx+5].LO,@BIT2 ; Is XBIOS allocated?
	 jz	 short @F	; Jump if not

	 mov	 ah,0C1h	; Return XBDA address (in ES)
	 int	 15h		; System service
	 assume  es:nothing	; Tell the assembler
	 jc	 short @F	; Jump if error

	 cmp	 ah,86h 	; Error?
	 je	 short @F	; Jump if error

	 mov	 XBIOS_SEG,es	; Save segment of XBDA,
				; as reported by the BIOS

	 jmp	 near ptr SIM_XBDA_EXIT ; Continue on

COMMENT |

BIOS says that there isn't an XBDA.  Since some BIOSes may be incorrect,
try to determine if there is an XBDA by other means.

There are  5 possible scenarios...

MAX	XBIOS		MAX Keyword	XBDA Keyword	XBDA Presence Test
---	-----		-----------	------------	------------------
Low	Low		NOLOADHI	default 	LSEG
Low	Middle		NOLOADHI	NOXBIOS 	INT12
High	Low		default 	default 	DOS 4 pseudo-MAC
High	Middle		default 	NOXBIOS 	INT12
High	High		default 	XBIOSHIGH	MAC

Note: If the BIOS tells us that the XBDA does not exist, but it really
      does exist, and it is within the low memory portion of MAX, and
      MAX is loaded in the high memory portion, and we are running
      under DOS 3.X, we will not see the XBDA and create our own XBDA.
      This is because we can not detect the length of our low memory
      portion without either an LSEG entry or DOS 4's MAC entry.

|

@@:
	 mov	 ax,seg BIOSDATA ; Prepare to address ...
	 mov	 es,ax		; ... the BIOS Data Area
	 assume  es:BIOSDATA	; Tell the assembler about it

; Does the user want us to assume the XBDA is present?

	 mov	 bx,XBDA_SEG	; Get alleged XBDA segment (LPT4 base)

	 test	 LCL_FLAG,@LCL_XBDA_PRES ; Are we to assume XBDA is present?
	 jnz	 near ptr SIM_XBDA_PRES ; Jump if so (XBDA seg in BX)

; Check for XBDA at top of DOS memory

	 mov	 bx,MEMORY_SIZE ; Get current memory size
	 shl	 bx,10-4	; Convert from 1KB to paras

	 cmp	 bx,XBDA_SEG	; Get alleged XBDA segment (LPT4 base)
	 je	 near ptr SIM_XBDA_PRES ; Jump if XBDA is in Middle memory
				; XBDA segment in BX

; Check for XBDA below our low memory portion

	 mov	 ax,MAXLO_SEG	; Get Low memory segment of MAX
	 mov	 bx,XBDA_SEG	; Get alleged XBDA segment

	 cmp	 bx,ax		; Is the XBDA below the low memory portion?
	 jb	 SIM_XBDA_XPRES ; Jump, there is no XBDA present

; Get the length of our low memory portion

	 mov	 fs,MAX_LSEG	; Get MAX's LSEG entry
	 assume  fs:nothing	; Tell the assembler about it

	 cmp	 MAX_LSEG,0A000h ; Is the LSEG in high memory?
	 ja	 short LSEG_HI	; Jump if so

	 add	 ax,fs:[LSEG_RPARA] ; Add length of Low DOS portion
	 jmp	 short LSEG_LO	; Jump to check high end of Low DOS size

LSEG_HI:

	 cmp	 DOSVER.HI,4	; Izit DOS 4 or above?
	 jb	 short LSEG_HI_DOS3 ; If not, skip MAC method and
				; ... use fixed constant for low memory length

	 dec	 ax		; Back up to MAC entry of low memory segment

	 mov	 fs,ax		; Address the pseudo MAC entry
	 assume  fs:nothing	; Tell the assembler about it

	 inc	 ax		; Return to MAX's start

	 cmp	 fs:[MAC_TYPE],44h ; Izit the pseudo MAC entry?
	 jne	 short SIM_XBDA_HIGH ; If not, check for XBDA in High DOS

	 add	 ax,fs:[MAC_NPAR] ; Add in MAX's low memory length

	 jmp	 short LSEG_LO	; Check for XBDA in low memory portion

LSEG_HI_DOS3:

;;;;;;;; add	 ax,@MAX_LOW_SIZE ; Add length in paras to low memory start
	 add	 ax,(80/16)+1	; Add size of low memory portion (in paras)
				; Include para for alleged XBDA

	 test	 LCL_FLAG,@LCL_NOWIN3 ; Are we running with NOWIN3?
	 jnz	 short @F	; Jump if so

;;;;;;;; add	 ax,@MAX_WIN3_SIZE	; Add size of WIN3 stub
	 add	 ax,((1040-80)/16)	; Add size of WIN3 stub (in paras)
@@:

; Check for XBDA within our low memory portion

LSEG_LO:

	 cmp	 bx,ax		; Is the XBDA above the low memory portion?
	 jb	 short SIM_XBDA_PRES ; Jump, the XBDA exists
				; XBDA segment is in BX

; Check for the existance of an upper memory portion of MAX

SIM_XBDA_HIGH:
	 mov	 ax,MAXLO_SEG	; Get Low memory segment of MAX
	 mov	 fs,ax		; ...
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 di,fs:[DD_INTR] ; Get address of alleged FAR JUMP

	 cmp	 fs:[di].LO,@OPCOD_JMPF ; Izit a FAR JUMP?
	 jne	 short SIM_XBDA_XPRES ; Jump, we can't find High DOS portion

	 cmp	 fs:[di+3],ax	; Is the jump pointing to LOW DOS?
	 je	 short SIM_XBDA_XPRES ; Jump, there is no High DOS portion

	 mov	 ax,fs:[di+3]	; Address the upper memory portion of MAX

	 dec	 ax		; Back up to the MAC entry

	 mov	 fs,ax		; Address the high DOS MAC entry
	 assume  fs:nothing	; Tell the assembler about it

	 cmp	 fs:[MAC_TYPE],@MAC_MID ; Izit a valid entry?
	 je	 short @F	; Jump if so

	 cmp	 fs:[MAC_TYPE],@MAC_END ; Izit the other valid entry?
	 jne	 short SIM_XBDA_XPRES	; XBDA is not present

; Check for XBDA below our upper memory portion

@@:
	 cmp	 bx,ax		; Is the XBDA below the high memory portion?
	 jb	 SIM_XBDA_XPRES ; Jump, there is no XBDA present

	 add	 ax,fs:[MAC_NPAR] ; Add in MAX's high memory length

; Check for XBDA within our upper memory portion

	 cmp	 bx,ax		; Is the XBDA above the high memory portion?
	 jb	 SIM_XBDA_PRES	; Jump, the XBDA exists
				; XBDA segment in BX

; There really is no XBDA, so we can create one here

SIM_XBDA_XPRES:

	 lea	 ax,XBDA	; Offset of temp XBDA (para aligned)
	 shr	 ax,(4-0)	; Convert from bytes to paras
	 mov	 bx,cs		; Add para of our program
	 add	 ax,bx		; Get para of XBDA

	 mov	 XBIOS_SEG,ax	; Save segment of XBDA

	 xchg	 ax,XBDA_SEG	; Switch with BIOS value
	 mov	 XBDA_TMP,ax	; Store for later restoration

	 or	 LCL_FLAG,@LCL_XBDA ; Indicate as using temp XBDA

	 jmp	 short SIM_XBDA_EXIT ; Join common exit code

SIM_XBDA_PRES:
	 mov	 XBIOS_SEG,bx	; Save segment of XBDA

SIM_XBDA_EXIT:
	 REGREST <fs,es,di,bx,ax> ; Restore
	 assume  es:PGROUP,fs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SIMULATE_XBDA	 endp		; End SIMULATE_XBDA procedure

;************************************************************************

	  NPPROC  FMT_BYTE -- Format AL to Hex at ES:DI
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	  REGSAVE <ax,bx,cx,dx>  ; Save registers

	  lea	  bx,HEXTABLE	 ; DS:BX ==> translate table
	  mov	  cx,2		 ; # hex digits in a word
	  mov	  dx,ax 	 ; Copy to test
FMT_BYTE1:
	  rol	  dl,4		 ; Copy the high-order digit
	  mov	  al,dl 	 ; Copy to XLAT register
	  and	  al,0Fh	 ; Isolate hex digit
	  xlat	  HEXTABLE	 ; Translate to ASCII
S16	  stosb 		 ; Save into output area

	  loop	  FMT_BYTE1	 ; Jump if more digits to convert

	  REGREST <dx,cx,bx,ax>  ; Restore

	  ret			 ; Return to caller

	  assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_BYTE endp			 ; End FMT_BYTE procedure


;*****************************************************************************

	  NPPROC  FMT_WORD -- Format AX to Hex at ES:DI
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	  REGSAVE <ax,bx,cx,dx>  ; Save registers

	  lea	  bx,HEXTABLE	 ; DS:BX ==> translate table
	  mov	  cx,4		 ; # hex digits in a word
	  mov	  dx,ax 	 ; Copy to test
FMT_WORD1:
	  rol	  dx,4		 ; Copy the high-order digit
	  mov	  al,dl 	 ; Copy to XLAT register
	  and	  al,0Fh	 ; Isolate hex digit
	  xlat	  HEXTABLE	 ; Translate to ASCII
S16	  stosb 		 ; Save into output area

	  loop	  FMT_WORD1	 ; Jump if more digits to convert

	  REGREST <dx,cx,bx,ax>  ; Restore

	  ret			 ; Return to caller

	  assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_WORD endp			 ; End FMT_WORD procedure


;*****************************************************************************

	  NPPROC  FMT_DWORD -- Format AX to Hex at ES:DI
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	  REGSAVE <ax,bx,cx,edx>  ; Save registers

	  lea	  bx,HEXTABLE	 ; DS:BX ==> translate table
	  mov	  cx,8		 ; # hex digits in a word
	  mov	  edx,eax	 ; Copy to test
FMT_DWORD1:
	  rol	  edx,4 	 ; Copy the high-order digit
	  mov	  al,dl 	 ; Copy to XLAT register
	  and	  al,0Fh	 ; Isolate hex digit
	  xlat	  HEXTABLE	 ; Translate to ASCII
S16	  stosb 		 ; Save into output area

	  loop	  FMT_DWORD1	 ; Jump if more digits to convert

	  REGREST <edx,cx,bx,ax>  ; Restore

	  ret			 ; Return to caller

	  assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_DWORD endp			 ; End FMT_WORD procedure

;***************************************************************************

	 NPPROC  BIN2BASE -- Convert From Binary to Specified Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIN2BASE -- Convert the number in AX to ASCII in base CX storing the
low-order digit of the # at ES:DI.

On exit:

ES:DI	 ==>	 next byte to left of the number

|

	 REGSAVE <ax,bx,cx,dx,si,bp,ds,es> ; Save all registers

	 push	 cs		; Set for MOVSB below
	 pop	 ds		; Now DS addresses NUMBERS_HI
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Set for DI
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB

	 mov	 bp,8		; Go through this many times
BIN2BASE_LOOP:
	 xor	 dx,dx		; Zero high-order word for division
	 div	 cx		; Divide by number base
				; DX has remainder, AX has quotient
	 lea	 si,NUMBERS_HI	; Get address of table
	 add	 si,dx		; Offset into table

S16	 movsb			; Store in result

	 and	 ax,ax		; Check for zero quotient
	 jz	 short BIN2BASE_EXIT ; That's all folks

	 dec	 bp		; Check for last digit
	 jnz	 short BIN2BASE_LOOP ; Not done yet
BIN2BASE_EXIT:
	 popf			; Restore flags

	 REGREST <es,ds,bp,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2BASE endp			; End BIN2BASE procedure

;***************************************************************************

	 NPPROC  HEX2BIN -- Hex to Binary Converter
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Hex to binary converter

On entry:

DS:SI	 ==>	 ASCII text to convert

On exit:

AX	 =	 binary value
DS:SI	 ==>	 (updated)

|

	 REGSAVE <cx,dx,di>	; Save registers

	 xor	 dx,dx		; Initialize accumulator
HEX2BIN_NEXT:
	 lodsb			; Get next ASCII value
	 call	 UPPERCASE	; Convert to uppercase

	 lea	 di,NUMBERS_HI	; ES:DI ==> uppercase hex digits
	 mov	 cx,16		; Length of ...
   repne scasb			; Search for it
	 jne	 short HEX2BIN_EXIT ; Jump if not hex

	 sub	 di,1+offset PGROUP:NUMBERS_HI ; Convert to origin-0
	 mov	 cl,4-0 	; Shift amount for one hex digit
	 shl	 dx,cl		; Shift over one hex digit
	 or	 dx,di		; Include new digit

	 jmp	 short HEX2BIN_NEXT ; Go around again

HEX2BIN_EXIT:
	 dec	 si		; Back off to last character
	 mov	 ax,dx		; Copy to result register

	 REGREST <di,dx,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

HEX2BIN  endp			; End HEX2BIN procedure

;*************************************************************************

	 NPPROC  LOWERCASE -- Convert To Lowercase
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert to lwoercase

On entry:

AL	 =	 character to convert

On exit:

AL	 =	 converted character

|

	 cmp	 al,'A'         ; Izit below lower limit?
	 jb	 short LOWERCASE_EXIT ; Jump if so

	 cmp	 al,'Z'         ; Izit above uppper limit?
	 ja	 short LOWERCASE_EXIT ; Jump if so

	 add	 al,'a'-'A'     ; Convert to lowercase
LOWERCASE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure

;*************************************************************************

	 NPPROC  UPPERCASE -- Convert to Uppercase
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert to uppercase

On entry:

AL	 =	 ASCII value

On exit:

AL	 =	 uppercase version of input

|

	 cmp	 al,'a'         ; Check against lower limit
	 jb	 short UPPERCASE_EXIT ; Jump if too small

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short UPPERCASE_EXIT ; Jump if too large

	 add	 al,'A'-'a'     ; Convert to uppercase
UPPERCASE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

UPPERCASE endp			; End UPPERCASE procedure

;*****************************************************************************

	 NPPROC BEEP_HIGH -- Beeps the speaker
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

@SPEAKER_PORT  equ  061h	; Address of the speaker port
@SPEAKER_OFF   equ  0FCh	; Mask to turn speaker off
@SPEAKER_ON    equ  02h 	; Mask to turn speaker on
@TONE_DURATION equ  040h	; Length of tone

	 REGSAVE <ax,bx,cx>		; Save registers
	 pushf				; Save flags

; Get contents of port and initially mask off

	 in	 al,@SPEAKER_PORT	; Get contents of port
	 mov	 bl,@SPEAKER_OFF	; Get speaker off mask
	 and	 al,bl			; Mask off speaker bits

	 mov	 cx,@TONE_DURATION ; Loop for tone duration

NOISE_ON:
	 push	 cx			; Save speaker duration count
	 or	 al,@SPEAKER_ON 	; Mask the speaker on
	 out	 @SPEAKER_PORT,al	; Turn the speaker on

	 mov	 cx,0ffh		; Delay before turning speaker off

TIME_1:  loop	 TIME_1

NOISE_OFF:
	 and	 al, @SPEAKER_OFF	; Mask the speaker off
	 out	 @SPEAKER_PORT,al	; Turn the speaker off

	 mov	 cx,0ffh		; Delay before turning speaker on
TIME_2:  loop	 TIME_2

	 pop	 cx			; Get duration count
	 loop	 NOISE_ON		; else, do it again

; Delay and do nothing (silence)

	 mov	 cx, @BEEP_DELAY	; Outer loop counter
TIME_3:  push	 cx			; Save outer loop counter
	 mov	 cx, 0fffeh		; Inner loop counter
TIME_4:  loop	 TIME_4 		; Do nothing loop
	 pop	 cx			; Restore outer loop counter
	 loop	 TIME_3 		; Loop again...

RT_BEEP_EXIT:
	 popf				; Restore flags
	 REGREST <cx,bx,ax>		; Restore registers

	 ret
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
BEEP_HIGH  endp

;*****************************************************************************

	 NPPROC BEEP_LOW -- Beeps the speaker
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

@SPEAKER_PORT  equ  061h	; Address of the speaker port
@SPEAKER_OFF   equ  0FCh	; Mask to turn speaker off
@SPEAKER_ON    equ  02h 	; Mask to turn speaker on
@TONE_DURATION equ  040h	; Length of tone

	 REGSAVE <ax,bx,cx>
	 pushf

; Get contents of port and initially mask off

	 in	 al,@SPEAKER_PORT	; Get contents of port
	 mov	 bl,@SPEAKER_OFF	; Get speaker off mask
	 and	 al,bl			; Mask off speaker bits

	 mov	 cx,@TONE_DURATION	; Loop for tone duration

LNOISE_ON:
	 push	 cx			; Save speaker duration count
	 or	 al, @SPEAKER_ON	; Mask the speaker on
	 out	 @SPEAKER_PORT,al	; Turn the speaker on

	 mov	 cx,03ffh		; Delay before turning speaker off
LTIME_1: loop	 LTIME_1

LNOISE_OFF:
	 and	 al,@SPEAKER_OFF	; Mask the speaker off
	 out	 @SPEAKER_PORT,al	; Turn the speaker off

	 mov	 cx,03ffh		; Delay before turning speaker on
LTIME_2: loop	 LTIME_2

	 pop	 cx			; Get duration count
	 loop	 LNOISE_ON		; else, do it again


;Delay and do nothing (silence)
	 mov	 cx, @BEEP_DELAY	; Outer loop counter
LTIME_3: push	 cx			; Save outer loop counter
	 mov	 cx, 0fffeh		; Inner loop counter
LTIME_4: loop	 LTIME_4		; Do nothing loop
	 pop	 cx			; Restore outer loop counter
	 loop	 LTIME_3		; Loop again...


RT_BEEP_LOW_EXIT:

	 popf				; Restore flags
	 REGREST <cx,bx,ax>		; Restore registers

	 ret
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BEEP_LOW  endp

;***************************************************************************

	 NPPROC  DUMMY -- Dummy Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT|


|

	 REGSAVE <>		; Save registers


	 REGREST <>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DUMMY	 endp			; End DUMMY procedure

;***************************************************************************

CODE	 ends			; End CODE segment

	 MEND	 PROBE		; End PROBE module



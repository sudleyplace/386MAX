;' $Header:   P:/PVCS/MAX/XLAT/XLAT.ASV   1.3   30 May 1997 12:26:02   BOB  $
	 title	 XLAT -- The XLAT.COM program
	 page	 58,122
	 name	 XLAT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, word-aligned,  stack,  class 'prog'
	       Program segment CODE,  word-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment LDATA, dword-aligned, public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'

Program derived from:  None.

Original code by: Marc Alexander, June 1991.

Change log:

Who		 When		What
--------------------------------------------------------------------------------
Marc Alexander	 June 1991	Initial code.

This is really two programs in one.  XLAT can be run from the command line
or from within MAX.  If this program is run from the command line, there
are optional parameters to define the BIOS in question and the translation
behaviour.  If this program is run from within MAX, it would be run in two
passes.
	Pass 1 coordinates all the variables between MAX and XLAT.
This pass also searches the BIOS and accumulates a list of data addresses
that are to be skipped in thranslation process.  The final step of Pass 1
is to save the XLAT data for retrieval during Pass 2.
	Pass 2 first retrieves the data that was stored during the first
pass.  Then all ocurrences of the search string are translated to the
replacement string.

Notes:	The CRC is only calculated for the first 24K of the BIOS.
	The search string has a default of 32K but can be user modified.

|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include VIDCALL.INC
	 include BIOSDATA.INC
	 include BIOSCONF.INC
	 include CPUFLAGS.INC
	 include PTR.INC
	 include 386.INC
	 include VERSION.INC
	 include OPEN.INC
	 include IOCTL.INC
	 include ROMSEG.INC
	 include OPCODES.INC
	 include IOPBITS.INC
	 include CPUID.INC
	 include ALLMEM.INC
	 include INTVEC.INC
	 include OPCODES.INC
	 include CMOS.INC

	 include QMAX_MAP.INC
	 include QMAX_MCS.INC
	 include QMAX_CTL.INC
	 include EMM2CALL.INC
	 include QMAX_FLX.INC
	 include QMAX_SYS.INC

.list

PGROUP	 group	 STACK,CODE,DATA,LDATA,DTAIL
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

;-------------	Flags, Macros, and Equates  -----------------

BETA_VER	equ	1	; This is a Beta version

; Equates for making the ROMs Read/Write or Read Only
@READONLY	equ	0	; Mark ROMs as Read Only
@READWRITE	equ	1	; Mark ROMs as Read/Write

	 public LCL_FLAG
LCL_FLAG	dw	@LCL_MODIFY1 ; Local Flags
@LCL_MODIFY1	equ	8000h	; The BIOS is allowed to be modified
@LCL_MODIFY2	equ	4000h	; The BIOS has been modified
@LCL_SUPPFONT	equ	2000h	; The font in question is supplemental
@LCL_WRITE	equ	1000h	; Write .BIO file to disk
@LCL_DISPLAY	equ	0800h	; Display the BIOS via SWAT
@LCL_OPTION	equ	0400h	; The user requested a command line option
@LCL_GETDATA	equ	0200h	; Set when GET_DATA has been executed
@LCL_VGASWAP	equ	0100h	; Test for VGASWAP compatibility
@LCL_VGA	equ	0080h	; VGA or above present (not jsut EGA)
@LCL_EXECUTE	equ	0040h	; Execute the BIOS (via SWAT)
@LCL_CMDLINE	equ	0001h	; Called from DOS command line (not within MAX)

; Note: BIOS modification is active at startup.  This is so MAX can
;	modify the BIOS.  If run from the command line, this flag is
;	turned off early in the program, and a command line switch is
;	needed to turn it back on.

@LOWEST_ROM	equ	0A000h	; Lowest segment we would expect to find a ROM


;----------------  386MAX specific variables  --------------

extrn	 BETA_H:abs		; Hundreds unit of Beta version number
extrn	 BETA_T:abs		; Tens ...
extrn	 BETA_U:abs		; Units ...

	 public DEVNAME_MAX, DEV_HNDL
DEVNAME_MAX  db  '386MAX$$',0   ; Our device driver name
DEV_HNDL     dw  ?		; Handle to above device

	 public MAXVERS_H
MAXVERS_H	equ	'6'     ; MAX major version number (for command line)

	 public  INFO_CTL, INFO, @INFOSIZE
	 include QMAXINFO.INC
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
@INFOSIZE equ	 size INFO_STR	; Local instance of QMAXINFO structure

	 public PORT67
PORT67	 dw	 ?		; I/O port for backdoor functions

	 public  SYSTEM_FLAG
SYSTEM_FLAG dd	 0		; MAX's System Flags

;--------------------  Text messages  --------------------

	 public  MSG_COPY
MSG_COPY db	 'XLAT  -- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
if BETA_VER
	 db	 '.',BETA_H,BETA_T,BETA_U
endif					; if BETA_VER
	 db	 CR,LF
ifdef LANG_GR
	 db	 ' (C) Copyright 1991-96 Qualitas, Inc.  Alle Rechte vorbehalten.'
else
	 db	 ' (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.'
endif				; IFDEF LANG_GR
	 db	 CR,LF,EOS
@MSG_COPYLEN	 equ	($-MSG_COPY)-1

	 public  MSG_HELP
ifdef LANG_GR
MSG_HELP db	 'Dieses ist ein Zusatz-Programm fr Qualitas MAX/BlueMAX (tm).'
else
MSG_HELP db	 'This is a supplementary program used by Qualitas MAX/BlueMAX (tm).'
endif				; IFDEF LANG_GR
	 db	 CR,LF,EOS

if 0 ;===================

; The help screen is commented out to help keep competitors out of the
; VGASWAP race.  Since this program is meant to be used from within MAX,
; its only use as a .COM program is as a debugging aid.  If this is the
; case, tech-support or development will be on the phone and guide the
; user through this program from the command line.

	 public  MSG_HELP
ifdef LANG_GR
MSG_HELP db	 'Sammelt wertvolle Informationen ber das Video-BIOS.'       ,CR,LF
	 db	 '/x     = zeigt nur die BIOS-Information'                    ,CR,LF
	 db	 '/aC000 = Adresse des BIOS'                                  ,CR,LF
	 db	 '/l8000 = BIOS-L„nge'                                        ,CR,LF
	 db	 '/sC000 = Such-String'                                       ,CR,LF
	 db	 '/rB000 = Ersetzungs-String'                                 ,CR,LF
	 db	 '/w     = schreibt .BIO-Datei auf Platte'                    ,CR,LF
	 db	 '/d=dateiname.erw - Anzeige des BIOS-Abbildes ber Debugger' ,CR,LF
	 db	 '/e=dateiname.erw - Durchfhrung der BIOS-Abbildung'         ,CR,LF
	 db	 CR,LF
	 db	 'Beachte: BIOS-L„nge erstreckt sich nur auf die Such-L„nge,' ,CR,LF
	 db	 '         CRC wird immer auf eine L„nge von 24 kB errechnet.',CR,LF
	 db	 EOS
else
MSG_HELP db	 'Gathers useful information on the video BIOS.',CR,LF
	 db	 '/x     = Just diaply BIOS information'          ,CR,LF
	 db	 '/aC000 = Address of BIOS'                       ,CR,LF
	 db	 '/l8000 = BIOS length'                           ,CR,LF
	 db	 '/sC000 = Search string'                         ,CR,LF
	 db	 '/rB000 = Replacement string'                    ,CR,LF
	 db	 '/w     = Write .BIO file to disk'               ,CR,LF
	 db	 '/d=filename.ext Display BIOS image via debugger',CR,LF
	 db	 '/e=filename.ext Execute BIOS image'             ,CR,LF
	 db	 CR,LF
	 db	 'Note: BIOS length effets search length only,   ',CR,LF
	 db	 '      CRC is always calculated on a 24K length.',CR,LF
	 db	 EOS
endif				; IFDEF LANG_GR
endif ;==================

	 public  MSG_XBIOS,MSG_XBIOS1
ifdef LANG_GR
MSG_XBIOS	db	'Achtung: habe eine ROM-Signatur gefunden bei '
else
MSG_XBIOS	db	'Warning: A ROM signature was not found at '
endif				; IFDEF LANG_GR
MSG_XBIOS1	db	'____.',CR,LF,BEL,EOS
@MSG_XBIOS_LEN	equ	(($-MSG_XBIOS)-1)-1	; Don't write BEL to file

	 public  MSG_OFFSET		; Offset within BIOS of match
MSG_OFFSET	db	'____ ',EOS
@MSG_OFFSET_LEN equ	 ($-MSG_OFFSET)-1

	 public  MSG_CRLF		; Carraige Return & Line Feed
MSG_CRLF	db	CR,LF,EOS
@MSG_CRLF_LEN	equ	($-MSG_CRLF)-1

	 public  MSG_COUNT, MSG_COUNT1	; Number of matches within BIOS
ifdef LANG_GR
MSG_COUNT  db	 'Z„hler  '
else
MSG_COUNT  db	 'Count  '
endif				; IFDEF LANG_GR
MSG_COUNT1 db	 '____',CR,LF,EOS
@MSG_COUNT_LEN	equ	($-MSG_COUNT)-1

	 public  MSG_RESULTS,MSG_ADDR,MSG_SEARCH,MSG_REPL,MSG_LEN,MSG_CRC
if 0	; ------- These look like keywords, but here they are in German:
MSG_RESULTS	db	'Adr.   '
MSG_ADDR	db	'____ ',CR,LF,'Suche  ' ; BIOS address
MSG_SEARCH	db	'____ ',CR,LF,'Ersetze' ; Search string
MSG_REPL	db	'____ ',CR,LF,'L„nge  ' ; Replacement string
MSG_LEN 	db	'____ ',CR,LF,'ID     ' ; Search length
MSG_CRC 	db	'____ ',CR,LF,'ROM-Lg.' ; CRC of first 24KB
MSG_ROMLENGTH	db	'__'   ,CR,LF,'Cachelg' ; ROM length ID byte
endif				; IF 0
MSG_RESULTS	db	'Addr   '
MSG_ADDR	db	'____ ',CR,LF,'Search ' ; BIOS address
MSG_SEARCH	db	'____ ',CR,LF,'Repl   ' ; Search string
MSG_REPL	db	'____ ',CR,LF,'Length ' ; Replacement string
MSG_LEN 	db	'____ ',CR,LF,'ID     ' ; Search length
MSG_CRC 	db	'____ ',CR,LF,'ROMLen ' ; CRC of first 24KB
MSG_ROMLENGTH	db	'__'   ,CR,LF,'Cachel ' ; ROM length ID byte
MSG_CACHELEN	db	'____',CR,LF            ; Minimum caching length
		db	CR,LF,EOS
@MSG_RESULTS_LEN	equ	 ($-MSG_RESULTS)-1

	 public  MSG_FONT,MSG_FONT1,MSG_FONT2,MSG_FONT3
MSG_FONT	db	'>'
MSG_FONT1	db	'____:'
MSG_FONT2	db	'____,'
MSG_FONT3	db	'____',CR,LF,EOS
@MSG_FONT_LEN	equ	($-MSG_FONT)-1

	 public  MSG_MODIFY
ifdef LANG_GR
MSG_MODIFY	db	 'Das BIOS wurde ge„ndert.',CR,LF,EOS
else
MSG_MODIFY	db	 'The BIOS has been modified.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_VGASWAP_OK,MSG_VGASWAP_FAIL
ifdef LANG_GR
MSG_VGASWAP_OK	 db	 'Ja  ', CR,LF,EOS ; N.B. Must be same size as below
MSG_VGASWAP_FAIL db	 'Nein', CR,LF,EOS ; N.B. Must be same size as above
else
MSG_VGASWAP_OK	 db	 'Yes',CR,LF,EOS ; N.B. Must be same size as below
MSG_VGASWAP_FAIL db	 'No ',CR,LF,EOS ; N.B. Must be same size as above
endif				; IFDEF LANG_GR
@MSG_VGASWAP_LEN equ	 $-MSG_VGASWAP_FAIL

	 public  PTR_MSG_VGASWAP
PTR_MSG_VGASWAP  dw	 ? ; Pointer to VGASWAP OK or VGASWAP FAIL message

	public	MSG_MAXOK
ifdef LANG_GR
MSG_MAXOK db	 'Qualitas MAX ist installiert.',CR,LF,EOS
else
MSG_MAXOK db	 'Qualitas MAX is installed.',CR,LF,EOS
endif				; IFDEF LANG_GR
@MSG_MAXOK_LEN	 equ	($-MSG_MAXOK)-1

	public	MSG_NOMAX
ifdef LANG_GR
MSG_NOMAX db	 'Qualitas MAX ist nicht installiert.',CR,LF,EOS
else
MSG_NOMAX db	 'Qualitas MAX is not installed.',CR,LF,EOS
endif				; IFDEF LANG_GR
@MSG_NOMAX_LEN	 equ	($-MSG_NOMAX)-1

	public	MSG_BADVER
ifdef LANG_GR
MSG_BADVER db	 '386MAX-Version 5 (oder „ltere).',CR,LF,EOS
else
MSG_BADVER db	 '386MAX version 5 (or below).',CR,LF,EOS
endif				; IFDEF LANG_GR
@MSG_BADVER_LEN  equ	($-MSG_BADVER)-1

	 public  MSG_ENTRY_NUM
	 public  MSG_ENTRY_SEG1,MSG_ENTRY_OFF1
MSG_ENTRY_NUM	 db	 '____) '       ; Interrupt number
MSG_ENTRY_SEG1	 db	 '____:'        ; Pointer segment
MSG_ENTRY_OFF1	 db	 '____ '        ; ...     offset
MSG_ENTRY_OPCOD  db	 '____ '        ; Opocde at that address
MSG_ENTRY_SEG2	 db	 '____'         ; Segment of Far Jump
MSG_ENTRY_COLON  db	 ':'            ;
MSG_ENTRY_OFF2	 db	 '____'         ; Offset  ...
		 db	 CR,LF,EOS
@MSG_ENTRY_LEN	 equ	 ($-MSG_ENTRY_NUM)-1

	 public MSG_COMMENT,KBD_BUFF
ifdef LANG_GR
MSG_COMMENT	db	'geben Sie bitte eine kurze, 1-zeilige Beschreibung ein, ',CR,LF
		db	'und best„tigen Sie dann mit <ÄÙ.',CR,LF,EOS
else
MSG_COMMENT	db	'Please enter a brief 1-line description, '
		db	'then press ENTER.',CR,LF,EOS
endif				; IFDEF LANG_GR
KBD_BUFF db	(80+3) dup (?)	; Buffer for user's comments

	   public	MSG_OPENCFG_ERR1
ifdef LANG_GR
MSG_OPENCFG_ERR1	db   'Fehler beim Anlegen der .CFG-Datei aufgetaucht.',CR,LF,EOS
else
MSG_OPENCFG_ERR1	db   'Error creating .CFG file.',CR,LF,EOS
endif				; IFDEF LANG_GR

	   public	MSG_WRITEBIO_ERR1, MSG_WRITEBIO_ERR2, MSG_WRITEBIO_ERR3
ifdef LANG_GR
MSG_WRITEBIO_ERR1	db   'Fehler beim Anlegen der .BIO-Datei.'      ,CR,LF,EOS
MSG_WRITEBIO_ERR2	db   'Fehler beim Schreiben der .BIO-Datei (1).',CR,LF,EOS
MSG_WRITEBIO_ERR3	db   'Fehler beim Schreiben der .BIO-Datei (2).',CR,LF,EOS
else
MSG_WRITEBIO_ERR1	db   'Error creating .BIO file.',CR,LF,EOS
MSG_WRITEBIO_ERR2	db   'Error writing .BIO file (1).',CR,LF,EOS
MSG_WRITEBIO_ERR3	db   'Error writing .BIO file (2).',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  BIOS_READ_ERR
ifdef LANG_GR
BIOS_READ_ERR	db	'Fehler beim Lesen der BIOS-Datei.',CR,LF,EOS
else
BIOS_READ_ERR	db	'Error reading BIOS file.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 publiC MSG_NOT386
ifdef LANG_GR
MSG_NOT386 db	 'Diese Programm erfordert eine 386-er (oder bessere) CPU.'
else
MSG_NOT386 db	 'This program requires a 386 (or better) CPU.'
endif				; IFDEF LANG_GR
	   db	 CR,LF,EOS

;--------------------  Variables  ---------------------

	 public  LCLSTK,LCLSTKZ
	 align	 2
LCLSTK	 dw	 80h dup (?)	; Local stack
LCLSTKZ  label	 word		; Top of stack

	 public  XLAT_COUNTER,BIOS_CRC,MIN_LENGTH
XLAT_COUNTER	dw	0	; Counter of string occurrences
BIOS_CRC	dw	?	; CRC before modification
MIN_LENGTH	dw	16*1024 ; Minimum BIOS length (Assume EGA)
				; Modified to 32 KB if on a VGA
				; Modified to (ROMLEN) KB if on a COMPAQ

	 public  SPECIAL_ADDR_CNT
SPECIAL_ADDR_CNT dw	 0	; Counter of special addresses

	 public  CACHE_LEN
CACHE_LEN	 dw	 0	; Caching length of ROM

;------------------  Special Strings  -------------------

; List of special strings in the video BIOS that have to be searched for

SEARCH_STR	 struc		; Structure used to find search strings
   SEARCH_COUNT  dw	?	; Byte count in Search String
   SEARCH_OFFSET dw	?	; Negative offset from search constant
   SEARCH_LABEL  db	?	; Identifier for debugging purposes
   SEARCH_STRING db	?	; Search string (6 spaces)
		 db	?	; 2
		 db	?	; 3
		 db	?	; 4
		 db	?	; 5
		 db	?	; 6
		 db	?	; 7
		 db	?	; 8
SEARCH_STR	 ends		; End SEARCH_STR structure

@SEARCH_STRLEN	 equ	size SEARCH_STR ; Size of above structure

	 public  MSG_SPECIAL_LBL
MSG_SPECIAL_LBL  db	'__',EOS ; Text for debugging string searches
@MSG_SPECIAL_LBLLEN equ ($-MSG_SPECIAL_LBL)-1

	 public  SEARCH_PATTERN
SEARCH_PATTERN	SEARCH_STR <2,3,20h,0F7h,046h> ; TEST [BP+imm8],C000
		SEARCH_STR <6,2,21h,081h,0C1h,000h,0C0h,014h,000h> ; ADD CX,C000
		SEARCH_STR <1,1,22h,025h>	; AND  AX,imm16
		SEARCH_STR <1,1,23h,00Dh>	; OR   AX,imm16
		SEARCH_STR <1,1,24h,035h>	; XOR  AX,imm16
		SEARCH_STR <1,1,25h,0A9h>	; TEST AX,imm16
		SEARCH_STR <6,3,26h,047h,04Fh,0FEh,000h,0C0h,020h> ; (#6)
		SEARCH_STR <1,1,27h,0E8h>	; CALL C000 R
		SEARCH_STR <6,1,28h,0B9h,000h,0C0h,083h,0FFh,009h> ; (#8)
		SEARCH_STR <8,4,29h,000h,040h,000h,080h,000h,0C0h,000h,000h>
		SEARCH_STR <8,1,2Ah,036h,000h,0C0h,036h,0EFh,036h,0FCh,036h>
		SEARCH_STR <8,3,2Bh,0C7h,006h,014h,000h,0E0h,00Eh,0FBh,0C3h>
@SEARCH_PATTERNLEN	 equ	 $-SEARCH_PATTERN

COMMENT |

Explanation of special strings listed above...
0) TEST [BP+imm8],C000
1) ADD	CX,C000
2) AND	AX,imm16
3) OR	AX,imm16
4) XOR	AX,imm16
5) TEST AX,imm16
6) Part of jump table on STB Power graph (CRC #6C26)
7) CALL xxxx (where xxxx is C000 bytes forward (actually 4000 bytes behind))
   8-bit Paradise CRC# C5D5
8) Mode switch code for some STB boards (MOV CX,C000) - (CRC #B0CD)
9) Part of unknown data table in CompuAdd (4000,8000,C000,0000)
A) Part of Video Seven (1.09) jump table

|

;-------------------  Disk & I/O variables  -----------

	 public  MAPSEG_NXT, BIO_SEG, CFG_SEG
MAPSEG_NXT	dw	0	; Next para of free memory
BIO_SEG 	dw	0	; Segment of .BIO file
CFG_SEG 	dw	0	; Segment of .CFG file

	 public HEXTABLE
HEXTABLE db	 '0123456789ABCDEF'     ; Hex digits for ASCII conversion

	 public  CON4K, CON24K, CON64K, CON1M
CON4K	 dd	    4*1024	;  4K
CON24K	 dd	   24*1024	; 24K
CON64K	 dd	   64*1024	; 64K
CON1M	 dd	 1024*1024	;  1M

	 public  DOT_CFG, DOT_BIO
DOT_CFG  db	 '.CFG',0
DOT_BIO  db	 '.BIO',0

	 public  FILEDEF, FILECRC,
FILEDEF  db	 'VID_'          ; Default filename
FILECRC  db	 '____',CR
@FILELEN equ	 8

	 public  FILEOFF,FILELEN,FILEBUF,FILEHNDL,TXTBUF,TXTLEN
	 align	 2
FILEOFF  dw	 ?		; Offset of start of filename
FILELEN  dw	 8		; Length of filename
TXTLEN	 dw	 ?		; Length of text file
TXTBUF	 db	 128 dup (0)	; Local copy of filename and text lines
FILEBUF  db	 80 dup (0)	; Local copy of filename
FILEHNDL dw	 ?		; Handle to CFG file

	 public  BIOS_FNAME
BIOS_FNAME	 db	'VID_BIOS.BIO',0        ; Default file name
		 db	80 DUP (0)		; Add room for long path
@BIOS_FNAME_LEN  equ	$-BIOS_FNAME

@CFG_EXT	 equ	 'GFC.'         ; Extension for CFG files


;------------------- Search strings -------------------------

	 public  LCL_PSIGN
LCL_PSIGN db 'Phoenix Technologies Ltd' ; Phoenix BIOS signature
LCL_PSIGN_LEN equ $-LCL_PSIGN	; Length of ...

	 public  LCL_WSIGN
LCL_WSIGN db '*Eagle II VGA BIOS' ; WGS6386 video BIOS signature
LCL_WSIGN_LEN equ $-LCL_WSIGN	; Length of ...

	 public  LCL_SPEEDSTAR
LCL_SPEEDSTAR db 'SpeedSTAR' ; Diamond Speedstar BIOS signature
LCL_SPEEDSTAR_LEN equ $-LCL_SPEEDSTAR ; Length of ...

	 public  LCL_DSS_CHECK
LCL_DSS_CHECK db     003h, 004h 	; ADD AX,[SI]
	      db     046h, 046h 	; INC SI, INC SI
	      db     033h, 004h 	; XOR AX,[SI]
	      db     046h, 046h 	; INC SI, INC SI
	      db     0E2h, 0F6h 	; LOOP @B
	      db     05Eh		; POP SI
	      db     03Bh, 044h, 04h	; CMP ax,[SI+4]
LCL_DSS_PATCH db     074h, 015h 	; JZ @F
@LCL_DSS_LEN  equ    $-LCL_DSS_CHECK	; Length of ...

	 public  @WGS_SIGN_ADDR
@WGS_SIGN_ADDR equ 02Dh 	; Offset of above WGS6386 signature

	 public  @SPEEDSTAR_SIGN_ADDR
@SPEEDSTAR_SIGN_ADDR equ 0A71h	; Offset of above SpeedSTAR signature


;-------------------  Single Step variables -----------

	 public  CPQ_FLAG
	 include QMAX_CPQ.INC
CPQ_FLAG CPQ_REC <>		; Local CPQ flags

	 public  SYSROM_START,ROMADDR_LO,ROMADDR_HI
SYSROM_START dw  0F000h 	; Lowest address of System BIOS
ROMADDR_LO   dw  0C000h 	; Lowest expected ROM address
ROMADDR_HI   dw  0C800h 	; Highest expected ROM address

	 public  CPQINT01_VEC
CPQINT01_VEC dd  ?		; Save area for original INT 01h handler

	 public  OLDINTHW_VEC
OLDINTHW_VEC dd  ?		; Save area for original hardware interrupt handler

	 public  OLDCPQSTK_VEC
OLDCPQSTK_VEC dd ?		; Caller's SS:SP

	 public  CPQSTK,CPQSTKZ
CPQSTK	 dw	 1024 dup ('??') ; Local stack
CPQSTKZ  label	 word

	 public  FINDHW_ACT
FINDHW_ACT dw	 ?		; Action if tripping address found

	 public  CPQINT01_LAST,CPQINT01_TRIP,CPQINT01_SAVE
CPQINT01_LAST dd ?		; Last used address
CPQINT01_TRIP dd ?		; Tripping address
CPQINT01_SAVE dd 0		; Saved address

	 public  TRIP_CS,TRIP_DS,TRIP_ES,TRIP_SS
TRIP_CS  equ	 CPQINT01_TRIP.VSEG ; Tripping address's segment registers
TRIP_DS  dw	 ?
TRIP_ES  dw	 ?
TRIP_SS  dw	 ?

	 public  TRIP_BX,TRIP_BP,TRIP_SI,TRIP_DI
TRIP_BX  dw	 ?		; Tripping address's base and index registers
TRIP_BP  dw	 ?
TRIP_SI  dw	 ?
TRIP_DI  dw	 ?

	 public  PRMACT 	; Decoding jump table
PRMACT	 dw	 PGROUP:RM000	; R/M = 000 = [BX+SI]
	 dw	 PGROUP:RM001	; R/M = 001 = [BX+DI]
	 dw	 PGROUP:RM010	; R/M = 010 = [BP+SI]
	 dw	 PGROUP:RM011	; R/M = 011 = [BP+DI]
	 dw	 PGROUP:RM100	; R/M = 100 = [SI]
	 dw	 PGROUP:RM101	; R/M = 101 = [DI]
	 dw	 PGROUP:RM110	; R/M = 110 = [BP]
	 dw	 PGROUP:RM111	; R/M = 111 = [BX]

	 public  IGNCNT
IGNCNT	 dw	 0		; Failed ignore count

BCFINT_STR struc
  BCFINT_FIND dw	 ?	; Action routine to find it
  BCFINT_VEC  dd	 ?	; Pointer to original interrupt vector
BCFINT_STR ends

BCFINTS  label	 tbyte
	 BCFINT_STR <PGROUP:FINDIGN,   4*05h> ; 05h  Print screen/BOUND
	 BCFINT_STR <PGROUP:FIND10,    4*10h> ; 10h  Video services
	 BCFINT_STR <PGROUP:FINDIGN,   4*1Dh> ; 1Dh  Video parameter table
	 BCFINT_STR <PGROUP:FINDIGN,   4*1Fh> ; 1Fh  Graphic characters table
	 BCFINT_STR <PGROUP:FINDIGN,   4*42h> ; 42h  EGA revectored INT 10h
	 BCFINT_STR <PGROUP:FINDIGN,   4*43h> ; 43h  EGA first 128 characters
	 BCFINT_STR <PGROUP:FIND10,    4*6Dh> ; 6Dh  Secondary VGA interrupt
	 BCFINT_STR <PGROUP:FINDIGN,   04A8h> ;12Ah  EGA save ptr
NBCFINTS equ	 ($-BCFINTS)/(type BCFINT_STR) ; # interrupts to check

;-------------------  Special tables  -----------

	public	 MAXLAT_DISPATCH
MAXLAT_DISPATCH  label	 word	; Function dispatcher jump table
	 dw	 PGROUP:MAXLAT_INIT
	 dw	 PGROUP:MAXLAT_GETSRCSEG
	 dw	 PGROUP:MAXLAT_SETSRCSEG
	 dw	 PGROUP:MAXLAT_GETDSTSEG
	 dw	 PGROUP:MAXLAT_SETDSTSEG
	 dw	 PGROUP:MAXLAT_GETROMLEN
	 dw	 PGROUP:MAXLAT_SETROMLEN
	 dw	 PGROUP:MAXLAT_DETECTION
	 dw	 PGROUP:MAXLAT_RESTORE
	 dw	 PGROUP:MAXLAT_TRANSLATE
	 dw	 PGROUP:MAXLAT_GETCACHELEN

	 public  @DISPATCH_LIMIT
@DISPATCH_LIMIT equ	($-MAXLAT_DISPATCH)/2	; Number of functions


	 public  MODEL_DPT	; Model Default Parameter Table
MODEL_DPT	 label	 byte
	 db	50h, 18h, 0Eh, 00h, 40h, 01h, 0Fh, 1Dh	; 00 - 07
	 db	02h, 63h, 5Fh, 4Fh, 50h, 82h, 88h, 0Ah	; 08 - 0F
	 db	0BFh,1Fh, 00h, 4Dh, 00h, 00h, 00h, 00h	; 10 - 17
	 db	00h, 00h, 9Ch, 8Eh, 8Fh, 28h, 1Fh, 96h	; 18 - 1F
	 db	0B9h,0A3h,0FFh,00h, 01h, 02h, 03h, 04h	; 20 - 27
	 db	05h, 06h, 07h, 08h, 09h, 0Ah, 0Bh, 0Ch	; 28 - 2F
	 db	0Dh, 0Eh, 0Fh, 01h, 00h, 0Fh, 00h, 00h	; 30 - 37
	 db	00h, 00h, 00h, 00h, 10h, 0Eh, 0Fh, 0FFh ; 38 - 3F

	 public  XORLIST
XORLIST  dw	 00000h, 0C0C1h, 0C181h, 00140h, 0C301h, 003C0h, 00280h, 0C241h
	 dw	 0C601h, 006C0h, 00780h, 0C741h, 00500h, 0C5C1h, 0C481h, 00440h
	 dw	 0CC01h, 00CC0h, 00D80h, 0CD41h, 00F00h, 0CFC1h, 0CE81h, 00E40h
	 dw	 00A00h, 0CAC1h, 0CB81h, 00B40h, 0C901h, 009C0h, 00880h, 0C841h
	 dw	 0D801h, 018C0h, 01980h, 0D941h, 01B00h, 0DBC1h, 0DA81h, 01A40h
	 dw	 01E00h, 0DEC1h, 0DF81h, 01F40h, 0DD01h, 01DC0h, 01C80h, 0DC41h
	 dw	 01400h, 0D4C1h, 0D581h, 01540h, 0D701h, 017C0h, 01680h, 0D641h
	 dw	 0D201h, 012C0h, 01380h, 0D341h, 01100h, 0D1C1h, 0D081h, 01040h
	 dw	 0F001h, 030C0h, 03180h, 0F141h, 03300h, 0F3C1h, 0F281h, 03240h
	 dw	 03600h, 0F6C1h, 0F781h, 03740h, 0F501h, 035C0h, 03480h, 0F441h
	 dw	 03C00h, 0FCC1h, 0FD81h, 03D40h, 0FF01h, 03FC0h, 03E80h, 0FE41h
	 dw	 0FA01h, 03AC0h, 03B80h, 0FB41h, 03900h, 0F9C1h, 0F881h, 03840h
	 dw	 02800h, 0E8C1h, 0E981h, 02940h, 0EB01h, 02BC0h, 02A80h, 0EA41h
	 dw	 0EE01h, 02EC0h, 02F80h, 0EF41h, 02D00h, 0EDC1h, 0EC81h, 02C40h
	 dw	 0E401h, 024C0h, 02580h, 0E541h, 02700h, 0E7C1h, 0E681h, 02640h
	 dw	 02200h, 0E2C1h, 0E381h, 02340h, 0E101h, 021C0h, 02080h, 0E041h
	 dw	 0A001h, 060C0h, 06180h, 0A141h, 06300h, 0A3C1h, 0A281h, 06240h
	 dw	 06600h, 0A6C1h, 0A781h, 06740h, 0A501h, 065C0h, 06480h, 0A441h
	 dw	 06C00h, 0ACC1h, 0AD81h, 06D40h, 0AF01h, 06FC0h, 06E80h, 0AE41h
	 dw	 0AA01h, 06AC0h, 06B80h, 0AB41h, 06900h, 0A9C1h, 0A881h, 06840h
	 dw	 07800h, 0B8C1h, 0B981h, 07940h, 0BB01h, 07BC0h, 07A80h, 0BA41h
	 dw	 0BE01h, 07EC0h, 07F80h, 0BF41h, 07D00h, 0BDC1h, 0BC81h, 07C40h
	 dw	 0B401h, 074C0h, 07580h, 0B541h, 07700h, 0B7C1h, 0B681h, 07640h
	 dw	 07200h, 0B2C1h, 0B381h, 07340h, 0B101h, 071C0h, 07080h, 0B041h
	 dw	 05000h, 090C1h, 09181h, 05140h, 09301h, 053C0h, 05280h, 09241h
	 dw	 09601h, 056C0h, 05780h, 09741h, 05500h, 095C1h, 09481h, 05440h
	 dw	 09C01h, 05CC0h, 05D80h, 09D41h, 05F00h, 09FC1h, 09E81h, 05E40h
	 dw	 05A00h, 09AC1h, 09B81h, 05B40h, 09901h, 059C0h, 05880h, 09841h
	 dw	 08801h, 048C0h, 04980h, 08941h, 04B00h, 08BC1h, 08A81h, 04A40h
	 dw	 04E00h, 08EC1h, 08F81h, 04F40h, 08D01h, 04DC0h, 04C80h, 08C41h
	 dw	 04400h, 084C1h, 08581h, 04540h, 08701h, 047C0h, 04680h, 08641h
	 dw	 08201h, 042C0h, 04380h, 08341h, 04100h, 081C1h, 08081h, 04040h

DATA	 ends			; End DATA segment

;***************************************************************************

LDATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

COMMENT |

The data in this segment is Saved / Restored
between passes when XLAT is run from within MAX.

386MAX will store up to 256 bytes between PASS 1 and PASS 2.
Only store data here that must be preserved between the two passes.

|

SAVED_DATA	label	byte	; This label must be first in LDATA segment

	 public  BIOS_ADDRESS,BIOS_ADDR2,BIOS_SRC,BIOS_DEST,BIOS_LEN
	 public  BIOS_FLAG
BIOS_ADDRESS	dw	0C000h	; Address of video BIOS
BIOS_ADDR2	dw	0	; Address of secondary video BIOS
BIOS_SRC	dw	0C000h	; Search string
BIOS_DEST	dw	0B000h	; Replacement string
BIOS_LEN	dw	08000h	; BIOS length in bytes
BIOS_FLAG	dw	0	; BIOS flags
@BIOS_C000 equ	 8000h		; SEARCH_BIOS on pass 1 found a duplicate
				; video ROM at C000

; List of special data tables in the BIOS

DATA_STR struc			; Structure for 'Off limits' data

DATA_SEG	dw	?	; Starting segment in paras
DATA_START	dw	?	; Starting offset in bytes
DATA_LEN	dw	?	; Length of font in bytes

DATA_STR ends			; End of DATA_STR structure

	 public  VOID
VOID	 DATA_STR 11 dup (<0,0,0>) ; List of 6 Font addresses
				   ; and the 1 Default Param table
				   ; and the 1 Extended DPT
				   ; and the 2 Save Pointers
				   ; and the 1 DCC table

	 public  VOID_PTR
VOID_PTR dw	0		; Index into above table
				; Points to the next (or last) entry

	 public  SPECIAL_ADDR
SPECIAL_ADDR	 label word	; List of special translation addresses
	 dw	 3 dup (?)	; Room for 3 entries

@SAVED_COUNT	 equ	$-SAVED_DATA	; Amount for MAX to Save/Restore
					; Includes major variables
					; ... and VOID structure
					; ... and VOID index pointer
					; ... special addresses to be translated


LDATA	 ends			; End LDATA segment

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
.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list


;***************************************************************************

	 NPPROC  INITIAL -- INITIAL Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Entry Point for the .COM program.

Following initial jump is MAX -> XLAT data strucutre.
The XLAT_STR structure is defined in QMAX_FLX.INC

Note : This jump must be exactly three bytes.
       386MAX will look for the XLAT structure at the fourth byte.

|

	 jmp	 near ptr TRANSLATE ; Jump to XLAT.COM code

XLAT_HDR XLAT_STR <VER,?,PGROUP:MAXLAT> ; XLAT Version #
					; MAX version # (fille in by MAX)
					; Offset to function dispatcher

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INITIAL  endp			; End INITIAL_PROC procedure

;***************************************************************************

	 FPPROC  MAXLAT -- Interface between MAX and XLAT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

MAX to XLAT Interace and Function dispatcher.

On entry :
AH	 =	Function number
BX,CX,DX =	Optional arguments (varies according to function)

On exit :
BX,CX,DX =	Optional return parameters
AX	=	Must be preserved across XLAT (for MAX error messages)
CF	=	0 indicates success
		1 indicates failure

Note : Functions that are called from real mode may return CF=1 to abort.
       Functions called from virtual mode may not return CF=1.

|

	 REGSAVE <ax,dx,si,ds,es> ; Save registers

	 push	 cs		; Get segment of PGROUP
	 pop	 ds		; ... and address via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Get segment of PGROUP
	 pop	 es		; ... and address via ES
	 assume  es:PGROUP	; Tell the assembler about it

	 cmp	 ah,@DISPATCH_LIMIT ; Check against upper limit
	 jae	 near ptr MAXLAT_ERROR ; Sorry, nothing defined for you

	 movzx	 si,ah		; Place in index register
	 shl	 si,1		; Convert byte to word

	 jmp	 MAXLAT_DISPATCH[si] ; Jump to appropriate function

;---------------
MAXLAT_INIT:

COMMENT |

Initialize XLAT (Pass 1).

On entry:
EBX	=	MAX's SYS_FLAG bit flag

On exit :
BX	=	 XLAT's version number

|

	 mov	 SYSTEM_FLAG,ebx ; Save MAX's system flags
				; Note: This variable is not saved for pass 2

	 call	 IZITVGA	; Is this a VGA or above?
	 cmp	 ax,-1		; Is a VGA present?
	 je	 short @F	; Jump if not

	 or	 LCL_FLAG,@LCL_VGA ; VGA or above is present
	 mov	 MIN_LENGTH,32*1024 ; Minimum BIOS length is 32KB for VGA

	 call	 SRCH_INT	; Find the video BIOS entry points

@@:
	 mov	 bx,@XLATVERS_HTU ; Return XLAT's (pseudo) version number

	 jmp	 near ptr MAXLAT_CLC ; Join common exit code

;---------------
MAXLAT_GETSRCSEG:

COMMENT |

Get source video BIOS address (Pass 1).

On entry:
CX	=	 Primary video BIOS
DX	=	 Secondary video BIOS

On exit :
BX	=	 Segment of video BIOS

|

	 call	 GET_VIDEO_SEG	; Get segment of video ROM
	 jc	 near ptr MAXLAT_ERROR ; Jump if failure

	 mov	 bx,BIOS_ADDRESS ; Set return value

	 cmp	 bx,cx		; Is BIOS_ADDRESS same as MAX's primary video
	 jne	 short @F	; Jump if not

	 mov	 cx,dx		; Use MAX's primary video as BIOS_ADDR2
@@:
	 mov	 BIOS_ADDR2,cx	; Save as secondary video ROM

	 jmp	 near ptr MAXLAT_CLC ; Join common exit code

;---------------
MAXLAT_SETSRCSEG:

COMMENT |

Set video BIOS source address (Pass 1).

On entry :
BX	=	 Segment of video BIOS.
CX	=	 Primary video BIOS
DX	=	 Secondary video BIOS

|

	 mov	 BIOS_ADDRESS,bx ; Store as address of BIOS

	 cmp	 bx,cx		; Is BIOS_ADDRESS same as MAX's primary video
	 jne	 short @F	; Jump if not

	 mov	 cx,dx		; Use MAX's primary video as BIOS_ADDR2
@@:
	 mov	 BIOS_ADDR2,cx	; Save as secondary video ROM

	 jmp	 near ptr MAXLAT_CLC ; Join common exit code

;---------------
MAXLAT_GETDSTSEG:

COMMENT |

Get video BIOS destination address (Pass 1).

On exit:
BX	=	 Destination segment of video BIOS.

|

	 mov	 bx,BIOS_DEST	; Get destination segment

	 jmp	 near ptr MAXLAT_CLC ; Join common exit code

;---------------
MAXLAT_SETDSTSEG:

COMMENT |

Set video BIOS destination address (Pass 1).

On entry :
BX	=	 Destination segment of video BIOS.

|

	 mov	 BIOS_DEST,bx	; Store as BIOS destination

	 jmp	 near ptr MAXLAT_CLC ; Join common exit code

;---------------
MAXLAT_GETROMLEN:

COMMENT |

Get video BIOS size in bytes (Pass 1).

We must first call GET_DATA to fill in the data structures
that are used to calculate the ROM's length.

On exit:
BX	=	 Size of video BIOS in bytes.

|

	 mov	 ax,BIOS_ADDRESS ; Get source address
	 mov	 BIOS_SRC,ax	; ... and store as search string

	 call	 GET_DATA	; Find BIOS protions that we should avoid
				; (and their lengths)
				; Always returns successfully

	 call	 CHECK_CPQ386	; If this is a COMPAQ, we should be able
				; to trust the ROM ID lengths

	 call	 CALC_LENGTH	; Calculate the BIOS length

	 mov	 bx,BIOS_LEN	; Default length is 32KB

	 jmp	 short MAXLAT_CLC ; Join common exit code

;---------------
MAXLAT_SETROMLEN:

COMMENT |

Set video BIOS size in bytes (Pass 1).

On entry :
BX	=	 Size of video BIOS in bytes.

|

	 mov	 BIOS_LEN,bx	; Store as BIOS length

	 jmp	 short MAXLAT_CLC ; Join common exit code

;---------------
MAXLAT_GETCACHELEN:

COMMENT |

Get Size of video BIOS to cache

This is the minimum size that has to be cached.

CACHE_LEN can only be determined after SEARCH_BIOS and XLAT_SPECIAL
have been executed.

|

	 and	 LCL_FLAG,(not @LCL_MODIFY1) ; Don't modify BIOS
				; We don't want to translate the BIOS,
				; all we want is some information from it

	 call	 SEARCH_BIOS	; Translate the BIOS (without modification)

	 call	 XLAT_SPECIAL	; Translate special cases (w/o modifiaction)

	 call	 CALC_CACHE_LEN ; Calculate the caching length of the BIOS

	 mov	 bx,CACHE_LEN	; Return the caching length of the BIOS

	 or	 LCL_FLAG,@LCL_MODIFY1 ; Permission to modify the BIOS

	 jmp	 short MAXLAT_CLC ; Join common exit code

;---------------
MAXLAT_DETECTION:

COMMENT |

Detect all portions of the video BIOS that are part of any data structures.
Also passes the address and byte count of data that must be saved for pass 2.
This function is processed during pass 1.

Note: We test to see if this routine has been processed already because
      it might not have if GETROMLEN wasn't needed (ie. the user
      specified the ROM length in the MAX profile).

On exit :
BX	=	Address of saved data within XLAT
CX	=	Byte count of data that must be saved for pass 2.

|

	 test	 LCL_FLAG,@LCL_GETDATA ; Did we process this already?
	 jnz	 short @F	; Jump if so

	 mov	 ax,BIOS_ADDRESS ; Get source address
	 mov	 BIOS_SRC,ax	; ... and store as search string

	 call	 GET_DATA	; Find BIOS protions that we should avoid
				; Always returns successfully

@@:
	 lea	 bx,SAVED_DATA	; Return the address of Save/Restored data
	 mov	 cx,@SAVED_COUNT ; Return the number of bytes to Save/Restore

	 jmp	 short MAXLAT_CLC ; Join common exit code

;-------------
MAXLAT_RESTORE:

COMMENT |

Restore XLAT variables (Pass 2).

On entry:
BX	=	Address of saved data within MAX
CX	=	Byte count of data that was saved from pass 1.

|

	 REGSAVE <fs>		; Save

	 mov	 fs,dx		; Address MAX's PGROUP
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 si,bx		; Source of data restoration
	 lea	 di,SAVED_DATA	; Destination of data restoration
S16  rep movs	 <PGROUP:[di].LO,fs:[si]> ; Restore data from MAX

	 REGREST <fs>		; Restore
	 assume  fs:nothing	; Tell the assembler

	 jmp	 short MAXLAT_CLC ; Join common exit code

;---------------
MAXLAT_TRANSLATE:

COMMENT |

Translate BIOS (Pass 2).

Note: If the BIOS is at E800, then we do not translate the BIOS.
      The search for E800 will give us many false positives, due to
      E8 being the NEAR CALL opcode.  If the BIOS is at E800, it
      probably was designed to be relocatable and therefore does not
      need to be translated.

|

	 mov	 ax,BIOS_DEST	; Get destination address
	 mov	 BIOS_ADDRESS,ax ; This is where the BIOS lies now

	 cmp	 BIOS_SRC,0E800h ; Is the source at E800?
	 je	 short @F	; Jump if so

	 call	 SEARCH_BIOS	; Translate the BIOS (no error return)
				; Always returns successfully
	 call	 XLAT_SPECIAL	; Translate the special cases

@@:
	 call	 CHECK_WGS6386	; This one needs a special patch
	 call	 CHECK_SPEEDSTAR ; This one needs a special patch

	 jmp	 short MAXLAT_CLC ; Join common exit code

;-----------
MAXLAT_ERROR:
	 stc			; Unknown function request (or error)

	 jmp	 short MAXLAT_EXIT ; Join common exit code

;-----------
MAXLAT_CLC:
	 clc			; Mark as success

;;;;;;;; jmp	 short MAXLAT_EXIT ; Join common exit code
;;;;;;;;
;-----------
;;;MAXLAT_STC:
;;;;;;;; stc			; Mark as failure
;;;;;;;;
;;;;;;;; jmp	 short MAXLAT_EXIT ; Join common exit code

;----------
MAXLAT_EXIT:
	 REGREST <es,ds,si,dx,ax> ; Restore registers
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MAXLAT endp			; End MAXLAT procedure

;***************************************************************************

	 NPPROC  TRANSLATE -- The XLAT Program
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Search through the BIOS translating addresses.
Used for VGASWAP testing.

|
.8086

	 lea	 sp,LCLSTKZ	; Switch to local stack

	 call	 CHECK_CPUID	; Ensure running on 386 or greater
	 jnc	 short @F	; Jump if 386 or greater

	 DOSCALL @STROUT,MSG_NOT386 ; Tell 'em the bad news

	 jmp	 near ptr TRANSLATE_EXIT ; Join common exit code

; N.B. We cannot use any 386 instructions before this point

CODE	 ends
.386p
CODE	 segment		; Ensure @WordSize = 2

@@:
	 or	 LCL_FLAG,@LCL_CMDLINE ; Called from DOS command line
	 and	 LCL_FLAG,(not @LCL_MODIFY1) ; Don't modify BIOS by default

; Calculate start of buffer

	 lea	 ax,ZTAIL[16-1] ; Get offset of tail (rounded up)
	 shr	 ax,(4-0)	; Convert from bytes to paras
	 mov	 bx,cs		; Get our own segment
	 add	 ax,bx		; Add to get segment of buffer
	 mov	 MAPSEG_NXT,ax	; Save for later use
	 mov	 BIO_SEG,ax	; Save for later use

; Determine probable Video BIOS segment

	 call	 GET_VIDEO_SEG	; Set video segment (ignore failure)

; Check for command line arguments

	 call	 CHECK_PARMS	; Read command line
	 jc	 near ptr TRANSLATE_EXIT ; Do not run program (if CF=1)

; Did the user ask us to display a BIOS?

	 test	 LCL_FLAG,(@LCL_DISPLAY) ; Display BIOS mode?
	 jz	 short @F	; Jump if not

	 call	 DISPLAY_BIOS	; Call SWAT to display BIOS

	 jmp	 near ptr TRANSLATE_EXIT ; All done

@@:

; Did the user ask us to load and execute the BIOS?

	 test	 LCL_FLAG,(@LCL_EXECUTE); Are we to execute the BIOS
	 jz	 short @F	; Jump if not

	 call	 EXECUTE_BIOS	; Call SWAT to execute BIOS
	 jc	 near ptr TRANSLATE_EXIT ; Jump if error

	 jmp	 near ptr TRANSLATE_TSR ; Jump to TSR exit code

@@:

	 call	 VALID_BIOS	; Determine BIOS validity (55AA search)
				; Return ROMLEN in AX

	 call	 TEST_VGASWAP	; Test for VGASWAP compatibility

; Did the user request any command line options?

	 test	 LCL_FLAG,@LCL_OPTION ; Any options specified?
	 jnz	 short @F	; Jump if so

	 DOSCALL @STROUT,MSG_COPY ; Display the copyright message
	 DOSCALL @STROUT,MSG_HELP ; Tell 'em its an internal program only

	 jmp	 near ptr TRANSLATE_EXIT ; All Done
@@:

; Calculate the CRC of the source BIOS

	 push	 BIOS_ADDRESS	; Pass the start in paras
	 push	 CON24K 	; Pass the length in bytes
	 call	 CALC_CRC	; Calculate the CRC into AX
	 mov	 BIOS_CRC,ax	; Save CRC for later

; Use the CRC as part of the filename

;;;;;;;; mov	 ax,BIOS_CRC	; Get CRC value
	 lea	 di,FILECRC	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

; If we are capturing a BIOS to disk, get the filename into buffer
; and open the .CFG file for writing.
; (This must be done after the CRC calculations above)

	 test	 LCL_FLAG,@LCL_WRITE ; Write .BIO file to disk?
	 jz	 short @F	; Jump if not

	 lea	 si,FILEDEF	; Our file name
	 lea	 di,FILEBUF	; New file name
	 mov	 cx,@FILELEN	; Length of file name
S16  rep movsb			; Copy it

	 call	 OPEN_CFG	; Open CFG file
@@:

; ---------------------------------------------------------------------------
; The .CFG File has been created at this point
; Any output sent to CON will also be sent to the .CFG file
; This will only happen, of course, via the DISPLAY subroutine
; ---------------------------------------------------------------------------

; Display the copyright message

	 lea	 dx,MSG_COPY	; Address of message
	 mov	 cx,@MSG_COPYLEN ; Length of message
	 call	 DISPLAY	; Display the opening message

; Display results of VGASWAP testing

	 mov	 dx,PTR_MSG_VGASWAP ; Get pass/fail message
	 mov	 cx,@MSG_VGASWAP_LEN ; Message length
	 call	 DISPLAY	; Display it

; Get any user input comments

	 test	 LCL_FLAG,@LCL_WRITE ; Writing .BIO file to disk?
	 jz	 short @F	; Jump if not

	 call	 GET_COMMENTS	; Get user's comments
@@:

; Determine BIOS address validity

	 call	 VALID_BIOS	; Determine BIOS validity (55AA search)
				; Return ROMLEN in AX

; Determine if 386MAX is present (and get INFO structure)

	 call	 MAX_PRESENT	; Is MAX present?
	 jnc	 short @F	; Jump if MAX is present

	 and	 LCL_FLAG,(not @LCL_MODIFY1) ; We can't modify BIOS
@@:

; Check to see if we are running on a VGA (or above)

	 call	 IZITVGA	; Is this a VGA or above?
	 cmp	 ax,-1		; Is a VGA present?
	 je	 short @F	; Jump if not

	 or	 LCL_FLAG,@LCL_VGA ; VGA or above is present
	 mov	 MIN_LENGTH,32*1024 ; Minimum BIOS length is 32KB for VGA
@@:

; Ensure BIOS is Read/Write

	 mov	 al,@READWRITE	; Make Read/Write function
	 call	 WROM		; Call WROM routine

; Determine all the data structures within the video BIOS

	 call	 GET_DATA	; Get all the data addresses
				; Also fill in text in VOID structure

; Determine the length of the BIOS

	 call	 CHECK_CPQ386	; If this is a COMPAQ, we should be able
				; to trust the ROM ID lengths

	 call	 CALC_LENGTH	; Get the video BIOS length

; Scan the BIOS for our search string, noting which should
; be translated, and which should not be translated.
; If requested, replace all string occurrences that should
; be translated with the replacement string.

	 call	 SEARCH_BIOS	; Search throughout the BIOS
				; and optionally modify it

; Find the BIOS entry points

	 call	 SRCH_INT	; Find the BIOS entry points
	 call	 XLAT_SPECIAL	; Translate the special cases
	 call	 CALC_CACHE_LEN ; Calculate the caching length of the BIOS

; Ensure BIOS is Read Only

	 mov	 al,@READONLY	; Make Read Only function
	 call	 WROM		; Call WROM routine

; Display final messages

	 mov	 ax,XLAT_COUNTER ; Get total count of transformations
	 lea	 di,MSG_COUNT1 ; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 lea	 dx,MSG_COUNT	; Address of above message
	 mov	 cx,@MSG_COUNT_LEN ; Length of messge
	 call	 DISPLAY	; Display the search count

	 mov	 ax,BIOS_ADDRESS ; Get address of BIOS
	 lea	 di,MSG_ADDR	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,BIOS_SRC	; Get Search string
	 lea	 di,MSG_SEARCH	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,BIOS_DEST	; Get replacement string
	 lea	 di,MSG_REPL	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,BIOS_LEN	; Get BIOS length
	 lea	 di,MSG_LEN	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,BIOS_CRC	; Get CRC value
	 lea	 di,MSG_CRC	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 lea	 dx,MSG_RESULTS ; Display results message
	 mov	 cx,@MSG_RESULTS_LEN ; Message length
	 call	 DISPLAY	; Display it

	 test	 LCL_FLAG,@LCL_MODIFY2 ; Did we modify the BIOS?
	 jz	 short @F	; Jump if not

	 DOSCALL @STROUT,MSG_MODIFY ; Let 'em know we modified the BIOS
@@:

; Write the CFG file and BIO file to disk

	 test	 LCL_FLAG,@LCL_WRITE ; Write .BIO file to disk?
	 jz	 short @F	; Jump if not

	 call	 CLOSE_CFG	; Close the file

	 call	 WRITE_BIO	; Capture the BIOS to disk
@@:

	 jmp	 short TRANSLATE_EXIT ; Join common exit code

TRANSLATE_TSR:
	 xor	 al,al		; Return code
	 mov	 dx,64*1024/16	; Resident size in paras
	 DOSCALL @KEEPRC	; Terminate process and remain resident, exit code in AL

TRANSLATE_EXIT:
	 xor	 al,al		; Return code
	 DOSCALL @EXITRC	; Exit process with return code in AL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TRANSLATE endp			; End XLAT procedure

;***************************************************************************

	 NPPROC  CHECK_CPUID -- Check On CPU Identifier
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're running on an 80386 or later processor.

On exit:

CF	 =	 0 if 386 or greater
	 =	 1 otherwise

|
.8086

	 REGSAVE <ax>		; Save register

	 push	 sp		; First test for earlier than a 286
	 pop	 ax		; 286 (and greater) decrements the SP
				; before pushing.

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
	 stc			; Indicate 286 or earlier

CHECK_CPUID_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPUID endp		; End CHECK_CPUID procedure

CODE	 ends
.386p
CODE	 segment		; Ensure @WordSize = 2

;***************************************************************************

	 NPPROC  GET_VIDEO_SEG -- Find probable video segment
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Find probable video segment and place it in BIOS_ADDRESS.

This routine should come before command line processing so that
the user may over ride this automatic detection.

On exit :
BIOS_ADDRESS =	updated if an address is available.
CF	=	0 indicates success
		1 indicates failure

|

	 REGSAVE <es>		; Save register
	 pusha			; Save all GP registers

; Determine address of BIOS by getting FONT address

	 mov	 bh,2		; Get address of Font 8x14
	 mov	 ax,1130h	; Function 11, Subfunc 30

	 int	 10h		; Ask the Video BIOS
	 assume  es:nothing	; Tell the assembler about it

	 mov	 dx,es		; Save address of BIOS

	 cmp	 dx,@LOWEST_ROM ; Compare to lowest ROM address
	 jae	 short GET_VIDEO_SEG_FOUND ; Jump if it's in ROM
					   ; (Note CF=0)

; Determine address of BIOS by getting segment of EGA Save Pointer

	 mov	 ax,seg BIOSDATA ; Prepare to address the BDA
	 mov	 es,ax		; Address it
	 assume  es:BIOSDATA	; Tell the assembler about it

	 mov	 dx,SAVE_PTR.VSEG ; Get segment of save pointer

	 cmp	 dx,@LOWEST_ROM ; Compare to lowest ROM address
	 jae	 short GET_VIDEO_SEG_FOUND ; Jump if it's in ROM
					   ; (Note CF=0)

; Determine address of BIOS be getting Segment of DCC table

	 les	 si,SAVE_PTR	; EGA save pointer -> ES:DI
	 assume  es:nothing	; Tell the assembler about it

	 les	 si,es:[si+EGASAVE_2ND] ; Secondary VGA Save Ptr -> ES:SI
	 assume  es:nothing	; Tell the assembler about it

	 mov	 dx,es:[si+VGASAVE_DCC].VSEG ; Get segment of DCC

	 cmp	 dx,@LOWEST_ROM ; Compare to lowest ROM address
	 jb	 short GET_VIDEO_SEG_EXIT ; Jump if ROM can't be found
					   ; (Note CF=1)

GET_VIDEO_SEG_FOUND:
	 mov	 BIOS_ADDRESS,dx ; New Address of BIOS
	 clc			; Mark as success

GET_VIDEO_SEG_EXIT:
	 popa			; Restore all GP registers

	 REGREST <es>		; Restore registers
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_VIDEO_SEG	 endp			; End GET_VIDEO_SEG_PROC procedure

;***************************************************************************

	 NPPROC  CHECK_PARMS -- Read the command line
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Read command line parameters

|

	 REGSAVE <ax,dx,si>	; Save registers


	 lea	 si,PSP_PARM_STRING ; DS:SI ==> parameter string
SKIPWHITE:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 short SKIPWHITE ; Jump if so

	 cmp	 al,TAB 	; Izit white space?
	 je	 short SKIPWHITE ; Jump if so

	 cmp	 al,'?'         ; Izit a request for help?
	 je	 short XLAT_HELP ; Jump if so

	 cmp	 al,'/'         ; Izit switch character?
	 jne	 short CHECK_PARMS_CLC	; Jump if not

	 call	 SWPROC 	; Process switch character at DS:SI
	 jc	 short XLAT_HELP ; Jump if invalid character

	 jmp	 short SKIPWHITE ; Go around again

XLAT_HELP:
	 DOSCALL @STROUT,MSG_COPY ; Display the flag
	 DOSCALL @STROUT,MSG_HELP ; Display help message

	 stc			; Indicate command line parsing error

	 jmp	 short CHECK_PARMS_EXIT ; Join common exit code

CHECK_PARMS_CLC:
	 clc			; Mark as successful

CHECK_PARMS_EXIT:

	 REGREST <si,dx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PARMS	 endp			; End CHECK_PARMS procedure

;*************************************************************************

	 NPPROC  SWPROC -- Process Switch Character
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process switch character

On entry:

DS:SI	 ==>	 switch character

On exit:

CF	 =	 1 if valid switch character
	 =	 0 otherwise

DS:SI	 ==>	 (updated)

|

	 REGSAVE <ax>		; Save registers

	 or	 LCL_FLAG,@LCL_OPTION ; A user option has been specified

	 lodsb			; Get switch character
	 call	 LOWERCASE	; Convert to common case

	 cmp	 al,'x'         ; Null parameter (will set the LCL_OPTION bit)
	 jne	 short @F	; Jump if not

	 clc			; Mark as successful

	 jmp	 near ptr SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'a'         ; Izit BIOS address?
	 jne	 short @F	; Jump if not

	 call	 HEX2BIN	; Convert ASCII hex at DS:SI to binary in AX
	 mov	 BIOS_ADDRESS,ax ; Store as address of BIOS

	 clc			; Mark as successful

	 jmp	 near ptr SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'l'         ; Izit BIOS length?
	 jne	 short @F	; Jump if not

	 call	 HEX2BIN	; Convert ASCII hex at DS:SI to binary in AX
	 mov	 BIOS_LEN,ax	; Store as ROM length

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'s'         ; Izit Source address?
	 jne	 short @F	; Jump if not

	 call	 HEX2BIN	; Convert ASCII hex at DS:SI to binary in AX
	 mov	 BIOS_SRC,ax ; Store as search string

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'r'         ; Izit Destin address?
	 jne	 short @F	; Jump if not

	 call	 HEX2BIN	; Convert ASCII hex at DS:SI to binary in AX
	 mov	 BIOS_DEST,ax	; Store as destin of move
	 or	 LCL_FLAG,@LCL_MODIFY1 ; Permission to modify the BIOS

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'d'         ; Izit display the BIOS?
	 jne	 short @F	; Jump if not

	 lodsb			; Get next character

	 cmp	 al,'='         ; Is filename specified?
	 jne	 short SWPROC_ERR ; Error if not

	 or	 LCL_FLAG,@LCL_DISPLAY ; Display the BIOS only

	 call	 GET_FILENAME	; Get file name of BIOS to display

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'e'         ; Izit Execute the BIOS?
	 jne	 short @F	; Jump if not

	 lodsb			; Get next character

	 cmp	 al,'='         ; Is filename specified?
	 jne	 short SWPROC_ERR ; Error if not

	 or	 LCL_FLAG,@LCL_EXECUTE ; Execute the BIOS only

	 call	 GET_FILENAME	; Get file name of BIOS to display

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'w'         ; Izit 'Write File' commnad?
	 jne	 short @F	; Jump if not

	 or	 LCL_FLAG,@LCL_WRITE ; Permission to write BIO file

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'t'         ; Izit 'Test for VGASWAP compatibility'?
	 jne	 short @F	; Jump if not

	 or	 LCL_FLAG,@LCL_VGASWAP ; Only testing for VGASWAP compatiblity

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code

@@:
SWPROC_ERR:
	 stc			; Mark as invalid
SWPROC_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SWPROC	 endp			; End SWPROC procedure

;***************************************************************************

	 NPPROC  CHECK_CPQ386 -- CHECK_CPQ386 Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

On true COMPAQ video ROMs, trust the video ROM length identifier.
However, we have to tally up the lengths of all ROMs within the first 32 KB
since we are not automatically assuming a 32 KB length

Check for specific COMPAQ 386 machines
* Test MAX's system flag for the COMPAQ bit
* Check for COMPAQ video BIOS signature
* Check for COMPAQ specific interrupt handler

On exit:
MIN_LENGTH may be updated (from 32 KB to the ROM marker length)

|

	 REGSAVE <ax,bx,cx,dx,es> ; Save registers

; Are we running on a COMPAQ machine?

	 test	 SYSTEM_FLAG,@SYS_CPQ ; Is it a COMPAQ Deskpro 386/486?
	 jz	 short CHECK_CPQ386_EXIT ; Jump if not

; Are we running with a genuine COMPAQ video board? (signature check)

	 mov	 es,BIOS_ADDRESS ; Address the video BIOS via ES
	 assume  es:nothing	; Tell the assemblera bout it

	 cmp	 es:[5FEAh].EDD,'PMOC' ; Is it the COMPAQ video signature?
	 jne	 short CHECK_CPQ386_EXIT ; Jump if not

	 cmp	 es:[5FEAh+4h].ELO,'QA' ; Is it the COMPAQ video signature?
	 jne	 short CHECK_CPQ386_EXIT ; Jump if not

; Are we running with a genuine COMPAQ video board? (interrupt check)

; If video BIOS is genuine COMPAQ, CX will return some value guaranteed
; by COMPAQ's video BIOS programmers to be other than FFFF.  This is how
; COMPAQ's own programs determine if there is a genuine COMPAQ video BIOS
; present.

	 REGSAVE <ds,es>	; Save registers (a little paranoia)

	 mov	 ax,0BF03h	; COMPAQ Get video environment function
	 xor	 bx,bx		; Unused parameter (should be zero)
	 mov	 cx,-1		; CX will be modified if true COMPAQ video
	 int	 10h		; Call the video BIOS
	 assume  ds:nothing	; Just in case the BIOS screws us
	 assume  es:nothing	; ...
				; Return BH = Active monitor
				;	 BL = Master mode
				;	 CH = 0 (reserved)
				;	 CL = Switchable VDU mode supported
				;	 DH = Internal monitor type
				;	 DL = External monitor type

	 REGREST <es,ds>	; Restore registers
	 assume  ds:PGROUP	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 cx,-1		; Was anyone home?
	 je	 short CHECK_CPQ386_EXIT ; Jump if not COMPAQ video BIOS

; Since we're going to trust the ROMLEN value on a COMPAQ,
; and not automatically assume it is a 32 KB ROM, we have to ensure
; that the minimum length includes the the secondary ROM (if any)

; If present, the secondary ROM will probably be at C680-C700 (for 2 KB)
; or C680-C800 (for 6 KB)

; ES ==> Primary video ROM

	 xor	 bx,bx		; Initialize offset within 32 KB block

CHECK_CPQ386_NEXT1:
	 mov	 cx,bx		; Tally in another video ROM

CHECK_CPQ386_NEXT2:
	 cmp	 es:[bx].ROMSIGN,0AA55h ; Is it a ROM? (primary or secondary)
	 je	 short CHECK_CPQ386_ROM ; Jump if so

	 add	 bx,16		; Skip to next paragraph

	 cmp	 bx,(32*1024)	; At end of search?
	 jb	 short CHECK_CPQ386_NEXT2 ; Jump if not

	 jmp	 short CHECK_CPQ386_DONE ; Join common code

CHECK_CPQ386_ROM:
	 movzx	 ax,es:[bx].ROMLEN ; Get BIOS size (in 512 blocks)
	 shl	 ax,(9-0)	; Convert from 512 bytes to bytes

	 add	 bx,ax		; Add ROM size to get new offset

	 cmp	 ax,32*1024	; At end of 32 KB block?
	 jb	 short CHECK_CPQ386_NEXT1 ; Jump if more to check
	 ja	 short CHECK_CPQ386_DONE ; Jump if above 32 KB
				; (last ROM must not be video)

CHECK_CPQ386_FORCE32:
	 mov	 cx,(32*1024)	; The ROM is 32 KB long

CHECK_CPQ386_DONE:

; We're on a true COMPAQ video ROM, trust the ROM ID length byte

	 mov	 MIN_LENGTH,cx	; All COMPAQs have honest ROM ID lengths
				; (but some might have 2 ROM IDs)

CHECK_CPQ386_EXIT:
	 REGREST <es,dx,cx,bx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assemblera bout it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPQ386	 endp			; End CHECK_CPQ386 procedure

;*****************************************************************************

	  NPPROC  GET_FILENAME -- Get filename from the command line
	  assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Get file name of BIOS that we are going to display.

On entry :	DS:SI => Command line parameter (file name)

On exit  :	BIOS_FNAME is updated

|

	 REGSAVE <ax,di>	; Save registers

	 lea	 di,BIOS_FNAME	; Address of destin file name

; Copy file name to destination

GET_FILENAME_NEXT:

	 lodsb			; Get next command line character

	 cmp	 al,' '         ; Izit white space?
	 je	 short GET_FILENAME_DONE ; jump if so

	 cmp	 al,TAB 	; Izit white space?
	 je	 short GET_FILENAME_DONE ; jump if so

	 cmp	 al,'/'         ; Izit a separator?
	 je	 short GET_FILENAME_DONE ; jump if so

	 cmp	 al,CR		; Izit a CR
	 je	 short GET_FILENAME_DONE ; jump if so

	 cmp	 al,LF		; Izit a LF?
	 je	 short GET_FILENAME_DONE ; jump if so

S16	 stosb			; Store the character

	 jmp	 short GET_FILENAME_NEXT ; Get next charactrer

GET_FILENAME_DONE:
	 dec	 si		; Skip back one (in command line)

	 REGREST <di,ax>	; Restore registers

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_FILENAME endp			 ; End GET_FILENAME procedure

;*****************************************************************************

	  NPPROC  GET_COMMENTS -- Get user comments
	  assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Get user comments from the keyboard and append to .CFG file

|

	 REGSAVE <ax,cx,dx,di> ; Save Registers

; Display user prompt

	 DOSCALL @STROUT,MSG_COMMENT ; Ask user for comment

; Read in user's comment

	 mov	 KBD_BUFF,80	; Set MAX # bytes to read in
	 DOSCALL @BKEYIN,KBD_BUFF ; Buffered keyboard input

; Add LF to string

	 movzx	 di,KBD_BUFF+1	; Get number of characters actually entered
	 mov	 KBD_BUFF[di]+2+1,LF ; Place LF at buffer's end

; Add $ to front of string so that it will not disply on the screen

	 mov	 KBD_BUFF+1,EOS ; Blast EOS in front of string

; Send comments to .CFG file

	 lea	 dx,KBD_BUFF+2-1 ; Start of buffer (-1 to include EOS)
	 mov	 cx,di		; Number of bytes in string
	 add	 cx,3		; Add CR,LF,and initial EOS to count

	 call	 DISPLAY	; Send it to the file

	 REGREST <dx,di,cx,ax> ; Restore Registers

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_COMMENTS endp		 ; End GET_COMMENTS procedure

;*****************************************************************************

	  NPPROC  VALID_BIOS -- Determine if BIOS is valid
	  assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Determine if the presumed BIOS address has a BIOS signature.
If not, display a warning message, but continue on.

Also get and display the BIOS length (if it is a valid BIOS)

On exit:
AX	=	Rom length in bytes
		0 if no BIOS signature

|

	 REGSAVE <cx,dx,di,fs>	; Save Registers

	 mov	 fs,BIOS_ADDRESS ; Address the alleged ROM
	 assume  fs:ROMSEG	; Tell the assembler about it

	 cmp	 ROMSIGN,0AA55h ; Izit a ROM?
	 je	 short VALID_BIOS_SIGOK ; Jump if so

; Address does not contain a valid ROM signature

	 mov	 ax,BIOS_ADDRESS ; Get presumed BIOS address
	 lea	 di,MSG_XBIOS1	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 lea	 dx,MSG_XBIOS	; Display 'Not a BIOS' message
	 mov	 cx,@MSG_XBIOS_LEN ; Message length
	 call	 DISPLAY	; Display it

	 xor	 ax,ax		; ROM length is 0 for invalid ROM IDs

	 jmp	 short VALID_BIOS_EXIT ; Join common exit code

VALID_BIOS_SIGOK:

; Address does contain a valid BIOS signature,
; Display the BIOS size (in 512 byte units)

	 mov	 al,ROMLEN	; Get BIOS size
	 lea	 di,MSG_ROMLENGTH ; Format string address
	 call	 FMT_BYTE	; Format AL -> ES:DI

	 shl	 ax,(9-0)	; Convert from 512 bytes to bytes

VALID_BIOS_EXIT:

	 REGREST <fs,di,dx,cx>	; Restore Registers
	 assume  fs:nothing	; Tell the assembler about it

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VALID_BIOS endp 		 ; End VALID_BIOS procedure

;*************************************************************************

	 NPPROC  MAX_PRESENT -- Check for 386MAX device presence
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Determine if MAX is present.
Then determine if our minimum version of MAX is present.

Also grab the PORT67 value.

On exit:
CF	=	0 if MAX is present
		1 if MAX is not present

|

	 REGSAVE <eax,bx,cx,dx> ; Save caller's registers

	 mov	 DEV_HNDL,0	; Initialize handle in case of error

	 mov	 al,02h 	; R/W access
	 DOSCALL @OPENF2,DEVNAME_MAX ; Attempt to open 386MAX device driver
	 jnc	 short MP_OK1	; Skip error code if open

MP_NOMAX:
	 lea	 dx,MSG_NOMAX	; Address of message
	 mov	 cx,@MSG_NOMAX_LEN ; Byte count
	 call	 DISPLAY	; Diplay the MAX not installed message

	 jmp	 short MP_ERRXIT ; Join common error exit code

MP_BADVER:
	 lea	 dx,MSG_BADVER	; Address of message
	 mov	 cx,@MSG_BADVER_LEN ; Byte count
	 call	 DISPLAY	; Diplay the Font address

	 jmp	 short MP_ERRXIT ; Join common error exit code
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
	 mov	 cx,@INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

; Make sure it's us and versions are in order

	 cmp	 INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short MP_NOMAX ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short MP_NOMAX ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short MP_NOMAX ; Not this time

	 cmp	 INFO.INFO_VER[0],'6' ; Izit minimum version supporting VGASWAP?
	 jb	 short MP_BADVER ; Not this time

	 mov	 ax,INFO.INFO_P67 ; I/O port number for EMM2 functions
	 mov	 PORT67,ax	; Save for EMMOUT macro

	 mov	 eax,INFO.INFO_SYS ; System ID flags
	 mov	 SYSTEM_FLAG,eax ; Save for later use

	 test	 LCL_FLAG,@LCL_VGASWAP ; Testing for VGASWAP compatibility?
	 jnz	 short @F	; Jump if so

	 lea	 dx,MSG_MAXOK	; Address of message
	 mov	 cx,@MSG_MAXOK_LEN ; Byte count
	 call	 DISPLAY	; Diplay the MAX installed message
@@:
	 clc			; Indicate 386MAX is installed

	 jmp	 short MP_XIT	; Join common exit code

MP_ERRXIT:
	 stc			; Indicate something failed

MP_XIT:
	 pushf			; Save return code

	 mov	 bx,DEV_HNDL	; Get device handle

	 or	 bx,bx		; Is it open?
	 jz	 short @F	; Jump if not

	 DOSCALL @CLOSF2	; Close file, handle in BX
@@:
	 popf			; Restore return code

	 REGREST <dx,cx,bx,eax> ; Restore caller's registers

	 ret			; ... to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
MAX_PRESENT endp		; End of MAX_PRESENT routine


;***************************************************************************

	  NPPROC  GET_DATA -- Get all the data addresses
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Get the addresses and lengths of the fonts (and other data tables).
If any address inside of these 11 data structures contains a C000,
we will not convert it.  This data is usually a bitmap or some other
C000, but it is not a hard coded address.

On exit :
Always returns successfully

|

	 REGSAVE <es>		; Save register
	 pusha			; Save all GP registers

	 mov	 bh,2		; ROM Font 8x14
	 mov	 si,14*256	; Size of font
	 and	 LCL_FLAG,(not @LCL_SUPPFONT) ; Normal font
	 call	 GET_FONT	; Get address range

	 mov	 bh,3		; ROM Font 8x8 (lower half)
	 mov	 si,8*128	; Size of font
	 and	 LCL_FLAG,(not @LCL_SUPPFONT) ; Normal font
	 call	 GET_FONT	; Get address range

	 mov	 bh,4		; ROM Font 8x8 (top half)
	 mov	 si,8*128	; Size of font
	 and	 LCL_FLAG,(not @LCL_SUPPFONT) ; Normal font
	 call	 GET_FONT	;  Get address range

	 mov	 bh,5		; ROM Font 9x14 supplemental
	 mov	 bl,14+1	; Bytes per character (for each cell)
	 mov	 si,0		; Dyanmic font size
	 or	 LCL_FLAG,@LCL_SUPPFONT ; Supplemental font
	 call	 GET_FONT	; Get address range

	 test	 LCL_FLAG,@LCL_VGA ; Are we running under VGA or above
	 jz	 short GETDATA_XVGA ; Jump if not

	 mov	 bh,6		; ROM Font 8x16
	 mov	 si,16*256	; Size of font
	 and	 LCL_FLAG,(not @LCL_SUPPFONT) ; Normal font
	 call	 GET_FONT	; Get address range

	 mov	 bh,7		; ROM Font 9x16 supplemental
	 mov	 bl,16+1	; Bytes per character (for each cell)
	 mov	 si,0		; Dyanmic font size
	 or	 LCL_FLAG,@LCL_SUPPFONT ; Supplemental font
	 call	 GET_FONT	; Get address range

GETDATA_XVGA:

; Get the Default Parameter Table's address

	 call	 PARAM_TABLE	; Get address of Default Parameter Table
				; Also the extended DPT

; Get the Save Pointer's address

	 call	 GET_EGASAVEPTR ; Get the address of both Save Pointers

; Get the Display Combination Code's (DCC) address

	 call	 GET_DCC	; Get DCC's address

	 call	 GET_DUALROM	; See if there's a dual ROM at C000 and elsewhere
				; Ignore return code
	 or	 LCL_FLAG,@LCL_GETDATA ; Indicate we just executed GET_DATA

	 popa			; Restore all GP registers

	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_DATA endp			; End GET_DATA procedure

;*****************************************************************************

	 NPPROC  GET_DUALROM -- Get Dual ROM State
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get dual ROM state

|

	 REGSAVE <ax,bx,cx,si,di,ds,es> ; Save registers

	 smsw	 ax		; Get MSW

	 test	 ax,mask $PE	; Izit in Pass 2?
	 jnz	 short GET_DUALROM_EXIT ; Jump if so

	 mov	 ax,0C000h	; Get the segment

	 cmp	 ax,BIOS_SRC	; Izit at C000?
	 je	 short GET_DUALROM_EXIT ; Jump if so

	 cmp	 ax,BIOS_DEST	; Izit at C000?
	 je	 short GET_DUALROM_EXIT ; Jump if so

; See if the two ROMs are close enough

	 mov	 es,BIOS_ADDR2	; It's pass1
	 assume  es:RGROUP	; Tell the assembler about it

	 mov	 ds,BIOS_SRC	; Address the other ROM
	 assume  ds:nothing	; Tell the assembler about it

	 movzx	 cx,ROMLEN	; Get ROM length in 512-bytes
	 shl	 cx,(9-0)	; Convert from 512-bytes to bytes
	 lea	 di,ROMSIGN	; ES:DI ==> ROM at C000 (or B000)

@FLEX_MISMATCH	 equ	 100	; Number of allowed mismatches

	 xor	 bx,bx		; Zero the match counter
	 mov	 si,di		; DS:SI ==> ROM at E000

	 push	 cx		; Save ROM length in bytes
CHK_SHDROM_NEXT:
	 cmps	 ds:[si].LO,RGROUP:[di].LO ; Compare 'em
	 jnz	 short @F	; Jump if not the same

	 inc	 bx		; Count in one more match
@@:
	 loop	 CHK_SHDROM_NEXT ; Check next byte

	 pop	 cx		; Restore ROM length in bytes

	 add	 bx,@FLEX_MISMATCH ; Add allotment of mismatches

	 cmp	 bx,cx		; Compare our match counter with BIOS length
	 jb	 short GET_DUALROM_EXIT ; Jump if not enough matches

	 mov	 ax,cs		; Get PGROUP segment
	 mov	 ds,ax		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 or	 BIOS_FLAG,@BIOS_C000 ; Mark for next time
GET_DUALROM_EXIT:
	 REGREST <es,ds,di,si,cx,bx,ax> ; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_DUALROM endp		; End GET_DUALROM procedure

;*****************************************************************************

	  NPPROC  GET_FONT -- Get a FONT's address and range
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Determine the address range of a video font.

On entry:
BH	=	Font number (2-7)
BL	=	# of bytes per character (supp fonts only)
SI	=	Number of bytes in font (if not supplemental font)

On exit:	VOID Data structure is filled in

|

	 REGSAVE <es>	; Save registers
	 pusha		; Save all GP registers

; Get the font address

	 REGSAVE <bx,si>	; Save registers

	 mov	 ax,1130h	; Function 11, Subfunc 30, font # in BH
	 int	 10h		; Get address of font into ES:BP
	 assume  es:nothing	; Tell the assembler about it

	 REGREST <si,bx>	; Restore registers

	 test	 LCL_FLAG,@LCL_SUPPFONT ; Izit a supplemental font?
	 jz	 short NOT_SUPP ; Jump if not

; Calculate the size (if supplemental font)

	 REGSAVE <bp,es>	; Save registers

	 mov	 si,BIOS_ADDRESS ; Get Address of new BIOS
	 mov	 es,si		; And prepare to address new BIOS
	 assume  es:nothing	; Tell the assembler about it

	 xor	 bh,bh		; Extend char size to 16 bits
	 mov	 si,(0+1)	; Initialize font size counter and
				; ... include trailing NULL

SUPP_NEXT:
	 mov	 al,es:[bp]	; Get first character of supp. font

	 or	 al,al		; Izit the end of the list?
	 jz	 short SUPP_END ; Jump if so

	 add	 si,bx		; Add in one more character
	 add	 bp,bx		; Point to next character (in the BIOS)

	 jmp	 short SUPP_NEXT ; Get next character in supp. font

SUPP_END:
	 REGREST <es,bp>	; Restore registers
	 assume  es:nothing	; Tell the assembler about it

NOT_SUPP:

; Display font information

	 mov	 ax,es		; Get segment of Font

	 push	 ds		; Get our data segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; tell the assembler about it

; Save font addresses in our table

	 mov	 bx,VOID_PTR	; Address the Font table structures
	 mov	 VOID[bx].DATA_SEG,ax ; Save Font segment
	 mov	 VOID[bx].DATA_START,bp ; Save Font offset
	 mov	 VOID[bx].DATA_LEN,si	; Save Font length
	 add	 VOID_PTR,size DATA_STR ; Point to next entry

	 lea	 di, MSG_FONT1	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,bp		; Get Offset of Font
	 lea	 di, MSG_FONT2	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,si		; Get Font byte count
	 lea	 di, MSG_FONT3	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 lea	 dx,MSG_FONT	; Address of font message
	 mov	 cx,@MSG_FONT_LEN ; Byte count
	 call	 DISPLAY	; Diplay the Font address

	 popa			; Restore all GP registers

	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_FONT endp			 ; End GET_FONT procedure

;****************************************************************************

	 NPPROC  PARAM_TABLE -- Find the address of the Default Param table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Find the address of the Default Parameter Table
This table has 29 entries of 64 bytes each.

Find the size of the 'Extended' Default Paramter Table.
Its address is immediatelly following the DPT.

The Default Parameter Table usually has more than the 29 entries
defined by the VGA standard.  To determine the number of entries
covered by the 'Extended' DPT, we compare the first EDPT entry against
our model DPT entry to determine if they are similar.  If at least
a certain number of bytes match, we assume the entry is valid, and
analyze the next entry.

|

@DPT_SIZE	equ	64	; 64 bytes per entry for Default Parm Table

	 REGSAVE <es>		; Save register
	 pusha			; Save all GP registeres

; Address the BIOS data area

	 mov	ax,seg BIOSDATA ; Prepare to address the BDA
	 mov	es,ax		; Address it
	 assume es:BIOSDATA	; Tell the assembler about it

; Address the EGA Save Pointer

	 les	si,SAVE_PTR	; EGA Save Pointer -> ES:SI
	 assume es:nothing	; Tell the assembler about it

; Address the Default Parameter Table

	 les	si,es:EGASAVE_VPT[si] ; Default Param Table -> ES:SI
	 assume es:nothing	; Tell the assembler about it

; Save the Default Parm Table's location in our structure

	 mov	 bx,VOID_PTR	; Address the Font table structures
	 mov	 VOID[bx].DATA_SEG,es ; Save Segment
	 mov	 VOID[bx].DATA_START,si ; Save Offset
	 mov	 VOID[bx].DATA_LEN,29*64; Save Length of DPT
	 add	 VOID_PTR,size DATA_STR ; Point to next entry in table

	 call	 GET_EDPT	; Get length of 'Extended' table (into BP)
	 add	 si,@DPT_SIZE*29 ; Point to EDPT

; Save the Extended Default Parm Table's location in our structure

	 mov	 bx,VOID_PTR	; Address the Font table structures
	 mov	 VOID[bx].DATA_SEG,es ; Save Segment
	 mov	 VOID[bx].DATA_START,si ; Save Offset
	 mov	 VOID[bx].DATA_LEN,bp ; Save Length
	 add	 VOID_PTR,size DATA_STR ; Point to next entry in table

; Display the DPT characteristics

	 mov	 ax,es		; Get segment of table

	 push	 ds		; Get our data segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di, MSG_FONT1	; Format the segment
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,si		; Get Offset of Table
	 sub	 ax,29*64	; Subtract to get start of first table
	 lea	 di, MSG_FONT2	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,29*64	; Get byte count of DPT
	 lea	 di, MSG_FONT3	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 lea	 dx,MSG_FONT	; Address of first message
	 mov	 cx,@MSG_FONT_LEN ; Byte count
	 call	 DISPLAY	; Display it

; Display the extended DPT characteristics

	 mov	 ax,si		; Get Offset of first Table
	 lea	 di, MSG_FONT2	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,bp		; Get byte count of extended DPT
	 lea	 di, MSG_FONT3	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 lea	 dx,MSG_FONT	; Address of second message
	 mov	 cx,@MSG_FONT_LEN ; Byte count
	 call	 DISPLAY	; Display it

	 popa			; Restore all GP registers

	 REGREST <es>		; Restore register
	 assume  es:PGROUP	; Tell the assembler about it

	 ret		; Return

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARAM_TABLE endp			; End PARAM_TABLE procedure

;***************************************************************************

	 NPPROC  GET_EDPT -- GET_EDPT Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Check EDPT against our model.
Find the number of entries that match our model entry.

On entry :

ES:SI	=	Address of Default Parameter Table

On exit :

BP	=	Number of bytes in 'Extended' DPT.

|

@EDPT_MIN	equ	11h	; Minimum # of matches needed for success

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

	 add	 si,@DPT_SIZE*29 ; Plus size of normal DPT
	 xor	 dx,dx		; Number of matching entries

CM_NEXT_ENTRY:

	 xor	 bx,bx		; Number of matching bytes in entry
	 mov	 cx,@DPT_SIZE	; Number of bytes in model DPT
	 lea	 di,MODEL_DPT	; Our model DPT

CM_NEXT_BYTE:
	 lods	 es:[si].LO	; Get next byte of supposed DPT entry

	 cmp	 al,[di]	; Izit same as model?
	 jne	 short @F	; jump if not

	 inc	 bx		; One more byte that matches
@@:

	 inc	 di		; Next byte in model
	 loop	 short CM_NEXT_BYTE ; Check next byte

	 cmp	 bx,@EDPT_MIN	; We need at least this many matches
	 jl	 short CM_EXIT	; Jump if not enough matches

	 add	 dx,@DPT_SIZE	; Add length of another entry

	 jmp	 short CM_NEXT_ENTRY ; Process next entry

CM_EXIT:

	 mov	 bp,dx		; Return number of bytes in EDPT

	 REGREST <di,si,dx,cx,bx,ax> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_EDPT	 endp			; End GET_EDPT_PROC procedure

;*****************************************************************************

	 NPPROC  GET_EGASAVEPTR -- Find the address of the EGA Ptrs.
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

The EGA SavePtr table has 7 dword entries.
The VGA SavePtr table is variable.  The first word is a byte count.

Note: Maybe we should not include the Save Pointers in the VOID data.
      This way, if our Pointer relocation misses an instance of C000,
      we will capture it here.

|

@VGASAVEPTR_LEN equ (3*4)+2	; 3 dword pointers + length word

	 REGSAVE <ax,cx,si,di,fs>	; Save registers

; Address the BIOS data area

	 mov	 ax,seg BIOSDATA ; Prepare to address the BDA
	 mov	 fs,ax		; Address it
	 assume  fs:BIOSDATA	; Tell the assembler about it

; Address the EGA Save Pointer

	 lfs	 si,SAVE_PTR	; EGA Save Pointer -> FS:SI
	 assume  fs:nothing	; Tell the assembler about it

; Add EGA Save Pointer into list of bad addresses

	 mov	 bx,VOID_PTR	; Address the Font table structures
	 mov	 VOID[bx].DATA_SEG,fs ; Save Segment
	 mov	 VOID[bx].DATA_START,si ; Save Offset
	 mov	 VOID[bx].DATA_LEN,7*4 ; Save Length (7 dwords)
	 add	 VOID_PTR,size DATA_STR ; Point to next entry in table

; Display the address on the screen

	 mov	 ax,fs		; Get segment of table
	 lea	 di,MSG_FONT1	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,si		; Get Offset of Table
	 lea	 di,MSG_FONT2	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,7*4 	; Get Byte count of table (7 dwords)
	 lea	 di,MSG_FONT3	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 lea	 dx,MSG_FONT	; Address of message
	 mov	 cx,@MSG_FONT_LEN ; Byte count
	 call	 DISPLAY	; Display it

; Address the Secondary VGA Save Pointer

	 test	 LCL_FLAG,@LCL_VGA ; Are we running under VGA or above
	 jz	 short GET_EGASAVEPTR_EXIT ; Jump if not

	 lfs	 si,fs:EGASAVE_2ND[si] ; Secondary VGA Save Ptr -> FS:SI
	 assume  fs:nothing	; Tell the assembler about it

; N.B. The Secondary Save Ptr length is listed as 3 dwords (+ word index)
; We do not calculate the length dynamically because MAX does not do this,
; and one of the purposes of this program is to catch MAX's mistakes.

; Add Secondary VGA Save Pointer into list of bad addresses

	 mov	 bx,VOID_PTR	; Address the Font table structures
	 mov	 VOID[bx].DATA_SEG,fs ; Save Segment
	 mov	 VOID[bx].DATA_START,si ; Save Offset
	 mov	 VOID[bx].DATA_LEN,@VGASAVEPTR_LEN ; Save Length
	 add	 VOID_PTR,size DATA_STR ; Point to next entry in table

; Display the Address on the screen

	 mov	 ax,fs		; Get segment of table
	 lea	 di, MSG_FONT1	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,si		; Get Offset of Table
	 lea	 di, MSG_FONT2	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,@VGASAVEPTR_LEN ; Get Byte count of table
	 lea	 di, MSG_FONT3	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 lea	 dx,MSG_FONT	; Address of message
	 mov	 cx,@MSG_FONT_LEN ; Byte count
	 call	 DISPLAY	; Display it

GET_EGASAVEPTR_EXIT:
	 REGREST <fs,di,si,cx,ax> ; Restore registers
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_EGASAVEPTR endp			; End GET_EGASAVEPTR procedure

;*****************************************************************************

	 NPPROC  GET_DCC -- Find the address of the DCC
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

The length of the Display Combination Code Table
is of the following formula ...

Size of table = ((Byte 0) * 2) + 4

|

	 REGSAVE <ax,cx,si,di,fs> ; Save registers

	 test	 LCL_FLAG,@LCL_VGA ; Are we running under VGA or above
	 jz	 short GET_DCC_EXIT ; Jump if not

; Address the BIOS data area

	 mov	ax,seg BIOSDATA ; Prepare to address the BDA
	 mov	fs,ax		; Address it
	 assume fs:BIOSDATA	; Tell the assembler

; Address the EGA Save Pointer

	 lfs	si,SAVE_PTR	; EGA Save Pointer -> FS:SI
	 assume fs:nothing	; Tell the assembler about it

; Address the Secondary VGA Save Pointer

	 lfs	 si,fs:[si].EGASAVE_2ND ; Secondary VGA Save Ptr -> FS:SI
	 assume  fs:nothing	; Tell the assembler about it

; Address the DCC

	 lfs	 si,fs:[si].VGASAVE_DCC ; DCC -> FS:SI
	 assume  fs:nothing	; Tell the assembler about it

; Get the byte count of the DCC

	 movzx	 ax,fs:[si]	; Get the DCC entry count
	 shl	 ax,1		; Convert word count -> bytes
	 add	 ax,4		; Add 4 byte header

; Save DCC addresses in our table

	 mov	 bx,VOID_PTR	; Address the Font table structures
	 mov	 VOID[bx].DATA_SEG,fs ; Save DCC segment
	 mov	 VOID[bx].DATA_START,si ; Save DCC offset
	 mov	 VOID[bx].DATA_LEN,ax	; Save DCC length
	 add	 VOID_PTR,size DATA_STR ; Point to next entry

	 lea	 di, MSG_FONT3	; Format string address (byte count)
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,fs		; Get Segment of DCC table
	 lea	 di, MSG_FONT1	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 mov	 ax,si		; Get Offset of DCC
	 lea	 di, MSG_FONT2	; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 lea	 dx,MSG_FONT	; Address of font message
	 mov	 cx,@MSG_FONT_LEN ; Byte count
	 call	 DISPLAY	; Diplay the Font address

GET_DCC_EXIT:
	 REGREST <fs,di,si,cx,ax> ; Restore registers
	 assume  fs:nothing	; Tell the assembler about it

	 ret		; Return

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_DCC endp			; End GET_DCC procedure

;***************************************************************************

	 NPPROC  CALC_LENGTH -- CALC_LENGTH Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Get the BIOS logical length via calculations

Note: This routine MUST be called after GET_DATA has been processed.

Algorithm:
1) Get offset of highest data structure
2) Get length via ROMLEN
3) Take the greater of the two
4) Ensure length is minimum of 32KB

On exit:
BIOS_LEN is updated.

Note:
We do not have to calculate the addresses or lengths of the
following RAM based structres...
* Dynamic Save Area Pointer
* Alpha Mode Auxiliary Pointer
* Graphics Mode Auxiliary Pointer
* Secondary Alpha Mode Auxiliary Pointer
* User Palette Profile Table Pointer

|

	 REGSAVE <ax,bx,ecx,dx,es> ; Save registers

; Determine the address of the highest data structure within the BIOS

	 xor	 bx,bx		; Zero index into 'off limits' table
	 xor	 dx,dx		; Highest offset in segment

	 mov	 cx,BIOS_ADDRESS ; Get primary BIOS segment
	 shl	 ecx,(16-0)	; Move to upper word
	 mov	 cx,BIOS_ADDR2	; Get secondary ...

CALC_LENGTH_NEXT:
	 cmp	 cx,VOID[bx].DATA_SEG ; Izit in primary/secondary segment?
	 je	 short CALC_LEN_SEGMENT ; Jump if so

	 ror	 ecx,(16-0)	; Swap primary and secondary segments

	 cmp	 cx,VOID[bx].DATA_SEG ; Izit in primary/secondary segment?
	 jne	 short CALC_LEN_LOOP ; Jump if not

CALC_LEN_SEGMENT:
	 mov	 ax,VOID[bx].DATA_START ; Get offset in bytes
	 add	 ax,VOID[bx].DATA_LEN ; Add length in bytes
	 dec	 ax		; Convert length to offset 0

	 cmp	 ax,dx		; Izit higher than highest value?
	 jbe	 short CALC_LEN_LOOP ; Jump if not

	 mov	 dx,ax		; Set new highest value

CALC_LEN_LOOP:
	 add	 bx,size DATA_STR ; Point to next item

	 cmp	 bx, VOID_PTR	; At end of list?
	 jb	 short CALC_LENGTH_NEXT ; No, look at next entry

; Determine the BIOS length via the ROM identifier

	 mov	 es,BIOS_ADDRESS ; Address the alleged ROM
	 assume  es:ROMSEG	; Tell the assembler about it

	 movzx	 ax,ROMLEN	; Get length in 512 bytes
	 shl	 ax,(9-0)	; Convert from 512 bytes to bytes

; Pick the greater of (data structure length) vs. (ROMLEN)

	 cmp	 ax,dx		; Is data struc length greater than ROMLEN?
	 jae	 short @F	; Jump if so

	 mov	 ax,dx		; Use ROMLEN as length
@@:

; Round up to the nearest 4KB boundary

	 test	 ax,(4*1024)-1	; Test for any insignificant bits
	 jz	 short @F	; Jump if none set

	 add	 ax,4*1024	; We need to round up
@@:
	 and	 ax,(not ((4*1024)-1)) ; Strip off all insignificant digits

; Pick the greater of (last result) vs. (32KB)

	 cmp	 ax,MIN_LENGTH	; Is calculated length grater than minimum?
	 jae	 short @F	; Jump if so

	 mov	 ax,MIN_LENGTH	; Use minimum length (adapter dependent)
				; 16KB for EGA, 32KB for VGA
@@:

	 mov	 BIOS_LEN,ax	; Set new BIOS length

	 REGREST <es,dx,ecx,bx,ax> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_LENGTH	 endp			; End CALC_LENGTH procedure

;***************************************************************************

	 NPPROC  CALC_CACHE_LEN -- CALC_CACHE_LEN Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Calculate the caching length of the BIOS

386MAX caches 24 KB (even on a 32 KB BIOS) by default.
We only extend the caching region if there is an offset outside of the
default caching region that has to be cached.

Note: This routine must be preformed after both
      SEARCH_BIOS and XLAT_SPECIAL

|

	 REGSAVE <ax,cx,di>	; Save registers

; Check the cache length against the EGA an VGA save pointer offsets
; if they're in either the primary or secondary ROM location

	 call	 CALC_CACHE_SAVE ; Calculate cache length
				; Updates CACHE_LEN

	 mov	 cx,SPECIAL_ADDR_CNT ; Get number of special addresses
	 jcxz	 short CALC_CACHE_LEN_EXIT ; Jump if nothing there

	 mov	 ax,CACHE_LEN	; Get top of cacheable ROM
	 xor	 di,di		; Zero index into SPECIAL_ADDR table

CALC_CACHE_LEN_NEXT:
	 cmp	 ax,SPECIAL_ADDR[di] ; Is top of ROM greater than special address?
	 ja	 short @F	; Jump if so

	 mov	 ax,SPECIAL_ADDR[di] ; Set as new top of cachable ROM
	 inc	 ax		; Include word being cached
@@:
	 add	 di,2		; Address next entry in table
	 loop	 CALC_CACHE_LEN_NEXT ; Try next special address

	 mov	 CACHE_LEN,ax	; Save as new top of cachable ROM

CALC_CACHE_LEN_EXIT:

	 mov	 ax,CACHE_LEN	; Get caching size of ROM
	 lea	 di,MSG_CACHELEN ; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 REGREST <di,cx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_CACHE_LEN	 endp			; End CALC_CACHE_LEN procedure

;*****************************************************************************

	 NPPROC  CALC_CACHE_SAVE -- Calculate Cache Length Versus EGA/VGA Save Ptrs
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check the cache length against the EGA an VGA save pointer offsets
if they're in either the primary or secondary ROM location

|

	 REGSAVE <ax,bx,cx,dx,di,es> ; Save registers

	 mov	 ax,BIOS_ADDRESS ; Get address of primary BIOS
	 mov	 dx,BIOS_ADDR2	; Get address of secondary BIOS

	 mov	 cx,CACHE_LEN	; Get top of cacheable ROM so far

	 push	 seg INTVEC	; Address segment 0
	 pop	 es		; Address it
	 assume  es:INTVEC	; Tell the assembler about it

; First check to see if the EGA save pointer is pointing into uncached ROM

	 cmp	 ax,INT00_VEC[04A8h].VSEG ; Is segment pointing into ours?
	 je	 short @F	; Jump if so

	 cmp	 dx,INT00_VEC[04A8h].VSEG ; Is segment pointing into ours?
	 jne	 short CALC_CACHE_SAVE1 ; Jump if not
@@:
	 mov	 bx,INT00_VEC[04A8h].VOFF ; Get offset of EGA Save Pointer
	 add	 bx,size EGASAVE_STR ; Add size of EGA Save Pointer

	 cmp	 cx,bx		; Compare to cached length calculated earlier
	 jae	 short @F	; Jump if larger (or equal)

	 mov	 cx,bx		; Use new value
@@:
CALC_CACHE_SAVE1:

; Ensure the EGA save pointer is valid

	 cmp	 INT00_VEC[04A8h],0 ; Izit valid?
	 je	 near ptr CALC_CACHE_SAVE_EXIT ; Jump if not

	 les	 di,INT00_VEC[04A8h] ; Get EGA save pointer
	 assume  es:nothing	; Tell the assembler about it

; Check to see if the secondary VGA save pointer is pointing into uncached ROM

	 cmp	 ax,es:[di].EGASAVE_2ND.VSEG ; Is segment pointing into ours?
	 je	 short @F	; Jump if so

	 cmp	 dx,es:[di].EGASAVE_2ND.VSEG ; Is segment pointing into ours?
	 jne	 short CALC_CACHE_SAVE2 ; Jump if not
@@:
	 mov	 bx,es:[di].EGASAVE_2ND.VOFF ; Get offset of secondary pointer
	 add	 bx,size VGASAVE_STR ; Add size of Secondary VGA Save Pointer

	 cmp	 cx,bx		; Compare to cached length calculated earlier
	 jae	 short @F	; Jump if larger (or equal)

	 mov	 cx,bx		; Use new value
@@:
CALC_CACHE_SAVE2:

CALC_CACHE_SAVE_EXIT:
	 mov	 CACHE_LEN,cx	; Save for later use

	 REGREST <es,di,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_CACHE_SAVE endp		; End CALC_CACHE_SAVE procedure

;*****************************************************************************

	  NPPROC  SEARCH_BIOS -- Search through BIOS
	  assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If neither of BIOS_SRC and BIOS_DEST are not C000 and the ROMs at
BIOS_SRC and C000 are close enough, search for both segments' values in
the ROM.  There are Zenith video ROMs which have both copies of the
ROM active, thus occurrences of both segments (typically C000 and
E000) need to be replaced by BIOS_DEST.

On pass 1, if there are two ROMs visible, they are at BIOS_SRC and
BIOS_ADDR2.  On pass2, they are at BIOS_SRC and BIOS_DEST because the
one at BIOS_ADDR2 likely has been overlaid with high DOS.

We tell the difference between the two by the $PE bit in the MSW.

|

	 call	 GET_DUALROM	; See if there's a dual ROM at C000 and elsewhere

	 test	 BIOS_FLAG,@BIOS_C000 ; Did we find a match?
	 jz	 short @F	; Jump if not

	 push	 BIOS_SRC	; Save for a moment

	 mov	 BIOS_SRC,0C000h ; Save new replacement value

	 call	 SEARCH_BIOS_SUB ; Call the routine's tail as a subroutine

	 pop	 BIOS_SRC	; Restore
@@:
SEARCH_BIOS_SUB:

COMMENT |

Stroll through the BIOS, looking for all references to C000
If we find a C000, translate it (unless FILTER tell us not to)
Then, patch any special cases (from SRCH_INT)

Also, because some Zenith video ROMs at E000 (which we might identify
at the source) don't have a proper ROM signature, we blast one in
there anyway.

On exit :
Always returns successfully

|

	 REGSAVE <ax,cx,dx,si,es> ; Save registers

	 mov	 es,BIOS_ADDRESS ; Get BIOS segment
	 assume  es:RGROUP	; Tell the assembler about it

; If we're to modify the ROM at BIOS_DEST, blast in a ROM signature
; as some Zenith ROMs don't have one there.

	 test	 LCL_FLAG,@LCL_MODIFY1 ; Are we to modify the BIOS?
	 jz	 short @F	; Jump if not

	 mov	 ROMSIGN,@ROMSIGN ; Mark it
@@:
	 mov	 cx,BIOS_LEN	; Get number of bytes to search through
	 xor	 di,di		; Start at beginning of segment
	 cld			; Ensure proper search direction

SEARCH_NEXT:
	 mov	 ax,BIOS_SRC	; Get search string
   repne scasb			; Scan until byte match
	 jcxz	 short SEARCH_BIOS_EXIT ; Jump if we reached the end of BIOS

; We found a byte match

	 cmp	 ah,es:[di]	; Compare second byte of word
	 jne	 short SEARCH_NEXT ; Jump if not a word match

; We found a word match

	 REGSAVE <di,es>	; Save Segment:Offset of match

; Display the address of the match

	 mov	 ax,ds		; Get our data segment
	 mov	 es,ax		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 ax,di		; Get pointer to BIOS
	 dec	 ax		; Point to offending address
	 lea	 di, MSG_OFFSET ; Format string address
	 call	 FMT_WORD	; Format AX -> ES:DI

	 REGSAVE <cx,dx>	; Save registers

	 lea	 dx,MSG_OFFSET ; String address
	 mov	 cx,@MSG_OFFSET_LEN ; Byte count
	 call	 DISPLAY	; Display the search string's address

	 REGREST <dx,cx>	; Restore registers

	 call	 FILTER 	; Filter out Bogus addresses (CF significant)

	 REGREST <es,di>	; Restore Segment:Offset of match
	 assume  es:nothing	; Tell the assembler about it

; Patch the word from C000 to B000 (if appropriate)

	 jc	 short DONT_MODIFY ; Don't modify BIOS if FILTER said not to

	 test	 LCL_FLAG,@LCL_MODIFY1 ; Are we to modify the BIOS?
	 jz	 short SKIP_MODIFY ; Jump if not

	 or	 LCL_FLAG,@LCL_MODIFY2 ; Mark as BIOS modification present

	 mov	 ax,BIOS_DEST	; Get replacement string
	 mov	 es:[di-1],ax	; And replace search string with it!

SKIP_MODIFY:

; Update pointer to highest patch point

	 cmp	 di,CACHE_LEN	; Is address higher than our top?
	 jb	 short @F	; Jump if not

	 mov	 CACHE_LEN,di	; Load new top of ROM (for caching)
@@:
DONT_MODIFY:

	 REGSAVE <cx,dx>	; Save registers

	 lea	 dx,MSG_CRLF	; String address
	 mov	 cx,@MSG_CRLF_LEN ; Byte count
	 call	 DISPLAY	; Display CR and LF

	 REGREST <dx,cx>	; Restore registers

	 inc	 XLAT_COUNTER	; Add 1 to count

	 jmp	 short SEARCH_NEXT ; Do again

SEARCH_BIOS_EXIT:
	 REGREST <es,di,dx,cx,ax> ; Restore registers
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEARCH_BIOS endp			 ; End SEARCH_BIOS procedure

;*****************************************************************************

	 NPPROC  FILTER -- Filter out Bogus addresses
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Algorithm:
	Determine if address is inside of 'off limits' data strucutre
	Determine if address is part of 'special search string'

On entry :	 AX = Offset of search string within BIOS
		 ES = Just PGROUP (there is no pointer to BIOS)

On exit :	 CF = 1 if we are not to modify this entry.
			(If it is within a data structure)

|

	 REGSAVE <ax,bx,cx,dx,si,di,bp,fs> ; Save registers

	 mov	 si,ax		; Save address of word in question

;------- Check for address inside of a special data structure ---------

	 xor	 bx,bx		; Zero index into font structure
	 mov	 bp,1		; Initialize search counter

FILTER_NEXT:
	 mov	 dx,VOID[bx].DATA_SEG ; Get segment of font

	 cmp	 dx,BIOS_SRC	; Izit our segment?
	 je	 short @F	; Jump if so

	 cmp	 dx,BIOS_ADDRESS ; Izit our segment?
	 je	 short @F	; Jump if so

	 cmp	 dx,BIOS_DEST	; Izit our segment?
	 jne	 short FILTER_LOOP ; Jump if not
@@:
	 cmp	 ax,VOID[bx].DATA_START ; Compare to length
	 jb	 short FILTER_LOOP ; Jump if before font

	 mov	 dx,VOID[bx].DATA_START ; Get start
	 add	 dx,VOID[bx].DATA_LEN ; Add Length

	 cmp	 ax,dx		; Is our pointer inside of Font?
	 jae	 short FILTER_LOOP ; Jump if not

; Address is in one of the data structures

	 mov	 ax,bp		; Get counter (ignore upper half)
	 lea	 di,MSG_SPECIAL_LBL ; String address
	 call	 FMT_BYTE	; Format AL => ES:DI

	 lea	 dx,MSG_SPECIAL_LBL ; String address
	 mov	 cx,@MSG_SPECIAL_LBLLEN ; Byte count of string
	 call	 DISPLAY	; Display it

	 jmp	 short FILTER_STC ; All done

FILTER_LOOP:
	 add	 bx,size DATA_STR ; Point to next item
	 inc	 bp		; Count in one more data structure

	 cmp	 bx, VOID_PTR	; At end of list?
	 jb	 short FILTER_NEXT ; No, do again

;------- Check if it is part of a special search string ---------------------
;	 SI => search string location in question (in the BIOS)

	 mov	 cx,BIOS_ADDRESS ; Get address of BIOS in question
	 mov	 fs,cx		; ... and address via FS
	 assume  fs:nothing	; Tell the assembler about it

	 xor	 bx,bx		; Zero index into search string table
	 mov	 dx,si		; Save pointer into BIOS

@@:
	 mov	 si,dx		; Get pointer into BIOS
	 lea	 di,SEARCH_PATTERN[bx].SEARCH_STRING ; Get known string
	 sub	 si,SEARCH_PATTERN[bx].SEARCH_OFFSET ; Get start of search
	 mov	 cx,SEARCH_PATTERN[bx].SEARCH_COUNT ; Get byte count

    repe cmps	 fs:[si].LO,es:[di].LO ; Compare the strings
	 jz	 short @F	; Jump if strings match

	 add	 bx,@SEARCH_STRLEN ; Point to next entry in table

	 cmp	 bx,@SEARCH_PATTERNLEN ; More to process?
	 jb	 short @B	; Jump if so

; We did not find a string match

	 jmp	 short FILTER_CLC ; Join common exit code

; We found a string match (this one gets filtered out)

@@:

	 mov	 al,SEARCH_PATTERN[bx].SEARCH_LABEL ; Get text label
	 lea	 di,MSG_SPECIAL_LBL ; String address
	 call	 FMT_BYTE	; Format AL => ES:DI

	 lea	 dx,MSG_SPECIAL_LBL ; String address
	 mov	 cx,@MSG_SPECIAL_LBLLEN ; Byte count of message
	 call	 DISPLAY	; Display it

FILTER_STC:
	 stc			; Mark as 'do not convert value'
	 jmp	 short FILTER_EXIT ; Join common exit code

FILTER_CLC:
	 clc			; Mark as OK to convert string

FILTER_EXIT:
	 REGREST <fs,bp,di,si,dx,cx,bx,ax>	; Restore
	 assume fs:nothing

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILTER endp			 ; End FILTER procedure

;***************************************************************************

	 NPPROC  XLAT_SPECIAL -- XLAT_SPECIAL Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Translate the special cases

|

	 REGSAVE <ax,cx,si,di,es>	; Save registers

	 mov	 es,BIOS_ADDRESS ; Get BIOS segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,SPECIAL_ADDR_CNT ; Get the count of above
	 jcxz	 short XLAT_SPECIAL_EXIT ; Jump if no special cases

	 lea	 si,SPECIAL_ADDR ; Get the list of specal addresses

XLAT_SPECIAL_NEXT:
	 mov	 di,[si]	; Get next entry from table

	 test	 LCL_FLAG,@LCL_MODIFY1 ; Are we to modify the BIOS?
	 jz	 short XX_MODIFY ; Jump if not

	 or	 LCL_FLAG,@LCL_MODIFY2 ; Mark as BIOS modification present

	 mov	 ax,BIOS_DEST	; Get replacement string
	 mov	 es:[di],ax	; And replace search string with it!

XX_MODIFY:

; If we were going to display each SPECIAL_ADDR,
; this is where we would do it.

	 add	 si,2		; Address next entry in the table
	 loop	 XLAT_SPECIAL_NEXT ; Loop if more special cases to follow

XLAT_SPECIAL_EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XLAT_SPECIAL	 endp			; End XLAT_SPECIAL procedure

;**************************************************************************


	 NPPROC  CALC_CRC -- Calculate The CRC
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate CRC.

On exit:

AX	 =	 computed CRC

|

CRC_STR  struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
CRC_CNT  dd	 ?		; Size in bytes
CRC_SEG  dw	 ?		; Segment in paras

CRC_STR  ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,dx,si,ds> ; Save registers

	 mov	 ds,[bp].CRC_SEG ; Get the segment to check
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> memory to CRC
	 xor	 dx,dx		; Initialize accumulated CRC
CALC_CRC_NEXTSEG:
	 mov	 ecx,[bp].CRC_CNT ; Get the size in bytes

	 cmp	 ecx,CON64K	; Check against maximum
	 jbe	 short CALC_CRC_NEXT ; Jump if it's within range

	 xor	 cx,cx		; Use full range
CALC_CRC_NEXT:
	 lodsb			; Get next byte

	 xor	 dl,al		; XOR into low-order byte of accumulated CRC
	 movzx	 ebx,dl 	; Copy to index register, zero high-order bytes
	 movzx	 dx,dh		; Shift down one byte, zero high-order byte
	 xor	 dx,XORLIST[ebx*(type XORLIST)] ; Compute polynomial residue

	 loop	 CALC_CRC_NEXT	; Jump if more bytes in this 64KB segment

	 mov	 ecx,CON64K	; Get one segment's worth

	 sub	 [bp].CRC_CNT,ecx ; Less that amount
	 jbe	 short CALC_CRC_EXIT ; Jump if no more

	 mov	 ax,ds		; Copy current segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 CALC_CRC_NEXTSEG ; Go around again

CALC_CRC_EXIT:
	 mov	 ax,dx		; Copy to result register

	 REGREST <ds,si,dx,ecx,ebx> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_CRC endp			; End CALC_CRC procedure


;***************************************************************************

	 NPPROC  TEST_VGASWAP -- Test for VGASWAP compatibilty
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Test for VGASWAP compatibilty

1) Monochrome adapter must NOT be present
2) EGA or VGA must be present
3) Machine must not be MCA
4) Machine must not have 128 KB system BIOS
5) If length is >32 KB, C000 -> C000+Length must be available.
   Otherwise, if MAX is present, check for B000+Length available.
   If MAX is not present, assume it's OK (note that we always
   fail if the length is >32K and MAX is not present).	The case
   where MAX is not present is insignificant, because the only
   place this should be called is in Phase II of MAXIMIZE.

On entry:
AX	=	ROM length in bytes

Note: This routine exits to DOS (with the appropriate error code)
      if invoked with the /t option.  This allows MAXIMIZE to determine
      whether or not to add VGASWAP to the profile.
      Error Code: 0 ==> OK to add VGASWAP profile option
      Error Code: 1 ==> VGASWAP not compatible with machine

|

	 pusha			; Save GP registers

	 mov	 ax,BIOS_ADDRESS ; Get ROM segment
	 mov	 BIOS_SRC,ax	; Save as source segment

	 REGSAVE <es>		; Save registers

	 mov	 bp,ax		; Save ROM length

; Test for monochrome adapter presence

	 mov	 dx,03B4h	; Address register of monochrome 6845

	 call	 CHK_CREG	; Check for mono adapter presence
	 jnc	 near ptr TV_FAIL ; Jump if so

; Test for EGA or VGA presence

	 call	 IZITEGA	; Check for EGA (or above)
	 cmp	 ax,-1		; Izit present?
	 je	 near ptr TV_FAIL ; Jump if not

; Test for MCA presence

	 mov	 ah,0C0h	; Attempt to read configuration record
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short TV_XMCA	; Jump if error (not an MCA)

	 cmp	 ah,80h 	; Check for error return
	 je	 short TV_XMCA	; Jump if error (not an MCA)

	 cmp	 ah,86h 	; Check for error return
	 je	 short TV_XMCA	; Jump if error (not an MCA)

	 test	 es:[bx].CFG_PARMS,@CFG_MCA ; Izit Micro Channel Architecture?
	 jnz	 near ptr TV_FAIL ; Jump if so (It is an MCA machine)

; Test for 128KB BIOS

TV_XMCA:
	 push	 seg CGROUP	; Get ROM BIOS segment
	 pop	 es		; Address via segment register
	 assume  es:CGROUP	; Tell the assembler about it

	 cmp	 BIOSCPUID,@CPU_MCA ; Check machine ID for 128KB BIOS

	 push	 ds		; Get PGROUP
	 pop	 es		; Address via ES
	 assume  es:PGROUP	; Tell the assembler about it

	 je	 short TV_FAIL	; Jump if not present

; Check to see if MAX is present.  If not, Len<=32K succeeds and >32K fails.

	 call	 MAX_PRESENT	; Is MAX present?
	 jnc	 short @F	; Jump if so

; Check to see if BIOS can fit in the monochrome area

	 cmp	 bp,32*1024	; Is ROM length within limits?
	 jbe	 short TV_OK	; Assume it will fit in mono area

	 jmp	 short TV_FAIL	; Won't fit in mono area and we can't check
				; the memory map to see if C000 works.

@@:
; If BIOS is at C000 and the length is >32K, there is nowhere to VGASWAP it to

	 mov	 dx,0B000h	; Assumed destination for len<=32K
	 cmp	 bp,32*1024	; Is ROM length within limits?
	 jbe	 short @F	; Jump if so

	 mov	 dx,0C000h	; Destination for len>32K
	 cmp	 BIOS_SRC,dx	; Is source == destination?
	 je	 short TV_FAIL	; Jump if so - we can't move it to its source

@@:
; Get the available memory structure from MAX, and check for RAM, INCLUDE or
; page frame at the destination.  We need BP bytes at DX:0.

	 lea	 di,ZTAIL	; ES:DI ==> save area for MCS
				; ((1024-640)/4 bytes==96, 1 per 4K page)
	 EMMOUT  @EMM2_GETMCS	; Read MCS structure
				; CX = number of entries

	 and	 ah,ah		; Check return code
	 jnz	 short TV_OK	; Jump if EMM2 error (?)

	 jcxz	 TV_FAIL	; Jump if no entries (?)

	 shr	 bp,4-0 	; Convert from bytes to paras
	 add	 bp,dx		; Get ending paragraph +1

; We are looking for available contiguous paras from DX:0 to BP:0

TV_MCS_NEXT:
	 mov	 ax,PGROUP:[di].MCS_PARA ; Get starting paragraph
	 mov	 bx,PGROUP:[di].MCS_NPAR ; Get length in paras
	 add	 bx,ax		; Get ending paragraph +1
	 mov	 si,PGROUP:[di].MCS_FLAG ; Get flags

	 cmp	 bp,ax		; Is this region above ours?
	 jbe	 short TV_MCS_LOOP ; Jump if so

	 cmp	 bx,dx		; Is this region below ours?
	 jbe	 short TV_MCS_LOOP ; Jump if so

; We have a partial intersection.  If this region is available,
; check to see if it contains DX-BP.
	 test	 si,@MCS_UNAVL or @MCS_INCL or @MCS_ROM or @MCS_RAM ; Izit
				; available?
	 jnz	 short TV_MCS_LOOP ; Jump if not (RAM= takes precedence)

	 cmp	 dx,ax		; Do we start at or above the starting para?
	 jb	 short TV_MCS_LOOP ; Jump if not

	 cmp	 bp,bx		; Are we contained by the region?
	 jbe	 short TV_OK	; Jump if so

TV_MCS_LOOP:
	 add	 di,size MCS_STR ; Skip to next entry

	 loop	 TV_MCS_NEXT	; Go around again

	 jmp	 short TV_FAIL	; Did not find a matching entry

TV_OK:
	 mov	 al,0		; Return VGASWAP OK to MAXIMIZE

	 test	 LCL_FLAG,@LCL_VGASWAP ; Testing for VGASWAP compatibility?
	 jnz	 short TV_TEST_EXIT ; Jump if so

	 mov	 PTR_MSG_VGASWAP,offset PGROUP:MSG_VGASWAP_OK ; Set up msg.

	 jmp	 TV_EXIT	; Join common exit code

TV_FAIL:
	 mov	 al,1		; Return VGASWAP not allowed to MAXIMZE

	 test	 LCL_FLAG,@LCL_VGASWAP ; Testing for VGASWAP compatibility?
	 jnz	 short TV_TEST_EXIT ; Jump if so

	 mov	 PTR_MSG_VGASWAP,offset PGROUP:MSG_VGASWAP_FAIL ; Set up msg.

	 jmp	 TV_EXIT	; Join common exit code

TV_TEST_EXIT:
;;;;;;;; mov	 al,??		; Set error code (already done)
	 DOSCALL @EXITRC	; Exit process with return code in AL
				; This is meant for returning to MAXIMIZE

TV_EXIT:
	 REGREST <es>		; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 popa			; Restore GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TEST_VGASWAP	 endp			; End TEST_VGASWAP procedure

;***************************************************************************

	 NPPROC  CHECK_WGS6386 -- Check for WGS6383
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Check for AT&T WGS6386

This computer has a pointer to the video BIOS in the XBDA
that needs to be relocated.

1) Check for Phoenix system BIOS signature
2) Check for WGS6386 video BIOS signature
3) Check for XBDA patch point
4) If all three are above conditions OK, patch the XBDA

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 push	 seg CPUID_SEG	; Address the system BIOS
	 pop	 es		; ... via ES
	 assume  es:CPUID_SEG	; Tell the assembler about it

; Check for Phoenix signature

	 lea	 di,PHOENIXSIGN ; ES:DI ==> expected signature in BIOS
	 lea	 si,LCL_PSIGN	; DS:SI ==> local copy
	 mov	 cx,LCL_PSIGN_LEN ; Length of ...
    repe cmpsb			; Compare 'em
	 jne	 short WGS6386_EXIT ; Jump if not what we expected

	 push	 BIOS_DEST	; Get destination of video BIOS
	 pop	 es		; ... and address via ES
	 assume  es:nothing	; Tell the assembler about it

; Check for WGS 6386 signature

	 mov	 di,@WGS_SIGN_ADDR ; ES:DI ==> expected signature in video BIOS
	 lea	 si,LCL_WSIGN	; DS:SI ==> local copy
	 mov	 cx,LCL_WSIGN_LEN ; Length of ...
    repe cmpsb			; Compare 'em
	 jne	 short WGS6386_EXIT ; Jump if not what we expected

; Check for BIOS data of 06/26/90
;;;;;;;;
;;;;;;;; cmp	 BIOS_DATE.EDD[0],'2/60' ; Izit?
;;;;;;;; jne	 short WGS6386_EXIT ; Jump if not
;;;;;;;;
;;;;;;;; cmp	 BIOS_DATE.EDD[4],'09/6' ; Izit?
;;;;;;;; jne	 short WGS6386_EXIT ; Jump if not
;;;;;;;;

; Check for XBIOS data

	 push	 seg BIOSDATA	; Get BIOS data segment
	 pop	 es		; Address it
	 assume  es:BIOSDATA	; Tell the assembler about it

	 mov	 es,XBDA_SEG	; Get XBIOS segment
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[30h].VSEG,0C000h ; Izit pointing to the C000 BIOS?
	 je	 short @F	; Jump if so

	 cmp	 es:[30h].VSEG,0E000h ; Izit pointing to the E000 BIOS?
	 jne	 short WGS6386_EXIT ; Jump if not

@@:
	 cmp	 es:[30h].VOFF,3A1Eh ; Izit pointing to correct offset?
	 jne	 short WGS6386_EXIT ; Jump if not

; This is a WGS6386, patch the XBIOS data area here

	 mov	 ax,BIOS_DEST ; Get source segment
	 mov	 es:[30h].VSEG,ax ; Point to new ROM location

WGS6386_EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_WGS6386 endp		; End CHECK_WGS6386 procedure

;***************************************************************************

	 NPPROC  CHECK_SPEEDSTAR -- CHECK_SPEEDSTAR Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Check for a Diamond Speedstar, and patch their checksum code.

Some Diamond Speedstar BIOSes contain a routine that checksums a small
portion of its own video BIOS.	This is probably some form of
copyright protection.  Unfortunately, if we patch a C000 inside of the
checksummed range, they will take an incorrect jump when they calculate
the checksum (inside of a mode switch).

* Look for SpeedSTAR signature
* Look for checksum routine
* Patch conditional jump at end of checksum routine

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 push	 BIOS_DEST	; Get destination of video BIOS
	 pop	 es		; ... and address via ES
	 assume  es:nothing	; Tell the assembler about it

; Check for Diamond Speedstar signature

	 mov	 di,@SPEEDSTAR_SIGN_ADDR ; ES:DI ==> expected signature in video BIOS
	 lea	 si,LCL_SPEEDSTAR ; DS:SI ==> local copy
	 mov	 cx,LCL_SPEEDSTAR_LEN ; Length of ...
    repe cmpsb			; Compare 'em
	 jne	 short SPEEDSTAR_EXIT ; Jump if not what we expected

; Check for the Checksum routine's signature

	 push	 BIOS_DEST	; Starting segment of BIOS
	 push	 word ptr 0000h ; ...	   offset ...
	 push	 BIOS_LEN	; Length of search area (64KB)
	 push	 offset PGROUP:LCL_DSS_CHECK ; Get offset of source string
	 push	 @LCL_DSS_LEN	; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short SPEEDSTAR_EXIT ; Jump if not found
				; Return with DI = offset of match in ROM

	 mov	 es:[di+(LCL_DSS_PATCH-LCL_DSS_CHECK)].LO,@OPCOD_JMPS
				; Patch the JNZ to a JMP

SPEEDSTAR_EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SPEEDSTAR  endp			; End CHECK_SPEEDSTAR procedure

;*****************************************************************************

	  NPPROC  WROM -- Mark ROM as Read/Write or Read Only
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Mark ROM as either Read Only or Read/Write

On entry :
AL	=	0 ==> Mark ROM as Read Only
		1 ==> Mark ROM as Read/Write

|

	 REGSAVE <ax,dx>	; Save registers

	 test	 LCL_FLAG,@LCL_MODIFY1 ; Permission to modify BIOS?
	 jz	 short @F	; Jump if not

	 EMMOUT @EMM2_ROMRW	; Alter ROM Read/Write State
@@:

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WROM endp			 ; End WROM procedure

;*****************************************************************************

	  NPPROC  OPEN_CFG -- Open the .CFG file
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Open the .CFG file

If open fails,
   Display copyright message
   Display error message
   Return to DOS

|

	 REGSAVE <ax,bx>  ; Save registers

	 push	 offset PGROUP:DOT_CFG ; Get extension
	 call	 CREATEFILE	; Append extension and create the file,
				; return with BX = handle
	 jc	 OPEN_CFG_ERR1 ; Jump if something went wrong

	 mov	 FILEHNDL,bx	; Save file handle

	 jmp	 short OPEN_CFG_EXIT ; All done

OPEN_CFG_ERR1:
	 DOSCALL @STROUT,MSG_COPY ; Display the copyright message
	 DOSCALL @STROUT,MSG_OPENCFG_ERR1 ; Display error message

	 mov	 al,1		; Error return code
	 DOSCALL @EXITRC	; Exit to DOS with error code

OPEN_CFG_EXIT:
	 REGREST <bx,ax>	; Restore registers

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OPEN_CFG endp			 ; End OPEN_CFG procedure

;*****************************************************************************

	  NPPROC  CLOSE_CFG -- Close the .CFG file
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Close the .CFG file

|

	 REGSAVE <ax,bx>  ; Save registers

	 mov	 bx,FILEHNDL	; Get file handle

	 DOSCALL @CLOSF2	; Close the .CFG file

	 REGREST <bx,ax>	; Restore

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLOSE_CFG endp			 ; End CLOSE_CFG procedure

;*****************************************************************************

	  NPPROC  WRITE_BIO -- Write the BIO file to disk
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Copy the BIOS image to disk.


|

; Create the file

	 push	 offset PGROUP:DOT_BIO ; Get extension
	 call	 CREATEFILE	; Append extension and create the file,
				; return with BX = handle
	 jc	 WRITE_BIO_ERR1; Jump if something went wrong

	 REGSAVE <ds,es>	; Save to address BIOS

; Copy BIOS to buffer
; Note we can't just point the @WRITF2 DS:DX to the BIOS
; as some machines don't allow DMA from the BIOS.

	 push	 BIOS_ADDRESS	; Get source segment
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it
	 xor	 si,si		; DS:DX ==> first half of the BIOS

	 mov	 es,BIO_SEG	; Get segment of buffer
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> local buffer

	 mov	 cx,8000h	; Copy 32K words
S16  rep movsw			; Copy 64K bytes

; Write out the buffer in two 32KB chunks

	 mov	 ds,BIO_SEG	; Get segment of buffer
	 assume  ds:nothing	; Tell the assembler about it
	 xor	 dx,dx		; DS:DX ==> first quarter of the BIOS

	 mov	 cx,8000h	; Write out half of the 64KB
	 DOSCALL @WRITF2	; Write it out
	 jc	 WRITE_BIO_ERR2 ; Jump if something went wrong

	 cmp	 ax,cx		; Izit the same length?
	 jne	 WRITE_BIO_ERR2 ; Jump if not

	 mov	 dx,8000h	; DS:DX ==> second half of the 64K BIOS
	 mov	 cx,8000h	; Write out half of the 64KB
	 DOSCALL @WRITF2	; Write it out
	 jc	 WRITE_BIO_ERR3 ; Jump if something went wrong

	 cmp	 ax,cx		; Izit the same length?
	 jne	 WRITE_BIO_ERR3 ; Jump if not

	 REGREST <es,ds>	; Restore registers
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 DOSCALL @CLOSF2	; Close the .BIO file

	 jmp	 short WRITE_BIO_EXIT ; All done

WRITE_BIO_ERR1:
	 DOSCALL @STROUT,MSG_WRITEBIO_ERR1 ; Display error message
	 jmp	 short WRITE_BIO_ERR ; Join common exit ocde

WRITE_BIO_ERR2:
	 push	 cs		; Address our data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 DOSCALL @STROUT,MSG_WRITEBIO_ERR2 ; Display error message
	 jmp	 short WRITE_BIO_ERR ; Join common exit ocde

WRITE_BIO_ERR3:
	 push	 cs		; Address our data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 DOSCALL @STROUT,MSG_WRITEBIO_ERR3 ; Display error message
;;;;;;;; jmp	 short WRITE_BIO_ERR ; Join common exit ocde

WRITE_BIO_ERR:
	 stc			; mark as unsuccessful

WRITE_BIO_EXIT:

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRITE_BIO endp			 ; End WRITE_BIO procedure

;*****************************************************************************

	 NPPROC  CREATEFILE -- Append Extension and Create File
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Append an extension and create a file.

On exit:

CF	 =	 0 if successful
	 =	 1 if not
BX	 =	 file handle if successful

|

CREA_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
CREA_EXT dw	 ?		; Offset of file extension

CREA_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,dx,si,di> ; Save registers

	 lea	 di,FILEBUF	; ES:DI ==> filename buffer
	 add	 di,FILELEN	; Skip to end+1
	 mov	 si,[bp].CREA_EXT ; DS:SI ==> file extension
	 mov	 cx,5		; CX = length of ...
S16  rep movsb			; Append the file extension

	 xor	 cx,cx		; Use default file attribute
	 DOSCALL @CREAF2,FILEBUF ; Create the file
	 jc	 short CREATEFILE_EXIT ; Jump if not successful
				; Note: CF is significant

	 mov	 bx,ax		; Return in file handle register
CREATEFILE_EXIT:
	 REGREST <di,si,dx,cx,ax> ; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CREATEFILE endp 		; End CREATEFILE procedure

;*****************************************************************************

	  NPPROC  DISPLAY_BIOS -- Display the BIOS via SWAT
	  assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Read the file into memory and call SWAT to display it.
Allows inspection of the BIOS for debugging purposes.

Upon entry into SWAT, AX = the segment that the file is loaded.
To view BIOS image, enter SWAT commands...
U AX:0	 -or-	 DB AX:0

|

	 REGSAVE <ax,bx>	; Save registers

	 call	 READ_FILE	; Read in the file
				; Retrurns: AX=segment, BX=handle
	 jc	 short DISPLAY_BIOS_STC ; jump if read error

	 push	 ax		; Save pointer to file image
	 DOSCALL @CLOSF2	; Close the file
	 pop	 ax		; Restore pointer to file image

; Call Debugger (AX points to BIOS image)

	 int	 01h		; Call the Debugger
	 nop			; Debugging aid

	 jmp	 short DISPLAY_BIOS_EXIT ; All done

DISPLAY_BIOS_STC:
	 DOSCALL @STROUT,BIOS_READ_ERR; Display error message
	 stc			; Mark as unsuccessful

DISPLAY_BIOS_EXIT:

	 REGREST <bx,ax>	; Restore registers

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPLAY_BIOS endp			 ; End DISPLAY_BIOS procedure

;*****************************************************************************

	  NPPROC  EXECUTE_BIOS -- Load and Execute the BIOS
	  assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

* Read the .BIO file into memory
* Read the .CFG file into memory
* Patch the EGA Save Pointer (0:4A8)
* Patch the Int 10 pointer (0:40)
* Patch the new BIOS to reflect new code segment

On exit:
CF	=	0 if all went well (ready to TSR)
		1 if error (do not TSR)

|

	 REGSAVE <ax,bx,cx,di,bp,ds> ; Save registers

; Read in the BIOS image

	 call	 READ_FILE	; Read in the .BIO file
				; Retrurns: AX=segment, BX=handle
	 jc	 short EXECUTE_BIOS_STC ; jump if read error

	 mov	 bp,ax		; Save the .BIO pointer

	 DOSCALL @CLOSF2	; Close the file

; Read in the CFG file to obtain entry point information

	 lea	 di,BIOS_FNAME	; Address of BIOS image file name
	 mov	 cx,-1		; We'll find it somewhere
	 mov	 al,'.'         ; Search for separator
  repne scas	 BIOS_FNAME[di] ; Search for it

	 mov	 [di-1].EDD,@CFG_EXT ; Add on .CFG extension (.CFG)

	 call	 READ_FILE	; Read in the .CFG file
				; Retrurns: AX=segment, BX=handle
	 jc	 short EXECUTE_BIOS_STC ; jump if read error

	 mov	 CFG_SEG,ax	; Save the .CFG segment

	 DOSCALL @CLOSF2	; Close the file

; Patch the EGA Save Ptr location (0:4A8)

	 xor	 ax,ax		; Address the IDT
	 mov	 ds,ax		; ... via DS
	 assume  ds:INTVEC	; Tell the assembler about it

	 mov	 ax,bp		; Get segment of BIO image
	 shl	 eax,16 	; Move segment to upper half

	 call	 EXEC_SAVEPTR	; Search .CFG file for save ptr location
				; Return value in AX

	 mov	 INT00_VEC+(4A8h),eax ; Set the new EGA Save Pointer

; Patch INT 10 address (0:40)

	 mov	 ax,bp		; Get segment of BIO image
	 shl	 eax,16 	; Move segment to upper half

	 call	 EXEC_I10	; Search .CFG file for INT 10 location
				; Return value in AX

	 mov	 INT00_VEC+(4*10h),eax ; Set the new INT 10 value

; Patch the BIOS itself

	 mov	 ds,bp		; Address the .BIO image via DS
	 assume  ds:nothing	; Tell the assembler about it

	 call	 EXEC_PATCH	; Search the patch points, fix up
				; any that require patching

	 clc			; Indicate success

	 jmp	 short EXECUTE_BIOS_EXIT ; All done

EXECUTE_BIOS_STC:
	 DOSCALL @STROUT,BIOS_READ_ERR; Display error message
	 stc			; Mark as unsuccessful

EXECUTE_BIOS_EXIT:

	 REGREST <ds,bp,di,cx,bx,ax> ; Restore registers
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EXECUTE_BIOS endp			 ; End EXECUTE_BIOS procedure

;*****************************************************************************

	  NPPROC  READ_FILE -- Read in a .BIO file
	  assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Reads in a .BIO file

On entry:	BIOS_SEG =	Segment to load disk image into

On exit :	CF	=	1 if Read Error.

		AX	=	Paragraph of file image
		BX	=	File Handle

|

	 REGSAVE <cx,dx,si,di>	; Save registers

; Open the filename in TXTBUF

	 mov	 al,@OPEN_RW	; Code for read-write access
	 DOSCALL @OPENF2,BIOS_FNAME ; Open it
	 jc	 READ_FILE_EXIT ; Jump if error (Note: CF significant)

	 mov	 bx,ax		; Copy to handle register

; Read in the file

	 mov	 cx,-1		; Read in the entire file
	 REGSAVE <ds>		; Save segment register

	 mov	 dx,BIO_SEG	; Get segment of buffer ...
	 mov	 ds,dx		; ... and address it
	 assume ds:nothing	; Tell the assembler about it

	 xor	 dx,dx		; Get offset of buffer

	 DOSCALL @READF2	; Read it (into DS:DX)

	 REGREST <ds>		; Pop the segment register
	 assume  ds:PGROUP	; Tell the assembler about it

	 jc	 READ_FILE_EXIT ; Jump if error (CF significant)

	 mov	 TXTLEN,ax	; Save # bytes read

	 shr	 ax,(4-0)	; Convert bytes to paras
	 mov	 cx,ax		; Save to update for next read

	 mov	 ax,BIO_SEG	; Return para of our BIOS copy
	 add	 BIO_SEG,cx	; Update next avail para

	 clc			; Mark as success

READ_FILE_EXIT:

	 REGREST <di,si,dx,cx>	; Restore

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_FILE endp			 ; End READ_FILE procedure

;***************************************************************************

	 NPPROC  EXEC_SAVEPTR -- EXEC_SAVEPTR Procedure
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Search the .CFG file for the EGA save Pointer entry.

On exit:
AX	=	Offset value within BIOS of EGA Save Pointer

|

	 REGSAVE <cx,si,di,ds,es> ; Save registers

	 mov	 es,CFG_SEG	; Address the .CFG file via ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,9		; The EGA Save Ptr is the 9th entry
	 mov	 al,'>'         ; Search for this
	 xor	 di,di		; Start at begining of file

@@:
	 REGSAVE <cx>		; Save outer counter

	 mov	 cx,-1		; Search count (inner loop counter)
   repne scas	 [di].LO	; Search for the byte

	 REGREST <cx>		; Restore outer counter

	 loop	 @B		; Search for next marker

; We are at the correct line in the .CFG file
; The line should look like  ">C000:009F,001C"

	 add	 di,5		; Point to the offset field in current line
	 mov	 si,di		; Set up for HEX2BIN

	 mov	 ax,es		; Address .CFG file
	 mov	 ds,ax		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,cs		; Address our data (HEXTABLE in particular)
	 mov	 es,ax		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 HEX2BIN	; Convert ASCII hex at DS:SI to binary in AX

	 REGREST <es,ds,di,si,cx> ; Restore registers
	 assume  ds:PGROUP	; Tell the assembler about it
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EXEC_SAVEPTR	 endp			; End EXEC_SAVEPTR procedure

;***************************************************************************

	 NPPROC  EXEC_I10 -- EXEC_I10 Procedure
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Search the .CFG file for a interrupt 10's entry point

On exit:
AX	=	Offset value within BIOS of Interrupt 10 entry point

|

	 REGSAVE <cx,si,di,ds,es> ; Save registers

	 mov	 es,CFG_SEG	; Address the .CFG file via ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,2+1 	; I10 entry is 2nd entry (plus Copyright paren)
	 mov	 al,')'         ; Search for this
	 xor	 di,di		; Start at begining of file

@@:
	 REGSAVE <cx>		; Save outer counter

	 mov	 cx,-1		; Search count (inner loop counter)
   repne scas	 [di].LO	; Search for the byte

	 REGREST <cx>		; Restore outer counter

	 loop	 @B		; Search for next marker

; We are at the correct line in the .CFG file
; The line should look like "0040) C000:0A7E"

	 add	 di,6		; Point to the offset field in current line
	 mov	 si,di		; Set up for HEX2BIN

	 mov	 ax,es		; Address .CFG file
	 mov	 ds,ax		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,cs		; Address our data (HEXTABLE in particular)
	 mov	 es,ax		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 HEX2BIN	; Convert ASCII hex at DS:SI to binary in AX

	 REGREST <es,ds,di,si,cx> ; Restore registers
	 assume  ds:PGROUP	; Tell the assembler about it
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EXEC_I10	 endp			; End EXEC_I10 procedure

;***************************************************************************

	 NPPROC  EXEC_PATCH -- EXEC_PATCH Procedure
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Search the .CFG file for all misc. patch points
Patch all appropriate patch points

On entry:
DS	=	Segment of .BIO file

|

	 REGSAVE <ax,bx,cx,si,di,ds,es,fs> ; Save registers

	 mov	 es,CFG_SEG	; Address the .CFG file via ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,11		; Look for the last '>' marker
	 mov	 al,'>'         ; Search for this
	 xor	 di,di		; Start at begining of file

@@:
	 REGSAVE <cx>		; Save outer counter

	 mov	 cx,-1		; Search count (inner loop counter)
   repne scas	 [di].LO	; Search for the byte

	 REGREST <cx>		; Restore outer counter

	 loop	 @B		; Search for next marker

; We are one line before the correct line in the .CFG file
; The line should look like ">C000:0068,0024"

	 add	 di,16		; Point to the next line (first patch line)
	 mov	 si,di		; Set up for HEX2BIN

; We are at the correct line in the .CFG file
; The line should look like "0024 09"

	 mov	 ax,ds		; Address the .BIO file
	 mov	 fs,ax		; ... via FS
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 ax,es		; Address .CFG file
	 mov	 ds,ax		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,cs		; Address our data (HEXTABLE in particular)
	 mov	 es,ax		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

SP_NEXT:
	 call	 HEX2BIN	; Convert ASCII hex at DS:SI to binary in AX
	 mov	 bx,ax		; Save BIOS offset (of C000 match)

	 lodsb			; Get next character from .CFG file
				; it should be ' ', ')', or CR

	 cmp	 al,')'         ; Izit end of the line?
	 je	 short SP_EXIT	; Jump if so

	 cmp	 al,' '         ; Izit a space?
	 je	 short SP_SPACE ; Jump if so

	 cmp	 al,CR		; Izit end of line?
	 jne	 short SP_EXIT	; Jump if not (this should not happen)

SP_CR:
	 add	 si,2		; Skip past CR,LF
	 mov	 fs:[bx],fs	; Patch the .BIO image

	 jmp	 short SP_NEXT	; Process next line

SP_SPACE:
	 lodsw			; Get ASCII two digit reason code

	 cmp	 ax,'90'        ; Izit EGA save ptr?
	 je	 short SP_REASON ; Jump if so (patch this entry)

	 cmp	 ax,'A0'        ; Izit VGA save ptr?
	 je	 short SP_REASON ; Jump if so (patch this entry)

	 add	 si,2		; Skip CR,LF

	 jmp	 short SP_NEXT	; Process next line

SP_REASON:
	 add	 si,2		; Skip past CR,LF
	 mov	 fs:[bx],fs	; Patch the .BIO image

	 jmp	 short SP_NEXT	; Process next line

SP_EXIT:
	 REGREST <fs,es,ds,di,si,cx,bx,ax> ; Restore registers
	 assume  ds:PGROUP	; Tell the assembler about it
	 assume  es:PGROUP	; Tell the assembler about it
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EXEC_PATCH	 endp			; End EXEC_PATCH procedure

;*****************************************************************************

	  NPPROC  DISPLAY -- Display data to screen and CFG file
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Display data to screen and to CFG file

On entry :	DX = address of message to display
		CX = Byte count (not including EOS)

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 test	 LCL_FLAG,@LCL_CMDLINE ; Comming from the command line?
	 jz	 short DISPLAY_EXIT ; Jump if not

	 test	 LCL_FLAG,@LCL_VGASWAP ; Are we testing only?
	 jnz	 short DISPLAY_EXIT ; Jump if so

; Display on the screen

	 DOSCALL @STROUT	; Display the string

	 test	 LCL_FLAG,@LCL_WRITE ; Write BIO file to disk?
	 jz	 short @F	; Jump if not

; Write to file

	 mov	 bx,FILEHNDL	; get file handle of CFG file
	 DOSCALL @WRITF2	; Write out the information
;;;;;;;; jc	 DISPLAY_STC	; Jump if unable to write
;;;;;;;;
;;;;;;;; cmp	 ax,cx		; Izit the same length?
;;;;;;;; jne	 DISPLAY_STC	; Jump if not
@@:

;;;;;;;; jmp	 short DISPLAY_EXIT ; All done

DISPLAY_STC:
DISPLAY_EXIT:

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPLAY endp			 ; End DISPLAY procedure

;************************************************************************

	 NPPROC  CHK_CREG -- Check Cursor Register DX For Adapter Presence
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Test for monochrome or color video adapter presence

On entry:
AX	=	3B4h if testing for mono adapter
		3D4h if testing for color adapter

On exit:
CF	=	0 if present
		1 if not

|

	 REGSAVE <ax,dx>	; Save registers

	 mov	 al,0Fh 	; Set CRTC to address cursor register
	 out	 dx,al		; Tell CRTC about it
	 inc	 dx		; Point to data register
	 jmp	 short $+2	; I/O delay for PC AT
	 jmp	 short $+2
	 jmp	 short $+2

	 in	 al,dx		; Save original value
	 push	 ax		; on the stack
	 mov	 al,5Ah 	; Test value for cursor position
	 out	 dx,al		; Tell CRTC about it
	 jmp	 short $+2	; I/O delay for PC AT
	 jmp	 short $+2
	 jmp	 short $+2

	 in	 al,dx		; Read it back in

	 cmp	 al,5Ah 	; Check against test value
	 pop	 ax		; Restore original cursor value
	 jmp	 short $+2	; I/O delay for PC AT
	 jmp	 short $+2
	 jmp	 short $+2

	 out	 dx,al		; Restore original value in CRTC
	 jne	 short CHK_CREG_NO ; Not present

	 clc			; Indicate it's present
	 jmp	 short CHK_CREG_EXIT ; Join common exit code

CHK_CREG_NO:
	 stc			; Indicate it's not present
CHK_CREG_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHK_CREG endp			; End CHK_CREG procedure

;************************************************************************

	 NPPROC  IZITEGA -- Check For Presence of EGA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return AX = -1 if EGA not present, otherwise
       AL =  0 if present and in color mode
	     1		      in mono mode
	     2		      in enhanced color mode
       AH = memory settings (0 = 64k, 1 = 128k, 2 = 192k, 3 = 256k)
|

	 REGSAVE <bx,cx>	; Save registers

	 mov	 bl,10h 	; Function code to return EGA information
	 mov	 bh,0FFh	; Set to value out of range
	 mov	 cl,0Fh 	; Ditto

	 VIDCALL @GETEGA	; Get EGA information
				; If EGA present, return with
				; BH = 0 if color mode, 1 if mono
				; BL = 0 (64k), 1 (128k), 2 (192k), 3 (256k)
				; CH = feature bits
				; CL = switch setting

	 mov	 ax,-1		; Assume not present

	 cmp	 bh,01h 	; Check against maximum allowed value
	 ja	 short IZITEGA_EXIT ; Invalid, no EGA

	 cmp	 bl,03h 	; Check against maximum allowed value
	 ja	 short IZITEGA_EXIT ; Invalid, no EGA

	 cmp	 cl,0Bh 	; Check against maximum allowed value
	 ja	 short IZITEGA_EXIT ; Invalid, no EGA

	 mov	 al,bh		; Copy mode to AL
	 mov	 ah,bl		; ...and memory size to AH

	 cmp	 cl,9		; Check switch setting for enhanced color mode
	 jne	 short IZITEGA_EXIT ; Not this time

	 mov	 al,2		; It's in enhanced color mode
IZITEGA_EXIT:
	 REGREST <cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITEGA  endp			; End IZITEGA procedure

;************************************************************************

	 NPPROC  IZITVGA -- Check For Presence of VGA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
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

IZITVGA  endp			; End IZITVGA procedure

;***************************************************************************

	 NPPROC  SRCHSTR -- Search For A String
	 assume  ds:PGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
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

	 mov	 si,[bp].SRCHSTR_OFF1 ; FS:SI ==> source string
	 mov	 cx,[bp].SRCHSTR_LEN2 ; Get length of search area
	 sub	 cx,[bp].SRCHSTR_LEN1 ; Less length of the string
	 dec	 cx		; Less one to not fall off the end
	 mov	 al,fs:[si]	; Get the first byte
SRCHSTR_NEXT:
	 jcxz	 SRCHSTR_ERR	; Jump if no more bytes to check
   repne scas	 es:[di].LO	; Search for the 1st byte
	 jne	 short SRCHSTR_ERR ; Jump if no match

	 REGSAVE <cx,di>	; Save registers
	 mov	 si,[bp].SRCHSTR_OFF1 ; FS:SI ==> source string
	 inc	 si		; Plus one to account for the first match
	 mov	 cx,[bp].SRCHSTR_LEN1 ; Get length of the string
	 dec	 cx		; Less one to account for the first match
    repe cmps	 fs:[si].LO,es:[di].LO ; Check the rest
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

;************************************************************************

	  NPPROC  FMT_BYTE -- Format AL to Hex at ES:DI
	  assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Format AL to Hex at ES:DI

|

	  REGSAVE <ax,bx,cx,dx>  ; Save registers

	  lea	  bx,HEXTABLE	 ; DS:BX ==> translate table
	  mov	  cx,2		 ; # hex digits in a byte
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
COMMENT |

Format AX to Hex at ES:DI

|

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

	 lea	 di,HEXTABLE	; ES:DI ==> uppercase hex digits
	 mov	 cx,16		; Length of ...
   repne scasb			; Search for it
	 jne	 short HEX2BIN_EXIT ; Jump if not hex

	 sub	 di,1+offset PGROUP:HEXTABLE ; Convert to origin-0
	 shl	 dx,4		; Shift over one hex digit
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

;***************************************************************************

	 NPPROC  READ_CMOS -- Read CMOS Data
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read CMOS data

On entry:
AH	 =	 index register to read

On exit:
AL	 =	 data value for register in AH

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 al,ah		; Copy register # to AL
	 out	 @CMOS_CMD,al	; Send command to CMOS
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Read data from CMOS

	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_CMOS endp			; End READ_CMOS procedure

;***************************************************************************

	 NPPROC  SRCH_INT -- Search For Video Interrupts
	 assume  ds:PGROUP,es:PGROUP,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Search for video interrupts

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,bx,cx,si,ds,gs> ; Save registers

	 push	 seg AGROUP	; Get interrupt vector segment
	 pop	 gs		; Address it
	 assume  gs:AGROUP	; Tell the assembler about it

; Initialize ROMADDR_LO and ROMADDR_HI

	 mov	 ax,BIOS_SRC	; Get BIOS source
	 mov	 ROMADDR_LO,ax	; ... and store as low point of ROM

	 mov	 bx,BIOS_LEN	; Get BIOS length
	 shr	 bx,(4-0)	; Convert from bytes to paras
	 add	 ax,bx		; Add together (start + length)
	 mov	 ROMADDR_HI,ax	; ... and store as high point of ROM

; Save old INT 01h handler to restore later

	 push	 es		; Save for a moment

	 mov	 al,01h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT 01h handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 CPQINT01_VEC.VOFF,bx ; Save to restore later
	 mov	 CPQINT01_VEC.VSEG,es

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

; Set address of action routine if found

	 mov	 FINDHW_ACT,offset PGROUP:FINDHW_ROM ; Save it

	 mov	 cx,NBCFINTS	; CX = # interrupt vectors to check
	 lea	 si,BCFINTS	; PGROUP:SI ==> BCF interrupt structures

SRCH_INT_NEXT:
	 mov	 eax,PGROUP:[si].BCFINT_VEC ; Get offset into segment 0
	 mov	 CPQINT01_SAVE,eax ; Save as seed in case of ignore
	 mov	 bx,ax		; Copy the offset to index register

	 mov	 ax,AGROUP:[bx].VSEG ; Get the segment from segment 0

	 and	 ax,ax		; Izit valid?
	 jz	 short SRCH_INT_LOOP ; Jump if not

	 cmp	 ax,SYSROM_START ; Izit in system ROM?
	 jae	 short SRCH_INT_LOOP ; Jump if so

	 cmp	 ax,ROMADDR_LO	; Izit below lowest video ROM?
	 jb	 short @F	; Jump if so

	 cmp	 ax,ROMADDR_HI	; Izit above highest video ROM?
	 jb	 short SRCH_INT_LOOP ; Jump if not (it's already in ROM)

@@:
	 cmp	 bx,4*100h	; Check for above the interrupt vector section
	 jae	 short SRCH_INT_XINT ; Jump if it's too large

; None of the above -- search for the original address

	 REGSAVE <bx,es>	; Save for a moment

	 mov	 ax,bx		; Get offset into segment 0
	 shr	 ax,2-0 	; Convert from bytes to dwords
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT xxh handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINTHW_VEC.VOFF,bx ; Save to use later
	 mov	 OLDINTHW_VEC.VSEG,es

	 REGREST <es,bx>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it
SRCH_INT_XINT:

	 call	 PGROUP:[si].BCFINT_FIND ; Take appropriate action
	 jc	 near ptr SRCH_INT_ERR ; Jump if we didn't find it

	 btr	 CPQ_FLAG,$CPQ_TRIPERR ; Did we trip on the trip?
	 jc	 near ptr SRCH_INT_ERR ; Jump if we tripped

	 mov	 eax,CPQINT01_SAVE ; EAX ==> saved interrupt vector
	 mov	 PGROUP:[si].BCFINT_VEC,eax ; Save for later use
SRCH_INT_LOOP:

	 call	 DISP_INT	; Display the single-step findings

	 add	 si,size BCFINT_STR ; Skip to next entry

	 loop	 SRCH_INT_NEXT	; Jump if more BCF interrupts to search
;;;;;;;; dec	 cx		; Count one more interrupt as processed
;;;;;;;; jnz	 SRCH_INT_NEXT	; Jump if more interrupts to search

	 clc			; Indicate all went well

	 jmp	 short SRCH_INT_EXIT ; Join common exit code

SRCH_INT_ERR:
;;;;;;;; test	 CMD_FLAG,@CMD_FORCEBCF ; Ignore BCF error?
;;;;;;;; jnz	 short SRCH_BCFINT_LOOP ; Jump if so
;;;;;;;;
;;;;;;;; REGSAVE <di,es>	; Save for a moment
;;;;;;;;
;;;;;;;; push	 seg PGROUP	; Get data segment
;;;;;;;; pop	 es		; Address it
;;;;;;;; assume  es:PGROUP	; Tell the assembler about it
;;;;;;;;
;;;;;;;; mov	 ax,bx		; Get the offset in segment 0
;;;;;;;; lea	 di,PGROUP:MSG_BCF_INT1 ; ES:DI ==> output save area
;;;;;;;; mov	 cx,16		; Convert in hexadecimal
;;;;;;;; call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI
;;;;;;;;
;;;;;;;; REGREST <es,di>	; Restore
;;;;;;;; assume  es:PGROUP	; Tell the assembler about it

	 stc			; Indicate something went wrong
SRCH_INT_EXIT:

	 REGREST <gs,ds,si,cx,bx,eax> ; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH_INT endp			; End SRCH_INT procedure

;***************************************************************************

	 NPPROC  DISP_INT -- DISP_INT Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Display the single-step findings
Also evaluate the code for the JUMPF peculiarity

On entry:
BX	=	Interrupt number * 4

|

	 REGSAVE <eax,cx,dx,di,fs> ; Save registers

; Format the interrupt number

	 mov	 ax,bx		; Get interrupt number
	 lea	 di,MSG_ENTRY_NUM ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

; Address the segment that holds the BIOS entry address

	 mov	 fs,CPQINT01_SAVE.VSEG ; Get segment
	 assume  fs:nothing	; Tell the assembler about it

; Format the BIOS entry address

	 mov	 di,CPQINT01_SAVE.VOFF ; Get offset of dword place holder
	 mov	 eax,dword ptr fs:[di] ; Get entry point Seg:Offset

	 mov	 dx,ax		; Save entry point offset
	 lea	 di,MSG_ENTRY_OFF1 ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 shr	 eax,16 	; Get entry point segment
	 mov	 fs,ax		; Address the opcode
	 assume fs:nothing	; Tell the assembler about it

	 lea	 di,MSG_ENTRY_SEG1 ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

; Format the JMPF statement

	 mov	 dword ptr MSG_ENTRY_OPCOD,'    ' ; Assume not JMPF
	 mov	 dword ptr MSG_ENTRY_SEG2, '    ' ; Assume not JMPF
	 mov	 byte  ptr MSG_ENTRY_COLON,' '    ; Assume not JMPF
	 mov	 dword ptr MSG_ENTRY_OFF2, '    ' ; Assume not JMPF

	 mov	 di,dx		; Copy offset to index register
	 cmp	 byte ptr fs:[di],@OPCOD_JMPF ; Izit our opcode?
	 jne	 short DISP_XFJMP ; Jump if not

	 mov	 dword ptr MSG_ENTRY_OPCOD,'FPMJ' ; It is a FAR JUMP

; Format the FAR JUMP address

	 mov	 ax,fs:[di+1].VSEG ; Get FJMP segment
	 mov	 dx,di		; Save for a moment
	 lea	 di,MSG_ENTRY_SEG2 ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 byte  ptr MSG_ENTRY_COLON,':'

	 mov	 di,dx		; Restore
	 mov	 ax,fs:[di+1].VOFF ; Get FJMP offset
	 lea	 di,MSG_ENTRY_OFF2 ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

; Record the address for later translation

	 mov	 di,dx		; Restore index register
	 mov	 ax,fs:[di+1].VSEG  ; Get the segment of the FJMP
	 cmp	 BIOS_ADDRESS,ax ; Is this patch within the BIOS?
	 jne	 short DISP_XFJMP ; Jump if Far Jump is not within the BIOS

	 add	 dx,3		; Point to the segment portion of the instruction
	 mov	 di,SPECIAL_ADDR_CNT ; Get next index number
	 shl	 di,1		; Convert from bytes to words

	 mov	 SPECIAL_ADDR[di],dx ; Store value for later
	 inc	 SPECIAL_ADDR_CNT ; Count in one more special address

DISP_XFJMP:

; Display the line

	 lea	 dx,MSG_ENTRY_NUM ; Address of message
	 mov	 cx,@MSG_ENTRY_LEN ; Length of message
	 call	 DISPLAY	; Display the opening message

	 REGREST <fs,di,dx,cx,eax> ; Restore registers
	 assume  fs:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_INT	 endp			; End DISP_INT procedure

;***************************************************************************

	 FPPROC  CPQINT01 -- Single-step Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Single-step interrupt handler

|

CPQINT01_STR struc

CPQINT01_BP dw	 ?		; Caller's BP
CPQINT01_IP dw	 ?		; ...	   IP
CPQINT01_CS dw	 ?		; ...	   CS
CPQINT01_FL dw	 ?		; ...	   FL
CPQINT01_FL2 dw  ?		; ...	   FL if CS:IP ==> POPF

CPQINT01_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 test	 CPQ_FLAG,mask $CPQ_TRIP ; Izit set already?
	 jnz	 short CPQINT01_CLR ; Jump if so

	 test	 CPQ_FLAG,mask $CPQ_I01 ; Izit active?
	 jz	 short CPQINT01_CLR ; Jump if not

; Determine if we are in the ROM that we are looking for

	 push	 ax		; Save for a moment
	 mov	 ax,[bp].CPQINT01_CS ; Get the current segment
	 cmp	 ax,ROMADDR_HI ; Izit above our top?
	 pop	 ax		; Restore
	 jae	 short CPQINT01_SAVELAST ; Jump if too high

	 push	 ax		; Save for a moment
	 mov	 ax,[bp].CPQINT01_CS ; Get the current segment
	 cmp	 ax,ROMADDR_LO	; Izit below our bottom?
	 pop	 ax		; Restore
	 jb	 short CPQINT01_SAVELAST ; Jump if too low

; We entered the ROM!

	 push	 CPQINT01_LAST.VSEG ; Get last segment
	 push	 CPQINT01_LAST.VOFF ; ...      offset

	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 pop	 CPQINT01_TRIP.VOFF ; Save as tripping offset
CSOVR	 pop	 CPQINT01_TRIP.VSEG ; ...	       segment
	 assume  ds:nothing	; Retract nose

	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 mov	 <TRIP_DS,ds>	; Save all segment registers
CSOVR	 mov	 <TRIP_ES,es>
CSOVR	 mov	 <TRIP_SS,ss>
CSOVR	 mov	 <TRIP_BX,bx>
CSOVR	 mov	 <TRIP_SI,si>
CSOVR	 mov	 <TRIP_DI,di>
	 assume  ds:nothing	; Retract nose

	 push	 [bp].CPQINT01_BP ; Get caller's BP

	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 pop	 TRIP_BP
CSOVR	 or	 <CPQ_FLAG,mask $CPQ_TRIP> ; Mark as set
	 assume  ds:nothing	; Retract nose
CPQINT01_CLR:
	 and	 [bp].CPQINT01_FL,not (mask $TF) ; Clear trap flag

	 jmp	 short CPQINT01_IRET ; Join common IRET code

CPQINT01_SAVELAST:
	 assume  ds:PGROUP	; Tell a white lie
	 push	 [bp].CPQINT01_CS   ; Get caller's segment
	 push	 [bp].CPQINT01_IP   ; ...	   offset
CSOVR	 pop	 CPQINT01_LAST.VOFF ; Save as last offset
CSOVR	 pop	 CPQINT01_LAST.VSEG ; ...	   segment
	 assume  ds:nothing	; Retract nose

; Check for next instruction as IRET or POPF

	 REGSAVE <ax,si,di,ds>	; Save registers

	 lds	 si,CPQINT01_LAST ; Get address of next instruction
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 di,0		; Assume it's POPF (# bytes to skip up stack)

	 cmp	 ds:[si].LO,@OPCOD_POPF ; Izit a POPF?
	 je	 short CPQINT01_TF ; Jump if so

	 mov	 di,4		; Assume it's IRET (# bytes to skip up stack)

	 cmp	 ds:[si].LO,@OPCOD_IRET ; Izit an IRET?
	 jne	 short @F	; Jump if not
CPQINT01_TF:
	 or	 [bp+di].CPQINT01_FL2,mask $TF ; Ensure trap flag set
@@:
	 REGREST <ds,di,si,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
CPQINT01_IRET:
	 pop	 bp		; Restore

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CPQINT01 endp			; End CPQINT01 procedure

;***************************************************************************

	 NPPROC  FINDIGN -- Ignore If There's A Mismatch
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The interrupt vector's segment is not in F000.

Ignore it.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 clc			; Mark as successful

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDIGN  endp			; End FINDIGN procedure

;***************************************************************************

	 NPPROC  FIND10 -- Find The Owner Of INT 10h/6Dh
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 10h/6Dh.

On entry:

All registers may be significant.
OLDINTHW_VEC contains address of routine to execute.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax>		 ; Save register

	 mov	 ah,@GETINF	; Code to get video information
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND10	 endp			; End FIND10 procedure

;***************************************************************************

	 NPPROC  FINDCHK -- Find An Interrupt Vector
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The interrupt vector's segment is not in F000.

Attempt to find it, but don't get upset if we don't.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 call	 FINDHW 	; Call as hardware interrupt
				; Return with CF significant
	 adc	 IGNCNT,0	; Count it in if we failed

	 and	 CPQ_FLAG,not (mask $CPQ_TRIPERR) ; Ignore trip failure

	 clc			; Mark as successful

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDCHK  endp			; End FINDCHK procedure

;***************************************************************************

	 NPPROC  FINDHW -- Find Owner of Hardware Interrupt
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of a hardware interrupt.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 mov	 OLDCPQSTK_VEC.VSEG,ss ; Save old stack pointers
	 mov	 OLDCPQSTK_VEC.VOFF,sp ; ...

	 push	 cs		; Get new stack segment
	 pop	 ss		; Address it
	 assume  ss:nothing	; Tell the assembler about it
	 lea	 sp,CPQSTKZ	; SS:SP ==> new stack

	 REGSAVE <ax,dx>	; Save registers

; Install our own single-step interrupt handler

	 mov	 al,01h 	; Intercept this one
	 DOSCALL @SETINT,CPQINT01 ; Install our own one

	 or	 CPQ_FLAG,mask $CPQ_I01 ; Mark as active

	 REGREST <dx,ax>	; Restore

STK_STR  struc

	 dw	 ?		; Caller's BP
STK_ARG1 dw	 ?		; Argument #1

STK_STR  ends

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es>	; Save segment registers

	 pushf			; Simulate INT calling environment
	 cli

	 pushf			; Save flags
	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack
	 or	 [bp].STK_ARG1,mask $TF ; Set trap flag
	 pop	 bp		; Restore
	 popf			; Put into effect

	 call	 OLDINTHW_VEC	; Request hardware interrupt service

	 REGREST <es,ds>	; Restore
	 popad			; Restore all EGP registers

	 and	 CPQ_FLAG,not (mask $CPQ_I01) ; Mark as inactive

	 REGSAVE <ax,dx,ds>	; Save registers

	 test	 CPQ_FLAG,mask $CPQ_I1B ; Is Ctrl-Break active?
	 jz	 short @F	; Jump if not

	 DOSCALL @KEYSTA	; Get keyboard status and check for Ctrl-Break
				; Ignore return value
@@:
	 mov	 al,01h 	; Restore this one
	 lds	 dx,CPQINT01_VEC ; DS:DX ==> original handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Restore the original handler

	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 btr	 CPQ_FLAG,$CPQ_TRIP ; Test and reset trip flag
	 cmc			; Complement to conform to prologue
	 jc	 short FINDHW_EXIT ; Jump if not found (note CF=1)

; Calculate the address of the dword with original
; hardware interrupt handler address

	 call	 DECODE_TRIP	; Attempt to decode the tripping address
	 jc	 short FINDHW_EXIT ; Jump if not found (note CF=1)

	 call	 FINDHW_ACT	; Take appropriate action

	 clc			; Indicate all went well
FINDHW_EXIT:
	 lss	 sp,OLDCPQSTK_VEC ; Restore original stack pointer
	 assume  ss:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDHW	 endp			; End FINDHW procedure

;***************************************************************************

	 NPPROC  DECODE_TRIP -- Decode The Tripping Address
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Decode the tripping address

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,si,es>	; Save registers

; Calculate the address of the dword with original INT 13h handler address

	 mov	 ax,TRIP_DS	; Get default segment register
	 mov	 CPQINT01_SAVE.VSEG,ax ; Save for later use
	 and	 CPQ_FLAG,not (mask $CPQ_SEG) ; Mark as not present

	 les	 si,CPQINT01_TRIP ; ES:SI ==> tripping address
	 assume  es:nothing	; Tell the assembler about it
DECODE_NEXT:
	 lods	 es:[si].LO	; Get next byte

	 cmp	 al,@OPCOD_CS	; Izit CS: override?
	MJ e	 DECODE_CS	; Jump if so

	 cmp	 al,@OPCOD_DS	; Izit DS: override?
	MJ e	 DECODE_DS	; Jump if so

	 cmp	 al,@OPCOD_ES	; Izit ES: override?
	MJ e	 DECODE_ES	; Jump if so

	 cmp	 al,@OPCOD_SS	; Izit SS: override?
	MJ e	 DECODE_SS	; Jump if so

	 cmp	 al,@OPCOD_CALLF ; Izit far call immediate?
	MJ e	 DECODE_IMMED	; Jump if so

	 cmp	 al,@OPCOD_JMPF ; Izit far jump immediate?
	MJ e	 DECODE_IMMED	; Jump if so

	 cmp	 al,@OPCOD_GRP5 ; Izit a Group 5 instruction?
	MJ ne	 DECODE_ERR	; Jump if not

	 lods	 es:[si].LO	; Get the MOD R/M byte

	 mov	 ah,al		; Copy for destructive testing
	 and	 ah,mask $REG	; Isolate the register field
	 shr	 ah,$REG	; Shift to low-order

	 cmp	 ah,011b	; Izit CALL Ep?
	 je	 short @F	; Jump if so

	 cmp	 ah,101b	; Izit JMP Ep?
	MJ ne	 DECODE_ERR	; Jump if not
@@:
	 and	 al,not (mask $REG) ; Clear the REG field
	 mov	 ah,al		; Copy for destructive testing
	 and	 ah,mask $MOD	; Isolate the MOD field
	 shr	 ah,$MOD	; Shift to low-order

	 cmp	 ah,11b 	; Izit MOD = 11?
	MJ e	 DECODE_ERR	; Jump if so

	 cmp	 al,(00b shl $MOD) or (110b shl $RM) ; Izit special 00xxx110 ?
	MJ e	 DECODE_D16	; Jump if so

	 cmp	 ah,00b 	; Izit MOD = 00?
	 je	 short DECODE_EA ; Yes, just no displacement

	 cmp	 ah,01b 	; Izit MOD = 01?
	 je	 short DECODE_D8 ; Yes, get sign-extended DISP8
				; Fall through for 16-bit displacement w/EA

	 lods	 es:[si].ELO	; Get the 16-bit displacement
	 mov	 CPQINT01_SAVE.VOFF,ax ; Save for later use

	 jmp	 short DECODE_EA ; Join common EA code

DECODE_D8:
	 lods	 es:[si].LO	; Get the 8-bit displacement
	 cbw			; Sign extend it
	 mov	 CPQINT01_SAVE.VOFF,ax ; Save for later use
DECODE_EA:
	 and	 al,mask $RM	; Isolate R/M field
	 shr	 al,$RM 	; Shift to low-order
	 mov	 bh,0		; Zero to use as word
	 mov	 bl,al		; Copy to index register
	 shl	 bx,1		; Times two to index table odd words

	 jmp	 PRMACT[bx]	; Take appropriate action

; Effective address is BX+SI

RM000:
	 mov	 ax,TRIP_BX	; Get base value
	 add	 ax,TRIP_SI	; Plus index value

	 jmp	 short DECODE_OFF ; Join common code

; Effective address is BX+DI

RM001:
	 mov	 ax,TRIP_BX	; Get base value
	 add	 ax,TRIP_DI	; Plus index value

	 jmp	 short DECODE_OFF ; Join common code

; Effective address is BP+SI

RM010:
	 mov	 ax,TRIP_BP	; Get base value
	 add	 ax,TRIP_SI	; Plus index value

	 jmp	 short DECODE_CHKSS ; Join common SS checking code

; Effective address is BP+DI

RM011:
	 mov	 ax,TRIP_BP	; Get base value
	 add	 ax,TRIP_DI	; Plus index value

	 jmp	 short DECODE_CHKSS ; Join common SS checking code

; Effective address is SI

RM100:
	 mov	 ax,TRIP_SI	; Get index value

	 jmp	 short DECODE_OFF ; Join common code

; Effective address is DI

RM101:
	 mov	 ax,TRIP_DI	; Get index value

	 jmp	 short DECODE_OFF ; Join common code

; Effective address is BP

RM110:
	 mov	 ax,TRIP_BP	; Get base value
DECODE_CHKSS:
	 test	 CPQ_FLAG,mask $CPQ_SEG ; Izit present?
	 jnz	 short @F	; Jump if so

	 mov	 bx,TRIP_SS	; Get default segment override
	 mov	 CPQINT01_SAVE.VSEG,bx ; Save for later use
@@:
	 jmp	 short DECODE_OFF ; Join common

; Effective address is BX

RM111:
	 mov	 ax,TRIP_BX	; Get base value
DECODE_OFF:
	 add	 CPQINT01_SAVE.VOFF,ax ; Save for later use

	 jmp	 short DECODE_CLC ; Join common OK code

DECODE_D16:
	 lods	 es:[si].ELO	; Get the 16-bit displacement
	 mov	 CPQINT01_SAVE.VOFF,ax ; Save for later use

	 jmp	 short DECODE_CLC ; Join common OK code

DECODE_CS:
	 mov	 ax,TRIP_CS	; Get segment register value

	 jmp	 short DECODE_SEG ; Join common code

DECODE_DS:
	 mov	 ax,TRIP_DS	; Get segment register value

	 jmp	 short DECODE_SEG ; Join common code

DECODE_ES:
	 mov	 ax,TRIP_ES	; Get segment register value

	 jmp	 short DECODE_SEG ; Join common code

DECODE_SS:
	 mov	 ax,TRIP_SS	; Get segment register value
DECODE_SEG:
	 or	 CPQ_FLAG,mask $CPQ_SEG ; Mark as segment override present

	 mov	 CPQINT01_SAVE.VSEG,ax ; Save for later use

	 jmp	 DECODE_NEXT	; Go around again

DECODE_ERR:
	 or	 CPQ_FLAG,mask $CPQ_TRIPERR ; Mark as a trip

	 stc			; Mark as unsuccessful

	 jmp	 short DECODE_EXIT ; Join common exit code

DECODE_IMMED:
	 mov	 CPQINT01_SAVE.VOFF,si ; Save the address
	 mov	 CPQINT01_SAVE.VSEG,es
DECODE_CLC:
	 clc			; Mark as successful
DECODE_EXIT:
	 REGREST <es,si,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DECODE_TRIP endp		; End DECODE_TRIP procedure

;***************************************************************************

	 NPPROC  FINDHW_ROM -- Action Routine If Tripping Address Found
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action routine if tripping address found in CPQINT01_SAVE.
Do nothing.

Note that this routine is used in CHECK_BCF.

|

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDHW_ROM endp 		; End FINDHW_ROM procedure

;***************************************************************************

CODE	 ends			; End CODE segment

	 MEND	 INITIAL	; End XLAT module




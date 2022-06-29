;' $Header:   P:/PVCS/MAX/ROMSRCH/FUNCS.ASV   1.7   30 May 1997 12:14:54   BOB  $
	 title	 FUNCS -- List of functions for PROBE
	 page	 58,122
	 name	 FUNCS

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
	  include PTR.INC
	  include 8255.INC
	  include 386.INC
	  include VERSION.INC
	  include OPCODES.INC
	  include ABIOS.INC
	  include EISA.INC
	  include INTVEC.INC
	  include PCI.INC
	include PNP.INC

	  include PROBE.INC
	include QMAX_DBG.INC
	include EMM2CALL.INC
.list

PGROUP	 group	 STACK,CODE,DATA,DTAIL
PnPGRP	group	PnPSEG

;***************************************************************************

PnPSEG	segment use16 at 0
	assume	ds:PnPGRP

	public	PnPSTR
PnPSTR	PnP_STR <>		; Dummy struc

PnPSEG	ends

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

@ZTAIL	equ	offset PGROUP:ZTAIL ; Equate for end of our program

	extrn	DBG_FLAG:word
	extrn	PORT67:word

	extrn	PnP_SEG:word

	public	PnP_NodeSize,PnP_NumNodes,PnP_Node,PnP_CTL,PnP_Message
	public	PnP_MinESCDSize,PnP_ESCDSize,PnP_NVStorageBase
	public	PnP_APMSize,PnP_Version
	public	PnP_IPLDevCnt,PnP_IPLMaxCnt,PnP_IPLStrSize
	public	PnP_BCVDevCnt,PnP_BCVMaxCnt,PnP_BCVStrSize
	public	PnP_IPLDevBoot,PnP_Boot1st
PnP_NodeSize dw ?		; PnP size of largest device node
PnP_NumNodes db ?,?		; PnP # nodes the BIOS returns
PnP_Node     dw ?		; PnP node # for Get/Set System Device Nodes
PnP_CTL      dw ?		; PnP control flags
PnP_Message  dw ?		; Event message
PnP_MinESCDSize dw ?		; Minimum buffer byte size for writing to NVS
PnP_ESCDSize dw ?		; Size allocated for the ESCD within NV storage block
PnP_NVStorageBase dd ?		;
PnP_APMSize  dw ?		; APM buffer size
PnP_Version  dw ?		; BIOS Boot Spec Version
PnP_IPLDevCnt  dw ?		; BBS IPL Device count
PnP_IPLMaxCnt  dw ?		; BBS IPL Maximum Device count
PnP_IPLStrSize dw ?		; BBS IPL Struc Size
PnP_BCVDevCnt  dw ?		; BBS BCV Device count
PnP_BCVMaxCnt  dw ?		; BBS BCV Maximum Device count
PnP_BCVStrSize dw ?		; BBS BCV Struc Size
PnP_IPLDevBoot dw ?		; IPL Device from Last Boot
PnP_Boot1st    dw ?		; Boot First device

	public	LCL_PnP_RMDS,LCL_PnP_RMVEC
LCL_PnP_RMDS dw ?		; Local PnP RM data segment/selector
LCL_PnP_RMVEC dd ?		; ...	PnP RM entry point

	 public  INT_VECTOR,INTXX
INT_VECTOR	dd	?	; Used to simulate interrupt (PUSHF/CALLF)
INTXX		db	?	; The current interrupt number

	 public  OLDINT0A_VEC,OLDINT15_VEC
	 public  PORT21_TEMP,PORTA1_TEMP
OLDINT0A_VEC	 dd	 ?	; Storage for INT 0A vector
OLDINT15_VEC	 dd	 ?	; Storage for INT 15 vector
PORT21_TEMP	 db	 ?	; Port 21 (IMR) storage space (master)
PORTA1_TEMP	 db	 ?	; Port A1 (IMR) storage space (slave)

	 public  INT13_BIOS
INT13_BIOS	 dd	 ?	; Interrupt 13h BIOS entry point

	 public  SAVED_STACK
SAVED_STACK	 dd	 ?	; Stack used to regain control during
				; 'fatal' error handling


;---------------- Interrupt 5Ch special code --------------------

	 public  PNETB_CCB ,NETB_CCB, NETB_CCB_VEC, STATBLK
PNETB_CCB    dw  offset PGROUP:NETB_CCB ; Offset of NETBIOS CCB
	     dw  ?		; Segment ...
NETB_CCB     db  0,21h,-1,-1,8 dup (0) ; NETBIOS status call Command Control Block
NETB_CCB_VEC dw  offset PGROUP:STATBLK	; Offset of status block
	     dw  ?		; Segment ...
STATBLK      db  50 dup (?)	; Status block output save area

@PNETB	equ	 offset PGROUP:PNETB_CCB ; Offset to NetBIOS CCB

;----------------- Debugging messages --------------------------

	 public  DEBUG_BUFFER1
DEBUG_BUFFER1	label	 byte
DEBUG_BUFF_INT	db  '__: ('     ; Interrupt number
DEBUG_BUFF_CNT	db  '__/'       ; Interrupt counter (incremental)
DEBUG_BUFF_REM	db  '__)'       ; Interrupt counter (decremental)
@DEBUG_BUFLEN1	equ $-DEBUG_BUFFER1

	 public  DEBUG_BUFFER2
DEBUG_BUFFER2	db  'AX='       ;
DEBUG_BUFF_AX	db  '____ BX='  ; AX
DEBUG_BUFF_BX	db  '____ CX='  ; BX
DEBUG_BUFF_CX	db  '____ DX='  ; CX
DEBUG_BUFF_DX	db  '____ SI='  ; DX
DEBUG_BUFF_SI	db  '____ DI='  ; SI
DEBUG_BUFF_DI	db  '____ BP='  ; DI
DEBUG_BUFF_BP	db  '____'      ; BP
@DEBUG_BUFLEN2	equ $-DEBUG_BUFFER2

	 public  DEBUG_BUFFER3
DEBUG_BUFFER3	db  'CS='       ;
DEBUG_BUFF_CS	db  '____ DS='  ; CS
DEBUG_BUFF_DS	db  '____ ES='  ; DS
DEBUG_BUFF_ES	db  '____ SS='  ; ES
DEBUG_BUFF_SS	db  '____   ('  ; SS
DEBUG_BUFF_SEG	db  '____:'     ; CS
DEBUG_BUFF_OFF	db  '____)'     ; IP
@DEBUG_BUFLEN3	equ $-DEBUG_BUFFER3

	 public  DEBUG_ADVICE
ifdef LANG_GR
DEBUG_ADVICE	db  'ROMSRCH /i Åbergeht diesen Funktionsaufruf'
else
DEBUG_ADVICE	db  'To skip this function call, use ROMSRCH /i'
endif				; IFDEF LANG_GR
DEBUG_ADVICE1	db  '__'
DEBUG_ADVICE2	db  '__'
@DEBUG_ADVICE	equ $-DEBUG_ADVICE


	 public  STATUS_HEADER,STATUS_TEXT0
ifdef LANG_GR
STATUS_HEADER	db	'prÅfe:          '
STATUS_TEXT0	db	'Farb-Wahl       '
STATUS_TEXT1	db	'Write String (1)'
STATUS_TEXT2	db	'Write String (2)'
STATUS_TEXT3	db	'Diskette        '
STATUS_TEXT4	db	'Festplatte      '
STATUS_TEXT5	db	'SekundÑr-Video  '
STATUS_TEXT6	db	'Disk-Tabellen   '
STATUS_TEXT7	db	'Video-Tabellen  '
STATUS_TEXT8	db	'PrtScr          '
STATUS_TEXT9	db	'ABIOS           '
STATUS_TEXT10	db	'EISA            '
STATUS_TEXT11	db	'Fertig          '
STATUS_TEXT12	db	'Alt-keys        '
STATUS_TEXT13	db	'PCI local bus   '
else
STATUS_HEADER	db	'Testing: '
STATUS_TEXT0	db	'Color Select    '
STATUS_TEXT1	db	'Write string (1)'
STATUS_TEXT2	db	'Write string (2)'
STATUS_TEXT3	db	'Floppy          '
STATUS_TEXT4	db	'Hard Disk       '
STATUS_TEXT5	db	'Secondary video '
STATUS_TEXT6	db	'Disk tables     '
STATUS_TEXT7	db	'Video Tables    '
STATUS_TEXT8	db	'PrtScr          '
STATUS_TEXT9	db	'ABIOS           '
STATUS_TEXT10	db	'EISA            '
STATUS_TEXT11	db	'Completed       '
STATUS_TEXT12	db	'Alt-keys        '
STATUS_TEXT13	db	'PCI local bus   '
endif				; IFDEF LANG_GR
@STATUS_HEADER_LEN equ	STATUS_TEXT0-STATUS_HEADER	; Length of header
@STATUS_TEXT_LEN equ	STATUS_TEXT1-STATUS_TEXT0	; Length of each line

	 public  @STAT_COMPLETED
@STAT_COLORSLCT  equ	 0
@STAT_WRITE1	 equ	 1
@STAT_WRITE2	 equ	 2
@STAT_FLOPPY	 equ	 3
@STAT_HARD	 equ	 4
@STAT_INT42	 equ	 5
@STAT_INT46	 equ	 6
@STAT_INT1F	 equ	 7
@STAT_INT05	 equ	 8
@STAT_ABIOS	 equ	 9
@STAT_EISA	 equ	 10
@STAT_COMPLETED  equ	 11
@STAT_ALTKEYS	 equ	 12
@STAT_PCI	 equ	 13

;N.B. Each text field (above) has to be 16 bytes for
;     our indexing scheme to work in DEBUG_MISC.

;------------------ File I/O variables ---------------------

	 public  FILENAME_A1, FILENAME_A2
	 public  FILENAME_B1, FILENAME_B2
	 public  FILENAME_C1, FILENAME_C2
FILENAME_A1	db	'A:\',0         ; Path for floppy temp file
		db	8+1+3 DUP (0)	; Padding
FILENAME_A2	db	'A:\',0         ; Path for floppy temp file
		db	8+1+3 DUP (0)	; Padding
FILENAME_B1	db	'B:\',0         ; Path for floppy temp file
		db	8+1+3 DUP (0)	; Padding
FILENAME_B2	db	'B:\',0         ; Path for floppy temp file
		db	8+1+3 DUP (0)	; Padding
FILENAME_C1	db	'C:\',0         ; Path for hard disk temp file
		db	8+1+3 DUP (0)	; Padding
FILENAME_C2	db	'C:\',0         ; Path for hard disk temp file
		db	8+1+3 DUP (0)	; Padding

	 public  FIRST_FILE, SECOND_FILE
FIRST_FILE	dw	?	; Pointer to first ASCIIZ filename
SECOND_FILE	dw	?	; ...	     second ...

	 public  MSG_FILE_ERR,@MSG_FILE_ERR_LEN
ifdef LANG_GR
MSG_FILE_ERR	db	CR,LF,BEL,@PROGNAME,' Datei-I/O-Fehler ('
else
MSG_FILE_ERR	db	CR,LF,BEL,@PROGNAME,' File I/O Error ('
endif				; IFDEF LANG_GR
MSG_FILE_ERR1	db	'__).  '
@MSG_FILE_ERR_LEN	equ	$-MSG_FILE_ERR

	 public  MSG_NOFLOPPY
ifdef LANG_GR
MSG_NOFLOPPY	db	BEL,CR,LF,@PROGNAME,' benîtigt eine Diskette '
		db	'im Laufwerk A: oder B:', CR,LF
		db	'Legen Sie bitte eine Diskette in eines der beiden Laufwerke',CR,LF
		db	'fÅr einen ungefÑhrlichen Schreib-Lese-Test;',CR,LF
		db	'weiter mit beliebiger Taste, ESC bricht den Vorgang ab.'
		db	 CR,LF
else
MSG_NOFLOPPY	db	BEL,CR,LF,@PROGNAME,' needs a floppy disk '
		db	'in either A: or B:', CR,LF
		db	'Please place a disk in either drive for a '
		db	'non-destructive read/write test.',CR,LF
		db	'Press any key to continue or ESCAPE to abort.'
		db	 CR,LF
endif				; IFDEF LANG_GR
@MSG_NOFLOPPY_LEN equ	$-MSG_NOFLOPPY

;------------ String for video testing ---------------

	 public  MSG_SPACE1, MSG_SPACE2
MSG_SPACE1	db	' ',CR,LF
MSG_SPACE2	db	' ',07h, CR,LF
MSG_SPACELEN	equ	3	; 3 characters (not inlcuding attributes)

;------------- Search strings (machine specific) -------------

	 public  T2000SXE_ID
T2000SXE_ID	label	 byte
	db	0FAh		; CLI
	db	060h		; PUSHA
	db	066h,060h	; PUSHAD
	db	01Eh,006h	; PUSH DS, PUSH ES
	db	00Fh,0A0h	; PUSH FS
	db	00Fh,0A8h	; PUSH GS
	db	00Fh,020h,000h	; MOV [BX+SI],CR0
T2000SXE_IDLEN	 equ	 $-T2000SXE_ID ; Length of above search string

	 public  T4400SX_ID
T4400SX_ID	label	 byte
	db	0FAh		; CLI
	db	0FCh		; CLD
	db	060h		; PUSHA
	db	066h,060h	; PUSHAD
	db	01Eh,006h	; PUSH DS, PUSH ES
	db	00Fh,0A0h	; PUSH FS
	db	00Fh,0A8h	; PUSH GS
	db	00Fh,020h,0C0h	; MOV EAX,CR0
	db	08Bh,0C8h	; MOV CX,AX
	db	066h,08Bh,0C8h	; MOV ECX,EAX
T4400SX_IDLEN equ $-T4400SX_ID	; Length of above search string

	 public  ORCHIDVGA_ID
ORCHIDVGA_ID	 label	 byte
	 db	 0E8h,02Ch,000h 	; C000:0F00 CALL 0F2F
	 db	 059h			; C000:0F03 POP CX
	 db	 052h			; C000:0F04 PUSH DX
	 db	 08Bh,016h,063h,004h	; C000:0F05 MOV DX,[0463]
	 db	 083h,0C2h,006h 	; C000:0F09 ADD DX,6
ORCHIDVGA_IDLEN  equ	 $-ORCHIDVGA_ID ; Length of above search string

	 public  BATTERYWATCH_ID
BATTERYWATCH_ID db     'Battery Watch'
BATTERYWATCH_IDLEN equ $-BATTERYWATCH_ID ; Length of above search string

	 public  EVEREX_TEMPO_ID
EVEREX_TEMPO_ID  label	 byte
	 db	 01Fh, 05Bh, 058h, 05Dh ; POP DS,BX,AX,BP
	 db	 0E9h, -1,   -1 	; JMP xxxx
	 db	 055h, 08Bh, 0ECh	; PUSH BP, MOV BP,SP
	 db	 053h, 01Eh, 0FCh, 0FAh ; PUSH BX, PUSH DS, CLD, CLI
	 db	 08Bh, 05Eh, 004h	; MOV BX,[BP+04]
	 db	 08Eh, 0DBh		; MOV DS,BX
	 db	 08Bh, 05Eh, 002h	; MOV BX,[BP+02]
	 db	 08Bh, 01Fh		; MOV BX,[BX]
	 db	 080h, 0FBh, 0F0h	; CMP BL,F0h
	 db	 075h, 06h		; JNZ +6
	 db	 0FFh, 046h, 02h	; INC WPTR [BP+02]
	 db	 0E9h, -1,   -1 	; JMP xxxx
	 db	 081h, 0FBh, 00Fh, 005h ; CMP BX,050Fh
	 db	 074h, -1		; JZ xxxx
	 db	 01Fh, 05Bh, 05Dh		; POP DS,BX,BP
	 db	 0EBh, 0D2h		; JMP (to EVEREX_TEMPO_ID)
EVEREX_TEMPO_ID_LEN equ  $-EVEREX_TEMPO_ID ; Length of above search string


;-------------- ABIOS variables --------------------

	 public  INIT_ENTRY_CTR,LOGICAL_ID
INIT_ENTRY_CTR	 dw	     0
LOGICAL_ID	 dw	     0

	 public  SYSPARM,CDA_SEG,SYSINIT_SEG,NVRAM_LID,NVRAM_RB_LEN,POS_BLK
SYSPARM 	 SYSPARM_STR <>
CDA_SEG 	 dw	?
SYSINIT_SEG	 dw	?
NVRAM_LID	 dw	?	; NVRAM Logical ID
NVRAM_RB_LEN	 dw	?	; NVRAM Request Block Length
POS_BLK 	 RB_POS_STR <>	; Used for ABIOS POS requests


;-------------- EISA variables --------------------

EISA_BUFFER	 db	 320 dup (?) ; EISA slot buffer


;-------------- Alt-key variables -----------------

	 public  SCAN_PTR
SCAN_PTR dw	 PGROUP:SCAN_TABLE	; Pointer to next entry in scan table

	 public  SCAN_TABLE
SCAN_TABLE label byte
	 db	 @NORM, 001h		; ESC		(first normal key)
	 db	 @NORM, 002h		; '1'
	 db	 @NORM, 030h		; 'B'
	 db	 @NORM, 044h		; F10
	 db	 @NORM, 053h		; Del key	(highest normal key)
	 db	 @ALT,	002h		; Alt - 1	(first Alt key)
	 db	 @ALT,	030h		; Alt - B
	 db	 @ALT,	044h		; Alt - F10
	 db	 @ALT,	00Dh		; Alt - =/+	(highest Alt key)
	 db	 @NORM, @K2S_OVER1	; Key detection error/overrun
	 db	 @END			; End of List

@NORM	 equ	  0	; Signifies normal keystroke is following
@ALT	 equ	 -1	; Signifies the key combination includes Alt key
@END	 equ	 -2	; Signifies 'End of List'

; Note: The @K2S_OVER1 keystroke is simulated to cause the keyboard
; handler to beep.  Some machines (HP comes to mind) use a separate
; beep routine for keyboard buffer overflow and Ctrl-G.


;-------------- Externs to PROBE.ASM --------------------

extrn	LCL_FLAG:dword		; Local Flags
extrn	CMD_FLAG:word		; Command line Flags
extrn	OLDINT05_VEC:dword	; Original PrtScr vector
extrn	OLDINT10_VEC:dword	; Original video handler
extrn	OLDINT17_VEC:dword	; Original Printer vector
extrn	VIDEO_SEG:word		; Segment of video adapter
extrn	VIDEO_MODE:word 	; Initial Video mode
extrn	SYSROM_START:word	; Start of System BIOS
extrn	XBIOS_SEG:word		; XBDA segment
extrn	OLDIRQ_TBL:byte 	; Table of IRQ entry points
extrn	OLDIRQ_05:byte		; BIOS entry point for PrtScr routine
extrn	@OLDIRQ_NUM:abs 	; Number of IRQs

DATA	 ends			; End DATA segment


;***************************************************************************

; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	 segment use16 para public 'data' ; Start DTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:dword	; Last byte in our program

DTAIL	 ends			; End DTAIL segment


;***************************************************************************

CODE	 segment use16 word public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

;------- Variables that have to CS relative ---------------------

	 public SAVE_AX, SAVE_BX, SAVE_CX, SAVE_DX
	 public SAVE_SI, SAVE_DI, SAVE_DS, SAVE_ES
SAVE_AX dw	0	; Save area for result of interrupt or function
SAVE_BX dw	0	; ...
SAVE_CX dw	0	; ...
SAVE_DX dw	0	; ...
SAVE_SI dw	0	; ...
SAVE_DI dw	0	; ...
SAVE_DS dw	0	; ...
SAVE_ES dw	0	; ...

	 public  INT_COUNTER_UP,INT_COUNTER_DN
INT_COUNTER_UP	dw	0	   ; Counts processed interrupts
INT_COUNTER_DN	dw	FUNC_TOTAL ; Counts remaining interrupts


;------- Externs to PROBE.ASM ----------------------------

extrn	 BEEP_HIGH:proc 	; Beeps the speaker for debugging
extrn	 BEEP_LOW:proc		; ...
extrn	 FMT_BYTE:proc		; For debugging
extrn	 FMT_WORD:proc		; ...
extrn	 SRCHSTR:proc		; Search for particular string
extrn	 SRCHSTRI:proc		; ...		      (with don't care bytes)
extrn	 NEWINT17:proc		; To trap/restore printer servces
extrn	 NEWINT0A:proc		; Temporary interrupt handler
extrn	 LOCAL_INT10:proc	; Temporary interrupt handler

;***************************************************************************

COMMENT |

Video interrupt table.

|

	 public  FIRST_FUNC
FIRST_FUNC	 label INT_STR	; The first function

	public FUNC10_TBL		; PPROC - Video functions
FUNC10_TBL:
   INT_STR <00000h,,,,,010h>	; Set Video Mode to BW40
   INT_STR <00000h,,,,,010h>	; Set Video Mode to CO40
   INT_STR <00D00h,,,,,010h>	; Read Dot from mode 1
   INT_STR <00C00h,,,,,010h>	; Write Dot into mode  1
   INT_STR <00002h,,,,,010h>	; Set Video Mode to BW80
   INT_STR <00004h,,,,,010h>	; Set Video Mode to CGA 4
   INT_STR <00D00h,,,,,010h>	; Read Dot from mode 4
   INT_STR <00C00h,,,,,010h>	; Write Dot into mode 4
   INT_STR <00005h,,,,,010h>	; Set Video Mode to CGA 5
   INT_STR <00006h,,,,,010h>	; Set Video Mode to CGA 6
   INT_STR <00D00h,,,,,010h>	; Read Dot from mode 6
   INT_STR <00C00h,,,,,010h>	; Write Dot into mode 6
;  INT_STR <00007h,,,,,010h>	; Set Video Mode to Monochrome 7 [FIXME]
   INT_STR <00010h,,,,,010h>	; Set Video Mode to EGA 10h (640x350)
   INT_STR <00D00h,,,,,010h>	; Read Dot from mode 10
   INT_STR <00C00h,,,,,010h>	; Write Dot into mode 10
I10VGA1:
   INT_STR <00012h,,,,,010h>	; Set Video Mode to VGA 12h (640x480)
   INT_STR <00D00h,,,,@SKIP,010h>	; Read Dot from mode 12
   INT_STR <00C00h,,,,,010h>	; Write Dot into mode 12
   INT_STR <00013h,,,,,010h>	; Set Video Mode to VGA 13h (256 color)
   INT_STR <00D00h,,,,,010h>	; Read Dot from mode 13
   INT_STR <00C00h,,,,,010h>	; Write Dot into mode 13
I10VGA1_LEN equ ($-I10VGA1)/STRUCT_LEN
I10VESA:
   INT_STR <0006Ah,,,,,010h>	; Set Video Mode to VESA 6A (800x600)
;  INT_STR <000??h,,,,,010h>	; More video modes - [FIXME]
I10A:
   INT_STR <00003h,,,,,010h>	; Set Video Mode to CO80 (Do this mode last!)
   INT_STR <00500h,,,,,010h>	; Select page 0
   INT_STR <00300h,,,,,010h>	; Read cursor position & type
   INT_STR <00200h,,,,@DX,010h> 	; Set cursor position (page 0)
   INT_STR <00300h,,,,,010h>		; Read cursor position & type
   INT_STR <00100h,,,,@CX,010h> 	; Set cursor type
   INT_STR <00400h,,,,,010h>		; Read Light pen position
   INT_STR <00601h,0700h,,0184Fh,,010h> ; Scroll Up 1 row
   INT_STR <00701h,0700h,,0184Fh,,010h> ; Scroll Down 1 row
   INT_STR <00600h,0700h,,0184Fh,,010h> ; Scroll Up (Blank the screen)
   INT_STR <00700h,0700h,,0184Fh,,010h> ; Scroll Down (Blank the screen)
   INT_STR <00800h,,,,,010h>		; Read character at cursor (page 0)
   INT_STR <00920h,07h,5,,,010h>	; Write char/attr at cursor (page 0)
   INT_STR <00A20h,,5,,,010h>		; Write character at cursor (page 0)
   INT_STR <00B00h,00000h,,,,010h>	; Set border color palette in CGA
   INT_STR <00B00h,00101h,,,,010h>	; Set color palette in CGA
   ; C & D are done above for each graphics mode.
   INT_STR <00E07h,,,,,010h>	; Write TTY (BEL)
   INT_STR <00E08h,,,,,010h>	; Write TTY (BS)
   INT_STR <00E0Ah,,,,,010h>	; Write TTY (LF)
   INT_STR <00E0Dh,,,,,010h>	; Write TTY (CR)
   INT_STR <00E20h,,,,,010h>	; Write TTY (space)
   INT_STR <00F00h,,,,,010h>	; Get Current Video State

   ; Start of EGA/VGA functions

   INT_STR <01007h,0h,,,,010h>	; Read indiv palette register
   INT_STR <01000h,,,,@BX,010h> ; Set  ...
   INT_STR <01008h,0h,,,,010h>	; Read overscan register
   INT_STR <01001h,,,,@BX,010h> ; Set ...
   INT_STR <01009h,,,@ZTAIL,,010h>	; Read all paletter registers
   INT_STR <01002h,,,@ZTAIL,,010h>	; Set ...
   INT_STR <01003h,0000h,,,,010h>	; Enable intensify
   INT_STR <01003h,0100h,,,,010h>	; Enable blink
   INT_STR <01015h,0h,,,@CX or @DX,010h> ; Read indiv DAC register
   INT_STR <01010h,0h,,,@CX or @DX,010h> ; Set ...
   INT_STR <01017h,0h,64,@ZTAIL,,010h>	; Read block of DAC registers
   INT_STR <01012h,0h,64,@ZTAIL,,010h>	; Set ...      (makes screen flicker)
;;;INT_STR <0101Ah,0h,,,,010h>	; Read color page state registers
;;;INT_STR <01013h,1h,,,,010h>	; Set # of DAC subsets avail
;;;INT_STR <01013h,,,,,010h>	; Select active DAC subset
   INT_STR <0101Bh,128,10h,,,010h> ; Sum registers to grey shades
I10B:
   INT_STR <00003h,,,,,010h>	; Reset Mode to CO80 (Do this mode last!)

   INT_STR <01100h,0803h,10h,0,,010h>	; User alpha load
   INT_STR <01101h,03h,,,,010h> ; Load ROM monochrome font
   INT_STR <01102h,03h,,,,010h> ; Load ROM double dot font
   INT_STR <01103h,1,,,,010h>	; Enable 512 byte character set
   INT_STR <01104h,03h,,,,010h> ; Load ROM 16 row font
   INT_STR <01110h,0803h,10h,0,,010h>	; User alpha load
   INT_STR <01111h,03h,,,,010h> ; Load ROM monochrome font
   INT_STR <01112h,03h,,,,010h> ; Load ROM double dot font
   INT_STR <01114h,03h,,,,010h> ; Load ROM 16 row font
   INT_STR <01120h,,,,,010h>	; Load graphics 8x8 font into 1F
   INT_STR <01121h,02h,10h,,,010h>	; Load graphics 8x8 font into 43
   INT_STR <01122h,02h,,,,010h> ; Load ROM 8x14 font (43)
   INT_STR <01123h,02h,,,,010h> ; Load ROM 8x8 font (43)
   INT_STR <01124h,02h,,,,010h> ; Load ROM 8x16 font (43)
   INT_STR <01130h,0000h,,,,010h>	; Get font info (0)
   INT_STR <01130h,0200h,,,,010h>	; Get font info (2)
   INT_STR <01130h,0300h,,,,010h>	; Get font info (7)
I10C:
   INT_STR <00003h,,,,,010h>	; Reset Mode to CO80 (Do this mode last!)

   INT_STR <01200h,010h,,,,010h>	; Return Alternate Select info
   INT_STR <01200h,020h,,,,010h>	; Select Alt Print Screen
   INT_STR <01202h,030h,,,,010h>	; Select 400 scan lines for text mode
   INT_STR <01201h,031h,,,,010h>	; Select default palette loading
   INT_STR <01201h,032h,,,,010h>	; Disable display adapter
   INT_STR <01200h,032h,,,,010h>	; Enable ...
   INT_STR <01200h,033h,,,,010h>	; Enable  Summing to gray shades
   INT_STR <01201h,033h,,,,010h>	; Disable Summing to gray shades
   INT_STR <01201h,034h,,,,010h>	; Disable Cursor emulation
   INT_STR <01200h,034h,,,,010h>	; Enable ...
;  INT_STR <01200h,035h,,,,010h>	; Display switch
   INT_STR <01201h,036h,,,,010h>	; Blank screen
   INT_STR <01200h,036h,,,,010h>	; Restore ...
I10D:
   INT_STR <00003h,,,,,010h>	; Reset Mode to CO80 (Do this mode last!)

;;;INT_STR <01300h,0h,1h,0h,,010h>	; Write string (char)	  (done later)
;;;INT_STR <01302h,0h,1h,0h,,010h>	; Write string (char/attr)(...)

   INT_STR <01A00h,,,,,010h>	; Read DCC registers
   INT_STR <01A01h,,,,@BX,010h> ; Write DCC reisters

;;;INT_STR <01B00h,0h,,,,010h>	; Return functionality state info (done later)
I10VGA2:
I101C_A:
   INT_STR <01C00h,,07h,,,010h> ; Get buffer Size for video save/restore
I101C_B:
   INT_STR <01C01h,@ZTAIL,07h,,,010h>	 ; Save Video State
I101C_C:
   INT_STR <01C02h,@ZTAIL,07h,,@BX,010h> ; Restore Video State
I10VGA2_LEN equ ($-I10VGA2)/STRUCT_LEN

I10E:
   INT_STR <00003h,,,,,010h>	; Reset Mode to CO80 (Do this mode last!)

	public	FUNC10_TBL_LEN
FUNC10_TBL_LEN equ	 ($-FUNC10_TBL)/STRUCT_LEN

;***************************************************************************

COMMENT |

Diskette interrupt table.

|

	public FUNC13_TBL		; PPROC - Hard Disk services
FUNC13_TBL:
;;;INT_STR <00000h,,,080h,,013h>	; Reset disk (done after func 0A)
;;;INT_STR <00100h,,,,,013h>		; Get disk status (FD only)
   INT_STR <00201h,@ZTAIL,01h,80h,,013h> ; Read
;;;INT_STR <00301h,@ZTAIL,01h,80h,,013h> ; Write (done later)
   INT_STR <00401h,@ZTAIL,01h,80h,,013h> ; Verify
;  INT_STR <00500h,,,,,013h>		; Format [FXIME]
;  INT_STR <00600h,,,80h,,013h> 	; Format cylinder w bad sector
;  INT_STR <00700h,,,80h,,013h> 	; Format drive from certain cylinder
   INT_STR <00800h,,,80h,,013h> 	; Return parameters
   INT_STR <00900h,,,80h,,013h> 	; Init Fixed disk
;--INT_STR <00A01h,@ZTAIL,0001h,80h,,013h> ; Read Long Sector (Diagnostics)
;--INT_STR <00800h,,,80h,,013h> 	; Return parms (required before func 00)
;--INT_STR <00000h,,,80h,,013h> 	; Reset disk   (required after func 0A)
;--INT_STR <00900h,,,80h,,013h> 	; Init disk    (required after func 00)
;  INT_STR <00B00h,,,80h,,013h> 	; Write Long Sector (Diagnostics)
   INT_STR <00C00h,,,80h,,013h> 	; Seek Cylinder
;  INT_STR <00D00h,,,80h,,013h> 	; Alternate disk reset
   ; Reserved for Diagnostics (0E => 0Fh)
;;;INT_STR <01000h,,,80h,,013h> ; Test Drive Ready (floppy only)
;;;INT_STR <01100h,,,80h,,013h> ; Recalibrate	   (floppy only)
   ; Reserved for Diagnostics (12h => 14h)
   INT_STR <01500h,,,80h,,013h> ; Retrun DASD type
;;;INT_STR <01600h,,,80h,,013h> ; Read Disk Change Line (diskette only)
;;;INT_STR <01700h,,,,,013h>	; Set DASD type for format (diskette only)
;;;INT_STR <01800h,,,,,013h>	; Set Media Type for format (diskette only)
;;;INT_STR <01900h,,,80h,,013h> ; Park heads (locks on Henry's PS/2 80)
;;;INT_STR <01A00h,,,80h,,013h> ; Format Entire ESDI disk (UGHH!)
   ; Reserved (1Bh -> 20h)
;  INT_STR <02100h,,,80h,,013h> ; Read multiple sectors
;  INT_STR <02200h,,,80h,,013h> ; Write multiple sectors
;  INT_STR <02300h,,,80h,,013h> ; Reserved
;  INT_STR <02400h,,,80h,,013h> ; Set multiple mode
;  INT_STR <02500h,,,80h,,013h> ; Identify Drive command
   ; Reserved (26h => FFh)


	public	FUNC13_TBL_LEN
FUNC13_TBL_LEN equ	 ($-FUNC13_TBL)/STRUCT_LEN

;***************************************************************************

COMMENT |

Serial Port interrupt table.

|

	public FUNC14_TBL		; PPROC - Serial Port functions
FUNC14_TBL:
   INT_STR <000E2h,,,,,014h>		; Reset Comm Port (9600,N81)
   INT_STR <00151h,,,,,014h>		; Trasmit a 'Q'
   INT_STR <00200h,,,,,014h>		; Receive a character
   INT_STR <00300h,,,,,014h>		; Get current COM status (dx=0=com1)
   INT_STR <00400h,,00307h,,,014h>	; Extended Initialize (9600,?81)
   INT_STR <00500h,,,,,014h>		; Read Modem Control Register (com1)
   INT_STR <00501h,,,,,014h>		; Write Modem Control Register (com1)

	public	FUNC14_TBL_LEN
FUNC14_TBL_LEN equ	 ($-FUNC14_TBL)/STRUCT_LEN


;***************************************************************************

COMMENT |

System Services interrupt table.

|

	public FUNC15_TBL		; PPROC - System Misc functions
FUNC15_TBL:
   INT_STR <00000h,,,,,015h>	; Turn cassette motor on
   INT_STR <00100h,,,,,015h>	; Turn cassette motor off
   INT_STR <00200h,,,,,015h>	; Read from cassette
   INT_STR <00300h,,,,,015h>	; Write to cassette
   ; 04h -> 0Eh (reserved)
   INT_STR <00F00h,,,,,015h>	; Formatter (periodic interrupt)
   ; 10h -> 20h (reserved)
   INT_STR <02100h,,,,,015h>	; POST Error log (Read)
   INT_STR <02101h,,,,,015h>	; POST Error log (Write) [FIXME]
   INT_STR <02200h,,,,,015h>	; Get segment of BASIC into ES
;  INT_STR <02400h,,,,,015h>	;
;  INT_STR <02402h,,,,,015h>	; A20 Support(query)
   ; 25h -> 3Fh (reserved)
   INT_STR <04000h,,,,,015h>		; Read System Profiles
   INT_STR <04001h,,,,@CX or @BX,015h>	; Modify System Profiles
   INT_STR <04002h,,,,,015h>		; Read Internal Modem Profiles
   INT_STR <04003h,,,,@BX,015h> 	; Modify Internal Modem Profiles
   INT_STR <04100h,,,,,015h>		; Wait for external event (L40)
   INT_STR <04200h,,,,,015h>		; Request System Power Off [FIXME]
   INT_STR <04300h,,,,,015h>		; Read system status [FIXME]
   INT_STR <04400h,,,,,015h>		; Internal Modem Power On [FIXME]
   INT_STR <04401h,,,,,015h>		; Internal Modem Power Off [FIXME]
   ; 45h -> 4Eh (reserved)
   ; INT_STR <04500h,,,,,015h>	[FIXME]
   ; 50h -> 52h (reserved)
   INT_STR <05300h,0,,,,015h>		; APM Installation Check

   INT_STR <05301h,0,,,,015h>		; APM RM/VM Connect
   INT_STR <0530Eh,0,0100h,,,015h>	; APM Driver Version # 1.0
   INT_STR <0530Eh,0,0101h,,,015h>	; APM Driver Version # 1.1
   INT_STR <05305h,0,,,,015h>		; APM CPU Idle
   INT_STR <05306h,0,,,,015h>		; APM CPU Busy
   INT_STR <0530Bh,0,,,,015h>		; APM Get PM Event
   INT_STR <05304h,0,,,,015h>		; APM Disconnect

   INT_STR <05302h,0,,,,015h>		; APM PM 16-bit Connect
   INT_STR <0530Eh,0,0100h,,,015h>	; APM Driver Version # 1.0
   INT_STR <0530Eh,0,0101h,,,015h>	; APM Driver Version # 1.1
   INT_STR <05305h,0,,,,015h>		; APM CPU Idle
   INT_STR <05306h,0,,,,015h>		; APM CPU Busy
   INT_STR <0530Bh,0,,,,015h>		; APM Get PM Event
   INT_STR <05304h,0,,,,015h>		; APM Disconnect

   INT_STR <05303h,0,,,,015h>		; APM PM 32-bit Connect
   INT_STR <0530Eh,0,0100h,,,015h>	; APM Driver Version # 1.0
   INT_STR <0530Eh,0,0101h,,,015h>	; APM Driver Version # 1.1
   INT_STR <05305h,0,,,,015h>		; APM CPU Idle
   INT_STR <05306h,0,,,,015h>		; APM CPU Busy
   INT_STR <0530Bh,0,,,,015h>		; APM Get PM Event
   INT_STR <05304h,0,,,,015h>		; APM Disconnect

   INT_STR <0530Ah,1,,,,015h>		; APM Get Power Status
; Phoenix BIOS 4.03 (Copyright 1987-1994) crashes on the following function
;;;INT_STR <0530Ch,1,,,,015h>		; APM Get Power State
   INT_STR <05380h,7F00h,,,,015h>	; APM OEM-defined APM Functions
   ; 54h -> 7Fh (reserved)
   INT_STR <08000h,,,,,015h>		; Device Open [QUES]
   INT_STR <08100h,,,,,015h>		; Device close [QUES]
   INT_STR <08200h,,,,,015h>		; Program Termination [QUES]
   INT_STR <08300h,,,,,015h>		; Event wait - Set interval [FIXME]
   INT_STR <08301h,,,,,015h>		; Event wait - Cancel interval [FIXME]
   INT_STR <08400h,,,,,015h>		; Joystick support (Read swithces)
   INT_STR <08401h,,,,,015h>		; Joystick support (Read resistors)
   INT_STR <08500h,,,,,015h>		; SysReq Key pressed
   INT_STR <08501h,,,,,015h>		; SysReq Key released
   INT_STR <08600h,,0,2,,015h>		; Wait (CX,DX * 976ms)
   ; MAX intercepts 087h
   ; MAX intercepts 088h
   ; MAX intercepts 089h
   ; 8Ah -> 8Fh (reserved)
   INT_STR <09000h,,,,,015h>		; Device Busy [QUES]
   INT_STR <09100h,,,,,015h>		; Interrupt complete [QUES]
   ; 92h -> BFh (reserved)
   INT_STR <0C000h,,,,,015h>		; Retrun system configuration
   INT_STR <0C100h,,,,,015h>		; Get XBDA address
I15M:
   INT_STR <0C200h,01h,,,,015h> 	; Mouse - Disable [FIXME]
   INT_STR <0C200h,00h,,,,015h> 	; Mouse - Enable
   INT_STR <0C202h,0500h,,,,015h>	; Mouse - Set sample rate (100ps)
   INT_STR <0C203h,0200h,,,,015h>	; Mouse - Set resolution (4cnt)
   INT_STR <0C204h,,,,,015h>		; Mouse - Read device type
;  INT_STR <0C205h,0500h,,,,015h>	; Mouse - Interface initialization
   INT_STR <0C206h,0h,,,,015h>		; Mouse - Extended commands
;  INT_STR <0C207h,,,,,015h>		; Mouse - Far call initialization
   INT_STR <0C201h,,,,,015h>		; Mouse - Reset
I15M_LEN equ ($-I15M)/STRUCT_LEN
   INT_STR <0C301h,200h,,,,015h>	; Watch Dog Timer (Enable w/count)
   INT_STR <0C300h,,,,,015h>		; Watch Dog Timer (Disable)
   INT_STR <0C402h,00h,,,,015h> 	; POS (Adapter enable)
   INT_STR <0C400h,00h,,,,015h> 	; POS (Get Base Register Address)
   INT_STR <0C401h,00h,,,,015h> 	; POS (Enable Slot for setup)
   INT_STR <0C402h,00h,,,,015h> 	; POS (Adapter enable)
;  INT_STR <0C500h,,,,,015h>		; Protected BIOS entry point intercept
;  INT_STR <0C600h,,,,,015h>		; POS (Return data)
;  INT_STR <0C700h,,,,,015h>		; POS (Reutrn memory ddata)
;  INT_STR <0C800h,,,,,015h>		; Disable cache
;  INT_STR <0C801h,,,,,015h>		; Enable cache
;  INT_STR <0C900h,,,,,015h>		; Return stepping level
;  INT_STR <0CA00h,,,,,015h>		;
;  INT_STR <0CB00h,,,,,015h>		;
;  INT_STR <0CC00h,,,,,015h>		;
;  INT_STR <0CD00h,,,,,015h>		;
;  INT_STR <0CE00h,,,,,015h>		; Allocate arbitration levels
;  INT_STR <0CF00h,,,,,015h>		; Deallocate Arbitration level BL
   ; D0h -> FFh (reserved) [FIXME]
;  INT_STR <,,,,,015h>

	public	FUNC15_TBL_LEN
FUNC15_TBL_LEN equ	 ($-FUNC15_TBL)/STRUCT_LEN

;***************************************************************************

COMMENT |

Keyboard interrupt table.

|

	public FUNC16_TBL		; PPROC - Keyboard services
FUNC16_TBL:
I1605A:
   INT_STR <00500h,,1051h,,,016h> ; Keyboard write 'Q' (do before fnc00)
I1600:
   INT_STR <00000h,,,,,016h>	; Read keyboard (destr w/wait)
   INT_STR <00100h,,,,,016h>	; Scan (nondestr w/o wait)
   INT_STR <00200h,,,,,016h>	; Get shift status
   INT_STR <00305h,,,,,016h>	; Set typematic rate
   INT_STR <00400h,,,,,016h>	; Set Keyboard click (PCJr only)
   ; 05h (done above)
   ; 06h -> 0Fh (reserved)
I1605B:
   INT_STR <00500h,,1051h,,,016h> ; Keyboard write 'Q' (do before fnc10)
;  INT_STR <00900h,,,,,016h>	; Keyboard Functionality Determination in AL
;  INT_STR <00A00h,,,,,016h>	; Retrun Keyboard ID in BX
   INT_STR <01000h,,,,,016h>	; Keyboard Read
   INT_STR <01100h,,,,,016h>	; Extended keyboard Status
   INT_STR <01200h,,,,,016h>	; Extended Shift Status

	public	FUNC16_TBL_LEN
FUNC16_TBL_LEN equ	 ($-FUNC16_TBL)/STRUCT_LEN

;***************************************************************************

COMMENT |

Printer interrupt table.

|

	public FUNC17_TBL		; PPROC - Printer services
FUNC17_TBL:
   INT_STR <00020h,,,,,017h>	; Print a ' ' to LPT1
   INT_STR <00008h,,,,,017h>	; Print a backspace to LPT1
   INT_STR <00100h,,,,,017h>	; Initialize (Reset) LPT1
   INT_STR <00200h,,,,,017h>	; Get printer status

	public	FUNC17_TBL_LEN
FUNC17_TBL_LEN equ	 ($-FUNC17_TBL)/STRUCT_LEN

;***************************************************************************

COMMENT |

Time of Day interrupt table.

|

	public FUNC1A_TBL		; PPROC - Time of Day functions
FUNC1A_TBL:
   INT_STR <00000h,,,,,01Ah>		; Read system timer
   INT_STR <00100h,,,,@CX or @DX,01Ah>	; Set system timer
   INT_STR <00200h,,,,,01Ah>		; Read RTC time
   INT_STR <00300h,,,,@CX or @DX,01Ah>	; Set RTC time
   INT_STR <00400h,,,,,01Ah>		; Read RTC date
   INT_STR <00500h,,,,@CX or @DX,01Ah>	; Set RTC date
   INT_STR <00600h,,01h,,,01Ah> 	; Set System Alarm (for 1 hour)
   INT_STR <00700h,,,,,01Ah>		; Disable System Alarm
;  INT_STR <00800h,,,,,01Ah>	; Set RTC Power on mode  [FIXME] (Convr. only?)
;  INT_STR <00900h,,,,,01Ah>	; Read RTC Alarm Time [FIXME] (Convrt. only)
   INT_STR <00A00h,,,,,01Ah>		; Read system timer Day counter
   INT_STR <00B00h,,,,@CX,01Ah> 	; Set system timer Day counter
   ; Reserved (0C -> 7Fh)
   INT_STR <08001h,,,,,01Ah>		; Sound Multiplexer (cassette)
   INT_STR <08002h,,,,,01Ah>		; Sound Multiplexer (audio in)
   INT_STR <08003h,,,,,01Ah>		; Sound Multiplexer (TI sound chip)
   INT_STR <08000h,,,,,01Ah>		; Sound Multiplexer (8253 channel 2)

	public	FUNC1A_TBL_LEN
FUNC1A_TBL_LEN equ	 ($-FUNC1A_TBL)/STRUCT_LEN

;***************************************************************************

COMMENT |

PCI local bus BIOS support function tables

|

	 public  PCIDFB,PCIDEVCLASS,PCIDEVIND,PCICFGREG
PCIDFB	 dw	 0			; Device (15-11), fn # (10-8), bus (7-0)
PCIDEVCLASS dd	 0			; Device ID or class code
PCIDEVIND dw	 0			; Device index if multiple devices
PCICFGREG dw	 0			; Config register index

	 public  PCIFN_TAB
PCIFN_TAB label word
	 dw	 @PCI_INST		; Installation check
	 dw	 @PCI_FINDDEV		; Find device
	 dw	 @PCI_FINDCLASS 	; Find class
	 dw	 @PCI_RDBYTE		; Read config byte
	 dw	 @PCI_RDWORD		; Read config word
	 dw	 @PCI_RDDWORD		; Read config dword
@PCIFN_CNT equ (($-PCIFN_TAB)/(type PCIFN_TAB))

;***************************************************************************

COMMENT |

Diskette interrupt table.

|

	public FUNC40_TBL		; PPROC - Diskette services
FUNC40_TBL:
   INT_STR <00000h,,,0h,,040h>	; Reset diskette
   INT_STR <00100h,,,,,040h>	; Get diskette status
   INT_STR <00201h,@ZTAIL,01h,0h,,040h> ; Read	(done later also)
;;;INT_STR <00301h,@ZTAIL,01h,0h,,040h> ; Write (done later)
   INT_STR <00401h,@ZTAIL,01h,0h,,040h> ; Verify
;  INT_STR <00500h,,,,,040h>			; Format [FIXME]
   ; Reserved for HD (6h & 7h)
   INT_STR <00800h,,,0h,,040h>			; Return parameters
   ; 09 - Init Fixed disk	(HD only)
   ; 0A - Read Long Sector	(HD Diagnostics only)
   ; 0B - Write Long Sector	(HD Diagnostics only)
   ; 0C - Seek Cylinder 	(HD only)
   ; 0D - Alternate Disk Reaet	(HD only)
   ; Reserved for Diagnostics (0E => 0Fh)
   ; Reserved for HD (10h => 11h)
   ; Reserved for Diagnostics (12h => 14h)
   INT_STR <01500h,,,0h,,040h>	; Retrun DASD type
   INT_STR <01600h,,,0h,,040h>	; Read Disk Change Line Status
;  INT_STR <01700h,,,0h,@AX,040h> ; Set DASD type for disk format [FIXME]
;  INT_STR <01800h,,,,,040h>	; Set Media Type for format [FIXME]

	public	FUNC40_TBL_LEN
FUNC40_TBL_LEN equ	 ($-FUNC40_TBL)/STRUCT_LEN

;***************************************************************************

COMMENT |

Misc. interrupt table.

|

	public FUNC_MISC_TBL		; PPROC - Miscellaneous Routines
	public I02,I06,I75
FUNC_MISC_TBL:
;;;INT_STR <,,,,@MISC,000h>		; 00h Divide Overflow
;;;INT_STR <,,,,@MISC or @IRQ,001h>	; 01h Single Step
I1605C:
   INT_STR <00500h,,1051h,,,016h>	; Stuff keyboard (to skip NMI text)
I02:
   INT_STR <,,,,@MISC,002h>		; 02h NMI
I10F:
   INT_STR <00003h,,,,,010h>		; Clear screen (to avoid NMI message)
;;;INT_STR <,,,,@MISC,003h>		; 03h Breakpoint
   INT_STR <,,,,@MISC,004h>		; 04h Overflow
;;;INT_STR <,,,,@MISC,005h>		; 05h BOUND/PRTSCR
I06:
   INT_STR <,,,,@MISC or @IRQ,006h>	; 06h Invalid Opcode
I10G:
   INT_STR <00003h,,,,,010h>		; Clear screen (to avoid any message)
   INT_STR <,,,,@MISC,007h>		; 07h Reserved
;;;INT_STR <,,,,@MISC or @IRQ,008h>	; IRQ 0 : Timer tick
;;;INT_STR <,,,,@MISC or @IRQ,009h>	; IRQ 1 : Keyboard
   INT_STR <,,,,@MISC or @IRQ,00Ah>	; IRQ 2 : Miscellaneous
   INT_STR <,,,,@MISC or @IRQ,00Bh>	; IRQ 3 : COM2
   INT_STR <,,,,@MISC or @IRQ,00Ch>	; IRQ 4 : COM1
   INT_STR <,,,,@MISC or @IRQ,00Dh>	; IRQ 5 : LPT2
   INT_STR <,,,,@MISC or @IRQ,00Eh>	; IRQ 6 : Diskette
   INT_STR <,,,,@MISC or @IRQ,00Fh>	; IRQ 7 : Printer
;;;INT_STR <,,,,@MISC,010h>	; 10h  Video Services
   INT_STR <,,,,@MISC,011h>	; 11h  Get Equipment status
   INT_STR <,,,,@MISC,012h>	; 12h  Get memory Size
;;;INT_STR <,,,,@MISC,013h>	; 13h  Disk/Diskette services
;;;INT_STR <,,,,@MISC,014h>	; 14h  COM services
;;;INT_STR <,,,,@MISC,015h>	; 15h  BIOS services
;;;INT_STR <,,,,@MISC,016h>	; 16h  Keyboard services
;;;INT_STR <,,,,@MISC,017h>	; 17h  Printer services
;;;INT_STR <,,,,@MISC,018h>	; 18h  BASIC services
;  INT_STR <,,,,@MISC,019h>	; 19h  Warm boot [FIXME]
;;;INT_STR <,,,,@MISC,01Ah>	; 1Ah  Timer services
;;;INT_STR <,,,,@MISC,01Bh>	; 1Bh  Control-break
   INT_STR <,,,,@MISC,01Ch>	; 1Ch  Timer tick
;  INT_STR <,,,,@MISC,01Dh>		; 1Dh  Video parameter table [FIXME]
;;;INT_STR <,,,,@MISC,01Eh>		; 1Eh  Diskette parameter table
;;;INT_STR <,,,,@MISC,01Fh>		; 1Fh  Graphic characters table
;;;INT_STR <,,,,@MISC,0??h>		;      DOS services (20h - 3Fh)
;;;INT_STR <,,,,@MISC,030h>		; 40h  Diskette services
;;;INT_STR <,,,,@MISC,041h>		; 41h  HD #0 parameter table
;;;INT_STR <,,,,@MISC,042h>		; 42h  EGA revectored INT 10h
;;;INT_STR <,,,,@MISC,043h>		; 43h  EGA first 128 characters
   INT_STR <,,,,@MISC or @RES,044h>	; 44h  Reserved
   INT_STR <,,,,@MISC or @RES,045h>	; 45h  Reserved
;;;INT_STR <,,,,@MISC,046h>		; 46h  HD #1 parameter table
   INT_STR <,,,,@MISC or @RES,047h>	; 47h  Reserved
   INT_STR <,,,,@MISC or @RES,048h>	; 48h  Reserved
   INT_STR <,,,,@MISC or @RES,049h>	; 49h  Reserved
   INT_STR <,,,,@MISC or @RES,04Ah>	; 4Ah  Reserved
   INT_STR <06900h,,,,@MISC,04Bh>	; 4Bh  VDS services (ah != VDS_MAJOR(81h))
   INT_STR <,,,,@MISC or @RES,04Ch>	; 4Ch  Reserved
   INT_STR <,,,,@MISC or @RES,04Dh>	; 4Dh  Reserved
   INT_STR <,,,,@MISC or @RES,04Eh>	; 4Eh  Reserved
   INT_STR <,,,,@MISC or @RES,04Fh>	; 4Fh  Reserved
   INT_STR <,,,,@MISC or @RES,050h>	; 50h  Reserved
   INT_STR <,,,,@MISC or @RES,051h>	; 51h  Reserved
   INT_STR <,,,,@MISC or @RES,052h>	; 52h  Reserved
   INT_STR <,,,,@MISC or @RES,053h>	; 53h  Reserved
   INT_STR <,,,,@MISC or @RES,054h>	; 54h  Reserved
   INT_STR <,,,,@MISC or @RES,055h>	; 55h  Reserved
   INT_STR <,,,,@MISC or @RES,056h>	; 56h  Reserved
   INT_STR <,,,,@MISC or @RES,057h>	; 57h  Reserved
   INT_STR <,,,,@MISC or @RES,058h>	; 58h  Reserved
   INT_STR <,,,,@MISC or @RES,059h>	; 59h  Reserved
   INT_STR <,,,,@MISC or @RES,05Ah>	; 5Ah  Reserved
   INT_STR <,,,,@MISC or @RES,05Bh>	; 5Bh  Reserved
   INT_STR <,@PNETB,,,@MISC or @RES,05Ch> ; 5Ch  NETBIOS
;  INT_STR <,,,,@MISC or @RES,05Dh>	; 5Dh  Reserved (used by Core controller)
   INT_STR <,,,,@MISC or @RES,05Eh>	; 5Eh  Reserved
   INT_STR <,,,,@MISC or @RES,05Fh>	; 5Fh  Reserved
;;;INT_STR <,,,,@MISC,0??h>		;      User-available interrupts (60h - 67h)
   INT_STR <,,,,@MISC or @RES,068h>	; 68h  Reserved
   INT_STR <,,,,@MISC or @RES,069h>	; 69h  Reserved
   INT_STR <,,,,@MISC or @RES,06Ah>	; 6Ah  Reserved
   INT_STR <,,,,@MISC or @RES,06Bh>	; 6Bh  Reserved
   INT_STR <,,,,@MISC or @RES,06Ch>	; 6Ch  Reserved
;;;INT_STR <,,,,@MISC,06Dh>		; 6Dh  Secondary VGA interrupt
   INT_STR <,,,,@MISC or @RES,06Eh>	; 6Eh  Reserved
   INT_STR <,,,,@MISC or @RES,06Fh>	; 6Fh  Reserved
I70:
   INT_STR <,,,,@MISC or @IRQ,070h>	; 70h  IRQ08:  Real-time clock
I71:
   INT_STR <,,,,@MISC or @IRQ,071h>	; 71h  IRQ09:  redirect to IRQ2
I72:
   INT_STR <,,,,@MISC or @IRQ,072h>	; 72h  IRQ10:  Reserved
I73:
   INT_STR <,,,,@MISC or @IRQ,073h>	; 73h  IRQ11:  Reserved
I74:
;;;INT_STR <,,,,@MISC or @IRQ,074h>	; 74h  IRQ12:  Pointing device
I1605D:
   INT_STR <00500h,,1051h,,,016h>	; Stuff keyboard (to skip NMI text)
I75:
   INT_STR <,,,,@MISC or @IRQ,075h>	; 75h  IRQ13:  80287 (calls Int02)
I76:
   INT_STR <,,,,@MISC or @IRQ,076h>	; 76h  IRQ14:  HD controller
I77:
   INT_STR <,,,,@MISC or @IRQ,077h>	; 77h  IRQ15:  Reserved
I10H:
   INT_STR <00003h,,,,,010h>		; Clear screen
;  No vectors above INT 77h are initialized.
;  Vectors 60-67 are also un-initialized.

	public	FUNC_MISC_TBL_LEN
FUNC_MISC_TBL_LEN equ	 ($-FUNC_MISC_TBL)/STRUCT_LEN

	 public  FUNC_TOTAL
FUNC_TOTAL	equ	FUNC10_TBL_LEN + FUNC13_TBL_LEN + \
			FUNC14_TBL_LEN + FUNC15_TBL_LEN + \
			FUNC16_TBL_LEN + FUNC17_TBL_LEN + \
			FUNC1A_TBL_LEN + FUNC40_TBL_LEN + \
			FUNC_MISC_TBL_LEN


;***************************************************************************

	 NPPROC  INT_XX -- Process all functions for a given interrupt
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT|

On entry:	SI = Address of function table
		CX = Number of entries in above table
		AL = Interrupt # to process

On exit:	CF is set is user has requested to ABORT.

|
	 REGSAVE <ds,es>	; Save registers
	 pushad 		; Save everything

	 cmp	 cx,0		; Anything to process?
	 je	 near ptr INT_XX_EXIT ; Exit if not

INTXX_LOOP:

	 push	 cx		; Save interrupt counter

	 mov	 ax,[si].P_INTNO ; Get Interrupt number
	 mov	 INTXX,al	; Set interrupt number

; Should we skip this one?

	 test	 [si].P_FLAG,@SKIP ; Skip this interrupt?
	 jnz	 near ptr INT_XX_CLEANUP ; Jump if so

; Check to verify that the interrupt vecor is valid
; If it is one of the reserved interrups, do additional special check
; Also set up address for PUSHF/CALL

	 call	 CHECK_BOGUS_INT ; Check for bogus interrupt vector (in AX)
	 jc	 near ptr INT_XX_CLEANUP ; Jump if we shouldn't process it

	 call	 SETUP_IRQ	; Set up PUSHF/CALL if IRQ

; If this is interrupt 71h, then we have to setup special INT 0A handler

	 cmp	 INTXX,71h	; Izit interrupt 71h?
	 jne	 short NOT_INT71_A ; Jump if not

	 REGSAVE <es>		; Save register

	 mov	 al,0Ah 	; We want to store this interrupt
	 DOSCALL @GETINT	; Get interrupt vector in AL to ES:BX
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT0A_VEC.VSEG,es ; Save INT 0A segment
	 mov	 OLDINT0A_VEC.VOFF,bx ; ...	    offset

	 mov	 al,0Ah 	; We want to set this interrupt
	 DOSCALL @SETINT,NEWINT0A ; Set interrupt vector in AL to DS:DX

	 REGREST <es>		; Restore register
	 assume  es:PGROUP	; Tell the assembler about it

NOT_INT71_A:

; If this is interrupt 06 or 0D, we have to set up a special
; INT 10 handler to intercept any 'fatal' messages

	 cmp	 INTXX,06h	; Izit interrupt 06h?
	 je	 short @F	; Jump if so

	 cmp	 INTXX,0Dh	; Izit interrupt 0Dh?
	 jne	 short NOT_INT0D_A ; Jump if not
@@:

	 mov	 al,10h 	; We want to set this interrupt
	 DOSCALL @SETINT,LOCAL_INT10 ; Set interrupt vector in AL to DS:DX

NOT_INT0D_A:

; If this is INT 02h, some IBM Value Point BIOSes when they receive
; a software INT 02h display a message and then CLI/HLT (thanks).
; To counter this, we tell 386MAX to treat CLI/HLT as an NMI.

	cmp	INTXX,02h	; Izit interrupt 02h?
	jne	short NOT_INT02_A ; Jump if not

; Save current state of DBG_FLAG in 386MAX

	test	DBG_FLAG,@DBG_HLT ; Izit already set?
	jnz	short NOT_INT02_A ; Jump if so

	mov	bx,@DBG_HLT	; Flip the CLI/HLT flag
	EMMOUT	@EMM2_DBGFLAG	; Flip bits in DBG_FLAG

; Now put a temporary NMI handler into place so when the CLI/HLT
; occurs we gain control

	push	es		; Save for a moment

	xor	ax,ax		; A convenient zero
	mov	es,ax		; Address the interrupt table
	assume	es:nothing	; Tell the assembler about it

	mov	es:[02h*(type INT00_VEC)].VSEG,cs
	mov	es:[02h*(type INT00_VEC)].VOFF,offset cs:LOCAL_INT02

	or	LCL_FLAG,@LCL_INT02 ; Mark as installed

	pop	es		; Restore
	assume	es:PGROUP	; Tell the assembler about it
NOT_INT02_A:

; Save the IMR values (some XT class machines may alter it)
; IMR value will also need to be restored during our 'fatal' error handler

	 in	 al,21h 	; Get the current IMR value
	 mov	 PORT21_TEMP,al ; Save for later restoration

	 test	 LCL_FLAG,@LCL_XTCLASS ; Izit an XT class machine?
	 jnz	 short @F	; Jump if so (no secondary PIC)

	 in	 al,0A1h	; Get the current slave IMR value
	 mov	 PORTA1_TEMP,al ; Save for later restoration
@@:

; Load all general registers from strucutre

	 mov	 ax,[si].P_AX	; Load all input registers
	 mov	 bx,[si].P_BX	; ...
	 mov	 cx,[si].P_CX	; ...
	 mov	 dx,[si].P_DX	; ...

; Load some registers with output from previous interrupt (if appropriate)

	 test	 [si].P_FLAG,@AX ; Use same AX as last output?
	 jz	 short @F	; Nope

	 mov	 ax,SAVE_AX	; Get last AX
@@:
	 test	 [si].P_FLAG,@BX ; Use same BX as last output?
	 jz	 short @F	; Nope

	 mov	 bx,SAVE_BX	; Get last BX
@@:
	 test	 [si].P_FLAG,@CX ; Use same CX as last output?
	 jz	 short @F	; Nope

	 mov	 cx,SAVE_CX	; Get last CX
@@:
	 test	 [si].P_FLAG,@DX ; Use same DX as last output?
	 jz	 short @F	; Nope

	 mov	 dx,SAVE_DX	; Get last DX
@@:

; Test for call to debugger for current interrupt

	 call	 DEBUG_INTXX	; Call debugger? (SI is used in here)
	 jnc	 short @F	; Jump if no need to call debugger

	 int	 01h		; Signal debugger
@@:

; Save the world

	 REGSAVE <ds,es,fs,gs>	; Save all segment registers
	 pushad 		; Save the world
	 pushf			; Save the flags

; Save the stack in case we have to abort the interrupt.
; This might happen if the handler attempts to display a 'fatal'
; error message.

	 mov	 SAVED_STACK.VSEG,ss ; Save the stack
	 mov	 SAVED_STACK.VOFF,sp ; ...

; Do the interrupt !!!

	 pushf			; Simulate interrupt
	 cli			; ...
	 call	 INT_VECTOR	; ...

	 public FATAL_ERR_RETURN
FATAL_ERR_RETURN:
	 assume ds:nothing, es:nothing ; Tell the assembler

; Save return values (in case they are needed)

	 assume ds:PGROUP	; Tell a white lie
CSOVR	 mov	 <SAVE_AX,ax>	; Hold onto return values
CSOVR	 mov	 <SAVE_BX,bx>	; ...
CSOVR	 mov	 <SAVE_CX,cx>	; ...
CSOVR	 mov	 <SAVE_DX,dx>	; ...

CSOVR	 mov	 <SAVE_ES,es>	; ...
CSOVR	 mov	 <SAVE_DS,ds>	; ...
	 assume ds:nothing	; Retract nose

	 popf			; Restore flags
	 popad			; Restore the world
	 REGREST <gs,fs,es,ds>	; Restore all segment registers
	 assume  ds:PGROUP,es:PGROUP,ss:nothing,fs:nothing,gs:nothing

; Restore the IMR value (some XT class machines may alter it)

	 test	 LCL_FLAG,@LCL_XTCLASS ; Izit an XT class machine?
	 jz	 short @F	; Jump if not

	 mov	 al,PORT21_TEMP ; Get the saved IMR value
	 out	 21h,al 	; Store back as IMR
@@:

INT_XX_CLEANUP:

; Load all important segment registers with PGROUP

	 mov	 ax,cs		; Get current code segment
	 mov	 ds,ax		; Smear into DS
	 mov	 es,ax		; Smear into ES
	 assume ds:PGROUP,es:PGROUP ; Tell the assembler about it

; If this is interrupt 71h, then we have to restore the INT 0A handler

	 cmp	 INTXX,71h	; Izit interrupt 71h?
	 jne	 short NOT_INT71_B ; Jump if not

	 REGSAVE <ds>		; Save register

	 lds	 dx,OLDINT0A_VEC ; Get original INT 0A vector
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,0Ah 	; We want to set this interrupt
	 DOSCALL @SETINT	; Set interrupt vector in AL to DS:DX

	 REGREST <ds>		; Restore register
	 assume  ds:PGROUP	; Tell the assembler about it

NOT_INT71_B:

; If this is INT 02h, restore the original handler

	test	LCL_FLAG,@LCL_INT02 ; Izit INT 02h?
	jz	short NOT_INT02_B ; Jump if not

	push	es		; Save for a moment

	mov	bx,@DBG_HLT	; Flip the CLI/HLT flag
	EMMOUT	@EMM2_DBGFLAG	; Flip bits in DBG_FLAG

	xor	ax,ax		; A convenient zero
	mov	es,ax		; Address the interrupt table
	assume	es:nothing	; Tell the assembler about it

	mov	eax,INT_VECTOR	; Get the original handler
	mov	es:[02h*(type INT00_VEC)],eax ; Restore

	pop	es		; Restore
	assume	es:PGROUP	; Tell the assembler about it

	and	LCL_FLAG,not @LCL_INT02 ; No more
NOT_INT02_B:

; If this is interrupt 06 or 0Dh, then we have to restore the INT 10 handler

	 cmp	 INTXX,06h	; Izit interrupt 06h?
	 je	 short @F	; Jump if so

	 cmp	 INTXX,0Dh	; Izit interrupt 0Dh?
	 jne	 short NOT_INT0D_B ; Jump if not
@@:

	 REGSAVE <ds>		; Save register

	 lds	 dx,OLDINT10_VEC ; Get original INT 10 vector
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,10h 	; We want to set this interrupt
	 DOSCALL @SETINT	; Set interrupt vector in AL to DS:DX

	 REGREST <ds>		; Restore register
	 assume  ds:PGROUP	; Tell the assembler about it

NOT_INT0D_B:

	 pop	 cx		; Restore interrupt counter

	 add	 si,STRUCT_LEN ; Point to next function
	 dec	 cx		; Count one more function as done
	 dec	 INT_COUNTER_DN ; Decrement debug counter
	 inc	 INT_COUNTER_UP ; Increment debug counter

	 cmp	 cx,0		; Are we all done?
	 jne	 near ptr INTXX_LOOP ; Jump if not

INT_XX_EXIT:

	 call	 CHECK_ABORT	; Does the user wish to terminate?
				; Note CF significant upon return

	 popad			; Restore everything
	 REGREST <es,ds>	; Restore Registers
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT_XX	 endp			; End INT_XX procedure

;***************************************************************************

	NPPROC	LOCAL_INT02 -- Local INT 02h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 02h handler

If we enter here, we were on a BIOS which responds to a software
INT 02h with a CLI/HLT.

|

	lss	sp,SAVED_STACK	; Restore

	jmp	FATAL_ERR_RETURN ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOCAL_INT02 endp		; End LOCAL_INT02 procedure

;***************************************************************************

	 NPPROC  DEBUG_INTXX -- Decide if debugger should be called
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

1) Debug via BEEP (if requested)
2) Debug via Write to video (if requested)
3) Read DEBUG flags to determine if we should INT 01 on exit

Note: Do not destroy any registers before DEBUG_WRITE

On exit :
CF	=	1 if debugger should be called
		0 if no action is neccessary

|

READ_DEBUG macro NUM, NUMH

	 test	 CMD_FLAG,@CMD_DEBUG&NUM ; Debug on int &NUM?
	 jz	 short @F	; Jump if not

ifidn <NUMH>,<99h>
	 test	 [si].P_FLAG,@MISC ; Izit a MISC interrupt?
	 jz	 short @F	; Jump if not
else
	 cmp	 INTXX,&NUMH	; Izit out interrupt?
	 jne	 short @F	; Jump if not
endif

	 jmp	 short DEBUG_INTXX_STC ; Call debugger in a moment
@@:

endm				; End of READ_DEBUG amcro

	 REGSAVE <ax,dx>	; Save registers

; Beep if debugging active

	 test	 CMD_FLAG,@CMD_DEBUGBEEP ; Beep debugging active?
	 jz	 short @F		; Jump if not

;;;;;;;; call	 BEEP_HIGH	; Beep the speaker
	 call	 BEEP_LOW	; Beep the speaker
@@:

	 call	 DEBUG_WRITE	; Write Debugging info on screen (if requested)

; Read Debugging flags (jump to STC if user requested)

	 READ_DEBUG 10,10h	; Look to see if DEBUG10 set
	 READ_DEBUG 13,13h	; Look to see if DEBUG13 set
	 READ_DEBUG 15,15h	; Look to see if DEBUG15 set
	 READ_DEBUG 1A,1Ah	; Look to see if DEBUG1A set
	 READ_DEBUG 40,40h	; Look to see if DEBUG40 set
	 READ_DEBUG 99,99h	; Look to see if DEBUG99 set

DEBUG_INTXX_CLC:
	 clc			; Mark as do not call debugger
	 jmp	 short DEBUG_INTXX_EXIT ; Join common exit code

DEBUG_INTXX_STC:
	 stc			; Mark as Call debugger upon exit

DEBUG_INTXX_EXIT:

	 REGREST <dx,ax>	; Restore Registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEBUG_INTXX	 endp			; End DEBUG_INTXX procedure

;***************************************************************************

	 NPPROC  DEBUG_WRITE -- Write debugging info to the screen
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Display Debugging information on screen (if requested)

 1) Display interrupt number
 2) Display all registers
 3) Display interrupt count and remaining interrupt count

On entry:
All registers are what they will be for interrupt simulation

|

	 REGSAVE <ax,cx,si,di,es>	; Save

	 test	 CMD_FLAG,@CMD_DEBUGWRITE ; Write debugging active?
	 jz	 near ptr DEBUG_WRITE_EXIT ; Jump if not

; Format the debugging information

	 push	 di		; Save caller's DI

	 lea	 di,DEBUG_BUFF_AX ; Temporary place holder for function
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 lea	 di,DEBUG_ADVICE2 ; Get interrupt function code
	 mov	 al,ah		; Place in correct register
	 call	 FMT_BYTE	; Format AL ==> ES:DI

	 pop	 di		; Restore caller's DI

	 mov	 ax,di		; Get DI register
	 lea	 di,DEBUG_BUFF_DI ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 ax,bx		; Get BX register
	 lea	 di,DEBUG_BUFF_BX ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 ax,cx		; Get CX register
	 lea	 di,DEBUG_BUFF_CX ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 ax,dx		; Get DX register
	 lea	 di,DEBUG_BUFF_DX ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 ax,si		; Get SI register
	 lea	 di,DEBUG_BUFF_SI ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 ax,bp		; Get BP register
	 lea	 di,DEBUG_BUFF_BP ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 ax,cs		; Get CS register
	 lea	 di,DEBUG_BUFF_CS ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 ax,ds		; Get DS register
	 lea	 di,DEBUG_BUFF_DS ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 ax,es		; Get ES register
	 lea	 di,DEBUG_BUFF_ES ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 ax,ss		; Get SS register
	 lea	 di,DEBUG_BUFF_SS ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 al,INTXX	; Get interrupt number
	 lea	 di,DEBUG_BUFF_INT ; Temporary place holder for interrupt
	 call	 FMT_BYTE	; Format AL ==> ES:DI

	 mov	 al,INTXX	; Get interrupt number
	 lea	 di,DEBUG_ADVICE1 ; Temporary place holder for interrupt
	 call	 FMT_BYTE	; Format AL ==> ES:DI

	 mov	 ax,INT_COUNTER_UP ; Get # of ints processed
	 lea	 di,DEBUG_BUFF_CNT ; Temporary place holder for counter
	 call	 FMT_BYTE	; Format AL ==> ES:DI

	 mov	 ax,INT_COUNTER_DN ; Get # of ints remaining
	 lea	 di,DEBUG_BUFF_REM ; Temporary place holder for counter
	 call	 FMT_BYTE	; Format AL ==> ES:DI

	 mov	 ax,INT_VECTOR.VSEG ; Get routine's CS
	 lea	 di,DEBUG_BUFF_SEG ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI

	 mov	 ax,INT_VECTOR.VOFF ; Get routine's IP
	 lea	 di,DEBUG_BUFF_OFF ; String address
	 call	 FMT_WORD	; Format AX ==> ES:DI


; Display the top debugging line

	 mov	 es,VIDEO_SEG	; Address the video segment
	 assume es:nothing	; Tell the assembler about it

	 lea	 si,DEBUG_BUFFER1 ; Source of debugging info
	 xor	 di,di		; Destin ...
	 mov	 cx,@DEBUG_BUFLEN1 ; Number of format bytes

@@:
S16	 movsb			; Place char in video memroy
	 inc	 di		; Skip past attribute byte

	 loop	 short @B	; Jump if more characters to do

; Display the middle debugging line

	 lea	 si,DEBUG_BUFFER2 ; Source of debugging info
	 mov	 di,(160*(2-1)) ; Second video row
	 mov	 cx,@DEBUG_BUFLEN2 ; Number of format bytes

@@:
S16	 movsb			; Place char in video memroy
	 inc	 di		; Skip past attribute byte

	 loop	 short @B	; Jump if more characters to do

; Display the bottom debugging line

	 lea	 si,DEBUG_BUFFER3 ; Source of debugging info
	 mov	 di,(160*(3-1)) ; Third video row
	 mov	 cx,@DEBUG_BUFLEN3 ; Number of format bytes

@@:
S16	 movsb			; Place char in video memroy
	 inc	 di		; Skip past attribute byte

	 loop	 short @B	; Jump if more characters to do

; Display the advice line

	 lea	 si,DEBUG_ADVICE ; Source of advice line
	 mov	 di,(160*(4-1)) ; Fourth video row
	 mov	 cx,@DEBUG_ADVICE ; Number of format bytes

@@:
S16	 movsb			; Place char in video memroy
	 inc	 di		; Skip past attribute byte

	 loop	 short @B	; Jump if more characters to do

DEBUG_WRITE_EXIT:

	 REGREST <es,di,si,cx,ax>	; Restore registers
	 assume es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEBUG_WRITE	 endp			; End DEBUG_WRITE procedure

;***************************************************************************

	 NPPROC  DEBUG_MISC -- Write misc debugging info to the screen
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Display Debugging information on screen

On entry :
BX	=	Miscellanious interrupt in question (0 relative)

On exit :
BX	=	Destroyed.

|

	 REGSAVE <ax,cx,si,di,es>	; Save registers

	 test	 CMD_FLAG,@CMD_DEBUGWRITE ; Write debugging active?
	 jz	 short DEBUG_MISC_EXIT ; Jump if not

; Address the video screen

	 mov	 es,VIDEO_SEG	; Address the video segment
	 assume es:nothing	; Tell the assembler about it

	 xor	 di,di		; Destin address (video offset)

; Address the debugging header

	 lea	 si,STATUS_HEADER ; Address of header
	 mov	 cx,@STATUS_HEADER_LEN ; Length of it

; Display header

@@:
	 lodsb			; Get first byte
S16	 stosb			; Place in video memory
	 inc	 di		; Skip past attribute byte

	 loop	 short @B	; Jump if more characters to do

; Address the correct debug text line

	 shl	 bx,4		; Mult. by 16 to get proper string
	 lea	 si,[bx].STATUS_TEXT0 ; Address of string
	 mov	 cx,@STATUS_TEXT_LEN ; Number of format bytes

; Display debugging text line

@@:
	 lodsb			; Get first byte
S16	 stosb			; Place in video memory
	 inc	 di		; Skip past attribute byte

	 loop	 short @B	; Jump if more characters to do

DEBUG_MISC_EXIT:

	 REGREST <es,di,si,cx,ax> ; Restore registers
	 assume es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEBUG_MISC	 endp			; End DEBUG_MISC procedure

;***************************************************************************

	 NPPROC  CHECK_BOGUS_INT -- Check for Bogus interrupt code
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Check all interrupt vectors and verify that they are valid (non-zero).
Check the interrupt code and check that it is not filler code.
Check to see if the interrupt is in the XBDA
If the interrupt is one of the "IBM Reserved" interrupts,
	we only execute one of these if it is at or above SYSROM_START

If the interrupt vector is OK, set up the address for PUSHF/CALL

There is a keyword to skip testing all 'Reserved' interrupts.

On entry :
AX	=	Interrupt number
SI	=	Pointer to current interrupt data structure

On exit :
CF	=	1 if we should skip this interrupt
		0 Otherwise

|

	 REGSAVE <eax,bx,es>	; Save registers

; Check to see if the interrupt vector is valid

	 movzx	 eax,ax 	; Extend interrupt number to 32 bits

	 xor	 bx,bx		; A convenient zero
	 mov	 es,bx		; Address the interrupt table
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[eax*4].EDD,0 ; Is the vector 0?
	 je	 short CHECK_BOGUS_STC ; Jump if so (vector is not valid)

; Get the interrupt vector

	 les	 bx,es:[eax*4]	; Get vector into ES:BX
	 assume  es:nothing	; Tell the assembler about it

; Store vector for later PUSHF/CALL (interrupt simulation)

	 mov	 INT_VECTOR.VOFF,bx ; Save for later use
	 mov	 INT_VECTOR.VSEG,es ; ...

; Check to see if the interrupt routine is valid

	 cmp	 es:[bx].EDD,0	; Izit filler?
	 je	 short CHECK_BOGUS_STC ; Jump if so

	 cmp	 es:[bx].EDD,0FFFFFFFFh ; Izit filler?
	 je	 short CHECK_BOGUS_STC ; Jump if so

	 cmp	 es:[bx].EDD,'386M' ; Izit filler?
	 je	 short CHECK_BOGUS_STC ; Jump if so

	 cmp	 es:[bx].EDD,'86M3' ; Izit filler?
	 je	 short CHECK_BOGUS_STC ; Jump if so

	 cmp	 es:[bx].EDD,'6M38' ; Izit filler?
	 je	 short CHECK_BOGUS_STC ; Jump if so

	 cmp	 es:[bx].EDD,'M386' ; Izit filler?
	 je	 short CHECK_BOGUS_STC ; Jump if so

	 cmp	 es:[bx].ELO,055AAh ; Izit a ROM signature?
	 je	 short CHECK_BOGUS_STC ; Jump if so

	 cmp	 es:[bx].ELO,0AA55h ; Izit the other ROM signature?
	 je	 short CHECK_BOGUS_STC ; Jump if so

; Is interrupt pointing into the XBDA?

	 mov	 bx,es		; Get segment into usable register

	 cmp	 bx,XBIOS_SEG	; Izit same?
	 je	 short CHECK_BOGUS_STC ; Jump if so

; Interrupt code looks good - Is this an 'IBM Reserved' interrupt?

	 test	 [si].P_FLAG,@RES ; Is this one 'Reserved'
	 jz	 short CHECK_BOGUS_CLC ; Jump if not

; Are we skipping all 'Reserved' interrupts?

	 test	 CMD_FLAG,@CMD_SKIPRES ; Skip all reserved interrupts?
	 jnz	 short CHECK_BOGUS_STC ; Jump if so

; Determine if the 'Reserved' interrupt is in ROM

	 cmp	 bx,SYSROM_START ; Is vector pointing below the ROM?
	 jb	short CHECK_BOGUS_EXIT ; Jump if so (Note CF is set)

; 'Reserved' Interrupt code is in our range

	 jmp	 short CHECK_BOGUS_CLC ; Process this interrupt

CHECK_BOGUS_STC:
	 stc			; Mark as to skip this interrupt
	 jmp	 short CHECK_BOGUS_EXIT ; Join common exit code

CHECK_BOGUS_CLC:
	 clc			; Mark as process interrupt

CHECK_BOGUS_EXIT:

	 REGREST <es,bx,eax>	; Restore Registers
	 assume  es:nothing	; tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BOGUS_INT  endp		; End CHECK_BOGUS_INT procedure

;***************************************************************************

	 NPPROC  SETUP_IRQ -- Setup the PUSHF/ALL address for IRQs
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

If the current interrupt is an IRQ,
modify the PUSHF/CALL address to use the original BIOS entry point.

On entry :
AX	=	Interrupt number
SI	=	Pointer to current interrupt data structure

|

	 REGSAVE <ebx,cx>	; Save registers

	 test	 [si].P_FLAG,@IRQ ; Is this one an IRQ?
	 jz	 short SETUP_IRQ_EXIT ; Jump if not

	 mov	 cx,@OLDIRQ_NUM ; Number of IRQs to check
	 lea	 bx,OLDIRQ_TBL	; Table of BIOS entry points
@@:
	 cmp	 al,[bx].OLDIRQ_NUM ; Our interrupt?
	 je	 short SETUP_IRQ_FOUND ; Jump if so

	 add	 bx,size OLDIRQ_STR ; Point to next item in list
	 loop	 short @B	; Check next item

	 jmp	 short SETUP_IRQ_EXIT ; Must not be an IRQ
				; This should never happen [FIXME]

SETUP_IRQ_FOUND:

	 mov	 ebx,[bx].OLDIRQ_VEC ; Get original IRQ vector
	 mov	 INT_VECTOR,ebx ; ... and store for PUSHF/CALL

SETUP_IRQ_EXIT:

	 REGREST <cx,ebx>	; Restore Registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_IRQ	 endp			; End SETUP_IRQ procedure

;***************************************************************************

	 NPPROC  CHECK_ABORT -- See if the user wants to abort
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Check if the user has pressed the ESCAPE key

On exit:
CF	=	0 if all is fine
		1 if User requested to ABORT via the ESC key

|

	 REGSAVE <>		; Save registers

; Is there something in the buffer?

CHECK_ABORT_NEXT:
	 mov	 ah,01h 	; Read keyboard status function
	 int	 016h		; Keyboard Services

	 jz	 short CHECK_ABORT_CLC ; Jump if no key waiting

	 mov	 ah,0h		; Read keyboard character function
	 int	 016h		; Read keyboard into AX

	 cmp	 al,ESCAPE	; Izit ESC character
	 jne	 short CHECK_ABORT_NEXT ; Jump if not (see if there are more)

	 stc			; Mark as ABORT requested
	 jmp	 short CHECK_ABORT_EXIT ; Join common exit code

CHECK_ABORT_CLC:
	 clc			; Mark as no ABORT requested

CHECK_ABORT_EXIT:

	 REGREST <>		; Restore Registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ABORT	 endp			; End CHECK_ABORT procedure

;***************************************************************************

	 NPPROC  PRESS_ANY_KEY -- Invokes user input
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

By asking the user to begin, we can exercise the IRQ 1 handler.

On exit:
CF	=	1 if user wishes to abort program.
		0 Otherwise

|

	 REGSAVE <ax,dx>	; Save registers

; Flush the keyboard buffer

FLUSH_BUFFER:

	 mov	 ah,01h 	; Read keyboard status function
	 int	 016h		; Keyboard Services

	 jz	 short @F	; Jump if no key waiting

	 mov	 ah,0		; Read keyboard character function
	 int	 016h		; Read keyboard into AX

	 jmp	 short FLUSH_BUFFER ; Look for more in buffer

; Wait for user acknowledgement to start PROBE

@@:
	 mov	 ah,0h		; Read keyboard character function
	 int	 016h		; Read keyboard into AX

	 cmp	 al,ESCAPE	; Izit ESC character
	 je	 short PRESS_ANY_KEY_STC ; jump if so

PRESS_ANY_KEY_CLC:
	 clc			; Mark as all is fine
	 jmp	 short PRESS_ANY_KEY_EXIT ; Join common exit code

PRESS_ANY_KEY_STC:
	 stc			; Mark as User aborting

PRESS_ANY_KEY_EXIT:

	 REGREST <dx,ax>	; Restore Registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PRESS_ANY_KEY	 endp			; End PRESS_ANY_KEY procedure

;***************************************************************************

	 NPPROC  PATCH_INTS -- Patch parts of our interrupt table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Patch interrupts for machine specific problems.

1) Skip INT 75 if no NDP present
2) Modify Mode Switch calls if on monochrome system
3) If no mouse present, do not do INT 15 (or INT 74) Mouse calls
4) If Toshiba T2000SXe or T4400SX, skip INT 02
5) Look for machine with disk buffer at F000 (like the Tandy 4000)
6) Skip VESA mode switch if VESA not present
7) Skip VGA functions if VGA not available
8) Check for INT 75/INT 02 problem
9) If Orchid Fahrenheit 1280, skip INT 10 func 1C calls (due to BIOS bug)
10) If on an XT machine, skip all AT class calls
11) If on a TI TravelMate laptop, skip suspend function (interrupt 77)

Note:
This routine must be executed before STORE_INTS, because our
string scans will access the entire BIOS.

|

	 REGSAVE <ax,bx,cx,dx,si,di,es,fs> ; Save registers

;------------------------------------------------------------

; Skip INT 75 if no NDP present

	 test	 LCL_FLAG,@LCL_NDP ; Any coprocessor present?
	 jnz	 short PATCH_XNDP ; Jump if so

	 or	 I75.P_FLAG,@SKIP ; Skip this interrupt (if no 387)

PATCH_XNDP:

; If on a monochrome system,
; patch most mode switches to go to mono instead of color

	 cmp	 VIDEO_MODE,07h ; Izit mono mode?
	 jne	 short PATCH_XMONO ; Jump if not

	 mov	 I10A.P_AX,0007h	; Switch to mono mode
	 mov	 I10B.P_AX,0007h	; ...
	 mov	 I10C.P_AX,0007h	; ...
	 mov	 I10D.P_AX,0007h	; ...
	 mov	 I10E.P_AX,0007h	; ...
	 mov	 I10F.P_AX,0007h	; ...
	 mov	 I10G.P_AX,0007h	; ...
	 mov	 I10H.P_AX,0007h	; ...

PATCH_XMONO:

;------------------------------------------------------------

; If on Toshiba T2000SXe or T4400SX, skip the INT 02 test
; This interrupt is actually Protected Mode code

	 mov	 ax,ds		; Get addressability to our data
	 mov	 fs,ax		; ... via FS
	 assume  fs:nothing	; Tell the assembler about it

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset PGROUP:T4400SX_ID ; Get offset of source string
	 push	 T4400SX_IDLEN	; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jnc	 short PATCH_SKIP02 ; Jump if found
				; Return with DI = offset of match in ROM

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset PGROUP:T2000SXE_ID ; Get offset of source string
	 push	 T2000SXE_IDLEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short PATCH_XT2000SXE ; Jump if not found
				; Return with DI = offset of match in ROM
PATCH_SKIP02:
	 or	 I02.P_FLAG,@SKIP ; Skip this interrupt

PATCH_XT2000SXE:

;------------------------------------------------------------

	 test	 LCL_FLAG,@LCL_F000BUFFER ; Did we already decide to
				; ... access F000-F800?
	 jnz	 short NOT_F000BUFFER ; Jump if so

; Look for a disk buffer at F000 (like on Tandy 4000)
; Note: We can only do this if we're on DOS 3.30 (or greater)
;	The LCL_F000BUFFER flag is already set if we're on DOS 3.00 - 3.20

	 mov	 ah,2		; Floppy Read function
	 mov	 al,1		; Sector count
	 mov	 dx,80h 	; Head 0, Hard disk 0
	 mov	 cx,1		; Track 0, Sector 1
	 mov	 bx,@ZTAIL	; Address of our buffer (ES:BX)

	 pushf			; Simulate interrupt
	 cli			; ...
	 call	 INT13_BIOS	; Call Interrupt 13h services (BIOS entry point)
	 jc	 short NOT_F000BUFFER ; Jump if error (skip buffer test)

; Compare our buffer to F000:0

	 push	 0F000h 	; Address the allegged buffer
	 pop	 es		; ... via FS
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; Offset of alleged buffer
	 mov	 si,@ZTAIL	; Offset of our buffer
	 mov	 cx,512 	; Byte count of one sector
    repe cmpsb			; Compare our buffer with F000:0
	 jnz	 short NOT_F000BUFFER ; Jump if not a match

	 or	 LCL_FLAG,@LCL_F000BUFFER ; Indicate disk buffer at F000:0

NOT_F000BUFFER:

;------------------------------------------------------------

; Look for a VESA compliant video adapter

	 test	 LCL_FLAG,@LCL_VESA ; VESA BIOS present?
	 jnz	 short PATCH_XVESA ; Jump if so

	 mov	 I10VESA.P_FLAG,@SKIP ; Skip this interrupt

PATCH_XVESA:

;------------------------------------------------------------

; Skip VGA functions if VGA not available

	 test	 LCL_FLAG,@LCL_VGAPRES ; VGA present?
	 jnz	 short PATCH_XVGA ; Jump if so

	 xor	 bx,bx		; Start at base of I10VGA1 table
	 mov	 cx,I10VGA1_LEN ; Number of INT 10 VGA calls
@@:
	 or	 I10VGA1[bx].P_FLAG,@SKIP ; Skip this interrupt
	 add	 bx,STRUCT_LEN	; Point to next table entry

	 loop	 short @B	; Do for next entry

	 xor	 bx,bx		; Start at base of I10VGA2 table
	 mov	 cx,I10VGA2_LEN ; Number of INT 10 VGA calls
@@:
	 or	 I10VGA2[bx].P_FLAG,@SKIP ; Skip this interrupt
	 add	 bx,STRUCT_LEN	; Point to next table entry

	 loop	 short @B	; Do for next entry

PATCH_XVGA:

;------------------------------------------------------------

; Skip INT 75 if INT 02 looks bad
; This is becuase INT 75 calls INT 02.

	 mov	 ax,02h 	; Get the interrupt in question

	 call	 CHECK_BOGUS_INT ; Is this interrupt valid?
	 jnc	 short PATCH_02_75 ; Jump if it is fine

	 mov	 I75.P_FLAG,@SKIP ; Skip this interrupt
PATCH_02_75:

;------------------------------------------------------------

; If on an Orchid Fahrenheit 1280 VGA, skip all INT 10 func 1C tests.
; This function call references the BDA without setting DS, causing DX
; to be loaded with the wrong port number, resulting in a lockup.
; Note: This machine can not be VGASWAPPed due to other reasons.

	 mov	 ax,ds		; Get addressability to our data
	 mov	 fs,ax		; ... via FS
	 assume  fs:nothing	; Tell the assembler about it

	 push	 dword ptr 0C0000F00h ; Get starting offset of BIOS
	 push	 ORCHIDVGA_IDLEN+2 ; Length of search area
	 push	 offset PGROUP:ORCHIDVGA_ID ; Get offset of source string
	 push	 ORCHIDVGA_IDLEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short PATCH_ORCHIDVGA ; Jump if not found
				; Return with DI = offset of match in ROM

	 or	 I101C_A.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I101C_B.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I101C_C.P_FLAG,@SKIP ; Skip this interrupt

	 or	 LCL_FLAG,@LCL_SKIP1C ; Skip SAVE/RESTORE via function 1C
PATCH_ORCHIDVGA:

;------------------------------------------------------------

; If this is an XT class machine, there are certain interrupts to skip
; These include ...
;  * INT 16, func 05/00
;  * Hardware interrupts betwwen IRQ8 and IRQ15 (INT70 through INT77)

	 test	 LCL_FLAG,@LCL_XTCLASS ; Is this an XT machine?
	 jz	 short PATCH_XT_DONE ; Jump if not

	 or	 I1605A.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I1605B.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I1605C.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I1605D.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I1600.P_FLAG,@SKIP ; Skip this interrupt

	 or	 I70.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I71.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I72.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I73.P_FLAG,@SKIP ; Skip this interrupt
;;;;;;;; or	 I74.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I75.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I76.P_FLAG,@SKIP ; Skip this interrupt
	 or	 I77.P_FLAG,@SKIP ; Skip this interrupt

PATCH_XT_DONE:

;------------------------------------------------------------

; If on TI TravelMate 3000, DG Walkabout/320, or similar machine
; skip the INT 77 test which shuts down the machine.

	 mov	 ax,ds		; Get addressability to our data
	 mov	 fs,ax		; ... via FS
	 assume  fs:nothing	; Tell the assembler about it

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset PGROUP:BATTERYWATCH_ID ; Get offset of source string
	 push	 BATTERYWATCH_IDLEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short PATCH_XBATTERYWATCH ; Jump if not found
				; Return with DI = offset of match in ROM

	 or	 I77.P_FLAG,@SKIP ; Skip this interrupt

PATCH_XBATTERYWATCH:

; Some Everex Tempo machines contain buggy interrupt 06 code.
; We have to recognize this code, and if found, skip testing interrupt 06.

	 mov	 ax,ds		; Get addressability to our data
	 mov	 fs,ax		; ... via FS
	 assume  fs:nothing	; Tell the assembler about it

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset PGROUP:EVEREX_TEMPO_ID ; Get offset of source string
	 push	 EVEREX_TEMPO_ID_LEN ; Get length of ...
	 call	 SRCHSTRI	; Search for the string (w/ don't care bytes)
	 jc	 short PATCH_XEVEREXTEMPO ; Jump if not found
				; Return with DI = offset of match in ROM

	 or	 I06.P_FLAG,@SKIP ; Skip this interrupt

PATCH_XEVEREXTEMPO:


;------------------------------------------------------------

	 REGREST <fs,es,di,si,dx,cx,bx,ax> ; Restore Registers
	 assume  fs:nothing,es:PGROUP ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PATCH_INTS	 endp			; End PATCH_INTS procedure

;***************************************************************************

	 NPPROC  MISC_CODE -- Tests misc. BIOS routines
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Perform miscelaneous code.

1) VGA routine : Select color subset
2) Write string (char)
3) Write string (char/attr)
4) Read/Write to diskette
   Try A:, if that doesn't work, try B:
5) Read/Write to Hard disk
6) Check secondary video adapter

N.B. If a routine is added, add to the debugging text in data group

On exit:
CF set is user requested ABORT.

|

	 REGSAVE <>	; Save registers
	 pusha		; Sae all GP registers

;----------------------------------------------------------

; Perform VGA routine : Select color subset

	 test	 CMD_FLAG,@CMD_DEBUG10 ; Are we debugging Video today?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:

	 mov	 bx,@STAT_COLORSLCT ; First debugging message
	 call	 DEBUG_MISC	; Spit out debugging string

	 mov	 ax,0101Ah	; VGA Read color page state register
	 int	 10h		; Return BH = active subset #
				;	 BL = # of sets avail.

	 mov	 dx,bx		; Save result

	 mov	 ax,01013h	; Subset Color select function
	 mov	 bl,00h 	; Select paging mode
	 mov	 bh,dl		; Get active paging mode
	 int	 10h		; Set it

	 mov	 ax,01013h	; Subset Color select function
	 mov	 bl,01h 	; Select active page
	 mov	 bh,dh		; Get active page
	 int	 10h		; Set it

;----------------------------------------------------------

MISC_CODE_WRITE_STRING:

	 mov	 bx,@STAT_WRITE1 ; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

; Write string (same attribute)

	 mov	 ax,01300h	; Write string, one attribute
	 mov	 bx,0007h	; Page 0, normal attr
	 mov	 cx,MSG_SPACELEN ; String length
	 mov	 dx,0		; Row 0, Column 0
	 lea	 bp,MSG_SPACE1	; Address of string
	 int	 10h		; Write it

;----------------------------------------------------------

; Write string (new attribute)

	 mov	 bx,@STAT_WRITE2 ; Debugging message number
	 call	 DEBUG_MISC	; Spit out string

	 mov	 ax,01302h	; Write string, with attributes
	 mov	 bx,0007h	; Page 0, normal attr
	 mov	 cx,MSG_SPACELEN ; String length
	 mov	 dx,0		; Row 0, Column 0
	 lea	 bp,MSG_SPACE2	; Address of string
	 int	 10h		; Write it

;----------------------------------------------------------

MISC_CODE_READWRITE:

	 test	 CMD_FLAG,@CMD_DEBUG40 ; Are we debugging Diskette today?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:

	 mov	 bx,@STAT_FLOPPY ; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

; Check for diskette in drive A:

	 mov	 si,3		; Try 3 times before we move on
@@:
	 mov	 ax,0201h	; Read function, 1 sector
	 mov	 bx,@ZTAIL	; Our buffer
	 mov	 cx,0001h	; Track 0, Secotr 1
	 mov	 dx,0000h	; Head 0, Drive 0

	 int	 13h		; Read it in
	 jnc	 short MISC_CODE_A ; Jump if it worked

	 xor	 ah,ah		; Reset disk subsystem function
	 xor	 dl,dl		; Drive 0
	 int	 13h		; Reset it

	 dec	 si		; Count in one more try
	 jnz	 short @B	; Try again

; Check for diskette in B:

	 mov	 si,3		; Try 3 times
@@:
	 mov	 ax,0201h	; Read function, 1 sector
	 mov	 bx,@ZTAIL	; Our buffer
	 mov	 cx,0001h	; Track 0, Secotr 1
	 mov	 dx,0001h	; Head 0, Drive 1

	 int	 13h		; Read it in
	 jnc	 short MISC_CODE_B ; Jump if it worked

	 xor	 ah,ah		; Reset disk subsystem function
	 mov	 dl,01		; Drive 1
	 int	 13h		; Reset it

	 dec	 si		; Count one more try
	 jnz	 short @B	; Try again

; Neither A: nor B: are available

	 DISP_STDERR MSG_NOFLOPPY ; Display error message

; Wait for a keystroke

	 call	PRESS_ANY_KEY	; Envoke user input to begin
	 jnc	near ptr MISC_CODE_READWRITE ; User wants to try again
				; Note: CF significant

	 or	 LCL_FLAG,@LCL_ABORT ; Indicate user is skipping floppy test

	 jmp	 short MISC_CODE_SKIPFLOPPY ; Join common exit code

MISC_CODE_A:

; Perform Diskette I/O on A:

	 lea	 ax,FILENAME_A1 ; Get first floppy temp name
	 mov	 FIRST_FILE,ax	; And save for upcoming routine

	 lea	 ax,FILENAME_A2 ; Get second floppy temp name
	 mov	 SECOND_FILE,ax ; And save for upcoming routine

	 xor	 bp,bp		; Floppy error code base.

	 call	 READ_WRITE	; Perform Floppy Diskette I/O
	 jmp	 short MISC_CODE_HARD ; Jump if it worked


MISC_CODE_B:

; Perform diskette I/O on B:

	 lea	 ax,FILENAME_B1 ; Get first floppy temp name
	 mov	 FIRST_FILE,ax	; And save for upcoming routine

	 lea	 ax,FILENAME_B2 ; Get second floppy temp name
	 mov	 SECOND_FILE,ax ; And save for upcoming routine

	 xor	 bp,bp		; Floppy error code base.

	 call	 READ_WRITE	; Perform Floppy Diskette I/O
	 jmp	 short MISC_CODE_HARD ; Jump if it worked


;----------------------------------------------------------

MISC_CODE_SKIPFLOPPY:
MISC_CODE_HARD:

	 test	 CMD_FLAG,@CMD_DEBUG13 ; Are we debugging Hard Disk today?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:

	 test	 LCL_FLAG,@LCL_HDISK ; Is there a hard disk?
	 jz	 short MISC_NOHARD ; Jump if no hard disks are present

	 mov	 bx,@STAT_HARD	; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

; Perform Hard Disk I/O

	 lea	 ax,FILENAME_C1 ; Get first hard temp name
	 mov	 FIRST_FILE,ax	; And save for upcoming routine

	 lea	 ax,FILENAME_C2 ; Get second hard temp name
	 mov	 SECOND_FILE,ax ; And save for upcoming routine

	 mov	 bp,10h 	; Hard disk error code base.

	 call	 READ_WRITE	; Perform Hard Disk I/O
MISC_NOHARD:

;----------------------------------------------------------

; Perform Secondary video test

	 test	 CMD_FLAG,@CMD_SKIP42 ; Should we skip this?
	 jnz	 short MISC_CODE_X42 ; Jump if so

	 test	 CMD_FLAG,@CMD_DEBUG10 ; Are we debugging Video today?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:
	 mov	 bx,@STAT_INT42 ; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

	 mov	 ax,3000h	; Invalid VGA function call
	 int	 10h		; Call it (3270PC function call)
@@:
MISC_CODE_X42:

;----------------------------------------------------------

	 clc			; Mark as successful

MISC_CODE_EXIT:

	 popa		; Reatore all GP registers
	 REGREST <>	; Restore Registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MISC_CODE	 endp			; End MISC_CODE procedure

;***************************************************************************

	 NPPROC  READ_WRITE -- Reads from and Writes to diskette
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Read/Write from a file on a floppy or hard disk.

1) Create temp filename
2) Creat temporary file
3) Delete first file, but save the name DOS created
4) Write to this file
5) Close file
6) Rename file to name saved previously
7) Reset disk
8) Open this file
9) Read in file
10) Close this file
11) Delete this file

Note: We must create both files before one can be erased.
Otherwise, DOS might use the same 'unique' file name on both files,
and the rename function will then fail.

The floppy portion of this code exercises Interrupt 13 functions ...
00 - Reset diskette
02 - Read  ...
03 - Write ...
16 - Read 'diskette change line' status

The hard disk porion of this code exercises Interrupt 13 functions...
02 - Read  ...
03 - Write ...

On entry :

BP	=	Error code.
		0x indicates floppy error.
		1x indicates hard disk error.

On exit:

CF is set if there was an error

|

@TMP_FILE_SIZE	equ	8000h	; 32KB is a good file size.

	 REGSAVE <>	; Save registers
	 pusha		; Sae all GP registers

	 test	 CMD_FLAG,@CMD_DEBUG13 ; Are we debugging Diskette today?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:

	 test	 CMD_FLAG,@CMD_DEBUG40 ; Are we debugging Hard disk today?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:

; Create temporary file, just to get valid file name for later 'rename'

	 mov	 cx,0h		; Normal attriubute
	 mov	 dx,SECOND_FILE ; Pointer to file

	 DOSCALL @TMPFIL	; Create temp file (5Ah)
	 jc	 near ptr RW_ERR_CREATE ; Jump if error

	 mov	 di,ax		; Save file handle

; Create a temporary file

	 mov	 cx,0h		; Normal attriubute
	 mov	 dx,FIRST_FILE	; Pointer to file

	 DOSCALL @TMPFIL	; Create temp file (5Ah)
	 jc	 short RW_ERR_CREATE ; Jump if error

	 mov	 si,ax		; Save file handle (first file)

; We've got a name, now let's close and delete this file

	 mov	 bx,di		; Get file handle

	 DOSCALL @CLOSF2	; Close the file, handle in BX (3Eh)
	 jc	 short RW_ERR_CLOSE ; Jump if error

	 mov	 dx,SECOND_FILE ; Pointer to file

	 DOSCALL @DELEF2	; Delete file (41h)
	 jc	 short RW_ERR_DELETE ; Jump if error

; Write to the temporary file

	 mov	 bx,si		; Get file handle (first file)

	 xor	 dx,dx		; A convenient zero
	 mov	 ds,dx		; Another convenient zero
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 cx,@TMP_FILE_SIZE ; 32KB
	 DOSCALL @WRITF2	; Write out buffer at DS:DX (40h)
	 jc	 RW_ERR_WRITE	; Jump if something went wrong

; Close the temporary file

	 DOSCALL @CLOSF2	; Close the file, handle in BX (3Eh)
	 jc	 short RW_ERR_CLOSE ; Jump if error

; Gain addressability to our data

	 mov	 ax,cs		; Get our code segment
	 mov	 ds,ax		; And address our data
	 assume  ds:PGROUP	; Tell the assembler abodut it

; Rename the temporary file

	 mov	 dx,FIRST_FILE	; First file
	 mov	 di,SECOND_FILE ; New file

	 DOSCALL @RENMF2	; Reanme DS:DX to ES:DI (56h)
	 jc	 short RW_ERR_RENAME ; Jump if error

; Reset Disk (flush all buffers)

	 DOSCALL @DRESET	; Disk Reset (0Dh)

; Open second file (it is not a temp. file)

	 mov	 al,0		; Normal attributes
	 mov	 dx,SECOND_FILE ; Name of file

	 DOSCALL @OPENF2	; Open file (3Dh)
	 jc	 short RW_ERR_OPEN ; Jump if error

	 mov	 bx,ax		; Save file handle (second file)

; Read in the second file (not temporary any more)

	 mov	 cx,@TMP_FILE_SIZE ; Size of 1st file
	 mov	 dx,@ZTAIL	; Address of our buffer

	 DOSCALL @READF2	; Read in file (3Fh)
	 jc	 short RW_ERR_READ ; Jump if error

; Close the second file

	 DOSCALL @CLOSF2	; Close the file, handle in BX (3Eh)
	 jc	 short RW_ERR_CLOSE ; Jump if error

; Delete the second file

	 mov	 dx,SECOND_FILE ; Pointer to file
	 DOSCALL @DELEF2	; Delet file, handle in BX (41h)
	 jc	 short RW_ERR_DELETE ; Jump if error

	 clc			; Mark as no error
	 jmp	 short READ_WRITE_EXIT ; Continue on


RW_ERR_OPEN:			; Open error
	 inc	 bp		; Increment error code (7)

RW_ERR_READ:			; Read error
	 inc	 bp		; Increment error code (6)

RW_ERR_RENAME:			; Rename error
	 inc	 bp		; Increment error code (5)

RW_ERR_WRITE:			; Write error
	 inc	 bp		; Increment error code (4)

RW_ERR_CREATE:			; Create error
	 inc	 bp		; Increment error code (3)

RW_ERR_CLOSE:			; Close  ...
	 inc	 bp		; Increment error code (2)

RW_ERR_DELETE:			; Delete ...
	 inc	 bp		; Increment error code (1)

	 mov	 ax,bp		; Get error code (lower half of word)
	 lea	 di, MSG_FILE_ERR1 ; String address of error code
	 call	 FMT_BYTE	; Format AL -> ES:DI

	 or	 LCL_FLAG,@LCL_FILE_ERR ; Mark as File I/O error
	 stc			; Mark as error ocurred

READ_WRITE_EXIT:

	 popa		; Reatore all GP registers
	 REGREST <>	; Restore Registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_WRITE	 endp			; End READ_WRITE procedure

;***************************************************************************

	 NPPROC  CHECK_DISKTABLES -- Read in both disk drive tables
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Read in both Disk Dirve parameter tables - [FIXME]

The COMPAQ machine seems different than the PS2 literature regarding
the Length identifier.
PS2 TRM syas the length identifier is a word, while COMPAQ seems to
have a fixed 16 byte entry (thus no length id).

Either way, if we read in 16 bytes (and at least touch the table)
we should have very high confidence that we will correctly mark this table.

|

	 REGSAVE <ax,bx,cx,dx,si,ds> ; Save Registers

	 mov	 bx,@STAT_INT46 ; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

; Read in the fixed disk drive parameter table #1

	 xor	 si,si		; A convenient zero
	 mov	 ds,si		; Address the interuupt table
	 assume  ds:nothing	; Tell the assembler about it

	 lds	 si,[si+(41h*4)] ; Get the interrupt vector into DS:SI
	 assume  ds:nothing	; Tell the assembler about it

;;;;;;;; mov	 cx,ds:[si]	; Length of Fixed disk drive table [IBM]
	 mov	 cx,16		; Length of Fixed disk drive table [COMAPQ]
     rep lodsb			; Read in entire table

; Read in the fixed disk drive parameter table #2

	 xor	 si,si		; A convenient zero
	 mov	 ds,si		; Address the interuupt table
	 assume  ds:nothing	; Tell the assembler about it

	 lds	 si,[si+(46h*4)] ; Get the interrupt vector into DS:SI
	 assume  ds:nothing	; Tell the assembler about it

;;;;;;;; mov	 cx,ds:[si]	; Length of Fixed disk drive table [IBM]
	 mov	 cx,16		; Length of Fixed disk drive table [COMAPQ]
     rep lodsb			; Read in entire table

	 REGREST <ds,si,dx,cx,bx,ax> ; Restore Registers
	 assume ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DISKTABLES	 endp		; End CHECK_DISKTABLES procedure

;***************************************************************************


	 NPPROC  CHECK_VIDEOTABLES -- Dummy Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Read in all video tables
	*) Interrupts 1Fh and 43h	˚
	*) All fonts (+ supp. fonts)	˚
	*) Static Functionality Table	˚
	*) EGA Save Pointer		˚
	*) VGA Save Pointer		˚
	*) Video Type Code Table	˚
	*) Parameter Table		(did in mode switches)

; Check for EGA or VGA
; What to do if Mono or CGA? [FIXME]

|

	 REGSAVE <ds,es>	; Save registers
	 pusha			; Save all GP registers

	 mov	 bx,@STAT_INT1F ; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

	 REGSAVE <ds>		; Save for just a moment

;---------------------------------------------------------------

; Check INT 1F (upper 128 characters)

	 xor	 ax,ax		; A convenient zero
	 mov	 ds,ax		; Address the interuupt table
	 assume ds:nothing	; Tell the assembler about it

	 mov	 bx,1Fh*4	; Graphics character Font

	 lds	 si,[bx]	; Get the interrupt vector into DS:SI
	 assume ds:nothing	; Tell the assembler about it

	 mov	 cx,4096	; Length of Font
	 rep	 lodsb		; Read in entire table

;---------------------------------------------------------------

; Check INT 43 (lower 128 characters)

	 xor	 ax,ax		; A convenient zero
	 mov	 ds,ax		; Address the interuupt table
	 assume ds:nothing	; Tell the assembler about it

	 mov	 bx,43h*4	; Graphics character Font

	 lds	 si,[bx]	; Get the interrupt vector into DS:SI
	 assume ds:nothing	; Tell the assembler about it

	 mov	 cx,4096	; Length of Font
	 rep	 lodsb		; Read in entire table

	 REGREST <ds>
	 assume ds:PGROUP	; Tell the assembler about it

;---------------------------------------------------------------

; Read in all the ROM fonts

	 mov	 bh,02h 	; ROM 8x14 Font
	 mov	 cx,14*256	; Byte count
	 call	 READ_FONT	; Read in the Font

	 mov	 bh,03h 	; ROM 8x8 Font
	 mov	 cx,8*256	; Byte count
	 call	 READ_FONT	; Read in the Font

	 mov	 bh,04h 	; ROM 8x8 Font (top half)
	 mov	 cx,8*256	; Byte count
	 call	 READ_FONT	; Read in the Font

	 mov	 bh,05h 	; ROM 9x14 Font (supplemental)
	 mov	 bl,14+1	; Bytes per character
	 mov	 cx,0		; Byte count
	 call	 READ_FONT	; Read in the Font

	 mov	 bh,06h 	; ROM 8x16Font
	 mov	 cx,16*256	; Byte count
	 call	 READ_FONT	; Read in the Font

	 mov	 bh,07h 	; ROM 9x16 Font (supplemental)
	 mov	 bl,16+1	; Bytes per character
	 mov	 cx,0		; Byte count
	 call	 READ_FONT	; Read in the Font

;---------------------------------------------------------------

; Read in the Static Functionality Table

	 mov	 ah,1Bh 	; Return VGA Status Info
	 mov	 bx,0		; Parameter (?)
	 mov	 di,@ZTAIL	; Address of our buffer

	 int	 10h		; Video BIOS call

	 cmp	 al,1Bh 	; Check return code
	 jne	 short @F	; Jump if feature not supported

	 lds	 si,es:[di]	; Get pointer to Static functionality table
	 assume ds:nothing	; Tell the assembler about it

	 mov	 cx,0Eh/2	; Size of static Functionality Table in words
     rep lodsw			; Read in the table

@@:

;---------------------------------------------------------------

; Read in the EGA Save Pointer

	 xor	 ax,ax		; A convenient zero
	 mov	 ds,ax		; Address the interuupt table
	 assume ds:nothing	; Tell the assembler about it

	 xor	 si,si		; A convenient zero
	 lds	 si,[si+04A8h]	; Address the EGA Save Pointer
	 assume ds:nothing

	 push	 si		; Save pointer to table
	 mov	 cx,7*4 	; Table has 7 far pointers
     rep lodsb			; Read in the table
	 pop	 si		; Restore pointer

;---------------------------------------------------------------

; Read in the VGA Save Pointer

	 lds	 si,[si+(4*4)]	; Address the VGA Save pointer
	 assume ds:nothing

	 push	 si		; Save pointer to table
	 mov	 cx,ds:[si]	; Get number of far pointers to follow
	 add	 cx,2		; Include counter
     rep lodsb			; Read in the table
	 pop	 si		; Restore pointer

;---------------------------------------------------------------

; Read in the DCC Table

	 lds	 si,[si+2]	; Address the DCC table
	 assume ds:nothing

	 movzx	 cx,ds:[si]	; Get DCC entry count
	 shl	 cx,1		; Each entry is 2 bytes
	 add	 cx,4		; Include DCC header
     rep lodsb			; Read in the table

	 popa			; Restore all GP registers
	 REGREST <es,ds>	; Restore Registers
	 assume ds:PGROUP

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VIDEOTABLES	 endp		; End CHECK_VIDEOTABLES procedure

;***************************************************************************

	 NPPROC  READ_FONT -- Rad in a particular font
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Read in all bytes of particular font.

On entry :	BH	=	Font number (2-7)
		CX	=	Byte count (0=Supplemental font)
		BL	=	Bytes/char (if supp. font)

|

	 REGSAVE <ax,ds,es>	; Save registers

	 push	 cx		; Save counter

	 mov	 ax,1130h	; Return font address
	 int	 10h		; Call the BIOS (ES:BP=pointer to font)
	 assume es:nothing

	 ; Read error codes here [FIXME]

	 pop	 cx		; Restore counter

	 mov	 si,bp		; Get offset of Font
	 mov	 ax,es		; Get segment of font...
	 mov	 ds,ax		;   into a usable register
	 assume ds:nothing

	 cmp	 cx,0		; Supplemental font?
	 jne	 short @F	; Jump if not (else calculate length)

	 mov	 al,es:[bp]	; Get first byte of font
	 mul	 bl		; Multiply by number of characters in font
				; (AL*BL=> AX)

	 mov	 cx,ax		; Place in proper register
	 inc	 cx		; Plus the byte count
@@:
	 rep	 lodsb		; Read in font

	 REGREST <es,ds,ax>	; Restore Registers
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_FONT	 endp			; End READ_FONT procedure

;***************************************************************************

	 NPPROC  CHECK_ALTKEYS -- Similate Alt-key keystrokes
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Simulate Alt-key keystrokes
Simulate some regular keystrokes
Simulate keyboard buffer overflow

|

	 pusha			; Save all GP registers
	 REGSAVE <ds>		; Save segment registers

	 mov	 bx,@STAT_ALTKEYS ; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

; Save interrupt 15h handler

	 REGSAVE <es>		; Save segment registers

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @GETINT	; Get interrupt vector in AL to ES:BX
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT15_VEC.VSEG,es ; Save for later restoer
	 mov	 OLDINT15_VEC.VOFF,bx ; ...

	 REGREST <es>		; Restore segment registers
	 assume  es:PGROUP	; Tell the assembler about it

; Install our interrupt 15 handler

	 mov	 al,15h 	; Restore this interrupt
	 DOSCALL @SETINT,LOCAL_INT15 ; Set interrupt vector in AL to DS:DX

; Check key code list for Alt-key code (or end of list)

CHECK_ALT_NEXT:
	 mov	 bx,SCAN_PTR	; Get next entry in scan code table (marker)
	 inc	 SCAN_PTR	; Point to scan code (skip over marker)

	 cmp	 [bx].LO,@END	; Is it End-Of-List?
	 je	 short CHECK_ALT_EXIT ; Jump if so

	 cmp	 [bx].LO,@ALT	; Is the next entry an Alt-key?
	 jne	 short CHECK_ALT_XALT ; Jump if not

; If requested, simulate the Alt key

	 REGSAVE <ds>		; Save segment register

	 mov	 ax,seg BIOSDATA ; Address the BIOS Data Area
	 mov	 ds,ax		; ...via DS
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 or	 [KB_FLAG],  mask $KB_ALT ; Set 'Either Alt key' to active
	 or	 [KB_FLAG_1],mask $KB1_LALT ; Set 'Left Alt key' to active

	 REGREST <ds>		; Restore segment register
	 assume  ds:PGROUP	; Tell the assembler about it
CHECK_ALT_XALT:

	 int	 09h		; Simulate keystroke

	 call	 DRAIN_KB_BUFFER ; Drain the keyboard buffer

; Ensure that the Alt-key is 'released'
; This can be done even if we have not simulated an Alt key press

	 REGSAVE <ds>		; Save segment register

	 mov	 ax,seg BIOSDATA ; Address the BIOS Data Area
	 mov	 ds,ax		; ...via DS
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 and	 [KB_FLAG],  not (mask $KB_ALT) ; Clear the Alt key flag
	 and	 [KB_FLAG_1],not (mask $KB1_LALT) ; Clear the Left Alt flag

	 REGREST <ds>		; Restore segment register
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 short CHECK_ALT_NEXT ; Test the next keystroke

CHECK_ALT_EXIT:

; Restore interrupt 15h handler

	 lds	 dx,OLDINT15_VEC ; Address of original routine
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,15h 	; Restore this interrupt
	 DOSCALL @SETINT	; Set interrupt vector in AL to DS:DX

	 REGREST <ds>		; Restore segment registers
	 assume  ds:PGROUP	; Tell the assembler about it
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ALTKEYS	 endp			; End CHECK_ALTKEYS procedure

;***************************************************************************

	 NPPROC  CHECK_PRTSCR -- Process PrtScr routines
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Process Print Screen routine and Alternate Print Screen routine.

We hook in a dummy INT 17 handler to speed up PRTSCRs.
This is fine since INT 17 was tested earlier.

|

	 REGSAVE <eax,bx,dx,ds> ; Save registers

	 mov	 bx,@STAT_INT05 ; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

; Save INT 17 vector

	 push	 es		; Save for a moment

	 mov	 al,17h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT 17h handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT17_VEC.VOFF,bx ; Save to restore later
	 mov	 OLDINT17_VEC.VSEG,es

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

; Install our INT 17 vector

	 mov	 al,17h 	; Intercept this one
	 DOSCALL @SETINT,NEWINT17 ; Install our own one

; Restore PrtScr vector
; ... because interrupt 10h testing might have modified this vector

	 mov	 al,05h 	; Restore Prtscr interrupt
	 lds	 dx,OLDINT05_VEC ; DS:DX ==> original handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Install our own one

; Process PrtScr (via current value in IDT)

	 mov	 eax,(5*type INT00_VEC) ; Check interrupt 05 (at 0:14h)
	 call	 VALIDATE_INT	; Validate the PrtScr interrupt
	 jc	 short @F	; Jump if interrupt is invalid

	 int	 05h		; Simulate a Print-Screen
@@:

; Process PrtScr (via BIOS entry Point)

	 mov	 ax,cs		; Segment of vector's address
	 shl	 eax,16 	; Move to upper half of dword
	 lea	 ax,PGROUP:OLDIRQ_05.OLDIRQ_VEC ; Offset of vector's address

	 call	 VALIDATE_INT	; Validate the PrtScr interrupt
	 jc	 short @F	; Jump if interrupt is invalid

	 pushf			; Simulate interrupt
	 sti			; ...
	 call	 OLDIRQ_05.OLDIRQ_VEC ; Process INT05 (as seen prior to MAX)
@@:

; Install Alt-PrtScr routine

	 mov	 ax,1200h	; Alternate Select
	 mov	 bl,20h 	; Alt-Prt-Scrn
	 int	 10h		; Select the Alternate PrtScr routine

; Process Alt-PrtScr

	 mov	 eax,(5*type INT00_VEC) ; Check interrupt 05 (at 0:14h)
	 call	 VALIDATE_INT	; Validate the PrtScr interrupt
	 jc	 short @F	; Jump if interrupt is invalid

	 int	 05h		; Simulate a Print-screen
@@:

; Restore original INT 17 vector

	 mov	 al,17h 	; Restore this one
	 lds	 dx,OLDINT17_VEC ; DS:DX ==> original handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Install our own one

	 REGREST <ds,dx,bx,eax> ; Restore registers
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PRTSCR	 endp			; End CHECK_PRTSCR procedure

;***************************************************************************

	 NPPROC  VALIDATE_INT -- VALIDATE interrupt routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Validate a particular interrupt vector

This is needed to combat a faulty Paradise video BIOS
that contains bad Alternate PrtScr code .

* Ensure vector is not 0:0
* Ensure code is not ADD [BX+SI],AL (0000)
* Ensure code is not ???? [DI]	    (FFFF)
* Ensure code is not 386LOAD filler pattern
* Ensure code is not ROM marker

On entrance:
EAX	=	Seg:Offset of vector address to validate
		For example, to test PrtScr, EAX would be 0:14h

On exit:
CF	=	0 if interrupt is valid
		1 if not

|

	 REGSAVE <eax,bx,ds>	; Save registers

; Address the interrupt vector

	 mov	 bx,ax		; Get offset of vector

	 shr	 eax,16 	; Address the vector's segment
	 mov	 ds,ax		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

; Validate the interrupt vector

	 cmp	 ds:[bx].EDD,0	; Is vector valid?
	 je	 short VALIDATE_INT_STC ; Jump if not a valid vector

; Address the interrupt code

	 lds	 bx,ds:[bx]	; Address the code
	 assume  ds:nothing	; Tell the assembler about it

; Validate the interrupt code

	 cmp	 ds:[bx].ELO,0	; Does it contain zero?
	 je	 short VALIDATE_INT_STC ; Jump if invalid code

	 cmp	 ds:[bx].ELO,-1 ; Does it contain 0FFFFh
	 je	 short VALIDATE_INT_STC ; Jump if invalid code

	 cmp	 ds:[bx].EDD,'386M' ; Does it contain filler?
	 je	 short VALIDATE_INT_STC ; Jump if invalid code

	 cmp	 ds:[bx].EDD,'86M3' ; Does it contain filler?
	 je	 short VALIDATE_INT_STC ; Jump if invalid code

	 cmp	 ds:[bx].EDD,'6M38' ; Does it contain filler?
	 je	 short VALIDATE_INT_STC ; Jump if invalid code

	 cmp	 ds:[bx].EDD,'M386' ; Does it contain filler?
	 je	 short VALIDATE_INT_STC ; Jump if invalid code

	 cmp	 ds:[bx].ELO,055AAh ; Izit a ROM signature?
	 je	 short VALIDATE_INT_STC ; Jump if invalid code

	 cmp	 ds:[bx].ELO,0AA55h ; Izit the other ROM signature?
	 je	 short VALIDATE_INT_STC ; Jump if invalid code

	 clc			; Indicate interrupt is valid

	 jmp	 short VALIDATE_INT_EXIT ; Join common exit code

VALIDATE_INT_STC:
	 stc			; Indicate interrupt is not valid

VALIDATE_INT_EXIT:
	 REGREST <ds,bx,eax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
VALIDATE_INT	 endp		; End VALIDATE_INT procedure

;***************************************************************************

	 NPPROC  CHECK_ABIOS -- Dummy Procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Process both ABIOS function cals

|

	 pushad 		; Save all GP registers

	 test	 CMD_FLAG,@CMD_SKIPABIOS ; Should we skip this test?
	 jnz	 short CHECK_ABIOS_EXIT ; Jump if so

; Test for ABIOS availability (Microchannel check)

	 REGSAVE <es>		; Save register

	 mov	 ah,0C0h	; Return System Configuration function
	 int	 15h		; System services (returns in ES:BX)
	 assume  es:nothing	; Tell the assembler

	 jc	 short @F	; Jump if error (CF significant)

	 test	 es:[bx+5].LO,@BIT1 ; Is this an MCA machine?
				; ZF significant
				; Note: This will Clear CF
@@:
	 REGREST <es>		; Restore register
	 assume  es:PGROUP	; Tell the assembler about it

	 jz	 short CHECK_ABIOS_EXIT ; Jump if this isn't an MCA machine
	 jc	 short CHECK_ABIOS_EXIT ; Jump if function C0 not supported

; Display a little debugging message

	 mov	 bx,@STAT_ABIOS ; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

; Set up the ABIOS

	 call	 POS_INIT	; Initalize the POS

	 cmp	 ax,-1		; Was there an error?
	 je	 short CHECK_ABIOS_EXIT ; Jump if so

; Read the POS values from one adapter

	 mov	 ax,ds		; Get pointer to PGROUP
	 shl	 eax,16 	; Move to upper word

	 mov	 ax,@ZTAIL	; Get pointer to temp buffer
	 push	 eax		; Pointer to Adapter ID

	 add	 ax,2		; Skip over adapter ID space
	 push	 eax		; Pointer to Adapter values

	 add	 ax,4		; Skip over Adapter values
	 push	 eax		; Pointer to CMOS values

	 push	 01		; Slot number

	 call	 POSREAD	; Read the POS values

; Recompute NVRAM checksum

	 call	 NVRAM		; Recompute NVRAM checksum

CHECK_ABIOS_EXIT:
	 popad			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ABIOS	 endp			; End CHECK_ABIOS procedure

;***************************************************************************

	 NPPROC  POS_INIT -- Initialize the ABIOS
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

'C' callable routine to initialize the POS (programable option select) data.

AX	 =	 0 if no error
	 =	 -1 otherwise

Note: This routine is taken from MAXIMIZE

|

	 REGSAVE <si,di,es>	; Save registers

;;;;;;;; mov	 ax,ds		; Get segment of PGROUP
;;;;;;;; mov	 es,ax		; Address it
;;;;;;;; assume  es:PGROUP	; Tell the assembler about it
	 lea	 di,SYSPARM	; ES:DI ==> system parameters table

	 push	 ds		; Save for a moment
	 mov	 ax,0		; Indicate no RAM extension
	 mov	 ds,ax		; DS:0 ==> RAM extension info
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,04h 	; Function code to build system parameters table
	 int	 15h		; Request BIOS service
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jb	 short ERR_RET0 ; Jump if something went wrong

	 mov	 ax,size INIT_TABLE_STR ; Get size of an init table entry
	 mul	 SYSPARM.NUM_ENTR ; Times # init table entries
	 add	 ax,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 ax,cl		; Convert from bytes to paras
	 mov	 bx,ax		; Copy to @GETMEM register
	 DOSCALL @GETMEM	; Allocate Memory for init table
	 jb	 short ERR_RET0 ; Jump if something went wrong

	 mov	 SYSINIT_SEG,ax ; Save for later use
	 mov	 es,ax		; Address that segment
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> initialization table

	 push	 ds		; Save for a moment
	 mov	 ax,0		; Indicate no RAM extension
	 mov	 ds,ax		; DS:0 ==> RAM extension info
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,05h 	; Function code to build initialization table
	 int	 15h		; Request BIOS service
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jc	 short ERR_RET0 ; Jump if something went wrong

COMMENT|

Build Common Data Area (CDA)

The size of the CDA is

size CDAHDR_STR 			header (essentially LID #0)
size CDALID_STR 			LID #1 (reserved)
(size CDALID_STR) x # logical ids	per device in INIT_TABLE_STR
DP_LEN					per device in INIT_TABLE_STR
2					data pointer count field

|

; Loop through the INIT_TABLE structure counting CDA size values

;;;;;;;; xor	 di,di		; ES:DI ==> start of init table
	 mov	 cx,SYSPARM.NUM_ENTR ; Get # init table entries

; Initialize accumulator in bytes

	 mov	 bx,2 + (size CDAHDR_STR) + (size CDALID_STR)
POSINIT_NEXT_ITE:
	 add	 bx,es:[di].DP_LEN ; Plus size of data pointers in bytes

	 mov	 ax,size CDALID_STR ; Get size of LID pointers in bytes
	 mul	 es:[di].NUM_LOG_IDS ; Times # logical IDs
	 add	 bx,ax		; Add into accumulator

	 add	 di,size INIT_TABLE_STR ; Skip to next entry

	 loop	 POSINIT_NEXT_ITE ; Jump if more init table entries

	 mov	 di,bx		; Save byte size

	 add	 bx,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
	 DOSCALL @GETMEM	; Allocate memory for init table
ERR_RET0:
	MJ b,	 ERR_RET	; Jump if something went wrong

	 mov	 CDA_SEG,ax	; Save segment for later use
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

; Zero the CDA

	 push	 di		; Save for a moment

	 mov	 cx,di		; Copy length in bytes
	 xor	 di,di		; ES:DI ==> CDA
	 mov	 al,0		; A convenient zero
     rep stosb			; Zap it

	 pop	 di		; Restore

; Set Data Pointer #0 offset and count field

	 sub	 di,2		; Back off to data pointer count field
	 mov	 es:[di].ELO,0	; Zero data pointer count field

	 sub	 di,size CDADP_STR ; Back off to data pointer #0 length
	 mov	 es:[0].CDAHDR_DP0OFF,di ; Save in CDA

	 mov	 LOGICAL_ID,2	; Starting number for logical ids
	 mov	 INIT_ENTRY_CTR,0 ; Initialize system init table entry count

	 mov	 es,SYSINIT_SEG ; Get segment of system initialization table
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> ...

; We initialize ABIOS internal and POS device ID only

GET_NEXTID:
	 cmp	 es:[di].DEVICE_ID,@ABIOS_POS ; Izit POS Device ID?
	 je	 short INIT_POS_LID ; Jump if so

	 cmp	 es:[di].DEVICE_ID,@ABIOS_NVRAM ; Izit NVRAM Device ID?
	 je	 short INIT_NVRAM_LID ; Jump if so

	 cmp	 es:[di].DEVICE_ID,@ABIOS_INTERNAL ; Izit ABIOS Internal ID?
	 je	 short INIT_INT_LID ; Jump if so

					; Ignore the others
BUMP_ID:
	 mov	 ax,es:[di].NUM_LOG_IDS ; Get # logical IDs in this device
	 add	 LOGICAL_ID,ax	; Count them in
	 add	 di,size INIT_TABLE_STR ; Skip to next init table entry

	 mov	 ax,INIT_ENTRY_CTR ; Get current
	 inc	 ax		; Skip to next one
	 mov	 INIT_ENTRY_CTR,ax ; Save for later use

	 cmp	 ax,SYSPARM.NUM_ENTR ; Are we at the end?
	 jb	 short GET_NEXTID ; Jump if not

	 mov	 es,CDA_SEG	; Get CDA segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,LOGICAL_ID	; Get # logical IDs
	 mov	 es:[0].CDAHDR_NLIDS,ax ; Save in CDA

; Convert pointers in CDA from 32-bit to seg:off

	 mov	 bx,es:[0].CDAHDR_DP0OFF ; Get offset to DP #0
	 mov	 cx,es:[bx+(size CDADP_STR)] ; Get data pointer count
POSINIT_NEXT_DP:
	 mov	 dx,es:[bx].CDADP_VEC.EHI ; Get high-order word
	 mov	 ax,es:[bx].CDADP_VEC.ELO ; ... low-

	 push	 cx		; Save for a moment

	 mov	 cx,4		; Loop counter
	 clc			; Set CF=0
@@:
	 rcr	 dx,1		; Rotate in CF from AX low, out CF
	 rcr	 ax,1		; Shift low-order bit into CF
	 loop	 @B		; Jump if more bits

	 mov	 es:[bx].CDADP_VEC.VSEG,ax ; Save as segment
	 mov	 cl,4		; Rotate amount
	 rol	 dx,cl		; Rotate high-order nibble (original low-order)
	 mov	 es:[bx].CDADP_VEC.VOFF,dx ; Save as offset

	 pop	 cx		; Restore

	 sub	 bx,size CDADP_STR ; Back off to next DP structure

	 loop	 POSINIT_NEXT_DP ; Jump if more data pointers to normalize

	 mov	 ax,0		; Done

	 jmp	 INIT_END	; Join common exit code

ERR_RET:			; Done but error
	 mov	 ax,-1		; Mark as error return

	 jmp	 INIT_END	; Join common exit code

INIT_POS_LID:
	 mov	 ax,LOGICAL_ID	; Get its logical ID
	 mov	 POS_BLK.RB_LID,ax ; ...and save it for later use
	 mov	 ax,es:[di].INIT_RB_LEN ; Get request block length
	 mov	 POS_BLK.RB_LEN,ax ; ...and save it for later use

	 jmp	 short INIT_LID ; Join common code

INIT_NVRAM_LID:
	 mov	 ax,LOGICAL_ID	; Get its logical ID
	 mov	 NVRAM_LID,ax	; ...and save it for later use
	 mov	 ax,es:[di].INIT_RB_LEN ; Get request block length
	 mov	 NVRAM_RB_LEN,ax ; ...and save it for later use

; Allocate memory for Device Block

INIT_INT_LID:
INIT_LID:
	 mov	 ax,size CDALID_STR ; Size of a CDA element
	 mul	 LOGICAL_ID	; Times current logical ID to get
				; ...correct offset
	 mov	 si,ax		; Copy to index register

	 mov	 bx,es:[di].DEV_BLK_LEN ; Size of Device Block in bytes
	 add	 bx,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
	 DOSCALL @GETMEM	; Allocate memory for Device Block
	 jb	 short ERR_RET	; Jump if something went wrong

; Because of a bug in the Phoenix MCA BIOS, we must ensure that the
; low-order byte of the segment of the Device Block is non-zero

	 xor	 dx,dx		; Set AX:DX to segment

	 cmp	 al,0		; Izit non-zero?
	 jne	 short @F	; Jump if so

	 dec	 ax		; Back off by one para
	 add	 dx,16		; ...and forward by 16 bytes
@@:

; Save segment of Device Block in System Initialization Table

	 mov	 es,CDA_SEG	; Get CDA segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[si].CDALID_DBVEC.VOFF,dx ; Save offset
	 mov	 es:[si].CDALID_DBVEC.VSEG,ax ; ...  segment

; Allocate memory for Function Transfer Table

	 mov	 es,SYSINIT_SEG ; Get segment of system initialization table
	 assume  es:nothing	; Tell the assembler about it

	 mov	 bx,es:[di].FTT_LEN ; Get size of Function Transfer Table
	 add	 bx,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
	 DOSCALL @GETMEM	; Allocate memory for Function Transfer Table
	 jb	 short ERR_RET	; Jump if something went wrong

; Because of a bug in the Phoenix MCA BIOS, we must ensure that the
; low-order byte of the segment of the Function Transfer Table is non-zero

	 xor	 dx,dx		; Set AX:DX to segment

	 cmp	 al,0		; Izit non-zero?
	 jne	 short @F	; Jump if so

	 dec	 ax		; Back off by one para
	 add	 dx,16		; ...and forward by 16 bytes
@@:

; Save segment of FTT in System Initialization Table

	 mov	 es,CDA_SEG	; Get CDA segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[si].CDALID_FTTVEC.VOFF,dx ; Save offset
	 mov	 es:[si].CDALID_FTTVEC.VSEG,ax ; ...  segment

; Call ABIOS to initialize pointers

	 mov	 es,SYSINIT_SEG ; Get segment of system initialization table
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,1		; # logical IDs to initialize
;;;????? mov	 cx,es:[di].NUM_LOG_IDS ; Get # logical IDs in this device
	 mov	 dx,LOGICAL_ID	; Logical ID # to initialize

	 push	 ds		; Save for a moment
	 mov	 ds,CDA_SEG	;  DS -> Common Data Area
	 assume  ds:nothing	; Tell the assembler about it

	 call	 es:[di].INIT_PTR ; Initialize 'em
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 BUMP_ID	; Go around again

; De-allocate memory for Initialization table ???

INIT_END:
	 mov	 es,SYSINIT_SEG ; Get segment of system initialization table
	 assume  es:nothing	; Tell the assembler about it

	 push	 ax		; Save for a moment
	 DOSCALL @RELMEM	; Release it
	 pop	 ax		; Restore

	 REGREST <es,di,si>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

POS_INIT	 endp			; End POS_INIT procedure

;***************************************************************************

	 NPPROC  POSREAD -- Process the POS READ code in the ABIOS
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

COMMENT |

'C' callable routine to read the POS (programable option select) data

posread (slot#, cmos_vals, adapt_vals, adapt_id);

Note: This routine is taken from MAXIMIZE

|

POS_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's return IP
SLOTNO	 db	 ?,?		; Slot #
CMOS_VALS dd	 ?		; Ptr to CMOS values
ADAP_VALS dd	 ?		; Ptr to adapter values
ADAP_ID   dd	 ?		; Ptr to adapter ID

POS_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <si,di,es>	; Save registers

	 mov	 al,[bp].SLOTNO ; Get slot # of the adapter
	 mov	 POS_BLK.POS_SLOT_NO,al ; Save in request block

	 mov	 POS_BLK.RB_RETCODE,0FFFFh ; Set default error code
	 mov	 POS_BLK.RB_FUNC,0Dh ; Function - read adapter POS
				; and write it to I/O ports 100h to 105h

	 mov	 POS_BLK.RB_UNIT,0 ; Must be zero at startup
	 mov	 POS_BLK.RB_RES1,0 ; ...
	 mov	 POS_BLK.RB_RES2,0 ; ...

	 mov	 POS_BLK.POS_RES1,0 ; Must be zero at startup ??? WHY ???
	 mov	 POS_BLK.POS_RES2,0 ; ...
	 mov	 POS_BLK.POS_RES3,0 ; ...
	 mov	 POS_BLK.POS_RES4,0 ; ...

	 mov	 ax,[bp].ADAP_VALS.VOFF ; Get offset of ADAP_VALS
	 mov	 POS_BLK.POS_VEC.VOFF,ax ; Save in request block
	 mov	 ax,[bp].ADAP_VALS.VSEG ; Get segment of ADAP_VALS
	 mov	 POS_BLK.POS_VEC.VSEG,ax ; Save in request block

	 mov	 POS_BLK.POS_ADAPT_ID,-1 ; Zap the adapter ID

SYSPLACE_STR struc

SYSPLACE_DB_VEC dd ?		; Device Block pointer
SYSPLACE_FTT_VEC dd ?		; Function Transfer Table pointer

SYSPLACE_STR ends


SYSCALL_STR struc

	 db	 (size SYSPLACE_STR) dup (?)
	 dd	 ?		; Request block pointer
	 dw	 ?		; Common Data Area segment

SYSCALL_STR ends

	 push	 CDA_SEG	; CDA segment
	 push	 ds		; Request block segment
	 lea	 ax,POS_BLK	; ...		offset
	 push	 ax		; Pass to SYSPARM routine
	 sub	 sp,size SYSPLACE_STR ; Make room for place holders
	 call	 SYSPARM.STARTPTR ; Request ABIOS service
	 add	 sp,size SYSCALL_STR ; Pop our own calling args

	 mov	 ax,POS_BLK.RB_RETCODE ; Check for error conditions

	 cmp	 ax,0C005h	; Check for slot # out of bounds
	 je	 short POSREAD_SAVEID ; Jump if so

	 cmp	 ax,0		; Izit in error?
	 jne	 short POSREAD_EXIT ; Jump if so

	 cmp	 POS_BLK.POS_ADAPT_ID,-1 ; Check adapter id
	 je	 short POSREAD_SAVEID ; Jump if not valid

	 mov	 POS_BLK.RB_RETCODE,0FFFFh ; Set default error code
	 mov	 POS_BLK.RB_FUNC,0Bh ; Function - Read 6 bytes from CMOS
				; into I/O ports 100h to 105h and
				; into adapter ID and Data Buffer

	 mov	 POS_BLK.RB_UNIT,0 ; Must be zero at startup
	 mov	 POS_BLK.RB_RES1,0 ; ...
	 mov	 POS_BLK.RB_RES2,0 ; ...

	 mov	 POS_BLK.POS_RES1,0 ; Must be zero at startup ??? WHY ???
	 mov	 POS_BLK.POS_RES2,0 ; ...
	 mov	 POS_BLK.POS_RES3,0 ; ...
	 mov	 POS_BLK.POS_RES4,0 ; ...

	 mov	 ax,[bp].CMOS_VALS.VOFF ; Get offset of CMOS_VALS
	 mov	 POS_BLK.POS_VEC.VOFF,ax ; Save in request block
	 mov	 ax,[bp].CMOS_VALS.VSEG ; Get segment of CMOS_VALS
	 mov	 POS_BLK.POS_VEC.VSEG,ax ; Save in request block

	 push	 CDA_SEG	; CDA segment
	 push	 ds		; Request block segment
	 lea	 ax,POS_BLK	; ...		offset
	 push	 ax		; Pass to SYSPARM routine
	 sub	 sp,size SYSPLACE_STR ; Make room for place holders
	 call	 SYSPARM.STARTPTR ; Request ABIOS service
	 add	 sp,size SYSCALL_STR ; Pop our own calling args
POSREAD_SAVEID:
	 les	 di,[bp].ADAP_ID ; ES:DI ==> adapter id
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,POS_BLK.POS_ADAPT_ID ; Get adapter id
	 mov	 es:[di],ax	; Return it to the caller

	 mov	 ax,POS_BLK.RB_RETCODE ; Return error code as result
POSREAD_EXIT:
	 REGREST <es,di,si>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 4+4+4+2	; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

POSREAD  endp			; End POSREAD procedure

;***************************************************************************

	 NPPROC  NVRAM -- Process the NVRAM code in the ABIOS
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

'C' callable routine to recompute the NVRAM (Non-Volatile RAM) checksum

nvramcheck ()

Note: This routine is taken from MAXIMIZE

|

	 REGSAVE <si,di,es>	; Save registers

; Because of a bug in the Phoenix MCA BIOS, we have to setup NVRAM_BLK
; differently than we would like to.  In particular, they test a location
; in the start of the segment of the request block (instead of NVRAM_FLAG)
; for whether or not the recomputation should be on the 64-byte RAM or
; the extended RAM.  To compensate for this, we allocate a new segment
; for NVRAM_BLK, setup the NVRAM_FLAG in the appropriate place, fill in
; NVRAM_BLK, and then call ABIOS.

; The word that the faulty Phoenix MCA BIOS tests is at DS:0052 if NMI
; is to be enabled upon exit, DS:00B2 otherwise (we always enable it).
; As that location is above the size of RB_NVRAM_STR, we just allocate
; room for 0052+2 bytes.

	 mov	 bx,52h+2	; Calculate # bytes to allocate
	 add	 bx,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
	 DOSCALL @GETMEM	; Allocate memory for Function Transfer Table
	 jb	 short NVRAMCHECK_EXIT ; Jump if something went wrong
				; ...with return code in AX

	 mov	 es,ax		; Address the new segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,NVRAM_LID	; Get NVRAM's logical ID
	 mov	 es:[0].RB_LID,ax ; Save in request block

	 mov	 ax,NVRAM_RB_LEN ; Get NVRAM's request block length
	 mov	 es:[0].RB_LEN,ax ; Save in request block

;;;;;;;; mov	 es:[0].RB_RETCODE,-1 ; Set default error code
;;;;;;;; mov	 es:[0].RB_FUNC,0Bh ; Function - Recompute checksum
;;;;;;;;
;;;;;;;; mov	 ax,0		; Flag:  NMI enabled on exit,
;;;;;;;;			;	 RAM type = 64-byte
;;;;;;;; mov	 es:[0].NVRAM_FLAG,ax
;;;;;;;; mov	 es:[52h],ax	; Save in pseudo-location
;;;;;;;;
;;;;;;;; mov	 es:[0].RB_UNIT,0 ; Must be zero at startup
;;;;;;;; mov	 es:[0].RB_RES1,0 ; ...
;;;;;;;; mov	 es:[0].RB_RES2,0 ; ...
;;;;;;;;
;;;;;;;; mov	 es:[0].NVRAM_RES1,0 ; ... ??? WHY ???
;;;;;;;; mov	 es:[0].NVRAM_RES2,0 ; ...
;;;;;;;; mov	 es:[0].NVRAM_RES3,0 ; ...
;;;;;;;; mov	 es:[0].NVRAM_RES4,0 ; ...
;;;;;;;;
;;;;;;;; push	 CDA_SEG	; CDA segment
;;;;;;;; push	 es		; Request block segment
;;;;;;;; xor	 ax,ax		; ...		offset
;;;;;;;; push	 ax		; Pass to SYSPARM routine
;;;;;;;; sub	 sp,size SYSPLACE_STR ; Make room for place holders
;;;;;;;; call	 SYSPARM.STARTPTR ; Request ABIOS service
;;;;;;;; add	 sp,size SYSCALL_STR ; Pop our own calling args
;;;;;;;;
;;;;;;;; mov	 ax,es:[0].RB_RETCODE ; Return error code as result
;;;;;;;;
;;;;;;;; cmp	 ax,0		; Izit OK?
;;;;;;;; jne	 short NVRAMCHECK_RLS ; Jump if not
;;;;;;;;
	 mov	 es:[0].RB_RETCODE,-1 ; Set default error code
	 mov	 es:[0].RB_FUNC,0Bh ; Function - Recompute checksum

	 mov	 ax,@NVRAM_FLAG_EXT ; Flag:  NMI enabled on exit,
				;	     RAM type = extended
	 mov	 es:[0].NVRAM_FLAG,ax
	 mov	 es:[52h],ax	; Save in pseudo-location

	 mov	 es:[0].RB_UNIT,0 ; Must be zero at startup
	 mov	 es:[0].RB_RES1,0 ; ...
	 mov	 es:[0].RB_RES2,0 ; ...

	 mov	 es:[0].NVRAM_RES1,0 ; ... ??? WHY ???
	 mov	 es:[0].NVRAM_RES2,0 ; ...
	 mov	 es:[0].NVRAM_RES3,0 ; ...
	 mov	 es:[0].NVRAM_RES4,0 ; ...

	 push	 CDA_SEG	; CDA segment
	 push	 es		; Request block segment
	 xor	 ax,ax		; ...		offset
	 push	 ax		; Pass to SYSPARM routine
	 sub	 sp,size SYSPLACE_STR ; Make room for place holders
	 call	 SYSPARM.STARTPTR ; Request ABIOS service
	 add	 sp,size SYSCALL_STR ; Pop our own calling args

	 mov	 ax,es:[0].RB_RETCODE ; Return error code as result
NVRAMCHECK_RLS:
	 push	 ax		; Save for a moment
	 DOSCALL @RELMEM	; Release it
	 pop	 ax		; Restore
NVRAMCHECK_EXIT:
	 REGREST <es,di,si>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NVRAM	 endp			; End NVRAM procedure

;***************************************************************************

	NPPROC	CHECK_PnP -- Check PnP Routines
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process all PnP functions

Note: PnP needs a 1KB stack for itself

|

	REGSAVE <eax,ebx,gs>	; Save registers

	test	LCL_FLAG,@LCL_PnP ; Izit present?
	jz	near ptr CHECK_PnP_EXIT ; Jump if not

	mov	gs,PnP_SEG	; Address the PnP segment
	assume	gs:PnPGRP	; Tell the assembler about it

	mov	ax,PnPGRP:[0].PnP_RMDS ; Get the RM data segment

	cmp	PnPGRP:[0].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F	; Jump if so

	xor	ax,ax		; No RMDS in old struc
@@:
	mov	LCL_PnP_RMDS,ax ; Save for later use

	mov	eax,PnPGRP:[0].PnP_RMVEC ; Get the RM entry point

	cmp	PnPGRP:[0].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F	; Jump if so

	mov	eax,PnPGRP:[0].PnP2_RMVEC ; Get the RM entry point
@@:
	mov	LCL_PnP_RMVEC,eax ; Save for later use

; Test function 00h -- Get Number of Nodes

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of PnP_NodeSize
	push	offset cs:PnP_NodeSize ; ...  offset  ...
	push	cs		; ...  segment of PnP_NumNodes
	push	offset cs:PnP_NumNodes ; ...  offset  ...
	push	@PnP_GET_NUM_NODES ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+4+2	; Strip back the stack

; Test functions 01h & 02h -- Get/Set System Device Nodes

	mov	PnP_CTL,01b	; Current configuration
	call	CHECK_PnP12	; Handle via subroutine

	mov	PnP_CTL,10b	; Next boot configuration
	call	CHECK_PnP12	; Handle via subroutine

; Some PnP BIOSes don't support functions 03h-05h, so we test for
; event notification to see whether or not we should exercise them.

	mov	ax,PnPGRP:[0].PnP_FLAG ; Get flag word
	and	ax,mask $PnPFLAG_ENM ; Isolate the Event Notification Mode

	cmp	ax,@PnPFLAG_ENM_NS shl $PnPFLAG_ENM ; Izit not supported?
	je	short CHECK_PnP_XEN ; Jump if so

; Test function 03h -- Get Event

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of PnP_Message
	push	offset cs:PnP_Message ; ...  offset  ...
	push	@PnP_GET_EVENT	; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

; Test function 04h -- Send Message

	mov	PnP_Message,@PnP_MSG_OK ; Pick a harmless message

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	PnP_Message	; ...  PnP_Message value
	push	@PnP_SEND_MSG	; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+2+2	; Strip back the stack

; Test function 05h -- Get Docking Station Info

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of @ZTAIL
	push	@ZTAIL		; ...  offset  ...
	push	@PnP_GET_DOCK_INFO ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack
CHECK_PnP_XEN:

; Functions 06h, 07h, and 08h are reserved

; Test function 0Ah -- Get Statically Allocated resources

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of @ZTAIL
	push	@ZTAIL		; ...  offset  ...
	push	@PnP_GET_STATIC_RES ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

; Test function 09h -- Set Statically Allocated resources
; Skipped because it might be destructive

; Test function 40h -- Get ISA Configuration Structure

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of @ZTAIL
	push	@ZTAIL		; ...  offset  ...
	push	@PnP_GET_ISA_CFG ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

; Test function 41h -- Get ESCD Info

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of PnP_NVStorageBase
	push	offset cs:PnP_NVStorageBase ; ...  offset  ...
	push	cs		; ...  segment of PnP_ESCDSize
	push	offset cs:PnP_ESCDSize ; ...  offset  ...
	push	cs		; ...  segment of PnP_MinESCDSize
	push	offset cs:PnP_MinESCDSize ; ...  offset  ...
	push	@PnP_GET_ESCD_INFO ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+4+4+2	; Strip back the stack

; Test function 42h -- Read ESCD data

	mov	ebx,PnP_NVStorageBase ; Get NV storage base (<1MB & /16)
	shr	ebx,4-0 	; Convert from bytes to paras

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	bx		; ...  segment of PnP_NVStorageBase
	push	cs		; ...  segment of @ZTAIL
	push	@ZTAIL		; ...  offset  ...
	push	@PnP_GET_ESCD	; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+2+2	; Strip back the stack
;;;;;;;
;;;;;;; cmp	ax,@PnP_SUCCESS ; Did it work?
;;;;;;; jne	short @F	; Jump if not
;;;;;;;
; Test function 43h -- Write ESCD data
; Skip this as it crashes on AMI BIOS 4/15/94
;;;;;;;
;;;;;;; push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
;;;;;;; push	bx		; ...  segment of PnP_NVStorageBase
;;;;;;; push	cs		; ...  segment of @ZTAIL
;;;;;;; push	@ZTAIL		; ...  offset  ...
;;;;;;; push	@PnP_SET_ESCD	; Pass function #
;;;;;;; call	LCL_PnP_RMVEC	; Request PnP service
;;;;;;; 			; Return status in AX
;;;;;;; add	sp,2+4+2+2	; Strip back the stack
;;;;;;;@@:

; Test function 0Bh -- Get APM ID Table

	mov	PnP_APMSize,0	; Set to zero to get actual size

; The first call with a buffer size of zero asks the BIOS
; to fill in the needed size

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of @ZTAIL
	push	@ZTAIL		; ...  offset  ...
	push	cs		; ...  segment of PnP_APMSize
	push	offset cs:PnP_APMSize ; ...  offset  ...
	push	@PnP_GET_APM_ID_TAB ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+4+2	; Strip back the stack

	cmp	ax,@PnP_SUCCESS ; Dis it work?
	jne	short @F	; Jump if not

; The second call gets the entire table

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of @ZTAIL
	push	@ZTAIL		; ...  offset  ...
	push	cs		; ...  segment of PnP_APMSize
	push	offset cs:PnP_APMSize ; ...  offset  ...
	push	@PnP_GET_APM_ID_TAB ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+4+2	; Strip back the stack
@@:

; Test function 60h -- Get Version and Installation Check

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of PnP_Version
	push	offset cs:PnP_Version ; ...  offset  ...
	push	@PnP_GET_VERSION ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	near ptr CHECK_PnP_XBBS ; Jump if not supported

; Test function 61h -- Get Device Count, IPL-relative

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of PnP_StrSize
	push	offset cs:PnP_IPLStrSize ; ...	offset	...
	push	cs		; ...  segment of PnP_MaxCnt
	push	offset cs:PnP_IPLMaxCnt ; ...  offset  ...
	push	cs		; ...  segment of PnP_DevCnt
	push	offset cs:PnP_IPLDevCnt ; ...  offset  ...
	push	@PnP_BBS_IPL	; IPL-relative
	push	@PnP_GET_DEV_CNT ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+4+4+2	; Strip back the stack

; Test function 61h -- Get Device Count, BCV-relative

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of PnP_StrSize
	push	offset cs:PnP_BCVStrSize ; ...	offset	...
	push	cs		; ...  segment of PnP_MaxCnt
	push	offset cs:PnP_BCVMaxCnt ; ...  offset  ...
	push	cs		; ...  segment of PnP_DevCnt
	push	offset cs:PnP_BCVDevCnt ; ...  offset  ...
	push	@PnP_BBS_BCV	; BCV-relative
	push	@PnP_GET_DEV_CNT ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+4+4+2	; Strip back the stack

; Test function 62h -- Get Priority and Table, IPL-relative

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of ZTAIL
	mov	ax,@ZTAIL	; Get  offset  of ZTAIL
	add	ax,PnP_IPLMaxCnt ; Skip over boot priority table
	push	ax		; Pass ...
	push	cs		; ...  segment of ZTAIL
	push	@ZTAIL		; Pass offset ...
	push	@PnP_BBS_IPL	; IPL-relative
	push	@PnP_GET_PRIORITY ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+4+2	; Strip back the stack

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	short @F	; Jump if not

; Test function 63h -- Set Priority, IPL-relative

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of ZTAIL
	push	@ZTAIL		; Pass offset
	push	@PnP_BBS_IPL	; IPL-relative
	push	@PnP_SET_PRIORITY ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+2	; Strip back the stack
@@:

; Test function 62h -- Get Priority and Table, BCV-relative

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of ZTAIL
	mov	ax,@ZTAIL	; Get  offset  of ZTAIL
	add	ax,PnP_BCVMaxCnt ; Skip over boot priority table
	push	ax		; Pass ...
	push	cs		; ...  segment of ZTAIL
	push	@ZTAIL		; Pass offset
	push	@PnP_BBS_BCV	; BCV-relative
	push	@PnP_GET_PRIORITY ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+4+2	; Strip back the stack

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	short @F	; Jump if not

; Test function 63h -- Set Priority, IPL-relative

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of ZTAIL
	push	@ZTAIL		; Pass offset
	push	@PnP_BBS_BCV	; BCV-relative
	push	@PnP_SET_PRIORITY ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+2	; Strip back the stack
@@:

; Test function 64h -- Get IPL Device from Last Boot

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of PnP_IPLDevBoot
	push	offset cs:PnP_IPLDevBoot ; ...	offset	...
	push	@PnP_GET_IPLDEV ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+2	; Strip back the stack

; Test function 65h -- Get Boot First

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of PnP_Boot1st
	push	offset cs:PnP_Boot1st ; ...  offset  ...
	push	@PnP_GET_BOOT1ST ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	short @F	; Jump if not

	cmp	PnP_Boot1st,0FFh ; Izit invalid?
	je	short @F	; Jump if so

; Test function 66h -- Set Boot First

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	cs		; ...  segment of PnP_Boot1st
	push	offset cs:PnP_Boot1st ; ...  offset  ...
	push	@PnP_SET_BOOT1ST ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack
@@:







CHECK_PnP_XBBS:















CHECK_PnP_EXIT:
	REGREST <gs,ebx,eax>	; Restore
	assume	gs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PnP endp			; End CHECK_PnP procedure

;***************************************************************************

	NPPROC	CHECK_PnP12 -- Test PnP Functions 1 and 2
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:PnPGRP,ss:nothing
COMMENT|

Check PnP functions 1 and 2.

On entry:

PnP_CTL has been initialized

|

	REGSAVE <eax,bx>	; Save registers

	mov	PnP_Node,0	; Initialize with starting node
CHECK_PnP12_NEXT:

; Note that the call to @PnP_GET_DEV_NODE increments the value of PnP_Node
; thus we save the current value in BL to pass to the @PnP_SET_DEV_NODE call.

	mov	bx,PnP_Node	; Get the current node #

	cmp	bx,0FFh 	; Izit end of the line?
	je	near ptr CHECK_PnP12_EXIT ; Jump if so

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	PnP_CTL 	; ...  control flags
	push	cs		; ...  segment of @ZTAIL
	push	@ZTAIL		; ...  offset  ...
	push	cs		; ...  segment of PnP_Node
	push	offset cs:PnP_Node ; ...  offset  ...
	push	@PnP_GET_DEV_NODE ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+4+4+2+2	; Strip back the stack

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	near ptr CHECK_PnP12_EXIT ; Jump if not

	test	ZTAIL.PnP_DEV_FLAG,@PnP_DEVFLAG_XCFG ; Izit not configurable?
	jnz	near ptr CHECK_PnP12_NEXT ; Jump if so

	push	LCL_PnP_RMDS	; Pass the R/W BIOS data selector
	push	PnP_CTL 	; ...  control flags
	push	cs		; ...  segment of @ZTAIL
	push	@ZTAIL		; ...  offset  ...
	push	bx		; ...  node # (only low-order 8 bits used)
	push	@PnP_SET_DEV_NODE ; Pass function #
	call	LCL_PnP_RMVEC	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+2+2	; Strip back the stack

;;;;;;; cmp	ax,@PnP_SUCCESS ; Did it work?
;;;;;;; je	short @F	; Jump if so
;;;;;;;
;;;;;;; int	03h		; Call our debugger
;;;;;;;@@:
	jmp	CHECK_PnP12_NEXT ; Go around again

CHECK_PnP12_EXIT:
	REGREST <bx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PnP12 endp		; End CHECK_PnP12 procedure

;***************************************************************************

	 NPPROC  CHECK_EISA -- Dummy Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Process all the EISA routines

There are four EISA functions:
00) Read slot configuration information
01) Read function configuration information
02) Clear Nonvolatile Memory
03) Write Nonvolatile Memory

Note: EISA needs a 2KB stack for itself

|

	 pusha			; Save all GP registers

	 test	 LCL_FLAG,@LCL_EISA ; Is this an EISA machine?
	 jz	 short EISA_EXIT ; Jump if not

	 test	 CMD_FLAG,@CMD_SKIPEISA ; Should we skip this test?
	 jnz	 short EISA_EXIT ; Jump if so

; Display a little debugging message

	 mov	 bx,@STAT_EISA	; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

; Read slot configuration information

	 xor	 cx,cx		; Slot 0
	 mov	 ax,ReadEISASlotInfo ; Get Slot Information

	 int	 15h		; Request BIOS service
				; N.B. An AST machine trashes CX

; Read function configuration information

	 xor	 cx,cx		; Function 0 (CH), Slot 0 (CL)
	 lea	 si,EISA_BUFFER ; DS:SI==> slot buffer
	 mov	 ax,ReadEISAFuncInfo ; Get Function Information

	 int	 15h		; Request BIOS service
				; N.B. An AST machine trashes CX

EISA_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EISA	 endp			; End CHECK_EISA procedure

;***************************************************************************

	 NPPROC  PCIFNS -- Check list of PCI functions
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Process a list of PCI local bus BIOS support functions.

On entry:
PGROUP:SI ==>	word list of functions
CX	 =	number of entries in list

On exit:
CF=1		function 0 (install check) failed
CF=0		install check succeeded
All EGP registers except EBP, ESP may be trashed.

|

	 cld			; Set forward direction
	 lods	 PGROUP:[si].ELO ; Get function 0

	 REGSAVE <cx,si>	; Save

	 stc			; Assume failure
	 PCICALL		; Return AH=0, CF=0, EDX='PCI ' if success

	 REGREST <si,cx>	; Restore
	 jc	 short PCIFNS_ERR ; Jump if we failed

	 or	 ah,ah		; Check for status=0 (OK)
	 jnz	 short PCIFNS_ERR ; Jump if not

	 cmp	 edx,@PCISIG	; Izit the 'PCI ' signature?
	 jne	 short PCIFNS_ERR ; Jump if not

	 jmp	 short PCIFNS_LOOP ; Join common code

PCIFNS_NEXT:
	 cld			; Set forward direction
	 lods	 PGROUP:[si].ELO ; Get function 0

	 REGSAVE <cx,si>	; Save

	 mov	 bx,PCIDFB	; Device, function, and bus numbers
	 mov	 ecx,PCIDEVCLASS ; Device or class
	 mov	 si,PCIDEVIND	; Device index if multiple devices
	 mov	 di,PCICFGREG	; Config register to read

	 PCICALL		; Ignore return status

	 REGREST <si,cx>	; Restore

PCIFNS_LOOP:
	 loop	 PCIFNS_NEXT	; Go around again

	 clc			; Indicate success

	 jmp	 short PCIFNS_EXIT ; Join common exit

PCIFNS_ERR:
	 stc			; Indicate failure

PCIFNS_EXIT:

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PCIFNS	 endp			; End PCIFNS procedure

;***************************************************************************

	 NPPROC  CHECK_PCI -- Check PCI local bus routines
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Process all the PCI local bus BIOS support routines

PCI local bus functions exist in vanilla and 32-bit versions.
We'll test all but the write config data and special cycle functions.

Note: PCI support needs a 1KB stack for itself

|

	 pushad 		; Save all EGP registers

	 test	 CMD_FLAG,@CMD_SKIPPCI ; Should we skip this test?
	 jnz	 short PCI_EXIT ; Jump if so

; Display a little debugging message

	 mov	 bx,@STAT_PCI	; Debugging message number
	 call	 DEBUG_MISC	; Spit out debugging string

	 lea	 si,PCIFN_TAB	; Address function table
	 mov	 cx,@PCIFN_CNT	; Number of functions
	 call	 PCIFNS 	; Process functions
				; Return with CF significant
PCI_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PCI endp			; End CHECK_PCI procedure

;***************************************************************************

	 NPPROC  LOCAL_INT15 -- Local interrupt 15h ahndler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Local interrupt 15 (function 4F) handler
Used by CHECK_ALTKEYS to simulate a particular keystroke

|

	 cmp	 ah,4Fh 	; Is it the keyboard intercept request?
	 je	 short LCL_I15_KEYTRAP ; Jump if so

	 jmp	 OLDINT15_VEC	; Chain to next handler

LCL_I15_KEYTRAP:

COMMENT |

On entry:
AH	=	4Fh (this function call number)
AL	=	Scan code

On exit:
CF	=	Set : Use scan code returned in AL
CF	=	Clear : Ignore scan code

|

LCL_I15_STR struc

	 dw	 ?		; Caller's BP
	 dd	 ?		; Caller's return CS:IP
I15_FL	 dw	 ?		; Caller's return flags

LCL_I15_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 push	 bx		; Save register

	 mov	 bx,SCAN_PTR	; Get pointer to scan code table
	 mov	 al,PGROUP:[bx] ; Get new scan code

	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 inc	 SCAN_PTR	; Point to next scan code
	 assume  ds:nothing	; Retract nose

	 pop	 bx		; Restore

	 or	 [bp].I15_FL,(mask $CF) ; Set CF for caller's return flags

	 pop	 bp		; Restore

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOCAL_INT15	 endp			; End LOCAL_INT15 procedure

;***************************************************************************

	 NPPROC  DRAIN_KB_BUFFER -- Drain the keyboard buffer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Drain the keyboard buffer

|

	 REGSAVE <ax>		; Save register

DRAIN_KB_BUFFER_NEXT:
	 mov	 ah,01h 	; Read keyboard status function
	 int	 016h		; Keyboard Services

	 jz	 short DRAIN_KB_BUFFER_EXIT ; Jump if no more keys waiting

	 xor	 ah,ah		; Read keyboard character function
	 int	 016h		; Read keyboard into AX

	 jmp	 short DRAIN_KB_BUFFER_NEXT ; Get next keystroke

DRAIN_KB_BUFFER_EXIT:
	 REGREST <ax>		; Restore register

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAIN_KB_BUFFER  endp			; End DRAIN_KB_BUFFER procedure

;***************************************************************************

	 NPPROC  FDUMMY -- Dummy Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |


|

	 REGSAVE <>		; Save registers


	 REGREST <>		; Restore Registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDUMMY	 endp			; End FDUMMY procedure

;***************************************************************************

CODE	 ends			; End CODE segment

	 MEND			; End FUNCS module




;' $Header:   P:/PVCS/MAX/QMT/MEM_HELP.ASV   1.0   05 Sep 1995 16:55:36   HENRY  $
	title	MEM_HELP -- MEMCHK Help Screens
	page	58,122
	name	MEM_HELP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include ALLMEM.INC
	 include KEYCODE.INC
	 include ASCII.INC
	 include CPUFLAGS.INC
	 include DOSCALL.INC
	 include VIDCALL.INC
	 include KEYCALL.INC

	 include MEM_SCRN.INC
	include MEM_SEGS.INC

	 include MEM_OEM.INC
.list

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 GL2_FLAG:word
	 include MEM_GL2.INC

	 extrn	 GL3_FLAG:word
	 include MEM_GL3.INC

	 extrn	 TIMETAB:tbyte
	 include MEM_TIME.INC

	 extrn	 HLPATTR:byte
	 extrn	 HLPAATTR:byte
	 extrn	 HLPBATTR:byte
	 extrn	 HKEYATTR:byte
	 extrn	 HERRATTR:byte
	 extrn	 HTTLATTR:byte

	 extrn	 DLGBATTR:byte
	 extrn	 DLGBTNATTR:byte
	 extrn	 DLGABTNATTR:byte
	 extrn	 DLGBHKATTR:byte
	 extrn	 DLGABHKATTR:byte
	 extrn	 DLGRBHKATTR:byte
	 extrn	 DLGTHKATTR:byte
	 extrn	 DLGEHATTR:byte
	 extrn	 DLGENATTR:byte
	 extrn	 DLGEFATTR:byte
	 extrn	 DISATTR:byte

	 extrn	 HELP_NAV:byte
	 extrn	 HELP_OVR:byte
	 extrn	 HELP_TST:byte
	 extrn	 HELP_ERR:byte
	 extrn	 HELP_CMD:byte
	 extrn	 HELP_MEM:byte
	 extrn	 HELP_NMI:byte
	 extrn	 HELP_NMIX:byte

	 extrn	 ARR_W_HTOP:tbyte

	 extrn	 PHTOPTTL:word

	 extrn	 LAST_PTST:word
	 extrn	 MSG_PTSTERR:byte

	 extrn	 MSG_HKEY:byte
	 extrn	 MSG_HKEYERR:byte

	 extrn	 W_HKEY:tbyte
	 extrn	 W_HKEYF2:tbyte
	 extrn	 W_HKEYERR:tbyte

	 extrn	 MSG_HELP:byte
	 extrn	 MSG_HELEV:byte
	 extrn	 W_HELP:tbyte
	 extrn	 W_HASK:tbyte
	 extrn	 W_HLIN:tbyte
	 extrn	 W_HSCR:tbyte
	 extrn	 W_HTTL:tbyte
	 extrn	 W_HELEV:tbyte
	 extrn	 W_HEBOX:tbyte

	 extrn	 HLIN_SROW:word
	 extrn	 @HLIN_LEN:abs
	 extrn	 @HTXT_NROW:abs
	 extrn	 @HTXT_NCOL:abs
	 extrn	 @HELEV_SROW:abs
	 extrn	 @HELEV_NROW:abs

	 extrn	 VIDBASE_FVEC:fword

	 extrn	 SEL_4GB:word
	 extrn	 TIMECNT:word

	 public  HLPIND
HLPIND	 dw	 0		; Index into help screen

	 public  HTOPIND,@HLPIND_MEM,@HLPIND_NMI,@HLPIND_NMIX
HTOPIND  dw	 ?		; Row index into HELP_NAV
	 dw	 ?		; ...		     _OVR
	 dw	 ?		; ...		     _TST
	 dw	 ?		; ...		     _ERR
	 dw	 ?		; ...		     _CMD
@HLPIND_MEM equ  ($-HTOPIND)/(type HTOPIND)
	 dw	 ?		; ...		     _MEM - Pseudo-entry for memory errors
@HLPIND_NMI equ  ($-HTOPIND)/(type HTOPIND)
	 dw	 ?		; ...		     _NMI - ... 	     NMI ...
@HLPIND_NMIX equ ($-HTOPIND)/(type HTOPIND)
	 dw	 ?		; ...		     _NMIX- ... 	     NMI ...
@HTOPIND equ	 ($-HTOPIND)/(type HTOPIND) ; # help topics

	 public  HLPTOPIC
HLPTOPIC dw	 DGROUP:HELP_NAV
	 dw	 DGROUP:HELP_OVR
	 dw	 DGROUP:HELP_TST
	 dw	 DGROUP:HELP_ERR
	 dw	 DGROUP:HELP_CMD
	 dw	 DGROUP:HELP_MEM ; Pseudo-entry for memory errors
	 dw	 DGROUP:HELP_NMI ; ...		    NMI ...
	 dw	 DGROUP:HELP_NMIX; ...		    NMIX ...

	 public  PMSG_HKEY,PW_HKEY
PMSG_HKEY dw	 DGROUP:MSG_HKEY	; Ptr to help key message
PW_HKEY  dw	 DGROUP:W_HKEY		; ...		  window descriptor

;----------------------- Dialog definitions ---------------------
; Dialog box object types (these need to match DLG_DISP call table)
@DLG_TEXT equ	 1		; One-line text
;;;;_MTEXT equ	 2		; Multi-line text
@DLG_EDIT equ	 3		; Single line edit text
;;;;_BOX equ	 4		; Frame box (for grouping)
@DLG_BTN equ	 5		; Window button
@DLG_RADIO equ	 6		; Radio button
;;;;_CHECK equ	 7		; Check box

; Window box line types (bits 0-1)
@WBOX_NONE equ	 0000h		; No line border
@WBOX_SGL equ	 0001h		; Single line border
@WBOX_DBL equ	 0002h		; Double line border

; Window shading types (bits 2-3)
@WSHD_NONE equ	 0000h		; No shadowing
@WSHD_NORM equ	 0004h		; Normal shadowing
;;;;;_DBL equ	 0008h		; Double shadowing

; Button attributes
@BTN_DEFLT equ	 0001h		; Default button
@BTN_DIS equ	 0002h		; Disabled
@BTN_HID equ	 0004h		; Invisible
@BTN_SEL equ	 0008h		; Selected (radio buttons and check boxes only)
@BTN_WDEF equ	 0010h		; Window default button

; Edit field attributes
$ED_REC record $ED_HIGH:1,$ED_HID:1;
@ED_HIGH equ	 (mask $ED_HIGH) ; Selected area is highlighted
@ED_HID equ	 (mask $ED_HID) ; Text is hidden

; This corresponds to W_STR in MEM_SCRN.INC
WIN_STR struc			; Window descriptor
WIN_ROW  dw	 ?		; Starting row
WIN_COL  dw	 ?		; Starting column
WIN_NROWS dw	 ?		; Number of rows
WIN_NCOLS dw	 ?		; Number of columns
WIN_STR ends

TRIGGER_STR struc		; Hotkey triggers
TRIG_KEYS dw 4 dup (?)		; Int 16h codes; if no high byte, compare low
TRIGGER_STR ends

POINT_STR struc 		; Point descriptor
POINT_ROW dw	 ?		; Row
POINT_COL dw	 ?		; Column
POINT_STR ends

; Allows nesting of structures IF the substructure consists of words
NSTRUC macro strucname,substrucname
&strucname&_&substrucname dw ((size &substrucname&_STR) / 2) dup (?)
	 endm			; NSTRUC

DIALOG_STR struc		; Dialog box
DIALOG_WIN dw ((size WIN_STR)/2) dup (?) ; Placement relative to screen
DIALOG_FOCUS dw  ?		; Offset of object currently with focus
DIALOG_NOBJ dw	 ?		; Number of objects following
DIALOG_STR ends

DIALOG_OBJ equ [size DIALOG_STR] ; Offset of first object record

DLGOBJ_STR struc		; Dialog object
DLGOBJ_TYPE dw	 ?		; @DLG_TEXT, @DLG_EDIT, etc.
DLGOBJ_pOBJ dw	 ?		; Near pointer to object structure
DLGOBJ_STR ends

DTEXT_STR struc 		; Dialog single-line text object
DTEXT_POS dw ((size POINT_STR)/2) dup (?) ; Placement of text relative to dialog
DTEXT_pszTXT dw ?		; Near pointer to ASCIIZ text
DTEXT_HOFS dw	?		; Offset within string to highlight (-1=none)
DTEXT_STR ends

DLGCTXT  macro	 name,wid,row,highlight
	 public  TXT_&name
TXT_&name POINT_STR <row,(wid-@MSG_&name&LEN)/2> ; DTEXT_POS
	 dw	 DGROUP:MSG_&name ; DTEXT_pszTXT
ifb <highlight>
	 dw	 -1		; No highlighting
else
	 dw	 highlight	; Offset of character to highlight
endif
	 endm			; DLGCTXT

DLGTXT	 macro	 name,row,col,highlight
	 public  TXT_&name
TXT_&name POINT_STR <row,col>	; DTEXT_POS
	 dw	 DGROUP:MSG_&name ; DTEXT_pszTXT
ifb <highlight>
	 dw	 -1		; No highlighting
else
	 dw	 highlight	; Offset of character to highlight
endif
	 endm			; DLGTXT

DEDIT_STR struc 		; Dialog single-line edit object
DEDIT_WIN dw ((size WIN_STR) / 2) dup (?) ; Placement of edit box relative to
				; dialog
DEDIT_TRIG dw ((size TRIGGER_STR) / 2) dup (0) ; Triggers for set focus
DEDIT_pszTXT dw  ?		; Near pointer to ASCIIZ text
DEDIT_TXTLEN dw  ?		; Maximum size of edit buffer
DEDIT_FLAGS dw	 ?		; @ED_? above
DEDIT_START dw	 ?		; Starting offset of text within window
DEDIT_CURSOR dw  ?		; Current cursor offset
DEDIT_ANCHOR dw  ?		; Where we started dragging
DEDIT_STR ends

BTN_STR struc			; Dialog window button object
BTN_WIN dw ((size WIN_STR) / 2) dup (?) ; Placement relative to dialog box
BTN_TRIG dw ((size TRIGGER_STR) / 2) dup (0) ; Triggers for this button
BTN_FLAGS dw	 ?		; @BTN_? above
BTN_HOFS dw	 ?		; Highlight offset (hot key)
BTN_pszTXT dw	 ?		; Near pointer to button text
BTN_STR ends

RADIO_STR struc 		; Radio button group object
RADIO_WIN dw ((size WIN_STR) / 2) dup (?) ; Placement relative to dialog box
RADIO_TRIG dw ((size TRIGGER_STR) / 2) dup (0) ; Triggers for set focus
RADIO_WFLAGS dw  ?		; @WBOX_?, @WSHD_? above
RADIO_NBTNS dw	 ?		; Number of buttons to follow
RADIO_STR ends

RADIO_pBTN equ [size RADIO_STR] ; First button structure

RBTN_STR struc			; Radio button (component of radio btn group)
RBTN_POS dw ((size POINT_STR) / 2) dup (?) ; Position relative to dialog box
RBTN_TRIG dw ((size TRIGGER_STR) / 2) dup (0) ; Triggers for this button
RBTN_FLAGS dw	 ?		; @BTN_? above
;;;;_CHAR dw	 'ù'            ; Alt-249
RBTN_BOFS dw	 ?		; Offset of button dot
RBTN_HOFS dw	 ?		; Offset of highlight (hot key)
RBTN_pszTXT dw	 ?		; Near pointer to button text
RBTN_STR ends

	 public  DLG_DISP
DLG_DISP label word		; Jump table for dialog display code
	 dw	 PGROUP:DRAW_DNONE ; 0 -	not supported
	 dw	 PGROUP:DRAW_DTEXT ; 1 -	One-line text
	 dw	 PGROUP:DRAW_DNONE ; 2 -	not supported
	 dw	 PGROUP:DRAW_DEDIT ; 3 -	Single line edit text
	 dw	 PGROUP:DRAW_DNONE ; 4 -	not supported
	 dw	 PGROUP:DRAW_DBTN  ; 5 -	Window button
	 dw	 PGROUP:DRAW_DRADIO ; 6 -	Radio button
	 dw	 PGROUP:DRAW_DNONE ; 7 -	not supported

	 public  pfnFOCUS
pfnFOCUS label word		; Functions to process focused input
	 dw	 PGROUP:INP_FOCNONE ; 0 -	not supported
	 dw	 PGROUP:INP_FOCTEXT ; 1 -	One-line text
	 dw	 PGROUP:INP_FOCNONE ; 2 -	not supported
	 dw	 PGROUP:INP_FOCEDIT ; 3 -	Single line edit text
	 dw	 PGROUP:INP_FOCNONE ; 4 -	not supported
	 dw	 PGROUP:INP_FOCBTN  ; 5 -	Window button
	 dw	 PGROUP:INP_FOCRADIO ; 6 -	Radio button
	 dw	 PGROUP:INP_FOCNONE ; 7 -	not supported

CH_STR	 struc
CH_LEFT  db	 '®'            ; Left chevron
CH_RIGHT db	 '¯'            ; Right ...
CH_STR	 ends

	 public  CHEV_PAT
CHEV_PAT CH_STR  <' ',' '>      ; No chevrons
	 CH_STR  <>		; Default chevrons

	 public  DPUT_CLIP
	 align	 2
DPUT_CLIP dw	 -1		; Clipping limit for DPUT_SZ

$EDIT_REC record $EDIT_OVER:1,$EDIT_RSVD:15;
	 public  EDIT_FLAGS,KEY_FLAGS
EDIT_FLAGS dw	 0		; Global edit flags
KEY_FLAGS dw	 ?		; Global keyboard flags from GETKEYXLT
@KEY_SHF equ ((mask $DLSH) or (mask $DRSH)) ; Any shift key
;----------------------- end dialog stuff -----------------------

@PDWID	 equ	 44		; Width of print dialog
@PDHGHT  equ	 20		; Height of print dialog
	 public  PRINTDLG
	 align	 2
PRINTDLG WIN_STR <4,16,@PDHGHT,@PDWID> ; DIALOG_WIN
	 dw	 DGROUP:RAD_WHAT ; DIALOG_FOCUS
	 dw	@NPRINTITEMS	; DIALOG_NOBJ
	 DLGOBJ_STR <@DLG_TEXT,DGROUP:TXT_PRINT1>
	 DLGOBJ_STR <@DLG_TEXT,DGROUP:TXT_PRINT2>
	 DLGOBJ_STR <@DLG_TEXT,DGROUP:TXT_PRINT3>
	 DLGOBJ_STR <@DLG_TEXT,DGROUP:TXT_PRINT4>
	 DLGOBJ_STR <@DLG_TEXT,DGROUP:TXT_PRINT5>
	 DLGOBJ_STR <@DLG_BTN,DGROUP:BTN_OK>
	 DLGOBJ_STR <@DLG_BTN,DGROUP:BTN_CANCEL>
	 DLGOBJ_STR <@DLG_RADIO,DGROUP:RAD_WHAT>
	 DLGOBJ_STR <@DLG_RADIO,DGROUP:RAD_OUTPUT>
	 DLGOBJ_STR <@DLG_EDIT,DGROUP:EDIT_FNAME>
@NPRINTITEMS equ ($-PRINTDLG.DIALOG_OBJ) / (size DLGOBJ_STR)

@PCDWID  equ	 32		; Width of print cancel dialog
@PCDHGHT equ	 8		; Height ...
	 public  PRINTCANDLG
	 align	 2
PRINTCANDLG WIN_STR <(@NROWS-@PCDHGHT)/2,(@NCOLS-@PCDWID)/2,@PCDHGHT,@PCDWID>
	 dw	 DGROUP:BTN_CCANCEL ; DIALOG_FOCUS
	 dw	 @NPRINTCANITEMS ; DIALOG_NOBJ
	 DLGOBJ_STR <@DLG_TEXT,DGROUP:TXT_PRINTC1>
	 DLGOBJ_STR <@DLG_TEXT,DGROUP:TXT_PRINTC2>
	 DLGOBJ_STR <@DLG_BTN,DGROUP:BTN_CCANCEL>
@NPRINTCANITEMS equ ($-PRINTCANDLG.DIALOG_OBJ) / (size DLGOBJ_STR)

DLGMSG	 macro	 name,txt
	 public  MSG_&name
MSG_&name db	 txt
@MSG_&name&LEN equ $-MSG_&name
	 db	 0
	 endm			; DLGMSG

DLGBMSG  macro	 name,txt,dot,hot
	 public  MSG_&name
MSG_&name db	 txt
@MSG_&name&LEN equ $-MSG_&name
@MSG_&name&_DOT equ dot
@MSG_&name&_HOT equ hot
	 db	 0
	 endm			; DLGBMSG

DLGBTN	 macro	 name,row,col,nrows,ncols,t1,t2,t3,t4,flags,highlight
	 public  BTN_&name
BTN_&name WIN_STR <row,col,nrows,ncols> ; BTN_WIN
	 dw	 t1,t2,t3,t4	; BTN_TRIG
	 dw	 flags		; BTN_FLAGS
ifb <highlight>
	 dw	 -1		; No highlighting
else
	 dw	 highlight	; BTN_HOFS
endif
	 dw	 DGROUP:MSG_&name ; BTN_pszTXT
	 endm			; DLGBTN

DLGRAD	 macro	 name,row,col,nrows,ncols,t1,t2,t3,t4,flags
	 public  RAD_&name
RAD_&name WIN_STR <row,col,nrows,ncols> ; RADIO_WIN
	 dw	 t1,t2,t3,t4	; RADIO_TRIG
	 dw	 flags		; RADIO_WFLAGS
	 dw	 @&name&_NBTNS	; RADIO_NBTNS
	 endm			; DLGRAD

DLGRBTN  macro	 bname,row,col,t1,t2,t3,t4,flags
	 public  RBTN_&bname
RBTN_&bname POINT_STR <row,col> ; RBTN_POS
	 dw	 t1,t2,t3,t4	; RBTN_TRIG
	 dw	 flags		; RBTN_FLAGS
	 dw	 @MSG_&bname&_DOT ; RBTN_BOFS
	 dw	 @MSG_&bname&_HOT ; RBTN_HOFS
	 dw	 DGROUP:MSG_&bname ; RBTN_pszTXT
	 endm			; DLGRBTN

DLGREND  macro	name
@&name&_NBTNS equ (($-RAD_&name)-(size RADIO_STR))/(size RBTN_STR)
	 endm			; DLGREND

DLGEDIT  macro	 name,row,col,nrows,ncols,t1,t2,t3,t4,len,flags,defval
	 public  EDIT_&name,ETXT_&name
EDIT_&name WIN_STR <row,col,nrows,ncols> ; DEDIT_WIN
	 dw	 t1,t2,t3,t4	; DEDIT_TRIG
	 dw	 DGROUP:ETXT_&name ; DEDIT_pszTXT
	 dw	 @ETXT_&name&_LEN ; DEDIT_TXTLEN
	 dw	 flags		; DEDIT_FLAGS
	 dw	 0		; DEDIT_START
	 dw	 0		; DEDIT_CURSOR
	 dw	 0		; DEDIT_ANCHOR
ETXT_&name db	 len dup (0)	; Edit buffer
@ETXT_&name&_LEN equ $-ETXT_&name ; Effective size of buffer (not including 0)
	 db	 0		; Trailing NULL
ifnb <defval>
	 __&name = $
	 org	 ETXT_&name	; Overlay edit buffer
	 db	 defval 	; Initialize with supplied string
	 org	 __&name	; Resume normal data stream
endif
	 endm			; DLGEDIT

;-------------------- Values for localization ------------------
; The following values change:
; Text, highlight offsets, hotkeys, button widths.

ifdef LANG_GR

DLGMSG	 PRINT1,' Druck '

DLGMSG	 PRINT2,'was drucken ?'
@PRINT2_HIGHLIGHT equ 0
@PRINT2_TRIGGER equ @KEY_ALT_W
DLGMSG	 PRINT3,'Ausgabe-Umleitung'
@PRINT3_HIGHLIGHT equ 9
@PRINT3_TRIGGER equ @KEY_ALT_M
DLGMSG	 PRINT4,'Dateiname'
@PRINT4_HIGHLIGHT equ 0
@PRINT4_TRIGGER equ @KEY_ALT_D

DLGMSG	 PRINT5,' [TAB   LEER <ÄÙ ESC] '
DLGMSG	 OK,'Fertig'
DLGMSG	 CANCEL,'Abbruch'

DLGBMSG  WHTHIS,'( ) dieses Hilfe-Thema',1,11
DLGBMSG  WHALL, '( ) alle Hilfe-Themen',1,10
DLGBMSG  OUPRINT,'( ) Drucker',1,6
DLGBMSG  OUFILE, '( ) Datei',1,6
DLGBMSG  OUAFILE,'( ) h„nge an Datei',1,6

DLGMSG	 PRINTC1,' Meldung '

else

DLGMSG	 PRINT1,' Print '

DLGMSG	 PRINT2,'What to Print'
@PRINT2_HIGHLIGHT equ 0
@PRINT2_TRIGGER equ @KEY_ALT_W
DLGMSG	 PRINT3,'Output Routing'
@PRINT3_HIGHLIGHT equ 7
@PRINT3_TRIGGER equ @KEY_ALT_R
DLGMSG	 PRINT4,'File Name'
@PRINT4_HIGHLIGHT equ 5
@PRINT4_TRIGGER equ @KEY_ALT_N

DLGMSG	 PRINT5,' [Tab   Space Enter Esc ] '
DLGMSG	 OK,'OK'
DLGMSG	 CANCEL,'Cancel'

DLGBMSG  WHTHIS,'( ) This help topic',1,4
DLGBMSG  WHALL, '( ) All help topics',1,4
DLGBMSG  OUPRINT,'( ) Printer',1,4
DLGBMSG  OUFILE, '( ) Disk file',1,9
DLGBMSG  OUAFILE,'( ) Add to disk file',1,12

DLGMSG	 PRINTC1,' Message '

endif			; IFDEF LANG_GR

MSG_CCANCEL equ MSG_CANCEL

	 public  MSG_PRINTC2,MSG_CRLF2,MSG_PHEADER,MSG_FF
ifdef LANG_GR
MSG_PRINTC2 db 'Drucke Seite  '
else
MSG_PRINTC2 db 'Printing page  '
endif			; IFDEF LANG_GR
MSG_PRINTC2P db '_',0
MSG_CRLF2 label byte
MSG_PHEADER db	CR,LF

ifdef @QMT
@PHDRNAME equ	'Qualitas Memory Tester'
elseifdef @RAMDEMO
@PHDRNAME equ	'Qualitas RAMexam Demo '
else
@PHDRNAME equ	'Qualitas RAMexam      '
endif					; IFDEF @QMT

ifdef LANG_GR
	 db	@PHDRNAME, '           HILFE                 Seite '
else	; LANG_GR
	 db	@PHDRNAME, '           HELP                  Page  '
endif	; LANG_GR

MSG_PHEADERP db '_',CR,LF
	 db	'--------------------------------------------------------------',CR,LF
@MSG_PHEADERLEN equ $-MSG_PHEADER
@MSG_PHEADERLINES equ 3+0	; Number of lines added by header and footer
MSG_FF	 db	 12		; ASCII form feed

DLGCTXT  PRINT1,@PDWID,0
DLGCTXT  PRINT2,@PDWID,1,@PRINT2_HIGHLIGHT
DLGCTXT  PRINT3,@PDWID,7,@PRINT3_HIGHLIGHT
DLGCTXT  PRINT4,@PDWID,14,@PRINT4_HIGHLIGHT
DLGCTXT  PRINT5,@PDWID,(@PDHGHT-1)

DLGCTXT  PRINTC1,@PCDWID,0
DLGTXT	 PRINTC2,2,2

ifdef LANG_GR
DLGBTN	 OK,	(@PDHGHT-3),9,1,10,	@KEY_CR,@KEY_ALT_F,0,0, <@BTN_WDEF+@BTN_DEFLT>, 0
DLGBTN	 CANCEL,(@PDHGHT-3),25,1,12,	@KEY_ESC,@KEY_ALT_A,0,0, 0, 0

DLGBTN	 CCANCEL,(@PCDHGHT-3),10,1,12,	@KEY_ESC,@KEY_CR,@KEY_ALT_A,0, @BTN_DEFLT, 0
else
DLGBTN	 OK,	(@PDHGHT-3),9,1,10,	@KEY_CR,@KEY_ALT_O,0,0, <@BTN_WDEF+@BTN_DEFLT>, 0
DLGBTN	 CANCEL,(@PDHGHT-3),25,1,12,	@KEY_ESC,@KEY_ALT_C,0,0, 0, 0

DLGBTN	 CCANCEL,(@PCDHGHT-3),10,1,12,	@KEY_ESC,@KEY_CR,@KEY_ALT_C,0, @BTN_DEFLT, 0
endif				; IFDEF LANG_GR

DLGRAD	 WHAT,	2,7,4,30,	@PRINT2_TRIGGER,0,0,0,	0,	@WHAT_NBTNS
ifdef LANG_GR
 DLGRBTN WHTHIS, 1,5,		@KEY_ALT_H,'H','h',0,   @BTN_SEL+@BTN_DEFLT
 DLGRBTN WHALL, 2,5,		@KEY_ALT_I,'I','i',0,   0
else
 DLGRBTN WHTHIS, 1,5,		@KEY_ALT_T,'T','t',0,   @BTN_SEL+@BTN_DEFLT
 DLGRBTN WHALL, 2,5,		@KEY_ALT_A,'A','a',0,   0
endif				; IFDEF LANG_GR
DLGREND  WHAT

DLGRAD	 OUTPUT, 8,7,5,30,	@PRINT3_TRIGGER,0,0,0,	0,	@OUTPUT_NBTNS
ifdef LANG_GR
 DLGRBTN OUPRINT, 1,5,		@KEY_ALT_U,'U','u',0,   @BTN_SEL+@BTN_DEFLT
 DLGRBTN OUFILE, 2,5,		@KEY_ALT_T,'T','t',0,   0
 DLGRBTN OUAFILE, 3,5,		@KEY_ALT_N,'N','n',0,   0
else
 DLGRBTN OUPRINT, 1,5,		@KEY_ALT_P,'P','p',0,   @BTN_SEL+@BTN_DEFLT
 DLGRBTN OUFILE, 2,5,		@KEY_ALT_F,'F','f',0,   0
 DLGRBTN OUAFILE, 3,5,		@KEY_ALT_I,'I','i',0,   0
endif				; IFDEF LANG_GR
DLGREND  OUTPUT

DLGEDIT  FNAME, 15,7,1,30,	@PRINT4_TRIGGER,0,0,0,	128, @ED_HID, <PUNAME,'.PRN'>

;-------------------- End values for localization --------------

BOXCHAR_STR struc
BOXCHAR_TOP db	'ÚÄ¿'
BOXCHAR_MID db	'³ ³'
BOXCHAR_BOT db	'ÀÄÙ'
BOXCHAR_STR ends

	 public  BOXCHARS
BOXCHARS BOXCHAR_STR <>
	 BOXCHAR_STR <'ÉÍ»','º º','ÈÍ¼'>

	 public  SCRSAVE,SCRCNT,PHLPIND,PHLPCNT,CURPAGE,PHANDLE,CURLINE
SCRSAVE  dd	 ?		; Offset in AGROUP of saved screen data
SCRCNT	 dd	 ?		; Dword count of screen data saved
PHLPIND  dw	 ?		; Help index (origin:0) for DO_PRINT
PHLPCNT  dw	 ?		; Number of topics to display for DO_PRINT
CURPAGE  dw	 ?		; Current page we're printing
PHANDLE  dw	 ?		; File handle we're printing to (-1 for LPT1)
CURLINE  dw	 ?		; Current line on this page
@MAXLINES equ	 58		; Maximum lines per page

	 public  @HELP_NONE,@HELP_TOPICS,@HELP_SCREEN,HELP_STATE
@HELP_NONE equ	 0		; Not displaying help
@HELP_TOPICS equ 1		; Displaying help topics only
@HELP_SCREEN equ 2		; Browsing a help screen
HELP_STATE dw	 @HELP_NONE	; Current help state

	 public  CURSOR_SHAPE
@CURSOR_HIDE equ 1000h		; No visible cursor
@CURSOR_THIN equ 0607h		; Normal cursor
@CURSOR_BLOCK equ 0706h 	; Full block cursor for overwrite mode
CURSOR_SHAPE dw @CURSOR_THIN	; Cursor shape for editing text field

DATA	 ends			; End DATA segment

STARTJTAB macro  name

KEYSEG	 segment use16 word public 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

	 public  name&VAL
name&VAL label	 word		; First byte in the table

KEYSEG	 ends			; End KEYSEG segment


ACTSEG	 segment use16 word public 'data' ; Start ACTSEG segment
	 assume  ds:DGROUP

	 public  name&ACT
name&ACT label	 word		; First action in the table

ACTSEG	 ends			; End ACTSEG segment

	 endm			; STARTJTAB

ENDJTAB  macro	 name

KEYSEG	 segment use16 word public 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

N&name&VAL  equ  ($-name&VAL)/(type name&VAL)

KEYSEG	 ends			; End KEYSEG segment

	 endm			; ENDJTAB

	 STARTJTAB HLP

	 KEYACT  ESC	  , HELP_ESC
	 KEYACT  UP	  , HELP_UP
	 KEYACT  XUP	  , HELP_UP
	 KEYACT  SHF_UP   , HELP_UP
	 KEYACT  DN	  , HELP_DN
	 KEYACT  XDN	  , HELP_DN
	 KEYACT  SHF_DN   , HELP_DN
	 KEYACT  PGUP	  , HELP_PGUP
	 KEYACT  XPGUP	  , HELP_PGUP
	 KEYACT  PGDN	  , HELP_PGDN
	 KEYACT  XPGDN	  , HELP_PGDN
	 KEYACT  F2	  , HELP_PRINT
	 KEYACT  F3	  , HELP_PREVTOP
	 KEYACT  F4	  , HELP_NEXTTOP
	 KEYACT  CR	  , HELP_CR
	 KEYACT  PADENTER , HELP_CR
	 KEYACT  Y	  , HELP_YES
	 KEYACT  SHF_Y	  , HELP_YES
	 KEYACT  N	  , HELP_NO
	 KEYACT  SHF_N	  , HELP_NO
	 KEYACT  A	  , HELP_ALL
	 KEYACT  SHF_A	  , HELP_ALL
ifdef @BETA
	 KEYACT  Q	  , HELP_DBG
	 KEYACT  SHF_Q	  , HELP_DBG
endif				; IFDEF @BETA
	 ENDJTAB HLP


	 STARTJTAB IFE

	 KEYACT  LEFT,		IFE_LEFT
	 KEYACT  RIGHT, 	IFE_RIGHT
	 KEYACT  HOME,		IFE_HOME
	 KEYACT  END,		IFE_END
	 KEYACT  DEL,		IFE_DEL
	 KEYACT  INS,		IFE_INS
	 KEYACT  BS,		IFE_BS

	 ENDJTAB IFE


; Jump table for INP_FOCEDIT when shift keys are active.  This prevents
; us from interpreting Shift-Left on the number pad as 4.
	 STARTJTAB SIFE

	 KEYACT  SHF_LEFT,	IFE_LEFT
	 KEYACT  SHF_RIGHT,	IFE_RIGHT
	 KEYACT  SHF_HOME,	IFE_HOME
	 KEYACT  SHF_END,	IFE_END

	 ENDJTAB SIFE


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 GETKEY:near
	 extrn	 CHKNDKEY:near
	 extrn	 WPUT_C:near
	 extrn	 WPUT_SC:near
	 extrn	 WPUT_CSA:near
	 extrn	 WPUT_SA:near
	 extrn	 WPUT_SHD1:near
	 extrn	 WSETUP:near

	 extrn	 DISP_CLRSCR:near
	 extrn	 DISP_SCRN:near
	 extrn	 DISP_ACTIV:near

	 extrn	 SEL_DATA:word

	 extrn	 BIN2DEC:near
	 
	 NPPROC  DISP_HLPERR -- Display Help On Errors
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

AX	 =	 incoming HLPIND

|

	 REGSAVE <ax>		; Save register

	 and	 GL2_FLAG,not @GL2_ACTIV ; Mark as no longer active

	 push	 PMSG_HKEY	; Save ptr to help keys message
	 push	 PW_HKEY	; ...			window descriptor
	 push	 HLPIND 	; Save current help index

	 mov	 PMSG_HKEY,offset DGROUP:MSG_HKEYERR ; Use error format
	 mov	 PW_HKEY,offset DGROUP:W_HKEYERR ; ...
	 mov	 HLPIND,ax	; Mark as special help index

	 mov	 al,HERRATTR	; Get help error attribute
	 xchg	 al,HLPATTR	; Swap with help

	 mov	 ah,HERRATTR	; Get help error attribute
	 xchg	 ah,HTTLATTR	; Swap with help title

	 mov	 HELP_STATE,@HELP_NONE ; Clear any previous help state
	 and	 GL2_FLAG,not @GL2_HSCR ; ...
	 or	 GL3_FLAG,@GL3_MEMERR ; Mark as displaying memory/NMI errors

	 call	 DISP_HELP	; Display memory error via help screen

	 and	 GL3_FLAG,not @GL3_MEMERR ; Mark as no longer displaying memory/NMI errors
	 mov	 LAST_PTST,offset DGROUP:MSG_PTSTERR ; Save as last PTST

	 mov	 HLPATTR,al	; Restore
	 mov	 HTTLATTR,ah	; ...

	 pop	 HLPIND 	; Restore
	 pop	 PW_HKEY	; ...
	 pop	 PMSG_HKEY	; ...

	 call	 DISP_SCRN	; Display the new screen
	 call	 DISP_ACTIV	; Display active elements

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_HLPERR endp		; End DISP_HLPERR procedure
	 NPPROC  GET_MEM -- Find a block of allocated memory
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find a block of memory in TIMETAB we've allocated for testing.
Note that since the caller will probably write to this memory,
this should not be used while testing is in progress.

On entry:
EAX	 Minimum size of block in bytes

On exit:
If CF=0, EAX = linear address in bytes
else nothing found.

|

	 REGSAVE <cx,si>	; Save

	 mov	 cx,TIMECNT	; Number of blocks to check
	 sub	 si,si		; Starting index into TIMETAB[]
	 jcxz	 GMEM_FAIL	; Jump if nothing (???)

GMEM_NEXT:
	 test	 TIMETAB[si].TT_FLAG,@TT_UNALL ; Izit allocated?
	 jnz	 short GMEM_LOOP ; Jump if not

	 cmp	 TIMETAB[si].TT_LEN,eax ; Izit large enough?
	 jc	 short GMEM_LOOP ; Jump if not

	 mov	 eax,TIMETAB[si].TT_LBASE ; Linear base address
	 jmp	 short GMEM_EXIT ; Join common exit (note CF=0)

GMEM_LOOP:
	 add	 si,size TT_STR ; Skip to next

	 loop	 GMEM_NEXT	; Go around again

GMEM_FAIL:
	 stc			; Indicate failure (nothing found)
GMEM_EXIT:
	 REGREST <si,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_MEM endp			; End GET_MEM procedure
	 NPPROC  WPUT_BOX -- Display A Box
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a single or double lined box.

|

WPUT_BOX_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_BOX_DESC dw ?		; Offset of descriptor
WPUT_BOX_TYPE dw ?		; 0 for single or 1 for double
WPUT_BOX_ATTR dw ?		; Attribute to use for border and filler

WPUT_BOX_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,ecx,dx,si,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WPUT_BOX_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to output
	 jz	 short WPUT_BOX_EXIT ; Jump if no rows

	 imul	 bx,[bp].WPUT_BOX_TYPE,size BOXCHAR_STR ; Index into BOXCHARS
	 mov	 ax,[bp].WPUT_BOX_ATTR ; Get attribute to smear
	 mov	 ah,al		; Put into position

; First row
	 cld			; String ops forwardly

	 mov	 si,cx		; Save number of columns

	 push	 edi		; Save

	 lea	 bx,BOXCHARS[bx].BOXCHAR_TOP ; Address characters for first line
	 mov	 al,DGROUP:[bx+0].LO ; Get top left corner
S32	 stos	 es:[edi].ELO	; Write to screen

	 sub	 cx,2		; Subtract top left and top right
	 jc	 short WPUT_BOX_EXIT ; Jump if no space left

	 mov	 al,DGROUP:[bx+1].LO ; Get horizontal member
     rep stos	 es:[edi].ELO	; Write to screen

	 mov	 al,DGROUP:[bx+2].LO ; Get top right corner
S32	 stos	 es:[edi].ELO	; Write to screen

	 pop	 edi		; Restore

	 lea	 bx,DGROUP:[bx].BOXCHAR_MID ; Address middle line characters
	 jmp	 short WPUT_BOX_LOOP ; Adjust loop counter and go around

WPUT_BOX_NEXT:
	 push	 edi		; Save

	 cmp	 dx,1		; Izit the last row?
	 jne	 short @F	; Jump if not

	 add	 bx,3		; Skip to characters for last line
@@:
	 mov	 al,DGROUP:[bx+0].LO ; Get left (corner) character
S32	 stos	 es:[edi].ELO	; Write to screen

	 mov	 cx,si		; Get number of characters in this row
	 sub	 cx,2		; Adjust for left and right (corner) characters
;;;;;;;  jc	 ???		; Minimum is 2 characters

	 mov	 al,DGROUP:[bx+1].LO ; Get horizontal member or space
     rep stos	 es:[edi].ELO	; Write to screen

	 mov	 al,DGROUP:[bx+2].LO ; Get right (corner) character
S32	 stos	 es:[edi].ELO	; Write to screen

	 pop	 edi		; Restore
WPUT_BOX_LOOP:
	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Adjust row counter
	 jnz	 short WPUT_BOX_NEXT ; Go around again if not done

WPUT_BOX_EXIT:
	 REGREST <es,edi,si,dx,ecx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 ret	 2+2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_BOX endp			; End WPUT_BOX procedure
	 NPPROC  DPUT_SZ -- Display ASCIIZ string relative to dialog box
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display ASCIIZ string using underlying attributes relative to a dialog box.

On entry:
DGROUP:BX ==>	 DIALOG_STR

|

DPUT_SZ_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DPUT_SZ_pTXT dw  ?		; Offset of string
DPUT_SZ_COL dw	 ?		; Offset from left of window
DPUT_SZ_ROW dw	 ?		; ...	      top  ...

DPUT_SZ_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,ecx,dx,si,edi,es> ; Save registers

	 lea	 si,[bx].DIALOG_WIN ; Address dialog window
	 xchg	 si,[bp].DPUT_SZ_pTXT ; Set up pseudo-window descriptor

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 imul	 cx,[bp].DPUT_SZ_COL,2 ; Get starting column
	 add	 edi,ecx	; Starting offset for string
	 imul	 cx,[bp].DPUT_SZ_ROW,@NCOLS*2 ; Get starting row
	 add	 edi,ecx	; Starting row

	 cld			; String ops forwardly
	 mov	 cx,DPUT_CLIP	; Get clipping limit
@@:
	 lods	 DGROUP:[si].LO ; Get string byte
	 or	 al,al		; Izit the end?
	 jz	 short @F	; Jump if so

S32	 stos	 es:[edi].LO	; Save character
	 inc	 edi		; Skip attribute
	 loop	 @B		; Go around again

@@:
DPUT_SZ_EXIT:
	 REGREST <es,edi,si,dx,ecx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 ret	 2+2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPUT_SZ endp			; End DPUT_SZ procedure
	 NPPROC  DPUT_SZA -- Display ASCIIZ string smearing attribute
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display ASCIIZ string smearing an attribute relative to a dialog box.

On entry:
DGROUP:BX ==>	 DIALOG_STR

|

DPUT_SZA_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DPUT_SZA_pTXT dw ?		; Offset of string
DPUT_SZA_COL dw  ?		; Offset from left of window
DPUT_SZA_ROW dw  ?		; ...	      top  ...
DPUT_SZA_ATTR dw ?		; Attribute to use

DPUT_SZA_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,ecx,dx,si,edi,es> ; Save registers

	 lea	 si,[bx].DIALOG_WIN ; Address dialog window
	 xchg	 si,[bp].DPUT_SZA_pTXT ; Set up pseudo-window descriptor

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 imul	 cx,[bp].DPUT_SZA_COL,2 ; Get starting column
	 add	 edi,ecx	; Starting offset for string
	 imul	 cx,[bp].DPUT_SZA_ROW,@NCOLS*2 ; Get starting row
	 add	 edi,ecx	; Starting row

	 cld			; String ops forwardly

	 mov	 cx,DPUT_CLIP	; Get clipping limit
	 mov	 ah,[bp].DPUT_SZA_ATTR.LO ; Get attribute to smear
@@:
	 lods	 DGROUP:[si].LO ; Get string byte
	 or	 al,al		; Izit the end?
	 jz	 short @F	; Jump if so

S32	 stos	 es:[edi].ELO	; Save character and attribute
	 loop	 @B		; Go around again

@@:
DPUT_SZA_EXIT:
	 REGREST <es,edi,si,dx,ecx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPUT_SZA endp			; End DPUT_SZA procedure
	 NPPROC  DPUT_CA -- Display character and attrib relative to dialog box
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display character and attribute relative to a dialog box.

On entry:
DGROUP:BX ==>	 DIALOG_STR

|

DPUT_CA_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DPUT_CA_CHAR dw  ?		; Character and attribute
DPUT_CA_COL dw	 ?		; Offset from left of window
DPUT_CA_ROW dw	 ?		; ...	      top  ...

DPUT_CA_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,ecx,dx,si,edi,es> ; Save registers

	 lea	 si,[bx].DIALOG_WIN ; Address dialog window
	 xchg	 si,[bp].DPUT_CA_CHAR ; Set up pseudo-window descriptor

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 imul	 cx,[bp].DPUT_CA_COL,2 ; Get starting column
	 add	 edi,ecx	; Starting offset for string
	 imul	 cx,[bp].DPUT_CA_ROW,@NCOLS*2 ; Get starting row
	 add	 edi,ecx	; Starting row

	 mov	 es:[edi].ELO,si ; Save character and attribute

	 REGREST <es,edi,si,dx,ecx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 ret	 2+2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPUT_CA endp			; End DPUT_CA procedure
	 NPPROC  DPUT_C -- Display character relative to dialog box
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display character relative to a dialog box.

On entry:
DGROUP:BX ==>	 DIALOG_STR

|

DPUT_C_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DPUT_C_CHAR dw	 ?		; Character
DPUT_C_COL dw	 ?		; Offset from left of window
DPUT_C_ROW dw	 ?		; ...	      top  ...

DPUT_C_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,ecx,dx,si,edi,es> ; Save registers

	 lea	 si,[bx].DIALOG_WIN ; Address dialog window
	 xchg	 si,[bp].DPUT_C_CHAR ; Set up pseudo-window descriptor
	 mov	 ax,si		; Save character

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 imul	 cx,[bp].DPUT_C_COL,2 ; Get starting column
	 add	 edi,ecx	; Starting offset for string
	 imul	 cx,[bp].DPUT_C_ROW,@NCOLS*2 ; Get starting row
	 add	 edi,ecx	; Starting row

	 mov	 es:[edi].LO,al ; Save character

	 REGREST <es,edi,si,dx,ecx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 ret	 2+2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPUT_C endp			; End DPUT_C procedure
	 NPPROC  DPUT_SCA -- Smear character and attrib relative to dialog box
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Smear character and attribute throughout a window relative to a dialog box.

On entry:
DGROUP:BX ==>	 DIALOG_STR

|

DPUT_SCA_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DPUT_SCA_WIN dw  ?		; Offset of window (relative to dialog)
DPUT_SCA_CHAR dw ?		; Character and attribute

DPUT_SCA_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,ecx,dx,si,edi,es> ; Save registers

	 lea	 si,[bx].DIALOG_WIN ; Address dialog window
	 xchg	 si,[bp].DPUT_SCA_WIN ; Set up pseudo-window descriptor

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 imul	 cx,DGROUP:[si].WIN_COL,2 ; Get starting column in box
	 add	 edi,ecx	; Starting offset to smear
	 imul	 cx,DGROUP:[si].WIN_ROW,@NCOLS*2 ; Get starting row
	 add	 edi,ecx	; Starting row
	 mov	 dx,DGROUP:[si].WIN_NROWS ; Get number of rows to smear
	 mov	 si,DGROUP:[si].WIN_NCOLS ; Get number of columns ...
	 mov	 ax,[bp].DPUT_SCA_CHAR ; Get character and attribute
@@:
	 mov	 cx,si		; Number of columns

	 push	 edi		; Save start of line
     rep stos	 es:[edi].ELO	; Smear specified # of columns
	 pop	 edi		; Restore

	 add	 edi,@NCOLS*2	; Skip to next row
	 dec	 dx		; Adjust row counter
	 jnz	 short @B	; Go around again if more

	 REGREST <es,edi,si,dx,ecx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPUT_SCA endp			; End DPUT_SCA procedure
	 NPPROC  DPUT_A -- Display attribute relative to dialog box
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display attribute relative to a dialog box.

On entry:
DGROUP:BX ==>	 DIALOG_STR

|

DPUT_A_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DPUT_A_ATTR dw	 ?		; Attribute
DPUT_A_COL dw	 ?		; Offset from left of window
DPUT_A_ROW dw	 ?		; ...	      top  ...

DPUT_A_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,ecx,dx,si,edi,es> ; Save registers

	 lea	 bx,[bx].DIALOG_WIN ; Address dialog window
	 xchg	 bx,[bp].DPUT_A_ATTR ; Set up pseudo-window descriptor

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 imul	 cx,[bp].DPUT_A_COL,2 ; Get starting column
	 add	 edi,ecx	; Starting offset for string
	 imul	 cx,[bp].DPUT_A_ROW,@NCOLS*2 ; Get starting row
	 add	 edi,ecx	; Starting row

	 mov	 es:[edi].HI,bl ; Save attribute

	 REGREST <es,edi,si,dx,ecx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 ret	 2+2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPUT_A endp			; End DPUT_A procedure
	 NPPROC  STRLEN -- Return length of ASCIIZ string
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return length of ASCIIZ string.

On exit:
AX	 string length in bytes

|

STRLEN_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
STRLEN_psz dw	 ?		; Near pointer to string

STRLEN_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <cx,di,es>	; Save registers

	 cld			; String ops forwardly

	 push	 ds		; Get DGROUP selector
	 pop	 es		; Address for SCAS
	 assume  es:DGROUP	; Tell the assembler

	 mov	 di,[bp].STRLEN_psz ; ES:DI ==> string
	 mov	 cx,-1		; Starting value
	 sub	 al,al		; What to look for
   repne scas	 DGROUP:[di].LO ; Find end of string
	 not	 cx		; Perform one's complement negation
	 dec	 cx		; Subtract NUL from total length
	 mov	 ax,cx		; Move to return register

	 REGREST <es,di,cx>	; Restore
	 assume  es:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STRLEN endp			; End STRLEN procedure
	 NPPROC  SETCSR -- Set cursor to specified shape
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set cursor to specified shape / attributes

|

SETCSR_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
SETCSR_SHAPE dw  ?		; New shape

SETCSR_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,ds>	; Save registers

	 mov	 cx,[bp].SETCSR_SHAPE ; Get new shape
	 VIDCALL @SETTYP	; Set cursor shape, attributes to CH,CL

	 REGREST <ds,cx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETCSR endp			; End SETCSR procedure

;;;;;;;  public  D2WCALL_RET
;;;;;;;D2WCALL_RET:
;;;;;;;  ret	 2+2		; Return to caller, popping arguments
;;;;;;;org $-2
;;;;;;;  public  D2WCALL_RETN
;;;;;;;D2WCALL_RETN dw	 ?		; Number of arguments to pop

	 NPPROC  D2WCALL -- Translate dialog to window coordinates
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate dialog box relative window to absolute and make specified call.

On entry:
DGROUP:BX ==>	 DIALOG_STR

On exit:
as defined by called procedure

|

D2WCALL_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
D2WCALL_pfn dw	 ?		; Near pointer to call
;;;;;;;D2WCALL_NARGS dw ?	; Number of word arguments to follow (including
;;;;;;; 			; window address)
D2WCALL_pWIN dw  ?		; Address of dialog-relative window

D2WCALL_STR ends

;;;;;;;D2WCALL_ARGS equ D2WCALL_pWIN[2] ; Start of argument list

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <bx,cx,si>	; Save registers

	 lea	 bx,DGROUP:[bx].DIALOG_WIN ; Address basic window structure
	 mov	 si,[bp].D2WCALL_pWIN ; Get dialog-relative window

	 push	 DGROUP:[si].WIN_ROW ; Save starting row
	 push	 DGROUP:[si].WIN_COL ; ...	     column
	 push	 si		; Save window pointer

	 mov	 cx,DGROUP:[bx].WIN_ROW ; Get starting row
	 add	 DGROUP:[si].WIN_ROW,cx ; Add to window
	 mov	 cx,DGROUP:[bx].WIN_COL ; Get starting column
	 add	 DGROUP:[si].WIN_COL,cx ; Add to window

;;;;;;;  mov	 cx,[bp].D2WCALL_NARGS ; Get number of additional arguments
;;;;;;;  mov	 si,cx		; Copy
;;;;;;;  shl	 si,1		; Convert words to bytes
;;;;;;;  add	 si,2+2+2	; Add required arguments
;;;;;;;  mov	 D2WCALL_RETN,si ; Set up to clean up stack on return
;;;;;;;
;;;;;;;  mov	 si,cx		; Get additional argument word count
;;;;;;;  shl	 si,1		; Convert to byte index into D2WCALL_ARGS[]
;;;;;;;  jcxz	 D2WCALL_WIN	; Jump if no other arguments
;;;;;;;
;;;;;;;@@:
;;;;;;;  push	 [bp].D2WCALL_ARGS[si] ; Pass argument
;;;;;;;  sub	 si,2		; Back off to previous argument
;;;;;;;  loop	 @B		; Go around again
;;;;;;;
;;;;;;;D2WCALL_WIN:
	 push	 si		; Pass address of window
	 call	 [bp].D2WCALL_pfn ; Call specified function

	 pop	 si		; Restore
	 pop	 DGROUP:[si].WIN_COL ; Restore starting column
	 pop	 DGROUP:[si].WIN_ROW ; ...		row

	 REGREST <si,cx,bx>	; Restore

	 pop	 bp		; Restore

;;;;;;;  jmp	 short D2WCALL_RET ; Join common return code
	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

D2WCALL endp			; End D2WCALL procedure
	 NPPROC  DRAW_DTEXT -- Draw dialog static text
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Draw static text in a dialog box.

On entry:
AX=0		Only redraw mutable portions
AX!=0		Redraw everything
DGROUP:DI ==>	DTEXT_STR
DGROUP:BX ==>	DIALOG_STR

|

	 REGSAVE <ax>		; Save

; Display static text
	 push	 DGROUP:[di].DTEXT_POS.POINT_ROW ; Starting row
	 mov	 ax,DGROUP:[di].DTEXT_POS.POINT_COL ; Starting column for text
	 push	 ax		; Pass as starting column
	 push	 DGROUP:[di].DTEXT_pszTXT ; Offset of text
	 call	 DPUT_SZ	; Display ASCIIZ string relative to dialog box

	 add	 ax,DGROUP:[di].DTEXT_HOFS ; Get column to highlight
	 jc	 short @F	; Jump if disabled (-1)

	 push	 DGROUP:[di].DTEXT_POS.POINT_ROW ; Starting row
	 push	 ax		; Column to highlight
	 mov	 al,DLGTHKATTR	; Attribute to set
	 push	 ax		; Pass attribute value
	 call	 DPUT_A 	; Set attribute
@@:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAW_DTEXT endp 		; End DRAW_DTEXT procedure
	 NPPROC  DRAW_DEDIT -- Draw dialog edit field
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Draw edit field in a dialog box.

On entry:
AX=0		Only redraw mutable portions
AX!=0		Redraw everything
DGROUP:DI ==>	DEDIT_STR
DGROUP:BX ==>	DIALOG_STR

|

	 REGSAVE <ax,cx,dx,si>	; Save

; Display single line edit text
	 lea	 si,DGROUP:[di].DEDIT_WIN ; Address window structure

	 or	 ax,ax		; Displaying everything?
	 jz	 short @F	; Jump if not

	 push	 si		; Pass address of window descriptor
	 push	 offset PGROUP:WPUT_SHD1 ; Function to call
	 call	 D2WCALL	; Display a type 1 shadow

@@:
; Hide the cursor
	 push	 @CURSOR_HIDE	; Make cursor invisible
	 call	 SETCSR 	; Set cursor shape / attributes

	 mov	 ah,DLGENATTR	; Normal background for edit
	 cmp	 DGROUP:[bx].DIALOG_FOCUS,di ; Do we currently have the focus?
	 jne	 short @F	; Jump if not

; We have the focus, so we need to show the cursor.
	 push	 bx		; Save

	 push	 CURSOR_SHAPE	; Show edit field cursor
	 call	 SETCSR 	; Set cursor shape and attributes

	 mov	 dl,DGROUP:[di].DEDIT_WIN.WIN_COL.LO ; Get starting column
	 add	 dl,DGROUP:[bx].DIALOG_WIN.WIN_COL.LO ; ...relative to screen
	 add	 dl,DGROUP:[di].DEDIT_CURSOR.LO ; Cursor X position
	 sub	 dl,DGROUP:[di].DEDIT_START.LO ; ...relative to window
	 inc	 dl		; Skip left margin
	 mov	 dh,DGROUP:[di].DEDIT_WIN.WIN_ROW.LO ; Get starting row
	 add	 dh,DGROUP:[bx].DIALOG_WIN.WIN_ROW.LO ; ...relative to screen
	 sub	 bh,bh		; Page to set cursor for
	 VIDCALL @SETPOS	; Set cursor position

	 pop	 bx		; Restore
	 mov	 ah,DLGEFATTR	; Use edit background for when we have focus
@@:
	 mov	 al,' '         ; Filler character
	 push	 ax		; Character and attribute to smear
	 push	 si		; Pass window descriptor offset
	 call	 DPUT_SCA	; Fill with specified character and attribute

	 test	 DGROUP:[di].DEDIT_FLAGS,@ED_HID ; Are we hiding?
	 jnz	 short DLG_DISPXEDIT ; Jump if not

	 push	 DPUT_CLIP	; Save default (no clipping)

; Edit string is displayed starting at offset 1 in the window.
; The left corner (DEDIT_START) will never be greater than the length
; of the text.
	 mov	 dx,DGROUP:[di].DEDIT_WIN.WIN_NCOLS ; Get size of edit window
	 sub	 dx,1+1 	; Adjust for left and right margins

	 cmp	 dx,DGROUP:[di].DEDIT_TXTLEN ; Izit smaller than maximum text?
	 jb	 short @F	; Jump if so

	 mov	 dx,DGROUP:[di].DEDIT_TXTLEN ; Use smaller value
@@:
	 mov	 DPUT_CLIP,dx	; Clipping value for DPUT_SZ

	 push	 DGROUP:[di].DEDIT_WIN.WIN_ROW ; Row for display
	 mov	 dx,DGROUP:[di].DEDIT_WIN.WIN_COL ; Get start of window
	 inc	 dx		; Skip to column 1
	 push	 dx		; Starting column for display
	 mov	 dx,DGROUP:[di].DEDIT_START ; Get starting offset within string
	 add	 dx,DGROUP:[di].DEDIT_pszTXT ; Starting position to display
	 push	 dx		; ASCIIZ string to display
	 call	 DPUT_SZ	; Display string

	 test	 DGROUP:[di].DEDIT_FLAGS,@ED_HIGH ; Is highlighting in effect?
	 jz	 short DLG_DISPXEDITHI ; Jump if not

; We'll redisplay the highlighted string at WIN_COL+1+min (DEDIT_ANCHOR,
; DEDIT_CURSOR)-DEDIT_START.

	 mov	 dx,DGROUP:[di].DEDIT_CURSOR ; Get cursor position
	 mov	 ax,DGROUP:[di].DEDIT_ANCHOR ; Get anchor position

	 cmp	 dx,ax		; Is cursor after anchor?
	 jnb	 short @F	; Jump if so

	 xchg	 ax,dx		; Swap 'em
@@:
	 mov	 si,ax		; Get first position offset
	 sub	 si,DGROUP:[di].DEDIT_START ; Get offset from start of window
	 inc	 si		; Starting column is 1

	 cmp	 si,DGROUP:[di].DEDIT_WIN.WIN_NCOLS ; Izit within range?
	 jge	 short DLG_DISPXEDITHI ; Jump if not

; If SI is negative, we need to check for the area ending before DEDIT_START.
	 cmp	 si,1		; Did it start before the display window?
	 jge	 short @F	; Jump if not

	 cmp	 dx,DGROUP:[di].DEDIT_START ; Does it end before start?
	 jb	 short DLG_DISPXEDITHI ; Jump if so

; Start at column 0 (origin:1)
	 mov	 si,1		; Smallest possible value
@@:
	 mov	 cl,DLGEHATTR	; Get highlight for edit field
	 push	 cx		; Attribute to smear
	 push	 DGROUP:[di].DEDIT_WIN.WIN_ROW ; Row for display
	 mov	 cx,DGROUP:[di].DEDIT_WIN.WIN_NCOLS ; Get end of clipping area
	 sub	 cx,si		; Physical space remaining for highlight
	 dec	 cx		; Less right margin space
	 sub	 dx,ax		; Logical length of highlighted area

	 cmp	 dx,cx		; Is logical space smaller?
	 jnb	 short @F	; Jump if not

	 xchg	 cx,dx		; Swap 'em
@@:
	 mov	 DPUT_CLIP,cx	; Save the smaller of the two

	 mov	 cx,si		; Get window offset for display
	 add	 si,DGROUP:[di].DEDIT_WIN.WIN_COL ; Starting column to display
	 push	 si		; Starting column
	 dec	 cx		; Get offset from DEDIT_START
	 add	 cx,DGROUP:[di].DEDIT_START ; Get offset within string
	 add	 cx,DGROUP:[di].DEDIT_pszTXT ; Start of string to highlight
	 push	 cx		; Pass string address
	 call	 DPUT_SZA	; Display string, smearing attribute

DLG_DISPXEDITHI:
	 pop	 DPUT_CLIP	; Restore clipping default

DLG_DISPXEDIT:
	 REGREST <si,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAW_DEDIT endp 		; End DRAW_DEDIT procedure
	 NPPROC  DRAW_DBTN -- Draw dialog window button
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Draw a window button in a dialog box.

On entry:
AX=0		Only redraw mutable portions
AX!=0		Redraw everything
DGROUP:DI ==>	BTN_STR
DGROUP:BX ==>	DIALOG_STR

|

	 REGSAVE <ax,cx,dx,si>	; Save

; Display window button
	 lea	 si,DGROUP:[di].BTN_WIN ; Address window structure

	 or	 ax,ax		; Redraw everything?
	 jz	 short @F	; Jump if not

	 push	 si		; Pass address of window descriptor
	 push	 offset PGROUP:WPUT_SHD1 ; Function to call
	 call	 D2WCALL	; Display a type 1 shadow

@@:
	 test	 DGROUP:[di].BTN_FLAGS,@BTN_HID ; Izit hidden?
	 jnz	 short DLG_XDISPBTN ; Jump if so

	 mov	 al,' '         ; Filler character
	 mov	 ah,DLGBTNATTR	; Background for button
	 cmp	 DGROUP:[bx].DIALOG_FOCUS,di ; Do we currently have the focus?
	 jne	 short @F	; Jump if not

	 mov	 ah,DLGABTNATTR ; Use highlighted attribute
@@:
	 push	 ax		; Character and attribute to smear
	 push	 si		; Pass window descriptor offset
	 call	 DPUT_SCA	; Fill with specified character and attribute

	 push	 DGROUP:[di].BTN_pszTXT ; Pass string offset
	 call	 STRLEN 	; AX = length of text
	 mov	 dx,ax		; Save for later

	 sub	 ax,DGROUP:[di].BTN_WIN.WIN_NCOLS ; Get -(start pos * 2)
	 neg	 ax		; Starting position for text * 2
	 shr	 ax,1		; Starting offset for button text
	 add	 ax,DGROUP:[di].BTN_WIN.WIN_COL ; Get offset from dialog margin

	 push	 DGROUP:[di].BTN_WIN.WIN_ROW ; Starting row
	 push	 ax		; Starting column for text
	 push	 DGROUP:[di].BTN_pszTXT ; Offset of text
	 call	 DPUT_SZ	; Display ASCIIZ string relative to dialog box

	 push	 ax		; Save start of text

	 push	 DGROUP:[di].BTN_WIN.WIN_ROW ; Starting row
	 add	 ax,DGROUP:[di].BTN_HOFS ; Offset of character to highlight
	 push	 ax		; Column to highlight
	 mov	 al,DLGBHKATTR	; Attribute to set
	 cmp	 DGROUP:[bx].DIALOG_FOCUS,di ; Do we currently have the focus?
	 jne	 short @F	; Jump if not

	 mov	 al,DLGABHKATTR ; Attribute for focused button hotkey
@@:
	 push	 ax		; Pass attribute value
	 call	 DPUT_A 	; Set attribute

	 pop	 ax		; Get start of text

; Display chevrons for default button.
	 mov	 ch,DLGABTNATTR ; Highlighted button attribute
	 sub	 si,si		; Assume no chevrons

	 test	 DGROUP:[di].BTN_FLAGS,@BTN_DEFLT ; Is this the default?
	 jz	 short @F	; Jump if not

	 add	 si,size CH_STR ; Skip to chevrons
@@:
	 mov	 cl,CHEV_PAT[si].CH_LEFT ; Get space or left chevron

	 sub	 ax,2		; Back off to first chevron location

	 push	 DGROUP:[di].BTN_WIN.WIN_ROW ; Row
	 push	 ax		; Column
	 push	 cx		; Character and attribute
	 call	 DPUT_CA	; Set character and attribute

	 add	 ax,dx		; Skip button text
	 add	 ax,2+2-1	; Skip to right chevron position
	 mov	 cl,CHEV_PAT[si].CH_RIGHT ; Get space or right chevron

	 push	 DGROUP:[di].BTN_WIN.WIN_ROW ; Row
	 push	 ax		; Column
	 push	 cx		; Character and attribute
	 call	 DPUT_CA	; Set character and attribute

DLG_XDISPBTN:
	 REGREST <si,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAW_DBTN endp			; End DRAW_DBTN procedure
	 NPPROC  DRAW_DRADIO -- Draw dialog radio button group
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Draw radio button group in a dialog box.

On entry:
AX=0		Only redraw mutable portions
AX!=0		Redraw everything
DGROUP:DI ==>	RADIO_STR
DGROUP:BX ==>	DIALOG_STR

|

	 REGSAVE <ax,cx,dx,si,di> ; Save

; Display radio button
	 lea	 si,DGROUP:[di].RADIO_WIN ; Address window structure

	 or	 ax,ax		; Redraw everything?
	 jz	 short @F	; Jump if not

	 mov	 al,' '         ; Filler character
	 mov	 ah,DLGBTNATTR	; Background for button
	 push	 ax		; Character and attribute to smear
	 push	 si		; Pass window descriptor offset
	 call	 DPUT_SCA	; Fill with specified character and attribute

; FIXME Use address of other shading routines based on RADIO_WFLAGS
	 push	 si		; Pass address of window descriptor
	 push	 offset PGROUP:WPUT_SHD1 ; Function to call
	 call	 D2WCALL	; Display a type 1 shadow

@@:
	 mov	 cx,DGROUP:[di].RADIO_NBTNS ; Get number of buttons to display
	 jcxz	 DLG_XDISPRADIO ; Jump if none

	 mov	 si,di		; DGROUP:SI ==> RADIO_STR
	 add	 di,size RADIO_STR ; DGROUP:DI ==> first RBTN_STR
DLG_DISPRBTN:
	 test	 DGROUP:[di].RBTN_FLAGS,@BTN_HID ; Izit hidden?
	 jnz	 short DLG_DISPRBTNLOOP ; Jump if so

; Put the basic text up
	 mov	 al,DLGBTNATTR	; Normal button attribute
	 cmp	 DGROUP:[bx].DIALOG_FOCUS,si ; Do we have the current focus?
	 jne	 short @F	; Jump if not

	 test	 DGROUP:[di].RBTN_FLAGS,@BTN_DEFLT ; Izit the default?
	 jz	 short @F	; Jump if not

	 mov	 al,DLGABTNATTR ; Background for highlighted button
@@:
	 push	 ax		; Attribute to smear

	 mov	 dx,DGROUP:[si].RADIO_WIN.WIN_ROW ; Get starting row for group
	 add	 dx,DGROUP:[di].RBTN_POS.POINT_ROW ; Dialog box row for button
	 push	 dx		; Where to display text
	 mov	 ax,DGROUP:[si].RADIO_WIN.WIN_COL ; Get starting col for group
	 add	 ax,DGROUP:[di].RBTN_POS.POINT_COL ; Dialog box col for button
	 push	 ax		; Where to display text
	 push	 DGROUP:[di].RBTN_pszTXT ; Offset of text
	 call	 DPUT_SZA	; Display ASCIIZ string with specified attribute

	 push	 ax		; Save start of text

; Fill in the button dot
	 add	 ax,DGROUP:[di].RBTN_BOFS ; Skip to button dot position
	 push	 dx		; Row of button
	 push	 ax		; Column of button dot
	 mov	 al,' '         ; Assume it's not on
	 test	 DGROUP:[di].RBTN_FLAGS,@BTN_SEL ; Izit selected?
	 jz	 short @F	; Good guess

	 mov	 al,'ù'         ; Selected dot
@@:
	 push	 ax		; Pass character to fill in
	 call	 DPUT_C 	; Fill in character

	 pop	 ax		; Get start of text

; Highlight hotkey
	 push	 dx		; Row of button
	 add	 ax,DGROUP:[di].RBTN_HOFS ; Skip to highlighted column
	 push	 ax		; Column to highlight
	 mov	 al,DLGRBHKATTR ; Title hotkey attribute
	 push	 ax		; Attribute to use
	 call	 DPUT_A 	; Set attribute

DLG_DISPRBTNLOOP:
	 add	 di,size RBTN_STR ; Skip to next button

	 loop	 DLG_DISPRBTN	; Go around again

DLG_XDISPRADIO:
	 REGREST <di,si,dx,cx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAW_DRADIO endp		; End DRAW_DRADIO procedure
	 NPPROC  DRAW_DNONE -- Do nothing
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Do nothing.  This is used as a stub in the object draw call table.

On entry:
AX=0		Only redraw mutable portions
AX!=0		Redraw everything
DGROUP:DI ==>	Object structure
DGROUP:BX ==>	DIALOG_STR

|

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAW_DNONE endp 		; End DRAW_DNONE procedure
	 NPPROC  DRAW_DLG -- Draw dialog box
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Draw dialog box DGROUP:BX.

On entry:
DGROUP:BX ==>	 DIALOG_STR

|

	 REGSAVE <cx,dx,si,di>	; Save

	 lea	 dx,[bx].DIALOG_WIN ; Get address of window descriptor

	 mov	 al,DLGBATTR	; Get dialog box border attribute
	 push	 ax		; Pass attribute to smear
	 push	 1		; Use double border box
	 push	 dx		; Pass address of window descriptor
	 call	 WPUT_BOX	; Create box

; Display a shadow below and to the right of the help screen

	 push	 dx		; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

; Display objects
	 mov	 cx,DGROUP:[bx].DIALOG_NOBJ ; Get number of objects
	 or	 cx,cx		; Are there any?
	 jz	 near ptr DRAW_DLG_EXIT ; Jump if not

	 lea	 si,[bx].DIALOG_OBJ ; Address first object
DLG_DISPOBJ:
	 imul	 di,DGROUP:[si].DLGOBJ_TYPE,2 ; Get object type word index
	 mov	 ax,DLG_DISP[di] ; Get address of display code
	 mov	 di,DGROUP:[si].DLGOBJ_pOBJ ; Address object

	 call	 ax		; Display object (note AX!=0)

	 add	 si,size DLGOBJ_STR ; Skip to next one

	 loop	 DLG_DISPOBJ	; Go around again if more

DRAW_DLG_EXIT:
	 REGREST <di,si,dx,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAW_DLG endp			; End DRAW_DLG procedure
	 NPPROC  INP_FOCNONE -- Default focused input processor
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process focused input for a dialog box object.

On entry:
AX		 Int 16h keycode to process
DGROUP:DI ==>	 Object structure

On exit:
CF=1		 It was our keycode
CF=0		 We don't want the keycode; take it elsewhere

|

	 clc			; Not our keycode

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INP_FOCNONE endp		; End INP_FOCNONE procedure
	 NPPROC  INP_FOCTEXT -- Focused input processor for static text
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process focused input for a static text object.

On entry:
AX		 Int 16h keycode to process
DGROUP:DI ==>	 DTEXT_STR

On exit:
CF=1		 It was our keycode
CF=0		 We don't want the keycode; take it elsewhere

|

	 clc			; Not our keycode

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INP_FOCTEXT endp		; End INP_FOCTEXT procedure
	 NPPROC  BRANCH_AX -- Check keycode/action table and branch
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check specified keycode/action table for the keycode in AX.

If found, return to the specified near pointer, otherwise return to caller.

On entry:
AX	 Laundered scan code from GETKEYXLT (flags in KEY_FLAGS)

On exit:
Return address may be changed if we find an action address.

|

BRANCH_STR struc

	 dw	 ?		; Caller's BP
BRANCH_RETIP dw  ?		; Caller's IP
BRANCH_COUNT dw  ?		; Entries in keycode/action tables
BRANCH_pACT dw	 ?		; Near pointer to action table
BRANCH_pTAB dw	 ?		; Near pointer to keycode table

BRANCH_STR ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <cx,di>	; Save

	 mov	 cx,[bp].BRANCH_COUNT ; Number of entries to scan
	 cld			; String ops forwardly
	 mov	 di,[bp].BRANCH_pTAB ; DGROUP:DI ==> Keycode table
   repne scas	 DGROUP:[di].ELO ; Scan for a match
	 jne	 short BRANCH_EXIT ; Jump if none found

; DGROUP:DI ==> entry after matching entry
	 sub	 di,2		; Point to matching entry
	 sub	 di,[bp].BRANCH_pTAB ; Get offset from start of key table
	 add	 di,[bp].BRANCH_pACT ; Address action table entry

	 mov	 cx,DGROUP:[di].ELO ; Get the address
	 mov	 [bp].BRANCH_RETIP,cx ; Where to return to
BRANCH_EXIT:
	 REGREST <di,cx>	; Restore

	 pop	 bp		; Restore

	 ret	 2+2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BRANCH_AX endp			; End BRANCH_AX procedure
	 NPPROC  INP_FOCEDIT -- Focused input processor for edit fields
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process focused input for an edit field.

Ins	 Toggle insert/overwrite state
Del	 Delete character at cursor, or delete selected area
Left,Right,Home,End Move cursor and anchor; if shift down, move cursor only.
Backspace Delete character before cursor

Highlighting works as follows:
Any printable key deletes the highlighting before starting to insert /
overwrite, leaving the cursor at the leftmost of the anchor / cursor.
Delete or backspace deletes the highlighted area.

On entry:
AX		 Int 16h keycode to process (flags in KEY_FLAG)
DGROUP:DI ==>	 DEDIT_STR

On exit:
CF=1		 It was our keycode
CF=0		 We don't want the keycode; take it elsewhere

|

	 pusha			; Save

	 push	 CURSOR_SHAPE	; Current shape / attributes
	 call	 SETCSR 	; Reveal the cursor

; Register usage:
;  AX=keycode
;  CX=bytes remaining in buffer
;  DGROUP:SI ==> string at cursor
;  DGROUP:DI ==> DEDIT_STR
IFE_AGAIN:
	 mov	 si,DGROUP:[di].DEDIT_pszTXT ; Address start of string

	 mov	 cx,ax		; Save keycode

	 push	 si		; String to measure
	 call	 STRLEN 	; AX=length in bytes

	 xchg	 cx,ax		; Get string length

	 add	 si,DGROUP:[di].DEDIT_CURSOR ; Address string at cursor

	 sub	 cx,DGROUP:[di].DEDIT_TXTLEN ; Get -(space remaining)
	 neg	 cx		; Space remaining in buffer

; Check for editing keys.
	 push	 offset ds:IFEVAL ; Start of key code table
	 push	 offset ds:IFEACT ; Start of action table
	 push	 NIFEVAL	; Number of entries
	 call	 BRANCH_AX	; Return to action or here if not found

; If shift key is active, try shift key actions.
	 test	 KEY_FLAGS,@KEY_SHF ; Either shift key down?
	 jz	 short @F	; Jump if not

	 push	 offset ds:SIFEVAL ; Shifted key code table
	 push	 offset ds:SIFEACT ; Shifted key code action table
	 push	 NSIFEVAL	; Number of entries
	 call	 BRANCH_AX	; Return to action or here if not found

@@:
	 jmp	 IFE_CHKASCII	; Check for an ASCII character


IFE_LEFT:
	 mov	 bx,DGROUP:[di].DEDIT_CURSOR ; Get cursor position
	 sub	 bx,1		; Adjust it
	 jc	 near ptr IFE_STC ; Jump if we're already home

	 jmp	 short IFE_CURSOR ; Join common cursor movement code


IFE_RIGHT:
	 mov	 bx,DGROUP:[di].DEDIT_CURSOR ; Get cursor position
	 cmp	 DGROUP:[si].LO,1 ; Are we already at the end?
	 cmc			; CF=0 if so
	 adc	 bx,0		; Adjust cursor if not at the end

IFE_CURSOR:
	 xchg	 DGROUP:[di].DEDIT_CURSOR,bx ; Save new position

; If shift key wasn't down but is, save BX as anchor and turn on highlight.
; If shift key was down but isn't, turn off highlight.
; If no change, do nothing.
	 test	 KEY_FLAGS,@KEY_SHF ; Izit down now?
	 setnz	 al		; Save current state in AL

	 test	 DGROUP:[di].DEDIT_FLAGS,@ED_HIGH ; Was shift down previously?
	 setnz	 ah		; Save previous state in AH

	 xor	 al,ah		; Was there any change?
	 jz	 short @F	; Jump if not

	 btr	 DGROUP:[di].DEDIT_FLAGS,$ED_HIGH ; Turn off highlight
	 jc	 short @F	; Jump if we just released it

	 or	 DGROUP:[di].DEDIT_FLAGS,@ED_HIGH ; Show highlight
	 mov	 DGROUP:[di].DEDIT_ANCHOR,bx ; Save old cursor position
@@:
	 jmp	 IFE_STC	; Join common exit


IFE_HOME:
	 mov	 dx,DGROUP:[di].DEDIT_ANCHOR ; Get current anchor position
	 neg	 dx		; Move it home
	 sub	 bx,bx		; New cursor position
	 jmp	 short IFE_CURSOR ; Join common code


IFE_END:
	 mov	 bx,DGROUP:[di].DEDIT_pszTXT ; Start of text
	 add	 bx,DGROUP:[di].DEDIT_ANCHOR ; Text at anchor
	 push	 bx		; Start of string
	 call	 STRLEN 	; AX = bytes from anchor to end

	 mov	 dx,ax		; Amount to add
	 push	 si		; Offset of text at cursor
	 call	 STRLEN 	; AX = bytes from cursor to end

	 mov	 bx,DGROUP:[di].DEDIT_CURSOR ; Get cursor position
	 add	 bx,ax		; New cursor position
	 jmp	 short IFE_CURSOR ; Join common code


IFE_DEL:
	 mov	 bx,DGROUP:[di].DEDIT_CURSOR ; Get cursor position

	 btr	 DGROUP:[di].DEDIT_FLAGS,$ED_HIGH ; Is highlight active?
	 jnc	 short IFE_DELBX_1 ; Jump if not

; Starting from min (cursor, anchor), delete abs (anchor-cursor) bytes.
	 mov	 si,DGROUP:[di].DEDIT_ANCHOR ; Get current anchor
	 cmp	 bx,si		; Is anchor after cursor?
	 jb	 short @F	; Jump if so

	 xchg	 bx,si		; Get smaller of two in BX
@@:
	 mov	 DGROUP:[di].DEDIT_CURSOR,bx ; Save as cursor position
	 sub	 si,bx		; SI = how much to delete
	 jmp	 short IFE_DELBX ; Join common code to delete SI characters


IFE_INS:
	 mov	 dx,@CURSOR_THIN ; Assume insert mode
	 btc	 EDIT_FLAGS,$EDIT_OVER ; Toggle mode
	 jc	 short @F	; Jump if going back to insert mode

	 mov	 dx,@CURSOR_BLOCK ; Overwrite mode
@@:
	 mov	 CURSOR_SHAPE,dx ; Set new cursor shape

	 push	 dx		; Cursor shape / attributes
	 call	 SETCSR 	; Set new cursor
	 jmp	 short IFE_STC	; Join common exit


IFE_BS:
; Backspace with highlighting is the same as Delete
	 test	 DGROUP:[di].DEDIT_FLAGS,@ED_HIGH ; Is highlighting active?
	 jnz	 short IFE_DEL	; Join common delete code if so

	 mov	 bx,DGROUP:[di].DEDIT_CURSOR ; Get cursor position

	 or	 bx,bx		; Are we already home?
	 je	 short IFE_STC	; Jump if so

	 dec	 bx		; Back off to previous position
	 mov	 DGROUP:[di].DEDIT_CURSOR,bx ; Save as new cursor position
IFE_DELBX_1:
	 mov	 si,1		; Characters to delete
IFE_DELBX:
	 add	 bx,DGROUP:[di].DEDIT_pszTXT ; Skip to text base
	 or	 si,si		; Anything to delete?
	 jz	 short IFE_STC	; Jump if so (nothing to do)

IFE_DELBX_NEXT:
; Delete SI characters from string starting at DGROUP:BX
	 mov	 al,DGROUP:[bx+si].LO ; Get next character
	 mov	 DGROUP:[bx].LO,al ; Save it
	 inc	 bx		; Skip to next
	 or	 al,al		; Did we reach the end?
	 jnz	 short IFE_DELBX_NEXT ; Go around again if not

	 jmp	 short IFE_STC	; Join common exit


IFE_CHKASCII:
; Check for printable ASCII characters
	 cmp	 al,' '         ; Izit printable?
	 jb	 short IFE_CLC	; Jump if not

; If there's a highlighted area, delete it and adjust space remaining
	 btr	 DGROUP:[di].DEDIT_FLAGS,$ED_HIGH ; Is highlighting active?
	 jnc	 short IFE_XREPLACE ; Jump if not

	 REGSAVE <ax>		; Save character

	 mov	 bx,DGROUP:[di].DEDIT_CURSOR ; Get cursor position
	 cmp	 bx,DGROUP:[di].DEDIT_ANCHOR ; Izit the same?
	 je	 short IFE_REPLDONE ; Jump if so (nothing to do here)

	 mov	 si,DGROUP:[di].DEDIT_ANCHOR ; Get current anchor position
	 cmp	 bx,si		; Is anchor after cursor?
	 jb	 short @F	; Jump if so

	 xchg	 bx,si		; Move smaller value into BX
@@:
	 mov	 DGROUP:[di].DEDIT_CURSOR,bx ; Save as cursor position
	 sub	 si,bx		; SI = characters to delete
	 add	 cx,si		; Adjust count of space remaining
	 add	 bx,DGROUP:[di].DEDIT_pszTXT ; Skip to text base
@@:
	 mov	 al,DGROUP:[bx+si].LO ; Get next character
	 mov	 DGROUP:[bx].LO,al ; Save it
	 inc	 bx		; Skip to next
	 or	 al,al		; Did we reach the end?
	 jnz	 short @B	; Go around again if not

	 lea	 si,[bx-1]	; Save as new cursor offset in string

	 REGREST <ax>		; Restore

IFE_REPLDONE:
	 jmp	 IFE_AGAIN	; Recalculate cursor position and try again

IFE_XREPLACE:
; Insert AL at cursor position if there's room
	 jcxz	 IFE_STC	; Jump if no room in buffer

@@:
	 xchg	 DGROUP:[si].LO,al ; Save and get previous character
	 inc	 si		; Skip to next position
	 or	 al,al		; Izit the end?
	 jz	 short @F	; Jump if so

	 test	 EDIT_FLAGS,mask $EDIT_OVER ; Are we overwriting?
	 loopz	 short @B	; Go around again if not

	 jmp	 short IFE_BUMPCSR ; Adjust cursor position

@@:
	 mov	 DGROUP:[si].LO,al ; Save trailing NULL
IFE_BUMPCSR:
	 inc	 DGROUP:[di].DEDIT_CURSOR ; Update cursor position

IFE_STC:
; If the cursor starts before the window, slide it back.
	 mov	 bx,DGROUP:[di].DEDIT_CURSOR ; Get cursor position
	 cmp	 bx,DGROUP:[di].DEDIT_START ; Izit out of the display window?
	 jnb	 short @F	; Jump if not

	 mov	 DGROUP:[di].DEDIT_START,bx ; Adjust display window
@@:
; If the cursor is outside the window, move the start over
	 sub	 bx,DGROUP:[di].DEDIT_START ; BX=cursor offset from start
	 mov	 dx,DGROUP:[di].DEDIT_WIN.WIN_NCOLS ; Size of window
	 sub	 dx,1+1 	; ...less margins
	 sub	 bx,dx		; BX=how far we've overrun the window
	 jbe	 short IFE_STC2 ; Jump if we're still within bounds

	 add	 DGROUP:[di].DEDIT_START,bx ; Adjust start of window
IFE_STC2:
	 stc			; Yes, we'll take this one
	 jmp	 short IFE_EXIT ; Join common exit code

IFE_CLC:
	 clc			; Not our keycode

IFE_EXIT:
	 popa			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INP_FOCEDIT endp		; End INP_FOCEDIT procedure
	 NPPROC  INP_FOCBTN -- Focused input processor for window button
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process focused input for a window button.

On entry:
AX		 Int 16h keycode to process
DGROUP:DI ==>	 BTN_STR

On exit:
CF=1		 It was our keycode
CF=0		 We don't want the keycode; take it elsewhere

|

; ENTER on a default window button selects it
	 test	 DGROUP:[di].BTN_FLAGS,@BTN_DEFLT ; Izit the default button?
	 jz	 short IFB_CLC	; Jump if not

	 cmp	 ax,@KEY_CR	; Izit the select button?
	 jne	 short IFB_CLC	; Jump if not

	 mov	 ax,DGROUP:[di].BTN_TRIG.TRIG_KEYS[0] ; Substitute first trigger
IFB_CLC:
	 clc			; Not our keycode
IFB_EXIT:

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INP_FOCBTN endp 		; End INP_FOCBTN procedure
	 NPPROC  INP_FOCRADIO -- Focused input processor for radio buttons
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process focused input for radio buttons.

The following keys have special significance in a radio button group
that has the current focus:
SPACE	 Turn default (highlighted) button on (select it)
UP	 Decrement current default button (no wrap)
DOWN	 Increment current default button (no wrap)

We'll also check all button triggers, including ASCII ones.

On entry:
AX		 Int 16h keycode to process
DGROUP:DI ==>	 RADIO_STR
DGROUP:BX ==>	 DIALOG_STR

On exit:
CF=1		 It was our keycode
CF=0		 We don't want the keycode; take it elsewhere

|

	 REGSAVE <bx,cx,dx,si,di,bp> ; Save

; Save current focus so we can check for hotkeys in unfocused groups.
	 sub	 cx,cx		; Clear high byte
	 cmp	 di,DGROUP:[bx].DIALOG_FOCUS ; Do we have the focus?
	 sete	 cl		; CX=1 if so
	 mov	 bp,cx		; Save for later

; Find highlighted button and look for hot keys.
	 mov	 cx,DGROUP:[di].RADIO_NBTNS ; Get number of buttons
	 lea	 bx,DGROUP:[di].RADIO_pBTN ; DGROUP:BX ==> First button
	 mov	 dx,bx		; Initialize highlighted offset
	 mov	 si,bx		; ...	     selected	 ...
IFRADIO_NEXTBTN:
; Note that a button may be both highlighted and selected
	 test	 DGROUP:[bx].RBTN_FLAGS,@BTN_DEFLT ; Izit highlighted?
	 jz	 short @F	; Jump if so

	 mov	 dx,bx		; Save offset
@@:
	 test	 DGROUP:[bx].RBTN_FLAGS,@BTN_SEL ; Izit selected?
	 jz	 short @F	; Jump if so

	 mov	 si,bx		; Save offset
@@:
; Check for hot keys.  If we get one, BX becomes selected and highlighted.
	 REGSAVE <cx,di>	; Save

	 lea	 di,DGROUP:[bx].RBTN_TRIG ; DGROUP:DI ==> trigger list
	 mov	 cx,4		; Maximum triggers to check
@@:
	 cmp	 DGROUP:[di].ELO,1 ; Izit empty?
	 jb	 short @F	; Jump if so

	 scas	 DGROUP:[di].ELO ; Compare AX with trigger
	 loopne  @B		; Try again if no match

@@:
	 REGREST <di,cx>	; Restore

	 jne	 short @F	; Jump if no hotkey found

	 mov	 bp,bx		; Save RBTN_STR to highlight
@@:
	 add	 bx,size RBTN_STR ; Skip to next button
	 loop	 IFRADIO_NEXTBTN ; Go around again

	 mov	 bx,dx		; Copy highlighted button to base register
; DGROUP:BX ==> RBTN_STR for highlighted button
; DGROUP:SI ==> RBTN_STR for selected button

; If we got a hotkey, switch to it
	 cmp	 bp,1		; BP=0 means no hotkey, no focus
	 jb	 short IFRADIO_CLC ; Jump if nothing to do

	 je	 short @F	; Jump if focus but no hotkey

	 mov	 bx,bp		; DGROUP:BX ==> new button to select
	 and	 DGROUP:[si].RBTN_FLAGS,not (@BTN_SEL or @BTN_DEFLT) ; Turn
				; previous one off
	 or	 DGROUP:[bx].RBTN_FLAGS,@BTN_SEL or @BTN_DEFLT ; Turn this
				; one on
	 jmp	 short IFRADIO_KEEP ; Join common exit

@@:
	 cmp	 al,' '         ; Izit turn this one on?
	 jne	 short @F	; Jump if not

IFRADIO_NEWON:
	 and	 DGROUP:[si].RBTN_FLAGS,not @BTN_SEL ; Turn previous one off
	 or	 DGROUP:[bx].RBTN_FLAGS,@BTN_SEL ; Turn this one on
	 jmp	 short IFRADIO_KEEP ; Join common exit

@@:
; FIXME Use a scan table
	 lea	 dx,DGROUP:[di].RADIO_pBTN ; Get first button
	 imul	 cx,DGROUP:[di].RADIO_NBTNS,size RBTN_STR ; Last button + 1
	 sub	 cx,size RBTN_STR ; Last button offset
	 add	 cx,dx		; Add to base

	 cmp	 ax,@KEY_UP	; Izit highlight previous?
	 jne	 short @F	; Jump if not

	 cmp	 bx,dx		; Is this already the first?
	 jna	 short IFRADIO_KEEP ; If so, ignore it

	 lea	 si,[bx-size RBTN_STR] ; Back off to previous
	 jmp	 short IFRADIO_NEWDEF ; Set new default

@@:
	 cmp	 ax,@KEY_DN	; Izit highlight next?
	 jne	 short @F	; Jump if not

	 lea	 si,[bx+size RBTN_STR] ; Skip to next
	 cmp	 si,cx		; Are we in range?
	 ja	 short IFRADIO_KEEP ; Ignore if not

	 jmp	 short IFRADIO_NEWDEF ; Set new default
@@:
	 cmp	 ax,@KEY_HOME	; Izit highlight first?
	 jne	 short @F	; Jump if not

	 mov	 si,dx		; First button
	 jmp	 short IFRADIO_NEWDEF ; Set new default

@@:
	 cmp	 ax,@KEY_END	; Izit highlight last?
	 jne	 short IFRADIO_CLC ; Jump if not

	 mov	 si,cx		; Last button
IFRADIO_NEWDEF:
	 and	 DGROUP:[bx].RBTN_FLAGS,not @BTN_DEFLT ; No longer default
	 or	 DGROUP:[si].RBTN_FLAGS,@BTN_DEFLT ; Make this the default
	 jmp	 short IFRADIO_KEEP ; Join common exit

IFRADIO_CLC:
	 clc			; Not our keycode

	 jmp	 short IFRADIO_EXIT ; Join common exit

IFRADIO_KEEP:
	 stc			; This was ours; let us keep it

IFRADIO_EXIT:
	 REGREST <bp,di,si,dx,cx,bx> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INP_FOCRADIO endp		; End INP_FOCRADIO procedure
	 NPPROC  FIND_OBJ -- Convert object pointer to DLG_STR pointer
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the object in DIALOG_OBJ[] matching the specified object pointer
and return the DLG_STR pointer from DIALOG_OBJ[].

On entry:
DGROUP:BX ==>	DIALOG_STR
DGROUP:SI ==>	Object (TEXT_STR, DEDIT_STR, etc.)

On exit:
DGROUP:SI ==>	DLG_STR

|

	 REGSAVE <cx,di>	; Save

	 mov	 di,si		; Save object pointer

	 mov	 cx,DGROUP:[bx].DIALOG_NOBJ ; Number of objects
	 lea	 si,DGROUP:[bx].DIALOG_OBJ ; Address first one
@@:
	 cmp	 DGROUP:[si].DLGOBJ_pOBJ,di ; Is this it?
	 je	 short @F	; Jump if so

	 add	 si,size DLGOBJ_STR ; Skip to next object
	 loop	 @B		; Go around again if not found

	 int	 3		; We should never get here
@@:
	 REGREST <di,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_OBJ endp			; End FIND_OBJ procedure
	 NPPROC  DRAW_SI -- Redraw object at DGROUP:SI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Redraw one object at DGROUP:SI.  We'll need to find the object type.

On entry:
DGROUP:BX ==>	DIALOG_STR
DGROUP:SI ==>	Object (TEXT_STR, DEDIT_STR, etc.)

|

	 REGSAVE <ax,si,di>	; Save

	 mov	 di,si		; Address object for DLG_DISP[]
	 call	 FIND_OBJ	; Convert DGROUP:SI ==> object to ==> DLG_STR

	 imul	 si,DGROUP:[si].DLGOBJ_TYPE,type DLG_DISP ; Index DLG_DISP
	 sub	 ax,ax		; Don't redisplay entire object
	 call	 DLG_DISP[si]	; Redisplay object that got focus

	 REGREST <di,si,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DRAW_SI  endp			; End DRAW_SI procedure
	 NPPROC  GET_DLG -- Get dialog box response
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process response for a dialog box until we get a window button.
Track focus and display of objects.

On entry:
DGROUP:BX ==>	DIALOG_STR

On exit:
AX		First trigger for selected window button

|

GDLG_STR struc			; Local variables for GET_DLG
GDLG_pFOCOBJ dw  ?		; Pointer to DLGOBJ_STR for current focus
GDLG_FOCTYPE dw  ?		; Object type of focus
GDLG_pOBJFIRST dw ?		; First DLGOBJ_STR pointer
GDLG_pOBJLAST dw ?		; Last DLGOBJ_STR pointer
GDLG_STR ends

	 push	 bp		; Prepare to address stack
	 sub	 sp,size GDLG_STR ; Allocate space for local variables
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <cx,dx,si,di,es> ; Save

	 push	 ds		; Get DGROUP selector
	 pop	 es		; Address for string ops
	 assume  es:DGROUP	; Tell the assembler

	 cld			; Forward direction for string ops
GET_DLG_KEY:
	 call	 GETKEYXLT	; Wait for a key

; Turn off cursor in case edit field lost focus
	 push	 @CURSOR_HIDE	; Make cursor invisible
	 call	 SETCSR 	; Set cursor shape / attributes

; First pass the key to the object with the current focus
	 mov	 cx,DGROUP:[bx].DIALOG_NOBJ ; Number of objects
	 lea	 si,DGROUP:[bx].DIALOG_OBJ ; Address first one
	 mov	 [bp].GDLG_pOBJFIRST,si ; Save for later
	 mov	 di,DGROUP:[bx].DIALOG_FOCUS ; Current focus
	 mov	 [bp].GDLG_pFOCOBJ,di ; Save for redraw
	 mov	 dx,si		; Initialize focus pointer
GET_DLG1:
	 cmp	 DGROUP:[si].DLGOBJ_pOBJ,di ; Is this it?
	 jne	 short @F	; Jump if not

	 mov	 dx,si		; Save it
@@:
	 mov	 [bp].GDLG_pOBJLAST,si ; Save last object pointer

	 add	 si,size DLGOBJ_STR ; Skip to next object
	 loop	 GET_DLG1	; Go around again

	 mov	 si,dx		; Set up DLGOBJ_STR pointer
GET_DLG1_FOCUS:
; DGROUP:SI ==> DLGOBJ_STR
; DGROUP:DI ==> Object
; AX = key to process
	 mov	 [bp].GDLG_pFOCOBJ,si ; Save DLGOBJ_STR pointer
	 mov	 si,DGROUP:[si].DLGOBJ_TYPE ; Get type index
	 mov	 [bp].GDLG_FOCTYPE,si ; Save for later
	 shl	 si,1		; Convert to word index
	 call	 pfnFOCUS[si]	; Call focused input processor
	 jc	 near ptr GET_DLG_REDRAW ; Jump if we did something with it
				; (Note: DI ==> current focus)

; If the object didn't do anything with it, check window buttons for
; triggers.  Note that ASCII triggers are only effective when we have
; focus; we've just checked for that above.
	 mov	 dx,DGROUP:[bx].DIALOG_NOBJ ; Number of objects
	 lea	 si,DGROUP:[bx].DIALOG_OBJ ; Address first one

GET_DLG2:
	 cmp	 DGROUP:[si].DLGOBJ_TYPE,@DLG_BTN ; Izit a window button?
	 jne	 short GET_DLG2_LOOP ; Jump if not

	 mov	 di,DGROUP:[si].DLGOBJ_pOBJ ; DGROUP:DI ==> BTN_STR
	 lea	 di,DGROUP:[di].BTN_TRIG[0] ; DGROUP:DI ==> TRIGGER_STR
	 mov	 cx,4		; Maximum number of triggers
@@:
	 cmp	 DGROUP:[di].HI,0 ; Izit the end?
	 je	 short GET_DLG2_LOOP ; Jump if so

	 scas	 DGROUP:[di].ELO ; Compare trigger
	 loopne  @B		; Go around again if mismatch

	 jne	 short GET_DLG2_LOOP ; Jump if no match

; FIXME Show button as pushed

; Return first trigger
	 mov	 di,DGROUP:[si].DLGOBJ_pOBJ ; DGROUP:DI ==> BTN_STR
	 mov	 ax,DGROUP:[di].BTN_TRIG[0] ; Return value
	 jmp	 GET_DLG_EXIT	; Join common exit

GET_DLG2_LOOP:
	 add	 si,size DLGOBJ_STR ; Skip to next object

	 dec	 dx		; Adjust loop counter
	 jnz	 short GET_DLG2 ; Go around again if more objects

; Check for a hotkey change of focus to an edit field or radio button
	 mov	 dx,DGROUP:[bx].DIALOG_NOBJ ; Number of objects
	 lea	 si,DGROUP:[bx].DIALOG_OBJ ; Address first one
GET_DLG3:
	 lea	 di,DGROUP:[0].DEDIT_TRIG[0] ; Additional offset for triggers
	 cmp	 DGROUP:[si].DLGOBJ_TYPE,@DLG_EDIT ; Izit edit text?
	 je	 short @F	; Jump if so

	 lea	 di,DGROUP:[0].RADIO_TRIG[0] ; Radio triggers
	 cmp	 DGROUP:[si].DLGOBJ_TYPE,@DLG_RADIO ; Izit a radio button group?
	 jne	 short GET_DLG3_LOOP ; Jump if not

@@:
	 add	 di,DGROUP:[si].DLGOBJ_pOBJ ; DGROUP:DI ==> TRIGGER_STR

	 mov	 cx,4		; Maximum number of triggers
@@:
	 cmp	 DGROUP:[di].HI,0 ; Izit the end?
	 je	 short GET_DLG3_CHKRAD ; Jump if so

	 scas	 DGROUP:[di].ELO ; Compare trigger
	 loopne  @B		; Go around again if mismatch

	 jne	 short GET_DLG3_CHKRAD ; Continue if no match

; If it's an edit field we're switching to, make sure it's visible.
	 cmp	 DGROUP:[si].DLGOBJ_TYPE,@DLG_EDIT ; Izit edit text?
	 jne	 short GET_DLG3_NEWFOCUS ; Jump if not

	 mov	 di,DGROUP:[si].DLGOBJ_pOBJ ; Get offset of object record
	 test	 DGROUP:[di].DEDIT_FLAGS,@ED_HID ; Are we hiding?
	 jnz	 short GET_DLG3_LOOP ; Skip if so

	 jmp	 short GET_DLG3_NEWFOCUS ; Set new focus to SI

GET_DLG3_CHKRAD:
; If it's a radio button, we need to check the hotkeys for each button
; in the group.  If one of the hotkeys has been pressed, we not only
; need to select the appropriate radio button, we need to switch focus.
	 cmp	 DGROUP:[si].DLGOBJ_TYPE,@DLG_RADIO ; Izit a radio button group?
	 jne	 short GET_DLG3_LOOP ; Jump if not

	 mov	 di,DGROUP:[si].DLGOBJ_pOBJ ; DGROUP:DI ==> RADIO_STR
	 call	 INP_FOCRADIO	; Check for hotkeys in this group
	 jnc	 short GET_DLG3_LOOP ; Jump if none found

; We've already handled the button selection in INP_FOCRADIO.  Change focus too.
GET_DLG3_NEWFOCUS:
; DGROUP:SI ==> DLGOBJ_STR to switch to
	 mov	 di,DGROUP:[si].DLGOBJ_pOBJ ; Get offset of object record
	 jmp	 short GET_DLG_REDRAW ; Join code to redisplay

GET_DLG3_LOOP:
	 add	 si,size DLGOBJ_STR ; Skip to next object

	 dec	 dx		; Adjust loop counter
	 jnz	 short GET_DLG3 ; Go around again if more objects


; Process TAB and Shift-TAB changes of focus
GET_DLG4:
	 mov	 dx,size DLGOBJ_STR ; Assume TAB
	 cmp	 ax,@KEY_TAB	; Izit TAB?
	 je	 short @F	; Good guess

	 neg	 dx		; Reverse direction
	 cmp	 ax,@KEY_SHF_TAB ; Izit Shift-TAB?
	 jne	 short GET_DLG5 ; Jump if not

@@:
	 mov	 si,[bp].GDLG_pFOCOBJ ; Get current focus
	 cmp	 DGROUP:[si].DLGOBJ_TYPE,@DLG_TEXT ; Izit only objects that
				; can't ever have focus?
	 je	 short GET_DLG5 ; Ignore it if so

GET_DLG4A:
	 add	 si,dx		; Point to new focus
	 cmp	 si,[bp].GDLG_pOBJFIRST ; Did we underflow?
	 jnb	 short @F	; Jump if not

	 mov	 si,[bp].GDLG_pOBJLAST ; Wrap back to last
@@:
	 cmp	 si,[bp].GDLG_pOBJLAST ; Did we overflow?
	 jna	 short @F	; Jump if not

	 mov	 si,[bp].GDLG_pOBJFIRST ; Wrap back to first
@@:
; If this is not an object that supports tab stops, keep going.
	 cmp	 DGROUP:[si].DLGOBJ_TYPE,@DLG_TEXT ; Izit static text?
	 je	 short GET_DLG4A ; Go around again if so

; If the new object is an edit field, make sure it's visible.
	 cmp	 DGROUP:[si].DLGOBJ_TYPE,@DLG_EDIT ; Izit an edit field?
	 jne	 short @F	; Jump if not

	 mov	 di,DGROUP:[si].DLGOBJ_pOBJ ; Address DEDIT_STR
	 test	 DGROUP:[di].DEDIT_FLAGS,@ED_HID ; Are we hiding?
	 jnz	 short GET_DLG4A ; Skip if so

@@:
; If we're switching from one window button to another, change the default.
	 mov	 di,[bp].GDLG_pFOCOBJ ; DGROUP:DI ==> DLGOBJ_STR
	 mov	 dx,DGROUP:[si].DLGOBJ_TYPE ; Get type for new focus holder
	 mov	 si,DGROUP:[si].DLGOBJ_pOBJ ; Get data pointer

	 cmp	 dx,@DLG_BTN	; Are we switching to a window button?
	 jne	 short @F	; Jump if not

	 cmp	 DGROUP:[di].DLGOBJ_TYPE,dx ; Switching from a window button?
	 jne	 short @F	; Jump if not

	 mov	 di,DGROUP:[di].DLGOBJ_pOBJ ; Address BTN_STR
	 and	 DGROUP:[di].BTN_FLAGS,not @BTN_DEFLT ; Lose the chevrons...
	 or	 DGROUP:[si].BTN_FLAGS,@BTN_DEFLT ; ...and move 'em here

@@:
	 mov	 di,si		; DGROUP:DI ==> new focus object
	 jmp	 short GET_DLG_REDRAW ; Join code to redisplay

; Ignore NOP keys
GET_DLG5:
	 jmp	 GET_DLG_KEY	; Go around again

GET_DLG_REDRAW:
; FIXME This should be handled by a callback.
; FIXME The callback should get both current and new focus, and can
; FIXME manually redisplay anything else it wants.
; If and only if we're sending to the printer, hide file name field.
	 mov	 ax,EDIT_FNAME.DEDIT_FLAGS ; Get current state
	 and	 EDIT_FNAME.DEDIT_FLAGS,not @ED_HID ; Assume we're not hiding
	 test	 RBTN_OUPRINT.RBTN_FLAGS,@BTN_SEL ; Are we printing?
	 jz	 short @F	; Jump if so

	 or	 EDIT_FNAME.DEDIT_FLAGS,@ED_HID ; Hide the filename
@@:
	 xor	 ax,EDIT_FNAME.DEDIT_FLAGS ; Set @ED_HID in AX if transition
	 test	 ax,@ED_HID	; Did we change hidden/unhidden state?
	 jz	 short @F	; Jump if not

	 lea	 si,EDIT_FNAME	; Address object to redisplay
	 cmp	 si,di		; Izit the one we're changing focus to?
	 je	 short @F	; Jump if so

	 cmp	 si,DGROUP:[bx].DIALOG_FOCUS ; Izit the one we're changing from?
	 je	 short @F	; Jump if so

	 call	 DRAW_SI	; Redraw DGROUP:SI
@@:
; FIXME End application specific code
; DGROUP:DI ==> new object for focus
	 mov	 si,di		; Copy it
	 xchg	 DGROUP:[bx].DIALOG_FOCUS,di ; Save as new focus

	 cmp	 si,di		; Did it change?
	 je	 short GET_DLG_XFCHG ; Jump if not

; If we're going from a window button to a non-window button, turn off the
; @BTN_DEFLT attribute.  If there's a window button with the @BTN_WDEF
; attribute, make that the new default.
	 cmp	 [bp].GDLG_FOCTYPE,@DLG_BTN ; Are we leaving a window button?
	 jne	 short GET_DLG_XWBLF ; Jump if not [window button losing focus]

	 call	 FIND_OBJ	; DGROUP:SI ==> new focus DLGOBJ_STR
	 cmp	 DGROUP:[si].DLGOBJ_TYPE,@DLG_BTN ; Are we going to a button?
	 je	 short GET_DLG_XWBLF ; Jump if not

; DGROUP:DI ==> BTN_STR for window button that's losing focus.
	 and	 DGROUP:[di].BTN_FLAGS,not @BTN_DEFLT ; Turn off default

; Find any window button with @BTN_WDEF and make that the new default
	 push	 di		; Save

	 mov	 cx,DGROUP:[bx].DIALOG_NOBJ ; Get number of objects
	 lea	 si,DGROUP:[bx].DIALOG_OBJ ; Address first one
GET_DLG_WBNEXT:
	 cmp	 DGROUP:[si].DLGOBJ_TYPE,@DLG_BTN ; Izit a window button?
	 jne	 short GET_DLG_WBLOOP ; Jump if not

	 mov	 di,DGROUP:[si].DLGOBJ_pOBJ ; DGROUP:DI ==> BTN_STR
	 test	 DGROUP:[di].BTN_FLAGS,@BTN_WDEF ; Izit a window default?
	 jz	 short GET_DLG_WBLOOP ; Jump if not

	 or	 DGROUP:[di].BTN_FLAGS,@BTN_DEFLT ; Make it the default

; If this isn't also the one we're leaving, redraw it.
	 cmp	 di,[bp].GDLG_pFOCOBJ ; Were we planning to redraw this one?
	 je	 short @F	; Jump if so

	 mov	 si,di		; DGROUP:SI ==> BTN_STR
	 call	 DRAW_SI	; Redisplay it

	 jmp	 short @F	; Bail out

GET_DLG_WBLOOP:
	 add	 si,size DLGOBJ_STR ; Skip to next
	 loop	 GET_DLG_WBNEXT ; Go around again

@@:
	 pop	 di		; Restore

GET_DLG_XWBLF:
	 imul	 si,[bp].GDLG_FOCTYPE,type DLG_DISP ; Index DLG_DISP
	 sub	 ax,ax		; Don't redisplay entire object
	 call	 DLG_DISP[si]	; Redisplay object that lost focus
GET_DLG_XFCHG:
	 mov	 si,DGROUP:[bx].DIALOG_FOCUS ; Get new focus
	 call	 DRAW_SI	; Redraw DGROUP:SI

	 jmp	 GET_DLG_KEY	; Go around again

GET_DLG_EXIT:
; Turn off cursor in case focus was on edit field
	 push	 @CURSOR_HIDE	; Make cursor invisible
	 call	 SETCSR 	; Set cursor shape / attributes

	 REGREST <es,di,si,dx,cx> ; Restore
	 assume  es:nothing	; Tell the assembler

	 add	 sp,size GDLG_STR ; Strip local variables from stack
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_DLG endp			; End GET_DLG procedure
	 NPPROC  GETKEYXLT -- Get and translate key
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get key scancode and translate to reduce synonymous scancodes
(such as those generated on the 101-key layout for arrow keys).

Save flags globally so we can check for shift keys, etc.

On exit:
AX	 Translated scancode

|

	 REGSAVE <cx,si>	; Save

	 call	 GETKEY 	; Get key scancode in AX

	 push	 ax		; Save

	 KEYCALL @GETSHF	; Return flags in AL
	 sub	 ah,ah		; Don't assume we have extended flags
	 mov	 KEY_FLAGS,ax	; Save globally

	 pop	 ax		; Restore scan code

	 or	 ah,ah		; Izit Alt-224 (possibly)?
	 jz	 short @F	; Jump if so

	 cmp	 al,0E0h	; Izit an extended key code?
	 jne	 short @F	; Jump if not

	 sub	 al,al		; Convert to normal key code
@@:
	 REGREST <si,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETKEYXLT endp			; End GETKEYXLT procedure
	 NPPROC  CHECK_CANKEY -- Check for cancel button pressed
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

While printing, we want to check periodically for keyboard activity
so the user can bail out.

On exit:
CF=1	 Stop the presses
CF=0	 OK to continue

|

	 REGSAVE <ax,cx,di>	; Save

	 call	 CHKNDKEY	; Is there a keystroke available?
	 jz	 short @F	; Jump if not (note CF=0)

	 call	 GETKEYXLT	; Return key scancode in AX

; We'll just check for cancel triggers...
	 lea	 di,BTN_CCANCEL.BTN_TRIG ; Address triggers
	 mov	 cx,3		; Number to look for
   repne scas	 BTN_CCANCEL.BTN_TRIG[di] ; Look for a trigger

	 stc			; Assume we found one
	 je	 short @F	; Jump if we should cancel

	 clc			; OK to continue
@@:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CANKEY endp		; End CHECK_CANKEY procedure
	 NPPROC  PLINE_SUB -- Send DGROUP:SI to PHANDLE for CX bytes
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Send DGROUP:SI to PHANDLE (a file handle or -LPTn) for CX bytes.

On entry:
DGROUP:SI ==>	 String to send
CX		 Bytes to send

On exit:
CF=0		 Success
CF=1		 Error occurred; error code or status in AX/AH

|

	 REGSAVE <bx,cx,dx,si>	; Save

	 cld			; String ops forwardly

	 mov	 bx,PHANDLE	; Get file handle or -1
	 cmp	 bx,0		; Are we printing to a file handle?
	 jl	 short @F	; Jump if not

	 mov	 dx,si		; DGROUP:DX ==> text to send to file
	 DOSCALL @WRITF2	; Write CX bytes from DS:DX to file BX
	 jmp	 short PLSUB_EXIT ; Join common code (CF significant)

@@:
	 not	 bx		; One's complement negation (LPTn origin:0)
	 mov	 dx,bx		; Printer port for Int 17h call
@@:
	 sub	 ah,ah		; Int 17h function 0: print AL to DX
	 lods	 DGROUP:[si].LO ; Get next character
	 int	 17h		; Return status in AH
	 test	 ah,00101001b	; Out of paper, I/O error, or time out?
	 loopz	 @B		; Go around again if OK

	 jz	 short PLSUB_EXIT ; Jump if no errors (note CF=0)

PLSUB_ERR:
	 stc			; Indicate failure
PLSUB_EXIT:
	 REGREST <si,dx,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PLINE_SUB endp			; End PLINE_SUB procedure
	 NPPROC  PRINT_LINE -- Send a line to the printer
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for conditions where we need to print a page header.
Send line to printer after trimming trailing blanks if there's no
trailing NULL.	Add CR,LF.

On exit:
CF=1	 An error occurred

|

PLINE_STR struc

	 dw	 ?		; Caller's BP
PLINE_FLAGS dw	 ?		; Caller's flags
	 dw	 ?		; Caller's IP
PLINE_ps dw	 ?		; Near pointer to string (not always ASCIIZ)
PLINE_NCOLS dw	 ?		; Maximum length to send

PLINE_STR ends

	 clc			; Assume success
	 pushf			; Preserve DF

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 pusha			; Save GP registers

; If there's a trailing NULL, it's an ASCIIZ string.  If not, we need to
; eliminate trailing blanks.
	 mov	 cx,[bp].PLINE_NCOLS ; How far to look
	 sub	 al,al		; What to look for
	 cld			; String ops forwardly
	 mov	 di,[bp].PLINE_ps ; DGROUP:DI ==> start of line
   repne scas	 DGROUP:[di].LO ; Search for trailing NUL
	 jne	 short @F	; Jump if not found

	 dec	 di		; Count out trailing NUL
	 sub	 di,[bp].PLINE_ps ; DI = actual length
	 mov	 cx,di		; Bytes to send
	 jmp	 short PRINT_LINE_START ; Join common code

@@:
; Find last non-space character.
	 mov	 di,[bp].PLINE_ps ; Get start of line
	 mov	 cx,[bp].PLINE_NCOLS ; How far to look

	 push	 di		; Save start of line

	 add	 di,cx		; Skip to end
	 dec	 di		; DGROUP:DI ==> Last character on this line
	 std			; Scan backwards
	 mov	 al,' '         ; What to skip
    repe scas	 DGROUP:[di].LO ; Find last non-blank character
	 setnz	 cl		; CX=1 if we didn't go all the way
	 inc	 cx		; CX=# to add for end+1
	 add	 cx,di		; DGROUP:CX ==> end character + 1

	 pop	 di		; Get start of line
	 sub	 cx,di		; Number of characters to send
PRINT_LINE_START:
; Check for conditions where we need to start a new page
	 cmp	 CURLINE,@MAXLINES ; Are we below the limit?
	 jb	 short PRINT_LINE_CHKPAGE ; Jump if so

	 push	 cx		; Save for a moment

	 mov	 cx,1		; Characters to send
	 lea	 si,MSG_FF	; ASCII form feed
	 call	 PLINE_SUB	; Send DGROUP:SI for CX bytes to PHANDLE

	 pop	 cx		; Restore

	 jc	 short PRINT_LINE_ERR ; Jump if error

	 inc	 CURPAGE	; Bump page number
	 mov	 CURLINE,0	; Reset line counter
PRINT_LINE_CHKPAGE:
; Check for conditions where we need to print a page header
	 cmp	 CURLINE,0	; Have we dumped the header yet?
	 jne	 short @F	; Jump if so

; Format page number
	 mov	 ax,CURPAGE	; Current page number
	 lea	 di,MSG_PRINTC2P ; Page number to display
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 lea	 di,MSG_PHEADERP ; Page number for header
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 lea	 bx,PRINTCANDLG ; "Printing in progress" dialog
	 call	 DRAW_DLG	; Display dialog DGROUP:BX

	 push	 cx		; Save count

	 mov	 cx,@MSG_PHEADERLEN ; Bytes to send
	 lea	 si,MSG_PHEADER ; Start of header
	 call	 PLINE_SUB	; Send DGROUP:SI for CX bytes to PHANDLE

	 pop	 cx		; Restore

	 jc	 short PRINT_LINE_ERR ; Jump if error occurred

	 add	 CURLINE,@MSG_PHEADERLINES ; Add to line count
@@:
	 jcxz	 @F		; Jump if line is empty

	 mov	 si,[bp].PLINE_ps ; DGROUP:SI ==> start of line
	 call	 PLINE_SUB	; Send DGROUP:SI for CX bytes to PHANDLE
	 jc	 short PRINT_LINE_ERR ; Jump if error occurred

@@:
; Add CR,LF and we're done.
	 lea	 si,MSG_CRLF2	; Line ending
	 mov	 cx,2		; Bytes to send
	 call	 PLINE_SUB	; Send DGROUP:SI for CX bytes to PHANDLE
	 jc	 short PRINT_LINE_ERR ; Jump if error occurred

	 inc	 CURLINE	; Bump line count
	 jmp	 short PRINT_LINE_EXIT ; Join common exit

PRINT_LINE_ERR:
	 or	 [bp].PLINE_FLAGS,mask $CF ; Set CF on return to indicate error
PRINT_LINE_EXIT:
	 popa			; Restore GP registers

	 pop	 bp		; Restore

	 popf			; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PRINT_LINE endp 		; End PRINT_LINE procedure
	 NPPROC  DO_PRINT -- Display print dialog and get options
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display print dialog and get print options

This routine runs in Protected Mode.

|

	 REGSAVE <bx,ecx,esi,edi,es,gs> ; Save

; If we're viewing help while testing is in progress, F2 is effectively
; disabled.
	 test	 GL2_FLAG,@GL2_ACTIV ; Are we active?
	 jnz	 near ptr DO_PRINT_EXIT ; Jump if so

; Since we're doing this only when testing is not in progress, we can
; use some of the allocated memory to save the screen.
	 cld			; String ops forwardly

	 mov	 ecx,25*80*2	; Bytes needed for screen
	 mov	 eax,ecx	; Pass as allocation request
	 call	 GET_MEM	; AGROUP:EAX ==> block to use
	 jc	 near ptr DO_PRINT_EXIT ; Jump if no memory found

	 mov	 es,SEL_4GB	; Get AGROUP data selector
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,eax	; AGROUP:EDI ==> Save destination
	 mov	 SCRSAVE,eax	; Save address

	 lgs	 esi,VIDBASE_FVEC ; GS:ESI ==> screen
	 assume  gs:nothing	; Tell the assembler

	 shr	 ecx,2-0	; Convert bytes to dword count
	 mov	 SCRCNT,ecx	; Dword count of data saved
S32  rep movs	 <AGROUP:[edi].EDD,gs:[esi].EDD> ; Copy screen to save buffer

	 mov	 PRINTDLG.DIALOG_FOCUS,offset DGROUP:RAD_WHAT ; Set initial focus
	 lea	 bx,PRINTDLG	; DGROUP:BX ==> dialog box
	 call	 DRAW_DLG	; Draw dialog DGROUP:BX

	 call	 GET_DLG	; Return dialog response in AX

; Restore screen contents
	 mov	 esi,SCRSAVE	; Get screen save buffer address
	 mov	 ecx,SCRCNT	; Get screen size in dwords

	 mov	 gs,SEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

	 les	 edi,VIDBASE_FVEC ; ES:EDI ==> screen
	 assume  es:nothing	; Tell the assembler

S32  rep movs	 <es:[edi].EDD,AGROUP:[esi].EDD> ; Restore screen contents

; Process dialog response
	 cmp	 ax,@KEY_ESC	; Did they cancel?
	 je	 near ptr DO_PRINT_EXIT ; Jump if so

	 mov	 PHANDLE,-1	; Assume no file I/O

; Put up "Cancel" dialog -- all they have to do is press ENTER or Esc
	 push	 ds		; Get DGROUP selector
	 pop	 es		; Address for DEC2BIN
	 assume  es:DGROUP	; Tell the assembler

	 mov	 CURPAGE,1	; Starting page number
	 mov	 CURLINE,0	; Starting line number

	 mov	 ax,CURPAGE	; Starting page
	 lea	 di,MSG_PRINTC2P ; Page number to display
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 lea	 bx,PRINTCANDLG ; "Printing in progress" dialog
	 call	 DRAW_DLG	; Display dialog DGROUP:BX

; Determine what to print
; We'll index ARR_W_HTOP, HLPTOPIC, and PHOPTTL

	 mov	 bx,HLPIND	; Assume this one
	 mov	 cx,1		; Just one topic, please

	 test	 RBTN_WHTHIS.RBTN_FLAGS,@BTN_SEL ; Is this one pushed?
	 jnz	 short @F	; Jump if so

	 sub	 bx,bx		; Start at the beginning
	 mov	 cx,@HLPIND_MEM ; Number of non-error topics to print
@@:
	 mov	 PHLPIND,bx	; Starting topic index
	 mov	 PHLPCNT,cx	; How many topics to print

; Determine type of printing to do
	 test	 RBTN_OUPRINT.RBTN_FLAGS,@BTN_SEL ; Is this one pushed?
	 jnz	 short DO_PRINT_XFILE ; Yes, so we're not doing file I/O

; Note that we can't have selected anything other than LPT1 if we're in
; protected mode other than via DPMI (VCPI, EPM).
	 test	 RBTN_OUFILE.RBTN_FLAGS,@BTN_SEL ; Overwrite existing file?
	 jnz	 short DO_PRINT_TRUNC ; Jump if so

; Attempt to open file read-write and seek to end

	 mov	 ax,@OPENF2*256 + 02h ; Read-write, sharing compatibility
	 lea	 dx,ETXT_FNAME	; DS:DX ==> ASCIIZ filename to open
	 DOSCALL		; AX = file handle
	 jnc	 short @F	; Jump if we succeeded

	 cmp	 ax,0002h	; Izit "File not found?"
	 je	 short DO_PRINT_TRUNC ; Try to create file if so

	 jmp	 DO_PRINT_PDONE ; Join common exit code

@@:
; Seek to end of file.

	 mov	 bx,ax		; Copy to handle register

	 mov	 ax,@MOVFP2*256 + 02h ; Seek relative to end of file
	 sub	 cx,cx		; Clear high word of offset
	 mov	 dx,cx		; Clear low word ...
	 DOSCALL		; DX:AX == length of file
;;;;;;;  jc	 ???		; Ignore seek error

	 mov	 ax,bx		; Get file handle
	 jmp	 short DO_PRINT_OPEN ; Join common code

; Truncate file, overwriting previous contents
DO_PRINT_TRUNC:
	 mov	 cx,0		; File attributes (normal)
	 DOSCALL @CREAF2,ETXT_FNAME ; AX = file handle
	 jc	 short DO_PRINT_PDONE ; Jump if we failed (quietly ignore error)

; AX contains handle for open file.
DO_PRINT_OPEN:
	 mov	 PHANDLE,ax	; Save file handle

DO_PRINT_XFILE:
; Send selected data to printer or file
	 call	 CHECK_CANKEY	; Check for cancel button
	 jc	 short DO_PRINT_CANCEL ; Jump if we should bail

	 imul	 bx,PHLPIND,type W_STR ; Get index into ARR_W_HTOP
	 imul	 si,PHLPIND,type PHTOPTTL ; Get index into help topic title ptrs
	 mov	 dx,ARR_W_HTOP[bx].WIN_NCOLS ; Get line width
	 push	 dx		; Pass maximum columns per line
	 push	 PHTOPTTL[si]	; String to dump
	 call	 PRINT_LINE	; Send to printer
	 jc	 short DO_PRINT_PDONE ; Jump if error occurred

	 imul	 si,PHLPIND,type HLPTOPIC ; Get index into help topic ptrs
	 mov	 si,HLPTOPIC[si] ; DGROUP:SI ==> start of first line
	 mov	 cx,ARR_W_HTOP[bx].WIN_NROWS ; Get number of lines

@@:
	 call	 CHECK_CANKEY	; Check for cancel button
	 jc	 short DO_PRINT_CANCEL ; Jump if we should bail

	 push	 dx		; Maximum columns to print
	 push	 si		; Current line offset
	 call	 PRINT_LINE	; Send to printer
	 jc	 short DO_PRINT_PDONE ; Jump if error occurred

	 add	 si,dx		; Skip to next line
	 loop	 @B		; Go around again

; See if we have more topics to print
	 inc	 PHLPIND	; Bump index
	 dec	 PHLPCNT	; Adjust outer loop counter
	 jz	 short DO_PRINT_CANCEL ; Jump if we're done

	 cmp	 CURLINE,0	; Did we print anything on this page?
	 je	 short @F	; Jump if not

	 mov	 CURLINE,@MAXLINES ; Force a page break
@@:
	 jmp	 short DO_PRINT_XFILE ; Go around again

DO_PRINT_CANCEL:
	 cmp	 CURLINE,0	; Have we put anything on this page?
	 je	 short DO_PRINT_PDONE ; Jump if not

	 mov	 cx,1		; Characters to send
	 lea	 si,MSG_FF	; ASCII form feed
	 call	 PLINE_SUB	; Send DGROUP:SI for CX bytes to PHANDLE

DO_PRINT_PDONE:
; Check for an open file
	 mov	 bx,PHANDLE	; Get file handle
	 cmp	 bx,-1		; Izit valid?
	 je	 short @F	; Jump if not

	 DOSCALL @CLOSF2	; Close it, ignoring error
	 mov	 PHANDLE,-1	; Mark as closed for debugging
@@:
; Restore screen contents (again)
	 mov	 esi,SCRSAVE	; Get screen save buffer address
	 mov	 ecx,SCRCNT	; Get screen size in dwords

	 mov	 gs,SEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

	 les	 edi,VIDBASE_FVEC ; ES:EDI ==> screen
	 assume  es:nothing	; Tell the assembler

S32  rep movs	 <es:[edi].EDD,AGROUP:[esi].EDD> ; Restore screen contents

DO_PRINT_EXIT:
	 REGREST <gs,es,edi,esi,ecx,bx> ; Restore
	 assume  es:DGROUP,gs:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DO_PRINT endp			; End DO_PRINT procedure
	 NPPROC  DISP_HELP -- Display Help Screen
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display help screen

This routine runs in Protected Mode.

If @GL3_RUNHELP is set, HELP_STATE is set to one of three states:
@HELP_NONE
@HELP_TITLES
@HELP_SCREEN
and AX contains the keystroke to process.

|

	 pusha			; Save all GP registers
	 push	 es		; Save segment register

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

; If we're running help while testing, we may already have gotten set up.
; unless we're displaying an error screen

	 test	 GL3_FLAG,@GL3_RUNHELP ; Are we active?
	 jz	 short @F	; Jump if not

	 cmp	 HELP_STATE,@HELP_NONE ; Are we entering for the first time?
	 je	 short @F	; Jump if so

	 cmp	 HELP_STATE,@HELP_TOPICS ; Are we displaying topics?
	 jne	 short HELP_NEXT2 ; Jump if not

	 jmp	 short HELP_START ; Redisplay topics in case we switched modes

; AX = @KEY_F1 - we don't need it
@@:
; Initialize the row indices for each help topic

	 mov	 cx,@HTOPIND	; Get # help topics
	 lea	 di,HTOPIND	; ES:DI ==> help topic row indices
	 xor	 ax,ax		; Initialize to zero
     rep stos	 HTOPIND[di]	; Initialize them

; If either a memory or parity error has occurred, go directly
; to that screen.

	 test	 GL2_FLAG,@GL2_MEMERR or @GL2_NMIERR ; Either error occur?
	 jnz	 near ptr HELP_CR ; Jump if so

; Display the help menu screen

HELP_START:
	 push	 ax		; Save in case we're redisplaying topics

	 mov	 al,HLPATTR	; Get help attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_HELP ; Pass address of local buffer
	 push	 offset ds:W_HELP ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display a shadow below and to the right of the help screen

	 push	 offset ds:W_HELP ; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

; Display the menu choices in a separate color

	 mov	 al,HLPBATTR	; Get background help line attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_HASK ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

	 pop	 ax		; Restore key code if redisplaying topics

	 jmp	 short HELP_NEXT2 ; Skip test for help while testing

HELP_NEXT:
	 test	 GL3_FLAG,@GL3_RUNHELP ; Are we testing?
	 jz	 short HELP_NEXT2 ; Jump if so (get another keystroke)

	 test	 GL2_FLAG,@GL2_HSCR ; Izit active?
	 jnz	 short @F	; Jump if so

	 mov	 al,HLPAATTR	; Get active help line attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_HLIN ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute
@@:
	 jmp	 DISP_HELP_EXIT ; Join common exit

HELP_NEXT2:
	 test	 GL2_FLAG,@GL2_HSCR ; Izit active?
	 jnz	 short @F	; Jump if so

	 push	 ax		; Save (in case it's a key code)

	 mov	 al,HLPAATTR	; Get active help line attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_HLIN ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

	 pop	 ax		; Restore key code
@@:
; If we're entering for the first time, that's all...
	 test	 GL3_FLAG,@GL3_RUNHELP ; Displaying help while testing?
	 jz	 short @F	; Jump if not

	 cmp	 HELP_STATE,@HELP_NONE ; Is this the first time?
	 jne	 short HELP_NEXTKEY ; No- process key code in AX

	 mov	 HELP_STATE,@HELP_TOPICS ; Set initial help state
	 jmp	 DISP_HELP_EXIT ; Join common exit

@@:
	 call	 GETKEY 	; Request a keystroke, return in AX
HELP_NEXTKEY:
	 lea	 di,HLPVAL	; ES:DI ==> valid keys
	 mov	 cx,NHLPVAL	; # valid keys
   repne scas	 HLPVAL[di]	; Search for it
	 jne	 short HELP_NEXT ; Jump if not found

	 test	 GL2_FLAG,@GL2_HSCR ; Izit active?
	 jnz	 short @F	; Jump if so

	 mov	 al,HLPBATTR	; Get background help line attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_HLIN ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute
@@:
	 sub	 di,(type HLPVAL) + offset es:HLPVAL ; Convert to origin-0

	 jmp	 HLPACT[di]	; Take appropriate action


HELP_PGUP:
	 test	 GL2_FLAG,@GL2_HSCR ; Is a help screen active?
	 jz	 short HELP_NEXT ; Jump if not

	 mov	 si,HLPIND	; Get the current topic index
	 shl	 si,1		; Times two to index table of words

	 sub	 HTOPIND[si],@HTXT_NROW ; Skip to previous page
	 jnc	 short @F	; Jump if not below the top

	 mov	 HTOPIND[si],0	; Back to the top
@@:
	 jmp	 HELP_TOPIC	; Join common code


HELP_PGDN:
	 test	 GL2_FLAG,@GL2_HSCR ; Is a help screen active?
	 jz	 near ptr HELP_NEXT ; Jump if not

	 mov	 si,HLPIND	; Get the current topic index
	 shl	 si,1		; Times two to index table of words

	 add	 HTOPIND[si],@HTXT_NROW ; Skip to the next page

	 jmp	 short HELP_DNCOM ; Join common code


HELP_UP:
	 test	 GL2_FLAG,@GL2_HSCR ; Is a help screen active?
	 jz	 short HELP_UP1 ; Jump if not

	 mov	 si,HLPIND	; Get the current topic index
	 shl	 si,1		; Times two to index table of words

	 sub	 HTOPIND[si],1	; Skip to previous line
	 jnc	 short @F	; Jump if not below the top

	 mov	 HTOPIND[si],0	; Back to the top
@@:
	 jmp	 HELP_TOPIC	; Join common code

HELP_UP1:
	 dec	 HLPIND 	; Skip to previous row
	 jns	 short @F	; Jump if no wrap

	 mov	 HLPIND,@HLIN_LEN - 1 ; Wrap to the end
@@:
	 jmp	 short HELP_COM ; Join common code

HELP_DN:
	 test	 GL2_FLAG,@GL2_HSCR ; Is a help screen active?
	 jz	 short HELP_DN1 ; Jump if not

	 mov	 si,HLPIND	; Get the current topic index
	 shl	 si,1		; Times two to index table of words

	 inc	 HTOPIND[si]	; Skip to next row
HELP_DNCOM:
	 imul	 bx,HLPIND,type W_STR ; Get index into ARR_W_HTOP
	 lea	 bx,ARR_W_HTOP[bx] ; Get offset of window descriptor

	 mov	 ax,DGROUP:[bx].NROW ; Get total # rows

	 sub	 ax,@HTXT_NROW	; Less a page's worth of lines
	 jae	 short @F	; Jump if it's within range

	 xor	 ax,ax		; Use maximum index
@@:

; AX has the maximum valid index

	 cmp	 ax,HTOPIND[si] ; Izit valid?
	 jae	 short @F	; Jump if so

	 mov	 HTOPIND[si],ax ; Save as maximum index
@@:
	 jmp	 HELP_TOPIC	; Join common code

HELP_DN1:
	 inc	 HLPIND 	; Skip to next row

	 cmp	 HLPIND,@HLIN_LEN - 1 ; Izit above the end?
	 jbe	 short @F	; Jump if no wrap

	 mov	 HLPIND,0	; Wrap to the start
@@:
HELP_COM:
	 mov	 ax,HLIN_SROW	; Wrap to the start
	 add	 ax,HLPIND	; Plus current index
	 mov	 W_HLIN.SROW,ax ; Save as new starting row

	 jmp	 HELP_NEXT	; Go around again


; Display the next help topic

HELP_NEXTTOP:
	 test	 GL2_FLAG,@GL2_MEMERR or @GL2_NMIERR ; Either error occur?
	 jnz	 near ptr HELP_NEXT ; Jump if so

	 test	 GL2_FLAG,@GL2_HSCR ; Izit active?
	 jz	 near ptr HELP_NEXT ; Jump if not

	 inc	 HLPIND 	; Skip to next row

	 cmp	 HLPIND,@HLIN_LEN - 1 ; Izit above the end?
	 jbe	 short @F	; Jump if no wrap

	 mov	 HLPIND,0	; Wrap to the start
@@:
	 jmp	 short HELP_TOPCOM ; Join common code


; Display the previous help topic

HELP_PREVTOP:
	 test	 GL2_FLAG,@GL2_MEMERR or @GL2_NMIERR ; Either error occur?
	 jnz	 near ptr HELP_NEXT ; Jump if so

	 test	 GL2_FLAG,@GL2_HSCR ; Izit active?
	 jz	 near ptr HELP_NEXT ; Jump if not

	 dec	 HLPIND 	; Skip to previous row
	 jns	 short @F	; Jump if no wrap

	 mov	 HLPIND,@HLIN_LEN - 1 ; Wrap to the end
@@:
HELP_TOPCOM:
	 mov	 ax,HLIN_SROW	; Wrap to the start
	 add	 ax,HLPIND	; Plus current index
	 mov	 W_HLIN.SROW,ax ; Save as new starting row

	 jmp	 short HELP_TOPIC ; Join common code


; Display the chosen help screen

HELP_CR:
	 test	 GL2_FLAG,@GL2_HSCR ; Izit active?
	 jnz	 near ptr HELP_NEXT ; Jump if so

	 test	 GL3_FLAG,@GL3_RUNHELP ; Are we displaying help during test?
	 jz	 short @F	; Jump if not

	 mov	 HELP_STATE,@HELP_SCREEN ; Not displaying topics now
@@:
	 call	 DISP_CLRSCR	; Display a clear screen

	 mov	 al,HLPATTR	; Get help attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_HSCR ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

; Display a shadow below and to the right of the help screen

	 push	 offset ds:W_HSCR ; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

; Display the help screen keys

	 mov	 al,HKEYATTR	; Get help key attribute
	 push	 ax		; Pass attribute to smear
	 push	 PMSG_HKEY	; Pass address of local buffer
	 push	 PW_HKEY	; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; If we've disabled F2, subdue it

	 test	 GL3_FLAG,@GL3_RUNHELP ; Showing help while we're testing?
	 jz	 short HELP_TOPIC ; Jump if not

	 mov	 al,DISATTR	; Show as disabled
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_HKEYF2 ; Pass window descriptor for "F2 Print..."
	 call	 WPUT_SA	; Smear attribute

; Display the help topic screen

HELP_TOPIC:

; Display the help topic title

	 imul	 bx,HLPIND,type PHTOPTTL ; Get index into help topic title ptrs

	 mov	 al,HTTLATTR	; Get help title attribute
	 push	 ax		; Pass attribute to smear
	 push	 PHTOPTTL[bx]	; Pass address of local buffer
	 push	 offset ds:W_HTTL ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display the help topic text

	 imul	 bx,HLPIND,type W_STR ; Get index into ARR_W_HTOP
	 lea	 bx,ARR_W_HTOP[bx] ; Get offset of window descriptor

	 mov	 si,HLPIND	; Get the current topic index
	 shl	 si,1		; Times two to index table of words

	 mov	 cx,HTOPIND[si] ; Get current help topic index
	 imul	 ax,cx,@HTXT_NCOL ; Skip over leading rows
	 add	 ax,HLPTOPIC[si] ; Plus address of local buffer

	 REGSAVE <DGROUP:[bx].SROW,DGROUP:[bx].NROW> ; Save starting & # rows

	 sub	 cx,DGROUP:[bx].NROW ; Less maximum # rows in text
	 neg	 cx		; Negate to get maximum # rows

	 cmp	 cx,@HTXT_NROW	; Izit within the screen size?
	 jbe	 short @F	; Jump if so

	 mov	 cx,@HTXT_NROW	; Use the maximum
@@:
	 mov	 DGROUP:[bx].NROW,cx ; Save as # rows

	 push	 ax		; Pass address of local buffer
	 push	 bx		; Pass address of window descriptor
	 call	 WPUT_C 	; Output the characters

; Clear to the end of the help text screen

	 add	 DGROUP:[bx].SROW,cx ; Skip to the next row

	 mov	 ax,@HTXT_NROW	; Get maximum # rows on the screen
	 sub	 ax,cx		; Less # rows already displayed
	 mov	 DGROUP:[bx].NROW,ax ; Save as # rows

	 mov	 al,' '         ; Smear a blank
	 push	 ax		; Pass the character to smear
	 push	 bx		; Pass address of window descriptor
	 call	 WPUT_SC	; Smear the character

	 REGREST <DGROUP:[bx].NROW,DGROUP:[bx].SROW> ; Restore

; Display the elevator if valid

	 cmp	 DGROUP:[bx].NROW,@HTXT_NROW ; More rows than fit on screen?
	 ja	 short @F	; Jump if so

	 mov	 al,' '         ; Smear a blank
	 push	 ax		; Pass the character to smear
	 push	 offset ds:W_HELEV ; Pass address of window descriptor
	 call	 WPUT_SC	; Smear the character

	 jmp	 short HELP_CR_END ; Join common code

@@:
	 push	 offset ds:MSG_HELEV ; Pass address of local buffer
	 push	 offset ds:W_HELEV ; Pass address of window descriptor
	 call	 WPUT_C 	; Output the characters

COMMENT|

Output the elevator box

Calculate a number between 0 and @HELEV_NROW-3 which
represents approximately where we are in the text display.
This calculation is

(@HELEV_NROW - 3) * HTOPIND[si] / (DGROUP:[bx].NROW - @HTXT_NROW)

|

	 imul	 ax,HTOPIND[si],@HELEV_NROW-3 ; Get 1st multiplier
	 xor	 dx,dx		; Zero to use as dword
	 mov	 cx,DGROUP:[bx].NROW ; Get total # rows
	 sub	 cx,@HTXT_NROW	; Less # rows that fit on screen
	 div	 cx		; Divide to get value in AX

	 add	 ax,@HELEV_SROW+1 ; Plus starting row
	 mov	 W_HEBOX.SROW,ax ; Save as starting row

	 mov	 al,'²'         ; Smear a half-tone
	 push	 ax		; Pass the character to smear
	 push	 offset ds:W_HEBOX ; Pass address of window descriptor
	 call	 WPUT_SC	; Smear the character
HELP_CR_END:
	 or	 GL2_FLAG,@GL2_HSCR ; Mark as active

	 jmp	 HELP_NEXT	; Go around again

	
HELP_ALL:
	test	GL3_FLAG,@GL3_MEMERR ; Displaying memory/NMI errors?
	jz	near ptr HELP_NEXT ; Jump if not

	or	GL3_FLAG,@GL3_ERRALL ; Mark as finding all errors

	jmp	short HELP_ESC	; Join common code

HELP_NO:
	test	GL3_FLAG,@GL3_MEMERR ; Displaying memory/NMI errors?
	jz	near ptr HELP_NEXT ; Jump if not

	jmp	short HELP_ESC	; Join common code

ifdef @BETA
HELP_DBG:
	test	GL2_FLAG,@GL2_SWAT ; Is 386SWAT present?
	jz	near ptr HELP_NEXT ; Jump if not

	int	01h		; Call our debugger
endif				; IFDEF @BETA
HELP_YES:
	test	GL3_FLAG,@GL3_MEMERR ; Displaying memory/NMI errors?
	jz	near ptr HELP_NEXT ; Jump if not

	or	GL3_FLAG,@GL3_ERRMORE ; Mark as finding more errors
;;;;;;;
;;;;;;; jmp	short HELP_ESC	; Join common code
;;;;;;;
HELP_ESC:

; If we're displaying a help topic, go back and display the
; help menu.  Otherwise, just exit.

	 btr	 GL2_FLAG,$GL2_HSCR ; Mark as inactive
	 jc	 short @F	; Jump if not done yet

	 test	 GL3_FLAG,@GL3_RUNHELP ; Are we called from Int 8?
	 jz	 short DISP_HELP_EXIT ; Jump if not

	 mov	 HELP_STATE,@HELP_NONE ; Reset help state
	 call	 DISP_SCRN	; Display the new screen
	 call	 DISP_ACTIV	; Display active elements
	 jmp	 short DISP_HELP_EXIT ; Join common exit

@@:
	 test	 GL3_FLAG,@GL3_RUNHELP ; Are we called from Int 8?
	 jz	 short @F	; Jump if not

	 mov	 HELP_STATE,@HELP_TOPICS ; Go back to previous help state
@@:
; If we're displaying either a memory or parity error screen, just exit

	 test	 GL2_FLAG,@GL2_MEMERR or @GL2_NMIERR ; Either error occur?
	 jnz	 short DISP_HELP_EXIT ; Jump if so

	 call	 DISP_SCRN	; Display the new screen
	 call	 DISP_ACTIV	; Display active elements

	 mov	 ax,@KEY_SPACE	; If we're displaying on top of test, turn off
				; Esc key
	 jmp	 HELP_START	; Display the help menu again

HELP_PRINT:

; Put up print dialog box and let 'em pick this topic or all topics
; with one set of radio buttons.  Let 'em pick the output destination
; as Printer (using Int 17h), File, or Add to file.

	 call	 DO_PRINT	; Get print options

	 jmp	 HELP_NEXT	; Go around again

DISP_HELP_EXIT:
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_HELP endp			; End DISP_HELP procedure

CODE	 ends			; End CODE segment

	 MEND			; End MEM_HELP module

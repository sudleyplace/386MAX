;' $Header:   P:/PVCS/MAX/QMT/MEM_MSGS.ASV   1.3   05 Jun 1998 14:03:26   BOB  $
	 title	 MEM_MSGS -- MEMCHK Message Text
	 page	 58,122
	 name	 MEM_MSGS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386
.xlist
	include MASM.INC
	include ASCII.INC
NOVER_HTU equ 1
	include VERSION.INC
	include MEM_OEM.INC
	include MEM_SCRN.INC
	include MEM_SEGS.INC
ifdef @BETA
	include VERSBETA.INC
endif
.list

DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	@ACHLP_NROW:abs
	extrn	@ACHLP_NCOL:abs

; When translating messages, don't forget the message text in the
; DPMIERR macro in MEM_EPM.ASM.

; Also, don't forget the entire MEM_HTXT.ASM module (as if you would).

	public	MSG_MEMERR,MSG_MEMERR1,MSG_NMIERR,MSG_NMIERR1,MSG_NOERR
	public	MSG_MEMERR_LEN,MSG_NMIERR_LEN,MSG_NOERR_LEN
ifdef LANG_GR
MSG_MEMERR db	 '--    '
MSG_MEMERR1 db	 '_ Speicherfehler. ',CR,LF
MSG_MEMERR_LEN equ $-MSG_MEMERR ; Length of message
MSG_NMIERR db	 '--    '
MSG_NMIERR1 db	 '_ ParitÑtsfehler. ',CR,LF
MSG_NMIERR_LEN equ $-MSG_NMIERR ; Length of message
MSG_NOERR db	 '-- Keine Fehler gefunden.',CR,LF
MSG_NOERR_LEN equ $-MSG_NOERR	; Length of message
else
MSG_MEMERR db	 '--    '
MSG_MEMERR1 db	 '_ memory error(s).',CR,LF
MSG_MEMERR_LEN equ $-MSG_MEMERR ; Length of message
MSG_NMIERR db	 '--    '
MSG_NMIERR1 db	 '_ parity error(s).',CR,LF
MSG_NMIERR_LEN equ $-MSG_NMIERR ; Length of message
MSG_NOERR db	 '-- No errors found.',CR,LF
MSG_NOERR_LEN equ $-MSG_NOERR	; Length of message
endif


	public	DATESEP,TIMESEP
ifdef LANG_GR
DATESEP db	'-'
TIMESEP db	':'
else
DATESEP db	'/'
TIMESEP db	':'
endif				; IFDEF LANG_GR

; =================== Messages used principally by MEM_FMT.ASM =================

PMAC	macro	NAM,SUF,ALEN

	public	NAM,NAM&A,NAM&B
ifnb <SUF>
	public	NAM&SUF 	; An extra suffix
endif				; IFNB <SUF>
ifnb <ALEN>
	irp	XX,<ALEN>
	public	NAM&&XX 	; An extra suffix
	endm			; IRP
else
	public	NAM&_LEN
endif				; IFNB <ALEN>
	endm			; PMAC


	PMAC	MSG_W0
ifdef LANG_GR
MSG_W0	db	'S 0                      '
MSG_W0A db	'________ -> '
MSG_W0B db	'________'
else
MSG_W0	db	'Wr 0s                    '
MSG_W0A db	'________ to '
MSG_W0B db	'________'
endif
MSG_W0_LEN equ $-MSG_W0

	PMAC	MSG_W1
ifdef LANG_GR
MSG_W1	db	'S 1                      '
MSG_W1A db	'________ -> '
MSG_W1B db	'________'
else
MSG_W1	db	'Wr 1s                    '
MSG_W1A db	'________ to '
MSG_W1B db	'________'
endif
MSG_W1_LEN equ $-MSG_W1

	PMAC	MSG_R0
ifdef LANG_GR
MSG_R0	db	'L 0                      '
MSG_R0A db	'________ -> '
MSG_R0B db	'________'
else
MSG_R0	db	'Rd 0s                    '
MSG_R0A db	'________ to '
MSG_R0B db	'________'
endif
MSG_R0_LEN equ $-MSG_R0

	PMAC	MSG_R0W1
ifdef LANG_GR
MSG_R0W1 db	'L 0 / S 1                '
MSG_R0W1A db	'________ -> '
MSG_R0W1B db	'________'
else
MSG_R0W1 db	'Rd 0s/Wr 1s              '
MSG_R0W1A db	'________ to '
MSG_R0W1B db	'________'
endif
MSG_R0W1_LEN equ $-MSG_R0W1

	PMAC	MSG_R0W1R1
ifdef LANG_GR
MSG_R0W1R1 db	'L 0 / S 1 / L 1          '
MSG_R0W1R1A db	'________ -> '
MSG_R0W1R1B db	'________'
else
MSG_R0W1R1 db	'Rd 0s/Wr 1s/Rd 1s        '
MSG_R0W1R1A db	'________ to '
MSG_R0W1R1B db	'________'
endif
MSG_R0W1R1_LEN equ $-MSG_R0W1R1

	PMAC	MSG_R0W1R1W0R0W1,Z,<_LEN1,_LEN2>
ifdef LANG_GR
MSG_R0W1R1W0R0W1 db  'L 0 / S 1 / L 1 / S 0 / L 0 / S 1   '
MSG_R0W1R1W0R0W1_LEN1 equ $-MSG_R0W1R1W0R0W1
MSG_R0W1R1W0R0W1Z db '                         '
MSG_R0W1R1W0R0W1A db '________ -> '
MSG_R0W1R1W0R0W1B db '________'
else
MSG_R0W1R1W0R0W1 db  'Rd 0s/Wr 1s/Rd 1s/Wr 0s/Rd 0s/Wr 1s '
MSG_R0W1R1W0R0W1_LEN1 equ $-MSG_R0W1R1W0R0W1
MSG_R0W1R1W0R0W1Z db '                         '
MSG_R0W1R1W0R0W1A db '________ to '
MSG_R0W1R1W0R0W1B db '________'
endif
MSG_R0W1R1W0R0W1_LEN2 equ $-MSG_R0W1R1W0R0W1Z

	PMAC	MSG_R0W1W0
ifdef LANG_GR
MSG_R0W1W0 db	'L 0 / S 1 / S 0          '
MSG_R0W1W0A db	'________ -> '
MSG_R0W1W0B db	'________'
else
MSG_R0W1W0 db	'Rd 0s/Wr 1s/Wr 0s        '
MSG_R0W1W0A db	'________ to '
MSG_R0W1W0B db	'________'
endif
MSG_R0W1W0_LEN equ $-MSG_R0W1W0

	PMAC	MSG_R1
ifdef LANG_GR
MSG_R1	db	'L 1                      '
MSG_R1A db	'________ -> '
MSG_R1B db	'________'
else
MSG_R1	db	'Rd 1s                    '
MSG_R1A db	'________ to '
MSG_R1B db	'________'
endif
MSG_R1_LEN equ $-MSG_R1

	PMAC	MSG_R1W0
ifdef LANG_GR
MSG_R1W0 db	'L 1 / S 0                '
MSG_R1W0A db	'________ -> '
MSG_R1W0B db	'________'
else
MSG_R1W0 db	'Rd 1s/Wr 0s              '
MSG_R1W0A db	'________ to '
MSG_R1W0B db	'________'
endif
MSG_R1W0_LEN equ $-MSG_R1W0

	PMAC	MSG_R1W0R0
ifdef LANG_GR
MSG_R1W0R0 db	'L 1 / S 0 / L 0          '
MSG_R1W0R0A db	'________ -> '
MSG_R1W0R0B db	'________'
else
MSG_R1W0R0 db	'Rd 1s/Wr 0s/Rd 0s        '
MSG_R1W0R0A db	'________ to '
MSG_R1W0R0B db	'________'
endif
MSG_R1W0R0_LEN equ $-MSG_R1W0R0

	PMAC	MSG_R1W0W1
ifdef LANG_GR
MSG_R1W0W1 db	'L 1 / S 0 / S 1          '
MSG_R1W0W1A db	'________ -> '
MSG_R1W0W1B db	'________'
else
MSG_R1W0W1 db	'Rd 1s/Wr 0s/Wr 1s        '
MSG_R1W0W1A db	'________ to '
MSG_R1W0W1B db	'________'
endif
MSG_R1W0W1_LEN equ $-MSG_R1W0W1

	PMAC	MSG_R1W0W1W0
ifdef LANG_GR
MSG_R1W0W1W0 db  'L 1 / S 0 / S 1 / S 0    '
MSG_R1W0W1W0A db '________ -> '
MSG_R1W0W1W0B db '________'
else
MSG_R1W0W1W0 db  'Rd 1s/Wr 0s/Wr 1s/Wr 0s  '
MSG_R1W0W1W0A db '________ to '
MSG_R1W0W1W0B db '________'
endif
MSG_R1W0W1W0_LEN equ $-MSG_R1W0W1W0

	public	ZMSG_CURPATB,ZMSG_CURPATB1,ZMSG_CURPATB_LEN
ifdef LANG_GR
ZMSG_CURPATB db  ZMSG_CURPATB_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'mit Muster '
ZMSG_CURPATB1 db '________'
else
ZMSG_CURPATB db  ZMSG_CURPATB_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'Using pattern '
ZMSG_CURPATB1 db '________'
endif
ZMSG_CURPATB_LEN equ ($-ZMSG_CURPATB)-2 ; Length of message (excluding LEN/ATTR)

	public	ZMSG_CURPATW,ZMSG_CURPATW1,ZMSG_CURPATW_LEN
ifdef LANG_GR
ZMSG_CURPATW db  ZMSG_CURPATW_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'mit Muster '
ZMSG_CURPATW1 db '________________'
else
ZMSG_CURPATW db  ZMSG_CURPATW_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'Using pattern '
ZMSG_CURPATW1 db '________________'
endif
ZMSG_CURPATW_LEN equ ($-ZMSG_CURPATW)-2 ; Length of message (excluding LEN/ATTR)

	public	ZMSG_CURPATD,ZMSG_CURPATD1,ZMSG_CURPATD_LEN
ifdef LANG_GR
ZMSG_CURPATD db  ZMSG_CURPATD_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'mit Muster '
ZMSG_CURPATD1 db '________________________________'
else
ZMSG_CURPATD db  ZMSG_CURPATD_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'Using pattern '
ZMSG_CURPATD1 db '________________________________'
endif
ZMSG_CURPATD_LEN equ ($-ZMSG_CURPATD)-2 ; Length of message (excluding LEN/ATTR)


; ============ Messages used by the individual test modules ====================

	public	ZMSG_UNLSAF
ifdef LANG_GR
ZMSG_UNLSAF db	ZMSG_UNLSAF_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'PrÅft auf Blockieren'
else
ZMSG_UNLSAF db	ZMSG_UNLSAF_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'Testing for Stuck-At Faults'
endif
ZMSG_UNLSAF_LEN equ ($-ZMSG_UNLSAF)-2 ; Length of message (excluding LEN/ATTR)

	public	ZMSG_UNLTRN
ifdef LANG_GR
ZMSG_UNLTRN db	 ZMSG_UNLTRN_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'PrÅft auf öbergangsfehler'
else
ZMSG_UNLTRN db	 ZMSG_UNLTRN_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'Testing for Transition Faults'
endif
ZMSG_UNLTRN_LEN equ ($-ZMSG_UNLTRN)-2 ; Length of message (excluding LEN/ATTR)

	public	ZMSG_UNLINV
ifdef LANG_GR
ZMSG_UNLINV db	ZMSG_UNLINV_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'PrÅft auf unabhÑngige Inversions-Kopplung'
else
ZMSG_UNLINV db	ZMSG_UNLINV_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'Testing for Unlinked Inversion Coupling Faults'
endif
ZMSG_UNLINV_LEN equ ($-ZMSG_UNLINV)-2 ; Length of message (excluding LEN/ATTR)

	public	ZMSG_UNLIDM
ifdef LANG_GR
ZMSG_UNLIDM db	ZMSG_UNLIDM_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'PrÅft auf unabhÑngige Folge-Stop Kopplung'
else
ZMSG_UNLIDM db	ZMSG_UNLIDM_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'Testing for Unlinked Idempotent Coupling Faults'
endif
ZMSG_UNLIDM_LEN equ ($-ZMSG_UNLIDM)-2 ; Length of message (excluding LEN/ATTR)

	public	ZMSG_LNKINV
ifdef LANG_GR
ZMSG_LNKINV db	ZMSG_LNKINV_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'PrÅft auf verkettete Inversions-Kopplung'
else
ZMSG_LNKINV db	ZMSG_LNKINV_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'Testing for Linked Inversion Coupling Faults'
endif
ZMSG_LNKINV_LEN equ ($-ZMSG_LNKINV)-2 ; Length of message (excluding LEN/ATTR)

	public	ZMSG_LNKIDM
ifdef LANG_GR
ZMSG_LNKIDM db	ZMSG_LNKIDM_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'PrÅft auf verkettete Folge-Stop Kopplung'
else
ZMSG_LNKIDM db	ZMSG_LNKIDM_LEN
	db	?		; Attribute to use (filled by CHECK_SCRN)
	db	'Testing for Linked Idempotent Coupling Faults'
endif
ZMSG_LNKIDM_LEN equ ($-ZMSG_LNKIDM)-2 ; Length of message (excluding LEN/ATTR)


; ============= Messages used principally by MEM_SCRN.ASM ======================

	public	W_CPY
W_CPY	W_STR	<@CPY_SROW, @CPY_SCOL, @CPY_NROWS, @CPY_NCOLS>

	public	W_AAR
W_AAR	W_STR	<@AAR_SROW, @AAR_SCOL, @AAR_NROWS, @AAR_NCOLS>

	public	W_KEY
W_KEY	W_STR	<@KEY_SROW, @KEY_SCOL, @KEY_NROWS, @KEY_NCOLS>

@CPY_SROW equ	1		; Starting row for Copyright Screen
@CPY_SCOL equ	1		; ...	   col ...

@AAR_SCOL equ	@CPY_SROW
@KEY_SCOL equ	@CPY_SROW

; Version number (padded and unpadded).  Note that ',VTXTP,' (including
;		     quotes) is the same length as 7.00.000·
ifdef @BETA
VTEXT equ	<VERS_H,'.',VERS_T,VERS_U,'.',BETA_H,BETA_T,BETA_U,'·'>
VTXTP equ	<VTEXT>
else
VTEXT equ	<VERS_H,'.',VERS_T,VERS_U>
;		    7.00.000·
VTXTP equ	<VTEXT,'     '>
endif	 ; IFDEF @BETA

	public	MSG_CPY
ifdef LANG_GR
MSG_CPY db	'                           '
@CPY_NCOLS equ	$-MSG_CPY
@AAR_NCOLS equ	@CPY_NCOLS
ifdef @QMT
	db	'  Qualitas Memory Tester   '
elseifdef @RAMDEMO
	db	'   Qualitas RAMexam Demo   '
else	; @QMT
	db	'     Qualitas RAMexam      '
endif	; @QMT
	db	'       Version ',VTXTP,'   '
@AAR_SROW equ	@CPY_SROW + ($-MSG_CPY)/@CPY_NCOLS
MSG_AAR db	'        (c) 1988-98        '
	db	'  Alle Rechte vorbehalten. '
	db	'                           '
@AAR_NROWS equ	($-MSG_AAR)/@AAR_NCOLS
@KEY_SROW equ	@CPY_SROW + ($-MSG_CPY)/@CPY_NCOLS
else
MSG_CPY db	'                           '
@CPY_NCOLS equ	$-MSG_CPY
@AAR_NCOLS equ	@CPY_NCOLS
ifdef @QMT
	db	'  Qualitas Memory Tester   '
elseifdef @RAMDEMO
	db	'   Qualitas RAMexam Demo   '
else ; @QMT
	db	'     Qualitas RAMexam      '
endif ; @QMT
	db	'       Version ',VTXTP,'   '
@AAR_SROW equ	@CPY_SROW + ($-MSG_CPY)/@CPY_NCOLS
MSG_AAR db	'        (c) 1988-98        '
	db	'    GNU General Public License version 3.   '
	db	'                           '
@AAR_NROWS equ	($-MSG_AAR)/@AAR_NCOLS
@KEY_SROW equ	@CPY_SROW + ($-MSG_CPY)/@CPY_NCOLS
endif

	public	MSG_QUIT
ifdef LANG_GR
MSG_QUIT db	'         F1=Hilfe          '
@KEY_NCOLS equ	$-MSG_QUIT
	db	'        Esc=Beenden        '
@KEY_NROWS equ	($-MSG_QUIT)/@KEY_NCOLS
	db	'                           '
@CPY_NROWS equ	 ($-MSG_CPY)/@CPY_NCOLS
else
MSG_QUIT db	'     Press F1 for Help     '
@KEY_NCOLS equ	$-MSG_QUIT
	db	'     Press Esc to Quit     '
@KEY_NROWS equ	($-MSG_QUIT)/@KEY_NCOLS
	db	'                           '
@CPY_NROWS equ	($-MSG_CPY)/@CPY_NCOLS
endif

	 public  MSG_HALT
ifdef LANG_GR
MSG_HALT db	 '     ESC hÑlt Tests an     ' ; Must be same # rows/cols
	 db	 '                           ' ; as MSG_QUIT
	 db	 '                           '
else
MSG_HALT db	 '     Press Esc to Halt     ' ; Must be same # rows/cols
	 db	 '                           ' ; as MSG_QUIT
	 db	 '                           '
endif

	 public  W_MODE
	 align	 2
W_MODE	 W_STR	 <@NROWS-1, 0, 1, @MODE_NCOLS>

	 public  MSG_BASIC,MSG_ADV
ifdef LANG_GR
MSG_BASIC db	 '   Alt-TAB=öberblick           '
@MODE_NCOLS equ  $-MSG_BASIC
MSG_ADV   db	 '   Alt-TAB=Erweiterte Anzeige  '
else
MSG_BASIC db	 '  Alt-TAB for basic display    '
@MODE_NCOLS equ  $-MSG_BASIC
MSG_ADV   db	 '  Alt-TAB for advanced display '
endif

	 public  W_BASE
	 align	 2
W_BASE	 W_STR	 <@NROWS-1, @NCOLS-@BASE_NCOLS, 1, @BASE_NCOLS>

	 public  MSG_DEC,MSG_HEX
ifdef LANG_GR
MSG_DEC  db	 '     Taste D=Adre·darstellung dezimal     '
@BASE_NCOLS equ  $-MSG_DEC
MSG_HEX   db	 '   Taste H=Adre·darstellung hexadezimal   '
else
MSG_DEC  db	 '     Press D to display decimal addresses '
@BASE_NCOLS equ  $-MSG_DEC
MSG_HEX   db	 ' Press H to display hexadecimal addresses '
endif

	 public  MSG_ALLOC,MSG_ALLOC_LEN
ifdef LANG_GR
MSG_ALLOC db	 ' Allokiere Speicher...' ; Message to display
MSG_ALLOC_LEN equ $-MSG_ALLOC	; Length of ...
else
MSG_ALLOC db	 ' Allocating Memory... ' ; Message to display
MSG_ALLOC_LEN equ $-MSG_ALLOC	; Length of ...
endif


; ================ Messages used principally by MEM_TIME.ASM ===================

	 public  W_MEMSCR
W_MEMSCR W_STR	 <@MEMSCR_SROW, @MEMSCR_SCOL, @MEMSCR_NROW, @MEMSCR_NCOL>

	 public  W_MEMLIN
W_MEMLIN W_STR	 <@MEMLIN_SROW, @MEMLIN_SCOL,		 ?, @MEMLIN_NCOL>

	 public  W_MEMWRK
W_MEMWRK W_STR	 <@MEMLIN_SROW, @MEMLIN_SCOL,		 1, @MEMLIN_NCOL>

@MEMSCR_SROW equ 11		; Starting row # for MEMSCR
@MEMSCR_SCOL equ 1		; ...	   col ...

@MEMHDR_NROW equ 1
@MEMHDR_SROW equ @MEMSCR_SROW

	 public  W_MEMH 	; "Memory To Test" window descriptor
W_MEMH	 W_STR	 <@MEMHDR_SROW, @MEMHDR_SCOL, @MEMHDR_NROW, @MEMHDR_NCOL>

	 public  MSG_MEMSCR
MSG_MEMSCR db	 '⁄ '
@MEMHDR_SCOL equ @MEMSCR_SCOL + $-MSG_MEMSCR
ifdef LANG_GR
MSG_MEMHDR db	 ' Testbereich  '
else
MSG_MEMHDR db	 'Memory To Test'
endif
@MEMHDR_NCOL equ $-MSG_MEMHDR
	 db	 ' ƒƒƒƒƒƒƒƒƒƒø'
@MEMSCR_NCOL equ $-MSG_MEMSCR ; # cols in line
	 db	 '≥                          ≥'
	 public  @MEMLIN_SROW
@MEMLIN_SROW equ @MEMSCR_SROW + ($-MSG_MEMSCR)/@MEMSCR_NCOL
MSG_MEMSCR1 db	 '≥                          ≥'
	 db	 '≥                          ≥'
	 db	 '≥                          ≥'
	 db	 '≥                          ≥'
	 db	 '≥                          ≥'
	 db	 '≥                          ≥'
	 db	 '≥                          ≥'
	 db	 '≥                          ≥'
@MEMLIN_NROW equ ($-MSG_MEMSCR1)/@MEMSCR_NCOL
	 db	 '≥                          ≥'
	 db	 '≥                          ≥'
	 db	 '¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ'
@MEMSCR_NROW equ ($-MSG_MEMSCR)/@MEMSCR_NCOL ; # rows

	 public  @MEMLIN_SCOL
@MEMLIN_SCOL equ @MEMSCR_SCOL+1 ; Starting col for MEMLIN

	 public  @MEMLIN_NCOL,@MEMITEM_LEN
@MEMLIN_NCOL equ type MEMLIN_STR ; # cols in line
@MEMITEM_LEN equ @MEMLIN_NROW+0 ; Maximum # memory lines on screen at once

	 public  MSG_MEMLIN
MSG_MEMLIN MEMLIN_STR @MEMITEM_LEN dup (<>)
	 db	 @MEMLIN_NCOL dup (' ') ; Room for memory total line

	 public  MSG_MEMATTR
MSG_MEMATTR db	 (@MEMLIN_NROW * @MEMLIN_NCOL) dup (?) ; Attributes for memory lines
	 db	 @MEMLIN_NCOL dup (?) ; Room for memory total attributes

	 public  @ELEV_SROW,@ELEV_NROW
@ELEV_SROW equ	 @MEMLIN_SROW + 0
@ELEV_SCOL equ	 @MEMLIN_SCOL + @MEMLIN_NCOL
@ELEV_NROW equ	 @MEMITEM_LEN + 0

	 public  W_ELEV
	 align	 2
W_ELEV	 W_STR	 <@ELEV_SROW, @ELEV_SCOL, @ELEV_NROW, 0>

	 public  MSG_ELEV
MSG_ELEV db	 '',(@MEMITEM_LEN-2) dup ('±'),''

	 public  W_EBOX
	 align	 2
W_EBOX	 W_STR	 <?, @ELEV_SCOL, 1, 1>

@MEMEND_SROW equ @MEMSCR_SROW + @MEMSCR_NROW - 2
@MEMEND_SCOL equ @MEMSCR_SCOL + 1
@MEMEND_NROW equ 1
@MEMEND_NCOL equ @MEMSCR_NCOL - 2

	 public  W_MEMEND
	 align	 2
W_MEMEND W_STR	 <@MEMEND_SROW, @MEMEND_SCOL, @MEMEND_NROW, @MEMEND_NCOL>

	 public  PMSG_MEMEND
PMSG_MEMEND dw	 DGROUP:MSG_MEMEND0 ; Ptr to ending message for memory lines

	 public  MSG_MEMEND0
MSG_MEMEND0 db	 @MEMLIN_NCOL dup (' ') ; Ending message if no unallocated
				; entries are present

	 public  MSG_MEMEND1
ifdef LANG_GR
MSG_MEMEND1 db	 ' Grau = Belegt/kein Test  '
else
MSG_MEMEND1 db	 ' Gray = in use/not tested '
endif

	 public  PAMEM
PAMEM	 label	 word
CNT	 =	 0
	 rept	 @MEMLIN_NROW
	 dw	 DGROUP:MSG_MEMLIN + CNT * (type MEMLIN_STR)
CNT	 =	 CNT+1
	 endm			; REPT

	 public  ARR_W_MEMLIN
ARR_W_MEMLIN label  tbyte

CNT	 =	 0
	 rept	 @MEMSCR_NROW
	 W_STR	 <@MEMLIN_SROW + CNT, @MEMLIN_SCOL, 1, @MEMLIN_NCOL>
CNT	 =	 CNT + 1
	 endm

	 public  MSG_TOT,MSG_TOT_LEN
ifdef LANG_GR
MSG_TOT  db	 'Gesamt '      ; "Total " text used in memory screen
else
MSG_TOT  db	 'Total '       ; "Total " text used in memory screen
endif
MSG_TOT_LEN equ  $-MSG_TOT	; Length of ...

; ================= Messages used principally by MEM_FALT.ASM ==================

@ASKSCR1_SROW equ 1
@ASKSCR1_SCOL equ 30

	 public  W_ASKSCR1
	 align	 2
W_ASKSCR1 W_STR  <@ASKSCR1_SROW, @ASKSCR1_SCOL, \
		  @ASKSCR1_NROW, @ASKSCR1_NCOL>

	 public  MSG_QUICKA,MSG_QUICKB
ifdef LANG_GR
MSG_QUICKA db	 ' Æ Kurz  Ø '
MSG_QUICKB db	 '   Kurz    '
else
MSG_QUICKA db	 ' Æ Quick Ø '
MSG_QUICKB db	 '   Quick   '
endif

	 public  MSG_FULLA,MSG_FULLB
ifdef LANG_GR
MSG_FULLA db	 ' Æ Voll Ø '
MSG_FULLB db	 '   Voll   '
else
MSG_FULLA db	 ' Æ Full Ø '
MSG_FULLB db	 '   Full   '
endif

	 public  MSG_ASKSCR1
ifdef LANG_GR
MSG_ASKSCR1 db	 '                                                '
@ASKSCR1_NCOL equ $-MSG_ASKSCR1
	 db	 ' WÑhlen Sie mit den Pfeiltasten den gewÅnschten '
	 db	 ' Testmodus. Starten Sie mit der Eingabetaste:   '
	 db	 '                                                '
	 db	 '                                                '
else
MSG_ASKSCR1 db	 '                                                '
@ASKSCR1_NCOL equ $-MSG_ASKSCR1
	 db	 '      Use the arrow keys to select the test     '
	 db	 '    you wish to run and press Enter to start:   '
	 db	 '                                                '
	 db	 '                                                '
endif
@ITEM1_SROW equ  @ASKSCR1_SROW + ($-MSG_ASKSCR1)/@ASKSCR1_NCOL
;;;;;;;; db	 '               Quick         Full               '
MSG_ASKSCR1QF label byte
	 db	 '            '
@ITEM1_SCOL1 equ  @ASKSCR1_SCOL + ($-MSG_ASKSCR1QF)
ifdef LANG_GR
MSG_ASKSCR1Q label byte
	 db	 '   Quick   '
else
MSG_ASKSCR1Q label byte
	 db	 '   Quick   '
endif
@ITEM1_NCOL1 equ  ($-MSG_ASKSCR1Q)
	 db	 '   '
@ITEM1_SCOL2 equ  @ASKSCR1_SCOL + ($-MSG_ASKSCR1QF)
ifdef LANG_GR
MSG_ASKSCR1F label byte
	 db	 '   Voll   '
else
MSG_ASKSCR1F label byte
	 db	 '   Full   '
endif
@ITEM1_NCOL2 equ  ($-MSG_ASKSCR1F)
	 db	 '            '
	 db	 '                                                '
	 db	 '                                                '
	 db	 '                                                '
@ASKSCR1_NROW equ ($-MSG_ASKSCR1)/@ASKSCR1_NCOL

	 public  ARR_W_ITEM1
	 align	 2
ARR_W_ITEM1 label tbyte
	 W_STR	 <@ITEM1_SROW + 0, @ITEM1_SCOL1, 1, @ITEM1_NCOL1>
	 W_STR	 <@ITEM1_SROW + 0, @ITEM1_SCOL2, 1, @ITEM1_NCOL2>


@ASKSCR2_SROW equ 1
@ASKSCR2_SCOL equ 30

	 public  W_ASKSCR2
	 align	 2
W_ASKSCR2 W_STR  <@ASKSCR2_SROW, @ASKSCR2_SCOL, \
		  @ASKSCR2_NROW, @ASKSCR2_NCOL>

	 public  MSG_ASKSCR2
MSG_ASKSCR2 db	 '                                                '
@ASKSCR2_NCOL equ $-MSG_ASKSCR2
@ASK_SROW equ	 @ASKSCR2_SROW + ($-MSG_ASKSCR2)/@ASKSCR2_NCOL
ifdef LANG_GR
;;;;;;;; ### C (continuously) changes to D (Dauertest) ###
MSG_ASK2 db	 ' Geben Sie hier an, '
@ASK_SCOL equ	 @ASKSCR2_SCOL + ($-MSG_ASK2)
	 db	 '  Blockieren          [  0] '
	 db	 ' wie oft jeder Test   öbergangsfehler     [  0] '
	 db	 ' durchlaufen werden   Verkett. Inversion  [  0] '
	 db	 ' soll oder C fÅr      Unabh. Inversion    [  0] '
	 db	 ' einen Dauertest.     Verkett. Folge-Stop [  0] '
	 db	 ' STRG-EINGABETASTE    Unabh. Folge-Stop   [  0] '
	 db	 ' = einmaliger Test.             START           '
	 db	 '                                                '
else
;;;;;;;; db	 ' Choose the number    Stuck-At Faults     [  0]'
MSG_ASK2 db	 ' Choose the number  '
@ASK_SCOL equ	 @ASKSCR2_SCOL + ($-MSG_ASK2)
	 db	 '  Stuck-At Faults     [  0] '
	 db	 ' of times to run      Transition Faults   [  0] '
	 db	 ' each test or C       Linked Inversion    [  0] '
	 db	 ' to run a test        Unlinked Inversion  [  0] '
	 db	 ' continuously.        Linked Idempotent   [  0] '
	 db	 ' Press Ctl-Enter      Unlinked Idempotent [  0] '
	 db	 ' to run test once.              START           '
	 db	 '                                                '
endif
@ASKSCR2_NROW equ ($-MSG_ASKSCR2)/@ASKSCR2_NCOL

	 public  MSG_ASK,MSG_ASK1,MSG_CNT1
MSG_ASK  db	 ' '
@ITEM_SCOL1 equ  @ASK_SCOL+($-MSG_ASK)
ifdef LANG_GR
MSG_ASK1 db	 ' Blockieren          [  '
MSG_CNT1 db	 '0]'
else
MSG_ASK1 db	 ' Stuck-At Faults     [  '
MSG_CNT1 db	 '0]'
endif
@ITEM_NCOL1 equ   $-MSG_ASK1
@ASK_NCOL equ	 $-MSG_ASK
ifdef LANG_GR
;;;;;;;; db	 '  Stuck-At Fehler     [  0]'
	 db	 '  öbergangsfehler     [  0]'
	 db	 '  Verkett. Inversion  [  0]'
	 db	 '  Unabh. Inversion    [  0]'
	 db	 '  Verkett. Folge-Stop [  0]'
	 db	 '  Unabh. Folge-Stop   [  0]'
	 db	 '            START          '
else
;;;;;;;; db	 '  Stuck-At Faults     [  0]'
	 db	 '  Transition Faults   [  0]'
	 db	 '  Linked Inversion    [  0]'
	 db	 '  Unlinked Inversion  [  0]'
	 db	 '  Linked Idempotent   [  0]'
	 db	 '  Unlinked Idempotent [  0]'
	 db	 '            START          '
endif
@ASK_NROW equ	 ($-MSG_ASK)/@ASK_NCOL
	public	MSG_ASK_CONT
MSG_ASK_CONT equ $-2		; Fill in here for continuous count (units digit)

	 public  PATXT2,PBTXT2
	 align	 2
PBTXT2	 label	 word
PATXT2	 dw	 DGROUP:MSG_ASK1 + 0 * @ASK_NCOL ; Ptr to ask advanced text cols
	 dw	 DGROUP:MSG_ASK1 + 1 * @ASK_NCOL
	 dw	 DGROUP:MSG_ASK1 + 2 * @ASK_NCOL
	 dw	 DGROUP:MSG_ASK1 + 3 * @ASK_NCOL
	 dw	 DGROUP:MSG_ASK1 + 4 * @ASK_NCOL
	 dw	 DGROUP:MSG_ASK1 + 5 * @ASK_NCOL
	 dw	 DGROUP:MSG_ASK1 + 6 * @ASK_NCOL

	 public  CNTTAB
	 align	 2
CNTTAB	 dw	 DGROUP:MSG_CNT1 + 0 * @ASK_NCOL ; Ptr to item count value
	 dw	 DGROUP:MSG_CNT1 + 1 * @ASK_NCOL
	 dw	 DGROUP:MSG_CNT1 + 2 * @ASK_NCOL
	 dw	 DGROUP:MSG_CNT1 + 3 * @ASK_NCOL
	 dw	 DGROUP:MSG_CNT1 + 4 * @ASK_NCOL
	 dw	 DGROUP:MSG_CNT1 + 5 * @ASK_NCOL

	 public  CMPTAB
	 align	 2
CMPTAB	 dw	 DGROUP:MSG_ASK1 + 0 * @ASK_NCOL - 1 ; Ptr to ask complete cols
	 dw	 DGROUP:MSG_ASK1 + 1 * @ASK_NCOL - 1
	 dw	 DGROUP:MSG_ASK1 + 2 * @ASK_NCOL - 1
	 dw	 DGROUP:MSG_ASK1 + 3 * @ASK_NCOL - 1
	 dw	 DGROUP:MSG_ASK1 + 4 * @ASK_NCOL - 1
	 dw	 DGROUP:MSG_ASK1 + 5 * @ASK_NCOL - 1

	 public  W_ASK
	 align	 2
W_ASK	 W_STR	 <@ASK_SROW, @ASK_SCOL, \
		  @ASK_NROW, @ASK_NCOL>

@ITEM_SROW equ	 @ASK_SROW

	 public  ARR_W_ITEM2
ARR_W_ITEM2 label tbyte
	 W_STR	 <@ITEM_SROW + 0, @ITEM_SCOL1, 1, @ITEM_NCOL1>
	 W_STR	 <@ITEM_SROW + 1, @ITEM_SCOL1, 1, @ITEM_NCOL1>
	 W_STR	 <@ITEM_SROW + 2, @ITEM_SCOL1, 1, @ITEM_NCOL1>
	 W_STR	 <@ITEM_SROW + 3, @ITEM_SCOL1, 1, @ITEM_NCOL1>
	 W_STR	 <@ITEM_SROW + 4, @ITEM_SCOL1, 1, @ITEM_NCOL1>
	 W_STR	 <@ITEM_SROW + 5, @ITEM_SCOL1, 1, @ITEM_NCOL1>
	 W_STR	 <@ITEM_SROW + 6, @ITEM_SCOL1, 1, @ITEM_NCOL1>

	 public  W_STATSCR
W_STATSCR W_STR  <@STATSCR_SROW, @STATSCR_SCOL, @STATSCR_NROW, @STATSCR_NCOL>

	 public  W_STATL
W_STATL  W_STR	 <@STATLIN_SROW-1, @STATLIN_SCOL, 1, @STATLIN_NCOL> ; Status
			; line window descriptor
	 public  W_SCROLL
W_SCROLL W_STR	 <@SCROLL_SROW, @SCROLL_SCOL, @SCROLL_NROW, @SCROLL_NCOL>


@STATSCR_SROW equ @ASKSCR2_SROW + @ASKSCR2_NROW + 1
@STATSCR_SCOL equ @ASKSCR2_SCOL

@STATHDR1_NROW equ 1
@STATHDR1_SROW equ @STATSCR_SROW

@STATHDR2_NROW equ 1
@STATHDR2_SROW equ @STATSCR_SROW

@STATHDR3_NROW equ 1
@STATHDR3_SROW equ @STATSCR_SROW

	 public  W_STATH1	; "Status" window descriptor
W_STATH1 W_STR	 <@STATHDR1_SROW, @STATHDR1_SCOL, @STATHDR1_NROW, @STATHDR1_NCOL>

	 public  W_STATH2	; "Elapsed  0:00:00" window descriptor
W_STATH2 W_STR	 <@STATHDR2_SROW, @STATHDR2_SCOL, @STATHDR2_NROW, @STATHDR2_NCOL>

	 public  W_STATH3	; "Estimated  0:00:00" window descriptor
W_STATH3 W_STR	 <@STATHDR3_SROW, @STATHDR3_SCOL, @STATHDR3_NROW, @STATHDR3_NCOL>

	 public  MSG_STATSCR
ifdef LANG_GR			; German Version ******************
MSG_STATSCR db	 '⁄'            ; German words for Elapsed and Estimated are longer
@STATHDR1_SCOL equ @STATSCR_SCOL + $-MSG_STATSCR
MSG_STATHDR db	 'Status'
@STATHDR1_NCOL equ $-MSG_STATHDR
	 db	 'ƒ'            ; German words for Elapsed and Estimated are longer
@STATHDR2_SCOL equ @STATSCR_SCOL + $-MSG_STATSCR
MSG_STATHDR2 db  'Abgelaufen '
@ELAP2_SCOL equ  @STATSCR_SCOL + ($-MSG_STATSCR)
@ELAP2_SROW equ  @STATSCR_SROW
MSG_ELAP2 db	 ' 0:00:00'
@STATHDR2_NCOL equ $-MSG_STATHDR2
	 db	 ' ƒ '
@STATHDR3_SCOL equ @STATSCR_SCOL + $-MSG_STATSCR
MSG_STATHDR3 db  'GeschÑtzt '
@ETA2_SCOL equ	 @STATSCR_SCOL + ($-MSG_STATSCR)
@ETA2_SROW equ	 @STATSCR_SROW
MSG_ETA2 db	 ' 0:00:00'
@STATHDR3_NCOL equ $-MSG_STATHDR3
	 db	 'ƒø'
@STATSCR_NCOL equ $-MSG_STATSCR
	 db	 '≥                                                ≥'
	 db	 '≥                                                ≥'
	 db	 '≥                                                ≥'
	 db	 '≥                                                ≥'
	 db	 '≥                                                ≥'
	 db	 '≥                                                ≥'
	 db	 '≥                                                ≥'
	 db	 '≥                                                ≥'
	 db	 '≥                                                ≥'
	 db	 '≥                                                ≥'
	 db	 '≥                                                ≥'
	 db	 '¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ'
@STATSCR_NROW equ ($-MSG_STATSCR)/@STATSCR_NCOL
else				; English Version *****************
MSG_STATSCR db	 '⁄ƒ'
@STATHDR1_SCOL equ @STATSCR_SCOL + $-MSG_STATSCR
MSG_STATHDR db	 'Status'
@STATHDR1_NCOL equ $-MSG_STATHDR
	 db	 'ƒƒ'
@STATHDR2_SCOL equ @STATSCR_SCOL + $-MSG_STATSCR
MSG_STATHDR2 db  'Elapsed '
@ELAP2_SCOL equ  @STATSCR_SCOL + ($-MSG_STATSCR)
@ELAP2_SROW equ  @STATSCR_SROW
MSG_ELAP2 db	 ' 0:00:00'
@STATHDR2_NCOL equ $-MSG_STATHDR2
	 db	 ' ƒ '
@STATHDR3_SCOL equ @STATSCR_SCOL + $-MSG_STATSCR
MSG_STATHDR3 db  'Estimated '
@ETA2_SCOL equ	 @STATSCR_SCOL + ($-MSG_STATSCR)
@ETA2_SROW equ	 @STATSCR_SROW
MSG_ETA2 db	 ' 0:00:00'
@STATHDR3_NCOL equ $-MSG_STATHDR3
	 db	 'ƒø'
@STATSCR_NCOL equ $-MSG_STATSCR
	 db	 '≥                                               ≥'
	 db	 '≥                                               ≥'
	 db	 '≥                                               ≥'
	 db	 '≥                                               ≥'
	 db	 '≥                                               ≥'
	 db	 '≥                                               ≥'
	 db	 '≥                                               ≥'
	 db	 '≥                                               ≥'
	 db	 '≥                                               ≥'
	 db	 '≥                                               ≥'
	 db	 '≥                                               ≥'
	 db	 '¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ'
@STATSCR_NROW equ ($-MSG_STATSCR)/@STATSCR_NCOL
endif

	 public  @STATLIN_SROW,@STATLIN_NCOL,@STATLIN_NROW,@STATLIN_END
@STATLIN_SROW equ @STATSCR_SROW + 1 ; Skip over the border
@STATLIN_NROW equ @STATSCR_NROW - 2 ; ...
@STATLIN_SCOL equ @STATSCR_SCOL + 1 ; ...
@STATLIN_NCOL equ @STATSCR_NCOL - 2 ; ...
@STATLIN_END  equ @STATLIN_SROW + @STATLIN_NROW ; Ending row #

@SCROLL_SROW equ @STATLIN_SROW	   ; Start at the first line
@SCROLL_NROW equ @STATLIN_NROW	   ; ...
@SCROLL_SCOL equ @STATLIN_SCOL	   ; Use same value as status line
@SCROLL_NCOL equ @STATLIN_NCOL	   ; ...

@CURPAT_SROW equ @STATSCR_SROW + @STATSCR_NROW - 1
@CURPAT_SCOL equ @STATSCR_SCOL + 1

	 public  W_CURPAT
	 align	 2
W_CURPAT W_STR	 <@CURPAT_SROW, @CURPAT_SCOL, 1, ?>

	 public  ZMSG_ELAP,ZMSG_ELAP1,ZMSG_ELAP_HR,MSG_ELAP,MSG_ELAP_LEN
ZMSG_ELAP db	 ZMSG_ELAP_LEN
	 db	 ?		; Attribute to use (filled by CHECK_SCRN)
ifdef LANG_GR
MSG_ELAP db	 'Abgelaufen '
else
MSG_ELAP db	 'Elapsed time '
endif
ZMSG_ELAP1 label byte
ZMSG_ELAP_HR   db '__:'
ZMSG_ELAP_MIN  db '__:'
ZMSG_ELAP_SEC  db '__ '
MSG_ELAP_LEN equ $-MSG_ELAP
@ELAP1_NCOL equ  $-ZMSG_ELAP1
@ELAP2_NCOL equ  @ELAP1_NCOL
	 public  ZMSG_ELAP_DONE
ZMSG_ELAP_DONE db '                  '
ZMSG_ELAP_LEN equ ($-ZMSG_ELAP)-2 ; Length of message (excluding LEN/ATTR)

	 public  ZMSG_ELAP_SEC_LEN,ZMSG_ELAP_MIN_LEN,ZMSG_ELAP_HR_LEN
ZMSG_ELAP_SEC_LEN equ ZMSG_ELAP_SEC-ZMSG_ELAP_HR ; Distance from start to SEC
ZMSG_ELAP_MIN_LEN equ ZMSG_ELAP_MIN-ZMSG_ELAP_HR ; ...			  MIN
ZMSG_ELAP_HR_LEN  equ ZMSG_ELAP_HR -ZMSG_ELAP_HR ; ...			  HR

	 public  MSG_DONE,MSG_DONE_LEN
ifdef LANG_GR
MSG_DONE db	 'Fehlerfrei FERTIG '
else
MSG_DONE db	 'ƒ DONE - No errors'
endif
MSG_DONE_LEN equ $-MSG_DONE	; Length of message

	 public  MSG_INTR,MSG_INTR_LEN
ifdef LANG_GR
MSG_INTR db	 'ƒ UNTERBROCHEN    '
else
MSG_INTR db	 'ƒ INTERRUPTED     '
endif
MSG_INTR_LEN equ $-MSG_INTR	; Length of message

	 public  ZMSG_BLK,ZMSG_BLK1,ZMSG_BLK3,ZMSG_BLK4,ZMSG_BLK5
ZMSG_BLK db	 ZMSG_BLK_LEN
	 db	 ?		; Attribute to use (filled by CHECK_SCRN)
ifdef LANG_GR
ZMSG_BLK1 db	 'Aktueller Block  '
else
ZMSG_BLK1 db	 'Current block is '
endif
ZMSG_BLK3 db	 '________-'
ZMSG_BLK4 db	 '________ (     '
ZMSG_BLK5 db	 '_ KB)'
ZMSG_BLK_LEN equ  ($-ZMSG_BLK)-2 ; Length of message (excluding LEN/ATTR)

	 public  MSG_BLKCLR
ifdef LANG_GR
MSG_BLKCLR db	 'Aktueller Block  ________-________ (     _ KB)'
else
MSG_BLKCLR db	 'Current block is ________-________ (     _ KB)'
endif

	 public  MSG_SCROLL
MSG_SCROLL db	 (2 * @SCROLL_NROW * @SCROLL_NCOL) dup (?) ; Room for scrolling
				; both characters and attributes

@PROG_SROW equ	 13

	 public  W_PROG
	 align	 2
W_PROG	 W_STR	 <@PROG_SROW, @PROG_SCOL, @PROG_NROW, @PROG_NCOL>

	 public  MSG_PROGSCR
MSG_PROGSCR db	 '                                                               '
@PROG_NCOL equ	 $-MSG_PROGSCR
@PROG_SCOL equ	 (@NCOLS - @PROG_NCOL)/2
@PTST_SROW equ	 @PROG_SROW + ($-MSG_PROGSCR)/@PROG_NCOL
	 db	 '                                                               '
	 db	 '                                                               '
@PBAR_SROW equ	 @PROG_SROW + ($-MSG_PROGSCR)/@PROG_NCOL
MSG_P1	 db	 '       '
@PBAR_SCOL equ	 @PROG_SCOL + ($-MSG_P1)
MSG_PROG1 db	 '                                                        '
	 db	 '                                                               '
	 db	 '      0%        25%          50%         75%         100%      '
	 db	 '                                                               '
ifdef LANG_GR
MSG_EL	 db	 ' Abgelaufen   '
@ELAP1_SCOL equ  @PROG_SCOL + ($-MSG_EL)
	 db	 ' 0:00:00   GeschÑtzte AusfÅhrungszeit   '
@ETA1_SCOL equ	 @PROG_SCOL + ($-MSG_EL)
	 db	 ' 0:00:00 '
else
MSG_EL	 db	 ' Elapsed time '
@ELAP1_SCOL equ  @PROG_SCOL + ($-MSG_EL)
	 db	 ' 0:00:00   Estimated time to completion '
@ETA1_SCOL equ	 @PROG_SCOL + ($-MSG_EL)
	 db	 ' 0:00:00 '
endif
@PROG_NROW equ	 ($-MSG_PROGSCR)/@PROG_NCOL

	 public  W_ELAP1
	 align	 2
W_ELAP1  W_STR	 <@ELAP1_SROW, @ELAP1_SCOL, @ELAP1_NROW, @ELAP1_NCOL>

@ELAP1_SROW equ  @PROG_SROW + @PROG_NROW - 1
@ELAP1_NROW equ  1

	 public  W_ELAP2
	 align	 2
W_ELAP2  W_STR	 <@ELAP2_SROW, @ELAP2_SCOL, @ELAP2_NROW, @ELAP2_NCOL>

@ELAP2_NROW equ  1

	 public  MSG_ETA_HR
	 db	 '   '          ; Handle overflow from MSG_ETA_HR
MSG_ETA_HR db	 ' 0:'
MSG_ETA_MIN db	 '00:'
MSG_ETA_SEC db	 '00'
@ETA1_NCOL equ	 $-MSG_ETA_HR
@ETA2_NCOL equ	 $-MSG_ETA_HR
@ETA1_NROW equ	 1
@ETA2_NROW equ	 1
@ETA1_SROW equ	 @PROG_SROW + @PROG_NROW - 1

	 public  W_ETA1
	 align	 2
W_ETA1	 W_STR	 <@ETA1_SROW, @ETA1_SCOL, @ETA1_NROW, @ETA1_NCOL>

	 public  W_ETA2
	 align	 2
W_ETA2	 W_STR	 <@ETA2_SROW, @ETA2_SCOL, @ETA2_NROW, @ETA2_NCOL>

	 public  W_PBAR
	 align	 2
W_PBAR	 W_STR	 <@PBAR_SROW, @PBAR_SCOL, @PBAR_NROW, @PBAR_NCOL>

@PBAR_NROW equ	 1
@PBAR_NCOL equ	 100/2

	 public  MSG_PBAR
MSG_PBAR db	 @PBAR_NCOL dup (' ')   ; Progress bar

	 public  MSG_PTSTQUIK,MSG_PTSTFULL,MSG_PTSTSAF,MSG_PTSTTF
	 public  MSG_PTSTLIN,MSG_PTSTUIN,MSG_PTSTLID,MSG_PTSTUID
	 public  MSG_PTSTCMP,MSG_PTSTALL,MSG_PTSTINT,MSG_PTSTGET
	 public  MSG_PTSTINI,MSG_PTSTERR
ifdef LANG_GR
MSG_PTSTQUIK db  '        Ablauf Kurztest (QUICK)       '
@PTST_NCOL equ	 $-MSG_PTSTQUIK
MSG_PTSTFULL db  '   Ablauf vollstÑndiger Test (FULL)   '
MSG_PTSTSAF  db  '         Ablauf Blockieren-Test       '
MSG_PTSTTF   db  '      Ablauf öbergangsfehler-Test     '
MSG_PTSTLIN  db  ' Test verkettete Inversions-Kopplung  '
MSG_PTSTUIN  db  ' Test unabhÑngige Inversions-Kopplung '
MSG_PTSTLID  db  ' Test verkettete Folge-Stop Kopplung  '
MSG_PTSTUID  db  ' Test unabhÑngige Folge-Stop Kopplung '
MSG_PTSTCMP db	 '          TEST ABGESCHLOSSEN          '
MSG_PTSTALL db	 '               DAUERTEST              '
MSG_PTSTERR db	 '          FEHLER AUFGETRETEN          '
MSG_PTSTINT db	 '           TEST UNTERBROCHEN          '
MSG_PTSTGET db	 '          Allokiere Speicher...       '
MSG_PTSTINI db	 '                                      '
@PTST_NROW equ	 1
else
MSG_PTSTQUIK db  '          Running QUICK Test          '
@PTST_NCOL equ	 $-MSG_PTSTQUIK
MSG_PTSTFULL db  '           Running FULL Test          '
MSG_PTSTSAF  db  '     Running Stuck-At Fault Test      '
MSG_PTSTTF   db  '    Running Transition Fault Test     '
MSG_PTSTLIN  db  '    Running Linked Inversion Test     '
MSG_PTSTUIN  db  '   Running Unlinked Inversion Test    '
MSG_PTSTLID  db  '    Running Linked Idempotent Test    '
MSG_PTSTUID  db  '   Running Unlinked Idempotent Test   '
MSG_PTSTCMP db	 '             TEST COMPLETE            '
MSG_PTSTALL db	 '          CONTINUOUS TESTING          '
MSG_PTSTERR db	 '          ERROR ENCOUNTERED           '
MSG_PTSTINT db	 '           TEST INTERRUPTED           '
MSG_PTSTGET db	 '          Allocating Memory...        '
MSG_PTSTINI db	 '                                      '
@PTST_NROW equ	 1
endif
@PTST_SCOL equ	 @PROG_SCOL + (@PROG_NCOL - @PTST_NCOL)/2

ifdef LANG_GR
.err Needs translation
else
MSG_TN_USF  db	', 0 - Stuck-At Fault test',0
MSG_TN_UTF  db	', 1 - Transition Fault test',0
MSG_TN_LIN  db	', 2 - Linked Inversion Test',0
MSG_TN_UIN  db	', 3 - Unlinked Inversion Test',0
MSG_TN_LID  db	', 4 - Linked Idempotent Test',0
MSG_TN_UID  db	', 5 - Unlinked Idempotent Test',0
endif

ifdef LANG_GR
.err Needs translation
else
	public	MSG_TIME_HDR,MSG_TIME
	public	MSG_TIME_BEG_HR,MSG_TIME_BEG_MIN,MSG_TIME_BEG_SEC
	public	MSG_TIME_END_HR,MSG_TIME_END_MIN,MSG_TIME_END_SEC
MSG_TIME_HDR db CR,LF
	db	'     Test Times',CR,LF
	db	'--------------------',CR,LF,0
;;;;;;; 	'nn:nn:nn to nn:nn:nn',0
MSG_TIME label	byte
MSG_TIME_BEG_HR  db 'nn:'
MSG_TIME_BEG_MIN db 'nn:'
MSG_TIME_BEG_SEC db 'nn to '
MSG_TIME_END_HR  db 'nn:'
MSG_TIME_END_MIN db 'nn:'
MSG_TIME_END_SEC db 'nn'
	db	0
endif
	align	2

	public	PMSG_PTST
PMSG_PTST dw	offset DGROUP:MSG_PTSTQUIK
	dw	offset DGROUP:MSG_PTSTFULL
	dw	offset DGROUP:MSG_PTSTSAF
	dw	offset DGROUP:MSG_PTSTTF
	dw	offset DGROUP:MSG_PTSTLIN
	dw	offset DGROUP:MSG_PTSTUIN
	dw	offset DGROUP:MSG_PTSTLID
	dw	offset DGROUP:MSG_PTSTUID

	public	PMSG_TSTNAM
PMSG_TSTNAM dw	offset DGROUP:MSG_TN_USF
	dw	offset DGROUP:MSG_TN_UTF
	dw	offset DGROUP:MSG_TN_LIN
	dw	offset DGROUP:MSG_TN_UIN
	dw	offset DGROUP:MSG_TN_LID
	dw	offset DGROUP:MSG_TN_UID

	public	W_PTST
W_PTST	W_STR	<@PTST_SROW, @PTST_SCOL, @PTST_NROW, @PTST_NCOL>

	public	MSG_HALTSCR
ifdef LANG_GR
MSG_HALTSCR db	 '                          '
@HALT_NCOL equ	 $-MSG_HALTSCR
	 db	 '  Taste ESC stoppt den    '
	 db	 '  laufenden Test, jede    '
	 db	 '  andere Taste setzt den  '
	 db	 '  Test fort:              '
	 db	 '                          '
else
MSG_HALTSCR db	 '                          '
@HALT_NCOL equ	 $-MSG_HALTSCR
	 db	 ' Press Esc again to stop  '
	 db	 ' the test in progress or  '
	 db	 ' press any other key to   '
	 db	 ' resume testing:          '
	 db	 '                          '
endif
@HALT_NROW equ	 ($-MSG_HALTSCR)/@HALT_NCOL

@HALT_SROW equ	 ((@NROWS - 1) - @HALT_NROW)/2 - 1 ; Center on screen
@HALT_SCOL equ	 ((@NCOLS - 1) - @HALT_NCOL)/2 ; ...

	 public  W_HALT
W_HALT	 W_STR	 <@HALT_SROW, @HALT_SCOL, @HALT_NROW, @HALT_NCOL>

	 public  LOGA,LOGB,LOGDATE,LOGC,LOGTIME,LOGD,LOGE,LOGF,LOGG
	 public  LOGF_K1,LOGF_K2,LOGF_H1,LOGF_H2,LOGF_K3
LOGA	 db	 CR,LF
	 db	 '*****************************************************',CR,LF,0
LOGB	 db	 CR,LF
ifdef LANG_GR
	 db	 PNAME,' wurde ausgefÅhrt am ',0
else
%	 db	 PNAME,' was executed on ',0
endif				; IFDEF LANG_GR
LOGDATE db	'xx/xx/xxxx',0
LOGC	 label byte
ifdef LANG_GR
	 db				     ' um ',0
else
	 db				     ' at ',0
endif				; IFDEF LANG_GR
LOGTIME db	'hh:mm xx',0
LOGD	 label byte
ifdef LANG_GR
	 db						 ' mit den folgenden',CR,LF
	 db	 'Optionen: ',0
else
	 db						 ' with the following',CR,LF
	 db	 'options: ',0
endif				; IFDEF LANG_GR
LOGE	 db								CR,LF
	 db	 CR,LF
ifdef LANG_GR
	 db	 'Die folgenden Speicherbereiche wurden ÅberprÅft:',CR,LF
else
	 db	 'The following memory ranges were tested:',CR,LF
endif				; IFDEF LANG_GR
	 db	 CR,LF,0
LOGF	 db	 'xxxxx'
LOGF_K1  db	      'xK - xxxxx'
LOGF_K2  db			'xK ('
LOGF_H1  db			    'xxxxxxxx-'
LOGF_H2  db				     'xxxxxxxx) xxxxx'
LOGF_K3  db						    'xK',CR,LF,0
LOGG	 db	 CR,LF,0

	 public  LOG_MEMERR,LOG_MEMERR1,LOG_NMIERR,LOG_NMIERR1,LOG_NOERR
	 public  LOG_HALT
LOG_MEMERR db	 '     '
ifdef LANG_GR
LOG_MEMERR1 db	 '_ Speicherfehler.',CR,LF,0
LOG_NMIERR db	 '     '
LOG_NMIERR1 db	 '_ ParitÑtsfehler.',CR,LF,0
LOG_HALT db	 'TESTS VOM ANWENDER ABGEBROCHEN.',CR,LF,0
LOG_NOERR db	 'KEINE FEHLER FESTGESTELLT.',CR,LF,0
else
LOG_MEMERR1 db	 '_ memory error(s).',CR,LF,0
LOG_NMIERR db	 '     '
LOG_NMIERR1 db	 '_ parity error(s).',CR,LF,0
LOG_NOERR db	 'NO ERRORS WERE DETECTED.',CR,LF,0
LOG_HALT db	 'TESTS CANCELLED BY USER.',CR,LF,0
endif

	 public  MSG_BYTERR,MSG_WORDERR,MSG_DWORDERR,MSG_NMIERROR,MSG_ADDR
ifdef LANG_GR
MSG_BYTERR db	 'Byte Abweichung bei ',0
MSG_WORDERR db	 'Word Abweichung bei ',0
MSG_DWORDERR db  'Dword Abweichung bei ',0
MSG_NMIERROR db  'ParitÑtsfehler bei ',0
else
MSG_BYTERR db	 'Byte mismatch at ',0
MSG_WORDERR db	 'Word mismatch at ',0
MSG_DWORDERR db  'Dword mismatch at ',0
MSG_NMIERROR db  'Parity error at ',0
endif
MSG_ADDR db	 '________',0

	 public  MSG_EXP,MSG_EXP1,MSG_EXP2,MSG_EXP3
ifdef LANG_GR
MSG_EXP db	 '; erwartet ',0
else
MSG_EXP db	 '; expected ',0
endif
	 db	 '______'
ifdef LANG_GR
MSG_EXP1 db	       '__, erhalten ',0
else
MSG_EXP1 db	       '__, actual ',0
endif
	 db	 '______'
MSG_EXP2 db	       '__',0
MSG_EXP3 db	 '.',CR,LF,0

; =============== Messages used principally by MEM_HELP.ASM ===================

	 public  W_HKEY,W_HKEYERR,W_HKEYF2
	 align	 2
W_HKEY	 W_STR	 <@HKEY_SROW, @HKEY_SCOL, @HKEY_NROW,	 @HKEY_NCOL>
W_HKEYERR W_STR  <@HKEY_SROW, @HKEY_SCOL, @HKEYERR_NROW, @HKEYERR_NCOL>
W_HKEYF2 W_STR	 <@HKEY_SROW, @HKEY_SCOL+@HKEY_F2COL, 1, @HKEY_F2NCOL>

	 public  MSG_HKEYERR
ifdef LANG_GR
MSG_HKEYERR db	 '                         ESC=ZurÅck zum Memory Tester                         '
else
MSG_HKEYERR db	 '                    Press ESC to return to Memory Tester                      '
endif
@HKEYERR_NCOL equ $-MSG_HKEYERR
@HKEYERR_NROW equ ($-MSG_HKEYERR)/@HKEYERR_NCOL

	 public  MSG_HKEY
ifdef LANG_GR
MSG_HKEY db	 'ESC=ZurÅck zum Hilfe-MenÅ                              '
@HKEY_F2COL equ  $-MSG_HKEY
	 db	 'F2=Druck Hilfe-Themen  '
@HKEY_NCOL equ	 $-MSG_HKEY
@HKEY_F2NCOL equ @HKEY_NCOL-@HKEY_F2COL
	 db	 'F3=Vorangehendes Hilfe-Thema                           F4=NÑchstes Hilfe-Thema'
else
MSG_HKEY db	 'Press ESC to return to Help Menu               '
@HKEY_F2COL equ  $-MSG_HKEY
	 db	 'Press F2 to print Help Topic(s)'
@HKEY_NCOL equ	 $-MSG_HKEY
@HKEY_F2NCOL equ @HKEY_NCOL-@HKEY_F2COL
	 db	 'Press F3 to see previous Help Topic            Press F4 to see next Help Topic'
endif
@HKEY_NROW equ	 ($-MSG_HKEY)/@HKEY_NCOL

@HKEY_SROW equ	 (@NROWS - 1) - (@HKEY_NROW - 1)
@HKEY_SCOL equ	 1

	 public  W_HELP
	 align	 2
W_HELP	 W_STR	 <@HELP_SROW, @HELP_SCOL, @HELP_NROW, @HELP_NCOL>

	 public  MSG_HELP
ifdef LANG_GR
MSG_HELP db	 '                            '
@HELP_NCOL equ	 $-MSG_HELP
	 db	 '   Eingabetaste wÑhlt ein   '
	 db	 '        Hilfe-Thema         '
	 db	 '                            '
@HLIN_SROW equ	 @HELP_SROW + ($-MSG_HELP)/@HELP_NCOL
MSG_HLIN db	 '  Steuerung in ',PNAME,'     ',PDIFF
	 db	 '  öberblick zu ',PNAME,'     ',PDIFF
	 db	 '  Info Åber die Tests       '
	 db	 '  Speicher & ParitÑtsfehler '
	 db	 '  Befehlszeilen-Schalter    '
else
MSG_HELP db	 '                            '
@HELP_NCOL equ	 $-MSG_HELP
	 db	 '  Press Enter to Select a   '
	 db	 '         Help Topic         '
	 db	 '                            '
@HLIN_SROW equ	 @HELP_SROW + ($-MSG_HELP)/@HELP_NCOL
MSG_HLIN db	 '  Navigating ',PNAME,PDIFF,'       '
	 db	 '  Overview of ',PNAME,PDIFF,'      '
	 db	 '  About the Tests           '
	 db	 '  Memory and Parity Errors  '
	 db	 '  Command Line Switches     '
endif
	 public  @HLIN_LEN
@HLIN_LEN equ	 ($-MSG_HLIN)/@HELP_NCOL
ifdef LANG_GR
	 db	 '                            '
	 db	 '  Mit ESC erreichen Sie den '
	 db	 '      Hauptbildschirm       '
	 db	 '                            '
else
	 db	 '                            '
	 db	 '   Press ESC to Return to   '
	 db	 '      the Main Screen       '
	 db	 '                            '
endif
@HELP_NROW equ	 ($-MSG_HELP)/@HELP_NCOL

@HELP_SROW equ	 (@NROWS - 1 - @HELP_NROW)/2 + 4 ; Center the box (plus a little)
@HELP_SCOL equ	 (@NCOLS - 1 - @HELP_NCOL)/2 ; ...

	 public  W_HLIN
	 align	 2
W_HLIN	 W_STR	 <@HLIN_SROW, @HLIN_SCOL, @HLIN_NROW, @HLIN_NCOL>

	 public  HLIN_SROW
HLIN_SROW dw	 @HLIN_SROW	; Overcome forward reference problems

@HLIN_SCOL equ	 @HELP_SCOL + 1
@HLIN_NROW equ	 1
@HLIN_NCOL equ	 @HELP_NCOL - 2

@HASK_NROW equ	 @HLIN_LEN
@HASK_NCOL equ	 @HLIN_NCOL
@HASK_SCOL equ	 @HLIN_SCOL
@HASK_SROW equ	 @HLIN_SROW

	 public  W_HASK
W_HASK	 W_STR	 <@HASK_SROW, @HASK_SCOL, @HASK_NROW, @HASK_NCOL>

	 public  W_HSCR
W_HSCR	 W_STR	 <@HSCR_SROW, @HSCR_SCOL, @HSCR_NROW, @HSCR_NCOL>

	 public  W_HTTL
W_HTTL	 W_STR	 <@HTTL_SROW, @HTTL_SCOL, @HTTL_NROW, @HTTL_NCOL>

@HSCR_SROW equ	 1
@HSCR_SCOL equ	 2

@HSCR_NROW equ	 (@NROWS - 1) - (@HSCR_SROW + 2)
@HSCR_NCOL equ	 (@NCOLS - 1) - (@HSCR_SCOL + 2)

@HTTL_SROW equ	 @HSCR_SROW + 1 	; Skip one row to the title
@HTTL_SCOL equ	 @HSCR_SCOL + 1 	; Indent one col from the left
@HTTL_NROW equ	 1
@HTTL_NCOL equ	 @HSCR_NCOL - (1+3)	; Indent 1 for a space, 3 for elevator

	 public  @HTXT_SROW,@HTXT_SCOL,@HTXT_NCOL,@HTXT_NROW
@HTXT_SROW equ	 @HTTL_SROW + 1 	; Skip one row to the text
@HTXT_SCOL equ	 @HTTL_SCOL + 0
@HTXT_NROW equ	 (@HSCR_NROW - 2) - @HTTL_NROW ; Indent one row from top and
					; bottom, less # rows in title
@HTXT_NCOL equ	 @HTTL_NCOL + 0

	 public  W_HELEV
W_HELEV  W_STR	 <@HELEV_SROW, @HELEV_SCOL, @HELEV_NROW, 1>

	 public  @HELEV_SROW,@HELEV_NROW
@HELEV_SROW equ  @HTXT_SROW + 0
@HELEV_SCOL equ  @HTXT_SCOL + @HTXT_NCOL + 1
@HELEV_NROW equ  @HTXT_NROW + 0

	 public  MSG_HELEV
MSG_HELEV db	 '',(@HELEV_NROW-2) dup ('±'),''

	 public  W_HEBOX
	 align	 2
W_HEBOX  W_STR	 <?, @HELEV_SCOL, 1, 1>

	 public  MSG_CANCELLED,MSG_CANCELLED_LEN
ifdef LANG_GR
MSG_CANCELLED db 'Tests vom Anwender abgebrochen.',CR,LF
else
MSG_CANCELLED db 'Tests cancelled by user.',CR,LF
endif				; IFDEF LANG_GR
MSG_CANCELLED_LEN equ $-MSG_CANCELLED

DATA	 ends			; End DATA segment


NDATA	 segment use16 dword public 'data' ; Start NDATA segment
	 assume  ds:DGROUP

	 public  MSG_COPY
ifdef LANG_GR
MSG_COPY db	 PNAME,PDIFF,' -- Version '
ifdef @QMT
	 db	 VTEXT,' -- Der Qualitas Memory Tester',CR,LF
elseifdef @RAMDEMO
	 db	 VTEXT,' -- Qualitas RAMexam Demo',CR,LF
else ; @QMT
	 db	 VTEXT,' -- Qualitas RAMexam',CR,LF
endif ; @QMT
	 db	 '   (C) Copyright 1988-98 Qualitas, Inc. Alle Rechte vorbehalten.',CR,LF,EOS
else
MSG_COPY db	 PNAME,PDIFF,' -- Version '
ifdef @QMT
	 db	 VTEXT,' -- The Qualitas Memory Tester',CR,LF
elseifdef @RAMDEMO
	 db	 VTEXT,' -- Qualitas RAMexam Demo',CR,LF
else ; @QMT
	 db	 VTEXT,' -- Qualitas RAMexam',CR,LF
endif ; @QMT
	 db	 '   (C) Copyright 1988-98 Qualitas, Inc.  GNU General Public License version 3.',CR,LF,EOS
endif

	 public  MSG_NOT386,MSG_WIN3,MSG_NOTVM,MSG_XMEM,MSG_XMEM1,MSG_XMEM2
	 public  MSG_XMEMSEED
	 public  MSG_PRVEXT
	 public  MSG_MULBUG,MSG_NOMEM
ifdef LANG_GR
MSG_NOT386 db	 BEL,'ÕÕ> Falscher Maschinentyp: Mu· auf einer 80386 oder hîheren CPU laufen.',CR,LF,EOS
MSG_WIN3 db	 BEL,'ÕÕ> Windows ist aktiv: Bitte verlassen Sie Windows, um ',PNAME,' zu starten.',CR,LF
	 db	 CR,LF

	 db	     '    ',PNAME,' mu· zum Test den gesamten verfÅgbaren Speicher nutzen.',CR,LF
	 db	     '    Damit wÑre unter Windows kein weiterer Speicher fÅr andere ',CR,LF
	 db	     '    Programme frei. Aus diesem Grund empfehlen wir nicht, ',PNAME,CR,LF
	 db	     '    unter Windows ablaufen zu lassen.',CR,LF
MSG_NOTVM db	 BEL,'ÕÕ> Kann nicht in Protected Mode schalten; entfernen Sie Memory Manager',CR,LF
	 db	     '    oder stellen Sie sicher, da· ein EMS Seitenrahmen verfÅgbar ist.',CR,LF,EOS
MSG_XMEM db	 BEL,'ÕÕ> ACHTUNG! Grî·e des Extended Memory zeigt Differenz:',CR,LF
	 db	     '    CMOS =     '
MSG_XMEM1 db	 '_ KB, BIOS =     '
MSG_XMEM2 db	 '_ KB.',CR,LF
	 db	     '    Grî·eren oder kleineren Wert verwenden [G/K]?  ',EOS
;;;;;;;; ### S/L changes to G/K ###
MSG_XMEMSEED db  BS,'S',BS,EOS
else
MSG_NOT386 db	 BEL,'ÕÕ> Wrong machine type:  Must run on an 80386 or later CPU.',CR,LF,EOS
MSG_WIN3 db	 BEL,'ÕÕ> Windows Active:  Please exit Windows in order to run ',PNAME,'.',CR,LF
	 db	 CR,LF
	 db	     '    ',PNAME,' needs to allocate all available memory for testing.  This',CR,LF
	 db	     '    would leave no additional memory for other programs running under ',CR,LF
	 db	     '    Windows. Because of this, we do not recommend running ',PNAME,' under',CR,LF
	 db	     '    Windows.',CR,LF
	 db	     EOS

MSG_NOTVM db	 BEL,'ÕÕ> Unable to enter protected mode; either remove memory manager',CR,LF
	 db	     '    or ensure that an EMS page frame is available.',CR,LF,EOS
MSG_XMEM db	 BEL,'ÕÕ> Warning!  Extended memory sizes disagree:',CR,LF
	 db	     '    CMOS =     '
MSG_XMEM1 db	 '_ KB, BIOS =     '
MSG_XMEM2 db	 '_ KB.',CR,LF
	 db	     '    Use the smaller or larger [S/L]?  ',EOS
MSG_XMEMSEED db  BS,'S',BS,EOS
endif
	 public  @MSG_SMALL,@MSG_LARGE
ifdef LANG_GR
@MSG_SMALL equ	 'g'            ; First letter of Smaller in lowercase
@MSG_LARGE equ	 'k'            ; ...             Larger ...
else
@MSG_SMALL equ	 's'            ; First letter of Smaller in lowercase
@MSG_LARGE equ	 'l'            ; ...             Larger ...
endif

ifdef LANG_GR
MSG_PRVEXT db	 BEL,'ÕÕ> Extended Memory belegt:',CR,LF
	 db	     '    Entfernen Sie Software, die Extended Memory belegt.',CR,LF,EOS
MSG_MULBUG db	 BEL,'ÕÕ> Die CPU hat einen Fehler in der Multiplikations-Instruktion entdeckt:',CR,LF
	 db	     '    Zur Fehlerbehebung mÅssen Sie die CPU auswechseln.',CR,LF,EOS
MSG_NOMEM db	 BEL,'ÕÕ> Es gibt kein Extended Memory zu testen.',CR,LF,EOS
else
MSG_PRVEXT db	 BEL,'ÕÕ> Extended memory in use:',CR,LF
	 db	     '    Remove software using extended memory.',CR,LF,EOS
MSG_MULBUG db	 BEL,'ÕÕ> The CPU has detected a bug in the multiply instruction:',CR,LF
	 db	     '    To correct the problem, you must replace the CPU.',CR,LF,EOS
MSG_NOMEM db	 BEL,'ÕÕ> There is no extended memory to test.',CR,LF,EOS
endif

	 public  MSG_ASKCLR
ifdef LANG_GR
MSG_ASKCLR db	 'Ist das folgende Zeichen in Farbe [J/N]?    ',EOS
else
MSG_ASKCLR db	 'Is the following character in color [Y/N]?  ',EOS
endif

	 public  MSG_CRLF
MSG_CRLF db	 CR,LF,EOS

	 public  MSG_EISA
ifdef LANG_GR
MSG_EISA db	 'PrÅfe EISA Speicher...',EOS
else
MSG_EISA db	 'Checking EISA memory...',EOS
endif

	 public  MSG_UNK
ifdef LANG_GR
MSG_UNK  db	 BEL,'ÕÕ> unbekanntes SchlÅsselwort:  ',EOS
else
MSG_UNK  db	 BEL,'ÕÕ> Unknown keyword:  ',EOS
endif

	 public  MSG_SEP,MSG_VAL,MSG_OVF
	public	MSG_OPEN,MSG_READ,MSG_NAME,MSG_PARSE
ifdef LANG_GR
MSG_SEP  db	 BEL,'ÕÕ> fehlendes Trennzeichen:  ',EOS
MSG_VAL  db	 BEL,'ÕÕ> fehlender Wert:  ',EOS
MSG_OVF  db	 BEL,'ÕÕ> Wert au·erhalb des Bereiches:  ',EOS
.err Needs translation
MSG_OPEN db	 BEL,'ÕÕ> Unable to open file:  ',EOS
MSG_READ db	 BEL,'ÕÕ> Unable to read file:  ',EOS
MSG_NAME db	 BEL,'ÕÕ> Unknown keyword in file:  ',EOS
MSG_PARSE db	 BEL,'ÕÕ> Unable to parse line in file:  ',EOS
else
MSG_SEP  db	 BEL,'ÕÕ> Missing separator:  ',EOS
MSG_VAL  db	 BEL,'ÕÕ> Missing value:  ',EOS
MSG_OVF  db	 BEL,'ÕÕ> Value out of range:  ',EOS
MSG_OPEN db	 BEL,'ÕÕ> Unable to open file:  ',EOS
MSG_READ db	 BEL,'ÕÕ> Unable to read file:  ',EOS
MSG_NAME db	 BEL,'ÕÕ> Unknown keyword in file:  ',EOS
MSG_PARSE db	 BEL,'ÕÕ> Unable to parse line in file:  ',EOS
endif

	 public  MSG_CMDS
ifdef LANG_GR
MSG_CMDS db	 PNAME,' Optionen:',CR,LF
	 db	 CR,LF
ifdef @QMT			; If we are building QMT
	 db	 '                        QMT KOMPATIBILITéTS-OPTIONEN',CR,LF
else
	 db	 '                      ',PNAME,' KOMPATIBILITéTS-OPTIONEN',CR,LF
endif				; If we are building QMT
	 db	 '  K                   vermeidet Tastaturprobleme wÑhrend ',PNAME,'-Ablauf',CR
;;;;;;;; db	 '  NOSCRUB             vermeidet PrÅfung von zusÑtzlich gewonnenem Speicher',CR,LF
	 db	 '  NOXRAM              macht besonderen Zusatzspeicher nicht ausdrÅcklich nutzbar',CR,LF
;;;;;;;; db	 '  SHADOWRAM           macht Schatten-RAM nutzbar (C&T CHIPSet-Kompatible)',CR,LF
	 db	 '  TOP384              macht 384KB COMPAQ-Ñhnlichen Speicher nutzbar',CR,LF
	 db	 '  NOPARITY            vermeidet ParitÑtsfehler bei einigen Systemen',CR,LF
	 db	 '  NODPMI              verwendet keine DPMI Services',CR,LF
	 db	 '  NOVCPI              verwendet keine VCPI Services',CR,LF
	 db	 '  L                   verwendet grî·ere BIOS und CMOS Werte bei Abweichungen.',CR,LF
	 db	 '  S                   verwendet kleinere BIOS und CMOS Werte bei Abweichungen.',CR,LF
;;;;;;;; db	 '  DEBUG=FAULT         to debug any fault-processing code',CR,LF
;;;;;;;; db	 '  DEBUG=TIME          to debug memory timing tests',CR,LF
	 db	 CR,LF
ifdef @QMT			; If we are building QMT
	 db	 '                         QMT TESTVERFAHREN-OPTIONEN',CR,LF
else
	 db	 '                       ',PNAME,' TESTVERFAHREN-OPTIONEN',CR,LF
endif
	 db	 '  SAF=nn              prÅft auf Blockieren, nn DurchlÑufe',CR,LF
	 db	 '  TF=nn               prÅft auf öbergangsfehler, nn DurchlÑufe',CR,LF
	 db	 '  UNLINV=nn           prÅft auf unabhÑnige Inversions-Kopplung, nn DurchlÑufe',CR,LF
	 db	 '  UNLIDM=nn           prÅft auf unabhÑnige Folge-Stop Kopplung, nn DurchlÑufe',CR,LF
	 db	 '  LNKINV=nn           prÅft auf verkettete Inversions-Kopplung, nn DurchlÑufe',CR,LF
	 db	 '  LNKIDM=nn           prÅft auf verkettete Folge-Stop Kopplung, nn DurchlÑufe',CR,LF
	 db	 '  QUICK=nn            fÅhrt Kurztests (Quick-Test) nn mal durch',CR,LF
	 db	 '  FULL=nn             fÅhrt vollstÑndige Tests nn mal durch',CR,LF
	 db	 '  ALL=nn              fÅhrt alle Tests nn mal durch',CR,LF
	 db	 CR,LF
ifdef @QMT			; If we are building QMT
	 db	 '                            QMT ANZEIGE-OPTIONEN',CR,LF
else
	 db	 '                          ',PNAME,' ANZEIGE-OPTIONEN',CR,LF
endif
	 db	 '  ADVANCED            startet im erweiterten Modus',CR,LF
	 db	 '  HEX                 startet im hexadezimalen Modus',CR,LF
	 db	 '  NOEXIT              kein Programmende nach automatischem Testablauf',CR,LF
	 db	 '  BW oder /B          zeigt Bildschirme schwarzwei·',CR,LF
	 db	 '  COLOR oder /C       zeigt Bildschirme in Farbe',CR,LF
	 db	 CR,LF
ifdef @RAMEXEAM 		; If we are building RAMEXAM
	 db	 '                         ',PNAME,' ABLAUFPLAN-OPTIONEN',CR,LF
	 db	 '  DAILY               ',PNAME,' lÑuft einmal tÑglich',CR,LF
	 db	 '  WEEKLY[=tag]        ',PNAME,' lÑuft einmal pro Woche. Ist wahlfrei ein Tag',CR,LF
	 db	 '                      angegeben, lÑuft ',PNAME,' an oder nach diesem'CR,LF
	 db	 '                      Wochentag (Sonntag=1, Montag=2, usw.)',CR,LF
	 db	 '  MONTHLY[=datum]     ',PNAME,' lÑuft einmal pro Monat. Ist wahlfrei ein Tag',CR,LF
	 db	 '                      angegeben lÑuft ',PNAME,' an oder nach diesem',CR,LF
	 db	 '                      Tag im Monat (1-31).',CR,LF
	 db	 '  INTERVAL=n          ',PNAME,' lÑuft nach n Tagen',CR,LF
	 db	 '                      seit dem letzten ',PNAME,'-Lauf.',CR,LF
	 db	 '  ASK[=zeit,antwort]  Fordert Aktion mit einer Voreinstellung an,',CR,LF
	 db	 '                      die nach angegebenem Zeitablauf ausgefÅhrt wird:',CR,LF
	 db	 '                      J (JA)       fÅhrt ',PNAME,' aus',CR,LF
	 db	 '                      N (Nein)     Åbergeht Test und wartet auf nÑchstes',CR,LF
	 db	 '                                   geplante Ereignis.',CR,LF
	 db	 '                      S (SpÑter)   Åbergeht Test, fragt spÑter wieder.',CR,LF
	 db	 '  LOG[=dateiname][,n] HÑngt einen Log-Eintrag an ',PUNAME,'.LOG oder andere',CR,LF
	 db	 '                      Datei an. Parameter ,n (neu) ersetzt die alte Datei.',CR,LF
.err Needs Translation
	 db	 '  TONE[=filename]     sound tones using defaults or from specified file',CR,LF
	 db	 '                      when certain events occur.',CR,LF
	 db	 CR,LF
	 db	 '  ?                   zeigt diesen Hilfe-Bildschirm',CR,LF
endif
	 db	 0
else
MSG_CMDS db	 PNAME,' Options:',CR,LF
	 db	 CR,LF
ifdef @QMT			; If we are building QMT
	 db	 '                          QMT COMPATIBILITY OPTIONS',CR,LF
else
	 db	 '                        ',PNAME,' COMPATIBILITY OPTIONS',CR,LF
endif
	 db	 '  K                   avoid spurious keyboard lockups',CR,LF
;;;;;;;; db	 '  NOSCRUB             to avoid scrubbing extra recovered memory',CR,LF
	 db	 '  NOXRAM              do not recover extra memory',CR,LF
;;;;;;;; db	 '  SHADOWRAM           to recover shadow RAM (C&T CHIPSet-compatible)',CR,LF
	 db	 '  TOP384              recover 384KB COMPAQ-like memory',CR,LF
	 db	 '  NOPARITY            avoid spurious parity errors on certain systems',CR,LF
	 db	 '  NODPMI              do not use DPMI services',CR,LF
	 db	 '  NOVCPI              do not use VCPI services',CR,LF
	 db	 '  L                   use larger of BIOS and CMOS sizes if they differ',CR,LF
	 db	 '  S                   use smaller of BIOS and CMOS sizes if they differ',CR,LF
	 db	 '  V                   to disable VLSI 82C480 cache controller',CR,LF
;;;;;;;; db	 '  DEBUG=FAULT         to debug any fault-processing code',CR,LF
;;;;;;;; db	 '  DEBUG=TIME          to debug memory timing tests',CR,LF
	 db	 CR,LF
ifdef @QMT			; If we are building QMT
	 db	 '                            QMT TEST TYPE OPTIONS',CR,LF
else
	 db	 '                          ',PNAME,' TEST TYPE OPTIONS',CR,LF
endif
	 db	 '  SAF=nn              run Stuck-At Fault Test nn times',CR,LF
	 db	 '  TF=nn               run Transition Fault Test nn times',CR,LF
	 db	 '  UNLINV=nn           run Unlinked Inversion Coupling Fault Test nn times',CR,LF
	 db	 '  UNLIDM=nn           run Unlinked Idempotent Coupling Fault Test nn times',CR,LF
	 db	 '  LNKINV=nn           run Linked Inversion Coupling Fault Test nn times',CR,LF
	 db	 '  LNKIDM=nn           run Linked Idempotent Coupling Fault Test nn times',CR,LF
	 db	 '  QUICK=nn            run Quick tests nn times',CR,LF
	 db	 '  FULL=nn             run Full tests nn times',CR,LF
	 db	 '  ALL=nn              run all tests nn times',CR,LF
	 db	 CR,LF
ifdef @QMT			; If we are building QMT
	 db	 '                             QMT DISPLAY OPTIONS',CR,LF
else
	 db	 '                           ',PNAME,' DISPLAY OPTIONS',CR,LF
endif
	 db	 '  ADVANCED            start execution in advanced mode',CR,LF
	 db	 '  HEX                 start execution in hexadecimal mode',CR,LF
	 db	 '  NOEXIT              do not exit after running tests automatically',CR,LF
	 db	 '  BW or /B            force black & white display',CR,LF
	 db	 '  COLOR or /C         force color display',CR,LF
	 db	 CR,LF
ifdef @RAMEXAM
	 db	 '                          ',PNAME,' SCHEDULING OPTIONS',CR,LF
	 db	 '  DAILY               run ',PNAME,' only if it has not been run since midnight',CR,LF
	 db	 '  WEEKLY[=day]        run ',PNAME,' only if it has not been run in the last week',CR,LF
	 db	 '                      -- if optional day is specified, ',PNAME,' will run on or',CR,LF
	 db	 '                      after that day of the week (Sunday=1, Monday=2, etc.)',CR,LF
	 db	 '  MONTHLY[=date]      run ',PNAME,' only if it has not run in the last month --',CR,LF
	 db	 '                      if option date is specified, ',PNAME,' will run on or after',CR,LF
	 db	 '                      that day of the month (1-31)',CR,LF
	 db	 '  INTERVAL=n          run ',PNAME,' only if at least n days have expired',CR,LF
	 db	 '                      since the last time ',PNAME,' was run',CR,LF
	 db	 '  ASK[=timeout,response] Prompt for action to take, with a default',CR,LF
	 db	 '                      response to be used after timeout seconds:',CR,LF
	 db	 '                      Y (Yes)      run ',PNAME,CR,LF
	 db	 '                      N (No)       skip test and wait until next',CR,LF
	 db	 '                                   scheduled occurrence',CR,LF
	 db	 '                      P (Postpone) skip test; ask again later',CR,LF
	 db	 '  LOG[=filename][,o]  append a log entry to ',PUNAME,'.LOG or other',CR,LF
	 db	 '                      filename and use o to overwrite any existing file of the',CR,LF
	 db	 '                      same name',CR,LF
	 db	 '  TONE[=filename]     sound tones using defaults or from specified file',CR,LF
	 db	 '                      when certain events occur.',CR,LF
	 db	 CR,LF
endif ; @RAMEXAM
	 db	 '  ?                   display this help message',CR,LF
	 db	 0
endif

	 public  MSG_PAK
MSG_PAK  label byte
ifdef LANG_GR
	 db	 'Weiter mit beliebiger Taste...',EOS
else
	 db	 'Press any key to continue...',EOS
endif

; =============== Messages used principally by MEM_CMD.ASM ====================

	 public  MSG_UNSCHED,MSG_UNSCHED_DATE
ifdef LANG_GR
MSG_UNSCHED db	 PNAME,' ist nicht eingestellt zum Ablauf vor '
else
MSG_UNSCHED db	 PNAME,' is not scheduled to run until '
endif
MSG_UNSCHED_DATE db 'xxxxxxxday, xx/xx/xxxx',CR,LF,EOS

	 public  SUNDAY,MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY
ifdef LANG_GR
SUNDAY	 db	 'Sonntag',0
MONDAY	 db	 'Montag',0
TUESDAY  db	 'Dienstag',0
WEDNESDAY db	 'Mittwoch',0
THURSDAY db	 'Donnerstag',0
FRIDAY	 db	 'Freitag',0
SATURDAY db	 'Samstag',0
else
SUNDAY	 db	 'Sunday',0
MONDAY	 db	 'Monday',0
TUESDAY  db	 'Tuesday',0
WEDNESDAY db	 'Wednesday',0
THURSDAY db	 'Thursday',0
FRIDAY	 db	 'Friday',0
SATURDAY db	 'Saturday',0
endif

	 public  MSG_QMTDAT,@MSG_QMTDAT_LEN
ifdef LANG_GR
MSG_QMTDAT db	 'Diese Datei wird fÅr den ',PNAME,' Ablaufplan verwendet.',CR,LF
else
MSG_QMTDAT db	 'This file used for ',PNAME,' scheduling.',CR,LF
endif
@MSG_QMTDAT_LEN equ $-MSG_QMTDAT

@ASKCMD_SROW equ 5
@ASKCMD_SCOL equ 15

	 public  W_ASKCMD,W_ASKCMDBACK,W_ASKCMDREM
	 align	 2
W_ASKCMD W_STR	<@ASKCMD_SROW, @ASKCMD_SCOL, \
		 @ASKCMD_NROW, @ASKCMD_NCOL>
W_ASKCMDBACK W_STR <@ASKCMD_SROW-2, @ASKCMD_SCOL-5, \
		    @ASKCMD_NROW+4, @ASKCMD_NCOL+10>
W_ASKCMDREM W_STR <@ASKCMD_SROW +  @ASKCMD_SREMROW, @ASKCMD_SCOL, \
		   1, @ASKCMD_NCOL>


	 public  MSG_YESA,MSG_YESB
ifdef LANG_GR
MSG_YESA db	 ' Æ  Ja  Ø '
MSG_YESB db	 '    Ja    '
else
MSG_YESA db	 ' Æ Yes  Ø '
MSG_YESB db	 '   Yes    '
endif

	 public  MSG_NOA,MSG_NOB
ifdef LANG_GR
MSG_NOA db	 ' Æ Nein Ø '
MSG_NOB db	 '   Nein   '
else
MSG_NOA db	 ' Æ  No  Ø '
MSG_NOB db	 '    No    '
endif

	 public  MSG_PPA,MSG_PPB
ifdef LANG_GR
MSG_PPA db	 ' Æ  SpÑter  Ø '
MSG_PPB db	 '    SpÑter    '
else
MSG_PPA db	 ' Æ Postpone Ø '
MSG_PPB db	 '   Postpone   '
endif

	 public  MSG_ASKCMD,MSG_ASKCMDOPT,@ASKCMD_SREMROW
MSG_ASKCMD label byte
	 db	 '                                                '
@ASKCMD_NCOL equ $-MSG_ASKCMD
ifdef LANG_GR
	 db	 '  ',PDIFF_2a,PNAME,' verwendet fÅr den Systemtest          ',PDIFF_2b
	 db	 '   derzeit folgende Optionen/Tests:             '
	 db	 '                                                '
	 db	 '                    (kei'
MSG_ASKCMDOPT db			 'ne)                     '
	 db	 '                                                '
	 db	 '      Soll der Test jetzt ablaufen?             '
else
	 db	 '  ',PDIFF_2a,PNAME,' is scheduled to test your system      ',PDIFF_2b
	 db	 '   memory using the following options/tests:    '
	 db	 '                                                '
	 db	 '                     (no'
MSG_ASKCMDOPT db			 'ne)                     '
	 db	 '                                                '
	 db	 '      Would you like the test to run now?       '
endif
	 db	 '                                                '
@ACMDITEM1_SROW equ  @ASKCMD_SROW + ($-MSG_ASKCMD)/@ASKCMD_NCOL
;;;;;;;; db	 '      Yes           No          Postpone        '
MSG_ASKCMDYNP label byte
	 db	 '   '
@ACMDITEM1_SCOL1 equ  @ASKCMD_SCOL + ($-MSG_ASKCMDYNP)
MSG_ASKCMDY label byte
ifdef LANG_GR
	 db	    '    Ja    '
else
	 db	    '   Yes    '
endif
@ACMDITEM1_NCOL1 equ  ($-MSG_ASKCMDY)
	 db	 '   '
@ACMDITEM1_SCOL2 equ  @ASKCMD_SCOL + ($-MSG_ASKCMDYNP)
MSG_ASKCMDN label byte
ifdef LANG_GR
	 db	 '   Nein   '
else
	 db	 '    No    '
endif
@ACMDITEM1_NCOL2 equ  ($-MSG_ASKCMDN)
	 db	 '   '
@ACMDITEM1_SCOL3 equ  @ASKCMD_SCOL + ($-MSG_ASKCMDYNP)
MSG_ASKCMDP label byte
ifdef LANG_GR
	 db	 '    SpÑter    '
else
	 db	 '   Postpone   '
endif
@ACMDITEM1_NCOL3 equ  ($-MSG_ASKCMDP)
	 db	 '     '
	 db	 '                                                '
	 db	 '                                                '
@ASKCMD_SREMROW equ ($-MSG_ASKCMD)/@ASKCMD_NCOL
	 db	 '                                                '
@ASKCMD_NROW equ ($-MSG_ASKCMD)/@ASKCMD_NCOL

	 public  MSG_ASKCMDREM,FMT_ASKCMDREM
ifdef LANG_GR
MSG_ASKCMDREM db '   Verbleibende Zeit:        '
FMT_ASKCMDREM db			      '_ Sekunden         '
else
MSG_ASKCMDREM db '   Time remaining:           '
FMT_ASKCMDREM db			      '_ seconds          '
endif					; IFDEF LANG_GR

@ACHLP_SROW equ 8
@ACHLP_SCOL equ 18

	 public  ARR_W_ITEM3,W_ACHLP
	 align	 2
ARR_W_ITEM3 label tbyte
	 W_STR	 <@ACMDITEM1_SROW + 0, @ACMDITEM1_SCOL1, 1, @ACMDITEM1_NCOL1>
	 W_STR	 <@ACMDITEM1_SROW + 0, @ACMDITEM1_SCOL2, 1, @ACMDITEM1_NCOL2>
	 W_STR	 <@ACMDITEM1_SROW + 0, @ACMDITEM1_SCOL3, 1, @ACMDITEM1_NCOL3>
W_ACHLP  W_STR	<@ACHLP_SROW, @ACHLP_SCOL, \
		 @ACHLP_NROW, @ACHLP_NCOL>

NDATA	 ends			; End NDATA segment

	 MEND			; End MEM_MSGS module

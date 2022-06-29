;' $Header:   P:/PVCS/MAX/QMT/MEM_FALT.ASV   1.1   05 Jun 1998 14:03:22   BOB  $
	 title	 MEM_FALT -- MEMCHK Fault Checking Routines
	 page	 58,122
	 name	 MEM_FALT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment NDATA, dword-aligned, public, class 'data'

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include KEYCODE.INC
	 include VIDATTR.INC
	 include 386.INC
	 include PTR.INC
	 include BIOSDATA.INC
	 include OPCODES.INC
	 include ALLMEM.INC
	 include INTRNATL.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include 8255.INC

	 include MEM_BLK.INC
	 include MEM_SCRN.INC
	 include MEM_COM.MAC
	 include MEM_OEM.INC
.list

PGROUP	 group	 CODE
DGROUP	 group	 DATA,KEYSEG,ACTSEG,NDATA


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

ifdef @BETA
	 extrn	 DBG_FLAG:word
	 include MEM_DBG.INC
endif				; IFDEF @BETA
	 extrn	 GL2_FLAG:word
	 include MEM_GL2.INC

	 extrn	 GL3_FLAG:word
	 include MEM_GL3.INC

	 extrn	 TIMETAB:tbyte
	 include MEM_TIME.INC

	 extrn	 CMD_FLAG:word
	 include MEM_CMD.INC

	 extrn	 PAMEM:word

	 extrn	 LaCODE:dword

	 extrn	 HLTATTR:byte
	 extrn	 HLPATTR:byte
	 extrn	 ASKATTR:byte
	 extrn	 STATATTR:byte
	 extrn	 STATHATTR:byte
	 extrn	 STATLATTR:byte
	 extrn	 PRGATTR:byte
	 extrn	 PRG1ATTR:byte
	 extrn	 PRG2ATTR:byte
	 extrn	 AMEMATTR:byte
	 extrn	 WMEMATTR:byte
	 extrn	 BACKATTR:byte

	 extrn	 MEMTIMER:qword

	 extrn	 W_MEMWRK:tbyte

	 extrn	 CLRMODE:word

	 extrn	 ARR_W_MEMLIN:tbyte

	 extrn	 TSTSIZEB:dword
	 extrn	 TSTSIZEW:dword
	 extrn	 TSTSIZED:dword

	 extrn	 TIMECNT:word
	 extrn	 @MEMITEM_LEN:abs

	 extrn	 @HLPIND_MEM:abs
	 extrn	 @HLPIND_NMI:abs

	 extrn	 HELP_MEM_ADDR:byte
	 extrn	 HELP_MEM_EXP:byte
	 extrn	 HELP_MEM_ACT:byte
	 extrn	 HELP_NMI_ADDR:byte

	 extrn	 PCALIB_USF:word
	 extrn	 PCALIB_UTF:word
	 extrn	 PCALIB_LIN:word
	 extrn	 PCALIB_UIN:word
	 extrn	 PCALIB_LID:word
	 extrn	 PCALIB_UID:word

	 extrn	 NMEMVAL:dword

	 extrn	 ARR_W_ITEM1:word

	 extrn	 PATXT2:word
	 extrn	 PBTXT2:word

	 extrn	 MSG_QUICKA:byte
	 extrn	 MSG_QUICKB:byte
	 extrn	 MSG_FULLA:byte
	 extrn	 MSG_FULLB:byte
	 extrn	 MSG_BLKCLR:byte
	 extrn	 MSG_HALTSCR:byte
	 extrn	 MSG_PROGSCR:byte
	 extrn	 MSG_SCROLL:byte
	 extrn	 MSG_PBAR:byte
	 extrn	 MSG_ASK:byte
	 extrn	 MSG_ETA_HR:byte
	 extrn	 MSG_STATSCR:byte
	 extrn	 MSG_ASKSCR1:byte
	 extrn	 MSG_ASKSCR2:byte
	 extrn	 MSG_DONE:byte
	 extrn	 MSG_DONE_LEN:abs
	 extrn	 MSG_INTR:byte
	 extrn	 MSG_INTR_LEN:abs

	 extrn	 CMPTAB:word
	 extrn	 CNTTAB:word

	 extrn	 W_ASK:tbyte
	 extrn	 W_STATSCR:tbyte
	 extrn	 W_HALT:tbyte
	 extrn	 W_SCROLL:tbyte
	 extrn	 W_PROG:tbyte
	 extrn	 W_PBAR:tbyte
	 extrn	 W_PTST:tbyte
	 extrn	 W_ETA1:tbyte
	 extrn	 W_ETA2:tbyte
	 extrn	 W_ELAP1:tbyte
	 extrn	 W_ELAP2:tbyte
	 extrn	 W_STATL:tbyte
	 extrn	 W_ASKSCR1:tbyte
	 extrn	 W_ASKSCR2:tbyte
	 extrn	 W_STATH1:tbyte
	 extrn	 W_STATH2:tbyte
	 extrn	 W_STATH3:tbyte

	 extrn	 ARR_W_ITEM2:word

	 extrn	 PMSG_PTST:word
	 extrn	 MSG_PTSTINI:byte
	 extrn	 MSG_PTSTALL:byte
	 extrn	 MSG_PTSTCMP:byte
	 extrn	 MSG_PTSTINT:byte

	 extrn	 ZMSG_ELAP:byte
	 extrn	 ZMSG_ELAP1:byte
	 extrn	 ZMSG_ELAP_HR:byte
	 extrn	 ZMSG_ELAP_HR_LEN:abs
	 extrn	 ZMSG_ELAP_MIN_LEN:abs
	 extrn	 ZMSG_ELAP_SEC_LEN:abs
	 extrn	 ZMSG_ELAP_DONE:byte

	 extrn	 ZMSG_BLK:byte
	 extrn	 ZMSG_BLK1:byte
	 extrn	 ZMSG_BLK3:byte
	 extrn	 ZMSG_BLK4:byte
	 extrn	 ZMSG_BLK5:byte

	 extrn	 @STATLIN_SROW:abs
	 extrn	 @STATLIN_NROW:abs
	 extrn	 @STATLIN_END:abs

	 extrn	 LOGA:byte
	 extrn	 LOGB:byte
	 extrn	 LOGDATE:byte
	 extrn	 LOGC:byte
	 extrn	 LOGTIME:byte
	 extrn	 LOGD:byte
	 extrn	 LOGE:byte
	 extrn	 LOGF:byte
	 extrn	 LOGF_K1:byte
	 extrn	 LOGF_K2:byte
	 extrn	 LOGF_H1:byte
	 extrn	 LOGF_H2:byte
	 extrn	 LOGF_K3:byte
	 extrn	 LOGG:byte

	 extrn	 LOG_MEMERR:byte
	 extrn	 LOG_MEMERR1:byte
	 extrn	 LOG_NMIERR:byte
	 extrn	 LOG_NMIERR1:byte
	 extrn	 LOG_NOERR:byte
	 extrn	 LOG_HALT:byte

	 extrn	 MSG_BYTERR:byte
	 extrn	 MSG_WORDERR:byte
	 extrn	 MSG_DWORDERR:byte
	 extrn	 MSG_NMIERROR:byte
	 extrn	 MSG_ADDR:byte

	 extrn	 MSG_EXP:byte
	 extrn	 MSG_EXP1:byte
	 extrn	 MSG_EXP2:byte
	 extrn	 MSG_EXP3:byte

	 extrn	 QMTLOGPATH:byte
	 extrn	 SAV_ASKCMDOPT:byte

	 extrn	 QMTDIR:byte
	 extrn	 QMT_STEM:word

	 extrn	 HELP_STATE:word
	 extrn	 @HELP_NONE:abs
	 extrn	 @HELP_TOPICS:abs
	 extrn	 @HELP_SCREEN:abs

	extrn	MSG_ASK_CONT:byte

	 public  TOTOPERS,TMPOPERS,NUMOPERS,MAXTIMER,ETATIMER,DECTIMER,INITIMER
TOTOPERS dq	 ?		; Total # operations
TMPOPERS dq	 ?		; Scratch area
NUMOPERS dq	 ?		; The # operations so far <= TOTOPERS
;;;;;;;;	 (100*60*60*1193180)/(64*1024) ; Maximum time we can display in ticks (99:59:59)
MAXTIMER dq	 6554333	; Maximum time we can display in ticks (99:59:59)
ETATIMER dq	 ?		; Estimated time to complete in ticks
DECTIMER dq	 ?		; Decrement to apply to ETATIMER while between
				; calls to DISP_OPERS
INITIMER dq	 ?		; Save area for elapsed time calculation

	 public  CON60,CON_CLOCK
CON60	 dd	 60		; # seconds in a minute & # minutes in a hour
CON_CLOCK dd	 1193180	; Clock frequency * 64K

	 public  ZAPOFF
ZAPOFF	 dw	 0		; Offset of zapped repeat prefix

	 public  PROGPCT
PROGPCT  dw	 0		; Progress percentage

	public	CONTCNT
CONTCNT dw	?		; Continuous iteration count

	 public  LAST_PTST
LAST_PTST dw	 DGROUP:MSG_PTSTINI ; Ptr to last completed message for basic screen

	 public  MEMERRCNT,NMIERRCNT
MEMERRCNT dw	 0		; Count of memory errors
NMIERRCNT dw	 0		; ...	   NMI ...

	 public  MEMWRKIND
MEMWRKIND dw	 -1		; Working memory line index (-1=none)

	 public  ASKBLK
ASKBLK	 dw	 @ITEM_ASKBAS	; Ask block (see @ITEM_xxx equates for values)

; Matching structures in the same order as the indices to ASKBLK

	 public  BLK_STRS
BLK_STRS BLK_STR <0, ?, 		     -1,	   -1, \
			     -1,	  -1, DGROUP:ASKTAB,   \
		  DGROUP:ARR_W_MEMLIN,DGROUP:PAMEM, DGROUP:PAMEM,  ?, ?>
	 BLK_STR <0, 2, 	  DGROUP:ASKBAS,DGROUP:ASKBAS, \
		  DGROUP:ASKBAS,DGROUP:ASKBAS,DGROUP:ASKTAB,   \
		  DGROUP:ARR_W_ITEM1, DGROUP:PATXT1,DGROUP:PBTXT1, ?, ?>
	 BLK_STR <0, @ASKITEM_LEN,DGROUP:ASKUP,DGROUP:ASKDN,   \
		  DGROUP:ASKLFT,DGROUP:ASKRHT,DGROUP:ASKTAB,   \
		  DGROUP:ARR_W_ITEM2, DGROUP:PATXT2,DGROUP:PBTXT2, ?, ?>
	 BLK_STR <0, 3, 	  DGROUP:ASKCMDUP,DGROUP:ASKCMDDN, \
		  DGROUP:ASKCMDUP,DGROUP:ASKCMDDN,DGROUP:ASKTAB,   \
		  DGROUP:ARR_W_ITEM3, DGROUP:PATXT3,DGROUP:PBTXT3, ?, ?>

	 public  MEMIND,ACMDIND,BASIND
MEMIND	 equ	 BLK_STRS[@ITEM_MEMADV * (type BLK_STR)].BLK_IND
BASIND	 equ	 BLK_STRS[@ITEM_ASKBAS * (type BLK_STR)].BLK_IND
ADVIND	 equ	 BLK_STRS[@ITEM_ASKADV * (type BLK_STR)].BLK_IND
ACMDIND  equ	 BLK_STRS[@ITEM_ASKCMD * (type BLK_STR)].BLK_IND

	 public  ITEM_LEN,MEMITEM_LEN
ITEM_LEN equ	 BLK_STRS[@ITEM_ASKADV * (type BLK_STR)].BLK_LEN ; # items for ASK
MEMITEM_LEN equ  BLK_STRS[@ITEM_MEMADV * (type BLK_STR)].BLK_LEN ; ...	       MEM (filled in later)

; The following table is used to translate states when
; pressing TAB or Shf-TAB

	 public  ASKTAB
ASKTAB	 db	 @ITEM_ASKADV,@ITEM_ASKBAS,@ITEM_MEMADV,@ITEM_ASKCMD

	 public  PATXT1
	 align	 2
PATXT1	 dw	 DGROUP:MSG_QUICKA
	 dw	 DGROUP:MSG_FULLA

	 public  PBTXT1
PBTXT1	 dw	 DGROUP:MSG_QUICKB
	 dw	 DGROUP:MSG_FULLB

	 public  PATXT3
PATXT3	 dw	 DGROUP:MSG_YESA
	 dw	 DGROUP:MSG_NOA
	 dw	 DGROUP:MSG_PPA

	 public  PBTXT3
PBTXT3	 dw	 DGROUP:MSG_YESB
	 dw	 DGROUP:MSG_NOB
	 dw	 DGROUP:MSG_PPB

	 public  ITEMOPERS
ITEMOPERS dw	 DGROUP:PCALIB_USF	; 0 = (Unlinked) Stuck-At
	 dw	 DGROUP:PCALIB_UTF	; 1 = (Unlinked) Transition
	 dw	 DGROUP:PCALIB_LIN	; 2 = Linked Inversion Coupling
	 dw	 DGROUP:PCALIB_UIN	; 3 = Unlinked Inversion Coupling
	 dw	 DGROUP:PCALIB_LID	; 4 = Linked Idempotent Coupling
	 dw	 DGROUP:PCALIB_UID	; 5 = Unlinked Idempotent Coupling

	 public  ITEMPATCNT
ITEMPATCNT dw	 0			; 0 = (Unlinked) Stuck-At
	 dw	 0			; 1 = (Unlinked) Transition
	 dw	 1			; 2 = Linked Inversion Coupling
	 dw	 1			; 3 = Unlinked Inversion Coupling
	 dw	 1			; 4 = Linked Idempotent Coupling
	 dw	 1			; 5 = Unlinked Idempotent Coupling

	 public  RCNT,BPU
RCNT	 dw	 ?		; Remaining count (scratch)
BPU	 dd	 ?		; Bytes per unit (2 for 16-bit, 4 for 32-bit)

	 public  REG0UP,REG1UP,REG0DN,REG1DN,PATCNT,PATOFF
REG0UP	 dd	 ?		; Register value for Read/Write 0s up
REG1UP	 dd	 ?		; ...				1s ...
REG0DN	 dd	 ?		; ...				0s down
REG1DN	 dd	 ?		; ...				1s ...
PATCNT	 dw	 ?		; Pattern count
PATOFF	 dw	 0		; Pattern offset (0=none)

	 public  ASKITEM,@ASKITEM_LEN
ASKITEM  dw	 PGROUP:ASK_UNLSAF	; 0 = (Unlinked) Stuck-At
	 dw	 PGROUP:ASK_UNLTRN	; 1 = (Unlinked) Transition
	 dw	 PGROUP:ASK_LNKINV	; 2 = Linked Inversion Coupling
	 dw	 PGROUP:ASK_UNLINV	; 3 = Unlinked Inversion Coupling
	 dw	 PGROUP:ASK_LNKIDM	; 4 = Linked Idempotent Coupling
	 dw	 PGROUP:ASK_UNLIDM	; 5 = Unlinked Idempotent Coupling
@ASKITEM_LEN equ  ($-ASKITEM)/(type ASKITEM)

	 public  ITEMCNT
ITEMCNT  dw	 @ASKITEM_LEN dup (0) ; Execution counters

	 public  CNT_FLAG
	 include MEM_CNT.INC
CNT_FLAG dw	 0		; Count flags

	 public  ASKLFT,ASKRHT,ASKUP,ASKDN,ASKBAS,ASKCMDUP,ASKCMDDN
;		 0  1  2  3  4	5  6	 Current state
ASKLFT	 db	 6, 0, 1, 2, 3, 4, 5	; State transition for left movement
ASKRHT	 db	 1, 2, 3, 4, 5, 6, 0	; ...		       right ...
ASKUP	 db	 6, 0, 1, 2, 3, 4, 5	; ...		       up    ...
ASKDN	 db	 1, 2, 3, 4, 5, 6, 0	; ...		       down  ...
ASKBAS	 db	 1, 0			; ...		       basic mode
ASKCMDUP db	 2, 0, 1		; ...		       ASK command up
ASKCMDDN db	 1, 2, 0		; ...		       ...	   down

	 public  ASKCMDBTN
ASKCMDBTN db	 @NATL_YESCHAR,@NATL_NOCHAR,@NATL_POSTPONE ; Return values

ifdef @RAMEXAM

	 public  QMTLOG
QMTLOG	 db	 PUNAME,'.LOG',0 ; Default log file basename

endif ; @RAMEXAM

LERRFMT_STR struc

LERRFMT_PTXT dw  ?		; Offset in DGROUP of type identifier text
LERRFMT_OFF dw	 ?		; Offset to subtract from MSG_EXP?
LERRFMT_PFN dw	 ?		; Near pointer to DEC2BYTE, DEC2WORD, DEC2DWORD

LERRFMT_STR ends

	 public  PLERR
	 align	 word
PLERR	 LERRFMT_STR <DGROUP:MSG_BYTERR,0,PGROUP:BIN2BYTE> ; Byte error
	 LERRFMT_STR <DGROUP:MSG_WORDERR,2,PGROUP:BIN2WORD> ; Word error
	 LERRFMT_STR <DGROUP:MSG_DWORDERR,6,PGROUP:BIN2DWORD> ; Dword error
	 LERRFMT_STR <DGROUP:MSG_NMIERROR,?,?> ; Parity error

; These values correspond to PLERR entries
@ERRLOG_NONE	 equ	 -1	; Entry not in use
@ERRLOG_BYTE	 equ	 0	; Byte mismatch error
@ERRLOG_WORD	 equ	 1	; Word mismatch error
@ERRLOG_DWORD	 equ	 2	; Dword mismatch error
@ERRLOG_NMI	 equ	 3	; Parity error

@ERRLOGMAX	 equ	 10	; Maximum errors to save

ERRDATA_STR struc

ERRDATA_TYP dw	 @ERRLOG_NONE	; @ERRLOG_BYTE, etc.
ERRDATA_ACT dd	 ?		; Actual data (ignored for NMI)
ERRDATA_EXP dd	 ?		; Expected    (...)
ERRDATA_ADDR dd  ?		; Physical address

ERRDATA_STR ends

	 public  ERRDATACNT,ERRDATA
ERRDATACNT dw	 0		; Number of entries in ERRDATA
ERRDATA ERRDATA_STR @ERRLOGMAX dup (<>)

DATA	 ends			; End DATA segment


KEYSEG	 segment use16 word 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

	 public  ASKVAL
ASKVAL	 label	 word		; First byte in the table

KEYSEG	 ends			; End KEYSEG segment


ACTSEG	 segment use16 word 'data' ; Start ACTSEG segment
	 assume  ds:DGROUP

	 public  ASKACT
ASKACT	 label	 word		; First action in the table

ACTSEG	 ends			; End ACTSEG segment


; Define active keys and their corresponding actions

	 KEYACT  F1	  , ASK_HELP
	 KEYACT  F5	  , ASK_COLOR
	 KEYACT  ESC	  , ASK_QUIT
	 KEYACT  F10	  , ASK_QUIT
	 KEYACT  CR	  , ASK_CR
	 KEYACT  PADENTER , ASK_CR
	 KEYACT  CTL_CR   , ASK_CR_ONCE
	 KEYACT  UP	  , ASK_UP
	 KEYACT  XUP	  , ASK_UP
	 KEYACT  DN	  , ASK_DN
	 KEYACT  XDN	  , ASK_DN
	 KEYACT  LEFT	  , ASK_LEFT
	 KEYACT  XLEFT	  , ASK_LEFT
	 KEYACT  RIGHT	  , ASK_RIGHT
	 KEYACT  XRIGHT   , ASK_RIGHT
	 KEYACT  SHF_TAB  , ASK_STAB
	 KEYACT  TAB	  , ASK_TAB
	 KEYACT  C	  , ASK_C
	 KEYACT  SHF_C	  , ASK_C
	 KEYACT  0	  , ASK_0
	 KEYACT  SHF_INS  , ASK_0
	 KEYACT  1	  , ASK_1
	 KEYACT  SHF_END  , ASK_1
	 KEYACT  2	  , ASK_2
	 KEYACT  SHF_DN   , ASK_2
	 KEYACT  3	  , ASK_3
	 KEYACT  SHF_PGDN , ASK_3
	 KEYACT  4	  , ASK_4
	 KEYACT  SHF_LEFT , ASK_4
	 KEYACT  5	  , ASK_5
	 KEYACT  SHF_PAD5 , ASK_5
	 KEYACT  6	  , ASK_6
	 KEYACT  SHF_RIGHT, ASK_6
	 KEYACT  7	  , ASK_7
	 KEYACT  SHF_HOME , ASK_7
	 KEYACT  8	  , ASK_8
	 KEYACT  SHF_UP   , ASK_8
	 KEYACT  9	  , ASK_9
	 KEYACT  SHF_PGUP , ASK_9
	 KEYACT  DEL	  , ASK_DEL
	 KEYACT  XDEL	  , ASK_DEL
	 KEYACT  BS	  , ASK_DEL

	 public  @KEY_HALT
@KEY_HALT equ	 @KEY_ESC+0

@KEY_SWITCH_MODE equ @KEY_ALT_TAB
@KEY_SWITCH_MODE2 equ @KEY_F9

	 KEYACT  SWITCH_MODE , ASK_MODE ; This does not seem to be used
	 KEYACT  F9	  , ASK_MODE
	 KEYACT  H	  , ASK_BASE16
	 KEYACT  SHF_H	  , ASK_BASE16
	 KEYACT  CTL_H	  , ASK_BASE16
	 KEYACT  D	  , ASK_BASE10
	 KEYACT  SHF_D	  , ASK_BASE10
	 KEYACT  CTL_D	  , ASK_BASE10


KEYSEG	 segment use16 word 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

NASKVAL  equ	 ($-ASKVAL)/(type ASKVAL)

KEYSEG	 ends			; End KEYSEG segment

; ---- Key action table for dialog box ----

KEYSEG	 segment use16 word 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

	 public  ASKCVAL
ASKCVAL  label	 word		; First byte in the table

KEYSEG	 ends			; End KEYSEG segment


ACTSEG	 segment use16 word 'data' ; Start ACTSEG segment
	 assume  ds:DGROUP

	 public  ASKCACT
ASKCACT  label	 word		; First action in the table

ACTSEG	 ends			; End ACTSEG segment

	 KEYACT  F1	  , ASKC_HELP
	 KEYACT  ESC	  , ASKC_ESC
	 KEYACT  UP	  , ASKC_UP
	 KEYACT  XUP	  , ASKC_UP
	 KEYACT  DN	  , ASKC_DN
	 KEYACT  XDN	  , ASKC_DN
	 KEYACT  LEFT	  , ASKC_LEFT
	 KEYACT  XLEFT	  , ASKC_LEFT
	 KEYACT  RIGHT	  , ASKC_RIGHT
	 KEYACT  XRIGHT   , ASKC_RIGHT
	 KEYACT  SHF_TAB  , ASKC_STAB
	 KEYACT  TAB	  , ASKC_TAB

KEYSEG	 segment use16 word 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

NASKCVAL  equ	 ($-ASKCVAL)/(type ASKCVAL)

KEYSEG	 ends			; End KEYSEG segment


NDATA	 segment use16 dword public 'data' ; Start NDATA segment
	 assume  ds:DGROUP

	 extrn	 MSG_YESA:byte
	 extrn	 MSG_YESB:byte
	 extrn	 MSG_NOA:byte
	 extrn	 MSG_NOB:byte
	 extrn	 MSG_PPA:byte
	 extrn	 MSG_PPB:byte

	 extrn	 ARR_W_ITEM3:word

	 extrn	 MSG_ACHLP:byte
	 extrn	 MSG_ASKCMD:byte
	 extrn	 MSG_ASKCMDREM:byte
	 extrn	 FMT_ASKCMDREM:byte

	 extrn	 W_ASKCMD:tbyte
	 extrn	 W_ASKCMDBACK:tbyte
	 extrn	 W_ASKCMDREM:tbyte
	 extrn	 W_ACHLP:tbyte

	 public  ASK_DEFAULT,ASK_TIMEOUT
ASK_DEFAULT db	 @NATL_YESCHAR	; 'Yes' is the answer, "Run QMT" is the question
ASK_TIMEOUT dw	 15		; Default timeout in seconds for ASK box

	 public  EPOCHTARG,SECTARG,LASTDIFF
EPOCHTARG dd	 ?		; Target epoch for timeout
SECTARG  dd	 ?		; Target second for timeout
LASTDIFF dd	 ?		; Last count of seconds remaining displayed

NDATA	 ends			; End NDATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 SEL_DATA:word

	 extrn	 DISP_MEMVAL:near
	 extrn	 DISP_STATLZ:near
	 extrn	 DISP_QUIT:near
	 extrn	 DISP_HALT:near
	 extrn	 DISP_SCRN:near
	 extrn	 DISP_BASE:near
	 extrn	 DISP_HELP:near
	 extrn	 DISP_HLPERR:near

	 extrn	 WPUT_C:near
	 extrn	 WPUT_CA:near
	 extrn	 WPUT_SA:near
	 extrn	 WPUT_SCA:near
	 extrn	 WPUT_CSA:near
	 extrn	 WPUT_SHD1:near
	 extrn	 WPUT_SHD2:near

	 extrn	 TEST_UNLSAF:near
	 extrn	 TEST_UNLTRN:near
	 extrn	 TEST_UNLINV:near
	 extrn	 TEST_UNLIDM:near
	 extrn	 TEST_LNKINV:near
	 extrn	 TEST_LNKIDM:near

	 extrn	 GETKEY:near
	 extrn	 CHKNDKEY:near
	 extrn	 PURGE_KBUFF:near

	 extrn	 BIN2DEC:near
	 extrn	 BIND2DEC:near
	 extrn	 BIN2BYTE:near
	 extrn	 BIN2WORD:near
	 extrn	 BIN2DWORD:near
	 extrn	 BIN2DVAL:near

	 extrn	 ENABLE_NMI:near

	 extrn	 SET_COLOR:near
	 extrn	 UPPERCASE:near

	 extrn	 DATE2EPOCH:near
	 extrn	 FMT_DMY:near
	 extrn	 FMT_HM:near

	 extrn	 REST_SCR:near
	 extrn	 VIDB_SEGOFF:near
	 extrn	 VIDB_LINEAR:near

	 NPPROC  CHECK_RHELP -- Check for Help Display
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we're currently displaying help topics, redisplay the screen now.
We'll pass @KEY_SPACE to DISP_HELP as a no-op key.

|

	 REGSAVE <ax>		; Save

	 cmp	 HELP_STATE,@HELP_TOPICS ; Are we displaying help topics?
	 jne	 short @F	; Jump if not

	 push	 GL3_FLAG	; Save flags

	 mov	 ax,@KEY_SPACE	; A nop key for DISP_HELP
	 or	 GL3_FLAG,@GL3_RUNHELP ; Pretend we're coming from Int 8
	 call	 DISP_HELP	; Update help topic display

	 pop	 GL3_FLAG	; Restore
@@:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_RHELP endp		; End CHECK_RHELP procedure
	 NPPROC  CHECK_FAULT -- Check for Faults
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Check for memory faults.

This routine runs in Protected Mode.

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,ecx,edx,di,es,gs> ; Save registers

ifdef @BETA
	 test	 DBG_FLAG,@DBG_FLT ; Debug start of faults?
	 jz	 short @F	; Not this time

	 int	 01h		; Call in the SWAT team
@@:
endif				; IFDEF @BETA
	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

; If there's a memory overflow, allow Tab and S-Tab to switch between
; the ASK advanced and memory screens.

	 test	 GL2_FLAG,@GL2_MEMOVF ; Is there another screen?
	 jnz	 short @F	; Jump if so

	 mov	 ASKTAB[@ITEM_ASKADV],@ITEM_ASKADV ; Disallow the switch
@@:

; ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
; ³ Copyright	   ³	  Ask	    ³
; ³ All rights ... ³	 Item	    ³
; ³ Key 	   ³	 Area	    ³
; ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
; ³ Memory ranges  ³	 Status     ³
; ³		   ³		    ³
; ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	 test	 CNT_FLAG,@CNT_AUTO ; Are we running in AUTO mode?
	 jz	 short ASK_NEXT0 ; Jump if not

; Set local timer as we're AUTO

	 call	 GET_MEMTIMER	; Return with EDX:EAX=local timer tick count
	 mov	 INITIMER.EDQLO,eax ; Save for later use
	 mov	 INITIMER.EDQHI,edx ; ...

; Calculate total # operations

	 call	 CALC_NOPERS	; Calculate the total number of operations

	 or	 GL2_FLAG,@GL2_ACTIV ; Mark as active (for DISP_PROGSCR)
	 mov	 ADVIND,-1	; Set so GET_NEXTIND starts at zero

	 test	 GL2_FLAG,@GL2_CONT ; Izit continuous?
	 jnz	 short @F	; Jump if so

	 mov	 LAST_PTST,-1	; Mark as to be computed
@@:
ASK_NEXT0:
	 call	 DISP_PROGSCR	; Display the progress screen
ASK_NEXT1:
;;;;;;;  and	 CNT_FLAG,not @CNT_HALT ; Clear halt flag
ASK_NEXT:
	 call	 DISP_ASKITEM	; Display the ask and item counts
	 call	 DISP_MEMVAL	; Display the memory values

	 mov	 MEMWRKIND,-1	; Mark as invalid

	 test	 CNT_FLAG,@CNT_AUTO ; Are we running in AUTO mode?
	 jnz	 near ptr ASK_AUTO ; Jump if so

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into BLK_STRS
	 mov	 al,BLK_STRS[bx].BLK_AASK ; Get active ask attribute
	 mov	 si,BLK_STRS[bx].BLK_PPATXT ; Get ptr to ptr to active text
	 call	 SET_BARATTR	; Set bar attribute

@@:
	 call	 GETKEY 	; Request a keystroke, return in AX

	 cmp	 HELP_STATE,@HELP_NONE ; Are we still showing help?
	 je	 short @F	; Jump if so

	 or	 GL3_FLAG,@GL3_RUNHELP ; Pretend we're calling from Int 8
	 call	 DISP_HELP	; Process AX
	 and	 GL3_FLAG,not @GL3_RUNHELP ; Restore previous state
	 jmp	 short @B	; Go around again

@@:
	 lea	 di,ASKVAL	; ES:DI ==> valid keys
	 mov	 cx,NASKVAL	; # valid keys
   repne scas	 ASKVAL[di]	; Search for it
	 jne	 short ASK_NEXT ; Ignore it if not found

	 sub	 di,(type ASKVAL) + offset es:ASKVAL ; Convert to origin-0

	 jmp	 ASKACT[di]	; Take appropriate action

ASK_PURGE:
	 call	 PURGE_KBUFF	; Purge the keyboard buffer

	 jmp	 short ASK_NEXT1 ; Join common code


ASK_UP:
	 and	 CNT_FLAG,not @CNT_NUM ; Last char no longer numeric

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into BLK_STRS
	 mov	 al,BLK_STRS[bx].BLK_BASK ; Get background ask attribute
	 mov	 si,BLK_STRS[bx].BLK_PPBTXT ; Get ptr to ptr to background text
	 call	 SET_BARATTR	; Set bar attribute

	 cmp	 ASKBLK,@ITEM_MEMADV ; Izit the memory screen?
	 je	 short ASK_UP1 ; Jump if so

;;;;;;;; imul	 bx,ASKBLK,type BLK_STR ; Get index into current struc
	 mov	 si,BLK_STRS[bx].BLK_PCUP ; Get offset of translate table
	 add	 si,BLK_STRS[bx].BLK_IND ; Plus current index
	 movzx	 ax,DGROUP:[si].LO ; Get translated value
	 mov	 BLK_STRS[bx].BLK_IND,ax ; Save as new index

	 jmp	 ASK_NEXT	; Go around again

ASK_UP1:
	 sub	 MEMIND,1	; Skip to previous row
	 jnc	 short @F	; Jump if not below the top

	 mov	 MEMIND,0	; Back to the top
@@:
	 jmp	 ASK_NEXT	; Go around again


ASK_DN:
	 and	 CNT_FLAG,not @CNT_NUM ; Last char no longer numeric

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into BLK_STRS
	 mov	 al,BLK_STRS[bx].BLK_BASK ; Get background ask attribute
	 mov	 si,BLK_STRS[bx].BLK_PPBTXT ; Get ptr to ptr to background text
	 call	 SET_BARATTR	; Set bar attribute

	 cmp	 ASKBLK,@ITEM_MEMADV ; Izit the memory screen?
	 je	 short ASK_DN1 ; Jump if so

;;;;;;;; imul	 bx,ASKBLK,type BLK_STR ; Get index into current struc
	 mov	 si,BLK_STRS[bx].BLK_PCDN ; Get offset of translate table
	 add	 si,BLK_STRS[bx].BLK_IND ; Plus current index
	 movzx	 ax,DGROUP:[si].LO ; Get translated value
	 mov	 BLK_STRS[bx].BLK_IND,ax ; Save as new index

	 jmp	 ASK_NEXT	; Go around again

ASK_DN1:
	 inc	 MEMIND 	; SkKip to next row

	 mov	 ax,TIMECNT	; Get total # rows
	 sub	 ax,@MEMITEM_LEN ; Less the maximum we can display
	 jae	 short @F	; Jump if it's within range

	 xor	 ax,ax		; Use maximum index
@@:

; AX has the maximum valid index

	 cmp	 ax,MEMIND	; Izit valid?
	 jae	 short @F	; Jump if so

	 mov	 MEMIND,ax	; Save as maximum index
@@:
	 jmp	 ASK_NEXT	; Go around again


ASK_LEFT:
	 and	 CNT_FLAG,not @CNT_NUM ; Last char no longer numeric

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into BLK_STRS
	 mov	 al,BLK_STRS[bx].BLK_BASK ; Get background ask attribute
	 mov	 si,BLK_STRS[bx].BLK_PPBTXT ; Get ptr to ptr to background text
	 call	 SET_BARATTR	; Set bar attribute

	 cmp	 ASKBLK,@ITEM_MEMADV ; Izit the memory screen?
	 je	 short @F      ; Jump if so

;;;;;;;; imul	 bx,ASKBLK,type BLK_STR ; Get index into current struc
	 mov	 si,BLK_STRS[bx].BLK_PCLF ; Get offset of translate table
	 add	 si,BLK_STRS[bx].BLK_IND ; Plus current index
	 movzx	 ax,DGROUP:[si].LO ; Get translated value
	 mov	 BLK_STRS[bx].BLK_IND,ax ; Save as new index
@@:
	 jmp	 ASK_NEXT	; Go around again


ASK_RIGHT:
	 and	 CNT_FLAG,not @CNT_NUM ; Last char no longer numeric

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into BLK_STRS
	 mov	 al,BLK_STRS[bx].BLK_BASK ; Get background ask attribute
	 mov	 si,BLK_STRS[bx].BLK_PPBTXT ; Get ptr to ptr to background text
	 call	 SET_BARATTR	; Set bar attribute

	 cmp	 ASKBLK,@ITEM_MEMADV ; Izit the memory screen?
	 je	 short @F      ; Jump if so

;;;;;;;; imul	 bx,ASKBLK,type BLK_STR ; Get index into current struc
	 mov	 si,BLK_STRS[bx].BLK_PCRT ; Get offset of translate table
	 add	 si,BLK_STRS[bx].BLK_IND ; Plus current index
	 movzx	 ax,DGROUP:[si].LO ; Get translated value
	 mov	 BLK_STRS[bx].BLK_IND,ax ; Save as new index
@@:
	 jmp	 ASK_NEXT	; Go around again


ASK_TAB:
ASK_STAB:

; If we're in basic mode, treat this as a right arrow (or any other arrow
; for that matter).

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short ASK_RIGHT ; Jump if not

; Shift to the other screen if we're in advanced mode;
; otherwise, ignore the key

	 and	 CNT_FLAG,not @CNT_NUM ; Last char no longer numeric

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into current struc
	 mov	 si,BLK_STRS[bx].BLK_PCTB ; Get offset of translate table
	 add	 si,ASKBLK	; Plus current mode
	 movzx	 ax,DGROUP:[si].LO ; Get translated value
	 mov	 ASKBLK,ax	; Save as new mode

	 jmp	 ASK_NEXT	; Go around again


ASK_C:
	 and	 CNT_FLAG,not @CNT_NUM ; Last char no longer numeric

	 cmp	 ASKBLK,@ITEM_ASKADV ; Izit in ask/adv mode?
	 jne	 near ptr ASK_NEXT ; Jump if not (just ignore it)

	 cmp	 ADVIND,@ASK_START ; Izit in the starting block?
	 je	 near ptr ASK_NEXT ; Jump if so (just ignore it)
ASK_CONT:
	 mov	 bx,ADVIND	; Get current index
	 shl	 bx,1		; Times two to index table of words
	 mov	 ITEMCNT[bx],@ICNT_CONT ; Mark as continuous

	 or	 CNT_FLAG,@CNT_CHG ; Mark as having changed
	 and	 CNT_FLAG,not @CNT_NUM ; Last char no longer numeric

	 jmp	 ASK_NEXT	; Go around again


ASK_0:
ASK_1:
ASK_2:
ASK_3:
ASK_4:
ASK_5:
ASK_6:
ASK_7:
ASK_8:
ASK_9:
	 cmp	 ASKBLK,@ITEM_ASKADV ; Izit in ask/adv mode?
	 jne	 near ptr ASK_NEXT ; Jump if not (just ignore it)

	 cmp	 ADVIND,@ASK_START ; Izit in the starting block?
	 je	 near ptr ASK_NEXT ; Jump if so (just ignore it)

	 movzx	 cx,al		; Copy the scan code
	 sub	 cl,'0'         ; Convert to origin-0

	 mov	 bx,ADVIND	; Get current index
	 shl	 bx,1		; Times two to index table of words
	 mov	 ax,ITEMCNT[bx] ; Get the last count

	 test	 CNT_FLAG,@CNT_NUM ; Was the last character numeric?
	 jnz	 short @F	; Jump if so

	 xor	 ax,ax		; Initialize accumulator to zero
@@:
	 imul	 ax,10		; Shift the last digit over one
	 jc	 short ASK_CONT ; Jump if too large (treat as continuous)

	 add	 ax,cx		; Add to get new value
	 jc	 short ASK_CONT ; Jump if too large (treat as continuous)

	 cmp	 ax,@CNT_MAX	; Izit larger than our largest value?
	 ja	 short ASK_CONT ; Jump if too large (treat as continuous)

	 mov	 ITEMCNT[bx],ax ; Save the new count

	 or	 CNT_FLAG,@CNT_CHG or @CNT_NUM ; Mark as having changed
				; and last char is numeric
	 jmp	 ASK_NEXT	; Go around again


; Delete the last numeric character

ASK_DEL:
	 cmp	 ASKBLK,@ITEM_ASKADV ; Izit in ask/adv mode?
	 jne	 near ptr ASK_NEXT ; Jump if not (just ignore it)

	 cmp	 ADVIND,@ASK_START ; Izit in the starting block?
	 je	 near ptr ASK_NEXT ; Jump if so (just ignore it)

	 mov	 bx,ADVIND	; Get current index
	 shl	 bx,1		; Times two to index table of words
	 mov	 ax,ITEMCNT[bx] ; Get the last count

	 cmp	 ax,@ICNT_CONT	; Izit continuous?
	 jne	 short @F	; Jump if not

	 xor	 ax,ax		; Use count of zero
@@:
	 xor	 dx,dx		; Zero to use as dword
	 mov	 cx,10		; Get divisor
	 div	 cx		; Delete the last digit

	 mov	 ITEMCNT[bx],ax ; Save the new count

	 or	 CNT_FLAG,@CNT_CHG or @CNT_NUM ; Mark as having changed
				; and last char is numeric
	 jmp	 ASK_NEXT	; Go around again


; Toggle between basic and advanced mode

ASK_MODE:
	 call	 SWITCH_MODE	; Switch to the other mode
	 call	 DISP_SCRN	; Display the new screen
	 call	 DISP_ACTIV	; Display active elements

	 jmp	 ASK_NEXT	; Go around again


; Set base number system in which to display addresses

ASK_BASE10:
	 and	 GL2_FLAG,not @GL2_HEX ; Set to decimal
	 or	 CNT_FLAG,@CNT_CHG ; Mark as having changed

	 call	 DISP_BASE	; Display the current number base

	 jmp	 ASK_NEXT	; Go around again


; Set base number system in which to display addresses

ASK_BASE16:
	 or	 GL2_FLAG,@GL2_HEX ; Set to hexadecimal
	 or	 CNT_FLAG,@CNT_CHG ; Mark as having changed

	 call	 DISP_BASE	; Display the current number base

	 jmp	 ASK_NEXT	; Go around again


; Display the help screen

ASK_HELP:
	 call	 DISP_HELP	; Display help
	 call	 DISP_SCRN	; Display the new screen
	 call	 DISP_ACTIV	; Display active elements

	 jmp	 ASK_NEXT	; Go around again


; Toggle between Color and B&W

ASK_COLOR:
	 call	 SWITCH_COLOR	; Toggle the color state

	 jmp	 ASK_NEXT	; Go around again


ASK_AGAIN:
	 call	 CHECK_KEYS	; See if any interesting keys were pressed
	 jne	 near ptr ASK_PURGE ; Jump if we're to halt (purge the buffer)

	 jmp	 short ASK_CR0	; Join common code

ASK_CR_ONCE:
	 cmp	 ASKBLK,@ITEM_MEMADV ; Izit memory screen?
	 je	 near ptr ASK_NEXT ; Jump if so (just ignore it)

	 cmp	 ADVIND,@ASK_START ; Izit in the starting block?
	 jne	 short ASK_CR1	; Jump if not (run once)
ASK_CR:
	 cmp	 ASKBLK,@ITEM_MEMADV ; Izit memory screen?
	 je	 near ptr ASK_NEXT ; Jump if so (just ignore it)

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced?
	 jz	 short ASK_CR1	; Jump if not

	 cmp	 ADVIND,@ASK_START ; Izit in the starting block?
	 jne	 near ptr ASK_DN ; Jump if not (treat as down arrow)

	 call	 GET_NEXTIND	; Get next ADVIND value
	 jc	 near ptr ASK_NEXT ; Jump if no more
ASK_CR1:

; Save current time for elapsed time calculation

	 call	 GET_MEMTIMER	; Return with EDX:EAX=local timer tick count
	 mov	 INITIMER.EDQLO,eax ; Save for later use
	 mov	 INITIMER.EDQHI,edx ; ...

	 call	 SET_ASKCOUNT	; Set ask counts
	 call	 CALC_NOPERS	; Calculate the total number of operations

; Display the progress screen and mark as active

	 or	 GL2_FLAG,@GL2_ACTIV ; Mark as active (for DISP_PROGSCR)

	 test	 GL2_FLAG,@GL2_CONT ; Izit continuous?
	 jnz	 short @F	; Jump if so

	 mov	 LAST_PTST,-1	; Mark as to be computed
@@:
	 call	 DISP_PROGSCR	; Display it
ASK_CR0:
	 or	 GL2_FLAG,@GL2_ACTIV ; Mark as active

	 test	 GL2_FLAG,@GL2_CONT ; Izit continuous?
	 jnz	 short @F	; Jump if so

	 mov	 LAST_PTST,-1	; Mark as to be computed
@@:
	 and	 CNT_FLAG,not (@CNT_NUM or @CNT_NMI or @CNT_HALT) ; Last char
				; no longer numeric, no NMI, and clear halt flag

	 call	 DISP_TEST	; Display the testing state
	 call	 DISP_ASKITEM	; Display the ask and item counts

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into BLK_STRS
	 mov	 al,BLK_STRS[bx].BLK_AASK ; Get active ask attribute
	 mov	 si,BLK_STRS[bx].BLK_PPATXT ; Get ptr to ptr to active text
	 call	 SET_BARATTR	; Set bar attribute

	 mov	 di,ADVIND	; Get current index
	 shl	 di,1		; Times two to index table of words

	 jmp	 ASKITEM[di]	; Take appropriate action


; Test for Unlinked Stuck-At Faults

ASK_UNLSAF:
	 call	 CLEAR_STATUS	; Clear the screen of previous status data
	 call	 DISP_HALT	; Display the how-to-halt line

	 call	 TEST_UNLSAF	; Test for Unlinked Stuck-at Faults
	 jc	 near ptr CHECK_FAULT_ERR ; Jump if something went wrong

	 push	 @ASK_UNLSAF	; Pass the index
	 call	 COUNTOUT	; Account for one fewer iteration

	 jmp	 ASK_COMPLETE	; Join common completion code


; Test for Unlinked Transition Faults

ASK_UNLTRN:
	 call	 CLEAR_STATUS	; Clear the screen of previous status data
	 call	 DISP_HALT	; Display the how-to-halt line

	 call	 TEST_UNLTRN	; Test for Unlinked Transition Faults
	 jc	 near ptr CHECK_FAULT_ERR ; Jump if something went wrong

	 push	 @ASK_UNLTRN	; Pass the index
	 call	 COUNTOUT	; Account for one fewer iteration

	 jmp	 ASK_COMPLETE	; Join common completion code


; Test for Unlinked Inversion Coupling Faults

ASK_UNLINV:
	 call	 CLEAR_STATUS	; Clear the screen of previous status data
	 call	 DISP_HALT	; Display the how-to-halt line

	 call	 TEST_UNLINV	; Test for Unlinked Inversion Coupling Faults
	 jc	 short CHECK_FAULT_ERR ; Jump if something went wrong

	 push	 @ASK_UNLINV	; Pass the index
	 call	 COUNTOUT	; Account for one fewer iteration

	 jmp	 short ASK_COMPLETE ; Join common completion code


; Test for Unlinked Idempotent Coupling Faults

ASK_UNLIDM:
	 call	 CLEAR_STATUS	; Clear the screen of previous status data
	 call	 DISP_HALT	; Display the how-to-halt line

	 call	 TEST_UNLIDM	; Test for Unlinked Idempotent Coupling Faults
	 jc	 short CHECK_FAULT_ERR ; Jump if something went wrong

	 push	 @ASK_UNLIDM	; Pass the index
	 call	 COUNTOUT	; Account for one fewer iteration

	 jmp	 short ASK_COMPLETE ; Join common completion code


; Test for Linked Inversion Coupling Faults

ASK_LNKINV:
	 call	 CLEAR_STATUS	; Clear the screen of previous status data
	 call	 DISP_HALT	; Display the how-to-halt line

	 call	 TEST_LNKINV	; Test for Linked Inversion Coupling Faults
	 jc	 short CHECK_FAULT_ERR ; Jump if something went wrong

	 push	 @ASK_LNKINV	; Pass the index
	 call	 COUNTOUT	; Account for one fewer iteration

	 jmp	 short ASK_COMPLETE ; Join common completion code


; Test for Linked Idempotent Coupling Faults

ASK_LNKIDM:
	 call	 CLEAR_STATUS	; Clear the screen of previous status data
	 call	 DISP_HALT	; Display the how-to-halt line

	 call	 TEST_LNKIDM	; Test for Linked Idempotent Coupling Faults
	 jc	 short CHECK_FAULT_ERR ; Jump if something went wrong

	 push	 @ASK_LNKIDM	; Pass the index
	 call	 COUNTOUT	; Account for one fewer iteration

	 jmp	 short ASK_COMPLETE ; Join common completion code


; Mark as in error

CHECK_FAULT_ERR:
	 and	 GL2_FLAG,not @GL2_ACTIV ; Mark as no longer active
	 and	 CNT_FLAG,not @CNT_AUTO ; Mark as no longer AUTO
	 call	 DISP_QUIT	; Display the how-to-quit line

	 mov	 cl,''         ; Use error marker
	 call	 SET_COMPLETE	; Mark as complete

	 jmp	 ASK_PURGE	; Go around again, purge the buffer


	 public  ASK_COMPLETE
ASK_COMPLETE:
	 and	 GL2_FLAG,not @GL2_ACTIV ; Mark as no longer active
	 call	 DISP_QUIT	; Display the how-to-quit line

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into BLK_STRS
	 mov	 al,BLK_STRS[bx].BLK_BASK ; Get background ask attribute
	 mov	 si,BLK_STRS[bx].BLK_PPBTXT ; Get ptr to ptr to background text
	 call	 SET_BARATTR	; Set bar attribute

; Mark as successful unless it was interrupted

	 test	 CNT_FLAG,@CNT_HALT ; Did we terminate on request?
	 jnz	 short @F	; Jump if so

	 mov	 cl,'û'         ; Use success marker
	 call	 SET_COMPLETE	; Mark as complete
@@:

; Calculate and format elapsed time

	 call	 FMT_ELAP	; Calculate and format elapsed time

	 push	 offset ds:ZMSG_ELAP ; Pass address of local buffer
	 call	 DISP_STATLZ	; Display on the status line with attributes

; If halt key was pressed, stop now

ASK_AUTO:
;;;;;;;  btr	 CNT_FLAG,$CNT_HALT ; Wuzit pressed?
;;;;;;;  jc	 near ptr ASK_PURGE ; Jump if so (purge the buffer)
	 test	 CNT_FLAG,@CNT_HALT ; Wuzit pressed?
	 jz	 near ptr ASK_AUTO2 ; If not, don't purge buffer

	 call	 PURGE_KBUFF	; Purge the keyboard buffer
	 jmp	 near ptr ASK_HALTED	; Continue on (possibly exit)

; See if there are any additional iterations

ASK_AUTO2:
	 call	 GET_NEXTIND	; Get next ADVIND value
	 jnc	 near ptr ASK_AGAIN ; Jump if there's more

ASK_HALTED:
	 btr	 CNT_FLAG,$CNT_AUTO ; Are we running in AUTO mode?
	 jnc	 near ptr ASK_NEXT ; Jump if not

	 btr	 CNT_FLAG,$CNT_NOEXIT ; Should we exit?
	 jc	 near ptr ASK_NEXT ; Jump if not

; Pause for a moment so the user can view the completion state

	 xor	 edx,edx	; Zero to use as dword
	 mov	 dx,seg BIOSDATA ; Get segment of BIOS data area
	 shl	 edx,4-0	; Convert from paras to bytes
	 assume  gs:BIOSDATA	; Tell the assembler about it

@TIMER_WAIT equ  18*2		; Wait for about two seconds

; Purge the keyboard buffer

	 call	 PURGE_KBUFF	; Purge the keyboard buffer

; Get the current timer high and low values

	 mov	 ecx,TIMER_LOW.EDD[edx] ; Get initial timer dword
CHECK_FAULT_WAIT:
	 call	 CHKNDKEY	; Is there a keystroke available?
				; Return with AX = keystroke, ZF significant
	 jnz	 short CHECK_FAULT_WAIT1 ; Jump if so

	 mov	 eax,TIMER_LOW.EDD[edx] ; Get current timer dword
	 sub	 eax,ecx	; Less initial value to handle wrap

	 cmp	 eax,@TIMER_WAIT ; Izit time?
	 jb	 short CHECK_FAULT_WAIT ; Jump if not

	 jmp	 short CHECK_FAULT_WAIT2 ; Join common code

CHECK_FAULT_WAIT1:
	 call	 GETKEY 	; Request a keystroke
CHECK_FAULT_WAIT2:
	 assume  gs:AGROUP	; Tell the assembler about it

	 or	 CNT_FLAG,@CNT_DISPEXIT ; Mark as displaying exit message
; If we're currently viewing help, make sure we exit.  Note that there's
; no active Int 08h handler, so we need a keyboard input loop.
	 or	 GL3_FLAG,@GL3_RUNHELP ; Mark as displaying help while testing
@@:
	 cmp	 HELP_STATE,@HELP_NONE ; Displaying help?
	 je	 short ASK_QUIT ; Jump if not

	 call	 GETKEY 	; Get keystroke in AX
	 call	 DISP_HELP	; Update help state and display
	 jmp	 short @B	; Go around again

ASK_QUIT:
	 clc			; Indicate all went well
CHECK_FAULT_EXIT:
	 REGREST <gs,es,di,edx,ecx,eax> ; Restore
	 assume  es:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_FAULT endp		; End CHECK_FAULT procedure
	 NPPROC  GET_NEXTIND -- Get Next ADVIND Value
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next ADVIND value with more to do.

On exit:

CF	 =	 0 if ADVIND has been set to the next value
	 =	 1 if there's no more to do

|

	 REGSAVE <bx,cx,si>	; Save registers

	 mov	 bx,ADVIND	; Get current advanced index
	 mov	 cx,@ASKITEM_LEN ; Get # ITEMCNT values
GET_NEXTIND1:
	 inc	 bx		; Skip to next item

	 cmp	 bx,@ASKITEM_LEN ; Check against maximum
	 jb	 short @F	; Jump if within range

	 xor	 bx,bx		; Wrap to beginning
	call	COUNT_CONT	; Count in one more continuous round (if appropriate)
@@:
	 mov	 si,bx		; Copy to index ITEMCNT
	 shl	 si,1		; Times two to index table of words

	 cmp	 ITEMCNT[si],1	; Is there more to do?
	 jae	 short GET_NEXTIND_MORE ; Jump if so

	 loop	 GET_NEXTIND1	; Jump if more items

	 stc			; Indicate there's no more items

	 jmp	 short GET_NEXTIND_EXIT ; Join common exit code

GET_NEXTIND_MORE:
	 mov	 ADVIND,bx	; Save for later use

	 clc			; Indicate there's more to do
GET_NEXTIND_EXIT:
	 REGREST <si,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_NEXTIND endp		; End GET_NEXTIND procedure
	NPPROC	COUNT_CONT -- Count In One More Continuous Round
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Count in one more continuous round.

|

	inc	CONTCNT 	; Count in one more continuous iteration
	or	CNT_FLAG,@CNT_CHG ; Mark as having changed

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COUNT_CONT endp 		; End COUNT_CONT procedure
	 NPPROC  SET_ASKCOUNT -- Set ASK Table Counts
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set ask table counts

|

	 and	 CNT_FLAG,not @CNT_BASIC ; Assume advanced mode
	mov	CONTCNT,0	; Initialize continuous iteration count

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short SET_ASKCOUNT_BAS ; Jump if not

; If the count for the current index is zero, change it to one
; to reflect what we're actually doing.

	 push	 bx		; Save for a moment

	 mov	 bx,ADVIND	; Get current index
	 shl	 bx,1		; Times two to index table of words

	 cmp	 ITEMCNT[bx],1	; Izit default value?
	 adc	 ITEMCNT[bx],0	; Set the actual count value

	 pop	 bx		; Restore

	 jmp	 short SET_ASKCOUNT_EXIT ; Join common exit code

SET_ASKCOUNT_BAS:
	 or	 CNT_FLAG,@CNT_BASIC ; Mark as BASIC mode

	 cmp	 BASIND,0	; Izit Quick?
	 je	 short SET_ASKCOUNT_BASQ ; Jump if so

	 mov	 ITEMCNT[@ASK_UNLSAF * (type ITEMCNT)],0 ; Clear in case leftover
	 mov	 ITEMCNT[@ASK_UNLTRN * (type ITEMCNT)],0 ; ...
	 mov	 ITEMCNT[@ASK_UNLINV * (type ITEMCNT)],0 ; ...
	 mov	 ITEMCNT[@ASK_LNKINV * (type ITEMCNT)],0 ; ...

	 mov	 ITEMCNT[@ASK_UNLIDM * (type ITEMCNT)],1 ; Set the initial value
	 mov	 ITEMCNT[@ASK_LNKIDM * (type ITEMCNT)],1 ; ...

	 mov	 ADVIND,@ASK_UNLIDM ; Start with this one

	 jmp	 short SET_ASKCOUNT_EXIT ; Join common exit code

SET_ASKCOUNT_BASQ:
	 mov	 ITEMCNT[@ASK_UNLSAF * (type ITEMCNT)],0 ; Clear in case leftover
	 mov	 ITEMCNT[@ASK_UNLINV * (type ITEMCNT)],0 ; ...
	 mov	 ITEMCNT[@ASK_LNKINV * (type ITEMCNT)],0 ; ...
	 mov	 ITEMCNT[@ASK_UNLIDM * (type ITEMCNT)],0 ; ...
	 mov	 ITEMCNT[@ASK_LNKIDM * (type ITEMCNT)],0 ; ...

	 mov	 ITEMCNT[@ASK_UNLTRN * (type ITEMCNT)],1 ; Set to initial value

	 mov	 ADVIND,@ASK_UNLTRN ; Start with this one
SET_ASKCOUNT_EXIT:
	 or	 CNT_FLAG,@CNT_CHG ; Mark as having changed

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_ASKCOUNT endp		; End SET_ASKCOUNT procedure
	 NPPROC  SWITCH_MODE -- Switch Between Modes
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Switch between advanced and basic modes.

|

	 xor	 GL2_FLAG,@GL2_ADV ; Toggle the mode

	 mov	 ASKBLK,@ITEM_ASKADV ; Assume we're in advanced mode

	 test	 GL2_FLAG,@GL2_ADV ; Izit now in advanced mode?
	 jnz	 short @F	; Jump if so

	 mov	 ASKBLK,@ITEM_ASKBAS ; Assume we're in basic mode
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWITCH_MODE endp		; End SWITCH_MODE procedure
	 NPPROC  GET_MEMTIMER -- Get Memory Timer Tick Count
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Get memory timer tick count

On exit:

EDX:EAX  =	 memory timer tick count

|

	 mov	 eax,MEMTIMER.EDQLO ; Get low-order dword of timer tick count
	 mov	 edx,MEMTIMER.EDQHI ; ... high-

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_MEMTIMER endp		; End GET_MEMTIMER procedure
	 NPPROC  CHECK_KEYS -- Check On Interesting Keys
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on interesting keys.

On exit:

ZF	 =	 0 if we're to halt
	 =	 1 if we're continuing

|

	 REGSAVE <ax>		; Save register

	 test	 CNT_FLAG,@CNT_HALT ; Izit already halting?
	 jnz	 short CHECK_KEYS_EXIT ; Jump if so (note ZF=0)

CHECK_KEYS1:
	 call	 CHKNDKEY	; Is there a keystroke available?
				; Return with AX = keystroke, ZF significant
	 jz	 short CHECK_KEYS_EXIT ; Jump if not (note ZF=1)

	 call	 GETKEY 	; Request a keystroke

; If it's the halt key, terminate the iterations, and check the next key.
; If it's Alt-TAB, switch screens, and check the next key.
;    the F9 key will also switch screens, and check the next key.
; If it's D, set decimal mode, and check the next key.
; If it's H, set hexadecimal mode, and check the next key.
; If it's F5, toggle the color state, and check the next key.
; If not, clear the keystroke and continue

	 cmp	 ax,@KEY_SWITCH_MODE ; Izit switch modes?
	 je	 short DO_SWITCH_MODE ; Jump if so

	 cmp	 ax,@KEY_SWITCH_MODE2 ; Izit the other switch modes?
	 jne	 short @F	; Jump if not

DO_SWITCH_MODE:
	 call	 SWITCH_MODE	; Switch to the other mode

	 cmp	 HELP_STATE,@HELP_SCREEN ; Displaying Help?
	 je	 short @F	; Jump if so

	 call	 DISP_SCRN	; Display the new screen
	 call	 DISP_ACTIV	; Display active elements
@@:
	 cmp	 ax,@KEY_D	; Izit Decimal?
	 je	 short CHECK_KEYS10 ; Jump if so

	 cmp	 ax,@KEY_SHF_D	; Izit Decimal?
	 jne	 short @F	; Jump if not
CHECK_KEYS10:
	 and	 GL2_FLAG,not @GL2_HEX ; Set to decimal

	 jmp	 short CHECK_KEYS_BASE ; Join common code

@@:
	 cmp	 ax,@KEY_H	; Izit Hexadecimal?
	 je	 short CHECK_KEYS16 ; Jump if so

	 cmp	 ax,@KEY_SHF_H	; Izit Hexadecimal?
	 jne	 short @F	; Jump if not
CHECK_KEYS16:
	 or	 GL2_FLAG,@GL2_HEX ; Set to hexadecimal
CHECK_KEYS_BASE:
	 or	 CNT_FLAG,@CNT_CHG ; Mark as having changed

	 call	 DISP_BASE	; Display the current number base
	 call	 DISP_MEMVAL	; Display the memory values

	 push	 ax		; Save for a moment

	 mov	 al,WMEMATTR	; Get working memory line attribute
	 call	 DISP_MEMWRK	; Display memory line working attribute

	 pop	 ax		; Restore
@@:
	 cmp	 HELP_STATE,@HELP_NONE ; Are we displaying help?
	 jne	 short CHECK_KEYS_HELP ; Jump if so

	 cmp	 ax,@KEY_F1	; Did we press F1?
	 jne	 short @F	; Jump if so

CHECK_KEYS_HELP:
	 call	 DISP_HELP	; Update current state
	 jmp	 short CHECK_KEYS1 ; Go around again

@@:
	 cmp	 ax,@KEY_F5	; Izit toggle color state?
	 jne	 short @F	; Jump if not

	 call	 SWITCH_COLOR	; Toggle the color state
@@:
	 cmp	 ax,@KEY_HALT	; Izit the halt key (Esc)?
	 jne	 short CHECK_KEYS1 ; Jump if not

	 call	 ASK_HALT	; Ask to see if that's what the user really wants
				; Return with ZF significant
;;;;;;;; jz	 short CHECK_KEYS_CONT ; Jump if we're to continue
CHECK_KEYS_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_KEYS endp 		; End CHECK_KEYS procedure
	 NPPROC  SWITCH_COLOR -- Toggle The Color State
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Toggle the color state

|

	 REGSAVE <ax>		; Save register

	 mov	 ax,CLRMODE	; Get color mode:  0 = mono, 1 = B&W, 2 = color

	 and	 ax,ax		; Izit mono?
	 jz	 short @F	; Jump if so (ignore it)

	 sub	 ax,3		; Convert 1 to -2, 2 to -1
	 neg	 ax		; Convert -2 to 2, -1 to 1
	 mov	 CLRMODE,ax	; Save for later use

; Set screen attributes for Monochrome, Black & White, or Color adapters

	 call	 SET_COLOR	; Set 'em

	 call	 DISP_SCRN	; Display the new screen
	 call	 DISP_ACTIV	; Display active elements
@@:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWITCH_COLOR endp		; End SWITCH_COLOR procedure
	 NPPROC  CHECK_HALT -- See If We Should Halt
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we should halt

On exit:

ZF	 =	 0 if we're to halt
	 =	 1 if we're to continue

|

	 test	 CNT_FLAG,@CNT_NMI or @CNT_HALT ; Did an external NMI/halt occur?
	 jz	 short CHECK_HALT_EXIT ; Jump if not (note ZF=1)

	 test	 CNT_FLAG,@CNT_NMI ; Did an external NMI occur?
	 jnz	 short CHECK_HALT_EXIT ; Jump if so (note ZF=0)

	 call	 ASK_HALT	; Ask to see if that's what the user really wants
				; Return with ZF significant
;;;;;;;; jz	 short CHECK_HALT_CONT ; Jump if we're to continue
CHECK_HALT_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_HALT endp 		; End CHECK_HALT procedure
	 NPPROC  ASK_HALT -- Ask About Halting
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if the user really wants to halt.

On exit:

ZF	 =	 0 if we're to halt
	 =	 1 if we're to continue

|

	 REGSAVE <ax,bx>	; Save registers

	 mov	 bx,GL2_FLAG	; Save state of @GL2_ACTIV
	 and	 bx,@GL2_ACTIV	; Isolate active flag
	 and	 GL2_FLAG,not @GL2_ACTIV ; Mark as no longer active
				; so the timers don't overwrite the screen

	 mov	 al,HLTATTR	; Get halt screen attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_HALTSCR ; Pass address of local buffer
	 push	 offset ds:W_HALT ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display a shadow below and to the right of the ask-halt screen

	 push	 offset ds:W_HALT ; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

; If we detected Esc in our Int 9 handler, we need to flush the first
; Esc before we ask for another keystroke.
	 btr	 CNT_FLAG,$CNT_KFLUSH ; Are we triggered via Int 9?
	 jnc	 short ASK_HALT_AGAIN ; Jump if not

	 call	 GETKEY 	; Purge keystroke from buffer
ASK_HALT_AGAIN:
	 call	 GETKEY 	; Request a keystroke, return in AX

	 cmp	 ax,@KEY_HALT	; Izit Esc again?
	 jne	 short ASK_HALT_CONT ; Jump if not (we're to continue)

ASK_HALT_HALT:
	 call	 CLEAR_CONT	; Mark as no longer continuous
	 or	 CNT_FLAG,@CNT_HALT ; Mark as halt key pressed
	 and	 ax,ax		; Set ZF=0 to halt

	 jmp	 short ASK_HALT_EXIT ; Join common exit code

ASK_HALT_CONT:
	 and	 CNT_FLAG,not @CNT_HALT ; Mark as not halting

	 or	 GL2_FLAG,bx	; Restore active flag

	 cmp	 ax,ax		; Set ZF=1 to continue
ASK_HALT_EXIT:
	 pushf			; Save flags (ZF in particular)

	 call	 DISP_SCRN	; Display the new screen
	 call	 DISP_ACTIV	; Display active elements

	 popf			; Restore flags

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ASK_HALT endp			; End ASK_HALT procedure
	 NPPROC  COUNTOUT -- Account For One Fewer Iteration
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Account for one fewer iteration unless we halted prematurely.

|

ACCT_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
ACCT_IND dw	 ?		; Row index

ACCT_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx>	; Save registers

	 test	 CNT_FLAG,@CNT_HALT ; Did we terminate on request?
	 jnz	 short COUNTOUT_EXIT ; Jump if so

	 imul	 bx,[bp].ACCT_IND,type ITEMCNT ; Get the row index

	 mov	 ax,ITEMCNT[bx] ; Get the count

	 cmp	 ax,@ICNT_CONT	; Izit continuous?
	 je	 short COUNTOUT_EXIT ; Jump if so

	 and	 ax,ax		; Izit unspecified (default)?
	 jz	 short COUNTOUT_EXIT ; Jump if so

	 dec	 ax		; One fewer iteration
	 mov	 ITEMCNT[bx],ax ; Save back

	 or	 CNT_FLAG,@CNT_CHG ; Mark as changed
COUNTOUT_EXIT:
	 REGREST <bx,ax>	; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COUNTOUT endp			; End COUNTOUT procedure
	 NPPROC  SET_BARATTR -- Set Current Bar Attribute
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set current bar attribute.

On entry:

AL	 =	 attribute to use
DGROUP:BX ==>	 BLK_STR
SI	 =	 ptr to ptr to text to display

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save for a moment

	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 short SET_BARA_EXIT ; Jump if so

	 mov	 cx,BLK_STRS[bx].BLK_IND ; Get current index
	 shl	 cx,1		; Times two to index table of words

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into current struc

	 xor	 dx,dx		; Assume it's memory screen

	 cmp	 ASKBLK,@ITEM_MEMADV ; Izit memory screen?
	 je	 short @F	; Jump if so

	 add	 si,cx		; Add to ptr to ptr to active text
	 imul	 dx,BLK_STRS[bx].BLK_IND,type W_STR ; Get current index
@@:
	 add	 dx,BLK_STRS[bx].BLK_PARR ; Add offset of array of W_STRs
				; to get offset in DGROUP of W_STR
	 push	 ax		; Pass attribute to smear
	 push	 DGROUP:[si].ELO ; Pass offset of local buffer
	 push	 dx		; Pass offset of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 call	 CHECK_RHELP	; Update help display if needed
SET_BARA_EXIT:
	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_BARATTR endp		; End SET_BARATTR procedure
	 NPPROC  SET_COMPLETE -- Mark Item as Complete
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark current item as completed.

On entry:

CL	 =	 marker

|

	 REGSAVE <bx>		; Save register

	 mov	 bx,ADVIND	; Get current index
	 shl	 bx,1		; Times two to index table of words
	 mov	 bx,CMPTAB[bx]	; Get offset in DGROUP of save byte
	 mov	 DGROUP:[bx],cl ; Mark as complete

	 call	 DISP_ASKITEM	; Display the ask and item counts

	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_COMPLETE endp		; End SET_COMPLETE procedure
	 NPPROC  DISP_ASKITEM -- Display Ask and Item Counts
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display ask and item counts

|

	 REGSAVE <ax,bx,cx,si,di,es> ; Save registers

	 cmp	 HELP_STATE,@HELP_SCREEN ; Displaying help screen?
	 je	 short DISP_ASKITEM_EXIT ; Jump if so

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short DISP_ASKITEM_EXIT ; Jump if not

	 btr	 CNT_FLAG,$CNT_CHG ; Has anything changed?
	 jnc	 short DISP_ASKITEM1 ; Jump if not

	mov	MSG_ASK_CONT[-3].EDD,'    ' ; Clear in case not continuous
	mov	MSG_ASK_CONT[ 1],' ' ; ...

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 cx,@ASKITEM_LEN ; Get # item counts
	 xor	 bx,bx		; Initialize item count index
	 xor	 si,si		; Initialize item count offset index
DISP_ASKITEM_NEXT:
	 mov	 di,CNTTAB[si]	; ES:DI ==> units digit
	 mov	 es:[di-4].EDD,'  [ ' ; Clear the field
	 mov	 es:[di].LO,'C' ; Assume continuous
	 mov	 ax,ITEMCNT[bx] ; Get next item count value

	 cmp	 ax,@ICNT_CONT	; Izit continuous value?
	 je	 short DISP_ASKITEM_LOOP ; Jump if so

	 push	 di		; Save ending address
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI
	 pop	 di		; Restore
DISP_ASKITEM_LOOP:
	 add	 si,type CNTTAB  ; Skip to the next count offset
	 add	 bx,type ITEMCNT ; Skip to the next item

	 loop	 DISP_ASKITEM_NEXT ; Jump if more item counts

; If there are any continuous items, display the current count

	test	GL2_FLAG,@GL2_CONT ; Izit continuous?
	jz	short DISP_ASKITEM1 ; Jump if not

	mov	ax,CONTCNT	; Get current count
	lea	di,MSG_ASK_CONT ; ES:DI ==> units digit
	call	BIN2DEC 	; Convert AX to decimal ending at ES:DI
	mov	MSG_ASK_CONT[1],'C' ; Mark as continuous
DISP_ASKITEM1:
	 mov	 al,BLK_STRS[@ITEM_ASKADV * (type BLK_STR)].BLK_BASK ; Get background ask attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_ASK ; Pass address of local buffer
	 push	 offset ds:W_ASK ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute
DISP_ASKITEM_EXIT:
	 REGREST <es,di,si,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ASKITEM endp		; End DISP_ASKITEM procedure
	 NPPROC  DISP_ACTIV -- Display Active Elements
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display active screen elements

|

	 call	 DISP_ASKITEM	; Display the ask and item counts
	 call	 DISP_MEMVAL	; Display the memory values
	 call	 DISP_PROGSCR	; Display the progress screen
	 call	 DISP_PROGRESS	; Display the progress bar on screen
	 call	 DISP_ETA	; Display estimated time to complete
	 call	 DISP_ELAP	; Display elapsed time
	 call	 DISP_TEST	; Display the testing state

	 cmp	 PATOFF,0	; Izit active?
	 je	 short @F	; Jump if not

	 call	 PATOFF 	; Display the current pattern
@@:
	 call	 DISP_STATLIN	; Display the status lines

	 REGSAVE <ax,bx,si>	; Save for a moment

	 mov	 al,WMEMATTR	; Get working memory line attribute
	 call	 DISP_MEMWRK	; Display memory line working attribute

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into BLK_STRS
	 mov	 al,BLK_STRS[bx].BLK_AASK ; Get active ask attribute
	 mov	 si,BLK_STRS[bx].BLK_PPATXT ; Get ptr to ptr to active text
	 call	 SET_BARATTR	; Set bar attribute

	 REGREST <si,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ACTIV endp 		; End DISP_ACTIV procedure
	 NPPROC  DISP_STATLIN -- Display Status Lines
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we're in advanced mode, display the status screen contents

|

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short @F	; Jump if not

	 push	 offset ds:MSG_SCROLL ; Pass address of local buffer
	 push	 offset ds:W_SCROLL ; Pass address of window descriptor
	 call	 WPUT_CA	; Output the characters and attributes
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STATLIN endp		; End DISP_STATLIN procedure
	 NPPROC  CLEAR_STATLIN -- Clear The Status Lines
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the status lines

|

	 REGSAVE <ax,cx,dx,di,es> ; Save registers

	 push	 ds		; Get DGROUP segment/selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 ax,W_SCROLL.NROW ; Get # rows in MSG_SCROLL
	 mul	 W_SCROLL.NCOL	; Times # cols ...

	 mov	 cx,ax		; Get # char/attrs in MSG_SCROLL
	 mov	 al,' '         ; Fill with blanks
	 mov	 ah,STATLATTR	; Get status line attribute
	 lea	 di,MSG_SCROLL	; ES:DI ==> MSG_SCROLL
     rep stos	 MSG_SCROLL[di].ELO ; Fill 'er up

	 REGREST <es,di,dx,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_STATLIN endp		; End CLEAR_STATLIN procedure
	 NPPROC  DISP_PROGSCR -- Display Progress Screen
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display progress screen

|

	 push	 ax		; Save for a moment

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jnz	 short DISP_PROGSCR_EXIT ; Jump if so

	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 short DISP_PROGSCR_EXIT ; Jump if so

; Display the progress screen without data

	 mov	 al,PRGATTR	; Get progress attribute
	 push	 ax		; Pass as argument
	 push	 offset ds:MSG_PROGSCR ; Pass offset of local buffer
	 push	 offset ds:W_PROG ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display a shadow below and to the right of the progress screen

	 push	 offset ds:W_PROG ; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

; Display blanks in the progress bar location

	 mov	 ah,PRG2ATTR	; Get inactive progress attribute
	 mov	 al,' '         ; Get a blank character
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_PBAR ; Pass address of window descriptor
	 call	 WPUT_SCA	; Smear character/attribute

	 inc	 W_PBAR.SROW	; Skip to the next row

;;;;;;;; mov	 ah,PRG2ATTR	; Get inactive progress attribute
;;;;;;;; mov	 al,' '         ; Get a blank character
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_PBAR ; Pass address of window descriptor
	 call	 WPUT_SCA	; Smear character/attribute

	 dec	 W_PBAR.SROW	; Restore

	 call	 DISP_TEST	; Display the testing state
DISP_PROGSCR_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_PROGSCR endp		; End DISP_PROGSCR procedure
	 NPPROC  DISP_TEST -- Display Test State
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display test state

|

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jnz	 short DISP_TEST_EXIT ; Jump if so

	 call	 CALC_PTST	; See if we need to calculate LAST_PTST

	 push	 LAST_PTST	; Pass address of local buffer
	 push	 offset ds:W_PTST ; Pass address of window descriptor
	 call	 WPUT_C 	; Output the characters
DISP_TEST_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_TEST endp			; End DISP_TEST procedure
	 NPPROC  DISP_OPERS -- Display The Current Number of Operations
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the current number of operations
and estimated time to completion.

This routine runs in protected mode.

|

	 test	 GL2_FLAG,@GL2_CONT ; Izit continuous?
	 jnz	 near ptr DISP_OPERS_EXIT ; Jump if so

	 test	 GL2_FLAG,@GL2_ACTIV ; Izit active?
	 jz	 near ptr DISP_OPERS_EXIT ; Jump if not

	 mov	 DECTIMER.EDQLO,0 ; No time for decrementing
	 mov	 DECTIMER.EDQHI,0 ; ...

	 REGSAVE <eax,ebx,ecx,edx,di,es> ; Save registers

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 CALC_PCT	; Return with EAX = percentage complete
	 mov	 PROGPCT,ax	; Save for later use
	 mov	 cx,ax		; Copy to count register

	 mov	 al,'Û'         ; Smear a full character
	 lea	 di,MSG_PBAR	; ES:DI ==> progress display

	 shr	 cx,1		; Divide by two to get screen units
     rep stos	 MSG_PBAR[di]	; Fill with progress
	 jnc	 short @F	; Jump if it's even

; The count is odd:  use a left-half character

	 mov	 al,'Ý'         ; Use a left-half character
S16	 stos	 MSG_PBAR[di]	; Fill with half progress
@@:

; Display the progress bar on screen

	 call	 DISP_PROGRESS	; Display it

COMMENT|

Calculate estimated time to completion.

The total # operations to be done is in TOTOPERS,
the # operations done so far is in NUMOPERS,
and the time used so far is MEMTIMER - INITIMER.

The estimated time to completion is

(MEMTIMER - INITIMER) * (TOTOPERS - NUMOPERS) / NUMOPERS

|

	 mov	 ebx,TOTOPERS.EDQLO ; Get total # operations
	 mov	 ecx,TOTOPERS.EDQHI ; ...

	 sub	 ebx,NUMOPERS.EDQLO ; Less # operations so far
	 sbb	 ecx,NUMOPERS.EDQHI ; ...

	 call	 GET_MEMTIMER	; Return with EDX:EAX=local timer tick count
	 sub	 eax,INITIMER.EDQLO ; Less starting time to get elapsed time
	 sbb	 edx,INITIMER.EDQHI ; ...

; Multiply EDX:EAX by ECX:EBX, result in TMPOPERS

; EBX * EAX =	      HI, LO
; ECX * EAX =	  XX, HI
; EBX * EDX =	  XX, HI
; ECX * EDX = XX, XX		(ignored)

	 REGSAVE <eax,edx>	; Save qword

	 mul	 ebx		; EDX:EAX = EAX * EBX
	 mov	 TMPOPERS.EDQLO,eax ; Save for a moment
	 mov	 TMPOPERS.EDQHI,edx ; ...

	 REGREST <edx,eax>	; Restore

	 push	 edx		; Save dword

	 mul	 ecx		; EDX:EAX = EAX * ECX
	 add	 TMPOPERS.EDQHI,eax ; Save for a moment

	 pop	 eax		; Restore to EAX

	 mul	 ebx		; EDX:EAX = EDX * EBX
	 add	 TMPOPERS.EDQHI,eax ; Add into accumulator

	 mov	 eax,TMPOPERS.EDQLO ; Get temporary qword
	 mov	 edx,TMPOPERS.EDQHI ; ...

	 mov	 ebx,NUMOPERS.EDQLO ; Get # operations so far
	 mov	 ecx,NUMOPERS.EDQHI ; ...

	 call	 SCALE_DOWN	; Scale EDX:EAX and ECX:EBX until ECX=0

; Divide by EBX to get estimated time in timer ticks

	 and	 ebx,ebx	; Izit scaled down to zero?
	 jz	 short @F	; Jump if so with quotient in EBX

	 div	 ebx		; Divide to get timer ticks
	 mov	 ebx,eax	; Copy quotient
@@:
	 mov	 eax,ebx	; Restore quotient
	 xor	 edx,edx	; Zero to use as dword
	 mov	 ETATIMER.EDQLO,eax ; Save for later use
	 mov	 ETATIMER.EDQHI,edx ; ...

	 call	 DISP_ETA	; Display estimated time to complete

	 REGREST <es,di,edx,ecx,ebx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it
DISP_OPERS_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_OPERS endp 		; End DISP_OPERS procedure
	 NPPROC  DISP_PROGRESS -- Display Progress Bar
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display progress bar

|

	 REGSAVE <ax>		; Save register

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jnz	 short DISP_PROGRESS_EXIT ; Jump if so

	 cmp	 HELP_STATE,@HELP_NONE ; Are we displaying help?
	 jne	 short DISP_PROGRESS_EXIT ; Jump if so

; Display the progress on screen

	 mov	 al,PRG1ATTR	; Get active progress attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_PBAR ; Pass address of local buffer
	 push	 offset ds:W_PBAR ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 inc	 W_PBAR.SROW	; Skip to the next row

;;;;;;;; mov	 al,PRG1ATTR	; Get active progress attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_PBAR ; Pass address of local buffer
	 push	 offset ds:W_PBAR ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 dec	 W_PBAR.SROW	; Restore

; Fill the trailing progress columns with other attribute

	 REGSAVE <W_PBAR.SCOL,W_PBAR.NCOL> ; Save for a moment

	 mov	 ax,PROGPCT	; Get progess percentage
	 inc	 ax		; Round up
	 shr	 ax,1		; Divide by two to get screen units
	 add	 W_PBAR.SCOL,ax ; Skip over active progress columns
	 sub	 W_PBAR.NCOL,ax ; ...

	 mov	 al,PRG2ATTR	; Get inactive progress attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_PBAR ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

	 inc	 W_PBAR.SROW	; Skip to the next row

;;;;;;;; mov	 al,PRG2ATTR	; Get inactive progress attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_PBAR ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

	 dec	 W_PBAR.SROW	; Restore

	 REGREST <W_PBAR.NCOL,W_PBAR.SCOL> ; Restore
DISP_PROGRESS_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_PROGRESS endp		; End DISP_PROGRESS procedure
	 NPPROC  DISP_ETA -- Display Estimated Time To Complete
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display estimated time to complete

|

	 REGSAVE <eax,edx,di,es> ; Save registers

	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 short DISP_ETA_EXIT ; Jump if so

	 test	 GL2_FLAG,@GL2_CONT ; Izit continuous?
	 jnz	 short DISP_ETA_EXIT ; Jump if so

	 test	 GL2_FLAG,@GL2_ACTIV ; Izit active?
	 jz	 short DISP_ETA_EXIT ; Jump if not

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,ETATIMER.EDQLO ; Get estimated time to complete
	 mov	 edx,ETATIMER.EDQHI ; ...

; Decrement the ETA by the amount of time between calls to DISP_OPERS

	 sub	 eax,DECTIMER.EDQLO ; Subtract out the timer
	 sbb	 edx,DECTIMER.EDQHI ; ...
	 jnc	 short @F	; Jump if no overflow

; The decrementing time is too large:  use a time of zero

	 xor	 eax,eax	; Use ETA of zero
	 xor	 edx,edx	; ...
@@:
	 lea	 di,MSG_ETA_HR	; ES:DI ==> output save area
	 call	 FMT_ELAPSUB	; Format EDX:EAX into ES:DI

	 lea	 ax,W_ETA2	; Get address of window descriptor (advanced)

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jnz	 short @F	; Jump if so

	 lea	 ax,W_ETA1	; Get address of window descriptor (basic)
@@:
	 push	 offset ds:MSG_ETA_HR ; Pass address of local buffer
	 push	 ax		; Pass address of window descriptor
	 call	 WPUT_C 	; Output the characters
DISP_ETA_EXIT:
	 REGREST <es,di,edx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ETA endp			; End DISP_ETA procedure
	 NPPROC  CALC_PCT -- Calculate Percentage Complete
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate percentage complete.

On exit:

EAX	 =	 percentage complete (0-100)

|

	 REGSAVE <ebx,ecx,edx>	; Save registers

; Scale NUMOPERS up by 100 so when we divide by TOTOPERS,
; we get a percentage.

	 mov	 eax,100	; Get multiplier
	 mul	 NUMOPERS.EDQLO ; Times low-order dword

	 mov	 ebx,eax	; Save for a moment
	 mov	 ecx,edx	; ...

	 mov	 eax,100	; Get multiplier
	 mul	 NUMOPERS.EDQHI ; Times high-order dword

	 add	 ecx,eax	; Add into high-order dword

	 mov	 eax,ebx	; Copy low-order dword
	 mov	 edx,ecx	; ...  high-...

; In case TOTOPERS is bigger than a dword, scale it and ECX:EBX down
; into range of a dword so we can divide one by the other.

	 mov	 ebx,TOTOPERS.EDQLO ; Get low-order dword
	 mov	 ecx,TOTOPERS.EDQHI ; ... high-...

	 call	 SCALE_DOWN	; Scale EDX:EAX and ECX:EBX until ECX=0

	 and	 ebx,ebx	; Izit scaled down to zero?
	 jz	 short @F	; Jump if so with quotient in EBX

; Divide by EBX to get percentage complete

	 div	 ebx		; Divide by total # operations
				; Quotient in EAX (0-100)
	 mov	 ebx,eax	; Copy quotient
@@:
	 mov	 eax,ebx	; Restore quotient

	 REGREST <edx,ecx,ebx>	; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_PCT endp			; End CALC_PCT procedure
	 NPPROC  SCALE_DOWN -- Scale Down
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Scale down EDX:EAX and ECX:EBX until ECX = 0.

On entry:

EDX:EAX  =	 qword to scale down
ECX:EBX  =	 qword to scale down

On exit:

EDX:EAX  =	 scaled down
ECX:EBX  =	 scaled down

|

@@:
	 jecxz	 @F		; Jump if it's within range

	 shr	 ecx,1		; Shift high-order dword down
	 rcr	 ebx,1		; ...

	 shr	 edx,1		; ...
	 rcr	 eax,1		; ...

	 jmp	 @B		; Go around again

@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SCALE_DOWN endp 		; End SCALE_DOWN procedure
	 NPPROC  CALC_NOPERS -- Calculate The Total Number of Operations
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the total number of operations.

The total # byte-operations is the sum of the products
of the byte sizes per chip width times the # operations
for each chip width.

This routine runs in protected mode.

|

	 pushad 		; Save all EGP registers

	 mov	 ETATIMER.EDQLO,0 ; Initialize ETA
	 mov	 ETATIMER.EDQHI,0 ; ...

	 mov	 DECTIMER.EDQLO,0 ; Initialize ETA decrement
	 mov	 DECTIMER.EDQHI,0 ; ...

	 mov	 cx,@ASKITEM_LEN ; Get # ITEMCNT values
	 xor	 bx,bx		; Initialize index into ITEMCNT
				; and ITEMOPERS
	 mov	 TOTOPERS.EDQLO,0 ; Initialize # operations
	 mov	 TOTOPERS.EDQHI,0 ; ...

	 and	 GL2_FLAG,not @GL2_CONT ; Mark as not continuous
	 mov	 LAST_PTST,-1	; Mark as to be computed
CALC_NOPERS_NEXT:
	 mov	 ax,ITEMCNT[bx] ; Get the item count

	 and	 ax,ax		; Izit to be run?
	 jz	 near ptr CALC_NOPERS_LOOP ; Jump if not

	 cmp	 ax,@ICNT_CONT	; Izit continuous?
	 je	 near ptr CALC_NOPERS_CONT ; Jump if so

	 mov	 si,ITEMOPERS[bx] ; Get the offset in DGROUP of CALIB_xxx

	 mov	 TMPOPERS.EDQLO,0 ; Initialize # operations
	 mov	 TMPOPERS.EDQHI,0 ; ...

	 REGSAVE <bx,cx>	; Save for a moment

	 mov	 cx,DGROUP:[si].PCALIB_LEN ; Get # calibration entries
				; for this module
	 mov	 si,DGROUP:[si].PCALIB_PTR ; Get the ptr to the ptr to this
				; module's calibration entries
	 xor	 eax,eax	; Initialize accumulator for per iteration
	 xor	 edx,edx	; ...			     overhead
@@:
	 mov	 bx,DGROUP:[si].ELO ; Get next ptr
	 add	 eax,DGROUP:[bx].CALIB_PERIT ; Accumulate timing value
	 add	 edx,DGROUP:[bx].CALIB_OVHD ; ...

	 add	 si,2		; Skip to next ptr

	 loop	 @B		; Jump if more calibration entries

	 REGREST <cx,bx>	; Restore

; Accumulate constant overhead time

	 push	 eax		; Save for a moment

	 mov	 eax,edx	; Copy overhead time
	 mul	 NMEMVAL	; Times # valid memory ranges

	 cmp	 TSTSIZEB,0	; Is there any byte-wide memory to test?
	 je	 short @F	; Jump if not

	 push	 3		; Pass # bits in a byte
	 call	 ADD_TMPOPERS	; Add EDX:EAX to TMPOPERS pattern count times
@@:
	 cmp	 TSTSIZEW,0	; Is there any word-wide memory to test?
	 je	 short @F	; Jump if not

	 push	 4		; Pass # bits in a word
	 call	 ADD_TMPOPERS	; Add EDX:EAX to TMPOPERS pattern count times
@@:
	 cmp	 TSTSIZED,0	; Is there any dword-wide memory to test?
	 je	 short @F	; Jump if not

	 push	 5		; Pass # bits in a dword
	 call	 ADD_TMPOPERS	; Add EDX:EAX to TMPOPERS pattern count times
@@:
	 pop	 eax		; Restore

; Accumulate per iteration times

	 push	 eax		; Save for a moment

	 mul	 TSTSIZEB	; Times # byte-wide bytes

	 push	 3		; Pass # bits in a byte
	 call	 ADD_TMPOPERS	; Add EDX:EAX to TMPOPERS pattern count times

	 pop	 eax		; Restore

	 push	 eax		; Save for a moment

	 mul	 TSTSIZEW	; Times # word-wide bytes

	 push	 4		; Pass # bits in a word
	 call	 ADD_TMPOPERS	; Add EDX:EAX to TMPOPERS pattern count times

	 pop	 eax		; Restore

	 push	 eax		; Save for a moment

	 mul	 TSTSIZED	; Times # dword-wide bytes

	 push	 5		; Pass # bits in a dword
	 call	 ADD_TMPOPERS	; Add EDX:EAX to TMPOPERS pattern count times

	 pop	 eax		; Restore

	 movzx	 eax,ITEMCNT[bx] ; Get the item count
	 mul	 TMPOPERS.EDQLO ; Times low-order dword

	 add	 TOTOPERS.EDQLO,eax ; Add into total
	 adc	 TOTOPERS.EDQHI,edx ; ...

	 movzx	 eax,ITEMCNT[bx] ; Get the item count
	 mul	 TMPOPERS.EDQHI ; Times high-order dword

	 add	 TOTOPERS.EDQHI,eax ; Add into total
CALC_NOPERS_LOOP:
	 add	 bx,type ITEMCNT ; Skip to next entry

;;;;;;;; loop	 CALC_NOPERS_NEXT ; Jump if more entries to check
	 dec	 cx		; Account for one fewer entry
	 jnz	 near ptr CALC_NOPERS_NEXT ; Jump if more entries to check

	 jmp	 short CALC_NOPERS_EXIT ; Join common exit code

CALC_NOPERS_CONT:
	 or	 GL2_FLAG,@GL2_CONT ; Mark as continuous
	 mov	 LAST_PTST,offset DGROUP:MSG_PTSTALL ; Save as last PTST
CALC_NOPERS_EXIT:

; Clear the progress bar

	 push	 es		; Save for a moment

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 al,' '         ; Clear to blanks
	 mov	 cx,length MSG_PBAR ; # bytes to clear
	 lea	 di,MSG_PBAR	; ES:DI ==> buffer
     rep stos	 MSG_PBAR[di]	; Clear 'em

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 mov	 NUMOPERS.EDQLO,0 ; Clear # operations
	 mov	 NUMOPERS.EDQHI,0 ; ...

	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_NOPERS endp		; End CALC_NOPERS procedure
	 NPPROC  ADD_TMPOPERS -- Add EDX:EAX To TMPOPERS Pattern Count Times
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Add EDX:EAX to TMPOPERS pattern count times

On entry:

EDX:EAX  =	 amount to add
BX	 =	 index into ITEMPATCNT

|

ADDTMP_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
ADDTMP_BIT dw	 ?		; # bits in corresponding memory width
				; (3, 4, or 5)
ADDTMP_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <bx,cx>	; Save registers

	 mov	 bx,ITEMPATCNT[bx] ; Get pattern count multiplier (0 or 1)
	 mov	 cx,[bp].ADDTMP_BIT ; Get # bits in memory width (3, 4, or 5)
	 shl	 bx,cl		; Times # bits per unit
	 mov	 cx,bx		; Copy to count register

; In case this test doesn't use patterns (i.e. USF or UTF), ensure we add
; in EDX:EAX at least once.

	 cmp	 cx,1		; Izit without pattern?
	 adc	 cx,0		; Ensure minimum of one
@@:
	 add	 TMPOPERS.EDQLO,eax ; Add into total
	 adc	 TMPOPERS.EDQHI,edx ; ...

	 loop	 @B		; Jump if more bits per pattern

	 REGREST <cx,bx>	; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ADD_TMPOPERS endp		; End ADD_TMPOPERS procedure
	 NPPROC  FMT_ELAP -- Calculate And Format Elapsed Time
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate and format elapsed time

|

	 REGSAVE <eax,edx,di,es> ; Save registers

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 GET_MEMTIMER	; Return with EDX:EAX=local timer tick count
	 sub	 eax,INITIMER.EDQLO ; Less starting time to get elapsed time
	 sbb	 edx,INITIMER.EDQHI ; ...

	 lea	 di,ZMSG_ELAP_HR ; ES:DI ==> output save area
	 call	 FMT_ELAPSUB	; Format EDX:EAX into ES:DI

	 REGREST <es,di,edx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_ELAP endp			; End FMT_ELAP procedure
	 NPPROC  FMT_ELAPSUB -- Format Time
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format time

On entry:

EDX:EAX  =	 timer ticks
ES:DI	 ==>	 output save area

|

	 REGSAVE <eax,bx,edx>	; Save registers

	 mov	 es:[di+ZMSG_ELAP_SEC_LEN].ELO,'??' ; Assume too large
	 mov	 es:[di+ZMSG_ELAP_MIN_LEN].ELO,'??' ; ...
	 mov	 es:[di+ZMSG_ELAP_HR_LEN].ELO,'??' ; ...

	 cmp	 edx,MAXTIMER.EDQHI ; Izit too large?
	 ja	 short FMT_ELAPSUB_EXIT ; Jump if so
	 jb	 short @F	; Jump if not

	 cmp	 eax,MAXTIMER.EDQLO ; Izit too large?
	 jae	 short FMT_ELAPSUB_EXIT ; Jump if so
@@:
	 shld	 edx,eax,16	; Times 64K so we can ...
	 shl	 eax,16 	; ...
	 div	 CON_CLOCK	; Divide by clock freq to get time in seconds

; Format # elapsed seconds

	 xor	 edx,edx	; Zero high-order dword
	 div	 CON60		; Divide by # seconds in a minute

	 REGSAVE <ax,di>	; Save quotient

	 mov	 ax,dx		; Copy remainder
	 add	 di,ZMSG_ELAP_SEC_LEN[1] ; ES:DI ==> output save area
	 mov	 es:[di-1].LO,'0' ; Ensure leading zero
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 REGREST <di,ax>	; Restore

; Format # elapsed minutes

	 xor	 edx,edx	; Zero high-order dword
	 div	 CON60		; Divide by # minutes in an hour

	 REGSAVE <ax,di>	; Save quotient

	 mov	 ax,dx		; Copy remainder
	 add	 di,ZMSG_ELAP_MIN_LEN[1] ; ES:DI ==> output save area
	 mov	 es:[di-1].LO,'0' ; Ensure leading zero
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 REGREST <di,ax>	; Restore

; Format # elapsed hours

	 push	 di		; Save for a moment

;;;;;;;; mov	 ax,ax		; Copy remainder
	 add	 di,ZMSG_ELAP_HR_LEN[1] ; ES:DI ==> output save area
	 mov	 es:[di-1].LO,' ' ; Ensure leading blank
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 pop	 di		; Restore
FMT_ELAPSUB_EXIT:
	 REGREST <edx,bx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_ELAPSUB endp		; End FMT_ELAPSUB procedure
	 NPPROC  DISP_ELAP -- Display Elapsed Time
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display elapsed time

|

	 push	 ax		; Save register

	 test	 GL2_FLAG,@GL2_ACTIV ; Are we active?
	 jz	 short DISP_ELAP_EXIT ; Jump if not

	 test	 GL3_FLAG,@GL3_RUNHELP ; Are we processing help?
	 jnz	 short DISP_ELAP_EXIT ; Jump if so

	 cmp	 HELP_STATE,@HELP_NONE ; Are we displaying help or topics?
	 jne	 short DISP_ELAP_EXIT ; Jump if so

	 call	 FMT_ELAP	; Calculate and format elapsed time

	 lea	 ax,W_ELAP2	; Pass address of window descriptor (advanced)

	 test	 GL2_FLAG,@GL2_ADV ; Are we advanced?
	 jnz	 short @F	; Jump if so

	 lea	 ax,W_ELAP1	; Pass address of window descriptor (basic)
@@:
	 push	 offset ds:ZMSG_ELAP1 ; Pass address of local buffer
	 push	 ax		; Pass address of window descriptor
	 call	 WPUT_C 	; Output the characters
DISP_ELAP_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ELAP endp			; End DISP_ELAP procedure
	 NPPROC  CLEAR_STATUS -- Clear Screen of Previous Status Data
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the screen of previous status data.

|

	 call	 DISP_STATSCR	; Display the status screen
	 call	 CLEAR_STATLIN	; Clear the status lines

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short @F	; Jump if not

	 push	 offset ds:MSG_SCROLL ; Pass address of local buffer
	 push	 offset ds:W_SCROLL ; Pass address of window descriptor
	 call	 WPUT_CA	; Output the characters and attributes
@@:
	 mov	 W_STATL.SROW,@STATLIN_SROW-1 ; Initialize to starting row
				; as one less to allow for the initial INCPTR
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_STATUS endp		; End CLEAR_STATUS procedure
	 NPPROC  FMT_BLK -- Format and Display Block Info
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display block information.

On entry:

BX	 =	 index into TIMETAB

|

	 REGSAVE <eax,cx,dx,si,di,es> ; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

; Clear the block message

	 lea	 si,MSG_BLKCLR	; DS:SI ==> clear message
	 lea	 di,ZMSG_BLK1	; ES:DI ==> output save area
	 movzx	 cx,ZMSG_BLK.ZMSG_LEN ; CX = # bytes in message
S16  rep movs	 <es:[di].LO,ds:[si].LO> ; Copy to clear

; Format current block #

	 mov	 eax,TIMETAB[bx].TT_PBASE ; Get base physical address
	 lea	 di,ZMSG_BLK3	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 mov	 eax,TIMETAB[bx].TT_LEN ; Get its length in bytes
	 add	 eax,TIMETAB[bx].TT_PBASE ; Plus base physical address
	 lea	 di,ZMSG_BLK4	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 mov	 eax,TIMETAB[bx].TT_LEN ; Get its length in bytes
	 shr	 eax,10-0	; Convert from bytes to 1KB (rounding down)
	 lea	 di,ZMSG_BLK5	; ES:DI ==> output save area
	 call	 BIND2DEC	; Convert EAX to decimal ending at ES:DI

; Display block title

	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 short FMT_BLK_EXIT ; Jump if so

	 push	 offset ds:ZMSG_BLK ; Pass address of local buffer
	 call	 DISP_STATLZ	; Display on the status line with attributes

; If the memory screen is visible (advanced mode), mark the
; current line in the window.  If it's not displayed in the
; window, scroll the memory lines until it is.

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short @F	; Jump if not

; If there is a previous working line, restore its attributes

	 mov	 al,AMEMATTR	; Get active attribute
	 call	 DISP_MEMWRK	; Display memory line working attribute
@@:

; Calculate current memory working index

	 mov	 ax,bx		; Copy index into TIMETAB
	 xor	 dx,dx		; Zero to use as dword
	 mov	 cx,type TT_STR ; Get size of TIMETAB entry in bytes
	 div	 cx		; Divide to get entry # in TIMETAB

	 mov	 MEMWRKIND,ax	; Save for later use

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short FMT_BLK_EXIT ; Jump if not

;;;;;;;; mov	 ax,MEMWRKIND	; Get current working index
	 mov	 cx,MEMIND	; Get current index

	 cmp	 ax,cx		; Izit at or above the current index?
	 jb	 short FMT_BLK_SCROLL ; Jump if not

	 add	 cx,@MEMITEM_LEN-1 ; Get last index on screen

	 sub	 ax,cx		; Izit at or below the last index on screen?
	 jbe	 short FMT_BLK_DISP ; Jump if so (just display the attribute)

	 add	 ax,MEMIND	; Plus current index
FMT_BLK_SCROLL:
	 mov	 MEMIND,ax	; Save as new memory index

	 push	 MEMWRKIND	; Save for a moment (clobbered by DISP_MEMVAL)
	 call	 DISP_MEMVAL	; Display the memory values
	 pop	 MEMWRKIND	; Restore
FMT_BLK_DISP:

; Display special attribute on entry for MEMWRKIND

	 mov	 al,WMEMATTR	; Get working memory line attribute
	 call	 DISP_MEMWRK	; Display memory line working attribute

	 call	 CHECK_RHELP	; Refresh help topic display if needed
FMT_BLK_EXIT:
	 REGREST <es,di,si,dx,cx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_BLK  endp			; End FMT_BLK procedure
	 NPPROC  DISP_MEMWRK -- Display Memory Line Working Attribute
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we're active in advanced mode,
display memory line working attribute.

On entry:

AL	 =	 attribute to use

|

	 REGSAVE <bx>		; Save register

	 test	 GL2_FLAG,@GL2_ACTIV ; Izit active?
	 jz	 short DISP_MEMWRK_EXIT ; Jump if not

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short DISP_MEMWRK_EXIT ; Jump if not

	 cmp	 MEMWRKIND,-1	; Izit valid?
	 je	 short DISP_MEMWRK_EXIT ; Jump if not

	 push	 W_MEMWRK.SROW	; Save starting row #

	 mov	 bx,MEMWRKIND	; Get working index #
	 sub	 bx,MEMIND	; Less the index of the one at the top
	 add	 W_MEMWRK.SROW,bx ; Add to get starting row #

	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_MEMWRK ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

	 pop	 W_MEMWRK.SROW	; Restore
DISP_MEMWRK_EXIT:
	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MEMWRK endp		; End DISP_MEMWRK procedure
	 NPPROC  FMT_DONE -- Format Done Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display "DONE" or "INTERRUPTED" message.

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 push	 ds		; Setup ES for MOVS
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 short FMT_DONE_EXIT ; Jump if so

	 test	 GL2_FLAG,@GL2_CONT ; Izit continuous?
	 jnz	 short FMT_DONE1 ; Jump if so

	 lea	 si,MSG_PTSTCMP ; Get address of local buffer

	 test	 CNT_FLAG,@CNT_HALT ; Did we terminate on request?
	 jz	 short @F	; Jump if not

	 lea	 si,MSG_PTSTINT ; Get address of local buffer
@@:
	 mov	 LAST_PTST,si	; Save as last PTST
FMT_DONE1:
	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced?
	 jnz	 short FMT_DONE_ADV ; Jump if so

	 call	 CALC_PTST	; See if we need to calculate LAST_PTST

	 push	 LAST_PTST	; Pass address of local buffer
	 push	 offset ds:W_PTST ; Pass address of window descriptor
	 call	 WPUT_C 	; Output the characters

	 jmp	 short FMT_DONE_EXIT ; Join common exit code

FMT_DONE_ADV:
	 lea	 si,MSG_DONE	; Get address of local buffer
	 mov	 cx,MSG_DONE_LEN ; Set # cols in message

	 test	 CNT_FLAG,@CNT_HALT ; Did we terminate on request?
	 jz	 short @F	; Jump if not

	 lea	 si,MSG_INTR	; Get address of local buffer
	 mov	 cx,MSG_INTR_LEN ; Set # cols in message
@@:
	 lea	 di,ZMSG_ELAP_DONE ; ES:DI ==> destination

S16  rep movs	 <ZMSG_ELAP_DONE[di],MSG_DONE[si]> ; Copy to ZMSG_ELAP
FMT_DONE_EXIT:
	 call	 CHECK_RHELP	; Refresh help topic display if needed

	 REGREST <es,di,si,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_DONE endp			; End FMT_DONE procedure
	 NPPROC  CALC_PTST -- Calculate LAST_PTST Value
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate LAST_PTST value

|

	 REGSAVE <bx>		; Save register

	 cmp	 LAST_PTST,-1	; Izit invalid?
	 jne	 short CALC_PTST_EXIT ; Jump if not

	 mov	 bx,ADVIND	; Get current index
	 add	 bx,2		; Skip over QUICK and FULL messages if advanced

	 test	 CNT_FLAG,@CNT_BASIC ; Izit BASIC mode?
	 jz	 short @F	; Jump if not

	 mov	 bx,BASIND	; Get BASIC index
@@:
	 shl	 bx,1		; Times two to index table of words
	 mov	 bx,PMSG_PTST[bx] ; Get the message offset

	 mov	 LAST_PTST,bx	; Save as message offset
CALC_PTST_EXIT:
	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_PTST endp			; End CALC_PTST procedure
	 NPPROC  INCPTR -- Increment the Pointer
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Increment the pointer.

|

	 push	 ax		; Save register

	 mov	 ax,W_STATL.SROW ; Get current status row #
	 inc	 ax		; Skip to next row
	 mov	 W_STATL.SROW,ax ; Save as starting row #

	 cmp	 ax,@STATLIN_END ; Check against ending row #
	 jb	 short INCPTR_EXIT ; Jump if it's within range

	 dec	 W_STATL.SROW	 ; Back off as starting row #

; Scroll the status window up one line

	 REGSAVE <ax,cx,dx,si,di,es> ; Save registers

	 push	 ds		; Get DGROUP data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 ax,W_SCROLL.NROW ; Get # rows in scroll window
	 dec	 ax		; Less one to account for scroll
	 mov	 si,W_SCROLL.NCOL ; Get # cols in scroll window
	 mul	 si		; Times # cols to get size
	 shl	 si,1		; Times two to skip over first row

	 mov	 cx,ax		; Copy as # words to scroll
	 lea	 si,MSG_SCROLL[si] ; DS:SI ==> source
	 lea	 di,MSG_SCROLL[ 0] ; ES:DI ==> destin
S16  rep movs	 <MSG_SCROLL[di].ELO,MSG_SCROLL[si].ELO> ; Scroll up one line

; Clear the last line

	 mov	 cx,W_SCROLL.NCOL ; Get # words to clear
	 mov	 ah,STATLATTR	; Get status line attribute
	 mov	 al,' '         ; Get a blank character
     rep stos	 MSG_SCROLL[di].ELO ; Clear the last line

	 REGREST <es,di,si,dx,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

; If we're in advanced mode, display the new screen

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short INCPTR_EXIT ; Jump if not

	 push	 offset ds:MSG_SCROLL ; Pass address of local buffer
	 push	 offset ds:W_SCROLL ; Pass address of window descriptor
	 call	 WPUT_CA	; Output the characters and attributes
INCPTR_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INCPTR	 endp			; End INCPTR procedure
	 NPPROC  ERRLOG -- Save error info for logging
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save error information for later.

On entry:

BX	 =	 index into TIMETAB
ESI	 =	 expected pattern
ES:EDI	 ==>	 error value

On stack:
code	 =	 @ERRLOG_BYTE, @ERRLOG_WORD, @ERRLOG_DWORD, @ERRLOG_NMI

|

ELSTK_STR struc

	 dd	 ?		; Saved EBP
	 dw	 ?		; Caller's near return
ELSTK_CODE dw	 ?		; Error type

ELSTK_STR ends

	 push	 ebp		; Prepare to address stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,edx,edi>	; Save registers

	 mov	 eax,es:[edi]	; Get failing value

	 mov	 edx,edi	; Get failing address
	 sub	 edx,TIMETAB[bx].TT_LBASE ; Less starting linear address
	 add	 edx,TIMETAB[bx].TT_PBASE ; Plus ...	  physical ...

	 mov	 di,ERRDATACNT	; Get previous errors
	 cmp	 di,@ERRLOGMAX	; Have we exceeded the limit?
	 jnb	 short ERRLOG_EXIT ; Jump if so

	 imul	 di,di,size ERRDATA_STR ; ERRDATA[DI] == next available entry

	 or	 di,di		; Is there a previous entry?
	 jz	 short ERRLOG_SALL ; Jump if not

	 sub	 di,size ERRDATA_STR ; Back off to previous entry for comparison

; Check previous entry.  If we're duplicating a previous entry, skip it.
	 cmp	 eax,ERRDATA[di].ERRDATA_ACT ; Is the actual data the same?
	 jne	 short ERRLOG_XDIFF ; Jump if not

	 push	 eax		; Save for a moment
	 mov	 ax,[ebp].ELSTK_CODE ; Get error type code
	 cmp	 ax,ERRDATA[di].ERRDATA_TYP ; Izit the same?
	 pop	 eax		; Restore
	 jne	 short ERRLOG_XDIFF ; Jump if not

	 cmp	 esi,ERRDATA[di].ERRDATA_EXP ; Is expected data the same?
	 jne	 short ERRLOG_XDIFF ; Jump if not

	 cmp	 edx,ERRDATA[di].ERRDATA_ADDR ; Is address the same?
	 je	 short ERRLOG_EXIT ; Jump if so

ERRLOG_XDIFF:
	 add	 di,size ERRDATA_STR ; Skip to new entry
ERRLOG_SALL:
	 mov	 ERRDATA[di].ERRDATA_ACT,eax ; Save actual data

	 mov	 ax,[ebp].ELSTK_CODE ; Get error type code
	 mov	 ERRDATA[di].ERRDATA_TYP,ax ; Save it

	 mov	 ERRDATA[di].ERRDATA_EXP,esi ; Save expected data

	 mov	 ERRDATA[di].ERRDATA_ADDR,edx ; Save physical address

	 inc	 ERRDATACNT	; Count in another entry

ERRLOG_EXIT:
	 REGREST <edi,edx,eax>	; Restore

	 pop	 ebp		; Restore

	 ret	 2		; Remove args and return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ERRLOG endp			; End ERRLOG procedure
	 NPPROC  DISP_ERRB -- Display Error Byte
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display error message with byte value.

On entry:

BX	 =	 index into TIMETAB
ESI	 =	 expected pattern
ES:EDI	 ==>	 error value

|

	 REGSAVE <eax,edi,es>	; Save registers

	 push	 @ERRLOG_BYTE	; Log byte compare error
	 call	 ERRLOG 	; Add to list for error logging

; Format error value

	 mov	 al,es:[edi]	; Get failing value

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 push	 di		; Save for a moment
	 lea	 di,HELP_MEM_ACT ; ES:DI ==> output save area
	 call	 BIN2BYTE	; Convert AL to hex at ES:DI
	 pop	 di		; Restore

	 mov	 HELP_MEM_ACT[2].ELO,'  ' ; Clear trailing space
	 mov	 HELP_MEM_ACT[4].EDD,'    ' ; ...

; Format expected value

	 REGSAVE <ax,di>	; Save for a moment

	 mov	 ax,si		; Copy expected value
	 lea	 di,HELP_MEM_EXP ; ES:DI ==> output save area
	 call	 BIN2BYTE	; Convert AL to hex at ES:DI

	 REGREST <di,ax>	; Restore

	 mov	 HELP_MEM_EXP[2].ELO,'  ' ; Clear trailing space
	 mov	 HELP_MEM_EXP[4].EDD,'    ' ; ...

	 jmp	 short DISP_ERRCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ERRB endp			; End DISP_ERRB procedure
	 NPPROC  DISP_ERRW -- Display Error Word
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display error message with word value.

On entry:

BX	 =	 index into TIMETAB
ESI	 =	 expected pattern
ES:EDI	 ==>	 error value

|

	 REGSAVE <eax,edi,es>	; Save registers

	 push	 @ERRLOG_WORD	; Log word compare error
	 call	 ERRLOG 	; Add to list for error logging

; Format error value

	 mov	 ax,es:[edi]	; Get failing value

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 push	 di		; Save for a moment
	 lea	 di,HELP_MEM_ACT ; ES:DI ==> output save area
	 call	 BIN2WORD	; Convert AX to hex at ES:DI
	 pop	 di		; Restore

	 mov	 HELP_MEM_ACT[4].EDD,'    ' ; Clear trailing space

; Format expected value

	 REGSAVE <ax,di>	; Save for a moment

	 mov	 ax,si		; Copy expected value
	 lea	 di,HELP_MEM_EXP ; ES:DI ==> output save area
	 call	 BIN2WORD	; Convert AX to hex at ES:DI

	 REGREST <di,ax>	; Restore

	 mov	 HELP_MEM_EXP[4].EDD,'    ' ; Clear trailing space

	 jmp	 short DISP_ERRCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ERRW endp			; End DISP_ERRW procedure
	 NPPROC  DISP_ERRD -- Display Error Dword
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display error message with dword value.

On entry:

BX	 =	 index into TIMETAB
ESI	 =	 expected pattern
ES:EDI	 ==>	 error value

|

	 REGSAVE <eax,edi,es>	; Save registers

	 push	 @ERRLOG_DWORD	; Log dword compare error
	 call	 ERRLOG 	; Add to list for error logging

; Format error value

	 mov	 eax,es:[edi]	; Get failing value

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 push	 di		; Save for a moment
	 lea	 di,HELP_MEM_ACT ; ES:DI ==> output save area
	 call	 BIN2DWORD	; Convert EAX to hex at ES:DI
	 pop	 di		; Restore

; Format expected value

	 REGSAVE <eax,di>	; Save for a moment

	 mov	 eax,esi	; Copy expected value
	 lea	 di,HELP_MEM_EXP ; ES:DI ==> output save area
	 call	 BIN2DWORD	; Convert EAX to hex at ES:DI

	 REGREST <di,eax>	; Restore

; Format error address

DISP_ERRCOM:
	 inc	 MEMERRCNT	; Count in another error

	 mov	 eax,edi	; Get failing address
	 sub	 eax,TIMETAB[bx].TT_LBASE ; Less starting linear address
	 add	 eax,TIMETAB[bx].TT_PBASE ; Plus ...	  physical ...

	 lea	 di,HELP_MEM_ADDR ; ES:DI ==> output save area
	 call	 BIN2DWORD	; Convert EAX to hex at ES:DI

; Display error message via help screen

	 or	 GL2_FLAG,@GL2_MEMERR ; Mark as memory error

	 mov	 ax,@HLPIND_MEM ; Get help index for memory error
	 call	 DISP_HLPERR	; Display help on error, AX = index

	 and	 GL2_FLAG,not @GL2_MEMERR ; Mark as no longer memory error

	 REGREST <es,edi,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ERRD endp			; End DISP_ERRD procedure
	 NPPROC  DISP_NMIERR -- Display NMI Error
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display NMI error message.

On entry:

BX	 =	 index into TIMETAB
ES:EDI	 ==>	 error value

|

	 REGSAVE <eax,edi,es>	; Save registers

	 push	 @ERRLOG_NMI	; Log NMI error
	 call	 ERRLOG 	; Add to list for error logging

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 inc	 NMIERRCNT	; Count in another error

; Format error address

	 mov	 HELP_NMI_ADDR.EDQLO,'????' ; Assume spurious
	 mov	 HELP_NMI_ADDR.EDQHI,'????' ; ...

	 mov	 eax,edi	; Get failing address

	 cmp	 eax,-1 	; Izit a spurious address (from INT02_COM)?
	 je	 short @F	; Jump if so

	 sub	 eax,TIMETAB[bx].TT_LBASE ; Less starting linear address
	 add	 eax,TIMETAB[bx].TT_PBASE ; Plus ...	  physical ...

	 lea	 di,HELP_NMI_ADDR ; ES:DI ==> output save area
	 call	 BIN2DWORD	; Convert EAX to hex at ES:DI
@@:

; Display error message via help screen

	 or	 GL2_FLAG,@GL2_NMIERR ; Mark as parity error

	 mov	 ax,@HLPIND_NMI ; Mark as special help index
	 call	 DISP_HLPERR	; Display help on error, AX = index

	 and	 GL2_FLAG,not @GL2_NMIERR ; Mark as no longer parity error

	 call	 ENABLE_NMI	; Enable NMI, clear the parity latches

	 REGREST <es,edi,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_NMIERR endp		; End DISP_NMIERR procedure
	 NPPROC  DISP_ASKSCR -- Display Ask Screen
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the ask screen background

|

	 push	 ax		; Save for a moment

	 test	 GL2_FLAG,@GL2_ADV ; Izit the advanced screen?
	 jnz	 short DISP_ASKSCR2 ; Jump if so

; Display the basic ask screen

	 mov	 al,ASKATTR	; Get ask attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_ASKSCR1 ; Pass address of local buffer
	 push	 offset ds:W_ASKSCR1 ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display a shadow below and to the right of the ask screen

	 push	 offset ds:W_ASKSCR1 ; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

; Display each item with a shadow

	 push	 BASIND 	; Save the current value

	 mov	 BASIND,0	; Display for Quick
	 call	 DISP_ASKBAS	; Display basic ask item

	 mov	 BASIND,1	; Display for Full
	 call	 DISP_ASKBAS	; Display basic ask item

	 pop	 BASIND 	; Restore

	 jmp	 short DISP_ASKSCR_EXIT ; Join common exit code

DISP_ASKSCR2:

; Display the advanced ask screen

	 mov	 al,ASKATTR	; Get ask attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_ASKSCR2 ; Pass address of local buffer
	 push	 offset ds:W_ASKSCR2 ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display a shadow below and to the right of the ask screen

	 push	 offset ds:W_ASKSCR2 ; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow
DISP_ASKSCR_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ASKSCR endp		; End DISP_ASKSCR procedure
	 NPPROC  DISP_ASKBAS -- Display Ask Basic Item
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display ask basic item

|

	 REGSAVE <ax,bx,si>	; Save registers

	 mov	 bx,@ITEM_ASKBAS * (type BLK_STR) ; Get index into BLK_STRS
	 mov	 al,BLK_STRS[bx].BLK_AASK ; Get active ask attribute
	 mov	 si,BLK_STRS[bx].BLK_PPBTXT ; Get ptr to ptr to background text
	 call	 SET_BARATTR	; Set bar attribute

; Display a shadow below and to the right of the item

	 imul	 ax,BLK_STRS[bx].BLK_IND,type W_STR ; Get current index
	 add	 ax,BLK_STRS[bx].BLK_PARR ; Plus offset of array of W_STRs

	 push	 ax		; Pass offset of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

	 REGREST <si,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ASKBAS endp		; End DISP_ASKBAS procedure
	 NPPROC  DISP_STATSCR -- Display Status Screen
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the status screen background

|

	 push	 ax		; Save for a moment

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short DISP_STATSCR_EXIT ; Jump if not

; Clear the status screen

	 mov	 al,STATATTR	; Get status screen attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_STATSCR ; Pass address of local buffer
	 push	 offset ds:W_STATSCR ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display the status header attributes

	 mov	 al,STATHATTR	; Get status header attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_STATH1 ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

;;;;;;;  mov	 al,STATHATTR	; Get status header attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_STATH2 ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

;;;;;;;  mov	 al,STATHATTR	; Get status header attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_STATH3 ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

; Set attributes inside the window

	 REGSAVE <W_STATL.SROW,W_STATL.NROW> ; Save window values

	 mov	 W_STATL.SROW,@STATLIN_SROW ; Initialize to starting row
	 mov	 W_STATL.NROW,@STATLIN_NROW ; Get # lines in status screen

	 mov	 al,STATLATTR	; Get status line attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_STATL ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

	 REGREST <W_STATL.NROW,W_STATL.SROW> ; Restore

; Display a shadow over the bottom line and right edge of the window

	 push	 offset ds:W_STATSCR ; Pass address of window descriptor
	 call	 WPUT_SHD2	; Display a type 2 shadow
DISP_STATSCR_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STATSCR endp		; End DISP_STATSCR procedure
	 NPPROC  ZAPREST -- Restore Zapped Repeat Prefix
	 assume  ds:DGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore zapped repeat instruction

This technique works because the repeat prefix is always
the first byte in the instruction and it is always @OPCOD_REP
never @OPCOD_REPNE.

Note we must not alter the flags as we might be called
after a REPx SCAS.

|

	 pushf			; Save flags

	 REGSAVE <ebx>		; Save register

	 xor	 ebx,ebx	; Zero to clear semaphore
	 xchg	 bx,ZAPOFF	; Get offset of zapped repeat prefix

	 and	 bx,bx		; Izit valid?
	 jz	 short ZAPREST_EXIT ; Jump if not

	 add	 ebx,LaCODE	; Add in the linear offset of PGROUP
	 mov	 AGROUP:[ebx].LO,@OPCOD_REP ; Restore the repeat prefix
ZAPREST_EXIT:
	 REGREST <ebx>		; Restore

	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ZAPREST  endp			; End ZAPREST procedure
	 NPPROC  CLEAR_CONT -- Mark As No Longer Continuous
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark as no longer continuous.

|

	 btr	 GL2_FLAG,$GL2_CONT ; No longer continuous
	 jnc	 short @F	; Jump if not previously

	 mov	 TOTOPERS.EDQLO,0 ; Clear total opers for progress screen
	 mov	 TOTOPERS.EDQHI,0 ; ...

	 mov	 NUMOPERS.EDQLO,0 ; Clear # opers ...
	 mov	 NUMOPERS.EDQHI,0 ; ...

	mov	MSG_ASK_CONT[-3].EDD,'    ' ; Clear counter
	mov	MSG_ASK_CONT[ 1],' ' ; ...
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_CONT endp 		; End CLEAR_CONT procedure
	 NPPROC  HMS2SECDAY -- Convert HH:MM:SS to day seconds
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:
CH	=	hours (0-23)
CL	=	minutes (0-59)
DH	=	seconds (0-59)

On exit:
EAX	=	seconds since 00:00:00 (midnight)

|

	 REGSAVE <edx>		; Save

	 movzx	 eax,ch 	; Get hours
	 imul	 ax,12		; Convert hours to minutes
	 add	 al,cl		; Add minutes
	 adc	 ah,0		; ... (note total won't exceed 1440)
	 imul	 eax,60 	; EAX = total seconds

	 movzx	 edx,dh 	; Extend to dword, unsigned
	 add	 eax,edx	; Add to total

	 REGREST <edx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HMS2SECDAY endp 		; End HMS2SECDAY procedure
	 NPPROC  DISP_BUTTON -- Display a button
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display specified button as active or inactive.

On entry:
AX:15-1  Index of button (0, 1, 2)
AX:0	 =1 to display button as default
	 =0 to display button as normal

On exit:
AX	Destroyed

|

	 REGSAVE <bx,si>	; Save
	 REGSAVE <ACMDIND>	; Save previous value

	 imul	 bx,ASKBLK,type BLK_STR ; Get index into BLK_STRS

	 shr	 ax,1		; Get index, save active flag in CF
	 mov	 ACMDIND,ax	; Save in structure

	 mov	 al,BLK_STRS[bx].BLK_AASK ; Get active ask attribute
	 mov	 si,BLK_STRS[bx].BLK_PPATXT ; Get ptr to ptr to active text

	 jc	 short @F	; Jump if we're active

	 mov	 si,BLK_STRS[bx].BLK_PPBTXT ; Get ptr to ptr to background text
@@:
	 call	 SET_BARATTR	; Set bar attribute

; Display a shadow below and to the right of the item

	 imul	 ax,BLK_STRS[bx].BLK_IND,type W_STR ; Get current index
	 add	 ax,BLK_STRS[bx].BLK_PARR ; Plus offset of array of W_STRs

	 push	 ax		; Pass offset of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

	 REGREST <ACMDIND>	; Restore
	 REGREST <si,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_BUTTON endp		; End DISP_BUTTON procedure
	 NPPROC  GET_ASKRESP -- Get response to ASK command dialog
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display buttons for ASK command dialog and get response
using specified default response and timeout.

On exit:
AL	 Response in uppercase

|

	 REGSAVE <bx,ecx,edx,di,es> ; Save
	 REGSAVE <ASKBLK>	; Save variables

	 push	 seg DGROUP	; Get DGROUP segment
	 pop	 es		; Address for BIN2DEC
	 assume  es:DGROUP	; Tell the assembler

	 cld			; Set forward direction for SCASW

	 mov	 ASKBLK,@ITEM_ASKCMD ; Displaying buttons for ASK box

	 sub	 bx,bx		; Timeout is in effect

	 mov	 LASTDIFF,-1	; Initialize last count displayed

	 DOSCALL @GETDTE	; CX=years-1980, DH=month, DL=day
	 call	 DATE2EPOCH	; EAX = days since 1/1/1980
	 mov	 EPOCHTARG,eax	; Save for comparison

	 DOSCALL @GETTME	; CH=hours, CL=minutes, DH=seconds, DL=sec/100
	 call	 HMS2SECDAY	; EAX = seconds since midnight
	 movzx	 edx,ASK_TIMEOUT ; Get timeout in seconds

	 or	 dx,dx		; If timeout is 0, we'll never time out
	 jnz	 short @F	; Jump if not

	 inc	 bx		; No timeout
	 jmp	 short GAR_BACKDISP ; Display background screen

@@:
	 add	 eax,edx	; Get target time
	 cdq			; EDX:EAX = target time in seconds
	 mov	 ecx,24*60*60	; Seconds in a day
	 div	 ecx		; EAX = days to add
	 add	 EPOCHTARG,eax	; Add to target date
	 mov	 SECTARG,edx	; Save remainder as target time

GAR_BACKDISP:
; Subdue the surrounding screen

	 mov	 ah,BACKATTR	; Get shade type 1 attribute
	 mov	 al,' '         ; Get a blank character
	 push	 ax		; Pass character and attribute to smear
	 push	 offset DGROUP:W_ASKCMDBACK ; Pass address of window descriptor
	 call	 WPUT_SCA	; Smear character and attribute

GAR_REDISP:
; Display the basic ask screen

	 mov	 al,ASKATTR	; Get ask attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset DGROUP:MSG_ASKCMD ; Pass address of local buffer
	 push	 offset DGROUP:W_ASKCMD ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display a shadow below and to the right of the ask screen

	 push	 offset DGROUP:W_ASKCMD ; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

	 mov	 ax,0*2+0	; "Yes" button
	 call	 DISP_BUTTON	; Display button with shadowing

	 mov	 ax,1*2+0	; "No" button
	 call	 DISP_BUTTON	; Display button with shadowing

	 mov	 ax,2*2+0	; "Postpone" button
	 call	 DISP_BUTTON	; Display button with shadowing

	 jmp	 GAR_SETFOCUS	; Force redisplay of active button

GAR_NEXT:
	 call	 CHKNDKEY	; Return ZF=1 if key is ready
				; Return with AX = keystroke, ZF significant
	 jz	 short GAR_TO	; Jump if nothing

	 call	 GETKEY 	; Return scan code in AX
	 or	 bx,bx		; Are we still timing out?
	 jnz	 short GAR_PROCKEY ; Jump if not

	 inc	 bx		; Turn off timeout

; Clear default message

	 push	 ax		; Save scan code

	 mov	 ah,ASKATTR	; Get ask attribute
	 mov	 al,' '         ; Get a blank character
	 push	 ax		; Pass attribute to smear
	 push	 offset DGROUP:W_ASKCMDREM ; Pass address of window descriptor
	 call	 WPUT_SCA	; Smear character/attribute

	 pop	 ax		; Restore

	 jmp	 short GAR_PROCKEY ; Process it

GAR_TO:
; Check to see if we've timed out
	 or	 bx,bx		; Are we timing out?
	 jnz	 short GAR_NEXT ; Go around again if not

	 DOSCALL @GETDTE	; CX=year-1980, DH=month, DL=day
	 call	 DATE2EPOCH	; EAX = days since 1/1/1980
	 cmp	 eax,EPOCHTARG	; Have we reached the target date?
	 jb	 short GAR_NEXT ; Go around again if not

	 ja	 near ptr GAR_USEDEFAULT ; Did we miss the wedding?

	 DOSCALL @GETTME	; CH=hours, CL=minutes, DH=seconds, DL=sec/100
	 call	 HMS2SECDAY	; EAX = seconds since midnight

	 sub	 eax,SECTARG	; Did we hit our target yet?
	 jnc	 near ptr GAR_USEDEFAULT ; Use default if so

	 neg	 eax		; Get # of seconds remaining
	 cmp	 eax,LASTDIFF	; Izit changed?
	 je	 short GAR_NEXT ; Jump if not

	 mov	 LASTDIFF,eax	; Save for comparison

; Format seconds remaining

	 lea	 di,FMT_ASKCMDREM ; End of "Seconds remaining:       _"
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI
	 mov	 DGROUP:[di].LO,' ' ; We're counting down, so clear high digit

; Update dialog box
	 mov	 al,ASKATTR	; Get ask attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset DGROUP:MSG_ASKCMDREM ; Pass address of local buffer
	 push	 offset DGROUP:W_ASKCMDREM ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 jmp	 short GAR_NEXT ; Go around again

GAR_PROCKEY:
	 mov	 cx,ax		; Save complete scan code

	 call	 UPPERCASE	; Convert AL to uppercase

	 cmp	 al,@NATL_YESCHAR ; Izit a valid response?
	 je	 short GAR_EXIT ; Jump if so

	 cmp	 al,@NATL_NOCHAR ; Izit other valid response?
	 je	 short GAR_EXIT ; Jump if so

	 cmp	 al,@NATL_POSTPONE ; Izit number 3?
	 je	 short GAR_EXIT ; Jump if so

	 mov	 di,ACMDIND	; Get current button's index
	 cmp	 al,CR		; Did we press ENTER?
	 mov	 al,ASKCMDBTN[di] ; Get return value for this one
	 je	 short GAR_EXIT ; Jump if so

	 mov	 ax,cx		; Get scan code
	 lea	 di,ASKCVAL	; Address start of table
	 mov	 cx,NASKCVAL	; Number of scan codes
   repne scas	 ASKCVAL[di]	; Search for AX
	 jne	 near ptr GAR_NEXT ; Jump if not found

	 sub	 di,(type ASKCVAL) + offset DGROUP:ASKCVAL ; Convert to origin-0

	 jmp	 ASKCACT[di]	; Take appropriate action

ASKC_UP:
ASKC_LEFT:
ASKC_STAB:
	 mov	 di,ACMDIND	; Get current index
	 mov	 al,ASKCMDUP[di] ; Get up transition
	 jmp	 short GAR_CHFOCUS ; Join common code

ASKC_DN:
ASKC_RIGHT:
ASKC_TAB:
	 mov	 di,ACMDIND	; Get current index
	 mov	 al,ASKCMDDN[di] ; Get down transition

; AL contains new ACMDIND value.  Lose focus on the old one, set it on the new.
GAR_CHFOCUS:
	 sub	 ah,ah		; Clear high byte
	 xchg	 ax,ACMDIND	; Get old index

	 shl	 ax,1		; Display as non-default
	 call	 DISP_BUTTON	; Display button with shadowing

GAR_SETFOCUS:
	 mov	 ax,ACMDIND	; Get new index
	 stc			; Prepare to set bit 0
	 rcl	 ax,1		; Display as default
	 call	 DISP_BUTTON	; Display button with shadowing

	 jmp	 GAR_NEXT	; Go around again

; Display simple help screen, and wait until hell freezes or they hit Esc...
ASKC_HELP:
	 mov	 al,HLPATTR	; Get help attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset DGROUP:MSG_ACHLP ; Pass address of local buffer
	 push	 offset DGROUP:W_ACHLP ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

;;;;;;;  push	 offset DGROUP:W_ACHLP ; Pass address of window descriptor
;;;;;;;  call	 WPUT_SHD1	; Display a type 1 shadow
;;;;;;;
@@:
	 call	 GETKEY 	; Wait for Esc
	 cmp	 ax,@KEY_ESC	; Izit our boy?
	 jne	 short @B	; Go around again if not

	 call	 VIDB_LINEAR	; Restore VIDBASE_VEC to 32-bit linear address
	 call	 REST_SCR	; Restore underlying screen
	 call	 VIDB_SEGOFF	; Convert VIDBASE_VEC from linear to seg:off

	 jmp	 GAR_BACKDISP	; Redraw the screen

ASKC_ESC:
	 mov	 al,@NATL_NOCHAR ; No way, Jose...
	 jmp	 short GAR_EXIT ; Join common exit

GAR_USEDEFAULT:
	 mov	 al,ASK_DEFAULT ; Get default response (already uppercase)

GAR_EXIT:
	 REGREST <ASKBLK>	; Restore variables
	 REGREST <es,di,edx,ecx,bx> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_ASKRESP endp		; End GET_ASKRESP procedure
	 NPPROC  WRITESTR -- Write ASCIIZ string to file
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Write ASCIIZ string at DS:DX to file BX.

On entry:
DS:DX	==>	ASCIIZ string to write
BX	=	File handle

On exit:
If CF=0,
AX	=	Bytes actually written

Else
AX	=	Error code

|

	 REGSAVE <cx,di>	; Save

	 cld			; Set forward direction for string ops
	 mov	 di,dx		; Get starting offset in DGROUP

	 sub	 al,al		; What to look for
	 mov	 cx,-1		; How many bytes to search
   repne scas	 DGROUP:[di].LO ; Find end of string
	 mov	 cx,di		; ES:DI ==> byte after 0
	 sub	 cx,dx		; Length plus 1
	 dec	 cx		; Bytes to write to file

	 DOSCALL @WRITF2	; Write CX bytes from DS:DX to file BX
				; Return with CF significant and AX=error or cnt

	 REGREST <di,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRITESTR endp			; End WRITESTR procedure

ifdef @RAMEXAM

	 NPPROC  DEFAULT_LOG -- Set up default QMTLOGPATH
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If LOG is specified without a filename, or if LOG is forced due
to an error condition, we need to construct a default log file
name from the saved path stem and the default name "RAMEXAM.LOG."

|

	 REGSAVE <ax,cx,si,di,ds> ; Save

	 push	 es		; Get DGROUP
	 pop	 ds		; Address it for LODS
	 assume  ds:DGROUP	; Tell the assembler

	 cld			; String ops forwardly

	 lea	 di,QMTLOGPATH	; Start of path
	 lea	 si,QMTDIR	; Default directory
	 mov	 cx,QMT_STEM	; Bytes to move
S16  rep movs	 <QMTLOGPATH[di],QMTDIR[si]> ; Copy CX bytes from DS:SI to ES:DI

	 lea	 si,QMTLOG	; Default "QMTLOG.TXT",0
	 mov	 cx,127 	; Maximum size less trailing 0
	 sub	 cx,QMT_STEM	; Less drive:\dir already copied
@@:
	 lods	 QMTLOG[si]	; Take a byte
S16	 stos	 QMTLOGPATH[di] ; Add to path
	 or	 al,al		; Did we reach the end?
	 loopnz  @B		; Go around again if not

	 sub	 al,al		; Create terminator in case we're truncating
S16	 stos	 QMTLOGPATH[di] ; Terminate path

	 REGREST <ds,di,si,cx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEFAULT_LOG endp		; End DEFAULT_LOG procedure
	 NPPROC  OPEN_LOG -- Write first part of log file entry
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Open log file (truncating it if ,o was specified) and write first
part of log file entry (first two lines ommitted if at offset 0):

<CR,LF>
********************************************************************<CR,LF>
<CR,LF>
QMT was executed on {mm/dd/yy} at {hh:mm xx} with the following<CR,LF>
options: {ASKCMDOPT}<CR,LF>
<CR,LF>

|

	 pusha			; Save

	 test	 CMD_FLAG,@CMD_LOG ; Are we writing to a log file?
	 jz	 near ptr OLOG_EXIT ; Jump if not

; If ,o was specified, truncate file.
	 test	 CMD_FLAG,@CMD_LOGDEL ; Should we overwrite existing file?
	 jnz	 short OLOG_TRUNC ; Jump if so

; Attempt to open file read-write and seek to end

	 mov	 ax,@OPENF2*256 + 02h ; Read-write, sharing compatibility
	 lea	 dx,QMTLOGPATH	; DS:DX ==> ASCIIZ filename to open
	 DOSCALL		; AX = file handle
	 jnc	 short @F	; Jump if we succeeded

	 cmp	 ax,0002h	; Izit "File not found?"
	 je	 short OLOG_TRUNC ; Try to create file if so

	 jmp	 OLOG_EXIT	; Join common exit code

@@:
; Seek to end of file.	If we're not writing to an empty file,
; write the leading separator first.

	 mov	 bx,ax		; Copy to handle register

	 mov	 ax,@MOVFP2*256 + 02h ; Seek relative to end of file
	 sub	 cx,cx		; Clear high word of offset
	 mov	 dx,cx		; Clear low word ...
	 DOSCALL		; DX:AX == length of file
	 jc	 short	OLOG_EXITCLOSE ; Jump if seek failed (???)

	 or	 ax,dx		; Is the file empty?
	 jz	 short OLOG_OPEN ; Jump if so (no leading separator needed)

; Write our leading separator

	 lea	 dx,LOGA	; DS:DX ==> ASCIIZ string to write
	 call	 WRITESTR	; Write ASCIIZ string at DS:DX to file BX
	 jmp	 short OLOG_OPEN ; Join common code

; Truncate file, overwriting previous contents
OLOG_TRUNC:
	 mov	 cx,0		; File attributes (normal)
	 DOSCALL @CREAF2,QMTLOGPATH ; AX = file handle
	 jc	 short OLOG_EXIT ; Jump if we failed (quietly ignore error)

	 mov	 bx,ax		; Copy to handle register

; BX contains handle for open file.  Write text to it.
OLOG_OPEN:
	 lea	 dx,LOGB	; "QMT ... on "
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

	 REGSAVE <bx>		; Save file handle

	 DOSCALL @GETDTE	; DH=month, DL=day, CX=year
	 mov	 bx,2		; Digits from year to display
	 sub	 cx,1900	; Convert to year-1900
	 lea	 di,LOGDATE	; Space for formatted date
	 call	 FMT_DMY	; Format as DD/MM/YY
	 sub	 al,al		; ES:DI ==> space for terminator
S16	 stos	 es:[di].LO	; Terminate the string

	 REGREST <bx>		; Restore

	 lea	 dx,LOGDATE	; "xx/xx/xx"
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

	 lea	 dx,LOGC	; " at "
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

	 DOSCALL @GETTME	; CH=hours (origin:0), CL=minutes, DH=seconds
	 lea	 di,LOGTIME	; Space for formatted time
	 call	 FMT_HM 	; Format as HH:MM AM/PM
	 sub	 al,al		; ES:DI ==> space for terminator
S16	 stos	 es:[di].LO	; Terminate the string

	 lea	 dx,LOGTIME	; "hh:mm PM"
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

	 lea	 dx,LOGD	; " with ...<CR,LF>options: "
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

	 lea	 dx,SAV_ASKCMDOPT ; Options saved from command line
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

OLOG_EXITCLOSE:
	 DOSCALL @CLOSF2	; Close file handle in BX
;;;;;;;  jc	 ???		; Ignore error

; Because we're about to enter protected mode, possibly by hand from
; real mode, let's make sure SMARTDRV doesn't try to do anything in
; the background while we're diddling A20...

	 DOSCALL @DRESET	; Force SMARTDRV and buffers to flush
OLOG_EXIT:
	 popa			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OPEN_LOG endp			; End OPEN_LOG procedure
	 NPPROC  APPEND_LOG -- Write final part of log file entry
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Open log file and write results in final part of log file entry:

The following memory ranges were tested:<CR,LF>
<CR,LF>
    xxxK -     xxxK (xxxxxxxx-xxxxxxxx)    xxxK<CR,LF>
 xxxxxxK -  xxxxxxK (xxxxxxxx-xxxxxxxx) xxxxxxK<CR,LF>
<CR,LF>
NO ERRORS WERE DETECTED.<CR,LF>

|

	 pushf			; Save caller's flags
	 pusha			; Save

	 test	 CMD_FLAG,@CMD_LOG ; Are we writing to a log file?
	 jnz	 short @F	; Jump if so

; If errors occurred, force logging.
	 mov	 ax,MEMERRCNT	; Get # memory errors
	 add	 ax,NMIERRCNT	; Add # NMI errors
	 jz	 near ptr ALOG_EXIT ; Jump if no errors

	 call	 DEFAULT_LOG	; Set up default log filename

	 or	 CMD_FLAG,@CMD_LOG ; Turn on LOG option with default
	 call	 OPEN_LOG	; Write first part of LOG file

@@:
; Attempt to open file read-write and seek to end

	 mov	 ax,@OPENF2*256 + 02h ; Read-write, sharing compatibility
	 lea	 dx,QMTLOGPATH	; DS:DX ==> ASCIIZ filename to open
	 DOSCALL		; AX = file handle
	 jc	 near ptr ALOG_EXIT ; Jump if we failed

; Seek to end of file.

	 mov	 bx,ax		; Copy to handle register

	 mov	 ax,@MOVFP2*256 + 02h ; Seek relative to end of file
	 sub	 cx,cx		; Clear high word of offset
	 mov	 dx,cx		; Clear low word ...
	 DOSCALL		; DX:AX == length of file
	 jc	 near ptr ALOG_EXITCLOSE ; Jump if seek failed (???)

	 lea	 dx,LOGE	; "The following..."
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

	 mov	 cx,TIMECNT	; Get number of ranges to display
	 sub	 si,si		; Address first entry in TIMETAB
ALOG_NEXTMEM:
	 test	 TIMETAB[si].TT_FLAG,@TT_UNALL ; Izit allocated?
	 jnz	 short ALOG_LOOPMEM ; Jump if not

	 REGSAVE <cx>		; Save outer loop counter

; Clear the right-justified fields
	 mov	 al,' '         ; Blank filler
	 lea	 di,LOGF_K1[-5] ; Start of field
	 mov	 cx,5		; Characters to fill
     rep stos	 LOGF_K1[di]	; Clear it

	 lea	 di,LOGF_K2[-5] ; Start of field
	 mov	 cx,5		; Characters to fill
     rep stos	 LOGF_K2[di]	; Clear it

	 lea	 di,LOGF_K3[-5] ; Start of field
	 mov	 cx,5		; Characters to fill
     rep stos	 LOGF_K3[di]	; Clear it

	 REGREST <cx>		; Restore outer loop counter

; Format physical base address

	 mov	 eax,TIMETAB[si].TT_PBASE ; EAX = physical address
	 lea	 di,LOGF_H1	; Destination for hex value
	 call	 BIN2DWORD	; Format EAX in hex at ES:DI

	 shr	 eax,10-0	; Convert bytes to K, rounding down
	 lea	 di,LOGF_K1	; Right end of destination for decimal value
	call	BIND2DEC	; Format EAX in decimal ending at ES:DI

; Format ending address

	 mov	 eax,TIMETAB[si].TT_PBASE ; Get starting physical address
	 add	 eax,TIMETAB[si].TT_LEN ; Skip to end
	 lea	 di,LOGF_H2	; Destination for hex value
	 call	 BIN2DWORD	; Format EAX in hex at ES:DI

	 add	 eax,1024/2	; Round up halfway
	 shr	 eax,10-0	; Convert bytes to K
	 lea	 di,LOGF_K2	; Right end of destination for decimal value
	call	BIND2DEC	; Format EAX in decimal ending at ES:DI

	 mov	 eax,TIMETAB[si].TT_LEN ; Get length of block
	 add	 eax,1024/2	; Round up halfway
	 shr	 eax,10-0	; Convert bytes to K
	 lea	 di,LOGF_K3	; Right end of destination for decimal value
	call	BIND2DEC	; Format EAX in decimal ending at ES:DI

; Display the formatted data

	 lea	 dx,LOGF	; Formatted range data
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

ALOG_LOOPMEM:
	 add	 si,size TT_STR ; Skip to next entry

;;;;;;;  loop	 ALOG_NEXTMEM	; Go around again
	 dec	 cx		; Adjust loop counter
	 jnz	 near ptr ALOG_NEXTMEM ; Go around again if not finished

	 lea	 dx,LOGG	; CR,LF
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

; Format any errors we've saved

	 mov	 cx,ERRDATACNT	; Get total errors
	 or	 cx,cx		; Are there any?
	 jz	 near ptr ALOG_NOERRORS ; Jump if none

; Format lines saved in ERRDATA
	 sub	 si,si		; Index start of error list
ALOG_NEXTERR:
	 mov	 eax,ERRDATA[si].ERRDATA_ADDR ; Get error address
	 lea	 di,MSG_ADDR	; ES:DI ==> output save area
	 call	 BIN2DWORD	; Convert EAX to hex at ES:DI

	 mov	 ax,ERRDATA[si].ERRDATA_TYP ; Get type of error
	 imul	 di,ax,size LERRFMT_STR ; PLERR[di] ==> LERRFMT_STR

	 mov	 dx,PLERR[di].LERRFMT_PTXT ; DS:DX ==> type of error text
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

	 lea	 dx,MSG_ADDR	; Address of error in hex
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

	 lea	 dx,MSG_EXP3	; End of line
	 cmp	 di,@ERRLOG_NMI * (size LERRFMT_STR) ; Izit a parity error?
	 jnb	 short ALOG_NMIERR ; Jump if so

; Format expected and actual bytes
	 REGSAVE <bx,di>	; Save

	 lea	 dx,MSG_EXP	; "; expected "
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

	 mov	 bx,di		; Save PLERR[] index

	 lea	 di,MSG_EXP1	; Expected value in hex (byte)
	 sub	 di,PLERR[bx].LERRFMT_OFF ; ES:DI ==> start of hex value
	 mov	 dx,di		; Save for later
	 mov	 eax,ERRDATA[si].ERRDATA_EXP ; Expected value
	 call	 PLERR[bx].LERRFMT_PFN ; Format EAX as required

	 lea	 di,MSG_EXP2	; Actual value in hex (byte)
	 sub	 di,PLERR[bx].LERRFMT_OFF ; ES:DI ==> start of hex value
	 mov	 eax,ERRDATA[si].ERRDATA_ACT ; Actual value
	 call	 PLERR[bx].LERRFMT_PFN ; Format EAX as required

	 REGREST <di,bx>	; Restore

	 call	 WRITESTR	; DS:DX ==> "xxxx, got "

	 lea	 dx,MSG_EXP2	; Actual value in hex (byte)
	 sub	 dx,PLERR[di].LERRFMT_OFF ; DS:DX ==> "xxxx.",CR,LF
ALOG_NMIERR:
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

	 add	 si,size ERRDATA_STR ; Skip to next

	 loop	 ALOG_NEXTERR	; Go around again

; Format error summary
	 mov	 ax,MEMERRCNT	; Get # memory errors
	 or	 ax,ax		; Are there any?
	 jz	 short @F	; Jump if none

	 lea	 di,LOG_MEMERR1 ; ES:DI ==> output save area
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 lea	 dx,LOG_MEMERR	; Memory error message
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

@@:
	 mov	 ax,NMIERRCNT	; Get # parity errors
	 or	 ax,ax		; Are there any here?
	 jz	 short @F	; Jump if not

	 lea	 di,LOG_NMIERR1 ; ES:DI ==> output save area
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 lea	 dx,LOG_NMIERR	; Memory error message
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

@@:
	 jmp	 short ALOG_EXITCLOSE ; Join common exit

ALOG_NOERRORS:
; If user pressed @KEY_HALT to stop the test, say so.
	 lea	 dx,LOG_NOERR	; "No errors..."
	 test	 CNT_FLAG,@CNT_HALT ; Did they hit the brakes?
	 jz	 short @F	; Jump if not

	 lea	 dx,LOG_HALT	; "Cancelled by user..."
@@:
	 call	 WRITESTR	; Write ASCIIZ at DS:DX to file BX

ALOG_EXITCLOSE:
	 DOSCALL @CLOSF2	; Close file BX
;;;;;;;  jc	 ???		; Ignore error

ALOG_EXIT:
	 popa			; Restore
	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

APPEND_LOG endp 		; End APPEND_LOG procedure

endif ; ifdef @RAMEXAM

CODE	 ends			; End CODE segment

	 MEND			; End MEM_FALT module

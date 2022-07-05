;' $Header:   P:/PVCS/MAX/386MAX/UTIL_SUM.ASV   1.3   08 Jul 1998 12:30:16   BOB  $
	 title	 UTIL_SUM -- 386LOAD/MOVE'EM TSR Summary and Fitter
	 page	 58,122
	 name	 UTIL_SUM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Data    segment UDATA,	dword-aligned, public, class 'udata'

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include ASCII.INC
	 include DOSCALL.INC
	 include VIDCALL.INC
	 include MAC.INC
	 include PTR.INC

	 include QMAX_FMT.INC
	 include LOAD_SEG.INC
	 include UTIL_OPT.INC
	 include COMM_OEM.INC
if @OEM_HARPO
	 include EMM2CALL.INC
endif				; IF @OEM_HARPO
.list

PGROUP	 group	 CODE,DATA,NCODE,NDATA,UCODE,UDATA


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 LOADSEG:word
	 extrn	 POVR_MAC:word
	 extrn	 EMMSIZE:word	; MOVE'em-compatible definition

DATA	 ends			; End DATA segment


NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 AZS_ERRMAC:byte

NDATA	 ends			; End NDATA segment


UDATA	 segment dword public 'udata' ; Start UDATA segment
	 assume  ds:PGROUP

	 extrn	 BESTSIZE:word
	 extrn	 PBTOPFIT:word
	 extrn	 CURSEG:word
	 extrn	 NREGS:word
if @OEM_FLEX
	 extrn	 REGEMS:word
endif				; IF @OEM_FLEX
	 extrn	 REGSPAN:word
	 extrn	 TOTREG:word
	 extrn	 NPROGS:word
	 extrn	 PSUMFIT_TAB:word
if @OEM_HARPO
	 extrn	 NSUBSEGS:word
	 extrn	 PSUBSEG_TAB:word
	 extrn	 MSG_FILES:byte
	 extrn	 MSG_FCBS:byte
	 extrn	 MSG_BUFFERS:byte
	 extrn	 MSG_LASTDRV:byte
	 extrn	 MSG_STACKS:byte
	 extrn	 MSG_IFS_G:byte
	 extrn	 MSG_IFS_H:byte
	 extrn	 MSG_IFS_R:byte
	 extrn	 MSG_IFS_Y:byte
	 extrn	 MSG_SUBSEG_DOS3:byte
	 extrn	 MSG_BATCH:byte
	 extrn	 MSG_XBDAREG:byte
	 extrn	 MSG_HPDAREG:byte
	 extrn	 MSG_STACKREG:byte
endif				; IF @OEM_HARPO
	 extrn	 SUMFIT_OFF:word
	 extrn	 SUMFIT_NUM:word
	 extrn	 REORD_FLAG:word

	 extrn	 UTL_FLAG:word
	 include QMAX_UTL.INC

	 align	 2
	 public  TOPSIZE,TOTREGB
TOPSIZE  dw	 ?		; Top size overall
TOTREGB  dd	 ?		; Total region size (+/REGTAB) in bytes

	 public  REOSUM_FLAG,DBG_FLAG
REOSUM_FLAG db	 ?		; 0 = SUMMARY, 1 = REORDER
@REOSUM_REO equ  1		; REORDER
@REOSUM_SUM equ  0		; SUMMARY
DBG_FLAG db	 ?		; If 1, /sid or /srd


if @OEM_FLEX
	 public  TXT_NOEMS,TXT_ERR,TXT_REQ,TXT_YES,TXT_NO
ifdef LANG_GR
TXT_NOEMS db	 'EMS=0'        ; EMS=0 and FLEXFRAME specified
TXT_ERR  db	 'Fehler'       ; Error when using FlexFrame !! tooo long ??
TXT_REQ  db	 'MUSS!'        ; Requires Flexframe
TXT_YES  db	 ' Ja  '        ; Allows FlexFrame
TXT_NO	 db	 'Nein '        ; Does not ...
else
TXT_NOEMS db	 'EMS=0'        ; EMS=0 and FLEXFRAME specified
TXT_ERR  db	 'Error'        ; Error when using FlexFrame
TXT_REQ  db	 ' Req '        ; Requires Flexframe
TXT_YES  db	 ' Yes '        ; Allows FlexFrame
TXT_NO	 db	 ' No  '        ; Does not ...
endif				; IFDEF LANG_GR
TXT_EYN_LEN equ  $-TXT_NO	; Length of each message
endif				; IF @OEM_FLEX

	 public  AZS_NOFIT1,AZS_NOFIT2
ifdef LANG_GR
AZS_NOFIT1 db	 ' paát    '    ; No fit message, line 1
AZS_NOFIT1LEN equ $-AZS_NOFIT1	; Length of ...
AZS_NOFIT2 db	 ' nicht ! '    ; No fit message, line 1
else
AZS_NOFIT1 db	 '  NO FIT '    ; No fit message, line 1
AZS_NOFIT1LEN equ $-AZS_NOFIT1	; Length of ...
AZS_NOFIT2 db	 ' POSSIBLE'    ; No fit message, line 1
endif				; IFDEF LANG_GR
AZS_NOFIT2LEN equ $-AZS_NOFIT2	; Length of ...


@NUMLEN  equ	 6		; Length of numeric field

	 public  MSG_GETSIZE,MSG_GETSIZE1
ifdef LANG_GR
MSG_GETSIZE db	 'entf. GETSIZE; nimm SIZE='
else
MSG_GETSIZE db	 'Remove GETSIZE; use SIZE='
endif				; IFDEF LANG_GR
MSG_GETSIZE1 db  @NUMLEN dup (' ')
MSG_GETSIZE_LEN equ $-MSG_GETSIZE ; Length of ...

	 public  MSG_REMSIZE
ifdef LANG_GR
MSG_REMSIZE db	 'entferne GETSIZE; SIZE unn”tig'
else
MSG_REMSIZE db	 'Remove GETSIZE; no SIZE needed'
endif				; IFDEF LANG_GR
MSG_REMSIZE_LEN equ $-MSG_REMSIZE ; Length of ...

	 public  MSG_REMPREG0
ifdef LANG_GR
MSG_REMPREG0 db  'Manager ins LoDOS geladen'
else
MSG_REMPREG0 db  'Manager loaded low'
endif				; IFDEF LANG_GR
MSG_REMPREG0_LEN equ $-MSG_REMPREG0 ; Length of ...

	 public  MSG_REPSIZE,MSG_REPSIZE1
ifdef LANG_GR
MSG_REPSIZE db	 'ersetze Wert durch SIZE='
else
MSG_REPSIZE db	 'Replace value with SIZE='
endif				; IFDEF LANG_GR
MSG_REPSIZE1 db  @NUMLEN dup (' ')
MSG_REPSIZE_LEN equ $-MSG_REPSIZE ; Length of ...

	 public  MSG_REQSIZE,MSG_REQSIZE1
ifdef LANG_GR
MSG_REQSIZE db	 'weiter mit SIZE='
else
MSG_REQSIZE db	 'Continue with SIZE='
endif				; IFDEF LANG_GR
MSG_REQSIZE1 db  @NUMLEN dup (' ')
MSG_REQSIZE_LEN equ $-MSG_REQSIZE ; Length of ...

	 public  MSG_FORSIZE,MSG_FORSIZE1
ifdef LANG_GR
MSG_FORSIZE db	 '*erforderlich* SIZE='
else
MSG_FORSIZE db	 'You *MUST* use SIZE='
endif				; IFDEF LANG_GR
MSG_FORSIZE1 db  @NUMLEN dup (' ')
MSG_FORSIZE_LEN equ $-MSG_FORSIZE ; Length of ...

	 public  MSG_NOSIZE
ifdef LANG_GR
MSG_NOSIZE db	 'kein SIZE-Parameter n”tig'
else
MSG_NOSIZE db	 'No SIZE parameter needed'
endif				; IFDEF LANG_GR
MSG_NOSIZE_LEN equ $-MSG_NOSIZE ; Length of ...

	 public  PAZS_SUMHEAD
	 align	 2
PAZS_SUMHEAD dw  PGROUP:AZS_SUMHEAD1
	 dw	 PGROUP:AZS_SUMHEAD2
	 dw	 PGROUP:AZS_SUMHEAD3
	 dw	 PGROUP:AZS_SUMHEAD4
	 dw	 PGROUP:AZS_SUMHEAD5
	 dw	 PGROUP:AZS_SUMHEAD6
	 dw	 PGROUP:AZS_SUMHEAD7
NAZS_SUMHEAD equ ($-PAZS_SUMHEAD)/(type PAZS_SUMHEAD)

	 public  AZS_SUMHEAD1,AZS_SUMHEAD2,AZS_SUMHEAD3
	 public  AZS_SUMHEAD4,AZS_SUMHEAD5,AZS_SUMHEAD6
	 public  AZS_SUMHEAD7
if @OEM_FLEX
AZS_SUMHEAD1 db  'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸',CR,LF,0
ifdef LANG_GR
AZS_SUMHEAD2 db  '³               LADE-VERHALTEN RESIDENTER PROGRAMME IM SPEICHER               ³',CR,LF,0
else
AZS_SUMHEAD2 db  '³                       RESIDENT PROGRAM MEMORY SUMMARY                       ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_SUMHEAD3 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_SUMHEAD4 db  '³              ³  Gr”áenparameter  ³ Flex-  ³                                 ³',CR,LF,0
AZS_SUMHEAD5 db  '³ Ger„te- oder ÃÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ´ Frame  ³ nderungs-Empfehlungen          ³',CR,LF,0
AZS_SUMHEAD6 db  '³ Programmname ³ Initial.³resident ³ (J/N)? ³ oder Hinweise                   ³',CR,LF,0
else
AZS_SUMHEAD4 db  '³              ³  Size Parameters  ³ Allow  ³                                 ³',CR,LF,0
AZS_SUMHEAD5 db  '³ Device or    ÃÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ´ Flex   ³                                 ³',CR,LF,0
AZS_SUMHEAD6 db  '³ Program Name ³ Initial ³Resident ³ Frame? ³ Suggested Action                ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_SUMHEAD7 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
;;;;;;;; db	 '³ filename.ext ³ nnn,nnn ³ nnn,nnn ³  Yes   ³                                 ³',CR,LF,0
else
AZS_SUMHEAD1 db  'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸',CR,LF,0
ifdef LANG_GR
AZS_SUMHEAD2 db  '³               LADE-VERHALTEN RESIDENTER PROGRAMME IM SPEICHER               ³',CR,LF,0
else
AZS_SUMHEAD2 db  '³                       RESIDENT PROGRAM MEMORY SUMMARY                       ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_SUMHEAD3 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_SUMHEAD4 db  '³              ³  Gr”áenparameter  ³                                          ³',CR,LF,0
AZS_SUMHEAD5 db  '³ Ger„te- oder ÃÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ´ nderungs-Empfehlungen                   ³',CR,LF,0
AZS_SUMHEAD6 db  '³ Programmname ³ Initial.³resident ³ oder Hinweise                            ³',CR,LF,0
else
AZS_SUMHEAD4 db  '³              ³  Size Parameters  ³                                          ³',CR,LF,0
AZS_SUMHEAD5 db  '³ Device or    ÃÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ´                                          ³',CR,LF,0
AZS_SUMHEAD6 db  '³ Program Name ³ Initial ³Resident ³ Suggested Action                         ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_SUMHEAD7 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
;;;;;;;; db	 '³ filename.ext ³ nnn,nnn ³ nnn,nnn ³                                          ³',CR,LF,0
endif				; IF @OEM_FLEX

	 public  PAZS_SUMLIN
	 align	 2
;;;;_SUMLIN dw	 PGROUP:AZS_SUMLIN_LSIZ,8
PAZS_SUMLIN dw	 PGROUP:AZS_SUMLIN_ISIZ,8
	 dw	 PGROUP:AZS_SUMLIN_RSIZ,8
	 dw	 PGROUP:AZS_SUMLIN_ACT+AZS_SUMLIN_ACTLEN-1,AZS_SUMLIN_ACTLEN
	 dw	 PGROUP:MSG_GETSIZE1+(size MSG_GETSIZE1)-1,size MSG_GETSIZE
	 dw	 PGROUP:MSG_REPSIZE1+(size MSG_REPSIZE1)-1,size MSG_REPSIZE
	 dw	 PGROUP:MSG_REQSIZE1+(size MSG_REQSIZE1)-1,size MSG_REQSIZE
	 dw	 PGROUP:MSG_FORSIZE1+(size MSG_FORSIZE1)-1,size MSG_FORSIZE
NAZS_SUMLIN equ  ($-PAZS_SUMLIN)/(2*type PAZS_SUMLIN)

	 public  AZS_SUMLIN
AZS_SUMLIN	db '³ '
AZS_SUMLIN_FNE	db 'Filename.ext ³ nnn,nn'
;;;_SUMLIN_LSIZ db 'n ³ nnn,nn'
AZS_SUMLIN_ISIZ db 'n ³ nnn,nn'
AZS_SUMLIN_RSIZ db 'n ³ '
if @OEM_FLEX
ifdef LANG_GR
AZS_SUMLIN_FLEX db '  Ja   ³ '
else
AZS_SUMLIN_FLEX db ' Yes   ³ '
endif				; IFDEF LANG_GR
endif				; IF @OEM_FLEX
AZS_SUMLIN_ACTLEN equ 78-($-AZS_SUMLIN)
AZS_SUMLIN_ACT	db AZS_SUMLIN_ACTLEN dup (' '),'³'
	 db	 CR,LF,0

ifdef OPTIM
	 public  PAZS_SUMTAIL
	 align	 2
PAZS_SUMTAIL dw  PGROUP:AZS_SUMTAIL1
	 dw	 PGROUP:AZS_SUMTAIL2
	 dw	 PGROUP:AZS_SUMTAIL3
	 dw	 PGROUP:AZS_SUMTAIL4
NAZS_SUMTAIL equ ($-PAZS_SUMTAIL)/(type PAZS_SUMTAIL)

	 public  AZS_SUMTAIL1,AZS_SUMTAIL2,AZS_SUMTAIL3,AZS_SUMTAIL4
	 public  AZS_SUMAVL1,AZS_SUMAVL2
if @OEM_FLEX
AZS_SUMTAIL1 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_SUMTAIL2 db  '³ Alle Programme / Umgebungen passen        ³ aktive Prog./Umgeb.           '
AZS_SUMAVL1  db  'n ³',CR,LF,0
AZS_SUMTAIL3 db  '³ in den HiDOS-Bereich                      ³ verfgbar                     '
AZS_SUMAVL2  db  'n ³',CR,LF,0
else
AZS_SUMTAIL2 db  '³ All programs/environments fit             ³  Prog/env in use              '
AZS_SUMAVL1  db  'n ³',CR,LF,0
AZS_SUMTAIL3 db  '³ into high DOS memory                      ³  Available                    '
AZS_SUMAVL2  db  'n ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_SUMTAIL4 db  'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾',CR,LF,0
else
AZS_SUMTAIL1 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_SUMTAIL2 db  '³ Alle Programme / Umgebungen      ³          aktive Prog./Umgeb.           '
AZS_SUMAVL1  db  'n ³',CR,LF,0
AZS_SUMTAIL3 db  '³ passen in den HiDOS-Bereich      ³          verfgbar                     '
AZS_SUMAVL2  db  'n ³',CR,LF,0
else
AZS_SUMTAIL2 db  '³ All programs/environments fit    ³           Prog/env in use              '
AZS_SUMAVL1  db  'n ³',CR,LF,0
AZS_SUMTAIL3 db  '³ into high DOS memory             ³           Available                    '
AZS_SUMAVL2  db  'n ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_SUMTAIL4 db  'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾',CR,LF,0
endif					; IF @OEM_FLEX
else
	 public  PAZS_SUMTAIL
	 align	 2
PAZS_SUMTAIL dw  PGROUP:AZS_SUMTAIL1
NAZS_SUMTAIL equ ($-PAZS_SUMTAIL)/(type PAZS_SUMTAIL)

	 public  AZS_SUMTAIL1
AZS_SUMTAIL1 db  'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾',CR,LF,0
endif					; IFDEF OPTIM

ifdef OPTIM
	 public  CURREG,STARTPARA,REGSTART,REGRFREE,REGIFREE,REGILEN,DBGTYPE
CURREG	 dw	 ?		; Current region
STARTPARA dw	 ?		; Starting paragraph
REGSTART dw	 @NREGS dup (?) ; Starting segment for each region
REGRFREE dw	 ?		; Free resident space
REGIFREE dw	 ?		; Free initialization space (may include FF)
REGILEN  dw	 ?		; Largest initialization size
DBGTYPE  dw	 ?		; Type of allocation:
@DBGTYPE_MAX equ 0		; 386MAX.SYS program storage
@DBGTYPE_MAXSUB equ 1		; HPDA, XBDA, MAX stack
@DBGTYPE_DEV equ 2		; DEVICE=
@DBGTYPE_INST equ 3		; INSTALL=
@DBGTYPE_SUB equ 4		; ExtraDOS subsegment
@DBGTYPE_TSR equ 5		; 386LOAD'ed TSR
@DBGTYPE_ENV equ 6		; Environment for 386LOAD'ed TSR
@DBGTYPE_UMB equ 7		; Any UMB

	 public  SUBSEG_OFF,CDBGORD,DISPRSUB
SUBSEG_OFF dw	 ?		; Current offset within SUBSEG_TAB
CDBGORD  dw	 ?		; Current order (origin:1) to display
DISPRSUB dw	 ?		; Flags defined as:
@DISPR_MAXSUB equ 0001h 	; MAX subsegs have been processed
@DISPR_LASTDEV equ 0002h	; Found LASTDEV in order
@DISPR_SUB equ	 0004h		; ExtraDOS subsegs have been displayed
				; for this region

	 public  DBGTLBL
DBGTLBL label byte
	 db	 'Manager     ' ; @DBGTYPE_MAX
@DBGTLBL_LEN equ $-DBGTLBL	; Length in bytes of each entry
	 db	 'Manager sub.' ; @DBGTYPE_MAXSUB
	 db	 'Device drvr ' ; @DBGTYPE_DEV
	 db	 'INSTALL=    ' ; @DBGTYPE_INST
	 db	 'Subsegment  ' ; @DBGTYPE_SUB
	 db	 'Resident prg' ; @DBGTYPE_TSR
	 db	 'Resident env' ; @DBGTYPE_ENV
	 db	 'UMB         ' ; @DBGTYPE_UMB

	 public  FREELBL
FREELBL  db	 ' - Unused - ' ; Free or unused initialization size
@FREELBL_LEN equ $-FREELBL

	 public  PAZS_DBGHEAD
	 align	 2
PAZS_DBGHEAD dw  PGROUP:AZS_DBGHEAD1
	 dw	 PGROUP:AZS_DBGHEAD2
	 dw	 PGROUP:AZS_DBGHEAD3
	 dw	 PGROUP:AZS_DBGHEAD4
	 dw	 PGROUP:AZS_DBGHEAD5
	 dw	 PGROUP:AZS_DBGHEAD6
NAZS_DBGHEAD equ ($-PAZS_DBGHEAD)/(type PAZS_DBGHEAD)

	 public  PAZS_DBGGROUP
	 align	 2
PAZS_DBGGROUP dw PGROUP:AZS_DBGHEAD7
NAZS_DBGGROUP equ ($-PAZS_DBGGROUP)/(type PAZS_DBGGROUP)

	 public  PAZS_DBGTAIL
	 align	 2
PAZS_DBGTAIL dw  PGROUP:AZS_DBGTAIL1
NAZS_DBGTAIL equ ($-PAZS_DBGTAIL)/(type PAZS_DBGTAIL)

	 public  PAZS_DBGLIN
	 align	 2
PAZS_DBGLIN dw	 PGROUP:AZS_DBGISIZE,8
	 dw	 PGROUP:AZS_DBGRSIZE,8
NAZS_DBGLIN equ  ($-PAZS_DBGLIN)/(2*type PAZS_DBGLIN)

	 public  AZS_DBGHEAD1,AZS_DBGHEAD2,AZS_DBGHEAD3,AZS_DBGHEAD4
	 public  AZS_DBGHEAD5,AZS_DBGHEAD6,AZS_DBGHEAD7,AZS_DBGTAIL1
	 public  AZS_DBGLIN
AZS_DBGHEAD1 db  'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸',CR,LF,0
ifdef LANG_GR
AZS_DBGHEAD2 db  '³                     HIDOS OPTIMIERUNGS-šBERSICHT                            ³',CR,LF,0
AZS_DBGHEAD3 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
AZS_DBGHEAD4 db  '³ Programmname ³ Typ          ³ Hex   ³ Initialisierung   ³ Resident          ³',CR,LF,0
AZS_DBGHEAD5 db  '³              ³              ³ Start ÃÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ´',CR,LF,0
AZS_DBGHEAD6 db  '³              ³              ³       ³ Gr”áe   ³ Hex Ende³ Gr”áe   ³ Hex Ende³',CR,LF,0
else
AZS_DBGHEAD2 db  '³                     HIGH DOS OPTIMIZATION SUMMARY                           ³',CR,LF,0
AZS_DBGHEAD3 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
AZS_DBGHEAD4 db  '³ Program Name ³ Type         ³ Hex   ³ Initialization    ³ Resident          ³',CR,LF,0
AZS_DBGHEAD5 db  '³              ³              ³ Start ÃÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ´',CR,LF,0
AZS_DBGHEAD6 db  '³              ³              ³       ³ Size    ³ Hex end ³ Size    ³ Hex end ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_DBGHEAD7 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄ´',CR,LF,0
;;;;;;;    db	 '³ filename.ext ³              ³ xxxx  ³ nnn,nnn ³ xxxx    ³ nnn,nnn ³ xxxx    ³',CR,LF,0
AZS_DBGLIN   db  '³ '
AZS_DBGFNE db	 'filename.ext ³ '
AZS_DBGTYPE db	 '             ³ '
AZS_DBGSTART db  'xxxx  ³ nnn,nn'
AZS_DBGISIZE db  'n ³ '
AZS_DBGIEND db	 'xxxx    ³ nnn,nn'
AZS_DBGRSIZE db  'n ³ '
AZS_DBGREND db	 'xxxx    ³',CR,LF,0
AZS_DBGTAIL1 db  'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍ¾',CR,LF,0
endif					; IFDEF OPTIM

ifdef OPTIM
	 public  _OPT_PROGRESS,_OPT_CALLBACK
_OPT_PROGRESS	label	dword
		dw	PGROUP:SHOW_PROGRESS,?
_OPT_CALLBACK	label	dword
		dw	PGROUP:CONFIRM_ABESC,?

	 public  OP_LASTPCT,OP_TOTPOS,OP_TOTHPOS,OP_CURPOS,OP_BESTPOS
	 public  OP_BESTPCTPOS
	 public  OP_BARPOS,OP_ELPOS,OP_BELPOS,OP_BESTBPOS,OP_DISPTOT,OP_VPAGE
	 public  OP_DISPESC
OP_LASTPCT dw	 ?		; Last percentage displayed
OP_TOTPOS dw	 0ch		; y,x of total position
OP_TOTHPOS dw	 46h		; Total bytes in high DOS position
OP_CURPOS dw	 0ch		; Current position
OP_BESTPOS dw	 0ch		; Best count position
OP_BARPOS dw	 14h		; Percentage histogram position
OP_ESCPOS dw	 1bh		; ", Esc to accept current best" position
OP_BESTPCTPOS dw 2ah		; Best count as percentage of total position
OP_ELPOS dw	 35h		; Elapsed time position
OP_BELPOS dw	 35h		; Best elapsed time position
OP_BESTBPOS dw	 46h		; Best bytes moved position
OP_DISPTOT db	 ?		; If !0, we displayed total already
OP_DISPESC db	 ?		; If !0, Esc to accept message is displayed
OP_VPAGE db	 ?		; Current display page

	 public  PAZS_OPTIM
	 align	 2
PAZS_OPTIM dw	 PGROUP:AZS_OPTIM1
	 dw	 PGROUP:AZS_OPTIM2
	 dw	 PGROUP:AZS_OPTIM3
	 dw	 PGROUP:AZS_OPTIM3B
	 dw	 PGROUP:AZS_OPTIM4
	 dw	 PGROUP:AZS_OPTIM5
	 dw	 PGROUP:AZS_OPTIM6
	 dw	 PGROUP:AZS_OPTIM7
	 dw	 PGROUP:AZS_OPTIM8
	 dw	 PGROUP:AZS_OPTIM9
	 dw	 PGROUP:AZS_OPTIM10
	 dw	 PGROUP:AZS_OPTIM11
	 dw	 PGROUP:AZS_OPTIM12
	 dw	 PGROUP:AZS_CTRLBRK
NAZS_OPTIM equ	 ($-PAZS_OPTIM)/(type PAZS_OPTIM)

	 public  PAZS_OPTIM2
PAZS_OPTIM2 dw	 PGROUP:AZS_OPTIM3A
	 dw	 PGROUP:AZS_OPTIM3B
	 dw	 PGROUP:AZS_OPTIM4
	 dw	 PGROUP:AZS_OPTIM5
	 dw	 PGROUP:AZS_OPTIM6
	 dw	 PGROUP:AZS_OPTIM7
	 dw	 PGROUP:AZS_OPTIM8
	 dw	 PGROUP:AZS_OPTIM9
	 dw	 PGROUP:AZS_OPTIM10
	 dw	 PGROUP:AZS_OPTIM11
	 dw	 PGROUP:AZS_OPTIM12
	 dw	 PGROUP:AZS_CTRLBRK
NAZS_OPTIM2 equ  ($-PAZS_OPTIM2)/(type PAZS_OPTIM2)


	 public  AZS_OPTIM1,AZS_OPTIM2,AZS_OPTIM3B,AZS_TOTAL,AZS_TOTHIGH
	 public  AZS_OPTIM3,AZS_CUR,AZS_CURTIME
	 public  AZS_BEST,AZS_BESTTIME,AZS_BESTBYTES,AZS_PCTBAR,AZS_PCTNULL
	 public  AZS_BESTPCT,AZS_BESTBPCT
AZS_OPTIM1 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_OPTIM2 db	 '³ Nicht alle Progr./Umgeb. passen in dieser Reihenfolge in den HiDOS-Bereich  ³',CR,LF,0
else
AZS_OPTIM2 db	 '³ Not all programs/environments fit into high DOS memory in this order        ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_OPTIM3 db	 'ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ',CR,LF,0
AZS_OPTIM3A db	 'ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ',CR,LF,0
ifdef LANG_GR
AZS_OPTIM3B db	 '³                           OPTIMIERUNGS-VORGANG                              ³',CR,LF,0
else
AZS_OPTIM3B db	 '³                           OPTIMIZATION PROGRESS                             ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_OPTIM4 db	 'ÃÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_OPTIM5 db	 '³         ³        Anzahl Kombinationen          ³     Zeit     ³ Byte        ³',CR,LF,0
else
AZS_OPTIM5 db	 '³         ³         Number of combinations       ³     Time     ³ Bytes       ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_OPTIM6 db	 'ÃÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_OPTIM7 db	 '³ gesamt  ³ '
else
AZS_OPTIM7 db	 '³ Total   ³ '
endif				; IFDEF LANG_GR
AZS_TOTAL  db		     '                                     ³              ³   '
AZS_TOTHIGH db									     '          ³',CR,LF,0
ifdef LANG_GR
AZS_OPTIM8 db	 '³ geprft ³ '
else
AZS_OPTIM8 db	 '³ Tested  ³ '
endif				; IFDEF LANG_GR
AZS_CUR    db		     '                                     ³   '
AZS_CURTIME db							      '           ³             ³',CR,LF,0
ifdef LANG_GR
AZS_OPTIM9 db	 '³ ideal   ³ '
else
AZS_OPTIM9 db	 '³ Best    ³ '
endif				; IFDEF LANG_GR
AZS_BEST   db		     '                              '
AZS_BESTPCT db						   '       ³   '
AZS_BESTTIME db 						      '           ³   '
AZS_BESTBYTES db								     '          ³',CR,LF,0
AZS_OPTIM10 db	 'ÃÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_OPTIM11 db	 '³ Prozent komplett: '
else
AZS_OPTIM11 db	 '³ Percent complete: '
endif				; IFDEF LANG_GR
AZS_PCTBAR db	 '°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°'
AZS_PCTNULL db	 '        ³',CR,LF,0
AZS_BESTBPCT db  'xxx',@NATL_DECIMAL,'x%',0
AZS_OPTIM12 db	 '³                   0           25           50          75          100      ³',CR,LF,0
ifdef LANG_GR
AZS_CTRLBRK db	 '³ Abbrechen mit Strg-Untbr.                                                   ³',CR,LF,0
else
AZS_CTRLBRK db	 '³ Press Ctrl-Break to abort                                                   ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_OPTIM13 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_ESC db	 ', ESC nimmt Vorschlag an',0
else
AZS_ESC db	 ', ESC to accept best fit',0
endif				; IFDEF LANG_GR

ifdef LANG_GR
AZS_OPTIM14 db	 '³                      OPTIMIERUNG RESIDENTER PROGRAMME                       ³',CR,LF,0
else
AZS_OPTIM14 db	 '³                        RESIDENT PROGRAM OPTIMIZATION                        ³',CR,LF,0
endif				; IFDEF LANG_GR

	 public  PAZS_FITHEAD
	 align	 2
PAZS_FITHEAD dw  PGROUP:AZS_OPTIM13
	 dw	 PGROUP:AZS_OPTIM14
	 dw	 PGROUP:AZS_FITHEAD1
	 dw	 PGROUP:AZS_FITHEAD2
	 dw	 PGROUP:AZS_FITHEAD3
	 dw	 PGROUP:AZS_FITHEAD4
	 dw	 PGROUP:AZS_FITHEAD5
NAZS_FITHEAD equ ($-PAZS_FITHEAD)/(type PAZS_FITHEAD)

	 public  AZS_FITHEAD1,AZS_FITHEAD2,AZS_FITHEAD3
	 public  AZS_FITHEAD4,AZS_FITHEAD5
if @OEM_FLEX
AZS_FITHEAD1 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_FITHEAD2 db  '³              ³maximale ³ residente ³ Flex-  ³ beste ³       ³(Umg.) ³       ³',CR,LF,0
AZS_FITHEAD3 db  '³ Programm-    ³Programm-³Prog./Umge-³ Frame  ³ Lade- ³ Prog- ³ Env-  ³Gruppe ³',CR,LF,0
AZS_FITHEAD4 db  '³ Name         ³  Gr”áe  ³bungs-Gr”áe³ (J/N)? ³ folge ³ Reg # ³ Reg # ³   #   ³',CR,LF,0
else
AZS_FITHEAD2 db  '³              ³ Maximum ³ Resident  ³ Allow  ³ Best  ³       ³       ³       ³',CR,LF,0
AZS_FITHEAD3 db  '³ Program      ³ Program ³ Prg & Env ³ Flex   ³ Load  ³ Prog  ³ Env   ³ Group ³',CR,LF,0
AZS_FITHEAD4 db  '³ Name         ³   Size  ³   Size    ³ Frame? ³ Order ³ Reg # ³ Reg # ³   #   ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_FITHEAD5 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄ´',CR,LF,0
;;;;;;;; db	 '³ filename.ext ³ nnn,nnn ³   nnn,nnn ³  Yes   ³   n   ³   n   ³   n   ³   n   ³',CR,LF,0
else
AZS_FITHEAD1 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
ifdef LANG_GR
AZS_FITHEAD2 db  '³              ³maximale ³ residente ³  beste  ³         ³(Umgebg.)³          ³',CR,LF,0
AZS_FITHEAD3 db  '³ Programm-    ³Programm-³Prog./Umge-³  Lade-  ³  Prog-  ³  Env-   ³  Gruppe  ³',CR,LF,0
AZS_FITHEAD4 db  '³ Name         ³  Gr”áe  ³bungs-Gr”áe³  folge  ³  Reg #  ³  Reg #  ³    #     ³',CR,LF,0
else
AZS_FITHEAD2 db  '³              ³ Maximum ³ Resident  ³  Best   ³         ³         ³          ³',CR,LF,0
AZS_FITHEAD3 db  '³ Program      ³ Program ³ Prg & Env ³  Load   ³  Prog   ³  Env    ³  Group   ³',CR,LF,0
AZS_FITHEAD4 db  '³ Name         ³   Size  ³   Size    ³  Order  ³  Reg #  ³  Reg #  ³    #     ³',CR,LF,0
endif				; IFDEF LANG_GR
AZS_FITHEAD5 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
;;;;;;;; db	 '³ filename.ext ³ nnn,nnn ³   nnn,nnn ³    n    ³    n    ³    n    ³    n     ³',CR,LF,0
endif				; IF @OEM_FLEX

if @OEM_HARPO

SUBSID_STR struc
SUBSID_OWNR db	 ?		; @SFO_HARPO, @SFO_MAX, etc.
SUBSID_TYP db	 ?		; F,X,B,L,S,A, etc.
SUBSID_PTXT dw	 ?		; Offset of text (' Files') in PGROUP
SUBSID_STR ends

	 public  AZS_HARPO,SUBSID_TAB
if @OEM_FLEX
AZS_HARPO db	 '³ ', @HARPONAME, ' ³    -    ³      -    ³        ³       ³       ³       ³       ³',CR,LF,0
else
AZS_HARPO db	 '³ ', @HARPONAME, ' ³    -    ³      -    ³         ³         ³         ³          ³',CR,LF,0
endif				; IF @OEM_FLEX
SUBSID_TAB label word
	SUBSID_STR <@SFO_HARPO, @TOKEN_FILES,	PGROUP:MSG_FILES>
	SUBSID_STR <@SFO_HARPO, @TOKEN_FCB,	PGROUP:MSG_FCBS>
	SUBSID_STR <@SFO_HARPO, @TOKEN_BUFFERS, PGROUP:MSG_BUFFERS>
	SUBSID_STR <@SFO_HARPO, @TOKEN_LASTDRV, PGROUP:MSG_LASTDRV>
	SUBSID_STR <@SFO_HARPO, @TOKEN_STACKS,	PGROUP:MSG_STACKS>
	SUBSID_STR <@SFO_HARPO, @TOKEN_IFS_G,	PGROUP:MSG_IFS_G>
	SUBSID_STR <@SFO_HARPO, @TOKEN_IFS_H,	PGROUP:MSG_IFS_H>
	SUBSID_STR <@SFO_HARPO, @TOKEN_IFS_R,	PGROUP:MSG_IFS_R>
	SUBSID_STR <@SFO_HARPO, @TOKEN_IFS_Y,	PGROUP:MSG_IFS_Y>
	SUBSID_STR <@SFO_HARPO, @TOKEN_DOS3,	PGROUP:MSG_SUBSEG_DOS3>
	SUBSID_STR <@SFO_HARPO, @TOKEN_BATCH,	PGROUP:MSG_BATCH>
	SUBSID_STR <@SFO_MAX,	@TOKEN_STACKREG,PGROUP:MSG_STACKREG>
	SUBSID_STR <@SFO_MAX,	@TOKEN_HPDAREG, PGROUP:MSG_HPDAREG>
	SUBSID_STR <@SFO_MAX,	@TOKEN_XBDAREG, PGROUP:MSG_XBDAREG>
@NSUBSIDS equ	($-SUBSID_TAB)/(size SUBSID_STR)

	 public  DISP_HARPO
DISP_HARPO db	 ?		; HARPO header displayed already

	 public  LASTDEV
LASTDEV dw	 ?		; Last LSEG segment for a device

endif				; IF @OEM_HARPO

	 public  PAZS_FITLIN
	 align	 2
PAZS_FITLIN dw	 PGROUP:AZS_FITLIN_MSIZ,8
	 dw	 PGROUP:AZS_FITLIN_RSIZ,8
NAZS_FITLIN equ  ($-PAZS_FITLIN)/(2*type PAZS_FITLIN)

	 public  AZS_FITLIN
AZS_FITLIN db	 '³ '
AZS_FITLIN_FNE	db 'filename.ext ³ nnn,nn'
AZS_FITLIN_MSIZ db '  ³   nnn,nn'
AZS_FITLIN_RSIZ db 'n ³ '
if @OEM_FLEX
ifdef LANG_GR
AZS_FITLIN_FLEX db '  Ja   ³   '
else
AZS_FITLIN_FLEX db ' Yes   ³   '
endif				; IFDEF LANG_GR
AZS_FITLIN_ORD	db '    ³   '
AZS_FITLIN_PRG	db '    ³   '
AZS_FITLIN_ENV	db '    ³   '
AZS_FITLIN_GRP	db '    ³'
else
		db '   '
AZS_FITLIN_ORD	db '     ³    '
AZS_FITLIN_PRG	db '     ³    '
AZS_FITLIN_ENV	db '     ³    '
AZS_FITLIN_GRP	db '      ³'
endif				; IF @OEM_FLEX
	 db	 CR,LF,0

	 public  PAZS_FITTAIL
	 align	 2
PAZS_FITTAIL dw  PGROUP:AZS_FITTAIL1
	 dw	 PGROUP:AZS_FITTAIL2
	 dw	 PGROUP:AZS_FITTAIL3
	 dw	 PGROUP:AZS_FITTAIL4
NAZS_FITTAIL equ ($-PAZS_FITTAIL)/(type PAZS_FITTAIL)

	 public  AZS_FITTAIL1,AZS_FITTAIL2,AZS_FITTAIL3
	 public  AZS_FITTAIL4
	 public  AZS_FITSIZ1,AZS_FITSIZ2,AZS_FITSIZ3
	 public  AZS_FITAVL1,AZS_FITAVL2,AZS_FITAVL3
if @OEM_FLEX
AZS_FITTAIL1 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄ´',CR,LF,0
else
AZS_FITTAIL1 db  'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´',CR,LF,0
endif				; IF @OEM_FLEX
ifdef LANG_GR
AZS_FITTAIL2 db  '³ Byte ins HiDOS verlagert   nnn,nn'
else
AZS_FITTAIL2 db  '³ Bytes moved into high DOS  nnn,nn'
endif				; IFDEF LANG_GR
AZS_FITSIZ1 db	 'n                '
	    db	 '            '
AZS_FITSIZ2 db	 '            '
AZS_FITSIZ3 db	 '  ³',CR,LF,0
ifdef LANG_GR
AZS_FITTAIL3 db  '³ Byte verfgbar             nnn,nn'
else
AZS_FITTAIL3 db  '³ Bytes available            nnn,nn'
endif				; IFDEF LANG_GR
AZS_FITAVL1 db	 'n                '
	    db	 '            '
AZS_FITAVL2 db	 '            '
AZS_FITAVL3 db	 '  ³',CR,LF,0
AZS_FITTAIL4 db  'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾',CR,LF,0

	 public  PAZS_FITSIZ,PAZS_FITAVL
	 align	 2		; Ensure word-aligned
PAZS_FITSIZ dw	 PGROUP:AZS_FITSIZ1,8 ; Pointer to AZS_FITSIZn,length areas
	 dw	 PGROUP:AZS_FITSIZ2,8
	 dw	 PGROUP:AZS_FITSIZ3,8
PAZS_FITAVL dw	 PGROUP:AZS_FITAVL1,8 ; Pointer to AZS_FITAVLn,length areas
	 dw	 PGROUP:AZS_FITAVL2,8
	 dw	 PGROUP:AZS_FITAVL3,8
endif				; IFDEF OPTIM

UDATA	 ends			; End UDATA segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 CHECK_LINE:near

CODE	 ends			; End CODE segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 PAR2BYT:near
	 extrn	 DW2HEX:near
	 extrn	 DISP_ASCIIZ:near

NCODE	 ends			; End NCODE segment


UCODE	 segment byte public 'ucode' ; Start UCODE segment
	 assume  cs:PGROUP

	 extrn	 SAVE_SUMFIT:far
	 extrn	 REST_SUMFIT:far
	 extrn	 CALCREG:far
	 extrn	 DD2DEC:near
ifdef OPTIM
	 extrn	 TRIALFIT:far
	 extrn	 ORDFIT:far
	 extrn	 GET_TOPFIT:far
	 extrn	 RLS_TOPFIT:far
endif				; IFDEF OPTIM

ifdef OPTIM
	 NPPROC  DBIOS_ASCIIZ -- Display ASCIIZ string using BIOS
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT |

Display an ASCIIZ string at a specified cursor position using the BIOS.

On entry:
Arguments on stack

On exit:
Nothing.
|

DBIOS_STR	struc
	dw	?	; Saved BP
	dw	?	; Caller's IP
DBIOS_PTR dw	?	; near ptr to string
DBIOS_XY dw	?	; hi=Y, lo=X
DBIOS_STR	ends

	 push	 bp		; Save BP
	 mov	 bp,sp		; Get stack frame

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

	 mov	 dx,[bp].DBIOS_XY ; Get cursor position
	 mov	 bh,OP_VPAGE	; Use current display page
	 VIDCALL @SETPOS	; Set cursor position

	 mov	 si,[bp].DBIOS_PTR ; Get offset of string
	 mov	 bl,@VID_ATTR_NORM ; Use normal attributes
	 cld			; Set forward direction
@@:
	 lodsb			; Get byte to display
	 or	 al,al		; Izit the end?
	 jz	 short @F	; Da-da-da-dat's all, folks

	 VIDCALL @SETTTY	; Display character in AL
	 jmp	 short @B	; Get next

@@:
	 REGREST <si,dx,cx,bx,ax> ; Restore registers

	 pop	 bp		; Restore BP

	 ret 2+2		; Return & pop arguments from stack

	 assume  ds:nothing,es:nothing,ss:nothing

DBIOS_ASCIIZ	endp		; End DBIOS_ASCIIZ procedure
	 FPPROC  SHOW_PROGRESS -- Display optimization progress
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT |

The ORDFIT procedure in UTIL_OPT.ASM calls this procedure C style,
with a far pointer to OPROG_STR (defined in UTIL_OPT.INC).

This module is linked with UTIL_OPT and other modules for 386UTIL,
386MAX, and 386LOAD.  MAXIMIZE has its own version of SHOW_PROGRESS,
as does Move'EM.

Input:
Arguments on stack (shown above)
Output:
None (function is type void)

|

ARG_STR  struc
	 dw	?		; Caller's BP saved on stack
	 dd	?		; Return address
pptr	 dd	?		; Far pointer to OPROG_STR structure
ARG_STR  ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Stack!

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 mov	 bh,OP_VPAGE	; Get current display page
	 VIDCALL @GETPOS	; Get cursor position
	 push	 dx		; Save it on stack

	 les	 bx,[bp].pptr	; Get pointer to caller info structure
	 assume  es:nothing	; Tell the assembler about it
	 mov	 cx,es:[bx].OPROG_PCT ; Get percentage

	 cmp	 cx,OP_LASTPCT	; Izit different?
	 je	 short SP_DISPNONE ; Ignore it

	 mov	 OP_LASTPCT,cx	; Save for future comparison
	 mov	 ax,'±Û'        ; Char for even percentages in AL, odd in AH
	 shr	 cl,1		; Divide by 2
	 jc	 short @F	; If odd, AH is OK

	 dec	 cx		; Fill all but the last
	 mov	 ah,al		; Character for even percentages
@@:
	 lea	 di,AZS_PCTBAR	; Get address of percentage histogram
	 cmp	 cx,1		; Are there any preceding locations?
	 ja	 short @F	; Fill preceding entries

	 je	 short SP_DISPLAST ; Display AH

	 cmp	 ah,al		; CX=0; if even, percentage is 0
	 jne	 short SP_DISPLAST ; Display AH

	 jmp	 short SP_DISPNONE ; Display nothing

@@:
    rep  stosb			; Fill preceding locations

SP_DISPLAST:
	 mov	 al,ah		; Get character for last one
	 stosb			; Blast it in

SP_DISPBAR:
	 push	 OP_BARPOS	; X,Y for histogram
	 lea	 dx,AZS_PCTBAR	; Get address
	 push	 dx		; Pass near pointer
	 call	 DBIOS_ASCIIZ	; Display string

SP_DISPNONE:
	 cmp	 OP_DISPTOT,0	; Did we display already?
	 jne	 short @F	; If so, jump

	 inc	 OP_DISPTOT	; Set total displayed flag
	 push	 OP_TOTPOS	; X,Y for total
	 push	 es:[bx].OPROG_PTOTAL.VOFF ; Pass offset part only
	 call	 DBIOS_ASCIIZ	; Display string

	 push	 OP_TOTHPOS	; X,Y for total high
	 push	 es:[bx].OPROG_PTOTHIGH.VOFF ; Offset only
	 call	 DBIOS_ASCIIZ	; Display string

@@:
	 push	 OP_CURPOS	; X,Y for current count
	 push	 es:[bx].OPROG_PDONE.VOFF ; Pass offset of current count
	 call	 DBIOS_ASCIIZ	; Display string

	 push	 OP_ELPOS	; X,Y for elapsed time
	 push	 es:[bx].OPROG_PELAPSED.VOFF ; Pass offset of elapsed time
	 call	 DBIOS_ASCIIZ	; Display string

	 test	 es:[bx].OPROG_FLAGS,@OPF_BESTDIRTY ; Do we need to display?
	 jz	 short OPT_PROGRESS_EXIT ; If not, skip this

	 and	 es:[bx].OPROG_FLAGS,not @OPF_BESTDIRTY ; Clear the flag

	 push	 OP_BESTPOS	; X,Y for best count
	 push	 es:[bx].OPROG_PBESTCNT.VOFF ; Pass offset of best count
	 call	 DBIOS_ASCIIZ	; Display string

	 push	 OP_BESTPCTPOS	; X,Y for best percentage of count
	 push	 es:[bx].OPROG_PBESTPCT.VOFF ; Pass offset of best count percentage
	 call	 DBIOS_ASCIIZ	; Display string

	 push	 OP_BELPOS	; X,Y for best elapsed time
	 push	 es:[bx].OPROG_PBESTELAP.VOFF ; Pass offset of best elapsed time
	 call	 DBIOS_ASCIIZ	; Display string

	 push	 OP_BESTBPOS	; X,Y for best bytes moved
	 push	 es:[bx].OPROG_PBESTBYTE.VOFF ; Pass offset of best bytes moved
	 call	 DBIOS_ASCIIZ	; Display string

	 cmp	 OP_DISPESC,0	; Did we display Esc to accept message yet?
	 jne	 short OPT_PROGRESS_EXIT ; Jump if so

	 mov	 di,es:[bx].OPROG_PBESTCNT.VOFF ; Get pointer to best string
	 cmp	 PGROUP:[di+@LONGSPC-2].LO,' ' ; Izit blank?
	 je	 short OPT_PROGRESS_EXIT ; Jump if so

	 inc	 OP_DISPESC	; Mark as displayed

	 push	 OP_ESCPOS	; X,Y for Esc message
	 lea	 dx,AZS_ESC	; Offset of Esc message
	 push	 dx		; Pass as argument
	 call	 DBIOS_ASCIIZ	; Display string

OPT_PROGRESS_EXIT:
	 sub	 bh,bh		; Assume page 0
	 pop	 dx		; Restore cursor position on entry
	 VIDCALL @SETPOS	; Set cursor position to DH,DL

	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler

	 pop	 bp		; Restore BP

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SHOW_PROGRESS endp		; End SHOW_PROGRESS procedure
endif				; ifdef OPTIM

ifdef OPTIM
	 FPPROC  CONFIRM_ABESC -- Confirm abort or Esc request from optimization
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

This procedure is called via a far call indirect by ORDFIT.  A similar
procedure exists for MAXIMIZE, and for Move'EM.

Currently, we always return 1 (confirmed).

On entry:
On stack	Callback type:	0 - Esc pressed, do you want to accept best fit?
				1 - Ctrl-Break, do you want to abort?

On exit:
AX	=	0	No, I don't want to do that
		1	Yes, go ahead and do it
(1 is always returned)
|

CALLBACK_STR  struc
		 dw	?	; Caller's BP saved on stack
		 dd	?	; Return address
cback_type	 dw	?	; Callback type (see above)
CALLBACK_STR  ends

;;;;;;	 push	 bp		; Prepare to address stack
;;;;;;	 mov	 bp,sp		; Hello, Stack!

;;;;;;	 REGSAVE <> ; Save registers

;;;;;;	 mov	 ax,[bp].cback_type ; Get callback type
	 mov	 ax,1		; Always return true

;;;;;;	 REGREST <> ; Restore registers

;;;;;;	 pop	 bp		; Restore BP

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CONFIRM_ABESC	endp		; End CONFIRM_ABESC procedure
endif				; ifdef OPTIM

	 NPPROC  INORDER -- Display Summary Report and Force Recalc Without Reordering
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display summary report and force recalc without reordering.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|


	 mov	 REOSUM_FLAG,@REOSUM_REO ; Set flag
	 mov	 REORD_FLAG,0	; Mark as not allowing re-ordering
	 mov	 DBG_FLAG,0	; Don't display additional output

	 jmp	 short REOSUM	; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing

INORDER  endp			; End INORDER procedure
	 NPPROC  INORDER_DBG -- Force Recalc Without Reordering w/ Debug Output
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display summary report and force recalc without reordering.
Also display debugging output.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|


	 mov	 REOSUM_FLAG,@REOSUM_REO ; Set flag
	 mov	 REORD_FLAG,0	; Mark as not allowing re-ordering
	 mov	 DBG_FLAG,1	; Display additional output for debugging

	 jmp	 short REOSUM	; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing

INORDER_DBG endp		; End INORDER_DBG procedure
	 NPPROC  REORDER -- Display Summary Report and Force Recalc With Reordering
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display summary report and force recalc with reordering.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|


	 mov	 REOSUM_FLAG,@REOSUM_REO ; Set flag
	 mov	 REORD_FLAG,1	; Mark as allowing re-ordering
	 mov	 DBG_FLAG,0	; Don't display additional output

	 jmp	 short REOSUM	; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing

REORDER  endp			; End REORDER procedure
	 NPPROC  REORDER_DBG -- Force Recalc With Reordering and Debug Output
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display summary report and force recalc with reordering.
Also display debugging output.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|


	 mov	 REOSUM_FLAG,@REOSUM_REO ; Set flag
	 mov	 REORD_FLAG,1	; Mark as allowing re-ordering
	 mov	 DBG_FLAG,1	; Display additional output for debugging

	 jmp	 short REOSUM	; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing

REORDER_DBG endp		; End REORDER_DBG procedure
	 NPPROC  SUMMARY -- Display Summary Report With Recalc If No Fit
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display summary report with recalc only if no fit

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 mov	 REOSUM_FLAG,@REOSUM_SUM ; Set flag
	 mov	 REORD_FLAG,1	; Mark as allowing re-ordering

	 jmp	 short REOSUM ; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing

SUMMARY  endp			; End SUMMARY procedure
	 NPPROC  REOSUM -- Re-odering and Summary Common Routine
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Common routine to REORDER and SUMMARY.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|


	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

; Save the summary data in local tables for TRY_SUMFIT

	 FCALL	 SAVE_SUMFIT	; Save 'em

; Format SUMFIT table information

	 call	 FMT_SUMFIT	; Format 'em

; Perform trial fit

ifdef OPTIM
	 mov	 OP_LASTPCT,0	; Clear old percentage comparison variable

	 FCALL	 TRIALFIT	; See if the programs fit in the order specified
				; Return with
				; AX = 0 if not all programs fit
				;    = 1 if all programs fit
				;    = 2 if MAC error

; Recalculate the region sizes in case we need to run the optimization
; algorithm again

	 FCALL	 CALCREG	; Calculate region sizes
	 jc	 short REOSUM_ERR ; Jump if MAC error

	 call	 CALC_TOTREGB	; Calculate total region size in bytes
				; used in cases where AX > 0

	 cmp	 ax,1		; Split cases
	 ja	 short REOSUM_ERR ; Jump if MAC error	     (AX=2)
	 jb	 short REOSUM_REO ; Jump if it didn't fit    (AX=0)

	 cmp	 REOSUM_FLAG,@REOSUM_SUM ; Did we enter at SUMMARY?
	 je	 short REOSUM_FIT ; Jump if so
REOSUM_REO:
	 push	 REORD_FLAG	; Pass flag as argument
	 call	 TRY_SUMFIT	; Attempt to fit the programs into the regions

	 jmp	 short REOSUM_CLC ; Join common OK code

REOSUM_ERR:
	 mov	 ax,@STD_ERR	; Get handle for standard error
	 push	 ax		; Send it there
	 lea	 ax,AZS_ERRMAC	; Write out the message
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 stc			; Indicate something went wrong

	 jmp	 short REOSUM_COM ; Join common code

REOSUM_FIT:

; Calculate # used bytes

	 call	 CALC_USED	; Return with DX:AX = # bytes used

	 lea	 di,AZS_SUMAVL1 ; ES:DI ==> output save area
	 mov	 bx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 bx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

; Calculate # available bytes

	 sub	 ax,TOTREGB.ELO ; Get total region size in bytes
	 sbb	 dx,TOTREGB.EHI
	 neg	 ax		; Negate to get positive #s
	 adc	 dx,0		; Compensate for two's-complement arithmetic
	 neg	 dx

	 lea	 di,AZS_SUMAVL2 ; ES:DI ==> output save area
	 mov	 bx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 bx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

	 lea	 si,PAZS_SUMTAIL ; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_SUMTAIL ; CX = # strings to display
	 call	 DISP_ASCIIZMUL ; Display multiple lines
REOSUM_CLC:
	 clc			; Indicate all went well
REOSUM_COM:

; Release SUMFIT table

	 pushf			; Save flags (CF is result)
	 FCALL	 REST_SUMFIT	; Release 'em
	 popf			; Restore
else
	 lea	 si,PAZS_SUMTAIL ; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_SUMTAIL ; CX = # strings to display
	 call	 DISP_ASCIIZMUL ; Display multiple lines

	 clc			; Indicate all went well
endif				; IFDEF OPTIM
	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REOSUM	 endp			; End REOSUM procedure
	 NPPROC  FMT_SUMFIT -- Format SUMFIT Table Information
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Format SUMFIT table information

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

; Display header

	 lea	 si,PAZS_SUMHEAD ; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_SUMHEAD ; CX = # strings to display
	 call	 DISP_ASCIIZMUL ; Display multiple lines

; Get the segment of the start of the high DOS memory chain

	 mov	 ax,LOADSEG	; Get the segment of the start of the chain
	 mov	 CURSEG,ax	; Save as current segment
FMT_SUMFIT_NEXT:
	 cmp	 CURSEG,-1	; Check for end-of-the-chain
	MJ e	 FMT_SUMFIT_EXIT ; Jump if there's no more

	 mov	 es,CURSEG	; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[0].LSEG_NEXT ; Get pointer to next segment (if any)
	 mov	 CURSEG,ax	; Save for next time

; Copy the filename.ext and clear the numeric and text fields

	 mov	 cx,NAZS_SUMLIN ; CX = # areas to clear
	 lea	 si,PAZS_SUMLIN ; DS:SI ==> array of offsets to clear
	 call	 SUMFIT_CLR	; Clear 'em

	 REGSAVE <ds,es>	; Save for a moment

	 push	 ds		; Our data segment
	 push	 es		; Caller's ...
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 si,ds:[0].LSEG_FNE ; DS:SI ==> "filename.ext"
	 lea	 di,AZS_SUMLIN_FNE ; ES:DI ==> output save area
	 mov	 cx,size LSEG_FNE ; CX = # bytes to copy
FMT_SUMFIT_FNE:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Izit too small?
	 jae	 short @F	; Jump if no

	 mov	 al,' '         ; Use a blank
@@:
	 stosb			; Store in output save area

	 loop	 FMT_SUMFIT_FNE ; Jump if more characters to copy

	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

; Format the load size

;;;;;;;; mov	 ax,es:[0].LSEG_LSIZE.ELO ; Get the load size in bytes
;;;;;;;; mov	 dx,es:[0].LSEG_LSIZE.EHI
;;;;;;;;
;;;;;;;; push	 es		; Save for a moment
;;;;;;;;
;;;;;;;; push	 ds		; Get our segment
;;;;;;;; pop	 es		; Address it
;;;;;;;; assume  es:PGROUP	; Tell the assembler about it
;;;;;;;;
;;;;;;;; lea	 di,AZS_SUMLIN_LSIZ ; ES:DI ==> output save area
;;;;;;;; mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
;;;;;;;; push	 cx		; Pass as argument
;;;;;;;; call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI
;;;;;;;;
;;;;;;;; pop	 es		; Restore
;;;;;;;; assume  es:nothing	; Tell the assembler about it
;;;;;;;;
; Format the initialization size

	 mov	 ax,es:[0].LSEG_ISIZE.ELO ; Get the initialization size in bytes
	 mov	 dx,es:[0].LSEG_ISIZE.EHI

	 push	 es		; Save for a moment

	 push	 ds		; Get our segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,AZS_SUMLIN_ISIZ ; ES:DI ==> output save area
	 mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

; Format the resident size

	 mov	 ax,es:[0].LSEG_RPARA ; Get the resident size in paras
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 push	 es		; Save for a moment

	 push	 ds		; Get our segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,AZS_SUMLIN_RSIZ ; ES:DI ==> output save area
	 mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

if @OEM_FLEX

; Display the FlexFrame status

	 mov	 ax,es:[0].LSEG_FLAG ; Get the LSEG flags
	 call	 CHECK_FLEX	; Return with PGROUP:SI ==> message text

	 push	 es		; Save for a moment

	 push	 ds		; Get our segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,AZS_SUMLIN_FLEX ; ES:DI ==> output save area
	 mov	 cx,TXT_EYN_LEN ; CX = # bytes in message
     rep movsb			; Save in message

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
endif				; IF @OEM_FLEX

; Determine the proper action to recommend

	 mov	 ax,es:[0].LSEG_RPARA ; Get the resident size in paras
	 sub	 ax,es:[0].LSEG_NPARA ; Less size of interrupt block in paras
				; including its MAC para
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 cmp	 dx,es:[0].LSEG_ISIZE.EHI ; Use the larger
	 ja	 short REOSUM1 ; Jump if resident size is larger
	 jb	 short @F	; Jump if initialization size is larger

	 cmp	 ax,es:[0].LSEG_ISIZE.ELO ; Use the larger
	 jae	 short REOSUM1 ; Jump if resident size is larger
@@:
	 mov	 ax,es:[0].LSEG_ISIZE.ELO ; Use initialization size
	 mov	 dx,es:[0].LSEG_ISIZE.EHI
REOSUM1:
	 mov	 bx,es:[0].LSEG_ASIZE.ELO ; Get actual SIZE (if any)
	 and	 bx,es:[0].LSEG_ASIZE.EHI

	 lea	 si,MSG_REMSIZE  ; Remove GETSIZE, no SIZE required
	 mov	 cx,MSG_REMSIZE_LEN ; Length of ...

	 cmp	 es:[0].LSEG_GRP,@GRPMAX ; Izit 386MAX?
	 jne	 short @F	; Jump if not

	 lea	 si,MSG_REMPREG0 ; Manager loaded in low DOS memory
	 mov	 cx,MSG_REMPREG0_LEN ; Length of ...
@@:
	 cmp	 bx,-1		; Was GETSIZE used?
	 je	 short @F	; Yes

	 lea	 si,MSG_NOSIZE	; No SIZE required
	 mov	 cx,MSG_NOSIZE_LEN ; Length of ...
@@:
	 push	 es		; Save for a moment

	 test	 es:[0].LSEG_FLAG,@LSEG_LSIZ ; Izit forced SIZE= ?
	 jnz	 short @F	; Jump if so

	 cmp	 dx,es:[0].LSEG_LSIZE.EHI ; Check against load size
	 ja	 short @F	; Jump if initialization size is larger
	 jb	 short FMT_SUMFIT_XSIZE ; Jump if no SIZE required

	 cmp	 ax,es:[0].LSEG_LSIZE.ELO ; Check against load size
	 jbe	 short FMT_SUMFIT_XSIZE ; Jump if no SIZE required
@@:
	 lea	 si,MSG_GETSIZE ; Assume GETSIZE used
	 lea	 di,MSG_GETSIZE1 ; ES:DI ==> output save area
	 mov	 cx,MSG_GETSIZE_LEN ; Length of ...

	 cmp	 bx,-1		; Was GETSIZE used?
	 je	 short FMT_SUMFIT_FMT ; Yes

	 lea	 si,MSG_REQSIZE ; Assume SIZE used
	 lea	 di,MSG_REQSIZE1 ; ES:DI ==> output save area
	 mov	 cx,MSG_REQSIZE_LEN ; Length of ...

	 cmp	 dx,es:[0].LSEG_ASIZE.EHI ; Compare against actual SIZE (if any)
	 jne	 short @F	; Jump if not the same

	 cmp	 ax,es:[0].LSEG_ASIZE.ELO ; Compare against actual SIZE (if any)
	 je	 short FMT_SUMFIT_FMT ; Jump if same
@@:
	 lea	 si,MSG_REPSIZE ; Assume SIZE used and too large
	 lea	 di,MSG_REPSIZE1 ; ES:DI ==> output save area
	 mov	 cx,MSG_REPSIZE_LEN ; Length of ...

	 jb	 short FMT_SUMFIT_FMT ; Jump if needed < actual

	 lea	 si,MSG_FORSIZE ; SIZE required and not used!!!
	 lea	 di,MSG_FORSIZE1 ; ES:DI ==> output save area
	 mov	 cx,MSG_FORSIZE_LEN ; Length of ...
FMT_SUMFIT_FMT:
	 push	 ds		; Get our segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Blank the numeric field

	 REGSAVE <ax,cx,di>	; Save for a moment

	 mov	 cx,@NUMLEN	; Get length of numeric field
	 mov	 al,' '         ; Fill with this
     rep stosb			; Fill it up

	 REGREST <di,cx,ax>	; Restore

	 mov	 bx,@DEC_LEFT	; Mark as left-justified
	 push	 bx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI
FMT_SUMFIT_XSIZE:
	 push	 ds		; Get our segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,AZS_SUMLIN_ACT ; ES:DI ==> output save area
     rep movs	 AZS_SUMLIN_ACT[di],ds:[si].LO ; Copy to output save area

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

; Display the output

	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,AZS_SUMLIN ; Write out the summary tail
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 call	 CHECK_LINE	; Count in another line and check for pause

	 jmp	 FMT_SUMFIT_NEXT ; Go around again

FMT_SUMFIT_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FMT_SUMFIT endp 		; End FMT_SUMFIT procedure
if @OEM_FLEX
	 NPPROC  CHECK_FLEX -- Check On FLEXFRAME Status
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Check on FLEXFRAME status.

On entry:

AX	 =	 LSEG/SUMFIT flags

On exit:

PGROUP:SI ==>	 TXT_xxx of FLEXFRAME status

|

	 lea	 si,TXT_REQ	; Assume required

	 test	 ax,@LSEG_INFLEX ; Izit?
	 jnz	 short CHECK_FLEX_EXIT ; Jump if so

	 lea	 si,TXT_YES	; Assume allowed

	 test	 ax,@LSEG_FLEX	; Izit?
	 jnz	 short CHECK_FLEX_EXIT ; Jump if so

	 lea	 si,TXT_NO	; Assume no EMS error

	 test	 ax,@LSEG_XEMS	; Izit?
	 jz	 short CHECK_FLEX_EXIT ; Jump if no error

	 lea	 si,TXT_NOEMS	; Assume no EMS services

ifdef @OEM_PROD
	 cmp	 EMMSIZE,0	; Izit present?
	 je	 short CHECK_FLEX_EXIT ; Jump if not
else
	 cmp	 EMMSIZE.EHI,0	; Izit present?
	 jne	 short @F	; Jump if so

	 cmp	 EMMSIZE.ELO,0	; Izit present?
	 je	 short CHECK_FLEX_EXIT ; Jump if not
@@:
endif				; IFDEF @OEM_PROD
	 lea	 si,TXT_ERR	; It's an EMS error
CHECK_FLEX_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_FLEX endp 		; End CHECK_FLEX procedure
endif				; IF @OEM_FLEX
ifdef OPTIM
	 NPPROC  CALC_USED -- Calculate Number of Bytes Used in High DOS
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Calculate the number of bytes used in high DOS
and format into AZS_SUMAVL1 & AZS_SUMAVL2.

On exit:

DX:AX	 =	 # bytes used

|

	 REGSAVE <cx,si>	; Save registers

; Calculate # used bytes

	 mov	 cx,NPROGS	; Get # programs loaded
	 mov	 si,PSUMFIT_TAB ; DS:SI ==> start of SUMFIT table
	 xor	 ax,ax		; Initialize accumulator
CALC_USED_NEXT:
	 cmp	 PGROUP:[si].SUMFIT_PREG,0 ; Izit going resident?
	 je	 short CALC_USED_LOOP ; Jump if not

	 add	 ax,PGROUP:[si].SUMFIT_RPARA ; Get # paras to go resident
	 inc	 ax		; Count in MAC para

	 test	 PGROUP:[si].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jnz	 short CALC_USED_LOOP ; Jump if so

	 add	 ax,PGROUP:[si].SUMFIT_EPAR1 ; Get # environment paras (after)
CALC_USED_LOOP:
	 add	 si,type SUMFIT_STR ; Skip to next program entry

	 loop	 CALC_USED_NEXT ; Jump if more programs to check

	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 REGREST <si,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CALC_USED endp			; End CALC_USED procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  CALC_TOTREGB -- Calculate Total Region Size in Bytes
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Calculate total region size in bytes.

|

	 REGSAVE <ax,dx>	; Save registers

; Calculate total region size in bytes

	 mov	 ax,TOTREG	; Get total region size in paras
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 mov	 TOTREGB.ELO,ax ; Save for later use
	 mov	 TOTREGB.EHI,dx

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CALC_TOTREGB endp		; End CALC_TOTREGB procedure
endif				; IFDEF OPTIM
ifdef OPTIM
if @OEM_HARPO
	 NPPROC  DISP_SUBSEGS -- Display subsegments for a particular owner
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

On entry:
AL	 Owner value to match (@SFO_MAX,@SFO_WIN,@SFO_HARPO)

|

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save

; Display subsegments belonging to 386MAX
	 mov	 cx,NSUBSEGS	; Number of subsegments
	 or	 cx,cx		; Are there any?
	MJ z	 DISPSUB_EXIT	; Jump if none

	 mov	 dl,al		; Save current owner value

	 mov	 bx,PSUBSEG_TAB ; Address subsegment table
DISPSUB_NEXT:
	 push	 cx		; Save loop counter

; Clear the numeric and text fields

	 mov	 cx,NAZS_FITLIN ; CX = # areas to clear
	 lea	 si,PAZS_FITLIN ; DS:SI ==> array of offsets to clear
	 call	 SUMFIT_CLR	; Clear 'em
	 mov	 ax,'  '        ; Prepare to clobber other fields we don't set
if @OEM_FLEX
	 mov	 AZS_FITLIN_FLEX[0].ELO,ax ; First half of field
	 mov	 AZS_FITLIN_FLEX[2].ELO,ax ; Second half
endif				; IF @OEM_FLEX
	 mov	 AZS_FITLIN_ORD,al ; Clobber order
	 mov	 AZS_FITLIN_ENV,al ; Clobber env
	 mov	 AZS_FITLIN_GRP,al ; Clobber group

; Format the line

	 mov	 ax,PGROUP:[bx].SUMFIT_FLAG ; Get flags
	 and	 ax,mask $SFLAG_OWNR ; Isolate owner bits
	 mov	 cl,$SFLAG_OWNR ; Convert to a value
	 shr	 ax,cl		; AL = @SFO_???
	 mov	 ah,al		; Save for comparison
	 mov	 al,PGROUP:[bx].SUMFIT_GRP ; Get type letter
	 lea	 di,SUBSID_TAB	; Address subsegment ID table
	 mov	 cx,@NSUBSIDS	; Number of possible choices
DISPSUB_NEXT_SUBSID:
	 cmp	 ah,PGROUP:[di].SUBSID_OWNR ; Izit the right owner?
	 jne	 short @F	; Jump if not

	 cmp	 ah,dl		; Izit the current one?
	 jne	 short @F	; Jump if not

	 cmp	 al,PGROUP:[di].SUBSID_TYP ; Izit the one we're looking for?
	 je	 short DISPSUB_GOT_SUBSID ; Jump if so

@@:
	 add	 di,size SUBSID_STR ; Skip to next
	 loop	 DISPSUB_NEXT_SUBSID ; Go around again

	 jmp	 DISPSUB_LOOPSUB ; Go to end of loop

DISPSUB_GOT_SUBSID:
	 cmp	 dl,@SFO_HARPO	; Are we doing HARPO?
	 jne	 short @F	; Jump if not

	 cmp	 DISP_HARPO,0	; Is HARPO header already displayed?
	 jne	 short @F	; Jump if so

	 mov	 DISP_HARPO,1	; Mark as displayed already
	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,AZS_HARPO	; Display HARPO header
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 call	 CHECK_LINE	; Count in another line and check for pause
@@:
	 mov	 si,PGROUP:[di].SUBSID_PTXT ; Source for copy
	 mov	 cx,@SUBSID_TXTLEN ; Length of subsegment name
	 lea	 di,AZS_FITLIN_FNE ; ES:DI ==> output save area
  rep	 movs	 AZS_FITLIN_FNE[di],PGROUP:[si].LO ; Move it

; Display the subsegment size (skipping initialization size)

	 push	 dx		; Save owner ID (in DL)

	 mov	 ax,PGROUP:[bx].SUMFIT_RPARA ; Get # paras needed
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 lea	 di,AZS_FITLIN_RSIZ ; ES:DI ==> output save area
	 mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

	 pop	 dx		; Restore

; Display the subsegment region #
; Note that the presence of a star doesn't mean something is wrong
; just that it doesn't obviously match the default behavior

	 mov	 al,PGROUP:[bx].SUMFIT_PREG ; Get optimized subsegment region #

	 cmp	 al,PGROUP:[bx].SUMFIT_EREG ; Izit the same as command line value?
	 mov	 ah,' '         ; Assume it is
	 je	 short @F	; Jump if so

	 mov	 ah,'*'         ; Mark as different
@@:
	 or	 al,al		; Izit low?
	 jnz	 short @F	; Jump if not

	 mov	 al,' '-'0'     ; Make sure we end up with a space
@@:
	 add	 al,'0'         ; Convert to decimal
	 mov	 AZS_FITLIN_PRG.ELO,ax ; Save in display

; Display the output

	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,AZS_FITLIN ; Write out the summary fit tail
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 call	 CHECK_LINE	; Count in another line and check for pause

DISPSUB_LOOPSUB:
	 pop	 cx		; Restore loop counter
	 add	 bx,size SUMFIT_STR ; Skip to next entry
;;;;;;;  loop	 DISPSUB_NEXT	; Go around again
	 dec	 cx		; Adjust counter
	MJ nz	 DISPSUB_NEXT	; Go around again

DISPSUB_EXIT:
	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_SUBSEGS endp		; End DISP_SUBSEGS procedure
endif				; IF @OEM_HARPO
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  TRY_SUMFIT -- Attempt a Summary Fit
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Fit the various sizes to the regions.

|

TRYSF_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
TRYSF_FLAG dw	 ?		; ...	   flags:  0 = don't re-order
				;		   1 = allow re-ordering
TRYSF_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 push	 ds		; Get our data segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 _OPT_PROGRESS.VSEG,cs ; Fix up segment of far ptr
	 mov	 _OPT_CALLBACK.VSEG,cs ; Fix up segment of far ptr

; Display progress display stuff using BIOS if we are not redirecting output

	 test	 UTL_FLAG,@UTL_COT ; Check on standard output
	 jz	 short TRYSF_XCOT1 ; Skip this if it's redirected

	 mov	 OP_DISPTOT,0	; Make sure we display total once and only once
	 mov	 OP_DISPESC,0	; Once a non-blank best count appears, display

	 lea	 si,PAZS_OPTIM2 ; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_OPTIM2 ; CX = # strings to display
	 cmp	 REOSUM_FLAG,@REOSUM_REO ; Inorder/reorder specified?
	 je	 @F		; Yes use different message then

	 lea	 si,PAZS_OPTIM	; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_OPTIM	; CX = # strings to display
@@:
	 call	 DISP_ASCIIZMUL ; Display multiple lines

	 mov	 AZS_PCTNULL,0	; Terminate percentage done histogram

	 VIDCALL @GETINF	; Get current page in BH
	 mov	 OP_VPAGE,bh	; Save it
	 VIDCALL @GETPOS	; Get position in current display page
	 dec	 dh		; DH = r-1

	 push	 dx		; Save for a moment
	 VIDCALL @SETPOS	; Move up one line so "Press Esc" will be erased
	 pop	 dx		; Restore position

	 mov	 OP_ESCPOS.HI,dh ; Y position
	 sub	 dh,2		; DH = r-3
	 mov	 OP_BARPOS.HI,dh ; Y position
	 sub	 dh,2		; DH = r-5
	 mov	 OP_BESTPOS.HI,dh ; Y position
	 mov	 OP_BELPOS.HI,dh ; Y position
	 mov	 OP_BESTBPOS.HI,dh ; Y position
	 mov	 OP_BESTPCTPOS.HI,dh ; Y position
	 dec	 dh		; DH = r-6
	 mov	 OP_CURPOS.HI,dh ; Y position
	 mov	 OP_ELPOS.HI,dh ; Y position
	 dec	 dh		; DH = r-7
	 mov	 OP_TOTPOS.HI,dh ; Y position
	 mov	 OP_TOTHPOS.HI,dh ; Y position
TRYSF_XCOT1:

; Allocate room for top fits

	 FCALL	 GET_TOPFIT	; Get it

	 mov	 TOPSIZE,0	; Initialize

	 push	 [bp].TRYSF_FLAG ; Pass flag as argument to ORDFIT
	 FCALL	 ORDFIT 	; Order the possibilities

; If we're redirecting output, display the ASCIIZ string of
; the last progress display

	 test	 UTL_FLAG,@UTL_COT ; Check on standard output
	 jnz	 short TRYSF_COT1 ; Skip this if it's not redirected

	 mov	 AZS_CTRLBRK,0	; Don't display Esc/Ctrl-Break msg

	 lea	 si,PAZS_OPTIM2 ; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_OPTIM2 ; CX = # strings to display
	 cmp	 REOSUM_FLAG,@REOSUM_REO ; Inorder/reorder specified?
	 je	 @F		; Yes use different message then

	 lea	 si,PAZS_OPTIM	; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_OPTIM	; CX = # strings to display
@@:
	 call	 DISP_ASCIIZMUL ; Display multiple lines

	 mov	 AZS_CTRLBRK,'³' ; Restore

TRYSF_COT1:
	 lea	 si,PAZS_FITHEAD ; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_FITHEAD ; CX = # strings to display
	 call	 DISP_ASCIIZMUL ; Display multiple lines

; Get the segment of the start of the high DOS memory chain

	 mov	 ax,LOADSEG	; Get the segment of the start of the chain
	 mov	 CURSEG,ax	; Save as current segment

if @OEM_HARPO
; Find the LSEG segment for the last driver.  That's where we'll display
; the HARPO subsegment info.
	 mov	 DISP_HARPO,0	; HARPO header not displayed yet
	 mov	 LASTDEV,ax	; Save a default value (should be MAX)
	 REGSAVE <es>		; Save
@@:
	 cmp	 ax,-1		; Izit the end of the chain?
	 je	 short @F	; Jump if so

	 mov	 es,ax		; Address LSEG
	 assume  es:nothing	; Tell the assembler

	 mov	 ax,es:[0].LSEG_NEXT ; Get segment of next entry
	 test	 es:[0].LSEG_FLAG,@LSEG_DRV ; Izit a device driver?
	 jz	 short @B	; Jump if not

	 mov	 LASTDEV,es	; Save segment of last driver
	 jmp	 short @B	; Go around again

@@:
	 REGREST <es>		; Restore
	 assume  es:PGROUP	; Tell the assembler

endif				; IF @OEM_HARPO

	 mov	 SUMFIT_OFF,0	; Initialize the offset into SUMFIT_TAB
	 mov	 SUMFIT_NUM,0	; Initialize SUMFIT #
TRY_SUMFIT_NEXT:
	 cmp	 CURSEG,-1	; Check for end-of-the-chain
	MJ e	 TRY_SUMFIT_END ; Jump if no more

; Copy the filename.ext and clear the numeric and text fields

	 REGSAVE <ds>		; Save for a moment

	 mov	 cx,NAZS_FITLIN ; CX = # areas to clear
	 lea	 si,PAZS_FITLIN ; DS:SI ==> array of offsets to clear
	 call	 SUMFIT_CLR	; Clear 'em

	 mov	 ds,CURSEG	; Get the current segment
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,ds:[0].LSEG_NEXT ; Get pointer to next segment (if any)
	 mov	 CURSEG,ax	; Save for next time

	 lea	 si,ds:[0].LSEG_FNE ; DS:SI ==> "filename.ext"
	 lea	 di,AZS_FITLIN_FNE ; ES:DI ==> output save area
	 mov	 cx,size LSEG_FNE ; CX = # bytes to copy
     rep movsb			; Copy to local area

	 REGREST <ds>		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

; Format the line

	 mov	 bx,SUMFIT_OFF	; Get the offset into SUMFIT_TAB
	 add	 bx,PSUMFIT_TAB ; Plus start of table

; Display the maximum program size

	 mov	 ax,PGROUP:[bx].SUMFIT_IPARA ; Get # paras needed to install
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 lea	 di,AZS_FITLIN_MSIZ ; ES:DI ==> output save area
	 mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

; Display the resident program and environment size

	 mov	 ax,PGROUP:[bx].SUMFIT_RPARA ; Get # paras needed to go resident
	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jnz	 short @F	; Jump if so

	 add	 ax,PGROUP:[bx].SUMFIT_EPAR1 ; Plus same for environment (after)
	 jz	 short TRY_SUMFIT_XRES ; Jump if it's empty
@@:
	 inc	 ax		; Count in the MAC para for program
TRY_SUMFIT_XRES:
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 lea	 di,AZS_FITLIN_RSIZ ; ES:DI ==> output save area
	 mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

; Display the group #s.  Note that MAXIMIZE will modify SUMFIT_GRP directly
; for UMB allocators that are manually marked for reordering, so to test for
; a UMB we can no longer compare SUMFIT_GRP with @GRPUMB.

	 mov	 al,PGROUP:[bx].SUMFIT_GRP ; Get its #

	 cmp	 al,@GRPUMB	; Izit a UMB?
	 je	 short @F	; Jump if so

	 cmp	 al,@GRPMAX	; Izit 386MAX?
	 je	 short @F	; Jump if so

	 cmp	 al,@GRP_HIPROG ; Izit loaded by HARPO?
	 jne	 short TRY_SUMFIT_FMTGRP ; Jump if not
@@:
	 mov	 al,0		; Set to zero
TRY_SUMFIT_FMTGRP:
	 call	 CNVAAM 	; Convert to decimal
				; AL = tens digit
				; AH = units ...
	 mov	 AZS_FITLIN_GRP.ELO[-1],ax ; Save in display

if @OEM_FLEX
; Display the FlexFrame status

	 mov	 ax,PGROUP:[bx].SUMFIT_FLAG ; Get SUMFIT flags
	 call	 CHECK_FLEX	; Return with PGROUP:SI ==> message text

	 lea	 di,AZS_FITLIN_FLEX ; ES:DI ==> output save area
	 mov	 cx,TXT_EYN_LEN ; CX = # bytes in message
     rep movsb			; Save in message
endif				; IF @OEM_FLEX

; Display the fit #s

	 xor	 di,di		; Initialize AZS_FITLIN index

	 cmp	 BESTSIZE,0	; Izit being used?
	 je	 short TRY_SUMFIT_NEXTORD_LOOP ; Jump if not

	 mov	 bp,PBTOPFIT	; DS:BP ==> TOPFIT[0;]
	 mov	 al,type RFIT_STR ; Get size of RFIT structure
	 mul	 SUMFIT_NUM.LO	; Times program #
	 add	 bp,ax		; DS:BP ==> TOPFIT[0;J]

; Display the program order #s

	 mov	 al,PGROUP:[bp].RFIT_PORD ; Get its order #
	 call	 CNVAAM 	; Convert to decimal
				; AL = tens digit
				; AH = units ...
	 mov	 AZS_FITLIN_ORD.ELO[di-1],ax ; Save in display

; Display the program region #s
; Mark as same if
;   * The program is loaded low
;   * A command line value is specified
;     and it is the same as the calculated value
;   * A command line value is not specified
;     and the calculated value is 1 (PRGREG=1) as that's the default
; Note that the presence of a star doesn't mean something is wrong
; just that it doesn't obviously match the default behavior
; The problem is determining the default region into which a program
; is loaded without explicit guidance from PRGREG=
; Note that this is not applicable to UMBs, since they never have a
; specified region.

	 mov	 al,PGROUP:[bp].RFIT_PREG ; Get its program region #
	 mov	 ah,PGROUP:[bx].SUMFIT_PREG ; Get command line value (if any)
	 mov	 AZS_FITLIN_PRG[di+1],' ' ; Assume they're the same

	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jnz	 short TRY_SUMFIT_PRGSAME ; Jump if so

	 cmp	 PGROUP:[bp].RFIT_PORD,0 ; Izit loaded low?
	 je	 short TRY_SUMFIT_PRGSAME ; Jump if so

	 cmp	 al,ah		; Izit the same as command line value?
	 je	 short TRY_SUMFIT_PRGSAME ; Jump if so

	 cmp	 ax,(@NOTSPEC shl 8) or 1 ; Izit not specified and PRGREG=1?
	 je	 short TRY_SUMFIT_PRGSAME ; Jump if so

	 mov	 AZS_FITLIN_PRG[di+1],'*' ; Mark as different
TRY_SUMFIT_PRGSAME:
	 call	 CNVAAM 	; Convert to decimal
				; AL = tens digit
				; AH = units ...
	 mov	 AZS_FITLIN_PRG.ELO[di-1],ax ; Save in display

; Display the environment region #s
; Mark as same if
;   * It's a device driver (no environment)
;   * A command line value is specified
;     and it is the same as the calculated value
;   * A command line value is not specified
;     and the calculated value is same as program region #

	 mov	 al,PGROUP:[bp].RFIT_EREG ; Get its environment region #
	 mov	 ah,PGROUP:[bx].SUMFIT_EREG ; Get command line value (if any)
	 mov	 AZS_FITLIN_ENV[di+1],' ' ; Assume they're the same

;;;;;;;  test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
;;;;;;;  jnz	 short TRY_SUMFIT_ENVSAME ; Jump if so
;;;;;;;
	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_DRV ; Izit a device driver?
	 jnz	 short TRY_SUMFIT_ENVSAME ; Jump if so (no environment)

	 cmp	 al,ah		; Izit the same as command line value?
	 je	 short TRY_SUMFIT_ENVSAME ; Jump if so

	 cmp	 ah,@NOTSPEC	; Izit not specified on the command line?
	 jne	 short @F	; Jump if not (it is specified)

	 cmp	 al,0		; Izit same as program region #?
	 je	 short TRY_SUMFIT_ENVSAME ; Jump if so

	 cmp	 al,PGROUP:[bp].RFIT_PREG ; Izit same as program region #?
	 je	 short TRY_SUMFIT_ENVSAME ; Jump if so
@@:
	 mov	 AZS_FITLIN_ENV[di+1],'*' ; Mark as different
TRY_SUMFIT_ENVSAME:
	 call	 CNVAAM 	; Convert to decimal
				; AL = tens digit
				; AH = units ...
	 mov	 AZS_FITLIN_ENV.ELO[di-1],ax ; Save in display
TRY_SUMFIT_NEXTORD_LOOP:

; Display the output

	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,AZS_FITLIN ; Write out the summary fit tail
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 call	 CHECK_LINE	; Count in another line and check for pause

if @OEM_HARPO
	 cmp	 PGROUP:[bx].SUMFIT_GRP,@GRPMAX ; Izit 386MAX?
	 jne	 short @F	; Jump if not

	 mov	 al,@SFO_MAX	; Display subsegments belonging to MAX
	 call	 DISP_SUBSEGS	; Display 'em

;;;;;;;  mov	 al,@SFO_WIN	; Display Windows instancing subsegs
;;;;;;;  call	 DISP_SUBSEGS	; Display 'em

@@:
	 mov	 ax,LASTDEV	; Get LSEG for last device driver
	 cmp	 PGROUP:[bx].SUMFIT_PARA,ax ; Is this it?
	 jne	 short @F	; Jump if not

	 mov	 al,@SFO_HARPO	; Subsegments belonging to HARPO
	 call	 DISP_SUBSEGS	; Display subsegs

@@:
endif				; IF @OEM_HARPO

	 add	 SUMFIT_OFF,type SUMFIT_STR ; Skip to next program entry
	 inc	 SUMFIT_NUM	; Count in another one

	 jmp	 TRY_SUMFIT_NEXT ; Go around again

TRY_SUMFIT_END:

; Clear the output save areas

	 mov	 cx,1		; CX = # areas to clear
	 lea	 si,PAZS_FITSIZ ; DS:SI ==> array of offsets
	 call	 SUMFIT_CLR	; Clear 'em

	 mov	 cx,1		; CX = # areas to clear
	 lea	 si,PAZS_FITAVL ; DS:SI ==> array of offsets
	 call	 SUMFIT_CLR	; Clear 'em

; Format the best size

	 mov	 ax,BESTSIZE	; Get the size in paras

	 and	 ax,ax		; Izit zero?
	 jz	 short TRY_SUMFIT_LOOPFIT ; Jump if so

	 cmp	 ax,TOPSIZE	; Save as larger
	 jbe	 short @F	; Jump if not better

	 mov	 TOPSIZE,ax	; Save as top size overall
@@:
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 mov	 di,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 di		; Pass as argument
	 mov	 di,PAZS_FITSIZ[0] ; ES:DI ==> output save area
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

; Calculate # available bytes

	 sub	 ax,TOTREGB.ELO ; Get total region size in bytes
	 sbb	 dx,TOTREGB.EHI
	 neg	 ax		; Negate to get positive #s
	 adc	 dx,0		; Compensate for two's-complement arithmetic
	 neg	 dx

	 mov	 di,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 di		; Pass as argument
	 mov	 di,PAZS_FITAVL[0] ; ES:DI ==> output save area
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI
TRY_SUMFIT_LOOPFIT:

; Did we find any fits?

	 cmp	 TOPSIZE,0	; Check against top size
	 jne	 short TRY_SUMFIT_XMT ; Jump if not empty

	 lea	 si,AZS_NOFIT1	; DS:SI ==> no fit message, line 1
	 mov	 cx,AZS_NOFIT1LEN ; CX = length of ...
	 lea	 di,AZS_FITSIZ1+1-AZS_NOFIT1LEN ; ES:DI ==>
     rep movsb			; Copy to output area

	 lea	 si,AZS_NOFIT2	; DS:SI ==> no fit message, line 2
	 mov	 cx,AZS_NOFIT2LEN ; CX = length of ...
	 lea	 di,AZS_FITAVL1+1-AZS_NOFIT2LEN ; ES:DI ==>
     rep movsb			; Copy to output area
TRY_SUMFIT_XMT:

; Display the summary fit tail

	 lea	 si,PAZS_FITTAIL ; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_FITTAIL ; CX = # strings to display
	 call	 DISP_ASCIIZMUL ; Display multiple lines

	 public  TRY_SUMFIT_DBG
TRY_SUMFIT_DBG:
	 cmp	 DBG_FLAG,0	; Izit util/sid or util/srd?
	MJ e	 TRY_SUMFIT_XDBG ; Jump if not

; Display debug header

	 lea	 si,PAZS_DBGHEAD ; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_DBGHEAD ; CX = # strings to display
	 call	 DISP_ASCIIZMUL ; Display multiple lines

; Calculate starting MAC para for each region

	 REGSAVE <es>		; Save

	 mov	 cx,NREGS	; Number of regions
	 sub	 di,di		; Index REGSPAN[] and REGSTART[]
	 mov	 ax,POVR_MAC	; Start of region 1
TRY_SUMFIT_GETSTART:
	 mov	 REGSTART[di],ax ; Save start of region
	 mov	 ax,REGSPAN[di] ; Get segment of spanning entry
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 inc	 ax		; Skip MAC entry
; For the last region, set REGSPAN to the first paragraph past the end.
	 cmp	 cx,1		; Izit the last region?
	 jne	 short @F	; Jump if not

	 mov	 REGSPAN[di],ax ; Save as end of region
@@:
	 add	 ax,es:[0].MAC_NPAR ; Get start of next region

	 add	 di,type REGSTART ; Update index

	 loop	 TRY_SUMFIT_GETSTART ; Do next region

if @OEM_HARPO
; Set LASTDEV to the last device loaded high or MAX (even if low).
	 mov	 ax,LOADSEG	; Get the segment of the start of the chain

; Find the LSEG segment for the last driver.  That's where we'll display
; the subsegment info.
	 mov	 LASTDEV,ax	; Save a default value (should be MAX)

	 mov	 bx,PSUMFIT_TAB ; PGROUP:BX ==> SUMFIT_TAB
DBG_SUMFIT_FINDLAST:
	 mov	 ax,PGROUP:[bx].SUMFIT_PARA ; Get LSEG paragraph
	 or	 ax,ax		; Izit the end of the SUMFIT list?
	 jz	 short DBG_SUMFIT_FOUNDLAST ; Jump if so

	 mov	 es,ax		; Address LSEG
	 assume  es:nothing	; Tell the assembler

	 test	 es:[0].LSEG_FLAG,@LSEG_DRV ; Izit a device driver?
	 jz	 short DBG_SUMFIT_FOUNDLAST ; Jump if not

	 cmp	 PGROUP:[bx].SUMFIT_PREG,0 ; Is this one going low?
	 je	 short @F	; Jump if so

	 mov	 LASTDEV,es	; Save segment of last driver
@@:
	 add	 bx,size SUMFIT_STR ; Skip to next entry
	 jmp	 short DBG_SUMFIT_FINDLAST ; Go around again

DBG_SUMFIT_FOUNDLAST:
endif				; IF @OEM_HARPO

	 REGREST <es>		; Restore
	 assume  es:PGROUP	; Tell the assembler

	 mov	 CURREG,0	; Starting region

; Get start of this region
DBG_SUMFIT_NEXTREG:
	 mov	 di,CURREG	; Get REGTAB index (origin:0)
	 shl	 di,1-0 	; Convert to word index

	 mov	 ax,REGSTART[di] ; Get start of region
	 mov	 STARTPARA,ax	; Save starting paragraph
	 mov	 cx,REGSPAN[di] ; Get end of available space
	 sub	 cx,ax		; Get total free space for region
	 mov	 REGRFREE,cx	; Set unused space
	 add	 cx,REGEMS[di]	; Add FLEXFRAME memory (if any)
	 mov	 REGIFREE,cx	; Set unused initialization space
	 mov	 REGILEN,0	; Set largest initialization size

; Display group header

	 lea	 si,PAZS_DBGGROUP ; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_DBGGROUP ; CX = # strings to display
	 call	 DISP_ASCIIZMUL ; Display multiple lines

	 mov	 CDBGORD,1	; Starting order
	 mov	 DISPRSUB,0	; No subsegments processed yet
DBG_SUMFIT_NEXTORD:
	 mov	 SUMFIT_OFF,0	; Initialize the offset into SUMFIT_TAB
	 mov	 SUMFIT_NUM,0	; Initialize SUMFIT #
DBG_SUMFIT_NEXT:
	 mov	 bx,SUMFIT_OFF	; Get the offset into SUMFIT_TAB
	 add	 bx,PSUMFIT_TAB ; Plus start of table

; Get the LSEG entry

	 mov	 ax,PGROUP:[bx].SUMFIT_PARA ; LSEG segment or 0 if no more
	 mov	 CURSEG,ax	; Save as current segment
	 or	 ax,ax		; Is this the end?
	 jnz	 short DBG_SUMFIT_ORDOK ; Jump if not

	 cmp	 BESTSIZE,0	; Izit being used?
	 je	 short @F	; Jump if not

	 mov	 ax,CDBGORD	; Get current order
	 inc	 ax		; Update it
	 mov	 CDBGORD,ax	; Save
	 cmp	 ax,NPROGS	; Have we done them all?
	 jbe	 short DBG_SUMFIT_NEXTORD ; Jump if not
@@:
	 jmp	 DBG_SUMFIT_END ; End of region

DBG_SUMFIT_ORDOK:
; Check to see if it's the current order
	 cmp	 BESTSIZE,0	; Izit being used?
	 je	 short DBG_SUMFIT_ORDOK2 ; Jump if not

	 mov	 di,PBTOPFIT	; PGROUP:DI ==> TOPFIT[0;]
	 mov	 al,type RFIT_STR ; Get size of RFIT structure
	 mul	 SUMFIT_NUM.LO	; Times program #
	 add	 di,ax		; PGROUP:DI ==> TOPFIT[0;J]

	 mov	 al,PGROUP:[di].RFIT_PORD ; Get its order #
	 cmp	 al,CDBGORD.LO	; Izit the one we want?
	 je	 short DBG_SUMFIT_ORDOK2 ; Jump if so

	 jmp	 DBG_SUMFIT_LOOP ; Process next program

DBG_SUMFIT_ORDOK2:
if @OEM_HARPO
; Check for LASTDEV
	 test	 DISPRSUB,@DISPR_LASTDEV ; Have we found LASTDEV?
	 jnz	 short @F	; Jump if so

	 mov	 ax,CURSEG	; Get LSEG segment
	 cmp	 ax,LASTDEV	; Izit LASTDEV?
	 jne	 short @F	; Jump if not

	 or	 DISPRSUB,@DISPR_LASTDEV ; Mark as found
@@:
endif				; IF @OEM_HARPO
; Determine current type
	 mov	 ax,@DBGTYPE_MAX ; Assume it's 386MAX
	 cmp	 PGROUP:[bx].SUMFIT_GRP,@GRPMAX ; Izit?
	 je	 short DBG_SUMFIT_TYPE ; Jump if so

	 mov	 ax,@DBGTYPE_DEV ; Assume DEVICE= 386load.sys
	 mov	 cx,PGROUP:[bx].SUMFIT_FLAG ; Get LSEG flags
	 test	 cx,@LSEG_DRV	; Izit a device driver?
	 jnz	 short DBG_SUMFIT_TYPE ; Jump if so

	 mov	 ax,@DBGTYPE_INST ; Assume INSTALL= 386load.com
	 test	 cx,@LSEG_INST	; Izit INSTALL=?
	 jnz	 short DBG_SUMFIT_TYPE ; Jump if so

	 mov	 ax,@DBGTYPE_UMB ; Assume it's a UMB
	 test	 cx,@LSEG_UMB	; Izit a UMB?
	 jnz	 short DBG_SUMFIT_TYPE ; Jump if so

	 mov	 ax,@DBGTYPE_TSR ; Assume it's 386LOAD.COM
DBG_SUMFIT_TYPE:
; AX = new value for DBGTYPE.
	 mov	 DBGTYPE,ax	; Save current type

DBG_SUMFIT_SSCOM:
	 mov	 di,PBTOPFIT	; PGROUP:DI ==> TOPFIT[0;]
	 mov	 al,type RFIT_STR ; Get size of RFIT structure
	 mul	 SUMFIT_NUM.LO	; Times program #
	 add	 di,ax		; PGROUP:DI ==> TOPFIT[0;J]

if @OEM_HARPO
	 mov	 al,PGROUP:[bx].SUMFIT_PREG ; Get subsegment program region
	 cmp	 DBGTYPE,@DBGTYPE_MAXSUB ; Izit a MAX subsegment?
	 je	 short DBG_SUMFIT_CMPREG ; Jump if so

	 cmp	 DBGTYPE,@DBGTYPE_SUB ; Izit an ExtraDOS subsegment?
	 je	 short DBG_SUMFIT_CMPREG ; Jump if so
endif				; IF @OEM_HARPO

	 mov	 al,PGROUP:[di].RFIT_PREG ; Get program region
	 cmp	 DBGTYPE,@DBGTYPE_ENV ; Izit the environment we want?
	 jne	 short DBG_SUMFIT_CMPREG ; Jump if not

	 mov	 al,PGROUP:[di].RFIT_EREG ; Get environment region
; FIXME We should use @NOTSPEC for RFIT_EREG, since it's OK to load the
; environment low.
;;;;;;	 cmp	 al,@NOTSPEC	; Izit same as PRGREG?
	 cmp	 al,0		; Izit same as PRGREG?
	 jne	 short DBG_SUMFIT_CMPREG ; Jump if not

	 mov	 al,PGROUP:[di].RFIT_PREG ; Use program region
DBG_SUMFIT_CMPREG:
	 dec	 al		; Convert to origin:0
	 mov	 ah,CURREG.LO	; Get current region for comparison

	 cmp	 al,ah		; Is this the right region?
	 je	 short DBG_SUMFIT_DISP ; Jump if so

	 or	 ah,ah		; Is this the first region?
	 jnz	 short @F	; Jump if not

	 cmp	 al,(@NOTSPEC-1) ; If unspecified, use first region
	 je	 short DBG_SUMFIT_DISP ; Jump if so

@@:
	 jmp	 DBG_SUMFIT_LOOP ; Skip this one

DBG_SUMFIT_DISP:
; Copy the filename.ext

if @OEM_HARPO
	 mov	 dl,@SFO_MAX	; Owner to check for
	 cmp	 DBGTYPE,@DBGTYPE_MAXSUB ; Izit MAX subsegments?
	 je	 short @F	; Jump if so

	 mov	 dl,@SFO_HARPO	; Owner to check for
	 cmp	 DBGTYPE,@DBGTYPE_SUB ; Izit other subsegments?
	 jne	 short DBG_SUMFIT_DISPLSEG ; Jump if not

@@:
	 mov	 ax,PGROUP:[bx].SUMFIT_FLAG ; Get flags
	 and	 ax,mask $SFLAG_OWNR ; Isolate owner bits
	 mov	 cl,$SFLAG_OWNR ; Convert to a value
	 shr	 ax,cl		; AL = @SFO_???

	 cmp	 al,dl		; Izit the one we want?
	MJ ne	 DBG_SUMFIT_LOOP ; Jump if not

	 mov	 ah,al		; Save for comparison
	 mov	 al,PGROUP:[bx].SUMFIT_GRP ; Get type letter
	 lea	 di,SUBSID_TAB	; Address subsegment ID table
	 mov	 cx,@NSUBSIDS	; Number of possible choices
DBG_SUMFIT_NEXTSID:
	 cmp	 ah,PGROUP:[di].SUBSID_OWNR ; Izit the right owner?
	 jne	 short @F	; Jump if not

	 cmp	 ah,dl		; Izit the current one?
	 jne	 short @F	; Jump if not

	 cmp	 al,PGROUP:[di].SUBSID_TYP ; Izit the one we're looking for?
	 je	 short DBG_SUMFIT_GOTSID ; Jump if so

@@:
	 add	 di,size SUBSID_STR ; Skip to next
	 loop	 DBG_SUMFIT_NEXTSID ; Go around again

DBG_SUMFIT_GOTSID:
; PGROUP:DI ==> SUBSID_STR
	 mov	 si,PGROUP:[di].SUBSID_PTXT ; PGROUP:SI ==> text
	 lea	 di,AZS_DBGFNE	; PGROUP:DI ==> output save area
	 mov	 cx,@SUBSID_TXTLEN ; Length of subsegment name
  rep	 movs	 PGROUP:[si].LO,AZS_DBGFNE[di] ; Copy subseg name
	 jmp	 short DBG_SUMFIT_FMTLINE ; Join common code

DBG_SUMFIT_DISPLSEG:
endif				; IF @OEM_HARPO

	 REGSAVE <ds>		; Save for a moment

	 mov	 ds,CURSEG	; Get the current segment
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 si,ds:[0].LSEG_FNE ; DS:SI ==> "filename.ext"
	 lea	 di,AZS_DBGFNE	; ES:DI ==> output save area
	 mov	 cx,size LSEG_FNE ; CX = # bytes to copy
     rep movsb			; Copy to local area

	 REGREST <ds>		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

DBG_SUMFIT_FMTLINE:
; Format the line

	 mov	 cx,NAZS_DBGLIN ; CX = # areas to clear
	 lea	 si,PAZS_DBGLIN ; DS:SI ==> array of offsets to clear
	 call	 SUMFIT_CLR	; Clear 'em

; Display type (Device, INSTALL, TSR, env, UMB, subsegment)

	 lea	 si,DBGTLBL	; Address list of type labels
	 mov	 ax,DBGTYPE	; Get current type
	 mov	 cx,@DBGTLBL_LEN ; Get length of each element
	 mul	 cl		; AX = offset of current label
	 add	 si,ax		; PGROUP:SI ==> label to copy
	 lea	 di,AZS_DBGTYPE ; ES:DI ==> output field
   rep	 movs	 DBGTLBL[si],AZS_DBGTYPE[di] ; Copy text

; Display the start of this program

	 mov	 ax,STARTPARA	; Get starting paragraph
	 lea	 di,AZS_DBGSTART ; ES:DI ==> output save area
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

; Display the maximum program size including MAC paragraph (NPARA,
; which includes its MAC para, is included in SUMFIT_IPARA).

	 mov	 ax,PGROUP:[bx].SUMFIT_IPARA ; Get # paras needed to install
	 inc	 ax		; Count MAC paragraph
	 cmp	 DBGTYPE,@DBGTYPE_ENV ; Izit 386LOAD environment?
	 jne	 short @F	; Jump if not

	 mov	 ax,PGROUP:[bx].SUMFIT_EPAR0 ; Get initial env size (including
				; MAC entry)
@@:
	 push	 ax		; Save initialization size

	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 lea	 di,AZS_DBGISIZE ; ES:DI ==> output save area
	 mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

	 pop	 ax		; Restore

; Display end of initialization size

	 mov	 di,CURREG	; Get REGTAB index (origin:0)
	 shl	 di,1-0 	; Convert to word index
	 add	 ax,STARTPARA	; Add starting address
	 sub	 ax,REGSTART[di] ; Subtract start of region
	 cmp	 ax,REGILEN	; Izit larger than the biggest init size so far?
	 jbe	 short @F	; Jump if not

	 mov	 REGILEN,ax	; Save high water mark
@@:
	 add	 ax,REGSTART[di] ; Add region start to get ending address
	 lea	 di,AZS_DBGIEND ; ES:DI ==> output save area
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

; Display resident size
	 mov	 ax,PGROUP:[bx].SUMFIT_RPARA ; Get resident paragraphs
	 inc	 ax		; Add MAC paragraph
	 cmp	 DBGTYPE,@DBGTYPE_ENV ; Izit 386LOAD environment?
	 jne	 short @F	; Jump if not

	 mov	 ax,PGROUP:[bx].SUMFIT_EPAR1 ; Get resident environment size,
				; including MAC paragraph
@@:
	 sub	 REGRFREE,ax	; Subtract from available space
	 add	 STARTPARA,ax	; Update starting address
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 lea	 di,AZS_DBGRSIZE ; ES:DI ==> output save area
	 mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

; Display ending resident address
	 mov	 ax,STARTPARA	; Get ending address
	 lea	 di,AZS_DBGREND ; ES:DI ==> output save area
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

; Display the output

	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,AZS_DBGLIN	; Write out the debug line
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 call	 CHECK_LINE	; Count in another line and check for pause

DBG_SUMFIT_LOOP:
	 cmp	 DBGTYPE,@DBGTYPE_TSR ; Izit a 386LOADed program?
	 jne	 short @F	; Jump if not

	 mov	 ax,@DBGTYPE_ENV ; Try the environment
	 jmp	 DBG_SUMFIT_TYPE ; Go around again

@@:
if @OEM_HARPO
	 cmp	 DBGTYPE,@DBGTYPE_MAXSUB ; Izit a 386MAX subseg?
	 je	 short DBG_SUMFIT_LOOPSUB ; Jump if so

	 cmp	 DBGTYPE,@DBGTYPE_SUB ; Izit an ExtraDOS subseg?
	 jne	 short DBG_SUMFIT_LOOP2 ; Jump if not

DBG_SUMFIT_LOOPSUB:
	 add	 SUBSEG_OFF,type SUMFIT_STR ; Skip to next subsegment
DBG_SUMFIT_NEXTSUB:
	 mov	 bx,SUBSEG_OFF	; Get offset into SUBSEG_TAB
	 add	 bx,PSUBSEG_TAB ; Plus start of table

	 cmp	 PGROUP:[bx].SUMFIT_PARA,0 ; Izit the end of the subsegs?
	MJ ne	 DBG_SUMFIT_SSCOM ; Jump if not

; Check for case where MAX.SYS is also the last device
	 mov	 bx,SUMFIT_OFF	; Get the offset into SUMFIT_TAB
	 add	 bx,PSUMFIT_TAB ; Plus start of table

	 cmp	 DBGTYPE,@DBGTYPE_MAXSUB ; Did we just do MAX subsegments?
	 mov	 DBGTYPE,@DBGTYPE_DEV ; We're no longer doing subsegs
	 je	 short DBG_SUMFIT_CHECKLAST ; Jump if so - check for LASTDEV

	 jmp	 DBG_SUMFIT_NEXT ; Resume processing programs

DBG_SUMFIT_LOOP2:
endif				; IF @OEM_HARPO

	 mov	 bx,SUMFIT_OFF	; Get the offset into SUMFIT_TAB
	 add	 bx,PSUMFIT_TAB ; Plus start of table

	 add	 SUMFIT_OFF,type SUMFIT_STR ; Skip to next program entry
	 inc	 SUMFIT_NUM	; Count in another one

if @OEM_HARPO
	 cmp	 PGROUP:[bx].SUMFIT_GRP,@GRPMAX ; Have we done 386MAX?
	 jne	 short DBG_SUMFIT_CHECKLAST ; Jump if not

	 test	 DISPRSUB,@DISPR_MAXSUB ; Have we displayed MAX subsegs?
	 jnz	 short DBG_SUMFIT_CHECKLAST ; Jump if so

	 or	 DISPRSUB,@DISPR_MAXSUB ; Mark as processed
	 mov	 DBGTYPE,@DBGTYPE_MAXSUB ; Process 386MAX subsegments
	 mov	 SUBSEG_OFF,0	; Start with beginning subsegment
	 jmp	 short DBG_SUMFIT_NEXTSUB ; Join common code

DBG_SUMFIT_CHECKLAST:
	 test	 DISPRSUB,@DISPR_LASTDEV ; Have we encountered LASTDEV?
	 jz	 short @F	; Jump if not

	 test	 DISPRSUB,@DISPR_SUB ; Did we display subsegs yet?
	 jnz	 short @F	; Jump if so

	 or	 DISPRSUB,@DISPR_SUB ; Mark as processed
	 mov	 DBGTYPE,@DBGTYPE_SUB ; Process subsegments
	 mov	 SUBSEG_OFF,0	; Start with beginning subsegment
	 jmp	 short DBG_SUMFIT_NEXTSUB ; Join common code
@@:
endif				; IF @OEM_HARPO

	 jmp	 DBG_SUMFIT_NEXT ; Go around again

DBG_SUMFIT_END:
; Display space remaining in region

	 lea	 si,FREELBL	; PGROUP:SI ==> ' - avail - '
	 lea	 di,AZS_DBGFNE	; ES:DI ==> output save area
	 mov	 cx,@FREELBL_LEN ; CX = # bytes to copy
     rep movs	 FREELBL[si],AZS_DBGFNE[di] ; Copy to local area

; Clear type field

	 mov	 cx,@DBGTLBL_LEN ; Get length of output field
	 lea	 di,AZS_DBGTYPE ; ES:DI ==> output field
	 mov	 al,' '         ; Clear it
   rep	 stos	 AZS_DBGTYPE[di] ; Set to all blanks

; Display the start of free space

	 mov	 cx,NAZS_DBGLIN ; CX = # areas to clear
	 lea	 si,PAZS_DBGLIN ; DS:SI ==> array of offsets to clear
	 call	 SUMFIT_CLR	; Clear 'em

	 mov	 ax,STARTPARA	; Get starting paragraph
	 lea	 di,AZS_DBGSTART ; ES:DI ==> output save area
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

; We're displaying the top of the initialization space here, although
; the starting address for this line is actually the high water mark.
	 mov	 di,CURREG	; Get current region
	 shl	 di,1-0 	; Convert to word index
	 mov	 ax,REGSTART[di] ; Get start of region
	 add	 ax,REGIFREE	; Get end of initialization space
	 lea	 di,AZS_DBGIEND ; ES:DI ==> output save area
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 mov	 ax,REGIFREE	; Get available space for initialization
	 sub	 ax,REGILEN	; Subtract high water mark
	 jnc	 short @F	; Jump if no underflow

	 sub	 ax,ax		; Display as 0
@@:
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 lea	 di,AZS_DBGISIZE ; ES:DI ==> output save area
	 mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

	 mov	 ax,REGRFREE	; Get unused resident space
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 lea	 di,AZS_DBGRSIZE ; ES:DI ==> output save area
	 mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

; Display ending resident address
	 mov	 ax,STARTPARA	; Get starting address
	 add	 ax,REGRFREE	; Get end of free space (end of region)
	 lea	 di,AZS_DBGREND ; ES:DI ==> output save area
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

; Display the output

	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,AZS_DBGLIN	; Write out the debug line
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 call	 CHECK_LINE	; Count in another line and check for pause


	 inc	 CURREG 	; Update current region count
	 mov	 ax,CURREG	; Get current region (origin:0)
	 cmp	 ax,NREGS	; Is this the last one?
	MJ b	 DBG_SUMFIT_NEXTREG ; Jump if not

; Display debug tail

	 lea	 si,PAZS_DBGTAIL ; DS:SI ==> array of offsets of strings
	 mov	 cx,NAZS_DBGTAIL ; CX = # strings to display
	 call	 DISP_ASCIIZMUL ; Display multiple lines

TRY_SUMFIT_XDBG:
; De-allocate room for top fits

	 FCALL	 RLS_TOPFIT	; Release it

	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,ss:nothing

TRY_SUMFIT endp 		; End TRY_SUMFIT procedure
endif				; IFDEF OPTIM
	 NPPROC  SUMFIT_CLR -- Clear Output Save Areas
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Clear output save areas

On entry:

DS:SI	 ==>	 array of offsets to clear
CX	 =	 # areas to clear

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 push	 ds		; Setup ES for STOS
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it
SUMFIT_NEXTCLR:
	 push	 cx		; Save for a moment

	 lodsw			; Get next offset
	 mov	 di,ax		; ES:DI ==> ending byte of area to clear
	 lodsw			; Get its length
	 mov	 cx,ax		; CX = length
	 sub	 di,cx		; Back off by length to first-1
	 inc	 di		; ES:DI ==> start of area to clear
	 mov	 al,' '         ; Fill with this
     rep stosb			; Clear it

	 pop	 cx		; Restore

	 loop	 SUMFIT_NEXTCLR ; Jump if more areas to clear

	 REGREST <es,di,si,cx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SUMFIT_CLR endp 		; End SUMFIT_CLR procedure
	 NPPROC  DISP_ASCIIZMUL -- Display Multiple ASCIIZ Strings
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Display multiple ASCIIZ strings.

On entry:

DS:SI	 ==>	 array of ASCIIZ strings
CX	 =	 # strings in table

|

	 REGSAVE <ax,cx,si>	; Save registers
@@:
	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lodsw			; Get next offset
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 call	 CHECK_LINE	; Count in another line and check for pause

	 loop	 @B		; Jump if more tails to write

	 REGREST <si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_ASCIIZMUL endp		; End DISP_ASCIIZMUL procedure
ifdef OPTIM
	 NPPROC  CNVAAM -- Convert To Decimal Via AAM
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert to decimal.  We used to use the AAM instruction here
(hence the name of the routine) but there was a bug in early
steppings of the 486 which broke the AAM instruction, so I
recoded it.

On entry:

AL	 =	 byte to convert

On exit:

AL	 =	 tens digit in ASCII
AH	 =	 units ...

|

	 push	 bx		; Save for a moment

	 mov	 bl,10		; Divisor
	 mov	 ah,0		; Zero high-order byte of dividend
	 div	 bl		; Convert to AL = tens digit
				;	     AH = units
	 add	 ax,'00'        ; Convert to ASCII

	 cmp	 al,'0'         ; Check for leading zero
	 jne	 short @F	; Jump if not

	 mov	 al,' '         ; Blank it

	 cmp	 ah,'0'         ; Check for trailing zero
	 jne	 short @F	; Jump if not

	 mov	 ah,' '         ; Blank it
@@:
	 pop	 bx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CNVAAM	 endp			; End CNVAAM procedure
endif				; IFDEF OPTIM

UCODE	 ends			; End UCODE segment

	 MEND			; End UTIL_SUM module

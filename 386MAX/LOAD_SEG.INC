;' $Header:   P:/PVCS/MAX/386MAX/LOAD_SEG.INV   1.0   11 Aug 1995 10:56:04   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	All rights reserved.
;
; LOAD_SEG.INC
;
; LSEG_STR structure
;

COMMENT|

Notes on Groups:

* @GRP_SUBSEG has a fixed loading order and a variable program size.
  This region may contain one or more of the following...
  FILES,BUFFERS,STACKS,FCBS, or LASTDRV.
* @GRP_HIPROG has a fixed loading order and may be one of the following...
  SHARE.EXE (DOS 4), COMMAND.COM, or the master environment.

|

@GRPMAX  equ	 -1		; Group # for 386MAX
@GRPUMB  equ	 -2		; Group # for UMBs
@GRP_SUBSEG equ  -3		; DOS Sub-segments loaded High via HARPO
@GRP_HIPROG equ  -4		; Program is loaded High via HARPO
@NOTSPEC equ	 -1		; Region # not specified (PRG & ENV)

COMMENT|

Notes on LSEG_STR:

* RPARA and RPAR2 do NOT count in their MAC paragraph
* RPARA and RPAR2 count in their interrupt block and MAC paragraph
* EPAR0 and EPAR1 count in their MAC paragraph
* ASIZE, ISIZE, and LSIZE count in the PSP (if present)
* ASIZE, ISIZE, and LSIZE do NOT count in the interrupt block
* NPARA counts in its MAC paragraph

|

LSEG_STR struc

LSEG_NEXT  dw	 -1		; 00-01:  Pointer to next LSEG_STR (-1 if last)
LSEG_PREV  dw	 -1		; 02-03:  Pointer to prev LSEG_STR (-1 if first)
LSEG_FNE   db	 12 dup (' ')   ; 04-0F:  File/device name/drive
LSEG_RPARA dw	 0		; 10-11:  Resident size in paras
				; For UMBs, LSEG_EPAR0 is the size in paras to
				; try to allocate.
LSEG_EPAR0 dw	 0		; 12-13:  Environment size in paras (before)
				; For UMBs, LSEG_EPAR1 contains two subfields
				; described below.
LSEG_EPAR1 dw	 0		; 14-15:  ...			    (after)
LSEG_RPAR2 dw	 0		; 16-17:  Forced resident size in paras if SIZE=n,n
LSEG_ASIZE dd	 0		; 18-1B:  Actual SIZE= used in bytes
LSEG_LSIZE dd	 0		; 1C-1F:  Load size in bytes
LSEG_ISIZE dd	 0		; 20-23:  Intialization size in bytes
LSEG_PREG  db	 @NOTSPEC	; 24-24:  Program region #
LSEG_EREG  db	 @NOTSPEC	; 25-25:  Environment ...
				; The following field *MUST* be on word boundary
LSEG_FLAG  dw	 0		; 26-27:  Flags (see below)
LSEG_NPARA dw	 ?		; 28-29:  Interrupt block in paras
LSEG_GRP   db	 0		; 2A-2A:  Group # (0=none specified, -1=386MAX)
LSEG2_FLAG db	 0		; 2B-2B:  Secondary flags (see below)
LSEG_OWNRHI dw	 ?		; 2C-2D:  Segment of owner in high DOS (0=none)
LSEG_INSTLO dw	 ?		; 2E-2F:  Segment of low DOS to instance
LSEG_INSTLEN dw  0		; 30-31:  Length in paras of LSEG_INSTLO (0=none)

LSEG_STR ends

; Note that this order *MUST* match the order in MAXIMIZE's QUALITAS.H
; and that the bit fields there are defined as

LSEG_FLAGREC record $LSEG_UMB:1,$LSEG_STRA:2,$LSEG_LSIZ:1,\
	$LSEG_IMAX:1,$LSEG_XRES:1,$LSEG_INFLEX:1,$LSEG_INPRO:1,\
	$LSEG_WINST:1,$LSEG_DRV:1,$LSEG_FSIZ:1,$LSEG_XEMS:1,\
	$LSEG_XLHI:1,$LSEG_GSIZE:1,$LSEG_INST:1,$LSEG_FLEX:1;

@LSEG_FLEX  equ  mask $LSEG_FLEX ; 0001: Allows FLEXFRAME
@LSEG_INST  equ  mask $LSEG_INST ; 0002: Called via DOS 4.x INSTALL=
@LSEG_GSIZE equ  mask $LSEG_GSIZE ; 0004: Forced GETSIZE if no room in high DOS
@LSEG_XLHI  equ  mask $LSEG_XLHI ; 0008: NOLOADHI on 386MAX line
@LSEG_XEMS  equ  mask $LSEG_XEMS ; 0010: EMS error during FLEXFRAME
@LSEG_FSIZ  equ  mask $LSEG_FSIZ ; 0020: Forced resident SIZE= present
@LSEG_DRV   equ  mask $LSEG_DRV ; 0040: This is a device driver
@LSEG_WINST equ  mask $LSEG_WINST ; 0080: Please instance me under Windows
@LSEG_INPRO equ  mask $LSEG_INPRO ; 0100: 386LOAD/HARPO in progress
@LSEG_INFLEX equ mask $LSEG_INFLEX ; 0200: FLEXFRAME used by this program
@LSEG_XRES  equ  mask $LSEG_XRES ; 0400: Program did not go resident
@LSEG_IMAX  equ  mask $LSEG_IMAX ; 0800: Initial allocation was for maximum (UMB only)
@LSEG_LSIZ  equ  mask $LSEG_LSIZ ; 1000: Load size > initialization size:  force SIZE=
@LSEG_STRA equ	 mask $LSEG_STRA ; 6000: Strategy used for allocation:
@LSS_FIRST equ	 0		; First fit
@LSS_BEST equ	 1		; Best fit
@LSS_LAST equ	 2		; Last fit
@LSEG_UMB equ	 mask $LSEG_UMB ; 8000: One or more UMBs allocated: let it load itself high

; These flags are not available for use by Maximize; there's no
; room for them in SUMFIT_STR.

LSEG2_FLAGREC record $LSEG2_RSVD:6,$LSEG2_FISIZE:1,$LSEG2_NOV:1;

@LSEG2_NOV equ	 mask $LSEG2_NOV ; 01: Possible 4B UMB from NETX
@LSEG2_FISIZE equ mask $LSEG2_FISIZE ; 02: Fixed initialization size

@LSEGPARA equ	 ((16-1)+(size LSEG_STR))/16 ; Size of LSEG_STR in paras

; Subfields for LSEG_EPAR1, for UMBs only.
; *PINST is a bitmap, with bits 11-0 corresponding to the previous LSEG,
; its predecessor, and so on back to the last 4B LSEG.	1 indicates that
; RPARA*10 == ISIZE in the corresponding LSEG at the time this LSEG was
; allocated and @LSEG_IMAX was not previously set.  If @LSEG_IMAX is set
; when the bitmap is constructed, the bit is also set along with $EP1UIMAX.
; *PSP is set if the LSEG was created by a 4B PSP.  We don't care about the
; environment- even if it's deleted and creates a hole it's not *LIKELY* to
; affect the placement of the PSP.  Besides, sometimes the environment LSEG
; will come after the PSP LSEG in the chain anyway.  In the optimization
; algorithm, we can then walk backwards from the current LSEG looking for
; UMB LSEGs.  If the corresponding bit (bit 11 for the immediate predecessor,
; bit 10 for its predecessor, and so on) is set, we'll treat that LSEG's
; initialization size as allocated.
; *PREV indicates that the bitmap is not empty.  This saves some time in the
; optimization algorithm.
; *IMAX indicates that at some point, @LSEG_IMAX was set.  This tells us
; when we find this LSEG in an ancestor bitmap that it occupies all the
; space in its region regardless of LSEG_ISIZE.
; *DLGHI indicates that there was no space in low DOS for DLGROUP.  When
; this occurs, the optimization algorithm must subtract DLGROUP from
; space available to all UMBs that have this PSP in their ancestor bitmap.
LSEG_EPAR1UMB record $LSEG_EP1UPSP:1,$LSEG_EP1UPREV:1,$LSEG_EP1UIMAX:1,\
		$LSEG_EP1UDLGHI:1,\
		$LSEG_EP1UPINST:12;


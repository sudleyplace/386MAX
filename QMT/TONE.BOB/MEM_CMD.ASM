;' $Header:   P:/PVCS/MAX/QMT/MEM_CMD.ASV   1.1   05 Jun 1998 14:03:20   BOB  $
	 title	 MEM_CMD -- MEMCHK Command Argument Routines
	 page	 58,122
	 name	 MEM_CMD

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include MAXDEV.INC
	 include INTRNATL.INC
	 include 386.INC
	 include VCPI.INC

	 include MEM_OEM.INC
	 include MEM_SCRN.INC
	include MEM_SEGS.INC
.list

CMDARG_MAC macro TXT,ACT,XDISP
	 local	 LCL_TXT,LCL_LEN

NDATA	 segment use16 dword public 'data' ; Start NDATA segment
	 assume  ds:DGROUP

LCL_TXT  db	 TXT
LCL_LEN  equ	 $-LCL_TXT
ifb <XDISP>
	 db	 0		; OK to display this option in ASK box
else
	 db	 XDISP		; Exclude / don't exclude from ASK box
endif				; IFB XDISP

NDATA	 ends			; End NDATA segment


SEG_LEN  segment use16 word public 'data' ; Start SEG_LEN segment
	 assume  ds:DGROUP

	 dw	 LCL_LEN

SEG_LEN  ends			; End SEG_LEN segment


SEG_TAB  segment use16 word public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	 dw	 DGROUP:LCL_TXT

SEG_TAB  ends			; End SEG_TAB segment


SEG_ACT  segment use16 word public 'data' ; Start SEG_ACT segment
	 assume  ds:DGROUP

	 dw	 PGROUP:ACT

SEG_ACT  ends			; End SEG_ACT segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 ACT:near

CODE	 ends			; End CODE segment

	 endm			; CMDARG_MAC


PGROUP	 group	 CODE
DGROUP	 group	 DATA,NDATA,SEG_TAB,SEG_LEN,SEG_ACT,IDENT
PSPGRP	 group	 PSP_SEG


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 GLB_FLAG:word
	 include MEM_GLB.INC

	 extrn	 GL2_FLAG:word
	 include MEM_GL2.INC

	 extrn	 CODESEG:word
	 extrn	 PSPSEG:word

	 extrn	 MSG_UNK:byte

	 extrn	 DATESEP:byte
	 extrn	 TIMESEP:byte

	public	CMD_FLAG
	include MEM_CMD.INC
CMD_FLAG dd	@CMD_EPM	; Command flags (default=use our own EPM routine)

ifdef @BETA			; Are we building BETA version ??
	 public  DBG_FLAG
	 include MEM_DBG.INC
DBG_FLAG dw	 0		; Debugging flags
endif				; IFDEF @BETA

	 public  QMTLOGPATH,SAV_ASKCMDOPT,@LEN_ASKCMDOPT
	public	QMTTONEPATH
QMTLOGPATH db	 128 dup (0)	; Complete path of log file
QMTTONEPATH db	 128 dup (0)	; ...		   tone ...
SAV_ASKCMDOPT db 45 dup (0)	; Options to display in ASK dialog box
@LEN_ASKCMDOPT equ $-SAV_ASKCMDOPT ; Maximum length to save

if (@NATL_TIME EQ @NATL_TIME12)
	 public  TIMEPREFIX
TIMEPREFIX dw	 'MA','MP'      ; AM and PM
endif				; IF 12-hour time format (US)

	 public  QMTDIR,QMT_STEM
QMTDIR db	 128 dup (0)	; Complete path (c:\qmt\qmt.exe)
QMT_STEM dw	 ?		; Length of drive:dir (c:\qmt\)

ifdef @RAMEXAM			; .DAT file only for RAMEXAM
azDATFileName db PUNAME,'.DAT'  ; Name of .DAT file
@lDATFileName equ ($ - azDATFileName)+1 ; Get length
endif ; @RAMEXAM

DATA	 ends			; End DATA segment


IDENT	 segment use16 dword public 'dataz' ; Start IDENT segment
	 assume  ds:DGROUP

IDENT	 ends			; End IDENT segment


SEG_TAB  segment use16 word public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	 public  CMDARG_TAB
CMDARG_TAB label word

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use16 word public 'data' ; Start SEG_LEN segment
	 assume  ds:DGROUP

	 public  CMDARG_LEN
CMDARG_LEN label word

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use16 word public 'data' ; Start SEG_ACT segment
	 assume  ds:DGROUP

	 public  CMDARG_ACT
CMDARG_ACT label word

SEG_ACT  ends			; End SEG_ACT segment


DFL_REC  record  $DFL_FULL:1,$DFL_XDISP:1

@DFL_FULL equ	 mask $DFL_FULL  ; Allow only if @IDN_FULL set
@DFL_XDISP equ	 mask $DFL_XDISP ; Skip in ASK dialog box

; The following keywords *MUST* be in UPPERCASE

;;;;;;;; CMDARG_MAC 'NOSCRUB',        FCN_NOSCRUB
	 CMDARG_MAC 'NOXRAM',         FCN_NOXRAM
;;;;;;;; CMDARG_MAC 'SHADOWRAM',      FCN_SHADOWRAM
	 CMDARG_MAC 'TOP384',         FCN_TOP384
	 CMDARG_MAC 'SAF',            FCN_UNLSAF
	 CMDARG_MAC 'TF',             FCN_UNLTRN
	 CMDARG_MAC 'UNLINV',         FCN_UNLINV
	 CMDARG_MAC 'UNLIDM',         FCN_UNLIDM
	 CMDARG_MAC 'LNKINV',         FCN_LNKINV
	 CMDARG_MAC 'LNKIDM',         FCN_LNKIDM
	 CMDARG_MAC 'QUICK',          FCN_QUICK
	 CMDARG_MAC 'FULL',           FCN_FULL
	 CMDARG_MAC 'ADVANCED',       FCN_ADVANCED
	 CMDARG_MAC 'ADV',            FCN_ADVANCED
	 CMDARG_MAC 'HEX',            FCN_HEX
	 CMDARG_MAC 'ALL',            FCN_ALL
	 CMDARG_MAC 'NOEXIT',         FCN_NOEXIT
	 CMDARG_MAC 'NOPARITY',       FCN_NOPARITY
	 CMDARG_MAC 'NODPMI',         FCN_NODPMI
	 CMDARG_MAC 'NOVCPI',         FCN_NOVCPI

ifdef @RAMEXAM			; If building RAMEXAM
	 CMDARG_MAC 'DAILY',          FCN_DAILY,        <@DFL_FULL or @DFL_XDISP>
	 CMDARG_MAC 'INTERVAL',       FCN_INTERVAL,     <@DFL_FULL or @DFL_XDISP>
	 CMDARG_MAC 'MONTHLY',        FCN_MONTHLY,      <@DFL_FULL or @DFL_XDISP>
	 CMDARG_MAC 'WEEKLY',         FCN_WEEKLY,       <@DFL_FULL or @DFL_XDISP>
	 CMDARG_MAC 'ASK',            FCN_ASK,          <@DFL_FULL or @DFL_XDISP>
	 CMDARG_MAC 'LOG',            FCN_LOG,           @DFL_FULL
	 CMDARG_MAC 'TONE',           FCN_TONE,          @DFL_FULL
	 CMDARG_MAC 'LIGHTS',         FCN_LIGHTS,        @DFL_FULL
endif				; If building RAMEXAM

	 CMDARG_MAC 'B&W',            FCN_BW
	 CMDARG_MAC 'BW',             FCN_BW
	 CMDARG_MAC 'B',              FCN_BW
	 CMDARG_MAC 'COLOR',          FCN_COLOR
	 CMDARG_MAC 'C',              FCN_COLOR
	 CMDARG_MAC 'L',              FCN_LARGER
	 CMDARG_MAC 'S',              FCN_SMALLER
	 CMDARG_MAC 'V',              FCN_VLSI
	 CMDARG_MAC '?',              FCN_HELP

	 CMDARG_MAC 'K',              FCN_K

ifdef @BETA

	 CMDARG_MAC 'DEBUG=FAULT',    FCN_DBGFAULT
	 CMDARG_MAC 'DEBUG:FAULT',    FCN_DBGFAULT
	 CMDARG_MAC 'DEBUG=TIME',     FCN_DBGTIME
	 CMDARG_MAC 'DEBUG:TIME',     FCN_DBGTIME

endif ; @BETA


SEG_TAB  segment use16 word public 'data' ; Start SEG_TAB segment
	 assume  ds:DGROUP

	 public  NCMDARGS
NCMDARGS equ	 ($-CMDARG_TAB)/(type CMDARG_TAB) ; Its length

SEG_TAB  ends			; End SEG_TAB segment


NDATA	 segment use16 dword public 'data' ; Start NDATA segment
	 assume  ds:DGROUP

	 extrn	 MSG_UNSCHED:byte
	 extrn	 MSG_UNSCHED_DATE:byte
	 extrn	 MSG_QMTDAT:byte
	 extrn	 @MSG_QMTDAT_LEN:abs

	 extrn	 SUNDAY:byte
	 extrn	 MONDAY:byte
	 extrn	 TUESDAY:byte
	 extrn	 WEDNESDAY:byte
	 extrn	 THURSDAY:byte
	 extrn	 FRIDAY:byte
	 extrn	 SATURDAY:byte

	 extrn	 MSG_ASKCMDOPT:byte

	 public  LASTKEY
LASTKEY  dw	 ?		; Offset in command line of last keyword

	 public  NUMBERS_LO
NUMBERS_LO db	 '0123456789abcdef' ; Conversion table for BASE2BIN

ifdef @RAMEXAM

	 public  TODAY,TODAY_DOW,TODAY_DOM,QMTDAT,QMTDAT_M,QMTDAT_W
TODAY	 dd	 ?		; Today's date (days since Jan 1 1980)
QMTDAT	 dd	 0		; Date of RAMEXAM.DAT (...)
QMTDAT_M dd	 ?		; Base date for RAMEXAM.DAT month comparisons
QMTDAT_W dd	 ?		; Base date for RAMEXAM.DAT week comparisons
TODAY_DOW db	 ?		; Today's day of week (Sunday=1)
TODAY_DOM db	 ?		; Today's day of month (origin:1)

	 public  NEXTSCHED
NEXTSCHED dd	 -1		; Next scheduled date for QMT to run

endif ; @RAMEXAM


	 public  MOTAB
MOTAB label word		; For January - December (origin:0), preceding
				; days for the year
	 dw	 0		; January - 31
	 dw	 31		; February - 28 (leap day added separately)
	 dw	 31+28		; March - 31
	 dw	 31+28+31	; April - 30

	 dw	 31+28+31+30	; May - 31
	 dw	 31+28+31+30+31 ; June - 30
	 dw	 31+28+31+30+31+30 ; July - 31
	 dw	 31+28+31+30+31+30+31 ; August - 31

	 dw	 31+28+31+30+31+30+31+31 ; September - 30
	 dw	 31+28+31+30+31+30+31+31+30 ; October - 31
	 dw	 31+28+31+30+31+30+31+31+30+31 ; November - 30
	 dw	 31+28+31+30+31+30+31+31+30+31+30 ; December - 31

	 public  DNTAB
DNTAB label word
	 dw	 DGROUP:SUNDAY	; 'SUNDAY'
	 dw	 DGROUP:MONDAY
	 dw	 DGROUP:TUESDAY
	 dw	 DGROUP:WEDNESDAY
	 dw	 DGROUP:THURSDAY
	 dw	 DGROUP:FRIDAY
	 dw	 DGROUP:SATURDAY

NDATA	 ends			; End NDATA segment


PSP_SEG  segment use16 at 0	; Start PSP_SEG segment
	 assume  cs:PSPGRP,ds:PSPGRP

	 extrn	 PSP_PARM_COUNT:byte
	 extrn	 PSP_PARM_STRING:byte
	 extrn	 PSP_ENVIR_PTR:word

PSP_SEG  ends			; End PSP_SEG segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 FCN_HELP:near
	 extrn	 LOWERCASE:near

	 extrn	 BIN2DEC:near

	 extrn	 SAVE_SCR:near
	 extrn	 REST_SCR:near

	 extrn	 VIDB_SEGOFF:near
	 extrn	 VIDB_LINEAR:near

	 extrn	 GET_ASKRESP:near

	 extrn	 CHECK_SCRN:near

; Bits in DX returned by DOS fn 5701 (get file date/time):
DOSDATE_REC record $DDTE_YEAR:7,$DDTE_MONTH:4,$DDTE_DAY:5;

	 public  WEEKDAYS
WEEKDAYS dw	 7		; Number of days in a week

	 NPPROC  DATE2EPOCH -- Convert year/month/day to days since 1/1/80
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert year/month/day to days elapsed since 1/1/80.  This allows
us to make interval comparisons.

Note that every year divisible by 4 is a leap year, with the exception
of years divisible by 100.  Years divisible by 400 are also leap years.
While 1900 was not a leap year, 2000 is.  We can ignore the divisible
by 100 case here - it's a long time to 3/1/2100.  Our baseline year,
1980, is also a leap year by the above rules.

On entry:
DL	 Day (1-31)
DH	 Month (1-12)
CX	 Year-1980 (0-199)

On exit:
EAX	 Days since 1/1/1980

|

	 REGSAVE <bx,cx,dx,esi> ; Save

	 sub	 eax,eax	; Clear high word
	 mov	 al,dl		; Get day
	 dec	 al		; Convert to origin:0

; Determine number of leap days since 1980.
	 mov	 esi,eax	; Save day value
	 mov	 ax,cx		; Prepare to divide

	 shr	 ax,1		; AX = years / 2
	 rcr	 ax,1		; AL = years / 4
	 adc	 ah,0		; Test for bit 0 or bit 1
	 jnz	 short @F	; Jump if not a leap year

	 cmp	 dh,3		; Does the preceding month have a leap day?
	 sbb	 al,0		; Adjust number of leap days if so
@@:
	 cbw			; Convert byte to signed integer
	 inc	 ax		; Add in 1980 (if year is 1980, ffff ==> 0)

	 add	 esi,eax	; Add to accumulated day value

; Determine days passed in all preceding months
	 movzx	 bx,dh		; Get month (origin:1)
	 dec	 bx		; Convert to origin:0
	 shl	 bx,1		; Convert bytes to words
	 mov	 ax,MOTAB[bx]	; Get elapsed days for first of this month
	 add	 esi,eax	; Add to accumulated day value

; Determine days passed in preceding years
	 mov	 ax,cx		; Get years since 1980
	 imul	 eax,365	; Get elapsed days for first of this year
	 add	 eax,esi	; Add into return value

	 REGREST <esi,dx,cx,bx> ; Restore

	 ret			; Return to caller

DATE2EPOCH endp 		; End DATE2EPOCH procedure

ifdef @RAMEXAM

	 NPPROC  EPOCH2DATE -- Convert days since 1/1/80 to month/day/year
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert days elapsed since 1/1/80 to month/day/year (where year is the
number of years since 1980, origin:0).	This allows us to make adjustments
for MONTHLY= and to display the next scheduled occurrence.

On entry:
EAX	 Days since 1/1/1980

On exit:
DL	 Day (1-31)
DH	 Month (1-12)
CX	 Year-1980 (0-199)

|

	 REGSAVE <eax,bx>	; Save

	 ror	 eax,16-0	; Get high word of days
	 mov	 dx,ax		; Save it
	 shr	 eax,16-0	; Move low word back into place
	 mov	 bx,(4*365)+1	; Days in a leap year cycle
	 div	 bx		; AX = cycles, DX = remainder

	 mov	 cx,ax		; Get leap year cycles (1/1/80 begins first one)
	 shl	 cx,2		; Convert cycles to years

	 mov	 ax,dx		; Get days remaining; see if we can get any
				; more years out of it
	 cwd			; Prepare to divide
	 mov	 bx,365 	; Length of non-leap years
	 div	 bx		; AX = additional years, DX = days in year + 1

	 or	 ax,ax		; Izit a leap year?
	 jz	 short E2D_LEAP ; Jump if so

	 sub	 dx,1		; First year had an extra day; subtract it
	 jnc	 short @F	; Jump if no year wrap

	 mov	 dx,365-1	; Wrap back to last day of a non-leap year
	 dec	 ax		; Back off to previous year (even if it's
				; a leap year, we've already adjusted DX)
@@:
	 add	 cx,ax		; CX = total years

	 jmp	 short E2D_XLEAP ; Join common code

E2D_LEAP:
; Adjust for leap year by subtracting one from days if > MOTAB[1] (Feb)
	 cmp	 MOTAB[1*2],dx	; Izit past the end of February?
	 sbb	 dx,0		; Adjust days to fit non-leap year profile
				; (DX != 0, therefore no year wrap)
E2D_XLEAP:
	 sub	 bx,bx		; Initialize index into MOTAB[]
@@:
	 cmp	 dx,MOTAB[bx]	; Have we reached the next month?
	 jb	 short @F	; Jump if so

	 add	 bx,2		; Skip to next month
	 cmp	 bx,2*12	; Did we reach the end of the year?
	 jb	 short @B	; Go around again if not

@@:
	 shr	 bx,1		; BX = month (origin:1)
	 push	 bx		; Save return value

	 dec	 bx		; Back off to previous month
	 shl	 bx,1		; Convert to word index

	 sub	 dx,MOTAB[bx]	; DX = day of month (origin:0)
	 inc	 dl		; DL = day (origin:1)

	 pop	 bx		; Restore return value
	 mov	 dh,bl		; Get month (origin:1)

	 REGREST <bx,eax>	; Restore

	 ret			; Return to caller

EPOCH2DATE endp 		; End EPOCH2DATE procedure
	 NPPROC  EPOCH2WEEKS -- Convert days since 1/1/1980 to weeks
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert days since 1/1/1980 to weeks and day of week (origin:0).

On entry:
EAX	 Days since 1/1/1980 (origin:0)

On exit:
AX	 Weeks since Sunday, 12/29/1979
EDX	 Day of week (Sunday=origin=0)

|

	 add	 eax,2		; Days since Sunday before 1/1/1980
	 mov	 edx,eax	; Get high word of dividend
	 shr	 edx,16-0	; DX,AX = dividend
.8086				; Avoid spurious "Impure memory reference"
	 div	 WEEKDAYS	; AX = weeks since 1/1/80, DX = day of week
DOT386 p
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EPOCH2WEEKS endp		; End EPOCH2WEEKS procedure
	 NPPROC  GET_DATES -- Get current and QMT.DAT dates for comparison
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Call DOS to get the current date, and convert to days since
1/1/80.  Get the file date on RAMexam.DAT (if it exists) and convert
to days since 1/1/80.

Note that QMTDAT is the date saved only for INTERVAL= comparison.
We use QMTDAT_W and QMTDAT_M for WEEKLY= and MONTHLY= comparisons.

|

	 REGSAVE <eax,bx,cx,edx,si,di,es> ; Save

	 DOSCALL @GETDTE	; AL=dow (Sun=0), CX=year, DH=month, DL=day
	 inc	 al		; Convert weekday to origin:1
	 mov	 TODAY_DOW,al	; Save for WEEKLY= comparison
	 mov	 TODAY_DOM,dl	; Save for MONTHLY= comparison
	 sub	 cx,1980	; Convert to year-1980

	 call	 DATE2EPOCH	; EAX = days since 1/1/1980
	 mov	 TODAY,eax	; Save for DAILY and INTERVAL= comparison

; Get the directory we were started from
	 mov	 es,PSPSEG	; Get command line segment
	 assume  es:PSPGRP	; Tell the assembler about it

	 mov	 es,PSP_ENVIR_PTR ; Address our environment
	 assume  es:nothing	; Tell the assembler

; Find the strings section
	 cld			; String ops forwardly
	 sub	 ax,ax		; Find end of environment string
	 mov	 cx,8000h	; Maximum environment size
	 sub	 di,di		; Start at beginning of env segment
@@:
   repne scas	 es:[di].LO	; Find end of string
	 jne	 near ptr GD_EXIT ; Jump if none found (???)

	 scas	 es:[di].LO	; Check for end of environment
	 loopne  @B		; Go around again if not the end
	 jne	 near ptr GD_EXIT ; Jump if not found (???)

	 scas	 es:[di].ELO	; String section count should be >0
	 je	 near ptr GD_EXIT ; Jump if not

	 push	 ds		; Get DGROUP segment
	 push	 es		; Segment of path
	 pop	 ds		; Address for LODS
	 pop	 es		; Address for STOS
	 assume  ds:nothing,es:DGROUP ; Tell the assembler

	 mov	 si,di		; DS:SI ==> complete program path

	 lea	 di,QMTDIR	; ES:DI ==> destination
	 mov	 cx,di		; Initialize stem length count
GD_NEXTCHAR:
	 lods	 ds:[si].LO	; Get next byte
S16	 stos	 QMTDIR[di]	; Save it

	 or	 al,al		; Izit the end?
	 jz	 short GD_ENDPATH ; Jump if so

; If it's a path separator, save DI as end of stem
	 cmp	 al,':'         ; End of drive designator?
	 je	 short GD_EOSTEM ; Jump if so

	 cmp	 al,'/'         ; End of path?
	 je	 short GD_EOSTEM ; Jump if so

	 cmp	 al,'\'         ; Other end of path?
	 jne	 short GD_NEXTCHAR ; Go around again if not

GD_EOSTEM:
	 mov	 cx,di		; Save as end of stem
	 jmp	 short GD_NEXTCHAR ; Go around again

GD_ENDPATH:
	 mov	 di,cx		; Address first byte past end of path
	 sub	 cx,offset DGROUP:QMTDIR[0] ; Get length of stem in bytes
	 mov	 QMT_STEM,cx	; Save for later

; Try to open d:\path\RAMEXAM.DAT

	 REGSAVE <ds,si,ax,cx>	; Save for a moment

	 mov	 ax,seg DGROUP	; Address DGROUP
	 mov	 ds,ax		; In DS
	 assume  ds:DGROUP	; Tell assembler about it

	 lea	 si,azDATFileName ; Address logfile name ==>DS:SI
	 mov	 cx,@lDATFileName ; Get length of logfile name

S16  rep movs	 <QMTDIR[di].ELO,azDATFileName[si].ELO> ; Copy bytes (including NULL)

	 REGREST <ax,cx,si,ds>	; Restore used regs

	 push	 es		; Get DGROUP segment
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler

	 mov	 al,0		; Access mode: read-only, compatibility mode
	 DOSCALL @OPENF2,QMTDIR ; Try to open the file
	 jc	 short GD_EXIT	; Jump if it's not there

	 mov	 bx,ax		; Use handle register
	 mov	 ax,@GSTDAT*256+00h ; Subfn 0: get time:date in CX:DX
	 DOSCALL		; DX = DOSDATE_REC

	 mov	 ax,dx		; Get packed date
	 and	 dl,mask $DDTE_DAY ; Isolate day of month
	 mov	 cx,ax		; Get year
	 and	 ax,mask $DDTE_MONTH ; Isolate month
	 shr	 ax,$DDTE_MONTH ; Shift over
	 mov	 dh,al		; DH = month, DL = day
	 shr	 cx,$DDTE_YEAR	; CX = year - 1980

;;;;;;;  mov	 QMTDAT_DOM,dl	; Save day of month

	 call	 DATE2EPOCH	; EAX = days since 1/1/1980
	 mov	 QMTDAT,eax	; Save for DAILY and INTERVAL= comparison

;;;;;;;  call	 EPOCH2WEEKS	; AX = weeks elapsed, DX = day of week (org:0)
;;;;;;;  inc	 dl		; Convert to origin:1 (Sunday)
;;;;;;;  mov	 QMTDAT_DOW,dl	; Save day of week

	 DOSCALL @CLOSF2	; Close file BX
GD_EXIT:
; If QMTDAT is 0, we need to pretend RAMEXAM was last run on the
; last day of today's month - 1 for MONTHLY= comparisons, and on
; the last day of today's week - 1 for WEEKLY= comparisons.
	 mov	 eax,QMTDAT	; Get date of RAMEXAM.DAT
	 mov	 QMTDAT_M,eax	; Save for MONTHLY= comparisons
	 mov	 QMTDAT_W,eax	; Save for WEEKLY= comparisons

	 or	 eax,eax	; Izit valid?
	 jnz	 short GD_EXIT2 ; Jump if so

	 mov	 eax,TODAY	; Get today's date (days since 1/1/80 org:0)
	 call	 EPOCH2DATE	; DH=month (origin:1), DL=day (org:1), CX=year
	 mov	 dl,1		; First of month
	 call	 DATE2EPOCH	; EAX = days since 1/1/1980
	 dec	 eax		; Back off to last day of previous month
	 mov	 QMTDAT_M,eax	; Save for MONTHLY= comparisons

	 mov	 eax,TODAY	; Get today's date (days since 1/1/80 org:0)
	 call	 EPOCH2WEEKS	; AX = weeks since 1/1/80 - 2 days
.8086				; Avoid spurious "Impure memory reference"
	 mul	 WEEKDAYS	; DX,AX = days since 1/1/80 - 2
DOT386 p
	 shl	 eax,16 	; Save low order word
	 mov	 ax,dx		; Get high order word
	 rol	 eax,16 	; EAX = days since 1/1/80 - 2 for last Sunday
	 sub	 eax,(2+1)	; Get last day of preceding week
	 jc	 short GD_EXIT2 ; Jump if date is 1/1/80

	 mov	 QMTDAT_W,eax	; Save for WEEKLY= comparisons
GD_EXIT2:
	 REGREST <es,di,si,edx,cx,bx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_DATES endp			; End GET_DATES procedure

endif ; @RAMEXAM

	 NPPROC  BYTE2DEC -- Convert AL to decimal at ES:DI
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL (where AL < 100) to ASCII decimal at ES:DI.

On entry:
AL	 Number to convert
ES:DI ==> Position for ASCII output

On exit:
AX	 Destroyed
ES:DI	 Updated

|


	 cbw			; Clear high byte
	 aam			; Digits in AH,AL
	 or	 ax,'00'        ; Convert to ASCII

	 cmp	 ah,'0'         ; Should we skip leading '0'?
	 je	 short @F	; Jump if so

	 xchg	 ah,al		; Swap to display order
S16	 stos	 DGROUP:[di].ELO ; Save both digits
	 jmp	 short B2D_EXIT ; Join common exit

@@:
S16	 stos	 DGROUP:[di].LO ; Save single digit
B2D_EXIT:

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BYTE2DEC endp			; End BYTE2DEC procedure
	 NPPROC  FMT_DMY -- Format date as ASCII
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format day, month and year values as an ASCII date.

On entry:
DH	 Month (origin:1)
DL	 Day (origin:1)
CX	 Year, either A.D. or since 1900
BX	 Digits to display in year (2 or 4)
ES:DI ==> Output for string

On exit:
ES:DI ==> Space for terminator (0 or EOS)

|

	 REGSAVE <ax>		; Save

ifdef @LANG_GR
	 mov	 al,dl		; Get day (dd/mm/yy)
else
	 mov	 al,dh		; Get month (mm/dd/yy)
endif
	 call	 BYTE2DEC	; Format as ASCII decimal

	 mov	 al,DATESEP	; / or -
S16	 stos	 DGROUP:[di].LO ; Append to date

ifdef @LANG_GR
	 mov	 al,dh		; Get month (dd/mm/yy)
else
	 mov	 al,dl		; Get day (mm/dd/yy)
endif
	 call	 BYTE2DEC	; Format as ASCII decimal

	 mov	 al,DATESEP	; / or -
S16	 stos	 DGROUP:[di].LO ; Append to date

	 lea	 di,[di+bx-1]	; Skip to low order digit of year
	 mov	 ax,cx		; Get year value
	 call	 BIN2DEC	; Display year, right justified at ES:DI
	 lea	 di,[di+bx+1]	; Skip past end of year

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_DMY  endp			; End FMT_DMY procedure
	 NPPROC  FMT_HM -- Format time as ASCII
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format hour and minute as ASCII.  If US version, reduce modulo 12 and
add AM or PM.
US:	1:45 PM
German: 13:45

On entry:
CH	 Hour (origin:0)
CL	 Minute (...)
DH	 Second (...)
DL	 Second / 100 (...)
ES:DI ==> Output for string

On exit:
ES:DI ==> Space for terminator

|

	 REGSAVE <ax,bx>	; Save

if (@NATL_TIME EQ @NATL_TIME12)
	 movzx	 ax,ch		; Get hours
	 mov	 bl,12		; Divisor
	 div	 bl		; AH=remainder, AL=quotient
	 mov	 ch,ah		; Hours modulo 12

; 0:01 AM is 12:01 AM, 0:01 PM is 12:01 PM
	 or	 ah,ah		; Izit 0?
	 jnz	 short @F	; Jump if not

	 mov	 ch,bl		; Force 12
@@:
	 movzx	 bx,al		; Get index into TIMEPREFIX
	 shl	 bx,1		; Convert to word index
endif				; IF 12-hour time format

	 mov	 al,ch		; Get hours
	 call	 BYTE2DEC	; Format as ASCII decimal

	 mov	 al,TIMESEP	; Should be ":"
S16	 stos	 DGROUP:[di].LO ; Append to time

; Minutes need to be formatted with a leading 0.
	 movzx	 ax,cl		; Get minutes
	 aam			; Digits in AH,AL
	 or	 ax,'00'        ; Convert to ASCII
	 xchg	 ah,al		; Swap to display order
S16	 stos	 DGROUP:[di].ELO ; Append to time

if (@NATL_TIME EQ @NATL_TIME12)
	 mov	 al,' '         ; Separator for AM/PM
S16	 stos	 DGROUP:[di].LO ; Append to time
	 mov	 ax,TIMEPREFIX[bx] ; Get 'AM' or 'PM' (in display order)
S16	 stos	 DGROUP:[di].ELO ; Append to time
endif				; IF 12-hour time

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_HM	 endp			; End FMT_HM procedure

ifdef @RAMEXAM

	 NPPROC  CHECK_SCHED -- Check scheduling
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for scheduling.  If any were specified and failed, and none
succeeded, display our unscheduled message and go no further.

On entry:
nothing

On exit:
CF=1	 Not time to run yet.
CF=0	 OK to proceed.

|

	 REGSAVE <eax,bx,cx,dx,si,di> ; Save

	 test	 CMD_FLAG,@CMD_SFAIL ; Should we fail scheduled execution?
	 jz	 short CSCHED_EXIT ; Jump if not (note CF=0)

; Someone might have an odd combination like MONTHLY=1 WEEKLY=3 where
; Monday is the first of the month.  We'll run on Monday, failing the
; WEEKLY=3 (Tuesday) test, and again on Tuesday, failing the MONTHLY=1
; test.
	 test	 CMD_FLAG,@CMD_SPASS ; Was there another test that passed?
	 jnz	 short CSCHED_EXIT ; Jump if so (note CF=0)

; Format the next date into our message
	 mov	 eax,NEXTSCHED	; Get days from 1/1/1980 for next execution
	 call	 EPOCH2WEEKS	; DX = day of week (origin:0)
	 mov	 bx,dx		; Copy to base register
	 shl	 bx,1		; Convert to word index
	 mov	 si,DNTAB[bx]	; Get pointer to ASCIIZ day name
	 lea	 di,MSG_UNSCHED_DATE ; Address start of date text
	 cld			; String ops forwardly
@@:
	 lods	 DGROUP:[si].LO ; Get next byte
	 or	 al,al		; Did we reach the end?
	 jz	 short @F	; Jump if so

S16	 stos	 MSG_UNSCHED_DATE[di] ; Put in message
	 jmp	 short @B	; Go around again

@@:
	 mov	 ax,' ,'        ; ", "
S16	 stos	 DGROUP:[di].ELO ; Append to string

	 mov	 eax,NEXTSCHED	; Get days from 1/1/1980
	 call	 EPOCH2DATE	; DH=month (origin:1), DL=day (org:1), CX=year

	 add	 cx,1980	; Convert epoch year to AD
	 mov	 bx,4		; Number of year digits to format
	 call	 FMT_DMY	; Format DD/MM/YYYY or MM/DD/YYYY date at ES:DI
	 mov	 ax,LF*256+CR	; Ending CR,LF
S16	 stos	 DGROUP:[di].ELO ; Add to end
	 mov	 DGROUP:[di].LO,EOS ; Terminate message

	 DOSCALL @STROUT,MSG_UNSCHED ; Tell 'em when the clock strikes one...

	 stc			; Indicate failure

CSCHED_EXIT:
	 REGREST <di,si,dx,cx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SCHED endp		; End CHECK_SCHED procedure
	 NPPROC  UPDATE_QMTDAT -- Re-write QMT.DAT to set current time/date
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Re-write QMT.DAT with our message to set the time/date stamp on it.

|

	 pushf			; Save return flags
	 REGSAVE <ax,bx,cx,dx>	; Save

	 mov	 cx,0		; Attributes to create file with
	 DOSCALL @CREAF2,QMTDIR ; Truncate file; return handle in AX
	 jc	 short UQD_EXIT ; Jump if we failed (???)

	 mov	 bx,ax		; Setup handle for write
	 mov	 cx,@MSG_QMTDAT_LEN ; Bytes to write
	 DOSCALL @WRITF2,MSG_QMTDAT ; "QMT scheduling data"
;;;;;;;  jc	 ???		; Ignore error

	 DOSCALL @CLOSF2	; Close file BX
;;;;;;;  jc	 ???		; Ignore error

UQD_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore
	 popf			; Restore CF

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPDATE_QMTDAT endp		; End UPDATE_QMTDAT procedure
	 NPPROC  CHECK_ASK -- Check for ASK keyword and update QMT.DAT
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If the ASK keyword was specified, put up a pseudo-dialog box and
ask 'em what to do.  If the answer is Yes or No, or ASK was not
specified, update QMT.DAT.

If it's No or Postpone, return CF=1 to caller so they can abort.

On entry:
nothing

On exit:
CF=1	 Return to DOS.
CF=0	 OK to proceed.

|

	 REGSAVE <eax,bx,cx,dx,si,di,es> ; Save

	 test	 CMD_FLAG,@CMD_ASK ; Should we ask to run QMT?
	 jz	 near ptr CASK_EXIT2 ; Jump if not (note CF=0)

	mov	eax,not @CMD_BWDEF ; Default mask for CMD_FLAG
	or	eax,CMD_FLAG	; Get current @CMD_BWDEF setting
	or	CMD_FLAG,@CMD_BWDEF ; Don't ask - assume B&W if we can't
				; determine display type

	 call	 CHECK_SCRN	; Set display mode

	and	CMD_FLAG,eax	; Restore previous state of @CMD_BWDEF

	 call	 SAVE_SCR	; Save entire screen contents

	 call	 VIDB_SEGOFF	; Convert VIDBASE_VEC from linear to seg:off

	 push	 seg DGROUP	; Get our data segment
	 pop	 es		; Address for LODS
	 assume  es:DGROUP	; Tell the assembler

	 cld			; Set forward direction for string ops

; If any options were processed, format them into the dialog box

	 lea	 di,SAV_ASKCMDOPT ; Address start of options
	 mov	 cx,@LEN_ASKCMDOPT ; How far to look
	 sub	 ax,ax		; What to look for
   repne scas	 SAV_ASKCMDOPT[di] ; ES:DI ==> character after trailing 0
	 setne	 al		; AX=1 if ES:DI ==> character after end
	 add	 di,ax		; ES:DI ==> character after putative terminator

	 sub	 di,offset DGROUP:SAV_ASKCMDOPT[1] ; Get length in bytes
	 mov	 cx,di		; Copy to count register
	 jcxz	 CA_XOPT	; Jump if empty

; Copy options, not including trailing 0
	 lea	 si,SAV_ASKCMDOPT ; Source for copy
	 mov	 bx,cx		; Get length of string
	 inc	 bx		; Round up to even boundary
	 shr	 bx,1		; Divide by 2 (rounding result)
	 neg	 bx		; Negate it
	 lea	 di,MSG_ASKCMDOPT[bx-4] ; Midpoint of destination less lead
	 mov	 eax,'    '     ; Filler to eliminate (keine)
S16	 stos	 MSG_ASKCMDOPT[di].EDD ; Clobber '(kei'
S16  rep movs	 <MSG_ASKCMDOPT[di],SAV_ASKCMDOPT[si]> ; Move it
S16	 stos	 MSG_ASKCMDOPT[di].EDD ; Clobber 'ne)'

CA_XOPT:
; Display the dialog box and get user's input

	 call	 GET_ASKRESP	; Return AL = toupper (response) î {Y, N, P}

	 cmp	 al,@NATL_YESCHAR ; Should we proceed?
	 je	 short CASK_EXIT ; Jump if so (note CF=0)

	 cmp	 al,@NATL_NOCHAR ; Don't ask me till next time?
	 je	 short CASK_ERR1 ; Jump if so

;;;;;;;  cmp	 al,@NATL_POSTPONE ; Ask me some other time?
;;;;;;;  jne	 ???		; ???

	 stc			; Indicate failure
	 jmp	 short CASK_EXIT1 ; Don't update QMT.DAT

CASK_ERR1:
	 stc			; Indicate failure
CASK_EXIT:
	 call	 UPDATE_QMTDAT	; Re-write QMT.DAT

CASK_EXIT1:
	 pushf			; Save CF

	 call	 VIDB_LINEAR	; Restore VIDBASE_VEC to 32-bit linear address

	 call	 REST_SCR	; Restore screen contents

	 popf			; Restore
	 jmp	 short CASK_EXIT3 ; Join common exit

CASK_EXIT2:
	 call	 UPDATE_QMTDAT	; Re-write QMT.DAT

CASK_EXIT3:
	 REGREST <es,di,si,dx,cx,bx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ASK endp			; End CHECK_ASK procedure

endif ; @RAMEXAM

	 NPPROC  IZITSEP -- Is AL a valid separator?
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:
AL	 character to check

On exit:
ZF=1	 AL is a valid separator (=,:,/, etc).
ZF=0	 not...

|

	 cmp	 al,'='         ; Check for valid separator
	 je	 short IZITSEP_EXIT ; Jump if valid (note ZF=1)

	 cmp	 al,':'         ; Check for valid separator
	 je	 short IZITSEP_EXIT ; Jump if valid (note ZF=1)

	 cmp	 al,';'         ; Check for valid separator
	 je	 short IZITSEP_EXIT ; Jump if valid (note ZF=1)

	 cmp	 al,'/'         ; Check for valid separator
	 je	 short IZITSEP_EXIT ; Jump if valid (note ZF=1)

	 cmp	 al,','         ; Check for valid separator
	 je	 short IZITSEP_EXIT ; Jump if valid (note ZF=1)

	 cmp	 al,' '         ; Check for blank or below
	 ja	 short IZITSEP_EXIT ; Jump if not (note ZF=0)

	 cmp	 al,al		; Set ZF=1 to indicate a match
IZITSEP_EXIT:

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITSEP  endp			; End IZITSEP procedure
	 NPPROC  CHECK_ARGS -- Check for Command Line Arguments
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for command line arguments.

On exit:
CF=0	 All went well.

CF=1	 Syntax error occurred, or a scheduling option was present
	 (DAILY, WEEKLY, MONTHLY, INTERVAL) and it's not time yet.

|

	 REGSAVE <ax,bx,ecx,dx,si,di,ds,fs> ; Save registers

	 mov	 fs,CODESEG	; Setup alias to code segment
	 assume  fs:PGROUP	; Tell the assembler about it

ifdef @RAMEXAM
	 call	 GET_DATES	; Get current date and RAMEXAM.DAT date
endif

; If there's an XMS driver or DPMI host, force NOXRAM as we
; can't afford to recover any such memory.

	 test	 GLB_FLAG,@GLB_XMS ; Is there an XMS driver present?
	 jnz	 short @F	; Jump if so

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jz	 short CHECK_ARGS1 ; Jump if not
@@:
	 call	 FCN_NOXRAM	; Mark as no extra memory recovery
CHECK_ARGS1:
	 mov	 ds,PSPSEG	; Get command line segment
	 assume  ds:PSPGRP	; Tell the assembler about it

	 lea	 si,PSP_PARM_STRING ; DS:SI ==> command line

; Convert everything to common case

	 movzx	 cx,PSP_PARM_COUNT ; Get the # characters on the line
CHECK_ARGS_UPPER:
	 lodsb			; Get next character

	 cmp	 al,CR		; Check for end-of-the-line
	 je	 short @f	; That's folks

	 call	 UPPERCASE	; Convert to uppercase
	 mov	 ds:[si-1],al	; Save back

	 loop	 CHECK_ARGS_UPPER ; Jump if more characters to convert
@@:
	 lea	 si,PSP_PARM_STRING ; DS:SI ==> command line
CHECK_ARGS_SRCH:		; Search for arguments
	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,CR		; Check for terminator
	 je	 near ptr CHECK_ARGS_VALID ; That's all folks

	 cmp	 al,';'         ; Check for terminator
	 je	 near ptr CHECK_ARGS_VALID ; That's all folks

	 cmp	 al,'/'         ; Check for leading slash
	 je	 short CHECK_ARGS_SRCH ; Jump if so (ignore it)

	 cmp	 al,'-'         ; Check for leading dash (Bill and Henry will be happy)
	 je	 short CHECK_ARGS_SRCH ; Jump if so (ignore it)

	 dec	 si		; Back off to last character

; Search for the argument text

	 xor	 bx,bx		; Zero index register
	 mov	 cx,NCMDARGS	; # arguments to check
CHECK_ARGS_NEXT:
	 mov	 di,CMDARG_TAB[bx] ; Get location of text

	 REGSAVE <cx,si>	; Save for a moment
	 mov	 cx,CMDARG_LEN[bx] ; Get length
    repe cmps	 ds:[si].LO,es:[di].LO ; Compare 'em
	 REGREST <si,cx>	; Restore
	 jne	 short CHECK_ARGS_NEXT1 ; Not this one

; If it's not ASK or a scheduling option, add to SAV_ASKCMDOPT

	 test	 DGROUP:[di].LO,@DFL_XDISP ; Display in ASK dialog box?
	 jnz	 short CHECK_ARGS_XDISP ; Jump if not

	 REGSAVE <cx,si>	; Save

	 lea	 di,SAV_ASKCMDOPT ; Address save string
	 mov	 cx,@LEN_ASKCMDOPT ; Space available
	 mov	 al,0		; What to look for
	 cmp	 DGROUP:[di].LO,0 ; Izit empty so far?
	 je	 short @F	; Jump if so

   repne scas	 SAV_ASKCMDOPT[di] ; ES:DI ==> character after 0
	 jcxz	 CHECK_ARGS_XSPACE ; Jump if no more space

	 mov	 DGROUP:[di-1].LO,' ' ; Add space to end of last option
@@:
	 lods	 ds:[si].LO	; Get next character
	 call	 IZITSEP	; Izit a separator?
	 je	 short @F	; Jump if so

S16	 stos	 SAV_ASKCMDOPT[di] ; Save it
	 loop	 @B		; Go around again

@@:
	 jcxz	 @F		; Jump if no space left

	 sub	 al,al		; Get a zero
S16	 stos	 SAV_ASKCMDOPT[di] ; Terminate the sucker
@@:
CHECK_ARGS_XSPACE:
	 REGREST <si,cx>	; Restore

CHECK_ARGS_XDISP:
; Mark as found only if the next character is a valid separator

	 mov	 di,CMDARG_LEN[bx] ; Get length of matching command
	 add	 di,si		; Add into starting offset
	 mov	 al,ds:[di]	; Get the next character

	 call	 IZITSEP	; Is AL a separator?
	 je	 short CHECK_ARGS_FOUND ; Jump if so

CHECK_ARGS_NEXT1:
	 add	 bx,type CMDARG_TAB ; Skip to next entry

	 loop	 CHECK_ARGS_NEXT ; Jump if more entries to check

; Keyword not found

	 mov	 LASTKEY,si	; Save as offset in command line of last keyword
	 lea	 di,MSG_UNK	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword

;;;;;;;  call	 FCN_HELP	; Display our help message

	 jmp	 CHECK_ARGS_ERR ; Join common error code

CHECK_ARGS_FOUND:
	 mov	 LASTKEY,si	; Save as offset of last keyword
	 add	 si,CMDARG_LEN[bx] ; Skip over the keyword

	 call	 CMDARG_ACT[bx] ; Take appropriate action
	 jnc	 near ptr CHECK_ARGS_SRCH ; Jump if all went OK

	 jmp	 CHECK_ARGS_ERR ; Join common error code


; Everything checked out -- now validate the options

CHECK_ARGS_VALID:
	 push	 es		; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

ifdef @RAMEXAM

	 call	 CHECK_SCHED	; Check scheduling
	 jc	 near ptr CHECK_ARGS_ERR ; Jump if we're not doing anything now

	 call	 CHECK_ASK	; If ASK specified, ask if they want to proceed
	 jc	 near ptr CHECK_ARGS_ERR ; Jump if No or Postpone

endif ; @RAMEXAM
ifdef @BETA			; If beta version
	 test	 GL2_FLAG,@GL2_SWAT ; Is SWAT available?
	 jnz	 short @F	; Jump if so

	 mov	 DBG_FLAG,0	; Clear all debug flags so we don't
				; generate false errors
@@:
endif				; ifdef @BETA
CHECK_ARGS_CLC:
	 clc			; Indicate all went well

	 jmp	 short CHECK_ARGS_EXIT ; Join common exit code

CHECK_ARGS_ERR:
	 stc			; Indicate an error occurred
CHECK_ARGS_EXIT:
	 REGREST <fs,ds,di,si,dx,ecx,bx,ax> ; Restore
	 assume  ds:DGROUP,fs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	 NPPROC  DISP_UNK -- Display Message and Unknown Keyword
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display error message and unknown keyword.

On entry:

ES:DI	 ==>	 error message to display
LASTKEY  ==>	 unknown keyword

|

	 push	 di		; Pass address of error message
	 call	 DISP_MSG	; Tell 'em we couldn't decipher their handwriting

; Copy unmatched text to local buffer

	 REGSAVE <ax,cx,si,di>	; Save registers

	 mov	 cx,30		; Maximum message length
	 mov	 si,LASTKEY	; DS:SI ==> last keyword
@@:
	 lodsb			; Get next character
S16	 stos	 es:[di].LO	; Save in local buffer

	 cmp	 al,' '         ; Check for terminator
	 jbe	 short @F	; Jump if that's all folks

	 loop	 @B		; Jump if more characters
@@:
	 mov	 ax,LF*256+CR	; Line terminators
S16	 stos	 es:[di].ELO	; Save in message

	 mov	 al,EOS 	; String terminator
S16	 stos	 es:[di].LO	; Save in message

	 REGREST <di,si,cx,ax>	; Restore

	 push	 di		; Pass address of unknown keyword
	 call	 DISP_MSG	; Tell 'em we couldn't decipher their handwriting

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_UNK endp			; End DISP_UNK procedure
	 NPPROC  DISP_MSG -- Display Message
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MSG_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's return address
DISP_MSG_OFF dw  ?		; Offset in CS of message

DISP_MSG_STR ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,dx,ds>	; Save registers

	 push	 es		; Setup DS for @STROUT
	 pop	 ds
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 dx,[bp].DISP_MSG_OFF ; DS:DX ==> message

	 DOSCALL @STROUT	; Display the message

	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MSG endp			; End DISP_MSG procedure
	 NPPROC  UPPERCASE -- Convert AL to Uppercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 cmp	 al,'a'         ; Check lower limit
	 jb	 short UPPERCASE_EXIT ; Too small for us

	 cmp	 al,'z'         ; Check upper limit
	 ja	 short UPPERCASE_EXIT ; Too big for us

	 add	 al,'A'-'a'     ; Convert alpha to upper case
UPPERCASE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPPERCASE endp			; End UPPERCASE procedure
	 NPPROC  SKIP_WHITE -- Skip over White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space and return the last
character in AL.

On entry:

DS:SI	 ==>	 command line

On exit:

DS:SI	 ==>	 command line (updated)
AL	 =	 lower case last character

|

	 lodsb			; Get the next byte

	 cmp	 al,' '         ; Check for blank
	 je	 short SKIP_WHITE ; Go around again

	 cmp	 al,TAB 	; Check for TAB
	 je	 short SKIP_WHITE ; Go around again

	 call	 LOWERCASE	; Convert to lowercase

	 ret			; Return to caller with next byte in AL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	 NPPROC  BASE2BIN -- Convert From Specified Base to Binary
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BASE2BIN -- Convert the number at DS:SI in base CX to binary.
The converted # is returned in AX.

On entry:

CX	 =	 number base
DS:SI	 ==>	 input save area

On exit:

CF	 =	 1 if overflow
	 =	 0 if OK
AX	 =	 converted #

|

	 REGSAVE <bx,dx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 xor	 bx,bx		; Zero accumulator
BASE2BIN_LOOP:
	 lea	 di,NUMBERS_LO	; Get address of number conversion table
	 push	 cx		; Save number base (and table length)
   repne scas	 NUMBERS_LO[di] ; Look for the character
	 pop	 cx		; Restore number base
	 jne	 short BASE2BIN_DONE ; Not one of ours

	 sub	 di,1+offset es:NUMBERS_LO ; Convert to origin 0
	 mov	 ax,bx		; Copy old to multiply by base

	 mul	 cx		; Shift over accumulated #
	 jc	 short BASE2BIN_EXIT ; Jump if out of range (note CF=1)

	 mov	 bx,ax		; Copy back
	 add	 bx,di		; Add in new #
	 jc	 short BASE2BIN_EXIT ; Jump if out of range (note CF=1)

	 lodsb			; Get next digit
	 call	 LOWERCASE	; Convert to lowercase

	 jmp	 BASE2BIN_LOOP	; Go around again

BASE2BIN_DONE:
	 dec	 si		; Back off to previous character
	 mov	 ax,bx		; Place result in accumulator

	 clc			; Indicate all went well
BASE2BIN_EXIT:
	 REGREST <di,dx,bx>	; Restore registers

	 ret			; Return to caller with number in AX

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BASE2BIN endp			; End BASE2BIN procedure

CODE	 ends			; End CODE segment

	 MEND			; End MEM_CMD module

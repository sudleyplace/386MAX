;' $Header:   P:/PVCS/MAX/386MAX/UTIL_OPT.ASV   1.3   08 Jul 1998 12:30:12   BOB  $
	 title	 UTIL_OPT -- 386LOAD/MOVE'EM TSR Optimizer
	 page	 58,122
	 name	 UTIL_OPT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Data    segment UDATA,	dword-aligned, public, class 'udata'
	       Data    segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include ASCII.INC
;;;;;;	 include DOSCALL.INC	; No DOS calls allowed while OPTINT8 installed.
	 include VIDCALL.INC
	 include VIDATTR.INC
	 include BITFLAGS.INC
	 include PTR.INC
	 include MAC.INC
	 include 8253.INC
	 include 8255.INC
	 include 8259.INC
	 include KEYCALL.INC
	 include KEYCODE.INC
	 include INTVEC.INC

	 include LOAD_SEG.INC
	 include UTIL_OPT.INC
	 include UTIL_USE.INC
	 include COMM_OEM.INC
if @OEM_HARPO
	 include EMM2CALL.INC
endif				; IF @OEM_HARPO
.list


@DEBUG	 equ	 0		; 1 = debug statements enabled, 0 = disabled

PGROUP	 group	 CODE,DATA,ACODE,ADATA,UCODE,UDATA,ZZTAIL


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 UTL_FLAG:word
	 include QMAX_UTL.INC

	 extrn	 POVR_MAC:word
	 extrn	 LOADSEG:word

DATA	 ends			; End DATA segment


ADATA	 segment dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP

if @OEM_FLEX
	 extrn	 MAPTAB:tbyte
	 extrn	 NMAPS:word
endif				; IF @OEM_FLEX

	 public  NEXTAVL
NEXTAVL  dw	 PGROUP:ZTAIL	; Offset of next available byte in PGROUP

ADATA	 ends			; End ADATA segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

if @OEM_HARPO
	 extrn	 WINOUT:near
endif				; IF @OEM_HARPO

CODE	 ends			; End CODE segment

ACODE	 segment byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

if @OEM_FLEX
	 extrn	 SET_MAPTAB:near
endif				; IF @OEM_FLEX

ACODE	 ends			; End ACODE segment


UDATA	 segment dword public 'udata' ; Start UDATA segment
	 assume  ds:PGROUP

	 public  OPTINT8_VEC
OPTINT8_VEC dd	?		; Save area for old INT 8 handler

if @DEBUG

.err @Debug conditionals need to be fixed!

@R_PRGORD equ	 0		; Row # for PRGORD
@C_PRGORD equ	 0		; Col ...

@R_APVORD equ	 1		; Row # for APVORD
@C_APVORD equ	 0		; Col ...

@R_APV	 equ	 2		; Row # for APV
@C_APV	 equ	 0		; Col ...

@R_RAPV  equ	 3		; Row # for RAPV
@C_RAPV  equ	 0		; Col ...

@R_NEXT  equ	 4		; Row # for next line
@C_NEXT  equ	 0		; Col ...

	 public  HEXTABLE
HEXTABLE db	 '0123456789ABCDEF'

	 public  MSG_PRGORD,MSG_APVORD,MSG_APV,MSG_RAPV
MSG_PRGORD db	 'PRGORD=',EOS
MSG_APVORD db	 'APVORD=',EOS
MSG_APV  db	 'APV= ',EOS
MSG_RAPV db	 'RAPV=',EOS

else
	 public  APV_PTR
APV_PTR  dw	 ?		; Video (Row,Col) for APV display
endif				; IF @DEBUG

	 public  RAPVCNT,TPOCNT,FITRES,LVL,CURSEG,NREGS,NREGSLVL,REGTAB,REGSPAN
	 align	 2
RAPVCNT  dw	 ?		; Count of RAPV
TPOCNT	 dw	 ?		; Count of TPO (decreases at lower levels)
FITRES	 dw	 ?		; Current fit
LVL	 dw	 ?		; Recursion level
CURSEG	 dw	 ?		; Current load segment for SUMMARY and SUMFIT
NREGS	 dw	 ?		; # regions in high DOS
NREGSLVL dw	 ?		; 2*(# regions in high DOS)
REGTAB	 dw	 @NREGS dup (?) ; Region table (size in paras)
REGSPAN  dw	 @NREGS dup (?) ; Region spanning segment #

if @OEM_FLEX
	 public  REGEMS,REGDIF,REGDIF_CNT,REGDIF_IND
REGEMS	 dw	 @NREGS dup (?) ; Region EMS table (size in paras)
REGDIF	 dw	 @NREGS dup (?) ; Different REGEMS values
REGDIF_CNT dw	 ?		; Count of ...
REGDIF_IND dw	 ?		; Index of current REGDIF value
endif				; IF @OEM_FLEX

	 public  TOTREG,OLDCURTYP,UREGDIF
TOTREG	 dw	 ?		; Total region size (+/REGTAB) in paras
OLDCURTYP dw	 ?		; Old cursor type
UREGDIF  dw	 @NREGS dup (?) ; Additional space subtracted from regions for
				; calculating placement of UMBs

	 public  PSUMFIT_TAB,SUMFIT_OFF,SUMFIT_NUM,NPROGS,NINST,NDEVS,REORD_FLAG
	 public  NELEM,BESTREG,PBESTREG,PLASTREG,MAXREG,PMAXREG
PSUMFIT_TAB dw	 0		; Offset of SUMFIT_TAB
SUMFIT_OFF dw	 ?		; Offset into SUMFIT_TAB
SUMFIT_NUM dw	 ?		; Entry # in SUMFIT_TAB
NPROGS	 dw	 ?		; # programs to fit
NINST	 dw	 ?		; # INSTALL= programs
NDEVS	 dw	 ?		; # device drivers
REORD_FLAG dw	 ?		; Re-ordering flag:  1 = do
				;		     0 = don't
				;		     2 = subsegments only
NELEM	 dw	 ?		; # of elements allocated: MAX(NPROGS,NSUBSEGS)
BESTREG  dw	 ?		; Size of best region fit found so far
MAXREG	 dw	 ?		; ...	  largest ...
PBESTREG dw	 ?		; Pointer to best region fit found so far
PLASTREG dw	 ?		; ...	     last    ...
PMAXREG  dw	 ?		; ...	     largest ...

if @OEM_HARPO
	 public  PSUBSEG_TAB,NSUBSEGS,ISIZES,MINIMA,DLGSIZE,DLGREG
PSUBSEG_TAB dw	 0		; Offset of SUBSEG_TAB
NSUBSEGS dw	 ?		; Number of subsegs
ISIZES	 dw	 @NREGS dup (?) ; Initialization high water mark for each region
MINIMA	 dw	 @NREGS dup (?) ; Minimum differences between regions for
				; programs that use maximal (worst) fit,
				; namely 4B allocators.
DLGSIZE  dw	 0		; Size of DLGROUP
DLGREG	 dw	 @NOTSPEC	; Region for DLGROUP (origin:0)
endif				; IF @OEM_HARPO

	 public  PBPRGORD,PBAPVORD,TEMPOFF,PBTOPFIT,PBAPVBIT,PBAPVMASK
	 public  PBRAPV,PBRFIT,PBPVR,PBEVR,PWREG,PBTPO,PQREXP,PBRPV
PBPRGORD dw	 ?		; Offset of program order table
PBAPVORD dw	 ?		; Offset of APV ...
TEMPOFF  dw	 ?		; Offset of temporary working area
PBTOPFIT dw	 ?		; Offset of top fits
PBAPVBIT dw	 ?		; Offset of available program bit vector
PBAPVMASK dw	 ?		; Offset of available program bit vector mask
PBRAPV	 dw	 ?		; Offset of available program bit vector by max size
PBRFIT	 dw	 ?		; Offset of global fit vector
PBPVR	 dw	 ?		; Offset of global prg vs. region bit vector
PBEVR	 dw	 ?		; Offset of global env vs. region bit vector
PWREG	 dw	 ?		; Offset of global region sizes
PBTPO	 dw	 ?		; Offset of temporary program order vector
PQREXP	 dw	 ?		; Offset of NREGS exponent vector
PBRPV	 dw	 ?		; Offset of recursive product vector

COMMENT|

PBPRGORD    is a grade vector of each program ordered descendingly by tare
	    within one of the three categories (DEvices, INSTALL=, TSRs).

PBRAPV	    is a selection vector applied to PBPRGORD.
	    == (PBAPVBIT & PBAPVMASK) [GradeUp PBAPVORD]

PBAPVORD    is a grade vector of each program resident size (RPARA + 1 + EPAR1)
	    in descending order.  The theory being that we should attempt to
	    place the largest resident programs first.

PBAPVBIT    is a selection vector applied to the programs in APVORD order.

PBAPVMASK   is a selection vector applied to the programs in APVORD order.
	    MASK [ PRGORD [ APVORD]]

|

	 public  BESTSIZE
BESTSIZE dw	 ?		; Top size in paras

ifdef OPTIM
	 public  DISP_CNT,DISP_BSY,ELAPSED,DISP_LOSE5,DISP_LOSE100,BAILOUT
DISP_CNT dw	 ?		; Display update counter
DISP_BSY db	 ?		; Display busy flag:  1 = busy, 0 = not
ELAPSED  dd	 ?		; Seconds elapsed since we started
DISP_LOSE5 db	 ?		; Counter to lose one tic
DISP_LOSE100 db  ?		; Counter to lose one tic
BAILOUT db	 ?		; Set to 0 if Esc not allowed, 1 if allowed,
				; 2 if Esc pressed

@DISP_REF equ	 18		; Refresh about once per second (secondary
@DISP_LOSE5 equ  5		; counters tell us to lose one tick every 5
@DISP_LOSE100 equ 100		; seconds, and one tick every 100 seconds).
				; Ticks occur 18.21 times per second.

	 extrn	 AZS_TOTAL:byte ; Space for formatted total
	 extrn	 AZS_TOTHIGH:byte ; Space for formatted bytes high DOS
	 extrn	 AZS_CUR:byte,AZS_CURTIME:byte ; Space for formatted count, time
	 extrn	 AZS_BEST:byte,AZS_BESTTIME:byte,AZS_BESTBYTES:byte ; Best "
	 extrn	 AZS_BESTPCT:byte ; Space for best count / cur * 100.0
	 extrn	 AZS_BESTBPCT:byte ; Space for best bytes moved / tothigh * 100

; Initialize percentage and offsets.  Blast in segments at run time.
	 public  OPROGRESS
OPROGRESS OPROG_STR	<0,0,\
			offset PGROUP:AZS_CUR,?,\
			offset PGROUP:AZS_CURTIME,?,\
			offset PGROUP:AZS_TOTAL,?,\
			offset PGROUP:AZS_TOTHIGH,?,\
			offset PGROUP:AZS_BEST,?,\
			offset PGROUP:AZS_BESTTIME,?,\
			offset PGROUP:AZS_BESTBYTES,?,\
			offset PGROUP:AZS_BESTPCT,?,\
			offset PGROUP:AZS_BESTBPCT,?>

	 extrn	 _OPT_PROGRESS:dword ; Far entry for progress display update
	 extrn	 _OPT_CALLBACK:dword ; Far entry for query callbacks

	 public  COMBINATIONS,COMBdiv100,COMBdiv1000,COMBINE1
	 public  QWORK1,QWORK2,QWFMTTMP,PROGACT,PROGMASK
	 public  NUMDONE,NUMMAX
	 public  PGSEG,CALL_STACK,SAVE_STACK
	 public  COMBscale100,COMBscale1000
COMBINATIONS dw @LONGWORDS dup (0) ; Total # possibilities we might try
COMBdiv100 dw @LONGWORDS dup (0) ; Combinations / 100
COMBdiv1000 dw @LONGWORDS dup (0) ; Combinations / 1000
COMBINE1 dw @LONGWORDS dup (0)	; Total # possibilities we might try per REGDIF_CNT
COMBscale100 dw ?		; Scale factor for COMBdiv100 (normally 1)
COMBscale1000 dw ?		; Scale factor for COMBdiv1000 (normally 1)
QWORK1	 dw @LONGWORDS dup (0)	; Temporary workspace
QWORK2	 dw @LONGWORDS dup (0)	; Additional temporary workspace
QWFMTTMP dw @LONGWORDS dup (0)
PROGACT  dw	?		; P - j (used during outside loop)
PROGMASK dw	?		; # progams masked out
NUMDONE  dw @LONGWORDS dup (0)	; Counter used for number done so far
NUMMAX	 dw @LONGWORDS dup (0)	; ...		   maximum number ...
PGSEG	 dw	?		; PGROUP segment used for callbacks
CALL_STACK dd	?		; SS:SP used for callbacks from Int 8 handler
SAVE_STACK dd	?		; SS:SP at interrupt time

	 public  BEST_ELAPSED,BEST_COUNT,BEST_BYTES,QWF_PLACE,QWF_BLANK
	 public  LAST_PCTBASE
BEST_ELAPSED	dd	?	; Seconds elapsed at time of last best fit
BEST_COUNT dw @LONGWORDS dup (0) ; Count at time of last best fit
BEST_BYTES	dd	?	; Number of bytes moved high for last best fit
QWF_PLACE	db	?	; Decimal place modulo 3
QWF_BLANK	db	?	; If value is blank, use space rather than 0
LAST_PCTBASE dw @LONGWORDS dup (0) ; Base value used to calculate last percentage
endif				; ifdef OPTIM

UDATA	 ends			; End UDATA segment


ZZTAIL	 segment dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

ZZTAIL	 ends			; End ZZTAIL segment


UCODE	 segment byte public 'ucode' ; Start UCODE segment
	 assume  cs:PGROUP

	 extrn	 CHECK_ORPHAN:near

ifdef OPTIM
	 NPPROC  LWORD_MOV -- Copy long value at ds:si into ES:DI
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

On entry:
DS:SI		address to copy from
ES:DI		address to copy to

On exit:
Nothing.

|

	 REGSAVE <cx,si,di>	; Save registers

	 mov	 cx,@LONGWORDS	; Number of words to move
   rep	 movs	 PGROUP:[di].ELO,PGROUP:[si].ELO ; Move CX words

	 REGREST <di,si,cx>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LWORD_MOV endp			; End LWORD_MOV procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  LWORD_MAX -- Compute Maximum of Two Lwords
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Compute maximum of two lwords.

On entry:

PGROUP:SI ==>	source lword
PGROUP:DI ==>	destin lword

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 mov	 cx,@LONGWORDS	; Number of words to traverse
	 add	 si,@LONGWORDS*2 ; Skip to end+1
	 add	 di,@LONGWORDS*2 ; Skip to end+1
@@:
	 sub	 si,2		; Back off to previous source word
	 sub	 di,2		; ...		       destin ...

	 mov	 ax,PGROUP:[si].ELO ; Get next lower-order source word

	 cmp	 ax,PGROUP:[di].ELO ; Izit larger than destin?
	 jb	 short LWORD_MAX_EXIT ; Jump if destin is larger
	 ja	 short LWORD_MAX_COPY ; Jump if source is larger

	 loop	 @B		; Jump if more words to check

; The two lwords are equal:  just exit

	 jmp	 short LWORD_MAX_EXIT ; Join common exit code

LWORD_MAX_COPY:
	 sub	 si,cx		; Back off source to start
	 sub	 si,cx		; ...
	 add	 si,2		; Take into account CX as length vs. SI as addr
	 sub	 di,cx		; Back off destin to start
	 sub	 di,cx		; ...
	 add	 di,2		; Take into account CX as length vs. SI as addr
     rep movs	 PGROUP:[di].ELO,PGROUP:[si].ELO ; Copy remainder of words
LWORD_MAX_EXIT:
	 REGREST <di,si,cx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LWORD_MAX endp			; End LWORD_MAX procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  LWORD_SET -- Extend AX as a Lword at PGROUP:DI
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

On entry:
AX		16-bit unsigned value to extend
PGROUP:DI ==>	address to store at

No registers changed on exit.

|

	 REGSAVE <ax,cx,di>	; Save registers

	 stos	 PGROUP:[di].ELO ; Set low order word

	 mov	 cx,@LONGWORDS-1 ; Number of high-order words - low word
	 sub	 ax,ax		; Get a 0 value
   rep	 stos	 PGROUP:[di].ELO ; Clear high order words

	 REGREST <di,cx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LWORD_SET endp			; End LWORD_SET procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  LWORD_ADD -- Add Lwords at PGROUP:SI & PGROUP:DI
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Add lwords at PGROUP:SI and at PGROUP:DI.  Store sum in PGROUP:DI.

On entry:
PGROUP:SI	==>	source operand
PGROUP:DI	==>	destination operand

On exit:
PGROUP:DI	==>	sum
CF=1			value exceeded @LONGWORDS words

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 mov	 cx,@LONGWORDS	; Number of words to add
	 clc			; Initialize CF from last result
@@:
	 lods	 PGROUP:[si].ELO ; Get source word
	 adc	 PGROUP:[di].ELO,ax ; Add CF and source to destin
				; Return CF significant
	 inc	 di		; Skip to next destin word
	 inc	 di		; ...without changing CF

	 loop	 @B		; Do all the words

	 REGREST <di,si,cx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LWORD_ADD endp			; End LWORD_ADD procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  LWORD_SUB -- Subtract PGROUP:SI from PGROUP:DI
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Subtract lword at PGROUP:SI from lword at PGROUP:DI,
leaving difference at PGROUP:DI.

On entry:
PGROUP:DI	==>	 minuend
PGROUP:SI	==>	 subtrahend

On exit:
PGROUP:DI	==>	 difference
CF=1			 underflow occurred
CF=0			 no underflow

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 mov	 cx,@LONGWORDS	; Number of words to subtract
	 clc			; Initialize CF from last result
@@:
	 lods	 PGROUP:[si].ELO ; Get source word
	 sbb	 PGROUP:[di].ELO,ax ; Subtract CF and source from destin
				; Return CF significant
	 inc	 di		; Skip to next destin word
	 inc	 di		; ...without changing CF

	 loop	 @B		; Do all the words

	 REGREST <di,si,cx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LWORD_SUB endp			; End LWORD_SUB procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  LWORD_MUL16 -- Multiply Lword at PGROUP:DI by AX
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Multiply lword at PGROUP:[DI] by AX, leaving result in place.

On entry:
AX			16-bit multiplier
PGROUP:DI	==>	Lword multiplicand

On exit:
PGROUP:DI	==>	Lword product (carries past 8 bytes ignored)
AX			Top 16 bits carried out (if any)

|
	 REGSAVE <bx,cx,dx,di>	; Save registers

	 mov	 cx,@LONGWORDS	; Number of words to subtract
	 mov	 bx,ax		; Put multiplier in BX
	 sub	 ax,ax		; Initialize high word of last result
LWMUL16_LOOP:
	 xchg	 ax,PGROUP:[di].ELO ; Save high word of last result, get next
	 mul	 bx		; DX:AX = product
	 add	 ax,PGROUP:[di].ELO ; Add low word of product in
	 stos	 PGROUP:[di].ELO ; Save back, skip to next destin word
	 mov	 ax,dx		; Prepare to put in low word

	 loop	 LWMUL16_LOOP	; Jump if more words to multiply

	 REGREST <di,dx,cx,bx>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LWORD_MUL16 endp		; End LWORD_MUL16 procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  LWORD_DIV16 -- Divide Lword at PGROUP:DI by AX
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Divide lword at PGROUP:DI by AX.  Leave quotient in place, return remainder
in AX.

On entry:
PGROUP:DI	==>	Lword dividend
AX			16-bit divisor

On exit:
PGROUP:DI	==>	Lword quotient
AX			Remainder
CF=1			Quotient is zero

|

	 REGSAVE <bx,cx,dx,si,di> ; Save registers

	 mov	 bx,ax		; Use BX for divisor
	 mov	 cx,@LONGWORDS	; Number of words to subtract
	 add	 di,(@LONGWORDS-1)*2 ; Skip to last word in lword
	 sub	 dx,dx		; Initialize high word of last result
	 xor	 si,si		; Initialize accumulative dividend

	 pushf			; Save flags
	 std			; Point direction flag downwards
LWDIV16_LOOP:
	 mov	 ax,PGROUP:[di].ELO ; Get dividend word in low word of dword
	 div	 bx		; Divide DX:AX by BX
	 or	 si,ax		; Accumulate quotient to check for zero
	 stos	 PGROUP:[di].ELO ; Save quotient; remainder in DX becomes
				; high word of next 32-bit dividend
	 loop	 LWDIV16_LOOP	; Jump if index still valid

	 popf			; Restore direction flag

	 mov	 ax,dx		; Return remainder
	 or	 si,ax		; Accumulate quotient to check for zero

	 cmp	 si,1		; Check for zero quotient
				; Return CF=1 if it's zero, CF=0 if not
	 REGREST <di,si,dx,cx,bx>  ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LWORD_DIV16 endp		; End LWORD_DIV16 procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  TIME_FMT -- Format DX:AX seconds as HH:MM:SS
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

On entry:
DX:AX		Seconds (if DX >= 60, truncate.  Max. hours is 1092, but only
			last 2 digits will be displayed)
DS:DI	==>	Destination for HH:MM:SS,0

|

	 REGSAVE <bx>		; Save register

	 mov	 bx,60		; Divisor constant
	 cmp	 dx,bx		; Are we risking divide overflow?
	 jb	 short @F	; No, it's OK

	 mov	 dx,59		; Set to maximum value
@@:
	 push	 ax		; Save for a moment
	 or	 ax,dx		; Izit 0?
	 pop	 ax		; Restore AX
	 jz	 short @F	; Skip division (note both AX and DX are 0)

	 div	 bx		; AX=quotient, DX=remainder
	 xchg	 ax,dx		; Get remainder
	 aam			; Convert AX to unpacked BCD

@@:
	 or	 ax,'00'        ; Convert to ASCII
	 xchg	 ah,al		; Reverse byte order
	 mov	 PGROUP:[di].TIME_SECS,ax ; Put in output

	 mov	 ax,dx		; Get quotient of last divide
	 or	 ax,ax		; Izit 0?
	 jz	 short @F	; Skip division (note both AX and DX are 0)

	 sub	 dx,dx		; Clear high word of dividend
	 div	 bx		; AX=hours, DX=minutes
	 aam			; Convert hours to BCD
	 xchg	 ax,dx		; Get minutes
	 aam			; Convert minutes to BCD

@@:
	 or	 ax,'00'        ; Convert minutes to ASCII
	 xchg	 ah,al		; Reverse byte order
	 or	 dx,'00'        ; Convert hours to ASCII
	 xchg	 dh,dl		; Reverse byte order
	 mov	 PGROUP:[di].TIME_MINS,ax ; Minutes
	 mov	 PGROUP:[di].TIME_HOURS,dx ; Hours

	 mov	 PGROUP:[di].TIME_COL1,':' ; First colon
	 mov	 PGROUP:[di].TIME_COL2,':' ; Second colon

	 REGREST <bx>		; Restore register

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

TIME_FMT endp			; End TIME_FMT procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  FMT_TPCT -- Format AX as nnn.n pct in PGROUP:DI
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Format AX at PGROUP:DI as an ASCIIZ decimal string.  Insert a '.' before
the last digit and add '%'.  Right justify the whole mess.

On entry:
AX		=	Value to format
PGROUP:DI	==>	Space for thousandth percentage output

On exit:
Nothing.

|

	 REGSAVE <bx,cx,dx,di>	; Save registers

; Initialize to "  0.0%"
	 mov	 PGROUP:[di+@PCTDSPC-3].ELO,'%0' ; "xxxx0%",0
	 mov	 PGROUP:[di+@PCTDSPC-5].ELO,@NATL_DECIMAL shl 8 + '0' ; "xx0.xx",0
	 mov	 PGROUP:[di+@PCTDSPC-7].ELO,'  ' ; "  xxxx",0

	 or	 ax,ax		; Izit 0?
	 jz	 short FB_PCTDONE ; Jump if 0

	 sub	 dx,dx		; Prepare for division
	 add	 di,@PCTDSPC-3	; Point to end - 2
	 std			; Do everything backwards
	 mov	 bx,10		; Get divisor for base 10
	 div	 bx		; Quotient in AX, remainder in DX
	 xchg	 dx,ax		; Get remainder
	 or	 al,'0'         ; Convert to ASCII
	 stos	 PGROUP:[di].LO ; Blast it in
	 dec	 di		; Skip over '.'
	 mov	 cx,3		; Number of digits remaining
FB_PCTLOOP:
	 mov	 ax,dx		; Get last quotient
	 or	 ax,ax		; Izit 0?
	 jz	 short FB_PCTDONE ; Jump if so

	 cwd			; Prepare for 16-bit divide
	 div	 bx		; Divide DX:AX
	 xchg	 dx,ax		; Get remainder
	 or	 al,'0'         ; Convert to ASCII
	 stos	 PGROUP:[di].LO ; Save a digit
	 loop	 FB_PCTLOOP	; Repeat until done

FB_PCTDONE:
	 cld			; Restore normal direction
	 REGREST <di,dx,cx,bx>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FMT_TPCT endp			; End FMT_TPCT procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  LWORD_FMT -- Format Lword from PGROUP:SI as ASCII Decimal
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Format the lword at PGROUP:SI as an ASCIIZ decimal string at PGROUP:DI.
Numeric output is right justified, with commas, and with all spaces leading.

On entry:
PGROUP:DI	==>	Space for ASCIIZ output
PGROUP:SI	==>	Lword to format
CX			Number of spaces (not including trailing NULL)

|

	 REGSAVE <ax,bx,cx,di> ; Save registers

	 mov	 bx,di		; Use BX to write
	 add	 bx,cx		; Point to end (NULL)
	 dec	 bx		; Move back to previous byte (1's)

	 lea	 di,QWFMTTMP	; Temporary value to divide
	 call	 LWORD_MOV	; Copy PGROUP:SI to PGROUP:DI

	 mov	 QWF_PLACE,4	; Reset place counter
	 mov	 QWF_BLANK,0	; Clear blank flag

QWF_LOOP:
	 cmp	 QWF_BLANK,1	; Izit all blank?
	 je	 short QWF_NODIGITS ; Don't display digits

	 dec	 QWF_PLACE	; Adjust place counter
	 jnz	 short @F	; Haven't hit a comma yet

	 mov	 QWF_PLACE,4	; Reset counter
	 mov	 al,@NATL_THOU	; Character to display

	 jmp	 short QWF_STO	; Display character

@@:
	 mov	 ax,10		; Divisor
	 call	 LWORD_DIV16	; QWORK1 /= 10, AX = remainder
	 jc	 short QWF_ENDDIGITS ; Quotient is 0; no more to display

	 add	 al,'0'         ; Convert to ASCII

	 jmp	 short QWF_STO	; Join common code

QWF_ENDDIGITS:
	 inc	 QWF_BLANK	; Set blank flag

	 cmp	 QWF_PLACE,3	; Did we stop at hundreds, leaving leading ','?
	 jne	 short QWF_NODIGITS ; No, so comma is OK

	 mov	 PGROUP:[bx+1].LO,' ' ; Zap comma

QWF_NODIGITS:
	 mov	 al,' '         ; Blank

QWF_STO:
	 mov	 PGROUP:[bx].LO,al ; Dump a character

	 dec	 bx		; Move one place to the left

	 loop	 QWF_LOOP	; If more spaces to fill, keep going

QWF_DONE:
	 REGREST <di,cx,bx,ax> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LWORD_FMT endp			; End LWORD_FMT procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  CALC_DOMAIN -- Calculate total number of possibilities
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Calculate the total number of possible combinations as
(NREGS+1)^(NPROGS-PROGMASK).

On exit:

COMBINATIONS =	 total # combinations
COMBdiv100   =	 final product div 100
COMBdiv1000  =	 COMBINATIONS div 1000

|

	 REGSAVE <ax,cx,si,di> ; Save registers

	 mov	 ax,1		; Set X[0] to 1
	 lea	 di,COMBINATIONS ; Point to result
	 call	 LWORD_SET	; Extend AX to long at PGROUP:DI

	 mov	 cx,NPROGS	; Initialize loop counter
	 sub	 cx,PROGMASK	; Less # programs masked out
	 jz	 short CD1	; Just in case
@@:
	 mov	 ax,NREGS	; R (number of regions)
	 inc	 ax		; Plus low DOS memory region
	 call	 LWORD_MUL16	; PGROUP:[DI] *= AX
				; Returning AX = overflow (if any)
	 loop	 @B		; Jump if more
CD1:
	 lea	 si,COMBINATIONS ; Get pointer to values
	 lea	 di,COMBINE1	; Get pointer to values
	 call	 LWORD_MOV	; Copy COMBINATIONS to COMBINE1

if @OEM_FLEX
	 cmp	 REORD_FLAG,1	; Allow re-ordering?
	 jne	 short @F	; Jump if not

; Multiply the result by # of regions adjoining EMS-mappable pages

	 lea	 di,COMBINATIONS ; Get pointer to values
	 mov	 ax,REGDIF_CNT	; Get # of regions abutting EMS-mappable pages
	 call	 LWORD_MUL16	; PGROUP:[DI] *= AX
				; Returning AX = overflow (if any)
@@:
endif				; @OEM_FLEX

; Calculate percentages and scale factors.  Since we calculate integer
; percentages by repeated subtraction, we must ensure that our granularity
; is not greater than the total combinations.  We keep scale factors to
; multiply the final result by.  The scale factors are initialized to 1
; in RESET_DATA.

	 lea	 si,COMBINATIONS ; Prepare to load COMBINATIONS
	 lea	 di,COMBdiv100	; Initialize COMBINATIONS div 100
	 call	 LWORD_MOV	; Divide COMBINATIONS...

	 lea	 di,COMBdiv1000 ; Initialize COMBINATIONS div 1000
	 call	 LWORD_MOV	; Set to total

	 mov	 ax,1000	; Value to compare against
	 lea	 di,QWORK1	; Temporary Lword
	 call	 LWORD_SET	; Convert AX to Lword
	 call	 LWORD_SUB	; Is total < 1000 (no CF if so)?
	 jnc	 short @F	; Jump if so

; COMBINATIONS >= 1000 -- this is the only case where COMBdiv1000 is different
	 lea	 di,COMBdiv1000 ; Divident / quotient
	 call	 LWORD_DIV16	; Divide by AX

	 mov	 ax,100 	; Divisor
	 lea	 di,COMBdiv100	; Dividend / quotient
	 call	 LWORD_DIV16	; Divide by AX
	 jmp	 CD_PCTDONE	; Done with percentages and scale factors

@@:
; COMBdiv1000 will now be the same as whatever we calculate for COMBdiv100,
; and COMBscale1000 will be COMBscale100 * 10
	 mov	 ax,100 	; Put divisor in AX
	 lea	 di,QWORK1	; Value to compare
	 call	 LWORD_SET	; Extend AX through QWORK1
	 call	 LWORD_SUB	; Subtract combinations from QWORK1
	 jnc	 short @F	; Jump if COMBINATIONS < 100

	 lea	 di,COMBdiv100	; Dividend / quotient
	 call	 LWORD_DIV16	; Divide it by AX
	 jmp	 short CD_PCTSCALE ; Copy COMBdiv100 to div1000 and mul scale

@@:
; Combinations are less than 100
	 mov	 ax,10		; Try divisor of 10
	 mov	 COMBscale100,ax ; Set scale factor
	 call	 LWORD_SET	; Extend through QWORK1
	 call	 LWORD_SUB	; Subtract combinations from QWORK1
	 jnc	 short @F	; Jump if < 10

	 lea	 di,COMBdiv100	; Dividend / quotient
	 call	 LWORD_DIV16	; Divide by AX
	 jmp	 short CD_PCTSCALE ; Copy to div100 and multiply scale by 10

@@:
; Combinations are less than 10; leave divisor (Combdiv100*) unchanged and quit
	 mov	 COMBscale100,100 ; Set scale factor

CD_PCTSCALE:
	 lea	 si,COMBdiv100	; Copy COMBdiv100
	 lea	 di,COMBdiv1000 ; ...to destination
	 call	 LWORD_MOV	; Move it

	 mov	 al,10		; Calculate COMBscale1000
	 mul	 COMBscale100.LO ; AX = 1000 percent scale factor
	 mov	 COMBscale1000,ax ; Save for later use

CD_PCTDONE:
; Now initialize PQREXP (NREGS^iota (NPROGS+1-PROGMASK))

	 mov	 ax,1		; Set first element to 1 ((NREGS+1)^0)
	 mov	 di,PQREXP	; Get pointer to exponent list
	 mov	 si,di		; Save pointer to previous term
	 call	 LWORD_SET	; Initialize long value

	 mov	 cx,NPROGS	; Get count of exponents
	 inc	 cx		; Count in zero case
	 sub	 cx,PROGMASK	; Less # programs masked out
CD_PQREXP:
	 add	 di,@LONGWORDS*2 ; Point to next destin element
	 call	 LWORD_MOV	; Copy previous element to current

	 mov	 ax,NREGS	; Get # regions
	 call	 LWORD_MUL16	; Multiply by previous element
				; Returning AX = overflow (if any)
	 add	 si,@LONGWORDS*2 ; Point to next source element

	 loop	 CD_PQREXP	; Next exponent

if @OEM_HARPO
; If there are more subsegments than programs+1, we need to fill the
; remaining elements with 1.
	 mov	 cx,NELEM	; Number of elements in array
	 add	 cx,PROGMASK	; Add programs we skipped
	 sub	 cx,NPROGS	; Get number we've done so far
	 jz	 short CD_PQREXPDONE ; Jump if no additional elements

	 mov	 ax,1		; Identity element for multiplication
CD_PQREXP2:
	 add	 di,@LONGWORDS*2 ; Point to next destin element
	 call	 LWORD_SET	; Initialize long value
	 loop	 CD_PQREXP2	; Next element to fill

CD_PQREXPDONE:
endif				; IF @OEM_HARPO

	 REGREST <di,si,cx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CALC_DOMAIN endp		; End CALC_DOMAIN procedure
endif				; ifdef OPTIM
ifdef OPTIM
	 NPPROC  RECALC_PCT -- Calculate Percentage And Update Display
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Called from timer tick (OPTINT8) ~once per second.

Divide the total number processed by COMBdiv100 by repeated subtraction
(maximum quotient allowed is 100).  Update percentage, format numeric
output, and refresh the display unconditionally.

No registers used.

|

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

	 inc	 DISP_BSY	; Disable interrupt-driven display

	 sub	 ax,ax		; Clear AX
	 lea	 di,QWORK1	; Get address to blast into
	 call	 LWORD_SET	; Set lword to AX extended

	 mov	 cx,LVL 	; Set up for loop
	 inc	 cx		; Count in current level
	 jz	 short RP_ADDNUM ; If not recursing, don't calculate sum

	 mov	 si,PQREXP	; Address recursive exponent vector
	 mov	 ax,@LONGWORDS*2 ; Get # bytes per exponent value
	 mul	 PROGACT	; Times # programs we're trying to fit
	 add	 si,ax		; Point to last exponent+1
	 mov	 bx,PBRPV	; Address recursive product vector

; Multiply each element of recursive exponent vector by corresponding
; recursive product vector value.  Sum all products into QWORK1.

RP_CALCRPV:
	 sub	 si,@LONGWORDS*2 ; Point to previous exponent

	 lea	 di,QWORK2	; Temporary copy of recursive exponent
	 call	 LWORD_MOV	; Copy exponent to QWORK2

	 mov	 al,PGROUP:[bx].LO ; Get RPV value
	 sub	 ah,ah		; Prepare to use as word
	 call	 LWORD_MUL16	; Multiply QWORK2 by AX
				; Returning AX = overflow (if any)
	 push	 si		; Save recursive exponent pointer

	 lea	 si,QWORK2	; Use QWORK2 as source
	 lea	 di,QWORK1	; Add to QWORK1
	 call	 LWORD_ADD	; Add QWORK2 to QWORK1

	 pop	 si		; Restore recursive exponent pointer

	 inc	 bx		; Point to next RPV value (last to first)

	 loop	 RP_CALCRPV	; Get next byte in array

RP_ADDNUM:
	 lea	 si,NUMDONE	; Get number done so far
	 lea	 di,QWORK1	; Get QWORK1
	 call	 LWORD_ADD	; Add NUMDONE to QWORK1

; We take the maximum so far so as to smooth out the case where
; we backtrack finding an environment fit the work for which isn't
; counted in the total # combinations.

	 lea	 si,QWORK1	; Get QWORK1
	 lea	 di,NUMMAX	; Get maximum number done so far
	 call	 LWORD_MAX	; Put max of the two lwords at SI and DI into DI

	 lea	 si,NUMMAX	; Get maximum number done so far
	 lea	 di,AZS_CUR	; "   n,nnn,nnn...",0
	 mov	 cx,@LONGSPC-1	; length (not including null)
	 call	 LWORD_FMT	; Format it

;;;;;;;; lea	 si,NUMMAX	; Get maximum number done so far
	 lea	 di,QWORK1	; Get QWORK1
	 call	 LWORD_MOV	; Copy PGROUP:SI to PGROUP:DI

	 mov	 ax,OPROGRESS.OPROG_PCT ; Initialize percentage to last
	 lea	 si,LAST_PCTBASE ; Address percentage base
	 call	 LWORD_SUB	; Subtract from QWORK1
	 mov	 bx,si		; Save pointer to percentage base
	 lea	 si,COMBdiv100	; Address divisor
@@:
	 cmp	 ax,100 	; Izit 100%?
	 jnb	 short @F	; If so, we're done.

	 call	 LWORD_SUB	; QWORK1 -= COMBdiv100
	 jc	 short @F	; If it doesn't fit, stop

	 add	 ax,COMBscale100 ; Bump percentage

	 xchg	 bx,di		; Address percentage base
	 call	 LWORD_ADD	; LAST_PCTBASE += CombDiv100
	 xchg	 bx,di		; Restore QWORK1 pointer
	 jmp	 short @B	; Go around again

@@:
	 mov	 OPROGRESS.OPROG_PCT,ax ; Store calculated percentage

	 mov	 ax,ELAPSED.ELO ; Get seconds elapsed
	 mov	 dx,ELAPSED.EHI ; Get high word of seconds
	 lea	 di,AZS_CURTIME ; "HH:MM:SS",0
	 call	 TIME_FMT	; Format AX seconds

	 test	 UTL_FLAG,@UTL_COT ; Izit re-directed?
	 jz	 short @F	; Jump if it is

	 push	 es		; Save our ES as _OPT_PROGRESS might clobber it

	 lea	 bx,OPROGRESS	; Get offset of structure
	 push	 ds		; Pass segment portion of far pointer
	 push	 bx		; Pass offset
	 call	 _OPT_PROGRESS	; Draw message box
	 add	 sp,2*2 	; Remove DS:BX from stack

	 pop	 es		; Restore our ES
	 assume  es:PGROUP	; Tell the assembler
@@:

	 dec	 DISP_BSY	; Enable interrupt-driven display

	 REGREST <di,si,dx,cx,bx,ax> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

RECALC_PCT	 endp		; End RECALC_PCT procedure
endif				; ifdef OPTIM
if @OEM_HARPO
	 NPPROC  MIN_REGDIFF -- Find minimum region difference
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

If the current entry is a UMB with EPAR0 != 0, find the smallest difference
between REGTAB[BX] and other regions.  Save the minimum of that value
and MINIMA[BX] in MINIMA[BX].

When we're done, we'll use MINIMA[] as maximum values for ISIZES[].
This prevents using unused space and forcing a maximal (worst) fit
into another region.

On entry:
BX	 Index into REGTAB
SI	 Offset in PGROUP of SUMFIT_STR

On exit:
MINIMA[BX] updated

|

	 REGSAVE <ax,cx,dx,di>	; Save

	 test	 PGROUP:[si].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jz	 short MRD_EXIT ; Jump if not

	 cmp	 PGROUP:[si].SUMFIT_EPAR0,0 ; Izit a maximal (worst) fit?
	 je	 short MRD_EXIT ; Jump if not

	 sub	 di,di		; Starting index into REGTAB
	 mov	 cx,NREGS	; Number of regions to check
	 mov	 dx,MINIMA[bx]	; Get current minimum difference
MRD_NEXTUMB:
	 cmp	 bx,di		; Izit the same region?
	 je	 short @F	; Skip it if so

	 mov	 ax,REGTAB[bx]	; Get remaining space in this region
	 sub	 ax,REGTAB[di]	; Get difference
	 jc	 short @F	; Jump if larger

	 cmp	 ax,dx		; Izit smaller?
	 jnb	 short @F	; Jump if not

	 mov	 dx,ax		; Save new minimum value
@@:
	 add	 di,type REGTAB ; Skip to next region
	 loop	 MRD_NEXTUMB	; Go around again

	 mov	 MINIMA[bx],dx	; Save new minimum
MRD_EXIT:
	 REGREST <di,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

MIN_REGDIFF endp		; End MIN_REGDIFF procedure
endif				; IF @OEM_HARPO
	 NPPROC  CHKMEM_ANY -- Check For Room In Any Region
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Check for room in any region.

On entry:

AX	 =	 # paras needed to install
DX	 =	 # paras needed to go resident (DX <= AX)
PGROUP:SI ==>	 SUMFIT_STR

On exit:

CF	 =	 0 if successful (REGTAB updated)
	 =	 1 otherwise

|

	 REGSAVE <bx,cx,si,di,bp> ; Save registers

	 mov	 cx,NREGS	; Get # regions
	 xor	 bx,bx		; Initialize index into REGTAB
	 mov	 di,PGROUP:[si].SUMFIT_FLAG ; Get flags
CHKMEM_ANY_NEXT:
	 mov	 si,REGTAB[bx]	; Get current region size in paras
	 mov	 bp,si		; Save size without FLEXFRAME
if @OEM_FLEX
	 test	 di,@LSEG_FLEX	; FLEXFRAME allowed?
	 jz	 short @F	; Jump if not

	 add	 si,REGEMS[bx]	; Plus any adjacent EMS mappable paras
@@:
endif				; IF @OEM_FLEX
	 cmp	 si,ax		; Any room at the inn?
	 jc	 short CHKMEM_ANY_XFIT ; Jump if not

	 cmp	 bp,dx		; Ensure resident size fits as well
	 jc	 short CHKMEM_ANY_XFIT ; Jump if not

if @OEM_HARPO
; Unused space is MIN (UNUSED_INIT, UNUSED_RES).  We can use more
; FLEXFRAME memory if necessary.
	 REGSAVE <si>		; Save

	 sub	 bp,dx		; Calculate resident memory not used
	 sub	 si,ax		; Calculate initialization memory not used
	 cmp	 bp,si		; Is there less unused initialization space?
	 jb	 short @F	; Jump if not

	 mov	 bp,si		; Take the smaller value
@@:
	 REGREST <si>		; Restore

	 call	 MIN_REGDIFF	; Find smallest difference between REGTAB[BX]
				; and other regions.

	 cmp	 bp,ISIZES[bx]	; Izit smaller than previous remaining size?
	 jnb	 short @F	; Jump if not

	 mov	 ISIZES[bx],bp	; Save unused space for subsegment optimization
@@:
endif				; IF @OEM_HARPO
	 sub	 REGTAB[bx],dx	; Subtract from region size (note CF=0)

	 jmp	 short CHKMEM_ANY_EXIT ; Join common code (note CF=0)

CHKMEM_ANY_XFIT:
	 add	 bx,type REGTAB ; Skip to next region

	 loop	 CHKMEM_ANY_NEXT ; Jump if more regions to try

	 stc			; Indicate no room
CHKMEM_ANY_EXIT:
	 REGREST <bp,di,si,cx,bx> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHKMEM_ANY endp 		; End CHKMEM_ANY procedure
	 NPPROC  CHKMEM_REG -- Check For Room In A Specified Region
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Check for room in a specified region.

On entry:

BL	 =	 region # (origin-1)
AX	 =	 # paras needed to install
DX	 =	 # paras needed to go resident (DX <= AX)
SI	 =	 SUMFIT_STR

On exit:

CF	 =	 0 if successful (REGTAB updated)
	 =	 1 otherwise

|

	 REGSAVE <bx,di,bp>	; Save registers

	 xor	 bh,bh		; Zero to use as word
	 dec	 bx		; Convert to origin-0
	 shl	 bx,1		; Times two to index table of words

	 mov	 di,REGTAB[bx]	; Get current region size in paras
	 mov	 bp,di		; Save size without FLEXFRAME
if @OEM_FLEX
	 test	 PGROUP:[si].SUMFIT_FLAG,@LSEG_FLEX ; FLEXFRAME allowed?
	 jz	 short @F	; Jump if not

	 add	 di,REGEMS[bx]	; Plus any adjacent EMS mappable paras
@@:
endif				; IF @OEM_FLEX
	 cmp	 di,ax		; Any room at the inn?
	 jc	 short CHKMEM_REG_XFIT ; Jump if not (note CF=1)

	 cmp	 bp,dx		; Ensure resident size fits as well
	 jc	 short CHKMEM_REG_XFIT ; Jump if not (note CF=1)

if @OEM_HARPO
; Unused space is MIN (UNUSED_INIT, UNUSED_RES).  We can use more
; FLEXFRAME memory if necessary.
	 REGSAVE <di>		; Save

	 sub	 bp,dx		; Calculate resident memory not used
	 sub	 di,ax		; Calculate initialization memory not used
	 cmp	 bp,di		; Is there less unused initialization space?
	 jb	 short @F	; Jump if not

	 mov	 bp,di		; Take the smaller value
@@:
	 REGREST <di>		; Restore

	 call	 MIN_REGDIFF	; Find smallest difference between REGTAB[BX]
				; and other regions.

	 cmp	 bp,ISIZES[bx]	; Izit smaller than previous remaining size?
	 jnb	 short @F	; Jump if not

	 mov	 ISIZES[bx],bp	; Save unused space for subsegment optimization
@@:
endif				; IF @OEM_HARPO
	 sub	 REGTAB[bx],dx	; Less actual amount used (note CF=0)
CHKMEM_REG_XFIT:
	 REGREST <bp,di,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHKMEM_REG endp 		; End CHKMEM_REG procedure
	 NPPROC  TRIALSUB -- Trial fit subroutine
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Does the work for TRIALFIT, with the GETSIZE check optional.

Note that while checking for a fit, we also calculate the total space
used by resident programs in each region (REGTAB) as well as the remaining
space unused by initialization or resident size (ISIZES).  We also need
to be sensitive to the order specified in the SUMFIT_ORD field, which
may be FF for programs left low or a 0-based order number.

As we're calculating the values in REGTAB and ISIZES in preparation
for subsegment optimization, we need to watch out for UMBs with
SUMFIT_EPAR0 != 0 (these will always be 4B PSPs).  When we find
such a beast in a region R with size S, we need to search all other
REGTAB values for the smallest V=S-REGTAB[n], and set MINIMA[R]
to min (MINIMA[R], V).	When we're done, we need to save the
minimum of MINIMA and ISIZES in ISIZES.  This prevents us from
placing a subsegment in a region such that that region is no
longer the largest region, and the maximal (worst) fit approach
taken for 4B allocations goes to another region.

We do the initialization of MINIMA[] here, but calculate the values
in CHKMEM_REG and CHKMEM_ANY.

On entry:
AX=0	 Check for 386MAX PRGREG!=0 or following GETSIZE entries
AX=1	 Skip GETSIZE check, process in order, ignore programs left low,
	 and use PBTOPFIT rather than PSUMFIT.

AX	 =	 0 if programs didn't fit
	 =	 1 if programs fit
	 =	 2 if MAC error

|

TRSUB_LCL struc 		; Local variables for TRIALSUB:
TRSUB_INORDER db ?,?		; Input flag: 1 to process in order & skip low
TRSUB_CURORD dw ?		; Current order to process
TRSUB_PREG db ? 		; Program region # (1-based)
TRSUB_EREG db ? 		; Environment region # (1-based)
TRSUB_PBTOPFIT dw ?		; Saved TOPFIT pointer
TRSUB_LCL ends

	 REGSAVE <bx,cx,dx,si,di,bp> ; Save registers

	 sub	 sp,size TRSUB_LCL ; Allocate space for local variables
	 mov	 bp,sp		; Address it

	 mov	 [bp].TRSUB_INORDER,al ; Save input flag
	 mov	 [bp].TRSUB_CURORD,0 ; Initialize current order

if @OEM_HARPO
; Initialize MINIMA to the identity element for MIN(x,y)
	 mov	 ax,-1		; Identity element for min (x,y)
	 mov	 cx,@NREGS	; Number of elements to initialize
	 lea	 di,MINIMA	; Values to initialize
   rep	 stos	 MINIMA[di]	; Initialize it
endif				; IF @OEM_HARPO

	 FCALL	 CALCREG	; Calculate region sizes
	MJ c	 TRIALFIT_ERRMAC ; Jump if MAC error

	 cmp	 NREGS,0	; Any high DOS memory available?
	MJ e	 TRIALFIT_NOROOM ; Jump if not

TRIALSUB_NEXTORD:
	 mov	 cx,NPROGS	; CX = # programs loaded
	 mov	 si,PSUMFIT_TAB ; DS:SI ==> start of SUMFIT table
	 mov	 di,PBTOPFIT	; DS:DI ==> optimized RFIT table (if TRSUB_INORDER)
	 mov	 [bp].TRSUB_PBTOPFIT,di ; Save for later

COMMENT|

If the first entry is for 386MAX (where else can it be???), and
either of the following are true:

* NOLOADHI is specified
* PRGREG=0 is specified and
  there are no following entries with GETSIZE specified,

then skip the first entry (386MAX).

|

	 cmp	 [bp].TRSUB_INORDER,0 ; Should we check for MAX high or GETSIZE?
	 jne	 short TRIALFIT_NEXTPROG ; Jump if not

	 cmp	 PGROUP:[si].SUMFIT_GRP,@GRPMAX ; Izit 386MAX?
	 jne	 short TRIALFIT_NEXTPROG ; Jump if not

	 test	 PGROUP:[si].SUMFIT_FLAG,@LSEG_XLHI ; Izit NOLOADHI?
	MJ nz	 TRIALFIT_LOOP	; Jump if so

	 cmp	 PGROUP:[si].SUMFIT_PREG,0 ; Izit PRGREG=0
	 jne	 short TRIALFIT_NEXTPROG ; Jump if not

; Trundle through the LSEG chain looking for GETSIZE entries

	 REGSAVE <ax,es>	; Save for a moment

	 mov	 ax,LOADSEG	; Get start of LSEG chain
TRIALFIT1:
	 cmp	 ax,-1		; Izit the end?
	 je	 short TRIALFIT3 ; Jump if so (note ZF=1)

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[0].LSEG_GRP,@GRPMAX ; Izit 386MAX?
	 je	 short TRIALFIT2 ; Jump if so

	 mov	 ax,es:[0].LSEG_ASIZE.ELO ; Get low-order of actual size
	 and	 ax,es:[0].LSEG_ASIZE.EHI ; ...and with high-order ...
				; If both -1, then AX = -1

	 cmp	 ax,-2		; Check against -2 to generate proper ZF
	 ja	 short TRIALFIT3 ; Jump if GETSIZE specified (note ZF=0)
TRIALFIT2:
	 mov	 ax,es:[0].LSEG_NEXT ; Get segment of next entry

	 jmp	 TRIALFIT1	; Go around again

TRIALFIT3:
	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it
	MJ e	 TRIALFIT_LOOP	; Jump if no following GETSIZE entries
TRIALFIT_NEXTPROG:

; If ENVREG not specified, or ENVREG = PRGREG, allocate space together
; Note that if PRGREG = 0, then ENVREG = @NOTSPEC

	 mov	 bl,PGROUP:[si].SUMFIT_PREG ; Get program region #
	 mov	 bh,PGROUP:[si].SUMFIT_EREG ; Get environment region #

	 cmp	 [bp].TRSUB_INORDER,0 ; Are we processing programs in order?
	 je	 short @F	; Jump if not

	 mov	 ax,[bp].TRSUB_CURORD ; Get current order in AL
	 cmp	 PGROUP:[di].RFIT_PORD,al ; Izit the one we're looking for?
	MJ ne	 TRIALFIT_LOOP	; Jump if not

	 mov	 bl,PGROUP:[di].RFIT_PREG ; Get optimized program region #
	 add	 bl,1		; Make it 1-based
	 sbb	 bl,0		; If unspecified, put it back the way it was
	 mov	 bh,PGROUP:[di].RFIT_EREG ; Get optimized environment region #
	 add	 bh,1		; Make it 1-based
	 sbb	 bh,0		; If unspecified, put it back the way it was
@@:
	 mov	 di,PGROUP:[si].SUMFIT_FLAG ; Get SUMFIT flags for FLEXFRAME

	 mov	 [bp].TRSUB_PREG,bl ; Save program region
	 mov	 [bp].TRSUB_EREG,bh ; Save environment region

	 cmp	 bh,@NOTSPEC	; Environment region # specified?
	 je	 short TRIALFIT_SAME ; Not this time, allocate in same region

	 cmp	 bl,@NOTSPEC	; Program region # specified?
	 je	 short TRIALFIT_DIFF ; Not this time, allocate separately

	 mov	 al,bh		; Get environment region #

	 cmp	 al,bl		; Check against program region #
	 jne	 short TRIALFIT_DIFF ; Unequal, allocate separately

; Find room for program and environment in same region

TRIALFIT_SAME:
	 mov	 ax,PGROUP:[si].SUMFIT_IPARA ; Get # paras to install

; If this is a UMB, EPAR0 contains the maximum allocation for UMBs
; so we don't include it in that case.

	 test	 PGROUP:[si].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jnz	 short @F	; Jump if so

	 add	 ax,PGROUP:[si].SUMFIT_EPAR0 ; Add # environment paras (before)
@@:
	 or	 ax,ax		; Is there an initialization size?
	 jz	 short @F	; Jump if it's empty

	 inc	 ax		; Count in MAC para for program
@@:
	 mov	 dx,PGROUP:[si].SUMFIT_RPARA ; Get # paras to go resident

; If this is a UMB, EPAR1 contains ancestor bitmap for UMBs
; so we don't include it in that case.

	 test	 PGROUP:[si].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jnz	 short @F	; Jump if so

	 add	 dx,PGROUP:[si].SUMFIT_EPAR1 ; Plus # environment paras (after)
	 jz	 short TRIALFIT_XRES ; Jump if it's empty

@@:
	 inc	 dx		; Count in MAC para for program
TRIALFIT_XRES:

; Distinguish whether or not a program region was specified

	 mov	 bl,[bp].TRSUB_PREG ; Get program region #

	 jmp	 short TRIALFIT_COM ; Join common code


; Find room for program and environment separately

TRIALFIT_DIFF:
	 mov	 ax,PGROUP:[si].SUMFIT_IPARA ; Get # paras to install
	 inc	 ax		; Count in MAC para

	 mov	 dx,PGROUP:[si].SUMFIT_RPARA ; Get # paras to go resident
	 inc	 dx		; Count in MAC para

; Distinguish whether or not a program region was specified

	 mov	 bl,[bp].TRSUB_PREG ; Get program region #

	 cmp	 bl,@NOTSPEC	; Izit specified?
	 je	 short TRIALFIT_DIFF_XREG ; Jump if not

	 cmp	 bl,0		; Izit region #0?
	 je	 short TRIALFIT_DIFF_XREG ; Jump if so

; Find memory for program in a specific region

	 call	 CHKMEM_REG	; Is there any room?
	 jc	 short TRIALFIT_NOROOM ; Jump if not

	 jmp	 short TRIALFIT_DIFF_ENV ; Join common environment allocation code


; Find memory for program in any region

TRIALFIT_DIFF_XREG:
	 call	 CHKMEM_ANY	; Check for room for AX paras in any region
	 jc	 short TRIALFIT_NOROOM ; Jump if no room
TRIALFIT_DIFF_ENV:
	 test	 PGROUP:[si].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jnz	 short TRIALFIT_DIFF_COM ; Jump if so (no environment)

	 mov	 ax,PGROUP:[si].SUMFIT_EPAR0 ; Get # environment paras (before)
	 mov	 dx,PGROUP:[si].SUMFIT_EPAR1 ; Get # environment paras (after)

	 mov	 bx,ax		; Copy before
	 or	 bx,dx		; Include after
	 jz	 short TRIALFIT_DIFF_COM ; Jump if nothing to allocate

; Distinguish whether or not an environment region was specified

	 mov	 bl,[bp].TRSUB_EREG ; Get environment region #
TRIALFIT_COM:
	 cmp	 bl,@NOTSPEC	; Izit specified?
	 je	 short TRIALFIT_DIFF_XREG2 ; Jump if not

	 cmp	 bl,0		; Izit other unspecified?
	 je	 short TRIALFIT_DIFF_XREG2 ; Jump if so

; Find memory for environment in a specific region

	 call	 CHKMEM_REG	; Is there any room?
	 jc	 short TRIALFIT_NOROOM ; Jump if not

	 jmp	 short TRIALFIT_DIFF_COM ; Join common code


; Find memory for environment in any region

TRIALFIT_DIFF_XREG2:
	 call	 CHKMEM_ANY	; Check for room for AX paras in any region
	 jc	 short TRIALFIT_NOROOM ; Jump if no room
TRIALFIT_DIFF_COM:
TRIALFIT_LOOP:
	 add	 si,type SUMFIT_STR ; Skip to next program entry
	 add	 [bp].TRSUB_PBTOPFIT,type RFIT_STR ; Skip to next TOPFIT entry
	 mov	 di,[bp].TRSUB_PBTOPFIT ; Restore TOPFIT pointer

;;;;;;;  loop	 TRIALFIT_NEXTPROG ; Jump if more programs to fit
	 dec	 cx		; Decrement loop counter
	MJ nz	 TRIALFIT_NEXTPROG ; Jump if more programs to fit

; Check next program in order
	 cmp	 [bp].TRSUB_INORDER,0 ; Are we checking programs in order?
	 je	 short @F	; Jump if not

	 inc	 [bp].TRSUB_CURORD ; Bump current order
	 mov	 ax,[bp].TRSUB_CURORD ; Get current order in AL
	 cmp	 ax,NPROGS	; Did we reach the end?
	 jnb	 short @F	; Jump if so

	 jmp	 TRIALSUB_NEXTORD ; Go around again
@@:
; All programs and environments fit in their specified regions

	 mov	 ax,1		; Mark as programs fitting

	 jmp	 short TRIALFIT_EXIT ; Join common exit code

TRIALFIT_ERRMAC:
	 mov	 ax,2		; Mark as MAC error

	 jmp	 short TRIALFIT_EXIT ; Join common exit code

TRIALFIT_NOROOM:
	 mov	 ax,0		; Mark as not fitting
TRIALFIT_EXIT:
if @OEM_HARPO
	 cmp	 [bp].TRSUB_INORDER,0 ; Are we checking programs in order?
	 je	 short TRIALFIT_EXIT3 ; Jump if not

	 mov	 cx,NREGS	; Number of regions
	 sub	 bx,bx		; Initialize word index
TRIALFIT_EXIT2:
	 mov	 ax,MINIMA[bx]	; Get minimum region difference
	 cmp	 ax,ISIZES[bx]	; Izit smaller?
	 jnb	 short @F	; Jump if not

	 mov	 ISIZES[bx],ax	; Save smaller value
@@:
	 add	 bx,type MINIMA ; Skip to next word
	 loop	 TRIALFIT_EXIT2 ; Go around again

TRIALFIT_EXIT3:
endif				; IF @OEM_HARPO
	 add	 sp,size TRSUB_LCL ; Release local variable storage

	 REGREST <bp,di,si,dx,cx,bx> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

TRIALSUB endp			; End TRIALSUB procedure
	 FPPROC  TRIALFIT -- Trial Fit
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check the programs as specified for a trial fit.

Note that the program size does not have the MAC entry para
counted in whereas the environment does.

On exit:

AX	 =	 0 if programs didn't fit
	 =	 1 if programs fit
	 =	 2 if MAC error

|

	 sub	 ax,ax		; Check for 386MAX PRGREG != 0 or GETSIZE
	 call	 TRIALSUB	; Call common code

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

TRIALFIT endp			; End TRIALFIT procedure
	 FPPROC  CALCREG -- Calculate Region Sizes
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Calculate region sizes and put into REGTAB.
Put spanning segment # into REGSPAN and fill in REGEMS.

On exit:

CF	 =	 0 if all went well
	 =	 1 if memory allocation chain error

|

	 REGSAVE <ax,bx,cx,dx,si,es> ; Save registers

if @OEM_FLEX
	 call	 SET_MAPTAB	; Setup the MAPTAB table
				; Ignore error return
endif				; IF @OEM_FLEX

; Calculate the region sizes

	 xor	 bx,bx		; Initialize index into REGTAB

	 mov	 REGTAB[0],0	; Initialize the first entry
	 mov	 TOTREG,0	; Initialize accumulated total
	 mov	 NREGS,1	; Initialize region count
	 mov	 ax,POVR_MAC	; Get segment of first MAC in high DOS memory

	 cmp	 ax,-1		; Any high DOS?
	MJ e	 CALCREG_EXIT	; Jump if not (note CF=0)
CALCREG_NEXT:
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,es:[0].MAC_NPAR ; Get # paras in this entry
	 inc	 cx		; Plus MAC para

	 cmp	 es:[0].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	 je	 short CALCREG_SPAN ; Jump if so

	 add	 REGTAB[bx],cx	; Add into current region size
	 add	 TOTREG,cx	; Add into total region size

	 jmp	 short CALCREG_LOOP ; Join common code

; We purposely don't count in the spanning MAC entry as it isn't
; allocatable space

CALCREG_SPAN:
;;;;;;;; inc	 REGTAB[bx]	; Count in spanning MAC entry
	 mov	 REGSPAN[bx],ax ; Save for later use
if @OEM_FLEX
	 mov	 REGEMS[bx],0	; Initialize the EMS size in paras
endif				; IF @OEM_FLEX
if @OEM_HARPO
	 push	 REGTAB[bx]	; Size of region
	 pop	 ISIZES[bx]	; Initialize unused space
endif				; IF @OEM_HARPO
	 add	 bx,type REGTAB ; Skip to next region
	 mov	 REGTAB[bx],0	; Initialize the entry size (even if not used)
	 inc	 NREGS		; Count in another region
CALCREG_LOOP:
	 add	 ax,cx		; Skip to next MAC entry (if any)

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the end?
	 je	 short CALCREG_EMS ; Jump if so

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short CALCREG_NEXT ; Jump if so

	 stc			; Indicate something went wrong

	 jmp	 short CALCREG_EXIT ; Join common exit code


; Check for adjacent EMS mappable pages

CALCREG_EMS:
	 dec	 ax		; Count out MAC paragraph to get
				; pseudo-spanning MAC entry
	 mov	 REGSPAN[bx],ax ; Save for later use

if @OEM_HARPO
	 push	 REGTAB[bx]	; Size of region
	 pop	 ISIZES[bx]	; Initialize unused space
endif				; IF @OEM_HARPO

if @OEM_FLEX

; Loop through REGSPAN table looking for matches in MAPTAB.MAP_SEG

	 cmp	 NMAPS,0	; Any EMS mappable regions?
	 je	 short CALCREG_CLC ; Jump if not

	 xor	 si,si		; Initialize index into REGSPAN/REGEMS
CALCREG_EMS_NEXT:
	 mov	 ax,REGSPAN[si] ; Get spanning segment #

; Search for AX in the MAPTAB table

	 xor	 bx,bx		; Zero index into MAPTAB
	 mov	 cx,NMAPS	; Get # active entries in table
@@:
	 cmp	 ax,MAPTAB.MAP_SEG[bx]	; Check for a match
	 je	 short CALCREG_EMS_FND ; Jump if so

	 add	 bx,type MAP_STR ; Skip to next MAPTAB entry

	 loop	 @B		; Jump if more MAPTAB entries

	 jmp	 short CALCREG_EMS_LOOP ; Join common loop code


; We found a match:  save the EMS mappable length in REGEMS

CALCREG_EMS_FND:
	 mov	 ax,MAPTAB.MAP_LEN[bx] ; Get the EMS mappable length in paras
	 mov	 REGEMS[si],ax	; Save for later use
CALCREG_EMS_LOOP:
	 add	 si,type REGSPAN ; Skip to next entry

	 loop	 CALCREG_EMS_NEXT ; Jump if more spanning entries to check
CALCREG_CLC:
endif				; IF @OEM_FLEX
	 mov	 ax,NREGS	; Get # regions
	 shl	 ax,1-0 	; Convert from words to bytes
	 mov	 NREGSLVL,ax	; Save for later use

	 clc			; Indicate all went well
CALCREG_EXIT:
	 REGREST <es,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CALCREG  endp			; End CALCREG procedure
	 FPPROC  SAVE_SUMFIT -- Save Into SUMFIT Tables
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Save the summary data in local tables for SUMFIT
and count the number of device drivers.

|

	 REGSAVE <ax,bx,cx,dx,di,es> ; Save registers

; Allocate space at our tail for SUMFIT_TAB

	 mov	 ax,NEXTAVL	; Get offset of next available byte
	 mov	 PSUMFIT_TAB,ax ; Mark as start of table

	 mov	 SUMFIT_OFF,0	; Initialize the offset into SUMFIT_TAB
	 mov	 NPROGS,0	; ...		 # programs to fit
	 mov	 NINST,0	; ...		 # INSTALL= programs
	 mov	 NDEVS,0	; ...		 # device drivers

; Make sure the LSEG data is up to date.  A UMB allocator may have
; left trailing hole entries, which need to get cleaned up by MAC_MERGESUB.
	 call	 CHECK_ORPHAN	; Consolidate high DOS MAC chain

; Get the segment of the start of the high DOS memory chain

	 mov	 ax,LOADSEG	; Get the segment of the start of the chain
	 mov	 CURSEG,ax	; Save as current segment
SAVE_SUMFIT_NEXT:
	 cmp	 CURSEG,-1	; Check for end-of-the-chain
	MJ e	 SAVE_SUMFIT_EXIT ; Jump if there's no more

	 mov	 es,CURSEG	; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[0].LSEG_NEXT ; Get pointer to next segment (if any)
	 mov	 CURSEG,ax	; Save for next time

; Save the summary data in local tables for SUMFIT

; Calculate the SIZE value as the largest of LSIZE, ISIZE, and RPARA

	 mov	 ax,es:[0].LSEG_LSIZE.ELO ; Get the low-order load size in bytes
	 mov	 bx,es:[0].LSEG_LSIZE.EHI ; ...     high-order ...
	 mov	 cx,es:[0].LSEG_ISIZE.ELO ; Get the low-order init size in bytes
	 mov	 dx,es:[0].LSEG_ISIZE.EHI ; ...     high-order ...

	 cmp	 bx,dx		; Compare high-order words
	 ja	 short SAVE_SUMFIT_NEXT2 ; Jump if (BX,AX) larger
	 jb	 short SAVE_SUMFIT_NEXT1 ; Jump if (DX,CX) larger

	 cmp	 ax,cx		; Compare low-order words
	 jae	 short SAVE_SUMFIT_NEXT2 ; Jump if (BX,AX) no smaller
SAVE_SUMFIT_NEXT1:
	 mov	 ax,cx		; Use initialization size (low-order)
	 mov	 bx,dx		; ...			  (high-order)
SAVE_SUMFIT_NEXT2:

; Convert (BX,AX) in bytes to AX in paras rounding up

	 add	 ax,16-1	; Round up to para boundary
	 adc	 bx,0		; In case of overflow

	 mov	 cx,4-0 	; Shift amount between paras and bytes
	 clc			; Start with CF=0
@@:
	 shr	 bx,1		; Shift down high-order
	 rcr	 ax,1		; ...	     low-order, including CF bit
	 loop	 @B		; Jump if more bits to shift

	 add	 ax,es:[0].LSEG_NPARA ; Plus size of interrupt block in paras
				; including its MAC para

; Use larger of RPARA and RPAR2

	 mov	 cx,es:[0].LSEG_RPARA ; Get the resident size in paras
	 mov	 dx,es:[0].LSEG_RPAR2 ; Get the forced resident size in paras

	 cmp	 cx,dx		; Put the larger into CX
	 jae	 short @F	; Jump if CX not smaller

	 mov	 cx,dx		; Use resident size
@@:

; Use the larger of resident size and initialization size

	 cmp	 ax,cx		; Put the larger into AX
	 jae	 short @F	; Jump if AX not smaller

	 mov	 ax,cx		; Use resident size
@@:
	 mov	 bx,SUMFIT_OFF	; Get the current offset
	 add	 bx,PSUMFIT_TAB ; Plus start of table

	 mov	 PGROUP:[bx].SUMFIT_PARA,es ; Save for later use
	 mov	 PGROUP:[bx].SUMFIT_IPARA,ax ; Save for later use
	 mov	 PGROUP:[bx].SUMFIT_RPARA,cx ; Save for later use

	 mov	 ax,es:[0].LSEG_EPAR0 ; Get environment size before
	 mov	 PGROUP:[bx].SUMFIT_EPAR0,ax ; Save for later use

	 mov	 ax,es:[0].LSEG_EPAR1 ; Get environment size after
	 mov	 PGROUP:[bx].SUMFIT_EPAR1,ax ; Save for later use

	 mov	 al,es:[0].LSEG_PREG ; Get program region # (if any)
	 mov	 PGROUP:[bx].SUMFIT_PREG,al ; Save for later use

	 mov	 al,es:[0].LSEG_EREG ; Get environment region # (if any)
	 mov	 PGROUP:[bx].SUMFIT_EREG,al ; Save for later use

	 mov	 al,es:[0].LSEG_GRP ; Get group # (if any)
	 mov	 PGROUP:[bx].SUMFIT_GRP,al ; Save for later use

	 mov	 ax,es:[0].LSEG_FLAG ; Get flags
	 mov	 PGROUP:[bx].SUMFIT_FLAG,ax ; Save for later use

	 test	 ax,@LSEG_INST	; Izit from INSTALL=?
	 jz	 short @F	; Jump if not

	 inc	 NINST		; Count in another
@@:
	 test	 ax,@LSEG_DRV	; Izit a device driver?
	 jz	 short @F	; Jump if not

	 inc	 NDEVS		; Count it in if so
@@:
	 add	 SUMFIT_OFF,type SUMFIT_STR ; Skip to next program entry
	 add	 NEXTAVL,type SUMFIT_STR ; Skip to next available byte
	 inc	 NPROGS 	; Count in another one

	 jmp	 SAVE_SUMFIT_NEXT ; Go around again

SAVE_SUMFIT_EXIT:
	 mov	 bx,SUMFIT_OFF	; Get the current offset
	 add	 bx,PSUMFIT_TAB ; Plus start of table

	 mov	 PGROUP:[bx].SUMFIT_PARA,0 ; Mark as end-of-the line

	 add	 NEXTAVL,2	; Skip over it

if @OEM_HARPO
	 push	 ds		; Get PGROUP segment
	 pop	 es		; Address PGROUP for EMM2CALL
	 assume  es:PGROUP	; Tell the assembler

	 mov	 ax,@EMM2_DLGROUP*256 + 00h ; Get DLGROUP size in BX
	 call	 WINOUT 	; Return with result in AH, size in BX
	 or	 ah,ah		; Did the call succeed?
	 jnz	 short @F	; Jump if not

	 mov	 DLGSIZE,bx	; Save size of DLGROUP
@@:
	 mov	 NSUBSEGS,0	; Assume no HARPO support

	 mov	 di,NEXTAVL	; Get next available byte
	 mov	 PSUBSEG_TAB,di ; Save offset of SUBSEG_STR
	 add	 di,@MAX_SUBSEGS*(size SUMFIT_STR) ; Skip to temporary workspace
	 mov	 cx,@MAX_SUBSEGS*(size SUBSEG_STR) ; Maximum space for subsegs
	 mov	 ax,@EMM2_HARPOINFO*256 + @HARPO_GET_SUBSEGS ; Copy subseg table
	 call	 WINOUT 	; Return with result in AH

	 or	 ah,ah		; Did the call succeed?
	 jnz	 short SAVE_SUMFIT_XSUBSEGS ; Jump if not

	 mov	 ax,cx		; Get bytes in table
	 cwd			; Prepare for divide
	 mov	 bx,size SUBSEG_STR ; Bytes per SUBSEG_STR
	 div	 bx		; AX = number of subseg records
	 mov	 cx,ax		; Copy to loop counter
	 sub	 ax,ax		; Initialize accumulator
	 mov	 bx,di		; Save start of saved data
@@:
	 cmp	 PGROUP:[di].SUBSEG_TYPE,0 ; Izit valid?
	 je	 short @F	; Jump if not

	 add	 di,size SUBSEG_STR ; Skip to next
	 inc	 ax		; Count in another one
	 loop	 @B		; Go around again

@@:
	 mov	 NSUBSEGS,ax	; Save for later
	 mov	 cx,ax		; Number of structures to translate
	 mov	 dx,size SUMFIT_STR ; Space needed per subseg
	 mul	 dx		; AX = bytes for subsegments
	 mov	 di,NEXTAVL	; Address beginning of storage space
	 add	 NEXTAVL,ax	; Add to next available
	 jcxz	 SAVE_SUMFIT_ENDLOOP ; Jump if none

@@:
	 mov	 al,PGROUP:[bx].SUBSEG_TYPE ; Get type identifier
	 mov	 PGROUP:[di].SUMFIT_GRP,al ; Use group field
	 mov	 al,PGROUP:[bx].SUBSEG_REG ; Get current region
	 mov	 PGROUP:[di].SUMFIT_EREG,al ; Use envreg field (PREG for optimized value)
	 mov	 ax,PGROUP:[bx].SUBSEG_NPAR ; Get paragraphs (not including MAC)
	 mov	 PGROUP:[di].SUMFIT_RPARA,ax ; Save as resident size
	 mov	 PGROUP:[di].SUMFIT_IPARA,ax ; Initialization size
	 mov	 ax,PGROUP:[bx].SUBSEG_FLAG ; Get flags
	 mov	 PGROUP:[di].SUMFIT_FLAG,ax ; Save as flags
	 sub	 ax,ax		; Prepare to clear unused fields
	 mov	 PGROUP:[di].SUMFIT_EPAR0,ax ; Initialization env size
	 mov	 PGROUP:[di].SUMFIT_EPAR1,ax ; Resident env size
	 mov	 PGROUP:[di].SUMFIT_ORD,al ; Sequence number
	 dec	 ax		; Use 0 only for last entry
	 mov	 PGROUP:[di].SUMFIT_PARA,ax ; LSEG segment

	 add	 bx,type SUBSEG_STR ; Skip to next
	 add	 di,type SUMFIT_STR ; Skip
	 loop	 @B		; Go around again

SAVE_SUMFIT_ENDLOOP:
	 mov	 PGROUP:[di].SUMFIT_PARA,0 ; Indicate the end
	 add	 NEXTAVL,2	; Count into total
SAVE_SUMFIT_XSUBSEGS:
endif				; IF @OEM_HARPO

	 REGREST <es,di,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SAVE_SUMFIT endp		; End SAVE_SUMFIT procedure
	 FPPROC  REST_SUMFIT -- Release SUMFIT Table
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Release SUMFIT table (and SUBSEG table, if present)

|

	 REGSAVE <ax>		; Save register

	 mov	 ax,PSUMFIT_TAB ; Get start of table
	 mov	 NEXTAVL,ax	; Save as offset of next available byte

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REST_SUMFIT endp		; End REST_SUMFIT procedure
ifdef OPTIM
	 NPPROC  AddExp -- Add element PROGACT of PQREXP values to # done so far
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Get element PROGACT of R^j values calculated during CALC_DOMAIN, and add it
to NUMDONE.

|

	 REGSAVE <ax,dx,si,di>	; Save registers

	 cmp	 REORD_FLAG,2	; Izit subsegments only?
	 je	 short @F	; Jump if so

	 mov	 si,PQREXP	; Address base of NREGS^j values
	 mov	 ax,@LONGWORDS*2 ; Get # bytes per exponent value
	 mul	 PROGACT	; Times # programs we're trying to fit
	 add	 si,ax		; Point to element Q of array (number to add)
	 lea	 di,NUMDONE	; Number to add to
	 call	 LWORD_ADD	; Add into NUMDONE

@@:
	 REGREST <di,si,dx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

AddExp endp			; End AddExp procedure
endif				; Ifdef OPTIM
ifdef OPTIM
	 NPPROC  SET_ASCIIZ -- Set/Reset 0s After ASCIIZ Strings
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Set/reset 0s after what should be ASCIIZ strings

On entry:

AL	 =	 value to save (0 or ' ')

|

	 REGSAVE <di>		; Save registers

	 lea	 di,AZS_TOTAL[@LONGSPC-1] ; Address last byte
	 stos	 PGROUP:[di].LO ; Set to AL
	 lea	 di,AZS_CUR[@LONGSPC-1] ; Address last byte
	 stos	 PGROUP:[di].LO ; Set to AL
	 lea	 di,AZS_BEST[@LONGSPC-1] ; Address last byte
	 stos	 PGROUP:[di].LO ; Set to AL

	 lea	 di,AZS_CURTIME[@HMSSPC-1] ; Address last byte
	 stos	 PGROUP:[di].LO ; Set to AL
	 lea	 di,AZS_BESTTIME[@HMSSPC-1] ; Address last byte
	 stos	 PGROUP:[di].LO ; Set to AL

	 lea	 di,AZS_BESTBYTES[@DDSPC-1] ; Address last byte
	 stos	 PGROUP:[di].LO ; Set to AL
	 lea	 di,AZS_TOTHIGH[@DDSPC-1] ; Address last byte
	 stos	 PGROUP:[di].LO ; Set to AL

	 lea	 di,AZS_BESTPCT[@PCTDSPC-1] ; Address last byte
	 stos	 PGROUP:[di].LO ; Set to AL
	 lea	 di,AZS_BESTBPCT[@PCTDSPC-1] ; Address last byte
	 stos	 PGROUP:[di].LO ; Set to AL

	 REGREST <di>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SET_ASCIIZ endp 		; End SET_ASCIIZ procedure
endif				; Ifdef OPTIM
ifdef OPTIM
	 NPPROC  RESET_DATA -- Reset data for ORDFIT
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

As ORDFIT may be called twice in the same image load (MAXIMIZE), we
cannot rely on initialized data being initialized to the compile-time
values.

|

	 REGSAVE <ax,cx,di>	; Save caller's registers

	 sub	 ax,ax		; Get 0 value for all numeric data
	 lea	 di,NUMDONE	; Current done
	 call	 LWORD_SET	; Initialize to 0's

	 lea	 di,NUMMAX	; Maximum number displayed
	 call	 LWORD_SET	; Initialize to unsigned min identity

	 lea	 di,LAST_PCTBASE ; Base value for last percentage
	 call	 LWORD_SET	; Initialize to 0

	 mov	 OPROGRESS.OPROG_PCT,ax ; Reset percentage done
	 mov	 OPROGRESS.OPROG_FLAGS,@OPF_BESTDIRTY ; Reset display flags

	 mov	 al,' '         ; Value to fill text with
	 lea	 di,AZS_CUR	; Current done
	 mov	 cx,@LONGSPC-1	; Spaces to fill less trailing null
   rep	 stos	 AZS_CUR[di]	; Blast away

	 lea	 di,AZS_CURTIME ; Elapsed time
	 mov	 cx,@HMSSPC-1	; Spaces to fill less trailing null
   rep	 stos	 AZS_CURTIME[di] ; Blast away

	 lea	 di,AZS_BEST	; Best count
	 mov	 cx,@LONGSPC-1	; Spaces to fill less trailing null
   rep	 stos	 AZS_BEST[di]	; Blast away

	 lea	 di,AZS_BESTTIME ; Best time
	 mov	 cx,@HMSSPC-1	; Spaces to fill less trailing null
   rep	 stos	 AZS_BESTTIME[di] ; Blast away

	 lea	 di,AZS_BESTBYTES ; Best bytes moved high
	 mov	 cx,@DDSPC-1	; Spaces to fill less trailing null
   rep	 stos	 AZS_BESTBYTES[di] ; Blast away

	 lea	 di,AZS_BESTPCT ; Best percentage
	 mov	 cx,@PCTDSPC-1	; Spaces to fill less trailing null
   rep	 stos	 AZS_BESTPCT[di] ; Blast away

	 lea	 di,AZS_BESTBPCT ; Best bytes high as percentage of high DOS
	 mov	 cx,@PCTDSPC-1	; Spaces to fill less trailing null
   rep	 stos	 AZS_BESTBPCT[di] ; Blast away

	 mov	 BAILOUT,0	; Disallow Esc
	 mov	 COMBscale100,1 ; Default for COMBdiv100
	 mov	 COMBscale1000,1; Default for COMBdiv1000

	 REGREST <di,cx,ax>	; Restore

	 ret			; Return

	 assume  ds:nothing,es:nothing,ss:nothing

RESET_DATA endp 		; End RESET_DATA procedure
endif				; Ifdef OPTIM
ifdef OPTIM
	 FPPROC  GET_TOPFIT -- Make Room for PBTOPFIT
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Make room for PBTOPFIT

|

	 REGSAVE <ax,cx,di>	; Save registers

; Allocate room for top fits at (type RFIT_STR) bytes per program

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBTOPFIT,di	; Save for later use
	 mov	 al,type RFIT_STR ; AL = type RFIT_STR
	 mul	 NPROGS.LO	; Times # programs
	 add	 NEXTAVL,ax	; Allocate it

; Initialize TOPFIT to -1

	 mov	 al,type RFIT_STR ; AL = type RFIT_STR
	 mul	 NPROGS.LO	; Times # programs
	 mov	 cx,ax		; Copy to count register
	 mov	 al,-1		; Fill with this
     rep stosb			; Fill it up

	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GET_TOPFIT endp 		; End GET_TOPFIT procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 FPPROC  RLS_TOPFIT -- Release Room for PBTOPFIT
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Release room for PBTOPFIT

|

	 REGSAVE <ax>		; Save register

; De-allocate room for top fits
; at (type RFIT_STR) bytes per program

	 mov	 al,type RFIT_STR ; AL = type RFIT_STR
	 mul	 NPROGS.LO	; Times # programs
	 sub	 NEXTAVL,ax	; De-allocate it
	 mov	 PBTOPFIT,-1	; Zap it for debugging

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

RLS_TOPFIT endp 		; End RLS_TOPFIT procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 FPPROC  ORDFIT -- Order The Fits
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Put the programs into order.

|

ORDFIT_STR struc

	 dw	 ?		; Caller's BP
	 dd	 ?		; ...	   CS:IP
ORDFIT_FLAG dw	 ?		; ...	   flags:  0 = don't re-order
				;		   1 = allow re-ordering
				;		   2 = subsegment optimization
ORDFIT_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

	 mov	 ax,[bp].ORDFIT_FLAG ; Get re-ordering flag
	 mov	 REORD_FLAG,ax	; Save for later use

; Initialize LVL to -1 to disable timer tick display of RPV

	 mov	 LVL,-1 	; Initialize level counter

	 cmp	 ax,2		; Izit subsegments only?
	MJ e	 ORDFIT_NEXTEMS1 ; Jump if so

; Set up SS:SP for callbacks during int 8 handler

	 mov	 CALL_STACK.VSEG,ss ; Save caller's SS
	 mov	 ax,16+(size FITREC_STR) ; Overhead for each level of recursion
	 mul	 NPROGS 	; Times maximum possible levels
	 add	 ax,128+32	; Allocate space for ORDFIT & interrupts
	 neg	 ax		; Prepare to subtract from SP
	 add	 ax,sp		; Get caller's SP - maximum stack use
	 mov	 CALL_STACK.VOFF,ax ; SP to be used for callbacks

; Set up PGSEG variable for DS reloads (no fixups when compiled as UTIL.COM)

	 mov	 PGSEG,ds	; Save PGROUP segment

; Set segment portion of far pointers in OPROGRESS (no fixups when linked
; as 386UTIL.COM)

	 mov	 OPROGRESS.OPROG_PDONE.VSEG,ds ; Number done
	 mov	 OPROGRESS.OPROG_PELAPSED.VSEG,ds ; Elapsed time
	 mov	 OPROGRESS.OPROG_PTOTAL.VSEG,ds ; Total to do
	 mov	 OPROGRESS.OPROG_PTOTHIGH.VSEG,ds ; Total bytes in high DOS
	 mov	 OPROGRESS.OPROG_PBESTCNT.VSEG,ds ; Number done to get best
	 mov	 OPROGRESS.OPROG_PBESTELAP.VSEG,ds ; Time elapsed to best
	 mov	 OPROGRESS.OPROG_PBESTBYTE.VSEG,ds ; Bytes moved high for best
	 mov	 OPROGRESS.OPROG_PBESTPCT.VSEG,ds ; BESTCNT / current * 100.0
	 mov	 OPROGRESS.OPROG_PBESTBPCT.VSEG,ds ; Bytes high as % of total

; Initialize display data

	 call	 RESET_DATA	; Set numbers to 0, text to all spaces

; Allocate storage for variables

	 call	 CV_MANY	; Create 'em

if @OEM_FLEX
	 cmp	 REORD_FLAG,1	; Allow re-ordering?
	 jne	 short ORDFIT_XREO ; Jump if not

; Determine how many different REGEMS values there are

	 call	 CALC_REGDIF	; Determine 'em

	 mov	 REGDIF_IND,0	; Initialize index
endif				; @OEM_FLEX
ORDFIT_XREO:

; Order the programs descendingly by maximum size within
; the device driver/TSR/group categories.  This is repeated at the
; top of the outside loop (ORDFIT_NEXTEMS), but we must do it
; here to set PROGMASK, which is needed for CALC_DOMAIN.
; If we are reordering, the code above this comment block
; takes care of initializing REGDIF*

	 call	 IV_PRGORD	; Initialize PRGORD and APVORD

; Calculate number of possibilities to go through

	 call	 CALC_DOMAIN	; COMBINATIONS = total

	 lea	 si,COMBINATIONS ; Long value to format
	 lea	 di,AZS_TOTAL	; Get address of total string
	 mov	 cx,@LONGSPC-1	; Max. spaces
	 call	 LWORD_FMT	; Format as decimal

	 lea	 di,QWORK1	; Temporary lword value
	 mov	 ax,TOTREG	; Paragraphs in high DOS
	 call	 LWORD_SET	; Extend AX as an LWORD at PGROUP:DI
	 mov	 ax,16		; Convert bytes to paras
	 call	 LWORD_MUL16	; Multiply LWORD at PGROUP:DI by AX
	 mov	 si,di		; Value to format
	 lea	 di,AZS_TOTHIGH ; Destination for output
	 mov	 cx,@DDSPC-1	; Max. spaces
	 call	 LWORD_FMT	; Format as decimal value

; Initialize variables used by timer routine

	 mov	 DISP_BSY,0	; Clear display busy flag
	 mov	 DISP_CNT,@DISP_REF ; Initial value for refresh countdown
	 mov	 DISP_LOSE5,@DISP_LOSE5 ; Initial value for "lose a turn" 1
	 mov	 DISP_LOSE100,@DISP_LOSE100 ; Initial value for "lose a turn" 2
	 mov	 ELAPSED.ELO,0	; Clear seconds elapsed
	 mov	 ELAPSED.EHI,0	; High word of seconds

	 mov	 al,0		; Set to this value
	 call	 SET_ASCIIZ	; Set/reset 0s after what should be ASCIIZ strings

; Prepare timer-dependent values if output not re-directed

	 test	 UTL_FLAG,@UTL_COT ; Izit re-directed?
	 jz	 short ORDFIT_XCOT1 ; Jump if it is

; Save and hide the cursor type

	 VIDCALL @GETINF	; Get current video state in AL,
				; # cols in AH, display page # in BH
	 VIDCALL @GETPOS	; Get cursor position in (DH,DL), type in (CH,CL)
	 mov	 OLDCURTYP,cx	; Save to restore later

	 mov	 cx,2000h	; Make invisible
	 VIDCALL @SETTYP	; Set cursor type to (CH,CL)

	 push	 es		; Save our ES as _OPT_PROGRESS might clobber it

	 lea	 bx,OPROGRESS	; Get offset of structure
	 push	 ds		; Pass segment portion of far pointer
	 push	 bx		; Pass offset
	 call	 _OPT_PROGRESS	; Draw message box
	 add	 sp,2*2 	; Remove DS:BX from stack

	 pop	 es		; Restore our ES
	 assume  es:PGROUP	; Tell the assembler

ORDFIT_XCOT1:
; Install INT 08h handler to refresh progress display
; We save and restore int 8 WITHOUT using DOS services because
; the @SETINT function checks for Ctrl-Break.

	 push	 es		; Save for a moment

	 mov	 ax, seg INTVEC ; Get a seg value for IDT
	 mov	 es, ax 	; Use es for IDT
	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 si,08h*(type INT00_VEC) ; Get index into IDT
	 les	 bx,INT00_VEC[si] ; Get vector
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OPTINT8_VEC.VOFF,bx ; Save to restore later
	 mov	 OPTINT8_VEC.VSEG,es ; ...

	 mov	 es, ax 	; Use es for IDT
	 assume  es:INTVEC	; Tell the assembler about it

	 cli			; Nobody move
	 mov	 INT00_VEC.VOFF[si],offset PGROUP:OPTINT8 ; Set offset
	 mov	 INT00_VEC.VSEG[si],cs ; Set segment
	 sti			; Enable interrupts

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

; !!!! WARNING !!!!  All code between here and ORDFIT_EXIT2 (where
; int 8 is restored) assumes there will be NO opportunities for
; termination via Ctrl-Break.  Ctrl-break is checked for in Optint8.
; If this code is linked with MAXIMIZE, Ctrl-break termination is
; disabled before calling _MAXIMIZE.

if @OEM_FLEX

; Get index of next REGDIF value
	 public  ORDFIT_NEXTEMS
ORDFIT_NEXTEMS:
	 cmp	 REORD_FLAG,1	; Allow re-ordering?
	 jne	 short ORDFIT_NEXTEMS1 ; Jump if not

	 lea	 di,REGDIF	; ES:DI ==> REGDIF
	 mov	 ax,-1		; Look for not this
	 mov	 cx,NREGS	; CX = # regions
    repe scasw			; Scan for new values
;;;;;;;; jne	 short @F	; Jump if found
;;;;;;;;
;;;;;;;; int	 03h		; Catch errors
;;;@@:
	 sub	 di,2+(offset PGROUP:REGDIF) ; Convert to origin-0 in words
	 mov	 REGDIF_IND,di	; Save for later use
	 mov	 REGDIF[di],ax	; Zap so we'll skip it next time
endif				; IF @OEM_FLEX
ORDFIT_NEXTEMS1:

; Order the programs descendingly by maximum size within
; the device driver/TSR/group categories.

	 call	 IV_PRGORD	; Initialize PRGORD and APVORD

; Construct the next APV

	 public  ORDFIT_NEXTAPV
ORDFIT_NEXTAPV:
	 mov	 di,PBAPVBIT	; DS:DI ==> available program bit vector
	 mov	 cx,NPROGS	; CX = # programs
	 add	 di,cx		; Point to the end+1
@@:
	 dec	 di		; Back off to previous byte

	 xor	 PGROUP:[di].LO,1 ; Subtract one from next value
	 loopnz  @B		; Jump if more to subtract

; Mask out programs which are not to be loaded high
; These programs include 386MAX if NOLOADHI specified,
; and device drivers/TSRs whose installation size is zero
; (that is, they didn't go resident).

	 mov	 di,PBAPVBIT	; DS:DI ==> available program bit vector
	 mov	 si,PBAPVMASK	; DS:SI ==> ... mask
	 mov	 cx,NPROGS	; CX = # programs
	 mov	 PROGACT,0	; Initialize PROGACT ((NPROGS - PROGMASK) - j)
	 xor	 ah,ah		; Zero to use as word
@@:
	 lods	 PGROUP:[si].LO ; Get next mask bit
	 and	 al,PGROUP:[di] ; Apply to APV
	 stos	 PGROUP:[di].LO ; Put it back in APV
	 add	 PROGACT,ax	; Add bit value to PROGACT

	 loop	 @B		; Jump if more APV bits

	 cmp	 BAILOUT,2	; Did user press Esc?
	MJ e	 ORDFIT_EXIT2	; Jump if so

; Re-order APV by APV order, kick out if it's all zero

	 mov	 di,PBAPVORD	; DS:DI ==> APV order # table
	 mov	 si,PBAPVBIT	; DS:SI ==> APV order bit table

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 RAPVCNT,0	; Zero the count
	 mov	 ah,0		; Zero to use as word
@@:
	 mov	 bh,0		; Zero to use as word
	 mov	 bl,PGROUP:[di] ; Get next APV order #
	 add	 bx,PBRAPV	; DS:BX ==> RAPV table
	 lodsb			; Get next APV bit
	 mov	 PGROUP:[bx],al ; Save in RAPV table

	 add	 RAPVCNT,ax	; Count in another

	 inc	 di		; Skip to next APV order bit

	 loop	 @B		; Jump if more bytes to translate

	 cmp	 RAPVCNT,0	; Any programs to fit?
	 jne	 short @F	; Jump if there's more to do

	 call	 AddExp 	; Add element Q of N pick j values to # done

	 jmp	 ORDFIT_EXIT	; Jump if it's the last one

@@:
if @DEBUG
	 call	 D_RAPV 	; Display RAPV
endif				; IF @DEBUG

; Calculate the putative resident size for this re-ordered APV
; Also, ensure no programs we select to be loaded low are UMBs
; as we have no way (at present) to tell a UMB allocator
; that yes we have no bananas.

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 si,PBRAPV	; DS:SI ==> re-ordered APV table
	 xor	 dx,dx		; Zero the accumulator
	 mov	 di,PBPRGORD	; DS:DI ==> program order table
ORDFIT_NEXTRAPV:
	 mov	 al,type SUMFIT_STR ; Get size of structure
	 mul	 PGROUP:[di].LO ; Times program order #
	 mov	 bx,ax		; Copy to index register
	 add	 bx,PSUMFIT_TAB ; DS:BX ==> this entry in summary fit table

	 lodsb			; Get next re-order APV

	 cmp	 al,0		; Izit available?
	 je	 short ORDFIT_NEXTRAPV1 ; Jump if not

	 add	 dx,PGROUP:[bx].SUMFIT_RPARA ; Plus # resident prg paras
	 inc	 dx		; Count in the MAC para
	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jnz	 short @F	; Jump if so

	 add	 dx,PGROUP:[bx].SUMFIT_EPAR1 ; Plus # resident env paras (after)
@@:
	 jmp	 short ORDFIT_NEXTRAPV2 ; Join common code

; Force the program to be loaded low -- check for UMBs and try again
; if present

ORDFIT_NEXTRAPV1:
	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jnz	 short ORDFIT_NEXTAPV0 ; Jump if so
ORDFIT_NEXTRAPV2:
	 inc	 di		; Skip to next program order #

	 loop	 ORDFIT_NEXTRAPV ; Jump if more to sum

; Ensure it'll fit

	 cmp	 dx,TOTREG	; Well?
	 ja	 short ORDFIT_NEXTAPV0 ; Jump if it's too large

; Ensure the fit would be better than at least one of our current best

	 cmp	 dx,BESTSIZE	; Check against best size
	 ja	 short @F	; Jump if new size is bigger
ORDFIT_NEXTAPV0:		; Fall through if new size is too small
	 call	 AddExp 	; Add element Q of N pick j values to # done

	 jmp	 ORDFIT_NEXTAPV ; Go around again

@@:
	 mov	 FITRES,dx	; Save for later use

; Initialize variables for recursion

	 call	 IV_MANY	; Initialize several variables

; Allocate room for temporary program order vector
; at one byte per TPOCNT

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBTPO,di	; Save for later use
	 mov	 ax,RAPVCNT	; Get # available programs
	 mov	 TPOCNT,ax	; Save as current TPO count
	 add	 NEXTAVL,ax	; Allocate it

; Construct temporary program order vector

	 mov	 bx,PBRAPV	; DS:BX ==> compression vector
	 mov	 si,PBPRGORD	; DS:SI ==> input table
	 mov	 cx,NPROGS	; CX = # programs
ORDFIT_NEXTTPO:
	 cmp	 PGROUP:[bx].LO,1 ; Izit available?
	 jne	 short @F	; Jump if not

	 mov	 al,PGROUP:[si] ; Get program order #
	 stosb			; Save in temporary program order table
@@:
	 inc	 si		; Skip to next entry in program order table
	 inc	 bx		; Skip to next bit in compression vector

	 loop	 ORDFIT_NEXTTPO ; Jump if more bytes to translate

; Initialize the recursion level

	 mov	 LVL,-1 	; Mark level for later increment

; Initialize recursive product vector to (NPROGS-PROGMASK) rho NREGS

	 mov	 al,NREGS.LO	; Get low byte of NREGS
	 mov	 di,PBRPV	; Get pointer to recursive product vector
	 mov	 cx,NPROGS	; Number of bytes to initialize
	 sub	 cx,PROGMASK	; Less # programs masked out
    rep  stosb			; Fill RPV with NREGS for NPROGS bytes

; Begin recursion

	 call	 FITREC 	; Call recursive program
				; Return with AX significant
	 call	 AddExp 	; Add element Q of N pick j values to # done

; De-allocate room for temporary program order vector
; at one byte per TPOCNT

	 push	 ax		; Save for a moment
	 mov	 ax,TPOCNT	; Get # available programs
	 sub	 NEXTAVL,ax	; De-allocate it
	 mov	 PBTPO,-1	; Zap it for debugging
	 pop	 ax		; Restore

	 cmp	 ax,2		; Did user press Esc?
	MJ e	 ORDFIT_EXIT2	; Jump if so

	 cmp	 ax,1		; Did we succeed?
	MJ ne	 ORDFIT_NEXTAPV ; Jump if we didn't

	 cmp	 REORD_FLAG,2	; Izit subsegments only?
	 je	 short ORDFIT_XCLRENV ; If so, leave environment region alone

; Clear the environment if same as program region

	 mov	 si,PBRFIT	; DS:SI ==> RFIT
	 mov	 cx,NPROGS	; CX = # programs
ORDFIT_CLRENV:
	 mov	 al,PGROUP:[si].RFIT_PREG ; Get the program region #

	 cmp	 al,PGROUP:[si].RFIT_EREG ; Same as environment region #?
	 jne	 short @F	; Jump if not

	 mov	 PGROUP:[si].RFIT_EREG,@NOTSPEC ; Zap it
@@:
	 add	 si,type RFIT_STR ; Skip to next structure entry

	 loop	 ORDFIT_CLRENV	; Jump if more triples to check

ORDFIT_XCLRENV:
	 mov	 ax,FITRES	; Get this fit

	 cmp	 ax,BESTSIZE	; Izit better than our previous best?
	 jbe	 short ORDFIT_AGAIN ; Jump if not

	 mov	 BESTSIZE,ax	; Save for later use

; Update and reformat best fit count, elapsed time, and bytes moved

	 call	 FORMAT_BEST	; Format the best fit values

; Save as next best fit

	 mov	 al,type RFIT_STR ; Get size of RFIT structure
	 mul	 NPROGS.LO	; Times # programs
	 mov	 cx,ax		; Copy to count register
	 mov	 di,PBTOPFIT	; ES:DI ==> TOPFIT[0;]
	 mov	 si,PBRFIT	; DS:SI ==> RFIT
     rep movs	 PGROUP:[di].LO,PGROUP:[si].LO ; Copy to TOPFIT

; Go around again if we had to delete a program

ORDFIT_AGAIN:
	 mov	 ax,NPROGS	; Get # programs

	 cmp	 ax,RAPVCNT	; Same as RAPV count?
	 je	 short ORDFIT_EXIT0 ; Jump if so

	 jmp	 ORDFIT_NEXTAPV ; Jump if not

; All programs fit on the first pass
; Subtract out the effect of the last ADDEXP, and add in COMBINE1

ORDFIT_EXIT0:
	 cmp	 REORD_FLAG,2	; Subsegments only?
	 je	 short ORDFIT_EXIT2 ; Jump if so

; Subtract out the effect of the last ADDEXP

	 mov	 si,PQREXP	; Address base of NREGS^j values
	 mov	 ax,@LONGWORDS*2 ; Get # bytes per exponent value
	 mul	 PROGACT	; Times # programs we're trying to fit
	 add	 si,ax		; Point to element Q of array (number to add)
	 lea	 di,NUMDONE	; Number to subtract from
	 call	 LWORD_SUB	; Subtract from NUMDONE

; Add in COMBINE1

	 lea	 si,COMBINE1	; Get source lword
;;;;;;;; lea	 di,NUMDONE	; Get destin lword
	 call	 LWORD_ADD	; Add COMBINE1 to NUMDONE

	 call	 RECALC_PCT	; Redisplay new NUMDONE

	 public  ORDFIT_EXIT
ORDFIT_EXIT:
if @OEM_FLEX
	 cmp	 REORD_FLAG,1	; Allow re-ordering?
	 jne	 short ORDFIT_EXIT2 ; Jump if not

	 dec	 REGDIF_CNT	; Count out another EMS region
	MJ nz	 ORDFIT_NEXTEMS ; Jump if more
endif				; IF @OEM_FLEX

ORDFIT_EXIT2:
	 cmp	 REORD_FLAG,2	; Izit subsegments only?
	MJ e	 ORDFIT_EXIT4	; Jump if so

	 push	 ds		; Save for a moment
	 push	 es		; Save ES

	 lds	 dx,OPTINT8_VEC ; Get address of previous handler
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax, seg INTVEC ; Get a seg value for IDT
	 mov	 es, ax 	; Use es for IDT
	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 si,08h*(type INT00_VEC) ; Get index into IDT
	 cli			; Nobody move
	 mov	 INT00_VEC.VOFF[si],dx ; Set offset
	 mov	 INT00_VEC.VSEG[si],ds ; Set segment
	 sti			; Enable interrupts

	 pop	 es		; Restore ES
	 pop	 ds		; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

; Restore cursor type if we hid it before

	 test	 UTL_FLAG,@UTL_COT ; Izit re-directed?
	 jz	 short @F	; Jump if it is

	 mov	 cx,OLDCURTYP	; Get original cursor type
	 VIDCALL @SETTYP	; Set cursor type to (CH,CL)
@@:

if @OEM_HARPO
; Process subsegments and others, such as XBIOSHI, STACKS, and HPDA
	 cmp	 NSUBSEGS,0	; Do we have any?
	MJ e	 ORDFIT_XSUBSEGS ; Jump if none

; Determine unused space in each region
	 mov	 ax,1		; Skip GETSIZE and respect ordering
	 call	 TRIALSUB	; Set up REGTAB and ISIZES

; Save variables MAXIMIZE and UTIL_SUM need
	 REGSAVE <BESTSIZE,TOTREG,NPROGS,NDEVS,NINST,PSUMFIT_TAB> ; Save
	 REGSAVE <PBTOPFIT,REORD_FLAG> ; Save

; Initialize variables needed
	 mov	 BESTSIZE,0	; Best fit
	 mov	 NDEVS,0	; Number of devices
	 mov	 NINST,0	; Number of INSTALL= programs
	 mov	 BAILOUT,0	; Clear previous state of Esc / Ctrl-Break

; Exchange NPROGS and allocate space for subsegment PBTOPFIT
	 mov	 ax,NSUBSEGS	; Ersatz number of programs
	 mov	 NPROGS,ax	; Save for ORDFIT
	 FCALL	 GET_TOPFIT	; Allocate and initialize TOPFIT array
	 mov	 ax,PSUBSEG_TAB ; Ersatz pointer to SUMFIT records
	 mov	 PSUMFIT_TAB,ax ; Save for ORDFIT

; Move ISIZES to REGTAB and recalculate TOTREG
	 mov	 TOTREG,0	; Initialize it
	 lea	 di,REGTAB	; Address first region
	 lea	 si,ISIZES	; Address space remaining
	 mov	 cx,NREGS	; Number of regions
@@:
	 lods	 ISIZES[si]	; Get region size
	 stos	 REGTAB[di]	; Save in REGTAB[]
	 add	 TOTREG,ax	; Update total
	 loop	 @B		; Go around again

; Call ORDFIT to optimize subsegments
	 mov	 ax,2		; Perform subsegment optimization only
	 push	 ax		; Pass flag on stack
	 FCALL	 ORDFIT 	; Optimize subsegments

; Translate top fit into PSUBSEG_TAB
	 sub	 bx,bx		; Don't subtract interrupt block, leave EREG
	 call	 CPY_SUMSUB	; Copy PBTOPFIT data to PSUMFIT_TAB (it's
				; actually PSUBSEG_TAB)

	 FCALL	 RLS_TOPFIT	; Free PBTOPFIT

	 mov	 ax,BESTSIZE	; Get additional paras moved high

; Restore variables
	 REGREST <REORD_FLAG,PBTOPFIT> ; Restore
	 REGREST <PSUMFIT_TAB,NINST,NDEVS,NPROGS,TOTREG,BESTSIZE> ; Restore

	 add	 BESTSIZE,ax	; Add into total

; Although BESTSIZE may have increased, we don't want to call FORMAT_BEST
; again because that will indicate that all the time occupied so far was
; needed.  Since the additional time for subsegment optimization is minimal,
; we can safely ignore the time and just update the total moved high.
	 or	 OPROGRESS.OPROG_FLAGS,@OPF_BESTDIRTY ; Flag data for redisplay

	 mov	 ax,BESTSIZE	; Get best fit so far (updated by subsegments)
	 lea	 di,QWORK1	; Address temporary lword
	 call	 LWORD_SET	; Extend AX as an LWORD at PGROUP:DI
	 mov	 ax,16		; Convert paras to bytes
	 call	 LWORD_MUL16	; Multiply LWORD by AX
	 mov	 si,di		; Value to format
	 lea	 di,AZS_BESTBYTES ; Destination for output
	 mov	 cx,@DDSPC-1	; Max. spaces
	 call	 LWORD_FMT	; Format as decimal value
ORDFIT_XSUBSEGS:
endif				; IF @OEM_HARPO

; Call RECALC_PCT one last time.  This is the ONLY call if output is redirected.

	 call	 RECALC_PCT	; Recalculate and display

	 mov	 al,' '         ; Set to this value
	 call	 SET_ASCIIZ	; Set/reset 0s after what should be ASCIIZ strings

; De-allocate storage for variables

	 call	 DV_MANY	; Delete 'em

ORDFIT_EXIT4:
; Convert TOPFIT to origin-1

	 mov	 al,type RFIT_STR ; AL = type RFIT_STR
	 mul	 NPROGS.LO	; Times # programs
	 mov	 cx,ax		; Copy to count register
	 mov	 si,PBTOPFIT	; DS:SI ==> TOPFIT[;]
@@:
	 inc	 PGROUP:[si].LO ; Convert to origin-1
	 inc	 si		; Skip to next entry

	 loop	 @B		; Jump if more entries to convert

	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,ss:nothing

ORDFIT	 endp			; End ORDFIT procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  FORMAT_BEST -- Format The Best Fit Values
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Format the best fit values

|

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

	 cmp	 REORD_FLAG,2	; Are we processing only subsegments?
	MJ e	 FORMAT_BEST_EXIT ; Jump if so

	 inc	 DISP_BSY	; Disable interrupt-driven display

	 or	 OPROGRESS.OPROG_FLAGS,@OPF_BESTDIRTY ; Flag data for redisplay

	 lea	 si,NUMDONE	; Number done so far (not NUMMAX)
	 lea	 di,BEST_COUNT	; Count for best fit
	 mov	 cx,@LONGWORDS	; Number of words to move
   rep	 movs	 PGROUP:[di].ELO,PGROUP:[si].ELO ; Move it!

	 lea	 si,BEST_COUNT	; Value to format
	 lea	 di,AZS_BEST	; Destination for output
	 mov	 cx,@LONGSPC-1	; Max. spaces
	 call	 LWORD_FMT	; Format lword as decimal

	 lea	 di,QWORK1	; Copy count
	 call	 LWORD_MOV	; QWORK1 <- BEST_COUNT

	 lea	 si,COMBdiv1000 ; Value to subtract
	 sub	 cx,cx		; Value to start with
@@:
	 cmp	 cx,1000	; Izit the maximum?
	 jnb	 short @F	; Jump if so

	 call	 LWORD_SUB	; Subtract CombDiv1000 from Qwork1, CF=1 if >
	 jc	 short @F	; Jump if it didn't fit

	 add	 cx,COMBscale1000 ; Add in scale factor
	 jmp	 short @B	; Do it again

@@:
	 mov	 ax,cx		; Value to format
	 lea	 di,AZS_BESTPCT ; Output for "nnn.n%"
	 call	 FMT_TPCT	; Format thousandths

	 mov	 ax,BESTSIZE	; Number of paras moved high
	 mov	 bx,1000	; Times 1000
	 mul	 bx		; DX:AX contains paras * 1000
	 div	 TOTREG 	; Divide by total paras in high DOS
	 lea	 di,AZS_BESTBPCT ; Bytes moved high as percentage of high DOS
	 call	 FMT_TPCT	; Format thousandths

	 mov	 ax,ELAPSED.ELO ; Seconds elapsed
	 mov	 dx,ELAPSED.EHI ; High word of seconds
	 mov	 BEST_ELAPSED.ELO,ax ; Record how long it took to get here
	 mov	 BEST_ELAPSED.EHI,dx ; High word
	 lea	 di,AZS_BESTTIME ; Destination for output
	 call	 TIME_FMT	; Format AX seconds as HH:MM:SS

	 mov	 ax,BESTSIZE	; Get best fit so far
	 lea	 di,QWORK1	; Address temporary lword
	 call	 LWORD_SET	; Extend AX as an LWORD at PGROUP:DI
	 mov	 ax,16		; Convert paras to bytes
	 call	 LWORD_MUL16	; Multiply LWORD by AX
	 mov	 si,di		; Value to format
	 lea	 di,AZS_BESTBYTES ; Destination for output
	 mov	 cx,@DDSPC-1	; Max. spaces
	 call	 LWORD_FMT	; Format as decimal value

	 dec	 DISP_BSY	; Allow display interrupt

	 call	 RECALC_PCT	; Recalculate and display

	 cmp	 BAILOUT,1	; Is BAILOUT enabled yet?
	 jnb	 short @F	; Jump if so

	 mov	 BAILOUT,1	; Enable user to bail out by pressing Esc

@@:
FORMAT_BEST_EXIT:
	 REGREST <di,si,dx,cx,bx,ax> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FORMAT_BEST endp		; End FORMAT_BEST procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  IV_PRGORD -- Initialize PRGORD and APVORD
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Initialize the variable PRGORD by ordering the programs
descendingly by maximum tare within the device
driver/TSR/group categories.

Initialize the variable APVORD by ordering the programs
descendingly by maximum size independent of category.

|

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

; Initialize APV bit vector to zero

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 di,PBAPVBIT	; ES:DI ==> available program vector
	 mov	 al,0		; Initial value
     rep stosb			; Clear to zero

; Fill the program order table with default values (iota NPROGS)

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 di,PBPRGORD	; ES:DI ==> program order table
	 mov	 al,0		; Initial value
@@:
	 stosb			; Save in program order table
	 inc	 al		; Skip to next value

	 loop	 @B		; Jump if more programs

; Fill the APV order table with default values (iota NPROGS)

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 di,PBAPVORD	; ES:DI ==> APV order table
	 mov	 al,0		; Initial value
@@:
	 stosb			; Save in APV order table
	 inc	 al		; Skip to next value

	 loop	 @B		; Jump if more programs

	 cmp	 REORD_FLAG,1	; Allow re-ordering?
	MJ ne	 IV_PRGORD_EXIT ; Jump if not

; Allocate room for temporary working area
; at one word per program

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 TEMPOFF,di	; Save for later use
	 mov	 ax,NPROGS	; Get # programs
	 shl	 ax,1-0 	; Convert from words to bytes
	 add	 NEXTAVL,ax	; Allocate it

; Fill TEMPOFF with maximum sizes

	 mov	 dx,0		; Indicate to fill with sizes (not tares)
	 call	 FILL_TEMPOFF	; Fill it up

; Ensure @GRPMAX is ordered first

	 mov	 di,PSUMFIT_TAB ; DS:DI ==> summary fit table

	 cmp	 PGROUP:[di].SUMFIT_GRP,@GRPMAX ; Izit present?
	 jne	 short @F	; Jump if not

	 mov	 si,TEMPOFF	; DS:SI ==> temporary working area
	 mov	 PGROUP:[si].ELO,07FFFh ; Make artificially large but positive
@@:

; Grade down the values in TEMPOFF putting the result into PBAPVORD
; We'll use a simple bubble sort (grade) because there are so few values
; Some care must be taken to ensure that this is a stable sort (grade)

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 si,TEMPOFF	; DS:SI ==> temporary working area
	 mov	 di,PBAPVORD	; ES:DI ==> existing permutation vector for result
	 call	 GRADE_DN	; Grade down CX signed words in DS:SI into ES:DI

; Fill TEMPOFF with maximum tares again after GRADE_DN re-ordered them

	 mov	 dx,1		; Indicate to fill with tares (not sizes)
	 call	 FILL_TEMPOFF	; Fill it up

; Ensure @GRPMAX is ordered first

	 mov	 di,PSUMFIT_TAB ; DS:DI ==> summary fit table
	 mov	 si,TEMPOFF	; DS:SI ==> temporary working area

	 cmp	 PGROUP:[di].SUMFIT_GRP,@GRPMAX ; Izit present?
	 jne	 short @F	; Jump if not

	 mov	 PGROUP:[si].ELO,07FFFh ; Make artificially large but positive
@@:

; Ensure UMBs are ordered last in case their tare is non-zero

;;;;;;;; mov	 di,PSUMFIT_TAB ; DS:DI ==> summary fit table
;;;;;;;; mov	 si,TEMPOFF	; DS:SI ==> temporary working area
	 mov	 cx,NPROGS	; Number of programs
IV_PRGORD_NEXTUMB2:
	 test	 PGROUP:[di].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jz	 short @F	; Jump if not

	 mov	 PGROUP:[si].ELO,0 ; Make small to place last
@@:
	 add	 si,2		; Skip to next value in TEMPOFF
	 add	 di,size SUMFIT_STR ; Skip to next program

	 loop	 IV_PRGORD_NEXTUMB2 ; Go around again

; Grade down the values in TEMPOFF putting the result into PBPRGORD
; We'll use a simple bubble sort (grade) because there are so few values
; Some care must be taken to ensure that this is a stable sort (grade)

; For the program order table, we need to preserve the relative
; installation order of (1) device drivers, (2) INSTALL=, (3) TSRs.

; If there are any UMBs preceding the first TSR, we must leave alone
; all such entries as we can't associate UMBs in CONFIG.SYS with
; their Device= lines.

; Check for UMBs preceding the first TSR

	 mov	 di,PSUMFIT_TAB ; DS:DI ==> summary fit table
	 mov	 cx,NPROGS	; Number of programs
	 xor	 bx,bx		; Initialize UMB count
	 xor	 ax,ax		; Initialize count of # entries preceding
				; the first TSR
IV_PRGORD_LSEG_NEXT:

; Izit a Device= or Install= line?

	 test	 PGROUP:[di].SUMFIT_FLAG,@LSEG_DRV or @LSEG_INST ; Izit?
	 jnz	 short @F	; Jump if so

	 test	 PGROUP:[di].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jz	 short IV_PRGORD_LSEG_END ; Jump if not

	 inc	 bx		; Count in another UMB
@@:
	 inc	 ax		; Count in another entry
	 add	 di,size SUMFIT_STR ; Skip to next program

	 loop	 IV_PRGORD_LSEG_NEXT ; Go around again
IV_PRGORD_LSEG_END:
	 and	 bx,bx		; Did we encounter any UMBs preceding 1st TSR?
	 jnz	 short IV_PRGORD_TSR ; Jump if so with AX = count

; First, the device drivers

	 mov	 cx,NDEVS	; CX = # device drivers
	 mov	 si,TEMPOFF	; DS:SI ==> temporary working area
	 mov	 di,PBPRGORD	; ES:DI ==> existing permutation vector for result
	 call	 GRADE_DN	; Grade down CX signed words in DS:SI into ES:DI

; Next, the INSTALL= programs (AX has # leading entries to skip)

	 mov	 ax,NDEVS	; AX = # device drvivers

	 mov	 cx,NINST	; CX = # INSTALL= programs
	 mov	 di,PBPRGORD	; ES:DI ==> existing permutation vector for result
	 add	 di,ax		; Skip over device drivers in PBPRGORD

	 shl	 ax,1-0 	; Convert from words to bytes
	 mov	 si,TEMPOFF	; DS:SI ==> temporary working area
	 add	 si,ax		; Skip over device drivers in TEMPOFF
	 call	 GRADE_DN	; Grade down CX signed words in DS:SI into ES:DI

; Last, the TSRs (AX has # leading entries to skip)

	 mov	 ax,NDEVS	; AX = # device drvivers
	 add	 ax,NINST	; Plus # INSTALL= programs
IV_PRGORD_TSR:
	 mov	 cx,NPROGS	; CX = # programs
	 sub	 cx,ax		; Subtract to get # TSRs
	 mov	 di,PBPRGORD	; ES:DI ==> existing permutation vector for result
	 add	 di,ax		; Skip over device drivers in PBPRGORD

	 shl	 ax,1-0 	; Convert from words to bytes
	 mov	 si,TEMPOFF	; DS:SI ==> temporary working area
	 add	 si,ax		; Skip over device drivers in TEMPOFF

; If the first TSR is COMMAND.COM, it can't be re-ordered

	 shr	 ax,1-0 	; Convert from bytes to words
	 mov	 ah,type SUMFIT_STR ; Get size of SUMFIT structure
	 mul	 ah		;
	 add	 ax,PSUMFIT_TAB ; DS:AX ==> summary fit table
	 mov	 bx,ax		; Copy to index register

	 cmp	 PGROUP:[bx].SUMFIT_GRP,@GRP_HIPROG ; Izit COMMAND.COM?
	 jne	 short @F	; Jump if not

	 dec	 cx		; Account for it
	 inc	 di		; Skip over the byte
	 add	 si,2		; ...		word
@@:
	 call	 GRADE_DN	; Grade down CX signed words in DS:SI into ES:DI

; Copy group #s to temporary working area (it's in words and we'll use
; it in bytes so no need to further allocate memory)

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 si,PBPRGORD	; DS:SI ==> program order table
	 mov	 di,TEMPOFF	; ES:DI ==> temporary working area
@@:
	 lodsb			; Get next program order #
	 mov	 ah,type SUMFIT_STR ; Get size of SUMFIT structure
	 mul	 ah		;
	 add	 ax,PSUMFIT_TAB ; DS:AX ==> summary fit table
	 mov	 bx,ax		; Copy to index register
	 mov	 al,PGROUP:[bx].SUMFIT_GRP ; Get the group #

	 stosb			; Save in temporary working area

	 loop	 @B		; Jump if more programs

; Ensure group members are in ascending order within the group

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 si,TEMPOFF	; DS:SI ==> temporary working area
IV_PRGORD_GRP_NEXT:
	 lodsb			; Get next group #

; Note that UMBs may have the SUMFIT_GRP value changed by Maximize if
; the UMB allocator was manually marked for reordering.
	 cmp	 al,@GRPUMB	; Izit our fearless leader or an unchanged UMB?
	 jae	 short IV_PRGORD_GRP_LOOP ; Jump if so

	 cmp	 al,0		; Izit in a group?
	 je	 short IV_PRGORD_GRP_LOOP ; Jump if not

; Get the corresponding program order # from PBPRGORD

	 REGSAVE <cx,si>	; Save for a moment

	 mov	 cx,si		; Copy index+1
	 dec	 cx		; Convert to origin-0
	 sub	 cx,TEMPOFF	; Convert to index #
	 mov	 bx,cx		; Copy to index register
	 add	 bx,PBPRGORD	; DS:BX ==> program order #
	 mov	 ah,PGROUP:[bx] ; Get program order #

; Swap this program order # with all preceding larger ones in the same group

; Search for others in the same group

	 mov	 di,TEMPOFF	; ES:DI ==> temporary working area
IV_PRGORD_SAME_NEXT:
	 jcxz	 IV_PRGORD_SAME_END ; Jump if none to search
   repne scasb			; Search for it
	 jne	 short IV_PRGORD_SAME_END ; Jump if not found

	 mov	 si,di		; Copy to another index register
	 dec	 si		; Convert to origin-0
	 sub	 si,TEMPOFF	; Convert to index #
	 add	 si,PBPRGORD	; DS:SI ==> program order #

	 cmp	 ah,PGROUP:[si] ; Check later AH vs earlier PGROUP:[si]
	 jae	 short @F	; Jump if in proper order

	 xchg	 ah,PGROUP:[si] ; Swap 'em
	 mov	 PGROUP:[bx],ah
@@:
	 jmp	 short IV_PRGORD_SAME_NEXT ; Go around again

IV_PRGORD_SAME_END:
	 REGREST <si,cx>	; Restore
IV_PRGORD_GRP_LOOP:
	 loop	 IV_PRGORD_GRP_NEXT ; Jump if more programs

; TEMPOFF is PRGORD iota APVORD

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 di,TEMPOFF	; ES:DI ==> temporary working area
	 mov	 si,PBAPVORD	; DS:SI ==> APV order table
@@:
	 lodsb			; Get next APV order #

	 REGSAVE <cx,di>	; Save for a moment

	 mov	 di,PBPRGORD	; ES:DI ==> program order table
	 mov	 cx,NPROGS	; CX = # programs
   repne scasb			; Search for it
	 sub	 di,PBPRGORD	; Convert to origin-1
	 dec	 di		; Convert to origin-0
	 mov	 ax,di		; Copy to STOS register

	 REGREST <di,cx>	; Restore

	 stosb			; Save in APV order table

	 loop	 @B		; Jump if more

; Copy back to APVORD

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 si,TEMPOFF	; DS:SI ==> temporary working area
	 mov	 di,PBAPVORD	; ES:DI ==> APV order table
     rep movs	 PGROUP:[di].LO,PGROUP:[si].LO ; Copy to APV order table

if @DEBUG
	 call	 D_APVORD	; Display APVORD
	 call	 D_PRGORD	; Display PRGORD
endif				; IF @DEBUG

; De-allocate room for temporary working area
; at one word per program

	 mov	 ax,NPROGS	; Get # programs
	 shl	 ax,1-0 	; Convert from words to bytes
	 sub	 NEXTAVL,ax	; De-allocate it
	 mov	 TEMPOFF,-1	; Zap it for debugging
IV_PRGORD_EXIT:

COMMENT|

Clear APV mask to 0 if

  * 386MAX if NOLOADHI
  * Device driver or TSR whose installation size is zero

otherwise, set to 1.

APVMASK[i] == MASK [PRGORD [APVORD[i]]]

|

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 si,PBAPVORD	; DS:SI ==> APV order table
	 mov	 di,PBAPVMASK	; ES:DI ==> APV mask
	 mov	 PROGMASK,0	; Start with no programs masked out
IV_PRGORD_MASK:
	 mov	 ah,0		; Zero to use as word
	 lodsb			; Get next APV order #
	 mov	 bx,PBPRGORD	; DS:BX ==> program order table
	 add	 bx,ax		; Add to get index into PBPRGORD

	 mov	 al,type SUMFIT_STR ; Get size of structure
	 mul	 PGROUP:[bx].LO ; Times program #
	 mov	 bx,ax		; Copy to index register
	 add	 bx,PSUMFIT_TAB ; DS:BX ==> this entry in summary fit table

; Check the mask state of this entry

	 mov	 al,0		; Assume to be loaded low

	 cmp	 PGROUP:[bx].SUMFIT_GRP,@GRPMAX ; Izit 386MAX?
	 jne	 short @F	; Jump if not

	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_XLHI ; Izit NOLOADHI?
	 jnz	 short IV_PRGORD_LOOP ; Jump if so

@@:
	 cmp	 REORD_FLAG,2	; Izit subsegment optimization?
	 je	 short IV_PRGORD_HI ; Jump if so (SUMFIT_FLAG is from SUBSEG_STR)

	 ; If we're using an older version of the loader for debugging
	 ; purposes, the program may have failed to go resident but the
	 ; @LOAD_XRES bit will not have been set.  Handle both cases.
; Programs with 386LOAD GETSIZE that allocate UMBs will have both the
; @LSEG_UMB and either @LSEG_DRV or @LSEG_INST bits set.  If this is
; the case, force it low and turn off the @LSEG_UMB bit, as this is
; how we recognize UMBs.
;;;;;;;  ; We also check here for programs that had a 386LOAD GETSIZE
;;;;;;;  ; on them, but end up allocating UMBs.  We plead nolo contendere
;;;;;;;  ; and leave it low, since 386LOAD won't allow a program to
;;;;;;;  ; load itself high AND allocate UMBs.
	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_XRES ; Did it not go resident?
	 jnz	 short IV_PRGORD_LOOP ; Jump if so

	 cmp	 PGROUP:[bx].SUMFIT_IPARA,0 ; Izit resident?
	 je	 short IV_PRGORD_LOOP ; Jump if not

	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB or 386LOAD with
				; a GETSIZE on a UMB allocator?
	 jz	 short IV_PRGORD_HI ; Jump if not

	 test	 PGROUP:[bx].SUMFIT_FLAG,(@LSEG_DRV or @LSEG_INST) ; Izit
				; 386LOAD with a UMB allocator?
	 jz	 short IV_PRGORD_HI ; Jump if not

	 and	 PGROUP:[bx].SUMFIT_FLAG,not @LSEG_UMB ; Don't mark as a UMB
	 or	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_XRES ; Mark it as non-resident
	 jmp	 short IV_PRGORD_LOOP ; Force it low

IV_PRGORD_HI:
	 mov	 al,1		; It's to be loaded high
IV_PRGORD_LOOP:

; APVMASK[i] == MASK [PRGORD [APVORD[i]]]

	 stosb			; Save in APV mask vector
	 mov	 ah,0		; Zero to use as word
	 xor	 al,1		; Complement to count zeros
	 add	 PROGMASK,ax	; Count it in

	 add	 bx,type SUMFIT_STR ; Skip to next program entry

	 loop	 IV_PRGORD_MASK ; Jump if more programs to check

	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

IV_PRGORD endp			; End IV_PRGORD procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  FILL_TEMPOFF -- Fill TEMPOFF
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Fill TEMPOFF with maximum sizes.

On entry:

DX	 =	 0 to fill with sizes
	 =	 1 to fill with tares

|

	 REGSAVE <ax,bx,cx,si,di> ; Save registers

; Copy maximum sizes (DX=0) or tares (DX=1) to TEMPOFF

	 mov	 cx,NPROGS	; CX = # programs
	 mov	 si,PSUMFIT_TAB ; DS:SI ==> summary fit table
	 mov	 di,TEMPOFF	; Get index into temporary working area
if @OEM_FLEX
	 mov	 bx,REGDIF_IND	; Get index into REGDIF/REGEMS
endif				; IF @OEM_FLEX
FILL_TEMPOFF_NEXT:
	 cmp	 dx,1		; Fill with tares?
	 je	 short FILL_TEMPOFF_TARE ; Jump if so

	 mov	 ax,PGROUP:[si].SUMFIT_RPARA ; Get # paras for resident program
	 inc	 ax		; Count in MAC para
	 test	 PGROUP:[si].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 jnz	 short @F	; Jump if so

	 add	 ax,PGROUP:[si].SUMFIT_EPAR1 ; Get # paras for resident environment
@@:
	 jmp	 short FILL_TEMPOFF_COM ; Join common code

FILL_TEMPOFF_TARE:
	 mov	 ax,PGROUP:[si].SUMFIT_IPARA ; Get # paras needed to install
;;;;;;;; inc	 ax		; Count in MAC para
	 sub	 ax,PGROUP:[si].SUMFIT_RPARA ; Less # paras needed to go resident
;;;;;;;; dec	 ax		; Count out MAC para

if @OEM_FLEX
	 test	 PGROUP:[si].SUMFIT_FLAG,@LSEG_FLEX ; Is FLEXFRAME allowed?
	 jz	 short FILL_TEMPOFF_COM ; Jump if not

	 cmp	 REORD_FLAG,1	; Allow re-ordering?
	 jne	 short FILL_TEMPOFF_COM ; Jump if not

	 sub	 ax,REGEMS[bx]	; Less size of adjacent EMS-mappable pages
endif				; IF @OEM_FLEX
FILL_TEMPOFF_COM:
	 stosw			; Save in temporary working area

	 add	 si,type SUMFIT_STR ; Skip to next program entry

	 loop	 FILL_TEMPOFF_NEXT ; Jump if more programs

	 REGREST <di,si,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FILL_TEMPOFF endp		; End FILL_TEMPOFF procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  GRADE_DN -- Grade Down Signed Words into Bytes
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Grade down an array of signed words into bytes.

On entry:

DS:SI	 ==>	 vector of words to grade down
CX	 =	 # words to grade down
ES:DI	 ==>	 existing permutation vector of bytes for result

|

GRADE_DN_STR struc

GRADE_DN_INP dw  ?		; Offset of original input
GRADE_DN_OUT dw  ?		; ...		     output

GRADE_DN_STR ends

	 push	 bp		; Prepare to address the stack
	 sub	 sp,size GRADE_DN_STR ; Make room for structure
	 mov	 bp,sp		; Hello, Mr. Stack

	 mov	 [bp].GRADE_DN_INP,si ; Save for later use
	 mov	 [bp].GRADE_DN_OUT,di ; ...

	 REGSAVE <ax,bx,cx,si>	; Save registers

	 jcxz	 GRADE_DN_EXIT	; Jump if no words to grade

	 jmp	 short GRADE_DN_NEXT ; Join common next code

GRADE_DN1:
	 cmp	 ax,PGROUP:[bx] ; Swap if next size is larger
	 jge	 short GRADE_DN2 ; Jump if not

; Rotate up by one the entries from SI to BX (SI < BX)

	 REGSAVE <cx,si,di>	; Save for a moment

	 mov	 ax,PGROUP:[bx] ; Save the old value at the top

; The length to move is then BX-SI as we save the top value separately

	 mov	 cx,bx		; Copy top offset
	 sub	 cx,si		; Less bottom offset to get length
	 shr	 cx,1-0 	; Convert from bytes to words

	 mov	 di,bx		; ES:DI ==> destin
	 lea	 si,[di-2]	; DS:SI ==> source
	 std			; String ops backwards
     rep movs	 PGROUP:[di].ELO,PGROUP:[si].ELO ; Copy backwards
	 cld			; Restore

	 REGREST <di,si,cx>	; Restore

	 mov	 PGROUP:[si],ax ; Save the old top value at the bottom

; Now do the same thing to the permutation vector

	 sub	 si,[bp].GRADE_DN_INP ; Convert to origin-0
	 shr	 si,1-0 	; Convert from words to bytes
	 add	 si,[bp].GRADE_DN_OUT ; Convert to index in permutation table

	 sub	 bx,[bp].GRADE_DN_INP ; Convert to origin-0
	 shr	 bx,1-0 	; Convert from words to bytes
	 add	 bx,[bp].GRADE_DN_OUT ; Convert to index in permutation vector

; Rotate up by one the entries from SI to BX (SI < BX)

	 REGSAVE <cx,si,di>	; Save for a moment

	 mov	 al,PGROUP:[bx] ; Save the old value at the top

; The length to move is then BX-SI as we save the top value separately

	 mov	 cx,bx		; Copy top offset
	 sub	 cx,si		; Less bottom offset to get length

	 mov	 di,bx		; ES:DI ==> destin
	 lea	 si,[di-1]	; DS:SI ==> source
	 std			; String ops backwards
     rep movs	 PGROUP:[di].LO,PGROUP:[si].LO ; Copy backwards
	 cld			; Restore

	 REGREST <di,si,cx>	; Restore

	 mov	 PGROUP:[si],al ; Save the old top value at the bottom

	 stc			; Indicate we swapped

	 jmp	 short GRADE_DN3 ; Join common code

GRADE_DN_NEXT:
	 mov	 ax,PGROUP:[si] ; Get next size

; Search through the remaining values looking for a larger value
; with which to exchange this one

	 REGSAVE <cx,si>	; Save for a moment

	 mov	 bx,si		; DS:BX ==> next temporary size
GRADE_DN2:
	 add	 bx,2		; Skip to next value

	 loop	 GRADE_DN1	; Jump if more sizes to check

	 clc			; Indicate no swap
GRADE_DN3:
	 REGREST <si,cx>	; Restore
	 jc	 short GRADE_DN_NEXT ; Jump if swapped

	 add	 si,2		; Skip to next entry

	 loop	 GRADE_DN_NEXT	; Jump if more entries to check
GRADE_DN_EXIT:
	 REGREST <si,cx,bx,ax>	; Restore

	 add	 sp,size GRADE_DN_STR ; Strip structure from stack
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GRADE_DN endp			; End GRADE_DN procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  CV_MANY -- Create Many Variables
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Create many variables.	For subsegment optimization, we need to allocate
MAX(NPROGS,NSUBSEGS) elements.

|

	 REGSAVE <ax,bx,cx,dx,di> ; Save registers

; Get number of elements to allocate
	 mov	 bx,NPROGS	; Default value
if @OEM_HARPO
	 cmp	 bx,NSUBSEGS	; Are there more subsegs than programs?
	 jnb	 short @F	; Jump if not

	 mov	 bx,NSUBSEGS	; New maximum
@@:
endif				; IF @OEM_HARPO
	 mov	 NELEM,bx	; Initialize element count

; Allocate room for program order vector
; at one byte per program/subsegment

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBPRGORD,di	; Save for later use
	 add	 NEXTAVL,bx	; Allocate it

; Allocate room for APV order vector
; at one byte per program/subsegment

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBAPVORD,di	; Save for later use
	 add	 NEXTAVL,bx	; Allocate it

; Initialize BESTSIZE to zero

	 mov	 BESTSIZE,0	; ES:DI ==> best sizes

; Allocate room for available program bit vector
; at one byte per program/subsegment

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBAPVBIT,di	; Save for later use
	 add	 NEXTAVL,bx	; Allocate it

; Allocate room for available program bit vector mask
; at one byte per program/subsegment

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBAPVMASK,di	; Save for later use
	 add	 NEXTAVL,bx	; Allocate it

; Allocate room for available program vector by max size
; at one byte per program/subsegment

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBRAPV,di	; Save for later use
	 add	 NEXTAVL,bx	; Allocate it

; Allocate room for global fit vector
; at (type RFIT_STR) bytes per element

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBRFIT,di	; Save for later use
	 mov	 al,type RFIT_STR ; Get size of RFIT structure
	 mul	 bl		; Times # elements
	 add	 NEXTAVL,ax	; Allocate it

; Allocate room for global program vs. region bit vector
; at NREGS bytes per element

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBPVR,di	; Save for later use
	 mov	 al,NREGS.LO	; Get # regions
	 mul	 bl		; Times # elements
	 add	 NEXTAVL,ax	; Allocate it

; Allocate room for global environment vs. region bit vector
; at NREGS bytes per element

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBEVR,di	; Save for later use
	 mov	 al,NREGS.LO	; Get # regions
	 mul	 bl		; Times # elements
	 add	 NEXTAVL,ax	; Allocate it

; Allocate room for global region size vector
; at NREGS words per (NELEM+1)

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PWREG,di	; Save for later use
	 mov	 al,bl		; Get # elements
	 inc	 al		; Count in an extra one
	 mul	 NREGS.LO	; Times # regions
	 shl	 ax,1-0 	; Convert from words to bytes
	 add	 NEXTAVL,ax	; Allocate it

; Allocate (NELEM+1) lword elements of NREGS^iota (NPROGS-PROGMASK)

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PQREXP,di	; Save offset of exponent list
	 mov	 ax,bx		; Get number of elements
	 inc	 ax		; Count in zero case
	 mov	 dx,@LONGWORDS*2 ; Get # bytes per lword
	 mul	 dx		; AX = bytes to release
	 add	 NEXTAVL,ax	; Allocate storage

; Allocate NELEM bytes for recursive product vector

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 mov	 PBRPV,di	; Save offset of recursive product vector
	 add	 NEXTAVL,bx	; Allocate storage

	 REGREST <di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CV_MANY  endp			; End CV_MANY procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  DV_MANY -- Delete Many Variables
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Delete many variables.

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 bx,NELEM	; Get number of elements

; De-allocate NELEM bytes for recursive product vector

	 sub	 NEXTAVL,bx	; De-allocate storage
	 mov	 PBRPV,-1	; Zap it for debugging

; De-allocate (NELEM+1) lword elements of NREGS^iota (NPROGS-PROGMASK)

	 mov	 ax,bx		; Get number of elements
	 inc	 ax		; Count in zero case
	 mov	 dx,@LONGWORDS*2 ; Get # bytes per lword
	 mul	 dx		; AX = bytes to release
	 sub	 NEXTAVL,ax	; De-allocate storage
	 mov	 PQREXP,-1	; Zap it for debugging

; De-allocate room for global region size vector
; at NREGS words per (NELEM+1)

	 mov	 al,bl		; Get # elements
	 inc	 al		; Count in an extra one
	 mul	 NREGS.LO	; Times # regions
	 shl	 ax,1-0 	; Convert from words to bytes
	 sub	 NEXTAVL,ax	; De-allocate it
	 mov	 PWREG,-1	; Zap it for debugging

; De-allocate room for global environment vs. region bit vector
; at NREGS bytes per element

	 mov	 al,bl		; Get # elements
	 mul	 NREGS.LO	; Times # regions
	 sub	 NEXTAVL,ax	; De-allocate it
	 mov	 PBEVR,-1	; Zap it for debugging

; De-allocate room for global program vs. region bit vector
; at NREGS bytes per element

	 mov	 al,bl		; Get # elements
	 mul	 NREGS.LO	; Times # regions
	 sub	 NEXTAVL,ax	; De-allocate it
	 mov	 PBPVR,-1	; Zap it for debugging

; De-allocate room for global fit vector
; at (type RFIT_STR) bytes per element

	 mov	 al,type RFIT_STR ; Get size of RFIT structure
	 mul	 bl		; Times # elements
	 sub	 NEXTAVL,ax	; De-allocate it
	 mov	 PBRFIT,-1	; Zap it for debugging

; De-allocate room for available program vector by max size
; at one byte per element

	 sub	 NEXTAVL,bx	; De-allocate it
	 mov	 PBRAPV,-1	; Zap it for debugging

; De-allocate room for available program bit vector mask
; at one byte per element

	 sub	 NEXTAVL,bx	; De-allocate it
	 mov	 PBAPVMASK,-1	; Zap it for debugging

; De-allocate room for available program bit vector
; at one byte per element

	 sub	 NEXTAVL,bx	; De-allocate it
	 mov	 PBAPVBIT,-1	; Zap it for debugging

; De-allocate room for APV order vector
; at one byte per element

	 sub	 NEXTAVL,bx	; De-allocate it
	 mov	 PBAPVORD,-1	; Zap for debugging

; De-allocate room for program order vector
; at one byte per element

	 sub	 NEXTAVL,bx	; De-allocate it
	 mov	 PBPRGORD,-1	; Zap for debugging

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DV_MANY  endp			; End DV_MANY procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  IV_MANY -- Initialize Several Variables
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Initialize several variables.

|

	 REGSAVE <ax,cx,dx,si,di> ; Save registers

; Initialize global fit vector to -1

	 mov	 di,PBRFIT	; ES:DI ==> global fit vector
	 mov	 al,type RFIT_STR ; Size of RFIT strcuture
	 mul	 NPROGS.LO	; Times # programs
	 mov	 cx,ax		; Copy to count register
	 mov	 al,-1		; Fill value
     rep stosb			; Fill it up

; Initialize the first row of the global region array

	 mov	 di,PWREG	; ES:DI ==> global region vector
	 lea	 si,REGTAB	; DS:SI ==> region table
	 mov	 cx,NREGS	; CX = # regions
     rep movs	 PGROUP:[di].ELO,PGROUP:[si].ELO ; Copy into the first row

	 REGREST <di,si,dx,cx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

IV_MANY  endp			; End IV_MANY procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  FITREC -- Recursive Fit
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Recursive fit

On exit:

AX	 =	 1 if we found a match
	 =	 0 if not
	 =	 2 if user decided to press Esc to accept most recent best fit

|

FITREC_STR struc

CURPORD  dw	 ?		; 00-01:  Current program order #
CURPREG  dw	 ?		; 02-03:  ...	  program region #
CUREREG  dw	 ?		; 04-05:  ...	  environment ...

SIZPINS  dw	 ?		; 06-07:  ...	  program region size to install
SIZPRES  dw	 ?		; 08-09:  ...	  program region size to go resident
SIZEINS  dw	 ?		; 0A-0B:  ...	  env	  region size to install
SIZERES  dw	 ?		; 0C-0D:  ...	  env	  region size to go resident

PWREGLVL dw	 ?		; 0E-0F:  Offset of REG[LVL;]
PBPVRLVL dw	 ?		; 10-11:  Offset of PVR[LVL;]
PBEVRLVL dw	 ?		; 12-13:  Offset of EVR[LVL;]

PBTPO_SRC dw	 ?		; 14-15:  Offset of source TPO
PSUMFIT  dw	 ?		; 16-17:  ...	    CURPORD in SUMFIT table
PSTMP	 dw	 ?		; 18-19:  Offset of temporary structure
DIFSIZ	 dw	 ?		; 1A-1B:  Difference in program max/res size for CURPREG
DIFREG	 dw	 ?		; 1C-1D:  NREGS - (Program region # for DIFSIZ)

FITREC_STR ends

FITRECBK_STR struc
	 db	 (size FITREC_STR) dup (?) ; FITREC_STR

FITREC_BACK dw	 ?		; Saved BP

FITRECBK_STR ends

	 push	 bp		; Prepare to address the stack

	 sub	 sp,size FITREC_STR ; Make room for structure
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <bx,cx,dx,si,di> ; Save registers

if @OEM_HARPO
	 push	 DLGREG 	; Save previous DLGROUP region
endif				; IF @OEM_HARPO

	 inc	 LVL		; Skip to next level

; Allocate room for temporary program order vector
; at one byte per TPOCNT-1

	 mov	 di,NEXTAVL	; Get offset of next available byte
	 xchg	 di,PBTPO	; Swap with previous value
	 mov	 [bp].PBTPO_SRC,di ; Save as source TPO
	 mov	 ax,TPOCNT	; Get # available programs
	 dec	 ax		; Less the one we're deleting
	 add	 NEXTAVL,ax	; Allocate it

	 mov	 si,[bp].PBTPO_SRC ; DS:SI ==> source TPO
	 lodsb			; Get next program order #
	 mov	 ah,0		; Zero to use as word
	 mov	 [bp].CURPORD,ax ; Save as current program order #

	 cmp	 BAILOUT,2	; Did user press Esc?
	MJ e	 FITREC_EXIT	; If so, bail out immediately

; Save offset of CURPORD in SUMFIT table for later use

	 mov	 ax,type SUMFIT_STR ; Get size of SUMFIT structure
	 mul	 [bp].CURPORD	; Times current program order #
	 add	 ax,PSUMFIT_TAB ; Plus offset of SUMFIT table
	 mov	 [bp].PSUMFIT,ax ; Save as offset of CURPORD in SUMFIT table

; Compute bit vector of regions into which this program fits

	 mov	 ax,LVL 	; Get current level #
	 mul	 NREGS		; Times # regions

	 mov	 si,ax		; Copy to index register
	 shl	 si,1-0 	; Convert from words to bytes
	 add	 si,PWREG	; DS:SI ==> REG[LVL;]
	 mov	 [bp].PWREGLVL,si ; Save for later use

	 mov	 di,ax		; Copy to index register
	 add	 di,PBEVR	; ES:DI ==> EVR[LVL;]
	 mov	 [bp].PBEVRLVL,di ; Save for later use

	 mov	 di,ax		; Copy to index register
	 add	 di,PBPVR	; ES:DI ==> PVR[LVL;]
	 mov	 [bp].PBPVRLVL,di ; Save for later use

	 mov	 bx,[bp].PSUMFIT ; DS:BX ==> entry for CURPORD in SUMFIT table
	 mov	 si,[bp].PWREGLVL ; DS:SI ==> REG[LVL;]
	 mov	 di,[bp].PBPVRLVL ; ES:DI ==> PVR[LVL;]

	 mov	 ax,PGROUP:[bx].SUMFIT_RPARA ; Get # paras needed to go resident
	 inc	 ax		; Count in MAC para
	 mov	 [bp].SIZPRES,ax ; Save for later use

	 mov	 ax,PGROUP:[bx].SUMFIT_IPARA ; Get # paras needed to install
	 inc	 ax		; Count in MAC para
	 mov	 [bp].SIZPINS,ax ; Save for later use

; Mark the program region for this entry if it's a UMB as the first one
;   into which it fits.
; Note that UMBs have no way to request FLEXFRAME,
;   so we don't need to introduce FLEXFRAME processing.
; The UMB must be allocated according to the strategy specified in $LSEG_STRA:
; @LSS_FIRST - First fit
; @LSS_BEST - Best fit
; @LSS_LAST - Last fit at high end of region
; We try to allocate the larger of the actual resident size and the maximum
; size saved in LSEG_EPAR0 (normally 0).  If this fails (as is normally the
; case with the default value of -1 used for .COM files) we'll use the
; largest block found, regardless of the current strategy.

; FIXME Note that one case is not covered here.  If we had a way to selectively
; turn off or relocate UMB's, we would need to take into account LSEG entries
; where the ISIZE field reflects an initial allocation for the entire size
; of the region.  This is indicated by the $LSEG_IMAX bit being set in the
; LSEG_FLAG field, in which case the LSIZE field indicates the minimum load
; size.

; Note that the group number for UMBs is not necessarily @GRPUMB;
; MAXIMIZE reordering may force a different group number.
; The @LSEG_UMB bit is also used by 386load.sys when a UMB
; allocator (like sstordrv.sys) is GETSIZEd.  Such entries
; should not exist in Phase 3 of Maximize; they get weeded out
; in Phase 2.
	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	MJ z	 FITREC_XUMB ; Jump if not

	 REGSAVE <di>		; Save register

	 mov	 di,PBRPV	; Get pointer to recursive product vector
	 add	 di,LVL 	; Add index for current level
	 mov	 ax,NREGS	; Get number of regions
	 dec	 ax		; Subtract 1
	 stosb			; PBRPV[LVL] <- NREGS-1

	 REGREST <di>		; Restore register

	 sub	 ax,ax		; Get a zero value
	 mov	 PBESTREG,ax	; Clear pointer to best fit
	 mov	 PLASTREG,ax	; Clear pointer to last fit
	 mov	 MAXREG,ax	; Clear largest fit
	 mov	 PMAXREG,ax	; Clear pointer to largest fit
	 dec	 ax		; Get -1
	 mov	 BESTREG,ax	; Initialize to a worst value

; We need to check the bitmap stored in SUMFIT_EPAR1 bits 0-11 for ancestors
; of this UMB which were allocated to their initialization size at the time
; this one was allocated.  We'll calculate the difference between their
; initialization and resident sizes, save it in an array, and subtract
; it from our REG[LVL;] array.	We'll add the saved values back in below.
; We check up to 12 ancestors.	Bit 11 corresponds to the previous LSEG,
; bit 10 to its predecessor, and so on.
; Note that ancestor UMB LSEGs are marked in the ancestor bitmap under
; exactly two conditions, which are evaluated when the bitmap is constructed
; when the UMB is initially allocated:
; 1. MAX(LSEG_ISIZE,LSEG_LSIZE) + LSEG_NPARA*10 == LSEG_RPARA*10 AND
;    $LSEG_EP1UIMAX is not set in LSEG_EPAR1.
; 2. @LSEG_IMAX is set in LSEG_FLAG.
if @OEM_HARPO
	 mov	 ax,@NOTSPEC	; Assume no DLGROUP allocated
	 xchg	 ax,DLGREG	; No DLGROUP allocated
endif				; IF @OEM_HARPO

	 test	 PGROUP:[bx].SUMFIT_EPAR1,mask $LSEG_EP1UPREV ; Are there any
				; ancestors?
if @OEM_HARPO
	 jnz	 short @F	; Jump if so

	 cmp	 ax,@NOTSPEC	; Was DLGROUP previously specified?
	MJ ne	 FITREC_XUMBPREV ; Jump if so

	 test	 PGROUP:[bx].SUMFIT_EPAR1,mask $LSEG_EP1UDLGHI ; Is DLGROUP
				; allocated in high DOS?
	MJ z	 FITREC_XUMBPREV ; Jump if not

@@:
	 push	 ax		; Save DLGROUP region
else
	MJ z	 FITREC_XUMBPREV ; Jump if not
endif				; IF @OEM_HARPO
	 REGSAVE <bx,dx,si,di>	; Save

	 mov	 cx,@NREGS	; Number of elements in UREGDIF
	 lea	 di,UREGDIF	; Address target of STOS
	 sub	 ax,ax		; A convenient zero
  rep	 stos	 UREGDIF[di]	; Initialize all elements to 0

	 mov	 cx,1+(width $LSEG_EP1UPINST) ; Maximum bits to test + 1 because
				; we start at the bottom of the loop

; Note that we'll walk back in physical (LSEG) order through SUMFIT_TAB.
; For each ancestor, we'll add MIN (0, ancestor.SUMFIT_IPARA -
; ancestor.SUMFIT_RPARA) to the UREGDIF table.	In IV_PRGORD, we ensure
; that UMBs are never reordered and will always be presented to FITREC
; in LSEG order.  If the ancestor has the $LSEG_EP1UIMAX bit set, we'll
; make the entire region unavailable.

; We also need to check here for ancestors with $LSEG_EP1UDLGHI set.
; If we find any, we need to restore the DLGREG value which was passed
; down to us.  Later, we'll check to see if this program has *DLGHI set.
; If so, we'll find a home for DLGROUP and pass its region down to our
; children in the recursion tree.

; PGROUP:BX ==> SUMFIT_STR for UMB
; SS:DX ==> FITREC_STR for previous level

	 mov	 dx,bp		; Offset of FITREC_STR for current level
	 jmp	 short FITREC_LOOPANC ; Start at the bottom

FITREC_NEXTANC:
; Check bit (cx+1) in EPAR1 flags.  If set, this ancestor was allocated
; to the max.
	 mov	 di,[bp].PSUMFIT ; PGROUP:DI ==> entry for CURPORD in SUMFIT table
	 mov	 ax,PGROUP:[di].SUMFIT_EPAR1 ; Get UMB ancestor flags
;;;;;;;  and	 ax,mask $LSEG_EP1UPINST ; Isolate ancestor bitmap
	 shr	 ax,cl		; CF=1 if bit (cx+1) was set
	 jnc	 short FITREC_LOOPANC ; Jump if not

	 mov	 di,dx		; SS:DI ==> Ancestor's FITREC_STR
	 mov	 di,ss:[di].CURPREG ; Ancestor's region (origin:0)
	 shl	 di,1		; Index word array
	 mov	 si,[bp].PWREGLVL ; PGROUP:SI ==> Regions for current level
	 add	 si,di		; PGROUP:SI ==> Region to subtract from

	 mov	 ax,PGROUP:[bx].SUMFIT_IPARA ; Get ancestor's initialization
				; size, or MAX(LSEG_ISIZE,LSEG_LSIZE)
	 test	 PGROUP:[bx].SUMFIT_EPAR1,mask $LSEG_EP1UIMAX ; Was it the whole region?
	 jz	 short @F	; Jump if not

	 mov	 ax,PGROUP:[si].ELO ; Get size remaining in region

	 sub	 ax,1		; Less room for a MAC para
	 jb	 short FITREC_LOOPANC ; Jump if there's no room
@@:
if @OEM_HARPO
	 test	 PGROUP:[bx].SUMFIT_EPAR1,mask $LSEG_EP1UDLGHI ; Was DLGREG
				; specified for this one?
	 jz	 short @F	; Jump if not

	 mov	 DLGREG,-2	; Special flag to restore previous value
@@:
endif				; IF @OEM_HARPO
	 sub	 ax,PGROUP:[bx].SUMFIT_RPARA ; Get difference
	 jbe	 short FITREC_LOOPANC ; Jump if <= 0

	 cmp	 ax,PGROUP:[si].ELO ; Compare with size remaining in region
	 jbe	 short @F	; Jump if OK

	 mov	 ax,PGROUP:[si].ELO ; Take what's left
@@:
	 add	 UREGDIF[di],ax ; Add to difference table
	 sub	 PGROUP:[si].ELO,ax ; Subtract from REG[LVL;]
FITREC_LOOPANC:
; If current record is itself a 4B PSP, the buck stops here
	 test	 PGROUP:[bx].SUMFIT_EPAR1,mask $LSEG_EP1UPSP ; Izit a PSP?
	 jnz	 short @F	; Jump if so

	 sub	 bx,size SUMFIT_STR ; Back off to ancestor
	 cmp	 bx,PSUMFIT_TAB ; Have we done 'em all?
	 jb	 short @F	; Jump if so

	 mov	 di,dx		; PGROUP:DI ==> FITREC_STR for this level
	 mov	 dx,ss:[di].FITREC_BACK ; Address FITREC_STR for previous level

; If the ancestor is not a UMB, we're done
	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	 loopnz  FITREC_NEXTANC ; Go around again if so

@@:
	 REGREST <di,si,dx,bx>	; Restore
if @OEM_HARPO
	 pop	 ax		; Restore old DLGREG value

	 cmp	 DLGREG,-2	; Should we restore the previous value?
	 jne	 short @F	; Jump if not

	 mov	 DLGREG,ax	; Restore previous value
@@:
; If a DLGROUP region hasn't been specified and the *DLGHI flag is set,
; do it now.  Because either the environment or the PSP may appear first
; in the LSEG chain, we need to ensure that we don't subtract DLGROUP
; twice, and thus we don't respecify it.
	 test	 PGROUP:[bx].SUMFIT_EPAR1,mask $LSEG_EP1UDLGHI ; Was DLGROUP
				; allocated from high DOS?
	 jz	 short FITREC_SUBDLGROUP ; Jump if not

	 mov	 ax,DLGSIZE	; Get paras to allocate
	 or	 ax,ax		; Is there anything?
	 jz	 short FITREC_XUMBPREV ; Jump if not

; Find a region for DLGROUP.  We allocate it at the high end of the best
; fit region.
	 REGSAVE <bx,cx,dx,si>	; Save

	 mov	 bx,[bp].PWREGLVL ; Address REG[LVL;]
	 mov	 cx,NREGS	; Number of regions
	 mov	 dx,-1		; Identity value for MIN(x,y)
	 sub	 si,si		; Starting index
; AX = paras to find
; PGROUP:BX ==> first high DOS region + word index / 2
; DX = difference.  Find smallest.
; SI = word index / 2 of current region
FITREC_FINDDLG:
	 push	 ax		; Save value we're looking for

	 sub	 ax,PGROUP:[bx+si].ELO ; Will it fit here?
	 jnc	 short @F	; Jump if not

	 neg	 ax		; Get actual difference

	 cmp	 ax,dx		; Izit a better fit than previously?
	 jnb	 short @F	; Jump if not (it's the first best fit we want)

	 mov	 dx,ax		; Save new best fit difference
	 mov	 DLGREG,si	; Save region index (origin:0)
@@:
	 pop	 ax		; Restore

	 inc	 si		; Skip to next byte
	 inc	 bx		; Skip to next word
	 loop	 FITREC_FINDDLG ; Go around again

	 REGREST <si,dx,cx,bx>	; Restore

FITREC_SUBDLGROUP:
	 cmp	 DLGREG,@NOTSPEC ; Has the region been specified?
	 je	 short FITREC_XUMBPREV ; Jump if not

; Subtract DLGSIZE from region DLGREG
	 REGSAVE <bx,si>	; Save

	 mov	 bx,DLGREG	; Get region index (origin:0)
	 shl	 bx,1		; Convert to word index
	 mov	 si,[bp].PWREGLVL ; Address REG[LVL;]
	 mov	 ax,DLGSIZE	; Size of DLGROUP in paras
	 sub	 PGROUP:[si+bx].ELO,ax ; Subtract from region
	 add	 UREGDIF[bx],ax ; Add to difference table

	 REGREST <si,bx>	; Restore
endif				; IF @OEM_HARPO
FITREC_XUMBPREV:
	 mov	 ax,PGROUP:[bx].SUMFIT_FLAG ; Get flags
	 and	 ax,@LSEG_STRA	; Isolate strategy field
	 mov	 cl,$LSEG_STRA	; Bits to shift right
	 shr	 ax,cl		; AL = strategy, AH=0

	 xchg	 ah,al		; Save strategy in AH, mark as not fitting
	 mov	 cx,NREGS	; CX = # regions
	 mov	 dx,[bp].SIZPINS ; Get # paras needed to install
	 cmp	 dx,PGROUP:[bx].SUMFIT_EPAR0 ; Izit larger than the maximum?
	 ja	 short FITREC_NEXTUMB ; Jump if so

	 mov	 dx,PGROUP:[bx].SUMFIT_EPAR0 ; Get maximum request
FITREC_NEXTUMB:
	 REGSAVE <dx>		; Save requested size
	 mov	 dx,PGROUP:[si] ; Get region size
	 cmp	 dx,MAXREG	; Izit larger than the previous worst fit?
	 jna	 short @F	; Jump if not

	 mov	 MAXREG,dx	; Save as worst fit
	 mov	 PMAXREG,di	; Save pointer to worst fit
@@:
	 REGREST <dx>		; Restore

	 cmp	 dx,PGROUP:[si] ; Does this one fit?
	 ja	 short FITREC_NEXTUMB0 ; Jump if not

	 or	 ah,ah		; Izit first fit?
	 jz	 short FITREC_NEXTUMB1 ; Jump if so

	 REGSAVE <dx>		; Save size requested
	 mov	 dx,PGROUP:[si] ; Get region size
	 mov	 PLASTREG,di	; Save pointer to last fit
	 cmp	 dx,BESTREG	; Izit smaller than the previous best fit?
	 jnb	 short @F	; Jump if not

	 mov	 BESTREG,dx	; Save as best fit
	 mov	 PBESTREG,di	; Save pointer to best fit
@@:
	 REGREST <dx>		; Restore
FITREC_NEXTUMB0:
	 stosb			; Save in PBPVR

	 add	 si,type REGTAB ; Skip to next region

	 loop	 FITREC_NEXTUMB ; Jump if more regions to check

; AH should be @LSS_FIRST (no fit), @LSS_BEST, or @LSS_LAST
; If we didn't get a fit, try the original size request on MAXREG.
	 inc	 cx		; Set CX=1 to skip rep stosb
	 mov	 di,PBESTREG	; Get pointer to best region fit
	 or	 di,di		; Did we find one?
	 jz	 short @F	; Jump if not

	 cmp	 ah,@LSS_BEST	; Is the strategy best fit?
	 je	 short FITREC_NEXTUMB1 ; Jump if so

@@:
	 mov	 di,PLASTREG	; Get pointer to last region we fit in
	 or	 di,di		; Did we find any?
;;;;;;;  jz	 short @F	; Jump if not
	 jnz	 short FITREC_NEXTUMB1 ; Jump if so

; If there's no last fit there's no fit at all.  Try the original size
;;;;;;;  cmp	 ah,@LSS_LAST	; Is the strategy last fit?
;;;;;;;  je	 short FITREC_NEXTUMB1 ; Jump if so
;;;;;;;
;;;;;;;@@:
	 mov	 di,PMAXREG	; Get pointer to worst (maximum tare) region fit
	 or	 di,di		; Did we find one?
	 jz	 short FITREC_NOFIT0 ; Jump if not

	 mov	 dx,[bp].SIZPINS ; Get # paras needed to install
	 cmp	 dx,MAXREG	; Will it fit?
	 ja	 short FITREC_NOFIT0 ; Jump if not

FITREC_NEXTUMB1:
; We got a fit.  DI - PBPVRLVL is the 0-based region number.
	 mov	 al,1		; Mark it as fitting
	 stosb			; Save in PBPVR
	 mov	 [bp].CURPREG,di ; Save for later
	 dec	 cx		; Account for it
	 mov	 al,0		; Mark as not fitting
     rep stosb			; Mark remainder as not fitting

; Add the additional allocations back in
if @OEM_HARPO
	 cmp	 DLGREG,@NOTSPEC ; Was a region specified for DLGROUP?
	 jne	 short @F	; Jump if so
endif				; IF @OEM_HARPO

	 test	 PGROUP:[bx].SUMFIT_EPAR1,mask $LSEG_EP1UPREV ; Are there any ancestors?
	MJ z	 FITREC_NEXTPREG3 ; Jump if not
@@:
	 call	 REST_UREGDIF	; Restore the UREGDIF values

	 jmp	 short FITREC_NEXTPREG3 ; Join common code

FITREC_NOFIT0:
	 call	 REST_UREGDIF	; Restore the UREGDIF values
FITREC_NOFIT:
	 stc			; Mark as no fit

	 jmp	 FITREC_EXIT	; Join common exit code

FITREC_XUMB:

COMMENT|

On entry:

DX	 =	 # paras needed to install (including MAC)
DS:BX	 ==>	 entry for CURPORD in SUMFIT table
DS:SI	 ==>	 REG[LVL;]
ES:DI	 ==>	 PVR[LVL;]

|

if @OEM_HARPO
	 mov	 DLGREG,@NOTSPEC ; No DLGROUP
endif				; IF @OEM_HARPO

	 REGSAVE <di>		; Save register

	 mov	 di,PBRPV	; Get base of recursive product vector
	 add	 di,LVL 	; Add index for current level
	 mov	 al,0		; Get value to store
	 stosb			; M[L] <- 0

	 REGREST <di>		; Restore register

	 mov	 cx,NREGS	; CX = # regions
FITREC_NEXTPVR:
	 mov	 al,0		; Assume it doesn't fit

; First, see if the resident size fits

	 mov	 dx,PGROUP:[si] ; Get the region size w/o EMS expansion

	 cmp	 [bp].SIZPRES,dx ; Duzit fit?
	 ja	 short FITREC_NEXTPVR_LOOP ; Jump if not

if @OEM_FLEX

; Next, see if the installation size fits

	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_FLEX ; FLEXFRAME allowed?
	 jz	 short @F	; Jump if not

	 push	 si		; Save for a moment

	 sub	 si,[bp].PWREGLVL ; Less REG[LVL;] to index REGEMS
	 add	 dx,REGEMS[si]	; Plus any adjacent EMS mappable paras

	 pop	 si		; Restore
@@:
endif				; IF @OEM_FLEX
	 cmp	 [bp].SIZPINS,dx ; Duzit fit?
	 ja	 short FITREC_NEXTPVR_LOOP ; Jump if not

	 mov	 al,1		; Mark it as fitting
FITREC_NEXTPVR_LOOP:
	 stosb			; Save in PBPVR

	 REGSAVE <di>		; Save register

	 mov	 di,PBRPV	; Get base of recursive product vector
	 add	 di,LVL 	; Add index for current level
	 cmp	 al,1		; Duzit fit?
	 adc	 PGROUP:[di].LO,0 ; Increment if not (AL=0)

	 REGREST <di>		; Restore register

	 add	 si,type REGTAB ; Skip to next region

	 loop	 FITREC_NEXTPVR ; Jump if more regions to check

; Find index of the smallest region into which this program fits

FITREC_NEXTPREG:
	 mov	 bx,[bp].PWREGLVL ; DS:BX ==> REG[LVL;]
	 mov	 si,[bp].PBPVRLVL ; DS:SI ==> PVR[LVL;]
	 mov	 cx,NREGS	; CX = # regions
	 mov	 dx,-1		; Initialize with unsigned min identity element
FITREC_NEXTPREG1:
	 lodsb			; Get next PVR byte (bit)

	 cmp	 al,0		; Izit available?
	 je	 short FITREC_NEXTPREG2 ; Jump if not

	 cmp	 dx,PGROUP:[bx] ; Use the smaller
	 jbe	 short FITREC_NEXTPREG2 ; Jump if nothing new

	 mov	 [bp].CURPREG,si ; Save region # (origin-PBPVR)
	 mov	 dx,PGROUP:[bx] ; Get the smaller value
FITREC_NEXTPREG2:
	 add	 bx,type REGTAB ; Skip to next region

	 loop	 FITREC_NEXTPREG1 ; Jump if more regions to check

	 cmp	 dx,-1		; Any regions found?
	MJ e	 FITREC_NOFIT ; Jump if not

FITREC_NEXTPREG3:
; We've found the correct region.  CURPREG = PBPVRLVL + index of region + 1.
	 mov	 si,PBRPV	; Get base of recursive product vector
	 add	 si,LVL 	; Add index for current level
	 inc	 PGROUP:[si].LO ; (PBRPV[LVL])++

; Mark program region as used and convert it to origin-0

	 mov	 si,[bp].CURPREG ; Get region # (origin-1)
	 dec	 si		; Convert to origin-0
	 mov	 PGROUP:[si].LO,0 ; Mark as used

	 sub	 si,[bp].PBPVRLVL ; Less PVR[LVL;]
	 mov	 [bp].CURPREG,si ; Save for later use

; Copy current region sizes to the next level

	 mov	 si,[bp].PWREGLVL ; DS:SI ==> REG[LVL;]
	 mov	 di,si		; Copy to destin register
	 add	 di,NREGSLVL	; ES:DI ==> REG[LVL+1;]

	 mov	 cx,NREGS	; CX = # regions
	 REGSAVE <si,di>	; Save for a moment
     rep movs	 PGROUP:[di].ELO,PGROUP:[si].ELO ; Copy to next level
	 REGREST <di,si>	; Restore

; Subtract out maximum program size from current program region

	 mov	 bx,[bp].PSUMFIT ; Get index of CURPORD in SUMFIT table
	 mov	 dx,[bp].SIZPINS ; Get # paras needed to install

if @OEM_FLEX
	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_FLEX ; FLEXFRAME allowed?
	 jz	 short @F	; Jump if not

	 mov	 si,[bp].CURPREG ; Get current region #
	 shl	 si,1-0 	; Convert from words to bytes
	 sub	 dx,REGEMS[si]	; Less any adjacent EMS mappable paras
				; Note that this size may go negative if we
				; are encroaching into FLEXFRAME
@@:
endif				; IF @OEM_FLEX
	 mov	 ax,[bp].CURPREG ; Get current region #
	 shl	 ax,1-0 	; Convert from words to bytes
	 add	 di,ax		; ES:DI ==> REG[LVL+1;PR]
	 sub	 PGROUP:[di],dx ; Less maximum size
				; Note that this result might include
				; adjacent EMS mappable paras

;;;;;;;; mov	 bx,[bp].PSUMFIT ; Get index of CURPORD in SUMFIT table
	 dec	 dx		; Count out MAC paragraph
	 sub	 dx,PGROUP:[bx].SUMFIT_RPARA ; Less resident size
	 mov	 [bp].DIFSIZ,dx ; Save for later use

; Calculate NREGS - CURPREG for use within the NEXTEVR loop

	 mov	 ax,NREGS	; Get # regions
	 sub	 ax,[bp].CURPREG ; Less current program region # (0, NREGS-1)
				; to get range (1, NREGS)
	 mov	 [bp].DIFREG,ax ; Save for later use

; Fit the environment

	 mov	 [bp].CUREREG,@NOTSPEC ; Assume there's no environment

;;;;;;;; mov	 bx,[bp].PSUMFIT ; Get index of CURPORD in SUMFIT table
	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	MJ nz	 FITREC_NOENV	; Jump if so (no environment)

	 mov	 ax,PGROUP:[bx].SUMFIT_EPAR0 ; Get # paras needed to install
	 or	 ax,PGROUP:[bx].SUMFIT_EPAR1 ; Include # paras needed to go resident
	MJ z	 FITREC_NOENV	; Jump if nothing to allocate

; Compute bit vector of regions into which this environment fits

	 mov	 di,[bp].PBEVRLVL ; ES:DI ==> EVR[LVL;]
	 mov	 si,[bp].PWREGLVL ; DS:SI ==> REG[LVL;]
	 add	 si,NREGSLVL	; DS:SI ==> REG[LVL+1;]

;;;;;;;; mov	 bx,[bp].PSUMFIT ; Get index of CURPORD in SUMFIT table
	 mov	 ax,PGROUP:[bx].SUMFIT_EPAR1 ; Get # paras needed to go resident
	 mov	 [bp].SIZERES,ax ; Save for later use

;;;;;;;; mov	 bx,[bp].PSUMFIT ; Get index of CURPORD in SUMFIT table
	 mov	 ax,PGROUP:[bx].SUMFIT_EPAR0 ; Get # paras needed to install
	 mov	 [bp].SIZEINS,ax ; Save for later use

	 mov	 cx,NREGS	; CX = # regions
FITREC_NEXTEVR:
	 mov	 al,0		; Assume it doesn't fit

; First, see if the resident size fits

	 mov	 dx,PGROUP:[si] ; Get the region size
				; Note that this result might include
				; adjacent EMS mappable paras

; Add back in the difference only for the same region #
; for which the difference was computed.

	 cmp	 cx,[bp].DIFREG ; Izit the same?
	 jne	 short @F	; Jump if not

	 add	 dx,[bp].DIFSIZ ; Add back in difference to get size after
				; program has gone resident
				; This number should be >= 0
				; and does NOT include adjacent
				; EMS mappable paras
@@:
	 cmp	 [bp].SIZERES,dx ; Duzit fit?
	 ja	 short FITREC_NEXTEVR_LOOP ; Jump if not

; Next, see if the installation size fits

	 mov	 dx,PGROUP:[si] ; Get the region size
				; Note that this result might include
				; adjacent EMS mappable paras
	 cmp	 [bp].SIZEINS,dx ; Duzit fit?
	 ja	 short FITREC_NEXTEVR_LOOP ; Jump if not

	 mov	 al,1		; Mark it as fitting
FITREC_NEXTEVR_LOOP:
	 stosb			; Save in PBPVR

	 add	 si,type REGTAB ; Skip to next region

	 loop	 FITREC_NEXTEVR ; Jump if more regions to check

; Find the index of the smallest region into which this environment fits

FITREC_NEXTEREG:
	 mov	 si,[bp].PBEVRLVL ; DS:SI ==> EVR[LVL;]
	 mov	 bx,[bp].PWREGLVL ; DS:BX ==> REG[LVL;]
	 add	 bx,NREGSLVL	; DS:BX ==> REG[LVL+1;]

; If there was a previous environment region (ER ne -1),
; add back in the environment size we subtracted out

	 cmp	 [bp].CUREREG,@NOTSPEC ; Any previous region?
	 je	 short @F	; Jump if not

	 mov	 ax,[bp].SIZERES ; Get previous size
	 mov	 di,[bp].CUREREG ; Get previous region # (origin-0)
	 shl	 di,1-0 	; Convert from words to bytes
	 add	 PGROUP:[bx+di],ax ; Add back in
@@:

; Try first with program and environment in the same region

	 mov	 di,si		; Copy to another index register
	 add	 di,[bp].CURPREG ; Plus current program region #

	 cmp	 PGROUP:[di].LO,1 ; Izit available?
	 je	 short FITREC_NEXTEREG3 ; Jump if so

	 mov	 cx,NREGS	; CX = # regions
	 mov	 dx,-1		; Initialize with unsigned min identity element
FITREC_NEXTEREG1:
	 lodsb			; Get next EVR byte (bit)

	 cmp	 al,0		; Izit available?
	 je	 short FITREC_NEXTEREG2 ; Jump if not

	 cmp	 dx,PGROUP:[bx] ; Use the smaller
	 jbe	 short FITREC_NEXTEREG2 ; Jump if nothing new

	 mov	 [bp].CUREREG,si ; Save region #
	 mov	 dx,PGROUP:[bx] ; Get the smaller value
FITREC_NEXTEREG2:
	 add	 bx,type REGTAB ; Skip to next region

	 loop	 FITREC_NEXTEREG1 ; Jump if more regions to check

	 cmp	 dx,-1		; Any regions found?
	MJ e	 FITREC_NEXTPREG ; Jump if not

; Mark environment region as used and convert it to origin-0

	 mov	 di,[bp].CUREREG ; Get region # (origin-1)
	 dec	 di		; Convert to origin-0
FITREC_NEXTEREG3:
	 mov	 PGROUP:[di].LO,0 ; Mark as used
	 sub	 di,[bp].PBEVRLVL ; Less EVR[LVL;]
	 mov	 [bp].CUREREG,di ; Save for later use

;;;;;;;; push	 [bp].CUREREG	; Pass as argument
;;;;;;;; push	 [bp].CURPREG	; Pass as argument
;;;;;;;; push	 [bp].CURPORD	; Pass as argument
;;;;;;;; call	 DISP_REGNO	; Display region #s
;;;;;;;;
; Subtract out environment size (after) from region into which
; the environment fits

;;;;;;;; mov	 di,[bp].CUREREG ; DI = EREG
	 shl	 di,1-0 	; Convert from words to bytes
	 add	 di,[bp].PWREGLVL ; ES:DI ==> REG[LVL;EREG]
	 add	 di,NREGSLVL	; ES:DI ==> REG[LVL+1;EREG]

	 mov	 ax,[bp].SIZERES ; Get environment size (after)
	 sub	 PGROUP:[di],ax ; Subtract it out
FITREC_NOENV:
	 cmp	 TPOCNT,1	; Have we bottomed out?
	 je	 short FITREC_FND ; Yes

; Add back in maximum size and remove resident size from the region
; into which the program fits

	 mov	 di,[bp].CURPREG ; DI = PREG
	 shl	 di,1-0 	; Convert from words to bytes
	 add	 di,[bp].PWREGLVL ; ES:DI ==> REG[LVL;PREG]
	 add	 di,NREGSLVL	; ES:DI ==> REG[LVL+1;PREG]

	 xor	 ax,ax		; A convenient zero
	 xchg	 ax,[bp].DIFSIZ ; Swap with resident size, zero for next time
	 add	 PGROUP:[di],ax ; Plus maximum size, less resident size

; Copy caller's vector to new area deleting CURPORD in the process

	 mov	 cx,TPOCNT	; Get # available programs
	 mov	 si,[bp].PBTPO_SRC ; DS:SI ==> source TPO
	 mov	 di,PBTPO	; ES:DI ==> destin TPO
	 mov	 ah,0		; Zero to use as word
FITREC_NEXTTPO:
	 lodsb			; Get next TPO #

	 cmp	 ax,[bp].CURPORD ; Izit the current one?
	 je	 short @F	; Yes, skip it

	 stosb			; Save in new TPO
@@:
	 loop	 FITREC_NEXTTPO ; Jump if more TPOs to copy

	 dec	 TPOCNT 	; One fewer TPO
	 call	 FITREC 	; Recurse one more level,
				; return with AX significant
	 inc	 TPOCNT 	; One more TPO

	 cmp	 ax,2		; Did user press Esc?
	 jz	 short FITREC_EXIT ; Jump if so

	 cmp	 ax,1		; Did we succeed?
	 je	 short FITREC_FND ; Jump if we did

	 cmp	 [bp].CUREREG,-1 ; Is there an environment?
	MJ ne	 FITREC_NEXTEREG ; Jump if there is

	 mov	 bx,[bp].PSUMFIT ; Get index of CURPORD in SUMFIT table
	 test	 PGROUP:[bx].SUMFIT_FLAG,@LSEG_UMB ; Izit a UMB?
	MJ z	 FITREC_NEXTPREG ; Try another program region if not

	 stc			; Indicate no fit
	 jmp	 short FITREC_EXIT ; Join common exit code

; The current PO fits, save program order #, region #, and environment #

FITREC_FND:
	 mov	 ax,type RFIT_STR ; Get size of RFIT strcuture
	 mul	 [bp].CURPORD	; Times the current PO
	 mov	 di,ax		; ES:DI ==> index into PBRFIT
	 add	 di,PBRFIT	; Plus offset

	 mov	 ax,RAPVCNT	; Get global # available programs
	 sub	 ax,TPOCNT	; Less # available programs
	 mov	 PGROUP:[di].RFIT_PORD,al ; Save in RFIT

	 mov	 ax,[bp].CURPREG ; Get the current program region #
	 mov	 PGROUP:[di].RFIT_PREG,al ; Save in RFIT

	 mov	 ax,[bp].CUREREG ; Get the current environment region #
	 mov	 PGROUP:[di].RFIT_EREG,al ; Save in RFIT

	 clc			; Indicate we succeeded
FITREC_EXIT:
	 pushf			; Save for a moment

; Set this level's entry in recursive product vector to NREGS

	 mov	 di,PBRPV	; Get base of RPV
	 add	 di,LVL 	; Add index for current level
	 mov	 al,NREGS.LO	; Get number of regions
	 stosb			; PBRPV[LVL] <- NREGS

; De-allocate room for temporary program order vector
; at one byte per TPOCNT-1

	 mov	 ax,TPOCNT	; Get # available programs
	 dec	 ax		; Less the one we deleted
	 sub	 NEXTAVL,ax	; De-allocate it
;;;;;;;; mov	 PBTPO,-1	; Zap it for debugging

; Restore caller's PBTPO

	 mov	 ax,[bp].PBTPO_SRC ; Get original value
	 mov	 PBTPO,ax	; Restore
	 popf			; Restore

	 dec	 LVL		; One fewer level (note CF unchanged)

if @OEM_HARPO
	 pop	 DLGREG 	; Restore previous level's DLGROUP region
endif				; IF @OEM_HARPO

	 REGREST <di,si,dx,cx,bx> ; Restore

	 mov	 ax,1		; Assume it worked
	 sbb	 ax,0		; Less one if it didn't

; Check BAILOUT flag

	 cmp	 BAILOUT,2	; Did user press Esc?
	 jne	 short @F	; Jump if not

	 mov	 ax,2		; Signal that we should return immediately
				; from the next level
@@:
	 add	 sp,size FITREC_STR ; Strip structure from stack
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FITREC	 endp			; End FITREC procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  REST_UREGDIF -- Restore UREGDIF Values
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Restore UREGDIF values

On entry:

SS:BP	 ==>	 FITREC_STR

|

	 REGSAVE <ax,bx,cx,si>	; Save registers

	 mov	 cx,NREGS	; Number of regions
	 lea	 si,UREGDIF	; Values to add back in
	 mov	 bx,[bp].PWREGLVL ; Address REG[LVL;]
@@:
	 lods	 UREGDIF[si]	; AX = value to add
	 add	 PGROUP:[bx].ELO,ax ; Add it back in
	 add	 bx,2		; Skip to next region

	 loop	 @B		; Go around again

	 REGREST <si,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REST_UREGDIF endp		; End REST_UREGDIF procedure
endif				; IFDEF OPTIM
ifdef OPTIM
if @DEBUG
	 NPPROC  D_APVORD -- Display APVORD
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display APVORD

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

	 mov	 dh,@R_APVORD	; Get the row #
	 mov	 dl,@C_APVORD	; ...	  col #
	 mov	 bh,0		; Display page #0
	 VIDCALL @SETPOS	; Set cursor position
;;;;;;;; DOSCALL @STROUT,MSG_APVORD ; Display label
	 lea	 dx,MSG_APVORD	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 mov	 si,PBAPVORD	; DS:SI ==> APVORD
	 mov	 cx,NPROGS	; CX = length of ...
	 lea	 bx,HEXTABLE	; DS:BX ==> translate table
	 mov	 dl,16		; Divisor
D_APVORD_NEXT:
	 lodsb			; Get next order #
	 mov	 ah,0		; Zero to use as word
	 div	 dl		; AL = high-order digit
				; AH = low-order ...

	 push	 ax		; Save for a moment
	 xlat	 HEXTABLE	; Translate to ASCII
	 VIDCALL @SETTTY	; Display in next position
	 pop	 ax		; Restore

	 mov	 al,ah		; Get low-order digit
	 xlat	 HEXTABLE	; Translate to ASCII
	 VIDCALL @SETTTY	; Display in next position

	 mov	 al,' '         ; Separator
	 VIDCALL @SETTTY	; Display in next position

	 loop	 D_APVORD_NEXT	; Jump if more

	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

D_APVORD endp			; End D_APVORD procedure
endif				; IF @DEBUG
endif				; IFDEF OPTIM
ifdef OPTIM
if @DEBUG
	 NPPROC  D_PRGORD -- Display PRGORD
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display PRGORD

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

	 mov	 dh,@R_PRGORD	; Get the row #
	 mov	 dl,@C_PRGORD	; ...	  col #
	 mov	 bh,0		; Display page #0
	 VIDCALL @SETPOS	; Set cursor position
;;;;;;;; DOSCALL @STROUT,MSG_PRGORD ; Display label
	 lea	 dx,MSG_PRGORD	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 mov	 si,PBPRGORD	; DS:SI ==> PRGORD
	 mov	 cx,NPROGS	; CX = length of ...
	 lea	 bx,HEXTABLE	; DS:BX ==> translate table
	 mov	 dl,16		; Divisor
D_PRGORD_NEXT:
	 lodsb			; Get next order #
	 mov	 ah,0		; Zero to use as word
	 div	 dl		; AL = high-order digit
				; AH = low-order ...

	 push	 ax		; Save for a moment
	 xlat	 HEXTABLE	; Translate to ASCII
	 VIDCALL @SETTTY	; Display in next position
	 pop	 ax		; Restore

	 mov	 al,ah		; Get low-order digit
	 xlat	 HEXTABLE	; Translate to ASCII
	 VIDCALL @SETTTY	; Display in next position

	 mov	 al,' '         ; Separator
	 VIDCALL @SETTTY	; Display in next position

	 loop	 D_PRGORD_NEXT	; Jump if more

	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

D_PRGORD endp			; End D_PRGORD procedure
endif				; IF @DEBUG
endif				; IFDEF OPTIM
ifdef OPTIM
if @DEBUG
	 NPPROC  D_APV -- Display APV
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display APV

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

	 mov	 dh,@R_APV	; Get the row #
	 mov	 dl,@C_APV	; ...	  col #
	 mov	 bh,0		; Display page #0
	 VIDCALL @SETPOS	; Set cursor position
;;;;;;;; DOSCALL @STROUT,MSG_APV ; Display label
	 lea	 dx,MSG_APV	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 mov	 si,PBAPVBIT	; DS:SI ==> APV
	 mov	 cx,NPROGS	; CX = length of ...
D_APV_NEXT:
	 lodsb			; Get next bit
	 add	 al,'0'         ; Convert to ASCII

	 VIDCALL @SETTTY	; Display in next position

	 loop	 D_APV_NEXT	; Jump if more

	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

D_APV	 endp			; End D_APV procedure
else
	 NPPROC  D_APV -- Display APV
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display APV

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

	 mov	 dx,APV_PTR	; Get the row #
	 mov	 bh,0		; Display page #0
	 VIDCALL @SETPOS	; Set cursor position

	 mov	 si,PBAPVBIT	; DS:SI ==> APV
	 mov	 cx,NPROGS	; CX = length of ...
D_APV_NEXT:
	 lodsb			; Get next bit
	 add	 al,'0'         ; Convert to ASCII

	 VIDCALL @SETTTY	; Display in next position

	 loop	 D_APV_NEXT	; Jump if more

	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

D_APV	 endp			; End D_APV procedure
endif				; IF @DEBUG
endif				; IFDEF OPTIM
ifdef OPTIM
if @DEBUG
	 NPPROC  D_RAPV -- Display RAPV
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display RAPV

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

	 mov	 dh,@R_RAPV	; Get the row #
	 mov	 dl,@C_RAPV	; ...	  col #
	 mov	 bh,0		; Display page #0
	 VIDCALL @SETPOS	; Set cursor position
;;;;;;;; DOSCALL @STROUT,MSG_RAPV ; Display label
	 lea	 dx,MSG_RAPV	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 mov	 si,PBRAPV	; DS:SI ==> RAPV
	 mov	 cx,NPROGS	; CX = length of ...
D_RAPV_NEXT:
	 lodsb			; Get next bit
	 add	 al,'0'         ; Convert to ASCII

	 VIDCALL @SETTTY	; Display in next position

	 loop	 D_RAPV_NEXT	; Jump if more

	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

D_RAPV	 endp			; End D_RAPV procedure
endif				; IF @DEBUG
endif				; IFDEF OPTIM
ifdef OPTIM
	 NPPROC  CPY_SUMSUB -- Subroutine to CPY_SUMFIT
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Perform actual copying for CPY_SUMFIT.

On entry:
BX=1	 Subtract interrupt block from SUMFIT_IPARA
BX=0	 Don't subtract interrupt block, leave EREG alone (this field
	 is used in subsegment optimization to save the previous subsegment
	 region)

|

	 REGSAVE <ax,cx,dx,si,di,es> ; Save registers

	 mov	 di,PSUMFIT_TAB ; DS:DI ==> SUMFIT_TAB
	 mov	 cx,NPROGS	; CX = # programs
	 mov	 si,PBTOPFIT	; DS:SI ==> TOPFIT[0;0]
	 xor	 bl,1		; Convert to increment for region numbers
CPY_SUMSUB_NEXT:

	 or	 bx,bx		; Are we supposed to adjust SUMFIT_IPARA?
	 jnz	 short @F	; Jump if not

; Subtract out the size of the interrupt block in paras

	 mov	 es,PGROUP:[di].SUMFIT_PARA ; Get segment of LSEG
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[0].LSEG_NPARA ; Get size of interrupt block in paras
				; including its MAC para
	 sub	 PGROUP:[di].SUMFIT_IPARA,ax ; Subtract from install size

; Copy the environment region #s

	 mov	 al,PGROUP:[si].RFIT_EREG ; Get its environment region #
	 mov	 PGROUP:[di].SUMFIT_EREG,al ; Save in SUMFIT table

@@:
; Copy the program order #s

	 mov	 al,PGROUP:[si].RFIT_PORD ; Get its order #
	 mov	 PGROUP:[di].SUMFIT_ORD,al ; Save in SUMFIT table

; Copy the program region #s

	 mov	 al,PGROUP:[si].RFIT_PREG ; Get its program region #
	 mov	 PGROUP:[di].SUMFIT_PREG,al ; Save in SUMFIT table

	 add	 si,type RFIT_STR ; Skip to next SUMFIT entry
	 add	 di,type SUMFIT_STR ; Skip to next program entry

	 loop	 CPY_SUMSUB_NEXT ; Jump if more programs
CPY_SUMSUB_END:
	 REGREST <es,di,si,dx,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CPY_SUMSUB endp 		; End CPY_SUMSUB procedure
endif				; IFDEF OPTIM
ifdef OPTIM
	 FPPROC  CPY_SUMFIT -- Copy TOPFIT data to SUMFIT tables
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Copy TOPFIT data to SUMFIT tables.

This program is called from MAXSUB.

|

	 REGSAVE <bx>		; Save

	 mov	 bx,1		; Adjust SUMFIT_IPARA field
	 call	 CPY_SUMSUB	; Move TOPFIT data to SUMFIT table

	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CPY_SUMFIT endp 		; End CPY_SUMFIT procedure
endif				; IFDEF OPTIM
if @OEM_FLEX
	 NPPROC  CALC_REGDIF -- Calculate Number Different REGEMS Regions
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Calculate the number of different REGEMS regions.

|

	 REGSAVE <ax,cx,si,di>	; Save registers

; Copy REGEMS to REGDIF

	 mov	 cx,NREGS	; CX = # regions
	 lea	 si,REGEMS	; DS:SI ==> REGEMS
	 lea	 di,REGDIF	; ES:DI ==> REGDIF
     rep movsw			; Copy 'em

; Search for first value that's not -1

	 mov	 REGDIF_CNT,0	; Initialize counter
	 mov	 cx,NREGS	; CX = # regions
	 lea	 di,REGDIF	; ES:DI ==> REGDIF
CALC_REGDIF_NEXT:
	 jcxz	 CALC_REGDIF_EXIT ; Jump if no more
	 mov	 ax,-1		; Search value
    repe scasw			; Search for it
	 je	 short CALC_REGDIF_EXIT ; Jump if no more

	 inc	 REGDIF_CNT	; Count it in

; Search for any other similar values and set them to -1

	 mov	 ax,PGROUP:[di-(type REGDIF)] ; Get the value that's not -1

	 REGSAVE <cx,di>	; Save count and index of next value
@@:
	 jcxz	 CALC_REGDIF_XEQ ; Jump if no more
   repne scasw			; Search for next
	 jne	 short CALC_REGDIF_XEQ ; Jump if no other matches

	 mov	 PGROUP:[di-(type REGDIF)].ELO,-1 ; Zap it

	 jmp	 short @B	; Go around again

CALC_REGDIF_XEQ:
	 REGREST <di,cx>	; Restore

	 jmp	 short CALC_REGDIF_NEXT ; Go around again

CALC_REGDIF_EXIT:
	 REGREST <di,si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CALC_REGDIF endp		; End CALC_REGDIF procedure
endif				; IF @OEM_FLEX
;;;;;;;;;	   NPPROC  DISP_REGNO -- Display Region #s
;;;;;;;;;	   assume  ds:PGROUP,es:PGROUP,ss:nothing
;;;;;;;;; COMMENT|
;;;;;;;;;
;;;;;;;;; Display region #s
;;;;;;;;;
;;;;;;;;; |
;;;;;;;;;
;;;;;;;;; REGNO_STR struc
;;;;;;;;;
;;;;;;;;;	   dw	   ?		  ; Caller's BP
;;;;;;;;;	   dw	   ?		  ; ...      IP
;;;;;;;;; REGNO_ORD db	   ?,?		  ; Order #
;;;;;;;;; REGNO_PRG db	   ?,?		  ; Program region #
;;;;;;;;; REGNO_ENV db	   ?,?		  ; Environment region #
;;;;;;;;;
;;;;;;;;; REGNO_STR ends
;;;;;;;;;
;;;;;;;;;	   push    bp		  ; Prepare to address the stack
;;;;;;;;;	   mov	   bp,sp	  ; Hello, Mr. Stack
;;;;;;;;;
;;;;;;;;;	   REGSAVE <ax,dx,di>	  ; Save registers
;;;;;;;;;
;;;;;;;;;	   mov	   al,[bp].REGNO_ORD ; Get order # (origin-1)
;;;;;;;;;	   lea	   di,MSG_REGNO1  ; ES:DI ==> output save area
;;;;;;;;;	   call    DB2HEX	  ; Convert AL to ASCII hex at ES:DI
;;;;;;;;;
;;;;;;;;;	   mov	   al,[bp].REGNO_PRG ; Get program region #
;;;;;;;;;	   inc	   al		  ; Convert to origin-1
;;;;;;;;;	   lea	   di,MSG_REGNO2  ; ES:DI ==> output save area
;;;;;;;;;	   call    DB2HEX	  ; Convert AL to ASCII hex at ES:DI
;;;;;;;;;
;;;;;;;;;	   mov	   al,[bp].REGNO_ENV ; Get environment region #
;;;;;;;;;	   inc	   al		  ; Convert to origin-1
;;;;;;;;;	   lea	   di,MSG_REGNO3  ; ES:DI ==> output save area
;;;;;;;;;	   call    DB2HEX	  ; Convert AL to ASCII hex at ES:DI
;;;;;;;;;
;;;;;;;;;	   DOSCALL @STROUT,MSG_REGNO ; Display message
;;;;;;;;;
;;;;;;;;;	   REGREST <di,dx,ax>	  ; Restore
;;;;;;;;;
;;;;;;;;;	   pop	   bp		  ; Restore
;;;;;;;;;
;;;;;;;;;	   ret	   3*2		  ; Return to caller, popping arguments
;;;;;;;;;
;;;;;;;;;	   assume  ds:nothing,es:nothing,ss:nothing
;;;;;;;;;
;;;;;;;;; DISP_REGNO endp		  ; End DISP_REGNO procedure
ifdef OPTIM
	 FPPROC  OPTINT8 -- Timer Tick Interrupt Handler
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Timer tick interrupt handler

|

	 dec	 DISP_CNT	; Subtract timer tick
	MJ nz	 OPTINT8_JMP	; Not time to display

	 mov	 DISP_CNT,@DISP_REF ; Reset counter

; Adjust seconds elapsed.  Adjust primary and secondary adjustment counters.

	 add	 ELAPSED.ELO,1	; Adjust seconds elapsed
	 adc	 ELAPSED.EHI,0	; Adjust high word
	 dec	 DISP_LOSE5	; When it hits 0, lose a tick
	 jnz	 short @F	; Keep going

	 mov	 DISP_LOSE5,@DISP_LOSE5 ; Reset to count another 5 seconds
	 inc	 DISP_CNT	; Add another tick to wait
@@:
	 dec	 DISP_LOSE100	; When this one hits 0, also lose a tick
	 jnz	 short @F	; Continue

	 mov	 DISP_LOSE100,@DISP_LOSE100 ; Reset to count another 100 seconds
	 inc	 DISP_CNT	; Add another tick to wait
@@:
	 cmp	 DISP_BSY,0	; Is the coast clear?
	 je	 short @F	; Go ahead

OPTINT8_JMP:
	 jmp	 OPTINT8_VEC	; Continue on

@@:
	 inc	 DISP_BSY	; Disallow re-entrancy

	 pushf			; Simulate interrupt
	 call	 OPTINT8_VEC	; Call previous handler (sending EOI to PIC)

	 sti			; Turn interrupts on
	 cld			; Set a sane direction for string ops

	 mov	 SAVE_STACK.VSEG,ss ; Save SS
	 mov	 SAVE_STACK.VOFF,sp ; Save SP

	 cli			; Turn off interrupts
	 mov	 ss,CALL_STACK.VSEG ; Get SS for C call
	 assume  ss:nothing	; Tell the assembler
	 mov	 sp,CALL_STACK.VOFF ; Get SP for C call
	 sti			; Enable interrupts

; Set up segment registers

	 REGSAVE <ax,bx,cx,dx,si,di,bp,ds,es> ; Save registers (C programs
				; will trash everything but DS)
	 mov	 ds,PGSEG	; Get our data segment
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 es,PGSEG	; Get our data segment
	 assume  es:PGROUP	; Tell the assembler

; Recalculate percentage and display (if output not redirected)

	 call	 RECALC_PCT	; Recalculate and display

; Check for Esc pressed

	 KEYCALL @GETKST	; Return with ZF=1 if no key pressed
	 jz	 short OPTINT8_EXIT ; Jump if nothing

	 KEYCALL @GETKEY	; Call again to clear keystroke from input

	 cmp	 al,3		; Izit ^C?
	 je	 short @F	; Jump if so

	 or	 ax,ax		; Izit Ctrl-Break?
	 jnz	 short OPTINT8_ESC ; Jump if not

@@:
	 mov	 ax,1		; Callback type 1: query abort
	 jmp	 short OPTINT8_BAILOUT ; Join common bailout code

OPTINT8_ESC:
	 cmp	 ax,@KEY_ESC	; Izit Esc?
	 jne	 short OPTINT8_EXIT ; If not, ignore

	 sub	 ax,ax		; Callback type 0: query accept best fit
	 cmp	 BAILOUT,1	; Can we bail out?
	 jb	 short OPTINT8_EXIT ; Jump if we can't (no best yet)

OPTINT8_BAILOUT:
	 push	 ax		; Pass callback type on stack
;;;;;	 mov	 al,@EOI	; Issue non-specific EOI
;;;;;	 out	 @ICR,al	; Since we are INSIDE int 8, if we don't
;;;;;				; do this before a dialog callback, int 9
;;;;;				; won't even get a chance.
	 call	 _OPT_CALLBACK	; Let the user confirm it
	 pop	 bx		; Clear argument from stack

	 or	 ax,ax		; Izit non-zero?
	 jz	 short OPTINT8_EXIT ; If not, ignore Ctrl-Break or Esc

	 mov	 BAILOUT,2	; Set flag to return NOW

OPTINT8_EXIT:
	 REGREST <es,ds,bp,di,si,dx,cx,bx,ax> ; Restore registers
	 assume  ds:nothing,es:nothing

	 cli			; Disable interrupts
	 mov	 ss,SAVE_STACK.VSEG ; Get old SS
	 assume  ss:nothing	; Tell the assembler
	 mov	 sp,SAVE_STACK.VOFF ; Restore SP
	 sti			; Enable interrupts

	 dec	 DISP_BSY	; OK to call again

	 iret			; Return to interrupt-time code

	 assume  ds:nothing,es:nothing,ss:nothing

OPTINT8 endp			; End OPTINT8 procedure
endif				; ifdef OPTIM

UCODE	 ends			; End UCODE segment

	 MEND			; End UTIL_OPT module

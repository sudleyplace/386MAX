;' $Header:   P:/PVCS/MAX/QMT/MEM_FCN.ASV   1.1   05 Jun 1998 14:03:24   BOB  $
	 title	 MEM_FCN -- MEMCHK Command Function Routines
	 page	 58,122
	 name	 MEM_FCN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-99 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include PTR.INC
	 include ASCII.INC
	 include KEYCALL.INC
	 include BIOSDATA.INC
	 include 386.INC
	include OPEN.INC

	 include MEM_BLK.INC
	 include MEM_OEM.INC
	include MEM_SEGS.INC
	include MEM_TONE.INC
.list

DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	BASIND:word

	extrn	CMD_FLAG:word
	include MEM_CMD.INC

	extrn	CM2_FLAG:word
	include MEM_CM2.INC

	extrn	CNT_FLAG:word
	include MEM_CNT.INC
ifdef @BETA
	extrn	DBG_FLAG:word
	include MEM_DBG.INC
endif				; IFDEF @BETA
	extrn	GL2_FLAG:word
	include MEM_GL2.INC

	extrn	GL3_FLAG:word
	include MEM_GL3.INC

	extrn	ASKBLK:word

	extrn	ITEMCNT:word
	extrn	@ASKITEM_LEN:abs
	extrn	ADVIND:word

	extrn	ACMDIND:word
	extrn	ASKCMDBTN:byte

	extrn	QMTLOGPATH:byte
	extrn	QMTPATH:byte
	extrn	MAPSEG_NXT:word

DATA	ends			; End DATA segment


NDATA	segment use16 dword public 'data' ; Start NDATA segment
	assume	ds:DGROUP

	extrn	MSG_SEP:byte
	extrn	MSG_VAL:byte
	extrn	MSG_OVF:byte
	extrn	MSG_CMDS:byte
	extrn	MSG_PAK:byte
	extrn	MSG_CRLF:byte
	extrn	MSG_READ:byte
	extrn	MSG_OPEN:byte
	extrn	MSG_NAME:byte
	extrn	MSG_PARSE:byte

ifdef @RAMEXAM

	extrn	QMTDAT:dword
	extrn	QMTDAT_W:dword
	extrn	QMTDAT_M:dword
	extrn	TODAY:dword
	extrn	NEXTSCHED:dword

	extrn	ASK_DEFAULT:byte
	extrn	ASK_TIMEOUT:word

	public	CMDOFF
CMDOFF	dw	?		; Saved offset in command line

endif ; @RAMEXAM

	public	MOLEN_TAB
MOLEN_TAB label byte		; Normal, leap year values for:
	db	31,31		; January
	db	28,29		; February
	db	31,31		; March
	db	30,30		; April
	db	31,31		; May
	db	30,30		; June
	db	31,31		; July
	db	31,31		; August
	db	30,30		; September
	db	31,31		; October
	db	30,30		; November
	db	31,31		; December

NDATA	ends			; End NDATA segment


ifdef @RAMEXAM

TONENAM_STR struc

TONENAM_NAME dw ?		; Offset in DGROUP of name
TONENAM_TABL dw ?		; Offset in DGROUP of table

TONENAM_STR ends


TONENAM_MAC macro NAM, TABL
	local	L1,L2

DATAMSG segment use16 byte public 'data' ; Start DATA segment
	assume	ds:DGROUP

L1	db	L2,NAM		; The keyword name
L2	equ	$-L1-1		; Length of ...

DATAMSG ends			; End DATAMSG segment

	TONENAM_STR <offset DGROUP:L1, offset DGROUP:TABL>

	endm			; TONENAM_MAC


DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

ifdef @LIGHTS
	public	LIGHTS_PORT
LIGHTS_PORT dw	?		; I/O port for lights
endif ; ifdef @LIGHTS


TABMAC	macro	TYP,NAM,FDP,RP	    ; Macro to fill in actual tone/light data
	local	L1,CNT

CNT	=	0		; Intialize counter
	irp	XX,<FDP>
CNT	=	CNT + 1 	; Count each entry
	endm			; IRP

;; Signal an error if we don't have triplets

.errnz CNT - 3 * (CNT / 3)

L1	label	byte		; Save the current position
	org	&TYP&TAB_&NAM	 ; Go to this position

	dw	RP, CNT / 3	; Fill in repeat and count fields
	dw	FDP		; Fill in (freq, dur, pause) fields

	org	L1		; Return to original position

	endm			; TABMAC

; Note the following entries *MUST* be in the same order
; as the @TONE_xxx equates

	public	TONE_STATE
TONE_STATE dw	offset DGROUP:TONETAB_INI ; @TONE_INI
	dw	offset DGROUP:TONETAB_RUN ; @TONE_RUN
	dw	offset DGROUP:TONETAB_ATC ; @TONE_ATC
	dw	offset DGROUP:TONETAB_MEM ; @TONE_MEM
	dw	offset DGROUP:TONETAB_PAR ; @TONE_PAR

	public	TONETAB_INI,TONETAB_RUN,TONETAB_ATC,TONETAB_MEM,TONETAB_PAR
TONETAB_INI TONETAB_STR <>	; Startup
TONETAB_RUN TONETAB_STR <>	; Running
TONETAB_ATC TONETAB_STR <>	; All-tests-complete
TONETAB_MEM TONETAB_STR <>	; Memory error
TONETAB_PAR TONETAB_STR <>	; Parity error

; Fill in the actual data

TABMAC	TONE,INI, <200,1,0, 400,1,0, 600,1,0, 800,1,0, 1000,1,0>,0
TABMAC	TONE,RUN, <500,1,18>,65535
TABMAC	TONE,MEM, <200,2,0, 200,2,0, 200,2,0, 90,9,11>,65535
TABMAC	TONE,PAR, <200,2,0, 200,2,0, 200,2,0, 90,9,11>,65535
TABMAC	TONE,ATC, <200,1,0, 400,1,0, 600,1,0, 800,1,0, 1000,1,0>,0

ifdef @LIGHTS
	public	LITE_STATE
LITE_STATE dw	offset DGROUP:LITETAB_INI ; @TONE_INI
	dw	offset DGROUP:LITETAB_RUN ; @TONE_RUN
	dw	offset DGROUP:LITETAB_ATC ; @TONE_ATC
	dw	offset DGROUP:LITETAB_MEM ; @TONE_MEM
	dw	offset DGROUP:LITETAB_PAR ; @TONE_PAR

	public	LITETAB_INI,LITETAB_RUN,LITETAB_ATC,LITETAB_MEM,LITETAB_PAR
LITETAB_INI TONETAB_STR <>	; Startup
LITETAB_RUN TONETAB_STR <>	; Running
LITETAB_ATC TONETAB_STR <>	; All-tests-complete
LITETAB_MEM TONETAB_STR <>	; Memory error
LITETAB_PAR TONETAB_STR <>	; Parity error

; Fill in the actual data

TABMAC	LITE,INI, <7,0,1>,65535
TABMAC	LITE,RUN, <2,1,0>,65535
TABMAC	LITE,MEM, <1,0,1>,65535
TABMAC	LITE,PAR, <1,0,1>,65535
TABMAC	LITE,ATC, <4,2,1>,65535

endif ; ifdef @LIGHTS

DATA	ends			; End DATA segment


NDATA	segment use16 dword public 'data' ; Start NDATA segment
	assume	ds:DGROUP

; Note the following entries *MUST* be in the same order
; as the @TONE_xxx equates

	public	TONENAM_TAB
TONENAM_TAB label tbyte

	TONENAM_MAC 'startup'           , TONETAB_INI
	TONENAM_MAC 'running'           , TONETAB_RUN
	TONENAM_MAC 'all-tests-complete', TONETAB_ATC
	TONENAM_MAC 'memory-failure'    , TONETAB_MEM
	TONENAM_MAC 'parity-failure'    , TONETAB_PAR

	public	TONENAM_TABLEN
TONENAM_TABLEN equ ($-TONENAM_TAB)/(type TONENAM_STR)


ifdef @LIGHTS
; Note the following entries *MUST* be in the same order
; as the @TONE_xxx equates

	public	LITENAM_TAB
LITENAM_TAB label tbyte

	TONENAM_MAC 'startup'           , LITETAB_INI
	TONENAM_MAC 'running'           , LITETAB_RUN
	TONENAM_MAC 'all-tests-complete', LITETAB_ATC
	TONENAM_MAC 'memory-failure'    , LITETAB_MEM
	TONENAM_MAC 'parity-failure'    , LITETAB_PAR

	public	LITENAM_TABPORT
LITENAM_TABPORT equ $-LITENAM_TAB

	TONENAM_MAC 'port'              , LIGHTS_PORT

	public	LITENAM_TABLEN
LITENAM_TABLEN equ ($-LITENAM_TAB)/(type TONENAM_STR)
endif ; ifdef @LIGHTS

NDATA	ends			; End NDATA segment
endif ; @RAMEXAM


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 SKIP_WHITE:near
	 extrn	 BASE2BIN:near
	 extrn	 DISP_UNK:near
	 extrn	 UPPERCASE:near

ifdef @RAMEXAM
	 extrn	 DATE2EPOCH:near
	 extrn	 EPOCH2DATE:near
	 extrn	 EPOCH2WEEKS:near
	 extrn	 WEEKDAYS:word
	 extrn	 DEFAULT_LOG:near
endif

	 extrn	 IZITSEP:near
	 extrn	 WRITESTR:near

	 extrn	 CHECK_VM86:near
	extrn	SetItemOrder:near

ifdef @RAMEXAM
	 NPPROC  NORMALIZE_DATE -- Normalize month and year of date
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:
DH	 Month (origin:1)
CX	 Year since 1980

On exit:
DH	 Normalized month within range 1-12
CX	 Adjusted according to month on entry

|

	 cmp	 dh,1		; Wrap back to previous year?
	 jae	 short @F	; Jump if not

	 add	 dh,12		; Convert 0 to December, etc.
	 dec	 cx		; Adjust year
@@:
	 cmp	 dh,12		; Wrap to next year?
	 jbe	 short @F	; Jump if not

	 sub	 dh,12		; Convert 13 to January, etc.
	 inc	 cx		; Adjust year
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NORMALIZE_DATE endp		; End NORMALIZE_DATE procedure
endif				; IFDEF @RAMEXAM
ifdef @RAMEXAM
	 NPPROC  LASTDAY -- Get last day of specified month
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:
EAX	 Epoch (days since 1/1/80 origin:0)

On exit:
DH	 This month (origin:1)
DL	 Last day of month (origin:1)

|

	 REGSAVE <eax,cx>	; Save

	 call	 EPOCH2DATE	; DH=month (origin:1), DL=day (org:1), CX=year
	 inc	 dh		; Skip to next month
	 call	 NORMALIZE_DATE ; Adjust year
	 mov	 dl,1		; First of next month
	 call	 DATE2EPOCH	; EAX = days since 1/1/1980 (origin:0)
	 dec	 eax		; Get epoch day for last of this month
	 call	 EPOCH2DATE	; DH=month (origin:1), DL=day (org:1), CX=year

	 REGREST <cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LASTDAY  endp			; End LASTDAY procedure
endif				; IFDEF @RAMEXAM
	 NPPROC  FCN_ADVANCED -- ADVANCED Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 GL2_FLAG,@GL2_ADV ; Mark as advanced mode
	 mov	 ASKBLK,@ITEM_ASKADV ; ...

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ADVANCED endp		; End FCN_ADVANCED procedure
	 NPPROC  FCN_ALL -- ALL Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

ALL=nn

|

	 REGSAVE <ax,cx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 je	 short @F	; Jump if OK

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_ALL_EQ ; Too bad
@@:
	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'c'         ; Izit to be run continuously?
	 je	 short FCN_ALL_CONT ; Jump if so

	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit an end-of-line character?
	 je	 short FCN_ALL_VAL ; Jump if so (missing value)

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_ALL_OVF ; Jump if too large

	 and	 ax,ax		; Is there anything to do?
	 jz	 short FCN_ALL_CLC ; Jump if not

	 cmp	 ax,@CNT_MAX	; Izit larger than our largest value?
	 jbe	 short @F	; Jump if not
FCN_ALL_CONT:
	 mov	 ax,@ICNT_CONT	; Mark as continuous
@@:
	 mov	 cx,@ASKITEM_LEN ; Get # tests to run
	 xor	 di,di		; Initialize index into ITEMCNT
@@:
	 mov	 ITEMCNT[di],ax ; Save as count value

	 add	 di,type ITEMCNT ; Skip to next entry

	 loop	 @B		; Jump it more entries to set

	 or	 CNT_FLAG,@CNT_AUTO or @CNT_CHG ; Mark as running in auto mode
				; and as having changed
FCN_ALL_CLC:
	 clc			; Indicate all went well

	 jmp	 short FCN_ALL_EXIT ; Join common exit code

FCN_ALL_EQ:
	 dec	 si		; Back up to character

	 lea	 di,MSG_SEP	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword

	 jmp	 short FCN_ALL_ERR ; Join common error code

FCN_ALL_VAL:
	 lea	 di,MSG_VAL	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword

	 jmp	 short FCN_ALL_ERR ; Join common error code

FCN_ALL_OVF:
	 lea	 di,MSG_OVF	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword
FCN_ALL_ERR:
	 stc			; Indicate something went wrong
FCN_ALL_EXIT:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ALL  endp			; End FCN_ALL procedure
	 NPPROC  FCN_BW -- BW Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_BW or @CMD_DSET ; Mark as black & white display

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_BW	 endp			; End FCN_BW procedure
	 NPPROC  FCN_COLOR -- COLOR Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 and	 CMD_FLAG,not @CMD_BW ; Turn off black & white flag
	 or	 CMD_FLAG,@CMD_DSET ; Mark as display type set

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_COLOR endp			; End FCN_COLOR procedure
ifdef @RAMEXAM			; If building RAMEXAM
	 NPPROC  FCN_ASK -- ASK Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

ASK[=timeout,default]

where timeout is a delay in seconds, 1 to 3600
and default is a default response î {Y, N, P} (Yes, No, or Postpone).

Specifying a timeout of 0 effectively disables timeout.

|

	 REGSAVE <ax,cx,di>	; Save

	 or	 CMD_FLAG,@CMD_ASK ; Ask for confirmation

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 je	 short @F	; Jump if OK

	 cmp	 al,':'         ; Must be
	 je	 short @F	; Jump if OK

	 dec	 si		; Back up to next keyword
	 jne	 short FCN_ASK_CLC ; Join common code

@@:
	 call	 SKIP_WHITE	; Skip over more white space

	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit an end-of-line character?
	 je	 short FCN_ASK_VAL ; Jump if so (missing value)

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_ASK_OVF ; Jump if too large

	 cmp	 ax,3600	; Izit out of range?
	 ja	 short FCN_ASK_OVF ; Jump if so

	 mov	 ASK_TIMEOUT,ax ; Save for dialog timeout (seconds)

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,','         ; Izit our separator?
	 jne	 short FCN_ASK_EQ ; Jump if not

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,CR		; Izit an end-of-line character?
	 je	 short FCN_ASK_VAL ; Jump if so (missing value)

	 call	 UPPERCASE	; Convert to caps

; Set default button index for this response

	 lea	 di,ASKCMDBTN	; Address button list
	 mov	 cx,3		; Number of button triggers to scan
   repne scas	 ASKCMDBTN[di]	; Find this one
	 jne	 short FCN_ASK_CLC ; Jump if not found (ignore bogus value)

	 mov	 ASK_DEFAULT,al ; Save as default response
	 sub	 di,offset DGROUP:ASKCMDBTN[1] ; DI == index (origin:0)
	 mov	 ACMDIND,di	; Save for dialog display

FCN_ASK_CLC:
	 clc			; Mark as success

	 jmp	 short FCN_ASK_EXIT ; Join common exit

FCN_ASK_VAL:
	 lea	 di,MSG_VAL	; ES:DI ==> error message
	 jmp	 short FCN_ASK_ERRMSG ; Join common error display code

FCN_ASK_EQ:
	 dec	 si		; Back up to character

	 lea	 di,MSG_SEP	; ES:DI ==> error message
	 jmp	 short FCN_ASK_ERRMSG ; Join common error display code

FCN_ASK_OVF:
	 lea	 di,MSG_OVF	; ES:DI ==> error message
FCN_ASK_ERRMSG:
	 call	 DISP_UNK	; Display it along with last keyword

	 stc			; Indicate something went wrong
FCN_ASK_EXIT:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ASK  endp			; End FCN_ASK procedure
endif ; ifdef @RAMEXAM		; If building RAMEXAM
ifdef @RAMEXAM			; If building RAMEXAM
	 NPPROC  FCN_DAILY -- DAILY Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If QMT hasn't run previously today, we're OK.  Otherwise,
return CF=1.

|

	 REGSAVE <eax>		; Save

	 mov	 eax,QMTDAT	; Get date of QMT.DAT (if found)
	 inc	 eax		; Next time = tomorrow
	 cmp	 eax,NEXTSCHED	; Izit sooner than last one we checked?
	 jnb	 short @F	; Jump if not

	 mov	 NEXTSCHED,eax	; Save for display ("Won't run until xx/xx/xx")
@@:
	 cmp	 eax,TODAY	; Izit time to run again?
	 jbe	 short @F	; Jump if so

	 or	 CMD_FLAG,@CMD_SFAIL ; Mark as failed (note CF=0)
	 jmp	 short FCN_DAILY_EXIT ; Join common exit

@@:
	 or	 CMD_FLAG,@CMD_SPASS ; Mark as passed (note CF=0)

FCN_DAILY_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DAILY endp			; End FCN_DAILY procedure
endif ; ifdef @RAMEXAM		; If building RAMEXAM
ifdef @RAMEXAM			; If building RAMEXAM
	 NPPROC  FCN_INTERVAL -- INTERVAL Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

INTERVAL=n

where n is a positive non-zero integer specifying the minimum
elapsed days since the last time QMT was run.

|

	 REGSAVE <eax,cx,di>	; Save

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 je	 short @F	; Jump if OK

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_INTRVL_EQ ; Join common code

@@:
	 call	 SKIP_WHITE	; Skip over more white space

	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit an end-of-line character?
	 je	 short FCN_INTRVL_VAL ; Jump if so (missing value)

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_INTRVL_OVF ; Jump if too large

	 and	 ax,ax		; Is there anything to do?
	 jz	 short FCN_INTRVL_VAL ; Jump if not

	 movzx	 eax,ax 	; Clear high word of INTERVAL= argument

	 add	 eax,QMTDAT	; Add date of QMT.DAT (if found)

	 cmp	 eax,NEXTSCHED	; Izit sooner than last one we checked?
	 jnb	 short @F	; Jump if not

	 mov	 NEXTSCHED,eax	; Save for display ("Won't run until xx/xx/xx")
@@:
	 cmp	 eax,TODAY	; Izit time to run again?
	 jbe	 short @F	; Jump if so

	 or	 CMD_FLAG,@CMD_SFAIL ; Mark as failed (note CF=0)
	 jmp	 short FCN_INTRVL_EXIT ; Join common exit

@@:
	 or	 CMD_FLAG,@CMD_SPASS ; Mark as passed (note CF=0)
	 jmp	 short FCN_INTRVL_EXIT ; Join common exit

FCN_INTRVL_VAL:
	 lea	 di,MSG_VAL	; ES:DI ==> error message
	 jmp	 short FCN_INTRVL_ERRMSG ; Join common error display code

FCN_INTRVL_EQ:
	 dec	 si		; Back up to character

	 lea	 di,MSG_SEP	; ES:DI ==> error message
	 jmp	 short FCN_INTRVL_ERRMSG ; Join common error display code

FCN_INTRVL_OVF:
	 lea	 di,MSG_OVF	; ES:DI ==> error message
FCN_INTRVL_ERRMSG:
	 call	 DISP_UNK	; Display it along with last keyword

	 stc			; Indicate something went wrong
FCN_INTRVL_EXIT:
	 REGREST <di,cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_INTERVAL endp		; End FCN_INTERVAL procedure
endif ; ifdef @RAMEXAM		; If building RAMEXAM
ifdef @RAMEXAM			; If building RAMEXAM
	NPPROC	FCN_OLOG -- OLOG Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

OLOG[=filename]

where the default filename is d:\path\QMTLOG.TXT.

|

	or	CMD_FLAG,@CMD_LOGDEL ; Overwrite log file

	jmp	short FCN_LOG	; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_OLOG endp			; End FCN_OLOG procedure
endif ; ifdef @RAMEXAM		; If building RAMEXAM
ifdef @RAMEXAM			; If building RAMEXAM
	NPPROC	FCN_LOG -- LOG Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

LOG[=filename][,o]

where the default filename is d:\path\QMTLOG.TXT.  If ,o is specified,
the log file will be deleted first; otherwise, we append to it.

|

	REGSAVE <ax,cx,di>	; Save

	cld			; Set forward direction for string ops

	or	CMD_FLAG,@CMD_LOG ; Write to log file

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,'='          ; Must be
	je	short @F	; Jump if OK

	cmp	al,':'          ; Must be
	jne	short FCN_LOG_DEFAULT ; Construct default filename
@@:
	call	SKIP_WHITE	; Skip over more white space

	cmp	al,','          ; Izit LOG=,o ?
	je	short FCN_LOG_DEFAULT ; Use default if so

	call	IZITSEP 	; Izit LOG= ?
	je	short FCN_LOG_VAL ; Bitch about missing value if so

	dec	si		; Back up to character

; Copy pathname for log file

	lea	di,QMTLOGPATH	; Start at the beginning
	mov	cx,127		; Maximum path length (with space for 0)
@@:
	lods	ds:[si].LO	; Get next character

	cmp	al,' '          ; Izit a path terminator?
	je	short @F	; Jump if so

	cmp	al,';'          ; Izit other path terminator?
	je	short @F	; Jump if so

	cmp	al,','          ; Izit other path terminator?
	je	short @F	; Jump if so

	cmp	al,'='          ; Izit other path terminator?
	je	short @F	; Jump if so

	cmp	al,CR		; Izit end of line?
	je	short @F	; Jump if so

S16	stos	QMTLOGPATH[di]	; Save
	loop	@B		; Go around again
@@:
	sub	al,al		; In case we're truncating...
S16	stos	QMTLOGPATH[di]	; ...add an extra terminator

	jmp	short FCN_LOG_COMMA ; Check for ,o

FCN_LOG_DEFAULT:
	call	DEFAULT_LOG	; Set up default QMTLOGPATH
FCN_LOG_COMMA:

; DS:SI ==> next character + 1.  First check for a comma.

	dec	si		; Back off to next character

	mov	al,ds:[si].LO	; Get in AL

	cmp	al,','          ; Izit comma?
	jne	short FCN_LOG_CLC ; Jump if not
@@:
	inc	si		; Skip over the comma
	call	SKIP_WHITE	; Skip whitespace
	call	UPPERCASE	; Convert AL to uppercase

	dec	si		; Back off to character

	cmp	al,@NATL_OVERWRITE ; Izit 'o'?
	jne	short FCN_LOG_VAL ; Jump if not (only option allowed)

	inc	si		; Skip 'o'

	or	CMD_FLAG,@CMD_LOGDEL ; Overwrite log file
FCN_LOG_CLC:
	clc			; Mark as success

	jmp	short FCN_LOG_EXIT ; Join common exit

FCN_LOG_VAL:
	lea	di,MSG_VAL	; ES:DI ==> error message
	call	DISP_UNK	; Display it along with last keyword

	stc			; Indicate something went wrong
FCN_LOG_EXIT:
	REGREST <di,cx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LOG endp			; End FCN_LOG procedure
endif ; ifdef @RAMEXAM		; If building RAMEXAM
ifdef @RAMEXAM			; If building RAMEXAM
	 NPPROC  FCN_MONTHLY -- MONTHLY Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

MONTHLY[=n]

Default for n is 1, meaning that QMT is run at least once on or
after the first of each month.

Note that specifying MONTH=31 will have the effect of always
running QMT on the last day of the month, even for months that
have less than 31 days.

|

	 REGSAVE <eax,ebx,cx,dx,di> ; Save

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 je	 short @F	; Jump if OK

	 cmp	 al,':'         ; Should be this or end of line
	 je	 short @F	; Jump if OK

	 mov	 ax,1		; Default value
	 dec	 si		; Back up to space
	 jmp	 short FCN_MONTHLY_XARG ; Join common code

@@:
	 call	 SKIP_WHITE	; Skip over more white space

	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit an end-of-line character?
	 je	 near ptr FCN_MONTHLY_VAL ; Jump if so (missing value)

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_MONTHLY_OVF ; Jump if too large

	 and	 ax,ax		; Is there anything to do?
	 jz	 near ptr FCN_MONTHLY_VAL ; Jump if not

	 cmp	 ax,31		; Izit a valid month number?
	 ja	 near ptr FCN_MONTHLY_OVF ; Jump if not

FCN_MONTHLY_XARG:
; First we need to normalize AL to the maximum of (AL, last day of
; RAMEXAM.DAT month) for comparison.
	 mov	 bl,al		; Save argument for RAMEXAM.DAT comparison
	 mov	 bh,al		; ...		    current	...
	 mov	 eax,QMTDAT_M	; Get RAMEXAM.DAT date
	 call	 LASTDAY	; DL = last day of RAMEXAM.DAT month
	 cmp	 bl,dl		; Is the argument out of range?
	 jbe	 short @F	; Jump if not

	 mov	 bl,dl		; Use last day of month
@@:
; BL contains normalized argument for RAMEXAM.DAT comparisons.
; Get the RAMEXAM.DAT date.  If day was not less than BL, add 1 to month.
	 mov	 eax,QMTDAT_M	; Get RAMEXAM.DAT date
	 call	 EPOCH2DATE	; DH=month (origin:1), DL=day (org:1), CX=year

	 cmp	 dl,bl		; Did it run during that month?
	 cmc			; Set CF=1 if it ran during that month
	 adc	 dh,0		; Go to next month if so
	 call	 NORMALIZE_DATE ; Adjust month and year modulo 12

	 mov	 dl,1		; Get a day we know is valid for the month
	 call	 DATE2EPOCH	; EAX = days since 1/1/1980 (origin:0)
	 call	 LASTDAY	; DL = last day of RAMEXAM.DAT month +
				; (DOM (RAMEXAM.DAT) < BL) ? 0 : 1

	 cmp	 bh,dl		; Is the argument within range for this month?
	 jbe	 short @F	; Jump if so

	 mov	 bh,dl		; Use last day of month
@@:
	 call	 EPOCH2DATE	; DH=month (origin:1), DL=day (org:1), CX=year
	 mov	 dl,bh		; Use normalized argument to MONTHLY=
	 call	 DATE2EPOCH	; EAX = days since 1/1/1980 (origin:0)

	 cmp	 TODAY,eax	; Are we at or past the scheduled date?
	 jb	 short FCN_MONTHLY_FAIL ; Jump if not

	 or	 CMD_FLAG,@CMD_SPASS ; Mark as passed (note CF=0)
	 jmp	 short FCN_MONTHLY_EXIT ; Join common exit

FCN_MONTHLY_FAIL:
	 cmp	 eax,NEXTSCHED	; Izit sooner than last one we checked?
	 jnb	 short @F	; Jump if not

	 mov	 NEXTSCHED,eax	; Save for display ("Won't run until xx/xx/xx")
@@:
	 or	 CMD_FLAG,@CMD_SFAIL ; Mark as failed
	 jmp	 short FCN_MONTHLY_EXIT ; Join common exit

FCN_MONTHLY_VAL:
	 lea	 di,MSG_VAL	; ES:DI ==> error message
	 jmp	 short FCN_MONTHLY_ERRMSG ; Join common error display code

FCN_MONTHLY_OVF:
	 lea	 di,MSG_OVF	; ES:DI ==> error message
FCN_MONTHLY_ERRMSG:
	 call	 DISP_UNK	; Display it along with last keyword
FCN_MONTHLY_ERR:
	 stc			; Indicate something went wrong
FCN_MONTHLY_EXIT:
	 REGREST <di,dx,cx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_MONTHLY endp		; End FCN_MONTHLY procedure
endif ; ifdef @RAMEXAM		; If building RAMEXAM
ifdef @RAMEXAM			; If building RAMEXAM
	 NPPROC  FCN_WEEKLY -- WEEKLY Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

WEEKLY[=n]

Default for n is 1, meaning that QMT is run once weekly on or
after each Sunday.

|

	 REGSAVE <eax,bx,cx,edx,di> ; Save

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 je	 short @F	; Jump if OK

	 cmp	 al,':'         ; Should be this or end of line
	 je	 short @F	; Jump if we have a number

	 dec	 si		; Back off to space
	 mov	 ax,1		; Default value
	 jmp	 short FCN_WEEKLY_XARG ; Join common code

@@:
	 call	 SKIP_WHITE	; Skip over more white space

	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit an end-of-line character?
	 je	 short FCN_WEEKLY_VAL ; Jump if so (missing value)

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_WEEKLY_OVF ; Jump if too large

	 and	 ax,ax		; Is there anything to do?
	 jz	 short FCN_WEEKLY_VAL ; Jump if not

	 cmp	 ax,WEEKDAYS	; Izit a valid weekday number?
	 ja	 short FCN_WEEKLY_OVF ; Jump if not

FCN_WEEKLY_XARG:
; AL contains the WEEKLY= argument (origin:1).
; Determine the next date to run by taking the week of the last RAMEXAM
; and adding (Dow (last RAMEXAM) < AL) ? 0 : 1.

	 mov	 bl,al		; Save argument
	 mov	 eax,QMTDAT_W	; Get base date for RAMEXAM.DAT
	 call	 EPOCH2WEEKS	; AX = weeks since 1/1/80 - 2 days, DX = day
				; of week (origin:0)
	 inc	 dl		; Convert to origin:1
	 cmp	 dl,bl		; Did it run that week?
	 cmc			; CF=1 if so
	 adc	 ax,0		; AX = week to run in

; Now convert back to epoch and add the argument.
.8086				; Avoid spurious "Impure memory reference"
	 mul	 WEEKDAYS	; DX,AX = days since (1/1/80 - 2 days)
DOT386 p
	 shl	 eax,16 	; Save low order word
	 mov	 ax,dx		; Get high order word
	 rol	 eax,16 	; EAX = days since 1/1/80 - 2 for last Sunday
	 sub	 eax,(2+1)	; Get last day of preceding week
	 movzx	 edx,bl 	; Convert argument to dword
	 add	 eax,edx	; EAX = epoch date to run on

	 cmp	 TODAY,eax	; Are we at or past that date?
	 jb	 short FCN_WEEKLY_FAIL ; Jump if not

	 or	 CMD_FLAG,@CMD_SPASS ; Mark as passed (note CF=0)
	 jmp	 short FCN_WEEKLY_EXIT ; Join common exit

FCN_WEEKLY_FAIL:
	 cmp	 eax,NEXTSCHED	; Izit sooner than last one we checked?
	 jnb	 short @F	; Jump if not

	 mov	 NEXTSCHED,eax	; Save for display ("Won't run until xx/xx/xx")
@@:
	 or	 CMD_FLAG,@CMD_SFAIL ; Mark as failed (note CF=0)
	 jmp	 short FCN_WEEKLY_EXIT ; Join common exit

FCN_WEEKLY_VAL:
	 lea	 di,MSG_VAL	; ES:DI ==> error message
	 jmp	 short FCN_WEEKLY_ERRMSG ; Join common error display code

FCN_WEEKLY_OVF:
	 lea	 di,MSG_OVF	; ES:DI ==> error message
FCN_WEEKLY_ERRMSG:
	 call	 DISP_UNK	; Display it along with last keyword
FCN_WEEKLY_ERR:
	 stc			; Indicate something went wrong
FCN_WEEKLY_EXIT:
	 REGREST <di,edx,cx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_WEEKLY endp 		; End FCN_WEEKLY procedure
endif ; ifdef @RAMEXAM		; If building RAMEXAM
	 NPPROC  FCN_FULL -- FULL Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

FULL=nn

|

	 REGSAVE <ax,cx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 je	 short @F	; Jump if OK

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_FULL_EQ ; Too bad
@@:
	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'c'         ; Izit to be run continuously?
	 je	 short FCN_FULL_CONT ; Jump if so

	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit an end-of-line character?
	 je	 short FCN_FULL_VAL ; Jump if so (missing value)

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_FULL_OVF ; Jump if too large

	 and	 ax,ax		; Is there anything to do?
	 jz	 short FCN_FULL_CLC ; Jump if not

	 cmp	 ax,@CNT_MAX	; Izit larger than our largest value?
	 jbe	 short @F	; Jump if not
FCN_FULL_CONT:
	 mov	 ax,@ICNT_CONT	; Mark as continuous
@@:
	 mov	 ITEMCNT[@ASK_UNLIDM*(type ITEMCNT)],ax ; Save as count value
	 mov	 ITEMCNT[@ASK_LNKIDM*(type ITEMCNT)],ax ; ...

	 or	 CNT_FLAG,@CNT_AUTO or @CNT_CHG ; Mark as running in auto mode
				; and as having changed
	 mov	 BASIND,1	; Mark as full
FCN_FULL_CLC:
	 or	 CNT_FLAG,@CNT_BASIC ; Mark as a BASIC option

	 clc			; Indicate all went well

	 jmp	 short FCN_FULL_EXIT ; Join common exit code

FCN_FULL_EQ:
	 dec	 si		; Back up to character

	 lea	 di,MSG_SEP	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword

	 jmp	 short FCN_FULL_ERR ; Join common error code

FCN_FULL_VAL:
	 lea	 di,MSG_VAL	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword

	 jmp	 short FCN_FULL_ERR ; Join common error code

FCN_FULL_OVF:
	 lea	 di,MSG_OVF	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword
FCN_FULL_ERR:
	 stc			; Indicate something went wrong
FCN_FULL_EXIT:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_FULL endp			; End FCN_FULL procedure
	 NPPROC  FCN_HELP -- HELP Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display command line help.

This could be broken out into a generalized procedure to display
zero-terminated text with pagination.

|

	 pusha			; Save

	 push	 ds		; Save for a moment

	 push	 seg BIOSDATA	; Prepare to address BIOS data area
	 pop	 ds		; Address it
	 assume  ds:BIOSDATA	; Tell the assembler

	 movzx	 bp,EGA_ROWS	; Get screen rows

	 push	 es		; Get segment of MSG_CMDS
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

	 lea	 di,MSG_CMDS	; DGROUP:DI ==> string to display paginated

	 test	 CMD_FLAG,@CMD_STDOUT ; Is STDOUT redirected?
	 jnz	 short @F	; Jump if not

	 mov	 dx,di		; Address message to display
	 mov	 bx,@STD_OUT	; Handle for standard output
	 call	 WRITESTR	; Send ASCIIZ string at DS:DX to file BX

	 jmp	 short FCN_HELP_EXIT ; Join common exit

@@:
;------- Entry to common code, DGROUP:DI ==> text to display ---------

	 cld			; String ops forwardly

	 mov	 dx,di		; Save start of text
	 mov	 cx,-1		; Maximum length supported = 64K
	 sub	 ax,ax		; Look for end of message
   repne scas	 DGROUP:[di].LO ; Find end
	 sete	 al		; AL = 1 if we found trailing null
	 not	 cx		; One's complement negation
	 sub	 cx,ax		; Subtract trailing null

	 mov	 di,dx		; DGROUP:DI ==> start of first line
	 sub	 si,si		; Initialize line counter
FCN_HELP_NEXTLN:
	 jcxz	 FCN_HELP_EOS	; Jump if we've reached the end

	 mov	 al,LF		; Search for end of line
	 mov	 dx,di		; Save start of line
   repne scas	 DGROUP:[di].LO ; DGROUP:DI ==> character after LF

	 push	 cx		; Save count
	 mov	 cx,di		; Get offset
	 sub	 cx,dx		; Subtract start
	 mov	 bx,@STD_OUT	; Handle for standard output
	 DOSCALL @WRITF2	; Write CX bytes from DS:DX to file BX
	 pop	 cx		; Restore count

	 inc	 si		; Adjust lines displayed count

	 cmp	 si,bp		; Have we reached the bottom line yet?
	 jb	 short FCN_HELP_NEXTLN ; Jump if not

	 DOSCALL @STROUT,MSG_PAK ; "Press any key to continue..."

	 KEYCALL @GETKEY	; Get any key

	 DOSCALL @STROUT,MSG_CRLF ; Display CR,LF,EOS

	 sub	 si,si		; Reset lines displayed counter
	 jmp	 short FCN_HELP_NEXTLN ; Go around again

FCN_HELP_EOS:
;------- End code to display text with pagination ----------

FCN_HELP_EXIT:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 stc			; Indicate we should stop here

	 popa			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_HELP endp			; End FCN_HELP procedure
	 NPPROC  FCN_HEX -- HEX Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 GL2_FLAG,@GL2_HEX ; Mark as hexadecimal mode

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_HEX  endp			; End FCN_HEX procedure
	 NPPROC  FCN_LARGER -- LARGER Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 GL2_FLAG,@GL2_LARGER ; Mark as using the larger of mismatched
				; CMOS and BIOS values
	 and	 GL2_FLAG,not @GL2_SMALLER ; ...and not the smaller

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LARGER endp 		; End FCN_LARGER procedure
	NPPROC	FCN_NOCACHE -- NOCACHE Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	or	CM2_FLAG,@CM2_NOCACHE ; Disable caching

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOCACHE endp		; End FCN_NOCACHE procedure
	NPPROC	FCN_NOCACHETEST -- NOCACHETEST Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	or	CM2_FLAG,@CM2_NOCACHETEST ; Disable caching of test code

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOCACHETEST endp		; End FCN_NOCACHETEST procedure
	 NPPROC  FCN_NODPMI -- NODPMI Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_NODPMI ; DPMI services aren't to be trusted

	 btr	 GL2_FLAG,$GL2_DPMI ; Did we detect DPMI services?
	 jnc	 short FCN_NODPMI_EXIT ; Jump if not (note CF=0)

	 REGSAVE <ds>		; Save

	 push	 es		; Get DGROUP segment
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler

	 call	 CHECK_VM86	; Check for a VCPI host, CF significant

	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler
FCN_NODPMI_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NODPMI endp 		; End FCN_NODPMI procedure
	NPPROC	FCN_NOVCPI -- NOVCPI Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	or	CMD_FLAG,@CMD_NOVCPI ; VCPI services aren't to be trusted

	btr	GL2_FLAG,$GL2_VCPI ; Did we detect VCPI services?
	jnc	short FCN_NOVCPI_EXIT ; Jump if not (note CF=0)

	REGSAVE <ds>		; Save

	push	es		; Get DGROUP segment
	pop	ds		; Address it
	assume	ds:DGROUP	; Tell the assembler

	call	CHECK_VM86	; Check for a VCPI host, CF significant

	REGREST <ds>		; Restore
	assume	ds:nothing	; Tell the assembler
FCN_NOVCPI_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOVCPI endp 		; End FCN_NOVCPI procedure
	 NPPROC  FCN_NOEXIT -- NOEXIT Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 CNT_FLAG,@CNT_NOEXIT ; Mark as not to exit after autorun

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOEXIT endp 		; End FCN_NOEXIT procedure
	 NPPROC  FCN_NOPARITY -- NOPARITY Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 GL2_FLAG,@GL2_NOPARITY ; Mark as not supporting parity

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOPARITY endp		; End FCN_NOPARITY procedure
	 NPPROC  FCN_NOSCRUB -- NOSCRUB Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_XSCRB ; Mark as not scrubbing extra RAM

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOSCRUB endp		; End FCN_NOSCRUB procedure
	 NPPROC  FCN_NOXRAM -- NOXRAM Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_X384 ; Mark as present
	 and	 CMD_FLAG,not @CMD_SHD ; Mark as no SHADOWRAM
	 and	 CMD_FLAG,not @CMD_TOP ; Mark as no generic top 384KB of RAM

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOXRAM endp 		; End FCN_NOXRAM procedure
	 NPPROC  FCN_SMALLER -- SMALLER Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 GL2_FLAG,@GL2_SMALLER ; Mark as using the smaller of mismatched
				; CMOS and BIOS values
	 and	 GL2_FLAG,not @GL2_LARGER ; ...and not the larger

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SMALLER endp		; End FCN_SMALLER procedure
	 NPPROC  FCN_QUICK -- QUICK Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

QUICK=nn

|

	 REGSAVE <ax,cx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 je	 short @F	; Jump if OK

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_QUICK_EQ ; Too bad
@@:
	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'c'         ; Izit to be run continuously?
	 je	 short FCN_QUICK_CONT ; Jump if so

	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit an end-of-line character?
	 je	 short FCN_QUICK_VAL ; Jump if so (missing value)

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_QUICK_OVF ; Jump if too large

	 and	 ax,ax		; Is there anything to do?
	 jz	 short FCN_QUICK_CLC ; Jump if not

	 cmp	 ax,@CNT_MAX	; Izit larger than our largest value?
	 jbe	 short @F	; Jump if not
FCN_QUICK_CONT:
	 mov	 ax,@ICNT_CONT	; Mark as continuous
@@:
	 mov	 ITEMCNT[@ASK_UNLTRN*(type ITEMCNT)],ax ; Save as count value

	 or	 CNT_FLAG,@CNT_AUTO or @CNT_CHG ; Mark as running in auto mode
				; and as having changed
	 mov	 BASIND,0	; Mark as quick
FCN_QUICK_CLC:
	 or	 CNT_FLAG,@CNT_BASIC ; Mark as a BASIC option

	 clc			; Indicate all went well

	 jmp	 short FCN_QUICK_EXIT ; Join common exit code

FCN_QUICK_EQ:
	 dec	 si		; Back up to character

	 lea	 di,MSG_SEP	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword

	 jmp	 short FCN_QUICK_ERR ; Join common error code

FCN_QUICK_VAL:
	 lea	 di,MSG_VAL	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword

	 jmp	 short FCN_QUICK_ERR ; Join common error code

FCN_QUICK_OVF:
	 lea	 di,MSG_OVF	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword
FCN_QUICK_ERR:
	 stc			; Indicate something went wrong
FCN_QUICK_EXIT:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_QUICK endp			; End FCN_QUICK procedure
	 NPPROC  FCN_SHADOWRAM -- SHADOWRAM Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

; Because we don't have the mechanisms in place to
; check for ROMs as well as avoid RAM buffers (such as
; for a network adapter), we can't afford the trouble
; this option would give us.

;;;	     call    CHECK_82C302   ; Check on it
;;;	     jc      short @F	    ; Jump if not present
;;;
;;;	     test    CMD_FLAG,@CMD_X384 ; NOXRAM specified?
;;;	     jnz     short @F	    ; Yes, ignore the keyword
;;;
;;;	     or      CMD_FLAG,@CMD_SHD ; Mark as generic shadow RAM
;;; @@:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SHADOWRAM endp		; End FCN_SHADOWRAM procedure
	 NPPROC  FCN_TOP384 -- TOP384 Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 test	 CMD_FLAG,@CMD_X384 ; NOXRAM specified?
	 jnz	 short @F	; Yes, ignore the keyword

	 or	 CMD_FLAG,@CMD_TOP ; Mark as generic top 384KB of RAM
@@:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TOP384 endp 		; End FCN_TOP384 procedure
	NPPROC	FCN_LNKIDM -- LNKIDM Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

LNKIDM=nn

|

	mov	ADVIND,@ASK_LNKIDM ; Save as index

	jmp	short FCN_CNTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LNKIDM endp 		; End FCN_LNKIDM procedure
	NPPROC	FCN_LNKINV -- LNKINV Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

LNKINV=nn

|

	mov	ADVIND,@ASK_LNKINV ; Save as index

	jmp	short FCN_CNTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LNKINV endp 		; End FCN_LNKINV procedure
	NPPROC	FCN_UNLIDM -- UNLIDM Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

UNLIDM=nn

|

	mov	ADVIND,@ASK_UNLIDM ; Save as index

	jmp	short FCN_CNTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_UNLIDM endp 		; End FCN_UNLIDM procedure
	NPPROC	FCN_UNLINV -- UNLINV Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

UNLINV=nn

|

	mov	ADVIND,@ASK_UNLINV ; Save as index

	jmp	short FCN_CNTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_UNLINV endp 		; End FCN_UNLINV procedure
	NPPROC	FCN_UNLSAF -- UNLSAF Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

UNLSAF=nn

|

	mov	ADVIND,@ASK_UNLSAF ; Save as index

	jmp	short FCN_CNTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_UNLSAF endp 		; End FCN_UNLSAF procedure
	NPPROC	FCN_UNLTRN -- UNLTRN Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

UNLTRN=nn

|

	mov	ADVIND,@ASK_UNLTRN ; Save as index

	jmp	short FCN_CNTCOM ; Join common code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_UNLTRN endp 		; End FCN_UNLTRN procedure
	NPPROC	FCN_CNTCOM -- Common Subroutine For Item Counts
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common subroutine for item counts.

|

	 REGSAVE <ax,cx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 je	 short @F	; Jump if OK

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_CNTCOM_EQ ; Too bad
@@:
	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'c'         ; Izit to be run continuously?
	 je	 short FCN_CNTCOM_CONT ; Jump if so

	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit an end-of-line character?
	 je	 short FCN_CNTCOM_VAL ; Jump if so (missing value)

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_CNTCOM_OVF ; Jump if too large

	 and	 ax,ax		; Is there anything to do?
	 jz	 short FCN_CNTCOM_CLC ; Jump if not

	 cmp	 ax,@CNT_MAX	; Izit larger than our largest value?
	 jbe	 short @F	; Jump if not
FCN_CNTCOM_CONT:
	 mov	 ax,@ICNT_CONT	; Mark as continuous
@@:
	call	SetItemOrder	; Set item order of ADVIND to first
	imul	di,ADVIND,type ITEMCNT ; Get ITEMCNT index
	 mov	 ITEMCNT[di],ax ; Save as count value
	 or	 CNT_FLAG,@CNT_AUTO or @CNT_CHG ; Mark as running in auto mode
				; and as having changed
FCN_CNTCOM_CLC:
	 and	 CNT_FLAG,not @CNT_BASIC ; Mark as not a BASIC selection

	 clc			; Indicate all went well

	 jmp	 short FCN_CNTCOM_EXIT ; Join common exit code

FCN_CNTCOM_EQ:
	 dec	 si		; Back up to character

	 lea	 di,MSG_SEP	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword

	 jmp	 short FCN_CNTCOM_ERR ; Join common error code

FCN_CNTCOM_VAL:
	 lea	 di,MSG_VAL	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword

	 jmp	 short FCN_CNTCOM_ERR ; Join common error code

FCN_CNTCOM_OVF:
	 lea	 di,MSG_OVF	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword
FCN_CNTCOM_ERR:
	 stc			; Indicate something went wrong
FCN_CNTCOM_EXIT:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_CNTCOM endp 		; End FCN_CNTCOM procedure
ifdef @RAMEXAM
	NPPROC	FCN_TONE -- TONE Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

TONE
TONE=d:\path\filename.ext

|

	REGSAVE <ax,bx,cx,dx,di,fs> ; Save registers

	or	CM2_FLAG,@CM2_TONE ; Mark as TONE present

; Check for optional filename

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,'='          ; Is filename present?
	je	short @F	; Jump if so

	cmp	al,':'          ; Is filename present?
	je	short @F	; Jump if so

	dec	si		; Back up to last character
	mov	CMDOFF,si	; Save command line offset

	jmp	FCN_TONE_OK	; Join common code

@@:
	call	SKIP_WHITE	; Skip over more white space
	dec	si		; Back up to character
;;;;;;; mov	CMDOFF,si	; Save command line offset

; Copy pathname for tone file

	lea	di,QMTPATH	; Start at the beginning
	mov	cx,127		; Maximum path length (with space for 0)
@@:
	lods	ds:[si].LO	; Get next character

	cmp	al,' '          ; Izit a path terminator?
	je	short @F	; Jump if so

	cmp	al,';'          ; Izit other path terminator?
	je	short @F	; Jump if so

	cmp	al,CR		; Izit end of line?
	je	short @F	; Jump if so

	stos	QMTPATH[di]	; Save
	loop	@B		; Go around again
@@:
	dec	si		; Back up to last character
	mov	CMDOFF,si	; Save command line offset

	sub	al,al		; In case we're truncating...
	stos	QMTPATH[di]	; ...add an extra terminator

; Open the file and read in its contents

	push	ds		; Save for a moment

	mov	ax,es		; Get DGROUP segment
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	al,@OPEN_R	; Open in read-only mode
	DOSCALL @OPENF2,QMTPATH ; Open the file
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
	jc	near ptr FCN_TONE_ERROPEN ; Jump if something went wrong

	mov	bx,ax		; Copy to handle register

; Read in the tone file contents

	push	ds		; Save for a moment

	mov	ds,MAPSEG_NXT	; Get next available segment
	assume	ds:nothing	; Tell the assembler about it

	xor	dx,dx		; DS:DX ==> buffer
	mov	cx,-1		; Read in the entire file
	DOSCALL @READF2 	; Read it in, return amount in AX
	mov	di,ax		; Copy amount read in
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
	jc	near ptr FCN_TONE_ERRREAD ; Jump if something went wrong

; Close the tone file

	DOSCALL @CLOSF2 	; Close it up
;;;;;;; jc	short ???	; Ignore error return

; Parse the tone file

	mov	fs,MAPSEG_NXT	; Get next available segment
	assume	fs:nothing	; Tell the assembler about it

	xor	si,si		; FS:SI ==> buffer
	mov	fs:[di].LO,EOF	; Ensure properly terminated
FCN_TONE_NEXT:
	lods	fs:[si].LO	; Get next character
FCN_TONE_NEXT1:
	cmp	al,CR		; Izit an EOL?
	je	short FCN_TONE_SKIP ; Jump if so

	cmp	al,LF		; Izit an EOL?
	je	short FCN_TONE_SKIP ; Jump if so

	cmp	al,EOF		; Izit an EOF?
	je	near ptr FCN_TONE_OK ; Jump if so

	cmp	al,';'          ; Izit a comment?
	jne	short @F	; Jump if not
FCN_TONE_SKIP:
	dec	si		; Back off to last char

	call	SKIP_LINE	; Skip to next line at FS:SI, length CX

	jmp	short FCN_TONE_NEXT ; Go around again

@@:
	dec	si		; Back off to last char

; Check for various keywords

	call	LINE_LOWERCASE	; Convert the line at FS:SI to lowercase

	xor	bx,bx		; Initialize index into TONE_TAB
	mov	cx,TONENAM_TABLEN  ; Get # entries
	mov	dx,si		; Copy starting offset
FCN_TONE_NEXTNAME:
	mov	si,dx		; Copy starting offset
	mov	di,TONENAM_TAB[bx].TONENAM_NAME ; DGROUP:DI ==> (Count, Char[])
	mov	cl,DGROUP:[di]	; Get the count
	inc	di		; Skip over it

   repe cmps	fs:[si].LO,DGROUP:[di].LO ; Compare 'em
	jne	short @F	; Jump if not

	mov	al,fs:[si]	; Get next character from tone file

	cmp	al,' '          ; Izit valid separator?
	je	short FCN_TONE_NAME ; Jump if so

	cmp	al,TAB		; Izit valid separator?
	je	short FCN_TONE_NAME ; Jump if so

	cmp	al,'='          ; Izit valid separator?
	je	short FCN_TONE_NAME ; Jump if so
@@:
	add	bx,type TONENAM_STR ; Skip to next entry

	loop	FCN_TONE_NEXTNAME ; Jump if more entries

	jmp	FCN_TONE_ERRNAME ; Jump if unknown name


; We have a matching name.  Parse the (freq, dur, pause) values, etc.

FCN_TONE_NAME:
	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	cmp	al,'='          ; Izit valid separator?
	jne	short FCN_TONE_ERRPARSE ; Jump if not

	mov	di,TONENAM_TAB[bx].TONENAM_TABL ; DGROUP:DI ==> TONETAB_STR
	mov	DGROUP:[di].TONETAB_CNT,0 ; Initialize the count
FCN_TONE_NEXTENTRY:
	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	cmp	al,'('          ; Izit start of a (freq, dur, pause) value?
	jne	short FCN_TONE_PARSE_TAIL ; Jump if not
FCN_TONE_NEXTENTRY1:
	dec	si		; Back off to last char

	call	PARSE_FD	; Parse a (freq, dur, pause) value at FS:SI into DI
				; updating SI
	jc	short FCN_TONE_ERRPARSE ; Jump if something went wrong

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	cmp	al,'('          ; Izit leading separator?
	je	short FCN_TONE_NEXTENTRY1 ; Jump if so
FCN_TONE_PARSE_TAIL:
	cmp	al,CR		; Izit EOL?
	je	short FCN_TONE_SKIP ; Jump if so

	cmp	al,LF		; Izit EOL?
	je	short FCN_TONE_SKIP ; Jump if so

	cmp	al,EOF		; Izit EOF?
	je	short FCN_TONE_OK ; Jump if so

	cmp	al,';'          ; Izit a comment
	je	short FCN_TONE_SKIP ; Jump if so

; Check for optional repeat value

	cmp	al,','          ; Izit valid separator?
	jne	short FCN_TONE_ERRPARSE ; Jump if not

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI
	dec	si		; Back up to last char

	call	PARSE_DEC	; Parse decimal value at FS:SI
				; Returning value in AX
				; updating si
	jc	short FCN_TONE_ERRPARSE ; Jump if number too large

	mov	DGROUP:[di].TONETAB_RPT,ax ; Save as repeat value

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	jmp	FCN_TONE_NEXT1	; Go around again

FCN_TONE_OK:
	clc			; Indicate all went well

	jmp	short FCN_TONE_EXIT ; Join common exit code

FCN_TONE_ERRREAD:
	lea	di,MSG_READ	; ES:DI ==> error message
	call	DISP_UNK	; Display it along with last keyword

; Close the tone file

	DOSCALL @CLOSF2 	; Close it up
;;;;;;; jc	short ???	; Ignore error return

	jmp	short FCN_TONE_ERRCOM ; Join common error code

FCN_TONE_ERROPEN:
	lea	di,MSG_OPEN	; ES:DI ==> error message
	call	DISP_UNK	; Display it along with last keyword

	jmp	short FCN_TONE_ERRCOM ; Join common error code

FCN_TONE_ERRPARSE:
	lea	di,MSG_PARSE	; ES:DI ==> error message
	call	DISP_UNK	; Display it along with last keyword

	jmp	short FCN_TONE_ERRCOM ; Join common error code

FCN_TONE_ERRNAME:
	lea	di,MSG_NAME	; ES:DI ==> error message
	call	DISP_UNK	; Display it along with last keyword

;;;;;;; jmp	short FCN_TONE_ERRCOM ; Join common error code

FCN_TONE_ERRCOM:
	stc			; Mark as in erorr
FCN_TONE_EXIT:
	mov	si,CMDOFF	; Restore command line offeet

	REGREST <fs,di,dx,cx,bx,ax> ; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TONE endp			; End FCN_TONE procedure
endif				; IFDEF @RAMEXAM
ifdef @RAMEXAM
	NPPROC	SKIP_LINE -- Skip To Next Line
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip to the next line

On entry:

FS:SI	==>	next char

On exit:

FS:SI	==>	(updated)

|

	REGSAVE <ax>		; Save registers
@@:
	lods	fs:[si].LO	; Get next character

	cmp	al,EOF		; Izit EOF?
	je	short SKIP_LINE_END ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	short @F	; Jump if so

	cmp	al,LF		; Izit EOL?
	jne	short @B	; Jump if not
@@:

; Skip over line terminators

@@:
	lods	fs:[si].LO	; Get next character

	cmp	al,EOF		; Izit EOF?
	je	short SKIP_LINE_END ; Jump if so

	cmp	al,CR		; Izit EOL?
	je	short @B	; Jump if so

	cmp	al,LF		; Izit EOL?
	je	short @B	; Jump if so
SKIP_LINE_END:
	dec	si		; Back off to it
SKIP_LINE_EXIT:
	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_LINE endp			; End SKIP_LINE procedure
endif				; IFDEF @RAMEXAM
ifdef @RAMEXAM
	NPPROC	LINE_LOWERCASE -- Convert Line To Lowercase
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert a line to lowercase

On entry:

FS:SI	==>	line (terminated by CR, LF, or EOF)

|

	REGSAVE <ax,si> 	; Save registers
@@:
	lods	fs:[si].LO	; Get next character

	cmp	al,CR		; Izit EOL?
	je	short LINE_LOWERCASE_EXIT ; Jump if so

	cmp	al,LF		; Izit EOL?
	je	short LINE_LOWERCASE_EXIT ; Jump if so

	cmp	al,EOF		; Izit EOF?
	je	short LINE_LOWERCASE_EXIT ; Jump if so

	cmp	al,'A'          ; Izit below minimum?
	jb	short @B	; Jump if so

	cmp	al,'Z'          ; Izit above maximum?
	ja	short @B	; Jump if so

	add	al,'a' - 'A'    ; Convert to lowercase
	mov	fs:[si-1].LO,al ; Save back

	jmp	@B		; Go around again

LINE_LOWERCASE_EXIT:
	REGREST <si,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LINE_LOWERCASE	endp		; End LINE_LOWERCASE procedure
endif				; IFDEF @RAMEXAM
ifdef @RAMEXAM
	NPPROC	SKIP_WHITE_FS -- Skip over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space and return the last
character in AL.

On entry:

FS:SI	==>	command line

On exit:

FS:SI	==>	command line (updated)
AL	=	lower case last character

|

@@:
	lods	fs:[si].LO	; Get the next byte

	cmp	al,' '          ; Check for blank
	je	short @B	; Go around again

	cmp	al,TAB		; Check for TAB
	je	short @B	; Go around again

	ret			; Return to caller with next byte in AL

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE_FS endp		; End SKIP_WHITE procedure
endif				; IFDEF @RAMEXAM
ifdef @RAMEXAM
	NPPROC	PARSE_FD -- Parse (freq, dur, pause) Value
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Parse (freq, dur, pause) value

On entry:

FS:SI	==>	(freq, dur, pause) value
DGROUP:DI ==>	TONETAB_STR

On exit:

FS:SI	==>	(updated)
CF	=	0 if successful
	=	1 it not (parsing error)

|

	REGSAVE <ax,bx> 	; Save registers

	mov	bx,DGROUP:[di].TONETAB_CNT ; Get # valid values

	cmp	bx,@TONETAB_MAXLEN ; Izit at maximum?
	je	short PARSE_FD_ERR ; Jump if so

	imul	bx,size TONEFD_STR ; Times size of one struc entry
	lea	bx,[di+bx].TONETAB_FD ; Add to get offset of next entry

; Skip over leading marker

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	cmp	al,'('          ; Izit start of a (freq, dur, pause) value?
	jne	short PARSE_FD_ERR ; Jump if not

; Parse frequency

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI
	dec	si		; Back up to last char

	call	PARSE_DEC	; Parse decimal value at FS:SI
				; Returning value in AX
				; updating si
	jc	short PARSE_FD_ERR ; Jump if number too large

	mov	DGROUP:[bx].TONEFD_FRQ,ax ; Save in struc

; Skip over separator

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	cmp	al,','          ; Izit valid separator?
	jne	short PARSE_FD_ERR ; Jump if not

; Parse duration

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI
	dec	si		; Back up to last char

	call	PARSE_DEC	; Parse decimal value at FS:SI
				; Returning value in AX
				; updating si
	jc	short PARSE_FD_ERR ; Jump if number too large

	mov	DGROUP:[bx].TONEFD_DUR,ax ; Save in struc

; Skip over separator

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	cmp	al,','          ; Izit valid separator?
	jne	short PARSE_FD_ERR ; Jump if not

; Parse pause

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI
	dec	si		; Back up to last char

	call	PARSE_DEC	; Parse decimal value at FS:SI
				; Returning value in AX
				; updating si
	jc	short PARSE_FD_ERR ; Jump if number too large

	mov	DGROUP:[bx].TONEFD_PAU,ax ; Save in struc

; Skip over trailing marker

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	cmp	al,')'          ; Izit valid separator?
	jne	short PARSE_FD_ERR ; Jump if not

; Count in another value

	inc	DGROUP:[di].TONETAB_CNT ; Count it in

	clc			; Mark as successful

	jmp	short PARSE_FD_EXIT ; Join common exit code

PARSE_FD_ERR:
	stc			; Mark as in error
PARSE_FD_EXIT:
	REGREST <bx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_FD endp			; End PARSE_FD procedure
endif				; IFDEF @RAMEXAM
ifdef @RAMEXAM
	NPPROC	PARSE_DEC -- Parse Decimal Value
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Parse decimal value

On entry:

FS:SI	==>	decimal value

On exit:

AX	=	decimal value
FS:SI	==>	(updated)
CF	=	0 if successful
	=	1 it not (parsing error)

|

	REGSAVE <cx,ds> 	; Save registers

	mov	ax,fs		; Copy segment
	mov	ds,ax		; Address it
	assume	ds:nothing	; Tell the assembler about it

	mov	cx,10		; Use base 10 to convert
	call	BASE2BIN	; Convert the number at DS:SI to binary in AX
				; Return with CF signifcant (too large)
	REGREST <ds,cx> 	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE_DEC endp			; End PARSE_DEC procedure
endif				; IFDEF @RAMEXAM
ifdef @RAMEXAM
ifdef @LIGHTS
	NPPROC	FCN_LIGHTS -- LIGHTS Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

LIGHTS
LIGHTS=d:\path\filename.ext

|

	REGSAVE <ax,bx,cx,dx,di,fs> ; Save registers

	or	CM2_FLAG,@CM2_LIGHTS ; Mark as LIGHTS present

; Get the default port #

	cmp	LIGHTS_PORT,0	; Izit unspecified?
	jne	short @F	; Jump if not

	mov	ax,seg BIOSDATA ; Get segment of BIOS data area
	mov	fs,ax		; Address it
	assume	fs:BIOSDATA	; Tell the assembler about it

	mov	ax,PRINTER_BASE[0] ; Get LPT1 port #
	mov	LIGHTS_PORT,ax	; Save for later use
@@:

; Check for optional filename

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,'='          ; Is filename present?
	je	short @F	; Jump if so

	cmp	al,':'          ; Is filename present?
	je	short @F	; Jump if so

	dec	si		; Back up to last character
	mov	CMDOFF,si	; Save command line offset

	jmp	FCN_LIGHTS_OK	; Join common code

@@:
	call	SKIP_WHITE	; Skip over more white space
	dec	si		; Back up to character
;;;;;;; mov	CMDOFF,si	; Save command line offset

; Copy pathname for lights file

	lea	di,QMTPATH	; Start at the beginning
	mov	cx,127		; Maximum path length (with space for 0)
@@:
	lods	ds:[si].LO	; Get next character

	cmp	al,' '          ; Izit a path terminator?
	je	short @F	; Jump if so

	cmp	al,';'          ; Izit other path terminator?
	je	short @F	; Jump if so

	cmp	al,CR		; Izit end of line?
	je	short @F	; Jump if so

	stos	QMTPATH[di]	; Save
	loop	@B		; Go around again
@@:
	dec	si		; Back up to last character
	mov	CMDOFF,si	; Save command line offset

	sub	al,al		; In case we're truncating...
	stos	QMTPATH[di]	; ...add an extra terminator

; Open the file and read in its contents

	push	ds		; Save for a moment

	mov	ax,es		; Get DGROUP segment
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

	mov	al,@OPEN_R	; Open in read-only mode
	DOSCALL @OPENF2,QMTPATH ; Open the file
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
	jc	near ptr FCN_LIGHTS_ERROPEN ; Jump if something went wrong

	mov	bx,ax		; Copy to handle register

; Read in the lights file contents

	push	ds		; Save for a moment

	mov	ds,MAPSEG_NXT	; Get next available segment
	assume	ds:nothing	; Tell the assembler about it

	xor	dx,dx		; DS:DX ==> buffer
	mov	cx,-1		; Read in the entire file
	DOSCALL @READF2 	; Read it in, return amount in AX
	mov	di,ax		; Copy amount read in
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
	jc	near ptr FCN_LIGHTS_ERRREAD ; Jump if something went wrong

; Close the lights file

	DOSCALL @CLOSF2 	; Close it up
;;;;;;; jc	short ???	; Ignore error return

; Parse the lights file

	mov	fs,MAPSEG_NXT	; Get next available segment
	assume	fs:nothing	; Tell the assembler about it

	xor	si,si		; FS:SI ==> buffer
	mov	fs:[di].LO,EOF	; Ensure properly terminated
FCN_LIGHTS_NEXT:
	lods	fs:[si].LO	; Get next character
FCN_LIGHTS_NEXT1:
	cmp	al,CR		; Izit an EOL?
	je	short FCN_LIGHTS_SKIP ; Jump if so

	cmp	al,LF		; Izit an EOL?
	je	short FCN_LIGHTS_SKIP ; Jump if so

	cmp	al,EOF		; Izit an EOF?
	je	near ptr FCN_LIGHTS_OK ; Jump if so

	cmp	al,';'          ; Izit a comment?
	jne	short @F	; Jump if not
FCN_LIGHTS_SKIP:
	dec	si		; Back off to last char

	call	SKIP_LINE	; Skip to next line at FS:SI, length CX

	jmp	short FCN_LIGHTS_NEXT ; Go around again

@@:
	dec	si		; Back off to last char

; Check for various keywords

	call	LINE_LOWERCASE	; Convert the line at FS:SI to lowercase

	xor	bx,bx		; Initialize index into LIGHTS_TAB
	mov	cx,LITENAM_TABLEN ; Get # entries
	mov	dx,si		; Copy starting offset
FCN_LIGHTS_NEXTNAME:
	mov	si,dx		; Copy starting offset
	mov	di,LITENAM_TAB[bx].TONENAM_NAME ; DGROUP:DI ==> (Count, Char[])
	mov	cl,DGROUP:[di]	; Get the count
	inc	di		; Skip over it

   repe cmps	fs:[si].LO,DGROUP:[di].LO ; Compare 'em
	jne	short @F	; Jump if not

	mov	al,fs:[si]	; Get next character from lights file

	cmp	al,' '          ; Izit valid separator?
	je	short FCN_LIGHTS_NAME ; Jump if so

	cmp	al,TAB		; Izit valid separator?
	je	short FCN_LIGHTS_NAME ; Jump if so

	cmp	al,'='          ; Izit valid separator?
	je	short FCN_LIGHTS_NAME ; Jump if so
@@:
	add	bx,type TONENAM_STR ; Skip to next entry

	loop	FCN_LIGHTS_NEXTNAME ; Jump if more entries

	jmp	FCN_LIGHTS_ERRNAME ; Jump if unknown name


; We have a matching name.  Parse the (freq, dur, pause) values, etc.

FCN_LIGHTS_NAME:
	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	cmp	al,'='          ; Izit valid separator?
	jne	near ptr FCN_LIGHTS_ERRPARSE ; Jump if not

; Check for port name/number

	cmp	bx,LITENAM_TABPORT ; Izit port?
	jne	short @F	; Jump if not

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI
	dec	si		; Back off to last char

	cmp	fs:[si].EDD,'1tpl' ; Izit LPT1?
	je	short FCN_LIGHTS_LPT1 ; Jump if so

	cmp	fs:[si].EDD,'2tpl' ; Izit LPT2?
	je	short FCN_LIGHTS_LPT2 ; Jump if so

	jmp	FCN_LIGHTS_ERRPARSE ; Join common error code

@@:
	mov	di,LITENAM_TAB[bx].TONENAM_TABL ; DGROUP:DI ==> LIGHTSTAB_STR
	mov	DGROUP:[di].TONETAB_CNT,0 ; Initialize the count
FCN_LIGHTS_NEXTENTRY:
	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	cmp	al,'('          ; Izit start of a (freq, dur, pause) value?
	jne	short FCN_LIGHTS_PARSE_TAIL ; Jump if not
FCN_LIGHTS_NEXTENTRY1:
	dec	si		; Back off to last char

	call	PARSE_FD	; Parse a (freq, dur, pause) value at FS:SI into DI
				; updating SI
	jc	near ptr FCN_LIGHTS_ERRPARSE ; Jump if something went wrong

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	cmp	al,'('          ; Izit leading separator?
	je	short FCN_LIGHTS_NEXTENTRY1 ; Jump if so
FCN_LIGHTS_PARSE_TAIL:
	cmp	al,CR		; Izit EOL?
	je	near ptr FCN_LIGHTS_SKIP ; Jump if so

	cmp	al,LF		; Izit EOL?
	je	near ptr FCN_LIGHTS_SKIP ; Jump if so

	cmp	al,';'          ; Izit a comment?
	je	near ptr FCN_LIGHTS_SKIP ; Jump if so

	cmp	al,EOF		; Izit EOF?
	je	short FCN_LIGHTS_OK ; Jump if so

; Check for optional repeat value

	cmp	al,','          ; Izit valid separator?
	jne	short FCN_LIGHTS_ERRPARSE ; Jump if not

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI
	dec	si		; Back up to last char

	call	PARSE_DEC	; Parse decimal value at FS:SI
				; Returning value in AX
				; updating si
	jc	short FCN_LIGHTS_ERRPARSE ; Jump if number too large

	mov	DGROUP:[di].TONETAB_RPT,ax ; Save as repeat value

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	jmp	FCN_LIGHTS_NEXT1 ; Go around again


; Set LPT1/LPT2 as lights port #

FCN_LIGHTS_LPT1:
	push	fs		; Save for a moment

	mov	ax,seg BIOSDATA ; Get segment of BIOS data area
	mov	fs,ax		; Address it
	assume	fs:BIOSDATA	; Tell the assembler about it

	mov	ax,PRINTER_BASE[0] ; Get LPT1 port #
	mov	LIGHTS_PORT,ax	; Save for later use

	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	add	si,4		; Skip over 'LPT1'

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	jmp	FCN_LIGHTS_NEXT1 ; Go around again

FCN_LIGHTS_LPT2:
	push	fs		; Save for a moment

	mov	ax,seg BIOSDATA ; Get segment of BIOS data area
	mov	fs,ax		; Address it
	assume	fs:BIOSDATA	; Tell the assembler about it

	mov	ax,PRINTER_BASE[2] ; Get LPT2 port #
	mov	LIGHTS_PORT,ax	; Save for later use

	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	add	si,4		; Skip over 'LPT1'

	call	SKIP_WHITE_FS	; Skip over more white space at FS:SI

	jmp	FCN_LIGHTS_NEXT1 ; Go around again


FCN_LIGHTS_OK:
	clc			; Indicate all went well

	jmp	short FCN_LIGHTS_EXIT ; Join common exit code

FCN_LIGHTS_ERRREAD:
	lea	di,MSG_READ	; ES:DI ==> error message
	call	DISP_UNK	; Display it along with last keyword

; Close the lights file

	DOSCALL @CLOSF2 	; Close it up
;;;;;;; jc	short ???	; Ignore error return

	jmp	short FCN_LIGHTS_ERRCOM ; Join common error code

FCN_LIGHTS_ERROPEN:
	lea	di,MSG_OPEN	; ES:DI ==> error message
	call	DISP_UNK	; Display it along with last keyword

	jmp	short FCN_LIGHTS_ERRCOM ; Join common error code

FCN_LIGHTS_ERRPARSE:
	lea	di,MSG_PARSE	; ES:DI ==> error message
	call	DISP_UNK	; Display it along with last keyword

	jmp	short FCN_LIGHTS_ERRCOM ; Join common error code

FCN_LIGHTS_ERRNAME:
	lea	di,MSG_NAME	; ES:DI ==> error message
	call	DISP_UNK	; Display it along with last keyword

;;;;;;; jmp	short FCN_LIGHTS_ERRCOM ; Join common error code

FCN_LIGHTS_ERRCOM:
	stc			; Mark as in erorr
FCN_LIGHTS_EXIT:
	mov	si,CMDOFF	; Restore command line offeet

	REGREST <fs,di,dx,cx,bx,ax> ; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LIGHTS endp 		; End FCN_LIGHTS procedure
endif ; ifdef @LIGHTS
endif				; IFDEF @RAMEXAM
ifdef @BETA
	 NPPROC  FCN_DBGFAULT -- DEBUG=FAULT Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_FLT ; Mark as debugging start of faults

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGFAULT endp		; End FCN_DBGFAULT procedure
endif				; IFDEF @BETA
ifdef @BETA
	 NPPROC  FCN_DBGTIME -- DEBUG=TIME Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_TIM ; Mark as debugging memory timing

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGTIME endp		; End FCN_DBGTIME procedure
endif				; IFDEF @BETA
	 NPPROC  FCN_K -- K Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 and	 CMD_FLAG,not @CMD_EPM ; Mark as using the BIOS's EPM routine

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_K	 endp			; End FCN_K procedure
	 NPPROC  FCN_VLSI -- VLSI Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

	 or	 GL3_FLAG,@GL3_VLSI ; Mark as VLSI 82C480 L2 cache controller present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_VLSI endp			; End FCN_VLSI procedure

CODE	ends			; End CODE segment

	MEND			; End MEM_FCN module

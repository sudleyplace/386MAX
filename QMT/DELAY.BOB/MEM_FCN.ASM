;' $Header:   P:/PVCS/MAX/QMT/MEM_FCN.ASV   1.1   05 Jun 1998 14:03:24   BOB  $
	 title	 MEM_FCN -- MEMCHK Command Function Routines
	 page	 58,122
	 name	 MEM_FCN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.

Segmentation:  See MEM_SEG.INC for details.

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

	 include MEM_BLK.INC
	 include MEM_OEM.INC
	include MEM_SEG.INC
.list

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 BASIND:word

	 extrn	 CMD_FLAG:word
	 include MEM_CMD.INC

	 extrn	 CNT_FLAG:word
	 include MEM_CNT.INC
ifdef @BETA
	 extrn	 DBG_FLAG:word
	 include MEM_DBG.INC
endif				; IFDEF @BETA
	 extrn	 GL2_FLAG:word
	 include MEM_GL2.INC

	 extrn	 GL3_FLAG:word
	 include MEM_GL3.INC

	 extrn	 ASKBLK:word

	 extrn	 ITEMCNT:word
	 extrn	 @ASKITEM_LEN:abs

	 extrn	 ACMDIND:word
	 extrn	 ASKCMDBTN:byte

	 extrn	 QMTLOGPATH:byte

	extrn	DELAYNUM:word

DATA	 ends			; End DATA segment


NDATA	 segment use16 dword public 'data' ; Start NDATA segment
	 assume  ds:DGROUP

	 extrn	 MSG_SEP:byte
	 extrn	 MSG_VAL:byte
	 extrn	 MSG_OVF:byte
	 extrn	 MSG_CMDS:byte
	 extrn	 MSG_PAK:byte
	 extrn	 MSG_CRLF:byte

ifdef @RAMEXAM

	 extrn	 QMTDAT:dword
	 extrn	 QMTDAT_W:dword
	 extrn	 QMTDAT_M:dword
	 extrn	 TODAY:dword
	 extrn	 NEXTSCHED:dword

	 extrn	 ASK_DEFAULT:byte
	 extrn	 ASK_TIMEOUT:word

endif ; @RAMEXAM

	 public  TMPIND
TMPIND	 dw	 ?		; Temporary index for item count functions

	 public  MOLEN_TAB
MOLEN_TAB label byte		; Normal, leap year values for:
	 db	 31,31		; January
	 db	 28,29		; February
	 db	 31,31		; March
	 db	 30,30		; April
	 db	 31,31		; May
	 db	 30,30		; June
	 db	 31,31		; July
	 db	 31,31		; August
	 db	 30,30		; September
	 db	 31,31		; October
	 db	 30,30		; November
	 db	 31,31		; December

NDATA	 ends			; End NDATA segment


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
	NPPROC	FCN_DELAY -- DELAY Function
	assume	ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DELAY=n

where n is an integer specifying the amount in seconds
to delay between runs.

|

	REGSAVE <ax,cx,di>	; Save

	call	SKIP_WHITE	; Skip over more white space

	cmp	al,'='          ; Must be
	je	short @F	; Jump if OK

	cmp	al,':'          ; Must be
	jne	short FCN_DELAY_EQ ; Join common code
@@:
	call	SKIP_WHITE	; Skip over more white space

	dec	si		; Back up to character

	cmp	al,CR		; Izit an end-of-line character?
	je	short FCN_DELAY_VAL ; Jump if so (missing value)

	mov	cx,10		; Use base 10 to convert
	call	BASE2BIN	; Convert the number at DS:SI to binary in AX
	jc	short FCN_DELAY_OVF ; Jump if too large

	mov	DELAYNUM,ax	; Save for later use

	jmp	short FCN_DELAY_EXIT ; Join common exit

FCN_DELAY_VAL:
	lea	di,MSG_VAL	; ES:DI ==> error message
	jmp	short FCN_DELAY_ERRMSG ; Join common error display code

FCN_DELAY_EQ:
	dec	si		; Back up to character

	lea	di,MSG_SEP	; ES:DI ==> error message
	jmp	short FCN_DELAY_ERRMSG ; Join common error display code

FCN_DELAY_OVF:
	lea	di,MSG_OVF	; ES:DI ==> error message
FCN_DELAY_ERRMSG:
	call	DISP_UNK	; Display it along with last keyword

	stc			; Indicate something went wrong
FCN_DELAY_EXIT:
	REGREST <di,cx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DELAY endp			; End FCN_DELAY procedure
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
	 NPPROC  FCN_LOG -- LOG Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

LOG[=filename][,o]

where the default filename is d:\path\QMTLOG.TXT.  If ,o is specified,
the log file will be deleted first; otherwise, we append to it.

|

	 REGSAVE <ax,cx,di>	; Save

	 cld			; Set forward direction for string ops

	 or	 CMD_FLAG,@CMD_LOG ; Write to log file

	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 je	 short @F	; Jump if OK

	 cmp	 al,':'         ; Must be
	 jne	 short FCN_LOG_DEFAULT ; Construct default filename

@@:
	 call	 SKIP_WHITE	; Skip over more white space

	 cmp	 al,','         ; Izit LOG=,o ?
	 je	 short FCN_LOG_DEFAULT ; Use default if so

	 call	 IZITSEP	; Izit LOG= ?
	 je	 short FCN_LOG_VAL ; Bitch about missing value if so

	 dec	 si		; Back up to character

; Copy pathname for log file

	 lea	 di,QMTLOGPATH	; Start at the beginning
	 mov	 cx,127 	; Maximum path length (with space for 0)
@@:
	 lods	 ds:[si].LO	; Get next character

	 cmp	 al,' '         ; Izit a path terminator?
	 je	 short @F	; Jump if so

	 cmp	 al,';'         ; Izit other path terminator?
	 je	 short @F	; Jump if so

	 cmp	 al,','         ; Izit other path terminator?
	 je	 short @F	; Jump if so

	 cmp	 al,'='         ; Izit other path terminator?
	 je	 short @F	; Jump if so

	 cmp	 al,CR		; Izit end of line?
	 je	 short @F	; Jump if so

S16	 stos	 QMTLOGPATH[di] ; Save
	 loop	 @B		; Go around again

@@:
	 sub	 al,al		; In case we're truncating...
S16	 stos	 QMTLOGPATH[di] ; ...add an extra terminator

	 jmp	 short FCN_LOG_COMMA ; Check for ,o

FCN_LOG_DEFAULT:
	 call	 DEFAULT_LOG	; Set up default QMTLOGPATH
FCN_LOG_COMMA:
; DS:SI ==> next character + 1.  First check for a comma.
	 dec	 si		; Back off to next character

	 mov	 al,ds:[si].LO	; Get in AL
	 cmp	 al,','         ; Izit comma?
	 jne	 short FCN_LOG_CLC ; Jump if not

@@:
	 inc	 si		; Skip over the comma
	 call	 SKIP_WHITE	; Skip whitespace
	 call	 UPPERCASE	; Convert AL to uppercase

	 dec	 si		; Back off to character

	 cmp	 al,@NATL_OVERWRITE ; Izit 'o'?
	 jne	 short FCN_LOG_VAL ; Jump if not (only option allowed)

	 inc	 si		; Skip 'o'

	 or	 CMD_FLAG,@CMD_LOGDEL ; Overwrite log file

FCN_LOG_CLC:
	 clc			; Mark as success

	 jmp	 short FCN_LOG_EXIT ; Join common exit

FCN_LOG_VAL:
	 lea	 di,MSG_VAL	; ES:DI ==> error message
	 call	 DISP_UNK	; Display it along with last keyword

	 stc			; Indicate something went wrong
FCN_LOG_EXIT:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LOG  endp			; End FCN_LOG procedure
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
	 NPPROC  CHECK_82C302 -- Check on 82C302
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Attempt to determine whether or not this system supports the 82C302
by writing to I/O port 21h and checking to see if the same value
appears at I/O port 23h.

On exit:

CF	 =	 0 82C302 appears to be present
	 =	 1 isn't

|

	 REGSAVE <ax,bx>	; Save registers

; Register usage:
;
; AL	 =	 scratch
; BL	 =	 original value from I/O port 21h
; BH	 =	 original value from I/O port 23h
; AH	 =	 second   value from I/O port 23h

	 in	 al,21h 	; Get and save the I/O port
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 mov	 bl,al		; Save to restore later

	 in	 al,23h 	; Get the I/O port
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 not	 al		; Complement the value so it's different
	 mov	 bh,al		; Save to compare

	 out	 21h,al 	; Change the IMR
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,23h 	; Get and save the I/O port
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 mov	 ah,al		; Save to compare

	 mov	 al,bl		; Get original value of IMR

	 out	 21h,al 	; Restore it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 cmp	 ah,bh		; Compare original and second values
	 je	 short CHECK_82C302_ERR ; Jump if same (thus same I/O ports)

	 clc			; Assume it's present

	 jmp	 short CHECK_82C302_EXIT ; Join common exit code

CHECK_82C302_ERR:
	 stc			; Indicate not supported
CHECK_82C302_EXIT:
	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_82C302 endp		; End CHECK_82C302 procedure
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
	 NPPROC  FCN_LNKIDM -- LNKIDM Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

LNKIDM=nn

|

	 mov	 TMPIND,@ASK_LNKIDM*(type ITEMCNT) ; Save ITEMCNT index

	 jmp	 short FCN_CNTCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LNKIDM endp 		; End FCN_LNKIDM procedure
	 NPPROC  FCN_LNKINV -- LNKINV Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

LNKINV=nn

|

	 mov	 TMPIND,@ASK_LNKINV*(type ITEMCNT) ; Save ITEMCNT index

	 jmp	 short FCN_CNTCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LNKINV endp 		; End FCN_LNKINV procedure
	 NPPROC  FCN_UNLIDM -- UNLIDM Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

UNLIDM=nn

|

	 mov	 TMPIND,@ASK_UNLIDM*(type ITEMCNT) ; Save ITEMCNT index

	 jmp	 short FCN_CNTCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_UNLIDM endp 		; End FCN_UNLIDM procedure
	 NPPROC  FCN_UNLINV -- UNLINV Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

UNLINV=nn

|

	 mov	 TMPIND,@ASK_UNLINV*(type ITEMCNT) ; Save ITEMCNT index

	 jmp	 short FCN_CNTCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_UNLINV endp 		; End FCN_UNLINV procedure
	 NPPROC  FCN_UNLSAF -- UNLSAF Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

UNLSAF=nn

|

	 mov	 TMPIND,@ASK_UNLSAF*(type ITEMCNT) ; Save ITEMCNT index

	 jmp	 short FCN_CNTCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_UNLSAF endp 		; End FCN_UNLSAF procedure
	 NPPROC  FCN_UNLTRN -- UNLTRN Function
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

UNLTRN=nn

|

	 mov	 TMPIND,@ASK_UNLTRN*(type ITEMCNT) ; Save ITEMCNT index

	 jmp	 short FCN_CNTCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_UNLTRN endp 		; End FCN_UNLTRN procedure
	 NPPROC  FCN_CNTCOM -- Common Subroutine For Item Counts
	 assume  ds:nothing,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
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
	 mov	 di,TMPIND	; Get ITEMCNT index
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

CODE	 ends			; End CODE segment

	 MEND			; End MEM_CMD module

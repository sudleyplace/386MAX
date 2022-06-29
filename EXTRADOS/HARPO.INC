;'$Header:   P:/PVCS/MAX/EXTRADOS/HARPO.INV   1.0   05 Sep 1995 15:13:14   HENRY  $

;
; Include file for HARPO - the DOS Memory Reorganizer
;

	 include HARP_LCL.INC	; Include Local Flag   defenitions
	 include HARP_CMD.INC	; Include Commadn Flag defenitions

;***************************************************************************

; Conditional equates

@STATISTICS	equ	0	; Compile with statisitcal debugging output
@MAX6		equ	0	; Compile for Bank of America

if @STATISTICS
	 echo	 STATISTICS  = active
else
	 echo	 STATISTICS  = inactive
endif			; if @STATISTICS

if @MAX6
	 echo	 MAX6	     = active	 (for BOA)
else
	 echo	 MAX6	     = inactive  (not for BOA)
endif			; if @MAX6


if @MAX6
@MAX7		 equ	0	; If MAX6, then not (MAX7)
else
@MAX7		 equ	1	; IF not (MAX6), then MAX7
endif				; IF @MAX6

if @MAX6
	 @ALLOC_METHOD equ @XMS_GETUMB
else
	 @ALLOC_METHOD equ @XMS_GET2UMB
endif			; if @MAX6

;***************************************************************************

; MASM 6.0 options

OPTION OFFSET:GROUP		; Have offsetts be GROUP relative
OPTION OLDMACROS		; Use old macro style
OPTION SEGMENT:USE16		; Verify USE16 Rules


;***************************************************************************

;--------------- MASM 6.0 Handy Equates -------------------

VVOFF	 TEXTEQU	<VECTOR.VOFF>	; A handy MASM 6.0 equate
VVSEG	 TEXTEQU	<VECTOR.VSEG>	; ...

BPTR	 TEXTEQU	<byte ptr>	; More handy MASM 6.0 equates
WPTR	 TEXTEQU	<word ptr>	; ...
DWPTR	 TEXTEQU	<dword ptr>	;...


;--------------- Handy Macros -------------------------

SWATTER  macro
LOCAL	 NO_DEBUG			; Local symbol
	 test	 LCL_FLAG,@LCL_DEBUG	; Is debugging enabled?
	 jz	 short NO_DEBUG 	; Jump if not

	 int	 01h			; Call SWAT (if requested)
NO_DEBUG:
endm

;------------ INFO READ/WRITE equates ------------------------

@CTL_OFFSET  equ 10h		; IOCTL type byte offset
@INFO_OFFSET equ 11h		; Info structure buffer offset


;***************************************************************************

HNCODE	 segment

EXTERNDEF LCL_FLAG:word 	; Local   Flags
EXTERNDEF CMD_FLAG:word 	; Command Flags

TOKEN_STR struc
  VALUE   db	 ?	; Token value (F,X,B,L,S)
  NPAR	  dw	 ?	; Number of paras requested (by MAXIMIZE)
  REG	  db	 ?	; Region requested (by MAXIMIZE)
  MESSAGE dw	 ?	; Address of name for error message (eg. 'FILES=')
  MACNAME dw	 ?	; Address of MAC entry name (eg. '>FILES ')
TOKEN_STR ends

EXTERNDEF TOKEN_LIST:TOKEN_STR	; List of tokens that we may act upon
EXTERNDEF @TOKEN_CNT:abs	; Number of Tokens we analyze


;----------- DeadMan equates ----------------------------------

; Note: These three DeadMan strings *MUST* be the same length !!!

@DEAD_DEV    TEXTEQU <'NOLOADHI=D'>     ; DEVICE=  DeadMan profile option
@DEAD_INS    TEXTEQU <'NOLOADHI=I'>     ; INSTALL= DeadMan profile option
@DEAD_OFLOW  TEXTEQU <'OVERFLOW  '>     ; Subseg Overflow  profile option

@DEAD_TMP SIZESTR @DEAD_DEV	; Length of above string
@DEAD_LEN equ (@DEAD_TMP-2)	; ... minus the quotes

HNCODE	 ends


;***************************************************************************

@HNAME	 TEXTEQU <'ExtraDOS'>
@DEVNAME TEXTEQU <'EXTRADOS'>   ; Device name for HARPO

; Note: because of a parsing bug in MASM 6, there is hard coded constant of
; 30 (which is 10*3) in LOCAL_ALLOC.  This constant is used to determine
; when the GETSIZE table is full, so we don't overwrite other data.

@SUBSEG_GETSIZE_CNT equ 10	; 10 GETSIZE entries
@SUBSEG_STRLEN	    equ  3	; 3 bytes per GETSIZE entry

SUBSEG		 struc
  STYPE  db	 0		; Sub-segmeny type (F,B,X,L,S)
  SLEN	 dw	 ?		; Sub-segment length (in paras)
SUBSEG		 ends

HINFO_STR	 struc
  RESULT db	 ?			      ; Testing result: 0=No, 1=Yes
	 SUBSEG  @SUBSEG_GETSIZE_CNT dup (<>) ; Individual sub-segment entries
	 db	 0			      ; End of structure marker
HINFO_STR	 ends


;***************************************************************************

; Stack frame used in our sub-segment and command_com patches

STACK_F  struc
	   dw	 ?	; Caller's BP
    RET_IP dw	 ?	; Caller's return IP (from far call)
	   dw	 ?	; Caller's return CS (from far call)
STACK_F  ends

;***************************************************************************






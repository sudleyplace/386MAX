;' $Header:   P:/PVCS/MISC/VCPITEST/VCP_ARGS.ASV   1.1   22 Feb 1994 12:19:28   HENRY  $

	 title	 VCP_ARGS -- VCPI Argument Checking Routines
	 page	 58,122
	 name	 VCP_ARGS
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1989-94 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'

Link requirements:  None, standalone subroutine.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC
.list


CMDARG_MAC macro TXT,ACT
	 local	 LCL_TXT,LCL_LEN

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  cs:PGROUP

LCL_TXT  db	 TXT
LCL_LEN  equ	 $-LCL_TXT

DATA	 ends			; End DATA segment


SEG_LEN  segment use16 word public 'data' ; Start SEG_LEN segment
	 assume  cs:PGROUP

	 dw	 LCL_LEN

SEG_LEN  ends			; End SEG_LEN segment


SEG_TAB  segment use16 word public 'data' ; Start SEG_TAB segment
	 assume  cs:PGROUP

	 dw	 PGROUP:LCL_TXT

SEG_TAB  ends			; End SEG_TAB segment


SEG_ACT  segment use16 word public 'data' ; Start SEG_ACT segment
	 assume  cs:PGROUP

	 dw	 PGROUP:ACT

SEG_ACT  ends			; End SEG_ACT segment

	 endm			; CMDARG_MAC


PGROUP	 group	 CODE,DATA,SEG_LEN,SEG_TAB,SEG_ACT


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 public  CMD_FLAG
	 include VCP_FLAG.INC
CMD_FLAG dw	 0

	 public  MSG_UNK
MSG_UNK  db	 BEL,'ออ> Unknown keyword.',CR,LF,EOS

DATA	 ends			; End DATA segment


SEG_TAB  segment use16 word public 'data' ; Start SEG_TAB segment
	 assume  cs:PGROUP

	 public  CMDARG_TAB
CMDARG_TAB label word

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use16 word public 'data' ; Start SEG_LEN segment
	 assume  cs:PGROUP

	 public  CMDARG_LEN
CMDARG_LEN label word

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use16 word public 'data' ; Start SEG_ACT segment
	 assume  cs:PGROUP

	 public  CMDARG_ACT
CMDARG_ACT label word

SEG_ACT  ends			; End SEG_ACT segment


; All keywords in this table *MUST* be in uppercase

	 CMDARG_MAC 'NOXLA',    FCN_NOXLA



SEG_TAB  segment use16 word public 'data' ; Start SEG_TAB segment
	 assume  cs:PGROUP

	 public  NCMDARGS
NCMDARGS equ	 ($-CMDARG_TAB)/(type CMDARG_TAB) ; Its length

SEG_TAB  ends			; End SEG_TAB segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 DISPERR:near

	 extrn	 PSP_PARM_STRING:byte

	 NPPROC  CHECK_ARGS -- Check for Arguments
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

Check for arguments

|

	 pusha			; Save all GP registers

	 lea	 si,PSP_PARM_STRING ; DS:SI ==> command line

	 call	 STR_UPPER	; Convert the string to upper case
CHECK_ARGS_SRCH:		; Search for arguments
	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,CR		; Check for terminator
	 je	 short CHECK_ARGS_CLC ; That's all folks

	 cmp	 al,';'         ; Check for terminator
	 je	 short CHECK_ARGS_CLC ; That's all folks

; Search for the argument text

	 xor	 bx,bx		; Zero index register
	 mov	 cx,NCMDARGS	; # arguments to check
CHECK_ARGS_NEXT:
	 mov	 di,CMDARG_TAB[bx] ; Get location of text

	 REGSAVE <cx,si>	; Save for a moment
	 mov	 cx,CMDARG_LEN[bx] ; Get length
    repe cmpsb			; Compare 'em
	 REGREST <si,cx>	; Restore
	 jne	 short CHECK_ARGS_NEXT1 ; Not this one

; Mark as found only if the next character is a valid separator

	 mov	 di,CMDARG_LEN[bx] ; Get length of matching command
	 add	 di,si		; Add into starting offset
	 mov	 al,ds:[di]	; Get the next character

	 cmp	 al,'='         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; Jump if valid

	 cmp	 al,';'         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; Jump if valid

	 cmp	 al,' '         ; Check for blank or below
	 jbe	 short CHECK_ARGS_FOUND ; A match
CHECK_ARGS_NEXT1:
	 add	 bx,type CMDARG_TAB ; Skip to next entry

	 loop	 CHECK_ARGS_NEXT ; Jump if more entries to check

; Keyword not found

	 lea	 dx,MSG_UNK	; Tell 'em the bad news
	 call	 DISPERR	; Display error message at DS:DX

	 stc			; Indicate an error occurred

	 jmp	 CHECK_ARGS_EXIT ; Join common exit code


CHECK_ARGS_FOUND:
	 add	 si,CMDARG_LEN[bx] ; Skip over the keyword

	 call	 CMDARG_ACT[bx] ; Take appropriate action
	 jc	 short CHECK_ARGS_ERR ; Join common error code

	 jmp	 CHECK_ARGS_SRCH ; Join common tail code

CHECK_ARGS_CLC:
	 clc			; Indicate all went well

	 jmp	 short CHECK_ARGS_EXIT ; Join common exit code

CHECK_ARGS_ERR:
	 stc			; Indicate something went wrong
CHECK_ARGS_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	 NPPROC  FCN_NOXLA -- NOXLA Function
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

NOXLA function

|

	 or	 CMD_FLAG,@CMD_NOXLA ; Mark as skipping invalid linear address check

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

FCN_NOXLA endp			; End FCN_NOXLA procedure
	 NPPROC  SKIP_WHITE -- Skip Over White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Skip over white space

On entry:

DS:SI	 ==>	 command line

On exit:

AL	 =	 non-white space character
DS:SI	 ==>	 (updated)

|

@@:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 short @B	; Yes, go around again

	 cmp	 al,TAB 	; Izit white space?
	 je	 short @B	; Yes, go around again

	 dec	 si		; Back off to previous character

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	 NPPROC  STR_UPPER -- Copnvert String to Uppercase
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

Convert CR-terminated string at DS:SI to uppercase

|

	 REGSAVE <ax,si>	; Save registers
STR_UPPER_NEXT:
	 lodsb			; Get next character

	 cmp	 al,CR		; Check for end-of-the-line
	 je	 short STR_UPPER_EXIT ; Good guess

	 cmp	 al,'a'         ; Check against lower limit
	 jb	 short STR_UPPER_NEXT ; Jump if too small

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short STR_UPPER_NEXT ; Jump if too large

	 add	 al,'A'-'a'     ; Convert to uppercase

	 mov	 ds:[si-1],al	; Save back in text

	 jmp	 short STR_UPPER_NEXT ; Go around again

STR_UPPER_EXIT:
	 REGREST <si,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

STR_UPPER endp			; End STR_UPPER procedure

CODE	 ends			; End CODE segment

	 MEND			; End VCP_ARGS module

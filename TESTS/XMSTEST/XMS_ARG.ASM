;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_ARG.ASV   1.1   06 Aug 1992 13:18:10   HENRY  $

	 title	 XMS_ARG -- XMS Argument Checker
	 page	 58,122
	 name	 XMS_ARG
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-92 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, July, 1988.

Modifications by:  None.

|

.286c
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
.list

PGROUP	 group	 CODE,DATA


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 public  CMD_FLAG
	 include XMS_CMD.INC
CMD_FLAG db	 0		; Command flags

	 public  CMDCHARS
CMDCHARS db	 'ahxmurle'     ; Valid command letters
CMDCHARS_LEN equ $-CMDCHARS	; Length of ...

	 public  CMDFLAGS
CMDFLAGS db	 @CMD_A20	; Corresponding flags
	 db	 @CMD_HMA
	 db	 @CMD_XMB
	 db	 @CMD_MOV
	 db	 @CMD_UMB
	 db	 @CMD_MOD
	 db	 @CMD_LCK
	 db	 @CMD_EDG

	 public  MSG_CMDERR
MSG_CMDERR db	 BEL,'ออ> Command line error -- valid commands are',CR,LF
	 db	     '   /A   test A20',CR,LF
	 db	     '   /H   test HMA',CR,LF
	 db	     '   /X   test XMBs',CR,LF
	 db	     '   /M   test XMB moves',CR,LF
	 db	     '   /U   test UMBs',CR,LF
	 db	     '   /R   test XMB reallocation',CR,LF
	 db	     '   /L   test XMB locking',CR,LF
	 db	     '   /E   test edge conditions',CR,LF
	 db	 EOS

DATA	 ends			; End DATA segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 DISPERR:near

	 extrn	 PSP_PARM_STRING:byte

	 NPPROC  CHECK_ARGS -- Check Arguments
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check command line arguments

|

	 pusha			; Save all GP registers

	 lea	 si,PSP_PARM_STRING ; DS:SI ==> command line
CHECK_ARGS_NEXT:
	 call	 SKIPWHITE	; Skip over white space

	 lodsb			; Get next character

	 cmp	 al,CR		; Izit EOL?
	 je	 short CHECK_ARGS_DONE ; Jump if so

	 cmp	 al,'/'         ; Izit a switch char?
	 jne	 short CHECK_ARGS_ERR ; Jump if not

	 lodsb			; Get next character

	 call	 LOWERCASE	; Convert AL to lowercase

	 lea	 di,CMDCHARS	; ES:DI ==> valid command letters
	 mov	 cx,CMDCHARS_LEN ; CX = length of ...
   repne scasb			; Search for it
	 jne	 short CHECK_ARGS_ERR ; Jump if not found

	 sub	 di,1+offset ds:CMDCHARS ; Convert to origin-0
	 mov	 al,CMDFLAGS[di] ; Get the corresponding flag
	 or	 CMD_FLAG,al	; Include in the list

	 jmp	 short CHECK_ARGS_NEXT ; Go around again

CHECK_ARGS_DONE:
	 cmp	 CMD_FLAG,0	; Any options selected?
	 jne	 short @F	; Jump if so

	 mov	 CMD_FLAG,@CMD_ALL ; Mark as all options
@@:
	 clc			; Indicate all went well

	 jmp	 short CHECK_ARGS_EXIT ; Join common exit code

CHECK_ARGS_ERR:
	 lea	 dx,MSG_CMDERR	; Tell 'em to type better
	 call	 DISPERR	; Display error message at DS:DX

	 stc			; Indicate something went wrong
CHECK_ARGS_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	 NPPROC  SKIPWHITE -- Skip Over White Space
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

On entry:

DS:SI	 ==>	 next command character

On exit:

DS:SI	 ==>	 (updated)

|

	 push	 ax		; Save for a moment
@@:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 short @B	; Jump if so

	 cmp	 al,TAB 	; Izit white space?
	 je	 short @B	; Jump if so

	 dec	 si		; Back off to non-white space character

	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SKIPWHITE endp			; End SKIPWHITE procedure
	 NPPROC  LOWERCASE -- Convert to Lowercase
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

On entry:

AL	 =	 character to convert

On exit:

AL	 =	 lowercase converted character

|

	 cmp	 al,'A'         ; Check against lower limit
	 jb	 short @F	; Jump if too small

	 cmp	 al,'Z'         ; Check against upper limit
	 ja	 short @F	; Jump if too large

	 add	 al,'a'-'A'     ; Convert to lowercase
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure

CODE	 ends			; End CODE segment

	 MEND			; End XMS_ARG module

;' $Header:   P:/PVCS/MAX/386LOAD/TSRLOAD.ASV   1.1   30 May 1997 10:38:14   BOB  $
	 title	 TSRLOAD -- 386MAX TSR Loader For AUTOEXEC.BAT
	 page	 58,122
	 name	 TSRLOAD

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Stack   segment STACK,	byte-aligned,  stack,  class 'prog'
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment DATA,	dword-aligned, public, class 'data'
	       Program segment DATZ,	para-aligned,  public, class 'data'
	       Program segment CODZ,	byte-aligned,  public, class 'ncode'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NLSEG,	para-aligned,  public, class 'ndata'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment DTAIL,	para-aligned,  public, class 'zdata'
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'
	       Program segment SEG_LEN, word-aligned,  public, class 'zdata'
	       Program segment SEG_TAB, word-aligned,  public, class 'zdata'
	       Program segment SEG_ACT, word-aligned,  public, class 'zdata'
	       Program segment SEG_TXT, byte-aligned,  public, class 'zdata'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Data    segment UDATA,	dword-aligned, public, class 'udata'
	       Data    segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Link requirements:  Final routine should have extension .SYS.
		    Link with VERSION.OBJ.

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOS.INC
	 include CPUFLAGS.INC
.list

PGROUP	 group	 STACK,CODE,DATA,DATZ,CODZ,NCODE,NDATA,NLSEG,DTAIL,ACODE,ADATA,SEG_LEN,SEG_TAB,SEG_ACT,SEG_TXT,UCODE,UDATA,ZZTAIL

; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .SYS file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 word stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
DATA	 ends			; End DATA segment


DATZ	 segment use16 para public 'data' ; Start DATZ segment
	 assume  ds:PGROUP

	 extrn	 TEMPSTKZ:word

DATZ	 ends			; End DATZ segment


CODZ	 segment use16 byte public 'ncode' ; Start CODZ segment
CODZ	 ends			; End CODZ segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 TSRCOM:near
	 extrn	 DISP_COPY:near

NCODE	 ends			; End NCODE segment


NLSEG	 segment use16 para public 'ndata' ; Start NLSEG segment
NLSEG	 ends			; End NLSEG segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
NDATA	 ends			; End NDATA segment


DTAIL	 segment use16 para public 'zdata' ; Start DTAIL segment
DTAIL	 ends			; End DTAIL segment


ACODE	 segment use16 byte public 'zdata' ; Start ACODE segment
ACODE	 ends			; End ACODE segment


ADATA	 segment use16 dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP

	 extrn	 MSG_COPY:byte
	 extrn	 MSG_NOT386:byte
	 extrn	 MSG_NOT386_LEN:abs

ADATA	 ends			; End ADATA segment


SEG_LEN  segment use16 word public 'zdata' ; Start SEG_LEN segment
SEG_LEN  ends			; End SEG_LEN segment


SEG_TAB  segment use16 word public 'zdata' ; Start SEG_TAB segment
SEG_TAB  ends			; End SEG_TAB segment


SEG_ACT  segment use16 word public 'zdata' ; Start SEG_ACT segment
SEG_ACT  ends			; End SEG_ACT segment


SEG_TXT  segment use16 byte public 'zdata' ; Start SEG_TXT segment
SEG_TXT  ends			; End SEG_TXT segment


UCODE	 segment use16 byte public 'ucode' ; Start UCODE segment
UCODE	 ends			; End UCODE segment


UDATA	 segment use16 dword public 'udata' ; Start UDATA segment
UDATA	 ends			; End UDATA segment


ZZTAIL	 segment use16 dword public 'zzdata' ; Start ZZTAIL segment
ZZTAIL	 ends			; End ZZTAIL segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP
.xlist
	 public  PSP_TERMINATE,PSP_ENVIR_PTR,PSP_FCB1,PSP_FCB2,PSP_DTA,
	 public  PSP_STOR_MAX,PSP_BYTES_INSEG
	 public  PSP_FILE_TAB_SIZ,PSP_FILE_TAB_PTR
	 public  PSP_CTRL_PSP,PSP_LCL_STACK
	 include PSP.INC	; Define and skip over PSP
.list

INITIAL:
	 jmp	 TSRLOAD	; Continue with initialization code

CODE	 ends			; End CODE segment


ACODE	 segment use16 byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near

	 NPPROC  TSRLOAD -- TSR Loader
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Load TSR into high DOS memory

|

; Switch to local stack

	 lea	 sp,TEMPSTKZ	; Address new stack

;;;;	 lea	 dx,MSG_COPY	; DS:DX ==> string to display
;;;;	 call	 STROUT 	; Display string at DS:DX

	 call	 CHECK_CPUID	; Ensure we're on a 386 processor
	MJ nc	 TSRCOM 	; Jump if OK

	 mov	 al,-1		; Get return code
	 DOSCALL @EXITRC	; Return to DOS with exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TSRLOAD  endp			; End TSRLOAD procedure
	 NPPROC  CHECK_CPUID -- Check On CPU Identifier
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're running on an 80386 processor.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

N.B.:  Use only 8088 instructions!!!!

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 push	 sp		; First test for a 286/386
	 pop	 ax

	 cmp	 ax,sp		; Same?
	 jne	 short CHECK_CPUID_ERR ; No, it's neither a 286 nor a 386

; Distinguish 286 from 386

	 pushf			; Save flags for a moment

	 mov	 ax,mask $IOPL	; Try to set IOPL bits in flag register

	 push	 ax
	 popf

	 pushf			; Get flags back into AX
	 pop	 ax

	 popf			; Restore original flags

	 test	 ax,mask $IOPL	; Any bits set?
	 clc			; Assume OK
	 jnz	 short CHECK_CPUID_EXIT ; Yes, so continue on
CHECK_CPUID_ERR:
	 call	 DISP_COPY	; Display banner

	 mov	 cx,MSG_NOT386_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOT386 ; Tell 'em it's the wrong CPU

	 stc			; Indicate we have a problem
CHECK_CPUID_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPUID endp		; End CHECK_CPUID procedure

ACODE	 ends			; End ACODE segment

	 MEND	 INITIAL	; End TSRLOAD module

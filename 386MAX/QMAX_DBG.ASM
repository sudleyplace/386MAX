;' $Header:   P:/PVCS/MAX/386MAX/QMAX_DBG.ASV   1.2   30 May 1997 10:44:16   BOB  $
	 title	 QMAX_DBG -- 386MAX Debug Routines
	 page	 58,122
	 name	 QMAX_DBG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment DEBUG, byte-aligned,  public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'

Link requirements:  Final routine should have extension .SYS.

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include BITFLAGS.INC

	 include QMAX_DTE.INC
	 include QMAX_TRC.INC
.list

PGROUP	 group	 CODE,EDATA,DEBUG


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

if DBG_TRACE
	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC
endif				; IF DBG_TRACE

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  cs:PGROUP

	 extrn	 HEXTABLE:byte

if DBG_TRACE
	 public  TRCBASE,TRACESIZE
TRCBASE  dd	 ?		; base address of trace table
TRACESIZE dd	 500000 	; Size of trace table in bytes
				; (including header)
endif				; IF DBG_TRACE

EDATA	 ends			; End EDATA segment


DEBUG	 segment use16 byte public 'ecode' ; Start DEBUG segment
	 assume  cs:PGROUP

	 public  @QMAX_DBG_DEBUG
@QMAX_DBG_DEBUG:nop		; Mark module start in .MAP file

	 NPPROC  DD2HEX -- Convert EAX to Hex at ES:DI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 rol	 eax,16 	; Swap order
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 rol	 eax,16 	; Swap order
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	 endp		       ; End DD2HEX procedure
	 NPPROC  DW2HEX -- Convert AX to Hex at ES:DI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 rol	 ax,8		; Swap order
	 call	 DB2HEX 	; Convert AL to hex at ES:DI

	 rol	 ax,8		; Swap order
	 call	 DB2HEX 	; Convert AL to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2HEX	 endp			; End DW2HEX procedure
	 NPPROC  DB2HEX -- Convert AL to Hex at ES:DI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 rol	 al,4		; Swap order
	 call	 DN2HEX 	; Convert low-order nibble in AL to hex at ES:DI

	 rol	 al,4		; Swap order
	 call	 DN2HEX 	; Convert low-order nibble in AL to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	 endp			; End DB2HEX procedure
	 NPPROC  DN2HEX -- Convert Low-order Nibble in AL to Hex at ES:DI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 REGSAVE <ax,bx>	; Save registers

	 cld			; String ops forwardly
	 lea	 bx,HEXTABLE	; CS:BX ==> translate table
	 and	 al,@NIB0	; Isolate the digit
	 xlat	 HEXTABLE
S16	 stosb

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DN2HEX	 endp		       ; End DN2HEX procedure
if DBG_TRACE
	 NPPROC  INIT_TRACE -- Initialize Trace Table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize the trace table

|

HTRC_STR struc			; Trace table header

HTRC_NEXT dd	 ?		; Next available location
HTRC_LEN  dd	 ?		; Length of trace table (including header)
HTRC_WRAP dd	 ?		; Wrap count

HTRC_STR ends

	 test	 CM3_FLAG,@CM3_TRACE ; Are we tracing?
	 jz	 short INIT_TRACE_RET ; Not today

	 REGSAVE <eax,ecx,edi,es> ; Save registers

	 push	 DTE_TRACE	; Get trace table descriptor
	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 edi,size HTRC_STR ; Get size of header
	 mov	 es:[0].HTRC_NEXT,edi ; Save as offset of next location
	 mov	 ecx,TRACESIZE ; Get size of trace table (including header)
	 mov	 es:[0].HTRC_LEN,ecx ; Save in trace buffer
	 mov	 es:[0].HTRC_WRAP,0 ; Initialize wrap counter to zero

	 sub	 ecx,edi	; Account for header size in length
	 shr	 ecx,2-0	; Convert from bytes to dwords
	 mov	 eax,'CART'     ; Initialize to this value
     rep stos	 es:[edi].EDD	; Initialize the table

	 REGREST <es,edi,ecx,eax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it
INIT_TRACE_RET:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_TRACE endp 		; End INIT_TRACE procedure
endif				; IF DBG_TRACE
if DBG_TRACE
	 NPPROC  TRACE -- Put Byte Into Trace Table
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Put a byte into the trace table

On entry:

TRC_VAL  =	 byte to store

|

TRC_STR  struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
TRC_VAL  db	 ?,?		; Value to store

TRC_STR  ends

	 test	 CM3_FLAG,@CM3_TRACE ; Are we tracing?
	 jz	 short TRACE_RET ; Not today

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ax,edi,es>	; Save registers

	 pushf			; Save flags

	 cld			; String ops forwardly

	 push	 DTE_TRACE	; Get trace table descriptor
	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 al,[ebp].TRC_VAL ; Get the value to save

	 mov	 edi,es:[0].HTRC_NEXT ; Get offset of next location
S32	 stos	 es:[edi].LO	; Save in table

	 cmp	 edi,es:[0].HTRC_LEN ; Check against length of table
	 jb	 short @F	; Jump if it's within range

	 mov	 edi,size HTRC_STR ; Save offset of next location
	 inc	 es:[0].HTRC_WRAP ; Increment wrap counter
@@:
	 mov	 es:[0].HTRC_NEXT,edi ; Save offset of next location

	 popf			; Restore flags

	 REGREST <es,edi,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore
TRACE_RET:
	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TRACE	 endp			; End TRACE procedure
endif				; IF DBG_TRACE

DEBUG	 ends			; End DEBUG segment

	 MEND			; End QMAX_DBG module

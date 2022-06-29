;' $Header:   P:/PVCS/MAX/QMT/MEM_FMT.ASV   1.0   05 Sep 1995 16:55:42   HENRY  $
	title	MEM_FMT -- MEMCHK Formatting Routines
	page	58,122
	name	MEM_FMT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC

	include MEM_SEGS.INC
.list

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 GL2_FLAG:word
	 include MEM_GL2.INC

	 extrn	 TIMETAB:tbyte
	 include MEM_TIME.INC

	 extrn	 REG1UP:dword

	 extrn	 ZMSG_CURPATB:byte
	 extrn	 ZMSG_CURPATB1:byte
	 extrn	 ZMSG_CURPATW:byte
	 extrn	 ZMSG_CURPATW1:byte
	 extrn	 ZMSG_CURPATD:byte
	 extrn	 ZMSG_CURPATD1:byte

EMAC	 macro	 NAM,SUF,ALEN

	 extrn	 NAM:byte
	 extrn	 NAM&A:byte
	 extrn	 NAM&B:byte
ifnb <SUF>
	 extrn	 NAM&SUF:byte	; An extra suffix
endif				; IFNB <SUF>
ifnb <ALEN>
	 irp	 XX,<ALEN>
	 extrn	 NAM&&XX:abs	; An extra suffix
	 endm			; IRP
else
	 extrn	 NAM&_LEN:abs
endif				; IFNB <ALEN>
	 endm			; EMAC

	 EMAC	 MSG_W0
	 EMAC	 MSG_W1
	 EMAC	 MSG_R0
	 EMAC	 MSG_R1
	 EMAC	 MSG_R1W0
	 EMAC	 MSG_R1W0R0
	 EMAC	 MSG_R1W0W1
	 EMAC	 MSG_R1W0W1W0
	 EMAC	 MSG_R0W1
	 EMAC	 MSG_R0W1R1
	 EMAC	 MSG_R0W1R1W0R0W1,Z,<_LEN1,_LEN2>
	 EMAC	 MSG_R0W1W0

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 DISP_STATL:near
	 extrn	 BIN2DVAL:near
	 extrn	 BIN2BIT:near

	 extrn	 DISP_CURPAT:near

	 NPPROC  FMT_W0 -- Format and Display W0 Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Write 0s message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_W0A	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_W0B	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_W0 ; Pass address of local buffer
	 push	 MSG_W0_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_W0	 endp		       ; End FMT_W0 procedure
	 NPPROC  FMT_W1 -- Format and Display W1 Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Write 1s message.

On entry:

BX	 =	 index into TIMETAB

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_W1A	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_W1B	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_W1 ; Pass address of local buffer
	 push	 MSG_W1_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_W1	 endp			; End FMT_W1 procedure
	 NPPROC  FMT_R0 -- Format and Display R0 Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 0s message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R0A	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R0B	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R0 ; Pass address of local buffer
	 push	 MSG_R0_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R0	 endp			; End FMT_R0 procedure
	 NPPROC  FMT_R0DN -- Format and Display R0DN Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 0s down message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R0B	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R0A	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R0 ; Pass address of local buffer
	 push	 MSG_R0_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R0DN endp			; End FMT_R0DN procedure
	 NPPROC  FMT_R1 -- Format and Display R1 Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 1s message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R1A	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R1B	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R1 ; Pass address of local buffer
	 push	 MSG_R1_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R1	 endp			; End FMT_R1 procedure
	 NPPROC  FMT_R1DN -- Format and Display R1DN Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 1s down message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R1B	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R1A	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R1 ; Pass address of local buffer
	 push	 MSG_R1_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R1DN endp			; End FMT_R1DN procedure
	 NPPROC  FMT_R0W1 -- Format and Display R0W1 Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 0s/Write 1s message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R0W1A	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R0W1B	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R0W1 ; Pass address of local buffer
	 push	 MSG_R0W1_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R0W1 endp			; End FMT_R0W1 procedure
	 NPPROC  FMT_R0W1R1 -- Format and Display R0W1R1 Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 0s/Write 1s/Read 1s message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R0W1R1A ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R0W1R1B ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R0W1R1 ; Pass address of local buffer
	 push	 MSG_R0W1R1_LEN ; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R0W1R1 endp 		; End FMT_R0W1R1 procedure
	 NPPROC  FMT_R0W1R1W0R0W1 -- Format and Display R0W1R1W0R0W1 Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 0s/Write 1s/Read 1s message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R0W1R1W0R0W1A ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R0W1R1W0R0W1B ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R0W1R1W0R0W1 ; Pass address of local buffer
	 push	 MSG_R0W1R1W0R0W1_LEN1 ; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 push	 offset ds:MSG_R0W1R1W0R0W1Z ; Pass address of local buffer
	 push	 MSG_R0W1R1W0R0W1_LEN2 ; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R0W1R1W0R0W1 endp		; End FMT_R0W1R1W0R0W1 procedure
	 NPPROC  FMT_R0W1DN -- Format and Display R0W1DN Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 0s/Write 1s down message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R0W1B	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R0W1A	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R0W1 ; Pass address of local buffer
	 push	 MSG_R0W1_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R0W1DN endp 		; End FMT_R0W1DN procedure
	 NPPROC  FMT_R1W0 -- Format and Display R1W0 Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 1s/Write 0s message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R1W0A	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R1W0B	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R1W0 ; Pass address of local buffer
	 push	 MSG_R1W0_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R1W0 endp			; End FMT_R1W0 procedure
	 NPPROC  FMT_R1W0DN -- Format and Display R1W0DN Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 1s/Write 0s down message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R1W0B	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R1W0A	; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R1W0 ; Pass address of local buffer
	 push	 MSG_R1W0_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R1W0DN endp 		; End FMT_R1W0DN procedure
	 NPPROC  FMT_R0W1W0 -- Format and Display R0W1W0 Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 0s/Write 1s/Write 0s message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R0W1W0A ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R0W1W0B ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R0W1W0 ; Pass address of local buffer
	 push	 MSG_R0W1W0_LEN ; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R0W1W0 endp 		; End FMT_R0W1W0 procedure
	 NPPROC  FMT_R0W1W0DN -- Format and Display R0W1W0DN Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 0s/Write 1s/Write 0s down message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R0W1W0B ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R0W1W0A ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R0W1W0 ; Pass address of local buffer
	 push	 MSG_R0W1W0_LEN ; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R0W1W0DN endp		; End FMT_R0W1W0DN procedure
	 NPPROC  FMT_R1W0W1 -- Format and Display R1W0W1  Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 1s/Write 0s/Write 1s message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R1W0W1A ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R1W0W1B ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R1W0W1 ; Pass address of local buffer
	 push	 MSG_R1W0W1_LEN ; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R1W0W1 endp 		; End FMT_R1W0W1 procedure
	 NPPROC  FMT_R1W0W1DN -- Format and Display R1W0W1DN Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 1s/Write 0s/Write 1s down message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R1W0W1B ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R1W0W1A ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R1W0W1 ; Pass address of local buffer
	 push	 MSG_R1W0W1_LEN ; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R1W0W1DN endp		; End FMT_R1W0W1DN procedure
	 NPPROC  FMT_R1W0W1W0DN -- Format and Display R1W0W1W0DN Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 1s/Write 0s/Write 1s/Write 0s down message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R1W0W1W0B ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R1W0W1W0A ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R1W0W1W0 ; Pass address of local buffer
	 push	 MSG_R1W0W1W0_LEN ; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R1W0W1W0DN endp		; End FMT_R1W0W1W0DN procedure
	 NPPROC  FMT_R1W0R0DN -- Format and Display R1W0R0DN Message
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display Read 1s/Write 0s/Read 0s down message.

On entry:

BX	 =	 index into TIMETAB
EDX	 =	 N in bytes

|

	 REGSAVE <eax,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,TIMETAB[bx].TT_PBASE ; EAX ==> A[0]
	 lea	 di,MSG_R1W0R0B ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,edx	; EAX ==> A[N]
;;;;;;;; dec	 eax		; EAX ==> A[N-1] (high-order byte)
	 lea	 di,MSG_R1W0R0A ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 push	 offset ds:MSG_R1W0R0 ; Pass address of local buffer
	 push	 MSG_R1W0R0_LEN ; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line

	 REGREST <es,di,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_R1W0R0DN endp		; End FMT_R1W0R0DN procedure
	 NPPROC  FMT_PATTERNB -- Format and Display Current Byte Pattern
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display the current byte pattern.

|

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short FMT_PATTERNB_EXIT ; Jump if not

	 REGSAVE <ax,cx,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 al,REG1UP.LO	; Get the pattern value to display
	 lea	 di,ZMSG_CURPATB1 ; ES:DI ==> output save area
	 mov	 cx,8		; CX = # bits to display
	 call	 BIN2BIT	; Convert EAX to CX bits

	 push	 offset ds:ZMSG_CURPATB ; Pass offset of message
	 call	 DISP_CURPAT	; Display the current pattern

	 REGREST <es,di,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it
FMT_PATTERNB_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_PATTERNB endp		; End FMT_PATTERNB procedure
	 NPPROC  FMT_PATTERNW -- Format and Display Current Word Pattern
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display the current word pattern.

|

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short FMT_PATTERNW_EXIT ; Jump if not

	 REGSAVE <ax,cx,di,es>	; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 ax,REG1UP.ELO	; Get the pattern value to display
	 lea	 di,ZMSG_CURPATW1 ; ES:DI ==> output save area
	 mov	 cx,16		; CX = # bits to display
	 call	 BIN2BIT	; Convert EAX to CX bits

	 push	 offset ds:ZMSG_CURPATW ; Pass offset of message
	 call	 DISP_CURPAT	; Display the current pattern

	 REGREST <es,di,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it
FMT_PATTERNW_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_PATTERNW endp		; End FMT_PATTERNW procedure
	 NPPROC  FMT_PATTERND -- Format and Display Current Dword Pattern
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display the current dword pattern.

|

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short FMT_PATTERND_EXIT ; Jump if not

	 REGSAVE <eax,cx,di,es> ; Save registers

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,REG1UP	; Get the pattern value to display
	 lea	 di,ZMSG_CURPATD1 ; ES:DI ==> output save area
	 mov	 cx,32		; CX = # bits to display
	 call	 BIN2BIT	; Convert EAX to CX bits

	 push	 offset ds:ZMSG_CURPATD ; Pass offset of message
	 call	 DISP_CURPAT	; Display the current pattern

	 REGREST <es,di,cx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it
FMT_PATTERND_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_PATTERND endp		; End FMT_PATTERND procedure

CODE	 ends			; End CODE segment

	 MEND			; End MEM_FMT module

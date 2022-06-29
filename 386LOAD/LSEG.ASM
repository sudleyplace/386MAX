;' $Header:   P:/PVCS/MAX/386LOAD/LSEG.ASV   1.1   30 May 1997 10:38:06   BOB  $
	 title	 LSEG -- Display LSEG Info
	 page	 58,122
	 name	 LSEG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1990-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, October, 1990.

Modifications by:  None.

|
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include IOCTL.INC
	 include PTR.INC

	 include QMAX_CTL.INC
	 include LOAD_SEG.INC
.list

PGROUP	 group	 STACK,CODE,DATA,DTAIL


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 public  NUMBERS_HI
NUMBERS_HI db	 '0123456789ABCDEF' ; Conversion table for BIN2BASE

	 public  DEVHNDL
DEVHNDL  dw	 ?		; Device handle #

	 public  DEVNAME
DEVNAME  db	 '386MAX$$',0   ; Our device name

	 public  INFO_CTL,INFO,INFOSIZE
	 include QMAXINFO.INC
	 db	 ?		; Force even alignment for INFO_STR
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR
LOADSEG  equ	 INFO.INFO_LSEG ; 27 = 386LOAD chain segment

	 public  PFLAGS
PFLAGS	 dw	 PGROUP:FLAG_FLEX
	 dw	 PGROUP:FLAG_INST
	 dw	 PGROUP:FLAG_GSIZE
	 dw	 PGROUP:FLAG_XLHI
	 dw	 PGROUP:FLAG_XEMS
	 dw	 PGROUP:FLAG_FSIZ
	 dw	 PGROUP:FLAG_DRV
	 dw	 PGROUP:FLAG_WINST
	 dw	 PGROUP:FLAG_INPRO
	 dw	 PGROUP:FLAG_INFLEX
	 dw	 PGROUP:FLAG_XRES
	 dw	 PGROUP:FLAG_IMAX
	 dw	 PGROUP:FLAG_LSIZ
	 dw	 ?			; Strategy field handled separately
	 dw	 ?			; ...
	 dw	 PGROUP:FLAG_UMB
@MAXFLAG equ	 $-PFLAGS

	 public  PFLAGS2
PFLAGS2  dw	 PGROUP:FLAG2_NOV
	 dw	 PGROUP:FLAG2_FISIZE
@MAXFLAG2 equ	 $-PFLAGS2

	 public  UFLAGS
UFLAGS	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_ANC
	 dw	 PGROUP:UFLAG_DLGHI
	 dw	 PGROUP:UFLAG_IMAX
	 dw	 PGROUP:UFLAG_PREV
	 dw	 PGROUP:UFLAG_PSP
@MAXUFLAG equ	 $-UFLAGS

	 public  PSTRA
PSTRA	 dw	 PGROUP:STRA_FIRST
	 dw	 PGROUP:STRA_BEST
	 dw	 PGROUP:STRA_LAST
	 dw	 PGROUP:STRA_UNDEF

FLAG_FLEX  db	 '  FLEXFRAME',CR,LF,EOS
FLAG_INST  db	 '  DOS 4.xx INSTALL',CR,LF,EOS
FLAG_GSIZE db	 '  Forced GETSIZE',CR,LF,EOS
FLAG_XLHI  db	 '  NOLOADHI',CR,LF,EOS
FLAG_XEMS  db	 '  EMS error in FLEXFRAME',CR,LF,EOS
FLAG_FSIZ  db	 '  Forced resident SIZE=',CR,LF,EOS
FLAG_DRV   db	 '  Device driver',CR,LF,EOS
FLAG_WINST db	 '  Needs instancing under Windows',CR,LF,EOS
FLAG_INPRO db	 '  386LOAD in progress',CR,LF,EOS
FLAG_INFLEX db	 '  Needs FLEXFRAME',CR,LF,EOS
FLAG_XRES  db	 '  Did not go resident',CR,LF,EOS
FLAG_IMAX  db	 '  Initial size was maximum',CR,LF,EOS
FLAG_LSIZ  db	 '  Load size > initialization size',CR,LF,EOS
FLAG_UMB   db	 '  UMB allocator',CR,LF,EOS

FLAG2_NOV  db	 '  Loaded by NETX',CR,LF,EOS
FLAG2_FISIZE db  '  Initialization size will remain fixed',CR,LF,EOS

UFLAG_ANC  db	 '  UMB: Entry [this-'
UFLAG_ANC1 db	 '__] was maximum',CR,LF,EOS
UFLAG_DLGHI db	 '  UMB: DLGROUP loaded high',CR,LF,EOS
UFLAG_IMAX db	 '  UMB: Resized from maximum size',CR,LF,EOS
UFLAG_PREV db	 '  UMB: Ancestor bitmap valid',CR,LF,EOS
UFLAG_PSP  db	 '  UMB: 4B PSP',CR,LF,EOS

STRA_FIRST db	 '  First fit allocation',CR,LF,EOS
STRA_BEST  db	 '  Best fit allocation',CR,LF,EOS
STRA_LAST  db	 '  Last fit allocation',CR,LF,EOS
STRA_UNDEF db	 '  *Undefined strategy*',CR,LF,EOS

	 public  LCLBUF
LCLBUF	 db	 'þ '
LCL_FNE  db	 12 dup (?)
	 db	 ' RPARA = '
LCL_RPARA db	 '____'
	 db	 ' EPAR0 = '
LCL_EPAR0 db	 '____'
	 db	 ' EPAR1 = '
LCL_EPAR1 db	 '____'
	 db	 ' RPAR2 = '
LCL_RPAR2 db	 '____'
	 db	 ' NPARA = '
LCL_NPARA db	 '____',CR,LF
	 db	 'ASIZE = '
LCL_ASIZE db	 '________'
	 db	 ' LSIZE = '
LCL_LSIZE db	 '________'
	 db	 ' ISIZE = '
LCL_ISIZE db	 '________'
	 db	 ' PREG = '
LCL_PREG db	 '__'
	 db	 ' EREG = '
LCL_EREG db	 '__'
	 db	 ' GRP = '
LCL_GRP  db	 '__',CR,LF
	 db	 'OWNRHI = '
LCL_OWNRHI db	 '____'
	 db	 ' INSTLO = '
LCL_INSTLO db	 '____'
	 db	 ' INSTLEN = '
LCL_INSTLEN db	 '____'
	 db	 ' FLAG = '
LCL_FLAG db	 '____'
	 db	 ', '
LCL2_FLAG db	 '__'
	 db	 '   @'
LCL_ADDRHI db	 '____:0000'
	 db	 CR,LF
LCLBUF_LEN equ	 $-LCLBUF	; Length of local buffer

	 public  LCLSTK,LCLSTKZ
LCLSTK	 db	 100h dup (?)	; Local stack
LCLSTKZ  dw	 0		; Top of stack

DATA	 ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	 segment dword public 'data' ; Start DTAIL segment
	 assume  ds:PGROUP

	 public  ZTAIL
ZTAIL	 label	 byte

DTAIL	 ends			; End DTAIL segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
	 NPPROC  LSEG -- Display LSEG Info
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

	 lea	 sp,LCLSTKZ	; Switch to local stack

; Ensure we're already installed

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2,DEVNAME ; Attempt to open 386MAX device driver
	 jc	 short LSEG_ERR ; Jump if not installed

	 mov	 DEVHNDL,ax	; Save for later use
	 mov	 bx,ax		; Copy to handle register

; Ensure it's a device

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 short LSEG_CLOSE ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short LSEG_CLOSE ; No???

	 call	 INFO_READ	; Read in INFO structure

	 DOSCALL @CLOSF2	; Close the opened file

	 mov	 ax,LOADSEG	; Get the segment of the 1st LSEG
LSEG_NEXT1:
	 cmp	 ax,-1		; Izit the last one?
	 je	 short LSEG_EXIT ; Jump if so

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 call	 DISP_LSEG	; Display the LSEG at ES:0

	 mov	 ax,es:[0].LSEG_NEXT ; Get segment of next LSEG in the chain

	 jmp	 short LSEG_NEXT1 ; Go around again

LSEG_CLOSE:
	 DOSCALL @CLOSF2	; Close the opened file
LSEG_ERR:
LSEG_EXIT:
	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,ss:nothing

LSEG	 endp			; End LSEG procedure
	 NPPROC  INFO_READ -- Read In INFO Structure
	 assume  ds:PGROUP,es:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 al,02h 	; Read from device
	 mov	 bx,DEVHNDL	; Get device handle
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INFO_READ endp			; End INFO_READ procedure
	 NPPROC  DISP_LSEG -- Display LSEG
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Display LSEG at ES:0

On entry:

ES:0	 ==>	 LSEG to display

|

	 REGSAVE <ax,bx,cx,dx,di> ; Save registers

; Copy device name to buffer

	 mov	 cx,12		; CX = # bytes to copy
	 xor	 bx,bx		; Index into LSEG_FNE
@@:
	 mov	 al,es:[bx].LSEG_FNE ; Get next byte
	 mov	 LCL_FNE[bx],al ; Save for later use
	 inc	 bx		; Skip to next byte
	 loop	 @B		; Jump if more bytes to copy

; Format various values

	 lea	 di,LCL_RPARA	; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_RPARA ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_EPAR0	; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_EPAR0 ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_EPAR1	; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_EPAR1 ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_RPAR2	; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_RPAR2 ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_NPARA	; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_NPARA ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_OWNRHI	; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_OWNRHI ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_INSTLO	; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_INSTLO ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_INSTLEN ; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_INSTLEN ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_PREG	; DS:DI ==> output save area
	 mov	 al,es:[0].LSEG_PREG ; Get the value
	 call	 DB2HEX 	; Convert AL to hex at DS:DI

	 lea	 di,LCL_EREG	; DS:DI ==> output save area
	 mov	 al,es:[0].LSEG_EREG ; Get the value
	 call	 DB2HEX 	; Convert AL to hex at DS:DI

	 lea	 di,LCL_GRP	; DS:DI ==> output save area
	 mov	 al,es:[0].LSEG_GRP ; Get the value
	 call	 DB2HEX 	; Convert AL to hex at DS:DI

	 lea	 di,LCL_ASIZE[4] ; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_ASIZE.ELO ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_ASIZE[0] ; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_ASIZE.EHI ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_LSIZE[4] ; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_LSIZE.ELO ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_LSIZE[0] ; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_LSIZE.EHI ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_ISIZE[4] ; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_ISIZE.ELO ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_ISIZE[0] ; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_ISIZE.EHI ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL_FLAG	; DS:DI ==> output save area
	 mov	 ax,es:[0].LSEG_FLAG ; Get the value
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

	 lea	 di,LCL2_FLAG	; DS:DI ==> output save area
	 mov	 al,es:[0].LSEG2_FLAG ; Get the value
	 call	 DB2HEX 	; Convert AL to hex at DS:DI

	 lea	 di,LCL_ADDRHI	; DS:DI ==> output save area
	 mov	 ax,es		; Segment of LSEG entry
	 call	 DW2HEX 	; Convert AX to hex at DS:DI

; Display the entire buffer

	 mov	 bx,@STD_OUT	; Send to standard output
	 mov	 cx,LCLBUF_LEN	; CX = # chars to write out
	 DOSCALL @WRITF2,LCLBUF ; Write it out

; Display the flag values

	 mov	 bx,es:[0].LSEG_FLAG ; Get flags
	 and	 bx,@LSEG_STRA	; Isolate strategy bits
	 mov	 cl,($LSEG_STRA-1) ; Convert field to word index
	 shr	 bx,cl		; BX = strategy * 2
	 jz	 short @F	; Jump if first fit (don't bother reporting)

	 mov	 dx,PSTRA[bx]	; DS:DX ==> text to display
	 DOSCALL @STROUT	; Display text
@@:
	 mov	 cx,es:[0].LSEG_FLAG ; Get the value
	 and	 cx,not @LSEG_STRA ; Mask off strategy bits
	 xor	 bx,bx		; Index into PFLAGS
DISP_LSEG_NEXT:
	 shr	 cx,1		; Shift down next bit
	 jnc	 short @F	; Jump if not set

	 mov	 dx,PFLAGS[bx]	; DS:DX ==> text to display
	 DOSCALL @STROUT	; Display text
@@:
	 add	 bx,2		; Skip to next entry

	 cmp	 bx,@MAXFLAG	; Izit beyond our table?
	 jb	 short DISP_LSEG_NEXT ; Jump if not yet

	 mov	 cl,es:[0].LSEG2_FLAG ; Get secondary flags
	 sub	 bx,bx		; Index into PFLAGS2
DISP_LSEG_NEXT2:
	 shr	 cl,1		; Put next bit into CF
	 jnc	 short @F	; Jump if not set

	 mov	 dx,PFLAGS2[bx] ; DS:DX ==> text to display
	 DOSCALL @STROUT	; Display text
@@:
	 add	 bx,2		; Skip to next entry

	 cmp	 bx,@MAXFLAG2	; Izit beyond our table?
	 jb	 short DISP_LSEG_NEXT2 ; Jump if not

; If it's a UMB, display special flags and ancestor bitmap from EPAR1
	 test	 es:[0].LSEG_FLAG,@LSEG_INST or @LSEG_DRV ; Izit 386LOAD?
	 jnz	 short DISP_LSEG_EXIT ; Jump if so

	 test	 es:[0].LSEG_FLAG,@LSEG_UMB ; Izit a UMB?
	 jz	 short DISP_LSEG_EXIT ; Jump if not

	 mov	 cx,es:[0].LSEG_EPAR1 ; Get UMB flags and ancestor bitmap
	 sub	 bx,bx		; Index into PFLAGS2
	 mov	 al,12		; Initialize ancestor index
DISP_LSEG_NEXTU:
	 shr	 cx,1		; Put next bit into CF
	 jnc	 short @F	; Jump if not set

	 lea	 di,UFLAG_ANC1	; DS:DI ==> output save area
	 call	 DB2HEX 	; Convert AL to hex at DS:DI

	 mov	 dx,UFLAGS[bx]	; DS:DX ==> text to display
	 DOSCALL @STROUT	; Display text
@@:
	 add	 bx,2		; Skip to next entry
	 dec	 al		; Count another ancestor

	 cmp	 bx,@MAXUFLAG	; Izit beyond our table?
	 jb	 short DISP_LSEG_NEXTU ; Jump if not

DISP_LSEG_EXIT:
	 REGREST <di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_LSEG endp			; End DISP_LSEG procedure
	 NPPROC  DB2HEX -- Convert AL to Hex At ES:DI
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Convert AL to hex at DS:DI

On entry:

AL	 =	 value to convert
DS:DI	 ==>	 output save area

On exit:

DS:DI	 ==>	 byte to right of converted number

|

	 push	 cx		; Save for a moment
	 mov	 cx,2		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 cx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DB2HEX	 endp			; End DB2HEX procedure
	 NPPROC  DW2HEX -- Convert AX to Hex At ES:DI
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Convert AX to hex at DS:DI

On entry:

AX	 =	 value to convert
DS:DI	 ==>	 output save area

On exit:

DS:DI	 ==>	 byte to right of converted number

|


	 push	 cx		; Save for a moment
	 mov	 cx,4		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 cx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DW2HEX	 endp			; End DW2HEX procedure
	 NPPROC  BIN2HEX_SUB
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Convert AL/AX to hex at DS:DI

On entry:

AL/AX	 =	 value to convert
CX	 =	 # hex digits to convert
DS:DI	 ==>	 output save area

On exit:

DS:DI	 ==>	 byte to right of converted number

|


	 REGSAVE <ax,bx,dx,es>	; Save registers

	 push	 ds		; Setup ES for string ops
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 pushf			; Save flags
	 std			; Store backwards

	 mov	 dx,ax		; Copy to secondary register
	 lea	 bx,NUMBERS_HI	; XLAT table
	 add	 di,cx		; Skip to the end+1
	 push	 di		; Save to return
	 dec	 di		; Now the last digit
BIN2HEX_MORE:
	 mov	 al,dl		; Copy to XLAT register
	 and	 al,0Fh 	; Isolate low-order digit
	 xlat	 NUMBERS_HI	; Convert to ASCII hex
	 stosb			; Save in output area

	 shr	 dx,1		; Shift next digit down to low-order
	 shr	 dx,1		; ...
	 shr	 dx,1		; ...
	 shr	 dx,1		; ...

	 loop	 BIN2HEX_MORE	; Jump if more digits to format

	 pop	 di		; Restore

	 popf			; Restore flags

	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure

CODE	 ends			; End CODE segment

	 MEND	 LSEG		; End LSEG module

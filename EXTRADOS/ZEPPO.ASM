
	 title	 ZEPPO -- Ths ZEPPO.COM porgram
	 page	 58,122
	 name	 ZEPPO

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, word-aligned,  stack,  class 'prog'
	       Program segment CODE,  word-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:

Modifications by:

Who		 When		What
--------------------------------------------------------------------------------


|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include IOCTL.INC
	 include PTR.INC

	 include QMAX_CTL.INC
	 include EMM2CALL.INC
	 include HARPO.INC
.list

PGROUP	 group	 STACK,CODE,DATA


;*******************************************************************

; MASM 6.0 options

OPTION OFFSET:GROUP		; Have offsetts be GROUP relative
OPTION OLDMACROS		; Use old macro style
OPTION SEGMENT:USE16		; Verify USE16 Rules

;***************************************************************************

; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 word stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


;***************************************************************************

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

;--------------- MASM 6.0 Handy Equates -------------------

VVOFF	 TEXTEQU	<VECTOR.VOFF>	; A handy MASM 6.0 equate
VVSEG	 TEXTEQU	<VECTOR.VSEG>	; ...

BPTR	 TEXTEQU	<byte ptr>	; More handy MASM 6.0 equates
WPTR	 TEXTEQU	<word ptr>	; ...
DWPTR	 TEXTEQU	<dword ptr>	;...


;--------------- Messages -----------------------------------

	 public  MSG_COPY
MSG_COPY db	 'ZEPPO  -- Version 1.03 '
	 db	 '  A Test program for HARPO',CR,LF
	 db	 '  (C) Copyright 1992 Qualitas, Inc.  All Rights reserved.'
	 db	 CR,LF
MSG_CRLF db	 CR,LF,EOS

if 0 ;==================
	 public  XMS_ENTRY,REGION
XMS_ENTRY	 dd	 ?	; XMS entry point
REGION		 db	 1	; UMB region (start at region 1)
endif ;==============

	 public MSG_TYPE,MSG_LENGTH
MSG_TYPE	 db	 '_ '
MSG_LENGTH	 db	 '____'
		 db	 CR,LF,EOS

if 0 ;=============
	 public  MSG_UMB,MSG_UMBREG,MSG_UMBSEG,MSG_UMBLEN
MSG_UMB 	 db	 'The largest UMB in region '
MSG_UMBREG	 db	 '____ is at segment '
MSG_UMBSEG	 db	 '____ for '
MSG_UMBLEN	 db	 '____ paras.'
		 db	 CR,LF,EOS
endif ;===============

	 public  MSG_TABLE_FULL
MSG_TABLE_FULL	 db	 BEL
		 db	 'Warning: The sub-seg table is full.'
		 db	 CR,LF,EOS

	 public  MSG_COMPAT,MSG_XCOMPAT
MSG_COMPAT	 db	 'HARPO is compatable with this system.',CR,LF,EOS
MSG_XCOMPAT	 db	 'HARPO is not compatable with this system.',CR,LF,EOS

if 0 ;=============
	 public  MSG_NOXMS,MSG_GETUMB_ERR1,MSG_GETUMB_ERR2
	 public  MSG_DELUMB_ERR
MSG_NOXMS	 db	 'Error, an XMS manager was not found.',CR,LF,EOS
MSG_GETUMB_ERR1  db	 'Error, XMS function 90h failed (first invocation).',CR,LF,EOS
MSG_GETUMB_ERR2  db	 'Error, XMS function 90h failed (second invocation).',CR,LF,EOS
MSG_DELUMB_ERR	 db	 'Error, Could not remove UMB.',CR,LF,EOS
endif ;=============

	 public  MSG_INFO
MSG_INFO      db	'Type Npar Bytes Reg Flags'   ,CR,LF
	      db	'---- ---- ----- --- -----'   ,CR,LF,EOS
MSG_INFO_STRT db	'   '
MSG_INFO_TYPE db	   '_ '
MSG_INFO_NPAR db	     '____ '
MSG_INFO_BYTE db		  '    _  '
MSG_INFO_REG  db			  '__ '
MSG_INFO_FLAG db			     '____'   ,CR,LF,EOS

	 public  MSG_FILE
MSG_FILE db	CR,LF,'The filespec is:',CR,LF,EOS

	 public  MSG_FILESPEC1,MSG_FILESPEC2
MSG_FILESPEC1 db	'C:\MISC\HARPO\HARPO.EXE',0
MSG_FILESPEC2 db	81 dup ('$')


;--------------- 386MAX variables --------------------------

	 public  DEVNAME_MAX,DEV_HNDL
DEVNAME_MAX	 db	 '386MAX$$',0   ; MAX's device name
DEV_HNDL	 dw	 0		; Handle used to open MAX


	 public  INFO_CTL,INFO,INFOSIZE
	 include QMAXINFO.INC
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR

	 public  PORT67
PORT67		 dw	 0	; MAX's port 67 value


;------------- Misc variables -----------------------

	 public  HEXTABLE
HEXTABLE   db	 '0123456789ABCDEF' ; Used for display routines

@BUFF_LEN equ	 256

	 public  BUFFER
BUFFER	 db	 @BUFF_LEN dup (?)	; Buffer for HARPO info (from MAX)

	 public  LCLSTK,LCLSTKZ
	 align	 2
LCLSTK	 db	 100h dup (?)	; Local stack
LCLSTKZ  dw	 0		; Top of stack

DATA	 ends			; End DATA segment


;***************************************************************************

CODE	 segment use16 word public 'prog' ; Start CODE segment
	 assume  cs:PGROUP
.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list


;***************************************************************************

	 NPPROC  ZEPPO -- The ZEPPO Program
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|


|

	 lea	 sp,LCLSTKZ	; Switch to local stack

	 DOSCALL @STROUT,MSG_COPY ; Display the flag

;--------

; Test the new IMM2 function calls

	 call	 TEST_SUBSEG	; Test the IMM2 calls (00,01,02)

	 call	 TEST_FILESPEC	; Test the IMM2 calls (03,04)

;--------

EXIT:
	 mov	 ax,4C00h	; DOS: Exit process function (no error code)
	 int	 21h		; Exit process with return code in AL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ZEPPO	 endp			; End ZEPPO procedure

;*****************************************************************************

	 NPPROC  TEST_SUBSEG -- TEST_SUBSEG procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Test the EMM2 sub-seg functions

Subfunction 00: Send info to MAX (for Windows)
Subfunction 01: Pass 1 sub-seg record to MAX
Subfunction 02: Read all sub-seg records

|

	 REGSAVE <ax,bx,cx,dx,di,ds,es> ; Save registers

	 call	 MAX_PRESENT	; Get MAX's PORT67 value

	 cmp	 PORT67,0	; Has it been initialized?
	 je	 EXIT		; Jump if not

; Send the size of one FILE entry to MAX (via EMM2)

	 mov	 bl,5Bh 	; Get size of file entry

	 push	 bp		; Save BP
	 mov	 bp,sp		; Save SP (in case MAX trashes it)

	 mov	 al,@HARPO_SET_INFO ; Send FILES= info th HARPO
	 EMMOUT  @EMM2_HARPOINFO ; Pass FILES= information to MAX

	 mov	 sp,bp		; Restore SP
	 pop	 bp		; Restore BP

if 0 ;============================

; Pass 1 sub-seg record to MAX

	 mov	 bl,'F'         ; Sub-segment type (F,X,B,L,S)
	 mov	 cx,69h 	; # Paras
	 mov	 bh,1		; Region #
	 mov	 dx,12h 	; Misc Flags

	 push	 bp		; Save BP
	 mov	 bp,sp		; Save SP (in case MAX trashes it)

	 mov	 al,@HARPO_SET_SUBSEG ; Send sub-segment info to HARPO
	 EMMOUT  @EMM2_HARPOINFO ; Pass FILES= information to MAX

	 mov	 sp,bp		; Restore SP
	 pop	 bp		; Restore BP

	 cmp	 ah,8Fh 	; Was the table full?
	 je	 TABLE_FULL	; Jump if so

; Pass 1 sub-seg record to MAX

	 mov	 bl,'X'         ; Sub-segment type (F,X,B,L,S)
	 mov	 cx,6Ah 	; # Paras
	 mov	 bh,2		; Region #
	 mov	 dx,13h 	; Misc Flags

	 push	 bp		; Save BP
	 mov	 bp,sp		; Save SP (in case MAX trashes it)

	 mov	 al,@HARPO_SET_SUBSEG ; Send sub-segment info to HARPO
	 EMMOUT  @EMM2_HARPOINFO ; Pass FILES= information to MAX

	 mov	 sp,bp		; Restore SP
	 pop	 bp		; Restore BP

	 cmp	 ah,8Fh 	; Was the table full?
	 jne	 @F		; Jump if so

TABLE_FULL:
	 DOSCALL @STROUT,MSG_TABLE_FULL ; Tell 'em the table is full

@@:

endif ;===================================

; Get the records back from MAX

	 lea	 di,BUFFER	; Address of local buffer
	 mov	 cx,@BUFF_LEN	; Length of buffer

	 push	 bp		; Save BP
	 mov	 bp,sp		; Save SP (in case MAX trashes it)

	 mov	 al,@HARPO_GET_SUBSEGS ; Get sub-segment info from HARPO
	 EMMOUT  @EMM2_HARPOINFO ; Pass FILES= information to MAX
				; Return CX = Number of bytes transfered

	 mov	 sp,bp		; Restore SP
	 pop	 bp		; Restore BP

; Display the records

	 DOSCALL @STROUT,MSG_INFO ; Display header

	 lea	 si,BUFFER	; Address the INFO buffer
	 add	 cx,offset BUFFER ; Address end of buffer

DISP_NEXT:
	 lodsb			; Get the sub-segment Type
	 mov	 [MSG_INFO_TYPE],al ; Store in message

	 lodsw			; Get the para count
	 lea	 di,MSG_INFO_NPAR
	 call	 FMT_WORD	;

	 mov	 WPTR MSG_INFO_BYTE,'  ' ; Zap previous number
	 mov	 WPTR MSG_INFO_BYTE+2,'  ' ; ...

	 shl	 ax,1		; Convert from paras to bytes
	 shl	 ax,1		;
	 shl	 ax,1		;
	 shl	 ax,1		;
	 lea	 di,MSG_INFO_BYTE+4
	 call	 FMT_BASE10	;

	 lodsb			; Get the region number
	 lea	 di,MSG_INFO_REG
	 call	 FMT_BYTE	;

	 lodsw			; Get the flags
	 lea	 di,MSG_INFO_FLAG
	 call	 FMT_WORD	;

	 DOSCALL @STROUT,MSG_INFO_STRT ; Display one line

	 cmp	 si,cx		; Have we reached the end?
	 jb	 DISP_NEXT	; Jump if not


EXIT:
	 REGREST <es,ds,di,dx,cx,bx,ax> ; Restore registers
	 assume  ds:PGROUP	; Tell the assembler about it
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
TEST_SUBSEG	 endp		; End TEST_SUBSEG procedure


;*************************************************************************

	 NPPROC  TEST_FILESPEC -- TEST_FILESPEC procedure
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Test the EMM2 FILESPEC functions

Subfunction 03: Pass HARPO.INI filespec to MAX
Subfunction 04: Get HARPO.INI filespec name from MAX

|

	 REGSAVE <>		; Save registers

	 call	 MAX_PRESENT	; Get MAX's PORT67 value

	 cmp	 PORT67,0	; Has it been initialized?
	 je	 EXIT		; Jump if not

if 0 ;================================

; Pass the filename to MAX

	 lea	 di,MSG_FILESPEC1	; Address of filespec

	 push	 bp		; Save BP
	 mov	 bp,sp		; Save SP (in case MAX trashes it)

	 mov	 al,@HARPO_SET_FILESPEC ; Pass filespec to MAX
	 EMMOUT  @EMM2_HARPOINFO ; Pass FILES= information to MAX
				; Return CX = Number of bytes transfered

	 mov	 sp,bp		; Restore SP
	 pop	 bp		; Restore BP

endif ;===========================

; Retrieve MAX's filespec

	 lea	 di,MSG_FILESPEC2 ; Address of new spec

	 push	 bp		; Save BP
	 mov	 bp,sp		; Save SP (in case MAX trashes it)

	 mov	 al,@HARPO_GET_FILESPEC ; Get filespec to MAX
	 EMMOUT  @EMM2_HARPOINFO ; Pass FILES= information to MAX
				; Return CX = Number of bytes transfered

	 mov	 sp,bp		; Restore SP
	 pop	 bp		; Restore BP

; Display the new FILESPEC

	 DOSCALL @STROUT,MSG_FILE	; Display header
	 DOSCALL @STROUT,MSG_FILESPEC2 ; Display file name


EXIT:
	 REGREST <>		; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
TEST_FILESPEC	 endp		; End TEST_FILESPEC procedure


;*************************************************************************

	 NPPROC  MAX_PRESENT -- Check for 386MAX device presence
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

COMMENT |

Determine if MAX is present.

If MAX is present, save the PORT67 value for the VxD EMM2 call.

|

	 REGSAVE <ax,bx,cx,dx>	; Save caller's registers

	 mov	 al,02h 	; R/W access
	 DOSCALL @OPENF2,DEVNAME_MAX ; Attempt to open 386MAX device driver
	 jc	 EXIT_ERR	; Jump if it failed

; Ensure it's a device

	 mov	 DEV_HNDL,ax	; Save for later use
	 mov	 bx,ax		; Move handle to proper register

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 EXIT_ERR	; Jump if error

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 EXIT_ERR	; No???

; Get QMAXINFO structure

	 mov	 al,02h 	; Read from device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

	 mov	 ax,INFO.INFO_P67 ; I/O port number for EMM2 functions
	 mov	 PORT67,ax	; Save for EMMOUT macro

	 jmp	 EXIT_CLOSE	; Join common exit code

EXIT_ERR:
	 clc			; Indicate all is OK

	 jmp	 EXIT		; Join common exit code

EXIT_CLOSE:
	 mov	 bx,DEV_HNDL	; Get device handle
	 or	 bx,bx		; Is it open?
	 jz	 @F		; Jump if not

	 DOSCALL @CLOSF2	; Close the handle
@@:

	 clc			; Indicate all is OK
EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore caller's registers

	 ret			; ... to caller

	 assume  ds:nothing,es:nothing,ss:nothing
MAX_PRESENT endp		; End of MAX_PRESENT routine


;*****************************************************************************

	  NPPROC  FMT_BYTE -- Format AX to Hex at ES:DI
	  assume  ds:nothing,es:PGROUP,ss:nothing
COMMENT |

Format AL to Hex at ES:DI

|

	  REGSAVE <ax,bx,cx,dx>  ; Save registers

	  lea	  bx,HEXTABLE	 ; DS:BX ==> translate table
	  mov	  cx,2		 ; # hex digits in a word
	  mov	  dl,al 	 ; Copy to test
FMT_BYTE1:
	  rol	  dl,1		 ; Copy the high-order digit
	  rol	  dl,1		 ; Copy the high-order digit
	  rol	  dl,1		 ; Copy the high-order digit
	  rol	  dl,1		 ; Copy the high-order digit
	  mov	  al,dl 	 ; Copy to XLAT register
	  and	  al,0Fh	 ; Isolate hex digit
	  xlat	  HEXTABLE	 ; Translate to ASCII
	  stosb 		 ; Save into output area

	  loop	  FMT_BYTE1	 ; Jump if more digits to convert

	  REGREST <dx,cx,bx,ax>  ; Restore

	  ret			 ; Return to caller

	  assume  ds:nothing,es:nothing,ss:nothing

FMT_BYTE endp			 ; End FMT_BYTE procedure


;*****************************************************************************

	  NPPROC  FMT_WORD -- Format AL to Hex at ES:DI
	  assume  ds:nothing,es:PGROUP,ss:nothing
COMMENT |

Format AX to Hex at ES:DI

|

	  REGSAVE <ax,bx,cx,dx>  ; Save registers

	  lea	  bx,HEXTABLE	 ; DS:BX ==> translate table
	  mov	  cx,4		 ; # hex digits in a word
	  mov	  dx,ax 	 ; Copy to test
FMT_WORD1:
	  rol	  dx,1		 ; Copy the high-order digit
	  rol	  dx,1		 ; Copy the high-order digit
	  rol	  dx,1		 ; Copy the high-order digit
	  rol	  dx,1		 ; Copy the high-order digit
	  mov	  al,dl 	 ; Copy to XLAT register
	  and	  al,0Fh	 ; Isolate hex digit
	  xlat	  HEXTABLE	 ; Translate to ASCII
	  stosb 		 ; Save into output area

	  loop	  FMT_WORD1	 ; Jump if more digits to convert

	  REGREST <dx,cx,bx,ax>  ; Restore

	  ret			 ; Return to caller

	  assume  ds:nothing,es:nothing,ss:nothing

FMT_WORD endp			 ; End FMT_WORD procedure


;***************************************************************************

	 NPPROC  FMT_BASE10 -- Convert From Binary to Base 10
	 assume  ds:nothing,es:PGROUP,ss:nothing
COMMENT|

FMT_BASE -- Convert the number in EAX to ASCII in base 10 storing the
low-order digit of the # at ES:DI.

On entry:
AX	 =	 Number that needs to be displayed
ES:DI	 ==>	 next byte to left of the number

Note :

Maximum Hex number is	  FFFF FFFF
	Dec ...       4,294,967,295

|

	 REGSAVE <ax,bx,cx,dx,si,bp> ; Save all registers

; Setup the conversion

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB
	 mov	 cx,10		; Set up BASE as decimal (Base 10)
	 mov	 bp,8		; Go through (up to) this many times

; Perform the conversion (place each byte in display)

FMT_BASE_LOOP:
	 xor	 dx,dx		; Zero high-order dword for division

	 div	 cx		; Divide (DX:AX / CX => AX Rem DX)
	 lea	 si,HEXTABLE	; Get address of table
	 add	 si,dx		; Offset into table

	 movsb			; Store in result
	 nop			; S16 macro

	 and	 ax,ax		; Check for zero quotient
	 jz	 short FMT_BASE_EXIT ; That's all folks

	 dec	 bp		; Check for last digit
	 jnz	 short FMT_BASE_LOOP ; Not done yet
FMT_BASE_EXIT:
	 popf			; Restore flags

	 REGREST <bp,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FMT_BASE10 endp 		; End FMT_BASE10 procedure


;***************************************************************************

CODE	 ends			; End CODE segment

	 END	 ZEPPO	; End ZEPPO module




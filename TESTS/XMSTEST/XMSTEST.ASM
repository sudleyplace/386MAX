;' $Header:   P:/PVCS/MISC/XMSTEST/XMSTEST.ASV   1.2   22 Feb 1994 12:48:16   HENRY  $

	 title	 XMSTEST -- XMS Tester
	 page	 58,122
	 name	 XMSTEST
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-94 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment TEXT,  byte-aligned,  public, class 'data'

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
	 include PTR.INC
	 include HMA.INC
	 include XMS.INC
	 include KEYCALL.INC
	 include XMS_TEST.INC
	 include VERSION.INC
.list

PGROUP	 group	 STACK,CODE,DATA,TEXT

; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 CMD_FLAG:byte
	 include XMS_CMD.INC

	 public  XMSDRV_VEC
XMSDRV_VEC dd	 ?		; Address of XMS driver controller

	 public  ERRMSG,ERRCODE
ERRMSG	 dw	 ?		; Offset of error message
ERRCODE  db	 ?		; Error code

	 public  XMS_QRYXMB,XMS_GETXMB,XMS_MODXMB,XMS_GETINF
XMS_QRYXMB db	 @XMS_QRYXMB	; Default query function
XMS_GETXMB db	 @XMS_GETXMB	; ...	  allocate ...
XMS_MODXMB db	 @XMS_MODXMB	; ...	  re-allocate ...
XMS_GETINF db	 @XMS_GETINF	; ...	  information ...

	 public  XMSVER,XMSDBG,XMSHMA,XMSHNDL,EXTSIZE
	 even
XMSVER	 dw	 ?		; Major/minor version #
XMSDBG	 dw	 ?		; Debugging version #
XMSHMA	 dw	 ?		; HMA availability:  1=Yes, 0=No
XMSHNDL  dw	 ?		; # handles to use
EXTSIZE  dw	 ?		; Size of extended memory

	 public  MSG_VER
MSG_VER  db	 'XMS version '
MSG_VER1 db	 '____, debugging version '
MSG_VER2 db	 '____.',CR,LF,EOS

	 public  MSG_HMA
MSG_HMA  dw	 PGROUP:MSG_HMA0
	 dw	 PGROUP:MSG_HMA1

	 public  MSG_HMA0,MSG_HMA1
MSG_HMA0 db	 'The HMA is NOT available.',CR,LF,EOS
MSG_HMA1 db	 'The HMA is available.',CR,LF,EOS

	 public  ERRTXT
ERRTXT	 dw	 PGROUP:ERR80
	 dw	 PGROUP:ERR81
	 dw	 PGROUP:ERR82
	 dw	 PGROUP:ERR8E
	 dw	 PGROUP:ERR8F
	 dw	 PGROUP:ERR90
	 dw	 PGROUP:ERR91
	 dw	 PGROUP:ERR92
	 dw	 PGROUP:ERR93
	 dw	 PGROUP:ERRA0
	 dw	 PGROUP:ERRA1
	 dw	 PGROUP:ERRA2
	 dw	 PGROUP:ERRA3
	 dw	 PGROUP:ERRA4
	 dw	 PGROUP:ERRA5
	 dw	 PGROUP:ERRA6
	 dw	 PGROUP:ERRA7
	 dw	 PGROUP:ERRA8
	 dw	 PGROUP:ERRA9
	 dw	 PGROUP:ERRAA
	 dw	 PGROUP:ERRAB
	 dw	 PGROUP:ERRAC
	 dw	 PGROUP:ERRAD
	 dw	 PGROUP:ERRB0
	 dw	 PGROUP:ERRB1
	 dw	 PGROUP:ERRB2

	 public  ERRNUM
ERRNUM	 db	 80h
	 db	 81h
	 db	 82h
	 db	 8Eh
	 db	 8Fh
	 db	 90h
	 db	 91h
	 db	 92h
	 db	 93h
	 db	0A0h
	 db	0A1h
	 db	0A2h
	 db	0A3h
	 db	0A4h
	 db	0A5h
	 db	0A6h
	 db	0A7h
	 db	0A8h
	 db	0A9h
	 db	0AAh
	 db	0ABh
	 db	0ACh
	 db	0ADh
	 db	0B0h
	 db	0B1h
	 db	0B2h
NERRNUM  equ	 $-ERRNUM	; # error codes

ERR80	 db	 'Function not implemented',CR,LF,EOS
ERR81	 db	 'VDISK detected',CR,LF,EOS
ERR82	 db	 'A20 error',CR,LF,EOS
ERR8E	 db	 'General XMS driver error',CR,LF,EOS
ERR8F	 db	 'Unrecoverable XMS driver error',CR,LF,EOS
ERR90	 db	 'HMA does not exist',CR,LF,EOS
ERR91	 db	 'HMA already in use',CR,LF,EOS
ERR92	 db	 'Request size less than HMAMIN',CR,LF,EOS
ERR93	 db	 'HMA not allocated',CR,LF,EOS
ERRA0	 db	 'All of extended memory is allocated',CR,LF,EOS
ERRA1	 db	 'All handles in use',CR,LF,EOS
ERRA2	 db	 'Handle invalid',CR,LF,EOS
ERRA3	 db	 'Move source handle invalid',CR,LF,EOS
ERRA4	 db	 'Move source offset invalid',CR,LF,EOS
ERRA5	 db	 'Move destination handle invalid',CR,LF,EOS
ERRA6	 db	 'Move destination offset invalid',CR,LF,EOS
ERRA7	 db	 'Move length invalid',CR,LF,EOS
ERRA8	 db	 'Destructive move overlap',CR,LF,EOS
ERRA9	 db	 'Parity error',CR,LF,EOS
ERRAA	 db	 'Block not locked',CR,LF,EOS
ERRAB	 db	 'Block locked',CR,LF,EOS
ERRAC	 db	 'Block lock count overflow',CR,LF,EOS
ERRAD	 db	 'Unable to lock block',CR,LF,EOS
ERRB0	 db	 'Smaller UMB available',CR,LF,EOS
ERRB1	 db	 'No UMBs available',CR,LF,EOS
ERRB2	 db	 'UMB segment number invalid',CR,LF,EOS
REASON	 db	 '様> Reason:  ',EOS

	 public  MSG_COPY
MSG_COPY db	 'XMS      -- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
	 db	 ' (C) Copyright 1988-94 Qualitas, Inc.',CR,LF,EOS

	 public  XLAT_TAB
XLAT_TAB db	 '0123456789ABCDEF'

	 public  LCLSTK,LCLSTKZ
LCLSTK	 dw	 256 dup (?)	; Local stack
LCLSTKZ  dw	 0		; End of the stack

DATA	 ends			; End DATA segment


TEXT	 segment byte public 'data' ; Start TEXT segment
TEXT	 ends			; End TEXT segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 CHECK_ARGS:near
	 extrn	 CHECK_MOV:near
	 extrn	 CHECK_HMA:near
	 extrn	 CHECK_XMB:near
	 extrn	 CHECK_A20:near
	 extrn	 CHECK_UMB:near
	 extrn	 CHECK_MOD:near
	 extrn	 CHECK_MOD2:near
	 extrn	 CHECK_LCK:near
	 extrn	 CHECK_EDGE:near
	 extrn	 MEM_SHRINK:near

.xlist
	 public  PSP_PARM_STRING
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
	 NPPROC  XMS -- XMS Tester
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

; Switch to local stack

	 lea	 sp,LCLSTKZ

; Display our copyright notice

	 DOSCALL @STROUT,MSG_COPY

; Check for command line arguments

	 call	 CHECK_ARGS	; Check 'em
	 jc	 short XMS_EXIT ; Jump if something went wrong

	 call	 MEM_SHRINK	; Shrink our memory usage
	 jc	 short XMS_ERR	; Jump if something went wrong

; Test the XMS system

	 call	 XMSTEST	; Test it
	 jnc	 short XMS_STAT ; Jump if all went well
XMS_ERR:
	 mov	 dx,ERRMSG	; DS:DX ==> error message
	 call	 DISPERR	; Display error message at DS:DX

	 mov	 al,ERRCODE	; Get the error code (if any)

	 cmp	 al,-1		; Check for not present
	 je	 short @F	; Jump if so

	 lea	 di,ERRNUM	; ES:DI ==> error numbers
	 mov	 cx,NERRNUM	; # error numbers
	 cld			; String ops forwardly
   repne scasb			; Search for it
	 jne	 short @F	; Jump if no match???

	 lea	 dx,REASON	; Display prefix
	 call	 DISPERR	; Display error message at DS:DX

	 sub	 di,1+offset es:ERRNUM ; Convert to origin-0
	 shl	 di,1		; Times two to index table of words
	 mov	 dx,ERRTXT[di]	; DS:DX ==> error message text
	 call	 DISPERR	; Display error message at DS:DX
@@:
XMS_STAT:
	 call	 XMSSTAT	; Display statistics
XMS_EXIT:
	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,ss:nothing

XMS	 endp			; End XMS procedure
	 NPPROC  XMSTEST -- XMS Tester
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Test XMS driver.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise (error message in ERRMSG)

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save registers

; Check for presence

	 DISPLAY '様> Checking for presence...'

	 mov	 ax,4300h	; Function to determine presence
	 int	 2Fh		; Request redirector service

	 cmp	 al,80h 	; Check for presence
	 SETMSG  "XMS driver not present"
	 MJ ne	 XMSTEST_ERR	; Jump if not present

; Request driver control address

	 DISPLAY '様> Requesting driver control address...'

	 push	 es		; Save for a moment

	 mov	 ax,4310h	; Function to get address
	 int	 2Fh		; Request redirector service
	 assume  es:nothing	; Tell the assembler about it

	 mov	 XMSDRV_VEC.VOFF,bx ; Save for later use
	 mov	 XMSDRV_VEC.VSEG,es

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

; Get the version #

	 DISPLAY '様> Requesting version #...'

	 mov	 ah,@XMS_VERS	; Code to get version #
	 call	 XMSDRV_VEC	; Request XMS service

	 and	 ax,ax		; Izit valid?
	 SETMSG  "Unable to request version #.",XMS
	 MJ z	 XMSTEST_ERR	; Jump if not

	 mov	 XMSVER,ax	; Save major/minor version #
	 mov	 XMSDBG,bx	; Save debugging   version #
	 mov	 XMSHMA,dx	; Save HMA availability:  1=Yes, 0=No

; Display the version #

	 mov	 ax,XMSVER	; Get the value
	 lea	 di,MSG_VER1	; Put formatted value here
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 mov	 ax,XMSDBG	; Get the value
	 lea	 di,MSG_VER2	; Put formatted value here
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 DOSCALL @STROUT,MSG_VER ; Display it

	 mov	 bx,XMSHMA	; Get HMA availability
	 shl	 bx,1		; Times two to index table of words
	 mov	 dx,MSG_HMA[bx] ; DS:DX ==> message to display
	 DOSCALL @STROUT	; Display it

; Get size of extended memory

	 mov	 ah,88h 	; Code to get extended memory size
	 int	 15h		; Request BIOS service
	 mov	 EXTSIZE,ax	; Save for later use

; Allocate one XMB so we can get handle information

	 mov	 dx,0		; Allocate 0KB
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with DX = handle #

; Get # available handles

	 push	 dx		; Save for a moment
	 mov	 ah,@XMS_GETINF ; Code to get handle information
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with BH = lock count,
				;	      BL = # free handles
				;	      DX = block length in 1KB
	 pop	 dx		; Restore

	 xor	 bh,bh		; Zero to use as word
	 inc	 bx		; Count in the current handle
	 mov	 XMSHNDL,bx	; Save # free handles

; De-allocate the handle

	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

; Check the state of the A20 line

	 test	 CMD_FLAG,@CMD_A20 ; Test A20?
	 jz	 short @F	; Jump if not

	 call	 CHECK_A20	; Check it out
	 jc	 short XMSTEST_ERR ; Jump if error
@@:

; Check the HMA

	 test	 CMD_FLAG,@CMD_HMA ; Test HMA?
	 jz	 short @F	; Jump if not

	 cmp	 XMSHMA,1	; Izit available?
	 jne	 short @F	; Not today

	 call	 CHECK_HMA	; Check it out
	 jc	 short XMSTEST_ERR ; Jump if error
@@:

; Check the extended memory block size, allocate, and de-allocate

	 test	 CMD_FLAG,@CMD_XMB ; Test XMBs?
	 jz	 short @F	; Jump if not

	 call	 CHECK_XMB	; Check it out
	 jc	 short XMSTEST_ERR ; Jump if error
@@:

; Check the extended memory block move

	 test	 CMD_FLAG,@CMD_MOV ; Test moves?
	 jz	 short @F	; Jump if not

	 call	 CHECK_MOV	; Check it out
	 jc	 short XMSTEST_ERR ; Jump if error
@@:

; Check the upper memory block size, allocate, and de-allocate

	 test	 CMD_FLAG,@CMD_UMB ; Test UMBs?
	 jz	 short @F	; Jump if not

	 call	 CHECK_UMB	; Check it out
	 jc	 short XMSTEST_ERR ; Jump if error
@@:

; Check on reallocation, primary function

	 test	 CMD_FLAG,@CMD_MOD ; Test reallocation?
	 jz	 short @F	; Jump if not

	 call	 CHECK_MOD	; Check it out
	 jc	 short XMSTEST_ERR ; Jump if error

; Check on reallocation, sedondary function

	 call	 CHECK_MOD2	; Check it out
	 jc	 short XMSTEST_ERR ; Jump if error
@@:

; Check on locking

	 test	 CMD_FLAG,@CMD_LCK ; Test locking?
	 jz	 short @F	; Jump if not

	 call	 CHECK_LCK	; Check it out
	 jc	 short XMSTEST_ERR ; Jump if error
@@:

; Check on edge conditions

	 test	 CMD_FLAG,@CMD_EDG ; Test edge conditions?
	 jz	 short @F	; Jump if not

	 call	 CHECK_EDGE	; Check it out
	 jc	 short XMSTEST_ERR ; Jump if error
@@:






	 clc			; Indicate all went well

	 jmp	 short XMSTEST_EXIT ; Join common exit code

XMSTEST_ERR:
	 stc			; Indicate we had a problem
XMSTEST_EXIT:
	 REGREST <es,ds>	; Restore
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

XMSTEST  endp			; End XMSTEST procedure
	 NPPROC  XMSSTAT -- Display Statistics
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display statistics

|

	 pusha			; Save all GP registers
	 REGSAVE <>		; Save registers




	 REGREST <>		; Restore
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

XMSSTAT  endp			; End XMSSTAT procedure
	 NPPROC  DB2HEX -- Binary AL To Hex at ES:DI & Following
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 cx,2		; # hex digits to convert (left-to-right)
	 lea	 bx,XLAT_TAB	; DS:BX ==> translate table
	 mov	 dl,al		; Copy for testing
DB2HEX_LOOP:
	 push	 cx		; Save for a moment

	 mov	 cl,4		; Shift amount
	 rol	 dl,cl		; Rotate high-order nibble to low-order
	 mov	 al,dl		; Copy to format
	 and	 al,0Fh 	; Isolate nibble
	 xlat	 XLAT_TAB	; Translate to ASCII

	 stosb

	 pop	 cx		; Restore loop counter

	 loop	 DB2HEX_LOOP	; Go around again

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DB2HEX	 endp			; End DB2HEX procedure
	 NPPROC  DW2HEX -- Binary AX To Hex at ES:DI & Following
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 cx,4		; # hex digits to convert (left-to-right)
	 lea	 bx,XLAT_TAB	; DS:BX ==> translate table
	 mov	 dx,ax		; Copy for testing
DW2HEX_LOOP:
	 push	 cx		; Save for a moment

	 mov	 cl,4		; Shift amount
	 rol	 dx,cl		; Rotate high-order nibble to low-order
	 mov	 al,dl		; Copy to format
	 and	 al,0Fh 	; Isolate nibble
	 xlat	 XLAT_TAB	; Translate to ASCII

	 stosb

	 pop	 cx		; Restore loop counter

	 loop	 DW2HEX_LOOP	; Go around again

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DW2HEX	 endp			; End DW2HEX procedure
	 NPPROC  DISPERR -- Display Error Message
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display error message

On entry:

DS:DX	 ==>	 error message ending with EOS

|

	 REGSAVE <ax,bx,cx,dx,di> ; Save registers

	 cld			; String ops forwardly

	 mov	 di,dx		; ES:DI ==> error message text
	 mov	 al,EOS 	; Search for this
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
				; CX = -(len+2)
	 neg	 cx		; CX =	 len+2
	 sub	 cx,2		; CX =	 len
	 mov	 bx,@STD_ERR	; Display to standard error
	 DOSCALL @WRITF2	; Display it

	 REGREST <di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISPERR  endp			; End DISPERR procedure

CODE	 ends			; End CODE segment

	 MEND	 XMS		; End XMSTEST module

;' $Header:   P:/PVCS/MISC/VCPITEST/VCPITEST.ASV   1.1   22 Feb 1994 12:32:36   HENRY  $

	 title	 VCPITEST -- VCPI Tester
	 page	 58,122
	 name	 VCPITEST
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-94 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment TEXT,  byte-aligned,  public, class 'data'
	       Tail    segment DTAIL, para-aligned,  public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, July, 1988.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include 386.INC
	 include KEYCALL.INC
	 include VCPI.INC
	 include VERSION.INC

	 include EMM2CALL.INC
	 include VCP_TEST.INC
.list

PGROUP	 group	 STACK,CODE,DATA,TEXT,DTAIL

; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 PORT67:word

	 extrn	 CMD_FLAG:word
	 include VCP_FLAG.INC

	 public  HEXTABLE
HEXTABLE db	 '0123456789ABCDEF'

	 public  TOTSIZE,PHYSIZE
TOTSIZE  dw	 ?		; Total extended memory size
PHYSIZE  dw	 ?		; Total physical memory (including first 1MB)

	 public  ERRMSG,ERRCODE
ERRMSG	 dw	 ?		; Offset of error message
ERRCODE  db	 ?		; Error code
	 even

	 public  ERRTXT
ERRTXT	 dw	 PGROUP:ERR00
	 dw	 PGROUP:ERR84
	 dw	 PGROUP:ERR88
	 dw	 PGROUP:ERR8A
	 dw	 PGROUP:ERR8F

	 public  ERRNUM
ERRNUM	 db	 00h
	 db	 84h
	 db	 88h
	 db	 8Ah
	 db	 8Fh
NERRNUM  equ	 $-ERRNUM	; # error codes

ERR00	 db	 'Successful return',CR,LF,EOS
ERR84	 db	 'Invalid function',CR,LF,EOS
ERR88	 db	 'Insufficient memory',CR,LF,EOS
ERR8A	 db	 'Invalid physical address',CR,LF,EOS
ERR8F	 db	 'Invalid subfunction',CR,LF,EOS

	 public  REASON
REASON	 db	 '様> Reason:  ',EOS

	 public  VCPIVER
VCPIVER  dw	 ?		; VCPI version #

	 public  MSG_COPY
MSG_COPY db	 'VCPITEST -- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
	 db	 ' -- VCPI Test Program',CR,LF
	 db	 '   (C) Copyright 1988-94 Qualitas, Inc.  GNU General Public License version 3.',CR,LF,EOS

	 public  MSG_VER
MSG_VER  db	 'VCPI version '
MSG_VER1 db	 '____.',CR,LF,EOS

	 public  MSG_NOT386
MSG_NOT386 db	 BEL,'様> Wrong machine type',CR,LF
	 db	     '    Must run on an 80386.',CR,LF
MSG_NOT386_LEN equ $-MSG_NOT386 ; Length of ...

	 public  MSG_NOTVM
MSG_NOTVM db	 BEL,'様> Must be Virtual 8086 Mode',CR,LF
	 db	     '    Enable the VM86 handler.',CR,LF
MSG_NOTVM_LEN equ $-MSG_NOTVM	; Length of ...

	 public  XLAT_TAB
XLAT_TAB db	 '0123456789ABCDEF'

	 public  LCLSTK,LCLSTKZ
	 align	 4		; Ensure dword-aligned
LCLSTK	 dw	 256 dup (?)	; Local stack
LCLSTKZ  dw	 0		; End of the stack

DATA	 ends			; End DATA segment


TEXT	 segment use16 byte public 'data' ; Start TEXT segment
TEXT	 ends			; End TEXT segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	 segment use16 para public 'data' ; Start DTAIL segment
	 assume  ds:PGROUP

	 public  ZTAIL
ZTAIL	 label	 byte

DTAIL	 ends			; End DTAIL segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 CHECK_ARGS:near
	 extrn	 CHECK_EMS:near
	 extrn	 CHECK_ALLOC:near
	 extrn	 CHECK_PHYS:near
	 extrn	 CHECK_DBG:near
	 extrn	 CHECK_IBV:near
	 extrn	 CHECK_EPM:near

.xlist
	 public  PSP_PARM_STRING
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
	 NPPROC  VCPI -- VCPI Tester
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

; Switch to local stack

	 lea	 sp,LCLSTKZ

; Display our copyright notice

	 DOSCALL @STROUT,MSG_COPY

; Check the CPU

	 call	 CHECK_CPUID	; Ensure we're on a 386 processor
	 jc	 short VCPI_EXIT ; Jump if not

; Ensure we're in Virtual 8086 mode

	 call	 CHECK_VM86	; Check on it
	 jc	 short VCPI_EXIT ; Jump if not

; Check for arguments

	 call	 CHECK_ARGS	; Check on 'em
	 jc	 short VCPI_EXIT ; Jump if error

; Test the VCPI system

	 call	 VCPITEST	; Test it
	 jnc	 short VCPI_EXIT ; Jump if all went well

	 mov	 dx,ERRMSG	; DS:DX ==> error message
	 call	 DISPERR	; Display error message at DS:DX

	 mov	 al,ERRCODE	; Get the error code (if any)

	 cmp	 al,-1		; Check for not present
	 je	 short VCPI_EXIT ; Jump if so

	 lea	 di,ERRNUM	; ES:DI ==> error numbers
	 mov	 cx,NERRNUM	; # error numbers
	 cld			; String ops forwardly
   repne scasb			; Search for it
	 jne	 short VCPI_EXIT ; Jump if no match???

	 lea	 dx,REASON	; DS:DX ==> error message
	 call	 DISPERR	; Display error message at DS:DX

	 sub	 di,1+offset es:ERRNUM ; Convert to origin-0
	 shl	 di,1		; Times two to index table of words
	 mov	 dx,ERRTXT[di]	; DS:DX ==> error message text
	 call	 DISPERR	; Display error message at DS:DX
VCPI_EXIT:
	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI	 endp			; End VCPI procedure
	 NPPROC  VCPITEST -- VCPI Tester
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test VCPI driver.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise (error message in ERRMSG)

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save registers

; Check for presence

	 DISPLAY '様> Checking for presence of EMS/VCPI driver...'

	 call	 CHECK_EMS	; Check for presence
	 SETMSG  "EMS driver not present"
	 MJ c	 VCPITEST_ERR	; Jump if not present

	 DISPLAY '様> Checking for presence of VCPI driver...'

	 VCPIBACK @VCPI_PRES	; Get presence function
	 mov	 VCPIVER,bx	; Save version #

	 cmp	 ah,00h 	; Check for presence
	 SETMSG  "VCPI driver not present"
	 MJ ne	 VCPITEST_ERR	; Jump if not present

; Display the version #

	 mov	 ax,VCPIVER	; Get the value
	 lea	 di,MSG_VER1	; Put formatted value here
	 call	 BIN2WORD	; Convert AX to hex at ES:DI

	 DOSCALL @STROUT,MSG_VER ; Display it

; Check memory allocations and de-allocations

	 call	 CHECK_ALLOC	; Check it out
	 jc	 short VCPITEST_ERR ; Jump if error

; Check debug registers

	 call	 CHECK_DBG	; Check it out
	 jc	 short VCPITEST_ERR ; Jump if error

; Check Interrupt Base Value settings

	 call	 CHECK_IBV	; Check it out
	 jc	 short VCPITEST_ERR ; Jump if error

; Check entering protected mode

	 call	 CHECK_EPM	; Check it out
	 jc	 short VCPITEST_ERR ; Jump if error

; Check physical addresses

	 call	 CHECK_PHYS	; Check it out
	 jc	 short VCPITEST_ERR ; Jump if error

	 clc			; Indicate all went well

	 jmp	 short VCPITEST_EXIT ; Join common exit code

VCPITEST_ERR:
	 stc			; Indicate we had a problem
VCPITEST_EXIT:
	 REGREST <es,ds>	; Restore
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPITEST endp			; End VCPITEST procedure
	 NPPROC  CHECK_CPUID -- Check On CPU Identifier
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're running on an 80386 processor.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 push	 sp		; First test for a 286/386
	 pop	 ax

	 cmp	 ax,sp		; Same?
	 jne	 short CHECK_CPUID_ERR ; No, it's neither a 286 nor a 386

; Get size of extended memory

	 mov	 ah,88h 	; Function code to get size of extended memory
	 int	 15h		; Request service, result in AX in 1KB blocks

	 mov	 TOTSIZE,ax	; Save for later use
	 add	 ax,1024	; Plus first megabyte
	 mov	 PHYSIZE,ax	; Save as top of physical memory

; Now distinguish 286 from 386

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
	 mov	 cx,MSG_NOT386_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOT386 ; Tell 'em the bad news

	 stc			; Indicate we have a problem
CHECK_CPUID_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPUID endp		; End CHECK_CPUID procedure
	 NPPROC  CHECK_VM86 -- Check on Virtual 8086 Mode
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're in Virtual 8086 Mode.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 smsw	 ax		; Get machine status word

	 test	 ax,mask $PE	; Test the Protect Enable bit
	 jnz	 short CHECK_VM86_EXIT ; Jump if we are (note CF=0)

	 mov	 cx,MSG_NOTVM_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOTVM ; Tell 'em the bad news

	 stc			; Indicate we failed
CHECK_VM86_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VM86 endp 		; End CHECK_VM86 procedure
	 NPPROC  BIN2DWORD -- Convert Binary EAX to Hex at ES:DI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 rol	 eax,16 	; Swap order
	 call	 BIN2WORD	; Convert AX to hex at ES:DI

	 rol	 eax,16 	; Swap order
	 call	 BIN2WORD	; Convert AX to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2DWORD endp			; End BIN2DWORD procedure
	 NPPROC  BIN2WORD -- Convert Binary AX to Hex at ES:DI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 rol	 ax,8		; Swap order
	 call	 BIN2BYTE	; Convert AL to hex at ES:DI

	 rol	 ax,8		; Swap order
	 call	 BIN2BYTE	; Convert AL to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2WORD endp			; End BIN2WORD procedure
	 NPPROC  BIN2BYTE -- Convert Binary AL to Hex at ES:DI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 rol	 al,4		; Swap order
	 call	 BIN2DIGIT	; Convert low-order digit in AL to hex at ES:DI

	 rol	 al,4		; Swap order
	 call	 BIN2DIGIT	; Convert low-order digit in AL to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2BYTE endp			; End BIN2BYTE procedure
	 NPPROC  BIN2DIGIT -- Convert Low-order Binary Digit in AL to Hex at ES:DI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

ES:DI	 ==>	 place to put high-order digit of output

On exit:

ES:DI	 ==>	 (updated)

|

	 REGSAVE <ax,bx>	; Save registers

	 lea	 bx,HEXTABLE	; DS:BX ==> translate table
	 and	 al,@NIB0	; Isolate the digit
	 xlat	 HEXTABLE
	 stosb

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2DIGIT endp			; End BIN2DIGIT procedure
	 NPPROC  DISPERR -- Display Error Message
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
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

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPERR  endp			; End DISPERR procedure

CODE	 ends			; End CODE segment

	 MEND	 VCPI		; End VCPITEST module

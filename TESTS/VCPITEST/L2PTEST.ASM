;' $Header:   P:/PVCS/MISC/VCPITEST/L2PTEST.ASV   1.1   22 Feb 1994 12:19:24   HENRY  $

	 title	 L2PTEST -- Linear To Physical Tester
	 page	 58,122
	 name	 L2PTEST

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1989-94 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, May, 1989.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include PTR.INC
	 include INTVEC.INC
	 include DEVDRV.INC
	 include CPUFLAGS.INC
	 include EMMCALL.INC
	 include 386.INC
	 include VCPI.INC
.list

PGROUP	 group	 STACK,CODE,DATA


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 public  EMSNAME
EMSNAME  db	 'EMMXXXX0'     ; EMS driver name
EMSNAME_LEN equ  $-EMSNAME	; Length of ...

	 public  LCLSTK,LCLSTKZ
LCLSTK	 db	 100h dup (?)	; Local stack
LCLSTKZ  dw	 0		; Top of stack

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP
.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
	 NPPROC  L2PTEST -- Linear to Physical Tester
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

Linear to physical address tester.

The routines of interest are

VCPI_PRES	 Determines whether or not a VCPI handler is present

LIN2PHYS	 Translates a linear address to a physical address

PHYS_SPAN	 Determines the span of contiguous physical memory

|

	 lea	 sp,LCLSTKZ	; Switch to local stack

	 call	 VCPI_PRES	; Determine whether or not VCPI handler present

	 and	 ax,ax		; Izit present?
	 jz	 short L2PTEST_EXIT ; Not this time

	 mov	 bx,1234h	; Sample segment
	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 bx,5678h	; Sample offset
	 mov	 cx,9ABCh	; Sample length in bytes
	 call	 PHYS_SPAN	; Determine physical span of linear address
				; in ES:BX for CX bytes
				; On return EDX = initial physical address
				;	     CX = byte span in contiguous
				;		  physical memory from ES:BX


L2PTEST_EXIT:
	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing

L2PTEST  endp			; End L2PTEST procedure
	 NPPROC  PHYS_SPAN -- Determine Physical Address Span
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Determine the physical span of a linear address

On entry:

ES:BX	 ==>	 linear address of transfer
CX	 =	 length of transfer in bytes

On exit:

EDX	 =	 corresponding physical address of 4KB block
		 which contains ES:BX
CX	 =	 # contiguous bytes of physical memory starting at ES:BX

If CX=0, then error

|

PHYS_STR struc

PHYS_INIT dd	 ?		; Initial physical address
PHYS_CNT  dw	 ?		; Initial physical byte count

PHYS_STR ends

	 push	 bp		; Prepare to address the stack
	 sub	 sp,size PHYS_STR ; Make room on stack for structure
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,bx,esi,es> ; Save registers

; Compute 32-bit linear address

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,es		; Copy starting segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 edx,bx 	; Copy offset, zero upper word
	 add	 eax,edx	; Add to get 32-bit linear address

; Determine whether or not we're in VM86 mode

	 smsw	 bx		; Save machine status word

	 test	 bx,mask $PE	; Check the protect enable bit
	 jz	 short PHYS_SPAN_REAL ; Jump if we're in real mode

; Compute residue in initial 4KB block
; Note if already on 4KB boundary, initial count is 0

	 mov	 bx,ax		; Copy low-order word
	 add	 bx,4*1024	; Plus 4KB
	 neg	 bx		; Negate to subtract from zero
	 and	 bx,4*1024-1	; Modulo 4KB

; Ensure residue is no larger than total count

	 cmp	 bx,cx		; Use the smaller
	 jbe	 short @F	; Jump if residue is smaller

	 mov	 bx,cx		; Use actual amount
@@:
	 mov	 [bp].PHYS_CNT,bx ; Save as initial contiguous byte count
	 sub	 cx,bx		; Reduce total length by residue in 1st block

; Perform initial translation

	 call	 NORMALIZE	; Normalize EAX into ES:BX
	 assume  es:nothing	; Tell the assembler about it

	 call	 LIN2PHYS	; Translate ES:BX to physical address in EDX
	 jc	 short PHYS_SPAN_ERR ; Jump if error

	 mov	 [bp].PHYS_INIT,edx ; Save initial address for later use
	 mov	 esi,edx	; Save for comparison

	 jcxz	 PHYS_SPAN_DONE ; Jump if transfer fits in 1st block
PHYS_SPAN_NEXT:
	 add	 eax,4*1024	; Skip to next 4KB linear address
	 add	 esi,4*1024	; Skip to next 4KB physical address

	 call	 NORMALIZE	; Normalize EAX into ES:BX
	 assume  es:nothing	; Tell the assembler about it

	 call	 LIN2PHYS	; Translate ES:BX to physical address in EDX
	 jc	 short PHYS_SPAN_ERR ; Jump if error

	 cmp	 edx,esi	; Check for contiguous physical memory
	 jne	 short PHYS_SPAN_DONE ; Jump if no longer contiguous

; Add into physical count 4KB or CX whichever is smaller

	 mov	 dx,4*1024	; Get maximum size

	 cmp	 cx,dx		; Use the smaller
	 jae	 short @F	; Jump if DX is smaller

	 mov	 dx,cx		; CX is smaller
@@:
	 add	 [bp].PHYS_CNT,dx ; Count in another block

	 sub	 cx,dx		; Less a 4KB block
	 jnz	 short PHYS_SPAN_NEXT ; Jump if more memory to check
PHYS_SPAN_DONE:
	 mov	 edx,[bp].PHYS_INIT ; Get initial physical address
	 mov	 cx,[bp].PHYS_CNT ; Get # contiguous physical bytes

	 jmp	 short PHYS_SPAN_EXIT ; Join common exit code

PHYS_SPAN_REAL:
	 mov	 edx,eax	; Copy 32-bit linear address

	 jmp	 short PHYS_SPAN_EXIT ; Join common exit code

PHYS_SPAN_ERR:
	 xor	 cx,cx		; Indicate error
PHYS_SPAN_EXIT:
	 REGREST <es,esi,bx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 add	 sp,size PHYS_STR ; Strip structure from stack

	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

PHYS_SPAN endp			; End PHYS_SPAN procedure
	 NPPROC  NORMALIZE -- Normalize EAX into ES:BX
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Convert 32-bit linear address into normalized segment:offset

On entry:

EAX	 =	 32-bit linear address

On exit:

ES:BX	 =	 normalized address with BX < 0010h

|

	 mov	 bx,ax		; Copy low-order word
	 and	 bx,000Fh	; Isolate low-order nibble
	 ror	 eax,4-0	; Convert from bytes to paras
	 mov	 es,ax		; ES:BX ==> normalized address
	 assume  es:nothing	; Tell the assembler about it
	 rol	 eax,4-0	; Convert from paras to bytes

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

NORMALIZE endp			; End NORMALIZE procedure
	 NPPROC  LIN2PHYS -- Linear to Physical Address Translator
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Linear to physical address handler

On entry:

ES:BX	 ==>	 linear address of transfer

On exit:

CF	 =	 0 if translation successful
	 =	 1 otherwise

EDX	 =	 corresponding physical address of 4KB block
		 which contains ES:BX

|

	 REGSAVE <ax,ecx>	; Save registers

	 xor	 ecx,ecx	; Zero entire register
	 mov	 cx,es		; Copy segment
	 shl	 ecx,4-0	; Convert from paras to bytes
	 movzx	 edx,bx 	; Copy offset, clear upper word
	 add	 ecx,edx	; Add to get 32-bit linear address
	 shr	 ecx,12-0	; Convert from bytes to 4KB

; Determine whether or not we're in VM86 mode

	 smsw	 ax		; Save machine status word

	 test	 ax,mask $PE	; Check the protect enable bit
	 jz	 short LIN2PHYS_REAL ; Jump if we're in real mode

	 EMMCALL @VCPI_GETPHYS	; Translate linear to physical address

	 or	 ah,ah		; Check for error
	 jnz	 short LIN2PHYS_ERR ; Jump if error

	 clc			; Indicate all went well

	 jmp	 short LIN2PHYS_EXIT ; Join common exit code

LIN2PHYS_REAL:
	 shl	 ecx,12-0	; Convert from 4KB to bytes
	 mov	 edx,ecx	; Copy to result register

	 clc			; Indicate all went well

	 jmp	 short LIN2PHYS_EXIT ; Join common exit code

LIN2PHYS_ERR:
	 stc			; Indicate something went wrong
LIN2PHYS_EXIT:
	 REGREST <ecx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

LIN2PHYS endp			; End LIN2PHYS procedure
	 NPPROC  VCPI_PRES -- VCPI Presence Detector
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

VCPI presence detector

On exit:

AX	 =	 1 if present
	 =	 0 if not

|

; Ensure we're on a 386/486

	 call	 CHECK_CPUID	; Ensure we're on a 386/486 processor
	 jc	 short VCPI_PRES_NOT ; Jump if not

; Check on EMS handler using the INT 67h method

	 call	 CHECK_EMS	; Ensure EMS handler present
	 jc	 short VCPI_PRES_NOT ; Jump if not

; Ensure VCPI handler present

	 push	 bx		; Save for a moment
	 EMMCALL @VCPI_PRES	; Detect VCPI presence
				; BH = major version #
				; BL = minor ...
	 pop	 bx		; Restore

	 or	 ah,ah		; Check for error
	 jnz	 short VCPI_PRES_NOT ; Jump if error

	 mov	 ax,1		; Indicate present

	 jmp	 short VCPI_PRES_EXIT ; Join common exit code

VCPI_PRES_NOT:
	 xor	 ax,ax		; Indicate not present
VCPI_PRES_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

VCPI_PRES endp			; End VCPI_PRES procedure
	 NPPROC  CHECK_CPUID -- Check On CPU Identifier
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Ensure we're running on an 80386 or 80486 processor.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

N.B.:  Use only 8088 instructions!!!!

|

	 REGSAVE <ax>		; Save register

	 push	 sp		; First test for a 286/386/486
	 pop	 ax

	 cmp	 ax,sp		; Same?
	 jne	 short CHECK_CPUID_ERR ; No, it's neither a 286, 386, nor 486

; Now distinguish 286 from 386/486

	 pushf			; Save flags for a moment

	 mov	 ax,mask $IOPL	; Try to set IOPL bits in flag register

	 push	 ax
	 popf

	 pushf			; Get flags back into AX
	 pop	 ax

	 popf			; Restore original flags

	 test	 ax,mask $IOPL	; Any bits set?
	 clc			; Assume OK
	 jnz	 short CHECK_CPUID_EXIT ; Yes, so it's a 386/486
CHECK_CPUID_ERR:
	 stc			; Indicate we have a problem
CHECK_CPUID_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_CPUID endp		; End CHECK_CPUID procedure
	 NPPROC  CHECK_EMS -- Check on EMS Handler
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Determine whether or not there's an EMS handler present

On exit:

CF	 =	 0 if EMS handler present
	 =	 1 if not

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 mov	 ax,seg INTVEC	; Get segment of interrupt vectors
	 mov	 es,ax		; Address it
	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 ax,INT00_VEC.VSEG[67h*type INT00_VEC] ; Get segment of INT 67h

	 and	 ax,ax		; Ensure non-zero
	 jz	 short CHECK_EMS_ERR ; Not this time

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 lea	 di,es:[0].DD_NAME ; ES:DI ==> EMS name if present
	 lea	 si,EMSNAME	; DS:SI ==> local copy of EMS name
	 mov	 cx,EMSNAME_LEN ; CX = # bytes in ...
	 cld			; Ensure string ops forwards
    repe cmps	 EMSNAME[si],es:[di] ; Compare 'em
	 je	 short CHECK_EMS_EXIT ; Jump if match (note CF=0)
CHECK_EMS_ERR:
	 stc			; Indicate not present
CHECK_EMS_EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_EMS endp			; End CHECK_EMS procedure

CODE	 ends			; End CODE segment

	 MEND	 L2PTEST	; End L2PTEST module

;' $Header:   P:/PVCS/MAX/386MAX/QMAX_I15.ASV   1.2   30 May 1997 10:44:40   BOB  $
	 title	 QMAX_I15 -- 386MAX INT 15h Handler
	 page	 58,122
	 name	 QMAX_I15

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include KEYCALL.INC
	 include ALLMEM.INC
	 include BIOSCONF.INC
	 include MASM5.MAC

	 include PDTGRP.INC
	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
.list

PGROUP	 group	 CODE,ECODE,EDATA
FGROUP	 group	 FDATA
IGROUP	 group	 LCODE,LDATA,ICODE


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

if @OEM_WIN3
	 extrn	 LOWWIN3_CB:byte
	 extrn	 VIRT_DEV_DPFE:byte
endif				; IF @OEM_WIN3

	 extrn	 RESINT15_INT:byte
	 extrn	 RESINT15_OLD:near

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 XMS_FLAG:word	; **BOTH** high and low memory
	 include QMAX_XMS.INC

	 extrn	 EXTSIZE:dword

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC

	 extrn	 DB3_FLAG:word
	 include QMAX_DB3.INC

	 extrn	 LAST_INTCOM:dword
	 extrn	 LAST_INTFLG:dword
	 extrn	 MINBASE:dword
	 extrn	 TOPBASE:dword
	 extrn	 A20SUP:word
	 extrn	 PRGPDT:dword
	 extrn	 PPDTBBMSRC:dword
	 extrn	 PPDTBBMDST:dword

	 extrn	 CON4KB:dword
	 extrn	 CON1MB:dword
	 extrn	 CON1P1MB:dword

	 extrn	 HIMEM_CS:word

	 public  LAST_BBMSRC,LAST_BBMDST
LAST_BBMSRC dd	 -1		; Last BBM source address
LAST_BBMDST dd	 -1		; ...	   destin ...

	 public  LaBBMSRC,LaBBMDST
LaBBMSRC dd	 ?		; Linear address of BIOS block move source
LaBBMDST dd	 ?		; ...				    destin

	 public  ASTMIO_LO,ASTMIO_HI
ASTMIO_LO dd	 80F00000h	; Special AST memory-mapped I/O address, low
ASTMIO_HI dd	 80F00003h	; ...					 high

	 public  CPQMIO_LO,CPQMIO_HI
CPQMIO_LO dd	 80C00000h	; Special COMPAQ memory-mapped I/O address, low
CPQMIO_HI dd	 80C00001h	; ...					    high

	 public  OLD_SRC
OLD_SRC  dw	 ?		; Save area for old source word

	 public  CPQMIO_HIGH
CPQMIO_HIGH db	 0		; Default memory-mapped I/O high value

if @OEM_WIN3
	 public  EBIOS_CODE
EBIOS_CODE db	  72h, 19h	; JC   NO_STDEBIOS_FND
	 db	  8Ch,0C0h	; MOV  AX,ES
	 db	  0Bh,0C0h	; OR   AX,AX
	 db	  74h, 13h	; JZ   NO_STDEBIOS_FND
	 db	 0C1h,0E8h, 08h ; SHR  AX,08
EBIOS_LEN equ	 $-EBIOS_CODE	; Length of above code fragment
endif				; IF @OEM_WIN3

EDATA	 ends			; End EDATA segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MSG_CTRL:byte

FDATA	 ends			; End FDATA segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DS3:word

LDATA	 ends			; End LDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

if @OEM_DPMI
	 extrn	 INT15_DPMI:near
endif				; IF @OEM_DPMI

ICODE	 ends			; End ICODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_I15_ECODE
@QMAX_I15_ECODE:		; Mark module start in .MAP file

	 extrn	 INTPROC00Z:near
	 extrn	 INTPROC15:near
	 extrn	 GOREAL_REBOOT:near
	 extrn	 INT0D_IRETD:near
	 extrn	 GETSHIFT:near

	 extrn	 FFLUSH_TLB:far
	 extrn	 FWRAP_ENABLE:far
	 extrn	 FWRAP_DISABLE:far
	 extrn	 FENABLE_NMI:far

	 FPPROC  FGETSHIFT -- Get the Shift Key status
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Get the Shift Key status

Far call to GETSHIFT

On entry:

Same as to GETSHIFT

On exit:

Same as to GETSHIFT

|

	 call	 GETSHIFT	; Get the shift key status
				; returns CF signigficant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FGETSHIFT endp			; End FGETSHIFT procedure

ECODE	 ends			; End ECODE segment


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
	 assume  cs:IGROUP

	 public  @QMAX_I15_LCODE
@QMAX_I15_LCODE:		; Mark module start in .MAP file

	 FPPROC  INT15 -- INT 15h Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Direct INT 15h interrupt handler (instead of using the one
in low memory).

Caller's IP has been incremented past the instruction.

|

if @OEM_DPMI
	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jnz	 short @F	; Jump if so

; Ensure IGROUP is present

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 near ptr INTPROC15_LCL ; Jump if so (call as VM INT 15h)

	 jmp	 INT15_DPMI	; Run through our translator

@@:
endif				; IF @OEM_DPMI
	 cmp	 ah,87h 	; Izit BIOS block move?
	 je	 short INT15_STK ; Jump if it is

	 cmp	 [esp].NRM_CS,seg PGROUP ; Check against caller's CS
	 org	 $-2
	 public  INT15_HIMEM_CS
INT15_HIMEM_CS label near
	 org	 $+2
	 jne	 near ptr INTPROC15_LCL ; Jump to low memory handler

; Check against device driver's IP

	 cmp	 [esp].NRM_EIP.ELO,offset PGROUP:RESINT15_INT+2
	 jne	 near ptr INTPROC15_LCL ; Jump to low memory handler
INT15_STK:
	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 eax,[ebp].INTXX_EIP ; Get offset of INTCOM-restartable point
	 xchg	 eax,LAST_INTCOM ; Swap with previous frame offset
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 eax,0		; Save previous flag
	 mov	 [ebp].INTXX_ICOMLO,ax ; Save it
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_ICOMHI,ax ; Save it

	 jmp	 short EMU_INT15_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT15	 endp			; End INT15 procedure
	 NPPROC  EMU_INT15 -- System Request Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

System request interrupt handler.

Trap function calls

AH = 04 	 ABIOS function       (return with CF=1, AH=86h)
AH = 05 	 ABIOS function       (return with CF=1, AH=86h)
AH = 24 	 A20 functions
AX = 4F53	 User pressed Ctrl-Alt-Del (exit protected mode)
AH = 87 	 Block Move	      (return with CF=0, ZF=1, AH=00h if OK
				       return with CF=1, ZF=0, AH=86h if not)
AH = 88 	 Get extended size    (return with CF=0, AX=EXTSIZE)
AH = 89 	 Enter protected mode (return with CF=1, AH=86h)
AH = C0 	 Get BIOS configuration data
AH = C1 	 Get Extended BIOS Data Area segment

On entry:

Error code is on the stack.

PUSHAD has been done.

Caller's IP has been incremented past the instruction.

SS:EBP	 ==>	 INTXX_STR

|

	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it
EMU_INT15_COM:
	 mov	 [ebp].INTXX_INTNO,4*15h + offset PGROUP:INTPROC00Z ; Mark as
				; INT 15h
	 cld			; Ensure string ops forwardly

	 push	 DTE_PDT	; Setup FS with PDT selector
	 pop	 fs		; Address it
	 assume  fs:PDTGRP	; Tell the assembler about it

	 mov	 ax,[ebp].INTXX_EAX.ELO ; Get function code from AH
				; subfunction from AL (if present)

	 cmp	 ah,04h 	; Check for ABIOS function
	 je	 short INT15_ABIOS ; Handle separately

	 cmp	 ah,05h 	; Check for ABIOS function
	 je	 short INT15_ABIOS ; Handle separately

	 cmp	 ah,24h 	; Check for A20 functions
	 je	 short INT15_A20FN ; Handle separately

	 cmp	 ax,4F53h	; Ctrl-Alt-Del time?
	 je	 near ptr INT15_BOOT ; Jump if so

	 cmp	 ah,87h 	; Check for block move
	 je	 near ptr INT15_MOVE ; Handle separately

	 cmp	 ah,88h 	; Check for memory size
	 je	 near ptr INT15_SIZE ; Handle separately

	 cmp	 ah,89h 	; Check for enter protected mode
	 je	 near ptr INT15_PROT ; Handle separately

if @OEM_WIN3
	 cmp	 ah,0C0h	; Check for Get BIOS configuration data
	 je	 near ptr INT15_BIOSCFG ; Handle separately

	 cmp	 ah,0C1h	; Check for Get XBIOS Segment
	 je	 near ptr INT15_XBIOS ; Handle separately
endif				; IF @OEM_WIN3

	 mov	 ax,[ebp].INTXX_ICOMHI ; Get previous frame offset
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_ICOMLO ; Get previous frame offset
	 btr	 ax,$INTCOM_VAL ; Move previous setting to CF
	 setc	 LAST_INTFLG.LO ; Move previous setting to memory
	 mov	 LAST_INTCOM,eax ; Restore it

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off error code
INTPROC15_LCL:
	 FIXIJMP PGROUP:INTPROC15,DTE_CS2 ; Give it to the real mode handler

COMMENT|

ABIOS functions:

AH = 04
   = 05

|

INT15_ABIOS:
	 test	 DB3_FLAG,@DB3_ABIOS ; Signal NMI?
	 jz	 short @F	; Jump if not

	 or	 GLB_FLAG,@GLB_NMI ; Mark it as NMI time when we return
@@:
	 jmp	 short INT15_ERR86 ; Join common error code


COMMENT|

A20 functions:

On entry:	 Means: 		On exit (return code in AH):

AX = 2400	 Disable A20		CF = 0 success, = 1 failure
   = 2401	 Enable  A20		CF = 0 success, = 1 failure
   = 2402	 Query	 A20		AL = 00 disabled, = 01 enabled
   = 2403	 Query support		BX = Original A20SUP value

|

INT15_A20FN:
	 cmp	 al,01h 	; Izit Enable/Disable A20?
	 jb	 short INT15_A20DIS ; Jump if disable
	 je	 short INT15_A20ENA ; Jump if enable

	 cmp	 al,03h 	; Izit Query A20/Query support?
	 jb	 short INT15_A20QRY ; Jump if query
	 je	 short INT15_A20SUP ; Jump if query support
INT15_ERR86:
	 mov	 ah,86h 	; Universal error code

	 jmp	 INT15_ERRCOM1	; Join common error code


INT15_A20DIS:

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 FIXICALL PGROUP:FWRAP_ENABLE,DTE_CS2 ; Enable the 1MB wrap

	 jmp	 short INT15_A20COM ; Join common success code


INT15_A20ENA:

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap

	 jmp	 short INT15_A20COM ; Join common success code


INT15_A20QRY:
	 test	 GLB_FLAG,@GLB_1MB ; Izit enabled?
	 mov	 al,01h 	; Assume so
	 jnz	 short INT15_A20COM ; Jump if so

	 mov	 al,00h 	; Mark as disabled

	 jmp	 short INT15_A20COM ; Join common success code


INT15_A20SUP:
	 mov	 ax,A20SUP	; Get original A20 support value
	 mov	 [ebp].INTXX_EBX.ELO,ax ; Return in BX
INT15_A20COM:
	 mov	 ah,00h 	; Return success code

	 jmp	 INT15_DONE1	; Join common exit code

COMMENT|

Function AX=4F53
Reboot the system

|

INT15_BOOT:
	 FIXICALL PGROUP:FGETSHIFT,DTE_CS2 ; Return with shift states in AL
	 assume  gs:AGROUP	; Tell the assembler about it

	 and	 al,(mask $DALT) or (mask $DCTL) ; Isolate just these two

	 cmp	 al,(mask $DALT) or (mask $DCTL) ; Ctrl and Alt pressed?
	 jne	 near ptr INT15_XCAD; Not this time

	 mov	 ax,[ebp].INTXX_ICOMHI ; Get previous frame offset
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_ICOMLO ; Get previous frame offset
	 btr	 ax,$INTCOM_VAL ; Move previous setting to CF
	 setc	 LAST_INTFLG.LO ; Move previous setting to memory
	 mov	 LAST_INTCOM,eax ; Restore it

	 lea	 bx,FGROUP:MSG_CTRL ; Reason code for termination

	 assume  gs:nothing	; Tell the assembler about it

	 FIXIJMP PGROUP:GOREAL_REBOOT,DTE_CS2 ; Exit protected mode and reboot


if @OEM_WIN3

COMMENT|

Function AH=C0
Get BIOS configuration data

Because Windows obtains this pointer in Virtual Mode with our
Page Tables in effect, and uses it in Protected Mode with its
Page Tables in effect (which are one-to-one at that time), we
must save a copy of the data in one-to-one memory and return
to Windows a pointer to our local data.

On entry:

CF	 =	 0 if ES:BX is valid
	 =	 1 otherwise
ES:BX	 ==>	 current data area

|

INT15_BIOSCFG:
	 test	 [ebp].INTXX_EFL.ELO,mask $CF ; Izit valid?
	 jnz	 near ptr INT15_EXIT1 ; Jump if not

	 push	 DTE_D4GB	; Get all memory selector
	 pop	 gs		; Address it
	 assume  gs:AGROUP	; Tell the assembler about it

	 movzx	 eax,[ebp].INTXX_ES ; Get caller's ES
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,[ebp].INTXX_EBX.ELO ; Get caller's BX
	 add	 esi,eax	; Add to get linear address of actual data
				; AGROUP:ESI ==> source data

; Search for the end of the VxD name

	 push	 DTE_DSLO	; Get selector for low DOS memory
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 edi,VIRT_DEV_DPFE ; ES:EDI ==> VxD name
	 mov	 cx,-1		; We know it's there
	 mov	 al,0		; String terminator
   repne scas	 PGROUP:[edi].LO ; Search for it

	 mov	 [ebp].INTXX_ES,seg PGROUP ; Save segment of VIRT_DEV_DPFE
	 mov	 [ebp].INTXX_EBX.ELO,di ; ES:BX ==> local copy of BIOS config data

	 movzx	 ecx,AGROUP:[esi].CFG_LEN ; Get length in bytes of following data
	 add	 ecx,2+8	; Add in length word (2) plus some slop (8)
S32  rep movs	 <PGROUP:[edi].LO,AGROUP:[esi]> ; Copy to local area

	 movzx	 ax,[ebp].INTXX_EAX.ELO.LO ; Get original AL, zero AH

	 jmp	 INT15_DONE	; Join common exit code

	 assume  es:nothing,gs:nothing ; Tell the assembler about it


COMMENT|

Function AH=C1
See if this is Windows' EBIOS driver asking for the XBIOS segment

|

INT15_XBIOS:
	 push	 DTE_DSHI	; Get selector for high DOS memory
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 assume  ds:nothing	; Tell a white lie
	 cmp	 LOWWIN3_CB,0	; Izit Windows 3 init time or later?
	 assume  ds:PGROUP	; Retract nose
	 je	 short INT15_XCAD ; Jump if not

	 push	 DTE_D4GB	; Get all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

; Ensure we've relocated XBIOS

	 test	 I15_FLAG,@I15_XBREL ; Izit relocated?
	 jz	 short INT15_XCAD ; Jump if not

	 movzx	 eax,[ebp].INTXX_ESP.ELO ; Get caller's SP
	 movzx	 edi,[ebp].INTXX_SS ; Get caller's SS
	 shl	 edi,4-0	; Convert from paras to bytes
	 add	 edi,eax	; AGROUP:EDI ==> caller's return address on stack

	 movzx	 eax,AGROUP:[edi].VOFF ; Get code offset
	 movzx	 edi,AGROUP:[edi].VSEG ; Get code segment
	 shl	 edi,4-0	; Convert from paras to bytes
	 add	 edi,eax	; AGROUP:EDI ==> caller's instruction stream

	 lea	 esi,EBIOS_CODE ; DS:ESI ==> telltale code fragment

	 mov	 ecx,EBIOS_LEN	; Get length of code fragment
    repe cmps	 PGROUP:[esi].LO,AGROUP:[edi].LO ; Compare 'em
	 jne	 short INT15_XCAD ; Jump if not the same

; We've detected (I hope) Windows' EBIOS VxD requesting the XBIOS segment

	 jmp	 INT15_ERR86	; Join common error code

	 assume  es:nothing	; Tell the assembler about it

endif				; IF @OEM_WIN3


COMMENT|

Function AH=89
Enter protected mode.

Return error code 86.

|

INT15_PROT:
	 mov	 ah,86h 	; Return common error code

	 jmp	 INT15_ERRCOM	; Join common error code


INT15_XCAD:
	 push	 DTE_D4GB	; Get all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

	 sub	 [ebp].INTXX_ESP.ELO,6 ; Make room (assuming it fits)

	 movzx	 edi,[ebp].INTXX_SS ; Get stack segment
	 shl	 edi,4-0	; Convert from paras to bytes
	 movzx	 ebx,[ebp].INTXX_ESP.ELO ; Get caller's ESP

	 lea	 ax,RESINT15_OLD ; Get the offset
	 xchg	 ax,[ebp].INTXX_EIP.ELO ; Swap IPs
	 mov	 AGROUP:[edi+ebx],ax ; Save on PL3 stack

	 mov	 ax,HIMEM_CS	; Get the segment
	 add	 bx,2		; Account for saved word, emulate 64KB wrap

	 xchg	 ax,[ebp].INTXX_CS ; Swap CSs
	 mov	 AGROUP:[edi+ebx],ax ; Save on PL3 stack

	 add	 bx,2		; Account for saved word, emulate 64KB wrap

	 mov	 ax,[ebp].INTXX_EFL.ELO ; Get FL (as opposed to EFL)
	 mov	 AGROUP:[edi+ebx],ax ; Save on PL3 stack

	 FIXIJMP PGROUP:INT0D_IRETD,DTE_CS2 ; Return to caller

	 assume  es:nothing	; Tell the assembler about it

COMMENT|

Function AH=88
Return size of extended memory.

This size is zero if we've installed our XMS INT 15h handler,
that is, an XMS call has closed off extended memory usage
through INT 15h BIOS block moves; only XMS calls should
access extended memory while in this state.

|

INT15_SIZE:
	 xor	 ax,ax		; Assume XMS INT 15h installed

	 test	 XMS_FLAG,mask $XMS_I15 ; Installed XMS INT 15h as yet?
	 jnz	 short @F	; Jump if so

	 mov	 eax,EXTSIZE	; Get size of extended memory

	 cmp	 eax,0FFFFh	; Izit bigger than 16-bits?
	 jbe	 short @F	; Jump if not

	 mov	 ax,0FFFFh	; Use maximum
@@:
	 jmp	 INT15_DONE	; Join common ending code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing


COMMENT|

Function AH=87
Validate the block move as outside MINBASE through TOPBASE.

ES:SI ==> GDT in real memory
ES:SI.MTE_DS ==> descriptor of source
ES:SI.MTE_ES ==> descriptor of destin

|

INT15_MOVE:
	 assume  ds:PGROUP,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

; Get 20-bit linear address offset of caller's GDT into ES:EBX

	 movzx	 eax,[ebp].INTXX_ES ; Get ES segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,[ebp].INTXX_ESI.ELO ; Get caller's offset
	 add	 ebx,eax	; ES:EBX ==> caller's GDT

; Get the source move address into ESI

	 mov	 eax,AGROUP:[ebx].MDTE_DS.DESC_BASE01.EDD
	 shl	 eax,8		; Shift out access rights byte
	 mov	 al,AGROUP:[ebx].MDTE_DS.DESC_BASE3 ; Get the high-order byte
	 ror	 eax,8		; Rotate back into position
	 mov	 esi,eax	; Copy to source register

; Get the destin move address into EDI

	 mov	 eax,AGROUP:[ebx].MDTE_ES.DESC_BASE01.EDD
	 shl	 eax,8		; Shift out access rights byte
	 mov	 al,AGROUP:[ebx].MDTE_ES.DESC_BASE3 ; Get the high-order byte
	 ror	 eax,8		; Rotate back into position
	 mov	 edi,eax	; Copy to destin register

; Get move size (in bytes) into ECX

	 movzx	 ecx,[ebp].INTXX_ECX.ELO ; Get CX from PL3 stack
	 shl	 ecx,1-0	; Convert from word to byte count
	 jz	 near ptr INT15_MOVE_MT ; Jump if move length is zero

	 dec	 ecx		; Convert from length to limit

; Ensure the move length is within the source segment limit

	 mov	 dl,AGROUP:[ebx].MDTE_DS.DESC_SEGLM1 ; Get limit bits 16-19
	 and	 dx,mask $SEGLM1 ; Isolate limit bits
	 shl	 edx,16 	; Shift to high-order word
	 mov	 dx,AGROUP:[ebx].MDTE_DS.DESC_SEGLM0 ; Get limit bits 0-15

	 test	 AGROUP:[ebx].MDTE_DS.DESC_SEGLM1,mask $DTE_G ; Check granularity
	 jz	 short @F	; Jump if byte-granular

	 shl	 edx,12 	; Make room for
	 or	 dx,0FFFh	; ...low-order bits
@@:
	 cmp	 ecx,edx	; Izit within limits?
	 jbe	 short @F	; Jump if it is

	 mov	 ecx,edx	; Set to the smaller
	 mov	 [ebp].INTXX_EAX.ELO.HI,02h ; Mark as in error
@@:

; Ensure the move length is within the destin segment limit

	 mov	 dl,AGROUP:[ebx].MDTE_ES.DESC_SEGLM1 ; Get limit bits 16-19
	 and	 dx,mask $SEGLM1 ; Isolate limit bits
	 shl	 edx,16 	; Shift to high-order word
	 mov	 dx,AGROUP:[ebx].MDTE_ES.DESC_SEGLM0 ; Get limit bits 0-15

	 test	 AGROUP:[ebx].MDTE_ES.DESC_SEGLM1,mask $DTE_G ; Check granularity
	 jz	 short @F	; Jump if byte-granular

	 shl	 edx,12 	; Make room for
	 or	 dx,0FFFh	; ...low-order bits
@@:
	 cmp	 ecx,edx	; Izit within limits?
	 jbe	 short @F	; Jump if it is

	 mov	 ecx,edx	; Set to the smaller
	 mov	 [ebp].INTXX_EAX.ELO.HI,02h ; Mark as in error
@@:
	 inc	 ecx		; Convert from limit to length

; Ensure the addresses ESI through ECX bytes are outside our protected range

	 mov	 eax,esi	; Check this one
	 call	 CHKMOVE	; Check on the move address in EAX for ECX bytes
	 jc	 near ptr INT15_MOVE_ERRLEN ; In our yard, so that's an error

; Ensure the addresses EDI through ECX bytes are outside our protected range

	 mov	 eax,edi	; Check this one
	 call	 CHKMOVE	; Check on the move address in EAX for ECX bytes
	 jc	 near ptr INT15_MOVE_ERRLEN ; In our yard, so that's an error

; If either the source or destination is at or above TOPBASE,
; setup the PTEs at PPDTBBMSRC and PPDTBBMDST to handle it.
; This situation occurs when running COMPAQ's VDISK or disk cache program.
; This situation also occurs when accessing Microsoft's ROM disk.

	 push	 LaBBMSRC	; Pass the linear address of the PTEs
	 push	 PPDTBBMSRC	; Pass the offset in PDT of PTEs
	 push	 esi		; Pass the source address
	 push	 offset PGROUP:LAST_BBMSRC ; Pass offset of last value
	 call	 CHECK_BBMFILL	; Check on fill in source PTEs
				; Returns (possibly) new address in EAX
	 mov	 esi,eax	; Copy to source address

	 push	 LaBBMDST	; Pass the linear address of the PTEs
	 push	 PPDTBBMDST	; Pass the offset in PDT of PTEs
	 push	 edi		; Pass the destin address
	 push	 offset PGROUP:LAST_BBMDST ; Pass offset of last value
	 call	 CHECK_BBMFILL	; Check on fill in destin PTEs
				; Returns (possibly) new address in EAX
	 mov	 edi,eax	; Copy to source address

	 test	 CM2_FLAG,@CM2_X384 ; Shadow RAM recovery disabled?
	 jnz	 short INT15_LOW ; Yes, skip all this

; See if we're running on a COMPAQ Deskpro 386 or an AST Premium/386
; and the destin move address is to the special COMPAQ memory-mapped I/O,
; and the move count is non-zero (otherwise we'll signal GP)

	 lea	 bx,CPQMIO_LO	; Assume it's a COMPAQ

	 test	 I15_FLAG,@I15_CPQ ; Izit COMPAQ TOP384 scheme?
	 jnz	 short INT15_CPQ1 ; Yes

	 lea	 bx,ASTMIO_LO	; Assume it's an AST

	 test	 I15_FLAG,@I15_AST ; Izit AST TOP384 scheme?
	 jz	 short INT15_LOW ; No, skip all this
INT15_CPQ1:
	 cmp	 edi,PGROUP:[bx] ; Check against lower limit
	 jb	 short INT15_LOW ; Too small, just move the dwords

	 cmp	 edi,PGROUP:[bx+4] ; Check against the upper limit
	 ja	 short INT15_LOW ; Too big, just move the dwords

	 cmp	 [ebp].INTXX_ECX.ELO,0 ; Anything to be moved?
	 je	 short INT15_LOW ; Not this time

	 test	 I15_FLAG,@I15_ROM ; Is the ROM disabled?
	 jz	 short INT15_LOW ; Not this time

; Check to see what we're setting it to

	 mov	 ax,AGROUP:[esi] ; Get the value to which we're setting it

; Change the source value to ensure both read-write and high/low mapped

	 mov	 OLD_SRC,ax	; Save to restore later
	 or	 I15_FLAG,@I15_SRC ; Mark as source changed

	 test	 I15_FLAG,@I15_AST ; Izit AST TOP384 scheme?
	 jz	 short INT15_CPQ2 ; Not this time

; Mark as high-only and read-write

	 and	 AGROUP:[esi].ELO,not ((@ASTMIO_HILO or @ASTMIO_ROM) * 0101h)

	 jmp	 short INT15_CPQ3 ; Join common code

; Mark as high-only and read-write

INT15_CPQ2:
	 or	 AGROUP:[esi].ELO,(@CPQMIO_HIGH + @CPQMIO_WRIT) * 0101h
INT15_CPQ3:
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
INT15_LOW:

; Save local data values on the stack

	 push	 OLD_SRC
	 push	 I15_FLAG

; Move the data

	 sti			; Allow interrupts

	 REGSAVE <esi,edi>	; Save source/destin starting offsets

	 movzx	 ecx,[ebp].INTXX_ECX.ELO ; Get caller's CX
	 shr	 ecx,2-1	; Convert from words to dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Move the data
	 jnc	 short @F	; Jump if no odd word at the end

S32	 movs	 <AGROUP:[edi].ELO,AGROUP:[esi].ELO> ; Move the last word of data
@@:
	 REGREST <edi,esi>	; Restore

	 cli			; Disallow interrupts

	 pop	 I15_FLAG	; Restore local data values
	 pop	 OLD_SRC

; Restore old source value if we have to modify it

	 test	 I15_FLAG,@I15_SRC ; Did we change the source value?
	 jz	 short @F	; Not this time

	 mov	 ax,OLD_SRC	; Get old source value
	 mov	 AGROUP:[esi],ax ; Save as source again
	 and	 I15_FLAG,not @I15_SRC ; Clear the flag
@@:

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 FIXICALL PGROUP:FWRAP_ENABLE,DTE_CS2 ; Enable the 1MB wrap
INT15_MOVE_MT:
	 movzx	 ax,[ebp].INTXX_EAX.ELO.LO ; Get original AL, zero AH

	 cmp	 [ebp].INTXX_EAX.ELO.HI,87h ; Did an error occur?
	 je	 short @F	; Jump if not

	 mov	 ah,[ebp].INTXX_EAX.ELO.HI ; Get error code
@@:
	 test	 GLB_FLAG,@GLB_NMI ; Did we encounter a parity error?
	 jz	 short INT15_DONE ; No

	 FIXICALL PGROUP:FENABLE_NMI,DTE_CS2 ; Enable NMI, clear the parity latches
	 and	 GLB_FLAG,not @GLB_NMI ; Clear it from our flags
	 mov	 ah,01h 	; Tell 'em we encountered a parity error

	 jmp	 short INT15_ERRCOM ; Join common error code

INT15_MOVE_ERRLEN:
	 mov	 ah,02h 	; Tell 'em an exception should have occurred
INT15_ERRCOM:
	 and	 [ebp].INTXX_EFL.ELO,not mask $ZF ; Clear the zero flag (ZF=0)
INT15_ERRCOM1:
	 or	 [ebp].INTXX_EFL.ELO,mask $CF ; Set the carry flag (CF=1)

	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Get original AL

	 jmp	 short INT15_EXIT ; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT15_DONE:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP

	 or	 [ebp].INTXX_EFL.ELO,mask $ZF ; Set the zero flag (ZF=1)
INT15_DONE1:
	 and	 [ebp].INTXX_EFL.ELO,not (mask $CF) ; Clear the carry flag (CF=0)
INT15_EXIT:
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Put return value onto stack
INT15_EXIT1:
	 FIXIJMP PGROUP:INT0D_IRETD,DTE_CS2 ; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMU_INT15 endp			; End EMU_INT15 procedure
	 NPPROC  CHKMOVE -- Check On Move Addresses
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If the move address at EAX for ECX bytes overlaps the 1MB
wrap region, disable that wrapping.

Ensure that the move addresses EAX for ECX bytes are outside
our protected region.

On entry:

EAX	 =	 starting linear address
ECX	 =	 # bytes to move

On exit:

CF	 =	 0 if it's outside our range
	 =	 1 otherwise

|

	 push	 ebx		; Save for a moment

; See if the range overlaps the 1MB wrap region

	 cmp	 eax,CON1P1MB	; Does it start below the wrap region's end?
	 jae	 short @F	; No, so there can be no overlap

	 lea	 ebx,[eax+ecx]	; EBX ==> end+1 of source/destin region

	 cmp	 ebx,CON1MB	; Does it end above the wrap region's start?
	 jbe	 short @F	; No, so there can be no overlap

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap
@@:
	 test	 DBG_FLAG,@DBG_XR ; XR moves allowed?
	 jnz	 short CHKMOVE_EXIT ; Yes, skip address check (note CF=0)

; Ensure the starting address is outside our protected range

	 cmp	 eax,MINBASE	; Check against lower bound
	 jb	 short CHKMOVE1 ; It's too small for us

	 cmp	 eax,TOPBASE	; Check against upper bound
;;;;;;;; jb	 short CHKMOVE_EXIT ; It's within our range (note CF=1)
	 jmp	 short CHKMOVE_EXIT ; It's outside our range (note CF=0)

; Add in ECX to point to the end of the destin move area
; Ensure the ending address is outside our protected range

CHKMOVE1:
	 lea	 ebx,[eax+ecx]	; EBX ==> end+1 of source/destin region

	 cmp	 ebx,MINBASE	; Check against lower bound
	 je	 short CHKMOVE_EXIT ; If     equal (CF=0), OK
				; If	 below (CF=1), OK; otherwise not
	 cmc			; If not below (CF=0), OK; otherwise not
CHKMOVE_EXIT:
	 pop	 ebx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHKMOVE  endp			; End CHKMOVE procedure
	 NPPROC  CHECK_BBMFILL -- Check On BIOS Block Move PTE Fill
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on BIOS block move PTE fill

On entry:

See BBMFILL_STR.

On exit:

EAX	 =	 (possibly new) output address

|

BBMFILL_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
BBMFILL_LAST dw  ?		; Offset in PGROUP of last input address
BBMFILL_INP dd	 ?		; Input address
BBMFILL_PDT dd	 ?		; Offset in PDT of PTEs
BBMFILL_La  dd	 ?		; Linear address of memory at PTEs

BBMFILL_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,edi>	; Save registers

	 mov	 eax,[ebp].BBMFILL_INP ; Get the incoming address

	 cmp	 eax,TOPBASE	; Check source address against our top limit
	 jb	 short CHECK_BBMFILL_EXIT ; It's within our PDIRs

	 mov	 di,[ebp].BBMFILL_LAST ; Get the offset in PGROUP of the last address

	 cmp	 eax,PGROUP:[di] ; Izit the same as the last address?
	 je	 short CHECK_BBMFILL_LAST ; Jump if so

	 mov	 PGROUP:[di],eax ; Save for the next time

	 and	 eax,not (mask $LA_OFF) ; Round down to 4KB boundary

; Ensure the User, Read-Write, Present, and Cache Disable bits are set

	 or	 ax,@PTE_URP or (mask $PTE_CD) ; Mark as User/Read-write/Present
				; and not cached
	 mov	 edi,[ebp].BBMFILL_PDT ; Get the offset in PDT of PTEs
	 add	 edi,PRGPDT	; Plus offset of PDT in PGROUP

	 mov	 cx,(64+4)/4	; # PTEs to cover 64+4 KB
@@:
	 mov	 PGROUP:[edi].PDT_PTE,eax ; Save as new PTE

	 add	 edi,size PDT_PTE ; Skip to next PTE
	 add	 eax,CON4KB	; Skip to next page

	 loop	 @B		; Jump if more PTEs to initialize

; Because we just changed the page table, we must flush the TLB

	 FIXICALL PGROUP:FFLUSH_TLB,DTE_CS2 ; Flush the TLB
CHECK_BBMFILL_LAST:
	 mov	 eax,[ebp].BBMFILL_INP ; Get the incoming address
	 and	 eax,mask $LA_OFF ; Isolate the offset in 4KB
	 add	 eax,[ebp].BBMFILL_La ; Plus the base linear address
CHECK_BBMFILL_EXIT:
	 REGREST <edi,ecx>	; Restore

	 pop	 ebp		; Restore

	 ret	 3*4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BBMFILL endp		; End CHECK_BBMFILL procedure
	 align	 4		; Ensure dword alignment

LCODE	 ends			; End LCODE segment

	 MEND			; End QMAX_I15 module

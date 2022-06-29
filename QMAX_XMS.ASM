;' $Header:   P:/PVCS/MAX/386MAX/QMAX_XMS.ASV   1.3   30 May 1997 10:46:18   BOB  $
	 title	 QMAX_XMS -- 386MAX Extended Memory Specification Handler
	 page	 58,122
	 name	 QMAX_XMS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Data    segment JDATA, dword-aligned, public, class 'jcode'

Program derived from:  None.

Original code by:  Bob Smith, July, 1988.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include 8259.INC
	 include PTR.INC
	 include MAC.INC
	 include XMS.INC
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include VDISK.INC
	 include INTVEC.INC
	 include ALLMEM.INC
	 include DEVDRV.INC
NOVER_HTU = 1
	 include VERSION.INC
	 include MASM5.MAC
	 include DPMI.INC
	 include IOTRAP.INC

	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAX_I31.INC
	 include QMAX_OEM.INC
.list

@ZEROLEN_BASE equ -1		; Pseudo-base of zero length handles


PGROUP	 group	 CODE,HICODE,ECODE,EDATA
IGROUP	 group	 LDATA,ICODE
JGROUP	 group	 JCODE,JDATA
PSPGRP	 group	 PSPSEG


PSPSEG	 segment use16 at 0	; Start PSPSEG segment
	 assume  cs:PSPGRP,ds:PSPGRP

	 public  PSP_ENVIR_PTR,PSP_TERMINATE,PSP_LCL_STACK
	 public  PSP_TERMINATE
	 include PSP.INC

	 assume  cs:nothing,ds:nothing

PSPSEG	 ends			; End PSPSEG segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

if @OEM_XMS
	 extrn	 QMAX_VER:byte
	 include QMAX_HDM.INC

if @OEM_HIFILL or @OEM_DPMI
	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC
endif				; IF @OEM_HIFILL or @OEM_DPMI

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 DB3_FLAG:word
	 include QMAX_DB3.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 XMS_FLAG:word	; **BOTH** high and low memory
	 include QMAX_XMS.INC

	 extrn	 EXTSIZE:dword
if @OEM_WIN3
	 extrn	 LOWWIN3_CB:byte
	 extrn	 DEVDRV:tbyte
endif				; IF @OEM_WIN3
endif				; IF @OEM_XMS

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 EX2SIZE:dword
if @OEM_WIN3
	 extrn	 RESINT2F_WIN3_BEGINIT_TAIL:near
endif				; IF @OEM_WIN3
	 extrn	 VM_VSAPI:near

HICODE	 ends			; End HICODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

if @OEM_WIN3
	 extrn	 WIN3_REF_DATA:tbyte
	 include QMAXWIN3.INC

	 extrn	 DOSX_FLAG:byte ; QMAX_N31.ASM
	 extrn	 OLD_DUM67_VEC:dword ; QMAX_IM2.ASM
endif				; IF @OEM_WIN3

if @OEM_HIFILL and @OEM_WIN3
	 extrn	 OLDHDM:byte
endif				; IF @OEM_HIFILL and @OEM_WIN3

if @OEM_DPMI
	 extrn	 I31_FLAG:word
	 extrn	 DPM_FLAG:word
	 extrn	 DPMITYPE:byte
	 extrn	 DPMI_CPIHOOK:byte
	 extrn	 DPMI_CPL:byte
endif				; IF @OEM_DPMI

	 extrn	 HMASIZE:dword

if @OEM_XMS
	 extrn	 EXTBASE:dword
	 extrn	 CMPSIZE:dword
	 extrn	 CMPSIZEXT:dword
	 extrn	 LAST_INTCOM:dword
	 extrn	 LAST_INTFLG:dword
	 extrn	 CON1MB:dword
	 extrn	 CON10FFF0:dword
	 extrn	 HIMEM_CS:word
	 extrn	 PRGPDT:dword
	 extrn	 EHNDLCNT:word

	 extrn	 PIOBIT:dword

	 public  PIOTRAP,IOTRAP_TYP
PIOTRAP  dd	 ?		; Offset in PGROUP of I/O trapping strucs
IOTRAP_TYP dd	 ?		; Flag for input or output

	 public  LaCVD
LaCVD	 dd	 ?		; Linear address of pseudo-1MB address

	 public  A20CNT,@A20DEF
A20CNT	 dd	 0		; Count of # times A20 gated ON
@A20DEF  equ	 0		; Default A20 count

; Note that the first entry in XMSBASE is unused
; and the first entry in XMSSIZE is the size of the free chain

	 public  PXMSBASE,PXMSSIZE,PXMSHNDL,PXMSLOCK
PXMSBASE dd	 ?		; PGROUP offset to XMSBASE DD array
PXMSSIZE dd	 ?		; PGROUP offset to XMSSIZE DD array
PXMSHNDL dd	 ?		; PGROUP offset to XMSHNDL DB array
PXMSLOCK dd	 ?		; PGROUP offset to XMSLOCK DB array

	 public  @H_AVAIL,@H_INUSE
@H_AVAIL equ	 0		; The handle is available
@H_INUSE equ	 1		; The handle is in use

	 public  SEL_DATA,SEL_DS3,SEL_4GB,SEL_4GB3,SEL_PDT,SEL_DSHI
	 public  SEL_DSFG3,SEL_DSIG3,SEL_DSJG3
SEL_DATA dw	 DTE_DS 	; PGROUP data selector
SEL_DS3  dw	 DTE_DS3   or (@DPMI_CPL shl $PL) ; PGROUP data selector at DPMI CPL
SEL_4GB  dw	 DTE_D4GB	; AGROUP data selector
SEL_4GB3 dw	 DTE_D4GB3 or (@DPMI_CPL shl $PL) ; AGROUP data selector at DPMI CPL
SEL_PDT  dw	 DTE_PDT	; Our PDT selector
SEL_DSHI dw	 DTE_DSHI	; Our high DOS memory selector
SEL_DSFG3 dw	 DTE_FIXUP or (@DPMI_CPL shl $PL) ; FGROUP data selector at DPMI CPL
SEL_DSIG3 dw	 DTE_DSIG  or (@DPMI_CPL shl $PL) ; IGROUP data selector at DPMI CPL
SEL_DSJG3 dw	 DTE_DSJG  or (@DPMI_CPL shl $PL) ; JGROUP data selector at DPMI CPL

	 public  HMAMIN
HMAMIN	 dw	 0		; Minimum value for HMA usage

	 public  XMSNHNDL,XHNDLCNT
XMSNHNDL dw	 32		; # XMS handles
XHNDLCNT dw	 1		; Count of XMS handles in use

	 public  XMS_FNS,XMS2_FNS
	 even
XMS_FNS  dw	 PGROUP:XMS_VERS	; 00 = Version #
	 dw	 PGROUP:XMS_REQHMA	; 01 = Request HMA
	 dw	 PGROUP:XMS_RELHMA	; 02 = Release HMA
	 dw	 PGROUP:XMS_GLBENA	; 03 = Global Enable A20
	 dw	 PGROUP:XMS_GLBDIS	; 04 = Global Disable A20
	 dw	 PGROUP:XMS_LCLENA	; 05 = Local Enable A20
	 dw	 PGROUP:XMS_LCLDIS	; 06 = Local Disable A20
	 dw	 PGROUP:XMS_QRYA20	; 07 = Query A20 status
	 dw	 PGROUP:XMS_QRYXMB	; 08 = Query free extended memory block
	 dw	 PGROUP:XMS_GETXMB	; 09 = Allocate extended memory block
	 dw	 PGROUP:XMS_RELXMB	; 0A = Release extended memory block
	 dw	 PGROUP:XMS_MOVXMB	; 0B = Move extended memory block
	 dw	 PGROUP:XMS_LCKXMB	; 0C = Lock extended memory block
	 dw	 PGROUP:XMS_UNLXMB	; 0D = Unlock extended memory block
	 dw	 PGROUP:XMS_GETINF	; 0E = Get handle information
	 dw	 PGROUP:XMS_MODXMB	; 0F = Reallocate extended memory block
if @OEM_HIFILL
	 dw	 PGROUP:XMS_GETUMB	; 10 = Allocate upper memory block
	 dw	 PGROUP:XMS_RELUMB	; 11 = Release upper memory block
	 dw	 PGROUP:XMS_MODUMB	; 12 = Reallocate upper memory block
else
	 dw	 PGROUP:XMS_EB1 	; 10 = Allocate upper memory block
	 dw	 PGROUP:XMS_EB1 	; 11 = Release upper memory block
	 dw	 PGROUP:XMS_EB1 	; 12 = Reallocate upper memory block
endif				; IF @OEM_HIFILL
XMS_CNT  equ	 ($-XMS_FNS)/2	; # primary XMS function supported
XMS2_FNS dw	 PGROUP:XMS_QRY2XMB	; 88 = Query free extended memory block
	 dw	 PGROUP:XMS_GET2XMB	; 89 = Allocate extended memory block
	 dw	 PGROUP:XMS_E80 	; 8A = (reserved)
	 dw	 PGROUP:XMS_E80 	; 8B = (reserved)
	 dw	 PGROUP:XMS_E80 	; 8C = (reserved)
	 dw	 PGROUP:XMS_E80 	; 8D = (reserved)
	 dw	 PGROUP:XMS_GET2INF	; 8E = Get handle information
	 dw	 PGROUP:XMS_MOD2XMB	; 8F = Reallocate extended memory block
	 dw	 PGROUP:XMS_E80 	; 90 = (reserved)
XMS2_CNT equ	 ($-XMS2_FNS)/2 ; # secondary XMS function supported

if @OEM_WIN3
	 public  VXD_LEVEL
VXD_LEVEL dw	 0		; VxD level count (0 = normal)

;;;	     public  WOLDINT0D_FVEC,WOLDINT0E_FVEC
;;;	     public  WLCLINT0D_FVEC,WLCLINT0E_FVEC
;;; WOLDINT0D_FVEC df ? 	    ; Save area for original INT 0Dh handler
;;; WOLDINT0E_FVEC df ? 	    ; ...			 0Eh ...
;;; WLCLINT0D_FVEC label fword	    ; Save area for new      INT 0Dh handler
;;;	     dw      PGROUP:WLCL_INT0D,0,?
;;; WLCLINT0E_FVEC label fword	    ; ...			 0Eh ...
;;;	     dw      PGROUP:WLCL_INT0E,0,?
;;;
;;;	     public  WOLDINT0D_ARB,WOLDINT0E_ARB
;;;	     public  WLCLINT0D_ARB,WLCLINT0E_ARB
;;; WOLDINT0D_ARB db ?		    ; Save area for original INT 0Dh ARB value
;;; WOLDINT0E_ARB db ?		    ; ...			 0Eh ...
;;; WLCLINT0D_ARB db  CPL0_INTR3 or CPL3 ; Save area for new INT 0Dh ...
;;; WLCLINT0E_ARB db  CPL0_INTR3 or CPL3 ; ...			 0Eh

endif				; IF @OEM_WIN3
endif				; IF @OEM_XMS

EDATA	 ends			; End EDATA segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DSIG3:word
	 extrn	 ISEL_4GB3:word
	 extrn	 ISEL_DS3:word

LDATA	 ends			; End LDATA segment


JCODE	 segment use16 dword public 'jcode' ; Start LCODE segment
	 assume  cs:JGROUP

	 extrn	 ACTIVATE_HOOK13:far
if @OEM_HIFILL
	 extrn	 MAC_ALLOC:far
	 extrn	 MAC_REALLOC:far
	 extrn	 MAC_FREE:far
endif				; IF @OEM_HIFILL

JCODE	 ends			; End JCODE segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
	 assume  ds:JGROUP

	 extrn	 JSEL_DS3:word

JDATA	 ends			; End JDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

if @OEM_DPMI
	 extrn	 PMINTCOM:far
	 extrn	 DPMIFN_CHKVSAPI:far
	 extrn	 DPMI_REFINT:far
endif				; IF @OEM_DPMI

ICODE	 ends			; End ICODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

if @OEM_XMS
	 extrn	 INTPROC00Z:near
	 extrn	 INTPROC2F:near
	 extrn	 EMM_EXIT:near
	 extrn	 WRAP_ENABLE:near
	 extrn	 WRAP_DISABLE:near
	 extrn	 FOPENHIGHDOS:far
	 extrn	 QRY_PGCNT:near
	 extrn	 ALLOCMEM:near
	 extrn	 ALLOCMEM_SUB:near
	 extrn	 DEALLOCMEM:near
	 extrn	 XMS_XLAT:near
	 extrn	 XMS_MEMSPAN:near

	 public  @QMAX_XMS_ECODE
@QMAX_XMS_ECODE:		; Mark module start in .MAP file

	 FPPROC  INT2F -- INT 2Fh Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Direct INT 2Fh interrupt handler (instead of using the one
in low memory).

|

if @OEM_DPMI

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 near ptr INT2F_INTRETVM ; Jump if so

; อออออออออออออออออออProtected mode INT 2Fh callsอออออออออออออออออออออออออออ

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT2F_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPIHOOK[2Fh/8],1 shl (2Fh mod 8) ; Izit hooked by current client?
	 jz	 short INT2F_INTRETPM ; Jump if not

	 mov	 [esp].NRM_INTNO,4*2Fh + offset PGROUP:INTPROC00Z ; Mark as INT 2Fh

; The stack is mapped by INTDPI_STR

	 push	 @PMINTCOM_NRM	; Use application stack
	 FIXIJMP IGROUP:PMINTCOM,DTE_CSIG ; Jump to common code

	 public  INT2F_INTRETPM
INT2F_INTRETPM:
	 cmp	 ax,@DPMI_CPUMODE ; Izit DPMI mode check (PM vs VM)?
	 jne	 short INT2F_INTRETPM1 ; Jump if not

	 xor	 ax,ax		; Mark as PM

	 iretd			; Return to caller with AX = 0

INT2F_INTRETPM1:
	 cmp	 ax,@DPMI_API2F ; Izit Vendor-Specific API Entry Point request?
	 jne	 short INT2F_INTRETPM2 ; Jump if not

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 short INT2F_INTRETPM2 ; Jump if so

	 push	 ds		; Pass caller's DS
	 push	 esi		; ...		ESI
	 FIXICALL IGROUP:DPMIFN_CHKVSAPI,DTE_CSIG ; Check for our string
	 assume  es:nothing	; Tell the assembler about it
	 jne	 short INT2F_INTRETPM2 ; Jump if it's not us

	 mov	 al,0		; Tell 'em it's a match

	 iretd			; Return to caller

INT2F_INTRETPM2:

; Check for Windows calling us to ask for XMS presence
; from a DPMI client.  In order to get KRNL386 to run
; under our DPMI services, we must fail this call.

	 cmp	 ax,4300h	; Izit XMS presence detection?
	 jne	 short INT2F_INTRETPM3 ; Jump if not

	 test	 I31_FLAG,mask $I31_KRNL ; Izit Windows?
	 jz	 short INT2F_INTRETPM3 ; Jump if not

	 iretd			; Return to caller

INT2F_INTRETPM3:

; Check for Windows asking for a read-write selector to the LDT

	 cmp	 ax,1688h	; Izit get read-write LDT selector?
	 jne	 short INT2F_INTRETPM4 ; Jump if not

; Return the LDT selector in BX at DPMI CPL

	 mov	 bx,DTE_DATALDT or (mask $TI) ; Return it
	 or	 bl,DPMI_CPL	; Plus DPMI CPL
	 xor	 ax,ax		; Tell 'em we succeeded

	 iretd			; Return to caller

INT2F_INTRETPM4:

; Check for Windows asking if Windows/386 is running.
; In order to come up in 386 Enhanced Mode, we must
; respond to this call.

	 cmp	 ax,1600h	; Izit Windows/386 installation check?
	 jne	 short INT2F_INTRETPM5 ; Jump if not

	 test	 I31_FLAG,mask $I31_KRNL ; Izit Windows?
	 jz	 short INT2F_INTRETPM5 ; Jump if not

	 test	 DPM_FLAG,mask $DPM_DPMISTD ; Force KRNL386 to come up in standard mode?
	 jnz	 short INT2F_INTRETPM5 ; Jump if so

	 mov	 ax,0003h	; Tell a lie

	 iretd			; Return to caller

INT2F_INTRETPM5:

; Nobody handled this function, so we must reflect it to VM
; If there's a DPMI client active, use DPMI_REFINT;
; otherwise, use INTPROC2F.

if @OEM_DPMI
	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 short @F	; Jump if not

	 mov	 [esp].NRM_INTNO,4*2Fh + offset PGROUP:INTPROC00Z ; Mark as INT 2Fh

	 FIXIJMP IGROUP:DPMI_REFINT,DTE_CSIG ; Reflect to VM

@@:
endif				; IF @OEM_DPMI
	 jmp	 INTPROC2F	; Reflect to VM

INT2F_INTRETVM:
; อออออออออออออออออออออVirtual mode INT 2Fh callsอออออออออออออออออออออออออออ

	 cmp	 [esp].NRM_CS,seg PGROUP ; Check against caller's CS
	 org	 $-2
	 public  INT2F_HIMEM_CS
INT2F_HIMEM_CS label near
	 org	 $+2
	 je	 near ptr INT2F_XMS ; Jump if it's an XMS call

	 cmp	 ax,@DPMI_CPUMODE ; Izit DPMI mode check (PM vs VM)?
	 jne	 short @F	; Jump if not

	 iretd			; Return to caller with AX <> 0

@@:
endif				; IF @OEM_DPMI

if @OEM_WIN3
	 test	 CM3_FLAG,@CM3_NOWIN3 ; Disabling support for WIN3?
	 jnz	 near ptr INT2F_XWIN3 ; Jump if so

; If the 1605h/1606h is from Standard mode, remember that fact for the
; INT 68h and INT 41h handlers.

	 cmp	 ax,1606h	; Izit Windows Exit?
	 jne	 short INT2F_X1606 ; Jump if not

	 push	 ds		; Save

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 DOSX_FLAG,0	; Remember we're not in DOSX

; If we didn't go through a disable callback sequence, reset Windows state

	 cmp	 LOWWIN3_CB,0	; Izit Windows 3 init time or later?
	 je	 short INT2F_1605_COM ; Jump if not

	 REGSAVE <eax,ds>	; Save registers

	 push	 DTE_DSLO	; Get data selector for low DOS memory
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 test	 GLB_FLAG,@GLB_I67 ; Are we providing INT 67h services?
	 jnz	 short INT2F_1606_EMS ; Yes, skip alterations

; Remove assume on DS to address SEL_DS3 using CS

	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 eax,OLD_DUM67_VEC ; Get old interrupt vector

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:INTVEC	; Tell the assembler

	 mov	 INT00_VEC[67h*(type INT00_VEC)],eax ; Restore it

	 push	 DTE_DSLO	; Get low DOS memory descriptor
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 DEVDRV.DD_NAME[0],'Q' ; Mark as EMS manager not installed
INT2F_1606_EMS:
	 REGREST <ds,eax>	; Restore registers
	 assume  ds:PGROUP	; Tell the assembler

if @OEM_HIFILL
; If high DOS memory was opened up before we started Windows, open it again

	 cmp	 OLDHDM,@HDM_CLOS ; Izit to remain closed off?
	 je	 short @F	; Jump if so

	 REGSAVE <gs>		; Save

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it

	 FCALL	 FOPENHIGHDOS	; Open up high DOS memory

	 REGREST <gs>		; Restore
	 assume  gs:nothing	; Tell the assembler

endif				; IF @OEM_HIFILL
@@:
	 FIXICALL JGROUP:ACTIVATE_HOOK13,DTE_CSJG ; Activate the HOOK13 byte if inactive

	 mov	 LOWWIN3_CB,0	; Mark as no longer OFF from Windows 3 callback

	 push	 DTE_DSLO	; Get low DOS memory descriptor
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 LOWWIN3_CB,0	; Mark as no longer OFF from Windows 3 callback

	 push	 DTE_DSHI	; Get high DOS memory descriptor
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 LOWWIN3_CB,0	; Mark as no longer OFF from Windows 3 callback
INT2F_1605_COM:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler

	 jmp	 short INT2F_XWIN3 ; Rejoin common code

INT2F_X1606:
	 cmp	 ax,1605h	; Izit Windows Begin Initialization?
	 jne	 short INT2F_XWIN3 ; Jump if not

	 push	 ds		; Save

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 DOSX_FLAG,dl	; Remember the Standard mode flag

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler

	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All GP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 movzx	 eax,[ebp].INTXX_SS ; Get caller's SS
	 shl	 eax,4-0	; Convert from paras to bytes
	 sub	 [ebp].INTXX_ESP.ELO,3*2 ; Make room for new IP, CS, FL
	 movzx	 ebx,[ebp].INTXX_ESP.ELO ; Get caller's SP
	 add	 ebx,eax	; Add to get linear address

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

INT_STR  struc

INT_IP	 dw	 ?		; Return IP
INT_CS	 dw	 ?		; ...	 CS
INT_FL	 dw	 ?		; ...	 FL

INT_STR  ends

; PL3 IP, CS, FL --> PL3 SS:SP
; LCL IP, CS, FL --> PL3 IP, CS, FL

	 lea	 ax,RESINT2F_WIN3_BEGINIT_TAIL ; Get offset of restart point
	 xchg	 ax,[ebp].INTXX_EIP.ELO ; Swap IPs
	 mov	 AGROUP:[ebx].INT_IP,ax ; Save on PL3 stack

	 mov	 ax,HIMEM_CS	; Get segment of high DOS memory
	 xchg	 ax,[ebp].INTXX_CS ; Swap CSs
	 mov	 AGROUP:[ebx].INT_CS,ax ; Save on PL3 stack

	 mov	 ax,@VMIOPL shl $IOPL ; Set clear flags, IOPL=@VMIOPL
	 xchg	 ax,[ebp].INTXX_EFL.ELO ; Swap FLs
	 mov	 AGROUP:[ebx].INT_FL,ax ; Save on PL3 stack

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off error code

	 jmp	 INTPROC2F	; Jump to next handler in sequence

	 assume  ds:nothing	; Tell the assembler about it

INT2F_XWIN3:
endif				; IF @OEM_WIN3
	 cmp	 ax,@DPMI_API2F ; Izit Vendor-Specific API Entry Point request?
	 jne	 short INT2F_INTRETVM1 ; Jump if not

; See if the input name in DS:SI is us

	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All GP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 call	 VMFN_CHKVSAPI	; Check it out, fill in caller's ES:DI if match
	 popad			; Restore
	 lea	 esp,[esp+(size INTXX_ERR)] ; Strip off pseudo-error code
	 jne	 short INT2F_INTRETVM1 ; Jump if not

	 xor	 ax,ax		; Indicate success

	 iretd			; Return to caller with AX = 0

INT2F_INTRETVM1:
	 cmp	 ax,@IOTRAP_API ; Izit I/O trapping?
	 jne	 near ptr INT2F_INTRETVM2 ; Jump if not

COMMENT|

I/O trapping

On entry:

BX	 =	 function #
------------------------------------------------
For BX=0,

CX	 =	 # entries in I/O dispatch table
EDX	 =	 MSW = high address of I/O trap
		 LSW = low ...
DS:SI	 ==>	 I/O dispatch table
DI	 =	 length of client's code/data

On exit:

AX	 =	 handle if CF=0
CF	 =	 0 if all went well
	 =	 1 otherwise
------------------------------------------------
For BX=1,

SI	 =	 handle

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise
------------------------------------------------
For BX=3,

On exit:

AH	 =	 Major version # of spec supported
AL	 =	 Minor ...
BX	 =	 Capability flags
		 Bit 0:  I/O trapping supported for DPMI programs
		 Bit 1:  I/O port width passed in ECX to I/O handler
		 Bit 2:  Error codes returned in AX
DX	 =	 Minimum I/O port # allowed to be trapped

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All GP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 REGSAVE <ds,gs>	; Save registers

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it

	 and	 [ebp].INTXX_EFL.ELO,not (mask $CF) ; CF=0

	 cmp	 [ebp].INTXX_EBX.ELO,1 ; Split cases
	 ja	 near ptr INT2F_IOTRAP_CAP ; Jump if possibly capabilities fn
	 je	 near ptr INT2F_IOTRAP_UNINST ; Jump if we're to uninstall

	 mov	 ax,[ebp].INTXX_EDX.ELO ; Get low-order word of EDX

	 cmp	 ax,[ebp].INTXX_EDX.EHI ; Izit below high-order word?
	 mov	 ax,@IOTRAP_ERR_EDX ; EDX.HI < EDX.LO
	 ja	 near ptr INT2F_IOTRAP_ERR ; Jump if not

	 mov	 ax,[ebp].INTXX_CS ; Get caller's CS

	 cmp	 ax,[ebp].INTXX_DS ; Izit the same as caller's DS?
	 mov	 ax,@IOTRAP_ERR_CSDS ; CS <> DS
	 jne	 near ptr INT2F_IOTRAP_ERR ; Jump if not

	 cmp	 [ebp].INTXX_ECX.ELO,0 ; Is CX valid?
	 mov	 ax,@IOTRAP_ERR_CX0 ; CX=0
	 je	 near ptr INT2F_IOTRAP_ERR ; Jump if not

; Ensure there's enough room in our local table

; Address the next available table entry

	 mov	 ebx,PIOTRAP	; Get offset in PGROUP to table base
	 mov	 cx,@IOTRAP_MAX ; Get # strucs
@@:
	 cmp	 PGROUP:[ebx].IOTRAP_TABCNT,0 ; Izit free?
	 je	 short @F	; Jump if so

	 add	 ebx,type IOTRAP_STR ; Skip to next entry

	 loop	 @B		; Jump if more entries

	 mov	 ax,@IOTRAP_ERR_NOHND ; Too many I/O handlers installed

	 jmp	 INT2F_IOTRAP_ERR ; Join common error code

@@:

; Save the caller's info in the IOTRAP table

	 movzx	 eax,[ebp].INTXX_DS ; Get caller's DS
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 PGROUP:[ebx].IOTRAP_GDTCS.DESC_BASE01,ax ; Save bytes 0-1
	 mov	 PGROUP:[ebx].IOTRAP_GDTDS.DESC_BASE01,ax ; ...
	 shr	 eax,16 	; Shift down high-order word
	 mov	 PGROUP:[ebx].IOTRAP_GDTCS.DESC_BASE2,al ; Save byte 2
	 mov	 PGROUP:[ebx].IOTRAP_GDTDS.DESC_BASE2,al ; ...
	 mov	 PGROUP:[ebx].IOTRAP_GDTCS.DESC_BASE3,ah ; ...	     3
	 mov	 PGROUP:[ebx].IOTRAP_GDTDS.DESC_BASE3,ah ; ...

	 movzx	 eax,[ebp].INTXX_EDI.ELO ; Get caller's DI (CS/DS length)
	 dec	 eax		; Convert from length to limit
	 mov	 PGROUP:[ebx].IOTRAP_GDTCS.DESC_SEGLM0,ax ; Save bits 0-15
	 mov	 PGROUP:[ebx].IOTRAP_GDTDS.DESC_SEGLM0,ax ; ...
	 shr	 eax,16 	; Shift down high-order word
	 mov	 PGROUP:[ebx].IOTRAP_GDTCS.DESC_SEGLM1,al ; Save bits 16-19
	 mov	 PGROUP:[ebx].IOTRAP_GDTDS.DESC_SEGLM1,al ; ...

	 mov	 PGROUP:[ebx].IOTRAP_GDTCS.DESC_ACCESS,CPL0_CODE ; Save A/R byte
	 mov	 PGROUP:[ebx].IOTRAP_GDTDS.DESC_ACCESS,CPL0_DATA ; ...

	 movzx	 eax,[ebp].INTXX_DS ; Get caller's DS
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,[ebp].INTXX_ESI.ELO ; Get caller's SI
	 add	 esi,eax	; Add to get 32-bit linear address
	 mov	 PGROUP:[ebx].IOTRAP_LaTAB,esi ; Save for later use

	 mov	 eax,[ebp].INTXX_EDX ; Get the I/O address range
	 mov	 PGROUP:[ebx].IOTRAP_IO,eax ; Save for later use

; Loop through the entries to verify the entries >= @IOTRAP_MINIO and within
; range specified in caller's EDX

	 mov	 cx,[ebp].INTXX_ECX.ELO ; Get the # entries in I/O dispatch tab
;;;;;;;; mov	 esi,PGROUP:[ebx].IOTRAP_LaTAB ; Get the LA of the table
@@:
	 mov	 dx,AGROUP:[esi].DI_wPORT ; Get the I/O port #

	 cmp	 dx,@IOTRAP_MINIO ; Izit in system I/O range?
	 mov	 ax,@IOTRAP_ERR_DI_MIN ; DI_wPort < minimum I/O port
	 jb	 near ptr INT2F_IOTRAP_ERR ; Jump if so

	 cmp	 dx,PGROUP:[ebx].IOTRAP_IO.ELO ; Izit within range?
	 mov	 ax,@IOTRAP_ERR_DI_LO ; DI_wPort < low-order word of EDX
	 jb	 near ptr INT2F_IOTRAP_ERR ; Jump if not

	 cmp	 dx,PGROUP:[ebx].IOTRAP_IO.EHI ; Izit within range?
	 mov	 ax,@IOTRAP_ERR_DI_HI ; DI_wPort > high-order word of EDX
	 ja	 near ptr INT2F_IOTRAP_ERR ; Jump if not

	 add	 esi,type DISPATCH_INFO ; Skip to next entry

	 loop	 @B		; Jump if more entries

; Loop through the entries to check the I/O ports used by other handlers

	 mov	 edx,PIOTRAP	; Get offset in PGROUP to table base
	 mov	 cx,@IOTRAP_MAX ; Get # strucs
INT2F_IOTRAP_NEXT1:

; Find the next entry in use

	 cmp	 PGROUP:[edx].IOTRAP_TABCNT,0 ; Izit free?
	 je	 short INT2F_IOTRAP_LOOP1 ; Jump if so

	 REGSAVE <cx,edx>	; Save for a moment

; Loop through this table's entries

	 mov	 cx,PGROUP:[edx].IOTRAP_TABCNT ; Get the # entries in I/O dispatch tab
	 mov	 edx,PGROUP:[edx].IOTRAP_LaTAB ; Get the LA of the table
INT2F_IOTRAP_NEXT2:
	 mov	 ax,AGROUP:[edx].DI_wPORT ; Get the I/O port #

	 REGSAVE <cx,edx>	; Save for a moment

; Check this I/O port against the ones in the incoming table

	 mov	 cx,[ebp].INTXX_ECX.ELO ; Get the # entries in I/O dispatch tab
	 mov	 edx,PGROUP:[ebx].IOTRAP_LaTAB ; Get the LA of the table
INT2F_IOTRAP_NEXT3:
	 cmp	 ax,AGROUP:[edx].DI_wPORT ; Izit the same I/O port #?
	 je	 short INT2F_IOTRAP_DONE3 ; Jump if so (note CF=0)

	 add	 edx,type DISPATCH_INFO ; Skip to next entry

	 loop	 INT2F_IOTRAP_NEXT3 ; Jump if more entries

	 stc			; Mark as not found
INT2F_IOTRAP_DONE3:
	 REGREST <edx,cx>	; Restore
	 jnc	 short INT2F_IOTRAP_DONE2 ; Jump if duplicate found (note CF=0)
INT2F_IOTRAP_LOOP2:
	 add	 edx,type DISPATCH_INFO ; Skip to next entry

	 loop	 INT2F_IOTRAP_NEXT2 ; Jump if more entries

	 stc			; Mark as not found
INT2F_IOTRAP_DONE2:
	 REGREST <edx,cx>	; Restore
	 jnc	 short INT2F_IOTRAP_DONE1 ; Jump if duplicate found (note CF=0)
INT2F_IOTRAP_LOOP1:
	 add	 edx,type IOTRAP_STR ; Skip to next entry

	 loop	 INT2F_IOTRAP_NEXT1 ; Jump if more entries

	 stc			; Mark as not found
INT2F_IOTRAP_DONE1:
	 mov	 ax,@IOTRAP_ERR_DI_IO ; DI_wPort in use by other I/O handler
	 jnc	 near ptr INT2F_IOTRAP_ERR ; Jump if duplicate found

; Loop through the entries to check the I/O permission bits used by MM

	 mov	 cx,[ebp].INTXX_ECX.ELO ; Get the # entries in I/O dispatch tab
	 mov	 esi,PGROUP:[ebx].IOTRAP_LaTAB ; Get the LA of the table
	 mov	 edi,PIOBIT	; Get offset in PGROUP of I/O bit map
@@:
	 movzx	 eax,AGROUP:[esi].DI_wPORT ; Get the I/O port #
	 bt	 PGROUP:[edi].EDD,eax ; Check the I/O permission bit
	 mov	 ax,@IOTRAP_ERR_DI_MM ; DI_wPort in use by MM
	 jc	 near ptr INT2F_IOTRAP_ERR ; Jump if already trapped

	 add	 esi,type DISPATCH_INFO ; Skip to next entry

	 loop	 @B		; Jump if more entries

; Loop through the entries to set the I/O permission bits

	 mov	 cx,[ebp].INTXX_ECX.ELO ; Get the # entries in I/O dispatch tab
	 mov	 esi,PGROUP:[ebx].IOTRAP_LaTAB ; Get the LA of the table
	 mov	 edi,PIOBIT	; Get offset in PGROUP of I/O bit map
@@:
	 movzx	 eax,AGROUP:[esi].DI_wPORT ; Get the I/O port #
	 bts	 PGROUP:[edi].EDD,eax ; Set the I/O permission bit

	 add	 esi,type DISPATCH_INFO ; Skip to next entry

	 loop	 @B		; Jump if more entries

; Mark this entry as in use

	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get the # entries in I/O dispatch tab
	 mov	 PGROUP:[ebx].IOTRAP_TABCNT,ax ; Mark as in use

; Return the handle (which for us is the struc index)

	 mov	 eax,ebx	; Get current offset
	 sub	 eax,PIOTRAP	; Less base address
	 xor	 dx,dx		; Zero to use DX:AX as dword
	 mov	 bx,type IOTRAP_STR ; Get struc size
	 div	 bx		; Divide to get entry #
	 inc	 ax		; Ensure non-zero (MS says so)
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save as return value

	 jmp	 short INT2F_IOTRAP_EXIT ; Join common exit code


COMMENT|

Uninstall a handler

On entry:

SI	 =	 handle

|

INT2F_IOTRAP_UNINST:
	 movzx	 ebx,[ebp].INTXX_ESI.ELO ; Get the handle
	 dec	 ebx		; Restore to index (see above MS comment)
	 imul	 ebx,type IOTRAP_STR ; Times size of table

	 cmp	 ebx,@IOTRAP_MAX*(type IOTRAP_STR) ; Izit a valid handle?
	 mov	 ax,@IOTRAP_ERR_HNDINV ; Invalid handle
	 jae	 short INT2F_IOTRAP_ERR ; Jump if not

	 add	 ebx,PIOTRAP	; Plus offset in PGROUP to table base

	 xor	 cx,cx		; Swap with zero
	 xchg	 cx,PGROUP:[ebx].IOTRAP_TABCNT ; Delete the entry
	 mov	 ax,@IOTRAP_ERR_HNDREM ; Handle already removed
	 jcxz	 INT2F_IOTRAP_ERR ; Jump if already deleted

	 mov	 esi,PGROUP:[ebx].IOTRAP_LaTAB ; Get linear address of table
	 mov	 edi,PIOBIT	; Get offset in PGROUP of I/O bit map
	 xor	 eax,eax	; Zero to use as dword
	 xor	 dx,dx		; Zero error count
@@:
	 mov	 ax,AGROUP:[esi].DI_wPORT ; Get the I/O port #
	 btr	 PGROUP:[edi].EDD,eax ; Clear the I/O permission bit
	 sbb	 dx,-1		; Count in error

	 add	 esi,type DISPATCH_INFO ; Skip to next entry

	 loop	 @B		; Jump if more I/O ports to delete

	 and	 dx,dx		; Any errors?
	 mov	 ax,@IOTRAP_ERR_DI_REM ; DI_wPort already removed
	 jnz	 short INT2F_IOTRAP_ERR ; Jump if so

	 jmp	 short INT2F_IOTRAP_EXIT ; Join common exit code


COMMENT|

Get I/O driver version and capabilities

On exit:

AH	 =	 Major version #
AL	 =	 Minor ...
BX	 =	 Flags
		 Bit 0:  I/O trapping supported in DPMI clients
		 Bit 1:  Width of I/O returned in ECX
		 Bit 2:  Error codes returned in AX
DX	 =	 minimum allowed I/O port

|

INT2F_IOTRAP_CAP:
	 cmp	 [ebp].INTXX_EBX.ELO,3 ; Split cases
	 mov	 ax,@IOTRAP_ERR_BADFN ; Invalid subfunction
	 jne	 short INT2F_IOTRAP_ERR ; Jump if not valid

	 mov	 [ebp].INTXX_EAX.ELO,0200h ; Return version #
	 mov	 [ebp].INTXX_EBX.ELO,1*@IOTRAP_CAP_ERRCOD or \
				     1*@IOTRAP_CAP_WIDTH  or \
				     0*@IOTRAP_CAP_DPMI ; Return flags
	 mov	 [ebp].INTXX_EDX.ELO,@IOTRAP_MINIO ; Return minimum I/O port

	 jmp	 short INT2F_IOTRAP_EXIT ; Join common exit code

INT2F_IOTRAP_ERR:
	 or	 [ebp].INTXX_EFL.ELO,mask $CF ; CF=1
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save error code
INT2F_IOTRAP_EXIT:
	 REGREST <gs,ds>	; Restore
	 assume  ds:nothing,gs:nothing ; Tell the assembler

	 popad			; Restore

	 add	 esp,size INTXX_ERR ; Strip off error code

	 iretd			; Return to caller with CF significant


INT2F_INTRETVM2:
	 jmp	 INTPROC2F	; Jump to next handler in sequence

INT2F_XMS:
	 mov	 [esp].NRM_INTNO,4*2Fh + offset PGROUP:INTPROC00Z ; Mark as INT 2Fh

	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All GP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 ebx,[ebp].INTXX_EIP ; Get offset of INTCOM-restartable point
	 xchg	 ebx,LAST_INTCOM ; Swap with previous frame offset
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 ebx,0		; Save previous flag
	 mov	 [ebp].INTXX_ICOMLO,bx ; Save it
	 shr	 ebx,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_ICOMHI,bx ; Save it

	 and	 GLB_FLAG,not @GLB_P67 ; Not coming from I/O port for INT 67h

	 cmp	 ah,XMS_CNT	; Check for valid subfunction range
	 jb	 short @F	; Jump if in range

	 sub	 ah,88h 	; Convert to origin-88
	 jc	 near ptr XMS_E80 ; Jump if out of range

	 cmp	 ah,XMS2_CNT	; Check for valid subfunction range
	 jnb	 near ptr XMS_E80 ; Jump if it's too big

	 add	 ah,XMS_CNT	; Convert to appendage to XMS_FNS
@@:
	 cmp	 ah,@XMS_VERS	; Request version #?
	 je	 short XMS_SPLIT ; Yes, skip $XMS_I15 check

; Installed XMS INT 15h as yet or is the HMA permanently unavailable?

	 test	 XMS_FLAG,(mask $XMS_I15) or (mask $XMS_XHMA)
	 jnz	 short XMS_SPLIT ; Yes

; Install it only if we're requesting the HMA,
;			   querying XMB size, (to enable use of EX2SIZE)
;			   requesting an XMB, or
;			   enabling A20

	 cmp	 ah,@XMS_REQHMA ; Izit request HMA?
	 je	 short XMS_INST ; Yes, attempt to install

	 cmp	 ah,@XMS_QRYXMB ; Izit query XMB?
	 je	 short XMS_INST ; Yes, attempt to install

	 cmp	 ah,@XMS_GETXMB ; Izit allocate XMB?
	 je	 short XMS_INST ; Yes, attempt to install

	 cmp	 ah,@XMS_QRY2XMB+XMS_CNT-88h ; Izit secondary query XMB?
	 je	 short XMS_INST ; Yes, attempt to install

	 cmp	 ah,@XMS_GET2XMB+XMS_CNT-88h ; Izit secondary allocate XMB?
	 je	 short XMS_INST ; Yes, attempt to install

	 cmp	 ah,@XMS_LCLENA ; Izit local A20 enable?
	 je	 short XMS_INST ; Yes, attempt to install

	 cmp	 ah,@XMS_GLBENA ; Izit global A20 enable?
	 jne	 short XMS_SPLIT ; Not this time
XMS_INST:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 short XMS_NOHMA ; Jump if present

	 call	 APPEND_EXT	; Append it
	 jnc	 short XMS_SPLIT ; Join common function code
				; Fall though to no HMA code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it

XMS_NOHMA:
	 or	 XMS_FLAG,mask $XMS_XHMA ; Mark as permanently unavailable
XMS_SPLIT:
	 sti			; Allow interrupts

	 test	 DB2_FLAG,@DB2_XMS ; Call SWAT on XMS calls?
	 jnz	 short XMS_SWAT ; Yes
XMS_SPLIT1:
	 movzx	 ebx,ah 	; Copy function number

	 jmp	 XMS_FNS[ebx*2] ; Take appropriate action

XMS_SWAT:
	 int	 01h		; Call our debugger

	 jmp	 short XMS_SPLIT1 ; Continue on

if @OEM_WIN3
	 public  XMS_VXDIN
XMS_VXDIN:
	 cmp	 ah,XMS_CNT	; Check for valid subfunction range
	 jb	 short @F	; Jump if in range

	 sub	 ah,88h 	; Convert to origin-88
	 jc	 near ptr XMS_E80 ; Jump if out of range

	 cmp	 ah,XMS2_CNT	; Check for valid subfunction range
	 jnb	 near ptr XMS_E80 ; Jump if it's too big

	 add	 ah,XMS_CNT	; Convert to appendage to XMS_FNS
@@:
	 jmp	 short XMS_SPLIT1 ; Join common code

endif				; IF @OEM_WIN3


; Successful return

	 public  XMS_SUCCESS
XMS_SUCCESS:
	 sti			; Allow interrupts

; Because some bozo XMS clients check CF, we need to clear it on success

	 and	 [ebp].INTXX_EFL.ELO,not (mask $CF) ; CF=0

	 mov	 ax,1		; Universal success return code

if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 ja	 near ptr XMS_VXDOUT ; Jump if so
endif				; IF @OEM_WIN3

	 jmp	 EMM_EXIT	; Join common EMM exit code with result in AX

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; Error returns

XMS_E00:
	 mov	 al,00h 	; A20 disabled

	 jmp	 short @F	; Join common error code

XMS_E80:
	 mov	 al,80h 	; Function not implemented

	 jmp	 short @F	; Join common error code

XMS_E81:
	 mov	 al,81h 	; VDISK installed or Weitek support active
@@:
	 jmp	 short XMS_ERR	; Join common error code

XMS_E8F@:
	 add	 esp,size MOVXMB_STR ; Strip from the stack
XMS_E8F:
	 mov	 al,8Fh 	; Unrecoverable driver error (MAC error)

	 jmp	 short XMS_ERR	; Join common error code

XMS_E91:
	 mov	 al,91h 	; HMA already in use

	 jmp	 short XMS_ERR	; Join common error code

XMS_E92:
	 mov	 al,92h 	; Requested HMA size < HMAMIN

	 jmp	 short XMS_ERR	; Join common error code

XMS_E93:
	 mov	 al,93h 	; HMA not allocated

	 jmp	 short XMS_ERR	; Join common error code

XMS_EA0:
	 mov	 al,0A0h	; Insufficient extended memory

	 jmp	 short XMS_ERR	; Join common error code

XMS_EA1:
	 mov	 al,0A1h	; No handles available

	 jmp	 short XMS_ERR	; Join common error code

XMS_EA2:
	 mov	 al,0A2h	; Invalid handle

	 jmp	 short XMS_ERR	; Join common error code

XMS_EA3@:
	 add	 esp,size MOVXMB_STR ; Strip from the stack
XMS_EA3:
	 mov	 al,0A3h	; Move source handle invalid

	 jmp	 short XMS_ERR	; Join common error code

XMS_EA4@:
	 add	 esp,size MOVXMB_STR ; Strip from the stack
XMS_EA4:
	 mov	 al,0A4h	; Move source offset invalid

	 jmp	 short XMS_ERR	; Join common error code

XMS_EA5@:
	 add	 esp,size MOVXMB_STR ; Strip from the stack
XMS_EA5:
	 mov	 al,0A5h	; Move destin handle invalid

	 jmp	 short XMS_ERR	; Join common error code

XMS_EA6@:
	 add	 esp,size MOVXMB_STR ; Strip from the stack
XMS_EA6:
	 mov	 al,0A6h	; Move destin offset invalid

	 jmp	 short XMS_ERR	; Join common error code

XMS_EA7@:
	 add	 esp,size MOVXMB_STR ; Strip from the stack
XMS_EA7:
	 mov	 al,0A7h	; Move length invalid

	 jmp	 short XMS_ERR	; Join common error code

XMS_EA8@:
	 add	 esp,size MOVXMB_STR ; Strip from the stack
XMS_EA8:
	 mov	 al,0A8h	; Destructive move overlap

	 jmp	 short XMS_ERR	; Join common error code

XMS_EAA:
	 mov	 al,0AAh	; Block not locked

	 jmp	 short XMS_ERR	; Join common error code

XMS_EAB:
	 mov	 al,0ABh	; Block is locked

	 jmp	 short XMS_ERR	; Join common error code

XMS_EAC:
	 mov	 al,0ACh	; Lock count overflow

	 jmp	 short XMS_ERR	; Join common error code

XMS_EB0:
	 mov	 al,0B0h	; Smaller UMB available

	 jmp	 short XMS_ERR	; Join common error code

XMS_EB1:
	 mov	 al,0B1h	; No UMBs available

	 jmp	 short XMS_ERR	; Join common error code

XMS_EB2:
	 mov	 al,0B2h	; UMB segment number invalid

	 jmp	 short XMS_ERR	; Join common error code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it

; General Error Return

	 public  XMS_ERR
XMS_ERR:
	 sti			; Allow interrupts

	 mov	 [ebp].INTXX_EBX.ELO.LO,al ; Save error code in BL

; Because some bozo XMS clients check CF, we need to set it on error

	 or	 [ebp].INTXX_EFL.ELO,mask $CF ; CF=1

	 call	 CHECK_HOOK	; See if we should unhook INT 15h

	 xor	 ax,ax		; Universal error return code

if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 ja	 near ptr XMS_VXDOUT ; Jump if so
endif				; IF @OEM_WIN3

	 jmp	 EMM_EXIT	; Join common EMM exit code with result in AX

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 00h -- Return major/minor/debugging version #

On exit:

AH	 =	 major version # (BCD format)
AL	 =	 minor ...
BX	 =	 debugging version # (unspecified format)
DX	 =	 1 if HMA exists
	 =	 0 otherwise

No errors possible.

|

	 public  XMS_VERS
XMS_VERS:

; The HMA exists iff there is no VDISK signature at 1MB
; and it isn't already permanently unavailable

	 mov	 ax,1		; Assume no VDISK

	 bt	 XMS_FLAG,$XMS_XHMA ; Izit permanently unavailable?
	 jc	 short @F	; Jump if so (note CF=1)

	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
				; Return CF=1 if VDISK found
@@:
	 sbb	 ax,0		; Decrement AX if VDISK found
	 mov	 [ebp].INTXX_EDX.ELO,ax ; Return in caller's DX

	 mov	 ah,VERS_H-'0'  ; Get hundreds digit
	 mov	 al,VERS_T-'0'  ; Get tens digit
	 shl	 al,4		; Shift to high-order nibble
	 or	 al,VERS_U-'0'  ; Include units digit
	 mov	 [ebp].INTXX_EBX.ELO,ax ; Debugging version #

	 mov	 ax,0300h	; Major/minor version #

; Because some bozo XMS clients check CF, we need to clear it on success

	 and	 [ebp].INTXX_EFL.ELO,not (mask $CF) ; CF=0

	 jmp	 EMM_EXIT	; Join common EMM exit code with result in AX

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 01h -- Request High Memory Area

If the HMA is not already in use, Weitek support is inactive,
and there's no VDISK signature at 1MB, grant the request.

On exit:

AX	 =	 1 if successful
	 =	 0 otherwise

Errors:

81	 =	 VDISK found or Weitek support active
91	 =	 HMA already in use
92	 =	 requested size < HMAMIN

|

	 public  XMS_REQHMA
XMS_REQHMA:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81  ; Jump if VDISK found

	 test	 XMS_FLAG,mask $XMS_XHMA ; Izit permanently unavailable?
	 jnz	 near ptr XMS_E91  ; Yes, so that's an error

	 test	 GLB_FLAG,@GLB_HMA ; Izit already in use?
	 jnz	 near ptr XMS_E91 ; Yes, so that's an error

	 cmp	 dx,HMAMIN	; Check against minimum required
	 jb	 near ptr XMS_E92 ; Jump if it's too small

	 or	 GLB_FLAG,@GLB_HMA ; Mark as in use

	 jmp	 XMS_SUCCESS	; Join common XMS success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 02h -- Release High Memory Area

If the HMA is already in use, grant the request.

On exit:

AX	 =	 1 if successful
	 =	 0 otherwise

Note we don't install if there isn't an HMA. *FIXME*

Errors:

81	 =	 VDISK found or Weitek support active
93	 =	 HMA not already in use

|

	 public  XMS_RELHMA
XMS_RELHMA:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 test	 GLB_FLAG,@GLB_HMA ; Izit already in use?
	 jz	 near ptr XMS_E93 ; No, so that's an error

	 and	 GLB_FLAG,not @GLB_HMA ; Mark as not in use

	 call	 CHECK_HOOK	; See if we should unhook INT 15h

	 jmp	 XMS_SUCCESS	; Join common XMS success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 03h -- Global Enable A20

If no VDISK installed and Weitek support is inactive, grant the request.

On exit:

AX	 =	 1 if successful
	 =	 0 otherwise

Errors:

81	 =	 VDISK found or Weitek support active

|

	 public  XMS_GLBENA
XMS_GLBENA:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 cli			; Disallow interrupts

	 bts	 XMS_FLAG,$XMS_A20 ; Izit already enabled?
	 jc	 near ptr XMS_SUCCESS ; Jump if so

	 jmp	 XMS_LCLENA_COM ; Join common local A20 enable code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 04h -- Global Disable A20

If VDISK installed or Weitek support is active, signal an error.
Otherwise, disable the A20 line.

On exit:

AX	 =	 1 if A20 still enabled
	 =	 0 if VDISK installed or Weitek support active

Errors:

81	 =	 VDISK found or Weitek support active

|

	 public  XMS_GLBDIS
XMS_GLBDIS:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 cli			; Disallow interrupts

	 and	 XMS_FLAG,not (mask $XMS_A20) ; Reset the bit

	 jmp	 XMS_LCLDIS_COM ; Join common local A20 disable code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 05h -- Local Enable A20

If Weitek support is inactive, grant the request.

On exit:

AX	 =	 1 if successful
	 =	 0 otherwise

Errors:

81	 =	 VDISK found or Weitek support active

|

	 public  XMS_LCLENA
XMS_LCLENA:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 cli			; Disallow interrupts

	 public  XMS_LCLENA_COM
XMS_LCLENA_COM:
	 inc	 A20CNT 	; Count in another one

	 test	 GLB_FLAG,@GLB_X1MB ; Check the state
	 jnz	 short @F	; Jump if already enabled

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_DISABLE	; Disable the 1MB wrap

	 or	 GLB_FLAG,@GLB_X1MB ; Enable the virtual A20 line
@@:

;;; ; For debugging only
;;;
;;;	     mov     eax,PRGPDT     ; Get offset in PGROUP of PDT
;;;	     mov     eax,PGROUP:[eax+((1024*1024) shr (12-2))] ; Get 1st PTE at 1MB
;;;	     and     ax,mask $PTE_FRM ; Isolate 4KB frame
;;;
;;;	     cmp     eax,CON1MB     ; Izit at 1MB?
;;;	     je      short @F	    ; Jump if so
;;;
;;;	     int     03h	    ; Call our debugger
;;; @@:
	 jmp	 XMS_SUCCESS	; Join common XMS success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 06h -- Local Disable A20

If Weitek support is active, signal an error.
If the count returns to zero, disable the A20 line.

On exit:

AX	 =	 1 if A20 still enabled
	 =	 0 if Weitek support active, or
		   if A20 disabled

Errors:

81	 =	 VDISK found or Weitek support active

|

	 public  XMS_LCLDIS
XMS_LCLDIS:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 cli			; Disallow interrupts

	 public  XMS_LCLDIS_COM
XMS_LCLDIS_COM:
	 cmp	 A20CNT,@A20DEF ; Check the current A20 count
	 je	 short XMS_LCLDIS1 ; Jump if it's already disabled

	 dec	 A20CNT 	; Remove another level
	 jnz	 short XMS_LCLDIS1 ; Jump if no need to enable

	 test	 XMS_FLAG,mask $XMS_A20 ; Izit enabled globally?
	 jnz	 short XMS_LCLDIS1 ; Yes, don't actually disable it

	 and	 GLB_FLAG,not @GLB_X1MB ; Disable the virtual A20 line

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_ENABLE	; Enable the 1MB wrap
XMS_LCLDIS1:
	 call	 CHECK_HOOK	; See if we should unhook INT 15h

;;; ; For debugging only
;;;
;;;	     mov     eax,PRGPDT     ; Get offset in PGROUP of PDT
;;;	     mov     eax,PGROUP:[eax+((1024*1024) shr (12-2))] ; Get 1st PTE at 1MB
;;;	     and     ax,mask $PTE_FRM ; Isolate 4KB frame
;;;
;;;	     cmp     eax,0	    ; Izit at 0MB?
;;;	     je      short @F	    ; Jump if so
;;;
;;;	     int     03h	    ; Call our debugger
;;; @@:
	 jmp	 XMS_SUCCESS	; Join common success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 07h -- Query status of A20 line

On exit:

AX	 =	 1 if A20 enabled
	 =	 0 if A20 disabled

Errors:

81	 =	 VDISK found or Weitek support active

|

	 public  XMS_QRYA20
XMS_QRYA20:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 mov	 [ebp].INTXX_EBX.ELO.LO,0 ; Mark as successful with BL=00h

	 test	 GLB_FLAG,@GLB_X1MB ; Check the status
	 jnz	 near ptr XMS_SUCCESS ; Jump if enabled

	 jmp	 XMS_E00	; Jump if disabled

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 08h -- Query free extended memory, primary function
	 88h -- Query free extended memory, secondary function

On exit:

AX	 =	 size of largest XMS block in kilobytes
DX	 =	 total amount of free extended memory
BL	 =	 0 if successful, otherwise contains error code (AX=0)

If entered at XMS_QRY2XMB,

EAX	 =	 size of largest XMS block in kilobytes
ECX	 =	 highest ending address of any memory block
EDX	 =	 total amount of free extended memory
BL	 =	 0 if successful, otherwise contains error code (EAX=0)

Errors:

81	 =	 VDISK found or Weitek support active
A0	 =	 Insufficient extended memory

|

	 public  XMS_QRYXMB
XMS_QRYXMB:
	 mov	 cl,0		; Mark as primary function

	 jmp	 short XMS_QRYXMB_COM ; Join common code

	 public  XMS_QRY2XMB
XMS_QRY2XMB:
	 mov	 eax,CMPSIZEXT	; Get size of EXT/XMS CMP
	 add	 eax,HMASIZE	; Plus size of HMA (0 or 64KB)
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 add	 eax,CON1MB	; Plus base of extended memory
	 dec	 eax		; Back off to last byte
	 mov	 [ebp].INTXX_ECX,eax ; Return as ECX

	 mov	 cl,1		; Mark as secondary function
XMS_QRYXMB_COM:
	 mov	 [ebp].INTXX_EBX.ELO.LO,0 ; Clear error return code for
				; apps that don't check AX (like Framework)
	 mov	 [ebp].INTXX_EDX.ELO,0 ; In case there's a VDISK/Weitek active

	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 push	 @ALLOC_XMS	; Pass allocation type
	 call	 QRY_PGCNT	; Return with EAX = # available 1KB
				; ...	      EDX = size of largest

	 xchg	 eax,edx	; Swap to more convenient registers

	 cmp	 cl,0		; Izit primary function?
	 je	 short XMS_QRYXMB2 ; Jump if so
				; Fall through to secondary function
	 mov	 [ebp].INTXX_EAX,eax ; Return as EAX
	 mov	 [ebp].INTXX_EDX,edx ; Return as EDX

	 jmp	 short XMS_QRYXMB3 ; Join common code

XMS_QRYXMB2:
	 cmp	 eax,0FFFFh	; Izit bigger than 16-bits?
	 jbe	 short @F	; Jump if not

	 mov	 eax,0FFFFh	; Use maximum
@@:
	 cmp	 edx,0FFFFh	; Izit bigger than 16-bits?
	 jbe	 short @F	; Jump if not

	 mov	 edx,0FFFFh	; Use maximum
@@:
	 mov	 [ebp].INTXX_EDX.ELO,dx ; Return as DX
XMS_QRYXMB3:
	 call	 CHECK_HOOK	; See if we should unhook INT 15h

; Because some bozo XMS clients check CF, we need to clear it on success

	 and	 [ebp].INTXX_EFL.ELO,not (mask $CF) ; CF=0

	 and	 eax,eax	; Any memory?
	 jnz	 near ptr EMM_EXIT ; Join common EMM exit code with result in AX

	 jmp	 XMS_EA0	; Jump if no XMBs available

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 09h -- Allocate extended memory block, primary function
	 89h -- Allocate extended memory block, secondary function

On entry:

DX	 =	 amount of extended memory requested in kilobytes

If entered at XMS_GET2XMB,

EDX	 =	 amount of extended memory requested in kilobytes

On exit:

If successful,

AX	 =	 1
DX	 =	 handle associated with block

If not successful,

AX	 =	 0
DX	 =	 0

Errors:

81	 =	 VDISK found or Weitek support active
A0	 =	 Insufficient extended memory
A1	 =	 No handles available

|

	 public  XMS_GETXMB
XMS_GETXMB:
	 xor	 ecx,ecx	; A Handy 0
	 jmp	 short @F	; Join common code

	 public  XMS_GET2XMB
XMS_GET2XMB:
	 mov	 ecx,[ebp].INTXX_EDX ; Load 32 bit value
	 xor	 cx,cx		; Handy 0
@@:

	 xchg	 cx,[ebp].INTXX_EDX.ELO ; Get requested size
					; Plug in a zero for callers DX in
					; case of allocation failure

	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 cli			; Disallow interrupts
				; to ensure handle count and available
				; memory doesn't change on us

; Find a free handle

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 ecx		; Save for a moment

	 mov	 edi,PXMSHNDL	; ES:EDI ==> available handles
	 movzx	 ecx,XMSNHNDL	; # handles to search through
	 mov	 al,@H_AVAIL	; Get free handle marker
   repne scas	 PGROUP:[edi].LO ; Look for it

	 pop	 ecx		; Restore
	 jne	 near ptr XMS_EA1 ; Jump if no free handles

	 sub	 edi,PXMSHNDL	; Convert to origin-1
	 dec	 edi		; Convert to origin-0
	 mov	 edx,edi	; Copy to handle register, zero high-order word

; EDX is an available handle #

	 shl	 ecx,10-0	; Convert from 1KB to bytes

; Allocate memory from the free chain

; Register usage:

; EDX	 =	 handle #
; ECX	 =	 # bytes to allocate

	 mov	 ebx,@ZEROLEN_BASE ; Use pseudo-base
	 jecxz	 XMS_GETXMB_ZEROLEN ; Jump if zero-length handle

	 push	 @ALLOC_XMS	; Tell 'em what kind of memory we're allocating
	 push	 ecx		; Pass # bytes to allocate
	 call	 ALLOCMEM	; Allocate 'em
	 assume  fs:nothing	; Tell the assembler about it
				; Return with EBX = linear address of memory
	 jc	 near ptr XMS_EA0 ; Jump if there's not enough memory
XMS_GETXMB_ZEROLEN:
	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 PGROUP:[esi+edx*4],ebx ; Save as base of newly allocated block

	 mov	 esi,PXMSHNDL	; Get offset of XMSHNDL table
	 mov	 PGROUP:[esi+edx].LO,@H_INUSE ; Mark handle as in use

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 PGROUP:[esi+edx*4],ecx ; Save as block size in bytes
	 sub	 PGROUP:[esi+  0*4],ecx ; Remove from total available memory

	 mov	 [ebp].INTXX_EDX.ELO,dx ; Return handle # in DX

	 inc	 XHNDLCNT	; Count in another handle

if @OEM_DEBUG and @OEM_XMS
	 test	 DB3_FLAG,@DB3_XPTE ; Should we check XMS PTEs?
	 jz	 short @F	; Jump if not

	 call	 XMSPTE_CLR	; Disable access to XMS PTEs for handle EDX
@@:
endif				; IF @OEM_DEBUG and @OEM_XMS
	 jmp	 XMS_SUCCESS	; Join common XMS success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 0Ah -- Release extended memory block

On entry:

AH	 =	 function #
DX	 =	 handle of block to free

On exit:

AX	 =	 1 if successful
	 =	 0 otherwise

Errors:

81	 =	 VDISK found or Weitek support active
A2	 =	 Invalid handle
AB	 =	 Handle locked

|

	 public  XMS_RELXMB
XMS_RELXMB:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 and	 dx,dx		; Ensure not the free chain handle
	 jz	 near ptr XMS_EA2 ; It is, so that's an error

	 call	 VALID_XHNDL	; Izit in use?
	 jnz	 near ptr XMS_EA2 ; No, so that's an error

	 mov	 esi,PXMSLOCK	; Get offset of XMSLOCK table

	 cmp	 PGROUP:[esi+edx].LO,0 ; Ensure unlocked
	 jne	 near ptr XMS_EAB ; Jump if not

	 cli			; Disallow interrupts

	 dec	 XHNDLCNT	; Count out another handle

	 mov	 esi,PXMSHNDL	; Get offset of XMSHNDL table
	 mov	 PGROUP:[esi+edx].LO,@H_AVAIL ; Mark the handle as available

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 ecx,PGROUP:[esi+edx*4] ; Get the length of the handle in bytes
	 jecxz	 XMS_RELXMB_EXIT ; Jump if zero-length handle

	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 edi,PGROUP:[esi+edx*4] ; Get the starting base

if @OEM_DEBUG and @OEM_XMS
	 test	 DB3_FLAG,@DB3_XPTE ; Should we check XMS PTEs?
	 jz	 short @F	; Jump if not

	 call	 XMSPTE_SET	; Enable access to XMS PTEs for handle EDX
@@:
endif				; IF @OEM_DEBUG and @OEM_XMS

; Deallocate ECX bytes at EDI

	 push	 ecx		; Pass byte length
	 push	 edi		; Pass starting linear address
	 call	 DEALLOCMEM	; Deallocate the memory
;;;;;;;; jc	 short ???	; Ignore error return
XMS_RELXMB_EXIT:
	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 PGROUP:[esi+edx*4].EDD,-1 ; Clear the base address

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 PGROUP:[esi+edx*4].EDD,0 ; Clear the size

	 call	 CHECK_HOOK	; See if we should unhook INT 15h

	 sti			; Allow interrupts

	 jmp	 XMS_SUCCESS	; Join common success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 0Bh -- Move extended memory block

On entry:

DS3:SI3  ==>	 EXTMOVE_STR

On exit:


AX	 =	 1, if successful
	 =	 0, if not

Errors:

81	 =	 VDISK found or Weitek support active
A3	 =	 Move source handle invalid
A4	 =	 Move source offset invalid
A5	 =	 Move destin handle invalid
A6	 =	 Move destin offset invalid
A7	 =	 Move length invalid
A8	 =	 Destructive move overlap

|

EXTMOVE_STR struc

EXTMOVE_LEN dd	 ?		; Length of move
EXTMOVE_SHNDL dw ?		; Source handle
EXTMOVE_SOFF  dd ?		; Source offset
EXTMOVE_DHNDL dw ?		; Destin handle
EXTMOVE_DOFF  dd ?		; Destin offset

EXTMOVE_STR ends


MOVXMB_STR struc

MOVXMB_EXT db	 (size EXTMOVE_STR) dup (?)

MOVXMB_STR ends


	 public  XMS_MOVXMB
XMS_MOVXMB:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

; During error checking, we can't allow any interruptions

	 cli			; Disallow interrupts

	 push	 ss		; Get our data selector
	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it

	 movzx	 eax,[ebp].INTXX_DS ; Get caller's DS
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,[ebp].INTXX_ESI.ELO ; Get caller's SI
	 add	 esi,eax	; GS:ESI = EXTMOVE_STR

; Copy to local storage for easier addressibility through ss:[ebx]

	 sub	 esp,size MOVXMB_STR ; Make room on the stack
	 lea	 edi,[esp].MOVXMB_EXT ; ES:EDI ==> local save area
	 mov	 ebx,edi	; SS:EBX ==> EXTMOVE_STR
	 mov	 ecx,size EXTMOVE_STR ; Size of move in bytes
S32  rep movs	 <es:[edi].LO,AGROUP:[esi].LO> ; Copy to local storage

; Put source linear address into ESI

	 mov	 dx,ss:[ebx].MOVXMB_EXT.EXTMOVE_SHNDL ; Get source handle

	 and	 dx,dx		; Check for handle zero
	 jz	 short XMS_MOVXMB1 ; Jump if we handle specially

	 call	 VALID_XHNDL	; Izit in use?
	 jnz	 near ptr XMS_EA3@ ; No, so that's an error

	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 esi,PGROUP:[esi+edx*4] ; Get the starting base
	 mov	 eax,ss:[ebx].MOVXMB_EXT.EXTMOVE_SOFF ; Get initial offset
	 add	 esi,eax	; Add to get source starting point

; Ensure source offset + move length is within bounds

	 mov	 ecx,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 ecx,PGROUP:[ecx+edx*4] ; Get size of this handle

	 cmp	 eax,ecx	; Ensure source offset is within bounds
	 ja	 near ptr XMS_EA4@ ; Jump if the source offset is invalid

	 add	 eax,ss:[ebx].MOVXMB_EXT.EXTMOVE_LEN ; Plus move length
	 jc	 near ptr XMS_EA7@ ; Jump if the length is invalid

	 cmp	 eax,ecx	; Ensure source offset is within bounds
	 ja	 near ptr XMS_EA7@ ; Jump if the length is invalid

	 jmp	 short XMS_MOVXMB2 ; Join common code


; Source is conventional memory

XMS_MOVXMB1:
	 movzx	 esi,ss:[ebx].MOVXMB_EXT.EXTMOVE_SOFF.VSEG ; Get segment
	 shl	 esi,4-0	; Convert from paras to bytes
	 movzx	 eax,ss:[ebx].MOVXMB_EXT.EXTMOVE_SOFF.VOFF ; Get offset
	 add	 esi,eax	; ESI = 32-bit linear address

; Ensure source offset + length is within conventional memory

	 mov	 eax,ss:[ebx].MOVXMB_EXT.EXTMOVE_LEN ; Get move length
	 add	 eax,esi	; Plus source offset

	 cmp	 eax,CON10FFF0	; Check against maximum length
	 ja	 near ptr XMS_EA7@ ; Jump if outside bounds
XMS_MOVXMB2:

; Put destin linear address into EDI

	 mov	 dx,ss:[ebx].MOVXMB_EXT.EXTMOVE_DHNDL ; Get destin handle

	 and	 dx,dx		; Check for handle zero
	 jz	 short XMS_MOVXMB3 ; Jump if we handle specially

	 call	 VALID_XHNDL	; Izit in use?
	 jnz	 near ptr XMS_EA5@ ; No, so that's an error

	 mov	 edi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 edi,PGROUP:[edi+edx*4] ; Get the starting base
	 mov	 eax,ss:[ebx].MOVXMB_EXT.EXTMOVE_DOFF ; Get initial offset
	 add	 edi,eax	; Add to get destin starting point

; Ensure destin offset + move length is within bounds

	 mov	 ecx,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 ecx,PGROUP:[ecx+edx*4] ; Get size of this handle

	 cmp	 eax,ecx	; Ensure destin offset is within bounds
	 ja	 near ptr XMS_EA6@ ; Jump if the destin offset is invalid

	 add	 eax,ss:[ebx].MOVXMB_EXT.EXTMOVE_LEN ; Plus move length
	 jc	 near ptr XMS_EA7@ ; Jump if the length is invalid

	 cmp	 eax,ecx	; Ensure destin offset is within bounds
	 ja	 near ptr XMS_EA7@ ; Jump if the length is invalid

	 jmp	 short XMS_MOVXMB4 ; Join common code


; Destin is conventional memory

XMS_MOVXMB3:
	 movzx	 edi,ss:[ebx].MOVXMB_EXT.EXTMOVE_DOFF.VSEG ; Get segment
	 shl	 edi,4-0	; Convert from paras to bytes
	 movzx	 eax,ss:[ebx].MOVXMB_EXT.EXTMOVE_DOFF.VOFF ; Get offset
	 add	 edi,eax	; EDI = 32-bit linear address

; Ensure destin offset + length is within conventional memory

	 mov	 eax,ss:[ebx].MOVXMB_EXT.EXTMOVE_LEN ; Get move length
	 add	 eax,edi	; Plus destin offset

	 cmp	 eax,CON10FFF0	; Check against maximum length
	 ja	 near ptr XMS_EA7@ ; Jump if outside bounds
XMS_MOVXMB4:
	 mov	 ecx,ss:[ebx].MOVXMB_EXT.EXTMOVE_LEN ; Get move length

	 and	 ecx,ecx	; Check move length
	 jz	 near ptr XMS_SUCCESS ; Jump if nothing to move

	 test	 cx,@BIT0	; Ensure even length
	 jnz	 near ptr XMS_EA7@ ; Not this time

; Check for destructive overlap

	 mov	 ax,ss:[ebx].MOVXMB_EXT.EXTMOVE_SHNDL ; Get source handle

	 cmp	 ax,ss:[ebx].MOVXMB_EXT.EXTMOVE_DHNDL ; Same as destin?
	 jne	 short XMS_MOVXMB5 ; No, can't be destructive overlap

; If the two handles are for an XMB, the offsets in ESI and EDI point
; within the block and are comparable.

; If the two handles are for conventional memory, the offsets in ESI and EDI
; point within conventional memory and also comparable.

; The two areas overlap destructively iff
;   SRCOFF < DSTOFF < SRCOFF+LEN

	 cmp	 esi,edi	; Check first inequality
	 jae	 short XMS_MOVXMB5 ; Jump if non-destructive

	 lea	 eax,[esi+ecx]	; EAX ==> end of source move

	 cmp	 edi,eax	; Check against starting destination offset
	 jb	 near ptr XMS_EA8@ ; It's destructive, so that's an error
XMS_MOVXMB5:

COMMENT|

Extended memory move, no overlap or non-destructive overlap.

On entry:

ECX	 =	 length
GS:ESI	 ==>	 source base
ES:EDI	 ==>	 destin base

Either of both of which might be in conventional or extended memory

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

XMS_MOVXMB_NDO:
if @OEM_WIN3

; If we're in a VxD call, translate the addresses in ESI and EDI for ECX
; bytes into physical, then linear addresses

	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 je	 short XMS_MOVXMB_XVXD ; Jump if not

; Translate ESI into a physical address through our Page Tables

	 mov	 eax,esi	; Copy address to translate for ECX bytes

	 call	 WIN_LIN2LIN	; Return with EAX = new linear address
	 jc	 near ptr XMS_E8F@ ; Jump if it failed

	 mov	 esi,eax	; Copy to source register

; Translate EDI into a physical address through our Page Tables

	 mov	 eax,edi	; Copy address to translate for ECX bytes

	 call	 WIN_LIN2LIN	; Return with EAX = new linear address
	 jc	 near ptr XMS_E8F@ ; Jump if it failed

	 mov	 edi,eax	; Copy to destin register
XMS_MOVXMB_XVXD:
endif				; IF @OEM_WIN3
if @OEM_DEBUG and @OEM_XMS
	 test	 DB3_FLAG,@DB3_XPTE ; Should we check XMS PTEs?
	 jz	 short XMS_MOVXMB_XPTE1 ; Jump if not

	 movzx	 edx,ss:[ebx].MOVXMB_EXT.EXTMOVE_SHNDL ; Get source handle

	 and	 dx,dx		; Izit valid?
	 jz	 short @F	; Jump if not

	 call	 XMSPTE_SET	; Enable access to XMS PTEs for handle EDX
@@:
	 movzx	 edx,ss:[ebx].MOVXMB_EXT.EXTMOVE_DHNDL ; Get destin handle

	 and	 dx,dx		; Izit valid?
	 jz	 short @F	; Jump if not

	 call	 XMSPTE_SET	; Enable access to XMS PTEs for handle EDX
@@:
XMS_MOVXMB_XPTE1:
endif				; IF @OEM_DEBUG and @OEM_XMS
	 sti			; Allow interrupts

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 push	 ecx		; Save move length

	 shr	 ecx,2-0	; Convert from bytes to dwords
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Move 'em

	 pop	 ecx		; Restore move length

	 and	 ecx,(1 shl 2)-1 ; Isolate offset in dword
S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Move 'em

	 cli			; Disallow interrupts

if @OEM_DEBUG and @OEM_XMS
	 test	 DB3_FLAG,@DB3_XPTE ; Should we check XMS PTEs?
	 jz	 short XMS_MOVXMB_XPTE2 ; Jump if not

	 movzx	 edx,ss:[ebx].MOVXMB_EXT.EXTMOVE_SHNDL ; Get source handle

	 and	 dx,dx		; Izit valid?
	 jz	 short @F	; Jump if not

	 call	 XMSPTE_CLR	; Disable access to XMS PTEs for handle EDX
@@:
	 movzx	 edx,ss:[ebx].MOVXMB_EXT.EXTMOVE_DHNDL ; Get destin handle

	 and	 dx,dx		; Izit valid?
	 jz	 short @F	; Jump if not

	 call	 XMSPTE_CLR	; Disable access to XMS PTEs for handle EDX
@@:
XMS_MOVXMB_XPTE2:
endif				; IF @OEM_DEBUG and @OEM_XMS
	 add	 esp,size MOVXMB_STR ; Strip from the stack

	 jmp	 XMS_SUCCESS	; Join common success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 0Ch -- Lock extended memory block

Prior to 7.01.015, we returned the linear address because that's what
the spec said previous to XMS 3.0.  If a program is flagged with M1
in 386LOAD.CFG, we will return the physical address.  Some programs
may expect this behavior.

On entry:

AH	 =	 function #
DX	 =	 handle of block to lock

On exit:

AX	 =	 1 if successful
	 =	 0 if not
DX:BX	 ==>	 32-bit linear address (if $XMS_LCKPHYS, physical address)

Errors:

81	 =	 VDISK found or Weitek support active
A2	 =	 Invalid handle
AC	 =	 Lock count overflow

|

	 public  XMS_LCKXMB
XMS_LCKXMB:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 and	 dx,dx		; Ensure not the free chain handle
	 jz	 near ptr XMS_EA2 ; It is, so that's an error

	 call	 VALID_XHNDL	; Izit in use?
	 jnz	 near ptr XMS_EA2 ; No, so that's an error

	 cli			; Disallow interrupts

	 mov	 esi,PXMSLOCK	; Get offset of XMSLOCK table

	 cmp	 PGROUP:[esi+edx].LO,255 ; Check for maximum lock count
	 je	 near ptr XMS_EAC ; Jump if we would overflow

	 inc	 PGROUP:[esi+edx].LO ; Count in another

	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 eax,PGROUP:[esi+edx*4] ; Get starting base

	 test	 XMS_FLAG,mask $XMS_LCKPHYS ; Does this program expect physical
				; addresses?
	 jnz	 short XMS_LCKXMBPHYS ; Jump if so

if @OEM_WIN3
	 cmp	 LOWWIN3_CB,0	; Izit Windows 3 init time or later?
	 je	 short XMS_LCKXMB_XWIN ; Jump if not

endif				; IF @OEM_WIN3
XMS_LCKXMBPHYS:
; Translate EAX into physical address

	 cmp	 eax,@ZEROLEN_BASE ; Izit pseudo-base for zero-length handles?
	 je	 short XMS_LCKXMB_XWIN ; Yes, ignore translation (zero-length handle)

	 mov	 esi,PRGPDT	; Get offset of PDT in PGROUP
	 mov	 ebx,eax	; Copy to use as PDT index
	 shr	 eax,12-0	; Convert from bytes to 4KB
	 mov	 eax,PGROUP:[esi+eax*4].PDT_PTE ; Get PTE
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame
	 and	 ebx,not ((mask $PTE_FRMHI) or (mask $PTE_FRM)) ; Isolate 4KB offset
	 add	 eax,ebx	; Add to get physical address
XMS_LCKXMB_XWIN:
	 mov	 [ebp].INTXX_EBX.ELO,ax ; Return in DX:BX
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_EDX.ELO,ax

	 jmp	 XMS_SUCCESS	; Join common success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 0Dh -- Unlock extended memory block

On entry:

DX	 =	 handle of block to unlock

On exit:

AX	 =	 1 if successful
	 =	 0 if not

Errors:

81	 =	 VDISK found or Weitek support active
A2	 =	 Invalid handle
AA	 =	 Block not locked

|

	 public  XMS_UNLXMB
XMS_UNLXMB:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 and	 dx,dx		; Ensure not the free chain handle
	 jz	 near ptr XMS_EA2 ; It is, so that's an error

	 call	 VALID_XHNDL	; Izit in use?
	 jnz	 near ptr XMS_EA2 ; No, so that's an error

	 mov	 esi,PXMSLOCK	; Get offset of XMSLOCK table

	 cmp	 PGROUP:[esi+edx].LO,0 ; Izit locked?
	 je	 near ptr XMS_EAA ; No, so that's an error

	 dec	 PGROUP:[esi+edx].LO ; Count in one fewer
	 jnz	 near ptr XMS_SUCCESS ; Jump if still locked

	 jmp	 XMS_SUCCESS	; Join common success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 0Eh -- Get handle information, primary function
	 8Eh -- Get handle information, secondary function

On entry:

AH	 =	 function #
DX	 =	 handle of block

On exit:

AX	 =	 1 if successful
	 =	 0 if not
BH	 =	 Block lock count
BL	 =	 # free XMS handles
DX	 =	 size of block in 1KB

If entered at XMS_GET2INF,

BH	 =	 Block lock count
CX	 =	 # free XMS handles
EDX	 =	 size of block in 1KB

Errors:

81	 =	 VDISK found or Weitek support active
A2	 =	 Invalid handle

|

	 public  XMS_GETINF
XMS_GETINF:
	 mov	 cx,0		; Mark as primary function

	 jmp	 short @F	; Join common code

	 public  XMS_GET2INF
XMS_GET2INF:
	 mov	 cx,1		; Mark as secondary function
@@:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 and	 dx,dx		; Ensure not the free chain handle
	 jz	 near ptr XMS_EA2 ; It is, so that's an error

	 call	 VALID_XHNDL	; Izit in use?
	 jnz	 near ptr XMS_EA2 ; No, so that's an error

	 cli			; Disallow interrupts

	 mov	 esi,PXMSLOCK	; Get offset of XMSLOCK table

	 mov	 al,PGROUP:[esi+edx] ; Get current lock count
	 mov	 [ebp].INTXX_EBX.ELO.HI,al ; Return in BH

	 mov	 ax,XMSNHNDL	; Get maximum # handles, zero high-order word
	 sub	 ax,XHNDLCNT	; Less the number already in use

	 jcxz	 XMS_GETINF1	; Jump if primary function
				; Fall through to secondary function
	 mov	 [ebp].INTXX_ECX.ELO,ax ; Return in CX

	 jmp	 short @F	; Join common code

XMS_GETINF1:
	 mov	 [ebp].INTXX_EBX.ELO.LO,al ; Return in BL
@@:

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 eax,PGROUP:[esi+edx*4] ; Get this block's size in bytes
	 shr	 eax,10-0	; Convert from bytes to 1KB

	 jcxz	 XMS_GETINF2	; Jump if primary function
				; Fall through to secondary function
	 mov	 [ebp].INTXX_EDX,eax ; Return in EDX

	 jmp	 short @F	; Join common code

XMS_GETINF2:
	 mov	 [ebp].INTXX_EDX.ELO,ax ; Return in DX
@@:
	 jmp	 XMS_SUCCESS	; Join common success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 0Fh -- Reallocate extended memory block, primary function
	 8Fh -- Reallocate extended memory block, secondary function

On entry:

DX	 =	 handle of block
BX	 =	 requested new size in 1KB

If entered at XMS_MOD2XMB,

DX	 =	 handle of block
EBX	 =	 requested new size in 1KB

On exit:

AX	 =	 1 if successful
	 =	 0 if not

Errors:

81	 =	 VDISK found or Weitek support active
A0	 =	 Insufficient extended memory
A1	 =	 can't occur in our implementation
A2	 =	 Invalid handle
AB	 =	 Block is locked

|

	 public  XMS_MODXMB
XMS_MODXMB:
	 movzx	 ecx,[ebp].INTXX_EBX.ELO ; Get requested size, zero high-order word

	 jmp	 short @F	; Join common code

	 public  XMS_MOD2XMB
XMS_MOD2XMB:
	 mov	 ecx,[ebp].INTXX_EBX ; Get requested size
@@:
	 call	 CHECK_VDISK	; Check for VDISK signature
	 assume  gs:nothing	; Tell the assembler about it
	 jc	 near ptr XMS_E81 ; Jump if VDISK found

	 and	 dx,dx		; Ensure not the free chain handle
	 jz	 near ptr XMS_EA2 ; It is, so that's an error

	 call	 VALID_XHNDL	; Izit in use?
	 jnz	 near ptr XMS_EA2 ; No, so that's an error

	 mov	 esi,PXMSLOCK	; Get offset of XMSLOCK table

	 cmp	 PGROUP:[esi+edx].LO,0 ; Ensure unlocked
	 jne	 near ptr XMS_EAB ; Jump if not

	 cli			; Disallow interrupts

	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 edi,PGROUP:[esi+edx*4] ; Get base of the block

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 eax,PGROUP:[esi+edx*4] ; Get this block's size in bytes

	 shl	 ecx,10-0	; Convert from 1KB to bytes

	 cmp	 eax,ecx	; Compare actual vs. requested
	 jb	 short XMS_MODXMB_GROW ; Jump if the block is to grow
	 je	 near ptr XMS_SUCCESS ; Jump if same size
				; Fall through to shrink the block

; Register usage:

; EAX	 =	 current size of this block ( > ECX)
; EDI	 ==>	 linear address of block to split
; ECX	 =	 offset at which to split the block (within the block)

	 add	 edi,ecx	; Add to get base of new free entry
	 sub	 eax,ecx	; Subtract to get size of free above

; Deallocate EAX bytes at EDI

	 push	 eax		; Pass byte length
	 push	 edi		; Pass starting linear address
	 call	 DEALLOCMEM	; Deallocate the memory
;;;;;;;; jc	 short ???	; Ignore error return

	 neg	 eax		; Negate to get negative value for MODXMB_COM

	 jmp	 XMS_MODXMB_COM ; Join common code

COMMENT|

 The block is to increase in size
 Ensure there is sufficient room above the block
 Note interrupts are disabled

 Handle special case where initial allocation was 0K.  Note that
 this is different from the case where a block was allocated to
 a non-zero length, reallocated to zero, and now we are attempting
 to reallocate to a (possibly different) non-zero length.

EAX	 Old size of block (bytes)
ECX	 Requested size (bytes)
EDX	 Existing handle
EDI	 Linear address of block (or @ZEROLEN_BASE if never allocated)

|

XMS_MODXMB_GROW:
	 cmp	 edi,@ZEROLEN_BASE ; Was it ever allocated?
	 jne	 short XMS_MODXMB_GROW2 ; Jump if so

; Block was never allocated, so we can treat it as a regular allocation.
; Significantly, this means we can put our dipper in the bucket without
; worrying about growing an existing block.  Note also that we assume
; the previous size was 0.

	 or	 ecx,ecx	; Are we reallocating an empty block to nothing?
	 jz	 near ptr XMS_MODXMB_EXIT ; Jump if so

	 push	 @ALLOC_XMS	; Tell 'em what kind of memory we're allocating
	 push	 ecx		; Pass # bytes to allocate
	 call	 ALLOCMEM	; Allocate 'em
	 assume  fs:nothing	; Tell the assembler about it
				; Return with EBX = linear address of memory
	 jc	 near ptr XMS_EA0 ; Jump if there's not enough memory

	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 PGROUP:[esi+edx*4],ebx ; Save as base of newly allocated block

	 mov	 eax,ecx	; Get new size in bytes

	 jmp	 XMS_MODXMB_COM ; Join common code (note existing size 0)


COMMENT|

The block can't grow upwards, so perhaps we can move it to another spot

On entry:

EDX	 =	 XMS handle
EAX	 =	 # additional bytes needed

|

XMS_MODXMB_GROW1:
	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 edi,PGROUP:[esi+edx*4] ; Get base of the block

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 ecx,PGROUP:[esi+edx*4] ; Get this block's size in bytes

; Deallocate ECX bytes at EDI in case the only available space is below us

	 push	 ecx		; Pass byte length
	 push	 edi		; Pass starting linear address
	 call	 DEALLOCMEM	; Deallocate the memory
;;;;;;;; jc	 short ???	; Ignore error return

	 lea	 ebx,[eax+ecx]	; Add to get total requested size in bytes

	 push	 @ALLOC_XMS	; Tell 'em what kind of memory we're allocating
	 push	 ebx		; Pass # bytes to allocate
	 call	 ALLOCMEM	; Allocate 'em
	 assume  fs:nothing	; Tell the assembler about it
				; Return with EBX = linear address of memory
	 jc	 short XMS_MODXMB_GROW1A ; Jump if there's not enough memory

; The new linear address is at EBX -- copy the old data there

	 mov	 edi,ebx	; AGROUP:EDI ==> destin

	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 xchg	 ebx,PGROUP:[esi+edx*4] ; Get base of the block
	 mov	 esi,ebx	; AGROUP:ESI ==> source

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 shr	 ecx,2-0	; Convert from bytes to dwords

; Note that the new block is either below the old one (and perhaps
; overlapping) or above the old one (and not overlapping).  In either
; case, this move is non-destructive.

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Move 'em

	 jmp	 short XMS_MODXMB_COM ; Join common code
				; w/EAX = # additional bytes
	 assume  es:nothing	; Tell the assembler about it


; Not enough room -- restore the original memory allocations

XMS_MODXMB_GROW1A:

; Allocate ECX bytes at EDI

	 push	 ecx		; Pass # bytes to set
	 push	 edi		; Pass starting linear address
	 call	 ALLOCMEM_SUB	; Allocate 'em

	 jmp	 XMS_EA0	; Jump if not

XMS_MODXMB_GROW2:
	 add	 edi,eax	; Skip to the end of this block
	 sub	 ecx,eax	; Get increase in bytes
	 mov	 eax,ecx	; Save for later use

	 shr	 ecx,10-0	; Convert from bytes to 1KB
	 shr	 edi,10-0	; Convert from bytes to 1KB

	 push	 eax		; Save for a moment

	 mov	 eax,edi	; Copy PDT offset
	 call	 XMS_XLAT	; Translate EAX if using non-standard LINKBASE
	 mov	 edi,eax	; Set translated address

	 pop	 eax		; Restore

; Ensure not greater than CMPSIZEXT

	 mov	 ebx,CMPSIZEXT	; Get size of EXT/XMS CMP
	 add	 ebx,HMASIZE	; Plus size of HMA (0 or 64KB)
	 add	 ebx,1024	; Plus first megabyte

	 lea	 esi,[edi+ecx]	; Skip to end of desired region

	 cmp	 esi,ebx	; Izit outside bounds of EXT/XMS CMP?
	 ja	 near ptr XMS_EA0 ; Jump if so

	 mov	 es,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

; Determine the span of available entries starting
; at EDI for no more than ECX entries

	 push	 @ALLOC_XMS	; Pass the allocation type
	 push	 ecx		; Pass # entries we need
	 push	 edi		; Pass starting offset into XMSBMAP
	 call	 XMS_MEMSPAN	; Determine the span of available entries
				; returning EDI = # consecutive available entries

	 cmp	 edi,ecx	; Izit all available?
	 jb	 near ptr XMS_MODXMB_GROW1 ; Jump if not

	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 edi,PGROUP:[esi+edx*4] ; Get base of the block

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 add	 edi,PGROUP:[esi+edx*4] ; Plus this block's size in bytes
				; to get ending address

; Allocate EAX bytes at EDI

	 push	 eax		; Pass # bytes to set
	 push	 edi		; Pass starting linear address
	 call	 ALLOCMEM_SUB	; Allocate 'em
	 jc	 near ptr XMS_E80 ; Jump if something went wrong
XMS_MODXMB_COM:
	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 add	 PGROUP:[esi+edx*4],eax ; Add into this block's size
				; or subtract if EAX is negative
	 sub	 PGROUP:[esi+  0*4],eax ; Subtract from total available memory
				; or add if EAX is negative
XMS_MODXMB_EXIT:
	 jmp	 XMS_SUCCESS	; Join common success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it


if @OEM_HIFILL
; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 10h -- Allocate upper memory block

On entry:

DX	 =	  size of block to allocate in paras

On exit:

If successful,

AX	 =	 1
BX	 =	 segment of allocated block
DX	 =	 actual size of block in paras (to which it can grow)

If not successful,

AX	 =	 0
DX	 =	 size of largest available block in paras

Errors:

BL	 =	 8F if MAC error encountered
	 =	 B0 if a smaller UMB is available
	 =	 B1 if no UMBs are available

|

	 public  XMS_GETUMB
XMS_GETUMB:
	 mov	 di,-1		; Indicate no particular region preference

	 test	 CMD_FLAG,@CMD_XHI ; High DOS memory disallowed?
	 jnz	 near ptr XMS_EB1 ; Yes, no UMBs possible

; We don't check for NO58.  If a program is flagged with M2 and NO58 is
; in effect, they have no way to allocate UMBs.  That's OK, since M2 is
; meant to keep programs like NSCHED from executing buggy code that
; doesn't work properly with XMS UMB allocation.
	 test	 XMS_FLAG,mask $XMS_NOXMSUMB ; XMS UMB allocation disallowed?
	 jnz	 near ptr XMS_EB1 ; Yes, make 'em use 5800 services

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 ax,@MAC_UMB	; Call it a UMB
	 mov	 bx,@STRA_UMB	; High DOS only, first fit
	 mov	 dx,[ebp].INTXX_EDX.ELO ; Get size of block to allocate
	 FIXICALL JGROUP:MAC_ALLOC,DTE_CSJG ; Return error code in AL
	 mov	 [ebp].INTXX_EDX.ELO,dx ; Save as size of largest block
	 jc	 near ptr XMS_ERR ; Jump if failed

	 mov	 [ebp].INTXX_EBX.ELO,ax ; Save segment of allocated block

	 jmp	 XMS_SUCCESS	; Join common success code

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it
endif				; IF @OEM_HIFILL


if @OEM_HIFILL
; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 11h -- Release upper memory block

On entry:

DX	 =	 segment of block to release

On exit:

AX	 =	 1 if successful
	 =	 0 if not

Errors:

BL	 =	 8F if MAC error encountered
	 =	 B1 if no UMBs are available
	 =	 B2 if UMB segment is invalid

|

	 public  XMS_RELUMB
XMS_RELUMB:
	 test	 CMD_FLAG,@CMD_XHI ; High DOS memory disallowed?
	 jnz	 near ptr XMS_EB1 ; Yes, no UMBs possible

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 dx,[ebp].INTXX_EDX.ELO ; Get block to release
	 FIXICALL JGROUP:MAC_FREE,DTE_CSJG ; Free MAC entry at DX:0
	 jc	 near ptr XMS_ERR ; Jump if failed (error code in AL)

	 jmp	 XMS_SUCCESS	; Join common

	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it
endif				; IF @OEM_HIFILL


if @OEM_HIFILL
; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

COMMENT|

Function 12h -- Re-allocate upper memory block

On entry:

BX	 =	 new size for UMB in paras
DX	 =	 segment of block to re-allocate

On exit:

AX	 =	 1 if successful
	 =	 0 if not

Errors:

BL	 =	 8F if MAC error encountered
	 =	 B0 if no UMB is large enough to satisfy the request
		    In which case DX contains size of largest UMB.
	 =	 B2 if UMB segment is invalid

|

	 public  XMS_MODUMB
XMS_MODUMB:
	 test	 CMD_FLAG,@CMD_XHI ; High DOS memory disallowed?
	 jnz	 near ptr XMS_EB1 ; Yes, no UMBs possible

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 ax,-1		; Don't reassert owner field in MAC entry
	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get new size of block
	 mov	 dx,[ebp].INTXX_EDX.ELO ; Get block to reallocate
	 FIXICALL JGROUP:MAC_REALLOC,DTE_CSJG ; Reallocate MAC entry at DX:0 to BX paras
	 jc	 near ptr XMS_ERR ; Jump if failed (error code in AL)

	 jmp	 XMS_SUCCESS	; Join common
endif				; IF @OEM_HIFILL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT2F	 endp			; End INT2F procedure
	 NPPROC  VMFN_CHKVSAPI -- Check On Vendor-Specific Calls
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check on vendor-specific calls from VM.

On entry:

SS:EBP	 ==>	 INTXX_STR
DS:SI	 ==>	 ASCIIZ VSAPI name

On exit:

ZF	 =	 1 if the name matches us
	 =	 0 otherwise

ES:DI	 ==>	 VSAPI entry point in VM

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 movzx	 eax,[ebp].INTXX_DS ; Get caller's DS
	 shl	 eax,4-0	; Convert from paras to bytes

	 movzx	 ebx,[ebp].INTXX_ESI.ELO ; Get caller's SI
	 add	 eax,ebx	; Add to get 32-bit linear address

	 cmp	 AGROUP:[eax].EDD,'M683' ; Izit bytes 0-3 of '386MAX',0?
	 jne	 short VMFN_CHKVSAPI_EXIT ; Jump if not (note ZF=0)

	 cmp	 AGROUP:[eax+4].ELO,'XA' ; Izit bytes 4-5 of '386MAX',0?
	 jne	 short VMFN_CHKVSAPI_EXIT ; Jump if not (note ZF=0)

	 cmp	 AGROUP:[eax+6].LO,0 ; Izit byte 6 of '386MAX',0?
	 jne	 short VMFN_CHKVSAPI_EXIT ; Jump if not (note ZF=0)

	 mov	 ax,HIMEM_CS	; Get segment of high DOS memory
	 mov	 [ebp].INTXX_ES,ax ; Return in caller's ES
	 mov	 [ebp].INTXX_EDI.ELO,offset PGROUP:VM_VSAPI ; Return offset
				; in caller's DI
	 cmp	 ax,ax		; Return with ZF=1
VMFN_CHKVSAPI_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMFN_CHKVSAPI endp		; End VMFN_CHKVSAPI procedure
	 NPPROC  CHECK_HOOK -- Check on Unhooking INT 15h
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we should unhook the secondary INT 15h handler.

Do this if all of the below are true:

1.  No XMS handles are in use;
2.  No EMS handles are in use;
3.  The HMA is not in use;
4.  The A20 line is disabled;
5.  There no active DPMI clients.

|

if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 ja	 short CHECK_HOOK_EXIT1 ; Jump if so
endif				; IF @OEM_WIN3

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 cmp	 XHNDLCNT,1	; Any XMS handles in use?
	 ja	 short CHECK_HOOK_EXIT ; Yes, don't unhook

	 cmp	 EHNDLCNT,1	; Any EMS handles in use?
	 ja	 short CHECK_HOOK_EXIT ; Yes, don't unhook

	 test	 GLB_FLAG,@GLB_HMA ; Izit in use?
	 jnz	 short CHECK_HOOK_EXIT ; Yes, don't unhook

	 test	 GLB_FLAG,@GLB_X1MB ; Izit disabled?
	 jnz	 short CHECK_HOOK_EXIT ; No, don't unhook

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 short CHECK_HOOK_EXIT ; Jump if so

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSHI	; Get high DOS memory selector
	 assume  ds:PGROUP	; Tell the assembler about it

	 and	 XMS_FLAG,not (mask $XMS_I15) ; Mark as uninstalled (low memory)

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 and	 XMS_FLAG,not (mask $XMS_I15) ; Mark as uninstalled (high memory)

; Remove memory 64KB to EX2SIZE from XMS free chain

	 cmp	 EX2SIZE,64	; Is there anything to remove?
	 jbe	 short @F	; Jump if not

	 call	 REMOVE_E2X	; Remove 'em
@@:
CHECK_HOOK_EXIT:
	 popf			; Restore flags
CHECK_HOOK_EXIT1:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_HOOK endp 		; End CHECK_HOOK procedure
if @OEM_WIN3
	 NPPROC  WIN_LIN2LIN -- Windows Linear to Linear Address Translator
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Linear address to linear address translator.

On entry:

EAX	 =	 incoming linear address
ECX	 =	 # consecutive bytes

On exit:

EAX	 =	 translated address
CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <edx,esi>	; Save registers

; First, translate EAX into a physical address

	 mov	 esi,PRGPDT	; Get offset of PDT in PGROUP
	 mov	 edx,eax	; Copy to use as PDT index
	 shr	 eax,12-0	; Convert from bytes to 4KB
	 mov	 eax,PGROUP:[esi+eax*4].PDT_PTE ; Get PTE
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame
	 and	 edx,not ((mask $PTE_FRMHI) or (mask $PTE_FRM)) ; Isolate 4KB offset
	 add	 edx,eax	; Add to get physical address in EDX

; Next translate this physical address into a linear one
; through the VxD callback

	 mov	 ah,01h 	; Code to translate EDX to EDX for ECX bytes
	 call	 WIN3_REF_DATA.REF_MAX2VXD_CB ; Ask the VxD for help
				; Return with CF significant

	 mov	 eax,edx	; Copy to return register

	 REGREST <esi,edx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WIN_LIN2LIN endp		; End WIN_LIN2LIN procedure
endif				; IF @OEM_WIN3
	 NPPROC  CHECK_VDISK -- Check For VDISK Signature
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for VDISK signature or Weitek support active.
Ignore VDISK of exactly 64KB if QEXT is present.

On exit:

CF	 =	 1 if either found
	 =	 0 otherwise
GS	 =	 AGROUP if we need to check

|

	 REGSAVE <esi>		; Save register

if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 ja	 short CHECK_VDISK_LOST ; Jump if so
endif				; IF @OEM_WIN3

	 test	 GLB_FLAG,@GLB_WTK ; Is Weitek support active?
	 jnz	 short CHECK_VDISK_FOUND ; Yes, handle as if VDISK installed

	 test	 XMS_FLAG,mask $XMS_VDISK ; Already found?
	 jnz	 short CHECK_VDISK_FOUND ; Yes

	 test	 XMS_FLAG,mask $XMS_I15 ; Installed XMS INT 15h as yet?
	 jnz	 short CHECK_VDISK_LOST ; Yes, VDISK can't exist

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 esi,LaCVD	; Get linear address of pseudo-1MB PTE

	 cmp	 AGROUP:[esi].VDISK_VEND.EDD,'SIDV' ; Check for signature
	 jne	 short CHECK_VDISK_LOST ; Jump if no signature

	 cmp	 AGROUP:[esi+4].VDISK_VEND,'K' ; Check for signature
	 jne	 short CHECK_VDISK_LOST ; Jump if no signature

	 test	 LCL_FLAG,@LCL_QEXT ; Is the new-style QEXT.SYS present?
	 jz	 short @F	; Jump if not

	 cmp	 AGROUP:[esi].VDISK_NEXT,1024+64 ; Izit 64KB in size?
	 je	 short CHECK_VDISK_LOST ; Jump if so
@@:
	 or	 XMS_FLAG,mask $XMS_VDISK ; Mark for next time
CHECK_VDISK_FOUND:
	 stc			; Indicate VDISK found

; Note that WRAP_ENABLE is called at EMM_EXIT

	 jmp	 short CHECK_VDISK_EXIT ; Join common exit code

CHECK_VDISK_LOST:
	 clc			; Indicate VDISK not found
CHECK_VDISK_EXIT:
	 REGREST <esi>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VDISK endp		; End CHECK_VDISK procedure
	 NPPROC  VALID_XHNDL -- Validate XMS Handle
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Validate an XMS handle.

On entry:

DX	 =	 handle to validate

On exit:

EDX	 =	 DX zero-extended
ZF	 =	 1 if in use
	 =	 0 if not

|

	 cmp	 dx,XMSNHNDL	; Izit a valid handle?
	 ja	 short VALID_XHNDL_EXIT ; Jump if not (note ZF=0)

	 push	 esi		; Save for a moment

	 mov	 esi,PXMSHNDL	; Get offset of XMSHNDL table
	 movzx	 edx,dx 	; Zero the high-order word

	 cmp	 PGROUP:[esi+edx].LO,@H_INUSE ; Izit in use?
				; Return with ZF significant
	 pop	 esi		; Restore
VALID_XHNDL_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VALID_XHNDL endp		; End VALID_XHNDL procedure
	 NPPROC  APPEND_EXT -- Append Extended Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Append the memory from 1MB + 64KB to 1MB + EX2SIZE
to the XMS free chain.
EX2SIZE reflects the size of extended memory in case
there has been a top down extended memory allocator.

On exit:

CF	 =	 0 if all went OK
	 =	 1 if no HMA (EXTSIZE < 64)

|

	 push	 eax		; Save for a moment

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSHI	; Get high DOS memory selector
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 eax,EX2SIZE	; Get current size of extended memory
	 or	 XMS_FLAG,mask $XMS_I15 ; Mark as installed (low memory)

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

; If this is 0000FFFFh, we're on a biggggg system -- use EXTSIZE instead
; as that's the actual amount of extended memory available

	 cmp	 eax,0000FFFFh	; Izit special lie value?
	 jne	 short @F	; Jump if so

	 mov	 eax,EXTSIZE	; Use correct value
@@:
	 mov	 EX2SIZE,eax	; Save for later use

	 pop	 eax		; Restore

; Append 64KB to EX2SIZE (if any) to XMS memory

	 cmp	 EX2SIZE,64	; Is there anything to append?
	 jb	 short APPEND_EXT_NOHMA ; Jump if not (and no HMA either)
	 je	 short @F	; Jump if not

	 call	 APPEND_E2X	; Append more memory
@@:
	 or	 XMS_FLAG,mask $XMS_I15 ; Mark as installed (high memory)
				; Note CF=0
	 jmp	 short APPEND_EXT_EXIT ; Join common exit code

APPEND_EXT_NOHMA:
	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSHI	; Get high DOS memory selector
	 assume  ds:PGROUP	; Tell the assembler about it

	 and	 XMS_FLAG,not (mask $XMS_I15) ; Mark as not installed (low memory)

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 stc			; Indicate no HMA
APPEND_EXT_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

APPEND_EXT endp 		; End APPEND_EXT procedure
	 NPPROC  APPEND_E2X -- Append New XMS Memory to Free Chain
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Append new memory to the XMS free chain from
64KB to EX2SIZE.

On entry:

EX2SIZE has been filled in

|

	 REGSAVE <eax,esi>	; Save registers

	 pushf			; Save flags

	 cli			; Disallow interrupts

	 bts	 XMS_FLAG,$XMS_E2X ; Mark as appended
	 jc	 short APPEND_E2X_EXIT ; Jump if already done

	 mov	 eax,EX2SIZE	; Get top of memory to append

	 sub	 eax,HMASIZE	; Less size of HMA (0 or 64KB)
	 jbe	 short APPEND_E2X_EXIT ; Jump if nothing to append

	 shl	 eax,10-0	; Convert from 1KB to bytes

; Add into total available XMS memory

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 add	 PGROUP:[esi+0*4],eax ; Add into total available memory

; Deallocate EAX bytes at EDI

	 push	 eax		; Pass byte length
	 push	 EXTBASE	; Pass starting linear address
	 call	 DEALLOCMEM	; Deallocate the memory
;;;;;;;; jc	 short ???	; Ignore error return
APPEND_E2X_EXIT:
	 popf			; Restore flags

	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

APPEND_E2X endp 		; End APPEND_E2X procedure
	 NPPROC  REMOVE_E2X -- Remove New XMS Memory from Free Chain
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Remove new memory from the XMS free chain from
64KB to EX2SIZE.

By construction,

* All XMS memory is free
* The free chain starts at EXTBASE

On entry:

EX2SIZE has been filled in

|

	 REGSAVE <eax,esi>	; Save registers

	 pushf			; Save flags

	 cli			; Disallow interrupts

	 btr	 XMS_FLAG,$XMS_E2X ; Mark as removed
	 jnc	 short REMOVE_E2X_EXIT ; Jump if not appended

	 mov	 eax,EX2SIZE	; Get top of memory to remove

	 sub	 eax,HMASIZE	; Less size of HMA (0 or 64KB)
	 jbe	 short REMOVE_E2X_EXIT ; Jump if nothing to remove

	 shl	 eax,10-0	; Convert from 1KB to bytes

; Subtract from total available XMS memory

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 sub	 PGROUP:[esi+0*4],eax ; Subtract from total available memory

; Allocate EAX bytes at EDI

	 push	 eax		; Pass # bytes to set
	 push	 EXTBASE	; Pass starting linear address
	 call	 ALLOCMEM_SUB	; Allocate 'em
;;;;;;;; jc	 short ???	; Ignore return code
REMOVE_E2X_EXIT:
	 popf			; Restore flags

	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REMOVE_E2X endp 		; End REMOVE_E2X procedure
	 NPPROC  INIT_XMS -- Initialize XMS Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Intialize XMS memory and variables

XMS memory initially extends from 1MB + min (64, EXTSIZE) * 1024
to 1MB + CMPSIZE * 1024.

    * Initialize free chain entry (1st) of XMSHNDL to @H_INUSE,
      all others to @H_AVAIL
    * Initialize all entries of XMSLOCK to 0
    * Initialize the free chain
    * Transfer the EMS entries which correspond to the first
      EXTSIZE - HMASIZE KB from the EMS free chain to the VMS free chain.

This routine executes in protected mode.

|

	 pushad 		; Save all EGP registers

;    * Initialize free chain entry (1st) of XMSHNDL to @H_INUSE,
;      all others to @H_AVAIL

	 movzx	 ecx,XMSNHNDL	; Get # entries in table
	 mov	 edi,PXMSHNDL	; ES:EDI ==> XMSHNDL table
	 mov	 al,@H_INUSE	; Get initial value
S32	 stos	 PGROUP:[edi].LO ; Save as first entry
	 dec	 ecx		; Account for it
	 mov	 al,@H_AVAIL	; Get value for remaining entries
     rep stos	 PGROUP:[edi].LO ; Initialize them


;    * Initialize all entries of XMSLOCK to 0

	 movzx	 ecx,XMSNHNDL	; Get # entries in table
	 mov	 edi,PXMSLOCK	; ES:EDI ==> XMSLOCK table
	 xor	 al,al		; Zero value
     rep stos	 PGROUP:[edi].LO ; Initialize them


;    * Initialize the free chain

	 mov	 edi,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 eax,CMPSIZE	; Get size of CMP in 1KB

	 shl	 eax,10-0	; Convert from 1KB to bytes
	 mov	 PGROUP:[edi+0*4],eax ; Save as size of XMS memory
	 jz	 short INIT_XMS_EXIT ; Jump if insufficient extended memory


;     * Remove the EMS entries which correspond to the first
;	 EXTSIZE - HMASIZE KB from the EMS free chain to the VMS free chain.

	 or	 XMS_FLAG,mask $XMS_E2X ; Mark as previously appended
	 mov	 eax,EXTSIZE	; Get size of extended memory
	 xchg	 eax,EX2SIZE	; Swap with secondary size (used by TRANS_E2X)
	 call	 REMOVE_E2X	; Remove 'em
	 mov	 EX2SIZE,eax	; Restore
INIT_XMS_EXIT:
	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_XMS endp			; End INIT_XMS procedure
if @OEM_WIN3
	 FPPROC  XMS_VXD2MAX -- VxD to MAX XMS Call Routine
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VxD to MAX XMS call routine

SS is WIN386's FLAT model selector and isn't PGROUP.
No procedures in the call tree from this point may assume SS:PGROUP.

On entry:

SS:EBP	 ==>	 client register structure

On exit:

SS:EBP	 ==>	 (modified as appropriate to XMS call)

|

	 test	 DB2_FLAG,@DB2_XMS ; Call SWAT on XMS calls?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:
	 REGSAVE <SEL_DATA,SEL_DS3,SEL_4GB,SEL_4GB3,SEL_PDT,SEL_DSHI,SEL_DSIG3,SEL_DSJG3,ds,es,fs,gs> ; Save data and regs
	 pushad 		; Save all EGP registers

	 mov	 SEL_DATA,ds	; Save as new data selector
	 mov	 SEL_DS3,ds	; Save as new data selector
	 mov	 SEL_4GB,gs	; ...	      all memory selector
	 mov	 SEL_4GB3,gs	; ...	      all memory selector
	 mov	 SEL_PDT,0	; For debugging
	 mov	 SEL_DSHI,0	; ...

	 push	 WIN3_REF_DATA.REF_DSIGR ; Save as new IGROUP data selector
	 pop	 SEL_DSIG3	; ...

	 push	 WIN3_REF_DATA.REF_DSJGR ; Save as new JGROUP data selector
	 pop	 SEL_DSJG3	; ...

	 mov	 es,SEL_DSIG3	; Establish addressibility to IGROUP
	 assume  es:IGROUP	; Tell the assembler

	 REGSAVE <ISEL_DS3,ISEL_DSIG3,ISEL_4GB3> ; Save IGROUP copies

	 mov	 ISEL_DS3,ds	; Save as new data selector (in IGROUP)
	 mov	 ISEL_DSIG3,es	; ...		   selector (in IGROUP)
	 mov	 ISEL_4GB3,gs	; ...	      all memory selector (in IGROUP)

	 mov	 es,SEL_DSJG3	; Establish addressibility to JGROUP
	 assume  es:JGROUP	; Tell the assembler

	 REGSAVE <JSEL_DS3>	; Save JGROUP copy

	 mov	 JSEL_DS3,ds	; Save as new data selector (in JGROUP)

	 inc	 VXD_LEVEL	; Increment the level #

	 mov	 eax,[ebp].INTXX_EAX ; Setup caller's EGP registers
	 mov	 ebx,[ebp].INTXX_EBX ; ...
	 mov	 ecx,[ebp].INTXX_ECX ; ...
	 mov	 edx,[ebp].INTXX_EDX ; ...

; Save original INT 0Dh and 0Eh handlers, and install our own

;;;;;;;; call	 INST_0D0E	; Save and install 'em

	 jmp	 XMS_VXDIN	; Join common code

XMS_VXDOUT:

; Restore the original INT 0Dh and 0Eh handlers

;;;;;;;; call	 REST_0D0E	; Restore 'em

	 dec	 VXD_LEVEL	; Decrement the level #

	 mov	 gs,SEL_4GB3	; Old stack selector
	 assume  gs:AGROUP	; Tell the assembler

	 mov	 AGROUP:[ebp].INTXX_EAX.ELO,ax ; Save return code

	 mov	 es,SEL_DSJG3	; Establish addressibility to JGROUP
	 assume  es:JGROUP	; Tell the assembler

	 REGREST <JSEL_DS3>	; Restore JGROUP copy

	 mov	 es,SEL_DSIG3	; Establish addressibility to IGROUP
	 assume  es:IGROUP	; Tell the assembler

	 REGREST <ISEL_4GB3,ISEL_DSIG3,ISEL_DS3> ; Restore IGROUP copies

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]
	 REGREST <gs,fs,es,ds,SEL_DSJG3,SEL_DSIG3,SEL_DSHI,SEL_PDT,SEL_4GB3,SEL_4GB,SEL_DS3,SEL_DATA> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 RETFD			; Return to caller (32-bit)

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMS_VXD2MAX endp		; End XMS_VXD2MAX procedure
endif				; IF @OEM_WIN3
;;; if @OEM_WIN3
;;; IDTMAC   macro   N1,N2,SRC,SAV
;;;	     local   L1
;;;
;;; IDT      equ     <AGROUP:[ebx+N1*(type IDT_STR)]>
;;;
;;;	     mov     ax,SRC&INT&N2&_FVEC.FSEL ; Get selector
;;;
;;;	     cmp     ax,IDT.IDT_SELECT ; Same as IDT?
;;;	     je      short L1	    ; Yes, ignore this interrupt
;;;
;;;	     xchg    ax,IDT.IDT_SELECT ; Swap with IDT
;;; ifnb <SAV>
;;;	     mov     SAV&INT&N2&_FVEC.FSEL,ax ; Save for later use
;;; endif
;;;
;;;	     mov     eax,SRC&INT&N2&_FVEC.FOFF ; Get 32-bit offset
;;;	     xchg    ax,IDT.IDT_OFFLO ; Swap with IDT
;;; ifnb <SAV>
;;;	     mov     SAV&INT&N2&_FVEC.FOFF.ELO,ax ; Save for later use
;;; endif
;;;	     shr     eax,16	    ; Shift to low-order
;;;	     xchg    ax,IDT.IDT_OFFHI ; Swap with IDT
;;; ifnb <SAV>
;;;	     mov     SAV&INT&N2&_FVEC.FOFF.EHI,ax ; Save for later use
;;; endif
;;;
;;;	     mov     al,SRC&INT&N2&_ARB ; Get access rights byte
;;;	     xchg    al,IDT.IDT_ACCESS ; Swap with IDT
;;; ifnb <SAV>
;;;	     mov     SAV&INT&N2&_ARB,al ; Save for later use
;;; endif
;;; L1:
;;;	     endm
;;;
;;; endif			    ; IF @OEM_WIN3
;;; if @OEM_WIN3
;;;	     NPPROC  INST_0D0E -- Save Original INT 0Dh and 0Eh Handlers and Install Our Own
;;;	     assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
;;; COMMENT|
;;;
;;; Save the original INT 0Dh and 0Eh handlers and install our own
;;;
;;; |
;;;
;;;	     REGSAVE <eax,ebx>	    ; Save registers
;;;
;;;	     mov     WLCLINT0D_FVEC.FSEL,cs ; Save code selector
;;;	     mov     WLCLINT0E_FVEC.FSEL,cs ;
;;;
;;;	     sub     esp,size IDT_STR ; Make room on the stack for the IDT
;;;	     SIDTD   [esp].EDF	    ; Save onto the stack
;;;	     mov     ebx,[esp].DTR_BASE ; Get the base address of the IDT
;;;	     add     esp,size IDT_STR ; Remove from the stack
;;;
;;;	     IDTMAC  0Dh,0D,WLCL,WOLD ; IDT to WOLD, WLCL to IDT
;;;	     IDTMAC  0Eh,0E,WLCL,WOLD ; IDT to WOLD, WLCL to IDT
;;;
;;;	     REGREST <ebx,eax>	    ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; INST_0D0E endp		    ; End INST_0D0E procedure
;;; endif			    ; IF @OEM_WIN3
;;; if @OEM_WIN3
;;;	     NPPROC  REST_0D0E -- Restore Original INT 0Dh and 0Eh Handlers
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Restore the original INT 0Dh and 0Eh handlers.
;;;
;;; |
;;;
;;;	     REGSAVE <eax,ebx,gs>   ; Save registers
;;;
;;;	     mov     gs,SEL_4GB3    ; Get AGROUP data selector at PL3
;;;	     assume  gs:AGROUP	    ; Tell the assembler about it
;;;
;;;	     sub     esp,size IDT_STR ; Make room on the stack for the IDT
;;;	     SIDTD   [esp].EDF	    ; Save onto the stack
;;;	     mov     ebx,[esp].DTR_BASE ; Get the base address of the IDT
;;;	     add     esp,size IDT_STR ; Remove from the stack
;;;
;;;	     IDTMAC  0Dh,0D,WOLD    ; WOLD to IDT
;;;	     IDTMAC  0Eh,0E,WOLD    ; WOLD to IDT
;;;
;;;	     REGREST <gs,ebx,eax>   ; Restore
;;;	     assume  gs:nothing     ; Tell the assembler about it
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; REST_0D0E endp		    ; End REST_0D0E procedure
;;; endif			    ; IF @OEM_WIN3
;;; if @OEM_WIN3
;;;	     FPPROC  WLCL_INT0D -- General Protection Interrupt Handler
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; General Protection interrupt handler.
;;;
;;; |
;;;
;;; ; Check for IRQ5 instead of a fault
;;;
;;;	     push    ax 	    ; Save for a moment
;;;
;;;	     mov     al,@GETISR     ; Code to read ISR
;;;	     out     @ICR,al	    ; Tell the 8259 about it
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;;	     in      al,@ICR	    ; Read the ISR
;;;
;;;	     test    al,mask $IRQ5  ; Izit in service?
;;;	     pop     ax 	    ; Restore
;;;	     jnz     short WLCL_INT0D_ORIG ; Jump if so
;;;
;;;	     int     01h	    ; Call SWAT
;;;
;;;	     add     esp,size INTXX_ERR ; Strip off error code
;;;
;;;	     iretd		    ; Return to caller
;;;
;;;	     jmp     short WLCL_INT0D ; In case we're returning from a TSS
;;;
;;; WLCL_INT0D_ORIG:
;;;	     sub     esp,4*2	    ; Make room for OLDINT0D_FVEC
;;;
;;;	     REGSAVE <eax,ds>	    ; Save for a moment
;;;
;;; WOLDINT0D_STR struc
;;;
;;;	     dw      ?		    ; Caller's DS
;;;	     dd      ?		    ; ...      EAX
;;; WOLDINT0D_FOFF dd ? 	    ; Place for WOLDINT0D_FVEC.FOFF
;;; WOLDINT0D_FSEL dw ?,?	    ; ...	WOLDINT0D_FVEC.FSEL
;;;
;;; WOLDINT0D_STR ends
;;;
;;;	     mov     ds,SEL_DS3     ; Get PGROUP data selector at PL3
;;;	     assume  ds:PGROUP	    ; Tell the assembler about it
;;;
;;;	     mov     eax,WOLDINT0D_FVEC.FOFF ; Get next offset
;;;	     mov     [esp].WOLDINT0D_FOFF,eax ; Save on stack
;;;
;;;	     mov     ax,WOLDINT0D_FVEC.FSEL ; Get next selector
;;;	     mov     [esp].WOLDINT0D_FSEL,ax ; Save on stack
;;;
;;;	     REGREST <ds,eax>	    ; Restore
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;;	     retfd		    ; Continue with original handler (32-bit)
;;;
;;;	     jmp     short WLCL_INT0D ; In case we're returning from a TSS
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; WLCL_INT0D endp		    ; End WLCL_INT0D procedure
;;; endif			    ; IF @OEM_WIN3
;;; if @OEM_WIN3
;;;	     FPPROC  WLCL_INT0E -- Page Fault Interrupt Handler
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Page Fault interrupt handler.
;;;
;;; |
;;;
;;; ; Check for IRQ6 instead of a fault
;;;
;;;	     push    ax 	    ; Save for a moment
;;;
;;;	     mov     al,@GETISR     ; Code to read ISR
;;;	     out     @ICR,al	    ; Tell the 8259 about it
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;	     jmp     short $+2	    ; I/O delay
;;;
;;;	     in      al,@ICR	    ; Read the ISR
;;;
;;;	     test    al,mask $IRQ6  ; Izit in service?
;;;	     pop     ax 	    ; Restore
;;;	     jnz     short WLCL_INT0E_ORIG ; Jump if so
;;;
;;;	     int     01h	    ; Call SWAT
;;;
;;;	     add     esp,size INTXX_ERR ; Strip off error code
;;;
;;;	     iretd		    ; Return to caller
;;;
;;;	     jmp     short WLCL_INT0E ; In case we're returning from a TSS
;;;
;;; WLCL_INT0E_ORIG:
;;;	     sub     esp,4*2	    ; Make room for OLDINT0E_FVEC
;;;
;;;	     REGSAVE <eax,ds>	    ; Save for a moment
;;;
;;; WOLDINT0E_STR struc
;;;
;;;	     dw      ?		    ; Caller's DS
;;;	     dd      ?		    ; ...      EAX
;;; WOLDINT0E_FOFF dd ? 	    ; Place for WOLDINT0E_FVEC.FOFF
;;; WOLDINT0E_FSEL dw ?,?	    ; ...	WOLDINT0E_FVEC.FSEL
;;;
;;; WOLDINT0E_STR ends
;;;
;;;	     mov     ds,SEL_DS3     ; Get PGROUP data selector at PL3
;;;	     assume  ds:PGROUP	    ; Tell the assembler about it
;;;
;;;	     mov     eax,WOLDINT0E_FVEC.FOFF ; Get next offset
;;;	     mov     [esp].WOLDINT0E_FOFF,eax ; Save on stack
;;;
;;;	     mov     ax,WOLDINT0E_FVEC.FSEL ; Get next selector
;;;	     mov     [esp].WOLDINT0E_FSEL,ax ; Save on stack
;;;
;;;	     REGREST <ds,eax>	    ; Restore
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;;	     retfd		    ; Continue with original handler (32-bit)
;;;
;;;	     jmp     short WLCL_INT0E ; In case we're returning from a TSS
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; WLCL_INT0E endp		    ; End WLCL_INT0E procedure
;;; endif			    ; IF @OEM_WIN3
if @OEM_DEBUG and @OEM_XMS
	 NPPROC  XMSPTE_CLR -- Disable Access to XMS PTEs
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable access to XMS PTEs for a handle

On entry:

EDX	 =	 handle #

|

	 REGSAVE <eax,ebx,ecx,esi> ; Save registers

if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 jne	 short XMSPTE_CLR_EXIT ; Jump if so
endif				; IF @OEM_WIN3
	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 eax,PGROUP:[esi+edx*4] ; Get starting base

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 ecx,PGROUP:[esi+edx*4] ; Get the length of the handle in bytes
	 jecxz	 XMSPTE_CLR_EXIT ; Jump if zero-length

	 mov	 ebx,PRGPDT	; Get offset in PGROUP of PDT

	 shr	 ecx,12-0	; Convert from bytes to 4KB (# PTEs)
	 shr	 eax,12-0	; Convert from bytes to 4KB

; Unless we're in a re-entrant call, $PTE_P should already be set.
; If it isn't, transfer the bit to $PTE_AV0.  If that bit is already set,
; transfer it to $PTE_AV1.

XMSPTE_CLR_NEXT:
	 btr	 PGROUP:[ebx+eax*4].PDT_PTE,$PTE_AV2 ; Wuzit prev prev prev present?
	 jc	 short @F	; Jump if so (leave it prev prev present)

	 btr	 PGROUP:[ebx+eax*4].PDT_PTE,$PTE_AV1 ; Wuzit prev prev present?
	 jc	 short @F	; Jump if so (leave it prev present)

	 btr	 PGROUP:[ebx+eax*4].PDT_PTE,$PTE_AV0 ; Wuzit prev present?
	 jc	 short @F	; Jump if so (leave it present)

	 btr	 PGROUP:[ebx+eax*4].PDT_PTE,$PTE_P ; Mark as not present
@@:
	 inc	 eax		; Skip to next PTE

	 loopd	 XMSPTE_CLR_NEXT ; Jump if more PTEs to clear
XMSPTE_CLR_EXIT:
	 REGREST <esi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMSPTE_CLR endp 		; End XMSPTE_CLR procedure
endif				; IF @OEM_DEBUG and @OEM_XMS
if @OEM_DEBUG and @OEM_XMS
	 NPPROC  XMSPTE_SET -- Enable Access to XMS PTEs
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable access to XMS PTEs for a handle

On entry:

EDX	 =	 handle #

|

	 REGSAVE <eax,ebx,ecx,esi> ; Save registers

if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 jne	 short XMSPTE_SET_EXIT ; Jump if so
endif				; IF @OEM_WIN3
	 mov	 esi,PXMSBASE	; Get offset of XMSBASE table
	 mov	 eax,PGROUP:[esi+edx*4] ; Get starting base

	 mov	 esi,PXMSSIZE	; Get offset of XMSSIZE table
	 mov	 ecx,PGROUP:[esi+edx*4] ; Get the length of the handle in bytes
	 jecxz	 XMSPTE_SET_EXIT ; Jump if zero-length

	 mov	 ebx,PRGPDT	; Get offset in PGROUP of PDT

	 shr	 ecx,12-0	; Convert from bytes to 4KB (# PTEs)
	 shr	 eax,12-0	; Convert from bytes to 4KB

; Unless we're in a re-entrant call, $PTE_P should already be clear.
; If it isn't, set $PTE_AV0 to indicate this fact.  If that bit is
; already set, transfer it to $PTE_AV1.

XMSPTE_SET_NEXT:
	 bts	 PGROUP:[ebx+eax*4].PDT_PTE,$PTE_P ; Mark as present
	 jnc	 short @F	; Jump if previously not present (as expected)

	 bts	 PGROUP:[ebx+eax*4].PDT_PTE,$PTE_AV0 ; Mark as prev present
	 jnc	 short @F	; Jump if not more than one level re-entrant

	 bts	 PGROUP:[ebx+eax*4].PDT_PTE,$PTE_AV1 ; Mark as prev prev present
	 jnc	 short @F	; Jump if not more than two levels re-entrant

	 bts	 PGROUP:[ebx+eax*4].PDT_PTE,$PTE_AV2 ; Mark as prev prev prev present
	 jnc	 short @F	; Jump if not more than three levels re-entrant

	 int	 01h		; Give up on more than three levels re-entrant
@@:
	 inc	 eax		; Skip to next PTE

	 loopd	 XMSPTE_SET_NEXT ; Jump if more PTEs to clear
XMSPTE_SET_EXIT:
	 REGREST <esi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMSPTE_SET endp 		; End XMSPTE_SET procedure
endif				; IF @OEM_DEBUG and @OEM_XMS
endif				; IF @OEM_XMS
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_XMS module

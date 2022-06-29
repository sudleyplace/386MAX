;' $Header:   P:/PVCS/MAX/386MAX/QMAX_I4B.ASV   1.2   30 May 1997 10:44:56   BOB  $
	 title	 QMAX_I4B -- 386MAX INT 4Bh Handler
	 page	 58,122
	 name	 QMAX_I4B

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Data    segment JDATA, dword-aligned, public, class 'jcode'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include ALLMEM.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include BIOSDATA.INC
	 include INTVEC.INC
NOVER_HTU = 1
	 include VERSION.INC
	 include VDS.INC
	 include XMS.INC
	 include MASM5.MAC

	 include QMAX_DTE.INC
	 include QMAX_I31.INC
	 include QMAX_OEM.INC
	 include QMAX_VMM.INC
.list

if @OEM_VDS

PGROUP	 group	 CODE,ECODE,EDATA
IGROUP	 group	 LCODE,ICODE,IDATA
JGROUP	 group	 JCODE,JDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 SYSROM_START:word

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 PVDSTAB:dword
	 extrn	 PDTVALID:dword

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

if @OEM_DPMI
	 extrn	 DPMI_CPIHOOK:byte
	 extrn	 LPMSTK_FVEC:fword
endif				; IF @OEM_DPMI

	 extrn	 CON4KB:dword
	 extrn	 CON64KB:dword
	 extrn	 CON128KB:dword
	 extrn	 CON1MB:dword
	 extrn	 CON1P1MB:dword

	 extrn	 SEL_DSHI:word
	 extrn	 SEL_DS3:word
	 extrn	 SEL_4GB3:word
	 extrn	 PRGPDT:dword

	 extrn	 LAST_INTCOM:dword
	 extrn	 LAST_INTFLG:dword
	 extrn	 DMASIZE:word
	 extrn	 DMA_LA:dword
	 extrn	 DMA_PA:dword
	 extrn	 PRGBASE:dword

	 extrn	 I13CNT:word
	 extrn	 SEL_DSIG3:word
	 extrn	 VMM_FLAG:word

I4B_REC  record  $I4B_INUSE:1,	\
		 $I4B_CPUPHYS:1

	 public  DMADISCNT,PDDSBUF,I4B_FLAG
DMADISCNT dd	 8 dup (0)	; DMA channel disable count
PDDSBUF  dd	 ?		; GETBUF caller's buffer 32-bit linear address
I4B_FLAG I4B_REC <>		; INT 4Bh flags

EDATA	 ends			; End EDATA segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
	 assume  ds:JGROUP

	 public  I4B_FNS
	 align	 2
I4B_FNS  dw	 JGROUP:INT4B_ERR0F  ; 00 = Reserved
	 dw	 JGROUP:INT4B_ERR0F  ; 01 = Reserved
	 dw	 JGROUP:I4B_VERS     ; 02 = Get version #
	 dw	 JGROUP:I4B_LOCK     ; 03 = Lock DMA region
	 dw	 JGROUP:I4B_UNLK     ; 04 = Unlock DMA region
	 dw	 JGROUP:I4B_SLOCK    ; 05 = Scatter/gather lock region
	 dw	 JGROUP:I4B_SUNLK    ; 06 = Scatter/gather unlock region
	 dw	 JGROUP:I4B_GETBUF   ; 07 = Request DMA buffer
	 dw	 JGROUP:I4B_RELBUF   ; 08 = Release DMA buffer
	 dw	 JGROUP:I4B_MEM2BUF  ; 09 = Memory to DMA buffer
	 dw	 JGROUP:I4B_BUF2MEM  ; 0A = DMA buffer to memory
	 dw	 JGROUP:I4B_DISTRAN  ; 0B = Disable DMA translation
	 dw	 JGROUP:I4B_ENATRAN  ; 0C = Enable DMA translation
I4B_CNT  equ	 ($-I4B_FNS)/2	; # valid functions

JDATA	 ends			; End JDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

if @OEM_DPMI
	 extrn	 PMINTCOM:near
	 extrn	 FDPMIFN_LPMSTK:far
endif				; IF @OEM_DPMI

if @OEM_VIRTUALMEM
	 extrn	 FVMM_LOCK:far
	 extrn	 FVMM_UNLOCK:far
endif				; IF @OEM_VIRTUALMEM

ICODE	 ends			; End ICODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 INTPROC4B:near
	 extrn	 INT0D_IRETD:near
	 extrn	 FWRAP_ENABLE:far
	 extrn	 FWRAP_DISABLE:far

if @OEM_DPMI
	 extrn	 INTPROC00Z:near
endif				; IF @OEM_DPMI

ECODE	 ends			; End ECODE segment


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
	 assume  cs:IGROUP

if @OEM_DPMI
	 extrn	 GETSELBASE:far
endif				; IF @OEM_DPMI

LCODE	 ends			; End LCODE segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

if @OEM_VIRTUALMEM
	 extrn	 LinearBottom:dword
	 extrn	 LinearClientTop:dword
endif				; IF @OEM_VIRTUALMEM

IDATA	 ends			; End IDATA segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 public  @QMAX_I4B_JCODE
@QMAX_I4B_JCODE:		; Mark module start in .MAP file

	 FPPROC  INT4B -- INT 4Bh Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

VDS services interrupt handler.

On entry:

AH	 =	 VDS services major function code
AL	 =	 ...	      minor ...

Caller's IP has been incremented past the instruction.

|

if @OEM_DEBUG
	 test	 DB2_FLAG,@DB2_VDS ; Call SWAT on VDS calls?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:
endif				; IF @OEM_DEBUG
if @OEM_DPMI
	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 short INT4B_INTRETVM ; Jump if so

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT4B_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_CPIHOOK[4Bh/8],1 shl (4Bh mod 8) ; Izit hooked by current client?
	 jz	 short INT4B_INTRETPM ; Jump if not

	 mov	 [esp].NRM_INTNO,4*4Bh + offset PGROUP:INTPROC00Z ; Mark as INT 4Bh

; The stack is mapped by INTDPI_STR

	 push	 @PMINTCOM_NRM	; Use application stack
	 FIXIJMP IGROUP:PMINTCOM,DTE_CSIG ; Jump to common code

	 public  INT4B_INTRETPM
INT4B_INTRETPM:
INT4B_INTRETVM:
endif				; IF @OEM_DPMI
	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All GP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

if @OEM_DPMI
	 REGSAVE <ds,gs>	; Save selectors
endif				; IF @OEM_DPMI
	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

if @OEM_DPMI
	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 short @F	; Jump if not
endif				; IF @OEM_DPMI
	 lea	 eax,[ebp].INTXX_EIP ; Get offset of INTCOM-restartable point
	 xchg	 eax,LAST_INTCOM ; Swap with previous frame offset
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 eax,0		; Save previous flag
	 mov	 [ebp].INTXX_ICOMLO,ax ; Save it
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_ICOMHI,ax ; Save it
@@:
if @OEM_DPMI
	 push	 LPMSTK_FVEC.FSEL ; Save current LPM stack top
	 push	 LPMSTK_FVEC.FOFF ; ...

; Set new LPM stack top for nested callers if it's active
; and we're called from PM

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 short @F	; Jump if so

	 lea	 eax,[ebp].INTXX_EIP ; SS:EAX ==> INTDPI_STR from PL3
	 push	 eax		; Pass the offset
	 FIXICALL IGROUP:FDPMIFN_LPMSTK,DTE_CSIG ; Save new LPM stack as appropriate
@@:
endif				; IF @OEM_DPMI

; Enable interrupts if the caller has them enabled

	 push	 [ebp].INTXX_EFL.ELO ; Get caller's flags
	 and	 [esp].ELO,not ((mask $NT) or (mask $DF) or (mask $TF)) ; NT=TF=DF=0
	 popf			; Put caller's IF into effect

	 mov	 ax,[ebp].INTXX_EAX.ELO ; Restore original value

	 and	 GLB_FLAG,not @GLB_P67 ; Not coming from I/O port for INT 67h

; Ensure valid major function

	 cmp	 ah,@VDS_MAJOR	; Check it
	 jne	 short INT4B_ERRMAJ ; Jump if not valid

; Ensure within range

	 cmp	 al,I4B_CNT	; Check for valid subfunction range
	 jnb	 near ptr INT4B_ERR0F ; Jump if out of range

	 movzx	 ebx,al 	; Copy subfunction #

	 jmp	 I4B_FNS[ebx*2] ; Take appropriate action


; Major function mismatch
; Chain if bit 3 in 40:7B set, or
;	if non-zero and not in ROM
; Otherwise, return as if nothing happened.

INT4B_ERRMAJ:
if @OEM_DPMI
	 push	 es		; Save for a moment
endif				; IF @OEM_DPMI

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:BIOSDATA	; Tell the assembler about it

	 test	 VDS[0400h],@VDS_CHAIN ; Check for chaining bit
	 jnz	 short INT4B_ORIG ; Jump if we should chain

	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 ax,SYSROM_START ; Get starting segment of system ROM

	 cmp	 ax,INT00_VEC.VSEG[4Bh*(type INT00_VEC)] ; Izit in system ROM?
	 jae	 short @F	; Jump if it is (no chaining)

	 cmp	 INT00_VEC.VSEG[4Bh*(type INT00_VEC)],0 ; Izit initialized?
	 jne	 short INT4B_ORIG ; Jump if it is (chain)
@@:
if @OEM_DPMI
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 cli			; Disable interrupts to avoid HW interrupt
				; after POPAD looking like a VM interrupt
	 pop	 LPMSTK_FVEC.FOFF ; Restore
	 pop	 LPMSTK_FVEC.FSEL ; ...

	 REGREST <gs,ds>	; Restore
	 assume  ds:nothing,gs:nothing ; Tell the assembler about it

; If we're returning to PM, strip the stack and do so

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 short @F	; Jump if so

	 popad			; Restore all EGP registers

	 add	 esp,size INTXX_ERR ; Strip pseudo-error code from stack

	 iretd			; Return to caller

@@:
endif				; IF @OEM_DPMI
	 FIXIJMP PGROUP:INT0D_IRETD,DTE_CS2 ; Join common return code

	 assume  es:nothing	; Tell the assembler about it
	 assume  ds:PGROUP	; Tell the assembler about it

; Chain to original INT 4Bh handler

INT4B_ORIG:
if @OEM_DPMI
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
endif				; IF @OEM_DPMI
	 cli			; Disallow interrupts

if @OEM_DPMI
	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 short @F	; Jump if not
endif				; IF @OEM_DPMI
	 mov	 ax,[ebp].INTXX_ICOMHI ; Get previous offset
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_ICOMLO ; Get previous offset
	 btr	 ax,$INTCOM_VAL ; Move previous setting to CF
	 setc	 LAST_INTFLG.LO ; Move previous setting to memory
	 mov	 LAST_INTCOM,eax ; Restore
@@:
	 cli			; Disable interrupts to avoid HW interrupt
				; after POPAD looking like a VM interrupt
if @OEM_DPMI
	 pop	 LPMSTK_FVEC.FOFF ; Restore
	 pop	 LPMSTK_FVEC.FSEL ; ...

	 REGREST <gs,ds>	; Restore
	 assume  ds:nothing,gs:nothing ; Tell the assembler about it
endif				; IF @OEM_DPMI
	 popad			; Restore all EGP registers

	 add	 esp,size INTXX_ERR ; Strip pseudo-error code from stack

; If we were called from PM, the following JMP is handled as a HW interrupt

	 FIXIJMP PGROUP:INTPROC4B,DTE_CS2 ; Join common code

	 assume  ds:PGROUP	; Tell the assembler about it

INT4B_ERR0F:
	 mov	 al,@VDSERR_INVMIN ; Unknown minor function code
INT4B_ERR:
;;;;;;;; mov	 esp,ebp	; Cut back the stack

	 or	 [ebp].INTXX_EFL.ELO,mask $CF ; Mark as error return
	 mov	 [ebp].INTXX_EAX.ELO.LO,al ; Return error code

	 jmp	 short INT4B_COM ; Join common exit code

INT4B_ERR03:
	 mov	 al,@VDSERR_UALOCK ; Unable to lock pages (VMM systems only)

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR05:
	 mov	 al,@VDSERR_BUFOVF ; Region too large for buffer

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR06:
	 mov	 al,@VDSERR_INUSE ; Buffer already in use

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR08:
	 mov	 al,@VDSERR_NPLOCK ; Memory was not previously locked

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR09:
	 mov	 al,@VDSERR_PTEOVF ; Too many physical pages

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR0A:
	 mov	 al,@VDSERR_INVBID ; Invalid buffer ID

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR0B:
	 mov	 al,@VDSERR_CPYOVF ; Copy count+offset > buffer size

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR0C:
	 mov	 al,@VDSERR_INVDCN ; Invalid DMA channel #

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR0D:
	 mov	 al,@VDSERR_CNTOVF ; DMA channel disable count overflow

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR0E:
	 mov	 al,@VDSERR_CNTUND ; DMA channel disable count underflow

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR10:
	 mov	 al,@VDSERR_INVFLG ; Invalid flag bits

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_ERR11:
	 mov	 al,@VDSERR_INVSEL ; Invalid selector

	 jmp	 short INT4B_ERR ; Join common error code

INT4B_CLC:
;;;;;;;; mov	 esp,ebp	; Cut back the stack
	 and	 [ebp].INTXX_EFL.ELO,not (mask $CF) ; Mark as OK
INT4B_COM:
	 and	 I4B_FLAG,not (mask $I4B_CPUPHYS) ; Mark as no longer
				; CPU physical

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 FIXICALL PGROUP:FWRAP_ENABLE,DTE_CS2 ; Enable the 1MB wrap

	 cli			; Disable interrupts to avoid HW interrupt
				; after POPAD looking like a VM interrupt
if @OEM_DPMI
	 pop	 LPMSTK_FVEC.FOFF ; Restore
	 pop	 LPMSTK_FVEC.FSEL ; ...

	 REGREST <gs,ds>	; Restore
	 assume  ds:nothing,gs:nothing ; Tell the assembler about it

; If we're returning to PM, strip the stack and do so

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 short @F	; Jump if so

	 popad			; Restore all EGP registers

	 add	 esp,size INTXX_ERR ; Strip pseudo-error code from stack

	 iretd			; Return to caller

@@:
endif				; IF @OEM_DPMI
	 FIXIJMP PGROUP:INT0D_IRETD,DTE_CS2 ; Join common return code

	 assume  ds:PGROUP	; Tell the assembler about it

; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Functions 00h and 01h -- Reserved functions,

On entry:

SS:EBP	 ==>	 INTXX_STR

On exit:

AL	 =	 error code

Error codes

AL	 =	 0F	subfunction not supported

|

; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 02h -- Return major/minor/debugging version #

On entry:

DX	 =	 flags (all bits reserved and zero)
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
AH	 =	 major specification version # (binary format)
AL	 =	 minor ...
BX	 =	 vendor product #
CX	 =	 vendor product revision #
SI:DI	 =	 maximum DMA buffer byte size
DX	 =	 flags
		 Bit 0 = if PC/XT bus (DMA in 1MB only)
		 Bit 1 = if physical buffer in first megabyte
		 Bit 2 = if automatic remapping supported
		 Bit 3 = all memory physically contiguous
		 All other bits are reserved and must be zero
else
CF	 =	 1
AL	 =	 error code

Error codes

AL	 =	 10	reserved bits set in DX

|

	 public  I4B_VERS
I4B_VERS:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not 0
	 jnz	 short INT4B_ERR10 ; Jump if so

	 mov	 [ebp].INTXX_EAX.ELO,0101h ; Major/minor version # in (AH,AL)
	 mov	 [ebp].INTXX_EBX.ELO,4560h ; OEM #		   in BX

	 mov	 ah,VERS_H-'0'  ; Get hundreds digit
	 mov	 al,VERS_T-'0'  ; Get tens digit
	 shl	 al,4		; Shift to high-order nibble
	 or	 al,VERS_U-'0'  ; Include units digit
	 mov	 [ebp].INTXX_ECX.ELO,ax    ; OEM revision #	   in CX

	 movzx	 eax,DMASIZE	; Get size of DMA buffer in 1KB
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 mov	 [ebp].INTXX_EDI.ELO,ax ; Save low-order word in DI
	 shr	 eax,16 	; Shift down the high-order word
	 mov	 [ebp].INTXX_ESI.ELO,ax ; Save high-order word in SI

	 xor	 ax,ax		; Zero flags

	 test	 LCL_FLAG,@LCL_XT ; Izit an XT?
	 jz	 short @F	; Jump if not

	 or	 ax,@BIT0	; Mark as XT
@@:
	 cmp	 DMA_PA,1024*1024 ; Izit in the first megabyte?
	 jae	 short @F	; Jump if not

	 or	 ax,@BIT1	; Mark as in the first megabyte
@@:

; Bits 2 & 3 are both zero

	 mov	 [ebp].INTXX_EDX.ELO,ax ; Save flags in DX

	 jmp	 INT4B_CLC	; Join common OK code


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 03h -- Lock DMA region

On entry:

DX	 =	 flags
		 Bit 1 = if data should be copied into buffer
		 Bit 2 = if buffer should not be allocated automatically
		 Bit 3 = if automatic remap should not be used
		 Bit 4 = if region should not cross a 64KB boundary
		 Bit 5 = if ... 		     128KB ...
		 All bits are reserved and must be zero
ES:DI	 ==>	 DMA descriptor structure
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
else
CF	 =	 1
AL	 =	 error code
DDS_SIZE =	 maximum contiguous length from start

Error codes

AL	 =	 01	region specified not contiguous memory
	 =	 02	region crossed a physical alignment boundary
	 =	 03	unable to lock pages (Virtual Memory systems only)
	 =	 05	region too large for buffer
	 =	 06	buffer currently in use
	 =	 07	invalid memory region
	 =	 10	reserved bits set in DX
	 =	 11	invalid selector in DDS

If error code 01 or 02, DDS_SIZE = maximum contiguous length buffer.

|

	 public  I4B_LOCK
I4B_LOCK:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not (@VDSF_COPY or \
					  @VDSF_XBUF or \
					  @VDSF_XMAP or \
					  @VDSF_X64  or \
					  @VDSF_X128 or \
					  @VDSF_BPHYS)
	 jnz	 near ptr INT4B_ERR10 ; Jump if so

; Address the DDS

	 call	 GET_DDS	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  gs:AGROUP	; Tell the assembler about it

	 call	 VDS_WRAP	; Check on VDS services wrap
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector
				; ESI = linear address of caller's region
				; Wrap disabled if appropriate

	 call	 INT4B_CPUPHYS	; Izit CPU physical only?

	 mov	 ecx,AGROUP:[edi].DDS_SIZE ; Get region size in bytes
	 add	 ecx,esi	; Address the next byte
	 add	 ecx,CON4KB	; Round up to 4KB boundary
	 dec	 ecx		; Back off to last byte in region
	 rcr	 ecx,1-0	; Convert from bytes to words using CF from ADD
	 shr	 ecx,12-1	; Convert from words to 4KB
	 shl	 ecx,12-(12-2)	; Convert from 4KB to 4KB in dwords

; Save the initial offset modulo 4KB

	 mov	 edx,esi	; Copy to get offset within 4KB
	 shr	 esi,12-0	; Convert from bytes to 4KB
	 shl	 esi,12-(12-2)	; Convert from 4KB to 4KB in dwords
	 sub	 ecx,esi	; Less the start to get length
	 shr	 ecx,12-(12-2)	; Convert from 4KB in dwords to 4KB (# PTEs)

	 call	 INT4B_VIRT_LOCK ; Lock VMM region EDX for ECX pages
	 jc	 near ptr INT4B_ERR03 ; Jump if that failed

	 and	 edx,not @PTE_FRM ; Isolate the offset within the frame

	 call	 INT4B_NEXTPTE	; Return with EAX=next PTE, ESI updated

	 add	 edx,eax	; Add together frame and offset
	 mov	 AGROUP:[edi].DDS_POFF,edx ; Save as physical address

	 mov	 edx,eax	; Copy as first PTE
	 sub	 esi,type PDT_PTE ; Skip back to it

	 mov	 AGROUP:[edi].DDS_BID,0 ; Assume no buffer allocated

	 cmp	 AGROUP:[edi].DDS_SIZE,0 ; Izit empty?
	 je	 near ptr I4B_GETBUF_EXIT  ; Jump if so

; See if the region is contiguous

	 push	 esi		; Save 1st PDT offset

	 mov	 bl,@VDSERR_XCONT ; Assume not contiguous error code
I4B_LOCK1:
	 call	 INT4B_NEXTPTE	; Return with EAX=next PTE, ESI updated

	 cmp	 eax,edx	; Izit contiguous?
	 jne	 near ptr I4B_LOCK2 ; Jump if not, with
				; EDX = next address after contiguous
				;	region (on 4KB boundary)
	 add	 edx,CON4KB	; Skip to next PTE

	 LOOPD	 I4B_LOCK1	; Jump if more PTEs to check

; In case there was a previous VDS table, translate w.r.t its entries

	 test	 I4B_FLAG,mask $I4B_CPUPHYS ; Izit CPU physical?
	 jnz	 short @F	; Jump if so

	 cmp	 PVDSTAB,0	; Izit active?
	 je	 short @F	; Jump if not

	 push	 AGROUP:[edi].DDS_SIZE ; Pass size in bytes
	 push	 AGROUP:[edi].DDS_POFF ; Pass physical address
	 FCALL	 PVDS_TRANS	; Return with EAX = translated address
				; EDX = next address after contiguous
				;	region (on 4KB boundary)
	 mov	 ecx,-1 	; Use maximum address in case not contiguous
	 mov	 AGROUP:[edi].DDS_POFF,eax ; Save new physical address
	 jc	 near ptr I4B_LOCK3 ; Jump if region not contiguous
@@:
	 pop	 esi		; Restore 1st PDT offset

; The region is contiguous -- check for boundary alignment

	 mov	 eax,AGROUP:[edi].DDS_POFF ; Get the base physical address
	 mov	 edx,eax	; Copy ...
	 add	 edx,AGROUP:[edi].DDS_SIZE ; Plus size to get next address
	 dec	 edx		; Back off to last byte in region
	 mov	 ecx,edx	; Copy last address
	 and	 cx,mask $PTE_FRM ; Isolate the frame (ECX = last PTE)
	 add	 ecx,CON4KB	; ECX = last PTE + 4KB
;;;;;;;; and	 ax,mask $PTE_FRM ; Isolate the frame
	 shr	 eax,16-0	; Convert from bytes to 64KB
	 shr	 edx,16-0	; Convert from bytes to 64KB
	 mov	 bl,@VDSERR_BOUND ; Assume DMA boundary error code

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_X64 ; Check for 64KB alignment
	 jz	 short @F	; Jump if not

	 cmp	 eax,edx	; Ensure the same
	 mov	 esi,CON64KB	; Get 64KB constant
	 jne	 short I4B_LOCK5 ; Jump if not (crosses 64KB DMA boundary)
@@:
	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_X128 ; Check for 128KB alignment
	 jz	 short @F	; Jump if not

	 shr	 eax,17-16	; Convert from 64KB to 128KB
	 shr	 edx,17-16	; Convert from 64KB to 128KB

	 cmp	 eax,edx	; Ensure the same
	 mov	 esi,CON128KB	 ; Get 128KB constant
	 jne	 short I4B_LOCK5 ; Jump if not (crosses 128KB DMA boundary)
@@:
	 jmp	 INT4B_CLC	; Join common OK code


; The memory is not contiguous
; Set ECX to maximum contiguous size

I4B_LOCK2:
	 mov	 ecx,edx	; Copy 4KB + last address which compared
	 sub	 ecx,AGROUP:[edi].DDS_POFF ; Less physical address to get length

; In case there was a previous VDS table, translate w.r.t its entries

	 test	 I4B_FLAG,mask $I4B_CPUPHYS ; Izit CPU physical?
	 jnz	 short I4B_LOCK4 ; Jump if so

	 cmp	 PVDSTAB,0	; Izit active?
	 je	 short I4B_LOCK4 ; Jump if not

	 push	 AGROUP:[edi].DDS_SIZE ; Pass size in bytes
	 push	 AGROUP:[edi].DDS_POFF ; Pass physical address
	 FCALL	 PVDS_TRANS	; Return with EAX = translated address
				; EDX = next address after contiguous
				;	region (on 4KB boundary)
	 mov	 AGROUP:[edi].DDS_POFF,eax ; Save new physical address
;;;;;;;; jc	 short I4B_LOCK3 ; Jump if region not contiguous

COMMENT|

If we entered here directly, then the 386MAX memory is
contiguous, but the previous VDS table memory is not.

ECX	 =	 -1
EAX	 =	 first address of region
		 relative to previous VDS table addresses
EDX	 =	 next address after contiguous region (on 4KB boundary)
		 relative to previous VDS table addresses

If we fell through from I4B_LOCK2, the 386MAX memory is
not contiguous.

ECX	 =	 maximum contiguous region in 386MAX memory
EAX	 =	 first address of region
		 relative to previous VDS table addresses
EDX	 =	 next address after contiguous region (on 4KB boundary)
		 relative to previous VDS table addresses

Find the smaller of ECX and EDX-EAX (the two maximum contiguous lengths).

|

I4B_LOCK3:
	 sub	 edx,eax	; Subtract to get length

	 cmp	 ecx,edx	; Use smaller length
	 jbe	 short @F	; Jump if MAX length is smaller

	 mov	 ecx,edx	; Use previous VDS table length
@@:
I4B_LOCK4:
	 pop	 esi		; Restore 1st PDT offset

	 jmp	 short I4B_LOCKBUF ; Join common buffer allocation code

; The region is not contiguous or it crosses a DMA boundary
; Error code in BL and maximum contiguous size in ECX
; Save maximum contiguous size into DDS_SIZE

I4B_LOCK_ERRBL:
	 mov	 AGROUP:[edi].DDS_SIZE,ecx ; Save as maximum contiguous size
	 mov	 al,bl		; Copy error code

	 jmp	 INT4B_ERR	; Join common error code

I4B_LOCK5:
	 dec	 esi		; Less one to get mask
	 not	 esi		; Complement to round down
	 and	 ecx,esi	; Isolate as multiple of 64KB or 128KB
	 sub	 ecx,AGROUP:[edi].DDS_POFF ; Less physical address to get length

; The region is not contiguous or it crosses a DMA boundary
; Attempt to allocate a buffer
; Error code in BL and maximum contiguous size in ECX if user says not to

I4B_LOCKBUF:

; At this point, we have decided that we can't lock the specified region.
; We may have already done a VMM_LOCK on the region, which we may have to
; now undo.

	 call	 INT4B_VIRT_UNLOCK ; Unlock region in caller's DDS
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector
				; ESI = linear address of caller's region
				; Wrap disabled if appropriate

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_XBUF ; Should we allocate a buffer?
	 jnz	 short I4B_LOCK_ERRBL ; Jump if not with error code in BL

; Ensure the buffer is available

	 cli			; Disallow interrupts

	 test	 I4B_FLAG,mask $I4B_INUSE ; Izit already in use?
	 jnz	 near ptr INT4B_ERR06 ; Yes, can't proceed

; Ensure the region fits inside the buffer

	 movzx	 eax,DMASIZE	; Get size of our DMA buffer
	 shl	 eax,10-0	; Convert from 1KB to bytes

	 cmp	 eax,AGROUP:[edi].DDS_SIZE ; Duzit cover the region size?
	 jb	 near ptr INT4B_ERR05 ; Jump if not

; Allocate the buffer

	 or	 I4B_FLAG,mask $I4B_INUSE ; Mark as in use
	 sti			; Allow interrupts

	 mov	 AGROUP:[edi].DDS_BID,1 ; Mark as buffer allocated

	 mov	 eax,DMA_PA	; Get buffer's physical address
	 mov	 AGROUP:[edi].DDS_POFF,eax ; Save as physical address

	 jmp	 I4B_GETBUF_COM ; Join common code to copy data into our buffer
				; if requested, and return bus physical

	 assume  gs:nothing	; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 04h -- Unlock DMA region

On entry:

DX	 =	 flags
		 Bit 1 = copy data out of buffer first
		 All other bits are reserved and must be zero
ES:DI	 ==>	 DMA descriptor structure
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
else
CF	 =	 1
AL	 =	 error code

Error codes

AL	 =	 08	memory was not locked
	 =	 0A	invalid buffer ID
	 =	 10	reserved bits set in DX
	 =	 11	invalid selector in DDS

|

	 public  I4B_UNLK
I4B_UNLK:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not @VDSF_COPY
	 jnz	 near ptr INT4B_ERR10 ; Jump if so

; Address the DDS

	 call	 GET_DDS	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  gs:AGROUP	; Tell the assembler about it

	 call	 INT4B_VIRT_UNLOCK ; Unlock region in caller's DDS
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector
				; ESI = linear address of caller's region
				; Wrap disabled if appropriate

	 cmp	 AGROUP:[edi].DDS_BID,0 ; Izit using local DMA buffer?
	 je	 short I4B_UNLK1 ; Jump if not

	 cmp	 AGROUP:[edi].DDS_BID,1 ; Izit a valid buffer ID?
	 jne	 near ptr INT4B_ERR0A ; Jump if not

	 test	 I4B_FLAG,mask $I4B_INUSE ; Izit already in use?
	 jz	 near ptr INT4B_ERR0A ; No, can't proceed

	 call	 BUF2MEM	; Copy data out of our buffer if requested

	 cmp	 AGROUP:[edi].DDS_BID,0 ; Izit using local DMA buffer?
	 je	 short I4B_UNLK1 ; Jump if not

	 and	 I4B_FLAG,not (mask $I4B_INUSE) ; Mark as available
I4B_UNLK1:
	 jmp	 INT4B_CLC	; Join common OK code

	 assume  gs:nothing	; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 05h -- Scatter/gather lock region

On entry:

DX	 =	 flags
		 Bit 6 = page table entries shoud be copied
		 Bit 7 = not present pages should not be locked
			 (ignored if bit 6 clear)
		 All other bits are reserved and must be zero
ES:DI	 ==>	 Extended DMA descriptor structure
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
XDDS_USED =	 # entries actually used
BX	 =	 offset into 1st PTE if @VDSF_PTE set in DX
else
CF	 =	 1
AL	 =	 error code
XDDS_USED =	 # entries actually needed
XDDS_SIZE =	 maximum length in bytes which can be locked
		 with this XDDS

Error codes

AL	 =	 03	unable to lock pages
	 =	 07	invalid memory region
	 =	 09	number of physical regions/pages greater than table length
	 =	 10	reserved bits set in DX
	 =	 11	invalid selector in DDS

|

	 public  I4B_SLOCK
I4B_SLOCK:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not (@VDSF_PTE or @VDSF_PLOCK or @VDSF_BPHYS)
	 jnz	 near ptr INT4B_ERR10 ; Jump if so

SLOCK_STR struc

SLOCK_REM dd	 ?		; Remainder within first 4KB page
SLOCK_OFF dd	 ?		; Offset ...
SLOCK_ACC dd	 ?		; Accumulated size used so far
SLOCK_CNT dd	 ?		; # PTEs which cover the region size
SLOCK_ADDR dd	 ?		; Physical address of start of this entry
SLOCK_SIZE dd	 ?		; Size in bytes of ...

SLOCK_STR ends

	 sub	 esp,type SLOCK_STR ; Make room for structure
	 mov	 [esp].SLOCK_REM,0 ; Initialize remainder in case empty
	 mov	 [esp].SLOCK_ACC,0 ; Initialize accumulated size

; Address the DDS

	 call	 GET_DDS	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  gs:AGROUP	; Tell the assembler about it

	 call	 VDS_WRAP	; Check on VDS services wrap
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector
				; ESI = linear address of caller's region
				; Wrap disabled if appropriate

	 call	 INT4B_CPUPHYS	; Izit CPU physical only?

	 mov	 AGROUP:[edi].XDDS_USED,0 ; Initialize # entries used

	 mov	 ecx,AGROUP:[edi].XDDS_SIZE ; Get region size in bytes
	 add	 ecx,esi	; Address the next byte
	 add	 ecx,CON4KB	; Round up to 4KB boundary
	 dec	 ecx		; Back off to last byte in region
	 rcr	 ecx,1-0	; Convert from bytes to words using CF from ADD
	 shr	 ecx,12-1	; Convert from words to 4KB
	 shl	 ecx,12-(12-2)	; Convert from 4KB to 4KB in dwords

; Save the initial offset modulo 4KB

	 mov	 eax,esi	; Copy to get offset within 4KB
	 mov	 edx,eax	; Copy to EDX for INT4B_VIRT_LOCK
	 and	 eax,not @PTE_FRM ; Isolate offset

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_PTE ; Should we copy PTEs?
	 jz	 short @F	; Jump if not

	 mov	 [ebp].INTXX_EBX.ELO,ax ; Save offset within first PTE in BX
@@:
	 shr	 esi,12-0	; Convert from bytes to 4KB
	 shl	 esi,12-(12-2)	; Convert from 4KB to 4KB in dwords

	 cmp	 AGROUP:[edi].XDDS_SIZE,0 ; Izit empty?
	 je	 near ptr I4B_SLOCK_CLC ; Jump if so

	 sub	 ecx,esi	; Less the start to get length in 4KB in dwords
	 shr	 ecx,12-(12-2)	; Convert from 4KB in dwords to 4KB (# PTEs)
	 mov	 [esp].SLOCK_CNT,ecx ; Save count

	 mov	 [esp].SLOCK_OFF,eax ; Save offset within first 4KB

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_PLOCK ; lock present only?
	 jz	 short @F	; jump if locking ALL pages

	 call	 INT4B_VIRT_LOCKPRESENT ; lock the present pages
	 jmp	 short INT4B_CHECK_LOCK ; join common path
@@:
	 call	 INT4B_VIRT_LOCK ; Lock VMM region EDX for ECX pages
INT4B_CHECK_LOCK:
	 jnc	 short @F	 ; Jump if successful

	 add	 esp,type SLOCK_STR ; Strip structure from stack

	 jmp	 near ptr INT4B_ERR03	; Join error code

@@:

; The remainder field is initially negative.  The first round adds 4KB
; to it.  If the initial offset is zero, the initial remainder is zero, too.

	 neg	 eax		; Negate to obtain remainder
	 mov	 [esp].SLOCK_REM,eax ; Save on stack in structure

; In case we need to count pseudo-entries for previous VDS tables,
; initialize the corresponding address and size fields

	 call	 INT4B_NEXTPTE	; Return with EAX=next PTE, ESI updated

	 mov	 [esp].SLOCK_ADDR,eax ; Initialize address field
	 mov	 [esp].SLOCK_SIZE,0 ; Initialize region size field
	 sub	 esi,type PDT_PTE ; Skip back to it

	 xor	 ebx,ebx	; Zero XDDS_DATA entry count
	 mov	 edx,-1 	; Set initial PTE as different
I4B_SLOCK_NEXT:
	 call	 INT4B_NEXTPTE	; Return with EAX=next PTE, ESI updated

; Split cases between physical addresses and PTEs

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_PTE ; Should we copy PTEs?
	 jnz	 short I4B_SLOCKPTE1 ; Jump if so

	 cmp	 eax,edx	; Izit contiguous?
	 je	 short I4B_SLOCK_CONT ; Jump if so

	 mov	 edx,eax	; Copy as new PTE
	 add	 eax,[esp].SLOCK_OFF ; Plus offset within first 4KB or zero
I4B_SLOCKPTE1:
	 inc	 AGROUP:[edi].XDDS_USED ; Count in another entry used

; Determine whether or not we should save data into the caller's structure

	 call	 SLOCK_INCXAVL	; Increment # used if none available
	 jb	 short I4B_SLOCK_XAVL ; Jump if none available (EAX/ECX clobbered)

; Split cases between physical addresses and PTEs

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_PTE ; Should we copy PTEs?
	 jnz	 short I4B_SLOCKPTE2 ; Jump if so

; Save region address

	 mov	 AGROUP:[edi+ebx*(size RDDS_STR)].XDDS_DATA.RDDS_ADDR,eax ; Save it

; Save region size

	 mov	 eax,CON4KB	; Get size of PTE
	 sub	 eax,[esp].SLOCK_OFF ; Less initial offset within first 4KB
	 mov	 [esp].SLOCK_OFF,0 ; Zero initial offset within first 4KB

; Ensure no larger than total region size

	 call	 SLOCK_MIN	; Ensure it's within bounds
	 mov	 AGROUP:[edi+ebx*(size RDDS_STR)].XDDS_DATA.RDDS_SIZE,eax ; Save it

	 jmp	 short I4B_SLOCK_INC ; Join common increment code

; Contiguous PTEs:  add in 4KB to region size unless none available

I4B_SLOCK_CONT:
	 mov	 eax,CON4KB	; Get size of a PTE

; Ensure no larger than total region size

	 call	 SLOCK_MIN	; Ensure it's within bounds

; Add the size into the count for this region

	 add	 [esp].SLOCK_SIZE,eax ; Add it in

	 call	 SLOCK_AVL	; Any available?
	 jb	 short I4B_SLOCK_XAVL ; Jump if not

; Add into previous region size

	 add	 AGROUP:[edi+ebx*(size RDDS_STR)-(size RDDS_STR)].XDDS_DATA.RDDS_SIZE,eax ; Add in

	 jmp	 short I4B_SLOCK_LOOP ; Join common loop code

I4B_SLOCKPTE2:
	 or	 eax,mask $PTE_P ; Mark as present
	 mov	 AGROUP:[edi+ebx*(size PDDS_STR)].XDDS_DATA.PDDS_PTE,eax ; Save as PTE
I4B_SLOCK_INC:
	 inc	 ebx		; Skip to next XDDS_DATA entry

; Determine whether or not we should add in another 4KB to the
; supported region size

	 call	 SLOCK_AVL	; Any available?
	 jb	 short I4B_SLOCK_XAVL ; Jump if not
I4B_SLOCK_LOOP:
	 mov	 eax,CON4KB	; Get size of PTE
	 add	 [esp].SLOCK_REM,eax ; Add into supported region size
I4B_SLOCK_XAVL:
	 add	 edx,CON4KB	; Skip to next contiguous PTE

;;;;;;;; loop	 I4B_SLOCK_NEXT ; Jump if more entries
	 dec	 [esp].SLOCK_CNT ; Account for one fewer
	 jnz	 near ptr I4B_SLOCK_NEXT ; Jump if more entries

; In case there is a previous VDS table, and there are no more
; entries available, check the last entry for contiguity and
; increment the # used if discontiguous.

	 call	 SLOCK_INCXAVL	; Increment # used if none available
;;;;;;;; jb	 short ???	; Jump if none available (EAX/ECX clobbered)

; In case there is a previous VDS table, merge its entries

	 test	 I4B_FLAG,mask $I4B_CPUPHYS ; Izit CPU physical?
	 jnz	 short @F	; Jump if so

	 cmp	 PVDSTAB,0	; Izit active?
	 je	 short @F	; Jump if not

	 call	 SLOCK_MERGE	; Merge 'em
@@:

; See if we used more entries than are available

	 call	 SLOCK_AVL	; Any available?
	 jae	 short I4B_SLOCK_CLC ; Jump if so

; Calculate amount of memory that this DDS can lock

	 mov	 eax,[esp].SLOCK_REM ; Get size of supported region
	 mov	 AGROUP:[edi].XDDS_SIZE,eax ; Save for caller's use

	 add	 esp,type SLOCK_STR ; Strip structure from stack

	 jmp	 INT4B_ERR09 ; Join common error code

I4B_SLOCK_CLC:
	 add	 esp,type SLOCK_STR ; Strip structure from stack

	 jmp	 INT4B_CLC	; Join common OK code

	 assume  gs:nothing	; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 06h -- Scatter/gather unlock region

On entry:

DX	 =	 flags
		 Bit 6 = page table entries should be copied
		 Bit 7 = not present pages should not be locked
			 (ignored if bit 6 clear)
		 All other bits are reserved and must be zero
ES:DI	 ==>	 Extended DMA descriptor structure
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
else
CF	 =	 1
AL	 =	 error code

Error codes

AL	 =	 08	memory was not locked
	 =	 10	reserved bits set in DX

|

	 public  I4B_SUNLK
I4B_SUNLK:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not (@VDSF_PTE or @VDSF_PLOCK)
	 jnz	 near ptr INT4B_ERR10 ; Jump if so

; Address the DDS

	 call	 GET_DDS	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  gs:AGROUP	; Tell the assembler about it

	 call	 INT4B_VIRT_UNLOCK ; Unlock region at EAX for EBX pages
				; ESI = linear address of caller's region
				; Wrap disabled if appropriate

; Otherwise, nothing to do

	 jmp	 INT4B_CLC	; Join common OK code


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 07h -- Request DMA buffer

On entry:

DX	 =	 flags
		 Bit 1 = copy data into buffer
		 All other bits are reserved and must be zero
ES:DI	 ==>	 DMA descriptor structure
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
else
CF	 =	 1
AL	 =	 error code

Error codes

AL	 =	 04	no buffer available
	 =	 05	region too large for buffer
	 =	 06	buffer currently in use
	 =	 07	invalid memory region
	 =	 10	reserved bits set in DX
	 =	 11	invalid selector in DDS

|

	 public  I4B_GETBUF
I4B_GETBUF:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not (@VDSF_COPY or @VDSF_BPHYS)
	 jnz	 near ptr INT4B_ERR10 ; Jump if so

; Address the DDS

	 call	 GET_DDS	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  gs:AGROUP	; Tell the assembler about it

; Ensure the buffer is available

	 cli			; Disallow interrupts

	 test	 I4B_FLAG,mask $I4B_INUSE ; Izit already in use?
	 jnz	 near ptr INT4B_ERR06 ; Yes, can't proceed

; Ensure the region fits inside the buffer

	 movzx	 eax,DMASIZE	; Get size of our DMA buffer
	 shl	 eax,10-0	; Convert from 1KB to bytes

	 cmp	 eax,AGROUP:[edi].DDS_SIZE ; Duzit cover the region size?
	 jb	 near ptr INT4B_ERR05 ; Jump if not

; Allocate the buffer

	 or	 I4B_FLAG,mask $I4B_INUSE ; Mark as in use
	 sti			; Allow interrupts

COMMENT|

The VDS spec is unclear on the following point as to whether or not we
should save back into the caller's DDS the size of our buffer.  A
close reading of the spec suggests that we should, however, that's
actually a bad idea.  The folks at Microsoft agree and will attempt to
clarify it in the next version.

|

;;;;;;;; mov	 AGROUP:[edi].DDS_SIZE,eax ; Save as new region size

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_COPY ; Copy data into our buffer?
	 jz	 short @F	; Jump if not

	 call	 VDS_WRAP	; Check on VDS services wrap
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector
				; ESI = linear address of caller's region
				; Wrap disabled if appropriate
@@:
	 mov	 AGROUP:[edi].DDS_BID,1 ; Mark as buffer allocated

	 mov	 eax,DMA_PA	; Get buffer's physical address
	 mov	 AGROUP:[edi].DDS_POFF,eax ; Save as physical address

; Save caller's buffer address for RELBUF as we can't rely upon anything
; else then except the buffer ID.

	 movzx	 esi,AGROUP:[edi].DDS_FVEC.FSEL ; Get segment, zero high-order word
	 call	 SEGSEL_BASE	; Return with ESI = segment/selector base
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector

	 add	 esi,AGROUP:[edi].DDS_FVEC.FOFF ; Plus offset to get 32-bit address
	 mov	 PDDSBUF,esi	; Save for later use
I4B_GETBUF_COM:
	 call	 MEM2BUF	; Copy data into our buffer if requested
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector

; Because Get Buffer should always return bus physical,
; skip the test for CPU physical

	 jmp	 short I4B_GETBUF_EXIT1 ; Join common code

; In case there was a previous VDS table, translate w.r.t its entries

I4B_GETBUF_EXIT:
	 test	 I4B_FLAG,mask $I4B_CPUPHYS ; Izit CPU physical?
	 jnz	 short @F	; Jump if so
I4B_GETBUF_EXIT1:
	 cmp	 PVDSTAB,0	; Izit active?
	 je	 short @F	; Jump if not

	 push	 AGROUP:[edi].DDS_SIZE ; Pass size in bytes
	 push	 AGROUP:[edi].DDS_POFF ; Pass physical address
	 FCALL	 PVDS_TRANS	; Return with EAX = translated address
				; EDX = next address after contiguous
				;	region (on 4KB boundary)
;;;;;;;; jc	 short ???	; Jump if region not contiguous (can't happen)
	 mov	 AGROUP:[edi].DDS_POFF,eax ; Save new physical address
@@:
	 jmp	 INT4B_CLC	; Join common OK code


	 assume  gs:nothing	; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 08h -- Release DMA buffer

On entry:

DX	 =	 flags
		 Bit 1 = copy data out of buffer
		 All other bits are reserved and must be zero
ES:DI	 ==>	 DMA descriptor structure
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
else
CF	 =	 1
AL	 =	 error code

Error codes

AL	 =	 0A	invalid buffer ID
	 =	 10	reserved bits set in DX
	 =	 11	invalid selector in DDS

|

	 public  I4B_RELBUF
I4B_RELBUF:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not @VDSF_COPY
	 jnz	 near ptr INT4B_ERR10 ; Jump if so

; Address the DDS

	 call	 GET_DDS	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  gs:AGROUP	; Tell the assembler about it

;;;;;;;; cmp	 AGROUP:[edi].DDS_BID,0 ; Izit using local DMA buffer?
;;;;;;;; je	 near ptr INT4B_ERR0A ; Jump if not
;;;;;;;;
	 cmp	 AGROUP:[edi].DDS_BID,1 ; Izit a valid buffer ID?
	 jne	 near ptr INT4B_ERR0A ; Jump if not

	 test	 I4B_FLAG,mask $I4B_INUSE ; Izit already in use?
	 jz	 near ptr INT4B_ERR0A ; No, can't proceed

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_COPY ; Copy data out of our buffer?
	 jz	 short I4B_RELBUF1 ; Jump if not

	 call	 VDS_WRAP	; Check on VDS services wrap
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector
				; ESI = linear address of caller's region
				; Wrap disabled if appropriate

	 mov	 esi,PDDSBUF	; Get the 32-bit linear address
	 call	 BUF2MEM	; Copy data out of our buffer if requested
I4B_RELBUF1:
	 and	 I4B_FLAG,not (mask $I4B_INUSE) ; Mark as available

	 jmp	 INT4B_CLC	; Join common OK code

	 assume  gs:nothing	; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 09h -- Memory to buffer transfer

On entry:

DX	 =	 flags
		 All other bits are reserved and must be zero
BX:CX	 =	 starting offset into our buffer
ES:DI	 ==>	 DMA descriptor structure
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
else
CF	 =	 1
AL	 =	 error code

Error codes

AL	 =	 0A	invalid buffer ID
	 =	 0B	copy count + offset > buffer size
	 =	 10	reserved bits set in DX
	 =	 11	invalid selector in DDS

|

	 public  I4B_MEM2BUF
I4B_MEM2BUF:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not 0
	 jnz	 near ptr INT4B_ERR10 ; Jump if so

; Address the DDS

	 call	 GET_DDS	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  gs:AGROUP	; Tell the assembler about it

;;;;;;;; cmp	 AGROUP:[edi].DDS_BID,0 ; Izit using local DMA buffer?
;;;;;;;; je	 near ptr INT4B_ERR0A ; Jump if not
;;;;;;;;
	 cmp	 AGROUP:[edi].DDS_BID,1 ; Izit a valid buffer ID?
	 jne	 near ptr INT4B_ERR0A ; Jump if not

	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get high-order word of starting offset
	 shl	 eax,16 	; Shift to upper word
	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get low-order word of starting offset

; Ensure that the starting offset + size field is within DMASIZE

	 movzx	 ecx,DMASIZE	; Get size of DMA buffer in 1KB
	 shl	 ecx,10-0	; Convert from 1KB to bytes

	 mov	 edx,AGROUP:[edi].DDS_SIZE ; Get copy length
	 add	 edx,eax	; Add to get ending byte+1
	 jc	 near ptr INT4B_ERR0B ; Jump if invalid

	 cmp	 edx,ecx	; Ensure within range
	 ja	 near ptr INT4B_ERR0B ; Jump if not

	 call	 VDS_WRAP	; Check on VDS services wrap
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector
				; ESI = linear address of caller's region
				; Wrap disabled if appropriate

	 call	 MEM2BUF_SUB	; Copy data into our buffer starting at EAX
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector

	 jmp	 INT4B_CLC	; Join common OK code

	 assume  gs:nothing	; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 0Ah -- Buffer to memory transfer

On entry:

DX	 =	 flags
		 All other bits are reserved and must be zero
BX:CX	 =	 starting offset into our buffer
ES:DI	 ==>	 DMA descriptor structure
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
else
CF	 =	 1
AL	 =	 error code

Error codes

AL	 =	 0A	invalid buffer ID
	 =	 0B	copy count + offset > buffer size
	 =	 10	reserved bits set in DX
	 =	 11	invalid selector in DDS

|

	 public  I4B_BUF2MEM
I4B_BUF2MEM:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not 0
	 jnz	 near ptr INT4B_ERR10 ; Jump if so

; Address the DDS

	 call	 GET_DDS	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  gs:AGROUP	; Tell the assembler about it

;;;;;;;; cmp	 AGROUP:[edi].DDS_BID,0 ; Izit using local DMA buffer?
;;;;;;;; je	 near ptr INT4B_ERR0A ; Jump if not
;;;;;;;;
	 cmp	 AGROUP:[edi].DDS_BID,1 ; Izit a valid buffer ID?
	 jne	 near ptr INT4B_ERR0A ; Jump if not

	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get high-order word of starting offset
	 shl	 eax,16 	; Shift to upper word
	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get low-order word of starting offset

; Ensure that the starting offset + size field is within DMASIZE

	 movzx	 ecx,DMASIZE	; Get size of DMA buffer in 1KB
	 shl	 ecx,10-0	; Convert from 1KB to bytes

	 mov	 edx,AGROUP:[edi].DDS_SIZE ; Get copy length
	 add	 edx,eax	; Add to get ending byte+1
	 jc	 near ptr INT4B_ERR0B ; Jump if invalid

	 cmp	 edx,ecx	; Ensure within range
	 ja	 near ptr INT4B_ERR0B ; Jump if not

	 call	 VDS_WRAP	; Check on VDS services wrap
	 jc	 near ptr INT4B_ERR11 ; Jump if invalid selector
				; ESI = linear address of caller's region
				; Wrap disabled if appropriate

	 call	 BUF2MEM_SUB	; Copy data out of our buffer starting at EAX

	 jmp	 INT4B_CLC	; Join common OK code

	 assume  gs:nothing	; Tell the assembler about it


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 0Bh -- Disable DMA translation

On entry:

BX	 =	 DMA channel #
DX	 =	 flags
		 All bits are reserved and must be zero
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
else
CF	 =	 1
AL	 =	 error code

Error codes

AL	 =	 0C	invalid DMA channel #
	 =	 0D	disable count overflow
	 =	 10	reserved bits set in DX

|

	 public  I4B_DISTRAN
I4B_DISTRAN:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not 0
	 jnz	 near ptr INT4B_ERR10 ; Jump if so

	 movzx	 ebx,[ebp].INTXX_EBX.ELO ; Zero high-order word to use in indexing

	 cmp	 bx,07h 	; Check against maximum DMA channel #
	 ja	 near ptr INT4B_ERR0C ; Jump if too large

	 cli			; Disallow interrupts

	 cmp	 DMADISCNT[ebx*(type DMADISCNT)],-1 ; Check for maximum
	 je	 near ptr INT4B_ERR0D ; Jump if too large

	 inc	 DMADISCNT[ebx*(type DMADISCNT)] ; Count in another one
	 sti			; Allow interrupts

	 jmp	 INT4B_CLC	; Join common OK code


; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様

COMMENT|

Function 0Ch -- Enable DMA translation

On entry:

BX	 =	 DMA channel #
DX	 =	 flags
		 All bits are reserved and must be zero
SS:EBP	 ==>	 INTXX_STR

On exit:

If no error,
CF	 =	 0
else
CF	 =	 1
AL	 =	 error code

Error codes

AL	 =	 0C	invalid DMA channel #
	 =	 0E	disable count underflow
	 =	 10	reserved bits set in DX

|

	 public  I4B_ENATRAN
I4B_ENATRAN:

; Any unsupported flag bits?

	 test	 [ebp].INTXX_EDX.ELO,not 0
	 jnz	 near ptr INT4B_ERR10 ; Jump if so

	 movzx	 ebx,[ebp].INTXX_EBX.ELO ; Zero high-order word to use in indexing

	 cmp	 bx,07h 	; Check against maximum DMA channel #
	 ja	 near ptr INT4B_ERR0C ; Jump if too large

	 cli			; Disallow interrupts

	 cmp	 DMADISCNT[ebx*(type DMADISCNT)],0 ; Check for minimum
	 je	 near ptr INT4B_ERR0E ; Jump if too small

	 dec	 DMADISCNT[ebx*(type DMADISCNT)] ; Count out another one
	 sti			; Allow interrupts
	 jnz	 short @F	; Jump if not enabled as yet

	 or	 [ebp].INTXX_EFL.ELO,mask $ZF ; Set zero flag to indicate enabled
@@:
	 jmp	 INT4B_CLC	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT4B	 endp			; End INT4B procedure
	 NPPROC  GET_DDS -- Get Address Of The DDS
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get the address of the DDS.

On entry:

SS:EBP	 ==>	 INTXX_STR

On exit:

GS:EDI	 ==>	 caller's DDS

|

	 push	 eax		; Save register

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it

if @OEM_DPMI
	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 short @F	; Jump if so

	 push	 es		; Pass selector
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	 jmp	 short GET_DDS_COM ; Join common code

@@:
endif				; IF @OEM_DPMI
	 movzx	 eax,[ebp].INTXX_ES ; Get segment of save area
	 shl	 eax,4-0	; Convert from paras to bytes
GET_DDS_COM:
	 movzx	 edi,[ebp].INTXX_EDI.ELO ; Copy EDI from PL3 DI
	 add	 edi,eax	; GS:EDI ==> PL3 ES:DI

	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_DDS  endp			; End GET_DDS procedure
	 NPPROC  VDS_WRAP -- Initialize Parameters And Check On 1MB Wrap
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Initialize parameters and check on 1MB wrap

On entry:

AGROUP:EDI ==>	 caller's DDS

On exit:

AGROUP:ESI ==>	 caller's region
1MB wrap disabled if appropriate
CF	 =	 0 if all went well
	 =	 1 if invalid selector

|

; Calculate initial parameters

	 movzx	 esi,AGROUP:[edi].DDS_FVEC.FSEL ; Get segment, zero high-order word
	 call	 SEGSEL_BASE	; Return with ESI = segment/selector base
	 jc	 short VDS_WRAP_EXIT ; Jump if invalid selector (note CF=1)

	 add	 esi,AGROUP:[edi].DDS_FVEC.FOFF ; Plus offset to get 32-bit address

COMMENT|

Check on need to disable 1MB wrap.

The wrap must be disabled if

(START < 1.1MB) and (END+1 > 1MB)

|

	 cmp	 esi,CON1P1MB	; Duzit start above 1MB wrap region?
	 jae	 short VDS_WRAP_EXIT ; Jump if so (note CF=0)

	 push	 esi		; Save for a moment

	 add	 esi,AGROUP:[edi].DDS_SIZE ; Plus region size

	 cmp	 CON1MB,esi	; Duzit end below 1MB wrap region?
	 pop	 esi		; Restore
	 jae	 short VDS_WRAP_EXIT ; Jump if so (note CF=0)

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap

	 clc			; Indicate all went well
VDS_WRAP_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VDS_WRAP endp			; End VDS_WRAP procedure
	 NPPROC  SLOCK_AVL -- Scatter/Gather Lock Available
	 assume  ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Determine whether or not any entries available

On entry:

AGROUP:EDI ==>	 XDDS

On exit:

CF	 =	 0 if entries available
	 =	 1 otherwise

|

	 push	 ax		; Save for a moment

	 mov	 ax,AGROUP:[edi].XDDS_AVL ; Get # available

	 cmp	 ax,AGROUP:[edi].XDDS_USED ; Check against # used

	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SLOCK_AVL endp			; End SLOCK_AVL procedure
	 NPPROC  SLOCK_MIN -- Scatter/Gather Lock Minimum
	 assume  ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Ensure size is no larger than total region size.

On entry:

EAX	 =	 putative individual region size
AGROUP:EDI ==>	 XDDS

On exit:

EAX	 =	 actual individual region size

|

SLOCKMIN_STR struc

	 dw	 ?		; Caller's IP
SLOCKMIN_STK dd  ?		; ...	   stack

SLOCKMIN_STR ends

	 add	 eax,[esp].SLOCKMIN_STK.SLOCK_ACC ; Plus accumulated size

	 cmp	 eax,AGROUP:[edi].XDDS_SIZE ; Izit within total region size?
	 jbe	 short @F	; Jump if so

	 mov	 eax,AGROUP:[edi].XDDS_SIZE ; Use total region size
@@:
	 sub	 eax,[esp].SLOCKMIN_STK.SLOCK_ACC ; Less accumulated size

; Add into accumulated region size unless none available

	 call	 SLOCK_AVL	; Any available?
	 jb	 short SLOCK_MIN_EXIT ; Jump if not

	 add	 [esp].SLOCKMIN_STK.SLOCK_ACC,eax ; Add into accumulated size
SLOCK_MIN_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SLOCK_MIN endp			; End SLOCK_MIN procedure
	 NPPROC  SLOCK_MERGE -- Merge Scatter/Gather Lock With Previous VDS Table
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Merge scatter/gather lock with previous VDS table

If the table format is in PTE format (PDDS_STR), translate the
physical addresses one-to-one.

If the table format is in start/length format (RDDS_STR), translate
the starting physical address and length splitting the entry in two if
the PVDS mapping is discontiguous.  This means moving all following
entries in the XDDS_STR structure up one RDDS_STR entry taking into
account that we might exceed the # available entries in the structure.

On entry:

AGROUP:EDI ==>	 Caller's XDDS_STR, filled in
SS:EBP	 ==>	 INTXX_STR

|

	 REGSAVE <eax,ebx,ecx,edx,esi> ; Save registers

	 mov	 esi,PVDSTAB	; Get offset in PGROUP of previous VDS table
	 xor	 ebx,ebx	; Initialize index into caller's table
	 mov	 cx,AGROUP:[edi].XDDS_USED ; Get # entries in caller's table

	 cmp	 cx,AGROUP:[edi].XDDS_AVL ; Izit smaller than # available?
	 jbe	 short @F	; Jump if so

	 mov	 cx,AGROUP:[edi].XDDS_AVL ; Use # available
@@:
	 and	 cx,cx		; Are there any available?
	 jz	 near ptr SLOCK_MERGE_EXIT ; Jump if not

; Split cases between physical addresses and PTEs

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_PTE ; Did we copy PTEs?
	 jz	 short SLOCK_MERGE_RDDS ; Jump if not

; The caller's table format is PTEs and is mapped by PDDS_STR

; Loop through the caller's table and translate PTE to PTE one for one

SLOCK_MERGE_NEXTPTE1:
	 mov	 eax,AGROUP:[edi+ebx*(size PDDS_STR)].XDDS_DATA.PDDS_PTE ; Get next PTE
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame

; Loop through the previous VDS table looking for this physical address

	 REGSAVE <ebx,ecx>	; Save outer loop index and counter

	 xor	 ebx,ebx	; Initialize index into previous VDS table
	 xor	 edx,edx	; Initialize starting PTA
	 mov	 cx,PGROUP:[esi].XDDS_USED ; Get # entries in previous VDS table
SLOCK_MERGE_NEXTPTE2:
	 cmp	 eax,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_EPTA ; Izit in range?
	 jae	 short SLOCK_MERGE_LOOPPTE2 ; Jump if not

; Convert this physical address

	 sub	 eax,edx	; Less starting base
	 add	 eax,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_ADDR ; Plus new base

	 jmp	 short SLOCK_MERGE_EXITPTE2 ; Join common exit code

SLOCK_MERGE_LOOPPTE2:

; Use the previous EPTA value as the next starting PTA

	 mov	 edx,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_EPTA ; Get 'em
	 inc	 ebx		; Skip to next entry in previous VDS table

	 loop	 SLOCK_MERGE_NEXTPTE2 ; Jump if more entries in previous VDS table
SLOCK_MERGE_EXITPTE2:
	 REGREST <ecx,ebx>	; Restore outer loop index and counter

; Save new PTE

	 and	 AGROUP:[edi+ebx*(size PDDS_STR)].XDDS_DATA.PDDS_PTE,not @PTE_FRM
	 or	 AGROUP:[edi+ebx*(size PDDS_STR)].XDDS_DATA.PDDS_PTE,eax ; Set new PTE

	 inc	 ebx		; Skip to next entry in caller's table

	 loop	 SLOCK_MERGE_NEXTPTE1 ; Jump if more entries in caller's table

	 jmp	 SLOCK_MERGE_EXIT ; Join common exit code

; The caller's table format is address/size and is mapped by RDDS_STR

; Loop through the caller's table and translate ranges, possibly
; splitting an entry into two or more parts

SLOCK_MERGE_RDDS:
SLOCK_MERGE_NEXTRNG1:

; Loop through the previous VDS table looking for this physical address

	 REGSAVE <ebx,ecx,edi>	; Save outer loop values

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

SLM_STR  struc

SLM_EBP  dd	 ?		; Caller's EBP
SLM_EDI  dd	 ?		; ...	   EDI
SLM_ECX  dd	 ?		; ...	   ECX
SLM_EBX  dd	 ?		; ...	   EBX

SLM_STR  ends

	 mov	 eax,AGROUP:[edi+ebx*(size RDDS_STR)].XDDS_DATA.RDDS_ADDR ; Get address
	 mov	 edi,AGROUP:[edi+ebx*(size RDDS_STR)].XDDS_DATA.RDDS_SIZE ; Get length
	 add	 edi,eax	; Add to get next address

	 xor	 ebx,ebx	; Initialize index into previous VDS table
	 xor	 edx,edx	; Initialize starting PTA
	 mov	 cx,PGROUP:[esi].XDDS_USED ; Get # entries in previous VDS table
SLOCK_MERGE_NEXTRNG2:
	 cmp	 eax,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_EPTA ; Izit in range?
	 jae	 short SLOCK_MERGE_LOOPRNG2 ; Jump if not

; Convert this physical address

	 sub	 eax,edx	; Less starting base
	 add	 eax,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_ADDR ; Plus new base

; If the entry in the caller's table overlaps the corresponding
; entry in the previous VDS table, we need to split the entry
; in the caller's table

	 sub	 edi,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_EPTA ; Izit overlapping?
	 jbe	 short SLOCK_MERGE_EXITRNG2 ; Jump if not

	 call	 SLOCK_SPLIT	; Split the current entry in two

	 jmp	 short SLOCK_MERGE_EXITRNG2 ; Join common exit code

SLOCK_MERGE_LOOPRNG2:

; Use the previous EPTA value as the next starting PTA

	 mov	 edx,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_EPTA ; Get 'em
	 inc	 ebx		; Skip to next entry in previous VDS table

	 loop	 SLOCK_MERGE_NEXTRNG2 ; Jump if more entries in previous VDS table
SLOCK_MERGE_EXITRNG2:
	 pop	 ebp		; Restore

	 REGREST <edi,ecx,ebx>	; Restore outer loop values

; Save new physical address

	 mov	 AGROUP:[edi+ebx*(size RDDS_STR)].XDDS_DATA.RDDS_ADDR,eax ; Set new address

	 inc	 ebx		; Skip to next entry in caller's table

	 loop	 SLOCK_MERGE_NEXTRNG1 ; Jump if more entries in caller's table
SLOCK_MERGE_EXIT:
	 REGREST <esi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SLOCK_MERGE endp		; End SLOCK_MERGE procedure
	 NPPROC  SLOCK_SPLIT -- Split Scatter/gather Lock Entry In Two
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Split scatter/gather lock entry in two

On entry:

EDI	 =	 size of overlap
SS:EBP	 ==>	 SLM_STR

|

; Make room for a new entry

	 REGSAVE <ecx,edx,esi,edi,es> ; Save for a moment

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 movzx	 ecx,[ebp].SLM_ECX.ELO ; Get # remaining RDDS_STRs to process
				; including this one
	 mov	 edi,[ebp].SLM_EDI ; Get caller's base address
	 movzx	 edx,AGROUP:[edi].XDDS_USED ; Get # entries used so far
	 inc	 dx		; Count in another entry used
	 mov	 AGROUP:[edi].XDDS_USED,dx ; Save for later use

	 cmp	 dx,AGROUP:[edi].XDDS_AVL ; Is there any room?
	 jbe	 short @F	; Jump if so

	 mov	 dx,AGROUP:[edi].XDDS_AVL ; Use smaller
	 dec	 cx		; Less last one which is overwritten
@@:

; The source address is one RDDS_STR structure below the destin
; address for the move upwards

	 lea	 edi,AGROUP:[edi+edx*(size RDDS_STR)].XDDS_DATA ; Get destin address
	 lea	 esi,AGROUP:[edi-(size RDDS_STR)] ; Get source address

	 imul	 ecx,size RDDS_STR ; Convert from RDDS_STR to bytes
	 shr	 ecx,2-0	; Convert from bytes to dwords
	 sub	 esi,size RDDS_ADDR ; Less size of move element
	 sub	 edi,size RDDS_ADDR ; ...
	 std			; Move backwards
S32  rep movs	 <AGROUP:[edi].RDDS_ADDR,AGROUP:[esi].RDDS_ADDR> ; Move 'em
	 cld			; Restore direction flag

	 REGREST <es,edi,esi,edx,ecx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

; Split the entry into two parts
; EDI	 =	 size of overlap

	 REGSAVE <eax,ebx,esi>	; Save registers

	 mov	 esi,[ebp].SLM_EDI ; Get caller's base address
	 mov	 ebx,[ebp].SLM_EBX ; Get caller's entry count
	 mov	 eax,AGROUP:[esi+ebx*(size RDDS_STR)].XDDS_DATA.RDDS_SIZE ; Get old entry size
	 sub	 eax,edi	; Less overlap to get new entry size
	 mov	 AGROUP:[esi+ebx*(size RDDS_STR)].XDDS_DATA.RDDS_SIZE,eax ; Set new entry size
	 inc	 ebx		; Skip to next entry
	 mov	 AGROUP:[esi+ebx*(size RDDS_STR)].XDDS_DATA.RDDS_SIZE,edi ; Set new entry size
	 add	 AGROUP:[esi+ebx*(size RDDS_STR)].XDDS_DATA.RDDS_ADDR,eax ; Set new base address

	 REGREST <esi,ebx,eax>	; Restore

; If we appended a new entry, increment the # RDDS_STRs remaining

	 call	 SLOCK_AVL	; Any available?
				; Return with CF=0 if so
				;		 1 if not
	 cmc			; CF=1 if entry was available
	 adc	 [ebp].SLM_ECX,0 ; Increment if so

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SLOCK_SPLIT endp		; End SLOCK_SPLIT procedure
	 NPPROC  SLOCK_INCXAVL -- Increment # Used if None Available
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

There is a new entry to count, but no more entries are available.
If we're using a previous VDS table, check the base and size of
this pseudo-entry to see if it is contiguous:  if not, count in
additional # entries we would use if we had room.

Increment # used in XDDS if using previous VDS table,
no more entries available and the region is discontiguous.

On entry:

EAX	 =	 base address of new region
EDI	 =	 linear address of caller's XDDS

On exit:

If no entries available,
EAX	 =	 clobbered
ECX	 =	 clobbered
CF	 =	 1

If entries are available,
CF	 =	 0

|

SLIX_STR struc

	 dw	 ?		; Caller's IP
SLIX_NXT db	 (size SLOCK_STR) dup (?) ; The rest of the stack

SLIX_STR ends

	 call	 SLOCK_AVL	; Any available?
	 jnc	 short SLOCK_INCXAVL_EXIT ; Jump if so (note CF=0)

; Split cases between physical addresses and PTEs

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_PTE ; Should we copy PTEs?
	 jnz	 short SLOCK_INCXAVL_STC ; Jump if so

	 test	 I4B_FLAG,mask $I4B_CPUPHYS ; Izit CPU physical?
	 jnz	 short SLOCK_INCXAVL_STC ; Jump if so

	 cmp	 PVDSTAB,0	; Izit active?
	 je	 short SLOCK_INCXAVL_STC ; Jump if not

	 xchg	 eax,[esp].SLIX_NXT.SLOCK_ADDR ; Get old base, save new one
	 mov	 ecx,[esp].SLIX_NXT.SLOCK_SIZE ; Get previous region size

	 push	 edx		; Save over loop
SLOCK_INCXAVL_NEXT:
	 push	 eax		; Save physical address

	 push	 ecx		; Pass region size
	 push	 eax		; Pass physical address
	 FCALL	 PVDS_TRANS	; Return with EAX = translated address
				; EDX = next address after contiguous
				;	region (on 4KB boundary)
	 jnc	 short SLOCK_INCXAVL_CONT ; Jump if it's contiguous

	 inc	 AGROUP:[edi].XDDS_USED ; Count in another entry used

	 sub	 edx,eax	; Subtract to get contiguous length
	 sub	 ecx,edx	; Account for it

	 pop	 eax		; Restore original physical address

	 add	 eax,edx	; Skip over contiguous region

	 jmp	 short SLOCK_INCXAVL_NEXT ; Join common code

SLOCK_INCXAVL_CONT:
	 pop	 eax		; Restore original physical address
	 pop	 edx		; Restore

; Save region size

	 mov	 eax,CON4KB	; Get size of PTE
	 sub	 eax,[esp].SLIX_NXT.SLOCK_OFF ; Less initial offset within first 4KB
	 mov	 [esp].SLIX_NXT.SLOCK_OFF,0 ; Zero initial offset within first 4KB

; Ensure no larger than total region size

	 call	 SLOCK_MIN	; Ensure it's within bounds
	 mov	 [esp].SLIX_NXT.SLOCK_SIZE,eax ; Save it
SLOCK_INCXAVL_STC:
	 stc			; Indicate no entries available
SLOCK_INCXAVL_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SLOCK_INCXAVL endp		; End SLOCK_INCXAVL procedure
	 FPPROC  PVDS_TRANS -- Translate Physical Address With Previous VDS Table
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Translate Physical Address With Previous VDS Table

On exit:

If successful,

CF	 =	 0 if region is contiguous
EAX	 =	 translated physical address
EDX	 =	 next address after contiguous region (on 4KB boundary)

If not successful,

CF	 =	 1 if region not contiguous
EAX	 =	 translated physical address
EDX	 =	 next address after contiguous region (on 4KB boundary)

|

PVDS_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   CS:IP
PVDS_ADDR dd	 ?		; Physical address to translate
PVDS_SIZE dd	 ?		; Size in bytes of region

PVDS_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,esi,edi> ; Save registers

	 mov	 esi,PVDSTAB	; Get offset in PGROUP of previous VDS table

	 mov	 eax,[ebp].PVDS_ADDR ; Get the physical address
	 mov	 edx,[ebp].PVDS_SIZE ; Get size in bytes
	 add	 edx,eax	; Add to get next address

; Loop through the previous VDS table looking for this physical address

	 xor	 ebx,ebx	; Initialize index into previous VDS table
	 mov	 cx,PGROUP:[esi].XDDS_USED ; Get # entries in previous VDS table
	 xor	 edi,edi	; Initialize starting PTA
PVDS_TRANS_NEXT:
	 cmp	 eax,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_EPTA ; Izit in range?
	 jb	 short PVDS_TRANS_CONV ; Jump if so

; Use the previous EPTA value as the next starting PTA

	 mov	 edi,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_EPTA ; Get 'em
	 inc	 ebx		; Skip to next entry in previous VDS table

	 loop	 PVDS_TRANS_NEXT ; Jump if more entries in previous VDS table

; Entry not found in table???

	 clc			; Mark as contiguous

	 jmp	 short PVDS_TRANS_EXIT ; Join common exit code

; Convert this physical address

PVDS_TRANS_CONV:
	 sub	 eax,edi	; Less starting base
	 add	 eax,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_ADDR ; Plus new base

; If the ending address of the entry in the caller's table exceeds
; that of the corresponding entry in the previous VDS table,
; the region is not contiguous.

	 add	 edx,4*1024-1	; Round up to next 4KB boundary
	 and	 edx,not (4*1024-1) ; ...

	 cmp	 PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_EPTA,edx ; Izit contiguous?
	 jae	 short @F	; Jump if so (note CF=0)

	 mov	 edx,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_EPTA ; Get ending address
@@:
	 pushf			; Save CF from CMP above
	 sub	 edx,edi	; Less starting base
	 add	 edx,PGROUP:[esi+ebx*(size VDDS_STR)].XDDS_DATA.VDDS_ADDR ; Plus new base
	 popf			; Restore CF
				; Note CF=0 if contiguous (non-overlapping)
PVDS_TRANS_EXIT:
	 REGREST <edi,esi,ecx,ebx> ; Restore

	 pop	 ebp		; Restore

	 ret	 2*4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PVDS_TRANS endp 		; End PVDS_TRANS procedure
	 NPPROC  INT4B_NEXTPTE -- Get Next PTE
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Get next PTE

If we came from VM and the linear address is out of bounds,
treat the mapping as one-to-one (as if we weren't in the system).

Otherwise, use the current mapping.

On entry:

ESI	 =	 current PTE offset
SS:EBP	 ==>	 INTXX_STR

On exit:

CF	 =	 0 if all went OK
	 =	 1 if VMM active and unable to lock page

EAX	 =	 current PTE
ESI	 =	 updated

|

	 mov	 eax,PRGPDT	; Get offset in PGROUP of PDT
	 add	 eax,PRGBASE	; Plus linear address of PGROUP

	 cmp	 esi,PDTVALID	; Izit beyond valid PTEs?
	 jb	 short INT4B_NEXTPTE_COM ; Jump if not

	 mov	 eax,esi	; Copy offset in PDT
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 short INT4B_NEXTPTE_EXIT ; Jump if so (EAX has result)

; Here if address is in VMM managed area and called from protected mode.
; This code should only be called after the region has been locked with
; VMM_LOCK. Otherwise, page directory entries may be "not present", and
; an unhandled fault will result.

	 mov	 eax,@PTBase	; eax <- base of page tables in agroup
INT4B_NEXTPTE_COM:
	 mov	 eax,AGROUP:[eax+esi].PDT_PTE ; Get the next PTE
	 and	 ax,mask $PTE_FRM ; Isolate the frame
INT4B_NEXTPTE_EXIT:
	 add	 esi,type PDT_PTE ; Skip over it

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT4B_NEXTPTE endp		; End INT4B_NEXTPTE procedure
	 NPPROC  MEM2BUF -- Memory To Buffer Transfer
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Memory to buffer transfer

On entry:

EDI	 ==>	 32-bit linear address of DDS
SS:EBP	 ==>	 INTXX_STR

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_COPY ; Should we copy data into our buffer?
	 jz	 short @F	; Jump if not (note CF=0)

	 push	 eax		; Save for a moment

	 xor	 eax,eax	; Initialize starting offset in our buffer
	 call	 MEM2BUF_SUB	; Copy data into our buffer starting at EAX
				; Return with CF significant
	 pop	 eax		; Restore
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEM2BUF  endp			; End MEM2BUF procedure
	 NPPROC  MEM2BUF_SUB -- Memory To Buffer Transfer Subroutine
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Memory to buffer transfer subroutine

On entry:

EDI	 ==>	 32-bit linear address of DDS
EAX	 =	 starting offset in our buffer for copy

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ecx,esi,edi,es> ; Save registers

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 movzx	 esi,AGROUP:[edi].DDS_FVEC.FSEL ; Get segment, zero high-order word
	 call	 SEGSEL_BASE	; Return with ESI = segment/selector base
	 jc	 short MEM2BUF_SUB_EXIT ; Jump if invalid selector (note CF=1)

	 add	 esi,AGROUP:[edi].DDS_FVEC.FOFF ; Plus offset to get 32-bit address

	 mov	 ecx,AGROUP:[edi].DDS_SIZE ; Get region size in bytes
	 mov	 edi,DMA_LA	; Get linear address of DMA buffer
	 add	 edi,eax	; Add starting offset to get 32-bit linear addr

S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy data into buffer

	 clc			; Indicate all went well
MEM2BUF_SUB_EXIT:
	 REGREST <es,edi,esi,ecx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEM2BUF_SUB endp		; End MEM2BUF_SUB procedure
	 NPPROC  BUF2MEM -- Buffer To Memory Transfer
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Buffer to memory transfer

On entry:

EDI	 ==>	 32-bit linear address of DDS
ESI	 ==>	 32-bit linear address of caller's buffer
SS:EBP	 ==>	 INTXX_STR

|

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_COPY ; Should we copy data out of our buffer?
	 jz	 short @F	; Jump if not

	 push	 eax		; Save for a moment

	 xor	 eax,eax	; Initialize starting offset in our buffer
	 call	 BUF2MEM_SUB	; Copy data out of our buffer starting at EAX

	 pop	 eax		; Restore
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BUF2MEM  endp			; End BUF2MEM procedure
	 NPPROC  BUF2MEM_SUB -- Buffer To Memory Transfer Subroutine
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Buffer to memory transfer subroutine

On entry:

EDI	 ==>	 32-bit linear address of DDS
ESI	 ==>	 32-bit linear address of caller's buffer
EAX	 =	 starting offset in our buffer for copy

|

	 REGSAVE <ecx,esi,edi,es> ; Save registers

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ecx,AGROUP:[edi].DDS_SIZE ; Get region size in bytes

	 mov	 edi,DMA_LA	; Get linear address of DMA buffer
	 xchg	 esi,edi	; Swap 'em for move in opposite direction
	 add	 esi,eax	; Skip to starting offset in our buffer

S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy data into buffer

	 REGREST <es,edi,esi,ecx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BUF2MEM_SUB endp		; End BUF2MEM_SUB procedure
	 FPPROC  FSEGSEL_BASE -- Get Segment/Selector Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get segment/selector base

Far call to SEGSEL_BASE.

On entry:

Same as SEGSEL_BASE.

On exit:

Same as SEGSEL_BASE.

|

	 call	 SEGSEL_BASE	; Return with ESI = segment/selector base
				; Return with CF significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FSEGSEL_BASE endp		; End FSEGSEL_BASE procedure
	 NPPROC  SEGSEL_BASE -- Get Segment/Selector Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get segment/selector base

On entry:

ESI	 =	 segment or selector
SS:EBP	 ==>	 INTXX_STR

On exit:

ESI	 =	 base address of segment/selector

CF	 =	 0 if valid selector
	 =	 1 otherwise

|

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 short SEGSEL_BASE1 ; Jump if so

	 and	 si,si		; Izit a zero selector?
	 jz	 short SEGSEL_BASE_EXIT ; Jump if so (note CF=0)

	 push	 eax		; Save for a moment

	 push	 si		; Pass the selector
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector
;;;;;;;; jc	 short ???	; Return with CF significant

	 mov	 esi,eax	; Copy to output register

	 pop	 eax		; Restore

	 jmp	 short SEGSEL_BASE_EXIT ; Join common exit code

SEGSEL_BASE1:
	 shl	 esi,4-0	; Convert from paras to bytes (note CF=0)
SEGSEL_BASE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEGSEL_BASE endp		; End SEGSEL_BASE procedure
	 NPPROC  INT4B_CPUPHYS -- Izit CPU Physical
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Izit CPU physical?

Windows Standard Mode and other programs use VDS services to translate
XMS linear addresses to physical addresses so it can fill up its page
tables for VCPI.  Were we to not recognize this case, we would double
translate the VDS addresses through any previous VDS table and give
Windows the wrong physical address.  Others also use the VDS
translation technique in preparation for entering PM through VCPI.
The distinction we need to draw is between the above programs who need
a CPU physical translation versus those which need a bus physical
translation.

In order to avoid such problems, we need to recognize this case.  The
technique used is to return a bus physical translation only if the VDS
service call occurs during an INT 13h call; otherwise, we perform a
CPU physical translation.

On entry:

SS:EBP	 ==>	 INTXX_STR

|

	 test	 [ebp].INTXX_EDX.ELO,@VDSF_BPHYS ; Izit bus physical?
	 jnz	 short INT4B_CPUPHYS_EXIT ; Jump if so

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSHI	; Get high DOS memory selector
	 assume  ds:PGROUP	; Tell the assembler about it

	 cmp	 I13CNT,0	; Izit within an INT 13h call?
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jne	 short INT4B_CPUPHYS_EXIT ; Jump if so

	 or	 I4B_FLAG,mask $I4B_CPUPHYS ; Mark as CPU physical
INT4B_CPUPHYS_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT4B_CPUPHYS endp		; End INT4B_CPUPHYS procedure
	 NPPROC  INT4B_VIRT_LOCK -- Lock Pages In VMM Managed Region
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:PGROUP
COMMENT|

If the call came from protected mode and the linear address is in the
VMM managed area, try to lock it.

On entry:

EDX	 =	 32-bit linear address of region to lock
ECX	 =	 size of region to lock, in pages
SS:EBP	 ==>	 INTXX_STR

On exit:

CF	=	0 successfully locked, or not managed by VMM
	=	1 couldn't lock it

|
	 REGSAVE <eax,ebx,ecx,ds>  ; Save registers

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 short INT4B_VIRT_LOCK_EXIT ; Jump if so (note CF=0)

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

; See if the address is managed by the VMM

	 mov	 eax,edx	; Copy region address
	 and	 eax,@PTE_FRM	; Isolate the 4KB frame

	 cmp	 LinearBottom,eax ; Izit below bottom of VMM region?
	 ja	 short INT4B_VIRT_LOCK_EXIT ; Jump if so (note CF=0)

	 cmp	 eax,LinearClientTop ; Izit above top of VMM region?
	 jae	 short INT4B_VIRT_LOCK_EXIT ; Jump if so (note CF=0)

; Ok, it's a VMM address so try to lock it down.

	 mov	 ebx,ecx	; Copy size of region in pages
	 FIXICALL IGROUP:FVMM_LOCK,DTE_CSIG ; Lock region at EAX for EBX pages
	 jc	 INT4B_VIRT_LOCK_EXIT ; jump if that failed

	 test	 VMM_FLAG,@VMM_BSPRES	; is swapping happening?
	 jnz	 short INT4B_VL_OK	; if so, we are done

; If there is no swapfile, we touch the pages to force them into memory

INT4B_VL_TOUCH:
	 mov	 bl,AGROUP:[eax] ; Touch it
	 add	 eax,@PageSize	; Skip to the next page

	 loopd	 INT4B_VL_TOUCH ; Jump if there's more pages to touch
INT4B_VL_OK:
	 clc
INT4B_VIRT_LOCK_EXIT:
	 REGREST <ds,ecx,ebx,eax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT4B_VIRT_LOCK endp		; End INT4B_VIRT_LOCK procedure
	 NPPROC  INT4B_VIRT_UNLOCK -- Unlock A Region If VMM Managed
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

If the call came from protected mode and the linear address is in the
VMM managed area, try to unlock it.

On entry:

EDI	 ==>	 32-bit linear address of DDS
SS:EBP	 ==>	 INTXX_STR

On exit:

ESI	 =	 32-bit linear address of caller's buffer
CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,ds>	; Save registers

	 call	 VDS_WRAP	; Check on VDS services wrap
	 jc	 near ptr INT4B_VIRT_UNLOCK_EXIT ; Jump if invalid selector (note CF=1)
				; ESI = linear address of caller's region
				; Wrap disabled if appropriate

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 near ptr INT4B_VIRT_UNLOCK_EXIT ; Jump if so (note CF=0)

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

; See if the address is managed by the VMM

	 mov	 eax,esi	; Copy linear address
	 and	 eax,@PTE_FRM	; Isolate frame

	 cmp	 LinearBottom,eax ; Izit below bottom of VMM region?
	 ja	 short INT4B_VIRT_UNLOCK_EXIT ; Jump if so (note CF=0)

	 cmp	 eax,LinearClientTop ; Izit above top of VMM region?
	 jae	 short INT4B_VIRT_UNLOCK_EXIT ; Jump if so (note CF=0)

	 mov	 ebx,AGROUP:[edi].DDS_SIZE ; Get size in bytes
	 add	 ebx,esi	; Add to address next byte
	 add	 ebx,@PageSize-1 ; Round up to page
	 and	 ebx,@PTE_FRM	; ...
	 sub	 ebx,eax	; Get full size of region
	 shr	 ebx,@BytePage	; Convert to pages

; Ok, it's a VMM address so try to unlock it

	 cmp	 [ebp].INTXX_EAX.ELO,8106h ; scatter/gather?
	 jne	 short INT4B_VUL_NORMAL ; jump if not

	 test	 [ebp].INTXX_EDX.ELO.LO,@VDSF_PLOCK ; Present pages only?
	 jz	 short INT4B_VUL_NORMAL ; jump if all pages

; Here if we are doing a scatter/gather unlock AND there may be pages that
; were not locked.

	 mov	 ecx,ebx	; ecx <- page count
INT4B_VUL_LOOP:
	 mov	 edx,eax	; Copy region addresss to make PTE address
	 MakePTEaddress edx	; edx <- address of PTE of address to unlock

	 test	 AGROUP:[edx].LO,@PG_PRESENT ; Is the page present?
	 jz	 short @F	; Skip this page if it is not present

	 mov	 ebx,1		; ebx <- count of pages to unlock
	 FIXICALL IGROUP:FVMM_UNLOCK,DTE_CSIG ; Unlock the current page
@@:
	 add	 eax,@PageSize	; eax <- address of next page to unlock

	 loopd	 INT4B_VUL_LOOP ; Jump if pages to check

	 clc			; Mark as success

	 jmp	 INT4B_VIRT_UNLOCK_EXIT ; Done

INT4B_VUL_NORMAL:
	 FIXICALL IGROUP:FVMM_UNLOCK,DTE_CSIG ; Unlock region at EAX for EBX pages
				; Return with CF significant
INT4B_VIRT_UNLOCK_EXIT:
	 REGREST <ds,edx,ecx,ebx,eax>	; Restore registers
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT4B_VIRT_UNLOCK endp		; End INT4B_VIRT_UNLOCK procedure
	 NPPROC INT4B_VIRT_LOCKPRESENT -- Lock present pages managed by VMM
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:PGROUP
COMMENT|

If the call came from protected mode and the linear address is in the
VMM managed area, try to lock it.

On entry:

EDX	 =	 32-bit linear address of region to lock
ECX	 =	 size of region to lock, in pages
SS:EBP	 ==>	 INTXX_STR

On exit:

CF	=	0 successfully locked, or not managed by VMM
	=	1 couldn't lock it

|
	 test	 VMM_FLAG,@VMM_BSPRES	; is swapping happening?
	 jz	 INT4B_VIRT_LOCK	; if not, treat as lock all

	 REGSAVE <eax,ebx,ecx,esi,ds>  ; Save registers

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 near ptr INT4B_VLP_EXIT ; Jump if so (note CF=0)

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

; See if the address is managed by the VMM

	 mov	 eax,edx	; Copy region address
	 and	 eax,@PTE_FRM	; Isolate the 4KB frame

	 cmp	 LinearBottom,eax ; Izit below bottom of VMM region?
	 ja	 near ptr INT4B_VLP_EXIT ; Jump if so (note CF=0)

	 cmp	 eax,LinearClientTop ; Izit above top of VMM region?
	 jae	 near ptr INT4B_VLP_EXIT ; Jump if so (note CF=0)

	 mov	 eax,edx	; Copy address to lock
	 and	 eax,@PTE_FRM	; Isolate the 4KB frame

	 push	 ecx		; Save count of pages to lock
INT4B_VLP_LOOP:
	 mov	 esi,eax	; Copy it again to make PTE address
	 MakePTEaddress esi	; esi <- address of PTE of address to lock

	 test	 AGROUP:[esi].LO,@PG_PRESENT ; Is the page present?
	 jz	 short @F	; Skip this page if it is not present

	 mov	 ebx,1		; ebx <- count of pages to lock
	 FIXICALL IGROUP:FVMM_LOCK,DTE_CSIG ; Lock the current page
	 jc	 INT4B_VLP_UNDO ; If it fails, have to unlock pages
@@:
	 add	 eax,@PageSize	; eax <- address of next page to lock

	 loopd	 INT4B_VLP_LOOP ; Do next page

	 pop	 ecx		; Restore (discard stack) count

	 clc			; Mark success

	 jmp	 short INT4B_VLP_EXIT ; we are done

INT4B_VLP_UNDO:
; We got part way thru the region, and then couldn't lock a page, so we
; have to unlock everything we locked. ECX currently holds the number of
; pages that were left to try to lock when we failed (including failed page).

	 pop	 eax		; eax<-original number of pages to lock
	 sub	 eax,ecx	; eax<-number of pages to check for unlocking
	 mov	 ecx,eax	; ecx<-count to unlock
	 mov	 eax,edx	; eax<-start address of region
	 and	 eax,@PTE_FRM	; Isolate the 4KB frame
INT4B_VLP_UNDOLOOP:
	 mov	 esi,eax	; Copy it again to make PTE address
	 MakePTEaddress esi	; esi <- address of PTE of address to unlock

	 test	 AGROUP:[esi].LO,@PG_PRESENT ; Is the page present?
	 jz	 short @F	; Skip this page if it is not present

	 mov	 ebx,1		; ebx <- count of pages to unlock
	 FIXICALL IGROUP:FVMM_UNLOCK,DTE_CSIG ; Unlock the current page
@@:
	 add	 eax,@PageSize	; eax <- address of next page to unlock

	 loopd	 INT4B_VLP_UNDOLOOP ; Do next page

	 stc			; Mark failure
INT4B_VLP_EXIT:
	 REGREST <ds,esi,ecx,ebx,eax>

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT4B_VIRT_LOCKPRESENT endp		; End INT4B_VIRT_LOCKPRESENT procedure
	 align	 4		; Ensure dword alignment

JCODE	 ends			; End JCODE segment
endif				; IF @OEM_VDS

	 MEND			; End QMAX_I4B module

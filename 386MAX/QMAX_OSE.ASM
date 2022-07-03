;' $Header:   P:/PVCS/MAX/386MAX/QMAX_OSE.ASV   1.3   30 May 1997 10:45:48   BOB  $
	 title	 QMAX_OSE -- 386MAX INT 67h Handler, EMM 4.0 OSE Fns
	 page	 58,122
	 name	 QMAX_OSE

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include PDTGRP.INC
	 include ALLMEM.INC

	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
.list

if @OEM_EMS

PGROUP	 group	 CODE,ECODE,EDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 PRPNTAB:dword
	 extrn	 PRPNCUR:dword
	 extrn	 RPNCURSIZ:word
	 extrn	 CON64KB:dword
	 extrn	 NPHYS16S:byte
	 extrn	 OFFCR3:dword
	 extrn	 PDTDIR2:dword
	 extrn	 PPDT1MB:dword
	 extrn	 PPDTPDIR:dword
	 extrn	 PaDIR2:dword
	 extrn	 PRGBASE:dword

	 public  LCL28_VEC
LCL28_VEC dd	 0		; Function 28 ES:DI save area

	 public  ACCKEY
ACCKEY	 dd	 ?		; Access key for OS/E functions

	 public  PMRS_PDT
PMRS_PDT dd	 ?		; Offset in PDT of AMRS PDEs

	 public  EMM_FLAG
	 include QMAX_EMM.INC
EMM_FLAG dw	 0		; EMM flags

	 public  MRS_MAX,MRS_CUR
MRS_MAX  db	 0,0		; Maximum allowed MRS # (usable as word)
MRS_CUR  db	 0,0		; Current Mapping Register Set (usable as word)

	 public  AMRS_TAB,@AMRS_FREE,@AMRS_INUSE
@AMRS_TABLEN equ 255
AMRS_TAB db	 @AMRS_TABLEN dup (@AMRS_FREE) ; AMRS usage table
@AMRS_FREE  equ   0		; AMRS available
@AMRS_INUSE equ  0FFh		; AMRS in use

	 public  GETXINFO_FNS
GETXINFO_FNS dw  PGROUP:EMM_GETXINFO0
	 dw	 PGROUP:EMM_GETXINFO1
GETXINFO_CNT equ ($-GETXINFO_FNS)/2


	 public  OSE_FNS
OSE_FNS  label	 word
	 dw	 PGROUP:EMM_OSE0
	 dw	 PGROUP:EMM_OSE1
	 dw	 PGROUP:EMM_OSE2
OSE_CNT  equ	 ($-OSE_FNS)/2


	 public  ALTMAPREG_FNS
ALTMAPREG_FNS label word
	 dw	 PGROUP:EMM_ALTMAPREG0
	 dw	 PGROUP:EMM_ALTMAPREG1
	 dw	 PGROUP:EMM_ALTMAPREG2
	 dw	 PGROUP:EMM_ALTMAPREG3
	 dw	 PGROUP:EMM_ALTMAPREG4
	 dw	 PGROUP:EMM_ALTMAPREG5
	 dw	 PGROUP:EMM_ALTMAPREG6
	 dw	 PGROUP:EMM_ALTMAPREG7
	 dw	 PGROUP:EMM_ALTMAPREG8
ALTMAPREG_CNT equ ($-ALTMAPREG_FNS)/2


EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_OSE_ECODE
@QMAX_OSE_ECODE:		; Mark module start in .MAP file

	 extrn	 EMM_E00AL:near
	 extrn	 EMM_E8F:near
	 extrn	 EMM_E9B:near
	 extrn	 EMM_E9C:near
	 extrn	 EMM_E9D:near
	 extrn	 EMM_EA3:near
	 extrn	 EMM_EA4:near

	 extrn	 EMM_PGCNT:near
	 extrn	 PL3ESDI:near
	 extrn	 COPY2LCL:near
	 extrn	 RPN_DIFF:near
	 extrn	 RPN_STORE:near

	 NPPROC  EMM_GETXINFO -- Expanded Memory Hardware Information
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 26, AH = 59h

Expanded memory hardware information functions

Note that for this function, only subfunction 0 is sensitive
to @EMM_NOSE; subfunction 1 is not.

Error return 8F if subfunction parameter invalid

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 cmp	 al,GETXINFO_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 GETXINFO_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETXINFO endp		; End EMM_GETXINFO procedure
	 NPPROC  EMM_GETXINFO0 -- Get Expanded Memory Hardware Information
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 26, AX = 5900h

Get expanded memory hardware information

Error return A4 if OSE fns disabled

All registers except EBP, SS, and ESP may be destroyed.

|

GETXINFO0_STR struc

RAW_PAGE_SIZE			dw	?
ALTERNATE_REGISTER_SETS 	dw	?
CONTEXT_SAVE_AREA_SIZE		dw	?
DMA_CHANNELS			dw	?
DMA_CHANNEL_OPERATION		dw	?

GETXINFO0_STR ends

	 test	 EMM_FLAG,@EMM_NOSE ; OS/E functions allowed?
	 jnz	 near ptr EMM_EA4 ; Not this time

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 es:[edi].RAW_PAGE_SIZE,16*1024/16 ; Raw page size is 16KB in paras
	 mov	 ax,MRS_MAX.ELO ; Get # additional AMRS
	 mov	 es:[edi].ALTERNATE_REGISTER_SETS,ax
	 mov	 ax,RPNCURSIZ	; Get size of RPNCUR area
	 mov	 es:[edi].CONTEXT_SAVE_AREA_SIZE,ax ; Save it
	 mov	 es:[edi].DMA_CHANNELS,0 ; No DMA channels supported
	 mov	 es:[edi].DMA_CHANNEL_OPERATION,0 ; DMA channel operations as per fn 28

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETXINFO0 endp		; End EMM_GETXINFO0 procedure
	 NPPROC  EMM_GETXINFO1 -- Get Raw Page Count Information
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 26, AX = 5901h

Get raw page count information

Errors as per EMM_PGCNT.

All registers except EBP, SS, and ESP may be destroyed.

|

	 jmp	 EMM_PGCNT	; Treat as "cooked" pages

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETXINFO1 endp		; End EMM_GETXINFO1 procedure
	 NPPROC  EMM_ALTMAPREG -- Alternate Map Register Functions
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 28, AH = 5Bh

Alternate map register functions

Error return 8F if subfunction parameter invalid
	     A4 if OSE fns disabled

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,ALTMAPREG_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 test	 EMM_FLAG,@EMM_NOSE ; OS/E functions allowed?
	 jnz	 near ptr EMM_EA4 ; Not this time

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 ALTMAPREG_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALTMAPREG endp		; End EMM_ALTMAPREG procedure
	 NPPROC  EMM_ALTMAPREG0 -- Alternate Map Register Get
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 28, AH = 5B00h

Alternate map register get

If MRS_CUR = 0,
return BL = 0 and ES:DI = LCL28_VEC saved by subfn 1
else
return BL = MRS_CUR.

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 al,MRS_CUR	; Get current MRS
	 mov	 [ebp].INTXX_EBX.ELO.LO,al ; Return as BL

	 cmp	 al,0		; Check current MRS
	 jne	 short EMM_ALTMAPREG0_EXIT ; That's all folks

	 mov	 ax,LCL28_VEC.VOFF ; Get previous DI
	 mov	 [ebp].INTXX_EDI.ELO,ax ; Return to caller

	 mov	 ax,LCL28_VEC.VSEG ; Get previous ES
	 mov	 [ebp].INTXX_ES,ax ; Return to caller

; See if the outgoing ES:DI is 0:0 -- if so, don't store out the pages

;;;;;;;; mov	 ax,LCL28_VEC.VSEG ; Here's caller's ES
	 or	 ax,LCL28_VEC.VOFF ; along with DI
	 jz	 short EMM_ALTMAPREG0_EXIT ; It's 0:0, so just exit

	 call	 RPN_STORE	; Store 'em out
EMM_ALTMAPREG0_EXIT:
	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALTMAPREG0 endp		; End EMM_ALTMAPREG0 procedure
	 NPPROC  EMM_ALTMAPREG1 -- Alternate Map Register Set
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM Function 28, AH = 5B01h

Alternate map register set

If BL = 0, save caller's ES:DI to return in subfunction 0,
read the contents of ES:DI into RPNCUR,
and set @EMM_SET28.

Error return 9C if MRS_MAX = 0 and BL > 0.
	     9D if BL > MRS_MAX or AMRS_TAB[BL-1] = 0.

Otherwise, activate MRS corresponding to BL.

All registers except EBP, SS, and ESP may be destroyed.

|

	 cli			; Disallow interrupts

	 movzx	 esi,[ebp].INTXX_EBX.ELO.LO ; Get value of BL

	 and	 si,si		; Check for software emulation mode
	 jz	 short EMM_ALTMAPREG1_EMU ; Emulate it

	 cmp	 si,MRS_MAX.ELO ; Izit in range?
	 ja	 near ptr EMM_ALTMAPREG1_ERR ; No, so that's an error

	 cmp	 AMRS_TAB[si-1],@AMRS_INUSE ; Izit in use?
	 jne	 near ptr EMM_ALTMAPREG1_ERR ; No, so that's an error

	 mov	 MRS_CUR.ELO,si ; Save as current MRS -- This value
				; *MUST* be set before calling SET_AMRS
	 mov	 ebx,esi	; Copy to set PRPNCUR
	 shl	 ebx,(6+1)-0	; Convert from 64 words to bytes
	 add	 ebx,PRPNTAB	; Plus start of RPN tables
	 mov	 PRPNCUR,ebx	; Save as new current PRN table

	 dec	 esi		; Convert to origin-0
	 shl	 esi,2-0	; Convert from dwords to bytes
	 add	 esi,PMRS_PDT	; Plus offset in PDT of MRS_PDE

; Setup address of 1MB area in new PDIR

	 mov	 edi,esi	; Copy offset in PDT
	 shl	 edi,(12-2)-0	; Convert from 4KB in dwords to bytes
	 sub	 edi,PRGBASE	; Less our program base to make relative to PGROUP
	 add	 edi,PPDT1MB	; Plus start of 1MB in the PDT
				; ES:EDI ==> start of 1MB entries in new PDT

	 mov	 eax,OFFPDT[esi] ; Get the current entry
	 call	 SET_AMRS	; Save EAX as the current AMRS PDE
				; Set HMA PTEs into ES:EDI
				; Some EGP registers clobbered

	 jmp	 EMM_E00AL	; Join common OK code

EMM_ALTMAPREG1_EMU:
	 xchg	 si,MRS_CUR.ELO ; Save as current MRS -- This value
				; *MUST* be set before calling SET_AMRS

	 and	 si,si		; Wuzit already zero?
	 jz	 short EMM_ALTMAPREG1_EMU1 ; Jump if so

	 mov	 eax,PRPNTAB	; Get start of RPN tables
	 mov	 PRPNCUR,eax	; Save as new current PRN table

; Setup address of 1MB area in new PDIR

	 push	 es		; Save for a moment

	 push	 DTE_D4GB	; Get all memory data selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PPDTPDIR	; Get location of PDIR PTE
	 shl	 edi,(12-2)-0	; Convert from 4KB in dwords to bytes
	 add	 edi,PPDT1MB	; Plus start of 1MB in the PDT
				; ES:EDI ==> start of 1MB entries in new PDT

	 mov	 eax,PaDIR2	; Get physical address of PTEs
	 call	 SET_AMRS	; Save EAX as the current AMRS PDE
				; Set HMA PTEs into ES:EDI
				; Some EGP registers clobbered
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
EMM_ALTMAPREG1_EMU1:
	 mov	 ax,[ebp].INTXX_EDI.ELO ; Get caller's DI
	 mov	 LCL28_VEC.VOFF,ax ; Save to return in subfn 0

	 mov	 ax,[ebp].INTXX_ES ; Get caller's ES
	 mov	 LCL28_VEC.VSEG,ax ; Save to return in subfn 0

	 or	 EMM_FLAG,@EMM_SET28 ; Mark as set has been done

; See if the incoming ES:DI is 0:0 -- if so, don't read in the pages

;;;;;;;; mov	 ax,LCL28_VEC.VSEG ; Here's caller's ES
	 or	 ax,LCL28_VEC.VOFF ; along with DI
	 jz	 short EMM_ALTMAPREG1_EXIT ; It's 0:0, so just exit

; Convert PL3 ES:DI to DS:ESI

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it

	 movzx	 eax,[ebp].INTXX_ES ; Get segment of save area
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,[ebp].INTXX_EDI.ELO ; Copy DI from PL3 DI
	 add	 esi,eax	; DS:ESI ==> PL3 ES:DI

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 movzx	 ecx,RPNCURSIZ	; CX = # bytes in RPNCUR area
	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 cx,NPHYS16S.ELO ; CX = # entries in RPNCUR
	 mov	 edi,PRPNCUR	; ES:EDI ==> EMS frame entries in RPNCUR

	 call	 RPN_DIFF	; Remap CX RPNs at DS:ESI which differ
	 jc	 near ptr EMM_EA3 ; Jump if something went wrong

	 sti			; Allow interrupts
EMM_ALTMAPREG1_EXIT:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

; Note that the stack is cut back to EBP at EMM_EXIT.

	 jmp	 EMM_E00AL	; Join common OK code

EMM_ALTMAPREG1_ERR:
	 cmp	 MRS_MAX,0	; Check on our support
	 je	 near ptr EMM_E9C ; Call it unsupported

	 jmp	 EMM_E9D	; Call it out of range

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALTMAPREG1 endp		; End EMM_ALTMAPREG1 procedure
	 NPPROC  SET_AMRS -- Save EAX as Current AMRS PDE
	 assume  ds:PGROUP,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Save EAX as the current AMRS PDE.

On entry:

ES:EDI	 ==>	 destin for HMA PTEs from PPDT1MB
EAX	 =	 new PDE
MRS_CUR  =	 new MRS

|

;;;;;;;; REGSAVE <ax,edi>	; Save registers

; Copy PTEs from HMA area in current to new PDIR

	 mov	 ecx,64/4	; # 4KB pages in the 64KB
	 mov	 esi,PPDT1MB	; FS:ESI ==> start of 1MB entries in PDT
S32  rep movs	 <es:[edi].PDT_PTE,OFFPDT[esi]> ; Copy 'em

	 or	 ax,@PTE_URP	; Ensure properly marked
	 mov	 edi,OFFCR3	; Get offset to PDE table
	 mov	 PGROUP:[edi].PDT_PTE,eax ; Save as first entry in PDE

	 test	 LCL_FLAG,@LCL_4MB ; Izit above 4MB limit?
	 jz	 short SET_AMRS_FLUSH ; No, join common flush code

	 mov	 edi,PDTDIR2	; Get offset to PDT PTE in PDT table
	 and	 ax,not (mask $PTE_US) ; Disable the user-bit
	 mov	 OFFPDT[edi],eax ; Save as new PTE
SET_AMRS_FLUSH:
	 or	 GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush

;;;;;;;; REGREST <edi,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_AMRS endp			; End SET_AMRS procedure
	 NPPROC  EMM_ALTMAPREG2 -- Alternate Map Register Size
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 28, AH = 5B02h

Alternate map register size

Return RPNCURSIZ in DX.

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 ax,RPNCURSIZ	; Get array size
	 mov	 [ebp].INTXX_EDX.ELO,ax ; Return in caller's DX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALTMAPREG2 endp		; End EMM_ALTMAPREG2 procedure
	 NPPROC  EMM_ALTMAPREG3 -- Alternate Map Register Allocate
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM Function 28, AH = 5B03h

Alternate map register allocate

Return BL = next available MRS

Error return 9B if none available.

All registers except EBP, SS, and ESP may be destroyed.

|

	 cli			; Disallow interrupts

	 mov	 cx,MRS_MAX.ELO ; Get maximum allowed

	 and	 cx,cx		; Izit software emulation only?
	 jz	 near ptr EMM_ALTMAPREG3_EMU ; Jump if so

	 mov	 al,@AMRS_INUSE ; In use marker
	 lea	 edi,AMRS_TAB	; ES:EDI ==> available AMRS table
    repe scasb			; Skip over AMRS in use
	 je	 near ptr EMM_E9B ; Jump if none available

	 sub	 edi,offset es:AMRS_TAB ; Convert to origin-1
	 mov	 AMRS_TAB[di-1],@AMRS_INUSE ; Mark as in use
	 mov	 ax,di		; Copy to high/low register
	 mov	 [ebp].INTXX_EBX.ELO.LO,al ; Return as BL

; Copy current contents of RPN table into the allocated RPN table

	 REGSAVE <edi>		; Save register

	 mov	 esi,PRPNCUR	; DS:ESI ==> current RPN table
	 shl	 edi,(6+1)-0	; Convert from 64 words to bytes
	 add	 edi,PRPNTAB	; Plus start of RPN tables
	 movzx	 ecx,RPNCURSIZ	; ECX = # bytes in RPNCUR
S32  rep movs	 <PGROUP:[edi].LO,PGROUP:[esi].LO> ; Copy 'em

	 REGREST <edi>		; Restore

	 sti			; Allow interrupts

; Copy current contents of the PDT into the allocated PDE

	 push	 DTE_AMRS	; Get our AMRS selector
	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 dec	 edi		; Convert to origin-0
	 mov	 esi,edi	; Save for later use
	 shl	 edi,12-0	; Convert from 4KB to bytes
				; ES:EDI ==> specified AMRS PDE

	 REGSAVE <esi,edi>	; Save offset

	 xor	 esi,esi	; FS:ESI ==> start of PDT
	 mov	 ecx,4*1024/4	; Size of PDE in dwords
S32  rep movs	 <es:[edi].PDT_PTE,OFFPDT[esi]> ; Copy it

	 REGREST <edi,esi>	; Restore

; If the first PTE is within the PDE (4MB worth), we must copy
; the new PDE into the new PTE

	 test	 LCL_FLAG,@LCL_4MB ; Izit above 4MB limit?
	 jnz	 short EMM_ALTMAPREG3_EXIT ; Yes, skip this

	 add	 edi,PDTDIR2	; ES:EDI ==> DIR2 in new AMRS

	 shl	 esi,2-0	; Convert from dwords to bytes
	 add	 esi,PMRS_PDT	; Plus offset in PDT of MRS_PDE
				; FS:ESI ==> associated PDE

	 lods	 OFFPDT[esi]	; Get the new PDE
	 or	 ax,@PTE_RP	; Ensure properly marked
S32	 stos	 es:[edi].PDT_PTE ; Copy the PDE into the PTE
	 or	 GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush
EMM_ALTMAPREG3_EXIT:
	 jmp	 EMM_E00AL	; Join common OK code

EMM_ALTMAPREG3_EMU:
	 mov	 [ebp].INTXX_EBX.ELO.LO,0 ; Return as BL

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALTMAPREG3 endp		; End EMM_ALTMAPREG3 procedure
	 NPPROC  EMM_ALTMAPREG4 -- Alternate Map Register Deallocate
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 28, AH = 5B04h

Alternate map register deallocate

If BL = 0, clear @EMM_SET28.

If BL > 0, clear AMRS_TAB[BL-1]

Error return 9C if MRS_MAX = 0 and BL > 0.
	     9D if BL > MRS_MAX or BL = MRS_CUR

All registers except EBP, SS, and ESP may be destroyed.

|

	 movzx	 si,[ebp].INTXX_EBX.ELO.LO ; Get value of BL

	 and	 si,si		; See if BL = 0
	 jz	 short EMM_ALTMAPREG4_EMU ; Jump if software emulation

	 cmp	 si,MRS_MAX.ELO ; Izit in range?
	 ja	 short EMM_ALTMAPREG4_ERR ; No, so that's an error

	 cmp	 si,MRS_CUR.ELO ; Izit the current AMRS?
	 je	 short EMM_ALTMAPREG4_ERR ; Yes, so that's an error

	 cmp	 AMRS_TAB[si-1],@AMRS_INUSE ; Izit in use?
	 jne	 short EMM_ALTMAPREG4_ERR ; No, so that's an error

	 mov	 AMRS_TAB[si-1],@AMRS_FREE ; Mark as available

	 jmp	 short EMM_ALTMAPREG4_EXIT ; Join common exit code

EMM_ALTMAPREG4_EMU:
	 and	 EMM_FLAG,not @EMM_SET28 ; Clear the flag
	 mov	 LCL28_VEC.VOFF,0 ; Zero the saved ES:DI
	 mov	 LCL28_VEC.VSEG,0
EMM_ALTMAPREG4_EXIT:
	 jmp	 EMM_E00AL	; Join common OK code

EMM_ALTMAPREG4_ERR:
	 cmp	 MRS_MAX,0	; Check on our support
	 je	 near ptr EMM_E9C ; Call it unsupported

	 jmp	 EMM_E9D	; Call it out of range

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALTMAPREG4 endp		; End EMM_ALTMAPREG4 procedure
	 NPPROC  EMM_ALTMAPREG5 -- DMA Register Set Allocate
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 28, AH = 5B05h

DMA register set allocate

Return BL = 0

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 [ebp].INTXX_EBX.ELO,0 ; Return BL = 0

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALTMAPREG5 endp		; End EMM_ALTMAPREG5 procedure
	 NPPROC  EMM_ALTMAPREG6 -- Enable DMA on Alternate Register Set
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 28, AH = 5B06h

Enable DMA on alternate register set

Error return 9C if BL <> 0

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 [ebp].INTXX_EBX.ELO,0 ; See if BL = 0
	 jne	 near ptr EMM_E9C ; It's not, so that's an error

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALTMAPREG6 endp		; End EMM_ALTMAPREG6 procedure
	 NPPROC  EMM_ALTMAPREG7 -- Disable DMA on Alternate Register Set
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 28, AH = 5B07h

Disable DMA on alternate register set

Error return 9C if BL <> 0

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 [ebp].INTXX_EBX.ELO,0 ; See if BL = 0
	 jne	 near ptr EMM_E9C ; It's not, so that's an error

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALTMAPREG7 endp		; End EMM_ALTMAPREG7 procedure
	 NPPROC  EMM_ALTMAPREG8 --  DMA Register Set Deallocate
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 28, AH = 5B08h

DMA register set deallocate

Error return 9C if BL <> 0

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 [ebp].INTXX_EBX.ELO,0 ; See if BL = 0
	 jne	 near ptr EMM_E9C ; It's not, so that's an error

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_ALTMAPREG8 endp		; End EMM_ALTMAPREG8 procedure
	 NPPROC  EMM_OSE -- Operating System Environment Functions
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 30, AH = 5Dh

Enable/disable Operating System Environment function

Error return 8F if subfunction parameter invalid
	     A4 if access key in use and (BX,CX) = invalid access key

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,OSE_CNT	; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 test	 EMM_FLAG,@EMM_INUSE ; Key already in use?
	 jz	 short EMM_OSESUB ; No, continue on

	 cmp	 cx,ACCKEY.EHI	; Same CX key as before?
	 jne	 near ptr EMM_EA4 ; No, so that's an error

	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get the other part from BX

	 cmp	 bx,ACCKEY.ELO	; Same BX key as before?
	 jne	 near ptr EMM_EA4 ; No, so that's an error
EMM_OSESUB:
	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 OSE_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_OSE  endp			; End EMM_OSE procedure
	 NPPROC  EMM_OSE0 -- Enable OSE Functions
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 30, AX = 5D00h

Enable the OS/E functions (that is, remove the restriction)

Mark as unrestricted.

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 and	 EMM_FLAG,not @EMM_NOSE ; Mark as unrestricted

	 call	 NEW_ACCKEY	; See if we should generate a new access key

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_OSE0 endp			; End EMM_OSE0 procedure
	 NPPROC  EMM_OSE1 -- Disable OSE Functions
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 30, AX = 5D01h

Disable the OS/E functions (that is, impose the restriction)

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 or	 EMM_FLAG,@EMM_NOSE ; Mark as restricted

	 call	 NEW_ACCKEY	; See if we should generate a new access key

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_OSE1 endp			; End EMM_OSE1 procedure
	 NPPROC  EMM_OSE2 -- Return Access Key
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 30, AX = 5D02h

Return the access key to us, enable OS/E functions,
The next call to NEW_ACCKEY returns a new key.

Error return A4 if no key is in use

All registers except EBP, SS, and ESP may be destroyed.

|

	 test	 EMM_FLAG,@EMM_INUSE ; Key already in use?
	 jz	 near ptr EMM_EA4 ; No, so that's an error

; Mark as unrestricted and no longer in use

	 and	 EMM_FLAG,not (@EMM_NOSE or @EMM_INUSE)

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_OSE2 endp			; End EMM_OSE2 procedure
	 NPPROC  NEW_ACCKEY -- Check on New Access Key
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we should generate a new access key.

|

	 test	 EMM_FLAG,@EMM_INUSE ; Key already in use?
	 jnz	 short NEW_ACCKEY_EXIT ; Yes, so we do nothing more

	 call	 CALC_ACCKEY	; Calculate the new access key

	 push	 ax		; Save for a moment

	 mov	 ax,ACCKEY.ELO	; Get the new key, low-order
	 mov	 [ebp].INTXX_EBX.ELO,ax ; Return in BX

	 mov	 ax,ACCKEY.EHI	; Get the new key, high-order
	 mov	 [ebp].INTXX_ECX.ELO,ax ; Return in CX

	 pop	 ax		; Restore

	 or	 EMM_FLAG,@EMM_INUSE ; Mark as in use
NEW_ACCKEY_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NEW_ACCKEY endp 		; End NEW_ACCKEY procedure
	 NPPROC  CALC_ACCKEY -- Calculate New Access Key
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the new access key and return it in ACCKEY.

|

	 REGSAVE <eax,ebx,ecx,esi> ; Save registers
	 REGSAVE <ds>

	 push	 DTE_D4GB	; Get data selector for all memory as data
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 ecx,CON64KB	; Initialize 32-bit count register to sum
				; 256KB (= 64KB dwords) of data

	 xor	 ebx,ebx	; Initialize 32-bit accumulator to zero
	 xor	 esi,esi	; Initialize 32-bit offset to zero
CALC_ACCKEY1:
	 lods	 AGROUP:[esi].EDD ; Get next dword

	 add	 ebx,eax	; Add into accumulator

	 loop	 CALC_ACCKEY1.EDD ; Jump if more dwords to sum

	 REGREST <ds>		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ACCKEY,ebx	; Save for later use

	 REGREST <esi,ecx,ebx,eax>  ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_ACCKEY endp		; End CALC_ACCKEY procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment
endif				; IF @OEM_EMS

	 MEND			; End QMAX_OSE module

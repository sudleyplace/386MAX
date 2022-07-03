;' $Header:   P:/PVCS/MAX/386MAX/QMAX_EM4.ASV   1.4   08 Jul 1998 12:04:40   BOB  $
	 title	 QMAX_EM4 -- 386MAX INT 67h Handler, EMM 4.0 Functions
	 page	 58,122
	 name	 QMAX_EM4

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
	 include CPUFLAGS.INC
	 include ALLMEM.INC

	 include QMAX_DTE.INC
	 include QMAX_OEM.INC	; For VCPI
.list

if @OEM_EMS
PGROUP	 group	 CODE,ECODE,EDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 PGMAPRET:far

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC

	 include QMAX_EMM.INC

	 extrn	 HIMEM_CS:word
	 extrn	 PHNDLCNT:dword
	 extrn	 PHNDLNAME:dword
	 extrn	 NPHYS16S:byte
	 extrn	 PPHYS2SEG:dword
	 extrn	 PSEG2PHYS:dword
	 extrn	 EHNDLCNT:word
	 extrn	 @MAX_EHNDLCNT:abs
	 extrn	 @RPN_UNMAP:abs
	 extrn	 PPL0STK_MIN:dword
	 extrn	 PPL0STK_MAP:dword
	 extrn	 @PPL0STK_INT:abs

	 extrn	 PRPNCUR:dword
	 extrn	 PHNDLPAGE:dword
	 extrn	 PPAGELINK:dword
	 extrn	 HP_LAST:dword
	 extrn	 TOTPGCNT:word
	 extrn	 REMPGCNT:word

	 public  GETSETATTR_FNS
GETSETATTR_FNS label word
	 dw	 PGROUP:EMM_GETSETATTR0
	 dw	 PGROUP:EMM_GETSETATTR1
	 dw	 PGROUP:EMM_GETSETATTR2
GETSETATTR_CNT equ ($-GETSETATTR_FNS)/2


	 public  GETSETNAME_FNS
GETSETNAME_FNS label word
	 dw	 PGROUP:EMM_GETSETNAME0
	 dw	 PGROUP:EMM_GETSETNAME1
GETSETNAME_CNT equ ($-GETSETNAME_FNS)/2


	 public  GETHDIR_FNS
GETHDIR_FNS label word
	 dw	 PGROUP:EMM_GETHDIR0
	 dw	 PGROUP:EMM_GETHDIR1
	 dw	 PGROUP:EMM_GETHDIR2
GETHDIR_CNT equ  ($-GETHDIR_FNS)/2


	 public  GETPHYS_FNS
GETPHYS_FNS label word
	 dw	 PGROUP:EMM_GETPHYS0
	 dw	 PGROUP:EMM_GETPHYS1
GETPHYS_CNT equ  ($-GETPHYS_FNS)/2


	 public  RAWALLOC_FNS
RAWALLOC_FNS label word
	 dw	 PGROUP:EMM_RAWALLOC0
	 dw	 PGROUP:EMM_RAWALLOC1
RAWALLOC_CNT equ ($-RAWALLOC_FNS)/2


	 public  GETSETPART_FNS
GETSETPART_FNS label word
	 dw	 PGROUP:EMM_GETSETPART0
	 dw	 PGROUP:EMM_GETSETPART1
	 dw	 PGROUP:EMM_GETSETPART2
GETSETPART_CNT equ ($-GETSETPART_FNS)/2


	 public  MULPGMAP_FNS
MULPGMAP_FNS label word
	 dw	 PGROUP:EMM_MULPGMAP0
	 dw	 PGROUP:EMM_MULPGMAP1
MULPGMAP_CNT equ ($-MULPGMAP_FNS)/2


	 public  PGMAPJMP_FNS
PGMAPJMP_FNS label word
	 dw	 PGROUP:EMM_PGMAPJMP0
	 dw	 PGROUP:EMM_PGMAPJMP1
PGMAPJMP_CNT equ ($-PGMAPJMP_FNS)/2


	 public  PGMAPCALL_FNS
PGMAPCALL_FNS label word
	 dw	 PGROUP:EMM_PGMAPCALL0
	 dw	 PGROUP:EMM_PGMAPCALL1
	 dw	 PGROUP:EMM_PGMAPCALL2
PGMAPCALL_CNT equ ($-PGMAPCALL_FNS)/2


EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_EM4_ECODE
@QMAX_EM4_ECODE:		; Mark module start in .MAP file

	 extrn	 EMM_E00:near
	 extrn	 EMM_E00AL:near
	 extrn	 EMM_E80:near
	 extrn	 EMM_E83:near
	 extrn	 EMM_E87:near
	 extrn	 EMM_E88:near
	 extrn	 EMM_E8B:near
	 extrn	 EMM_E8F:near
	 extrn	 EMM_E91:near
	 extrn	 EMM_EA0:near
	 extrn	 EMM_EA1:near
	 extrn	 EMM_EA3:near
	 extrn	 EMM_ERR:near

	 extrn	 VALID_HNDL:near
	 extrn	 EMM_ALLOC_ZERO:near
	 extrn	 PL3DSSI:near
	 extrn	 PL3ESDI:near
	 extrn	 PGMAP_COM:near
	 extrn	 RPNMAP_COM:near
	 extrn	 PL3STK_DS:near
	 extrn	 ACTIVE_PAGES:near
;;;;;;;; extrn	 PURGE_HFRMSAV:near
;;;;;;;; extrn	 WRAP_DISABLE:near
	 extrn	 SWAP_H0PAGES:near
	 extrn	 ALLOCEMS:near
	 extrn	 DEALLOCEMS:near

	 NPPROC  EMM_GETSETPART -- Get/Set Partial RPNs
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 16, AH = 4Fh

Get/set partial RPNs

Error return 8F if subfunction parameter invalid

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,GETSETPART_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 GETSETPART_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETPART endp		; End EMM_GETSETPART procedure
	 NPPROC  EMM_GETSETPART0 -- Get Partial RPNs
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 16, AX = 4F00h

Store partial RPNs as specified by structure at DS:SI into ES:DI.

All registers except EBP, SS, and ESP may be destroyed.

Error return 8B if a specified segment not mappable
	     A3 if partial page map structure invalid

|

GETSETPART_STR struc

GETSETPART_PPN db ?		; Physical page #
GETSETPART_RPN dw ?		; Relative page #

GETSETPART_STR ends

	 sti			; Allow interrupts

	 mov	 dx,es		; Save selector of our data segment

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

	 lods	 ds:[esi].ELO	; Get entry count

	 cmp	 ax,NPHYS16S.ELO ; Check against total # mappable pages
	 ja	 near ptr EMM_EA3 ; It's out of range

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 cx,ax		; Copy to count register
S32	 stos	 AGROUP:[edi].ELO ; Save entry count in destination array
	 jcxz	 EMM_GETSETPART0_EXIT ; No segments to map
EMM_GETSETPART0_NEXT:
	 lods	 ds:[esi].ELO	; Get next segment

; Search for this segment in PHYS2SEG

	 REGSAVE <ecx,es>	; Save for a moment

	 mov	 es,dx		; Restore addressibility to our data segment
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 ebx,edi	; Save current offset
	 mov	 edi,PPHYS2SEG	; ES:EDI ==> PHYS2SEG table
	 movzx	 ecx,NPHYS16S.ELO ; Get # physical 16KB pages in the EMS system
   repne scas	 PGROUP:[edi].ELO ; Search for it
	 REGREST <es,ecx>	; Restore
	 assume  es:AGROUP	; Tell the assembler about it
	 jne	 near ptr EMM_E8B ; Not found, so that's an error

	 xchg	 ebx,edi	; Save offset, restore old one

	 sub	 ebx,PPHYS2SEG	; Convert to origin-2
	 shr	 bx,1-0 	; Convert from word index to byte index
	 dec	 bx		; Convert to origin-0
	 mov	 AGROUP:[edi].GETSETPART_PPN,bl ; Save as physical page #

	 mov	 eax,size RPN_STR ; Get size of each RPNCUR entry
	 mul	 bl		; Times PPN to get index into RPNCUR
	 mov	 ebx,eax	; Copy to index register
	 add	 ebx,PRPNCUR	; Plus start of current RPN table

	 cli			; Disallow interrupts

	 mov	 ax,PGROUP:[ebx].RPN_RPN ; Get the matching LPN
	 mov	 AGROUP:[edi].GETSETPART_RPN,ax ; Save as logical page #

	 sti			; Allow interrupts

	 add	 edi,size GETSETPART_STR ; Skip to next entry

	 loop	 EMM_GETSETPART0_NEXT ; Jump if more segments to map

EMM_GETSETPART0_EXIT:
	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETPART0 endp		; End EMM_GETSETPART0 procedure
	 NPPROC  EMM_GETSETPART1 -- Set Partial RPNs
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 16, AX = 4F01h

Set partial RPNs from DS:SI

All registers except EBP, SS, and ESP may be destroyed.

Error return A3 if partial page map structure invalid

Note that we read the data into local storage before
remapping any pages.  That way the user's data area can
reside in a page about to mapped out.

|

	 sti			; Allow interrupts

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

	 lods	 ds:[esi].ELO	; Get entry count

	 and	 ax,ax		; Any entries?
	 jz	 short EMM_GETSETPART1_EXIT ; No pages to restore

	 cmp	 ax,NPHYS16S.ELO ; Check against total # mappable pages
	 ja	 near ptr EMM_EA3 ; It's out of range

	 movzx	 ecx,ax 	; Save for a moment

	 mov	 ah,size GETSETPART_STR ; Size of structure
	 mul	 ah		; Times # physical pages passed in
				; AX = byte size of structure
				; CX = # entries in input structure
	 xchg	 ax,cx		; Copy to count register

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 cx,ax		; Restore to count register for LOOP

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return
;;;;;;;;
;;;;;;;; call	 WRAP_DISABLE	; Disable the 1MB wrap
;;;;;;;;
;;;;;;;; or	 GLB_FLAG,@GLB_XWRP ; Disregard 1MB wrap in subfunctions
EMM_GETSETPART1_NEXT:
	 movzx	 bx,ds:[esi].GETSETPART_PPN ; Get the physical page #
	 mov	 di,bx		; Copy for later use

	 mov	 eax,size RPN_STR ; Get size of each RPNCUR entry
	 mul	 bl		; Times PPN to get index into RPNCUR
	 mov	 ebx,eax	; Copy to index register
	 add	 ebx,PRPNCUR	; Plus start of current RPN table

	 cli			; Disallow interrupts

	 mov	 dx,ds:[esi].GETSETPART_RPN ; Get the relative page #

	 cmp	 dx,PGROUP:[ebx].RPN_RPN ; Compare the RPNs
	 je	 short EMM_GETSETPART1_LOOP ; Same so continue on

	 push	 dx		; Pass the relative 16KB page # (origin-0)
	 push	 di		; Pass the physical 16KB page # (origin-0)
	 call	 RPNMAP_COM	; Call common page map routine
	 jc	 near ptr EMM_EA3 ; Jump if something went wrong

	 mov	 PGROUP:[ebx].RPN_RPN,dx ; Save as new relative page #
EMM_GETSETPART1_LOOP:
	 add	 esi,size GETSETPART_STR ; Skip to next entry

	 sti			; Allow interrupts

	 loop	 EMM_GETSETPART1_NEXT ; Jump if more entries to restore
EMM_GETSETPART1_EXIT:

; Note that @GLB_XWRP is cleared, WRAP_ENABLE is called at EMM_EXIT,
; and the stack is cut back to EBP.

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETPART1 endp		; End EMM_GETSETPART1 procedure
	 NPPROC  EMM_GETSETPART2 -- Get Partial RPNs Size
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 16, AX = 4F02h

Get partial RPNs size for BX physical pages

All registers except EBP, SS, and ESP may be destroyed.

Error return 8B if BX > # physical pages in system

|

	 sti			; Allow interrupts

	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get # physical pages passed in

	 cmp	 ax,NPHYS16S.ELO ; Check against # 16KB pages in EMS system
	 ja	 near ptr EMM_E8B ; It's too big

	 mov	 ah,size GETSETPART_STR ; Size of structure
	 mul	 ah		; Times # physical pages passed in
	 add	 al,2		; Plus two for count word

	 jmp	 EMM_E00	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETPART2 endp		; End EMM_GETSETPART2 procedure
	 NPPROC  EMM_MULPGMAP -- Map/Unmap Multiple HPs
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 17, AH = 50h

Map/unmap multiple logical handle-pages to either physical page or segment #s.

Error return 8F if subfunction parameter invalid

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,MULPGMAP_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 MULPGMAP_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_MULPGMAP endp		; End EMM_MULPGMAP procedure
	 NPPROC  MULPGMAP_PPN -- Map/Unmap Logical Pages To Physical Pages
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Map/unmap multiple logical handle-pages to physical page #s.

On entry:

CX	 =	 # entries to map/unmap
DX	 =	 handle
DS:ESI	 ==>	 MULPGMAP0_STR in local storage

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise with error code in AH

All registers except EBP, SS, and ESP may be destroyed.

|

MULPGMAP0_STR struc

MULPGMAP0_LPN dw ?		; Logical  page #
MULPGMAP0_PPN dw ?		; Physical page #

MULPGMAP0_STR ends

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return
;;;;;;;;
;;;;;;;; call	 WRAP_DISABLE	; Disable the 1MB wrap
;;;;;;;;
;;;;;;;; or	 GLB_FLAG,@GLB_XWRP ; Disregard 1MB wrap in subfunctions
MULPGMAP_PPN_NEXT:
	 mov	 ax,ds:[esi].MULPGMAP0_PPN ; Get the physical page #

	 cmp	 ax,NPHYS16S.ELO ; Check # physical 16KB pages in EMS system
	 jae	 short MULPGMAP_PPN8B ; Too big for us

	 cli			; Disallow interrupts

	 push	 dx		; Pass the handle
	 push	 ds:[esi].MULPGMAP0_LPN ; Pass the logical 16KB page # (origin-0)
	 push	 ax		; Pass the physical 16KB page # (origin-0)
	 call	 PGMAP_COM	; Call common page map routine
	 jc	 short MULPGMAP_PPN8A ; Jump if logical page # not found
				; Return with AX = RPN
	 mov	 bx,ax		; Copy to use AX

; Keep the RPNCUR up-to-date

	 mov	 eax,size RPN_STR ; Get size of structure
	 mul	 ds:[esi].MULPGMAP0_PPN.LO ; Times the physical 16KB page # (origin-0)
	 mov	 edi,eax	; Copy to index register
	 add	 edi,PRPNCUR	; Plus start of current RPN table

	 mov	 PGROUP:[edi].RPN_RPN,bx ; Save in structure

	 sti			; Allow interrupts

	 add	 esi,size MULPGMAP0_STR ; Skip to next input entry

	 loop	 MULPGMAP_PPN_NEXT ; Jump if more entries to map/unmap

	 clc			; Indicate all went well

	 jmp	 short MULPGMAP_PPN_EXIT ; Join common exit code

MULPGMAP_PPN8A:
	 mov	 ah,8Ah 	; Return error code

	 jmp	 short MULPGMAP_PPN_ERR ; Join common error code

MULPGMAP_PPN8B:
	 mov	 ah,8Bh 	; Return error code
MULPGMAP_PPN_ERR:
	 stc			; Indicate something went wrong
MULPGMAP_PPN_EXIT:

; Note that @GLB_XWRP is cleared and WRAP_ENABLE is called at EMM_EXIT

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MULPGMAP_PPN endp		; End MULPGMAP_PPN procedure
	 NPPROC  EMM_MULPGMAP0 -- Map/Unmap Logical Page To Physical Page
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 17, AX = 5000h

Map/unmap multiple logical handle-pages to physical page #s.

Error return 83 if DX not valid handle
	     8A if logical-page  >= # 16KB pages allocated to handle DX
	     8B if physical-page >= NPHYS16S or CX >= NPHYS16S
	     A3 if partial page map structure invalid

All registers except EBP, SS, and ESP may be destroyed.

On entry:

CX	 =	 # entries in array
DX	 =	 handle
DS:ESI	 ==>	 logical-to-physical array

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 cmp	 cx,NPHYS16S.ELO ; Check # physical 16KB pages in EMS system
	 ja	 near ptr EMM_E8B ; Jump if out of range

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 mov	 ax,cx		; Copy to restore later

	 shl	 cx,2-0 	; Convert from dwords to bytes
	 jz	 short EMM_MULPGMAP0_EXIT ; No pages to map/unmap

	 movzx	 ecx,cx 	; Zero to use as dword
	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 cx,ax		; Restore entry count for MULPGMAP_PPN

	 call	 MULPGMAP_PPN	; Map multiple logical pages to physical page #s
	 jc	 near ptr EMM_ERR ; Jump if something went wrong; error code in AH
EMM_MULPGMAP0_EXIT:

; Note that the stack is cut back to EBP at EMM_EXIT.

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_MULPGMAP0 endp		; End EMM_MULPGMAP0 procedure
	 NPPROC  MULPGMAP_SEG -- Map/Unmap Logical Page To Segment Number
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Map/unmap multiple logical handle-pages to segment #s.

On entry:

CX	 =	 # entries to map/unmap
DX	 =	 handle
DS:ESI	 ==>	 MULPGMAP1_STR in local storage

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise with error code in AH

All registers except EBP, SS, and ESP may be destroyed.

|

MULPGMAP1_STR struc

MULPGMAP1_LPN dw ?		; Logical page #
MULPGMAP1_SEG dw ?		; Segment #

MULPGMAP1_STR ends

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return
;;;;;;;;
;;;;;;;; call	 WRAP_DISABLE	; Disable the 1MB wrap
;;;;;;;;
;;;;;;;; or	 GLB_FLAG,@GLB_XWRP ; Disregard 1MB wrap in subfunctions
MULPGMAP_SEG_NEXT:
	 mov	 ax,ds:[esi].MULPGMAP1_SEG ; Get the segment #

; Search for this segment in PHYS2SEG

	 push	 ecx		; Save for a moment
	 mov	 edi,PPHYS2SEG	; ES:EDI ==> PHYS2SEG
	 movzx	 ecx,NPHYS16S.ELO ; Get # physical 16KB pages in the EMS system
   repne scas	 PGROUP:[edi].ELO ; Search for it
	 pop	 ecx		; Restore
	 jne	 short MULPGMAP_SEG8B ; Not found

	 sub	 edi,PPHYS2SEG	; Convert to origin-2
	 shr	 di,1-0 	; Convert from word index to byte index
	 dec	 di		; Convert to origin-0 physical page #

	 cli			; Disallow interrupts

	 push	 dx		; Pass the handle
	 push	 ds:[esi].MULPGMAP1_LPN ; Pass the logical 16KB page # (origin-0)
	 push	 di		; Pass the physical 16KB page # (origin-0)
	 call	 PGMAP_COM	; Call common page map routine
	 jc	 short MULPGMAP_SEG8A ; Jump if logical page # not found
				; Return with AX = RPN
	 mov	 bx,ax		; Copy to use AX

; Keep the RPNCUR up-to-date

	 mov	 eax,edi	; Copy physical 16KB page #
	 mov	 ah,size RPN_STR ; Get size of structure
	 mul	 ah		; Times physical 16KB page # (origin-0)
	 mov	 edi,eax	; Copy to index register
	 add	 edi,PRPNCUR	; Plus start of current RPN table

	 mov	 PGROUP:[edi].RPN_RPN,bx ; Save in structure

	 sti			; Allow interrupts

	 add	 esi,size MULPGMAP1_STR ; Skip to next input entry

	 loop	 MULPGMAP_SEG_NEXT ; Jump if more entries to map/unmap

	 clc			; Indicate all went well

	 jmp	 short MULPGMAP_SEG_EXIT ; Join common exit code

MULPGMAP_SEG8A:
	 mov	 ah,8Ah 	; Return error code

	 jmp	 short MULPGMAP_SEG_ERR ; Join common error code

MULPGMAP_SEG8B:
	 mov	 ah,8Bh 	; Return error code
MULPGMAP_SEG_ERR:
	 stc			; Indicate something went wrong
MULPGMAP_SEG_EXIT:

; Note that @GLB_XWRP is cleared and WRAP_ENABLE is called at EMM_EXIT

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MULPGMAP_SEG endp		; End MULPGMAP_SEG procedure
	 NPPROC  EMM_MULPGMAP1 -- Map/Unmap Logical Page To Segment Number
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 17, AX = 5001h

Map/unmap multiple logical handle-pages to segment #s.

Error return 83 if DX not valid handle
	     8A if logical-page > # 16KB pages allocated to handle DX
	     8B if segment # not found or CX >= NPHYS16S
	     A3 if partial page map structure invalid

All registers except EBP, SS, and ESP may be destroyed.

On entry:

CX	 =	 # entries in array
DX	 =	 handle
DS:ESI	 ==>	 logical-to-physical array

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 cmp	 cx,NPHYS16S.ELO ; Check # physical 16KB pages in EMS system
	 ja	 near ptr EMM_E8B ; Jump if out of range

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 mov	 ax,cx		; Copy to restore later

	 shl	 cx,2-0 	; Convert from dwords to bytes
	 jz	 short EMM_MULPGMAP1_EXIT ; No pages to map/unmap

	 movzx	 ecx,cx 	; Zero to use as dword
	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 cx,ax		; Restore entry count for MULPGMAP_SEG

	 call	 MULPGMAP_SEG	; Map multiple logical pages to segment #s
	 jnc	 short EMM_MULPGMAP1_EXIT ; Join common exit code

	 jmp	 EMM_ERR	; Jump if something went wrong; error code in AH

EMM_MULPGMAP1_EXIT:
	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_MULPGMAP1 endp		; End EMM_MULPGMAP1 procedure
	 NPPROC  EMM_REALLOC -- Reallocate Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 18, AH = 51h

Reallocate pages

Re-allocate BX 16KB pages to handle DX.
Return in BX the number of pages allocated to this handle
after re-allocation.

Error return 80 if software bug
	     83 if DX not valid handle
	     87 if BX > TOTPGCNT
	     88 if BX > REMPGCNT

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 call	 ACTIVE_PAGES	; Return in AX # active pages for handle DX
;;;;;;;  jc	 near ptr EMM_E80 ; Something went wrong

	 cmp	 ax,[ebp].INTXX_EBX.ELO ; Less requested value
	 jz	 near ptr EMM_E00AL ; Same as before, just exit
	 jb	 short EMM_REALLOC_MORE ; Old value is smaller, allocate more

; We're to free trailing pages

; Remove from HFRMSAV any (handle, LPN) entries with a matching handle

;;;;;;;; mov	 ax,[ebp].INTXX_EBX.ELO ; Remove LPNs >= this value
;;;;;;;; call	 PURGE_HFRMSAV	; Purge the HFRMSAV area

; Skip over the first # logical pages to be retained

	 push	 [ebp].INTXX_EBX.ELO ; Pass the # logical pages to skip
	 push	 dx		; Pass the handle
	 call	 SKIP_LPN	; Skip over the logical pages
	 jc	 near ptr EMM_ERR ; Must be a software bug, error code in AH
				; Return with EBX ==> next logical page offset

; Purge entries from RPNCUR starting at DS:EBX

	 call	 PURGE_RPNCUR	; Purge 'em

; De-allocate the pages, include them in REMPGCNT

	 call	 DEALLOCEMS	; Deallocate 'em starting at DS:EBX

	 jmp	 short EMM_REALLOC_CNT ; Join common handle count code


; We're to allocate more logical pages to this handle

EMM_REALLOC_MORE:
	 xchg	 ax,[ebp].INTXX_EBX.ELO ; Set BX to actual # allocated pages

	 cli			; Disallow interrupts

; Stack has actual # pages, AX has # requested

	 cmp	 ax,TOTPGCNT	; More than we ever had?
	 ja	 near ptr EMM_E87 ; Yes, so that's an error

	 xchg	 ax,[ebp].INTXX_EBX.ELO ; Restore original requested # pages to BX
	 sub	 ax,[ebp].INTXX_EBX.ELO ; Less requested value to get -(# new pages)
	 neg	 ax		; Negate for # new pages

	 cmp	 ax,REMPGCNT	; Enough remaining?
	 ja	 near ptr EMM_E88 ; No, so that's an error

	 sub	 REMPGCNT,ax	; Fewer remaining 16KB pages
	 mov	 bx,ax		; Copy count to more convenient register

; Search through PAGELINK for BX unallocated 16KB pages

; If this is handle zero, first try to get consecutive pages

	 and	 dx,dx		; Izit handle zero?
	 jnz	 short @F	; Jump if not

	 call	 SWAP_H0PAGES	; Swap handle zero pages to start of free chain
@@:
	 call	 ALLOCEMS	; Allocate EMS pages
				; Return with EAX = entry of 1st allocated page
	 jc	 near ptr EMM_E80 ; Jump if software bug

	 sti			; Allow interrupts

	 mov	 esi,eax	; Save for a moment

	 call	 ACTIVE_PAGES	; Return in AX # active pages for handle DX
	 jc	 near ptr EMM_E80 ; Something went wrong

; Skip over the first AX logical pages (to last one)

	 push	 ax		; Pass the # logical pages to skip
	 push	 dx		; Pass the handle
	 call	 SKIP_LPN	; Skip over logical pages
	 jc	 near ptr EMM_ERR ; Must be a software bug, error code in AH
				; Return with EBX ==> next logical page offset

	 xchg	 esi,PGROUP:[ebx].PL_NEXT ; Save address of last 16KB page

	 cmp	 esi,HP_LAST	; We should be pointing to previous last entry
	 jne	 near ptr EMM_E80 ; We're not, so that's a software bug

; Keep the handle-count up-to-date

EMM_REALLOC_CNT:
	 movzx	 esi,dx 	; Copy handle
	 shl	 esi,1		; Times two to index table of words
	 add	 esi,PHNDLCNT	; Plus pointer to handle-count table
	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get requested LPN count
	 mov	 PGROUP:[esi],ax ; Save as new LPN count

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_REALLOC endp		; End EMM_REALLOC procedure
	 NPPROC  PURGE_RPNCUR -- Purge Entries From RPNCUR
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Purge entries from RPNCUR.

On entry:

DS:EBX	 ==>	 first RPN to purge

|

	 REGSAVE <eax,ebx,ecx,edi> ; Save registers

; In case any of the changed RPNs are mapped into a current EMS physical page,
; translate the RPNCUR entries into PTEs and put them into EMS physical pages

PURGE_RPNCUR1:
	 mov	 ebx,PGROUP:[ebx].PL_NEXT ; Get next address

	 cmp	 ebx,HP_LAST	; Izit the end-of-the-line?
	 je	 short PURGE_RPNCUR3 ; Yes

	 mov	 eax,ebx	; Copy to SCASW register
	 sub	 eax,PPAGELINK	; Less start to get RPN
	 mov	 edi,PRPNCUR	; ES:EDI ==> current RPN table
	 movzx	 ecx,NPHYS16S.ELO ; Get # physical 16KB pages in EMS system
PURGE_RPNCUR2:
	 jcxz	 PURGE_RPNCUR1	; Jump if no more physical pages
   repne scas	 PGROUP:[edi].RPN_RPN ;  Search for it
	 jne	 short PURGE_RPNCUR1 ; Jump if not found

	 mov	 PGROUP:[edi-(size RPN_STR)].RPN_RPN,@RPN_UNMAP ; Mark it as unmapped

	 jmp	 short PURGE_RPNCUR2 ; Go around again

PURGE_RPNCUR3:
	 REGREST <edi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PURGE_RPNCUR endp		; End PURGE_RPNCUR procedure
	 NPPROC  EMM_GETSETATTR -- Get/Set Handle Attribute
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 19, AH = 52h

Get/set handle attribute

Error return 8F if subfunction parameter invalid

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,GETSETATTR_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 GETSETATTR_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETATTR endp		; End EMM_GETSETATTR procedure
	 NPPROC  EMM_GETSETATTR0 -- Get Handle Attribute
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 19, AX = 5200h

Get handle attribute:  0 = volatile
		       1 = non-volatile

Error return 83 if DX not valid handle
	     91 if non-volatile attribute not supported

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 mov	 al,0		; Volatile handles only

	 jmp	 EMM_E00	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETATTR0 endp		; End EMM_GETSETATTR0 procedure
	 NPPROC  EMM_GETSETATTR1 -- Set Handle Attribute
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 19, AX = 5201h

Set handle attribute for DX:  0 = volatile
			      1 = non-volatile

Error return 83 if DX not valid handle
	     90 if attribute type undefined
	     91 if non-volatile attribute not supported

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 cmp	 [ebp].INTXX_EBX.ELO.LO,1 ; Check attribute type
	 je	 near ptr EMM_E91 ; Non-volatile handles not supported

	 mov	 ah,90h 	; Attribute type undefined

	 jmp	 EMM_ERR	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETATTR1 endp		; End EMM_GETSETATTR1 procedure
	 NPPROC  EMM_GETSETATTR2 -- Get Handle Attribute Capability
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 19, AX = 5202h

Get handle attribute capability:
  0 = only volatile handles supported
  1 = both volatile and non-volatile handles supported

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 mov	 al,0		; Only volatile handles supported

	 jmp	 EMM_E00	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETATTR2 endp		; End EMM_GETSETATTR2 procedure
	 NPPROC  EMM_GETSETNAME -- Get/Set Handle Name
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 20, AH = 53h

Get/set handle name

Error return 8F if subfunction parameter invalid

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,GETSETNAME_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 GETSETNAME_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETNAME endp		; End EMM_GETSETNAME procedure
	 NPPROC  EMM_GETSETNAME0 -- Get Handle Name
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 20, AX = 5300h

Get handle name for handle DX

Error return 83 if DX not valid handle

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 movzx	 esi,dx 	; Move to index register
	 shl	 esi,3		; Times eight to index table of handle names
	 add	 esi,PHNDLNAME	; DS:ESI ==> this handle's name

; Point to entry in HNDLNAME directory

	 cli			; Disallow interrupts

S32	 movs	 <AGROUP:[edi].EDD,PGROUP:[esi].EDD> ; Move the handle name
S32	 movs	 <AGROUP:[edi].EDD,PGROUP:[esi].EDD> ; ...two dwords worth

	 sti			; Allow interrupts

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETNAME0 endp		; End EMM_GETSETNAME0 procedure
	 NPPROC  EMM_GETSETNAME1 -- Set Handle Name
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 20, AX = 5301h

Set handle name for handle DX

Error return 83 if DX not valid handle
	     A1 if duplicate named handle found

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

	 movzx	 edx,dx 	; Zero to use as dword
	 push	 dx		; Pass excluded handle as argument #1
	 call	 SRCH_HNAME	; Look for the name in DS:ESI except for DX
				; Return with count of matching handles in AX,
				; ...last matching handle in EDX if AX > 0

	 and	 ax,ax		; Did we find any?
	 jnz	 near ptr EMM_EA1 ; Yes, so that's an error

; Point to entry in HNDLNAME directory

	 mov	 edi,edx	; Move to index register
	 shl	 edi,3		; Times eight to index table of handle names
	 add	 edi,PHNDLNAME	; ES:EDI ==> this handle's new name

	 cli			; Disallow interrupts

S32	 movs	 <es:[edi].EDD,ds:[esi].EDD> ; Move the handle name
S32	 movs	 <es:[edi].EDD,ds:[esi].EDD> ; ...(two dwords worth)

	 sti			; Allow interrupts

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETSETNAME1 endp		; End EMM_GETSETNAME1 procedure
	 NPPROC  EMM_GETHDIR -- Handle Directory Functions
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 21, AH = 54h

Get handle directory

Error return 8F if subfunction parameter invalid

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,GETHDIR_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 GETHDIR_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETHDIR endp		; End EMM_GETHDIR procedure
	 NPPROC  EMM_GETHDIR0 -- Store Handle Directory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 21, AX = 5400h

Store handle directory into caller's ES:DI

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 xor	 dx,dx		; Initialize handle to zero
	 mov	 cx,@MAX_EHNDLCNT ; CX = maximum # EMS handles
EMM_GETHDIR0_NEXT:
	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 short EMM_GETHDIR0_LOOP ; Jump if not valid

; The handle in DX is valid, store it in ES:DI followed
; by the 8-byte handle name

	 mov	 ax,dx		; Copy handle #
S32	 stos	 AGROUP:[edi].ELO ; Save handle # in output area

; Point to entry in HNDLNAME directory

	 movzx	 esi,dx 	; Move to index register
	 shl	 esi,3		; Times eight to index table of handle names
	 add	 esi,PHNDLNAME	; DS:ESI ==> this handle's name

	 cli			; Disallow interrupts

S32	 movs	 <AGROUP:[edi].EDD,PGROUP:[esi].EDD> ; Move the handle name
S32	 movs	 <AGROUP:[edi].EDD,PGROUP:[esi].EDD> ; ...two dwords worth

	 sti			; Allow interrupts
EMM_GETHDIR0_LOOP:
	 inc	 dx		; Bump to next handle

	 loop	 EMM_GETHDIR0_NEXT ; Jump if more to check

	 mov	 al,EHNDLCNT.LO ; Return # active EMS handles in AL

	 jmp	 EMM_E00	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETHDIR0 endp		; End EMM_GETHDIR0 procedure
	 NPPROC  EMM_GETHDIR1 -- Search for Handle name
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 21, AX = 5401h

Search for handle name in caller's DS:SI.
Return handle # in DX if exactly one found.
Return 0 in DX otherwise.

Error return A0 if handle name not found
	     A1 if duplicate named handle found
		or if one handle found and name is all zero

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

	 push	 -1		; Pass excluded handle as argument #1
	 call	 SRCH_HNAME	; Look for the name in DS:ESI, no exceptions
				; Return with count of matching handles in AX,
				; ...last matching handle in EDX if AX > 0

	 cmp	 ax,1		; How many did we find?
	 jb	 short EMM_GETHDIR1_ERR0 ; None, so that's an error
	 ja	 short EMM_GETHDIR1_ERR1 ; Too many, so that's an error

; If the found name is all zero, call it an A1h

	 mov	 edi,edx	; Copy handle #
	 shl	 edi,3		; Times eight to index HNDLNAME directory
	 add	 edi,PHNDLNAME	; Plus offset of directory start
				; ES:EDI ==> this handle name

	 mov	 ecx,8/4	; # dwords in handle name
	 xor	 eax,eax	; Look for zero-named handle

	 cli			; Disallow interrupts
    repe scas	 PGROUP:[edi].EDD ; Izit all zero?
	 sti			; Allow interrupts
	 je	 short EMM_GETHDIR1_ERR1 ; Yes, so that's an error

	 mov	 [ebp].INTXX_EDX.ELO,dx ; Return in caller's DX

	 jmp	 EMM_E00AL	; Join common OK code

EMM_GETHDIR1_ERR0:
	 sti			; Allow interrupts

	 mov	 [ebp].INTXX_EDX.ELO,0 ; Zero the returned handle

	 jmp	 EMM_EA0	; Join common error code

EMM_GETHDIR1_ERR1:
	 mov	 [ebp].INTXX_EDX.ELO,0 ; Zero the returned handle

	 jmp	 EMM_EA1	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETHDIR1 endp		; End EMM_GETHDIR1 procedure
	 NPPROC  SRCH_HNAME -- Search For Handle Name
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search for the handle name at DS:ESI in the handle directory
excluding the handle passed on the stack.

On entry:

DS:ESI	 ==>	 8-byte handle name to search for

On exit:

AX	 =	 # matching names
EDX	 =	 handle # of last matching name (only if AX > 0)

|

SRCH_HNAME_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
SRCH_HNAME_EXCL dw ?		; Excluded handle

SRCH_HNAME_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <cx,edi>	; Save registers

	 pushf			; Save flags

	 cli			; Disallow interrupts

	 mov	 edi,PHNDLNAME	; ES:EDI ==> HNDLNAME directory
	 mov	 cx,@MAX_EHNDLCNT ; CX = maximum # EMS handles
	 xor	 ax,ax		; Initialize # matches found
SRCH_HNAME_NEXT:
	 REGSAVE <ecx,esi,edi>	; Save for a moment

	 mov	 ecx,8/4	; # dwords in handle name
    repe cmps	 ds:[esi].EDD,es:[edi].EDD ; Compare 'em
	 REGREST <edi,esi,ecx>	; Restore
	 jne	 short SRCH_HNAME_LOOP ; No match, try again

	 mov	 edx,edi	; Copy handle name offset
	 sub	 edx,PHNDLNAME	; Less offset of directory start
	 shr	 edx,3		; Divide by eight to get handle #

	 cmp	 dx,[ebp].SRCH_HNAME_EXCL ; Does it match the one to exclude?
	 je	 short SRCH_HNAME_LOOP ; Yes, skip it

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 short SRCH_HNAME_LOOP ; Jump if not valid

	 inc	 ax		; Count in another one
SRCH_HNAME_LOOP:
	 add	 di,8		; Skip to next handle name

	 loop	 SRCH_HNAME_NEXT ; Go around again

	 popf			; Restore flags

	 REGREST <edi,cx>	; Restore

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH_HNAME endp 		; End SRCH_HNAME procedure
	 NPPROC  EMM_GETHDIR2 -- Get Total Supported Handles
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 21, AX = 5402h

Get total # handles which we support

Return value in BX

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|
	 sti			; Allow interrupts

	 mov	 [ebp].INTXX_EBX.ELO,@MAX_EHNDLCNT ; Return max # EMS handles in BX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETHDIR2 endp		; End EMM_GETHDIR2 procedure
	 NPPROC  EMM_PGMAPJMP -- Alter Page Map and Far Jump
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 22, AH = 55h

Alter page map and far jump

All registers except EBP, SS, and ESP may be destroyed.

Error return 8F if subfunction parameter invalid

|

	 cmp	 al,PGMAPJMP_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 PGMAPJMP_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGMAPJMP endp		; End EMM_PGMAPJMP procedure
	 NPPROC  EMM_PGMAPJMP0 -- Alter Page Map and Far Jump (Physical Pages)
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 22, AX = 5500h

Alter page map and far jump (physical pages)

DX	 =	 handle
DS:SI	 ==>	 PGMAPJMP0_STR

Error return 83 if DX not valid handle
	     8A if logical-page  >= # 16KB pages allocated to handle DX
	     8B if physical-page >= NPHYS16S

All registers except EBP, SS, and ESP may be destroyed.

|

PGMAPJMP0_STR struc

PGMAPJMP0_FJMP dd ?		; Far jump address
PGMAPJMP0_CNT  db ?		; # pages to map
PGMAPJMP0_PTR  dd ?		; Far pointer to MULPGMAP0_STR structure

PGMAPJMP0_STR ends

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

; Save caller's far jump target in case
; the call to MULPGMAP_PPN below maps that segment out.

	 push	 ds:[esi].PGMAPJMP0_FJMP ; Save new segment:offset

; Convert PGMAPJMP0_PTR to local DS:ESI

	 movzx	 ecx,ds:[esi].PGMAPJMP0_CNT ; Get entry count
	 movzx	 eax,ds:[esi].PGMAPJMP0_PTR.VSEG ; Get caller's data segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,ds:[esi].PGMAPJMP0_PTR.VOFF ; Get caller's data offset
	 add	 esi,eax	; DS:ESI ==> PGMAPJMP0_PTR

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 mov	 ax,cx		; Copy to restore later

	 shl	 ecx,2-0	; Convert from dwords to bytes
	 jz	 short EMM_PGMAPJMP0_EXIT ; No pages to map/unmap

	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 ecx		; Save byte count over MULPGMAP_PPN

	 mov	 cx,ax		; Restore entry count for MULPGMAP_PPN

	 call	 MULPGMAP_PPN	; Map multiple logical pages to physical page #s
	 pop	 ecx		; Restore
	 jc	 near ptr EMM_ERR ; Jump if something went wrong; error code in AH

	 cli			; Disallow interrupts

	 add	 [ebp].INTXX_ESP.ELO,3*2 ; Strip off CS:IP, FL from RESINT67

; Remove input data from the stack -- data at DS:ESI may be destroyed

	 add	 esp,ecx	; Strip back the stack

; As there's been no error, we can store the
; far jump target in caller's CS:IP

	 pop	 [ebp].INTXX_EIP.ELO ; Save as return offset
	 pop	 [ebp].INTXX_CS  ; Save as return segment

	 test	 DBG_FLAG,@DBG_JMP ; Signal NMI upon exit?
	 jz	 short EMM_PGMAPJMP0_EXIT ; Not this time

	 or	 GLB_FLAG,@GLB_NMI ; Signal NMI
EMM_PGMAPJMP0_EXIT:

; Note that the stack is cut back to EBP at EMM_EXIT.

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGMAPJMP0 endp		; End EMM_PGMAPJMP0 procedure
	 NPPROC  EMM_PGMAPJMP1 -- Alter Page Map and Far Jump (Segment Numbers)
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 22, AX = 5501h

Alter page map and far jump (segment numbers)

DX	 =	 handle
DS:SI	 ==>	 PGMAPJMP1_STR

Error return 83 if DX not valid handle
	     8A if logical-page  >= # 16KB pages allocated to handle DX
	     8B if physical-page >= NPHYS16S

All registers except EBP, SS, and ESP may be destroyed.

|

PGMAPJMP1_STR struc

PGMAPJMP1_FJMP dd ?		; Far jump address
PGMAPJMP1_CNT  db ?		; # pages to map
PGMAPJMP1_PTR  dd ?		; Far pointer to MULPGMAP1_STR structure

PGMAPJMP1_STR ends

	 sti			; Allow interrupts

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

; Save caller's far jump target in case
; the call to MULPGMAP_SEG below maps that segment out.

	 push	 ds:[esi].PGMAPJMP1_FJMP ; Save new segment:offset

; Convert PGMAPJMP1_PTR to DTE_D4GB:ESI

	 movzx	 ecx,ds:[esi].PGMAPJMP1_CNT ; Get entry count
	 movzx	 eax,ds:[esi].PGMAPJMP1_PTR.VSEG ; Get caller's data segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,ds:[esi].PGMAPJMP1_PTR.VOFF ; Get caller's data offset
	 add	 esi,eax	; DS:ESI ==> PGMAPJMP1_PTR

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 mov	 ax,cx		; Copy to restore later

	 shl	 ecx,2-0	; Convert from dwords to bytes
	 jz	 short EMM_PGMAPJMP1_EXIT ; No pages to map/unmap

	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 ecx		; Save byte count over MULPGMAP_SEG

	 mov	 cx,ax		; Restore entry count for MULPGMAP_SEG

	 call	 MULPGMAP_SEG	; Map multiple logical pages to segment #s
	 pop	 ecx		; Restore
	 jc	 near ptr EMM_ERR ; Jump if something went wrong; error code in AH

	 cli			; Disallow interrupts

	 add	 [ebp].INTXX_ESP.ELO,3*2 ; Strip off CS:IP, FL from RESINT67

; Remove input data from the stack -- data at DS:ESI may be destroyed

	 add	 esp,ecx	; Strip back the stack

; As there's been no error, we can store the
; far jump target in caller's CS:IP

	 pop	 [ebp].INTXX_EIP.ELO ; Save as return offset
	 pop	 [ebp].INTXX_CS  ; Save as return segment

	 test	 DBG_FLAG,@DBG_JMP ; Signal NMI upon exit?
	 jz	 short EMM_PGMAPJMP1_EXIT ; Not this time

	 or	 GLB_FLAG,@GLB_NMI ; Signal NMI
EMM_PGMAPJMP1_EXIT:

; Note that the stack is cut back to EBP at EMM_EXIT.

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGMAPJMP1 endp		; End EMM_PGMAPJMP1 procedure
	 NPPROC  EMM_PGMAPCALL -- Alter Page Map and Far Call
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 23, AH = 56h

Alter page map and far call

All registers except EBP, SS, and ESP may be destroyed.

Error return 8F if subfunction parameter invalid

|

	 cmp	 al,PGMAPCALL_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 PGMAPCALL_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGMAPCALL endp		; End EMM_PGMAPCALL procedure
	 NPPROC  EMM_PGMAPCALL0 -- Alter Page Map and Far Call (Physical Pages)
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 23, AX = 5600h

Alter page map and far call (physical pages)

DX	 =	 handle
DS:SI	 ==>	 PGMAPCALL_STR

Error return 83 if DX not valid handle
	     8A if logical-page  >= # 16KB pages allocated to handle DX
	     8B if physical-page >= NPHYS16S

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 ax,0		; Code for physical page #s
	 lea	 bx,MULPGMAP_PPN ; Map multiple logical pages to physical page #s

	 jmp	 short EMM_PGMAPCALL_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGMAPCALL0 endp		; End EMM_PGMAPCALL0 procedure
	 NPPROC  EMM_PGMAPCALL1 -- Alter Page Map and Far Call (Segment Numbers)
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 23, AX = 5601h

Alter page map and far call (segment numbers)

DX	 =	 handle
DS:SI	 ==>	 PGMAPCALL_STR

Error return 83 if DX not valid handle
	     8A if logical-page  >= # 16KB pages allocated to handle DX
	     8B if physical-page >= NPHYS16S

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 ax,1		; Code for segment #s
	 lea	 bx,MULPGMAP_SEG ; Map multiple logical pages to segment #s

;;;;;;;; jmp	 short EMM_PGMAPCALL_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGMAPCALL1 endp		; End EMM_PGMAPCALL1 procedure
	 NPPROC  EMM_PGMAPCALL_COM -- Common Routine to EMM_PGMAPCALLx
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common routine for EMM_PGMAPCALL0 and EMM_PGMAPCALL1

On entry:

AX	 =	 0 for physical page #s
	 =	 1 for segment #s
CS:BX	 =	 address of MULGPMAP_xxx routine

|

PGMAPCALL_STR struc

PGMAPCALL_FCALL  dd ?		; Far call address
PGMAPCALL_NEWCNT db ?		; # new pages to map
PGMAPCALL_NEWPTR dd ?		; Far pointer to new MULPGMAP0_STR
PGMAPCALL_OLDCNT db ?		; # old pages to map
PGMAPCALL_OLDPTR dd ?		; Far pointer to old MULPGMAP0_STR
PGMAPCALL_RSVD dw 4 dup (?)	; Reserved

PGMAPCALL_STR ends


; The stack bottom is filled with the following structure

STKBOT_STR struc

STKBOT_SEGPHYS	dw ?		; 0 = physical page #s
				; 1 = segment #s
STKBOT_HNDL	dw ?		; EMS handle
STKBOT_OLDCNT	dw ?		; PGMAPCALL_OLDCNT
STKBOT_VALUES	dd 1 dup (?)	; Contents of PGMAPCALL_OLDPTR
;;;;;;_BACKPTR	dd ?		; Back pointer to start of STKBOT_STR

STKBOT_STR ends

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

	 push	 ds:[esi].PGMAPCALL_FCALL ; Save far call address

; Copy certain values at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

; Save code indicating whether this is a physical page # or segment # mapping

	 mov	 edi,PPL0STK_MAP ; Get next offset at bottom of stack
S32	 stos	 es:[edi].ELO	; Save on stack

; Save the caller's EMS handle

	 mov	 ax,dx		; Copy the handle
S32	 stos	 es:[edi].ELO	; Save on stack

; Save the # pages in PGMAPCALL_OLDPTR

	 movzx	 ecx,ds:[esi].PGMAPCALL_OLDCNT ; Get count of OLDPTR
	 mov	 ax,cx		; Copy to save
S32	 stos	 es:[edi].ELO	; Save on stack

; Save the contents of PGMAPCALL_OLDPTR

	 push	 esi		; Save for a moment

	 movzx	 eax,ds:[esi].PGMAPCALL_OLDPTR.VSEG ; Get the segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,ds:[esi].PGMAPCALL_OLDPTR.VOFF ; Get the offset
	 add	 esi,eax	; DS:ESI ==> contents of PGMAPCALL_OLDPTR
S32  rep movs	 <es:[edi].EDD,ds:[esi].EDD> ; Copy to local storage

	 pop	 esi		; Restore

; Save the back pointer

	 mov	 eax,PPL0STK_MAP ; Get the back pointer
S32	 stos	 es:[edi].EDD	; Save on stack

	 lea	 eax,[edi+@PPL0STK_INT] ; Copy current offset and add in slop for ints
	 mov	 PPL0STK_MIN,eax ; Save as new minimum for hardware interrupts

; Update the stack pointer

	 xchg	 edi,PPL0STK_MAP ; Save as new Map & Call offset, and
				; restore original pointer

	 sti			; Allow interrupts

; Convert PGMAPCALL_NEWPTR to DTE_D4GB:ESI

	 movzx	 cx,ds:[esi].PGMAPCALL_NEWCNT ; Get entry count
	 movzx	 eax,ds:[esi].PGMAPCALL_NEWPTR.VSEG ; Get caller's data segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,ds:[esi].PGMAPCALL_NEWPTR.VOFF ; Get caller's data offset
	 add	 esi,eax	; DS:ESI ==> contents of PGMAPCALL_NEWPTR

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 mov	 ax,cx		; Copy to restore later

	 shl	 ecx,2-0	; Convert from dwords to bytes
	 jz	 short EMM_PGMAPCALL_EXIT ; No pages to map/unmap

	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 REGSAVE <ecx,edi>	; Save over MULPGMAP_xxx

	 mov	 cx,ax		; Restore entry count for MULPGMAP_xxx

	 call	 bx		; Map multiple logical pages to physical/segment #s
	 REGREST <edi,ecx>	; Restore
	 jc	 near ptr EMM_ERR ; Jump if something went wrong; error code in AH

	 cli			; Disallow interrupts

; Remove input data from the stack

	 add	 esp,ecx	; Strip back the stack

; Make room on the stack for the PGMAPCALL_STR and our return address

@PGMAPCALL_FARP equ 4		; Size of one far ptr
@PGMAPCALL_BACK equ 4		; Size of one dword back pointer

; Size of one far pointer plus dword back pointer

@PGMAPCALL_PMSIZE equ @PGMAPCALL_FARP + @PGMAPCALL_BACK
@PGMAPCALL_VMSIZE equ @PGMAPCALL_PMSIZE + 6

	 sub	 [ebp].INTXX_ESP.ELO,@PGMAPCALL_PMSIZE

; Note that by definition, the caller's stack can't be in EMS memory.
; The caller had better ensure it isn't mapped out from conventional memory.

	 call	 PL3STK_DS	; Return with DS:ESI ==> caller's stack
	 assume  ds:nothing	; Tell the assembler about it

; Save address of PGMAPRET on the caller's stack

	 mov	 ds:[esi].VOFF,offset cs:PGMAPRET ; Save return offset on stack
	 mov	 ax,HIMEM_CS	; Get segment of driver in high DOS memory
	 mov	 ds:[esi].VSEG,ax ; Save return segment on stack
	 mov	 ds:[esi+size VECTOR],edi ; Save back pointer

; Save far call address as the return point

	 pop	 eax		; Get new segment:offset

	 mov	 [ebp].INTXX_EIP.ELO,ax ; Save as return offset
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_CS,ax ; Save as return segment

	 test	 DBG_FLAG,@DBG_CALL ; Signal NMI upon exit?
	 jz	 short EMM_PGMAPCALL_EXIT ; Not this time

	 or	 GLB_FLAG,@GLB_NMI ; Signal NMI
EMM_PGMAPCALL_EXIT:

; Note that the stack is cut back to EBP at EMM_EXIT.

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGMAPCALL_COM endp		; End EMM_PGMAPCALL_COM procedure
	 NPPROC  EMM_PGMAPCALL2 -- Alter Page Map and Far Call Stack Size
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 23, AX = 5602h

Alter page map and far call stack size.
Return in BX the stack size needed for CALL0 and CALL1 functions.

No errors possible.

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 mov	 [ebp].INTXX_EBX.ELO,@PGMAPCALL_VMSIZE ; Return in BX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGMAPCALL2 endp		; End EMM_PGMAPCALL2 procedure
	 NPPROC  EMM_PGMAPRET -- Return from PGMAPCALL
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 23, AX = 5600h or 5601h return

Alter page map and far return (physical pages or segment numbers)

SS:ESP	 ==>	 PGMAPCALL?_STR

Error return 83 if DX not valid handle
	     8A if logical-page  >= # 16KB pages allocated to handle DX
	     8B if physical-page >= NPHYS16S

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 call	 PL3STK_DS	; Return with DS:ESI ==> caller's stack
	 assume  ds:nothing	; Tell the assembler about it

; Get pointer to the structure at the bottom of the stack

	 mov	 esi,ds:[esi]	; ES:ESI ==> STKBOT structure

; Strip off back pointer from caller's stack

	 add	 [ebp].INTXX_ESP.ELO,@PGMAPCALL_BACK ; Strip it

	 push	 es		; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

; Ensure proper nesting of structures

	 mov	 edi,PPL0STK_MAP ; DS:EDI ==> top of STKBOT structure

	 cmp	 esi,ds:[edi-(type PPL0STK_MAP)] ; Ensure they're the same
	 mov	 ah,80h 	; Error code
	 jne	 short EMM_PGMAPRET_ERR ; Jump if inconsistent

; Address contents of PGMAPCALL_OLDPTR in DS:ESI

	 mov	 dx,ds:[esi].STKBOT_HNDL ; Get the caller's handle

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 mov	 ah,83h 	; Error code
	 jnc	 short EMM_PGMAPRET_ERR ; It's not, strip off structure and exit

	 mov	 cx,ds:[esi].STKBOT_OLDCNT ; Get the # pages in PGMAPCALL_OLDPTR

	 cmp	 ds:[esi].STKBOT_SEGPHYS,1 ; Check for reasonable
	 mov	 ah,80h 	; Error code
	 ja	 short EMM_PGMAPRET_ERR ; That's a bug (probably user's corrupted struc)
	 push	 esi		; Save offset
	 lea	 esi,ds:[esi].STKBOT_VALUES ; DS:ESI ==> contents of PGMAPCALL_OLDPTR
	 je	 short EMM_PGMAPRET_SEG ; It's to segment #s

	 call	 MULPGMAP_PPN	; Map multiple logical pages to physical page #s
	 pop	 PPL0STK_MAP	; Strip off STKBOT structure
	 jnc	 short EMM_PGMAPRET_EXIT ; Join common exit code

	 jmp	 EMM_ERR	; Jump if something went wrong; error code in AH

EMM_PGMAPRET_SEG:
	 call	 MULPGMAP_SEG	; Map multiple logical pages to segment #s
	 pop	 PPL0STK_MAP	; Strip off STKBOT structure
	 jnc	 short EMM_PGMAPRET_EXIT ; Join common exit code

	 jmp	 EMM_ERR	; Jump if something went wrong; error code in AH

EMM_PGMAPRET_EXIT:
	 mov	 ah,00h 	; Error code
	 mov	 esi,PPL0STK_MAP ; Get offset of current map

	 jmp	 short EMM_PGMAPRET_INT ; Join common code

; Something went wrong
; Strip off the STKBOT structure and exit with
; error code in AH.

EMM_PGMAPRET_ERR:
	 mov	 esi,PPL0STK_MAP ; Get offset of current map
	 mov	 esi,ds:[esi-(type PPL0STK_MAP)] ; Get back pointer
	 mov	 PPL0STK_MAP,esi ; Strip off STKBOT structure
EMM_PGMAPRET_INT:
	 add	 esi,@PPL0STK_INT ; Add in stack space for interrupts
	 mov	 PPL0STK_MIN,esi ; Save as new minimum for hardware interrupts

; Note that the stack is cut back to EBP at EMM_EXIT.

	 jmp	 EMM_ERR	; Jump if something went wrong; error code in AH

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_PGMAPRET endp		; End EMM_PGMAPRET procedure
	 NPPROC  EMM_GETPHYS -- Mappable Physical Page Array Functions
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 25, AH = 58h

Mappable physical page array address functions.

Error return 8F if subfunction parameter invalid

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,GETPHYS_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 GETPHYS_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETPHYS endp		; End EMM_GETPHYS procedure
	 NPPROC  EMM_GETPHYS0 -- Get Mappable Physical Page Array
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 25, AX = 5800h

Get mappable physical page address array.
Store into ES:DI the physical page address array.
Store into CX the mappable physical address array entry count.

No errors possible.

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 cx,NPHYS16S.ELO ; Get # physical 16KB pages in EMS system
	 mov	 [ebp].INTXX_ECX.ELO,cx ; Return in CX

	 mov	 esi,PSEG2PHYS	; DS:ESI ==> segment to physical page table
	 xor	 eax,eax	; Zero to use as word
EMM_GETPHYS0_NEXT:
	 lods	 PGROUP:[esi].LO ; Get next physical page #

	 push	 esi		; Save for a moment

	 mov	 esi,PPHYS2SEG	; DS:ESI ==> physical page to segment table
	 add	 esi,eax	; Add in physical page #
	 add	 esi,eax	; Twice to index table of words
S32	 movs	 <AGROUP:[edi].ELO,PGROUP:[esi].ELO> ; Move the segment #
S32	 stos	 AGROUP:[edi].ELO ; Store the physical page #

	 pop	 esi		; Restore

	 loop	 EMM_GETPHYS0_NEXT ; Jump if more physical pages
EMM_GETPHYS0_EXIT:
	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETPHYS0 endp		; End EMM_GETPHYS0 procedure
	 NPPROC  EMM_GETPHYS1 -- Get Mappable Physical Page Count
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 25, AX = 5801h

Get mappable physical address array entry count.
Store into CX the mappable physical address array entry count.

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 mov	 ax,NPHYS16S.ELO ; Get # physical 16KB pages in EMS system
	 mov	 [ebp].INTXX_ECX.ELO,ax ; Return in CX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_GETPHYS1 endp		; End EMM_GETPHYS1 procedure
	 NPPROC  EMM_RAWALLOC -- Allocate Logical or Raw Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 27, AH = 5Ah

Allocate logical or raw pages

Error return 8F if subfunction parameter invalid

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,RAWALLOC_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 RAWALLOC_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_RAWALLOC endp		; End EMM_RAWALLOC procedure
	 NPPROC  EMM_RAWALLOC0 -- Allocate Logical Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 27, AH = 5A00h

Allocate logical pages, allowing zero page allocation.

Errors as per EMM_ALLOC_ZERO.

|

	 sti			; Allow interrupts

	 jmp	 EMM_ALLOC_ZERO ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_RAWALLOC0 endp		; End EMM_RAWALLOC0 procedure
	 NPPROC  EMM_RAWALLOC1 -- Allocate Raw Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 27, AH = 5A01h

Allocate raw pages, allowing zero page allocation.

Errors as per EMM_ALLOC_ZERO.

|

	 sti			; Allow interrupts

	 jmp	 EMM_ALLOC_ZERO ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_RAWALLOC1 endp		; End EMM_RAWALLOC1 procedure
	 NPPROC  EMM_BOOT -- Prepare For Warm Boot
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM Function 29, AH = 5Ch

Prepare for warm boot.

Re-initialize the EMM data areas.

No errors possible.

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_BOOT endp			; End EMM_BOOT procedure
	 NPPROC  SKIP_LPN -- Skip LPNs
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over the first NLPN logical pages in handle.

On exit:

EBX	 =	 offset from PGROUP:0 of next LPN after skip
CF	 =	 0 if all went well
	 =	 1 otherwise; error code in AH
AH	 =	 error code only if error
	 =	 unchanged otherwise

|

SKIP_LPN_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
SKIP_LPN_HNDL db ?,?		; The handle
SKIP_LPN_NLPN dw ?		; # logical pages to skip

SKIP_LPN_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <cx>		; Save register

	 movzx	 ebx,[ebp].SKIP_LPN_HNDL ; Get the handle
	 shl	 bx,2		; Times four to index table of dwords
	 add	 ebx,PHNDLPAGE	; Plus start of HNDLPAGE table
	 mov	 cx,[ebp].SKIP_LPN_NLPN ; Get the # logical pages to skip

	 jcxz	 SKIP_LPN_OK	; We're at the last one
SKIP_LPN_NEXT:
	 mov	 ebx,PGROUP:[ebx].PL_NEXT ; Get next link

	 cmp	 ebx,HP_LAST	; Last entry?
	 je	 short SKIP_LPN_E80 ; Yes, so that's a software bug

	 loop	 SKIP_LPN_NEXT	; Jump if more pages to skip
SKIP_LPN_OK:
	 clc			; Indicate all went OK

	 jmp	 short SKIP_LPN_EXIT ; Join common exit code

SKIP_LPN_E80:
	 mov	 ah,80h 	; Return error code
	 stc			; Indicate we had a problem
SKIP_LPN_EXIT:
	 REGREST <cx>		; Restore

	 pop	 ebp		; Restore

	 ret	 2*2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_LPN endp			; End SKIP_LPN procedure
	 NPPROC  COPY2LCL -- Copy CX Bytes From DS:ESI to Local Storage
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Copy the CX bytes at DS:ESI to local storage,
and return DS:ESI ==> local storage.

|

COPY2LCL_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		;	   IP
COPY2LCL_ESP dd  ?		; Next stack position

COPY2LCL_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,edi,es>	; Save registers

	 push	 ss		; Use stack selector
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 movzx	 ecx,cx 	; Zero the high-order word

	 lea	 edi,[ebp].COPY2LCL_ESP ; ES:EDI ==> destin offset
S32  rep movs	 <es:[edi].LO,ds:[esi].LO> ; Move to local storage

	 push	 ss		; Return as new DS:ESI
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 esi,[ebp].COPY2LCL_ESP ; DS:ESI ==> local copy

	 REGREST <es,edi,ecx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY2LCL endp			; End COPY2LCL procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment
endif				; IF @OEM_EMS

	 MEND			; End QMAX_EM4 module

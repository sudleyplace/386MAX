;' $Header:   P:/PVCS/MAX/386MAX/QMAX_MAC.ASV   1.3   30 May 1997 10:45:34   BOB  $
	 title	 QMAX_MAC -- 386MAX Memory Allocation Chain
	 page	 58,122
	 name	 QMAX_MAC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Data    segment JDATA, dword-aligned, public, class 'jcode'
	       Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'
	       Data    segment XDATA, dword-aligned, public, class 'xdata'
	       Group YGROUP:
	       Data    segment YDATA, dword-aligned, public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include EMMCALL.INC
	 include ASCII.INC
	 include OPEN.INC
	 include MAC.INC
	 include DTA.INC
	 include 386.INC
	 include PTR.INC
	 include EXE.INC
	 include DEVDRV.INC
	 include INTVEC.INC
	 include ROMSEG.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include ALLMEM.INC

	 include LOAD_SEG.INC
	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
.list

PGROUP	 group	 CODE,ECODE,EDATA,NDATA
JGROUP	 group	 JCODE,JDATA
XGROUP	 group	 XCODE,XDATA
YGROUP	 group	 YDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 RH_VEC:dword
	 extrn	 EMMSIZE:dword
	 extrn	 P1ST_MAC:dword
	 extrn	 POVR_MAC:word
	 extrn	 OLDDOS:word

if @OEM_XMS
	 extrn	 LOADSEG:word
endif				; IF @OEM_XMS

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 MCSTAB:tbyte,MCSTAB_CNT:word
	 include QMAX_MCS.INC

	 extrn	 NPHYS16F:byte
	 extrn	 @RPN_UNMAP:abs
	 extrn	 DOSVER:word

if @OEM_FLEXROM
	 extrn	 FLEXROM_FLAG:word
	 extrn	 FLEXROM_LEN:word
	 extrn	 FLEXROM_TBL:tbyte
	 include QMAX_FLX.INC
endif				; IF @OEM_FLEXROM

	 include QMAX_CPD.INC

if @OEM_XMS
	 extrn	 HIMEM_CS:word
	 extrn	 SEL_4GB3:word
	 extrn	 SEL_DSJG3:word
endif				; IF @OEM_XMS

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

	 extrn	 PBAPPBASE:dword
	 extrn	 MSG_APPLNAME:byte

EDATA	 ends			; End EDATA segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
	 assume  ds:JGROUP

if @OEM_HIFILL
	 extrn	 BFLG_IDX:word
	 extrn	 BFLG_BASE:word
	 extrn	 BFLG_LIM:word
	 extrn	 TEMP_PSP:word
endif				; IF @OEM_HIFILL

	 public  JSEL_DS3
JSEL_DS3  dw	 DTE_DS3   or (@DPMI_CPL shl $PL) ; PGROUP data selector at DPMI CPL

	 public  FILLPAT
FILLPAT dd	 'M683'         ; '386M' filler pattern

JDATA	 ends			; End JDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_MAC_ECODE
@QMAX_MAC_ECODE:		; Mark module start in .MAP file

	 extrn	 KEYWAIT:near

	 FPPROC  FKEYWAIT -- Far Call To KEYWAIT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to KEYWAIT.

|

	 call	 KEYWAIT	; Wait for an acknowledgement
				; Return with key in AX

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FKEYWAIT endp			; End FKEYWAIT procedure

ECODE	 ends			; End ECODE segment

JCODE	 segment use16 dword public 'jcode' ; Start LCODE segment
	 assume  cs:JGROUP

if @OEM_HIFILL
	 extrn	 IZITLSEG:near
	 extrn	 UNLINK_LSEG:near
	 extrn	 IZIT_MACLINK:far
endif				; IF @OEM_HIFILL

if @OEM_HIFILL
	 NPPROC  CHECK_ORPHSUB -- Check on Orphan LSEG Entries at EBX
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Check on orphan LSEG entries in MAC chain starting at AGROUP:EBX.

On entry:
AGROUP:EBX ==>	Start of MAC chain to check (low or high DOS)

|

	 REGSAVE <eax,ebx,edx,esi> ; Save registers

CHECK_ORPHAN_NEXT:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a valid MAC entry?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit a valid MAC entry?
	 jne	 short CHECK_ORPHAN_EXIT ; Jump if not
@@:
	 mov	 eax,ebx	; Copy to convert to PSP segment #
	 shr	 eax,4-0	; Convert from bytes to paras
	 inc	 ax		; Convert from MAC to PSP

	 movzx	 edx,AGROUP:[ebx].MAC_NPAR ; Get # paras in MAC entry
	 inc	 dx		; Account for MAC entry
	 shl	 edx,4-0	; Convert from paras to bytes

	 call	 IZITLSEG	; Is AX an LSEG entry?
	 jnc	 short CHECK_ORPHAN_LOOP ; Jump if not

	 cmp	 AGROUP:[ebx+edx].MAC_OWNR,@MAC_FREE ; Next entry free?
	 je		 short CHECK_ORPHSUB_OWNRFREE ; Jump if so

	 cmp	 AGROUP:[ebx+edx].MAC_OWNR,@MAC_HOLE ; Next entry free but plugged?
	 jne	 short CHECK_ORPHAN_LOOP ; Jump if not

CHECK_ORPHSUB_OWNRFREE:
; If this is 386LOAD in progress, don't free this entry

	 test	 AGROUP:[ebx+(size MAC_STR)].LSEG_FLAG,@LSEG_INPRO ; Izit in progress?
	 jnz	 short CHECK_ORPHAN_LOOP ; Jump if so

; If the next entry doesn't match LSEG_OWNRHI, don't free it.  It may
; be an ExtraDOS LSEG for COMMAND.COM in low DOS (GETSIZE).
	 lea	 eax,[ebx+edx+(size MAC_STR)] ; Get putative PSP
	 shr	 eax,4-0	; Convert bytes to paras

	 cmp	 ax,AGROUP:[ebx+(size MAC_STR)].LSEG_OWNRHI ; Does it match?
	 je		 short CHECK_ORPHSUB_FREE ; Jump if so

; It may also be low, if for example a GETSIZEd TSR frees itself
; (LSL u under BATPROC creates one such rare case).  In this case
; LSEG_INSTLO should match the LSEG itself.  When COMMAND.COM is
; GETSIZEd for ExtraDOS LSEG_INSTLO is always 0.
	 mov	 eax,ebx	; Get MAC address for LSEG
	 shr	 eax,4-0	; Convert bytes to paras
	 inc	 ax			; Get segment of LSEG

	 cmp	 ax,AGROUP:[ebx+(size MAC_STR)].LSEG_INSTLO ; Does it match low?
	 jne	 short CHECK_ORPHAN_LOOP ; Jump if not

; As an additional paranoid step, we'd like to check the back link
; but unfortunately can't count on it being there.
	 dec	 ax			; Back off to MAC
	 cmp	 ax,AGROUP:[ebx+edx].MAC_BACK ; Is it our boy?
	 jne	 short CHECK_ORPHAN_LOOP ; Jump if not

CHECK_ORPHSUB_FREE:
	 lea	 esi,[ebx+(size MAC_STR)] ; AGROUP:ESI ==> LSEG
	 call	 UNLINK_LSEG	; Unlink the LSEG at GS:ESI

	 mov	 AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; Mark LSEG as free
CHECK_ORPHAN_LOOP:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit the last MAC entry?
	 je	 short CHECK_ORPHAN_EXIT ; Jump if so

	 add	 ebx,edx	; Skip to next MAC entry

	 jmp	 CHECK_ORPHAN_NEXT ; Go around again

CHECK_ORPHAN_EXIT:
	 REGREST <esi,edx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ORPHSUB endp		; End CHECK_ORPHSUB procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  MAC_MERGE -- Merge Adjacent Free MACs
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Merge adjacent free MACs starting at POVR_MAC
and check for orphan LSEG entries.

On entry:

GS:0	 ==>	 all memory

On exit:

CF	 =	 0 if all went OK
	 =	 1 if something went wrong

|

	 REGSAVE <ebx>		; Save register

	 movzx	 ebx,POVR_MAC	; Get segment of high DOS memory
	 shl	 ebx,4-0	; Convert from paras to bytes

	 call	 MAC_MERGESUB	; Merge MAC entries starting at 0:EBX
				; CF=1 if MAC error
MAC_MERGE_EXIT:
	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MAC_MERGE endp			; End MAC_MERGE procedure
endif				; IF @OEM_HIFILL
	 NPPROC  MAC_MERGESUB -- MAC Merge Subroutine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Merge adjacent free MACs and MACs marked as @MAC_HOLE.	The latter
are created when a resident UMB is shrunken with other UMBs after
it goes resident.  @MAC_HOLE UMBs are available for reallocation,
but no LSEG will be created.

Whenever a free MAC follows a @MAC_HOLE entry, the two entries will be
merged as a free entry.  Free followed by @MAC_HOLE will not be merged.
Whenever a @MAC_HOLE - @MAC_FREE merge occurs, we need to go through
the process again after adjusting any LSEG entry that happens to cover
the former @MAC_HOLE entry.

Ending @MAC_HOLE entries and @MAC_HOLE entries followed by spanning entries
will also be converted to @MAC_FREE.

On entry:

0:EBX	 ==>	 starting MAC entry

On exit:

CF	 =	 0 if all went OK
	 =	 1 if something went wrong

|

	 REGSAVE <eax,ebx,edx,esi,ds,gs> ; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

; Load segment registers for CHECK_ORPHSUB
	 mov	 ds,JSEL_DS3	; Address PGROUP
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it

MAC_MERGESUB_AGAIN:
	 call	 CHECK_ORPHSUB	; Check on orphan LSEG entries in arena EBX

	 mov	 edx,ebx	; Save start of arena
	 shl	 edx,1		; Create space for "do it again" bit

; The "previous" entry doesn't actually exist but we construct a
; pointer such that the MAC_OWNR offset is non-zero.
; In practice, we use the far jump location in the ROM BIOS

	 mov	 esi,0FFFF3h	; Ensure GS:[ESI].MAC_OWNR is non-zero
MAC_MERGESUB_NEXT:
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 near ptr MAC_MERGESUB_XFREE ; Jump if not

	 cmp	 AGROUP:[esi].MAC_OWNR,@MAC_FREE ; Is the previous entry free?
	 je	 near ptr MAC_MERGESUB_MERGE ; Jump if so (merge)

; Holes followed by free entries will be converted to free and merged.
; The whole idea behind @MAC_HOLE is to catch UMBs that create holes
; or mini-regions by resizing themselves downwards.  If the following
; UMB that bounds the hole is released, there is no need to treat the
; former hole specially.  However, we'll need to first adjust the RPARA
; field of the LSEG covering the @MAC_HOLE entry, since the hole is still
; included.
	 cmp	 AGROUP:[esi].MAC_OWNR,@MAC_HOLE ; Is the previous entry a hole?
	 jne	 near ptr MAC_MERGESUB_CHK ; No, hence no merge

; Walk through LSEG chain looking for an entry below esi that covers it.
; Subtract MAC entry + size from the LSEG_RPARA field.
	 REGSAVE <eax,ebx>	; Save

	 movzx	 ebx,HIMEM_CS	; Get segment of high DOS memory

	 shl	 ebx,4-0	; Convert from paras to bytes
	 assume  gs:PGROUP	; Tell a white lie
	 movzx	 ebx,gs:LOADSEG[ebx] ; Get low memory LOADSEG
	 assume  gs:AGROUP	; Retract nose

MAC_MERGESUB_LSEGNEXT:
	 cmp	 bx,-1		; Izit the end?
	 je	 short MAC_MERGESUB_LSEGEND ; Jump if so

	 shl	 ebx,4-0	; Convert from paras to bytes

	 cmp	 AGROUP:[ebx].LSEG_GRP,@GRPMAX ; Izit 386MAX.SYS?
	 je	 short @F	; Jump if so

	 cmp	 ebx,esi	; Izit below @MAC_HOLE entry?
	 jnb	 short @F	; Jump if not

	 movzx	 eax,AGROUP:[ebx].LSEG_RPARA ; Get resident size of LSEG
	 shl	 eax,4-0	; Convert paras to bytes
	 add	 eax,ebx	; Skip to end of memory covered by this LSEG
	 cmp	 eax,esi	; Does it cover our @MAC_HOLE entry?
	 jna	 short @F	; Jump if not

; Subtract the paras in our MAC entry + 1 para for the MAC entry itself
; from the resident size of the LSEG.
	 mov	 ax,AGROUP:[esi].MAC_NPAR ; Get number of paragraphs
	 inc	 ax		; Add MAC entry
	 sub	 AGROUP:[ebx].LSEG_RPARA,ax ; Subtract from resident size
;;;;;;;  jc	 ???		; This should never happen
	 jmp	 short MAC_MERGESUB_LSEGEND ; We're done

@@:
	 movzx	 ebx,AGROUP:[ebx].LSEG_NEXT ; Get next segment
	 jmp	 short MAC_MERGESUB_LSEGNEXT ; Go around again

MAC_MERGESUB_LSEGEND:
	 REGREST <ebx,eax>	; Restore

	 push	 esi		; Pass address of MAC to free
	 call	 RELEASE_MAC	; Free it

	 or	 dx,1		; We need to run through again
	 jmp	 short MAC_MERGESUB_MERGE ; Join common code to merge entries

MAC_MERGESUB_XFREE:
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_HOLE ; Izit other free?
	 jne	 short MAC_MERGESUB_XHOLE ; Not this time

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit the end of the MAC entries?
	 jne	 short @F	; Jump if not

	 push	 ebx		; Pass address of MAC to free
	 call	 RELEASE_MAC	; Free it

	 or	 dx,1		; We need to run through again
@@:
	 cmp	 AGROUP:[esi].MAC_OWNR,@MAC_HOLE ; Is the previous entry a hole?
	 jne	 short MAC_MERGESUB_CHK ; No, hence no merge

; We don't merge a free entry followed by a hole.

MAC_MERGESUB_MERGE:
; In case the LSEG for this MAC needs to be unlinked, do it now.
	 push	 ebx		; Pass address of MAC to free
	 call	 RELEASE_MAC	; Free it

	 mov	 ax,AGROUP:[ebx].MAC_NPAR ; Get # paragraphs in freed MAC entry
	 inc	 ax		; Account for MAC paragraph
	 add	 AGROUP:[esi].MAC_NPAR,ax ; Merge into previous MAC entry
	 mov	 al,AGROUP:[ebx].MAC_TYPE ; Get the MAC type
	 mov	 AGROUP:[esi].MAC_TYPE,al ; Save as new type

	 jmp	 short MAC_MERGESUB_CHK1 ; Join common code

MAC_MERGESUB_XHOLE:
	 push	 ebx		; Pass linear address
	 FCALL	 IZIT_MACLINK	; Is GS:EBX a MAC linking entry?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_SPAN ; Izit the end of a region?
	 jne	 short MAC_MERGESUB_CHK ; Jump if not
@@:
	 cmp	 AGROUP:[esi].MAC_OWNR,@MAC_HOLE ; Is the previous entry a hole?
	 jne	 short MAC_MERGESUB_CHK ; Jump if not

	 mov	 AGROUP:[esi].MAC_OWNR,@MAC_FREE ; Convert to a free entry
	 or	 dx,1		; We need to run through again

; Save ESI as pointer to previous MAC entry

MAC_MERGESUB_CHK:
	 mov	 esi,ebx	; GS:ESI ==> previous MAC entry
MAC_MERGESUB_CHK1:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit the end of the MAC entries?
	 je	 short MAC_MERGESUB_CLC ; Yes

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Ensure valid
	 jne	 short MAC_MERGESUB_ERRMAC ; Not this time

	 movzx	 eax,AGROUP:[ebx].MAC_NPAR ; Get # paras in this entry
	 inc	 ax		; Count in MAC paragraph
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 ebx,eax	; Skip to the next entry

	 jmp	 MAC_MERGESUB_NEXT ; Go around again

MAC_MERGESUB_ERRMAC:
	 popf			; Restore flags

	 stc			; Indicate something went wrong

	 jmp	 short MAC_MERGESUB_EXIT ; Join common exit code

MAC_MERGESUB_CLC:
	 shr	 edx,1		; Do we need to run through again?
	 jnc	 short @F	; Jump if not

	 mov	 ebx,edx	; Start over again
	 jmp	 MAC_MERGESUB_AGAIN ; Look for more adjacent free entries

@@:
	 popf			; Restore flags

	 clc			; Indicate success
MAC_MERGESUB_EXIT:
	 REGREST <gs,ds,esi,edx,ebx,eax> ; Restore
	 assume  ds:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MAC_MERGESUB endp		; End MAC_MERGESUB procedure
	 NPPROC  RELEASE_MAC -- Free MAC and associated LSEG
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Free MAC entry after checking for an LSEG back link.

|

RMAC_STR struc

	 dw	 ?		; Caller's IP
	 dd	 ?		; Saved EBP
RMAC_ADDR dd	 ?		; Address of MAC to free

RMAC_STR ends

	 push	 ebp		; Prepare to address stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 pushad 		; Save

	 mov	 esi,[ebp].RMAC_ADDR ; Get address of MAC to free
	 mov	 AGROUP:[esi].MAC_OWNR,@MAC_FREE ; Free it

	 mov	 edx,esi	; Get MAC address
	 shr	 edx,4-0	; Convert bytes to paras

	 mov	 ax,AGROUP:[esi].MAC_BACK ; Get LSEG MAC back link
	 inc	 ax		; Skip to start of LSEG
	 call	 IZITLSEG	; Is AX:0 an LSEG entry?
	 jnc	 short RM_EXIT	; Jump if not

; As a further sanity check, make sure the LSEG_OWNRHI field matches.
	 sub	 esi,esi	; Clear high word
	 mov	 si,ax		; Get LSEG para
	 shl	 esi,4-0	; Convert paras to bytes

	 mov	 ax,AGROUP:[esi].LSEG_OWNRHI ; Get segment to match
	 dec	 ax		; Back off to MAC
	 cmp	 ax,dx		; Does it match the segment we're freeing?
	 jne	 short RM_EXIT	; Jump if not - MAC_BACK field is invalid

	 call	 UNLINK_LSEG	; Unlink the LSEG at GS:ESI
	 sub	 esi,size MAC_STR ; Back off to LSEG MAC entry
	 mov	 AGROUP:[esi].MAC_OWNR,@MAC_HOLE ; Free it
RM_EXIT:
	 popad			; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RELEASE_MAC endp		; End RELEASE_MAC procedure
if @OEM_HIFILL
	 NPPROC  LOAD_INPRO -- Check for 386LOAD in progress
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Check the LSEG chain.  If any non-GETSIZE entries have the 386LOAD
in-progress bit set, this means we should let 386LOAD or HARPO worry about
updating LSEGs.  With 386LOAD GETSIZE, we need to know if the program
loads itself high into UMBs.  If so, we'll leave it alone.

On exit:

CF	 =	 1 if 386LOAD in progress
	 =	 0 if not

|

	 REGSAVE <ebx>		; Save register

; Walk through the LSEG chain

	 movzx	 ebx,HIMEM_CS	; Get segment of high DOS memory
	 shl	 ebx,4-0	; Convert from paras to bytes
	 assume  gs:PGROUP	; Tell a white lie
	 movzx	 ebx,gs:LOADSEG[ebx] ; Get low memory LOADSEG
	 assume  gs:AGROUP	; Retract nose
LSINPRO_NEXT:
	 cmp	 bx,-1		; Izit the end?
	 je	 short LSINPRO_EXIT ; Jump if so (note CF=0)

	 shl	 ebx,4-0	; Convert from paras to bytes

	 cmp	 AGROUP:[ebx].LSEG_ASIZE,-1 ; Izit (possibly) 386LOAD GETSIZE?
	 je	 short @F	; Jump if so

	 bt	 AGROUP:[ebx].LSEG_FLAG,$LSEG_INPRO ; Izit owned by 386LOAD?
	 jc	 short LSINPRO_EXIT ; Jump if so (note CF=1)

@@:
	 movzx	 ebx,AGROUP:[ebx].LSEG_NEXT ; Get segment of next entry

	 jmp	 short LSINPRO_NEXT ; Go around again

LSINPRO_EXIT:
	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOAD_INPRO endp 		; End LOAD_INPRO procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 FPPROC  MAC_ALLOC -- Allocate memory block
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Common routine to allocate a memory block (DOS low/high, XMS UMB).

All memory blocks in high DOS have an accompanying LSEG unless they
were carved out of @MAC_HOLE space or 386LOAD is active.

On entry:

AX	 =	 Owner to assign
BX	 =	 Allocation strategy flags (see MAC.INC)
DX	 =	 Number of paragraphs to allocate
DI	 =	 High DOS region to allocate from (origin:1) or
		 -1 if not specified

On exit:

AX	 =	 Segment if successful (CF=0)
AL	 =	 Error code if failed (CF=1):
	 =	 8F if MAC error encountered
	 =	 B0 if a smaller UMB is available
	 =	 B1 if no UMBs are available
	 =	 B2 if entry is not in MAC (free and realloc only)
DX	 =	 Largest block available (in specified region) if failed
	 =	 Size of block allocated if success

|

MALOCAL_STR struc

MALLOC_REG dw	 ?		; Actual region allocated in
MALLOC_LSEG dw	 ?		; Paras needed (if any) for LSEG and MAC para
MALLOC_OWNER dw  ?		; Owner to set
MALLOC_LARGEST dd ?		; Linear address of largest block found
MALLOC_LARGREG dw ?		; Region index of largest block found

MALOCAL_STR ends

@MALLOC_LCLVARS equ (type MALOCAL_STR)

MALLOC_STR struc

	 db	 @MALLOC_LCLVARS dup (?) ; Local variables

	 dw	 ?		; ES on entry
	 dd	 ?		; EBP on entry
MALLOC_EDI dd	 ?		; Region to allocate from
	 dd	 ?		; Saved ESI
MALLOC_EDX dd	 ?		; Largest block size or size of block allocated
	 dw	 ?		; Saved CX
MALLOC_EBX dd	 ?		; Strategy for allocation (see MAC.INC)
MALLOC_EAX dd	 ?		; Return segment or error
MALLOC_FLAGS dw  ?		; Flags on entry

MALLOC_STR ends

	 clc			; Assume success
	 pushf			; Save IF
	 REGSAVE <eax,ebx,cx,edx,esi,edi,ebp,es> ; Save (must correspond to MALLOC_STR)

	 sub	 esp,@MALLOC_LCLVARS ; Allocate space for local variables
	 mov	 ebp,esp	; Address MALLOC_STR

	 mov	 [ebp].MALLOC_OWNER,ax ; Save owner to set for allocated entry

; If the 386LOAD.CFG 'B' flag is in effect, the incoming owner matches
; the specified range of PSPs, the index has been specified, and the
; region requested wasn't specified, use the index previously specified.
	 cmp	 di,@NOTSPEC	; Was a region specified?
	 jne	 short @F	; Jump if so

	 test	 I15_FLAG,@I15_XSPLIT ; Was the 386LOAD.CFG 'B' flag specified?
	 jz	 short @F	; Jump if not

	 cmp	 BFLG_IDX,0	; Was a region specified?
	 je	 short @F	; Jump if not

	 cmp	 ax,BFLG_BASE	; Izit below our range?
	 jb	 short @F	; Jump if so

	 cmp	 ax,BFLG_LIM	; Izit within range?
	 ja	 short @F	; Jump if not

	 mov	 di,BFLG_IDX	; Get region specified
	 mov	 [ebp].MALLOC_EDI.ELO,di ; Force this region
@@:
	 mov	 es,SEL_4GB3	; Get all memory selector for MOVS / STOS
	 assume  es:AGROUP	; Tell the assembler

	 call	 LOAD_INPRO	; Is 386LOAD in progress?
	 jnc	 short @F	; Jump if not

	 or	 [ebp].MALLOC_EBX.ELO,@STRA_NOLSEG ; Don't create an LSEG

@@:
	 xor	 cx,cx		; Initialize counter of largest free block
	 mov	 [ebp].MALLOC_EAX.ELO,cx ; Initialize segment of last block
	 mov	 [ebp].MALLOC_REG,1 ; Initialize current and best region

	 cli			; Nobody move
MALLOC_STARTCHAIN:
	 mov	 di,[ebp].MALLOC_EDI.ELO ; Reload region index
	 mov	 [ebp].MALLOC_LSEG,0 ; Assume it's low DOS (no LSEG)
	 test	 [ebp].MALLOC_EBX.ELO,@STRA_WANTHI ; Are we looking at high DOS at all?
	 jnz	 short @F	; Jump if so

	 movzx	 ebx,P1ST_MAC.VSEG ; Address first MAC entry in low DOS
	 shl	 ebx,4-0	; Convert paras to bytes
	 call	 MAC_MERGESUB	; Merge adjacent free MAC entries at AGROUP:EBX
	 jc	 near ptr MALLOC_ERRMAC ; Jump if something went wrong

	 jmp	 short MALLOC_NEXT ; Search for requested size

@@:
	 call	 MAC_MERGE	; Merge adjacent free MACs starting at POVR_MAC
	 jc	 near ptr MALLOC_ERRMAC ; Jump if something went wrong

	 movzx	 ebx,POVR_MAC	; Get segment of high DOS memory
	 shl	 ebx,4-0	; Convert from paras to bytes

MALLOC_NEXTHI:
	 test	 [ebp].MALLOC_EBX.ELO,@STRA_NOLSEG ; Skip LSEG creation?
	 jnz	 short MALLOC_NEXT ; Jump if so

	 mov	 [ebp].MALLOC_LSEG,1+@LSEGPARA ; Add in room for
				; 1 MAC para
				; 1 LSEG_STR rounded up to para boundary

MALLOC_NEXT:
; Check for a free block of size DX or greater
	 mov	 dx,[ebp].MALLOC_EDX.ELO ; Get requested size in paras
	 add	 dx,[ebp].MALLOC_LSEG ; Add LSEG and its MAC para (if present)
	 jnc	 short @F	; Jump if we didn't overflow

	 mov	 dx,-1		; Use maximum size
@@:
; Register usage:

; CX	 =	 size of largest free block in paras (in case we
;		 can't find one large enough) or free block closest
;		 to requested size (if best fit).  For last fit, we
;		 save MAX(MIN(previous CX,requested size),block size).
;		 To simplify comparisons, size is saved without LSEG.
; DX	 =	 size of the block we're looking for (in paras) including
;		 LSEG and LSEG MAC entry.
; GS:EBX ==>	 current block

; Check for valid MAC entry
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Yes

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 near ptr MALLOC_ERRMAC ; No
@@:

; If this is a spanning entry, then we're closing in on the region that
; we can allocate a UMB from (if the user has requested a specific region)
; Note that if we're in low DOS and the arenas are linked, we'll have to
; add the LSEG overhead after we cross over into high DOS.

	 test	 [ebp].MALLOC_EBX.ELO,@STRA_WANTHI ; Did we already check high DOS?
	 jnz	 short MALLOC_FINDHI ; Jump if so

	 push	 ebx		; Pass linear address
	 FCALL	 IZIT_MACLINK	; Is GS:EBX a MAC linking entry?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	 jne	 short MALLOC0	; Jump if not (we're still in low DOS)
@@:
	 or	 [ebp].MALLOC_EBX.ELO,@STRA_HITRAN ; We're not in Kansas anymore

; We emulate DOS=UMB by linking the arenas at DEVICE= time.  If this is
; the case, we MUST NOT allocate memory from high DOS unless explicitly
; specified in the strategy.
	 cmp	 TEMP_PSP,0	; Are we still processing DEVICE= statements?
	 je	 short @F	; Jump if not

	 test	 [ebp].MALLOC_EBX.ELO,@STRA_HI or @STRA_HIONLY ; Was high DOS
				; requested?
	 jz	 near ptr MALLOC_ENDCHAIN ; Jump if not

@@:
; DI is meaningless and should always be -1.
; We need to adjust the current region, since this spanning entry will get
; counted in when we go through again.
	 mov	 [ebp].MALLOC_REG,0 ; Throw away this spanning entry
	 jmp	 short MALLOC_NEXTHI ; Adjust size requirements

MALLOC_FINDHI:
	 push	 ebx		; Pass linear address
	 FCALL	 IZIT_MACLINK	; Is GS:EBX a MAC linking entry?
	 je	 short MALLOC_FINDHI1 ; Jump if so

	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	 jne	 short @F	; Jump if not
MALLOC_FINDHI1:
	 inc	 [ebp].MALLOC_REG.LO ; Bump current region count
@@:
	 cmp	 di,-1		; Looking for a region specific UMB?
	 je	 short MALLOC0	; Jump if not

	 push	 ebx		; Pass linear address
	 FCALL	 IZIT_MACLINK	; Is GS:EBX a MAC linking entry?
	 je	 short MALLOC_FINDHI2 ; Jump if so

	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	 jne	 @F		; Jump if not
MALLOC_FINDHI2:
	 dec	 di		; Count in another region (if spanning entry)
				; We're one region closer to requested region
	 jz	 near ptr MALLOC_ENDCHAIN ; Jump if we're done

@@:

; See if the UMB is in our region (if user requested a specific region)

	 cmp	 di,1		; Is this the requested region?
	 jne	 near ptr MALLOC_LOOP ; No, try the next one
MALLOC0:

	 movzx	 eax,AGROUP:[ebx].MAC_NPAR ; Get size of block in paras

	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; Izit free?
	 je	 short MALLOC0A ; Jump if so

	 test	 [ebp].MALLOC_EBX.ELO,@STRA_TMP ; Are we grabbing @MAC_PLUG?
	 jz	 short @F	; Jump if not

	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_PLUG ; Izit plugged by 386LOAD?
	 je	 short MALLOC0A ; Jump if so
@@:
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_HOLE ; Izit a free hole?
	 jne	 near ptr MALLOC_LOOP ; No, try the next one

; We're allocating out of a hole, so we need to subtract MALLOC_LSEG
; back out (we don't care if DX is -1, it wouldn't fit anyway).
	 sub	 dx,[ebp].MALLOC_LSEG ; No LSEG needed

	 cmp	 ax,dx		; Is the block large enough?
	 jb	 near ptr MALLOC_FREE2 ; No, but it's available

	 mov	 dx,ax		; Get size of block
	 jmp	 short MALLOC_CHECKFIT ; Check type of fit

MALLOC0A:
; We have found a free block (in our region if one was specified)

	 cmp	 ax,dx		; Is the block large enough?
	 jb	 near ptr MALLOC_FREE ; No, but it's available

	 mov	 dx,ax		; Get size of block
	 sub	 dx,[ebp].MALLOC_LSEG ; Subtract LSEG and its MAC (if needed)

MALLOC_CHECKFIT:
	 mov	 eax,ebx	; Get current linear address
	 shr	 eax,4-0	; Convert bytes to paras

; If strategy is find first, we're done.  Otherwise, check for a better
; fit (find best) or save this fit for find last.
	 test	 [ebp].MALLOC_EBX.ELO,@STRA_LAST ; Izit find last?
	 jnz	 short MALLOC_SAVEBEST ; Save and continue if so

	 test	 [ebp].MALLOC_EBX.ELO,@STRA_BEST ; Izit find best?
	 jnz	 short @F	; Jump if so

	 mov	 cx,dx		; Save first fit
	 mov	 [ebp].MALLOC_EAX.ELO,ax ; Save segment
	 mov	 al,[ebp].MALLOC_REG.LO ; Get current (high DOS) region
	 mov	 [ebp].MALLOC_REG.HI,al ; Save if it's high DOS
	 jmp	 MALLOC_GOTBLOCK ; Edit MAC entry at AX:0

@@:
	 cmp	 cx,[ebp].MALLOC_EDX.ELO ; Does previous best fit work?
	 jb	 short MALLOC_SAVEBEST ; Jump if not

	 cmp	 dx,cx		; Is this block closer than the previous best?
	 jnb	 MALLOC_LOOP	; Continue if not

MALLOC_SAVEBEST:
	 mov	 cx,dx		; Save size of best (last) fit
	 mov	 [ebp].MALLOC_EAX.ELO,ax ; Save segment
	 mov	 al,[ebp].MALLOC_REG.LO ; Get current (high DOS) region
	 mov	 [ebp].MALLOC_REG.HI,al ; Save if it's high DOS
	 jmp	 short MALLOC_LOOP ; Keep looking for a best (last) fit

MALLOC_FREE:
; This block doesn't fill the bill, but it's free.  Note that we save
; the size without 1+@LSEGPARA to normalize comparisons.  We needn't
; save the segment since it doesn't fit.
	 sub	 ax,[ebp].MALLOC_LSEG ; Subtract LSEG and its MAC entry
	 jc	 short MALLOC_LOOP ; Jump if no room for LSEG and MAC

MALLOC_FREE2:
; This block is not large enough to fill the request, but it's free.
	 cmp	 cx,ax		; Put larger into CX in case we fail
	 jae	 short MALLOC_LOOP ; A previous block is larger

; It's also the largest free block so far.
; If, however, we decided it's free because @STRA_TMP is set and it's
; a @MAC_PLUG entry, we DON'T want to consider it as the largest free
; block.  A program may do this:

; mov bx,-1	; Grab largest available block
; DOSCALL @GETMEM ; BX = largest block
; DOSCALL @GETMEM ; Allocate it

; What we want to happen in the @STRA_TMP case is that the largest block
; in the target region is allocated.  If this approach is used by programs
; that really want low DOS, like NAV&.SYS and LMOUSE with VESA, they'll fail.

; If this turns out to be a problem, we may have to use PSP range
; checking as well.  If the requesting PSP is outside the target
; range, we could return the maximum size gotten from @MAC_PLUG entries
; as well.
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_PLUG ; Izit plugged by 386LOAD?
	 je	 short MALLOC_LOOP ; Jump if so

	 mov	 cx,ax		; Current block is larger
	 mov	 [ebp].MALLOC_LARGEST,ebx ; Save its linear address
	 mov	 ax,[ebp].MALLOC_REG ; Get region index
	 mov	 [ebp].MALLOC_LARGREG,ax ; Save for later
MALLOC_LOOP:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Check for the end-of-the-line
	 je	 short MALLOC_ENDCHAIN ; That's all folks

	 movzx	 eax,AGROUP:[ebx].MAC_NPAR ; Get # paras in this entry
	 inc	 ax		; Count in MAC paragraph
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 ebx,eax	; Skip to the next entry

	 jmp	 MALLOC_NEXT	; Go around again

MALLOC_ENDCHAIN:
; We don't create LSEGs for UMBs that didn't go high.  This should be a rare
; case where it creates problems with MAXIMIZE, since it would require that
; the post-MAXIMIZE configuration has more free high DOS at the time of the
; attempted UMB allocation than before.  This is only possible via reordering.

; Note that we compare the largest block found against the original request,
; since CX already has the LSEG overhead (if present) removed.	Note also
; that we must guard against requested size of 0 paras.
	 jcxz	 @F		; Jump if nothing found

	 cmp	 cx,[ebp].MALLOC_EDX.ELO ; Did we find the requested block?
	 jnc	 short MALLOC_GOTBLOCK ; Jump if so

@@:
; If strategy is high first (not high only) we'll turn it off and go around
; again to see if there's anything in low DOS that fits our needs.
	 btr	 [ebp].MALLOC_EBX.ELO,$STRA_HI ; Izit high DOS then low DOS (not high only)?
	 jnc	 short MALLOC_SHORT ; Jump if not - we came up short

	 jmp	 MALLOC_STARTCHAIN ; Go around again

MALLOC_SHORT:
; Some programs, specifically LMOUSE.COM with VESA extensions and NAV&.SYS,
; expect low DOS memory to be free when they're loaded high.  Since 386LOAD
; plugs low DOS (and high DOS outside the target region) with @MAC_PLUG,
; we'll use these entries to fill allocation requests in low DOS only when
; 386LOAD is active.
	 call	 LOAD_INPRO	; Is 386LOAD in progress?
	 jnc	 short @F	; Jump if not

	 bts	 [ebp].MALLOC_EBX.ELO,$STRA_TMP ; Use @MAC_PLUG in low DOS
	 jc	 short @F	; Jump if we already tried that

	 and	 [ebp].MALLOC_EBX.ELO,not @STRA_HITRAN ; Clear transition bit
	 jmp	 MALLOC_STARTCHAIN ; Try again

@@:
; Note that CX is the largest block size without the LSEG and its MAC entry
	 mov	 [ebp].MALLOC_EDX.ELO,cx ; Save as size of largest block

	 and	 cx,cx		; Check size of largest available block
	 jnz	 near ptr MALLOC_ERRSHORT ; Mark as smaller block available

	 jmp	 MALLOC_ERRNONE ; Mark as no UMBs available

MALLOC_GOTBLOCK:
; MALLOC_EAX.ELO contains segment of free block.
; CX contains size of block sans LSEG size.
; If strategy is last fit, allocate at high end of free block.
; If MALLOC_LSEG, create LSEG entry at the beginning of the block.

; If the strategy is high first and best fit, we may have found our fit
; in low DOS but continued walking into high DOS.  We detect that case
; here and zero the LSEG size.
	 mov	 dx,[ebp].MALLOC_LSEG ; Get size of LSEG and its MAC

	 movzx	 ebx,[ebp].MALLOC_EAX.ELO ; Get segment of free block
	 mov	 ax,bx		; Save segment
	 shl	 ebx,4-0	; Convert paras to bytes
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_HOLE ; Are we recovering a hole?
	 je	 short MALLOC_NOLSEG ; Jump if so

	 cmp	 ax,POVR_MAC	; Are we in high DOS?
	 jnb	 short @F	; Jump if so

MALLOC_NOLSEG:
	 sub	 dx,dx		; No LSEG needed if low DOS or recovering hole
	 mov	 [ebp].MALLOC_LSEG,dx ; Save new value
@@:
	 add	 dx,[ebp].MALLOC_EDX.ELO ; Add paras requested to LSEG
;;;;;;;  jc	 ???		; It exists, so it can't be this close

; AGROUP:EBX ==> MAC entry for free block
; DX = number of paras including LSEG and its MAC para
	 mov	 di,@LSEG_IMAX or @LSEG_UMB ; LSEG flags if exactly equal
	 mov	 ax,AGROUP:[ebx].MAC_NPAR ; Get number of paras
	 cmp	 ax,dx		; Izit the same as paras needed?
	 je	 short MALLOC_MARK ; It's just enough, no split
;;;;;;;  jb	 ???		; It can't be insufficient

; If strategy is last fit, we need to allocate our block from the top
; of the region.  We'll also do this if our reserved "high end" bit is set.
	 mov	 di,@LSEG_UMB	; Initial LSEG flags
	 test	 [ebp].MALLOC_EBX.ELO,@STRA_LAST or @STRA_END ; Izit last fit?
	 jz	 short MALLOC_NSPLIT ; No, split normally

	 sub	 ax,dx		; Subtract from free block
	 dec	 ax		; Subtract MAC paragraph
	 mov	 AGROUP:[ebx].MAC_NPAR,ax ; Save as new size of free block
	 mov	 cl,@MAC_MID	; Mark as middle block
	 xchg	 cl,AGROUP:[ebx].MAC_TYPE ; Swap with current type
	 shr	 ebx,4-0	; Convert bytes to paras
	 add	 bx,ax		; Skip over paras in free block
	 inc	 bx		; Skip free block's MAC para
	 shl	 ebx,4-0	; Convert paras back to bytes
	 mov	 AGROUP:[ebx].MAC_NPAR,dx ; Size of new block
	 mov	 AGROUP:[ebx].MAC_TYPE,cl ; Save as new type
	 jmp	 short MALLOC_MARK ; Join common code

MALLOC_NSPLIT:
	 mov	 AGROUP:[ebx].MAC_NPAR,dx ; Save as new size

; Split the block into pieces of size DX and (AX-DX)

	 inc	 dx		; Count in MAC paragraph
	 sub	 ax,dx		; Get 2nd block size
	 movzx	 edx,dx 	; Zero high-order word
	 shl	 edx,4-0	; Convert from paras to bytes
				; GS:EBX+EDX ==> 2nd entry

	 mov	 cl,@MAC_MID	; Mark as middle block
	 xchg	 cl,AGROUP:[ebx].MAC_TYPE ; Swap with current type
	 mov	 AGROUP:[ebx+edx].MAC_TYPE,cl ; Save as new type
	 push	 AGROUP:[ebx].MAC_OWNR ; Copy @MAC_HOLE, @MAC_FREE, or @MAC_PLUG
	 pop	 AGROUP:[ebx+edx].MAC_OWNR ; ... to trailing entry
	 mov	 AGROUP:[ebx+edx].MAC_NPAR,ax ; Save new size
MALLOC_MARK:
; DOS doesn't fill in the MAC_NAME for non-4B allocations.  We'll give it a
; default value in case the program that owns it frees its environment.
; This might have already happened, so we'll snatch the name of the
; last program to load.
	 REGSAVE <ecx,edi>	; Save

	 lea	 edi,PGROUP:MSG_APPLNAME[size LENTXT_LEN] ; Address start of pathname
	 mov	 esi,PBAPPBASE	; Get PGROUP offset of basename
	 mov	 ecx,esi	; Copy it
	 sub	 ecx,edi	; Get offset of basename from path
	 sub	 cx,MSG_APPLNAME.LENTXT_LEN ; Get -(length of basename)
	 neg	 cx		; Make it positive
	 mov	 ax,8		; Maximum size for MAC_NAME
	 cmp	 cx,ax		; Does it fit?
	 jbe	 short @F	; Jump if so

	 mov	 cx,ax		; Maximum MAC_NAME length
@@:
	 sub	 ax,cx		; AL=spaces to fill with 0
	 mov	 ah,al		; Save it

	 lea	 edi,[ebx].MAC_NAME[0] ; Destination for copy
@@:
	 lods	 PGROUP:[esi].LO ; Get next character
	 cmp	 al,'.'         ; Izit the end of the basename?
	 je	 short @F	; Jump if so

S32	 stos	 <AGROUP:[edi].LO> ; Save it
	 loop	 @B		; Go around again

@@:
	 add	 cl,ah		; Add count of 0's to pad to 8 spaces
	 sub	 al,al		; Get a convenient 0
    rep  stos	 AGROUP:[edi].LO ; Clear remainder of MAC_NAME field

	 REGREST <edi,ecx>	; Restore

; We're assuming that the size of the block allocated is the original
; size plus 1+@LSEGPARA, unless it's in low DOS.  No LSEG is allocated
; for high DOS allocations satisfied by a hole.

	 sub	 si,si		; Assume no LSEG
	 cmp	 [ebp].MALLOC_LSEG,0 ; Izit high or low with LSEG?
	 je	 near ptr MALLOC_MARK1 ; Jump if not, or if $STRA_NOLSEG set

; Split off the LSEG entry from the bottom in case it's re-allocated later
; That way, we know the LSEG entry always precedes its associated block

; Note that we need to assign the same owner for all non-XMS LSEGs
; so that free calls can eliminate LSEGS when the Int 21 call is
; trapped in the IDT.
;;;;;;;  mov	 ax,[ebp].MALLOC_OWNER ; Set same owner as segment
;;;;;;;  cmp	 ax,@MAC_UMB	; Izit an XMS UMB allocate?
;;;;;;;  jne	 short @F	; Jump if not
;;;;;;;
;;;;;;;  mov	 ax,@MAC_LSEG
;;;;;;;@@:
;;;;;;;  mov	 AGROUP:[ebx].MAC_OWNR,ax ; Mark owner as appropriate
	 mov	 AGROUP:[ebx].MAC_OWNR,@MAC_LSEG ; Mark as an LSEG entry

	 mov	 ax,@LSEGPARA	; Get size in paras of LSEG entry
	 xchg	 ax,AGROUP:[ebx].MAC_NPAR ; Swap 'em
	 movzx	 edx,ax 	; Copy and zero high-order word
	 sub	 dx,1+@LSEGPARA ; Count out the INT block and its MAC para
				; for ASIZE, ISIZE, and LSIZE
	 shl	 edx,4-0	; Convert from paras to bytes

	 mov	 cl,@MAC_MID	; Mark as middle block
	 xchg	 cl,AGROUP:[ebx].MAC_TYPE ; Swap with current type

; Calculate the back link for the LSEG entry

	 mov	 esi,ebx	; Save as back link entry
	 shr	 esi,4-0	; Convert from bytes to paras

; Save LSEG entry data
; AX  = # paras in allocated block
; EDX = # bytes ...
; EBX = linear address of MAC entry which contains the LSEG
; SI  = segment of new MAC entry
; DI  = flags (@LSEG_UMB, possibly @LSEG_IMAX)
; CL  = new MAC_TYPE

	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_NEXT,-1 ; Mark as end-of-the-chain
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_FNE.EDD[0],' BMU' ; Mark as 'UMB '
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_FNE.EDD[4],'    ' ; Mark as '    '
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_FNE.EDD[8],'    ' ; Mark as '    '

	 REGSAVE <ax,ebx,cx,dx> ; Save
	 mov	 dx,[ebp].MALLOC_OWNER ; Get owner
	 cmp	 dx,@MAC_UMB	; Izit a DOS allocate?
	 je	 short MALLOC_XMSLSEG ; Jump if not

	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_FNE.EDD[4],'=PSP' ; Mark as 'PSP='
	 mov	 cx,4		; Number of nybbles to process
	 lea	 ebx,[ebx+(size MAC_STR)].LSEG_FNE.EDD[8] ; Address first byte
@@:
	 rol	 dx,4		; Get next lower order nybble
	 mov	 al,dl		; Prepare to convert to hex
	 and	 al,0Fh 	; Mask off high nybble
	 add	 al,90h 	; Add 90h so DAA will set CF on wrap past 99h
	 daa			; Convert to BCD & set CF if A-F
	 adc	 al,'@'         ; Add 40h + CF (no change to low nybble if 0-9)
	 daa			; Convert to BCD (ignore CF)
	 mov	 AGROUP:[ebx].LO,al ; Save
	 inc	 ebx		; Skip to next space in output
	 loop	 @B		; Go around again

MALLOC_XMSLSEG:
; Isolate the 2 low order strategy bits and save as the strategy field in flags
	 mov	 ax,[ebp].MALLOC_EBX.ELO ; Get strategy
	 and	 ax,(@STRA_BEST or @STRA_LAST) ; Isolate low bits
				; Note that we've weeded out invalid combos
				; with both bits set in 5801 (set strategy).
	 shl	 ax,$LSEG_STRA	; Shift over to LSEG_FLAG strategy subfield
	 or	 di,ax		; Combine with current flags
	 REGREST <dx,cx,ebx,ax> ; Restore

	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_RPARA,ax
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_EPAR0,0 ; No environment
; LSEG_EPAR1 contains special flags and ancestor bitmap for UMBs.  See below.
;;;;;;;  mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_EPAR1,0 ; No environment
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_RPAR2,0 ; No forced SIZE=
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_NPARA,1+@LSEGPARA ; INT block
						; Including MAC para
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_FLAG,di ; Save strategy
				; & other flags (@LSEG_UMB, @LSEG_IMAX)

	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_ASIZE,edx
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_LSIZE,edx
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_ISIZE,edx

	 REGSAVE <eax>		; Save for a moment

; We don't act on the @I15_NOVELL flag now, since the initialization size
; can't be larger than the first allocation.  When (if) we resize downwards
; and scan for filler pattern, we'll test (and reset) @LSEG2_NOV.  It tells
; us to round the initialization size up to a 256 byte boundary and add an
; extra 256 bytes.
	 test	 I15_FLAG,(@I15_NOVELL or @I15_FROUND) ; Is NETX eating
				; 4B calls, or are we forcing rounding?
	 setnz	 al		; AL=1 if so, 0 if not
	 shl	 al,$LSEG2_NOV	; Move into position for LSEG2_FLAG
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG2_FLAG,al ; Save for later

	 mov	 al,[ebp].MALLOC_EDI.ELO.LO ; Get region requested (-1 if not spec)
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_PREG,al ; Not specified or #
;;;;;;;  mov	 al,[ebp].MALLOC_REG.HI ; Get actual region (1-based)
;;;;;;;  mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_EREG,al ; Save for util/si
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_EREG,@NOTSPEC ; Not specified

; LSEG_GRP == @GRPUMB is no longer a valid test for UMBs.  Use @LSEG_UMB
; if not (@LSEG_DRV or @LSEG_INST).
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_GRP,@GRPUMB ; Default group

	 mov	 eax,ebx	; Get LSEG MAC
	 shr	 eax,4-0	; Convert to segment value
	 add	 ax,1+@LSEGPARA+1 ; Skip LSEG MAC, LSEG, and MAC
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_OWNRHI,ax ; Mark as no owner

	 REGREST <eax>		; Restore

	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_INSTLO,0 ; Mark as no low DOS to instance
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_INSTLEN,0 ; Mark as no low DOS to instance

; We now do the filler pattern for all LSEGs, since some (like bozo
; LanMan TCP/IP's UMB.COM) get the largest region, then allocate its
; size - 2 paras.
;;;;;;;; If we've initially allocated the entire region, we need to blast in our
;;;;;;;; filler pattern so we can determine the actual initialization size when
;;;;;;;; we resize downward.
;;;;;;;  test	 di,@LSEG_IMAX	; Did we grab the entire region?
;;;;;;;  jz	 short MALLOC_XFILL ; Jump if not
;;;;;;;
	 REGSAVE <eax,ecx>	; Save

	 sub	 edi,edi	; Clear high order word
	 mov	 di,1+@LSEGPARA ; Size of LSEG and its MAC entry
	 movzx	 ecx,ax 	; Get number of paras
	 sub	 cx,di		; Less LSEG
	 shl	 ecx,4-2	; Convert paras to dwords
	 mov	 eax,FILLPAT	; '386M' filler pattern
	 add	 di,si		; Address starting MAC entry
	 inc	 di		; Skip MAC entry
	 shl	 edi,4-0	; Convert paras to bytes

   rep	 stos	 AGROUP:[edi].EDD ; Blast in our filler pattern

	 REGREST <ecx,eax>	; Restore
;;;;;;;MALLOC_XFILL:
; Link this LSEG entry into the chain

; AX  = # paras in allocated block
; EBX = linear address of MAC entry which contains the LSEG
; DI  = ancestor bitmap
; SI  = segment of new MAC entry
; CL  = new MAC_TYPE

	 REGSAVE <eax,ebx>	; Save for a moment

	 movzx	 eax,HIMEM_CS	; Get segment of high DOS memory
	 shl	 eax,4-0	; Convert from paras to bytes
	 assume  gs:PGROUP	; Tell a white lie
	 movzx	 eax,gs:LOADSEG[eax] ; Get low memory LOADSEG
	 assume  gs:AGROUP	; Retract nose

; Note that LOADSEG can never be the last LSEG
; While we're trundling through the LSEG chain, look for ancestors
; with LSEG_RPARA == (MAX (LSEG_ISIZE,LSEG_LSIZE) >> 4) + LSEG_NPARA
; or with @LSEG_IMAX previously set (indicated by $LSEG_EP1UIMAX).
; Note that our linear bitmap does NOT support LSEGs that are resized
; downward twice, and therefore we will NOT set the corresponding
; bit if $LSEG_EP1UIMAX has already been set.
; Although we'll only set bits until we encounter a 4B PSP entry
; (which is also processed) or a non-UMB, we also need to check
; for both of these ending conditions in the optimization algorithm
; to guard against misalignment resulting from deletion of LSEG
; entries.
; We'll clear DI for non-UMB LSEG entries.  Note that we're constructing
; the bitmap starting from the beginning of the LSEG chain.  We use it
; in UTIL_OPT.ASM starting from the current entry and working backwards.
MALLOC1:
	 sub	 di,di		; Clear ancestor bitmap
MALLOC1A:
	 cmp	 ax,-1		; End of the line?
	 je	 short MALLOC2	; Jump if so

	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 ebx,eax	; Save for next time
	 movzx	 eax,AGROUP:[ebx].LSEG_NEXT ; Get next segment

	 test	 AGROUP:[ebx].LSEG_FLAG,@LSEG_UMB ; Izit a UMB?
	 jz	 short MALLOC1	; Clear bitmap and continue if not

	 test	 AGROUP:[ebx].LSEG_FLAG,@LSEG_DRV or @LSEG_INST ; Izit 386LOAD?
	 jnz	 short MALLOC1	; Jump if so

	 bt	 AGROUP:[ebx].LSEG_EPAR1,$LSEG_EP1UPSP ; Izit a 4B PSP?
	 jnc	 short @F	; Jump if not

	 sub	 di,di		; Clear ancestor bitmap
@@:
	 bt	 AGROUP:[ebx].LSEG_EPAR1,$LSEG_EP1UIMAX ; Was @LSEG_IMAX set previously?
	 jc	 short MALLOC1B ; Jump if so (note CF=1)

	 mov	 edx,AGROUP:[ebx].LSEG_ISIZE ; Get initialization size
	 cmp	 edx,AGROUP:[ebx].LSEG_LSIZE ; Izit smaller than load size?
	 jnb	 short @F	; Jump if not

	 mov	 edx,AGROUP:[ebx].LSEG_LSIZE ; Take the larger of the two
@@:
	 shr	 edx,4-0	; Convert bytes to paras
	 add	 dx,AGROUP:[ebx].LSEG_NPARA ; Add size of interrupt block
	 cmp	 dx,AGROUP:[ebx].LSEG_RPARA ; Izit the same as the resident size?
	 je	 short MALLOC1B ; Jump if so (note CF=0)

	 bt	 AGROUP:[ebx].LSEG_FLAG,$LSEG_IMAX ; Izit at the maximum size?
	 cmc			; CF=0 if so

MALLOC1B:
	 cmc			; CF=1 if we should mark this one
	 rcr	 di,1		; Move previous ancestors over, setting high bit to CF
	 jmp	 short MALLOC1A ; Go around again

; Link in new LSEG entry

; EBX = linear address of last LSEG entry
; DI = ancestor bitmap (bit 15 = last ancestor)
; SI  = segment of new MAC entry
; CL  = new MAC_TYPE

MALLOC2:
	 mov	 ax,si		; Copy segment of MAC entry
	 inc	 ax		; Skip to LSEG entry
	 mov	 AGROUP:[ebx].LSEG_NEXT,ax ; Save link to new LSEG

	 mov	 edx,ebx	; Copy linear address of last LSEG entry
	 shr	 edx,4-0	; Convert from bytes to paras

	 REGREST <ebx,eax>	; Restore

	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_PREV,dx ; Mark as previous LSEG
	 shr	 di,4-0 	; Right justify ancestor bitmap
	 or	 di,di		; Are there any?
	 jz	 short @F	; Jump if not

	 or	 di,mask $LSEG_EP1UPREV ; Mark as ancestors present
@@:
	 mov	 AGROUP:[ebx+(size MAC_STR)].LSEG_EPAR1,di ; Save additional flags and ancestor bitmap

; Skip to user's MAC entry and save type and size info

; AX  = # paras in allocated block
; EBX = linear address of last LSEG entry
; SI  = segment of LSEG MAC entry
; CL  = new MAC_TYPE

	 add	 ebx,(1+@LSEGPARA) shl (4-0) ; Skip to new block
	 mov	 AGROUP:[ebx].MAC_TYPE,cl ; Save as new block type
	 sub	 ax,1+@LSEGPARA ; Subtract from old size (including MAC para)
	 mov	 AGROUP:[ebx].MAC_NPAR,ax ; Save as # paras
MALLOC_MARK1:
; LSEG has already been created if applicable.	Save segment for return
; and we're done.
	 mov	 AGROUP:[ebx].MAC_BACK,si ; Save for XMS_RELUMB
	 mov	 ax,[ebp].MALLOC_OWNER ; Get owner to set
	 mov	 AGROUP:[ebx].MAC_OWNR,ax ; Set ownership

	 shr	 ebx,4-0	; Convert from bytes to paras
	 inc	 bx		; Skip over MAC entry
	 mov	 [ebp].MALLOC_EAX.ELO,bx ; Save as segment of block
				; DX (room for growth) unchanged
	 jmp	 short MALLOC_EXIT ; Join common exit code

MALLOC_ERRMAC:
	 mov	 al,8Fh 	; MAC corrupted
	 jmp	 short MALLOC_ERR ; Join common error exit

MALLOC_ERRSHORT:
; If we found a block in high DOS, the 386LOAD.CFG 'B' flag is in
; effect, and BFLG_IDX hasn't been set, set it now.
; MALLOC_EAX.ELO contains segment of free block.
; CX contains size of block sans LSEG size.
	 test	 I15_FLAG,@I15_XSPLIT ; Is the 386LOAD.CFG 'B' flag in effect?
	 jz	 short @F	; Jump if not

	 cmp	 BFLG_IDX,0	; Has the index already been set?
	 jne	 short @F	; Jump if so

	 mov	 eax,[ebp].MALLOC_LARGEST ; Get address
	 shr	 eax,4-0	; Convert bytes to paras
	 cmp	 ax,POVR_MAC	; Izit in high DOS?
	 jb	 short @F	; Jump if not

	 mov	 es,SEL_DSJG3	; Establish addressibility to JGROUP
	 assume  es:JGROUP	; Tell the assembler

	 mov	 BFLG_BASE,ax	; Bottom of PSP range
	 add	 ax,cx		; Get highest possible PSP
	 mov	 BFLG_LIM,ax	; Save it for comparison
	 mov	 ax,[ebp].MALLOC_LARGREG ; Get region we found it in
	 mov	 BFLG_IDX,ax	; Save it to force allocations in this region
@@:
	 mov	 al,0B0h	; Smaller block available
	 jmp	 short MALLOC_ERR ; Join common error exit

MALLOC_ERRNONE:
	 mov	 al,0B1h	; No space available
;;;;;;;  jmp	 short MALLOC_ERR ; Join common error exit

MALLOC_ERR:
	 mov	 [ebp].MALLOC_EAX.LO,al ; Save error return code
	 or	 [ebp].MALLOC_FLAGS,mask $CF ; Indicate failure

MALLOC_EXIT:
	 add	 esp,@MALLOC_LCLVARS ; Strip local storage
	 REGREST <es,ebp,edi,esi,edx,cx,ebx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler
	 popf			; Restore flags with CF significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MAC_ALLOC endp			; End MAC_ALLOC procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 FPPROC  MAC_REALLOC -- Reallocate a MAC entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Reallocate a MAC entry to specified size, in low or high DOS.

If in high DOS and we're shrinking a @MAC_MID type memory block,
we need to ensure that the next entry is owned by @MAC_SPAN.
If that's not the case, we're creating a hole.  Rather than freeing
the new entry covering the hole, we set the owner to @MAC_HOLE,
and we DON'T adjust the LSEG values.  As far as the optimization
algorithm is concerned, that hole doesn't exist.

Note that when 386LOAD is in the picture, we don't do any creation
of holes.

If any subsequent UMBs make a request and we find it in the hole,
we won't create an LSEG.  Splitting a @MAC_HOLE entry creates another
@MAC_HOLE entry.

This adds yet another wrinkle.	We can no longer assume that every
MAC in high DOS has an LSEG.  If a MAC being resized or freed is not
adjacent to any LSEG, it's in a hole and there's no LSEG adjustment
to be done.

If we're resizing a MAC upwards and the following MAC entry is a hole,
we use the space in the hole but don't change the size in the LSEG.

One case must be covered in MAC_MERGESUB.  If a MAC entry is allocated,
another is allocated after it (creating a hole), then the original
MAC entry is resized downwards, and the second MAC entry is released,
MAC_MERGE will automatically merge the @MAC_HOLE entry created into
the free chain.  However, the LSEG for the original MAC entry still
has the original resident size.  In this case, we search for the
LSEG covering the @MAC_HOLE entry and adjust LSEG_RPARA.

On entry:
AX	 =	 Owner to force or -1 to leave it alone
BX	 =	 New size in paras
DX:0	 ==>	 MAC entry to resize

On exit:
CF=0		 Entry resized OK, AX=input segment
CF=1		 Error occurred, error code in AL (see MAC_ALLOC)
DX	 =	 Maximum possible size if failed

|

MREALLOC_STR struc

	 dw	 ?		; Saved ES
	 dd	 ?		; Saved EBP
	 dw	 ?		; Saved DI
	 dd	 ?		; Saved ESI
MREALLOC_EDX dd  ?		; Segment to resize
	 dd	 ?		; Saved ECX
MREALLOC_EBX dd  ?		; New size in paras
MREALLOC_EAX dd  ?		; Error return in AL
MREALLOC_FLAGS dw ?		; Flags saved on entry

MREALLOC_STR ends

	 clc			; Assume success
	 pushf			; Save IF
	 REGSAVE <eax,ebx,ecx,edx,esi,di,ebp,es> ; Save (must match MREALLOC_STR)

	 mov	 ebp,esp	; Address MREALLOC_STR

	 mov	 es,SEL_4GB3	; Get all memory selector for SCAS
	 assume  es:AGROUP	; Tell the assembler

	 mov	 di,@MAC_FREE	; Value to use for free entry when splitting

; Ensure the MAC entry is valid

	 movzx	 ebx,dx 	; Copy and zero high-order word

	 sub	 ebx,1		; Back off to MAC entry
	 jc	 near ptr MREALLOC_EB2 ; Jump if that's a problem (bad MAC entry)

	 shl	 ebx,4-0	; Convert from paras to bytes

	 cli			; Nobody move

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Yes

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 near ptr MREALLOC_EB2 ; No, so that's an error
@@:
;;;;;;;  cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_UMB ; Izit a UMB-owned entry?
;;;;;;;  jne	 near ptr MREALLOC_EB2 ; No, so that's an error
;;;;;;;
; Merge MAC entries in case multiple adjacent free entries above this one
; Note that we only merge starting with entries at or above this one, since
; this entry may be freed already (VPRMODE frees its PSP then goes resident).

	 call	 MAC_MERGESUB	; Merge adjacent free entries starting with EBX
	 jc	 near ptr MREALLOC_E8F ; Jump if something went wrong

; See if there's enough room above

	 mov	 ax,AGROUP:[ebx].MAC_NPAR ; Get # paras in MAC entry
	 movzx	 esi,ax 	; Copy to use as index
	 inc	 esi		; Skip over MAC para
	 shl	 esi,4-0	; Convert from paras to bytes
	 xor	 cx,cx		; Zero size of region above

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 je	 short MREALLOC1 ; Yes, there's no next entry

	 cmp	 AGROUP:[ebx+esi].MAC_OWNR,@MAC_FREE ; Izit free?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx+esi].MAC_OWNR,@MAC_HOLE ; Izit a hole?
	 jne	 short MREALLOC1 ; Jump if not

	 call	 LOAD_INPRO	; Is 386LOAD in progress?
	 jc	 short @F	; Jump if so

	 mov	 di,@MAC_HOLE	; Don't adjust LSEG
@@:
; Note that the following entry may have length 0, but we can still
; eat the MAC entry.
	 mov	 cx,AGROUP:[ebx+esi].MAC_NPAR ; Get # paras in MAC entry
	 inc	 cx		; Plus MAC para
MREALLOC1:
	 movzx	 edx,[ebp].MREALLOC_EBX.ELO ; Get size needed, zero high-order word

; Check for shrink or same

	 cmp	 ax,dx		; Izit large enough?
	 jae	 short MREALLOC_SHRINK ; Jump if it is

	 add	 ax,cx		; Add in size above (if any)

; Check for grow

	 cmp	 ax,dx		; Izit large enough?
	 jae	 short MREALLOC_GROW ; Jump if so

	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_UMB ; Izit a UMB-owned entry?
	 jne	 short @F	; Jump if not (assume it's DOS)

	 mov	 [ebp].MREALLOC_EDX.ELO,ax ; Save as largest size
	 jmp	 MREALLOC_EB0	; Join common error code

@@:
; If the size requested is not available, use the maximum size,
; but still return an error code.  This is very ugly, but that's what
; DOS does.  Note that we still need to do all the right stuff
; in updating the MAC entry and its LSEG.
	 or	 [ebp].MREALLOC_FLAGS,mask $CF ; Indicate failure

	 mov	 dx,ax		; Maximum size (includes free space above)

MREALLOC_GROW:
; If we're merging the contents of the following entry to accommodate
; growth, CX>0 (even if AGROUP:[ebx+esi].MAC_NPAR == 0).  If we're not
; merging, we don't need to change the current MAC type.
	 jcxz	 MREALLOC_SHRINK ; Jump if not merging

	 mov	 cl,AGROUP:[ebx+esi].MAC_TYPE ; Get free entry's type
	 mov	 AGROUP:[ebx].MAC_TYPE,cl ; Save as new type

MREALLOC_SHRINK:
	 REGSAVE <eax,edx>	; Save registers

; Modify the LSEG entry (for both shrink and grow cases)

	 mov	 ax,dx		; Get new para size
	 sub	 ax,AGROUP:[ebx].MAC_NPAR ; Subtract old para size
	 cwde			;  ... to get 32 bit difference (in paras)

	 mov	 AGROUP:[ebx].MAC_NPAR,dx ; Save as total size (in MAC entry)

; Since we may create an LSEG in low DOS if the strategy was high (not
; high only) and there was not enough room in high DOS, we need to check
; low DOS as well for LSEG entries.
	 movzx	 edx,AGROUP:[ebx].MAC_BACK ; Get back link to LSEG MAC
	 or	 dx,dx		; Izit valid (non-zero)?
	 jz	 near ptr MREALLOC_XLSEG ; Jump if not

	 inc	 dx		; Skip LSEG MAC entry
	 push	 ax		; Save signed offset
	 mov	 ax,dx		; Segment to check for LSEG-ness
	 call	 IZITLSEG	; Return CF=1 if AX:0 is an LSEG entry
	 pop	 ax		; Restore
	 jnc	 near ptr MREALLOC_XLSEG ; Jump if not an LSEG

	 shl	 edx,4-0	; Convert paras to bytes
	 test	 AGROUP:[edx].LSEG_FLAG,@LSEG_INPRO ; Izit 386LOAD or HARPO?
	 jnz	 near ptr MREALLOC_XLSEG ; Jump if so (leave it alone)

; Since a segment allocated by DOS for a 4B in low DOS may have a random
; value in the LSEG back link field, and this value may HAPPEN to point
; to a valid LSEG, we need to check for this case.
	 mov	 cx,[ebp].MREALLOC_EDX.ELO ; Get segment we're reallocating
	 cmp	 cx,POVR_MAC	; Izit in high DOS?
	 jnb	 short @F	; Jump if so

	 cmp	 cx,AGROUP:[edx].LSEG_OWNRHI ; Izit our LSEG?
	 jne	 near ptr MREALLOC_XLSEG ; Jump if not (leave LSEG alone)

@@:
	 cmp	 di,@MAC_FREE	; Did we eat a hole?
	 jne	 short MREALLOC_SHRINK1 ; If so, don't adjust LSEG

	 add	 AGROUP:[edx].LSEG_RPARA,ax ; New resident paras
	 jnc	 short MREALLOC_SHRINK1 ; Jump if we didn't shrink it

	 shr	 edx,4-0	; Convert bytes to paras
	 cmp	 dx,POVR_MAC	; Izit in high DOS?
	 rcl	 edx,4-0	; Convert paras to bytes, bit 3 == CF
	 btr	 dx,$BIT03	; Test and clear CF
	 jb	 short MREALLOC_SHRINK1       ; Jump if not high (no holes to worry about)

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 jne	 short MREALLOC_SHRINK1 ; Jump if not

	 push	 eax		; Save for a moment
	 lea	 eax,AGROUP:[ebx+esi] ; Get linear address
	 push	 eax		; Pass linear address
	 FCALL	 IZIT_MACLINK	; Is GS:EAX a MAC linking entry?
	 pop	 eax		; Restore
	 je	 short MREALLOC_SHRINK1 ; Jump if so

	 cmp	 AGROUP:[ebx+esi].MAC_OWNR,@MAC_SPAN ; Izit at end of region?
	 je	 short MREALLOC_SHRINK1 ; Jump if so

	 cmp	 AGROUP:[ebx+esi].MAC_OWNR,@MAC_FREE ; Is the next entry free?
	 je	 short MREALLOC_SHRINK1 ; Jump if so

	 sub	 AGROUP:[edx].LSEG_RPARA,ax ; Restore previous value
	 mov	 di,@MAC_HOLE	; Don't actually free it
MREALLOC_SHRINK1:

; We've ensured that this MAC entry is the last one in its region.
; While this MAC was bloated to a larger initialization size, the
; placement of subsequent allocations in high DOS may have been
; affected.  We'll keep track of that through the ancestor bitmap
; scheme (kept in LSEG_EPAR1).

; If the LSEG's initial allocation was for the maximum available, clear
; the @LSEG_IMAX bit and calculate the initialization size.  Note that we
; leave the load size alone.  If the initial allocation was via 4B0x,
; this value is the minimum load size, and the optimization algorithm
; will use the larger of LSEG_ISIZE and LSEG_LSIZE.
; We'll set $LSEG_EP1UIMAX to indicate that @LSEG_IMAX was previously set.
; We need to know this in the optimization algorithm when we're walking
; back down the ancestor bitmap.

; We'll ignore the results of the test here (which we still use to clear
; the bit) since all UMBs now have the filler pattern blown in.
;;;;;;;; We calculate the initialization size by scanning for a break in
;;;;;;;; the filler pattern which we blew in when the segment was initially
;;;;;;;; allocated for the entire region size.	This is necessary to handle
;;;;;;;; programs loaded by NETX; our 4B code never gets control.
	 btr	 AGROUP:[edx].LSEG_FLAG,$LSEG_IMAX ; Was initial allocation maximum?
	 jnc	 short @F	; Jump if not

	 or	 AGROUP:[edx].LSEG_EPAR1,mask $LSEG_EP1UIMAX ; Mark as @LSEG_IMAX set
@@:
; Bit has been cleared
; EAX = signed difference in paras.
; We'll scan downward from the top of the region to see how much
; of the filler pattern is left.
	 test	 AGROUP:[edx].LSEG2_FLAG,@LSEG2_FISIZE ; Are we changing?
	 jnz	 near ptr MREALLOC_XLSEG ; Jump if not

	 REGSAVE <eax,edi>	; Save

	 mov	 ecx,eax	; Get signed difference in paras
	 neg	 ecx		; Paras to scan
	 movzx	 edi,[ebp].MREALLOC_EDX.ELO ; Get starting segment
	 add	 di,[ebp].MREALLOC_EBX.ELO ; Skip to (new) end
	 add	 di,cx		; Skip to end of region to scan
	 shl	 edi,4-0	; Convert paras to bytes
	 sub	 edi,4		; Start with penultimate dword
	 shl	 ecx,2-0	; Convert paras to dwords

	 mov	 eax,FILLPAT	; '386M' pattern to look for

	 std			; Scan backwards
   repe  scas	 AGROUP:[edi].EDD ; ECX = corrupted dwords - 1
	 cld			; Restore normal direction

	 REGREST <edi,eax>	; Restore

	 je	 short @F	; Jump if entire region is intact

	 inc	 ecx		; Include current dword in total corrupted
@@:
	 add	 ecx,4-1	; Round up to dword boundary
	 shr	 ecx,(4-2)	; Convert from dwords to paras
	 add	 eax,ecx	; Reduce size delta by corrupted paras

; If the @LSEG2_NOV flag is set, we need to further reduce delta (possibly
; making it positive) to round the initialization size up to a 256 byte
; boundary and add an additional 256 bytes for good measure.
	 btr	 AGROUP:[edx].LSEG2_FLAG,$LSEG2_NOV ; Is NETX involved?
	 jnc	 short MREALLOC_XSCAN ; Jump if not

	 or	 AGROUP:[edx].LSEG2_FLAG,@LSEG2_FISIZE ; Don't change ISIZE
	 shl	 eax,(4-0)	; Convert difference from paras to bytes
	 add	 eax,AGROUP:[edx].LSEG_ISIZE ; Get new size
	 add	 eax,256+256-1	; Round it up
	 and	 ax,not (256-1) ; Knock off excess
	 sub	 eax,AGROUP:[edx].LSEG_ISIZE ; Get new delta (it may now be
				; positive)
	 jmp	 short @F	; Join common code

MREALLOC_XSCAN:
	 shl	 eax,(4-0)	; Convert difference from paras to bytes
@@:
	 add	 AGROUP:[edx].LSEG_ASIZE,eax ; New USE= size
	 add	 AGROUP:[edx].LSEG_ISIZE,eax ; New init size
	 bt	 AGROUP:[edx].LSEG_EPAR1,$LSEG_EP1UPSP ; Izit a 4B PSP?
	 jc	 short MREALLOC_XLSEG ; Jump if so - LSIZE is significant

	 add	 AGROUP:[edx].LSEG_LSIZE,eax ; New load size
MREALLOC_XLSEG:
; Reassert ownership of MAC entry.  This is what DOS does, and some programs
; rely upon it.  DOS also returns the segment in AX.
	 mov	 dx,[ebp].MREALLOC_EDX.ELO ; Get segment

	 xchg	 dx,[ebp].MREALLOC_EAX.ELO ; Get ownership to assert (if any)
	 cmp	 dx,-1		; Should we leave it alone (XMS UMB services)?
	 je	 short @F	; Jump if so

; The ownership of LSEG MAC entries should remain @MAC_LSEG.  NETX will
; do its own assertion of ownership for programs (like SMARTDRV) that
; 4B themselves into high DOS.	Unfortunately, we don't have a way to
; cover our LSEG entries.  Their ownership remains that of the instance
; of SMARTDRV in low DOS, which terminates without going resident, freeing
; our LSEG.  It's not a happy ending...

; The only cases where LSEGs are freed are:
; 1) A MAC entry is freed, and the LSEG is pointed to in the MAC_BACK field.
; 2) We detect an orphaned LSEG in MAC_MERGESUB.
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_LSEG ; Izit an LSEG entry?
	 je	 short @F	; Leave it alone if so

	 mov	 AGROUP:[ebx].MAC_OWNR,dx ; Set owner to current PSP
@@:
	 REGREST <edx,eax>	; Restore registers

	 cmp	 ax,dx		; Are we changing size?
	 je	 short MREALLOC_EXIT0 ; Jump if it's just right (no split block)

; Split the block into pieces of size DX and (AX-DX)

	 inc	 dx		; Count in MAC paragraph
	 sub	 ax,dx		; Get 2nd block size
	 shl	 edx,4-0	; Convert from paras to bytes
				; GS:EBX+EDX ==> 2nd entry

	 mov	 cl,@MAC_MID	; Mark as middle block
	 xchg	 cl,AGROUP:[ebx].MAC_TYPE ; Swap with current type
	 mov	 AGROUP:[ebx+edx].MAC_TYPE,cl ; Save as new type
	 mov	 AGROUP:[ebx+edx].MAC_OWNR,di ; Mark as free or hole
	 mov	 AGROUP:[ebx+edx].MAC_NPAR,ax ; Save new size

MREALLOC_EXIT0:
; AX = new size of block

; If we forced an error but still reallocated to the maximum size,
; we need to return an error code in AX, and the size in DX (which
; will get translated to BX in QMAX_I21!INT21_MACFNS).
	 test	 [ebp].MREALLOC_FLAGS,mask $CF ; Are we failing?
	 jz	 short MREALLOC_EXIT ; Jump if not

	 mov	 [ebp].MREALLOC_EDX.ELO,ax ; Save new size as maximum
	 jmp	 short MREALLOC_EB0 ; Join common error code

MREALLOC_E8F:
	 mov	 al,8Fh 	; MAC arena hosed
	 jmp	 short MREALLOC_ERR ; Join common error code

MREALLOC_EB0:
	 mov	 al,0B0h	; Can't grow to specified size
	 jmp	 short MREALLOC_ERR ; Join common error code

MREALLOC_EB2:
	 mov	 al,0B2h	; Not a MAC entry
;;;;;;;  jmp	 short MREALLOC_ERR ; Join common error code

MREALLOC_ERR:
	 mov	 [ebp].MREALLOC_EAX.LO,al ; Save error code
	 or	 [ebp].MREALLOC_FLAGS,mask $CF ; Indicate failure

MREALLOC_EXIT:
	 REGREST <es,ebp,di,esi,edx,ecx,ebx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler
	 popf			; Restore (CF significant)

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MAC_REALLOC endp		; End MAC_REALLOC procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 FPPROC  MAC_FREE -- Free a MAC entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Free a MAC entry, in low or high DOS.

On entry:
DX:0	 ==>	 MAC entry to free

On exit:
CF=0		 Entry freed OK
CF=1		 Error occurred, error code in BL (see MAC_ALLOC)

|

MFREE_STR struc

	 dw	 ?		; Saved DI
	 dd	 ?		; Saved ESI
	 dw	 ?		; Saved CX
	 dd	 ?		; Saved EBX
MFREE_EAX dd	 ?		; Saved EAX
MFREE_FLAGS dw	 ?		; Saved flags

MFREE_STR ends

	 clc			; Assume success
	 pushf			; Save (IF significant)
	 REGSAVE <eax,ebx,cx,esi,di> ; Save (must correspond to MFREE_STR)

	 sub	 di,di		; Initialize count of freed entries owning LSEGs

; Ensure the UMB is valid

	 movzx	 ebx,dx 	; Copy and zero high-order word

	 sub	 ebx,1		; Back off to MAC entry
	 jc	 near ptr MFREE_EB2 ; Jump if that's a problem (bad MAC entry)

	 shl	 ebx,4-0	; Convert from paras to bytes

	 cli			; Nobody move

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Yes

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 near ptr MFREE_EB2 ; No, so that's an error
@@:
;;;;;;;  cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_UMB ; Izit a UMB-owned entry?
;;;;;;;  jne	 near ptr MFREE_EB2 ; No, so that's an error
;;;;;;;
; If there's an LSEG entry back link, free it, and de-link from the
; LSEG entry chain

	 cmp	 AGROUP:[ebx].MAC_BACK,0 ; Check back link pointer
	 je	 short MFREE3	; Jump if not present

	 movzx	 eax,HIMEM_CS	; Get segment of high DOS memory
	 shl	 eax,4-0	; Convert from paras to bytes
	 assume  gs:PGROUP	; Tell a white lie
	 movzx	 eax,gs:LOADSEG[eax] ; Get low memory LOADSEG
	 assume  gs:AGROUP	; Retract nose
	 movzx	 esi,AGROUP:[ebx].MAC_BACK ; Get segment of LSEG entry
	 inc	 esi		; Skip to LSEG entry
	 shl	 esi,4-0	; Convert from paras to bytes

; Note that the back pointer can never be to LOADSEG
; Note also that if the entry we're freeing has no LSEG, we need to
; mark it as @MAC_HOLE rather than free.  Future allocations MUST NOT
; create a duplicate LSEG, since the only way a MAC entry without an
; LSEG could be created is if a UMB was shrunk after other UMBs were
; allocated after it.

MFREE1:
	 cmp	 ax,-1		; End of the line?
	 je	 short MFREE3	; Jump if so

	 shl	 eax,4-0	; Convert from paras to bytes

	 cmp	 eax,esi	; Same as our guy?
	 jne	 short MFREE2	; Jump if not

	 inc	 di		; MAC_MERGESUB needed

; If freeing this MAC will create a hole, convert to @MAC_HOLE instead
; unless 386LOAD is in progress.
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit the last one?
	 je	 short MFREE4	; Jump if so

	 movzx	 eax,AGROUP:[ebx].MAC_NPAR ; Get length of block
	 inc	 ax		; Skip MAC
	 shl	 eax,4-0	; Convert paras to bytes
	 add	 eax,ebx	; Address next MAC

	 push	 eax		; Pass linear address
	 FCALL	 IZIT_MACLINK	; Is GS:EAX a MAC linking entry?
	 je	 short MFREE4	; Jump if so

	 cmp	 AGROUP:[eax].MAC_OWNR,@MAC_SPAN ; Izit the last one in region?
	 je	 short MFREE4	; Jump if so

	 cmp	 AGROUP:[eax].MAC_OWNR,@MAC_FREE ; Izit free?
	 je	 short MFREE4	; Jump if so

	 mov	 cx,@MAC_HOLE	; New MAC_OWNR value
	 jmp	 short MFREE3B	; Convert to @MAC_HOLE unconditionally

MFREE2:
;;;;;;;; mov	 edx,eax	; Save for next time
	 movzx	 eax,AGROUP:[eax].LSEG_NEXT ; Get next segment

	 jmp	 short MFREE1	; Go around again

; EBX = linear address of MAC entry to free
; ESI = linear address of LSEG entry to free and de-link
;;;;; EDX = linear address of LSEG entry which precedes ESI

MFREE3:
;;;;;;;; xor	 esi,esi	; Mark as no LSEG to unlink
	 mov	 cx,@MAC_HOLE	; MAC entry reverts to being a hole
	 cmp	 dx,POVR_MAC	; Are we in high DOS?
	 jb	 short MFREE4	; Jump if not

MFREE3B:
	 call	 LOAD_INPRO	; Is 386LOAD loading it high?
	 jnc	 short MFREE5	; Jump if not

	 sub	 di,di		; Don't merge - let 386LOAD handle it
MFREE4:
	 mov	 cx,@MAC_FREE	; Always free entries in low DOS or
				; when 386LOAD is active
MFREE5:
	 mov	 AGROUP:[ebx].MAC_OWNR,cx ; Mark it as free or hole

; Some programs (like VPRMODE) rely on DOS not merging entries on a
; function 49h (free) call.  They free all their segments (including
; the PSP), then go resident.
	 or	 di,di		; Was the freed segment an LSEG owner?
	 jz	 short MFREE_EXIT ; Jump if not, or if 386LOAD is in progress.

; The preceding LSEG entry is now an orphan and will be freed and
; unlinked in CHECK_ORPHAN in MAC_MERGE

; See if we should merge it into adjacent blocks

	 cmp	 dx,POVR_MAC	; Are we in high DOS?
	 jnb	 short @F	; Jump if so

	 movzx	 ebx,P1ST_MAC.VSEG ; Get start of low DOS MAC
	 shl	 ebx,4-0	; Convert paras to bytes
	 call	 MAC_MERGESUB	; Merge adjacent free entries
	 jmp	 short MFREE_MCOM ; Join common MAC_MERGE code (CF significant)

@@:
	 call	 MAC_MERGE	; Merge adjacent free MACs starting at POVR_MAC
MFREE_MCOM:
	 jnc	 short MFREE_EXIT ; Jump if OK

MFREE_E8F:
	 mov	 al,8Fh 	; MAC arena hosed
	 jmp	 short MFREE_ERR ; Join common error code

MFREE_EB2:
	 mov	 al,0B2h	; Not a valid segment
;;;;;;;  jmp	 short MFREE_ERR ; Join common error code

MFREE_ERR:
	 mov	 [esp].MFREE_EAX.LO,al ; Save for return
	 or	 [esp].MFREE_FLAGS,mask $CF ; Indicate failure

MFREE_EXIT:
	 REGREST <di,esi,cx,ebx,eax> ; Restore
	 popf			; Restore (CF significant)

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MAC_FREE endp			; End MAC_FREE procedure
endif				; IF @OEM_HIFILL

JCODE	 ends			; End JCODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 PGRSEG:word

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

NDATA	 ends			; End NDATA segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

	 public  BUSINT13_VEC
BUSINT13_VEC dd  ?		; Save area for old INT 13h handler

	 public  BUSHNDL,BUSLEN,BUSSEG,BUSPPN
BUSHNDL  dw	 -1		; Bus EMS handle (-1 = not used)
BUSLEN	 dw	 ?		; Length of bus mapping area
BUSSEG	 dw	 ?		; Segment of ...
BUSPPN	 db	 ?		; Buf EMS physical page #

	 public  DPFE_END
	 align	 2
DPFE_END dw	 ?		; Offset of end+1 d:\path\filename.ext (386MAX.SYS)

if @OEM_FLEXROM
	 public  POVR_MAC2
POVR_MAC2 dw	 ?		; Original segment of first MAC in high DOS memory
endif				; IF @OEM_FLEXROM

	 public  FILE_HEAD
FILE_HEAD EXE_STR <>		; File header for .EXE file

	 public  BUSSTK,BUSSTKZ
BUSSTK	 dw	 80h dup (?)	; Local stack for BUSMASTER
BUSSTKZ  label	 word		; End of ...

	 public  OLDBUSSTK_VEC,NEWBUSSTK_VEC
OLDBUSSTK_VEC dd ?		; Old stack pointer
NEWBUSSTK_VEC dd XGROUP:BUSSTKZ ; New ...

	 public  BUSDATA
@BUSVAL  equ	 '?'            ; Common value
BUSDATA  db	 1024 dup (@BUSVAL) ; Local data for bus mapping region comparison

	 public  LCLDPFE
LCLDPFE  db	 80 dup (?)	; Local copy of DPFE

	 public  PLAST_MAC
PLAST_MAC dd	?		; Ending MAC entry in low DOS

XDATA	 ends			; End XDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

	 extrn	 MSG_BUSMASTER:byte
	 extrn	 MSG_PRESS:byte

YDATA	 ends			; End YDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 extrn	 DISP_CPDMSG:far

	 public  @QMAX_MAC_XCODE
@QMAX_MAC_XCODE:		; Mark module start in .MAP file

	 NPPROC  ZMAC_FN52 -- DOS Function 52h Method For Finding Last MAC Entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DOS function 52h method for finding last MAC entry.

This method can be used with DOS 3.x and later.

On exit:

If
CF	 =	 0	we found it
then
AX:0	 ==>	 Head of memory allocation chain
ES:BX	 ==>	 Tail of memory allocation chain
else
CF	 =	 1     we didn't find it
endif

|

	 REGSAVE <dx,si>	; Save registers

	 cmp	 DOSVER,0300h	; Check for DOS 3.x or later
	 jb	 short ZMAC_FN52_NF ; Too early, call it not found

	 DOSCALL @GETLST	; Return with ES:BX ==> list of lists ptr
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es,es:[bx-2]	; Get segment of MAC entry pointer
	 assume  es:nothing	; Tell the assembler about it

	 mov	 si,es		; Save head of MAC

; Point to next MAC entry (if not the last)

ZMAC_FN52_NEXT:

; Ensure we are where we think we should be

	 cmp	 es:[0].MAC_TYPE,'Z' ; Ensure it's the last entry
	 je	 short ZMAC_FN52_CHK ; It is, check it out

	 cmp	 es:[0].MAC_TYPE,'M' ; Maybe it's a middle entry
	 jne	 short ZMAC_FN52_NF ; Not this time

	 mov	 ax,es		; Copy current segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Add in # paragraphs in this entry
	 mov	 es,ax		; Point to next entry
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 ZMAC_FN52_NEXT ; Go around again

ZMAC_FN52_CHK:
	 mov	 dx,es		; Copy current segment
	 inc	 dx		; Count in MAC paragraph
	 add	 dx,es:[0].MAC_NPAR ; Add in # paragraphs in this entry

	 int	 12h		; Get current top of DOS into AX
	 shl	 ax,10-4	; Convert from 1KB to paras

	 cmp	 ax,dx		; Same value?
	 jne	 short ZMAC_FN52_NF ; Not this time

	 mov	 ax,si		; Segment of first entry
	 xor	 bx,bx		; Offset is zero

	 clc			; Indicate we found it

	 jmp	 short ZMAC_FN52_EXIT ; Join common exit code

ZMAC_FN52_NF:
	 stc			; Indicate we didn't find it
ZMAC_FN52_EXIT:
	 REGREST <si,dx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ZMAC_FN52 endp			; End ZMAC_FN52 procedure
	 NPPROC  ZMAC_SRCH -- Search Method For Finding Last MAC Entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search method for finding last MAC entry.

This method can be used with DOS 2.x and later.

On exit:

If
CF	 =	 0	we found it
then
AX:0	 ==>	 Head of memory allocation chain
ES:BX	 ==>	 Tail of memory allocation chain
else
CF	 =	 1     we didn't find it
AX,BX,ES	 Contents destroyed
endif

|

	 REGSAVE <cx,dx,si,di>	; Save registers

; Search for the last MAC entry with a 'Z' on a paragraph boundary
; followed by MAC_PARA which points to the end of memory.

	 xor	 di,di		; Start at 0:0
	 mov	 es,di
	 assume  es:nothing	; Tell the assembler about it

	 mov	 si,ax		; Return value for AX (no way to get first MAC)
	 mov	 cx,-1		; We know it's there
ZMAC_SRCH_NEXT:
	 jcxz	 ZMAC_SRCH_NF	; Use next method
	 mov	 al,'Z'         ; Ending entry signature
   repne scasb			; Search for it
	 jne	 short ZMAC_SRCH_NF ; Not found, so use the next method

	 mov	 bx,di		; Copy offset of next byte
	 dec	 bx		; Back off to 'Z'

	 test	 bx,1111b	; Ensure it's on a para boundary
	 jnz	 ZMAC_SRCH_NEXT ; Not so, go around again

	 shr	 bx,4		; Convert from bytes to paras
	 mov	 dx,es		; Copy current segment
	 add	 dx,bx		; Add 'em up
	 mov	 es,dx		; Point to segment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 bx,bx		; Current offset is zero
	 mov	 di,1		; Next offset is one

;;;;;;;; mov	 dx,es		; Copy current segment
	 inc	 dx		; Count in MAC paragraph
	 add	 dx,es:[bx].MAC_NPAR ; Add in # paragraphs in this entry

	 int	 12h		; Get current top of DOS into AX
	 shl	 ax,10-4	; Convert from 1KB to paras

	 cmp	 ax,dx		; Same value?
	 jne	 ZMAC_SRCH_NEXT ; Not this time

	 mov	 si,es		; Return value for AX

	 clc			; Indicate we found it

	 jmp	 short ZMAC_SRCH_EXIT ; Join common exit code

ZMAC_SRCH_NF:
	 stc			; Indicate we didn't find it
ZMAC_SRCH_EXIT:
	 mov	 ax,si		; Segment of tail or original AX
	 REGREST <di,si,dx,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ZMAC_SRCH endp			; End ZMAC_SRCH procedure
	 NPPROC  ZMAC_DTA -- DTA Method For Finding Last MAC Entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DTA method for finding last MAC entry.

This method can be used with DOS 3.x and later.

On exit:

If
CF	 =	 0	we found it
then
AX:0	 ==>	 Head of memory allocation chain
ES:BX	 ==>	 Tail of memory allocation chain
else
CF	 =	 1     we didn't find it
AX,BX,ES	 Contents destroyed
endif

|

	 REGSAVE <dx,si>	; Save registers

	 cmp	 DOSVER,0300h	; Check for DOS 3.x or later
	 jb	 short ZMAC_DTA_NF ; Too early, call it not found

; Save old and set new DTA

	 DOSCALL @GETDTA	; Return with ES:BX ==> current DTA
	 assume  es:nothing	; Tell the assembler about it

	 sub	 si,si		; Assume we don't find a MAC entry

; Point to next MAC entry (if not the last)

ZMAC_DTA_NEXT:

; Ensure we are where we think we should be

	 or	 si,si		; Did we get a MAC entry yet?
	 jnz	 short @F	; Jump if so

	 mov	 si,es		; Save it
@@:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Ensure it's the last entry
	 je	 short ZMAC_DTA_CHK ; It is, check it out

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Maybe it's a middle entry
	 jne	 short ZMAC_DTA_NF ; Not this time

	 mov	 ax,es		; Copy current segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Add in # paragraphs in this entry
	 mov	 es,ax		; Point to next entry
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 ZMAC_DTA_NEXT	; Go around again

ZMAC_DTA_CHK:
	 mov	 dx,es		; Copy current segment
	 inc	 dx		; Count in MAC paragraph
	 add	 dx,es:[0].MAC_NPAR ; Add in # paragraphs in this entry

	 int	 12h		; Get current top of DOS into AX
	 shl	 ax,10-4	; Convert from 1KB to paras

	 cmp	 ax,dx		; Same value?
	 jne	 short ZMAC_DTA_NF ; Not this time

	 xor	 bx,bx		; Offset is zero
	 mov	 ax,si		; Return segment of first MAC entry

	 clc			; Indicate we found it

	 jmp	 short ZMAC_DTA_EXIT ; Join common exit code

ZMAC_DTA_NF:
	 stc			; Indicate we didn't find it
ZMAC_DTA_EXIT:
	 REGREST <si,dx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ZMAC_DTA endp			; End ZMAC_DTA procedure
	 FPPROC  FINDZMAC -- Find End of Memory Allocation Chain
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the end of the Memory Allocation Chain.

On exit:

CF	 =	 0 if we found it
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,es>	; Save registers

	 test	 NRD_FLAG,@NRD_MAC ; Found the last time?
	 jnz	 short FINDZMAC_EXIT ; Yes, use it (note CF=0)

	 call	 ZMAC_FN52	; Use DOS function 52h
	 assume  es:nothing	; Tell the assembler about it
	 jnc	 short FINDZMAC_SAVE ; Jump if we found it

	 call	 ZMAC_SRCH	; Use search method
	 assume  es:nothing	; Tell the assembler about it
	 jnc	 short FINDZMAC_SAVE ; Jump if we found it

	 call	 ZMAC_DTA	; Use DTA method
	 assume  es:nothing	; Tell the assembler about it
	 jnc	 short FINDZMAC_SAVE ; Jump if we found it

	 stc			; Indicate we failed

	 jmp	 short FINDZMAC_EXIT ; Join common exit code

FINDZMAC_SAVE:
.8086
	 mov	 PLAST_MAC.VOFF,bx ; Save for later use
	 mov	 PLAST_MAC.VSEG,es
DOT386 p
	 mov	 P1ST_MAC.VSEG,ax ; First MAC entry
	 mov	 P1ST_MAC.VOFF,0

	 or	 NRD_FLAG,@NRD_MAC ; Indicate we found it

	 clc			; Indicate success
FINDZMAC_EXIT:
	 REGREST <es,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDZMAC endp			; End FINDZMAC procedure
	 FPPROC  DECR_MAC -- Decrement Memory Allocation Chain
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Decrement the # paragraphs in the last entry in the memory allocation chain
and create high DOS memory allocation chain entries.

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save segment registers

	 call	 FINDZMAC	; P1ST_MAC = 1st MAC entry, PLAST_MAC = last
	 jc	 near ptr DECR_MAC_EXIT ; Not found???

	 les	 bx,PLAST_MAC	; ES:BX ==> final entry in MAC
	 assume  es:nothing	; Tell the assembler

	 mov	 dx,es		; Copy current segment
	 inc	 dx		; Count in MAC paragraph
	 add	 dx,es:[bx].MAC_NPAR ; Add in # paragraphs in this entry

	 int	 12h		; Get current top of DOS into AX
	 shl	 ax,10-4	; Convert from 1KB to paras

	 cmp	 ax,dx		; Same value?
	 jne	 near ptr DECR_MAC_EXIT ; Not this time

	 mov	 bx,es		; Save as back pointer
	 dec	 dx		; Back off to last paragraph
	 mov	 es,dx		; ES:0 ==> DOS's last MAC entry
	 assume  es:nothing	; Tell the assembler about it

; Insert the MCS entries into the allocation chain

	 xor	 si,si		; Initialize index into MCSTAB
				; ES:0 ==> top entry in last MAC block
	 mov	 cx,MCSTAB_CNT	; CX = # entries in MCSTAB
	 mov	 dx,1		; Set initial flag to skip first entry
DECR_MAC_ALLOC:
	 test	 MCSTAB.MCS_FLAG[si],@MCS_AVAIL ; Izit available?
	 jz	 short DECR_MAC_INUSE ; No, it's in use

; Finish up top entry in last MAC block if not the first entry

	 cmp	 dx,1		; Izit the first entry?
	 je	 short @F	; Jump if so

	 mov	 ax,es		; Copy para # of last entry
	 sub	 ax,MCSTAB.MCS_PARA[si] ; Less para # of this entry
	 neg	 ax		; Difference is size of this entry
	 dec	 ax		; Less MAC entry
	 mov	 es:[0].MAC_TYPE,@MAC_MID ; Mark as middle entry
	 mov	 es:[0].MAC_OWNR,@MAC_SPAN ; Mark as spanning entry
	 mov	 es:[0].MAC_NPAR,ax ; Save as # paras
@@:
	 xor	 dx,dx		; Mark as no longer first MAC entry

	 mov	 bx,es		; Save as back pointer

; Address and fill in bottom entry in this MAC block

	 mov	 es,MCSTAB.MCS_PARA[si] ; ES:0 ==> this entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,MCSTAB.MCS_NPAR[si] ; Get # paras in this entry
	 dec	 ax		; Less one for first MAC entry
	 dec	 ax		; Less one for last MAC entry
	 mov	 es:[0].MAC_TYPE,@MAC_MID ; Mark as middle entry
	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Indicate no owner
	 mov	 es:[0].MAC_NPAR,ax ; Save as # paras in this entry
	 mov	 es:[0].MAC_BACK,bx ; Save back pointer
	 mov	 bx,es		; Save as back pointer

; Address top entry in this MAC block and fill in back pointer

	 mov	 ax,es		; Get para # of this entry
	 add	 ax,MCSTAB.MCS_NPAR[si] ; Add in # paras in this entry
	 dec	 ax		; Less one for last MAC entry
	 mov	 es,ax		; ES:0 ==> last entry in this block
	 mov	 es:[0].MAC_BACK,bx ; Save back pointer
DECR_MAC_INUSE:
	 add	 si,size MCS_STR ; Skip to next entry

	 loop	 DECR_MAC_ALLOC ; Jump if more entries

	 cmp	 dx,1		; Izit still the first entry?
	 je	 short DECR_MAC_DONE ; Jump if so

	 mov	 es,es:[0].MAC_BACK ; ES:0 ==> previous entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].MAC_TYPE,@MAC_END ; Mark as last one in chain
	 inc	 es:[0].MAC_NPAR ; Count in last para
DECR_MAC_DONE:

if @OEM_FLEXROM

; If FLEXROM is in effect and FLEX_SRC is at C000 and C000 starts
; a MAC entry, subtract out the first @VGAHDR bytes from the MAC entry
; at C000 and copy the corresponding amount of data from FLEX_DST

	 test	 FLEXROM_FLAG,@FR_VGA ; Is a VGA being FLEXed?
	 jz	 near ptr DECR_MAC_EXIT ; Jump if not

	 test	 FLEXROM_FLAG,@FR_VID_C000 ; Is there a video ROM at C000?
	 jz	 short DECR_MAC_EXIT ; Jump if not

	 test	 FLEXROM_FLAG,@FR_NOGORE ; Dis the user request "No gore"?
	 jnz	 short DECR_MAC_EXIT ; Jump if so

	 xor	 bx,bx		; Initialize index into FLEXROM_TBL
DECR_MAC_FLEXNEXT:
	 test	 FLEXROM_TBL.FLEX_FLAG[bx],@FLEXFLAG_VGA ; Izit a VGA?
	 jnz	 short DECR_MAC_FLEXFND ; Jump if so

	 add	 bx,@FLEXROM_STRLEN ; Skip to next entry

	 cmp	 bx,FLEXROM_LEN ; Izit the end?
	 jb	 short DECR_MAC_FLEXNEXT ; Jump if there's more

	 jmp	 short DECR_MAC_EXIT ; Jump if no VGAs being flexed today

DECR_MAC_FLEXFND:
; Note: The source might not be at C000 if the ROM is shadowed at E000
;	We can ignore the source since we already checked @FR_VID_C000 flag

;;;;;;;; cmp	 FLEXROM_TBL.FLEX_SRC[bx],0C000h ; Duzit start at C000?
;;;;;;;; jne	 short DECR_MAC_EXIT ; Jump if not

; Check for a MAC entry at C000

	 mov	 ax,POVR_MAC2	; Get original segment of 1st MAC in high DOS
	 mov	 dx,-1		; Initialize segment of previous MAC entry
DECR_MAC_MACNEXT:
	 mov	 es,ax		; Get segment of MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 ax,0C000h	; Izit our boy?
	 je	 short DECR_MAC_MACFND ; Jump if so

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the end?
	 je	 short DECR_MAC_EXIT ; Jump if so

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 jne	 short DECR_MAC_EXIT ; Jump if not (huh???)

	 mov	 dx,es		; Save segment of previous MAC entry

	 inc	 ax		; Count in the MAC entry
	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in MAC entry

	 jmp	 short DECR_MAC_MACNEXT ; Go around again

; MAC entry at C000 found:  DX has segment of previous MAC entry

DECR_MAC_MACFND:

; Copy old MAC entry to new location

	 xor	 si,si		; ES:SI ==> source of MAC entry
	 mov	 di,@VGAHDR	; ES:DI ==> destin ...
	 mov	 cx,size MAC_STR ; CX = # bytes in ...
S16  rep movs	 <es:[di].LO,es:[si].LO> ; Copy old MAC entry to new location

; Copy the first @VGAHDR bytes from FLEX_DST to ES:0

	 push	 ds		; Save for a moment

	 mov	 ds,FLEXROM_TBL.FLEX_DST[bx] ; Get destin segment
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 cx,@VGAHDR	; CX = # bytes to copy
	 xor	 si,si		; DS:SI ==> source of ROM signature
	 xor	 di,di		; ES:DI ==> destin ...
S16  rep movs	 <es:[di].LO,ds:[si].LO> ; Copy VGA ROM signature to new location

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

; Change the length byte of this pseudo-ROM to reflect its size

	 assume  es:ROMSEG	; Tell the assembler about it
	 mov	 ROMLEN,@VGAHDR/512 ; Set length in units of 512 bytes
	 assume  es:nothing	; Tell the assembler about it

; Delete the first @VGAHDR bytes from this MAC entry

	 sub	 es:[@VGAHDR].MAC_NPAR,@VGAHDR/16 ; Reduce the # paras

; If there's a previous MAC entry it must be a spanning entry:
;   adjust its size by @VGAHDR/16 paras
; If not, the MAC entry at C000 is the first one:
;   POVR_MAC has already been adjusted by @VGAHDR/16 paras

	 cmp	 dx,-1		; Is there a previous MAC entry?
	 je	 short DECR_MAC_EXIT ; Jump if not

	 mov	 es,dx		; Address previous MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 add	 es:[0].MAC_NPAR,@VGAHDR/16 ; Increase the # paras
endif				; IF @OEM_FLEXROM
DECR_MAC_EXIT:
	 REGREST <es,ds>	; Restore segment registers
	 assume  ds:nothing,es:nothing
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DECR_MAC endp			; End DECR_MAC procedure
	 FPPROC  BUSMASTER -- Check For Busmaster Hard Disks
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for busmaster hard disks

Search through high DOS memory for a free chunk which is guaranteed
not to be one-to-one with physical memory.  Read from the hard disk
into this memory.  If the data does not match the actual contents from
the hard disk, there's a busmaster hard disk in the system and we had
better tell the user before he calls us.

|

	 REGSAVE <ds,es>	; Save segment registers

	 push	 seg XGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 push	 seg XGROUP	; Get our data segment
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

; Switch to local stack

	 mov	 OLDBUSSTK_VEC.VOFF,sp ; Save old pointer
	 mov	 OLDBUSSTK_VEC.VSEG,ss

	 lss	 sp,NEWBUSSTK_VEC ; Load up new stack
	 assume  ss:nothing	; Tell the assembler about it

	 pusha			; Save all GP registers

; Search for EMS of high DOS memory

	 CPD	 'Calling SRCHMEM, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 SRCHMEM	; Search for it
	 jc	 near ptr BUSMASTER_EXIT ; Jump if not found

	 CPD	 'Resetting disk subsystem, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 DOSCALL @DRESET	; Reset the disk subsystem to flush the buffers

	 push	 ds		; Save for a moment

	 push	 seg PGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 lds	 si,RH_VEC	; DS:SI ==> request header
	 assume  ds:nothing	; Tell the assembler about it

	 lds	 dx,ds:[si].INIT_CMD_VEC ; DS:DX ==> d:\path\filename.ext [args]
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 si,DPFE_END	; Get offset of end of DPFE

; Read from the disk into this area of high DOS

	 CPD	 'Opening file for read, CS:IP=%CS:%IP  DS:DX=%DS:%DX  ES=%ES'

	 mov	 bl,0		; ASCIIZ string terminator
	 xchg	 bl,ds:[si]	; Terminate it
	 mov	 al,@OPEN_R	; Function code for read-only
	 DOSCALL @OPENF2	; Open the file
	 xchg	 bl,ds:[si]	; Restore
	 pop	 ds		; Restore
	 assume  ds:XGROUP	; Tell the assembler about it
	 jc	 near ptr BUSMASTER_EXIT ; Jump if something went wrong

	 mov	 bx,ax		; Copy to handle register

; Read in the file header to get start of file

	 CPD	 'Reading file header, CS:IP=%CS:%IP  DS:DX=%DS:%DX  ES=%ES'

	 mov	 cx,size EXE_STR ; Get size of structure to read in
	 DOSCALL @READF2,FILE_HEAD ; Read it in
	 jc	 near ptr BUSMASTER_CLOSE ; Jump if something went wrong

; Move file pointer to BUSDATA

	 mov	 cx,seg XGROUP	; Get segment of BUSDATA
	 sub	 cx,seg PGROUP	; Less segment of start of file

	 cmp	 FILE_HEAD.EXE_SIGN,@EXE_SIGN ; Izit an .EXE file?
	 jne	 short @F	; Jump if not

	 add	 cx,FILE_HEAD.EXE_HSIZ ; Plus size of header in paras
@@:
	 mov	 dx,cx		; Copy as low-order
	 shl	 dx,4-0 	; Convert from paras to bytes
	 shr	 cx,16-4	; Convert from paras to bytes
	 add	 dx,offset XGROUP:BUSDATA ; Plus its offset
	 adc	 cx,0		; In case of overflow

	 CPD	 'Moving file pointer, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 al,0		; Function code to move relative to start of file
	 DOSCALL @MOVFP2	; Move pointer to CX:DX using method in AL
	 jc	 short BUSMASTER_CLOSE ; Jump if something went wrong

; Read the file from the disk into high DOS memory

	 mov	 cx,BUSLEN	; Get length in bytes

	 cmp	 cx,size BUSDATA; Use the smaller of the two
	 jbe	 short @F	; Jump if high DOS memory chunk is smaller

	 mov	 cx,size BUSDATA; Use the size of our code
@@:
	 mov	 ds,BUSSEG	; Get bus mapping segment
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 dx,dx		; DS:DX ==> bus mapping area

	 CPD	 'Reading file into high DOS, CS:IP=%CS:%IP  DS:DX=%DS:%DX  ES=%ES'

	 DOSCALL @READF2	; Read into high DOS at DS:DX
	 jc	 short BUSMASTER_CLOSE ; Jump if something went wrong

	 mov	 es,BUSSEG	; Get bus mapping segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 di,dx		; ES:DI ==> high DOS memory copy

; Compare the contents

	 CPD	 'Verifying data in high DOS, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 al,@BUSVAL	; Get common value
    repe scas	 es:[di].LO	; Search for it
	 je	 short BUSMASTER_CLOSE ; Jump if all OK

	 push	 seg YGROUP	; Get our code segment
	 pop	 ds		; Address it for @STROUT
	 assume  ds:YGROUP	; Tell the assembler about it

	 DOSCALL @STROUT,MSG_BUSMASTER ; Tell 'em the bad news
	 DOSCALL @STROUT,MSG_PRESS ; Tell 'em to press a key

; Purge the keyboard buffer and wait for a key press -- discard the key

	 call	 FKEYWAIT	; Wait for an acknowledgement
				; Return with key in AX

	 push	 seg PGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ds,PGRSEG	; Get segment of our program (might be in high DOS)
	 assume  ds:PGROUP	; Tell the assembler about it

	 or	 CM2_FLAG,@CM2_XSCSI ; Mark as busmaster present
BUSMASTER_CLOSE:
	 assume  ds:nothing	; Tell the assembler about it

	 DOSCALL @CLOSF2	; Close it up
BUSMASTER_EXIT:
	 push	 seg XGROUP	; Get our code segment
	 pop	 ds		; Address it for @STROUT
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 dx,BUSHNDL	; Get EMS handle if any

	 cmp	 dx,-1		; Izit in use?
	 je	 short @F	; Jump if not

	 mov	 bx,@RPN_UNMAP	; Unmap the pages
	 mov	 al,BUSPPN	; Get physical page #

	 CPD	 'Unmapping one page, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 EMMCALL @EMM_MAPHNPG	; Unmap handle/page
				; Ignore any error return

	 CPD	 'Deallocating one page, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 EMMCALL @EMM_RLSPAGE	; De-allocate the handle
				; Ignore any error return
@@:
	 popa			; Restore all GP registers

	 lss	 sp,OLDBUSSTK_VEC ; Load up old stack
	 assume  ss:nothing	; Tell the assembler about it

	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BUSMASTER endp			; End BUSMASTER procedure
	 NPPROC  SRCHMEM -- Search For EMS Or High DOS Memory
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search for EMS or high DOS memory.
We're looking for memory not mapped one-to-one.

The memory we want can come from

* EMS page frame
* other EMS-mappable memory
* high DOS memory

On exit:

CF	 =	 0 if memory found
	 =	 1 if none available
DS:0	 ==>	 available memory

|

	 REGSAVE <ax,bx,dx,si,ds,es> ; Save registers

	 push	 seg XGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 push	 seg PGROUP	; Get our data segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Skip this routine if we're OFF

	 test	 GLB_FLAG,@GLB_ON or @GLB_AUTO ; Are we ON or AUTO?
	 jz	 near ptr SRCHMEM_ERR ; Jump if not

	 cmp	 EMMSIZE,0	; Any EMS memory?
	 je	 short SRCHMEM_OVR ; No, try for high DOS memory

; First check for EMS page frame

	 cmp	 NPHYS16F,0	; Any pages in the frame?
	 je	 short SRCHMEM_MAP ; No, try alternate memory

; Ensure the page frame isn't in conventional memory

	 EMMCALL @EMM_GETPGFR	; Get the address of the page frame
				; in BX paras

	 cmp	 ah,0		; Izit in error?
	 jne	 short SRCHMEM_MAP ; Jump if error to alternate memory

	 cmp	 bx,OLDDOS	; Izit in conventional memory?
	 jb	 short SRCHMEM_MAP ; Jump if so to alternate memory

	 mov	 BUSSEG,bx	; Save as segment
	 mov	 BUSLEN,16*1024 ; Save as length

; Allocate and map one EMS page

	 CPD	 'Allocating one page, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 bx,1		; One logical page
	 EMMCALL @EMM_SETPAGE	; Allocate it, return handle in DX

	 cmp	 ah,0		; Izit in error?
	 jne	 short SRCHMEM_OVR ; Jump if error to alternate memory

	 mov	 BUSHNDL,dx	; Save for later use

	 CPD	 'Mapping one page, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 al,0		; Physical page #0
	 mov	 BUSPPN,al	; Save for later use
	 mov	 bx,0		; Logical page #0
	 EMMCALL @EMM_MAPHNPG	; Map handle DX log page BX to phys page AL

	 cmp	 ah,0		; Izit in error?
	 je	 short SRCHMEM_CLC ; Jump if not

	 jmp	 short SRCHMEM_ERR1 ; Jump if error (release handle)

; Second, check for other EMS-mappable pages

SRCHMEM_MAP:










; Third, check for high DOS memory

SRCHMEM_OVR:
	 mov	 ax,POVR_MAC	; Get the segment of first MAC in high DOS

	 cmp	 ax,-1		; Izit valid?
	 je	 near ptr SRCHMEM_ERR ; Jump if not

	 xor	 dx,dx		; Zero largest UMB size
				; SI has the corresponding MAC segment
SRCHMEM_OVRNEXT:
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 short SRCHMEM_OVRINC ; Jump if not

; ES:0 ==> free MAC entry

	 cmp	 dx,es:[0].MAC_NPAR ; Check against the largest size so far
	 jae	 short SRCHMEM_OVRINC ; Jump if new size is no larger

	 mov	 dx,es:[0].MAC_NPAR ; Set as new largest size
	 mov	 si,es		; Save segment of MAC entry
SRCHMEM_OVRINC:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the last entry?
	 je	 short SRCHMEM_OVREND ; Jump if so

	 inc	 ax		; Skip over MAC entry
	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in this entry

	 jmp	 short SRCHMEM_OVRNEXT ; Go around again

SRCHMEM_OVREND:
	 and	 dx,dx		; Did we find any high DOS?
	 jz	 short SRCHMEM_ERR ; Jump if not

	 cmp	 dx,0FFFh-1	; Izit bigger than 64KB-16 (for MAC entry)?
	 jbe	 short @F	; Jump if not

	 mov	 dx,0FFFh-1	; Use smaller
@@:
	 shl	 dx,4-0 	; Convert from paras to bytes
	 mov	 BUSLEN,dx	; Save as length

	 inc	 si		; Skip over the MAC entry
	 mov	 BUSSEG,si	; Save as segment
SRCHMEM_CLC:
	 clc			; Indicate DS valid

	 jmp	 short SRCHMEM_EXIT ; Join common exit code

SRCHMEM_ERR0:
	 EMMCALL @EMM_RESTMAP	; Restore page map
SRCHMEM_ERR1:
	 EMMCALL @EMM_RLSPAGE	; De-allocate the handle
	 mov	 BUSHNDL,-1	; Mark as unused
SRCHMEM_ERR:
	 stc			; Indicate something went wrong
SRCHMEM_EXIT:
	 REGREST <es,ds,si,dx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCHMEM  endp			; End SRCHMEM procedure

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_MAC module

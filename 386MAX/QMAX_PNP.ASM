;' $Header:   P:/PVCS/MAX/386MAX/QMAX_PNP.ASV   1.1   30 May 1997 10:45:52   BOB  $
	title	QMAX_PNP -- 386MAX Plug 'n Play Routines
	page	58,122
	name	QMAX_PNP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1995-7 Qualitas, Inc.  GNU General Public License version 3.

Program derived from:  None.

Original code by:  Bob Smith, September, 1995.

Modifications by:  None.

|

.386
.xlist
	include MASM.INC
	include PTR.INC
	include DTE.INC
	include PNP.INC
	include ALLMEM.INC

	include QMAX_DTE.INC
.list

PGROUP	group	CODE,ECODE,EDATA
XGROUP	group	XCODE


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	ds:PGROUP

	extrn	CM2_FLAG:word
	include QMAX_CM2.INC

	extrn	SYSROM_START:word

CODE	ends			; End CODE segment


EDATA	segment use16 dword public 'edata' ; Start EDATA segment
	assume	cs:PGROUP

	extrn	SEL_4GB:word
	extrn	PRGBASE:dword
	extrn	VCPIBASE:dword

	public	OffPnP_RMVEC,OffPnP_PMCS,OffPnP_PMOFF
OffPnP_RMVEC dd PnP_RMVEC	; Offset to PnP_RMVEC in PnP_STR or PnP2_STR
OffPnP_PMCS  dd PnP_PMCS	; ...	    PnP_PMCS  ...
OffPnP_PMOFF dd PnP_PMOFF	; ...	    PnP_PMOFF ...

	public	LaPnP_BIOS,LaPnP_PMCS,LaPnP_PMDS,PnP_VCPI_DIFF
LaPnP_BIOS dd	?		; Linear address of PnP BIOS in extended memory
LaPnP_PMCS dd	?		; ...			PM code segment base
LaPnP_PMDS dd	?		;			   data ...
PnP_VCPI_DIFF dd ?		; Difference between PnP BIOS with and without VCPI

	public	PnP_VEC
PnP_VEC dd     ?		; Sel|Off of PnP BIOS entry point

	public	PnP_SEG,PnP_DATA
PnP_SEG dw	0		; PnP struc segment in BIOS (0=none)
PnP_DATA dw	0		; ...	    data segment (0=none)

EDATA	ends			; End EDATA segment


ECODE	segment use16 dword public 'ecode' ; Start ECODE segment
	assume	cs:PGROUP

	public	@QMAX_PNP_ECODE
@QMAX_PNP_ECODE:		; Mark module start in .MAP file

	NPPROC	PnP_TO_VCPI -- Handle PnP Issues Upon Entering PM Via VCPI
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Handle PnP Issues Upon Entering PM Via VCPI

|

	REGSAVE <eax,ebx,edi>	; Save registers

; Convert PnP code and data base addresses from MAX's GDT
; to the VCPI's GDT

	movzx	edi,PnP_SEG	; Get the PnP struc segment in BIOS
	shl	edi,4-0 	; Conevrt from paras to bytes
	jz	short PnP_TO_VCPI_EXIT ; Jump if not present

	mov	eax,LaPnP_PMCS	; Get the current value
	sub	eax,PRGBASE	; Less linear address of our base
	add	eax,VCPIBASE	; Plus linear address of our VCPI base
	add	eax,PnP_VCPI_DIFF ; Plus differencing value
	mov	ebx,OffPnP_PMCS ; Get offset to PnP_PMCS
	mov	AGROUP:[edi+ebx],eax ; Save back for VCPI clients

	cmp	AGROUP:[edi].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short PnP_TO_VCPI_EXIT ; Join common code (no PMDS in old struc)

	mov	eax,LaPnP_PMDS	; Get the current value

	cmp	eax,@PnP_BIOS_BEG ; Izit below the BIOS?
	jb	short @F	; Jump if so (no change)

	sub	eax,PRGBASE	; Less linear address of our base
	add	eax,VCPIBASE	; Plus linear address of our VCPI base
	add	eax,PnP_VCPI_DIFF ; Plus differencing value
	mov	AGROUP:[edi].PnP_PMDS,eax ; Save back for VCPI clients
@@:
PnP_TO_VCPI_EXIT:
	REGREST <edi,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PnP_TO_VCPI endp		; End PnP_TO_VCPI procedure
	NPPROC	PnP_FR_VCPI -- Handle PnP Issues Upon Returning From PM Via VCPI
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle PnP Issues Upon returning from PM Via VCPI

On exit:

GS clobbered

|

	REGSAVE <eax,ebx,edi>	; Save registers

	movzx	edi,PnP_SEG	; Get the PnP struc segment in BIOS
	shl	edi,4-0 	; Convrt from paras to bytes
	jz	short PnP_FR_VCPI_EXIT ; Jump if not present

	mov	gs,SEL_4GB	; Get our all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	mov	eax,LaPnP_PMCS	; Get the original value
	mov	ebx,OffPnP_PMCS ; Get offset to PnP_PMCS
	mov	AGROUP:[edi+ebx],eax ; Save back for DPMI clients

	cmp	AGROUP:[edi].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short PnP_FR_VCPI_EXIT ; Join common code (no PMDS in old struc)

	mov	eax,LaPnP_PMDS	; Get the original value
	mov	AGROUP:[edi].PnP_PMDS,eax ; Save back for DPMI clients
PnP_FR_VCPI_EXIT:
	REGREST <edi,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PnP_FR_VCPI endp		; End PnP_FR_VCPI procedure

ECODE	ends			; End ECODE segment


XCODE	segment use16 byte public 'xcode' ; Start XCODE segment
	assume	cs:XGROUP

	public	@QMAX_PNP_XCODE
@QMAX_PNP_XCODE:		; Mark module start in .MAP file

	NPPROC	IZIT_PnP -- Is There A Plug 'n Play BIOS
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine Plug 'n Play availability

If this is a PnP BIOS, somewhere in the BIOS on a para boundary
is the PnP structure with a matching checksum.

|

	REGSAVE <ax,cx,si,ds>	; Save registers

	test	CM2_FLAG,@CM2_NOPnP ; Izit disabled?
	jnz	near ptr IZIT_PnP_EXIT ; Jump if so

	mov	cx,SYSROM_START ; Segment of start of ROM (paras)
	mov	ds,cx		; Address it
	assume	ds:nothing	; Tell the assembler about it

	neg	cx		; Get length of BIOS in paras
	xor	si,si		; Initialize index into BIOS
@@:
	cmp	ds:[si].EDD,@PnP_SIGREV ; Duzit have the right signature?
	je	short IZIT_PnP_SUM ; Jump if so
IZIT_PnP_SKIP:
	add	si,16		; Skip to next para

	loop	@B		; Jump if more paras to check

	jmp	short IZIT_PnP_EXIT ; Join common exit code

IZIT_PnP_SUM:

; Validate the checksum

	REGSAVE <cx,si> 	; Save for a moment

	movzx	cx,ds:[si].PnP_LEN ; Get the structure's byte length
	mov	ah,0		; Initialize the checksum accumulator
@@:
	lods	ds:[si].LO	; Get the next byte
	add	ah,al		; Add into accumulator
	loop	@B		; Jump if more bytes to checksum

	REGREST <si,cx> 	; Restore

	cmp	ah,0		; Duzit match?
	jne	short IZIT_PnP_SKIP ; Jump if not

; Ensure it's a version 1.0 struc

	cmp	ds:[si].PnP_VER,10h ; Izit version 1.0?
	jne	short IZIT_PnP_SKIP ; Jump if not

; Ensure it's one of the two type strucs we support

	mov	ax,ds:[si].PnP_PMOFF ; Get offset of PM entry point
	mov	cx,ds:[si].PnP_RMDS ; Get RM data segment

	cmp	ds:[si].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F	; Jump if so

	mov	ax,ds:[si].PnP2_PMOFF ; Get offset of PM entry point

	cmp	ds:[si].PnP_LEN,size PnP2_STR ; Izit old struc?
	jne	short IZIT_PnP_SKIP ; Jump if not

	mov	OffPnP_RMVEC,PnP2_RMVEC ; Save as offset
	mov	OffPnP_PMCS, PnP2_PMCS	; ...
	mov	OffPnP_PMOFF,PnP2_PMOFF ; ...
	xor	cx,cx		; No RMDS in old struc
@@:
	mov	PnP_VEC.VOFF,ax ; Save for later use
	mov	PnP_VEC.VSEG,DTE_PnPCS ; ...
	mov	PnP_DATA,cx	; Save for later use

	mov	ax,ds		; Copy the segment
	shr	si,4-0		; Convert from bytes to paras
	add	ax,si		; Add to get the segment
	mov	PnP_SEG,ax	; Save for later use
IZIT_PnP_EXIT:
	REGREST <ds,si,cx,ax>	; Restore
	assume	ds:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_PnP endp			; End IZIT_PnP procedure

XCODE	ends			; End XCODE segment

	MEND			; End QMAX_PNP module

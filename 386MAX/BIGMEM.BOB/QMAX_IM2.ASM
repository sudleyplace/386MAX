;' $Header:   P:/PVCS/MAX/386MAX/QMAX_IM2.ASV   1.3   30 May 1997 10:45:08   BOB  $
	title	QMAX_IM2 -- 386MAX INT 67h Handler, IMM2 Functions
	page	58,122
	name	QMAX_IM2

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-2002 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Data    segment ZDATA, para-aligned,  public, class 'zdata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'
	       Group SGROUP:
	       Program segment SCODE, para-aligned,  public, class 'scode'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Program segment IDATA, dword-aligned, public, class 'idata'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Data    segment JDATA, dword-aligned, public, class 'jcode'

Program derived from:  QMAX_EM2.ASM.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include CPUID.INC
	include BIOSDATA.INC
	include MASM5.MAC
	include ALLMEM.INC
	include DEVDRV.INC
	include INTVEC.INC
	include VDS.INC
	include WIN3PAGE.INC
NOVER_HTU = 1
	include VERSION.INC
	include VDISK.INC
	include MAC.INC
	include 8259.INC
	include VMVSAPI.INC
	include CPUFET.INC
	include IOTRAP.INC

	include LOAD_SEG.INC
	include QMAXDPMI.INC
	include QMAX_CFG.INC
	include QMAX_DTE.INC
	include QMAX_I31.INC
	include QMAX_LOD.INC
	include QMAX_OEM.INC
	include QMAX_TRC.INC
	include QMAX_TSS.INC
	include QMAX_RAM.INC
	include QMAX_FLX.INC
	include PDTGRP.INC
.list

PGROUP	group	CODE,HICODE,ECODE,EDATA,ZDATA
FGROUP	group	FDATA
SGROUP	group	SCODE
IGROUP	group	LCODE,ICODE,IDATA
JGROUP	group	JCODE,JDATA
CGROUP	group	CPUID_SEG


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

if @OEM_WIN3
if @OEM_EMS
	extrn	RESINT67:near
	extrn	DUMMY_INT67:far
endif				; IF @OEM_EMS
	extrn	WIN3_CB_GOREAL:near
	extrn	WIN3_CB:far

	extrn	DEVDRV:tbyte
endif				; IF @OEM_WIN3

	extrn	CMD_FLAG:word
	include QMAX_CMD.INC

	extrn	CM2_FLAG:word
	include QMAX_CM2.INC

	extrn	CM3_FLAG:word
	include QMAX_CM3.INC

	extrn	DBG_FLAG:word
	include QMAX_DBG.INC

	extrn	DB2_FLAG:word
;;;;;;; include QMAX_DB2.INC

	extrn	GLB_FLAG:word
	include QMAX_GLB.INC

if @OEM_HIFILL and @OEM_WIN3
	extrn	QMAX_VER:byte
	include QMAX_HDM.INC
endif				; IF @OEM_HIFILL and @OEM_WIN3

	extrn	LCL_FLAG:word
	include QMAX_LCL.INC

	extrn	XMS_FLAG:word
	include QMAX_XMS.INC

if @OEM_WIN3
	extrn	LOADSEG:word
	extrn	STKPTR:dword
	extrn	OLDDOS:word
	extrn	LOWWIN3_CB:byte
	extrn	WIN3_STARTUP:tbyte
endif				; IF @OEM_WIN3
	extrn	TOTSIZE:dword
	extrn	LOWSIZE:word
	extrn	OVRSIZE:word
	extrn	EXTSIZE:dword
	extrn	MAPSIZE:word
if @OEM_EMS
	extrn	EMMSIZE:dword
endif				; IF @OEM_EMS
	extrn	IDT_REAL:fword
	extrn	PRGSIZE:word
;;;;;;; extrn	SHDSIZE:word
	extrn	SYSROM_START:word
	extrn	POVR_MAC:word

CODE	ends			; End CODE segment


HICODE	segment use16 dword public 'prog' ; Start HICODE segment
	assume	ds:PGROUP

	extrn	EX2SIZE:dword
if @OEM_WIN3
	extrn	WIN3_VERSION:word
endif				; IF @OEM_WIN3
	extrn	HOOK13:byte
	extrn	@HOOK13_OFF:abs
	extrn	@HOOK13_INACT:abs
	extrn	@HOOK13_ACTIV:abs

HICODE	ends			; End HICODE segment


EDATA	segment use16 dword public 'edata' ; Start EDATA segment
	assume	ds:PGROUP

	extrn	MAPTAB:tbyte,MAPTAB_CNT:word
	include QMAX_MAP.INC

	extrn	I15_FLAG:word
	include QMAX_I15.INC

	extrn	PDSTKCOM:dword
	extrn	LaDSTK_TAB:dword
	extrn	DSTK_CNT:word
	extrn	DSTK_ISIZ:word
	extrn	DSTK_HWINTS:byte
	extrn	DSTK_FLAG:byte

if @OEM_WIN3
	extrn	PCFGFILE:dword
	extrn	CFG_CNT:word
	extrn	AMRS_TAB:byte
	extrn	@AMRS_INUSE:abs
	extrn	MRS_MAX:word

	extrn	SEL_4GB3:word
	include EMM2CALL.INC

	extrn	WIN3_REF_DATA:tbyte
	include QMAXWIN3.INC

	extrn	A20CNT:dword
	extrn	@A20DEF:abs

	extrn	PHYSIZE:dword
	extrn	WINSIZE:dword
endif				; IF @OEM_WIN3
	extrn	FILES_STR_LEN:byte
	extrn	PRGBASE:dword
	extrn	TOPBASE:dword
	extrn	SEL_DSIG3:word
	extrn	SEL_DSFG3:word
	extrn	SEL_DSHI:word
if @OEM_EMS
if @OEM_WIN3
	extrn	FRAME:word
	extrn	RPNCURSIZ:word
endif				; IF @OEM_WIN3
	include QMAX_EMM.INC
endif				; IF @OEM_EMS

if @OEM_XMS
	extrn	CMPSIZEMM:dword
	extrn	PXMSBASE:dword
	extrn	PXMSSIZE:dword
	extrn	PXMSHNDL:dword
	extrn	XMSNHNDL:word
	extrn	@H_INUSE:abs
endif				; IF @OEM_XMS

	extrn	LCLMEM:byte
	extrn	LCLMEM_LEN:abs
	extrn	PDBSIZE:dword
	extrn	OFFCR3:dword
	extrn	PPL0STK_INI:dword
	extrn	PPL0STK_MAP:dword
	extrn	PPL0STK_MAX:dword
	extrn	PVMTSS:dword
	extrn	@IOMAP:abs
if @OEM_DMA
	extrn	PPDTDMAP:dword,PPDTDMA:dword
endif				; IF @OEM_DMA
if @OEM_EMS
	extrn	PHNDLPAGE:dword
	extrn	PHNDLCNT:dword
	extrn	PPAGELINK:dword
	extrn	PLINKBASE:dword
	extrn	PHNDLNAME:dword
	extrn	PPHYS2SEG:dword
	extrn	PSEG2PHYS:dword
endif				; IF @OEM_EMS
	extrn	PPDTCNV:dword
	extrn	PPDTMAP:dword
if @OEM_EMS
	extrn	PPDTEMM:dword
endif				; IF @OEM_EMS
	extrn	PPDT1MB:dword
	extrn	PPDT1P1MB:dword
	extrn	CON1KB:dword
	extrn	CON4KB:dword
	extrn	CON16KB:dword
	extrn	CON64KB:dword
	extrn	CON1MB:dword
if @OEM_EMS
	extrn	PRPNTAB:dword
	extrn	PRPNCUR:dword
	extrn	EHNDLCNT:word
	extrn	NPHYS16F:byte
	extrn	NPHYS16S:byte
	extrn	NPHYSCNV:byte
	extrn	NPHYSSCR:byte

	extrn	HP_LAST:dword
	extrn	@MAX_EHNDLCNT:abs
	extrn	@RPN_IDENT:abs
	extrn	@RPN_UNMAP:abs
endif				; IF @OEM_EMS
	extrn	PaOPTE1:dword
	extrn	LAST_INTCOM:dword
	extrn	LAST_INTFLG:dword

	extrn	PCURTSS:dword
	extrn	PIOBIT:dword
	extrn	OLDINT_VECS:dword

if DBG_TRACE
	extrn	TRCBASE:dword
endif				; IF DBG_TRACE

if @OEM_SYS eq @OEMSYS_RET
	extrn	PSMSEG:word
	extrn	PSMWIN:word
	extrn	PSMSIZE:word
	extrn	PPDTPSM:dword
endif				;IF @OEM_SYS eq @OEMSYS_RET

	extrn	LaCVD:dword
	extrn	DMASIZE:word
	extrn	DMA_LA:dword
	extrn	HMASIZE:dword
	extrn	MAPBASE:dword
	extrn	LOWBASE:dword
	extrn	OVRBASE:dword
	extrn	LaCR3:dword
	extrn	LaDIR2:dword
	extrn	PDTLEN:dword
	extrn	LOADCOUNT:word
	extrn	LOADTAB:tbyte
	extrn	LOADTABIND:word
	extrn	PCHECKER_INP:dword
	extrn	CHECKER_LEN:word
	extrn	FGRBASE:dword
	extrn	FGRSIZE:dword
	extrn	IGRBASE:dword
	extrn	IGRSIZE:dword
	extrn	JGRBASE:dword
	extrn	JGRDSIZE:dword
if @OEM_DPMI
	extrn	LPMSTK_SIZ:dword
	extrn	DPMIPDIR_CNT:dword
	extrn	LaDPMIPDIR:dword
	extrn	DPMIOLDPM_SIZ:dword
	extrn	DPMIDYN_SIZ:dword
if @OEM_VIRTUALMEM
	extrn	DPMITYPE:byte

	extrn	VMM_FLAG:word
	include QMAX_VMM.INC
endif				; IF @OEM_VIRTUALMEM
endif				; IF @OEM_DPMI

if @OEM_FLEXROM
	extrn	FLEXROM_LEN:word
	extrn	FLEXROM_FLAG:word
	extrn	FLEXROM_TBL:tbyte
endif				; IF @OEM_FLEXROM

	extrn	PVDSTAB:dword
	extrn	VDSTAB_LEN:dword

	extrn	CPUFET_FLAG:dword
	extrn	PIOTRAP:dword

if @OEM_WIN3
	extrn	HIMEM_CS:word
	extrn	ACCKEY:dword
	extrn	PWIN3_PAGE:dword
	extrn	PWIN3_PAGEZ:dword
	extrn	@UMB_INST_N:abs

	public	WIN3_IMPORT_VENDOR,@WIN3_IMPORT_VENDOR_LEN
WIN3_IMPORT_VENDOR db	'QUALITAS'
	db	(20-($-WIN3_IMPORT_VENDOR)) dup (' ') ; Pad out to length 20
@WIN3_IMPORT_VENDOR_LEN equ $-WIN3_IMPORT_VENDOR

	public	WIN3_IMPORT_PRODUCT,@WIN3_IMPORT_PRODUCT_LEN
WIN3_IMPORT_PRODUCT db	'386MAX ',VERS_H,'.',VERS_T,VERS_U
	db	(20-($-WIN3_IMPORT_PRODUCT)) dup (' ') ; Pad out to length 20
@WIN3_IMPORT_PRODUCT_LEN equ $-WIN3_IMPORT_PRODUCT

	public	PWIN3_CB,PWIN3_STARTUP
PWIN3_CB dd	PGROUP:WIN3_CB	; Address of low DOS memory WIN3 callback routine
PWIN3_STARTUP dd PGROUP:WIN3_STARTUP ; Address of ...

	public	PUMB_INST
PUMB_INST dd	?		; 32-bit offset in DTE_DS to UMB instance data

	public	OLD_DUM67_VEC, NEW_DUM67_VEC
OLD_DUM67_VEC dd ?		; Holds the original INT 67h vector for INITWIN3
NEW_DUM67_VEC dd PGROUP:DUMMY_INT67 ; Vector to dummy INT67 handler

	public	HIGHDOS_MAP
HIGHDOS_MAP dd	((1024/4)/32) dup (?) ; 1 bit per 4KB page from 0 to 1MB

	public	POVR_MAC_SQZ
POVR_MAC_SQZ	dw	?	; Original POVR_MAC value before SQZOVR_WIN3

	public	NOSWAP_CNT
NOSWAP_CNT dw	0		; Lie about swapping this many times

if @OEM_HIFILL and @OEM_WIN3
	public	OLDHDM
OLDHDM	db	?		; Old value for HDM_FLAG
endif				; IF @OEM_HIFILL and @OEM_WIN3

endif				; IF @OEM_WIN3

OVR_REC record	$OVR_SQZ:1

	public	OVR_FLAG
OVR_FLAG OVR_REC <>		; High DOS memory flags

EDATA	ends			; End EDATA segment


ZDATA	segment use16 para public 'zdata' ; Start ZDATA segment
	assume	ds:PGROUP

	extrn	ZLDATA:byte	; End of static code/data

ZDATA	ends			; End ZDATA segment


FDATA	segment use16 dword public 'fixup' ; Start FDATA segment
	assume	ds:FGROUP

	extrn	MAXINT_VECS:dword

FDATA	ends			; End FDATA segment


SCODE	segment use16 para public 'scode' ; Start SCODE segment
	assume	ds:SGROUP

	extrn	DSTK_TAB:tbyte

SCODE	ends			; End SCODE segment


JCODE	segment use16 dword public 'jcode' ; Start JCODE segment
	assume	ds:JGROUP

	public	DSTKS_FNS
DSTKS_FNS label word
	dw	JGROUP:JMM2_DSTKS0
	dw	JGROUP:JMM2_DSTKS1
	dw	JGROUP:JMM2_DSTKS2
DSTKS_CNT equ	($-DSTKS_FNS)/2

	public	VSAPIACT
VSAPIACT dw	JGROUP:JMM2_VSAPI00 ; Disable swapfile
@VSAPI_LEN equ	($-VSAPIACT)/(type VSAPIACT) ; # functions supported

JCODE	ends			; End JCODE segment


ICODE	segment use16 dword public 'icode' ; Start ICODE segment
	assume	cs:IGROUP

	extrn	FDPMIFN_BITMAP_SIZ:far
	extrn	FDPMIFN_XLDT_SIZ:far

ICODE	ends			; End ICODE segment


IDATA	segment use16 dword public 'idata' ; Start IDATA segment
	assume	ds:IGROUP

if @OEM_VIRTUALMEM
	extrn	@BSCSize:abs
	extrn	PBScache:dword
endif				; IF @OEM_VIRTUALMEM

IDATA	ends			; End IDATA segment


ECODE	segment use16 dword public 'ecode' ; Start ECODE segment
	assume	cs:PGROUP

	public	@QMAX_IM2_ECODE
@QMAX_IM2_ECODE:		; Mark module start in .MAP file

	extrn	ENABLE_NMI:near
	extrn	DISABLE_NMI:near

	extrn	FLUSH_TLB:near
	extrn	EMM_E00AL:near
	extrn	EMM_E84:near
	extrn	EMM_E87:near
	extrn	EMM_E8A:near
	extrn	EMM_E8B:near
if @OEM_EMS
	extrn	VALID_HNDL:near
endif				; IF @OEM_EMS
	extrn	PL3ESDI:near
	extrn	REST_PTE:near
	extrn	SWAP_MAP:near
if @OEM_WIN3
	extrn	INIT_PROT:near
	extrn	REST_PROT:near
	extrn	FSET_PPL0STK:far
	extrn	CHECK_HFRMSAV:near
if @OEM_HIFILL
	extrn	FCLOSEHIGHDOS:far
endif				; IF @OEM_HIFILL
endif				; IF @OEM_WIN3
	extrn	FWRAP_DISABLE:far
	extrn	FWRAP_ENABLE:far
	extrn	XCHG_PTE:near
	extrn	PGMAP_COM:near
	extrn	FDISP_STR:far
	extrn	FQRY_PGCNT:far
	extrn	FALLOCMEM:far
	extrn	FDEALLOCMEM:far
	extrn	DISABLE_P5:far

EMM2_MAC macro	NAM

	public	EMM2_&NAM
EMM2_&NAM:
	FIXIJMP JGROUP:JMM2_&NAM,DTE_CSJG

	endm			; EMM2_MAC


	EMM2_MAC GETPTE 	; Function 05h
	EMM2_MAC GLBFLAG	;	   09h
	EMM2_MAC DBGFLAG	;	   0Ah
	EMM2_MAC DB2FLAG	;	   0Bh
	EMM2_MAC CM3FLAG	;	   0Ch
if DBG_TRACE
	EMM2_MAC TRACE		;	   10h
endif				; IF DBG_TRACE
if @OEM_ROMSCAN
	EMM2_MAC RAMSCAN	;	   11h
endif				; IF @OEM_RAMSCAN
	EMM2_MAC ROMSWAP	;	   12h
	EMM2_MAC ROMRW		;	   13h
if @OEM_WIN3
	EMM2_MAC GOREALWIN3	;	   15h
endif				; IF @OEM_WIN3
if @OEM_WIN3
	EMM2_MAC INITWIN3	;	   17h
endif				; IF @OEM_WIN3
	EMM2_MAC PSMEM		;	   18h
	EMM2_MAC PHYS2LIN	;	   19h
	EMM2_MAC SETPTE 	;	   1Ah
if @OEM_FLEXROM
	EMM2_MAC FLEXINFO	;	   1Bh
endif				; IF @OEM_FLEXROM
	EMM2_MAC GETOLDINT	;	   1Ch
	EMM2_MAC DISPSTR	;	   1Dh
	EMM2_MAC EXTADDR	;	   1Eh
	EMM2_MAC GETMAXINT	;	   20h
	EMM2_MAC DSTKS		;	   21h
	EMM2_MAC INITREST	;	   22h
	EMM2_MAC TMPCLOSE	;	   25h
if @OEM_VIRTUALMEM
	EMM2_MAC SWAPFILE	;	   28h
endif				; IF @OEM_VIRTUALMEM
	EMM2_MAC VMVSAPI	;	   29h

	FPPROC	FPL3ESDI -- Convert PL3 ES:DI to DTE_D4GB:EDI
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert the PL3 ES:DI to AGROUP:EDI.

|

	call	PL3ESDI 	; Convert PL3 ES:DI to AGROUP:EDI
	assume	es:AGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FPL3ESDI endp			; End FPL3ESDI procedure
	FPPROC	FFLUSH_TLB -- Flush Translation Lookaside Buffer
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Flush the translation lookaside buffer by respecifying the
Page Descriptor Base Register.

|

	call	FLUSH_TLB	; Flush the TLB

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FFLUSH_TLB endp 		; End FFLUSH_TLB procedure
	FPPROC	FDISABLE_NMI -- Disable NMI
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable NMI

Note that this routine is bimodal.

|

	call	DISABLE_NMI	; Disable NMIs

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDISABLE_NMI endp		; End FDISABLE_NMI procedure
	FPPROC	FENABLE_NMI -- Enable NMI, Clear Parity Latches
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable NMI, clear parity latches.

Note that this routine is bimodal.

|

	call	ENABLE_NMI	; Enable NMI, clear the parity latches

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FENABLE_NMI endp		; End FENABLE_NMI procedure
	FPPROC	FREST_PTE -- Restore PTEs
	assume	ds:nothing,es:nothing,fs:PDTGRP,gs:nothing,ss:PGROUP
COMMENT|

Restore FS:SI entry in PDT to physical memory calculated from DI
without modifying flag bits.
Flush page translation cache.

On entry:

FS:SI	==>	destin PTE (e.g., C000 or if VGASWAP B000)
FS:DI	==>	source PTE (	   C000 	      C000)

|

	call	REST_PTE	; Restore 'em and flush page translation cache

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FREST_PTE endp			; End FREST_PTE procedure
	FPPROC	FSWAP_MAP -- Swap PDT Entries for MAPBASE
	assume	ds:PGROUP,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Swap PDT entries for MAPBASE and MAPTAB entries.

On entry:

EDX	=	current linear address of MAPBASE
ESI	=	offset in PDT of next MAPBASE entry
DI	=	index into MAPTAB

On exit:

EDX	=	(updated)
ESI	=	(updated)

|

	call	SWAP_MAP	; Swap PTEs for MAP, increment ESI and EDX

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FSWAP_MAP endp			; End FSWAP_MAP procedure
	FPPROC	FINIT_PROT -- Initialize API Protected Mode
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize API protected mode for all files

|

	call	INIT_PROT	; Initialize 'em

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINIT_PROT endp 		; End FINIT_PROT procedure
	FPPROC	FREST_PROT -- Restore API Protected Mode
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore API protected mode for all files

|

	call	REST_PROT	; Restore 'em

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FREST_PROT endp 		; End FREST_PROT procedure
	FPPROC	FVALID_HNDL -- Validate Handle DX
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Validate handle in DX.

On entry:

DX	=	handle to validate

On exit:

CF	=	1 if handle in use
	=	0 if not

|

	call	VALID_HNDL	; Ensure it's a valid handle

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FVALID_HNDL endp		; End FVALID_HNDL procedure
	FPPROC	FCHECK_HFRMSAV -- Check HFRMSAV For DX
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check the HFRMSAV area for handle DX in use.

On entry:

DL	=	handle to check

On exit:

DS:EBX	==>	entry for this handle
ZF	=	1 the entry is free
	=	0 the entry is in use

|

	call	CHECK_HFRMSAV	; Return ZF=1 if entry is free
				; DS:EBX = corresponding record
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCHECK_HFRMSAV endp		; End FCHECK_HFRMSAV procedure
	FPPROC	FXCHG_PTE -- Exchange PTEs
	assume	ds:nothing,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Exchange PTEs

On entry:

FS:ESI	==>	source PTE
FS:EDI	==>	dest	PTE

On exit:

FS:ESI	==>	next source PTE
FS:EDI	==>	next dest   PTE

|

	call	XCHG_PTE	; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FXCHG_PTE endp			; End FXCHG_PTE procedure
	FPPROC	FPGMAP_COM -- Common Page Mapping Routine
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate logical page PGMAP_LPN of handle PGMAP_HNDL
into a PTE and save in the physical page PGMAP_PPN in the EMS frame.

If PGMAP_LPN = @RPN_UNMAP, unmap the corresponding physical page.
If PGMAP_LPN = @RPN_IDENT, map in the identity physical page.

On entry:

PGMAP_STR filled in.

On exit:

AX	=	RPN

CF	=	0 if all went well
	=	1 if logical page # not found

|

PGMAP_STR struc

	dd	?		; Caller's EBP
	dd	?		; Caller's return address
PGMAP_PPN  db	?,?		; The physical page #
PGMAP_LPN  dw	?		; The logical page #
PGMAP_HNDL db	?,?		; The handle

PGMAP_STR ends

	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack

	push	[ebp].PGMAP_HNDL.ELO ; Pass handle #
	push	[ebp].PGMAP_LPN ; Pass logical page #
	push	[ebp].PGMAP_PPN.ELO ; Pass physical page #
	call	PGMAP_COM	; Call common page map routine
				; Return with CF significant
	pop	ebp		; Restore

	ret	3*2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FPGMAP_COM endp 		; End FPGMAP_COM procedure
	align	4		; Ensure dword alignment

ECODE	ends			; End ECODE segment


LCODE	segment use16 dword public 'icode' ; Start LCODE segment
	assume	cs:IGROUP

	extrn	GETSELBASE:far

LCODE	ends			; End LCODE segment


JDATA	segment use16 dword public 'jcode' ; Start JDATA segment
	assume	ds:JGROUP

	extrn	JSEL_DS3:word

	public	NOSCAN_MAP
NOSCAN_MAP db	((384/4)/8) dup (0) ; NOSCAN bit map
				; 0 = OK to scan
				; 1 = not

JDATA	ends			; End JDATA segment


JCODE	segment use16 dword public 'jcode' ; Start JCODE segment
	assume	cs:JGROUP

	extrn	MAC_MERGE:near

	public	@QMAX_IM2_JCODE
@QMAX_IM2_JCODE:		; Mark module start in .MAP file

	public	JMM_E84
JMM_E84:
	FIXIJMP PGROUP:EMM_E84,DTE_CS2

	public	JMM_E87
JMM_E87:
	FIXIJMP PGROUP:EMM_E87,DTE_CS2

	public	JMM_E8A
JMM_E8A:
	FIXIJMP PGROUP:EMM_E8A,DTE_CS2

	public	JMM_E8B
JMM_E8B:
	FIXIJMP PGROUP:EMM_E8B,DTE_CS2

	extrn	JMM_E8F:near

	FPPROC	JMM2_GETPTE -- Save PTEs in ES:DI
	assume	ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 5, AH = 05h

Save PTEs from FS:SI of length CX (both in KB) into ES:DI.
If CX = 0, return PTEs to end of memory.
If AL = 0, disable 1MB wrap first
      = 1, enable ...

Error return 8F if AL > 1
	     87 if (SI+CX) > (TOTSIZE+1024)

All registers except EBP, SS, and ESP may be destroyed.

|

	sti			; Allow interrupts

	cmp	[ebp].INTXX_EAX.ELO.LO,1 ; Check subfunction
	ja	near ptr JMM_E8F ; Jump if out of range
	je	short EMM2_GETPTE1 ; Jump if leave 1MB wrap as is

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap
EMM2_GETPTE1:
	movzx	esi,[ebp].INTXX_ESI.ELO ; Get lower limit in bytes
	movzx	ecx,[ebp].INTXX_ECX.ELO ; Get length in bytes

; Ensure values are on 4KB boundaries

	and	si,not (4-1)	; Round starting address down
	and	cx,not (4-1)	; ... length

; Ensure values are in range

	mov	eax,TOTSIZE	; Get total size of extended memory
	add	eax,CON1KB	; Plus amount for first megabyte

	mov	ebx,esi 	; Copy starting point
	add	ebx,ecx 	; Plus length

	sub	eax,ebx 	; Check against limit
	jb	short JMM_E87 ; Jump if upper limit is too large

	and	cx,cx		; Check for special case
	jnz	short @F	; Not this time

	mov	ecx,eax 	; Use maximum value to end of memory
@@:
	mov	[ebp].INTXX_ECX.ELO,cx ; Save length in bytes

; Address the caller's save area

	FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	assume	es:AGROUP	; Tell the assembler about it

	shr	ecx,2-0 	; Convert from bytes to dwords
S32 rep movs	<AGROUP:[edi].EDD,OFFPDT[esi]>

; Note that @GLB_XWRP is cleared and WRAP_ENABLE is called at EMM_EXIT

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GETPTE endp		; End JMM2_GETPTE procedure
	FPPROC	JMM2_GLBFLAG -- EMM2 Flip Bits in GLB_FLAG
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 9, AH = 09h

Flip bits in GLB_FLAG as marked in BX

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	sti			; Allow interrupts

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap

	mov	ax,[ebp].INTXX_EBX.ELO ; Get bits to flip
	xor	GLB_FLAG,ax	; Flip 'em

; Note that @GLB_XWRP is cleared and WRAP_ENABLE is called at EMM_EXIT

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GLBFLAG endp		; End JMM2_GLBFLAG procedure
	FPPROC	JMM2_DBGFLAG -- EMM2 Flip Bits in DBG_FLAG
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 10, AH = 0Ah

Flip bits in DBG_FLAG as marked in BX

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	sti			; Allow interrupts

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap

	mov	ax,[ebp].INTXX_EBX.ELO ; Get bits to flip
	xor	DBG_FLAG,ax	; Flip 'em

if @OEM_EMS
	test	DBG_FLAG,@DBG_EPTE ; Testing EMS PTEs?
	jz	short @F	; Not this time

	FCALL	JMM_TEST	; Test the EMM tables
@@:
endif				; IF @OEM_EMS

; Note that @GLB_XWRP is cleared and WRAP_ENABLE is called at EMM_EXIT

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_DBGFLAG endp		; End JMM2_DBGFLAG procedure
	FPPROC	JMM2_DB2FLAG -- EMM2 Flip Bits in DB2_FLAG
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 11, AH = 0Bh

Flip bits in DB2_FLAG as marked in BX

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	sti			; Allow interrupts

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap

	mov	ax,[ebp].INTXX_EBX.ELO ; Get bits to flip
	xor	DB2_FLAG,ax	; Flip 'em

; Note that @GLB_XWRP is cleared and WRAP_ENABLE is called at EMM_EXIT

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_DB2FLAG endp		; End JMM2_DB2FLAG procedure
	FPPROC	JMM2_CM3FLAG -- EMM2 Flip Bits in CM3_FLAG
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 12, AH = 0Ch

Flip bits in CM3_FLAG as marked in BX

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	sti			; Allow interrupts

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap

	mov	ax,[ebp].INTXX_EBX.ELO ; Get bits to flip
	xor	CM3_FLAG,ax	; Flip 'em

; Note that @GLB_XWRP is cleared and WRAP_ENABLE is called at EMM_EXIT

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_CM3FLAG endp		; End JMM2_CM3FLAG procedure
if DBG_TRACE
	FPPROC	JMM2_TRACE -- EMM2 I/O Trace Information
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 16, AH = 10h

Return I/O trace information.

All registers except EBP, SS, and ESP may be destroyed.

|

	mov	eax,TRCBASE	; Get trace table case address
	mov	[ebp].INTXX_EBX,eax ; Return in caller's EBX

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_TRACE endp 		; End JMM2_TRACE procedure
endif				; IF DBG_TRACE
if @OEM_ROMSCAN
	FPPROC	JMM2_RAMSCAN -- EMM2 High DOS Memory RAM Scan
	assume	ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 17, AH = 11h

High DOS memory RAM scan.

Store into ES:DI the following structure:
       DB      ?	      ; Flags for corresponding 4KB page
repeated as many times as there are 4KB pages between 640KB and 1024KB.

The flags come from QMAX_RAM.INC.

All registers except EBP, SS, and ESP may be destroyed.

|

; Setup page table with A000 to FF00 physical addresses.

	push	DTE_OPTE	; Get overflow PTE selector
	pop	es		; Address it
	assume	es:nothing	; Tell the assembler about it

	xor	di,di		; ES:DI ==> local Page Table

	mov	eax,0A0000h or (mask $PTE_CD) or (mask $PTE_WT) or @PTE_URP ; Get initial physical address
	mov	cx,(100000h-0A0000h)/(4*1024) ; # 4KB PTEs between A000 and 10000
@@:
S16	stosd			; Save in Page Table
	add	eax,CON4KB	; Skip to next entry
	loop	@B		; Jump if more entries to set

; Ensure the PDE used for D2M and CNV entries is overwritten by the
; one for the overflow PTE table in case the move is into that area

	mov	ebx,OFFCR3	; Get offset of CR3's PDIRs
	mov	eax,PDBSIZE	; Get # PDEs
	shl	eax,2-0 	; Convert from dwords to bytes
	add	ebx,eax 	; Skip to next entry

	mov	edx,PaOPTE1	; Get its physical address
	or	edx,@PTE_URP	; Ensure User/Read-write/Present bits are set

	xchg	edx,PGROUP:[ebx] ; Swap 'em

; Because we just changed the page table, we must flush the TLB

	FIXICALL PGROUP:FFLUSH_TLB,DTE_CS2 ; Flush the TLB

	REGSAVE <ebx,edx>	; Save the base and PTE value

; Get 20-bit linear address offset of caller's ES:DI into AGROUP:EDI

	FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	assume	es:AGROUP	; Tell the assembler about it

	mov	ebx,PDBSIZE	; Get # PDEs
	shl	ebx,(2+10+10)-0 ; Convert from 4MB to bytes

; Test for memory at ES:EBX

	mov	cx,(100000h-0A0000h)/(4*1024) ; # 4KB PTEs between A000 and 10000
	mov	edx,0A0000h	; Get initial physical address
	mov	si,0A0000h shr (12-2) ; FS:SI ==> next PTE in page table

COMMENT|

Register usage:

ES	=	AGROUP
EBX	=	next linear address to check
CX	=	# 4KB blocks to check
EDX	=	next physical address
ES:EDI	==>	caller's buffer
FS:SI	==>	next PTE in page table

|

EMM2_RAMSCAN_NEXT:

; Check for one-to-one memory in the Page Table

	lods	OFFPDT[si]	; Get next PTE
	and	ax,mask $PTE_FRM ; Isolate frame

	cmp	eax,edx 	; Izit one-to-one?
	sete	al		; Set low-order bit if so
	shl	al,$RAM_IDN	; Shift into position

; Check for EMS-mappable memory (note SI has been incremented)

	call	EMS_RAM 	; Check it
	jnc	short @F	; Jump if not EMS-mappable

	or	al,mask $RAM_EMS ; Mark as EMS-mappable
@@:

; Check for NOSCAN memory in the range A000-10000

	push	edx		; Save for a moment

	shr	edx,12-0	; Convert from bytes to 4KB

	cmp	edx,1024/4	; Izit too large (above or equal to 1MB)?
	jae	short @F	; Jump if so (note CF=0)

	sub	edx,640/4	; Izit too small (below 640KB)?
;;;;;;; jb	short @F	; Jump if so
	cmc			; Complement for ending
	jae	short @F	; Jump if so

	bt	NOSCAN_MAP.ELO,dx ; Izit not to be scanned?
				; CF = 1 if not to be scanned
				;    = 0 if OK to scan
@@:
	pop	edx		; Restore
	jc	short @F	; Jump if not to be scanned

	call	TEST_RAM	; Test for it
	jnc	short @F	; Jump if not RAM

	or	al,mask $RAM_RAM ; Mark as RAM
@@:

if @OEM_SYS eq @OEMSYS_RET

; Test for PS memory (note SI has been incremented)

	call	TEST_PSMEM	; Test for it
	jnc	short @F	; Jump if not PS memory

	or	al,mask $RAM_PSM ; Mark as PSMEM
@@:
endif				; IF @OEM_SYS eq @OEMSYS_RET
S32	stos	AGROUP:[edi].LO ; Save bits in user's table

	add	ebx,CON4KB	; Skip to next 4KB page
	add	edx,CON4KB	; ...

	loop	EMM2_RAMSCAN_NEXT ; Jump if more

; Restore original PDE in EDX

	REGREST <edx,ebx>	; Restore base and PTE value

	xchg	edx,PGROUP:[ebx] ; Restore original PDE

; Because we just changed the page table, we must flush the TLB

	FIXICALL PGROUP:FFLUSH_TLB,DTE_CS2 ; Flush the TLB

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_RAMSCAN endp		; End JMM2_RAMSCAN procedure
endif				; IF @OEM_ROMSCAN
if @OEM_ROMSCAN
	NPPROC	EMS_RAM -- EMS-Mappable RAM Scan
	assume	ds:PGROUP,es:AGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMS-mappable RAM scan

On entry:

SI-4	=	this 4KB page in PTE

On exit:

CF	=	1 if EMS-mappable
	=	0 if not

|

	REGSAVE <ax,ecx,edi>	; Save registers

	lea	ax,[si-4]	; Copy offset and subtract
	shl	ax,(12-2)-4	; Convert from 4KB in dwords to paras
	and	ax,not ((16*1024/16)-1) ; Round down to 16KB boundary
	mov	edi,PPHYS2SEG	; ES:EDI ==> EMS-mappable segment #s
	add	edi,PRGBASE	; Convert to linear address
	movzx	ecx,NPHYS16S	; Get # physical 16KB pages in EMS system
  repne scas	AGROUP:[edi].ELO ; Search for it
	stc			; Assume it's found
	je	short @F	; Jump if found

	clc			; Indicate not found
@@:
	REGREST <edi,ecx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMS_RAM endp			; End EMS_RAM procedure
endif				; IF @OEM_ROMSCAN
if @OEM_ROMSCAN
	NPPROC	TEST_RAM -- Test For RAM In High DOS Memory
	assume	ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test for RAM in high DOS memory

On entry:

ES	=	AGROUP
EBX	=	linear address of 4KB block to test
IF	=	0

On exit:

CF	=	0 means many mismatches (RAM not present)
	=	1 means few  mismatches (RAM	  present)

|

	REGSAVE <ax,ecx,dx,esi,edi> ; Save registers

	FIXICALL PGROUP:FDISABLE_NMI,DTE_CS2 ; Disable NMIs

; 1.  Save the data in case there's really RAM there.

	mov	esi,ebx 	; ES:ESI ==> start of 512-byte block

	lea	edi,LCLMEM	; EDI ==> local storage area
	add	edi,PRGBASE	; Convert to 32-bit linear address
	mov	ecx,LCLMEM_LEN	; # bytes in LCLMEM
	shr	ecx,1-0 	; Convert from bytes to words
S32 rep movs	<AGROUP:[edi].ELO,AGROUP:[esi].ELO> ; Copy it to local memory

; 2.  Store a single value throughout the 512-byte block.

	mov	ax,'&!'-1234h   ; Store this
	add	ax,1234h	; Add back in to avoid "bus capacitance" problems
	mov	ecx,LCLMEM_LEN	; # bytes in LCLMEM
	shr	ecx,1-0 	; Convert from bytes to words
	mov	edi,ebx 	; ES:EDI ==> start of 512-byte block
    rep stos	AGROUP:[edi].ELO ; Store constant value

; 3.  Flush any cache controller by reading lots of data

	push	ax		; Save for a moment
	xor	esi,esi 	; Point to 0:0
	mov	ecx,CON64KB	; ECX = # words to read
    rep lods	AGROUP:[esi].ELO ; Read to flush cache controller
	pop	ax		; Restore

; 4.  Scan for the stored value and count the # matches.

	mov	ecx,LCLMEM_LEN	; # bytes in LCLMEM
	shr	ecx,1-0 	; Convert from bytes to words
	mov	edi,ebx 	; ES:EDI ==> start of 512-byte block
	xor	dx,dx		; Zero counter for mismatches
TEST_RAM_NEXT:
	jcxz	TEST_RAM_REST	; That's all folks
   repe scas	AGROUP:[edi].ELO ; Scan for stored value
	je	short TEST_RAM_REST ; No more to search

	inc	dx		; Count in a mismatch

	jmp	TEST_RAM_NEXT	; Go around again

; 5.  Restore the values saved in step 1.

TEST_RAM_REST:
	lea	esi,LCLMEM	; DS:ESI ==> local storage area
	mov	edi,ebx 	; ES:EDI ==> start of 512-byte block

	mov	ecx,LCLMEM_LEN	; # bytes in LCLMEM
	shr	ecx,1-0 	; Convert from bytes to words
S32 rep movs	<AGROUP:[edi].ELO,PGROUP:[esi].ELO> ; Copy it from local memory

	FIXICALL PGROUP:FENABLE_NMI,DTE_CS2 ; Enable NMI, clear the parity latches

; 6.  To err on the side of conservatism (we don't want to
;     mis-identify real RAM), if we find the stored value
;     at more than half the positions we'll call it real RAM.

	mov	cx,LCLMEM_LEN	; # bytes in LCLMEM
	shr	cx,2-0		; Convert from bytes to dwords
	cmp	dx,cx		; More than half are mismatches?

; CF = 0 means many mismatches (RAM not present)
; CF = 1 means few  mismatches (RAM	present)

	REGREST <edi,esi,dx,ecx,ax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TEST_RAM endp			; End TEST_RAM procedure
endif				; IF @OEM_ROMSCAN
if @OEM_ROMSCAN and @OEM_SYS eq @OEMSYS_RET
	NPPROC	TEST_PSMEM -- Test for PS Memory in High DOS
	assume	ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test for PS Memory in high DOS memory

On entry:

SI-4	=	offset into PDTGRP of this PTE
IF	=	0

On exit:

CF	=	1 if PS memory present
	=	0 not

|

	REGSAVE <ax,si> 	; Save registers

	cmp	PSMWIN,0	; Izit specified?
	je	short TEST_PSMEM_EXIT ; Jump if not (note CF=0)

	sub	si,4		; Back off to PTE

	mov	ax,PSMSEG	; Get PSM starting segment (/4KB)
	shr	ax,(12-2)-4	; Convert from paras to 4KB in dwords

	cmp	ax,si		; Izit PS memory?
	ja	short TEST_PSMEM_EXIT ; Jump if not (note CF=0)

	add	ax,PSMWIN	; Plus size of window in 1KB (/4KB)

	cmp	si,ax		; Izit PS memory?
;;;;;;; jae	short TEST_PSMEM_EXIT ; Jump if not (note CF=0)
;;;;;;;
;;;;;;; stc			; Mark as PS memory
TEST_PSMEM_EXIT:
	REGREST <si,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TEST_PSMEM endp 		; End TEST_PSMEM procedure
endif				; IF @OEM_ROMSCAN and @OEM_SYS eq @OEMSYS_RET
	FPPROC	JMM2_ROMSWAP -- EMM2 System ROM Swap In/out
	assume	ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 18, AH = 12h

System ROM swap in and out.

On entry:

AL	=	0 to swap system ROM out
	=	1 ...		      in

All registers except EBP, SS, and ESP may be destroyed.

|

; If we compressed the system ROM, we can't afford to restore it
; as there might have been fixups in the second half which would
; not be present in the restored ROM.

	test	LCL_FLAG,@LCL_CROM or @LCL_BCF ; Did we compress the system ROM?
	jnz	short EMM2_ROMSWAP_EXIT ; Jump if so

	push	DTE_PDT 	; Get our PDT selector
	pop	fs		; Address it
	assume	fs:PDTGRP	; Tell the assembler about it

	cmp	[ebp].INTXX_EAX.ELO.LO,1 ; Split cases based on function code
	ja	near ptr JMM_E8F ; Jump if too large
	je	short EMM2_ROMSWAPIN ; Jump if we're to swap it back in
				; Fall through to swap ROM out

; Swap back to ROM the affected page
; Restore FS:SI entry in PDT to original ROM value

	mov	si,SYSROM_START ; Get starting segment of system ROM
	mov	cx,si		; Copy to calculate length
	neg	cx		; Subtract from 10000h
	shr	si,(12-2)-4	; Convert from paras to 4KB in dwords
	shr	cx,12-4 	; Convert from paras to 4KB

	test	CM2_FLAG,@CM2_NWB ; Izit NOWARMBOOT?
	jz	short EMM2_ROMSWAPOUT ; Jump if not

	dec	cx		; Less one for WARMBOOT
EMM2_ROMSWAPOUT:
	test	OFFPDT[si],mask $PTE_RW ; Izit marked as ROM?
	jnz	short @F	; Jump if not

	mov	di,si		; Copy source to destin for REST_PTE
	FIXICALL PGROUP:FREST_PTE,DTE_CS2 ; Restore 'em and flush page translation cache
@@:
	add	si,4		; Skip to next PTE

	loop	EMM2_ROMSWAPOUT ; Jump if more PTEs to swap

	jmp	short EMM2_ROMSWAP_EXIT ; Join common exit code

; Swap the ROM back in (assuming we cached it in the first place)

EMM2_ROMSWAPIN:
	mov	cx,MAPTAB_CNT	; Get # entries in table
	jcxz	EMM2_ROMSWAPIN_NONE ; Skip out if nothing to do
	mov	edx,MAPBASE	; Get linear address of map base
	mov	esi,PPDTMAP	; Initialize offset into MAPBASE area
	xor	di,di		; Initialize index to MAPTAB
EMM2_ROMSWAPIN_NEXT:
	FIXICALL PGROUP:FSWAP_MAP,DTE_CS2 ; Swap PTEs for MAP, increment ESI and EDX

	add	di,type MAP_STR ; Skip to next entry

	loop	EMM2_ROMSWAPIN_NEXT ; Jump if more entries

; Because we just changed the page table, we must flush the TLB

	FIXICALL PGROUP:FFLUSH_TLB,DTE_CS2 ; Flush the TLB
EMM2_ROMSWAPIN_NONE:
	and	GLB_FLAG,not @GLB_ROM ; Mark as no longer needing ROM swap
EMM2_ROMSWAP_EXIT:
	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_ROMSWAP endp		; End JMM2_ROMSWAP procedure
	FPPROC	JMM2_ROMRW -- EMM2 Swapped ROM Write Enable
	assume	ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 19, AH = 13h

Swapped ROM write enable.

On entry:

AL	=	0 to make swapped ROMs Read Only
	=	1 to make swapped ROMs Read/Write

All registers except EBP, SS, and ESP may be destroyed.

Error return 8F if AL > 1

|

	mov	cx,MAPTAB_CNT	; Get # entries in table
	jcxz	EMM2_ROMRW_NONE ; Skip out if nothing to do

	xor	di,di		; Initialize index into MAPTAB
ROMRW_NEXT_MAP:
	test	MAPTAB.MAP_FLAG[di],@MAP_ROM	; This entry a ROM?
	jz	short ROMRW_GOON ; No, so on to next entry

	test	MAPTAB.MAP_FLAG[di],@MAP_SWAP	; Swappable?
	jz	short ROMRW_GOON ; No, so on to next entry

	push	cx		; Save number of MAPTAB entries remaining
	push	di		; Save index into MAPTAB

	mov	cx,MAPTAB.MAP_LEN[di]	; Number of paragraphs in this entry
	jcxz	ROMRW_SKIP		; No one's home
	shr	cx,12-4 		; Convert to # of 4KB pages

	mov	di,MAPTAB.MAP_PARA_DST[di] ; Original paragraph of ROM
	shr	di,12-4 		; Convert to 4KB page style
	shl	di,2			; Times 4 to index table
					; FS:DI --> this page entry in PDT
ROMRW_NEXT_PTE:

; Examine PTE
	cmp	[ebp].INTXX_EAX.ELO.LO,1 ; Split cases based on function code
	ja	near ptr JMM_E8F	; Jump if too large
	je	short ROMRW_RW		; Jump to 1 = R/W case

	and	OFFPDT[di],not(mask $PTE_RW)	; Make R/O

	jmp	short ROMRW_MASK_COM		; Rejoin common code

ROMRW_RW:
	or	OFFPDT[di],mask $PTE_RW 	; Make R/W

ROMRW_MASK_COM:
	add	di,4			; Advance to next PTE

	loop	ROMRW_NEXT_PTE		; Jump if more pages
ROMRW_SKIP:
	pop	di			; Restore index into MAPTAB
	pop	cx			; Restore # of MAPTAB entries remaining
ROMRW_GOON:
	add	di,type MAP_STR 	; Skip to next entry

	loop	ROMRW_NEXT_MAP		; Continue if more to go

; Because we just changed the page table, we must flush the TLB

	FIXICALL PGROUP:FFLUSH_TLB,DTE_CS2 ; Flush the TLB
EMM2_ROMRW_NONE:
	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_ROMRW endp 		; End JMM2_ROMRW procedure
if @OEM_WIN3
	FPPROC	JMM2_GOREALWIN3 -- Enter Real Mode for Windows 3
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 21, AH = 15h

Enter real mode for Windows 3

All registers except EBP, SS, and ESP may be destroyed.

|

	mov	gs,SEL_4GB3	; Get AGROUP data selector at PL3
	assume	gs:AGROUP	; Tell the assembler about it

	FCALL	DMA_WIN3	; Swap DMA buffer if in conventional memory

; In order to reduce the size of the WIN386.EXE footprint in low DOS,
; we'll not connect unallocated high DOS in the VxD.  WIN386 will use the
; pages as mapping buffers, avoiding low DOS.

; Scan the MAC chain in high DOS, marking adjacent free blocks 4KB or larger
; as spanning entries.	Scan the MAC chain again, filling in a bitmap of
; pages that should be connected as high DOS within Windows.  FILL_WIN3
; refers to the bitmap when filling in the GPIS 1.11 UMB data.	Similar
; code in the VxD fills in the bitmap for GPIS 1.0 versions of Windows.

	call	SQZOVR_WIN3	; Squeeze out unused 4KB blocks in high DOS
	call	FILL_HIGHDOS_MAP ; Setup bitmap of high DOS pages

; Fill in WIN3 Paging Import Data

	call	FILL_WIN3	; Fill 'er up

; Copy UMB instance data to local buffer

	mov	cx,@UMB_INST_N	; # of entries table will hold
	call	COPY_INST_DATA	; Sort out the UMB instance data items

; Set extended memory data values

	mov	LOWWIN3_CB,2	; Mark as using Windows GDT/IDT/CR3

; Set low DOS memory data values

	push	DTE_DSLO	; Get data selector for low DOS memory
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	mov	LOWWIN3_CB,2	; Mark as using Windows GDT/IDT/CR3

	test	GLB_FLAG,@GLB_I67 ; Are we providing INT 67h services?
	jnz	short @F	; Yes, skip alterations

	assume	gs:INTVEC	; Tell the assembler about it

	mov	eax,es:OLD_DUM67_VEC ; Get old interrupt vector
	mov	INT00_VEC[67h*(type INT00_VEC)],eax ; Restore it

	mov	DEVDRV.DD_NAME[0],'Q' ; Mark as EMS manager not installed

	assume	gs:AGROUP	; Tell the assembler
@@:

; Save caller's stack to restore later

	mov	ax,[ebp].INTXX_SS ; Get caller's SS
	mov	STKPTR.VSEG,ax	; Save to restore later

	mov	ax,[ebp].INTXX_ESP.ELO ; Get caller's SP
	mov	STKPTR.VOFF,ax	; Save to restore later

; Set high DOS memory data values

	push	DTE_DSHI	; Get data selector for high DOS memory
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	mov	LOWWIN3_CB,2	; Mark as using Windows GDT/IDT/CR3

	mov	ax,LOADSEG	; Get segment of initial LSEG
	mov	es:WIN3_REF_DATA.REF_LOADSEG,ax ; Save in VxD struc

	mov	al,es:FILES_STR_LEN ; Length of FILES= structure
	sub	ah,ah		; Convert from BYTE to WORD
	mov	es:WIN3_REF_DATA.REF_FILES_LEN,ax ; Save in VxD struc

	push	DTE_DS		; Get data selector for extended memory
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

; Reset interrupt counters

	mov	eax,PPL0STK_MAX ; Get initial top of stack pointer
	mov	ebx,PCURTSS	; Get offset in PGROUP of current TSS
	mov	PGROUP:[ebx].TSS_ESP0,eax ; Restore
	sub	eax,size INTCOM_STR ; Back off by frame size
	mov	LAST_INTCOM,eax ; Save as offset of last INTCOM interrupt frame
	and	LAST_INTFLG,not @INTCOM_VAL ; Mark as invalid

; These FICALLs are used instead of FIXICALL because they are always executed
; under 386MAX's GDT, etc. and should never be translated by the Windows
; fixup apparatus.

; Recalculate PL0STK pointers

	FICALL	PGROUP:FSET_PPL0STK,DTE_CS2 ; Set PPL0STK... pointers

; Call restore protected mode entry point in all API files loaded

	FICALL	PGROUP:FREST_PROT,DTE_CS2 ; Call 'em

if @OEM_VDS

; Clear DMA services enabled bit
; unless there's a previous VDS handler.

	cmp	PVDSTAB,0	; Is there a previous VDS table?
	jne	short @F	; Jump if so

	assume	gs:BIOSDATA	; Tell the assembler about it
	and	VDS[400h],not @VDS_ENA ; Mark as disabled
	assume	gs:AGROUP	; Tell the assembler about it
@@:
endif				; IF @OEM_VDS

	FIXICALL PGROUP:DISABLE_P5,DTE_CS2 ; Disable P5-specific features

	popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]
				; Note EAX is restored in WIN3_CB_GOREAL

	add	esp,size INTXX_ERR ; Strip off error code

; **** Don't try debugging from here on ****

; Load base and limit of IDT for real mode

	LIDTD	IDT_REAL	; Reset IDT for real mode

; Load all data segment registers with 64KB selector in low memory

	mov	ax,DTE_D64K	; Use low DOS memory 64KB data selector

	mov	ds,ax		; Set to 64KB selector
	assume	ds:PGROUP	; Tell the assembler about it

	mov	es,ax		; ...
	assume	es:PGROUP	; Tell the assembler about it

	mov	fs,ax		; ...
	assume	fs:PGROUP	; Tell the assembler about it

	mov	gs,ax		; ...
	assume	gs:PGROUP	; Tell the assembler about it

	mov	ss,ax		; ...
	assume	ss:nothing	; Tell the assembler about it
	mov	sp,sp		; Just for the fun of it

; This FIJMP is used instead of FIXIJMP because it is always executed under
; 386MAX's GDT, etc. and is never translated by the Windows fixup apparatus.

	FIJMP	PGROUP:WIN3_CB_GOREAL,DTE_CSLO ; Jump to code in low DOS memory

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GOREALWIN3 endp		; End JMM2_GOREALWIN3 procedure
endif				; IF @OEM_WIN3
if @OEM_WIN3
	NPPROC	FILL_HIGHDOS_MAP -- Fill In High DOS Bitmap
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Fill in HIGHDOS_MAP Bitmap

This bitmap contains 1 bit per 4KB page from 0 to 1MB.
The MAC chain starting at POVR_MAC is scanned.	Spanning entries are skipped.
Other the range of memory covered by non-spanning entries are marked in
the bitmap.

All EGP registers except EBP clobbered.

|

	lea	edi,HIGHDOS_MAP ; PGROUP:EDI ==> HIGHDOS_MAP
	mov	ecx,(1024/4)/32 ; Number of DWORDs in bitmap
	sub	eax,eax 	; A handy zero
    rep stos	PGROUP:[edi].EDD ; Zero the bitmap

	movzx	ebx,POVR_MAC	; Get segment of first MAC entry in high DOS

	cmp	bx,-1		; Izit valid?
	je	short FHDM_EXIT ; Jump if not

	shl	ebx,(12-8)	; Convert from segment to linear address

FHDM_NXT:

; EBX = V86 linear address of the MAC entry being examined
; If this isn't a special entry, map the high DOS pages it overlaps

	cmp	AGROUP:[ebx].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	je	short FHDM_ADVANCE ; Advance if so

; Find the end of this MAC entry

	movzx	eax,AGROUP:[ebx].MAC_NPAR ; # paragraphs allocated to this MAC
	shl	eax,(4-0)	; Convert from paras to bytes
	lea	edx,[ebx+(type MAC_STR)-1] ; End of this MAC entry space

	cmp	AGROUP:[ebx].MAC_TYPE,@MAC_END ; Ending entry?
	je	short @F	; Skip inclusion of next MAC header if so

	add	edx,(type MAC_STR) ; Account for next MAC header
@@:
	add	edx,eax 	; ...

; EBX = V86 linear address of the MAC entry being examined
; EDX = V86 linear address of next MAC entry

	mov	eax,ebx 	; Copy V86 linear address of MAC entry
	shr	eax,(12-0)	; Convert from linear address to page #

	shr	edx,(12-0)	; Convert from linear address to page #

; EAX = page # of 1st page
; EDX = page # of last page (inclusive)

FHDM_ILP:
	bts	HIGHDOS_MAP,eax ; Set bit for this page

	inc	eax		; Bump to next page

	cmp	eax,edx 	; Did we get 'em all yet?
	jbe	short FHDM_ILP	; Jump to set next bit if not

; Advance to next MAC entry.

FHDM_ADVANCE:
	cmp	AGROUP:[ebx].MAC_TYPE,@MAC_END ; Ending entry?
	je	short @F	; Yes, exit loop

	movzx	eax,AGROUP:[ebx].MAC_NPAR ; # paragraphs allocated to this MAC
	shl	eax,(4-0)	; Convert from paras to bytes
	lea	ebx,[ebx+(type MAC_STR)] ; Advance to next MAC entry
	add	ebx,eax 	; ...

	jmp	short FHDM_NXT	; Continue on to next MAC entry

@@:
FHDM_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
FILL_HIGHDOS_MAP endp		; End FILL_HIGHDOS_MAP procedure
	NPPROC	FILL_WIN3 -- Fill In Windows 3 Paging Import Data
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Fill in Windows 3 Paging Import Data structure

All EGP registers except EBP clobbered.

|

	REGSAVE <ds,es,fs>	; Save registers

	push	DTE_PDT 	; Get our PDT selector
	pop	fs		; Address it
	assume	fs:PDTGRP	; Tell the assembler about it

; Fill in WIN3 Paging Import Data ==============================================

	mov	esi,PWIN3_PAGE	; DS:ESI ==> Paging Import Data

	push	ds		; Save for a moment

	push	DTE_DSHI	; Get data selector for high DOS memory
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	mov	ax,WIN3_VERSION ; Get major/minor version #

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	mov	WIN3_VERSION,ax ; Save in extended memory storage

	cmp	ax,0300h	; Izit Windows 3.00 or earlier?
	mov	ax,0100h	; Assume so
	mov	cl,0		; Assume no UMB maps
	jbe	short @F	; Jump if so

	mov	ax,010Bh	; Assume we're using 1.11
	mov	cl,((1024-640)/16) ; Number of EMM_Import_UMB_Map entries
@@:
	mov	PGROUP:[esi].EMM_Import_Version,ax ; Save in structure
	mov	PGROUP:[esi].EMM_Import_UMB_Cnt,cl ; Save in structure
	mov	PGROUP:[esi].EMM_Import_Flags,0 ; Clear the flags

; Mark if any Fast Register Set is allocated

	lea	di,AMRS_TAB	; ES:DI ==> AMRS usage table
	mov	cx,MRS_MAX	; CX = length of ...
	jcxz	@F		; Jump if none
	mov	al,@AMRS_INUSE	; AL = AMRS in use value
  repne scas	AMRS_TAB[di]	; Search for any allocated AMRSs
	jne	short @F	; Jump if none

	or	PGROUP:[esi].EMM_Import_Flags,EMM_I_F_FRSAlloced
@@:

; Fill in OS/E access key

	mov	eax,ACCKEY	; Get OS/E access key
	mov	PGROUP:[esi].EMM_Import_OSKey,eax ; Save in struc

; Save 4E03h value
; Ensure it's no smaller than 4 + 3 * NPHYS16S

	mov	al,3		; Get per element size
	mul	NPHYS16S	; Times # physical 16KB pages in EMS system
	add	ax,4		; Plus 4

	cmp	ax,RPNCURSIZ	; Check against # bytes in RPNCUR save area
	jae	short @F	; Jump if they're bigger

	mov	al,RPNCURSIZ.LO ; Use our size
@@:
	mov	PGROUP:[esi].EMM_Import_CntxtSz,al ; Save in structure

; Fill in EMM_Import_Context data, one entry per 16KB page in the first MB

; ==============================================================================

; Zero the contents except for the handle which is set to @NUL_HNDL
; Get size of area in units of (size EMM_Import_Context)

	mov	cx,1024/16	; # 16KB pages in 1MB
	lea	edi,[esi].EMM_Import_Cntxt ; ES:EDI ==> EMM_Import_Context data
	xor	ax,ax		; A convenient zero
@@:
	mov	PGROUP:[edi].Import_Cntxt_Flags,al ; Clear the flags
	mov	PGROUP:[edi].Import_Cntxt_Hand,@NUL_HNDL ; Set NUL handle
	mov	PGROUP:[edi].Import_Cntxt_LPag,@RPN_UNMAP ; Unmap LPN
	mov	PGROUP:[edi].Import_Cntxt_PPag,al ; Zero PPN
	mov	PGROUP:[edi].Import_Cntxt_EFlgs,al ; Zero non-EMM/UMB flags

	add	edi,size EMM_Import_Context ; Skip to next entry

	loop	@B		; Jump if more structure entries to initialize

	cmp	NPHYS16S,0	; Check # physical 16KB pages in EMS system
	je	near ptr FILL_WIN3_XEMS ; Jump if none

; Skip over SCREEN handle

	test	CM2_FLAG,@CM2_SCR ; Izit specified?
	jz	short @F	; Jump if not

	cmp	NPHYS16S,4	; Check # physical 16KB pages in EMS system
	je	near ptr FILL_WIN3_XEMS ; Jump if none other than SCREEN
@@:

; ==============================================================================

COMMENT|

Register usage:

DX	=	handle #
CX	=	LPN within handle DX
BX	=	RPN within handle DX
DS:ESI	==>	EMM_Import_Data structure

|

; Loop through the EMS handles

	xor	edx,edx 	; Start with handle zero
FILL_WIN3_NEXTHNDL:
	FIXICALL PGROUP:FVALID_HNDL,DTE_CS2 ; Ensure it's a valid handle
	jnc	near ptr FILL_WIN3_UNUSED ; Jump if not in use

; Skip over SCREEN handle

	test	CM2_FLAG,@CM2_SCR ; Izit specified?
	jz	short @F	; Jump if not

	cmp	dl,@SCR_HNDL	; Izit the SCREEN handle?
	je	short FILL_WIN3_UNUSED ; Jump if so
@@:
	movzx	ebx,dx		; Copy to index register
	shl	ebx,2		; Times four to index table of dwords
	add	ebx,PHNDLPAGE	; EBX ==> HNDLPAGE[ebx] ==> PAGELINK[??]
	xor	cx,cx		; Initialize LPN
FILL_WIN3_NEXTRPN1:
	mov	ebx,PGROUP:[ebx].PL_NEXT ; EBX = next link

	cmp	ebx,HP_LAST	; Check for last entry
	je	short FILL_WIN3_UNUSED ; Jump if no more

; Look for this RPN in RPNCUR

	mov	edi,PRPNCUR	; DS:EDI ==> current RPN table
	mov	eax,ebx 	; Copy to SCASW register
	sub	eax,PPAGELINK	; Less start to get RPN

	push	ecx		; Save for a moment
	movzx	ecx,NPHYS16S.ELO ; Get # physical 16KB pages in EMS system
  repne scas	PGROUP:[edi].RPN_RPN ; Search for it
	pop	ecx		; Restore
	jne	short FILL_WIN3_UNMAP ; Jump if it's not mapped

	sub	edi,size RPN_RPN ; Back off to found value
	sub	edi,PRPNCUR	; Less start to get PPN * 2

; Translate this PPN to a VM86 segment

	add	edi,PPHYS2SEG	; Plus start of PHYS2SEG table
	movzx	edi,PGROUP:[edi].ELO ; DI has segment # in paras of this
				; physical page (multiple of 4KB in paras)
	shr	di,14-4 	; Convert from paras to 16KB
	imul	di,size EMM_Import_Context ; Times size of struc

; Save handle # (DL), LPN (CX), and PPN (AL)

	mov	PGROUP:[esi+edi].EMM_Import_Cntxt.Import_Cntxt_Hand,dl
	mov	PGROUP:[esi+edi].EMM_Import_Cntxt.Import_Cntxt_LPag,cx
FILL_WIN3_UNMAP:
	inc	cx		; Skip to next LPN

	jmp	short FILL_WIN3_NEXTRPN1 ; Go around again


FILL_WIN3_UNUSED:
	inc	dx		; Skip to next handle #

	cmp	dx,@MAX_EHNDLCNT ; Check against maximum EMS handle #
	jb	near ptr FILL_WIN3_NEXTHNDL ; Jump if still within range

; ==============================================================================

; Mark unmapped and identity-mapped EMS pages as such
; Note that the case of NPHYS16S == 0 has already been handled above

	mov	cx,NPHYS16S.ELO ; Get # physical 16KB pages in EMS system
	mov	edi,PRPNCUR	; DS:EDI ==> current RPN table
FILL_WIN3_NEXTRPN2:
	mov	ax,PGROUP:[edi].RPN_RPN ; Get RPN of next PPN

	cmp	ax,@RPN_IDENT	; Check for identity or unmapped LPN
	jb	short FILL_WIN3_XIDENT ; Jump if not

	push	edi		; Save for a moment

	sub	edi,PRPNCUR	; Less start to get PPN * (size RPN_STR)
;;;;;;; shr	edi,1		; Convert from RPN_STR to bytes
;;;;;;; shl	edi,1		; Convert from bytes to PHYS2SEG
	add	edi,PPHYS2SEG	; Plus start of PHYS2SEG table
	movzx	edi,PGROUP:[edi].ELO ; EDI has segment # in paras of this
				; physical page (multiple of 4KB in paras)

; Skip over EMS-mappable SCREEN pages

	test	CM2_FLAG,@CM2_SCR ; Izit specified?
	jz	short FILL_WIN3_NEXTRPN3 ; Jump if not

	cmp	di,0B000h	; Izit an EMS-mappable SCREEN page?
	jb	short FILL_WIN3_NEXTRPN3 ; Jump if not

	cmp	di,0C000h	; Izit an EMS-mappable SCREEN page?
	jb	short FILL_WIN3_NEXTRPN4 ; Jump if so
FILL_WIN3_NEXTRPN3:
	shr	di,14-4 	; Convert from paras to 16KB
	imul	di,size EMM_Import_Context ; Times size of struc
	mov	PGROUP:[esi+edi].EMM_Import_Cntxt.Import_Cntxt_LPag,ax
FILL_WIN3_NEXTRPN4:
	pop	edi		; Restore
FILL_WIN3_XIDENT:
	add	edi,size RPN_STR ; Skip to next RPN entry

	loop	FILL_WIN3_NEXTRPN2 ; Jump if more RPNs to check

; ==============================================================================

; Mark EMS page frame entries as such

	mov	cx,NPHYS16F.ELO ; Get # physical 16KB pages in EMS frame
	jcxz	FILL_WIN3_XFRAME ; Jump if none
	movzx	edi,FRAME	; Get starting para of EMS page frame
	shr	di,14-4 	; Convert from paras to 16KB
FILL_WIN3_NEXTEMS:
	push	di		; Save for a moment

	imul	di,size EMM_Import_Context ; Times size of struc
	or	PGROUP:[esi+edi].EMM_Import_Cntxt.Import_Cntxt_Flags,I_Ctxt_F_LIM320

	pop	di		; Restore

	inc	di		; Skip to next 16KB page

	loop	FILL_WIN3_NEXTEMS ; Jump if more pages in EMS page frame
FILL_WIN3_XFRAME:

; ==============================================================================

; Mark EMS-mappable pages as such

	mov	cx,NPHYS16S.ELO ; Get # physical 16KB pages in EMS system
	mov	edi,PPHYS2SEG	; ES:EDI ==> EMS-mappable segment #s
	xor	al,al		; Initialize PPN
FILL_WIN3_NEXTPPN:
	push	edi		; Save for a moment

	movzx	edi,PGROUP:[edi].ELO ; EDI = segment # of next PPN

; Skip over EMS-mappable SCREEN pages

	test	CM2_FLAG,@CM2_SCR ; Izit specified?
	jz	short FILL_WIN3_NEXTPPN1 ; Jump if not

	cmp	di,0B000h	; Izit an EMS-mappable SCREEN page?
	jb	short FILL_WIN3_NEXTPPN1 ; Jump if not

	cmp	di,0C000h	; Izit an EMS-mappable SCREEN page?
	jb	short FILL_WIN3_NEXTPPN2 ; Jump if so
FILL_WIN3_NEXTPPN1:
	shr	di,14-4 	; Convert from paras to 16KB
	imul	di,size EMM_Import_Context ; Times size of struc
	or	PGROUP:[esi+edi].EMM_Import_Cntxt.Import_Cntxt_Flags,I_Ctxt_F_IsEMM
	mov	PGROUP:[esi+edi].EMM_Import_Cntxt.Import_Cntxt_PPag,al
FILL_WIN3_NEXTPPN2:
	pop	edi		; Restore

	add	edi,2		; Skip to next PHYS2EG index
	inc	al		; Skip to next PPN

	loop	FILL_WIN3_NEXTPPN ; Jump if more PPNs
FILL_WIN3_XEMS:

; Skip to next byte

	mov	edi,esi 	; Copy pointer to import structure
	lea	esi,[esi].EMM_Import_UMB ; Point to UMB maps

; ==============================================================================

; PGROUP:[edi].EMM_Import_Data ==> EMM import data
; PGROUP:[esi].EMM_Import_UMB  ==> EMM_Import_UMB maps

; Split cases based upon Windows 3 version #

	cmp	WIN3_VERSION,0300h ; Izit Windows 3.00?
	je	near ptr FILL_WIN3_XUMB ; Jump if so

; Fill in EMM_Import_UMB_Map structure
; Update ESI to point to next available byte

	mov	esi,edi 	; Restore pointer to import structure

; Fill the EMM_Import_UMB maps with known value for debugging purposes

	movzx	ecx,PGROUP:[esi].EMM_Import_UMB_Cnt ; Get the count
	imul	ecx,(type EMM_Import_UMB_Map)/4 ; Times entry size/4 to
				; get # dwords
	mov	eax,-1		; Le Arbitrary Value
	lea	edi,[edi].EMM_Import_UMB ; Point to UMB maps
    rep stos	PGROUP:[edi].EDD ; Fill 'er up

	mov	edi,0A0h	; Start off with A0h page

; Note that the PTE index in ESI is also used to as a linear page #

FILL_WIN3_UMB_NXT:
	mov	eax,OFFPDT[edi*4] ; Get PTE

	test	eax,mask $PTE_AV0 ; Is this an EMS mappable page?
	jnz	near ptr FILL_WIN3_XUMB0 ; Yes, so it's not a UMB page

	test	eax,mask $PTE_RW ; Is this a ROM?
	jz	near ptr FILL_WIN3_XUMB0 ; Yes, so it's not a UMB page

;;;;;;; and	edx,(mask $PTE_FRMHI) or (mask $PTE_FRM) ; Isolate addr field
	shr	eax,(12-0)	; Isolate and convert to physical page #

	cmp	edi,eax 	; Is it mapped 1:1?
	je	near ptr FILL_WIN3_XUMB0 ; Yes, so it's not a UMB page

; Check for FlexROMed memory-mapped I/O pages

	test	FLEXROM_FLAG,@FR_ACTIVE ; Anything being Flexed?
	jz	near ptr FILL_WIN3_UMB1 ; Jump if not

	REGSAVE <eax,bx,ecx,edx> ; Save registers

	xor	bx,bx		; Zero index into FlexROM table
FILL_WIN3_NEXTFLEX:
	movzx	edx,FLEXROM_TBL[bx].FLEX_DST ; Get ROM destination segment
	shr	dx,(12-4)	; Convert segment to page number

	cmp	di,dx		; Compare against UMB page
	jb	short @F	; Skip if not in range (too low)

	shl	edx,(12-0)	; Convert pages to bytes
	movzx	ecx,FLEXROM_TBL[bx].FLEX_LEN ; Get ROM length
	add	edx,ecx 	; Add to get end of ROM

	shr	edx,(12-0)	; Convert bytes to pages

	cmp	di,dx		; Compare against UMB page
	jae	short @F	; Skip if not in range (too high)

; We have found our page within a Flexed ROM

	mov	dx,FLEXROM_TBL[bx].FLEX_DST ; Get ROM destination segment
	shr	dx,(12-4)	; Convert segment to page number
	sub	dx,di		; Subtract our UMB page number
	neg	dx		; ...

	bt	FLEXROM_TBL[bx].FLEX_MAP,dx ; Is page memory-mapped I/O?
	jc	short FILL_WIN3_MEMIO ; Jump if so (CF significant)
@@:
	add	bx,@FLEXROM_STRLEN ; Point to next entry

	cmp	bx,FLEXROM_LEN	; More ROMs to process?
	jb	short FILL_WIN3_NEXTFLEX ; Jump if more entries
				; N.B. CF is clear
FILL_WIN3_MEMIO:
	REGREST <edx,ecx,bx,eax> ; Restore registers

	jc	short FILL_WIN3_XUMB0 ; Skip if memory-mapped I/O
FILL_WIN3_UMB1:

; Test for SQUEEZED out high DOS pages

	movzx	edx,di		; UMB linear page # (00h - FFh)

	bt	HIGHDOS_MAP,edx ; Is this a high DOS memory page?
	jnc	short FILL_WIN3_XUMB0 ; Jump if not
FILL_WIN3_UMB2:

; DI is a UMB page number that needs to be filled in the structures
; EAX is the physical page #

	mov	dx,di		; Get the UMB linear page #
	sub	dx,0A0h 	; UMB maps start at 0A0h
	mov	PGROUP:[esi+edx*4].EMM_Import_UMB.edd,eax ; Physical page #

	mov	dx,di		; Get the UMB linear page #
	shr	dx,2		; Convert from 4KB to 16KB
	imul	dx,size EMM_Import_Context ; Times size of structure

; DX is byte index into EMM_Import_Contxt

	mov	ax,di		; UMB linear page #
	sub	ax,0A0h 	; UMB maps start at 0A0h
	shr	al,2		; Convert from 4KB to 16KB

; AX is struc index into EMM_Import_UMB

	mov	PGROUP:[esi+edx].EMM_Import_Cntxt.Import_Cntxt_UMB_Indx,al

	mov	cx,di		; UMB linear page #
	and	cl,3		; Isolate 4KB page within 16KB page
	mov	al,I_Ctxt_F_UMBPg0 ; Bit for page 0
	shl	al,cl		; Form correct flag bit
	or	PGROUP:[esi+edx].EMM_Import_Cntxt.Import_Cntxt_Flags,al
FILL_WIN3_XUMB0:
	inc	di		; Bump to next page

	cmp	di,100h 	; Are we done with all possible UMBs?
	jb	near ptr FILL_WIN3_UMB_NXT ; No, so do the next one

; Advance past UMB maps

	lea	esi,[esi+((1024-640)/16) * size EMM_Import_UMB_Map].EMM_Import_UMB
FILL_WIN3_XUMB:

; ==============================================================================

; Fill in EMM_Import_Handle structure
; Update ESI to point to next available byte

	movzx	eax,EHNDLCNT.LO ; Return # active EMS handles in AL

; Skip over SCREEN handle

	test	CM2_FLAG,@CM2_SCR ; Izit specified?
	jz	short @F	; Jump if not

	dec	al		; Count out the SCREEN handle
@@:
	mov	PGROUP:[esi].LO,al ; Save in struc
	inc	esi		; Skip over it

; Get address of where to save PTEs

	imul	eax,size EMM_Import_Handle ; Times size of struc
	lea	edi,[esi+eax]	; ES:EDI ==> End of 1.0 GPIS data

; There's additional information for version of WPIS used for Windows 3.1

	cmp	WIN3_VERSION,0300h ; Izit Windows 3.00?
	je	short @F	; Jump if so

	add	edi,4+4+1+1+1+@WIN3_IMPORT_VENDOR_LEN+@WIN3_IMPORT_PRODUCT_LEN
				; Skip over 1.11 import data:
				; EMM_Import_INT67 dd ? 	  ; 4 bytes
				; EMM_Import_HMAAliasPhysPtr dd ? ; 4 ...
				; EMM_Import_Free_Cnt db 0	  ; 1 ...
				; EMM_Import_XMS_Cnt db 0	  ; 1 ...
				; EMM_Import_FreeUMB_Cnt db 0	  ; 1 ...
				; Vendor and product names
	cmp	WINSIZE,0	; Izit invalid?
	je	short @F	; Jump if so

	add	edi,type EMM_Import_FreeReg ; Skip over struc
@@:

; PGROUP:EDI ==> save area for PTEs

	xor	edx,edx 	; Start with handle zero
FILL_WIN3_NEXTHNDL2:
	FIXICALL PGROUP:FVALID_HNDL,DTE_CS2 ; Ensure it's a valid handle
	jnc	near ptr FILL_WIN3_UNUSED2 ; Jump if not in use

; Skip over SCREEN handle

	test	CM2_FLAG,@CM2_SCR ; Izit specified?
	jz	short @F	; Jump if not

	cmp	dl,@SCR_HNDL	; Izit the SCREEN handle?
	je	near ptr FILL_WIN3_UNUSED2 ; Jump if so
@@:
	mov	PGROUP:[esi].Import_HandleNum,dl ; Save the handle #

	mov	ebx,edx 	; Move to index register
	shl	ebx,3-0 	; Convert from two dwords to bytes
	add	ebx,PHNDLNAME	; DS:EBX ==> this handle's name
	mov	eax,PGROUP:[ebx].EDQLO ; Get low-order word of handle name
	mov	PGROUP:[esi].Import_HandleName.EDQLO,eax ; Save in struc
	mov	eax,PGROUP:[ebx].EDQHI ; Get high-...
	mov	PGROUP:[esi].Import_HandleName.EDQHI,eax ; Save in struc

	mov	ebx,edx 	; Copy handle
	shl	ebx,1		; Times two to index table of words
	add	ebx,PHNDLCNT	; Plus pointer to handle-count table
	mov	ax,PGROUP:[ebx] ; Get LPN count
	mov	PGROUP:[esi].Import_NumLogPages,ax ; Save in struc

; Set flags

	cmp	PGROUP:[esi].Import_HandleName.EDQLO,0 ; Izit valid?
	jne	short @F	; Jump if so

	cmp	PGROUP:[esi].Import_HandleName.EDQHI,0 ; Izit valid?
	je	short FILL_WIN3_NONAME ; Jump if not
@@:
	or	PGROUP:[esi].Import_HandleFlags,HF_Imp_HasName
FILL_WIN3_NONAME:
	FIXICALL PGROUP:FCHECK_HFRMSAV,DTE_CS2 ; Return ZF=1 if handle DL is free
				; DS:EBX = corresponding record
	jz	short FILL_WIN3_XSAVE ; Jump if no context saved for it

	or	PGROUP:[esi].Import_HandleFlags,HF_Imp_SavedContext
	mov	eax,PWIN3_PAGE	; DS:EAX ==> Paging Import Data
	or	PGROUP:[eax].EMM_Import_Flags,EMM_I_F_HandHasContext
FILL_WIN3_XSAVE:
	push	DTE_DS		; Pass our data selector
	FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	add	eax,edi 	; Plus offset to get linear address
	call	LIN2PHYS	; Translate linear EAX to physical EAX
	mov	PGROUP:[esi].Import_PhysPtrToPTEs,eax ; Save in struc

; Copy PTEs to PGROUP:[edi]

	movzx	ebx,dx		; Copy handle #
	shl	ebx,2		; Times four to index table of dwords
	add	ebx,PHNDLPAGE	; EBX ==> HNDLPAGE[ebx] ==> PAGELINK[??]
FILL_WIN3_NEXTLPN2:
	mov	ebx,PGROUP:[ebx].PL_NEXT ; EBX = next link

	cmp	ebx,HP_LAST	 ; Check for last entry
	je	short FILL_WIN3_UNMAP2 ; Jump if no more LPNs

	REGSAVE <ebx,esi>	; Save for a moment

	sub	ebx,PPAGELINK	; Convert to RPN
	mov	esi,ebx 	; Save for a moment
;;;;;;; shl	ebx,2-2 	; Convert from dword to dword index
	add	ebx,PLINKBASE	; Plus base of PDT PTEs
	shl	esi,4-2 	; Convert from dword to four-dword index
	add	esi,PGROUP:[ebx] ; Plus the corresponding offset

; FS:ESI = address of PTEs in PDT for this 16KB page

	mov	ecx,16/4	; # PTEs in 16KB
S32 rep movs	<PGROUP:[edi].EDD,OFFPDT[esi]> ; Copy the PTEs

	REGREST <esi,ebx>	; Restore

	jmp	short FILL_WIN3_NEXTLPN2 ; Go around again


FILL_WIN3_UNMAP2:
	add	esi,size EMM_Import_Handle ; Skip to next struc entry
FILL_WIN3_UNUSED2:
	inc	dx		; Skip to next handle #

	cmp	dx,@MAX_EHNDLCNT ; Check against maximum EMS handle #
	jb	near ptr FILL_WIN3_NEXTHNDL2 ; Jump if still within range

; ==============================================================================

; Split cases based upon Windows 3 version #

	cmp	WIN3_VERSION,0300h ; Izit Windows 3.00?
	je	near ptr FILL_WIN3_XBACK ; Jump if so

; Fill in EMS back door pointer
; Update ESI to point to next available byte

	mov	ax,HIMEM_CS	; Get segment of high DOS memory
	shl	eax,16		; Shift ot high-order word
	lea	ax,RESINT67	; Get offset of our INT 67h handler
	mov	PGROUP:[esi],eax ; Save in struc
	add	esi,4		; Skip over it

; Fill in HMA alias physical pointer
; only if the HMA is aliased; otherwise use 0.
; Update ESI to point to next available byte

; Check the current A20 count just in case there's some odd state we
; can get into where A20 is disabled and the PTEs are wrapping at 1MB
; (we wouldn't want to check those PTEs).

	cmp	A20CNT,@A20DEF	; Check the current A20 count
	je	short FILL_WIN3_HMA_ONE ; Jump if it's disabled

	test	XMS_FLAG,mask $XMS_XHMA ; Izit available at all?
	jnz	short FILL_WIN3_HMA_ONE ; Jump if not

	mov	edi,PPDT1MB	; Offset of 1st PTE above 1 MB
	mov	cx,64/4 	; Get # PTEs in the HMA
	mov	ebx,CON1MB	; Get 1st one-to-one value
@@:
	mov	eax,OFFPDT[edi] ; Get the next PTE
	and	eax,@PTE_FRM	; Isolate the frame

	cmp	eax,ebx 	; Izit one-to-one?
	jne	short FILL_WIN3_HMA_ALIAS ; Jump if not

	add	ebx,CON4KB	; Skip to next PTE
	add	edi,4		; ...

	loop	@B		; Jump if more PTEs to check
FILL_WIN3_HMA_ONE:
	xor	eax,eax 	; Mark as not aliased

; HMA not aliased

	jmp	short FILL_WIN3_HMA_END ; Join common code


FILL_WIN3_HMA_ALIAS:
	push	DTE_PDT 	; Pass our PDT selector
	FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base of selector

	add	eax,PPDT1MB	; Offset to 1st PTE above 1MB
	call	LIN2PHYS	; Translate linear EAX to physical EAX
FILL_WIN3_HMA_END:
	mov	PGROUP:[esi],eax ; Fill in EMM_Import_HMAAliasPhysPtr
	add	esi,4		; Skip over it

; Fill in Free physical pages count
; Update ESI to point to next available byte

	mov	eax,WINSIZE	; Get PHYSIZE for Windows in 1KB
	mov	ebx,PHYSIZE	; Get reduced PHYSIZE in 1KB

	sub	eax,ebx 	; Less reduced PHYSIZE
	jbe	short FILL_WIN3_FR_NONE ; Jump if nothing extra

	shr	eax,12-10	; Convert from 1KB to 4KB
	shr	ebx,12-10	; ...

	mov	PGROUP:[esi].LO,1 ; Fill in EMM_Import_Free_Cnt
	inc	esi		; Skip over it

	mov	PGROUP:[esi].Import_Free_Start,ebx ; Fill in starting page #
	mov	PGROUP:[esi].Import_Free_Cnt,eax ; Fill in 4KB page count
	add	esi,type EMM_Import_FreeReg ; SKip over struc

	jmp	short FILL_WIN3_FR_END ; Join common end code


FILL_WIN3_FR_NONE:
	mov	PGROUP:[esi].LO,0 ; Fill in EMM_Import_Free_Cnt
	inc	esi		; Skip over it
FILL_WIN3_FR_END:

; Fill in XMS handle array count
; Note that this value of zero must be used with the EMM_I_F_NoXMSHndInfo flag
; Update ESI to point to next available byte

	mov	eax,PWIN3_PAGE	; DS:EAX ==> Paging Import Data
	or	PGROUP:[eax].EMM_Import_Flags,EMM_I_F_NoXMSHndInfo

	mov	PGROUP:[esi].LO,0 ; Fill in EMM_Import_xMS_Cnt
	inc	esi		; Skip over it

; Fill in free UMB count
; Note that this value of zero must be used with the EMM_I_F_NoXMSUMBInfo flag
; Update ESI to point to next available byte

	mov	eax,PWIN3_PAGE	; DS:EAX ==> Paging Import Data
	or	PGROUP:[eax].EMM_Import_Flags,EMM_I_F_NoXMSUMBInfo

	mov	PGROUP:[esi].LO,0 ; Fill in EMM_Import_FreeUMB_Cnt
	inc	esi		; Skip over it

; Fill in the vendor and product strings

	mov	edi,esi 	; EDI ==> strings in import data

	mov	ecx,@WIN3_IMPORT_VENDOR_LEN ; Length to copy
	lea	esi,WIN3_IMPORT_VENDOR ; ESI ==> model vendor string
S32 rep movs	<PGROUP:[edi].LO,PGROUP:[esi].LO> ; Copy vendor to import data

	mov	ecx,@WIN3_IMPORT_PRODUCT_LEN ; Length to copy
	lea	esi,WIN3_IMPORT_PRODUCT ; ESI ==> model product string
S32 rep movs	<PGROUP:[edi].LO,PGROUP:[esi].LO> ; Copy product to import data

	mov	esi,edi 	; ==> next available byte in paging import data
FILL_WIN3_XBACK:

; ==============================================================================

; Calculate size of structure

	mov	eax,PWIN3_PAGE	; Get starting offset
	sub	esi,eax 	; Subtract to get length
	mov	PGROUP:[eax].EMM_Import_Length,si ; Save in struc

; End of WIN3 Paging Import Data fill ==========================================

	REGREST <fs,es,ds>	; Restore
	assume	ds:PGROUP,es:nothing,fs:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_WIN3 endp			; End FILL_WIN3 procedure
endif				; IF @OEM_WIN3
if @OEM_WIN3 or @OEM_VIRTUALMEM
	NPPROC	LIN2PHYS -- Translate Linear To Physical Address
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate a linear address to a physical address

On entry:

EAX	=	Linear address

On exit:

EAX	=	Physical address

|

	REGSAVE <edx,fs>	; Save for a while

; EAX = input linear address

	mov	edx,eax 	; Save a copy of the linear address

	push	DTE_PDT 	; Get our PTE selector
	pop	fs		; Address it
	assume	fs:PDTGRP	; Tell the assembler about it

; FS:0 = physical address of start of PTEs

	and	eax,((mask $LA_DIR) or (mask $LA_PAGE)) ; Isolate non-offset portion
	shr	eax,($LA_PAGE-2)-0 ; Convert from bytes to 4KB in dwords
	mov	eax,OFFPDT[eax] ; Get the PTE
	and	ax,mask $PTE_FRM ; Keep just the address part

; EAX = physical address of start of corresponding 4KB page

	and	edx,mask $LA_OFF ; Isolate the offset portion
	add	eax,edx 	; Add offset to physical address of page

; EAX = physical address corresponding to input linear address

	REGREST <fs,edx>	; Restore
	assume	fs:nothing	; Tell the assembler about it

	ret			; To caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LIN2PHYS endp			; End LIN2PHYS procedure
endif				; IF @OEM_WIN3 or @OEM_VIRTUALMEM
if @OEM_WIN3 or @OEM_VIRTUALMEM
	FPPROC	FLIN2PHYS -- Far call to LIN2PHYS
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See LIN2PHYS

|

	call	LIN2PHYS	; Translate EAX (linear) to physical

	ret			; To caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FLIN2PHYS endp			; End FLIN2PHYS procedure
endif				; IF @OEM_WIN3 or @OEM_VIRTUALMEM
if @OEM_WIN3 or @OEM_VIRTUALMEM
	NPPROC	PHYS2LIN -- Translate physical address to linear
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate physical to linear.

We do this both in the Windows import context and with nested DPMI
clients.  Each nested client has its own address space, and the PDEs
are different, so we need to go through a second level of
indirection.  This should not be necessary under Windows.

On entry:
EBX	 Physical address

On exit:
If CF=0,
EBX	 Linear address (using current CR3)

If CF=1,
corresponding linear address not found.

|

	REGSAVE <eax,ecx,edx,esi,edi,ds,fs> ; Save

	mov	edx,ebx 	; Save input address
	and	ebx,not (mask $LA_OFF) ; Isolate the 4KB frame

	mov	ds,JSEL_DS3	; Get addressability to PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	push	DTE_PDT 	; Get our PDT selector
	pop	fs		; Address it
	assume	fs:PDTGRP	; Tell the assembler about it

; FS:0 = linear address of 2nd level PTEs

	mov	ecx,TOTSIZE	; Get total size of extended memory
	shr	ecx,(2-0)	; Convert size in 1 KB to size in 4 KB (# PTEs)

	mov	esi,PPDT1MB	; Offset of 1st PTE above 1 MB
P2L_NXT:
	lods	OFFPDT[esi]	; Get next PTE

	test	ax,mask $PTE_P	; Izit present?
	jz	short P2L_LOOP	; Jump if not

	and	eax,not (mask $LA_OFF) ; Isolate the 4KB frame

	cmp	eax,ebx 	; Same value?
	jne	short P2L_LOOP	; Jump if not

; We've hit the physical address in question

	mov	eax,esi 	; Offset to next PTE
	sub	eax,size OFFPDT ; Back up offset to PTE just examined
	shl	eax,($LA_PAGE-2)-0 ; Convert from 4KB in dwords to bytes

	mov	ebx,edx 	; Get input physical address
	and	ebx,(mask $LA_OFF) ; Isolate the offset within the 4KB page
	add	ebx,eax 	; Form linear address for return (note CF=0)
	jmp	short P2L_EXIT	; Join common exit

P2L_LOOP:
	LOOPD	P2L_NXT 	; Jump if more PTEs to search

; We exhausted all the PTEs without finding the input physical address
	stc			; Mark as not found

P2L_EXIT:
	REGREST <fs,ds,edi,esi,edx,ecx,eax> ; Restore
	assume	ds:nothing,fs:nothing ; Tell the assembler

	ret			; To caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PHYS2LIN endp			; End PHYS2LIN procedure
endif				; IF @OEM_WIN3 or @OEM_VIRTUALMEM
if @OEM_WIN3 or @OEM_VIRTUALMEM
	FPPROC	FPHYS2LIN -- Far call to PHYS2LIN
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See PHYS2LIN

|

	call	PHYS2LIN	; Translate EBX (physical) to linear
	ret			; To caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FPHYS2LIN endp			; End FPHYS2LIN procedure
endif				; IF @OEM_WIN3 or @OEM_VIRTUALMEM
if @OEM_WIN3
	NPPROC	COPY_INST_DATA -- Sort Out UMB Instance Data Items
	assume	ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Copy UMB instance data items to our local buffer for the VxD.

Windows 3.00 can not handle UMB instance data items so we filter them out.
The LoadHi portion of the VxD will instance them.

Windows 3.10 can instance these items itself, so we do not filter them out,
we simply copy them for our own inspection in the VxD.

On entry:

SS:EBP	==>	INTXX_STR
ESI3	=	32-bit physical address of undocumented Windows 3 WIN3UNK_STR
		 Passed to the WIN3_CB in ESI
CX	=	Maximum number of entries that'll fit in local table
		 Each item is defined by IIS_STR.

On exit:

CF	=	0 indicates success
	=	1 indicates failure due to overfull table

|

	REGSAVE <eax,ebx,cx,edx,esi,edi,es> ; Save caller's registers

	push	DTE_DS		; Get data selector for extended memory
	pop	es		; Address it
	assume	es:PGROUP	; Tell the assembler about it
	mov	edi,PUMB_INST	; ES:EDI ==> local UMB instance table

; AGROUP:ESI3 ==> WIN3UNK structure

	mov	esi,[ebp].INTXX_ESI ; Get caller's ESI

	cmp	AGROUP:[esi].WIN3UNK_FLG,1 ; Are there any instance data items present?
	jne	near ptr CID_OK ; No, that was easy

	mov	ebx,AGROUP:[esi].WIN3UNK_SIS ; Get 32-bit linear address of WIN3SIS

; AGROUP:EBX ==> WIN3_START_STR

	movzx	eax,AGROUP:[ebx].SIS_INSTANCE_DATA_PTR.VSEG ; Get segment
	shl	eax,4-0 	; Convert paras to bytes
	movzx	esi,AGROUP:[ebx].SIS_INSTANCE_DATA_PTR.VOFF ; Get offset
	add	esi,eax 	; Add to get 32-bit linear address
	jz	near ptr CID_OK ; Nothing in the table so we're done

; AGROUP:ESI ==> a table of INSTANCE_ITEM_STRs

COMMENT|

Now we do the real work.  Any existing instance items in a UMB are copied
to our local table.  The remaining items are shifted down.  If there are
no instance data items remaining in the original table we'll NULL the
SIS_Instance_Data_Ptr in the fake WIN3_START_STR.

For Windows 3.10 we don't shift the items down to filter out UMB items.

|

	push	esi		; Save start address of original table

	mov	ebx,esi 	; Output point to original table

COMMENT|

Register usage:

EBX	=	Resulting table offset
ESI	=	Next table offset
CX	=	Maximum number of entries that'll fit in local table
ES:EDI	==>	Local UMB instance table

|

CID_MDLP:
	lods	AGROUP:[esi].IIS_PTR ; Get ptr field of the next instance item
				; EAX is in Seg:Off format

	or	eax,eax 	; A zero marks the end of the table
	jz	short CID_EOL	; Jump if we're at the end of the list

	push	eax		; Save the original IIS_PTR

	movzx	edx,ax		; Copy offset
	shr	eax,16		; Move the segment to the low-order end
	shl	eax,(4-0)	; Convert to real-mode segment form
	add	edx,eax 	; Form 32-bit linear address
	shr	edx,4-0 	; Convert from bytes to paras

	pop	eax		; Restore original IIS_PTR

	cmp	dx,OLDDOS	; Is this IIS is a UMB?
	jae	short CID_FND	; Jump is so.  Copy into our table

; This instance data item does not live in a UMB.

	cmp	WIN3_VERSION,030Ah ; Izit Windows 3.10?
	jae	short @F	; Yes, so don't modify input table

	mov	AGROUP:[ebx].IIS_PTR,eax ; Leave in input table, shifted down
	lods	AGROUP:[esi].IIS_SIZE	; Get the IIS_SIZE
	mov	AGROUP:[ebx].IIS_SIZE,ax ; Copy the length also

	add	ebx,type INSTANCE_ITEM_STR ; Advance output ptr to next slot
@@:
	jmp	short CID_MDLP	; On to the next entry

; This entry specifies instance data in a UMB.	Copy it to our table.

CID_FND:
	jcxz	CID_FULL	; Jump if table is full
	dec	cx		; Account for entry about to be used

S32	stos	PGROUP:[edi].IIS_PTR ; Save IIS_PTR in our table
S32	movs	<PGROUP:[edi].IIS_SIZE,AGROUP:[esi].IIS_SIZE> ; Copy IIS_SIZE

	jmp	short CID_MDLP	; On to the next entry

; We've hit the end of the list.  If we removed all the entries from the
; original list, NULL out its pointer in the fake WIN3_START_STR

CID_EOL:
	pop	esi		; Restore original table pointer

	cmp	WIN3_VERSION,030Ah ; Izit Windows 3.10?
	jae	short @F	; Yes, so don't modify input table

	xor	eax,eax 	; EAX is already clear, but let's be sure

	cmp	ebx,esi 	; Have we stored anything back into the table?
	je	short CID_NONE	; No, so go NULL out the pointer

	mov	AGROUP:[ebx].IIS_PTR,eax ; Terminate the original table
@@:
	jmp	short CID_OK	; Join common normal exit code

; Oops, we're out of space in out local table.  Return an error indication

CID_FULL:
	pop	esi		; Restore original table pointer

	stc			; Indicate something went wrong

	jmp	short CID_EXIT	; Join common exit code


; All the instance data items were in UMBs.  Zap the entire table

CID_NONE:
	mov	esi,[ebp].INTXX_ESI ; Get caller's ESI
	mov	ebx,AGROUP:[esi].WIN3UNK_SIS ; Get 32-bit lin addr of WIN3SIS
	mov	AGROUP:[ebx].SIS_INSTANCE_DATA_PTR,eax ; NULL out the pointer

; Null terminate our local table

CID_OK:
	xor	eax,eax 	; Damn handy number, zero
S32	stos	PGROUP:[edi].IIS_PTR ; NULL out the IIS_PTR of the next entry

	clc			; Indicate things worked OK
CID_EXIT:
	REGREST <es,edi,esi,edx,cx,ebx,eax> ; Restore caller's registers
	assume	es:nothing	; Tell the assembler about it

	ret			; ... to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_INST_DATA endp		; End COPY_INST_DATA procedure
endif				; IF @OEM_WIN3
if @OEM_WIN3
	FPPROC	MAP_WIN3 -- Re-map EMS Pages As Per Windows 3 Exit State
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Re-map EMS pages as per Windows 3 exit state.

|

	REGSAVE <eax,ebx,ecx,edx,esi> ; Save registers

	mov	esi,PWIN3_PAGE	; DS:ESI ==> Paging Import Data
	lea	esi,[esi].EMM_Import_Cntxt ; DS:ESI ==> EMM_Import_Context data
	mov	cx,1024/16	; # 16KB pages in 1MB
MAP_WIN3_NEXT:

; Test for EMS-mappable pages

	test	PGROUP:[esi].Import_Cntxt_Flags,I_Ctxt_F_IsEMM ; Izit EMS_mappable?
	jz	short MAP_WIN3_LOOP ; Jump if not

	movzx	dx,PGROUP:[esi].Import_Cntxt_Hand ; Get the handle

	cmp	dx,@NUL_HNDL	; Izit the null handle?
	jne	short @F	; Jump if not

	mov	dx,@OSE_HNDL	; Use OSE handle
@@:
	movzx	ax,PGROUP:[esi].Import_Cntxt_PPag ; Get the PPN

	push	dx		; Pass the handle
	push	PGROUP:[esi].Import_Cntxt_LPag ; Pass the logical 16KB page # (origin-0)
	push	ax		; Pass the physical 16KB page # (origin-0)
	FIXICALL PGROUP:FPGMAP_COM,DTE_CS2 ; Call common page map routine
;;;;;;; jc	near ptr JMM_E8A ; Jump if logical page # not found
				; Return with AX = RPN
	mov	dx,ax		; Copy RPN

; Keep the RPNCUR up-to-date with RPN for this physical page

	mov	eax,size RPN_STR ; Get size of structure
	mul	PGROUP:[esi].Import_Cntxt_PPag ; Times physical 16KB page # (origin-0)
	mov	ebx,eax 	; Copy to index register
	add	ebx,PRPNCUR	; DS:EBX ==> current RPN table

	mov	PGROUP:[ebx].RPN_RPN,dx ; Save in structure
MAP_WIN3_LOOP:
	add	esi,size EMM_Import_Context ; Skip to next entry

	loop	MAP_WIN3_NEXT	; Jump if more EMS pages to check

; Ensure TLB flushed if necessary

	test	GLB_FLAG,@GLB_TLB ; Duzit need to be flushed?
	jz	short @F	; Jump if not

; Because we just changed the page table, we must flush the TLB

	FIXICALL PGROUP:FFLUSH_TLB,DTE_CS2 ; Flush the TLB

	and	GLB_FLAG,not @GLB_TLB ; Clear for next time
@@:
	REGREST <esi,edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MAP_WIN3 endp			; End MAP_WIN3 procedure
endif				; IF @OEM_WIN3
if @OEM_WIN3
	FPPROC	DMA_WIN3 -- Swap DMA Buffer if in conventional memory
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Swap DMA buffer if in conventional memory

This will be necessary on ...
* XT class machines
* Machines where there is no suitable DMA buffer area above 1 MB

|

	REGSAVE <eax,ecx,esi,edi,es,fs> ; Save registers

	test	CMD_FLAG,@CMD_XDM ; Doing DMA?
	jnz	short DMA_WIN3_EXIT ; Jump if not

	cmp	PPDTDMAP,((640*1024) shr ((12-2) - 0)) ; Within conv memroy?
	jae	short DMA_WIN3_EXIT ; Jump if above conventional memory

	push	DTE_D4GB	; Get our all memory selector
	pop	es		; Address it
	assume	es:AGROUP	; Tell the assembler about it

	movzx	ecx,DMASIZE	; Get size of DMA buffer in 1KB
	shl	ecx,10-2	; Convert from 1KB to dwords

	mov	esi,PPDTDMA	; Get offset in PDT of DMA buffer
	mov	edi,PPDTDMAP	; ...			   physical
	shl	esi,(12-2)-0	; Convert from 4KB in dwords to bytes
	shl	edi,(12-2)-0	; ...
	xor	ebx,ebx 	; Zero index into these items
@@:
	mov	eax,AGROUP:[esi+ebx*4] ; Get source dword
	xchg	eax,AGROUP:[edi+ebx*4] ; Swap with destin dword
	mov	AGROUP:[esi+ebx*4],eax ; Save as new source dword

	inc	ebx		; Skip to next source/destin dword

	loopd	@B		; Jump if more dwords to exchange

; Now swap the PTEs

	push	DTE_PDT 	; Get PDT selector
	pop	fs		; Ensure FS points to the PDT
	assume	fs:PDTGRP	; Tell the assembler about it

	mov	esi,PPDTDMA	; Get offset in PDT of DMA buffer
	mov	edi,PPDTDMAP	; ...			   physical

	mov	cx,DMASIZE	; Get size of DMA buffer in 1KB (/4KB)
	shr	cx,12-10	; Convert from 1KB to 4KB (# PTEs to swap)
@@:
	FIXICALL PGROUP:FXCHG_PTE,DTE_CS2 ; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE

	loop	@B		; Jump if more PTEs to swap
DMA_WIN3_EXIT:
	REGREST <fs,es,edi,esi,ecx,eax> ; Restore
	assume	es:nothing,fs:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DMA_WIN3 endp			; End DMA_WIN3 procedure
endif				; IF @OEM_WIN3
if @OEM_WIN3
	NPPROC	SQZOVR_WIN3 -- Squeeze High DOS Memory
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Squeeze high DOS memory

Mark all free (unused) MAC entries as spanning, and then merge all
adjacent spanning entries into one larger entry.  The VxD later comes
along and does not allocate as high DOS any memory covered by a
spanning entry.

The original state of the free or spanning entries is saved in the MAC
entry so it can be restored upon exit of Windows.  Note that this code
is dependent upon nobody messing with the values saved in the MAC
entry.

|

	pushad			; Save all EGP registers

	mov	ebp,esp 	; Address the stack

SQZOVR_STR	struc
SQZ_NONSPAN	dd	?	; Linear address of 1st non-spanning entry
SQZOVR_STR	ends		; End SQZOVR_STR structure

	sub	esp,(type SQZOVR_STR) ; Get space for local variables

	mov	[ebp-(type SQZOVR_STR)].SQZ_NONSPAN,0
				; Initialize ==> 1st non-spanning entry
	movzx	ebx,POVR_MAC	; Get segment of first MAC entry in high DOS
	mov	POVR_MAC_SQZ,bx ; Original POVR_MAC for Windows' exit

; Check the reference data structure for the # of 4 KB pages
; desired for virtual high DOS.
; For 386MAX 6.01, we either give 'em all we can, or nothing at all

	cmp	WIN3_REF_DATA.REF_VHD_SIZE,0
				; Do they want virtual high DOS support?
	jne	near ptr SQZOVR_WIN3_EXIT ; Jump if not

	cmp	bx,-1		; Izit valid?
	je	near ptr SQZOVR_WIN3_EXIT ; Jump if not

	FIXICALL JGROUP:FMAC_MERGE,DTE_CSJG ; Merge adjacent free MACs starting at POVR_MAC
	jc	near ptr SQZOVR_WIN3_ERRMAC ; Jump if something went wrong

	bts	OVR_FLAG,$OVR_SQZ ; Test and set squeeze state
	jc	near ptr SQZOVR_WIN3_EXIT ; Jump if already suqeezed

	shl	ebx,4-0 	; Convert from paras to bytes

COMMENT|

Trundle through high DOS looking for unused entries

Adjacent entries of the form (1st, 2nd) which can be squeezed include

(Any,  FREE) ==> (Any,	SPAN) Mark all free entries as spanning.

(SPAN, SPAN)	 Merge spanning entry into spanning entry

For each free and/or spanning entry, MAC_BACK is filled in with the
original MAC_NPAR value so we can restore it later.  Also, MAC_DRV is
filled in with the original type plus either @MAC_DRVSPAN or
@MAC_DRVFREE depending upon whether or not the original entry was
spanning or free, again so we can restore it later.

|

@MAC_SPANSPAN  equ (@MAC_SPAN shl 16) or (@MAC_SPAN and 0FFFFh)
@MAC_DRVSPAN equ 0		; Originally a spanning entry
@MAC_DRVFREE equ 1		; ...	       free ...

	mov	esi,11110000h	; Initialize last owner with pseudo-value
SQZOVR_WIN3_NEXT:
	cmp	AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit a valid MAC entry?
	je	short @F	; Jump if so

	cmp	AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a valid MAC entry?
	jne	near ptr SQZOVR_WIN3_ERRMAC ; Jump if not
@@:
	mov	si,AGROUP:[ebx].MAC_OWNR ; Get current owner
	movzx	eax,AGROUP:[ebx].MAC_NPAR ; Get # paras in MAC entry

; If this is a spanning entry, save its true length in MAC_BACK
; as we might modify it and then need to restore it later.
; Also, save a marker in MAC_DRV to indicate it's a spanning entry.

	cmp	si,@MAC_SPAN	; Izit a spanning entry?
	jne	short @F	; Jump if not

	mov	AGROUP:[ebx].MAC_BACK,ax ; Save to restore later

	mov	dl,AGROUP:[ebx].MAC_TYPE ; Get the original type
	add	dl,@MAC_DRVSPAN ; Plus marker as originally spanning entry
	mov	AGROUP:[ebx].MAC_DRV,dl ; Save to restore later
@@:

; If this is a free entry, save its true length in MAC_BACK
; as we might modify it and then need to restore it later.
; Also, save a marker in MAC_DRV to indicate it's a free entry.
; Mark it as a spanning entry so it can be merged into other
; spanning entries.

	cmp	si,@MAC_FREE	; Izit a free entry?
	je	short @F	; Jump if so

; If this isn't a free or spanning entry, and is the first such, remember
; its address.

	cmp	si,@MAC_SPAN	; Izit a spanning entry?
	je	short SQZOVR_WIN3_COM1 ; Rejoin common code if not

	cmp	[ebp-(type SQZOVR_STR)].SQZ_NONSPAN,0 ; Hit a live MAC yet?
	jne	short SQZOVR_WIN3_COM1 ; Rejoin common code if so

	mov	[ebp-(type SQZOVR_STR)].SQZ_NONSPAN,ebx ; Remember 1st live MAC

	jmp	short SQZOVR_WIN3_COM1 ; Rejoin common code

@@:
	mov	AGROUP:[ebx].MAC_BACK,ax ; Save to restore later

	mov	dl,AGROUP:[ebx].MAC_TYPE ; Get the original type
	add	dl,@MAC_DRVFREE ; Plus marker as originally free entry
	mov	AGROUP:[ebx].MAC_DRV,dl ; Save to restore later

	mov	AGROUP:[ebx].MAC_OWNR,@MAC_SPAN ; Mark as spanning entry
	mov	si,@MAC_SPAN	; ...
SQZOVR_WIN3_COM1:
	inc	ax		; Account for MAC entry

; Split cases

	cmp	esi,@MAC_SPANSPAN ; Izit (SPAN, SPAN)?
	je	short SQZOVR_WIN3_SPANSPAN ; Jump if so

	shl	esi,16		; Shift up to high-order word
	mov	ecx,ebx 	; Save address of previous MAC entry

	jmp	short SQZOVR_WIN3_LOOP ; Join common loop code


; Spanning entry at ECX, spanning entry at EBX
; Merge spanning entry into spanning entry

SQZOVR_WIN3_SPANSPAN:
	add	AGROUP:[ecx].MAC_NPAR,ax ; Add into previous entry

	mov	dl,AGROUP:[ebx].MAC_TYPE ; Get current type
	mov	AGROUP:[ecx].MAC_TYPE,dl ; Save as new type
SQZOVR_WIN3_LOOP:
	cmp	AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	je	short SQZOVR_WIN3_END ; Jump if so

	shl	eax,4-0 	; Convert from paras to bytes
	add	ebx,eax 	; Skip to next MAC entry

	jmp	SQZOVR_WIN3_NEXT ; Go around again

SQZOVR_WIN3_END:
	mov	bx,-1		; Assume all of high DOS was squeezed

	cmp	[ebp-(type SQZOVR_STR)].SQZ_NONSPAN,0 ; Hit a live MAC entry?
	je	short @F	; Skip if not

	mov	ebx,[ebp-(type SQZOVR_STR)].SQZ_NONSPAN ; ==> 1st live MAC
	shr	ebx,(4-0)	; Convert from linear address to segment
@@:

; Set POVR_MAC in high DOS memory for the INFO read

	REGSAVE <ds>		; Save

	mov	ax,DTE_DSHI	; Get data selector for high DOS memory
	mov	ds,ax		; Address it via DS
	assume	ds:PGROUP	; Tell the assembler

	mov	POVR_MAC,bx	; Update segment of first MAC entry in high DOS

	REGREST <ds>		; Restore
	assume	ds:PGROUP	; Tell the assembler

	xchg	bx,POVR_MAC	; Update segment of first MAC entry in high DOS
	mov	POVR_MAC_SQZ,bx ; Remember the old one for Windows' exit

SQZOVR_WIN3_EXIT:
SQZOVR_WIN3_ERRMAC:
	mov	esp,ebp 	; Strip local variables from the stack
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SQZOVR_WIN3 endp		; End SQZOVR_WIN3 procedure
endif				; IF @OEM_WIN3
if @OEM_WIN3
	FPPROC	CAPOVR_WIN3 -- Re-capture High DOS Memory
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Re-capture high DOS memory

|

	REGSAVE <eax,ebx,edx>	; Save registers

	movzx	ebx,POVR_MAC_SQZ ; Get segment of 1st MAC in high DOS
				; ... before SQZOVR_WIN3

	mov	POVR_MAC,bx	; Replace it in extended memory

; Set POVR_MAC in high DOS memory for the INFO read

	REGSAVE <ds>		; Save

	mov	ax,DTE_DSHI	; Get data selector for high DOS memory
	mov	ds,ax		; Address it via DS
	assume	ds:PGROUP	; Tell the assembler

	mov	POVR_MAC,bx	; Update it in high DOS memory

	REGREST <ds>		; Restore
	assume	ds:PGROUP	; Tell the assembler

	cmp	bx,-1		; Izit valid?
	je	near ptr CAPOVR_WIN3_EXIT ; Jump if not

	FIXICALL JGROUP:FMAC_MERGE,DTE_CSJG ; Merge adjacent free MACs starting at POVR_MAC
	jc	short CAPOVR_WIN3_ERRMAC ; Jump if something went wrong

	btr	OVR_FLAG,$OVR_SQZ ; Test and reset squeeze state
	jnc	short CAPOVR_WIN3_EXIT ; Jump if not squeezed

	shl	ebx,4-0 	; Convert from paras to bytes

COMMENT|

Trundle through high DOS looking for free and/or spanning entries and
convert them back to their original form based upon the values in
MAC_BACK and MAC_DRV.

|

CAPOVR_WIN3_NEXT:
	cmp	AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit a valid MAC entry?
	je	short @F	; Jump if so

	cmp	AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a valid MAC entry?
	jne	short CAPOVR_WIN3_ERRMAC ; Jump if not
@@:
	cmp	AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; Izit a free entry?
	je	short @F	 ; Jump if so

	cmp	AGROUP:[ebx].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	jne	short CAPOVR_WIN3_LOOP ; Jump if not
@@:
	mov	dx,AGROUP:[ebx].MAC_BACK ; Get original size in paras
	mov	AGROUP:[ebx].MAC_NPAR,dx ; Restore

	mov	dl,AGROUP:[ebx].MAC_DRV ; Get original type plus flag

	cmp	dl,@MAC_MID + @MAC_DRVSPAN ; Izit a middle spanning entry?
	je	short CAPOVR_WIN3_MIDSPAN ; Jump if so

	cmp	dl,@MAC_END + @MAC_DRVSPAN ; Izit an ending spanning entry?
	je	short CAPOVR_WIN3_ENDSPAN ; Jump if so

	cmp	dl,@MAC_MID + @MAC_DRVFREE ; Izit a middle free entry?
	je	short CAPOVR_WIN3_MIDFREE ; Jump if so

	cmp	dl,@MAC_END + @MAC_DRVFREE ; Izit an ending free entry?
	jne	short CAPOVR_WIN3_ERRMAC ; Jump if not
CAPOVR_WIN3_MIDFREE:
	mov	AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; Mark as free entry
	sub	dl,@MAC_DRVFREE ; Convert to type entry

	jmp	short CAPOVR_WIN3_TYPE ; Join common type save code

CAPOVR_WIN3_MIDSPAN:
CAPOVR_WIN3_ENDSPAN:
	mov	AGROUP:[ebx].MAC_OWNR,@MAC_SPAN ; Mark as spanning entry
	sub	dl,@MAC_DRVSPAN ; Convert to type entry
CAPOVR_WIN3_TYPE:
	mov	AGROUP:[ebx].MAC_TYPE,dl ; Save as new type
CAPOVR_WIN3_LOOP:
	cmp	AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	je	short CAPOVR_WIN3_EXIT ; Jump if so

	movzx	eax,AGROUP:[ebx].MAC_NPAR ; Get # paras in MAC entry
	inc	ax		; Account for MAC entry
	shl	eax,4-0 	; Convert from paras to bytes
	add	ebx,eax 	; Skip to next MAC entry

	jmp	short CAPOVR_WIN3_NEXT ; Go around again

CAPOVR_WIN3_ERRMAC:
CAPOVR_WIN3_EXIT:
	REGREST <edx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CAPOVR_WIN3 endp		; End CAPOVR_WIN3 procedure
endif				; IF @OEM_WIN3
if @OEM_WIN3
	FPPROC	JMM2_INITWIN3 -- EMM2 Initialize For Windows
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 23, AH = 17h

Initialize for Windows

On entry:

Caller:
AL	=	0 if start of the way up through 1605 chain
	=	1 if end ...
ES:BX	==	 0:0
DS:SI	==	 0:0
DI	=	version # (major,minor)
CX	=	0
DX	=	flags
		 Bit 0 = 1 if Windows 286 DOS extender (standard mode)
		       = 0 if ...     386	       (enhanced mode)
SS:EBP	==>	INTXX_STR

On exit:

CX	=	0 if all went well
DS:SI	==>	our callback routine
ES:BX	==>	our startup structure

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	cmp	al,0		; Izit the start of the ending?
	je	short EMM2_INIT_WIN3_START ; Jump if so

	call	INACTIVATE_HOOK13 ; Inactivate HOOK13 byte if active

; Save caller's ES:BX in our reference data structure

	mov	eax,[ebp].INTXX_ES.EDD-2 ; Get caller's ES into high-order of EAX
	mov	ax,[ebp].INTXX_EBX.ELO ; Get caller's BX into low-order ..
	mov	WIN3_REF_DATA.REF_STARTUP,eax ; Save in VxD struc

	jmp	EMM2_INITWIN3_EXIT ; Join common exit code


EMM2_INIT_WIN3_START:

; Check CX from any previous handler

	cmp	[ebp].INTXX_ECX.ELO,0 ; Izit failing already?
	jnz	near ptr EMM2_INITWIN3_EXIT ; Jump if so

; Since we use the DS:SI callback convention and only one such
; callback can exist for WIN3, we must ensure that no previous
; handler is using it

	mov	ax,[ebp].INTXX_DS ; Get the segment part
	or	ax,[ebp].INTXX_ESI.ELO ; Include the offset part
	jnz	near ptr EMM2_INITWIN3_ERR ; Jump if previous callback

; Fill in return values

	mov	eax,PWIN3_CB	; EAX ==> our callback routine
	mov	[ebp].INTXX_ESI.ELO,ax ; Return as caller's DS:SI
	shr	eax,16		; Shift down high-order word
	mov	[ebp].INTXX_DS,ax ; Return as caller's DS:SI

	mov	ebx,[ebp].INTXX_ES.EDD-2 ; Get caller's ES into high-order of EBX
	mov	bx,[ebp].INTXX_EBX.ELO ; Get caller's BX

; EBX has the caller's ES:BX

	mov	eax,PWIN3_STARTUP ; EAX ==> our startup structure
	mov	[ebp].INTXX_EBX.ELO,ax ; Return as caller's ES:BX
	shr	eax,16		; Shift down high-order word
	mov	[ebp].INTXX_ES,ax ; Return as caller's ES:BX

; Save the Windows/386 version # in extended memory

	mov	ax,[ebp].INTXX_EDI.ELO ; Get major/minor version #
	mov	WIN3_VERSION,ax ; Save major/minor version #

; Set flag for Windows 3 initialization in extended, high, and low DOS memory

	mov	LOWWIN3_CB,1	; Mark as Windows 3 initialization

	push	DTE_DSLO	; Get data selector for low DOS memory
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	mov	LOWWIN3_CB,1	; Mark as Windows 3 initialization
	mov	WIN3_STARTUP.SIS_NEXT_DEV_PTR,ebx ; Save any previous address

	test	GLB_FLAG,@GLB_I67 ; Are we providing INT 67h services?
	jnz	short @F	; Yes, skip alterations

	push	DTE_D4GB	; Get our all memory selector
	pop	gs		; Address it
	assume	gs:INTVEC	; Tell the assembler about it

	mov	eax,es:NEW_DUM67_VEC ; Get new interrupt vector
	xchg	eax,INT00_VEC[67h*(type INT00_VEC)]
	mov	es:OLD_DUM67_VEC,eax ; Save for replacement later

	mov	DEVDRV.DD_NAME[0],'E' ; Mark as EMS manager installed

	assume	gs:nothing	; Tell the assembler
@@:
	push	DTE_DSHI	; Get data selector for high DOS memory
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	mov	LOWWIN3_CB,1	; Mark as Windows 3 initialization
	mov	WIN3_STARTUP.SIS_NEXT_DEV_PTR,ebx ; Save any previous address

; Save the Windows/386 version # in high DOS memory

	mov	ax,[ebp].INTXX_EDI.ELO ; Get major/minor version #
	mov	WIN3_VERSION,ax ; Save major/minor version #

if @OEM_HIFILL

; Save current state and close off high DOS memory

	mov	al,HDM_FLAG	; Get current state of high DOS
	mov	es:OLDHDM,al	; Save to restore later

	push	DTE_D4GB	; Get our all memory selector
	pop	gs		; Address it
	assume	gs:AGROUP	; Tell the assembler about it
endif				; IF @OEM_HIFILL

	push	DTE_DS		; Get our data selector
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

if @OEM_HIFILL
	FIXICALL PGROUP:FCLOSEHIGHDOS,DTE_CS2 ; Save current state and close it off
endif				; IF @OEM_HIFILL

if @OEM_WIN3
; Save DOS stacks globals used by SuperVM in the reference data structure

	mov	eax,LaDSTK_TAB	; Linear address of DSTK_TAB_STR
	mov	WIN3_REF_DATA.REF_LaDSTK_TAB,eax ; Save for the VxD

	mov	ax,DSTK_CNT	; Total # of DOS stacks we supply
	mov	WIN3_REF_DATA.REF_DSTK_CNT,ax ; Save for the VxD

	mov	eax,PDSTKCOM	; Segment:offset of common return routine
	mov	WIN3_REF_DATA.REF_PDSTKCOM,eax ; Save for the VxD
endif				; IF @OEM_WIN3

	jmp	short EMM2_INITWIN3_EXIT ; Join common exit code

	assume	gs:nothing	; Tell the assembler about it

EMM2_INITWIN3_ERR:
	mov	[ebp].INTXX_ECX.ELO,1 ; Mark as in error
EMM2_INITWIN3_EXIT:
	and	GLB_FLAG,not @GLB_P67 ; Mark as not a PORT67 function
				; so we'll return to real mode as appropriate

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_INITWIN3 endp		; End JMM2_INITWIN3 procedure
endif				; IF @OEM_WIN3
if @OEM_SYS eq @OEMSYS_RET
	FPPROC	JMM2_PSMEM -- EMM2 Periscope Memory Functions
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 24, AH = 18h

Periscope memory functions

On entry:

Caller:
AL	=	0 if requesting information
	=	1 if mapping LPN in BX to PPN in CL
	=	2 if marking all PSMEM pages as read-only
	=	3 ...				 read-write
SS:EBP	==>	INTXX_STR

On exit:

AH	=	0  if all went well
	=	8A if BX >= # 4KB pages allocated to Periscope memory
	=	8B if CL >= PSMWIN/4
	=	8F if AL > 3
	=	80 if software inconsistency

All registers except EBP, SS, and ESP may be destroyed.

|

	cmp	PSMWIN,0	; Izit specified?
	je	near ptr JMM_E8A ; Jump if not

	mov	al,[ebp].INTXX_EAX.ELO.LO ; Get the minor function #

	cmp	al,0		; Izit get information?
	je	short EMM2_PSMEM_INFO ; Jump if so

	cmp	al,1		; Izit map LPN to PPN?
	je	short EMM2_PSMEM_MAP ; Jump if so

	cmp	al,2		; Izit mark pages as read-only?
	je	near ptr EMM2_PSMEM_ROM ; Jump if so

	cmp	al,3		; Izit mark pages as read-write?
	je	near ptr EMM2_PSMEM_RAM ; Jump if so

	jmp	JMM_E8F 	; Jump if invalid minor function

COMMENT|

Get information

BX	=	starting segment in paras
CX	=	# 4KB pages allocated
DX	=	# 4KB pages in window

|

EMM2_PSMEM_INFO:
	mov	ax,PSMSEG	; Get starting segment in paras
	mov	[ebp].INTXX_EBX.ELO,ax ; Return in caller's BX

	mov	ax,PSMSIZE	; Get size of memory in 1KB (/4KB)
	shr	ax,12-10	; Convert from 1KB to 4KB
	mov	[ebp].INTXX_ECX.ELO,ax ; Return in caller's CX

	mov	ax,PSMWIN	; Get size of window in 1KB (/4KB)
	shr	ax,12-10	; Convert from 1KB to 4KB
	mov	[ebp].INTXX_EDX.ELO,ax ; Return in caller's DX

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code


COMMENT|

Map LPN in BX to PPN in CL

|

EMM2_PSMEM_MAP:
	movzx	eax,PSMSIZE	; Get size of memory in 1KB (/4KB)
	shr	eax,12-10	; Convert from 1KB to 4KB
	movzx	esi,[ebp].INTXX_EBX.ELO ; Get LPN
	movzx	bx,[ebp].INTXX_ECX.ELO.LO ; Get PPN

	cmp	esi,eax 	; Izit too big?
	jae	near ptr JMM_E8A ; Jump if so

	mov	ax,PSMWIN	; Get size of window in 1KB (/4KB)
	shr	ax,12-10	; Convert from 1KB to 4KB

	cmp	bx,ax		; Izit too big?
	jae	near ptr JMM_E8B ; Jump if so

	shl	esi,12-(12-2)	; Convert from 4KB to 4KB in dwords
	add	esi,PPDTPSM	; Plus offset within PDT of base memory
				; FS:ESI ==> source PTE

	shl	bx,12-(12-2)	; Convert from 4KB to 4KB in dwords
	mov	ax,PSMSEG	; Get PSM starting segment (/4KB)
	shr	ax,(12-2)-4	; Convert from paras to 4KB in dwords
	add	bx,ax		; Add to get offset in PDT of PPN
				; FS:BX ==> destin PTE

	push	DTE_PDT 	; Get our PDT selector
	pop	fs		; Address it
	assume	fs:PDTGRP	; Tell the assembler about it

	mov	eax,OFFPDT[esi] ; Get source PTE
	or	ax,@PTE_URP	; Mark as User/Read-write/Present
	mov	OFFPDT[bx],eax	; Save as destin PTE

; Because we just changed the page table,
; we must mark it as needing to be flushed

	or	GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	fs:nothing	; Tell the assembler about it


COMMENT|

Mark pages as read-only

|

EMM2_PSMEM_ROM:
	push	DTE_PDT 	; Get our PDT selector
	pop	fs		; Address it
	assume	fs:PDTGRP	; Tell the assembler about it

	mov	bx,PSMSEG	; Get PSM starting segment (/4KB)
	shr	bx,(12-2)-4	; Convert from paras to 4KB in dwords

	mov	cx,PSMWIN	; Get size of PSM window in 1KB (/4KB)
	shr	cx,12-10	; Convert from 1KB to 4KB
@@:
	and	OFFPDT[bx],not (mask $PTE_RW) ; Mark as ROM
	add	bx,size OFFPDT	; Skip to next PTE

	loop	@B		; Jump if more PTEs to mark

; Because we just changed the page table,
; we must mark it as needing to be flushed

	or	GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	fs:nothing	; Tell the assembler about it


COMMENT|

Mark pages as read-write

|

EMM2_PSMEM_RAM:
	push	DTE_PDT 	; Get our PDT selector
	pop	fs		; Address it
	assume	fs:PDTGRP	; Tell the assembler about it

	mov	bx,PSMSEG	; Get PSM starting segment (/4KB)
	shr	bx,(12-2)-4	; Convert from paras to 4KB in dwords

	mov	cx,PSMWIN	; Get size of PSM window in 1KB (/4KB)
	shr	cx,12-10	; Convert from 1KB to 4KB
@@:
	or	OFFPDT[bx],mask $PTE_RW ; Mark as RAM
	add	bx,size OFFPDT	; Skip to next PTE

	loop	@B		; Jump if more PTEs to mark

; Because we just changed the page table,
; we must mark it as needing to be flushed

	or	GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	fs:nothing	; Tell the assembler about it

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_PSMEM endp 		; End JMM2_PSMEM procedure
endif				; IF @OEM_SYS eq @OEMSYS_RET
	FPPROC	JMM2_PHYS2LIN -- EMM2 Translate Physical to Linear
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 25, AH = 19h

Translate physical address to linear address

On entry:

EDX	=	physical address

On exit:

AH	=	00h if successful
	=	8Bh if not
EDX	=	linear address modulo 4K

All registers except EBP, SS, and ESP may be destroyed.

|

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap

	mov	ebx,[ebp].INTXX_EDX ; Get input physical address

	call	PHYS2LIN	; Translate EBX physical to linear
	jc	near ptr JMM_E8B ; Join common error code if not found

	mov	[ebp].INTXX_EDX,ebx ; Set return value to linear address

; Note that @GLB_XWRP is cleared and WRAP_ENABLE is called at EMM_EXIT

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_PHYS2LIN endp		; End JMM2_PHYS2LIN procedure
	FPPROC	JMM2_SETPTE -- EMM2 Set single PTE
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 26, AH = 1Ah

Set Single PTE

On entry:

EDX	=	New PTE contents
ESI	=	Linear address

On exit:

AH	=	00h if successful
	=	8Bh if not

All registers except EBP, SS, and ESP may be destroyed.

|

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap

	mov	eax,[ebp].INTXX_EDX ; Get input new PTE
	mov	edx,[ebp].INTXX_ESI ; Get input linear address
	shr	edx,(12-2)	; Convert bytes to pages in Dwords

	push	DTE_PDT 	; Get our PDT selector
	pop	fs		; Address it
	assume	fs:PDTGRP	; Tell the assembler about it

; FS:0 = linear address of 2nd level PTEs

	mov	ecx,TOTSIZE	; Get total size of extended memory
	add	cx,1024 	; Account for the 1st MB

; N.B. The two actions cancel each other out
;	 shr	 ecx,(2-0)	; Convert size in 1 KB to size in 4 KB (# PTEs)
;	 shl	 ecx,(2-0)	; Convert to account for dword entries

; N.B. This comparison will not allow modification to the shadow RAM PTEs.
; This would be a nice enhancement.
	cmp	edx,ecx 	; Is PTE in range?
	jae	short EMM2_SETPTE_ERR ; No

; Set specific PTE
	mov	OFFPDT[edx],eax ; Set PTE

; Because we just changed the page table,
; we must mark it as needing to be flushed

	or	GLB_FLAG,@GLB_TLB ; Mark as needing TLB flush

; Note that @GLB_XWRP is cleared and WRAP_ENABLE is called at EMM_EXIT

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

EMM2_SETPTE_ERR:
	jmp	JMM_E8B 	; Join common error code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_SETPTE endp		; End JMM2_SETPTE procedure
if @OEM_FLEXROM
	FPPROC	JMM2_FLEXINFO -- EMM2 Get FlexROM information
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 27, AH = 1Bh

Get FlexROM Information.

On exit:

EDX	=	Physical address of FlexROM table (for VxD)
CX	=	# of entries in FlexROM table
BX	=	FLEXROM_FLAG
AH	=	00h indicating success

All registers except EBP, SS, and ESP may be destroyed.

|

	push	DTE_DS		; Pass our data selector
	FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	add	eax,offset PGROUP:FLEXROM_TBL ; Plus offset to linear address
	call	LIN2PHYS	; Translate linear EAX to physical EAX

	mov	[ebp].INTXX_EDX,eax ; Return physical address in EDX

	mov	ax,FLEXROM_LEN	; Get number of bytes in FlexROM table
	mov	cl,@FLEXROM_STRLEN ; Get number of bytes per entry
	div	cl		; Get number of entries (AX/CL ==> AL Rem AH)
	sub	ah,ah		; Convert byte to word
	mov	[ebp].INTXX_ECX.ELO,ax ; Return entry count in CX

	mov	ax,FLEXROM_FLAG ; Get the flags
	mov	[ebp].INTXX_EBX.ELO,ax ; Return in caller's BX

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_FLEXINFO endp		; End JMM2_FLEXINFO procedure
endif				; If @OEM_FLEXROM
	FPPROC	JMM2_GETOLDINT -- EMM2 Get old interrupt vector
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 28, AH = 1Ch

Get interrupt vector prior to MAX's installation

On entry:

AL	=	Interrupt number

On exit:

EDX	=	Segment:Offset of interrupt (prior to MAX's installation)
AH	=	00h indicates success

All registers except EBP, SS, and ESP may be destroyed.

|

	movzx	eax,[ebp].INTXX_EAX.LO ; Get the interrupt number

	mov	eax,OLDINT_VECS[eax*4] ; Get vector from table

	mov	[ebp].INTXX_EDX,eax ; Set return value

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GETOLDINT endp		; End JMM2_GETOLDINT procedure
	FPPROC	JMM2_DISPSTR -- EMM2 Display String Through INT 10h
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 29, AH = 1Dh

Display string through INT 10h

On entry:

SI	=	offset in PGROUP (extended memory) of message to display
		 with leading byte length

All registers except EBP, SS, and ESP may be destroyed.

|

	mov	dx,-1		; Use current position
	mov	si,[ebp].INTXX_ESI.ELO ; ES:SI ==> message to display
	FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_DISPSTR endp		; End JMM2_DISPSTR procedure
	FPPROC	JMM2_EXTADDR -- EMM2 Get Extended Memory Addresses Into ES:DI
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 30, AH = 1Eh

Get extended memory address into ES:DI

On entry:

AL	=	1 if debugging data requested,
		 0 if not
ES:DI	==>	EXTADDR_STR structure in caller's data space

On exit:

AH	=	0
CX	=	length of result (# structure entries filled in)

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	sti			; Allow interrupts

; Get 20-bit linear address offset of caller's ES:DI into AGROUP:EDI

	FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	assume	es:AGROUP	; Tell the assembler about it

; Save secondary size of EXT/XMS memory if not already set

	test	XMS_FLAG,mask $XMS_I15 ; Izit installed?
	jnz	short @F	; Jump if so (EX2SIZE is valid)

	mov	ah,88h		; Function code to get size of extended memory
	int	15h		; Request BIOS service
	movzx	eax,ax		; Zero to use as dword

	mov	EX2SIZE,eax	; Save for later use
@@:
	xor	ecx,ecx 	; Initialize bottom up extended memory size

; If we've installed our XMS services, don't check for VDISK signature
; as we might get false positive if someone (well, it's DOS 5) copies
; data into the HMA which looks like a bottom up VDISK allocation

	test	XMS_FLAG,mask $XMS_I15 ; Izit installed?
	jnz	short EMM2_EXTADDR_NOEXTUP ; Jump if so

; Process bottom up extended memory if present

	mov	esi,LaCVD	; Get linear address of pseudo-1MB PTE

	cmp	AGROUP:[esi].VDISK_VEND.EDD,'SIDV' ; Check for signature
	jne	short EMM2_EXTADDR_NOEXTUP ; Jump if no signature

	cmp	AGROUP:[esi+4].VDISK_VEND,'K' ; Check for signature
	jne	short EMM2_EXTADDR_NOEXTUP ; Jump if no signature

	movzx	eax,AGROUP:[esi].VDISK_NEXT ; Get its size in 1KB
	sub	eax,1024	; Less 1MB
	mov	bl,@EXTADDRTYPE_EXTUP ; Get the type

	jmp	short EMM2_EXTADDR_HMACOM ; Join common code

EMM2_EXTADDR_NOEXTUP:

; Process HMA if present

	mov	eax,HMASIZE	; Get size of HMA (0 or 64KB)

	and	eax,eax 	; Izit present?
	jz	short EMM2_EXTADDR_NOHMA ; Jump if not

	cmp	EX2SIZE,64	; Is there enough room?
	jb	short EMM2_EXTADDR_NOHMA ; Jump if not

	mov	bl,@EXTADDRTYPE_HMA ; Get the type
EMM2_EXTADDR_HMACOM:
	mov	ecx,eax 	; Save as bottom up extended memory size
	mov	AGROUP:[edi].EXTADDR_ADDR,00100000h ; Save as starting address
	shl	eax,10-0	; Convert from 1KB to bytes
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,bl ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear the flags
	add	edi,size EXTADDR_STR ; Skip to next entry
EMM2_EXTADDR_NOHMA:

; Process EXT= middle memory between bottom up and top down allocations
; which has not as yet been returned to the XMS memory pool.
; This memory is placed into the pool when XMS services are turned on.

	test	XMS_FLAG,mask $XMS_I15 ; Izit installed?
	jnz	short EMM2_EXTADDR_NOEXTMID ; Jump if so (memory in pool)

; The length in 1KB is EX2SIZE - EXTUP

	mov	eax,EX2SIZE	; Get secondary size of EXT/XMS memory
	sub	eax,ecx 	; Less bottom up extended memory size
	jbe	short EMM2_EXTADDR_NOEXTMID ; Jump if it's empty

	shl	eax,10-0	; Convert from 1KB to bytes
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length

; The starting address is at 1MB + 1KB * EXTUP

	mov	eax,ecx 	; Copy bottom up extended memory size
	shl	eax,10-0	; Convert from 1KB to bytes
	add	eax,CON1MB	; Plus base address of 1MB
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_EXTMD ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear the flags
	add	edi,size EXTADDR_STR ; Skip to next entry
EMM2_EXTADDR_NOEXTMID:

; Process top down extended memory

	mov	eax,EXTSIZE	; Get original size of EXT/XMS memory
	mov	ebx,EX2SIZE	; Get secondary ...

	sub	eax,ebx 	; Less secondary size to get length
	jz	short EMM2_EXTADDR_NOEXTDN ; Jump if no top down allocations

	shl	eax,10-0	; Convert from 1KB to bytes
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length

	shl	ebx,10-0	; Convert from 1KB to bytes
	add	ebx,CON1MB	; Plus base address of 1MB
	mov	AGROUP:[edi].EXTADDR_ADDR,ebx ; Save as starting address

;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_EXTDN ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear the flags
	add	edi,size EXTADDR_STR ; Skip to next entry
EMM2_EXTADDR_NOEXTDN:

; Process allocated XMS memory

	mov	edx,PXMSHNDL	; Get offset of XMSHNDL table
	mov	cx,XMSNHNDL	; Get total # XMS handles
	dec	cx		; Less the free chain
	mov	ebx,1		; Initialize handle #
				; skipping over the free chain
EMM2_EXTADDR_NEXTXMS:
	cmp	PGROUP:[edx+ebx].LO,@H_INUSE ; Izit in use?
	jne	short EMM2_EXTADDR_LOOPXMS ; Jump if not

	mov	eax,PXMSBASE	; Get offset of XMSBASE table
	mov	eax,PGROUP:[eax+ebx*4] ; Get next base address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	eax,PXMSSIZE	; Get offset of XMSSIZE table
	mov	eax,PGROUP:[eax+ebx*4] ; Get next length in bytes
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length

	mov	AGROUP:[edi].EXTADDR_HNDL,bx ; Save as handle #

	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_XMS ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Mark as valid
	add	edi,size EXTADDR_STR ; Skip to next entry
EMM2_EXTADDR_LOOPXMS:
	inc	ebx		; Skip to next XMS handle value

	loop	EMM2_EXTADDR_NEXTXMS ; Jump if more XMS handles
EMM2_EXTADDR_NOXMS:

; Process allocated EMS memory
; Loop through the EMS handles

	cmp	EMMSIZE,0	; Any EMS memory available?
	je	near ptr EMM2_EXTADDR_NOEMS ; Jump if not

	mov	edx,1		; Start with this handle #
EMM2_EXTADDR_NEXTEMS:
	FIXICALL PGROUP:FVALID_HNDL,DTE_CS2 ; Ensure it's a valid handle
	jnc	near ptr EMM2_EXTADDR_LOOPEMS ; Jump if not in use

; Skip over SCREEN handle

	test	CM2_FLAG,@CM2_SCR ; Izit specified?
	jz	short @F	; Jump if not

	cmp	dl,@SCR_HNDL	; Izit the SCREEN handle?
	je	near ptr EMM2_EXTADDR_LOOPEMS ; Jump if so
@@:
	mov	cl,@EXTADDRFLAG_HNDL ; Mark as valid

; Set has-name bit if the name is non-blank

	mov	ebx,edx 	; Copy to index HNDLNAME
	shl	ebx,3-0 	; Convert from two dwords to bytes
	add	ebx,PHNDLNAME	; DS:EBX ==> this handle's name

	cmp	PGROUP:[ebx].EDQLO,'    ' ; Check low-order dword of handle name
	jne	short EMM2_EXTADDR_EMSNAME ; Jump if non-blank

	cmp	PGROUP:[ebx].EDQHI,'    ' ; Check high-...
	je	short @F	; Jump if all blank
EMM2_EXTADDR_EMSNAME:
	or	cl,@EXTADDRFLAG_NAME ; Mark as valid
@@:

; Check for zero-length EMS handle

	mov	ebx,edx 	; Copy handle
	shl	ebx,1		; Times two to index table of words
	add	ebx,PHNDLCNT	; Plus pointer to handle-count table

	cmp	PGROUP:[ebx].ELO,0 ; Izit zero-length?
	jne	short EMM2_EXTADDR_XZERO ; Jump if not

	mov	AGROUP:[edi].EXTADDR_ADDR,-1 ; Save as starting address
	mov	AGROUP:[edi].EXTADDR_LEN,0 ; Save as length
	mov	AGROUP:[edi].EXTADDR_HNDL,dx ; Save as handle #
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_EMS ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,cl ; Save as flags
	add	edi,size EXTADDR_STR ; Skip to next entry

	jmp	short EMM2_EXTADDR_LOOPEMS ; Join common code

EMM2_EXTADDR_XZERO:
	xor	esi,esi 	; Initialize last ending address

; Loop through the LPNs allocated to this handle
; CL	 =	 EXTADDR_FLAG value
; ESI	 =	 last ending address

	movzx	ebx,dx		; Copy handle #
	shl	ebx,2		; Times four to index table of dwords
	add	ebx,PHNDLPAGE	; EBX ==> HNDLPAGE[ebx] ==> PAGELINK[??]
EMM2_EXTADDR_NEXTLPN:
	mov	ebx,PGROUP:[ebx].PL_NEXT ; EBX = next link

	cmp	ebx,HP_LAST	; Check for last entry
	je	short EMM2_EXTADDR_LOOPEMS ; Jump if no more LPNs

	push	ebx		; Save next link

	sub	ebx,PPAGELINK	; Convert to RPN
	mov	eax,ebx 	; Save for a moment
;;;;;;; shl	ebx,2-2 	; Convert from dword to dword index
	add	ebx,PLINKBASE	; Plus base of PDT PTEs
	shl	eax,4-2 	; Convert from dword to four-dword index
	add	eax,PGROUP:[ebx] ; Plus the corresponding offset

; EAX = offset of PTEs in PDT for this 16KB page

	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes

; If this starting address is the same as the last ending address,
; the two LPNs are linearly adjacent.  Add in 16KB to the previous
; entry rather than creating a new entry.

	cmp	eax,esi 	; Same address?
	jne	short @F	; Jump if not

	mov	eax,CON16KB	; Get length
	add	AGROUP:[edi-(type EXTADDR_STR)].EXTADDR_LEN,eax ; Add to prev entry

	jmp	short EMM2_EXTADDR_COMEMS ; Join common code

@@:
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	mov	esi,eax 	; Save new starting address
	mov	eax,CON16KB	; Get length
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
	mov	AGROUP:[edi].EXTADDR_HNDL,dx ; Save as handle #
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_EMS ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,cl ; Save as flags
	add	edi,size EXTADDR_STR ; Skip to next entry
EMM2_EXTADDR_COMEMS:
	add	esi,eax 	; Plus its length to get ending address

	pop	ebx		; Restore next link

	jmp	short EMM2_EXTADDR_NEXTLPN ; Go around again

EMM2_EXTADDR_LOOPEMS:
	inc	dx		; Skip to next handle #

	cmp	dx,@MAX_EHNDLCNT ; Check against maximum EMS handle #
	jb	near ptr EMM2_EXTADDR_NEXTEMS ; Jump if still within range
EMM2_EXTADDR_NOEMS:

if @OEM_DPMI

	test	CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	jnz	near ptr EMM2_EXTADDR_NODPMI1 ; Jump if so

; Process allocated DPMI memory

; Loop through the active DPMI clients
; Note that we don't distinguish between different DPMI clients.
; That is, we may have two or more handle #0 entries, one for each
; DPMI client.

	mov	edx,PVMTSS	; Get offset in PGROUP of the 1st TSS
	xor	cx,cx		; Initialize DPMI save area handle #
EMM2_EXTADDR_NEXTHNDL:

; Process DPMI old PM save areas, LDTs, memory handle tables,
; and dynamic save areas.

; Process DPMI old PM save areas

	mov	eax,PGROUP:[edx].DPTSS_OLDPM ; Get address

	and	eax,eax 	; Izit valid?
	jz	short @F	; Jump if not

	cmp	eax,TOPBASE	; Izit out of bounds?
	jae	short @F	; Jump if so

	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	eax,DPMIOLDPM_SIZ ; Get the size of the region
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
	mov	AGROUP:[edi].EXTADDR_HNDL,cx ; Save as handle #
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_DPOPM ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Mark as valid
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:

; Note that the first TSS has neither a dynamic save area nor
; a separately allocated LDT or memory handle table
; nor an LPM stack

	cmp	edx,PVMTSS	; Izit the 1st TSS?
	je	near ptr EMM2_EXTADDR_NEXTHNDL1 ; Jump if so

; Process dynamic save area

	mov	eax,PGROUP:[edx].DPTSS_DYN ; Get address

	cmp	eax,TOPBASE	; Izit out of bounds?
	jae	short @F	; Jump if so

	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	eax,DPMIDYN_SIZ ; Get the size of the region
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
	mov	AGROUP:[edi].EXTADDR_HNDL,cx ; Save as handle #
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_DPDYN ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Mark as valid
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:

; Process separately allocated LDTs

	mov	eax,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT

	cmp	eax,TOPBASE	; Izit out of bounds?
	jae	short @F	; Jump if so

	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	eax,PGROUP:[edx].DPTSS_LDT_SIZ ; Get byte size of DPMI LDT (/8)
	FIXICALL IGROUP:FDPMIFN_XLDT_SIZ,DTE_CSIG ; Return with EBX = byte size of extended LDT
				; using LDT_SIZ of EAX

	mov	AGROUP:[edi].EXTADDR_LEN,ebx ; Save as length
	mov	AGROUP:[edi].EXTADDR_HNDL,cx ; Save as handle # (LDT #)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_LDT ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Mark as valid
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:

; Process separately allocated memory handle tables

	mov	eax,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EAX ==> DPMI memory
				; handle table

	cmp	eax,TOPBASE	; Izit out of bounds?
	jae	short @F	; Jump if so

	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get # handles
	imul	eax,type DPMIHNDL_STR ; Times # bytes per handle
	add	eax,@DPMI_BOUND-1 ; Round up to next
	and	eax,not (@DPMI_BOUND-1) ; ... boundary for ALLOCMEM

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
	mov	AGROUP:[edi].EXTADDR_HNDL,cx ; Save as handle #
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_DHNDL ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Mark as valid
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:

; Process LPM stack in two parts:  unused and used

	mov	eax,PGROUP:[edx].DPTSS_LPMBASE ; Get starting address

	cmp	eax,TOPBASE	; Izit out of bounds?
	jae	near ptr EMM2_EXTADDR_NEXTHNDL1 ; Jump if so

	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

; Calculate the size of the unused portion of the LPM stack

	REGSAVE <ecx,edi>	; Save for a moment

	mov	ecx,LPMSTK_SIZ	; Get size in bytes of PL3 fault stack
	shr	ecx,2-0 	; Convert from bytes to dwords

	mov	edi,eax 	; AGROUP:EDI ==> LPM stack
	mov	eax,@LPMSTKFILL ; Get filler pattern
   repe scas	AGROUP:[edi].EDD ; Look for it
	je	short @F	; Jump if all match

	sub	edi,4		; Back off to last mismatch
	inc	ecx		; Count it back in
@@:
	shl	ecx,2-0 	; Convert from dwords to bytes
	mov	ebx,ecx 	; Copy for later use
	mov	eax,edi 	; Copy linear address
	sub	eax,PGROUP:[edx].DPTSS_LPMBASE ; Subtract to get length in bytes

	REGREST <edi,ecx>	; Restore

	cmp	eax,0		; Is there any unused LPM stack present?
	je	short @F	; Jump if not

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
	mov	AGROUP:[edi].EXTADDR_HNDL,cx ; Save as handle #
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_LPMLO ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Mark as valid
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:
	cmp	ebx,0		; Is there any used LPM stack present?
	je	short @F	; Jump if not

	add	eax,PGROUP:[edx].DPTSS_LPMBASE ; Add starting address to
				; get to used part
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	AGROUP:[edi].EXTADDR_LEN,ebx ; Save as length
	mov	AGROUP:[edi].EXTADDR_HNDL,cx ; Save as handle #
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_LPMHI ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Mark as valid
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:
EMM2_EXTADDR_NEXTHNDL1:
	mov	esi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:ESI ==> DPMI memory
				; handle table
	cmp	esi,TOPBASE	; Izit out of bounds?
	jae	short EMM2_EXTADDR_LOOPDPMI1 ; Jump if so

	push	ecx		; Save the handle #

	mov	ecx,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get total # handles
EMM2_EXTADDR_NEXTDPMI:
	cmp	AGROUP:[esi].DPMIHNDL_LEN,0 ; Izit allocated?
	je	short EMM2_EXTADDR_LOOPDPMI ; Jump if not

	mov	eax,AGROUP:[esi].DPMIHNDL_LA ; Get starting address

	cmp	eax,TOPBASE	; Izit out of bounds?
	jae	short EMM2_EXTADDR_LOOPDPMI ; Jump if so

	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	eax,AGROUP:[esi].DPMIHNDL_LEN ; Get length
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length

	mov	eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get total # handles
	sub	eax,ecx 	; Less countdown value to get handle #
				; in origin-0, unit increments
	mov	AGROUP:[edi].EXTADDR_HNDL,ax ; Save as handle #
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_DPMI ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Mark as valid
	add	edi,size EXTADDR_STR ; Skip to next entry
EMM2_EXTADDR_LOOPDPMI:
	add	esi,type DPMIHNDL_STR ; Skip to next entry

	loopd	EMM2_EXTADDR_NEXTDPMI ; Jump if more DPMI handles to check

	pop	ecx		; Restore handle #
EMM2_EXTADDR_LOOPDPMI1:
	add	edx,type DPTSS_STR ; Skip to next TSS
	inc	cx		; Skip to next handle #

	cmp	cx,@TSS_MAX	; Izit the last TSS?
	je	short @F	; Jump if so

	cmp	PGROUP:[edx].TSS_LINK,-1 ; Izit available?
	jne	near ptr EMM2_EXTADDR_NEXTHNDL ; Jump if not

	jmp	short EMM2_EXTADDR_LOOPDPMI1 ; Go around again

@@:
EMM2_EXTADDR_NODPMI1:
endif				; IF @OEM_DPMI

; Process unallocated memory by allocating it until there's no more

	mov	esi,edi 	; Remember starting address
EMM2_EXTADDR_NEXTAVL:
	push	@ALLOC_XMS	; Pass allocation type
	FIXICALL PGROUP:FQRY_PGCNT,DTE_CS2 ; Return with EAX = # available 1KB
				; ...	      EDX = size of largest

	shl	edx,10-0	; Convert from 1KB to bytes
	jz	short EMM2_EXTADDR_NOAVL ; Jump if nothing remains

	push	@ALLOC_XMS	; Tell 'em what kind of memory we're allocating
	push	edx		; Pass # bytes to allocate
	FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
	assume	fs:nothing	; Tell the assembler about it
	jc	short EMM2_EXTADDR_NOAVL ; Jump if something went wrong
				; Return with EBX = linear address of memory
	mov	AGROUP:[edi].EXTADDR_ADDR,ebx ; Save as starting address
	mov	AGROUP:[edi].EXTADDR_LEN,edx ; Save as length

;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_AVL ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear the flags
	add	edi,size EXTADDR_STR ; Skip to next entry

	jmp	short EMM2_EXTADDR_NEXTAVL ; Go around again

; No more memory available:  give it all back

EMM2_EXTADDR_NOAVL:
	cmp	esi,edi 	; Are we done freeing the memory?
	je	short EMM2_EXTADDR_NOFREE ; Jump if so

; Deallocate ECX bytes at EDI

	push	AGROUP:[esi].EXTADDR_LEN ; Pass byte length
	push	AGROUP:[esi].EXTADDR_ADDR ; Pass starting linear address
	FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
;;;;;;; jc	short ???	; Ignore error return

	add	esi,size EXTADDR_STR ; Skip to next entry

	jmp	short EMM2_EXTADDR_NOAVL ; Go around again


EMM2_EXTADDR_NOFREE:

; Process program storage

	mov	eax,PRGBASE	; Get starting address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	movzx	eax,PRGSIZE	; Get size
	shl	eax,10-0	; Convert from 1KB to bytes
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_PRG ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear the flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process WINSIZE memory (if any)

	mov	eax,WINSIZE	; Get PHYSIZE for Windows in 1KB
	mov	ebx,PHYSIZE	; Get reduced PHYSIZE in 1KB

	sub	eax,ebx 	; Less reduced PHYSIZE
	jbe	short @F	; Jump if nothing there

	shl	eax,10-0	; Convert from 1KB to bytes
	shl	ebx,10-0	; ...
	mov	AGROUP:[edi].EXTADDR_ADDR,ebx ; Save as starting address
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_WINSIZ ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear the flags

	add	edi,size EXTADDR_STR ; Skip to next entry
@@:

; Accumulate high DOS memory fill, ROM fill, and low DOS memory fill into
; one entry if debugging state is off

; Note that we're counting on the three above fill regions to be
; allocated increasingly in the above-mentioned order.

	cmp	[ebp].INTXX_EAX.ELO.LO,1 ; Is debugging on?
	je	short EMM2_EXTADDR_DEBUG ; Jump if so

	mov	ebx,OVRBASE	; Get starting address of 1st entry
	mov	AGROUP:[edi].EXTADDR_ADDR,ebx ; Save as starting address

	movzx	eax,LOWSIZE	; Get size of last entry

	cmp	ax,0		; Izit negative?
	jg	short @F	; Jump if not

	xor	ax,ax		; Set to zero
@@:
	shl	eax,10-0	; Convert from 1KB to bytes
	add	eax,LOWBASE	; Plus starting address of last entry

	sub	eax,ebx 	; Izit the same (no remapping entries)?
	je	short @F	; Jump if so

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_ABS ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:
	jmp	EMM2_EXTADDR_DEBUGCOM ; Join common code

; ออออออออออออออออออออออออ ALL DEBUGGING ENTRIES GO HERE อออออออออออออออออออออออ

; Process low DOS memory fill

EMM2_EXTADDR_DEBUG:
	mov	eax,LOWBASE	; Get starting address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	movzx	eax,LOWSIZE	; Get size

	cmp	ax,0		; Ensure non-negative
	jle	short @F	; Jump if not

	shl	eax,10-0	; Convert from 1KB to bytes
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_LOWF ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:

; Process high DOS memory fill

	mov	eax,OVRBASE	; Get starting address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	movzx	eax,OVRSIZE	; Get size

	shl	eax,10-0	; Convert from 1KB to bytes
	jz	short @F	; Jump if none

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_OVRF ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:

; Process ROM fill

	mov	eax,MAPBASE	; Get starting address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	movzx	eax,MAPSIZE	; Get size

	shl	eax,10-0	; Convert from 1KB to bytes
	jz	short @F	; Jump if none

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_ROMF ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:

; Process static code/data

	mov	eax,PRGBASE	; Get linear address of our base
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	lea	eax,ZLDATA	; End of data area (note relocatable)
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_MAX ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process 16-bit EMS tables

	mov	eax,PPHYS2SEG	; Get starting offset
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	sub	eax,PRGBASE	; Convert from linear address to offset

; Note that we're relying upon the fact that RPNTAB is the
; last table in this sequence

	mov	ebx,PRPNTAB	; Get starting offset of ending table

	movzx	ecx,MRS_MAX	; Get maximum # AMRS
	inc	cx		; Count in the default one
	imul	cx,NPHYS16S.ELO ; Times # physical 16KB pages in EMS system
	shl	ecx,1		; Times two for one word per RPNTAB entry
	add	ebx,ecx 	; Add to get ending address

	sub	eax,ebx 	; Subtract from maximum to get negative of length
	neg	eax		; Negate to get length
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_EMS16 ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process the stack

	mov	eax,PPL0STK_INI ; Get starting offset
	sub	eax,type PPL0STK_MAP ; Make room for PPL0STK_MAP deadman switch
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	sub	eax,PRGBASE	; Convert from linear address to offset

	sub	eax,PPL0STK_MAX ; Subtract from maximum to get negative of length
	neg	eax		; Negate to get length
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_STK ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process first set of 32-bit EMS tables

	mov	eax,PLINKBASE	; Get starting offset
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	sub	eax,PRGBASE	; Convert from linear address to offset

; Note that we're relying upon the fact that PCHECKER_INP is the
; next table in sequence

	sub	eax,PCHECKER_INP ; Subtract from maximum to get negative of length
	neg	eax		; Negate to get length
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_EMS32 ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process I/O check tables

	mov	eax,PCHECKER_INP ; Get starting offset
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	movzx	eax,CHECKER_LEN ; Get table limit in words
	shl	eax,2-0 	; Convert from two words to bytes
				; (two words for both the _INP and _OUT tables)
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_IOCHK ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process second set of 32-bit EMS tables

	mov	eax,PHNDLNAME	; Get starting offset
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	bx,@MAX_EHNDLCNT ; BX = maximum # EMS handles
	shl	bx,3		; Times eight bytes per handle name

	mov	ax,@MAX_EHNDLCNT+1 ; AX = maximum # handles plus unallocated handle
	shl	ax,1		; Times two for one word per handle page entry

	add	ax,bx		; Add to get length in bytes
	movzx	eax,ax		; Zero to use as dword

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_EMS32 ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process XMS tables

	mov	eax,PXMSBASE	; Get starting offset
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	sub	eax,PRGBASE	; Convert from linear address to offset

; Note that we're relying upon the fact that PVMTSS is the
; next table in sequence

	sub	eax,PVMTSS	; Subtract from maximum to get negative of length
	neg	eax		; Negate to get length
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_XMS32 ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process TSSs

	mov	eax,PVMTSS	; Get starting offset
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	mov	AGROUP:[edi].EXTADDR_LEN,@TSS_MAX * (type DPTSS_STR) ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_TSS ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process I/O Bit Permission Map

	mov	eax,PIOBIT	; Get starting offset
	add	eax,PRGBASE	; Convert from offset to linear address
	xor	ebx,ebx 	; Zero entire register
	mov	bx,@IOMAP+1	; Size of I/O map (note external)

; If there's an SIRB, it precedes the I/O bit permission map

	test	CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	jz	short @F	; Jump if not

	sub	eax,256/8	; Less size of SIRBCUR table
	add	ebx,256/8	; Plus ...
@@:
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	AGROUP:[edi].EXTADDR_LEN,ebx ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_IOBIT ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

if @OEM_WIN3

; Process UMB instance data

	mov	eax,PUMB_INST	; Get starting offset
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	xor	eax,eax 	; Zero to use as dword
	mov	ax,@UMB_INST_N+1 ; Get # entries
	imul	eax,type INSTANCE_ITEM_STR ; Times bytes per entry
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_INST ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process configuration file

	mov	eax,PCFGFILE	; Save as offset in PGROUP
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	movzx	eax,CFG_CNT	; Get the file size in bytes

	and	ax,ax		; Izit empty?
	jz	short @F	; Jump if so

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_CFG ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:

; Process Windows Paging Import Data area

	mov	eax,PWIN3_PAGE	; Get starting offset
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	sub	eax,PRGBASE	; Convert from linear address to offset

	sub	eax,PWIN3_PAGEZ ; Less ending address to get negative of length
	neg	eax		; Negate to get length
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_WIN3 ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry
endif				; IF @OEM_WIN3

; Process DMA buffer

	mov	eax,DMA_LA	; Get starting address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	movzx	eax,DMASIZE	; Get size
	shl	eax,10-0	; Convert from 1KB to bytes
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_DMA ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process Page Table Level 1

	mov	eax,LaCR3	; Get linear address of CR3
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	mov	eax,CON4KB	; Get size
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_PT1 ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process Page Tables Level 2

	mov	eax,LaDIR2	; Get offset of second level dirs
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	mov	eax,PDTLEN	; Get length of PDT segment in bytes
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_PT2 ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process AMRS Page Tables

	push	DTE_AMRS	; Pass selector
	FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	movzx	eax,MRS_MAX	; Get maximum # AMRS
	shl	eax,12-0	; Convert from 4KB to bytes
	jz	short @F	; Jump if none

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_AMRS ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:

if @OEM_SYS eq @OEMSYS_RET

; Process Periscope Memory

	mov	eax,PPDTPSM	; Get offset in PDT of PSMEM
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	movzx	eax,PSMSIZE	; Get size of memory in 1KB (/4KB)
	shl	eax,10-0	; Convert from 1KB to bytes
	jz	short @F	; Jump if none

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_PSM ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry
@@:
endif				; IF @OEM_SYS eq @OEMSYS_RET

; Process IGROUP entry

	mov	eax,IGRBASE	; Get starting address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	mov	eax,IGRSIZE	; Get size of IGROUP
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_IGR ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process FGROUP entry

	mov	eax,FGRBASE	; Get starting address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	mov	eax,FGRSIZE	; Get size of FGROUP
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_FGR ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process JGROUP & DL2GROUP entry

	mov	eax,JGRBASE	; Get starting address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	mov	eax,JGRDSIZE	; Get size of JGROUP & DL2GROUP
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_JGR ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

if @OEM_DPMI

; Process DPMI entries

	test	CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	jnz	near ptr EMM2_EXTADDR_NODPMI2 ; Jump if so

; Process LDT inside 386MAX

	mov	edx,PVMTSS	; Get offset in PGROUP of 1st TSS
	mov	eax,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	eax,PGROUP:[edx].DPTSS_LDT_SIZ ; Get byte size of DPMI LDT (/8)
	FIXICALL IGROUP:FDPMIFN_BITMAP_SIZ,DTE_CSIG ; Return with EBX = byte size of DPMI LDT (/8)
				; bitmap using LDT_SIZ of EAX
	add	eax,ebx 	; Add to get size of extended DPMI LDT

; The LDT for the 1st TSS is not extensible and its size is
; not rounded up to the next ALLOCMEM boundary

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
	mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (LDT #)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_LDT ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Mark as valid
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process DPMI memory handles inside 386MAX

;;;;;;; mov	edx,PVMTSS	; Get offset in PGROUP of 1st TSS
	mov	eax,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:ESI ==> DPMI memory
				; handle table
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get # handles
	imul	eax,type DPMIHNDL_STR ; Times # bytes per handle

; The DPMI memory handle table for the 1st TSS is not extensible
; and its size is not rounded up to the next ALLOCMEM boundary

	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
	mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (table #)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_DHNDL ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Mark as valid
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process DPMI page directories

	mov	eax,LaDPMIPDIR	; Get starting address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	eax,DPMIPDIR_CNT ; Get # PDIRs
	shl	eax,12-0	; Convert from 4KB to bytes
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_DPDIR ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry
EMM2_EXTADDR_NODPMI2:
endif				; IF @OEM_DPMI
if @OEM_VIRTUALMEM

; Process the Backing Store cache

	test	VMM_FLAG,@VMM_BSGLOBAL ; Is there a swap file present?
	jz	short EMM2_EXTADDR_NOSWAP ; Jump if not

	push	fs		; Save for a moment

	mov	fs,SEL_DSIG3	; Get IGROUP data selector at PL3
	assume	fs:IGROUP	; Tell the assembler about it

	mov	eax,PBSCache	; Get starting address
	add	eax,IGRBASE	; Plus linear address of IGROUP to get LA
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	mov	AGROUP:[edi].EXTADDR_LEN,@BSCSize ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_BSC ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it
EMM2_EXTADDR_NOSWAP:
endif				; IF @OEM_VIRTUALMEM

; Process I/O trapping tables

	mov	eax,PIOTRAP	; Get offset in PGROUP of I/O trapping strucs
	add	eax,PRGBASE	; Convert to 32-bit linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address
	mov	AGROUP:[edi].EXTADDR_LEN,@IOTRAP_MAX * (type IOTRAP_STR) ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_IOTRAP ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

; Process load modules

	mov	cx,LOADCOUNT	; Get # files to load
	jcxz	EMM2_EXTADDR_NOLOAD ; Jump if none

	mov	si,LOADTABIND	; Initialize index into LOADTAB
@@:
	mov	eax,LOADTAB.LOAD_POFF[si] ; Get offset in PGROUP
	add	eax,PRGBASE	; Convert to 32-bit linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	ebx,LOADTAB.LOAD_SIZ[si] ; Get the initialized file size
	add	ebx,LOADTAB.LOAD_USIZ[si] ; Plus size of uninitialized data
	mov	AGROUP:[edi].EXTADDR_LEN,ebx ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_LOAD ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry

	add	eax,ebx 	; Skip to next base address
	add	si,size LOAD_STR ; Skip to next structure entry

	loop	@B		; Jump if more load modules
EMM2_EXTADDR_NOLOAD:

; Process previous VDS table (if any)

	mov	eax,PVDSTAB	; Get offset in PGROUP of previous VDS table

	and	eax,eax 	; Izit valid?
	jz	short EMM2_EXTADDR_NOVDS ; Jump if not

	add	eax,PRGBASE	; Convert from offset to linear address
	mov	AGROUP:[edi].EXTADDR_ADDR,eax ; Save as starting address

	mov	eax,VDSTAB_LEN	; Get the table length in bytes
	mov	AGROUP:[edi].EXTADDR_LEN,eax ; Save as length
;;;;;;; mov	AGROUP:[edi].EXTADDR_HNDL,0 ; Save as handle # (ignored)
	mov	AGROUP:[edi].EXTADDR_TYPE,@EXTADDRTYPE_VDS ; Save as type
	mov	AGROUP:[edi].EXTADDR_FLAG,0 ; Clear flags
	add	edi,size EXTADDR_STR ; Skip to next entry
EMM2_EXTADDR_NOVDS:
; ออออออออออออออออออออออออ END OF ALL DEBUGGING ENTRIES ออออออออออออออออออออออออ
EMM2_EXTADDR_DEBUGCOM:
	mov	eax,edi 	; Save address of next byte in variable length fields

; Get 20-bit linear address offset of caller's ES:DI into AGROUP:EDI

	FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	assume	es:AGROUP	; Tell the assembler about it

; Calculate # entries in variable length fields

	sub	eax,edi 	; Subtract to get (# entries) * (type EXTADDR_STR)
	xor	edx,edx 	; Zero to use as qword
	mov	ebx,type EXTADDR_STR ; Get # bytes per structure entry
	div	ebx		; Divide to get # entries

	mov	[ebp].INTXX_ECX.ELO,ax ; Save as # entries in caller's CX

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_EXTADDR endp		; End JMM2_EXTADDR procedure
	FPPROC	JMM2_GETMAXINT -- EMM2 Get old interrupt vector
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 32, AH = 20h

Get interrupt vector after MAX's installation

On entry:

AL	=	Interrupt number

On exit:

EDX	=	Segment:Offset of interrupt (after MAX's installation)
AH	=	00h indicates success

All registers except EBP, SS, and ESP may be destroyed.

|

	mov	es,SEL_DSFG3	; Get FGROUP data selector at PL3
	assume	es:FGROUP	; Tell the assembler about it

	movzx	eax,[ebp].INTXX_EAX.LO ; Get the interrupt number

	mov	eax,MAXINT_VECS[eax*(type INT00_VEC)] ; Get vector from table

	mov	[ebp].INTXX_EDX,eax ; Set return value

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GETMAXINT endp		; End JMM2_GETMAXINT procedure
	FPPROC	JMM2_DSTKS -- EMM2 DOS Stacks Management
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 33, AH = 21h

Get/set DOS stacks information
Set DOS stacks state

On entry:

AL	=	0 to get DOS stacks information
	=	1 to set ...
	=	2 to set DOS stacks state

All registers except EBP, SS, and ESP may be destroyed.

|

	cmp	al,DSTKS_CNT ; Check for valid subfunction range
	jnb	near ptr JMM_E8F ; It's too big

	movzx	ebx,al		; Copy to index register, clear high-order bytes

	jmp	DSTKS_FNS[ebx*2] ; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_DSTKS endp 		; End JMM2_DSTKS procedure
	NPPROC	JMM2_DSTKS0 -- EMM2 Get DOS Stacks Information
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 33, AX = 2100h

Get DOS stacks information

On exit:

AH	=	0
ES:BX	==>	DSTK_TAB
CX	=	DSTK_CNT
DX	=	DSTK_ISIZ
SI.LO	=	master PIC intercepts
SI.HI	=	slave ...
DI.LO	=	DOS stacks state (see DSTK_REC for bit definitions)

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	mov	ax,DSTK_CNT	; Get # DOS stacks
	mov	[ebp].INTXX_ECX.ELO,ax ; Return in caller's CX

	mov	ax,DSTK_ISIZ	; Get size of each stack
	mov	[ebp].INTXX_EDX.ELO,ax ; Return in caller's DX

	mov	ax,PDSTKCOM.VSEG ; Get segment of DSTK_TAB
	mov	[ebp].INTXX_ES,ax ; Return in caller's ES
	mov	[ebp].INTXX_EBX.ELO,offset SGROUP:DSTK_TAB ; Return in caller's BX

	mov	al,DSTK_HWINTS[@IMRBASE/8] ; Get master HW interrupts
	mov	ah,DSTK_HWINTS[@IMR2BASE/8] ; ... slave ...
	mov	[ebp].INTXX_ESI.ELO,ax ; Return in caller's SI

	mov	al,DSTK_FLAG	; Get DOS stacks state
	mov	[ebp].INTXX_EDI.ELO.LO,al ; Return in caller's DI.LO

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_DSTKS0 endp		; End JMM2_DSTKS0 procedure
	NPPROC	JMM2_DSTKS1 -- EMM2 Set DOS Stacks Information
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 33, AX = 2101h

Set DOS stacks information

On entry:

EBX	=	new PDSTKCOM
ECX	=	new LaDSTK_TAB

On exit:

AH	=	0

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	mov	eax,[ebp].INTXX_EBX ; Get new PDSTKCOM
	mov	PDSTKCOM,eax	; Save new value

	mov	eax,[ebp].INTXX_ECX ; Get new LaDSTK_TAB
	mov	LaDSTK_TAB,eax	; Save new value

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_DSTKS1 endp		; End JMM2_DSTKS1 procedure
	NPPROC	JMM2_DSTKS2 -- EMM2 Set DOS Stacks State
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 33, AX = 2102h

Set DOS stacks state

On exit:

AH	=	0  if all went well
	=	8A if BL > 1

All registers except EBP, SS, and ESP may be destroyed.

|

	mov	al,[ebp].INTXX_EBX.ELO.LO ; Get state from caller's BL

	cmp	al,1 shl (width DSTK_REC) ; Ensure valid
	jae	near ptr JMM_E8A ; Jump if not

	mov	DSTK_FLAG,al	; Set DOS stacks state

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_DSTKS2 endp		; End JMM2_DSTKS2 procedure
	FPPROC	JMM2_INITREST -- EMM2 Call API Load Module INIT_PROT/REST_PROT
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 34, AH = 22h

Call API load module INIT_PROT / REST_PROT procedures

On entry:
AL	=	1	Call INIT_PROT
AL	=	0	Call REST_PROT

On exit:

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	cmp	[ebp].INTXX_EAX.ELO.LO,0 ; Izit INIT or REST?
	je	short JMM2_INITREST_REST ; Jump to REST_PROT code

	FIXICALL PGROUP:FINIT_PROT,DTE_CS2 ; Call 'em

	jmp	short JMM2_INITREST_COM ; Rejoin common code

JMM2_INITREST_REST:
	FIXICALL PGROUP:FREST_PROT,DTE_CS2 ; Call 'em

JMM2_INITREST_COM:
	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_INITREST endp		; End JMM2_INITREST procedure
if @OEM_EMS
	FPPROC	JMM_TEST -- Test The EMM Tables
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure integrity of the EMM tables

|

	pushf			; Save flags
	cli			; Disallow interrupts

	REGSAVE <ebx,cx,dx,ds,fs> ; Save registers

	push	DTE_DS		; Get our data selector
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	push	DTE_PDT 	; Get our PDT selector
	pop	fs		; Address it
	assume	fs:PDTGRP	; Tell the assembler about it

; If the EMS pages can extend into the 1MB wrap region, disable
; the 1MB wrap

	mov	ebx,PPDTEMM	; Get offset in PDT of EMS entries
	mov	dx,GLB_FLAG	; Save 1MB wrap bit

	cmp	ebx,PPDT1P1MB	; Izit within 1MB wrap region?
	jae	short @F	; Jump if not

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap, ignore return
@@:

; For all handles as well as the free chain, follow them though the
; tables and mark them as used.

	mov	ebx,PHNDLPAGE	; DS:EBX ==> HNDLPAGE table
	mov	cx,@MAX_EHNDLCNT ; CX = maximum # EMS handles
@@:
	call	ET_CHK		; Check it out

	add	ebx,size PL_STR ; Skip to next handle offset

	loop	@B		; Jump if more handles to check

; Test the free chain

	mov	ebx,PHNDLPAGE	; DS:EBX ==> HNDLPAGE table
	add	ebx,@FREE_HNDL*(size PL_STR) ; Get free chain handle offset

	call	ET_CHK		; Check it out

; If SCREEN specified, test it too

	test	CM2_FLAG,@CM2_SCR ; SCREEN specified?
	jz	short @F	; Not this time

	mov	ebx,PHNDLPAGE	; DS:EBX ==> HNDLPAGE table
	add	ebx,@SCR_HNDL*(size PL_STR) ; Get SCREEN handle offset

	call	ET_CHK		; Check it out
@@:

if @OEM_XMS

; If VCPI/XMS allocations made, test them, too

	mov	ebx,PHNDLPAGE	; DS:EBX ==> HNDLPAGE table
	add	ebx,@VMS_HNDL*(size PL_STR) ; Get VMS handle offset

	call	ET_CHK		; Check it out
endif				; IF @OEM_XMS
	call	ET_CLR		; Clear the entries

; If we disabled the 1MB wrap above, re-enable it

	xor	dx,GLB_FLAG	; Match the before and after

	test	dx,@GLB_1MB	; Did it change?
	jz	short @F	; Jump if not

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	FIXICALL PGROUP:FWRAP_ENABLE,DTE_CS2 ; Enable the 1MB wrap, ignore return
@@:
	REGREST <fs,ds,dx,cx,ebx> ; Restore
	assume	ds:nothing,fs:nothing ; Tell the assembler about it

	popf			; Restore flags

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM_TEST endp			; End JMM_TEST procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	NPPROC	ET_CHK -- EMM_TEST Checking Subroutine
	assume	ds:PGROUP,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

On entry:

DS:EBX	==>	HNDLPAGE entry

|

	REGSAVE <eax,ebx,ecx,esi> ; Save registers

	mov	eax,HP_LAST	; Get value of last entry
ET_CHK_NEXT:
	cmp	PGROUP:[ebx].PL_NEXT,eax ; Izit the last entry?
	je	short ET_CHK_EXIT ; Yes, skip out

	bts	PGROUP:[ebx].PL_NEXT.LO,0 ; Test and set the bit
	jnc	short ET_CHK_NEXT1 ; Jump if it was clear

	int	01h		; Call our debugger
ET_CHK_NEXT1:
	mov	ebx,PGROUP:[ebx].PL_NEXT ; Get next link
	dec	ebx		; Clear low-order bit

	push	ebx		; Save for a moment

	sub	ebx,PPAGELINK	; Convert to (size PL_STR) * 16KB page #
	mov	esi,ebx 	; Save for a moment
;;;;;;; shl	ebx,2-2 	; Convert from dword to dword index
	add	ebx,PLINKBASE	; Plus base of PDT PTEs
	shl	esi,4-2 	; Convert from dword to four-dword index
	add	esi,PGROUP:[ebx] ; Plus the corresponding offset

	pop	ebx		; Restore

; ES:ESI = offset of PTEs in PDT for this 16KB page

	mov	cx,4		; # PTEs to test and set
ET_CHK_PTE:
	bts	OFFPDT[esi],$PTE_AV2 ; Test and set the bit
	jnc	short @F

	int	01h		; Call our debugger
@@:
	add	esi,4		; Skip to next PTE

	loop	ET_CHK_PTE	; Jump if more PTEs to test and set

	jmp	ET_CHK_NEXT	; Go around again

ET_CHK_EXIT:
	REGREST <esi,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ET_CHK	endp			; End ET_CHK procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	NPPROC	ET_CLR -- Test and Clear EMM Table Entries
	assume	ds:PGROUP,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Test and clear previously set EMM table entries.

|

	REGSAVE <eax,ecx,esi>	; Save registers

; Trundle through the HNDLPAGE, PAGELINK, EMMBASE, and CNVBASE tables
; testing and clearing the previously set bits


; For the PAGELINK table, either the entry is HP_LAST or its
; low-order bit is set; otherwise, ugh.

	mov	esi,PHNDLPAGE	; DS:ESI ==> start of HNDLPAGE table
	mov	cx,@MAX_EHNDLCNT+1 ; CX = maximum # EMS handles plus free chain
if @OEM_WIN3
	inc	cx		; Include EMS to XMS chain handle
endif				; IF @OEM_WIN3
	mov	eax,HP_LAST	; Get value of last entry
ET_CLR_NEXTHNDL:
	cmp	PGROUP:[esi].PL_NEXT,eax ; Check for ending entry
	je	short ET_CLR_LOOPHNDL ; Jump if so

	btr	PGROUP:[esi].PL_NEXT,0 ; Test and reset the bit
	jc	short ET_CLR_LOOPHNDL ; Jump if it was set

	int	01h		; Call our debugger
ET_CLR_LOOPHNDL:
	add	esi,size PL_STR ; Skip to next handle offset

	loop	ET_CLR_NEXTHNDL ; Jump if more entries to clear



; For the PAGELINK table, either the entry is HP_LAST or its
; low-order bit is set; otherwise, ugh.

	mov	esi,PPAGELINK	; DS:ESI ==> start of PAGELINK table
	mov	ecx,CMPSIZEMM	; Get EMS limited size of common memory pool in 1KB (multiple of 4KB)
;;;;;;; and	ecx,not (16-1)	; Round down to 16KB boundary
	shr	ecx,14-10	; Convert from 1KB to 16KB (size of EMS pages)

	push	eax		; Save for a moment

	movzx	eax,NPHYSCNV.ELO ; Get # physical 16KB pages in CNV memory
	add	ax,NPHYSSCR.ELO ; Plus # physical 16KB pages in SCREEN memory
	add	ecx,eax 	; Add to get # 16KB pages in EMS system

	pop	eax		; Restore
ET_CLR_NEXTPAGE:
	cmp	PGROUP:[esi].PL_NEXT,eax ; Clear for ending entry
	je	short ET_CLR_LOOPPAGE ; Jump if so

	btr	PGROUP:[esi].PL_NEXT,0 ; Test and reset the bit
	jc	short ET_CLR_LOOPPAGE ; Jump if it was set

	int	01h		; Call our debugger
ET_CLR_LOOPPAGE:
	add	esi,size PL_STR ; Skip to next page link

	loopd	ET_CLR_NEXTPAGE ; Jump if more entries to clear


; For the EMMBASE PTEs, the $PTE_AV2 bit must be set

	mov	ecx,CMPSIZEMM	; Get EMS limited size of common memory pool in 1KB (multiple of 4KB)
	and	ecx,not (16-1)	; Round down to 16KB boundary
	shr	ecx,12-10	; Convert from 1KB to 4KB
	mov	esi,PPDTEMM	; ES:ESI ==> start of EMS PTEs in PDT
ET_CLR_NEXTPTE1:
	btr	OFFPDT[esi],$PTE_AV2 ; Test and reset the bit
	jc	short @F	; Jump if it was set

	int	01h		; Call our debugger
@@:
	add	esi,4		; Skip to next PTE

	loopd	ET_CLR_NEXTPTE1 ; Jump if more PTEs to clear


; For the CNVBASE PTEs, the $PTE_AV2 bit must be set

	mov	cx,NPHYSCNV.ELO ; Get # physical 16KB pages in CNV memory
	mov	esi,PSEG2PHYS	; DS:ESI ==> SEG2PHYS table
	movzx	esi,PGROUP:[esi].LO ; Get first entry (lowest CNV entry)
	shl	esi,1		; Times two to index table of words
	add	esi,PPHYS2SEG	; Plus base of PHYS2SEG table
				; DS:ESI ==> CNV entries
ET_CLR_NEXTCNV:
	xor	eax,eax 	; Zero to use as dword
	lods	PGROUP:[esi].ELO ; Get next segment (multiple of 4KB in paras)
	shr	eax,(12-2)-4	; Convert from paras to 4KB in dwords
	add	eax,PPDTCNV	; Plus base of CNV entries

	push	cx		; Save for a moment

	mov	cx,16/4 	; # 4KB PTEs in 16KB EMS page
ET_CLR_NEXTPTE2:
	btr	OFFPDT[eax],$PTE_AV2 ; Test and reset the bit
	jc	short @F	; Jump if it was set

	int	01h		; Call our debugger
@@:
	add	eax,4		; Skip to next PTE

	loop	ET_CLR_NEXTPTE2 ; Jump if more PTEs to clear

	pop	cx		; Restore

	loop	ET_CLR_NEXTCNV	; Jump if more CNVs to clear

	REGREST <esi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ET_CLR	endp			; End ET_CLR procedure
endif				; IF @OEM_EMS
	FPPROC	JMM2_TMPCLOSE -- EMM2 Call Temporarily Close High DOS
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 37, AH = 25h

Temporarily close high DOS to prevent illicit allocations
by DOS 4B00/4B01 calls while arenas are linked.  Arenas will
automatically be re-linked by next DOS call that invokes
INT21_MACFNS.

Call is ignored unless low and high DOS arenas were linked
via Int 21h function 5803h.

On exit:

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|


	test	I15_FLAG,@I15_LINK58 ; Is high DOS open for business?
	jz	short @F	; Jump if not (no action needed)

	or	I15_FLAG,@I15_HI4B ; Set flag for next call to MACFNS

	mov	gs,SEL_4GB3	; Address our all memory selector
	assume	gs:AGROUP	; Tell the assembler about it

	FIXICALL PGROUP:FCLOSEHIGHDOS,DTE_CS2 ; Unlink low and high DOS arenas
@@:
	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_TMPCLOSE endp		; End JMM2_TMPCLOSE procedure
if @OEM_VIRTUALMEM
	FPPROC	JMM2_SWAPFILE -- EMM2 Call To Get SWAPFILE-Related Data
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 40, AH = 28h

Return SWAPFILE-related data.

On exit:

If successful,
AH	=	0
CX	=	file handle of SWAPFILE
DX	=	PSP in which the SWAPFILE was last opened

If not successful,
AH	=	8Fh

All registers except EBP, SS, and ESP may be destroyed.

|

	cmp	DPMITYPE,@DPMITYPEXX ; Is DPMI active?
	je	near ptr JMM_E8F ; Jump if not (ignore)

	test	VMM_FLAG,@VMM_SYSINIT ; Has the system been initialized?
	jz	near ptr JMM_E8F ; Jump if not (ignore)

	test	VMM_FLAG,@VMM_BSPRES ; Is a SWAPFILE present?
	jz	near ptr JMM_E8F ; Jump if not (ignore)

	test	VMM_FLAG,@VMM_BSCLOSE ; Is the SWAPFILE being closed?
	jnz	near ptr JMM_E8F ; Jump if so (allow this close)

	mov	ebx,PCURTSS	; Get offset in PGROUP of current TSS

	mov	ax,PGROUP:[ebx].DPTSS_VMM_BS_PSP ; Get the PSP
	mov	[ebp].INTXX_EDX.ELO,ax ; Return in DX

	mov	ax,PGROUP:[ebx].DPTSS_VMM_BS_handle ; Get the handle
	mov	[ebp].INTXX_ECX.ELO,ax ; Return in CX

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_SWAPFILE endp		; End JMM2_SWAPFILE procedure
endif				; IF @OEM_VIRTUALMEM
	FPPROC	JMM2_VMVSAPI -- EMM2 Call To Perform VM Vendor-Specific API Call
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 41, AH = 29h

Perform VM Vendor-Specific API call

On entry:

On PL3 stack:
SS:SP	==>	AX (function #) to be popped

On exit:

If successful,
AH	=	0

If not successful,
AH	=	8Fh

All registers except EBP, SS, and ESP may be destroyed.

|

	mov	gs,SEL_4GB3	; Get AGROUP data selector at PL3
	assume	gs:AGROUP	; Tell the assembler about it

	movzx	eax,[ebp].INTXX_SS ; Get caller's stack segment
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	esi,[ebp].INTXX_ESP.ELO ; Get caller's stack pointer

	movzx	eax,AGROUP:[eax+esi] ; Get PUSHed AX from PL3 stack
	mov	[ebp].INTXX_EAX.ELO,ax ; Save for our local handlers
	add	[ebp].INTXX_ESP.ELO,2 ; Skip over PUSHed AX

	cmp	ax,@VSAPI_LEN	; Izit a valid function number?
	jae	near ptr JMM_E84 ; Jump if not

	jmp	VSAPIACT[eax*(type VSAPIACT)] ; Take appropriate action

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_VMVSAPI endp		; End JMM2_VMVSAPI procedure
	NPPROC	JMM2_VSAPI00 -- VSAPI Function To Set No SWAPFILE Count
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

VMVSAPI function 0000 to set no SWAPFILE count.
The count is decremented each time a client enters PM.
When it is non-zero, @VMM_BSPRES is clear.

On entry:

SS:EBP	==>	INTXX_STR

In PL3 registers,

BX	=	count (-1 = forever)

On exit:

AH	=	0 if successful
BX	=	old count

All registers except EBP, SS, and ESP may be destroyed.

|

	mov	ax,0		; Assume no swapfile

	test	VMM_FLAG,@VMM_BSGLOBAL ; Is there a global swapfile?
	jz	short @F	; Jump if not

	mov	ax,[ebp].INTXX_EBX.ELO ; Get the count
	xchg	ax,NOSWAP_CNT	; Swap with old value
@@:
	mov	[ebp].INTXX_EBX.ELO,ax ; Return to caller

	FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_VSAPI00 endp		; End JMM2_VSAPI00 procedure
	FPPROC	FMAC_MERGE -- Merge Adjacent Free MACs
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Merge adjacent feee MACs starting at POVR_MAC
and check for orphan LSEG entries.

On entry:

GS:0	==>	all memory

On exit:

CF	=	0 if all went OK
	=	1 if something went wrong

|

	call	MAC_MERGE	; Merge adjacent free MACs starting at POVR_MAC
				; Return with CF significant
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMAC_MERGE endp 		; End FMAC_MERGE procedure
	FPPROC	ACTIVATE_HOOK13 -- Activate The HOOK13 Byte
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Activate the HOOK13 byte if it's inactive.

Because of an incompatibility with IOS.386 in WFW 3.11, we need to
change how we manage vector swapping in response to INT 2Fh/AH=13h.
The changes are in JMM2_INITWIN3 to disable swapping, and in ENTERVM
(and a back up in INT2F w/AX=1606h in case Windows doesn't initialize)
to enable swapping.

If we're initializing Windows (1605 time) and we're hooking INT 13h
via INT 2Fh/AH=13h, then we change HOOK13 to active state.

Also, see comments in INACTIVATE_HOOK13.

|

	push	ds		; Save for a moment

	mov	ds,JSEL_DS3	; Get PGROUP data selector at PL3
	assume	ds:PGROUP	; Tell the assembler about it

	mov	ds,SEL_DSHI	; Get high DOS memory selector
	assume	ds:PGROUP	; Tell the assembler about it

	cmp	LOWWIN3_CB,0	; Is Windows active?
	jne	short @F	; Jump if so

	cmp	HOOK13,@HOOK13_OFF ; Izit hooked?
	je	short @F	; Jump if not

	mov	HOOK13,@HOOK13_ACTIV ; Mark as active
@@:
	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACTIVATE_HOOK13 endp		; End ACTIVATE_HOOK13 procedure
	NPPROC	INACTIVATE_HOOK13 -- Inactivate HOOK13
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Inactivate the HOOK13 byte if it's active.

Because of an incompatibility with IOS.386 in WFW 3.11, we need to
change how we manage vector swapping in response to INT 2Fh/AH=13h.
The changes are in JMM2_INITWIN3 to disable swapping, and in ENTERVM
(and a back up in INT2F w/AX=1606h in case Windows doesn't initialize)
to enable swapping.

If we're already hooking INT 13h, and it's Windows version 3.11 or
later, then we change HOOK13 to inactive state.

Also, see comments in ACTIVATE_HOOK13.

|

	push	ds		; Save for a moment

	mov	ds,JSEL_DS3	; Get PGROUP data selector at PL3
	assume	ds:PGROUP	; Tell the assembler about it

	mov	ds,SEL_DSHI	; Get high DOS memory selector
	assume	ds:PGROUP	; Tell the assembler about it

	cmp	HOOK13,@HOOK13_OFF ; Izit hooked?
	je	short INACTIVATE_HOOK13_EXIT ; Jump if not

	cmp	WIN3_VERSION,030Bh ; Izit Windows 3.11 or later?
	jb	short INACTIVATE_HOOK13_EXIT ; Jump if not

	mov	HOOK13,@HOOK13_INACT ; Mark as inactive until
				; next 4Bxxh w/LOWWIN3_CB=0
INACTIVATE_HOOK13_EXIT:
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INACTIVATE_HOOK13 endp		; End INACTIVATE_HOOK13 procedure
	align	4		; Ensure dword alignment

JCODE	ends			; End JCODE segment

	MEND			; End QMAX_IM2 module

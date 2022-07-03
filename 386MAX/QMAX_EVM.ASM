;' $Header:   P:/PVCS/MAX/386MAX/QMAX_EVM.ASV   1.9   30 May 1997 10:44:28   BOB  $
	 title	 QMAX_EVM -- 386MAX Enter VM 8086 Mode Routines
	 page	 58,122
	 name	 QMAX_EVM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
	       Program segment ZCODE, para-aligned,  public, class 'zcode'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Program segment NCODE, byte-aligned,  public, class 'ncode'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'
	       Data    segment ZDATA, para-aligned,  public, class 'zdata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'
	       Data    segment FIXUP,	    para-aligned, public, class 'fixup'
	       Data    segment FIX_PGROUP,  word-aligned, public, class 'fixup'
	       Data    segment FIXZ_PGROUP, word-aligned, public, class 'fixup'
	       Data    segment FIX_IGROUP,  word-aligned, public, class 'fixup'
	       Data    segment FIXZ_IGROUP, word-aligned, public, class 'fixup'
	       Data    segment FIX_JGROUP,  word-aligned, public, class 'fixup'
	       Data    segment FIXZ_JGROUP, word-aligned, public, class 'fixup'
	       Group IGROUP:
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'
	       Data    segment XDATA, dword-aligned, public, class 'xdata'
	       Group YGROUP:
	       Data    segment YDATA, dword-aligned, public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include VIDCALL.INC
	 include BIOSDATA.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include IOPBITS.INC
	 include CMOS.INC
	 include 8255.INC
	 include 8259.INC
	 include 386.INC
	 include PTR.INC
	 include MASM5.MAC
	 include DEVDRV.INC
	 include ALLMEM.INC
	 include VDS.INC
	 include EMM2CALL.INC
	 include WIN3PAGE.INC
	 include INTVEC.INC
	 include ROMSEG.INC
	 include MOVSPR.INC
	 include CPUFET.INC
	 include IOTRAP.INC
	include PNP.INC

	 include PDTGRP.INC
	 include QMAX_CFG.INC
	 include QMAX_DMA.INC
	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAX_LOD.INC
	 include QMAX_OEM.INC
	 include QMAX_SWT.INC	; For SWAT
	 include QMAX_TRC.INC
	 include QMAX_FLX.INC
	 include QMAX_TSS.INC
	 include QMAX_I31.INC
.list

if @OEM_DEBUG
PGROUP	 group	 CODE,HICODE,ZCODE,ECODE,DEBUG,EDATA,NCODE,NDATA,ZDATA
else
PGROUP	 group	 CODE,HICODE,ZCODE,ECODE,EDATA,NCODE,NDATA,ZDATA
endif				; IF @OEM_DEBUG
FGROUP	 group	 FDATA,FIXUP,FIX_PGROUP,FIXZ_PGROUP,FIX_IGROUP,FIXZ_IGROUP,FIX_JGROUP,FIXZ_JGROUP
IGROUP	 group	 LDATA
JGROUP	 group	 JCODE
XGROUP	 group	 XCODE,XDATA
YGROUP	 group	 YDATA


FIXUP	 segment use16 para public 'fixup' ; Begin FIXUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 extrn	 FIXUP_LAST_CS2:word
	 extrn	 FIXUP_LAST_CSIG:word
	 extrn	 FIXUP_LAST_CSJG:word

FIXUP	 ends			; End FIXUP segment


FIX_PGROUP segment use16 word public 'fixup' ; Begin FIX_PGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 extrn	 FIXTAB_PGROUP:word

FIX_PGROUP ends 		; End FIX_PGROUP segment


FIXZ_PGROUP segment use16 word public 'fixup' ; Begin FIXZ_PGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 extrn	 FIXTABZP:word

FIXZ_PGROUP ends		; End FIXZ_PGROUP segment


FIX_IGROUP segment use16 word public 'fixup' ; Begin FIX_IGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 extrn	 FIXTAB_IGROUP:word

FIX_IGROUP ends 		; End FIX_IGROUP segment


FIXZ_IGROUP segment use16 word public 'fixup' ; Begin FIXZ_IGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 extrn	 FIXTABZI:word

FIXZ_IGROUP ends		; End FIXZ_IGROUP segment


FIX_JGROUP segment use16 word public 'fixup' ; Begin FIX_JGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 extrn	 FIXTAB_JGROUP:word

FIX_JGROUP ends 		; End FIX_JGROUP segment


FIXZ_JGROUP segment use16 word public 'fixup' ; Begin FIXZ_JGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 extrn	 FIXTABZJ:word

FIXZ_JGROUP ends		; End FIXZ_JGROUP segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 extrn	 INIT_DATA:far
	 extrn	 MAP_WIN3:far
	 extrn	 DMA_WIN3:far
	 extrn	 CAPOVR_WIN3:far
	 extrn	 PVDS_TRANS:far
	 extrn	 ACTIVATE_HOOK13:far

JCODE	 ends			; End JCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 PPI_K2S:near
	 extrn	 WAITOBUF_CLR:near

	 extrn	 GATEA20:near
	 extrn	 ENABLE_IMR:near
	 extrn	 SHADOW_ENABLE:near
	extrn	RESINT_PnP:far
	extrn	ORIG_PnP_RMVEC:dword

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

	extrn	CM4_FLAG:word
	include QMAX_CM4.INC

	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 DB3_FLAG:word
	 include QMAX_DB3.INC

	 extrn	 QMAX_VER:byte
	 include QMAX_HDM.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 DEVDRV:tbyte
	 extrn	 SHDSIZE:word
if @OEM_EMS
	 extrn	 EMMSIZE:dword
endif				; IF @OEM_EMS
	 extrn	 PRGSIZE:word
	 extrn	 TOTSIZE:dword
	 extrn	 SWPSIZE:word
	 extrn	 LOWSIZE:word
	 extrn	 EXTSIZE:dword
	 extrn	 LCL_CR3:dword
	 extrn	 PORT67:word
	 extrn	 PLOWSTKZ:word
	 extrn	 LOWSTKZ:byte
	 extrn	 INTA01:byte
	 extrn	 INTB01:byte

if @OEM_WIN3
	 extrn	 LOWWIN3_CB:byte
endif				; IF @OEM_WIN3
	extrn	PnP_SEG:word

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

if @OEM_WIN3
	 extrn	 WIN3_VERSION:word
	 extrn	 EMM_Import_Ptr:dword
endif				; IF @OEM_WIN3

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

HICODE	 ends			; End HICODE segment


ZCODE	 segment use16 para public 'zcode' ; Start ZCODE segment
	 assume  ds:PGROUP

	 extrn	 OVR_HPDA:tbyte

ZCODE	 ends			; End ZCODE segment


if @OEM_DEBUG
DEBUG	 segment use16 byte public 'ecode' ; Start DEBUG segment
	 assume  cs:PGROUP

	 extrn	 CHECKPOINT:near

DEBUG	 ends			; End DEBUG segment
endif				; IF @OEM_DEBUG


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_4GB3:word
	 extrn	 ISEL_DS3:word

LDATA	 ends			; End LDATA segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 PIOTRAP:dword

	 extrn	 PVDSTAB:dword
	 extrn	 VDSTAB_LEN:dword

	 extrn	 MAPTAB:tbyte,MAPTAB_CNT:word
	 include QMAX_MAP.INC

	 extrn	 MCSTAB:tbyte,MCSTAB_CNT:word
	 include QMAX_MCS.INC

	 extrn	 PPMTAB:byte,PPMTAB_LEN:abs
	 include QMAX_PPM.INC

	 extrn	 SHDTAB:word,SHDCNT:word
	 include QMAX_SHD.INC

	 extrn	 PRGPDT:dword
if @OEM_XMS
	 extrn	 PPDTCVD:dword
endif				; IF @OEM_XMS
	 extrn	 PPDTLOW:dword
	 extrn	 PPDTPRG:dword
	 extrn	 PPDTCNV:dword
	 extrn	 PPDTSCR:dword
	 extrn	 PPDT1MB:dword
	 extrn	 PPDT1W1MB:dword
	 extrn	 PPDTPDIR:dword
if @OEM_DMA
	 extrn	 PPDTDMAP:dword,PPDTDMA:dword,DMASIZE:word
endif				; IF @OEM_DMA
	extrn	PPDTPnPBIOS:dword
	extrn	LaPnP_BIOS:dword
	extrn	LaGDTPnPARG:dword
	extrn	laPnP_PMCS:dword
	extrn	laPnP_PMDS:dword
	extrn	SEL_PnPDS:word
	extrn	OffPnP_PMCS:dword
	extrn	OffPnP_RMVEC:dword
	 extrn	 OVRBASE:dword,PPDTOVR:dword,OVRSIZE:word
	 extrn	 MAPBASE:dword,PPDTMAP:dword,MAPSIZE:word
	 extrn	 LMLBASE:dword,PPDTLML:dword
	 extrn	 EXFSIZE:dword

if @OEM_EMS
	 extrn	 PPHYS2SEG:dword
	 extrn	 PSEG2PHYS:dword
	 extrn	 NPHYS16S:byte
endif				; IF @OEM_EMS
	 extrn	 CON4KB:dword
	 extrn	 CON64KB:dword
	 extrn	 CON1MB:dword
	 extrn	 CON16MB:dword

	 extrn	 CPUFET_FLAG:dword
	 extrn	 LaSIRBCUR:dword
	 extrn	 PVMTSS:dword
	 extrn	 PCURTSS:dword
	 extrn	 PIOBIT:dword
	 extrn	 @IOMAP:abs
	 extrn	 PPL0STK_MAX:dword

	 extrn	 LOWOFF:dword
	 extrn	 VIDOFF:dword
	 extrn	 LMLTOP:dword
	 extrn	 WRAPTAB:dword
	 extrn	 MAPSEG_NXT:word
if @OEM_DMA
	 extrn	 DMA_LA:dword,DMA_PA:dword
endif				; IF @OEM_DMA
if @OEM_SYS ne @OEMSYS_ILIM and @OEM_SYS ne @OEMSYS_LHY
	 extrn	 MSG_EAVL:byte
endif				; IF @OEM_SYS ne @OEMSYS_ILIM and @OEM_SYS ne @OEMSYS_LHY

	 extrn	 IDT_DESC:qword
	 extrn	 IDT_DESC_LEN:abs

	 extrn	 PGDT_LHI:fword
	 extrn	 PIDT_LHI:fword

	 extrn	 SEL_DSHI:word
	 extrn	 SEL_GDT:word
	 extrn	 SEL_4GB3:word
	 extrn	 SEL_DSFG3:word

	 extrn	 CFG_CNT:word
	 extrn	 CFG_LCNT:word
	 extrn	 CFGLIST:word
	 extrn	 @CFGLIST_LEN:abs
	 extrn	 PCFGFILE:dword

if @OEM_WIN3
if @OEM_HIFILL and @OEM_WIN3
	 extrn	 OLDHDM:byte
endif				; IF @OEM_HIFILL and @OEM_WIN3
endif				; IF @OEM_WIN3

	 extrn	 FGRBASE:dword
	 extrn	 FGRSIZE:dword
	 extrn	 IGRBASE:dword
	 extrn	 IGRSIZE:dword
	 extrn	 JGRBASE:dword
	 extrn	 JGRSIZE:dword
	 extrn	 JGRDSIZE:dword

if @OEM_DPMI
	 extrn	 DPMI_DATA:word
	 extrn	 PDPMILDT:dword
	 extrn	 LDT_SIZ:dword
	 extrn	 VM2PM_TSS:word
	 extrn	 DPMIHNDL_CNT:dword
	 extrn	 DPMIHNDL_OFF:dword
	 extrn	 DPMIPDIR_CNT:dword
	 extrn	 LaDPMIPDIR:dword
	 extrn	 LaDPMIPDIRMEM:dword
	 extrn	 HPDABUF_OFF:word
	 extrn	 HPDABUF_SIZ:word
	 extrn	 HPDASTK_SIZ:word
	 extrn	 HPDASTK_TOP:word
endif				; IF @OEM_DPMI

if @OEM_DEBUG
	 extrn	 CPD_FLAG:word
	 include QMAX_CPD.INC

	 extrn	 HEXTABLE:byte
endif				; IF @OEM_DEBUG

if @OEM_FLEXROM
	 extrn	 FLEXROM_FLAG:word
	 extrn	 FLEXROM_LEN:word
	 extrn	 FLEXROM_TBL:tbyte
	 extrn	 VGA_ALTSEG1:word
	 extrn	 VGA_ALTSEG2:word
endif				; IF @OEM_FLEXROM

	 extrn	 LOADCOUNT:word
	 extrn	 LOADTABIND:word
	 extrn	 LOADTAB:tbyte

	 extrn	 FLG_GET_DRn:byte
	 extrn	 FLG_SET_DRn:byte

; For best performance, ensure the GDT is on a dword boundary

	 public  DESC_TAB
	 align	 4		; Ensure dword-aligned
DESC_TAB db	 (type XDTE_STR) dup (?) ; Extended descriptor tables
; Due to a bug in LINK, an instance of XDTE_STR <> must not be used!

	 public  PRGBASE,PaPRGBASE,PaPRGBASE2
PRGBASE  dd	 ?		; Start of PRG in extended memory
PaPRGBASE dd	 ?		; Physical address of ...
PaPRGBASE2 dd	 ?		; Secondary physical address of ...

	 public  LaDIR2,PaDIR2,PDTDIR2,LaOPTE,PaOPTE1
	 public  OFFCR3,PDBSIZE,LaPDIREND
LaDIR2	 dd	 ?		; Linear address of PDEs
PaDIR2	 dd	 ?		; Physical ...
PDTDIR2  dd	 ?		; Offset of PDE in PDT
LaOPTE	 dd	 ?		; Linear address of overflow PTE table
PaOPTE1  dd	 ?		; Physical ...	    first ...
OFFCR3	 dd	 ?		; Offset of PDE table from PGROUP:0
PDBSIZE  dd	 ?		; # active page directory base entries
LaPDIREND dd	 ?		; Linear address of end of PDIR

	 public  LaCR3
LaCR3	 dd	 ?		; Linear address of CR3

	 public  PPDTSHD
PPDTSHD  dd	 ?		; Offset in PDT of shadow RAM

	 public  GORSIZE
GORSIZE  dd	 0		; Size of gore region in 1KB

if @OEM_WIN3
	 public  WIN3_REF_DATA
	 include QMAXWIN3.INC
;;WIN3_REF_DATA  REF_DATA_STR <> ; Reference data structure for VxD
WIN3_REF_DATA db (type REF_DATA_STR) dup (0) ; Reference data structure for VxD
; Due to a bug in LINK, an instance of WIN3_REF_DATA <> can't be used
endif				; IF @OEM_WIN3

if @OEM_DMA
	 public  DMA_SWAP
DMA_SWAP dw	 0010h		; Starting address (in units of 4KB)
				; of DMA swapping area search

COMMENT|

The maximum DMA buffer address is constrained by several factors:

1.  The DMA buffer may be as large as 128KB.
2.  Early versions of the COMPAQ 16 MHz system board do not allow
    DMA into the last 128KB of reserved memory.  Maybe other systems
    have the same problem, so the limit is no larger than 00FE0000 on
    all machines with shadow RAM recovery at just under 16 MB.
3.  The DMA controller on AT-class systems is limited to 24-bit
    addressing, so the limit is no larger than 00100000.
4.  Systems which use SHADOWRAM would have recovered memory used as
    the DMA buffer, but we would have some trouble ensuring that
    that the entire buffer is physically contiguous memory.
5.  PC/XT systems are further limited by the 20-bit DMA controller
    so the DMA buffer must be within the first megabyte (00100000),
    and in practice within the first 640KB (000A0000).
|

	 public  DMA_MAX
DMA_MAX  dd	 @DMA_PA_ATHI	; Maximum DMA physical address
endif				; IF @OEM_DMA

	 public  INT07DP,MSW_PM
INT07DP  dq	 ?		; IDT entry for INT07
MSW_PM	 dw	 ?		; MSW for PM operation

	 public  NMIPORT,NMIENA,NMIDIS,NMIMASK
NMIPORT  dw	 @CMOS_CMD	; NMI clear I/O port
NMIENA	 db	 @CMOS_ENANMI	; ... enable value
NMIDIS	 db	 @CMOS_DISNMI	; ... disable value
NMIMASK  db	 mask $ATPAR	; ... clear mask

	 public  FILES_STR_LEN
FILES_STR_LEN	 db	0	; Length of FILES= structure in DOS

	 public  CPUREV
CPUREV	 db	 ?		; CPU revision # (P5 or later only)

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 FIND_PTE_SUB:near

	 extrn	 SET_PPL0STK:near
	 extrn	 LINPHYS:near
	 extrn	 WRAP_SWAP:near
	 extrn	 SET_GDT:near
	 extrn	 RESET_KEYB:near
if @OEM_XMS
	 extrn	 INIT_XMS:near
endif				; IF @OEM_XMS
if @OEM_EMS
	 extrn	 INT67:near
endif				; IF @OEM_EMS
	 extrn	 BIN2BASE:near

	 extrn	 SWAP_MAP:near
	 extrn	 SWAP_MEM:far
	 extrn	 XCHG_PTE:near

if DBG_TRACE
	 extrn	 INIT_TRACE:near
endif				; IF DBG_TRACE

	NPPROC	CALC_PnPSUM -- Re-calculate The PnP Checksum
	assume	ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Re-calculate the PnP checksum

On entry:

GS:EDI	==>	PnP struc in BIOS

|

	REGSAVE <eax,ecx,esi>	; Save registers

	movzx	ecx,AGROUP:[edi].PnP_LEN ; Get # bytes in the struc
	mov	ah,0		; Initialize the checksum
	mov	esi,edi 	; AGROUP:ESI ==> start of PnP struc
@@:
	lods	AGROUP:[esi].LO ; Get next byte
	add	ah,al		; Accumulate in checksum

	loop	@B		; Jump if more bytes to checksum

	sub	AGROUP:[edi].PnP_SUM,ah ; Save as new checksum

	REGREST <esi,ecx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_PnPSUM endp		; End CALC_PnPSUM procedure
	NPPROC	PATCH_PnP -- Patch Into PnP Struc In BIOS
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Patch into PnP struc in BIOS

|

	REGSAVE <eax,ebx,edi>	; Save registers

	movzx	edi,PnP_SEG	; Get the PnP struc segment in BIOS
	shl	edi,4-0 	; Convert from paras to bytes
	jz	short PATCH_PnP_EXIT ; Jump if not present

	mov	eax,LaPnP_PMCS	; Get patch value
	mov	ebx,OffPnP_PMCS ; Get offset to PnP_PMCS
	mov	AGROUP:[edi+ebx],eax ; Save back for DPMI clients

	mov	ebx,OffPnP_RMVEC ; Get offset to PnP_RMVEC
	mov	AGROUP:[edi+ebx].VSEG,seg PGROUP ; Save in PnP struc
	mov	AGROUP:[edi+ebx].VOFF,offset PGROUP:RESINT_PnP ; ...

	cmp	AGROUP:[edi].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short @F	; Jump if not (no PMDS in old struc)

	mov	eax,LaPnP_PMDS	; Get patch value
	mov	AGROUP:[edi].PnP_PMDS,eax ; Save back for DPMI clients
@@:

; Re-calculate the checksum

	call	CALC_PnPSUM	; Recalculate the PnP checksum at GS:EDI
PATCH_PnP_EXIT:
	REGREST <edi,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PATCH_PnP endp			; End PATCH_PnP procedure

ECODE	 ends			; End ECODE segment


ZDATA	 segment use16 para public 'zdata' ; Start ZDATA segment
	 assume  ds:PGROUP

	 extrn	 ZLDATA:byte

ZDATA	 ends			; End ZDATA segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MAXINT_VECS:dword
	 extrn	 NOLDINTS:abs

FDATA	 ends			; End FDATA segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

if @OEM_FLEXROM
	 extrn	 NFLEXROMINTS:abs
	 extrn	 FLEXROMINTS:tbyte
endif				; IF @OEM_FLEXROM

XDATA	 ends			; End XDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
YDATA	 ends			; End YDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 extrn	 DISP_CPDMSG:far

XCODE	 ends			; End XCODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

	 extrn	 MOVE_TAB:qword
	 extrn	 ERR_CODE:byte
	 extrn	 ERR_FLAG:byte
	 extrn	 ERR_CODE_VAL:word
	 extrn	 ERR_CODE_ADDR:dword

	 extrn	 MEM_MAP:byte,MEM_MAP_LEN:abs
	 extrn	 @XLAT_OTH:abs

	 extrn	 @ERR_MOV:abs
	 extrn	 @ERR_PRO:abs

if @OEM_WIN3
	 extrn	 LaEMM_Import_Ptr:dword
	 extrn	 CFG_SEG:word
endif				; IF @OEM_WIN3
	 extrn	 IOWRAP:byte
	 extrn	 VDSTAB_SEG:word

	 public  SAVE_ESP
SAVE_ESP dd	 ?		; Save area for return ESP

	 public  PICBASE
PICBASE  dw	 0870h		; (Master, Slave) PIC base values

	 public  MAXMOVE
MAXMOVE  dw	 7800h		; Maximum move segment

	 public  PGDT_PHI,PIDT_PHI,PIDT_LLO
PGDT_PHI DTR_STR <>		; Pointer to GDT in ext physical memory
PIDT_PHI DTR_STR <8*256-1,>	; ...	     IDT ...
PIDT_LLO DTR_STR <8*256-1,>	; ...	     IDT in low linear memory

if @OEM_DEBUG
	 public  CPDOFF,CPDCNT
CPDOFF	 dd	 ?		; CPD video buffer offset
CPDCNT	 dw	 0		; CPD line counter for pause

	 public  CPDREGTAB,CPDREGTAB_LEN
CPDREGTAB dw	 'di'           ; These entries *MUST* be in PUSHAD_STR order
	 dw	 'si'           ; and in lowercase
	 dw	 'bp'
	 dw	 'sp'
	 dw	 'bx'
	 dw	 'dx'
	 dw	 'cx'
	 dw	 'ax'
CPDREGTAB_LEN equ ($-CPDREGTAB)/(type CPDREGTAB) ; # entries in table
endif				; IF @OEM_DEBUG

NDATA	 ends			; End NDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 public  @QMAX_EVM_NCODE
@QMAX_EVM_NCODE:		; Mark module start in .MAP file

	 extrn	 SETIOPERM:near
	 extrn	 FILELOAD:near
if @OEM_BCF
	 extrn	 INIT_MIVT:near
endif				; IF @OEM_BCF

if @OEM_DEBUG
	 NPPROC  DISP_CPDMSG_PM -- Display CPD Message From PM
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display CPD message from PM

|

DISPCPD_STR struc

DISPCPD_ES dw	 ?		; Caller's ES
DISPCPD_DS dw	 ?		; ...	   DS
DISPCPD_EGP db	 (size PUSHAD_STR) dup (?) ; Caller's EGP registers
DISPCPD_FL dw	 ?		; ...	   FL
DISPCPD_IP dw	 ?		; ...	   IP
DISPCPD_OFF dw	 ?		; Offset in YGROUP of the message

DISPCPD_STR ends

	 pushf			; Save to ensure we're isolated

	 test	 CPD_FLAG,@CPD_MSG ; Allowing Checkpoint Debugging?
	 jz	 near ptr DISP_CPDMSG_PM_EXIT ; Jump if not

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es>	; Save for a moment

	 mov	 ebp,esp	; SS:EBP ==> DISPCPD_STR

; Note we use DTS_SS here as that selector is read-write
; into low linear memory where the NDATA variables we
; reference are located.

	 mov	 ax,DTE_SS	; Get PGROUP data selector at PL0
	 mov	 ds,ax		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

; Check for display buffer:  mono or color

	 mov	 edi,0B8000h	; Get base address of color display buffer

	 test	 NRD_FLAG,@NRD_CLR ; Izit color?
	 jnz	 short @F	; Jump if so

	 mov	 edi,0B0000h	; Get base address of mono display buffer
@@:
	 mov	 edx,edi	; Save starting address
	 add	 edi,CPDOFF	; Plus last offset

	 xor	 esi,esi	; Zero to use as dword
	 mov	 si,seg YGROUP	; Get segment of the text to display
	 shl	 esi,4-0	; Convert from paras to bytes

	 movzx	 eax,[ebp].DISPCPD_OFF ; Get offset in YGROUP of the message
	 add	 esi,eax	; Add to get offset in AGROUP of the message

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 cld			; String ops forwardly
DISP_CPDMSG_PM_NEXT:
	 lods	 AGROUP:[esi].LO ; Get next character from message

	 cmp	 al,EOS 	; Izit string terminator?
	 je	 near ptr DISP_CPDMSG_PM_DONE ; Jump if so

	 cmp	 al,CR		; Izit line ending?
	 je	 near ptr DISP_CPDMSG_PM_CR ; Jump if so

	 cmp	 al,LF		; Izit newline?
	 je	 short DISP_CPDMSG_PM_LF ; Jump if so

	 cmp	 al,'%'         ; Izit substitution?
	 je	 near ptr DISP_CPDMSG_PM_SUB ; Jump if so

	 cmp	 al,-1		; Izit time to pause?
	 je	 near ptr DISP_CPDMSG_PM_PAUSE ; Jump if so
DISP_CPDMSG_PM_SAVE:
	 mov	 ah,07h 	; Use white on black attribute
S32	 stos	 AGROUP:[edi].ELO ; Save in screen

	 jmp	 short DISP_CPDMSG_PM_NEXT ; Go around again

DISP_CPDMSG_PM_LF:

; If we're at the last row, scroll the screen up by one row

	 cmp	 CPDOFF,24*2*80 ; Izit the last row?
	 jb	 short DISP_CPDMSG_PM_NOSCROLL ; Jump if not

	 REGSAVE <esi,edi>	; Save for a moment

	 mov	 edi,edx	; ES:EDI ==> top of screen (destin)
	 lea	 esi,AGROUP:[edi+2*80] ; ES:ESI ==> line 1 of screen (source)
	 mov	 ecx,(24*2*80)/4 ; ECX = # dwords to scroll
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Move screen up one line

	 REGREST <edi,esi>	; Restore

; Blank the last line

	 push	 edi		; Save for a moment

	 mov	 ax,0720h	; Fill with this value
	 mov	 ecx,2*80	; Get length of one screen row
     rep stos	 AGROUP:[edi].ELO ; Blank the line

	 pop	 edi		; Restore

	 jmp	 short @F	; Check for time to pause

DISP_CPDMSG_PM_NOSCROLL:
	 add	 edi,2*80	; Skip to next line
@@:

; Check for time to pause

	 inc	 CPDCNT 	; Count in another line

	 cmp	 CPDCNT,@CPDCNT ; Izit time to pause?
	 jb	 short DISP_CPDMSG_PM_NOPAUSE ; Jump if not
DISP_CPDMSG_PM_PAUSE:
	 mov	 CPDCNT,0	; Reset for the next time

	CPDPMNP 'Pausing, press any key to continue...'

; Wait for a keystroke from the user by checking the 8042 output buffer

DISP_CPDMSG_PM_WAIT:
	 call	 PPI_K2S	; Wait for a response, returned in AL
	 jc	 short DISP_CPDMSG_PM_WAIT ; Jump if no response

	 push	 ax		; Save scancode for a moment
	 mov	 al,@EOI1	; Get specific EOI for IRQ1
	 out	 @ICR,al	; Tell the master 8259 about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 pop	 ax		; Restore scancode

; Distinguish pressing from releasing a keystroke
; Filter out releases

	 test	 al,@BIT7	; Izit press or release?
	 jnz	 short DISP_CPDMSG_PM_WAIT ; Jump if release

; Clear any pending scan code from the 8042 output buffer in case the
; keystroke generated multiple scan codes.

	 call	 WAITOBUF_CLR	; Wait for the output buffer to clear
DISP_CPDMSG_PM_NOPAUSE:
	 jmp	 DISP_CPDMSG_PM_NEXT ; Go around again

DISP_CPDMSG_PM_CR:
	 call	 ROUND_SCRDN_PM ; Round EDI down to the last screen row

	 jmp	 DISP_CPDMSG_PM_NEXT ; Go around again

DISP_CPDMSG_PM_SUB:
	 lods	 AGROUP:[esi].LO ; Get next character from message

	 cmp	 al,'%'         ; Izit real percent sign?
	 je	 near ptr DISP_CPDMSG_PM_SAVE ; Jump if so

	 mov	 ah,al		; Copy for later use
	 lods	 AGROUP:[esi].LO ; Get next character from message
	 or	 ax,2020h	; Convert to lowercase

	 cmp	 ax,'fl'        ; Izit FL?
	 mov	 bx,[ebp].DISPCPD_FL ; Assume so
	 je	 near ptr DISP_CPDMSG_PM_WORD1 ; Jump if so

	 cmp	 ax,'ip'        ; Izit IP?
	 mov	 bx,[ebp].DISPCPD_IP ; Assume so
	 je	 near ptr DISP_CPDMSG_PM_WORD1 ; Jump if so

	 cmp	 ax,'cs'        ; Izit CS?
	 mov	 bx,cs		; Assume so
	 je	 near ptr DISP_CPDMSG_PM_WORD1 ; Jump if so

	 cmp	 ax,'ds'        ; Izit DS?
	 mov	 bx,[ebp].DISPCPD_DS ; Assume so
	 je	 near ptr DISP_CPDMSG_PM_WORD1 ; Jump if so

	 cmp	 ax,'es'        ; Izit ES?
	 mov	 bx,[ebp].DISPCPD_ES ; Assume so
	 je	 near ptr DISP_CPDMSG_PM_WORD1 ; Jump if so

	 cmp	 ax,'fs'        ; Izit FS?
	 mov	 bx,fs		; Assume so
	 je	 near ptr DISP_CPDMSG_PM_WORD1 ; Jump if so

	 cmp	 ax,'gs'        ; Izit GS?
	 mov	 bx,gs		; Assume so
	 je	 near ptr DISP_CPDMSG_PM_WORD1 ; Jump if so

	 cmp	 ax,'ss'        ; Izit SS?
	 mov	 bx,ss		; Assume so
	 je	 near ptr DISP_CPDMSG_PM_WORD1 ; Jump if so

	 cmp	 ax,'cr'        ; Izit CRn?
	 je	 short DISP_CPDMSG_PM_CRn ; Jump if so

	 cmp	 ah,'e'         ; Izit extended register?
	 je	 near ptr DISP_CPDMSG_PM_EXTREG ; Jump if so

	 xor	 ebx,ebx	; Initialize index into CPD register table
	 mov	 cx,CPDREGTAB_LEN ; CX = # entries in ...
@@:
	 cmp	 ax,CPDREGTAB[bx] ; Check next entry
	 je	 near ptr DISP_CPDMSG_PM_WORD ; Jump if it's a match

	 add	 bx,type CPDREGTAB ; Skip to next entry

	 loop	 @B		; Jump if more entries

; No match:  Check for byte registers

	 cmp	 ax,'al'        ; Izit AL?
	 mov	 bx,PUSHAD_EAX.ELO.LO ; Assume so
	 je	 near ptr DISP_CPDMSG_PM_BYTE ; Jump if so

	 cmp	 ax,'ah'        ; Izit AH?
	 mov	 bx,PUSHAD_EAX.ELO.HI ; Assume so
	 je	 near ptr DISP_CPDMSG_PM_BYTE ; Jump if so

	 cmp	 ax,'bl'        ; Izit BL?
	 mov	 bx,PUSHAD_EBX.ELO.LO ; Assume so
	 je	 near ptr DISP_CPDMSG_PM_BYTE ; Jump if so

	 cmp	 ax,'bh'        ; Izit BH?
	 mov	 bx,PUSHAD_EBX.ELO.HI ; Assume so
	 je	 near ptr DISP_CPDMSG_PM_BYTE ; Jump if so

	 cmp	 ax,'cl'        ; Izit CL?
	 mov	 bx,PUSHAD_ECX.ELO.LO ; Assume so
	 je	 short DISP_CPDMSG_PM_BYTE ; Jump if so

	 cmp	 ax,'ch'        ; Izit CH?
	 mov	 bx,PUSHAD_ECX.ELO.HI ; Assume so
	 je	 short DISP_CPDMSG_PM_BYTE ; Jump if so

	 cmp	 ax,'dl'        ; Izit DL?
	 mov	 bx,PUSHAD_EDX.ELO.LO ; Assume so
	 je	 short DISP_CPDMSG_PM_BYTE ; Jump if so

	 cmp	 ax,'dh'        ; Izit DH?
	 mov	 bx,PUSHAD_EDX.ELO.HI ; Assume so
	 je	 short DISP_CPDMSG_PM_BYTE ; Jump if so

; No match:  ESI points past %xx

	 sub	 esi,2		; Back up to char after '%'
	 mov	 al,'%'         ; Display this one

	 jmp	 DISP_CPDMSG_PM_SAVE ; Join common code

DISP_CPDMSG_PM_CRn:
	 lods	 AGROUP:[esi].LO ; Get next character from message

	 cmp	 al,'0'         ; Izit CR0?
	 mov	 ebx,cr0	; Assume so
	 je	 short DISP_CPDMSG_PM_DWORD1 ; Jump if so

	 cmp	 al,'2'         ; Izit CR2?
	 mov	 ebx,cr2	; Assume so
	 je	 short DISP_CPDMSG_PM_DWORD1 ; Jump if so

	 cmp	 al,'3'         ; Izit CR3?
	 mov	 ebx,cr3	; Assume so
	 je	 short DISP_CPDMSG_PM_DWORD1 ; Jump if so

; No match:  ESI points past %xxx

	 sub	 esi,3		; Back up to char after '%'
	 mov	 al,'%'         ; Display this one

	 jmp	 DISP_CPDMSG_PM_SAVE ; Join common code

DISP_CPDMSG_PM_EXTREG:
	 mov	 ah,al		; Copy for later use
	 lods	 AGROUP:[esi].LO ; Get next character from message
	 or	 al,20h 	; Convert to lowercase

	 xor	 ebx,ebx	; Initialize index into CPD register table
	 mov	 cx,CPDREGTAB_LEN ; CX = # entries in ...
@@:
	 cmp	 ax,CPDREGTAB[bx] ; Check next entry
	 je	 short DISP_CPDMSG_PM_DWORD ; Jump if it's a match

	 add	 bx,type CPDREGTAB ; Skip to next entry

	 loop	 @B		; Jump if more entries

; No match:  ESI points past %xxx

	 sub	 esi,3		; Back up to char after '%'
	 mov	 al,'%'         ; Display this one

	 jmp	 DISP_CPDMSG_PM_SAVE ; Join common code

DISP_CPDMSG_PM_DWORD:
	 mov	 ebx,[ebp+ebx*2].DISPCPD_EGP.EDD ; Get the dword register value
DISP_CPDMSG_PM_DWORD1:
	 mov	 cx,8		; # nibbles to display

	 jmp	 short DISP_CPDMSG_PM_COM ; Join common code

DISP_CPDMSG_PM_WORD:
	 mov	 bx,[ebp+ebx*2].DISPCPD_EGP.ELO ; Get the word register value
DISP_CPDMSG_PM_WORD1:
	 shl	 ebx,16 	; Shift to high-order word
	 mov	 cx,4		; # nibbles to display

	 jmp	 short DISP_CPDMSG_PM_COM ; Join common code

DISP_CPDMSG_PM_BYTE:
	 mov	 bh,[ebp+ebx].DISPCPD_EGP.LO ; Get the byte register value
	 shl	 ebx,16 	; Shift to high-order word
	 mov	 cx,2		; # nibbles to display

	 jmp	 short DISP_CPDMSG_PM_COM ; Join common code

DISP_CPDMSG_PM_COM:
	 rol	 ebx,4		; Rotate next nibble to low-order
	 movzx	 eax,bl 	; Copy to format
	 and	 al,@NIB0	; Isolate the nibble
	 mov	 al,HEXTABLE[eax] ; Get the ASCII character
	 mov	 ah,07h 	; Use white on black attribute
S32	 stos	 AGROUP:[edi].ELO ; Save in screen

	 loop	 DISP_CPDMSG_PM_COM ; Jump if more nibbles to format and display

	 jmp	 DISP_CPDMSG_PM_NEXT ; Go around again

DISP_CPDMSG_PM_DONE:
	 sub	 edi,edx	; Less starting video base
	 mov	 CPDOFF,edi	; Save for next time

; Update the cursor position in the BIOS data area

	 mov	 ax,di		; Copy buffer offset

	 xor	 dx,dx		; Zero upper dword for division
	 mov	 cx,2*80	; Get # chars/attrs in a line
	 div	 cx		; Divide to get
				; AX = rows # (origin-0)
				; DX = cols # (origin-0)
	 mov	 dh,al		; (DH,DL) = (row,col)

	 xor	 ebx,ebx	; Zero to use as dword
	 mov	 bx,seg BIOSDATA ; Get segment of BIOS data area
	 shl	 ebx,4-0	; Convert from paras to bytes
	 add	 ebx,offset CURSOR_POSN[0] ; Plus offset of cursor
				; position save area
	 mov	 AGROUP:[ebx],dx ; Save for later use

	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 popad			; Restore all EGP registers
DISP_CPDMSG_PM_EXIT:
	 popf			; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CPDMSG_PM endp		; End DISP_CPDMSG_PM procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 NPPROC  GETIRR -- Read The IRR
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read the IRR.

On exit:

AL	 =	 IRR

|

	 mov	 al,@GETIRR	; Function to read IRR
	 out	 @ICR,al	; Tell the master 8259 about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@ICR	; Get the IRR

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETIRR	 endp			; End GETIRR procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 NPPROC  ROUND_SCRDN_PM -- Round Down to Last Screen Row
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Round down to last screen row

On entry:

EDX	 =	 starting video base (0B0000h or 0B8000h)
EDI	 =	 offset in AGROUP of current screen position

On exit:

EDI	 =	 value rounded down

|

	 REGSAVE <eax,ecx>	; Save registers

	 mov	 eax,edi	; Copy to skip to prev line
	 sub	 eax,edx	; Less starting video base

	 push	 edx		; Save for a moment

	 xor	 edx,edx	; Zero upper dword for division
	 mov	 ecx,2*80	; Get # chars/attrs in a line
	 div	 ecx		; Divide to get
				; EAX = rows # (origin-0)
				; EDX = cols # (origin-0) (ignored)
	 mul	 ecx		; Times # chars/attrs in a line
				; EDX:EAX = product
	 mov	 edi,eax	; Copy as starting offset in buffer

	 pop	 edx		; Restore

	 add	 edi,edx	; Add back in starting video base

	 REGREST <ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROUND_SCRDN_PM endp		; End ROUND_SCRDN_PM procedure
endif				; IF @OEM_DEBUG
	 FPPROC  ENTERPM -- Enter Protected Mode
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter VM 8086 mode

|

; Save stack pointer to restore later

	 mov	 SAVE_ESP,esp	; Save stack offset to restore later

	 PUSHD	 gs
	 PUSHD	 fs
	 PUSHD	 ds
	 PUSHD	 es
	 PUSHD	 ss		; Put return stack segment onto stack

	 push	 SAVE_ESP	; Put returning ESP onto the stack

; VM bit set, NT bit clear, IOPL at @VMIOPL

	 push	 dword ptr ((mask $VMHI) or (@VMIOPL shl $IOPL))

	 PUSHD	 cs		; Put return CS onto stack

	 push	 0		; Top half of EIP
	 push	 offset cs:FARPTR_LO ; Put return EIP onto stack

	 CPD	 'Calling SHADOW_ENABLE,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 SHADOW_ENABLE	; Set shadow RAM on CHIPSets to read-write

; Now that we have saved all data in memory (including the stack),
; move everything to high memory.  Note that we move only the static
; data.  If we moved PRGSIZE worth of data we might exceed 64KB.

	 lea	 si,MOVE_TAB	; ES:SI ==> block move descriptor tables
	 lea	 cx,ZLDATA[2-1] ; End of static code and data, rounded up
	 shr	 cx,1		; Convert from bytes to words

if @OEM_DEBUG
	 CHECK	 1		; Checkpoint
endif				; IF @OEM_DEBUG

	 CPD	 'Moving PGROUP to extended memory,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 REGSAVE <fs,gs>	; Save for a moment
	 mov	 ah,87h 	; Function code to move extended memory
	 int	 15h		; Request BIOS service
	 REGREST <gs,fs>	; Restore
				; No need to emulate this call

if @OEM_DEBUG
	 CHECK	 2		; Checkpoint
endif				; IF @OEM_DEBUG

	 cmp	 ah,0		; Any problems?
	 je	 short ENTERPM1A ; Jump if no error

if @OEM_SOFT
	 test	 CMD_FLAG,@CMD_XPARITY ; Was NOPARITY specified?
	 jz	 short @F	; Continue if not

	 cmp	 ah,1		; Was it a parity error?
	 je	 short ENTERPM1A ; Don't treat it as an error

@@:
endif				; IF @OEM_SOFT

	 mov	 ERR_CODE,ah	; Save error code
	 or	 ERR_FLAG,@ERR_MOV ; Mark as in error

	 jmp	 FARPTR_LO	; Join common exit code

ENTERPM1A:

; Read back the memory to ensure it's the same as was written out there

	 mov	 eax,MOVE_TAB.MDTE_ES.EDD[0] ; Get 1st half of destination
	 mov	 MOVE_TAB.MDTE_DS.EDD[0],eax ; Save as source
	 mov	 eax,MOVE_TAB.MDTE_ES.EDD[4] ; Get 2nd half of destination
	 mov	 MOVE_TAB.MDTE_DS.EDD[4],eax ; Save as source

	 movzx	 eax,MAPSEG_NXT ; Get segment of next available low DOS memory
	 shl	 eax,4-0	; Convert from paras to bytes

	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE01,ax ; Save low-order 16-bits
	 ror	 eax,16 	; Shift down high-order 16-bits
	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE2,al ; Save bits 16-23
	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE3,ah ; Save bits 24-31
	 rol	 eax,16 	; Restore

	 lea	 si,MOVE_TAB	; ES:SI ==> block move descriptor tables

; Because we might impinge on DOS, ensure that we don't move anything
; above segment MAXMOVE.  Above that point are the pseudo-buffers as well
; as CONFIG.SYS processing code.

	 movzx	 ebx,MAXMOVE	; Get maximum move address
	 shl	 ebx,4-0	; Convert from paras to bytes

	 lea	 ecx,ZLDATA[2-1] ; End of static code and data, rounded up
	 add	 ecx,eax	; Add to get ending linear address

	 cmp	 ecx,ebx	; Check against maximum
	 jbe	 short @F	; Jump if within range

	 mov	 ecx,ebx	; Use maximum
@@:
	 sub	 ecx,eax	; Subtract to get offset
	 jc	 short ENTERPM1C ; Jump if we're too far

	 push	 cx		; Save byte count over BIOS block move

	 shr	 cx,1		; Convert from bytes to words

if @OEM_DEBUG
	 CHECK	 3		; Checkpoint
endif				; IF @OEM_DEBUG

	 CPD	 'Moving PGROUP from extended memory,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 REGSAVE <fs,gs>	; Save for a moment
	 mov	 ah,87h 	; Function code to move extended memory
	 int	 15h		; Request BIOS service
	 REGREST <gs,fs>	; Restore
				; No need to emulate this call

	 pop	 cx		; Restore byte count

if @OEM_DEBUG
	 CHECK	 4		; Checkpoint
endif				; IF @OEM_DEBUG

	 cmp	 ah,0		; Any problems?
	 je	 short ENTERPM1B ; Jump if no error

if @OEM_SOFT
	 test	 CMD_FLAG,@CMD_XPARITY ; Was NOPARITY specified?
	 jz	 short @F	; Continue if not

	 cmp	 ah,1		; Was it a parity error?
	 je	 short ENTERPM1B ; Don't treat it as an error

@@:
endif				; IF @OEM_SOFT

	 mov	 ERR_CODE,ah	; Save error code
	 or	 ERR_FLAG,@ERR_MOV ; Mark as in error

	 jmp	 FARPTR_LO	; Join common exit code

ENTERPM1B:
	 push	 es		; Save for a moment

	 mov	 es,MAPSEG_NXT	; Get next available segment
	 assume  es:nothing	; Tell the assembler about it

	 lea	 si,LOWSTKZ	; DS:SI ==> start of original area after stack
	 mov	 di,si		; ES:DI ==> start of extended memory copy

; In case we're just on the edge where we copy less than MAXMOVE - base,
; the subtraction below might underflow.

	 sub	 cx,si		; Less size of the stack
	 jnc	 short @F	; Jump if there's something to compare

	 xor	 cx,cx		; Compare nothing
				; (note ZF=1 after the following SHR
				;  so the CMPSW will complete with
				;  ZF set correctly)
@@:
	 CPD	 'Comparing PGROUP for match,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 shr	 cx,1		; Convert from bytes to words
	 mov	 ERR_CODE_VAL,cx ; Save word count for error message

    repe cmpsw			; Compare 'em
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 je	 short ENTERPM1C ; All compared

	 mov	 ERR_CODE,08h	; Save error code
	 or	 ERR_FLAG,@ERR_MOV ; Mark as in error
	 sub	 ERR_CODE_VAL,cx ; Minus words left (uncounted)

	 jmp	 FARPTR_LO	; Join common exit code

ENTERPM1C:

; Move FGROUP code/data to extended memory

	 mov	 ax,seg FGROUP	; Get starting segment
	 mov	 edx,FGRBASE	; Get linear address of destin
	 mov	 ecx,FGRSIZE	; Get size of FGROUP
	 CPD	 'Moving FGROUP to extended memory,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'
	 call	 HOIST_GROUP	; Copy FGROUP to extended memory
	 jc	 short ENTERPM_HOISTERR ; Rejoin common error code

; Move IGROUP code/data to extended memory

	 mov	 ax,seg IGROUP	; Get starting segment
	 mov	 edx,IGRBASE	; Get linear address of destin
	 mov	 ecx,IGRSIZE	; Get size of IGROUP
	 CPD	 'Moving IGROUP to extended memory,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'
	 call	 HOIST_GROUP	; Copy IGROUP to extended memory
	 jc	 short ENTERPM_HOISTERR ; Rejoin common error code

; Move JGROUP code/data to extended memory

	 mov	 ax,seg JGROUP	; Get starting segment
	 mov	 edx,JGRBASE	; Get linear address of destin
	 mov	 ecx,JGRDSIZE	; Get size of JGROUP and DLGROUP
	 CPD	 'Moving JGROUP/DLGROUP to extended memory,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'
	 call	 HOIST_GROUP	; Copy JGROUP to extended memory
	 jnc	 short ENTERPM1X ; Rejoin common code if no error

ENTERPM_HOISTERR:
	 mov	 ERR_CODE,ah	; Save error code
	 or	 ERR_FLAG,@ERR_MOV ; Mark as in error

	 jmp	 FARPTR_LO	; Join common exit code

ENTERPM1X:

	 PUSHD	 0		; Ensure IOPL=NT=DF=0
	 popfd

if @OEM_DEBUG
	 CHECK	 5		; Checkpoint
endif				; IF @OEM_DEBUG

	 CPD	 'Entering PM,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 lea	 si,DESC_TAB	; ES:SI ==> descriptor tables
	 call	 EPM		; Use common subroutine to Enter Protected Mode
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it
	 jnc	 short ENTERPM2 ; Jump if we succeeded

	 mov	 ERR_CODE,ah	; Save error code
	 or	 ERR_FLAG,@ERR_PRO ; Mark as in error

	 jmp	 FARPTR_LO	; Join common exit code

	 public  ENTERPM2
ENTERPM2:
if @OEM_DEBUG
	 CHECK	 1		; Checkpoint
	 CPDPM	 'In PM,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'
endif				; IF @OEM_DEBUG

	 PUSHD	 0		; Ensure IOPL=NT=DF=0
	 popfd

; If we loaded any LOD modules directly into extended memory, we
; need to put them in their proper place now so when we exchange
; them below we eventually put them into fast memory

; Note that because the extended memory data isn't really there
; as yet, we need to use CS: overrides to reference data variables

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 cx,cs:LOADCOUNT ; Get # files to load
	 jcxz	 ENTERPM_XLOD	; Jump if none

	 movzx	 ebx,cs:LOADTABIND ; Get index to first load table entry
	 mov	 edx,cs:ERR_CODE_ADDR ; Get destination address
ENTERPM_LODNEXT:
	 test	 cs:LOADTAB.LOAD_FLG[bx],@LOAD_VSIZE ; Duzit support MD_VSIZE?
	 jz	 short ENTERPM_LODLOOP ; Jump if not

	 mov	 esi,cs:LOADTAB.LOAD_PHYS[bx] ; Get physical address of image

	 mov	 edi,cs:LOADTAB.LOAD_POFF[bx] ; Get offset in PGROUP
	 mov	 eax,edi	; Copy to use in LOAD_PHYS calc
	 add	 edi,cs:ERR_CODE_ADDR ; Plus destination address

; Because the code after ENTERPM_XLOD changes the LOD module base to
; LMLBASE (from ERR_CODE_ADDR), we use a different calculation to get
; the new physical address of the LOD module.  The address is saved
; in both low and extended memory in case it is referenced in both places.

	 add	 eax,cs:LMLBASE ; Plus new base

; Save new physical base in extended memory as well as low memory
; Extended memory is addressed through AGROUP (ES:) at EBX+EDX.
; Low memory is addressed through PGROUP (CS:) at BX.

	 test	 cs:LCL_FLAG,@LCL_LML ; Low memory load?
	 jnz	 short @F	; Jump if so

	 mov	 eax,edi	; Use actual physical destination
@@:
	 assume  es:PGROUP	; Tell a white lie
	 mov	 es:LOADTAB.LOAD_PHYS[ebx+edx],eax ; Save as new physical base
	 assume  es:AGROUP	; Retract nose
	 assume  ss:PGROUP	; Tell the assembler about it
	 mov	 ss:LOADTAB.LOAD_PHYS[bx],eax ; Save as new physical base
	 assume  ss:nothing	; Tell the assembler about it

	 push	 ecx		; Save loop counter

	 mov	 ecx,cs:LOADTAB.LOAD_SIZ[bx] ; Get the initialized file size
	 shr	 ecx,2-0	; Convert from bytes to dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Move to new home

	 pop	 ecx		; Restore
ENTERPM_LODLOOP:
	 add	 ebx,size LOAD_STR ; Skip to next structure entry

	 loop	 ENTERPM_LODNEXT ; Jump if more modules to check
ENTERPM_XLOD:

; If we're loading low, exchange the data values now

	 test	 cs:LCL_FLAG,@LCL_LML ; Low memory load?
	 jz	 short ENTERPM_XLML ; Jump if not

; Exchange PRGSIZE * 1KB of memory from PRGBASE in high physical memory
;				   to	LMLBASE

	 CPDPM	 'Exchanging PRGSIZE for LML,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 movzx	 ecx,cs:PRGSIZE ; Get size of PRG (in units of 1KB)
	 shl	 ecx,10-2	; Convert from 1KB to dwords

	 mov	 esi,cs:LMLBASE ; Get low memory load base
	 mov	 edi,cs:ERR_CODE_ADDR ; Get destination physical memory base
	 xor	 ebx,ebx	; Zero index into these items

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it
@@:
	 mov	 eax,AGROUP:[esi+ebx*4] ; Get source dword
	 xchg	 eax,AGROUP:[edi+ebx*4] ; Swap with destin dword
	 mov	 AGROUP:[esi+ebx*4],eax ; Save as new source dword

	 inc	 ebx		; Skip to next source/destin dword

	 loopd	 @B		; Jump if more dwords to exchange
ENTERPM_XLML:

if @OEM_DEBUG
	 CHECK	 2		; Checkpoint
endif				; IF @OEM_DEBUG

	 mov	 ax,DTE_DSXP	; Get physical extended memory data selector
	 mov	 ds,ax
	 mov	 es,ax
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

; Setup PDT selector into FS

	 push	 DTE_PDT	; Get PDT selector
	 pop	 fs		; Ensure FS points to the PDT
	 assume  fs:PDTGRP	; Tell the assembler about it

	 xor	 ax,ax		; Clear register
	 mov	 gs,ax		; Ensure GS is valid
	 assume  gs:nothing	; Tell the assembler about it


if @OEM_DEBUG
; =============================================================================

; Load requested files

	 CPDPM	 'Starting FILELOAD,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILELOAD	; Load 'em

	 test	 DB2_FLAG,@DB2_EVM ; Call debugger?
	 jz	 short ENTERPM_XDBG ; Not this time

	 SWAT	 PGROUP 	; Call the debugger
ENTERPM_XDBG:
	 CHECK	 3		; Checkpoint
endif				; IF @OEM_DEBUG
	CPDPM	'After FILELOAD,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'


; =============================================================================

	 push	 es		; Save for a moment

	 push	 ss		; Get low memory selector
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Check for Cyrix EMC87 chip

	 assume  ds:nothing	; Tell a white lie
	 test	 NRD_FLAG,@NRD_EMC87 ; Izit present?
	 assume  ds:PGROUP	; Retract nose
	 jz	 short ENTERPM_XCYRIX ; Jump if not

	 CPDPM	 'Checking for Cyrix EMC87 chip,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

; Note that we *MUST* execute the following instruction before we
; enable paging as we don't have a PTE to cover the address at 3GB.

; Note that MASM 5.10 doesn't correctly assemble an instruction with
; a 32-bit constant in the address field.

	 mov	 eax,0C0000AB0h ; Get address of Cyrix enable byte
	 mov	 AGROUP:[eax].LO,0 ; Mark as active
ENTERPM_XCYRIX:
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it


; =============================================================================
; Initialize TSSs
	CPDPM	'Initializing TSSs,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 mov	 edi,PVMTSS	; ES:EDI ==> TSSs
	 mov	 ecx,(@TSS_MAX*(type DPTSS_STR))/4 ; ECX # dwords in TSSs
	 xor	 eax,eax	; Fill with this
     rep stos	 PGROUP:[edi].EDD ; Clear to fill value

	 mov	 cx,@TSS_MAX	; Get # TSSs we have
	 mov	 ebx,PVMTSS	; Get offset in PGROUP of 1st TSS
	 mov	 si,VM2PM_TSS	; Get selector of the 1st TSS

	 CPDPM	 'Filling TSSs,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'
ENTERPM_NEXTTSS:

; This TSS will never be called from PL1 or PL2,
; so we can ignore their stacks.

	 mov	 eax,PPL0STK_MAX ; Get top of stack
	 mov	 PGROUP:[ebx].TSS_ESP0,eax ; Save in TSS

	 mov	 PGROUP:[ebx].TSS_SS0,DTE_DS ; Save stack selector
if @OEM_DPMI
	 mov	 PGROUP:[ebx].TSS_LDT,0 ; Save LDT selector
endif				; IF @OEM_DPMI
	 mov	 PGROUP:[ebx].TSS_LINK,-1 ; Mark TSS as available

	 mov	 eax,PIOBIT	; Get offset in PGROUP of I/O bit map
	 sub	 eax,ebx	; Less base address
	 mov	 PGROUP:[ebx].TSS_IOMAP,ax ; Save offset to I/O bit map

; Note we zero the DPTSS-specific fields when we first use the TSS

	 mov	 PGROUP:[ebx].DPTSS_SEL,si ; Save the selector value

	 add	 si,2*(type DESC_STR) ; Skip over LDT selector to next TSS selector
	 add	 ebx,type DPTSS_STR ; Skip to next TSS

	 loop	 ENTERPM_NEXTTSS ; Jump if more TSSs to initialize

	CPDPM	'Initializing First TSS,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

; The first TSS is initialized differently as it is used when there
; are no DPMI clients active.  The HPDA to which it points is at OVR_HPDA.

	 mov	 ebx,PVMTSS	; Get offset in PGROUP of 1st TSS

	 mov	 PGROUP:[ebx].DPTSS_OLDPM,-1 ; Zap starting linear address
	 mov	 PGROUP:[ebx].DPTSS_LPMSTK_FVEC.FOFF,-1 ; ...
	 mov	 PGROUP:[ebx].DPTSS_LPMSTK_FVEC.FSEL,-1 ; ...
	 mov	 PGROUP:[ebx].DPTSS_LPMSTK_CNT,-1 ; ...
	 mov	 PGROUP:[ebx].DPTSS_LPMBASE,-1 ; ...
if @OEM_DPMI
	 mov	 PGROUP:[ebx].TSS_LDT,DTE_DPMILDT ; Save LDT selector
endif				; IF @OEM_DPMI
	 mov	 eax,LaSIRBCUR	; Get current linear address
	 mov	 PGROUP:[ebx].DPTSS_LaSIRBCUR,eax ; Save for later use

	 lea	 eax,OVR_HPDA	; Get offset of pseudo-HPDA (/16)
	 shr	 ax,4-0 	; Convert from bytes to paras
	 add	 ax,seg PGROUP	; Plus segment of low DOS memory

	 mov	 PGROUP:[ebx].DPTSS_HPDASEG,ax ; Save for later use
	 mov	 PGROUP:[ebx].DPTSS_VMSTKSEG,ax ; ...
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 PGROUP:[ebx].DPTSS_LaHPDA,eax ; Save for later use

; If we're on a P5 or later, initialize the Software Interrupt
; Re-direction Bitmap

	mov	eax,CPUFET_FLAG ; Get CPU feature flag
	CPDPM	'Testing for SIRB,  CS|IP=%CS|%IP  DS=%DS  ES=%ES, FET=%EAX'

	 test	 CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	 jz	 near ptr ENTERPM_XP5 ; Jump if not

	CPDPM	'Initializing SIRB,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 mov	 edi,PIOBIT	; Get offset in PGROUP of I/O bit map
	 mov	 ecx,256/8	; Get length of SIR bitmap in bytes
	 sub	 edi,ecx	; Back off to start of the SIR bitmap
	 mov	 al,0		; Initialize to this
     rep stos	 PGROUP:[edi].LO ; Initialize it
ENTERPM_XP5:

; Note that the following code *MUST* execute *AFTER* API loads
; in case we load a 386 emulator.  We're assuming that any 387
; emulator also emulates floating point instructions from VM
; so we can save the current MSW into the MSW for VM operation.

	 smsw	 ax		; Get MSW after API loads
	 and	 ax,mask $EM	; Isolate EM bit

	 test	 LCL_FLAG,@LCL_NDPIN ; Is NDP installed?
	 jz	 short @F	; Jump if not

	 or	 ax,mask $MP	; Mark as enabled for this client
@@:
	 mov	 MSW_PM,ax	; Save MSW for PM operation
	 mov	 PGROUP:[ebx].DPTSS_MSW,ax ; Save MSW for VM operation

	 mov	 eax,IDT_DESC.EDQLO[07h*(type IDT_DESC)] ; Get low-order dword
	 mov	 PGROUP:[ebx].DPTSS_IDT07.EDQLO,eax ; Save for later use

	 mov	 eax,IDT_DESC.EDQHI[07h*(type IDT_DESC)] ; Get high-order dword
	 mov	 PGROUP:[ebx].DPTSS_IDT07.EDQHI,eax ; Save for later use

if @OEM_DPMI
	 test	 LCL_FLAG,@LCL_DPMI ; Load module DPMI services requested?
	 jz	 short ENTERPM_XDPMI ; Jump if not

COMMENT|

Setup MAX's HPDA -- note that the following fields
are not filled in and are not supported:

DPTSS_DYN	 no dynamic save area
DPTSS_DTA_FVEC	 no DTA

|

; Save the initial current buffer offset and size

	 CPDPM	 'Initializing HPDA for load module,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 mov	 ax,HPDABUF_OFF ; Get the offset
	 mov	 PGROUP:[ebx].DPTSS_VMBUFOFF,ax ; Save for later use

	 mov	 ax,HPDABUF_SIZ ; Get the size
	 mov	 PGROUP:[ebx].DPTSS_VMBUFSIZ,ax ; Save for later use

; Save the offset of the current stack top

	 mov	 ax,HPDASTK_TOP ; Get offset of top of HPDA stack
	 mov	 PGROUP:[ebx].DPTSS_VMSTKOFF,ax ; Save for later use

	 sub	 ax,HPDASTK_SIZ ; Less size of HPDA stack
	 mov	 PGROUP:[ebx].DPTSS_VMSTKBOT,ax ; Save for later use
ENTERPM_XDPMI:
endif				; IF @OEM_DPMI

; Set the LDTR to a known value

	mov	ax,PGROUP:[ebx].TSS_LDT ; Get LDTR for CPDPM
	CPDPM	'Initializing LDTR,  CS|IP=%CS|%IP  DS=%DS  ES=%ES  LDTR=%AX'

	 lldt	 PGROUP:[ebx].TSS_LDT ; Set LDTR

; Setup related stack variables

	CPDPM	'Calling SET_PPL0STK,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 SET_PPL0STK	; Set PPL0STK... pointers

; =============================================================================

; Initialize I/O bit permission map to zero

	 CPDPM	 'Initializing I/O bit permission map,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 mov	 edi,PIOBIT	; Get offset in PGROUP of I/O bit map
	 xor	 ecx,ecx	; Zero entire register
	 mov	 cx,@IOMAP	; ECX = size of bit map in bytes
	 xor	 al,al		; Fill with this value
     rep stos	 PGROUP:[edi].LO ; Consider it zeroed
	 mov	 al,cs:IOWRAP	; Also include the strange "terminating" byte
S32	 stos	 PGROUP:[edi].LO

	 CPDPM	 'Calling SETIOPERM,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 SETIOPERM	; Set I/O permission bits

if @OEM_DEBUG
	 CHECK	 4		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Initialize the Page Descriptor Table

	 CPDPM	 'Calling FILL_PDT,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_PDT	; Fill it in

if @OEM_DEBUG
	 CHECK	 5		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

if @OEM_EMS

; Fill in PHYS2SEG table

	 CPDPM	 'Calling FILL_PHYS2SEG,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_PHYS2SEG	; Fill it in
endif				; IF @OEM_EMS

if @OEM_DEBUG
	 CHECK	 7		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

if @OEM_EMS

; Fill in SEG2PHYS table

	 CPDPM	 'Calling FILL_SEG2PHYS,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_SEG2PHYS	; Fill it in
endif				; IF @OEM_EMS

if @OEM_DEBUG
	 CHECK	 8		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Swap PRG memory for faster memory than available in extended RAM
; if available

	 test	 LCL_FLAG,@LCL_LML ; Low memory load?
	 jz	 near ptr ENTERPM_LML1 ; Not this time

	 CPDPM	 'Initiating LML,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

; Setup descriptor for DTE_LML

	 movzx	 eax,PRGSIZE	; Get size of PRG (in units of 1KB)
	 shl	 eax,10-0	; Convert from 1KB to bytes

	 push	 eax		; Pass size of segment
	 mov	 eax,LMLBASE	; Get low memory load base
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_LML	; Pass descriptor to set
	 call	 SET_GDT	; Set the GDT to EAX base

; Swap PDT entries for PRG

	 CPDPM	 'Calling SWAP_PRG,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 SWAP_PRG	; Swap 'em

; Swap low memory load PTEs

	 CPDPM	 'Calling SWAP_LML,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 SWAP_LML	; Swap 'em
ENTERPM_LML1:

; Fill the Page Directory Table

	 CPDPM	 'Calling FILL_PDIR,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_PDIR

if @OEM_DEBUG
	 CHECK	 13		; Checkpoint
endif				; IF @OEM_DEBUG

; Tell the 386 about paging -- put LCL_CR3 into CR3

	 mov	 eax,LCL_CR3	 ; Put LCL_CR3 in a location recognized by CPDPM

	 CPDPM	 'Calling PAGE_ON,  CS|IP=%CS|%IP  DS=%DS  ES=%ES  CR0=%CR0  CR3=%EAX'

	 call	 PAGE_ON	; Turn on paging
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 CPDPM	 'Paging enabled,  CS|IP=%CS|%IP  DS=%DS  ES=%ES  CR0=%CR0  CR3=%CR3'
if @OEM_DEBUG
	 CHECK	 14		; Checkpoint
endif				; IF @OEM_DEBUG

; =============================================================================
; Now that paging is enabled (so the code selector for INT 12h is valid),
; we can enable the MCE bit in CR4 if we're on a P5 or later CPU

	 test	 CPUFET_FLAG,mask $CPUFET_MCE ; Is MCE supported?
	 jz	 short @F	; Jump if not

	 CPDPM	 'Enabling CR4.MCE,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 MOVSPR  eax,cr4	; Get CPU extensions register
	 or	 eax,mask $MCE	; Enable the Machine Check Exception
	 MOVSPR  cr4,eax	; Tell the CPU about it
@@:

; =============================================================================

; Copy previous VDS table to extended memory
; Note:  This routine *MUST* be called before SWAP_DMA
;	 in case we need the previous VDS table

	 CPDPM	 'Calling COPY_VDS,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 COPY_VDS	; Copy it

; =============================================================================

if @OEM_DMA

; Swap DMA buffer PTEs

	 CPDPM	 'Calling SWAP_DMA,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 SWAP_DMA	; Swap 'em
endif				; IF @OEM_DMA

; =============================================================================

; Swap MAPBASE entries if using shadow RAM

	 CPDPM	 'Calling SWAP_MAPBASE,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 SWAP_MAPBASE	; Swap 'em

if @OEM_DEBUG
	 CHECK	 6		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Exchange the PTEs starting at LOWOFF with PPDTLOW and mark them
; as not physical memory.
; The PTEs at LOWOFF get mapped in during INIT_DATA from PDTCNV.

	 CPDPM	 'Calling FILL_LOWBASE,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_LOWBASE	; Fill it in

if @OEM_DEBUG
	 CHECK	 15		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Swap the pages beginning at MAPBASE with the entries in MAPTAB

	 CPDPM	 'Calling FILL_MAPBASE,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_MAPBASE	; Fill it in

if @OEM_DEBUG
	 CHECK	 17		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Initialize the interrupt vector table if BCF in effect
; If any errors occur, @NRD_BCFERR will be set so we can display the
; bad news on return to V86 mode.

if @OEM_BCF
	 CPDPM	 'Calling INIT_MIVT,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 INIT_MIVT	; Initialize it
endif				; IF @OEM_BCF


; =============================================================================

; Fill in the pages in OVRBASE to begin where entries in the
; MCSTAB table indicate

	 CPDPM	 'Calling FILL_OVRBASE,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_OVRBASE	; Fill it in

if @OEM_DEBUG
	 CHECK	 16		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Modify the PTEs for the new VGA BIOS if Swapped

if @OEM_FLEXROM
	 CPDPM	 'Calling FILL_VGASWAP,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_VGASWAP	; Fill it in
endif				; IF @OEM_FLEXROM


; =============================================================================

if @OEM_DEBUG
	 CHECK	 18		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Copy CFGFILE data to extended memory

	 CPDPM	 'Calling COPY_CFG,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 COPY_CFG	; Copy it

; =============================================================================

; If we've been requested to do so, swap memory at segment 0000h
; with (presumably) faster memory at 1MB

	 CPDPM	 'Calling SWAP_MEM,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 FICALL  PGROUP:SWAP_MEM,DTE_CS2 ; Swap slow low memory with fast high memory

if @OEM_DEBUG
	 CHECK	 19		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Initialize the WRAPTAB for the 1MB wrap as well as PDTCVD
; This routine *MUST* be run after SWAP_MEM

	 CPDPM	 'Calling FILL_WRAPTAB,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_WRAPTAB	; Fill it up

if @OEM_DEBUG
	 CHECK	 20		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Map the first 64KB of memory above the 1MB limit to the first 64KB
; Note we can't use WRAP_ENABLE because it assumes SS is in high memory

;;;;;;;; and	 GLB_FLAG,not (@GLB_1MB or @GLB_XWRP) ; Ensure clear
	 and	 GLB_FLAG,not @GLB_1MB ; Ensure clear

	 test	 GLB_FLAG,@GLB_X1MB ; Izit allowed?
	 jnz	 short ENTERPM_X1MB ; Not this time

	 pushf			; Save flags

	 cli			; Disable interrupts

	 CPDPM	 'Calling WRAP_SWAP,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 WRAP_SWAP	; Swap the 1MB wrap table entries (note ES=PGROUP)

	 or	 GLB_FLAG,@GLB_1MB ; Mark as enabled

	 popf			; Restore flags
ENTERPM_X1MB:
if @OEM_DEBUG
	 CHECK	 21		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Fill in PDTCNV table

	 CPDPM	 'Calling FILL_PDTCNV,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_PDTCNV	; Fill it in

if @OEM_DEBUG
	 CHECK	 22		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Fill in PDTSCR table

	 CPDPM	 'Calling FILL_PDTSCR,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 FILL_PDTSCR	; Fill it in

if @OEM_DEBUG
	 CHECK	 23		; Checkpoint
endif				; IF @OEM_DEBUG


; =============================================================================

; Fill in PDTPnPBIOS table and other variables

	CPDPM	'Calling FILL_PDTPnPBIOS,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	call	FILL_PDTPnPBIOS ; Fill it in


; =============================================================================

; Initialize the various data areas

	 CPDPM	 'Calling INIT_DATA,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 FICALL  JGROUP:INIT_DATA,DTE_CSJG ; Initialize 'em
if @OEM_XMS
	 CPDPM	 'Calling INIT_XMS,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 INIT_XMS	; Initialize XMS areas
endif				; IF @OEM_XMS
if @OEM_DPMI
	 CPDPM	 'Calling INIT_DPMITAB,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 INIT_DPMITAB	; Initialize DPMI tables
endif				; IF @OEM_DPMI

	 CPDPM	 'Calling INIT_SIRBCUR,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 INIT_SIRBCUR	; Initialize SIRBCUR table
if @OEM_DEBUG
	 CHECK	 24		; Checkpoint
endif				; IF @OEM_DEBUG

	 CPDPM	 'Zeroing PIOTRAP,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 mov	 edi,PIOTRAP	; Get the offset in PGROUP of I/O trap strucs
	 mov	 ecx,@IOTRAP_MAX*(type IOTRAP_STR) ; Get # bytes in table
	 xor	 al,al		; Fill with this value
     rep stos	 PGROUP:[edi].LO ; Consider it zeroed


; =============================================================================

; Initialize the trace table

if DBG_TRACE
	 CPDPM	 'Calling INIT_TRACE,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 call	 INIT_TRACE	; Initialize it
endif				; IF DBG_TRACE


; =============================================================================

; Tell the 386 about our TSS

	 mov	 ax,DTE_TSS	; Get 1st TSS selector
	 ltr	 ax		; Tell 386 about it

if @OEM_DEBUG
	 CHECK	 25		; Checkpoint
endif				; IF @OEM_DEBUG

; Clear any parity errors which might have occurred

	 CPDPM	 'Calling ENABLE_NMI,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 and	 GLB_FLAG,not @GLB_NMI
	 call	 ENABLE_NMI	; Enable NMI, clear the parity latches

if @OEM_DEBUG
	 CHECK	 26		; Checkpoint
endif				; IF @OEM_DEBUG

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 gs		; Address it
	 assume  gs:AGROUP	; Tell the assembler about it

if @OEM_VDS

; Set DMA services enabled bit

	 assume  gs:BIOSDATA	; Tell the assembler about it
	 or	 VDS[400h],@VDS_ENA ; Mark as enabled
	 assume  gs:AGROUP	; Tell the assembler about it
endif				; IF @OEM_VDS

; Return to original routine and enable VM 8086 mode

	 CPDPM	 'Copying RM IDT to MAXINT_VECS,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 assume  gs:INTVEC	; Tell the assembler about it

	 mov	 es,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  es:FGROUP	; Tell the assembler about it

	 lea	 si,INT00_VEC[00h*type INT00_VEC] ; GS:SI ==> int vectors
	 lea	 di,MAXINT_VECS ; ES:DI ==> local copies of int vectors

; Set CX to the number of dwords to move

	 mov	 cx,NOLDINTS	; # interrupt vectors to save
S16  rep movs	 <MAXINT_VECS[di],INT00_VEC[si]> ; Save original interrupt vectors

	 CPDPM	 'Entering VM 8086 mode,  CS|IP=%CS|%IP  DS=%DS  ES=%ES'

; Because we can run out of stack in low DOS, we might have overwritten
; static data down there such as the name of the VxD.  However, the copy
; of this data in extended memory is untouched, so we copy it so as to
; refresh the data.

	push	ss		; Get our stack selector
	pop	es		; Address it
	assume	es:PGROUP	; Tell the assembler about it

	lea	esi,DEVDRV	; DS:ESI ==> data in extended memory
	lea	edi,DEVDRV	; ES:EDI ==> ...     low DOS memory
	mov	ecx,esp 	; Get lowest save point

S32 rep movs	<DEVDRV.LO[edi],ds:[esi].LO> ; Copy to refresh

	 iretd			; Return to original program in VM mode

	 public  FARPTR_LO
FARPTR_LO:

COMMENT|

In order to support the DOS CONFIG.SYS option of HIMEM /DOS /NOXMS,
we *MUST NOT* use any DOS calls until we have installed our own XMS
handler into low DOS memory which is done in INTR_SET.

|

; Tell the assembler about the ASSUMEs

	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

if @OEM_DEBUG
	 CPD	 'In VM 8086 mode,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'
endif				; IF @OEM_DEBUG

; Re-initialize segment registers

	 mov	 ax,cs
	 mov	 ds,ax
	 mov	 es,ax
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 mov	 ss,ax
	 mov	 esp,SAVE_ESP

	 xor	 ax,ax		; Ensure FS is invalid
	 mov	 fs,ax		; Ensure set to null
	 assume  fs:nothing	; Tell the assembler about it
	 mov	 gs,ax		; Ensure set to null
	 assume  gs:nothing	; Tell the assembler about it

; If we're initially OFF (or AUTO inactive), return to real mode

	 test	 GLB_FLAG,@GLB_ON ; Check the ON bit
	 jnz	 short FARPTR_LO1 ; Jump if we're to stay that way

	 CPD	 'Calling @EMM2_GOREAL,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 push	 PLOWSTKZ	; Save current offset
	 mov	 PLOWSTKZ,sp	; Protect us so far

	 mov	 al,0		; Function code to exit unconditionally
	 EMMOUT  @EMM2_GOREAL	; Exit protected mode

	 pop	 PLOWSTKZ	; Restore
FARPTR_LO1:

; Restore original master and slave interrupt masks

	 CPD	 'Calling ENABLE_IMR,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 ENABLE_IMR	; Enable the 8259 interrupt mask register

; Reset the keyboard if requested to do so

	 CPD	 'Calling RESET_KEYB,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 RESET_KEYB	; Ensure the keyboard is reset

	 sti			; Enable interrupts

	 CPD	 'Calling ENABLE_NMI,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 ENABLE_NMI	; Enable NMI, clear the parity latches

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENTERPM  endp			; End ENTERPM procedure
	 NPPROC  HOIST_GROUP -- Copy Group to Extended Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy Group to Extended Memory.

On entry:

AX	 =	 Real mode segment address of group
EDX	 ==>	 Destination within program storage in extended memory
CX	 =	 Length of segment in bytes

On exit:

AH	 =	 Error code from BIOS block move
CF	 =	 set if AH != 0

|

	 lea	 si,MOVE_TAB	; ES:SI ==> block move descriptor tables

	 movzx	 eax,ax 	; Zero high-order half to use as DWORD
	 shl	 eax,4-0	; Convert from paras to bytes

	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE01,ax ; Save low-order 16-bits
	 ror	 eax,16 	; Shift down high-order 16-bits
	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE2,al ; Save bits 16-23
	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE3,ah ; Save bits 24-31
;;;;;;;; rol	 eax,16 	; Restore

	 sub	 edx,PRGBASE	; Less the program's linear address
				; to get relative address in PGROUP

; Destination address is relative address plus original physical address

	 add	 edx,ERR_CODE_ADDR ; Plus the appropriate physical address

	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE01,dx ; Save low-order 16-bits
	 ror	 edx,16 	; Shift down high-order 16-bits
	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE2,dl ; Save bits 16-23
	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE3,dh ; Save bits 24-31
;;;;;;;; rol	 edx,16 	; Restore

	 dec	 cx		; Convert from length to limit
	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM0,cx ; Save as source limit
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM0,cx ; ...	   destin
	 add	 cx,1+1 	; Round up to next word boundary
	 shr	 cx,1-0 	; Convert from bytes to words

	 REGSAVE <fs,gs>	; Save for a moment
	 mov	 ah,87h 	; Function code to move extended memory
	 int	 15h		; Request BIOS service
	 REGREST <gs,fs>	; Restore
				; No need to emulate this call

	 or	 ah,ah		; Any problems?
	 jz	 short HOISTGRP_XIT ; Rejoin exit code if not error

if @OEM_SOFT
	 test	 CMD_FLAG,@CMD_XPARITY ; Was NOPARITY specified?
	 jz	 short @F	; Continue if not

	 cmp	 ah,1		; Was it a parity error?
	 je	 short HOISTGRP_XIT ; Don't treat it as an error if so

@@:
	 stc			; Indicate an error occurred
endif				; IF @OEM_SOFT

HOISTGRP_XIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HOIST_GROUP endp		; End HOIST_GROUP procedure
	 NPPROC  EPM -- Enter Protected Mode
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common routine to enter Protected Mode.

On entry:

ES:SI	 ==>	 Global Descriptor Table

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise
AH	 =	 error code if CF=1
BX	 =	 clobbered
CX	 =	 clobbered by some BIOSs
FS	 =	 0
GS	 =	 0

IF	 =	 0
NMI	 =	 disabled

|

	 xor	 ax,ax		; A convenient zero

	 mov	 fs,ax		; Ensure valid
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 gs,ax		; Ensure valid
	 assume  gs:nothing	; Tell the assembler about it

	 call	 DISABLE_IMR	; Disable the 8259 interrupt mask register
	 call	 DISABLE_NMI	; Disable NMI

if @OEM_DEBUG

; Test for @DB3_EPM set in DB3_FLAG (force entry to protected mode via
; INT15PROT emulation rather than trying via INT 15h first).

	 test	 DB3_FLAG,@DB3_EPM ; Do we force the issue?
	 jnz	 short EPM_EMU	; Jump if so
endif				; IF @OEM_DEBUG

; Because of a bug in certain ValuePoint system BIOSes, we need to
; point DS to a harmless location so the BIOS can write into memory
; without destroying any of our data.  The bug is in the BIOS code
; which executes function 89h and, probably because of incorrect
; hand-coding of an assembler instruction, executes the bytes 00 00.
; These bytes correspond to the assembler instruction ADD [BX+SI],AL.
; BX on entry must be 0870h and SI is the offset in ES of the GDT.
; The workaround used here is to set DS to F000 so that the ADD is
; harmless.  Whatta kludge!

	 mov	 ax,0F000h	; Get segment of the system BIOS
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 bx,PICBASE	; Initialize hardware interrupts here
	 mov	 ah,89h 	; Function code to enter protected mode
	 int	 15h		; Request BIOS service
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it
	 cli			; Disable interrupts

; Because some stupid BIOS vendors don't correctly set either
; the CPU flags or AH, we just test the $PE bit in the MSW to
; determine whether or not we are in protected mode

	 smsw	 cx		; Get machine status word

	 test	 cx,mask $PE	; Check the Protect Enable bit
	 jnz	 short EPM_CLC	; Jump if we are in protected mode

	 cmp	 ah,80h 	; Check for function not supported
	 je	 short EPM_EMU	; Yes, so we must emulate it

	 cmp	 ah,86h 	; Check for function not supported
	 je	 short EPM_EMU	; Yes, so we must emulate it

	 cmp	 ah,89h 	; Check for function not supported
	 je	 short EPM_EMU	; Yes, so we must emulate it

	 stc			; Indicate we failed, reason in AH

	 jmp	 short EPM_EXIT ; Join common exit code

	 assume  ds:nothing	; Tell the assembler about it

EPM_EMU:
	 mov	 bx, PICBASE	; Reload BX -- either 1) a failed call
				; to Int 15 AH=89 trashed it or 2) we
				; came here through DEBUG=EPM and BX
				; has not been set.
	 call	 near ptr INT15PROT ; Enter protected mode
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

; Return in protected mode with interrupts and NMI disabled

EPM_CLC:
	 xor	 ax,ax		; A convenient zero

	 mov	 fs,ax		; Ensure valid
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 gs,ax		; Ensure valid
	 assume  gs:nothing	; Tell the assembler about it

	 clc			; Indicate we are in protected mode
EPM_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EPM	 endp			; End EPM procedure
	 NPPROC  FILL_PDT -- Fill In PDT
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Fill in PDT.

Also fill in LCL_CR3, PaDIR2, PaOPTE1, DMA_SWAP, and DMA_PA
with the correct physical addresses.

|

	 REGSAVE <eax,ecx,edx,esi,edi,es> ; Save registers

	 push	 DTE_PDT	; Get our PDT selector
	 pop	 es		; Address it
	 assume  es:PDTGRP	; Tell the assembler about it

	 xor	 edi,edi	; ES:EDI ==> table start (on 4KB boundary)

; Fill in all of the PTEs except for shadow RAM

	 mov	 ecx,TOTSIZE	; Get total amount of extended memory
	 sub	 ecx,GORSIZE	; Less size of gore region
	 movzx	 eax,SHDSIZE	; Get size of shadow RAM
	 sub	 ecx,eax	; Less size of shadow RAM
	 shr	 ecx,12-10	; Convert from 1KB to 4KB
	 add	 ecx,1*1024/4	; Plus # PTEs for first megabyte = 1MB/4KB
	 mov	 edx,ecx	; Copy # PTEs to fill in
	 mov	 eax,@PTE_URP	; Mark as User/Read-write/Present
	 call	 FILL_PDT_SUB	; Fill in ECX PTEs with EAX at ES:EDI

; Fill in PTEs for shadow RAM

	 movzx	 ecx,SHDCNT	; Get # entries in shadow RAM structure
	 jecxz	 FILL_PDT_GOR	; Nothing there

	 lea	 si,SHDTAB	; DS:SI ==> shadow RAM structure
	 mov	 PPDTSHD,edi	; Save as offset in PDT of shadow RAM
FILL_PDT_NEXT1:
	 push	 ecx		; Save for a moment

	 movzx	 ecx,PGROUP:[si].SHD_ESIZE ; Get size of this block in 1KB
	 shr	 ecx,12-10	; Convert from 1KB to 4KB
	 add	 edx,ecx	; Plus # PTEs to fill in
	 mov	 eax,PGROUP:[si].SHD_EBASE ; Get physical address of shadow RAM
	 or	 ax,@PTE_URP	; Mark as User/Read-write/Present
	 call	 FILL_PDT_SUB	; Fill in ECX PTEs with EAX at ES:EDI

	 pop	 ecx		; Restore

	 add	 si,size SHD_STR ; Skip to next entry

	 loop	 FILL_PDT_NEXT1 ; Jump if more shadow RAM entries

; Copy PRGBASE PTEs up GORSIZE/4 entries

FILL_PDT_GOR:
	 push	 edi		; Save for a moment

	 movzx	 ecx,PRGSIZE	; Get size of PRG region
	 shr	 ecx,12-10	; Convert from 1KB to 4KB
	 sub	 edi,4		; Back off to last PTE
	 mov	 esi,edi	; FS:ESI ==> source (end of current PTEs)
	 mov	 eax,GORSIZE	; Get size of gore
	 add	 edi,eax	; Skip to destination point
	 shr	 eax,12-10	; Convert from 1KB to 4KB
	 add	 edx,eax	; Plus # PTEs to fill in

	 std			; Move backwards
S32  rep movs	 <es:[edi].EDD,fs:[esi].EDD> ; Move 'em up
	 cld			; Restore direction flag

	 pop	 edi		; Restore

; Fill in the remainder of the PDT

	 mov	 eax,GORSIZE	; Get size of gore region in 1KB
	 add	 edi,eax	; Skip to destination point
	 mov	 ecx,edi	; Copy offset

; The following instruction ordering is important to return a zero
; if the memory is a multiple of 4MB

	 sub	 ecx,4*1024	; Subtract from 4KB
	 neg	 ecx		; ...to get remainder
	 and	 ecx,4*1024-1	; ...modulo 4KB

	 shr	 ecx,2-0	; Convert from bytes to dwords

	 mov	 eax,edx	; Copy # PTEs filled in so far
	 shl	 eax,12-0	; Convert from 4KB to bytes
	 or	 ax,@PTE_URP	; Mark as User/Read-write/Present
	 call	 FILL_PDT_SUB	; Fill in ECX PTEs with EAX at ES:EDI

if @OEM_XMS
	 mov	 esi,PPDTCVD	; Get offset in PDT of CHECK_VDISK pseudo-1MB
	 mov	 eax,CON1MB	; Get physical address of 1MB
	 or	 ax,@PTE_URP	; Mark as User/Read-Write/Present
	 mov	 OFFPDT[esi],eax ; Save in PDT
endif				; IF @OEM_XMS

; Set cache Disable bit for PTEs in RAM= statements

	 lea	 si,MEM_MAP	; CS:SI ==> memory map
	 mov	 cx,MEM_MAP_LEN ; CX = # 512-byte entries
FILL_PDT_NEXT2:
	 lods	 cs:[si].LO	; Get next byte
				; Note use CS: to get low memory copy in NDATA
	 cmp	 al,@XLAT_OTH	; Izit other RAM?
	 jne	 short FILL_PDT_LOOP ; Jump if not

	 mov	 di,si		; Copy offset
	 sub	 di,1+offset ds:MEM_MAP ; Convert to origin-0

; On some systems (esp. with Intel Overdrive CPUs),
; if we set the Cache Disable bit, the contents of the
; ROM can change out from underneath us.  This has
; happened on a COMPAQ 466 XL system which works with a
; 486DX or 486DX2-66 CPU, but fails with an Overdrive
; CPU (CPUID = 1532h).	The workaround is not to set the
; Cache Disable bit on ROM residues -- that is, ROMs which
; don't end on a 4KB boundary which we then mark the residue
; as Other RAM.

; COMPAQ (Mike Milleson 713-518-0317) says this is an
; incompatibility in the bridge chips on their 466 XL
; with the Intel Overdrive CPU.  I suspect that the hardware
; bug is in the COMPAQ system, rather than the Intel CPU.

	test	CM4_FLAG,@CM4_NOCRR ; Is NOCRR in effect?
	jz	short @F	; Jump if not

	test	di,(4*1024/512)-1 ; Izit on a 4KB boundary?
	jnz	short FILL_PDT_LOOP ; Jump if not
@@:
	 and	 di,not ((4*1024/512)-1) ; Round down to 4KB boundary
	 shr	 di,(12-2)-9	; Convert from 512-byte to 4KB in dwords

	 or	 OFFPDT[di],mask $PTE_CD ; Mark as Cache Disabled
FILL_PDT_LOOP:
	 loop	 FILL_PDT_NEXT2 ; Jump if more entries to check

; Fill in local variables

	 call	 SET_PHYS	; Set various physical addresses

	 REGREST <es,edi,esi,edx,ecx,eax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_PDT endp			; End FILL_PDT procedure
	 NPPROC  FILL_PDT_SUB -- Subroutine to FILL_PDT
	 assume  ds:PGROUP,es:PDTGRP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in PTEs

On entry:

EAX	 =	 next PTE to use, +CON4KB each time thereafter
ECX	 =	 # PTEs to fill in
ES:EDI	 ==>	 save area for first PTE

On exit:

EAX	 =	 next PTE to use (updated)
ES:EDI	 ==>	 save area for next PTE

|

	 jecxz	 FILL_PDT_SUB_EXIT ; None to fill in

	 push	 ecx		; Save register
FILL_PDT_SUB_NEXT:
S32	 stos	 OFFPDT[edi]	; Save as new PTE

	 add	 eax,CON4KB	; Skip to next page

	 loopd	 FILL_PDT_SUB_NEXT ; Jump if more PTEs to fill in

	 pop	 ecx		; Restore
FILL_PDT_SUB_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_PDT_SUB endp		; End FILL_PDT_SUB procedure
	 NPPROC  SET_PHYS -- Set Various Physical Addresses
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set various physical addresses.

Fill in LCL_CR3, PaDIR2, PaOPTE, DMA_SWAP, and DMA_PA
with the correct physical addresses.

|

	 REGSAVE <eax,ebx,es>	; Save registers

	 push	 DTE_PDT	; Get our PDT selector
	 pop	 es		; Address it
	 assume  es:PDTGRP	; Tell the assembler about it

	 mov	 ebx,LaCR3	; Get linear address (multiple of 4KB)
	 shr	 ebx,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 eax,OFFPDT[ebx] ; Get corresponding physical address
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame address
	 mov	 LCL_CR3,eax	; Save as CR3
	 assume  ds:nothing,ss:PGROUP ; Tell the assembler about it
	 mov	 LCL_CR3,eax	; ... in low DOS, too
	 assume  ds:PGROUP,ss:nothing ; Tell the assembler about it
if @OEM_WIN3
	 mov	 WIN3_REF_DATA.REF_CR3,eax ; Save in structure for VxD
	 assume  ds:nothing,ss:PGROUP ; Tell the assembler about it
	 mov	 WIN3_REF_DATA.REF_CR3,eax ; ... in low DOS, too
	 assume  ds:PGROUP,ss:nothing ; Tell the assembler about it
endif				; IF @OEM_WIN3

	 push	 cx		; Save for a moment

	 mov	 cx,@TSS_MAX	; Get # TSSs we have
	 mov	 ebx,PVMTSS	; Get offset in PGROUP of 1st TSS
@@:
	 mov	 PGROUP:[ebx].TSS_CR3,eax ; Save current CR3 in TSS

	 add	 ebx,type DPTSS_STR ; Skip to next TSS

	 loop	 @B		; Jump if more TSSs to initialize

	 pop	 cx		; Restore

; Set the high-order bit of LCL_CR3 if DEBUG=CR3 set

	 test	 DBG_FLAG,@DBG_CR3 ; Set high-order bit of CR3?
	 jz	 short SET_PHYS_CR3 ; No

	 or	 LCL_CR3,@BIT31 ; Set high-order bit
SET_PHYS_CR3:
	 mov	 ebx,LaDIR2	; Get linear address (multiple of 4KB)
	 shr	 ebx,12-0	; Convert from bytes to 4KB
	 mov	 eax,OFFPDT[ebx*4] ; Get corresponding physical address
	 shl	 ebx,12-(12-2)	; Convert from 4KB to 4KB in dwords
	 mov	 PDTDIR2,ebx	; Save for later use
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame address
	 mov	 PaDIR2,eax	; Save as physical address

	 mov	 ebx,PPDTPDIR	; Get offset in PDT of PDIR PTE
	 or	 eax,@PTE_URP	; Mark as User/Read-write/Present
	 mov	 OFFPDT[ebx],eax ; Save for later use

; Because we update the PTE at this location when switching maps
; via AMRS, we need to know whether or not it is within the first PDE

	 cmp	 ebx,1000h	; Izit beyond 4MB?
	 jb	 short SET_PHYS_X4MB ; No

	 or	 LCL_FLAG,@LCL_4MB ; Mark as beyond 4MB
SET_PHYS_X4MB:
	 mov	 ebx,LaOPTE	; Get linear address (multiple of 4KB)
	 shr	 ebx,12-0	; Convert from bytes to 4KB

	 mov	 eax,OFFPDT[ebx*size PDT_PTE] ; Get corresponding physical address
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame address
	 mov	 PaOPTE1,eax	; Save physical address of 1st overflow PTE

if @OEM_WIN3
	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSHI	; Get high DOS memory descriptor
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ebx,cs:LaEMM_Import_Ptr ; Get linear EMM Import Data Pointer
	 shr	 ebx,12-0	; Convert from bytes to 4KB
	 mov	 eax,OFFPDT[ebx*4] ; Get corresponding physical address
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame address
	 movzx	 ebx,cs:LaEMM_Import_Ptr.ELO ; Get linear EMM Import Data Pointer
	 and	 bx,not (mask $PTE_FRM) ; Isolate 4KB offset address
	 add	 eax,ebx	; Add to get 32-bit physical address

	 mov	 EMM_Import_Ptr,eax ; Save as physical EMM Import Data Pointer

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
endif				; IF @OEM_WIN3

if @OEM_DMA
	 mov	 ebx,DMA_LA	; Get linear address (multiple of 4KB)
	 shr	 ebx,12-0	; Convert from bytes to 4KB
	 mov	 eax,OFFPDT[ebx*4] ; Get corresponding physical address
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame address
	 mov	 DMA_PA,eax	; Save as physical address

; Start DMA swaps at the new physical address at 1MB, unless we're on an XT
; which has a 20-bit DMA controller only

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jnz	 short @F	; Yes, DMA_SWAP already set

	 mov	 ebx,PPDT1MB	; Get offset to start of 1MB in the PDT
	 mov	 ax,OFFPDT.EHI[ebx] ; Get high-order word
	 mov	 DMA_SWAP,ax	; Save for DMA swapping
@@:
endif				; IF @OEM_DMA
	 REGREST <es,ebx,eax>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_PHYS endp			; End SET_PHYS procedure
	 NPPROC  SWAP_LML -- Swap LML PTEs
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

If we're doing low memory load and it's above LOWOFF,
swap the PTEs for LOWBASE, OVRBASE, and MAPBASE.

|

	 REGSAVE <ebx,ecx,esi,edi> ; Save registers

	 mov	 ecx,LMLTOP	; Get top of LML load area in 1KB

	 cmp	 ecx,LOWOFF	; Check against top of low DOS memory in 1KB
	 jbe	 near ptr SWAP_LML_EXIT ; It's within the DOS area

	 mov	 ebx,-1 	; Set to identity element for minimum

; Exchange LOWSIZE PTEs at PPDTLOW and PPDTLML-(PPDTPRG-PPDTLOW)

	 mov	 cx,LOWSIZE	; Get size of low DOS memory fill

	 cmp	 cx,0		; Check sign
	 jle	 short SWAP_LML_XLO ; None this time

	 shr	 cx,12-10	; Convert from 1KB to 4KB

	 mov	 esi,PPDTLOW	; Get offset of LOWBASE in PDT
	 mov	 edi,PPDTLML	; Get offset of LMLBASE in PDT
	 sub	 edi,PPDTPRG	; Less start of PRGBASE
	 add	 edi,esi	; Plus start of LOWBASE

	 cmp	 edi,PPDT1MB	; Ensure not too small
	 jb	 short SWAP_LML_XLO ; It's too small

	 cmp	 edi,ebx	; Check against previous value
	 jae	 short @F	; It's out of range

	 mov	 ebx,edi	; Save as new low point
@@:
	 call	 XCHG_PTE	; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE

	 loop	 @B		; Jump if more PTEs to swap
SWAP_LML_XLO:

; Exchange OVRSIZE PTEs at PPDTOVR and PPDTLML-(PPDTPRG-PPDTOVR)

	 mov	 cx,OVRSIZE	; Get size of high DOS memory fill
	 shr	 cx,12-10	; Convert from 1KB to 4KB
	 jz	 short SWAP_LML_XHI ; None this time

	 mov	 esi,PPDTOVR	; Get offset of OVRBASE in PDT
	 mov	 edi,PPDTLML	; Get offset of LMLBASE in PDT
	 sub	 edi,PPDTPRG	; Less start of PRGBASE
	 add	 edi,esi	; Plus start of OVRBASE

	 cmp	 edi,PPDT1MB	; Ensure not too small
	 jb	 short SWAP_LML_XHI ; It's too small

	 cmp	 edi,ebx	; Check against previous value
	 jae	 short @F	; It's out of range

	 mov	 ebx,edi	; Save as new low point
@@:
	 call	 XCHG_PTE	; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE

	 loop	 @B		; Jump if more PTEs to swap
SWAP_LML_XHI:

; Exchange MAPSIZE PTEs at PPDTMAP and PPDTLML-(PPDTPRG-PPDTMAP)
; unless we're on a shadow RAM system which needs the PTEs mapped
; one-to-one.

;;;;;;;; test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
;;;;;;;; jnz	 short SWAP_LML_XRM ; Yes, don't move the PTEs

	 mov	 cx,MAPSIZE	; Get size of ROM fill
	 shr	 cx,12-10	; Convert from 1KB to 4KB
	 jz	 short SWAP_LML_XRM ; None this time

	 mov	 esi,PPDTMAP	; Get offset of MAPBASE in PDT
	 mov	 edi,PPDTLML	; Get offset of LMLBASE in PDT
	 sub	 edi,PPDTPRG	; Less start of PRGBASE
	 add	 edi,esi	; Plus start of MAPBASE

	 cmp	 edi,PPDT1MB	; Ensure not too small
	 jb	 short SWAP_LML_XRM ; It's too small

	 cmp	 edi,ebx	; Check against previous value
	 jae	 short @F	; It's out of range

	 mov	 ebx,edi	; Save as new low point
@@:
	 call	 XCHG_PTE	; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE

	 loop	 @B		; Jump if more PTEs to swap
SWAP_LML_XRM:

; Ensure PPDTSHD is smaller than EBX

	 cmp	 ebx,PPDTSHD	; Check against PPDTSHD
	 jae	 short @F	; It's out of range

	 mov	 PPDTSHD,ebx	; Save as smaller PPDTSHD
@@:

; Ensure SWPSIZE is smaller than EBX

;;;;;;;; sh?	 ebx,(12-2)-10	; Convert from 4KB in dwords to 1KB

	 cmp	 ebx,0FFFFh	; Izit bigger than 16-bits?
	 ja	 short @F	; Jump if so

	 cmp	 bx,SWPSIZE	; Check against SWPSIZE
	 jae	 short @F	; It's out of range

	 mov	 SWPSIZE,bx	; Save as smaller SWPSIZE
@@:
	 call	 SET_PHYS	; Set various physical addresses
SWAP_LML_EXIT:
	 REGREST <edi,esi,ecx,ebx> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_LML endp			; End SWAP_LML procedure
if @OEM_DMA
	 NPPROC  SWAP_DMA -- Swap DMA Buffer PTEs
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Make room for the DMA buffer

DMA buffer constraints:
* Must be located below MAX_DMA (which is machine dependent)
* Must be in physically contiguous memory
* Must not be between @DMA_PA_ATLO (640 KB) and 1 MB
* If (DMASIZE >  64 KB) then DMA_BUFFER location must be on a 128 KB boundry
* If (DMASIZE <= 64 KB) then DMA_BUFFER location must lie within a 64KB boundary
* On MCA machines, there are no DMA buffer boundary restrictions
* On EISA machines, there are no DMA buffer boundary restrictions
  assuming we use the extended (32-bit) addresssing (which we do).

If the physical address of the DMA buffer does not meet these criteria,
then we must swap the PTEs for DTE_DMA and some PTEs which are below
DMA_MAX and follow the restrictions listed above.

This routine *MUST* be called after SWAP_PRG.
This routine *MUST* be called after PAGING is enabled

|

	 pushad 		; Save all EGP registers

	 test	 CMD_FLAG,@CMD_XDM ; Doing DMA?
	 jnz	 near ptr SWAP_DMA_EXIT ; Not this time

; If we are recovering BIM memory from AST, COMPAQ, or TOP384,
; then we'll have to limit the highest DMA address to 16 MB - 128 KB

	 test	 I15_FLAG,(@I15_CPQ or @I15_AST) ; Recovering shadow memory?
	 jz	 short @F	; Jump if not

	 mov	 DMA_MAX,@DMA_PA_BIMHI ; Set new stricter limit
@@:

; On EISA systems, the DMA buffer can reside anywhere in 4 GB

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Is this an EISA style DMA machine?
	 jz	 short @F	; Jump if not

	 mov	 DMA_MAX,@DMA_PA_EISA ; Set new looser limit
@@:

; Determine potential starting location (linear address) of DMA buffer

	 mov	 edi,PPDTDMA	; Get start of DMA buffer in PDT

; Determine length of DMA buffer

	 mov	 cx,DMASIZE	; Get size of DMA buffer in 1KB (/4KB)
	 shr	 cx,12-10	; Convert from 1KB to 4KB (# PTEs to check)
	 mov	 dx,cx		; Save count to restore later

; There are two ways to search for a DMA buffer physical address
; 1) SWAP_DMA_LOW:	Called if > 16 MB in system
; 2) SWAP_DMA_HIGH:	Called if < 16 MB in system

	 cmp	 edi,((16*1024*1024/(4*1024))*4) ; Is the buffer above 16 MB?
	 jb	 short @F	; Jump if not (under 16 MB)

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Is this an EISA style DMA machine?
	 jnz	 short @F	; Jump if so

	 call	 SWAP_DMA_LOW	; Find home for DMA buffer
				; Start search at 1.1MB
				; Search upwards until address is found

	 jmp	 short SWAP_DMA_COM ; Join common code

@@:
	 call	 SWAP_DMA_HIGH	; Find home for DMA buffer
				; Start search at PPDTDMA
				; Continue search at just under PRGBASE
				; Search downward until address is found

SWAP_DMA_COM:

; EAX = Physical address of last page of DMA buffer
; EDI = Offset in PDT of DMA source

	 mov	 PPDTDMAP,edi	; Save as offset in PDT of DMA source

; If the physical DMA buffer is below 640KB, we must force ON

	 cmp	 eax,@DMA_PA_ATLO ; Check for below 640KB
	 ja	 short SWAP_DMA_XCNV ; Not this time

; Set the flags in high physical memory

	 mov	 eax,EXFSIZE	; Get EXTSIZE if forced ON
	 mov	 EXTSIZE,eax	; Save as actual EXTSIZE
	 or	 GLB_FLAG,@GLB_FORC or @GLB_ON ; Mark as forced ON state
	 and	 GLB_FLAG,not @GLB_AUTO ; ...and not AUTO

if @OEM_SYS ne @OEMSYS_ILIM and @OEM_SYS ne @OEMSYS_LHY
; Re-format the new EXTSIZE into MSG_EAVL

	 REGSAVE <di,es>	; Save for a moment

	 lea	 di,MSG_EAVL-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 push	 DTE_SS 	; Get low memory data selector with 64KB access
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_EAVL-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 REGREST <es,di>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it
endif				; IF @OEM_SYS ne @OEMSYS_ILIM and @OEM_SYS ne @OEMSYS_LHY

; Set the flags in low linear memory

	 push	 es		; Save for a moment

	 mov	 ds,SEL_DSHI	; Get high DOS memory descriptor
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 EXTSIZE,eax	; Save as actual EXTSIZE
	 or	 GLB_FLAG,@GLB_FORC or @GLB_ON ; Mark as forced ON state
	 and	 GLB_FLAG,not @GLB_AUTO ; ...and not AUTO

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
SWAP_DMA_XCNV:

; Check to see if the buffer has the same source and destin address.
; If so, then there is nothing to swap.

	 mov	 edi,PPDTDMAP	; Get offset in PDT of DMA source

	 cmp	 edi,PPDTDMA	; Izit equal to the DMA destin?
	 je	 short SWAP_DMA_SETPHYS ; Jump if so (nothing to swap)

; We have to swap memory in order to find a home for the DMA buffer
; First: Copy the contents at the low memory location into the
;	 high memory location.
; Second: Swap the PTEs.

; FS:EDI ==> offset within PDT of the lowest PTE

	 REGSAVE <edi,ds,es>	; Save registers

	 movzx	 ecx,DMASIZE	; Get size of DMA buffer in 1KB (/4KB)
	 shl	 ecx,10-2	; Convert from 1KB to dwords
	 mov	 esi,edi	; Copy as source register
	 shl	 esi,(12-2)-0	; Convert from 4KB in dwords to bytes

	 push	 DTE_D4GB	; Get low memory data selector
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it

	 push	 DTE_DMA	; Get DMA buffer selector
	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it
	 xor	 edi,edi	; ES:EDI ==> DMA buffer

	 cld			; String ops forwardly
S32  rep movs	 <es:[edi].EDD,AGROUP:[esi].EDD> ; Copy low memory to DMA buffer

	 REGREST <es,ds,edi>	; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

; Swap the PTEs

	 mov	 esi,PPDTDMA	; FS:ESI ==> DMA buffer PTEs (destin)
				; FS:EDI ==> low memory PTEs (source)
	 mov	 cx,DMASIZE	; Get size of DMA buffer in 1KB (/4KB)
	 shr	 cx,12-10	; Convert from 1KB to 4KB (# PTEs to swap)
SWAP_DMA_XCHG:
	 call	 XCHG_PTE	; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE

	 loop	 SWAP_DMA_XCHG	; Jump if more PTEs to swap

SWAP_DMA_SETPHYS:
	 call	 SET_PHYS	; Set various physical addresses

SWAP_DMA_EXIT:
	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_DMA endp			; End SWAP_DMA procedure
	 NPPROC  SWAP_DMA_LOW -- SWAP_DMA_LOW procedure
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT |

Find a home for the DMA buffer.
* Start at 1.1 MB and search up until we find a home
* If MS-DOS 7, we start at 1.11MB

On entry:
CX,DX	=	Size of DMA buffer in pages
EDI	=	Start of DMA buffer in PDT
EBP	=	Start of PRGBASE in PDT

On exit:
EAX	=	Physical address of last page of DMA buffer
EDI	=	Offset in PDT of DMA source

|

	 REGSAVE <ebx,cx,esi,ebp> ; Save registers

	 mov	 edi,PPDT1W1MB	; Get next available low PTE (at 1.1/1.11MB)
	 mov	 ebp,edi	; Store as next PTE to check

; Determine potential starting location (physical address) of DMA buffer

SWAP_DMA_LOW_NEXT:
	 mov	 esi,edi	; Copy starting offset
	 mov	 ebx,OFFPDT[esi] ; Seed with initial PTE
	 and	 bx,mask $PTE_FRM ; Isolate frame (get physical address)

; Determine if the block is contiguous and meets the boundary conditions
; and is below DMA_MAX

	 call	 SWAP_DMA_SUB	; Does the block pass all our tests?
	 jc	 short SWAP_DMA_LOW_LOOP ; Jump if not

; EAX = Physical address of last page of DMA buffer
; EDI = Offset in PDT of DMA source

; We know that the buffer is above 1 MB, so we don't have to check
; for DMA between 640 KB and 1 MB

	 jmp	 short SWAP_DMA_LOW_EXIT ; Join common exit code

; We've already determined that the buffer can not reside at the linear
; address whose PDT offset is in DI.  Back up to the previous page and
; try again.

SWAP_DMA_LOW_LOOP:
	 mov	 cx,dx		; Restore page count (of DMA buffer)
	 add	 ebp,4		; Skip to next 4KB page
	 mov	 edi,ebp	; Get next PDT offset to search for

	 jmp	 short SWAP_DMA_LOW_NEXT ; Go around again

SWAP_DMA_LOW_EXIT:
	 REGREST <ebp,esi,cx,ebx> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
SWAP_DMA_LOW	 endp			; End SWAP_DMA_LOW procedure
	 NPPROC  SWAP_DMA_HIGH -- SWAP_DMA_HIGH procedure
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT |

Find a home for the DMA buffer.
* Start search at PPDTDMA
* Continue search at just under PRGBASE and search down until we find a home

On entry:
CX,DX	=	Size of DMA buffer in pages
EDI	=	Start of DMA buffer in PDT
EBP	=	Start of PRGBASE in PDT

On exit:
EAX	=	Physical address of last page of DMA buffer
EDI	=	Offset in PDT of DMA source

|

	 REGSAVE <ebx,cx,esi,ebp> ; Save registers

; In case the DMA buffer has to be swapped with lower memory, determine the
; linear address where we'll start the search

	 mov	 ebp,PPDTPRG	; Get the start of PRGBASE in PDT
	 movzx	 eax,DMASIZE	; Get size of DMA buffer in KB
;;;;;;;; shr	 ax,(12-10)	; Convert from KB to 4 KB pages
;;;;;;;; shl	 ax,(2-0)	; Convert from 4 KB pages in dwords to bytes
	 sub	 ebp,eax	; Get highest possible start of swap buffer
	 add	 ebp,4		; Add to compensate for later subtraction
				; ... at SWAP_DMA_HIGH_LOOP

; Determine potential starting location (physical address) of DMA buffer

SWAP_DMA_HIGH_NEXT:
	 mov	 esi,edi	; Copy starting offset
	 mov	 ebx,OFFPDT[esi] ; Seed with initial PTE
	 and	 bx,mask $PTE_FRM ; Isolate frame (get physical address)

; Determine if the block is contiguous and meets the boundary conditions
; and is below DMA_MAX

	 call	 SWAP_DMA_SUB	; Determine if block is contiguous
	 jc	 short SWAP_DMA_HIGH_LOOP ; Jump if not

; EAX = Physical address of last page of DMA buffer
; EDI = Offset in PDT of DMA source

; If we're below 1MB, ensure it's below @DMA_PA_ATLO
; Ensure that the DMA buffer doesn't span the address range from
; @DMA_PA_ATLO to CON1MB.

; This means that the last physical address in the buffer must be
; below @DMA_PA_ATLO, and the first physical address in the buffer
; must be at or above CON1MB.

	 cmp	 eax,@DMA_PA_ATLO ; Check last address against limit
	 jb	 short SWAP_DMA_HIGH_EXIT ; It's below the range to avoid

	 movzx	 ebx,DMASIZE	; Get size of DMA buffer in 1KB (/4KB)
	 shl	 ebx,10-0	; Convert from 1KB to bytes
	 sub	 eax,ebx	; Subtract from last physical address in buffer
	 add	 eax,CON4KB	; Plus size of one page to get first ...

	 cmp	 eax,CON1MB	; Check against 1MB
	 jae	 short SWAP_DMA_HIGH_EXIT ; It's not below, all PTEs are valid

; We've already determined that the buffer can not reside at the linear
; address whose PDT offset is in DI.  Back up to the previous page and
; try again.

SWAP_DMA_HIGH_LOOP:
	 mov	 cx,dx		; Restore page count (of DMA buffer)
	 sub	 ebp,4		; Back off to previous 4KB page (CF significant)
	 mov	 edi,ebp	; Get next PDT offset to search for
	 jnc	 short SWAP_DMA_HIGH_NEXT ; Go around again

	 int	 03h		; We could not find any memory to swap

SWAP_DMA_HIGH_EXIT:
	 REGREST <ebp,esi,cx,ebx> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
SWAP_DMA_HIGH	 endp			; End SWAP_DMA_HIGH procedure
	 NPPROC  SWAP_DMA_SUB -- Subroutine to SWAP_DMA
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT |

Determine if the proposed DMA address is suitable for a DMA buffer
* Check for machine specific boundary conditions
* Verify that buffer is physically contiguous

On entry:
EBX	=	Physical address of proposed DMA buffer
CX	=	Size of DMA buffer in pages
ESI	=	Start of DMA buffer in PDT

On exit:
CF	=	0 if the DMA is OK at current location
		1 if not
EAX	=	Physical address of last page in buffer (if CF=0)
		Undefined (if CF=1)

|

	 REGSAVE <ebx,cx,esi>	; Save registers

; Ensure physical start of block meets boundary conditions

	 call	 CHECK_DMA_BOUNDARY ; Ensure all boundary conditions are met
	 jc	 short SWAP_DMA_SUB_STC ; Jump if boundary is no good

	 or	 bx,@PTE_URP	; Ensure we swap with URP entries

; Ensure all pages are physically contiguous

SWAP_DMA_SUB_NEXT_PTE:
	 lods	 OFFPDT[esi]	; Get next PTE from table into EAX

; Isolate frame, absent, and URP bits

	 and	 ax,(mask $PTE_FRM) or (mask $PTE_AV1) or @PTE_URP

; Ensure page is consecutive
; EAX = entry from table
; EBX = pseudo entry obtained by adding 4 KB at end of loop

	 cmp	 eax,ebx	; Must be the same
	 jne	 short SWAP_DMA_SUB_STC ; Jump if not

	 add	 ebx,CON4KB	; Skip to next consecutive PTE

	 loop	 SWAP_DMA_SUB_NEXT_PTE ; Jump if more PTEs to check

	 and	 ax,mask $PTE_FRM ; Isolate the frame

	 cmp	 eax,DMA_MAX	; Check against maximum physical address
	 jae	 short SWAP_DMA_SUB_STC ; Jump if buffer is too high in memory

	 clc			; Indicate buffer is fine at current location

	 jmp	 short SWAP_DMA_SUB_EXIT ; Join common exit code

SWAP_DMA_SUB_STC:
	 stc			; Indicate buffer is not OK

SWAP_DMA_SUB_EXIT:
	 REGREST <esi,cx,ebx>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
SWAP_DMA_SUB	 endp			; End SWAP_DMA_SUB procedure
	 NPPROC  CHECK_DMA_BOUNDARY -- Verify DMA boundary address
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT |

Verify that the proposed DMA buffer is at an appropriate
address for the given machine

The boundary conditions are:
* If there's a previous VDS table, use the translated physical address
  to check boundary conditions.
* If (DMASIZE >  64 KB) then DMA_BUFFER location must be on a 128 KB boundry
* If (DMASIZE <= 64 KB) then DMA_BUFFER location must lie within a 64KB boundary
* On MCA machines, there are no DMA buffer boundary restrictions
* On EISA machines, there are no DMA buffer boundary restrictions
  assuming we use the extended (32-bit) addresssing (which we do).

Note: All boundary checks are performed on physical memory (not linear)

On entry:
EBX	=	Physical address of start of proposed DMA buffer

On exit:
CF	=	0 if buffer is fine at this address
		1 if not

|

	 REGSAVE <eax,ebx>	; Save physical address

; Verify that the proposed buffer is in contiguous memory,
; if there is a previous VDS mapping

	 cmp	 PVDSTAB,0	; Is there a previous VDS table?
	 je	 short CHECK_DMA_BOUNDARY_XPVDS ; Jump if not

	 REGSAVE <eax,edx>	; Save for a moment

	 movzx	 eax,DMASIZE	; Get DMA buffer size in 1KB
	 shl	 eax,10-0	; Convert from 1KB to bytes

	 push	 eax		; Pass the size in bytes
	 push	 ebx		; Pass the physical address
	 FICALL  JGROUP:PVDS_TRANS,DTE_CSJG ; Return with EAX = translated address
				; EDX = next address after contiguous
				;	region (on 4KB boundary)
	 REGREST <edx,eax>	; Restore registers
	 jc	 short CHECK_DMA_BOUNDARY_EXIT ; Jump if region is
				; not contiguous (note CF=1)

; Verify that the proposed DMA buffer meets the boundary conditions
; of the particular machine.

	 mov	 ebx,eax	; Copy new physical address
CHECK_DMA_BOUNDARY_XPVDS:
	 test	 LCL_FLAG,@LCL_MCA ; Izit a Micro channel machine?
	 jnz	 short CHECK_DMA_BOUNDARY_EXIT ; Jump if so (no boundary
				; requirements) (note CF=0)
	 test	 CM2_FLAG,@CM2_EISA_DMA ; Is this an EISA style DMA machine?
	 jnz	 short CHECK_DMA_BOUNDARY_EXIT ; Jump if so (no boundary
				; requirements) (note CF=0)
	 mov	 ax,DMASIZE	; Get DMA buffer size in 1KB

	 cmp	 ax,64		; Is DMA buffer greater than 64 KB?
	 ja	 short CHECK_DMA_BOUNDARY_128 ; Jump if so

	 shl	 ax,10-0	; Convert from 1KB to bytes
	 dec	 ax		; Convert from length to limit

	 add	 bx,ax		; Add buffer size to starting location
	 jmp	 short CHECK_DMA_BOUNDARY_EXIT ; Join common exit code
				; with CF significant
				; CF=0 if buffer will fit in 64 KB
				;   =1 if it won't
CHECK_DMA_BOUNDARY_128:
	 test	 ebx,(1 shl (10+7)) - 1 ; Is phys addr on a 128 KB boundary?
	 jz	 short CHECK_DMA_BOUNDARY_EXIT ; Jump if so (note CF=0)

	 stc			; Indicate DMA buffer address not acceptable
CHECK_DMA_BOUNDARY_EXIT:
	 REGREST <ebx,eax>	; Restore physical address

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
CHECK_DMA_BOUNDARY	 endp	; End CHECK_DMA_BOUNDARY procedure
endif				; IF @OEM_DMA
	 NPPROC  SWAP_MAPBASE -- Swap MAPBASE PTEs With Shadow RAM
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

If we're using SHADOWRAM, ensure the PTEs are one-to-one linear-to-physical

|

	 REGSAVE <ecx,edx,esi,edi> ; Save registers

	 test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
	 jz	 short SWAP_MAPBASE_EXIT ; Not this time

	 mov	 cx,MAPTAB_CNT	; Get # entries in table

	 and	 cx,cx		; Any entries to search?
	 jz	 short SWAP_MAPBASE_EXIT ; None this time

	 mov	 esi,PPDTMAP	; Initialize offset into MAPBASE area
	 xor	 di,di		; Initialize index to MAPTAB
SWAP_MAPBASE_NEXT1:
	 REGSAVE <cx>		; Save for a moment

	 test	 MAPTAB.MAP_FLAG[di],@MAP_ROM ; Izit ROM?
	 jz	 short SWAP_MAPBASE_LOOP ; No, skip this one

	 test	 MAPTAB.MAP_FLAG[di],@MAP_SWAP ; Izit subject to swapping?
	 jz	 short SWAP_MAPBASE_LOOP ; No, skip this one

	 cmp	 MAPTAB.MAP_LEN[di],0 ; Check entry length in paras
	 je	 short SWAP_MAPBASE_LOOP ; Nothing there, skip this one

; Find the matching PTEs in the PDT and swap them with FS:SI

	 REGSAVE <di>		; Save register

	 mov	 cx,MAPTAB.MAP_LEN[di] ; Get entry length in paras
	 add	 cx,(4*1024/16)-1 ; Round up to 4KB boundary
	 shr	 cx,12-4	; Convert from paras to 4KB

	 movzx	 edx,MAPTAB.MAP_PARA_SRC[di] ; Get paragraph # of ROM
	 shl	 edx,4-0	; Convert from paras to bytes
	 or	 dx,@PTE_URP	; Mark as User/Read-write/Present

	 mov	 edi,esi	; FS:EDI ==> next PTE at PPDTMAP

; Loop through CX 4KB PTEs

SWAP_MAPBASE_NEXT2:
	 push	 cx		; Save for a moment

	 movzx	 ecx,SHDSIZE	; ECX = total size of shadow RAM
	 shr	 ecx,12-10	; Convert from 1KB to 4KB
	 mov	 esi,PPDTSHD	; FS:ESI ==> starting point of search

; Search for EDX in the PDT -- return that offset in ESI
; Start at FS:ESI for ECX entries

	 call	 FIND_PTE_SUB	; Find the PTE in EDX, return offset in ESI
	 jnc	 short SWAP_MAPBASE_FND ; Jump if found

	 add	 edi,4		; Skip to next PPDTMAP PTE

	 jmp	 short SWAP_MAPBASE_FND1 ; Join common code

SWAP_MAPBASE_FND:
	 call	 XCHG_PTE	; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE
				; although we ignore the increment to ESI
SWAP_MAPBASE_FND1:
	 add	 edx,CON4KB	; Skip to next PTE

	 pop	 cx		; Restore

	 loop	 SWAP_MAPBASE_NEXT2 ; Jump if more PTEs to find

	 mov	 esi,edi	; FS:ESI ==> next PTE at PPDTMAP

	 REGREST <di>		; Restore
SWAP_MAPBASE_LOOP:
	 REGREST <cx>		; Restore

	 add	 di,type MAP_STR ; Skip to next MAPTAB entry

	 loop	 SWAP_MAPBASE_NEXT1 ; Jump if more MAPTAB entries
SWAP_MAPBASE_EXIT:
	 REGREST <edi,esi,edx,ecx> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_MAPBASE endp		; End SWAP_MAPBASE procedure
	 NPPROC  FILL_LOWBASE -- Fill In LOWBASE Pages
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Exchange the PTEs starting at LOWOFF with PPDTLOW and mark them
as not physical memory.
The PTEs at LOWOFF get mapped in during INIT_DATA from PDTCNV.

|

	 REGSAVE <ecx,esi,edi>	; Save registers

	 test	 CMD_FLAG,@CMD_XLO ; Are we filling in low DOS memory?
	 jnz	 short FILL_LOWBASE_XLO ; Not this time

	 xor	 esi,esi	; FS:SI ==> start of PDT
	 add	 esi,LOWOFF	; Plus start of DOS low memory -- the unit
				; is 1KB which is the same as 4KB in dwords
				; DS:ESI ==> table start (on 4KB boundary)
	 mov	 cx,LOWSIZE	; Get size of low DOS memory

	 cmp	 cx,0		; Check sign
	 jle	 short FILL_LOWBASE_XLO ; No low filling this time

	 shr	 cx,12-10	; Convert from 1KB to 4KB

	 mov	 edi,PPDTLOW	; ES:EDI ==> PDT entries at LOWBASE

	 REGSAVE <cx>		; Save for a moment
FILL_LOWBASE_XCHG:
	 call	 XCHG_PTE	; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE

	 loop	 FILL_LOWBASE_XCHG ; Jump if more PTEs to exchange

	 REGREST <cx>		; Restore

; Mark the entries as not physical memory

	 mov	 esi,PPDTLOW	; DS:ESI ==> PDT entries at LOWBASE
FILL_LOWBASE_NEXT:
	 or	 OFFPDT.ELO[esi],mask $PTE_AV1 ; Mark as absent

	 add	 esi,4		; Skip to next entry

	 loop	 FILL_LOWBASE_NEXT ; Jump if more PTEs

	 jmp	 short FILL_LOWBASE_EXIT ; Join common exit code

; Not filling low DOS memory
; Mark these PTEs as absent

FILL_LOWBASE_XLO:
	 mov	 esi,LOWOFF	; Get start of top of DOS memory in 1KB
	 mov	 ecx,VIDOFF	; Get start of video memory in 1KB
	 sub	 ecx,esi	; Less start of top of DOS memory
	 shr	 ecx,12-10	; Convert from 1KB to 4KB
	 jcxz	 FILL_LOWBASE_EXIT ; Nothing to mark as absent

	 jmp	 FILL_LOWBASE_NEXT ; Join common code

FILL_LOWBASE_EXIT:
	 REGREST <edi,esi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_LOWBASE endp		; End FILL_LOWBASE procedure
if @OEM_EMS
	 NPPROC  FILL_SEG -- Fill in Segment for PHYS2SEG
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in segment for PHYS2SEG table.

On entry:

ES:EDI	 ==>	 output save area
BL	 =	 primary marker for search
BH	 =	 secondary ...

On exit:

ES:EDI	 ==>	 (updated)

|

	 REGSAVE <ax,cx,si>	; Save registers

	 lea	 si,PPMTAB	; DS:SI ==> Physical Page Map table
	 mov	 cx,PPMTAB_LEN	; CX = # table length
FILL_SEG_NEXT:
	 lodsb			; Get next entry
	 and	 al,not mask $PPM_SHD ; Remove shadow RAM marker

	 cmp	 al,bl		; Duzit match primary marker?
	 je	 short @F	; Yes

	 cmp	 al,bh		; Duzit match secondary marker?
	 jne	 short FILL_SEG_LOOP ; No
@@:
	 mov	 ax,si		; Copy offset of next entry
	 sub	 ax,1+offset ds:PPMTAB ; Convert to origin-0
	 shl	 ax,14-4	; Convert from 16KB to paras

S32	 stos	 PGROUP:[edi].ELO ; Save in PHYS2SEG table
FILL_SEG_LOOP:
	 loop	 FILL_SEG_NEXT	; Jump if more entries to check

	 REGREST <si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_SEG endp			; End FILL_SEG procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  FILL_PHYS2SEG -- Fill In PHYS2SEG Table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in PHYS2SEG table

|

	 REGSAVE <bx,edi>	; Save registers

	 mov	 edi,PPHYS2SEG	; ES:EDI ==> start of table

; First the EMS frame entries

	 mov	 bl,@PPM_FRM	; EMS frame marker
	 mov	 bh,-1		; No secondary marker
	 call	 FILL_SEG	; Fill in the segments

	 test	 CM3_FLAG,@CM3_DOS4 ; DOS4 numbering specified?
	 jnz	 short @F	; Yes, do conventional memory next

; Next the INCLUDEd and SCREEN entries

	 mov	 bl,@PPM_INC	; INCLUDEd marker
	 mov	 bh,@PPM_SCR	; SCREEN marker
	 call	 FILL_SEG	; Fill in the segments
@@:

; Next conventional memory entries

	 mov	 bl,@PPM_CNV	; Conventional marker
	 mov	 bh,-1		; No secondary marker
	 call	 FILL_SEG	; Fill in the segments

	 test	 CM3_FLAG,@CM3_DOS4 ; DOS4 numbering specified?
	 jz	 short @F	; No, all done

; Next the INCLUDEd and SCREEN entries

	 mov	 bl,@PPM_INC	; INCLUDEd marker
	 mov	 bh,@PPM_SCR	; SCREEN marker
	 call	 FILL_SEG	; Fill in the segments
@@:
	 REGREST <edi,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_PHYS2SEG endp		; End FILL_PHYS2SEG procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  FILL_SEG2PHYS -- Fill In SEG2PHYS Table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in SEG2PHYS table by grading the PHYS2SEG table

|

@FILL_PHYS equ	 -1		; Filler marker (must be >= NPHYS16S)
@TMPLEN  equ	 1024/16	; Length of temporary table

	 pushad 		; Save all EGP registers

; Use a simple address sort

	 sub	 esp,@TMPLEN	; Make room for # 16KB pages in 1MB
	 mov	 ebp,esp	; SS:EBP ==> temporary table

; Fill table with known values

	 push	 es		; Save for a moment

	 push	 ss		; Get stack selector
	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 edi,ebp	; ES:EDI ==> temporary table
	 mov	 ecx,@TMPLEN	; ECX = # 16KB pages in 1MB
	 mov	 al,@FILL_PHYS	; Filler
     rep stos	 es:[edi].LO	; Fill it up

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 cx,NPHYS16S.ELO ; Get # physical 16KB pages in EMS system
	 jcxz	 FILL_SEG2PHYS_EXIT ; None

	 xor	 dx,dx		; Zero counter
	 mov	 esi,PPHYS2SEG	; DS:ESI ==> start of table
FILL_SEG2PHYS_NEXT1:
	 lods	 PGROUP:[esi].ELO ; Get next segment
	 movzx	 edi,ax 	; Copy to index register
	 shr	 edi,14-4	; Convert from paras to 16KB

	 mov	 [ebp+edi],dl	; Save index
	 inc	 dx		; Skip to next 16KB page #

	 loop	 FILL_SEG2PHYS_NEXT1 ; Jump if more 16KB pages

; Now trundle through the temporary table and copy
; non-filler entries to SEG2PHYS

	 mov	 esi,ebp	; SS:ESI ==> temporary table
	 mov	 edi,PSEG2PHYS	; ES:EDI ==> SEG2PHYS table
	 mov	 cx,@TMPLEN	; CX = # 16KB pages in 1MB
FILL_SEG2PHYS_NEXT2:
	 lods	 ss:[esi].LO	; Get next entry

	 cmp	 al,@FILL_PHYS	; Izit the filler?
	 je	 short @F	; Yes, skip save

S32	 stos	 PGROUP:[edi].LO ; Save in SEG2PHYS table
@@:
	 loop	 FILL_SEG2PHYS_NEXT2 ; Jump if more physical pages to check
FILL_SEG2PHYS_EXIT:
	 add	 esp,@TMPLEN	; Strip table from stack

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_SEG2PHYS endp		; End FILL_SEG2PHYS procedure
endif				; IF @OEM_EMS
	 NPPROC  FILL_OVRBASE -- Fill In OVRBASE Pages
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Map in OVRBASE pages to fill high DOS memory
Also, zero the memory so it starts off with a fixed value.
Some BIOS's POST fills with 55AA which we will confuse as ROM.

Note that paging is enabled.

|

	 REGSAVE <eax,ebx,ecx,esi,edi,es,fs> ; Save registers

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,OVRBASE	; ES:EDI ==> base address in extended memory
	 movzx	 ecx,OVRSIZE	; Size of high DOS memory in 1KB
	 shl	 ecx,10-2	; Convert from 1KB to dwords
	 xor	 eax,eax	; A convenient zero
     rep stos	 AGROUP:[edi].EDD ; Fill with constant value

; If we're providing Win3 support, ensure that the PTEs
; we're to use to high DOS memory are below 16MB physical memory
; If there's possible DMA target mapped into high DOS, Windows
; won't check the address and fails.

	 test	 CM3_FLAG,@CM3_NOWIN3 ; Disabling support for WIN3?
	 jnz	 near ptr FILL_OVRBASE_XWIN3 ; Jump if so

	 push	 DTE_PDT	; Get PDT selector
	 pop	 fs		; Ensure FS points to the PDT
	 assume  fs:PDTGRP	; Tell the assembler about it

	 mov	 cx,OVRSIZE	; Get size of high DOS memory fill
	 shr	 cx,12-10	; Convert from 1KB to 4KB
	 jz	 short FILL_OVRBASE_XWIN3 ; Jump if nothing to do

; Check for OVRBASE PTEs at or above 16MB

	 mov	 esi,PPDTOVR	; Get offset of OVRBASE in PDT
@@:
	 lods	 OFFPDT[esi]	; Get next PTE
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame

	 cmp	 eax,CON16MB	; Izit bigger than a breadbox?
	 jae	 short @F	; Jump if so

	 loop	 @B		; Jump if more PTes to check

	 jmp	 short FILL_OVRBASE_XWIN3 ; Jump if they're all within range

@@:
; Physical memory at or above 16MB is mapped into high DOS
; Steal some memory from below 16MB and swap it with PPDTOVR

	 mov	 esi,PPDTOVR	; Get offset of OVRBASE in PDT
	 mov	 edi,PPDT1W1MB	; ...		1.1/1.11MB ...

FILL_OVRBASE_NEXTBLOCK:
	 mov	 ebx,edi	; Save start of current search block

	 mov	 cx,OVRSIZE	; Get size of high DOS memory fill
	 shr	 cx,12-10	; Convert from 1KB to 4KB

FILL_OVRBASE_NEXTPTE:
	 mov	 eax,OFFPDT[edi] ; Get the PTE there
	 and	 ax,mask $PTE_FRM ; Isolate 4KB frame

	 cmp	 eax,CON16MB	; Izit bigger than a breadbox?
	 jae	 short FILL_OVRBASE_SLOOP ; Jump if so

	 add	 edi,size OFFPDT ; Skip to next PTE
	 loop	 short FILL_OVRBASE_NEXTPTE ; Check next PTE

	 mov	 edi,ebx	; Restore start of swap area

	 mov	 cx,OVRSIZE	; Get size of high DOS memory fill
	 shr	 cx,12-10	; Convert from 1KB to 4KB

FILL_OVRBASE_SWAP:
	 call	 XCHG_PTE	; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE

	 loop	 short FILL_OVRBASE_SWAP ; Jump if more PTEs to swap

	 jmp	 short FILL_OVRBASE_XWIN3 ; Join common code

FILL_OVRBASE_SLOOP:
	 mov	 edi,ebx	; Restore start of swap area
	 add	 edi,size OFFPDT ; Skip to next PTE

	 cmp	 edi,(16*1024*1024/1024) ; Have we reached the top of our search?
	 jb	 short FILL_OVRBASE_NEXTBLOCK ; Jump if not (below linear 16MB)

	 mov	 cx,OVRSIZE	; Get size of high DOS memory fill
	 shr	 cx,12-10	; Convert from 1KB to 4KB

; Set flag in both ext and low DOS memory

	 or	 CMD_FLAG,@CMD_OVR16 ; Mark as present
	 assume  ss:PGROUP	; Ensure SS has proper base frame
	 or	 ss:CMD_FLAG,@CMD_OVR16 ; Mark as present
	 assume  ss:nothing	; Tell the assembler about it
FILL_OVRBASE_XWIN3:
	 mov	 eax,OVRBASE	; Get base address in extended memory
	 or	 ax,@PTE_URP	; Mark as User/Read-write/Present
	 mov	 cx,MCSTAB_CNT	; CX = # entries in MCSTAB
	 mov	 esi,PPDTOVR	; Get offset of OVRBASE in PDT
	 xor	 bx,bx		; Index into MCSTAB
FILL_OVRBASE1:
	 test	 MCSTAB.MCS_FLAG[bx],@MCS_HOLE ; Izit a hole (end of the chain)?
	 jnz	 short FILL_OVRBASE_EXIT ; Yes, skip out

	 test	 MCSTAB.MCS_FLAG[bx],@MCS_AVAIL ; Izit available?
	 jz	 short FILL_OVRBASE_LOOP ; No, skip it

	 push	 cx		; Save for a moment

	 mov	 cx,MCSTAB.MCS_NPAR[bx] ; Get # paragraphs

	 shr	 cx,12-4	; Convert from paras to 4KB
	 jz	 short FILL_OVRBASE5  ; Check next entry

	 mov	 di,MCSTAB.MCS_PARA[bx] ; Get paragraph #
	 shr	 di,12-4	; Convert from paras to 4KB
	 shl	 di,2		; Times four to index table of dwords
FILL_OVRBASE4:
	 mov	 eax,OFFPDT[esi] ; Get high memory entry
	 xchg	 eax,OFFPDT[di] ; Swap with low memory entry
	 or	 ax,mask $PTE_AV1 ; Mark as absent in memory
	 mov	 OFFPDT[esi],eax ; Save back into high memory

	 add	 di,4		; Skip to next entry
	 add	 esi,4		; Skip to next entry

	 loop	 FILL_OVRBASE4	; Jump if more pages in rest of extended memory
FILL_OVRBASE5:
	 pop	 cx		; Restore
FILL_OVRBASE_LOOP:
	 add	 bx,size MCS_STR ; Skip to next entry

	 loop	 FILL_OVRBASE1	; Go around again
FILL_OVRBASE_EXIT:
	 REGREST <fs,es,edi,esi,ecx,ebx,eax> ; Restore
	 assume  es:PGROUP,fs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_OVRBASE endp		; End FILL_OVRBASE procedure
if @OEM_FLEXROM
	 NPPROC  FILL_VGASWAP -- Fill In Trailing VGA ROM Pages
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Map in VGASWAP pages to reflect the old BIOS's physical address

Note that paging is enabled.

|

	 pushad 		; Save all EGP registers
	 REGSAVE <es>		; Save segment register

	 test	 FLEXROM_FLAG,@FR_ACTIVE ; Is VGASWAP in effect?
	 jz	 near ptr FILL_VGASWAP_EXIT ; Jump if not

	 xor	 bp,bp		; Initialize index to start of FLEXROM table

; Prepare to search the new ROM for any uninitialized PTEs
; If we find any, we will point them to the original ROM

FILL_VGASWAP_NEXT_ROM:
	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 es		; Address it
	 assume  es:RGROUP	; Tell the assembler about it

	 movzx	 edi,FLEXROM_TBL[bp].FLEX_DST ; Get destin FLEXROM segment
	 shl	 edi,4-0	; Convert from paras to bytes
	 mov	 edx,edi	; Save for 1:1 comaprison

	 movzx	 eax,FLEXROM_TBL[bp].FLEX_SRC ; Get source FLEXROM segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 or	 ax,@PTE_URP	; Mark as User/Read-write/Present

	 movzx	 ecx,FLEXROM_TBL[bp].FLEX_LEN ; Get ROM length
	 shr	 ecx,(16-4)	; Convert from bytes to 4KB

	 shr	 edi,(12-2)-0	; Convert from bytes to 4KB in dwords
				; PDTGROUP:DI => offset in PDT of trailing PTEs
				; to be set to one-to-one

; Loop through all PTEs that make up the new BIOS
; Check for any which have not been set (they are still 1:1)
; For any that we do find, change them to point directly to the original ROM.
; This will primarily be used for ROMs with an uncached C6 and C7

FILL_VGASWAP_NEXT:
	 mov	 esi,OFFPDT[di] ; Get PTE in question
	 and	 esi,(mask $PTE_FRM) or (mask $PTE_FRMHI) ; Mask off flag bits

	 cmp	 edx,esi	; Izit a 1-1 PTE?
	 jne	 short FILL_VGASWAP_LOOP ; No, so don't modify it

	 mov	 OFFPDT[di],eax ; Save new PTE (points to original BIOS)

	 REGSAVE <eax>		; Save register

	 mov	 eax,edx	; Get destination address
	 shr	 eax,(4-0)	; Convert bytes to paras
	 sub	 ax,FLEXROM_TBL[bp].FLEX_DST ; Convert to 0 origin
	 shr	 ax,(12-4)	; Convert paras to pages
	 bts	 FLEXROM_TBL[bp].FLEX_MAP,ax ; Set bit for this page

	 REGREST <eax>		; Restore register

FILL_VGASWAP_LOOP:
	 add	 di,size OFFPDT ; Skip to next PTE offset
	 add	 eax,CON4KB	; Skip to next PTE value
	 add	 edx,CON4KB	; Skip to next PTE value

	 loop	 FILL_VGASWAP_NEXT ; Jump if more trailing PTEs to set

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 call	 FLEXROM_RELOC	; Relocate the ROM's resources

	 add	 bp,@FLEXROM_STRLEN ; Point to next ROM

	 cmp	 bp,FLEXROM_LEN ; More entries to process?
	 jb	 near ptr FILL_VGASWAP_NEXT_ROM ; Yes, process next entry

FILL_VGASWAP_EXIT:
	 REGREST <es>		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_VGASWAP endp		; End FILL_VGASWAP procedure
endif				; IF @OEM_FLEXROM
	 NPPROC  FILL_MAPBASE -- Fill In MAPBASE Pages
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Swap the pages beginning at MAPBASE with the entries in MAPTAB.

|

	 REGSAVE <eax,ecx,edx,esi,edi,es> ; Save registers

	 mov	 cx,MAPTAB_CNT	; Get # entries in table
	 jcxz	 FILL_MAPBASE_END ; Jump if no entries to search

	 mov	 edx,MAPBASE	; Get linear address of map base
	 mov	 esi,PPDTMAP	; Initialize offset into MAPBASE area
	 xor	 di,di		; Initialize index to MAPTAB

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it
FILL_MAPBASE1:
	 test	 MAPTAB.MAP_FLAG[di],@MAP_ROM ; Izit ROM?
	 jz	 short FILL_MAPBASE_LOOP ; No, skip this one

	 test	 MAPTAB.MAP_FLAG[di],@MAP_SWAP ; Izit subject to swapping?
	 jz	 short FILL_MAPBASE_LOOP ; No, skip this one

	 cmp	 MAPTAB.MAP_LEN[di],0 ; Check entry length in paras
	 je	 short FILL_MAPBASE_LOOP ; Nothing there, skip this one

	 REGSAVE <ecx,esi,edi>	; Save registers

	 movzx	 esi,MAPTAB.MAP_PAR2[di] ; Get paragraph # in low memory
	 shl	 esi,4-0	; Convert from paras to bytes

; Move data from source (low  memory -- presumably slow)
;	      to destin (high memory -- presumably fast)

	 movzx	 ecx,MAPTAB.MAP_LEN[di] ; Get entry length in paras
	 shl	 ecx,4-2	; Convert from paras to dwords

	 mov	 edi,edx	; Copy linear address of destination
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Move to high memory

	 REGREST <edi,esi,ecx>	; Restore

	 call	 SWAP_MAP	; Swap PTEs for MAP, increment ESI and EDX
FILL_MAPBASE_LOOP:
	 add	 di,type MAP_STR ; Skip to next MAPTAB entry

	 loop	 FILL_MAPBASE1	; Jump if more entries
FILL_MAPBASE_END:
	 REGREST <es,edi,esi,edx,ecx,eax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_MAPBASE endp		; End FILL_MAPBASE procedure
	 NPPROC  FILL_WRAPTAB -- Fill WRAPTAB
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill the 1MB wrap table as well as PDTCVD
with the PTEs of the first 64KB.
This routine *MUST* be run after SWAP_MEM.

|

	 REGSAVE <ecx,esi,edi>	; Save registers

	 lea	 edi,WRAPTAB	; ES:EDI ==> destination for move
	 mov	 esi,PRGPDT	; ES:ESI ==> source of move
	 mov	 ecx,64/4	; # dwords (PTEs) in 1MB wrap region

S32  rep movs	 <WRAPTAB[edi],PGROUP:[esi].PDT_PTE> ; Move 'em

	 or	 LCL_FLAG,@LCL_WRP ; Mark as intialized

; Copy the 1MB wrap entries to the pseudo-1MB unwrap location at PPDTCVD

	 mov	 esi,PPDT1MB	; DS:ESI ==> source PTEs
	 add	 esi,PRGPDT	; Plus offset of PDT in PGROUP

	 mov	 edi,PPDTCVD	; ES:EDI ==> destin PTEs
	 add	 edi,PRGPDT	; Plus offset of PDT in PGROUP

	 mov	 ecx,64/4	; # dwords (PTEs) in 1MB wrap region

S32  rep movs	 <PGROUP:[edi].PDT_PTE,PGROUP:[esi].PDT_PTE> ; Move PTEs

	 REGREST <edi,esi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_WRAPTAB endp		; End FILL_WRAPTAB procedure
	 NPPROC  FILL_PDTCNV -- Fill In PDTCNV Table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in PDTCNV table with default PTEs for all conventional memory pages.

This routine *MUST* be called after both FILL_LOWBASE and SWAP_MEM
and before INIT_DATA.

|

	 REGSAVE <ecx,esi,edi>	; Save registers

	 mov	 edi,PPDTCNV	; ES:EDI ==> start of table
	 add	 edi,PRGPDT	; Plus offset of PDT in PGROUP

; Fill in the original DOS memory entries starting with segment at 0000h.

	 mov	 esi,PRGPDT	; DS:ESI ==> PTEs at start of table
	 mov	 ecx,VIDOFF	; Get start of video buffers
	 shr	 ecx,12-10	; Convert from 1KB to 4KB

S32  rep movs	 <PGROUP:[edi].PDT_PTE,PGROUP:[esi].PDT_PTE> ; Move PTEs

	 REGREST <edi,esi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_PDTCNV endp		; End FILL_PDTCNV procedure
	 NPPROC  FILL_PDTSCR -- Fill In PDTSCR Table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in PDTCNV table with default PTEs for all SCREEN memory pages.

This routine *MUST* be called after both FILL_LOWBASE and SWAP_MEM
and before INIT_DATA.

|

	 REGSAVE <ecx,esi,edi>	; Save registers

	 test	 CM2_FLAG,@CM2_SCR ; SCREEN specified?
	 jz	 short FILL_PDTSCR_EXIT ; Not this time

	 mov	 edi,PPDTSCR	; ES:EDI ==> start of table
	 add	 edi,PRGPDT	; Plus offset of PDT in PGROUP

; Fill in the video buffer entries

	 mov	 esi,PRGPDT	; DS:ESI ==> PTEs at start of table
	 add	 esi,0B000h shr ((12-2)-4) ; Convert from paras to 4KB in dwords
	 mov	 ecx,64/4	; # 4KB dword-entries in 64KB

S32  rep movs	 <PGROUP:[edi].PDT_PTE,PGROUP:[esi].PDT_PTE> ; Move PTEs
FILL_PDTSCR_EXIT:
	 REGREST <edi,esi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_PDTSCR endp		; End FILL_PDTSCR procedure
	NPPROC	FILL_PDTPnPBIOS -- Fill In PDTPnPBIOS Table
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in PDTPnPBIOS table with the BIOS PTEs.

|

	REGSAVE <eax,ecx,esi,edi,gs> ; Save registers

	movzx	edi,PnP_SEG	; Get the PnP struc segment in BIOS
	shl	edi,4-0 	; Convert from paras to bytes
	jz	near ptr FILL_PDTPnPBIOS_EXIT ; Jump if not

	mov	gs,SEL_4GB3	; Get AGROUP data selector at PL3
	assume	gs:AGROUP	; Tell the assembler about it

; Setup the PnP code, data, and argument selectors

	mov	eax,OffPnP_PMCS ; Get offset to PnP_PMCS
	mov	eax,AGROUP:[edi+eax] ; Get PM code segment base

	cmp	AGROUP:[edi].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F	; Jump if so (no PMDS in old struc)

	mov	SEL_PnPDS,0	; No PMDS in old struc
@@:
	sub	eax,@PnP_BIOS_BEG ; Less our starting base
	add	eax,LaPnP_BIOS	; Plus the linear address of the PnP BIOS
	mov	LaPnP_PMCS,eax	; Save for VCPI use

	push	CON64KB 	; Pass size of segment
	push	CPL0_CODE or CPL0 ; Pass access rights byte
	push	DTE_PnPCS	; Pass descriptor to set
	call	SET_GDT 	; Set the GDT to EAX base

	xor	eax,eax 	; No PMDS in old struc

	cmp	AGROUP:[edi].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short @F	; Jump if not (no PMDS in old struc)

	mov	eax,AGROUP:[edi].PnP_PMDS ; Get PM data segment base

	cmp	eax,@PnP_BIOS_BEG ; Izit below start of system BIOS?
	jb	short @F	; Jump if so

	cmp	eax,@PnP_BIOS_END ; Izit above end of system BIOS?
	jae	short @F	; Jump if so

	sub	eax,@PnP_BIOS_BEG ; Less our starting base
	add	eax,LaPnP_BIOS	; Plus the linear address of the PnP BIOS
@@:
	mov	LaPnP_PMDS,eax	; Save for VCPI use

	push	CON64KB 	; Pass size of segment
	push	CPL0_DATA or CPL0 ; Pass access rights byte
	push	DTE_PnPDS	; Pass descriptor to set
	call	SET_GDT 	; Set the GDT to EAX base

	xor	eax,eax 	; An arbitrary base
	push	CON64KB 	; Pass size of segment
	push	CPL0_DATA or CPL0 ; Pass access rights byte
	push	DTE_PnPARG0	; Pass descriptor to set
	call	SET_GDT 	; Set the GDT to EAX base

;;;;;;; xor	eax,eax 	; An arbitrary base
	push	CON64KB 	; Pass size of segment
	push	CPL0_DATA or CPL0 ; Pass access rights byte
	push	DTE_PnPARG1	; Pass descriptor to set
	call	SET_GDT 	; Set the GDT to EAX base

;;;;;;; xor	eax,eax 	; An arbitrary base
	push	CON64KB 	; Pass size of segment
	push	CPL0_DATA or CPL0 ; Pass access rights byte
	push	DTE_PnPARG2	; Pass descriptor to set
	call	SET_GDT 	; Set the GDT to EAX base

; Save the original RM entry point in extended memory
; which will be copied to low DOS before we enter VM

	mov	eax,OffPnP_RMVEC ; Get offset to PnP_RMVEC
	mov	eax,AGROUP:[edi+eax] ; Get original value

	mov	ORIG_PnP_RMVEC,eax ; Save for later use

; Fill in the linear address of the PnP argument selectors in the GDT

	lea	eax,DESC_TAB[DTE_PnPARG0] ; Get offset in PGROUP of PnP
				; argument selectors in the GDT
	add	eax,PRGBASE	; Convert from offset to linear address
	mov	LaGDTPnPARG,eax ; Save for later use

; Fill in segment of PnP struc in BIOS

	mov	ax,PnP_SEG	; Get the PnP struc segment in BIOS
	mov	WIN3_REF_DATA.REF_PnP_SEG,ax ; Save in structure for VxD

; Fill in PTEs of the original BIOS starting with @PnP_BIOS_BEG

	mov	edi,PPDTPnPBIOS ; ES:EDI ==> start of table
	add	edi,PRGPDT	; Plus offset of PDT in PGROUP

	mov	eax,@PnP_BIOS_BEG or @PTE_URP ; Get starting physical address
				; marked as User/Read-Write/Present
	mov	ecx,@PnP_NPTES	; Get # PTEs to fill in
@@:
S32	stos	PGROUP:[edi].PDT_PTE ; Save in PDT
	add	eax,CON4KB	; Skip to next PTE

	loop	@B		; Jump if more PTEs to fill in

	call	PATCH_PnP	; Patch into the PnP struc in BIOS
FILL_PDTPnPBIOS_EXIT:
	REGREST <gs,edi,esi,ecx,eax> ; Restore
	assume	gs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_PDTPnPBIOS endp		; End FILL_PDTPnPBIOS procedure
	 NPPROC  FILL_PDIR -- Fill The PDIR Entries
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize the PDEs

|

	 REGSAVE <eax,ecx,esi,edi> ; Save registers

	 mov	 edi,OFFCR3	; ES:EDI ==> page directory base
	 mov	 esi,PDTDIR2	; DS:ESI ==> offset in PDT of 2nd level dir entries
	 add	 esi,PRGPDT	; Plus offset of PDT in PGROUP
	 mov	 ecx,PDBSIZE	; Get # page directory base entries
	 inc	 ecx		; Plus one for device-to-memory transfers
				; and access to CNV PTEs
@@:
	 lods	 PGROUP:[esi].PDT_PTE ; Get next PTE from the PDT
	 or	 ax,@PTE_URP	; Ensure accessible
S32	 stos	 PGROUP:[edi].PDT_PTE ; Save it

	 loopd	 @B		; Jump if more page directory base entries

; Initialize the remaining entries to the physical address of
; the first overflow PTE table

	 mov	 ecx,1024	; Get # 4MB PDEs in 4GB
	 sub	 ecx,PDBSIZE	; Less # we just installed
	 dec	 ecx		; Less one for D2M and CNV as above

	 mov	 eax,PaOPTE1	; Get physical address of overflow PTE table

; Ensure the User, Read-Write, and Present bits are set

	 or	 ax,@PTE_URP	; Mark as User/Read-write/Present
     rep stos	 PGROUP:[edi].EDD ; Save as default PDIR entry

	 REGREST <edi,esi,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_PDIR endp			; End FILL_PDIR procedure
	 NPPROC  SWAP_PRG -- Swap PDT Entries for PRG
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Swap PDT entries for PRGBASE and LMLBASE

|

	 REGSAVE <ecx,esi,edi>	; Save registers

	 mov	 edi,LMLTOP	; Get start of low memory load (unit = 1KB)
	 movzx	 ecx,PRGSIZE	; Get size of PRG (in units of 1KB)
	 sub	 edi,ecx	; Back off to start of low memory area
	 shr	 ecx,12-10	; Convert from 1KB to 4KB
				; ECX = # PTEs in the PRG

; Skip over PTEs which precede LML area

;;;;;;;; sh?	 edi,(14-4)-10	; Convert from 1KB to 16KB in four dwords
				; FS:EDI ==> start of LML PTEs in PDT
	 mov	 esi,PPDTPRG	; FS:ESI ==> start of PRG PTEs in PDT
SWAP_PRG_LOOP:
	 call	 XCHG_PTE	; Swap PTEs at FS:ESI and FS:EDI
				; Increment ESI and EDI to next PTE

	 loop	 SWAP_PRG_LOOP	; Jump if more entries to swap

	 call	 SET_PHYS	; Set various physical addresses

	 REGREST <edi,esi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_PRG endp			; End SWAP_PRG procedure
	 FPPROC  INT15PROT -- Enter Protected Mode
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter protected mode by hand because we can't trust some
BIOSes to do it properly.

On entry:

* Disable NMI
* Disable IMR

ES:SI	 ==>	 descriptor table
BH	 =	 8259 origin for master
BL	 =	 8259 origin for slave

On exit:

* Disable interrupts
* Read and save A20 state
* Gate A20 on
* Setup DTE_BIOS entry
* Load GDTR
* Load IDTR
* Program the 8259
* Enter protected mode
* Setup segment registers
* Return to caller

|

; * Disable interrupts

	 cli

; * Gate A20 on

	 call	 GATEA20

; * Setup DTE_BIOS entry

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,cs		; Get current code segment
	 shl	 eax,4-0	; Convert from paras to bytes

	 mov	 es:[si].DTE_BIOS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 es:[si].DTE_BIOS.DESC_BASE3,al
;;;;;;;; ror	 eax,8		; Rotate back
	 mov	 es:[si].DTE_BIOS.DESC_SEGLM0,0FFFFh ; 64KB of code
	 mov	 es:[si].DTE_BIOS.DESC_SEGLM1,0
	 mov	 es:[si].DTE_BIOS.DESC_ACCESS,CPL0_CODE

; * Load GDTR from low memory

	 LGDTD	 es:[si].DTE_GDT.EDF

; * Load IDTR

	 LIDTD	 es:[si].DTE_IDT.EDF

; * Program the 8259

	 test	 DB3_FLAG,@DB3_PIC ; Should we reprogram the PIC?
	 jz	 near ptr INT15PROT2 ; Jump if not

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jz	 short INT15PROT1 ; Not this time

; ICW1

	 mov	 al,13h 	; ICW1 -- edge-triggered, single, ICW4 needed
	 out	 @ICR,al	; Send to 8259
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

; ICW2

	 mov	 al,bh		; ICW2 -- start of 8259 vector
	 out	 @IMR,al	; Send to 8259
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

; ICW3 (none because it's not in cascade mode)
; ICW4

	 mov	 al,09h 	; ICW4 -- buffered slave, normal EOI, 8086 mode
	 out	 @IMR,al	; Send to 8259
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 jmp	 short INT15PROT2 ; Join common code

INT15PROT1:

; ICW1 -- master 8259

	 mov	 al,11h 	; ICW1 -- edge-triggered, cascade, ICW4 needed

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jz	 short @F	; Not this time

	 or	 al,08h 	; Mark as level-triggered
@@:
	 mov	 ah,al		; Save for later use
	 out	 @ICR,al	; Send to master 8259
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

; ICW2 -- master 8259

	 mov	 al,bh		; ICW2 -- start of 8259 vector
	 out	 @IMR,al	; Send to 8259
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

; ICW3 -- master 8259

	 mov	 al,@BIT2	; ICW3 -- master level 2
	 out	 @IMR,al	; Send to master 8259
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

; ICW4 -- master 8259

	 mov	 al,01h 	; ICW4 -- not SFNM, normal EOI, 8086 mode
	 out	 @IMR,al	; Send to master 8259
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

; ICW1 -- slave 8259

	 mov	 al,ah		; ICW1 -- level/edge-triggered, cascade, ICW4 needed
	 out	 @ICR2,al	; Send to slave 8259
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

; ICW2 -- slave 8259

	 mov	 al,bl		; ICW2 -- start of slave 8259 vector
	 out	 @IMR2,al	; Send to slave 8259
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

; ICW3 -- slave 8259

	 mov	 al,02h 	; ICW3 -- slave level 2
	 out	 @IMR2,al	; Send to slave 8259
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

; ICW34-- slave 8259

	 mov	 al,01h 	; ICW4 -- not SFNM, normal EOI, 8086 mode
	 out	 @IMR2,al	; Send to slave 8259
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
INT15PROT2:

; * Enter protected mode

	 mov	 eax,cr0	; Get current CR0
	 or	 ax,mask $PE	; Mark as enabling protected mode
	 mov	 cr0,eax	; Enter protected mode

	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 FIJMP	 PGROUP:@F,DTE_BIOS ; Flush prefetch instruction queue
@@:

; * Setup segment registers

	 mov	 ax,DTE_DS	; Get DS selector
	 mov	 ds,ax
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ax,DTE_DS	; Get DS selector
	 mov	 es,ax
	 assume  es:PGROUP	; Tell the assembler about it

	 xor	 ax,ax		; A convenient zero

	 mov	 fs,ax		; Ensure valid
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 gs,ax		; Ensure valid
	 assume  gs:nothing	; Tell the assembler about it

	 mov	 ax,DTE_SS	; Get SS selector
	 mov	 ss,ax
	 assume  ss:nothing	; Tell the assembler about it

; * Return to caller

	 pop	 ax		; Get return offset
	 push	 DTE_CS 	; Put return selector on stack
	 push	 ax		; Followed by offset

	 xor	 ax,ax		; Successful return code (AH=0, CF=0, ZF=1)

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT15PROT endp			; End INT15PROT procedure
	 NPPROC  RELOC_DTE -- Relocate a GDT Entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

EAX	 =	 relocation factor (to be subtracted from the DTE's base)

|

RELOC_DTE_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
RELOC_DTE_SEL dw ?		; The selector

RELOC_DTE_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,si>	; Save registers

	 mov	 si,[ebp].RELOC_DTE_SEL ; Get the selector

; Put 32-bit selector base into EBX

	 mov	 ebx,DESC_TAB.DESC_BASE01.EDD[si] ; Get base of selector
	 shl	 ebx,8		; Shift out access rights byte
	 mov	 bl,DESC_TAB.DESC_BASE3[si] ; Include high-order byte
	 ror	 ebx,8		; Shift back

	 sub	 ebx,eax	; Relocate the base

; Save 32-bit selector base back into GDT

	 mov	 DESC_TAB.DESC_BASE01[si],bx ; Save bytes 0 and 1
	 shr	 ebx,16 	; Shift high-order word to low-order
	 mov	 DESC_TAB.DESC_BASE2[si],bl ; Save byte 2
	 mov	 DESC_TAB.DESC_BASE3[si],bh ; Save byte 3

	 REGREST <si,ebx>	; Restore

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RELOC_DTE endp			; End RELOC_DTE procedure
	 NPPROC  RELOC_GDT -- Relocate The GDT Entries
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Relocate GDT entries.

On entry:

EAX	 =	 relocation factor (to be subtracted from the DTE's base)

|

	 sub	 DESC_TAB.DTE_IDT.DTR_BASE,eax

	 push	 DTE_CS2	; Pass selector
	 call	 RELOC_DTE	; Relocate the GDT entry

	 push	 DTE_DS 	; Pass selector
	 call	 RELOC_DTE	; Relocate the GDT entry

	 push	 DTE_DS3	; Pass selector
	 call	 RELOC_DTE	; Relocate the GDT entry

	 push	 DTE_PDT	; Pass selector
	 call	 RELOC_DTE	; Relocate the GDT entry

	 push	 DTE_CR3	; Pass selector
	 call	 RELOC_DTE	; Relocate the GDT entry

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RELOC_GDT endp			; End RELOC_GDT procedure
	 NPPROC  DISABLE_IMR -- Disable the 8259 Interrupt Mask Register
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable the 8259 interrupt mask register

This routine is called from real mode only.

|

	 REGSAVE <ax>		; Save register

	 in	 al,@IMR	; Get current value
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ

	 mov	 INTA01,al	; Save to restore later

	 mov	 al,0FFh	; Disable all interrupts
	 out	 @IMR,al	; Send to 8259

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jnz	 short DISABLE_IMR_EXIT ; Yes, so there's no slave controller

	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ

	 in	 al,@IMR2	; Get current value
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ

	 mov	 INTB01,al	; Save to restore later

	 mov	 al,0FFh	; Disable all interrupts
	 out	 @IMR2,al	; Reset in slave 8259
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ
DISABLE_IMR_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_IMR endp		; End DISABLE_IMR procedure
	 NPPROC  COPY_CFG -- Copy CFGFILE Data to Extended Memory
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Copy CFGFILE data to extended memory.

|

	 REGSAVE <eax,ecx,esi,edi,ds> ; Save registers

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it

; In order to read the value from low DOS memory, we remove the
; assume on ES

	 assume  es:nothing	; Tell the assembler about it

	 mov	 edi,PCFGFILE	; Get offset in PGROUP of CFGFILE data
	 movzx	 esi,CFG_SEG	; Get its segment
	 shl	 esi,4-0	; Convert from paras to bytes

	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 eax,edi	; Value to add (offset within PGROUP)

	 movzx	 ecx,CFG_CNT	; ECX = byte count of CFGFILE data (0 = none)
S32  rep movs	 <PGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy to extended memory

; Relocate the pointers and names

	 mov	 cx,CFG_LCNT	; Get # linked list entries
	 jcxz	 COPY_CFG_EXIT	; Jump if none
COPY_CFG_FIBS:
	 sub	 edi,type LFLG_STR ; Back off to previous entry

	 add	 PGROUP:[edi].LFLG_FNAM,eax ; Relocate the filename

	 cmp	 PGROUP:[edi].LFLG_NEXT,-1 ; Is there a next entry?
	 je	 short @F	; Jump if not

	 add	 PGROUP:[edi].LFLG_NEXT,eax ; Relocate next pointer
@@:
	 loop	 COPY_CFG_FIBS	; Jump if more linked list entries

; Relocate the flag list pointers

	 mov	 cx,@CFGLIST_LEN ; Number of flag lists
	 sub	 si,si		; Index starting entry
COPY_CFG_NEXTFLG:
	 cmp	 CFGLIST[si].LLST_DAT.LFLG_NEXT,-1 ; Is this list empty?
	 je	 short @F	; Jump if so

	 add	 CFGLIST[si].LLST_DAT.LFLG_NEXT,eax ; Relocate it
@@:
	 add	 si,size LLST_STR ; Skip to next
	 loop	 COPY_CFG_NEXTFLG ; Go around again

COPY_CFG_EXIT:
	 REGREST <ds,edi,esi,ecx,eax> ; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_CFG endp			; End COPY_CFG procedure
	 NPPROC  COPY_VDS -- Copy Previous VDS Table to Extended Memory
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Copy previous VDS table to extended memory.

|
	 REGSAVE <ecx,esi,edi,ds> ; Save registers

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it

; In order to read the value from low DOS memory, we remove the
; assume on ES

	 assume  es:nothing	; Tell the assembler about it

	 mov	 edi,PVDSTAB	; Get offset in PGROUP of previous VDS table

	 cmp	 edi,0		; Is there a secondary VDS table?
	 je	 short COPY_VDS_EXIT ; No, go

	 movzx	 esi,VDSTAB_SEG ; Get its segment
	 shl	 esi,4-0	; Convert from paras to bytes

	 mov	 ecx,VDSTAB_LEN ; Get the table length in bytes

	 assume  es:PGROUP	; Tell the assembler about it

S32  rep movs	 <PGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy to extended memory
COPY_VDS_EXIT:
	 REGREST <ds,edi,esi,ecx> ; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_VDS endp			; End COPY_VDS procedure
if @OEM_FLEXROM
	 NPPROC  FLEXROM_RELOC -- Relocate a FLEXed ROM's resources
	 assume  ds:PGROUP,es:AGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Relocate FlexROM Resources.

On entry:	BP	=	Index into FLEXROM table

|

	 pushad 		; Save all EGP registers
	 REGSAVE <es>		; Save segment register

; Loop through the interrupts checking the @ROMINT_RELOC flag
; If set, relocate to FLEX_DST

	 mov	 cx,NFLEXROMINTS	; CX = # interrupt vectors to check
	 xor	 esi,esi	; Initialize index into FLEXROMINTS
	 mov	 si,seg XGROUP	; Get the segment of FLEXROMINTS
	 shl	 esi,4-0	; Convert from paras to bytes
	 add	 esi,offset XGROUP:FLEXROMINTS ; Plus offset of the table
	 mov	 di,FLEXROM_TBL[bp].FLEX_SRC ; Get source ROM segment

; Determine if the interrupt from the FLEXROMINTS table is part of
; the current FLEXROM source (or alternate source).

FLEXROM_RELOC_NEXT:

	 cmp	 AGROUP:[esi].FLEXROMINT_SRC,di ; Is vector pointing to source?
	 je	 short @F		; Jump if so

	 test	 AGROUP:[esi].FLEXROMINT_FLAG,@ROMINT_VGA ; Izit a VGA entry?
	 jz	 short FLEXROM_RELOC_LOOP ; Jump if not

	 test	 FLEXROM_FLAG,@FR_SHDROM ; Is VGASWAP helping shadowROM?
	 jz	 short FLEXROM_RELOC_LOOP ; Jump if not

	 cmp	 VGA_ALTSEG1,di 	; Izit an alternate shadowed VGA entry?
	 je	 short @F		; Jump if so

	 cmp	 VGA_ALTSEG2,di 	; Izit an alternate shadowed VGA entry?
	 jne	 short FLEXROM_RELOC_LOOP ; Jump if not

@@:
	 cmp	 AGROUP:[esi].FLEXROMINT_SRC,@FLEX_UNUSED ; Unused entry?
	 je	 short FLEXROM_RELOC_LOOP ; Yes, skip

	 test	 AGROUP:[esi].FLEXROMINT_FLAG,@ROMINT_RELOC ; Need relocating?
	 jz	 short FLEXROM_RELOC_LOOP ; Jump if not

; Relocate the interrupt

	 movzx	 eax,AGROUP:[esi].FLEXROMINT_VEC.VSEG ; Get the segment value
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,AGROUP:[esi].FLEXROMINT_VEC.VOFF ; Get the offset ...
	 add	 ebx,eax	; AGROUP:EBX ==> ptr to relocate

	 mov	 ax,FLEXROM_TBL[bp].FLEX_DST ; Get destin ROM segment
	 mov	 AGROUP:[ebx].VSEG,ax ; Relocate it

FLEXROM_RELOC_LOOP:
	 cmp	 AGROUP:[esi].FLEXROMINT_NUM,04A8h ; Izit EGA Save pointer?
	 je	 short FLEXROM_RELOC_EGASAVE ; Jump if so (special case)

FLEXROM_RELOC_LOOP2:
	 add	 esi,size FLEXROMINT_STR ; Skip to next entry

	 loop	 FLEXROM_RELOC_NEXT ; Jump if more interrupts to check

	 jmp	 near ptr FLEXROM_RELOC_EXIT ; All done relocating

FLEXROM_RELOC_EGASAVE:

; Relocate the EGA save pointer values separately

	 assume  es:INTVEC	; Tell the assembler about it

; Get the EGA Save Pointer value

	 movzx	 eax,INT00_VEC.VSEG[04A8h] ; Get save pointer segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,INT00_VEC.VOFF[04A8h] ; Get the offset ...
	 add	 ebx,eax	; AGROUP:EBX ==> ptr to relocate

	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ax,FLEXROM_TBL[bp].FLEX_DST ; Get destin ROM segment
	 mov	 dx,di		; Get source ROM segment

; Relocate the Default Parameter Table (if appropriate)

	 mov	 di,AGROUP:[ebx].EGASAVE_VPT.VSEG ; Get pointer
	 call	 IZIT_SHDROM	; Izit ours?
	 jc	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].EGASAVE_VPT.VSEG,ax ; Restore to C000
@@:

; Relocate the Dynamic Save Area Pointer (if appropirate)

	 mov	 di,AGROUP:[ebx].EGASAVE_DYN.VSEG ; Get pointer
	 call	 IZIT_SHDROM	; Izit ours?
	 jc	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].EGASAVE_DYN.VSEG,ax ; Restore to C000
@@:

; Relocate the Alpha Mode Character Generator Pointer (if appropirate)

	 mov	 di,AGROUP:[ebx].EGASAVE_ALP.VSEG ; Get pointer
	 call	 IZIT_SHDROM	; Izit ours?
	 jc	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].EGASAVE_ALP.VSEG,ax ; Restore to C000
@@:

; Relocate the Graphics Mode Character Generator Pointer (if appropirate)

	 mov	 di,AGROUP:[ebx].EGASAVE_GRX.VSEG ; Get pointer
	 call	 IZIT_SHDROM	; Izit ours?
	 jc	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].EGASAVE_GRX.VSEG,ax ; Restore to C000
@@:

; Relocate the First Reserved Pointer (if appropirate)

	 mov	 di,AGROUP:[ebx].EGASAVE_RES1.VSEG ; Get pointer
	 call	 IZIT_SHDROM	; Izit ours?
	 jc	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].EGASAVE_RES1.VSEG,ax ; Restore to C000
@@:

; Relocate the Second Reserved Pointer (if appropirate)

	 mov	 di,AGROUP:[ebx].EGASAVE_RES2.VSEG ; Get pointer
	 call	 IZIT_SHDROM	; Izit ours?
	 jc	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].EGASAVE_RES2.VSEG,ax ; Restore to C000
@@:


; Relocate the VGA Secondary Save Pointer (if appropirate)

	 cmp	 AGROUP:[ebx].EGASAVE_2ND.VSEG,0 ; Izit present?
	 je	 near ptr FLEXROM_RELOC_LOOP2 ; Jump if not (next ROM)

	 mov	 di,AGROUP:[ebx].EGASAVE_2ND.VSEG ; Get pointer
	 call	 IZIT_SHDROM	; Izit ours?
	 jc	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].EGASAVE_2ND.VSEG,ax ; Restore to C000
@@:

; Address the VGA Secondary Save Pointer

	 movzx	 eax,AGROUP:[ebx].EGASAVE_2ND.VSEG ; Get segment of secondary table
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,AGROUP:[ebx].EGASAVE_2ND.VOFF ; Get offset ...
	 add	 ebx,eax	; AGROUP:EBX ==> ptr to relocate

	 mov	 ax,FLEXROM_TBL[bp].FLEX_DST ; Get destin ROM segment

; Relocate the Display Combination Code Pointer (if appropirate)

	 mov	 di,AGROUP:[ebx].VGASAVE_DCC.VSEG ; Get pointer
	 call	 IZIT_SHDROM	; Izit ours?
	 jc	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].VGASAVE_DCC.VSEG,ax ; Restore to C000
@@:

; Relocate the Second Alpha Mode Character Generator Pointer (if appropirate)

	 mov	 di,AGROUP:[ebx].VGASAVE_ALP.VSEG ; Get pointer
	 call	 IZIT_SHDROM	; Izit ours?
	 jc	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].VGASAVE_ALP.VSEG,ax ; Restore to C000
@@:

; Relocate the User Pallette Profile Table Pointer (if appropirate)

	 mov	 di,AGROUP:[ebx].VGASAVE_PAL.VSEG ; Get pointer
	 call	 IZIT_SHDROM	; Izit ours?
	 jc	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].VGASAVE_PAL.VSEG,ax ; Restore to C000
@@:
	 jmp	 near ptr FLEXROM_RELOC_LOOP2 ; Do for next resource

FLEXROM_RELOC_EXIT:

	 REGREST <es>		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FLEXROM_RELOC endp		; End FLEXROM_RELOC procedure
endif				; IF @OEM_FLEXROM
if @OEM_FLEXROM
	 NPPROC  IZIT_SHDROM -- Does DI:0 belong to a shadow ROM?
	 assume  ds:PGROUP,es:AGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Determine if DI is segment of an alternate shadowed video ROM

On entry:
DX	=	Source of FLEXed video ROM
DI	=	Segment of ROM inquestion

On exit:
CF	=	0 if DI is the segment of an alternate video ROM
		1 if not
|

	 cmp	 dx,di		; Is it the video source?
	 je	 short IZIT_SHDROM_CLC ; Jump if so

	 test	 FLEXROM_FLAG,@FR_SHDROM ; Do we have a shadow RAM?
	 jz	 short IZIT_SHDROM_STC ; Jump if not

	 cmp	 VGA_ALTSEG1,di ; Izit a shadowed VGA entry?
	 je	 short IZIT_SHDROM_CLC ; Jump if so

	 cmp	 VGA_ALTSEG2,di ; Izit a shadowed VGA entry?
	 je	 short IZIT_SHDROM_CLC ; Jump if so

IZIT_SHDROM_STC:
	 stc			; Indicate DI is not a video ROM
	 jmp	 short IZIT_SHDROM_EXIT ; Join common exit code

IZIT_SHDROM_CLC:
	 clc			; Indicate DI is a video ROM

IZIT_SHDROM_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_SHDROM endp		; End IZIT_SHDROM procedure
endif				; IF @OEM_FLEXROM
if @OEM_DPMI
	 NPPROC  INIT_DPMITAB -- Initialize DPMI Tables
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

Initialize DPMI tables

On entry:

Paging is enabled

|

	 REGSAVE <eax,ecx,edx,edi,es> ; Save registers

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 near ptr INIT_DPMITAB_EXIT ; Jump if so

; Initialize the DPMI LDT to all zero

	 mov	 edi,PDPMILDT	; ES:EDI ==> offset in PGROUP of DPMI LDT
	 mov	 ecx,LDT_SIZ	; Get byte size of DPMI LDT (/8)
	 shr	 ecx,2-0	; Convert from bytes to dwords
	 xor	 eax,eax	; A convenient zero
     rep stos	 PGROUP:[edi].EDD ; Fill the LDT with zeros

; Calculate the linear address of memory mapped by the first DPMI page directory

	 mov	 eax,DPMIPDIR_CNT ; Get # page directories to use
	 inc	 eax		; Plus one to avoid conflict with SWAT's PDIR
	 shl	 eax,22-0	; Convert from 4MB to bytes
	 mov	 edi,2*1024*1024*1024 ; Back off from 2GB
	 sub	 edi,eax	; Subtract to get the linear address (/4MB)
	 mov	 LaDPMIPDIRMEM,edi ; Save for later use

; Fill in DPMI page directories entries in the PDIR

	 mov	 eax,LaDPMIPDIR ; Get the linear address of the first DPMI
				; page directory (/4KB)
	 shr	 eax,12-0	; Convert from bytes to 4KB
	 mov	 eax,OFFPDT[eax*4] ; Get corresponding physical address
	 or	 eax,@PTE_URP	; Mark as User/Read-write/Present

; EAX	 =	 physical address of the first DPMI page directory

	 mov	 ecx,DPMIPDIR_CNT ; Get # page directories to use

;;;;;;;; mov	 edi,LaDPMIPDIRMEM ; Get linear address of memory mapped by
				; first DPMI page directory (/4MB)
	 shr	 edi,(22-2)-0	; Convert from bytes to 4MB in dwords
	 add	 edi,OFFCR3	; ES:EDI ==> page directory for 1st DPMI PDIR
@@:
S32	 stos	 PGROUP:[edi].EDD ; Save the new physical address
	 add	 eax,CON4KB	; Skip to next PTE

	 loopd	 @B		; Jump if more PDIRs to fill in

; Initialize the DPMI page directories with one-to-one PTEs
; and with the User/Supervisor bit clear to indicate that
; they are unallocated

	 mov	 edi,LaDPMIPDIR ; Get the linear address of the first DPMI PDIR
	 sub	 edi,PRGBASE	; Less our program base to get offset in PGROUP
	 mov	 ecx,DPMIPDIR_CNT ; Get # page directories to use
	 shl	 ecx,22-12	; Convert from 4MB to 4KB
				; to get # PTEs covered by our PDIRs
	 mov	 eax,LaDPMIPDIRMEM ; Get linear address of memory mapped by
				; first DPMI page directory (/4MB)
	 or	 eax,@PTE_URP	; Mark as User/Read-write/Present
	 and	 eax,not (mask $PTE_US) ; Mark as unallocated
@@:
S32	 stos	 PGROUP:[edi].EDD ; Save the new physical address
	 add	 eax,CON4KB	; Skip to next PTE

	 loopd	 @B		; Jump if more PTEs to fill in

; Initialize the DPMI memory handle structure to all zero

	 mov	 edx,PVMTSS	; Get offset in PGROUP of 1st TSS
	 mov	 ecx,DPMIHNDL_CNT ; Get initial # memory handles
	 mov	 PGROUP:[edx].DPTSS_DPMIHNDL_CNT,ecx ; Save for later use
	 imul	 ecx,type DPMIHNDL_STR ; Times # bytes per handle
	 mov	 edi,DPMIHNDL_OFF ; Offset in PGROUP of initial DPMI memory
				; handle table
	 mov	 eax,edi	; Copy to set linear address
	 add	 eax,PRGBASE	; Convert from offset to linear address
	 mov	 PGROUP:[edx].DPTSS_LaDPMIHNDL,eax ; Save for later use
	 xor	 al,al		; A convenient zero
     rep stos	 PGROUP:[edi].LO ; Zero the DPMI memory handle structure

; Save linear address of DPMI LDT as Read-Write data descriptor at PL3

	 mov	 eax,PDPMILDT	; Get the offset in PGROUP of the LDT
	 add	 eax,PRGBASE	; Convert from offset to linear address
	 mov	 PGROUP:[edx].DPTSS_LaLDT,eax ; Save for later use

	 mov	 ecx,LDT_SIZ	; Get byte size of DPMI LDT (/8)
	 mov	 PGROUP:[edx].DPTSS_LDT_SIZ,ecx ; Save for later use

	 push	 ecx		; Pass size of area in bytes
	 push	 DPMI_DATA	; Pass access rights byte
	 push	 LDTE_DATALDT3	; Pass descriptor to set
	 call	 SET_GDT	; Set the GDT to EAX base
INIT_DPMITAB_EXIT:
	 REGREST <es,edi,edx,ecx,eax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_DPMITAB endp		; End INIT_DPMITAB procedure
endif				; IF @OEM_DPMI
	 NPPROC  SET_SIRBCUR -- Set Software Interrupt Re-direction Count Values
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set software interrupt re-direction count values

|

	 mov	 edi,LaSIRBCUR	; AGROUP:EDI ==> default table
	 xor	 eax,eax	; Initial value
	 mov	 ecx,(256/8)/4	; Get size of table in dwords
	 push	 edi		; Save over STOS
     rep stos	 AGROUP:[edi].EDD ; Zero the table
	 pop	 edi		; Restore

; Set SIRB table at AGROUP:EDI using SIRB_MAC

	 SIRB_MAC 15		; INT  15h - BIOS
	 SIRB_MAC 21		; ...  21h - DOS
	 SIRB_MAC 2F		; ...  2Fh - XMS

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 short @F	; Jump if so

	 SIRB_MAC 31		; ...  31h - DPMI
@@:
	 SIRB_MAC 4B		; ...  4Bh - VDS
	 SIRB_MAC 67		; ...  67h - EMS/VCPI

	 SIRB_MAC 01		; ...  01h - Debugger
	 SIRB_MAC 02		; ...  02h - NMI
	 SIRB_MAC 03		; ...  03h - Debugger
	 SIRB_MAC 68		; ...  68h - WDEB

	 SIRB_MAC 81		; ...  81h - Lotus 1-2-3 bug
	 SIRB_MAC 82		; ...  82h - ...
	 SIRB_MAC 83		; ...  83h - ...
	 SIRB_MAC 84		; ...  84h - ...
	 SIRB_MAC FE		; ... 0FEh - Old VCPI
	 SIRB_MAC FF		; ... 0FFh - HARDINT/DPMI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_SIRBCUR endp		; End SET_SIRBCUR procedure
	 NPPROC  INIT_SIRBCUR -- Initialize SIRBCUR Table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize SIRBCUR table

On entry:

Paging is enabled.
If SWAT is present, enable debugging extensions.

|

	 REGSAVE <eax,es>	; Save registers

; If this is a B0-step Pentium CPU or an A1-step SL Enhanced 486, it
; doesn't implement VME correctly, so we masked off $CPUFET_VME at
; CHECK_CPUID time.

	 test	 CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	 jz	 short INIT_SIRBCUR_EXIT ; Jump if not

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

; Set default SIR count values for INTs we must intercept in PM

	 call	 SET_SIRBCUR	; Set 'em

	 FCALL	 SIRBCUR2B	; Copy SIRBCUR values to SIRB

	 mov	 bx,LCL_FLAG	; Get flags with @LCL_SWAT bit
	 CPDPM	 'Enabling CR4.VME,  LCL_FLAG=%BX CS|IP=%CS|%IP  DS=%DS  ES=%ES'

	 MOVSPR  eax,cr4	; Get CPU extensions register

	 or	 eax,mask $VME	; Enable Virtual Mode Extensions

	 test	 bx,@LCL_SWAT	; Is 386SWAT present?
	 jz	 short INIT_SIRBCUR_XSWATDE ; Jump if not

	 test	 CPUFET_FLAG,mask $CPUFET_IOBRK ; Debugging extensions present?
	 jz	 short INIT_SIRBCUR_XSWATDE ; Jump if not

	 or	 eax,mask $DE	; Enable debugging extensions
	 or	 FLG_GET_DRn,(@BIT5 or @BIT4) ; Enable DR4-5
	 or	 FLG_SET_DRn,(@BIT5 or @BIT4) ; ...
INIT_SIRBCUR_XSWATDE:
	 MOVSPR  cr4,eax	; Tell the CPU about it
INIT_SIRBCUR_EXIT:
	 REGREST <es,eax>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_SIRBCUR endp		; End INIT_SIRBCUR procedure

NCODE	 ends			; End NCODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_EVM_ECODE
@QMAX_EVM_ECODE:		; Mark module start in .MAP file

	 extrn	 INIT_PROT:near
	 extrn	 FLUSH_TLB:near
if @OEM_WIN3
if @OEM_HIFILL
	 extrn	 OPENHIGH:near
endif				; IF @OEM_HIFILL
endif				; IF @OEM_WIN3
	 FPPROC  SIRBCUR2B -- Copy SIRBCUR Values To SIRB
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy SIRBCUR values to SIRB

|

	 REGSAVE <ecx,esi,edi>	; Save registers

	 mov	 ecx,(256/8)/4	; Get # dwords in SIRB/SIRBCUR tables
	 mov	 esi,LaSIRBCUR	; Get linear address of current table

	 mov	 edi,PIOBIT	; Get offset in PGROUP of I/O bit map
	 sub	 edi,256/8	; Back off to start of the SIR bitmap
	 add	 edi,PRGBASE	; Plus program base to get linear address
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy in new table

	 REGREST <edi,esi,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SIRBCUR2B endp			; End SIRBCUR2B procedure
	 NPPROC  OUTCMOS -- Out To CMOS, Conditional Read
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Out to CMOS, conditional read.

Note that this routine is bimodal.

This routine should not be interrupted between the OUT and IN.

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 out	 dx,al		; Send to CMOS

	 cmp	 dx,@CMOS_CMD	; Izit an AT?
	 jne	 short @F	; Jump if not

	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Ensure OUT is followed by IN
@@:
	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OUTCMOS  endp			; End OUTCMOS procedure
	 NPPROC  DISABLE_NMI -- Disable NMI
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable NMI

Note that this routine is bimodal.

|

	 pushf			; Save flags
	 cli			; Ensure interrupts disabled

	 REGSAVE <ax,dx>	; Save for a moment

; Disable NMI

	 mov	 dx,NMIPORT	; Get NMI clear I/O port
	 mov	 al,NMIDIS	; ...	  disable value
	 call	 OUTCMOS	; Out to CMOS, conditional read

	 REGREST <dx,ax>	; Restore
	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_NMI endp		; End DISABLE_NMI procedure
	 NPPROC  ENABLE_NMI -- Enable NMI, Clear Parity Latches
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable NMI, clear parity latches.

Note that this routine is bimodal.

|

	 pushf			; Save flags
	 cli			; Ensure interrupts disabled

	 REGSAVE <ax,dx>	; Save for a moment

; Clear the parity latches

	 call	 CLR_PARITY	; Clear any parity errors

; Enable the NMI latch

	 mov	 dx,NMIPORT	; Get NMI clear I/O port
	 mov	 al,NMIENA	; ...	  enable value
	 call	 OUTCMOS	; Out to CMOS, conditional read

	 REGREST <dx,ax>	; Restore
	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_NMI endp 		; End ENABLE_NMI procedure
	 NPPROC  CLR_PARITY -- Clear Parity Latches
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the parity latches

Note that this routine is bimodal.

|

	 REGSAVE <ax>		; Save register

if @OEM_SOFT
	 test	 CMD_FLAG,@CMD_XPARITY ; Was NOPARITY specified?
	 jnz	 short CLR_PARITY_EXIT ; Jump if so
endif				; IF @OEM_SOFT

	 mov	 ah,NMIMASK	; Get parity mask
	 in	 al,@8255_B	; Get the parity latches
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 or	 al,ah		; Toggle parity check latches off
	 out	 @8255_B,al	; Tell the system about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 xor	 al,ah		; Toggle parity check latches on
	 out	 @8255_B,al	; Tell the system about it
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

CLR_PARITY_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLR_PARITY endp 		; End CLR_PARITY procedure
	 NPPROC  COPY_GDT -- Copy GDT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy GDT from source selector to destination selector.

|

COPY_GDT_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
COPY_GDT_SRC dw  ?		; Source selector
COPY_GDT_DST dw  ?		; Destin selector

COPY_GDT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <cx,si,di,ds,es> ; Save registers

	 mov	 ds,[ebp].COPY_GDT_SRC ; Get source selector
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 es,[ebp].COPY_GDT_DST ; Get destin selector
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,(size XDTE_STR)/4 ; CX = # dwords in GDT
	 lea	 si,DESC_TAB	; DS:SI ==> source GDT
	 mov	 di,si		; ES:DI ==> destin GDT

	 cld			; Ensure direction flag up
S16  rep movsd			; Move it into place

	 REGREST <es,ds,di,si,cx> ; Restore
	 assume  ds:nothing,es:nothing

	 pop	 ebp		; Restore

	 ret	 2*2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_GDT endp			; End COPY_GDT procedure
	 NPPROC  COPY_IDT -- Copy IDT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy IDT from source selector to destination selector.

|

COPY_IDT_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
COPY_IDT_SRC dw  ?		; Source selector
COPY_IDT_DST dw  ?		; Destin selector

COPY_IDT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <cx,si,di,ds,es> ; Save registers

	 mov	 ds,[ebp].COPY_IDT_SRC ; Get source selector
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 es,[ebp].COPY_IDT_DST ; Get destin selector
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,IDT_DESC_LEN ; CX = # bytes in IDT
	 shr	 cx,2		; Convert from bytes to dwords
	 lea	 si,IDT_DESC	; DS:SI ==> source IDT
	 mov	 di,si		; ES:DI ==> destin IDT

	 cld			; Ensure direction flag up
S16  rep movsd			; Move it into place

	 REGREST <es,ds,di,si,cx> ; Restore
	 assume  ds:nothing,es:nothing

	 pop	 ebp		; Restore

	 ret	 2*2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_IDT endp			; End COPY_IDT procedure
	 NPPROC  PAGE_ON -- Turn On Paging
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Tell the CPU we're using paging

Don't try to single-step through this routine if
PaPRGBASE .ne. PRGBASE.

|

	 REGSAVE <eax>		; Save registers

	 push	 DTE_DSXP	; Get physical extended memory data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

; Copy the GDT from low to high physical memory

	 push	 DTE_DSXP	; Use physical extended memory data selector
	 push	 DTE_SS 	; Use low DOS memory selector as source
	 call	 COPY_GDT	; Copy GDT from source to destination

; Switch GDT entries in high physical memory to new linear addresses

	 mov	 eax,PaPRGBASE	; Get old program base address
	 sub	 eax,PRGBASE	; Less new one
	 call	 RELOC_GDT	; Relocate 'em

; Copy the IDT from low to high physical memory

	 push	 DTE_DSXP	; Use physical extended memory data selector
	 push	 DTE_SS 	; Use low DOS memory selector as source
	 call	 COPY_IDT	; Copy IDT from source to destination

	 mov	 eax,LCL_CR3	; Get contents of CR3
	 mov	 cr3,eax	; Set page descriptor base register

; Tell the 386 we're paging

	 mov	 eax,cr0	; Get current CR0
	 or	 eax,mask $PG	; Turn on page bit
	 mov	 cr0,eax	; Enable paging

; Flush the pre-fetch instruction queue after setting paging on

	 jmp	 short $+2

	 assume  ds:nothing	; Tell the assembler about it

; Ensure the GDTR/IDTR points to the one in high linear memory

	 LGDTD	 PGDT_LHI
	 LIDTD	 PIDT_LHI

; Reset segment registers to flush descriptor caches

	 mov	 ax,DTE_DS	; Get data selector
	 mov	 ds,ax		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it
	 mov	 es,ax		; ...
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 ax,fs		; Get current value
	 mov	 fs,ax		; Re-specify
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 ax,gs		; Get current value
	 mov	 gs,ax		; Re-specify
	 assume  gs:nothing	; Tell the assembler about it

	 mov	 SEL_GDT,DTE_DS ; Note new selector which maps GDT

; Set in low DOS memory as well in case anyone calls SET_GDT
; before we return to VM86 mode

	 push	 ds		; Save for a moment

	 mov	 ax,DTE_SS	; Get low DOS memory selector
	 mov	 ds,ax		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 SEL_GDT,DTE_DS ; Note new selector which maps GDT

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 call	 LINPHYS	; Check file load DTEs for linear/physical

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PAGE_ON  endp			; End PAGE_ON procedure
	 FPPROC  ENTERVM -- Enter Virtual 8086 Mode
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter Virtual 8086 mode

This routine is called from low DOS memory with a skeleton
GDT and no IDT.

It must load the real GDT and IDT and return to virtual mode.
The caller's stack contains the FAR VM86 return address.

Note that SS contains the real mode value although the
invisible descriptor cache is still valid.

Due to the Windows selector fixup apparatus, no FIXICALL or FIXIJMP macros
may be used before the call to FIXUP_ISELS below.

|

WIN3_STK struc

WIN3_EBP dd	 ?		; Caller's EBP
WIN3_EAX dd	 ?		; ...	   EAX
WIN3_VEC dd	 ?		; ...	   CS:IP (VM86)

WIN3_STK ends

	 PUSHD	 0		; Ensure IOPL=NT=DF=0
	 popfd

	 push	 eax		; Save for a moment
	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

; Ensure the IDTR/GDTR points to the ones in high linear memory

	 LIDTD	 PIDT_LHI	; Respecify IDT
	 LGDTD	 PGDT_LHI	; Respecify GDT

; Far jump to set CS so we can do far calls
; This FIJMP is used instead of FIXIJMP because it is always executed under
; 386MAX's GDT, etc. and is never translated by the Windows fixup apparatus.

	 FIJMP	 PGROUP:@F,DTE_CS2 ; Far jump to set access rights
@@:
	 PUSHD	 gs		; Save current segment registers as dwords
	 PUSHD	 fs		; ...
	 PUSHD	 ds		; ...
	 PUSHD	 es		; ...
	 PUSHD	 ss		; Put return stack segment onto stack

; Now that we've saved the real mode SS,
; setup a valid descriptor for the stack selector

	 push	 DTE_DSLO	; Get low DOS memory descriptor
	 pop	 ss		; Address it
	 assume  ss:nothing	; Tell the assembler about it

	 lea	 eax,[ebp].WIN3_VEC + (size WIN3_VEC) ; Point to end of stack
	 push	 eax		; Put return stack offset ...

; VM bit set, NT bit clear, IOPL at @VMIOPL, CF=0

	 push	 dword ptr ((mask $VMHI) or (@VMIOPL shl $IOPL))

	 movzx	 eax,[ebp].WIN3_VEC.VSEG ; Get caller's return CS
	 push	 eax		; Put onto stack

	 movzx	 eax,[ebp].WIN3_VEC.VOFF ; Get caller's return IP
	 push	 eax		; Put onto stack

; Initialize all non-stack segment registers so INIT_PROT can push/pop them

	 xor	 ax,ax		; A convenient initial value
	 mov	 ds,ax		; Ensure valid
	 mov	 es,ax		; ...
	 mov	 fs,ax		; ...
	 mov	 gs,ax		; ...

; Call initialize protected mode entry point in all API files loaded

	 call	 INIT_PROT	; Call 'em

; Set extended memory data values

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 gs		; Address it
	 assume  gs:AGROUP	; Tell the assembler about it

	 push	 DTE_DS 	; Get high memory selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

; Set the LDTR to a known value

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 lldt	 PGROUP:[eax].TSS_LDT ; Set LDTR

if @OEM_WIN3
	 mov	 al,0		; Code to mark as no longer OFF from Win3 callback
	 xchg	 al,LOWWIN3_CB	; Mark it

	 cmp	 al,0		; Wuzit ON?
	 je	 short ENTERVM_XWIN3 ; Jump if not

; N.B. No FIXICALL or FIXIJMP macros may be used before the following call

	 REGSAVE <es,fs,gs>	; Save registers

	 push	 DTE_DSIG	; Get our writeable IGROUP selector
	 pop	 es		; Address it via ES
	 assume  es:IGROUP	; Tell the assembler about it

	 push	 DTE_DSJG	; Get our writeable JGROUP selector
	 pop	 fs		; Address it via FS
	 assume  fs:JGROUP	; Tell the assembler about it

	 push	 DTE_FIXUP	; Get our fixup selector
	 pop	 gs		; Address it via GS
	 assume  gs:FGROUP	; Tell the assembler about it

				; DS = data selector for PGROUP
				; ES = data selector for IGROUP
				; FS = data selector for JGROUP
				; GS = data selector for FGROUP
	 push	 DTE_CS2	; Pass code selector for PGROUP
	 push	 DTE_CSIG	; Pass code selector for IGROUP
	 push	 DTE_CSJG	; Pass code selector for JGROUP
	 push	 DTE_DS3 or (@DPMI_CPL shl $PL) ; PGROUP data selector at PL3
	 push	 DTE_D4GB3 or (@DPMI_CPL shl $PL) ; AGROUP data selector at PL3
	 FCALLD  FIXUP_ISELS	; Fixup FIXICALL and FIXIJMP selectors

	 REGREST <gs,fs,es>	; Restore registers
	 assume  es:nothing, fs:nothing, gs:AGROUP ; Tell the assembler

	 FCALL	 ENABLE_P5	; Enable P5-specific features

	call	PATCH_PnP	; Patch into the PnP struc in BIOS

; Note: We have to call DMA_WIN3 before MAP_WIN3 because the MAP_WIN3
;	code will wreck the PTEs that were swapped to get the DMA buffer
;	out of conventional memory.

	 FICALL  JGROUP:DMA_WIN3,DTE_CSJG ; Swap DMA buffer if in conv memory
	 FICALL  JGROUP:MAP_WIN3,DTE_CSJG ; Re-map EMS as per Windows 3 exit state
	 FICALL  JGROUP:CAPOVR_WIN3,DTE_CSJG ; Re-capture high DOS memory

; Prime the WIN3_VERSION for the next IOCTL from WIN.COM

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSHI	; Get high DOS memory descriptor
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 WIN3_VERSION,0 ; Get major/minor version #

	 pop	 ds		; Restore to extended memory PGROUP data selector
	 assume  ds:PGROUP	; Tell the assembler about it

if @OEM_HIFILL

; If high DOS memory was opened up before we started Windows,
; open it again

	 cmp	 OLDHDM,@HDM_CLOS ; Izit to remain closed off?
	 je	 short @F	; Jump if so

	 call	 OPENHIGH	; Open up high DOS memory
@@:
endif				; IF @OEM_HIFILL
ENTERVM_XWIN3:
endif				; IF @OEM_WIN3
; Set low DOS memory values

	 push	 ds		; Save for a moment

	 push	 DTE_DSLO	; Get low DOS memory descriptor
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

if @OEM_WIN3
	 mov	 LOWWIN3_CB,0	; Mark as no longer OFF from Windows 3 callback
endif				; IF @OEM_WIN3
	 or	 GLB_FLAG,@GLB_ON ; Note that we're now ON

	 pop	 ds		; Restore to extended memory PGROUP data selector
	 assume  ds:PGROUP	; Tell the assembler about it

; Set high DOS memory values

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSHI	; Get high DOS memory descriptor
	 assume  ds:PGROUP	; Tell the assembler about it

if @OEM_WIN3
	 mov	 LOWWIN3_CB,0	; Mark as no longer OFF from Windows 3 callback
endif				; IF @OEM_WIN3

	 FIXICALL JGROUP:ACTIVATE_HOOK13,DTE_CSJG ; Activate the HOOK13 byte if inactive

; Transfer the AUTO bit from low/high DOS memory to extended memory

	 or	 GLB_FLAG,@GLB_ON ; Note that we're now ON
	 mov	 ax,GLB_FLAG	; Get low memory global flags

	 pop	 ds		; Restore to extended memory PGROUP data selector
	 assume  ds:PGROUP	; Tell the assembler about it

	 and	 ax,@GLB_AUTO or @GLB_X1MB ; Isolate the low memory bits
	 and	 GLB_FLAG,not @GLB_AUTO or @GLB_X1MB ; Clear the high memory bits
	 or	 GLB_FLAG,ax	; Transfer the low memory bits

; Turn off busy bit in our TSS

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 bx,PGROUP:[eax].DPTSS_SEL ; Get the TSS selector
	 and	 bx,not (mask $PL) ; Clear PL bits
	 and	 DESC_TAB.DESC_ACCESS[bx],not (mask $DS_BUSY)

; Tell the 386 about TSS

	 ltr	 bx		; Tell 386 about it

; Ensure the keyboard is reset

	 call	 RESET_KEYB

; Clear any parity errors which might have occurred

	 and	 GLB_FLAG,not @GLB_NMI
	 call	 ENABLE_NMI	; Enable NMI, clear the parity latches

if @OEM_EMS

; Note in low memory whether or not INT 67h is intercepted

	 mov	 ds,SEL_DSHI	; Get high DOS memory descriptor
	 assume  ds:PGROUP	; Tell the assembler about it

	 cmp	 EMMSIZE,0	; Any EMS memory to manage?
	 je	 short REENTERVM1 ; Not this time

	 or	 GLB_FLAG,@GLB_I67 ; Mark as intercepted
	 mov	 DEVDRV.DD_NAME[0],'E' ; Mark as EMS manager installed

	 REGSAVE <ax,ds>	; Save for a moment

	 push	 DTE_DS 	; Get high memory selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ax,cs		; Copy current selector

	 cmp	 ax,IDT_DESC.IDT_SELECT[67h*type IDT_STR] ; Same as before?
	 jne	 short @F	; No, so don't change the offset

	 mov	 IDT_DESC.IDT_OFFLO[67h*type IDT_STR],offset cs:INT67
@@:
	 REGREST <ds,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
REENTERVM1:
endif				; IF @OEM_EMS
	 or	 GLB_FLAG,@GLB_ON ; Note that we're now ON

if @OEM_VDS

; Set DMA services enabled bit

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 gs		; Address it
	 assume  gs:BIOSDATA	; Tell the assembler about it

	 or	 VDS[400h],@VDS_ENA ; Mark as enabled
endif				; IF @OEM_VDS
	 mov	 eax,[ebp].WIN3_EAX ; Restore caller's EAX
	 mov	 ebp,[ebp].WIN3_EBP ; ...	       EBP

; Return to original routine and enable VM 8086 mode

	 iretd			; Return to original program in VM mode

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENTERVM  endp			; End ENTERVM procedure
if @OEM_WIN3
	 FPPROC  FIXUP_ISELS -- Fixup Selectors in Immediate CALLs and JMPs
	 assume  ds:PGROUP,es:IGROUP,fs:nothing,gs:FGROUP,ss:nothing
COMMENT|

Fixup Selectors in Immediate CALLs and JMPs.
Called directly by the VxD.

N.B. Because it is called by the VxD, this is an FCALLD procedure.
SS isn't PGROUP.

On entry:

DS	 =	 New data selector for PGROUP
ES	 =	 New data selector for IGROUP
FS	 =	 New data selector for JGROUP
GS	 =	 New data selector for FGROUP

On the stack (pushed in this order):
	 New PGROUP code selector
	 New IGROUP code selector
	 New JGROUP code selector
	 New PGROUP data selector at PL3
	 New AGROUP data selector at PL3

On exit:

|

FIXUP_ISELS_STR struc		; Structure to access procedure arguments

	 dd	 ?		; Caller's EBP
	 dd	 ?		; Caller's EIP
	 dd	 ?		; Caller's CS w/ filler
FIXUP_ISELS_4GB3  dw  ? 	; New AGROUP data selector at PL3
FIXUP_ISELS_DS3   dw  ? 	; New PGROUP data selector at PL3
FIXUP_ISELS_JGRCS dw  ? 	; New code selector for JGROUP
FIXUP_ISELS_IGRCS dw  ? 	; New code selector for IGROUP
FIXUP_ISELS_PGRCS dw  ? 	; New code selector for PGROUP

FIXUP_ISELS_STR ends		; End FIXUP_ISELS_STR structure

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ax,cx,edx,si,es> ; Save caller's registers

	 cld			; Forward for string ops in FIXUP_SUB

; Update the selector variables

	 mov	 ax,[ebp].FIXUP_ISELS_DS3 ; New PGROUP data selector at PL3
	 mov	 ISEL_DS3,ax	; Update it

	 mov	 ax,[ebp].FIXUP_ISELS_4GB3 ; New AGROUP data selector at PL3
	 mov	 ISEL_4GB3,ax	; Update it in IGROUP
	 mov	 SEL_4GB3,ax	; Update it in PGROUP

; IGROUP adjusted first because ES is already set

	 mov	 edx,IGRSIZE	; Size of IGROUP (varies with the NODPMI option)
	 lea	 cx,FIXTABZI	; FGROUP:CX ==> end of IGROUP fixup table
	 lea	 si,FIXTAB_IGROUP ; FGROUP:SI ==> IGROUP fixup table
	 call	 FIXUP_SUB	; Fixup the selectors in JGROUP

	 mov	 edx,-1 	; Size of PGROUP	FIXME WRL
	 lea	 cx,FIXTABZP	; FGROUP:CX ==> end of PGROUP fixup table
	 lea	 si,FIXTAB_PGROUP ; FGROUP:SI ==> PGROUP fixup table

	 mov	 ax,ds		; Pass writeable selector to PGROUP
	 mov	 es,ax		; ... in ES
	 assume  es:nothing	; Tell the assembler

	 call	 FIXUP_SUB	; Fixup the selectors in PGROUP

	 mov	 edx,JGRSIZE	; Size of JGROUP
	 lea	 cx,FIXTABZJ	; FGROUP:CX ==> end of JGROUP fixup table
	 lea	 si,FIXTAB_JGROUP ; FGROUP:SI ==> JGROUP fixup table

	 mov	 ax,fs		; Pass writeable selector to JGROUP
	 mov	 es,ax		; ... in ES
	 assume  es:nothing	; Tell the assembler

	 call	 FIXUP_SUB	; Fixup the selectors in JGROUP

	 mov	 ax,[ebp].FIXUP_ISELS_PGRCS ; New code selector for PGROUP
	 mov	 FIXUP_LAST_CS2,ax ; Remember new PGROUP selector

	 mov	 ax,[ebp].FIXUP_ISELS_IGRCS ; New code selector for IGROUP
	 mov	 FIXUP_LAST_CSIG,ax ; Remember new IGROUP selector

	 mov	 ax,[ebp].FIXUP_ISELS_JGRCS ; New code selector for JGROUP
	 mov	 FIXUP_LAST_CSJG,ax ; Remember new JGROUP selector

	 REGREST <es,si,edx,cx,ax> ; Restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 pop	 ebp		; Restore previous stack frame

	 RETFD	 <(type FIXUP_ISELS_STR)-4*3> ; Return to caller (32-bit), popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
FIXUP_ISELS endp		; End FIXUP_ISELS procedure
endif				; IF @OEM_WIN3
if @OEM_WIN3
	 NPPROC  FIXUP_SUB -- Common Sub-procedure for FIXUP_ISELS
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:FGROUP,ss:nothing
COMMENT|

Fixup Selectors in Immediate CALLs and JMPs.

On entry:

CX	 ==>	 End of fixup table
SI	 ==>	 Start of fixup table
EDX	 =	 Size of segment being adjusted
ES	 =	 Writeable selector to group being adjusted

SS:EBP	 ==>	 FIXUP_ISELS_STR

|

	 REGSAVE <ax,cx,si,edi> ; Save caller's registers

	 sub	 edi,edi	; Kill high-order half for 32-bit compares

	 sub	 cx,si		; Length of table in bytes
	 shr	 cx,1		; Convert from length to # of entries
FIXSUB_NXT:
	 mov	 di,FGROUP:[si] ; Get next fixup offset
	 inc	 si		; Advance to next fixup
	 inc	 si		; ...

	 cmp	 edi,edx	; Is the fixup offset past the segment length?
	 jae	 short FIXSUB_LOOP ; Skip this fixup if so

	 mov	 ax,es:[di]	; Current selector at fixup

	 cmp	 ax,FIXUP_LAST_CS2 ; Izit currently refering to PGROUP?
	 je	 short FIXSUB_PG ; Jump to PGROUP code

	 cmp	 ax,FIXUP_LAST_CSIG ; Izit currently refering to IGROUP?
	 je	 short FIXSUB_IG ; Jump to IGROUP code

	 cmp	 ax,FIXUP_LAST_CSJG ; Izit currently refering to JGROUP?
	 je	 short FIXSUB_JG ; Jump to JGROUP code

	 jmp	 short FIXSUB_LOOP ; Skip this unrecognized selector

FIXSUB_JG:
	 mov	 ax,[ebp].FIXUP_ISELS_JGRCS ; New code selector for JGROUP

	 jmp	 short FIXSUB_STORE ; Rejoin common patch code

FIXSUB_IG:
	 mov	 ax,[ebp].FIXUP_ISELS_IGRCS ; New code selector for IGROUP

	 jmp	 short FIXSUB_STORE ; Rejoin common patch code

FIXSUB_PG:
	 mov	 ax,[ebp].FIXUP_ISELS_PGRCS ; New code selector for PGROUP

;;;;;;	 jmp	 short FIXSUB_STORE ; Rejoin common patch code

FIXSUB_STORE:
S16	 stosw			; Patch the selector at ES:DI

FIXSUB_LOOP:
	 loop	 FIXSUB_NXT	; Loop until all the entries are adjusted

	 REGREST <edi,si,cx,ax> ; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
FIXUP_SUB endp			; End FIXUP_SUB procedure
endif				; IF @OEM_WIN3
	 FPPROC  ENABLE_P5 -- Enable P5-specific features
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable Machine Check Exception and Virtual Mode Exception bits.

|

	 REGSAVE <eax,ebx>	; Save

	 mov	 ebx,CPUFET_FLAG ; Get flags
	 test	 ebx,@CPUFET_VME or @CPUFET_MCE ; Do we need to enable
				; VME or MCE?
	 jz	 short ENAP5_EXIT ; Jump if not

	 MOVSPR  eax,cr4	; Get CPU extensions register

	 test	 ebx,@CPUFET_VME ; Virtual Mode Extensions supported?
	 jz	 short @F	;  Jump if not

	 or	 eax,mask $VME	; Enable Virtual Mode Extensions
@@:
	 test	 ebx,@CPUFET_MCE ; Is Machine Check Exception supported?
	 jz	 short @F	; Jump if not

	 or	 eax,mask $MCE	; Enable Machine Check Exception
@@:
	 MOVSPR  cr4,eax	; Tell the CPU about it
ENAP5_EXIT:
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_P5 endp			; End ENABLE_P5 procedure

	 FPPROC  DISABLE_P5 -- Disable P5-specific features
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable Machine Check Exception and Virtual Mode Exception bits.

|

	 REGSAVE <eax,ebx>	; Save

	 mov	 ebx,CPUFET_FLAG ; Get flags
	 test	 ebx,@CPUFET_VME or @CPUFET_MCE ; Do we need to disable
				; VME or MCE?
	 jz	 short DISP5_EXIT ; Jump if not

	 MOVSPR  eax,cr4	; Get CPU extensions register

	 test	 ebx,@CPUFET_VME ; Virtual Mode Extensions supported?
	 jz	 short @F	;  Jump if not

	 and	 eax,not (mask $VME) ; Disable Virtual Mode Extensions
@@:
	 test	 ebx,@CPUFET_MCE ; Is Machine Check Exception supported?
	 jz	 short @F	; Jump if not

	 and	 eax,not (mask $MCE) ; Enable Machine Check Exception
@@:
	 MOVSPR  cr4,eax	; Tell the CPU about it
DISP5_EXIT:
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_P5 endp 		; End DISABLE_P5 procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_EVM module

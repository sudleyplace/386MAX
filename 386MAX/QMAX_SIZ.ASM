;' $Header:   P:/PVCS/MAX/386MAX/QMAX_SIZ.ASV   1.6   30 May 1997 10:46:00   BOB  $
	 title	 QMAX_SIZ -- 386MAX Size Calculations
	 page	 58,122
	 name	 QMAX_SIZ

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ZCODE, para-aligned,  public, class 'zcode'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Data    segment ZDATA, para-aligned,  public, class 'zdata'
	       Program segment NCODE, byte-aligned,  public, class 'ncode'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'
	       Group FGROUP:
	       Data    segment FDATZ, dword-aligned, public, class 'fixup'
	       Group JGROUP:
	       Program segment JCODZ, dword-aligned, public, class 'jcode'
	       Group DL2GROUP:
	       Data    segment DL2DATZ, dword-aligned, public, class 'dl2code'
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
	 include ASCII.INC
	 include 386.INC
	 include PTR.INC
	 include WIN3PAGE.INC
	 include VDS.INC
	 include CPUFET.INC
	 include IOTRAP.INC

	 include QMAXDPMI.INC
	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_TRC.INC
	 include QMAX_TSS.INC
	 include QMAXWIN3.INC
	 include QMAX_FLX.INC
.list

	 public  @MAX_XHNDLCNT
@MAX_XHNDLCNT equ 256		; Maximum # XMS handles

PGROUP	 group	 CODE,ZCODE,ECODE,EDATA,NCODE,NDATA,ZDATA
FGROUP	 group	 FDATZ
JGROUP	 group	 JCODZ
DL2GROUP group	 DL2DATZ
XGROUP	 group	 XCODE,XDATA
YGROUP	 group	 YDATA


FDATZ	 segment use16 dword public 'fixup' ; Begin FDATZ segment
	 assume  ds:FGROUP	; Tell the assembler

	 extrn	 FDATA_NXT:dword

FDATZ	 ends			; End FDATZ segment


JCODZ	 segment use16 dword public 'jcode' ; Start JCODZ segment
	 assume  ds:JGROUP

	 extrn	 JCODE_NXT:dword

JCODZ	 ends			; End JCODZ segment

DL2DATZ  segment use16 dword public 'dl2code' ; Start DL2DATZ segment

	 extrn	 DL2GROUP_END:word

DL2DATZ  ends			; End DL2DATZ segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 XMS_FLAG:word
	 include QMAX_XMS.INC

if @OEM_EMS
	 extrn	 EMMSIZE:dword
endif				; IF @OEM_EMS
	 extrn	 EXTSIZE:dword
	 extrn	 OFFSIZE:word
	 extrn	 ONFSIZE:word
	 extrn	 SWPSIZE:word
	 extrn	 LOWSIZE:word
	 extrn	 OVRSIZE:word
	 extrn	 PRGSIZE:word
	 extrn	 TOTSIZE:dword
	 extrn	 SHDSIZE:word
	 extrn	 XSHDSIZE:word
	 extrn	 POVR_MAC:word

CODE	 ends			; End CODE segment


ZCODE	 segment use16 para public 'zcode' ; Start ZCODE segment
	 assume  ds:PGROUP

	 extrn	 OVR_HPDA:tbyte

ZCODE	 ends			; End ZCODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 FSET_GDT:far

ECODE	 ends			; End ECODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  cs:PGROUP

	 extrn	 MCSTAB:tbyte,MCSTAB_CNT:word
	 include QMAX_MCS.INC

	 extrn	 SHDIND:word
	 extrn	 SCRBCNT:word,SCRBIND:word
	 include QMAX_SHD.INC

	 extrn	 PRGBASE:dword
	 extrn	 PaPRGBASE:dword
	 extrn	 PaPRGBASE2:dword

	 extrn	 CNVBASE:dword

if @OEM_WIN3
	 extrn	 PUMB_INST:dword
	 extrn	 PCFGFILE:dword
	 extrn	 CFG_CNT:word
endif				; IF @OEM_WIN3

	 extrn	 GORSIZE:dword
if @OEM_DMA
	 extrn	 DMASIZE:word
endif				; IF @OEM_DMA
	 extrn	 PHYSIZE:dword
if @OEM_DMA
	 extrn	 PPDTD2M:dword,DMA_D2M:dword
	 extrn	 PPDTDMA:dword,PPDTDMAZ:dword
endif				; IF @OEM_DMA
	 extrn	 PPDTSCR:dword
	 extrn	 PPDTUNW:dword
	 extrn	 PPDTUNWZ:dword
	 extrn	 PPDT1MB:dword
	 extrn	 PPDT1P1MB:dword
	 extrn	 PPDT1W1MB:dword
	 extrn	 PPDTBACK:dword
	 extrn	 PPDTMISS:dword
	 extrn	 PPDTPDIR:dword
	 extrn	 UNWCNT:word
if @OEM_SYS eq @OEMSYS_RET
	 extrn	 PPDTPSM:dword
endif				; IF @OEM_SYS eq @OEMSYS_RET
	 extrn	 PPDTBBMSRC:dword
	 extrn	 PPDTBBMDST:dword
	 extrn	 LaBBMSRC:dword
	 extrn	 LaBBMDST:dword

	extrn	LaPnP_BIOS:dword
	extrn	PPDTPnPBIOS:dword
	extrn	PnP_SEG:word

	 extrn	 LOADBYTE:dword
	 extrn	 MINBASE:dword
if @OEM_EMS
	 extrn	 EMMBASE:dword, 	    PPDTEMM:dword,PPDTEMMZ:dword
endif				; IF @OEM_EMS
	 extrn	 RSVBASE:dword, 	    PPDTRSV:dword
	 extrn	 LOWBASE:dword, 	    PPDTLOW:dword
	 extrn	 OVRBASE:dword, 	    PPDTOVR:dword
	 extrn	 LMLBASE:dword, 	    PPDTLML:dword,LMLTOP:dword
	 extrn				    PPDTPRG:dword
	 extrn	 MAPBASE:dword,MAPSIZE:word,PPDTMAP:dword
	 extrn	 TOPBASE:dword
if DBG_TRACE
	 extrn	 TRACESIZE:dword
	 extrn	 TRCBASE:dword
endif				; IF DBG_TRACE

	 extrn	 @IOMAP:abs
	 extrn	 PVMTSS:dword
	 extrn	 PCURTSS:dword
	 extrn	 CPUFET_FLAG:dword
	 extrn	 PIOBIT:dword
	 extrn	 MAPSEG_NXT:word
	 extrn	 PPDTCNV:dword,PPDTCNVZ:dword
	 extrn	 OFFCR3:dword
	 extrn	 LaCR3:dword
	 extrn	 LaDIR2:dword
	 extrn	 LaOPTE:dword
if @OEM_DMA
	 extrn	 DMA_LA:dword
endif				; IF @OEM_DMA
	 extrn	 PDBSIZE:dword
	 extrn	 LaPDIREND:dword
	 extrn	 CON1KB:dword
	 extrn	 CON4KB:dword
	 extrn	 CON8KB:dword
	 extrn	 CON64KB:dword
	 extrn	 CON1MB:dword
	 extrn	 CON1P1MB:dword
	 extrn	 LOWOFF:dword
	 extrn	 VIDOFF:dword
	 extrn	 LAST_INTCOM:dword
	 extrn	 PCHECKER_INP:dword
	 extrn	 PCHECKER_OUT:dword
	 extrn	 CHECKER_LEN:word
if @OEM_EMS
	 extrn	 REMPGCNT:word
	 extrn	 TOTPGCNT:word
	 extrn	 PMRS_PDT:dword
	 extrn	 @MAX_EHNDLCNT:abs
	 extrn	 NBOARDS:word
	 extrn	 PORTPMR:word
	 extrn	 PORTPMRZ:word
	 extrn	 NPHYS16F:byte
	 extrn	 NPHYSCNV:byte
	 extrn	 NPHYSSCR:byte
	 extrn	 NPHYS16S:byte
	 extrn	 MRS_MAX:byte
	 extrn	 PRPNTAB:dword
	 extrn	 PRPNCUR:dword
endif				; IF @OEM_EMS

if @OEM_XMS
	 extrn	 EXTBASE:dword
	 extrn	 PXMSBASE:dword
	 extrn	 PXMSSIZE:dword
	 extrn	 PXMSHNDL:dword
	 extrn	 PXMSLOCK:dword
	 extrn	 PXMSBMAP:dword
	 extrn	 XMSBMAP_LEN:dword
	 extrn	 XMSNHNDL:word
	 extrn	 PPDTCVD:dword
	 extrn	 LaCVD:dword
endif				; IF @OEM_XMS

if @OEM_FLEXROM
	 extrn	 FLEXROM_FLAG:word
endif				; IF @OEM_FLEXROM

	 extrn	 PIOTRAP:dword
	 extrn	 DOSVER:word

if @OEM_WIN3
	 extrn	 @WIN3_IMPORT_VENDOR_LEN:abs
	 extrn	 @WIN3_IMPORT_PRODUCT_LEN:abs

	 public  PWIN3_PAGE,PWIN3_PAGEZ
PWIN3_PAGE dd	 ?		; Offset in data segment of EMM Paging Import Data
PWIN3_PAGEZ dd	 ?		; Ending offset ...
endif				; IF @OEM_WIN3


	 public  PDTLEN,PDTVALID,PRGTAIL,PRGPDT
PDTLEN	 dd	 0		; Length of PDT table in bytes
PDTVALID dd	 ?		; Length of valid PTEs in bytes
PRGTAIL  dd	 ?		; Offset of end of PRG with PDT
PRGPDT	 dd	 ?		; Offset of end of PRG w/o  PDT

if @OEM_EMS

; Pointer to handle count table
; This table is @MAX_EHNDLCNT+1 words long and contains for each handle
; (including the EMS free chain) the number of LPNs allocated to it.
; The values are valid only if the handle is valid;
; otherwise, they are undefined.

	 public  PHNDLCNT
PHNDLCNT dd	 ?


; Pointer to handle name directory
; This table consists of 8-byte names, one per handle.
; It is ordered by handle # (0 to @MAX_EHNDLCNT-1) and is
; initialized to zeros.

	 public  PHNDLNAME
PHNDLNAME dd	 ?


; Pointer to link base offset into PDT of the PTEs corresponding to
; offsets in PAGELINK.
; This table is NPHYS16S dwords long and is filled with either
; PPDTEMM or PPDTEMM-PPDTEMMZ depending upon whether or not the
; corresponding physical page is in the extended memory EMS region
; or in the conventional memory region.

	 public  PLINKBASE
PLINKBASE dd	 ?


; Pointer to linked list structure for 16KB physical pages of expanded memory

	 public  PPAGELINK
PPAGELINK dd	 ?


; Pointer to linear address map to PAGELINK table entries
; This table is (1024 + EXTSIZE + EMMSIZE)/16 dwords long and
; is filled with the PAGELINK entries which correspond to the
; linear address index (in units of 16KB).

	 public  PBASEPAGE,BASEPAGE_LEN
PBASEPAGE dd	 ?
BASEPAGE_LEN dd  ?		; Length of BASEPAGE table in dwords


; Pointer to handle page entry table
; This table consists of dword-wide links to entries in the PAGELINK table
; or if there are no logical pages associated with this handle,
; the corresponding entry is zero.
; It is ordered by handle # (0 to @MAX_EHNDLCNT+1) including @FREE_HNDL,
; and @VMS_HNDL, and is initialized to @HP_LAST.

	 public  PHNDLPAGE
PHNDLPAGE dd	 ?


; Pointer to physical page to segment table.
; This table is one word wide and contains mappable segment numbers.
; The # entries is NPHYS16S.
; It is ordered by ascending physical page #.
; For example, it might contain the following entries in order
;
;   E000  as Physical Page #00
;   E400		    01
;   E800		    02
;   EC00		    03
;   4000		    04
;   4400		    05
;   4800		    06
;   4C00		    07
;    ...		   ...
;   9C00		    1C

	 public  PPHYS2SEG
PPHYS2SEG dd	 ?


; Pointer to segment to physical page table.
; This table is one byte wide and contains the physical page numbers
; necessary to order PPHYS2SEG ascendingly by segment #.
; The # entries is NPHYS16S.
; For example, it might contain the following entries in order
;   04, 05, 06, 07, ..., 1C, 00, 01, 02, 03

	 public  PSEG2PHYS
PSEG2PHYS dd	 ?


; HFRMSAV is a matrix of @MAX_EHNDLCNT rows by HFRMLEN bytes.
; The first entry in each row is a marker of whether or not the entry is in
; use.	The possible values are @PMR_UNUSED (not in use) or the handle #.
; The remaining entries are (handle, LPN), one per physical page in the
; EMS frame (NPHYS16F).
; The entire collection of saved arrays is pointed to by PHFRMSAV
; The entire array size is HFRMSIZE

	 public  PHFRMSAV,HFRMLEN,HFRMSIZE
PHFRMSAV dd	 ?		; Save area for HFRMs
HFRMLEN  dd	 ?		; Size of an HFRMSAV entry
HFRMSIZE dd	 ?		; Size of all HFRMSAV entries
endif				; IF @OEM_EMS

	 public  PPL0STK_INI,PPL0STK_ERR,PPL0STK_NRM,PPL0STK_MIN
	 public  PPL0STK_MAX,PPL0STK_MAP
	 public  @PPL0STK_INT
@PPL0STK_INT equ 128		; Stack size for hardware interrupts
PPL0STK_INI dd	 ?		; Pointer to PL0STK	(fixed)
PPL0STK_ERR dd	 ?		; Offset of stack when error code present
PPL0STK_NRM dd	 ?		; Offset of stack when normal start
PPL0STK_MIN dd	 ?		; Offset of stack minimum for interrupts
PPL0STK_MAX dd	 ?		; Offset of stack maximum for interrupts
PPL0STK_MAP dd	 ?		; Offset of stack bottom for Map & Call struc

if @OEM_DPMI
	 public  PPL0STK_DERR,PPL0STK_DNRM
PPL0STK_DERR dd  ?		; Offset of stack when DPMI fault
PPL0STK_DNRM dd  ?		; Offset of stack when DPMI HW/SW interrupt
endif				; IF @OEM_DPMI

	 public  LaSIRBCUR
LaSIRBCUR dd	 ?		; Linear address of current SIRB table

	 public  NSTACKS
NSTACKS  dw	 0		; # 256-byte stacks to reserve

if @OEM_SYS eq @OEMSYS_RET
	 public  PSMSIZE,PSMWIN,PSMSEG
PSMSIZE  dw	 0		; Size of Periscope memory in 1KB
PSMWIN	 dw	 0		; Size of Periscope window in 1KB (/4KB)
				; 0 if PSMEM= not specified
PSMSEG	 dw	 ?		; Starting para # (/4KB)
endif				; IF @OEM_SYS eq @OEMSYS_RET

if @OEM_XMS
	 public  HMASIZE,CMPSIZE,CMPSIZEXT,CMPSIZEMM
HMASIZE  dd	 0		; Size of HMA (0 or 64KB) (can be used as dword)
CMPSIZE  dd	 ?		; Size of Common Memory Pool in 1KB
CMPSIZEXT dd	 ?		; ...				    for EXT=
CMPSIZEMM dd	 ?		; ...				    for EMS= (max 32MB)
endif				; IF @OEM_XMS

	 public  PRVSIZE,EXFSIZE
PRVSIZE  dd	 0		; Size of preceding extended memory usage
EXFSIZE  dd	 ?		; Size of EXTSIZE in cased forced ON by low
				; DOS memory DMA buffer
	 public  PVDSTAB,VDSTAB_LEN
PVDSTAB  dd	 0		; Offset in PGROUP of the secondary
				; VDS lookup table (0 for none)
VDSTAB_LEN dd	 ?		; Length in bytes of above table

	 public  FGRBASE, FGRSIZE
FGRBASE  dd	 ?		; Base of FGROUP
FGRSIZE  dd	 ?		; Size of FGROUP in bytes

	 public  JGRBASE, JGRSIZE, JGRDSIZE
JGRBASE  dd	 ?		; Base of JGROUP
JGRSIZE  dd	 ?		; Size of JGROUP in bytes
JGRDSIZE dd	 ?		; Size of JGROUP and DL?GROUP in bytes

EDATA	 ends			; End EDATA segment


ZDATA	 segment use16 para public 'zdata' ; Start ZDATA segment
	 assume  cs:PGROUP

	 extrn	 ZLDATA:byte

ZDATA	 ends			; End ZDATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

if @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

	 extrn	 MEM_MAP:byte,MEM_MAP_LEN:abs
	 extrn	 @XLAT_OTH:abs
	 extrn	 @XLAT_OVR:abs
	 extrn	 XLAT_FLAG:byte
	 extrn	 VDSTAB_SEG:word

if @OEM_WIN3
	 public  LaEMM_Import_Ptr
LaEMM_Import_Ptr dd ?		; Linear address of Windows 3 Paging Import Data
endif				; IF @OEM_WIN3

	 public  REMSIZE,PUTSIZE
REMSIZE  dd	 ?		; Remainder (added into EXTSIZE at end)
PUTSIZE  dd	 ?		; Putative program size

NDATA	 ends			; End NDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 FBIN2BASE:far

NCODE	 ends			; End NCODE segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

if @OEM_FLEXROM
	 extrn	 POVR_MAC2:word
endif				; IF @OEM_FLEXROM
	 extrn	 EMMSIZE2:dword

; The theoretical maximum for EMS memory appears to be 256MB
; calculated as no more than 128 2MB "boards" as limited by
; the EMS 3.0 I/O mapping functions.

	 public  MAX_EMSMEM
MAX_EMSMEM dd	 256*1024	; Maximum EMS allowed in 1KB
				; The stated EMS 4.0 limit is 32MB, but the
				; theoretical EMS 4.0 limit is 256MB.
				; Mostly we're changing this so Shared memory
				; display isn't limited to 32MB.

XDATA	 ends			; End XDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

	 extrn	 MSG_WSFULL:byte
	 extrn	 MSG_NOTDRV:byte

if @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 MSG_EMSFULL:byte
	 extrn	 MSG_NOEMS:byte
else
MSG_NOEMS equ	 MSG_WSFULL
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

if @OEM_SIZE
	 extrn	 MSG_SIZE_P1:byte
	 extrn	 MSG_SIZE_P2:byte
	 extrn	 MSG_SIZE_P3:byte
	 extrn	 MSG_SIZE_LOW:byte
if @OEM_HIFILL
	 extrn	 MSG_SIZE_OVR:byte
endif				; IF @OEM_HIFILL
	 extrn	 MSG_SIZE_MAP:byte
	 extrn	 MSG_SIZE_EXT:byte
	 extrn	 MSG_SIZE_PRV:byte
	 extrn	 MSG_SIZE_EMM:byte
	 extrn	 MSG_SIZE_PRG:byte
	 extrn	 MSG_SIZE_REQ:byte
	 extrn	 MSG_SIZE_TOT:byte
	 extrn	 MSG_SIZE_DIF:byte
endif				; IF @OEM_SIZE

YDATA	 ends			; End YDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_SIZ_XCODE
@QMAX_SIZ_XCODE:		; Mark module start in .MAP file

	 extrn	 BIND2BASE:near
	 extrn	 CALC_OVRSIZE:far
	 extrn	 SAVE_SHADOW:far
	 extrn	 YMSGOUT2:near
if @OEM_EMS
	 extrn	 CALC_NPHYS:far
endif				; IF @OEM_EMS
if @OEM_VCPI
	 extrn	 SET_VCPIVARS:near
endif				; IF @OEM_VCPI
if @OEM_DPMI
	 extrn	 ROOM_DPMI:near
	 extrn	 ROOM_DPMI2:near
endif				; IF @OEM_DPMI
	 extrn	 CALC_LODSTART:near

if @OEM_EMS
	 NPPROC  ROOM_PHYS -- Make Room for EMS Physical Page Tables
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for the EMS physical page to default PTE table, and
	      the EMS physical page to segment table, and
	      the EMS segment to physical page table, and
	      the HNDLCNT table, and
	      the HNDLPAGE table, and
	      the PAGELINK table.
All addresses should be on a word boundary in offset terms.

This routine *MUST* be called before calling ROOM_HFRM.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ecx		; Save register

	 sub	 eax,PRGBASE	; Convert from linear address to offset

; ===================== PHYS2SEG ==============================

; Round up to word boundary

	 add	 eax,2-1	; Round up to word boundary
	 and	 ax,not (2-1)	; ...

; Save offset of PHYS2SEG table

	 mov	 PPHYS2SEG,eax	; Save as pointer to PHYS2SEG table

; Add in the size of the PHYS2SEG table as one word per
; physical page in the EMS system

	 movzx	 ecx,NPHYS16S.ELO ; Get # physical 16KB pages in EMS system
	 shl	 cx,1		; Times two as size of word entry
	 add	 eax,ecx	; Add into total

; ===================== SEG2PHYS ==============================

; Round up to word boundary

	 add	 eax,2-1	; Round up to word boundary
	 and	 ax,not (2-1)	; ...

; Save offset of SEG2PHYS table

	 mov	 PSEG2PHYS,eax	; Save as pointer to SEG2PHYS table

; Add in the size of the SEG2PHYS table as one byte per physical page
; There are NPHYS16S physical 16KB pages in the EMS system

	 movzx	 ecx,NPHYS16S.ELO ; Add in # physical 16KB pages in EMS system
	 add	 eax,ecx	; Add in # physical 16KB pages in EMS system

; ===================== HNDLPAGE ==============================

; Round up to dword boundary

	 add	 eax,4-1	; Round up to dword boundary
	 and	 ax,not (4-1)	; ...

; Save offset of HNDLPAGE table

	 mov	 PHNDLPAGE,eax	; Save as pointer to HNDLPAGE table

; Add in the size of the HNDLPAGE table
; This size is @MAX_EHNDLCNT (maximum # allowable handles) plus one for
; the EMS free chain, plus one for the VMS free chain
; times one dword per handle page entry.

	 xor	 ecx,ecx	; Zero entire register as MASM doesn't
				; handle the next instruction with ECX
	 mov	 cx,@MAX_EHNDLCNT+2 ; CX = maximum # handles plus EMS and VMS
				; free chain handles
	 shl	 cx,2		; Times four for one dword per handle page entry
	 add	 eax,ecx	; Add it into putative PRGSIZE

; ===================== PAGELINK ==============================

; Round up to dword boundary

	 add	 eax,4-1	; Round up to dword boundary
	 and	 ax,not (4-1)	; ...

; Save offset of PAGELINK table

	 mov	 PPAGELINK,eax	; Save as pointer to PAGELINK table

; Add in the size of the PAGELINK table
; This size is one dword per 16KB logical page in the CMP

	 mov	 ecx,CMPSIZEMM	; Get EMS limited size of common memory pool
;;;;;;;; and	 ecx,not (16-1) ; Round down to 16KB boundary
	 shr	 ecx,14-10	; Convert from 1KB to 16KB (size of EMS pages)

	 push	 eax		; Save for a moment

	 movzx	 eax,NPHYSCNV.ELO ; Get # physical 16KB pages in CNV memory
	 add	 ax,NPHYSSCR.ELO ; Plus # physical 16KB pages in SCREEN memory
	 add	 ecx,eax	; Add to get # 16KB pages in EMS system

	 pop	 eax		; Restore

	 shl	 ecx,2		; Times four as size of handle-page entry
	 add	 eax,ecx	; Add it into putative PRGSIZE

	 add	 eax,PRGBASE	; Convert from offset to linear address

	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_PHYS endp			; End ROOM_PHYS procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  ROOM_HFRM -- Make Room for EMS HFRMSAV Table
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for the EMS HFRMSAV table.
Its address should be on a word boundary in offset terms.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 sub	 eax,PRGBASE	; Convert from linear address to offset

; Round up to word boundary

	 add	 eax,2-1	; Round up to word boundary
	 and	 ax,not (2-1)	; ...

; Save as offset of HFRMSAV table

	 mov	 PHFRMSAV,eax	; Save as pointer to HFRMSAV table (fixed)

; Add in the size of the HFRMSAV table (HFRMSIZE)

	 add	 eax,HFRMSIZE	; Add size of table into putative PRGSIZE

	 add	 eax,PRGBASE	; Convert from offset to linear address

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_HFRM endp			; End ROOM_HFRM procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	 NPPROC  ROOM_RPNTAB -- Make Room for RPN Tables
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for (MRS_MAX+1) RPN tables.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ecx		; Save register

	 sub	 eax,PRGBASE	; Convert from linear address to offset

; Round up to word boundary

	 add	 eax,2-1	; Round up to word boundary
	 and	 ax,not (2-1)	; ...

	 mov	 PRPNTAB,eax	; Save offset for later use
	 mov	 PRPNCUR,eax	; ...

; ===================== PRPNTAB ===============================

; Add in the size of the RPNTAB table
; The PRPNTAB table points to a contiguous collection of RPN tables, one
; per AMRS mapping.  It is (MRS_MAX + 1) * NPHYS16S words long.  RPNCUR
; is one of the tables in the collection.

	 movzx	 ecx,MRS_MAX	; Get maximum # AMRS
	 inc	 cx		; Count in the default one
	 imul	 cx,NPHYS16S.ELO ; Times # physical 16KB pages in EMS system
	 shl	 ecx,1		; Times two for one word per RPNTAB entry
	 add	 eax,ecx	; Add it into putative PRGSIZE

	 add	 eax,PRGBASE	; Convert from offset to linear address

	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_RPNTAB endp		; End ROOM_RPNTAB procedure
endif				; IF @OEM_EMS
	 NPPROC  ROOM_STACK -- Make Room for Program Stack
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for program stack.
Its address should be on a dword boundary in offset terms.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ebx		; Save register

	 sub	 eax,PRGBASE	; Convert from linear address to offset

; Round up to dword boundary

	 add	 eax,4-1	; Round up to dword boundary
	 and	 ax,not (4-1)	; ...
	 add	 eax,type PPL0STK_MAP ; Make room for PPL0STK_MAP deadman switch

; Save offset of start of the stack

	 mov	 PPL0STK_INI,eax ; Save for later use
	 mov	 PPL0STK_MAP,eax ; Save for later use

; Save offset of minimum stack for hardware interrupts

	 mov	 ebx,eax	; Copy start
	 add	 ebx,@PPL0STK_INT ; Add in minimum stack
	 mov	 PPL0STK_MIN,ebx ; Save as offset to minimum stack size

; Add in the size of the program stack
; This size is 4096 plus NSTACKS times 256 rounded up to a dword boundary

	 movzx	 ebx,NSTACKS	; Get parameter, zero high-order word
	 shl	 ebx,8-0	; Convert from 256-bytes to bytes
	 add	 ebx,4096	; Plus base
	 add	 eax,ebx	; Add it into putative PRGSIZE
	 add	 eax,4-1	; Round up to dword boundary
	 and	 ax,not (4-1)	; ...
	 mov	 PPL0STK_MAX,eax ; Save to restore from later
	 mov	 ebx,eax	; Copy to modify
	 sub	 ebx,size INTCOM_STR ; Back off by frame size
	 mov	 LAST_INTCOM,ebx ; Save as offset of last INTCOM interrupt frame

	 add	 eax,PRGBASE	; Convert from offset to linear address

	 pop	 ebx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_STACK endp 		; End ROOM_STACK procedure
	 NPPROC  ROOM_SIRBDEF -- Make Room for Default SIRB Table
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for default SIRB table if we're on a P5 or later CPU.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 test	 CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	 jz	 short ROOM_SIRBDEF_EXIT ; Jump if not

; Save linear address of start of the default SIRB table

	 mov	 LaSIRBCUR,eax	; Save for later use

; Add in the size of the default SIRB table
; This size is 256/8 bytes

	 add	 eax,256/8	; Skip over the default SIRB table
ROOM_SIRBDEF_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_SIRBDEF endp		; End ROOM_SIRBDEF procedure
	 NPPROC  ROOM_VDS -- Make Room for Previous VDS Table
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for previous VDS table
Its address should be on a dword boundary in offset terms.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|
	 REGSAVE <ebx,es>	; Save

	 cmp	 VDSTAB_SEG,0	; Do we have a secondary VDS table?
	 je	 short ROOM_VDS_EXIT ; Jump if not

; Round up to dword boundary

	 add	 eax,4-1	; Round up to dword boundary
	 and	 al,not (4-1)	; Then down

	 sub	 eax,PRGBASE	; Convert from linear address to offset

	 mov	 PVDSTAB,eax	; Save offset in PGROUP of previous VDS table

; Add in the size of the previous VDS table

	 mov	 ebx,VDSTAB_LEN ; Get the table's byte length
	 add	 eax,ebx	; Skip over the previous VDS table

	 add	 eax,PRGBASE	; Convert from offset to linear address
ROOM_VDS_EXIT:
	 REGREST <es,ebx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_VDS endp			; End ROOM_VDS procedure
if @OEM_EMS
	 NPPROC  ROOM_PHYS2 -- Make Room for EMS Physical Page Tables, Part II
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for the LINKBASE table, and
	      the BASEPAGE table.

All addresses should be on a dword boundary in offset terms.

This routine *MUST* be called before calling ROOM_HFRM.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ecx		; Save register

	 sub	 eax,PRGBASE	; Convert from linear address to offset

; ===================== LINKBASE ==============================

; Round up to dword boundary

	 add	 eax,4-1	; Round up to dword boundary
	 and	 ax,not (4-1)	; ...

; Save offset of LINKBASE table

	 mov	 PLINKBASE,eax	; Save as pointer to LINKBASE table

; Add in the size of the LINKBASE table
; This size is one dword per 16KB logical page in the CMP

	 mov	 ecx,CMPSIZEMM	; Get EMS limited size of common memory pool
;;;;;;;; and	 ecx,not (16-1) ; Round down to 16KB boundary
	 shr	 ecx,14-10	; Convert from 1KB to 16KB (size of EMS pages)

	 push	 eax		; Save for a moment

	 movzx	 eax,NPHYSCNV.ELO ; Get # physical 16KB pages in CNV memory
	 add	 ax,NPHYSSCR.ELO ; Plus # physical 16KB pages in SCREEN memory
	 add	 ecx,eax	; Add to get # 16KB pages in EMS system

	 pop	 eax		; Restore

	 shl	 ecx,2		; Times four as size of each LINKBASE entry
	 add	 eax,ecx	; Add it into putative PRGSIZE

; ===================== BASEPAGE ===============================

; Save offset of BASEPAGE table

	 mov	 PBASEPAGE,eax	; Save as pointer to BASEPAGE table

; Add in the size of the BASEPAGE table
; This size is (1024 + CMPSIZE + HMASIZE)/16 dwords

	 mov	 ecx,CMPSIZE	; Get size of common memory pool
	 add	 ecx,HMASIZE	; Plus size of HMA (0 or 64KB)
	 add	 ecx,1024+16-1	; Plus first megabyte (and round up to 16KB)
;;;;;;;; and	 ecx,not (16-1)  ; ...
	 shr	 ecx,14-10	; Convert from 1KB to 16KB
	 mov	 BASEPAGE_LEN,ecx ; Save for later use
	 shl	 ecx,2-0	; Convert from dwords to bytes
	 add	 eax,ecx	; Add it into putative PRGSIZE

	 add	 eax,PRGBASE	; Convert from offset to linear address

	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_PHYS2 endp 		; End ROOM_PHYS2 procedure
endif				; IF @OEM_EMS
	 NPPROC  ROOM_IOCHK -- Make Room for I/O Port Check Tables
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for the I/O port check tables.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ecx		; Save for a moment

	 sub	 eax,PRGBASE	; Convert from linear address to offset

; Round up to word boundary

	 add	 eax,2-1	; Round up to word boundary
	 and	 ax,not (2-1)	; ...

	 movzx	 ecx,CHECKER_LEN ; Get table limit in words
	 shl	 ecx,1-0	; Convert from words to bytes

; ===================== CHECKER_INP ===========================

	 mov	 PCHECKER_INP,eax ; Save as pointer to CHECKER_INP table
	 add	 eax,ecx	; Skip over CHECKER_INP table

; ===================== CHECKER_OUT ===========================

	 mov	 PCHECKER_OUT,eax ; Save as pointer to CHECKER_OUT table
	 add	 eax,ecx	; Skip over CHECKER_OUT table

	 add	 eax,PRGBASE	; Convert from offset to linear address

	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_IOCHK endp 		; End ROOM_IOCHK procedure
if @OEM_EMS
	 NPPROC  ROOM_HNDL -- Make Room for EMS HNDLNAME and HNDLCNT Tables
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for the HNDLNAME and HNDLCNT tables.
Its address should be on a dword boundary in offset terms.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ecx		; Save register

	 xor	 ecx,ecx	; Zero entire register

	 sub	 eax,PRGBASE	; Convert from linear address to offset

; ===================== HNDLNAME ==============================

; Round up to dword boundary

	 add	 eax,4-1	; Round up to dword boundary
	 and	 ax,not (4-1)	; ...

; Save offset of HNDLNAME table

	 mov	 PHNDLNAME,eax	; Save as pointer to HNDLNAME table

; Add in the size of the HNDLNAME table
; This size is @MAX_EHNDLCNT (maximum # allowable handles)
;   times 8 bytes per handle name

	 mov	 cx,@MAX_EHNDLCNT ; BX = maximum # EMS handles
	 shl	 cx,3		; Times eight bytes per handle name
	 add	 eax,ecx	; Add it into putative PRGSIZE

; ===================== HNDLCNT ===============================

; Save offset of HNDLCNT table

	 mov	 PHNDLCNT,eax	; Save as pointer to HNDLCNT table

; Add in the size of the HNDLCNT table
; This size is @MAX_EHNDLCNT (maximum # allowable handles) plus one for
; the unallocated entries times one word per handle page entry

	 mov	 cx,@MAX_EHNDLCNT+1 ; CX = maximum # handles plus unallocated handle
	 shl	 cx,1		; Times two for one word per handle page entry
	 add	 eax,ecx	; Add it into putative PRGSIZE

	 add	 eax,PRGBASE	; Convert from offset to linear address

	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_HNDL endp			; End ROOM_HNDL procedure
endif				; IF @OEM_EMS
if @OEM_XMS
	 NPPROC  ROOM_XMSTAB -- Make Room for The XMS Tables
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for XMS tables

XMSBASE  dd	 XMSNHDNL dup (?)	Start of allocated memory
XMSSIZE  dd	 XMSNHDNL dup (?)	Size of ... in bytes
XMSHNDL  db	 XMSNHDNL dup (?)	1 = in use, 0 = available
XMSLOCK  db	 XMSNHDNL dup (?)	Lock count
XMSBMAP  db	 (CMPSIZE+HMASIZE+1024) dup (?)  XMS allocation and boundary bitmap

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ebx		; Save register

	 sub	 eax,PRGBASE	; Convert from linear address to offset

; Round up to dword boundary

	 add	 eax,4-1	; Round up to dword boundary
	 and	 ax,not (4-1)	; ...

; Save offset of start of the XMSBASE table

	 mov	 PXMSBASE,eax	; Save for later use

; Add in the size of the XMSBASE table
; This size is XMSNHNDL times 4

	 movzx	 ebx,XMSNHNDL	; Get parameter, zero high-order three bytes
	 shl	 ebx,2-0	; Convert from dwords to bytes
	 add	 eax,ebx	; Add it into putative PRGSIZE

; Save offset of start of the XMSSIZE table

	 mov	 PXMSSIZE,eax	; Save for later use

; Add in the size of the XMSSIZE table
; This size is XMSNHNDL times 4

	 movzx	 ebx,XMSNHNDL	; Get parameter, zero high-order three bytes
	 shl	 ebx,2-0	; Convert from dwords to bytes
	 add	 eax,ebx	; Add it into putative PRGSIZE

; Save offset of start of the XMSHNDL table

	 mov	 PXMSHNDL,eax	; Save for later use

; Add in the size of the XMSHNDL table
; This size is XMSNHNDL times 1

	 movzx	 ebx,XMSNHNDL	; Get parameter, zero high-order three bytes
	 add	 eax,ebx	; Add it into putative PRGSIZE

; Save offset of start of the XMSLOCK table

	 mov	 PXMSLOCK,eax	; Save for later use

; Add in the size of the XMSLOCK table
; This size is XMSNHNDL times 1

	 movzx	 ebx,XMSNHNDL	; Get parameter, zero high-order three bytes
	 add	 eax,ebx	; Add it into putative PRGSIZE

; Save offset of start of the XMSBMAP table

	 mov	 PXMSBMAP,eax	; Save for later use

; Add in the size of the XMSBMAP table
; This size is CMPSIZE+HMASIZE+1024+4 bytes

	 mov	 ebx,CMPSIZE	; Get size of extended memory to use
	 add	 ebx,HMASIZE	; Plus size of HMA (0 or 64KB)
	 add	 ebx,CON1KB	; Add into accumulator
	 mov	 XMSBMAP_LEN,ebx ; Save for later use
	 add	 ebx,4		; Plus another dword (we only need a byte)
				; to act as an terminal entry
	 add	 eax,ebx	; Add it into putative PRGSIZE

	 add	 eax,PRGBASE	; Convert from offset to linear address

	 pop	 ebx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_XMSTAB endp		; End ROOM_XMSTAB procedure
endif				; IF @OEM_XMS
	 NPPROC  ROOM_TSS -- Make Room for TSSs
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for TSSs

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 REGSAVE <ebx>		; Save register

	 add	 eax,4-1	; Round up to dword boundary
	 and	 eax,not (4-1)	; ...

	 sub	 eax,PRGBASE	; Less linear address of our base
	 mov	 PVMTSS,eax	; Save as offset in PGROUP of 1st TSS
	 mov	 PCURTSS,eax	; Save as offset in PGROUP of current TSS
	 mov	 OVR_HPDA.HPDA_PCURTSS,eax ; Save as back pointer

	 add	 eax,@TSS_MAX * (type DPTSS_STR) ; Skip over the TSSs

	 test	 CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	 jz	 short @F	; Jump if not

	 add	 eax,256/8	; Make room for Software Interrupt
				; Re-direction Bitmap
@@:
	 mov	 PIOBIT,eax	; Save as offset in PGROUP of I/O bit map

; Add in the size of the I/O permission bit map
; plus the terminating byte of 0FFh

	 xor	 ebx,ebx	; Zero entire register
	 mov	 bx,@IOMAP+1	; Size of I/O map (note external)
	 add	 eax,ebx	; Skip over it

	 add	 eax,PRGBASE	; Convert from offset to linear address

	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_TSS endp			; End ROOM_TSS procedure
if @OEM_WIN3
	 NPPROC  ROOM_INST -- Make Room for UMB Instance Data
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for the UMB instance data.
Its address should be on a word boundary in linear address terms
just for efficiency.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ecx		; Save for a moment

; Round up to linear address word boundary

	 add	 eax,2-1	; Round up to word boundary
	 and	 ax,not (2-1)	; Round down

; Save as 32-bit offset in our data segment of UMB instance data

	 sub	 eax,PRGBASE	; Less linear address of our base
	 mov	 PUMB_INST,eax	; Save it

; Add in the size of the UMB instance data

	 public  @UMB_INST_N
@UMB_INST_N equ  100		; # of items local table will hold

	 add	 eax,(@UMB_INST_N+1)*(type INSTANCE_ITEM_STR)

; Make room for configuration file

	 movzx	 ecx,CFG_CNT	; Get the file size in bytes
	 jcxz	 @F		; Jump if it's empty

	 mov	 PCFGFILE,eax	; Save as offset in PGROUP
	 add	 eax,ecx	; Skip over file contents
@@:
	 add	 eax,PRGBASE	; Convert from offset to linear address

	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_INST endp			; End ROOM_INST procedure
endif				; IF @OEM_WIN3
	 NPPROC  ROOM_PDT -- Make Room for Page Descriptor Tables
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for Alternate Mapping Register Sets table
Make room for Page Descriptor Directory and Entry Tables.
Make room for Page Descriptor Directory for INT 15h block moves.
All addresses must be on a 4KB boundary in linear address terms.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 REGSAVE <ebx,ecx,edx>	; Save EGP register

; Round up to linear address 4KB boundary

	 add	 eax,CON4KB	; Round up to 4KB boundary
	 dec	 eax		; Less one for rounding
	 and	 ax,not (4*1024-1)

; Save as linear address of first level Page Directory Base (i.e., CR3)

	 mov	 LaCR3,eax	; Save as potential CR3

; Save offset of CR3 address into which PDEs go

	 sub	 eax,PRGBASE	; Less linear address of our base
	 mov	 OFFCR3,eax	; Save as offset to PDE table
	 add	 eax,PRGBASE	; Convert from offset to linear address

; Add in the size of the PDE table (a 4KB page)

	 add	 eax,CON4KB	; Plus 4KB

; Save linear address of second level Page Directory Base
; into which PTEs go.

	 mov	 LaDIR2,eax	; Save as absolute offset of second level dirs

	 sub	 eax,PRGBASE	; Less linear address of our base
				; to get PRGSIZE in bytes to this point

; Save as offset of PRG without PDT -- this might be >64KB

	 mov	 PRGPDT,eax	; Save as offset of PDT

; ===================== PPDT ==================================

; Note that the size in bytes of the PDT can never overflow a 16-bit register.
; However, the offset from the start of PRG can exceed 64KB.

; Add in the size of the PDT
; This size is (TOTSIZE * 1K) + 1MB at 4 bytes per 4KB
; = 4 * Ceil(((TOTSIZE * 1K) + 1MB)/4K)
; = 4 * Ceil(((TOTSIZE + 1KB) * 1K)/4K)
; = 4 * Ceil((TOTSIZE + 1KB)/4) in units of one byte

	 mov	 ecx,TOTSIZE	; Get total amount of extended memory
	 add	 ecx,1024	; Plus 1MB base (in units of 1KB)
;;;;;;;; add	 ecx,4-1	; Round up to next multiple of 4
;;;;;;;; and	 ecx,not (4-1)
	 add	 ecx,4*1024-1	; Round up to 4KB boundary
	 and	 ecx,not (4*1024-1)
	 add	 eax,ecx	; Add it into putative PRGSIZE
	 mov	 PDTVALID,ecx	; Save as byte length of valid PTEs

; ===================== PDTCNV ================================

; Save offset of PDTCNV table

	 mov	 PPDTCNV,ecx	; Save as pointer to PDTCNV table

; Add in the size of the PDTCNV table as one dword per
; 4KB page in conventional memory

	 mov	 ebx,VIDOFF	; Get start of video buffers (multiple of 4KB in 1KB)
;;;;;;;; sh?	 ebx,10-(12-2)	; Convert from 1KB to 4KB in dwords
	 add	 ecx,ebx	; Add into PDT offset

	 mov	 PPDTCNVZ,ecx	; Save as pointer to end of conventional entries

; ===================== PDTSCR ================================

; Save offset of PDTSCR table

	 test	 CM2_FLAG,@CM2_SCR ; SCREEN specified?
	 jz	 short ROOM_PDT_NOSCR ; Not this time

	 mov	 PPDTSCR,ecx	; Save as pointer to PDTSCR table

; Add in the size of the PDTSCR table as 16 dwords

	 add	 ebx,4*64/4	; At 1 dword per 4KB
	 add	 ecx,4*64/4	; At 1 dword per 4KB
ROOM_PDT_NOSCR:
	 add	 eax,ebx	; Add it into putative PRGSIZE

if @OEM_DMA

; ===================== PDTD2M ================================

; Add in DMASIZE + 4 bytes for DMA destination PTEs

	 mov	 PPDTD2M,ecx	; Save as offset in PDT of device-to-memory PTEs

	 mov	 ebx,ecx	; Copy current offset into PDT (multiple of 4KB in 4KB in dwords)
	 shl	 ebx,(12-2)-0	; Convert from 4KB in dwords to bytes
	 mov	 DMA_D2M,ebx	; Save for later use

	 movzx	 ebx,DMASIZE	; Get size of DMA transfer buffer (multiple of 4KB in 1KB)
;;;;;;;; sh?	 ebx,(12-2)-10	; Convert from 1KB to 4KB in dwords
	 add	 ebx,4		; Plus one PTE for slop
	 add	 ecx,ebx	; Skip to next PTE offset in PDT
	 add	 eax,ebx	; Skip to next PRG offset
endif				; IF @OEM_DMA

if @OEM_XMS

; ===================== PDTCVD ================================

; Add in 4*16 bytes for CHECK_VDISK in QMAX_XMS
; and VCPI access to 1MB wrap region

	 mov	 PPDTCVD,ecx	; Save as offset in PDT of CHECK_VDISK address

	 mov	 ebx,ecx	; Copy current offset into PDT (multiple of 4KB in 4KB in dwords)
	 shl	 ebx,(12-2)-0	; Convert from 4KB in dwords to bytes
	 mov	 LaCVD,ebx	; Save for later use

	 add	 ecx,16*(size PDT_PTE) ; Skip to next PTE offset in PDT
	 add	 eax,16*(size PDT_PTE) ; Skip to next PRG offset
endif				; IF @OEM_XMS

; ===================== PDTMISS ===============================

; Add in 4 bytes for FIND_PTE missing PTE save area

	 mov	 PPDTMISS,ecx	; Save as offset in PDT of missing PTE
	 add	 ecx,4		; Skip to next PTE offset in PDT
	 add	 eax,4		; Skip to next PRG offset

; ===================== PDTPDIR ===============================

; Add in 4 bytes for PDIR PTE

	 mov	 PPDTPDIR,ecx	; Save as offset in PDT of PDIR PTE
	 add	 ecx,4		; Skip to next PTE offset in PDT
	 add	 eax,4		; Skip to next PRG offset

; ===================== BIOS Block Move =======================

	 mov	 ebx,ecx	; Copy current offset into PDT (multiple of 4KB in 4KB in dwords)
	 shl	 ebx,(12-2)-0	; Convert from 4KB in dwords to bytes
	 mov	 LaBBMSRC,ebx	; Save linear address of BIOS block move source
	 mov	 PPDTBBMSRC,ecx ; Save as offset in PDT of BBM source

	 add	 ecx,17*(size PDT_PTE) ; Skip to next PTE offset in PDT
	 add	 eax,17*(size PDT_PTE) ; Skip to next PRG offset

	 mov	 ebx,ecx	; Copy current offset into PDT (multiple of 4KB in 4KB in dwords)
	 shl	 ebx,(12-2)-0	; Convert from 4KB in dwords to bytes
	 mov	 LaBBMDST,ebx	; Save linear address of BIOS block move destin
	 mov	 PPDTBBMDST,ecx ; Save as offset in PDT of BBM destin

	 add	 ecx,17*(size PDT_PTE) ; Skip to next PTE offset in PDT
	 add	 eax,17*(size PDT_PTE) ; Skip to next PRG offset

; ===================== Plug 'n Play ==========================

	cmp	PnP_SEG,0	; Izit present?
	je	short ROOM_PDT_NOPnP ; Not this time

	mov	ebx,ecx 	; Copy current offset into PDT (multiple of 4KB in 4KB in dwords)
	shl	ebx,(12-2)-0	; Convert from 4KB in dwords to bytes
	mov	LaPnP_BIOS,ebx	; Save linear address of PnP BIOS
	mov	PPDTPnPBIOS,ecx ; Save as offset in PDT of PnP BIOS

; Make room for the BIOS

	add	ecx,@PnP_NPTES*(size PDT_PTE) ; Skip to next PTE offset in PDT
	add	eax,@PnP_NPTES*(size PDT_PTE) ; Skip to next PRG offset
ROOM_PDT_NOPnP:

; Ending code

	 mov	 PDTLEN,ecx	; Save as length of PDT segment in bytes
	 add	 eax,PRGBASE	; Convert from offset to linear address

	 REGREST <edx,ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_PDT endp			; End ROOM_PDT procedure
if @OEM_DMA
	 NPPROC  ROOM_DMASWAP -- Make Room for DMA Page Swapping Area
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for the DMA Page Desciptor Entry.
Its address should be on a 4KB boundary in physical address terms
so its PTEs may be swapped.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 push	 ebx		; Save for a moment

; Round up to physical address 4KB boundary

	 add	 eax,CON4KB	; Round up to 4KB boundary
	 dec	 eax		; Less one for rounding
	 and	 ax,not (4*1024-1) ; Round down

; Save as linear address of DMA swapping area

	 mov	 DMA_LA,eax

; Get length of the area in 1KB

	 movzx	 ebx,DMASIZE	; Clear high-order word
	 shl	 ebx,10-0	; Convert from 1KB to bytes

; Save linear address of DMA page swapping area

	 push	 ebx		; Pass size of area in bytes
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_DMA	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Add in the size of the DMA page swapping area

	 add	 eax,ebx	; Skip over DMA swapping page

	 pop	 ebx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_DMASWAP endp		; End ROOM_DMASWAP procedure
endif				; IF @OEM_DMA
	 NPPROC  ROOM_OPTE -- Make Room for PDE for Overflow PTE Table
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for the PDE for overflow PTE table and Windows 3 Paging Import Data.
Its address must be on a 4KB boundary in linear address terms.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

if @OEM_WIN3
	 mov	 LaEMM_Import_Ptr,eax ; Save as linear address later
				; translated to physical address

; Save as 32-bit offset in our data segment of WIN3 Paging Import Data

	 sub	 eax,PRGBASE	; Less linear address of our base
	 mov	 PWIN3_PAGE,eax ; Save it
	 add	 eax,PRGBASE	; Convert from offset to linear address
endif				; IF @OEM_WIN3

; Round up to linear address 4KB boundary

	 add	 eax,CON4KB	; Round up to 4KB boundary
	 dec	 eax		; Less one for rounding
	 and	 ax,not (4*1024-1)

; Save as linear address of overflow PTE tables

	 mov	 LaOPTE,eax	; Save it

; Set the corresponding descriptor

	 push	 CON8KB 	; Pass size of area
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_OPTE	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Add in the size of the one PDE

	 push	 ebx		; Save for a moment

	 add	 eax,CON4KB	; Skip over the overflow PDE

if @OEM_WIN3

; Ensure there's enough room for the Windows 3 Paging Import Data structure

	 mov	 ebx,LaEMM_Import_Ptr ; Get starting linear address

; Add in
;	 size EMM_Import_Data	for static elements
;	 1			for EMM_Import_Hnd_Cnt

	 add	 ebx,(size EMM_Import_Data)+1

; Add in (size EMM_Import_UMB_Map) bytes for each 16KB UMB
; As we don't know at this stage how many UMBs there'll be, we use a
; maximum value of (1024-640)/16.
; Note that this field is valid for Windows 3.10 or later only.

	 add	 ebx,((1024-640)/16)*(size EMM_Import_UMB_Map)

; Add in (size EMM_Import_Handle) bytes for each EMS handle
; As we don't know how many EMS handles will be in use, we use a
; maximum value of @MAX_EHNDLCNT

	 push	 eax		; Save for a moment

	 mov	 eax,@MAX_EHNDLCNT ; Get maximum # handles
	 imul	 eax,size EMM_Import_Handle
	 add	 ebx,eax	; Add it in

	 pop	 eax		; Restore

; End of version 1.00 import data

; Add in 4 bytes for EMM_Import_INT67 value
; ...	 4	     EMM_Import_HMAAliasPhysPtr
; ...	 1	     EMM_Import_Free_Cnt
; ...	 1	     EMM_Import_xMS_Cnt
; ...	 1	     EMM_Import_FreeUMB_Cnt
; ...	 @WIN3_IMPORT_xxx_LEN  Vendor and product names

	 add	 ebx,4+4+1+1+1	; Add it in
	 add	 ebx,@WIN3_IMPORT_VENDOR_LEN
	 add	 ebx,@WIN3_IMPORT_PRODUCT_LEN

; Add in EMM_Import_Free_Cnt * (size EMM_Import_FreeReg) bytes
; for EMM_Import_FreePhys.
; As we don't know how many regions there'll be, we use a
; maximum value of @MAX_FREE_REG.

	 public  @MAX_FREE_REG
@MAX_FREE_REG equ 16		; Maximum # free regions

	 add	 ebx,@MAX_FREE_REG * (size EMM_Import_FreeReg)

; Add in EMM_Import_xMS_Cnt * (size EMM_Import_xMSHnd) bytes
; for EMM_Import_xMSHndA.
; As we don't know how many XMS handles will be allocated we use
; a maximum value of @MAX_XHNDLCNT.

	 add	 ebx,@MAX_XHNDLCNT * (size EMM_Import_xMSHnd)

; Add in EMM_Import_FreeUMB_Cnt * (size EMM_Import_FreeUMB) bytes
; for EMM_Import_Free_UMBA.
; As we don't know how many free UMBs there'll be, we use
; a maximum value of @MAX_FREE_UMBS.

	 public  @MAX_FREE_UMBS
@MAX_FREE_UMBS equ 256

	 add	 ebx,@MAX_FREE_UMBS * (size EMM_Import_FreeUMB)

; Add in room for an extra copy of the CMPSIZEMM PTEs in Import_PhysPtrToPTEs

	 push	 eax		; Save for a moment

	 mov	 eax,CMPSIZEMM	; Get EMS limited size of common memory pool
;;;;;;;; and	 eax,not (16-1) ; Round down to 16KB boundary
	 shr	 eax,14-10	; Convert from 1KB to 16KB (size of EMS pages)

	 push	 ecx		; Save for a moment

	 movzx	 ecx,NPHYSCNV.ELO ; Get # physical 16KB pages in CNV memory
	 add	 cx,NPHYSSCR.ELO ; Plus # physical 16KB pages in SCREEN memory
	 add	 eax,ecx	; Add to get # 16KB pages in EMS system

	 pop	 ecx		; Restore

	 shl	 eax,14-(12-2)	; Convert from 16KB to 4KB in dwords
	 add	 ebx,eax	; Add it in

	 pop	 eax		; Restore

; Use the larger value of EAX (end of 1st OPTE)
; and EBX (end of Windows Paging Import Data)

	 cmp	 eax,ebx	; Use the larger
	 jae	 short @F	; Jump if 8KB PDE is larger

	 mov	 eax,ebx	; Use Windows 3 Paging Import Data ending
@@:
	 sub	 eax,PRGBASE	; Less linear address of our base
	 mov	 PWIN3_PAGEZ,eax ; Save it
	 add	 eax,PRGBASE	; Convert from offset to linear address
endif				; IF @OEM_WIN3
	 pop	 ebx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_OPTE endp			; End ROOM_OPTE procedure
if @OEM_EMS
	 NPPROC  ROOM_AMRS -- Make Room for Alternate Mapping Register Sets
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for Alternate Mapping Register Sets
All addresses must be on a 4KB boundary in linear address terms.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 REGSAVE <ebx>		; Save register

; Round up to linear address 4KB boundary

	 add	 eax,CON4KB	; Round up to 4KB boundary
	 dec	 eax		; Less one for rounding
	 and	 ax,not (4*1024-1)

; Save offset in PDT of AMRS PDEs

	 mov	 ebx,eax	; Copy to modify (multiple of 4KB)
	 shr	 ebx,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PMRS_PDT,ebx	; Save for later use

; Make room for MRS_MAX Alternate Mapping Register Sets

	 movzx	 ebx,MRS_MAX	; Get maximum # AMRS
	 shl	 ebx,12-0	; Convert from 4KB to bytes

; Save linear address of AMRS PTEs

	 push	 ebx		; Pass size of AMRS PTEs
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_AMRS	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

	 add	 eax,ebx	; Add it into putative PRGSIZE

	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_AMRS endp			; End ROOM_AMRS procedure
endif				; IF @OEM_EMS
if @OEM_SYS eq @OEMSYS_RET
	 NPPROC  ROOM_PSM -- Make Room for Periscope Memory Area
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for Periscope Memory Area
All addresses must be on a 4KB boundary in linear address terms.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 REGSAVE <ebx>		; Save register

	 movzx	 ebx,PSMSIZE	; Get size of Periscope memory
	 shl	 ebx,10-0	; Convert from 1KB to bytes
	 jz	 short ROOM_PSM_EXIT ; Jump if none

; Round up to linear address 4KB boundary

	 add	 eax,CON4KB	; Round up to 4KB boundary
	 dec	 eax		; Less one for rounding
	 and	 ax,not (4*1024-1)

	 push	 eax		; Save for a moment

	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PPDTPSM,eax	; Save for later use

	 pop	 eax		; Restore

; Make room for PSMSIZE memory

	 add	 eax,ebx	; Add it into putative PRGSIZE
ROOM_PSM_EXIT:
	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_PSM endp			; End ROOM_PSM procedure
endif				; IF @OEM_SYS eq @OEMSYS_RET
if DBG_TRACE
	 NPPROC  ROOM_TRACE -- Make Room for Trace Table
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for trace table
For simplicity, the base address is on a 4KB boundary in linear address terms.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 REGSAVE <ebx>		; Save register

	 test	 CM3_FLAG,@CM3_TRACE ; Using tracing?
	 jz	 short ROOM_TRACE_EXIT ; Not this time

; Round up to linear address 4KB boundary

	 add	 eax,CON4KB	; Round up to 4KB boundary
	 dec	 eax		; Less one for rounding
	 and	 ax,not (4*1024-1)

; Save linear address of trace table in DTE_TRACE

	 mov	 TRCBASE,eax	; Save linear address
	 mov	 ebx,TRACESIZE	; Get size of trace table

	 push	 ebx		; Pass size of trace table
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_TRACE	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

	 add	 eax,ebx	; Add it into putative PRGSIZE
ROOM_TRACE_EXIT:
	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_TRACE endp 		; End ROOM_TRACE procedure
endif				; IF DBG_TRACE
	 NPPROC  ROOM_FGROUP -- Make Room for Fixup Segments
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fixup Segments

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 REGSAVE <ebx>		; Save caller's register

	 add	 eax,2-1	; Round up to word boundary
	 and	 ax,not (2-1)	; ...

	 mov	 FGRBASE,eax	; Save linear address for later use

	 lea	 ebx,FGROUP:FDATA_NXT ; Size of FGROUP
	 mov	 FGRSIZE,ebx	; Save for use by others

	 add	 eax,ebx	; Account for space used by FGROUP

	 REGREST <ebx>		; Restore caller's register

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_FGROUP endp		; End ROOM_FGROUP procedure
	 NPPROC  ROOM_JGROUP -- Make Room for JGROUP and DL?GROUP Segments
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for JGROUP and DL?GROUP segments.  Note that DLGROUP and
DL2GROUP are contiguous to JGROUP so we can use JGROUP's data selector.
We also save different sizes for the JGROUP code and data, since the code
selector is limited to 64K.

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 REGSAVE <ebx>		; Save caller's register

	 add	 eax,2-1	; Round up to word boundary
	 and	 ax,not (2-1)	; ...

	 mov	 JGRBASE,eax	; Save linear address for later use

	 lea	 ebx,JGROUP:JCODE_NXT ; Just past last byte in JGROUP
	 mov	 JGRSIZE,ebx	; Save for use by others

	 mov	 bx,seg DL2GROUP ; Get starting segment (note high word = 0)
	 sub	 bx,seg JGROUP	; Get offset in paras from start of JGROUP
	 shl	 ebx,4-0	; Convert paras to bytes

	 lea	 ebx,DL2GROUP:DL2GROUP_END[ebx] ; Just past last byte in DL2GROUP
	 mov	 JGRDSIZE,ebx	; Save size including DLGROUP and DL2GROUP
	 add	 eax,ebx	; Account for space used by JGROUP & DL?GROUP

	 REGREST <ebx>		; Restore caller's register

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_JGROUP endp		; End ROOM_JGROUP procedure
	 NPPROC  ROOM_IOTRAP -- Make Room for I/O Trapping Strucs
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Make room for I/O trapping strucs

On entry:

EAX	 =	 next available linear address

On exit:

EAX	 =	 (updated)

|

	 add	 eax,2-1	; Round up to word boundary
	 and	 ax,not (2-1)	; ...

	 sub	 eax,PRGBASE	; Less linear address of our base
	 mov	 PIOTRAP,eax	; Save offset in PGROUP for later use
	 add	 eax,PRGBASE	; Convert from offset to linear address

	 add	 eax,@IOTRAP_MAX * (type IOTRAP_STR) ; Account for space used by I/O trapping strucs

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROOM_IOTRAP endp		; End ROOM_IOTRAP procedure
	 FPPROC  CALC_FORCE -- Calculate If We're Forced ON
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate if we're forced to the ON state.

|

if @OEM_FLEXROM
	 test	 FLEXROM_FLAG,@FR_ACTIVE ; Is any ROM being swapped?
	 jnz	 short CALC_FORCE_ON ; Yes, so force state to ON
endif				; IF @OEM_FLEXROM

	 cmp	 LOWSIZE,0	; Low DOS memory present?
	 jg	 short CALC_FORCE_ON ; Yes, so force state to ON

	 cmp	 OVRSIZE,0	; High DOS memory present?
	 jne	 short CALC_FORCE_ON ; Yes, so force state to ON

	 cmp	 SWPSIZE,0	; Swapping memory?
	 jne	 short CALC_FORCE_ON ; Yes, so force state to ON

if @OEM_SYS eq @OEMSYS_RET
	 cmp	 PSMSIZE,0	; Mapping periscope memory?
	 jne	 short CALC_FORCE_ON ; Yes, so force state to ON
endif				; IF @OEM_SYS eq @OEMSYS_RET

	 test	 LCL_FLAG,@LCL_LML or @LCL_BCF ; Loading PRG in low memory or BCF in effect?
	 jnz	 short CALC_FORCE_ON ; Yes, so force state to ON

;;;;;;;; test	 CM3_FLAG,@CM3_XA20 ; Izit FORCEA20?
;;;;;;;; jnz	 short CALC_FORCE_ON ; Yes, so force state to ON

	 test	 CMD_FLAG,@CMD_EMS ; Izit specified?
	 jz	 short @F	; No, so we can't trust the value

	 cmp	 SHDSIZE,0	; Any shadow RAM?
	 je	 short @F	; No, so we can't be providing extended memory

if @OEM_EMS
	 cmp	 EMMSIZE,0	; Providing EMS services?
	 je	 short CALC_FORCE_ON ; No, so we must be providing extended memory
else
	 jmp	 short CALC_FORCE_ON ; We must be providing extended memory
endif				; IF @OEM_EMS
@@:
	 and	 GLB_FLAG,not @GLB_FORC ; Mark as not forced ON

	 jmp	 short CALC_FORCE_EXIT ; Join common exit code

CALC_FORCE_ON:
	 or	 GLB_FLAG,@GLB_FORC or @GLB_ON ; Mark as forced ON state
	 and	 GLB_FLAG,not @GLB_AUTO ; ...and not AUTO
CALC_FORCE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_FORCE endp 		; End CALC_FORCE procedure
	 FPPROC  FILL_MCS -- Fill In MCSTAB From MEM_MAP
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

At this point, all of MEM_MAP is filled in.

Fill in MCSTAB entries from MEM_MAP.

Search through the entries using XLAT_FLAG to translate
each character into @MCS_ values.

|

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

	 mov	 bx,LOWOFF.ELO	; Get offset of low DOS memory (unit = 1KB)
	 add	 bx,LOWSIZE	; Add in the amount of fill (unit = 1KB)
;;;;;;;; mov	 bx,VIDOFF.ELO	; Get offset of video memory (unit = 1KB)
;;;;;;;; add	 bx,VIDSIZE	; Add in its size (unit = 1KB)
	 shl	 bx,10-9	; Convert from 1KB to 512
	 mov	 cx,MEM_MAP_LEN ; Get # characters in MEM_MAP
	 sub	 cx,bx		; Less starting point

; Search through MEM_MAP inserting entries as we find them

	 xor	 si,si		; Zero index to memory chain structure
	 lea	 di,MEM_MAP[bx] ; ES:DI ==> next memory map character
				; after video memory
FILL_MCS1:
	 jcxz	 FILL_MCS3	; Nothing more to do

	 mov	 al,es:[di]	; Get first character as seed
	 mov	 bx,di		; Save starting point
    repe scasb			; Search for others like it
	 je	 short FILL_MCS2 ; Not found

	 dec	 di		; Back up to first different byte
	 inc	 cx		; Count it back in
FILL_MCS2:
	 mov	 dx,di		; Copy ending point
	 sub	 dx,bx		; DX has length in units of 512
	 sub	 bx,offset es:MEM_MAP ; Convert to origin-0

	 shl	 bx,9-4 	; Convert from 512 to paras
	 shl	 dx,9-4 	; Convert from 512 to paras

	 mov	 MCSTAB.MCS_PARA[si],bx ; Save as paragraph #
	 mov	 MCSTAB.MCS_NPAR[si],dx ; Save as # paragraphs

	 xor	 ah,ah		; Zero to use as word
	 lea	 bx,XLAT_FLAG	; DS:BX ==> translate table to flags
	 xlat	 XLAT_FLAG	; Translate into appropriate flags
	 mov	 MCSTAB.MCS_FLAG[si],ax ; Save as flag word
	 inc	 MCSTAB_CNT	; Count in another entry

	 add	 si,type MCS_STR ; Skip to next entry

	 jmp	 FILL_MCS1	; Go around again

FILL_MCS3:

; Search through MCSTAB to calculate POVR_MAC

	 xor	 si,si		; Zero index to memory chain structure
	 mov	 cx,MCSTAB_CNT	; Get # entries
	 jcxz	 FILL_MCS_EXIT	; Jump if no high DOS
FILL_MCS_NEXTPOVR:
	 test	 MCSTAB.MCS_FLAG[si],@MCS_AVAIL ; Izit available?
	 jnz	 short @F	; Jump if so

	 add	 si,type MCS_STR ; Skip to next entry

	 loop	 FILL_MCS_NEXTPOVR ; Jump if more MCS entries to check

	 jmp	 short FILL_MCS_EXIT ; Join common ending code

@@:
	 mov	 ax,MCSTAB.MCS_PARA[si] ; Get starting para #
if @OEM_FLEXROM

; If FLEXROM is in effect, POVR_MAC would be C000, and FLEX_SRC
; is at C000, increment POVR_MAC past the first @VGAHDR bytes so
; we can copy that many bytes of signature to C000.

	 push	 es		; Save for a moment

	 push	 seg XGROUP	; Get segment of POVR_MAC2
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 mov	 POVR_MAC2,ax	; Save original value

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 test	 FLEXROM_FLAG,@FR_VGA ; Is a VGA being FLEXed?
	 jz	 short FILL_MCS_XFLEX ; Jump if not

	 cmp	 ax,0C000h	; Is POVR_MAC at or below C000?
	 ja	 short FILL_MCS_XFLEX ; Jump if not

	 test	 FLEXROM_FLAG,@FR_VID_C000 ; Is there a video ROM at C000?
	 jz	 short FILL_MCS_XFLEX ; Jump if not

	 test	 FLEXROM_FLAG,@FR_NOGORE ; Did the user request "No gore"?
	 jnz	 short FILL_MCS_XFLEX ; Jump if so

; Run through the rest of the MCSTAB entries looking for an
; available entry which starts at C000 (thus there'll be a
; MAC entry there).

FILL_MCS_NEXTPOVR2:
	 test	 MCSTAB.MCS_FLAG[si],@MCS_AVAIL ; Izit available?
	 jz	 short @F	; Jump if not

; Check for MAC entry at C000

	 cmp	 MCSTAB.MCS_PARA[si],0C000h ; Duzit start at C000?
	 jne	 short @F	; Jump if not

	 or	 FLEXROM_FLAG,@FR_GORE ; Mark as present

	 jmp	 short FILL_MCS_XGORE ; Join common code

@@:
	 add	 si,type MCS_STR ; Skip to next entry

	 loop	 FILL_MCS_NEXTPOVR2 ; Jump if more MCS entries to check

; No MAC entry at C000, hence no gore

FILL_MCS_XGORE:
	 cmp	 ax,0C000h	; Is POVR_MAC at C000?
	 jne	 short FILL_MCS_XFLEX ; Jump if not

	 add	 ax,@VGAHDR/16 ; Skip over VGA header
FILL_MCS_XFLEX:
endif				; IF @OEM_FLEXROM
	 mov	 POVR_MAC,ax	; Save as segment of 1st MAC entry in high DOS
FILL_MCS_EXIT:
	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_MCS endp			; End FILL_MCS procedure
if @OEM_SIZE
	 FPPROC  SIZE_ERR -- Calculate Sizes for Error Message
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate various sizes for error message.

|

	 REGSAVE <eax,ebx,ecx,di,es> ; Save registers

	 push	 seg YGROUP	; Get segment of YDATA
	 pop	 es		; Address it
	 assume  es:YGROUP	; Tell the assembler about it

	 xor	 ebx,ebx	; Initialize accumulator

; Display the amount of low DOS memory needed

	 movzx	 eax,LOWSIZE	; Get total amount of low DOS memory
	 add	 ebx,eax	; Add in to accumulator
	 lea	 di,YGROUP:MSG_SIZE_LOW-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

if @OEM_HIFILL
; Display the amount of high DOS memory needed

	 movzx	 eax,OVRSIZE	; Get total amount of high DOS memory
	 add	 ebx,eax	; Add in to accumulator
	 lea	 di,YGROUP:MSG_SIZE_OVR-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI
endif				; IF @OEM_HIFILL

; Display the amount of ROM re-mapping memory needed

	 movzx	 eax,MAPSIZE	; Get size of ROM mapping region
	 add	 ebx,eax	; Add in to accumulator
	 lea	 di,YGROUP:MSG_SIZE_MAP-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

; Display the amount of remaining extended memory needed

	 mov	 eax,EXTSIZE	; Get remaining amount of extended memory
	 add	 eax,REMSIZE	; Plus remainder
	 add	 ebx,eax	; Add in to accumulator
	 lea	 di,YGROUP:MSG_SIZE_EXT-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 push	 offset YGROUP:MSG_SIZE_P1 ; Display part 1 of message
	 call	 YMSGOUT2	; Display YGROUP message

	 mov	 eax,PRVSIZE	; Get amount of preceding VDISK
if @OEM_XMS
	 add	 eax,HMASIZE	; Plus size of HMA (0 or 64KB)
endif				; IF @OEM_XMS

	 and	 eax,eax	; Anything to report on?
	 jz	 short @f	; Not this time

; Display the amount of extended memory needed for a preceding VDISK
; or XMS HMA

	 lea	 di,YGROUP:MSG_SIZE_PRV-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

	 push	 offset YGROUP:MSG_SIZE_P2 ; Display part 2 of message
	 call	 YMSGOUT2	; Display YGROUP message
@@:

if @OEM_EMS

; Display the amount of EMS memory needed

	 mov	 eax,EMMSIZE	; Get total amount of expanded memory
	 add	 ebx,eax	; Add in to accumulator
	 lea	 di,YGROUP:MSG_SIZE_EMM-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI
endif				; IF @OEM_EMS

; Display the amount of program size needed

	 mov	 eax,PUTSIZE	; Get putative program size
	 add	 eax,4-1	; Round up to 4KB boundary
	 and	 eax,not (4-1)
	 add	 ebx,eax	; Add in to accumulator
	 lea	 di,YGROUP:MSG_SIZE_PRG-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

; Display the total amount needed

	 mov	 eax,ebx	; Get amount requested
	 lea	 di,YGROUP:MSG_SIZE_REQ-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

; Display the total amount available

	 mov	 eax,TOTSIZE	; Get total amount of extended memory
	 sub	 eax,GORSIZE	; Less the amount of the gore region
	 lea	 di,YGROUP:MSG_SIZE_TOT-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

; Display the difference

	 sub	 ebx,eax	; Get the additional amount needed
	 mov	 eax,ebx	; Copy to FBIN2BASE input register
	 lea	 di,YGROUP:MSG_SIZE_DIF-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 push	 offset YGROUP:MSG_SIZE_P3 ; Display part 3 of message
	 call	 YMSGOUT2	; Display YGROUP message

	 REGREST <es,di,ecx,ebx,eax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SIZE_ERR endp			; End SIZE_ERR procedure
endif				; IF @OEM_SIZE
	 FPPROC  CALC_SIZE -- Calculate Various Sizes
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup PRGBASE, EMMBASE, LOWBASE, and OVRBASE.

Extended memory is organized as follows:

ีอออออออออออออออธ  End of   PRG base	  (TOPBASE)
ณ		ณ
ฦอออออออออออออออต  Start of PRG base	  (PRGBASE  L  PRGSIZE)
ณ		ณ
ฦอออออออออออออออต  Start of DOS low fill  (LOWBASE  L  LOWSIZE)
ณ		ณ
ฦอออออออออออออออต  Start of MAP base	  (MAPBASE  L  MAPSIZE)
ณ		ณ
ฦอออออออออออออออต  Start of DOS high	  (OVRBASE  L  OVRSIZE) = RSVBASE
ณ		ณ
ณ		ณ
ณ		ณ
ณ		ณ EMS saved here (multiple of 16KB)
ณ		ณ
ณ		ณ
ณ		ณ
ณ		ณ
ฦอออออออออออออออต  Start of EMS 	  (EMMBASE  L  CMPSIZEMM)
ณ		ณ
ณ		ณ  Remainder left over (if any) after above installed
ณ		ณ
ิอออออออออออออออพ  Start of extended memory (1MB) = MINBASE

This routine calculates the value of PRGBASE and EMMBASE.

Because the page descriptor table must be located on a 4KB boundary,
the calculation of PRGBASE must be iterative.

* MAPSIZE is a multiple of  4KB
* PRGSIZE is a multiple of  4KB
* OVRSIZE is a multiple of  4KB
* LOWSIZE is a multiple of  4KB
* EMMSIZE is a multiple of 16KB
* EXTSIZE is a multiple of 16KB to simplify CMP calculations

* MAPBASE must be on a 4KB page boundary so as to allow paging
* PDT	  must be on a 4KB page boundary because it is a page descriptor
* PRGBASE must be on a 4KB page boundary so as to allow paging
* OVRBASE must be on a 4KB page boundary so as to allow paging
	  but we align it on a 16KB boundary to simplify CMP calculations
* LOWBASE must be on a 4KB page boundary so as to allow paging
* EMMBASE must be on a 4KB page boundary so as to allow paging

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,dx>	; Save registers

	 lea	 eax,ZLDATA	; Get size of static program

	 add	 eax,4*1024-1	 ; Round up to multiple of 4KB
	 and	 eax,not (4*1024-1)
	 shr	 eax,10-0	; Convert from bytes to 1KB
	 mov	 PRGSIZE,ax	; Save as tentative initial program size
	 mov	 PUTSIZE,eax	; Save as putative program size

; Ensure EXTSIZE >= PRVSIZE + HMASIZE

	 mov	 eax,PRVSIZE	; Get size of preceding extended memory usage
if @OEM_XMS
	 add	 eax,HMASIZE	; Plus size of HMA (0 or 64KB)
endif				; IF @OEM_XMS

	 cmp	 eax,EXTSIZE	; Ensure no larger
	 jb	 short CALC_SIZE_EMM ; It's OK

	 mov	 EXTSIZE,eax	; Save as minimum size
CALC_SIZE_EMM:
	 xor	 eax,eax	; A convenient zero
	 xchg	 eax,GORSIZE	; Assume it's initially zero
	 sub	 TOTSIZE,eax	; Subtract out old value

if @OEM_EMS
	 test	 CMD_FLAG,@CMD_EMS ; Did the user specify EMS= ?
	 jnz	 short CALC_SIZE_BASE ; Yes, EMMSIZE already specified

; EMMSIZE is TOTSIZE - GORSIZE - MAPSIZE - PRGSIZE - OVRSIZE - LOWSIZE - EXTSIZE
; rounded down to a multiple of 16KB but no larger than 32MB

	 mov	 eax,TOTSIZE	; Get total amount of extended memory
	 sub	 eax,GORSIZE	; Less size of gore region

	 movzx	 ebx,MAPSIZE	; Get amount needed for map regions
	 sub	 eax,ebx	; Less amount needed for map regions
	 jc	 near ptr CALC_SIZE_WSF ; No room for program

	 movzx	 ebx,PRGSIZE	; Get size of PRG high
	 sub	 eax,ebx	; Less size of PRG high
	 jc	 near ptr CALC_SIZE_WSF ; No room for program

	 movzx	 ebx,OVRSIZE	; Less amount needed for DOS high memory
	 sub	 eax,ebx	; Less amount needed for DOS high memory
	 jc	 near ptr CALC_SIZE_WSF ; No room for program

	 cmp	 LOWSIZE,0	; Check the sign
	 jle	 short @F	; Jump if there's nothing to fill

	 movzx	 ebx,LOWSIZE	; Get amount needed for DOS low  memory
	 sub	 eax,ebx	; Less amount needed for DOS low  memory
	 jc	 near ptr CALC_SIZE_WSF ; No room for program
@@:
	 sub	 eax,EXTSIZE	; Less amount needed for extended memory
	 jc	 near ptr CALC_SIZE_WSF ; No room for program

	 and	 eax,not (16-1) ; Round down to a multiple of 16KB

	 cmp	 eax,MAX_EMSMEM ; Check against theoretical maximum
	 jbe	 short CALC_SIZE_NOMAX ; It's within range

	 add	 EXTSIZE,eax	; Add in as extended memory
	 mov	 eax,MAX_EMSMEM ; Use maximum
	 sub	 EXTSIZE,eax	; Less EMMSIZE

; So we can remain at the maximum EMS memory, set @CMD_EMS if EXT=
; is not specified

	 test	 CMD_FLAG,@CMD_EXT ; Izit specified?
	 jnz	 short CALC_SIZE_NOMAX ; Jump if so

	 or	 CMD_FLAG,@CMD_EMS ; Mark as specified
CALC_SIZE_NOMAX:
	 mov	 EMMSIZE,eax	; Save as size of EMS
endif				; IF @OEM_EMS
CALC_SIZE_BASE:
	 mov	 eax,TOTSIZE	; Get total amount of extended memory
	 add	 eax,CON1KB	; Plus first megabyte
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 mov	 TOPBASE,eax	; Save for later use

;;;;;;;; mov	 eax,TOPBASE	; Get top of extended memory
	 and	 ax,not (4*1024-1) ; Round down to 4KB boundary

; PRGBASE is PRGSIZE * 1K bytes long

	 movzx	 ebx,PRGSIZE	; Get size of PRG
	 shl	 ebx,10-0	; Convert from 1KB to bytes

	 sub	 eax,ebx	; EAX = MAPBASE - (PRGSIZE * 1K)
	 jc	 near ptr CALC_SIZE_WSF ; Not enough extended memory

	 cmp	 eax,CON1MB	; Check against 1MB limit
	 jb	 near ptr CALC_SIZE_WSF ; No room for program

	 mov	 PRGBASE,eax	; Save as PRGBASE

; Ensure PRGBASE is at least 64KB above CON1MB
; If not, insert a gore.

	 mov	 ebx,CON1P1MB	; Get address of 1.1MB

	 sub	 ebx,eax	; Find the difference
	 jbe	 short CALC_SIZE_XGOR ; No need for an extra gore region

	 shr	 ebx,10-0	; Convert from bytes to 1KB
	 add	 TOTSIZE,ebx	; Add into total extended memory size
	 xchg	 ebx,GORSIZE	; Save as size of gore region
	 sub	 TOTSIZE,ebx	; Subtract out old value

	 jmp	 short CALC_SIZE_BASE ; Start over again

CALC_SIZE_XGOR:
	 mov	 ebx,GORSIZE	; Get requested amount of gore region
	 shl	 ebx,10-0	; Convert from 1KB to bytes
	 sub	 eax,ebx	; EAX = PRGBASE - (GORSIZE * 1K)
;;;;;;;; mov	 GORBASE,eax	; Save as GORBASE

; LOWBASE is LOWSIZE * 1K bytes long

	 cmp	 LOWSIZE,0	; Check the sign
	 jle	 short @F	; Jump if there's nothing to fill

	 movzx	 ebx,LOWSIZE	; Get requested amount of DOS low  memory
	 shl	 ebx,10-0	; Convert from 1KB to bytes

	 sub	 eax,ebx	; EAX = GORBASE - (LOWSIZE * 1K)
	 jc	 near ptr CALC_SIZE_WSF ; Not enough extended memory
@@:
	 cmp	 eax,CON1MB	; Check against 1MB limit
	 jb	 near ptr CALC_SIZE_WSF ; No room for program

	 mov	 LOWBASE,eax	; Save as LOWBASE

; MAPBASE is MAPSIZE * 1K bytes long

	 movzx	 ebx,MAPSIZE	; Get size of mapping region
	 shl	 ebx,10-0	; Convert from 1KB to bytes

	 sub	 eax,ebx	; EAX = LOWBASE - (MAPSIZE * 1K)
	 jc	 near ptr CALC_SIZE_WSF ; Not enough extended memory

	 cmp	 eax,CON1MB	; Check against 1MB limit
	 jb	 near ptr CALC_SIZE_WSF ; No room for program

	 mov	 MAPBASE,eax	; Save as MAPBASE

; OVRBASE is OVRSIZE * 1K bytes long

	 movzx	 ebx,OVRSIZE	; Get requested amount of DOS high memory
	 shl	 ebx,10-0	; Convert from 1KB to bytes

	 sub	 eax,ebx	; EAX = MAPBASE - (OVRSIZE * 1K)
	 jc	 near ptr CALC_SIZE_WSF ; Not enough extended memory

	 cmp	 eax,CON1MB	; Check against 1MB limit
	 jb	 near ptr CALC_SIZE_WSF ; No room for program

	 mov	 OVRBASE,eax	; Save as OVRBASE

; Ensure OVRBASE is on a 16KB boundary.  This greatly simplifies
; the common memory pool calculations as it mens that the EMS
; portion of the common memory pool starts on a 16KB boundary.

	 test	 OVRBASE,16*1024-1 ; Izit on a 16KB boundary?
	 jz	 short @F	; Jump if so

	 add	 PRGSIZE,4	; Add into program size
	 add	 PUTSIZE,4	; Add into putative program size in case
				; we run out of room
	 jmp	 CALC_SIZE_EMM	; Go around again

@@:
; Calculate REMSIZE, CMPSIZE, CMPSIZEXT, and CMPSIZEMM

	 mov	 eax,TOTSIZE	; Get total amount of extended memory

	 sub	 eax,GORSIZE	; Less size of gore region
	 jc	 near ptr CALC_SIZE_WSF ; No room for program

	 movzx	 ebx,MAPSIZE	; Get size of ROM mapping region
	 sub	 eax,ebx	; Less size of ROM mapping region
	 jc	 near ptr CALC_SIZE_WSF ; No room for program

	 movzx	 ebx,PRGSIZE	; Get size of static program
	 sub	 eax,ebx	; Less size of static program
	 jc	 near ptr CALC_SIZE_WSF ; No room for program

	 movzx	 ebx,OVRSIZE	; Get size of DOS high memory
	 sub	 eax,ebx	; Less size of DOS high memory
	 jc	 near ptr CALC_SIZE_WSF ; No room for program

	 cmp	 LOWSIZE,0	; Check the sign
	 jle	 short @F	; Jump if there's nothing to fill

	 movzx	 ebx,LOWSIZE	; Get size of DOS low  memory
	 sub	 eax,ebx	; Less size of DOS low	memory
	 jc	 near ptr CALC_SIZE_WSF ; No room for program
@@:
if @OEM_EMS
	 sub	 eax,EMMSIZE	; Less amount requested
	 jc	 near ptr CALC_SIZE_WSF ; No room for program
endif				; IF @OEM_EMS

	 sub	 eax,EXTSIZE	; Less amount requested
	 jc	 near ptr CALC_SIZE_WSF ; No room for program

	 mov	 REMSIZE,eax	; Yields an initial value for the remainder

	 add	 eax,EMMSIZE	; Plus size of EMS memory
	 add	 eax,EXTSIZE	; Plus size of extended memory
	 sub	 eax,HMASIZE	; Less size of HMA (0 or 64KB)
	 mov	 CMPSIZE,eax	; Save for later use
	 mov	 CMPSIZEXT,eax	; Save for later use

	 cmp	 eax,MAX_EMSMEM ; Izit too large for EMS pool?
	 jbe	 short @F	; Jump if not

	 mov	 eax,MAX_EMSMEM ; Use maximum
@@:
	 mov	 CMPSIZEMM,eax	; Save for later use

if @OEM_EMS

; EMMBASE is CMPSIZEMM * 1K bytes long

	 mov	 eax,OVRBASE	; Get previous base
	 mov	 ebx,CMPSIZEMM	; Get EMS limited size of common memory pool
	 shl	 ebx,10-0	; Convert from 1KB to bytes

	 sub	 eax,ebx	; EAX = OVRBASE - (CMPSIZEMM * 1K)
	 jc	 near ptr CALC_SIZE_WSF ; Not enough extended memory

	 cmp	 eax,CON1MB	; Check against 1MB limit
	 jb	 near ptr CALC_SIZE_WSF ; No room for program

	 mov	 EMMBASE,eax	; Save as EMMBASE
endif				; IF @OEM_EMS

; See if we have enough room for program storage
; That is, is PRGSIZE large enough?

; Goto end of resident data area

	 lea	 eax,ZLDATA	; End of data area (note relocatable)
	 add	 eax,PRGBASE	; Plus linear address of our base

if @OEM_EMS
	 call	 ROOM_PHYS	; Make room for the EMS physical page tables
	 call	 ROOM_HFRM	; Make room for the EMS HFRMSAV  table
	 call	 ROOM_RPNTAB	; Make room for the RPN tables
endif				; IF @OEM_EMS

; During ROOM_STACK and beyond the linear address need no
; longer necessarily be less than 64KB

	 call	 ROOM_STACK	; Make room for program stack
	 call	 ROOM_SIRBDEF	; Make room for default SIRB table if P5
	 call	 ROOM_VDS	; Make room for previous VDS table
	 call	 ROOM_PHYS2	; Make room for the EMS physical page tables, II
	 call	 ROOM_IOCHK	; Make room for the I/O port check tables
if @OEM_EMS
	 call	 ROOM_HNDL	; Make room for the EMS HNDLNAME and HNDLCNT tables
endif				; IF @OEM_EMS
if @OEM_XMS
	 call	 ROOM_XMSTAB	; Make room for the XMS tables
endif				; IF @OEM_XMS
	 call	 ROOM_TSS	; Make room for the TSSs
if @OEM_WIN3
	 call	 ROOM_INST	; Make room for UMB instance data
endif				; IF @OEM_WIN3
	 call	 ROOM_OPTE	; Make room for PDE for both overflow PTE tables

	 call	 ROOM_FGROUP	; Make room for FGROUP

	 call	 ROOM_JGROUP	; Make room for JGROUP and DL?GROUP

if @OEM_DPMI
	 call	 ROOM_DPMI2	; Make room for DPMI page directories
				; Multiple of 4KB in size on 4KB boundary
endif				; IF @OEM_DPMI
if @OEM_DMA
	 call	 ROOM_DMASWAP	; Make room for DMA page swapping area
				; Multiple of 4KB in size on 4KB boundary
endif				; IF @OEM_DMA
if @OEM_EMS
	 call	 ROOM_AMRS	; Make room for the Alternate Mapping Register Sets
				; Multiple of 4KB in size on 4KB boundary
endif				; IF @OEM_EMS
if @OEM_SYS eq @OEMSYS_RET
	 call	 ROOM_PSM	; Make room for the Periscope memory
				; Multiple of 4KB in size on 4KB boundary
endif				; IF @OEM_SYS eq @OEMSYS_RET
	 call	 ROOM_PDT	; Make room for the Page Descriptor Table
				; Multiple of 4KB + slop in size on 4KB boundary
if DBG_TRACE
	 call	 ROOM_TRACE	; Make room for the Trace Table
endif				; IF DBG_TRACE
if @OEM_DPMI
	 call	 ROOM_DPMI	; Make room for DPMI tables
endif				; IF @OEM_DPMI
	 call	 ROOM_IOTRAP	; Make room for I/O trapping strucs

	 add	 eax,LOADBYTE	; Plus size of files to be loaded

; Note that LOD modules *MUST* be loaded last as they are
; moved to extended memory already

	 sub	 eax,PRGBASE	; Convert from linear address to offset
	 mov	 PRGTAIL,eax	; Save as offset of PRG tail

; Round up to multiple of 1KB in units of 1KB

	 add	 eax,CON1KB	; Round up
	 dec	 eax		; Less one for rounding
	 shr	 eax,10-0	; Convert from bytes to 1KB

; Compare this size with PRGSIZE

	 cmp	 ax,PRGSIZE	; Izit within range?
	 jbe	 near ptr CALC_SIZE_END ; Yes

	 mov	 PUTSIZE,eax	; Save as putative program size

; Increment PRGSIZE by 4KB

	 add	 PRGSIZE,4	; The right hand giveth

; Not enough room -- try with less remainder
; First try taking the space from REMSIZE
;    If that works, go around again.
; Next	try taking the space from EXTSIZE
;    If that works, go around again.
; Otherwise, if the user didn't specified a size,
;    Try to take 16KB from EMMSIZE
;	If that works, go around again.
;	Otherwise, give up

CALC_SIZE_WSF:
	 sub	 REMSIZE,4	; Subtract it out
	 jnb	 near ptr CALC_SIZE_EMM ; Go around again

	 mov	 REMSIZE,0	; In case not a multiple of 4KB

	 test	 CMD_FLAG,@CMD_EXT ; User specify extended memory size?
	 jnz	 short CALC_SIZE_WSF1 ; Yes, take from EMMSIZE

	 mov	 eax,EXTSIZE	; Get current extended memory size

	 sub	 eax,4		; The left hand taketh away
	 jb	 short CALC_SIZE_PRV ; It's too small

if @OEM_XMS
	 cmp	 eax,HMASIZE	; Check against minimum
	 jb	 short CALC_SIZE_HMA ; It's too small
endif				; IF OEM_XMS

	 cmp	 eax,PRVSIZE	; Check against minimum
	 jb	 short CALC_SIZE_PRV ; It's too small

	 mov	 EXTSIZE,eax	; Save as new size

	 jmp	 CALC_SIZE_EMM	; Join common code

if @OEM_XMS
CALC_SIZE_HMA:
	 mov	 eax,HMASIZE	; Get minimum size
	 mov	 EXTSIZE,eax	; In case not a multiple of 4KB

	 jmp	 short CALC_SIZE_HMAPRV ; Join common code
endif				; IF @OEM_XMS

CALC_SIZE_PRV:
	 mov	 eax,PRVSIZE	; Get minimum size
	 mov	 EXTSIZE,eax	; In case not a multiple of 4KB
CALC_SIZE_HMAPRV:

if @OEM_SYS eq @OEMSYS_HPRS
	 test	 CMD_FLAG,@CMD_EMS ; Did the user specify EMS= ?
	 jz	 short CALC_SIZE_WSF1 ; No, continue on

	 test	 NRD_FLAG,@NRD_WSF ; Have we displayed the WSF message before?
	 jnz	 short CALC_SIZE_WSF1 ; Yes, continue on

	 push	 offset YGROUP:MSG_EMSFULL ; Tell 'em we have to bite into EMMSIZE
	 call	 YMSGOUT2	; Display YGROUP message

	 or	 NRD_FLAG,@NRD_WSF ; Mark as displayed

else
if @OEM_EMS
	 test	 CMD_FLAG,@CMD_EMS ; Did the user specify EMS= ?
	 jnz	 short CALC_SIZE_HMAFULL ; Yes, so honor it
else
	 jmp	 short CALC_SIZE_HMAFULL ; Join common error code
endif				; IF @OEM_EMS
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
CALC_SIZE_WSF1:
if @OEM_EMS
	 mov	 eax,EMMSIZE	; Get current size

	 sub	 eax,16 	; The left hand is busy today
	 jc	 short CALC_SIZE_HMAFULL ; No more room

	 mov	 EMMSIZE,eax	; Save for later use
else
	 jmp	 short CALC_SIZE_HMAFULL ; Join common error code
endif				; IF @OEM_EMS
CALC_SIZE_BACK:
	 jmp	 CALC_SIZE_EMM	; Go around again

CALC_SIZE_HMAFULL:
if @OEM_XMS
	 xor	 eax,eax	 ; Zero a register
	 xchg	 eax,HMASIZE	; Swap and zero
;;;;;;;; add	 EXTSIZE,eax	; Add back in as extended memory

	 and	 ax,ax		; Check for already zero
	 jnz	 short CALC_SIZE_BACK ; Jump if we can steal from HMA
endif				; IF @OEM_XMS

; Attempt to take some RAM from OVRSIZE
; Convert a 4KB block of high DOS memory to Other RAM

	 mov	 al,@XLAT_OVR	; Search for this
	 lea	 di,MEM_MAP	; ES:DI ==> MEM_MAP
	 mov	 cx,MEM_MAP_LEN ; CX = # 512-byte entries
   repne scasb			; Search for it
	 jne	 short CALC_SIZE_WSFULL ; Jump if not found

	 dec	 di		; Back up to previous entry
	 mov	 cx,4096/512	; # 512-byte entries in a 4KB page
	 mov	 al,@XLAT_OTH	; Converted entry type
     rep stosb			; Mark as Other RAM

; Calculate the OVRSIZE value

	 call	 CALC_OVRSIZE	; Count @XLAT_OVR entries

	 jmp	 short CALC_SIZE_BACK ; Go around again

CALC_SIZE_WSFULL:

if @OEM_SYS eq @OEMSYS_HPRS
	 cmp	 PHYSIZE,1024	; Izit a 1MB system?
	 jne	 short CALC_SIZE_WSFULL1 ; No

	 test	 CM2_FLAG,@CM2_X384 ; Skip shadow RAM fill?
	 jnz	 short CALC_SIZE_WSFULL1 ; Yes

	 push	 offset YGROUP:MSG_NOEMS ; Tell 'em we have a problem
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short CALC_SIZE_WSFULL2 ; Join common code

CALC_SIZE_WSFULL1:
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

if @OEM_SIZE
	 call	 SIZE_ERR	; Calculate sizes for error message
else
	 push	 offset YGROUP:MSG_WSFULL ; Tell 'em we have a problem
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SIZE
CALC_SIZE_WSFULL2:
	 stc			; Indicate we didn't succeed

	 jmp	 CALC_SIZE_EXIT ; Join common exit code

CALC_SIZE_END:

if @OEM_VCPI
	 call	 SET_VCPIVARS	; Set VCPI variables
endif				; IF @OEM_VCPI

; Put the ROM, OTHER, and OVRSIZE entries into a Memory Chain Structure

	 call	 FILL_MCS	; Fill it in

; Add REMSIZE back into EXTSIZE

	 xor	 eax,eax	; A convenient zero
	 xchg	 eax,REMSIZE	; Get the remainder, set to zero
	 add	 EXTSIZE,eax	; This is the only place where we can use it

; If the user specified EMS=nnn, calculate the equivalent EXT= value

	 push	 es		; Save for a moment

	 mov	 ax,seg XGROUP	; Get segment of EMMSIZE2
	 mov	 es,ax		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 cmp	 EMMSIZE2,-1	; Is EMS= value from profile specified?
	 stc			; Assume not
	 je	 short CALC_SIZE_XEMM2 ; Jump if not (note CF=1)

	 mov	 eax,EMMSIZE	; Get size of EMS memory
	 add	 eax,EXTSIZE	; Plus size of EXT/XMS memory

	 sub	 eax,EMMSIZE2	; Less size requested
	 jc	 short CALC_SIZE_XEMM2 ; Jump if too small (ignore the value)
				; Note CF=1
	 cmp	 eax,HMASIZE	; Ensure we leave enough room for the HMA
	 jc	 short CALC_SIZE_XEMM2 ; Jump if too small (ignore the value)
				; Note CF=1
	 mov	 EXTSIZE,eax	; Save as desired size of EXT/XMS memory
	 or	 CMD_FLAG,@CMD_EXT ; Mark EXT= as specified

	 mov	 EMMSIZE2,-1	; Disable for next time through

	 clc			; Mark as going around again
CALC_SIZE_XEMM2:
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 jnc	 CALC_SIZE_EMM	; Go around again

; Save EXTSIZE as forced ON value

	 mov	 eax,EXTSIZE	; Get it
	 mov	 EXFSIZE,eax	; Save it

; Calculate the start of the extended memory free chain

	 mov	 eax,HMASIZE	; Get size of HMA (0 or 64KB)
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 add	 eax,CON1MB	; Plus start of extended memory
	 mov	 EXTBASE,eax	; Save for later use

; Calculate the size of the second level page tables
; This size is (TOTSIZE * 1K) + 1MB at 4 bytes per 4MB (rounded up)
; = 4 * Ceil(((TOTSIZE * 1K) + 1MB)/4M)
; = 4 * Ceil(((TOTSIZE + 1K) * 1K)/4M)
; = 4 * Ceil((TOTSIZE + 1K)/4K) in units of one byte

	 mov	 eax,TOTSIZE	; Get total amount of extended memory
	 add	 eax,1024	; Plus 1MB base (in units of 1KB)
	 add	 eax,4*1024-1	; Round up to next multiple of 4KB
	 shr	 eax,12 	; Divide by 4K to get # entries
	 mov	 PDBSIZE,eax	; Save for later use

	 shl	 eax,(22-0)	; Convert from 4MB to bytes
	 mov	 LaPDIREND,eax	; Save for later use

if @OEM_EMS

; Set the total and remaining page count in EMS memory
; Note that because CMPSIZEMM is limited to 256MB, neither
; REMPGCNT nor TOTPGCNT can overflow 16-bits.

	 mov	 eax,CMPSIZEMM	; Get EMS limited size of common memory pool
	 shr	 eax,14-10	; Convert from 1KB to 16KB (size of EMS pages)
	 mov	 REMPGCNT,ax	; Save for later use

	 add	 ax,NPHYSCNV.ELO ; Plus # physical 16KB pages in CNV memory
	 add	 ax,NPHYSSCR.ELO ; Plus # physical 16KB pages in SCREEN memory
	 mov	 TOTPGCNT,ax	; Save for later use

; Calculate the # 2MB "boards" in the EMS system

	 xor	 edx,edx	; Zero to use as dword
	 mov	 eax,CMPSIZEMM	; Get EMS limited size of common memory pool
	 and	 eax,not (16-1) ; Round down to 16KB boundary
	 mov	 ebx,2*1024	 ; Divisor = 2MB per board
	 div	 ebx		; EAX = # full 2MB "boards" in the system,
				; EDX = remainder
; Note that EDX < EBX and because EBX is small, we can use DX instead of EDX.
; Also, because CMPSIZEMM is limited to 256MB, the quotient in EAX is <= 128,
; hence we can use AX instead of EAX.

	 cmp	 dx,1		; Any remainder?
	 cmc
	 adc	 ax,0		; Add in one more if any remainder
	 mov	 NBOARDS,ax	; Save for later use

; Calculate the ending+1 I/O port address for PMR mapping

	 shl	 ax,2		; Times four I/O ports per 2MB "board"
	 add	 ax,PORTPMR	; Plus starting I/O address
	 mov	 PORTPMRZ,ax	; Save for later use
endif				; IF @OEM_EMS

; Calculate linear address of PDTCNV entries

	 mov	 eax,PPDTCNV	; Get starting offset in PDT
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	 mov	 CNVBASE,eax	; Save for later use

; Calculate the end of backfill entries in the PDT

	 mov	 eax,LOWOFF	; Get top of DOS in KB
	 movzx	 ebx,LOWSIZE	; Get size of lowfill (multiple of 4KB in 1KB)
	 add	 eax,ebx	; Add to get offset of backfill entries
;;;;;;;; sh?	 ax,(12-2)-10	; Convert from 1KB to 4KB in dwords
	 mov	 PPDTBACK,eax	; Save for later use

; Calculate the start of 1MB in the PDT

	 mov	 eax,1024	; Get 1MB in KB (multiple of 4KB in 1KB)
;;;;;;;; sh?	 eax,(12-2)-10	; Convert from 1KB to 4KB in dwords
	 mov	 PPDT1MB,eax	; Save for later use

; Calculate end of 1.1MB in the PDT

	 mov	 eax,1024+64	; Get 1.1MB in KB (multiple of 4KB in 1KB)
;;;;;;;; sh?	 eax,(12-2)-10	; Convert from 1KB to 4KB in dwords
	 mov	 PPDT1P1MB,eax	; Save for later use

; Because of a bug in MS-DOS 7, we need to ensure that the first available
; XMS block (at 00110000h = 1092 KB = 1.11MB) is mapped one-to-one linear
; to physical.

	 cmp	 DOSVER,0700h	; Izit MS-DOS 7.00 or later?
	 jb	 short @F	; Jump if not

	 add	 eax,4		; Skip to 1.11MB
@@:
	 mov	 PPDT1W1MB,eax	; Save for later use

; Calculate the start of LOWBASE in the PDT

	 mov	 eax,LOWBASE	; Get value of LOWBASE (multiple of 4KB)
	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PPDTLOW,eax	; Save for later use

; Calculate the start of OVRBASE in the PDT

	 mov	 eax,OVRBASE	; Get value of OVRBASE (multiple of 4KB)
	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PPDTOVR,eax	; Save for later use

if @OEM_EMS

; Calculate the start and end of EMMBASE in the PDT

	 mov	 eax,EMMBASE	; Get value of EMMBASE (multiple of 4KB)
	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PPDTEMM,eax	; Save for later use
	 mov	 ebx,CMPSIZEMM	; Get EMS limited size of common memory pool
	 and	 ebx,not (16-1) ; Round down to 16KB boundary
;;;;;;;; sh?	 ebx,(12-2)-10	; Convert from 4KB in dwords to 1KB
	 add	 eax,ebx	; Plus size of region
	 mov	 PPDTEMMZ,eax	; Save for later use
endif				; IF @OEM_EMS

if @OEM_DMA

; Calculate the start and end of DMA buffer in the PDT

	 mov	 eax,DMA_LA	; Get value of DMA linear address (multiple of 4KB)
	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PPDTDMA,eax	; Save for later use
	 movzx	 ebx,DMASIZE	; Get size of buffer
	 add	 eax,ebx	; Plus size of buffer
	 mov	 PPDTDMAZ,eax	; Save for later use
endif				; IF @OEM_DMA

; Calculate the start of PRGBASE in the PDT

	 mov	 eax,PRGBASE	; Get value of PRGBASE (multiple of 4KB)
	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PPDTPRG,eax	; Save for later use

; Calculate the physical address of PRGBASE

	 mov	 eax,PRGBASE	; Get linear address of PRG if no shadow RAM
	 mov	 ebx,GORSIZE	; Get size of gore region
	 shl	 ebx,10-0	; Convert from 1KB to bytes
	 sub	 eax,ebx	; Less that offset

	 cmp	 SHDSIZE,0	; Any shadow RAM?
	 je	 near ptr CALC_SIZE_XSHD_EXIT ; Not this time

; We're assuming that the program fits into the last shadow RAM entry
; If not, we don't use shadow RAM for program storage

; If SCRBTAB is filled in, use it instead of SHDTAB because of
; SHADOWRAM complications.  The program size might grow to the
; point where it overlaps ROM

	 cmp	 SCRBCNT,0	; Any scrub entries defined?
	 je	 short CALC_SIZE_XSCRB ; Not this time

	 cmp	 XSHDSIZE,0	; Have we been here before?
	 jne	 short CALC_SIZE_XSCRB ; Yes, once is enough

	 mov	 si,SCRBIND	; Get index of next entry
	 sub	 si,size SCRB_STR ; Back off to last entry
	 movzx	 ebx,PGROUP:[si].SCRB_ESIZE ; Get size of last shadow RAM entry

	 sub	 bx,PRGSIZE	; Less size of program
	 jc	 short CALC_SIZE_XSHD0 ; There's no room in shadow RAM

	 mov	 eax,ebx	; Copy to result register
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 add	 eax,PGROUP:[si].SCRB_EBASE ; Plus linear address of start

	 jmp	 short CALC_SIZE_XSHD_EXIT ; Join common code

CALC_SIZE_XSCRB:
	 mov	 si,SHDIND	; Get index of next entry
	 sub	 si,size SHD_STR ; Back off to last entry
	 movzx	 ebx,PGROUP:[si].SHD_ESIZE ; Get size of last shadow RAM entry

	 sub	 bx,PRGSIZE	; Less size of program
	 jc	 short CALC_SIZE_XSHD0 ; There's no room in shadow RAM

	 mov	 eax,ebx	; Copy to result register
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 add	 eax,PGROUP:[si].SHD_EBASE ; Plus linear address of start

	 jmp	 short CALC_SIZE_XSHD_EXIT ; Join common code

CALC_SIZE_XSHD0:

; To ensure the x-shadow RAM is not used for program storage,
; we append PRGSIZE of extended memory as shadow RAM.

	 mov	 eax,PHYSIZE	; Get size of physical memory in KB
	 movzx	 ebx,PRGSIZE	; Get putative size of program

	 sub	 eax,ebx	; Less size of program
	 jc	 short CALC_SIZE_XSHD_ERR ; Jump if no more room

	 cmp	 eax,1024	; Ensure at least 1MB remains
	 jc	 short CALC_SIZE_XSHD_ERR ; Jump if no more room

	 shl	 eax,10-0	; Convert from 1KB to bytes to get base

	 push	 bx		; Amount of shadow RAM in 1KB
	 push	 eax		; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 add	 XSHDSIZE,bx	; Include as excluded shadow memory for stats

	 and	 LCL_FLAG,not @LCL_LML ; Mark as not loading PRG in low memory

	 cmp	 ebx,TOTSIZE	; Enough RAM remaining?
	 jb	 near ptr CALC_SIZE_EMM ; Go around again if there's
				; some extended memory remaining
CALC_SIZE_XSHD_ERR:
	 push	 offset YGROUP:MSG_NOEMS ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message

	 stc			; Indicate we didn't succeed

	 jmp	 CALC_SIZE_EXIT ; Join common exit code

CALC_SIZE_XSHD_EXIT:
	 mov	 PaPRGBASE,eax	; Save for later use
	 mov	 PaPRGBASE2,eax ; Save for later use

; Calculate the start of MAPBASE in the PDT

	 mov	 eax,MAPBASE	; Get value of MAPBASE (multiple of 4KB)
	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PPDTMAP,eax	; Save for later use

; Use OVRBASE as RSVBASE -- start of area protected from swapping

	 mov	 eax,OVRBASE	; Get value of OVRBASE
	 mov	 RSVBASE,eax	; Save as start of reserved area
	 mov	 eax,PPDTOVR	; Get offset of OVRBASE in PDT
	 mov	 PPDTRSV,eax	; Save as start of reserved area

; If we're loading low, ensure that MAPSEG_NXT doesn't cross LMLTOP-PRGSIZE
; (with appropriate unit conversions)

	 test	 LCL_FLAG,@LCL_LML ; Low memory load?
	 jz	 near ptr CALC_SIZE_XLML ; Jump if not

	 mov	 eax,LMLTOP	; Get top of low memory load in 1KB
	 movzx	 ebx,PRGSIZE	; Get size of program in 1KB
	 sub	 eax,ebx	; Less size of program in 1KB

; If we're providing support for Windows, we can't allow LMLTOP-PRGSIZE
; to be below 640KB

	 test	 CM3_FLAG,@CM3_NOWIN3 ; Disabling support for Windows 3?
	 jnz	 short @F	; Jump if so

	 cmp	 eax,640	; Izit below 640KB?
	 jb	 short CALC_SIZE_NOLML ; Jump if so
@@:
	 shl	 eax,10-4	; Convert from 1KB to paras
	 movzx	 ebx,MAPSEG_NXT ; Get next available segment

	 cmp	 eax,ebx	; Does it overlap?
	 jae	 short @F	; Jump if not
CALC_SIZE_NOLML:
	 and	 LCL_FLAG,not @LCL_LML ; Disable low memory load
	 mov	 eax,PHYSIZE	; Get current physical memory size in 1KB
	 mov	 LMLTOP,eax	; Set as low memory top (shouldn't be used)
@@:
	 test	 LCL_FLAG,@LCL_LML ; Loading PRG in low memory?
	 jz	 near ptr CALC_SIZE_XLML ; Jump if not

; Calculate the start of LMLBASE in the PDT
; Ensure it doesn't overlap the reserved area
; Ensure we don't overlap SWAPSIZE

	 mov	 eax,LMLTOP	; Get top of LML (in units of 1KB)

	 cmp	 XSHDSIZE,0	; Any x-shadow RAM?
	 jne	 short @F	; Yes, this problem can't happen

	 cmp	 eax,PPDTRSV	; Check against reserved region
	 jbe	 short @F	; Jump if no overlap

	 sub	 eax,PPDTRSV	; Less reserved offset to get size of overlap
	 sub	 LMLTOP,eax	; Back off from the top
	 mov	 eax,LMLTOP	; Get new top of LML
@@:
	 movzx	 ebx,PRGSIZE	; Get size of PRG including PDT
	 sub	 eax,ebx	; Less size of PRG including PDT

	cmp	eax,1024+64	; Izit below 1.1MB in KB (and thus too small)?
	jb	short CALC_SIZE_XLML0 ; Jump if so (no LML)

	 cmp	 eax,0FFFFh	; Izit bigger than 16-bits?
	 ja	 short @F	; Jump if so

	 cmp	 ax,SWPSIZE	; Check against swapping size
	 jae	 short @F	; It's beyond any swapping region

	 mov	 bx,ax		; Copy to spare register
	 and	 bx,not (4-1)	; Round down to multiple of 4KB
	 mov	 SWPSIZE,bx	; Save back
@@:
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 mov	 LMLBASE,eax	; Save as low memory load base

; If we're running Windows and our starting physical address intrudes into
; the HMA, don't use low memory load

	 test	 CM3_FLAG,@CM3_NOWIN3 ; Disabling support for Windows 3?
	 jnz	 short @F	; Jump if so

	 cmp	 eax,CON1P1MB	; Izit below HMA upper limit?
	 jae	 short @F	; Jump if not

	 cmp	 eax,CON1MB	; Izit at or above HMA lower limit?
	 jae	 short CALC_SIZE_XLML0 ; Jump if so (no LML)
@@:
	 movzx	 ebx,MAPSIZE	; Get size of ROM mapping region in 1KB
	 add	 bx,OVRSIZE	; Plus size of high DOS memory in 1KB
	 shl	 ebx,10-0	; Convert from 1KB to bytes
	 sub	 ebx,eax	; Subtract from physical address
	 neg	 ebx		; Negate to get positive number

	 cmp	 ebx,CON1P1MB	; Izit below HMA upper limit?
	 jae	 short CALC_SIZE_LML ; Jump if not

	 cmp	 ebx,CON1MB	; Izit at or above HMA lower limit?
	 jb	 short CALC_SIZE_LML ; Jump if not (LML is OK)
CALC_SIZE_XLML0:
	 and	 LCL_FLAG,not @LCL_LML ; Disable low memory load

	 jmp	 short CALC_SIZE_XLML ; Join common code

CALC_SIZE_LML:
	 mov	 PaPRGBASE,eax	; Save as new physical address of PRG
	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PPDTLML,eax	; Save for later use
CALC_SIZE_XLML:

; Mark HMA as unavailable if HMASIZE is zero

	 cmp	 HMASIZE,0	; Izit available?
	 jne	 short @F	; Jump if so

	 or	 XMS_FLAG,mask $XMS_XHMA ; Mark as permanently unavailable
@@:

; Use (1024 + HMASIZE + CMPSIZE) * 1024 as MINBASE -- start of our entire reserved area

	 mov	 eax,CMPSIZE	; Get size of common memory pool
	 add	 eax,HMASIZE	; Plus size of HMA (0 or 64KB)
	 add	 eax,CON1KB	; Plus first megabyte
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 mov	 MINBASE,eax	; Save as start of minimum of our entire area

; Ensure SWPSIZE is within RSVBASE bounds

	 mov	 eax,PPDTRSV	; Get offset in PDT of reserved area (multiple of 4KB in 1KB)
;;;;;;;; sh?	 eax,(12-2)-10	; Convert from 4KB in dwords to 1KB
	 sub	 eax,1024	; Less first 1MB

	 cmp	 eax,CON64KB	; Izit bigger than 16-bits?
	 jae	 short CALC_SIZE_SWP ; Jump if so

	 cmp	 ax,SWPSIZE	; Check against size of swapping region
	 jae	 short CALC_SIZE_SWP ; Jump if it's within range

	 and	 ax,not (4-1)	; Ensure it's a multiple of 4KB
	 mov	 SWPSIZE,ax	; Save back
CALC_SIZE_SWP:

if @OEM_EMS

; Abort if EMMSIZE > 0 and another EMS driver is present

	 cmp	 EMMSIZE,0	; Any EMS memory?
	 je	 short CALC_SIZE_NOEMM ; No

	 test	 LCL_FLAG,@LCL_DRV ; Another EMS driver present?
	 jz	 short CALC_SIZE_NOEMM1 ; Not this time

	 push	 offset YGROUP:MSG_NOTDRV ; Give 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message

	 stc			; Indicate we didn't succeed

	 jmp	 CALC_SIZE_EXIT ; Join common exit code

CALC_SIZE_NOEMM:
	 and	 LCL_FLAG,not @LCL_LOWFR ; Hence no low frame
	 mov	 NPHYS16F,0	; Save as no physical 16KB pages in EMS frame
	 call	 CALC_NPHYS	; Re-calculate # physical pages in EMS memory
CALC_SIZE_NOEMM1:
endif				; IF @OEM_EMS
	 cmp	 OVRSIZE,0	; Any high DOS memory?
	 jne	 short CALC_SIZE_NOOVR ; Yes

	 or	 CMD_FLAG,@CMD_XHI ; Mark as not present
CALC_SIZE_NOOVR:
	 cmp	 LOWSIZE,0	; Any low DOS memory?
	 jne	 short CALC_SIZE_NOLOW ; Yes

	 or	 CMD_FLAG,@CMD_XLO ; Mark as not present
CALC_SIZE_NOLOW:
	 call	 CALC_FORCE	; Calculate if we're forced ON

	 mov	 eax,PHYSIZE	; Get top of physical memory
	 sub	 eax,1024	; Less first megabyte

	 test	 GLB_FLAG,@GLB_FORC ; Are we forced on?
	 jnz	 short CALC_SIZE_EXT ; Yes, use EXTSIZE directly

; Because we can be turned off, we cannot reflect any recovered RAM
; in EXTSIZE.  Thus EXTSIZE is the smaller of EXTSIZE and (PHYSIZE-1024).
; In case we are forced ON later (by low DOS memory DMA buffer), the
; original value of EXTSIZE is saved in EXFSIZE.

	 cmp	 eax,EXTSIZE	; Check against size of extended memory
	 ja	 short CALC_SIZE_EXT ; Use EXTSIZE

	 test	 GLB_FLAG,@GLB_AUTO ; AUTO specified (or default)?
	 jnz	 short @F	; Yes, shorten EXTSIZE

	 test	 GLB_FLAG,@GLB_ON ; ON specified (or default)?
	 jz	 short @F	; No, shorten EXTSIZE

	 or	 GLB_FLAG,@GLB_FORC ; Mark as forced ON

	 jmp	 short CALC_SIZE_EXT ; Join common code

@@:
	 mov	 EXTSIZE,eax	; Save for later use
CALC_SIZE_EXT:

; Calculate the # PTEs in the pseudo-1MB unwrap region (0-16)

	 mov	 UNWCNT,0	; Assume no overlap
	 mov	 ebx,PPDTEMM	; Get start of EMMBASE in the PDT
	 mov	 eax,PPDT1P1MB	; Get start of 1.1MB in the PDT

; If we've limited EMS memory to MAX_EMSMEM, then PPDTEMM > PPDT1P1MB,
; and there can't be any overlap

	 cmp	 eax,ebx	; Is there any overlap?
	 jbe	 short CALC_SIZE_XUNW ; Jump if not

	 sub	 ebx,PPDT1MB	; Convert to origin-1MB
	 sub	 eax,PPDT1MB	; Convert to origin-1MB

	 add	 ebx,PPDTCVD	; Convert to origin-CVD
	 add	 eax,PPDTCVD	; Convert to origin-CVD

	 mov	 PPDTUNW,ebx	; Save as start of 1MB unwrap region
	 mov	 PPDTUNWZ,eax	; ...	  end ...

	 cmp	 EMMSIZE,0	; Any EMS memory converted from extended memory?
	 je	 short CALC_SIZE_XUNW ; Jump if not

	 sub	 eax,ebx	; Subtract to get size of 1MB wrap region
	 shr	 eax,12-(12-2)	; Convert from 4KB in dwords to 4KB
	 mov	 UNWCNT,ax	; Save as unwrap region count (# PTEs)
				; (always a multiple of 4)
CALC_SIZE_XUNW:

; When we are turned OFF, we free up the EMS memory pool as extended memory
; This value is min(CMPSIZE+HMASIZE, PHYSIZE-1024)

	 mov	 eax,PHYSIZE	; Get top of physical memory
	 sub	 eax,1024	; Less first megabyte

	 mov	 ebx,CMPSIZE	; Get size of common memory pool
	 add	 ebx,HMASIZE	; Plus size of HMA (0 or 64KB)

	 cmp	 eax,ebx	; Use the smaller of the two as OFFSIZE
	 jbe	 short @F	; Jump if PHYSIZE-1024 is smaller

	 mov	 eax,ebx	; Use CMPSIZE+HMASIZE
@@:
	 cmp	 eax,0FFFFh	; Izit bigger than 16-bits?
	 jbe	 short @F	; Jump if not

	 mov	 ax,0FFFFh	; Use maximum
@@:
	 mov	 OFFSIZE,ax	; Save for later use
	 mov	 ONFSIZE,ax	; Save for later use

if @OEM_DMA

; Clear @CMD_XDM if we're trapping any DMA -- that is,
; if there's any low  DOS memory mapped in, or
; if there's any high DOS memory mapped in, or
; if we're swapping memory in, or
; if we're managing EMS memory, or
; if we're loading PRG in low memory.

	 test	 CMD_FLAG,@CMD_XDM ; User say no?
	 jnz	 short CALC_SIZE_DMA_END ; That's right

	 test	 CMD_FLAG,@CMD_XLO ; Any low DOS memory?
	 jz	 short CALC_SIZE_DMA_END ; Yes, so we need to trap DMA

	 test	 CMD_FLAG,@CMD_XHI ; Any high DOS memory?
	 jz	 short CALC_SIZE_DMA_END ; Yes, so we need to trap DMA

	 cmp	 SWPSIZE,0	; Any memory to swap?
	 jne	 short CALC_SIZE_DMA_END ; Yes, so we need to trap DMA

if @OEM_EMS
	 cmp	 EMMSIZE,0	; Any EMS memory?
	 jne	 short CALC_SIZE_DMA_END ; Yes, so we need to trap DMA
endif				; IF @OEM_EMS

	 test	 LCL_FLAG,@LCL_LML ; Loading PRG in low memory?
	 jnz	 short CALC_SIZE_DMA_END ; Yes, so we need to trap DMA
endif				; IF @OEM_DMA

	 or	 CMD_FLAG,@CMD_XDM ; Mark as no DMA
CALC_SIZE_DMA_END:

; Calculate the offset in PGROUP of each LOD module

	 call	 CALC_LODSTART	; Calculate 'em

	 clc			; Indicate all went well
CALC_SIZE_EXIT:
	 REGREST <dx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_SIZE endp			; End CALC_SIZE procedure

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_SIZ module

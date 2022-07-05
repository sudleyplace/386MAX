;' $Header:   P:/PVCS/MAX/386MAX/QMAX_SYS.ASV   1.2   30 May 1997 10:46:04   BOB  $
	 title	 QMAX_SYS -- 386MAX System Identification
	 page	 58,122
	 name	 QMAX_SYS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Program segment NCODE, byte-aligned,  public, class 'ncode'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'
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
	 include VIDCALL.INC
	 include ASCII.INC
	 include INTVEC.INC
	 include 386.INC
	 include PTR.INC
	 include 8255.INC
	 include ROMSEG.INC
	 include BIOSCONF.INC
	 include BIOSDATA.INC
	 include CPUID.INC
	 include IOCTL.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include DEVDRV.INC
	 include EXE.INC
	 include OPCODES.INC
	 include VDISK.INC
	 include CMOS.INC
	 include EPSON.INC
	 include A20.INC
	 include EISA.INC
	 include 8253.INC
	 include OPEN.INC
	 include HMA.INC
	 include PCI.INC
	 include CPUFET.INC

	 include QMAX_OEM.INC
	 include QMAX_SHD.INC
	 include QMAX_FLX.INC
	 include QMAX_POS.INC
	 include QMAX_CPD.INC
.list

PGROUP	 group	 CODE,HICODE,ECODE,EDATA,NCODE,NDATA
XGROUP	 group	 XCODE,XDATA
YGROUP	 group	 YDATA
CGROUP	 group	 CPUID_SEG


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 PPI_S2C:near
	 extrn	 PPI_S2C_K2S:near

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

if @OEM_SYS eq @OEMSYS_ILIM
	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

	 extrn	 EXTSIZE:dword
	 extrn	 LOWSIZE:word
	 extrn	 SHDSIZE:word
	 extrn	 SWPSIZE:word
	 extrn	 TOTSIZE:dword

	 extrn	 SYSROM_START:word
if @OEM_SYS eq @OEMSYS_3COM or @OEM_SYS eq @OEMSYS_SHS
	 extrn	 RH_VEC:dword
endif				; IF @OEM_SYS eq @OEMSYS_SHS or @OEM_SYS eq @OEMSYS_SHS

	 extrn	 AT386_CFG:byte
	 extrn	 AT386_RAB:byte
	 extrn	 AT386_RCD:byte
	 extrn	 AT386_REF:byte

	 extrn	 CT_ROMCFG:byte
	 extrn	 CT_RAM_AB:byte
	 extrn	 CT_RAM_CD:byte
	 extrn	 CT_RAM_EF:byte

	 extrn	 ACTA20_COMSUB:word
	 extrn	 A20COM_I92:near
	 extrn	 A20COM_QUD:near
	 extrn	 A20COM_XT:near
	 extrn	 A20COM_I78:near

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

HICODE	 ends			; End HICODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 PPI_S2K:near
	 extrn	 PPI_S2K_K2S:near
	 extrn	 WAITOBUF_CLR:near
	 extrn	 READ_CHIPSET:near

ECODE	 ends			; End ECODE segment


DEBUG	 segment use16 byte public 'ecode' ; Start DEBUG segment
	 assume  cs:PGROUP

	 extrn	 FDW2HEX:far

DEBUG	 ends			; End DEBUG segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 NMIPORT:word
	 extrn	 NMIENA:byte
	 extrn	 NMIDIS:byte
	 extrn	 NMIMASK:byte

if @OEM_DMA
	 include QMAX_DMA.INC
endif				; IF @OEM_DMA

if @OEM_XMS
	 extrn	 HMASIZE:dword

	 extrn	 XMS_FLAG:word
	 include QMAX_XMS.INC
endif				; IF @OEM_XMS
	 extrn	 PHYSIZE:dword
	 extrn	 PRVSIZE:dword
	 extrn	 LOWOFF:dword
if @OEM_DMA
	 extrn	 DMA_SWAP:word
endif				; IF @OEM_DMA

if @OEM_DMA
	 extrn	 DMASIZE:word
	 extrn	 DMA_MAX:dword
endif				; IF @OEM_DMA
	 extrn	 CON16KB:dword
	 extrn	 CON1MB:dword
	 extrn	 IO_LIM_MASK:word
	 extrn	 REP_FAC:word
	 extrn	 MAPSEG_NXT:word

	 public  PaMAX
PaMAX	 dd	 ?		; Maximum physical address (possibly discontiguous)

	 public  A20SUP
A20SUP	 dw	 mask $A20_8042 ; Assume we're using an 8042

	 public  LOFFCPQSTR
LOFFCPQSTR dw	 ?		; Offset in CGROUP of CPQSTR

; SHDTAB contains a summary of shadow RAM usage allowing for
; discontiguous physical addresses.  The only requirement is that
; the size of the last entry >= PRGSIZE.

	 public  SHDCNT,SHDIND,SHDTAB
SHDCNT	 dw	 0		; # entries in shadow structure
SHDIND	 dw	 PGROUP:SHDTAB	; Offset of next available entry
SHDTAB	 SHD_STR 10 dup (<>)	; Shadow RAM structure

; SCRBTAB contains a summary of scrub RAM usage allowing for
; discontiguous physical addresses.

	 public  SCRBCNT,SCRBIND,SCRBTAB
SCRBCNT  dw	 0		; # entries in structure
SCRBIND  dw	 PGROUP:SCRBTAB ; Offset of next available entry
SCRBTAB  SCRB_STR 10 dup (<>)	; Shadow RAM structure

	 public  PPMTAB,PPMTAB_LEN
	 include QMAX_PPM.INC
PPMTAB	 db	 (1024/16) dup (@PPM_AVL) ; EMS physical page map, one per 16KB block
PPMTAB_LEN equ	 $-PPMTAB	; Table length in bytes

if @OEM_FLEXROM
	 extrn	 FLEXROM_FLAG:word
	 extrn	 VGA_ALTSEG1:word
	 extrn	 VGA_ALTSEG2:word
	 extrn	 FLEXROM_FLAG:word
endif				; IF @OEM_FLEXROM

	 extrn	 CPUFET_FLAG:dword

EDATA	 ends			; End EDATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

	 extrn	 @XLAT_OVR:abs
	 extrn	 @XLAT_OTH:abs
	 extrn	 @XLAT_UNK:abs
	 extrn	 @XLAT_ROM0:abs
	 extrn	 @XLAT_ROM1:abs
	 extrn	 @XLAT_ROM2:abs
	 extrn	 MEM_MAP:byte

	 extrn	 OLDXMS_VEC:dword

	 extrn	 PICBASE:word

	 extrn	 MOVE_TAB:qword

	 public  DRVPATH_END
DRVPATH_END dw	 ?		; Offset to end+1 of driver's "d:\path\"

if @OEM_BCF
	 public  UCSYSROM_START
UCSYSROM_START dd 0F0000h	; Linear address of uncompressed ROM start
endif				; IF @OEM_BCF

if @OEM_SYS eq @OEMSYS_ILIM or @OEM_SOFT
	 public  FNAM_INBRDPC,FNAM_INBRDAT
FNAM_INBRDPC db  'INBRDPC%',0
FNAM_INBRDAT db  'INBRDAT%',0
endif				; IF @OEM_SYS eq @OEMSYS_ILIM or @OEM_SOFT

	 public  MACHID
MACHID	 db	 ?		; Machine ID byte

NDATA	 ends			; End NDATA segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

	 extrn	 FINDHW_ACT:word
	 extrn	 OLDINTHW_VEC:dword
	 extrn	 ROMADDR:word

	 extrn	 CPQINT01_SAVE:dword

if @OEM_FLEXROM
	 extrn	 NFLEXROMINTS:abs
	 extrn	 FLEXROMINTS:tbyte
endif				; IF @OEM_FLEXROM

	 public  BIOSCONF_VEC
BIOSCONF_VEC dd  0		; Seg:Off of BIOS configuration data (0 if none)

	 public  FAKEINT6D
FAKEINT6D dd	 0C0000000h	; Fake INT 6Dh address

	 public  OLDINT24_VEC
OLDINT24_VEC dd  ?		; Save area for old INT 24h handler

	 public  POSBASE
POSBASE  dw	 ?		; Base I/O address for POS

	 public  MCAID
MCAID	 dw	 @MAXPOSDEV dup (?) ; MCA adapter IDs (including system board)

if @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
	 public  FASTREGS
FASTREGS dw	 0208h		; fASTram base registers
	 dw	 0218h
	 dw	 0258h
	 dw	 0268h
	 dw	 02A8h
	 dw	 02B8h
	 dw	 02E8h
NFASTREGS equ	 ($-FASTREGS)/(type FASTREGS) ; # registers
endif				; IF @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT

	 public  PICDATA
PICDATA  db	 0BAh,0A0h, 00h ; mov	  dx,00A0h
	 db	 0B0h, 19h	; mov	  al,19h
	 db	 0EEh		; out	  dx,al
	 db	 0EBh, 00h	; jmp	  short $+2
	 db	 0EBh, 00h	; jmp	  short $+2
	 db	  42h		; inc	  dx
	 db	  8Bh, 46h, 06h ; mov	  ax,[bp+06]
	 db	  86h,0E0h	; xchg	  ah,al
	 db	 0EEh		; out	  dx,al
PICDATA_LEN equ  $-PICDATA	; Length of PICDATA

	 public  I78DATA
I78DATA  db	 0E4h,78h	; in	  al,78h
	 db	  0Ch, 04h	; or	  al,04h
	 db	 0E6h,78h	; out	  78h,al
I78DATA_LEN equ  $-I78DATA	; Length of I78DATA

	 public  CPQVGASIGN
CPQVGASIGN db	 'Copyright COMPAQ Computer Corporation'
CPQVGASIGN_LEN equ $-CPQVGASIGN ; Length of ...

	 public  CPQVGABUG,CPQVGAFIX
	 public  CPQVGABUG_LEN,CPQVGABUG_LEN2,CPQVGABUG_LEN3
CPQVGABUG db	 0B3h, 00h			; mov	bl,0
	  db	  87h,0FBh			; xchg	di,bx
	  db	 0B9h, 00h, 40h 		; mov	cx,4000
	  db	 0B8h, 20h, 07h 		; mov	ax,0720
	  db	  73h, 05h			; jae	CLR_SCRN
CPQVGAFIX db	 0B9h, 00h, 80h 		; mov	cx,8000
	  db	  33h,0C0h			; xor	ax,ax
						; CLR_SCRN:
CPQVGABUG_LEN equ $-CPQVGABUG	; Length of entire search string
CPQVGABUG_LEN2 equ CPQVGAFIX-CPQVGABUG ; Length of good code in search string
CPQVGABUG_LEN3 equ $-CPQVGAFIX	; Length of buggy code in search string

	 public  CPQVGAPAT,CPQVGAPAT_LEN
CPQVGAPAT db	  33h,0C0h			; xor	ax,ax
	 db	  80h, 3Eh, 49h, 00h, 07h	; cmp	byte ptr [0049],07
	 db	  72h, 03h			; jb	@F
	 db	 0B9h, 00h, 80h 		; mov	cx,8000
						;@@:
	 db	 0E9h,	? ,  ?			; jmp	CLR_SCRN
CPQVGAPAT_LEN equ $-CPQVGAPAT	; Length of CPQVGAPAT

	 public  CPQVGAOFF
CPQVGAOFF dw	 ?		; Offset in C000 of CPQVGABUG code

	 public  CPQVGABUG2
CPQVGABUG2 db	  52h				; push	 dx
	 db	  50h				; push	 ax
	 public  CPQVGABUG2_PAT1
CPQVGABUG2_PAT1 equ $-CPQVGABUG2 ; First patch point
	 db	  8Bh, 16h, 63h, 00h		; mov	dx,[0063]
	 db	 0F6h, 06h, 87h, 00h, 08h	; test	byte ptr [0087],08
	 db	  75h, 0Ch			; jnz	$+0C
	 db	  83h,0C2h, 06h 		; add	dx,+06
	 db	 0ECh				; in	al,dx
	 db	 0B0h, 20h			; mov	al,20
	 db	 0BAh,0C0h, 03h 		; mov	dx,03C0
	 db	 0EEh				; out	dx,al
	 db	 0EBh, 0Ch			; jmp	$+0C
	 db	  83h,0C2h, 04h 		; add	dx,+04
	 db	 0A0h, 65h, 00h 		; mov	al,[0065]
	 db	  0Ch, 08h			; or	al,08
	 db	 0EEh				; out	dx,al
	 db	 0A2h, 65h, 00h 		; mov	[0065],al
	 public  CPQVGABUG2_PAT2
CPQVGABUG2_PAT2 equ $-CPQVGABUG2 ; Second patch point
	 db	  58h				; pop	ax
	 db	  5Ah				; pop	dx
	 db	 0C3h				; ret
CPQVGABUG2_LEN equ $-CPQVGABUG2 ; Length of entire search string

	 public  CPQVGABUG2_RPL1,CPQVGABUG2_RPL1_LEN
CPQVGABUG2_RPL1 label byte	; First replacement string
	 db	  1Eh				; push	ds
	 db	 0E8h,	? ,  ?			; call	PATCH1
CPQVGABUG2_RPL1_LEN equ $-CPQVGABUG2_RPL1 ; Length of replacement string

	 public  CPQVGABUG2_FIX1,CPQVGABUG2_FIX1_LEN
CPQVGABUG2_FIX1 label byte	; First fix string
	 db	  6Ah, 40h			; push	40
	 db	  1Fh				; pop	ds
	 db	  8Bh, 16h, 63h, 00h		; mov	dx,[0063]
	 db	 0C3h				; ret
CPQVGABUG2_FIX1_LEN equ $-CPQVGABUG2_FIX1 ; Length of fix string

	 public  CPQVGABUG2_RPL2,CPQVGABUG2_RPL2_LEN
CPQVGABUG2_RPL2 label byte	; Second replacement string
	 db	 0E9h,	? ,  ?			; jmp	PATCH2
CPQVGABUG2_RPL2_LEN equ $-CPQVGABUG2_RPL2 ; Length of replacement string

	 public  CPQVGABUG2_FIX2,CPQVGABUG2_FIX2_LEN
CPQVGABUG2_FIX2 label byte	; Second fix string
	 db	  1Fh				; pop	ds
	 db	  5Ah				; pop	ax
	 db	  58h				; pop	dx
	 db	 0C3h				; ret
CPQVGABUG2_FIX2_LEN equ $-CPQVGABUG2_FIX2 ; Length of fix string

	 public  CPQVGAOFF2A,CPQVGAOFF2B
CPQVGAOFF2A dw	 ?		; Offset in C000 of 1st patch in CPQVGABUG2 code
CPQVGAOFF2B dw	 ?		; ...		    2nd ...

	 public  CPQVGAPATOFF
@CPQVGAPAT_BEG equ 05FC7h	; Offset in COMPAQ VGA ROM of patch area start
@CPQVGAPAT_END equ 05FE3h	; ...					 end (inclusive)
CPQVGAPATOFF dw  @CPQVGAPAT_BEG ; ... as a read/writable data variable

; Ensure the above patches fit into the ROM patch area
; were they all to be applied at the same time

.errnz (@CPQVGAPAT_END+1-@CPQVGAPAT_BEG) LT (CPQVGAPAT_LEN+CPQVGABUG2_FIX1_LEN+CPQVGABUG2_FIX2_LEN)


if @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2 or @OEM_SOFT
	 public  LCL_OLISIGN
LCL_OLISIGN db	 'COPYRIGHT (C) OLIVETTI'
OLISIGN_LEN equ  $-LCL_OLISIGN	; Length of signature
endif				; IF @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2 or @OEM_SOFT

if @OEM_SOFT
	 public  LCL_ITTSIGN
LCL_ITTSIGN db	 '(C) COPYRIGHT XTRA BUSINESS SYSTEMS'
LCL_ITTSIGN_LEN equ $-LCL_ITTSIGN  ; Length of signature
	 public  LCL_ALCSIGN
LCL_ALCSIGN db	 '(C) COPYRIGHT ALCATEL'
ALCSIGN_LEN equ  $-LCL_ALCSIGN	; Length of signature
endif				; IF @OEM_SOFT

if @OEM_SOFT
	 public  LCL_DELLSIGN
LCL_DELLSIGN db  'Dell System 3' ; Dell Systems signature
LCL_DELLSIGN_LEN equ $-LCL_DELLSIGN ; Length of ...
endif				; IF @OEM_SOFT

if @OEM_SOFT
	 public  LCL_ALRSIGN
LCL_ALRSIGN db	 'Advanced Logic Research Inc.',CR,LF ; ALR Systems signature
	 db	 'FlexCache'
LCL_ALRSIGN_LEN equ $-LCL_ALRSIGN ; Length of ...
endif				; IF @OEM_SOFT

if @OEM_SOFT
	 public  LCL_AMSTRADSIGN
LCL_AMSTRADSIGN db 'AMSTRAD PC' ; '3386SX' ; AMSTRAD PC 3386 SX signature
LCL_AMSTRADSIGN_LEN equ $-LCL_AMSTRADSIGN ; Length of ...
endif				; IF @OEM_SOFT

if @OEM_SOFT
	 public  LCL_ZDSSIGN
LCL_ZDSSIGN db	'ZDS'           ; Zenith Systems signature
LCL_ZDSSIGN_LEN equ $-LCL_ZDSSIGN ; Length of ...

	 public  LCL_ZMSPORT
LCL_ZMSPORT db	  55h,0AAh, 30h,0E9h,0F8h, 28h
	 db	 '10 Copyright 1989, ZDSSVIBM'
LCL_ZMSPORT_LEN equ $-LCL_ZMSPORT ; Length of ...
endif				; IF @OEM_SOFT

if @OEM_SYS eq @OEMSYS_NEC or @OEM_SOFT
	 public  LCL_NECSIGN
LCL_NECSIGN db	'NEC Corporation' ; NEC Systems signature
LCL_NECSIGN_LEN equ $-LCL_NECSIGN ; Length of ...

	 public  LCL_NECSIGNLAP
LCL_NECSIGNLAP db	'UltraLite Versa' ; NEC UltraLight Versa signature
LCL_NECSIGNLAP_LEN equ $-LCL_NECSIGNLAP ; Length of ...

	 public  LCL_NECSXSIGN
LCL_NECSXSIGN db 'SX Plus'      ; NEC SX Plus Systems signature
LCL_NECSXSIGN_LEN equ $-LCL_NECSXSIGN ; Length of ...
endif				; IF @OEM_SYS eq @OEMSYS_NEC or @OEM_SOFT

if @OEM_SYS eq @OEMSYS_GRID or @OEM_SOFT
	 public  LCL_PHOENIXSIGN
LCL_PHOENIXSIGN db 'Phoenix Technologies Ltd' ; Tandy (GRiD) Phoenix BIOS signature
LCL_PHOENIXSIGN_LEN equ $-LCL_PHOENIXSIGN
endif				; IF @OEM_SYS eq @OEMSYS_GRID or @OEM_SOFT

if @OEM_SYS eq @OEMSYS_GRID or @OEM_SOFT
	 public  LCL_TANDYSIGN
LCL_TANDYSIGN db 'Tandy' ; Tandy BIOS signature
LCL_TANDYSIGN_LEN equ $-LCL_TANDYSIGN
endif				; IF @OEM_SYS eq @OEMSYS_GRID or @OEM_SOFT

if @OEM_SYS eq @OEMSYS_ASEM or @OEM_SOFT
	 public  LCL_ASEMSIGN
LCL_ASEMSIGN db 'ASEM'
LCL_ASEMSIGN_LEN equ $-LCL_ASEMSIGN
endif				; IF @OEM_SYS eq @OEMSYS_ASEM or @OEM_SOFT

if @OEM_SYS eq @OEMSYS_EPSON or @OEM_SOFT
	 public  LCL_EPSONSIGN
LCL_EPSONSIGN db 'EPSON'
LCL_EPSONSIGN_LEN equ $-LCL_EPSONSIGN
endif				; IF @OEM_SYS eq @OEMSYS_EPSON or @OEM_SOFT

if @OEM_SYS eq @OEMSYS_TOSH or @OEM_SOFT
	 public  LCL_TOSHSIGN
LCL_TOSHSIGN db  'T5100'
LCL_TOSHSIGN_LEN equ $-LCL_TOSHSIGN
endif				; IF @OEM_SYS eq @OEMSYS_TOSH or @OEM_SOFT

if @OEM_SYS eq @OEMSYS_QUAD386 or @OEM_SOFT
	 public  LCL_QUADSIGN
LCL_QUADSIGN db  'Quadram Quad386XT',0
LCL_QUADSIGN_LEN equ $-LCL_QUADSIGN
endif				; IF @OEM_SYS eq @OEMSYS_QUAD386 or @OEM_SOFT

if @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
	 public  LCL_ASTSIGN
LCL_ASTSIGN db	 'COPYRIGHT AST RESEARCH'
LCL_ASTSIGN_LEN equ $-LCL_ASTSIGN
endif				; IF @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT

if @OEM_SYS eq @OEMSYS_CA or @OEM_SOFT
	 public  LCL_CASIGN
LCL_CASIGN db	 'System: 386'
LCL_CASIGN_LEN equ $-LCL_CASIGN

; The following tables are split into two parts in case the user
; has both video and system BIOS shadowed.  For that case, we must
; append shadow RAM in the opposite order so as to put the 128KB
; chunk at the top.  This allows us to use that RAM for our program
; storage which must fit into contiguous physical memory.

; CA_SIZEx = Amount of shadow RAM in 1KB
; CA_ADDRx = Location of shadow RAM

	 public  CA_SIZE1,CA_ADDR1
	 public  CA_SIZE2,CA_ADDR2
	 align	 2		; Ensure wortd alignment
CA_SIZE1 dw	 384		; 00 = Neither
	 dw	 320		; 01 = System only
	 dw	 128		; 10 = Video only
	 dw	  64		; 11 = Both
CA_ADDR1 dd	 200A0000h	; 00 = Neither	    A000-10000
	 dd	 200A0000h	; 01 = System only  A000- F000
	 dd	 200A0000h	; 10 = Video only   A000- C000
	 dd	 200E0000h	; 11 = Both	    E000- F000
CA_SIZE2 dw	   0		; 00 = Neither
	 dw	   0		; 01 = System only
	 dw	 128		; 10 = Video only
	 dw	 128		; 11 = Both
CA_ADDR2 dd	 20100000h	; 00 = Neither	   10000-10000
	 dd	 200F0000h	; 01 = System only  F000- F000
	 dd	 200E0000h	; 10 = Video only   E000-10000
	 dd	 200A0000h	; 11 = Both	    A000- C000
endif				; IF @OEM_SYS eq @OEMSYS_CA or @OEM_SOFT

if @OEM_SYS eq @OEMSYS_3COM
	 public  TCOM3PLUS,TCOM3OPEN
TCOM3PLUS db	 '?:\3PLUS\3CONFIG\3SPONGE.COM',0 ; Path & Name of file
TCOM3PLUS_LEN equ $-TCOM3PLUS	; Length of text
TCOM3OPEN db	 '..\LANMAN.INI',0
TCOM3OPEN_LEN equ $-TCOM3OPEN	; Length of text

	 public  TCOMBUF
TCOMBUF  db	 80 dup (?)	; Local buffer for 3COM file detection
endif				; IF @OEM_SYS eq @OEMSYS_3COM

if @OEM_SYS eq @OEMSYS_SHS
	 public  OMNISIGN
OMNISIGN db	 'TASKVIEW'     ; Signature for OMNIVIEW (aka TASKVIEW)
OMNISIGN_LEN equ $-OMNISIGN	; Signature length

	 public  OMNIFILE1,OMNIFILE2
OMNIFILE1 db	 'OMNIVIEW.EXE',0 ; Name and extension of file (English version)
OMNIFILE1_LEN equ $-OMNIFILE1	 ; Length of text
OMNIFILE2 db	 'MANGFALD.EXE',0 ; Name and extension of file (Swedish version)
OMNIFILE2_LEN equ $-OMNIFILE2	 ; Length of text

	 public  OMNIBUF
OMNIBUF  db	 80 dup (?)	; Local buffer for OMNIVIEW detection
endif				; IF @OEM_SYS eq @OEMSYS_SHS

if @OEM_SOFT
	 public  SHAD_KEYB_DLY
SHAD_KEYB_DLY	 db	 0	; For systems that change the value at
				; 40:b0 depending on whether or not shadowing
				; is in effect (Dell, ALR), value to blast in
endif

if @OEM_FLEXROM
	 public  UNROM_TEXT
UNROM_TEXT	db	'='
UNROM_TXTSRC	db	'E000,'         ; Source
UNROM_TXTDST	db	'C000;'         ; Destin
endif				; IF @OEM_FLEXROM

	 public  QEXTXXX0
QEXTXXX0 db	 'QEXTXXX0',0   ; Device name for QEXTXXX0

if @OEM_DMA
	 public  DMA_MAX_LEN
DMA_MAX_LEN dw	 @DMA_MAX_LEN	; Maximum size for DMA buffer
endif				; if @OEM_DMA

	 public  LCL_GATEWAYSIGN
LCL_GATEWAYSIGN db 'Gateway 2000' ; Identifies machine with Gateway motherboard
LCL_GATEWAYSIGN_LEN equ $-LCL_GATEWAYSIGN

	 public  MOVPCI
MOVPCI	 db	 66h,0BAh,'PCI ' ; MOV EDX,' ICP'
MOVPCI_LEN equ	 $-MOVPCI	; Length of ...

	 public  AMIBIOS
AMIBIOS  db	 'AMIBIOS(C)AMI' ; Identifying string
AMIBIOS_LEN equ  $-AMIBIOS	; Length of ...

AMIDATE_STR struc		; Date struc which follows the above string

AMIDATE_MM dw	 ?		; Month
AMIDATE_SEP1 db  '/'            ; Separator
AMIDATE_DD dw	 ?		; Day
AMIDATE_SEP2 db  '/'            ; Separator
AMIDATE_CCYY dd  ?		; Century-Year (e.g. '1994')

AMIDATE_STR ends

XDATA	 ends			; End XDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

if @OEM_DEBUG
	 extrn	 MSG_ERRSROM:byte
	 extrn	 MSG_ERRSROM1:byte
	 extrn	 MSG_SHDROM2:byte
	 extrn	 MSG_SHDROM3:byte
	 extrn	 MSG_SHDROM4:byte
endif				; IF @OEM_DEBUG

if @OEM_SYS eq @OEMSYS_QUAD386
	 extrn	 MSG_XQUAD:byte
elseif @OEM_SYS eq @OEMSYS_CA
	 extrn	 MSG_XCA:byte
elseif @OEM_SYS eq @OEMSYS_ASEM
	 extrn	 MSG_XASEM:byte
elseif @OEM_SYS eq @OEMSYS_AM1 or @OEM_SYS eq @OEMSYS_AM2
	 extrn	 MSG_XAM1:byte
elseif @OEM_SYS eq @OEMSYS_AM3
	 extrn	 MSG_XAM3:byte
elseif @OEM_SYS eq @OEMSYS_EPSON
	 extrn	 MSG_XEPSON:byte
elseif @OEM_SYS eq @OEMSYS_TOSH
	 extrn	 MSG_XTOSH:byte
elseif @OEM_SYS eq @OEMSYS_AST386
	 extrn	 MSG_XAST:byte
elseif @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 MSG_XHPRS:byte
elseif @OEM_SYS eq @OEMSYS_GRID
	 extrn	 MSG_XGRID:byte
elseif @OEM_SYS eq @OEMSYS_OLI
	 extrn	 MSG_XOLI:byte
elseif @OEM_SYS eq @OEMSYS_OL2
	 extrn	 MSG_XOLI:byte
elseif @OEM_SYS eq @OEMSYS_NEC
	 extrn	 MSG_XNEC:byte
				; IF @OEM_SYS eq @OEMSYS_NEC
				; IF @OEM_SYS eq @OEMSYS_OL2
				; IF @OEM_SYS eq @OEMSYS_OLI
				; IF @OEM_SYS eq @OEMSYS_GRID
				; IF @OEM_SYS eq @OEMSYS_HPRS
				; IF @OEM_SYS eq @OEMSYS_AST386
				; IF @OEM_SYS eq @OEMSYS_TOSH
				; IF @OEM_SYS eq @OEMSYS_CA
				; IF @OEM_SYS eq @OEMSYS_EPSON
				; IF @OEM_SYS eq @OEMSYS_AM3
				; IF @OEM_SYS eq @OEMSYS_AM1 or @OEM_SYS eq @OEMSYS_AM2
				; IF @OEM_SYS eq @OEMSYS_ASEM
endif				; IF @OEM_SYS eq @OEMSYS_QUAD386

if @OEM_SYS eq @OEMSYS_ILIM
	 extrn	 MSG_NOINBRDPC:byte
	 extrn	 MSG_NOINBRDAT:byte
	 extrn	 MSG_NOINBRDPS:byte
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

if @OEM_SYS eq @OEMSYS_3COM
	 extrn	 MSG_NO3COM:byte
endif				; IF @OEM_SYS eq @OEMSYS_3COM

if @OEM_SYS eq @OEMSYS_SHS
	 extrn	 MSG_NOOMNI:byte
endif				; IF @OEM_SYS eq @OEMSYS_SHS

YDATA	 ends			; End YDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_SYS_XCODE
@QMAX_SYS_XCODE:		; Mark module start in .MAP file

	 extrn	 FINDHW:far
	 extrn	 FINDCHK:far
	 extrn	 FIND13:far
	 extrn	 FCN_NOXRAM:far
if @OEM_SOFT
	 extrn	 FCN_NOCOMPROM:far
endif				; IF @OEM_SOFT
	 extrn	 FMT_ERR_CODE:far
	 extrn	 YMSGOUT2:near
;;;;;;;; extrn	 FILL_ROM:far
if @OEM_SRAM or @OEM_SYS eq @OEMSYS_HPRS or @OEM_SYS eq @OEMSYS_NEC
	 extrn	 FCN_SHADOWRAM:far
endif				; IF @OEM_SRAM or @OEM_SYS eq @OEMSYS_HPRS or @OEM_SYS eq @OEMSYS_NEC
if @OEM_HIFILL
	 extrn	 COMPROM:near
endif				; IF @OEM_HIFILL
if @OEM_FLEXROM
	 extrn	 FCN_VGASWAP:far
	 extrn	 PROCESS_FLEXFILE:proc
endif				; IF @OEM_FLEXROM
	 extrn	 SET_NOSCAN:near
	 extrn	 DISP_CPDMSG:far
	 extrn	 CPQZAPSTR:near
if @OEM_CPQCUT
	 extrn	 CHECK_LOSTINT:near
endif				; IF @OEM_CPQCUT

	 FPPROC  LCL_INT24 -- DOS Critical Error Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DOS critical error interrupt handler.

Cut back the stack to the INT 21h caller,
set CF, and RETF 2.

|

ARG_STR  struc

	 dw	 ?		; Caller's BP
ARG_CSIP dd	 ?		; Caller's return address
ARG_FLG  dw	 ?		; Caller's flags

ARG_STR  ends

	 add	 sp,3*2 	; Strip off IP, CS, FL from INT 24h caller

	 REGREST <ax,bx,cx,dx,si,di,bp,ds,es> ; Restore INT 21h caller's regs
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 DOSCALL @GETDSK	; Request DOS service to ensure stable

; Set caller's flags (IF is the only significant one)

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack
	 push	 [bp].ARG_FLG	; Put flags onto stack
	 popf			; Restore caller's IF
	 pop	 bp		; Restore

	 stc			; Ensure set to indicate error

	 ret	 2		; Return to INT 21h caller, popping flags

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT24 endp			; End LCL_INT24 procedure
	 FPPROC  INST24 -- Install INT 24h Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,ds,es>	; Save registers

	 push	 seg XGROUP	; Setup DS for data references
	 pop	 ds
	 assume  ds:XGROUP	; Tell the assembler about it

	 push	 seg INTVEC	; Prepare to address segment zero
	 pop	 es		; Hello, segment zero
	 assume  es:INTVEC	; Tell the assembler about it

	 cli			; Nobody move

	 lea	 ax,LCL_INT24	; Get & set offset
	 xchg	 ax,INT00_VEC.VOFF[24h*type INT00_VEC]
	 mov	 OLDINT24_VEC.VOFF,ax ; Save to restore later

	 mov	 ax,seg XGROUP	; Get & set segment
	 xchg	 ax,INT00_VEC.VSEG[24h*type INT00_VEC]
	 mov	 OLDINT24_VEC.VSEG,ax ; Save to restore later

	 sti			; Allow interrupts

	 REGREST <es,ds,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST24	 endp			; End INST24 procedure
	 FPPROC  REST24 -- Restore INT 24h Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore old INT 24h handler
N.B.:  No flags may be changed.

|

	 REGSAVE <eax,es>	; Save registers

	 push	 seg INTVEC	; Prepare to address segment zero
	 pop	 es		; Hello, segment zero
	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 eax,OLDINT24_VEC ; EAX ==> old interrupt handler
	 mov	 INT00_VEC[24h*type INT00_VEC],eax ; Restore Seg:Off

	 REGREST <es,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST24	 endp			; End REST24 procedure
	 NPPROC  FINDHW_ROM -- Action Routine If Tripping Address Found
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action routine if tripping address found in CPQINT01_SAVE.
Do nothing.

Note that this routine is used in CHECK_BCF.

|

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDHW_ROM endp 		; End FINDHW_ROM procedure
	 FPPROC  ROMINT10 -- ROM Interrupt Check For INT 10h
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

ROM interrupt check for INT 10h.

On exit:

CF	 =	 0 if INT 10h found
	 =	 1 if not

|

	 REGSAVE <ax,ds>	; Save registers

	 push	 seg XGROUP	; Get the segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

; Set address of action routine if found

	 mov	 FINDHW_ACT,offset XGROUP:FINDHW_ROM ; Save it
	 mov	 ROMADDR,0C000h ; Set lowest expected ROM address

	 mov	 ah,@GETINF	; Get video information
	 call	 FINDHW 	; Find original interrupt vector
				; Return with CF significant

	 REGREST <ds,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMINT10 endp			; End ROMINT10 procedure
	 FPPROC  ROMINT11 -- ROM Interrupt Check For INT 11h
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

ROM interrupt check for INT 11h.

On exit:

CF	 =	 0 if INT 11h found
	 =	 1 if not

|

	 REGSAVE <ax,si,ds>	; Save registers

	 push	 seg XGROUP	; Get the segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 xor	 si,si		; Ensure we don't call SCSI services

; Set address of action routine if found

	 mov	 FINDHW_ACT,offset XGROUP:FINDHW_ROM ; Save it
	 mov	 ROMADDR,di ; Set lowest expected ROM address

	 call	 FINDCHK	; Find original interrupt vector
				; Return with CF significant

	 REGREST <ds,si,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMINT11 endp			; End ROMINT11 procedure
	 FPPROC  ROMINT13 -- ROM Interrupt Check For INT 13h
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

ROM interrupt check for INT 13h.

On exit:

CF	 =	 0 if INT 13h found
	 =	 1 if not

|

	 REGSAVE <ax,ds>	; Save registers

	 push	 seg XGROUP	; Get the segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

; Set address of action routine if found

	 mov	 FINDHW_ACT,offset XGROUP:FINDHW_ROM ; Save it
	 mov	 ROMADDR,di ; Set lowest expected ROM address

	 call	 FIND13 	; Find original interrupt vector
				; Return with CF significant

	 REGREST <ds,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMINT13 endp			; End ROMINT13 procedure
	 FPPROC  ROMINT6D -- ROM Interrupt Check For INT 6Dh
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

ROM interrupt check for INT 6Dh.

Thanks to the folks who brought you the DEPCA card, we must
waffle here.  In particular, we attempt to root out the address
of INT 6Dh which switches into ROM, and check it, but the DEPCA
hooks this interrupt and doesn't always pass it through to the
original ROM holder.

|

	 REGSAVE <ax,ds>	; Save registers

	 push	 seg XGROUP	; Get the segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

; Set address of action routine if found

	 mov	 FINDHW_ACT,offset XGROUP:FINDHW_ROM ; Save it
	 mov	 ROMADDR,0C000h ; Set lowest expected ROM address

	 mov	 ah,@GETINF	; Get video information
	 call	 FINDHW 	; Find original interrupt vector
	 jnc	 short ROMINT6D_EXIT ; Jump if found

	 mov	 CPQINT01_SAVE.VSEG,cs ; Fake it so we don't fail
	 mov	 CPQINT01_SAVE.VOFF,offset cs:FAKEINT6D

	 clc			; Mark as successful
ROMINT6D_EXIT:
	 REGREST <ds,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMINT6D endp			; End ROMINT6D procedure
	 FPPROC  SAVE_SHADOW -- Append to Shadow RAM Structure
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save shadow RAM information in structure.

|

SAVE_SHADOW_STR struc

	 dw	 ?		; Caller's BP
	 dd	 ?		; Caller's CS:IP
SAVE_SHADOW_BASE dd ?		; Base address
SAVE_SHADOW_SIZE dw ?		; Size in 1KB

SAVE_SHADOW_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,si,ds>	; Save registers

	 push	 seg PGROUP	; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

; Validate the input variables

	 cmp	 [bp].SAVE_SHADOW_BASE,0 ; Does the base equal zero?
	 je	 short SAVE_SHADOW_EXIT ; Jump if nothing to add

	 cmp	 [bp].SAVE_SHADOW_SIZE,0 ; Does the size equal zero?
	 je	 short SAVE_SHADOW_EXIT ; Jump if nothing to add

; See if we can merge this entry with the previous one

	 cmp	 SHDCNT,0	; Any previous entries?
	 je	 short SAVE_SHADOW1 ; Not this time

	 mov	 si,SHDIND	; Get offset of next index
	 sub	 si,size SHD_STR ; Back off to previous entry

	 movzx	 eax,PGROUP:[si].SHD_ESIZE ; Get previous size in 1KB
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 add	 eax,PGROUP:[si].SHD_EBASE ; Add in previous base
				; to get next base

	 cmp	 eax,[bp].SAVE_SHADOW_BASE ; Same as new base?
	 jne	 short SAVE_SHADOW1 ; No, so there's a discontiguity

	 mov	 ax,[bp].SAVE_SHADOW_SIZE ; Get size of shadow RAM
	 add	 PGROUP:[si].SHD_ESIZE,ax ; Add into previous size
	 add	 SHDSIZE,ax	; Add into cumulative count, too

	 jmp	 short SAVE_SHADOW_COMMON ; Join common shadow code

SAVE_SHADOW1:
	 mov	 si,SHDIND	; Get offset of next index

	 mov	 ax,[bp].SAVE_SHADOW_SIZE ; Get size of shadow RAM
	 mov	 PGROUP:[si].SHD_ESIZE,ax ; Save in shadow RAM structure
	 add	 SHDSIZE,ax	; Add into cumulative count, too

	 mov	 eax,[bp].SAVE_SHADOW_BASE ; Get base of shadow RAM
	 mov	 PGROUP:[si].SHD_EBASE,eax ; Save in shadow RAM structure

	 add	 SHDIND,size SHD_STR ; Skip to next entry
	 inc	 SHDCNT 	; Count in another entry
SAVE_SHADOW_COMMON:
	 mov	 si,SHDIND	; Get offset of next index
	 sub	 si,size SHD_STR ; Skip to last entry
	 movzx	 eax,PGROUP:[si].SHD_ESIZE ; Get last size
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 add	 eax,PGROUP:[si].SHD_EBASE ; Plus starting base

	 cmp	 eax,PaMAX	; Check against maximum physical address so far
	 jbe	 short @F	; Jump if no new maximum

	 mov	 PaMAX,eax	; Save as new maximum
@@:
SAVE_SHADOW_EXIT:
	 REGREST <ds,si,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_SHADOW endp		; End SAVE_SHADOW procedure
	 FPPROC  SAVE_SCRUB -- Append to Scrub RAM Structure
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save scrub RAM information in structure.

|

SAVE_SCRUB_STR struc

	 dw	 ?		; Caller's BP
	 dd	 ?		; Caller's CS:IP
SAVE_SCRUB_BASE dd ?		; Base address
SAVE_SCRUB_SIZE dw ?		; Size in 1KB

SAVE_SCRUB_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,si,ds>	; Save registers

	 push	 seg PGROUP	; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

; See if we can merge this entry with the previous one

	 cmp	 SCRBCNT,0	; Any previous entries?
	 je	 short SAVE_SCRUB1 ; Not this time

	 mov	 si,SCRBIND	; Get offset of next index
	 sub	 si,size SCRB_STR ; Back off to previous entry

	 movzx	 eax,PGROUP:[si].SCRB_ESIZE ; Get previous size in 1KB
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 add	 eax,PGROUP:[si].SCRB_EBASE ; Add in previous base
				; to get next base

	 cmp	 eax,[bp].SAVE_SCRUB_BASE ; Same as new base?
	 jne	 short SAVE_SCRUB1 ; No, so there's a discontiguity

	 mov	 ax,[bp].SAVE_SCRUB_SIZE ; Get size of shadow RAM
	 add	 PGROUP:[si].SCRB_ESIZE,ax ; Add into previous size

	 jmp	 short SAVE_SCRUB_EXIT ; Join common exit code

SAVE_SCRUB1:
	 mov	 si,SCRBIND	; Get offset of next index

	 mov	 ax,[bp].SAVE_SCRUB_SIZE ; Get size of shadow RAM
	 mov	 PGROUP:[si].SCRB_ESIZE,ax ; Save in shadow RAM structure

	 mov	 eax,[bp].SAVE_SCRUB_BASE ; Get base of shadow RAM
	 mov	 PGROUP:[si].SCRB_EBASE,eax ; Save in shadow RAM structure

	 add	 SCRBIND,size SCRB_STR ; Skip to next entry
	 inc	 SCRBCNT	; Count in another entry
SAVE_SCRUB_EXIT:
	 REGREST <ds,si,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_SCRUB endp 		; End SAVE_SCRUB procedure
	 FPPROC  MARK_XT -- Mark as PC/XT Present
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark as PC/XT present.

|

	 or	 LCL_FLAG,@LCL_XT ; Mark as PC/XT present
	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_XT ; Save routine addr

	 mov	 NMIPORT,0A0h	; NMI clear I/O port
	 mov	 NMIENA,80h	; ... enable value
	 mov	 NMIDIS,00h	; ... disable value
	 mov	 NMIMASK,mask $XTPAR ; ... clear mask

	 or	 CM3_FLAG,@CM3_XLHI ; Mark as LOADHI not allowed
	 or	 CMD_FLAG,@CMD_XRM ; Mark as NOROM

if @OEM_DMA
	 mov	 DMASIZE,@DMA_DSK ; Use hard disk transfer buffer size
	 mov	 DMA_MAX,@DMA_PA_XT ; Mark as maximum DMA physical address

; Use the top of original DOS for DMA swapping
; Note we use 128KB in case there's a 64KB DMA boundary error

	 push	 ax		; Save for a moment

	 mov	 ax,LOWOFF.ELO	; Get top of original DOS in 1KB
	 sub	 ax,128 	; Back off 128KB
	 shr	 ax,16-10	; Convert from 1KB to 64KB
	 mov	 DMA_SWAP,ax	; Use low memory for DMA swapping

	 pop	 ax		; Restore
endif				; IF @OEM_DMA
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARK_XT  endp			; End MARK_XT procedure
	 NPPROC  GET_POSID -- Get POS ID For A Slot
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get the POS ID for a slot.

On entry:

BL	 =	 slot # (origin-1 or 0 for system board)

On exit:

AX	 =	 POS ID or -1 if call failed (slot invalid)

|

	 REGSAVE <dx>		; Save register

	 or	 bl,bl		; Izit the system board?
	 jnz	 short @F	; Jump if not

; Put system board into setup mode

	 in	 al,94h 	; Get current system board setup register
	 jmp	 short $+2	; I/O delay

	 and	 al,not @BIT7	; Clear enable bit
	 out	 94h,al 	; Put system board into setup mode
;;;;;;;; jmp	 short $+2	; I/O delay
	 jmp	 short GET_POSID_COM1 ; Join common code

@@:
	 mov	 ax,0C401h	; Function code to setup adapter in slot BL
	 int	 15h		; Request BIOS service
	 mov	 ax,-1		; Assume call failed; no adapter present
	 jc	 short GET_POSID_EXIT ; Jump if something went wrong

GET_POSID_COM1:
	 cli			; Disallow interrupts

	 mov	 dx,POSBASE	; Adapter ID LSB register
	 in	 al,dx		; Get LSB of adapter ID

	 mov	 ah,al		; Save for later use
	 inc	 dx		; Skip to adapter MSB register

	 in	 al,dx		; Get MSB of adapter ID

	 xchg	 al,ah		; Swap to comparison order

	 push	 ax		; Save for a moment

	 or	 bl,bl		; Izit the system board?
	 jnz	 short @F	; Jump if not

; Put system board into enable mode

	 in	 al,94h 	; Get current system board setup register
	 jmp	 short $+2	; I/O delay

	 or	 al,@BIT7	; Set enable bit
	 out	 94h,al 	; Put system board into setup mode
;;;;;;;; jmp	 short $+2	; I/O delay
	 jmp	 short GET_POSID_COM2 ; Join common code

@@:
	 mov	 ax,0C402h	; Function code to enable adapter in slot BL
	 int	 15h		; Request BIOS service

GET_POSID_COM2:
	 pop	 ax		; Restore
	 sti			; Allow interrupts
;;;;;;;; jc	 short GET_POSID_EXIT ; Jump if something went wrong
GET_POSID_EXIT:
	 REGREST <dx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_POSID endp			; End GET_POSID procedure
	 NPPROC  SRCHSTR -- Search For A String
	 assume  ds:PGROUP,es:nothing,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Search for a string.

On entry:

On exit:

DI	 =	 offset of match in ROM
CF	 =	 0 if found
	 =	 1 if not

|

SRCHSTR_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
SRCHSTR_LEN1 dw  ?		; Length of string
SRCHSTR_OFF1 dw  ?		; Offset of string in XGROUP
SRCHSTR_LEN2 dw  ?		; Length of search area
SRCHSTR_VEC2 dd  ?		; Ptr to area to search

SRCHSTR_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,si,es>	; Save registers

	 les	 di,[bp].SRCHSTR_VEC2 ; ES:DI ==> start of search area
	 assume  es:nothing	; Tell the assembler about it

	 mov	 si,[bp].SRCHSTR_OFF1 ; FS:SI ==> source string
	 mov	 cx,[bp].SRCHSTR_LEN2 ; Get length of search area
	 sub	 cx,[bp].SRCHSTR_LEN1 ; Less length of the string
	 dec	 cx		; Less one to not fall off the end
	 mov	 al,XGROUP:[si] ; Get the first byte
SRCHSTR_NEXT:
	 jcxz	 SRCHSTR_ERR	; Jump if no more bytes to check
   repne scas	 es:[di].LO	; Search for the 1st byte
	 jne	 short SRCHSTR_ERR ; Jump if no match

	 REGSAVE <cx,di>	; Save registers
	 mov	 si,[bp].SRCHSTR_OFF1 ; FS:SI ==> source string
	 inc	 si		; Plus one to account for the first match
	 mov	 cx,[bp].SRCHSTR_LEN1 ; Get length of the string
	 dec	 cx		; Less one to account for the first match
    repe cmps	 XGROUP:[si].LO,es:[di].LO ; Check the rest
	 REGREST <di,cx>	; Restore
	 jne	 short SRCHSTR_NEXT ; Jump if no match

	 dec	 di		; Back off to start of match

	 clc			; Mark as found

	 jmp	 short SRCHSTR_EXIT ; Join common exit code

SRCHSTR_ERR:
	 stc			; Mark as not found
SRCHSTR_EXIT:
	 REGREST <es,si,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2+2+4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCHSTR  endp			; End SRCHSTR procedure
	 FPPROC  CHECK_DEVICE -- Check On Device Driver
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine whether or not a specified device driver is already installed.

On entry:

DS:DX	 ==>	 device driver name

On exit:

CF	 =	 0 installed
	 =	 1 not installed

|

	 REGSAVE <ax,bx,dx,es>	; Save registers

	 push	 seg XGROUP	; Get segment of OLDINT24_VEC
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 push	 OLDINT24_VEC	; Save old INT 24h handler's address
	 call	 INST24 	; Install local INT 24h handler

	 mov	 al,0		; Function code for read-only access
	 stc			; Assume error
	 DOSCALL @OPENF2	; Try to open the device driver
	 jc	 short CHECK_DEVICE_EXIT ; No luck (note CF=1)

	 mov	 bx,ax		; Copy to handle register
	 mov	 al,0		; Function code to get device information
	 DOSCALL @IOCTL2	; Return with device info in DX

	 DOSCALL @CLOSF2	; Close it up

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jnz	 short CHECK_DEVICE_EXIT ; Yes, it's installed (note CF=0)

	 stc			; Indicate it's not installed
CHECK_DEVICE_EXIT:
	 call	 REST24 	; Restore INT 24h handler
	 pop	 OLDINT24_VEC	; Restore old INT 24h handler's address

	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DEVICE endp		; End CHECK_DEVICE procedure
	 NPPROC  CHECK_288 -- Check for 2.88 MB Diskette Drive
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for 2.88 MB diskette drive.
If present, set DMASIZE to @DMA_288.

|

	 REGSAVE <ax,bx,cx,dx,di,es> ; Save registers

	 mov	 dl,0		; Diskette drive #0
	 mov	 ah,08h 	; Code to read drive parameters
	 int	 13h		; Request diskette service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_288_EXIT ; Jump if not valid
				; Return with
				; AX = 0
				; BL = 01 for 360 KB,  5¬, 40 tpi
				;    = 02 for 1.2 MB,  5¬, 80 tpi
				;    = 03 for 720 KB,  3«, 80 tpi
				;    = 04 for 1.44 MB, 3«, 80 tpi
				;    = 05 for ???
				;    = 06 for 2.88 MB, 3«, ?? tpi
				; BH = 0
				; CL =
				; CH =
				; DL = # diskette drives installed
				; DH = maximum head #
				; ES:DI ==> drive parameter table
				; CF = 0 if above is valid
				;    = 1 if not

	 cmp	 bl,06h 	; Izit a 2.88MB drive?
	 je	 short CHECK_288_D64 ; Jump if so

	 movzx	 cx,dl		; Copy # diskette drives installed
	 jcxz	 CHECK_288_EXIT ; Jump if none???

	 mov	 dl,0		; Diskette drive #0
CHECK_288_NEXT:
	 REGSAVE <cx,dx>	; Save for a moment

	 mov	 ah,08h 	; Code to read drive parameters
	 int	 13h		; Request diskette service
	 assume  es:nothing	; Tell the assembler about it
	 REGREST <dx,cx>	; Restore
	 jc	 short CHECK_288_EXIT ; Jump if not valid

	 cmp	 bl,06h 	; Izit a 2.88MB drive?
	 je	 short CHECK_288_D64 ; Jump if so

	 inc	 dl		; Skip to next diskette drive

	 loop	 CHECK_288_NEXT ; Jump if more diskette drives to check

	 jmp	 short CHECK_288_EXIT ; Join common exit code

CHECK_288_D64:
	 mov	 DMASIZE,@DMA_288 ; Use 2.88MB diskette transfer buffer size
CHECK_288_EXIT:
	 REGREST <es,di,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_288 endp			; End CHECK_288 procedure
	 FPPROC  CHECK_MODEL -- Check for MCA-Compatible Machines
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for MCA-compatible, EISA, and a whole bunch more machines.

|

	 REGSAVE <ax,bx,cx,dx,di,es,fs> ; Save registers

	 push	 seg CGROUP	; Get ROM BIOS segment
	 pop	 es		; Address via segment register
	 assume  es:CGROUP	; Tell the assembler about it

	 push	 seg XGROUP	; Get extra data segment
	 pop	 fs		; Address via segment register
	 assume  fs:XGROUP	; Tell the assembler about it

	 mov	 al,BIOSCPUID	; Get the machine ID byte
	 mov	 MACHID,al	; Save for later use

; Check for 2.88 MB diskette drives

	 call	 CHECK_288	; Check it

; Check on using I/O port 92h for toggling A20

	 mov	 ax,@A20_SUP	; A20 function, Query A20 gate support
	 int	 15h		; Request BIOS service

	 cmp	 ah,0		; Did it succeed?
	 jne	 short @F	; Jump if not

	 mov	 A20SUP,bx	; Save for later use
	 or	 NRD_FLAG,@NRD_A20FN ; Mark as services present

	 test	 bx,mask $A20_I92 ; Duzit use I/O port 92h to toggle A20?
	 jz	 short @F	; Jump if not

	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_I92 ; Save routine addr
@@:

; If this BIOS doesn't support A20 Architecture functions,
; check for I/O port 92h gating of A20

	 test	 NRD_FLAG,@NRD_A20FN ; Are A20 Architecture services present?
	 jnz	 short @F	; Jump if so

	 call	 CHECK_I92	; Check for I/O port 92h A20 gating
@@:

; Ensure far jump at REBOOTD -- if not, set NOWARMBOOT

	 cmp	 REBOOTD.LO,@OPCOD_JMPF ; Izit a far jump?
	 je	 short @F	; Jump if so

	 or	 CM2_FLAG,@CM2_NWB ; Mark as NOWARMBOOT
@@:

; Save pointer to BIOS configuration data (if supported)

	 push	 es		; Save for a moment

	 mov	 ah,0C0h	; Attempt to read configuration record
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short @F	; Jump if error

	 cmp	 ah,80h 	; Check for error return
	 je	 short @F	; Jump if error

	 cmp	 ah,86h 	; Check for error return
	 je	 short @F	; Jump if error

	 mov	 BIOSCONF_VEC.VOFF,bx ; Save for later use
	 mov	 BIOSCONF_VEC.VSEG,es ; ...
@@:
	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it

; Check for EISA signature at F000:FFD9

; Some early EISA machines don't follow the spec, they put their
; signature somewhere else in the BIOS.  However, We can't search
; through the entire BIOS, because many ISA machines have EISA
; strings that we would pick up as false positives.

	 cmp	 dword ptr EISASIGN,'ASIE' ; Check for EISA signature
	 jne	 short CHECK_MODEL_XEISA ; Jump if not EISA machine

	 or	 NRD_FLAG,@NRD_EISA ; Mark as present (EISA machine)
	 jmp	 CHECK_MODEL_DMA32 ; 32-bit DMA present

CHECK_MODEL_XEISA:

; Because some device drivers which may precede us don't correctly
; take their corresponding adapter out of setup mode, we do that
; here for all adapters

	 mov	 ax,0C400h	; Major POS function, minor to get POS base
	 int	 15h		; Request BIOS service
	 jc	 near ptr CHECK_MODEL_XMCA ; Jump if not Micro Channel

	 mov	 POSBASE,dx	; Save as base I/O address for POS

	 mov	 cx,8		; # slots
	 mov	 bl,1		; Start with slot #1
@@:
	 mov	 ax,0C402h	; Major POS function, minor to enable adapter
	 int	 15h		; Request BIOS service
	 jc	 short CHECK_MODEL_XMCA ; Jump if not Micro Channel

	 inc	 bl		; Skip to next slot

	 loop	 @B		; Jump if more slots to enable

; Check for MCA-compatible machines

	 cmp	 BIOSCONF_VEC.VSEG,0 ; Izit valid?
	 je	 short CHECK_MODEL_XMCA; Jump if not

	 les	 bx,BIOSCONF_VEC ; ES:BX ==> BIOS configuration data
	 assume  es:nothing	; Tell the assembler about it

	 test	 es:[bx].CFG_PARMS,@CFG_MCA ; Izit a Micro Channel Architecture?
	 jz	 short CHECK_MODEL_XMCA ; Not this time

	 or	 LCL_FLAG,@LCL_MCA ; Mark as an MCA-compatible machine
	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_I92 ; Save routine addr

	 test	 NRD_FLAG,@NRD_A20FN ; A20 services present?
	 jnz	 short @F	; Jump if so

	 mov	 A20SUP,mask $A20_I92 ; Mark as A20 support value
@@:

; Read in the adapter IDs

	 push	 seg XGROUP	; Setup ES for STOSW
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 mov	 cx,8		; Loop counter
	 mov	 bl,1		; Start with slot #1 (origin-1)
	 lea	 di,MCAID	; ES:DI ==> adapter ID save area
CHECK_MODEL_MCA_NEXT:
	 call	 GET_POSID	; Return with AX = POS ID for slot BL (origin-1)
S16	 stos	 MCAID		; Save in MCAID

	 inc	 bl		; Skip to next slot #

	 loop	 CHECK_MODEL_MCA_NEXT ; Jump if more adapters to check

; Get the system board ID and store it in MCAID[8]

	 sub	 bl,bl		; Pseudo-slot # for system board
	 call	 GET_POSID	; Return with AX = POS ID for system board
S16	 stos	 MCAID		; Save in MCAID

CHECK_MODEL_BIOS128:
	 mov	 REP_FAC,1	; Use repeat factor of 1 for I/O ports
	 mov	 IO_LIM_MASK,-1 ; All I/O bits are significant
	 mov	 SYSROM_START,0E000h ; Mark as starting segment of system ROM
if @OEM_BCF
	 mov	 UCSYSROM_START,0E0000h ; Starting address of uncompressed ROM
endif				; IF @OEM_BCF

	 jmp	 CHECK_MODEL_EXIT ; Join common exit code

	 assume  es:nothing	; Tell the assembler about it

CHECK_MODEL_XMCA:
; Check for PCI local bus BIOS.
	 CPD	 'Calling PCI local bus check'

	 call	 CHECK_AMI	; See if this is an AMI BIOS with the bug which
				; prevents us from making the PCICALL below
				; Return with DI = offset of match in ROM
	 jc	 short CHECK_MODEL_XAMI ; Jump if not AMI BIOS

	 push	 seg CGROUP	; Get ROM BIOS segment
	 pop	 es		; Address via segment register
	 assume  es:CGROUP	; Tell the assembler about it

	 add	 di,AMIBIOS_LEN ; Skip over the string

; This bug should be fixed in the BIOS with a code base date of 04/15/1994.
; Note that the code base date is from the original BIOS vendor (AMI)
; which has been modified by Intel.  Apparently, Intel doesn't get the
; code from AMI in a timely manner or they're slow to integrate it into
; their own versions.

	 cmp	 es:[di].AMIDATE_SEP1,'/' ; Izit valid?
	 jne	 short CHECK_MODEL_XAMI ; Jump if not

	 cmp	 es:[di].AMIDATE_SEP2,'/' ; Izit valid?
	 jne	 short CHECK_MODEL_XAMI ; Jump if not

	 cmp	 es:[di].AMIDATE_CCYY,'4991' ; Izit later than 1994?
	 ja	 short CHECK_MODEL_XAMI ; Jump if later (assume fixed)
	 jb	 short CHECK_MODEL_AMI ; Jump if earlier (assume buggy)
				       ; Fall through if same
	 cmp	 es:[di].AMIDATE_MM,'40' ; Izit later than 04?
	 ja	 short CHECK_MODEL_XAMI ; Jump if later (assume fixed)
	 jb	 short CHECK_MODEL_AMI ; Jump if earlier (assume buggy)
				       ; Fall through if same
	 cmp	 es:[di].AMIDATE_DD,'51' ; Izit later than 15?
	 jae	 short CHECK_MODEL_XAMI ; Jump if same or later (assume fixed)
;;;;;;;; jb	 short CHECK_MODEL_AMI ; Jump if earlier (assume buggy)

	 assume  es:nothing	; Tell the assembler about it

; Search for the MOVPCI string in F000:0 to FFFF

CHECK_MODEL_AMI:
	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset XGROUP:MOVPCI ; Get offset of source string
	 push	 MOVPCI_LEN	; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jnc	 short CHECK_MODEL_PCI ; Jump if found
				; Return with DI = offset of match in ROM
	 jmp	 short CHECK_MODEL_XPCI ; Join common code

CHECK_MODEL_XAMI:
	 stc			; Assume failure
	 PCICALL @PCI_INST	; Return CF=0 and AH=0 if PCI BIOS present
	 jc	 short CHECK_MODEL_XPCI ; Jump if not present

	 or	 ah,ah		; Did we succeed?
	 jnz	 short CHECK_MODEL_XPCI ; Jump if not
CHECK_MODEL_PCI:
	 or	 SYS_FLAG,@SYS_PCIBIOS ; PCI BIOS detected
CHECK_MODEL_DMA32:
	 CPD	 '32-bit DMA supported'

	 mov	 REP_FAC,1	; Use repeat factor of 1 for I/O ports
	 mov	 IO_LIM_MASK,-1 ; All I/O bits are significant

if @OEM_DMA
	 or	 CM2_FLAG,@CM2_EISA_DMA ; Mark as present (EISA style DMA)
	 mov	 DMA_MAX_LEN,@DMA_MAX_EISALEN ; Maximum size of DMA buffer
endif				; IF @OEM_DMA

	 jmp	 CHECK_MODEL_EXIT ; Join common code

CHECK_MODEL_XPCI:
	 mov	 al,MACHID	; Restore machine ID

	 cmp	 al,@CPU_MCA	; Check for other MCA (128KB BIOS?)
	 je	 near ptr CHECK_MODEL_BIOS128 ; Jump if present

	 cmp	 al,@CPU_AT	; Izit a 286 processor?
	 je	 short CHECK_MODEL_AT ; Jump if so

	 cmp	 al,@CPU_PC	; Check for PC
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 cmp	 al,@CPU_XT	; Check for XT
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 cmp	 al,@CPU_XT2	; Check for XT2
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 cmp	 al,@CPU_M30	; Check for PS/2 Model 30
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 cmp	 al,@CPU_CNV	; Check for Convertible
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 cmp	 al,@CPU_JR	; Check for Jr
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 jmp	 short CHECK_MODEL_EXIT ; Join common code


; The processor is a 286:  see if it has a 128KB BIOS

CHECK_MODEL_AT:
	 cmp	 BIOSCONF_VEC.VSEG,0 ; Izit valid?
	 je	 short CHECK_MODEL_EXIT ; Jump if not

	 les	 bx,BIOSCONF_VEC ; ES:BX ==> BIOS configuration data
	 assume  es:nothing	; Tell the assembler about it

	 mov	 al,es:[bx].CFG_TYPE ; Get type byte

	 cmp	 al,09h 	; Izit a PS/2 model 30/286?
	 je	 short @F	; Jump if so

	 cmp	 al,19h 	; Izit a PS/2 model 40SLC?
	 je	 short @F	; Jump if so

	 cmp	 al,24h 	; Izit a PS/2 model 40SX?
	 jne	 short CHECK_MODEL_EXIT ; Jump if not

@@:
	 jmp	 CHECK_MODEL_BIOS128 ; Assume 128K BIOS

CHECK_MODEL_PCXT:
	 call	 MARK_XT	; Mark as PC/XT present
CHECK_MODEL_EXIT:
	 REGREST <fs,es,di,dx,cx,bx,ax> ; Restore
	 assume  es:CGROUP,fs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_MODEL endp		; End CHECK_MODEL procedure
	 NPPROC  CHECK_AMI -- Check On Certain AMI BIOSes
	 assume  ds:PGROUP,es:nothing,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on certain AMI BIOSes which have a bug which prevents us
from calling PCICALL.

On exit:

CF	 =	 0 if found
	 =	 1 if not
DI	 =	 offset in ROM of string match

|

; Search for the AMIBIOS string in F000:0

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 1000h		; Length of search area (4KB)
	 push	 offset XGROUP:AMIBIOS ; Get offset of source string
	 push	 AMIBIOS_LEN	; Get length of ...
	 call	 SRCHSTR	; Search for the string
				; Return with DI = offset of match in ROM
				; Return with CF=0 if found, CF=1 if not
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_AMI endp			; End CHECK_AMI procedure
	 NPPROC  CHECK_I92 -- Check For I/O Port 92h A20 Gating
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for I/O port 92h A20 gating

|

	 REGSAVE <ax,cx,si,di,ds,es> ; Save registers

; See if this system supports I/O port 92h to gate A20

COMMENT|

Alas, from the no-good-deed-goes-unpunished file, it turns out that on
some systems the very act of writing to I/O port 92h (the actual value
doesn't matter) gates A20 on, but then that's all she wrote.  No
further writes to 92h or to the 8042 for that matter have any effect.

As this causes us some problems, we need to recognize this situation
and avoid it.  On the system I encountered with this hardware bug, the
input value of I/O port 92h is 0C0h, so the test used below checks for
the two high-order bits on.  If that's a valid I/O port (at least in
MCA parlance), that would mean that both Fixed Disk lights are on,
which is, I trust, an unlikely event.  This also catches the case
where the I/O port has no effect and a read returns 0FFh.

|

@FD01	 equ	 ((mask $PS2_FD0) or (mask $PS2_FD1)) ; Both fixed disk lights

	 in	 al,@PS2_A	; Get current state
	 and	 al,@FD01	; Isolate Fixed Disk lights

	 cmp	 al,@FD01	; Izit valid?
	 je	 short CHECK_I92_EXIT ; Jump if so

	 mov	 es,MAPSEG_NXT	; Get next available segment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> local buffer

	 mov	 ax,seg HMASEG	; Get segment of HMA
	 mov	 ds,ax		; Address it
	 assume  ds:HMASEG	; Tell the assembler about it

	 lea	 si,HMASTART	; DS:SI ==> start of HMA

	 mov	 cx,100h	; # bytes to copy and compare
	 cld			; String ops forwardly

	 cli			; Disable interrupts in case
				; the contents of the HMA can change
	 REGSAVE <cx,si,di>	; Save for a moment

S16  rep movs	 <es:[di].LO,HMASTART[si]> ; Copy to local buffer

	 REGREST <di,si,cx>	; Restore

; Toggle the I/O port 92h state

	 in	 al,@PS2_A	; Get current state
	 xor	 al,mask $PS2_GATE ; Toggle the state
	 out	 @PS2_A,al	; Write it back out

; Compare the data (we might get fooled by a memory cache)

    repe cmps	 HMASTART[si],es:[di].LO ; Compare with the local buffer
	 pushf			; Save ZF and IF for a moment

; Toggle the I/O port 92h state back

	 in	 al,@PS2_A	; Get current state
	 xor	 al,mask $PS2_GATE ; Toggle the state
	 out	 @PS2_A,al	; Write it back out

	 popf			; Restore ZF and IF
	 sti			; Enable interrupts again
	 je	 short CHECK_I92_EXIT ; Jump if the same (not I/O port 92 system)

	 push	 seg PGROUP	; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_I92 ; Save routine addr
	 mov	 A20SUP,mask $A20_I92 ; Mark as A20 support value
CHECK_I92_EXIT:
	 REGREST <es,ds,di,si,cx,ax> ; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_I92 endp			; End CHECK_I92 procedure
	 FPPROC  CHECK_SYSID -- System- and Model-Dependent Code
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle system- and model-dependent code.

On exit:

CF	 =	 0 if all went well
	 =	 1 if something went wrong

|

	 REGSAVE <ax,es,fs>	; Save registers

	 push	 seg CGROUP	; Get ROM BIOS segment
	 pop	 es		; Address it
	 assume  es:CGROUP	; Tell the assembler about it

	 push	 seg XGROUP	; Get XGROUP segment
	 pop	 fs		; Address it
	 assume  fs:XGROUP	; Tell the assembler about it

	 mov	 al,BIOSCPUID	; Get the machine ID byte
	 mov	 MACHID,al	; Save for later use

	 call	 CHECK_PICBUG	; Check for PIC swap bug
	 call	 CHECK_I78	; Check for I/O port 78h toggle of A20

if @OEM_SYS eq @OEMSYS_SHS

; Check for OMNIVIEW presence

	 call	 CHECK_OMNI	; Return with CF=0 if we found it, =1 otherwise
	 jc	 near ptr CHECK_SYSID_EXIT ; Jump if not found
endif				; IF @OEM_SYS eq @OEMSYS_SHS


if @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT

; Check for AST fASTram board

	 CPD	 'Calling CHECK_FASTRAM'
	 call	 CHECK_FASTRAM	; Either the memory is there and we can use it,
				; or it isn't and we can't -- so there
endif				; IF @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT


if @OEM_SYS eq @OEMSYS_3COM

; Check for 3COM software drivers

	 call	 CHECK_3COM	; Return with CF=0 if we found one, =1 otherwise
	 jc	 near ptr CHECK_SYSID_EXIT ; Jump if not found
endif				; IF @OEM_SYS eq @OEMSYS_3COM


if @OEM_SYS eq @OEMSYS_ILIM

; Check for iNBRDPC or iNBRDAT signature

	 call	 CHECK_INBRD	; Return with CF=0 if we found one, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for iNBRDPC or iNBRDAT signature

	 CPD	 'Calling CHECK_INBRD'
	 call	 CHECK_INBRD	; Return with CF=0 if we found one, =1 otherwise
	 jnc	 near ptr CHECK_SYSID_CLC ; We found one of them, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

	 call	 CHECK_GATEWAY	; Check for Gateway 2000

if @OEM_SYS eq @OEMSYS_CA

; Check for CompuAdd signature

	 call	 CHECK_CA	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for CompuAdd signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 near ptr CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_CA'
	 call	 CHECK_CA	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 near ptr CHECK_SYSID_CLC ; We found it, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SYS eq @OEMSYS_CA


if @OEM_SYS eq @OEMSYS_ASEM

; Check for ASEM signature

	 call	 CHECK_ASEM	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for ASEM signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 near ptr CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_ASEM'
	 call	 CHECK_ASEM	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 near ptr CHECK_SYSID_CLC ; We found it, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SYS eq @OEMSYS_ASEM


if @OEM_SYS eq @OEMSYS_EPSON

; Check for EPSON signature

	 call	 CHECK_EPSON	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for EPSON signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 near ptr CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_EPSON'
	 call	 CHECK_EPSON	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 near ptr CHECK_SYSID_CLC ; We found it, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SYS eq @OEMSYS_EPSON


if @OEM_SYS eq @OEMSYS_TOSH

; Check for Toshiba 5100 signature

	 call	 CHECK_TOSH	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for Toshiba 5100 signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 near ptr CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_TOSH'
	 call	 CHECK_TOSH	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 near ptr CHECK_SYSID_CLC ; We found it, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SYS eq @OEMSYS_TOSH


if @OEM_SYS eq @OEMSYS_QUAD386

; Check for Quadram 386XT signature

	 call	 CHECK_QUAD386	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for Quadram 386XT signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 near ptr CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_QUAD386'
	 call	 CHECK_QUAD386	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 near ptr CHECK_SYSID_CLC ; We found it, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SS eq @OEMSYS_QUAD386


if @OEM_SYS eq @OEMSYS_AST386

; Check for AST Premium 386 signature

	 call	 CHECK_AST386	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for AST Premium 386 signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 near ptr CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_AST386'
	 call	 CHECK_AST386	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 near ptr CHECK_SYSID_CLC ; We found it, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SYS eq @OEMSYS_AST386


if @OEM_SYS eq @OEMSYS_HPRS

; Check for HP signature

	 call	 CHECK_HPRS	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for HP signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 near ptr CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_HPRS'
	 call	 CHECK_HPRS	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 near ptr CHECK_SYSID_CLC ; We found it, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SYS eq @OEMSYS_HPRS


if @OEM_SOFT

; Check for ITT XTRA/Alcatel signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 near ptr CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_ITT'
	 call	 CHECK_ITT	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 near ptr CHECK_SYSID_CLC ; We found it, so just exit
endif				; IF @OEM_SOFT


if @OEM_SYS eq @OEMSYS_GRID

; Check for GRiD signature

	 CPD	 'Calling CHECK_GRID'
	 call	 CHECK_GRID	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for GRiD signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 near ptr CHECK_SYSID_CLC ; Yes, so just exit

	 call	 CHECK_GRID	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 near ptr CHECK_SYSID_CLC ; We found it, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SYS eq @OEMSYS_GRID


if @OEM_SYS eq @OEMSYS_NEC

; Check for NEC Ultra Versa

	 CPD	 'Calling CHECK_NECLAP'
	 call	 CHECK_NECLAP	; Identify E800-F000 is unusable on this machine

; Check for NEC signature

	 CPD	 'Calling CHECK_NEC'

	 call	 CHECK_NEC	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for NEC Ultra Versa

	 CPD	 'Calling CHECK_NECLAP'
	 call	 CHECK_NECLAP	; Identify E800-F000 is unusable on this machine

; Check for NEC signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 near ptr CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_NEC'
	 call	 CHECK_NEC	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYSID_CLC ; We found it, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SYS eq @OEMSYS_NEC


if @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2

; Check for AT&T/Olivetti signature

	 call	 CHECK_OLI	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it

	 jmp	 short CHECK_SYSID_CLC ; Join common exit code
elseif @OEM_SOFT

; Check for AT&T/Olivetti signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 short CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_OLI'
	 call	 CHECK_OLI	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYSID_CLC ; We found it, so just exit
				; IF @OEM_SOFT
endif				; IF @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2


if @OEM_SYS eq @OEMSYS_AM1 or @OEM_SYS eq @OEMSYS_AM2

; Check for AMKLY memory board in an MCA slot

	 call	 CHECK_AM1	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it
endif				; IF @OEM_SYS eq @OEMSYS_AM1 or @OEMSYS eq @OEMSYS_AM2


if @OEM_SYS eq @OEMSYS_AM3

; Check for AMKLY EISA system board

	 call	 CHECK_AM3	; Return with CF=0 if we found it, =1 otherwise
	 jc	 short CHECK_SYSID_EXIT ; Jump if we didn't find it
endif				; IF @OEM_SYS eq @OEMSYS_AM3


if @OEM_SOFT

; Check for Dell Systems signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 short CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_DELL'
	 call	 CHECK_DELL	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYSID_CLC ; We found it, so just exit
endif				; IF @OEM_SOFT


if @OEM_SOFT

; Check for ALR Systems signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 short CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_ALR'
	 call	 CHECK_ALR	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYSID_CLC ; We found it, so just exit
endif				; IF @OEM_SOFT


if @OEM_SOFT

; Check for Zenith Systems signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 short CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_ZDS'
	 call	 CHECK_ZDS	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYSID_CLC ; We found it, so just exit
endif				; IF @OEM_SOFT


if @OEM_SOFT

; Check for AMSTRAD PC

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 short CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_AMSTRAD'
	 call	 CHECK_AMSTRAD	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYSID_CLC ; We found it, so just exit
endif				; IF @OEM_SOFT


if @OEM_SOFT

; Check for COMPAQ Deskpro 386/486 signature

	 cmp	 SYS_FLAG,0	; Any SYSID specified as yet?
	 jne	 short CHECK_SYSID_CLC ; Yes, so just exit

	 CPD	 'Calling CHECK_CPQ386'
	 call	 CHECK_CPQ386	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYSID_CLC ; We found it, so just exit
endif				; IF @OEM_SOFT
CHECK_SYSID_CLC:

	 REGSAVE <eax>		; Save
	 mov	 eax,SYS_FLAG	; Get system flags for debugging display
	 CPD	 'Calling CHECK_UNROM, SYS_FLAG=%eax, CS:IP=%CS:%IP  DS=%DS ES=%ES'
	 REGREST <eax>		; Restore

	 call	 CHECK_UNROM	; Check on unshadowing the video ROM
;;;;;;;; jc	 short ???	; Ignore error return

if @OEM_FLEXROM
	 CPD	 'Calling PROCESS_FLEXFILE,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 PROCESS_FLEXFILE ; Process the video translation file
endif				; IF @OEM_FLEXROM

if @OEM_HIFILL

; See if we should compress the system ROM

	 CPD	 'Calling CHECK_CROM,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 CHECK_CROM	; Check on it
endif				; IF @OEM_HIFILL

	 clc			; Indicate all went well
CHECK_SYSID_EXIT:
	 REGREST <fs,es,ax>	; Restore
	 assume  es:nothing,fs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SYSID endp		; End CHECK_SYSID procedure
	 NPPROC  CHECK_PICBUG -- Check for PIC Swap Bug
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check for PIC swap bug.

In certain Phoenix MCA BIOSs there is a bug which swaps the
meaning of the PIC master and slave vector bases.  This routine
detects those BIOSs and implements a workaround.

|

	 REGSAVE <ax,di>	; Save registers

; Search for the PICDATA string in F000:0 to FFFF

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset XGROUP:PICDATA ; Get offset of source string
	 push	 PICDATA_LEN	; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short CHECK_PICBUG_EXIT ; Jump if not found
				; Return with DI = offset of match in ROM

	 mov	 ax,PICBASE	; Get (Master, Slave) PIC base values
	 xchg	 al,ah		; Swap 'em
	 mov	 PICBASE,ax	; Restore
CHECK_PICBUG_EXIT:
	 REGREST <di,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PICBUG endp		; End CHECK_PICBUG procedure
	 NPPROC  CHECK_I78 -- Check for I/O Port 78h A20 Toggle
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check for I/O port 78h to toggle A20

In certain systems I/O port 78h is used to toggle A20.	This routine
detects those BIOSs and marks it as such.

|

	 push	 di		; Save register

; A newer system from Intel uses I/O port 78h for a
; completely different purpose.  To handle both circumstances,
; we now check the BIOS date for 1989 or earlier.

	 cmp	 BIOS_DATE[6],'8' ; Izit 198x?
	 jne	 short CHECK_I78_EXIT ; Jump if not

; Search for the I78DATA string in F000:0 to FFFF

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset XGROUP:I78DATA ; Get offset of source string
	 push	 I78DATA_LEN	; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short CHECK_I78_EXIT ; Jump if not found
				; Return with DI = offset of match in ROM

	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_I78 ; Save routine addr
CHECK_I78_EXIT:
	 pop	 di		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_I78 endp			; End CHECK_I78 procedure
if @OEM_SYS eq @OEMSYS_SHS
	 NPPROC  CHECK_OMNI -- Check for OMNIVIEW Presence
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check for presence of OMNIVIEW.
For OMNIVIEW to be present, either the file OMNIVIEW.EXE
or MANGFALD.EXE (the Swedish version) must be in the same
directory from which we were loaded, and the first few
bytes of the file (after the .EXE header) must match the
signature in our local variable OMNISIGN.

On exit:

CF	 =	 0 if OMNIVIEW installed
	 =	 1 if not

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save registers

	 push	 seg XGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 push	 OLDINT24_VEC	; Save old INT 24h handler's address
	 call	 INST24 	; Install local INT 24h handler

; Construct the appropriate drive and directory path

	 lds	 si,RH_VEC	; DS:SI ==> request header
	 assume  ds:nothing	; Tell the assembler about it

	 lds	 si,ds:[si].INIT_CMD_VEC ; Get address of command line args
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 cx,DRVPATH_END ; Get offset to end+1 of path
	 sub	 cx,si		; Less start to get length
	 lea	 di,OMNIBUF	; ES:DI ==> local buffer
S16  rep movs	 <OMNIBUF[di],ds:[si].LO> ; Copy it

	 push	 seg XGROUP	; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 lea	 si,OMNIFILE1	; DS:SI ==> OMNIVIEW filename.ext,0
	 mov	 cx,OMNIFILE1_LEN ; Get length of text
	 push	 di		; Save for a moment
S16  rep movs	 <OMNIBUF[di],OMNIFILE1[si]> ; Copy it
	 pop	 di		; Restore

	 call	 CHECK_OMNISUB	; Check on it
	 jnc	 short CHECK_OMNI_EXIT ; Jump if we found it (note CF=0)

	 lea	 si,OMNIFILE2	; DS:SI ==> OMNIVIEW filename.ext,0
	 mov	 cx,OMNIFILE2_LEN ; Get length of text
	 push	 di		; Save for a moment
S16  rep movs	 <OMNIBUF[si],OMNIFILE2[di]> ; Copy it
	 pop	 di		; Restore

	 call	 CHECK_OMNISUB	; Check on it
	 jnc	 short CHECK_OMNI_EXIT ; Jump if we found it (note CF=0)

	 push	 offset YGROUP:MSG_NOOMNI ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message

	 stc			; Indicate not found
CHECK_OMNI_EXIT:
	 call	 REST24 	; Restore INT 24h handler
	 pop	 OLDINT24_VEC	; Restore old INT 24h handler's address

	 REGREST <es,ds>	; Restore segment registers
	 assume  ds:PGROUP,es:CGROUP ; Tell the assembler about it
	 popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_OMNI endp 		; End CHECK_OMNI procedure
endif				; IF @OEM_SYS eq @OEMSYS_SHS
if @OEM_SYS eq @OEMSYS_SHS
	 NPPROC  CHECK_OMNISUB -- Subroutine to CHECK_OMNI
	 assume  ds:XGROUP,es:XGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Open the file in OMNIBUF and check for the OMNIVIEW signature.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

; Attempt to open the file in OMNIBUF

	 mov	 al,0		; Code for read-only access
	 DOSCALL @OPENF2,OMNIBUF ; Request DOS service
	 jc	 short CHECK_OMNISUB_ERR ; Jump if something went wrong

; Read in the file's .EXE header

	 mov	 bx,ax		; Copy to handle register
	 mov	 cx,size EXE_STR ; Get size of .EXE header
	 DOSCALL @READF2,OMNIBUF ; Read it into our buffer
	 jc	 short CHECK_OMNISUB_ERRCLOS ; Jump if something went wrong

; Position file pointer just beyond the file header

	 xor	 cx,cx		; Clear high-order word of CX:DX
	 mov	 dx,OMNIBUF.EXE_HSIZ ; Get size of header in paras
	 shl	 dx,4-0 	; Convert from paras to bytes
	 mov	 al,0		; Code to move from beginning of file
	 DOSCALL @MOVFP2	; Move it
	 jc	 short CHECK_OMNISUB_ERRCLOS ; Jump if something went wrong

; Read the first few bytes of the executable file

	 mov	 cx,OMNISIGN_LEN ; Get length of signature
	 DOSCALL @READF2,OMNIBUF ; Read it into our buffer
	 jc	 short CHECK_OMNISUB_ERRCLOS ; Jump if something went wrong

; Close the file

	 DOSCALL @CLOSF2	; Close the file we opened

; Compare the signatures

	 lea	 si,OMNISIGN	; DS:SI ==> our copy of signature
	 lea	 di,OMNIBUF	; ES:DI ==> file's ...
;;;;;;;; mov	 cx,OMNISIGN_LEN ; Get length of signature
    repe cmps	 OMNISIGN[si],XGROUP:[di].LO ; Compare 'em
	 jne	 short CHECK_OMNISUB_ERR ; Jump if no match

	 clc			; Indicate found

	 jmp	 short CHECK_OMNISUB_EXIT ; Join common exit code

CHECK_OMNISUB_ERRCLOS:
	 DOSCALL @CLOSF2	; Close the file we opened
CHECK_OMNISUB_ERR:
	 stc			; Indicate something went wrong
CHECK_OMNISUB_EXIT:
	 popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_OMNISUB endp		; End CHECK_OMNISUB procedure
endif				; IF @OEM_SYS eq @OEMSYS_SHS
if @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
	 NPPROC  CHECK_FASTRAM -- Check for FASTRAM Board
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check for presence of AST FASTRAM board.

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

	 test	 CM3_FLAG,@CM3_FSTRM ; Izit specified?
	 jz	 short CHECK_FASTRAM_EXIT ; Not this time

; See if it's present by checking for the signature of xB from the info register

	 lea	 si,FASTREGS	; FS:SI ==> fASTram registers
	 mov	 cx,NFASTREGS	; Get # registers
CHECK_FASTRAM_NEXT:
	 lods	 FASTREGS	; Get next base register
	 or	 ax,@AST_INFO	; Shift to Information Register
	 mov	 dx,ax		; Copy to I/O port register
	 call	 READ_ABSENT	; Read from possibly absent I/O port in DX
				; Return with value in AL
	 jnz	 short CHECK_FASTRAM_LOOP ; Jump if port probably absent

	 mov	 bl,al		; Copy to compute memory size
	 and	 bx,@NIB1	; Isolate nibble #1 (memory size)
	 add	 bx,10h 	; Convert nibble #1 to origin-1
	 shl	 bx,(17-4)-10	; Convert from 128KB in nibble #1 to 1KB

	 and	 al,@NIB0	; Isolate nibble #0 (signature)

	 cmp	 al,0Bh 	; Check for signature
	 jne	 short CHECK_FASTRAM_LOOP ; Not this time

; Ensure the starting address is at 2MB

	 mov	 dx,[si-2]	; Get base register
	 or	 dx,@AST_SWR0	; Shift to Switch Register 0
	 call	 READ_ABSENT	; Read from possibly absent I/O port in DX
				; Return with value in AL
	 jnz	 short CHECK_FASTRAM_LOOP ; Jump if port probably absent

	 and	 ax,@NIB1	; Isolate nibble #1 (starting address)
	 shl	 ax,(20-4)-10	; Convert from 1MB in nibble #1 to 1KB

	 cmp	 ax,2048	; Ensure it starts at 2MB
	 jne	 short CHECK_FASTRAM_EXIT ; Not this time

	 and	 bx,bx		; Any memory on the board?
	 jz	 short CHECK_FASTRAM_EXIT ; Jump if nothing there

	 push	 bx		; Amount of shadow RAM in 1KB
	 push	 dword ptr 00260000h ; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 push	 bx		; Amount of shadow RAM in 1KB
	 push	 dword ptr 00260000h ; ...at this location
	 call	 SAVE_SCRUB	; Append to scrub RAM structure

	 jmp	 short CHECK_FASTRAM_EXIT ; Join common exit code

CHECK_FASTRAM_LOOP:
	 loop	 CHECK_FASTRAM_NEXT ; Jump if more info registers to check
CHECK_FASTRAM_EXIT:
	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_FASTRAM endp		; End CHECK_FASTRAM procedure
endif				; IF @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
	 NPPROC  READ_ABSENT -- Read From Possibly Absent I/O Port
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read from a possibly absent I/O port

On entry:

DX	 =	 I/O port #

On exit:

ZF	 =	 0 if I/O port invalid
	 =	 1 if valid and
AL	 =	 value read
AH	 =	 same as AL

|

	 in	 al,dx		; Read from the I/O port
	 jmp	 $+2		; Drain the PIQ
	 jmp	 $+2		; Drain the PIQ

	 mov	 ah,al		; Save the value
	 in	 al,dx		; Read it in again
	 jmp	 $+2		; Drain the PIQ
	 jmp	 $+2		; Drain the PIQ

	 cmp	 al,ah		; Ensure they are the same
	 jne	 short READ_ABSENT_EXIT ; Jump if not (note ZF=0)

	 in	 al,dx		; Read it in again
	 jmp	 $+2		; Drain the PIQ
	 jmp	 $+2		; Drain the PIQ

	 cmp	 al,ah		; Ensure they are the same
READ_ABSENT_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_ABSENT endp		; End READ_ABSENT procedure
endif				; IF @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_3COM
	 NPPROC  CHECK_3COM -- Check for 3COM Presence
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check for presence of 3COM files.

For us to install on 3+ servers, the file in TCOM3PLUS must
be present on the same drive as 3COMEMM.

Fo us to install on 3+Open workstations, the file in TCOM3OPEN must
be present on the same drive as 3COMEMM, and in the directory
immediately above the directory of 3COMEMM.

* Install INT 24h handler
* Attempt to open the files one by one
* Otherwise, display message, set CF and exit (failure)
* Remove INT 24h handler

On exit:

CF	 =	 0 if 3COM files installed
	 =	 1 if not

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save registers

	 push	 seg XGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 push	 OLDINT24_VEC	; Save old INT 24h handler's address
	 call	 INST24 	; Install local INT 24h handler

; Construct the appropriate drive and directory path

	 lds	 si,RH_VEC	; DS:SI ==> request header
	 assume  ds:nothing	; Tell the assembler about it

	 lds	 si,ds:[si].INIT_CMD_VEC ; Get address of command line args
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 cx,DRVPATH_END ; Get offset to end+1 of path
	 sub	 cx,si		; Less start to get length
	 lea	 di,TCOMBUF	; ES:DI ==> local buffer
S16  rep movs	 <TCOMBUF[di],ds:[si].LO> ; Copy it

	 push	 seg XGROUP	; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

; First check for a 3+Open file

	 lea	 si,TCOM3OPEN	; DS:SI ==> 3COM filename.ext,0
	 mov	 cx,TCOM3OPEN_LEN ; Get length of text
S16  rep movs	 <TCOMBUF[di],TCOM3OPEN[si]> ; Copy it

	 lea	 dx,TCOMBUF	; DS:DX ==> local buffer
	 call	 CHECK_3COMSUB	; Check on it
	 jnc	 short CHECK_3COM_EXIT ; Jump if we found it (note CF=0)

; Now check for a 3+ file.

	 lea	 dx,TCOM3PLUS[2] ; DS:DX ==> file to open if no drive

	 cmp	 TCOMBUF[1],':' ; Was a drive letter specified?
	 jne	 short @F	; Jump if not

	 mov	 al,TCOMBUF	; Get the drive letter
	 mov	 TCOM3PLUS[0],al ; Save in string
	 lea	 dx,TCOM3PLUS[0] ; DS:DX ==> file to open if drive used
@@:
	 call	 CHECK_3COMSUB	; Check on it
	 jnc	 short CHECK_3COM_EXIT ; Jump if we found it (note CF=0)

	 push	 offset YGROUP:MSG_NO3COM ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message

	 stc			; Indicate not found
CHECK_3COM_EXIT:
	 call	 REST24 	; Restore INT 24h handler
	 pop	 OLDINT24_VEC	; Restore old INT 24h handler's address

	 REGREST <es,ds>	; Restore segment registers
	 assume  ds:PGROUP,es:CGROUP ; Tell the assembler about it
	 popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_3COM endp 		; End CHECK_3COM procedure
endif				; IF @OEM_SYS eq @OEMSYS_3COM
if @OEM_SYS eq @OEMSYS_3COM
	 NPPROC  CHECK_3COMSUB -- Subroutine to CHECK_3COM
	 assume  ds:XGROUP,es:XGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Open a file.

On entry:

DX:DX	 ==>	 ASCIIZ string of file to open.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx>	; Save registers

; Attempt to open the file in DS:DX

	 mov	 al,0		; Code for read-only access
	 stc			; Assume error
	 DOSCALL @OPENF2	; Request DOS service
	 jc	 short CHECK_3COMSUB_EXIT ; Jump if error (note CF=1)

; Close the file

	 mov	 bx,ax		; Copy to handle register
	 DOSCALL @CLOSF2	; Close the file we opened

	 clc			; Indicate found
CHECK_3COMSUB_EXIT:
	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_3COMSUB endp		; End CHECK_3COMSUB procedure
endif				; IF @OEM_SYS eq @OEMSYS_SHS
if @OEM_SYS eq @OEMSYS_ILIM or @OEM_SOFT
	 NPPROC  CHECK_INBRD -- Check For iNBRDPC/AT Presence
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check for presence of iNBRDPC or iNBRDAT character device drivers w/IOCTL,
or MCA-compatible machine add-in board signature.

* Install INT 24h handler
* Attempt to open iNBRDPC -- if OK, ensure device
* Otherwise, attempt to open iNBRDAT -- if OK, ensure device
* Otherwise, display message, set CF and exit (failure)
* Remove INT 24h handler

On exit:

CF	 =	 1 if neither was found
	 =	 0 if one was found

|

	 pusha			; Save all GP registers

if @OEM_SYS eq @OEMSYS_ILIM

; See if we're on an MCA-compatible machine with an Intel memory board
; If so, we should find an adapter ID of 7788 or 70B0 through 70B5.

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jz	 short CHECK_INBRD_XMCA ; Not this time

	 and	 DBG_FLAG,not @DBG_CR3 ; Mark as not needing CR3 fixup

	 lea	 si,MCAID	; FS:SI ==> adapter IDs
	 mov	 cx,8		; Loop counter
CHECK_INBRD_MCA_NEXT:
	 lods	 MCAID		; Get the next ID

	 cmp	 ax,7788H	; Check the odd one
	 je	 short CHECK_INBRD_OK ; It's an Intel memory adapter

	 cmp	 ax,70B0h	; Check lower end
	 jb	 short CHECK_INBRD_MCA_LOOP ; It's too small

	 cmp	 ax,70B5h	; Check upper end
	 jbe	 short CHECK_INBRD_OK ; It's an Intel memory adapter
CHECK_INBRD_MCA_LOOP:
	 loop	 CHECK_INBRD_MCA_NEXT ; Jump if more channels to check

	 push	 offset YGROUP:MSG_NOINBRDPS ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short CHECK_INBRD_ERRCOM ; Join common error exit code

CHECK_INBRD_XMCA:
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

	 lea	 dx,FNAM_INBRDPC ; DS:DX ==> device name
	 call	 CHECK_DEVICE	; Check on that device driver
	 jc	 short CHECK_INBRD_AT ; No luck, try for AT driver

	 or	 SYS_FLAG,@SYS_INBRDPC ; Mark as Inboard/PC
	 mov	 SWPSIZE,0	; Mark as not swapping memory
	 call	 MARK_XT	; Mark as PC/XT present
CHECK_INBRD_OK:
	 clc			; Indicate we found a match

	 jmp	 short CHECK_INBRD_EXIT ; Yes, exit with CF=0

CHECK_INBRD_AT:
	 lea	 dx,FNAM_INBRDAT ; DS:DX ==> device name
	 call	 CHECK_DEVICE	; Check on that device driver
	 jc	 short CHECK_INBRD_ERR ; No luck, so that's an error

	 or	 SYS_FLAG,@SYS_INBRDAT ; Mark as Inboard/AT

	 clc			; Indicate we found a match

	 jmp	 short CHECK_INBRD_EXIT ; Yes, exit with CF=0

CHECK_INBRD_ERR:
	 cmp	 MACHID,@CPU_AT ; Izit an AT?
	 je	 short CHECK_INBRD_ERR1 ; Yes, use AT-specific message

if @OEM_SYS eq @OEMSYS_ILIM
	 push	 offset YGROUP:MSG_NOINBRDPC ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

	 test	 SYS_FLAG,@SYS_INBRD ; Inboard specified?
	 jz	 short CHECK_INBRD_ERRCOM ; No

	 or	 SYS_FLAG,@SYS_INBRDPC ; Mark as Inboard/PC
	 mov	 SWPSIZE,0	; Mark as not swapping memory
	 call	 MARK_XT	; Mark as PC/XT present

	 jmp	 short CHECK_INBRD_ERRCOM ; Join common error exit code

CHECK_INBRD_ERR1:
if @OEM_SYS eq @OEMSYS_ILIM
	 push	 offset YGROUP:MSG_NOINBRDAT ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

	 test	 SYS_FLAG,@SYS_INBRD ; Inboard specified?
	 jz	 short CHECK_INBRD_ERRCOM ; No

	 or	 SYS_FLAG,@SYS_INBRDAT ; Mark as Inboard/AT
CHECK_INBRD_ERRCOM:
	 stc			; Indicate something went wrong
CHECK_INBRD_EXIT:
	 popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_INBRD endp		; End CHECK_INBRD procedure
endif				; IF @OEM_SYS eq @OEMSYS_ILIM or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_CA or @OEM_SOFT
	 NPPROC  CHECK_CA -- Check for CompuAdd Signature
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of CompuAdd signature.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pushad 		; Save all EGP registers

	 lea	 si,LCL_CASIGN	; FS:SI ==> CompuAdd signature
	 lea	 di,CASIGN	; ES:DI ==> same if CompuAdd machine
	 mov	 cx,LCL_CASIGN_LEN ; CX = length of ...
    repe cmps	 LCL_CASIGN[si],CGROUP:[di].LO ; Compare 'em
	 jne	 near ptr CHECK_CA_XPRES ; Jump if no match

	 test	 CM2_FLAG,@CM2_X384 ; Is NOXRAM specified?
	 jnz	 short CHECK_CA_CLC ; Yes, don't use it

if @OEM_SYS eq @OEMSYS_CA
	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM
	 call	 SET_NOSCAN	; Set all bits in NOSCAN if C&T SHADOWRAM

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it
endif				; IF @OEM_SYS eq @OEMSYS_CA

; Some CompuAdd systems contain a C&T 82C307 ChipSet, so we check for
; that next

	 test	 CM2_FLAG,@CM2_SHD ; Izit C&T shadow RAM?
	 jnz	 short CHECK_CA_CLC ; Yes, RAM recovery complete

; At CompuAdd's request, we are shipping a version which attempts
; to recover the additional 384KB of memory unless the user has
; specified NOXRAM.  Our retail version is more conservative.

if @OEM_SYS ne @OEMSYS_CA

; If SHADOWRAM specified, attempt to recover it

	 test	 CM3_FLAG,@CM3_SHDCA ; Izit specified?
	 jz	 short CHECK_CA_CLC ; Jump if no memory to reclaim
endif				; IF @OEM_SYS ne @OEMSYS_CA

; Read option port to see what additional memory can be recovered

	 in	 al,30h 	; Read option values
	 and	 al,@BIT1 or @BIT0 ; Isolate bits
	 movzx	 eax,al 	; Clear high-order bytes

	 push	 CA_SIZE1[eax*2] ; Amount of shadow RAM in 1KB
	 push	 CA_ADDR1[eax*4] ; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 push	 CA_SIZE1[eax*2] ; Amount of shadow RAM in 1KB
	 push	 CA_ADDR1[eax*4] ; ...at this location
	 call	 SAVE_SCRUB	; Append to scrub RAM structure

	 push	 CA_SIZE2[eax*2] ; Amount of shadow RAM in 1KB
	 push	 CA_ADDR2[eax*4] ; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 push	 CA_SIZE2[eax*2] ; Amount of shadow RAM in 1KB
	 push	 CA_ADDR2[eax*4] ; ...at this location
	 call	 SAVE_SCRUB	; Append to scrub RAM structure
CHECK_CA_CLC:
	 or	 SYS_FLAG,@SYS_CA; Mark as CompuAdd machine
if @OEM_SYS eq @OEMSYS_CA
	 test	 CM2_FLAG,@CM2_SHD ; Izit C&T shadow RAM?
	 jnz	 short @F	   ; Yes, Skip over setting NOROM

	 or	 CMD_FLAG,@CMD_XRM ; Mark as NOROM
@@:
endif				; IF @OEM_SYS eq @OEMSYS_CA

	 clc			; Indicate we found it

	 jmp	 short CHECK_CA_EXIT ; Join common exit code

CHECK_CA_XPRES:

if @OEM_SYS eq @OEMSYS_CA
	 push	 offset YGROUP:MSG_XCA ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_CA

	 stc			; Indicate not CompuAdd machine
CHECK_CA_EXIT:
	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CA endp			; End CHECK_CA procedure
endif				; IF @OEM_SYS eq @OEMSYS_CA or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_ASEM or @OEM_SOFT
	 NPPROC  CHECK_ASEM -- Check for ASEM Signature
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of ASEM signature.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 push	 di		; Save register

; Search for the ASEM string in F000:8000 to FFFF

	 push	 dword ptr 0F0008000h ; Get starting offset of BIOS at 8000h
	 push	 8000h		; Length of search area (32KB)
	 push	 offset XGROUP:LCL_ASEMSIGN ; Get offset of source string
	 push	 LCL_ASEMSIGN_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short CHECK_ASEM_XPRES ; Jump if not found
				; Return with DI = offset of match in ROM

	 or	 SYS_FLAG,@SYS_ASEM ; Mark as ASEM machine

	 clc			; Indicate we found it

	 jmp	 short CHECK_ASEM_EXIT ; Join common exit code

CHECK_ASEM_XPRES:

if @OEM_SYS eq @OEMSYS_ASEM
	 push	 offset YGROUP:MSG_XASEM ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_ASEM

	 stc			; Indicate not ASEM machine
CHECK_ASEM_EXIT:
	 pop	 di		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ASEM endp 		; End CHECK_ASEM procedure
endif				; IF @OEM_SYS eq @OEMSYS_ASEM or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_EPSON or @OEM_SOFT
	 NPPROC  CHECK_EPSON -- Check for EPSON Signature
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of EPSON signature.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <ax,bx,cx,di>	; Save registers

; Search for the EPSON string in F000:0 to FFFF

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset XGROUP:LCL_EPSONSIGN ; Get offset of source string
	 push	 LCL_EPSONSIGN_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 near ptr CHECK_EPSON_XPRES ; Jump if not found
				; Return with DI = offset of match in ROM

	 or	 SYS_FLAG,@SYS_EPSON ; Mark as EPSON machine

COMMENT|

EPSON machine-specific code

The different machines are recognized as follows:

Machine Name	 BIOSCPUID	  EPSALTID	Memory Properties
-----------------------------------------------------------------
Cheetah 	 @CPU_AT	  08		SHADOWRAM (82C302)
Panther 	 @CPU_AT	  30		None (384KB contiguous at 1MB)
Tiger		 @CPU_AT	  31		TOP384
Trout		 @CPU_AT	  33		None (384KB contiguous at 1MB)

|

; All supported systems have @CPU_AT in BIOSCPUID

	 cmp	 BIOSCPUID,@CPU_AT ; Izit a supported system?
	 jne	 near ptr CHECK_EPSON_CLC ; Jump if not

	 cmp	 EPSALTID,08h	; Izit a Cheetah system?
	 je	 near ptr CHECK_EPSON_SHD ; Jump if so

	 cmp	 EPSALTID,30h	; Izit a 386SX system?
	 je	 near ptr CHECK_EPSON_CLC ; Jump if so

	 cmp	 EPSALTID,31h	; Izit a Tiger system?
	 je	 short CHECK_EPSON_TIGER ; Jump if so

	 cmp	 EPSALTID,33h	; Izit a Trout system? (386SX+)
	 je	 short CHECK_EPSON_CLC ; Jump if so

	 jmp	 short CHECK_EPSON_CLC ; Join common code

CHECK_EPSON_TIGER:

; Check to see if we should recover XRAM

	 test	 CM2_FLAG,@CM2_X384 ; Is NOXRAM specified?
	 jnz	 short CHECK_EPSON_CLC ; Yes, skip to exit

	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Recover at least 256K in all cases

	 push	 256		; Amount of shadow RAM in 1KB
	 push	 dword ptr 00FA0000h ; ...at this location (15M + 640K)
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

; Read CR1 before modifying some of its bits

	 mov	 al,@EPS_CR1	; Index pointer registers
	 call	 GET_EPS	; Read into AL from Epson control register AL

; Flip all bits in AL and place in BL

	 mov	 cx,8		; Set the count for 8 bits
@@:	 shl	 al,1		; Place AL's high order bit into CF
	 rcr	 bl,1		; The place it into BL's low order bit
	 loop	 @B		; Do next bit if still more

; Can we use the E000 segment?

	 test	 NRD_FLAG,@NRD_UE000 ; Is E000 available?
	 jz	 short CHECK_EPSON1 ; Jump if not

; If able, recover the E000 segment

	 push	 64		; Amount of shadow RAM in 1KB
	 push	 dword ptr 00FE0000h ; ...at this location (15M + 896K)
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 and	 bl,not (mask $EPSCR1_E000)  ; Clear the relevant bits
	 or	 bl,@EPSCR1_RW shl $EPSCR1_E000 ; Mark as read-write

; Now, mark the MEM_MAP as available in E000

	 mov	 cx,64 shl (10-9) ; Express 64KB in 512-bytes
	 mov	 di,0E000h shr (9-4) ; Convert from paras to 512-bytes
	 mov	 al,@XLAT_OVR	; Mark as high DOS memory (for EMS page frame
				; even if NOHIGH is specified)
	 call	 ROM2OVR	; Mark as type AL memory in MEM_MAP
				; offset DI for CX entries
CHECK_EPSON1:

; Tell the hardware that we want exclusive use of 00FE0000

; Write CR1 (and any changes) back to the hardware register

	 mov	 al,@EPS_CR1	; Index pointer registers
	 call	 SET_EPS	; Write BL to Epson control register AL

; Enable caching of top MB

; Read CR3 before modifying some of its bits

	 mov	 al,@EPS_CR3	; Index pointer registers
	 call	 GET_EPS	; Read into AL from Epson control register AL

	 and	 al,not (mask $EPSCR3_F) ; Enable caching of 00F00000-00FFFFFF
	 mov	 bl,al		; Copy to SET_EPS input register
	 mov	 al,@EPS_CR3	; Index pointer registers
	 call	 SET_EPS	; Write BL to Epson control register AL

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it

	 jmp	 short CHECK_EPSON_CLC ; Join common code

CHECK_EPSON_SHD:
	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM
	 call	 SET_NOSCAN	; Set all bits in NOSCAN if C&T SHADOWRAM

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it
CHECK_EPSON_CLC:
	 clc			; Indicate we found it

	 jmp	 short CHECK_EPSON_EXIT ; Join common exit code

CHECK_EPSON_XPRES:

if @OEM_SYS eq @OEMSYS_EPSON
	 push	 offset YGROUP:MSG_XEPSON ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_EPSON

	 stc			; Indicate not EPSON machine
CHECK_EPSON_EXIT:
	 REGREST <di,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EPSON endp		; End CHECK_EPSON procedure
endif				; IF @OEM_SYS eq @OEMSYS_EPSON or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_EPSON or @OEM_SOFT
	 NPPROC  GET_EPS -- Read from Epson Control Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read from Epson control register AL into AL.

On entry:

AL	 =	 control register # (1 = CR0, 2 = CR1, 3 = CR2, 4 = CR3)

On exit:

AL	 =	 value read

|

	 REGSAVE <dx>		; Save registers

	 cli			; Disable interrupts

	 mov	dx,@EPS_CMD	; The address of the command port
	 out	dx, al		; Tell the hardware which register we need
	 jmp	short $+2	; Flush the PIQ

	 mov	dx,@EPS_DAT	; The data port where the info is
	 in	al,dx		; Read the information from the hardware

	 sti			; All done, enable interrupts again

	 REGREST <dx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_EPS  endp			; End GET_EPS procedure
endif				; IF @OEM_SYS eq @OEMSYS_EPSON or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_EPSON or @OEM_SOFT
	 NPPROC  SET_EPS -- Write to Epson Control Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Write BL to Epson control register AL.

On entry:

AL	 =	 control register # (1 = CR0, 2 = CR1, 3 = CR2, 4 = CR3)
BL	 =	 value to write

On exit:

|

	 REGSAVE <ax,dx>	; Save registers

	 cli			; Disable interrupts

	 mov	dx,@EPS_CMD	; The address of the command port
	 out	dx, al		; Tell the hardware which register we need
	 jmp	short $+2	; Flush the PIQ

	 mov	dx,@EPS_DAT	; The data port where the info is
	 mov	al, bl		; The bits that were flipped (above)
	 out	dx, al		; Get the information to the hardware

	 sti			; All done, enable interrupts again

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_EPS  endp			; End SET_EPS procedure
endif				; IF @OEM_SYS eq @OEMSYS_EPSON or @OEM_SOFT
	 NPPROC  CHECK_GATEWAY -- Check for Gateway Signature
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check for machines with Gateway 2000 motherboards (some Gateway
machines use Intel motherboards; we don't care about them).

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 push	 di		; Save register

; Search for the Gateway 2000 string in F000:8000 to FFFF

	 push	 dword ptr 0F0008000h ; Get starting offset of BIOS at 8000h
	 push	 8000h		; Length of search area (32KB)
	 push	 offset XGROUP:LCL_GATEWAYSIGN ; Get offset of source string
	 push	 LCL_GATEWAYSIGN_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short CHECK_GATEWAY_XPRES ; Jump if not found
				; Return with DI = offset of match in ROM

	 and	 CPUFET_FLAG,not @CPUFET_INVD ; Don't use INVD/WBINVD

	 clc			; Indicate we found it

	 jmp	 short CHECK_GATEWAY_EXIT ; Join common exit code

CHECK_GATEWAY_XPRES:

	 stc			; Indicate not Gateway machine
CHECK_GATEWAY_EXIT:
	 pop	 di		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_GATEWAY endp		; End CHECK_GATEWAY procedure
if @OEM_SYS eq @OEMSYS_TOSH or @OEM_SOFT
	 NPPROC  CHECK_TOSH -- Check for Toshiba 5100 Signature
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of Toshiba 5100 signature.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pusha			; Save all GP registers

	 lea	 si,LCL_TOSHSIGN ; FS:SI ==> Toshiba 5100 signature
	 lea	 di,TOSHSIGN	; ES:DI ==> same if Toshiba 5100 machine
	 mov	 cx,LCL_TOSHSIGN_LEN ; CX = length of ...
    repe cmps	 LCL_TOSHSIGN[si],CGROUP:[di].LO ; Compare 'em
	 jne	 short CHECK_TOSH_XPRES ; Jump if no match

	 or	 SYS_FLAG,@SYS_TOSH; Mark as Toshiba 5100 machine
	 or	 CM3_FLAG,@CM3_XPULS ; Mark as not pulsing the 8042

	 clc			; Indicate we found it

	 jmp	 short CHECK_TOSH_EXIT ; Join common exit code

CHECK_TOSH_XPRES:

if @OEM_SYS eq @OEMSYS_TOSH
	 push	 offset YGROUP:MSG_XTOSH ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_TOSH

	 stc			; Indicate not Toshiba 5100 machine
CHECK_TOSH_EXIT:
	 popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_TOSH endp 		; End CHECK_TOSH procedure
endif				; IF @OEM_SYS eq @OEMSYS_TOSH or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_QUAD386 or @OEM_SOFT
	 NPPROC  CHECK_QUAD386 -- Check for Quadram 386XT Signature
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of Quadram 386XT signature.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

@CFG_QUADXT equ 0A6h		; Config type for Quadram 386XT

	 pusha			; Save all GP registers
	 REGSAVE <es>		; Save segment register

	 mov	 ah,0C0h	; Code to get BIOS configuration data
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_QUAD386_XPRES ; Not Quadram 386XT machine

	 cmp	 ah,0		; Ensure AH=00 on return
	 jne	 short CHECK_QUAD386_XPRES ; Not Quadram 386XT machine

	 cmp	 es:[bx].CFG_LEN,26 ; Ensure minimum length
	 jb	 short CHECK_QUAD386_XPRES ; Not Quadram 386XT machine

	 cmp	 es:[bx].CFG_MODEL,@CPU_XT ; Ensure correct model byte
	 jne	 short CHECK_QUAD386_XPRES ; Not Quadram 386XT machine

	 cmp	 es:[bx].CFG_TYPE,@CFG_QUADXT ; Ensure correct type byte
	 jne	 short CHECK_QUAD386_XPRES ; Not Quadram 386XT machine

	 lea	 si,LCL_QUADSIGN ; FS:SI ==> Quadram 386XT signature
	 lea	 di,[bx+10]	; ES:DI ==> same if Quadram 386XT machine
	 mov	 cx,LCL_QUADSIGN_LEN ; CX = length of ...
    repe cmps	 LCL_QUADSIGN[si],es:[di].LO ; Compare 'em
	 jne	 short CHECK_QUAD386_XPRES ; Jump if not found

	 or	 SYS_FLAG,@SYS_QUAD386 ; Mark as Quadram 386XT machine
	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_QUD ; Save routine addr
	 call	 MARK_XT	; Mark as PC/XT present

	 clc			; Indicate we found it

	 jmp	 short CHECK_QUAD386_EXIT ; Join common exit code

CHECK_QUAD386_XPRES:

if @OEM_SYS eq @OEMSYS_QUAD386
	 push	 offset YGROUP:MSG_XQUAD ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_QUAD386

	 stc			; Indicate not Quadram 386XT machine
CHECK_QUAD386_EXIT:
	 REGREST <es>		; Restore
	 assume  es:CGROUP	; Tell the assembler about it
	 popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_QUAD386 endp		; End CHECK_QUAD386 procedure
endif				; IF @OEM_SYS eq @OEMSYS_QUAD386 or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
	 NPPROC  CHECK_AST386 -- Check for AST Premium/386
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of AST Premium/386
or MCA-compatible machine add-in board signature.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pusha			; Save all GP registers

	 REGSAVE <es>		; Save for a moment

if @OEM_SYS eq @OEMSYS_AST386

; See if we're on an MCA-compatible machine with an AST memory board
; If so, we should find an adapter ID of 7081 through 7083.

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jz	 short CHECK_AST_XMCA ; Not this time

	 lea	 si,MCAID	; FS:SI ==> adapter IDs
	 mov	 cx,8		; Loop counter
CHECK_AST_MCA_NEXT:
	 lods	 MCAID		; Get the next ID

	 cmp	 ax,7081h	; Check lower end
	 jb	 short CHECK_AST_MCA_NEXT1 ; It's too small

	 cmp	 ax,7083h	; Check upper end
	 jbe	 short CHECK_AST_MCA_OK ; It's an AST memory adapter
CHECK_AST_MCA_NEXT1:
	 cmp	 ax,7003h	; Check lower end
	 jb	 short CHECK_AST_MCA_LOOP ; It's too small

	 cmp	 ax,7005h	; Check upper end
	 jbe	 short CHECK_AST_MCA_OK ; It's an AST memory adapter
CHECK_AST_MCA_LOOP:
	 loop	 CHECK_AST_MCA_NEXT ; Jump if more channels to check
CHECK_AST_XMCA:
endif				; IF @OEM_SYS eq @OEMSYS_AST386
	 mov	 ah,0C0h	; Code to get BIOS configuration data
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_AST386_XPRES ; Not AST 386 machine

	 cmp	 ah,0		; Ensure AH=00 on return
	 jne	 short CHECK_AST386_XPRES ; Not AST 386 machine

AST_STR  struc

AST_ID	 db	 ?		; Machine ID
AST_COPR db	 22 dup (?)	; Copyright message

AST_STR  ends

; Equates for AST_ID

@AST_PREM20  equ 01h		; Premium /20
@AST_CUPID25 equ 08h		;	  /25
@AST_WALLST  equ 09h		;	   SX
@AST_PREM16  equ 0Bh		;	  /16
@AST_CUPID33 equ 0Dh		;	  /33

	 lea	 si,LCL_ASTSIGN ; FS:SI ==> AST copyright notice
	 add	 bx,es:[bx]	; Get length of configuration data
	 add	 bx,2		; Skip over word length
	 lea	 di,[bx].AST_COPR ; ES:DI ==> same if AST machine
	 mov	 cx,LCL_ASTSIGN_LEN ; CX = length of ...
    repe cmps	 LCL_ASTSIGN[si],es:[di].LO ; Compare 'em
	 jne	 short CHECK_AST386_XPRES ; Jump if not found

	 or	 SYS_FLAG,@SYS_AST386 ; Mark as AST Premium/386
	 or	 I15_FLAG,@I15_AST ; Use AST TOP384 scheme

	 cmp	 es:[bx].AST_ID,@AST_PREM16 ; Izit Premium/16?
	 je	 short CHECK_AST_MEM ; Yes, recover memory

	 cmp	 es:[bx].AST_ID,@AST_PREM20 ; Izit Premium/20?
	 je	 short CHECK_AST_MEM ; Yes, recover memory

;;;;;;;; cmp	 es:[bx].AST_ID,@AST_WALLST ; Izit Premium/SX?
;;;;;;;; je	 short CHECK_AST_X384 ; Yes, no shadow RAM to recover
;;;;;;;;
;;;;;;;; cmp	 es:[bx].AST_ID,@AST_CPUID25 ; Izit Premium/25?
;;;;;;;; je	 short CHECK_AST_X384 ; Yes, no shadow RAM to recover
;;;;;;;;
;;;;;;;; cmp	 es:[bx].AST_ID,@AST_CPUID33 ; Izit Premium/33?
;;;;;;;; je	 short CHECK_AST_X384 ; Yes, no shadow RAM to recover

	 jmp	 short CHECK_AST_X384 ; For all others, no shadow RAM recovery

CHECK_AST_MEM:

; If there is more than 16MB-384KB of RAM installed, force NOXRAM

	 cmp	 PHYSIZE,16*1024-384 ; Check it
	 jbe	 short @F	; Jump if there's no overlap
CHECK_AST_X384:
	 or	 CM2_FLAG,@CM2_X384 ; Skip shadow RAM fill
@@:
CHECK_AST_MCA_OK:
	 clc			; Indicate we found it

	 jmp	 short CHECK_AST386_EXIT ; Join common exit code

CHECK_AST386_XPRES:

if @OEM_SYS eq @OEMSYS_AST386
	 push	 offset YGROUP:MSG_XAST ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_AST386

	 stc			; Indicate not AST machine
CHECK_AST386_EXIT:
	 REGREST <es>		; Restore
	 assume  es:CGROUP	; Tell the assembler about it

	 popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_AST386 endp		; End CHECK_AST386 procedure
endif				; IF @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_HPRS or @OEM_SOFT
	 NPPROC  CHECK_HPRS -- Check for HP Vectra RS/16 or /20
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of HP Vectra RS/16 or /20.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <ax,bx>	; Save registers

	 cmp	 HPSIGN.ELO,'PH' ; Ensure correct signature
	 jne	 near ptr CHECK_HPRS_XPRES ; Jump if not found

	 or	 SYS_FLAG,@SYS_HPRS ; Mark as HP Vectra system
	 mov	 al,HPTYPE	; Get the system type

	 cmp	 al,@HPRS20C	; Izit an RS20C?
	 je	 short @F	; Yes

	 cmp	 al,@HPRS25C	; Izit an RS25C?
	 jne	 short CHECK_HPRS_XCACHE ; No, hence no cache controller
@@:
	 or	 SYS_FLAG,@SYS_HPCACHE ; Mark as having cache controller
CHECK_HPRS_XCACHE:

; Skip shadow RAM fill on HP systems other than
; RS/16, RS/20, QS/16, QS/20, RS/20C, RS/25C, and QS/16S

	 cmp	 al,@HPRS16	; Izit an RS/16?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPRS20	; Izit an RS/20?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPQS16	; Izit an QS/16?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPQS20	; Izit an QS/20?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPRS20C	; Izit an RS/20C?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPRS25C	; Izit an RS/25C?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPQS16S	; Izit an QS/16S?
	 je	 short CHECK_HPRS_FILL ; Yes

	 or	 CM2_FLAG,@CM2_X384 ; Skip shadow RAM fill
CHECK_HPRS_FILL:
	 test	 CM2_FLAG,@CM2_X384 ; Skip shadow RAM fill?
	 jnz	 short CHECK_HPRS1 ; Yes

	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM
	 call	 SET_NOSCAN	; Set all bits in NOSCAN if C&T SHADOWRAM

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
CHECK_HPRS1:

; Fill in the top of DOS memory as @PPM_CNV unless EXCLUDEd

	 mov	 bx,LOWOFF.ELO	; Get top of original DOS memory
	 add	 bx,LOWSIZE	; Plus low fill size
	 shr	 bx,14-10	; Convert from 1KB to 16KB

	 cmp	 PPMTAB[bx-1],@PPM_EXC ; Izit EXCLUDEd?
	 je	 short CHECK_HPRS_CLC ; Yes, don't touch it

	 mov	 PPMTAB[bx-1],@PPM_CNV ; Mark as conventional memory
CHECK_HPRS_CLC:

; If we're on a 1MB system and neither EMS= nor EXT= have been specified,
; force EXT=0.

	 cmp	 PHYSIZE,1024	; Izit a 1MB system?
	 jne	 short @F	; Not this time

	 test	 CMD_FLAG,@CMD_EMS or @CMD_EXT ; Are either specified?
	 jnz	 short @F	; Yes, so don't force it

	 mov	 EXTSIZE,0	; Mark as EXT=0
	 or	 CMD_FLAG,@CMD_EXT ; Mark as specified
if @OEM_XMS
	 mov	 HMASIZE,0	; Mark as no HMA
	 or	 XMS_FLAG,mask $XMS_XHMA ; Mark as permanently unavailable
endif				; IF @OEM_XMS
@@:
	 clc			; Indicate we found it

	 jmp	 short CHECK_HPRS_EXIT ; Join common exit code

CHECK_HPRS_XPRES:

if @OEM_SYS eq @OEMSYS_HPRS
	 push	 offset YGROUP:MSG_XHPRS ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

	 stc			; Indicate not HPRS machine
CHECK_HPRS_EXIT:
	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_HPRS endp 		; End CHECK_HPRS procedure
endif				; IF @OEM_SYS eq @OEMSYS_HPRS or @OEM_SOFT
if @OEM_SOFT
	 NPPROC  CHECK_ITT -- Check for ITT XTRA/Alcatel
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of ITT XTRA/Alcatel.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pusha			; Save registers

	 lea	 di,ITTSIGN	; ES:DI ==> place where signature should be
	 lea	 si,LCL_ITTSIGN ; FS:SI ==> local copy of it
	 mov	 cx,LCL_ITTSIGN_LEN ; # bytes in signature
    repe cmps	 LCL_ITTSIGN[si],CGROUP:[di].LO ; Compare 'em
	 je	 short CHECK_ITT_PRES ; Jump if it's a match

	 lea	 di,ITTSIGN	; ES:DI ==> place where signature should be
	 lea	 si,LCL_ALCSIGN ; FS:SI ==> local copy of it
	 mov	 cx,ALCSIGN_LEN ; # bytes in signature
    repe cmps	 LCL_ALCSIGN[si],CGROUP:[di].LO ; Compare 'em
	 jne	 short CHECK_ITT_XPRES ; Jump if no match
CHECK_ITT_PRES:
	 or	 SYS_FLAG,@SYS_ITT ; Mark as ITT XTRA/Alcatel

	 test	 CM2_FLAG,@CM2_X384 ; Skip shadow RAM fill?
	 jnz	 short CHECK_ITT1 ; Yes

	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM
	 call	 SET_NOSCAN	; Set all bits in NOSCAN if C&T SHADOWRAM

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
CHECK_ITT1:

; Fill in the top of DOS memory as @PPM_CNV unless EXCLUDEd

	 mov	 bx,LOWOFF.ELO	; Get top of original DOS memory
	 add	 bx,LOWSIZE	; Plus low fill size
	 shr	 bx,14-10	; Convert from 1KB to 16KB

	 cmp	 PPMTAB[bx-1],@PPM_EXC ; Izit EXCLUDEd?
	 je	 short CHECK_ITT_CLC ; Yes, don't touch it

	 mov	 PPMTAB[bx-1],@PPM_CNV ; Mark as conventional memory
CHECK_ITT_CLC:
	 clc			; Indicate we found it

	 jmp	 short CHECK_ITT_EXIT ; Join common exit code

CHECK_ITT_XPRES:
	 stc			; Indicate not ITT machine
CHECK_ITT_EXIT:
	 popa			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ITT endp			; End CHECK_ITT procedure
endif				; IF @OEM_SOFT
if @OEM_SYS eq @OEMSYS_GRID or @OEM_SOFT
	 NPPROC  CHECK_GRID -- Check for GRiD Systems 1500 or Later and Desktops
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of GRiD Systems 1500 (Laptop) or later, or the line
of desktop machines made by Tandy for GRiD.

Desktop machines are identified by having a Phoenix copyright and:
  Classic bus machines have the byte 'C0' at F000:80A1 and
   an INT 15h model of @CPU_AT ...
  MCA bus machines have an INT 15h model of @CPU_MCA (notice no 'C0' byte) ...

and one of the following submodel codes:

81h	Tandy 4000, also Grid 1530 Laptop
82h	Tandy 4000LX aka GRiD 386is
03h	Tandy 4000SX aka GRiD 386isx
01h	Tandy 4016SX aka GRiD 386sx-MFP
01h	Tandy 5000   aka GRiD 386mc

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

@CFG_GRID_386IS2 equ 82h	; Grid 386is-XX (older version)
@CFG_GRID_1530	 equ 81h	; Grid 1530 Laptop (&Tandy 4000)
@CFG_GRID_386ISX equ 03h	; Grid 386isx
@CFG_GRID_386IS  equ 01h	; Grid 386 is-XX (newer version)
@CFG_GRID_MC	 equ 01h	; Grid 5000 (Micro channel)

	 pusha			; Save all GP registers
	 REGSAVE <es,gs>	; Save registers

;Check for Grid Laptop computer
	 cmp	 GRIDDASH.ELO,'--' ; Ensure correct signature
	 jne	 short CHECK_GRID_DESKTOPS ; Jump if not found

;;;;;;;; cmp	 GRIDSIGN.ELO,'RG' ; Ensure correct signature
;;;;;;;; jne	 short CHECK_GRID_XPRES ; Jump if not found
;;;;;;;;
;;;;;;;; cmp	 GRIDSIGN.EHI,'Di' ; Ensure correct signature
;;;;;;;; jne	 short CHECK_GRID_XPRES ; Jump if not found

	 mov	 ax,0E421h	; Get current color map
	 mov	 dl,0FFh	; Function code
	 int	 15h		; Request BIOS service
	 jc	 near ptr CHECK_GRID_XPRES ; Jump if not supported

	 cmp	 ah,00h 	; Check for valid return code
	 jne	 near ptr CHECK_GRID_XPRES ; Jump if not supported

; Check for 1450sx laptop

	 cmp	 GRIDMODEL,@GRIDLYNX.LO ; Izit a 1450sx?
	 jne	 short CHECK_GRID_X1450 ; If not, search for next ID

COMMENT |

If we are on a GRID 1450sx laptop,
we can't recover shadow RAM if any of these three modes are enabled.
	Standby mode
	Automatic standby mode
	Low power standby mode

|

;Check for Standby mode enabled

	 mov	ax, 0E489h	; Get/Set standby mode
	 mov	dl, 0FFh	; Get current state of standby mode
	 int	15h		; Request BIOS service
	 jc	short CHECK_GRID_STANDBY_OK ; Jump if standby mode not supported

	 cmp	ah,0		; AH should be 0
	 jne	short CHECK_GRID_NOXRAM ; Jump if error

	 cmp	dl,0		; Is standby mode disabled?
	 jne	short CHECK_GRID_NOXRAM ; If not, don't recover XRAM

CHECK_GRID_STANDBY_OK:

; Check for Auto standby mode enabled

	 mov	ax,0E48Ah	; Get/Set automatic standby mode
	 mov	dl,0FFh 	; Get state of auto standby mode
	 int	15h		; Request BIOS service
	 jc	short CHECK_GRID_AUTOSB_OK ;jump if auto standby mode not supported

	 cmp	ah,0		; AH should be 0
	 jne	short CHECK_GRID_NOXRAM ; Jump if error

	 cmp	dl,0		; Is auto standby mode disabled?
	 jne	short CHECK_GRID_NOXRAM ; If not, don't recover XRAM

CHECK_GRID_AUTOSB_OK:

; Check for Low Power Standby Mode enabled

	 mov	ax,0E48Bh	; Get/Set low power standby mode
	 mov	dl,0FFh 	; Get state of low power standby mode
	 int	15h		; Request BIOS service
	 jc	short CHECK_GRID_LOWBATT_OK ; Jump if low power standby not supported

	 cmp	ah,0		; AH should be 0
	 jne	short CHECK_GRID_NOXRAM ; Jump if error

	 cmp	dl,0		; Is low power standby mode disabled?
	 jne	short CHECK_GRID_NOXRAM ; If not, don't recover XRAM

CHECK_GRID_LOWBATT_OK:
	 jmp	 CHECK_GRID_CLC ; Proceed as normal

; Check for future laptops here

CHECK_GRID_X1450:
	 jmp	 CHECK_GRID_CLC ; Proceed as normal

CHECK_GRID_NOXRAM:
	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 FCN_NOXRAM	; Mark as NOXRAM

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it

	 jmp	short CHECK_GRID_CLC ; Proceed as normal

CHECK_GRID_DESKTOPS:

; Look for Phoenix signature

	 lea	 si,LCL_PHOENIXSIGN ; FS:SI ==> Tandy signature
	 lea	 di,PHOENIXSIGN     ; ES:DI ==> same if Tandy machine
	 mov	 cx,LCL_PHOENIXSIGN_LEN ; CX = length of ...
    repe cmps	 LCL_PHOENIXSIGN[si],PHOENIXSIGN[di] ; Compare 'em
	 jne	 short CHECK_GRID_XPRES ; Jump if no match

;;;;;;;; mov	 cl,GRIDSIGN2	; Save contents for later use

;Check to see if there is BIOS support
	 mov	 ah,0C0h	; Code to get BIOS configuration data
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_GRID_XPRES ; Not Tandy desktop (4000 series)

	 cmp	 ah,0		; Ensure AH=00 on return
	 jne	 short CHECK_GRID_XPRES ; Not Tandy desktop (4000 series)

; Check for MCA first then AT compatible ID byte

	 test	 es:[bx].CFG_PARMS,@CFG_MCA ; Izit an MCA?
	 jnz	 short CHECK_GRID_MCA ; Jump if so

	 cmp	 es:[bx].CFG_MODEL,@CPU_AT ; Ensure correct model byte
	 jne	 short CHECK_GRID_XPRES ; Not Tandy desktop (4000 series)

; Check for AT compatible signature
;;;;;;;;
;;;;;;;; cmp	 cl,@GRIDSIGN2	; Ensure correct signature
;;;;;;;; jne	 short CHECK_GRID_XPRES ; Jump if not found

	 push	 seg CGROUP	; Setup ES for BIOS References
	 pop	 es		; Address it
	 assume  es:CGROUP	; Tell the assembler about it

; Search for the TANDY string in F000:0 to FFFF

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset XGROUP:LCL_TANDYSIGN ; Get offset of source string
	 push	 LCL_TANDYSIGN_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short CHECK_GRID_XPRES ; Jump if not found
				; Return with DI = offset of match in ROM

; Check for System type byte (sub-model type)

;;;;;;;; cmp	 es:[bx].CFG_TYPE,@CFG_GRID_386IS2 ; Ensure correct type byte
;;;;;;;; je	 short CHECK_GRID_DESKTOP ; Found older Grid 386is
;;;;;;;;
;;;;;;;; cmp	 es:[bx].CFG_TYPE,@CFG_GRID_386ISX ; Ensure correct type byte
;;;;;;;; je	 short CHECK_GRID_DESKTOP ; Found Grid 386isx
;;;;;;;;
;;;;;;;; cmp	 es:[bx].CFG_TYPE,@CFG_GRID_386IS ; Ensure correct type byte
;;;;;;;; jne	 short CHECK_GRID_XPRES ; Not newer Grid 386is (or any other)

CHECK_GRID_DESKTOP:
	 test	 CM2_FLAG,@CM2_X384 ; Is NOXRAM specified?
	 jnz	 short CHECK_GRID_CLC	  ; Yes, don't use it

	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM
	 call	 SET_NOSCAN	; Set all bits in NOSCAN if C&T SHADOWRAM

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 CHECK_GRID_CLC ; Join common code

; It's an MCA with Tandy signature match

CHECK_GRID_MCA:
	 cmp	 es:[bx].CFG_TYPE,@CFG_GRID_MC ; Ensure correct type byte
	 je	 CHECK_GRID_CLC ; Found Tandy 5000

	 jmp	 CHECK_GRID_XPRES ; Join common not present code

CHECK_GRID_CLC:
	 or	 SYS_FLAG,@SYS_GRID ; Mark as GRiD Systems 1500 or later
				; and desktops including MCA machines
				; and 1450SX laptop
	 clc			; Indicate we found it

	 jmp	 short CHECK_GRID_EXIT ; Join common exit code

CHECK_GRID_XPRES:

if @OEM_SYS eq @OEMSYS_GRID
	 push	 offset YGROUP:MSG_XGRID ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_GRID

	 stc			; Indicate not GRiD machine
CHECK_GRID_EXIT:
	 REGREST <gs,es>	; Restore
	 assume  es:nothing,gs:nothing ; Tell the assembler about it
	 popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_GRID endp 		; End CHECK_GRID procedure
endif				; IF @OEM_SYS eq @OEMSYS_GRID or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_NEC or @OEM_SOFT
	 NPPROC  CHECK_NEC -- Check for NEC Systems
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of NEC and NEC SX Plus Systems

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pusha			; Save all GP registers

	 lea	 di,NECSIGN	; ES:DI ==> place where signature should be
	 lea	 si,LCL_NECSIGN ; FS:SI ==> local copy of it
	 mov	 cx,LCL_NECSIGN_LEN ; # bytes in signature
    repe cmps	 LCL_NECSIGN[si],CGROUP:[di].LO ; Compare 'em
	 jne	 short CHECK_NEC_XPRES ; Jump if not found

; Now distinguish SX Plus from others

	 lea	 di,NECSXSIGN	; ES:DI ==> place where signature should be
	 lea	 si,LCL_NECSXSIGN ; FS:SI ==> local copy of it
	 mov	 cx,LCL_NECSXSIGN_LEN ; # bytes in signature
    repe cmps	 LCL_NECSXSIGN[si],CGROUP:[di].LO ; Compare 'em
	 jne	 short CHECK_NEC_XSXPLUS ; Jump if not found

	 jmp	 short CHECK_NEC1 ; Join common code

CHECK_NEC_XSXPLUS:
	 test	 CM2_FLAG,@CM2_X384 ; Skip shadow RAM fill?
	 jnz	 short CHECK_NEC1 ; Yes

	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM
	 call	 SET_NOSCAN	; Set all bits in NOSCAN if C&T SHADOWRAM

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
CHECK_NEC1:
	 or	 SYS_FLAG,@SYS_NEC ; Mark as NEC System

	 clc			; Indicate we found it

	 jmp	 short CHECK_NEC_EXIT ; Join common exit code

CHECK_NEC_XPRES:

if @OEM_SYS eq @OEMSYS_NEC
	 push	 offset YGROUP:MSG_XNEC ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_NEC

	 stc			; Indicate not NEC machine
CHECK_NEC_EXIT:
	 popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_NEC endp			; End CHECK_NEC procedure
	 NPPROC  CHECK_NECLAP -- Check for NEC Systems
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of NEC UltraLigte Versa
This machine has a ROM with no signature at E800:0

On exit:

MEMMAP is updated

|

	 pusha			; Save all GP registers

	 lea	 di,NECSIGN2	; ES:DI ==> place where signature should be
	 lea	 si,LCL_NECSIGN ; FS:SI ==> local copy of it
	 mov	 cx,LCL_NECSIGN_LEN ; # bytes in signature
    repe cmps	 LCL_NECSIGN[si],CGROUP:[di].LO ; Compare 'em
	 jne	 short CHECK_NECLAP_XPRES ; Jump if not found

	 lea	 di,NECSIGNLAP	; ES:DI ==> place where signature should be
	 lea	 si,LCL_NECSIGNLAP ; FS:SI ==> local copy of it
	 mov	 cx,LCL_NECSIGNLAP_LEN ; # bytes in signature
    repe cmps	 LCL_NECSIGNLAP[si],CGROUP:[di].LO ; Compare 'em
	 jne	 short CHECK_NECLAP_XPRES ; Jump if not found

; Update MEMMAP
	 push	 es		; Save for later

	 push	 seg PGROUP	; Address PGROUP
	 pop	 es		; w/ES
	 assume  es:PGROUP	; Tell assembler

	 lea	 di,MEM_MAP

	 lea	 di,MEM_MAP[ (0E800h shr (9-4)) ] ; Address MEM_MAP
	 mov	 cx,32 shl (10-9) ; Express 32KB in 512-bytes

;;;	 call	 ROM2OVR	; Mark as type AL memory in MEM_MAP
;;;				; offset DI for CX entries

	 mov	 al,@XLAT_ROM1	; ROM entry, 1st of many
	 stos	 MEM_MAP[di].LO ; Write in first entry

	 dec	 cx		; Update CX

	 mov	 al,@XLAT_ROM2	; ROM entry, 2nd and subsequent
     rep stos	 MEM_MAP[di].LO ; Write in the rest of the entries

	 pop	 es		; Restore used register

CHECK_NECLAP_XPRES:

CHECK_NECLAP_EXIT:
	 popa			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_NECLAP endp			; End CHECK_NECLAP procedure
endif				; IF @OEM_SYS eq @OEMSYS_NEC or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2 or @OEM_SOFT
	 NPPROC  CHECK_OLI -- Check for AT&T/Olivetti Signature
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of AT&T/Olivetti.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 lea	 di,OLISIGN	; ES:DI ==> place where signature should be
	 lea	 si,LCL_OLISIGN ; FS:SI ==> local copy of it
	 mov	 cx,OLISIGN_LEN ; # bytes in signature
    repe cmps	 LCL_OLISIGN[si],CGROUP:[di].LO ; Compare 'em
	 jne	 near ptr CHECK_OLI_XPRES ; Jump if no match

	 test	 CM2_FLAG,@CM2_X384 ; Skip shadow/built-in RAM fill?
	 jnz	 near ptr CHECK_OLI_CLC ; Yes, skip all this

; Check for MCA which has no built-in RAM at 800A0000h

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jnz	 near ptr CHECK_OLI_CLC ; Yes, don't recover any RAM

; Check for Olivetti M300 -- this machine has no built-in RAM
; so don't attempt to recover it

	 cmp	 OLIALTID,@OLI_M300 ; Izit an M300?
	 je	 near ptr CHECK_OLI_CLC ; Jump if so

; Check for Olivetti M305/M310 -- this machine has no built-in RAM
; so don't attempt to recover it

	 cmp	 OLIALTID,@OLI_M305 ; Izit an M305/M310?
	 je	 near ptr CHECK_OLI_CLC ; Jump if so

; Check for Olivetti M386/25 (XP2) -- this machine has no built-in RAM
; so don't attempt to recover it

	 cmp	 OLIALTID,@OLI_XP2 ; Izit an M386/25 (XP2)?
	 je	 near ptr CHECK_OLI_CLC ; Jump if so

; Check for Olivetti M386/20? (XP1/3/5) -- this machine has built-in RAM
; Check for AT&T WGS 6386 (Olivetti XP1)

	 cmp	 OLIALTID,@OLI_XP5 ; Izit an M386/20? (XP1/3/5)?
	 je	 near ptr CHECK_OLI_RAM ; Jump if so

; Check for Olivetti M386/25 (XP4/7/9) -- this machine has built-in RAM

	 cmp	 OLIALTID,@OLI_XP9 ; Izit an M386/25 (XP4/7/9)?
	 je	 near ptr CHECK_OLI_RAM ; Jump if so

; Check for Olivetti M316 -- this machine has C&T shadow RAM

	 cmp	 OLIALTID,@OLI_M316 ; Izit an M316?
	 je	 near ptr CHECK_OLI_SHD ; Jump if so to recover shadow RAM

	 jmp	 short CHECK_OLI_CLC ; Otherwise, no RAM recovery

CHECK_OLI_SHD:
	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM
	 call	 SET_NOSCAN	; Set all bits in NOSCAN if C&T SHADOWRAM

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it

	 jmp	 short CHECK_OLI_CLC ; Join common code


; Recover built-in RAM at 800A000h

CHECK_OLI_RAM:

; Check for ROM at E000 or E800.
; If not present, recover all 384KB.
; If present, and the vectors point to the ROM, re-vector them,
;   and recover all 384KB.
; Otherwise, recover the lower 256KB only.

	 mov	 ax,256 	; Amount of RAM in KB to recover

	 test	 NRD_FLAG,@NRD_UE000 ; Is E000 available?
	 jz	 short CHECK_OLI_SAVE ; Jump if not

	 call	 far ptr OLI_RESET ; Disable the system's use of built-in RAM
	 jc	 short CHECK_OLI_SAVE ; Jump if something went wrong

	 mov	 ax,384 	; Amount of RAM in KB to recover

; Recover AX KB of shadow RAM at 2GB+640KB

CHECK_OLI_SAVE:
	 push	 ax		; Amount of RAM in 1KB
	 push	 dword ptr 800A0000h ; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure
CHECK_OLI_CLC:
	 or	 SYS_FLAG,@SYS_OLI ; Mark as Olivetti/AT&T system

	 clc			; Indicate we found it

	 jmp	 short CHECK_OLI_EXIT ; Join common exit code

CHECK_OLI_XPRES:
	 sti			; Allow interrupts

if @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2
	 push	 offset YGROUP:MSG_XOLI ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2

	 stc			; Indicate not AT&T/Olivetti machine
CHECK_OLI_EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore
	 assume  es:CGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_OLI endp			; End CHECK_OLI procedure
endif				; IF @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2 or @OEM_SOFT
if @OEM_SYS eq @OEMSYS_AM1 or @OEM_SYS eq @OEMSYS_AM2
	 NPPROC  CHECK_AM1 -- Check for AMKLY memory board in a MCA slot
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing

COMMENT|

Check on presence of AMKLY MCA board
This routine is called for AM1 - Version similar to LIMit
			   AM2 - Version similar to MAX (w/o LOAD)

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pusha			; Save all GP registers

; See if we're on an MCA-compatible machine

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jz	 short CHECK_AM1_ERR ; Not this time

	 lea	 si,MCAID	; FS:SI ==> adapter IDs
	 mov	 cx,8		; Loop counter
CHECK_AM1_NEXT:
	 lods	 MCAID		; Get the next ID

	 cmp	 ax,7430h	; Izit our memory adapter?
	 je	 short CHECK_AM1_CLC ; Yep

	 loop	 CHECK_AM1_NEXT ; Jump if more channels to check
CHECK_AM1_ERR:
	 push	 offset YGROUP:MSG_XAM1 ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message

	 stc			; Mark as not found

	 jmp	short CHECK_AM1_EXIT ; Join common exit code

CHECK_AM1_CLC:
	 clc			; Mark as found
CHECK_AM1_EXIT:
	 popa			; Restore all registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_AM1 endp			; End CHECK_AM1 procedure
endif				; IF @OEM_SYS eq @OEMSYS_AM1 or @OEM_SYS equ @OEMSYS_AM2
if @OEM_SYS eq @OEMSYS_AM3
	 NPPROC  CHECK_AM3 -- Check for AMKLY EISA system board
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing

COMMENT|

Check on presence of AMKLY EISA system board

On exit:

CF	 =	 0 if found
	 =	 1 if not

The EISA system board has a two byte compressed manufacturer code.
 "AMK" packs into 2 bytes.
 Port 0C80h has an 05h
 Port 0C81h has an ABh

|

	 pusha			; Save all GP registers

; See if we're on an EISA machine

	 test	 NRD_FLAG,@NRD_EISA ; Izit an EISA machine?
	 jz	 short CHECK_AM3_ERR ; Not this time

; See if we're on an Amkley EISA

	 mov	 dx,EISA_SysID_Port1 ; EISA System board product ID port 1
	 in	 al,dx		; Get the first System board product ID byte
	 mov	 ah,al		; Save first byte

	 mov	 dx,EISA_SysID_Port2 ; EISA System board product ID port 2
	 in	 al,dx		; Get the second System board product ID byte

	 cmp	 ax,05ABh	; Izit an Amkly system board?
	 je	 short CHECK_AM3_CLC ; We have a winner!

CHECK_AM3_ERR:
	 push	 offset YGROUP:MSG_XAM3 ; Tell 'em to find the correct machine
	 call	 YMSGOUT2	; Display YGROUP message

	 stc			; Mark as not found

	 jmp	short CHECK_AM3_EXIT ; Join common exit code

CHECK_AM3_CLC:
	 clc			; Mark as found
CHECK_AM3_EXIT:
	 popa			; Restore all registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_AM3 endp			; End CHECK_AM3 procedure
endif				; IF @OEM_SYS eq @OEMSYS_AM3
if @OEM_SOFT
	 NPPROC  CHECK_DELL -- Check for Dell Systems Signature
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of Dell Systems 310/325/310A/...

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <si,di>		; Save registers

; Search for the DELL string in F000:0 to FFFF

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset XGROUP:LCL_DELLSIGN ; Get offset of source string
	 push	 LCL_DELLSIGN_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 near ptr CHECK_DELL_EXIT ; Jump if not found (note CF=1)
				; Return with DI = offset of match in ROM

	 or	 SYS_FLAG,@SYS_DELL ; Mark as Dell Systems 310/325/310A/....

	 cmp	 DELLTYPE,@DELL_SYS300	; Check for 300
	 je	 CHECK_DELL_FOUND	; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS310	; Check for 310
	 je	 CHECK_DELL_FOUND	; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS325	; Check for 325
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS310A ; Check for 310A
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS316	; Check for 316
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS316SX ; Check for 316SX
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS316LT ; Check for 316LT
	 je	 short CHECK_DELL_VGA	; If a match, jump to VGA check

	 cmp	 DELLTYPE,@DELL_SYS320LX ; Check for 320LX
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS425E ; Check for 425E
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS433E ; Check for 433E
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS320LT ; Check for 320LT
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS3xxD ; Check for 325D/333D
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS3xxP ; Check for 325D/333P
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS425GE ; Check for 425GE
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS433GE ; Check for 433GE
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 cmp	 DELLTYPE,@DELL_SYS320N ; Check for 320N
	 je	 short CHECK_DELL_FOUND ; Jump if a match

	 jmp	 CHECK_DELL_CLC ; Exit - unsupported system type

CHECK_DELL_VGA:

if 0 ;=============  This is handled by FLEXROM_RESET ==================

	 ; Check certain models for special case where 1f and 43h point
	 ; into C000, and C000 and E000 both have BIOS signatures and
	 ; appear to have the same size.  If this is the case, blast in
	 ; USE=E000-E600.  The only models we know to do this are:
	 ; 316LT
	 ; These models allow shadowing of the VGA BIOS located at E000,
	 ; but our normal shadow detection scheme doesn't work because
	 ; the shadow differs by a few bytes; numerous references to
	 ; the segment are changed, as well as another byte to keep the
	 ; checksum constant.  This VGA BIOS also lies about its size;
	 ; it is actually 32K.

	 mov	 di, 0E000h	; Check for VGA shadow at E000
	 mov	 si, 0C000h	; With active VGA at C000
	 call	 CHECK_QROM	; Check for condition described above
	 jnc	 short CHECK_DELL_FOUND ; If successful, don't try again

	 mov	 di, 0E800h	; Check for VGA shadow at E800
	 mov	 si, 0E000h	; With active VGA at E000
	 call	 CHECK_QROM	; Check for shadowed ROM
endif ;=======

CHECK_DELL_FOUND:
	 call	 DELL_SETSPEED	; Determine a value for the 8042 delay byte

	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM
	 call	 SET_NOSCAN	; Set all bits in NOSCAN if C&T SHADOWRAM

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
CHECK_DELL_CLC:
	 clc			; Indicate we found it
CHECK_DELL_EXIT:

	 REGREST <di,si>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DELL endp 		; End CHECK_DELL procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 NPPROC  DELL_SETSPEED -- Calculate 8042 delay byte for Dell systems
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Many Dell systems use a byte at 40:b0 (DELL_KEYB) as a timing base for
communication with the 8042.  This value depends on whether the ROM is
shadowed or not.  We recalculate this value here and store it in
SHAD_KEYB_DLY.	This value is blasted into the BIOS data area in QMAX_TIM.

No registers used for input or output.

|

	 REGSAVE <AX,BX,CX,DX>	; Save registers

	 pushf			; Save flags with EI bit
	 cli			; Turn off interrupts

DELL_SETSPEED0:
	 mov	 al,@TIMER_LATCH ; Latch & snatch channel 0
	 out	 @8253_CTL,al	; Latch
	 jmp	 short $+2	; Wait for I/O to settle
	 jmp	 short $+2	; Wait for I/O to settle
	 jmp	 short $+2	; Wait for I/O to settle

	 in	 al,@8253_CH0	; Snatch counter 0 LSB
	 jmp	 short $+2	; Wait for I/O to settle
	 jmp	 short $+2	; Wait for I/O to settle
	 jmp	 short $+2	; Wait for I/O to settle
	 mov	 ah,al		; Save in AH

	 in	 al,@8253_CH0	; Snatch counter 0 MSB
	 xchg	 ah,al		; Swap bytes
	 mov	 bx,ax		; Save in BX
	 mov	 cx,100 	; loop 100 times
@@:
	 loop	 @B		; Spin for a while

	 mov	 al,@TIMER_LATCH ; Latch & snatch channel 0 again
	 out	 @8253_CTL,al	; Latch it
	 jmp	 short $+2	; Wait for I/O to settle
	 jmp	 short $+2	; Wait for I/O to settle
	 jmp	 short $+2	; Wait for I/O to settle

	 in	 al,@8253_CH0	; Snatch counter 0 LSB
	 jmp	 short $+2	; Wait for I/O to settle
	 jmp	 short $+2	; Wait for I/O to settle
	 jmp	 short $+2	; Wait for I/O to settle
	 mov	 ah,al		; Save in AH

	 in	 al,@8253_CH0	; Snatch counter 0 MSB
	 xchg	 ah,al		; Swap bytes
	 sub	 bx,ax		; Get difference
	 jc	 short DELL_SETSPEED0 ; If AX > BX, try again

	 popf			; Restore EI bit

	 shr	 bx,1		; BX >>= 1
	 cmp	 bx,0e00h	; Izit below the limit?
	 jb	 short @F	; Yes, so BX is cool
	 mov	 bx,0dffh	; Maximum value allowed
@@:
	 mov	 ax,bx		; Get dividend in AX
	 mov	 cl, 0eh	; Divisor of 14 will divide original value by 28
	 div	 cl		; Quotient in AL
	 sub	 ah,ah		; Clear remainder
	 sub	 bx,ax		; BX = ((ctdiff>>1) - (int) (ctdiff >> 1) / 14)
	 sub	 dx,dx		; Clear DX for DIV
	 mov	 ax,2e9dh	; Constant value (11,933)
	 div	 bx		; AX = quotient

	 mov	 SHAD_KEYB_DLY, al ; Blast it in (ignore high byte)

	 REGREST <DX,CX,BX,AX>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DELL_SETSPEED endp		; End DELL_SETSPEED procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 NPPROC  CHECK_ALR -- Check for ALR Systems Signature
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of ALR Systems FlexCache

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <di>		; Save register

; Search for the ALR string in F000:0 to FFFF

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset XGROUP:LCL_ALRSIGN ; Get offset of source string
	 push	 LCL_ALRSIGN_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 near ptr CHECK_ALR_EXIT ; Jump if not found (note CF=1)
				; Return with DI = offset of match in ROM

	 mov	 SHAD_KEYB_DLY,0E0h ; Blast in an arbitrary value
CHECK_ALR_CLC:
	 clc			; Indicate we found it
CHECK_ALR_EXIT:
	 REGREST <di>		; Restore register

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ALR endp			; End CHECK_ALR procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 NPPROC  CHECK_ZDS -- Check for Zenith Systems Signature
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of Zenith Systems.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pusha			; Save registers

	 lea	 si,LCL_ZDSSIGN ; FS:SI ==> local copy of signature
	 lea	 di,ZDSSIGN	; ES:DI ==> ROM ...
	 mov	 cx,LCL_ZDSSIGN_LEN ; # bytes in signature
    repe cmps	 LCL_ZDSSIGN[si],CGROUP:[di].LO ; Check for a match
	 jne	 short CHECK_ZDS_XPRES ; Jump if mismatch

	 or	 SYS_FLAG,@SYS_ZDS ; Mark as Zenith Systems
	 and	 NRD_FLAG,not @NRD_UE000 ; Mark E000 as unavailable

; Mark F000-F100 as unavailable because it's used for ROM scratchpad area

	 push	 seg PGROUP	; Get our data segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MEM_MAP[0F000h shr (9-4)] ; ES:DI ==> F000 in MEM_MAP
	 mov	 cx,(4*1024) shr (9-0) ; # 512-bytes blocks in 4KB
	 mov	 ah,PGROUP:[di] ; Get and save the initial ROM byte
	 mov	 al,@XLAT_OTH	; Mark as other high DOS memory
     rep stos	 PGROUP:[di].LO ; Fill it up
	 mov	 PGROUP:[di],ah ; Save old initial ROM marker

CHECK_ZDS_CLC:
	 clc			; Indicate we found it

	 jmp	 short CHECK_ZDS_EXIT ; Join common exit code

CHECK_ZDS_XPRES:
	 stc			; Indicate not Zenith Data Systems machine
CHECK_ZDS_EXIT:
	 popa			; Restore
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ZDS endp			; End CHECK_ZDS procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 NPPROC  CHECK_AMSTRAD -- Check For AMSTRAD PC
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of AMSTRAD PC.
If found, mark as NOCOMPROM as they roll their own
BIOS and don't put everything into the second half.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 push	 di		; Save register

; Search for the AMSTRAD string in F000:0 to FFFF

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset XGROUP:LCL_AMSTRADSIGN ; Get offset of source string
	 push	 LCL_AMSTRADSIGN_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short CHECK_AMSTRAD_EXIT ; Jump if not found (note CF=1)
				; Return with DI = offset of match in ROM

	 or	 SYS_FLAG,@SYS_AMSTRAD ; Mark as present

	 push	 es		; Save for a moment

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 FCN_NOCOMPROM	; Force NOCOMPROM

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it

	 clc			; Indicate we found it
CHECK_AMSTRAD_EXIT:
	 pop	 di		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_AMSTRAD endp		; End CHECK_AMSTRAD procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 NPPROC  CHECK_CPQ386 -- Check For COMPAQ Deskpro 386
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of COMPAQ Deskpro 386

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <eax,cx,dx,si,di,ds,es> ; Save registers

	 cmp	 VENDOR.EDD[0],'PMOC' ; Check for 'COMPAQ'
	 jne	 near ptr CHECK_CPQ386_ERR ; Not this time

	 cmp	 VENDOR.ELO[4],'QA' ; Check for 'COMPAQ'
	 jne	 near ptr CHECK_CPQ386_ERR ; Not this time

	 cmp	 BIOS_TYPE.ELO,'60' ; Check for COMPAQ 686 product
	 je	 short @F	; Good guess

	 cmp	 BIOS_TYPE.ELO,'50' ; Check for COMPAQ 586 product
	 je	 short @F	; Good guess

	 cmp	 BIOS_TYPE.ELO,'40' ; Check for COMPAQ 486 product
	 je	 short @F	; Good guess

	 cmp	 BIOS_TYPE.ELO,'30' ; Check for COMPAQ 386 product
	 jne	 near ptr CHECK_CPQ386_ERR ; Not this time
@@:
	 mov	 si,OFFCPQSTR	; ES:SI ==> CPQSTR
	 mov	 LOFFCPQSTR,si	; Save for later use in case COMPROM changes it

; Determine if the 80C00000 I/O port scheme to recover shadow memory
; exists.  Newer COMPAQs remap their extra memory to the top of extended
; memory instead of this scheme.  If this is true, CPQSTR_FLAG will
; contain FFFF, and there will be no extra memory to recover.

; Note: Some Micronics systems put "COMPAQ" in the vendor ID field,
; but don't implement the 80C00000 protocol.  However, we no longer can
; use the 80C00000 scheme in our COMPAQ detection scheme since the newer
; COMPAQs do not support 80C00000.

	 cmp	 CGROUP:[si].CPQSTR_FLAG,0FFFFh ; Check the presence flag
	 je	 short CHECK_CPQ386_NOCPQSTR ; No extra memory available

	 cmp	 CGROUP:[si].CPQSTR_TOT,4000h ; Ensure reasonable
	 ja	 near ptr CHECK_CPQ386_ERR ; It's not, skip all this

	 cmp	 CGROUP:[si].CPQSTR_AVL,4000h ; Ensure reasonable
	 ja	 near ptr CHECK_CPQ386_ERR ; It's not, skip all this

	 cmp	 CGROUP:[si].CPQSTR_LOW,0A000h ; Ensure reasonable
	 jb	 near ptr CHECK_CPQ386_ERR ; It's not, skip all this

; Newer COMPAQs, such as the Deskpro 466 XE, have no shadow RAM.
	 cmp	 CGROUP:[si].CPQSTR_TOT,0 ; Is there any shadow RAM?
	 je	 short CHECK_CPQ386_NOCPQSTR ; Jump if not

	 cmp	 CGROUP:[si].CPQSTR_AVL,0 ; Is any of it available?
	 je	 short CHECK_CPQ386_NOCPQSTR ; Jump if not

	 or	 I15_FLAG,@I15_CPQ ; Use COMPAQ TOP384 scheme
	 or	 CM3_FLAG,@CM3_XSCRB ; Mark as not scrubbing extra RAM

CHECK_CPQ386_NOCPQSTR:

	 and	 CM2_FLAG,not @CM2_TOP ; Remove TOP384 if specified
	 or	 SYS_FLAG,@SYS_CPQ ; Mark as COMPAQ Deskpro 386/486

; Check for COMPAQ VGA BIOS with bug during set mode in modes 4, 5, 6
; as well as the bug in mode switch with an incorrect assume on DS

	 push	 dword ptr 0C0000000h ; Get starting offset of BIOS
	 push	 24*1024	; Length of search area (24KB)
	 push	 offset XGROUP:CPQVGASIGN ; Get offset of source string
	 push	 CPQVGASIGN_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short CHECK_CPQ386_XBUG ; Jump if not found
				; Return with DI = offset of match in ROM

	 push	 dword ptr 0C0000000h ; Get starting offset of BIOS
	 push	 24*1024	; Length of search area (24KB)
	 push	 offset XGROUP:CPQVGABUG ; Get offset of source string
	 push	 CPQVGABUG_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short @F	; Jump if not found
				; Return with DI = offset of match in ROM
	 add	 di,CPQVGABUG_LEN2 ; Skip over good code in search string
	 mov	 CPQVGAOFF,di	; Save start of patch for later use

	 or	 NRD_FLAG,@NRD_CPQVGA ; Mark as present
@@:
	 push	 dword ptr 0C0000000h ; Get starting offset of BIOS
	 push	 24*1024	; Length of search area (24KB)
	 push	 offset XGROUP:CPQVGABUG2 ; Get offset of source string
	 push	 CPQVGABUG2_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short @F	; Jump if not found
				; Return with DI = offset of match in ROM
	 lea	 ax,[di+CPQVGABUG2_PAT1] ; Calculate 1st patch point
	 mov	 CPQVGAOFF2A,ax ; Save for later use

	 lea	 ax,[di+CPQVGABUG2_PAT2] ; Calculate 2nd patch point
	 mov	 CPQVGAOFF2B,ax ; Save for later use

	 or	 NRD_FLAG,@NRD_CPQVGA2 ; Mark as present
@@:
CHECK_CPQ386_XBUG:

if @OEM_HIFILL

if @OEM_CPQCUT
; See if the system supports a cut table

	 call	 CHECK_CPQCUT	; Check for and process cut table
endif				; IF @OEM_CPQCUT

; See if we should compress the system ROM

; Note that the value of OFFCPQSTR might change over the call to COMPROM
; which is why we save it in LOFFCPQSTR.

	 call	 CHECK_CROM	; Check on it
endif				; IF @OEM_HIFILL

; If there is more than 16MB-384KB of RAM installed, force NOXRAM

	 cmp	 PHYSIZE,16*1024-384 ; Check it
	 jbe	 short @F	; Jump if there's no overlap

	 or	 CM2_FLAG,@CM2_X384 ; Skip shadow RAM fill
@@:

if @OEM_DMA

; If the user didn't specify DMA=, use 64KB so we can format floppy disks

	 test	 CM3_FLAG,@CM3_DMA ; Izit specified?
	 jnz	 short @F	; Yes, don't override the value

	 mov	 DMASIZE,64	; Use 64KB as default
@@:
endif				; IF @OEM_DMA
CHECK_CPQ386_CLC:
	 clc			; Indicate we found it

	 jmp	 short CHECK_CPQ386_EXIT ; Join common exit code

CHECK_CPQ386_ERR:
	 stc			; Indicate we didn't find it
CHECK_CPQ386_EXIT:
	 REGREST <es,ds,di,si,dx,cx,eax> ; Restore
	 assume  ds:PGROUP,es:CGROUP ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPQ386 endp		; End CHECK_CPQ386 procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT and @OEM_CPQCUT
	 NPPROC  CHECK_CPQCUT -- Check For COMPAQ Cut Table
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of COMPAQ Cut Table

On exit:

CF	 =	 0 if found
	 =	 1 if not

If a Cut table is found:
	SYSROM_START is updated to reflect the new BIOS start
	MEM_MAP is updated to reflect the added High DOS
	CM3_FLAG is updated to reflect that compression is no longer needed

|

CUT_TABLE	struc		; Cut Table Header
   CT_FLAG	dw	?	; Flag (1234 = Valid Cut table)
   CT_ENTRIES	db	?	; Number of entries
   CT_FIRSTENTRY db	?	; Start of first entry
CUT_TABLE	ends

CUT_ENTRY_STR	struc		; Cut Table Entry definition
   CTE_TYPE	db	?	; Type of memory (POST,Video,etc)
   CTE_OFFSET	dw	?	; Offset of end of address space
CUT_ENTRY_STR	ends

CTE_ENTRY_STR_LEN equ size CUT_ENTRY_STR ; Length of 1 Cut Table entry

; List of Cut Table Entry Points

@CUT_SEGMENT	equ	01h	; Segment Base
@CUT_POST	equ	02h	; POST Code
@CUT_RUNTIME	equ	03h	; Run Time Code
@CUT_SETUP	equ	04h	; Set Up Code
@CUT_INT42	equ	05h	; Int 42 System Video Code
@CUT_PM16	equ	06h	; 16 bit PM mode capable code
@CUT_PM32	equ	07h	; 32 bit PM mode capable code

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save

	 test	 CM3_FLAG,@CM3_XCROM ; Compressing today?
	 jnz	 near ptr CHECK_CPQCUT_EXIT ; Jump if not

; Only BIOSes dated 1990 or later have valid vector tables

	 cmp	 BIOS_DATE+6,'8' ; Look at tens digit in year
	 je	 short CHECK_CPQCUT_STC ; 198X is no good

; Determine if the Cut Table is defined in vector table

	 cmp	 CPQCUT_POINTER,0 ; Is the pointer null?
	 je	 short CHECK_CPQCUT_STC ; Cut table is not defined

; Determine if the Cut table is valid

	 mov	 si,CPQCUT_POINTER ; Address the Cut Table

	 cmp	 CGROUP:[si].CT_FLAG,1234h ; Is table valid?
	 jne	 short CHECK_CPQCUT_STC ; Cut table is not valid

	 movzx	 cx,CGROUP:[si].CT_ENTRIES ; Get no. of entries in cut table
	 jcxz	 short CHECK_CPQCUT_STC ; No entries, mark as no table found

; Process the Cut Table entries

	 add	 si,CT_FIRSTENTRY ; Address first entry in Cut Table
	 mov	 dx,SYSROM_START ; Initialize local copy of System ROM start
CHECK_CPQCUT_LOOP:
	 mov	 al,CGROUP:[si].CTE_TYPE ; Get Entry Type
	 mov	 bx,CGROUP:[si].CTE_OFFSET ; Get Entry Operand

	 cmp	 al,@CUT_SEGMENT ; Izit a Segment Base?
	 je	 short CHECK_CPQCUT_SEGMENT ; Yes it is

	 cmp	 al,@CUT_POST	; Izit Post code?
	 je	 short CHECK_CPQCUT_DISCARD ; Yes, we can discard it

	 cmp	 al,@CUT_SETUP	; Izit Setup code?
	 je	 short CHECK_CPQCUT_DISCARD ; Yes, we can discard it

	 jmp	 short CHECK_CPQCUT_OVR ; No more discardable entries

CHECK_CPQCUT_DISCARD:
	 inc	 bx		; Round up offset
	 shr	 bx,(4-0)	; Convert bytes -> paras

	 and	 dx,0F000h	; Mask off all insignificant digits in segment
	 add	 dx,bx		; Add new Offset to Segment

	 jmp	 short CHECK_CPQCUT_NEXT ; Prepare for next entry

CHECK_CPQCUT_SEGMENT:
	 mov	 dx,bx		; Save segment base

;;;;;;;; jmp	 short CHECK_CPQCUT_NEXT ; Prepare for next entry

CHECK_CPQCUT_NEXT:
	 add	 si,CTE_ENTRY_STR_LEN ; Point to next entry

	 loop	 short CHECK_CPQCUT_LOOP ; Process next entry

; We've processed all entries, now convert ROM to High DOS

CHECK_CPQCUT_OVR:
	 and	 dx,0FF00h	; Round down to 4KB boundary
	 call	 CHECK_LOSTINT	; Check for interrupts between SYSROM_START
				; and DX:0.  Set SYSROM_START to DX and
				; return old SYSROM_START in DX.

; Get ROM marker for old SYSROM_START

	 mov	 di,dx		; Get start of original BIOS
	 shr	 di,(9-4)	; Convert paras -> 512-bytes
	 mov	 ah,MEM_MAP[di] ; Get ROM marker

; Get the # of 512 byte chunks to recover

	 sub	 dx,SYSROM_START ; Subtract old start from new start of ROM
	 neg	 dx		; Turn to a positive number
	 shr	 dx,(9-4)	; Convert paras -> 512-bytes
	 mov	 bx,dx		; Move to index register

; Save new Start of ROM marker

	 mov	 MEM_MAP[bx+di],ah ; Mark new start of ROM

; Inform MEM_MAP about recovered High DOS

	 mov	 cx,bx		; # of 512 byte entries
	 mov	 al,@XLAT_OVR	; Mark as high DOS memory
	 call	 ROM2OVR	; Mark as high DOS memory in MEM_MAP
				; offset DI for CX entries

	 or	 CM3_FLAG,@CM3_XCROM ; Mark as not compressing system ROMs

	 clc			; Mark as Cut Table processed

	 jmp	 short CHECK_CPQCUT_EXIT ; All done

CHECK_CPQCUT_STC:
	 stc			; Mark as no Cut Table found
CHECK_CPQCUT_EXIT:
	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPQCUT endp		; End CHECK_CPQCUT procedure
endif				; IF @OEM_SOFT and @OEM_CPQCUT
if @OEM_SOFT
	 NPPROC  READ_CMOS -- Read CMOS Data
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read CMOS data

On entry:

AH	 =	 index register to read

On exit:

AL	 =	 data value for register in AH

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 al,ah		; Copy register # to AL
	 out	 @CMOS_CMD,al	; Send command to CMOS
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Read data from CMOS

	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_CMOS endp			; End READ_CMOS procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 NPPROC  SEND_CMOS -- Send Data to CMOS
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Send data to CMOS

On entry:

AH	 =	 index register
AL	 =	 data to write

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 xchg	 al,ah		; Swap register and data value
	 out	 @CMOS_CMD,al	; Send command to CMOS
	 jmp	 short $+2	; I/O delay

	 xchg	 al,ah		; Restore original data value
	 out	 @CMOS_DATA,al	; Send data to CMOS

	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEND_CMOS endp			; End SEND_CMOS procedure
endif				; IF @OEM_SOFT
if @OEM_HIFILL
	 NPPROC  CHECK_CROM -- Check On Compressing System ROM
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on compressing system ROM.

|

	 test	 CM3_FLAG,@CM3_XCROM ; Compressing today?
	 jnz	 short @F	; Jump if not

	 test	 LCL_FLAG,@LCL_CROM or @LCL_MCA ; Already compressed or MCA?
	 jnz	 short @F	; Jump if not

	 call	 COMPROM	; Attempt to compress it
	 jc	 short @F	; Jump if unsuccessful

	 or	 LCL_FLAG,@LCL_CROM ; Mark as successful
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CROM endp 		; End CHECK_CROM procedure
endif				; IF @OEM_HIFILL
	 NPPROC  CHECK_UNROM -- Check On Unshadowing Any ROM
	 assume  ds:PGROUP,es:CGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check on unshadowing any ROM

1) See if either E000, E800 or F000 contain a ROM signature
2) See if there is an alternate ROM that is similar (usually at C000)
3) Turn on VGASWAP if it is off
4) Save variables for later video ROM unshadowing
   A) Relocate all video resources
   B) Recover High DOS on top of old video ROMs

On exit:

CF	 =	 0 if no error
	 =	 1 if ROM present, but we're unable to relocate INTs

|

	 REGSAVE <ax,bx,dx,di,es,fs> ; Save registers

; Determine if there is a ROM at E000 or E800 or F000

	 mov	 di,0E000h	; Assumed segment
	 mov	 es,di		; Address it
	 assume  es:RGROUP	; Tell the assembler about it

	 cmp	 ROMSIGN,@ROMSIGN ; Check for the signature at E000:0
	 je	 short CHECK_UNROMIT ; Jump if present

	 mov	 di,0E800h	; Assumed segment
	 mov	 es,di		; Address it
	 assume  es:RGROUP	; Tell the assembler about it

	 cmp	 ROMSIGN,@ROMSIGN ; Check for the signature at E800:0
	 je	 short CHECK_UNROMIT ; Jump if present

	 mov	 di,0F000h	; Assumed segment
	 mov	 es,di		; Address it
	 assume  es:RGROUP	; Tell the assembler about it

	 cmp	 ROMSIGN,@ROMSIGN ; Check for the signature at F000:0
	 jne	 near ptr CHECK_UNROM_AVAIL ; Jump if not present

CHECK_UNROMIT:

; We have a BIOS above C000, now check for an alternate video BIOS.
; We can not assume that the alternate ROM will be at C000 (thanks Dell)

	 mov	 ax,0C000h	; Assumed segment
	 mov	 es,ax		; Address it
	 assume  es:RGROUP	; Tell the assembler about it

	 cmp	 ROMSIGN,@ROMSIGN ; Check for the signature at C000:0
	 je	 short CHECK_UNROMIT2 ; Jump if present

; Check for a second video ROM above C000 here

	 mov	 ax,di		; Get segment of video
	 xor	 ax,(0E000h xor 0E800h) ; Switch (E000 to E800) or (E800 to E000)
	 mov	 es,ax		; Address the other allegged video ROM
	 assume  es:RGROUP	; Tell the assembler about it

	 cmp	 ROMSIGN,@ROMSIGN ; Check for the signature at ES:0
	 jne	 near ptr CHECK_UNROM_AVAIL ; Jump if not present

CHECK_UNROMIT2:

; See whether or not the video ROM at AX:0 is shadowed at DI:0
; If one of the ROMS is at C000, it will be AX

	 call	 CHECK_SHDROM	; See if ROM at AX:0 is shadowed at DI:0
if @OEM_DEBUG
	 lea	 dx,YGROUP:MSG_SHDROM2 ; Assume not present at C000
endif				; IF @OEM_DEBUG
	 jc	 near ptr CHECK_UNROM_AVAIL2 ; Jump if not present
if @OEM_DEBUG
	 lea	 dx,YGROUP:MSG_SHDROM3 ; Assume not same copy
endif				; IF @OEM_DEBUG
	 jne	 near ptr CHECK_UNROM_EXIT ; Jump if present and unequal (note CF=0)

; We have a shadowed video ROM.  If this is a Zenith, the copy at E000
; is not visible to MAX because the 55AA signature is wiped out.  If this
; is the case, we have to force a 32KB ROM at E000, because MAX won't.
; Note: We have to do this even if the SHADOWROM keyword is present

	 test	 SYS_FLAG,@SYS_ZDS ; Izit a Zenith?
	 jz	 short CHECK_UNROM_ZDSROM ; Jump if not

	 REGSAVE <ax,cx,di,es>	; Save registers

; Calculate size of the E000 ROM (greater of C000 size and 32KB)

	 mov	 ax,0C000h	; Address the primary video ROM
	 mov	 es,ax		; ... via ES
	 assume  es:RGROUP	; Tell the assembler about it

	 movzx	 cx,ROMLEN	; Get ROM length in 512-bytes

	 cmp	 cx,((0E800h-0E000h) shr (9-4)) ; Compare to 32 KB
	 ja	 short @F	; Jump if C000 ROM is greater than 32 KB

	 mov	 cx,((0E800h-0E000h) shr (9-4)) ; Use 32 KB as E000 ROM length
@@:
	 dec	 cx		; Minus initial ROM marker

; Address the MEM_MAP table to blast in the E000 ROM

	 mov	 ax,seg PGROUP	; Address the MEM_MAP table
	 mov	 es,ax		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MEM_MAP[0E000h shr (9-4)] ; Address E000 portion of table

	 cmp	 PGROUP:[di].LO,@XLAT_ROM0 ; Is it a user specified ROM?
	 je	 short @F	; Jump if so

	 mov	 al,@XLAT_ROM1	; Initial ROM marker
S16	 stos	 <MEM_MAP[di]>	; Force an initial ROM marker at E000

	 mov	 al,@XLAT_ROM2	; Get subsequent ROM marker

     rep stos	 MEM_MAP[di]	; Force subsequent ROM markers up to E800
@@:
	 REGREST <es,di,cx,ax>	; Restore registers
	 assume es:RGROUP	; tell the assembler about it

CHECK_UNROM_ZDSROM:

; We have two video ROMs. Save address of alternate ROM for later
; relocation during FLEXROM_RESET.

	 mov	 VGA_ALTSEG1,di ; Save as alternate video ROM
	 mov	 VGA_ALTSEG2,ax ; ...

	 cmp	 ax,0C000h	; Is ROM at C000?
	 jne	 short @F	; Jump if not

	 or	 FLEXROM_FLAG,@FR_VID_C000 ; Indicate video ROM at C000
@@:

	 cmp	 di,0C000h	; Is ROM at C000?
	 jne	 short @F	; Jump if not

	 or	 FLEXROM_FLAG,@FR_VID_C000 ; Indicate video ROM at C000
@@:

	 or	 FLEXROM_FLAG,@FR_SHDROM ; Indicate shadowed ROMs present

; If we're requested to leave the ROM alone, do so
; (now that we've already recorded the fact that there are two video ROMs)

if @OEM_DEBUG
	 lea	 dx,YGROUP:MSG_SHDROM4 ; No error message from here on
endif				; IF @OEM_DEBUG
	 test	 CM3_FLAG,@CM3_ROMSH ; Izit to be left alone?
	 stc			; In case it is
	 jnz	 near ptr CHECK_UNROM_EXIT ; Jump if so (note CF=1)

; Ensure that VGASWAP is turned on

	 test	 FLEXROM_FLAG,@FR_VGA ; Is VGASWAP active?
	 jnz	 short CHECK_UNROM_VGASWAP ; Jump if so

; Set up segment registers for pseudo-profile parsing

	 mov	 di,seg XGROUP	; Gain addressability to XGROUP
	 mov	 es,di		; ... via ES
	 mov	 fs,di		; ... via FS
	 assume  es:XGROUP,fs:XGROUP ; Tell the assembler about it

; Simulate VGASWAP profile keyword

	 REGSAVE <si,ds>	; Save registers

	 mov	 ax,VGA_ALTSEG1 ; Get source shadowed ROM (above C000)
	 lea	 di,UNROM_TXTSRC ; FCN_VGASWAP parameter string
	 call	 FDW2HEX	; Format AX => ES:DI

	 mov	 ax,VGA_ALTSEG2 ; Get destination shadowed ROM (prob C000)
	 lea	 di,UNROM_TXTDST ; FCN_VGASWAP parameter string
	 call	 FDW2HEX	; Format AX => ES:DI

	 push	 seg PGROUP	; Gain addressability to PGROUP
	 pop	 es		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 seg XGROUP	; Gain addressability to XGROUP
	 pop	 ds		; ... via DS
	 assume  ds:XGROUP	; Tell the assembler about it

	 lea	 si,UNROM_TEXT	; FCN_VGASWAP parameter string

	 CPD	 'Calling FCN_VGASWAP,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 FCN_VGASWAP	; We need VGASWAP in effect

	 REGREST <ds,si>	; Restore registers
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 short CHECK_UNROM_AVAIL2 ; Join common code

CHECK_UNROM_VGASWAP:
	 or	 FLEXROM_FLAG,@FR_SHDVGA ; Indicate VGASWAP and
				; two shadowed ROMS are present
	 jmp	 short CHECK_UNROM_AVAIL2 ; Join common ocde

CHECK_UNROM_AVAIL:
	 test	 SYS_FLAG,@SYS_ZDS ; Izit a Zenith?
	 jz	 short CHECK_UNROM_AVAIL2 ; Jump if not

	 mov	 ax,0C000h	; Video ROM might be here
	 mov	 di,0E000h	; There won't be a BIOS signature here
				; on some Zenith machines

	 jmp	 near ptr CHECK_UNROMIT2 ; One more try at unshadowing it

CHECK_UNROM_AVAIL2:
	 or	 NRD_FLAG,@NRD_UE000 ; Mark E000 as available for use

	 clc			; Indicate no error
CHECK_UNROM_EXIT:
if @OEM_DEBUG
	 pushf			; Save flags

	 test	 DB2_FLAG,@DB2_SROM ; Display debug info?
	 jz	 short @F	; Jump if not

	 push	 dx		; Pass address as argument
	 call	 YMSGOUT2	; Display YGROUP message
@@:
	 popf			; Restore
endif				; IF @OEM_DEBUG

	 REGREST <fs,es,di,dx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_UNROM endp		; End CHECK_UNROM procedure
if @OEM_FLEXROM
	 NPPROC  FLEXROM_RESET -- Find a ROM's resources
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find all the Resources for a particular ROM.
Actual Resource Relocation will be done later (in PM).

On entry:

DI	 =	 ROM source segment
DX	 =	 ROM destin segment
CX	 =	 Length of ROM in bytes

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers
	 REGSAVE <es,fs,gs>	; Save segment registers

	 mov	 bp,cx		; Save ROM length

	 push	 seg INTVEC	; Address segment 0
	 pop	 es		; Address it
	 assume  es:INTVEC	; Tell the assembler about it

	 push	 seg XGROUP	; Get the segment
	 pop	 gs		; Address it
	 assume  gs:XGROUP	; Tell the assembler about it

	 mov	 cx,NFLEXROMINTS	; CX = # interrupt vectors to check
	 xor	 si,si		; Initialize index into FLEXROMINTS

FLEXROM_RESET_NEXT1:

; See if this FLEXROMINTS entry is pointing into our ROM (source)

	 cmp	 FLEXROMINTS.FLEXROMINT_SRC[si],di ; Does it match our ROM source?
	 je	 short @F		; Jump if so

	 test	 FLEXROMINTS.FLEXROMINT_FLAG[si],@ROMINT_VGA ; Izit a video entry?
	 jz	 near ptr FLEXROM_RESET_LOOP1 ; No, Try next entry

	 cmp	 di,VGA_ALTSEG1 	; Is segment part of shadowed VGA ROM?
	 je	 short @F		; Jump if so

	 cmp	 di,VGA_ALTSEG2 	; Is segment part of shadowed VGA ROM?
	 jne	 near ptr FLEXROM_RESET_LOOP1 ; No, Try next entry

; Ensure that the FLEXROMINTS entry is valid

@@:
	 cmp	 FLEXROMINTS.FLEXROMINT_SRC[si],@FLEX_UNUSED ; Unused entry?
	 je	 near ptr FLEXROM_RESET_LOOP1 ; Yes, skip it

; Save address of pointer (somewhere in the IDT)

	 mov	 bx,FLEXROMINTS.FLEXROMINT_NUM[si] ; Get interrupt # times 4
	 mov	 CPQINT01_SAVE.VOFF,bx ; Save as offset of ptr to ptr
	 mov	 CPQINT01_SAVE.VSEG,seg INTVEC ; ... segment ...
FLEXROM_RESET_AGAIN:
	 lfs	 bx,CPQINT01_SAVE ; FS:BX ==> saved interrupt vector
	 assume  fs:nothing	; Tell the assembler about it

; Save value of pointer

	 mov	 FLEXROMINTS.FLEXROMINT_VEC.VOFF[si],bx ; Save for later use
	 mov	 FLEXROMINTS.FLEXROMINT_VEC.VSEG[si],fs

; Point to beginning of interrupt handler

	 lfs	 bx,fs:[bx]	; FS:BX ==> code in ROM
	 assume  fs:nothing	; Tell the assembler about it

; Save address of interrupt routine

	 mov	 OLDINTHW_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINTHW_VEC.VSEG,fs

	 mov	 ax,fs		; Copy the segment

; Analyze the location that FLEXROMINT is pointing to
; If the vector is already pointing into the ROM source,
; then all we have to do is mark it as being relocatable

	 cmp	 ax,di		; Izit in relocated region?
	 je	 near ptr FLEXROM_RESET_RELOC ; Yes, mark as relocatable

	 test	 FLEXROMINTS.FLEXROMINT_FLAG[si],@ROMINT_VGA ; Izit a video entry?
	 jz	 near ptr @F	 ; No, we'll have to find its BIOS entry point

	 cmp	 ax,VGA_ALTSEG1 	; Is segment part of shadowed VGA ROM?
	 je	 short FLEXROM_RESET_RELOC ; Jump if so

	 cmp	 ax,VGA_ALTSEG2 	; Is segment part of shadowed VGA ROM?
	 je	 near ptr FLEXROM_RESET_RELOC ; Yes, Mark it as relocatable

@@:

; N.B. We check for the interrupt pointing into F000 after we check for
;      VGA_ALTSEG in case the alternate video segment is F000
;      (like in some Grids and COMPAQs).

	 cmp	 ax,0F000h	; Is vector pointing to system BIOS?
	 je	 near ptr FLEXROM_RESET_LOOP1 ; Yes, leave it alone

	 test	 FLEXROMINTS.FLEXROMINT_FLAG[si],@ROMINT_CODE ; Izit code?
	 jz	 short @F	; Jump if not (resource must point to data)

	 cmp	 fs:[bx].LO,@OPCOD_IRET ; Izit an IRET?
	 je	 short FLEXROM_RESET_LOOP1 ; Yes
@@:

	 call	 FLEXROMINTS.FLEXROMINT_FIND[si] ; Take appropriate action
	 jc	 near ptr FLEXROM_RESET_ERR ; Jump if we failed

; Analyze BIOS entry point to determine if the resource has to be relocated

	 lfs	 bx,CPQINT01_SAVE ; FS:BX ==> saved interrupt vector
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 ax,fs:[bx].VSEG ; Get the segment

	 cmp	 ax,dx		; Izit pointing to destination BIOS?
	 jne	 short FLEXROM_RESET_XVID ; Jump if not

	 lfs	 bx,fs:[bx]	; FS:BX ==> code in ROM
	 assume  fs:nothing	; Tell the assembler about it

	 jmp	 FLEXROM_RESET_AGAIN ; Go around again

FLEXROM_RESET_XVID:

	 cmp	 ax,0F000h	; Izit pointing to system BIOS?
	 je	 short FLEXROM_RESET_LOOP1 ; Yes, leave it alone

	 cmp	 ax,di		; Izit in relocated region?
	 je	 @F		; Jump if so

	 cmp	 ax,VGA_ALTSEG1 ; Izit in the Alternate video segment?
	 je	 @F		; Jump if so

	 cmp	 ax,VGA_ALTSEG2 ; Izit in the other Alternate video segment?
	 jne	 near ptr FLEXROM_RESET_ERR ; Jump if not
@@:

	 mov	 FLEXROMINTS.FLEXROMINT_VEC.VOFF[si],bx ; Save the address for later use
	 mov	 FLEXROMINTS.FLEXROMINT_VEC.VSEG[si],fs

FLEXROM_RESET_RELOC:

; Verify that the interrupt rouitne is within the length of the ROM
; that we are FLEXing.	This will trap the COMAPQ case where both the
; video BIOS and the system BIOS are at F000.  In this case we wouldn't
; want to relocate any resources that are pointing into the upper half
; of F000 (into the system BIOS).

	 REGSAVE <di,fs>	; Save temporary registers

	 lfs	 di,FLEXROMINTS.FLEXROMINT_VEC[si] ; FS:DI ==> address of vector
	 assume  fs:nothing	; Tell the assembler about it

	 cmp	 fs:[di].VSEG,0F000h ; Is vector pointing into F000?
	 jne	 short FR_VIDEO ; Jump if not (OK to relocate)

	 cmp	 fs:[di].VOFF,bp ; Is interrupt routine above video ROM?
	 jae	 short FR_SYSTEM ; Jump if so (don't relocate)
FR_VIDEO:

; Mark resource as needing relocation

	 or	 FLEXROMINTS.FLEXROMINT_FLAG[si],@ROMINT_RELOC ; Mark it

FR_SYSTEM:
	 REGREST <fs,di>	; Restore temporary registers
	 assume  fs:nothing	; Tell the assembler about it

FLEXROM_RESET_LOOP1:
	 add	 si,size FLEXROMINT_STR ; Skip to next entry

;;;;;;;; loop	 FLEXROM_RESET_NEXT1 ; Jump if more interrupts to check
	 dec	 cx		; Account for one round
	 jnz	 near ptr FLEXROM_RESET_NEXT1 ; Jump if more interrupts to check

FLEXROM_RESET_CLC:
	 clc			; Indicate all went well

	 jmp	 short FLEXROM_RESET_EXIT ; Join common exit code

FLEXROM_RESET_ERR:
if @OEM_DEBUG
	 test	 DB2_FLAG,@DB2_SROM ; Display debug info?
	 jz	 short FLEXROM_RESET_ERR1 ; Jump if not

	 push	 seg PGROUP	; Get the segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 ax,FLEXROMINTS.FLEXROMINT_NUM[si] ; Get interrupt # times 4
	 lea	 si,YGROUP:MSG_ERRSROM1 ; YGROUP:SI ==> error code save area
	 call	 FMT_ERR_CODE	; Format the error code

	 push	 offset YGROUP:MSG_ERRSROM ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message
FLEXROM_RESET_ERR1:
endif				; IF @OEM_DEBUG
	 stc			; Indicate something went wrong
FLEXROM_RESET_EXIT:
	 REGREST <gs,fs,es>	; Restore
	 assume  es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FLEXROM_RESET endp		; End FLEXROM_RESET procedure
endif				; IF @OEM_FLEXROM
	 NPPROC  ROM2OVR -- Mark ROM As Type AL Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark ROM at DI:0 as type AL memory.

On entry:

AL	 =	 @XLAT_xxx memory type
CX	 =	 # 512-byte entries to mark
DI	 =	 Offset into MEM_MAP in 512-bytes

|

	 REGSAVE <ax,cx,di,es>	; Save registers

; Remove ROM at DI:0 from MEM_MAP

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MEM_MAP[di] ; ES:DI ==> segment DI in MEM_MAP
ROM2OVR_NEXT:
	 mov	 ah,PGROUP:[di] ; Get the value

	 cmp	 ah,@XLAT_ROM0	; Izit a ROM?
	 je	 short ROM2OVR_REPL ; Yes, replace it

	 cmp	 ah,@XLAT_ROM1	; Izit a ROM?
	 je	 short ROM2OVR_REPL ; Yes, replace it

	 cmp	 ah,@XLAT_ROM2	; Izit a ROM?
	 je	 short ROM2OVR_REPL ; Yes, replace it

	 cmp	 ah,@XLAT_OTH	; Izit RAM?
	 je	 short ROM2OVR_REPL ; Yes, replace it

	 cmp	 ah,@XLAT_UNK	; Izit unknown?
	 je	 short ROM2OVR_REPL ; Yes, replace it

	 inc	 di		; Skip over it

	 jmp	 short ROM2OVR_LOOP ; Join common code

ROM2OVR_REPL:
S16	 stos	 PGROUP:[di].LO ; Mark it as high DOS memory
ROM2OVR_LOOP:
	 loop	 ROM2OVR_NEXT	; Jump if more entries to fill

	 REGREST <es,di,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROM2OVR  endp			; End ROM2OVR procedure
	 NPPROC  CHECK_SHDROM -- Check On Shadowed Video ROM
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See whether or not the video ROM at AX:2 is shadowed at DI:2

The video ROM is said to be shadowed if (ROMLEN - @FLEX_MISMATCH)
bytes are the same.  This will take into account machines
like the NEC SX that have similar BIOSes (but not exact
duplicate BIOSes).

On entry:

AX:0	 ==>	 Address of alleged shadowed video ROM
DI:0	 ==>	 Address of alleged shadowed video ROM

On exit:

CF	 =	 1 if not present
	 =	 0 otherwise
ZF	 =	 1 if ROM at C000 is shadowed at DI:0
	 =	 0 if no video ROM at C000, or not shadowed

|

@FLEX_MISMATCH	 equ	 100	; Number of allowed mismatches


	 REGSAVE <ax,bx,cx,si,di,ds,es> ; Save registers

	 mov	 es,ax		; Get video ROM segment
	 assume  es:RGROUP	; Tell the assembler about it

	 mov	 ds,di		; Get shadowed ROM segment
	 assume  ds:nothing	; Tell the assembler about it

	 movzx	 cx,ROMLEN	; Get ROM lenggth in 512-bytes
	 shl	 cx,(9-0)	; Convert from 512-bytes to bytes
	 lea	 di,ROMSIGN	; ES:DI ==> ROM at C000

	 xor	 bx,bx		; Zero the match counter
	 mov	 si,di		; DS:SI ==> ROM at E000

	 REGSAVE <cx>		; Save BIOS length

CHK_SHDROM_NEXT:
	 cmps	 ds:[si].LO,RGROUP:[di].LO ; Compare 'em
	 jnz	 short @F	; Jump if not the same

	 inc	 bx		; Count in one more match
@@:

	 loop	 CHK_SHDROM_NEXT ; Check next byte

; Check for minimum number of matches to indicate a duplicate BIOS

	 REGREST <cx>		; Restore BIOS length

; We previously added @FLEX_MISMATCH to the match count, and compared that
; number to the byte count of the BIOS.  The Zenith Mastersport SL laptop
; has a 13,225 byte match count (out of a 24KB BIOS).  Instead of allowing
; a 100 byte mismatch count, we now only look for a 50% (of original count)
; match count to determine that the BIOSes are similar.  This is done by
; dividing the byte count by two instead of multiplying the match count
; by 2 (this prevents BX*2 from overflowing if the match count > 32KB).

; Actually, the above change to allow 50% hit rate is a bad idea.  The
; Zenith Mastersport SL has such a low hit rate because the ROMs are
; offset from each other about halfway through.  Better yet, let's go
; back to the @FLEX_MISMATCH idea and recognize the Zenith Mastersport SL
; as a special case.

	 call	 IZIT_ZMSPORT	; Izit a Zenith MasterSport 386SL?
	 je	 short CHECK_SHDROM_MATCH ; Jump if so

	 add	 bx,@FLEX_MISMATCH ; Add alottment of mismatches

	 cmp	 bx,cx		; Compare our match counter with BIOS length
	 jb	 short @F	; Jump if not enough matches
CHECK_SHDROM_MATCH:
	 cmp	 cx,cx		; Set ZF (indicate BIOS match)
	 jmp	 short CHECK_SHDROM_CLC ; Join common exit code

@@:
	 sub	 cx,1		; Clear zero flag (indicate no BIOS match)

CHECK_SHDROM_CLC:
	 clc			; Mark as present

CHECK_SHDROM_EXIT:
	 REGREST <es,ds,di,si,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SHDROM endp		; End CHECK_SHDROM procedure
	 NPPROC  IZIT_ZMSPORT -- Check On Zenith MasterSport 386SL
	 assume  ds:nothing,es:RGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on Zenith MasterSport 386SL

Check for a signature in the ROM at E000.

On exit:

ZF	 =	 1 if it's a match
	 =	 0 otherwise

|

	 REGSAVE <cx,si,di>	; Save registers

	 lea	 si,LCL_ZMSPORT ; CS:SI ==> local copy of signature
	 xor	 di,di		; ES:DI ==> ROM ...
	 mov	 cx,LCL_ZMSPORT_LEN ; # bytes in signature
    repe cmps	 LCL_ZMSPORT[si],RGROUP:[di].LO ; Check for a match
				; Return with ZF significant
	 REGREST <di,si,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_ZMSPORT endp		; End IZIT_ZMSPORT procedure
	 FPPROC  CHECK_PRVEXT -- Check on Preceding Extended Memory Usage
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on preceding extended memory usage.

|

	 REGSAVE <eax,ecx,si,ebp> ; Save registers

; Setup source address for move

	 mov	 eax,CON1MB	; Read starting at 1MB
	 mov	 ecx,size VDISK_STR ; # bytes to read

	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM1,cl ; Save size & flags
	 ror	 ecx,16 	; Swap back
	 mov	 MOVE_TAB.MDTE_DS.DESC_ACCESS,CPL0_DATA

; Setup destination address for move

	 sub	 sp,size VDISK_STR ; Make room on the stack
	 movzx	 ebp,sp 	; Address it

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,ss		; Copy current segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,ebp	; Plus stack offset to get destination

	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM1,cl ; Save size & flags
	 ror	 ecx,16 	; Swap back
	 mov	 MOVE_TAB.MDTE_ES.DESC_ACCESS,CPL0_DATA

; Move the data to the local stack

	 lea	 si,MOVE_TAB	; ES:SI ==> block move descriptor tables
	 shr	 cx,1		; Convert from bytes to words

	 REGSAVE <fs,gs>	; Save for a moment
	 mov	 ah,87h 	; Function code to move extended memory
	 int	 15h		; Request BIOS service
	 REGREST <gs,fs>	; Restore
	 jc	 short CHECK_PRVEXT_ERR ; Jump if error

	 cmp	 ah,00h 	; Ensure it worked
	 jne	 short CHECK_PRVEXT_ERR ; Jump if error

	 cmp	 [bp].VDISK_VEND.EDD,'SIDV' ; Check for signature
	 jne	 short CHECK_PRVEXT_EXIT ; No signature

	 cmp	 [bp+4].VDISK_VEND,'K' ; Check for signature
	 jne	 short CHECK_PRVEXT_EXIT ; No signature

	 movzx	 eax,[bp].VDISK_NEXT ; Get kilobytes of usage

	 sub	 eax,1024	; Less first megabyte
	 jc	 short CHECK_PRVEXT_ERR ; Something's wrong

	 cmp	 eax,PRVSIZE	; Use the larger of the two
	 jbe	 short @F	; Jump if new size is no larger

	 mov	 PRVSIZE,eax	; Save for later use
@@:
	 jmp	 short CHECK_PRVEXT_EXIT ; Join common exit code

CHECK_PRVEXT_ERR:




CHECK_PRVEXT_EXIT:
	 add	 sp,size VDISK_STR ; Strip from stack

	 REGREST <ebp,si,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PRVEXT endp		; End CHECK_PRVEXT procedure
	 FPPROC  CHECK_QEXT -- Check On QEXT.SYS
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If old-style QEXT.SYS is already installed, set FORCEA20.
If new-style ...			  , note that fact for later use.

|

	 REGSAVE <ax,bx,dx,ds,es> ; Save registers

	 push	 ds		; Get PGROUP segment
	 pop	 es		; Set for data references
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 seg XGROUP	; Get segment of QEXTXXX0
	 pop	 ds		; Address for @OPENF2
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 al,@OPEN_R	; Function code for read-only access
	 DOSCALL @OPENF2,QEXTXXX0 ; Attempt to open the file
	 jc	 short CHECK_QEXT_EXIT ; Jump if not present

	 mov	 bx,ax		; Copy to handle register
	 mov	 al,0		; Function code to get device information
	 DOSCALL @IOCTL2	; Get device info into DX

	 pushf			; Save CF from DOSCALL @IOCTL2
	 DOSCALL @CLOSF2	; Close the file
	 popf			; Restore
	 jc	 short CHECK_QEXT_EXIT ; Jump if error from DOSCALL @IOCTL2

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short CHECK_QEXT_EXIT ; Jump if not

; Now separate old- and new-style QEXTs

; The old-style QEXT.SYS uses the 8042 to toggle the A20 gate.
; If we don't set FORCEA20, we'll crash and burn when it disables A20,
; which is why we must set FORCEA20.

	 mov	 ax,11DEh	; Special function call for old-style QEXT.SYS
	 stc			; Assume not present
	 int	 15h		; Request BIOS service
	 jc	 short CHECK_QEXT_NEW ; Not this time

	 or	 CM3_FLAG,@CM3_XA20 ; Set FORCEA20 on

; The new QEXT might also respond to the 11DEh call.
; If the segment returned by this call is the same as that
; of the old XMS driver, then we have found the new QEXT.

	 test	 XMS_FLAG,mask $XMS_OLD ; Is there an old XMS driver?
	 jz	 short CHECK_QEXT_EXIT ; Jump if not

	 cmp	 ax,OLDXMS_VEC.VSEG ; Are they one and the same?
	 jne	 short CHECK_QEXT_EXIT ; Jump if not
CHECK_QEXT_NEW:
	 or	 LCL_FLAG,@LCL_QEXT ; Mark as new-style present

; If there's a previous 64KB VDISK, clear it as we no longer honor it

	 cmp	 PRVSIZE,64	; Is there a VDISK signature?
	 jne	 short CHECK_QEXT_EXIT ; Jump if not

	 mov	 PRVSIZE,0	; Mark as no more
CHECK_QEXT_EXIT:
	 REGREST <es,ds,dx,bx,ax> ; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_QEXT endp 		; End CHECK_QEXT procedure
	 NPPROC  SRCH_PPMTAB -- Search Through PPMTAB
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search the next 128/16 entries in PPMTAB for mask $PPM_SHD
If found, clear the corresponding bit in AH;
otherwise leave it alone.

If we're on an 82C212 system, complement the bits on the way in
as well as the way out.

On entry:

AH	 =	 AT386 or NEAT register
EDX	 =	 base of next 16KB block in bytes
DS:SI	 ==>	 next entry in PPMTAB

On exit:

AH	 =	 AT386 or NEAT register (updated)
EDX	 =	 base of next 16KB block in bytes (updated)
DS:SI	 ==>	 next entry in PPMTAB (updated)

|

	 REGSAVE <cx>		; Save register

	 mov	 cx,128/16	; # 16KB entries in 128KB block

	 cmp	 CT_ROMCFG,65h	; Izit 82C212?
	 jne	 short SRCH_PPMTAB_NEXT ; Not this time

	 not	 ah		; Complement to 82C302 format
SRCH_PPMTAB_NEXT:
	 lodsb			; Get next PPMTAB marker

	 test	 al,mask $PPM_SHD ; Available for use as shadow RAM?
	 jz	 short SRCH_PPMTAB_LOOP ; Not this time

	 and	 ah,not 1	; Clear the bit

	 push	 16		; Amount of shadow RAM in 1KB
	 push	 edx		; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 cmp	 al,(mask $PPM_SHD) or @PPM_ROM ; Izit ROM?
	 je	 short SRCH_PPMTAB_LOOP ; Yes, don't scrub it

	 push	 16		; Amount of shadow RAM in 1KB
	 push	 edx		; ...at this location
	 call	 SAVE_SCRUB	; Append to scrub RAM structure
SRCH_PPMTAB_LOOP:
	 ror	 ah,1		; Rotate the bit around

	 add	 edx,CON16KB	; Skip to next 16KB base

	 loop	 SRCH_PPMTAB_NEXT ; Jump if more entries

	 cmp	 CT_ROMCFG,65h	; Izit 82C212?
	 jne	 short @F	; Not this time

	 not	 ah		; Complement to 82C302 format
@@:
	 REGREST <cx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH_PPMTAB endp		; End SRCH_PPMTAB procedure
	 FPPROC  CHECK_SHADOW -- Check On Shadow RAM
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on shadow RAM such as on a COMPAQ DP 386 and HP Vectra RS/20.
If present, unlink it from its current use and link it into our
page tables.

|

	 REGSAVE <eax,cx,edx,si,di,es> ; Save registers

	 test	 CM2_FLAG,@CM2_X384 ; Skip shadow RAM fill?
	 jnz	 near ptr CHECK_SHADOW_EXIT ; Yes

	 test	 SYS_FLAG,@SYS_CPQ ; Izit a COMPAQ Deskpro 386/486?
	 jnz	 near ptr CHECK_SHADOW_CPQ ; Jump if so

	 test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
	 jz	 near ptr CHECK_SHADOW1 ; Not this time

; If either NOROM or ROM= are specified, skip using shadow RAM

	 test	 CMD_FLAG,@CMD_XRM ; NOROM specifed?
	 jnz	 near ptr CHECK_SHADOW_EXIT ; Yes, ignore shadow RAM

	 test	 CM2_FLAG,@CM2_ROM ; ROM= specifed?
	 jnz	 near ptr CHECK_SHADOW_EXIT ; Yes, ignore shadow RAM

;;;;;;;; mov	 DMA_MAX,@DMA_PA_SHD ; Mark as maximum DMA physical address

	 pushf			; Save flags
	 cli			; Nobody move

	 mov	 ah,AT386_CFG[0] ; Get old register value
	 and	 ah,not (@BIT7 or @BIT6 or @BIT5) ; Enable read-write access
	 and	 ah,not (@BIT3 or @BIT2 or @BIT1) ; Disable ROM substitution

; If we're on an 82C212, set the bits we just cleared

	 cmp	 CT_ROMCFG,65h	; Izit 82C212?
	 jne	 short @F	; Not this time

	 or	 ah,@BIT3 or @BIT2 or @BIT1 ; Disable ROM substitution
@@:
	 mov	 AT386_CFG[1],ah ; Save new register value

	 lea	 si,PPMTAB[0A000h shr (14-4)] ; DS:SI ==> A000 in PPMTAB
	 mov	 edx,000A0000h	; Start of tested memory

; Check A000-C000 (register 0Dh or 67h)
; If we're using 82C212, exchange the nibbles in AL (thanks C&T)

	 mov	 al,AT386_RAB[0] ; Get old register value
	 call	 SWAP_CTAL	; Swap nibbles in AL if 82C212
	 mov	 ah,al		; Copy to common register
	 call	 SRCH_PPMTAB	; Search the next 128/16 entries in PPMTAB

; If we're using 82C212, exchange the nibbles in AL (thanks C&T)

	 mov	 al,ah		; Copy to common register
	 call	 SWAP_CTAL	; Swap nibbles in AL if 82C212
	 mov	 AT386_RAB[1],al ; Save new register value

; Check C000-E000 (register 0Eh or 68h)

	 mov	 ah,AT386_RCD[0] ; Get old register value
	 call	 SRCH_PPMTAB	; Search the next 128/16 entries in PPMTAB
	 mov	 AT386_RCD[1],ah ; Save new register value

; Check E000-10000 (register 0Fh or 69h)

	 mov	 ah,AT386_REF[0] ; Get old register value
	 call	 SRCH_PPMTAB	; Search the next 128/16 entries in PPMTAB
	 mov	 AT386_REF[1],ah ; Save new register value

	 popf			; Restore

	 jmp	 CHECK_SHADOW_COM ; Join common code

CHECK_SHADOW1:
	 test	 CM2_FLAG,@CM2_TOP ; Izit generic top 384KB of RAM?
	 jz	 short CHECK_SHADOW2 ; Not this time

	 push	 256		; Amount of shadow RAM in 1KB
	 push	 dword ptr 00FA0000h ; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 test	 NRD_FLAG,@NRD_UE000 ; Is E000 available?
	 jz	 near ptr CHECK_SHADOW_COM ; Jump if not

; Add in the 128KB gained from disabling the ROM mapping

	 push	 128		; Amount of shadow RAM in 1KB
	 push	 dword ptr 00FE0000h ; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 or	 I15_FLAG,@I15_ROM ; Mark as ROM disabled

	 jmp	 short CHECK_SHADOW_COM ; Join common code

CHECK_SHADOW2:
	 test	 SYS_FLAG,@SYS_AST386 ; Izit an AST Premium/386?
	 jz	 short CHECK_SHADOW3 ; No

	 push	 256		; Amount of shadow RAM in 1KB
	 push	 dword ptr 00FA0000h ; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

;;;;;;;; push	 256		; Amount of shadow RAM in 1KB
;;;;;;;; push	 dword ptr 00FA0000h ; ...at this location
;;;;;;;; call	 SAVE_SCRUB	; Append to scrub RAM structure

	 test	 NRD_FLAG,@NRD_UE000 ; Is E000 available?
	 jz	 short CHECK_SHADOW_COM ; Jump if not

; Add in the 128KB gained from disabling the ROM mapping

	 push	 128		; Amount of shadow RAM in 1KB
	 push	 dword ptr 00FE0000h ; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

;;;;;;;; push	 128		; Amount of shadow RAM in 1KB
;;;;;;;; push	 dword ptr 00FE0000h ; ...at this location
;;;;;;;; call	 SAVE_SCRUB	; Append to scrub RAM structure

	 or	 I15_FLAG,@I15_ROM ; Mark as ROM disabled

	 jmp	 short CHECK_SHADOW_COM ; Join common code

CHECK_SHADOW3:
CHECK_SHADOW_COM:
	 jmp	 short CHECK_SHADOW_EXIT ; Join common exit code

CHECK_SHADOW_CPQ:

; Set next entry in SHD_STR to contain all available COMPAQ shadow RAM

	 test	 I15_FLAG,@I15_CPQ ; Izit a COMPAQ TOP384 scheme?
	 jz	 short CHECK_SHADOW_EXIT ; No extra memory available

	 mov	 ax,seg CGROUP	; Address the system BIOS
	 mov	 es,ax		; ... via ES
	 assume  es:CGROUP	; Tell the assembler about it

	 mov	 si,LOFFCPQSTR	; Get original value

	 cmp	 CGROUP:[si].CPQSTR_FLAG,0FFFFh ; Check the presence flag
	 je	 short CHECK_SHD_CPQ386_ROM ; No extra memory available

	 mov	 cx,CGROUP:[si].CPQSTR_AVL ; Get size of available region
	 movzx	 eax,CGROUP:[si].CPQSTR_LOW ; Get low address
	 sub	 ax,cx		; Less size to get starting address
	 shr	 cx,10-4	; Convert from paras to 1KB
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,15*1024*1024 ; Plus 15MB to get physical address

	 push	 cx		; Amount of shadow RAM in 1KB
	 push	 eax		; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 or	 NRD_FLAG,@NRD_CPQBIM ; Mark as recovering BIM memory
	 call	 CPQZAPSTR	; Zap the BIM presence flag

; Enable the cache for this memory (if present on this machine)

; Read machine ID from CMOS byte 24h

	 mov	 ah,24h 	; Get this byte
	 call	 READ_CMOS	; Return with AL = current value

;;;;;;;; cmp	 al,37h 	; Izit 386/33 ?
;;;;;;;; je	 short CHECK_CPQ386_33MHZ ; Jump if so
;;;;;;;;
	 cmp	 al,39h 	; Izit 386/25e ?
	 je	 short @F	; Jump if so

	 cmp	 al,3Ah 	; Izit 386/20e (second revision)?
	 jne	 short CHECK_SHD_CPQ386_ROM ; Jump if not
@@:
	 mov	 dx,0C67h	; Special I/O port

	 in	 al,dx		; Read current value
	 jmp	 short $+2	; I/O delay

	 or	 al,@BIT5	; Set the cache 12-16MB bit
	 out	 dx,al		; Send back

;;;;;;;; jmp	 short CHECK_CPQ386_ROM ; Join common code
;;;
;;;CHECK_CPQ386_33MHZ:
;;;	    mov     esi,00FA0000h  ; Address to be made cacheable
;;;	    mov     ah,@CPQCACHE   ; COMPAQ cache controller function code
;;;	    mov     al,03h	   ; Subfunction to read cache map
;;;	    int     16h 	   ; Request cache services
;;;				   ; Return with
;;;				   ; AX = E203 if supported
;;;				   ; BX = granularity in bytes (0 if not supported)
;;;				   ; CX = # blocks with property in DX
;;;				   ; DX = 0000 if cached, 00FF if not
;;;				   ; EDI = address of next block
;;;
;;;	    cmp     ax,0E203h	   ; Check for proper return code
;;;	    jne     short CHECK_CPQ386_ROM ; Jump if not
;;;
;;;	    cmp     bx,0	   ; Izit supported?
;;;	    je	    short CHECK_CPQ386_ROM ; Jump if not
;;;
;;;; Mark as to be cached the blocks from 00FA0000 to 00FE0000 in units of BX bytes
;;;
;;;	    mov     esi,00FA0000h  ; Starting address to be made cacheable
;;;@@:
;;;	    mov     cx,1	   ; Mark at least one block
;;;	    mov     dx,0000h	   ; Mark as to be made cacheable
;;;	    mov     ah,@CPQCACHE   ; COMPAQ cache controller function code
;;;	    mov     al,04h	   ; Subfunction to write cache map
;;;	    int     16h 	   ; Request cache services
;;;				   ; Ignore return code
;;;	    mov     esi,edi	   ; Copy next boundary address
;;;
;;;	    cmp     esi,00FE0000h  ; At the end as yet?
;;;	    jb	    short @F	   ; Jump if not
CHECK_SHD_CPQ386_ROM:
	 push	 seg PGROUP	; Setup ES to receive structure
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 test	 NRD_FLAG,@NRD_UE000 ; Is E000 available?
	 jz	 short CHECK_SHADOW_EXIT ; Jump if not

; Add in the 128KB gained from disabling the ROM mapping

	 push	 128		; Amount of shadow RAM in 1KB
	 push	 dword ptr 00FE0000h ; ...at this location
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 or	 I15_FLAG,@I15_ROM ; Mark as ROM disabled

CHECK_SHADOW_EXIT:
	 movzx	 eax,SHDSIZE	; Get size of shadow RAM (if any)
	 add	 TOTSIZE,eax	; Add in to total size

	 REGREST <es,di,si,edx,cx,eax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SHADOW endp		; End CHECK_SHADOW procedure
	 NPPROC  SWAP_CTAL -- Swap Nibbles in AL if 82C212
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Swap the nibbles in AL if we're on 82C212

On entry:

AL	 =	 value to change

On exit:

AL	 =	 (updated)

|

	 cmp	 CT_ROMCFG,65h	; Izit 82C212?
	 jne	 short @F	; Not this time

	 rol	 al,4		; Swap 'em
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_CTAL endp			; End SWAP_CTAL procedure
;;;	     NPPROC  COMP_CTAL -- Complement Bits in AL if 82C212
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Complement the bits in AL if we're on 82C212
;;;
;;; On entry:
;;;
;;; AL	     =	     value to change
;;;
;;; On exit:
;;;
;;; AL	     =	     (updated)
;;;
;;; |
;;;
;;;	     cmp     CT_ROMCFG,65h  ; Izit 82C212?
;;;	     jne     short @F	    ; Not this time
;;;
;;;	     not     al 	    ; Complement 'em
;;; @@:
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; COMP_CTAL endp		    ; End COMP_CTAL procedure

XCODE	 ends			; End XCODE segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 public  @QMAX_SYS_NCODE
@QMAX_SYS_NCODE:		; Mark module start in .MAP file

if @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2 or @OEM_SOFT
	 FPPROC  OLI_RESET -- Disable Olivetti/AT&T Use of Shadow RAM
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable the Olivetti/AT&T system's use of shadow RAM

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx>	; Save registers

	 cli			; Disallow interrupts

	 call	 WAITOBUF_CLR	; Clear the 8042's output buffer

	 mov	 ah,0A8h	; Special function to set state
	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short OLI_RESET_XPRES ; Something went wrong

	 mov	 ah,81h 	; Code to read special register
	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short OLI_RESET_XPRES ; Something went wrong

	 mov	 ah,02h 	; Special register #2 (configuration latch)
	 call	 PPI_S2K_K2S	; Send command AH to 6805, response in AL
	 jc	 short OLI_RESET_XPRES ; Something went wrong

; Clear bit 6 in AL to disable the system's use of shadow RAM
; adn send back to the controller

	 and	 al,not @BIT6	; Clear it
	 mov	 bl,al		; Copy it

	 call	 WAITOBUF_CLR	; Clear the 8042's output buffer

	 mov	 ah,0A8h	; Special function to set state
	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short OLI_RESET_XPRES ; Something went wrong

	 mov	 ah,80h 	; Code to write special register
	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short OLI_RESET_XPRES ; Something went wrong

	 mov	 ah,02h 	; Special register #2 (configuration latch)
	 call	 PPI_S2K	; Send data AH to keyboard
	 jc	 short OLI_RESET_XPRES ; Something went wrong

	 mov	 ah,bl		; New value for configuration latch
	 call	 PPI_S2K	; Send data AH to keyboard
	 jc	 short OLI_RESET_XPRES ; Something went wrong

; Read the command byte to ensure last command accepted

	 mov	 ah,@S2C_RCMD	; Read the command byte
	 call	 PPI_S2C_K2S	; Send AH to 8042, return with AL = response
;;;;;;;; jc	 short OLI_RESET_XPRES ; Something went wrong
OLI_RESET_XPRES:
	 sti			; Allow interrupts

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OLI_RESET endp			; End OLI_RESET procedure
endif				; IF @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2 or @OEM_SOFT
	 FPPROC  INIT_CHIPSET -- Initialize CHIPset Settings
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize CHIPset AT386_Rxx and PPMTAB entries.

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
	 jz	 near ptr INIT_CHIPSET_EXIT ; Not this time

	 pushf			; Save flags
	 cli			; Nobody move

	 mov	 al,CT_ROMCFG	; Register #
	 call	 READ_CHIPSET	; Read data from CHIPset into AH
	 mov	 AT386_CFG[0],ah ; Save old register value
	 mov	 AT386_CFG[1],ah ; Save old register value

; Check A000-C000 (register 0Dh or 67h)

	 mov	 al,CT_RAM_AB	; Register #
	 call	 READ_CHIPSET	; Read data from CHIPset into AH
	 mov	 AT386_RAB[0],ah ; Save old register value
	 mov	 AT386_RAB[1],ah ; Save old register value

; Check C000-E000 (register 0Eh or 68h)

	 mov	 al,CT_RAM_CD	; Register #
	 call	 READ_CHIPSET	; Read data from CHIPset into AH
	 mov	 AT386_RCD[0],ah ; Save old register value
	 mov	 AT386_RCD[1],ah ; Save old register value

; Check E000-10000 (register 0Fh or 69h)

	 mov	 al,CT_RAM_EF	; Register #
	 call	 READ_CHIPSET	; Read data from CHIPset into AH
	 mov	 AT386_REF[0],ah ; Save old register value
	 mov	 AT386_REF[1],ah ; Save old register value

	 popf			; Restore
INIT_CHIPSET_EXIT:
	 REGREST <di,si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_CHIPSET endp		; End INIT_CHIPSET procedure
	 NPPROC  YMSGOUT -- Display YGROUP Message
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display YGROUP message.

Note that this routine might be called to note that we're not
running on a 386, so we are limited to 8088 instructions.

|

YMSGOUT_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's return address
YMSGOUT_OFF dw	 ?		; Offset in YGROUP of message

YMSGOUT_STR ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,dx,ds>	; Save registers

	 mov	 ax,seg YGROUP	; Get message segment
	 mov	 ds,ax		; Address it
	 assume  ds:YGROUP	; Tell the assembler about it

	 mov	 dx,[bp].YMSGOUT_OFF ; DS:DX ==> message

	 DOSCALL @STROUT	; Display it

	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

YMSGOUT  endp			; End YMSGOUT procedure

NCODE	 ends			; End NCODE segment

	 MEND			; End QMAX_SYS module

;' $Header:   P:/PVCS/MAX/386MAX/QMAX_ARG.ASV   1.6   30 May 1997 10:44:08   BOB  $
	 title	 QMAX_ARG -- 386MAX Argument Routines
	 page	 58,122
	 name	 QMAX_ARG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment HICODE,	dword-aligned, public, class 'prog'
	       Program segment ECODE,	dword-aligned, public, class 'ecode'
	       Data    segment EDATA,	dword-aligned, public, class 'edata'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Group IGROUP:
	       Data    segment IDATA,	dword-aligned, public, class 'idata'
	       Group JGROUP:
	       Data    segment JDATA,	dword-aligned, public, class 'jcode'
	       Group XGROUP:
	       Program segment XCODE,	byte-aligned,  public, class 'xcode'
	       Data    segment XDATA,	dword-aligned, public, class 'xdata'
	       Data    segment SEG_LEN, word-aligned,  public, class 'xdata'
	       Data    segment SEG_ACT, word-aligned,  public, class 'xdata'
	       Data    segment SEG_TAB, word-aligned,  public, class 'xdata'
	       Data    segment WBPAT_SEG, word-aligned, public, class 'xdata'
	       Data    segment WBPAT_END, word-aligned, public, class 'xdata'
	       Group YGROUP:
	       Data    segment YDATA,	dword-aligned, public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include VIDCALL.INC
	 include ASCII.INC
	 include DEVDRV.INC
	 include INTVEC.INC
	 include OPEN.INC
	 include 386.INC
	 include PTR.INC
	 include ROMSEG.INC
	 include CPUFET.INC
	 include OPCODES.INC

	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_CFG.INC
	 include QMAXDPMI.INC
	 include QMAX_TRC.INC
	 include QMAX_FLX.INC
	 include QMAXWIN3.INC
	 include INTRNATL.INC
.list

CMDARG_MAC macro TXT,ACT
	 local	 LCL_TXT,LCL_LEN

XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

LCL_TXT  db	 TXT
LCL_LEN  equ	 $-LCL_TXT

XDATA	 ends			; End XDATA segment


SEG_TAB  segment use16 word public 'xdata' ; Start SEG_TAB segment
	 assume  ds:XGROUP

	 dw	 XGROUP:LCL_TXT

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use16 word public 'xdata' ; Start SEG_LEN segment
	 assume  ds:XGROUP

	 dw	 LCL_LEN

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use16 word public 'xdata' ; Start SEG_ACT segment
	 assume  cs:XGROUP

	 dd	 XGROUP:ACT

SEG_ACT  ends			; End SEG_ACT segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 extrn	 ACT:far
if @OEM_STATE
	 extrn	 FCN_AUTO:far
else
	 extrn	 FCN_ON:far
endif				; IF @OEM_STATE

XCODE	 ends			; End XCODE segment

	 endm			; CMDARG_MAC

PGROUP	 group	 CODE,HICODE,ECODE,EDATA,NDATA
if @OEM_DPMI
IGROUP	 group	 IDATA
endif				; IF @OEM_DPMI
JGROUP	 group	 JDATA
XGROUP	 group	 XCODE,XDATA,SEG_LEN,SEG_ACT,SEG_TAB,WBPAT_SEG
YGROUP	 group	 YDATA

CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

if @OEM_WIN3
	 extrn	 DEV_INTR3:far
endif				; IF @OEM_WIN3

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

	 extrn	 CM4_FLAG:word
	 include QMAX_CM4.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SYS_FLAG:dword
;;;;;;;; include QMAX_SYS.INC

if @OEM_WIN3
	 extrn	 DEVDRV:tbyte
endif				; IF @OEM_WIN3

	 extrn	 RH_VEC:dword
	 extrn	 EXTSIZE:dword
if @OEM_EMS
	 extrn	 EMMSIZE:dword
endif				; IF @OEM_EMS
	 extrn	 SWPSIZE:word

	 extrn	 VIRT_DEV_DPFE:byte

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

HICODE	 ends			; End HICODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 FKEYWAIT:far

ECODE	 ends			; End ECODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

if @OEM_DEBUG
	 include QMAX_CPD.INC
endif				; IF @OEM_DEBUG

	 extrn	 DSTK_FLAG:word
;;;;;;;; include QMAX_CFG.INC

	 extrn	 CPUFET_FLAG:dword
	 extrn	 PRVSIZE:dword
if @OEM_XMS
	 extrn	 HMASIZE:dword

	 extrn	 XMS_FLAG:word
	 include QMAX_XMS.INC
endif				; IF @OEM_XMS

if @OEM_FLEXROM
	 extrn	 FLEXROM_FLAG:word
	 extrn	 FLEXROM_LEN:word
	 extrn	 FLEXROM_TBL:tbyte
	 extrn	 VGA_ALTSEG1:word
	 extrn	 VGA_ALTSEG2:word
endif				; IF @OEM_FLEXROM

if @OEM_DPMI
	 extrn	 DPMIOLDPM_SIZ:dword
	 extrn	 DPMI_CPIHOOK:byte
	 extrn	 DPMI_CPFHOOK:byte
	 extrn	 DPMI_CVFHOOK:byte
	 extrn	 I31_FLAG:word
	 extrn	 DPMITYPE:byte
	 extrn	 LAST_DPMI_DS:word
	 extrn	 LAST_DPMI_ES:word
	 extrn	 LAST_DPMI_FS:word
	 extrn	 LAST_DPMI_GS:word
endif				; IF @OEM_DPMI

	 extrn	 DSTK_CNT:word

	 extrn	 CFGLIST:word	; List of lists of PGROUP offsets of programs
	 extrn	 @CFGLIST_LEN:abs ; Number of LLST_STR entries in CFGLIST

	 public  LaVROM_BEG,LaVROM_END
	 public  PTE_VROM_BEG,PTE_VROM_END,PTE_VROM_SRC
LaVROM_BEG dd	 000C0000h	; Starting linear address of video ROM
LaVROM_END dd	 000C8000h	; Ending ...
PTE_VROM_BEG dw  0C000h shr ((12-2)-4) ; Starting PTE offset of linear video ROM
PTE_VROM_END dw  0C800h shr ((12-2)-4) ; Ending ...
PTE_VROM_SRC dw  0C000h shr ((12-2)-4) ; Starting PTE offset of physical ...

	 public  CFG_CNT,CFG_LCNT
CFG_CNT  dw	 0		; # bytes in the file
CFG_LCNT dw	 0		; Count of # linked list entries

	 public  INVALID_OK
INVALID_OK	 db	0	; 0 = Invalid keyword is OK, 1 = Not OK

EDATA	 ends			; End EDATA segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
	 assume  ds:JGROUP

	 extrn	 NOSCAN_MAP:byte

JDATA	 ends			; End JDATA segment


if @OEM_DPMI
IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

	 extrn	 PMINT_FVECS:fword
	 extrn	 PMINT_DVECS:dword
	 extrn	 PMFLT_FVECS:fword
	 extrn	 PMFLT_DVECS:dword
	 extrn	 VMFLT_FVECS:fword
	 extrn	 VMFLT_DVECS:dword

	 extrn	 DBGCTL:byte
	 extrn	 DBGSTA:byte
	 extrn	 DBGREGS:dword
	 extrn	 DBGDR7:dword

IDATA	 ends			; End IDATA segment
endif				; IF @OEM_DPMI

SEG_TAB  segment use16 word public 'xdata' ; Start SEG_TAB segment
	 assume  ds:XGROUP

	 public  CMDARG_TAB
CMDARG_TAB label word

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use16 word public 'xdata' ; Start SEG_LEN segment
	 assume  ds:XGROUP

	 public  CMDARG_LEN
CMDARG_LEN label word

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use16 word public 'xdata' ; Start SEG_ACT segment
	 assume  ds:XGROUP

	 public  CMDARG_ACT
CMDARG_ACT label dword

SEG_ACT  ends			; End SEG_ACT segment


; All keywords in this table *MUST* be in uppercase

if @OEM_HIFILL and @OEM_SYS eq @OEMSYS_ILIM
	 CMDARG_MAC 'HIGHDOS',          FCN_HIGHDOS
endif				; IF @OEM_HIFILL and @OEM_SYS eq @OEMSYS_ILIM

if @OEM_SYS eq @OEMSYS_HPRS or @OEM_SYS eq @OEMSYS_ILIM
	 CMDARG_MAC 'REBOOT',           FCN_FORCEA20
elseif @OEM_DEBUG
	 CMDARG_MAC 'FORCEA20',         FCN_FORCEA20
if @OEM_DMA
	 CMDARG_MAC 'NODMA',            FCN_NODMA
	 CMDARG_MAC 'NOEISADMA',        FCN_NOEISADMA
	 CMDARG_MAC 'SLOWDMA',          FCN_SLOWDMA
endif				; IF @OEM_DMA
endif				; IF @OEM_SYS eq @OEMSYS_HPRS or @OEM_SYS eq @OEMSYS_ILIM

	 CMDARG_MAC '32BITDMA',         FCN_32BITDMA

if @OEM_EMS
	 CMDARG_MAC 'FRAME',            FCN_FRAME
endif				; IF @OEM_EMS
if @OEM_DMA
	 CMDARG_MAC 'DMA',              FCN_DMA
endif				; IF @OEM_DMA

if @OEM_XMS
if @OEM_SYS eq @OEMSYS_HPRS
	 CMDARG_MAC 'NUMHANDLES',       FCN_XMSHNDL
	 CMDARG_MAC 'NOHMA',            FCN_NOHMA
else
	 CMDARG_MAC 'XMSHNDL',          FCN_XMSHNDL
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
	 CMDARG_MAC 'HMAMIN',           FCN_HMAMIN
endif				; IF @OEM_XMS

if @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
	 CMDARG_MAC 'FASTRAM',          FCN_FASTRAM
endif				; IF @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT

if @OEM_EMS and @OEM_SYS ne @OEMSYS_AST386
	 CMDARG_MAC 'EXT',              FCN_EXT
endif				; IF @OEM_EMS and @OEM_SYS ne @OEMSYS_AST386

if @OEM_SYS ne @OEMSYS_ILIM
if @OEM_EMS
	 CMDARG_MAC 'AMRS',             FCN_AMRS
	 CMDARG_MAC 'DOS4',             FCN_DOS4
	 CMDARG_MAC 'EMS30',            FCN_EMS30
endif				; IF @OEM_EMS
if @OEM_HIFILL
	 CMDARG_MAC 'DOS5',             FCN_DOS5
endif				; IF @OEM_HIFILL
	 CMDARG_MAC 'NOCRR',            FCN_NOCRR
	 CMDARG_MAC 'NOTIME',           FCN_NOTIME
	 CMDARG_MAC 'NOXRAM',           FCN_NOXRAM
	 CMDARG_MAC 'ON',               FCN_RET
	 CMDARG_MAC 'OFF',              FCN_RET
	 CMDARG_MAC 'AUTO',             FCN_RET

if @OEM_FLEX
	 CMDARG_MAC 'IGNOREFLEXFRAME',  FCN_IGNOREFLEXFRAME
	 CMDARG_MAC 'NOFLEX',           FCN_IGNOREFLEXFRAME
endif				; IF @OEM_FLEX
if @OEM_EMS
	 CMDARG_MAC 'INCLUDE',          FCN_INCLUDE
	 CMDARG_MAC 'EXCLUDE',          FCN_EXCLUDE
endif				; IF @OEM_EMS
if @OEM_DEBUG
	 CMDARG_MAC 'NOPULSE',          FCN_NOPULSE
	 CMDARG_MAC 'NOSCRUB',          FCN_NOSCRUB
endif				; IF @OEM_DEBUG
endif				; IF @OEM_SYS ne @OEMSYS_ILIM

if @OEM_SYS eq @OEMSYS_HPRS
	 CMDARG_MAC 'LOWFRAME',         FCN_LOWFRAME
	 CMDARG_MAC 'NOWARMBOOT',       FCN_NOWARMBOOT
if @OEM_WTK
	 CMDARG_MAC 'W=OFF',            FCN_WTK0
	 CMDARG_MAC 'W=ON',             FCN_WTK1
endif				; IF @OEM_WTK
else
if @OEM_WTK
	 CMDARG_MAC 'WEITEK=FORCE',     FCN_WTKF
	 CMDARG_MAC 'WEITEK=OFF',       FCN_WTK0
	 CMDARG_MAC 'WEITEK=ON',        FCN_WTK1
endif				; IF @OEM_WTK
if @OEM_EMS
	 CMDARG_MAC 'EMS',              FCN_EMS
endif				; IF @OEM_EMS
if @OEM_EMS and @OEM_SYS ne @OEMSYS_ILIM
	 CMDARG_MAC 'NOFRAME',          FCN_NOFRAME
	 CMDARG_MAC 'SHORTFRAME',       FCN_NOFRAME
	 CMDARG_MAC 'EMM',              FCN_EMS
endif				; IF @OEM_EMS and @OEM_SYS ne @OEMSYS_ILIM
if @OEM_SYS ne @OEMSYS_AST386
if @OEM_SYS ne @OEMSYS_OLI and @OEM_SYS ne @OEMSYS_OL2
	 CMDARG_MAC 'NOLOW',            FCN_NOLOW
	 CMDARG_MAC 'NOWARMBOOT',       FCN_NOWARMBOOT
endif				; IF @OEM_SYS ne @OEMSYS_OLI and @OEM_SYS ne @OEMSYS_OL2

;;;;;;;; CMDARG_MAC 'SLOWKEYB',         FCN_SLOWKEYB
	 CMDARG_MAC 'RESETKEYB',        FCN_RESETKEYB
	 CMDARG_MAC 'STACKS',           FCN_STACKS
	 CMDARG_MAC 'ISTACKS',          FCN_ISTACKS

if @OEM_SOFT or @OEM_ACCEL
	 CMDARG_MAC 'SWAP',             FCN_SWAP
endif				; IF @OEM_SOFT or @OEM_ACCEL
endif				; IF @OEM_SYS eq @OEMSYS_AST386
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

if @OEM_SYS eq @OEMSYS_RET
	 CMDARG_MAC 'TERSE',            FCN_TERSE
	 CMDARG_MAC 'EXTSIZE',          FCN_EXTSIZE
	 CMDARG_MAC 'NOSCAN',           FCN_NOSCAN
endif				; IF @OEM_SYS eq @OEMSYS_RET

if @OEM_BCF
	 CMDARG_MAC 'AUTOBCF',          FCN_AUTOBCF
	 CMDARG_MAC 'BCF',              FCN_BCF
	 CMDARG_MAC 'FORCEBCF',         FCN_FORCEBCF
endif				; IF @OEM_BCF
	 CMDARG_MAC 'POSFILE',          FCN_POSFILE
if @OEM_HIFILL
	 CMDARG_MAC 'NO4B',             FCN_NO4B
	 CMDARG_MAC 'NO58',             FCN_NO58
	 CMDARG_MAC 'NOCOMPROM',        FCN_NOCOMPROM
	 CMDARG_MAC 'NOHIGH',           FCN_NOHIGH
	 CMDARG_MAC 'NOLOADHIGH',       FCN_NOLOADHI
	 CMDARG_MAC 'NOLOADHI',         FCN_NOLOADHI
	 CMDARG_MAC 'PRGREG',           FCN_PRGREG
	 CMDARG_MAC 'HPDAREG',          FCN_HPDAREG
	 CMDARG_MAC 'XBDAREG',          FCN_XBDAREG
	 CMDARG_MAC 'STACKREG',         FCN_STACKREG
	 CMDARG_MAC 'RAM',              FCN_RAM
	 CMDARG_MAC 'ROM',              FCN_ROM
	 CMDARG_MAC 'USE',              FCN_USE
elseif @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2 or @OEM_SYS eq @OEMSYS_CA
	 CMDARG_MAC 'ROM',              FCN_ROM
				; IF @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2 or @OEM_SYS eq @OEMSYS_CA
endif				; IF @OEM_HIFILL

if @OEM_FLEXROM
	 CMDARG_MAC 'VGASWAP',          FCN_VGASWAP
	 CMDARG_MAC 'FLEXROM',          FCN_FLEXROM
	 CMDARG_MAC 'NOVGASIG',         FCN_NOVGASIG
endif				; IF @OEM_FLEXROM

if @OEM_LOFILL
	 CMDARG_MAC 'VIDMEM',           FCN_VIDMEM
	 CMDARG_MAC 'CGA',              FCN_CGA
	 CMDARG_MAC 'EGA',              FCN_VEGA
	 CMDARG_MAC 'VGA',              FCN_VEGA
	 CMDARG_MAC 'MONO',             FCN_MONO
endif				; IF @OEM_LOFILL

if @OEM_SYS ne @OEMSYS_ILIM
if @OEM_SYS ne @OEMSYS_HPRS
	 CMDARG_MAC 'SHADOWROM',        FCN_SHADOWROM
if @OEM_SYS ne @OEMSYS_AST386
if @OEM_SYS ne @OEMSYS_OLI
if @OEM_SYS ne @OEMSYS_OL2
	 CMDARG_MAC 'NOROM',            FCN_NOROM
endif				; IF @OEM_SYS ne @OEMSYS_OL2
endif				; IF @OEM_SYS ne @OEMSYS_OLI
endif				; IF @OEM_SYS ne @OEMSYS_AST386
endif				; IF @OEM_SYS ne @OEMSYS_HPRS
endif				; IF @OEM_SYS ne @OEMSYS_ILIM

if @OEM_EEMS
	 CMDARG_MAC 'EEMS',             FCN_EEMS
endif				; IF @OEM_EEMS

if @OEM_MISC
	 CMDARG_MAC 'IOP',              FCN_IOP
	 CMDARG_MAC 'PROF',             FCN_PRO
	 CMDARG_MAC 'PRO',              FCN_PRO
endif				; IF @OEM_MISC

if @OEM_SOFT
	 CMDARG_MAC 'NOPARITY'          FCN_NOPARITY
	 CMDARG_MAC 'SYST',             FCN_SYS
	 CMDARG_MAC 'SYS',              FCN_SYS
endif				; IF @OEM_SOFT

if @OEM_EMS and (@OEM_SYS eq @OEMSYS_RET or @OEM_SYS eq @OEMSYS_SHS)
	 CMDARG_MAC 'SCREEN',           FCN_SCREEN
endif				; IF @OEM_EMS and (@OEM_SYS eq @OEMSYS_RET or @OEM_SYS eq @OEMSYS_SHS)

if @OEM_SRAM
	 CMDARG_MAC 'SHADOWRAM',        FCN_SHADOWRAM
endif				; IF @OEM_SRAM

if @OEM_SOFT or @OEM_SYS eq @OEMSYS_OEM or @OEM_SYS eq @OEMSYS_ASEM
	 CMDARG_MAC 'TOP384',           FCN_TOP384
endif				; IF @OEM_SOFT or @OEM_SYS eq @OEMSYS_OEM or @OEM_SYS eq @OEMSYS_ASEM
if @OEM_SOFT
	 CMDARG_MAC 'UNSHIFT',          FCN_UNSHIFT
endif				; IF @OEM_SOFT

if @OEM_WIN3
	 CMDARG_MAC 'NOWIN3',           FCN_NOWIN3
	 CMDARG_MAC 'NOWIN30',          FCN_NOWIN30
	 CMDARG_MAC 'VXD',              FCN_VXD
endif				; IF @OEM_WIN3
	 CMDARG_MAC 'MCE',              FCN_MCE
	 CMDARG_MAC 'NOABIOS'           FCN_NOABIOS
	 CMDARG_MAC 'NOCACHE'           FCN_NOCACHE
	 CMDARG_MAC 'NOGATE'            FCN_NOGATE
	 CMDARG_MAC 'NOPNP'             FCN_NOPNP
	 CMDARG_MAC 'NOVME'             FCN_NOVME
	 CMDARG_MAC 'NOXBIOS'           FCN_NOXBIOS
	 CMDARG_MAC 'XBIOSHI'           FCN_XBIOSHI
	 CMDARG_MAC 'XBIOSHIGH'         FCN_XBIOSHI
	 CMDARG_MAC 'NOSCSI'            FCN_NOSCSI
	 CMDARG_MAC 'CACHESIZE'         FCN_CACHESIZE
if @OEM_DPMI
	 CMDARG_MAC 'DPMIMEM',          FCN_DPMIMEM
	 CMDARG_MAC 'NODPMI',           FCN_NODPMI
if @OEM_VIRTUALMEM
	 CMDARG_MAC 'SWAPFILE',         FCN_SWAPFILE
endif				; IF @OEM_VIRTUALMEM
endif				; IF @OEM_DPMI

if @OEM_SYS eq @OEMSYS_RET
	 CMDARG_MAC 'PSMEM'             FCN_PSMEM
endif				; IF @OEM_SYS eq @OEMSYS_RET

if @OEM_SOFT
	 CMDARG_MAC 'IOWRAP'            FCN_IOWRAP
	 CMDARG_MAC 'NOIOWRAP'          FCN_NOIOWRAP
endif				; IF @OEM_SOFT

if @OEM_DEBUG
;;;;;;;; CMDARG_MAC 'NOSPEC'            FCN_NOSPEC
	 CMDARG_MAC 'LMLTOP',           FCN_LMLTOP
	 CMDARG_MAC 'LOAD',             FCN_LOAD
if DBG_TRACE
	 CMDARG_MAC 'TRACE',            FCN_TRACE
endif				; IF DBG_TRACE
	 CMDARG_MAC 'DEBUG=8042',       FCN_DBG8042
	 CMDARG_MAC 'DEBUG=ABIOS',      FCN_DBGABIOS
	 CMDARG_MAC 'DEBUG=ALLROM',     FCN_DBGALLROM
	 CMDARG_MAC 'DEBUG=BIOS',       FCN_DBGBIOS
	 CMDARG_MAC 'DEBUG=CALL',       FCN_DBGCALL
	 CMDARG_MAC 'DEBUG=CAPS',       FCN_DBGCAPS
	 CMDARG_MAC 'DEBUG=COMPROM',    FCN_DBGCOMPROM
	 CMDARG_MAC 'DEBUG=CR3',        FCN_DBGCR3
if @OEM_DPMI
	 CMDARG_MAC 'DEBUG=DPMI',       FCN_DBGDPMI
	 CMDARG_MAC 'DEBUG=DPMIERR',    FCN_DBGDPMIERR
	 CMDARG_MAC 'DEBUG=DPMILOCK',   FCN_DBGDPMILOCK
	 CMDARG_MAC 'DEBUG=DPMINEWSEL', FCN_DBGDPMINEWSEL
	 CMDARG_MAC 'DEBUG=DPMIPHYS',   FCN_DBGDPMIPHYS
	 CMDARG_MAC 'DEBUG=DPMISEL',    FCN_DBGDPMISEL
	 CMDARG_MAC 'DEBUG=DPMISPURNT', FCN_DBGDPMISPURNT
	 CMDARG_MAC 'DEBUG=DPMISTD',    FCN_DBGDPMISTD
	 CMDARG_MAC 'DEBUG=DPMITERM',   FCN_DBGDPMITERM
	 CMDARG_MAC 'DEBUG=DPMIV100',   FCN_DBGDPMIV100
	 CMDARG_MAC 'DEBUG=DPMIXCOPY',  FCN_DBGDPMIXCOPY
endif				; IF @OEM_DPMI
	 CMDARG_MAC 'DEBUG=EMSERR',     FCN_DBGEMSERR
	 CMDARG_MAC 'DEBUG=EMSRDWR',    FCN_DBGEMSRDWR
	 CMDARG_MAC 'DEBUG=EMSWRIT',    FCN_DBGEMSWRIT
	 CMDARG_MAC 'DEBUG=EMSSAVE',    FCN_DBGEMSSAVE
	 CMDARG_MAC 'DEBUG=EPM',        FCN_DBGEPM
	 CMDARG_MAC 'DEBUG=EVM',        FCN_DBGEVM
	 CMDARG_MAC 'DEBUG=FILL',       FCN_DBGFILL
	 CMDARG_MAC 'DEBUG=HLT',        FCN_DBGHLT
	 CMDARG_MAC 'DEBUG=I06',        FCN_DBGI06
	 CMDARG_MAC 'DEBUG=I67',        FCN_DBGI67
	 CMDARG_MAC 'DEBUG=INT',        FCN_DBGCAPS
	 CMDARG_MAC 'DEBUG=INV',        FCN_DBGINV
	 CMDARG_MAC 'DEBUG=IOWRAP',     FCN_DBGIOWRAP
	 CMDARG_MAC 'DEBUG=JMP',        FCN_DBGJMP
	 CMDARG_MAC 'DEBUG=LED',        FCN_DBGLED
	 CMDARG_MAC 'DEBUG=NOVCPI',     FCN_DBGNOVCPI
	 CMDARG_MAC 'DEBUG=NOWRAP',     FCN_DBGNOWRAP
	 CMDARG_MAC 'DEBUG=PIC',        FCN_DBGPIC
	 CMDARG_MAC 'DEBUG=PMR',        FCN_DBGPMR
	 CMDARG_MAC 'DEBUG=EMSPTE',     FCN_DBGEMSPTE
	 CMDARG_MAC 'DEBUG=RC',         FCN_DBGRC
	 CMDARG_MAC 'DEBUG=ROM',        FCN_DBGROM
	 CMDARG_MAC 'DEBUG=ROMSWAP',    FCN_DBGROMSWAP
	 CMDARG_MAC 'DEBUG=SCRUB',      FCN_DBGSCRUB
	 CMDARG_MAC 'DEBUG=SOR',        FCN_DBGSOR
	 CMDARG_MAC 'DEBUG=TIME',       FCN_DBGTIME
	 CMDARG_MAC 'DEBUG=TRIP',       FCN_DBGTRIP
	 CMDARG_MAC 'DEBUG=UNSHADOWROM',FCN_DBGUNSHADOWROM
	 CMDARG_MAC 'DEBUG=VCPI',       FCN_DBGVCPI
	 CMDARG_MAC 'DEBUG=VDS',        FCN_DBGVDS
	 CMDARG_MAC 'DEBUG=VMS',        FCN_DBGVMS
if @OEM_DMA
	 CMDARG_MAC 'DEBUG=XDMA',       FCN_DBGXDMA
endif				; IF @OEM_DMA
	 CMDARG_MAC 'DEBUG=X09',        FCN_DBGX09
	 CMDARG_MAC 'DEBUG=X67',        FCN_DBGX67
	 CMDARG_MAC 'DEBUG=XM',         FCN_DBGXM
if @OEM_XMS
	 CMDARG_MAC 'DEBUG=XMS',        FCN_DBGXMS
	 CMDARG_MAC 'DEBUG=XMSPTE',     FCN_DBGXMSPTE
endif				; IF @OEM_XMS
	 CMDARG_MAC 'DEBUG=XR',         FCN_DBGXR
endif				; IF @OEM_DEBUG


SEG_TAB  segment use16 word public 'xdata' ; Start SEG_TAB segment
	 assume  ds:XGROUP

	 public  NCMDARGS
NCMDARGS equ	 ($-CMDARG_TAB)/(type CMDARG_TAB) ; Its length

SEG_TAB  ends			; End SEG_TAB segment


; SYS= arguments

if @OEM_SOFT
SEG_TAB  segment use16 word public 'xdata' ; Start SEG_TAB segment
	 assume  ds:XGROUP

	 public  SYSARG_TAB
SYSARG_TAB label word

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use16 word public 'xdata' ; Start SEG_LEN segment
	 assume  ds:XGROUP

	 public  SYSARG_LEN
SYSARG_LEN label word

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use16 word public 'xdata' ; Start SEG_ACT segment
	 assume  ds:XGROUP

	 public  SYSARG_ACT
SYSARG_ACT label dword

SEG_ACT  ends			; End SEG_ACT segment


	 CMDARG_MAC 'INBOARD',          SYSCHK_INBOARD
	 CMDARG_MAC 'JET386',           SYSCHK_JET386


SEG_TAB  segment use16 word public 'xdata' ; Start SEG_TAB segment
	 assume  ds:XGROUP

	 public  NSYSARGS
NSYSARGS equ	 ($-SYSARG_TAB)/(type SYSARG_TAB) ; Its length

SEG_TAB  ends			; End SEG_TAB segment
endif				; IF @OEM_SOFT


WBPAT_SEG segment use16 word public 'xdata' ; Start WBPAT_SEG segment
	 assume  ds:XGROUP

	 extrn	 WBPAT_TAB:word ; WBINVD patch table

WBPAT_SEG ends			; End WBPAT_SEG segment

WBPAT_END segment use16 word public 'xdata' ; Start WBPAT_END segment
	 assume  ds:XGROUP

	 extrn	 WBPAT_ENDTAB:word ; End of WBINVD patch table

WBPAT_END ends			; End WBPAT_END segment

NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 MEM_MAP:byte
	 extrn	 @XLAT_ROM0:abs
	 extrn	 @XLAT_ROM2:abs
	 extrn	 @XLAT_OTH:abs

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

	 extrn	 PROF_CNT:word
	 extrn	 PROF_SEG:word
	 extrn	 DRVPATH_END:word

	 extrn	 READ_SEG:word
	 extrn	 READ_CNT:word

	 public  CFG_SEG,CFG_LNXT
CFG_SEG  dw	 0		; Segment of the file
CFG_LNXT dw	 ?		; Offset of next available linked list entry

if @OEM_FLEXROM
	 public  FLEXFILE_CNT,FLEXFILE_SEG,FLEXFILE_VEC
FLEXFILE_CNT  dw	 0	; # bytes in the file
FLEXFILE_SEG  dw	 0	; Segment of the file
FLEXFILE_VEC  dd	 0	; Flexfile function dispatcher address

	 public  FLEXFILE
FLEXFILE  db	  @FLEXFILE,0	; Filename.ext of video translation file
FLEXFILE_LEN equ  $-FLEXFILE	; Length of ...
endif				; IF @OEM_FLEXROM

	 public  SEPARATOR
SEPARATOR db	 '='            ; Command separator for INCLUDE/EXCLUDE

NDATA	 ends			; End NDATA segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

	 extrn	 CFGBITMAP:word
	 extrn	 CFGBITCNT:byte
if @OEM_FLEXROM
	 extrn	 FLEXROMINTS:tbyte

@FLEXDATA_MAX	 equ	256	; Maximum number of bytes we can hold

	 public  FLEXDATA,FLEXDATA_CNT
FLEXDATA_CNT	 dw	?	; Byte count of above
FLEXDATA	 db	@FLEXDATA_MAX dup (?) ; Data storage between passes

endif				; IF @OEMFLEXROM

	 public  FLEXFILE_DPFE,PATHSTEM_LEN
FLEXFILE_DPFE	 db 128 dup (?) ; Buffer for file/path name
PATHSTEM_LEN	 dw	0	; Length of d:\pathname\ part of FLEXFILE_DPFE

	 extrn	 DPFE_END:word

if @OEM_WIN3
	 extrn	 OLDINT24_VEC:dword

	 public  VIRT_DEV_NAME
VIRT_DEV_NAME db @OEM_FILE,'.VxD',0 ; Filename.ext of Windows support device
VIRT_DEV_NAME_LEN equ $-VIRT_DEV_NAME ; Length of ...

	 public  ALT_VIRT_DEV_NAME, ALT_VIRT_DEV_NAME_LEN
ALT_VIRT_DEV_NAME dw	0	; Pointer to alternate VXD DPFE
ALT_VIRT_DEV_NAME_LEN dw 0	; Length of above

	 public  CFGFILE
CFGFILE  db	 '386LOAD.CFG',0 ; Fileanme.ext of configuration file
CFGFILE_LEN equ  $-CFGFILE	; Length of ...
endif				; IF @OEM_WIN3

	 public  ARGSTK,ARGSTKZ
	 align	 4		; Align for better performacne
ARGSTK	 dw	 128 dup ('??') ; Local stack for CHECK_ARGS
ARGSTKZ  label	 word		; End of ...

	 public  OLDARGSTK_VEC,NEWARGSTK_VEC
OLDARGSTK_VEC dd ?		; Old stack pointer
NEWARGSTK_VEC dd XGROUP:ARGSTKZ ; New ...

	 public  LASTKEY
LASTKEY  dw	 ?		; Offset of last keyword

	 public  NUMBERS_LO
NUMBERS_LO db	 '0123456789abcdef' ; Conversion table for BASE2BIN

	 public  DEF_STACKS
DEF_STACKS db	 '=6',CR        ; Default DOS stacks setting [,128]

XDATA	 ends			; End XDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

if @OEM_WTK
	 extrn	 MSG_WTKOFF:byte
endif				; IF @OEM_WTK

	 extrn	 MSG_UNK:byte
	 extrn	 MSG_SEP:byte
	 extrn	 MSG_INVALIDOK:byte
	 extrn	 MSG_CRLF:byte

if @OEM_SYS eq @OEMSYS_HPRS
MSG_INVERR equ	 MSG_UNK
MSG_LENERR equ	 MSG_UNK
	 extrn	 MSG_CMDCHK_EMSEXT:byte
else
if @OEM_MISC
	 extrn	 MSG_UNKPRO:byte
	 extrn	 MSG_EOLERR:byte
endif				; IF @OEM_MISC
MSG_LENERR equ	 MSG_SEP
	 extrn	 MSG_INVERR:byte
	 extrn	 MSG_OVF:byte
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

if @OEM_WIN3
	 extrn	 MSG_NOVXD:byte
	 extrn	 MSG_NOALTVXD:byte
endif				; IF @OEM_WIN3

if @OEM_FLEXROM
	 extrn	 MSG_NOFLEXFILE_PASS1:byte
	 extrn	 MSG_FF_ERR:byte
	 extrn	 MSG_FF_ERR1:byte
	 extrn	 MSG_FF_XVID:byte
	 extrn	 MSG_FF_XVID1:byte
	 extrn	 MSG_FF_XROOM:byte
	 extrn	 MSG_FF_XVER:byte
	 extrn	 MSG_FF_NOROM:byte
	 extrn	 MSG_FF_NORAM:byte
	 extrn	 MSG_FF_SHDROM:byte
	 extrn	 MSG_FF_ROM:byte
	 extrn	 MSG_PASS1_PAK:byte
endif				; IF @OEM_FLEXROM

YDATA	 ends			; End YDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_ARG_XCODE
@QMAX_ARG_XCODE:		; Mark module start in .MAP file

if @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 FCN_EMS_SUB:far
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 FMT_ERR_CODE:far
	 extrn	 YMSGOUT2:near
	 extrn	 DISP_CPDMSG:far
if @OEM_WIN3
	 extrn	 READFILE:far
	 extrn	 INST24:far
	 extrn	 REST24:far
endif				; IF @OEM_WIN3
	 extrn	 INIT_MBOOT:far
	 extrn	 CHECK_MBOOT:far

	 NPPROC  XSKIP_WHITE -- Skip over White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over white space and return the last
character in AL.

On entry:

DS:SI	 ==>	 command line

On exit:

DS:SI	 ==>	 command line (updated)
AL	 =	 lower case last character

|

	 lodsb			; Get the next byte

	 cmp	 al,' '         ; Check for blank
	 je	 short XSKIP_WHITE ; Go around again

	 cmp	 al,TAB 	; Check for TAB
	 je	 short XSKIP_WHITE ; Go around again

	 cmp	 al,40h 	; Test for conversion of alpha to lower case
	 jb	 short @F	; Not this time

	 or	 al,20h 	; Convert alpha to lower case
@@:
	 ret			; Return to caller with next byte in AL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XSKIP_WHITE endp		; End XSKIP_WHITE procedure
	 NPPROC  XSKIP_BLACK -- Skip over non-White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over non-white space and return the last
character in AL.

On entry:

DS:SI	 ==>	 command line

On exit:

DS:SI	 ==>	 command line (updated)
AL	 =	 lower case last character

|

	 lodsb			; Get the next byte

	 cmp	 al,EOF 	; Are we at the end of the file?
	 je	 short @F	; Yes, we are done, exit

	 cmp	 al,CR		; Is it a CR
	 je	 short @F	; Yes, we are done, exit

	 cmp	 al,LF		; Is it a LF
	 je	 short @F	; Yes, we are done, exit

	 cmp	 al,' '         ; Check for blank
	 je	 short @F	; We are done, exit

	 cmp	 al,TAB 	; Check for TAB
	 jne	 short XSKIP_BLACK ; No, check next char

@@:
	 ret			; Return to caller with next byte in AL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XSKIP_BLACK endp		; End XSKIP_BLACK procedure
	 FPPROC  CALC_SCRN -- Determine Screen Adapter Presence
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set NRD_FLAG according to

EGA	 @NRD_EGA
Color	 @NRD_CLR
Mono	 @NRD_MDA

|

	 REGSAVE <ax,dx>	; Save registers

	and	NRD_FLAG,not @NRD_CLR ; Clear default value

	 mov	 dx,03B4h	; Address register of monochrome 6845

	 call	 CHK_CREG	; Check cursor register
	 jc	 short CALC_SCRN1 ; It's not present

	 or	 NRD_FLAG,@NRD_MDA ; Mark as present
CALC_SCRN1:
	 mov	 dx,03D4h	; Address register of color/graphics 6845

	 call	 CHK_CREG	; Check cursor register
	 jc	 short CALC_SCRN2 ; It's not present

	 or	 NRD_FLAG,@NRD_CLR ; Mark as present
CALC_SCRN2:
	 call	 IZITEGA	; Check for EGA -- return AX = -1 if not

	 cmp	 ax,-1		; Check it out
	 je	 short CALC_SCRN3 ; Not this time

	 or	 NRD_FLAG,@NRD_EGA ; Mark as present
CALC_SCRN3:
	 call	 IZITVGA	; Check for VGA -- return AX = -1 if not

	 cmp	 ax,-1		; Check it out
	 je	 short CALC_SCRN4 ; Not this time

	 or	 NRD_FLAG,@NRD_VGA ; Mark as present
	 or	 LCL_FLAG,@LCL_VGA ; Mark as present
CALC_SCRN4:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_SCRN endp			; End CALC_SCRN procedure
	 NPPROC  IZITEGA -- Check For Presence of EGA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return AX = -1 if EGA not present, otherwise
       AL =  0 if present and in color mode
	     1		      in mono mode
	     2		      in enhanced color mode
       AH = memory settings (0 = 64k, 1 = 128k, 2 = 192k, 3 = 256k)
|

	 REGSAVE <bx,cx>	; Save registers

	 mov	 bl,10h 	; Function code to return EGA information
	 mov	 bh,0FFh	; Set to value out of range
	 mov	 cl,0Fh 	; Ditto

	 VIDCALL @GETEGA	; Get EGA information
				; If EGA present, return with
				; BH = 0 if color mode, 1 if mono
				; BL = 0 (64k), 1 (128k), 2 (192k), 3 (256k)
				; CH = feature bits
				; CL = switch setting

	 mov	 ax,-1		; Assume not present

	 cmp	 bh,01h 	; Check against maximum allowed value
	 ja	 short IZITEGA_EXIT ; Invalid, no EGA

	 cmp	 bl,03h 	; Check against maximum allowed value
	 ja	 short IZITEGA_EXIT ; Invalid, no EGA

	 cmp	 cl,0Bh 	; Check against maximum allowed value
	 ja	 short IZITEGA_EXIT ; Invalid, no EGA

	 mov	 al,bh		; Copy mode to AL
	 mov	 ah,bl		; ...and memory size to AH

	 cmp	 cl,9		; Check switch setting for enhanced color mode
	 jne	 short IZITEGA_EXIT ; Not this time

	 mov	 al,2		; It's in enhanced color mode
IZITEGA_EXIT:
	 REGREST <cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITEGA  endp			; End IZITEGA procedure
	 NPPROC  IZITVGA -- Check For Presence of VGA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return AX = -1 if VGA not present
	  =  1 if present and in mono mode
	  =  2		      in enhanced color mode

|

	 REGSAVE <bx>		; Save register

	 mov	 al,00h 	; Subfunction to get DCC
	 VIDCALL @GSTDCC	; Get display combination code
				; Return with
				; AL = 1Ah means function supported
				; BL = Active display DCC
				; BH = Alternate ...

	 cmp	 al,@GSTDCC	; Izit supported?
	 jne	 short IZITVGA_XPRES ; Jump if not

	 mov	 ax,01h 	; Assume monochrome

	 cmp	 bl,07h 	; Izit active analog mono?
	 je	 short IZITVGA_EXIT ; Yes, use code in AX

	 cmp	 bh,07h 	; Izit alternate ...
	 je	 short IZITVGA_EXIT ; Yes, use code in AX

	 mov	 ax,02h 	; Assume enhanced color

	 cmp	 bl,08h 	; Izit active analog color?
	 je	 short IZITVGA_EXIT ; Yes, use code in AX

	 cmp	 bh,08h 	; Izit alternate ...
	 je	 short IZITVGA_EXIT ; Yes, use code in AX
IZITVGA_XPRES:
	 mov	 ax,-1		; Mark as not present
IZITVGA_EXIT:
	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITVGA  endp			; End IZITVGA procedure
	 NPPROC  CHK_CREG -- Check Cursor Register DX For Adapter Presence
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,dx>	; Save registers

	 mov	 al,0Fh 	; Set CRTC to address cursor register
	 out	 dx,al		; Tell CRTC about it
	 inc	 dx		; Point to data register
	 jmp	 short $+2	; I/O delay for PC AT
	 jmp	 short $+2
	 jmp	 short $+2

	 in	 al,dx		; Save original value
	 push	 ax		; on the stack
	 mov	 al,5Ah 	; Test value for cursor position
	 out	 dx,al		; Tell CRTC about it
	 jmp	 short $+2	; I/O delay for PC AT
	 jmp	 short $+2
	 jmp	 short $+2

	 in	 al,dx		; Read it back in

	 cmp	 al,5Ah 	; Check against test value
	 pop	 ax		; Restore original cursor value
	 jmp	 short $+2	; I/O delay for PC AT
	 jmp	 short $+2
	 jmp	 short $+2

	 out	 dx,al		; Restore original value in CRTC
	 jne	 short CHK_CREG_NO ; Not present

	 clc			; Indicate it's present
	 jmp	 short CHK_CREG_EXIT ; Join common exit code

CHK_CREG_NO:
	 stc			; Indicate it's not present
CHK_CREG_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHK_CREG endp			; End CHK_CREG procedure
	 NPPROC  DISP_UNK -- Display Message and Unknown Keyword
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display error message and unknown keyword.

On entry:

YGROUP:DI ==>	 error message to display
DS:SI	 ==>	 unknown keyword

On exit:

DS:SI	 ==>	Points to just after unknown keyword

|

; Display Error message
	 push	 di		; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 REGSAVE <ax,bx,cx,dx> ; Save registers

; Display Keyword
	 mov	 cx,30		; Maximum message length
	 mov	 dx,si		; Address message for later

@@:	 lodsb			; Get next character
	 cmp	 al,' '         ; Check for terminator
	 jbe	 short @F	; Jump if that's all folks
	 loop	 @B		; Jump if more characters

@@:	 dec	 si		; Back off one (usually CR)

	 mov	 cx,si		; Get string length
	 sub	 cx,dx		; Subtract starting address

	 mov	 bx,@STD_OUT
	 DOSCALL @WRITF2	; Write to file BX, from DS:DX

	 push	 offset YGROUP:MSG_CRLF ; Print missing CR/LF
	 call	 YMSGOUT2	; Display it


	 REGREST <dx,cx,bx,ax> ; Restore

	 stc			; Ensure an error occurs

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_UNK endp			; End DISP_UNK procedure
	 NPPROC  DISP_UNK2 -- Display Message and Unknown Keyword
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display error message and unknown keyword.

* Display error message
* Display keyword
* Ask the user to Abort or Ignore

On entry:

YGROUP:DI ==>	 error message to display
DS:SI	 ==>	 unknown keyword

On exit:

CF = 1	 ==>	Treat as an error, do not install MAX
CF = 0	 ==>	Do not treat as an error
DS:SI	 ==>	Points to just after unknown keyword

|

; Display Error message
	 push	 di		; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 REGSAVE <ax,bx,cx,dx> ; Save registers

; Display Keyword
	 mov	 cx,30		; Maximum message length
	 mov	 dx,si		; Address message for later

@@:	 lodsb			; Get next character
	 cmp	 al,' '         ; Check for terminator
	 jbe	 short @F	; Jump if that's all folks
	 loop	 @B		; Jump if more characters

@@:	 dec	 si		; Back off one (usually CR)

	 mov	 cx,si		; Get string length
	 sub	 cx,dx		; Subtract starting address

	 mov	 bx,@STD_OUT
	 DOSCALL @WRITF2	; Write to file BX, from DS:DX

	 push	 offset YGROUP:MSG_CRLF ; Print missing CR/LF
	 call	 YMSGOUT2	; Display it

	 call	 XSKIP_EOL	; Skip to the end of the line

	 call	 ABORT_IGNORE	; Ask the user to Abort or Ignore
				; Returns CF=1 on abort

	 REGREST <dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_UNK2 endp			; End DISP_UNK2 procedure
if @OEM_MISC
	 NPPROC  PROC_PROFILE -- Process Profile Entries
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es,fs>	; Save segment registers

	 push	 seg XGROUP	; Setup FS for data references
	 pop	 fs
	 assume  fs:XGROUP	; Tell the assembler about it

	 lds	 si,RH_VEC	; Address request header
	 assume  ds:nothing	; Tell the assembler

	 call	 INIT_MBOOT	; Find current CONFIG= setting

	 mov	 ds,PROF_SEG	; Get the segment
	 assume  ds:nothing	; Tell the assembler about it

; Convert everything to common case

	 xor	 si,si		; DS:SI ==> start of profile

	 mov	 cx,PROF_CNT	; Get # bytes in profile

	 and	 cx,cx		; Izit empty?
	 jz	 near ptr PROC_PROF_EOF ; Exit if profile is empty
PROC_PROF_UPPER:
	 lodsb			; Get next character
	 call	 UPPERCASE	; Convert to uppercase
	 mov	 ds:[si-1],al	; Save back

	 loop	 PROC_PROF_UPPER ; Jump if more characters to convert

; Loop through the file contents

	 xor	 si,si		; DS:SI ==> start of profile
PROC_PROF_LINE:
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to start of argument

	 cmp	 al,EOF 	; Check for end of the file
	 je	 near ptr PROC_PROF_EOF ; Skip over it

	 call	 CHECK_MBOOT	; Check to see if line belongs to us
	 jc	 short @F	; Jump if so

	 call	 SKIP_EOL_COMMENT ; Skip entire line
	 jmp	 PROC_PROF_EOL2 ; Join common code

@@:
	 call	 IZITCOMMENT	; Check for a comment delimiter
	 je	 short PROC_PROF_EOL ; Skip over it

	 call	 IZITEOL	; Check for end of the line
	 je	 short PROC_PROF_EOL ; Skip over it

; Search for the argument text

	 xor	 ebx,ebx	; Zero index register
	 mov	 cx,NCMDARGS	; # arguments to check
PROCHK_ARGS_NEXT:
	 mov	 di,CMDARG_TAB[ebx*(type CMDARG_TAB)] ; Get location of text

	 REGSAVE <cx,si,es>	; Save for a moment

	 push	 seg XGROUP	; Get CMDARG_TAB segment
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 mov	 cx,CMDARG_LEN[ebx*(type CMDARG_LEN)] ; Get length
    repe cmps	 ds:[si].LO,CMDARG_TAB.LO[di] ; Compare 'em
	 REGREST <es,si,cx>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 jne	 short PROCHK_ARGS_NEXT1 ; Not this one

; Mark as found only if the next character is a valid separator

	 mov	 di,CMDARG_LEN[ebx*(type CMDARG_LEN)] ; Get length of matching command
	 add	 di,si		; Add into starting offset
	 mov	 al,ds:[di]	; Get the next character

	 cmp	 al,'/'         ; Check for valid separator
	 je	 short PROCHK_ARGS_FOUND ; Jump if valid

	 cmp	 al,'='         ; Check for valid separator
	 je	 short PROCHK_ARGS_FOUND ; Jump if valid

	 call	 IZITCOMMENT	; Check for a comment delimiter
	 je	 short PROCHK_ARGS_FOUND ; Jump if valid

	 cmp	 al,' '         ; Check for blank or below
	 jbe	 short PROCHK_ARGS_FOUND ; A match
PROCHK_ARGS_NEXT1:
	 inc	 ebx		; Skip to next entry

	 loop	 PROCHK_ARGS_NEXT ; Jump if more entries to check

	 lea	 di,YGROUP:MSG_UNKPRO ; YGROUP:DI ==> error message
	 call	 DISP_UNK2	; Display it along with unknown keyword at DS:SI
	 jc	 short PROC_PROF_ERR ; Call it an error

	 call	 SKIP_EOL	; Go to the end of this line
	 jmp	 short PROC_PROF_EOL2 ; Pick up the next line

PROCHK_ARGS_FOUND:
	 mov	 LASTKEY,si	; Save starting offset
	 add	 si,CMDARG_LEN[ebx*(type CMDARG_LEN)] ; Skip over the keyword

	 call	 CMDARG_ACT[ebx*(type CMDARG_ACT)] ; Take appropriate action
	 jnc	 short PROC_PROF_EOL ; Jump if something went wrong

	 cmp	 INVALID_OK,0 ; Is the Invalid keyword OK?
	 jne	 short PROC_PROF_ERR ; Jump if something went wrong

PROC_PROF_EOL:
	 call	 SKIP_EOL	; Skip to end of line, allowing white space
	 lea	 dx,YGROUP:MSG_EOLERR ; In case something goes wrong
	 jc	 short PROC_PROF_ERRMSG ; Jump if error

PROC_PROF_EOL2:
	 cmp	 al,EOF 	; Check for EOF
	 je	 short PROC_PROF_EOF ; Jump if EOF found

	 cmp	 si,PROF_CNT	; Check against current position
	 jb	 near ptr PROC_PROF_LINE ; Continue on
PROC_PROF_EOF:
	 clc			; Indicate all went well
	 jmp	 short PROC_PROF_EXIT ; Join common exit code

PROC_PROF_ERRMSG:
	 push	 dx		; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message
PROC_PROF_ERR:
	 stc			; Indicate something went wrong
PROC_PROF_EXIT:
	 REGREST <fs,es,ds>	; Restore
	 assume  ds:nothing,es:PGROUP,fs:nothing ; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_PROFILE endp		; End PROC_PROFILE procedure
endif				; IF @OEM_MISC
	 NPPROC  UPPERCASE -- Convert AL to Uppercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 cmp	 al,'a'         ; Check lower limit
	 jb	 short UPPERCASE_EXIT ; Too small for us

	 cmp	 al,'z'         ; Check upper limit
	 ja	 short UPPERCASE_EXIT ; Too big for us

	 add	 al,'A'-'a'     ; Convert alpha to upper case
UPPERCASE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPPERCASE endp			; End UPPERCASE procedure
if @OEM_MISC
	 NPPROC  SKIP_EOL -- Skip to End-of-line
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip to the end of the current line ensuring that there's at
most white space or comment text in the trailing portion.

On Entry:
DS:SI	==>	String to process.

On Exit:
DS:SI	==>	Updated, SI advances to next white space charactor
AL	=	Next charactor.

CF = 1	If no DS:SI does not point to white space on entry.
CF = 0	Otherwise

|

	 call	 XSKIP_WHITE	; Skip over white space

	 cmp	 al,EOF 	; Check for EOF
	 je	 short SKIP_EOL_EXIT  ; Jump if so (note CF=0)

	 call	 IZITCOMMENT	; Check for a comment delimiter
	 je	 short SKIP_EOL_COMMENT ; Jump if so

	 cmp	 al,CR		; Check for CR
	 je	 short SKIP_EOL_CRLF  ; Jump if so

	 cmp	 al,LF		; Check for LF
	 je	 short SKIP_EOL_CRLF  ; Jump if so

	 stc			; Indicate something went wrong

	 jmp	 short SKIP_EOL_EXIT ; Join common exit code

	 public  SKIP_EOL_COMMENT
SKIP_EOL_COMMENT:
	 lodsb			; Get next byte

	 cmp	 al,CR		; Izit end of the line?
	 je	 short SKIP_EOL_CRLF  ; Yes

	 cmp	 al,LF		; Izit end of the line?
	 je	 short SKIP_EOL_CRLF  ; Yes

	 cmp	 al,EOF 	; Izit end of the file?
	 je	 short SKIP_EOL_EXIT  ; Yes (note CF=0)

	 jmp	 short SKIP_EOL_COMMENT ; Go around again

SKIP_EOL_CRLF:
	 call	 XSKIP_WHITE	; Skip over white space

	 cmp	 al,EOF 	; Check for EOF
	 je	 short SKIP_EOL_EXIT  ; Jump if so (note CF=0)

	 cmp	 al,CR		; Check for CR
	 je	 short SKIP_EOL_CRLF  ; Jump if so

	 cmp	 al,LF		; Check for LF
	 je	 short SKIP_EOL_CRLF  ; Jump if so

	 clc			; Indicate all went OK
SKIP_EOL_EXIT:
	 dec	 si		; Back up to last byte

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_EOL endp			; End SKIP_EOL procedure
	 NPPROC  XSKIP_EOL -- Skip to End-of-line (CR/LF if in profile mode)
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip to the end of the current line.

On Entry:
	DS:SI	==>	String to process.

On Exit:

If processing profile
	DS:SI	==>	Updated, SI advances to next CR/LF or EOF.
	AL	=	Next charactor.

	CF = 0	Always

If not processing profile
	DS:SI	==>	Updated, SI advances to next white space charactor.
			(Same as SKIP_EOL)
	AL	=	Next charactor.

	CF = 0	Always

|
	 call	 SKIP_EOL	; SKip to next white space

	 push	 es		; Save for later

	 push	 seg PGROUP	; Get PGROUP segment
	 pop	 es		; into es
	 assume  es:PGROUP	; For NRD_FLAG

	 test	 NRD_FLAG,@NRD_PRO ; Are we looking at the profile?

	 pop	 es		; Restore

	 assume  es:nothing	; Tell assembler

	 jz	 short XSKIP_EOL_EXIT ; Not in the profile? Exit

XSKIP_EOL_TOP:			; Search for next CR or LF
	 lodsb			; Get next char

	 cmp	 al,CR		; Check for CR
	 je	 short XSKIP_EOL_EXIT ; Exit if CR

	 cmp	 al,EOF 	; Check for EOF
	 je	 short XSKIP_EOL_EXIT ; Exit if EOF

	 cmp	 al,LF		; Check for LF
	 jne	 short XSKIP_EOL_TOP ; Loop if it is not a CF/LF/EOF

XSKIP_EOL_EXIT:
	 dec	 si		; Back up one

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XSKIP_EOL endp			; End XSKIP_EOL procedure
endif				; IF @OEM_MISC
	 NPPROC  IZITCOMMENT -- Check for a comment delimiter
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If AL is a comment delimiter (; or *) return ZR, otherwise NZ.

|

	 cmp	 al,';'         ; Izit a comment delimiter?
	 je	 short @F	; Jump if so

	 cmp	 al,'*'         ; Izit other comment delimiter?
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITCOMMENT endp		; End IZITCOMMENT procedure
	 NPPROC  IZITEOL -- Check For An End-Of-Line Character
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If AL is an EOL character return ZF=1, otherwise ZF=0.

|

	 cmp	 al,0		; Izit EOL?
	 je	 short @F	; Jump if so

	 cmp	 al,LF		; Izit EOL?
	 je	 short @F	; Jump if so

	 cmp	 al,CR		; Izit EOL?
	 je	 short @F	; Jump if so

	 cmp	 al,EOF 	; Izit EOL?
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITEOL  endp			; End IZITEOL procedure
	 NPPROC  READ_CFG -- Read 386LOAD Configuration File
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read in the 386LOAD configuration file

On entry:

ES:DI	 ==>	 tail of our d:\path\

|

	 REGSAVE <eax,bx,cx,dx,esi,edi,ds,es,fs,gs> ; Save registers

	 push	 seg PGROUP	; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 seg PGROUP	; Setup FS for data references
	 pop	 fs
	 assume  fs:PGROUP	; Tell the assembler about it

	 push	 seg XGROUP	; Setup GS for data references
	 pop	 gs
	 assume  gs:XGROUP	; Tell the assembler about it

; Copy 386LOAD.CFG filename.ext to end of tail

	 lea	 si,CFGFILE	; FS:SI ==> config filename.ext
	 mov	 cx,CFGFILE_LEN ; CX = length of ...
S16  rep movs	 <PGROUP:[di].LO,CFGFILE[si]> ; Copy to local storage

	 lea	 si,VIRT_DEV_DPFE ; DS:SI ==> local buffer

	 push	 0		; Mark as NOT to be deleted
	 call	 READFILE	; Read in the file at DS:SI
	 jc	 near ptr READ_CFG_EXIT ; Something went wrong, ignore it

	 mov	 ax,READ_SEG	; Get the segment
	 mov	 CFG_SEG,ax	; Save for later use
	 mov	 ax,READ_CNT	; Get the count
	 inc	 ax		; Count in the EOF

; Convert the contents of the file to all uppercase
; Strip out comments and excess whitespace.
; Parse out special flagged entries.

	 mov	 cx,ax		; Copy actual length to count register
	 add	 ax,4-1 	; Round up...
	 and	 ax,not (4-1)	; ...to dword boundary
	 mov	 CFG_CNT,ax	; Save for later use
	 mov	 CFG_LNXT,ax	; ...

	 mov	 ds,READ_SEG	; Get segment of the file
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 es,READ_SEG	; Set up destination segment
	 assume  es:nothing	; Tell the assembler

	 xor	 esi,esi	; DS:SI ==> start of CFG file
	 sub	 edi,edi	; ES:DI ==> start of stripped-down CFG file
				; (ESI & EDI used to save linked list pointers)
	 sub	 dx,dx		; Set initial field count and token state
				; Fields are:
				; flags filename date [optional]
				; States in DH: 0=get next token; 1=in token;
				; 2=ignore till EOL
				; Field number (if DH=1) in DL
	 call	 READ_CFG_CLEAR ; Clear CFGBITxxx fields
READ_CFG_NEXT:
	 lodsb			; Get next character

	 call	 UPPERCASE	; Convert AL to uppercase

	 call	 IZITCOMMENT	; Return ZR if AL is a comment (; or *)
	 je	 near ptr READ_CFG_CMT ; Jump if so

	 cmp	 al,CR		; Izit end of line?
	 jne	 short @F	; Jump if not

	 or	 dl,dl		; Are there any tokens on this line?
	 jz	 near ptr READ_CFG_LOOP ; Ignore it if so
@@:
	 cmp	 al,LF		; Izit end of line?
	 je	 near ptr READ_CFG_EOL ; Jump if so

	 cmp	 dh,2		; Are we ignoring everything?
	 je	 near ptr READ_CFG_LOOP ; Jump if so

	 cmp	 al,' '         ; Izit a blank?
	 je	 short @F	; Jump if not

	 cmp	 al,TAB 	; Izit other whitespace?
	 jne	 short READ_CFG_XWS ; Jump if not

	 mov	 al,' '         ; Make all whitespace blanks
@@:
	 cmp	 dh,1		; Were we reading a token?
	 jne	 near ptr READ_CFG_LOOP ; Jump if not

	 sub	 dh,dh		; Not reading token

	 jmp	 READ_CFG_PUT	; Join common code

READ_CFG_XWS:
	 or	 dh,dh		; Are we already in a token?
	 jnz	 short @F	; Jump if so

	 inc	 dh		; Change state
	 inc	 dl		; Count in token
@@:

; Check for flags in CFGLIST and add to appropriate list if found

	 cmp	 dl,1		; Are we reading flags?
	 jne	 short READ_CFG_XFL ; Jump if not

; Convert the decimal number which follows (if any)
; To simplify the following code, we limit the following decimal
; number to a single digit.

	 mov	 ah,ds:[si]	; Get the next character

	 cmp	 ah,'9'         ; Izit a number?
	 ja	 short @F	; Jump if not

	 sub	 ah,'0'         ; Izit a number?
	 jb	 short @F	; Jump if not

	 inc	 si		; Skip over it

	 jmp	 short READ_CFG_NUM ; Join common code

@@:
	 mov	 ah,0		; Mark as not a number
READ_CFG_NUM:
	 push	 cx		; Save loop counter

	 mov	 cx,@CFGLIST_LEN ; Number of flags to check for
	 sub	 bx,bx		; Index first flag record to check for
READ_CFG_NEXTFLG:
	 cmp	 ah,CFGLIST[bx].LLST_NUM ; Do we have a match?
	 jne	 short @F	; Jump if not

	 cmp	 al,CFGLIST[bx].LLST_LTR ; Do we have a match?
	 je	 short READ_CFG_MATCH ; Jump if so
@@:
	 add	 bx,size LLST_STR ; Skip to next one

	 loop	 READ_CFG_NEXTFLG ; Go around again

	 jmp	 short READ_CFG_NOMATCH ; Jump if we do not have a match

READ_CFG_MATCH:
	 inc	 CFGBITCNT	; Indicate a match
	 sub	 cx,@CFGLIST_LEN ; Less # list entries
	 neg	 cx		; Negate to get origin-0 entry index
	 bts	 CFGBITMAP,cx	; Mark as present
READ_CFG_NOMATCH:
	 pop	 cx		; Restore loop counter

; Write out the flag and any following decimal number

	 stosb			; Store it back

; Note what a pain the following code would be if we allowed the
; decimal number following the flag to be multidigit.

	 mov	 al,ah		; Copy decimal number

	 cmp	 al,0		; Izit valid?
	 je	 short @F	; Jump if not

	 add	 al,'0'         ; Convert to decimal
	 stosb			; Store it back
@@:
	 jmp	 short READ_CFG_LOOP ; Join common code

READ_CFG_XFL:
	 cmp	 dl,2		; Are we reading program name?
	 jne	 short READ_CFG_PUT ; Jump if not

	 cmp	 CFGBITCNT,0	; Were there any matches?
	 je	 short READ_CFG_PUT ; Jump if not

	 push	 cx		; Save for a moment

	 movzx	 cx,CFGBITCNT	; Get # matches
@@:
	 bsf	 bx,CFGBITMAP	; Get bit index into BX of next match
	 btr	 CFGBITMAP,bx	; Clear the bit for next time
	 imul	 bx,size LLST_STR ; Convert from bit index to CFGLIST index

	 lea	 bx,CFGLIST[bx].LLST_DAT ; Offset of start of linked list
	 push	 bx		; Pass offset of offset
	 call	 READ_CFG_LINK	; Link this name into the list

	 loop	 @B		; Jump if more matches

	 pop	 cx		; Restore

	 call	 READ_CFG_CLEAR ; Clear CFGBITxxx fields
READ_CFG_PUT:

; Save and continue

	 stosb			; Store it back

	 jmp	 short READ_CFG_LOOP ; Join common code

READ_CFG_CMT:
	 mov	 dh,2		; Ignore everything

	 jmp	 short READ_CFG_LOOP ; Join common code

READ_CFG_EOL:
	 sub	 dh,dh		; Reset state
	 or	 dl,dl		; Were there any tokens on this line?
	 mov	 dl,0		; Reset token count (flags unaffected)
	 jnz	 short READ_CFG_PUT ; Jump if so

READ_CFG_LOOP:
;;;;;;;  loop	 READ_CFG_NEXT	; Jump if more characters to convert
	 dec	 cx		; Adjust loop counter
	 jnz	 near ptr READ_CFG_NEXT ; Jump if more characters to convert


; Recalculate length of linked list

	 add	 di,4-1 	; Round up to dword boundary
	 and	 di,not (4-1)	; Truncate
	 mov	 si,CFG_CNT	; Get old end of list

	 mov	 ebx,esi	; Copy ptr to end of text
	 sub	 ebx,edi	; Less start of LFLG_STRs to get delta

	 mov	 cx,CFG_LCNT	; Get # linked list entries
	 jcxz	 READ_CFG_UPD	; Jump if none

; Move linked list down over end of CFG file

READ_CFG_NEXTLST:
	 cmp	 ds:[si].LFLG_NEXT,-1 ; Is there a next entry?
	 je	 short @F	; Jump if so

	 sub	 ds:[si].LFLG_NEXT,ebx ; Relocate downwards
@@:
	 push	 cx		; Save # linked list entries

	 mov	 cx,type LFLG_STR ; Get # bytes in this linked list entry
S16  rep movs	 <es:[di].LO,ds:[si].LO> ; Move next entry in list

	 pop	 cx		; Restore

	 loop	 READ_CFG_NEXTLST ; Jump if more linked list entries

; We've relocated the entire linked list downwards; now relocate the
; heads of any non-empty flag lists.

	 sub	 si,si		; Index first entry
	 mov	 cx,@CFGLIST_LEN ; Number of entries to process
READ_CFG_NEXTLST2:
	 cmp	 CFGLIST[si].LLST_DAT.LFLG_NEXT,-1 ; Izit empty?
	 je	 short @F	; Jump if so

	 sub	 CFGLIST[si].LLST_DAT.LFLG_NEXT,ebx ; Relocate downwards
@@:
	 add	 si,size LLST_STR ; Skip to next entry
	 loop	 READ_CFG_NEXTLST2 ; Go around again

; Update count of bytes in CFG file + length of linked list

READ_CFG_UPD:
	 mov	 CFG_CNT,di	; Save as new length
READ_CFG_EXIT:
	 REGREST <gs,fs,es,ds,edi,esi,dx,cx,bx,eax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_CFG endp			; End READ_CFG procedure
	 NPPROC  READ_CFG_CLEAR -- Clear CFGBITxxx Fields
	 assume  ds:nothing,es:nothing,fs:nothing,gs:XGROUP,ss:nothing
COMMENT|

Clear CFGBITxxx fields.

|

	 REGSAVE <ax,cx>	; Save registers

	 mov	 CFGBITCNT,0	; Mark as no CFGLIST[] matches

	 mov	 cx,@CFGLIST_LEN ; Get # bits to clear
	 xor	 ax,ax		; Initialize bit index
@@:
	 btr	 CFGBITMAP,ax	; Clear the bit
	 inc	 ax		; Skip to next bit

	 loop	 @B		; Jump if more bits to clear

	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_CFG_CLEAR endp		; End READ_CFG_CLEAR procedure
	 NPPROC  READ_CFG_LINK -- Link Into READ_CFG List
	 assume  ds:nothing,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Link into READ_CFG list

On entry:

EDI	 =	 offset in PGROUP of filename

|

READ_CFG_LSTR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
READ_CFG_LOFF dw ?		; Offset of offset of last flagged name

READ_CFG_LSTR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,bx,si>	; Save registers

	 mov	 bx,CFG_LNXT	; Address next available linked list entry
	 mov	 ds:[bx].LFLG_FNAM,edi ; Save new filename offset

	 mov	 si,[bp].READ_CFG_LOFF ; Get offset of offset of last flagged name
	 movzx	 eax,bx 	; Get offset of current entry

	 xchg	 eax,PGROUP:[si].LFLG_NEXT ; Swap with offset of last flagged name
	 xchg	 eax,ds:[bx].LFLG_NEXT ; Save new next offset, get terminator

	 add	 bx,type LFLG_STR ; Skip to next entry
	 mov	 CFG_LNXT,bx	; Save for later use

	 inc	 CFG_LCNT	; Count in another one

	 REGREST <si,bx,eax>	; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_CFG_LINK endp		; End READ_CFG_LINK procedure
	 FPPROC  SET_PATHSTEM -- Extract 386MAX directory
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy the drive and path from device= to FLEXFILE_DPFE, make sure
it ends in \, and save the length of the prefix in PATHSTEM_LEN.

|

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es,fs>	; Save segment registers

	 cld			; String ops forwardly

	 push	 seg XGROUP	; Get segment of XGROUP
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 push	 seg PGROUP	; Setup FS for data references
	 pop	 fs
	 assume  fs:PGROUP	; Tell the assembler about it

;;;;;;;; Switch to a local stack in XGROUP
;;;;;;;
;;;;;;;  mov	 OLDARGSTK_VEC.VSEG,ss ; Save to restore later
;;;;;;;  mov	 OLDARGSTK_VEC.VOFF,sp ; ...
;;;;;;;
;;;;;;;  lss	 sp,NEWARGSTK_VEC ; SS:SP ==> new top of stack
;;;;;;;  assume  ss:nothing	; Tell the assembler about it
;;;;;;;
; Copy path from device driver

	 lds	 si,RH_VEC	; DS:SI ==> request header
	 assume  ds:nothing	; Tell the assembler about it

	 lds	 si,ds:[si].INIT_CMD_VEC ; Get address of command line args
	 assume  ds:nothing	; Tell the assembler about it

	 REGSAVE <si,ds>	; Save

	 mov	 DRVPATH_END,si ; Save as end+1 ...
SETPATH_INIT:			; Initial scan to skip over file name
	 lodsb			; Get the next byte

	 cmp	 al,CR		; If CR, end of line (?)
	 je	 short SETPATH_ENDNAME ; Use defaults

	 cmp	 al,LF		; If LF, end of line (?)
	 je	 short SETPATH_ENDNAME ; Use defaults

	 cmp	 al,' '         ; If a space, then we've reached the end
	 je	 short SETPATH_SRCH ; Yup

	 and	 al,al		; If zero, we've reached the end
	 jz	 short SETPATH_SRCH ; Yup

	 cmp	 al,':'         ; Check for drive separator
	 je	 short @F	; Jump if so

	 cmp	 al,'\'         ; Check for path separator
	 je	 short @F	; Jump if so

	 cmp	 al,'/'         ; Check for alternate path separator
	 jne	 short SETPATH_INIT ; Not as yet
@@:
	 mov	 DRVPATH_END,si ; Save as end+1 of driver path

	 jmp	 short SETPATH_INIT ; Not there as yet, continue looking

SETPATH_SRCH:
	 dec	 si		; Back off to end+1
	 mov	 DPFE_END,si	; Save as end+1 of d:\path\filename.ext

SETPATH_ENDNAME:
	 REGREST <ds,si>	; Restore
	 assume  ds:nothing	; Tell the assembler

	 lea	 di,FLEXFILE_DPFE ; ES:DI ==> local buffer for filename

	 cmp	 ds:[si+1].LO,':' ; Is there a drive separator?
	 je	 short PROC_FF1 ; Jump if so

	 DOSCALL @GETDSK	; Return with current drive # in AL (origin-0)
	 add	 al,'A'         ; Convert to uppercase ASCII

S16	 stos	 FLEXFILE_DPFE[di] ; Save in output area
	 mov	 al,':'         ; Get drive separator
S16	 stos	 FLEXFILE_DPFE[di] ; Save in output area

	 jmp	 short PROC_FF2 ; Join common code

PROC_FF1:
S16	 movs	 <FLEXFILE_DPFE[di].ELO,ds:[si].ELO> ; Move drive letter and separator

PROC_FF2:
	 cmp	 ds:[si].LO,'\' ; Is there a path separator?
	 je	 short PROC_FF3 ; Jump if so

	 mov	 al,'\'         ; Get path separator
S16	 stos	 FLEXFILE_DPFE[di] ; Save in output area

	 REGSAVE <si,ds>	; Save for a moment

	 mov	 al,FLEXFILE_DPFE ; Get drive letter
	 call	 UPPERCASE	; Convert AL to uppercase
	 sub	 al,'A'-1       ; Convert to origin-1
	 mov	 dl,al		; Copy to @GETDIR register

	 push	 es		; Get destin segment
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it
	 mov	 si,di		; DS:SI ==> output save area

	 DOSCALL @GETDIR	; Get current directory for drive DL to DS:SI

; Skip to the end of the output area

	 mov	 al,0		; String terminator
	 mov	 cx,-1		; We know it's there
   repne scas	 FLEXFILE_DPFE[di] ; Search for it

	 dec	 di		; Back off to trailing zero

	 cmp	 es:[di-1].LO,'\' ; Is there a trailing path separator?
	 je	 short @F	; Jump if so

	 mov	 al,'\'         ; Get path separator
S16	 stos	 FLEXFILE_DPFE[di] ; Save in output area
@@:
	 REGREST <ds,si>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

PROC_FF3:
	 mov	 cx,DRVPATH_END ; Get offset to end+1 of path
	 sub	 cx,si		; Less start to get length
S16  rep movs	 <FLEXFILE_DPFE[di],ds:[si].LO> ; Copy it

; FS:DI ==> end+1 of path.  Save length.
	 sub	 di,offset XGROUP:FLEXFILE_DPFE ; Get length of path
	 mov	 PATHSTEM_LEN,di ; Save

SET_PATHEXIT:
;;;;;;;  lss	 sp,OLDARGSTK_VEC ; SS:SP ==> old top of stack
;;;;;;;  assume  ss:nothing	; Tell the assembler about it
;;;;;;;
	 REGREST <fs,es,ds>	; Restore
	 assume  ds:nothing,es:nothing,fs:nothing ; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_PATHSTEM endp		; End SET_PATHSTEM procedure
if @OEM_FLEXROM
	 FPPROC  READ_FLEXFILE -- Read VGASWAP Translation File
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read in the VGASWAP video translation file.

|

	 REGSAVE <ax,si,ds,es,fs> ; Save registers

	 mov	 ax,seg XGROUP	; Address XGROUP...
	 mov	 ds,ax		; ... via DS
	 mov	 fs,ax		; ... via FS
	 assume  ds:XGROUP,fs:XGROUP ; Tell the assembler about it

	 push	 seg PGROUP	; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 si,FLEXFILE_DPFE ; DS:SI ==> local buffer

	 push	 0		; Mark as NOT to be deleted
	 call	 READFILE	; Read in the file (filename at DS:SI)
	 jc	 short READ_FF_EXIT ; Something went wrong, ignore it
				; Note: CF significant

	 mov	 ax,READ_SEG	; Get the segment
	 mov	 FLEXFILE_SEG,ax ; Save for later use

	 mov	 ax,READ_CNT	; Get the count
	 inc	 ax		; Count in the EOF
	 mov	 FLEXFILE_CNT,ax ; Save for later use

	 clc			; Mark as successful

READ_FF_EXIT:
	 REGREST <fs,es,ds,si,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_FLEXFILE endp			; End READ_FLEXFILE procedure
endif				; IF @OEM_FLEXROM
if @OEM_FLEXROM
	 NPPROC  PROCESS_FLEXFILE -- Process the VGASWAP Translation File
	 assume  ds:nothing,es:nothing,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Process the VGASWAP Video Translation File.

Pass 1: Read in the video translation file.
	Determine BIOS address.
	Find all of the C000 ocurrences.
	Store this information in MAX for retreival during pass 2.

Note:	Pass 2 occurs in QMAX_INI, just after we return to VM.

|

	 REGSAVE <ax,bx,cx,si,di,ds,es,fs,gs> ; Save registers

; Set up segment registers for FLEXROM processing

	 mov	 ax,seg XGROUP	; Gain addressability to XGROUP...
	 mov	 ds,ax		; ... via DS
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 ax,seg PGROUP	; Gain addressability to PGROUP...
	 mov	 es,ax		; ... via ES
	 mov	 gs,ax		; ... via GS
	 assume  es:PGROUP,gs:PGROUP ; Tell the assembler about it

; Are we processing FLEXROM today?

	 test	 FLEXROM_FLAG,@FR_VGA ; Is VGASWAP active?
	 jz	 near ptr PROC_FF_EXIT ; Jump if not

	 test	 LCL_FLAG,@LCL_XT ; Is this an XT?
	 jnz	 short PROC_FF_XT ; Jump if so (skip NOROM test)

	 test	 CMD_FLAG,@CMD_XRM ; Is NOROM specified?
	 jnz	 near ptr PROC_FF_NOROM ; Jump if so

PROC_FF_XT:
	 test	 CM3_FLAG,@CM3_ROMSH ; Is SHADOWROM specified?
	 jnz	 near ptr PROC_FF_SHDROM ; Jump if so

	 REGSAVE <es>		; Save register

	 mov	 ax,seg XGROUP	; Address XGROUP
	 mov	 es,ax		; ... via ES
	 assume  es:XGROUP	; Tell the assembler about it

; Copy @FLEXFILE filename.ext to end of tail

	 mov	 di,PATHSTEM_LEN ; Get length of load path (d:\path\)
	 lea	 di,FLEXFILE_DPFE[di] ; Point to character after backslash
	 lea	 si,FLEXFILE	; FS:SI ==> config filename.ext
	 mov	 cx,FLEXFILE_LEN ; CX = length of ...
S16  rep movs	 <FLEXFILE_DPFE[di].LO,FLEXFILE[si]> ; Copy to local storage

	 REGREST <es>		; Restore register
	 assume  es:PGROUP	; Tell the assembler about it

; Find video entry in FLEXROM_TBL (if it exists)

	 xor	 bx,bx		; Zero index into FlexROM table
@@:
	 test	 FLEXROM_TBL[bx].FLEX_FLAG,@FLEXFLAG_VGA ; Izit a video entry?
	 jnz	 short @F	; Jump if so

	 add	 bx,@FLEXROM_STRLEN ; point to next entry

	 cmp	 bx,FLEXROM_LEN ; More ROMs to process?
	 jb	 short @B	; Jump if more entries

	 jmp	 near ptr PROC_FF_XVID ; None of the entries are video

@@:

	 mov	 si,bx		; Save pointer into FLEXROM_TBL

; Read in Video Translation file

	 CPD	 'Reading XLAT (1),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 READ_FLEXFILE	; Read in the video translation file
	 jc	 near ptr PROC_FF_READ_ERR ; Jump if error

; Prep the video translation file

	 mov	 ax,READ_SEG	; Segment of XLAT program
	 sub	 ax,10h 	; Skip back 10h paras to simulate PSP

	 mov	 fs,ax		; Adjusted segment of XLAT program
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 FLEXFILE_VEC.VSEG,fs ; Setup segment of dispatcher

	 mov	 ax,fs:[@XLAT_OFF].MAX_XLAT ; Get offset of dispatcher
	 mov	 FLEXFILE_VEC.VOFF,ax ; Set ...

; Note: We are no longer stuffing our version number in XLAT's header

; Check here for correct video translation file version number.
; Currently, we accept all version numbers, so there is no need to check it.

; Initialize the video translation file

	 CPD	 'Calling XLAT (Init),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 ebx,SYS_FLAG	; Get System ID flags
	 mov	 ah,@MAXLAT_INIT ; Initialize XLAT function call
	 call	 FLEXFILE_VEC	; Make function call to video translation file
	 jc	 near ptr PROC_FF_XVER ; Jump if error

	 cmp	 bx,@XLATVERS_HTU ; Is this the correct version of XLAT?
	 jne	 near ptr PROC_FF_XVER ; Jump if not

PROC_FF_SRC:
	 test	 FLEXROM_FLAG,@FR_VSRC ; Video Source explicitely specified?
	 jnz	 short @F	; Jump if explicitly specified

	 CPD	 'Calling XLAT (GetSrcSeg),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 ah,@MAXLAT_GETSRCSEG ; Get Video ROM segment
	 mov	 cx,VGA_ALTSEG1 ; Primary ROM source
	 mov	 dx,VGA_ALTSEG2 ; Secondary ROM source
	 call	 FLEXFILE_VEC	; Make function call to video translation file
	 jc	 near ptr PROC_FF_XLAT_ERR ; Jump if error

	 CPD	 'Calling MODIFY_FLEXINFO,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 FLEXROM_TBL[si].FLEX_SRC,bx ; Set VGASWAP source
	 call	 MODIFY_FLEXINFO ; Inform FLEXROMINTS of new source
	 jmp	 short PROC_FF_DEST ; Continue

@@:
	 CPD	 'Calling XLAT (SetSrcSeg),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 ah,@MAXLAT_SETSRCSEG ; Set Video ROM segment
	 mov	 bx,FLEXROM_TBL[si].FLEX_SRC ; Video ROM source
	 mov	 cx,VGA_ALTSEG1 ; Primary ROM source
	 mov	 dx,VGA_ALTSEG2 ; Secondary ROM source
	 call	 FLEXFILE_VEC	; Make function call to video translation file
	 jc	 near ptr PROC_FF_XLAT_ERR ; Jump if error

PROC_FF_DEST:
	 cmp	 bx,0C000h	; Is the source C000?
	 jne	 short @F	; Jump if not

	 or	 FLEXROM_FLAG,@FR_VID_C000 ; Indicate video ROM at C000
@@:

	 test	 FLEXROM_FLAG,@FR_VDST ; Video Destin explicitely specified?
	 jnz	 short @F	; Jump if explicitly specified

	 CPD	 'Calling XLAT (GetDestSeg),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 ah,@MAXLAT_GETDSTSEG ; Get Video ROM destination segent
	 call	 FLEXFILE_VEC	; Make function call to video translation file
	 jc	 near ptr PROC_FF_XLAT_ERR ; Jump if error

	 mov	 FLEXROM_TBL[si].FLEX_DST,bx ; Set VGASWAP destin
	 jmp	 short PROC_FF_LEN ; Continue

@@:
	 CPD	 'Calling XLAT (SetDestSeg),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 ah,@MAXLAT_SETDSTSEG ; Set video ROM destination segment
	 mov	 bx,FLEXROM_TBL[si].FLEX_DST ; Video ROM destin
	 call	 FLEXFILE_VEC	; Make function call to video translation file
	 jc	 near ptr PROC_FF_XLAT_ERR ; Jump if error

PROC_FF_LEN:
	 test	 FLEXROM_FLAG,@FR_VLEN ; Video length explicitely specified?
	 jnz	 short @F	; Jump if explicitly specified

	 CPD	 'Calling XLAT (GetROMLen),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 ah,@MAXLAT_GETROMLEN ; Get video ROM length
	 call	 FLEXFILE_VEC	; Make function call to video translation file
	 jc	 near ptr PROC_FF_XLAT_ERR ; Jump if error

	 mov	 FLEXROM_TBL[si].FLEX_LEN,bx ; Set VGASWAP length

	 cmp	 bx,8000h	; Izit greater than 32KB?
	 jbe	 short PROC_FF_DETECT ; Jump if not

	 test	 FLEXROM_FLAG,@FR_VDST ; Video Destin explicitely specified?
	 jnz	 short PROC_FF_DETECT ; Jump if explicitly specified

	 cmp	 FLEXROM_TBL[si].FLEX_SRC,bx ; Is our source C000?
	 je	 near ptr PROC_FF_ERR3 ; Jump if so, there's no where to FLEX to
				; This will be a silent error (no message)

	 mov	 FLEXROM_TBL[si].FLEX_DST,0C000h ; Set our destin to C000

	 CPD	 'Calling XLAT (SetDestSeg),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 ah,@MAXLAT_SETDSTSEG ; Set video ROM destination segment
	 mov	 bx,0C000h	; Our new destin (it all will fit here)
	 call	 FLEXFILE_VEC	; Tell XLAT about our new video destination
	 jc	 near ptr PROC_FF_XLAT_ERR ; Jump if error

	 jmp	 short PROC_FF_DETECT ; Join common code

@@:
	 CPD	 'Calling XLAT (SetROMLen),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 ah,@MAXLAT_SETROMLEN ; Set video ROM Length
	 mov	 bx,FLEXROM_TBL[si].FLEX_LEN ; Video ROM length
	 call	 FLEXFILE_VEC	; Make function call to video translation file
	 jc	 near ptr PROC_FF_XLAT_ERR ; Jump if error

; Detect video BIOS data structures (and prepare to save for pass2)

PROC_FF_DETECT:
	 CPD	 'Calling XLAT (Detection),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 ah,@MAXLAT_DETECTION ; Find off-limit areas
	 call	 FLEXFILE_VEC	; Make function call to video translation file
				; Return BX=start of data, CX=byte count
	 jc	 near ptr PROC_FF_XLAT_ERR ; Jump if error

	 cmp	 cx,@FLEXDATA_MAX ; Do we have enough room?
	 ja	 near ptr XLAT_FF_XROOM ; Jump if not

; Save XLAT's data for second pass

	 REGSAVE <si,es>	; Save registers

	 mov	 ax,seg XGROUP	; Address FLEXDATA...
	 mov	 es,ax		; ... via ES
	 assume  es:XGROUP	; Tell the assembler about it

	 mov	 FLEXDATA_CNT,cx ; Save for later

	 lea	 di,FLEXDATA	; Our temporary storage
	 mov	 si,bx		; XLAT's data is here
S16  rep movs	<FLEXDATA[di],fs:[si].LO> ; Store data

	 REGREST <es,si>	; Restore registers
	 assume  es:PGROUP	; Tell the assembler about it

PROC_FF_CACHE_LEN:
	 CPD	 'Calling XLAT (GetCacheLen),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 mov	 ah,@MAXLAT_GETCACHELEN ; Find minimum cache length of BIOS
	 call	 FLEXFILE_VEC	; Make function call to video translation file
				; Return BX=cache length
	 jc	 near ptr PROC_FF_XLAT_ERR ; Jump if error

; Determine highest offset that has to be cached

	 add	 bx,4096-1	; Round down to 4 KB
	 and	 bx,not(4096-1) ; ...
	 shr	 bx,(9-0)	; Convert bytes to 512 bytes (MEM_MAP units)

	 mov	 cx,bx		; Place in counter
	 jcxz	 short PROC_FF_XROMFILL ; Skip if no patch points in ROM

	 mov	 bx,FLEXROM_TBL[si].FLEX_SRC ; Get start of video BIOS
	 shr	 bx,(9-4)	; Convert paras to 512 bytes (MEM_MAP units)
	 lea	 di,MEM_MAP[bx] ; ES:DI ==> memory map in 512-byte blocks

	 dec	 cx		; Minus initial ROM marker
	 inc	 di		; Skip over ...

	 mov	 al,@XLAT_ROM2	; Get ROM marker
    rep stos	 MEM_MAP[di].LO ; Mark as ROM (to ensure caching)

PROC_FF_XROMFILL:

; Now that we know all about the video BIOS (source, length, & destination),
; check to see if we can go ahead with VGASWAP

; Find video entry in FLEXROM_TBL (if it exists)

	 xor	 bx,bx		; Zero index into FlexROM table
@@:
	 test	 FLEXROM_TBL[bx].FLEX_FLAG,@FLEXFLAG_VGA ; Izit a video entry?
	 jnz	 short @F	; Jump if so

	 add	 bx,@FLEXROM_STRLEN ; point to next entry

	 cmp	 bx,FLEXROM_LEN ; More ROMs to process?
	 jb	 short @B	; Jump if more entries

	 jmp	 near ptr PROC_FF_XVID ; None of the entries are video

@@:

; If we're only caching certain ROMs, see if ours is one of them

	 mov	 di,FLEXROM_TBL[bx].FLEX_SRC ; Get BIOS source in paras
	 shr	 di,(9-4)	; Convert from paras to 512 bytes

	 test	 CM2_FLAG,@CM2_ROM ; Is ROM= specified?
	 jz	 short @F	; Jump if not

	 cmp	 MEM_MAP[di],@XLAT_ROM0 ; Izit special (cached) ROM?
	 jne	 near ptr PROC_FF_ROM ; Jump if not (we can't VGASWAP)
@@:

; Check to see if our source ROM is covered by a RAM= statement

	 add	 di,offset PGROUP:MEM_MAP ; Add base of MEM_MAP

	 mov	 cx,FLEXROM_TBL[bx].FLEX_LEN ; Length of video ROM
	 shr	 cx,(9-0)	; Convert from bytes to 512 bytes

	 mov	 al,@XLAT_OTH	; Search for a RAM= marker
   repne scas	 MEM_MAP[di]	; Search the MEM_MAP for a RAM= marker
	 jz	 short PROC_FF_NORAM ; Jump if found

; Check to see if our destination ROM is covered by a RAM= statement

	 mov	 di,FLEXROM_TBL[bx].FLEX_DST ; Get BIOS destin in paras
	 shr	 di,(9-4)	; Convert from paras to 512 bytes

	 add	 di,offset PGROUP:MEM_MAP ; Add base of MEM_MAP

	 mov	 cx,FLEXROM_TBL[bx].FLEX_LEN ; Length of video ROM
	 shr	 cx,(9-0)	; Convert from bytes to 512 bytes

	 mov	 al,@XLAT_OTH	; Search for a RAM= marker
   repne scas	 MEM_MAP[di]	; Search the MEM_MAP for a RAM= marker
	 jz	 short PROC_FF_NORAM ; Jump if found

; Setup variables to be used in our Page Fault handler
; for paged mode ROMs

	 REGSAVE <eax,ecx>	; Save for a moment

	 movzx	 eax,FLEXROM_TBL[bx].FLEX_DST ; Get BIOS destin in paras
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 LaVROM_BEG,eax ; Save for later use
	 mov	 ecx,eax	; Copy to calculate PTE offset
	 shr	 ecx,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PTE_VROM_BEG,cx ; Save for later use

	 movzx	 ecx,FLEXROM_TBL[bx].FLEX_LEN ; Get BIOS length in bytes
	 add	 eax,ecx	; Add to get ending address
	 mov	 LaVROM_END,eax ; Save for later use
	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 PTE_VROM_END,ax ; Save for later use

	 movzx	 eax,FLEXROM_TBL[bx].FLEX_SRC ; Get BIOS source in paras
	 shr	 eax,(12-2)-4	; Convert from paras to 4KB in dwords
	 mov	 PTE_VROM_SRC,ax ; Save for later use

	 REGREST <ecx,eax>	; Restore

	 jmp	 PROC_FF_EXIT	; Continue on (skip error)

PROC_FF_XVID:
	 assume  fs:XGROUP	; Tell the assembler about it

	 REGSAVE <si,ds>	; Save registers

	 push	 seg PGROUP	; Get data segment (needed for HEXTABLE)
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 al,1		; Indicate Pass 1
	 lea	 si,YGROUP:MSG_FF_XVID1 ; YGROUP:SI ==> error code save area
	 call	 FMT_ERR_CODE	; Format the error code

	 REGREST <ds,si>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 bx,offset YGROUP:MSG_FF_XVID ; Address of error message
	 jmp	 short PROC_FF_ERR2 ; Continue on

PROC_FF_NORAM:
	 mov	 bx,offset YGROUP:MSG_FF_NORAM ; Address of error message
	 jmp	 short PROC_FF_ERR2 ; Continue on

PROC_FF_NOROM:
	 mov	 bx,offset YGROUP:MSG_FF_NOROM ; Address of error message
	 jmp	 short PROC_FF_ERR2 ; Continue on

PROC_FF_SHDROM:
	 mov	 bx,offset YGROUP:MSG_FF_SHDROM ; Address of error message
	 jmp	 short PROC_FF_ERR2 ; Continue on

PROC_FF_ROM:
	 mov	 bx,offset YGROUP:MSG_FF_ROM ; Address of error message
	 jmp	 short PROC_FF_ERR2 ; Continue on

PROC_FF_READ_ERR:
	 mov	 bx,offset YGROUP:MSG_NOFLEXFILE_PASS1 ; Address of error message
	 jmp	 short PROC_FF_ERR2 ; Continue on

XLAT_FF_XROOM:
	 mov	 bx,offset YGROUP:MSG_FF_XROOM ; Address of error message
	 jmp	 short PROC_FF_ERR2 ; Continue on

PROC_FF_XVER:
	 mov	 bx,offset YGROUP:MSG_FF_XVER ; Address of error message
	 jmp	 short PROC_FF_ERR2 ; Continue on

PROC_FF_XLAT_ERR:
	 test	 FLEXROM_FLAG,@FR_SHDROM ; Is there a shadowed ROM?
	 jz	 short @F	; Jump if not

	 and	 NRD_FLAG,not @NRD_UE000 ; Mark E000 as unavailable

	 test	 FLEXROM_FLAG,@FR_SHDVGA ; VGASWAP been specified also?
	 jz	 short PROC_FF_ERR3 ; Jump if not (no VGASWAP keyword)
				; If failure due to shadowrom,
				; don't display the VGASWAP error message
@@:
	 REGSAVE <si,ds>	; Save registers

	 push	 seg PGROUP	; Get data segment (needed for HEXTABLE)
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 al,ah		; Get the error code (MAXLAT function number)
	 lea	 si,YGROUP:MSG_FF_ERR1 ; YGROUP:SI ==> error code save area
	 call	 FMT_ERR_CODE	; Format the error code

	 REGREST <ds,si>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 bx,offset YGROUP:MSG_FF_ERR ; Address of error message
;;;;;;;; jmp	 short PROC_FF_ERR2 ; Continue on

; Tell 'em that VGASWAP is turned off

PROC_FF_ERR2:
	 test	 FLEXROM_FLAG,@FR_SHDROM ; Is there a shadowed ROM?
	 jz	 short @F	; Jump if not

	 and	 NRD_FLAG,not @NRD_UE000 ; Mark E000 as unavailable

	 test	 FLEXROM_FLAG,@FR_SHDVGA ; VGASWAP been specified also?
	 jz	 short PROC_FF_ERR3 ; Jump if not (no VGASWAP keyword)
				; If failure due to shadowrom,
				; don't display the VGASWAP error message
@@:
	 push	 bx		; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 push	 offset YGROUP:MSG_PASS1_PAK ; Address of 'Press any key'
	 call	 YMSGOUT2	; Display YGROUP message

	 call	 FKEYWAIT	; Wait for an acknowledgement
				; Return with key in AX

; Error with video translation file - delete video entry from table

PROC_FF_ERR3:

	 and	 FLEXROM_FLAG,(not @FR_VGA) ; Turn off VGASWAP

	 sub	 FLEXROM_LEN,@FLEXROM_STRLEN ; Delete current entry

	 cmp	 si,FLEXROM_LEN ; Anything following this entry?
	 jae	 short PROC_FF_ERR4 ; Jump if not

	 mov	 cx,FLEXROM_LEN ; Get total length...
	 sub	 cx,si		; ... minus current entry

	 mov	 di,si		; Current entry is destination
	 add	 si,@FLEXROM_STRLEN ; Next entry is source

     rep movs	 FLEXROM_TBL[di].LO,FLEXROM_TBL[si].LO ; Move remainder of table

PROC_FF_ERR4:
	 cmp	 FLEXROM_LEN,0	; Anything left to be FLEXed?
	 jne	 short PROC_FF_ERR5 ; Jump if so

	 and	 FLEXROM_FLAG,(not @FR_ACTIVE) ; Turn off FLEXROM

PROC_FF_ERR5:

PROC_FF_EXIT:
	 REGREST <gs,fs,es,ds,di,si,cx,bx,ax> ; Restore
	 assume  ds:XGROUP,fs:XGROUP,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROCESS_FLEXFILE endp			; End PROCESS_FLEXFILE procedure
endif				; IF @OEM_FLEXROM
if @OEM_FLEXROM
	 NPPROC  MODIFY_FLEXINFO -- Modify FLEXROM information
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Modify the FLEXROMINTS table.

The FLEXROMINTS structure is set up with a source of C000.
Unfortunately, the BIOS source has been determined to be somewhere else,
and we now have to reflect that change to the FLEXROMINTS structure.

Trundle through each entry in FLEXROMINTS,
if it is a video entry, modify it to reflect new video source location.

On entry:
SI	=	FLEXROM_TBL index for video ROM

|
	 REGSAVE <bx,cx,si,fs> ; Save registers

	 mov	 bx,seg XGROUP	; Gain addresability to FLEXROMINTS
	 mov	 fs,bx		; ... via FS
	 assume  fs:XGROUP	; Tell the assembler about it

	 mov	 cx,@FLEXROM_RESOURCE_MAX ; Set FLEXROMINTS counter
	 xor	 bx,bx		; Zero pointer into FLEXROMINTS

	 mov	 si,FLEXROM_TBL[si].FLEX_SRC ; Get our source address

MODIFY_FLEX_NEXT:
	 cmp	 [bx].FLEXROMINTS.FLEXROMINT_NUM,@FLEX_UNUSED ; Izit unused?
	 je	 short MODIFY_FLEX_LOOP ; Jump if so

; Modify all FLEXROMINT source variables

	 test	 [bx].FLEXROMINTS.FLEXROMINT_FLAG,@ROMINT_VGA ; Izit a VGA?
	 jz	 short MODIFY_FLEX_LOOP ; Jump if not

	 mov	 [bx].FLEXROMINTS.FLEXROMINT_SRC,si ; Set new source

MODIFY_FLEX_LOOP:
	 add	 bx,@FLEXROMINT_STRLEN ; Point to next entry

	 loop	 MODIFY_FLEX_NEXT ; Try next entry

	 REGREST <fs,si,cx,bx>	; Restore registers
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MODIFY_FLEXINFO endp			; End MODIFY_FLEXINFO procedure
endif				; IF @OEM_FLEXROM
	 FPPROC  CHECK_ARGS -- Check the Command Line Arguments
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es,fs>	; Save segment registers

	 cld			; String ops forwardly

	 push	 seg PGROUP	; Get segment of PGROUP
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 seg XGROUP	; Setup FS for data references
	 pop	 fs
	 assume  fs:XGROUP	; Tell the assembler about it

; Switch to a local stack in XGROUP

	 mov	 OLDARGSTK_VEC.VSEG,ss ; Save to restore later
	 mov	 OLDARGSTK_VEC.VOFF,sp ; ...

	 lss	 sp,NEWARGSTK_VEC ; SS:SP ==> new top of stack
	 assume  ss:nothing	; Tell the assembler about it

	 lds	 si,RH_VEC	; DS:SI ==> request header
	 assume  ds:nothing	; Tell the assembler about it

	 lds	 si,ds:[si].INIT_CMD_VEC ; DS:SI ==> command line args
	 assume  ds:nothing	; Tell the assembler about it
if @OEM_STATE
	 call	 FCN_AUTO	; Mark initial state as AUTO
else
	 call	 FCN_ON 	; Mark initial state as ON
endif				; IF @OEM_STATE
	 mov	 si,DRVPATH_END ; Get end+1 of driver name
CHECK_ARGS_INIT:		; Initial scan to skip over file name
	 lodsb			; Get the next byte

	 cmp	 al,CR		; If CR, then no arguments
	 je	 near ptr CHECK_ARGS_VALID ; Use defaults

	 cmp	 al,LF		; If LF, then no arguments
	 je	 near ptr CHECK_ARGS_VALID ; Use defaults

	 cmp	 al,' '         ; If a space, then we've reached the end
	 je	 short CHECK_ARGS_SRCH ; Yup

	 and	 al,al		; If zero, we've reached the end
	 jnz	 short CHECK_ARGS_INIT ; Not there as yet, continue looking

CMDCHK_INI:
CHECK_ARGS_SRCH:		; Search for arguments
	 call	 XSKIP_WHITE	; Skip over white space

	 cmp	 al,CR		; Check for terminator
	 je	 near ptr CHECK_ARGS_VALID ; That's all folks

	 cmp	 al,LF		; Check for terminator
	 je	 near ptr CHECK_ARGS_VALID ; That's all folks

	 call	 IZITCOMMENT	; Check for a comment delimiter
	 je	 near ptr CHECK_ARGS_VALID ; That's all folks

	 dec	 si		; Back off to last character

; Search for the argument text

	 xor	 ebx,ebx	; Zero index register
	 mov	 cx,NCMDARGS	; # arguments to check
CHECK_ARGS_NEXT:
	 mov	 di,CMDARG_TAB[ebx*(type CMDARG_TAB)] ; Get location of text

	 REGSAVE <cx,si,es>	; Save for a moment

	 push	 seg XGROUP	; Get CMDARG_TAB segment
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 mov	 cx,CMDARG_LEN[ebx*(type CMDARG_LEN)] ; Get length
    repe cmps	 ds:[si].LO,CMDARG_TAB.LO[di] ; Compare 'em
	 REGREST <es,si,cx>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 jne	 short CHECK_ARGS_NEXT1 ; Not this one

; Mark as found only if the next character is a valid separator

	 mov	 di,CMDARG_LEN[ebx*(type CMDARG_LEN)] ; Get length of matching command
	 add	 di,si		; Add into starting offset
	 mov	 al,ds:[di]	; Get the next character

	 cmp	 al,'/'         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; Jump if valid

	 cmp	 al,'='         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; Jump if valid

	 call	 IZITCOMMENT	; Check for a comment delimiter
	 je	 short CHECK_ARGS_FOUND ; Jump if valid

	 cmp	 al,' '         ; Check for blank or below
	 jbe	 short CHECK_ARGS_FOUND ; A match
CHECK_ARGS_NEXT1:
	 inc	 ebx		; Skip to next entry

	 loop	 CHECK_ARGS_NEXT ; Jump if more entries to check

; Keyword not found

if @OEM_SYS eq @OEMSYS_HPRS

; Check for size parameter

	 mov	 al,[si]	; Get the first character

	 cmp	 al,'0'         ; Check lower limit of digits
	 jb	 short CHECK_ARGS_UNK ; Too small for that

	 cmp	 al,'9'         ; Check upper limit of digits
	 ja	 short CHECK_ARGS_UNK ; Too big for that

	 test	 CMD_FLAG,@CMD_EXT or @CMD_EMS ; EXT= or EMS= already specified?
	 jz	 short @F	; Jump if neither

	 push	 offset YGROUP:MSG_CMDCHK_EMSEXT ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 CHECK_ARGS_ERR ; Join common error code

@@:
	 call	 FCN_EMS_SUB	; Treat as EMS=
	 jc	 short CHECK_ARGS_ERR ; Jump if too large

	 or	 CMD_FLAG,@CMD_EMS ; Mark as EMS= specified

	 jmp	 CHECK_ARGS_SRCH ; Continue on
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

CHECK_ARGS_UNK:
	 lea	 di,YGROUP:MSG_UNK ; YGROUP:DI ==> error message
	 call	 DISP_UNK2	; Display it along with unknown keyword at DS:SI
				; Returns CF=1 if user wishes to abort

	 jnc	 CHECK_ARGS_SRCH ; Continue on if user wishes (CF=0)

CHECK_ARGS_ERR:
	 stc			; Indicate an error occurred

	 jmp	 CHECK_ARGS_EXIT ; Join common exit code


CHECK_ARGS_FOUND:
	 mov	 LASTKEY,si	; Save starting offset
	 add	 si,CMDARG_LEN[ebx*(type CMDARG_LEN)] ; Skip over the keyword

	 call	 CMDARG_ACT[ebx*(type CMDARG_ACT)] ; Take appropriate action
	 jc	 short CHECK_ARGS_ERR ; Join common error code

	 jmp	 CHECK_ARGS_SRCH ; Join common tail code


; Everything checked out -- now validate the options

CHECK_ARGS_VALID:
	 push	 seg PGROUP	; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

if @OEM_DEBUG
	 test	 CMD_FLAG,@CMD_XDM ; NODMA specified?
	 jz	 short CHECK_ARGS_VALID1 ; Not this time

	 and	 CMD_FLAG,not @CMD_EXT ; As if not specified
	 or	 CMD_FLAG,@CMD_EMS ; As if specified
if @OEM_EMS
	 mov	 EMMSIZE,0	; ...as EMS=0
endif				; IF @OEM_SIZE
	 mov	 EXTSIZE,0	; In case EXT= specified
	 mov	 SWPSIZE,0	; Force SWAP=0

if @OEM_SYS ne @OEMSYS_HPRS
if @OEM_SYS ne @OEMSYS_OLI
if @OEM_SYS ne @OEMSYS_OL2
	 call	 FCN_NOLOW	; No low  DOS memory allowed
endif				; IF @OEM_SYS ne @OEMSYS_OL2
endif				; IF @OEM_SYS ne @OEMSYS_OLI
endif				; IF @OEM_SYS ne @OEMSYS_HPRS

if @OEM_HIFILL
	 call	 FCN_NOHIGH	; No high DOS memory allowed
endif				; IF @OEM_HIFILL

	 and	 LCL_FLAG,not @LCL_LML ; No low memory load allowed
CHECK_ARGS_VALID1:
endif				; IF @OEM_DEBUG

if @OEM_WTK
; Ensure W=ON and AUTO inactive ==> AUTO active

	 test	 GLB_FLAG,@GLB_WTK ; Is the Weitek active?
	 jz	 short CHECK_ARGS_VALID2 ; Not this time

	 test	 GLB_FLAG,@GLB_AUTO ; Is our initial state AUTO inactive?
	 jnz	 short CHECK_ARGS_VALID1A ; Yes, mark as AUTO active

; Ensure W=ON and OFF ==> W=OFF

	 test	 GLB_FLAG,@GLB_ON ; Is our initial state ON?
	 jnz	 short CHECK_ARGS_VALID2 ; Yes, keep on trucking

	 push	 offset YGROUP:MSG_WTKOFF ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 and	 GLB_FLAG,not @GLB_WTK ; Mark as inactive

	 jmp	 short CHECK_ARGS_VALID2 ; Join common code

CHECK_ARGS_VALID1A:
	 or	 GLB_FLAG,@GLB_ON ; Mark as AUTO active
endif				; IF @OEM_WTK
CHECK_ARGS_VALID2:

if @OEM_XMS

; Ensure HMA is reserved unless there is a previous VDISK or
; EXT= specified and EXTSIZE < 64.

	 cmp	 PRVSIZE,0	; Is there a previous VDISK?
	 jne	 short CHECK_ARGS_VALID3 ; Jump if so

	 test	 XMS_FLAG,mask $XMS_XHMA ; HMA permanently unavailable?
	 jnz	 short CHECK_ARGS_VALID3 ; Yes

	 test	 CMD_FLAG,@CMD_EXT ; EXT= specified?
	 jz	 short @F	; Not this time

	 cmp	 EXTSIZE,64	; Ensure big enough
	 jb	 short CHECK_ARGS_VALID3 ; Not this time
@@:
	 mov	 HMASIZE,64	; Grab the entire area
endif				; IF @OEM_XMS

CHECK_ARGS_VALID3:
; Copy path and default virtual device name for Windows 3 support
; Also needed to read 386LOAD.CFG for 'M' flagged entries.

	 push	 seg XGROUP	; Prepare to address XGROUP
	 pop	 ds		; ... via DS
	 assume  ds:XGROUP	; Tell the assembler

	 lea	 si,FLEXFILE_DPFE ; drive:\path\ from device name
	 lea	 di,VIRT_DEV_DPFE ; ES:DI ==> local buffer

	 mov	 cx,PATHSTEM_LEN ; Length of path prefix
	 jcxz	 @F		; Jump if no path

S16 rep  movs	 <VIRT_DEV_DPFE[di],FLEXFILE_DPFE[si]> ; Copy to VxD name
@@:
;;;;;;;  dec	 di		; Back off to trailing zero

	 call	 READ_CFG	; Read in the 386LOAD.CFG file

if @OEM_WIN3
	 test	 CM3_FLAG,@CM3_NOWIN3 ; Disable support for Windows 3?
	 jnz	 near ptr CHECK_ARGS_VALID4 ; Jump if so

	 mov	 SWPSIZE,0	; Force SWAP=0

; Pick either the stock VXD name or the alternate supplied by the user

	 push	 seg XGROUP	; Get segment of VIRT_DEV_NAME
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 cx,ALT_VIRT_DEV_NAME_LEN ; Get length of alternate VXD filename
	 or	 cx,cx		; Was an alternate name specified?
	 jz	 short CHECK_ARGS_WIN3D ; No, copy stock name to our path

	 lea	 di,VIRT_DEV_DPFE ; ES:DI ==> local buffer
	 mov	 si,ALT_VIRT_DEV_NAME ; DS:SI ==> d:\path\vxdname.ext

	 push	 ds		; Save around the move
	 mov	 ds,PROF_SEG	; Get the segment
	 assume  ds:nothing	; Tell the assembler about it

S16  rep movs	 <VIRT_DEV_DPFE[di],[si].LO> ; Copy it
	 sub	 al,al		; A trailing NUL
S16	 stosb			; Terminate the VXD filename

	 pop	 ds		; Restore
	 assume  ds:XGROUP	; Tell the assembler

	 mov	 DEVDRV.DD_INTR,offset PGROUP:DEV_INTR3 ; Mark as new intr handler
	 or	 DEVDRV.DD_ATTR,DRV_ATTR_IOCTL ; Mark as supporting IOCTL

	 jmp	 short CHECK_ARGS_VALID3B ; Rejoin common flow
				; Bypass file existance check

CHECK_ARGS_WIN3D:
	 lea	 si,VIRT_DEV_NAME ; DS:SI ==> filename.ext to use
	 mov	 cx,VIRT_DEV_NAME_LEN ; CX = length of ...
				      ; (including trailing 0)
S16  rep movs	 <VIRT_DEV_DPFE[di],VIRT_DEV_NAME[si].LO> ; Copy it

; Ensure the file exists -- if not, set NOWIN3 attribute

	 push	 OLDINT24_VEC	; Save old INT 24h handler's address
	 call	 INST24 	; Install local INT 24h handler

	 push	 ds		; Save for a moment

	 push	 seg PGROUP	; Get segment of VIRT_DEV_DPFE
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 al,@OPEN_R	; Function code for read-only access
	 DOSCALL @OPENF2,VIRT_DEV_DPFE ; Attempt to open it
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it
	 jnc	 short @F	; Jump if successful

	 call	 FCN_NOWIN3	; Mark as not providing support for Windows 3
				; Note ES = PGROUP

	 cmp	 ALT_VIRT_DEV_NAME_LEN,0 ; Are we using an alternate VXD?
	 jz	 short CHECK_ARGS_WIN3F ; No, use MSG_NOVXD

	 push	 offset YGROUP:MSG_NOALTVXD ; Pass address of error message

	 jmp	 short CHECK_ARGS_WIN3G ; Rejoin common code

CHECK_ARGS_WIN3F:
	 push	 offset YGROUP:MSG_NOVXD ; Pass address of error message

CHECK_ARGS_WIN3G:
	 call	 YMSGOUT2	; Display YGROUP message

	 call	 FKEYWAIT	; Wait for an acknowledgement
				; Return with key in AX

	 jmp	 short CHECK_ARGS_VALID3A ; Join common code

@@:
	 mov	 bx,ax		; Copy to handle register
	 DOSCALL @CLOSF2	; Close the opened file

	 mov	 DEVDRV.DD_INTR,offset PGROUP:DEV_INTR3 ; Mark as new intr handler
	 or	 DEVDRV.DD_ATTR,DRV_ATTR_IOCTL ; Mark as supporting IOCTL
CHECK_ARGS_VALID3A:
	 call	 REST24 	; Restore INT 24h handler
	 pop	 OLDINT24_VEC	; Restore old INT 24h handler's address
CHECK_ARGS_VALID3B:
endif				; IF @OEM_WIN3

CHECK_ARGS_VALID4:

if @OEM_DPMI
	 test	 LCL_FLAG,@LCL_DPMI ; Load module DPMI services requested?
	 jz	 short @F	; Jump if not

	 and	 CMD_FLAG,not @CMD_XDPMI ; Turn off any NODPMI setting
@@:

; Calculate and save the byte size of each old PM data area

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 short CHECK_ARGS_VALID5 ; Jump if so

	 xor	 eax,eax	; Initial size

	 test	 CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	 jz	 short @F	; Jump if not

	 add	 eax,256/8	; Size of SIRBCUR table
@@:
	 add	 eax,(256/8)*(type DPMI_CPIHOOK)
	 add	 eax,( 32/8)*(type DPMI_CPFHOOK)
	 add	 eax,( 32/8)*(type DPMI_CVFHOOK)
	 add	 eax,256*(type PMINT_FVECS) + 256*(type PMINT_DVECS)
	 add	 eax, 32*(type PMFLT_FVECS) +  32*(type PMFLT_DVECS)
	 add	 eax, 32*(type VMFLT_FVECS) +  32*(type VMFLT_DVECS)
	 add	 eax,type LAST_DPMI_DS
	 add	 eax,type LAST_DPMI_ES
	 add	 eax,type LAST_DPMI_FS
	 add	 eax,type LAST_DPMI_GS
	 add	 eax,type I31_FLAG
	 add	 eax,type DPMITYPE
	 add	 eax,type DBGCTL
	 add	 eax,type DBGSTA
	 add	 eax,4*(type DBGREGS)
	 add	 eax,type DBGDR7
	 add	 eax,@DPMI_BOUND-1 ; Round up to next
	 and	 eax,not (@DPMI_BOUND-1) ; ... boundary for ALLOCMEM
	 mov	 DPMIOLDPM_SIZ,eax ; Save for later use
CHECK_ARGS_VALID5:
endif				; IF @OEM_DPMI

; If SHADOWRAM is specified, set all the bits in NOSCAN_MAP
; to avoid scanning the memory from A000 to 10000.

	 call	 SET_NOSCAN	; Set all bits in NOSCAN if C&T SHADOWRAM

CHECK_ARGS_VALID6:

; If the user didn't specify any DOS stacks, use a default setting of
; STACKS=6[,128] with all HW interrupts hooked.

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jnz	 short CHECK_ARGS_VALID7 ; Jump if so

	 cmp	 DSTK_CNT,0	; Wuzit explicitly disabled?
	 je	 short CHECK_ARGS_VALID7 ; Jump if so

if @REF_STRUC_VER ge 0700h	; Ensure that the WIN3 refdata is up to
				; the level which requires SOP
; Note DS:XGROUP, ES:PGROUP, and FS:XGROUP

	 lea	 si,DEF_STACKS	; DS:SI ==> default stacks line
	 call	 FCN_STACKS	; Enable stacks
else
	 mov	 DSTK_CNT,0	; Ensure disabled for later reference
endif				; IF @REF_STRUC_VER ge 0700h
	 or	 DSTK_FLAG,mask $DSTK_GLBOFF ; Mark as globally off
CHECK_ARGS_VALID7:
	 call	 PATCH_WBINVD	; Replace all *CACHE_INVD calls with WBINVD

; Disable MCE checking unless explicitly requested

	 test	 CM4_FLAG,@CM4_MCE ; Izit to be enabled?
	 jnz	 short @F	; Jump if so

	 and	 CPUFET_FLAG,not (mask $CPUFET_MCE) ; Mark as not supported
@@:
	 clc			; Indicate all went well

	 assume  ds:nothing	; Tell the assembler about it

CHECK_ARGS_EXIT:
	 lss	 sp,OLDARGSTK_VEC ; SS:SP ==> old top of stack
	 assume  ss:nothing	; Tell the assembler about it

	 REGREST <fs,es,ds>	; Restore
	 assume  ds:nothing,es:nothing,fs:nothing ; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller with carry flag

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	 NPPROC  SET_NOSCAN -- Set NOSCAN Bitmap
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If SHADOWRAM is specified, set all the bits in NOSCAN_MAP
to avoid scanning the memory from A000 to 10000.

|

	 REGSAVE <ax,cx,di,es>	; Save registers

; Because some systems with local bus video have the video ROM
; at C000 as read-write, we check for that here and set the NOSCAN
; bits for that ROM.

	 mov	 ax,0C000h	; Get the video ROM segment
	 mov	 es,ax		; Address it
	 assume  es:RGROUP	; Tell the assembler about it

	 cmp	 ROMSIGN,@ROMSIGN ; Izit a ROM?
	 jne	 short SET_NOSCAN_XROM ; Jump if not

	 movzx	 cx,ROMLEN	; Get the ROM length in 512 bytes
	 shr	 cx,12-9	; Convert from 512 bytes to 4KB (rounding down)
	 jz	 short SET_NOSCAN_XROM ; Jump if it's tiny

	 mov	 ax,seg JGROUP	; Get segment of NOSCAN_MAP
	 mov	 es,ax		; Address it
	 assume  es:JGROUP	; Tell the assembler about it

	 mov	 ax,(0C000h-0A000h) shr (12-4) ; Get bit index for C000
SET_NOSCAN_NEXT:
	 bts	 NOSCAN_MAP.ELO,ax ; Mark as not to be scanned
	 inc	 ax		; Skip to next bit index

	 loop	 SET_NOSCAN_NEXT ; Jump if more 4KB blocks to set
SET_NOSCAN_XROM:
	 mov	 ax,seg PGROUP	; Get segment of CM2_FLAG
	 mov	 es,ax		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 test	 CM2_FLAG,@CM2_SHD ; Izit C&T shadow RAM?
	 jz	 short SET_NOSCAN_EXIT ; Jump if not

	 mov	 ax,seg JGROUP	; Get segment of NOSCAN_MAP
	 mov	 es,ax		; Address it
	 assume  es:JGROUP	; Tell the assembler about it

	 mov	 cx,(384/4)/8	; Get # bytes in the table
	 mov	 al,-1		; Set all the bits
	 lea	 di,NOSCAN_MAP	; ES:DI ==> NOSCAN table
     rep stos	 NOSCAN_MAP[di] ; Set all the bits
SET_NOSCAN_EXIT:
	 REGREST <es,di,cx,ax>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_NOSCAN endp 		; End SET_NOSCAN procedure
	 NPPROC  GET_CMDARGS -- Parse Command Line For Arguments
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Parse the command line at DS:SI for arguments of the
form xxxx L llll (length format) or  xxxx-yyyy (range format)

On entry:

DS:SI	 ==>	 command line

On exit:

DS:SI	 ==>	 command line (updated)
BP	 =	 1st parameter
AX	 =	 2nd parameter as length (even if specified as range)
CF	 =	 1 if something went wrong
	 =	 0 otherwise

|

	 REGSAVE <bx,cx,dx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,SEPARATOR	; Must be
	 lea	 dx,YGROUP:MSG_SEP ; In case it's unequal
	 jne	 near ptr GET_CMDARGS_ERR ; Not this time

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to start of segment

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short GET_CMDARGS_STC ; Jump if too large

	 mov	 bp,ax		; Save for later use

	 call	 XSKIP_WHITE	; Skip over more white space

	 mov	 bl,al		; Save the marker

	 cmp	 al,'-'         ; Check the marker
	 je	 short GET_CMDARGS_RNG ; It's a range marker

	 cmp	 al,'l'         ; Length marker?
	 je	 short GET_CMDARGS_RNG ; Yes

	 lea	 dx,YGROUP:MSG_SEP ; In case it's not auto include

	 test	 NRD_FLAG,@NRD_INC ; Allow auto INCLUDE= ?
	 jz	 short GET_CMDARGS_ERR ; No, so that's an error

; Convert the number in BP from base 16 to base 10

	 mov	 cx,4		; # digits to convert
	 xor	 ax,ax		; Set accumulator to zero
GET_CMDARGS_CNV:
	 mov	 dx,10		; Multiplier
	 mul	 dx		; Shift over by 10

	 rol	 bp,4		; Rotate out another digit
	 mov	 dx,bp		; Copy digits
	 and	 dx,0Fh 	; Isolate low-order digit
	 add	 ax,dx		; Add into accumulator

	 loop	 GET_CMDARGS_CNV ; Convert another digit

	 mov	 bp,ax		; Copy back
	 and	 NRD_FLAG,not @NRD_INC ; Clear the flag to indicate a match
	 dec	 si		; Back up to previous character

	 lea	 dx,YGROUP:MSG_INVERR ; In case it's not

	 test	 bp,16-1	; Ensure 16KB boundary
	 jnz	 short GET_CMDARGS_ERR ; It's not, so that's an error

	 jmp	 short GET_CMDARGS_CLC ; Join common code

GET_CMDARGS_RNG:
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to start of segment

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short GET_CMDARGS_STC ; Jump if too large

	 cmp	 al,0FFh	; Izit just below a 4KB boundary?
	 jne	 short GET_CMDARGS_RNG1 ; Not this time

	 inc	 ax		; Increment to 4KB boundary
GET_CMDARGS_RNG1:

; If the user specified a range, convert it to length

	 cmp	 bl,'l'         ; Check the marker
	 je	 short GET_CMDARGS_LEN ; It's already a length marker

	 sub	 ax,bp		; Convert range to length
GET_CMDARGS_LEN:

; Ensure both starting segment and length are on a 512-byte boundary

	 lea	 dx,YGROUP:MSG_INVERR ; In case it's not

	 test	 bp,(512/16)-1	; Check boundary
	 jnz	 short GET_CMDARGS_ERR ; It isn't

	 test	 ax,(512/16)-1	; Check boundary
	 jnz	 short GET_CMDARGS_ERR ; It isn't
GET_CMDARGS_CLC:
	 clc			; Indicate all went well

	 jmp	 short GET_CMDARGS_EXIT ; Join common exit code

GET_CMDARGS_ERR:
	 push	 dx		; Pass offset of error message
	 call	 YMSGOUT2	; Display YGROUP message
GET_CMDARGS_STC:
	 stc			; Indicate we had a problem
GET_CMDARGS_EXIT:
	 REGREST <dx,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_CMDARGS endp		; End GET_CMDARGS procedure
	 NPPROC  LOWERCASE -- Convert AL to Lowercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 cmp	 al,40h 	; Test for conversion of alpha to lower case
	 jb	 short LOWERCASE_EXIT ; Not this time

	 or	 al,20h 	; Convert alpha to lower case
LOWERCASE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	 NPPROC  BASE2BIN -- Convert From Specified Base to Binary
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BASE2BIN -- Convert the number at DS:SI in base CX to binary.
The converted # is returned in AX.

On entry:

CX	 =	 number base
DS:SI	 ==>	 input save area

On exit:

CF	 =	 1 if overflow
	 =	 0 if OK
AX	 =	 converted #

|

	 REGSAVE <bx,dx,di,es>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 xor	 bx,bx		; Zero accumulator

	 push	 seg XGROUP	; Move NUMBERS_LO segment to ES for SCASB
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it
BASE2BIN_LOOP:
	 lea	 di,NUMBERS_LO	; Get address of number conversion table
	 push	 cx		; Save number base (and table length)
   repne scas	 NUMBERS_LO[di] ; Look for the character
	 pop	 cx		; Restore number base
	 jne	 short BASE2BIN_DONE ; Not one of ours

	 sub	 di,1+offset es:NUMBERS_LO ; Convert to origin 0
	 mov	 ax,bx		; Copy old to multiply by base

	 mul	 cx		; Shift over accumulated #
	 jnc	 short BASE2BIN_ADD ; Jump if within range

; Allow overflow if 'Keyword=10000'

	 dec	 dx		; Check for DX=1
	 jnz	 short BASE2BIN_OVF ; Not this time

	 and	 di,di		; Check for new digit
	 jnz	 short BASE2BIN_OVF ; Not this time

	 cmp	 ds:[si].LO,'0' ; Check against lower range
	 jb	 short BASE2BIN_ADD ; Jump if not a digit

	 cmp	 ds:[si].LO,'9' ; Check against upper range
	 jbe	 short BASE2BIN_OVF ; Jump if it's a digit
BASE2BIN_ADD:
	 mov	 bx,ax		; Copy back
	 add	 bx,di		; Add in new #
	 jc	 short BASE2BIN_OVF ; Jump if out of range

	 lodsb			; Get next digit
	 call	 LOWERCASE	; Convert to lowercase

	 jmp	 BASE2BIN_LOOP	; Go around again

BASE2BIN_OVF:
if @OEM_SYS ne @OEMSYS_HPRS
	 mov	 si,LASTKEY	; DS:SI ==> last keyword
	 lea	 di,YGROUP:MSG_OVF ; YGROUP:DI ==> error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI
endif				; IF @OEM_SYS ne @OEMSYS_HPRS
	 stc			; Indicate something went wrong

	 jmp	 short BASE2BIN_EXIT ; Join common exit code

BASE2BIN_DONE:
	 dec	 si		; Back off to previous character
	 mov	 ax,bx		; Place result in accumulator

	 clc			; Indicate all went well
BASE2BIN_EXIT:
	 REGREST <es,di,dx,bx>	; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller with number in AX

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BASE2BIN endp			; End BASE2BIN procedure
	 NPPROC  BASE2BIND -- Convert From Specified Base to Binary
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BASE2BIND -- Convert the number at DS:SI in base CX to binary.
The converted # is returned in EAX.

On entry:

CX	 =	 number base
DS:SI	 ==>	 input save area

On exit:

CF	 =	 1 if overflow
	 =	 0 if OK
EAX	 =	 converted #

|

	 REGSAVE <ebx,ecx,edx,edi,es> ; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 xor	 ebx,ebx	; Zero accumulator
	 movzx	 ecx,cx 	; Zero to use as dword

	 push	 seg XGROUP	; Move NUMBERS_LO segment to ES for SCASB
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it
BASE2BIND_LOOP:
	 lea	 edi,NUMBERS_LO ; Get address of number conversion table
	 push	 cx		; Save number base (and table length)
   repne scas	 NUMBERS_LO[di] ; Look for the character
	 pop	 cx		; Restore number base
	 jne	 short BASE2BIND_DONE ; Not one of ours

	 sub	 di,1+offset es:NUMBERS_LO ; Convert to origin 0
	 mov	 eax,ebx	; Copy old to multiply by base

	 mul	 ecx		; Shift over accumulated #
	 jc	 short BASE2BIND_OVF ; Jump if out of range

	 mov	 ebx,eax	; Copy back
	 add	 ebx,edi	; Add in new #
	 jc	 short BASE2BIND_OVF ; Jump if out of range

	 lodsb			; Get next digit
	 call	 LOWERCASE	; Convert to lowercase

	 jmp	 BASE2BIND_LOOP ; Go around again

BASE2BIND_OVF:
if @OEM_SYS ne @OEMSYS_HPRS
	 mov	 si,LASTKEY	; DS:SI ==> last keyword
	 lea	 di,YGROUP:MSG_OVF ; YGROUP:DI ==> error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI
endif				; IF @OEM_SYS ne @OEMSYS_HPRS
	 stc			; Indicate something went wrong

	 jmp	 short BASE2BIND_EXIT ; Join common exit code

BASE2BIND_DONE:
	 dec	 si		; Back off to previous character
	 mov	 eax,ebx	; Place result in accumulator

	 clc			; Indicate all went well
BASE2BIND_EXIT:
	 REGREST <es,edi,edx,ecx,ebx> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller with number in AX

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BASE2BIND endp			; End BASE2BIND procedure
	 NPPROC  ABORT_IGNORE -- ABORT_IGNORE procedure
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT |

	Common routine to query the user about aborting.

On Entry:
Nothing

On Exit:
If user aborted:
	CF=1 if user aborted
	YGROUP:MSG_INVLIDOK = 1
If user does not wish to abort:
	CF=0 If user did not wish to abort
	YGROUP:MSG_INVLIDOK = 0

|

	 REGSAVE <es,ax>	; Save registers

	 push	 seg PGROUP	; Address INVALID_OK message
	 pop	 es		; Message is in DS, must use ES
	 assume  es:PGROUP	; Tell assembler

	 push	 offset YGROUP:MSG_INVALIDOK ; Is the invalid code ok?
	 call	 YMSGOUT2	; Display message (question)

	 mov	 al,@KEYINE	; Wait for a key w echo
	 DOSCALL @CKEYIN	; Clear keyboard input buffer and wait for a key

	 push	 offset YGROUP:MSG_CRLF
	 call	 YMSGOUT2	; Move cursor

	 call	 UPPERCASE	; Convert AL to upper case
	 cmp	 al,@NATL_ABORT ; Did they select abort
	 sete	 al		; Set to 1 if aborting
	 mov	 INVALID_OK,al	; Record if they where aborting or not
	 shr	 al,1		; Move abort setting into carry flag

	 REGREST <ax,es>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
ABORT_IGNORE	 endp			; End ABORT_IGNORE procedure

	 NPPROC  PATCH_WBINVD -- Replace CALL *CACHE_INVD with WBINVD
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we didn't detect a Gateway motherboard and INVD / WBINVD is supported
(contraindicated by Gateway motherboard and/or NOGATE), replace all calls
to CACHE_INVD and NRCACHE_INVD with WBINVD (@OPCOD_WBINVD = 0Fh,09h).

It's far easier to modify the code by putting in the shorter WBINVD
plus NOP over a CALL, although in most cases we'll want to patch it,
since WBINVD works on every other system in the known universe.

On entry:
	 Nothing.

On exit:
	 Nothing.

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save

	 mov	 ax,seg PGROUP	; Prepare to address data segment
	 mov	 es,ax		; Address it
	 assume  es:PGROUP	; Tell the assembler

; Note that we don't test for 486; someone could make a 386 supporting
; WBINVD (fat chance, but we'll be ready).
	 test	 CPUFET_FLAG,@CPUFET_INVD ; OK to use WBINVD?
	 jz	 short PATWB_EXIT ; Jump if not

	 mov	 ax,seg XGROUP	; Prepare to address data segment
	 mov	 ds,ax		; Address it
	 assume  ds:XGROUP	; Tell the assembler

	 sub	 si,si		; Address start of table
	 mov	 ax,offset XGROUP:WBPAT_ENDTAB ; Get end of table
	 sub	 ax,offset XGROUP:WBPAT_TAB ; Get length in bytes
	 mov	 cl,size WBPAT_STR ; Size of record
	 div	 cl		; AL = number of records
	 cbw			; AX = count
	 mov	 cx,ax		; Number to patch
	 jcxz	 PATWB_EXIT	; Jump if none

	 cld			; Ensure string ops go up
PATWB_NEXT:
	 les	 di,WBPAT_TAB[si].WBPAT_PTR ; Address CALL instruction
	 assume  es:nothing	; Tell the assembler

	 mov	 ax,@OPCOD_WBINVD ; WBINVD instruction (0fh, 09h)
	 stos	 es:[di].ELO	; Blast away

	 mov	 dx,WBPAT_TAB[si].WBPAT_LEN ; Number of bytes to fill
	 sub	 dx,2		; Less WBINVD

	 mov	 al,@OPCOD_NOP	; NOP instruction (90h)
@@:
	 stos	 es:[di].LO	; Blast it in
	 dec	 dx		; Count another one cleared
	 jnz	 short @B	; Go around again

	 add	 si,size WBPAT_STR ; Skip to next entry

	 loop	 PATWB_NEXT	; Go around again

PATWB_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PATCH_WBINVD endp		; End PATCH_WBINVD procedure

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_ARG module

;' $Header:   P:/PVCS/MAX/386MAX/QMAX.ASV   1.3   30 May 1997 10:44:08   BOB  $
	 title	 QMAX -- 386MAX Low DOS Resident Routines
	 page	 58,122
	 name	 QMAX

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Stack   segment STACK,	para-aligned,  stack,  class 'prog'
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment HICODE,	dword-aligned, public, class 'prog'
	       Program segment ZCODE,	para-aligned,  public, class 'zcode'
	       Program segment ECODE,	dword-aligned, public, class 'ecode'
	       Program segment BLINK,	byte-aligned,  public, class 'blink'
	       Data    segment EDATA,	dword-aligned, public, class 'edata'
	       Data    segment VALSEG,	byte-aligned,  public, class 'edata'
	       Data    segment ZDATA,	para-aligned,  public, class 'zdata'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Group FGROUP:
	       Data    segment FIXUP,	    para-aligned, public, class 'fixup'
	       Data    segment FIX_PGROUP,  word-aligned, public, class 'fixup'
	       Data    segment FIXZ_PGROUP, word-aligned, public, class 'fixup'
	       Data    segment FIX_IGROUP,  word-aligned, public, class 'fixup'
	       Data    segment FIXZ_IGROUP, word-aligned, public, class 'fixup'
	       Data    segment FIX_JGROUP,  word-aligned, public, class 'fixup'
	       Data    segment FIXZ_JGROUP, word-aligned, public, class 'fixup'
	       Data    segment FIXUPZ,	    word-aligned, public, class 'fixup'
	       Data    segment FDATA,	dword-aligned, public, class 'fixup'
	       Data    segment FDATZ,	dword-aligned, public, class 'fixup'
	       Group SGROUP:
	       Program segment SCODE,	para-aligned,  public, class 'scode'
	       Group IGROUP:
	       Program segment LCODE,	dword-aligned, public, class 'icode'
	       Data    segment LDATA,	dword-aligned, public, class 'icode'
	       Program segment LCODZ,	dword-aligned, public, class 'icode'
	       Program segment ICODE,	dword-aligned, public, class 'icode'
	       Data    segment IDATA,	dword-aligned, public, class 'idata'
	       Data    segment ACTSEG,	word-aligned,  public, class 'idata'
	       Data    segment IDATZ,	dword-aligned, public, class 'idata'
	       Group JGROUP:
	       Program segment JCOD0,	 para-aligned, public, class 'jcode'
	       Program segment JCODE,	dword-aligned, public, class 'jcode'
	       Data    segment JDATA,	dword-aligned, public, class 'jcode'
	       Program segment JCODZ,	dword-aligned, public, class 'jcode'
	       Group DLGROUP:
	       Program segment DLCODE,	para-aligned, public, class 'dlcode'
	       Data    segment DLDATA,	word-aligned, public, class 'dlcode'
	       Data    segment DLDATZ,	dword-aligned, public, class 'dlcode'
	       Group DL2GROUP:
	       Program segment DL2CODE, para-aligned, public, class 'dl2code'
	       Data    segment DL2DATA, word-aligned, public, class 'dl2code'
	       Data    segment DL2DATZ, dword-aligned, public, class 'dl2code'
	       Group XGROUP:
	       Program segment XCODE,	byte-aligned,  public, class 'xcode'
	       Data    segment XDATA,	dword-aligned, public, class 'xdata'
	       Data    segment SEG_LEN, word-aligned,  public, class 'xdata'
	       Data    segment SEG_ACT, word-aligned,  public, class 'xdata'
	       Data    segment SEG_TAB, word-aligned,  public, class 'xdata'
	       Data    segment WBPAT_SEG, word-aligned, public, class 'xdata'
	       Data    segment WBPAT_END, word-aligned, public, class 'xdata'
	       Data    segment RAM_EXT, para-aligned,  public, class 'xdata'
	       Group YGROUP:
	       Data    segment YDATA,	dword-aligned, public, class 'ydata'
	       Data    segment YDATZ,	para-aligned,  public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

@WAIT8042 equ	 12		; Wait counter for 8042 timeout

ARG_STR  struc

ARG_BP	 dw	 ?		; Caller's BP
ARG_CSIP dd	 ?		; Caller's return address
ARG_FLG  dw	 ?		; Caller's flags

ARG_STR  ends

.386p
.xlist
	 include MASM.INC
	 include EMM2CALL.INC
	 include BITFLAGS.INC
	 include DEVDRV.INC
	 include 8255.INC
	 include 8259.INC
	 include 386.INC
	 include PTR.INC
	 include MASM5.MAC
	 include DEVMAC.INC
	 include OPCODES.INC
NOVER_HTU = 1
	 include VERSION.INC
	 include PNP.INC

	 include QMAX_DTE.INC
	 include QMAX_OEM.INC

if @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 VERS_HP:abs
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
.list

PGROUP	 group	 STACK,CODE,HICODE,BLINK,ZCODE,ECODE,EDATA,VALSEG,ZDATA,NCODE,NDATA
FGROUP	 group	 FIXUP,FIX_PGROUP,FIXZ_PGROUP,FIX_IGROUP,FIXZ_IGROUP,FIX_JGROUP,FIXZ_JGROUP,FIXUPZ,FDATA,FDATZ
SGROUP	 group	 SCODE
IGROUP	 group	 LCODE,LDATA,LCODZ,ICODE,IDATA,ACTSEG,IDATZ
JGROUP	 group	 JCOD0,JCODE,JDATA,JCODZ
DLGROUP  group	 DLCODE,DLDATA,DLDATZ
DL2GROUP group	 DL2CODE,DL2DATA,DL2DATZ
XGROUP	 group	 XCODE,XDATA,SEG_LEN,SEG_ACT,SEG_TAB,WBPAT_SEG,WBPAT_END,RAM_EXT
YGROUP	 group	 YDATA,YDATZ


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKers need to have
; a stack segment.

STACK	 segment use16 para stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  cs:PGROUP,ds:PGROUP

if @OEM_WIN3
	 extrn	 IIS_MAX:tbyte
endif				; IF @OEM_WIN3
	extrn	GET_WINVXD_VEC:far

HICODE	 ends			; End HICODE segment


ZCODE	 segment use16 para public 'zcode' ; Start ZCODE segment
ZCODE	 ends			; End ZCODE segment


BLINK	 segment use16 byte public 'blink' ; Start BLINK segment
BLINK	 ends			; End BLINK segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 ENTERVM:near

ECODE	 ends			; End ECODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
EDATA	 ends			; End EDATA segment


VALSEG	 segment use16 byte public 'edata' ; Start VALSEG segment
VALSEG	 ends			; End VALSEG segment


ZDATA	 segment use16 para public 'zdata' ; Start ZDATA segment
	 assume  ds:PGROUP

	 public  ZLDATA
ZLDATA	 label	 byte

ZDATA	 ends			; End ZDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 INIT:far
if @OEM_EMS
	 extrn	 INIT2:far
	 extrn	 DEV_STR2:far
endif				; IF @OEM_EMS

NCODE	 ends			; End NCODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
NDATA	 ends			; End NDATA segment


FIXUP	 segment use16 para public 'fixup' ; Begin FIXUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 public  FIXUP_LAST_CS2, FIXUP_LAST_CSIG, FIXUP_LAST_CSJG
FIXUP_LAST_CS2	 dw	DTE_CS2 	; Selector last used for PGROUP
FIXUP_LAST_CSIG  dw	DTE_CSIG	; Selector last used for IGROUP
FIXUP_LAST_CSJG  dw	DTE_CSJG	; Selector last used for JGROUP

FIXUP	 ends			; End FIXUP segment


FIX_PGROUP segment use16 word public 'fixup' ; Begin FIX_PGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 public  FIXTAB_PGROUP
FIXTAB_PGROUP	 label	word

FIX_PGROUP ends 		; End FIX_PGROUP segment


FIXZ_PGROUP segment use16 word public 'fixup' ; Begin FIXZ_PGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 public  FIXTABZP
FIXTABZP label	 word		; End of the FICALL/FIJMP selector fixup list

FIXZ_PGROUP ends		; End FIXZ_PGROUP segment


FIX_IGROUP segment use16 word public 'fixup' ; Begin FIX_IGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 public  FIXTAB_IGROUP
FIXTAB_IGROUP	 label	word

FIX_IGROUP ends 		; End FIX_IGROUP segment


FIXZ_IGROUP segment use16 word public 'fixup' ; Begin FIXZ_IGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 public  FIXTABZI
FIXTABZI label	 word		; End of the FICALL/FIJMP selector fixup list

FIXZ_IGROUP ends		; End FIXZ_IGROUP segment


FIX_JGROUP segment use16 word public 'fixup' ; Begin FIX_JGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 public  FIXTAB_JGROUP
FIXTAB_JGROUP	 label	word

FIX_JGROUP ends 		; End FIX_JGROUP segment


FIXZ_JGROUP segment use16 word public 'fixup' ; Begin FIXZ_JGROUP segment
	 assume  ds:FGROUP	; Tell the assembler

	 public  FIXTABZJ
FIXTABZJ label	 word		; End of the FICALL/FIJMP selector fixup list

FIXZ_JGROUP ends		; End FIXZ_JGROUP segment


FIXUPZ segment use16 word public 'fixup' ; Begin FIXUPZ segment
	 assume  ds:FGROUP	; Tell the assembler

	 public  FIXTABZ
FIXTABZ  label	 word		; Mark end of fixups segments

FIXUPZ ends			; End FIXUPZ segment


FDATA	 segment use16 dword public 'fixup' ; Begin FDATA segment
FDATA	 ends			; End FDATA segment


FDATZ	 segment use16 dword public 'fixup' ; Begin FDATZ segment
	 assume  ds:FGROUP

	 public  FDATA_NXT
FDATA_NXT label  dword		; Next available byte in FGROUP
				; after FDATA segment

FDATZ	 ends			; End FDATZ segment


SCODE	 segment use16 para public 'scode' ; Start SCODE segment
SCODE	 ends			; End SCODE segment


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
LCODE	 ends			; End LCODE segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
LDATA	 ends			; End LDATA segment


LCODZ	 segment use16 dword public 'icode' ; Start LCODZ segment
	 assume  ds:IGROUP

	 public  LCODE_NXT
LCODE_NXT label  dword		; Next available byte in IGROUP
				; after LCODE segment

LCODZ	 ends			; End LCODZ segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
ICODE	 ends			; End ICODE segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
IDATA	 ends			; End IDATA segment


ACTSEG	 segment use16 word public 'idata' ; Start ACTSEG segment
ACTSEG	 ends			; End ACTSEG segment


IDATZ	 segment use16 dword public 'idata' ; Start IDATZ segment
IDATZ	 ends			; End IDATZ segment


JCOD0	 segment use16 para public 'jcode' ; Start JCOD0 segment
JCOD0	 ends			; End JCOD0 segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
JCODE	 ends			; End JCODE segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
JDATA	 ends			; End JDATA segment


JCODZ	 segment use16 dword public 'jcode' ; Start JCODZ segment
	 assume  ds:JGROUP	; Tell the assembler

	 public  JCODE_NXT
JCODE_NXT label  dword		; Next available byte in JGROUP
				; after JCODE segment

JCODZ	 ends			; End JCODZ segment


; Note that DLGROUP and DL2GROUP *MUST* follow JGROUP.	We don't need
; selectors for either, but we do need to copy them.  We use JGROUP's
; DS with ESI = ((seg DL?GROUP) - (seg JGROUP)) shl 4.	Initialization of
; DLGROUP data is done only in low DOS.

; Code and data for 4Bxx loadhi emulation
DLCODE	 segment use16 para public 'dlcode' ; Start DLCODE segment
DLCODE	 ends			; End DLCODE segment


DLDATA	 segment use16 word public 'dlcode' ; Start DLDATA segment
DLDATA	 ends			; End DLDATA segment


DLDATZ	 segment use16 dword public 'dlcode' ; Start DLDATZ segment
	 assume  ds:DLGROUP

	 public  DLGROUP_END
DLGROUP_END label word		; Mark end of downloadable code/data

DLDATZ	 ends			; End DLDATZ segment


; Code and data copied to HPDA for Ctrl-break handling on swapfile init
DL2CODE  segment use16 para public 'dl2code' ; Start DL2CODE segment
DL2CODE  ends			; End DL2CODE segment


DL2DATA  segment use16 word public 'dl2code' ; Start DL2DATA segment
DL2DATA  ends			; End DL2DATA segment


DL2DATZ  segment use16 dword public 'dl2code' ; Start DL2DATZ segment
	 assume  ds:DL2GROUP

	 public  DL2GROUP_END
DL2GROUP_END label word 	; Mark end of downloadable code/data

DL2DATZ  ends			; End DL2DATZ segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
XCODE	 ends			; End XCODE segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
XDATA	 ends			; End XDATA segment


SEG_TAB  segment use16 word public 'xdata' ; Start SEG_TAB segment
SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use16 word public 'xdata' ; Start SEG_LEN segment
SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use16 word public 'xdata' ; Start SEG_ACT segment
SEG_ACT  ends			; End SEG_ACT segment


WBPAT_SEG segment use16 word public 'xdata' ; Start WBPAT_SEG segment
	 assume  ds:XGROUP

	 public  WBPAT_TAB
WBPAT_TAB label word		; Mark start of WBINVD patch table

WBPAT_SEG ends			; End WBPAT_SEG segment


WBPAT_END segment use16 word public 'xdata' ; Start WBPAT_END segment
	 assume  ds:XGROUP

	 public  WBPAT_ENDTAB
WBPAT_ENDTAB label word 	; Mark end of table

WBPAT_END ends			; End WBPAT_END segment


RAM_EXT  segment use16 para public 'xdata' ; Start RAM_EXT segment
RAM_EXT  ends			; End RAM_EXT segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
YDATA	 ends			; End YDATA segment


YDATZ	 segment use16 para public 'ydata' ; Start YDATZ segment
YDATZ	 ends			; End YDATZ segment

	 include HMA.INC

CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 DEV_STRA:near
	 extrn	 DEV_INTR:near
if @OEM_WIN3
	 extrn	 DEV_INTR3:near
endif				; IF @OEM_WIN3

;      D E V I C E   H E A D E R

	 DEVMAC  @OEM_IOCTL

if @OEM_EMS
	 public  DEVDRV,DEVDRV2
DEVDRV	 DD_STR  <DEVDRV2-DEVDRV,DRV_ATTR_CHAR,PGROUP:DEV_STRA,PGROUP:INIT,'EMMXXXX0'>
DEVDRV2  DD_STR  <-1,DRV_ATTR_CHAR or DRV_ATTR_IOCTL,PGROUP:DEV_STR2,PGROUP:INIT2,@DEVNAME>
else
	 public  DEVDRV
DEVDRV	 DD_STR  <-1,DRV_ATTR_CHAR or DRV_ATTR_IOCTL,PGROUP:DEV_STRA,PGROUP:INIT,@DEVNAME>
endif				; IF @OEM_EMS

if @OEM_HIFILL
	 org	 40h+6
	 public  LHI_STRA,LHI_STRA_CS
LHI_STRA:
	 db	 @OPCOD_JMPF
	 dw	 PGROUP:DEV_STRA
LHI_STRA_CS dw	 seg PGROUP

	 public  LHI_INTR,LHI_INTR_CS
LHI_INTR:
	 db	 @OPCOD_JMPF
	 dw	 PGROUP:DEV_INTR
LHI_INTR_CS dw	 seg PGROUP

	 public  LHI_END
LHI_END  label	 byte
endif				; IF @OEM_HIFILL

if @OEM_WIN3
	 public  LHI_INTR3,LHI_INTR_CS3
LHI_INTR3:
	 db	 @OPCOD_JMPF
	 dw	 PGROUP:DEV_INTR3
LHI_INTR_CS3 dw  seg PGROUP
endif				; IF @OEM_WIN3

	 DDALIGN DEVDRV 	; Ensure dword-aligned

	 public  LCL_CR3
LCL_CR3  dd	 ?		; Local copy of CR3

	 public  STKPTR
STKPTR	 dd	 ?		; Save area for caller's stack pointer

	public	ORIG_PnP_RMVEC,LO_WINVXD_VEC,LO_PGET_WINVXD_VEC
ORIG_PnP_RMVEC dd ?		; Original PnP RM entry point
LO_WINVXD_VEC dd ?		; Pointer to Windows VxD API Entry Point
LO_PGET_WINVXD_VEC dd PGROUP:GET_WINVXD_VEC ; Pointer to GET_WINVXD_VEC

	 public  LOWGDT
LOWGDT	 LOWGDT_STR <>		; Low DOS memory skeleton GDT

	 public  PLOWSTKZ
PLOWSTKZ dw	 PGROUP:LOWSTKZ ; Pointer to next available entry

; Low memory stack -- used during initialization
; A portion of this area is used by 386MAX LOADHIGH and LOADLOW
; after PSP switch to save the caller's stack

	 public  VIRT_DEV_DPFE
VIRT_DEV_DPFE label byte

	 public  LOWSTK,LOWSTKZ
LOWSTK	 dw	 128 dup ('??')
LOWSTKZ  label	 word

	 public  INFO_CTL,INFO
	 db	 ?		;						      1 1 1 1	   1	  1 1 1 1
INFO_CTL db	 ?		; IOCTL type			    1 2 3 4 5 6 7 8 9 0 1 2 3	   4	  5 6 7 8
	 include QMAXINFO.INC
	 include QMAX_HDM.INC
INFO	 INFO_STR <'386MAX',VERS_H,@HDM_CLOS,VERS_T,VERS_U,seg PGROUP,?,0,0,0,0,0,0,0,0,0,0,0F080h,0F084h,?,?,0>

	 public  INFOSIZE,QMAX_VER,DEVICE_CS
	 public  GLB_FLAG,LOWSIZE,VIDSIZE,OVRSIZE
	 public  EXTSIZE,EMMSIZE,PRGSIZE,MAPSIZE,TOTSIZE
	 public  PORT15,PORT67,CMDCOM_PAR,OLDDOS,SYS_FLAG
	 public  SWPSIZE,P1ST_MAC,LCL_FLAG,DBG_FLAG
	 public  MSC_FLAG,POVR_MAC,CMD_FLAG,CM2_FLAG,CM3_FLAG,LOADSEG
	 public  OFFSIZE,DB2_FLAG,SHDSIZE,XSHDSIZE,ONFSIZE,SYSROM_START
	 public  DB3_FLAG,OLDINT21_VEC,CURINT67_VEC
INFOSIZE equ	 size INFO_STR	; Size of structure in bytes
QMAX_VER equ	 INFO.INFO_VER	;      Version #
DEVICE_CS equ	 INFO.INFO_QMAX ;  1 = Segment of device driver (non-relocatable)
GLB_FLAG equ	 INFO.INFO_GLB	;  4 = Global flags
	 include QMAX_GLB.INC
LOWSIZE  equ	 INFO.INFO_LOW	;  5 = Size of low DOS needed	 (unit = 1KB)
VIDSIZE  equ	 INFO.INFO_VID	;  6 = Size of video memory	 (unit = 1KB)
OVRSIZE  equ	 INFO.INFO_OVR	;  7 = Size of high DOS needed	 (unit = 1KB)
				;  8 = Size of extended memory left (unit = 1KB)
				;  9 = EMM memory size requested (unit = 1K)
PRGSIZE  equ	 INFO.INFO_PRG	; 10 = Size of program in extmem (unit = 1KB)
MAPSIZE  equ	 INFO.INFO_MAP	; 11 = Size of map region
				; 12 = Size of extended memory	 (unit = 1KB)
PORT15	 equ	 INFO.INFO_P15	; 13 = I/O port for INT 15h communications
PORT67	 equ	 INFO.INFO_P67	; 14 = I/O port for INT 67h communications
CMDCOM_PAR equ	 INFO.INFO_COMR ; 15 = Room for COMMAND.COM
OLDDOS	 equ	 INFO.INFO_OLD	; 16 = Old top of DOS		 (unit = para)
SYS_FLAG equ	 INFO.INFO_SYS	; 17 = SYSID flags
	 include QMAX_SYS.INC
P1ST_MAC equ	 INFO.INFO_PMAC ; 18 = Ptr to first entry in MAC
LCL_FLAG equ	 INFO.INFO_LCL	; 19 = Local flags
	 include QMAX_LCL.INC
DBG_FLAG equ	 INFO.INFO_DBG	; 20 = Debug flags
;;;;;;;; include QMAX_DBG.INC
DB2_FLAG equ	 INFO.INFO_DB2	; 21 = Debug flags, part 2
;;;;;;;; include QMAX_DB2.INC
MSC_FLAG equ	 INFO.INFO_MISC ; 22 = Miscellaneous flags
POVR_MAC equ	 INFO.INFO_POVR ; 23 = Segment of first MAC in high DOS memory
CMD_FLAG equ	 INFO.INFO_CMD	; 24 = Command flags
;;;;;;;; include QMAX_CMD.INC
CM2_FLAG equ	 INFO.INFO_CM2	; 25 = Command flags, part 2
	 include QMAX_CM2.INC
CM3_FLAG equ	 INFO.INFO_CM3	; 26 = Command flags, part 3
	 include QMAX_CM3.INC
LOADSEG  equ	 INFO.INFO_LSEG ; 27 = 386LOAD chain segment
OFFSIZE  equ	 INFO.INFO_OFF	; 28 = Size of extended memory if OFF (unit = 1KB)
SHDSIZE  equ	 INFO.INFO_SHD	; 29 = Size of shadow RAM (unit = 1KB)
XSHDSIZE equ	 INFO.INFO_XSHD ; 30 = Size of extra shadow RAM (unit = 1KB)
SWPSIZE  equ	 INFO.INFO_SWP	; 31 = Size of memory swap region (unit = 1KB)
ONFSIZE  equ	 INFO.INFO_ONF	; 32 = EXTSIZE over ON/OFF
SYSROM_START equ INFO.INFO_SROM ; 33 = Starting segment of system ROM
DB3_FLAG equ	 INFO.INFO_DB3	; 34 = Debug flags, part 3
;;;;;;;; include QMAX_DB3.INC
OLDINT21_VEC equ INFO.INFO_I21	; 35 = OLDINT21_VEC
CURINT67_VEC equ INFO.INFO_C67	; 36 = CURINT67_VEC
TOTSIZE  equ	 INFO.INFO_TOT	; 37 = Dword size of extended memory (unit = 1KB)
EXTSIZE  equ	 INFO.INFO_EXT	; 38 = Dword size of extended memory left (unit = 1KB)
EMMSIZE  equ	 INFO.INFO_EMM	; 39 = Dword EMM memory size requested (unit = 1K)


	 public  ACTA20_COMSUB,ACTA20_ENA
	 include QMAX_A20.INC
ACTA20_COMSUB dw PGROUP:A20COM_ISA ; Default A20 handler
ACTA20_ENA ACTA20_STR <PGROUP:A20ENA_I92,PGROUP:A20ENA_QUD,PGROUP:A20ENA_XT,PGROUP:A20ENA_ISA,PGROUP:A20ENA_I78>

if @OEM_WIN3
	 public  WIN3_STARTUP
	 include QMAXWIN3.INC
WIN3_STARTUP WIN386_START_STR <,		    \
			      ?,		    \
			      PGROUP:VIRT_DEV_DPFE, \
			      ?,		    \
			      PGROUP:IIS_MAX>

	 public  LOWWIN3_CB
LOWWIN3_CB db	 0		; 0 = outside Windows
				; 1 = inside Windows initialization
				; 2 = using Windows GDT/IDT/CR3
endif				; IF @OEM_WIN3

	 public  AT386_CFG,SAVE_AH,AT386_RAB,AT386_RCD,AT386_REF
AT386_CFG db	 ?
SAVE_AH  db	 ?		; Saved AH from Int 20h call
AT386_RAB db	 ?,?
AT386_RCD db	 ?,?
AT386_REF db	 ?,?

	 public  CT_ROMCFG,CT_RAM_AB,CT_RAM_CD,CT_RAM_EF
CT_ROMCFG db	 09h		; CHIPSet ROM configuration reg:  09h or 65h
CT_RAM_AB db	 0Dh		; ...	  RAM A000-C000     reg:  0Dh or 67h
CT_RAM_CD db	 0Eh		; ...	  RAM C000-E000     reg:  0Eh or 68h
CT_RAM_EF db	 0Fh		; ...	  RAM E000-10000    reg:  0Fh or 69h

	 NPPROC  SEND_CHIPSET -- Send Command/Data to CHIPSet
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Send data in AH to command register in AL in the CHIPSet.

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 REGSAVE <ax>		; Save register

	 out	 @CT_INDX,al	; Send command to CHIPSet
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 al,ah		; Put data into AL
	 out	 @CT_DATA,al	; Send data to CHIPSet
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 REGREST <ax>		; Restore

	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SEND_CHIPSET endp		; End SEND_CHIPSET procedure
	 NPPROC  SHADOW_ENABLE -- Enable Shadow RAM
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set shadow RAM on C&T CHIPSet machines to read-write.

|

	 REGSAVE <ax>		; Save register

	 test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
	 jz	 short SHADOW_ENABLE_EXIT ; Not this time

	 pushf			; Save flags
	 cli			; Nobody move

; Put EGA back into ROM

	 mov	 ah,AT386_CFG[1] ; Get new register value
	 mov	 al,CT_ROMCFG	; Register #
	 call	 SEND_CHIPSET	; Send AL=command/AH=data to CHIPSet

; Handle Address Map registers 0Dh to 0Fh

	 mov	 ah,AT386_RAB[1] ; Get new register value
	 mov	 al,CT_RAM_AB	; Register #
	 call	 SEND_CHIPSET	; Send AL=command/AH=data to CHIPSet

	 mov	 ah,AT386_RCD[1] ; Get new register value
	 mov	 al,CT_RAM_CD	; Register #
	 call	 SEND_CHIPSET	; Send AL=command/AH=data to CHIPSet

	 mov	 ah,AT386_REF[1] ; Get new register value
	 mov	 al,CT_RAM_EF	; Register #
	 call	 SEND_CHIPSET	; Send AL=command/AH=data to CHIPSet

	 popf			; Restore
SHADOW_ENABLE_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SHADOW_ENABLE endp		; End SHADOW_ENABLE procedure
	 NPPROC  STATE_PM -- Change State to Protected Mode
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Change current state to Protected Mode.

|

	 cli			; Disallow interrupts

; Ensure A20 is gated on

	 call	 GATEA20	; Enable address line A20

	 call	 SHADOW_ENABLE	; Set shadow RAM on CHIPSets to read-write

; Save stack to restore later

	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 mov	 <STKPTR.VSEG,ss> ; Save caller's stack pointer for a moment
	 assume  ds:nothing	; Retract nose

	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 mov	 <STKPTR.VOFF,sp>
	 assume  ds:nothing	; Retract nose

	 push	 cs		; Setup SS for local stack
	 pop	 ss
;;;;;;;; assume  ss:PGROUP	; Tell the assembler about it
	 movzx	 esp,PLOWSTKZ	; SS:ESP ==> local stack

	 push	 STKPTR 	; Save on stack

	 LGDTD	 LOWGDT.LOWDTE_GDT.EDF ; Load a skeleton GDT

	 push	 eax		; Save for a moment

	 mov	 eax,LCL_CR3	; Get new CR3
	 mov	 cr3,eax	; Tell the CPU about it

	 mov	 eax,cr0	; Get current CR0
	 or	 eax,(mask $PG) or (mask $PE) ; Enable Paging and Protected mode
	 mov	 cr0,eax	; Tell the CPU about it

	 pop	 eax		; Restore

; This FICALL is used instead of FIXICALL because it is always executed under
; 386MAX's GDT, etc. and is never translated by the Windows fixup apparatus.

	 FICALL  PGROUP:ENTERVM,LOWDTE_CSLHI ; Jump to extended memory code

	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 pop	 STKPTR 	; Restore from stack
	 assume  ds:nothing	; Retract nose

	 lss	 sp,STKPTR	; Restore caller's stack pointer
	 assume  ss:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STATE_PM endp			; End STATE_PM procedure
	 NPPROC  WAITIBUF_CLR -- Wait For The Input Buffer To Clear
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait for the one-byte input buffer to clear.

On entry:

IF	 =	 0

On exit:

CF	 =	 0 if buffer empty
	 =	 1 otherwise

|

	 REGSAVE <ax,cx>	; Save registers

	 mov	 ah,@WAIT8042	; Outer loop counter (arbitrary value)
	 xor	 cx,cx		; Inner loop counter (arbitrary value)
WAITIBUF_CLR1:
	 in	 al,@8042_ST	; Get status from keyboard

	 and	 al,mask $INPFULL ; Check Input Buffer Full flag
	 loopnz  WAITIBUF_CLR1	; Last char not read as yet
	 jz	 short WAITIBUF_CLR_EXIT ; Jump if buffer clear (note CF=0)

	 dec	 ah		; One fewer time
	 jnz	 short WAITIBUF_CLR1 ; Go around again

	 stc			; Indicate something went wrong
WAITIBUF_CLR_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WAITIBUF_CLR endp		; End WAITIBUF_CLR procedure
	 NPPROC  WAITOBUF_CLR -- Wait For The Output Buffer To Clear
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

IF	 =	 0

Wait for the one-byte output buffer to clear.

|

	 push	 ax		; Save for a moment
WAITOBUF_CLR1:
	 in	 al,@8042_ST	; Get status from keyboard

	 and	 al,mask $OUTFULL ; Check Output Buffer Full flag
	 jz	 short WAITOBUF_CLR_EXIT ; Jump if buffer clear before

	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@8255_A	; Purge the character
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 jmp	 short WAITOBUF_CLR1 ; Go around again

WAITOBUF_CLR_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WAITOBUF_CLR endp		; End WAITOBUF_CLR procedure
	 NPPROC  WAITOBUF_SET -- Wait for Output Buffer Full
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Wait for the output buffer to fill.

On entry:

IF	 =	 0

On exit:

CF	 =	 1 if no response
	 =	 0 otherwise

|

	 REGSAVE <ax,cx>	; Save registers

; Wait for a response

	 mov	 ah,@WAIT8042	; Outer loop counter (arbitrary value)
	 xor	 cx,cx		; Inner loop counter (arbitrary value)
WAITOBUF_SET1:
	 in	 al,@8042_ST	; Get status from keyboard

	 and	 al,mask $OUTFULL ; Check Output Buffer Full flag
	 loopz	 WAITOBUF_SET1	; Jump if no response as yet
	 jnz	 short WAITOBUF_SET_EXIT ; Join common exit code (note CF=0)

	 dec	 ah		; One fewer time
	 jnz	 short WAITOBUF_SET1 ; Jump if more tries available

	 stc			; Indicate something went wrong
WAITOBUF_SET_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WAITOBUF_SET endp		; End WAITOBUF_SET procedure
	 NPPROC  PPI_S2C -- PPI System to Controller
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller.
Send a command to the controller (8042).

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Wait for the input buffer to clear to avoid overrun.
2.  Send the command in AH to the keyboard controller port 64h.
    There is no acknowledgement of this command.

On entry:

AH	 =	 command
IF	 =	 0

On exit:

CF	 =	 1 if keyboard controller not responding
	 =	 0 otherwise

|

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short @F	; Error, controller not reading data (note CF=1)

	 xchg	 al,ah		; Swap to put command in AL
	 out	 @8042_ST,al	; Send the command
	 xchg	 al,ah		; Restore
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2C  endp			; End PPI_S2C procedure
	 NPPROC  PPI_K2S -- PPI Keyboard to System
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI Keyboard to System.
Wait for a response from the keyboard or its controller.

On entry:

IF	 =	 0

On exit:

CF	 =	 1 if no response
	 =	 0 otherwise

AL	 =	 response if CF=0

|

	 call	 WAITOBUF_SET	; Wait for the output buffer to fill
	 jc	 short @F	; Jump if no timely response (note CF=1)

	 in	 al,@8255_A	; Read in the code
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_K2S  endp			; End PPI_K2S procedure
	 NPPROC  PPI_S2C_K2S -- PPI System to Controller, Keyboard to System
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller, Keyboard to System
Send a command to the controller (8042), wait for a response.

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Send the command to the 8042.
2.  Wait for the output buffer to fill.
3.  Read the response.

Note that resend does not occur with the controller (8042)
(although it can with the keyboard (6805)).

On entry:

AH	 =	 S2C command
IF	 =	 0

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

AL	 =	 byte read (if CF=0)

|

	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short @F	; Jump if something went wrong (note CF=1)

	 call	 PPI_K2S	; Wait for a response, returned in AL
				; Return with CF significant
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2C_K2S endp		; End PPI_S2C_K2S procedure
	 NPPROC  PPI_S2C_S2K -- PPI System to Controller, System to Keyboard
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PPI System to Controller, System to Keyboard.

Note that it's the caller's responsibility to ensure that
the 8042 output buffer is clear.

1.  Send the command to the 8042.
2.  Send the data to the 8042.

On entry:

AH	 =	 S2C command
AL	 =	 byte to send
IF	 =	 0

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short @F	; Jump if something went wrong (note CF=1)

	 call	 WAITIBUF_CLR	; Wait for input buffer to clear
	 jc	 short @F	; Error, controller not reading data (note CF=1)

	 out	 @8255_A,al	; Send data AL to 8042
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PPI_S2C_S2K endp		; End PPI_S2C_S2K procedure
	 NPPROC  PULSE8042 -- Pulse 8042
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Pulse the 8042 to ensure the last command has been accepted.
Typically, this is necssary after toggling A20.

|

	 test	 CM3_FLAG,@CM3_XPULS ; Should we pulse the controller?
	 jnz	 short PULSE8042_EXIT ; Not this time (note CF=0)

; Pulse the controller to ensure the last 8042 command has been processed

	 push	 ax		; Save for a moment
	 mov	 ah,@S2C_RESET	; Ensure in a stable state
	 call	 PPI_S2C	; Send command AH to 8042
	 pop	 ax		; Restore
				; Return with CF significant
PULSE8042_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PULSE8042 endp			; End PULSE8042 procedure
	 NPPROC  READ_IRR -- Read Master 8259 Interrupt Request Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read master 8259 Interrupt Request Register (IRR)

On exit:

AL	 =	 IRR

|

	 mov	 al,@GETIRR	; Command to get IRR
	 out	 @ICR,al	; Tell the master 8259 about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@ICR	; Get the master IRR
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READ_IRR endp			; End READ_IRR procedure
	 NPPROC  A20ENA_I92 -- A20 Enable for I/O Port 92 Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for I/O port 92 systems

On entry:

AL	 =	 @PS2_A port value

On exit:

AL	 =	 (updated to enable A20)

|

	 or	 al,mask $PS2_GATE ; Enable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_I92 endp 		; End A20ENA_I92 procedure
	 NPPROC  A20ENA_QUD -- A20 Enable for Quadram 386/XT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for Quadram 386/XT

On entry:

AL	 =	 1F8h port value

On exit:

AL	 =	 (updated to enable A20)

|

	 or	 al,@BIT0	; Mark as enabling

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_QUD endp 		; End A20ENA_QUD procedure
	 NPPROC  A20ENA_XT -- A20 Enable for Inboard/PC
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for Inboard/PC

On exit:

AL	 =	 value to enable A20

|

	 mov	 al,@S2O_E20	; Tell it to enable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_XT endp			; End A20ENA_XT procedure
	 NPPROC  A20ENA_I78 -- A20 Enable for I/O Port 78h Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for I/O port 78h systems

On entry:

AL	 =	 port 78h byte

On exit:

AL	 =	 (updated to enable A20)

|

	 or	 al,@BIT2	; Enable A20 gate

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_I78 endp 		; End A20ENA_I78 procedure
	 NPPROC  A20ENA_ISA -- A20 Enable for ISA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable for ISA

On entry:

AL	 =	 output port byte

On exit:

AL	 =	 (updated to enable A20)

|

;;;;;;;; or	 al,(mask $S2O_DATA ) or \
;;;;;;;;	    (mask $S2O_OBFUL) or \
;;;;;;;;	    (mask $S2O_IBFMT) or \
;;;;;;;;	    (mask $S2O_GATE )
;;;;;;;;			; Ensure 6805 data line high,
;;;;;;;;			; output buffer full,
;;;;;;;;			; input buffer empty
;;;;;;;;			; gate A20 enabled
	 or	 al,mask $S2O_OBFUL ; Ensure output buffer marked as full
	 or	 al,mask $S2O_GATE ; Enable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20ENA_ISA endp 		; End A20ENA_ISA procedure
	 NPPROC  A20COM_I92 -- Common A20 I/O Port 92h Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 I/O port 92h routine

On entry:

CS:BX	 ==>	 enable/disable routine

On exit:

AL	 =	 clobbered
AH	 =	 preserved

|

	 in	 al,@PS2_A	; Get system control port A
	 call	 PGROUP:[bx].ACTA20_I92 ; Call common I92 action
	 out	 @PS2_A,al	; Tell the system about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_I92 endp 		; End A20COM_I92 procedure
	 NPPROC  A20COM_QUD -- Common A20 Quadram 386/XT Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 Quadram 386/XT routine

On entry:

CS:BX	 ==>	 enable/disable routine

On exit:

AL	 =	 clobbered
AH	 =	 preserved

|

	 push	 dx		; Save for a moment

	 mov	 dx,01F8h	; Get A20 gate/degate I/O port
	 in	 al,dx		; Get the current value
;;;;;;;; jmp	 short $+2	; Drain the PIQ
;;;;;;;; jmp	 short $+2	; Drain the PIQ
;;;;;;;; jmp	 short $+2	; Drain the PIQ

	 call	 PGROUP:[bx].ACTA20_QUD ; Call common Quadram 386/XT action
	 out	 dx,al		; Tell the board about it
;;;;;;;; jmp	 short $+2	; Drain the PIQ
;;;;;;;; jmp	 short $+2	; Drain the PIQ
;;;;;;;; jmp	 short $+2	; Drain the PIQ

	 pop	 dx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_QUD endp 		; End A20COM_QUD procedure
	 NPPROC  A20COM_XT -- Common A20 Inboard/PC Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 Inboard/PC routine

On entry:

CS:BX	 ==>	 enable/disable routine

On exit:

AL	 =	 clobbered
AH	 =	 preserved

|

	 call	 PGROUP:[bx].ACTA20_XT ; Call common Inboard/PC action
;;;;;;;; or	 al,10010000b	; Ensure 6805 data line high,
				; output buffer full
	 out	 @8255_A,al	; Issue the command
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_XT endp			; End A20COM_XT procedure
	 NPPROC  A20COM_I78 -- Common A20 I/O Port 78h Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 I/O port 78h routine

On entry:

CS:BX	 ==>	 enable/disable routine

On exit:

AL	 =	 clobbered
AH	 =	 preserved

|

	 in	 al,78h 	; Get current value
	 call	 PGROUP:[bx].ACTA20_I78 ; Call common I78 action
	 out	 78h,al 	; Send back

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_I78 endp 		; End A20COM_I78 procedure
	 NPPROC  A20COM_ISA -- Common A20 ISA Bus Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common A20 ISA Bus routine

On entry:

CS:BX	 ==>	 enable/disable routine

On exit:

AL	 =	 clobbered
AH	 =	 preserved

|

	 REGSAVE <ax>		; Save for a moment

; Allow interrupts in case pending IRQ0 or IRQ1 to avoid losing a keystroke
; unless we're coming through Windows 3 callback

if @OEM_WIN3
	 cmp	 LOWWIN3_CB,0	; Izit Windows 3 init time or later?
	 ja	 short A20COM_ISA_WIN3CB ; Jump if so
endif				; IF @OEM_WIN3

	 mov	 ah,@S2C_DIS	; Disable the keyboard
	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short A20COM_ISA_COM_ERR1 ; Jump if error (note CF=1)
A20COM_ISA_FLUSH:
	 sti			; Allow interrupts
	 nop			; One for IRQ0
	 nop			; ...	  IRQ1
	 cli			; Disallow interrupts

; Read the IRR:  if IRQ1 is still pending,
; and both IRQ0 and IRQ1 are enabled in the IMR, go around again

	 call	 READ_IRR	; Return with AL = IRR

	 test	 al,mask $IRQ1	; IRQ1 pending?
	 jz	 short A20COM_ISA_WIN3CB ; Jump if not

	 in	 al,@IMR	; Get master IMR

	 test	 al,(mask $IRQ1) or (mask $IRQ0) ; Are both enabled?
	 jz	 short A20COM_ISA_FLUSH ; Jump if so

	 mov	 al,@EOI1	; Get specific EOI for IRQ1
	 out	 @ICR,al	; Clear IRQ1 from the IRR
A20COM_ISA_WIN3CB:

; First, clear any pending scan code from the output buffer (belt and suspenders)

	 call	 WAITOBUF_CLR	; Wait for the output buffer to clear

	 mov	 ah,@S2C_ROUT	; Read output port byte command
	 call	 PPI_S2C_K2S	; Send AH to 8042, return with AL = response
	 jc	 short A20COM_ISA_COM_ERR ; Jump if error (note CF=1)

; As some 8042s aren't reliable and return with the $S2O_RESET bit
; clear, if that's the case, we assume that none of the bits are
; reliable -- we then use a constant return value.

	 test	 al,mask $S2O_RESET ; Izit set?
	 jnz	 short @F	; Jump if so

	 mov	 al,(mask $S2O_DATA)  or \
		    (mask $S2O_CLOCK) or \
		    (mask $S2O_OBFUL) or \
		    (mask $S2O_RESET)
@@:
	 call	 PGROUP:[bx].ACTA20_ISA ; Call common ISA action

	 mov	 ah,@S2C_WOUT	; Write output port byte
	 call	 PPI_S2C_S2K	; Write command AH, data AL to 8042
	 jc	 short A20COM_ISA_COM_ERR ; Jump if error (note CF=1)

	 call	 PULSE8042	; Pulse the 8042 to ensure A20 toggle done
				; Return with CF significant
A20COM_ISA_COM_ERR:
	 pushf			; Save previous flags

; Last, enable the keyboard

	 mov	 ah,@S2C_ENA	; Enable the keyboard
	 call	 PPI_S2C	; Send command AH to 8042
				; Ignore error return
	 popf			; Restore previous flags
A20COM_ISA_COM_ERR1:
	 REGREST <ax>		; Restore

	 adc	 ah,0		; Set CF in AH image of flags as necessary

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20COM_ISA endp 		; End A20COM_ISA procedure
	 NPPROC  GATEA20 -- Enable Address Line A20
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable address line A20.

On exit:

CF	 =	 0 if all went well
	 =	 1 if we couldn't enable A20

|

	 push	 bx		; Save register

	 lea	 bx,ACTA20_ENA	; CS:BX ==> enable A20 actions

	 jmp	 short ACTA20_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GATEA20  endp			; End GATEA20 procedure
	 NPPROC  ACTA20_COM -- A20 Enable/Disable Common Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 enable/disable common routine

On entry:

BX	 pushed onto stack
CS:BX	 ==>	 enable/disable action structure

|

	 push	 ax		; Save register

	 clc			; Assume all goes well
	 lahf			; Load AH with flags

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 call	 ACTA20_COMSUB	; Call the appropriate subroutine

	 popf			; Restore flags

	 sahf			; Store AH into flags

	 pop	 ax		; Restore

	 pop	 bx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACTA20_COM endp 		; End ACTA20_COM procedure
if @OEM_WIN3
	 FPPROC  WIN3_CB -- WINDOWS 3.0 Callback Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

WIN3 callback routine.

On entry:

IF	 =	 0	interrupts are disabled
AX	 =	 0	if we're to disable ourselves
	 =	 1	if we're to re-enable ourselves

|

	 cmp	 ax,1		; Izit re-enable?
	 je	 short WIN3_CB_ENA ; Jump if so

; Must be disable time

	 test	 GLB_FLAG,@GLB_ON ; Are we already OFF or AUTO inactive?
	 jz	 short WIN3_CB_DISOFF ; Jump if so

	 push	 eax		; Save for a moment

	 EMMOUT  @EMM2_GOREALWIN3 ; Come back in real mode

	 public  WIN3_CB_GOREAL
WIN3_CB_GOREAL:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

; It must be true that the linear and physical address for
; this page are identical

; Turn off paging and exit protected mode

	 mov	 eax,cr0	; Get current CR0
	 and	 eax,not ((mask $PG) or (mask $PE)) ; Turn off PG & PE bits
	 mov	 cr0,eax	; Exit protected mode

; Jump to real mode code

	 FIJMP	 PGROUP:$+4,<seg PGROUP> ; Far jump to set access rights

; Clear the PDBR

	 xor	 eax,eax	; Zero EAX to clear CR3
	 mov	 cr3,eax	; Flush paging translation cache

; Flush the pre-fetch instruction queue after flushing page translation cache

	 jmp	 short $+2	; Flush it

	 lss	 sp,STKPTR	; Restore caller's stack pointer
	 assume  ss:nothing	; Tell the assembler about it

	 pop	 eax		; Restore
WIN3_CB_DISOFF:
	 clc			; Indicate we succeeded

	 ret			; Return to caller

; It's time to re-enable ourselves

WIN3_CB_ENA:
	 test	 GLB_FLAG,@GLB_ON ; Were we OFF or AUTO inactive?
	 jz	 short WIN3_CB_ENAOFF ; Jump if so

	 call	 STATE_PM	; Change state to Protected Mode
WIN3_CB_ENAOFF:

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WIN3_CB  endp			; End WIN3_CB procedure
	FPPROC	RESINT_PnP -- Low DOS Memory PnP Entry Point
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Low DOS memory PnP entry point

Note this code must reside in linear=physical memory

Some PnP drivers (alright, it's DWCFGMG.SYS from Intel) call
the PnP struc entry point in the BIOS from VM and RM (they
get to RM by entering PM via VCPI and then clearing the
$PE bit in CR0).  Thus we need to be in one-to-one memory as
well as distinguish the RM and VM cases.

On entry:

The stack is setup as per the PnP spec

On exit:

AX	=	error code (0 if successful)

|

; Distinguish between RM and VM

	smsw	ax		; Get register with PE bit

	test	al,mask $PE	; Izit in VM?
	jnz	short @F	; Jump if so

	jmp	ORIG_PnP_RMVEC	; Jump to the original entry point

@@:
if @OEM_WIN3
	cmp	LOWWIN3_CB,2   ; Izit under control of Windows' GDT/IDT/CR3?
	jne	short RESINT_PnP_INT ; Jump if not

	call	LO_PGET_WINVXD_VEC ; Fill in WINVXD_VEC
	jnc	short RESINT_PnP_ERR ; Jump if something went wrong

	mov	ah,@EMM2_PnP	; Mark as PnP function
	push	@VXDAPI_UTIL	; Code to request UTIL service
	call	LO_WINVXD_VEC	; Request Windows Virtual Device API service

	ret			; Return to caller

RESINT_PnP_ERR:
	mov	ax,@PnP_ERR_NOTSUP ; Mark as function not supported

	ret			; Return to caller

RESINT_PnP_INT:
endif				; IF @OEM_WIN3
	EMMOUT	@EMM2_PnP	; Request PnP service

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT_PnP endp 		; End RESINT_PnP procedure

	 public  DUMMY_INT67
DUMMY_INT67 label far
	 mov	 ah,84h 	; Invalid function error code

	 iret			; Used in QMAX_EM2:INITWIN3

	 assume  ds:PGROUP	; Tell the assembler about it

	 public  WIN3_END
WIN3_END label	 byte
endif				; IF @OEM_WIN3

CODE	 ends			; End CODE segment

	 MEND	 INIT		; End QMAX module

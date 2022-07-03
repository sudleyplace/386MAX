;' $Header:   P:/PVCS/MAX/386MAX/QMAX_INI.ASV   1.7   30 May 1997 10:45:14   BOB  $
	title	QMAX_INI -- 386MAX Initialization
	page	58,122
	name	QMAX_INI

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
	       Group SGROUP:
	       Program segment SCODE, para-aligned,  public, class 'scode'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Data    segment JDATA, dword-aligned, public, class 'jcode'
	       Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'
	       Data    segment XDATA, dword-aligned, public, class 'xdata'
	       Group YGROUP:
	       Data    segment YDATA, dword-aligned, public, class 'ydata'
	       Data    segment YDATZ, para-aligned,  public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.387
.xlist
	include MASM.INC
	include DOSCALL.INC
	include KEYCALL.INC
	include VIDCALL.INC
	include EMMCALL.INC
	include EMM2CALL.INC
	include ASCII.INC
	include DEVDRV.INC
	include INTVEC.INC
	include 386.INC
	include 8259.INC
	include PTR.INC
	include MAC.INC
	include I11.INC
	include BIOSDATA.INC
	include BIOSCONF.INC
	include BITFLAGS.INC
	include CPUFLAGS.INC
	include NDP.INC
	include XMS.INC
	include XBIOS.INC
	include CMOS.INC
	include EISA.INC
	include VDS.INC
	include IOPBITS.INC
	include CPUSIG.INC
	include CPUFET.INC
	include MOVSPR.INC
	include OPCODES.INC

	include QMAX_CFG.INC
	include QMAX_DTE.INC
	include QMAX_OEM.INC
	include QMAX_VCP.INC
	include QMAX_FLX.INC
	include QMAX_STK.INC
if @OEM_DPMI
	include QMAXDPMI.INC
endif				; IF @OEM_DPMI
.list

PGROUP	group	CODE,HICODE,ZCODE,ECODE,EDATA,NCODE,NDATA
SGROUP	group	SCODE
IGROUP	group	LCODE,ICODE
JGROUP	group	JDATA
XGROUP	group	XCODE,XDATA
YGROUP	group	YDATZ


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

	extrn	SYS_FLAG:dword
	include QMAX_SYS.INC

	extrn	DEV_STRA:far
	extrn	DEV_INTR:far
if @OEM_WTK
	extrn	RESINT11:near
	extrn	OLDINT11_VEC:dword
endif				; IF @OEM_WTK
	extrn	RESINT15:near
	extrn	RESINT19:near
	extrn	RESINT67_IRET:near

if @OEM_HILOAD
	extrn	RESINT20:near
	extrn	RESINT21:near
	extrn	RESINT27:near
	extrn	OLDINT20_VEC:dword
	extrn	OLDINT21_VEC:dword
	extrn	OLDINT27_VEC:dword
endif				; IF @OEM_HILOAD

if @OEM_WIN3
;;;;;;; extrn	LOWINT15:far
;;;;;;; extrn	LOWINT2F:far
	extrn	WIN3_END:near
endif				; IF @OEM_WIN3

if @OEM_XMS
	extrn	RESINT2F:far
	extrn	OLDINT2F_VEC:dword
	extrn	RESINT_XMS:near
endif				; IF @OEM_XMS
	extrn	RESINT40:near
;;;;;;; extrn	READA20:near

	extrn	CMD_FLAG:word
	include QMAX_CMD.INC

	extrn	CM2_FLAG:word
	include QMAX_CM2.INC

	extrn	CM3_FLAG:word
	include QMAX_CM3.INC

	extrn	DBG_FLAG:word
	include QMAX_DBG.INC

	extrn	DB3_FLAG:word
	include QMAX_DB3.INC

	extrn	GLB_FLAG:word
	include QMAX_GLB.INC

	extrn	LCL_FLAG:word
	include QMAX_LCL.INC

	extrn	XMS_FLAG:word
	include QMAX_XMS.INC

	extrn	INFO:tbyte
	extrn	LOADSEG:word
	extrn	DEVICE_CS:word

	extrn	OLDINT15_VEC:dword
	extrn	OLDINT19_VEC:dword
	extrn	OLDINT40_VEC:dword
	extrn	CURINT67_VEC:dword

if @OEM_WIN3
;;;;;;; extrn	INT15L_HIMEM_CS:word
;;;;;;; extrn	INT2FL_HIMEM_CS:word
;;;;;;; extrn	INTXMSL_HIMEM_CS:word
;;;;;;; extrn	WIN3_HIMEM_CS:word
	extrn	WIN3_STARTUP:tbyte
	include QMAXWIN3.INC
endif				; IF @OEM_WIN3

	extrn	DEVDRV:byte
if @OEM_EMS
	extrn	DEVDRV2:byte
endif				; IF @OEM_EMS
	extrn	RH_VEC:dword
	extrn	PORT67:word
	extrn	POVR_MAC:word

if @OEM_EMS
	extrn	EMMSIZE:dword
endif				; IF @OEM_EMS
	extrn	LOWSIZE:word
	extrn	TOTSIZE:dword

	extrn	CMDCOM_PAR:word
	extrn	PLOWSTKZ:word
	extrn	OLDDOS:word
	extrn	SBIOSDATA:word

if @OEM_HIFILL
	extrn	LHI_STRA:near
	extrn	LHI_INTR:near
	extrn	LHI_END:byte
	extrn	LHI_STRA_CS:word
	extrn	LHI_INTR_CS:word
if @OEM_WIN3
	extrn	LHI_INTR3:near
	extrn	LHI_INTR_CS3:word
endif				; IF @OEM_WIN3
endif				; IF @OEM_HIFILL

CODE	ends			; End CODE segment


HICODE	segment use16 dword public 'prog' ; Start HICODE segment
	assume	ds:PGROUP

	extrn	XBIOS_SRC:dword
	extrn	PRESINT_XMS:dword

	extrn	OLDINT13A_VEC:dword
	extrn	OLDINT13B_VEC:dword

	extrn	RESINT13A:near
	extrn	RESINT13B:near

if @OEM_WIN3
	extrn	IIS_MAX:tbyte
endif				; IF @OEM_WIN3

	extrn	EMPTY_HIMAC:byte

	extrn	HOOK13:byte
	extrn	@HOOK13_ACTIV:abs

HICODE	ends			; End HICODE segment


ZCODE	segment use16 para public 'zcode' ; Start ZCODE segment
	assume	cs:PGROUP,ds:PGROUP

;;;;;;; extrn	Z67CODE:byte
if @OEM_DPMI
;;;;;;; extrn	ZLODPMI:byte
	extrn	OVR_HPDA:tbyte
	extrn	@OVR_HPDALENP:abs
	extrn	@OVR_HPDALEND:abs
endif				; IF @OEM_DPMI
	extrn	ZLOCODE:byte
	extrn	ZLOCODE_XINB:byte
if @OEM_EMS
	extrn	OLDINT67_VEC:dword
	extrn	RESINT67:near
endif				; IF @OEM_EMS
	extrn	ZCODE_XLHI:byte

if @OEM_HIFILL
	extrn	LSEG:tbyte
	include LOAD_SEG.INC
endif				; IF @OEM_HIFILL

ZCODE	ends			; End ZCODE segment


EDATA	segment use16 dword public 'edata' ; Start EDATA segment
	assume	ds:PGROUP

	extrn	I15_FLAG:word
	include QMAX_I15.INC

if @OEM_VIRTUALMEM
	extrn	VMM_FLAG:word
	include QMAX_VMM.INC
endif				; IF @OEM_VIRTUALMEM

	extrn	DSTK_CNT:word
	extrn	DSTK_ISIZ:word

	extrn	CON16MB:dword

if @OEM_DEBUG
	extrn	HEXTABLE:byte
	extrn	LOADCOUNT:word
endif				; IF @OEM_DEBUG

if @OEM_WIN3
	extrn	WIN3_REF_DATA:tbyte
	extrn	PaPRGBASE:dword
	extrn	PRGBASE:dword
	extrn	FGRBASE:dword
	extrn	FGRSIZE:dword
	extrn	IGRBASE:dword
	extrn	IGRSIZE:dword
	extrn	JGRBASE:dword
	extrn	JGRSIZE:dword
endif				; IF @OEM_WIN3
	extrn	MSG_STAT:byte
	extrn	MSG_STATLEN:abs
	extrn	@MSG_STAT_ROWCNT:abs
	extrn	LCL_SAVE_PTR:dword
	extrn	MAPSEG_NXT:word
	extrn	PaMAX:dword
	extrn	PRGSIZE:word
	extrn	PRVSIZE:dword
if @OEM_XMS
	extrn	HMASIZE:dword
endif				; IF @OEM_XMS
	extrn	NPHYS16F:byte
	extrn	NPHYS16S:byte
if @OEM_WIN3
	extrn	PUMB_INST:dword
endif				; IF @OEM_WIN3
	extrn	CPUTYPE:byte
	extrn	CPUREV:byte
if @OEM_DPMI
	extrn	HPDA_NPAR:word
	extrn	SEL_DSIG3:word
endif				; IF @OEM_DPMI
	extrn	PDSTKCOM:dword
	extrn	LaDSTK_TAB:dword
	extrn	VDSTAB_LEN:dword
	extrn	POVR_LIE:word
	extrn	FLG_GET_CRn:byte
	extrn	FLG_SET_CRn:byte
	extrn	FLG_GET_DRn:byte
	extrn	FLG_SET_DRn:byte
	extrn	FLG_GET_TRn:byte
	extrn	FLG_SET_TRn:byte

	extrn	CFGLIST_XMEI:tbyte

	public	LaINDOS
LaINDOS dd	?		; Linear address of the InDOS flag

	public	PCFGFILE
PCFGFILE dd	0		; Offset in PGROUP to CFGFILE data (0 = none)

	public	PHYSIZE,WINSIZE
PHYSIZE dd	?		; Top of physical memory (including 1st MB)
WINSIZE dd	?		; ...			 (...) for Windows

	public	CPUFET_FLAG
CPUFET_FLAG CPUFET_REC <>	; CPU feature bits

; The following OLDINT entries are intercepted
; Note that these interrupt vectors *MUST* be consecutive

	public	NOLDINTS,OLDINT_VECS
NOLDINTS equ	(7Fh+1) 	; # interrupt vectors to save
OLDINT_VECS dd	NOLDINTS dup (?) ; INT 00h through 21h

	public	VIDOFF,LOWOFF,LMLTOP
VIDOFF	dd	?		; Start of video memory       (unit = 1KB)
LOWOFF	dd	?		; Start of DOS low addition   (unit = 1KB)
LMLTOP	dd	?		; Top of low memory load area (unit = 1KB)

	public	HIMEM_CS
HIMEM_CS dw	seg PGROUP	; Segment of device driver in high DOS memory

; MCSTAB contains a summary of MEM_MAP's high memory usage.
; It is filled in by FILL_MCS and described by MCS_STR.
; The entries indicate where in high memory OVR memory should
; mapped as well as how to extend the DOS memory allocation chain.

	public	MCSTAB,MCSTAB_CNT
	include QMAX_MCS.INC
MCSTAB_CNT dw	0		; # entries in MCSTAB
MCSTAB	MCS_STR (192/4) dup (<,,@MCS_HOLE>) ; Memory Chain Structure

if @OEM_FLEXROM
	extrn	FLEXROM_FLAG:word
	extrn	FLEXROM_LEN:word
	extrn	FLEXROM_TBL:tbyte
endif				; IF @OEM_FLEXROM

	public	DOSVER
DOSVER	dw	?		; DOS version # in comparison order

if @OEM_DEBUG
	public	CPD_FLAG
	include QMAX_CPD.INC
CPD_FLAG dw	0		; Checkpoint Debugging flags
endif				; IF @OEM_DEBUG

EDATA	ends			; End EDATA segment


SCODE	segment use16 para public 'scode' ; Start SCODE segment
	assume	ds:SGROUP

	extrn	DSTK_TAB_NXTOFF:word
	extrn	SCODE_END:byte
	extrn	DSTK_TAB:tbyte

SCODE	ends			; End SCODE segment


LCODE	segment use16 dword public 'icode' ; Start LCODE segment
	assume	cs:IGROUP

	extrn	INT15_HIMEM_CS:word

LCODE	ends			; End LCODE segment


ICODE	segment use16 dword public 'icode' ; Start ICODE segment
	assume	cs:IGROUP

if @OEM_DPMI
	extrn	INT31A_HIMEM_CS:word
	extrn	INT31B_HIMEM_CS:word
endif				; IF @OEM_DPMI

ICODE	ends			; End ICODE segment


ECODE	segment use16 dword public 'ecode' ; Start ECODE segment
	assume	cs:PGROUP,ds:PGROUP

	public	@QMAX_INI_ECODE
@QMAX_INI_ECODE:		; Mark module start in .MAP file

	extrn	FKEYWAIT:far
	extrn	OUTCMOS:near

if @OEM_WIN3
	extrn	XMS_VXD2MAX:far
	extrn	UTL_VXD2MAX:near
	extrn	FIXUP_ISELS:far
endif				; IF @OEM_WIN3

if @OEM_XMS
	extrn	INT2F_HIMEM_CS:word
endif				; IF @OEM_XMS
if @OEM_EMS
	extrn	INT67A_HIMEM_CS:word
	extrn	INT67B_HIMEM_CS:word
endif				; IF @OEM_EMS
if @OEM_VCPI and @VCP_OLD
	extrn	INTFE_HIMEM_CS:word
endif				; IF @OEM_VCPI and @VCP_OLD
	extrn	INTFF_HIMEM_CS:word

	FPPROC	SET_EXTMEM_CS -- Set New HIMEM_CS Value
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set new HIMEM_CS value

On entry:

DS	=	selector/segment for data area (might be high DOS memory)
AX	=	new value

|

	mov	HIMEM_CS,ax   ; Save original value
	mov	ax,offset PGROUP:EMPTY_HIMAC ; Offset of bogus high DOS MAC
	shr	ax,4-0		; Convert to paras
	add	ax,HIMEM_CS	; AX contains bogus POVR_MAC
	mov	POVR_LIE,ax	; Save so we can lie to Microsoft UMB.COM
	mov	ax,HIMEM_CS	; Restore high segment value
if @OEM_XMS
	mov	INT2F_HIMEM_CS,ax
endif				; IF @OEM_XMS
	push	ds		; Save for a moment

	mov	ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	assume	ds:IGROUP	; Tell the assembler about it

if @OEM_DPMI
	test	CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	jnz	short SET_EXTMEM_CS_XDPMI ; Jump if so

	mov	INT31A_HIMEM_CS,ax
	mov	INT31B_HIMEM_CS,ax
SET_EXTMEM_CS_XDPMI:
endif				; IF @OEM_DPMI
	mov	INT15_HIMEM_CS,ax

	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler about it
if @OEM_EMS
	mov	INT67A_HIMEM_CS,ax
	mov	INT67B_HIMEM_CS,ax
endif				; IF @OEM_EMS
if @OEM_VCPI and @VCP_OLD
	mov	INTFE_HIMEM_CS,ax
endif				; IF @OEM_VCPI and @VCP_OLD
	mov	INTFF_HIMEM_CS,ax

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_EXTMEM_CS endp		; End SET_EXTMEM_CS procedure
	align	4		; Ensure dword alignment

ECODE	ends			; End ECODE segment


JDATA	segment use16 dword public 'jcode' ; Start JDATA segment
	assume	ds:JGROUP

if @OEM_HIFILL
	extrn	MAC_STRA:word
	extrn	LaLINKFLG:dword
	extrn	LaLINKSEG:dword
	extrn	TEMP_PSP:word
endif				; IF @OEM_HIFILL

JDATA	ends			; End JDATA segment


NDATA	segment use16 dword public 'ndata' ; Start NDATA segment
	assume	ds:PGROUP

	extrn	MOVE_TAB:qword

	extrn	@XLAT_OTH:abs
	extrn	MEM_MAP:byte
	extrn	MAXMOVE:word

if @OEM_DEBUG
	extrn	CPDOFF:dword
	extrn	CPDCNT:word
	extrn	CPDREGTAB:word
	extrn	CPDREGTAB_LEN:abs
endif				; IF @OEM_DEBUG

if @OEM_FLEXROM
	extrn	READ_SEG:word
	extrn	FLEXFILE_VEC:dword
endif				; IF @OEM_FLEXROM

	public	NRD_FLAG
	include QMAX_NRD.INC
NRD_FLAG dd	@NRD_CLR	; Non-resident data flags

if @OEM_XMS
	public	OLDXMS_VEC,NEWXMS_VEC
OLDXMS_VEC dd	?		; Save area for previous XMS handler
NEWXMS_VEC dd	PGROUP:RESINT_XMS ; Save area for new XMS handler
endif				; IF @OEM_XMS

	public	OLDSTK_VEC
OLDSTK_VEC VECTOR <>

	public	ENDADDR,LSEG_OFF,HI_ENDADDR,XHI_ENDADDR
ENDADDR dw	PGROUP:ZCODE_XLHI ; Ending address of program in low DOS
LSEG_OFF dw	?		; Offset of final LSEG entry
HI_ENDADDR dw	?		; Ending address of program in high DOS
XHI_ENDADDR dw	?		; Ending address if program was in high DOS

	public	VDSTAB_SEG
VDSTAB_SEG dw	0		; Segment of VDS table (0=none)

	public	CTL387
CTL387	dw	?		; Save area for 387 control word

if @OEM_HIFILL
	public	PRGREG
PRGREG	dw	-1		; Program region # (-1 means first fit)
endif				; IF @OEM_HIFILL

	public	CMDCOM_VER,CMDCOM_SIZ
CMDCOM_VER dw	0200h,020Ah,020Bh,0300h,030Ah,0314h,031Eh,0400h,0000h,0000h
CMDCOM_NVER equ ($-CMDCOM_VER)/type CMDCOM_VER ; # versions supported
;		  2.00	2.10  2.11  3.00  3.10	3.20  3.30  4.00  ?.??	?.??  Not found
CMDCOM_SIZ dw	0350h,0351h,02FEh,0459h,0487h,0492h,04D6h,06D7h,0700h,0700h,0700h

;;;;;;; public	PPMAC_OFF
;;; PPMAC_OFF dw     010Ch,00F8h,00EEh,012Ah,0024h,0024h,0024h,0024h,	 ?,    ?,    ?

;;;;;;; public	PPMAC_HEAD
;;; PPMAC_HEAD dd    ?		    ; Ptr to ptr to memory allocation chain head

	public	PGRSEG
PGRSEG	dw	seg PGROUP	; Segment of our group

	public	PZLOCODE
PZLOCODE dw	PGROUP:ZLOCODE	; Default end of high DOS

NDATA	ends			; End NDATA segment


NCODE	segment use16 byte public 'ncode' ; Start NCODE segment
	assume	cs:PGROUP

	extrn	INIT_CHIPSET:far
	extrn	TIME_ALLMEM:far
	extrn	FDISP_COLOR:far

	FPPROC	FOUTCMOS -- Far Call to OUTCMOS
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to OUTCMOS

|

	call	OUTCMOS 	; Call the near routine

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FOUTCMOS endp			; End FOUTCMOS procedure
	FPPROC	LCL_INT03 -- Local INT 03h Handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Call resident debugger with INT 03h.

N.B.:  Leave this routine in PGROUP unless you want to
complicate the /U 11 routine in UXR.COM through Periscope.

|

	int	03h		; Call our resident debugger

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT03 endp			; End LCL_INT03 procedure

NCODE	ends			; End NCODE segment


XDATA	segment use16 dword public 'xdata' ; Start XDATA segment
	assume	ds:XGROUP

	include QMAX_IDN.INC

	extrn	@MAX_EMSMEM:abs

	extrn	OLDCPQSTK_VEC:dword
	extrn	CPQSTKZ:byte

if @OEM_FLEXROM
	extrn	FLEXDATA:byte
	extrn	FLEXDATA_CNT:word
endif				; IF @OEM_FLEXROM
	extrn	DSTK_NPAR:word

	extrn	PLAST_MAC:dword

	public	RH_VECX
RH_VECX dd	?		; Ptr to request header

	public	XPGRSEG
XPGRSEG dw	seg PGROUP	; Segment of our group

if @OEM_HIFILL
	public	HPDAR,XBDAR,STACKR
HPDAR	REG_STR <,,YGROUP:MSG_HPDARCHG> ; Region, size for HPDA
XBDAR	REG_STR <,,YGROUP:MSG_XBDARCHG> ; ...		    XBDA
STACKR	REG_STR <,,YGROUP:MSG_STACKRCHG>; ...		    STACKS
endif				; IF @OEM_HIFILL

if @OEM_DPMI
	public	HPDASEG,TMPHPDASEG
HPDASEG dw	?		; Segment of final destination for HPDA
TMPHPDASEG dw	seg PGROUP	; Segment of OVR_HPDA
endif				; IF @OEM_DPMI

if @OEM_HIFILL
	public	PREV_LMAC_NPAR
PREV_LMAC_NPAR	dw	 ?	; Previous MAC_NPAR from PLAST_MAC for comparison
endif				; IF @OEM_HIFILL

	public	XENDADDR
XENDADDR  dw	PGROUP:ZCODE_XLHI ; Ending address of program in low DOS

	public	XBIOS_DST,XBIOS_SIZ,XBIOS_DOS
XBIOS_DST dd	0		; XBIOS source pointer
XBIOS_SIZ  dw	?		; XBIOS length in bytes if loaded low
XBIOS_DOS dw	?		; New top of DOS after XBIOS relocation

	public	EISAREGS
EISAREGS db	01h		; 0401	DMA ch0 high base & current count
	db	03h		; 0403	DMA ch1 ...
	db	05h		; 0405	DMA ch2 ...
	db	07h		; 0407	DMA ch3 ...
;;;;;;;  db	 ???		; ????	DMA ch4 ...
	db	0C6h		; 04C6	DMA ch5 ...
	db	0CAh		; 04CA	DMA ch6 ...
	db	0CEh		; 04CE	DMA ch7 ...
	db	87h		; 0487	DMA ch0 high page
	db	83h		; 0483	DMA ch1 ...
	db	82h		; 0482	DMA ch2 ...
	db	81h		; 0481	DMA ch3 ...
;;;;;;;  db	 ???		; ????	DMA ch4 ...
	db	8Bh		; 048B	DMA ch5 ...
	db	89h		; 0489	DMA ch6 ...
	db	8Ah		; 048A	DMA ch7 ...
@EISAREGCNT equ ($-EISAREGS)/(type EISAREGS)

XDATA	ends			; End XDATA segment


YDATA	segment use16 dword public 'ydata' ; Start YDATA segment
	assume	ds:YGROUP

if @OEM_BCF
	extrn	MSG_BCFERR:byte
endif				; IF @OEM_BCF
	extrn	MSG_ABORT:byte
	extrn	MSG_NOT386:byte
	extrn	MSG_NOTVM:byte

	extrn	MSG_NOTINST:byte
	extrn	MSG_NOTDRV:byte

if @OEM_SYS ne @OEMSYS_AST386
	extrn	MSG_COPYRIGHT:byte
endif				; IF @OEM_SYS ne @OEMSYS_AST386

	extrn	MSG_EISA_BAD:byte
	extrn	MSG_EISA_BAD1:byte

	extrn	MSG_VDSERR:byte

if @OEM_FLEXROM
	extrn	MSG_NOFLEXFILE_PASS2:byte
	extrn	MSG_FF_ERR:byte
	extrn	MSG_FF_ERR1:byte
	extrn	MSG_FF_XVID:byte
	extrn	MSG_FF_XVID1:byte
	extrn	MSG_PRESS:byte
endif				; IF @OEM_FLEXROM

if @OEM_HIFILL
	extrn	MSG_HPDARCHG:byte
	extrn	MSG_STACKRCHG:byte
	extrn	MSG_XBDARCHG:byte
endif				; IF @OEM_HIFILL

	extrn	MSG_ABIOSERR:byte

YDATA	ends			; End YDATA segment


YDATZ	segment use16 para public 'ydata' ; Start YDATZ segment
	assume	ds:YGROUP

	public	PIDENT
PIDENT	dd	XGROUP:IDENTIFY ; Point to identification string

	public	YDATA_NXT
YDATA_NXT label byte

YDATZ	ends			; End YDATZ segment


XCODE	segment use16 byte public 'xcode' ; Start XCODE segment
	assume	cs:XGROUP

	public	@QMAX_INI_XCODE
@QMAX_INI_XCODE:		; Mark module start in .MAP file

	extrn	POSREADALL:far
if @OEM_BCF
	extrn	CHECK_BCRC:far
endif				; IF @OEM_BCF

	extrn	SAVE_SHADOW:far
	extrn	CHECK_DEVICE:far
	extrn	CHECK_MODEL:far
	extrn	CHECK_SYSID:far
	extrn	CALC_ALLMEM:far
	extrn	FILL_MAP:far
	extrn	CALC_SIZE:far
	extrn	CHECK_ARGS:far
	extrn	CALC_SCRN:far
	extrn	CALC_STAT:far
	extrn	DECR_MAC:far
	extrn	BUSMASTER:far
	extrn	FINDZMAC:far
if @OEM_DMA and @OEM_SYS ne @OEMSYS_ILIM
	extrn	TEST_DMA:far
endif				; IF @OEM_DMA and @OEM_SYS ne @OEMSYS_ILIM
	extrn	FCN_WTKF:far
	extrn	FMT_ERR_CODE:far
	extrn	PROT_INIT:far

if @OEM_DEBUG
	extrn	INIT_VIRT:far
endif				; IF @OEM_DEBUG
	extrn	YMSGOUT2:near
	extrn	SET_LOWMEM:far
	extrn	CHECK_PRVEXT:far
	extrn	CHECK_QEXT:far
	extrn	CHECK_SHADOW:far
	extrn	SET_PATHSTEM:far

if @OEM_FLEXROM
	extrn	READ_FLEXFILE:far
endif				; IF @OEM_FLEXROM
	extrn	DISP_OEM:near
	extrn	IZIT_PnP:near

if @OEM_DEBUG
	FPPROC	DISP_CPDMSG -- Display CPD Message
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display CPD message

Note we can't use any BIOS services as the video
might not be hooked up as yet.

On entry:

YGROUP:SI ==>	 message to display

|

DISPCPD_STR struc

DISPCPD_FS dw	?		; Caller's FS
DISPCPD_ES dw	?		; ...	   ES
DISPCPD_DS dw	?		; ...	   DS
DISPCPD_EGP db	(size PUSHAD_STR) dup (?) ; Caller's EGP registers
DISPCPD_FL dw	?		; ...	   FL
DISPCPD_CSIP dd ?		; ...	   CS:IP
DISPCPD_OFF dw	?		; Offset in YGROUP of the message

DISPCPD_STR ends

	pushf			; Save to ensure we're isolated

	push	ds		; Save for a moment

	push	seg PGROUP	; Get segment of CPD_FLAG
	pop	ds		; Address it
	assume	ds:PGROUP	; Don't tell the assembler about it

	test	CPD_FLAG,@CPD_MSG ; Allowing Checkpoint Debugging?
	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it
	jz	near ptr DISP_CPDMSG_EXIT ; Jump if not

	pushad			; Save all EGP registers
	REGSAVE <ds,es,fs>	; Save for a moment

	movzx	ebp,sp		; SS:EBP ==> DISPCPD_STR

	mov	ax,seg YGROUP	; Get segment of the text to display
	mov	ds,ax		; Address it
	assume	ds:YGROUP	; Don't tell the assembler about it

	mov	ax,seg PGROUP	; Get segment of the text to display
	mov	fs,ax		; Address it
	assume	fs:PGROUP	; Don't tell the assembler about it

; Check for display buffer:  mono or color

	mov	ax,0B800h	; Get base address of color display buffer

	test	NRD_FLAG,@NRD_CLR ; Izit color?
	jnz	short @F	; Jump if so

	mov	ax,0B000h	; Get base address of mono display buffer
@@:
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	mov	di,CPDOFF.ELO	; ES:DI ==> next screen offset
	mov	si,[ebp].DISPCPD_OFF ; Get offset in YGROUP of the message
	cld			; String ops forwardly
DISP_CPDMSG_NEXT:
	lods	YGROUP:[si].LO	; Get next character from message

	cmp	al,EOS		; Izit string terminator?
	je	near ptr DISP_CPDMSG_DONE ; Jump if so

	cmp	al,CR		; Izit line ending?
	je	short DISP_CPDMSG_CR ; Jump if so

	cmp	al,LF		; Izit newline?
	je	short DISP_CPDMSG_LF ; Jump if so

	cmp	al,'%'          ; Izit substitution?
	je	short DISP_CPDMSG_SUB ; Jump if so

	cmp	al,-1		; Izit time to pause?
	je	short DISP_CPDMSG_PAUSE ; Jump if so
DISP_CPDMSG_SAVE:
	mov	ah,07h		; Use white on black attribute
S16	stos	es:[di].ELO	; Save in screen

	jmp	short DISP_CPDMSG_NEXT ; Go around again

DISP_CPDMSG_LF:

; If we're at the last row, scroll the screen up by one row

	cmp	CPDOFF,24*2*80	; Izit the last row?
	jb	short DISP_CPDMSG_NOSCROLL ; Jump if not

	REGSAVE <si,di> 	; Save for a moment

	xor	di,di		; ES:DI ==> top of screen (destin)
	lea	si,es:[di+2*80] ; ES:SI ==> line 1 of screen (source)
	mov	cx,(24*2*80)/4	; CX = # dwords to scroll
S16 rep movs	<es:[di].EDD,es:[si].EDD> ; Move screen up one line

	REGREST <di,si> 	; Restore

; Blank the last line

	push	di		; Save for a moment

	mov	ax,0720h	; Fill with this value
	mov	cx,2*80 	; Get length of one screen row
    rep stos	es:[di].ELO	; Blank the line

	pop	di		; Restore

	jmp	short @F	; Check for time to pause

DISP_CPDMSG_NOSCROLL:
	add	di,2*80 	; Skip to next line
@@:

; Check for time to pause

	inc	CPDCNT		; Count in another line

	cmp	CPDCNT,@CPDCNT	; Izit time to pause?
	jb	short DISP_CPDMSG_NOPAUSE ; Jump if not
DISP_CPDMSG_PAUSE:
	in	al,@IMR 	; Get the current IMR mask

	test	al,mask $IRQ1	; Is the keyboard enabled?
	jnz	short DISP_CPDMSG_NOPAUSE ; Jump if not

	mov	CPDCNT,0	; Reset for the next time

	CPD	'Pausing, press any key to continue...'

	KEYCALL @GETKEY 	; Return with AX = keycode
DISP_CPDMSG_NOPAUSE:
	jmp	short DISP_CPDMSG_NEXT ; Go around again

DISP_CPDMSG_CR:
	call	ROUND_SCRDN	; Round DI down to the last screen row

	jmp	short DISP_CPDMSG_NEXT ; Go around again

DISP_CPDMSG_SUB:
	lods	YGROUP:[si].LO	; Get next character from message

	cmp	al,'%'          ; Izit real percent sign?
	je	short DISP_CPDMSG_SAVE ; Jump if so

	mov	ah,al		; Copy for later use
	lods	YGROUP:[si].LO	; Get next character from message
	or	ax,2020h	; Convert to lowercase

	cmp	ax,'fl'         ; Izit FL?
	mov	bx,[ebp].DISPCPD_FL ; Assume so
	je	near ptr DISP_CPDMSG_WORD1 ; Jump if so

	cmp	ax,'ip'         ; Izit IP?
	mov	bx,[ebp].DISPCPD_CSIP.VOFF ; Assume so
	je	near ptr DISP_CPDMSG_WORD1 ; Jump if so

	cmp	ax,'cs'         ; Izit CS?
	mov	bx,[ebp].DISPCPD_CSIP.VSEG ; Assume so
	je	near ptr DISP_CPDMSG_WORD1 ; Jump if so

	cmp	ax,'ds'         ; Izit DS?
	mov	bx,[ebp].DISPCPD_DS ; Assume so
	je	near ptr DISP_CPDMSG_WORD1 ; Jump if so

	cmp	ax,'es'         ; Izit ES?
	mov	bx,[ebp].DISPCPD_ES ; Assume so
	je	near ptr DISP_CPDMSG_WORD1 ; Jump if so

	cmp	ax,'fs'         ; Izit FS?
	mov	bx,[ebp].DISPCPD_FS ; Assume so
	je	near ptr DISP_CPDMSG_WORD1 ; Jump if so

	cmp	ax,'gs'         ; Izit GS?
	mov	bx,gs		; Assume so
	je	near ptr DISP_CPDMSG_WORD1 ; Jump if so

	cmp	ax,'ss'         ; Izit SS?
	mov	bx,ss		; Assume so
	je	near ptr DISP_CPDMSG_WORD1 ; Jump if so

	cmp	ax,'cr'         ; Izit CRn?
	je	short DISP_CPDMSG_CRn ; Jump if so

	cmp	ah,'e'          ; Izit extended register?
	je	near ptr DISP_CPDMSG_EXTREG ; Jump if so

	xor	ebx,ebx 	; Initialize index into CPD register table
	mov	cx,CPDREGTAB_LEN ; CX = # entries in ...
@@:
	cmp	ax,CPDREGTAB[bx] ; Check next entry
	je	near ptr DISP_CPDMSG_WORD ; Jump if it's a match

	add	bx,type CPDREGTAB ; Skip to next entry

	loop	@B		; Jump if more entries

; No match:  Check for byte registers

	cmp	ax,'al'         ; Izit AL?
	mov	bx,PUSHAD_EAX.ELO.LO ; Assume so
	je	near ptr DISP_CPDMSG_BYTE ; Jump if so

	cmp	ax,'ah'         ; Izit AH?
	mov	bx,PUSHAD_EAX.ELO.HI ; Assume so
	je	near ptr DISP_CPDMSG_BYTE ; Jump if so

	cmp	ax,'bl'         ; Izit BL?
	mov	bx,PUSHAD_EBX.ELO.LO ; Assume so
	je	near ptr DISP_CPDMSG_BYTE ; Jump if so

	cmp	ax,'bh'         ; Izit BH?
	mov	bx,PUSHAD_EBX.ELO.HI ; Assume so
	je	short DISP_CPDMSG_BYTE ; Jump if so

	cmp	ax,'cl'         ; Izit CL?
	mov	bx,PUSHAD_ECX.ELO.LO ; Assume so
	je	short DISP_CPDMSG_BYTE ; Jump if so

	cmp	ax,'ch'         ; Izit CH?
	mov	bx,PUSHAD_ECX.ELO.HI ; Assume so
	je	short DISP_CPDMSG_BYTE ; Jump if so

	cmp	ax,'dl'         ; Izit DL?
	mov	bx,PUSHAD_EDX.ELO.LO ; Assume so
	je	short DISP_CPDMSG_BYTE ; Jump if so

	cmp	ax,'dh'         ; Izit DH?
	mov	bx,PUSHAD_EDX.ELO.HI ; Assume so
	je	short DISP_CPDMSG_BYTE ; Jump if so

; No match:  SI points past %xx

	sub	si,2		; Back up to char after '%'
	mov	al,'%'          ; Display this one

	jmp	DISP_CPDMSG_SAVE ; Join common code

DISP_CPDMSG_CRn:
	lods	YGROUP:[si].LO	; Get next character from message

	cmp	al,'0'          ; Izit CR0?
	mov	ebx,cr0 	; Assume so
	je	short DISP_CPDMSG_DWORD1 ; Jump if so

	cmp	al,'2'          ; Izit CR2?
	mov	ebx,cr2 	; Assume so
	je	short DISP_CPDMSG_DWORD1 ; Jump if so

	cmp	al,'3'          ; Izit CR3?
	mov	ebx,cr3 	; Assume so
	je	short DISP_CPDMSG_DWORD1 ; Jump if so

; No match:  SI points past %xxx

	sub	si,3		; Back up to char after '%'
	mov	al,'%'          ; Display this one

	jmp	DISP_CPDMSG_SAVE ; Join common code

DISP_CPDMSG_EXTREG:
	mov	ah,al		; Copy for later use
	lods	YGROUP:[si].LO	; Get next character from message
	or	al,20h		; Convert to lowercase

	xor	ebx,ebx 	; Initialize index into CPD register table
	mov	cx,CPDREGTAB_LEN ; CX = # entries in ...
@@:
	cmp	ax,CPDREGTAB[bx] ; Check next entry
	je	short DISP_CPDMSG_DWORD ; Jump if it's a match

	add	bx,type CPDREGTAB ; Skip to next entry

	loop	@B		; Jump if more entries

; No match:  SI points past %xxx

	sub	si,3		; Back up to char after '%'
	mov	al,'%'          ; Display this one

	jmp	DISP_CPDMSG_SAVE ; Join common code

DISP_CPDMSG_DWORD:
	mov	ebx,[ebp+ebx*2].DISPCPD_EGP.EDD ; Get the dword register value
DISP_CPDMSG_DWORD1:
	mov	cx,8		; # nibbles to display

	jmp	short DISP_CPDMSG_COM ; Join common code

DISP_CPDMSG_WORD:
	mov	bx,[ebp+ebx*2].DISPCPD_EGP.ELO ; Get the word register value
DISP_CPDMSG_WORD1:
	shl	ebx,16		; Shift to high-order word
	mov	cx,4		; # nibbles to display

	jmp	short DISP_CPDMSG_COM ; Join common code

DISP_CPDMSG_BYTE:
	mov	bh,[ebp+ebx].DISPCPD_EGP.LO ; Get the byte register value
	shl	ebx,16		; Shift to high-order word
	mov	cx,2		; # nibbles to display

	jmp	short DISP_CPDMSG_COM ; Join common code

DISP_CPDMSG_COM:
	rol	ebx,4		; Rotate next nibble to low-order
	movzx	eax,bl		; Copy to format
	and	al,@NIB0	; Isolate the nibble
	mov	al,HEXTABLE[eax] ; Get the ASCII character
	mov	ah,07h		; Use white on black attribute
S16	stos	es:[di].ELO	; Save in screen

	loop	DISP_CPDMSG_COM ; Jump if more nibbles to format and display

	jmp	DISP_CPDMSG_NEXT ; Go around again

DISP_CPDMSG_DONE:
	mov	CPDOFF.ELO,di	; Save for next time

; Update the cursor position in the BIOS data area

	mov	ax,di		; Copy buffer offset

	xor	dx,dx		; Zero upper dword for division
	mov	cx,2*80 	; Get # chars/attrs in a line
	div	cx		; Divide to get
				; AX = rows # (origin-0)
				; DX = cols # (origin-0)
	mov	dh,al		; (DH,DL) = (row,col)

	mov	bx,seg BIOSDATA ; Get segment of BIOS data area
	mov	ds,bx		; Address it
	assume	ds:BIOSDATA	; Tell the assembler about it

	mov	CURSOR_POSN[0],dx ; Save for later use

	REGREST <fs,es,ds>	; Restore
	assume	ds:nothing,es:nothing,fs:nothing ; Tell the assembler about it
	popad			; Restore all EGP registers
DISP_CPDMSG_EXIT:
	popf			; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CPDMSG endp		; End DISP_CPDMSG procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	NPPROC	ROUND_SCRDN -- Round Down to Last Screen Row
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Round down to last screen row

On entry:

DI	=	offset in ES of current screen position

On exit:

DI	=	value rounded down

|

	REGSAVE <ax,cx> 	; Save registers

	mov	ax,di		; Copy to skip to prev line

	push	dx		; Save for a moment

	xor	dx,dx		; Zero upper dword for division
	mov	cx,2*80 	; Get # chars/attrs in a line
	div	cx		; Divide to get
				; AX = rows # (origin-0)
				; DX = cols # (origin-0) (ignored)
	mul	cx		; Times # chars/attrs in a line
				; DX:AX = product
	mov	di,ax		; Copy as starting offset in buffer

	pop	dx		; Restore

	REGREST <cx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROUND_SCRDN endp		; End ROUND_SCRDN procedure
endif				; IF @OEM_DEBUG
	NPPROC	CHECK_SHIFT -- Check on Keyboard Shift State
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check keyboard shift states.

If either of the Alt-keys are down, don't install.
If either of the Ctrl-keys are down, signal INT 03h.
If either of the Shift-keys are down, allow CPD debugging.

On exit:

CF	=	0 if not all three keys down
	=	1 if a Ctrl- and Alt- and Shift-key are all pressed.

|
.8086
	REGSAVE <ax,bx> 	; Save registers

	KEYCALL @GETSHF 	; Get key shift states into AL

if @OEM_DEBUG
	test	al,(mask $DLSH) or (mask $DRSH) ; Is there shifting business?
	jz	short CHECK_SHIFT_XSHF ; Jump if not

	push	ds		; Save for a moment

	mov	bx,seg XGROUP	; Get segment of CPD_FLAG
	mov	ds,bx		; Address it
	assume	ds:XGROUP	; Tell the assembler about it

	or	CPD_FLAG,@CPD_MSG ; Mark as allowing Checkpoint Debugging

	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler about it
CHECK_SHIFT_XSHF:
endif				; IF @OEM_DEBUG
	test	al,mask $DALT	; Is there pressing business?
	jz	short CHECK_SHIFT_XALT ; Jump if not

	lea	ax,YGROUP:MSG_ABORT ; Tell 'em we're not installing
	push	ax		; Pass as argument
	call	YMSGOUT2	; Display YGROUP message

	stc			; Indicate we should abort

	jmp	short CHECK_SHIFT_EXIT ; Join common exit code

CHECK_SHIFT_XALT:
	test	al,mask $DCTL	; Is there any other pressing business?
	jz	short CHECK_SHIFT_EXIT ; Jump if not (note CF=0)

	call	LCL_INT03	; Call the resident debugger
CHECK_SHIFT_EXIT:
	REGREST <bx,ax> 	; Restore

	ret			; Return to caller
DOT386 p
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SHIFT endp		; End CHECK_SHIFT procedure
	FPPROC	CHECK_BPI -- Check on Breakpoint Interrupt
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we should generate a breakpoint interrupt

This routine is called with a preceding PUSHF so we
must exit with an IRET.

|

	test	DBG_FLAG,@DBG_CAPS ; Breakpoint if CapsLock on?
	jz	short CHECK_BPI_NOCAPS ; Not this time

	push	ax		; Save for a moment

	KEYCALL @GETSHF 	; Get the shift state into AL

	test	al,mask $CP	; CapsLock on?
	pop	ax		; Restore
	jz	short CHECK_BPI_NOCAPS; Jump if not

	call	LCL_INT03	; Call the resident debugger
CHECK_BPI_NOCAPS:
	iret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BPI endp			; End CHECK_BPI procedure
	NPPROC	CHECK_INFO -- Check IDN Information
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check and display IDN information.

On exit:

CF	=	0 if all went OK
	=	1 if something went wrong
CX	=	1 if a one-line message was displayed (ignored here)
	=	0 if not

|

	REGSAVE <cx,ds> 	; Save registers

	push	seg XGROUP	; Ensure DS points to IDENTIFY
	pop	ds		; Address it
	assume	ds:XGROUP	; Tell the assembler about it

ife @OEM_INST
	cmp	IDENT_CHK,0	; Has it been filled in as yet?
	je	short CHECK_INFO_EXIT ; Jump if not (note CF=0)
endif

	CHKIDN	@STD_OUT,@STD_OUT ; Check and display all messages to
				; standard output
				; Return with CX and CF significant
				; Ignore CX
;;;;;;; jcxz	CHECK_INFO_EXIT ; Jump if no message displayed
;;;;;;;
;;;;;;; pushf			; Save CF
;;;;;;; call	CHECK_LINE	; Count in another line and check for pause
;;;;;;; popf			; Restore CF
CHECK_INFO_EXIT:
	REGREST <ds,cx> 	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_INFO endp 		; End CHECK_INFO procedure
	NPPROC	CHECK_NDP -- Check on NDP Status
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine if there is an NDP (either a 287 or 387) in the system.
If there is, set @LCL_NDPIN, otherwise leave it clear.

Because some IBM PC/ATs and 3270/ATs without an NDP don't handle
floating-point instructions correctly, we rely upon the equipment
flags to tell us if there's an NDP installed.

This behavior is also present on some 386s.

|

	REGSAVE <eax>		; Save register

	xor	eax,eax 	; Zero entire register
	int	11h		; Get equipment flags into EAX

	test	ax,mask $I11_NDP ; Check NDP-installed bit
	jz	short CHECK_NDP2 ; Jump if not installed

	smsw	ax		; Get machine status word

	test	ax,mask $ET	; Check for 287 vs. 387
	jz	short CHECK_NDP1 ; Jump if it's a 287

; Check for EMC87 from Cyrix
; If the high-order bit of 387 control word sticks at 1,
; then an EMC87 is present

	fninit			; Set NDP to a known state
	fnstcw	CTL387		; Save control word

; Unfortunately, some systems don't handle NDP instructions well
; even without the WAIT opcode if there's no NDP installed.  Thus
; if the system board switch is mis-set, we could lockup the system
; with the FLDCW instruction if we attempt it.	Instead, we'll
; validate the value stored in CTL387 and proceed only if it looks OK.

	mov	ax,CTL387	; Get the control word
	and	ax,@CWMASK	; Isolate selected parts

	cmp	ax,@CWVALID	; Check for valid value
	jne	short CHECK_NDP_EXIT ; Join common exit code

	or	CTL387,@BIT15	; Set high-order bit
	fldcw	CTL387		; Load it back
	fnstcw	CTL387		; Save again to check for stickiness

	test	CTL387,@BIT15	; Izit sticky?
	jz	short CHECK_NDP1 ; Jump if not (must be Intel 387)

; As the bit has no other meaning, we leave the bit set

	or	NRD_FLAG,@NRD_EMC87 ; Mark as present to enable presence later
	call	FCN_WTKF	; Force it present (ES=PGROUP)
CHECK_NDP1:
	or	LCL_FLAG,@LCL_NDPIN ; Mark as installed
	or	CPUFET_FLAG,@CPUFET_NDPIN ; Mark as installed, really
CHECK_NDP2:
if @OEM_WTK
	test	eax,@BIT24	; Check for Weitek 1167
	jz	short @F	; Jump if not installed

	call	FCN_WTKF	; Force it present (ES=PGROUP)
@@:
endif				; IF @OEM_WTK
CHECK_NDP_EXIT:
	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_NDP endp			; End CHECK_NDP procedure
	NPPROC	CHECK_XBIOS -- Check On XBIOS Relocatability
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on XBIOS relocatability.

Note that this routine *MUST* be called before CHECK_CNV.

If present and relocatable, setup variables:

XBIOS_SRC ==>	 current XBIOS data area
XBIOS_SIZ  =	 size of XBIOS data area in bytes
XBIOS_DOS =	 size of DOS in 1KB after XBIOS relocated

XBIOS_DST to be filled in later.  If the XBDA exists but its
length is defined as 0, don't attempt to relocate it.

|

	REGSAVE <ax,es> 	; Save registers

; Ensure the extended BIOS data area is at the top of memory

	push	seg BIOSDATA	; Get segment of BIOS data area
	pop	es		; Address it
	assume	es:BIOSDATA	; Tell the assembler about it

	mov	ax,MEMORY_SIZE	; Get current memory size
	shl	ax,10-4 	; Convert from 1KB to paras

	cmp	ax,XBDA_SEG	; Check against XBDA segment
	jne	short CHECK_XBIOS_EXIT ; Jump if not

	mov	XBIOS_SRC.VSEG,ax ; Save as source segment

	mov	es,ax		; Address it
	assume	es:XBIOS	; Tell the assembler about it

	int	12h		; AX = KBs of conventional memory
.8086
	mov	XBIOS_DOS,ax	; Save as current DOS memory size
DOT386 p

	movzx	ax,XBIOS_SIZE	; Get size of area in 1KB
	or	ax,ax		; Izit 0?
	jz	short CHECK_XBIOS_EXIT ; Jump if so

.8086
	add	XBIOS_DOS,ax	; Add into new low DOS memory size
DOT386 p
	shl	ax,10-0 	; Convert from 1KB to bytes
.8086
	mov	XBIOS_SIZ,ax	; Save as length in bytes if loaded low
DOT386 p

	or	I15_FLAG,@I15_XBREL ; Mark as relocatable
CHECK_XBIOS_EXIT:
	REGREST <es,ax> 	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XBIOS endp		; End CHECK_XBIOS procedure
	FPPROC	CHECK_CNV -- Check On Conventional Memory
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on conventional memory.

Fill in LOWOFF, OLDDOS, and PaMAX.

|

	REGSAVE <eax,cx>	; Save registers

	mov	eax,PHYSIZE	; Get top of physical memory
	shl	eax,10-0	; Convert from 1KB to bytes
	mov	PaMAX,eax	; Save as current maximum physical address

	mov	ax,XBIOS_DOS	; Get size of DOS in 1KB if XBIOS relocated

	test	I15_FLAG,@I15_XBREL ; Izit to be relocated?
	jnz	short @F	; Jump if so

	int	12h		; AX = KBs of conventional memory
@@:

; If AX isn't on a 64KB boundary, then we assume we can't fill
; in low DOS memory
; For example, on an MCA-compatible machine, there is a hole at 639KB
; (9FC0h in paras) for the 1KB data area.  With certain RLL controllers,
; the top 2 KB of conventional memory is stolen for RAM storage.
; The HP Vectra RS/16 and /20 also steal 4 or 8 KB of DOS memory.

	test	ax,64-1 	; Izit a multiple of 64KB?
	jz	short CHECK_CNV1 ; Yes, it's OK to fill

	or	CMD_FLAG,@CMD_XLO ; Mark as if user said no low fill
	mov	LOWSIZE,0	; Ensure zero
CHECK_CNV1:
	mov	cx,ax		; Copy to compute LOWOFF
	add	cx,64-1 	; Round up to 64KB boundary
	and	cx,not (64-1)
	mov	LOWOFF.ELO,cx	; Save for later use

	mov	cl,10-4 	; Shift amount between 1KB and paras
				; Note we don't know yet if this CPU supports
				; multibit shifts
	shl	ax,cl		; Convert from 1KB to paras
	mov	OLDDOS,ax	; Save for later use

	REGREST <cx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CNV endp			; End CHECK_CNV procedure
if @OEM_WIN3
	NPPROC	CALC_WIN3 -- Calculate Values Needed by Windows 3
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate values needed by Windows 3.
These values depend upon other values calculated in CALC_SIZE,
so we must be sure that this call follows CALC_SIZE.

|

	REGSAVE <eax,ebx,es>	; Save registers

; Fill in linear address of reference data structure into the SIS

	lea	eax,WIN3_REF_DATA ; Get offset in PGROUP of Win3 ref data
	add	eax,PaPRGBASE	; Plus physical of start of code/data
	mov	WIN3_STARTUP.SIS_REFERENCE_DATA,eax ; Move to Windows struc

; Setup the REFERENCE_DATA_STR for VxD

	mov	eax,PaPRGBASE	; Get physical of start of code/data
	add	eax,PUMB_INST	; Plus offset of local instance table
	mov	WIN3_REF_DATA.REF_UMB_INST,eax ; Save for VxD

; Note that WIN3_REF_DATA.REF_OLDDOS has never been used by a retail VxD.
; For 386MAX 5.13 and newer, it's location in the structure has been
; replaced by REF_STRUC_VER

;;;;;;	 mov	 ax,OLDDOS	; Get original top of DOS in paras
;;;;;;	 mov	 WIN3_REF_DATA.REF_OLDDOS,ax ; Save for VxD

	mov	WIN3_REF_DATA.REF_STRUC_VER,@REF_STRUC_VER ; Save version #
	mov	WIN3_REF_DATA.REF_STRUC_LEN,(type REF_DATA_STR) ; Save length

	mov	ax,POVR_MAC	; Segment of 1st MAC in high DOS (-1 if none)
	mov	WIN3_REF_DATA.REF_OVRMAC,ax ; Save for VxD

; Find start of DOS device header chain and stick into reference data structure

	DOSCALL @GETLST 	; Get DOS variables
	assume	es:nothing	; Tell the assembler about it

	mov	ax,es:[bx-2]	; Get segment of MAC entry pointer
	mov	WIN3_REF_DATA.REF_P1MAC,ax ; Save into struct for VxD

	add	bx,22h		; ES:BX is start of device header chain

	xor	eax,eax 	; Clear to use as dword
	mov	ax,es		; Get real mode segment
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	ebx,bx		; Isolate the offset
	add	eax,ebx 	; Form linear address of start of device header

	mov	WIN3_REF_DATA.REF_DOS_DEV_HDR,eax ; Save into struct for VxD

; Setup related to the PGROUP selectors

	mov	eax,PaPRGBASE	; Get physical of start of code/data
	mov	WIN3_REF_DATA.REF_MAXPHYS,eax ; Save into struct for VxD

	movzx	eax,PRGSIZE	; Get size of program in 1KB
	shl	eax,10-0	; Convert from 1KB to bytes
	mov	WIN3_REF_DATA.REF_MAXLEN,eax ; Save into struct for VxD

; Setup related to the IGROUP selectors

	mov	eax,IGRBASE	; Base of IGROUP
	sub	eax,PRGBASE	; Offset from PGROUP to IGROUP
	add	eax,PaPRGBASE	; Physical address of IGROUP
	mov	WIN3_REF_DATA.REF_IGRPHYS,eax ; Save into struct for VxD

	mov	eax,IGRSIZE	; Get size of IGROUP in bytes
	mov	WIN3_REF_DATA.REF_IGRSIZE,eax ; Save into struct for VxD

; Setup related to the JGROUP selectors

	mov	eax,JGRBASE	; Base of JGROUP
	sub	eax,PRGBASE	; Offset from PGROUP to JGROUP
	add	eax,PaPRGBASE	; Physical address of JGROUP
	mov	WIN3_REF_DATA.REF_JGRPHYS,eax ; Save into struct for VxD

	mov	eax,JGRSIZE	; Get size of JGROUP in bytes
	mov	WIN3_REF_DATA.REF_JGRSIZE,eax ; Save into struct for VxD

; Setup related to the FGROUP selector

	mov	eax,FGRBASE	; Base of FGROUP
	sub	eax,PRGBASE	; Offset from PGROUP to FGROUP
	add	eax,PaPRGBASE	; Physical address of FGROUP
	mov	WIN3_REF_DATA.REF_FGRPHYS,eax ; Save into struct for VxD

	mov	eax,FGRSIZE	; Get size of FGROUP in bytes
	mov	WIN3_REF_DATA.REF_FGRSIZE,eax ; Save into struct for VxD

; Setup related to the FAR CALL interface between 386MAX.SYS and the VxD

	lea	eax,XMS_VXD2MAX ; Get offset in PGROUP of VxD to MAX XMS call
	mov	WIN3_REF_DATA.REF_XMS_VXD2MAX.FOFF,eax ; Save in ref data VxD

	lea	eax,UTL_VXD2MAX ; Offset in PGROUP of VxD to MAX utility call
	mov	WIN3_REF_DATA.REF_UTL_VXD2MAX.FOFF,eax ; Save in ref data VxD

	lea	eax,FIXUP_ISELS ; PGROUP offset of VxD -> MAX FIXUP procedure
	mov	WIN3_REF_DATA.REF_FIXUP_ISELS.FOFF,eax ; Save in ref data VxD

	mov	eax,PCFGFILE	; Plus offset to CFGFILE data

	and	eax,eax 	; Izit present?
	jz	short @F	; Jump if not

	add	eax,PaPRGBASE	; Get physical of start of code/data
	mov	WIN3_REF_DATA.REF_CFGFILE,eax ; Save into struct for VxD
@@:

; These map items can be handled by the PM VxD code as long as CR3 is known

	REGREST <es,ebx,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_WIN3 endp			; End CALC_WIN3 procedure
endif				; IF @OEM_WIN3
	NPPROC	CHECK_DOSVER -- Check DOS Version
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're running on DOS 3.00 or later

On exit:

CF	=	0 if all went OK
	=	1 otherwise

|

	REGSAVE <eax,ebx,cx,dx,di,es> ; Save registers

	DOSCALL @DOSVER 	; Return with
				; AL=major
				; AH=minor
				; BX=CX=0
	xchg	al,ah		; Swap to comparison order

	mov	DOSVER,ax	; Save for later use

; Search for the version # in CMDCOM_VER and put the
; corresponding entry from CMDCOM_SIZ into CMDCOM_PAR, and the
;;; ; corresponding entry from PPMAC_OFF  into PPMAC_HEAD.VOFF

	lea	di,CMDCOM_VER	; ES:DI ==> version #s
	mov	cx,CMDCOM_NVER	; CX = # entries in CMDCOM_VER
  repne scas	CMDCOM_VER[di]	; Search for it
	jne	short CHECK_DOSVER1 ; Not found case handled by extra entry
				; at end of CMDCOM_SIZ
	or	NRD_FLAG,@NRD_VER ; Mark as version # found
CHECK_DOSVER1:
	sub	di,offset es:CMDCOM_VER[2] ; Convert to origin-0

	mov	ax,CMDCOM_SIZ[di] ; Get relevant size
	mov	CMDCOM_PAR,ax	; Save for later use

;;;;;;; mov	ax,PPMAC_OFF[di] ; Get PPMAC offset
;;;;;;; mov	PPMAC_HEAD.VOFF,ax ; Save for later use
;;;;;;;

; If this is DOS 5.0 or later, save the maximum move address passed
; to us by the CONFIG.SYS processor

	cmp	DOSVER,0500h	; Izit DOS 5.0 or later?
	jb	short @F	; Jump if not

	les	bx,RH_VEC	; ES:BX ==> request header
	assume	es:nothing	; Tell the assembler about it

	mov	ax,es:[bx].INIT_END_VEC.VSEG ; Get ending segment
	mov	MAXMOVE,ax	; Save for later use
@@:

; Get the pointer to the InDOS flag and save it as a linear address

	DOSCALL @DOSPTR 	; Return ES:BX ==> DOS call level byte (internal)
	assume	es:nothing	; Tell the assembler about it

	xor	eax,eax 	; Zero to use as dword
	mov	ax,es		; Copy the segment
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	ebx,bx		; Zero to use as dword
	add	eax,ebx 	; Add to get the linear address
	mov	LaINDOS,eax	; Save for later use

	clc			; Indicate all went well

	REGREST <es,di,dx,cx,ebx,eax> ; Restore
	assume	es:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DOSVER endp		; End CHECK_DOSVER procedure
	NPPROC	CHECK_EXT -- Get Size of Extended Memory
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get size of extended memory

If the INT 15h value is zero,
and there's a previous XMS handler,
and we're not on an XT,
then get the value from CMOS as the previous XMS handler
might have closed off extended memory.

In case QEXT.SYS is loaded before us, we check for 64KB or above.

On exit:

CF	=	0 if all went well
	=	1 There was an error determining system memory

|

	REGSAVE <eax,ebx,ecx,edx> ; Save registers

; See if COMPAQ/Phoenix/maybe others memory function works

	xor	cx,cx		; Set to known value
	xor	dx,dx		; ...
	mov	ax,0E801h	; Get function code to return extended memory
	int	15h		; Request BIOS service
				; Return AX = installed extmem in 1KB up to 16MB
				; ...	 BX = ..		 64KB above 16MB
				; ...	 CX = configured extmem in 1KB up to 16MB
				; ...	 DX = ..		 64KB above 16MB
	jcxz	@F		; Jump if not supported

	movzx	eax,cx		; Get extended memory up to 16MB in 1KB
	movzx	edx,dx		; Zero to use as dword
	shl	edx,16-10	; Convert from 64KB to 1KB
	add	eax,edx 	; Plus extmem up to 16MB

	jmp	CHECK_EXT2	; Join common code

@@:

; See if the AMI BIOS PCI Memory Function works

	mov	ax,0DA88h	; Get function code to return extended memory
	int	15h		; Request BIOS service
				; Return extended memory in CL:BX, AX=0
	cmp	ax,0		; Did it work?
	jne	short @F	; Jump if not

	mov	al,cl		; Copy the high-order byte (AH already zero)
	shl	eax,16		; Shift to high-order word
	mov	ax,bx		; Copy low-order word

	jmp	short CHECK_EXT2 ; Join common code

@@:
	mov	ah,88h		; Function code to get size of extended memory
	int	15h		; Request service, result in AX in 1KB blocks
	movzx	eax,ax		; Zero to use as dword

	cmp	ax,64		; Check for any memory above 64KB
	ja	short CHECK_EXT1 ; Jump if there's some

	test	XMS_FLAG,mask $XMS_OLD ; Izit previously installed?
	jz	short CHECK_EXT1 ; Jump if not

; If we're not on an XT, get the size of extended memory from CMOS

	test	LCL_FLAG,@LCL_XT ; Izit an XT?
	jnz	short CHECK_EXT1 ; Jump if so

	mov	dx,@CMOS_CMD	; Get CMOS command port
	mov	al,@CMOS_EXTHI	; Get extended memory size, high byte
	call	FOUTCMOS	; Out to CMOS, conditional read

	mov	ah,al		; Copy to high-order byte

	mov	al,@CMOS_EXTLO	; Get extended memory size, low byte
	call	FOUTCMOS	; Out to CMOS, conditional read
CHECK_EXT1:
	test	NRD_FLAG,@NRD_EISA ; Izit an EISA machine?
	jz	short CHECK_EXT2 ; Skip if not EISA

	mov	edx,eax 	; Save amount of fn 88 memory

	CPD	'Calling CHECK_EISA_EXT, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	push	dword ptr ((1024*1024)/1024) ; Pass starting address in 1KB
	call	CHECK_EISA_EXT	; Check for any EISA super extended memory
				; Return with EISA super ext. memory in EAX
				; and lowest extra RAM address in EBX (unit=1KB)
	jc	short CHECK_EXT_EXIT ; Jump if there was an error in EISA land
				; (note CF=1)

; If there's extra non-contiguous RAM above the normal EISA memory,
; save it for later use.

	call	CHECK_EISA_SHD	; Check on memory at EBX*1024

	xchg	eax,edx 	; Assume we're going to use fn88 memory

	cmp	eax,edx 	; Is fn 88 memory greater than EISA memory?
	jae	short CHECK_EXT2 ; Jump if so

	CPD	'Calling VALIDATE_EISAMEM, CS:IP=%CS:%IP  DS=%DS  ES=%ES'
	CPD	'                          EAX=%EAX EDX=%EDX'

	call	VALIDATE_EISAMEM ; Validate the EISA memory that we found
	jc	short CHECK_EXT2 ; Jump if EISA memory is not safe to use

	mov	eax,edx 	; Use EISA findings as total ext memory
CHECK_EXT2:
	and	eax,not (4-1)	; Round down to a multiple of four

	mov	ebx,@MAX_EMSMEM ; Get maximum EMS in 1MB
	shl	ebx,10-0	; Convert from 1MB to 1KB

	cmp	eax,ebx 	; Izit within what we can handle?
	jbe	short @F	; Jump if so

	add	eax,1024	; Plus first megabyte
	mov	WINSIZE,eax	; Save as maximum size for Windows

	CPD	'WINSIZE=%EAX'

	mov	eax,ebx 	; Use the maximum
@@:
	CPD	'TOTSIZE=%EAX'

	mov	TOTSIZE,eax	; Save for later use
	add	eax,1024	; Plus first megabyte
	mov	PHYSIZE,eax	; Save as top of physical memory

	clc			; Mark as successful
CHECK_EXT_EXIT:
	REGREST <edx,ecx,ebx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EXT endp			; End CHECK_EXT procedure
	NPPROC	CHECK_EISA_SHD -- Check On Extra EISA RAM
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on extra non-contiguous EISA RAM.

On entry:

EBX	=	lowest address of extra RAM (unit=1KB) (-1 if none)

On exit:

|

	REGSAVE <eax,ebx,ecx>	; Save registers

	test	CM2_FLAG,@CM2_X384 ; Is NOXRAM specified?
	jnz	short CHECK_EISA_SHD_EXIT ; Jump if so
CHECK_EISA_SHD_NEXT:
	cmp	ebx,-1		; Izit present?
	je	short CHECK_EISA_SHD_EXIT ; Jump if not

	mov	ecx,ebx 	; Copy starting address in 1KB

	push	ebx		; Pass starting address in 1KB
	call	CHECK_EISA_EXT	; Check for any EISA super extended memory
				; Return with EISA super ext. memory in EAX
				; and lowest extra RAM address in EBX
	add	eax,(1024*1024)/1024 ; Add back in the first 1MB

	sub	eax,ecx 	; Izit within reason?
	jbe	short @F	; Jump if not

	shl	ecx,10-0	; Convert from 1KB to bytes

	push	ax		; Amount of shadow RAM in 1KB
	push	ecx		; ...at this location
	call	SAVE_SHADOW	; Append to shadow RAM structure
@@:
	jmp	CHECK_EISA_SHD_NEXT ; Go around again

CHECK_EISA_SHD_EXIT:
	REGREST <ecx,ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EISA_SHD endp		; End CHECK_EISA_SHD procedure
	NPPROC	CHECK_VDS -- Check On Previous VDS Handler
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on previous VDS handler

On exit:

CF	=	0 if all went well
	=	1 otherwise

|
	REGSAVE <eax,bx,cx,dx,di,es> ; Save registers

	mov	es,SBIOSDATA	; Get segnment of BIOS data area
	assume	es:BIOSDATA	; Tell the assembler about it

	test	VDS,@VDS_ENA	; Are VDS services available?
	jz	near ptr CHECK_VDS_EXIT ; Jump if not (note CF=0)

	mov	es,MAPSEG_NXT	; Get next available segment
	assume	es:nothing	; Tell the assembler about it

	xor	di,di		; ES:DI ==> scatter/gather lock XDDS
	mov	es:[di].XDDS_SIZE,-1 ; Length is 4GB

	mov	es:[di].XDDS_FVEC.FOFF,0 ; Start at the beginning of memory
	mov	es:[di].XDDS_FVEC.FSEL,0 ; ...

; Set table length to something reasonable about 126 entries

	mov	es:[di].XDDS_AVL,(1024-size XDDS_STR)/type XDDS_DATA

	xor	dx,dx		; Clear VDS flags
	VDSCALL @VDS_SLOCK	; Fill in DS:SI with scatter gather info
	jnc	short CHECK_VDS1 ; Go if no error

	CPD	'Error from @VDS_SLOCK,  CS:IP=%CS:%IP  DS=%DS  ES=%ES  AL=%AL'

	push	offset YGROUP:MSG_VDSERR ; Tell 'em the bad news
	call	YMSGOUT2	; Display YGROUP message

	stc			; Indicate something went wrong

	jmp	short CHECK_VDS_EXIT ; Join common exit code

CHECK_VDS1:
	xor	dx,dx		; Clear VDS flags
	VDSCALL @VDS_SUNLK	; Unlock the region

; Convert the size field into a cumulative sum
; which in effect converts the structure from
; RDDS_STR to VDDS_STR.

	mov	cx,es:[di].XDDS_USED ; Get the number of entries
	jcxz	CHECK_VDS2	; Jump if nothing to do

	xor	bx,bx		; Initialize index into table
	xor	eax,eax 	; Initialize accumulator
@@:
	add	eax,es:[bx+di].XDDS_DATA.RDDS_SIZE ; Plus current size
	mov	es:[bx+di].XDDS_DATA.VDDS_EPTA,eax ; Save as ending physical
				; translation address
	add	bx,size RDDS_STR ; Skip to next table entry

	loop	@B		; Jump if more entries to accumulate

; If the entries sum to 4GB (zero), change the last one to FFFFFFFF
; so we have proper ending physical translation address

	and	eax,eax 	; Izit 4GB (zero)?
	jnz	short CHECK_VDS2 ; Jump if not

	dec	eax		; Convert to proper limit
	mov	es:[bx+di-(size RDDS_STR)].XDDS_DATA.VDDS_EPTA,eax ; Save as cumulative size
CHECK_VDS2:

; Save segment of previous VDS table for later use in ENTERPM code (in NDATA)

	mov	VDSTAB_SEG,es	; Save segment of table

	movzx	eax,es:[di].XDDS_USED ; Get the number of entries
	imul	eax,type VDDS_STR ; Convert to bytes
	add	eax,offset XDDS_DATA ; Add in the size of the header
	mov	VDSTAB_LEN,eax	; Save for later use

	add	eax,16-1	; Round up to para boundary
	shr	eax,4-0 	; Convert to from bytes to paras

; Update MAPSEG_NXT to protect the saved memory

	add	MAPSEG_NXT,ax	; Set next available segment address

	clc			; Indicate all went well
CHECK_VDS_EXIT:
	REGREST <es,di,dx,cx,bx,eax> ; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VDS endp			; End CHECK_VDS procedure
	NPPROC	CHECK_EISA_EXT -- Get Size of EISA Extended Memory
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get size of extended memory by polling the EISA slots.
We already know we are on an EISA machine.
Start counting EISA memory from 1MB, not from top of fn 88 memory.

On exit:

EAX	=	Amount of EISA extended memory
EBX	=	Lowest address above EAX with extra non-contiguous
		 system RAM (-1 if none) in units of 1KB

Local Variables: EDI - Top of EISA memory place holder (units of 256 bytes)

|

CHKEISA_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
CHKEISA_START dd ?		; Starting address in bytes in 1KB

CHKEISA_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <cx,edx,si,edi,ds> ; Save registers

	mov	edi,[bp].CHKEISA_START ; Copy starting address in 1KB
	shl	edi,10-8	; Convert from 1KB to 256 bytes
	mov	ebx,-1		; Initialize lowest address with non-contiguous
				; system RAM (in units of 256 bytes)
	mov	ax,MAPSEG_NXT	; Get while we can still use PGROUP

	push	seg XGROUP	; Get new data segment
	pop	ds		; Address it
	assume	ds:XGROUP	; Tell the assembler about it

	mov	OLDCPQSTK_VEC.VSEG,ss ; Save old stack pointers
	mov	OLDCPQSTK_VEC.VOFF,sp ; ...

	push	seg XGROUP	; Get new stack segment
	pop	ss		; Address it
	assume	ss:nothing	; Tell the assembler about it
	lea	sp,CPQSTKZ	; SS:SP ==> new stack

	mov	ds,ax		; Setup DS for Slot buffer
	assume	ds:nothing	; Tell the assembler about it
EISA_START_SEARCH:
	xor	cx,cx		; Function 0 (CH), Slot 0 (CL)
GET_SUPER_FCN:
	xor	si,si		; DS:SI==> slot buffer
	mov	ax,ReadEISAFuncInfo ; Get Function Information

; Note: There are rude BIOSes that clobber registers that they aren't
;	supposed to.  Take precaution by saving and then restoring
;	all registers.	Some BIOSes (thanks Mylex) even disable
;	interrupts upon exit from the interrupt 15h call.

	REGSAVE <ebx,ecx,edx,esi,edi,ebp> ; Save general registers
	REGSAVE <ds,es,fs,gs>	; Save segment registers

	int	15h		; Request BIOS service
				; Return error code in AH
				; Update data strucutre at DS:SI

	sti			; Enable interrupts (Thanks Mylex)

	REGREST <gs,fs,es,ds>	; Restore segment registers
	REGREST <ebp,edi,esi,edx,ecx,ebx> ; Restore general registers

	jnc	short CHECK_SUP ; Jump if call was successful

	cmp	ah,80h		; Past all slots?
	je	near ptr ALL_SLOTS_COUNTED ; Yes

	cmp	ah,81h		; Invalid function number?
	je	short @F	; Yep, continue on

	cmp	ah,83h		; Empty slot?
	jne	near ptr CHECK_EISA_ERR ; Unknown error, display the bad news
@@:
	inc	cl		; Increment to next slot
	xor	ch,ch		; Start again at function 0

	jmp	short GET_SUPER_FCN ; Try next slot

CHECK_SUP:

; We have some configuration information,
; Check to see if it's a memory configuration

	test	[si].EISA_FUNC_INFO,mask $EISAFNC_MEM ; Izit a memory entry?
	jnz	short GET_ENTRY ; Yes
NO_MEMORY_ENTRIES:
	inc	ch		; No - bump to next function

	jmp	short GET_SUPER_FCN ; Go around again

GET_ENTRY:
	lea	si,[si].EISA_MEMCONFIG ; Point at memory configuration

; We have memory - Check to see if it is system (or other) memory

GOT_MEMORY_ENTRY:
	mov	al,[si].MEM_CONFIG ; Memory config byte

	test	al,mask $EISAMEM_RAM ; Izit RAM?
	jz	short NEXT_SUPER_ENTRY ; Jump if not

	and	al,mask $EISAMEM_MEMTYPE ; We need the memory config bits

	cmp	al,@EISAMEM_SYS shl $EISAMEM_MEMTYPE ; System memory?
	je	short CONT_CHK_ENTRY ; Yes

; Check to see if there are more memory entries in this function

NEXT_SUPER_ENTRY:
	test	[si].MEM_CONFIG,mask $EISAMEM_CONT ; More memory entries?
	jz	short NO_MEMORY_ENTRIES ; No

	add	si,size EISAMEM_STR ; Yes - bump to next memory entry

	jmp	short GOT_MEMORY_ENTRY ; Go around again

; We have system memory - Check to see if it is the next logical block

CONT_CHK_ENTRY:
	mov	edx,[si].MEM_START_LSB.EDD ; Get starting address (+ some)
	and	edx,00FFFFFFh	; Clear top byte of dword

	cmp	edx,edi 	; Is this the next logical block?
	je	short GOT_SUPER_BLOCK ; Jump if so
	jb	short NEXT_SUPER_ENTRY ; Jump if it's too low

; Check for lowest address above current high-water mark with system RAM
; First, is this incoming address in extended memory?

	cmp	edx,(1024*1024)/256 ; Izit at or above 1MB?
	jb	short @F	; Jump if not

	cmp	edx,ebx 	; Izit a new low?
	jae	short @F	; Jump if not

	mov	ebx,edx 	; Save as new low
@@:
	jmp	short NEXT_SUPER_ENTRY ; No, try the next block

; We have the next logical block of system memory

GOT_SUPER_BLOCK:
	movzx	edx,[si].MEM_LEN ; Memory size in 1 KB blocks

	shl	edx,(10-8)	; Convert from 256 bytes -> 1KB
	jnz	short NOT_64MB	; Skip if not 64 meg

	mov	edx,10000h shl (10-8) ; Make edx=64 Mbytes of 256 byte blocks
NOT_64MB:
	add	edi,edx 	; New top of memory

	cmp	ebx,edi 	; Check against lowest extra RAM address
	ja	short @F	; Jump if still valid

	mov	ebx,-1		; Invalidate the lowest extra RAM address
@@:
	jmp	near ptr EISA_START_SEARCH ; Go at it again (from beginning)

ALL_SLOTS_COUNTED:
	shr	edi,(10-8)	; Convert from 256 bytes -> 1KB
	sub	edi,(1024*1024)/1024 ; Subtract for the first 1MB
	mov	eax,edi 	; Return extended memory in EAX

	cmp	ebx,-1		; Is the lowest extra RAM address valid?
	je	short @F	; Jump if not

	shr	ebx,10-8	; Convert from 256 bytes to 1KB
@@:
	clc			; Mark as successful

	jmp	short CHECK_EISA_EXIT ; Continue on

CHECK_EISA_ERR:
	push	seg PGROUP	; Get data segment (needed for HEXTABLE)
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	mov	al,ah		; Get the error code
	lea	si,YGROUP:MSG_EISA_BAD1 ; YGROUP:SI ==> error code save area
	call	FMT_ERR_CODE	; Format the error code

	push	offset YGROUP:MSG_EISA_BAD ; Tell 'em the bad news
	call	YMSGOUT2	; Display YGROUP message

	stc			; Indicate something went wrong
CHECK_EISA_EXIT:
	push	seg XGROUP	; Get new data segment
	pop	ds		; Address it
	assume	ds:XGROUP	; Tell the assembler about it

	lss	sp,OLDCPQSTK_VEC ; Restore original stack pointer
	assume	ss:nothing	; Tell the assembler about it

	REGREST <ds,edi,si,edx,cx> ; Restore
	assume	ds:PGROUP	; Tell the assembler about it

	pop	bp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EISA_EXT endp		; End CHECK_EISA_EXT procedure
	NPPROC	VALIDATE_EISAMEM -- Ensure EISA memory is valid
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure any EISA memory that we plan to use is valid

If there is less than 16MB of EISA memory, assume that the memory is valid.
If there is more than 16MB of EISA memory, perform a 1024 byte Read/Write
test at 16MB, and at 256 KB increments, until we hit the top of
reported memory.

On entry:
EAX	=	Amount of fn88 memory (in KB)
EDX	=	Amount of EISA memory (in KB)

On exit:
CF	=	0 if the EISA memory is valid
		1 if not

|

@EISA_CMP_SIZE equ	 1024	; # of bytes to compare
@EISA_CMP_INC  equ	 256*1024 ; Extended memory increment size

	REGSAVE <eax,ecx,edx,esi,edi,es> ; Save registers

; Initialize input parameters

	shl	edx,(10-0)	; Convert KB to bytes

	cmp	edx,CON16MB	; Is there more than 16MB of EISA memory
	jbe	near ptr VALIDATE_EISAMEM_CLC ; Jump if not
				; We only need to test memory above 16 MB

; Initialize source (extended memory) and destination (local buffer)

	mov	esi,CON16MB	; Source is 16 MB line
	movzx	edi,MAPSEG_NXT	; Destin is next available free para
	mov	es,di		; Address MAPSEG
	assume	es:nothing	; Tell the assemblera bout it
	shl	edi,4-0 	; Convert from paras to bytes

VALIDATE_EISAMEM_NEXT:

; Save extended memory into primary buffer

	mov	ecx,@EISA_CMP_SIZE ; # bytes to read
	call	BIOS_BLOCK_MOVE ; Move from ext to cnv memory
	jc	near ptr VALIDATE_EISAMEM_STC ; Jump if error

; Copy the primary buffer to secondary buffer

	REGSAVE <si,di> 	; Save registers

	mov	cx,@EISA_CMP_SIZE/4 ; # dwords to copy
	xor	si,si		; Address primary buffer
	mov	di,@EISA_CMP_SIZE ; Address secondary buffer
S16 rep movs	<es:[di].EDD,es:[si].EDD> ; Move data to secondary buffer

; Negate the memory in secondary buffer (to create a unique pattern)

	mov	cx,@EISA_CMP_SIZE/4 ; # dwords to negate
	mov	si,@EISA_CMP_SIZE ; Address secondary buffer

@@:
	not	es:[si].EDD	; Negate the value
	add	si,4		; Next dword
	loop	@B		; Do for entire count

	REGREST <di,si> 	; Restore registers

; Write our pattern from secondary buffer to extended memory

	xchg	esi,edi 	; Switch source and destination
	add	esi,@EISA_CMP_SIZE ; Bump up to secondary buffer

	mov	ecx,@EISA_CMP_SIZE ; # bytes to read
	call	BIOS_BLOCK_MOVE ; Move from cnv to ext memory
	jc	short VALIDATE_EISAMEM_STC ; Jump if error

; Read our pattern back from extended memory into secondary buffer

	xchg	esi,edi 	; Switch source and destination

	mov	ecx,@EISA_CMP_SIZE ; # bytes to read
	call	BIOS_BLOCK_MOVE ; Move from ext to cnv memory
	jc	short VALIDATE_EISAMEM_STC ; Jump if error

; Write back original memory from primary buffer to extended memory

	xchg	esi,edi 	; Switch source and destination
	sub	esi,@EISA_CMP_SIZE ; Bump back to primary buffer

	mov	ecx,@EISA_CMP_SIZE ; # bytes to read
	call	BIOS_BLOCK_MOVE ; Move from cnv to ext memory
	jc	short VALIDATE_EISAMEM_STC ; Jump if error

; Negate pattern in secondary buffer to duplicate origianl pattern

	REGSAVE <si,di> 	; Save registers

	mov	cx,@EISA_CMP_SIZE/4 ; # dwords to negate
	mov	si,@EISA_CMP_SIZE ; Address secondary buffer

@@:
	not	es:[si].EDD	; Negate the value
	add	si,4		; Next dword
	loop	@B		; Do for entire count

; Compare primary and secondary buffers

	mov	cx,@EISA_CMP_SIZE/4 ; # dwords to negate
	xor	di,di		; Address primary buffer
	mov	si,@EISA_CMP_SIZE ; Address secondary buffer
   repe cmps	es:[di].EDD,es:[si].EDD ; Compare the buffers

	REGREST <di,si> 	; Restore registers

	jnz	short VALIDATE_EISAMEM_STC ; Jump if buffers are not equal
				; (Memory is not safe to use)

; Buffers are equal, one more block of extended memory is valid

	xchg	esi,edi 	; Switch source and destination
	add	esi,@EISA_CMP_INC ; Skip to next extended memory block

	cmp	esi,edx 	; More extended memory to check?
	jb	near ptr VALIDATE_EISAMEM_NEXT ; Jump if so

VALIDATE_EISAMEM_CLC:
	clc			; Indicate we can use EISA memory

	jmp	short VALIDATE_EISAMEM_EXIT ; Join common exit code

VALIDATE_EISAMEM_STC:
	stc			; Indicate we can't use EISA memory

VALIDATE_EISAMEM_EXIT:
	REGREST <es,edi,esi,edx,ecx,eax> ; Restore registers
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VALIDATE_EISAMEM endp		; End VALIDATE_EISAMEM procedure
	NPPROC	BIOS_BLOCK_MOVE -- BIOS_BLOCK_MOVE procedure
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Move memory via the BIOS_BLOCK_MOVE function call

On entry:
ECX	=	Number of bytes to move
ESI	=	Linear address of source
EDI	=	...		  destin

|

	REGSAVE <eax,ecx,esi,es> ; Save registers

; Set up source for move

	mov	eax,esi 	; Get linear address of source

	mov	MOVE_TAB.MDTE_DS.DESC_BASE01.EDD,eax
	rol	eax,8		; Rotate out the high-order byte
	mov	MOVE_TAB.MDTE_DS.DESC_BASE3,al ; Save as base byte #3
	ror	eax,8		; Rotate back
	mov	MOVE_TAB.MDTE_DS.DESC_SEGLM0,cx ; Save as data limit
	rol	ecx,16		; Swap high- and low-order words
	mov	MOVE_TAB.MDTE_DS.DESC_SEGLM1,cl ; Save size & flags
	ror	ecx,16		; Swap back
	mov	MOVE_TAB.MDTE_DS.DESC_ACCESS,CPL0_DATA

; Setup destination address for move

	mov	eax,edi 	; Get linear address of desitnation

	mov	MOVE_TAB.MDTE_ES.DESC_BASE01.EDD,eax
	rol	eax,8		; Rotate out the high-order byte
	mov	MOVE_TAB.MDTE_ES.DESC_BASE3,al ; Save as base byte #3
	ror	eax,8		; Rotate back
	mov	MOVE_TAB.MDTE_ES.DESC_SEGLM0,cx ; Save as data limit
	rol	ecx,16		; Swap high- and low-order words
	mov	MOVE_TAB.MDTE_ES.DESC_SEGLM1,cl ; Save size & flags
	ror	ecx,16		; Swap back
	mov	MOVE_TAB.MDTE_ES.DESC_ACCESS,CPL0_DATA

; Move the data

	mov	ax,seg PGROUP	; Address MOVE_TAB
	mov	es,ax		; ... via ES
	assume	es:nothing	; Tell the assembler about it

	lea	si,MOVE_TAB	; ES:SI ==> block move descriptor tables
	shr	cx,1		; Convert from bytes to words

	REGSAVE <fs,gs> 	; Save for a moment
	mov	ah,87h		; Function code to move extended memory
	int	15h		; Request BIOS service
	REGREST <gs,fs> 	; Restore
	jc	short BBM_STC	; Jump if error

	cmp	ah,00h		; Ensure it worked
	jne	short BBM_STC	; Jump if error

	clc			; Indicate success

	jmp	short BBM_EXIT	; Join common exit code

BBM_STC:
	stc			; Indicate failure

BBM_EXIT:
	REGREST <es,esi,ecx,eax> ; Restore registers
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
BIOS_BLOCK_MOVE endp			; End BIOS_BLOCK_MOVE procedure
	NPPROC	CHECK_CPUID -- Check On CPU Identifier
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're running on an 80386 or later processor.

On exit:

CF	=	0 if all went OK
	=	1 otherwise

N.B.:  Use only 8088 instructions!!!!

|
.8086

	REGSAVE <ax>		; Save register

	push	sp		; First test for earlier than a 286
	pop	ax

	cmp	ax,sp		; Same?
	jne	short CHECK_CPUID_ERR ; No, it's too early
.286

; Now distinguish 286 from 386

	pushf			; Save flags for a moment

	push	mask $IOPL	; Try to set IOPL bits in flag register
	popf

	pushf			; Get flags back into AX
	pop	ax

	popf			; Restore original flags

	test	ax,mask $IOPL	; Any bits set?
	jnz	short @F	; Yes, so it's a 386 or later
.8086
CHECK_CPUID_ERR:
	lea	ax,YGROUP:MSG_NOT386 ; Tell 'em the bad news
	push	ax		; Pass as argument
	call	YMSGOUT2	; Display YGROUP message

	stc			; Indicate we have a problem

	jmp	CHECK_CPUID_EXIT ; Join common exit code

DOT386 p
@@:

; Now distinguish a 386 from a 486

	call	IZIT486 	; Izit a 486?
	jnc	near ptr CHECK_CPUID_DONE ; Jump if not

	mov	CPUTYPE,04h	; Mark as a 486

; Assume for now that this machine supports WBINVD.  If it's a Gateway
; or NOGATE was specified, we'll avoid use of WBINVD.
	or	CPUFET_FLAG,@CPUFET_INVD ; Mark as supporting INVD/WBINVD

	or	FLG_GET_TRn,@BIT5 or @BIT4 or @BIT3 ; Mark as TR3-5 valid
	or	FLG_SET_TRn,@BIT5 or @BIT4 or @BIT3 ; ...

; Now see if the CPU supports the CPUID instruction

	call	IZIT_CPUID	; Duzit support the CPUID instruction?
	jnc	near ptr CHECK_CPUID_DONE ; Jump if not

	REGSAVE <eax,ebx,ecx,edx> ; Save for a moment

	mov	eax,1		; Function code to retrieve feature bits
	CPUID			; Return with EAX = stepping info
				;	      EBX, ECX reserved
				;	      EDX = feature bits

	and	edx,not @CPUFET_LOCAL ; Zero local CPU_FLAG flags

; Check for steppings which identify themselves as supporting VME but
; don't.  These include the Pentium B0 step, and the A1 stepping of
; 486 S series parts.
	mov	ebx,eax 	; Copy stepping info
	and	ebx,@CPUSIG_FAM or @CPUSIG_MOD or @CPUSIG_REV ; Isolate family,
				; model, and stepping in BX

	cmp	bx,0414h	; Izit S series 486DX, A1 step?
	je	short @F	; Jump if so

	cmp	bx,0424h	; Izit S series 486SX, A1 step?
	je	short @F	; Jump if so

	cmp	bx,0434h	; Izit S series 486DX-2, A1 step?
	je	short @F	; Jump if so

; If this is a B0-step Pentium CPU, it doesn't implement VME correctly,
; so we don't enable the feature.

	cmp	bx,0510h	; Izit a 486?
	jb	short CHECK_CPUID_VMEOK ; Jump if so

	cmp	bx,0512h	; Izit revision #2 or earlier?
	ja	short CHECK_CPUID_VMEOK ; Jump if not
@@:
	and	edx,not @CPUFET_VME ; Don't enable Virtual Mode Extensions
CHECK_CPUID_VMEOK:
	or	CPUFET_FLAG,edx ; Include in our list

	push	eax		; Save for a moment

	and	eax,mask $CPUSIG_REV ; Isolate the revision field
	shr	eax,$CPUSIG_REV ; Shift to low-order
	mov	CPUREV,al	; Save for later use

	pop	eax		; Restore

	and	eax,mask $CPUSIG_FAM ; Isolate the family field
	shr	eax,$CPUSIG_FAM ; Shift to low-order
	mov	CPUTYPE,al	; Save for later use

	cmp	al,05h		; Izit P5 or later?
	jb	short CHECK_CPUID_XP5 ; Jump if not

	or	FLG_GET_CRn,@BIT4 ; Mark as CR4 valid
	or	FLG_SET_CRn,@BIT4 ; ...

	test	CPUFET_FLAG,@CPUFET_IOBRK ; Are debugging extensions present?
	jz	short @F	; Jump if not

	and	FLG_GET_DRn,not (@BIT5 or @BIT4) ; Disable DR4-5
	and	FLG_SET_DRn,not (@BIT5 or @BIT4) ; ...
@@:
CHECK_CPUID_XP5:
	REGREST <edx,ecx,ebx,eax> ; Restore
CHECK_CPUID_DONE:
	clc			; Assume OK
CHECK_CPUID_EXIT:
	REGREST <ax>		; Restore

	ret			; Return to caller
DOT386 p
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPUID endp		; End CHECK_CPUID procedure
	NPPROC	IZIT486 -- Determine Presence of 486
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The test for 386 vs. 486 or later is done by attempting to set the
Alignment Check bit in the high-order word of the extended flag dword.
If that's successful, it's a 486 or later; otherwise, it's a 386.

On exit:

CF	=	0 if it's a 386
	=	1 if it's a 486

|

	push	bp		; Save to align stack
	mov	bp,sp		; Save original stack pointer

	and	esp,(0FFFFh and (not (4-1))) ; Align on a dword boundary in
				; case we're in V86 mode and $AM is set in CR0
				; Also clear upper word of ESP

	push	eax		; Save to use as scratch
	pushfd			; Save original flags

	pushfd			; Save original flags
	or	[esp].EHI,mask $AC ; Set Alignment Check bit
	popfd			; Put into effect

	pushfd			; Put onto the stack
	pop	eax		; Copy to register

	test	eax,(mask $AC) shl 16 ; Izit still set?
	jnz	short @F	; Yes, so it's a 486

	popfd			; Restore original flags

	clc			; Indicate it's a 386

	jmp	short IZIT486_EXIT ; Join common code

@@:
	popfd			; Restore original flags

	stc			; Indicate it's a 486
IZIT486_EXIT:
	pop	eax		; Restore

	mov	sp,bp		; Restore original pointer
	pop	bp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT486 endp			; End IZIT486 procedure
	NPPROC	IZIT_CPUID -- Determine Support of CPUID Instruction
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The test for the CPUID instruction is done by attempting to set the ID
bit in the high-order word of the extended flag dword.	If that's
successful, the CPUID instruction is supported; otherwise, it's not.

On exit:

CF	=	1 if it's supported
	=	0 otherwise

|

	push	bp		; Save to address the stack
	clc			; Assume it's not supported
	pushfd			; Save original flags
	pushfd			; Save temporary flags

IZIT_CPUID_STR struc

IZIT_CPUID_TMPEFL dd ?		; Temporary EFL
IZIT_CPUID_RETEFL dd ?		; Return EFL
	dw	?		; Caller's BP

IZIT_CPUID_STR ends

	mov	bp,sp		; Address the stack
	or	[bp].IZIT_CPUID_TMPEFL,mask $ID ; Set ID bit
	popfd			; Put into effect

	pushfd			; Put back onto the stack to test

	test	[bp].IZIT_CPUID_TMPEFL,mask $ID ; Izit still set?
	jz	short @F	; No, so it's not supported

	or	[bp].IZIT_CPUID_RETEFL,mask $CF ; Indicate it's supported
@@:
	popfd			; Restore temporary flags
	popfd			; Restore original flags
	pop	bp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_CPUID endp 		; End IZIT_CPUID procedure
if @OEM_XMS
	NPPROC	CHECK_XMS -- Check On Previous XMS Handler
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if there is a previous XMS handler installed.
If so, save its address for later patching, and
capture the state of the HMA and A20 line.

Note that this routine runs *BEFORE* we've determined the
CPU type so it *MUST* use 8088 instructions only.

Note we *MUST* use NRD_FLAG.ELO in case we're not on a 386

|

	REGSAVE <ax,bx,dx,es>	; Save registers

; See if previous XMS handler already installed

	mov	ax,4300h	; Function code to check on presence
	int	2Fh		; Request redirector service

	cmp	al,80h		; Izit installed?
	jne	short CHECK_XMS_EXIT ; Jump if not present

	mov	ax,4310h	; Function code to obtain address of handler
	int	2Fh		; Request redirector service
	assume	es:nothing	; Tell the assembler about it

	mov	OLDXMS_VEC.VOFF,bx ; Save for later use
	mov	OLDXMS_VEC.VSEG,es

; Capture the state of the HMA

	mov	dx,-1		; Request all of it
	mov	ah,@XMS_REQHMA	; Function code to request the HMA
	call	OLDXMS_VEC	; Request XMS service

	cmp	ax,1		; Did we get it?
	jne	short @F	; Jump if not

	mov	ah,@XMS_RELHMA	; Function code to release the HMA
	call	OLDXMS_VEC	; Request XMS service

	mov	bl,0		; Mark as no error
@@:
	cmp	bl,91h		; Izit already in use?
	jne	short @F	; Jump if not

	or	NRD_FLAG.ELO,@NRD_HMA ; Mark as initially in use
	mov	HMASIZE,64	; Grab the entire HMA
@@:
	cmp	bl,90h		; Does it not exist?
	je	short @F	; Jump if that's true

	cmp	PRVSIZE,64	; Use the larger of the two
	jae	short @F	; Jump if not smaller than 64KB

	mov	PRVSIZE,64	; Mark as minimum area
@@:

; Capture the state of the A20 line

	mov	ah,@XMS_QRYA20	; Function code to query A20 status
	call	OLDXMS_VEC	; Request XMS service

	cmp	ax,1		; Izit enabled?
	jne	short @F	; Jump if not

	or	NRD_FLAG.ELO,@NRD_A20 ; Mark as initially ON (enabled)
@@:
	or	XMS_FLAG,mask $XMS_OLD ; Mark as XMS handler previously installed
CHECK_XMS_EXIT:
	REGREST <es,dx,bx,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XMS endp			; End CHECK_XMS procedure
endif				; IF @OEM_XMS
	NPPROC	CHECK_VM86 -- Check On Virtual 8086 Mode
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if there's another VM86 monitor running.

On exit:

CF	=	0 if all went well
	=	1 otherwise.

|

	REGSAVE <ax>		; Save register

	smsw	ax		; Get machine status word

	test	ax,mask $PE	; Check the Protect Enable bit
	jz	short CHECK_VM86_EXIT ; No other one running (note CF=0)

	push	offset YGROUP:MSG_NOTVM ; Tell 'em the bad news
	call	YMSGOUT2	; Display YGROUP message

	stc			; Indicate we have a problem
CHECK_VM86_EXIT:
	REGREST <ax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VM86 endp 		; End CHECK_VM86 procedure
	NPPROC	INTR_GET -- Get and Save Old Interrupt Handlers
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	REGSAVE <eax,bx,dx,si,di> ; Save registers

; Save the current values of NOLDINTS interrupt vectors

	push	ds		; Save for a moment

	push	seg INTVEC	; Address segment zero
	pop	ds		; Address it
	assume	ds:INTVEC	; Tell the assembler about it

	lea	si,INT00_VEC[00h*type INT00_VEC] ; DS:SI ==> int vectors
	lea	di,OLDINT_VECS	; ES:DI ==> local copies of int vectors

; Set CX to the number of dwords to move

	mov	cx,NOLDINTS	; # interrupt vectors to save
	cld			; String ops forwardly
S16 rep movsd			; Save original interrupt vectors

	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler about it

if @OEM_WTK
	lea	si,OLDINT_VECS[11h*type INT00_VEC] ; DS:SI ==> old INT 11h
	lea	di,OLDINT11_VEC
S16	movsd			; Copy to resident device driver memory
endif				; IF @OEM_WTK

	lea	si,OLDINT_VECS[15h*type INT00_VEC] ; DS:SI ==> old INT 15h
	lea	di,OLDINT15_VEC
S16	movsd			; Copy to resident device driver memory

	lea	si,OLDINT_VECS[19h*type INT00_VEC] ; DS:SI ==> old INT 19h
	lea	di,OLDINT19_VEC
S16	movsd			; Copy to resident device driver memory

if @OEM_HILOAD
	lea	si,OLDINT_VECS[20h*type INT00_VEC] ; DS:SI ==> old INT 20h
	lea	di,OLDINT20_VEC
S16	movsd			; Copy to resident device driver memory

	lea	si,OLDINT_VECS[21h*type INT00_VEC] ; DS:SI ==> old INT 21h
	lea	di,OLDINT21_VEC
S16	movsd			; Copy to resident device driver memory

	lea	si,OLDINT_VECS[27h*type INT00_VEC] ; DS:SI ==> old INT 27h
	lea	di,OLDINT27_VEC
S16	movsd			; Copy to resident device driver memory
endif				; IF @OEM_HILOAD

if @OEM_XMS
	lea	si,OLDINT_VECS[2Fh*type INT00_VEC] ; DS:SI ==> old INT 2Fh
	lea	di,OLDINT2F_VEC
S16	movsd			; Copy to resident device driver memory
endif				; IF @OEM_XMS
	lea	si,OLDINT_VECS[40h*type INT00_VEC] ; DS:SI ==> old INT 40h
	lea	di,OLDINT40_VEC
S16	movsd			; Copy to resident device driver memory

if @OEM_EMS
	lea	si,OLDINT_VECS[67h*type INT00_VEC] ; DS:SI ==> old INT 67h
	lea	di,OLDINT67_VEC
S16	movsd			; Copy to resident device driver memory

; In case it's zero, point OLDINT67_VEC to an IRET

	cmp	OLDINT67_VEC,0	; Izit uninitialized?
	jne	short @F	; Jump if not

	mov	OLDINT67_VEC.VOFF,offset PGROUP:RESINT67_IRET
	mov	OLDINT67_VEC.VSEG,seg PGROUP
@@:
endif				; IF @OEM_EMS

	push	ds		; Save for a moment

	mov	ds,SBIOSDATA	; Address the BIOS data area
	assume	ds:BIOSDATA	; Tell the assembler about it

	mov	eax,SAVE_PTR	; Get current SAVE_PTR
	mov	LCL_SAVE_PTR,eax ; Save for later use

	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler about it

	REGREST <di,si,dx,bx,eax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTR_GET endp			; End INTR_GET procedure
	NPPROC	CALC_RESIDENT -- See If Already Resident
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we are already resident, an OUT to PORT67 sets values in our segment.

Also check to see if there's another INT 67h handler resident.

Handle double installation and reboot on INT 19h.

On exit:

CF	=	0 if all went OK
	=	1 otherwise

|

	REGSAVE <ax,bx,cx,dx,si,di,bp,es> ; Save registers

if @OEM_EMS
	lea	dx,DEVDRV2.DD_NAME ; DS:DX ==> device name
	xor	al,al		; A convenient zero
	xchg	al,DEVDRV2.DD_NAME[8] ; Ensure it's an ASCIIZ string
	call	CHECK_DEVICE	; Check on that device driver
	xchg	al,DEVDRV2.DD_NAME[8] ; Restore
else
	lea	dx,DEVDRV.DD_NAME ; DS:DX ==> device name
	xor	al,al		; A convenient zero
	xchg	al,DEVDRV.DD_NAME[8] ; Ensure it's an ASCIIZ string
	call	CHECK_DEVICE	; Check on that device driver
	xchg	al,DEVDRV.DD_NAME[8] ; Restore
endif				; IF @OEM_EMS
	jnc	short CALC_RESIDENT_ERR ; It's installed, so that's an error

	smsw	ax		; Get machine status word

	test	ax,mask $PE	; In protected mode?
	jz	short CALC_RESIDENT_COM ; No, so we're not active

; Get the message statistics

	lea	di,MSG_STAT	; ES:DI ==> save area for message text
	mov	cx,MSG_STATLEN	; CX = maximum length
	mov	bp,sp		; Save stack offset
	EMMOUT	@EMM2_GETTEXT	; Get message text
	mov	sp,bp		; In case we're not installed

	and	ah,ah		; Check return code
	jnz	short CALC_RESIDENT_COM ; Good guess

; Get the MCS table

	lea	di,MCSTAB	; ES:DI ==> save area for memory chain structure
	mov	bp,sp		; Save stack offset
	EMMOUT	@EMM2_GETMCS	; Get memory chain structure
	mov	sp,bp		; In case we're not installed

	and	ah,ah		; Check return code
	jnz	short CALC_RESIDENT_COM ; Good guess

; Get the local information

	lea	di,INFO 	; ES:DI ==> save area for INFO_STR
	mov	bp,sp		; Save stack offset
	EMMOUT	@EMM2_GETINFO	; Get information structure
	mov	sp,bp		; In case of error

	and	ah,ah		; Check return code
	jnz	short CALC_RESIDENT_COM ; Good guess

; Check the segment information
; This catches duplicate installation where the first one is ON

	cmp	DEVICE_CS,seg PGROUP ; Same as that of resident driver?
	je	short CALC_RESIDENT_RES ; Yes, so we're installed
CALC_RESIDENT_ERR:
	push	offset YGROUP:MSG_NOTDRV ; Give 'em the bad news
	call	YMSGOUT2	; Display YGROUP message

	stc			; Indicate we have a problem

	jmp	short CALC_RESIDENT_EXIT ; Join common exit code

; We must have come in on an INT 19h

CALC_RESIDENT_RES:
	or	NRD_FLAG,@NRD_RES ; Mark as resident and ON or AUTO active
CALC_RESIDENT_COM:

if @OEM_EMS and @OEM_HIFILL

; See if there is another INT 67h handler already resident

	push	es		; Save for a moment
	mov	al,'E'          ; First character if ON or another driver
	call	CHECK_EMSDRV	; Check on EMS driver presence
	assume	es:nothing	; Tell the assembler about it
	pop	es		; Restore
	assume	es:PGROUP	; Tell the assembler about it
	jnc	short CALC_RESIDENT_CLC ; Jump if not already installed

	or	LCL_FLAG,@LCL_DRV ; Mark as another EMS driver present

; Get the EMS frame of the preceding driver

	EMMCALL @EMM_GETPGFR	; Return in BX

	or	ah,ah		; Check for error
	jnz	short CALC_RESIDENT_CLC ; ????

; Mark that memory as RAM which we shouldn't use as high DOS memory

	mov	di,bx		; Copy to STOSB register
	shr	di,9-4		; Convert from paras to 512-byte
	lea	di,MEM_MAP[di]	; Point to spot within MEM_MAP
	mov	cx,64*(1024/512) ; CX = # entries in MEM_MAP for 64KB

	mov	al,@XLAT_OTH	; Other RAM index
    rep stosb			; Save in memory map

	or	CMD_FLAG,@CMD_EMS ; Mark as EMS=0
	mov	EMMSIZE,0	; ...
	mov	NPHYS16F,0	; Mark as no physical 16KB pages in EMS frame
	mov	NPHYS16S,0	; ...					system
CALC_RESIDENT_CLC:
endif				; IF @OEM_EMS and @OEM_HIFILL
	clc			; Indicate all went OK
CALC_RESIDENT_EXIT:
	REGREST <es,bp,di,si,dx,cx,bx,ax> ; Restore
	assume	es:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_RESIDENT endp		; End CALC_RESIDENT procedure
if @OEM_EMS and @OEM_HIFILL
	NPPROC	CHECK_EMSDRV -- Check On Preceding EMS Driver
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if there another EMS Driver installed (possibly ourselves)
Use the modified Get Interrupt Vector method

On entry:

AL	=	character to use in DD_NAME[0]

On exit:

CF	=	1 if already installed
	=	0 otherwise

ES	=	segment of preceding driver

|

	REGSAVE <cx,si,di>	; Save registers

	push	seg INTVEC	; Address segment zero
	pop	es
	assume	es:INTVEC	; Tell the assembler about it

; Get segment of INT 67h handler (if any)

	mov	es,INT00_VEC.VSEG[67h*type INT00_VEC]
	assume	es:nothing	; Tell the assembler about it

	lea	si,DEVDRV.DD_NAME ; DS:SI ==> Our device driver name
	mov	di,si		; Should be same in other driver's segment
	xchg	al,DEVDRV.DD_NAME[0] ; Swap with incoming character
	mov	cx,8		; Length of device driver name
   repe cmpsb			; Compare 'em
	xchg	al,DEVDRV.DD_NAME[0] ; Restore orginal character
	je	short CHECK_EMSDRV_EXIT ; Jump if it's a match (Note CF=0)

	stc			; Set flags to complement below
CHECK_EMSDRV_EXIT:
	cmc			; CF=1 if already installed, CF=0 if not

	REGREST <di,si,cx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EMSDRV endp		; End CHECK_EMSDRV procedure
endif				; IF @OEM_EMS and @OEM_HIFILL
	NPPROC	INTR_SET -- Install Interrupt Handlers
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Setup interrupt vectors.

This routine is called once before loading ourselves
into high DOS memory, and once after.  Each time, DS
points to the segment of the interrupt handler.

Note that because only the resident portion of our
code has been moved into high DOS, we must address
variables outside that area via SS which continues
to point to low DOS.

|

SETINT	macro	NN,NAM

ifnb <NAM>
	lea	ax,NAM&INT&NN	; Get offset of interrupt handler
else
	lea	ax,RESINT&NN	; Get offset of interrupt handler
endif				; IFNB
	mov	INT00_VEC[NN&h*(type INT00_VEC)],eax

	endm			; SETINT

	REGSAVE <eax,bx,dx,es>	; Save registers

	push	seg INTVEC	; Get segment of interrupt vectors
	pop	es		; Address it
	assume	es:INTVEC	; Tell the assembler about it

	mov	ax,ds		; Copy common interrupt handler segment
	shl	eax,16		; Shift to high-order word

if @OEM_WTK
	assume	ds:nothing	; Force use of SS override
	test	NRD_FLAG,@NRD_WTK ; Izit present?
	assume	ds:PGROUP	; Back to the truth
	jz	short @F	; Not this time

	SETINT	11		; Install our own handler
@@:
endif				; IF @OEM_WTK

	SETINT	15		; Install our own handler
	SETINT	19		; Install our own handler
if @OEM_HILOAD
	test	CMD_FLAG,@CMD_XHI ; Any high memory to fill in?
	jnz	short INTR_SET_XHI ; Not this time
	SETINT	20		; Install our own handler
	SETINT	21		; Install our own handler
	SETINT	27		; Install our own handler
INTR_SET_XHI:
endif				; IF @OEM_HILOAD

; Set new XMS handler segment in both high and low DOS memory copies

	assume	ds:nothing	; Force use of SS override
;;;;;;; mov	PRESINT_XMS.VOFF,offset PGROUP:RESINT_XMS ; Save offset
	mov	PRESINT_XMS.VSEG,ds		       ; ... segment
	assume	ds:PGROUP	; Back to the truth
;;;;;;; mov	PRESINT_XMS.VOFF,offset PGROUP:RESINT_XMS ; Save offset
	mov	PRESINT_XMS.VSEG,ds		       ; ... segment

if @OEM_XMS or @OEM_WIN3
	SETINT	2F		; Install our own handler
; If a previous XMS handler existed, bung a far jump to our handler
; into its first five bytes.  This is necessary if DOS has saved the
; address of the previous handler already and is using it for enabling
; A20.
	test	XMS_FLAG,mask $XMS_OLD ; Was a previous handler installed?
	jz	short @F	; Jump if not

	push	es		; Save

	assume	ds:nothing	; Force use of SS override
	les	bx,OLDXMS_VEC	; Get address of previous handler
	assume	es:nothing	; Tell the assembler
	assume	ds:PGROUP	; Back to the truth

	mov	es:[bx].LO,@OPCOD_JMPF ; Far jump immediate
	mov	es:[bx+1].VOFF,offset PGROUP:RESINT_XMS ; Offset of our handler
	mov	es:[bx+1].VSEG,ds ; Segment

	pop	es		; Restore
	assume	es:INTVEC	; Tell the assembler about it

@@:
INTR_SET_WIN3COM:
endif				; IF @OEM_XMS or @OEM_WIN3
	SETINT	40		; Install our own handler

if @OEM_EMS
	assume	ds:nothing	; Force use of SS override
	mov	CURINT67_VEC.VOFF,offset PGROUP:RESINT67
	mov	CURINT67_VEC.VSEG,ds
	assume	ds:PGROUP	; Back to the truth
;;;;;;; mov	CURINT67_VEC.VOFF,offset PGROUP:RESINT67
	mov	CURINT67_VEC.VSEG,ds

	test	LCL_FLAG,@LCL_DRV ; Another EMS driver present?
	jnz	short @F	; Jump if so

	SETINT	67		; Install our own handler
@@:
	cmp	EMMSIZE,0	; Using any expanded memory?
	je	short INTR_SET_XEMS ; No, don't install INT 67h

	or	GLB_FLAG,@GLB_I67 ; Set flag to show we hooked INT 67

	jmp	short INTR_SET_XMS ; Join common code

; No expanded memory -- change device driver name
; Also, the ending address should omit INT 67h handler

INTR_SET_XEMS:
	mov	DEVDRV.DD_NAME[0],'Q'
	and	GLB_FLAG,not @GLB_I67 ; Mark as not intercepted
endif				; IF @OEM_EMS
INTR_SET_XMS:
if @OEM_XMS
	assume	ds:nothing	; Force use of SS override
	mov	NEWXMS_VEC.VSEG,ds ; Save as new segment
	assume	ds:PGROUP	; Back to the truth
endif				; IF @OEM_XMS

; If we call LOADHI, XBIOS_DST is already calculated for low DOS

	REGREST <es,dx,bx,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTR_SET endp			; End INTR_SET procedure
	NPPROC	SETMEM -- Set Low Memory Size
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Add/subtract in/from LOWSIZE to low memory size value.

|

	REGSAVE <ax,es> 	; Save registers

	test	CMD_FLAG,@CMD_XLO ; Are adding low DOS memory?
	jnz	short SETMEM_EXIT ; No

	mov	es,SBIOSDATA	; Address the BIOS data area
	assume	es:BIOSDATA	; Tell the assembler about it

; Because of low memory EMS page frames and relocated XBIOS,
; we just add in LOWSIZE.

;;;;;;; mov	ax,LOWOFF.ELO	; Get previous top of memory
;;;;;;; add	ax,LOWSIZE	; Plus the amount we're adding/subtracting
;;;;;;;
;;;;;;; mov	MEMORY_SIZE,ax	; Save in BIOS data area
	mov	ax,LOWSIZE	; Get amount we're adding /subtracting
	add	MEMORY_SIZE,ax	; Include in BIOS data area
SETMEM_EXIT:
	REGREST <es,ax> 	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETMEM	endp			; End SETMEM procedure
if @OEM_HIFILL
	NPPROC	LOADHISUB -- Allocate a subsegment
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate subsegment in region specified.  If region is 0, add size to
ENDADDR and calculate segment based on PGROUP.

On entry:
AL		 Subsegment identifier token (see MAC.INC)
BX		 Number of paras to allocate (must be < 64K)
XGROUP:SI ==>	 REG_STR (see QMAX_NRD.INC)

On exit:
AX		 Segment allocated in

|

	REGSAVE <bx,cx,dx,di,es> ; Save

	mov	dl,al		; Save token type
	mov	cx,bx		; CX=number of paras to allocate
	mov	bx,XGROUP:[si].RREG ; Get region to use
	mov	ax,XGROUP:[si].RSIZE ; Get size to compare with

	or	bx,bx		; Izit low?
	jz	short LHS_LOW	; Jump if so

	cmp	ax,-1		; Was a size specified?
	je	short @F	; Jump if not

	cmp	ax,cx		; Does actual size match the one specified?
	jne	short LHS_FORCELOW ; Jump if not

@@:
	REGSAVE <bx,cx,si>	; Save

	mov	di,bx		; High DOS region (1-based)
	mov	si,@MAC_SUBSEG_MAX ; Owner to set
				; CX = number of paragraphs to allocate
	mov	bx,@STRA_NOLSEG or @STRA_HIONLY ; Strategy flags
	EMMOUT	@EMM2_MALLOC	; Call MAC_ALLOC; return segment in BX
	or	ah,ah		; Did the allocate succeed?
	mov	ax,bx		; Save segment returned if call succeeded

	REGREST <si,cx,bx>	; Restore
	jnz	short LHS_FORCELOW ; Jump if it failed

	dec	ax		; Back off to MAC entry
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler

	mov	es:[0].MAC_DRV,dl ; Save token type in drive field for UTIL/m
	inc	ax		; Skip MAC entry
	mov	es,ax		; Address return segment
	assume	es:nothing	; Tell the assembler

	jmp	short LHS_COM	; Join common code

LHS_FORCELOW:
; Forced low because of different size or insufficient memory.	Display
; error message and continue.

	push	XGROUP:[si].RMSG ; Address of error message
	call	YMSGOUT2	; Display YGROUP message

	sub	bx,bx		; Force region 0
LHS_LOW:
; Add size into ENDADDR.
; BX = region
; CX = number of paras
; DL = subsegment type
	mov	ax,ENDADDR	; Get size of low DOS part /16
	shr	ax,4-0		; Convert to paras
	add	ax,seg PGROUP	; Get segment to return
	mov	es,ax		; Save in ES
	assume	es:nothing	; Tell the assembler

	shl	cx,4-0		; Convert paras to bytes
	add	ENDADDR,cx	; Allocate in low DOS part of MAX
	shr	cx,4-0		; Convert bytes to paras
;;;;;;;  call	 ROUND_END	; Round up ending addresses to para boundaries

LHS_COM:
; Add to subsegment list in extended memory
	mov	bh,bl		; BH=region
	mov	bl,dl		; BL=subsegment type
				; CX=numparas
	mov	dx,@SFO_MAX	; DX=flags- this subsegment owned by MAX
	EMMOUT	@EMM2_HARPOINFO,@HARPO_SET_SUBSEG ; Add to subsegment list
;;;;;;;  or	 ah,ah		; Did the call succeed?
;;;;;;;  jnz	 ???		; Ignore error

LHS_EXIT:
	mov	ax,es		; Segment to return
;;;;;;;  cmp	 POVR_MAC,ax	; Set CF if in high DOS

	REGREST <es,di,dx,cx,bx> ; Restore
	assume	es:nothing	; Tell the assembler

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOADHISUB endp			; End LOADHISUB procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	NPPROC	LOADHI -- Attempt to Load into High DOS Memory
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy LSEG values to ending address, and
attempt to load ourselves into high DOS memory.

The parts which can go high or low are as follows:

386MAX resident including the initial LSEG.
	Specified by PRGREG=.  If no fit, forced low.
	If unspecified (default), find the first region that
	fits.

HPDA (short or long).
XBIOS data area.
STACKS data area.
	Specified by HPDAREG=, XBDAREG=, and STACKREG=.  Default
	is 0 (leave 'em low).

Note that there are two separate issues with respect to loading
different components high or low.  One is putting them in place.
This is described above.  The other issue is the resident size
for 386MAX.  Previously, this would include the size of components
(XBDA and STACKS) that were forced low to get the resident 386MAX
high.

Now we'll always tell the truth about the resident size of 386MAX.
The other components will be reported on as subsegments in the
optimization algorithm.

|

	pushad			; Save all EGP registers
	REGSAVE <es>		; Save segment register

	push	seg XGROUP	; Prepare to address XGROUP
	pop	es		; Avoid CS: overrides
	assume	es:XGROUP	; Tell the assembler

; If it's not an Inboard/AT, we can discard some code in high DOS.

	test	SYS_FLAG,@SYS_INBRDAT ; Izit an Inboard/AT?
	jnz	short @F	; Jump if so

	lea	dx,PGROUP:ZLOCODE_XINB[16-1] ; Discard Inboard code
	and	dx,not (16-1)	; Round off to paragraph boundary
	mov	PZLOCODE,dx	; Save as ending address
@@:
; To maintain backward compatibility with XBIOSHI and Stacks /h, we
; use the same region as PRGREG if no explicit region was specified.
	mov	eax,NRD_FLAG	; Get non-resident flags
	mov	bx,PRGREG	; Default for XBIOSHI and STACKS /h
	test	eax,@NRD_XBRSPEC ; Was a region specified for XBDA?
	jnz	short @F	; Jump if so

	test	eax,@NRD_XBIOSHI ; Was XBIOSHI present?
	jz	short @F	; Jump if not

	mov	XBDAR.RREG,bx	; Same as PRGREG
@@:
	test	eax,@NRD_SRSPEC ; Was a region specified for STACKS?
	jnz	short @F	; Jump if so

	test	eax,@NRD_STACKHI ; Was it STACKS /h?
	jz	short @F	; Jump if not

	mov	STACKR.RREG,bx	; Same as PRGREG
@@:
LOADHI_CALCADDR:
	mov	ENDADDR,offset PGROUP:ZCODE_XLHI ; Default low DOS end
	mov	HI_ENDADDR,0	; Default high DOS end
	mov	ax,PZLOCODE	; Get potential high DOS end
	mov	XHI_ENDADDR,ax	; Save it

	test	CM3_FLAG,@CM3_XLHI or @CM3_PREG0 ; Is NOLOADHI specified?
	jnz	short LOADHI_CALCXHI ; Yes, HI_ENDADDR is OK

	test	CMD_FLAG,@CMD_XHI ; Is NOHIGH specified?
	jnz	short LOADHI_CALCXHI ; Yes, HI_ENDADDR is OK

	mov	ENDADDR,offset PGROUP:LHI_END ; Default low DOS end with NOWIN3
if @OEM_WIN3
	test	CM3_FLAG,@CM3_NOWIN3 ; Disabling support for Windows 3?
	jnz	short @F	; Jump if so

	mov	ENDADDR,offset PGROUP:WIN3_END ; Include Windows 3 support
@@:
endif				; IF @OEM_WIN3

	mov	ax,PZLOCODE	; Get high DOS ending address
	mov	HI_ENDADDR,ax	; High DOS ending address
LOADHI_CALCXHI:
	call	ROUND_END	; Round up ending addresses to para boundaries

; Now we've got ENDADDR and HI_ENDADDR set up.  HI_ENDADDR won't change,
; but any subsegments that don't fit (or are unspecified) will get added
; to ENDADDR after the LSEG.  They won't have separate MAC entries if
; they're added to the low DOS portion of MAX.  Note that the subsegment
; info structure doesn't count the MAC paragraph in the subsegment size.

; Allocate high DOS portion of MAX (if any).  If there's not enough
; room (this is not possible if there's high DOS) we'll add the difference
; back in to ENDADDR and force MAX low.
	mov	cx,HI_ENDADDR	; Get ending address in high DOS (para-aligned)
	jcxz	short LOADHI_NOLOADHI ; Jump if no high DOS portion

	mov	bx,@STRA_NOLSEG or @STRA_HIONLY ; Flags for strategy
	add	cx,(size LSEG_STR)+16-1 ; Add LSEG
	shr	cx,4-0		; Get paras to allocate
	mov	si,@MAC_DRV	; It's a device driver
	mov	di,PRGREG	; -1 if not specified or 1-based region #
	EMMOUT	@EMM2_MALLOC	; Return AH=0 if allocate succeeded
				; BX:0 ==> segment
	or	ah,ah		; Did we succeed?
	jnz	short LOADHI_FORCELOW ; Jump if not

; BX is the high DOS segment.
	mov	PGRSEG,bx	; Save high DOS segment
	jmp	short LOADHI_NOLOADHI ; Join common code

LOADHI_FORCELOW:
	and	CM3_FLAG,not @CM3_PREG ; Specified region is invalid
	or	CM3_FLAG,@CM3_PREG0 ; Act as if PRGREG=0 were specified
	jmp	short LOADHI_CALCADDR ; Recalculate addresses

LOADHI_NOLOADHI:
; Add the LSEG to the appropriate [HI_]ENDADDR
	sub	bx,bx		; Adjust ENDADDR and create LSEG_OFF
	call	CREA_LSEG	; Create LSEG entry at (HI_)ENDADDR, advancing
				; it even if no high DOS memory

; Check HPDAREG, STACKREG, and XBDAREG.  Try to allocate high DOS space.
; If we fail, force 'em low and add their sizes to ENDADDR.
if @OEM_DPMI
	lea	bx,PGROUP:OVR_HPDA[16-1] ; Get offset of OVR_HPDA
	shr	bx,4-0		; Convert to paras
	add	TMPHPDASEG,bx	; Save segment of temporary HPDA

	mov	bx,@OVR_HPDALENP ; Size of short HPDA in paras
;;;;;;;  lea	 bx,PGROUP:ZLODPMI[16-1] ; Address end of OVR_HPDA
;;;;;;;  sub	 bx,PZLOCODE	; Get length
;;;;;;;  shr	 bx,4-0 	; Convert bytes to paras

	test	LCL_FLAG,@LCL_DPMI ; Load module DPMI services requested?
	jz	short @F	; Jump if not

	mov	bx,HPDA_NPAR	; Get # paras in the HPDA
@@:
	lea	si,XGROUP:HPDAR ; Address structure
	mov	al,@TOKEN_HPDAREG ; Subsegment token to use
	call	LOADHISUB	; Return segment in AX
	mov	HPDASEG,ax	; Save for later
endif				; IF @OEM_DPMI

; Include the DOS stacks code/data

	test	I15_FLAG,@I15_DSTK ; Izit present?
	jz	short LOADHI_CALCXDSTK ; Jump if not

	mov	bx,DSTK_NPAR	; Get # paras in DOS stacks including code/data
	lea	si,XGROUP:STACKR ; Address structure
	mov	al,@TOKEN_STACKREG ; Subsegment identifier
	call	LOADHISUB	; Return segment in AX
	mov	PDSTKCOM.VSEG,ax ; Save complete destination segment

LOADHI_CALCXDSTK:
	test	I15_FLAG,@I15_XBREL ; Izit to be relocated?
	jz	short LOADHI_CALCDONE ; Jump if not

	mov	bx,XBIOS_SIZ	; Get size of XBDA in bytes (/1024)
	shr	bx,4-0		; Convert to paras
	lea	si,XGROUP:XBDAR ; Address structure
	mov	al,@TOKEN_XBDAREG ; Subsegment identifier
	call	LOADHISUB	; Return segment in AX
	mov	XBIOS_DST.VSEG,ax ; Save complete destination segment

LOADHI_CALCDONE:

; Save a copy of ENDADDR in XGROUP, as we'll need it after PGROUP in
; low memory has been clobbered.
	mov	ax,ENDADDR	; Get final ending address in low memory
	mov	XENDADDR,ax	; Update copy in XGROUP

; Note that if we're not loading anything high, the HPDA will always
; overlay OVR_HPDA so it's not necessary to tell MAX in extended memory
; about the HPDA segment.
	test	CMD_FLAG,@CMD_XHI ; Is there any high DOS memory?
	jnz	near ptr LOADHI_REG0 ; Not this time, just create LSEG

	test	CM3_FLAG,@CM3_XLHI or @CM3_PREG0 ; Izit NOLOADHI or PRGREG=0?
	jnz	near ptr LOADHI_REG0 ; Yes, just create LSEG

; Set the flag now so it's copied to high DOS memory

	or	LCL_FLAG,@LCL_LODHI ; Mark as in effect

	mov	es,PGRSEG	; Address segment in high DOS
	assume	es:nothing	; Tell the assembler

	xor	si,si		; DS:SI ==> start
	mov	di,si		; ES:DI ==> destination
	mov	cx,HI_ENDADDR	; Get ending offset (# bytes to move)
S16 rep movsb			; Move into high DOS memory

; Point interrupt vectors into high DOS memory

	push	ds		; Save for a moment

	push	seg XGROUP	; Get addressibility to XGROUP
	pop	ds		; ...
	assume	ds:XGROUP	; Tell the assembler about it

	mov	bx,es		; Get PGRSEG value
	mov	XPGRSEG,bx	; Save for later use
	mov	ds,bx		; Address it for INTR_SET
	assume	ds:PGROUP	; Tell the assembler about it

	call	INTR_SET	; Install our own interrupt handlers

if @OEM_WIN3
	mov	WIN3_STARTUP.SIS_INSTANCE_DATA_PTR.VSEG,bx ; Relocate ptr to
				; instance data in high DOS to high DOS
	mov	IIS_MAX.IIS_PTR.VSEG,bx ; Relocate segment of instance data
				; in high DOS to high DOS
endif				; IF @OEM_WIN3
	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler about it

if @OEM_WIN3
	mov	WIN3_STARTUP.SIS_INSTANCE_DATA_PTR.VSEG,bx ; Relocate ptr to
				; instance data in low DOS to high DOS
endif				; IF @OEM_WIN3

; Set new ending address

if @OEM_WIN3
	test	CM3_FLAG,@CM3_NOWIN3 ; Disabling support for Windows 3?
	jnz	short LOADHI_XWIN3 ; Jump if so

	mov	DEVDRV.DD_INTR,offset PGROUP:LHI_INTR3

	jmp	short LOADHI_WIN3COM ; Join common code

LOADHI_XWIN3:
endif				; IF @OEM_WIN3
	mov	DEVDRV.DD_INTR,offset PGROUP:LHI_INTR
LOADHI_WIN3COM:

; Set new strategy and interrupt routines

	mov	DEVDRV.DD_STRA,offset PGROUP:LHI_STRA

; Fill in segments for LHI_STRA and LHI_INTR

	mov	LHI_STRA_CS,bx
	mov	LHI_INTR_CS,bx
if @OEM_WIN3
	mov	LHI_INTR_CS3,bx ; Not needed if NOWIN3 in effect
endif				; IF @OEM_WIN3

; Tell protected mode code of new HIMEM_CS in BX and of short HPDA
if @OEM_DPMI
	mov	cx,TMPHPDASEG	; Get segment of HPDA stub in low DOS
endif				; IF @OEM_DPMI
	EMMOUT	@EMM2_HIMEM
	jmp	short LOADHI_REG1 ; Join common code

LOADHI_REG0:
	xor	bx,bx		; Mark as no owner in high DOS
LOADHI_REG1:
	push	bx		; Save
	mov	bx,1		; Copy LSEG data, but don't adjust (HI_)ENDADDR
	call	CREA_LSEG	; Create LSEG at LSEG_OFF
	pop	bx		; Restore

	call	FILL_LSEG	; Fill in LSEG entry

	mov	ax,HI_ENDADDR	; Get ending address
	or	ax,ax		; Izit valid?
	jnz	short @F	; Jump if so

	mov	ax,ENDADDR	; Get ending address
@@:
	mov	es,PGRSEG	; Address high DOS
	assume	es:PGROUP	; Tell the assembler

	add	ax,16-1 	; Round up to para boundary
	shr	ax,4-0		; Convert from bytes to paras
	mov	si,LSEG_OFF	; Get LSEG offset
	assume	ds:nothing	; Force ES: override
	mov	PGROUP:[si].LSEG_OWNRHI,bx ; Save as owner entry
	mov	PGROUP:[si].LSEG_INSTLO,seg PGROUP ; Save as low DOS memory seg
	mov	PGROUP:[si].LSEG_INSTLEN,ax ; Save as length of ...
	assume	ds:PGROUP	; Turn off override

	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOADHI	endp			; End LOADHI procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	NPPROC	ROUND_END -- Round Up ENDADDR Variables
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Round up ending addresses to para boundaries

|

	push	ax		; Save for a moment

	mov	ax,ENDADDR	; Get current offset
	add	ax,16-1 	; Round up
	and	ax,not (16-1)	; Knock off to paragraph boundary
	mov	ENDADDR,ax	; Save as new low end address

	mov	ax,HI_ENDADDR	; Get current offset
	add	ax,16-1 	; Round up
	and	ax,not (16-1)	; Knock off to paragraph boundary
	mov	HI_ENDADDR,ax	; Save as new high end address

	mov	ax,XHI_ENDADDR	; Get current offset
	add	ax,16-1 	; Round up
	and	ax,not (16-1)	; Knock off to paragraph boundary
	mov	XHI_ENDADDR,ax	; Save as new high end address

	pop	ax		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROUND_END endp			; End ROUND_END procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	NPPROC	CREA_LSEG -- Create LSEG Entry
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Create LSEG entry

On entry:
BX=0	 Calculate new LSEG_OFF and adjust ENDADDR, but don't copy data
BX=1	 Don't change LSEG_OFF and ENDADDR, but copy data

|

	REGSAVE <cx,si,di,es>	; Save registers

	call	ROUND_END	; Ensure all segment values are rounded up

; Copy LSEG to ENDADDR and update it

	push	seg PGROUP	; Get our data segment
	pop	es		; Address it
	assume	es:PGROUP	; Tell the assembler about it

	lea	si,LSEG 	; DS:SI ==> LSEG contents
	mov	di,ENDADDR	; ES:DI ==> ending address
	cmp	HI_ENDADDR,0	; Do we have our fingers in high DOS?
	jz	short @F	; Jump if not

	mov	es,PGRSEG	; Address high DOS
	assume	es:nothing	; Tell the assembler

	mov	di,HI_ENDADDR	; End of high DOS portion of MAX
@@:
	mov	cx,size LSEG_STR ; # bytes to move

	or	bx,bx		; Are we adjusting values?
	jnz	short CREA_LSEG_COPY ; Jump if not

	mov	LSEG_OFF,di	; Save for later use
	add	di,cx		; Add bytes to be copied

	add	XHI_ENDADDR,cx	; Add to putative size in high DOS

	cmp	HI_ENDADDR,0	; Izit in high DOS?
	jz	short @F	; Jump if not

	mov	HI_ENDADDR,di	; Save rounded up value
	jmp	short CREA_LSEG_XCOPY ; Join common code

@@:
	mov	ENDADDR,di	; Save for later use
	jmp	short CREA_LSEG_XCOPY ; Join common code

CREA_LSEG_COPY:
	mov	di,LSEG_OFF	; Use previously saved value
S16 rep movsb			; Copy to ending address

CREA_LSEG_XCOPY:
	call	ROUND_END	; Ensure all segment values are rounded up

	REGREST <es,di,si,cx>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CREA_LSEG endp			; End CREA_LSEG procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	NPPROC	FILL_LSEG -- Fill In LSEG Entry
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in LSEG entry

|

	test	NRD_FLAG,@NRD_LSEG ; Izit already filled in?
	jnz	near ptr FILL_LSEG_EXIT ; Jump if so

	REGSAVE <ax,bx,cx,es>	; Save registers

; Fill in LSEG with values

	mov	es,PGRSEG	; Get high DOS segment
	assume	es:PGROUP	; Tell the assembler

; Note that XHI_ENDADDR is the same as ENDADDR without the HPDAREG,
; XBDAREG, and STACKREG.
	mov	ax,XHI_ENDADDR	; Get putative ending address in high DOS
	mov	bx,LSEG_OFF	; Get LSEG offset
	mov	cl,@NOTSPEC	; Assume PRGREG not specified

	test	CM3_FLAG,@CM3_PREG ; Izit specified?
	jz	short @F	; Jump if not

	mov	cl,PRGREG.LO	; Get specified program region #
@@:
	test	LCL_FLAG,@LCL_LODHI ; Izit loaded high?
	jz	short FILL_LSEG_XLHI ; Jump if not

	assume	ds:nothing	; Use ES: override
	mov	PGROUP:[bx].LSEG_ASIZE.ELO,ax ; Save as actual SIZE
	mov	PGROUP:[bx].LSEG_ASIZE.EHI,0
	assume	ds:PGROUP	; OK to use DS

	jmp	short FILL_LSEG_COM ; Join common code

FILL_LSEG_XLHI:
	assume	ds:nothing	; Use ES: override
	mov	PGROUP:[bx].LSEG_ASIZE,-1 ; Save as pseudo-SIZE
	mov	cl,0		; Mark as PRGREG=0
FILL_LSEG_COM:
	mov	PGROUP:[bx].LSEG_PREG,cl ; Save as program region #
	mov	PGROUP:[bx].LSEG_EREG,@NOTSPEC ; ...environment not specified
	mov	PGROUP:[bx].LSEG_GRP,@GRPMAX ; Put into a group by itself

	mov	PGROUP:[bx].LSEG_LSIZE.ELO,ax ; Save as load size
	mov	PGROUP:[bx].LSEG_LSIZE.EHI,0

	mov	PGROUP:[bx].LSEG_ISIZE.ELO,ax ; Save as initialization size
	mov	PGROUP:[bx].LSEG_ISIZE.EHI,0

	shr	ax,4-0		; Convert from bytes to paras
	mov	PGROUP:[bx].LSEG_RPARA,ax ; Save as resident size in paras
	mov	PGROUP:[bx].LSEG_EPAR0,0 ; No environment size (before)
	mov	PGROUP:[bx].LSEG_EPAR1,0 ; No environment size (after)
	mov	PGROUP:[bx].LSEG_RPAR2,0 ; No forced SIZE=
;;;;;;; mov	PGROUP:[bx].LSEG_NPARA,1+@LSEGPARA ; INT block incl MAC para
	mov	PGROUP:[bx].LSEG_NPARA,0 ; INT block incl MAC para
				; (already counted in AX)
	or	PGROUP:[bx].LSEG_FLAG,@LSEG_DRV ; Mark as device driver

; Fill in new LOADSEG address

	mov	ax,es		; Get PGROUP segment in high DOS
	shr	bx,4-0		; Convert from bytes to paras
	add	ax,bx		; AX = new load segment #
	mov	LOADSEG,ax	; Save as load chain segment
	assume	ds:PGROUP	; Address low DOS

	mov	LOADSEG,ax	; Save as load chain segment

	or	NRD_FLAG,@NRD_LSEG ; Mark as filled in

	REGREST <es,cx,bx,ax>	; Restore
	assume	es:nothing	; Tell the assembler
FILL_LSEG_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_LSEG endp			; End FILL_LSEG procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	NPPROC	FILL_DSTKS -- Fill In DOS Stacks
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in DOS stacks variables, tables, and signatures,
and tell the code in extended memory about it.

|

	pushad			; Save all EGP registers
	REGSAVE <ds,es> 	; Save segment registers

	mov	ax,seg PGROUP	; Get low DOS PGROUP
	mov	ds,ax		; Address PGROUP
	assume	ds:PGROUP	; Tell the assembler

; Copy static SGROUP code to its final destination

	push	ds		; Save for a moment

	mov	es,PDSTKCOM.VSEG ; Get segment of DOS stacks destination
	assume	es:nothing	; Tell the assembler about it

	mov	ax,seg SGROUP	; Get segment of DOS stacks source
	mov	ds,ax		; Address it
	assume	ds:SGROUP	; Tell the assembler about it

	lea	cx,SCODE_END	; Use static ending address as byte length
	xor	si,si		; DS:SI ==> DOS stack source
	xor	di,di		; ES:DI ==> ...       destin
S16 rep movs	<es:[di].LO,SGROUP:[si]> ; Move to final destin

	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler about it

	assume	es:SGROUP	; For the purposes of the following code

; Initialize LaDSTK_TAB variable

	movzx	eax,PDSTKCOM.VSEG ; Get segment of DOS stacks
	shl	eax,4-0 	; Convert from paras to bytes

	lea	ebx,DSTK_TAB[eax] ; Get linear address of DSTK_TAB
	mov	LaDSTK_TAB,ebx	; Save for later use

; Initialize DSTK_TAB and the DOS stacks signature

;;;;;;; movzx	eax,PDSTKCOM.VSEG ; Get segment of DOS stacks
;;;;;;; shl	eax,4-0 	; Convert from paras to bytes
	movzx	edi,DSTK_NPAR	; Get # paras in DOS stacks
	shl	edi,4-0 	; Convert from paras to bytes
	add	eax,edi 	; Add to get linear address of top of stack

	movzx	edx,PDSTKCOM.VSEG ; Get segment of DOS stacks
	shl	edx,16		; Shift to high-order word
	mov	dx,di		; Copy byte offset of top of stack

	mov	cx,DSTK_CNT	; Get # DOS stacks
	xor	bx,bx		; Initialize index into DSTK_TAB
	movzx	esi,DSTK_ISIZ	; Get size of individual DOS stack
FILL_DSTKS_NEXT:
	mov	DSTK_TAB.DSTK_TAB_OLDSTKVEC[bx],@STKAVL ; Mark as available
	mov	DSTK_TAB.DSTK_TAB_DOSSTKVEC[bx],edx ; Save Seg:Off of stack top
	mov	DSTK_TAB.DSTK_TAB_LaDOSTOP[bx],eax  ; Save linear address of ...

; Fill the DOS stack with a known value

	REGSAVE <eax,cx,di>	; Save for a moment

	mov	cx,si		; Get size of individual DOS stack (/4)
	shr	cx,2-0		; Convert from bytes to dwords
	dec	cx		; Less the last dword (stored separately)
	sub	di,4		; Back off to last dword

	std			; String ops backwards

	mov	eax,@STKSIG	; Get the stack signature
S16	stos	SGROUP:[di].EDD ; Store the signature

	mov	eax,@STKFILL	; Fill the remainder with this
    rep stos	SGROUP:[di].EDD ; Store the signature

	cld			; String ops forwardly

	REGREST <di,cx,eax>	; Restore

	sub	eax,esi 	; Back off by one stack's worth
	sub	dx,si		; ...
	sub	di,si		; ...

	add	bx,type DSTK_TAB_STR ; Skip to next entry

	loop	FILL_DSTKS_NEXT ; Jump if more entries

; Save the next offset after DSTK_TAB for use in DSTKCOM

	mov	DSTK_TAB_NXTOFF,bx ; Save for later use

; Tell protected mode code of new PDSTKCOM in EBX
; and LaDSTKTAB in ECX

	CPD	'Calling @EMM2_DSTKS,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	mov	ebx,PDSTKCOM	; Get new value
	mov	ecx,LaDSTK_TAB	; ...

; Use DS in high DOS in case we overwrote the low memory PORT67 value.

	mov	ds,XPGRSEG	; Setup DS for data references
	assume	ds:PGROUP	; Tell the assembler about it

	mov	al,@DSTKS_SETINFO ; Function code to set new values
	EMMOUT	@EMM2_DSTKS	; Tell 'em

	REGREST <es,ds> 	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_DSTKS endp 		; End FILL_DSTKS procedure
endif				; IF @OEM_HIFILL
if @OEM_EMS
	FPPROC	INIT2X -- Secondary Device Driver Initialization
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize secondary device driver to same ending address
as the first device driver.

We can no longer count on addressability to anything in PGROUP
that's not in QMAX_OVR.  We need to use PGRSEG for any such
addressability, since the following data items may have been
appended to the low DOS portion of MAX, overwriting whatever
was there previously:

HPDA	6K
XBDA	3K
Stacks	64K

Anything else we need here will have to come from XGROUP.

We also check here for the ending low DOS MAC entry having changed.
This indicates that DOS=UMB is in effect.  If this is the case, we
set the @I15_X58 flag so that 5802/5803 calls will be passed down to DOS.

If DOS=UMB is not in effect, we need to allocate one paragraph for a
spanning entry anyway.	As we're emulating DOS=UMB, we need to go the
whole nine yards and leave the arenas linked; some programs, namely
XTRADRV.SYS v3.0, rely on this.  If a paragraph has been allocated for
a spanning entry, they complain if high DOS isn't also linked.

|

	CPD	'Entering INIT2X,  CS:IP=%CS:%IP  DS=%DS  ES:BX=%ES:%BX'

	REGSAVE <ax,bx,ds,es>	; Save registers

	mov	ds,XPGRSEG	; Setup DS for data references
	assume	ds:PGROUP	; Tell the assembler about it

	les	bx,RH_VECX	; Restore ES:BX to request header
	assume	es:nothing	; Tell the assembler about it

; ENDADDR and PGRSEG may not exist in the low DOS part of PGROUP.
; Use the copies in XGROUP.

	mov	ax,XENDADDR	; Get ending offset
	mov	es:[bx].INIT_END_VEC.VOFF,ax ; Tell DOS about it
	mov	es:[bx].INIT_END_VEC.VSEG,seg PGROUP ; Segment, too
	mov	es:[bx].INIT_UNITS,0 ; No units defined

	push	seg PGROUP	; Prepare to address low DOS PGROUP
	pop	es		; Get addressability to DEVDRV2
	assume	es:PGROUP	; Tell the assembler

if @OEM_HIFILL
	test	LCL_FLAG,@LCL_LODHI ; LOADHI in effect?
	jz	short INIT2X_XLODHI ; Not this time

; Set new strategy and interrupt routines

	assume	ds:nothing	; Force override
	mov	DEVDRV2.DD_STRA,offset PGROUP:LHI_STRA
	mov	DEVDRV2.DD_INTR,offset PGROUP:LHI_INTR
	assume	ds:PGROUP	; Address PGRSEG

	jmp	short INIT2X_COM ; Join common code

INIT2X_XLODHI:
endif				; IF @OEM_HIFILL
	assume	ds:nothing	; Force override
	mov	DEVDRV2.DD_STRA,offset PGROUP:DEV_STRA ; Note for next time
	mov	DEVDRV2.DD_INTR,offset PGROUP:DEV_INTR ; Note for next time
	assume	ds:PGROUP	; Address PGRSEG
INIT2X_COM:
if @OEM_HIFILL
	les	bx,PLAST_MAC	; ES:BX ==> last entry in MAC
	assume	es:nothing	; Tell the assembler

	mov	ax,PREV_LMAC_NPAR ; Get previous value of starting MAC entry

	test	CMD_FLAG,@CMD_XHI ; Is NOHIGH specified?
	jnz	short INIT2X_X58 ; Jump if so

	cmp	es:[0].MAC_NPAR,ax ; Did the length change?
	je	short @F	; Jump if no change

INIT2X_X58:
	or	I15_FLAG,@I15_X58 ; Pass all function 58 calls down to DOS

	jmp	short INIT2X_EXIT ; Join common exit

@@:
	dec	es:[0].MAC_NPAR ; Allocate space for spanning entry

; Link high DOS arena.	When DOS=UMB is active, the arena is linked as soon
; as it is created (i.e., as soon as XMS UMBs can be allocated) but 5802 and
; 5803 calls are not hooked up yet.  The flag at ]LOLSEG:89 is not updated
; although the spanning entry segment at [LOLSEG:8C is.  After all DEVICE
; statements but before the first INSTALL, the arenas are unlinked and fn 58
; services work as expected.

; We've saved the PSP in INITX; until we get a call from a different PSP
; (meaning we're running an INSTALL= program, COMMAND.COM, or an application)
; we won't update the flag at ]LOLSEG:89.  On the first call, we'll close
; the arena link.  This is as precise as we can get without depending on
; code searches and the like to bung patches into DOS (no thank you).
	mov	bx,1		; Set state to linked
	mov	ax,@MACALG*100h + 03h ; Set link state to BX
	DOSCALL 		; Ignore return status
INIT2X_EXIT:
endif				; IF @OEM_HIFILL

	les	bx,RH_VECX	; Restore ES:BX to request header
	assume	es:nothing	; Tell the assembler about it

	STATUS	DONE,NOERROR	; Set status word (done, no error)

	CPD	'Leaving INIT2X,  CS:IP=%CS:%IP  DS=%DS  ES:BX=%ES:%BX'

	REGREST <es,ds,bx,ax>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT2X	endp			; End INIT2X procedure
endif				; IF @OEM_EMS
if @OEM_EMS
	FPPROC	DEV_STR2X -- Secondary Device Strategy Routine
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save ES:BX for later use.

|

	CPD	'Entering DEV_STR2X,  CS:IP=%CS:%IP  DS=%DS  ES:BX=%ES:%BX'
.8086
	mov	RH_VECX.VSEG,es ; Save segment of request header pointer
	mov	RH_VECX.VOFF,bx ; ...	offset
DOT386 p
	CPD	'Leaving DEV_STR2X,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_STR2X endp			; End DEV_STR2X procedure
endif				; IF @OEM_EMS
	NPPROC	MODIFY_INT2F -- Modify Int 2F function 13h
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Modify INT 2F func 13h

If the BIOS has been compressed due to either BCF or COMPROM methods,
we have to modify the ES:BX portion of INT 2F func 13h to recognize the
compressed BIOS entry points.  Since our single stepping method updates
the DS:DX value, we must modify the ES:BX value only.

If we're in the testing phase, compare the ES:BX and DS:DX values.
If we're in the modifying phase and the testing phase found the two
original vectors to be the same, set the ES:BX value to the DS:DX
value in case we modified one but not the other.

If we're in the replacing stage, it has nothing to do with the BIOS
being compressed.  Instead, there is a previous VDS table and we need
to distinguish CPU physical from bus physical VDS translations and need
to know whether or not we're in the midst of an INT 13h call.

Unfortunately, Windows 3.1's WDCTRL 32-bit disk access driver
doesn't like to see anyone below A000 hooking the disk vector this way.
We'll need to restore and re-hook the vector when Windows starts
up (1605) and shuts down (1606).

|

MINT2F_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
MINT2F_FLG dw	?		; Flag:  0 = testing, 1 = modifying, 2 = replacing

MINT2F_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	pushad			; Save all EGP registers
	REGSAVE <ds,es,fs>	; Save segment registers

	mov	ax,cs		; Get segment of LOCAL_INT13
	mov	ds,ax		; ... and address it
	assume	ds:XGROUP	; Tell the assembler about it
	mov	es,ax		; ... and address it
	assume	es:XGROUP	; Tell the assembler about it

	mov	ax,seg PGROUP	; Get segment of NRD_FLAG
	mov	fs,ax		; ... and address it
	assume	fs:PGROUP	; Tell the assembler about it

	lea	dx,LOCAL_INT13	; DS:DX ==> local INT 13h handler
	mov	bx,dx		; ES:BX ==> local INT 13h handler (for reboot)

; Get DOS' current idea of the INT 13h vectors

	cli			; Make the unlikely interrupt window smaller

	mov	ah,13h		; Swap INT 13h vector in IO.SYS
	int	2Fh		; DOS multiplex services
	assume	ds:nothing, es:nothing ; Tell the assembler

	cli			; Make the unlikely interrupt window smaller

; Distinguish cases

	cmp	[bp].MINT2F_FLG,1 ; Check the state
	jb	short MODIFY_INT2F_SAVE ; Jump if we're testing
	ja	short MODIFY_INT2f_REPL ; Jump if we're replacing

; Modify phase:  note equality test applied by caller

	push	ds		; Copy DS:DX to ES:BX
	pop	es		; ...
	assume	es:nothing	; Tell the assembler about it

	mov	bx,dx		; ...

	jmp	short MODIFY_INT2F_COM ; Join common code

MODIFY_INT2F_SAVE:

; Calculate the corresponding linear address for ES:BX and DS:DX
; and compare them

	xor	esi,esi 	; Zero to use as dword
	mov	si,ds		; Copy segment value
	shl	esi,4-0 	; Convert from paras to bytes
	movzx	edx,dx		; Zero to use as dword
	add	esi,edx 	; Add to get 32-bit linear address

	xor	edi,edi 	; Zero to use as dword
	mov	di,es		; Copy segment value
	shl	edi,4-0 	; Convert from paras to bytes
	movzx	ebx,bx		; Zero to use as dword
	add	edi,ebx 	; Add to get 32-bit linear address

	cmp	esi,edi 	; Compare 'em
	jne	short MODIFY_INT2F_COM ; Jump if not

	or	NRD_FLAG,@NRD_INT2FEQ ; Mark as equal for modify phase

	jmp	short MODIFY_INT2F_COM ; Join common code

MODIFY_INT2F_REPL:
	mov	fs,XPGRSEG	; Address the segment of OLDINT13A/B
	assume	fs:PGROUP	; Tell the assembler about it

; Save the current addresses for later use

	mov	OLDINT13A_VEC.VSEG,ds ; Save 'em
	mov	OLDINT13A_VEC.VOFF,dx ; ...

	mov	OLDINT13B_VEC.VSEG,es ; ...
	mov	OLDINT13B_VEC.VOFF,bx ; ...

	mov	ds,XPGRSEG	; Address the segment of RESINT13A
	assume	ds:PGROUP	; Tell the assembler about it

	lea	dx,RESINT13A	; DS:DX ==> new handler

	mov	es,XPGRSEG	; Address the segment of RESINT13B
	assume	es:PGROUP	; Tell the assembler about it

	lea	bx,RESINT13B	; ES:BX ==> new handler

	assume	ds:nothing,es:nothing,fs:nothing ; Tell the assembler about it

MODIFY_INT2F_COM:

; Reset the vectors

	mov	ah,13h		; Swap INT 13h vector in IO.SYS
	int	2Fh		; DOS multiplex services
	assume	ds:nothing, es:nothing ; Tell the assembler

	sti			; Open the interrupt window

	REGREST <fs,es,ds>	; Restore
	assume	ds:PGROUP,es:PGROUP,fs:nothing ; Tell the assembler about it
	popad			; Restore all EGP registers

	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MODIFY_INT2F endp		; End MODIFY_INT2F procedure
	FPPROC	LOCAL_INT13 -- Local INT 13h handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Local INT 13h handler while we diddle with INT 2F func 13h

|

LI13_STR struc			; Structure to access IRET frame

LI13_BP dw	?		; Caller's BP
LI13_IP dw	?		; ...	   IP
LI13_CS dw	?		; ...	   CS
LI13_FL dw	?		; ...	   flags

LI13_STR ends			; End LI13_STR structure

	push	bp		; Save previous stack frame
	mov	bp,sp		; Access our local stack frame

	or	[bp].LI13_FL,(mask $CF) ; Set carry flag in IRET frame

	pop	bp		; Restore previous stack frame

	mov	ah,80h		; Time-out error indicator

	iret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOCAL_INT13 endp		; End LOCAL_INT13 procedure
	FPPROC	INITX -- Initialization Code
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

I N I T I A L I Z A T I O N

Check command line arguments and take action as appropriate.
Fill in the BPB pointer and ending addresses.

|
.8086

; Switch to local stack

	push	ds		; Save for a moment

	mov	ds,XPGRSEG	; Setup DS for data references
	assume	ds:PGROUP	; Tell the assembler about it

	mov	OLDSTK_VEC.VSEG,ss ; Save current stack segment
	mov	OLDSTK_VEC.VOFF,sp ; ...		 pointer

	cli			; In case we're on an old 8088
	mov	ss,PGRSEG	; Setup SS for stack references
	mov	sp,PLOWSTKZ	; Address new temporary stack
	sti			; Allow interrupts again

	pushf			; Save flags

	cld			; String ops forwardly

	REGSAVE <ax,bx,cx,dx,si,di,bp,es> ; Save all registers

	mov	es,PGRSEG	; Setup ES for data references
	assume	es:PGROUP	; Tell the assembler about it

	mov	DEVDRV.DD_INTR,offset PGROUP:DEV_INTR ; Note for next time

; Initialize MAPSEG_NXT

	lea	ax,YGROUP:YDATA_NXT[16-1] ; Get offset of next paragraph
	mov	cl,4-0		; Shift amount between bytes and paras
	shr	ax,cl		; Convert from bytes to paras
	add	ax,seg YGROUP	; Plus its segment
	mov	MAPSEG_NXT,ax	; Save as next available segment

; Mark as using our own method to Enter PM

	or	DB3_FLAG,@DB3_EPM ; Mark it as such

; Display our copyright notice

if @OEM_SYS ne @OEMSYS_AST386
	lea	ax,YGROUP:MSG_COPYRIGHT ; Display the flag
	push	ax		; Pass as argument
	call	YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_SYS ne @OEMSYS_AST386

	call	CHECK_SHIFT	; Check keyboard shift state
	MJ c	UGH_INIT	; User says not to install

	call	CHECK_CPUID	; Ensure we're on a 386 processor
	MJ c	UGH_INIT	; Not to our liking
DOT386 p
; Note that only after this point are we allowed to use non-8088 instructions

; Note that until we call CALC_SCRN, we don't know whether we're using
; the mono or color text buffer.  As this fact is needed by the routine
; called in the CPD macro, we call CALC_SCRN early.

	call	CALC_SCRN	; Determine screen adapter presence

if @OEM_DEBUG
	REGSAVE <eax,bx,cx,dx>	; Save for a moment

	mov	bh,0		; Display page #0
	VIDCALL @GETPOS 	; Get cursor position into (DH,DL) from page BH
				; (CH,CL) is cursor type
	movzx	eax,dh		; Copy screen row # (origin-0)
	imul	eax,2*80	; Times length of one screen row
	mov	CPDOFF,eax	; Save for later use

	REGREST <dx,cx,bx,eax>	; Restore
endif				; IF @OEM_DEBUG

	CPD	'Calling DISP_OEM,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	DISP_OEM	; Display any OEM messages

	CPD	'Calling CHECK_INFO,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_INFO	; Check and display IDN info
	jc	near ptr UGH_INIT ; Jump if something went wrong

if @OEM_XMS
	CPD	'Calling CHECK_XMS,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_XMS	; See if XMS handler already installed
endif				; IF @OEM_XMS
	CPD	'Calling CHECK_MODEL,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_MODEL	; Check for MCA-compatible machine to set
				; SYSROM_START and FRAME, XT to set @LCL_XT
				; and DMASIZE, and EISA or PCI to set flags

	CPD	'Calling CHECK_EXT,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_EXT	; Get size of extended memory
	jc	near ptr UGH_INIT ; Jump if bad memory return from EISA board

	CPD	'Calling CHECK_VDS,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_VDS	; Check on previous VDS handler
	jc	near ptr UGH_INIT ; Jump if VDS error

;;;;;;; call	READA20 	; Return the state of the A20 line in @GLB_X1MB

	CPD	'Calling CHECK_XBIOS,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_XBIOS	; Check on XBIOS data area presence and relocatibility

	CPD	'Calling CHECK_CNV,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_CNV	; Check on conventional memory

	CPD	'Calling CHECK_DOSVER,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_DOSVER	; Ensure we're on DOS 3.00 or later
	jc	near ptr UGH_INIT ; Jump if something went wrong

if @OEM_HIFILL
	CPD	'Calling GET_MACINFO, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	GET_MACINFO	; Get MAC strategy
endif				; IF @OEM_HIFILL

	CPD	'Calling INTR_GET,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	INTR_GET	; Get old interrupt handlers

	CPD	'Calling CALC_RESIDENT,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CALC_RESIDENT	; See if we're already resident
	jc	near ptr UGH_INIT ; Something went wrong

	CPD	'Calling SET_LOWMEM,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	SET_LOWMEM	; Setup low memory values

	test	NRD_FLAG,@NRD_RES ; Already resident?
	jnz	near ptr INIT_CHKRES ; Yes

	CPD	'Calling CHECK_VM86,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_VM86	; Ensure no other Virtual 8086 mode monitor
	jc	near ptr UGH_INIT ; Something went wrong

; Note we *MUST* check on previous bottom-up extended memory users
; before we check on QEXT.SYS.

	CPD	'Calling CHECK_PRVEXT,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_PRVEXT	; Check on preceding extended memory usage

	CPD	'Calling CHECK_QEXT,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_QEXT	; See if QEXT.SYS is already installed

	CPD	'Calling SET_PATHSTEM, CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	SET_PATHSTEM	; Save drive and path from device line
				; Used by POSREADALL, CHECK_ARGS, and
				; when reading XLAT.COM

	test	LCL_FLAG,@LCL_MCA ; Izit PS/2-compatible?
	jz	short @F	; Jump if not

	CPD	'Calling POSREADALL,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	POSREADALL	; Read all POS data from MCA
@@:
if @OEM_BCF
	CPD	'Calling CHECK_BCRC,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_BCRC	; Set the BIOS CRC
endif				; IF @OEM_BCF
	CPD	'Calling FILL_MAP,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	FILL_MAP	; Fill in initial MAP_MEM and PPMTAB entries

	CPD	'Calling CHECK_NDP,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_NDP	; Check on NDP status
				; Call before CHECK_ARGS to set NDP bits

; Note that the test phase of MODIFY_INT2F *MUST* be called
; before CHECK_ARGS and CHECK_SYSID.

	CPD	'Calling MODIFY_INT2F(0),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	push	0		; Mark as just testing
	call	MODIFY_INT2F	; Modify INT 2F func 13h (if appropriate)

	CPD	'Calling CHECK_ARGS,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_ARGS	; Check command line arguments
	jc	near ptr UGH_INIT ; Something went wrong

; We must defer display of the ABIOS initialization error message till
; here so we can override it with NOABIOS.
	test	NRD_FLAG,@NRD_ABIOSERR ; Did an error occur?
	jz	short @F	; Jump if not

; Bitch about the failure; perhaps the user patched to this version
; and needs to run INSTALL/r or MAXIMIZE.
	push	offset YGROUP:MSG_ABIOSERR ; Pass address of error message
	call	YMSGOUT2	; Display YGROUP message
@@:
	CPD	'Calling CHECK_BPI,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	pushf			; Simulate INT environment
	call	CHECK_BPI	; Check on breakpoint interrupts

if @OEM_DMA and @OEM_SYS ne @OEMSYS_ILIM
	CPD	'Calling TEST_DMA,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	TEST_DMA	; Test hard disk for DMA (@LCL_XT-dependent)
endif				; IF @OEM_DMA and @OEM_SYS ne @OEMSYS_ILIM

	CPD	'Calling CHECK_SYSID,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_SYSID	; Handle system- and model-dependent code
	jc	near ptr UGH_INIT ; Something went wrong

	CPD	'Calling CHECK_EISADMA, CS:IP=%CS:%IP'

	call	CHECK_EISADMA	; If EISA DMA, set high order bytes to 0

	CPD	'Calling INIT_CHIPSET,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	INIT_CHIPSET	; Initialize CHIPset entries

	CPD	'Calling CALC_ALLMEM,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CALC_ALLMEM	; Check out needed memory
	jc	near ptr UGH_INIT ; Something went wrong

	CPD	'Calling CHECK_SHADOW,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CHECK_SHADOW	; Check for shadow RAM

; Note we must call IZIT_PnP before calling TIME_ALLMEM as the
; latter code references variables initialized in the former.

	CPD	'Calling IZIT_PnP,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	IZIT_PnP	; See if there's a Plug 'n Play BIOS

	CPD	'Calling TIME_ALLMEM,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	TIME_ALLMEM	; Time memory accesses
	jc	near ptr UGH_INIT ; Something went wrong

	CPD	'Calling CALC_SIZE,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CALC_SIZE	; Calculate various sizes
	jc	near ptr UGH_INIT ; Something went wrong

if @OEM_WIN3
	CPD	'Calling CALC_WIN3,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CALC_WIN3	; Calculate values needed by Windows 3
endif				; IF @OEM_WIN3

	CPD	'Calling FIND_ZMAC,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	FINDZMAC	; P1ST_MAC <== 1st MAC entry, PLAST_MAC <== last
;;;;;;; jnc	short ???	; Jump if found

if @OEM_SYS ne @OEMSYS_HPRS and @OEM_SYS ne @OEMSYS_AST386
	CPD	'Calling CALC_STAT,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CALC_STAT	; Calculate statistics

	CPD	'Calling PROT_INIT,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	PROT_INIT	; Protected mode routines
	jc	near ptr UGH_INIT ; Something went wrong

COMMENT|

In order to support the DOS CONFIG.SYS option of HIMEM /DOS /NOXMS,
we *MUST NOT* use any DOS calls until we have installed our own XMS
handler into low DOS memory which is done in INTR_SET.

|

	CPD	'Calling INTR_SET,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	INTR_SET	; Install our own interrupt handlers
else
	CPD	'Calling PROT_INIT,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	PROT_INIT	; Protected mode routines
	jc	near ptr UGH_INIT ; Something went wrong

COMMENT|

In order to support the DOS CONFIG.SYS option of HIMEM /DOS /NOXMS,
we *MUST NOT* use any DOS calls until we have installed our own XMS
handler into low DOS memory which is done in INTR_SET.

|

	CPD	'Calling INTR_SET,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	INTR_SET	; Install our own interrupt handlers

	CPD	'Calling CALC_STAT,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	CALC_STAT	; Calculate statistics
endif				; IF @OEM_SYS ne @OEMSYS_HPRS and @OEM_SYS ne @OEMSYS_AST386

if @OEM_BCF
; If an error occurred in INIT_MIVT, there may be a problem with the
; BCF file.  Tell 'em about it now; this is the first chance to use
; DOS services.
	test	NRD_FLAG,@NRD_BCFERR ; Did an error occur?
	jz	short @F	; Jump if not

	push	offset YGROUP:MSG_BCFERR ; Tell 'em we found an interrupt that
				; wasn't handled by the BCF file
	call	YMSGOUT2	; Display YGROUP message

	push	offset YGROUP:MSG_PRESS ; Address of 'Press any key'
	call	YMSGOUT2	; Display YGROUP message

	call	FKEYWAIT	; Give 'em a chance to read message
				; Return with key in AX
@@:
endif				; IF @OEM_BCF

if @OEM_FLEXROM
	CPD	'Calling XLAT_VIDEO,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	XLAT_VIDEO	; Translate Video BIOS

	CPD	'Leaving XLAT_VIDEO,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'
endif				; IF @OEM_FLEXROM

; Change the last MAC entry to tell DOS about the additional low memory

	test	CMD_FLAG,@CMD_XLO ; Are we allowed to fill in low DOS memory?
	jnz	short INIT_CHK3 ; No, Join common code

	mov	cx,LOWOFF.ELO	; Get top of original DOS memory in 1KB
	shl	cx,10-4 	; Convert from 1KB to paras
	mov	ax,LOWSIZE	; Get the amount we're adding or subtracting
	sal	ax,10-4 	; Convert from 1KB to paras
	add	ax,cx		; Plus top of original DOS memory
	sub	ax,OLDDOS	; Less top of available DOS memory

	push	es		; Save for a moment

	les	bx,PLAST_MAC	; ES:BX ==> last entry in MAC
	assume	es:nothing	; Tell the assembler

	add	es:[bx].MAC_NPAR,ax ; Add/subtract into/from last MAC entry

	pop	es		; Restore
	assume	es:PGROUP	; Tell the assembler about it

	CPD	'Calling SET_MEM,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	SETMEM		; Set low memory size

	jmp	short INIT_CHK3 ; Join common code

INIT_CHKRES:
	CPD	'Calling INTR_SET,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	INTR_SET	; Install our own interrupt handlers
INIT_CHK3:
	test	LCL_FLAG,@LCL_LOWFR ; EMS page frame in low DOS memory?
	jnz	short INIT_CHK4 ; Yes

	test	CMD_FLAG,@CMD_XHI ; Any new high DOS memory?
	jnz	short @F	; No
INIT_CHK4:
	CPD	'Calling DECR_MAC,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	DECR_MAC	; Decrement memory allocation chain
@@:

if @OEM_HIFILL
	CPD	'Calling LOADHI,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	LOADHI		; Attempt to load ourselves into high memory
endif				; IF @OEM_HIFILL

	test	LCL_FLAG,(@LCL_BCF or @LCL_CROM) ; Is the BIOS compressed?
	jz	short @F	; Jump if not

	test	NRD_FLAG,@NRD_INT2FEQ ; Were INT 2Fh vectors equal in RM?
	jz	short @F	; Jump if not

	CPD	'Calling MODIFY_INT2F(1),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	push	1		; Mark as just modifying
	call	MODIFY_INT2F	; Modify INT 2F func 13h (if appropriate)
@@:

; If there's a previous VDS handler, we'll need to hook INT 13h
; to distinguish CPU physical from bus physical translation.

	cmp	VDSTAB_SEG,0	; Is there a previous VDS table?
	jne	short INIT_MOD2F ; Jump if so

if @OEM_VIRTUALMEM
; If there are any XMEIs, we must install an INT 13h handler
; so we can tell if we're in the midst of an INT 13h call when
; a HW interrupt occurs and paging is active.

	test	VMM_FLAG,@VMM_BSGLOBAL ; Is a swap file present?
	jz	short INIT_XMOD2F ; Jump if not

	cmp	CFGLIST_XMEI.LLST_DAT.LFLG_NEXT,-1 ; Anybody home?
	je	short INIT_XMOD2F ; Jump if not
else
	jmp	short INIT_XMOD2F ; Not necessary to hook INT 13h
endif				; IF @OEM_VIRTUALMEM

INIT_MOD2F:
	CPD	'Calling MODIFY_INT2F(2),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	push	2		; Mark as just replacing
	call	MODIFY_INT2F	; Modify INT 2F func 13h (if appropriate)

; Mark as hooked.  Note that we do this AFTER using Int 2fh; we'll terminate
; all Int 2Fh function 13h calls from now on.
	push	ds		; Save for a moment

	mov	ds,PGRSEG	; Get HIMEM_CS value
	assume	ds:PGROUP	; Tell the assembler

	mov	HOOK13,@HOOK13_ACTIV ; Mark as disk vector intercepted
				; and active
	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler

INIT_XMOD2F:

if @OEM_XMS
	test	NRD_FLAG,@NRD_HMA ; Izit initially in use?
	jz	short @F	; Jump if not

	CPD	'Calling NEWXMS_VEC(REQHMA),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	mov	dx,-1		; Request all of it
	mov	ah,@XMS_REQHMA	; Function code to request the HMA
	call	NEWXMS_VEC	; Request XMS service
@@:
	test	NRD_FLAG,@NRD_A20 ; Izit initially enabled?
	jz	short @F	; Jump if not

	CPD	'Calling NEWXMS_VEC(LCLENA),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	mov	ah,@XMS_LCLENA	; Function code to request local enable of A20
	call	NEWXMS_VEC	; Request XMS service
@@:
endif				; IF @OEM_XMS

	jmp	short INIT_OK	; All went OK

; There is an unspecified failure during initialization

.8086
UGH_INIT:
	mov	DEVDRV.DD_ATTR,0 ; Bug in DOS doesn't allow char devices to
				; fail initialization -- convert to block device
if @OEM_EMS
	mov	DEVDRV2.DD_ATTR,0 ; Here, too
endif				; IF @OEM_EMS

	and	I15_FLAG,not (@I15_XBREL or @I15_DSTK) ; Clear XBIOS and STACKS flags
;;;;;;; mov	XBIOS_HI,0	; Clear value, too
	or	CM2_FLAG,@CM2_XSCSI ; Ensure we don't check for SCSI bus masters
if @OEM_DEBUG
	mov	LOADCOUNT,0	; Don't do anything in INIT_VIRT
endif				; IF @OEM_DEBUG
if @OEM_DPMI
	mov	HPDASEG,0	; Don't make EMM2CALL for HIMEM_CS / HPDA seg
endif				; IF @OEM_DPMI

	les	bx,RH_VEC	; Restore ES:BX to request header
	assume	es:nothing	; Tell the assembler about it

	mov	es:[bx].INIT_UNITS,0 ; No units defined
	mov	es:[bx].INIT_END_VEC.VOFF,0
	mov	es:[bx].INIT_END_VEC.VSEG,seg PGROUP ; Mark as ending address

	STATUS	DONE,ERROR,ERR_UGH ; Mark as general failure

	lea	ax,YGROUP:MSG_NOTINST ; Tell 'em we're not installed
	push	ax		; Pass as argument
	call	YMSGOUT2	; Display YGROUP message

; Purge the keyboard buffer and wait for a key press -- discard the key

	call	FKEYWAIT	; Wait for an acknowledgement
				; Return with key in AX

	jmp	short EXIT	; Join common exit code
DOT386 p
INIT_OK:

; Display message of successful installation

	test	CMD_FLAG,@CMD_TERSE ; Izit to be terse?
	jnz	short @F	; Jump if so

	add	CPDCNT,@MSG_STAT_ROWCNT ; Ensure the Blue Screen does not
				; scroll our messages off the screen

	CPD	'Calling FDISP_COLOR,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	push	offset ds:MSG_STAT ; Pass offset of string
	call	FDISP_COLOR	; Display string in color
@@:

; Report back our ending address

	les	bx,RH_VEC	; Restore ES:BX to request header
	assume	es:nothing	; Tell the assembler about it

	mov	es:[bx].INIT_UNITS,0 ; No units defined
	mov	ax,ENDADDR	; Get ending offset
	mov	es:[bx].INIT_END_VEC.VOFF,ax ; Tell DOS about it
	mov	es:[bx].INIT_END_VEC.VSEG,seg PGROUP ; Segment, too

	STATUS	DONE,NOERROR	; Set status word (done, no error)
.8086
EXIT:
	REGREST <es,bp,di,si,dx,cx,bx,ax> ; Restore registers
	assume	es:nothing	; Tell the assembler about it

	popf			; Restore

	assume	ds:PGROUP	; Tell the assembler about it

; Switch back to caller's stack

	cli			; In case we're on an old 8088

; Note that we might be on a non-386 so we can't use LSS

	mov	ss,OLDSTK_VEC.VSEG ; Restore old stack segment
	mov	sp,OLDSTK_VEC.VOFF ;			pointer

	sti			; Allow interrupts again
	cld			; Ensure string ops forwarly

; Test for bus masters

	test	CM2_FLAG,@CM2_XSCSI ; Should we check for 'em?
	jnz	short @F	; Jump if not
DOT386 p
	CPD	'Calling BUSMASTER,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	BUSMASTER	; Check for 'em, complain if found
@@:
if @OEM_DPMI
; Copy initialized OVR_HPDA to its final destination.  This may destroy
; part of PGROUP in low DOS.  If NOWIN3 is present and MAX is loaded high,
; the addresses destroyed will be very low.
.8086
	REGSAVE <ax,bx,cx,si,di,es> ; Save

	mov	cx,HPDASEG	; Get HPDA segment
	jcxz	short @F	; Jump if none
DOT386 p
	mov	es,cx		; Address HPDA (short or full)
	assume	es:nothing	; Tell the assembler

	sub	di,di		; Starting offset
	lea	si,PGROUP:OVR_HPDA ; Initialized short HPDA in low DOS
	mov	cx,@OVR_HPDALEND ; Size of short HPDA in dwords
S16 rep movs	<es:[di].EDD,OVR_HPDA[si].EDD> ; Initialize HPDA

; Tell protected mode code of new HIMEM_CS and of HPDA.
	mov	bx,PGRSEG	; Get HIMEM_CS value
	mov	cx,HPDASEG	; Get segment of HPDA

	EMMOUT	@EMM2_HIMEM
@@:
.8086
	REGREST <es,di,si,cx,bx,ax> ; Restore
	assume	es:nothing	; Tell the assembler

endif				; IF @OEM_DPMI
if @OEM_DEBUG
; If any load modules use the full HPDA in their INIT_VIRT code,
; we may no longer have addressability to PGROUP addresses below
; XHI_ENDADDR after the following code.
	cmp	LOADCOUNT,0	; Are there any load modules to initialize?
	je	short @F	; Jump if not
DOT386 p
	CPD	'Calling INIT_VIRT,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	INIT_VIRT	; Call all virtual mode initializations
	jc	near ptr UGH_INIT ; Jump if something went wrong
@@:
endif				; IF @OEM_DEBUG
.8086
; If we're relocating the XBIOS data area, add its size into the
; memory size, include its size in the memory allocation chain,
; and move the data to the appropriate area
; Note that even if we're relocating the XBDA within low DOS, we're
; taking it out of DMAC's allocation and including it in ENDADDR.

; Note that I15_FLAG in low DOS may have been clobbered in INIT_VIRT
	mov	ds,PGRSEG	; Address PGROUP in high DOS
	assume	ds:PGROUP	; Tell the assembler

	test	I15_FLAG,@I15_XBREL ; Izit to be relocated?
	MJ z	INIT_EXIT	; Jump if not
DOT386 p
	REGSAVE <ax,cx,si,di,ds,es> ; Save for a moment

	CPD	'Relocating XBIOS,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	mov	cx,XBIOS_SIZ	; Get size of XBIOS data area in bytes
	mov	ax,cx		; Copy to convert

; Include in MAC entry

	push	ds		; Save

	mov	ds,PLAST_MAC.VSEG ; Get segment of last MAC
	assume	ds:nothing	; Tell the assembler about it

	shr	ax,4-0		; Convert from bytes to paras
	add	ds:[0].MAC_NPAR,ax ; Add into MAC entry

	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler

; Add into DOS memory size

; Note that SBIOSDATA in low DOS may have been clobbered by INIT_VIRT
	mov	ds,SBIOSDATA	; Address the BIOS data area
	assume	ds:BIOSDATA	; Tell the assembler about it

	push	ds		; Save

	shr	ax,10-4 	; Convert from paras to 1KB
	add	MEMORY_SIZE,ax	; Add back in the kilobytes

	les	di,XBIOS_DST	; Get XBIOS destin vector
	assume	es:nothing	; Tell the assembler about it

; Note that XBIOS_SRC in low DOS may have been clobbered by INIT_VIRT
	mov	ds,XPGRSEG	; Address PGROUP in high DOS
	assume	ds:PGROUP	; Tell the assembler

	lds	si,XBIOS_SRC	; Get XBIOS source vector
	assume	ds:nothing	; Tell the assembler about it

S16 rep movsb			; Move into place

	mov	ax,es		; Get destin segment
	mov	si,ds		; ... source ...

	pop	ds		; Restore
	assume	ds:BIOSDATA	; Tell the assembler about it

	mov	XBDA_SEG,ax	; Save as segment of XBIOS data area

; See if any of the interrupt vectors from 00h to 7Fh point into the XBIOS
; If so, relocate them.

	CPD	'Relocating XBIOS INTs,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	push	seg INTVEC	; Get segment of interrupt vectors
	pop	ds		; Address it
	assume	ds:INTVEC	; Tell the assembler about it

@INT_BEG equ	00h		; Starting interrupt #
@INT_END equ	7Fh		; Ending ...

	mov	cx,@INT_END-@INT_BEG+1 ; Get # interrupts to check
	mov	di,@INT_BEG*(type INT00_VEC) ; Initialize index into INT00_VEC
INIT_NEXTINT:
	cmp	di,30h*(type INT00_VEC) ; Izit at INT 30.4?
	je	short @F	; Jump if so (it's not a valid interrupt)

	cmp	si,INT00_VEC[di].VSEG ; Izit pointing into XBIOS?
	jne	short @F	; Jump if not

	CPD	'Relocating XBIOS INT(0:%DI),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	mov	INT00_VEC[di].VSEG,ax ; Relocate it
@@:
	add	di,type INT00_VEC ; Skip to next interrupt vector

	loop	INIT_NEXTINT	; Jump if more interrupts to check

	REGREST <es,ds,di,si,cx,ax> ; Restore
	assume	ds:PGROUP,es:nothing ; Tell the assembler about it
.8086
INIT_EXIT:
; If we're defining DOS stacks, initialize that area now
; and tell the code in extended memory about it

; Note that I15_FLAG in low DOS may have been clobbered in INIT_VIRT
	test	I15_FLAG,@I15_DSTK ; Izit present?
	jz	short @F	 ; Jump if not

	CPD	'Calling FILL_DSTKS,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	FILL_DSTKS	; Fill in DOS stacks
@@:

if @OEM_HIFILL
	REGSAVE <ax,es> 	; Save for a moment

	mov	es,PLAST_MAC.VSEG ; Get segment of last MAC
	assume	es:nothing	; Tell the assembler about it

	push	es:[0].MAC_NPAR ; Get value
	pop	PREV_LMAC_NPAR	; Save for comparison during INIT2X

	REGREST <es,ax> 	; Restore
	assume	es:nothing	; Tell the assembler
endif				; IF @OEM_HIFILL

	CPD	'Leaving INITX,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller
DOT386 p
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INITX	endp			; End INITX procedure
if @OEM_FLEXROM
	NPPROC	XLAT_VIDEO -- Translate FLEXed Video ROM
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translates a video BIOS that has been FLEXed.

Pass 2: Read in the video translation file.
	Restore information obtained from pass 1.
	Translate the C000 occurrences to B000.
	Pass 1 has previously happened in QMAX_ARG, just after the
	profile has been processed.

Note:	If there are any errors encountered while processing the video
	translation file, we can't abort MAX installation, its simply
	too late at this point.  All we can do is display an error
	message and trudge on.

|
	REGSAVE <ax,bx,cx,dx,fs> ; Save registers

	test	FLEXROM_FLAG,@FR_VGA ; Is VGASWAP active?
	jz	near ptr XLAT_VIDEO_EXIT ; Jump if not

; Find video entry (if it exists)

	xor	bx,bx		; Zero index into FlexROM table
@@:
	test	FLEXROM_TBL[bx].FLEX_FLAG,@FLEXFLAG_VGA ; Izit a video entry?
	jnz	short @F	; Jump if so

	add	bx,@FLEXROM_STRLEN ; point to next entry

	cmp	bx,FLEXROM_LEN	; More ROMs to process?
	jb	short @B	; Jump if more entries

	jmp	short XLAT_VIDEO_XVID ; None of the entries are video

; Read in video translation file

@@:
	CPD	'Reading XLAT (2),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	call	READ_FLEXFILE	; Read it in to memory
	jc	short XLAT_VIDEO_READ_ERR ; Jump if error

; Prep the video translation file

	mov	ax,READ_SEG	; Segment of XLAT program
	sub	ax,10h		; Skip back 10h paras to simulate PSP

	mov	fs,ax		; Adjusted segment of XLAT program
	assume	fs:nothing	; Tell the assembler about it

	mov	FLEXFILE_VEC.VSEG,fs ; Setup segment of dispatcher

	mov	ax,fs:[@XLAT_OFF].MAX_XLAT ; Get offset of dispatcher
	mov	FLEXFILE_VEC.VOFF,ax ; Set ...

; Restore flexfile variables

	REGSAVE <es>		; Save pointer to PGROUP

	mov	ax,seg XGROUP	; Address FLEXDATA...
	mov	es,ax		; ... via ES
	assume	es:XGROUP	; Tell the assembler about it

	lea	bx,FLEXDATA	; Address of our stored data
	mov	cx,FLEXDATA_CNT ; Number of bytes
	mov	dx,seg XGROUP	; Segment of FLEXDATA

	CPD	'Calling XLAT (Restore),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	mov	ah,@MAXLAT_RESTORE ; Restore variables to flexfile
	call	FLEXFILE_VEC	; Make function call to video translation file

	REGREST <es>		; Restore pointer to PGROUP
	assume	es:PGROUP	; Tell the assembler about it

	jc	short XLAT_VIDEO_XLAT_ERR ; Jump if error

; Preform video translation

	CPD	'Calling XLAT (Translate),  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	mov	al,1		; Make BIOS Read/Write
	EMMOUT @EMM2_ROMRW	; Alter ROM Read/Write State

	mov	ah,@MAXLAT_TRANSLATE ; Translate ROM to new address
	call	FLEXFILE_VEC	; Make function call to video translation file
	jc	short XLAT_VIDEO_XLAT_ERR ; Jump if error

	mov	al,0		; Make BIOS Read Only
	EMMOUT @EMM2_ROMRW	; Alter ROM Read/Write State

	jmp	short XLAT_VIDEO_EXIT ; Join common exit code

XLAT_VIDEO_XVID:
	REGSAVE <si>		; Save register

	mov	al,2		; Indicate Pass 2
	lea	si,YGROUP:MSG_FF_XVID1 ; YGROUP:SI ==> error code save area
	call	FMT_ERR_CODE	; Format the error code

	REGREST <si>		; Restore register

	push	offset YGROUP:MSG_FF_XVID ; Tell 'em the bad news

	jmp	short XLAT_VIDEO_ERR1 ; Join common error code

XLAT_VIDEO_READ_ERR:
	push	offset YGROUP:MSG_NOFLEXFILE_PASS2 ; Tell 'em the bad news

	jmp	short XLAT_VIDEO_ERR1 ; Join common error code

XLAT_VIDEO_XLAT_ERR:
	REGSAVE <si>		; Save register

	mov	al,ah		; Get the error code (MAXLAT function number)
	lea	si,YGROUP:MSG_FF_ERR1 ; YGROUP:SI ==> error code save area
	call	FMT_ERR_CODE	; Format the error code

	REGREST <si>		; Restore register

	push	offset YGROUP:MSG_FF_ERR ; Tell 'em the bad news
;;;;;;; jmp	short XLAT_VIDEO_ERR1 ; Join common error code

XLAT_VIDEO_ERR1:
	call	YMSGOUT2	; Display YGROUP message

	push	offset YGROUP:MSG_PRESS ; Address of 'Press any key'
	call	YMSGOUT2	; Display YGROUP message

	call	FKEYWAIT	; Give 'em a chance to read message
				; Return with key in AX

XLAT_VIDEO_EXIT:
	REGREST <fs,dx,cx,bx,ax> ; Restore register
	assume	fs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XLAT_VIDEO endp 		; End XLAT_VIDEO procedure
endif				; IF @OEM_FLEXROM
if @OEM_HIFILL
	NPPROC	GET_MACINFO -- Save memory allocation strategy
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Use DOS function 58 subfunction 0 to get current memory allocation
strategy and save it away, since we'll control all memory allocation.

|

	REGSAVE <eax,bx,ds,es>	; Save

	push	seg JGROUP	; Prepare to address JGROUP data
	pop	ds		; Address it
	assume	ds:JGROUP	; Tell the assembler

; Save current PSP to determine when we're done with DEVICE= statements.
	DOSCALL @GETPS0 	; Get current PSP in BX
	mov	TEMP_PSP,bx	; Save for later comparison

; Get current memory allocation strategy.  This should normally fail, but
; we'll try to be fair about it.
	mov	al,0		; Subfunction 0: Get current allocation strategy
	DOSCALL @MACALG 	; Return current strategy in BX
	jc	short @F	; Jump if not hooked up yet

	mov	MAC_STRA,ax	; Save current strategy gotten from DOS
@@:
; If it's DOS 5, we need to get the addresses of the link state flag
; and link segment.  MEM does this by adding the constants 89h and
; 8Ch to the list of lists segment.
	cmp	DOSVER,0500h	; Izit DOS 5?
	jb	short GET_MACEXIT ; Jump if not

	DOSCALL @GETLST 	; ES:BX ==> list of lists
	assume	es:nothing	; Tell the assembler

	sub	eax,eax 	; Clear high order word
	mov	ax,es		; Get segment
	shl	eax,4-0 	; Convert paras to bytes
	add	LaLINKFLG,eax	; Add constant 89h
	add	LaLINKSEG,eax	; Add constant 8Ch
GET_MACEXIT:
	REGREST <es,ds,bx,eax>	; Restore
	assume	ds:PGROUP,es:PGROUP ; Tell the assembler

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_MACINFO endp		; End GET_MACINFO procedure
endif				; IF @OEM_HIFILL
	NPPROC	CHECK_EISADMA -- Clear high order bytes of EISA DMA controller
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we're on an EISA system and supporting EISA DMA (NOEISADMA not
specified) we need to clear the high order bytes of all extended
DMA registers in case we're on one of those AMI EISA systems that
does a half-assed job of setting up EISA DMA.

It's debatable whether such systems have properly working DMA
chipsets, since the default behavior should be to return 0.
When we rely on this behavior, we get burnt.

|

	REGSAVE <ax,cx,dx,si,ds> ; Save

	test	CM2_FLAG,@CM2_EISA_DMA ; Is EISA DMA support enabled?
	jz	short CED_EXIT	; Jump if not

	pushf			; Save IF

	cld			; Ensure string ops forwardly

	push	seg XGROUP	; Prepare to address XGROUP data
	pop	ds		; Address it
	assume	ds:XGROUP	; Tell the assembler

	mov	cx,@EISAREGCNT	; Get number of registers to clear
	lea	si,EISAREGS	; DS:SI ==> list of 04xxh addresses to clear
	sub	dx,dx		; Clear value to send out
	mov	ah,04h		; Set high byte of port address

	cli			; Nobody move
@@:
	lods	EISAREGS[si]	; AX = port address
	xchg	ax,dx		; DX = address, AL = 0
	out	dx,al		; Clear register
	xchg	ax,dx		; Restore high byte of port address
	loop	@B		; Go around again

	popf			; Restore interrupt enabled state
CED_EXIT:
	REGREST <ds,si,dx,cx,ax> ; Restore
	assume	ds:PGROUP	; Tell the assembler

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EISADMA endp		; End CHECK_EISADMA procedure

XCODE	ends			; End XCODE segment


NCODE	segment use16 byte public 'ncode' ; Start NCODE segment
	assume	cs:PGROUP

	public	@QMAX_INI_NCODE
@QMAX_INI_NCODE:		; Mark module start in .MAP file

	public	INIT
INIT	label	far
	jmp	INITX		; Join code in XGROUP

if @OEM_EMS
	public	INIT2
INIT2	label	far
	jmp	INIT2X		; Join code in XGROUP

	public	DEV_STR2
DEV_STR2 label	far
	jmp	DEV_STR2X	; Join code in XGROUP
endif				; IF @OEM_EMS

NCODE	ends			; End NCODE segment

	MEND			; End QMAX_INI module

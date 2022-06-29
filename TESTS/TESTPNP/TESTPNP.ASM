	title	TESTPnP -- Test Plug 'n Play
	page	58,122
	name	TESTPnP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1995-7 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'

Program derived from:  None.

Original code by:  Bob Smith, September, 1995.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include DOSCALL.INC
	include ASCII.INC
	include PTR.INC
	include DPMI.INC
	include 386.INC
	include IOCTL.INC
	include BITFLAGS.INC
	include CPUFLAGS.INC
	include PNP.INC
	include OPEN.INC
	include ALLMEM.INC
	include VCPI.INC
	include OPCODES.INC

	include TESTPNP.INC
	include QMAX_CTL.INC
	include QMAX_VCP.INC
.list

PGROUP	group	STACK,CODE,DATA,DTAIL
PnPGRP	group	PnPSEG


ERRCHK	macro	TXT
	local	L1,L2

	cmp	ax,@PnP_SUCCESS ; Did it work?
	je	short L1	; Jump if so

	REGSAVE <ax,dx> 	; Save for a moment

	DOSCALL @STROUT,L2	; Display error message

	REGREST <dx,ax> 	; Restore

DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:PGROUP

L2	db	TXT		; Error message
	db	CR,LF,EOS

DATA	ends
L1:
	endm			; ERRCHK

PnPSEG	segment use16 at 0
	assume	ds:PnPGRP

	public	PnPSTR
PnPSTR	PnP_STR <>		; Dummy struc

PnPSEG	ends


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	segment use16 byte stack 'prog' ; Start STACK segment
STACK	ends			; End STACK segment


DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:PGROUP

BIT_STR struc

BIT_MSK dw	?		; Bit mask
BIT_WID dw	?		; Bit mask width
BIT_PTR dw	?		; Ptr to text

BIT_STR ends

BIT_MAC macro	TXT
	BIT_STR <mask $&TXT, $&TXT, PGROUP:PTR_&TXT>
	endm			; BIT_MAC


	public	PMSTK,PMSTKZ
PMSTK	dw	0FFh dup (?)	; Protected mode stack
PMSTKZ	dw	0		; End of ...

	public	OLDINT67
OLDINT67 dd	?		; Previous Int 67h handler

	public	HEXTAB
HEXTAB	db	'0123456789ABCDEF' ; Binary to ASCII translate table

	public	DPMI_LDTE
DPMI_LDTE DESC_STR <>		; DTE for DPMI selector

	public	DPMIDRV_VEC
DPMIDRV_VEC dd	?		; Seg:Off of DPMI handler

	public	CON64K,CON1M
CON64K	dd	  64*1024	; Constant 64K
CON1M	dd	1024*1024	; ...	    1M

	public	LaSWAT
LaSWAT	dd	-1		; Linear address of SWAT's code/data (-1=none)

	public	LCLGDT
LCLGDT	XDTE_STR <>		; Protected mode DTE structure

IDT_MAC macro	NCNT
	IDT_STR <PGROUP:INTPROC&NCNT,DTE_CS,,CPL0_INTR3 or CPL3,0>
	endm			; IDT_MAC

	public	LCLIDT
LCLIDT	label	qword		; Interrupt descriptor table

CNT	=	0
.xlist
	rept	100h		; Define all interrupts

	IDT_MAC %CNT
CNT	=	CNT+1

	endm			; REPT 100h
.list
	public	LCLIDT_LEN
LCLIDT_LEN equ	$-LCLIDT	; Length of the IDT

	public	LaCODE,LaDATA,LaCR3,LaPTE,PaCR3,NEXTPTE
LaCODE	dd	?		; Linear address of our code segment
LaDATA	dd	?		; ...			data
LaCR3	dd	?		; ...			CR3
LaPTE	dd	?		; ...			PTEs
PaCR3	dd	?		; Physical		CR3
NEXTPTE dd	?		; Offset of next available PTE in PDT

	public	EPMTAB
EPMTAB	EPM_STR <>		; Enter Protected Mode structure

	public	LCLTSS
LCLTSS	TSS_STR <>		; Local TSS

	public	PnP_VEC,PnP_DS
PnP_VEC dd	?		; Entry point to PnP BIOS
PnP_DS	dw	?,?		; Data segment/selector for PnP BIOS

	public	OffNVStoragePTE
OffNVStoragePTE dd ?		; Offset in LaPTE of NV Storage PTEs

	public	OffPnP_RMVEC,OffPnP_PMCS,OffPnP_PMOFF
OffPnP_RMVEC dd PnP_RMVEC	; Offset to PnP_RMVEC in PnP_STR or PnP2_STR
OffPnP_PMCS  dd PnP_PMCS	; ...	    PnP_PMCS  ...
OffPnP_PMOFF dd PnP_PMOFF	; ...	    PnP_PMOFF ...

	public	PMI_FVEC
PMI_FVEC df	?		; Sel:Off to PMI code

	public	SEL_DATA
SEL_DATA dw	DTE_DS		; Data selector (PGROUP)

	public	CODESEG,DATASEG
CODESEG dw	?		; Code segment paragraph
DATASEG dw	?		; Data ...

	public	PMONSTK_FVEC
PMONSTK_FVEC label fword
	dd	?		; Stack ending offset
	dw	DTE_SS		; Stack selector

	public	HPDASEG
HPDASEG dw	?		; Segment of the HPDA (if DPMI host)

	public	SEL_4GB
SEL_4GB dw	DTE_4GB 	; 4GB  selector (AGROUP)

	public	LCL_FLAG
LCL_FLAG dw	0		; Local flags
@LCL_DPMI equ	8000h		; In DPMI mode
@LCL_VCPI equ	4000h		; In VCPI mode
@LCL_SWAT equ	2000h		; SWAT is present
@LCL_PRES equ	1000h		; Presence check only
@LCL_TESTRMVM equ 0800h 	; Check for functions in RM/VM
@LCL_TESTVCPI equ 0400h 	; Check for functions in VCPI (if available)
@LCL_TESTDPMI equ 0200h 	; Check for functions in DPMI (if available)
@LCL_TESTALL equ @LCL_TESTRMVM or @LCL_TESTVCPI or @LCL_TESTDPMI ; All modes

	public	PnP_SEG
PnP_SEG dw	?		; Segment of PnP struc

	public	PTAIL
PTAIL	dw	PGROUP:ZTAIL	; Ending offset

	public	PnP_NodeSize,PnP_NumNodes,PnP_Node,PnP_CTL
	public	PnP_PRODID,PnP_PRODNO,PnP_Message
	public	PnP_MinESCDSize,PnP_ESCDSize,PnP_NVStorageBase
	public	PnP_APMSize,PnP_Version
	public	PnP_IPLDevCnt,PnP_IPLMaxCnt,PnP_IPLStrSize
	public	PnP_BCVDevCnt,PnP_BCVMaxCnt,PnP_BCVStrSize
	public	PnP_IPLDevBoot,PnP_Boot1st
PnP_NodeSize dw ?		; PnP size of largest device node
PnP_NumNodes db ?,?		; PnP # nodes the BIOS returns
PnP_Node     dw ?		; PnP node # for Get/Set System Device Nodes
PnP_CTL      dw ?		; PnP control flags
PnP_PRODID   dd ?		; Product ID
PnP_PRODNO   dd ?		; ...	  #
PnP_Message  dw ?		; Event message
PnP_MinESCDSize dw ?		; Minimum buffer byte size for writing to NVS
PnP_ESCDSize dw ?		; Size allocated for the ESCD within NV storage block
PnP_NVStorageBase dd ?		; NV Storage base address
PnP_APMSize  dw ?		; APM buffer size
PnP_Version  dw ?		; BIOS Boot Spec Version
PnP_IPLDevCnt  dw ?		; BBS IPL Device count
PnP_IPLMaxCnt  dw ?		; BBS IPL Maximum Device count
PnP_IPLStrSize dw ?		; BBS IPL Struc Size
PnP_BCVDevCnt  dw ?		; BBS BCV Device count
PnP_BCVMaxCnt  dw ?		; BBS BCV Maximum Device count
PnP_BCVStrSize dw ?		; BBS BCV Struc Size
PnP_IPLDevBoot dw ?		; IPL Device from Last Boot
PnP_Boot1st    dw ?		; Boot First device

	public	ENM_TAB
ENM_TAB dw	PGROUP:MSG_ENM00 ; ENM flags 00
	dw	PGROUP:MSG_ENM01 ; ...	     01
	dw	PGROUP:MSG_ENM10 ; ...	     10
	dw	PGROUP:MSG_ENM11 ; ...	     11

	public	INFO_CTL,INFO,INFOSIZE
	include QMAXINFO.INC
	db	?		; Force even alignment for INFO_STR
INFO_CTL db	?		; IOCTL type
INFO	INFO_STR <>
INFOSIZE equ	size INFO_STR

	public	VCPIDBG_VER
VCPIDBG_VER dw	?		; VCPI debugger interface version number

	public	PORT67
PORT67	equ	INFO.INFO_P67	; 14 = I/O port for INT 67h communications

	public	VMINTFN
VMINTFN dw	?		; Save area for VM interrupt function

	public	IBV0,IBV0Z,IBV1,IBV1Z
IBV0	db	08h		; Master PIC base
IBV0Z	db	08h+8		; ...		  top
IBV1	db	70h		; Slave ...
IBV1Z	db	70h+8		; ...		  top

	public	MAXNAME
MAXNAME db	'386MAX$$',0    ; Device name for 386MAX/BlueMAX

	public	EMMNAME
EMMNAME db	'EMMXXXX0',0    ; EMM device name

	public	EMMNAM2,EMMNAM3,EMMNAM4,EMMNAM5
EMMNAM2 db	'$MMXXXX0',0    ; EMM386.EXE device name if NOEMS
EMMNAM3 db	'EMMXXXQ0',0    ; QEMM386.SYS device name if NOEMS
EMMNAM4 db	'EMMQXXX0',0    ; RM386.EXE device name if NOFRAME
EMMNAM5 db	'QMMXXXX0',0    ; 386MAX.SYS device name if EMS=0

	public	SWTNAME
SWTNAME db	'386SWAT$',0    ; 386SWAT.SYS device name

	public	ERRCODE
ERRCODE db	0		; Return code

	public	MSG_COPY
MSG_COPY db	"TESTPnP  -- Version 1.01 -- A Plug 'n Play Test Program",CR,LF
	db	"   (C) Copyright 1995-7 Qualitas, Inc.  All rights reserved.",CR,LF,EOS

	public	MSG_HELP
MSG_HELP db	'Syntax:  TESTPNP [args]',CR,LF
	db	'  where [args] may be zero or more of',CR,LF
	db	'  /p = Presence check only',CR,LF
	db	'  /r = Test RM/VM',CR,LF
	db	'  /v = Test VCPI (if available)',CR,LF
	db	'  /d = Test DPMI (if available)',CR,LF
	db	'  If the none of the above flags are present,',CR,LF
	db	'  all available modes are tested.',CR,LF
	db	EOS

	public	MSG_SEG
MSG_SEG db	"A Plug 'n Play BIOS structure is present at "
MSG_SEG1 db	"____:0 and is a length "
MSG_SEG2 db	"__h struc.",CR,LF,EOS

	public	MSG_NOPnP
MSG_NOPnP db	"This is not a Plug 'n Play BIOS.",CR,LF,EOS

	public	MSG_VM,MSG_DPMI,MSG_VCPI
MSG_VM	 db	'ออ> Running as VM client.',CR,LF,EOS
MSG_DPMI db	'ออ> Running as DPMI client.',CR,LF,EOS
MSG_VCPI db	'ออ> Running as VCPI client.',CR,LF,EOS

	public	MSG_ENM00,MSG_ENM01,MSG_ENM10,MSG_ENM11
MSG_ENM00 db	'Event notification is not supported.',CR,LF,EOS
MSG_ENM01 db	'Event notification is handled through polling.',CR,LF,EOS
MSG_ENM10 db	'Unknown Event Notification flag = 10b.',CR,LF,EOS
MSG_ENM11 db	'Unknown Event Notification flag = 11b.',CR,LF,EOS

	public	MSG_ENF
MSG_ENF db	'The Event Notification Flag Physical address is '
MSG_ENF1 db	'________h.',CR,LF,EOS

	public	MSG_RMVEC
MSG_RMVEC db	'The RM entry point is '
MSG_RMVECSEG db '____:'
MSG_RMVECOFF db '____.',CR,LF,EOS

	public	MSG_PMOFF
MSG_PMOFF db	'The PM entry point offset is '
MSG_PMOFF1 db	'____h.',CR,LF,EOS

	public	MSG_PMCS
MSG_PMCS db	'The PM code segment base address is '
MSG_PMCS1 db	'________h.',CR,LF,EOS

	public	MSG_RMDS
MSG_RMDS db	'The RM data segment is '
MSG_RMDS1 db	'____h.',CR,LF,EOS

	public	MSG_PMDS
MSG_PMDS db	'The PM data segment base address is '
MSG_PMDS1 db	'________h.',CR,LF,EOS

	public	MSG_OEM
MSG_OEM db	'The OEM device identifier is '
MSG_OEM1 db	'____'
	org	$-1		; Back up by one because the product ID is
				; only three bytes long
MSG_OEM2 db	'____.',CR,LF,EOS

	public	MSG_DEVTTL
MSG_DEVTTL db	'-----------------------------------------',CR,LF,EOS

	public	MSG_NODE
MSG_NODE db	'Device node = '
MSG_NODE1 db	'__h.',CR,LF,EOS

	public	MSG_PID
MSG_PID db	'The device product identifier is '
MSG_PID1 db	'____'
	org	$-1		; Back up by one because the product ID is
				; only three bytes long
MSG_PID2 db	'____.',CR,LF,EOS

	public	MSG_TYPE
MSG_TYPE db	'The type code is '
MSG_TYPE0 db	'__h '
MSG_TYPE1 db	'__h '
MSG_TYPE2 db	'__h.',CR,LF,EOS

	align	2
	public	DEV_BITTAB
DEV_BITTAB label tbyte
	BIT_MAC PnP_DEVFLAG_CFG
	BIT_MAC PnP_DEVFLAG_REM
	BIT_MAC PnP_DEVFLAG_DOCK
	BIT_MAC PnP_DEVFLAG_IPL
	BIT_MAC PnP_DEVFLAG_INP
	BIT_MAC PnP_DEVFLAG_OUT
	BIT_MAC PnP_DEVFLAG_XCFG
	BIT_MAC PnP_DEVFLAG_XDIS
DEV_BITTAB_LEN equ ($-DEV_BITTAB)/(type BIT_STR) ; # entries

PTR_PnP_DEVFLAG_CFG  dw PGROUP:MSG_DEV_CFG00
		     dw PGROUP:MSG_DEV_CFG01
		     dw PGROUP:MSG_DEV_CFG10
		     dw PGROUP:MSG_DEV_CFG11

PTR_PnP_DEVFLAG_REM  dw PGROUP:MSG_DEV_REM0
		     dw PGROUP:MSG_DEV_REM1

PTR_PnP_DEVFLAG_DOCK dw PGROUP:MSG_DEV_DOCK0
		     dw PGROUP:MSG_DEV_DOCK1

PTR_PnP_DEVFLAG_IPL  dw PGROUP:MSG_DEV_IPL0
		     dw PGROUP:MSG_DEV_IPL1

PTR_PnP_DEVFLAG_INP  dw PGROUP:MSG_DEV_INP0
		     dw PGROUP:MSG_DEV_INP1

PTR_PnP_DEVFLAG_OUT  dw PGROUP:MSG_DEV_OUT0
		     dw PGROUP:MSG_DEV_OUT1

PTR_PnP_DEVFLAG_XCFG dw PGROUP:MSG_DEV_XCFG0
		     dw PGROUP:MSG_DEV_XCFG1

PTR_PnP_DEVFLAG_XDIS dw PGROUP:MSG_DEV_XDIS0
		     dw PGROUP:MSG_DEV_XDIS1

MSG_DEV_CFG00  db '   Device can be configured for next boot (static)',CR,LF,EOS
MSG_DEV_CFG01  db '   Device can be configured at runtime (dynamically)',CR,LF,EOS
MSG_DEV_CFG10  db '   (Reserved)',CR,LF,EOS
MSG_DEV_CFG11  db '   Device can be configured at runtime (dynamically) only',CR,LF,EOS

MSG_DEV_REM1   db '   Device is a removable system device',CR,LF
MSG_DEV_REM0   db EOS

MSG_DEV_DOCK1  db '   Device is a docking station device',CR,LF
MSG_DEV_DOCK0  db EOS

MSG_DEV_IPL1   db '   Device is capable of being primary IPL device',CR,LF
MSG_DEV_IPL0   db EOS

MSG_DEV_INP1   db '   Device is capable of being primary input device',CR,LF
MSG_DEV_INP0   db EOS

MSG_DEV_OUT1   db '   Device is capable of being primary output device',CR,LF
MSG_DEV_OUT0   db EOS

MSG_DEV_XCFG0  db '   Device is configurable',CR,LF ; Note reversed sense
MSG_DEV_XCFG1  db EOS

MSG_DEV_XDIS1  db '   Device can be disabled',CR,LF
MSG_DEV_XDIS0  db EOS


	align	2
	public	RES_LEN
RES_LEN dw	?		; Length of resource data

	align	2
	public	SRES_NAME_TAB
SRES_NAME_TAB dw PGROUP:SRES_NAME_RES00 ; 0
	      dw PGROUP:SRES_NAME_VER	; 1
	      dw PGROUP:SRES_NAME_LID	; 2
	      dw PGROUP:SRES_NAME_CID	; 3
	      dw PGROUP:SRES_NAME_IRQ	; 4
	      dw PGROUP:SRES_NAME_DMA	; 5
	      dw PGROUP:SRES_NAME_SDF	; 6
	      dw PGROUP:SRES_NAME_EDF	; 7
	      dw PGROUP:SRES_NAME_IO	; 8
	      dw PGROUP:SRES_NAME_IOF	; 9
	      dw PGROUP:SRES_NAME_RES0A ; A
	      dw PGROUP:SRES_NAME_RES0B ; B
	      dw PGROUP:SRES_NAME_RES0C ; C
	      dw PGROUP:SRES_NAME_RES0D ; D
	      dw PGROUP:SRES_NAME_VEN	; E
	      dw PGROUP:SRES_NAME_EOT	; F

SRES_NAME_RES00 db '(Small Resource Reserved - 00)',CR,LF,EOS
SRES_NAME_VER	db 'PnP Version #',CR,LF,EOS
SRES_NAME_LID	db 'Logical device ID',CR,LF,EOS
SRES_NAME_CID	db 'Compatible device ID',CR,LF,EOS
SRES_NAME_IRQ	db 'IRQ format',CR,LF,EOS
SRES_NAME_DMA	db 'DMA format',CR,LF,EOS
SRES_NAME_SDF	db 'Start dependent function',CR,LF,EOS
SRES_NAME_EDF	db 'End dependent function',CR,LF,EOS
SRES_NAME_IO	db 'I/O port descriptor',CR,LF,EOS
SRES_NAME_IOF	db 'Fixed location I/O port descriptor',CR,LF,EOS
SRES_NAME_RES0A db '(Small Resource Reserved - 0A)',CR,LF,EOS
SRES_NAME_RES0B db '(Small Resource Reserved - 0B)',CR,LF,EOS
SRES_NAME_RES0C db '(Small Resource Reserved - 0C)',CR,LF,EOS
SRES_NAME_RES0D db '(Small Resource Reserved - 0D)',CR,LF,EOS
SRES_NAME_VEN	db 'Vendor defined',CR,LF,EOS
SRES_NAME_EOT	db 'End tag',CR,LF,EOS

	align	2
	public	SRES_NAME_ACT
SRES_NAME_ACT dw PGROUP:SRES_ACT_RES00 ; 0
	      dw PGROUP:SRES_ACT_VER   ; 1
	      dw PGROUP:SRES_ACT_LID   ; 2
	      dw PGROUP:SRES_ACT_CID   ; 3
	      dw PGROUP:SRES_ACT_IRQ   ; 4
	      dw PGROUP:SRES_ACT_DMA   ; 5
	      dw PGROUP:SRES_ACT_SDF   ; 6
	      dw PGROUP:SRES_ACT_EDF   ; 7
	      dw PGROUP:SRES_ACT_IO    ; 8
	      dw PGROUP:SRES_ACT_IOF   ; 9
	      dw PGROUP:SRES_ACT_RES0A ; A
	      dw PGROUP:SRES_ACT_RES0B ; B
	      dw PGROUP:SRES_ACT_RES0C ; C
	      dw PGROUP:SRES_ACT_RES0D ; D
	      dw PGROUP:SRES_ACT_VEN   ; E
	      dw PGROUP:SRES_ACT_EOT   ; F

MSG_SRES_VER   db '   '
MSG_SRES_VER1  db '_.'
MSG_SRES_VER2  db '_, vendor-specific version # '
MSG_SRES_VER3  db '__.',CR,LF,EOS

MSG_SRES_IO16  db '   16 bits',EOS
MSG_SRES_IO10  db '   10 bits',EOS
MSG_SRES_IORNG	db ', min addr = '
MSG_SRES_IORNG1 db '____, max addr = '
MSG_SRES_IORNG2 db '____, align = '
MSG_SRES_IORNG3 db '__, len = '
MSG_SRES_IORNG4 db '__',CR,LF,EOS

MSG_SRES_IOFRNG  db '   addr = '
MSG_SRES_IOFRNG1 db '____, len = '
MSG_SRES_IOFRNG2 db '__',CR,LF,EOS

	align	2
	public	SRES_IRQTAB
SRES_IRQTAB dw	PGROUP:MSG_SRES_IRQ0  ; 0
	    dw	PGROUP:MSG_SRES_IRQ1  ; 1
	    dw	PGROUP:MSG_SRES_IRQ2  ; 2
	    dw	PGROUP:MSG_SRES_IRQ3  ; 3
	    dw	PGROUP:MSG_SRES_IRQ4  ; 4
	    dw	PGROUP:MSG_SRES_IRQ5  ; 5
	    dw	PGROUP:MSG_SRES_IRQ6  ; 6
	    dw	PGROUP:MSG_SRES_IRQ7  ; 7
	    dw	PGROUP:MSG_SRES_IRQ8  ; 8
	    dw	PGROUP:MSG_SRES_IRQ9  ; 9
	    dw	PGROUP:MSG_SRES_IRQ10 ; 10
	    dw	PGROUP:MSG_SRES_IRQ11 ; 11
	    dw	PGROUP:MSG_SRES_IRQ12 ; 12
	    dw	PGROUP:MSG_SRES_IRQ13 ; 13
	    dw	PGROUP:MSG_SRES_IRQ14 ; 14
	    dw	PGROUP:MSG_SRES_IRQ15 ; 15

MSG_SRES_IRQHDR db '   IRQ # ',EOS

MSG_SRES_IRQ0  db '0 ',EOS
MSG_SRES_IRQ1  db '1 ',EOS
MSG_SRES_IRQ2  db '2 ',EOS
MSG_SRES_IRQ3  db '3 ',EOS
MSG_SRES_IRQ4  db '4 ',EOS
MSG_SRES_IRQ5  db '5 ',EOS
MSG_SRES_IRQ6  db '6 ',EOS
MSG_SRES_IRQ7  db '7 ',EOS
MSG_SRES_IRQ8  db '8 ',EOS
MSG_SRES_IRQ9  db '9 ',EOS
MSG_SRES_IRQ10 db '10 ',EOS
MSG_SRES_IRQ11 db '11 ',EOS
MSG_SRES_IRQ12 db '12 ',EOS
MSG_SRES_IRQ13 db '13 ',EOS
MSG_SRES_IRQ14 db '14 ',EOS
MSG_SRES_IRQ15 db '15 ',EOS

	align	2
	public	IRQ_BITTAB
IRQ_BITTAB label tbyte
	BIT_MAC PnP_IRQ_LOLVL
	BIT_MAC PnP_IRQ_HILVL
	BIT_MAC PnP_IRQ_LOEDG
	BIT_MAC PnP_IRQ_HIEDG
IRQ_BITTAB_LEN equ ($-IRQ_BITTAB)/(type BIT_STR) ; # entries

PTR_PnP_IRQ_LOLVL dw PGROUP:MSG_IRQ_LOLVL0
		  dw PGROUP:MSG_IRQ_LOLVL1

PTR_PnP_IRQ_HILVL dw PGROUP:MSG_IRQ_HILVL0
		  dw PGROUP:MSG_IRQ_HILVL1

PTR_PnP_IRQ_LOEDG dw PGROUP:MSG_IRQ_LOEDG0
		  dw PGROUP:MSG_IRQ_LOEDG1

PTR_PnP_IRQ_HIEDG dw PGROUP:MSG_IRQ_HIEDG0
		  dw PGROUP:MSG_IRQ_HIEDG1

MSG_IRQ_LOLVL1 db '   Low true level sensitive',CR,LF
MSG_IRQ_LOLVL0 db EOS

MSG_IRQ_HILVL1 db '   High true level sensitive',CR,LF
MSG_IRQ_HILVL0 db EOS

MSG_IRQ_LOEDG1 db '   Low true edge sensitive',CR,LF
MSG_IRQ_LOEDG0 db EOS

MSG_IRQ_HIEDG1 db '   High true edge sensitive',CR,LF
MSG_IRQ_HIEDG0 db EOS


	align	2
	public	SRES_DMATAB
SRES_DMATAB dw	PGROUP:MSG_SRES_IRQ0  ; 0
	    dw	PGROUP:MSG_SRES_IRQ1  ; 1
	    dw	PGROUP:MSG_SRES_IRQ2  ; 2
	    dw	PGROUP:MSG_SRES_IRQ3  ; 3
	    dw	PGROUP:MSG_SRES_IRQ4  ; 4
	    dw	PGROUP:MSG_SRES_IRQ5  ; 5
	    dw	PGROUP:MSG_SRES_IRQ6  ; 6
	    dw	PGROUP:MSG_SRES_IRQ7  ; 7

MSG_SRES_DMAHDR db '   DMA Channel # ',EOS

	align	2
	public	DMA_BITTAB
DMA_BITTAB label tbyte
	BIT_MAC PnP_DMA_CHAN
	BIT_MAC PnP_DMA_WMODE
	BIT_MAC PnP_DMA_BMODE
	BIT_MAC PnP_DMA_BUSM
	BIT_MAC PnP_DMA_TRANS
DMA_BITTAB_LEN equ ($-DMA_BITTAB)/(type BIT_STR) ; # entries

PTR_PnP_DMA_CHAN  dw PGROUP:MSG_DMA_CHAN00
		  dw PGROUP:MSG_DMA_CHAN01
		  dw PGROUP:MSG_DMA_CHAN10
		  dw PGROUP:MSG_DMA_CHAN11

PTR_PnP_DMA_WMODE dw PGROUP:MSG_DMA_WMODE0
		  dw PGROUP:MSG_DMA_WMODE1

PTR_PnP_DMA_BMODE dw PGROUP:MSG_DMA_BMODE0
		  dw PGROUP:MSG_DMA_BMODE1

PTR_PnP_DMA_BUSM  dw PGROUP:MSG_DMA_BUSM0
		  dw PGROUP:MSG_DMA_BUSM1

PTR_PnP_DMA_TRANS dw PGROUP:MSG_DMA_TRANS00
		  dw PGROUP:MSG_DMA_TRANS01
		  dw PGROUP:MSG_DMA_TRANS10
		  dw PGROUP:MSG_DMA_TRANS11

MSG_DMA_CHAN00 db '   Compatibility mode',CR,LF,EOS
MSG_DMA_CHAN01 db '   Type A DMA (EISA)',CR,LF,EOS
MSG_DMA_CHAN10 db '   Type D DMA',CR,LF,EOS
MSG_DMA_CHAN11 db '   Type F DMA',CR,LF,EOS

MSG_DMA_WMODE1 db '   DMA may execute in count word mode',CR,LF
MSG_DMA_WMODE0 db EOS

MSG_DMA_BMODE1 db '   DMA may execute in count byte mode',CR,LF
MSG_DMA_BMODE0 db EOS

MSG_DMA_BUSM1  db '   Logical device is a bus master',CR,LF
MSG_DMA_BUSM0  db EOS

MSG_DMA_TRANS00 db '   8-bit only',CR,LF,EOS
MSG_DMA_TRANS01 db '   8- and 16-bit',CR,LF,EOS
MSG_DMA_TRANS10 db '   16-bit only',CR,LF,EOS
MSG_DMA_TRANS11 db '   (Reserved)',CR,LF,EOS


MSG_SRES_LID  db '   '
MSG_SRES_LID1 db '____'
	org	$-1		; Back up by one because the ID is
				; only three bytes long
MSG_SRES_LID2 db '____',CR,LF,EOS

MSG_SRES_LIDFLAG db  '   Flags = '
MSG_SRES_LIDFLAG1 db '____',CR,LF,EOS

MSG_SRES_CID  db '   '
MSG_SRES_CID1 db '____'
	org	$-1		; Back up by one because the ID is
				; only three bytes long
MSG_SRES_CID2 db '____',CR,LF,EOS

	align	2
	public	PTR_SDF_TAB
PTR_SDF_TAB label word
	dw	PGROUP:MSG_SDF_GOOD
	dw	PGROUP:MSG_SDF_OK
	dw	PGROUP:MSG_SDF_SOSO
	dw	PGROUP:MSG_SDF_RES

@SDF_RES equ	3		; Reserved priority configurations

MSG_SDF_GOOD db '   Good configuration -- highest priority and preferred',CR,LF,EOS
MSG_SDF_OK   db '   Acceptable configuration -- lower priority, but acceptable',CR,LF,EOS
MSG_SDF_SOSO db '   Sub-optimal configuration -- functional, but not optimal',CR,LF,EOS
MSG_SDF_RES  db '   (Reserved Priority)',CR,LF,EOS

MSG_SRES_EOT  db '   Checksum = '
MSG_SRES_EOT1 db '__',CR,LF,EOS

MSG_RES_DATAHDR db '   Unknown data = ',EOS
MSG_RES_DATA db '__ ',EOS
MSG_CRLF db	CR,LF,EOS

	align	2
	public	LRES_NAME_TAB
LRES_NAME_TAB dw PGROUP:LRES_NAME_RES  ; 0
	      dw PGROUP:LRES_NAME_M16  ; 1
	      dw PGROUP:LRES_NAME_IDA  ; 2
	      dw PGROUP:LRES_NAME_IDU  ; 3
	      dw PGROUP:LRES_NAME_VEN  ; 4
	      dw PGROUP:LRES_NAME_M32  ; 5
	      dw PGROUP:LRES_NAME_M32F ; 6
	      dw PGROUP:LRES_NAME_MAX  ; 7

LRES_NAME_RES  db '(Large Resource Reserved - 00)',CR,LF,EOS
LRES_NAME_M16  db '16-bit memory range descriptor',CR,LF,EOS
LRES_NAME_IDA  db 'Identifier string (ANSI)',CR,LF,EOS
LRES_NAME_IDU  db 'Identifier string (Unicode)',CR,LF,EOS
LRES_NAME_VEN  db 'Vendor defined',CR,LF,EOS
LRES_NAME_M32  db '32-bit memory range descriptor',CR,LF,EOS
LRES_NAME_M32F db '32-bit fixed location memory range descriptor',CR,LF,EOS
LRES_NAME_MAX  db 'Exceeds maximum defined value',CR,LF,EOS

	align	2
	public	LRES_NAME_ACT
LRES_NAME_ACT dw PGROUP:LRES_ACT_RES  ; 0
	      dw PGROUP:LRES_ACT_M16  ; 1
	      dw PGROUP:LRES_ACT_IDA  ; 2
	      dw PGROUP:LRES_ACT_IDU  ; 3
	      dw PGROUP:LRES_ACT_VEN  ; 4
	      dw PGROUP:LRES_ACT_M32  ; 5
	      dw PGROUP:LRES_ACT_M32F ; 6
	      dw PGROUP:LRES_ACT_MAX  ; 7

	align	2
	public	M32F_BITTAB
M32F_BITTAB label tbyte
	BIT_MAC PnP_M32F_ROM
	BIT_MAC PnP_M32F_SHD
	BIT_MAC PnP_M32F_CTL
	BIT_MAC PnP_M32F_SUP
	BIT_MAC PnP_M32F_CAC
	BIT_MAC PnP_M32F_WRT
M32F_BITTAB_LEN equ ($-M32F_BITTAB)/(type BIT_STR) ; # entries
M32_BITTAB     equ M32F_BITTAB
M32_BITTAB_LEN equ M32F_BITTAB_LEN
M16_BITTAB     equ M32F_BITTAB
M16_BITTAB_LEN equ M32F_BITTAB_LEN


PTR_PnP_M32F_ROM dw PGROUP:MSG_M32F_ROM0
		 dw PGROUP:MSG_M32F_ROM1

PTR_PnP_M32F_SHD dw PGROUP:MSG_M32F_SHD0
		 dw PGROUP:MSG_M32F_SHD1

PTR_PnP_M32F_CTL dw PGROUP:MSG_M32F_CTL00
		 dw PGROUP:MSG_M32F_CTL01
		 dw PGROUP:MSG_M32F_CTL10
		 dw PGROUP:MSG_M32F_CTL11

PTR_PnP_M32F_SUP dw PGROUP:MSG_M32F_SUP0
		 dw PGROUP:MSG_M32F_SUP1

PTR_PnP_M32F_CAC dw PGROUP:MSG_M32F_CAC0
		 dw PGROUP:MSG_M32F_CAC1

PTR_PnP_M32F_WRT dw PGROUP:MSG_M32F_WRT0
		 dw PGROUP:MSG_M32F_WRT1

MSG_M32F_ROM1  db '   Memory is an expansion ROM',CR,LF
MSG_M32F_ROM0  db EOS

MSG_M32F_SHD1  db '   Memory is shadowable',CR,LF
MSG_M32F_SHD0  db EOS

MSG_M32F_CTL00 db '   8-bit memory only',CR,LF,EOS
MSG_M32F_CTL01 db '   16-bit memory only',CR,LF,EOS
MSG_M32F_CTL10 db '   8- and 16-bit memory',CR,LF,EOS
MSG_M32F_CTL11 db '   32-bit memory only',CR,LF,EOS

MSG_M32F_SUP1  db '   Decode supports high address',CR,LF,EOS
MSG_M32F_SUP0  db '   Decode supports range length',CR,LF,EOS

MSG_M32F_CAC1  db '   Read cacheable, write-through',CR,LF,EOS
MSG_M32F_CAC0  db '   Non-cacheable',CR,LF,EOS

MSG_M32F_WRT1  db '   Writeable',CR,LF,EOS
MSG_M32F_WRT0  db '   Non-writeable (ROM)',CR,LF,EOS

MSG_LRES_M32F  db '   address = '
MSG_LRES_M32F1 db '________, length = '
MSG_LRES_M32F2 db '________',CR,LF,EOS

MSG_LRES_M16   db '   min addr = '
MSG_LRES_M16A  db '________, max addr = '
MSG_LRES_M16B  db '________, alignment = '
MSG_LRES_M16C  db '____ (0=64KB), length = '
MSG_LRES_M16D  db '________',CR,LF,EOS

MSG_LRES_M32   db '   min addr = '
MSG_LRES_M32A  db '________, max addr = '
MSG_LRES_M32B  db '________, alignment = '
MSG_LRES_M32C  db '________ length = '
MSG_LRES_M32D  db '________',CR,LF,EOS


	public	MSG_NUMNODES
MSG_NUMNODES db 'The number of nodes is '
MSG_NUMNODES1 db '__h.',CR,LF,EOS

	public	MSG_NODESIZE
MSG_NODESIZE db 'The largest device node size is '
MSG_NODESIZE1 db '____h.',CR,LF,EOS

	public	MSG_BBS_VERS
MSG_BBS_VERS db 'The BIOS Boot Specification is supported at version # '
MSG_BBS_VERS1 db '____h.',CR,LF,EOS

	public	MSG_BBS_IPLCNT
MSG_BBS_IPLCNT	db 'The BBS device count is '
MSG_BBS_IPLCNT1 db '____h, the maximum # devices supported is '
MSG_BBS_IPLCNT2 db '____h,',CR,LF
		db '  and a table entry is '
MSG_BBS_IPLCNT3 db '____h bytes, all IPL-relative.'
		db CR,LF,EOS

	public	MSG_BBS_BCVCNT
MSG_BBS_BCVCNT	db 'The BBS device count is '
MSG_BBS_BCVCNT1 db '____h, the maximum # devices supported is '
MSG_BBS_BCVCNT2 db '____h,',CR,LF
		db '  and a table entry is '
MSG_BBS_BCVCNT3 db '____h bytes, all BCV-relative.'
		db CR,LF,EOS

DATA	ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	segment use16 dword public 'data' ; Start DTAIL segment
	assume	ds:PGROUP

	public	LCLSTK,LCLSTKZ
LCLSTK	label	word		; Local stack
	org	LCLSTK[100h*(type LCLSTK)] ; The stack
LCLSTKZ label	word		; Top of stack

	public	ZTAIL
ZTAIL	label	byte

DTAIL	ends			; End DTAIL segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP
.xlist
	include PSP.INC 	; Define & skip over PSP area for .COM program
.list
	NPPROC	TESTPnP -- Test Plug 'n Play
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	lea	sp,LCLSTKZ	; Switch to local stack

	mov	CODESEG,cs	; Save as our code segment
	mov	DATASEG,ds	; ...	      data ...

	DOSCALL @STROUT,MSG_COPY ; Display the flag

	call	CHECK_ARGS	; Check for command line arguments
	jc	near ptr TESTPnP_EXIT ; Jump if something went wrong

	call	CHECK_SWAT	; See if SWAT is present

	call	IZIT_PnP	; Determine Plug 'n Play availability
	jc	short TESTPnP_ERR ; Jump if not present

	mov	gs,PnP_SEG	; Address the PnP struc
	assume	gs:PnPGRP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_VM	; Tell 'em we're in VM

	mov	eax,OffPnP_RMVEC ; Get offset to PnP_RMVEC
	mov	eax,PnPGRP:[eax] ; Get the RM entry point
	mov	bx,PnPGRP:[0].PnP_RMDS ; Get the RM data segment

	cmp	PnPGRP:[0].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F	; Jump if so

	xor	bx,bx		; No RMDS in old struc
@@:
	mov	PnP_VEC,eax	; Save for later use
	mov	PnP_DS,bx	; Save for later use

	call	DISP_PnP	; Display PnP struc values

	test	LCL_FLAG,@LCL_PRES ; Izit presence check only?
	jnz	short TESTPnP_EXIT ; Jump if so

	test	LCL_FLAG,@LCL_TESTRMVM ; Test functions in RM/VM?
	jz	short @F	; Jump if not

	call	CHECK_PnP	; Check the functions
@@:

; If there's a VCPI host, enter PM and re-run CHECK_PnP

	test	LCL_FLAG,@LCL_TESTVCPI ; Test functions in VCPI?
	jz	short @F	; Jump if not

	call	CHECK_VCPI	; If VCPI host, enter PM via it
	jc	short @F	; Jump if not present

	call	ENTER_PM	; Enter PM via VCPI
	call	DISP_PnP	; Display PnP struc values
	call	CHECK_PnP	; Check the functions via VCPI
	call	GOVM86		; Return to VM86 mode
@@:

; If there's a DPMI host, enter PM and re-run CHECK_PnP

	test	LCL_FLAG,@LCL_TESTDPMI ; Test functions in DPMI?
	jz	short @F	; Jump if not

	call	CHECK_DPMI	; If DPMI host, enter PM via it
	jc	short @F	; Jump if not present

	call	DISP_PnP	; Display PnP struc values
	call	CHECK_PnP	; Check the functions via DPMI
@@:
	jmp	short TESTPnP_EXIT ; Join common exit code

TESTPnP_ERR:
	DOSCALL @STROUT,MSG_NOPnP ; Tell 'em to upgrade their BIOS
TESTPnP_EXIT:
	mov	al,ERRCODE	; Get return code
	DOSCALL @EXITRC 	; Return to DOS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TESTPnP endp			; End TESTPnP procedure
	NPPROC	CHECK_ARGS -- Check For Command Line Arguments
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for command line arguments

On exit:

CF	=	0 if successful
	=	1 otherwise

|

	REGSAVE <ax,dx,si>	; Save registers

	lea	si,PSP_PARM_STRING ; DS:SI ==> command line
CHECK_ARGS_NEXT:
	call	SKIP_WHITE	; Skip over leading white space
				; returning AL = next char, skipping over it
	call	LOWERCASE	; Convert AL to lowercase

	cmp	al,CR		; Izit EOL?
	je	short CHECK_ARGS_DONE ; Jump if so (note CF=0)

	cmp	al,'/'          ; Izit command switch?
	jne	short CHECK_ARGS_ERR ; Jump if not

	call	SKIP_WHITE	; Skip over leading white space
				; returning AL = next char, skipping over it
	call	LOWERCASE	; Convert AL to lowercase

	cmp	al,'p'          ; Izit a request for presence check only?
	jne	short CHECK_ARGS1 ; Jump if not

	or	LCL_FLAG,@LCL_PRES ; Mark as checking for presence only

	jmp	short CHECK_ARGS_NEXT ; Go around again

CHECK_ARGS_DONE:
	test	LCL_FLAG,@LCL_TESTALL ; Any specific modes?
	jnz	short @F	; Jump if so

	or	LCL_FLAG,@LCL_TESTALL ; Test all available modes
@@:
	clc			; Mark as successful

	jmp	short CHECK_ARGS_EXIT ; Join common exit code

CHECK_ARGS1:
	cmp	al,'r'          ; Izit a request to test RM/VM?
	jne	short CHECK_ARGS2 ; Jump if not

	or	LCL_FLAG,@LCL_TESTRMVM ; Mark as testing RM/VM

	jmp	short CHECK_ARGS_NEXT ; Go around again


CHECK_ARGS2:
	cmp	al,'v'          ; Izit a request to test VCPI?
	jne	short CHECK_ARGS3 ; Jump if not

	or	LCL_FLAG,@LCL_TESTVCPI ; Mark as testing VCPI

	jmp	short CHECK_ARGS_NEXT ; Go around again


CHECK_ARGS3:
	cmp	al,'d'          ; Izit a request to test DPMI?
	jne	short CHECK_ARGS4 ; Jump if not

	or	LCL_FLAG,@LCL_TESTDPMI ; Mark as testing DPMI

	jmp	short CHECK_ARGS_NEXT ; Go around again


CHECK_ARGS4:
CHECK_ARGS_ERR:
	DOSCALL @STROUT,MSG_HELP ; Give 'em a hand

	stc			; Indicate error
CHECK_ARGS_EXIT:
	REGREST <di,dx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
	NPPROC	SKIP_WHITE -- Skip Over White Space
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	lods	ds:[si].LO	; Get next character

	cmp	al,' '          ; Izit a blank?
	je	short SKIP_WHITE ; Yes, so go around again

	cmp	al,TAB		; Izit a TAB?
	je	short SKIP_WHITE ; Yes, so go around again

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	NPPROC	LOWERCASE -- Convert AL to Lowercase
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	cmp	al,40h		; Test for conversion of alpha to lower case
	jb	short LOWERCASE_EXIT ; Not this time

	or	al,20h		; Convert alpha to lower case
LOWERCASE_EXIT:
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	NPPROC	IZIT_PnP -- Determine Plug 'n Play Availability
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine Plug 'n Play availability

If this is a PnP BIOS, somewhere in the BIOS on a para boundary
is the PnP structure with a matching checksum.

|

	REGSAVE <ax,cx,si,ds>	; Save registers

	mov	cx,0F000h	; Segment of start of ROM (paras)
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

	stc			; Mark as not present

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

	cmp	ds:[si].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F	; Jump if so

	cmp	ds:[si].PnP_LEN,size PnP2_STR ; Izit old struc?
	jne	short IZIT_PnP_SKIP ; Jump if not

	mov	OffPnP_RMVEC,PnP2_RMVEC ; Save as offset
	mov	OffPnP_PMCS, PnP2_PMCS	; ...
	mov	OffPnP_PMOFF,PnP2_PMOFF ; ...
@@:
	mov	ax,ds		; Copy the segment
	shr	si,4-0		; Convert from bytes to paras
	add	ax,si		; Add to get the segment
	mov	PnP_SEG,ax	; Save for later use

	clc			; Mark as present
IZIT_PnP_EXIT:
	REGREST <ds,si,cx,ax>	; Restore
	assume	ds:PGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_PnP endp			; End IZIT_PnP procedure
	NPPROC	DISP_PnP -- Display PnP Struc Values
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:PnPGRP,ss:nothing
COMMENT|

Display PnP struc values

|

	pushad			; Save registers

; Display the segment #

	mov	ax,PnP_SEG	; Get the segment
	lea	di,MSG_SEG1	; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	mov	al,PnPGRP:[0].PnP_LEN ; Get the struc length
	lea	di,MSG_SEG2	; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	DOSCALL @STROUT,MSG_SEG ; Display it

; Display the Event Notification Flags

	mov	bx,PnPGRP:[0].PnP_FLAG ; Get the flags
	and	bx,mask $PnPFLAG_ENM ; Isolate the flags
	shr	bx,$PnPFLAG_ENM ; Shift to low-order
	shl	bx,1-0		; Convert from words to bytes

	mov	dx,ENM_TAB[bx]	; Get the corresponding message
	DOSCALL @STROUT 	; Display it

; Display the Event Notification Physical Address

	cmp	PnPGRP:[0].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short @F	; Jump if not (no ENF in old struc)

	mov	eax,PnPGRP:[0].PnP_ENF ; Get the physical address
	lea	di,MSG_ENF1	; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	DOSCALL @STROUT,MSG_ENF ; Display it
@@:

; Display the real mode entry point

	mov	eax,OffPnP_RMVEC ; Get offset to PnP_RMVEC
	mov	eax,PnPGRP:[eax] ; Get the real mode entry point
	lea	di,MSG_RMVECOFF ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	shr	eax,16		; Shift down the high-order word
	lea	di,MSG_RMVECSEG ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	DOSCALL @STROUT,MSG_RMVEC ; Display it

; Display the PM USE16 entry point offset

	mov	eax,OffPnP_PMOFF ; Get offset to PnP_PMOFF
	mov	ax,PnPGRP:[eax] ; Get the PM offset
	lea	di,MSG_PMOFF1	; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	DOSCALL @STROUT,MSG_PMOFF ; Display it

; Display the PM USE16 code segment base address

	mov	eax,OffPnP_PMCS ; Get offset to PnP_PMCS
	mov	eax,PnPGRP:[eax] ; Get the PM code segment base address
	lea	di,MSG_PMCS1	; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	DOSCALL @STROUT,MSG_PMCS ; Display it

; Display the OEM device identifier

	cmp	PnPGRP:[0].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short @F	; Jump if not (no OEM identifier in old struc)

	mov	eax,PnPGRP:[0].PnP_OEM ; Get the compressed OEM device identifier
	call	CVT_EISAID	; Convert EISA ID in EAX to ASCII

	mov	eax,PnP_PRODID	; Get the uncompressed product ID
	mov	MSG_OEM1.EDD,eax ; Save in message

	mov	eax,PnP_PRODNO	; Get the uncompressed product #
	mov	MSG_OEM2.EDD,eax ; Save in message

	DOSCALL @STROUT,MSG_OEM ; Display it
@@:

; Display the RM data segment

	cmp	PnPGRP:[0].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short @F	; Jump if not (no RMDS in old struc)

	mov	ax,PnPGRP:[0].PnP_RMDS ; Get the RM data segment
	lea	di,MSG_RMDS1	; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	DOSCALL @STROUT,MSG_RMDS ; Display it
@@:

; Display the PM data segment base address

	cmp	PnPGRP:[0].PnP_LEN,size PnP_STR ; Izit new struc?
	jne	short @F	; Jump if not (no PMDS in old struc)

	mov	eax,PnPGRP:[0].PnP_PMDS ; Get the PM data segment base address
	lea	di,MSG_PMDS1	; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	DOSCALL @STROUT,MSG_PMDS ; Display it
@@:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_PnP endp			; End DISP_PnP procedure
	NPPROC	CHECK_PnP -- Check PnP Routines
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:PnPGRP,ss:nothing
COMMENT|

Process all PnP functions

Note: PnP needs a 1KB stack for itself

|

	pushad			; Save all EGP registers
	REGSAVE <gs>		; Save segment register

; Test function 00h -- Get Number of Nodes

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of PnP_NodeSize
	push	offset ds:PnP_NodeSize ; ...  offset  ...
	push	ds		; ...  segment of PnP_NumNodes
	push	offset ds:PnP_NumNodes ; ...  offset  ...
	push	@PnP_GET_NUM_NODES ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 00h (Get Number of Nodes) failed!',BEL>

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	near ptr CHECK_PnP1 ; Jump if not

; Display NumNodes

	mov	al,PnP_NumNodes ; Get the # nodes
	lea	di,MSG_NUMNODES1 ; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_NUMNODES ; Display it

; Display NodeSize

	mov	ax,PnP_NodeSize ; Get the size of the largest device node
	lea	di,MSG_NODESIZE1 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_NODESIZE ; Display it
CHECK_PnP1:

; Test functions 01h & 02h -- Get/Set System Device Nodes

	mov	PnP_CTL,01b	; Current configuration
	call	CHECK_PnP12	; Handle via subroutine

	mov	PnP_CTL,10b	; Next boot configuration
	call	CHECK_PnP12	; Handle via subroutine

; Some PnP BIOSes don't support functions 03h-05h, so we test for
; event notification to see whether or not we should exercise them.

	mov	ax,PnPGRP:[0].PnP_FLAG ; Get flag word
	and	ax,mask $PnPFLAG_ENM ; Isolate the Event Notification Mode

	cmp	ax,@PnPFLAG_ENM_NS shl $PnPFLAG_ENM ; Izit not supported?
	je	short CHECK_PnP_XEN ; Jump if so

; Test function 03h -- Get Event

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of PnP_Message
	push	offset ds:PnP_Message ; ...  offset  ...
	push	@PnP_GET_EVENT	; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 03h (Get Event) failed!',BEL>

; Test function 04h -- Send Message

	mov	PnP_Message,@PnP_MSG_OK ; Pick a harmless message

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	PnP_Message	; ...  PnP_Message value
	push	@PnP_SEND_MSG	; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+2+2	; Strip back the stack

	ERRCHK	<'*** PnP function 04h (Send Message) failed!',BEL>

; Test function 05h -- Get Docking Station Info

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; ...  offset  ...
	push	@PnP_GET_DOCK_INFO ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 05h (Get Docking Station Info) failed!',BEL>

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	near ptr CHECK_PnP2 ; Jump if not

; Display docking station info













CHECK_PnP2:
CHECK_PnP_XEN:

; Functions 06h, 07h, and 08h are reserved

; Test function 0Ah -- Get Statically Allocated resources

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; ...  offset  ...
	push	@PnP_GET_STATIC_RES ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 0Ah (Get Statically Allocated Resources) failed!',BEL>

; Test function 09h -- Set Statically Allocated resources
; Skipped because it might be destructive

; Test function 40h -- Get ISA Configuration Structure

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; ...  offset  ...
	push	@PnP_GET_ISA_CFG ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 40h (Get ISA Configuration Structure) failed!',BEL>

; Test function 41h -- Get ESCD Info

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of PnP_NVStorageBase
	push	offset ds:PnP_NVStorageBase ; ...  offset  ...
	push	ds		; ...  segment of PnP_ESCDSize
	push	offset ds:PnP_ESCDSize ; ...  offset  ...
	push	ds		; ...  segment of PnP_MinESCDSize
	push	offset ds:PnP_MinESCDSize ; ...  offset  ...
	push	@PnP_GET_ESCD_INFO ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+4+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 41h (Get ESCD Info) failed!',BEL>

; Test function 42h -- Read ESCD data

	mov	ebx,PnP_NVStorageBase ; Get NV storage base (<1MB & /16)
	shr	ebx,4-0 	; Convert from bytes to paras

; If we're in DPMI mode, do a phys-to-lin and convert this to a selector

	test	LCL_FLAG,@LCL_DPMI ; Are we in DPMI mode?
	jz	short CHECK_PnP_XDPMI ; Jump if not

; Allocate a selector to address the NV storage base

	mov	cx,1		; # selectors to allocate
	DPMICALL @DPMI_GETLDT	; Allocate selectors
;;;;;;; jc	short ???	; Ignore error return

	mov	bx,ax		; Copy the selector
	xor	cx,cx		; CX:DX = 64KB-1
	mov	dx,-1		; ...
	DPMICALL @DPMI_SSELLIM	; Set selector limit
;;;;;;; jc	short ???	; Ignore error return

	push	bx		; Save the selector

	mov	ebx,PnP_NVStorageBase ; Get NV storage base (<1MB & /16)
	mov	cx,bx		; Get low-order word
	shr	ebx,16		; Shift down high-order word
				; BX:CX = physical memory
	mov	si,1		; SI:DI ==> 64KB
	xor	di,di		; ...
	DPMICALL @DPMI_GETP2L	; Return with BX:CX ==> linear address
;;;;;;; jc	short ???	; Ignore error return

	mov	dx,cx		; Copy so that CX:DX ==> base address
	mov	cx,bx		; ...

	pop	bx		; Restore selector

	DPMICALL @DPMI_SSELBAS	; Set selector base to CX:DX
;;;;;;; jc	short ???	; Ignore error return

	jmp	short CHECK_PnP_ESCD_COM ; Join common code

CHECK_PnP_XDPMI:
	test	LCL_FLAG,@LCL_VCPI ; Are we in VCPI mode?
	jz	short CHECK_PnP_ESCD_COM ; Jump if not

; Because NV Storage base address is physical,
; we save it as a series of PTEs

	mov	eax,PnP_NVStorageBase ; Get NV storage base (<1MB & /16)
	or	eax,@PTE_URP	; Mark as User/Read-write/Present

	push	fs		; Save for a moment

	mov	fs,SEL_4GB	; Get AGROUP data selector
	assume	fs:AGROUP	; Tell the assembler about it

	mov	ebx,OffNVStoragePTE ; Get offset in LaPTE of NV Storage PTEs
	add	ebx,LaPTE	; Plus linear address of the PTEs (/4KB)
	mov	cx,16		; Get # PTEs to setup
@@:
	mov	AGROUP:[ebx].EDD,eax ; Save as PTE

	add	ebx,4		; Skip to next PTE
	add	eax,4*1024	; ...

	loop	@B		; Jump if more PTEs to setup

	pop	fs		; Restore
	assume	fs:nothing	; Tell the assembler about it

	mov	eax,cr3 	; Get current value
	mov	cr3,eax 	; Reset to flush the TLB

	mov	bx,DTE_PnPNVST	; Get the selector
CHECK_PnP_ESCD_COM:
	push	PnP_DS		; Pass the R/W BIOS data selector
	push	bx		; ...  segment of PnP_NVStorageBase
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; ...  offset  ...
	push	@PnP_GET_ESCD	; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+2+2	; Strip back the stack

	ERRCHK	<'*** PnP function 42h (Read ESCD Data) failed!',BEL>
;;;;;;;
;;;;;;; cmp	ax,@PnP_SUCCESS ; Did it work?
;;;;;;; jne	short @F	; Jump if not
;;;;;;;
; Test function 43h -- Write ESCD data
; Skip this as it crashes on AMI BIOS 4/15/94
;;;;;;;
;;;;;;; push	PnP_DS		; Pass the R/W BIOS data selector
;;;;;;; push	bx		; ...  segment of PnP_NVStorageBase
;;;;;;; push	ds		; ...  segment of ZTAIL
;;;;;;; push	PTAIL		; ...  offset  ...
;;;;;;; push	@PnP_SET_ESCD	; Pass function #
;;;;;;; call	PnP_VEC 	; Request PnP service
;;;;;;; 			; Return status in AX
;;;;;;; add	sp,2+4+2+2	; Strip back the stack
;;;;;;;
;;;;;;; ERRCHK	<'*** PnP function 43h (Write ESCD Data) failed!',BEL>
;;;;;;;@@:

; Test function 0Bh -- Get APM ID Table

	mov	PnP_APMSize,0	; Set to zero to get actual size

; The first call with a buffer size of zero asks the BIOS
; to fill in the needed size

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; ...  offset  ...
	push	ds		; ...  segment of PnP_APMSize
	push	offset ds:PnP_APMSize ; ...  offset  ...
	push	@PnP_GET_APM_ID_TAB ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 0Bh (Get APM ID Table #1) failed!',BEL>

	cmp	ax,@PnP_SUCCESS ; Dis it work?
	jne	short @F	; Jump if not

; The second call gets the entire table

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; ...  offset  ...
	push	ds		; ...  segment of PnP_APMSize
	push	offset ds:PnP_APMSize ; ...  offset  ...
	push	@PnP_GET_APM_ID_TAB ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 0Bh (Get APM ID Table #2) failed!',BEL>
@@:

; Test function 60h -- Get Version and Installation Check

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of PnP_Version
	push	offset ds:PnP_Version ; ...  offset  ...
	push	@PnP_GET_VERSION ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 60h (Get Version and Installation Check) failed!',BEL>

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	near ptr CHECK_PnP_XBBS ; Jump if not supported

; Display BIOS Boot Specification Version #

	mov	ax,PnP_Version	; Get the size of the largest device node
	lea	di,MSG_BBS_VERS1 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_BBS_VERS ; Display it

; Test function 61h -- Get Device Count, IPL-relative

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of PnP_StrSize
	push	offset ds:PnP_IPLStrSize ; ...	offset	...
	push	ds		; ...  segment of PnP_MaxCnt
	push	offset ds:PnP_IPLMaxCnt ; ...  offset  ...
	push	ds		; ...  segment of PnP_DevCnt
	push	offset ds:PnP_IPLDevCnt ; ...  offset  ...
	push	@PnP_BBS_IPL	; IPL-relative
	push	@PnP_GET_DEV_CNT ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+4+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 61h (Get Device Count, IPL-relative) failed!',BEL>

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	short @F	; Jump if not

	mov	ax,PnP_IPLDevCnt ; Get the device count
	lea	di,MSG_BBS_IPLCNT1 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	mov	ax,PnP_IPLMaxCnt ; Get the maximum # devices supported
	lea	di,MSG_BBS_IPLCNT2 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	mov	ax,PnP_IPLStrSize ; Get the table entry size
	lea	di,MSG_BBS_IPLCNT3 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_BBS_IPLCNT ; Display it
@@:

; Test function 61h -- Get Device Count, BCV-relative

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of PnP_StrSize
	push	offset ds:PnP_BCVStrSize ; ...	offset	...
	push	ds		; ...  segment of PnP_MaxCnt
	push	offset ds:PnP_BCVMaxCnt ; ...  offset  ...
	push	ds		; ...  segment of PnP_DevCnt
	push	offset ds:PnP_BCVDevCnt ; ...  offset  ...
	push	@PnP_BBS_BCV	; BCV-relative
	push	@PnP_GET_DEV_CNT ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+4+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 61h (Get Device Count, BCV-relative) failed!',BEL>

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	short @F	; Jump if not

	mov	ax,PnP_BCVDevCnt ; Get the device count
	lea	di,MSG_BBS_BCVCNT1 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	mov	ax,PnP_BCVMaxCnt ; Get the maximum # devices supported
	lea	di,MSG_BBS_BCVCNT2 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	mov	ax,PnP_BCVStrSize ; Get the table entry size
	lea	di,MSG_BBS_BCVCNT3 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_BBS_BCVCNT ; Display it
@@:

; Test function 62h -- Get Priority and Table, IPL-relative

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of ZTAIL
	mov	ax,PTAIL	; Get  offset  of ZTAIL
	add	ax,PnP_IPLMaxCnt ; Skip over boot priority table
	push	ax		; Pass ...
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; Pass offset ...
	push	@PnP_BBS_IPL	; IPL-relative
	push	@PnP_GET_PRIORITY ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 62h (Get Priority and Table, IPL-relative) failed!',BEL>

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	short @F	; Jump if not

; Test function 63h -- Set Priority, IPL-relative

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; Pass offset ...
	push	@PnP_BBS_IPL	; IPL-relative
	push	@PnP_SET_PRIORITY ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 63h (Set Priority, IPL-relative) failed!',BEL>
@@:

; Test function 62h -- Get Priority and Table, BCV-relative

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of ZTAIL
	mov	ax,PTAIL	; Get  offset  of ZTAIL
	add	ax,PnP_BCVMaxCnt ; Skip over boot priority table
	push	ax		; Pass ...
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; Pass offset ...
	push	@PnP_BBS_BCV	; BCV-relative
	push	@PnP_GET_PRIORITY ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 62h (Get Priority and Table, BCV-relative) failed!',BEL>

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	short @F	; Jump if not

; Test function 63h -- Set Priority, IPL-relative

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; Pass offset ...
	push	@PnP_BBS_BCV	; BCV-relative
	push	@PnP_SET_PRIORITY ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 63h (Set Priority, BCV-relative) failed!',BEL>
@@:

; Test function 64h -- Get IPL Device from Last Boot

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of PnP_IPLDevBoot
	push	offset ds:PnP_IPLDevBoot ; ...	offset	...
	push	@PnP_GET_IPLDEV ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 64h (Get IPL Device from Last Boot) failed!',BEL>

; Test function 65h -- Get Boot First

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of PnP_Boot1st
	push	offset ds:PnP_Boot1st ; ...  offset  ...
	push	@PnP_GET_BOOT1ST ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 65h (Get Boot First) failed!',BEL>

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	short @F	; Jump if not

	cmp	PnP_Boot1st,0FFh ; Izit invalid?
	je	short @F	; Jump if so

; Test function 66h -- Set Boot First

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	ds		; ...  segment of PnP_Boot1st
	push	offset ds:PnP_Boot1st ; ...  offset  ...
	push	@PnP_SET_BOOT1ST ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+2	; Strip back the stack

	ERRCHK	<'*** PnP function 66h (Set Boot First) failed!',BEL>
@@:







CHECK_PnP_XBBS:





CHECK_PnP_EXIT:
	REGREST <gs>		; Restore
	assume	gs:nothing	; Tell the assembler about it
	popad			; ...

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PnP endp			; End CHECK_PnP procedure
	NPPROC	CHECK_PnP12 -- Test PnP Functions 1 and 2
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:PnPGRP,ss:nothing
COMMENT|

Check PnP functions 1 and 2.

On entry:

PnP_CTL has been initialized

|

	REGSAVE <eax,bx,cx,si>	; Save registers

	mov	PnP_Node,0	; Initialize with starting node
CHECK_PnP12_NEXT:

; Note that the call to @PnP_GET_DEV_NODE increments the value of PnP_Node
; thus we save the current value in BL to pass to the @PnP_SET_DEV_NODE call.

	mov	bx,PnP_Node	; Get the current node #

	cmp	bx,0FFh 	; Izit end of the line?
	je	near ptr CHECK_PnP12_EXIT ; Jump if so

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	PnP_CTL 	; ...  control flags
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; ...  offset  ...
	push	ds		; ...  segment of PnP_Node
	push	offset ds:PnP_Node ; ...  offset  ...
	push	@PnP_GET_DEV_NODE ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+4+4+2+2	; Strip back the stack

	ERRCHK	<'*** PnP function 01h (Get Device Node) failed!',BEL>

	cmp	ax,@PnP_SUCCESS ; Did it work?
	jne	near ptr CHECK_PnP12_EXIT ; Jump if not

; Display the device info

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_DEVTTL ; Display device title

	mov	si,PTAIL	; Get offset of buffer
	mov	al,PGROUP:[si].PnP_DEV_NODE ; Get the node #
	lea	di,MSG_NODE1	; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_NODE ; Display it

; Decode the compressed device product ID

	mov	eax,PGROUP:[si].PnP_DEV_PROD ; Get the compressed product ID/#
	call	CVT_EISAID	; Convert EISA ID in EAX to ASCII

	mov	eax,PnP_PRODID	; Get the uncompressed product ID
	mov	MSG_PID1.EDD,eax ; Save in message

	mov	eax,PnP_PRODNO	; Get the uncompressed product #
	mov	MSG_PID2.EDD,eax ; Save in message

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_PID ; Display it

; Display the device type code

	mov	al,PGROUP:[si].PnP_DEV_TYPE[0] ; Get the type code byte #0
	lea	di,MSG_TYPE0	; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	mov	al,PGROUP:[si].PnP_DEV_TYPE[1] ; Get the type code byte #1
	lea	di,MSG_TYPE1	; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	mov	al,PGROUP:[si].PnP_DEV_TYPE[2] ; Get the type code byte #2
	lea	di,MSG_TYPE2	; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_TYPE ; Display it

; Display the device flags

	push	PGROUP:[si].PnP_DEV_FLAG ; Pass the flags
	push	offset PGROUP:DEV_BITTAB ; Pass the table offset
	push	DEV_BITTAB_LEN	; Pass the table length
	call	DISP_BITS	; Display 'em

; Display the device resources

	push	si		; Save for a moment

	mov	cx,PGROUP:[si].PnP_DEV_LEN ; Get # bytes in device node struc
	sub	cx,PnP_DEV_REST ; Less start of trailing data
	lea	si,PGROUP:[si].PnP_DEV_REST ; DS:SI ==> start of trailing variable data
@@:
	and	cx,cx		; Izit empty?
	jz	short @F	; Jump if so

	call	DISP_DEV_NODE	; Display trailing variable data

	jmp	short @B	; Go around again

@@:
	pop	si		; Restore

; Send back the same data

	test	PGROUP:[si].PnP_DEV_FLAG,@PnP_DEVFLAG_XCFG ; Izit not configurable?
	jnz	near ptr CHECK_PnP12_NEXT ; Jump if so

	push	PnP_DS		; Pass the R/W BIOS data selector
	push	PnP_CTL 	; ...  control flags
	push	ds		; ...  segment of ZTAIL
	push	PTAIL		; ...  offset  ...
	push	bx		; ...  node # (only low-order 8 bits used)
	push	@PnP_SET_DEV_NODE ; Pass function #
	call	PnP_VEC 	; Request PnP service
				; Return status in AX
	add	sp,2+2+4+2+2	; Strip back the stack

	ERRCHK	<'*** PnP function 02h (Set Device Node) failed!',BEL>

;;;;;;; cmp	ax,@PnP_SUCCESS ; Did it work?
;;;;;;; je	short @F	; Jump if so
;;;;;;;
;;;;;;; int	03h		; Call our debugger
@@:
	jmp	CHECK_PnP12_NEXT ; Go around again

CHECK_PnP12_EXIT:
	REGREST <si,cx,bx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PnP12 endp		; End CHECK_PnP12 procedure
	NPPROC	DISP_DEV_NODE -- Display Device Node Trailing Variable Data
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:PnPGRP,ss:nothing
COMMENT|

Display device node trailing variable data

On entry:

CX	=	# bytes remaining
DS:SI	==>	trailing data

On exit:

CX	=	(updated)
DS:SI	==>	(updated)

|

	REGSAVE <ax,bx,edx>	; Save registers

	lods	ds:[si].LO	; Get data type
	dec	cx		; Count it out

	btr	al,$PnP_SRES_TYPE ; Izit large resource data type?
	jc	near ptr DISP_DEV_NODE_LARGE ; Jump if so

	movzx	bx,al		; Copy
	and	bx,mask $PnP_SRES_NAME ; Isolate the name bits
	shr	bx,$PnP_SRES_NAME ; Shift to low-order
	shl	bx,1-0		; Convert from words to bytes

	and	ax,mask $PnP_SRES_LEN ; Isolate the length bits
	shr	ax,$PnP_SRES_LEN ; Shift to low-order
	mov	RES_LEN,ax	; Save for later use

	movzx	edx,SRES_NAME_TAB[bx] ; DS:EDX ==> name
	DOSCALL @STROUT 	; Display it

; Process each different type

	jmp	SRES_NAME_ACT[bx] ; Take appropriate action


; Version #
;   Byte 0 = packed BCD
;	 1 = vendor-specific

SRES_ACT_VER:
	movzx	ax,ds:[si].LO	; Get the PnP version # in packed BCD format
	shl	ax,4		; Shift up the nibbles
	shr	al,4		; Shift low-order nibble down
	add	ax,'00'         ; Convert to ASCII
	mov	MSG_SRES_VER2,al ; Save in message
	mov	MSG_SRES_VER1,ah ; ...

	mov	al,ds:[si+1]	; Get vendor-specific version #
	lea	di,MSG_SRES_VER3 ; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	DOSCALL @STROUT,MSG_SRES_VER ; Displpay the message

	jmp	DISP_DEV_NODE_SMALL_NEXT ; Join common code


; I/O Port Descriptor
;   Byte 0:  Bit 0 = 1 if 16-bit I/O decode
;		   = 0 if 10-bit ...
;	 1 = Range min base addr bits[7:0]
;	 2 = ...		     15:8
;	 3 = Range max base addr bits[7:0]
;	 4 = ...		     15:8
;	 5 = Base alignment
;	 6 = Range length

SRES_ACT_IO:
	test	ds:[si+0].LO,@BIT0 ; Duzit support 16-bit decode?
	lea	dx,MSG_SRES_IO16 ; Assume so
	jnz	short @F	; Jump if so

	lea	dx,MSG_SRES_IO10 ; It doesn't
@@:
	DOSCALL @STROUT 	; Display the I/O address decode width

	mov	ax,ds:[si+1]	; Get the range minimum base address
	lea	di,MSG_SRES_IORNG1 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	mov	ax,ds:[si+3]	; Get the range maximum base address
	lea	di,MSG_SRES_IORNG2 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	mov	al,ds:[si+5]	; Get the base alignment
	lea	di,MSG_SRES_IORNG3 ; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	mov	al,ds:[si+6]	; Get the range length
	lea	di,MSG_SRES_IORNG4 ; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	DOSCALL @STROUT,MSG_SRES_IORNG ; Display it

	jmp	DISP_DEV_NODE_SMALL_NEXT ; Join common code


; Fixed Location I/O Port Descriptor
;   Byte 0 = Range base addr bits[7:0]
;	 1 = ...		 15:8
;	 2 = Range length

SRES_ACT_IOF:
	mov	ax,ds:[si+0]	; Get the range base address
	lea	di,MSG_SRES_IOFRNG1 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	mov	al,ds:[si+2]	; Get the range length
	lea	di,MSG_SRES_IOFRNG2 ; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	DOSCALL @STROUT,MSG_SRES_IOFRNG ; Display it

	jmp	DISP_DEV_NODE_SMALL_NEXT ; Join common code


; IRQ format
;   Byte 0 = IRQ mask bits[7:0]
;	 1 =		  15:8
;	 2 = IRQ info (optional)
;	     Bit 3 = low true level-sensitive
;	     Bit 2 = high ...
;	     Bit 1 = low true edge-sensitive
;	     Bit 0 = high ...

SRES_ACT_IRQ:
	cmp	RES_LEN,0	; Izit a null IRQ derscriptor?
	je	near ptr DISP_DEV_NODE_SMALL_NEXT ; Jump if so

	REGSAVE <cx>		; Save for a moment

	mov	bx,ds:[si].PnP_IRQ_MASK ; Get the IRQ mask bits
	mov	cx,16		; Get # bits in a word

	cmp	bx,0		; Any interrupts?
	je	short SRES_ACT_IRQ1 ; Jump if not

	DOSCALL @STROUT,MSG_SRES_IRQHDR ; Display the header
SRES_ACT_IRQ_NEXT:
	shr	bx,1		; Shift out another bit
	jnc	short @F	; Jump if not active

; Display the IRQ #

	mov	di,cx		; Count loop counter
	sub	di,16		; Less maximum #
	neg	di		; Negate to get IRQ #
	shl	di,1-0		; Convet from words to bytes
	mov	dx,SRES_IRQTAB[di] ; Get offset of message
	DOSCALL @STROUT 	; Display it
@@:
	loop	SRES_ACT_IRQ_NEXT ; Jump if more bits

	DOSCALL @STROUT,MSG_CRLF ; End the line
SRES_ACT_IRQ1:
	REGREST <cx>		; Restore

; Display optional IRQ info

	cmp	RES_LEN,3	; Izit present?
	jb	short @F	; Jump if not

	push	ds:[si].PnP_IRQ_INFO.ELO ; Pass the flags (low-order 8 bits only)
	push	offset PGROUP:IRQ_BITTAB ; Pass the table offset
	push	IRQ_BITTAB_LEN	; Pass the table length
	call	DISP_BITS	; Display 'em
@@:
	jmp	DISP_DEV_NODE_SMALL_NEXT ; Join common code


; DMA Format
;   Byte 0 = DMA channel mask bits
;	 1 = flags
;	     Bit 7    = 0
;	     Bits 6:5 = 00:  compatibility mode
;			01:  Type A DMA (EISA)
;			10:  Type B DMA
;			11:  Type F DMA
;	     Bit 4    = DMA word mode
;			0 = not supported
;			1 = is supported
;	     Bit 3    = DMA byte mode status
;			0 = not supported
;			1 = is supported
;	     Bit 2    = Logical device bus master
;			0 = not bus master
;			1 = is bus master
;	     Bits 1:0 = Transfer type preference
;			00 = 8-bit only
;			01 = 8- and 16-bit
;			10 = 16-bit only
;			11 = (Reserved)

SRES_ACT_DMA:
	cmp	RES_LEN,0	; Izit a null IRQ derscriptor?
	je	near ptr DISP_DEV_NODE_SMALL_NEXT ; Jump if so

	REGSAVE <cx>		; Save for a moment

	mov	bl,ds:[si].PnP_DMA_MASK ; Get the DMA mask bits
	mov	cx,8		; Get # bits in a byte

	cmp	bl,0		; Any channels?
	je	short SRES_ACT_DMA1 ; Jump if not

	DOSCALL @STROUT,MSG_SRES_DMAHDR ; Display the header
SRES_ACT_DMA_NEXT:
	shr	bl,1		; Shift out another bit
	jnc	short @F	; Jump if not active

; Display the DMA #

	mov	di,cx		; Count loop counter
	sub	di,8		; Less maximum #
	neg	di		; Negate to get IRQ #
	shl	di,1-0		; Convet from words to bytes
	mov	dx,SRES_DMATAB[di] ; Get offset of message
	DOSCALL @STROUT 	; Display it
@@:
	loop	SRES_ACT_DMA_NEXT ; Jump if more bits

	DOSCALL @STROUT,MSG_CRLF ; End the line
SRES_ACT_DMA1:
	REGREST <cx>		; Restore

; Display flags bits

	push	ds:[si].PnP_DMA_INFO.ELO ; Pass the flags (low-order 8 bits only)
	push	offset PGROUP:DMA_BITTAB ; Pass the table offset
	push	DMA_BITTAB_LEN	; Pass the table length
	call	DISP_BITS	; Display 'em

	jmp	DISP_DEV_NODE_SMALL_NEXT ; Join common code


; Logical Device ID
;   Bytes 0-3 = Compressed device ID
;	  4-5 = Flags

SRES_ACT_LID:
	mov	eax,ds:[si+0]	; Get the compressed device ID
	call	CVT_EISAID	; Convert EISA ID in EAX to ASCII

	mov	eax,PnP_PRODID	; Get the uncompressed product ID
	mov	MSG_SRES_LID1.EDD,eax ; Save in message

	mov	eax,PnP_PRODNO	; Get the uncompressed product #
	mov	MSG_SRES_LID2.EDD,eax ; Save in message

	DOSCALL @STROUT,MSG_SRES_LID ; Display it

; Display the flags

	mov	ax,ds:[si+1]	; Get the LID flags
	lea	di,MSG_SRES_LIDFLAG1 ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	DOSCALL @STROUT,MSG_SRES_LIDFLAG ; Display it

	jmp	short DISP_DEV_NODE_SMALL_NEXT ; Join common code


; Compatible Device ID
;   Bytes 0-3 = Compressed device ID

SRES_ACT_CID:
	mov	eax,ds:[si+0]	; Get the compressed device ID
	call	CVT_EISAID	; Convert EISA ID in EAX to ASCII

	mov	eax,PnP_PRODID	; Get the uncompressed product ID
	mov	MSG_SRES_CID1.EDD,eax ; Save in message

	mov	eax,PnP_PRODNO	; Get the uncompressed product #
	mov	MSG_SRES_CID2.EDD,eax ; Save in message

	DOSCALL @STROUT,MSG_SRES_CID ; Display it

	jmp	short DISP_DEV_NODE_SMALL_NEXT ; Join common code


; Start Dependent Functions
;   Byte 0 = Priority (optional)
;	     0 = Good configuration -- highest priority and preferred
;	     1 = Acceptable configuration -- lower priority, but acceptable
;	     2 = Sub-optimal configuration -- functional, but not optimal
;	     3-255 = reserved

SRES_ACT_SDF:
	cmp	RES_LEN,0	; Izit present?
	je	short SRES_ACT_SDF_EXIT ; Jump if not

	movzx	bx,ds:[si+0].LO ; Get the priority byte

	cmp	bx,@SDF_RES	; Izit too large?
	jbe	short @F	; Jump if not

	mov	bx,@SDF_RES	; Use maximum
@@:
	shl	bx,1-0		; Convert from words to bytes
	mov	dx,PTR_SDF_TAB[bx] ; DS:DX ==> message
	DOSCALL @STROUT 	; Display the message
SRES_ACT_SDF_EXIT:
	jmp	short DISP_DEV_NODE_SMALL_NEXT ; Join common code


SRES_ACT_RES00:
SRES_ACT_EDF:
SRES_ACT_RES0A:
SRES_ACT_RES0B:
SRES_ACT_RES0C:
SRES_ACT_RES0D:
SRES_ACT_VEN:
	jmp	short DISP_DEV_NODE_DATA ; Join common code


; End tag
;   Byte 0 = 00 if no checksum, otherwise it's the checksum

SRES_ACT_EOT:
	mov	al,ds:[si+0]	; Get the checksum

	cmp	al,0		; Izit unspecified?
	je	short DISP_DEV_NODE_SMALL_NEXT ; Jump if so

	lea	di,MSG_SRES_EOT1 ; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	DOSCALL @STROUT,MSG_SRES_EOT ; Display it

	jmp	short DISP_DEV_NODE_SMALL_NEXT ; Join common code


DISP_DEV_NODE_DATA:
	call	DISP_DEV_DATA	; Display device node data, at DS:SI, len=DX
DISP_DEV_NODE_SMALL_NEXT:
	sub	cx,RES_LEN	; Subtract from overall count
	add	si,RES_LEN	; Skip over it

	jmp	DISP_DEV_NODE_EXIT ; Join common exit code

DISP_DEV_NODE_LARGE:
	movzx	bx,al		; Copy
	and	bx,mask $PnP_LRES_NAME ; Isolate the name bits
	shr	bx,$PnP_LRES_NAME ; Shift to low-order

	cmp	bx,@PnP_LRES_NAME_MAX ; Izit above the maximum?
	jbe	short @F	; Jump if so

	mov	bx,@PnP_LRES_NAME_MAX+1 ; Use maximum+1
@@:
	shl	bx,1-0		; Convert from words to bytes

	movzx	edx,LRES_NAME_TAB[bx] ; DS:EDX ==> name
	DOSCALL @STROUT 	; Display it

; Get the length word

	lods	ds:[si].ELO	; Get the length word
	sub	cx,2		; Count it out
	mov	RES_LEN,ax	; Save for later use

; Process each different type

	jmp	LRES_NAME_ACT[bx] ; Take appropriate action


; 32-bit Fixed Location Memory Range Descriptor
;   Byte 0 = Information bits
;	     Bit 7 = 0
;	     Bit 6 = Expansion ROM
;		     0 = not
;		     1 = is
;	     Bit 5 = Shadow ROM
;		     0 = not
;		     1 = is
;	     Bits 4:3 = Memory control
;			00 = 8-bit memory only
;			01 = 16-bit memory only
;			10 = 8- and 16-bit memory
;			11 = 32-bit memory only
;	     Bit 2 = Support type
;		     0 = decode supports range length
;		     1 = decode supports high address
;	     Bit 1 = Cache support type
;		     0 = non-cacheable
;		     1 = read cacheable, write-through
;	     Bit 0 = Write status
;		     0 = non-writeable (ROM)
;		     1 = writeable
;   Bytes 1-4 = address
;   Bytes 5-8 = length

LRES_ACT_M32F:

; Display the infomation bits

	push	ds:[si+0].ELO	; Pass the flags (low-order 8 bits only)
	push	offset PGROUP:M32F_BITTAB ; Pass the table offset
	push	M32F_BITTAB_LEN ; Pass the table length
	call	DISP_BITS	; Display 'em

; Display the address base and length

	mov	eax,ds:[si+1]	; Get the base address
	lea	di,MSG_LRES_M32F1 ; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	mov	eax,ds:[si+5]	; Get the length
	lea	di,MSG_LRES_M32F2 ; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	DOSCALL @STROUT,MSG_LRES_M32F ; Display it

	jmp	DISP_DEV_NODE_LARGE_NEXT ; Join common code


; 16-bit Memory Range Descriptor
;   Byte 0   = Information bits (see M32F for details)
;	 1-2 = minimum base address
;	 3-4 = maximum ...
;	 5-6 = alignment bits
;	 7-8 = length

LRES_ACT_M16:

; Display the infomation bits

	push	ds:[si+0].ELO	; Pass the flags (low-order 8 bits only)
	push	offset PGROUP:M16_BITTAB ; Pass the table offset
	push	M16_BITTAB_LEN	; Pass the table length
	call	DISP_BITS	; Display 'em

; Display the address min/max base, alignment, and length

	movzx	eax,ds:[si+1].ELO ; Get the minimum base address (*256)
	shl	eax,8		; Shift up as address bits 0-7 were assumed to be 0
	lea	di,MSG_LRES_M16A ; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	movzx	eax,ds:[si+3].ELO ; Get the maximum base address
	shl	eax,8		; Shift up as address bits 0-7 were assumed to be 0
	lea	di,MSG_LRES_M16B ; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	mov	ax,ds:[si+5]	; Get the alignment
	lea	di,MSG_LRES_M16C ; ES:DI ==> output save area
	call	DW2HEX		; Convert AX to hex at ES:DI

	movzx	eax,ds:[si+7].ELO ; Get the length (*256)
	shl	eax,8		; Shift up as length bits 0-7 are assumed to be 0
	lea	di,MSG_LRES_M16D ; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	DOSCALL @STROUT,MSG_LRES_M16 ; Display it

	jmp	short DISP_DEV_NODE_LARGE_NEXT ; Join common code


; 32-bit Memory Range Descriptor
;   Byte 0     = Information bits (see M32F for details)
;	 1-4   = minimum base address
;	 5-8   = maximum ...
;	 9-12  = alignment bits
;	 13-16 = length

LRES_ACT_M32:

; Display the infomation bits

	push	ds:[si+0].ELO	; Pass the flags (low-order 8 bits only)
	push	offset PGROUP:M32_BITTAB ; Pass the table offset
	push	M32_BITTAB_LEN	; Pass the table length
	call	DISP_BITS	; Display 'em

; Display the address min/max base, alignment, and length

	mov	eax,ds:[si+1]	; Get the minimum base address
	lea	di,MSG_LRES_M32A ; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	mov	eax,ds:[si+5]	; Get the maximum base address
	lea	di,MSG_LRES_M32B ; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	mov	eax,ds:[si+9]	; Get the alignment
	lea	di,MSG_LRES_M32C ; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	mov	eax,ds:[si+13]	; Get the length
	lea	di,MSG_LRES_M32D ; ES:DI ==> output save area
	call	DD2HEX		; Convert EAX to hex at ES:DI

	DOSCALL @STROUT,MSG_LRES_M32 ; Display it

	jmp	short DISP_DEV_NODE_LARGE_NEXT ; Join common code


LRES_ACT_RES:
LRES_ACT_IDA:
LRES_ACT_IDU:
LRES_ACT_VEN:
LRES_ACT_MAX:
	call	DISP_DEV_DATA	; Display device node data, at DS:SI, len=DX
DISP_DEV_NODE_LARGE_NEXT:
	sub	cx,RES_LEN	; Subtract from overall count
	add	si,RES_LEN	; Skip over it
DISP_DEV_NODE_EXIT:
	REGREST <edx,bx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DEV_NODE endp		; End DISP_DEV_NODE procedure
	NPPROC	DISP_DEV_DATA -- Display Device Node Data
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:PnPGRP,ss:nothing
COMMENT|

Display device node data

On entry:

DS:SI	==>	data to display
RES_LEN =	# bytes in data

|

	REGSAVE <cx,dx,si>	; Save for a moment

	mov	cx,RES_LEN	; Copy length count
	jcxz	DISP_DEV_DATA_EXIT ; Jump if none

	DOSCALL @STROUT,MSG_RES_DATAHDR ; Display the header
@@:
	lods	ds:[si].LO	; Get next character

	lea	di,MSG_RES_DATA ; ES:DI ==> output save area
	call	DB2HEX		; Convert AL to hex at ES:DI

	DOSCALL @STROUT,MSG_RES_DATA ; Displpay the message

	loop	@B		; Jump if more characters

	DOSCALL @STROUT,MSG_CRLF ; End the line
DISP_DEV_DATA_EXIT:
	REGREST <si,dx,cx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DEV_DATA endp		; End DISP_DEV_DATA procedure
	NPPROC	CVT_EISAID -- Convert Compressed Product ID To ASCII
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:PnPGRP,ss:nothing
COMMENT|

Convert compressed product ID to ASCII

On entry:

EAX	=	compressed product ID

On exit:

PnP_PRODID & PnP_PRODNO filled in.

|

	REGSAVE <eax,ebx>	; Save registers

	mov	ebx,eax 	; Save for a moment
	movzx	eax,ax		; 76543210 76543210 76543210 76543210
				;		    22233333 z1111122
	xchg	al,ah		; 76543210 76543210 76543210 76543210
				;		    .1111122 22233333
	shl	eax,6		; 76543210 76543210 76543210 76543210
				;	   ...11111 22222333 33......
	shr	ax,3		; 76543210 76543210 76543210 76543210
				;	   ...11111 ...22222 33333...
	shr	al,3		; 76543210 76543210 76543210 76543210
				;	   ...11111 ...22222 ...33333
	add	eax,20404040h	; Convert to ASCII
	xchg	al,ah		; 76543210 76543210 76543210 76543210
				;	   ...11111 ...33333 ...22222
	rol	eax,16		; 76543210 76543210 76543210 76543210
				; ...33333 ...22222 ........ ...11111
	xchg	al,ah		; 76543210 76543210 76543210 76543210
				; ...33333 ...22222 ...11111 ........
	shr	eax,8		; 76543210 76543210 76543210 76543210
				; ........ ...33333 ...22222 ...11111
	mov	PnP_PRODID,eax	; Save to inspect

	mov	eax,ebx 	; Get the compressed product #
	shr	eax,16		; Shift down the compressed product #
				; 76543210 76543210 76543210 76543210
				; ........ ........ 33334444 11112222
	shl	eax,8		; 76543210 76543210 76543210 76543210
				; ........ 33334444 11112222 ........
	shr	ax,4		; 76543210 76543210 76543210 76543210
				; ........ 33334444 ....1111 2222....
	shr	al,4		; 76543210 76543210 76543210 76543210
				; ........ 33334444 ....1111 ....2222
	rol	eax,16		; 76543210 76543210 76543210 76543210
				; ....1111 ....2222 ........ 33334444
	shl	ax,4		; 76543210 76543210 76543210 76543210
				; ....1111 ....2222 ....3333 4444....
	shr	al,4		; 76543210 76543210 76543210 76543210
				; ....1111 ....2222 ....3333 ....4444
	push	bx		; Save for a moment

	lea	bx,HEXTAB	; CS:BX ==> translate table

	xlat	HEXTAB[bx]	; Translate next digit
	ror	eax,8		; Rotate in a new digit

	xlat	HEXTAB[bx]	; Translate next digit
	ror	eax,8		; Rotate in a new digit

	xlat	HEXTAB[bx]	; Translate next digit
	ror	eax,8		; Rotate in a new digit

	xlat	HEXTAB[bx]	; Translate next digit
	ror	eax,8		; Rotate in a new digit

	pop	bx		; Restore

	xchg	al,ah		; 76543210 76543210 76543210 76543210
				; ....1111 ....2222 ....4444 ....3333
	rol	eax,16		; 76543210 76543210 76543210 76543210
				; ....4444 ....3333 ....1111 ....2222
	xchg	al,ah		; 76543210 76543210 76543210 76543210
				; ....4444 ....3333 ....2222 ....1111
	mov	PnP_PRODNO,eax	; Save to inspect

	REGREST <ebx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CVT_EISAID endp 		; End CVT_EISAID procedure
	NPPROC	CHECK_DPMI -- Check On DPMI Host
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on DPMI host

On exit:

CF	=	0 if DPMI host present
	=	1 if not

|

	pushad			; Save registers

	push	es		; Save for a moment

	mov	ax,1687h	; Function code to check DPMI presence
	int	2Fh		; Request multiplexor service
				; Return with BX = flags
				;	      CL = processor type
				;	      DX = DPMI version #
				;	      SI = # paras for HPDA
				;	      ES:DI ==> switch entry point
	or	ax,ax		; Izit present?
	mov	ax,es		; Copy new value
	pop	es		; Restore
	assume	es:PGROUP	; Tell the assembler about it
	jnz	near ptr CHECK_DPMI_ERR ; Jump if not

	mov	DPMIDRV_VEC.VOFF,di ; Save for later use
	mov	DPMIDRV_VEC.VSEG,ax ; ...

	mov	ax,PTAIL	; Get next available byte
	add	ax,16-1 	; Round up to para boundary
	shr	ax,4-0		; Convert from bytes to para
	mov	bx,ds		; Copy data segment
	add	ax,bx		; Add to get HPDA segment
	mov	HPDASEG,ax	; Save for later use
	shl	si,4-0		; Convert from paras to bytes
	add	PTAIL,si	; Skip over it

; Enter PM via DPMI

	mov	es,HPDASEG	; ES:0 ==> HPDA
	assume	es:nothing	; Tell the assembler about it

	mov	ax,1		; We're a 32-bit client
	call	DPMIDRV_VEC	; Request entry into PM
	jc	near ptr CHECK_DPMI_EXIT ; Jump if something went wrong (note CF=1)

	mov	ax,ds		; Get PGROUP data selector
	mov	es,ax		; Address it
	assume	es:PGROUP	; Tell the assembler about it

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_DPMI ; Tell 'em we're in PM courtesy of DPMI

; Setup selectors for PnP

	mov	bx,PnP_SEG	; Get PnP struc segment
	DPMICALL @DPMI_SEG2SEL	; Convert segment in BX to selector in AX
	jc	near ptr CHECK_DPMI_EXIT ; Jump on error (note CF=1)

	mov	gs,ax		; Address it
	assume	gs:PnPGRP	; Tell the assembler about it

; Setup the code and data selectors

	mov	eax,OffPnP_PMOFF ; Get offset to PnP_PMOFF
	mov	ax,PnPGRP:[eax] ; Get the PM offset
	mov	PnP_VEC.VOFF,ax ; Save as entry point offset

; Allocate code selector

	mov	cx,1		; # selectors to allocate
	DPMICALL @DPMI_GETLDT	; Allocate selectors
	jc	near ptr CHECK_DPMI_EXIT ; Jump on error (note CF=1)

	mov	PnP_VEC.VSEG,ax ; Save as entry point selector

	mov	bx,ax		; Copy to selector register
	lea	edi,DPMI_LDTE	; ES:EDI ==> DTE
	DPMICALL @DPMI_GETLDTE	; Get LDTE into ES:eDI
	jc	near ptr CHECK_DPMI_EXIT ; Jump on error (note CF=1)

; Set the selector base

	mov	eax,OffPnP_PMCS ; Get offset to PnP_PMCS
	mov	eax,PnPGRP:[eax] ; Get the PM code segment base address

	mov	DPMI_LDTE.DESC_BASE01,ax ; Save as bytes 0-1
	shr	eax,16		; Shift down the high-order word
	mov	DPMI_LDTE.DESC_BASE2,al ; Save as byte 2
	mov	DPMI_LDTE.DESC_BASE3,ah ; ...	       3

; Set the selector limit

	mov	DPMI_LDTE.DESC_SEGLM0,-1 ; Set to 64KB limit
	and	DPMI_LDTE.DESC_SEGLM1,not (mask $SEGLM1) ; ...

; Set the selector A/R byte

	and	DPMI_LDTE.DESC_ACCESS,not ((mask $DT_DC) or (mask $DT_TYP))
	or	DPMI_LDTE.DESC_ACCESS,CPL0_CODE

	DPMICALL @DPMI_SETLDTE	; Set LDTE from ES:eDI
	jc	short CHECK_DPMI_EXIT ; Jump on error (note CF=1)

; Allocate data selector

	mov	cx,1		; # selectors to allocate
	DPMICALL @DPMI_GETLDT	; Allocate selectors
	jc	short CHECK_DPMI_EXIT ; Jump on error (note CF=1)

	mov	PnP_DS,ax	; Save for later use

	mov	bx,ax		; Copy to selector register
	lea	edi,DPMI_LDTE	; ES:EDI ==> DTE
	DPMICALL @DPMI_GETLDTE	; Get LDTE into ES:eDI
	jc	short CHECK_DPMI_EXIT ; Jump on error (note CF=1)

; Set the selector base

	mov	eax,PnPGRP:[0].PnP_PMDS ; Get the PM data segment base address

	cmp	PnPGRP:[0].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F	; Jump if so

	xor	eax,eax 	; No PMDS in old struc
	mov	PnP_DS,ax	; ...
@@:
	mov	DPMI_LDTE.DESC_BASE01,ax ; Save as bytes 0-1
	shr	eax,16		; Shift down the high-order word
	mov	DPMI_LDTE.DESC_BASE2,al ; Save as byte 2
	mov	DPMI_LDTE.DESC_BASE3,ah ; ...	       3

; Set the selector limit

	mov	DPMI_LDTE.DESC_SEGLM0,-1 ; Set to 64KB limit
	and	DPMI_LDTE.DESC_SEGLM1,not (mask $SEGLM1) ; ...

; Set the selector A/R byte

	and	DPMI_LDTE.DESC_ACCESS,not ((mask $DT_DC) or (mask $DT_TYP))
	or	DPMI_LDTE.DESC_ACCESS,CPL0_DATA

	DPMICALL @DPMI_SETLDTE	; Set LDTE from ES:eDI
	jc	short CHECK_DPMI_EXIT ; Jump on error (note CF=1)

	or	LCL_FLAG,@LCL_DPMI ; Mark as in DPMI mode

	clc			; Mark as present

	jmp	short CHECK_DPMI_EXIT ; Join common exit code

CHECK_DPMI_ERR:
	stc			; Mark as not present
CHECK_DPMI_EXIT:
	popad			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DPMI endp 		; End CHECK_DPMI procedure
	FPPROC	TMPINT67 -- Temporary Int 67h handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Before checking for load module SWAT, we need to catch Int 67h
in case we're running an older version of 386MAX with EMS=0.

|

	iret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TMPINT67 endp			; End TMPINT67
	NPPROC	CHECK_SWAT -- Check On SWAT
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on SWAT

|

	pusha			; Save all GP registers
	REGSAVE <es>		; Save

; If the device name for device 386SWAT is present,
; we can safely make the debugger presence call.

	lea	dx,SWTNAME	; Device name for 386SWAT
	call	CHECK_DEV	; Does it exist?
	jc	short CHECK_SWAT1 ; Jump if so

; If 386MAX is present, it could be an older version (pre-7.01.033)
; with EMS=0, where Int 67h is not hooked at all.  If it's load
; module SWAT, we're hooking it in the IDT anyway.

	lea	dx,MAXNAME	; Device name for 386MAX
	call	CHECK_DEV	; Does it exist?
	jnc	short CHECK_SWAT_EXIT ; Jump if not present

	mov	al,67h		; Get current Int 67 vector
	DOSCALL @GETINT 	; ES:BX ==> vector
	assume	es:nothing	; Tell the assembler

	mov	OLDINT67.VSEG,es ; Save previous handler's vector
	mov	OLDINT67.VOFF,bx ; ...

	push	ds		; Save

	push	cs		; Get PGROUP
	pop	ds		; Address for set vector
	assume	ds:PGROUP	; Tell the assembler

	mov	al,67h		; Set Int 67h vector
	DOSCALL @SETINT,TMPINT67 ; Set vector for Int AL to DS:DX

; Determine whether or not load module SWAT is present

	VCPICALL @VCPI_DPRES	; Izit present?

	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler

	REGSAVE <ax,ds> 	; Save return value in AH

	lds	dx,OLDINT67	; DS:DX ==> Previous handler
	assume	ds:nothing	; Tell the assembler

	mov	al,67h		; Set Int 67h vector
	DOSCALL @SETINT 	; Set vector for Int AL to DS:DX

	REGREST <ds,ax> 	; Restore
	assume	ds:PGROUP	; Tell the assembler

	jmp	short CHECK_SWAT2 ; Join common code

CHECK_SWAT1:

; Determine whether or not a resident debugger is present

	VCPICALL @VCPI_DPRES	; Izit present?
CHECK_SWAT2:
	or	ah,ah		; Check for presence
	jnz	short @F	; Jump if not

	mov	VCPIDBG_VER,bx	; BH = major, BL = minor
	or	LCL_FLAG,@LCL_SWAT ; Mark as present
@@:
CHECK_SWAT_EXIT:
	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler

	popa			; Restore all GP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SWAT endp 		; End CHECK_SWAT procedure
	NPPROC	CHECK_VCPI -- Check On VCPI Host
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on VCPI host

On exit:

CF	=	0 if VCPI host is available
	=	1 otherwise.

|

	pushad			; Save all EGP registers
	REGSAVE <es>		; Save register

; First, there must be an EMS provider

	lea	dx,EMMNAME	; Attempt to open the EMS device
	call	CHECK_DEV	; Does it exist?
	jc	short CHECK_VCPI1 ; Jump if present

	lea	dx,EMMNAM2	; Attempt to open the EMS device
	call	CHECK_DEV	; Does it exist?
	jc	short CHECK_VCPI1 ; Jump if present

	lea	dx,EMMNAM3	; Attempt to open the EMS device
	call	CHECK_DEV	; Does it exist?
	jc	short CHECK_VCPI1 ; Jump if present

	lea	dx,EMMNAM4	; Attempt to open the EMS device
	call	CHECK_DEV	; Does it exist?
	jc	short CHECK_VCPI1 ; Jump if present

	lea	dx,EMMNAM5	; Attempt to open the EMS device
	call	CHECK_DEV	; Does it exist?
	jc	short CHECK_VCPI1 ; Jump if present

	lea	dx,MAXNAME	; 386MAX device driver
	call	CHECK_DEV	; Does it exist?
	jnc	near ptr CHECK_VCPI_ERR ; Jump if not - it's another program
CHECK_VCPI1:

; See if there's a VCPI host present

	VCPICALL @VCPI_PRES	; Check on VCPI host
				; Return with AH = 0 if present
				;	 (BH,BL) = version #
	cmp	ah,0		; Izit present?
	jne	near ptr CHECK_VCPI_ERR ; Jump if not

; Read the master and slave IRQ bases

	VCPICALL @VCPI_GIBV	; Return with BX = master base
				; ...	      CX = slave base
	mov	IBV0,bl 	; Save for later use
	mov	IBV1,cl 	; ...
	add	bl,8		; Calculate top value
	add	cl,8		; ...
	mov	IBV0Z,bl	; Save for later use
	mov	IBV1Z,cl	; ...

; Setup for VCPI calls

	xor	ebx,ebx 	; Zero to use as dword
	mov	bx,ds		; Copy data segment
	shl	ebx,4-0 	; Convert from paras to bytes

	movzx	eax,PTAIL	; Get next available offset
	add	eax,ebx 	; Convert from offset to linear address
	add	eax,4*1024-1	; Round up to 4KB
	and	eax,not (4*1024-1) ; ...
	mov	LaCR3,eax	; Save as linear address of CR3 (/4KB)
	add	eax,4*1024	; Skip over CR3
	mov	LaPTE,eax	; Save as linear address of PTEs
	sub	eax,ebx 	; Convert from linear address to offset
	mov	PTAIL,ax	; Protect the CR3

; Get the physical address of the CR3

	mov	ecx,LaCR3	; Get linear address of CR3 (/4KB)

	push	ecx		; Pass linear address as argument
	call	ZERO_PAGE	; Zero the contents of the 4KB page

	shr	ecx,12-0	; Convert from bytes to 4KB
	VCPICALL @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX
	and	dx,mask $PTE_FRM ; Isolate the 4KB frame
	mov	PaCR3,edx	; Save for later use

; Setup PMI

	mov	eax,LaPTE	; Get linear address of PTEs (/4KB)

	push	eax		; Pass linear address as argument
	call	ZERO_PAGE	; Zero the contents of the 4KB page

	shr	eax,4-0 	; Convert from bytes to paras
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	lea	si,LCLGDT.DTE_PMCS ; DS:SI ==> three DTEs for PMI
	xor	di,di		; ES:DI ==> PTEs
	VCPICALL @VCPI_GPMI	; Return with EBX=offset, DI=advanced

	cmp	ah,0		; Check for error
;;;;;;; SETMSG	"Unable to read Protected Mode Interface data",ERR
	jne	near ptr CHECK_VCPI_ERR ; Jump if not OK

	mov	PMI_FVEC.FOFF,ebx ; Save offset of PMI
	mov	PMI_FVEC.FSEL,DTE_PMCS ; Save selector of PMI

	mov	OffNVStoragePTE.ELO,di ; Save as offset in LaPTE of NV Storage PTEs
	add	di,4*16 	; Skip over them

	mov	NEXTPTE.ELO,di	; Save offset of next available PTE

; Make room for PTEs sufficient for two PDIRs

	mov	eax,8*1024*1024 ; Get size of physical memory (including the
				; 1st megabyte)
	shr	eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	add	eax,NEXTPTE	; Skip over existing PTEs

; If SWAT is present, reserve space for it

	test	LCL_FLAG,@LCL_SWAT ; Is SWAT present?
	jz	short @F	; Jump if not

	mov	ecx,eax 	; Copy as maximum size of PTEs
	shl	ecx,(12-2)-0	; Convert from 4KB in dwords to bytes
	mov	LaSWAT,ecx	; Save as new linear address
	add	ecx,4*1024*1024 ; Reserve 4MB for it (we don't know how
				; big it is until much later)
	shr	ecx,(12-2)-0	; Convert from bytes to 4KB in dwords
	mov	eax,ecx 	; Copy as next PTE offset
@@:

; This is the next available offset in bytes after all PTEs

	mov	ecx,eax 	; Copy as maximum size of PTEs
	add	eax,16-1	; Round up to next para
	and	eax,not (16-1)	; ...
	add	PTAIL,ax	; Protect the memory

; Calculate the # PDIRs

	add	ecx,4*1024-1	; Round up to 4KB bonudary
	shr	ecx,12-0	; Convert from bytes to 4KB (# PDIRs)

; Fill in the PDIRs

	mov	eax,LaCR3	; Get linear address of CR3 (/4KB)
	shr	eax,4-0 	; Convert from bytes to paras
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	xor	di,di		; ES:DI ==> PDEs

	mov	ebx,LaPTE	; Get its linear address (/4KB)
	shr	ebx,12-0	; Convert from bytes to 4KB
	push	ecx		; Save for a moment
CHECK_VCPI_NEXT:
	push	ecx		; Save for a moment

	mov	ecx,ebx 	; Copy linear address in 4KB
	VCPICALL @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	pop	ecx		; Restore

	mov	eax,edx 	; Copy to output register
	and	ax,mask $PTE_FRM ; Isolate the 4KB frame
	or	eax,@PTE_URP	; Mark as User/Read-Write/Present
	stos	es:[di].EDD	; Save as next PDE

	inc	ebx		; Skip to next PDE

	loop	CHECK_VCPI_NEXT ; Jump if more PDIRs to fill in

	pop	ecx		; Restore

; Zero the second and subsequent PDIRs

	dec	ecx		; Less the first PDIR (already filled in)
	jz	short CHECK_VCPI_DONE ; Jump if there's only one

	mov	eax,LaPTE	; Get its linear address (/4KB)
	add	eax,4*1024	; Skip over the first PDIR
@@:
	push	eax		; Pass linear address as argument
	call	ZERO_PAGE	; Zero the contents of the 4KB page

	add	eax,4*1024	; Skip to the next PDIR

	loop	@B		; Jump if more PDIRs to zero
CHECK_VCPI_DONE:
	or	LCL_FLAG,@LCL_VCPI ; Mark as using VCPI services to enter PM

	jmp	short CHECK_VCPI_EXIT ; Join common exit code

CHECK_VCPI_ERR:
	stc			; Indicate something went wrong
CHECK_VCPI_EXIT:
	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VCPI endp 		; End CHECK_VCPI procedure
	NPPROC	ZERO_PAGE -- Zero A 4KB Page
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Zero a 4KB page

|

ZP_STR	struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
ZP_LA	dd	?		; Linear address of page to zero

ZP_STR	ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,cx,di,es>	; Save registers

	mov	eax,[bp].ZP_LA	; Get the linear address
	shr	eax,4-0 	; Convert from bytes to paras

	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	xor	di,di		; ES:DI ==> 4KB page to zero
	xor	eax,eax 	; Set to this value
	mov	cx,(4*1024)/4	; # dwords in a 4KB page
    rep stos	es:[di].EDD	; Zero the 4KB page

	REGREST <es,di,cx,eax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	pop	bp		; Restore

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ZERO_PAGE endp			; End ZERO_PAGE procedure
	NPPROC	CHECK_DEV -- Check for device
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return CF=1 if device exists.

On entry:

DS:DX	==>	Device name

On exit:

CF	=	1  Exists and is a device
CF	=	0    Doesn't exist or isn't a device

|

	REGSAVE <ax,bx,dx>	; Save registers

	mov	al,@OPEN_R	; Code for read-only access
	DOSCALL @OPENF2 	; Open it
	jc	short CHECK_DEV_EXIT ; Jump if no luck

	mov	bx,ax		; Save handle

	mov	al,0		; Code to get device info
	DOSCALL @IOCTL2 	; Read device info
	pushf			; Save CF from call
	DOSCALL @CLOSF2 	; Close the file
	popf			; Restore CF
	jc	short CHECK_DEV_EXIT ; Jump if something went wrong

	test	dx,@IOCTL_DEV	; Izit a device?
	jnz	short CHECK_DEV_EXIT ; Jump if so (note CF=0)

	stc			; Not a device
CHECK_DEV_EXIT:
	cmc			; Set CF if success

	REGREST <dx,bx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DEV endp			; End CHECK_DEV procedure
	NPPROC	DISP_BITS -- Display The Bits
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:PnPGRP,ss:nothing
COMMENT|

Display the bits

|

DISP_BITS_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
DISP_BITS_LEN dw ?		; Table length
DISP_BITS_TAB dw ?		; ...	offset
DISP_BITS_FLG dw ?		; Bit flags

DISP_BITS_STR ends

	push	bp	       ; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	pusha			; Save registers

	mov	bx,[bp].DISP_BITS_TAB ; Get offset of the table
	mov	cx,[bp].DISP_BITS_LEN ; Get # entries in ...
DISP_BITS_NEXT:
	mov	si,PGROUP:[bx].BIT_MSK ; Get mask value

	and	si,[bp].DISP_BITS_FLG ; Any matching bits
	jz	short DISP_BITS_LOOP ; Jump if not

	push	cx		; Save for a moment

	mov	cx,PGROUP:[bx].BIT_WID ; Get the mask width
	shr	si,cl		; Shift to low-order
	shl	si,1-0		; Convert from words to bytes

	pop	cx		; Restore

	add	si,PGROUP:[bx].BIT_PTR ; Get the table pointer
	mov	dx,PGROUP:[si]	; DS:DX ==> message

	DOSCALL @STROUT 	; Display it
DISP_BITS_LOOP:
	add	bx,type BIT_STR ; Skip to next table entry

	loop	DISP_BITS_NEXT	; Jump if more table entries

	popa			; Restore

	pop	bp		; Restore

	ret	2+2+2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_BITS endp			; End DISP_BITS procedure
	NPPROC	DB2HEX -- Convert AL to Hex At ES:DI
	assume	ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to hex at ES:DI

On entry:

AL	=	value to convert
ES:DI	==>	output save area

On exit:

ES:DI	==>	byte to right of converted number

|

	push	cx		; Save for a moment
	mov	cx,2		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	cx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	endp			; End DB2HEX procedure
	NPPROC	DW2HEX -- Convert AX to Hex At ES:DI
	assume	ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AX to hex at ES:DI

On entry:

AX	=	value to convert
ES:DI	==>	output save area

On exit:

ES:DI	==>	byte to right of converted number

|


	push	cx		; Save for a moment
	mov	cx,4		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	cx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2HEX	endp			; End DW2HEX procedure
	NPPROC	DD2HEX -- Convert EAX to Hex At ES:DI
	assume	ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert EAX to hex at ES:DI

On entry:

EAX	=	value to convert
ES:DI	==>	output save area

On exit:

ES:DI	==>	byte to right of converted number

|


	push	cx		; Save for a moment
	mov	cx,8		; # hex digits
	call	BIN2HEX_SUB	; Handle by subroutine
	pop	cx		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	endp			; End DD2HEX procedure
	NPPROC	BIN2HEX_SUB
	assume	ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL/AX/EAX to hex at ES:DI

On entry:

AL/AX/EAX=	 value to convert
CX	 =	 # hex digits to convert
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 byte to right of converted number

|


	REGSAVE <ax,bx,edx>	; Save registers

	pushf			; Save flags
	std			; Store backwards

	mov	edx,eax 	; Copy to secondary register
	lea	bx,HEXTAB	; XLAT table
	add	di,cx		; Skip to the end+1
	push	di		; Save to return
	dec	di		; Now the last digit
BIN2HEX_MORE:
	mov	al,dl		; Copy to XLAT register
	and	al,0Fh		; Isolate low-order digit
	xlat	HEXTAB[bx]	; Convert to ASCII hex
	stosb			; Save in output area

	shr	edx,4		; Shift next digit down to low-order

	loop	BIN2HEX_MORE	; Jump if more digits to format

	pop	di		; Restore

	popf			; Restore flags

	REGREST <edx,bx,ax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure
	NPPROC	VMINTFN1 -- VM Interrupt Function #1
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VM interrupt function #1 (SW INTs)

|

	db	@OPCOD_INT
VMINTNO1 db	?		; Interrupt #

	ret		       ; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMINTFN1 endp			; End VMINTFN1 procedure
	NPPROC	VMINTFN2 -- VM Interrupt Function #2
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VM interrupt function #2 (HW INTs)

|

	pushad			; Save all EGP registers

	db	@OPCOD_INT
VMINTNO2 db	?		; Interrupt #

	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMINTFN2 endp			; End VMINTFN2 procedure
	NPPROC	STOREINT -- Store The INT #
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Store the INT # from [bp].INT_ERR into VMINTNO.

On entry:

SS:BP	==>	INT_STR

|

	REGSAVE <ax,es>        ; Save for a moment

	mov	es,CODESEG	; Get segment of PGROUP
	assume	es:PGROUP	; Tell the assembler about it

	mov	al,[bp].INT_ERR ; Get the interrupt #

	cmp	al,IBV0 	; Izit at or above master PIC base?
	jb	short STOREINT1 ; Jump if not

	cmp	al,IBV0Z	; Izit below master PIC top?
	jb	short STOREINT_HW ; Jump if so (it's a HW INT)

	cmp	al,IBV1 	; Izit at or above slave PIC base?
	jb	short STOREINT1 ; Jump if not

	cmp	al,IBV1Z       ; Izit below slave PIC top?
	jb	short STOREINT_HW ; Jump if so (it's a HW INT)
STOREINT1:
	mov	PGROUP:VMINTNO1,al ; Save in INT instruction
	mov	VMINTFN,offset PGROUP:VMINTFN1 ; Save routine addr

	jmp	short STOREINT_EXIT ; Join common exit code

STOREINT_HW:
	mov	PGROUP:VMINTNO2,al ; Save in INT instruction
	mov	VMINTFN,offset PGROUP:VMINTFN2 ; Save routine addr
STOREINT_EXIT:
	REGREST <es,ax> 	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STOREINT endp			; End STOREINT procedure
	FPPROC	INTPROC -- IDT Entries
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IDT entries.

|

INT_STR struc

INT_BP	dw	?		; Caller's BP
	dw	4 dup (?)	; DS, ES, FS, GS
INT_ERR db	?,?		; Interrupt #
INT_EIP dd	?		; ...	   EIP
INT_CS	dw	?,?		; ...	   CS w/filler
INT_EFL dd	?		; ...	   EFL

INT_STR ends

	public	INTPROC_COM
INTPROC_COM:
	REGSAVE <ds,es,fs,gs>	; Save for a moment

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	mov	ds,SEL_DATA	; Get PGROUP data selector
	assume	ds:PGROUP	; Tell the assembler about it

	call	GOVM86		; Return to VM86 mode

; Reflect the interrupt to the appropriate handler

	call	STOREINT	; Store the INT # from [bp].INT_ERR into VMINTNO

	push	ax		; Save for a moment

	mov	ds,DATASEG	; Get segment of PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	mov	es,DATASEG	; Get segment of PGROUP
	assume	es:PGROUP	; Tell the assembler about it

; Get caller's flags
; SS:BP ==>	INT_STR

FLMASKLO =	((mask $NT) or (mask $IOPL) or (mask $TF) or (mask $IF))

	mov	ax,[bp].INT_EFL.ELO ; Get caller's flags
	and	ax,not FLMASKLO ; NT=IOPL=TF=IF=0
	push	ax		; Put into effect
	popf			; ...

	pop	ax		; Restore

	pop	bp		; Restore

	call	VMINTFN 	; Call the appropriate function

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

FLMASKHI =	((mask $VMHI) or (mask $RFHI) or FLMASKLO)

	push	eax		; Save for a moment

	pushfd			; Get the return flags
	pop	eax		; ...
	and	eax,not FLMASKHI ; VM=RF=NT=IOPL=TF=IF=0
	and	[bp].INT_EFL,FLMASKHI ; Isolate
	or	[bp].INT_EFL,eax ; Include

	pop	eax		; Restore

	pop	bp		; Restore

	mov	ds,DATASEG	; Get segment of PGROUP
	assume	ds:PGROUP	; Tell the assembler about it

	mov	es,DATASEG	; Get segment of PGROUP
	assume	es:PGROUP	; Tell the assembler about it

	call	ENTER_PMSUB	; Enter or fail
	assume	ds:PGROUP	; Tell the assembler about it
	assume	gs:AGROUP	; Tell the assembler about it
	jnc	short @F	; Jump if all went OK

	int	03h		; Call our debugger

	jmp	short $ 	; March in place
@@:
	REGREST <gs,fs,es,ds>	; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it
	assume	fs:nothing,gs:nothing ; Tell the assembler about it

	add	sp,2		; Strip error code from stack

	iretd			; Return to caller

LBL	macro	NUM
INTPROC&NUM:
	endm			; LBL

CNT	=	0

	rept	100h		; Define all entries
	LBL	%CNT
	push	CNT
	jmp	INTPROC_COM	; Join common code
CNT	=	CNT+1

	endm

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTPROC endp			; End INTPROC procedure
	NPPROC	GOVM86 -- Switch Into VM86 Mode
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Switch into VM86 mode and continue with the interrupted instruction.

|

	REGSAVE <eax,bx>       ; Save registers

; Return to Virtual Mode

	mov	es,SEL_DATA	; Get PGROUP data selector
	assume	es:PGROUP	; Tell the assembler about it

	mov	eax,esp        ; Copy current ESP

	PUSHD	gs		; GS with filler
	PUSHD	fs		; FS ...
	push	DATASEG.EDD	; DS ...
	push	DATASEG.EDD	; ES ...
	push	DATASEG.EDD	; SS ...
	push	eax		; ESP
	PUSHD	0		; EFL
	push	CODESEG.EDD	; Real mode CS with filler
	lea	eax,GOVM86_PMOFF ; Get return address
	push	eax		; EIP

	push	DTE_4GB 	; Get all memory selector
	pop	ds		; Address it
	assume	ds:nothing	; Tell the assembler about it

	cli			; Exit with IF=0

	mov	ah,@VCPI	; Get major VCPI function code
	mov	al,@VCPI_EPM	; Return to VM86 mode
	call	PMI_FVEC	; Call PMI code
GOVM86_PMOFF:
	assume	ds:PGROUP,es:PGROUP ; Tell the assembler about it

	REGREST <bx,eax>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GOVM86	endp			; End GOVM86 procedure
	NPPROC	ENTER_PM -- Enter Protected Mode
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter protected mode to check memory.

On exit:

CF	=	0 if all went well
	=	1 otherwise

|

	pushad		       ; Save all EGP registers

	mov	fs,CODESEG     ; Setup alias to code segment
	assume	fs:PGROUP      ; Tell the assembler about it

	xor	ax,ax		; Zero register
	mov	fs,ax		; Initialize FS and GS
	assume	fs:nothing	; Tell the assembler about it
	mov	gs,ax
	assume	gs:nothing	; Tell the assembler about it

	push	ds		; Get PGROUP segment
	pop	es		; Address it
	assume	es:PGROUP	; Tell the assembler

	push	es		; Get PGROUP segment
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler

; If SWAT is present, create its PTEs

	call	SETUP_PTE	; Setup SWAT's PTEs

; Setup the GDT entries

	call	SETUP_GDT	; Setup the GDT entries

; Install our own handlers in the new IDT

	call	SETUP_IDT	; Setup the IDT entries

; Enter PM

	call	ENTER_PMSUB	; Enter or fail
	assume	ds:PGROUP	; Tell the assembler about it
	assume	gs:AGROUP	; Tell the assembler about it
	jc	near ptr ENTER_PM_EXIT ; Jump if something went wrong

	push	dword ptr 0	; Ensure IOPL=NT=DF=0
	popfd

	xor	ebp,ebp 	; Ensure the high-order word is zero
				; as there is code which references the
				; stack with EBP.
	sti			; Allow interrupts

	xor	edx,edx 	; Zero to use as dword
	DOSCALL @STROUT,MSG_VCPI ; Tell 'em we're in PM courtesy of VCPI

; Setup PnP PM code segment

	mov	ax,DTE_PnPSTR	; Get selector of
	mov	gs,ax		; Address it
	assume	gs:PnPGRP	; Tell the assembler about it

	mov	eax,OffPnP_PMOFF ; Get offset to PnP_PMOFF
	mov	ax,PnPGRP:[eax] ; Get the PM offset
	mov	PnP_VEC.VOFF,ax ; Save as entry point offset
	mov	PnP_VEC.VSEG,DTE_PnPCS ; ...	      segment

; Note that we can't just PUSH the Dword at PnP_PMCS as MASM 5.10b
; assembles a Word PUSH.

	mov	eax,OffPnP_PMCS ; Get offset to PnP_PMCS
	mov	eax,PnPGRP:[eax] ; Get the PM code segment base address

	push	eax		; Pass the PM code segment base address
	push	CON64K		; Pass length
	push	CPL0_CODE	; Pass access rights byte
	push	DTE_PnPCS	; Pass selector
	call	SET_GDT 	; Set the GDT

; Setup PnP PM data segment

	mov	PnP_DS,DTE_PnPDS ; Save for later use

; Note that we can't just PUSH the Dword at PnP_PMDS as MASM 5.10b
; assembles a Word PUSH.

	mov	eax,PnPGRP:[0].PnP_PMDS ; Get the PM data segment base address

	cmp	PnPGRP:[0].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F	; Jump if so

	xor	eax,eax 	; No PMDS in old struc
	mov	PnP_DS,ax	; ...
@@:
	push	eax		; Pass the PM data segment base address
	push	CON64K		; Pass length
	push	CPL0_DATA	; Pass access rights byte
	push	DTE_PnPDS	; Pass selector
	call	SET_GDT 	; Set the GDT

; Setup PnP NV Storage Base address

	mov	eax,OffNVStoragePTE ; Get offset in LaPTE of NV Storage PTEs
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes

	push	eax		; Pass the PM NV storage segment base address
	push	CON64K		; Pass length
	push	CPL0_DATA	; Pass access rights byte
	push	DTE_PnPNVST	; Pass selector
	call	SET_GDT 	; Set the GDT

	clc			; Indicate we succeeded
ENTER_PM_EXIT:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENTER_PM endp			; End ENTER_PM procedure
	NPPROC	ENTER_PMSUB -- Subroutine To ENTER_PM
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Subroutine to ENTER_PM

On exit:

CF	=	0 if successful
	=	1 otherwise
IF	=	0 if entered from RM

|

	pushad		       ; Save all EGP registers

	mov	PMONSTK_FVEC.FOFF,esp ; Save current ESP

	cli			; Enter with IF=0

	lea	esi,EPMTAB	; Get offset of system tables
	add	esi,LaDATA	; Plus base linear address
	VCPICALL @VCPI_EPM	; Enter Protected Mode
ENTER_PMSUB_PMON:
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing

	cli			; Some VCPI hosts (RM386 comes to mind)
				; start us off with IF=1

; Ensure no interrupts between above VCPICALL and the following LSS

	mov	ds,SEL_DATA	; Get PGROUP data selector
	assume	ds:PGROUP	; Tell the assembler about it

	mov	es,SEL_DATA	; Get PGROUP data selector
	assume	es:PGROUP	; Tell the assembler about it

	lss	esp,PMONSTK_FVEC ; SS:ESP ==> PM stack
	assume	ss:nothing	; Tell the assembler about it

	xor	ax,ax		; A convenient zero
	mov	fs,ax		; Clear selector
	assume	fs:nothing	; Tell the assembler about it

	mov	gs,SEL_4GB	; Get AGROUP data selector
	assume	gs:AGROUP	; Tell the assembler about it

	clc			; Indicate we're successful

	popad		       ; Restore all EGP registers

	ret		       ; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENTER_PMSUB endp		; End ENTER_PMSUB procedure
	NPPROC	SETUP_GDT -- Setup the GDT
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the GDT entries

|

	REGSAVE <eax,ebx,ecx,gs> ; Save registers

	xor	eax,eax 	; Zero entire register
	mov	ax,cs		; Get our data segment
	shl	eax,4-0 	; Convert to paras to bytes
	mov	LaCODE,eax	; Save as our code's linear base address

	xor	eax,eax 	; Zero entire register
	mov	ax,ds		; Get our data segment
	shl	eax,4-0 	; Convert to paras to bytes
	mov	LaDATA,eax	; Save as our data's linear base address

; Setup DTE_CS descriptor to our code segment

	push	LaCODE		; Pass base
	push	CON64K		; Pass length
	push	CPL0_CODE	; Pass access rights byte
	push	DTE_CS		; Pass selector
	call	SET_GDT 	; Set the GDT

; Setup DTE_DS, DTE_ES, and DTE_SS descriptors to our data segment

	push	LaDATA		; Pass base
	push	CON64K		; Pass length
	push	CPL0_DATA	; Pass access rights byte
	push	DTE_DS		; Pass selector
	call	SET_GDT 	; Set the GDT

	push	LaDATA		; Pass base
	push	CON64K		; Pass length
	push	CPL0_DATA	; Pass access rights byte
	push	DTE_ES		; Pass selector
	call	SET_GDT 	; Set the GDT

	push	LaDATA		; Pass base
	push	CON64K		; Pass length
	push	((mask $DTE_B) shl 8) or CPL0_DATA ; Pass access rights byte
	push	DTE_SS		; Pass selector
	call	SET_GDT 	; Set the GDT

; Setup local code alias descriptor

	push	LaCODE		; Pass base
	push	CON64K		; Pass length
	push	CPL0_DATA	; Pass access rights byte
	push	DTE_ALIAS	; Pass selector
	call	SET_GDT 	; Set the GDT

; Setup local all memory descriptor

	push	dword ptr 0	; Pass base
	push	dword ptr 0	; Pass length
	push	CPL0_DATA	; Pass access rights byte
	push	DTE_4GB 	; Pass selector
	call	SET_GDT 	; Set the GDT

; Setup PnP struc segment in BIOS

	movzx	eax,PnP_SEG	; Get segment of the PnP struc
	shl	eax,4-0 	; Convert from paras to bytes

	push	eax		; Pass base
	push	CON64K		; Pass length
	push	CPL0_DATA	; Pass access rights byte
	push	DTE_PnPSTR	; Pass selector
	call	SET_GDT 	; Set the GDT

; Note that we can't setup the PnP PM code and data selectors until
; after we enter PM as the base addresses change over the transition

; Setup DTE_GDT

	lea	ebx,LCLGDT	; Get the GDT offset to linear address
	add	ebx,LaDATA	; Plus our 32-bit linear address of DGROUP
	mov	LCLGDT.DTE_GDT.DTR_BASE,ebx ; Save base
	mov	LCLGDT.DTE_GDT.DTR_LIM,(size XDTE_STR)-1 ; Save limit

; Setup DTE_IDT

	lea	ebx,LCLIDT	; Get the IDT offset to linear address
	add	ebx,LaDATA	; Plus our 32-bit linear address of DGROUP
	mov	LCLGDT.DTE_IDT.DTR_BASE,ebx ; Save base
	mov	LCLGDT.DTE_IDT.DTR_LIM,LCLIDT_LEN-1 ; Save limit

	call	SETUP_TSS	; Setup the TSS

; Setup the structures for PM entry via VCPI
; Setup to Enter and Exit Protected Mode

	call	SETUP_EPM	; Set it up
SETUP_GDT_EXIT:
	REGREST <gs,ecx,ebx,eax> ; Restore
	assume	gs:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_GDT endp			; End SETUP_GDT procedure
	NPPROC	SET_GDT -- Set Global Descriptor Table
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the global descriptor table.

|

SET_GDT_STR struc

	dw	?		; Caller's BP
	dw	?		; Caller's IP
SET_GDT_DTE dw	?		; DTE to set
SET_GDT_ARB db	?		; Access rights byte
SET_GDT_FLG db	?		; DTE flags
SET_GDT_LEN dd	?		; Segment length
SET_GDT_BAS dd	?		; Segment base

SET_GDT_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <eax,bx,ecx>	; Save registers

	pushf			; Save flags
	cli			; Disallow interrupts

	mov	eax,[bp].SET_GDT_BAS ; Get segment base
	mov	ecx,[bp].SET_GDT_LEN ; Get segment length
	dec	ecx		; Convert from length to limit

	cmp	ecx,CON1M	; Check against limit limit
	jb	short @F	; Jump if within range

	shr	ecx,12-0	; Convert from bytes to 4KB
	or	ecx,(mask $DTE_G) shl 16 ; Set G-bit
@@:
	mov	bx,[bp].SET_GDT_DTE ; Get the DTE to set

	mov	LCLGDT.DESC_BASE01.EDD[bx],eax
	rol	eax,8		; Rotate out the high-order byte
	mov	LCLGDT.DESC_BASE3[bx],al ; Save as base byte #3
	ror	eax,8		; Rotate back
	mov	LCLGDT.DESC_SEGLM0[bx],cx ; Save as data limit
	rol	ecx,16		; Swap high- and low-order words
	or	cl,[bp].SET_GDT_FLG ; Include any flags
	mov	LCLGDT.DESC_SEGLM1[bx],cl ; Save as data limit
;;;;;;; ror	ecx,16		; Swap back

; Set access rights byte

	mov	al,[bp].SET_GDT_ARB ; Get it
	mov	LCLGDT.DESC_ACCESS[bx],al ; Set it

	popf			; Restore flags

	REGREST <ecx,bx,eax>	; Restore

	pop	bp		; Restore

	ret	2*2+2*4 	; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_GDT endp			; End SET_GDT procedure
	NPPROC	SETUP_TSS --  Setup The TSS
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the TSS for EPM

|

	REGSAVE <eax>		; Save register

; Setup local TSS descriptor

	lea	eax,LCLTSS	; Get local TSS address
	add	eax,LaDATA	; Convert from relative to absolute

	push	eax		; Pass base
	push	dword ptr (size TSS_STR) ; Pass length
	push	CPL0_IDLE3	; Pass access rights byte
	push	DTE_TSS 	; Pass selector
	call	SET_GDT 	; Set the GDT

; We should never use the PL0 stack, but let's set it up anyway

	mov	LCLTSS.TSS_ESP0,offset ds:PMSTKZ
	mov	LCLTSS.TSS_SS0,DTE_SS

	mov	eax,PaCR3	; Get CR3 physical address
	mov	LCLTSS.TSS_CR3,eax ; Save in TSS

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_TSS endp			; End SETUP_TSS procedure
	NPPROC	SETUP_EPM -- Setup to Enter and Exit Protected Mode
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup to enter and exit protected mode.

|

	REGSAVE <eax>		; Save register

; Setup our own CR3

	mov	eax,PaCR3	; Get CR3 physical address
	mov	EPMTAB.EPM_CR3,eax ; Save in EPMTAB

; Setup pointer to local GDT

	lea	eax,LCLGDT.DTE_GDT ; Get pointer
	add	eax,LaDATA	; Plus linear address of data segment
	mov	EPMTAB.EPM_GDTP,eax ; Save it

; Setup pointer to local IDT

	lea	eax,LCLGDT.DTE_IDT ; Get pointer
	add	eax,LaDATA	; Plus linear address of data segment
	mov	EPMTAB.EPM_IDTP,eax ; Save it

; Setup local LDT and TR

	mov	EPMTAB.EPM_LDTR,0 ; Don't use one
	mov	EPMTAB.EPM_TR,DTE_TSS ; Use local one

; Setup return address

	mov	EPMTAB.EPM_EXIT.FOFF,offset cs:ENTER_PMSUB_PMON
	mov	EPMTAB.EPM_EXIT.FSEL,DTE_CS ; Save our code selector

	REGREST <eax>		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_EPM endp			; End SETUP_EPM procedure
	NPPROC	SETUP_IDT -- Setup IDT Entries
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup IDT entries

|

	pushad			; Save all EGP registers

	test	LCL_FLAG,@LCL_SWAT ; Is SWAT present?
	jz	short SETUP_IDT_XDBG ; Jump if not

; Tell SWAT about our new CR3 and linear address
; if we're entering PM via VCPI
; Note that we don't want to use the VCPIBACK macro here, as
; SWAT hooks Int 67h out of the IDT.

	mov	edx,LaSWAT	; Get new linear address
	mov	ebx,PaCR3	; Get new CR3 physical address
	VCPICALL @VCPI_DBGLIN	; Set new CR3 and linear address

	or	ah,ah		; Check for presence
;;;;;;; SETMSG	"Error on debugger set CR3 and linear address",ERR
	jnz	near ptr SETUP_IDT_ERR ; Jump if in error
@@:

; Initialize debugger GDT entries

	lea	di,LCLGDT.DTE_SWAT ; ES:DI ==> 1st debugger GDT entry
	mov	bx,DTE_SWAT	; Get initial selector
	VCPICALL @VCPI_DBGINI	; Initialize the GDT entries

	or	ah,ah		; Check for presence
;;;;;;; SETMSG	"Error on debugger GDT initialization",ERR
	jnz	near ptr SETUP_IDT_ERR ; Jump if in error

; Initialize the debugger's IDT entries

	xor	bx,bx		; Initial interrupt #
	mov	cx,20h		; # interrupt #s
	lea	di,LCLIDT	; ES:DI ==> initial IDT entry
	mov	edx,PaCR3	; Get physical address of CR3
SETUP_IDT_DBGNEXT:
	VCPICALL @VCPI_DBGIDT	; Initialize an IDT entry

	cmp	ah,83h		; Check for invalid interrupt #
	je	short @F	; Jump if so

	or	ah,ah		; Check for presence
;;;;;;; SETMSG	"Error on debugger GDT initialization",ERR
	jnz	near ptr SETUP_IDT_ERR ; Jump if in error
@@:
	inc	bx		; Skip to next interrupt #
	add	di,size IDT_STR ; Skip to next IDT entry

	loop	SETUP_IDT_DBGNEXT ; Jump if more interrupt #s
SETUP_IDT_XDBG:
SETUP_IDT_ERR:
SETUP_IDT_EXIT:
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_IDT endp			; End SETUP_IDT procedure
	NPPROC	SETUP_PTE -- Setup SWAT PTEs
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup SWAT PTEs if the debugger interface version is 4.0 or higher.

|

	pushad		       ; Save all EGP registers
	REGSAVE <es>	       ; Save register

	test	LCL_FLAG,@LCL_SWAT ; Is SWAT present?
	jz	short SETUP_PTE_EXIT ; Jump if not

; If we're not entering PM via VCPI, there are no PTEs for us to use.
; If we're starting from RM, there's no need to setup SWAT's
;   PTEs as it used topdown INT 15h to allocate itself.
; If we're entering PM via DPMI, we don't have our own PTEs.

; If we can't setup old SWAT's PTEs, turn off all debugging support

	cmp	VCPIDBG_VER,0400h ; Does it support function F9?
	jb	short SETUP_PTE_NOSWAT ; Jump if not

; Get and round down the base address to a 4KB boundary

	mov	edi,LaSWAT	; Get linear address of SWAT
	and	di,not (4*1024-1) ; Round down to 4KB boundary

; Convert the linear address to offset into the PDIR

	shr	edi,(12-2)-0	; Convert from bytes to 4KB in dwords
	add	edi,LaPTE	; Plus linear address of the PTEs (/4KB)

	xor	ax,ax		; A convenient zero
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

; Request that SWAT fill in the PTEs

	mov	ecx,-1		; Fill in as many as it wants
	VCPICALL @VCPI_FILLPTE	; Fill in ECX PTEs into ES:EDI

	or	ah,ah		; Check for presence
;;;;;;; SETMSG	"Error on debugger fill PTE",ERR
	jz	short SETUP_PTE_EXIT ; Jump if all went well
SETUP_PTE_NOSWAT:
	and	LCL_FLAG,not @LCL_SWAT ; No SWAT today
SETUP_PTE_EXIT:
	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_PTE endp			; End SETUP_PTE procedure

CODE	ends			; End CODE segment

	MEND	TESTPnP 	; End TESTPnP module

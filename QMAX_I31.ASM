;' $Header:   P:/PVCS/MAX/386MAX/QMAX_I31.ASV   1.3   30 May 1997 10:44:54   BOB  $
	 title	 QMAX_I31 -- 386MAX INT 31h Handler
	 page	 58,122
	 name	 QMAX_I31

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-8 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Program segment DEBUG, byte-aligned,  public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Data    segment VALSEG,byte-aligned,  public, class 'edata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'
	       Group IGROUP:
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'
	       Data    segment ACTSEG,word-aligned,  public, class 'idata'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Group DL2GROUP:
	       Program segment DL2CODE, para-aligned, public, class 'dl2code'
	       Data    segment DL2DATA, word-aligned, public, class 'dl2code'
	       Data    segment DL2DATZ, dword-aligned, public, class 'dl2code'

Program derived from:  None.

Original code by:  William R. Lewis, April, 1991.
		   Additional code by BOB.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include DOSCALL.INC
	 include VIDCALL.INC
	 include ASCII.INC
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include ALLMEM.INC
	 include OPCODES.INC
	 include MAC.INC
	 include DPMI.INC
	 include DOSERR.INC
	 include MASM5.MAC
	 include INTVEC.INC
	 include MAXDEV.INC
	 include CPUFET.INC

	 include QMAX_OEM.INC
	 include QMAX_DTE.INC
	 include QMAX_DYN.INC
	 include QMAX_EMM.INC
	 include QMAXDPMI.INC
	 include QMAX_I31.INC
	 include QMAX_TSS.INC
	 include QMAX_VMM.INC
.list

if @OEM_DPMI

PGROUP	 group	 CODE,HICODE,ECODE,DEBUG,EDATA,VALSEG
FGROUP	 group	 FDATA
IGROUP	 group	 LDATA,ICODE,IDATA,ACTSEG
JGROUP	 group	 JCODE
DL2GROUP group	 DL2CODE,DL2DATA,DL2DATZ
PSPGRP	 group	 PSPSEG


PSPSEG	 segment use16 at 0	; Start PSPSEG segment
	 assume  ds:PSPGRP

	 extrn	 PSP_ENVIR_PTR:word
	 extrn	 PSP_TERMINATE:dword

PSPSEG	 ends			; End PSPSEG segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 XMS_FLAG:word	; **BOTH** high and low memory
	 include QMAX_XMS.INC

	 extrn	 MSC_FLAG:word
	 include QMAX_MSC.INC

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 EXITRCHI:word

HICODE	 ends			; End HICODE segment


DL2DATA  segment use16 word public 'dl2code' ; Start DL2DATA segment
	 assume  ds:DL2GROUP

	 public  DL2_PMERET,DL2_PGRSEG
DL2_PMERET dd	 ?		; Return from call to protected mode entry
DL2_PGRSEG dw	 ?		; High DOS segment for PGROUP

DL2DATA  ends			; End DL2DATA segment


DL2CODE  segment use16 para public 'dl2code' ; Start DL2CODE segment
	 assume  cs:DL2GROUP

if @OEM_DPMI
	 NPPROC  GENINT23 -- Act on Int 23
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Act on Int 23 if Ctrl-Break detected during DPMI client's backing store
initialization.  We detect the Int 23 and ignore it while initializing
the swap file, but abort client initialization.  We'll return here from
protected mode via IRETD, then call the current Int 23 handler.  If CF=1
(abort) we'll set the flag in QMAX_OVR to return our own value for function
4D (we want to return 0300 - terminated via Ctrl-C) and terminate with
function 4C.  Otherwise, we'll IRET to the code following the call to
the protected mode entry point.

|

	 clc			; Assume we'll ignore it
	 int	 23h		; Call current Ctrl-Break handler
	 jc	 short @F	; Jump if we need to abort program

; Ignore Ctrl-C; return to instruction following far call to protected mode
; entry point with CF=1 and AX=8014 (insufficient backing store).
	 mov	 ax,@DERR_INSUFF_BACK ; This is the only error message
				; related to backing store.
	 stc			; Indicate error

	 jmp	 DL2_PMERET	; Note that stack is already set up for return

@@:
	 push	 ds		; Save for a moment

; Set return code to 0300 via high DOS function 4D hook
	 mov	 ds,DL2_PGRSEG	; Address PGROUP in high DOS
	 assume  ds:PGROUP	; Tell the assembler

	 or	 MSC_FLAG,mask $MSC_GETRC ; Lie about return code on next fn 4D
	 mov	 EXITRCHI,0300h ; Terminated via Ctrl-C

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler

	 mov	 al,0		; No return code
	 DOSCALL @EXITRC	; Terminate with return code AL

	 int	 20h		; In case it's DOS 4...

	 assume  ds:nothing,es:nothing,ss:nothing

GENINT23 endp			; End GENINT23 procedure
endif				; IF @OEM_DPMI

DL2CODE  ends			; End DL2CODE segment


DL2DATZ  segment use16 dword public 'dl2code' ; Start DL2DATZ segment
	 assume  ds:DL2GROUP

	 extrn	 DL2GROUP_END:word

DL2DATZ  ends			; End DL2DATZ segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 LDT_SIZ:dword
	 extrn	 XLDT_SIZ:dword
	 extrn	 DESC_TAB:qword
	 extrn	 IDT_DESC:qword
	 extrn	 SEL_DS3:word
	 extrn	 SEL_DSFG3:word
	 extrn	 SEL_DSJG3:word
	 extrn	 SEL_4GB:word
	 extrn	 SEL_4GB3:word
	 extrn	 HMASIZE:dword
	 extrn	 LAST_INTCOM:dword
	 extrn	 LAST_INTFLG:dword
	 extrn	 LPMSTK_CNT:dword
	 extrn	 LPMSTK_SIZ:dword
	 extrn	 LPMSTK_FVEC:fword
	 extrn	 CON64KB:dword

	 extrn	 DPMI_CPIHOOK:byte

	 extrn	 LaSIRBCUR:dword
	 extrn	 CPUFET_FLAG:dword

	 extrn	 PPL0STK_ERR:dword
	 extrn	 PPL0STK_NRM:dword
	 extrn	 PPL0STK_DERR:dword
	 extrn	 PPL0STK_DNRM:dword
	 extrn	 PPL0STK_MIN:dword
	 extrn	 PPL0STK_MAP:dword

	 extrn	 PVMTSS:dword
	 extrn	 PCURTSS:dword
	 extrn	 PPRMTSS:dword

	 extrn	 MSG_APPLNAME:tbyte

	 extrn	 VMCREGS:tbyte

	 extrn	 TSRsize:word
if @OEM_VIRTUALMEM
	 extrn	 VMM_FLAG:word
	 extrn	 NOSWAP_CNT:word
endif
;;;;;;;; extrn	 MINBASE:dword
;;;;;;;; extrn	 TOPBASE:dword

	 public  I31_FLAG,PDC_FLAG
I31_FLAG dw	 0		; INT 31h flags (mapped by I31_REC)
PDC_FLAG dw	 0		; Per DPMI Client flags (mapped by I31_REC)

	 public  VM2PM_PSP,VM2PM_DTAVEC,VM2PM_TSS,VM2PM_ERR
VM2PM_PSP dw	 ?		; Caller's PSP
VM2PM_DTAVEC dd  ?		; Temporary save area for caller's DTA
VM2PM_TSS dw	 DTE_TSS	; Current TSS selector
VM2PM_ERR dw	 ?		; Error code if we terminate

	 public  DPM_FLAG
DPM_FLAG dw	 0		; DPMI debugging flags

	 public  EXITRC
EXITRC	 dw	 @EXITRC shl 8	; DOS function code to exit with code

; Note that comparisons against the DPMITYPE byte should *ALMOST ALWAYS*
; be made with @DPMITYPE16.  That way, we treat the "no DPMI client"
; (i.e. MAX's use of these services) case as 32-bit

	 public  CPUTYPE,DPMITYPE
CPUTYPE  db	 03h		; CPU type (02 = 286, 03 = 386, 04 = 486, etc.)
DPMITYPE db	 @DPMITYPEXX	; DPMI client type:
				; 0 = 16-bit
				; 1 = 32-bit
				; 2 = no DPMI clients active

	 public  DPMI_CODE,DPMI_DATA,DPMI_IDEF,DPMI_CPL,DPMI_DPL
DPMI_CODE dw	 CPL0_CODE or (@DPMI_CPL shl $DT_DPL) ; A/R byte for DPMI code
DPMI_DATA dw	 CPL0_DATA or (@DPMI_CPL shl $DT_DPL) ; ...		  data
DPMI_IDEF dw	 DTE_DPMIDEF or (@DPMI_CPL shl $PL)   ; Interrupt selector
DPMI_CPL  db	 @DPMI_CPL shl $PL     ; DPMI CPL
DPMI_DPL  db	 @DPMI_CPL shl $DT_DPL ; DPMI DPL

	 public  HPDASTK_SIZ,HPDABUF_SIZ,HPDAVMC_CNT
HPDASTK_SIZ dw	 @HPDASTK_DEF	; Size of HPDA stack  in bytes
HPDABUF_SIZ dw	 @HPDABUF_DEF	; Size of HPDA buffer in bytes
HPDAVMC_CNT dw	 @HPDAVMC_DEF	; # HPDA VM callbacks

@HPDASTK_OFF equ (4*(((4-1)+(size HPDA_STR))/4)) ; Default HPDA stack bottom

	 public  HPDASTK_OFF,HPDASTK_TOP,HPDABUF_OFF,HPDAVMC_OFF,HPDA_NPAR
SOF	 =	 @HPDASTK_OFF	; Size so far
HPDASTK_OFF dw	 SOF		; Offset of local stack in HPDA
SOF	 =	 SOF + @HPDASTK_DEF ; Plus size of default stack
HPDASTK_TOP dw	 SOF		; Offset of top of local HPDA stack
HPDABUF_OFF dw	 SOF		; Offset of local HPDA buffer
SOF	 =	 SOF + @HPDABUF_DEF ; Plus size of default buffer
HPDAVMC_OFF dw	 SOF		; Offset of local VM callback structures
SOF	 =	 SOF + (@HPDAVMC_DEF * (size HPDAVMC_STR)) ; Plus size of default VM callback strucs
HPDA_NPAR dw	 ((16-1)+SOF)/16 ; # paras in HPDA

	 public  DPMIDYN_SIZ,DPMIHNDL_CNT,DPMIPDIR_CNT,DPMIHNDL_SIZ,DPMIHNDL_OFF
	 public  DPMIPDIR_OFF,LaDPMIPDIR,LaDPMIPDIRMEM
	 align	 4		; Ensure dword-aligned
DPMIDYN_SIZ dd	 @DPMIDYN_DEF	; Size of dynamic save area
DPMIHNDL_CNT dd  @DPMIHNDL_DEF	; Initial # DPMI memory handles
@DPMIHNDL_SIZ equ @DPMIHNDL_DEF*(type DPMIHNDL_STR)
@DPMIHNDL_RND equ (@DPMIHNDL_SIZ+(@DPMI_BOUND-1)) and (not (@DPMI_BOUND-1))
DPMIHNDL_SIZ dd  @DPMIHNDL_RND	; Initial byte size of DPMI memory handle table
				; /@DPMI_BOUND
DPMIPDIR_CNT dd  @DPMIPDIR_DEF	; # DPMI page directories for phys-to-lin mappings
DPMIHNDL_OFF dd  ?		; Offset in PGROUP of initial resident DPMI
				; memory handle structure
DPMIPDIR_OFF dd  ?		; Offset in PGROUP of page directories
LaDPMIPDIR dd	 ?		; Linear address of the first DPMI page
				; directory (/4KB)
LaDPMIPDIRMEM dd ?		; Linear address of the memory mapped by the
				; first DPMI page directory (/4MB)

	 public  DPMIOLDPM_SIZ
DPMIOLDPM_SIZ dd ?		; Size of old PM data area

	 public  LPMSTK_SEL
LPMSTK_SEL dw	 LDTE_DATALPM3	; Default LPM stack selector

EDATA	 ends			; End EDATA segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MSG_DPMIAPPLNAME:tbyte

FDATA	 ends			; End FDATA segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 public  ISEL_DSIG3,ISEL_DS3,ISEL_4GB3
ISEL_DSIG3 dw	 DTE_DSIG  or (@DPMI_CPL shl $PL) ; IGROUP data selector at DPMI CPL
ISEL_DS3   dw	 DTE_DS3   or (@DPMI_CPL shl $PL) ; PGROUP data selector at DPMI CPL
ISEL_4GB3  dw	 DTE_D4GB3 or (@DPMI_CPL shl $PL) ; AGROUP data selector at DPMI CPL

LDATA	 ends			; End LDATA segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

	 extrn	 BSTotal:dword
	 extrn	 BSGTotal:dword

; Note that comparisons against the DPMITYPEIG byte should *ALMOST ALWAYS*
; be made with @DPMITYPE16.  That way, we treat the "no DPMI client"
; (i.e. MAX's use of these services) case as 32-bit

	 public  DPMITYPEIG
DPMITYPEIG db	 @DPMITYPEXX	; DPMI client type:  (same as DPMITYPE)

IDATA	 ends			; End IDATA segment



; Define DPMI functions which we handle

DPMIMAC  macro	 VAL,ACT,EXT

VALSEG	 segment use16 byte public 'edata' ; Start VALSEG segment
	 assume  ds:PGROUP

VALORG	 =	 ((VAL and (mask $MAXDFN_HI)) shr (width $MAXDFN_MD)) or (VAL and (mask $MAXDFN_LO))

	 org	 DPMI_VAL+VALORG
	 db	 NXTDFN 	; Fill with next DPMI function code
	 org	 DPMI_VALZ	; back to the ending byte

NXTDFN	 =	 NXTDFN+(type DPMI_ACT) ; Skip to next DPMI function code

VALSEG	 ends			; End VALSEG segment


ACTSEG	 segment use16 word public 'idata' ; Start ACTSEG segment
	 assume  ds:IGROUP

	 dw	 IGROUP:DPMI_&ACT

ACTSEG	 ends			; End ACTSEG segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 extrn	 DPMI_&ACT:near

ICODE	 ends			; End ICODE segment

	 endm			; DPMIMAC


VALSEG	 segment use16 byte public 'edata' ; Start VALSEG segment
	 assume  ds:PGROUP

; Pack the DPMI function code into a hash via the $MAXDFN_xx record
; where we delete the $MAXDFN_MD section.

@MAXDFN  equ	 0E01h		; Maximum DPMI function code

MAXDFN_REC record $MAXDFN_HI:4,$MAXDFN_MD:3,$MAXDFN_LO:5

@MAXDVAL equ	 (@MAXDFN shr (width $MAXDFN_MD)) or \
		 (@MAXDFN and (mask $MAXDFN_LO))

	 public  DPMI_VAL
DPMI_VAL db	 (@MAXDVAL-1) dup (00h) ; Fill with Invalid Function code
DPMI_VALZ label  byte

VALSEG	 ends			; End VALSEG segment


ACTSEG	 segment use16 word public 'idata' ; Start ACTSEG segment
	 assume  ds:IGROUP

	 public  DPMI_ACT
DPMI_ACT dw	 IGROUP:INT31_ERR_NOFNS ; Seed with Invalid Function entry

ACTSEG	 ends			; End ACTSEG segment


NXTDFN	 =	 type DPMI_ACT	; Initialize next DPMI function code
				; after the Invalid Function entry

; LDT Descriptor Management Services

	 DPMIMAC 0000h,GETLDT	  ; [0.9] Allocate LDT selectors
	 DPMIMAC 0001h,RELLDT	  ; [0.9] Free an LDT selector
	 DPMIMAC 0002h,SEG2SEL	  ; [0.9] Convert Segment to Selector
	 DPMIMAC 0003h,NXTSEL	  ; [0.9] Get next selector increment value
	 DPMIMAC 0004h,LOCKSEG	  ; [0.8] Lock Linear Region using selector
	 DPMIMAC 0005h,LOCKSEG	  ; [0.8] Unlock Linear Region using selector
	 DPMIMAC 0006h,GSELBAS	  ; [0.9] Get selector base address
	 DPMIMAC 0007h,SSELBAS	  ; [0.9] Set selector base address
	 DPMIMAC 0008h,SSELLIM	  ; [0.9] Set selector limit
	 DPMIMAC 0009h,SSELARW	  ; [0.9] Set selector A/R word
	 DPMIMAC 000Ah,GETALIAS   ; [0.9] Get selector alias
	 DPMIMAC 000Bh,GETLDTE	  ; [0.9] Get LDT entry
	 DPMIMAC 000Ch,SETLDTE	  ; [0.9] Set LDT entry
	 DPMIMAC 000Dh,GETRLDT	  ; [0.9] Allocate reserved LDT selector
	 DPMIMAC 000Eh,GETMLDTE   ; [1.0] Get multiple LDT entries		   1.0
	 DPMIMAC 000Fh,SETMLDTE   ; [1.0] Set multiple LDT entries		   1.0

; DOS Memory Management Services

	 DPMIMAC 0100h,GETDMEM	  ; [0.9] Allocate DOS memory block
	 DPMIMAC 0101h,RELDMEM	  ; [0.9] Free DOS memory block
	 DPMIMAC 0102h,MODDMEM	  ; [0.9] Resize DOS memory block

; Interrupt Management Services

	 DPMIMAC 0200h,GETVMIV	  ; [0.9] Get VM interrupt vector
	 DPMIMAC 0201h,SETVMIV	  ; [0.9] Set VM interrupt vector
	 DPMIMAC 0202h,GETPEHV	  ; [0.9] Get processor exception handler vector
	 DPMIMAC 0203h,SETPEHV	  ; [0.9] Set processor exception handler vector
	 DPMIMAC 0204h,GETPMIV	  ; [0.9] Get protected mode interrupt vector
	 DPMIMAC 0205h,SETPMIV	  ; [0.9] Set protected mode interrupt vector
	 DPMIMAC 0210h,GETPEHV	  ; [1.0] Get extended PM proc exception handler
	 DPMIMAC 0211h,GETEVMPEHV ; [1.0] Get extended VM proc exception handler
	 DPMIMAC 0212h,SETPEHV	  ; [1.0] Set extended PM proc exception handler
	 DPMIMAC 0213h,SETEVMPEHV ; [1.0] Set extended VM proc exception handler

	 DPMIMAC 0900h,INTCLI	  ; [0.9] Get & Disable Virtual Interrupt State
	 DPMIMAC 0901h,INTSTI	  ; [0.9] Get & Enable Virtual Interrupt State
	 DPMIMAC 0902h,GETIF	  ; [0.9] Get Virtual Interrupt State

; Translation Services

	 DPMIMAC 0300h,SIMVMI	  ; [0.9] Simulate VM interrupt
	 DPMIMAC 0301h,SIMVMCFR   ; [0.9] Simulate VM call with far return
	 DPMIMAC 0302h,SIMVMCIR   ; [0.9] Simulate VM call with IRET return
	 DPMIMAC 0303h,GETVMCB	  ; [0.9] Allocate VM callback address
	 DPMIMAC 0304h,RELVMCB	  ; [0.9] Free VM callback address
	 DPMIMAC 0305h,GETSSR	  ; [0.9] Get State Save/Restore addresses
	 DPMIMAC 0306h,GETRMS	  ; [0.9] Get Raw Mode Switch addresses

; Extended Memory Management Services

	 DPMIMAC 0500h,GETFMI	  ; [0.9] Get Free Memory Information
	 DPMIMAC 0501h,GETMEM	  ; [0.9] Allocate Memory Block
	 DPMIMAC 0502h,RELMEM	  ; [0.9] Free Memory Block
	 DPMIMAC 0503h,MODMEM	  ; [0.9] Resize Memory Block
	 DPMIMAC 0504h,GETLMB	  ; [1.0] Allocate Linear Memory Block
	 DPMIMAC 0505h,MODLMB	  ; [1.0] Resize Linear Memory Block
	 DPMIMAC 0506h,GPGATTR	  ; [1.0] Get Page Attributes
	 DPMIMAC 0507h,SPGATTR	  ; [1.0] Set Page Attributes
	 DPMIMAC 0508h,MAPDEV	  ; [1.0] Map Device in Memory Block
	 DPMIMAC 0509h,MAPCONV	  ; [1.0] Map Conventional Memory in Memory Block
	 DPMIMAC 050Ah,GETMBLKSZ  ; [1.0] Get Memory Block Size & Base
	 DPMIMAC 050Bh,GETMEMI	  ; [1.0] Get Memory Information

	 DPMIMAC 0800h,GETP2L	  ; [0.9] Get Physical to Linear Address Mapping
	 DPMIMAC 0801h,RELP2L	  ; [1.0] Free Physical to Linear Address Mapping

	 DPMIMAC 0D00h,GETSHR	  ; [1.0] Allocate Shared Memory
	 DPMIMAC 0D01h,RELSHR	  ; [1.0] Free Shared Memory
	 DPMIMAC 0D02h,SERIALIZE  ; [1.0] Serialize on Shared Memory
	 DPMIMAC 0D03h,RELSERIAL  ; [1.0] Free Serialization on Shared Memory

; Page Management Services

	 DPMIMAC 0600h,LOCKLINREG ; [0.9] Lock Linear Region
	 DPMIMAC 0601h,UNLKLINREG ; [0.9] Unlock Linear Region
	 DPMIMAC 0602h,PAGEVM	  ; [0.9] Mark VM Region as Pageable
	 DPMIMAC 0603h,RLCKVM	  ; [0.9] Relock VM Region
	 DPMIMAC 0604h,GETPAGESIZ ; [0.9] Get Page Size

	 DPMIMAC 0700h,PGSELUNLK  ; [0.8] Mark Selector as Pageable
	 DPMIMAC 0701h,PGSELFREE  ; [0.8] Mark Selector as Discardable
	 DPMIMAC 0702h,PGUNLK	  ; [0.9] Mark Page as Pageable
	 DPMIMAC 0703h,PGFREE	  ; [0.9] Mark Page as Discardable

; Debug Support Services

	 DPMIMAC 0B00h,DBGSET	  ; [0.9] Set Debug Watchpoint
	 DPMIMAC 0B01h,DBGCLR	  ; [0.9] Clear Debug Watchpoint
	 DPMIMAC 0B02h,DBGQRY	  ; [0.9] Query State of Debug Watchpoint
	 DPMIMAC 0B03h,DBGRST	  ; [0.9] Reset Debug Watchpoint

; Miscellaneous Services

	 DPMIMAC 0400h,GETVER	  ; [0.9] Get Version Information
	 DPMIMAC 0401h,GETCAP	  ; [1.0] Get DPMI Capabilities

	 DPMIMAC 0A00h,VSAPI	  ; [0.9] Get Vendor-Specific API Entry Point

	 DPMIMAC 0C00h,TSRSRV	  ; [1.0] Install Resident Service Provider CB
	 DPMIMAC 0C01h,TSRXIT	  ; [1.0] Terminate & Stay Resident

	 DPMIMAC 0E00h,EMUGET	  ; [1.0] Get Coprocessor Status
	 DPMIMAC 0E01h,EMUSET	  ; [1.0] Set Coprocessor Emulation


DEBUG	 segment use16 byte public 'ecode' ; Start DEBUG segment
	 assume  cs:PGROUP

	 extrn	 DD2HEX:near

DEBUG	 ends			; End DEBUG segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_I31_ECODE
@QMAX_I31_ECODE:		; Mark module start in .MAP file

	 extrn	 WRAP_DISABLE:near
	 extrn	 WRAP_ENABLE:near
	 extrn	 DISP_STR:near
	 extrn	 EMM_EXIT:near
	 extrn	 INTPROC00Z:near
	 extrn	 INTPROC31:near
	 extrn	 SET_PPL0STK:near
	 extrn	 ALLOCMEM:near
	 extrn	 DEALLOCMEM:near
	 extrn	 APPEND_EXT:near
	 extrn	 CHECK_HOOK:near

	 FPPROC  FDISP_STR -- Display A String Through INT 10h
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to DISP_STR

On entry:

Same as for DISP_STR but the arguments are on the stack.

On exit:

Same as for DISP_STR

|

FDS_STR  struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   CS:IP
FDS_VEC  dd	 ?		; ES:SI ==> string to display

FDS_STR  ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <si,es>	; Save registers

	 les	 si,[ebp].FDS_VEC ; ES:SI ==> string to display
	 assume  es:nothing	; Tell the assembler about it

	 call	 DISP_STR	; Display it

	 REGREST <es,si>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDISP_STR endp			; End FDISP_STR rocedure
	 FPPROC  FDD2HEX -- Convert EAX to Hex At ES:DI
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to DD2HEX

On entry:

Same as for DD2HEX

On exit:

Same as for DD2HEX

|

	 call	 DD2HEX 	; Convert EAX to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDD2HEX  endp			; End FDD2HEX procedure
	 FPPROC  FSET_PPL0STK -- Setup PPL0STK Variables
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to SET_PPL0STK

On entry:

Same as for SET_PPL0STK

On exit:

Same as for SET_PPL0STK

|

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 call	 SET_PPL0STK	; Set PPL0STK... pointers

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FSET_PPL0STK endp		; End FSET_PPL0STK procedure
	 FPPROC  FALLOCMEM -- Allocate Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to ALLOCMEM

On entry:

Same as for ALLOCMEM

On exit:

Same as for ALLOCMEM

|

FALLOCMEM_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   CS:IP
FALLOCMEM_LEN dd ?		; # bytes to allocate
FALLOCMEM_TYP dw ?		; Allocation type

FALLOCMEM_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 push	 [ebp].FALLOCMEM_TYP ; Pass allocation type
	 push	 [ebp].FALLOCMEM_LEN ; Pass # bytes to allocate
	 call	 ALLOCMEM	; Allocate 'em
				; Return with CF significant
				; If CF = 0, EBX = linear address of memory
	 pop	 ebp		; Restore

	 ret	 2+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FALLOCMEM endp			; End FALLOCMEM procedure
	 FPPROC  FDEALLOCMEM -- Deallocate Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to DEALLOCMEM

On entry:

Same as for DEALLOCMEM

On exit:

Same as for DEALLOCMEM

|

FDEALLOCMEM_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   CS:IP
FDEALLOCMEM_LA	dd  ?		; Linear address to deallocate
FDEALLOCMEM_LEN dd  ?		; Byte length of deallocate

FDEALLOCMEM_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 push	 [ebp].FDEALLOCMEM_LEN ; Pass byte length
	 push	 [ebp].FDEALLOCMEM_LA  ; Pass starting linear address
	 call	 DEALLOCMEM	; Deallocate memory
				; Return with CF significant

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDEALLOCMEM endp		; End FDEALLOCMEM procedure
	 FPPROC  FWRAP_DISABLE -- Disable the 1MB Wrap
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to WRAP_DISABLE

On entry:

Same as for WRAP_DISABLE

On exit:

Same as for WRAP_DISABLE

|

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_DISABLE	; Disable the 1MB wrap
				; Return with CF significant
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FWRAP_DISABLE endp		; End FWRAP_DISABLE procedure
	 FPPROC  FWRAP_ENABLE -- Enable the 1MB Wrap
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to WRAP_ENABLE

On entry:

Same as for WRAP_ENABLE

On exit:

Same as for WRAP_ENABLE

|

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_ENABLE	; Enable the 1MB wrap, ignore return
				; Return with CF significant
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FWRAP_ENABLE endp		; End FWRAP_ENABLE procedure
	 FPPROC  FAPPEND_EXT -- Append Extended Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to APPEND_EXT

On entry:

Same as APPEND_EXT

On exit:

Same as APPEND_EXT

|

	 call	 APPEND_EXT	; Append it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FAPPEND_EXT endp		; End FAPPEND_EXT procedure
	 FPPROC  FCHECK_HOOK -- Check on Unhooking INT 15h
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to CHECK_HOOK

On entry:

Same as CHECK_HOOK

On exit:

Same as CHECK_HOOK

|

	 call	 CHECK_HOOK	; See if we should unhook INT 15h

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCHECK_HOOK endp		; End FCHECK_HOOK procedure
	 NPPROC  EMM2_DPMIPRES -- DPMI Presence Detection
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI presence detection

On entry:

AX	 =	 1687
SS:ESP	 ==>	 INTXX_STR

On exit:

AX	 =	 0
BX	 =	 1 (32-bit apps supported)
CL	 =	 CPU type (02 = 286, 03 = 386, 04 = 486, etc.)
DH	 =	 DPMI major version # (in decimal)
DL	 =	 ...  minor ...
SI	 =	 # paras in host private data area
ES:DI	 ==>	 VM -> PM entry point

|

	 mov	 ax,[ebp].INTXX_EAX.ELO ; Get caller's AX in case disabled

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 short EMM2_DPMIPRES_EXIT ; Jump if so

	 test	 MSC_FLAG,@MSC_NODPMI ; Should we lie?
	 jnz	 short EMM2_DPMIPRES_EXIT ; Jump if so

	 FIXICALL IGROUP:IMM2_DPMIPRES,DTE_CSIG ; Join common code
EMM2_DPMIPRES_EXIT:
	 and	 GLB_FLAG,not @GLB_P67 ; Mark as not coming from I/O port
				; for INT 67h so we go disabled if no EMS usage
	 jmp	 EMM_EXIT	; Join common EMM exit code with result in AX

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM2_DPMIPRES endp		; End EMM2_DPMIPRES procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 public  @QMAX_I31_ICODE
@QMAX_I31_ICODE:		; Mark module start in .MAP file

	 extrn	 GETSET_LDTVAR:near
	 extrn	 GETSET_LDTFIX:near
	 extrn	 CLR_LDT:near
	 extrn	 DPMIFN_LPMSTK:near
	 extrn	 DPMIFN_RESTMEI:near
	 extrn	 DPMIFN_INITVARS:near
	 extrn	 DPMIFN_DELINKTSS:near
	 extrn	 DPMIFN_PLNKTSS:near
	 extrn	 DPMIFN_FREE_VMOLDPM:near
	 extrn	 DPMIFN_INITLDT:near
	 extrn	 DPMIFN_INITDPMIHNDL:near
	 extrn	 DPMIFN_FREELDT:near
	 extrn	 DPMIFN_SAVEOLDPM:near
	 extrn	 CHECK_ENVCFG:near
	 extrn	 DPMIFN_RESTWIN:near
	 extrn	 DPMIFN_FREEMEM:near
	 extrn	 DPMIFN_RESTDYN:near
	 extrn	 DPMIFN_RESTOLDPM:near
	 extrn	 DPMIFN_FAULT:near

	 extrn	 SAVE_VMCREGS:near
	 extrn	 REST_VMCREGS:near

	 extrn	 PMINTCOM:far

if @OEM_VIRTUALMEM
	 extrn	 FVMM_INIT:far
	 extrn	 FVMM_INIT_CLIENT:far
	 extrn	 FVMM_LOCK:far
	 extrn	 VMM_TERMINATE_CLIENT:near
endif				; IF @OEM_VIRTUALMEM

	 extrn	 IMM2_DPMIPRES:far

	 FPPROC  INT31 -- DPMI Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI protected mode interrupt handler

If we're called from VM, we provide a VM to PM mode switch from
   DPMI_VM2PM.

If we're called from PM, and there are no DPMI clients active,
   service the call.

If we're called from PM, and there are DPMI clients active,
   give them a crack at this interrupt.  If we regain control,
   service the call.

|

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 near ptr INT31_INTRETVM ; Jump if so

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT31_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 assume  ss:PGROUP	; Tell the assembler about it
	 test	 DPMI_CPIHOOK[31h/8],1 shl (31h mod 8) ; Izit hooked by current client?
	 assume  ss:nothing	; Tell the assembler about it
	 jz	 short INT31_INTRETPM ; Jump if not

	 mov	 [esp].NRM_INTNO,4*31h + offset PGROUP:INTPROC00Z ; Mark as INT 31h

; The stack is mapped by INTDPI_STR

	 push	 @PMINTCOM_NRM	; Use application stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

	 public  INT31_INTRETPM
INT31_INTRETPM:
	 PUSHD	 0		; Put pseudo-error code onto stack

	 pushad 		; All EGP registers

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR
				; (nothing above INTXX_SS is valid)

	 REGSAVE <ds,es>	; Save selectors

; Note that the above REGSAVE is mapped by I31_STR and must be
; consistent with it

; Split cases based upon the DPMI function # in AX

	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 test	 DPM_FLAG,mask $DPM_DPMI ; Is debugging desired?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:
	 mov	 es,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 LPMSTK_FVEC.FSEL ; Save current LPM stack top
	 push	 LPMSTK_FVEC.FOFF ; ...

; Set new LPM stack top for nested callers if it's active
; and we're called from PM

	 lea	 eax,[ebp].INTXX_EIP ; SS:EAX ==> INTDPI_STR from PL3
	 push	 eax		; Pass the offset
	 call	 DPMIFN_LPMSTK	; Save new LPM stack as appropriate

COMMENT|

Note that although the IDT entry for this interrupt is marked as an
interrupt gate, we have been careful to be able to handle incoming
hardware interrupts.  This means that it's safe to enable interrupts
which is what the following code might do.  In fact, we set our
interrupt flag (IF) to that of the caller's giving us the effect of
being a trap gate.  We are not marked as a trap gate in the IDT
because we might become confused by the stack frame if we were to get
an interrupt (timer tick) immediately following the above PUSHD 0.
Were that to happen, ESP would match PPL0STK_DERR and we would think
that a Double Fault had occurred.

If we need to perform data accesses without interruption use
PUSHF/CLI/.../POPF.

|

	 push	 [ebp].INTXX_EFL.ELO ; Get caller's flags
	 and	 [esp].ELO,not ((mask $NT) or (mask $DF) or (mask $TF)) ; NT=TF=DF=0
	 popf			; Put caller's IF into effect

	 mov	 bx,[ebp].INTXX_EAX.ELO ; Get the function #

	 test	 bx,mask $MAXDFN_MD ; Any hashed-out bits set?
	 jnz	 short INT31_ERR_NOFNS ; Jump if so

	 cmp	 bx,@MAXDFN	; Izit above the maximum DPMI function?
	 ja	 short INT31_ERR_NOFNS ; Jump if so
				; BX = 0000 xxxx 000x xxxx
	 shl	 bl,width $MAXDFN_MD ; Shift up low-order bits
				; next to high-order bits
				; BX = 0000 xxxx xxxx x000
	 shr	 bx,width $MAXDFN_MD ; Shift down to byte index
				; BX = 0000 000x xxxx xxxx
	 movzx	 bx,DPMI_VAL[bx] ; Get the function code byte

	 jmp	 DPMI_ACT[bx]	; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 public  INT31_ERR_MAC
INT31_ERR_MAC:
	 mov	 [ebp].INTXX_EAX.ELO,@DOSERR_XMAC ; Mark as MAC error

	 jmp	 INT31_ERR	; Join common error exit code

	 public  INT31_ERR_MNF
INT31_ERR_MNF:
	 mov	 [ebp].INTXX_EAX.ELO,@DOSERR_MNF ; Mark as MAC not found error

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_NODMEM
INT31_ERR_NODMEM:
	 mov	 [ebp].INTXX_EAX.ELO,@DOSERR_XMEM ; Mark as insufficient DOS memory

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_NOFNS
INT31_ERR_NOFNS:
	 mov	 [ebp].INTXX_EAX.ELO,8001h ; Mark as unsupported function

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_INVSTATE
INT31_ERR_INVSTATE:
	 mov	 [ebp].INTXX_EAX.ELO,8002h ; Mark as invalid state

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_REQCAN
INT31_ERR_REQCAN:
	 mov	 [ebp].INTXX_EAX.ELO,8005h ; Mark as serial request cancelled

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_NOSEL
INT31_ERR_NOSEL:
	 mov	 [ebp].INTXX_EAX.ELO,8011h ; Mark as no selectors available

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_NOMEM
INT31_ERR_NOMEM:
	 mov	 [ebp].INTXX_EAX.ELO,8012h ; Mark as no memory available

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_NOPHYSMEM
INT31_ERR_NOPHYSMEM:
	 mov	 [ebp].INTXX_EAX.ELO,8013h ; Mark as no physical mem available

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_NOVMC
INT31_ERR_NOVMC:
	 mov	 [ebp].INTXX_EAX.ELO,8015h ; Mark as no VM callback available

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_NOHNDL
INT31_ERR_NOHNDL:
	 mov	 [ebp].INTXX_EAX.ELO,8016h ; Mark as no handles available

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_EXCLUSIVE
INT31_ERR_EXCLUSIVE:
	 mov	 [ebp].INTXX_EAX.ELO,8018h ; Mark as already serialized

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_SHARED
INT31_ERR_SHARED:
	 mov	 [ebp].INTXX_EAX.ELO,8019h ; Mark as already serialized

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_INVVAL
INT31_ERR_INVVAL:
	 mov	 [ebp].INTXX_EAX.ELO,8021h ; Mark as invalid value

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_INVSEL
INT31_ERR_INVSEL:
	 mov	 [ebp].INTXX_EAX.ELO,8022h ; Mark as invalid selector

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_INVHNDL
INT31_ERR_INVHNDL:
	 mov	 [ebp].INTXX_EAX.ELO,8023h ; Mark as invalid handle

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_INVVMC
INT31_ERR_INVVMC:
	 mov	 [ebp].INTXX_EAX.ELO,8024h ; Mark as invalid VM callback address

	 jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR_INVADDR
INT31_ERR_INVADDR:
	 mov	 [ebp].INTXX_EAX.ELO,8025h ; Mark as invalid linear address

;;;;;;;; jmp	 short INT31_ERR ; Join common error exit code

	 public  INT31_ERR
INT31_ERR:
	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 test	 DPM_FLAG,mask $DPM_DPMIERR ; Debugging on DPMI errors?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:
	 or	 [ebp].INTXX_EFL.ELO,mask $CF ; Set the carry flag

	 jmp	 short INT31_EXIT ; Join common exit code


	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 public  INT31_CLC
INT31_CLC:
	 and	 [ebp].INTXX_EFL.ELO,not (mask $CF) ; Clear the carry flag

	 assume  ss:PGROUP	; Tell the assembler about it
INT31_EXIT:
	 cli			; Disable interrupts to avoid HW interrupt
				; after POPAD looking like a VM interrupt
	 pop	 LPMSTK_FVEC.FOFF ; Restore
	 pop	 LPMSTK_FVEC.FSEL ; ...

	 REGREST <es,ds>	; Restore selectors
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 popad			; Restore all EGP registers

	 add	 esp,size INTXX_ERR ; Strip off pseudo-error code

	 iretd			; Return to caller


COMMENT|

INT 31h has been called from VM.

If it's from our device driver, then it's a DPMI request
to switch from VM to PM.

If not, continue with INTPROC31.

|

INT31_INTRETVM:
	 cmp	 [esp].NRM_CS,seg PGROUP ; Izit from high DOS?
	 org	 $-2
	 public  INT31A_HIMEM_CS
INT31A_HIMEM_CS label near	; Address previous segment for relocation
	 org	 $+2
	 je	 short INT31_VM2PM ; Jump if so

	 cli			; Disallow interrupts as per interrupt gate
				; expectations of all other INTPROCxx entries
	 FIXIJMP PGROUP:INTPROC31,DTE_CS2 ; Call as VM INT 31h


COMMENT|

Switch from VM to PM

On entry (in PL3 stack):

AX	 =	 flags:  Bit 0 = 1 if 32-bit application
			       = 0 if 16-bit ...
CX	 =	 segment of PSP
ES:BX	 ==>	 DTA
SS:SP[0] ==>	 caller's ES (segment of HPDA)
     [2] ==>	 ...	  CX (to be restored)
     [4] ==>	 ...	  BX ...
     [6] ==>	 ...	  AX ...
     [8] ==>	 ...	  CS:IP

On exit (in DPMI TSS):

CF	 =	 0 if successful
CS	 =	 16-bit     64KB selector mapping caller's CS
DS	 =	 16-/32-bit 64KB selector mapping caller's DS
ES	 =	 16-/32-bit 100h selector mapping caller's PSP
FS	 =	 0
GS	 =	 0
SS	 =	 16-/32-bit 64KB selector mapping caller's SS

CF	 =	 1 if not successful
AX	 =	 8011 if descriptor unavailable
	 =	 8012 if linear memory unavailable (dynamic save area)
	 =	 8021 if invalid value (mismatch of 16- vs. 32-bit clients)
		 80ff is used internally; it will never be returned to
		 a caller, but is used to indicate that Ctrl-Break was
		 pressed during swapfile initialization.

|

INT31_VM2PM:
	 PUSHD	 0		; Put pseudo-error code onto stack

	 pushad 		; All EGP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 es,ISEL_DSIG3	; Get IGROUP code/data selector at PL3
	 assume  es:IGROUP	; Tell the assembler about it

	 mov	 gs,SEL_4GB	; Get AGROUP data selector at PL0
	 assume  gs:AGROUP	; Tell the assembler about it

; Save caller's PSP segment

	 cli			; Disallow interrupts as we use
				; non-sharable data variables
	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get the segment
	 mov	 VM2PM_PSP,ax	; Save to use later

; Save caller's DTA

	 mov	 ax,[ebp].INTXX_ES ; Get the segment
	 mov	 VM2PM_DTAVEC.VSEG,ax ; Save for later use
	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get the segment
	 mov	 VM2PM_DTAVEC.VOFF,ax ; Save for later use

VM2PM_STR struc

VM2PM_ES dw	 ?		; Caller's original ES
VM2PM_CX dw	 ?		; ...		    CX
VM2PM_BX dw	 ?		; ...		    BX
VM2PM_AX dw	 ?		; ...		    AX
VM2PM_CSIP dd	 ?		; ...		    CS:IP

VM2PM_STR ends

; Save caller's HPDA segment and restore the original AX, BX, CX, ES

	 movzx	 eax,[ebp].INTXX_SS ; Get caller's SS
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,[ebp].INTXX_ESP.ELO ; Get caller's SP

	 mov	 dx,AGROUP:[eax+ebx].VM2PM_ES ; Get the original ES
	 mov	 [ebp].INTXX_ES,dx ; Restore the original value

	 mov	 dx,AGROUP:[eax+ebx].VM2PM_CX ; Get the original CX
	 mov	 [ebp].INTXX_ECX.ELO,dx ; Restore the original value

	 mov	 dx,AGROUP:[eax+ebx].VM2PM_BX ; Get the original BX
	 mov	 [ebp].INTXX_EBX.ELO,dx ; Restore the original value

	 mov	 dx,AGROUP:[eax+ebx].VM2PM_AX ; Get the original AX
	 mov	 [ebp].INTXX_EAX.ELO,dx ; Restore the original value

; Restore the return address from the stack to CS:IP

	 mov	 dx,AGROUP:[eax+ebx].VM2PM_CSIP.VOFF ; Get the return offset
	 mov	 [ebp].INTXX_EIP.ELO,dx ; Save as new IP

	 mov	 dx,AGROUP:[eax+ebx].VM2PM_CSIP.VSEG ; Get the return segment
	 mov	 [ebp].INTXX_CS,dx ; Save as new CS

	 add	 bx,size VM2PM_STR ; Skip over saved registers
	 mov	 [ebp].INTXX_ESP.ELO,bx ; Save as new SP

; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様
; From this point on we can signal an error

; Ensure we're not running out of TSSs

	 mov	 esi,PVMTSS	; Get offset in PGROUP of the 1st TSS
	 mov	 cx,@TSS_MAX-1	; Get maximum # TSSs we support
@@:
	 add	 esi,type DPTSS_STR ; Skip to next valid TSS

	 cmp	 PGROUP:[esi].TSS_LINK,-1 ; Izit available?
	 je	 short @F	; Jump if so

	 loop	 @B		; Jump if more TSSs to check

	 mov	 VM2PM_ERR,8010h ; Internal resource unavailable

	 jmp	 INT31_VM2PM_ERRCOM ; Jump if no TSSs available

@@:
	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

; ESI	 =	 offset in PGROUP of the incoming TSS
; EDX	 =	 ...			 current ...

; Zero all fields beyond TSS_STR in DPTSS_STR so we start
; off with a known value except for the constant fields

	 push	 PGROUP:[esi].DPTSS_SEL ; Save the selector

	 push	 es		; Save for a moment

	 mov	 es,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 edi,PGROUP:[esi+(type TSS_STR)] ; Skip over TSS_STR in DPTSS_STR
	 mov	 ecx,((type DPTSS_STR)-(type TSS_STR))/4 ; Get size in dwords
	 xor	 eax,eax	; Filler value
     rep stos	 PGROUP:[edi].EDD ; Set to known value

	 pop	 es		; Restore
	 assume  es:IGROUP	; Tell the assembler about it

	 pop	 PGROUP:[esi].DPTSS_SEL ; Restore the selector

; Save back pointers to the current TSS in the incoming TSS

	 mov	 PGROUP:[esi].DPTSS_PLNKTSS,edx ; Save as back pointer
	 str	 PGROUP:[esi].TSS_LINK ; ...
	 mov	 PGROUP:[esi].DPTSS_PRMSTSS,esi ; ...

; Address the next TSS to use.	We must save this value into PCURTSS
; because it is needed to reference the current LDT.  If we encounter
; an error, we'll back off from this value.

	 mov	 edx,esi	; Get the next pointer
	 mov	 PCURTSS,edx	; Save for next time
	 mov	 PPRMTSS,edx	; ...
	 mov	 ax,PGROUP:[edx].DPTSS_SEL ; Get the next TSS selector
	 mov	 VM2PM_TSS,ax	; Skip to next TSS selector
	 ltr	 ax		; Set new Task Register (CPU marks as busy)

; Save the bit type

; Note we don't save the value into DPMITYPEIG as yet so we can
; use it as the old value in the old PM data area

	 test	 [ebp].INTXX_EAX.ELO,@BIT0 ; Set ==> 32-bit, Clr ==> 16-bit
	 setnz	 DPMITYPE	; Save to check the next time

	 call	 DPMIFN_INITVARS ; Initialize TSS and HPDA

; In case the user specified EMS=0 and there hasn't been any XMS
; client since then, we need to append the remaining extended memory
; to the CMP.  Note that our VM2PM stub in the first megabyte has
; already filled in the current value for EX2SIZE in low memory.

	 test	 XMS_FLAG,mask $XMS_I15 ; Izit already installed?
	 jnz	 short @F	; Jump if so

	 FIXICALL PGROUP:FAPPEND_EXT,DTE_CS2 ; Append it
@@:

; If this is the first DPMI client, allocate memory
; for the current PMxxT_xVECS and other variables
; and save its address in the current DPTSS_STR

	 mov	 eax,PVMTSS	; Get offset in PGROUP of the 1st TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_PLNKTSS ; Izit the 1st TSS?
	 jne	 short INT31_VM2PM_X1TSS ; Jump if not

	 mov	 VM2PM_ERR,8012h ; Assume we run out of linear memory

if @OEM_VIRTUALMEM
	 push	 @ALLOC_VCPI	; Tell 'em what kind of memory we're allocating
else
	 push	 @ALLOC_DPMI	; Tell 'em what kind of memory we're allocating
endif				; IF @OEM_VIRTUALMEM
	 push	 DPMIOLDPM_SIZ	; Pass # bytes to allocate
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
				; Return with EBX = linear address of memory
	 jc	 near ptr INT31_VM2PM_ERR_NOMEM9 ; Jump if no memory found

	 mov	 PGROUP:[eax].DPTSS_OLDPM,ebx ; Save for later use
INT31_VM2PM_X1TSS:

; Allocate memory for the current PMxxT_xVECS and other variables
; and save its address in the current DPTSS_STR

	 mov	 VM2PM_ERR,8012h ; Assume we run out of linear memory

if @OEM_VIRTUALMEM
	 push	 @ALLOC_VCPI	; Tell 'em what kind of memory we're allocating
else
	 push	 @ALLOC_DPMI	; Tell 'em what kind of memory we're allocating
endif				; IF @OEM_VIRTUALMEM
	 push	 DPMIOLDPM_SIZ	; Pass # bytes to allocate
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
				; Return with EBX = linear address of memory
	 jc	 near ptr INT31_VM2PM_ERR_NOMEM8 ; Jump if no memory found

	 mov	 PGROUP:[edx].DPTSS_OLDPM,ebx ; Save for later use

	 test	 CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	 jz	 short @F	; Jump if not

	 mov	 PGROUP:[edx].DPTSS_LaSIRBCUR,ebx ; Save for later use
	 mov	 LaSIRBCUR,ebx	; Save as current linear address
@@:

; Save current PMxxT_xVECS to outgoing PM data area
; and re-initialize PMxxT_xVECS.

	 push	 PGROUP:[edx].DPTSS_PLNKTSS ; Point to previous TSS
	 push	 1		; Tell 'em to re-initialize
	 call	 DPMIFN_SAVEOLDPM ; Save 'em

if @OEM_VIRTUALMEM

; If the swapfile is not active for this client, clear the bit now

	 test	 VMM_FLAG,@VMM_BSGLOBAL ; Izit globally available?
	 jz	 short INT31_VM2PM_NOSWAP ; Jump if not

; If this isn't the first DPMI client, ignore the NOSWAP count as
; we can't re-initialize BSM at this point

	 mov	 eax,PVMTSS	; Get offset in PGROUP of the 1st TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_PLNKTSS ; Izit the 1st TSS?
	 jne	 short INT31_VM2PM_NOSWAP ; Jump if not

	 or	 VMM_FLAG,@VMM_BSPRES ; Mark as present
	 mov	 eax,BSGTotal	; Get global swapfile size
	 mov	 BSTotal,eax	; Save as local size

	 cmp	 NOSWAP_CNT,0	; Izit time to lie?
	 je	 short @F	; Jump if not

	 cmp	 NOSWAP_CNT,-1	; Izit forever?
	 sbb	 NOSWAP_CNT,0	; One fewer for next time if not forever
	 and	 VMM_FLAG,not @VMM_BSPRES ; Mark as not present
	 mov	 BSTotal,0	; Save as local size
@@:
	 test	 PDC_FLAG,@I31_NOSWAP ; Skip swapfile for this DPMI client?
	 jz	 short @F	; Jump if not

	 and	 VMM_FLAG,not @VMM_BSPRES ; Mark as not present
	 mov	 BSTotal,0	; Save as local size
@@:
INT31_VM2PM_NOSWAP:

; If this is the first DPMI client, and VMM is present,
; initialize the VMM system.  If that fails, we disallow
; further VMM calls.

	 and	 VMM_FLAG,not @VMM_CTRLBREAK ; Clear Ctrl-Break flag

	 mov	 eax,PVMTSS	; Get offset in PGROUP of the 1st TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_PLNKTSS ; Izit the 1st TSS?
	 jne	 short @F	; Jump if not

	 FCALL	 FVMM_INIT	; Initialize the VMM system
	 mov	 VM2PM_ERR,ax	; In case we fail
	 jc	 near ptr INT31_VM2PM_ERR_NOMEM7 ; Jump if unable to initialize
@@:

; Initialize this client's portion of the VM system

	 FCALL	 FVMM_INIT_CLIENT ; Initialize the client
	 mov	 VM2PM_ERR,ax	; In case we fail
	 jc	 near ptr INT31_VM2PM_ERR_NOMEM7 ; Jump if no memory found
				; with error code in AX

; Check for Ctrl-Break pressed during swapfile initialization
	 mov	 VM2PM_ERR,@DERR_CTRLBREAK_SWP ; Assume this (internal) error
	 test	 VMM_FLAG,@VMM_CTRLBREAK ; Did we hit the panic button?
	 jnz	 near ptr INT31_VM2PM_ERR_NOMEM7 ; Jump if so

endif				; IF @OEM_VIRTUALMEM

; If there's no HMA, ensure the 1MB wrap is disabled as we might allocate
; to a DPMI client the extended memory at 1MB to 1.1MB

	 cmp	 HMASIZE,0	; Izit available?
	 jne	 short @F	; Jump if so

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap
	 jc	 short @F	; Jump if we didn't flush the TLB
				; (and thus didn't change state)
	 or	 PGROUP:[edx].DPTSS_FLAG,mask $DPTSS_WRAP ; Mark as changed
	 or	 GLB_FLAG,@GLB_X1MB ; Enable the virtual A20 line
@@:

; Allocate a Locked Protected Mode stack

	 mov	 VM2PM_ERR,8012h ; Assume we run out of linear memory

	 push	 @ALLOC_DPMI	; Tell 'em what kind of memory we're allocating
	 push	 LPMSTK_SIZ	; Pass # bytes to allocate
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
				; Return with EBX = linear address of memory
	 jc	 near ptr INT31_VM2PM_ERR_NOMEM6 ; Jump if no memory found

	 mov	 PGROUP:[edx].DPTSS_LPMBASE,ebx ; Save for later use

if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_SYSINIT ; Is VMM active?
	 jz	 short @F	; Jump if not

	 mov	 eax,ebx	; Copy linear address
	 mov	 ebx,LPMSTK_SIZ ; Get # bytes in the stack
	 add	 ebx,4*1024-1	; Round up to 4KB boundary
	 shr	 ebx,12-0	; Convert from bytes to 4KB
	 FCALL	 FVMM_LOCK	; Lock EBX bytes at EAX
	 mov	 VM2PM_ERR,ax	; In case we failed
	 jc	 near ptr INT31_VM2PM_ERR_NOMEM5 ; Jump if some error occurred
@@:
endif				; IF @OEM_VIRTUALMEM

; Initialize the LPM stack to known values for debugging purposes.
; That way, we can see how much gets used by DPMI clients.

	 push	 es		; Save for a moment

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PGROUP:[edx].DPTSS_LPMBASE ; Get linear address of the LPM stack
	 mov	 ecx,LPMSTK_SIZ ; Get size of the LPM stack in bytes
	 shr	 ecx,2-0	; Convert from bytes to dwords
	 mov	 eax,@LPMSTKFILL ; Fill with this value
     rep stos	 AGROUP:[edi].EDD ; Fill it

	 pop	 es		; Restore
	 assume  es:IGROUP	; Tell the assembler about it

; Allocate memory for our extended LDT
; and save its address in the new DPTSS_STR

	 mov	 VM2PM_ERR,8012h ; Assume we run out of linear memory

	 push	 @ALLOC_DPMI	; Tell 'em what kind of memory we're allocating
	 push	 XLDT_SIZ	; Pass # bytes to allocate (/@DPMI_BOUND)
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
				; Return with EBX = linear address of memory
	 jc	 near ptr INT31_VM2PM_ERR_NOMEM4 ; Jump if no memory found

	 mov	 PGROUP:[edx].DPTSS_LaLDT,ebx ; Save for later use

	 mov	 eax,LDT_SIZ	; Get initial byte size of DPMI LDT (/8)
	 mov	 PGROUP:[edx].DPTSS_LDT_SIZ,eax ; Save for later use

	 mov	 ax,VM2PM_TSS	; Get current TSS selector
	 add	 ax,type DESC_STR ; Skip to LDT selector
	 mov	 PGROUP:[edx].TSS_LDT,ax ; Save in TSS
if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_SYSINIT ; Is VMM active?
	 jz	 short @F	; Jump if not

	 mov	 eax,ebx	; Copy linear address
	 mov	 ebx,XLDT_SIZ	; Get # bytes in the LDT
	 add	 ebx,4*1024-1	; Round up to 4KB boundary
	 shr	 ebx,12-0	; Convert from bytes to 4KB
	 FCALL	 FVMM_LOCK	; Lock EBX bytes at EAX
	 mov	 VM2PM_ERR,ax	; In case we failed
	 jc	 near ptr INT31_VM2PM_ERR_NOMEM3 ; Jump if some error occurred
@@:
endif				; IF @OEM_VIRTUALMEM

	 call	 DPMIFN_INITLDT ; Initialize the contents of the LDT
				; and install it

; Allocate memory for our DPMI memory handle structure
; and save its address in the new DPTSS_STR

	 mov	 VM2PM_ERR,8012h ; Assume we run out of linear memory

	 push	 @ALLOC_DPMI	; Tell 'em what kind of memory we're allocating
	 push	 DPMIHNDL_SIZ	; Pass # bytes to allocate (/@DPMI_BOUND)
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
				; Return with EBX = linear address of memory
	 jc	 near ptr INT31_VM2PM_ERR_NOMEM3 ; Jump if no memory found

	 mov	 PGROUP:[edx].DPTSS_LaDPMIHNDL,ebx ; Save for later use

	 mov	 eax,DPMIHNDL_CNT ; Get initial # DPMI memory handles
	 mov	 PGROUP:[edx].DPTSS_DPMIHNDL_CNT,eax ; Save for later use

	 call	 DPMIFN_INITDPMIHNDL ; Initialize the contents of the DPMI
				; memory handle structure

; Allocate memory for our dynamic data save area
; and save its address in the new DPTSS_STR

	 mov	 VM2PM_ERR,8012h ; Assume we run out of linear memory

	 push	 @ALLOC_DPMI	; Tell 'em what kind of memory we're allocating
	 push	 DPMIDYN_SIZ	; Pass # bytes to allocate
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
				; Return with EBX = linear address of memory
	 jc	 near ptr INT31_VM2PM_ERR_NOMEM2 ; Jump if no memory found

	 mov	 PGROUP:[edx].DPTSS_DYN,ebx ; Save for later use

; Setup LDT selector for caller's return CS

	 mov	 VM2PM_ERR,8011h ; Assume selector unavailable

	 movzx	 eax,[ebp].INTXX_CS ; Get the return CS
	 shl	 eax,4-0	; Convert from paras to bytes

	 push	 DPMI_CODE	; Pass access rights word
	 push	 CON64KB	; Pass segment length in bytes
	 push	 eax		; Pass base address
	 call	 GETSET_LDTVAR	; Return with EAX = selector ($TI and $PL set)
	 jc	 near ptr INT31_VM2PM_ERR_NOSEL ; Jump if not available

	 mov	 ebx,PGROUP:[edx].DPTSS_LaHPDA ; Get linear address of the HPDA
	 mov	 PGROUP:[edx].TSS_CS,ax ; Save for later use
	 mov	 AGROUP:[ebx].HPDA_pCS,ax ; Save for later use

; Set B-bit for data selectors if it's not a 16-bit client

	 mov	 cl,DPMI_DATA.LO ; Get A/R byte for 16-bit client

	 cmp	 DPMITYPE,@DPMITYPE16 ; Izit a 16-bit client?
	 setne	 ch		; CH = 1 if 32-bit or no DPMI
				;    = 0 if 16-bit
	 shl	 ch,$DTE_B	; Set B-bit for 32-bit apps

; Setup selector for caller's DTA

	 movzx	 eax,VM2PM_DTAVEC.VSEG ; Get the DTA segment
	 shl	 eax,4-0	; Convert from paras to bytes

	 push	 cx		; Pass A/R word (from above)
	 push	 dword ptr 80h	; Pass segment length in bytes
	 push	 eax		; Pass base address
	 call	 GETSET_LDTFIX	; Return with EAX = selector ($TI and $PL set)
	 jc	 near ptr INT31_VM2PM_ERR5 ; Jump if not available

	 mov	 PGROUP:[edx].DPTSS_DTA_FVEC.FSEL,ax ; Save for later use
	 movzx	 eax,VM2PM_DTAVEC.VOFF ; Get the DTA offset
	 mov	 PGROUP:[edx].DPTSS_DTA_FVEC.FOFF,eax ; ...

; Setup LDT selector for caller's DS

	 movzx	 eax,[ebp].INTXX_DS ; Get caller's DS
	 shl	 eax,4-0	; Convert from paras to bytes

	 push	 cx		; Pass A/R word (from above)
	 push	 CON64KB	; Pass segment length in bytes
	 push	 eax		; Pass base address
	 call	 GETSET_LDTVAR	; Return with EAX = selector ($TI and $PL set)
	 jc	 near ptr INT31_VM2PM_ERR4 ; Jump if not available

	 mov	 PGROUP:[edx].TSS_DS,ax ; Save for later use
	 mov	 AGROUP:[ebx].HPDA_pDS,ax ; Save for later use

; Setup LDT selector for caller's SS

	 movzx	 eax,[ebp].INTXX_SS ; Get caller's SS
	 shl	 eax,4-0	; Convert from paras to bytes

	 push	 cx		; Pass A/R word (from above)
	 push	 CON64KB	; Pass segment length in bytes
	 push	 eax		; Pass base address
	 call	 GETSET_LDTVAR	; Return with EAX = selector ($TI and $PL set)
	 jc	 near ptr INT31_VM2PM_ERR3 ; Jump if not available

	 mov	 PGROUP:[edx].TSS_SS,ax ; Save for later use
	 mov	 AGROUP:[ebx].HPDA_pSS,ax ; Save for later use

; Setup LDT selector for caller's PSP

	 movzx	 eax,VM2PM_PSP	; Get the PSP segment
	 shl	 eax,4-0	; Convert from paras to bytes

	 push	 cx		; Pass A/R word (from above)
	 push	 dword ptr 100h ; Pass segment length in bytes
	 push	 eax		; Pass base address
	 call	 GETSET_LDTFIX	; Return with EAX = selector ($TI and $PL set)
	 jc	 near ptr INT31_VM2PM_ERR2 ; Jump if not available

	 mov	 PGROUP:[edx].TSS_ES,ax ; ...
	 mov	 AGROUP:[ebx].HPDA_pES,ax ; ...

; Setup LDT selector for caller's environment

	 movzx	 esi,VM2PM_PSP	; Get the PSP segment
	 shl	 esi,4-0	; Convert from paras to bytes

	 assume  gs:PSPGRP	; Tell the assembler about it
	 movzx	 eax,PSP_ENVIR_PTR[esi] ; Get the environment segment
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 AGROUP:[ebx].HPDA_ENVSEG,ax ; Save for later use

	 shl	 eax,4-0	; Convert from paras to bytes
	 jz	 short INT31_VM2PM_XENV ; Jump if it's been freed

	 public  @ENVLEN
@ENVLEN  equ	 8000h		; Length of environment

	 push	 cx		; Pass A/R word (from above)
	 push	 dword ptr @ENVLEN ; Pass size of area in bytes (32KB maximum)
	 push	 eax		; Pass base address
	 call	 GETSET_LDTFIX	; Return with EAX = selector ($TI and $PL set)
	 jc	 near ptr INT31_VM2PM_ERR1 ; Jump if not available

	 call	 CHECK_ENVCFG	; Check for this program in environment AX
				; in the CFG file
	 assume  gs:PSPGRP	; Tell the assembler about it
	 mov	 PSP_ENVIR_PTR[esi],ax ; Save the environment selector
	 assume  gs:AGROUP	; Tell the assembler about it
INT31_VM2PM_XENV:

; 様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様
; From this point on, we should not signal any errors

; Now that we know we're going to succeed, we can save the
; per DPMI client flags in a more permanent place (I31_FLAG)
; which gets switched in and out as the client changes.

	 xor	 ax,ax		; Clear for the next time
	 xchg	 ax,PDC_FLAG	; Get per DPMI client flags and zero 'em
	 or	 I31_FLAG,ax	; Include for later use

	 push	 PCURTSS	; Pass offset in PGROUP of the current TSS
	 call	 DPMIFN_LMSW	; Put MSW and INT 07h values into effect

; Initialize dynamic save area.
; Note we wait until after we've disabled the 1MB wrap to initialize
; this area in case it's in the wrap region.

	 mov	 eax,PGROUP:[edx].DPTSS_DYN ; Get linear address of dynamic save area
	 mov	 AGROUP:[eax].DYNHDR_FN,@DYNFN_EOL ; Mark as nothing present

; Copy the DPMI client application name to a local save area

	 push	 es		; Save for a moment

	 mov	 es,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  es:FGROUP	; Tell the assembler about it

	 mov	 cx,MSG_APPLNAME.LENTXT_LEN ; Get word length of application
	 add	 cx,size LENTXT_LEN ; Count in length word
	 lea	 si,MSG_APPLNAME ; DS:SI ==> source name
	 lea	 di,MSG_DPMIAPPLNAME ; ES:DI ==> destin name
S16  rep movs	 <MSG_DPMIAPPLNAME.LO[di],MSG_APPLNAME.LO[si]> ; Copy to local save area

	 pop	 es		; Restore
	 assume  es:IGROUP	; Tell the assembler about it

; Setup registers for when caller returns to us

	 mov	 eax,[ebp].INTXX_EAX ; Get caller's EAX
	 mov	 PGROUP:[edx].TSS_EAX,eax ; Save in new TSS

	 mov	 eax,[ebp].INTXX_EBX ; ...	    EBX
	 mov	 PGROUP:[edx].TSS_EBX,eax ; ...

	 mov	 eax,[ebp].INTXX_ECX ; ...	    ECX
	 mov	 PGROUP:[edx].TSS_ECX,eax ; ...

	 mov	 eax,[ebp].INTXX_EDX ; ...	    EDX
	 mov	 PGROUP:[edx].TSS_EDX,eax ; ...

	 mov	 eax,[ebp].INTXX_ESI ; ...	    ESI
	 mov	 PGROUP:[edx].TSS_ESI,eax ; ...

	 mov	 eax,[ebp].INTXX_EDI ; ...	    EDI
	 mov	 PGROUP:[edx].TSS_EDI,eax ; ...

	 mov	 eax,[ebp].INTXX_EBP ; ...	    EBP
	 mov	 PGROUP:[edx].TSS_EBP,eax ; ...

	 mov	 PGROUP:[edx].TSS_FS,0 ; Ensure valid
	 mov	 PGROUP:[edx].TSS_GS,0 ; ...

; Set new TSS_ESP0 to previous value for nesting

	 mov	 eax,PGROUP:[edx].DPTSS_PLNKTSS ; Get offset in PGROUP of prev TSS
	 mov	 eax,PGROUP:[eax].TSS_ESP0 ; Get top of MAX stack
	 mov	 PGROUP:[edx].TSS_ESP0,eax ; Set top of MAX stack

; Recalculate PL0STK pointers

	 FIXICALL PGROUP:FSET_PPL0STK,DTE_CS2 ; Set PPL0STK... pointers

; Swap the value of the INT 22h address in the PSP with our own

	 mov	 eax,PGROUP:[edx].DPTSS_LaHPDA ; Get linear address of HPDA

	 movzx	 ecx,VM2PM_PSP	; Get the PSP segment
	 shl	 ecx,4-0	; Convert from paras to bytes

	 mov	 bx,PGROUP:[edx].DPTSS_HPDASEG ; Get segment of the HPDA
	 shl	 ebx,16 	; Shift to high-order word
	 mov	 bx,HPDA_I22DEF ; Get offset of default Terminate handler

	 assume  gs:PSPGRP	; Tell the assembler about it
	 xchg	 ebx,PSP_TERMINATE[ecx] ; Swap with the previous address
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 AGROUP:[eax].HPDA_I22VEC,ebx ; Save for later use

; Swap the value of the INT 23h address in the VM IDT with our own

;;;;;;;; mov	 eax,PGROUP:[edx].DPTSS_LaHPDA ; Get linear address of HPDA

	 mov	 bx,PGROUP:[edx].DPTSS_HPDASEG ; Get segment of the HPDA
	 shl	 ebx,16 	; Shift to high-order word
	 mov	 bx,HPDA_I23DEF ; Get offset of default Ctrl-Break handler

	 assume  gs:INTVEC	; Tell the assembler about it
	 xchg	 ebx,INT00_VEC[23h*(type INT00_VEC)] ; Get the previous address
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 AGROUP:[eax].HPDA_I23VEC,ebx ; Save for later use

; Swap the value of the INT 24h address in the VM IDT with our own

;;;;;;;; mov	 eax,PGROUP:[edx].DPTSS_LaHPDA ; Get linear address of HPDA

	 mov	 bx,PGROUP:[edx].DPTSS_HPDASEG ; Get segment of the HPDA
	 shl	 ebx,16 	; Shift to high-order word
	 mov	 bx,HPDA_I24DEF ; Get offset of default Critical Error handler

	 assume  gs:INTVEC	; Tell the assembler about it
	 xchg	 ebx,INT00_VEC[24h*(type INT00_VEC)] ; Get the previous address
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 AGROUP:[eax].HPDA_I24VEC,ebx ; Save for later use

; Save current LPM stack pointer in the outgoing TSS

	 mov	 edx,PGROUP:[edx].DPTSS_PLNKTSS ; Get offset in PGROUP of prev TSS

	 mov	 eax,LPMSTK_FVEC.FOFF ; Get offset of top of LPM stack
	 mov	 PGROUP:[edx].DPTSS_LPMSTK_FVEC.FOFF,eax ; Save for later use
	 mov	 ax,LPMSTK_FVEC.FSEL ; Get selector of top of LPM stack
	 mov	 PGROUP:[edx].DPTSS_LPMSTK_FVEC.FSEL,ax ; Save for later use
	 mov	 eax,LPMSTK_CNT ; Get current LPM stack usage count
	 mov	 PGROUP:[edx].DPTSS_LPMSTK_CNT,eax ; Save for later use

; Save new value for LPM stack pointer and count

	 mov	 ax,LPMSTK_SEL	; Get the default selector
	 mov	 LPMSTK_FVEC.FSEL,ax ; Save the new selector
	 mov	 eax,LPMSTK_SIZ ; Get initial stack offset
	 mov	 LPMSTK_FVEC.FOFF,eax ; Save for later use
	 mov	 LPMSTK_CNT,0	; Set initial LPM stack usage count

	 and	 LAST_INTFLG,not @INTCOM_VAL ; Mark as invalid

; Call Resident Service Providers

	 mov	 ah,0		; Pass INITIALIZATION parameter
	 mov	 al,DPMITYPE	; Pass bitness
	 FIXICALL JGROUP:DPMIFN_CALL_RSPS,DTE_CSJG ; Call RSPs

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS
	 or	 PGROUP:[edx].DPTSS_FLAG,mask $DPTSS_INIT ; Mark as initialized

; Because we don't want to set the NT bit, we effect a task switch
; by hand.

INT31_VM2PM_TS:
	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 push	 PGROUP:[edx].TSS_SS.EDD ; Setup for IRETD
	 push	 PGROUP:[edx].TSS_ESP	 ; ...

; If the return CS is at PL0 (as may be the case if we entered here
; from a spurious IRET/D at PL0 because the DPMI client set the NT
; flag and then called us), restore the stack immediately because
; the following IRETD won't perform a ring transition.

	 test	 PGROUP:[edx].TSS_CS,mask $PL ; Izit at PL0?
	 jnz	 short @F	; Jump if not

	 lss	 esp,[esp].EDF	; Restore it now
	 assume  ss:nothing	; Tell the assembler about it
@@:
	 push	 PGROUP:[edx].TSS_EFL	 ; ...
	 push	 PGROUP:[edx].TSS_CS.EDD ; ...
	 push	 PGROUP:[edx].TSS_EIP	 ; ...

	 mov	 eax,PGROUP:[edx].TSS_EAX ; Restore from new TSS
	 mov	 ebx,PGROUP:[edx].TSS_EBX ; ...
	 mov	 ecx,PGROUP:[edx].TSS_ECX ; ...
	 mov	 esi,PGROUP:[edx].TSS_ESI ; ...
	 mov	 edi,PGROUP:[edx].TSS_EDI ; ...
	 mov	 ebp,PGROUP:[edx].TSS_EBP ; ...

	 push	 PGROUP:[edx].TSS_EDX ; Save on stack

	 mov	 gs,PGROUP:[edx].TSS_GS ; Restore from new TSS
	 assume  gs:nothing	; Tell the assembler about it

	 mov	 fs,PGROUP:[edx].TSS_FS ; ...
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 es,PGROUP:[edx].TSS_ES ; ...
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ds,PGROUP:[edx].TSS_DS ; ...
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 edx		; Restore

	 iretd			; Switch to the new task

	 assume  ds:PGROUP,es:IGROUP  ; Tell the assembler about it
	 assume  fs:nothing,gs:AGROUP ; Tell the assembler about it

	 public  INT31_VM2PM_RET
INT31_VM2PM_RET:

; This might be a spurious task switch caused by an IRET/D with NT set
; If $I31_EXIT is set, it's valid; if not, it's spurious

	 clts			; Clear the Task Switched flag in CR0

	 btr	 I31_FLAG,$I31_EXIT ; Reset and check
	 jc	 short INT31_VM2PM_RETOK ; Jump if valid

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 lldt	 PGROUP:[edx].TSS_LDT ; Get new LDT
	 ltr	 PGROUP:[edx].DPTSS_SEL ; Set new Task Register (CPU marks as busy)

	 mov	 eax,PGROUP:[edx].TSS_CR3 ; Get incoming CR3
	 mov	 cr3,eax	; Tell the CPU about it

; Decrement the EIP in the last TSS and restart the task

	 mov	 esi,PGROUP:[edx].TSS_EIP ; TSS_CS:ESI ==> IRET + 1
	 dec	 esi		; Back up to IRET

; If this is a 32-bit client, or we came from PL0, check for IRETD

	 test	 PGROUP:[edx].TSS_CS,mask $PL ; Izit at PL0?
	 jz	 short @F	; Jump if so

	 cmp	 DPMITYPE,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short INT31_VM2PM_RET1 ; Jump if so
@@:
	 push	 ds		; Save for a moment

	 mov	 ds,PGROUP:[edx].TSS_CS ; Get client's CS
	 assume  ds:nothing	; Tell the assembler about it

	 cmp	 ds:[esi-1].LO,@OPCOD_OSP ; Izit Operand Size Prefix for IRETD?
	 jne	 short @F	; Jump if not

	 dec	 esi		; Back up to IRETD
@@:
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
INT31_VM2PM_RET1:
	 mov	 PGROUP:[edx].TSS_EIP,esi ; Save back

	 test	 DPM_FLAG,mask $DPM_DPMISPURNT ; Should we signal INT 01h?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:
	 jmp	 INT31_VM2PM_TS ; Go around again


	 assume  ds:PGROUP,es:IGROUP  ; Tell the assembler about it
	 assume  fs:nothing,gs:AGROUP ; Tell the assembler about it

	 public  INT31_VM2PM_RETOK
INT31_VM2PM_RETOK:

; If we've been told not to switch stacks, the value of ESP is already set

	 test	 I31_FLAG,mask $I31_NOSWITCH ; Should we use the same stack?
	 jnz	 short INT31_VM2PM_RETOK1 ; Jump if so

; Setup our return stack pointer with room for INTCOM_STR.  If we
; exit due to a fault, we need this to address the faulting CS|EIP.
; If we exit normally, we need this space defined to return to VM.

	 push	 eax		; Save for a moment

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 eax,PGROUP:[eax].DPTSS_PLNKTSS ; Back off to previous TSS
	 mov	 eax,PGROUP:[eax].TSS_ESP0 ; Get top of MAX stack
	 sub	 eax,size INTCOM_STR ; Make room

	 xchg	 eax,[esp]	; Swap with original EAX

	 mov	 esp,[esp]	; Set to new location
INT31_VM2PM_RETOK1:
	 test	 I31_FLAG,mask $I31_FAULT ; Did we terminate because of a fault?
	 jnz	 short @F	; Jump if so (error code already on stack)

	 PUSHD	 0		; Make room for pseudo-error code
@@:

; At this point, the DPMI client has terminated (via DOS function 4C or
; because of a fault) and we must clean up.  Restart execution in VM
; in the host private data area at the INT 21h function there.
; Note that we return with interrupts disabled as that's how we
; entered the last TSS.

; The stack has room on it for INTCOM_STR preceded by an error code
; If we terminated due to a fault, the INTDPF_STR portion of the stack
; is meaningful; otherwise, the contents of the stack are undefined.

	 pushad 		; All EGP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR
				; (nothing above INTXX_EFL is valid)

; Restore LAST_INTCOM, LAST_INTFLG, PL0 stack values, and LPM stack top

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 mov	 eax,PGROUP:[edx].DPTSS_INTCOM ; Get previous value
	 mov	 LAST_INTCOM,eax ; Restore it

	 mov	 eax,PGROUP:[edx].DPTSS_INTFLG ; Get previous value
	 mov	 LAST_INTFLG,eax ; Restore it

	 mov	 eax,PGROUP:[edx].DPTSS_STKERR ; Get previous value
	 mov	 PPL0STK_ERR,eax ; Restore it

	 mov	 eax,PGROUP:[edx].DPTSS_STKDNRM ; Get previous value
	 mov	 PPL0STK_DNRM,eax ; Restore it

	 mov	 eax,PGROUP:[edx].DPTSS_STKDERR ; Get previous value
	 mov	 PPL0STK_DERR,eax ; Restore it

	 mov	 eax,PGROUP:[edx].DPTSS_STKNRM ; Get previous value
	 mov	 PPL0STK_NRM,eax ; Restore it

	 mov	 eax,PGROUP:[edx].DPTSS_STKMIN ; Get previous value
	 mov	 PPL0STK_MIN,eax ; Restore it

	 mov	 eax,PGROUP:[edx].DPTSS_STKMAP ; Get previous value
	 mov	 PPL0STK_MAP,eax ; Restore it

	 mov	 ebx,PGROUP:[edx].DPTSS_PLNKTSS ; Get offset in PGROUP of prev TSS
	 mov	 eax,PGROUP:[ebx].DPTSS_LPMSTK_FVEC.FOFF ; Get offset of LPM stack top
	 mov	 LPMSTK_FVEC.FOFF,eax ; Restore it
	 mov	 ax,PGROUP:[ebx].DPTSS_LPMSTK_FVEC.FSEL ; Get offset of LPM stack top
	 mov	 LPMSTK_FVEC.FSEL,ax ; Restore it
	 mov	 eax,PGROUP:[ebx].DPTSS_LPMSTK_CNT ; Get previous LPM stack usage count
	 mov	 LPMSTK_CNT,eax ; Restore it

; Restore DPMI client's EGP registers from the previous TSS

	 mov	 eax,PGROUP:[edx].TSS_EAX ; Get caller's EAX
	 mov	 [ebp].INTXX_EAX,eax ; Save on stack
	 mov	 eax,PGROUP:[edx].TSS_EBX ; ... 	 EBX
	 mov	 [ebp].INTXX_EBX,eax ; ...
	 mov	 eax,PGROUP:[edx].TSS_ECX ; ... 	 ECX
	 mov	 [ebp].INTXX_ECX,eax ; ...
	 mov	 eax,PGROUP:[edx].TSS_EDX ; ... 	 EDX
	 mov	 [ebp].INTXX_EDX,eax ; ...
	 mov	 eax,PGROUP:[edx].TSS_ESI ; ... 	 ESI
	 mov	 [ebp].INTXX_ESI,eax ; ...
	 mov	 eax,PGROUP:[edx].TSS_EDI ; ... 	 EDI
	 mov	 [ebp].INTXX_EDI,eax ; ...
	 mov	 eax,PGROUP:[edx].TSS_EBP ; ... 	 EBP
	 mov	 [ebp].INTXX_EBP,eax ; ...

	 FIXICALL PGROUP:FCHECK_HOOK,DTE_CS2 ; See if we should unhook INT 15h

; De-link this TSS if we faulted in the middle of the chain
; Note that we *MUST* call this routine before we have reset PCURTSS.

	 call	 DPMIFN_DELINKTSS ; De-link 'em

; Back off to previous TSS and its selector
; Note we still need the value in EDX below

	 call	 DPMIFN_PLNKTSS ; Back off to previous TSS with EDX=PCURTSS

; If we terminated because of a fault, display an appropriate message
; Note we *MUST NOT* call this routine before we have reset PCURTSS and
; DPMITYPE.

	 call	 DPMIFN_FAULT	; Check it out using EDX = old PCURTSS

; If we previously enabled the 1MB wrap, ensure it's restored to
; its previous state
; Note we wait until after we've used and de-allocated the dynamic save
; area in case it's in the wrap region.

	 test	 PGROUP:[edx].DPTSS_FLAG,mask $DPTSS_WRAP ; Izit changed?
	 jz	 short @F	; Jump if so

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 and	 GLB_FLAG,not @GLB_X1MB ; Disable the virtual A20 line
	 FIXICALL PGROUP:FWRAP_ENABLE,DTE_CS2 ; Enable the 1MB wrap, ignore return
@@:

; Get the segment of the current PSP in case it's been switched on us
; Note that we can't use the DOSCALL macro as the value of LAST_INTCOM
; might not point to an INTXX_STR frame (it might be that of the DOS
; @EXITRC function and thus it's an INTDPI_STR frame).

;;;;;;;; DOSCALL @GETPS0	; Get PSP into BX
	 push	 edx		; Use HPDA stack in here
	 call	 DPMIFN_GETPSP	; Get PSP segment into BX using
				; the HPDA stack from EDX
	 movzx	 ecx,bx 	; Copy to convert to bytes
	 shl	 ecx,4-0	; Convert from paras to bytes

; Address the HPDA

	 mov	 ebx,PGROUP:[edx].DPTSS_LaHPDA ; Get linear address of HPDA

; Convert the caller's environment selector back to a segment

	 mov	 ax,AGROUP:[ebx].HPDA_ENVSEG ; Get the original environment segment

	 assume  gs:PSPGRP	; Tell the assembler about it
	 mov	 PSP_ENVIR_PTR[ecx],ax ; Set the environment selector
	 assume  gs:AGROUP	; Tell the assembler about it

; Zap the Terminate, Ctrl-Break, and Critical Error addresses in the HPDA
; so we continue with the next handler in sequence

	 mov	 AGROUP:[ebx].HPDA_I22DEF[0].ELO,@OPCOD_JMPS or \
				((HPDA_I22DEF2-HPDA_I22DEF-2) shl 8)
	 mov	 AGROUP:[ebx].HPDA_I23DEF[0].ELO,@OPCOD_JMPS or \
				((HPDA_I23DEF2-HPDA_I23DEF-2) shl 8)
	 mov	 AGROUP:[ebx].HPDA_I24DEF[0].ELO,@OPCOD_JMPS or \
				((HPDA_I24DEF2-HPDA_I24DEF-2) shl 8)

; If this client is BC 3.0 (DPMILOAD.EXE), it has clobbered the
; INT 22h address in the PSP by setting the offset but not the segment.
; Check for that and make it all better.

	 call	 DPMIFN_CHK22	; Fix it if it's broken

; If we're returning to the caller directly (as opposed to the
; INT 21h address in the PSP), skip restoring the INTXX_xxx registers

	 test	 I31_FLAG,mask $I31_RETCALL ; Return to caller?
	 jnz	 short INT31_VM2PM_RETOK3 ; Jump if so

; Note that if we don't use "dword ptr" on the HPDA_xxx values
; below MASM generates incorrect .OBJ code without any warning

	 mov	 eax,ebx	; Get linear address of HPDA
	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 [ebp].INTXX_CS,ax ; Save as return segment
	 mov	 [ebp].INTXX_EIP,dword ptr HPDA_INT21 ; Save as return EIP
	 mov	 [ebp].INTXX_SS,ax ; Save as return stack
	 movzx	 eax,HPDASTK_TOP ; Get offset of top of HPDA stack
	 mov	 [ebp].INTXX_ESP,eax ; Save as return ESP
	 mov	 [ebp].INTXX_EFL,(mask $VMHI) or (@VMIOPL shl $IOPL) or (mask $IF) ; Save flags

; Restore VM segment registers to the values present
; when the VM to PM switch was done

	 mov	 ax,AGROUP:[ebx].HPDA_vDS ; Get original DS
	 mov	 [ebp].INTXX_DS,ax ; Save as return DS
	 mov	 ax,AGROUP:[ebx].HPDA_vES ; ... 	 ES
	 mov	 [ebp].INTXX_ES,ax ; ...	    ES
	 mov	 ax,AGROUP:[ebx].HPDA_vFS ; ... 	 FS
	 mov	 [ebp].INTXX_FS,ax ; ...	    FS
	 mov	 ax,AGROUP:[ebx].HPDA_vGS ; ... 	 GS
	 mov	 [ebp].INTXX_GS,ax ; ...	    GS

	 mov	 ax,EXITRC	; Mark as exiting with return code
	 mov	 [ebp].INTXX_EAX.ELO,ax

; If we are terminating due to a TSR (resident service provider) request,
; then set the DOS function to 31h (keep process) and load the count of
; paragraphs to keep from global.

	 xor	 cx,cx		; A convenient zero
	 xchg	 cx,TSRsize	; Pick up size to TSR
	 jcxz	 short @F	; Jump if already zero

	 mov	 [ebp].INTXX_EDX.ELO,cx ; Store for DOS call
	 mov	 [ebp].INTXX_EAX.ELO.HI,@KEEPRC ; Set function code
@@:
INT31_VM2PM_RETOK3:
	 and	 I31_FLAG,@I31_PERCLIENT ; Isolate DPMI client-specific flags

	 push	 PVMTSS 	; Pass offset in PGROUP of the 1st TSS
	 call	 DPMIFN_LMSW	; Put MSW and INT 07h values into effect

	 popad			; Restore all EGP registers

	 add	 esp,size INTXX_ERR ; Strip off pseudo-error code

	 iretd			; Continue in VM in the HPDA at INT 21h

	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it



	 assume  ds:PGROUP,es:IGROUP  ; Tell the assembler about it
	 assume  fs:nothing,gs:AGROUP ; Tell the assembler about it

INT31_VM2PM_ERR1:
	 push	 PGROUP:[edx].TSS_ES ; Get selector to free
	 call	 CLR_LDT	; Free this LDT selector
;;;;;;;; jc	 short ???	; Ignore error return
INT31_VM2PM_ERR2:
	 push	 PGROUP:[edx].TSS_SS ; Get selector to free
	 call	 CLR_LDT	; Free this LDT selector
;;;;;;;; jc	 short ???	; Ignore error return
INT31_VM2PM_ERR3:
	 push	 PGROUP:[edx].TSS_DS ; Get selector to free
	 call	 CLR_LDT	; Free this LDT selector
;;;;;;;; jc	 short ???	; Ignore error return
INT31_VM2PM_ERR4:
	 push	 PGROUP:[edx].DPTSS_DTA_FVEC.FSEL ; Get selector to free
	 call	 CLR_LDT	; Free this LDT selector
;;;;;;;; jc	 short ???	; Ignore error return
INT31_VM2PM_ERR5:
	 push	 PGROUP:[edx].TSS_CS ; Get selector to free
	 call	 CLR_LDT	; Free this LDT selector
;;;;;;;; jc	 short ???	; Ignore error return
INT31_VM2PM_ERR_NOSEL:

; Deallocate dynamic save area

	 push	 DPMIDYN_SIZ	; Pass byte length
	 push	 PGROUP:[edx].DPTSS_DYN ; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:
INT31_VM2PM_ERR_NOMEM2:

; Deallocate DPMI memory handle structure

	 push	 DPMIHNDL_SIZ	; Pass byte length
	 push	 PGROUP:[edx].DPTSS_LaDPMIHNDL ; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:
INT31_VM2PM_ERR_NOMEM3:

; Deallocate old LDT and restore new one

	 call	 DPMIFN_FREELDT ; Free it
INT31_VM2PM_ERR_NOMEM4:
INT31_VM2PM_ERR_NOMEM5:

; Deallocate DPMI LPM stack

	 push	 LPMSTK_SIZ	; Pass byte length
	 push	 PGROUP:[edx].DPTSS_LPMBASE ; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:
INT31_VM2PM_ERR_NOMEM6:

; If we previously enabled the 1MB wrap, ensure it's restored to
; its previous state

	 test	 PGROUP:[edx].DPTSS_FLAG,mask $DPTSS_WRAP ; Izit changed?
	 jz	 short @F	; Jump if so

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 and	 GLB_FLAG,not @GLB_X1MB ; Disable the virtual A20 line
	 FIXICALL PGROUP:FWRAP_ENABLE,DTE_CS2 ; Enable the 1MB wrap, ignore return
@@:
INT31_VM2PM_ERR_NOMEM7:

; Restore the incoming PM data area

	 push	 @BIT0		; Tell 'em we're terminating
	 push	 PGROUP:[edx].DPTSS_PLNKTSS ; Get offset in PGROUP of prev TSS
	 call	 DPMIFN_RESTOLDPM ; Restore it

; De-allocate the outgoing PM data area

	 push	 DPMIOLDPM_SIZ	; Pass byte length
	 push	 PGROUP:[edx].DPTSS_OLDPM ; Pass linear address of old PM data area
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:
INT31_VM2PM_ERR_NOMEM8:

; If this is the first DPMI client, de-allocate memory
; for the current PMxxT_xVECS and other variables
; Note that this routine must be called *BEFORE* PCURTSS has been
; restored to the incoming TSS.

	 call	 DPMIFN_FREE_VMOLDPM ; Free it
INT31_VM2PM_ERR_NOMEM9:
	 FIXICALL PGROUP:FCHECK_HOOK,DTE_CS2 ; See if we should unhook INT 15h

if @OEM_VIRTUALMEM

; Terminate this client and the VMM system if this is the last client

	 test	 VMM_FLAG,@VMM_SYSINIT ; Is VMM active?
	 jz	 short @F	; Jump if not

	 call	 VMM_TERMINATE_CLIENT ; Terminate the current client (PCURTSS)
@@:
endif				; IF @OEM_VIRTUALMEM

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 bx,PGROUP:[edx].DPTSS_SEL ; Get the next TSS selector
	 and	 DESC_TAB.DESC_ACCESS[bx],not (mask $DS_BUSY) ; Mark as not busy

; Back off to previous TSS and its selector

	 call	 DPMIFN_PLNKTSS ; Back off to previous TSS with EDX=PCURTSS

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS
	 lldt	 PGROUP:[edx].TSS_LDT ; Set LDTR
	 mov	 bx,PGROUP:[edx].DPTSS_SEL ; Get the next TSS selector
	 and	 DESC_TAB.DESC_ACCESS[bx],not (mask $DS_BUSY) ; Mark as not busy
	 ltr	 bx		; Tell the CPU about it

	 mov	 ax,VM2PM_ERR	; Return error code
INT31_VM2PM_ERRCOM:
	 mov	 bl,DPMITYPEIG	; Restore original DPMITYPE value
	 mov	 DPMITYPE,bl	; Restored

	 or	 [ebp].INTXX_EFL.ELO,mask $CF ; Indicate we failed

; In order to be compatible with the code at EMM_EXIT,
; we need to save LAST_INTCOM on the stack and increment
; LAST_INTCNT because EMM_EXIT restores LAST_INTCOM from
; the stack and clears LAST_INTFLG.

	 lea	 ebx,[ebp].INTXX_EIP ; Get offset of INTCOM-restartable point
	 xchg	 ebx,LAST_INTCOM ; Swap with the last one
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 ebx,0		; Save previous flag
	 mov	 [ebp].INTXX_ICOMLO,bx ; Save to restore later
	 shr	 ebx,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_ICOMHI,bx ; Save to restore later

; If the error is caused by Ctrl-Break during swapfile initialization,
; we need to IRETD to code in the HPDA which issues an Int 23, then
; checks for abort.  If not aborting, we have an IRET frame pointing
; to the original return address, and we just IRET there.  If aborting,
; we need to set the reason for termination to Ctrl-Break.
	 cmp	 ax,@DERR_CTRLBREAK_SWP ; Izit Ctrl-Break during swapfile init?
	 jne	 short @F	; Jump if not

	 FIXICALL JGROUP:CPY_DL2GROUP,DTE_CSJG ; Set up return to code in HPDA

@@:
	 FIXIJMP PGROUP:EMM_EXIT,DTE_CS2 ; Join common EMM exit code
				; with result in AX

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT31	 endp			; End INT31 procedure
	 NPPROC  DPMIFN_CHK22 -- Check INT 22h In The PSP
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

If this client is BC 3.0 (DPMILOAD.EXE), it has clobbered the
INT 22h address in the PSP by setting the offset but not the segment.
Check for that and make it all better.

On entry:

EBX	 =	 linear address of HPDA
ECX	 =	 linear address of PSP

|

	 REGSAVE <eax,esi>	; Save registers

; See if it's our friend DPMILOAD.EXE

	 mov	 si,MSG_APPLNAME.LENTXT_LEN ; Get word length of application
	 add	 si,size LENTXT_LEN ; Count in length word

	 cmp	 MSG_APPLNAME.EDD[si-4],'EXE.' ; Izit ".EXE"?
	 jne	 short DPMIFN_CHK22_EXIT ; Jump if not

	 cmp	 MSG_APPLNAME.EDD[si-8],'DAOL' ; Izit "LOAD"?
	 jne	 short DPMIFN_CHK22_EXIT ; Jump if not

	 cmp	 MSG_APPLNAME.EDD[si-12],'IMPD' ; Izit "DPMI"?
	 jne	 short DPMIFN_CHK22_EXIT ; Jump if not

; If the segment portion of the PSP_TERMINATE address is that of
; our HPDA, but the offset portion doesn't match any of our entry
; addresses, then it must be invalid.

	 mov	 eax,ebx	; Copy HPDA linear address
	 shr	 eax,4-0	; Convert from bytes to paras

	 assume  gs:PSPGRP	; Tell the assembler about it
	 cmp	 ax,PSP_TERMINATE[ecx].VSEG ; Izit our segment?
	 assume  gs:AGROUP	; Tell the assembler about it
	 jne	 short DPMIFN_CHK22_EXIT ; Jump if not

	 assume  gs:PSPGRP	; Tell the assembler about it
	 mov	 ax,PSP_TERMINATE[ecx].VOFF ; Get the offset
	 assume  gs:AGROUP	; Tell the assembler about it

; Check the offset portion against all the legitimate offsets
; in our HPDA.

	 cmp	 ax,HPDA_SIMRET ; Izit SIMRET?
	 je	 short DPMIFN_CHK22_EXIT ; Jump if so

	 cmp	 ax,HPDA_I22DEF ; Izit INT 22h?
	 je	 short DPMIFN_CHK22_EXIT ; Jump if so

; Set the segment portion of the PSP_TERMINATE address to
; that of the original address.

	 mov	 ax,AGROUP:[ebx].HPDA_I22VEC.VSEG ; Get the original segment

	 assume  gs:PSPGRP	; Tell the assembler about it
	 mov	 PSP_TERMINATE[ecx].VSEG,ax ; Save as the segment
	 assume  gs:AGROUP	; Tell the assembler about it
DPMIFN_CHK22_EXIT:
	 REGREST <esi,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_CHK22 endp		; End DPMIFN_CHK22 procedure
	 NPPROC  DPMIFN_NEWLINE -- Start On A New Line
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Start on a new line

|

	 REGSAVE <ax>		; Save registers

	 mov	 al,CR		; Start a new line
	 VIDCALL @SETTTY	; Write to screen

	 mov	 al,LF		; Start a new line
	 VIDCALL @SETTTY	; Write to screen

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_NEWLINE endp		; End DPMIFN_NEWLINE procedure
	 NPPROC  DPMIFN_LMSW -- Load New MSW For DPMI Client
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Load the MSW for a DPMI client.

|

DPMIFN_LMSW_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
DPMIFN_LMSW_TSS dd ?		; Offset in PGROUP of the TSS to use

DPMIFN_LMSW_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,edx>	; Save registers

	 mov	 edx,[ebp].DPMIFN_LMSW_TSS ; Get offset in PGROUP of the TSS

COMMENT|

Note we don't change the global value of the MP bit as
the DPMI client's value tells us whether or not to save
the NDP state when we switch tasks, not the presence of
an NDP.

Because we're not a multitasking OS, we can ignore this
information.

|

	 smsw	 ax		; Get current MSW
	 and	 ax,not (mask $EM) ; Clear EM bit
	 mov	 bx,PGROUP:[edx].DPTSS_MSW ; Get this client's MSW
	 and	 bx,mask $EM	; Isolate EM bit
	 or	 ax,bx		; Include client's EM bit
	 lmsw	 ax		; Set into effect

; Put into effect the appropriate IDT entry for INT 07h

	 mov	 eax,PGROUP:[edx].DPTSS_IDT07.EDQLO ; Get low-order dword
	 mov	 IDT_DESC.EDQLO[07h*(type IDT_DESC)],eax ; Save into the IDT

	 mov	 eax,PGROUP:[edx].DPTSS_IDT07.EDQHI ; Get high-order dword
	 mov	 IDT_DESC.EDQHI[07h*(type IDT_DESC)],eax ; Save into the IDT

	 REGREST <edx,ebx,eax>	; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_LMSW endp		; End DPMIFN_LMSW procedure
	 FPPROC  FDPMIFN_LMSW -- Load New MSW For DPMI Client
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Far call to DPMIFN_LMSW

On entry:

Same as DPMIFN_LMSW.

On exit:

Same as DPMIFN_LMSW.

|

FDPMIFN_LMSW_STR struc

	 dd	 ?		; Caller's CS|EIP
FDPMIFN_LMSW_TSS dd ?		; Offset in PGROUP of the TSS to use

FDPMIFN_LMSW_STR ends

	 push	 [esp].FDPMIFN_LMSW_TSS ; Pass offset in PGROUP of the TSS
	 call	 DPMIFN_LMSW	; Put MSW and INT 07h values into effect

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMIFN_LMSW endp		; End FDPMIFN_LMSW procedure
	 NPPROC  DPMIFN_GETPSP -- Get PSP
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get PSP into BX using the HPDA stack from stack argument

On exit:

BX	=	 segment of the current PSP

|

PSPSTK_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
PSPSTK_PTSS dd	 ?		; Offset in PGROUP of TSS to use

PSPSTK_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ax,cx,edi,es> ; Save registers

	 mov	 es,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 SAVE_VMCREGS	; Save current values of VMCREGS on stack

	 mov	 edi,[ebp].PSPSTK_PTSS ; Get offset in PGROUP of TSS

	 mov	 VMCREGS.VMC_EAX.ELO.HI,@GETPS0 ; Save DOS function

	 mov	 ax,PGROUP:[edi].DPTSS_VMSTKOFF ; Get current stack offset
	 mov	 VMCREGS.VMC_SP,ax ; Use as new SP

	 sub	 ax,@HPDAFRM_SIZ ; Make room for a level
;;;;;;;; jb	 short DPMIFN_GETPSP_VMFULL ; Jump if there's no more room
;;;;;;;;
;;;;;;;; cmp	 ax,PGROUP:[edi].DPTSS_VMSTKBOT ; Izit below the bottom?
;;;;;;;; jb	 short DPMIFN_GETPSP_VMFULL ; Jump if so
;;;;;;;;
	 push	 PGROUP:[edi].DPTSS_VMSTKOFF ; Save the old value

	 mov	 PGROUP:[edi].DPTSS_VMSTKOFF,ax ; Make room for a level

	 mov	 ax,PGROUP:[edi].DPTSS_VMSTKSEG ; Get current stack segment
	 mov	 VMCREGS.VMC_SS,ax ; Use as new SS

	 mov	 VMCREGS.VMC_FL,0 ; Set to known value

	 mov	 bx,21h 	; BL = Interrupt #, BH = flags (none)
	 xor	 cx,cx		; # words to copy
	 lea	 edi,VMCREGS	; ES:EDI ==> VMC register structure
	 DPMICALL0 @DPMI_SIMVMI  ; Request DPMI service
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
	 mov	 edi,[ebp].PSPSTK_PTSS ; Get offset in PGROUP of TSS

	 pop	 PGROUP:[edi].DPTSS_VMSTKOFF ; Restore the old value

	 mov	 bx,VMCREGS.VMC_EBX.ELO ; Get the segment #

	 call	 REST_VMCREGS	; Restore old values of VMCREGS from stack

	 REGREST <es,edi,cx,ax> ; Restore
	 assume  es:IGROUP	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_GETPSP endp		; End DPMIFN_GETPSP procedure
	 NPPROC  DPMIFN_SETPSP -- Set PSP
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set PSP to BX using the HPDA stack stack argument

On entry:

BX	 =	 segment of PSP to set

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ax,cx,edi,es> ; Save registers

	 mov	 es,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 SAVE_VMCREGS	; Save current values of VMCREGS on stack

	 mov	 edi,[ebp].PSPSTK_PTSS ; Get offset in PGROUP of TSS

	 mov	 VMCREGS.VMC_EAX.ELO.HI,@SETPSP ; Save DOS function

	 mov	 ax,PGROUP:[edi].DPTSS_VMSTKOFF ; Get current stack offset
	 mov	 VMCREGS.VMC_SP,ax ; Use as new SP

	 sub	 ax,@HPDAFRM_SIZ ; Make room for a level
;;;;;;;; jb	 short DPMIFN_SETPSP_VMFULL ; Jump if there's no more room
;;;;;;;;
;;;;;;;; cmp	 ax,PGROUP:[edi].DPTSS_VMSTKBOT ; Izit below the bottom?
;;;;;;;; jb	 short DPMIFN_SETPSP_VMFULL ; Jump if so
;;;;;;;;
	 push	 PGROUP:[edi].DPTSS_VMSTKOFF ; Save the old value

	 mov	 PGROUP:[edi].DPTSS_VMSTKOFF,ax ; Make room for a level

	 mov	 ax,PGROUP:[edi].DPTSS_VMSTKSEG ; Get current stack segment
	 mov	 VMCREGS.VMC_SS,ax ; Use as new SS

	 mov	 VMCREGS.VMC_FL,0 ; Set to known value
	 mov	 VMCREGS.VMC_EBX.ELO,bx ; Save incoming PSP

	 mov	 bx,21h 	; BL = Interrupt #, BH = flags (none)
	 xor	 cx,cx		; # words to copy
	 lea	 edi,VMCREGS	; ES:EDI ==> VMC register structure
	 DPMICALL0 @DPMI_SIMVMI  ; Request DPMI service
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
	 mov	 edi,[ebp].PSPSTK_PTSS ; Get offset in PGROUP of TSS

	 pop	 PGROUP:[edi].DPTSS_VMSTKOFF ; Restore the old value

	 call	 REST_VMCREGS	; Restore old values of VMCREGS from stack

	 REGREST <es,edi,cx,ax> ; Restore
	 assume  es:IGROUP	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_SETPSP endp		; End DPMIFN_SETPSP procedure
	 NPPROC  DPMIFN_TERMINATE -- Handle DPMI Client Termination
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle DPMI client termination

If there are any activities which need to be done at
termination time when PCURTSS and TR match, now's the time

On exit:

IF	 =	 0
DS, FS, GS clobbered.
ES	 =	 PGROUP

|

	 REGSAVE <eax,edx>	; Save registers

	 cli			; Disable interrupts because we switch back
				; to the previous address space and can't
				; afford HW interrupts to be reflected to VM

	 xor	 dx,dx		; A convenient zero
	 mov	 fs,dx		; Zero in case it's in the LDT
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 es,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  es:IGROUP	; Tell the assembler about it

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it

; Notify Resident Service Providers that client is terminating

	 mov	 ah,1		; Flag termination
	 mov	 al,DPMITYPEIG	; Pass client bitness
	 FIXICALL JGROUP:DPMIFN_CALL_RSPS,DTE_CSJG ; Notify RSPs

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS
	 and	 PGROUP:[edx].DPTSS_FLAG,not (mask $DPTSS_INIT) ; Mark as not initialized

; If the terminating DPMI client is Windows 3.00, restore PL1 state to @DPMI_CPL

	 test	 I31_FLAG,mask $I31_KRNL ; Izit the KRNL?
	 jz	 short @F	; Jump if not

	 test	 I31_FLAG,mask $I31_WIN3 ; Izit Windows 3.00?
	 jz	 short @F	; Jump if not

	 call	 DPMIFN_RESTWIN ; Restore the state
@@:

; Free memory allocated to this client

	 call	 DPMIFN_FREEMEM ; Free 'em

; Restore data in the dynamic save area

	 call	 DPMIFN_RESTDYN ; Restore it

; Restore the incoming PM data area

; We're about to restore I31_FLAG (among other things).
; Because we need the current value for a bit longer, we
; save it, and exchange it with the incoming value until
; we finish terminating.

	 mov	 ax,I31_FLAG	; Get current value

	 push	 @BIT0		; Tell 'em we're terminating
	 push	 PGROUP:[edx].DPTSS_PLNKTSS ; Get offset in PGROUP of prev TSS
	 call	 DPMIFN_RESTOLDPM ; Restore it

	 xchg	 ax,I31_FLAG	; Swap back the original value

; De-allocate the outgoing PM data area

	 push	 DPMIOLDPM_SIZ	; Pass byte length
	 push	 PGROUP:[edx].DPTSS_OLDPM ; Pass linear address of old PM data area
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:

; If this is the first DPMI client, de-allocate memory
; for the current PMxxT_xVECS and other variables
; Note that this routine must be called *BEFORE* PCURTSS has been
; restored to the incoming TSS.

	 call	 DPMIFN_FREE_VMOLDPM ; Free it

; Deallocate DPMI LPM stack

	 cmp	 PGROUP:[edx].DPTSS_LPMBASE,0 ; Izit initialized as yet?
	 je	 short @F	; Jump if not

	 push	 LPMSTK_SIZ	; Pass byte length
	 push	 PGROUP:[edx].DPTSS_LPMBASE ; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:
	 mov	 PGROUP:[edx].DPTSS_LPMBASE,0 ; Mark as not initialized

	 mov	 es,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_SYSINIT ; Is VMM active?
	 jz	 short @F	; Jump if not

	 call	 VMM_TERMINATE_CLIENT ; Terminate the current client (PCURTSS)

	 jmp	 short DPMIFN_TERMINATE1 ; Join common code

@@:
endif				; IF @OEM_VIRTUALMEM

; Deallocate old LDT and restore new one

	 call	 DPMIFN_FREELDT ; Free it
DPMIFN_TERMINATE1:

; If there was a Swapped Mouse Interrupt Subroutine,
; restore the original one now
; Note we must do this in the current TSS so that PCURTSS and
; TR match.

	 call	 DPMIFN_RESTMEI ; Restore it

	 mov	 I31_FLAG,ax	; Save it for real

	 REGREST <edx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_TERMINATE endp		; End DPMIFN_TERMINATE procedure
	 align	 4		; Ensure dword alignment

ICODE	 ends			; End ICODE segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 extrn	 DPMIFN_CALL_RSPS:far

	 FPPROC  CPY_DL2GROUP -- Copy Int 23 code to HPDA
	 assume  ds:PGROUP,es:IGROUP,fs:nothing,gs:AGROUP
COMMENT|

Copy Int 23 code to HPDA and set up return stack.

If Ctrl-Break was pressed during swapfile initialization (BREAK=ON),
we need to ignore it until we're done initializing the swapfile.
Then we abort client initialization, and call this procedure to
set up VM code to call the current Int 23 handler.  If we're to
ignore the Ctrl-Break, we return to the code which called the
Enter Protected Mode address returned by Int 2f fn 1687.  If we're
to abort, we need to set the Int 21 fn 4d return code in QMAX_OVR.

On entry:
CLD		In effect
SS:EBP ==>	INTXX_STR:
		INTXX_ES = segment of HPDA
		INTXX_EIP.ELO = Return IP to modify
		INTXX_CS = Return CS to modify

On exit:
SS:EBP.INTXX_EIP ==> GENINT23
SS:EBP.INTXX_CS = HPDA segment
DL2GROUP code and data initialized and copied to HPDA segment

|

	 REGSAVE <eax,ecx,esi,edi,es,fs> ; Save

	 mov	 fs,SEL_DSJG3	; Address JGROUP
	 assume  fs:JGROUP	; Tell the assembler

	 mov	 ax,[ebp].INTXX_ES ; Get HPDA segment
	 movzx	 edi,ax 	; Save destination segment
	 xchg	 ax,[ebp].INTXX_CS ; Set new return segment and get previous
	 shl	 eax,16 	; Move segment to high word of vector
	 mov	 ax,offset DL2GROUP:GENINT23 ; Offset of entry point in HPDA
	 xchg	 ax,[ebp].INTXX_EIP.ELO ; Set return offset and get previous

	 sub	 esi,esi	; Clear high word
	 mov	 si,seg DL2GROUP ; Get DL2GROUP segment
	 sub	 si,seg JGROUP	; ESI = offset in paras from JGROUP base
	 shl	 esi,4-0	; Convert paras to bytes

	 assume  fs:DL2GROUP	; Tell a little white lie
	 mov	 DL2_PMERET[esi],eax ; Return address if ignoring Ctrl-Break
	 mov	 ax,IGROUP:INT31A_HIMEM_CS.ELO ; Get high DOS PGROUP segment
	 mov	 DL2_PGRSEG[esi],ax ; Save for later
	 assume  fs:JGROUP	; Retract nose

	 push	 gs		; Get AGROUP selector
	 pop	 es		; Address for REP MOVS
	 assume  es:AGROUP	; Tell the assembler

	 shl	 edi,4-0	; Convert destination segment to address
	 lea	 ecx,DL2GROUP:DL2GROUP_END[4-1] ; Address end of DL2GROUP
	 shr	 ecx,2-0	; Convert bytes to dwords

S32 rep  movs	 <AGROUP:[edi].EDD,JGROUP:[esi].EDD> ; Copy DL2GROUP downstairs

	 REGREST <fs,es,edi,esi,ecx,eax> ; Restore
	 assume  es:nothing,fs:nothing ; Tell the assembler

	 ret			; Return to caller

CPY_DL2GROUP endp		; End CPY_DL2GROUP procedure

JCODE	 ends			; End JCODE segment

endif				; IF @OEM_DPMI

	 MEND			; End QMAX_I31 module

;' $Header:   P:/PVCS/MAX/386MAX/QMAX_EM2.ASV   1.8   30 May 1997 10:44:20   BOB  $
	 title	 QMAX_EM2 -- 386MAX INT 67h Handler, EMM2 Functions
	 page	 58,122
	 name	 QMAX_EM2

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Data    segment JDATA, dword-aligned, public, class 'jcode'
	       Group XGROUP:
	       Data    segment WBPAT_SEG, word-aligned, public, class 'xdata'
	       Group DLGROUP:
	       Data    segment DLDATZ,	dword-aligned, public, class 'dlcode'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include CPUID.INC
	 include 8255.INC
	 include BITFLAGS.INC
	 include BIOSDATA.INC
	 include MASM5.MAC
	 include ALLMEM.INC
	 include CPUFET.INC
	 include IOPBITS.INC
	 include MOVSPR.INC
	 include MSR.INC
	include PNP.INC
	include CPUFLAGS.INC

	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_TIM.INC
	 include QMAX_TSS.INC
	 include QMAX_XMS.INC
	 include QMAXWIN3.INC
	 include PDTGRP.INC
.list

PGROUP	 group	 CODE,HICODE,ECODE,EDATA
IGROUP	 group	 LCODE,LDATA
JGROUP	 group	 JCODE,JDATA
XGROUP	 group	 WBPAT_SEG
CGROUP	 group	 CPUID_SEG
DLGROUP  group	 DLDATZ


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 SHADOW_DISABLE:near

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

	 extrn	 DB3_FLAG:word
	 include QMAX_DB3.INC

	 extrn	 INFO:tbyte,INFOSIZE:abs
	 extrn	 TOTSIZE:dword
if @OEM_EMS
;;;;;;;; extrn	 EMMSIZE:dword
endif				; IF @OEM_EMS
	 extrn	 IDT_REAL:fword
	 extrn	 PRGSIZE:word
	 extrn	 PLOWSTKZ:word
	 extrn	 POVR_MAC:word

	extrn	LO_PGET_WINVXD_VEC:dword

CODE	 ends			; End CODE segment


HICODE	segment use16 dword public 'prog' ; Start HICODE segment
	assume	ds:PGROUP

	extrn	HI_PGET_WINVXD_VEC:dword

HICODE	ends			; End HICODE segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DSIG3:word
	 extrn	 ISEL_4GB3:word
	 extrn	 ISEL_DS3:word

LDATA	 ends			; End LDATA segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
	 assume  ds:JGROUP

	 extrn	 JSEL_DS3:word

JDATA	 ends			; End JDATA segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 MAPTAB:tbyte,MAPTAB_CNT:word
	 include QMAX_MAP.INC

	 extrn	 MCSTAB:tbyte,MCSTAB_CNT:word
	 include QMAX_MCS.INC

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

if @OEM_SOFT
	 extrn	 @IO_LIM:abs
	 extrn	 REP_FAC:word
endif				; IF @OEM_SOFT

if @OEM_WIN3
	 extrn	 WIN3_REF_DATA:tbyte
	 extrn	 VXD_LEVEL:word

	 extrn	 SEL_DATA:word
	 extrn	 SEL_DS3:word
	 extrn	 SEL_4GB:word
	 extrn	 SEL_4GB3:word
	 extrn	 SEL_PDT:word
	 extrn	 SEL_DSHI:word
	 extrn	 SEL_DSIG3:word
	 extrn	 SEL_DSJG3:word
	 include EMM2CALL.INC
endif				; IF @OEM_WIN3
	 extrn	 FILES_STR_LEN:byte
	 extrn	 LOADBYTE:dword
	 extrn	 PRGBASE:dword
	 extrn	 DESC_TAB:qword
;;;;;;;; extrn	 PGDT_LLO:fword
if @OEM_EMS
	 extrn	 EMM_FLAG:word
	 include QMAX_EMM.INC
endif				; IF @OEM_EMS

if @OEM_XMS
	 extrn	 CMPSIZEMM:dword
	 extrn	 EXTBASE:dword
	 extrn	 PXMSBMAP:dword
	 extrn	 XMSBMAP_LEN:dword
	 extrn	 XHNDLCNT:word
endif				; IF @OEM_XMS

	 extrn	 PPMTAB:byte,PPMTAB_LEN:abs

	 extrn	 PPHNDLVMS:dword

	 extrn	 PPL0STK_INI:dword
	 extrn	 PPL0STK_MAP:dword
	 extrn	 PVMTSS:dword
if @OEM_DMA
	 extrn	 DMA_CHAN:byte
endif				; IF @OEM_DMA
if @OEM_EMS
	 extrn	 HMAP:byte,@HMAPSIZE:abs
	 extrn	 PHNDLPAGE:dword
	 extrn	 PPHNDLFREE:dword
	 extrn	 PHNDLCNT:dword
	 extrn	 PPAGELINK:dword
	 extrn	 PLINKBASE:dword
	 extrn	 PHNDLNAME:dword
	 extrn	 PPHYS2SEG:dword
	 extrn	 PSEG2PHYS:dword
	 extrn	 EMMBASE:dword
	 extrn	 PBASEPAGE:dword
	 extrn	 BASEPAGE_LEN:dword
endif				; IF @OEM_EMS
	 extrn	 PPDTSCR:dword
	 extrn	 PPDTCNV:dword
if @OEM_EMS
	 extrn	 PPDTEMM:dword
	 extrn	 PPDTFRM:dword
	 extrn	 PPDTFRMZ:dword
endif				; IF @OEM_EMS
	 extrn	 PPDTUNW:dword
	 extrn	 UNWCNT:word
	 extrn	 MSG_STAT:byte,MSG_STATLEN:abs
	 extrn	 CON4KB:dword
	 extrn	 CON64KB:dword
	 extrn	 CON256KB:dword
if @OEM_EMS
	 extrn	 PRPNTAB:dword
	 extrn	 PRPNCUR:dword
	 extrn	 PHFRMSAV:dword
	 extrn	 EHNDLCNT:word
	 extrn	 NPHYS16F:byte
	 extrn	 NPHYS16S:byte
	 extrn	 NPHYSCNV:byte
	 extrn	 NPHYSSCR:byte
	 extrn	 MRS_CUR:byte

	 extrn	 HP_LAST:dword
	 extrn	 @MAX_EHNDLCNT:abs
	 extrn	 @RPN_UNUSED:abs
	 extrn	 @RPN_IDENT:abs
	 extrn	 @RPN_UNMAP:abs
	 extrn	 MAXRPN:dword
endif				; IF @OEM_EMS
	 extrn	 HARDCNT:word

	 extrn	 PIOBIT:dword

	 extrn	 CPUTYPE:byte

if @OEM_DPMI
	 extrn	 NEWIMR1:word
	 extrn	 NEWIMR2:word
endif				; IF @OEM_DPMI

	 extrn	 POSDATA:byte
	 include QMAX_POS.INC

	 extrn	 HIMEM_CS:word

	 extrn	 CPUFET_FLAG:dword

	extrn	PnP_VEC:dword

SEL_PnPCS equ	<PnP_VEC.VSEG>

	 public  BASEPAGE_INV
@BASEPAGE_INV equ -2		; Invalid marker for BASEPAGE table
BASEPAGE_INV dd @BASEPAGE_INV	; ...

	public	LaPL3STK
LaPL3STK dd	?		; Linear address of PL3 stack

	public	GDTR_PnP,LaGDTPnPARG
GDTR_PnP label	fword
	dw	?		; GDTR limit
LaGDTPnPARG dd	?		; Linear address of PnP argument selectors in GDT

	public	SEL_PnPDS,SEL_PnPARG0,SEL_PnPARG1,SEL_PnPARG2
SEL_PnPDS dw	DTE_PnPDS	; PnP data selector
SEL_PnPARG0 dw	DTE_PnPARG0	; ... data argument selector #0
SEL_PnPARG1 dw	DTE_PnPARG1	; ...			      1
SEL_PnPARG2 dw	DTE_PnPARG2	; ...			      2

	 public  EMSPGCNT
EMSPGCNT dw	 ?		; Used by INIT_DATA to include all
				; possible EMS pages excluding CNV entries

	 public  IDT_REBOOT
IDT_REBOOT df	 0		; IDT with zero limit to reboot the system

if @OEM_DPMI
	 public  DPMI_HWSP,DPMI_HW,DPMI_CPIHOOK,DPMI_CPFHOOK
	 public  DPMI_PPIHOOK,DPMI_PVFHOOK,DPMI_CVFHOOK
DPMI_HWSP db	 (256/8) dup (?) ; Bit map for HW/SP interrupts
DPMI_HW  db	 (256/8) dup (?) ; ...	       HW    ...

COMMENT|

The totality of exceptions (EX), software (SW), hardware (HW), and
special (1C/23/24) interrupts in VM/MAX/DPMI which may occur are as
follows:

Current Client		Primary Client		Not Presented To Any Client
---------------------------------------------------------------------------
23 VM			HW VM			SW VM
24 VM			EX VM
			1C VM
EX MAX			HW MAX			SW MAX
						1C MAX*
						23 MAX*
						24 MAX*
SW DPMI 		HW DPMI
EX DPMI
1C DPMI*
23 DPMI*
24 DPMI*

The above table comes from reading the DPMI 1.0 spec.  The distinction
between 1C (primary) and 23/24 (current) VM interrupts is not
specifically covered by the spec and it is our (Steve/Fred/Bob's)
interpretation.

* = does not (if in MAX) or should not (if in DPMI) occur.

|

DPMI_CPIHOOK db  (256/8) dup (0) ; Bit map for any PM interrupts hooked by DPMI
				; current clients.
				; Test this for col #1 SW interrupts and special
				; (23/24) VM interrupts.
DPMI_CPFHOOK db  (32/8) dup (0) ; Bit map for any PM faults hooked by DPMI
				; current clients.
				; Test this for col #1 exceptions.
DPMI_PPIHOOK db  (256/8) dup (0) ; Bit map for any PM interrupts hooked by DPMI
				; primary client.
				; Test this for col #2 HW interrupts and special
				; (1C) VM interrupts.
DPMI_PVFHOOK db  (32/8) dup (0) ; Bit map for any VM faults hooked by DPMI
				; primary client.
				; Test this for col #2 exceptions.
DPMI_CVFHOOK db  (32/8) dup (0) ; Bit map for any VM faults hooked by DPMI
				; current client.  This variable is not tested
				; for any event.  It is used to hold the current
				; state which is copied to/from the old PM area
				; and when this client becomes the primary
				; client, it is copied to DPMI_PVFHOOK.
endif				; IF @OEM_DPMI

if @OEM_HARPO
@SUBSEG_CNT equ 20	; Make room for 20 entries

	 public  SUBSEG_INFO
SUBSEG_INFO SUBSEG_STR @SUBSEG_CNT dup (<0,0,0,0>) ; Holds info on variable
					; length High DOS allocators

	 public  SUBSEG_PTR
SUBSEG_PTR dw	 offset PGROUP:SUBSEG_INFO ; Dynamic ptr to next table element

	 public  HARPO_FILESPEC
HARPO_FILESPEC db 80 dup (0)	; Drive:\path\name.ext of HARPO profile
endif				; IF @OEM_HARPO

EDATA	 ends			; End EDATA segment


DLDATZ	 segment use16 dword public 'dlcode' ; Start DLDATZ segment
	 assume  ds:DLGROUP

	 extrn	 DLGROUP_END:word

DLDATZ	 ends			; End DLDATZ segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_EM2_ECODE
@QMAX_EM2_ECODE:		; Mark module start in .MAP file

	 extrn	 FENABLE_NMI:far
	 extrn	 FWRAP_DISABLE:far

	 extrn	 FFLUSH_TLB:far
if @OEM_TIMEMEM
	 extrn	 TIME_MEM:far
endif				; IF @OEM_TIMEMEM
	 extrn	 SETBASE:far
	 extrn	 EMM_E00AL:near
	 extrn	 EMM_E8F:near
	 extrn	 EMM_ERR:near
	 extrn	 EMM_EXIT:near
if @OEM_EMS
	 extrn	 EMM_EA4:near
	 extrn	 PGMAP_ALL:near
endif				; IF @OEM_EMS
	 extrn	 FPL3ESDI:far
	 extrn	 FSET_GDT:far
	 extrn	 EMM_EXIT_GOREAL:near
	 extrn	 SET_EXTMEM_CS:far
	 extrn	 FOPENHIGHDOS:far
	 extrn	 FCLOSEHIGHDOS:far
if @OEM_WIN3
if @OEM_XMS
	 extrn	 SET_XMSBND:near
endif				; IF @OEM_XMS
endif				; IF @OEM_WIN3

	 extrn	 CACHE_INVD:near

JMM2_MAC macro	 NAM

	 public  EMM2_&NAM
EMM2_&NAM:
	 FIXIJMP JGROUP:JMM2_&NAM,DTE_CSJG

	 endm			; EMM2_MAC

	 JMM2_MAC GETMCS	; Function 01h
	 JMM2_MAC GETMAP	; Function 02h
	 JMM2_MAC GETINFO	; Function 03h
	 JMM2_MAC GETPPM	; Function 04h
	 JMM2_MAC MEMTIME	; Function 06h
	 JMM2_MAC GOREAL	; Function 07h
	 JMM2_MAC HIMEM 	; Function 08h
	 JMM2_MAC CURSOR	; Function 0Eh
	 JMM2_MAC POSCOPY	; Function 14h
	 JMM2_MAC GETTEXT	; Function 16h
	 JMM2_MAC HARPOINFO	; Function 23h
	 JMM2_MAC GSLINK58	; Function 24h
	 JMM2_MAC MALLOC	; Function 26h
	 JMM2_MAC DLGROUP	; Function 27h
	 JMM2_MAC PnP		; Function 2Ah
	 JMM2_MAC PnP1		; Function 2Ah, from Windows

	 NPPROC  EMM2_REBOOT -- EMM2 System Reboot
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 15, AH = 0Fh

System reboot.

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

;;;;	 mov	 bx,seg BIOSDATA ; Get segment of BIOS data area
;;;;	 shl	 bx,4-0 	; Convert from paras to bytes
;;;;	 assume  es:BIOSDATA	; Tell the assembler about it
;;;;
;;;;	 mov	 RESET_FLAG[bx],1234h ; Set flag to avoid memory test
;;;;
;;;;	 assume  es:AGROUP	; Tell the assembler about it

; Copy our code to the first megabyte
; but not above 9F000h in case there's an XBDA (up to 16KB in length).

	 mov	 esi,PRGBASE	; ES:ESI ==> source
	 mov	 edi,CON64KB	; ES:EDI ==> destin
	 movzx	 ecx,PRGSIZE	; Get size of our program in 1KB
	 shl	 ecx,10-0	; Convert from 1KB to bytes
	 sub	 ecx,LOADBYTE	; Don't move API programs
	 add	 ecx,edi	; Add to get ending address

	 cmp	 ecx,0009F000h	; Izit above 9F000h?
	 jbe	 short @F	; Jump if not

	 mov	 ecx,0009F000h	; Use maximum
@@:
	 sub	 ecx,edi	; Less starting point to get byte length
	 shr	 ecx,2-0	; Convert from bytes to dwords
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Move to low memory

; Ensure CS has 64KB segment length and is located in real memory

	 mov	 eax,CON64KB	; Get our new program base address
	 push	 CON64KB	; Pass segment length
	 push	 CPL0_CODE or CPL0 ; Pass access rights byte
	 push	 DTE_BIOS	; Pass descriptor to set
	 FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the GDT to EAX base

; Set a data selector to same location with 64KB length
; Arbitrarily, we choose DTE_D64K

;;;;;;;; mov	 eax,CON64KB	; Get our new program base address
	 push	 CON64KB	; Pass segment length
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_D64K	; Pass descriptor to set
	 FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the GDT to EAX base

	 FIJMP	 PGROUP:@F,DTE_BIOS ; Load new CS
@@:

; Ensure other selectors have 64KB segment length

	 mov	 ax,DTE_D64K	; Get data selector with 64KB limit
	 mov	 ds,ax
	 mov	 es,ax
	 mov	 fs,ax
	 mov	 gs,ax
	 mov	 ss,ax
	 movzx	 esp,cs:PLOWSTKZ ; Setup dummy stack

	 mov	 al,@S2C_SHUT	; Command for system shutdown
	 mov	 dx,@8042_ST	; I/O port for ...

	 call	 SHADOW_DISABLE ; Set shadow RAM on CHIPSets to original values

	 REGSAVE <eax>		; Save

	 test	 CPUFET_FLAG,@CPUFET_VME ; Are Virtual Mode Extensions enabled?
	 jz	 short @F	; Jump if not

	 MOVSPR  eax,cr4	; Get CPU extensions register
	 and	 eax,not (mask $VME) ; Disable Virtual Mode Extensions
	 MOVSPR  cr4,eax	; Set CPU extensions register
@@:
; Some P54C systems don't reset TR12.  We used to turn on the AutoHalt
; disable bit in TR12 as an errata workaround, and this caused problems.
	 REGREST <eax>		; Restore

	 mov	 ebx,cr0	; Get current control register

	 cmp	 CPUTYPE,04h	; Izit a 486 or later?
	 jb	 short @F	; Jump if not

	 or	 ebx,(mask $CD) or (mask $NW) ; Disable cache

	 WBPAT	 CACHE_INVD,PGROUP ; Invalidate and flush cache by hand

	 mov	 cr0,ebx	; Tell the CPU about it

; Note, we flush the cache BEFORE since the DELL 450/ME does not
; seem to like waiting until after, and we are using the rather
; lengthy (vs a straight WBINVD) overwhelm the cache technique
; so that Gateway PCI bus computers work. DEBUG=WBINVD tells
; us that it is OK to use the WBINVD instruction.
; We've copied our code, including INVD_CACHE, into low memory.
; Note also that if we don't invalidate by hand we could be a
; victim of stale or unwritten cache data in the write-back context.

@@:
	 and	 ebx,not ((mask $PG) or (mask $PE)) ; Disable paging and PM

; If DEBUG=TRIP is specified, use triple fault to reboot.

	 test	 DB3_FLAG,@DB3_TRIP ; Are we using the triple fault?
	 jnz	 short REBT_TRIP ; Jump if so

; If DEBUG=8042 is specified, use OUT DX,AL to reboot.
; By default we'll jump to the REBOOT location, since triple fault and 8042
; locks on some systems.

	 test	 DB3_FLAG,@DB3_8042 ; Are we using the 8042?
	 jnz	 short REBT_8042 ; Jump if so

	 LIDTD	 IDT_REAL	; Set IDT to normal for RM

; On some machines, it appears to be important that the OUT
; instruction following the MOV into CR0 which disables paging and
; protect enable be in the prefetch queue so the CPU doesn't
; generate another bus event.  If we flush the PIQ now, the CPU
; fills the PIQ entirely before executing the first instruction.

	 DDALIGN @QMAX_EM2_ECODE,4-2 ; Align so that MOV CR0,EBX
				; is on a dword boundary
	 jmp	 short $+2	; Flush the prefetch instruction queue

	 mov	 cr0,ebx	; Tell the CPU about it

	xor	ecx,ecx 	; A handy zero for CR3
	mov	cr3,ecx 	; No more paging

	jmp	REBOOT		; Jump to the reboot location

REBT_8042:

; On some machines, it appears to be important that the OUT
; instruction following the MOV into CR0 which disables paging and
; protect enable be in the prefetch queue so the CPU doesn't
; generate another bus event.  If we flush the PIQ now, the CPU
; fills the PIQ entirely before executing the first instruction.

	 DDALIGN @QMAX_EM2_ECODE,4-2 ; Align so that MOV CR0,EBX
				; is on a dword boundary
	 jmp	 short $+2	; Flush the prefetch instruction queue

	 mov	 cr0,ebx	; Tell the CPU about it

	xor	ecx,ecx 	; A handy zero for CR3
	mov	cr3,ecx 	; No more paging

	 out	 dx,al		; Initiate system shutdown
	 hlt
;;;;;;;  jmp	 short $	; We're not going anywhere

REBT_TRIP:
	 LIDTD	 IDT_REBOOT	; Set IDT limit to zero

; On some machines, it appears to be important that the OUT
; instruction following the MOV into CR0 which disables paging and
; protect enable be in the prefetch queue so the CPU doesn't
; generate another bus event.  If we flush the PIQ now, the CPU
; fills the PIQ entirely before executing the first instruction.

	 DDALIGN @QMAX_EM2_ECODE,4-2 ; Align so that MOV CR0,EBX
				; is on a dword boundary
	 jmp	 short $+2	; Flush the prefetch instruction queue

	 mov	 cr0,ebx	; Tell the CPU about it

	xor	ecx,ecx 	; A handy zero for CR3
	mov	cr3,ecx 	; No more paging

COMMENT|

To reboot the system, we set the IDT limit to zero and then issue an
interrupt (any interrupt).  This causes a GP Fault because the
interrupt # is beyond the IDT limit.  This then causes a Double Fault
because the GP Fault interrupt # is beyond the IDT limit.  This then
causes a Triple Fault (system reset) because the Double Fault
interrupt # is beyond the IDT limit.  This way, we don't have to
depend upon peripherals such the 8042 which might or might not work
correctly.

|

	 int	 03h		; Issue an interrupt

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM2_REBOOT endp		; End EMM2_REBOOT procedure
if @OEM_WIN3
	 FPPROC  UTL_VXD2MAX -- VxD to MAX Utility Call Routine
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

VxD to MAX utility call routine

SS is WIN386's FLAT model selector and isn't PGROUP.
No procedures in the call tree from this point may assume SS:PGROUP.

On entry:

SS:EBP	 ==>	 client register structure
IF	 =	 1 (Interrupts are enabled upon entry)

On exit:

SS:EBP	 ==>	 (modified as appropriate to utility call)

|

	 REGSAVE <SEL_DATA,SEL_DS3,SEL_4GB,SEL_4GB3,SEL_PDT,SEL_DSHI,SEL_DSIG3,SEL_DSJG3,es> ; Save data and regs
	 REGSAVE <SEL_PnPCS,SEL_PnPDS,SEL_PnPARG0,SEL_PnPARG1,SEL_PnPARG2,LaGDTPnPARG>
	 pushad 		; Save all EGP registers

	 mov	 SEL_DATA,ds	; Save as new data selector
	 mov	 SEL_DS3,ds	; ...
	 mov	 SEL_4GB,gs	; ...	      all memory selector
	 mov	 SEL_4GB3,gs	; ...	      all memory selector
	 mov	 SEL_PDT,0	; For debugging
	 mov	 SEL_DSHI,0	; ...

	 push	 WIN3_REF_DATA.REF_DSIGR ; Save as new IGROUP data selector
	 pop	 SEL_DSIG3	; ...

	 push	 WIN3_REF_DATA.REF_DSJGR ; Save as new JGROUP data selector
	 pop	 SEL_DSJG3	; ...

	mov	ax,WIN3_REF_DATA.REF_PnPCS ; Get as new PnP code selector
	mov	SEL_PnPCS,ax	; Save for later use

	mov	ax,WIN3_REF_DATA.REF_PnPDS ; Get as new PnP data selector
	mov	SEL_PnPDS,ax	; Save for later use

	mov	ax,WIN3_REF_DATA.REF_PnPARG0 ; Get as new PnP argument data selector #0
	mov	SEL_PnPARG0,ax	; Save for later use

	mov	ax,WIN3_REF_DATA.REF_PnPARG1 ; Get as new PnP argument data selector #1
	mov	SEL_PnPARG1,ax	; Save for later use

	mov	ax,WIN3_REF_DATA.REF_PnPARG2 ; Get as new PnP argument data selector #2
	mov	SEL_PnPARG2,ax	; Save for later use

	SGDTD	GDTR_PnP	; Save GDTR
	movzx	eax,SEL_PnPARG0 ; Get PnP argument data selector #0
	add	LaGDTPnPARG,eax ; Add to get offset to PnP argument data selectors

; Calculate the linear address of the SS3:PL3 for later use

	movzx	eax,[ebp].INTXX_SS ; Get client's SS
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	ebx,[ebp].INTXX_ESP.ELO ; Get client's SP
	add	eax,ebx 	; Add to get linear address
	add	eax,2		; Skip over @VXDAPI_UTIL
	mov	LaPL3STK,eax	; Save for later use

	 mov	 es,SEL_DSIG3	; Establish addressibility to IGROUP
	 assume  es:IGROUP	; Tell the assembler

	 REGSAVE <ISEL_DS3,ISEL_DSIG3,ISEL_4GB3> ; Save IGROUP copies

	 mov	 ISEL_DS3,ds	; Save as new data selector (in IGROUP)
	 mov	 ISEL_DSIG3,es	; ...		   selector (in IGROUP)
	 mov	 ISEL_4GB3,gs	; ...	      all memory selector (in IGROUP)

	 mov	 es,SEL_DSJG3	; Establish addressibility to JGROUP
	 assume  es:JGROUP	; Tell the assembler

	 REGSAVE <JSEL_DS3>	; Save JGROUP copy

	 mov	 JSEL_DS3,ds	; Save as new data selector (in JGROUP)

	 inc	 VXD_LEVEL	; Increment the level #

	 mov	 eax,[ebp].INTXX_EAX ; Setup caller's EGP registers
	 mov	 ebx,[ebp].INTXX_EBX ; ...
	 mov	 ecx,[ebp].INTXX_ECX ; ...
	 mov	 edx,[ebp].INTXX_EDX ; ...

	 cmp	 ah,@EMM2_GETMCS ; Izit Get Memory Chain Structure?
	 je	 near ptr EMM2_GETMCS ; Jump if so

	 cmp	 ah,@EMM2_GETMAP ; Izit Get Memory Map Structure?
	 je	 near ptr EMM2_GETMAP ; Jump if so

	 cmp	 ah,@EMM2_GETINFO ; Izit Get Information Structure?
	 je	 near ptr EMM2_GETINFO ; Jump if so

	 cmp	 ah,@EMM2_GETPPM ; Izit Get PPMTAB Structure?
	 je	 near ptr EMM2_GETPPM ; Jump if so

	 cmp	 ah,@EMM2_POSCOPY ; Izit Get POS Structure?
	 je	 near ptr EMM2_POSCOPY ; Jump if so

	 cmp	 ah,@EMM2_GETTEXT ; Izit Get Message Text?
	 je	 near ptr EMM2_GETTEXT ; Jump if so

if @OEM_HARPO
	 cmp	 ah,@EMM2_HARPOINFO ; Izit HARPO subfunctions?
	 je	 near ptr EMM2_HARPOINFO ; Jump if so
endif				; IF @OEM_HARPO

	 cmp	 ah,@EMM2_GSLINK58 ; Izit Get/Set 5802 link state?
	 je	 near ptr EMM2_GSLINK58 ; Jump if so

	 cmp	 ah,@EMM2_DLGROUP ; Izit DLGROUP support?
	 je	 near ptr EMM2_DLGROUP ; Jump if so

	cmp	ah,@EMM2_PnP	; Izit PnP support?
	jne	short UTL_VXD2MAX_XPnP ; Jump if not

	mov	gs,SEL_4GB	; Get all memory selector
	assume	gs:AGROUP	; Tell the assembler

; Enable interrupts if they're on in the caller

	test	[ebp].INTXX_EFL.ELO,mask $IF ; Izit enabled?
	jz	short @F	; Jump if not

	sti			; Enable interrupts
@@:
	mov	ebx,LaPL3STK	; Get linear address of PL3 stack

	jmp	EMM2_PnP1	; Join common code

UTL_VXD2MAX_XPnP:
	 assume  es:nothing	; Tell the assembler
UTL_VXDOUT_ERR:
	 mov	 gs,SEL_4GB3	; Old stack selector
	 assume  gs:AGROUP	; Tell the assembler

	 mov	 al,AGROUP:[ebp].INTXX_EAX.ELO.LO ; Get original AL
	 mov	 ah,80h 	; Return error code (software error)

	 jmp	 short UTL_VXDOUT ; Join common code

	 assume  es:nothing	; Tell the assembler
UTL_VXDOUT00AL:
	 mov	 gs,SEL_4GB3	; Old stack selector
	 assume  gs:AGROUP	; Tell the assembler

	 movzx	 ax,AGROUP:[ebp].INTXX_EAX.ELO.LO ; Get original AL, zero AH

UTL_VXDOUT:
	 dec	 VXD_LEVEL	; Decrement the level #

	 mov	 AGROUP:[ebp].INTXX_EAX.ELO,ax ; Save return code

	 mov	 es,SEL_DSJG3	; Establish addressibility to JGROUP
	 assume  es:JGROUP	; Tell the assembler

	 REGREST <JSEL_DS3>	; Restore JGROUP copy

	 mov	 es,SEL_DSIG3	; Establish addressibility to IGROUP
	 assume  es:IGROUP	; Tell the assembler

	 REGREST <ISEL_4GB3,ISEL_DSIG3,ISEL_DS3> ; Restore IGROUP copies

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]
	 REGREST <LaGDTPnPARG,SEL_PnPARG2,SEL_PnPARG1,SEL_PnPARG0,SEL_PnPDS,SEL_PnPCS> ; Restore
	 REGREST <es,SEL_DSJG3,SEL_DSIG3,SEL_DSHI,SEL_PDT,SEL_4GB3,SEL_4GB,SEL_DS3,SEL_DATA> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 RETFD			; Return to caller (32-bit)

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UTL_VXD2MAX endp		; End UTL_VXD2MAX procedure
endif				; IF @OEM_WIN3
	 FPPROC  FSET_XMSBND -- Set XMSBND entries
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set XMSBMAP entries marking where they span physically discontiguous memory

|

	 call	 SET_XMSBND	; Set XMSBMAP boundary entries

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FSET_XMSBND endp		; End FSET_XMSBND procedure
if @OEM_EMS
	 FPPROC  FPGMAP_ALL -- Map All RPNCUR Entries Into PTEs
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Translate the RPNCUR entries into PTEs and put them into EMS physical pages.

|

	 call	 PGMAP_ALL	; Mapp all RPNCUR entries into PTEs

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FPGMAP_ALL endp 		; End FPGMAP_ALL procedure
endif				; IF @OEM_EMS
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
	 assume  cs:IGROUP	; Tell the assembler

	 public  @QMAX_EM2_LCODE
@QMAX_EM2_LCODE:		; Mark module start in .MAP file

	 FPPROC  GETSELBASE -- Get Selector Base Address
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get selector base address

On entry:

Stack has selector

On exit:

EAX	 =	 base address of selector

|

GSB_STR  struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   CS:IP
GSB_SEL  dw	 ?		; Selector

GSB_STR  ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,ds>	; Save registers

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 movzx	 ebx,[ebp].GSB_SEL ; Get the selector
	 and	 bl,not (mask $PL) ; Clear PL bits

	 btr	 bx,$TI 	; Izit in the LDT?
	 jnc	 short GETSELBASE_GDT ; Jump if not

	 sldt	 ax		; Get LDT selector

	 push	 ax		; Pass selector as argument
	 FCALL	 GETSELBASE	; Return with EAX = base address of selector

	 add	 ebx,eax	; Add to get AGROUP address of selector

	 jmp	 short GETSELBASE_COM ; Join common code

GETSELBASE_GDT:
	 sub	 esp,size DESC_STR ; Make room for GDTR
	 SGDTD	 [esp].EDF	; Store GDTR on stack
	 add	 ebx,[esp].DTR_BASE ; Plus the GDT base to AGROUP addr of selector
	 add	 esp,size DESC_STR ; Strip from stack
GETSELBASE_COM:
	 mov	 eax,AGROUP:[ebx].DESC_BASE01.EDD ; Get bytes 0-2
	 shl	 eax,8		; Make room for byte 3
	 mov	 al,AGROUP:[ebx].DESC_BASE3 ; Get byte 3
	 ror	 eax,8		; Rotate back to normal order

	 REGREST <ds,ebx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETSELBASE endp 		; End GETSELBASE procedure
	 align	 4		; Ensure dword alignment

LCODE	 ends			; End LCODE segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP, ds:JGROUP ; Tell the assembler

	 extrn	 MAC_ALLOC:far
	 extrn	 DO_RINFO:near
	 extrn	 FREE_RINFO:near
	 extrn	 CALC_EXEHDR:near

	 public  @QMAX_EM2_JCODE
@QMAX_EM2_JCODE:		; Mark module start in .MAP file

if @OEM_SOFT
	 public  CURSOR_FNS
CURSOR_FNS label word
	 dw	 JGROUP:JMM2_CURSOR0
	 dw	 JGROUP:JMM2_CURSOR1
CURSOR_CNT equ	 ($-CURSOR_FNS)/2
endif				; IF @OEM_SOFT

if @OEM_HARPO
	 public  HARPO_FNS
HARPO_FNS label word
	 dw	 JGROUP:JMM2_HARP0	; Pass misc. info to MAX
	 dw	 JGROUP:JMM2_HARP1	; Pass next subseg record to 386MAX
	 dw	 JGROUP:JMM2_HARP2	; Get all subseg records
	 dw	 JGROUP:JMM2_HARP3	; Set HARPO profile filespec
	 dw	 JGROUP:JMM2_HARP4	; Get HARPO profile filespec
@HARPO_CNT equ	 ($-HARPO_FNS)/2
endif				; IF @OEM_HARPO

	 public  JMM_E8F
JMM_E8F:
	 FIXIJMP PGROUP:EMM_E8F,DTE_CS2

	 NPPROC  JMM2_GETMCS -- EMM2 Return Memory Chain Structure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 1, AH = 01h

Return Memory Chain Structure

ES:DI ==> Memory Chain Structure in caller's data space

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

; Get 20-bit linear address offset of caller's ES:DI into AGROUP:EDI

	 FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 lea	 esi,MCSTAB	; DS:ESI ==> highmem MCSTAB

	 mov	 bx,MCSTAB_CNT	; Get count of # entries
	 mov	 [ebp].INTXX_ECX.ELO,bx ; Pass back to caller in CX

	 mov	 ax,type MCS_STR ; Get size of structure
	 mul	 bx		; Times # entries in MCSTAB
	 movzx	 ecx,ax 	; Copy to count register
S32  rep movs	 <AGROUP:[edi].LO,PGROUP:[esi].LO> ; Save in low memory

	 public  JMM_E00AL
JMM_E00AL:
if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 jz	 short @F	; Skip if not

	 FIXIJMP PGROUP:UTL_VXDOUT00AL,DTE_CS2 ; Join common OK code
@@:
endif				; IF @OEM_WIN3
	 FIXIJMP PGROUP:EMM_E00AL,DTE_CS2 ; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GETMCS endp		; End JMM2_GETMCS procedure
	 NPPROC  JMM2_GETMAP -- EMM2 Get Memory Map Structure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 2, AH = 02h

Return Memory Map Structure

ES:DI ==> Memory Map Structure in caller's data space

Return the # entries in CX

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

; Get 20-bit linear address offset of caller's ES:DI into AGROUP:EDI

	 FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 lea	 esi,MAPTAB	; DS:ESI ==> highmem MAPTAB

	 mov	 bx,MAPTAB_CNT	; Get count of # entries
	 mov	 [ebp].INTXX_ECX.ELO,bx ; Pass back to caller in CX

	 mov	 ax,type MAP_STR ; Get size of structure
	 mul	 bx		; Times # entries in MAPTAB
	 movzx	 ecx,ax 	; Copy to count register
S32  rep movs	 <AGROUP:[edi].LO,PGROUP:[esi].LO> ; Save in low memory

	 jmp	 short JMM_E00AL ; Rejoin common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GETMAP endp		; End JMM2_GETMAP procedure
	 NPPROC  JMM2_GETINFO -- EMM2 Return INFO Structure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 3, AH = 03h

Return INFO structure

ES:DI ==> INFO structure in caller's data space

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

; Get 20-bit linear address offset of caller's ES:DI into AGROUP:EDI

	 FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 lea	 esi,INFO	; DS:ESI ==> highmem INFO structure

	 mov	 ecx,INFOSIZE	; ECX = # bytes in INFO structure
S32  rep movs	 <AGROUP:[edi].LO,PGROUP:[esi].LO> ; Save in low memory

	 jmp	 short JMM_E00AL ; Rejoin common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GETINFO endp		; End JMM2_GETINFO procedure
	 NPPROC  JMM2_GETPPM -- EMM2 Return PPMTAB Structure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 4, AH = 04h

Return PPMTAB structure

ES:DI ==> PPMTAB structure in caller's data space

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

; Get 20-bit linear address offset of caller's ES:DI into AGROUP:EDI

	 FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 lea	 esi,PPMTAB	; DS:ESI ==> PPMTAB structure

	 mov	 ecx,PPMTAB_LEN ; ECX = # bytes in PPMTAB structure
	 mov	 [ebp].INTXX_ECX.ELO,cx ; Return in CX
S32  rep movs	 <AGROUP:[edi].LO,PGROUP:[esi].LO> ; Save in low memory

	 jmp	 short JMM_E00AL ; Rejoin common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GETPPM endp		; End JMM2_GETPPM procedure
if @OEM_TIMEMEM
	 NPPROC  JMM2_MEMTIME -- EMM2 Time Memory Accesses
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 6, AH = 06h

Time memory access throughout the system

Return in CX the # 4KB pages in the system (possibly duplicated)
Store into ES:DI the following structure:
       DD      ?	      ; 32-bit physical address of the 4KB page
       DW      ?	      ; The memory access time of this 4KB page
repeated as many times as there are 4KB pages in the system

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 FIXICALL PGROUP:FWRAP_DISABLE,DTE_CS2 ; Disable the 1MB wrap

	 FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	 assume  es:AGROUP	; Tell the assembler about it

; Flush any memory cache that might be out there.
; To do this we read 256 KB of data (which should be four times
; larger than any existing cache buffer) starting at 256KB.

	 mov	 esi,CON256KB	; Initialize offset in 256KB
	 mov	 ecx,CON64KB	; ECX = # dwords to read

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

     rep lods	 AGROUP:[esi].EDD ; Read it all in to flush the cache

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 xor	 eax,eax	; Address 00000000h
	 mov	 ebx,eax	; Save as base accumulator

	 push	 CON4KB 	; Get size of a page
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_BIOS	; Pass descriptor to set
	 FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the GDT to EAX base

	 mov	 ecx,TOTSIZE	; Get # 1KB blocks of extended memory
	 shr	 ecx,12-10	; Convert from 1KB to 4KB
	 add	 ecx,1024/4	; Get # 4KB blocks of first MB memory
	 mov	 [ebp].INTXX_ECX,ecx ; Return in caller's ECX

	 xor	 esi,esi	; FS:ESI = offset in page descriptor tables
				; ES:EDI ==> output save area
				; EBX = base address accumulator
				; CX = # PTEs
MEMTIME_NEXT:

; Check for not physical memory

	 mov	 ax,@TIM_ABS	; Assume not physical memory

	 test	 OFFPDT.ELO[esi],mask $PTE_AV1 ; Izit marked as not physical memory?
	 jnz	 short MEMTIME_NEXT1 ; Yes, skip timing

; Check for in EMS frame (hence not physical memory)

	 cmp	 esi,PPDTFRM	; Below PDT offset of start of frame?
	 jb	 short MEMTIME1 ; Yes, hence it's real

	 cmp	 esi,PPDTFRMZ	; Above PDT offset of end of frame?
	 jb	 short MEMTIME_NEXT1 ; No, so it's in the frame -- mark it as absent
MEMTIME1:
	 cli			; Disallow interrupts

	 mov	 dx,OFFPDT.ELO[esi] ; Get the page table entry

; In case the PTE is for swapped ROM (which is marked as not present),
; we must mark it present for the moment

	 or	 OFFPDT.ELO[esi],mask $PTE_P ; Ensure it's present

; Because we just changed the page table, we must flush the TLB

	 FIXICALL PGROUP:FFLUSH_TLB,DTE_CS2 ; Flush the TLB

	 and	 GLB_FLAG,not @GLB_NMI ; Assume no parity errors

	 push	 DTE_BIOS	; Pass segment to time
	 FIXICALL PGROUP:TIME_MEM,DTE_CS2 ; Return with AX = timer value

	 mov	 OFFPDT.ELO[esi],dx ; Restore

	 sti			; Allow interrupts

	 test	 GLB_FLAG,@GLB_NMI ; Any parity errors?
	 jz	 short MEMTIME_NEXT1 ; Not this time

	 mov	 ax,@TIM_PAR	; Return parity error code
	 and	 GLB_FLAG,not @GLB_NMI ; Clear parity error
	 FIXICALL PGROUP:FENABLE_NMI,DTE_CS2 ; Enable NMI, clear parity latches
MEMTIME_NEXT1:
S32	 movs	 <AGROUP:[edi].EDD,OFFPDT[esi]> ; Copy PTE to user's buffer
S32	 stos	 AGROUP:[edi].ELO   ; Save timing value

	 add	 ebx,CON4KB	; Skip to next 4KB block

; Save back into GDT

	 mov	 DESC_TAB.DTE_BIOS.DESC_BASE01,bx ; Save bytes 0-1
	 ror	 ebx,16 	; Shift down high-order word
	 mov	 DESC_TAB.DTE_BIOS.DESC_BASE2,bl ; Save byte 2
	 mov	 DESC_TAB.DTE_BIOS.DESC_BASE3,bh ; Save byte 3
	 rol	 ebx,16 	; Shift back

;;;;;;	 loop	 MEMTIME_NEXT	; Jump if more 4KB pages to time
	 dec	 cx		; Account for page just timed
	 jnz	 near ptr MEMTIME_NEXT ; Jump if more 4KB pages to time

; Note that @GLB_XWRP is cleared and WRAP_ENABLE is called at EMM_EXIT

	 jmp	 near ptr JMM_E00AL ; Rejoin common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_MEMTIME endp		; End JMM2_MEMTIME procedure
endif				; IF @OEM_TIMEMEM
	 NPPROC  JMM2_GOREAL -- Exit Protected Mode
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 8, AH = 08h

Exit from protected mode

If AL = 0, exit unconditionally.
If AL = 1, exit if EMS memory not in use.

Error return A4 if EMS or XMS memory in use

All registers except EBP, SS, and ESP may be destroyed.

|

if @OEM_EMS
	 cmp	 [ebp].INTXX_EAX.ELO.LO,0 ; Check function code
	 je	 short JMM2_GOREAL_GO ; Exit unconditionally

; See if there are any EMS handles in use

	 cmp	 EHNDLCNT,1	; Check the EMS handle count
	 jne	 short JMM2_GOREAL_ERR ; Jump if some are still active

; See if there are any XMS handles in use

if @OEM_XMS
	 cmp	 XHNDLCNT,1	; Check the XMS handle count
	 jne	 short JMM2_GOREAL_ERR ; Jump if some are still active
endif				; IF @OEM_XMS

; See if the HMA is in use

	 test	 GLB_FLAG,@GLB_HMA ; Izit in use?
	 jnz	 short JMM2_GOREAL_ERR ; Jump if so
JMM2_GOREAL_GO:
	 mov	 [ebp].INTXX_EAX.ELO.HI,0 ; Mark as successful

	 FIXIJMP PGROUP:EMM_EXIT_GOREAL,DTE_CS2 ; Join common exit code

JMM2_GOREAL_ERR:
	 FIXIJMP PGROUP:EMM_EA4,DTE_CS2 ; Exit with error
else
	 mov	 [ebp].INTXX_EAX.ELO.HI,0 ; Mark as successful

	 FIXIJMP PGROUP:EMM_EXIT_GOREAL,DTE_CS2 ; Join common exit code
endif				; IF @OEM_EMS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GOREAL endp		; End JMM2_GOREAL procedure
	 NPPROC  JMM2_HIMEM -- EMM2 New HIMEM_CS
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 13, AH = 0Dh

Set new HIMEM_CS segment from BX
Set new HPDA segment from CX.  OVR_HPDA is static and is discarded
after we use it to dynamically create the actual HPDA.

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 cli			; Disallow interrupts

; Set HIMEM_CS and related values

	 movzx	 eax,[ebp].INTXX_EBX.ELO ; Get new HIMEM_CS
	 FIXICALL PGROUP:SET_EXTMEM_CS,DTE_CS2 ; Set new value in extended mem

	 push	 eax		; Save for a moment

; Save in 1st TSS.  Note that the HPDA segment will only be in its
; static location if NOLOADHI is in effect.

	 mov	 ebx,PVMTSS	; Get offset in PGROUP of 1st TSS
	 movzx	 ecx,[ebp].INTXX_ECX.ELO ; Get new HPDA segment

	 mov	 PGROUP:[ebx].DPTSS_HPDASEG,cx ; Save for later use
	 mov	 PGROUP:[ebx].DPTSS_VMSTKSEG,cx ; ...
	 shl	 ecx,4-0	; Convert from paras to bytes
	 mov	 PGROUP:[ebx].DPTSS_LaHPDA,ecx ; Save for later use

; Set DTE_DSHI selector

	 shl	 eax,4-0	; Convert from paras to bytes

	 lea	 ebx,DESC_TAB.DTE_DSHI ; DS:EBX ==> selector to change
	 FIXICALL PGROUP:SETBASE,DTE_CS2 ; Set selector's base of DS:EBX to EAX

	 lea	 ebx,DESC_TAB.DTE_CS ; DS:EBX ==> selector to change
	 FIXICALL PGROUP:SETBASE,DTE_CS2 ; Set selector's base of DS:EBX to EAX

	 lea	 ebx,DESC_TAB.DTE_SS ; DS:EBX ==> selector to change
	 FIXICALL PGROUP:SETBASE,DTE_CS2 ; Set selector's base of DS:EBX to EAX

;;;;;;;; add	 eax,offset ds:DESC_TAB ; Get new base of GDT
;;;;;;;; mov	 PGDT_LLO.DTR_BASE,eax ; Save for later use
;;;;;;;;
	 pop	 eax		; Restore

; Save HIMEM_CS in LO_ and HI_PGET_WINVXD_VEC

	push	ds		; Save for a moment

	mov	ds,SEL_DSHI	; Get
	assume	ds:PGROUP	; Tell the assembler about it

	mov	HI_PGET_WINVXD_VEC.VSEG,ax ; Save it

	push	DTE_DSLO	; Get data selector for low DOS memory
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	mov	LO_PGET_WINVXD_VEC.VSEG,ax ; Save it

	pop	ds		; Restore
	assume	ds:PGROUP	; Tell the assembler about it

	 cmp	 ax,POVR_MAC	; Izit in high DOS, or are we just setting
				; the HPDA segment?
	 jb	 short @F	; Jump if low

	 or	 LCL_FLAG,@LCL_LODHI ; Mark as LOADHI in effect
@@:
; Set REBOOT location segment

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:CGROUP	; Tell the assembler about it

	 xor	 ebx,ebx	; Zero entire register
	 mov	 bx,seg CGROUP	; Get segment of system ROM
	 shl	 ebx,4-0	; Convert from paras to bytes

	 sub	 CHKSUM[ebx],al ; Subtract new value from checksum
	 sub	 CHKSUM[ebx],ah ; ...
	 xchg	 ax,REBOOT_VEC[ebx].VSEG ; Set REBOOT location segment
	 add	 CHKSUM[ebx],al ; Add old value into checksum
	 add	 CHKSUM[ebx],ah ; ...

	 jmp	 near ptr JMM_E00AL ; Rejoin common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_HIMEM endp 		; End JMM2_HIMEM procedure
if @OEM_SOFT
	 NPPROC  JMM2_CURSOR -- EMM2 Virtual Cursor
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 14, AH = 0Eh

Enable/disable virtual cursor.

On entry:

AL	 =	 0 to disable virtual cursor
	 =	 1 to enable ...

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,CURSOR_CNT ; Check for valid subfunction range
	 jnb	 near ptr JMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 CURSOR_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_CURSOR endp		; End JMM2_CURSOR procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 NPPROC  JMM2_CURSOR0 -- Disable Virtual Cursor
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

EMM2 Function 14, AX = 0E00h

Disable virtual cursor.

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 esi,03B4h	; I/O port address to clear
	 FCALL	 CLR_BITMAP	; Clear the bit

	 inc	 si		; I/O port address to clear
	 FCALL	 CLR_BITMAP	; Clear the bit

	 mov	 esi,03D4h	; I/O port address to clear
	 FCALL	 CLR_BITMAP	; Clear the bit

	 inc	 si		; I/O port address to clear
	 FCALL	 CLR_BITMAP	; Clear the bit

	 jmp	 near ptr JMM_E00AL ; Rejoin common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_CURSOR0 endp		; End JMM2_CURSOR0 procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 NPPROC  JMM2_CURSOR1 -- Enable Virtual Cursor
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

EMM2 Function 14, AX = 0E01h

Enable virtual cursor.

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 esi,03B4h	; I/O port address to set
	 FCALL	 SET_BITMAP	; Set the bit

	 mov	 esi,03D4h	; I/O port address to set
	 FCALL	 SET_BITMAP	; Set the bit

	 jmp	 near ptr JMM_E00AL ; Rejoin common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_CURSOR1 endp		; End JMM2_CURSOR1 procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 FPPROC  CLR_BITMAP -- Clear Bit in I/O Bit Permission Map
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Clear a bit in the I/O bit permission map.

On entry:

ESI	 =	 bit to clear

|

	 REGSAVE <ebx,cx,si>	; Save registers

	 mov	 ebx,PIOBIT	; Get offset in PGROUP of I/O bit map
	 mov	 cx,REP_FAC	; Repeat factor for loop
@@:
	 btr	 PGROUP:[ebx],esi ; Clear the bit

	 add	 si,@IO_LIM	; Skip to next I/O port address

	 loop	 @B		; Jump if more to do

	 REGREST <si,cx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLR_BITMAP endp 		; End CLR_BITMAP procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 FPPROC  SET_BITMAP -- Setr Bit in I/O Bit Permission Map
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Set a bit in the I/O bit permission map.

On entry:

ESI	 =	 bit to set

|

	 REGSAVE <ebx,cx,si>	; Save registers

	 mov	 ebx,PIOBIT	; Get offset in PGROUP of I/O bit map
	 mov	 cx,REP_FAC	; Repeat factor for loop
@@:
	 bts	 PGROUP:[ebx],esi ; Set the bit

	 add	 si,@IO_LIM	; Skip to next I/O port address

	 loop	 @B		; Jump if more to do

	 REGREST <si,cx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_BITMAP endp 		; End SET_BITMAP procedure
endif				; IF @OEM_SOFT
	 NPPROC  JMM2_POSCOPY -- EMM2 Copy POS Data
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 20, AH = 14h

Copy POS Data into caller's ES:DI.

Error return A4 if ABIOS not supported on this system.

All registers except EBP, SS, and ESP may be destroyed.

|

	 test	 SYS_FLAG,@SYS_MCAXABIOS ; Izit an MCA system w/o ABIOS?
	 jnz	 short JMM2_POSERR ; Jump if so (join error code)

	 FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ecx,@MAXPOSDEV*(size POSD_STR)/2 ; Get size in words of POSDATA
	 lea	 esi,POSDATA	; DS:ESI ==> saved POS data

S32  rep movs	 <AGROUP:[edi].ELO,PGROUP:[esi].ELO> ; Copy to caller's save area

	 jmp	 near ptr JMM_E00AL ; Rejoin common OK code

JMM2_POSERR:
if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 jz	 short @F	; Skip if not

	 FIXIJMP PGROUP:UTL_VXDOUT_ERR,DTE_CS2 ; Exit with error
@@:
endif				; IF @OEM_WIN3
	 FIXIJMP PGROUP:EMM_EA4,DTE_CS2 ; Exit with error
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_POSCOPY endp		; End JMM2_POSCOPY procedure
	 NPPROC  JMM2_GETTEXT -- EMM2 Return Message Text
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 22, AH = 16h

Return message text

ES:DI	 ==>	 message text area in caller's data space
SS:EBP	 ==>	 INTXX_STR

No errors possible

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

; Get 20-bit linear address offset of caller's ES:DI into AGROUP:EDI

	 FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 lea	 esi,MSG_STAT	; DS:ESI ==> highmem message text
	 mov	 ecx,MSG_STATLEN ; ECX = byte length of message text

	 cmp	 cx,[ebp].INTXX_ECX.ELO ; Use the smaller of the two
	 jbe	 short @F	; Actual length is smaller

	 mov	 cx,[ebp].INTXX_ECX.ELO ; Specified length is smaller
@@:
S32  rep movs	 <AGROUP:[edi].LO,PGROUP:[esi].LO> ; Save in low memory

	 jmp	 near ptr JMM_E00AL ; Rejoin common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GETTEXT endp		; End JMM2_GETTEXT procedure
if @OEM_HARPO
	 NPPROC  JMM2_HARPOINFO -- EMM2 Set Globals Containing HARPO Information
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 35, AH = 23h

Communication interface between HARPO, 386MAX, and MAXIMIZE

On entry:
AL	=	Subfunction number (0-4)
		0 => Pass misc. info to 386MAX
		1 => Pass next subseg record to 386MAX
		2 => Get all subseg records
		3 => Set HARPO profile filespec
		4 => Get HARPO profile filespec


On exit:

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Get sub-function number

	 cmp	 al,@HARPO_CNT ; Check for valid subfunction range
	 jnb	 near ptr JMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 HARPO_FNS[ebx*2] ; Take appropriate action

JMM2_HARPO_COMN:
	 assume  es:nothing	; Tell the assembler

	 jmp	 near ptr JMM_E00AL ; Rejoin common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_HARPOINFO endp		; End JMM2_HARPOINFO procedure
	 NPPROC  JMM2_HARP0 -- EMM2_HARP0 procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Pass misc. info to MAX (for Windows)

On entry:
BL	=	size of FILES= structure element

On exit:
All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 al,[ebp].INTXX_EBX.ELO.LO ; Get size of FILES= structure in DOS
	 mov	 FILES_STR_LEN,al	; Save for Windows

	 jmp	 short JMM2_HARPO_COMN	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
JMM2_HARP0	 endp			; End JMM2_HARP0 procedure
	 NPPROC  JMM2_HARP1 -- EMM2_HARP1 procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Pass next subseg record to MAX

On entry:
BL	=	Sub-segment type
CX	=	Para count
BH	=	Region number
DX	=	Flags

On exit:
AH	=	8F if table is full
All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 di,SUBSEG_PTR	; Next address of structure

	 cmp	 di,(offset PGROUP:SUBSEG_INFO +(@SUBSEG_CNT*type(SUBSEG_STR)))
	 jnb	 near ptr JMM_E8F ; It's too big

	 mov	 al,[ebp].INTXX_EBX.ELO.LO ; Get subsegment type
	 mov	 PGROUP:[di].SUBSEG_TYPE,al ; ... and store away

	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get para count
	 mov	 PGROUP:[di].SUBSEG_NPAR,ax ; ... and store away

	 mov	 al,[ebp].INTXX_EBX.ELO.HI ; Get region number
	 mov	 PGROUP:[di].SUBSEG_REG,al ; ... and store away

	 mov	 ax,[ebp].INTXX_EDX.ELO ; Get flags
	 mov	 PGROUP:[di].SUBSEG_FLAG,ax ; ... and store away

	 add	 SUBSEG_PTR,(type SUBSEG_STR) ; Update dynamic pointer

	 jmp	 short JMM2_HARPO_COMN	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
JMM2_HARP1	 endp			; End JMM2_HARP1 procedure
	 NPPROC  JMM2_HARP2 -- EMM2_HARP2 procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Get all sub-seg records

On entry:
CX	=	Number of bytes requested (updated upon exit)
ES:DI	=	Seg:Off of destination buffer

On exit:
All registers except EBP, SS, and ESP may be destroyed.

|

	 movzx	 ecx,[ebp].INTXX_ECX.ELO ; Get byte count

	 cmp	 ecx,(@SUBSEG_CNT*(type SUBSEG_STR)) ; Requested too much?
	 jb	 short @F	; Jump if not

	 mov	 ecx,(@SUBSEG_CNT*(type SUBSEG_STR)) ; Give 'em all we've got
	 mov	 [ebp].INTXX_ECX.ELO,cx ; Return new byte count
@@:

; Address the caller's save area

	 FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 lea	 esi,SUBSEG_INFO ; Start of our buffer

S32  rep movs	 <AGROUP:[edi].LO,SUBSEG_INFO[esi].LO> ; Move the buffer

	 jmp	 short JMM2_HARPO_COMN	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
JMM2_HARP2	 endp			; End JMM2_HARP2 procedure
	 NPPROC  JMM2_HARP3 -- EMM2_HARP3 procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Transfer HARPO profile filespec (HARPO --> MAX)

On entry:
ES:DI	=	Address of file spec (null terminated)

On exit:
All registers except EBP, SS, and ESP may be destroyed.

|

	 FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 esi,edi	; Place in source register
	 lea	 edi,HARPO_FILESPEC ; Address of local buffer

@@:
	 lods	 AGROUP:[esi].LO ; Get next filespec character
	 mov	 PGROUP:[edi].LO,al ; Store in local buffer
	 inc	 edi		; Next char in destination

	 or	 al,al		; Is it the end of the string?
	 jnz	 short @B	; Jump if not

	 jmp	 near ptr JMM2_HARPO_COMN ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
JMM2_HARP3	 endp			; End JMM2_HARP3 procedure
	 NPPROC  JMM2_HARP4 -- EMM2_HARP4 procedure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Transfer HARPO profile filespec (MAX --> MAXIMIZE)

On entry:
ES:DI	=	Address of file spec (null terminated)

On exit:
All registers except EBP, SS, and ESP may be destroyed.

|

	 FIXICALL PGROUP:FPL3ESDI,DTE_CS2 ; Convert PL3 ES:DI to AGROUP:EDI
	 assume  es:AGROUP	; Tell the assembler about it

	 lea	 esi,HARPO_FILESPEC ; Address of local buffer

@@:
	 lods	 HARPO_FILESPEC[esi].LO ; Move one char
S32	 stos	 AGROUP:[edi].LO ; ...

	 or	 al,al		; Is it the end of the string?
	 jnz	 short @B	; Jump if not

	 jmp	 near ptr JMM2_HARPO_COMN ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
JMM2_HARP4	 endp		; End JMM2_HARP4 procedure
endif				; IF @OEM_HARPO
	 NPPROC  JMM2_GSLINK58 -- Get/Set 5802/5803 link state
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 36, AH = 24h

Get/Set 5802/5803 link status.
If AL=0, returns link state in BX (0=closed, 1=linked).
If AL=1, set link state to BX.

Error return A4 if DOS=UMB in effect.

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 gs,SEL_4GB3	; Address AGROUP for OPENHIGH/CLOSEHIGH
	 assume  gs:AGROUP	; Tell the assembler

	 movzx	 ebx,HIMEM_CS	; Address MAX in high DOS
	 shl	 ebx,4-0	; Convert paras to bytes

	 assume  gs:PGROUP	; Tell a white lie
	 test	 gs:I15_FLAG[ebx],@I15_X58 ; Is NO58 in effect?
	 assume  gs:AGROUP	; Retract nose
	 jnz	 short JMM2_GSLERR ; Return error code if so

;;;;;;;  test	 CM2_FLAG,@CM2_DOS5 ; Is DOS=UMB in effect?
;;;;;;;  jnz	 short JMM2_GSLERR ; Return error code if so

	 cmp	 [ebp].INTXX_EAX.LO,1 ; Izit set link state?
	 ja	 short JMM2_GSLERR ; Jump if invalid

	 je	 short JMM2_GSLSET ; Jump if set state

JMM2_GSLGET:
; Return link state in BX: 0 if high DOS closed off, 1 if linked
	 sub	 bx,bx		; Clear high byte
	 test	 I15_FLAG,@I15_LINK58 ; Are they linked?
	 setnz	 bl		; 1 if linked, 0 if not
	 mov	 [ebp].INTXX_EBX.ELO,bx ; Return link state to caller
	 jmp	 short JMM2_GSLEXIT ; Join common exit

JMM2_GSLSET:
; Set link state to BX: 0 to close high DOS, 1 to link it
	 cmp	 [ebp].INTXX_EBX.ELO,1 ; Are we linking?
	 ja	 short JMM2_GSLERR ; Jump if invalid

	 je	 short @F	; Jump if linking

	 btr	 I15_FLAG,$I15_LINK58 ; Was it linked?
	 jnc	 short JMM2_GSLEXIT ; Jump if not (no action required)

	 FIXICALL PGROUP:FCLOSEHIGHDOS,DTE_CS2 ; Close arenas
	 jmp	 short JMM2_GSLEXIT ; Join common exit (ignore error return)

@@:
	 bts	 I15_FLAG,$I15_LINK58 ; Was it linked?
	 jc	 short JMM2_GSLEXIT ; Jump if so (no action required)

	 FIXICALL PGROUP:FOPENHIGHDOS,DTE_CS2 ; Join arenas
;;;;;;;  jc	 ???		; Ignore error return

JMM2_GSLEXIT:
	 jmp	 JMM_E00AL	; Join common OK code

JMM2_GSLERR:
if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 jz	 short @F	; Skip if not

	 FIXIJMP PGROUP:UTL_VXDOUT_ERR,DTE_CS2 ; Exit with error
@@:
endif				; IF @OEM_WIN3
	 FIXIJMP PGROUP:EMM_EA4,DTE_CS2 ; Exit with error
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_GSLINK58 endp		; End JMM2_GSLINK58 procedure
	 NPPROC  JMM2_MALLOC -- Call MAC_ALLOC
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 38, AH = 26h

Make an unguarded call to MAC_ALLOC.
We don't test for NO58 or DOS=UMB (same thing).  If we don't have control
of the arena (as in DOS=UMB) the call just fails.

All registers except EBP, SS, and ESP may be destroyed.

Caller's registers on entry:
BX	 Allocation strategy flags (see MAC.INC).  Reserved flags
	 such as @STRA_NOLSEG may be used.
CX	 Number of paragraphs to allocate.
SI	 Owner value to set.
DI	 High DOS region to allocate from or -1 for any region.

On exit:
AH	 Return error code from MAC_ALLOC or 0 if successful.
BX:0	 Segment of block allocated if successful.
CX	 Length of block in paras or largest block available if failed.

|

	 mov	 gs,SEL_4GB3	; Address AGROUP for MAC_ALLOC
	 assume  gs:AGROUP	; Tell the assembler

	 mov	 ax,[ebp].INTXX_ESI.ELO ; Get owner to set
	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get uncensored strategy flags
	 mov	 dx,[ebp].INTXX_ECX.ELO ; Get number of paras to allocate
	 mov	 di,[ebp].INTXX_EDI.ELO ; Get region or -1 for any

	 FCALL	 MAC_ALLOC	; Allocate block
	 mov	 [ebp].INTXX_ECX.ELO,dx ; Save length or largest size
	 jc	 short JMM2_MALERR ; Jump if we failed

	 mov	 [ebp].INTXX_EBX.ELO,ax ; Return segment of block

JMM2_MALEXIT:
	 jmp	 JMM_E00AL	; Join common OK code

JMM2_MALERR:
	 mov	 ah,al		; Get return error from MAC_ALLOC
if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 jz	 short @F	; Skip if not

	 FIXIJMP PGROUP:UTL_VXDOUT_ERR,DTE_CS2 ; Exit with error
@@:
endif				; IF @OEM_WIN3
	 FIXIJMP PGROUP:EMM_ERR,DTE_CS2 ; Exit with error in AH
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_MALLOC endp		; End JMM2_MALLOC procedure
	 NPPROC  JMM2_DLGROUP -- Subfunctions for 4B support in DLGROUP
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 39, AH = 27h

If AL = 0, return size of DLGROUP in paras in BX.

If AL = 1, process LSEG entries for PSP in BX.

If AL = 2, free LSEG entries.

If AL = 3, calculate load size.  DX,CX is the actual file size and
the EXE header is at CS:DLEXEHDR.

All registers except EBP, SS, and ESP may be destroyed.

Caller's registers on entry:
AL	 Subfunction (0, 1, 2 or 3).

If AL = 1,
BX	 PSP

If AL = 3,
DX	 High order word of file size
CX	 Low order word ...

On exit:
AH	 Error return A4 if AL out of range.
BX	 Size of DLGROUP in paras (AL=0 only)

|

	 mov	 gs,SEL_4GB3	; Address AGROUP
	 assume  gs:AGROUP	; Tell the assembler

	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Get subfunction
	 cmp	 al,3		; Izit in range?
	 ja	 short JMM2_DLGERR ; Jump if invalid

	 je	 short JMM2_DLG03 ; Jump if calculate header size

	 cmp	 al,1		; Izit process RINFO entries?
	 ja	 short JMM2_DLG02 ; Jump if free RINFO entries

	 je	 short JMM2_DLG01 ; Jump if process RINFO entries

JMM2_DLG00:
	 lea	 bx,DLGROUP:DLGROUP_END[16-1] ; Address end of DLGROUP
	 shr	 bx,4-0 	; Convert bytes to paras, rounding up
	 mov	 [ebp].INTXX_EBX.ELO,bx ; Save return value
	 jmp	 short JMM2_DLGEXIT ; Join common exit

JMM2_DLG01:
	 mov	 ax,[ebp].INTXX_CS ; Get caller's CS
	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get PSP
	 call	 DO_RINFO	; Process RINFO_STR entries
	 jmp	 short JMM2_DLGEXIT ; Join common exit

JMM2_DLG02:
	 call	 FREE_RINFO	; Free LSEG entries allocated in DO_RINFO
	 jmp	 short JMM2_DLGEXIT ; Join common exit

JMM2_DLG03:
	 movzx	 ebx,[ebp].INTXX_CS ; Get caller's CS
	 shl	 ebx,4-0	; Convert paras to bytes
	 mov	 dx,[ebp].INTXX_EDX.ELO ; Get high word of file size
	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get low word of file size
	 call	 CALC_EXEHDR	; Calculate load size for program and save it

JMM2_DLGEXIT:
	 jmp	 JMM_E00AL	; Join common OK code

JMM2_DLGERR:
if @OEM_WIN3
	 cmp	 VXD_LEVEL,0	; Izit in VXD call?
	 jz	 short @F	; Skip if not

	 FIXIJMP PGROUP:UTL_VXDOUT_ERR,DTE_CS2 ; Exit with error
@@:
endif				; IF @OEM_WIN3
	 FIXIJMP PGROUP:EMM_EA4,DTE_CS2 ; Exit with error

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_DLGROUP endp		; End JMM2_DLGROUP procedure
	 NPPROC  JMM2_PnP -- Subfunctions For PnP Support
	 assume  ds:PGROUP,es:PGROUP,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

EMM2 Function 42, AH = 2Ah


All registers except EBP, SS, and ESP may be destroyed.

Caller's registers on entry:

SS3:ESP3 ==>	PnP_VM_STR

On exit:

AX	 Error return code

|

PnP_VM_STR struc

	dd	?		; Caller's CS:IP return address
PnP_VM_FN dw	?		; PnP function
PnP_VM_REST dd	?		; The rest of the argument stack the
				; contents of which depend upon the function #
PnP_VM_STR ends

	mov	gs,SEL_4GB3	; Address AGROUP
	assume	gs:AGROUP	; Tell the assembler

; Enable interrupts if they're on in the caller

	test	[ebp].INTXX_EFL.ELO,mask $IF ; Izit enabled?
	jz	short @F	; Jump if not

	sti			; Enable interrupts
@@:
	movzx	eax,[ebp].INTXX_SS ; Get PL3 SS
	shl	eax,4-0 	; Convert from paras to bytes
	movzx	ebx,[ebp].INTXX_ESP.ELO ; Get PL3 SP
	add	ebx,eax 	; Add to get linear address
JMM2_PnP1:
	mov	edx,LaGDTPnPARG ; Get linear address of PnP arg selectors in GDT

	mov	ax,AGROUP:[ebx].PnP_VM_FN ; Get the PnP function

	cmp	ax,@PnP_GET_NUM_NODES  ; Izit Get # nodes?
	je	near ptr JMM2_PnP_GET_NUM_NODES ; Jump if so

	cmp	ax,@PnP_GET_DEV_NODE   ; Izit Get System Device Node?
	je	near ptr JMM2_PnP_GET_DEV_NODE ; Jump if so

	cmp	ax,@PnP_SET_DEV_NODE   ; Izit Set System Device Node?
	je	near ptr JMM2_PnP_SET_DEV_NODE ; Jump if so

	cmp	ax,@PnP_GET_EVENT      ; Izit Get Event #?
	je	near ptr JMM2_PnP_GET_EVENT ; Jump if so

	cmp	ax,@PnP_SEND_MSG       ; Izit Send Message?
	je	near ptr JMM2_PnP_SEND_MSG ; Jump if so

	cmp	ax,@PnP_GET_DOCK_INFO  ; Izit Get Docking Info?
	je	near ptr JMM2_PnP_GET_DOCK_INFO ; Jump if so

	cmp	ax,@PnP_SET_STATIC_RES ; Izit Set Statically Allocated Resources?
	je	near ptr JMM2_PnP_SET_STATIC_RES ; Jump if so

	cmp	ax,@PnP_GET_STATIC_RES ; Izit Get Statically Allocated Resources?
	je	near ptr JMM2_PnP_GET_STATIC_RES ; Jump if so

	cmp	ax,@PnP_GET_APM_ID_TAB ; Izit Get APM ID Table?
	je	near ptr JMM2_PnP_GET_APM_ID_TAB ; Jump if so

	cmp	ax,@PnP_GET_ISA_CFG    ; Izit Get ISA Configuration Struc?
	je	near ptr JMM2_PnP_GET_ISA_CFG ; Jump if so

	cmp	ax,@PnP_GET_ESCD_INFO  ; Izit Read ESCD Info?
	je	near ptr JMM2_PnP_GET_ESCD_INFO ; Jump if so

	cmp	ax,@PnP_GET_ESCD       ; Izit Read ESCD?
	je	near ptr JMM2_PnP_GET_ESCD ; Jump if so

	cmp	ax,@PnP_SET_ESCD       ; Izit Write ESCD?
	je	near ptr JMM2_PnP_SET_ESCD ; Jump if so

	cmp	ax,@PnP_GET_VERSION    ; Izit Get Version?
	je	near ptr JMM2_PnP_GET_VERSION ; Jump if so

	cmp	ax,@PnP_GET_DEV_CNT    ; Izit Get Device Count?
	je	near ptr JMM2_PnP_GET_DEV_CNT ; Jump if so

	cmp	ax,@PnP_GET_PRIORITY   ; Izit Get Priority?
	je	near ptr JMM2_PnP_GET_PRIORITY ; Jump if so

	cmp	ax,@PnP_SET_PRIORITY   ; Izit Set Priority?
	je	near ptr JMM2_PnP_SET_PRIORITY ; Jump if so

	cmp	ax,@PnP_GET_IPLDEV     ; Izit Get IPL Device from Last Boot?
	je	near ptr JMM2_PnP_GET_IPLDEV ; Jump if so

	cmp	ax,@PnP_GET_BOOT1ST    ; Izit Get Boot First?
	je	near ptr JMM2_PnP_GET_BOOT1ST ; Jump if so

	cmp	ax,@PnP_SET_BOOT1ST    ; Izit Set Boot First?
	je	near ptr JMM2_PnP_SET_BOOT1ST ; Jump if so

	test	LCL_FLAG,@LCL_SWAT ; Is 386SWAT installed?
	jz	short @F	; Jump if not

	int	03h		; Call our debugger
@@:
	mov	ax,@PnP_ERR_UNKFN ; Mark as Unknown Function
JMM2_PnP_EXIT:
if @OEM_WIN3
	cmp	VXD_LEVEL,0	; Izit in VXD call?
	jz	short @F	; Skip if not

	FIXIJMP PGROUP:UTL_VXDOUT,DTE_CS2 ; Exit with error code in AX
@@:
endif				; IF @OEM_WIN3
	FIXIJMP PGROUP:EMM_EXIT,DTE_CS2 ; Exit with error code in AX


PnP_ARG macro	RESTOFF,DTE

	mov	ecx,AGROUP:[ebx].PnP_VM_REST[RESTOFF] ; Get ptr to far arg
	movzx	eax,SEL_PnPARG&DTE ; Get data argument selector
	rol	ecx,16		; Swap offset and segment
	xchg	ax,cx		; Swap 'em
	rol	ecx,16		; Swap offset and segment
	push	ecx		; Pass ptr to far arg

	shl	eax,4-0 	; Convert from paras to bytes
	mov	AGROUP:[edx + DTE*(size DESC_STR)].DESC_BASE01,ax ; Save as bytes 0-1
	shr	eax,16		; Shift down high-order word
	mov	AGROUP:[edx + DTE*(size DESC_STR)].DESC_BASE2,al ; Save as byte 2
	mov	AGROUP:[edx + DTE*(size DESC_STR)].DESC_BASE3,ah ; Save as byte 3

	endm			; PnP_ARG


PnP_SAVE macro	DTE

	push	AGROUP:[edx + DTE*(size DESC_STR)].EDQLO ; Save DTE for arg #DTE
	push	AGROUP:[edx + DTE*(size DESC_STR)].EDQHI ; ...

	endm			; PnP_SAVE


PnP_REST macro	DTE

	pop	AGROUP:[edx + DTE*(size DESC_STR)].EDQHI ; Restore DTE for arg #DTE
	pop	AGROUP:[edx + DTE*(size DESC_STR)].EDQLO ; ...

	endm			; PnP_REST


JMM2_PnP_GET_NUM_NODES:
JMM2_PnP_GET_APM_ID_TAB:

PnP_FF_STR struc

PnP_FF_F1 dd	?		; unsigned int far *
PnP_FF_F2 dd	?		; unsigned int far *

PnP_FF_STR ends

; Handle prototype of (function, far *, far *, BIOS data selector)

	PnP_SAVE 0		; Save DTE for arg #0
	PnP_SAVE 1		; ...		    1

	REGSAVE <ds,es,fs,gs>	; Put on body armor

	push	SEL_PnPDS	; Pass BIOS data selector

	PnP_ARG PnP_FF_F2, 1	; Pass PnP arg at REST.PnP_FF_F2, DTE/arg #1
	PnP_ARG PnP_FF_F1, 0	; ...			       1,	   0

	push	AGROUP:[ebx].PnP_VM_FN ; Pass the function #

	call	PnP_VEC 	; Request PnP service
	add	esp,2+(size PnP_FF_STR)+2 ; Strip arguments from the stack

	REGREST <gs,fs,es,ds>	; Take it off

	PnP_REST 1		; Restore DTE for arg #1
	PnP_REST 0		; ...		       0

	jmp	JMM2_PnP_EXIT	; Join common exit code


JMM2_PnP_GET_DEV_NODE:

PnP_FFI_STR struc

PnP_FFI_F1 dd	?		; unsigned int far *
PnP_FFI_F2 dd	?		; unsigned int far *
PnP_FFI_I1 dw	?		; int

PnP_FFI_STR ends

; Handle prototype of (function, far *, far *, int, BIOS data selector)

	PnP_SAVE 0		; Save DTE for arg #0
	PnP_SAVE 1		; ...		    1

	REGSAVE <ds,es,fs,gs>	; Put on body armor

	push	SEL_PnPDS	; Pass BIOS data selector

	push	AGROUP:[ebx].PnP_VM_REST.PnP_FFI_I1 ; Pass 1st int

	PnP_ARG PnP_FFI_F2, 1	; Pass PnP arg at REST.PnP_FFI_F2, DTE/arg #1
	PnP_ARG PnP_FFI_F1, 0	; ...				1,	    0

	push	AGROUP:[ebx].PnP_VM_FN ; Pass the function #

	call	PnP_VEC 	; Request PnP service
	add	esp,2+(size PnP_FFI_STR)+2 ; Strip arguments from the stack

	REGREST <gs,fs,es,ds>	; Take it off

	PnP_REST 1		; Restore DTE for arg #1
	PnP_REST 0		; ...		       0

	jmp	JMM2_PnP_EXIT	; Join common exit code


JMM2_PnP_SET_DEV_NODE:

PnP_IFI_STR struc

PnP_IFI_I1 dw	?		; int
PnP_IFI_F1 dd	?		; unsigned int far *
PnP_IFI_I2 dw	?		; int

PnP_IFI_STR ends

; Handle prototype of (function, int, far *, int, BIOS data selector)

	PnP_SAVE 0		; Save DTE for arg #0

	REGSAVE <ds,es,fs,gs>	; Put on body armor

	push	SEL_PnPDS	; Pass BIOS data selector

	push	AGROUP:[ebx].PnP_VM_REST.PnP_IFI_I2 ; Pass 2nd int

	PnP_ARG PnP_IFI_F1, 0	; Pass PnP arg at REST.PnP_IFI_F1, DTE/arg #0

	push	AGROUP:[ebx].PnP_VM_REST.PnP_IFI_I1 ; Pass 1st int

	push	AGROUP:[ebx].PnP_VM_FN ; Pass the function #

	call	PnP_VEC 	; Request PnP service
	add	esp,2+(size PnP_IFI_STR)+2 ; Strip arguments from the stack

	REGREST <gs,fs,es,ds>	; Take it off

	PnP_REST 0		; Restore DTE for arg #0

	jmp	JMM2_PnP_EXIT	; Join common exit code


JMM2_PnP_GET_EVENT:
JMM2_PnP_GET_DOCK_INFO:
JMM2_PnP_SET_STATIC_RES:
JMM2_PnP_GET_STATIC_RES:
JMM2_PnP_GET_ISA_CFG:
JMM2_PnP_GET_VERSION:
JMM2_PnP_GET_IPLDEV:
JMM2_PnP_GET_BOOT1ST:
JMM2_PnP_SET_BOOT1ST:

PnP_F_STR struc

PnP_F_F1 dd	?		; unsigned int far *

PnP_F_STR ends

; Handle prototype of (function, far *, BIOS data selector)

	PnP_SAVE 0		; Save DTE for arg #0

	REGSAVE <ds,es,fs,gs>	; Put on body armor

	push	SEL_PnPDS	; Pass BIOS data selector

	PnP_ARG PnP_F_F1, 0	; Pass PnP arg at REST.PnP_F_F1, DTE/arg #0

	push	AGROUP:[ebx].PnP_VM_FN ; Pass the function #

	call	PnP_VEC 	; Request PnP service
	add	esp,2+(size PnP_F_STR)+2 ; Strip arguments from the stack

	REGREST <gs,fs,es,ds>	; Take it off

	PnP_REST 0		; Restore DTE for arg #0

	jmp	JMM2_PnP_EXIT	; Join common exit code


JMM2_PnP_SEND_MSG:

PnP_I_STR struc

PnP_I_I1 dw	?		; int

PnP_I_STR ends

; Handle prototype of (function, int, BIOS data selector)

	REGSAVE <ds,es,fs,gs>	; Put on body armor

	push	SEL_PnPDS	; Pass BIOS data selector

	push	AGROUP:[ebx].PnP_VM_REST.PnP_I_I1 ; Pass 1st int

	push	AGROUP:[ebx].PnP_VM_FN ; Pass the function #

	call	PnP_VEC 	; Request PnP service
	add	esp,2+(size PnP_I_STR)+2 ; Strip arguments from the stack

	REGREST <gs,fs,es,ds>	; Take it off

	jmp	JMM2_PnP_EXIT	; Join common exit code


JMM2_PnP_GET_ESCD_INFO:

PnP_FFF_STR struc

PnP_FFF_F1 dd	?		; unsigned int far *
PnP_FFF_F2 dd	?		; unsigned int far *
PnP_FFF_F3 dd	?		; unsigned int far *

PnP_FFF_STR ends

; Handle prototype of (function, far *, far *, far *, BIOS data selector)

	PnP_SAVE 0		; Save DTE for arg #0
	PnP_SAVE 1		; ...		    1
	PnP_SAVE 2		; ...		    2

	REGSAVE <ds,es,fs,gs>	; Put on body armor

	push	SEL_PnPDS	; Pass BIOS data selector

	PnP_ARG PnP_FFF_F3, 2	; Pass PnP arg at REST.PnP_FFF_F3, DTE/arg #2
	PnP_ARG PnP_FFF_F2, 1	; ...				2,	    1
	PnP_ARG PnP_FFF_F1, 0	; ...				1,	    0

	push	AGROUP:[ebx].PnP_VM_FN ; Pass the function #

	call	PnP_VEC 	; Request PnP service
	add	esp,2+(size PnP_FFF_STR)+2 ; Strip arguments from the stack

	REGREST <gs,fs,es,ds>	; Take it off

	PnP_REST 2		; Restore DTE for arg #2
	PnP_REST 1		; ...		       1
	PnP_REST 0		; ...		       0

	jmp	JMM2_PnP_EXIT	; Join common exit code


JMM2_PnP_GET_ESCD:
JMM2_PnP_SET_ESCD:

PnP_FS_STR struc

PnP_FS_F1 dd	?		; unsigned int far *
PnP_FS_S1 dw	?		; selector

PnP_FS_STR ends

; Handle prototype of (function, far *, ESCD selector, BIOS data selector)

	PnP_SAVE 0		; Save DTE for arg #0
	PnP_SAVE 1		; ...		    1

	REGSAVE <ds,es,fs,gs>	; Put on body armor

	push	SEL_PnPDS	; Pass BIOS data selector

	push	SEL_PnPARG1	; Pass argument data selector #1

	movzx	eax,AGROUP:[ebx].PnP_VM_REST.PnP_FS_S1 ; Get ESCD segment
	shl	eax,4-0 	; Convert from paras to bytes
	mov	AGROUP:[edx + 1*(size DESC_STR)].DESC_BASE01,ax ; Save as bytes 0-1
	shr	eax,16		; Shift down high-order word
	mov	AGROUP:[edx + 1*(size DESC_STR)].DESC_BASE2,al ; Save as byte 2
	mov	AGROUP:[edx + 1*(size DESC_STR)].DESC_BASE3,ah ; Save as byte 3

	PnP_ARG PnP_FS_F1, 0   ; Pass PnP arg at REST.PnP_FS_F1, DTE/arg #0

	push	AGROUP:[ebx].PnP_VM_FN ; Pass the function #

	call	PnP_VEC 	; Request PnP service
	add	esp,2+(size PnP_FS_STR)+2 ; Strip arguments from the stack

	REGREST <gs,fs,es,ds>	; Take it off

	PnP_REST 1		; Restore DTE for arg #1
	PnP_REST 0		; ...		       0

	jmp	JMM2_PnP_EXIT	; Join common exit code


JMM2_PnP_GET_DEV_CNT:

PnP_IFFF_STR struc

PnP_IFFF_I1 dw	?		; int
PnP_IFFF_F1 dd	?		; unsigned far *
PnP_IFFF_F2 dd	?		; unsigned far *
PnP_IFFF_F3 dd	?		; unsigned far *

PnP_IFFF_STR ends

; Handle prototype of (function, int, far *, far *, far *, BIOS data selector)

	PnP_SAVE 0		; Save DTE for arg #0
	PnP_SAVE 1		; ...		    1
	PnP_SAVE 2		; ...		    2

	REGSAVE <ds,es,fs,gs>	; Put on body armor

	push	SEL_PnPDS	; Pass BIOS data selector

	PnP_ARG PnP_IFFF_F3, 2	; Pass PnP arg at REST.PnP_IFFF_F3, DTE/arg #2
	PnP_ARG PnP_IFFF_F2, 1	; ...				 2,	     1
	PnP_ARG PnP_IFFF_F1, 0	; ...				 1,	     0

	push	AGROUP:[ebx].PnP_VM_REST.PnP_IFFF_I1 ; Pass 1st int

	push	AGROUP:[ebx].PnP_VM_FN ; Pass the function #

	call	PnP_VEC 	; Request PnP service
	add	esp,2+(size PnP_IFFF_STR)+2 ; Strip arguments from the stack

	REGREST <gs,fs,es,ds>	; Take it off

	PnP_REST 2		; Restore DTE for arg #2
	PnP_REST 1		; ...		       1
	PnP_REST 0		; ...		       0

	jmp	JMM2_PnP_EXIT	; Join common exit code


JMM2_PnP_GET_PRIORITY:

PnP_IFF_STR struc

PnP_IFF_I1 dw	?		; int
PnP_IFF_F1 dd	?		; unsigned far *
PnP_IFF_F2 dd	?		; unsigned far *

PnP_IFF_STR ends

; Handle prototype of (function, int, far *, far *, BIOS data selector)

	PnP_SAVE 0		; Save DTE for arg #0
	PnP_SAVE 1		; ...		    1

	REGSAVE <ds,es,fs,gs>	; Put on body armor

	push	SEL_PnPDS	; Pass BIOS data selector

	PnP_ARG PnP_IFF_F2, 1	; Pass PnP arg at REST.PnP_IFF_F2, DTE/arg #1
	PnP_ARG PnP_IFF_F1, 0	; ...				1,	    0

	push	AGROUP:[ebx].PnP_VM_REST.PnP_IFF_I1 ; Pass 1st int

	push	AGROUP:[ebx].PnP_VM_FN ; Pass the function #

	call	PnP_VEC 	; Request PnP service
	add	esp,2+(size PnP_IFF_STR)+2 ; Strip arguments from the stack

	REGREST <gs,fs,es,ds>	; Take it off

	PnP_REST 1		; Restore DTE for arg #1
	PnP_REST 0		; ...		       0

	jmp	JMM2_PnP_EXIT	; Join common exit code


JMM2_PnP_SET_PRIORITY:

PnP_IF_STR struc

PnP_IF_I1 dw   ?	       ; int
PnP_IF_F1 dd   ?	       ; unsigned far *

PnP_IF_STR ends

; Handle prototype of (function, int, far *, BIOS data selector)

	PnP_SAVE 0		; Save DTE for arg #0

	REGSAVE <ds,es,fs,gs>	; Put on body armor

	push	SEL_PnPDS	; Pass BIOS data selector

	PnP_ARG PnP_IF_F1, 0	; Pass PnP arg at REST.PnP_IF_F1, DTE/arg #0

	push	AGROUP:[ebx].PnP_VM_REST.PnP_IF_I1 ; Pass 1st int

	push	AGROUP:[ebx].PnP_VM_FN ; Pass the function #

	call	PnP_VEC 	; Request PnP service
	add	esp,2+(size PnP_IF_STR)+2 ; Strip arguments from the stack

	REGREST <gs,fs,es,ds>	; Take it off

	PnP_REST 0		; Restore DTE for arg #0

	jmp	JMM2_PnP_EXIT	; Join common exit code


	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

JMM2_PnP endp			; End JMM2_PnP procedure
if @OEM_DPMI
	 FPPROC  SET_HWSP -- Set DPMI_HWSP Values
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set DPMI_HWSP bitmap values.  These bits are used in INTCOM to
check on hardware or special interrupts from VM or MAX which
must be reflected to DPMI clients in PM.

The special interrupt #s are 1Ch, 23h, 24h.
The hardware interrupts are anything from the master or slave PIC.

|

	 REGSAVE <ax,cx,di>	; Save registers

; Clear the maps

	 mov	 cx,size DPMI_HWSP ; CX = # bytes in DPMI_HWSP
	 lea	 di,DPMI_HWSP	; ES:DI ==> DPMI_HWSP
	 xor	 al,al		; A convenient zero
     rep stos	 DPMI_HWSP[di]	; Clear it

	 mov	 cx,size DPMI_HW ; CX = # bytes in DPMI_HW
	 lea	 di,DPMI_HW	; ES:DI ==> DPMI_HW
;;;;;;;; xor	 al,al		; A convenient zero
     rep stos	 DPMI_HW[di]	; Clear it

; Set the special values

; Note that we can't use BTS with immediate here as MASM 5.10 doesn't
; handle it correctly

	 or	 DPMI_HWSP[1Ch/8],1 shl (1Ch mod 8) ; Set the bit for INT 1Ch
	 or	 DPMI_HWSP[23h/8],1 shl (23h mod 8) ; ...	      INT 23h
	 or	 DPMI_HWSP[24h/8],1 shl (24h mod 8) ; ...	      INT 24h

	 mov	 di,NEWIMR1	; Get master PIC base (/8)
	 shr	 di,3-0 	; Convert from bits to bytes
	 mov	 DPMI_HWSP[di],0FFh ; Set all eight IRQs
	 mov	 DPMI_HW[di],0FFh ; ...

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jnz	 short @F	; Jump if so (no slave PIC)

	 mov	 di,NEWIMR2	; Get slave PIC base (/8)
	 shr	 di,3-0 	; Convert from bits to bytes
	 mov	 DPMI_HWSP[di],0FFh ; Set all eight IRQs
	 mov	 DPMI_HW[di],0FFh ; ...
@@:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_HWSP endp			; End SET_HWSP procedure
endif				; IF @OEM_DPMI
	 FPPROC  INIT_DATA -- Initialize The Various Data Areas
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize the various data areas.

    * Initialize PPL0STK_MAP and deadman switch
    * Zero DMA_CHAN
    * Zero HARDCNT
    * Initialize XMSBMAP bytemaps
    * Set current MRS to default
    * Free all existing handles
    * Initialize BASEPAGE table to invalid markers
    * Mark all page link pointers as unallocated
    * Mark all names in HNDLNAME as zero
    * Clear HFRMSAV pointers
    * Restore remaining page count
    * Mark RPNCUR entries with their defaults
    * Keep RPNCUR up-to-date with RPNs of handle zero
    * Mark all EMMSIZE page link pointers as unallocated
    * Link conventional memory into PAGELINK
    * Mark all entries in HNDLPAGE as last entries
    * Set XMSBMAP contiguity bounds
    * Translate the RPNCUR entries into PTEs and put them into the PDT
    * Fill in default entries for LINKBASE table
    * Clear EMM_FLAG values
    * Set DPMI_HWSP values

Note that XMS data areas are initialized separately by INIT_XMS.

|

	 pushad 		; Save all EGP registers

	 pushf			; Save flags

	 cli			; Disallow interrupts

;     * Initialize PPL0STK_MAP and deadman switch

	 mov	 ebx,PPL0STK_INI ; Get start of stack
	 mov	 PPL0STK_MAP,ebx ; Initialize it
	 mov	 PGROUP:[ebx-(type PPL0STK_MAP)],ebx ; Save as deadman switch

if @OEM_DMA

;     * Zero DMA_CHAN

	 mov	 DMA_CHAN,0	; Start off with no DMA channels in use
endif				; IF @OEM_DMA

;     * Zero HARDCNT

	 mov	 HARDCNT,0	; Start off with no pending hardware interrupts


;     * Initialize XMSBMAP bytemap

	 mov	 edi,PXMSBMAP	; ES:EDI ==> XMS allocation bytemap table
	 mov	 ecx,EXTBASE	; Get start of XMS free chain
	 shr	 ecx,10-0	; Convert from bytes to 1KB
	 mov	 ebx,ecx	; Save for later use
	 mov	 al,@XMSB_ALLOC ; Get allocated marker
     rep stos	 PGROUP:[edi].LO ; Mark as allocated

	 mov	 ecx,XMSBMAP_LEN ; ECX = byte length of XMSBMAP
	 sub	 ecx,ebx	; Less leading part
	 mov	 al,00h 	; No bits set means available
     rep stos	 PGROUP:[edi].LO ; Mark as available

	 mov	 al,0FFh	; All bits set means terminal entry
S32	 stos	 PGROUP:[edi].LO ; Mark as terminal


if @OEM_EMS

;     * Set current MRS to default

	 mov	 MRS_CUR,0	; Set current MRS to default

;     * Free all existing handles

	 lea	 di,HMAP	; ES:DI ==> HMAP
	 mov	 al,@BIT0	; Mark OS/E handle as active
S16	 stos	 HMAP[di]	; Save first value with OS/E active

	 mov	 al,00h 	; Set the remainder to zero
	 mov	 cx,@HMAPSIZE-1 ; # bytes in HMAP
     rep stos	 HMAP[di]	; Consider it zeroed

	 mov	 EHNDLCNT,1	; Back to OS/E EMS handle only

	 test	 CM2_FLAG,@CM2_SCR ; SCREEN specified?
	 jz	 short INIT_DATA_NOSCR1 ; Not this time

	 or	 HMAP[@SCR_HNDL/8],@BIT0 shl (@SCR_HNDL mod 8) ; Mark as active
	 inc	 EHNDLCNT	; Include in EMS handle count
INIT_DATA_NOSCR1:

;     * Mark all names in HNDLNAME as zero

	 mov	 ecx,@MAX_EHNDLCNT ; ECX = maximum # EMS handles
	 shl	 ecx,1		; Times two dwords per handle name
	 mov	 edi,PHNDLNAME	; ES:EDI ==> start of HNDLNAME table
	 xor	 eax,eax	; 0 = unnamed
     rep stos	 PGROUP:[edi].EDD ; Zero the handle names


;     * Clear HFRMSAV pointers

;;;;;;;; cmp	 EMMSIZE,0	; Any EMS memory?
;;;;;;;; je	 short INIT_DATA_HFRMSAV_END ; No, skip all this
;;;;;;;;
	 mov	 edi,PHFRMSAV	; ES:EDI ==> start of HFRMSAV area
	 mov	 cx,@MAX_EHNDLCNT ; CX = # rows in table
INIT_DATA_HFRMSAV_LOOP1:
	 mov	 PGROUP:[edi].HFRM_OWNR,@RPN_UNUSED ; Mark it as unused

	 push	 cx		; Save for a moment

	 lea	 edi,[edi].HFRM_SAVE ; ES:EDI ==> (handle, LPN) entries
	 mov	 cx,NPHYS16F.ELO ; Get # (handle, LPN) entries in EMS page frame
	 jcxz	 INIT_DATA_HFRMSAV_LOOP3 ; Jump if NOFRAME
INIT_DATA_HFRMSAV_LOOP2:
	 mov	 PGROUP:[edi].RPN_RPN,@RPN_UNMAP ; Mark RPN as unmapped

	 add	 edi,size RPN_STR ; Skip to next RPN entry

	 loop	 INIT_DATA_HFRMSAV_LOOP2 ; Jump if more entries to initialize
INIT_DATA_HFRMSAV_LOOP3:
	 pop	 cx		; Restore

	 loop	 INIT_DATA_HFRMSAV_LOOP1 ; Jump if more rows to mark
INIT_DATA_HFRMSAV_END:


;     * Restore remaining page count
;	This value is the # 16KB pages in EMS memory from extended memory

	 mov	 eax,CMPSIZEMM	; Get EMS lmited size of common memory pool
;;;;;;;; and	 eax,not (16-1) ; Round down to 16KB boundary
	 shr	 eax,14-10	; Convert from 1KB to 16KB
	 mov	 EMSPGCNT,ax	; Save as remaining logical page count


;     * Mark RPNCUR entries with their defaults

	 mov	 eax,PRPNTAB	; Get pointer to start of RPN tables
	 mov	 PRPNCUR,eax	; Save as pointer to current table

	 xor	 edi,edi	; Initialize index into RPNCUR
	 mov	 ebx,PRPNCUR	; DS:EBX ==> current RPN table
	 mov	 cx,NPHYS16S.ELO ; Get # physical 16KB pages in the EMS system
	 jcxz	 INIT_DATA_RPNCUR_NEXT ; No EMS-mappable pages
@@:
	 mov	 PGROUP:[ebx+edi].RPN_RPN,@RPN_IDENT ; Mark RPN as identity mapping

	 add	 edi,size RPN_STR ; Skip to next RPN entry

	 loop	 @B		; Jump if more entries to fill in
INIT_DATA_RPNCUR_NEXT:


;	Next, fill in conventional memory entries
;     * Keep RPNCUR up-to-date with RPNs of handle zero
;	for conventional memory entries, unmapped pages for INCLUDEd entries

	 mov	 eax,size RPN_STR ; Get size of each RPN_STR entry
	 mov	 edi,PSEG2PHYS	; Get address of start of SEG2PHYS table
	 mul	 PGROUP:[edi].LO ; Times physical page #
	 mov	 edi,eax	; Save as offset into table
	 mov	 ax,EMSPGCNT	; Get # 16KB pages of EMS (not CNV memory)
	 shl	 ax,2		; Times four to index table of dwords (as an RPN)
;;;;;;;; mov	 ebx,PRPNCUR	; DS:EBX ==> current RPN table
	 mov	 cx,NPHYSCNV.ELO ; Get # physical 16KB pages in CNV memory
	 jcxz	 INIT_DATA_XCNV2 ; Jump if no mapped conventional memory
INIT_DATA_CNV:
	 mov	 PGROUP:[ebx+edi].RPN_RPN,ax ; Save RPN

	 add	 edi,size RPN_STR ; Skip to next RPN entry

	 add	 ax,size PL_STR ; Skip to next RPN

	 loop	 INIT_DATA_CNV	; Jump if more CNV entries
INIT_DATA_XCNV2:


;	Next, fill in screen memory entries
;     * Keep RPNCUR up-to-date with RPNs of handle @SCR_HNDL

	 mov	 cx,NPHYSSCR.ELO ; Get # physical 16KB pages in SCREEN memory
	 jcxz	 INIT_DATA_XSCR2 ; Jump if no mapped screen memory
INIT_DATA_SCR:
	 mov	 PGROUP:[ebx+edi].RPN_RPN,ax ; Save RPN

	 add	 edi,size RPN_STR ; Skip to next RPN entry

	 add	 ax,size PL_STR ; Skip to next RPN

	 loop	 INIT_DATA_SCR	; Jump if more SCR entries
INIT_DATA_XSCR2:


;     * Initialize BASEPAGE table to invalid markers

	 mov	 edi,PBASEPAGE	; ES:EDI ==> BASEPAGE table
	 mov	 ecx,BASEPAGE_LEN ; Get length in dwords
	 mov	 eax,BASEPAGE_INV ; Invalid marker
     rep stos	 PGROUP:[edi].PL_NEXT ; Mark all entries as invalid


;     * Mark all page link pointers as free by linking them into a chain

	 mov	 esi,PHNDLCNT	; Get pointer to handle-count table

	 mov	 cx,EMSPGCNT	; Get # 16KB pages of EMS (not CNV memory)
	 mov	 PGROUP:[esi+2*@FREE_HNDL],cx ; Save as handle-count for free handle
	 mov	 edi,PPAGELINK	; ES:EDI ==> start of PAGELINK table
	 mov	 edx,EMMBASE	; Get base of EMS memory
	 call	 FILL_LINK	; Fill in chained links


;     * Link conventional memory into PAGELINK

	 mov	 cx,NPHYSCNV.ELO ; Get # physical 16KB pages in CNV memory
	 mov	 PGROUP:[esi+2*@OSE_HNDL],cx ; Save as handle-count for OS/E handle
	 mov	 ebx,edi	; Save offset as start of handle zero link
	 mov	 edx,PSEG2PHYS	; DS:EDX ==> SEG2PHYS table
	 movzx	 edx,PGROUP:[edx].LO ; Get first entry (lowest CNV entry)
	 shl	 edx,1-0	; Convert from words to bytes
	 add	 edx,PPHYS2SEG	; Plus base of PHYS2SEG table
	 movzx	 edx,PGROUP:[edx].ELO ; EDX = para of start of CNV entries
	 shl	 edx,4-0	; Convert from paras to bytes
	 call	 FILL_LINK	; Fill in chained links


;     * Link SCREEN memory into PAGELINK

	 mov	 cx,NPHYSSCR.ELO ; Get # physical 16KB pages in SCREEN memory
	 mov	 PGROUP:[esi+2*@SCR_HNDL],cx ; Save as handle-count for SCR handle
	 push	 edi		; Save offset as start of SCREEN handle link
	 mov	 edx,000B0000h	; EDX = start of SCR memory
	 call	 FILL_LINK	; Fill in chained links
	 pop	 edx		; Restore to EDX for later use

	 sub	 edi,PPAGELINK	; Less start of table
	 mov	 MAXRPN,edi	; Save as maximum RPN


;     * Mark all entries in HNDLPAGE as last entries

	 mov	 edi,PHNDLPAGE	; ES:EDI ==> HNDLPAGE
	 mov	 eax,ebx	; Copy pointer to start of handle zero links

	 cmp	 NPHYSCNV,0	; Any EMS pages in conventional memory?
	 jne	 short INIT_DATA_HNDL ; Yes, use BX

	 mov	 eax,HP_LAST	; Mark as last entry
INIT_DATA_HNDL:
S32	 stos	 PGROUP:[edi].PL_NEXT ; Save in HNDLPAGE table

	 xor	 ecx,ecx	; Avoid MASM bug
	 mov	 cx,@MAX_EHNDLCNT-1 ; ECX = maximum # EMS handles less OS/E handle
	 mov	 eax,HP_LAST	; Mark as last entry
     rep stos	 PGROUP:[edi].PL_NEXT ; Mark LPN as last entry

	 mov	 PPHNDLFREE,edi ; Save as ptr to ptr to start free chain
	 mov	 eax,PPAGELINK	; Get start of PAGELINK table
S32	 stos	 PGROUP:[edi].PL_NEXT ; Mark as pointer to free chain "handle"

	 mov	 PPHNDLVMS,edi	; Save as ptr to ptr to start of VMS chain
	 mov	 eax,HP_LAST	; Mark as last entry
S32	 stos	 PGROUP:[edi].PL_NEXT ; Mark as pointer to VMS chain "handle"

; Fill in SCREEN handle page-link

	 test	 CM2_FLAG,@CM2_SCR ; SCREEN specified?
	 jz	 short INIT_DATA_NOSCR3 ; Not this time

	 mov	 esi,PHNDLPAGE	; DS:ESI ==> HNDLPAGE table
	 mov	 PGROUP:[esi+@SCR_HNDL*(size PL_STR)].PL_NEXT,edx ; Save offset of SCREEN handle link
INIT_DATA_NOSCR3:

;     * Fill in default entries for LINKBASE table

	 mov	 edi,PLINKBASE	; ES:EDI ==> LINKBASE

;	First, fill in entries for EMS memory in extended memory

	 movzx	 ecx,EMSPGCNT	; Get # 16KB pages of EMS memory
				; excluding conventional memory pages
	 mov	 eax,PPDTEMM	; Fill with PPDTEMM
     rep stos	 PGROUP:[edi].EDD ; Mark as using EMMBASE

;	Next, fill in conventional memory entries

	 mov	 cx,NPHYSCNV.ELO ; Get # physical 16KB pages in CNV memory
	 jcxz	 INIT_DATA_LINK_SCR ; No conventional memory pages

	 mov	 ebx,PPDTCNV	; Get start of PDTCNV in 4KB in dwords
	 mov	 eax,CMPSIZEMM	; Get EMS limited size of common memory pool (multiple of 4KB in 1KB)
	 and	 eax,not (16-1) ; Round down to 16KB boundary
;;;;;;;; sh?	 eax,(12-2)-10	; Convert from 1KB to 4KB in dwords
	 sub	 ebx,eax	; Back off by that amount

	 mov	 esi,PSEG2PHYS	; DS:ESI ==> SEG2PHYS table
	 movzx	 esi,PGROUP:[esi].LO ; Get first entry (lowest CNV entry)
	 shl	 esi,1		; Times two to index table of words
	 add	 esi,PPHYS2SEG	; Plus base of PHYS2SEG table
				; DS:ESI ==> CNV entries
INIT_DATA_LINK_NEXT:
	 xor	 eax,eax	; Zero to use as dword
	 lods	 ds:[esi].ELO	; Get next segment (multiple of 4KB in paras)
	 shr	 eax,(12-2)-4	; Convert from paras to 4KB in dwords
	 add	 eax,ebx	; Add in base
S32	 stos	 PGROUP:[edi].EDD ; Save in LINKBASE table

	 sub	 ebx,4*4	; Less four dwords

	 loop	 INIT_DATA_LINK_NEXT ; Jump if more conventional physical pages

;	Next, fill in SCREEN memory entries

INIT_DATA_LINK_SCR:
	 mov	 eax,PPDTSCR	; Get start of PDTSCR in 4KB in dwords
	 mov	 ebx,CMPSIZEMM	; Get EMS limited size of common memory pool (multiple of 4KB in 1KB)
	 and	 ebx,not (16-1) ; Round down to 16KB boundary
;;;;;;;; sh?	 ebx,(12-2)-10	; Convert from 1KB to 4KB in dwords
	 sub	 eax,ebx	; Back off by that amount
	 movzx	 ebx,NPHYSCNV.ELO ; Get # physical 16KB pages in CNV memory
	 shl	 ebx,14-(12-2)	; Convert from 16KB to 4KB in dwords
	 sub	 eax,ebx	; Back off by that amount

	 movzx	 ecx,NPHYSSCR.ELO ; Get # physical 16KB pages in SCREEN memory
     rep stos	 PGROUP:[edi].EDD ; Save in LINKBASE table


;	Next, fill in entries for pseudo-1MB unwrap
; These entries are used only if there is an overlap of EMS memory
; with any of the PTEs in the 1MB wrap region

	 mov	 edi,PLINKBASE	; ES:EDI ==> LINKBASE
	 mov	 eax,PPDTUNW	; Get start of PDTUNW in 4KB in dwords
	 movzx	 ecx,UNWCNT	; Get count of # PTEs in unwrap region
				; (always a multiple of 4)
	 shr	 ecx,14-12	; Convert from 4KB to 16KB
     rep stos	 PGROUP:[edi].EDD ; Save in LINKBASE table


if @OEM_WIN3 and @OEM_XMS

;     * Set XMSBMAP contiguity bounds

	 FIXICALL PGROUP:FSET_XMSBND,DTE_CS2 ; Set XMSBMAP boundary entries
endif				; IF @OEM_WIN3 or @OEM_XMS


;     * Translate the RPNCUR entries into PTEs and put them into the PDT

	 FIXICALL PGROUP:FPGMAP_ALL,DTE_CS2 ; Translate RPNCUR entries into PTEs
	 jnc	 short INIT_DATA_PGMAPOK ; Jump if all went well
INIT_DATA_PGMAP_ERR:
	 int	 3		; Break here on error FIXME

	 jmp	 short INIT_DATA_PGMAP_ERR ; Just keep on breaking

INIT_DATA_PGMAPOK:


;     * Clear EMM_FLAG values

	 mov	 EMM_FLAG,0	; Clear it to original value

endif				; IF @OEM_EMS

if @OEM_DPMI

;     * Set DPMI_HWSP values

	 FCALL	 SET_HWSP	; Set DPMI_HWSP values for special interrupts
endif				; IF @OEM_DPMI

	 popf			; Restore

	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_DATA endp			; End INIT_DATA procedure
if @OEM_EMS
	 NPPROC  FILL_LINK -- Fill In Chained Links
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in chained links in the PAGELINK table

On entry:

CX	 =	 # entries to fill in
ES:EDI	 ==>	 offset of next entry
EDX	 =	 starting linear address of the memory being linked

On exit:

ES:EDI	 ==>	 offset of next entry (updated)
EDX	 =	 clobbered

|

	 REGSAVE <eax,cx>	; Save registers

	 jcxz	 FILL_LINK_EXIT ; No physical pages in conventional memory

	 and	 edx,not (16*1024-1) ; Round down to 16KB boundary
	 shr	 edx,(14-2)-0	; Convert from bytes to 16KB in dwords
	 add	 edx,PBASEPAGE	; Plus start of BASEPAGE table

	 dec	 cx		; Store the last one separately
	 jz	 short FILL_LINK_END ; Only one physical page in conventional memory???

	 mov	 eax,edi	; Copy current offset
FILL_LINK_LOOP:
	 mov	 PGROUP:[edx].PL_NEXT,eax ; Save in BASEPAGE table
	 add	 edx,size PL_STR ; Skip to next entry

	 add	 eax,size PL_STR ; Point to next entry

S32	 stos	 PGROUP:[edi].PL_NEXT ; Save the page-link

	 loop	 FILL_LINK_LOOP ; Jump if more to link
FILL_LINK_END:
	 mov	 PGROUP:[edx].PL_NEXT,eax ; Save in BASEPAGE table

	 mov	 eax,HP_LAST	; Mark as last entry
S32	 stos	 PGROUP:[edi].PL_NEXT ; Save the page-link
FILL_LINK_EXIT:
	 REGREST <cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_LINK endp			; End FILL_LINK procedure
endif				; IF @OEM_EMS
	 align	 4		; Ensure dword alignment

JCODE	 ends			; End JCODE segment

	 MEND			; End QMAX_EM2 module

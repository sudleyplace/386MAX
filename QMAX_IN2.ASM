;' $Header:   P:/PVCS/MAX/386MAX/QMAX_IN2.ASV   1.3   30 May 1997 10:45:12   BOB  $
	 title	 QMAX_IN2 -- 386MAX Initialization Routines, Part 2
	 page	 58,122
	 name	 QMAX_IN2

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Data    segment ZDATA, para-aligned,  public, class 'zdata'
	       Program segment NCODE, byte-aligned,  public, class 'ncode'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'
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
	 include CPUFLAGS.INC
	 include 8259.INC
	 include 386.INC
	 include PTR.INC
	 include ALLMEM.INC
	 include CPUFET.INC

	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_I31.INC
	 include QMAX_TDT.INC
	 include QMAX_TSS.INC
	 include QMAX_VCP.INC
	 include QMAX_VMM.INC
.list

PGROUP	 group	 CODE,HICODE,ECODE,EDATA,ZDATA,NCODE,NDATA
IGROUP	 group	 LCODE,ICODE
JGROUP	 group	 JCODE
XGROUP	 group	 XCODE
YGROUP	 group	 YDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

if @OEM_WIN3
	 extrn	 WIN3_END:near

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC
endif				; IF @OEM_WIN3

if @OEM_DPMI
	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC
endif				; IF @OEM_DPMI
	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 INTA01:byte
	 extrn	 INTB01:byte

	 extrn	 PRGSIZE:word
	 extrn	 LOWSIZE:word
	 extrn	 LOWGDT:qword

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 SBIOSDATA:word

HICODE	 ends			; End HICODE segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 ENTERPM:far

NCODE	 ends			; End NCODE segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

	 extrn	 MSG_ERRMOV:byte,MSG_ERRMOV1:byte
	 extrn	 MSG_ERRPRO:byte,MSG_ERRPRO1:byte
	 extrn	 MSG_ERRMOV2:byte,MSG_ERRMOV3:byte
	 extrn	 MSG_ERRMOV4:byte

YDATA	 ends			; End YDATA segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 CPUFET_FLAG:dword
	 extrn	 VIDMODE:byte
if @OEM_DPMI
	 extrn	 PDPMILDT:dword
	 extrn	 LDT_SIZ:dword
	 extrn	 SEL_4GB3:word
if @OEM_VIRTUALMEM
	 extrn	 VMM_FLAG:word
endif				; IF @OEM_VIRTUALMEM
endif				; IF @OEM_DPMI
	 extrn	 INT07DP:qword

	 public  @IOMAP
@IOMAP	 equ	 2000h		; Byte size of I/O bit permission map

	 extrn	 DESC_TAB:qword
	 extrn	 PRGBASE:dword
	 extrn	 PaPRGBASE:dword
	 extrn	 PaPRGBASE2:dword
	 extrn	 LOWOFF:dword
	 extrn	 IDT_DESC:qword
	 extrn	 IDT_DESC_LEN:abs
if @OEM_EMS
	 extrn	 NPHYS16F:byte
endif				; IF @OEM_EMS
	 extrn	 LaCR3:dword
	 extrn	 LaDIR2:dword
	 extrn	 PDTLEN:dword
	 extrn	 HEXTABLE:byte
	 extrn	 DSTK_HWINTS:byte
if @OEM_VCPI
	 extrn	 VCPIBASE:dword

	 extrn	 FGRBASE:dword
	 extrn	 FGRSIZE:dword
	 extrn	 JGRBASE:dword
	 extrn	 JGRSIZE:dword
	 extrn	 JGRDSIZE:dword

	 public  EPMTAB
EPMTAB	 EPM_STR <>		; Enter Protected Mode structure

	 public  PGDT_VCP,PIDT_VCP
PGDT_VCP df	 ?		; GDT in VCPI area
PIDT_VCP df	 ?		; IDT in VCPI area

endif				; IF @OEM_VCPI

	 public  PGDT_LHI,PIDT_LHI
PGDT_LHI DTR_STR <>		; Pointer to GDT in ext linear memory
PIDT_LHI DTR_STR <8*256-1,>	; ...	     IDT ...

	 public  CON1KB,CON4KB,CON8KB,CON16KB,CON64KB,CON128KB,CON256KB
	 public  CON1MB,CON10FFF0,CON1P1MB,CON4MB,CON16MB,CON4GB
	 align	 4		; Ensure dword alignment
CON1KB	 dd	 00000400h	;   1KB as a dword in bytes
CON4KB	 dd	 00001000h	;   4KB ...
CON8KB	 dd	 00002000h	;   8KB ...
CON16KB  dd	 00004000h	;  16KB ...
CON64KB  dd	 00010000h	;  64KB ...
CON128KB dd	 00020000h	; 128KB ...
CON256KB dd	 00040000h	; 256KB ...
CON1MB	 dd	 00100000h	;   1MB ...
CON10FFF0 dd	 0010FFF0h	;   Length of DOS memory: 0:0 to FFFF:FFFF
CON1P1MB dd	 00110000h	; 1.1MB ...
CON4MB	 dd	 00400000h	;   4MB ...
CON16MB  dd	 01000000h	;  16MB ...
CON4GB	 dd	 00000000h	;   4GB ...

	 public  PVMTSS,PCURTSS,PPRMTSS,PIOBIT
PVMTSS	 dd	 ?		; Offset in PGROUP of 1st TSS
PCURTSS  dd	 ?		; ...		      current TSS
PPRMTSS  dd	 ?		; ...		      primary TSS
PIOBIT	 dd	 ?		; ...		      I/O bit permission map

if @OEM_EMS
	 public  EMS_START,EMS_END
EMS_START dd	 ?		; Starting EMS memory linear address
EMS_END   dd	 ?		; Ending ...
endif				; IF @OEM_EMS

	 public  MINBASE,RSVBASE,LOWBASE,OVRBASE
	 public  MAPBASE,TOPBASE,LMLBASE
	 public  CNVBASE,EXTBASE
MINBASE  dd	 ?		; Start of our entire reserved area
RSVBASE  dd	 ?		; Start of reserved from swapping region
LOWBASE  dd	 ?		; Start of DOS low  memory in extended memory
OVRBASE  dd	 ?		; Start of DOS high memory in extended memory
MAPBASE  dd	 ?		; Start of map region
TOPBASE  dd	 ?		; Top of extended memory
LMLBASE  dd	 ?		; Start of low memory load
CNVBASE  dd	 ?		; Start of CNV entries
EXTBASE  dd	 00110000h	; Start of extended memory

if @OEM_EMS
	 public  EMMBASE
EMMBASE  dd	 ?		; Start of expanded memory in extended memory
endif				; IF @OEM_EMS

if @OEM_DPMI
	 public  IGRBASE, IGRSIZE
IGRBASE  dd	 ?		; Start of IGROUP code/data
IGRSIZE  dd	 ?		; Size	of IGROUP code/data
endif				; IF @OEM_DPMI

	 public  PPDTRSV
	 public  PPDTLOW,PPDTOVR,PPDTPRG,PPDTMAP,PPDTLML
	 public  PPDTCNV,PPDTCNVZ,PPDTBACK,PPDT1MB,PPDT1P1MB,PPDTSCR
	 public  PPDTVID,PPDTUNW,PPDTUNWZ,PPDTMISS,PPDTPDIR
	 public  PPDT1W1MB
if @OEM_EMS
	 public  PPDTFRM,PPDTFRMZ,PPDTEMM,PPDTEMMZ
PPDTFRM  dd	 ?		; Pointer to start of PTE for EMS frame
PPDTFRMZ dd	 ?		; Pointer to end+1 of PTE for EMS frame
PPDTEMM  dd	 ?		; Offset of EMMBASE in PDT
PPDTEMMZ dd	 ?		; Offset of EMMBASE end in PDT
endif				; IF @OEM_EMS
PPDTRSV  dd	 ?		; Offset of RSVBASE in PDT
PPDTLOW  dd	 ?		; Offset of LOWBASE in PDT
PPDTOVR  dd	 ?		; Offset of OVRBASE in PDT
PPDTPRG  dd	 ?		; Offset of PRGBASE in PDT
PPDTMAP  dd	 ?		; Offset of MAPBASE in PDT
PPDTLML  dd	 ?		; Offset of LMLBASE in PDT
PPDTCNV  dd	 ?		; Offset of start of conventional entries in PDT
PPDTCNVZ dd	 ?		; Offset of end   ...
PPDTBACK dd	 ?		; Offset of end of backfill entries in CNV memory
PPDT1MB  dd	 ?		; Offset of 1MB in PDT
PPDT1P1MB dd	 ?		; Offset of 1.1MB in PDT
PPDT1W1MB dd	 ?		; Offset of 1.1/1.11MB in PDT
PPDTSCR  dd	 ?		; Offset of SCREEN in PDT
PPDTVID  dd	 ?		; Offset of video memory in PDT
PPDTUNW  dd	 ?		; Offset of pseudo-1MB unwrap in PDT
PPDTUNWZ dd	 ?		; Offset of pseudo-1MB unwrap end in PDT
PPDTMISS dd	 ?		; Offset of missing PTE for FIND_PTE in PDT
PPDTPDIR dd	 ?		; Offset of PDIR PTE for EMM_ALTMAPREG1

	 public  PPDTBBMSRC,PPDTBBMDST
PPDTBBMSRC dd	 ?		; Offset of BIOS block move source
PPDTBBMDST dd	 ?		; Offset of BIOS block move destin

	public	PPDTPnPBIOS
PPDTPnPBIOS dd	?		; Offset of PnP BIOS in extended memory

if @OEM_SYS eq @OEMSYS_RET
	 public  PPDTPSM
PPDTPSM  dd	 ?		; Offset of Periscope memory in PDT
endif				; IF @OEM_SYS eq @OEMSYS_RET

if @OEM_XMS
	 public  PPDTCVD
PPDTCVD  dd	 ?		; Offset of CHECK_VDISK pseudo-1MB PTE
endif				; IF @OEM_XMS

	 public  UNWCNT
UNWCNT	 dw	 ?		; # PTEs in pseudo-1MB unwrap region
				; (always a multiple of 4)

if @OEM_DMA
	 public  PPDTDMA,PPDTDMAZ,PPDTD2M,PPDTDMAP
PPDTDMA  dd	 ?		; Offset of DMA buffer start in PDT
PPDTDMAZ dd	 ?		; Offset of DMA buffer end ...
PPDTD2M  dd	 ?		; Offsets of device-to-memory PTEs
PPDTDMAP dd	 ?		; Offset of DMA physical buffer start in PDT
endif				; IF @OEM_DMA

if @OEM_EMS
	 public  FRAME,CONTEXTS
FRAME	 dw	 0E000h 	; Default frame (as segment #)
CONTEXTS dw	 0		; Default # contexts for Alt Map Reg Sets (AMRS)
endif				; IF @OEM_EMS

	 public  SEL_GDT
SEL_GDT  dw	 DTE_SS 	; PGROUP data selector for the active GDT

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_IN2_ECODE
@QMAX_IN2_ECODE:		; Mark module start in .MAP file

if @OEM_DEBUG
	 extrn	 INT01:near
	 extrn	 INT03:near
endif				; IF @OEM_DEBUG
	 extrn	 INT02:near
	 extrn	 INT06:near
	 extrn	 INT07:near
	 extrn	 INT09:near
	 extrn	 INT0A:near
	 extrn	 INT0B:near
	 extrn	 INT0C:near
	 extrn	 INT0D:near
	 extrn	 INT0E:near
	 extrn	 INT0F:near

if @OEM_HIFILL
	 extrn	 INT21:near
endif				; IF @OEM_HIFILL
if @OEM_XMS
	 extrn	 INT2F:near
endif				; IF @OEM_XMS
if @OEM_DPMI
	 extrn	 INT08:near
	 extrn	 INT10:near
endif				; IF @OEM_DPMI
if @OEM_EMS
	 extrn	 INT67:near
endif				; IF @OEM_EMS
	 extrn	 INT70:near
	 extrn	 INT71:near
	 extrn	 INT72:near
	 extrn	 INT73:near
	 extrn	 INT74:near
	 extrn	 INT75:near
	 extrn	 INT76:near
	 extrn	 INT77:near

	 extrn	 INTFF:near

if @OEM_VCPI
if @VCP_OLD
	 extrn	 INTFE:near
endif				; IF @VCP_OLD
	 extrn	 PMVCPI0C_NEXT:near
endif				; IF @OEM_VCPI

	 NPPROC  MOVE_DB -- Move Bytes
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVE_DB_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
MOVE_DB_SRC dw	 ?		; Source DTE
MOVE_DB_DST dw	 ?		; Dest	 DTE

MOVE_DB_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,esi,edi,ds,es> ; Save registers

	 mov	 ds,[ebp].MOVE_DB_SRC ; Get source DTE
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 es,[ebp].MOVE_DB_DST ; Get dest DTE
	 assume  es:nothing	; Tell the assembler about it

	 xor	 esi,esi	; Zero source offset
	 xor	 edi,edi	; Zero destination offset

	 cld			; Ensure string ops forwardly

	 push	 ecx		; Save for a moment
	 shr	 ecx,2-0	; Convert from bytes to dwords
S32  rep movs	 <es:[edi].EDD,ds:[esi].EDD> ; Move arbitrary dwords
	 pop	 ecx		; Restore

	 and	 ecx,11b	; Isolate low-order two bits

S32  rep movs	 <es:[edi].LO,ds:[esi].LO> ; Move arbitrary bytes

	 REGREST <es,ds,edi,esi,ecx> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 2*2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVE_DB  endp			; End MOVE_DB procedure
	 NPPROC  SET_GDT -- Set Global Descriptor Table
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the global or local descriptor table to base EAX.

Note that this routine must execute in BOTH real and protected modes.

Also, because the LDT might not be addressable within 64KB
of the start of PGROUP, we can't use this routine to set an
LDT entry from real mode.

We can't afford to allow the GDT/LDT to be partially changed,
so we disable interrupts during changes.

On entry:

EAX	 =	 segment base

|

SET_GDT_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
SET_GDT_DTE dw	 ?		; DTE to set
SET_GDT_ARB db	 ?		; Access rights byte
SET_GDT_FLG db	 ?		; DTE flags
SET_GDT_LEN dd	 ?		; Segment length

SET_GDT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,ds>	; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 smsw	 bx		; Get machine status word

	 test	 bx,mask $PE	; Check protection bit
	 jz	 short SET_GDT_REAL ; Jump if we're in real mode

	 mov	 bx,SEL_GDT	; Get data selector for the GDT

	 jmp	 short SET_GDT_COM ; Join common code

SET_GDT_REAL:
	 mov	 bx,cs		; Get real mode data segment
SET_GDT_COM:
	 mov	 ds,bx		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ecx,[ebp].SET_GDT_LEN ; Get segment length
	 dec	 ecx		; Convert from length to limit

	 cmp	 ecx,CON1MB	; Check against limit limit
	 jb	 short @F	; Jump if within range

	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 or	 [ebp].SET_GDT_FLG,mask $DTE_G ; Set G-bit
@@:
	 movzx	 ebx,[ebp].SET_GDT_DTE ; Get the DTE to set
	 and	 bx,not (mask $PL) ; Clear the PL bits
if @OEM_DPMI
	 btr	 bx,$TI 	; Check and reset the table index bit
	 jnc	 short SET_GDT1 ; Jump if it's in the GDT

	 push	 eax		; Save for a moment

	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS
	 add	 ebx,PGROUP:[eax].DPTSS_LaLDT ; Plus linear address of DPMI LDT

	 mov	 ds,SEL_4GB3	; Get all memory data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 pop	 eax		; Restore

	 jmp	 short SET_GDT2 ; Join common code

SET_GDT1:
endif				; IF @OEM_DPMI
	 lea	 ebx,DESC_TAB[bx] ; DS:EBX ==> descriptor table to set
SET_GDT2:
	 assume  ds:nothing	; Tell the assembler about it

; Because DS can point to either PGROUP or AGROUP,
; we remove the ASSUME on it to avoid mistakes.

	 mov	 ds:[ebx].DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 ds:[ebx].DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 ds:[ebx].DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 or	 cl,[ebp].SET_GDT_FLG ; Include any flags
	 mov	 ds:[ebx].DESC_SEGLM1,cl ; Save as data limit
;;;;;;;; ror	 ecx,16 	; Swap back

; Set access rights byte

	 mov	 cl,[ebp].SET_GDT_ARB ; Get it
	 mov	 ds:[ebx].DESC_ACCESS,cl ; Set it

	 popf			; Restore flags

	 REGREST <ds,ecx,ebx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 (2*2)+(1*4)	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_GDT  endp			; End SET_GDT procedure
	 FPPROC  FSET_GDT -- Set GDT Entry
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to SET_GDT

On entry:

Same as for SET_GDT

On exit:

Same as for SET_GDT

|

FSET_GDT_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; Caller's CS:IP
FSET_GDT_DTE dw  ?		; DTE to set
FSET_GDT_ARB db  ?		; Access rights byte
FSET_GDT_FLG db  ?		; DTE flags
FSET_GDT_LEN dd  ?		; Segment length

FSET_GDT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 push	 [ebp].FSET_GDT_LEN ; Pass length parameter
	 push	 [ebp].FSET_GDT_ARB.ELO ; Pass ARB & flag parameters
	 push	 [ebp].FSET_GDT_DTE ; Pass DTE to set parameter
	 call	 SET_GDT	; Set the GDT to EAX base

	 pop	 ebp		; Restore

	 ret	 2*2+1*4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FSET_GDT endp			; End FSET_GDT procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment


ZDATA	 segment use16 para public 'zdata' ; Start ZDATA segment
	 assume  ds:PGROUP

	 extrn	 ZLDATA:byte

ZDATA	 ends			; End ZDATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

	 extrn	 ENDADDR:word

	 extrn	 TIDT_DESC:qword
	 extrn	 TIDT_DESC_LEN:abs
	 extrn	 PIDT_LLO:fword

	 extrn	 PGDT_PHI:fword
	 extrn	 PIDT_PHI:fword

	 public  LaLO
LaLO	 dd	 ?		; Linear address of low memory

	 public  MOVE_TAB
MOVE_TAB MDTE_STR <>		; Move block descriptor tables

	 public  TDESC_TAB
TDESC_TAB TDTE_STR <>		; Timing memory descriptor tables

	 public  ERR_CODE,ERR_FLAG
	 public  ERR_CODE_ADDR,ERR_CODE_VAL
ERR_CODE_ADDR dd ?		; Physical address of destination
ERR_CODE_VAL  dw ?		; Matching word count (for cmps)
ERR_CODE db	 ?		; Error code
ERR_FLAG db	 0		; Error flags

	 public  @ERR_MOV,@ERR_PRO,@ERR_TIM
@ERR_MOV equ	 80h		; Unable to move data to extended memory
@ERR_PRO equ	 40h		; Unable to enter protected mode
@ERR_TIM equ	 20h		; Unable to time protected mode

NDATA	 ends			; End NDATA segment


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
	 assume  cs:IGROUP

	 extrn	 INT15:near

LCODE	 ends			; End LCODE segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 extrn	 INT12:near
	 extrn	 INT81:near
	 extrn	 INT82:near
	 extrn	 INT83:near
	 extrn	 INT84:near
if @OEM_VDS
	 extrn	 INT4B:near
endif				; IF @OEM_VDS

JCODE	 ends			; End JCODE segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

if @OEM_DPMI
	 extrn	 INT00:near
	 extrn	 INT04:near
	 extrn	 INT05:near
	 extrn	 INT11:near
if @OEM_VIRTUALMEM
	 extrn	 INT1C:near
	 extrn	 INT23:near
	 extrn	 INT24:near
endif				; IF @OEM_VIRTUALMEM
	 extrn	 INT20:near
	 extrn	 INT25:near
	 extrn	 INT26:near
	 extrn	 INT27:near
	 extrn	 INT31:near
	 extrn	 INT33:near
	 extrn	 INT41:near
	 extrn	 INT68:near
%	 extrn	 INT&@PMI_INT:near
%	 extrn	 INT&@PMF_INT:near
%	 extrn	 INT&@PMM_INT:near
	 extrn	 DPMIFN_VSAPI:near
	 extrn	 PMIDEF_LEN:abs
	 extrn	 PMIDEF:near
endif				; IF @OEM_DPMI

ICODE	 ends			; End ICODE segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 extrn	 YMSGOUT2:near

	 public  @QMAX_IN2_XCODE
@QMAX_IN2_XCODE:		; Mark module start in .MAP file

	 NPPROC  SET_CG -- Set GDT With Call Gate
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the global descriptor table with a call gate.

Note that this routine executes in real mode only.

|

SET_CG_STR struc

	 dw	 ?		; Caller's EBP
	 dw	 ?		; Caller's IP
SET_CG_DTE dw	 ?		; DTE to set
SET_CG_ARB db	 ?		; Access rights byte
SET_CG_CNT db	 ?		; Parameter count
SET_CG_FVEC df	 ?		; Code Sel:Off

SET_CG_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,bx>	; Save registers

	 mov	 bx,[bp].SET_CG_DTE ; Get the DTE to set
	 and	 bx,not (mask $PL) ; Clear the PL bits

; The code selector goes into BASE01

	 mov	 ax,[bp].SET_CG_FVEC.FSEL ; Get it
	 mov	 DESC_TAB.DESC_BASE01[bx],ax ; Save it

; The offset goes into SEGLM0, SEGLM1, BASE3

	 mov	 eax,[bp].SET_CG_FVEC.FOFF ; Get the offset
	 mov	 DESC_TAB.DESC_SEGLM0[bx],ax ; Save bytes 0-1
	 shr	 eax,16 	; Shift down the high-order word
	 mov	 DESC_TAB.DESC_SEGLM1[bx],al ; Save byte 2
	 mov	 DESC_TAB.DESC_BASE3[bx],ah ; Save byte 3

; The parameter count goes into BASE2

	 mov	 al,[bp].SET_CG_CNT ; Get it
	 mov	 DESC_TAB.DESC_BASE2[bx],al ; Save it

; The A/R word goes into ACCESS

	 mov	 al,[bp].SET_CG_ARB ; Get it
	 mov	 DESC_TAB.DESC_ACCESS[bx],al ; Save it

	 REGREST <bx,eax>	; Restore

	 pop	 bp		; Restore

	 ret	 2+1+1+6	; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_CG	 endp			; End SET_CG procedure
	 FPPROC  FMT_ERR_CODE -- Format Error Code
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format the error code.

On entry:

AL	 =	 error code
YGROUP:SI ==>	 high-order hex digit of save area

|

	 REGSAVE <ax,bx,es>	; Save registers

	 push	 seg YGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:YGROUP	; Tell the assembler about it

	 mov	 ah,0		; Zero to use as word
	 shl	 ax,4		; Split apart the hex digits
	 shr	 al,4
	 lea	 bx,HEXTABLE	; BX ==> hex to ASCII table
	 xlat	 HEXTABLE	; Translate low-order digit
	 mov	 YGROUP:[si].HI,al ; Save in message
	 mov	 al,ah		; Get high-order digit
	 xlat	 HEXTABLE	; Translate high-order digit
	 mov	 YGROUP:[si].LO,al ; Save in message

	 REGREST <es,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_ERR_CODE endp		; End FMT_ERR_CODE procedure
	 FPPROC  FMT_WORD_YGRP -- Format word into YGROUP message
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format AX => YGROUP:DI as 4 hex digits

On entry:
AX	  =	Value to be formatted
YGROUP:DI ==>	High-order hex digit of save area

On exit:
DI	=	advanced past output area

|

	 REGSAVE <ax,bx,cx,dx,es> ; Save registers

	 push	 seg YGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:YGROUP	; Tell the assembler about it

	 lea	  bx,HEXTABLE	; DS:BX ==> translate table
	 mov	  cx,4		; # hex digits in a word
	 mov	  dx,ax 	; Move value to more permanent register
FMT_WORD1:
	 rol	  dx,4		; Copy the high-order digit
	 mov	  al,dl 	; Copy to XLAT register
	 and	  al,0Fh	; Isolate hex digit
	 xlat	  HEXTABLE	; Translate to ASCII
S16	 stos	 YGROUP:[di].LO ; Save into output area

	 loop	  FMT_WORD1	; Jump if more digits to convert

	 REGREST <es,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_WORD_YGRP endp		; End FMT_WORD_YGRP procedure
if @OEM_VCPI
	 FPPROC  SETUP_EPM -- Setup EPMTAB
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup EPMTAB values

|

	 REGSAVE <eax>		; Save register

	 lea	 eax,PGDT_VCP	; Get offset of GDT in VCPI memory
	 add	 eax,VCPIBASE	; Plus our VCPI base
	 mov	 EPMTAB.EPM_GDTP,eax ; Save as linear adress of GDT ptr

	 lea	 eax,PIDT_VCP	; Get offset of IDT in VCPI memory
	 add	 eax,VCPIBASE	; Plus our VCPI base
	 mov	 EPMTAB.EPM_IDTP,eax ; Save as linear adress of IDT ptr

; If we're supplying DPMI services, the TR in EPMTAB may vary
; so it's set in QMAX_VCP each time.  If we're not supplying
; DPMI services, we set it here

if @OEM_DPMI
	 mov	 EPMTAB.EPM_LDTR,DTE_DPMILDT ; Save as our LDT
else
	 mov	 EPMTAB.EPM_TR,DTE_TSS ; Save as our TR
	 mov	 EPMTAB.EPM_LDTR,0 ; Zero our LDT
endif				; IF @OEM_DPMI
	 mov	 EPMTAB.EPM_EXIT.FSEL,DTE_VCOD ; Save VCPI code selector
	 mov	 EPMTAB.EPM_EXIT.FOFF,offset PGROUP:PMVCPI0C_NEXT ; ... offset

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_EPM endp			; End SETUP_EPM procedure
endif				; IF @OEM_VCPI
	 FPPROC  SET_LOWMEM -- Setup Low Memory Descriptor Tables
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save low memory values in case we exit on error code.

Setup low memory descriptor tables in case of error return.
In this case, we need to enter protected mode in order to
reset the master 8259 interrupt base.

|

	 push	 eax		; Save register

; Save master and slave interrupt masks to restore later

	 in	 al,@IMR	; Get master interrupt settings
	 mov	 INTA01,al	; Save to restore later

	 in	 al,@IMR2	; Get slave interrupt settings
	 mov	 INTB01,al	; Save to restore later

; Save original screen mode

	 VIDCALL @GETINF	; Get video information
	 and	 al,not 80h	; Isolate mode bits
	 mov	 VIDMODE,al	; Save for later use

; Setup TIME_ALLMEM global descriptor table

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,seg PGROUP	; Copy segment of low linear addresses
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 LaLO,eax	; Save for later use

	 mov	 TDESC_TAB.TDTE_CS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 TDESC_TAB.TDTE_CS.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 TDESC_TAB.TDTE_CS.DESC_SEGLM0,0FFFFh ; 64KB of code
	 mov	 TDESC_TAB.TDTE_CS.DESC_SEGLM1,0
	 mov	 TDESC_TAB.TDTE_CS.DESC_ACCESS,CPL0_CODE

	 mov	 TDESC_TAB.TDTE_DS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 TDESC_TAB.TDTE_DS.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 TDESC_TAB.TDTE_DS.DESC_SEGLM0,0FFFFh ; 64KB of data
	 mov	 TDESC_TAB.TDTE_DS.DESC_SEGLM1,0
	 mov	 TDESC_TAB.TDTE_DS.DESC_ACCESS,CPL0_DATA

; Note that we're depending upon the TDTE_SS selector being
; in one-to-one memory and 64KB in length

	 mov	 TDESC_TAB.TDTE_SS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 TDESC_TAB.TDTE_SS.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 TDESC_TAB.TDTE_SS.DESC_SEGLM0,0FFFFh ; 64KB of stack
	 mov	 TDESC_TAB.TDTE_SS.DESC_SEGLM1,0
	 mov	 TDESC_TAB.TDTE_SS.DESC_ACCESS,CPL0_DATA

; Setup all memory selector

	 xor	 eax,eax	; Base address is 0

	 mov	 TDESC_TAB.TDTE_D4GB.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 TDESC_TAB.TDTE_D4GB.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 TDESC_TAB.TDTE_D4GB.DESC_SEGLM0,0FFFFh ; 4GB of data
	 mov	 TDESC_TAB.TDTE_D4GB.DESC_SEGLM1,(mask $DTE_G) or (0Fh shl $SEGLM1)
	 mov	 TDESC_TAB.TDTE_D4GB.DESC_ACCESS,CPL0_DATA

; Compute the 24-bit address of TDESC_TAB for GDT for use by BIOS

	 lea	 eax,TDESC_TAB	; Include offset
	 add	 eax,LaLO	; Plus low memory linear address

	 mov	 TDESC_TAB.TDTE_GDT.DTR_BASE,eax
	 mov	 TDESC_TAB.TDTE_GDT.DTR_LIM,(size TDTE_STR)-1 ; Save GDT limit

; Handle errors in TIME_ALLMEM upon interruption

	 lea	 eax,TIDT_DESC	; Include offset
	 add	 eax,LaLO	; Plus low memory linear address

	 mov	 TDESC_TAB.TDTE_IDT.DTR_BASE,eax
	 mov	 TDESC_TAB.TDTE_IDT.DTR_LIM,TIDT_DESC_LEN-1 ; Save IDT limit

; Mark dummy GDT entry as data so we can check for CR3/A31 bug

	 mov	 TDESC_TAB.TDTE_DUMMY.DESC_ACCESS,CPL0_DATA ; Mark as data

	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_LOWMEM endp 		; End SET_LOWMEM procedure
	 FPPROC  PROT_INIT -- Protected Mode Initialization Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Setup 386 TSS
* Move	386 TSS to high memory
* Setup IDT
* Move	IDT to high memory
* Setup GDT
* Move	GDT to high memory
* Setup exception handlers for all interrupts
* Move interrupt routines to high end of extended memory
* IRET to original task and set VM flag bit in the process

|

	 pushad 		; Save all registers
				; N.B.:  Do not follow with [EAX+???*?]

	 REGSAVE <ds,es>	; Segment registers, too

	 push	 seg PGROUP	; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 seg PGROUP	; Setup ES for INT 15h call
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

; Setup selector for BIOS data area

	 movzx	 eax,SBIOSDATA	; Get segment of BIOS data area
	 shl	 eax,4-0	; Convert from paras to bytes

	 push	 dword ptr 300h ; Pass segment length
	 push	 CPL0_DATA or (@DPMI_CPL shl $DT_DPL) ; Pass access rights byte
	 push	 DTE_BDA	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Setup low and high linear addresses and high physical address

	 movzx	 ecx,ENDADDR	; Get ending offset in bytes

	 mov	 eax,LaLO	; Use low memory linear address
	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_DSHI	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Setup DTE_CSLO and DTE_DSLO for when we return from entering protected mode
; The code selector *MUST* be 64KB in length
; The stack selector *MUST* be 64KB in length, byte granular, expand up,
; writable, and present as it is used to initialize all segment registers
; before entering real mode.

	 mov	 eax,LaLO	; Use low memory linear address
	 mov	 ecx,CON64KB	; 64KB of code
	 push	 ecx		; Pass segment length
	 push	 CPL0_CODE or CPL0 ; Pass access rights byte
	 push	 DTE_CSLO	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_D64K	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

if @OEM_WIN3
	 test	 CM3_FLAG,@CM3_NOWIN3 ; Disable support for Windows 3?
	 jnz	 short @F	; Jump if so

	 lea	 ecx,WIN3_END	; Get end of Windows 3 data area
@@:
endif				; IF @OEM_WIN3
	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_DSLO	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

	 movzx	 ecx,PRGSIZE	; Get size of PRG in 1KB
	 shl	 ecx,10-0	; Convert from 1KB to bytes

	 mov	 eax,PaPRGBASE	; Use physical address
	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_DSXP	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Setup low memory skeleton GDT for STATE_PM

	 lea	 eax,LOWGDT	; EAX ==> low memory GDT
	 add	 eax,LaLO	; Plus low memory linear address

	 mov	 LOWGDT.LOWDTE_GDT.DTR_BASE,eax
	 mov	 LOWGDT.LOWDTE_GDT.DTR_LIM,(size LOWGDT_STR)-1 ; Save GDT limit

	 mov	 eax,PRGBASE	; Use linear address
	 movzx	 ecx,PRGSIZE	; Get size of PRG in 1KB
	 shl	 ecx,10-0	; Convert from 1KB to bytes
	 dec	 ecx		; Convert from length to limit

	 cmp	 ecx,CON1MB	; Check against limit limit
	 jb	 short @F	; Jump if within range

	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 or	 ecx,(mask $DTE_G) shl (8*(DESC_SEGLM1-DESC_BASE2)) ; Set G-bit
@@:
	 mov	 LOWGDT.LOWDTE_CSLHI.DESC_BASE01.EDD,eax ; Save base bytes 0-2
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 LOWGDT.LOWDTE_CSLHI.DESC_BASE3,al ; Save as base byte #3
;;;;;;;; ror	 eax,8		; Rotate back
	 mov	 LOWGDT.LOWDTE_CSLHI.DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 LOWGDT.LOWDTE_CSLHI.DESC_SEGLM1,cl ; Save as data limit
;;;;;;;; ror	 ecx,16 	; Swap back
	 mov	 LOWGDT.LOWDTE_CSLHI.DESC_ACCESS,CPL0_CODE or CPL0 ; Set it

; Fill in DTE_CR3 with its physical address

	 mov	 eax,LaCR3	; Get linear address of first level dirs
	 sub	 eax,PRGBASE	; Less linear address of PRG
	 add	 eax,PaPRGBASE	; Plus physical ...

	 push	 PDTLEN 	; Pass size of segment
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_CR3	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Fill in DTE_PDT with its physical address

	 mov	 eax,LaDIR2	; Get linear address of second level dirs
	 sub	 eax,PRGBASE	; Less linear address of PRG
	 add	 eax,PaPRGBASE	; Plus physical ...

	 push	 PDTLEN 	; Pass size of segment
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_PDT	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Setup 386 TSSs

	 mov	 eax,PVMTSS	; Get offset in PGROUP of 1st TSS
	 add	 eax,PRGBASE	; Get offset of 1st TSS as linear address

	 mov	 cx,@TSS_MAX	; Get # TSSs we have
	 mov	 bx,DTE_TSS	; Get 1st TSS selector
@@:
	 mov	 edx,PIOBIT	; Get offset in PGROUP of I/O bit map
	 add	 edx,PRGBASE	; Get offset of I/O bit map as linear address
	 add	 edx,@IOMAP+1	; Plus size of the map (including term byte)
	 sub	 edx,eax	; Less base address to get length

	 push	 edx		; Pass segment length
	 push	 CPL0_IDLE3 or CPL0 ; Pass access rights byte
	 push	 bx		; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

	 add	 eax,type DPTSS_STR ; Skip to next TSS
	 add	 bx,2*(type DESC_STR) ; Skip over LDT selector to next TSS selector

	 loop	 @B		; Jump if more TSS descriptors to initialize

; Save linear address of IGROUP code/data

	 mov	 eax,IGRBASE	; Get linear address of IGROUP
	 mov	 ebx,IGRSIZE	; Get size of IGROUP
	 push	 ebx		; Pass size of area in bytes
	 push	 CPL0_CODE or CPL0 ; Pass access rights byte
	 push	 DTE_CSIG	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; So we can address dynamic data from IGROUP, use a selector
; limit for DTE_DSIG to the end of PGROUP.  The actual limit
; is (PRGSIZE*1024 + PGRBASE) - IGRBASE.

	 movzx	 ebx,PRGSIZE	; Get size of PRG in 1KB
	 shl	 ebx,10-0	; Convert from 1KB to bytes
	 add	 ebx,PRGBASE	; Plus linear address of PGROUP
				; to get ending linear address
	 sub	 ebx,IGRBASE	; Less linear address of IGROUP
				; to get length from start of IGROUP
	 push	 ebx		; Pass size of area in bytes
	 push	 CPL0_DATA or (@DPMI_CPL shl $DT_DPL) ; Pass access rights byte
	 push	 DTE_DSIG	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Save linear address of FGROUP data

	 mov	 eax,FGRBASE	; Get linear address of FGROUP
	 mov	 ebx,FGRSIZE	; Get size of FGROUP
	 push	 ebx		; Pass size of area in bytes
	 push	 CPL0_DATA or (@DPMI_CPL shl $DT_DPL) ; Pass access rights byte
	 push	 DTE_FIXUP	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Save linear address of JGROUP code/data.  Note that only the JGROUP data
; selector includes DLGROUP in its limit.

	 mov	 eax,JGRBASE	; Get linear address of JGROUP
	 mov	 ebx,JGRSIZE	; Get size of JGROUP
	 push	 ebx		; Pass size of area in bytes
	 push	 CPL0_CODE or CPL0 ; Pass access rights byte
	 push	 DTE_CSJG	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

	 mov	 ebx,JGRDSIZE	; Get size of JGROUP including DLGROUP
	 push	 ebx		; Pass size of area in bytes
	 push	 CPL0_DATA or (@DPMI_CPL shl $DT_DPL) ; Pass access rights byte
	 push	 DTE_DSJG	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Save linear address of DPMI LDT

	 mov	 eax,PDPMILDT	; Get the offset in PGROUP of the LDT
	 add	 eax,PRGBASE	; Convert from offset to linear address
	 mov	 ebx,1		; Assume not present or disabled
if @OEM_DPMI
	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 short @F	; Jump if so

	 mov	 ebx,LDT_SIZ	; Get byte size of DPMI LDT (/8)
@@:
endif				; IF @OEM_DPMI

	 push	 ebx		; Pass size of area in bytes
	 push	 CPL0_LDT or CPL0 ; Pass access rights byte
	 push	 DTE_DPMILDT	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

if @OEM_DPMI

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 near ptr PROT_INIT_XDPMI ; Jump if so

; Save DPMI default interrupt handlers

	 xor	 ebx,ebx	; Zero to use as dword
	 mov	 bx,PMIDEF_LEN	; Get length of the default interrupt handlers

	 mov	 eax,IGRBASE	; Get linear address of IGROUP
	 add	 eax,offset IGROUP:PMIDEF ; Plus offset of default handler

	 push	 ebx		; Pass size of area in bytes
	 push	 CPL0_CODE or (@DPMI_CPL shl $DT_DPL) ; Pass access rights byte
	 push	 DTE_DPMIDEF	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Save DPMI Vendor-Specific API entry call gate

	 lea	 eax,IGROUP:DPMIFN_VSAPI ; Get the offset
	 push	 DTE_CSIG	; Pass code selector
	 push	 eax		; Pass offset
	 push	 ((@VSAPI_DDSTKSIZE+2) shl 8) or CPL0_CALL3 or (@DPMI_CPL shl $DT_DPL)
				; Pass access, rights byte,
				; parm count = @VSAPI_DDSTKSIZE+2
	 push	 DTE_DPMI_VSAPI ; Pass descriptor to set
	 call	 SET_CG 	; Set the GDT to a call gate

; Save limits and A/R byet for swapfile DTE

	 xor	 eax,eax	; The actual base address changes with each swap
	 push	 dword ptr @PageSize ; Pass size of area in bytes
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_SWAPBUF	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base
PROT_INIT_XDPMI:
endif				; IF @OEM_DPMI

; Compute the 24-bit address of IDT_DESC for GDT for use by BIOS
; Note that this address cannot exceed 24-bits as the BIOS call
; to enter protected mode won't load the high-order byte

	 lea	 eax,IDT_DESC	; EAX ==> Interrupt descriptor table
	 add	 eax,PRGBASE	; Plus linear address of ext memory
	 mov	 PIDT_LHI.DTR_BASE,eax

	 lea	 eax,IDT_DESC	; EAX ==> Interrupt descriptor table
	 add	 eax,PaPRGBASE	; Plus physical address of ext memory
	 mov	 PIDT_PHI.DTR_BASE,eax

	 lea	 eax,IDT_DESC	; EAX ==> Interrupt descriptor table
	 add	 eax,LaLO	; Plus linear address of low memory
	 mov	 PIDT_LLO.DTR_BASE,eax
	 mov	 DESC_TAB.DTE_IDT.DTR_BASE,eax
	 mov	 DESC_TAB.DTE_IDT.DTR_LIM,IDT_DESC_LEN-1 ; Save IDT limit

SETIDT	 macro	 NN,DTE,ARB
ifnb <DTE>
	 mov	 IDT_DESC.IDT_OFFLO[0&NN&h*type IDT_STR],offset DTE&GROUP:INT&NN
	 mov	 IDT_DESC.IDT_SELECT[0&NN&h*type IDT_STR],DTE_CS&DTE&G
else
	 mov	 IDT_DESC.IDT_OFFLO[0&NN&h*type IDT_STR],offset PGROUP:INT&NN
endif				; IFNB
ifnb <ARB>
	 mov	 IDT_DESC.IDT_ACCESS[0&NN&h*type IDT_STR],ARB
endif				; IFNB
	 endm			; SETIDT


HWSETIDT macro	 NN,DTE,ARB
	 local	 L1

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DSTK_HWINTS[NN&h/8],1 shl (NN&h mod 8) ; Izit to be intercepted?
	 jz	 short L1	; Jump if not

	 SETIDT  NN,DTE,ARB
L1:
	 endm			; HWSETIDT


; Handle debug and breakpoint exceptions specially

if @OEM_DEBUG
	 SETIDT  01		; Debug exception
	 SETIDT  03		; Breakpoint exception
endif				; IF @OEM_DEBUG

; Handle NMI specially in case it interrupts us

	 SETIDT  02		; NMI

	 SETIDT  06		; Invalid opcode exception (for LOADALL)
	 SETIDT  07		; Coprocessor not available (clear TS)

; Handle error code interrupts specially

	 HWSETIDT 08		; Normal IRQ0 = Double Fault

	 test	 DB2_FLAG,@DB2_X09 ; Trap INT 09h in IDT?
	 jnz	 short @F	; Not this time

	 SETIDT  09		; Normal IRQ1 = Keyboard Hardware Interrupt
@@:
	 HWSETIDT 09		; Normal IRQ1 = Keyboard Hardware Interrupt
	 HWSETIDT 0A		; Normal IRQ2 = Invalid TSS
	 HWSETIDT 0B		; Normal IRQ3 = Segment Not Present
	 SETIDT  0C		; Normal IRQ4 = Stack Fault
	 SETIDT  0D		; Normal IRQ5 = General Protection
	 SETIDT  0E		; Normal IRQ6 = Page Fault
	 HWSETIDT 0F		; Normal IRQ7 = Printer

	 test	 CPUFET_FLAG,mask $CPUFET_MCE ; Is MCE supported?
	 jz	 short @F	; Jump if not

	 SETIDT  12,J		; Machine check for P5
@@:

; Trap INT 15h in IDT, too

	 SETIDT  15,I		; BIOS System Services

if @OEM_HILOAD
	 SETIDT  21		; DOS Functions
endif				; IF @OEM_HILOAD

if @OEM_XMS
	 SETIDT  2F		; XMS interrupt handler
endif				; IF @OEM_XMS

	 HWSETIDT 70		; Normal IRQ8  = Real-Time Clock
	 HWSETIDT 71		; Normal IRQ9  = Redirect Cascade
	 HWSETIDT 72		; Normal IRQ10 = (Reserved)
	 HWSETIDT 73		; Normal IRQ11 = (Reserved)
	 HWSETIDT 74		; Normal IRQ12 = Auxiliary Device (Mouse)
	 HWSETIDT 75		; Normal IRQ13 = Math Coprocessor (Redirect to NMI)
	 HWSETIDT 76		; Normal IRQ14 = Fixed Disk
	 HWSETIDT 77		; Normal IRQ15 = (Reserved)

	 SETIDT  81,J		; In case Lotus 1-2-3 v3.1 is present
	 SETIDT  82,J		; ...
	 SETIDT  83,J		; ...
	 SETIDT  84,J		; ...

if @OEM_DPMI
	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 near ptr PROT_INIT_XDPMI2 ; Jump if so

	 SETIDT  00,I		; Give PM users a crack at it
	 SETIDT  04,I		; ...
	 SETIDT  05,I		; ...
	 SETIDT  08		; Normal IRQ0 = Double Fault
	 SETIDT  0B		; Normal IRQ3 = Segment Not Present
	 SETIDT  10		; Used for BIOS translation
	 SETIDT  11,I		; Alignment check for 486
if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_BSGLOBAL ; Is there a swapfile present?
	 jz	 short @F	; Jump if not

	 SETIDT  1C,I		; Secondary timer tick
	 SETIDT  23,I		; Ignore if paging active
	 SETIDT  24,I		; Fail if paging active
@@:
endif				; IF @OEM_VIRTUALMEM
	 SETIDT  20,I		; Fail if called from PM
	 SETIDT  25,I		; ...
	 SETIDT  26,I		; ...
	 SETIDT  27,I		; ...
	 SETIDT  41,I		; ...
	 SETIDT  68,I		; ...
	 SETIDT  31,I		; DPMI interrupt handler
	 SETIDT  33,I		; Mouse interrupt handler
%	 SETIDT  @PMI_INT,I	; PM Interrupt return
%	 SETIDT  @PMF_INT,I	; PM (and VM) Fault return
%	 SETIDT  @PMM_INT,I	; PM miscellaneous returns
PROT_INIT_XDPMI2:
endif				; IF @OEM_DPMI

if @OEM_VDS
	 SETIDT  4B,J		; VDS services interrupt handler
endif				; IF @OEM_VDS

if @OEM_EMS
	 SETIDT  67		; EMS Services
endif				; IF @OEM_EMS

; Handle old VCPI entry point specially

if @OEM_VCPI and @VCP_OLD
	 SETIDT  FE		; Old VCPI interrupt handler
endif				; IF @OEM_VCPI and @VCP_OLD

; Handle hardware interrupt returns specially

	 SETIDT  FF		; Hardware interrupt return

; Note that the following code *MUST* execute *BEFORE* API loads
; in case we load a 386 emulator and *AFTER* SETIDT 07.

	 mov	 eax,IDT_DESC.EDQLO[07h*(type IDT_DESC)] ; Get low-order dword
	 mov	 INT07DP.EDQLO,eax ; Save for later use

	 mov	 eax,IDT_DESC.EDQHI[07h*(type IDT_DESC)] ; Get high-order dword
	 mov	 INT07DP.EDQHI,eax ; Save for later use

; Setup remainder of GDT

	 movzx	 ecx,PRGSIZE	; Get size of PRG in 1KB
	 shl	 ecx,10-0	; Convert from 1KB to bytes

; Setup GDT descriptor for monitor code when running in extended memory

	 mov	 eax,PaPRGBASE	; Use physical address
	 push	 ecx		; Pass segment length
	 push	 CPL0_CODE or CPL0 ; Pass access rights byte
	 push	 DTE_CS2	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Setup GDT descriptor for monitor data in extended memory
; Note we must set the B bit in this selector to force load of
; all of ESP at the VM86 to PM switch

	 mov	 eax,PaPRGBASE	; Use physical address
	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or CPL0 or ((mask $DTE_B) shl 8); Pass access rights byte
	 push	 DTE_DS 	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base
if @OEM_DPMI
;;;;;;;; mov	 eax,PaPRGBASE	; Use physical address
	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or (@DPMI_CPL shl $DT_DPL) or ((mask $DTE_B) shl 8); Pass access rights byte
	 push	 DTE_DS3	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base
endif				; IF @OEM_DPMI
;;;;;;;; mov	 eax,PaPRGBASE	; Use physical address
	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte (must be CPL0)
	 push	 DTE_ES 	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

if @OEM_VCPI
	 mov	 eax,VCPIBASE	; Use VCPI address
	 push	 ecx		; Pass segment length
	 push	 CPL0_CODE or CPL0 ; Pass access rights byte
	 push	 DTE_VCOD	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

	 mov	 eax,VCPIBASE	; Use VCPI address
	 push	 ecx		; Pass segment length
	 push	 ((mask $DTE_B) shl 8) or CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_VDAT	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Compute the 24-bit address of GDT in VCPI area

	 lea	 eax,DESC_TAB	; Get offset
	 add	 eax,VCPIBASE	; Plus linear address

	 mov	 PGDT_VCP.DTR_BASE,eax
	 mov	 PGDT_VCP.DTR_LIM,(size XDTE_STR)-1 ; Save GDT limit

; Compute the 24-bit address of IDT in VCPI area

	 lea	 eax,IDT_DESC	; Get offset
	 add	 eax,VCPIBASE	; Plus linear address

	 mov	 PIDT_VCP.DTR_BASE,eax
	 mov	 PIDT_VCP.DTR_LIM,IDT_DESC_LEN-1 ; Save IDT limit
endif				; IF @OEM_VCPI

; Compute the 24-bit address of DESC_TAB for GDT in linear extended memory

	 lea	 eax,DESC_TAB	; Get offset
	 add	 eax,PRGBASE	; Plus linear address

	 mov	 PGDT_LHI.DTR_BASE,eax
	 mov	 PGDT_LHI.DTR_LIM,(size XDTE_STR)-1 ; Save GDT limit

; Setup DTE_CS and DTE_SS for when we return from entering protected mode
; The code selector *MUST* be 64KB in length
; The stack selector *MUST* be 64KB in length, byte granular, expand up,
; writable, and present as it is used to initialize all segment registers
; before entering real mode.

	 mov	 eax,LaLO	; Use low memory linear address
	 mov	 ecx,CON64KB	; 64KB of code

; Setup GDT descriptor for monitor code when running in low memory

	 push	 ecx		; Pass segment length
	 push	 CPL0_CODE or CPL0 ; Pass access rights byte
	 push	 DTE_CS 	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Setup GDT descriptor for monitor stack in low memory

	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_SS 	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Setup descriptor for physical extended memory GDT

	 lea	 eax,DESC_TAB	; Include offset
	 add	 eax,PaPRGBASE	; Plus physical extended memory base address

	 mov	 PGDT_PHI.DTR_BASE,eax
	 mov	 PGDT_PHI.DTR_LIM,(size XDTE_STR)-1 ; Save GDT limit

; Setup descriptor to address the all memory as data

	 xor	 eax,eax	; Starting address is 00000000

	 push	 CON4GB 	; Pass size of segment
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_D4GB	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

;;;;;;;; xor	 eax,eax	; Starting address is 00000000

	 push	 CON4GB 	; Pass size of segment
	 push	 CPL0_DATA or (@DPMI_CPL shl $DT_DPL) ; Pass access rights byte
	 push	 DTE_D4GB3	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Setup descriptor to address the video buffer as data

	 mov	 eax,000B0000h	; EAX = linear address of monochrome memory

	 test	 NRD_FLAG,@NRD_MDA ; Monochrome installed?
	 jnz	 short SETSCR_COM ; Yes
				; Fall through to use color/graphics adapter

	 or	 ax,8000h	; EAX = linear address of color/graphics memory
SETSCR_COM:
	 mov	 ecx,32*1024	; 32KB of data

	 push	 ecx		; Pass segment length
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_VID	; Pass descriptor to set
	 call	 FSET_GDT	; Set the GDT to EAX base

; Setup descriptor so we can move everything to high memory

; Source address is PGROUP:0

	 mov	 eax,LaLO	; Use low memory linear address

	 lea	 ecx,ZLDATA[2-1] ; End of static code and data, rounded up
	 and	 cx,not (2-1)	; Round down to even boundary
	 dec	 ecx		; Convert from length to limit

	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM1,cl ; Save size & flags
	 ror	 ecx,16 	; Swap back
	 mov	 MOVE_TAB.MDTE_DS.DESC_ACCESS,CPL0_DATA

; Compute the 24-bit address of DESC_TAB for GDT for use by BIOS
; Note that this address cannot exceed 24-bits as the BIOS call
; to enter protected mode won't load the high-order byte

	 lea	 eax,DESC_TAB	; Include offset
	 add	 eax,LaLO	; Plus low memory linear address

	 mov	 DESC_TAB.DTE_GDT.DTR_BASE,eax
	 mov	 DESC_TAB.DTE_GDT.DTR_LIM,(size XDTE_STR)-1 ; Save GDT limit

; Destination address is PaPRGBASE or PaPRGBASE2 if LML

	 mov	 eax,PaPRGBASE	; Get physical address of program

	 test	 LCL_FLAG,@LCL_LML ; Low memory load?
	 jz	 short @F	; Jump if not

	 mov	 eax,PaPRGBASE2 ; Get secondary physical address of program
@@:
	 mov	 ERR_CODE_ADDR,eax ; Save as destination physical address

	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM1,cl ; Save size & flags
	 ror	 ecx,16 	; Swap back
	 mov	 MOVE_TAB.MDTE_ES.DESC_ACCESS,CPL0_DATA

if @OEM_EMS

; Save lower and upper (inclusive/exclusive) PDT offsets of EMS frame

	 movzx	 eax,FRAME	; Get the frame # (multiple of 4KB in paras)
	 shr	 eax,(12-2)-4	; Convert from paras to 4KB in dwords
	 mov	 PPDTFRM,eax	; Save for later use

	 movzx	 eax,NPHYS16F.ELO ; Get # physical 16KB pages in EMS frame
	 shl	 eax,14-(12-2)	; Convert from 16KB to 4KB in dwords
	 add	 eax,PPDTFRM	; Add in base pointer
	 mov	 PPDTFRMZ,eax	; Save as offset of end+1 of EMS frame

; Save lower and upper (inclusive/exclusive) linear addresses of EMS frame

	 movzx	 eax,FRAME	; Get the frame #
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 EMS_START,eax	; Save as starting address
	 add	 eax,CON64KB	; Plus 10000h bytes
	 mov	 EMS_END,eax	; Save as ending address
endif				; IF @OEM_EMS

; Save lower limit of video memory in PDT

	 mov	 eax,LOWOFF	; Get size of low DOS memory (multiple of 4KB in 1KB)
	 movzx	 ebx,LOWSIZE	; Get amount of added low DOS memory (multiple of 4KB in 1KB)
	 add	 eax,ebx	; Add to get offset of video memory
;;;;;;;; sh?	 eax,(12-2)-10	; Convert from 1KB to 4KB in dwords
	 mov	 PPDTVID,eax	; Save for later use

if @OEM_VCPI

; Setup EPMTAB

	 call	 SETUP_EPM	; Set 'em up
endif				; IF @OEM_VCPI

; IRET to original task and set VM flag bit in the process

	 call	 ENTERPM	; Enter Protected Mode

COMMENT|

In order to support the DOS CONFIG.SYS option of HIMEM /DOS /NOXMS,
we *MUST NOT* use any DOS calls until we have installed our own XMS
handler into low DOS memory which is done in INTR_SET.

|

	 test	 ERR_FLAG,@ERR_MOV ; Error moving to extended memory?
	 jz	 short PROT_INIT1 ; No

	 mov	 al,ERR_CODE	; Get the error code
	 lea	 si,YGROUP:MSG_ERRMOV1 ; YGROUP:SI ==> error code save area
	 call	 FMT_ERR_CODE	; Format the error code

	 mov	 eax,ERR_CODE_ADDR ; Get the error's linear address
	 lea	 di,YGROUP:MSG_ERRMOV3 ; YGROUP:DI ==> ASCII text save area
	 call	 FMT_WORD_YGRP	; Format the address (lower half)

	 shr	 eax,16 	; Get upper half of linear address
	 lea	 di,YGROUP:MSG_ERRMOV2 ; YGROUP:DI ==> ASCII text  save area
	 call	 FMT_WORD_YGRP	; Format the address (upper half)

	 mov	 ax,ERR_CODE_VAL ; Get the error word count
	 lea	 di,YGROUP:MSG_ERRMOV4 ; YGROUP:DI ==> ASCII text save area
	 call	 FMT_WORD_YGRP	; Format the word mismatch count

	 push	 offset YGROUP:MSG_ERRMOV ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short PROT_INIT_ERR ; Join common error code

PROT_INIT1:
	 test	 ERR_FLAG,@ERR_PRO ; Error entering protected mode?
	 jz	 short PROT_INIT2 ; No, note CF=0

	 mov	 al,ERR_CODE	; Get the error code
	 lea	 si,YGROUP:MSG_ERRPRO1 ; YGROUP:SI ==> error code save area
	 call	 FMT_ERR_CODE	; Format the error code

	 push	 offset YGROUP:MSG_ERRPRO ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message
PROT_INIT_ERR:
	 stc			; Indicate something went wrong
PROT_INIT2:
	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing

	 popad			; Restore all GP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROT_INIT endp			; End PROT_INIT procedure

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_IN2 module

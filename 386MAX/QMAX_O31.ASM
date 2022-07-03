;' $Header:   P:/PVCS/MAX/386MAX/QMAX_O31.ASV   1.3   30 May 1997 10:45:46   BOB  $
	 title	 QMAX_O31 -- More 386MAX INT 31h Handlers
	 page	 58,122
	 name	 QMAX_O31

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-8 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Program segment DEBUG, byte-aligned,  public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'

Program derived from:  QMAX_I31.ASM

Original code by:  William R. Lewis, April, 1991.
		   Additional code by BOB.

Modifications by:  Henry Groover, December 1995.

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

PGROUP	 group	 CODE,HICODE,ECODE,DEBUG,EDATA
FGROUP	 group	 FDATA
IGROUP	 group	 LCODE,LDATA,ICODE,IDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 DB3_FLAG:word
	 include QMAX_DB3.INC

	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

CODE	 ends			; End CODE segment

HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 DPMI_VM2PM:near

HICODE	 ends			; End HICODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 LAST_DPMI_DS:word
	 extrn	 LAST_DPMI_ES:word
	 extrn	 LAST_DPMI_FS:word
	 extrn	 LAST_DPMI_GS:word
	 extrn	 PRGBASE:dword
	 extrn	 IGRBASE:dword
	 extrn	 XLDT_SIZ:dword
	 extrn	 DESC_TAB:qword
	 extrn	 IDT_DESC:qword
	 extrn	 SEL_DSFG3:word
	 extrn	 SEL_4GB:word
	 extrn	 SEL_4GB3:word
	 extrn	 LAST_INTCOM:dword
	 extrn	 LAST_INTFLG:dword
	 extrn	 LPMSTK_SIZ:dword
	 extrn	 CON4KB:dword

	 extrn	 DPMI_CPIHOOK:byte
	 extrn	 DPMI_CPFHOOK:byte
	 extrn	 DPMI_CVFHOOK:byte
	 extrn	 DPMI_PPIHOOK:byte
	 extrn	 DPMI_PVFHOOK:byte

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

	 extrn	 DPMIMSG:word

	 extrn	 SWATCODE:fword

	 extrn	 MSW_PM:word

	 extrn	 I31_FLAG:word
	 extrn	 PDC_FLAG:word

	 extrn	 VM2PM_TSS:word

	 extrn	 DPM_FLAG:word

	 extrn	 CPUTYPE:byte
	 extrn	 DPMITYPE:byte

	 extrn	 DPMI_CODE:word
	 extrn	 DPMI_DATA:word
	 extrn	 DPMI_IDEF:word
	 extrn	 DPMI_CPL:byte
	 extrn	 DPMI_DPL:byte

	 extrn	 HPDASTK_SIZ:word
	 extrn	 HPDABUF_SIZ:word
	 extrn	 HPDAVMC_CNT:word

	 extrn	 HPDASTK_TOP:word
	 extrn	 HPDABUF_OFF:word
	 extrn	 HPDAVMC_OFF:word
	 extrn	 HPDA_NPAR:word

	 extrn	 DPMIDYN_SIZ:dword
	 extrn	 DPMIPDIR_OFF:dword
	 extrn	 LaDPMIPDIRMEM:dword

	 extrn	 DPMIOLDPM_SIZ:dword

	 extrn	 LPMSTK_SEL:word

EDATA	 ends			; End EDATA segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MSG_TITLE:tbyte
	 extrn	 MSG_TITL2:tbyte
	 extrn	 MSG_TITL3:tbyte
	 extrn	 MSG_TITL4:tbyte
	 extrn	 MSG_APPLUNK:tbyte
	 extrn	 MSG_TAIL:tbyte

	 extrn	 MSG_DPMIAPPLNAME:tbyte
	 extrn	 MSG_DPMIADDR:tbyte
	 extrn	 MSG_DPMIADDROFF:byte
	 extrn	 MSG_DPMIADDRSEP:byte
	 extrn	 MSG_DPMIADDRSEL:byte
	 extrn	 MSG_DPMIPRESS:tbyte

	 public  MSG_FOXCOMPAT
MSG_FOXCOMPAT db 'Incompatible memory manager',LF,0
MSG_FOXCOMPAT_LEN equ $-MSG_FOXCOMPAT ; Length of ...

	 public  MSG_RATIONAL1
MSG_RATIONAL1 db 'Copyright (C) 1987-199'
MSG_RATIONAL1A db '? by Rational Systems, Inc.'
MSG_RATIONAL1_LEN equ $-MSG_RATIONAL1 ; Length of ...

	 public  MSG_RATIONAL2
MSG_RATIONAL2 db 'Copyright (C) Rational Systems, Inc. 1'
MSG_RATIONAL2_LEN equ $-MSG_RATIONAL2 ; Length of ...

	 public  MSG_PHARLAP
MSG_PHARLAP db	 'Copyright (C) 1986-1989 Phar Lap Software, Inc.'
MSG_PHARLAP_LEN equ $-MSG_PHARLAP ; Length of ...

FDATA	 ends			; End FDATA segment


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
	 assume  cs:IGROUP

	 extrn	 GETSELBASE:far

LCODE	 ends			; End LCODE segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DSIG3:word
	 extrn	 ISEL_DS3:word

LDATA	 ends			; End LDATA segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

	 extrn	 DBGCTL:byte
	 extrn	 DBGSTA:byte
	 extrn	 DBGREGS:dword
	 extrn	 DBGDR7:dword

PM_MAC16 macro	 NAME,N
	 dw	 NAME&N,DTE_DPMIDEF or (@DPMI_CPL shl $PL)
	 endm			; PM_MAC16

PM_MAC32 macro	 NAME,N
	 dw	 NAME&N,0,DTE_DPMIDEF or (@DPMI_CPL shl $PL)
	 endm			; PM_MAC32

; Define default PM interrupt handlers

	 public  PMINT_FVECS
PMINT_FVECS label fword

CNT	 =	 0
	 rept	 256

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 PM_MAC32 PMIDEF,%N
CNT	 =	 CNT + 1
	 endm			; REPT 256

	 public  PMINT_DVECS
PMINT_DVECS label dword

CNT	 =	 0
	 rept	 256

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 PM_MAC16 PMIDEF,%N
CNT	 =	 CNT + 1
	 endm			; REPT 256


; Define default PM fault handlers

	 public  PMFLT_FVECS
PMFLT_FVECS label fword

CNT	 =	 0
	 rept	 32

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 PM_MAC32 PMFDEF,%N
CNT	 =	 CNT + 1
	 endm			; REPT 32

	 public  PMFLT_DVECS
PMFLT_DVECS label dword

CNT	 =	 0
	 rept	 32

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 PM_MAC16 PMFDEF,%N
CNT	 =	 CNT + 1
	 endm			; REPT 32

; Define default VM fault handlers

	 public  VMFLT_FVECS
VMFLT_FVECS label fword

CNT	 =	 0
	 rept	 32

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 PM_MAC32 VMFDEF,%N
CNT	 =	 CNT + 1
	 endm			; REPT 32

	 public  VMFLT_DVECS
VMFLT_DVECS label dword

CNT	 =	 0
	 rept	 32

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 PM_MAC16 VMFDEF,%N
CNT	 =	 CNT + 1
	 endm			; REPT 32

	 extrn	 DPMITYPEIG:byte

	 public  KRNL386
KRNL386  db	 'KRNL386.EXE',0 ; Windows DPMI client
KRNL386_LEN equ  $-KRNL386	; Length of ...

	 public  HPDA_TEMPLATE
HPDA_TEMPLATE HPDA_STR <>	; HPDA template used for all HPDAs

IDATA	 ends			; End IDATA segment


DEBUG	 segment use16 byte public 'ecode' ; Start DEBUG segment
	 assume  cs:PGROUP

	 extrn	 FDW2HEX:far

DEBUG	 ends			; End DEBUG segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 FKEYWAIT:far
	 extrn	 FSET_GDT:far
	 extrn	 SIRBCUR2B:far

	 extrn	 FDISP_STR:far
	 extrn	 FDD2HEX:far
	 extrn	 FDEALLOCMEM:far

ECODE	 ends			; End ECODE segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 extrn	 CLR_LDT:near
	 extrn	 DPMIFN_XLDT_SIZ:near

	 extrn	 INT31_VM2PM_RET:near

PMEXT_MAC macro  NAME,N
	 extrn	 NAME&N:abs
	 endm			; PMEXT_MAC


CNT	 =	 0
	 rept	 256

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 PMEXT_MAC PMIDEF,%N
CNT	 =	 CNT + 1
	 endm			; REPT 256

CNT	 =	 0
	 rept	 32

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 PMEXT_MAC PMFDEF,%N
	 PMEXT_MAC VMFDEF,%N
CNT	 =	 CNT + 1
	 endm			; REPT 32


	 extrn	 DPMIFN_NEWLINE:near

	 extrn	 @ENVLEN:abs

	 FPPROC  IMM2_DPMIPRES -- DPMI Presence Detection
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

	 call	 IMM2_USEVCPI	; Check for DOS extenders better off with VCPI
	 jnc	 short IMM2_DPMIPRES_EXIT ; Jump if no match

	 mov	 [ebp].INTXX_EBX.ELO,@BIT0 ; BX = 1 (we support 32-bit apps)
	 mov	 al,CPUTYPE	; Get the CPU type
	 mov	 [ebp].INTXX_ECX.ELO.LO,al ; Return in CL

; Because of a bug in certain Rational Systems-based programs,
; we need to check for their signature and return version 0.90
; instead of 1.00.  These programs actually test the major DPMI
; version # and take a different path if it's 1.00.  Of course,
; the path they take has never been tested (we're the first DPMI
; 1.00 host), and (of course) the code on that path doesn't work.

	 mov	 ax,0100h	; We're thoroughly modern

	 call	 IZIT_RATIONAL	; Izit Rational Systems, Inc.?
	 jc	 short IMM2_DPMIPRES1 ; No, but it makes sense

	 or	 PDC_FLAG,mask $I31_RSI ; Mark as Rational Systems, Inc.

	 jmp	 short IMM2_DPMIPRES2 ; Join common code

IMM2_DPMIPRES1:
	 test	 PDC_FLAG,mask $I31_VER090 ; Time to lie?
	 jz	 short IMM2_DPMIPRES3 ; Jump if not
IMM2_DPMIPRES2:
	 test	 DPM_FLAG,mask $DPM_DPMIV100 ; Should we force version 1.00?
	 jnz	 short IMM2_DPMIPRES3 ; Jump if so

	 mov	 ax,005Ah	; Use the back level version (0.90)
IMM2_DPMIPRES3:
	 mov	 [ebp].INTXX_EDX.ELO.HI,ah ; Save major version #
	 mov	 [ebp].INTXX_EDX.ELO.LO,al ; ...  minor ...
	 mov	 ax,HPDA_NPAR	; Get size of HPDA in paras
	 mov	 [ebp].INTXX_ESI.ELO,ax ; # paras in HPDA
	 mov	 [ebp].INTXX_EDI.ELO,offset PGROUP:DPMI_VM2PM
	 mov	 [ebp].INTXX_ES,seg PGROUP ; Return high DOS CS
	 org	 $-2
	 public  INT31B_HIMEM_CS
INT31B_HIMEM_CS label near	; Address previous segment for relocation
	 org	 $+2

	 xor	 ax,ax		; Result in AX is zero
				; for INT 67h so we go disabled if no EMS usage
IMM2_DPMIPRES_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IMM2_DPMIPRES endp		; End IMM2_DPMIPRES procedure
	 NPPROC  IMM2_USEVCPI -- Check for DOS Extenders For VCPI
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for DOS extenders which would be better off using VCPI.

On exit:

CF	 =	 0 if we have a match and should fail the 1687 call
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers
	 REGSAVE <es,fs>	; Save selectors

	 test	 DPM_FLAG,mask $DPM_DPMIXCOPY ; Should we disregard copyright notices?
	 jnz	 near ptr IMM2_USEVCPI_NOMATCH ; Jump if so

; Because the alternative is to use VCPI, we had better be sure
; we're providing those services.

	 test	 LCL_FLAG,@LCL_DRV ; Another EMS driver present?
	 jnz	 near ptr IMM2_USEVCPI_NOMATCH ; Jump if so

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 fs,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  fs:FGROUP	; Tell the assembler about it

; Check for Foxpro DOS extender which has the error message
; MSG_FOXCOMPAT at DS:007E.

	 movzx	 edi,[ebp].INTXX_DS ; Get caller's DS
	 shl	 edi,4-0	; Convert from paras to bytes
	 add	 edi,007Eh	; Plus magic offset

	 lea	 esi,MSG_FOXCOMPAT ; FGROUP:ESI ==> string to match
	 mov	 ecx,MSG_FOXCOMPAT_LEN ; ECX = length of ...
    repe cmps	 MSG_FOXCOMPAT[esi].LO,AGROUP:[edi].LO ; Duzit match?
	 je	 near ptr IMM2_USEVCPI_EXIT ; Jump if so (note CF=0)

	 call	 IZIT_RATIONAL	; Izit Rational Systems, Inc.?
	 jnc	 short IMM2_USEVCPI_EXIT ; Jump if so (note CF=0)

; Check for Phar Lap copyright message at PSP:0100 with either
; 'P3', 'P5', or 'P6' at PSP:PHARLAP_CFG_ESIG

	 DOSCALL @GETPS0	; Get PSP into BX

	 push	 bx		; Pass selector as argument
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	 mov	 edi,eax	; Copy to string register

PHARLAP_CFGBLK_STR struc

	 db	 100h dup (?)	; The PSP
PHARLAP_CFG_COPYRIGHT db 32h dup (?) ; Their copyright notice
PHARLAP_CFG_TYPE      dw ?	; Configuration type block
PHARLAP_CFG_RSRV1     dw ?	; Reserved
PHARLAP_CFG_RSRV2     dw ?	; Reserved
PHARLAP_CFG_ESIG      dw ?	; .EXE file signature

PHARLAP_CFGBLK_STR ends

	 cmp	 AGROUP:[edi].PHARLAP_CFG_ESIG,'3P' ; Izit 'P3'?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[edi].PHARLAP_CFG_ESIG,'5P' ; Izit 'P5'?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[edi].PHARLAP_CFG_ESIG,'6P' ; Izit 'P6'?
	 jne	 short IMM2_USEVCPI_NOMATCH ; Jump if not
@@:
	 lea	 edi,AGROUP:[edi].PHARLAP_CFG_COPYRIGHT ; AGROUP:EDI ==> copyright notice
	 lea	 esi,MSG_PHARLAP ; FGROUP:ESI ==> string to match
	 mov	 ecx,MSG_PHARLAP_LEN ; ECX = length of ...

    repe cmps	 MSG_PHARLAP[esi].LO,AGROUP:[edi].LO ; Duzit match?
	 je	 short IMM2_USEVCPI_EXIT ; Jump if so (note CF=0)
IMM2_USEVCPI_NOMATCH:
	 stc			; Mark as no match
IMM2_USEVCPI_EXIT:
	 REGREST <fs,es>	; Restore
	 assume  es:nothing,fs:nothing ; Tell the assembler about it
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IMM2_USEVCPI endp		; End IMM2_USEVCPI procedure
	 NPPROC  IZIT_RATIONAL -- Check For Rational Systems, Inc.
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for the three different Rational Systems copyright notices
each of which is at DS3:XXXX where XXXX is the word at DS3:0030.

On entry:

SS:EBP	 ==>	 INTXX_STR

On exit:

CF	 =	 0 if it's a Rational Systems, Inc based program
	 =	 1 otherwise

|

	 REGSAVE <eax,ecx,esi,edi,es,fs> ; Save registers

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 fs,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  fs:FGROUP	; Tell the assembler about it

	 movzx	 edi,[ebp].INTXX_DS ; Get caller's DS
	 shl	 edi,4-0	; Convert from paras to bytes
	 movzx	 eax,AGROUP:[edi+0030h].ELO ; Get word ptr at DS:0030h
	 add	 edi,eax	; AGROUP:EDI ==> copyright string (if present)

	 lea	 esi,MSG_RATIONAL1 ; FGROUP:ESI ==> string to match
	 mov	 ecx,MSG_RATIONAL1_LEN ; ECX = length of ...

	 mov	 MSG_RATIONAL1A,'0' ; Try '1990'

	 REGSAVE <ecx,esi,edi>	; Save for a moment
    repe cmps	 MSG_RATIONAL1[esi].LO,AGROUP:[edi].LO ; Duzit match?
	 REGREST <edi,esi,ecx>	; Restore
	 je	 short IZIT_RATIONAL_EXIT ; Jump if so (note CF=0)

	 mov	 MSG_RATIONAL1A,'1' ; Try '1991'

	 REGSAVE <ecx,esi,edi>	; Save for a moment
    repe cmps	 MSG_RATIONAL1[esi].LO,AGROUP:[edi].LO ; Duzit match?
	 REGREST <edi,esi,ecx>	; Restore
	 je	 short IZIT_RATIONAL_EXIT ; Jump if so (note CF=0)

	 lea	 esi,MSG_RATIONAL2 ; FGROUP:ESI ==> string to match
	 mov	 ecx,MSG_RATIONAL2_LEN ; ECX = length of ...

    repe cmps	 MSG_RATIONAL2[esi].LO,AGROUP:[edi].LO ; Duzit match?
	 je	 short IZIT_RATIONAL_EXIT ; Jump if so (note CF=0)

	 stc			; Mark as not Rational, but sensible
IZIT_RATIONAL_EXIT:
	 REGREST <fs,es,edi,esi,ecx,eax> ; Restore
	 assume  es:nothing,fs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_RATIONAL endp		; End IZIT_RATIONAL procedure
	 NPPROC  DPMIFN_INITVARS -- Initialize TSS and HPDA
	 assume  ds:PGROUP,es:IGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Initialize TSS and HPDA

On entry:

EDX	 =	 offset in PRGOUP of the incoming TSS
SS:EBP	 ==>	 INTXX_STR

On exit:

|

	 REGSAVE <eax,ebx,ecx,edx,esi,edi> ; Save registers

; Save LAST_INTCOM, LAST_INTFLG, and PL0 stack values into the next TSS

	 mov	 eax,LAST_INTCOM ; Get last INTCOM restart point
	 mov	 PGROUP:[edx].DPTSS_INTCOM,eax ; Save to restore later

	 mov	 eax,LAST_INTFLG ; Get its flag
	 mov	 PGROUP:[edx].DPTSS_INTFLG,eax ; Save to restore later

	 mov	 eax,PPL0STK_ERR ; Get stack offset when error code present
	 mov	 PGROUP:[edx].DPTSS_STKERR,eax ; Save to restore later

	 mov	 eax,PPL0STK_NRM ; Get stack offset when normal start
	 mov	 PGROUP:[edx].DPTSS_STKNRM,eax ; Save to restore later

	 mov	 eax,PPL0STK_DERR ; Get stack offset when DPMI fault occurs
	 mov	 PGROUP:[edx].DPTSS_STKDERR,eax ; Save to restore later

	 mov	 eax,PPL0STK_DNRM ; Get stack offset when DPMI HW/SW occurs
	 mov	 PGROUP:[edx].DPTSS_STKDNRM,eax ; Save to restore later

	 mov	 eax,PPL0STK_MIN ; Get stack minimum for interrupts
	 mov	 PGROUP:[edx].DPTSS_STKMIN,eax ; Save to restore later

	 mov	 eax,PPL0STK_MAP ; Get stack bottom for Map & Call struc
	 mov	 PGROUP:[edx].DPTSS_STKMAP,eax ; Save to restore later

; Save the initial current buffer offset and size

	 mov	 ax,HPDABUF_OFF ; Get the offset
	 mov	 PGROUP:[edx].DPTSS_VMBUFOFF,ax ; Save for later use

	 mov	 ax,HPDABUF_SIZ ; Get the size
	 mov	 PGROUP:[edx].DPTSS_VMBUFSIZ,ax ; Save for later use

; Save MSW and INT 07h values

	 mov	 ax,MSW_PM	; Get MSW for PM operaton
	 mov	 PGROUP:[edx].DPTSS_MSW,ax ; Save for later use

	 mov	 eax,IDT_DESC.EDQLO[07h*(type IDT_DESC)] ; Get low-order dword
	 mov	 PGROUP:[edx].DPTSS_IDT07.EDQLO,eax ; Save for later use

	 mov	 eax,IDT_DESC.EDQHI[07h*(type IDT_DESC)] ; Get high-order dword
	 mov	 PGROUP:[edx].DPTSS_IDT07.EDQHI,eax ; Save for later use

; Save the segment of the host private data area

	 movzx	 ebx,[ebp].INTXX_ES ; Get the HPDA segment
	 mov	 PGROUP:[edx].DPTSS_HPDASEG,bx ; Save for later use
	 mov	 PGROUP:[edx].DPTSS_VMSTKSEG,bx ; ...
	 shl	 ebx,4-0	; Convert from paras to bytes
	 mov	 PGROUP:[edx].DPTSS_LaHPDA,ebx ; Save for later use

; Setup constant values in the HPDA

	 push	 es		; Save for a moment

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,ebx	; ES:EDI ==> HPDA in first megabyte
	 lea	 esi,HPDA_TEMPLATE ; CS:ESI ==> HPDA template
	 mov	 ecx,(size HPDA_TEMPLATE)/4 ; ECX = # dwords in HPDA template
S32  rep movs	 <AGROUP:[edi].EDD,HPDA_TEMPLATE.EDD> ; Copy template to HPDA

	 pop	 es		; Restore
	 assume  es:IGROUP	; Tell the assembler about it

; Save back pointer to the current TSS

	 mov	 AGROUP:[ebx].HPDA_PCURTSS,edx ; Save as back pointer

; Save stack segment and initial offsets

	 mov	 ax,HPDASTK_TOP ; Get offset of top of HPDA stack
	 mov	 PGROUP:[edx].DPTSS_VMSTKOFF,ax ; Save for later use
	 sub	 ax,HPDASTK_SIZ ; Less size of HPDA stack
	 mov	 PGROUP:[edx].DPTSS_VMSTKBOT,ax ; Save for later use

; Save caller's EIP and ESP in new TSS for transfer

	 movzx	 eax,[ebp].INTXX_EIP.ELO ; Get the return EIP
	 mov	 PGROUP:[edx].TSS_EIP,eax ; Save for later use

	 movzx	 eax,[ebp].INTXX_ESP.ELO ; Get the return ESP
	 mov	 PGROUP:[edx].TSS_ESP,eax ; Save for later use

; Save the original segment registers so we can restore them when we exit

	 mov	 ax,[ebp].INTXX_DS ; Get original DS
	 mov	 AGROUP:[ebx].HPDA_vDS,ax ; Save to restore later
	 mov	 ax,[ebp].INTXX_ES ; ...	  ES
	 mov	 AGROUP:[ebx].HPDA_vES,ax ; ...
	 mov	 ax,[ebp].INTXX_FS ; ...	  FS
	 mov	 AGROUP:[ebx].HPDA_vFS,ax ; ...
	 mov	 ax,[ebp].INTXX_GS ; ...	  GS
	 mov	 AGROUP:[ebx].HPDA_vGS,ax ; ...

; Initialize VM callback structures

	 mov	 cx,HPDAVMC_CNT ; Get # VM callback structures
	 movzx	 eax,HPDAVMC_OFF ; Get offset of 1st VM callback struc
@@:
	 mov	 AGROUP:[ebx+eax].HPDAVMC_INTFF[0],@OPCOD_INT3 ; Mark as free

	 add	 eax,size HPDAVMC_STR ; Skip to next VM callback struc

	 loop	 @B		; Jump if more VM callback struc

; Clear the VM and CF bits, set IOPL to DPMIOPL; IF remains as set by the caller

	 mov	 eax,[ebp].INTXX_EFL ; Get the return EFL
	 and	 eax,not ((mask $VMHI) or (mask $IOPL) or (mask $CF))
	 or	 eax,@DPMIOPL shl $IOPL ; IOPL=@DPMIOPL
	 mov	 PGROUP:[edx].TSS_EFL,eax ; Save for later use

; Save our important registers into our own TSS to restore upon return

	 mov	 edx,PGROUP:[edx].DPTSS_PLNKTSS ; Get offset in PGROUP of prev TSS

	 mov	 PGROUP:[edx].TSS_CS,cs ; Save it
	 mov	 PGROUP:[edx].TSS_DS,ds ; ...
	 mov	 PGROUP:[edx].TSS_ES,es ; ...
	 mov	 PGROUP:[edx].TSS_FS,fs ; ...
	 mov	 PGROUP:[edx].TSS_GS,gs ; ...
	 mov	 PGROUP:[edx].TSS_SS,ss ; ...
	 mov	 PGROUP:[edx].TSS_EFL,0 ; ...

; Setup our return stack pointer to a minimum stack with just enough
; room to handle spurious IRET/Ds with NT set

; The following number must be large enough to handle all stack
; activity between the entry at INT31_VM2PM_RET through a return
; to the caller at the IRETD just above INT31_VM2PM_RET.

@SPURNT  equ	 256		; Size of stack for spurious TSS switch

	 mov	 eax,PGROUP:[edx].DPTSS_STKMIN ; Get minimum stack offset
	 add	 eax,@SPURNT	; Make it a short stack (with blueberries?)
	 mov	 PGROUP:[edx].TSS_ESP,eax ; Save in old TSS

	 lea	 eax,INT31_VM2PM_RET ; Get offset of our return EIP
	 mov	 PGROUP:[edx].TSS_EIP,eax ; ...

	 REGREST <edi,esi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_INITVARS endp		; End DPMIFN_INITVARS procedure
	 NPPROC  DPMIFN_DELINKTSS -- De-link TSS If Fault in Middle
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

De-link this TSS if we faulted in the middle of the chain
Note that we *MUST* call this routine before we have reset PCURTSS.

On entry:

EDX	 =	 PCURTSS

|

	 REGSAVE <eax,ecx,edx>	; Save registers

; Search through all valid TSSs looking for one
; whose DPTSS_PLNKTSS == PCURTSS and de-link that one

	 mov	 cx,@TSS_MAX	; Get maximum # TSSs
	 mov	 eax,PVMTSS	; Get offset in PGROUP of the 1st TSS
DPMIFN_DELINKTSS_NEXT:
	 cmp	 edx,PGROUP:[eax].DPTSS_PLNKTSS ; Duzit point to outgoing TSS?
	 je	 short @F	; Jump if so

	 add	 eax,type DPTSS_STR ; Skip to next TSS

	 loop	 DPMIFN_DELINKTSS_NEXT ; Jump if more TSS to check

	 jmp	 short DPMIFN_DELINKTSS_EXIT ; Join common exit code

@@:
	 mov	 ecx,PGROUP:[edx].DPTSS_PLNKTSS ; Get offset in PGROUP of prev TSS
	 mov	 PGROUP:[eax].DPTSS_PLNKTSS,ecx ; De-link us

	 mov	 cx,PGROUP:[edx].TSS_LINK ; Get prev TSS link
	 mov	 PGROUP:[eax].TSS_LINK,cx ; De-link us
DPMIFN_DELINKTSS_EXIT:
	 REGREST <edx,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_DELINKTSS endp		; End DPMIFN_DELINKTSS procedure
	 NPPROC  DPMIFN_PLNKTSS -- Back Off To Previous TSS and Selector
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Back off to the previous TSS and its selector.

On entry:

EDX	 =	 PCURTSS

|

	 REGSAVE <eax>		; Save register

	 xor	 eax,eax	; Get invalid marker
	 mov	 PGROUP:[edx].TSS_LDT,ax ; Ensure invalid
	 xchg	 eax,PGROUP:[edx].DPTSS_PLNKTSS ; Get offset in PGROUP of the prev TSS
	 mov	 PCURTSS,eax	; Back off to previous TSS
	 mov	 PPRMTSS,eax	; ...

	 mov	 ax,-1		; Get available TSS marker
	 xchg	 ax,PGROUP:[edx].TSS_LINK ; Mark as available
	 mov	 VM2PM_TSS,ax	; Back off to previous TSS selector

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_PLNKTSS endp		; End DPMIFN_PLNKTSS procedure
	 NPPROC  DPMIFN_FREE_VMOLDPM -- Free First Old PM Data Area
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Free the first old PM data area if we are back to the first TSS.

Note that this routine must be called *BEFORE* PCURTSS has been
restored to the incoming TSS.

|

	 REGSAVE <edx>		; Save register

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 edx,PGROUP:[edx].DPTSS_PLNKTSS ; Get offset in PGROUP of prev TSS

	 cmp	 edx,PVMTSS	; Izit the 1st TSS?
	 jne	 short DPMIFN_FREE_VMOLDPM_EXIT ; Jump if not

	 cmp	 PGROUP:[edx].DPTSS_OLDPM,0 ; Izit initialized as yet?
	 je	 short @F	; Jump if not

	 push	 DPMIOLDPM_SIZ	; Pass byte length
	 push	 PGROUP:[edx].DPTSS_OLDPM ; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:
	 mov	 PGROUP:[edx].DPTSS_OLDPM,0 ; Mark as not initialized
DPMIFN_FREE_VMOLDPM_EXIT:
	 REGREST <edx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_FREE_VMOLDPM endp	; End DPMIFN_FREE_VMOLDPM procedure
	 NPPROC  DPMIFN_INITLDT -- Initialize the Contents of the LDT
	 assume  ds:PGROUP,es:IGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Initialize the contents of the LDT and install it as the current one.

On entry:

AGROUP:EDX ==>	 current TSS

|

	 REGSAVE <eax,ecx,edi,es> ; Save registers

; Initialize the LDT contents to zero

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT
	 xor	 eax,eax	; Set contents to this value
	 mov	 ecx,XLDT_SIZ	; Get byte size of extended LDT (/@DPMI_BOUND)
	 shr	 ecx,2-0	; Convert from bytes to dwords
     rep stos	 AGROUP:[edi].EDD ; Initialize it

; Set linear address of new DPMI LDT in the GDT

	 mov	 eax,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT

	 push	 PGROUP:[edx].DPTSS_LDT_SIZ ; Pass size of area in bytes (/8)
	 push	 CPL0_LDT or CPL0 ; Pass access rights byte
	 push	 PGROUP:[edx].TSS_LDT ; Pass descriptor to set
	 FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the GDT to EAX base

; Tell the CPU about the new LDTR

	 lldt	 PGROUP:[edx].TSS_LDT ; Set LDTR

; Save linear address of DPMI LDT as Read-Write data descriptor at PL3
; now so we get the same selector for each LDT

	 mov	 eax,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT

	 push	 PGROUP:[edx].DPTSS_LDT_SIZ ; Pass size of area in bytes (/8)
	 push	 DPMI_DATA	; Pass access rights byte
	 push	 LDTE_DATALDT3	; Pass descriptor to set
	 FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the GDT to EAX base

; Save linear address of DPMI LPM as Read-Write data descriptor at PL3
; now so we get the same selector for each LDT

	 mov	 eax,PGROUP:[edx].DPTSS_LPMBASE ; Get linear address of LPM

	 mov	 cl,DPMI_DATA.LO ; Get A/R byte for 16-bit client

	 cmp	 DPMITYPE,@DPMITYPE16 ; Izit a 16-bit client?
	 setne	 ch		; CH = 1 if 32-bit or no DPMI
				;    = 0 if 16-bit
	 shl	 ch,$DTE_B	; Set B-bit for 32-bit apps

	 push	 LPMSTK_SIZ	; Pass size of area in bytes
	 push	 cx		; Pass access rights word
	 push	 LDTE_DATALPM3	; Pass descriptor to set
	 FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the GDT to EAX base

	 REGREST <es,edi,ecx,eax> ; Restore
	 assume  es:IGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_INITLDT endp		; End DPMIFN_INITLDT procedure
	 NPPROC  DPMIFN_INITDPMIHNDL -- Initialize the Contents of the DPMI Memory Handle Table
	 assume  ds:PGROUP,es:IGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Initialize the contents of the DPMI memory handle table

On entry:

AGROUP:EDX ==>	 current TSS

|

	 REGSAVE <eax,ecx,edi,es> ; Save registers

; Initialize the DPMI memory handle table contents to zero

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; Get linear address of DPMI
				; memory handle table
	 mov	 al,0		; Set contents to this value
	 mov	 ecx,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 imul	 ecx,type DPMIHNDL_STR ; Convert from struc to bytes
     rep stos	 AGROUP:[edi].LO ; Initialize it

	 REGREST <es,edi,ecx,eax> ; Restore
	 assume  es:IGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_INITDPMIHNDL endp	; End DPMIFN_INITDPMIHNDL procedure
	 NPPROC  DPMIFN_FREELDT -- De-allocate The LDT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

Note that both PCURTSS and VM2PM_TSS point to the outgoing TSS.

|

	 REGSAVE <eax,ebx,edx,ds> ; Save registers

	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 mov	 eax,PGROUP:[edx].DPTSS_LDT_SIZ ; Get byte size of DPMI LDT (/8)
	 call	 DPMIFN_XLDT_SIZ ; Return with EBX = byte size of extended
				; DPMI LDT using LDT_SIZ of EAX

	 cmp	 PGROUP:[edx].DPTSS_LaLDT,0 ; Izit initialized as yet?
	 je	 short DPMIFN_FREELDT_EXIT ; Jump if not (leave LDTR alone
				; as we haven't switched to this client)
	 push	 ebx		; Pass byte length
	 push	 PGROUP:[edx].DPTSS_LaLDT ; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:
	 mov	 PGROUP:[edx].DPTSS_LaLDT,0 ; Mask as not initialized

; Invalidate the LDTR until we switch back to the previous client

	 xor	 ax,ax		; An invalid DTE
	 lldt	 ax		; Set LDTR
DPMIFN_FREELDT_EXIT:
	 REGREST <ds,edx,ebx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_FREELDT endp		; End DPMIFN_FREELDT procedure
	 NPPROC  DPMIFN_SAVEOLDPM -- Save Current Data to Old PM Data Area
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save current data into old PM data area
and re-initialize all values if asked to.

The structure of the old PM data area is

SIRBCUR
DPMI_CPIHOOK
DPMI_CPFHOOK
DPMI_CVFHOOK
PMINT_FVECS
PMINT_DVECS
PMFLT_FVECS
PMFLT_DVECS
VMFLT_FVECS
VMFLT_DVECS
LAST_DPMI_DS
LAST_DPMI_ES
LAST_DPMI_FS
LAST_DPMI_GS
I31_FLAG
DPMITYPE
DBGCTL
DBGSTA
DBGREGS
DBGDR7

If any fields are added/deleted from this list, be sure to update
DPMIFN_RESTOLDPM as well as the size calculations in QMAX_ARG.ASM in
the CHECK_ARGS_VALIDxx section.

|

SAVEOLDPM_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
SAVEOLDPM_FLG dw ?		; Flag:  1 = re-initialize variables
				;	 0 = don't
SAVEOLDPM_TSS dd ?		; Offset in PGROUP of TSS to use

SAVEOLDPM_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 pushad 		; Save all EGP registers
	 REGSAVE <es>		; Save selector

	 mov	 es,SEL_4GB	; Get AGROUP data selector at PL0
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,[ebp].SAVEOLDPM_TSS ; Get offset in PGROUP of TSS to use
	 mov	 edi,PGROUP:[edi].DPTSS_OLDPM ; Get linear address of old PM data area


; Skip over SIRBCUR

	 test	 CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	 jz	 short @F	; Jump if not

	 add	 edi,256/8	; Skip over SIRBCUR table
@@:


; Copy DPMI_CPIHOOK

	 lea	 esi,DPMI_CPIHOOK ; Get offset in PGROUP of current PM
				; interrupt hook bitmap
	 add	 esi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,256/(8*4)	; Get size of table in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy to old PM data area


; Copy DPMI_CPFHOOK

	 lea	 esi,DPMI_CPFHOOK ; Get offset in PGROUP of current PM
				; fault hook bitmap
	 add	 esi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,32/(8*4)	; Get size of table in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy to old PM data area


; Copy DPMI_CVFHOOK

	 lea	 esi,DPMI_CVFHOOK ; Get offset in PGROUP of current VM
				; fault hook bitmap
	 add	 esi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,32/(8*4)	; Get size of table in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy to old PM data area


; Copy PMINT_FVECS

	 lea	 esi,IGROUP:PMINT_FVECS ; Get offset in IGROUP of PMINT_FVECS
	 add	 esi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(256/4)*(type PMINT_FVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy to old PM data area


; Copy PMINT_DVECS

	 lea	 esi,IGROUP:PMINT_DVECS ; Get offset in IGROUP of PMINT_DVECS
	 add	 esi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(256/4)*(type PMINT_DVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy to old PM data area


; Copy PMFLT_FVECS

	 lea	 esi,IGROUP:PMFLT_FVECS ; Get offset in IGROUP of PMFLT_FVECS
	 add	 esi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(32/4)*(type PMFLT_FVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy to old PM data area


; Copy PMFLT_DVECS

	 lea	 esi,IGROUP:PMFLT_DVECS ; Get offset in IGROUP of PMFLT_DVECS
	 add	 esi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(32/4)*(type PMFLT_DVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy to old PM data area


; Copy VMFLT_FVECS

	 lea	 esi,IGROUP:VMFLT_FVECS ; Get offset in IGROUP of VMFLT_FVECS
	 add	 esi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(32/4)*(type VMFLT_FVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy to old PM data area


; Copy VMFLT_DVECS

	 lea	 esi,IGROUP:VMFLT_DVECS ; Get offset in IGROUP of VMFLT_DVECS
	 add	 esi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(32/4)*(type VMFLT_DVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy to old PM data area


; Copy LAST_DPMI_xS

	 mov	 ax,LAST_DPMI_DS ; Get the value
S32	 stos	 AGROUP:[edi].ELO ; Copy to old PM data area
	 mov	 ax,LAST_DPMI_ES ; Get the value
S32	 stos	 AGROUP:[edi].ELO ; Copy to old PM data area
	 mov	 ax,LAST_DPMI_FS ; Get the value
S32	 stos	 AGROUP:[edi].ELO ; Copy to old PM data area
	 mov	 ax,LAST_DPMI_GS ; Get the value
S32	 stos	 AGROUP:[edi].ELO ; Copy to old PM data area


; Copy I31_FLAG

	 mov	 ax,I31_FLAG	; Get the value
S32	 stos	 AGROUP:[edi].ELO ; Copy to old PM data area


; Copy DPMITYPEIG

	 mov	 al,DPMITYPEIG	; Get the value
S32	 stos	 AGROUP:[edi].LO ; Copy to old PM data area


; Copy DBGCTL

	 mov	 al,DBGCTL	; Get the value
S32	 stos	 AGROUP:[edi].LO ; Copy to old PM data area


; Copy DBGSTA

	 mov	 al,DBGSTA	; Get the value
S32	 stos	 AGROUP:[edi].LO ; Copy to old PM data area


; Copy DBGREGS

	 lea	 esi,IGROUP:DBGREGS ; Get offset in IGROUP of DBGREGS
	 add	 esi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,4*(type DBGREGS)/4 ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy to old PM data area


; Copy DBGDR7

	 mov	 eax,DBGDR7	; Get the value
S32	 stos	 AGROUP:[edi].EDD ; Copy to old PM data area


; Check on whether or not we should re-initialize

	 cmp	 [ebp].SAVEOLDPM_FLG,1 ; Should we?
	 jne	 near ptr DPMIFN_SAVEOLDPM_EXIT ; Jump if not

; Re-initialize SIRBCUR to default values

	 test	 CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	 jz	 short DPMIFN_SAVEOLDPM_XP5 ; Jump if not

	 mov	 eax,PVMTSS	; Get offset in PGROUP of the 1st TSS
	 mov	 esi,PGROUP:[eax].DPTSS_LaSIRBCUR ; Get linear address of the
				; default SIRB table
	 mov	 edi,LaSIRBCUR	; Get linear address of current SIRB table

	 mov	 ecx,(256/8)/4	; Get size of table in dwords
	 push	 edi		; Save for a moment
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy it
	 pop	 edi		; Restore

; Set SIRBCUR values for INTs 23h and 24h at AGROUP:EDI using SIRB_MAC

	 SIRB_MAC 23		; INT  23h - Ctrl-Break termination
	 SIRB_MAC 24		; ...  24h - Critical Error termination

	 FIXICALL PGROUP:SIRBCUR2B,DTE_CS2 ; Copy SIRBCUR values to SIRB
DPMIFN_SAVEOLDPM_XP5:

; Re-initialize DPMI_PPIHOOK

	 lea	 edi,DPMI_PPIHOOK ; Get offset in PGROUP of primary PM
				; interrupt hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,256/(8*4)	; Get size of table in dwords
	 xor	 eax,eax	; Initial value
     rep stos	 AGROUP:[edi].EDD ; Zero it


; Re-initialize DPMI_CPIHOOK

	 lea	 edi,DPMI_CPIHOOK ; Get offset in PGROUP of current PM
				; interrupt hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,256/(8*4)	; Get size of table in dwords
	 xor	 eax,eax	; Initial value
     rep stos	 AGROUP:[edi].EDD ; Zero it


; Re-initialize DPMI_CPFHOOK

	 lea	 edi,DPMI_CPFHOOK ; Get offset in PGROUP of current PM
				; fault hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,32/(8*4)	; Get size of table in dwords
	 xor	 eax,eax	; Initial value
     rep stos	 AGROUP:[edi].EDD ; Zero it


; Re-initialize DPMI_CVFHOOK

	 lea	 edi,DPMI_CVFHOOK ; Get offset in PGROUP of current VM
				; fault hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,32/(8*4)	; Get size of table in dwords
	 xor	 eax,eax	; Initial value
     rep stos	 AGROUP:[edi].EDD ; Zero it


; Re-initialize DPMI_PPIHOOK

	 lea	 edi,DPMI_PPIHOOK ; Get offset in PGROUP of primary PM
				; interrupt hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,256/(8*4)	; Get size of table in dwords
	 xor	 eax,eax	; Initial value
     rep stos	 AGROUP:[edi].EDD ; Zero it


; Re-initialize DPMI_PVFHOOK

	 lea	 edi,DPMI_PVFHOOK ; Get offset in PGROUP of primary VM
				; fault hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,32/(8*4)	; Get size of table in dwords
	 xor	 eax,eax	; Initial value
     rep stos	 AGROUP:[edi].EDD ; Zero it


; Re-initialize PMINT_xVECS

	 mov	 es,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  es:IGROUP	; Tell the assembler about it

	 mov	 cx,256 	; # entries in PMINT_xVECS
	 xor	 si,si		; Initialize index into PMINT_FVECS
	 xor	 di,di		; Initialize index into PMINT_DVECS
	 mov	 eax,PMIDEF00	; Get initial routine offset
DPMIFN_SAVEOLDPM_NEXT_IDEF:
	 mov	 PMINT_FVECS.FSEL[si],DTE_DPMIDEF or (@DPMI_CPL shl $PL) ; Set selector
	 mov	 PMINT_DVECS.VSEG[di],DTE_DPMIDEF or (@DPMI_CPL shl $PL) ; ...

	 mov	 PMINT_FVECS.FOFF[si],eax ; Set offset
	 mov	 PMINT_DVECS.VOFF[di],ax  ; ...

	 add	 si,type PMINT_FVECS ; Skip to next entry
	 add	 di,type PMINT_DVECS ; ...
	 add	 eax,@PMxDEF_LEN ; ...

	 loop	 DPMIFN_SAVEOLDPM_NEXT_IDEF ; Jump if more handlers


; Re-initialize PMFLT_xVECS and VMFLT_xVECS

	 mov	 cx,32		; # entries in PMFLT_xVECS & VMFLT_xVECS
	 xor	 si,si		; Initialize index into PMFLT_FVECS & VMFLT_FVECS
	 xor	 di,di		; Initialize index into PMFLT_DVECS & VMFLT_DVECS
	 mov	 eax,PMFDEF00	; Get initial routine offset
	 mov	 ebx,VMFDEF00	; ...
DPMIFN_SAVEOLDPM_NEXT_FDEF:
	 mov	 PMFLT_FVECS.FSEL[si],DTE_DPMIDEF or (@DPMI_CPL shl $PL) ; Set selector
	 mov	 PMFLT_DVECS.VSEG[di],DTE_DPMIDEF or (@DPMI_CPL shl $PL) ; ...

	 mov	 VMFLT_FVECS.FSEL[si],DTE_DPMIDEF or (@DPMI_CPL shl $PL) ; Set selector
	 mov	 VMFLT_DVECS.VSEG[di],DTE_DPMIDEF or (@DPMI_CPL shl $PL) ; ...

	 mov	 PMFLT_FVECS.FOFF[si],eax ; Set offset
	 mov	 PMFLT_DVECS.VOFF[di],ax  ; ...

	 mov	 VMFLT_FVECS.FOFF[si],ebx ; Set offset
	 mov	 VMFLT_DVECS.VOFF[di],bx  ; ...

	 add	 si,type PMFLT_FVECS ; Skip to next entry
	 add	 di,type PMFLT_DVECS ; ...
	 add	 eax,@PMxDEF_LEN ; ...
	 add	 ebx,@PMxDEF_LEN ; ...

	 loop	 DPMIFN_SAVEOLDPM_NEXT_FDEF ; Jump if more handlers


; Re-initialize LAST_DPMI_xS

	 mov	 LAST_DPMI_DS,0 ; Clear for next time
	 mov	 LAST_DPMI_ES,0 ; ...
	 mov	 LAST_DPMI_FS,0 ; ...
	 mov	 LAST_DPMI_GS,0 ; ...


; Re-initialize I31_FLAG

	 and	 I31_FLAG,@I31_PERCLIENT ; Isolate DPMI client-specific flags


; Re-initialize DPMITYPEIG

	 mov	 al,DPMITYPE	; Get the new value
	 mov	 DPMITYPEIG,al	; Save to check the next time


; Re-initialize DBGDR7

	 mov	 DBGDR7,0	; Clear for next time


; Re-initialize DR0-3 and DR7

	 xor	 eax,eax	; A convenient zero
	 mov	 ebx,dr7	; Get debug control register

	 bt	 DBGCTL,0	; Test bit for DR0
	 jnc	 short @F	; Jump if inactive

	 mov	 dr0,eax	; Clear for next time
	 and	 ebx,not ((mask $LEN0) or (mask $RW0) or (mask $G0) or (mask $L0))
@@:
	 bt	 DBGCTL,1	; Test bit for DR1
	 jnc	 short @F	; Jump if inactive

	 mov	 dr1,eax	; Clear for next time
	 and	 ebx,not ((mask $LEN1) or (mask $RW1) or (mask $G1) or (mask $L1))
@@:
	 bt	 DBGCTL,2	; Test bit for DR2
	 jnc	 short @F	; Jump if inactive

	 mov	 dr2,eax	; Clear for next time
	 and	 ebx,not ((mask $LEN2) or (mask $RW2) or (mask $G2) or (mask $L2))
@@:
	 bt	 DBGCTL,3	; Test bit for DR3
	 jnc	 short @F	; Jump if inactive

	 mov	 dr3,eax	; Clear for next time
	 and	 ebx,not ((mask $LEN3) or (mask $RW3) or (mask $G3) or (mask $L3))
@@:
	 mov	 dr7,ebx	; Clear for next time


; Re-initialize DBGCTL

	 mov	 DBGCTL,0	; Clear for next time


; Re-initialize DBGSTA

	 mov	 DBGSTA,0	; Clear for next time


; Re-initialize DBGREGS

	 lea	 edi,IGROUP:DBGREGS ; Get offset in IGROUP of DBGREGS
	 mov	 ecx,4*(type DBGREGS)/4 ; Get size in dwords
	 xor	 eax,eax	; Initialize to this value
     rep stos	 DBGREGS[edi]	; Clear for next time
DPMIFN_SAVEOLDPM_EXIT:
	 REGREST <es>		; Restore selector
	 assume  es:IGROUP	; Tell the assembler about it
	 popad			; Restore all EGP registers

	 pop	 ebp		; Restore

	 ret	 2+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_SAVEOLDPM endp		; End DPMIFN_SAVEOLDPM procedure
	 NPPROC  CHECK_ENVCFG -- Check For This Program In CFG File
	 assume  ds:PGROUP,es:IGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Check for This program in the CFG file and set a bit if found.

On entry:

AX	 =	 environment selector
EDX	 =	 offset in PGROUP of DPTSS_STR
SS:EBP	 ==>	 INTXX_STR

On exit:

AX	 =	 environment selector (possibly now at PL1)

|

	 REGSAVE <ebx,ecx,si,edi,es> ; Save registers

	 mov	 es,ax		; Address the environment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 edi,edi	; Start at the beginning
	 mov	 cx,@ENVLEN	; Get selector length
	 mov	 al,0		; Search for the end
@@:
	 cmp	 al,1		; Ensure ZF=0 in case CX=0
   repne scasb			; Scan for end of next string
	 jne	 near ptr CHECK_ENVCFG_DONE ; Jump if not found

	 scasb			; Izit double zero at end of environment?
	 jne	 short @B	; Jump if not

; We're at the end of the environment

	 add	 di,2		; Skip over the string counter
	 sub	 cx,2		; Account for it
	 jbe	 near ptr CHECK_ENVCFG_DONE ; Jump if nothing remains

; Search for the end of the program name

   repne scasb		       ; Scan for end of program name
	 jne	 near ptr CHECK_ENVCFG_DONE ; Jump if not found???

	 dec	 di		; Back off to trailing zero
	 mov	 cx,di		; Copy offset so far as the length

; Back up to the start of the program name

	 mov	 al,'\'         ; Look for trailing backslash
	 std			; Search backwards
   repne scasb			; Search for it
	 cld			; Restore
	 jne	 near ptr CHECK_ENVCFG_DONE ; Jump if not found???

	 add	 di,2		; Skip over backslash to start of program name

; Check for KRNL386.EXE which requries special treatment

	 cmp	 cx,KRNL386_LEN ; Use the smaller
	 jb	 near ptr CHECK_ENVCFG_DONE ; Jump if file is smaller

	 mov	 cx,KRNL386_LEN ; Use length of program name

	 push	 ds		; Save for a moment

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 lea	 si,KRNL386	; DS:SI ==> KRNL386 name
    repe cmps	 KRNL386,es:[di].LO ; Compare 'em
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jne	 near ptr CHECK_ENVCFG_DONE ; Jump if no match

	 or	 PDC_FLAG,mask $I31_KRNL ; Mark as Windows DPMI client

; Tell SWAT that Windows is coming up (sort of) so it can
; ignore ARPLs and 0F FFs

	 push	 SWATCODE.FSEL	; Get SWAT code selector
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	 or	 AGROUP:[eax].MD_ATTR,@MD_WIN3 ; Mark as Windows active

; If this is Windows 3.00, we must change all our PL3 values to PL1
; Alas, I can't seem to find a way to distinguish Windows 3.00 from
; later versions except by a few bytes preceding the return address
; in the caller's code segment.  Here we go again.

	 movzx	 ebx,[ebp].INTXX_CS ; Get caller's CS
	 shl	 ebx,4-0	; Convert from paras to bytes
	 movzx	 eax,[ebp].INTXX_EIP.ELO ; Get caller's IP

	 cmp	 AGROUP:[ebx+eax-1Dh].EDD,7203F980h ; Izit CMP CL,03//JC xxx ?
	 jne	 near ptr CHECK_ENVCFG_DONE ; Jump if not

	 or	 PDC_FLAG,mask $I31_WIN3 ; Mark as Windows 3.00

; Change DPL of DTE_DPMIDEF from @DPMI_CPL to 1

	 and	 DESC_TAB.DTE_DPMIDEF.DESC_ACCESS,not (mask $DT_DPL) ; Clear DPL bits
	 or	 DESC_TAB.DTE_DPMIDEF.DESC_ACCESS,1 shl $DT_DPL ; DPL=1

; Change DPL of DTE_DATALPM from @DPMI_CPL to 1

	 mov	 edi,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT
	 and	 AGROUP:[edi].DTE_DATALPM.DESC_ACCESS,not (mask $DT_DPL) ; Clear DPL bits
	 or	 AGROUP:[edi].DTE_DATALPM.DESC_ACCESS,1 shl $DT_DPL ; DPL=1

; Change RPL of default interrupt handlers from @DPMI_CPL to 1

	 mov	 ax,1 shl $PL	; RPL=1
	 call	 DPMIFN_SETRPL	; Set RPL of default interrupt handlers to AX

; Change LPM stack selector RPL from @DPMI_CPL to 1

	 and	 LPMSTK_SEL,not (mask $PL) ; Clear the PL bits
	 or	 LPMSTK_SEL,1 shl $PL ; RPL=1

; Set DPMI client RPL and DPL to 1

	 mov	 DPMI_CODE,CPL0_CODE or (1 shl $DT_DPL)
	 mov	 DPMI_DATA,CPL0_DATA or (1 shl $DT_DPL)
	 mov	 DPMI_IDEF,DTE_DPMIDEF or (1 shl $PL)
	 mov	 DPMI_CPL,1 shl $PL
	 mov	 DPMI_DPL,1 shl $DT_DPL

; Change LDT entries from @DPMI_CPL to 1

	 mov	 ebx,PGROUP:[edx].DPTSS_LaLDT ; Get linear address of DPMI LDT
	 mov	 ecx,PGROUP:[edx].DPTSS_LDT_SIZ ; Get byte size of DPMI LDT (/8)
	 shr	 ecx,3-0	; Convert from bytes to qwords (# LDTEs)
CHECK_ENVCFG_NEXT:
	 mov	 al,AGROUP:[ebx].DESC_ACCESS ; Get the A/R byte

	 and	 al,mask $DT_DPL ; Isolate the DPL

	 cmp	 al,@DPMI_CPL shl $DT_DPL ; Izit at DPMI DPL?
	 jne	 short @F	; Jump if not

	 and	 AGROUP:[ebx].DESC_ACCESS,not (mask $DT_DPL) ; Clear DPL bits
	 or	 AGROUP:[ebx].DESC_ACCESS,1 shl $DT_DPL ; Set to DPL1
@@:
	 add	 ebx,type DESC_STR ; Skip to next LDTE

	 loop	 CHECK_ENVCFG_NEXT ; Jump if more LDTEs to check

; Change DPTSS selectors RPL from @DPMI_CPL to 1

	 mov	 ax,PGROUP:[edx].TSS_CS ; Get caller's CS
	 and	 ax,not (mask $PL) ; Clear PL bits
	 or	 ax,1 shl $PL	; CPL = 1
	 mov	 PGROUP:[edx].TSS_CS,ax ; Restore

	 mov	 ax,PGROUP:[edx].DPTSS_DTA_FVEC.FSEL ; Get caller's DTA
	 and	 ax,not (mask $PL) ; Clear PL bits
	 or	 ax,1 shl $PL	; CPL = 1
	 mov	 PGROUP:[edx].DPTSS_DTA_FVEC.FSEL,ax ; Restore

	 mov	 ax,PGROUP:[edx].TSS_DS ; Get caller's DS
	 and	 ax,not (mask $PL) ; Clear PL bits
	 or	 ax,1 shl $PL	; CPL = 1
	 mov	 PGROUP:[edx].TSS_DS,ax ; Restore

	 mov	 ax,PGROUP:[edx].TSS_ES ; Get caller's ES
	 and	 ax,not (mask $PL) ; Clear PL bits
	 or	 ax,1 shl $PL	; CPL = 1
	 mov	 PGROUP:[edx].TSS_ES,ax ; Restore

	 mov	 ax,PGROUP:[edx].TSS_SS ; Get caller's SS
	 and	 ax,not (mask $PL) ; Clear PL bits
	 or	 ax,1 shl $PL	; CPL = 1
	 mov	 PGROUP:[edx].TSS_SS,ax ; Restore

; Return AX as caller's environment selector at RPL1

	 mov	 ax,es		; Get caller's environment selector
	 and	 ax,not (mask $PL) ; Clear PL bits
	 or	 ax,1 shl $PL	; CPL = 1

	 jmp	 short CHECK_ENVCFG_EXIT ; Join common exit code

CHECK_ENVCFG_DONE:
	 mov	 ax,es		; Get caller's environment selector
CHECK_ENVCFG_EXIT:
	 REGREST <es,edi,si,ecx,ebx> ; Restore
	 assume  es:IGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ENVCFG endp		; End CHECK_ENVCFG procedure
	 NPPROC  DPMIFN_RESTWIN -- Restore PL State to Normal After Windows
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Restore the PL state to normal after Windows ran at PL1.

|

	 REGSAVE <eax,ebx,cx>	; Save registers

; Tell SWAT that Windows is no longer active

	 push	 SWATCODE.FSEL	; Get SWAT code selector
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	 and	 AGROUP:[eax].MD_ATTR,not @MD_WIN3 ; Mark as Windows inactive

; Change DPL of DTE_DPMIDEF from 1 to @DPMI_CPL

	 and	 DESC_TAB.DTE_DPMIDEF.DESC_ACCESS,not (mask $DT_DPL) ; Clear DPL bits
	 or	 DESC_TAB.DTE_DPMIDEF.DESC_ACCESS,@DPMI_CPL shl $DT_DPL ; DPL=@DPMI_CPL

; Reset LPM stack selector RPL to @DPMI_CPL

	 and	 LPMSTK_SEL,not (mask $PL) ; Clear the PL bits
	 or	 LPMSTK_SEL,@DPMI_CPL shl $PL ; RPL=@DPMI_CPL

; Reset RPL and DPL in case it was KRNL386

	 mov	 DPMI_CODE,CPL0_CODE or (@DPMI_CPL shl $DT_DPL)
	 mov	 DPMI_DATA,CPL0_DATA or (@DPMI_CPL shl $DT_DPL)
	 mov	 DPMI_IDEF,DTE_DPMIDEF or (@DPMI_CPL shl $PL)
	 mov	 DPMI_CPL,@DPMI_CPL shl $PL
	 mov	 DPMI_DPL,@DPMI_CPL shl $DT_DPL

; Note we don't need to change the LDTE RPLs as we're about to abandon
; that LDT

	 REGREST <cx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_RESTWIN endp		; End DPMIFN_RESTWIN procedure
	 NPPROC  DPMIFN_SETRPL -- DPMI Function to Set RPL of Default Interrupt Handlers
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set RPL of default interrupt handlers

On entry:

AX	 =	 new RPL

|

	 REGSAVE <cx,si,di,ds>	; Save registers

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 mov	 cx,256 	; # entries in PMINT_xVECS
	 xor	 si,si		; Initialize index into PMINT_FVECS
	 xor	 di,di		; Initialize index into PMINT_DVECS
DPMIFN_SETRPL_NEXT_IDEF:
	 and	 PMINT_FVECS.FSEL[si],not (mask $PL) ; Clear PL bits
	 and	 PMINT_DVECS.VSEG[di],not (mask $PL) ; ...

	 or	 PMINT_FVECS.FSEL[si],ax ; RPL=AX
	 or	 PMINT_DVECS.VSEG[di],ax ; ...

	 add	 si,type PMINT_FVECS ; Skip to next entry
	 add	 di,type PMINT_DVECS ; ...

	 loop	 DPMIFN_SETRPL_NEXT_IDEF ; Jump if more handlers

	 mov	 cx,32		; # entries in PMFLT_xVECS & VMFLT_xVECS
	 xor	 si,si		; Initialize index into PMFLT_FVECS & VMFLT_FVECS
	 xor	 di,di		; Initialize index into PMFLT_DVECS & VMFLT_DVECS
DPMIFN_SETRPL_NEXT_FDEF:
	 and	 PMFLT_FVECS.FSEL[si],not (mask $PL) ; Clear PL bits
	 and	 PMFLT_DVECS.VSEG[di],not (mask $PL) ; ...

	 and	 VMFLT_FVECS.FSEL[si],not (mask $PL) ; Clear PL bits
	 and	 VMFLT_DVECS.VSEG[di],not (mask $PL) ; ...

	 or	 PMFLT_FVECS.FSEL[si],ax ; RPL=AX
	 or	 PMFLT_DVECS.VSEG[di],ax ; ...

	 or	 VMFLT_FVECS.FSEL[si],ax ; RPL=AX
	 or	 VMFLT_DVECS.VSEG[di],ax ; ...

	 add	 si,type PMFLT_FVECS ; Skip to next entry
	 add	 di,type PMFLT_DVECS ; ...

	 loop	 DPMIFN_SETRPL_NEXT_FDEF ; Jump if more handlers

	 REGREST <ds,di,si,cx>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_SETRPL endp		; End DPMIFN_SETRPL procedure
	 NPPROC  DPMIFN_FREEMEM -- Free Allocated Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Free memory allocated to this DPMI client

|

	 REGSAVE <eax,ecx,edx,edi> ; Save registers

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS

	 mov	 ecx,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EDI ==> DPMI memory
				; handle table
	 and	 edi,edi	; Izit initialized as yet?
	 jz	 near ptr DPMIFN_FREEMEM_EXIT ; Jump if not

	 mov	 ax,VM2PM_TSS	; Get the current TSS selector
DPMIFN_FREEMEM_NEXT:
	 cmp	 AGROUP:[edi].DPMIHNDL_LEN,0 ; Izit a valid entry?
	 je	 short DPMIFN_FREEMEM_LOOP ; Jump if not

	 cmp	 ax,AGROUP:[edi].DPMIHNDL_TSS ; Izit the same client?
	 jne	 short DPMIFN_FREEMEM_LOOP ; Jump if not

	 test	 DPM_FLAG,mask $DPM_DPMITERM ; Should we tell anybody about this?
	 jz	 short @F	; Jump if not

	 int	 01h		; Call our debugger
@@:

; Deallocate the memory

	 push	 AGROUP:[edi].DPMIHNDL_LEN ; Pass byte length
	 push	 AGROUP:[edi].DPMIHNDL_LA ; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:

; Free the corresponding selector (if any)

	 cmp	 AGROUP:[edi].DPMIHNDL_SEL,0 ; Izit valid?
	 je	 short @F	; Jump if not

	 push	 AGROUP:[edi].DPMIHNDL_SEL ; Get the selector
	 call	 CLR_LDT	; Free this LDT selector
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:
	 mov	 AGROUP:[edi].DPMIHNDL_LEN,0 ; Free the handle
DPMIFN_FREEMEM_LOOP:
	 add	 edi,type DPMIHNDL_STR ; Skip to next entry

	 loopd	 DPMIFN_FREEMEM_NEXT ; Jump if more handles to check

; Free the DPMI memory handle table itself

	 mov	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 imul	 eax,type DPMIHNDL_STR ; Convert from struc to bytes
	 add	 eax,@DPMI_BOUND-1 ; Round up to next
	 and	 eax,not (@DPMI_BOUND-1) ; ... boundary for ALLOCMEM

	 push	 eax		; Pass byte length
	 push	 PGROUP:[edx].DPTSS_LaDPMIHNDL ; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:
	 mov	 PGROUP:[edx].DPTSS_LaDPMIHNDL,0 ; Mark as not initialized
DPMIFN_FREEMEM_EXIT:
	 REGREST <edi,edx,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_FREEMEM endp		; End DPMIFN_FREEMEM procedure
	 NPPROC  DPMIFN_RESTDYN -- Restore Data In Dynamic Save Area
	 assume  ds:PGROUP,es:IGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Restore data in dynamic save area

The structure of the dynamic save area is described in QMAX_DYN.INC

|

	 pushad 		; Save all EGP registers

	 mov	 bx,VM2PM_TSS	; Get the current TSS selector
	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 mov	 esi,PGROUP:[edx].DPTSS_DYN ; Get linear address of dynamic save area

	 and	 esi,esi	; Izit initialized as yet?
	 jz	 near ptr DPMIFN_RESTDYN_EXIT ; Jump if not

	 mov	 edi,esi	; Save for later use
DPMIFN_RESTDYN_NEXT:
	 cmp	 AGROUP:[esi].DYNHDR_FN,@DYNFN_EOL ; Izit End-of-the-line?
	 je	 near ptr DPMIFN_RESTDYN_DONE ; Jump if so

	 cmp	 AGROUP:[esi].DYNHDR_FN,@DYNFN_DEL ; Izit deleted?
	 je	 near ptr DPMIFN_RESTDYN_LOOP ; Jump if so

	 cmp	 bx,AGROUP:[esi].DYNHDR_TSS ; Izit the same TSS?
	 jne	 near ptr DPMIFN_RESTDYN_LOOP ; Jump if not

; The following code is commented out because when we save
; (and later restore) a VMIV some DPMI clients (at least
; Lotus 1-2-3 v3.1) has already put its handler in place
; before issuing this call and we see the new handler only,
; not the old one.  Thus, we can't restore the old one.
; Restoring VMIVs is the client's responsibility, not ours,
; but I put in this code originally knowing how well programs
; clean up after themselves.  In fact, Lotus 1-2-3 v3.1 hooks
; INT 00h and never restores it.  Moreover, they hook INT 00h
; before entering PM through us so we can't even save the original
; value at that point.	So, I decided that we shouldn't bother
; with this kind of cleanup.  Damn the torpedoes, ...

; VMIV cleanup, Part II:  Well, now that we're trying to excise
; faulting DPMI clients who exit out of order, I think it's a
; good idea to cleanup after DPMI clients who terminate by way
; of a fault.

	 cmp	 AGROUP:[esi].DYNHDR_FN,@DYNFN_VMIV ; Izit VMIV function code?
	 jne	 short DPMIFN_RESTDYN_XVMIV ; Jump if not

	 test	 I31_FLAG,mask $I31_FAULT ; Did we terminate because of a fault?
	 jz	 short @F	; Jump if not

; Restore the original handler

	 mov	 edx,AGROUP:[esi].DYNVMIV_VEC ; Get original handler
	 movzx	 eax,AGROUP:[esi].DYNVMIV_NUM ; Get interrupt #

	 assume  gs:INTVEC	; Tell the assembler about it
	 mov	 INT00_VEC[eax*(type INT00_VEC)],edx ; Restore
	 assume  gs:AGROUP	; Tell the assembler about it
@@:
	 jmp	 short DPMIFN_RESTDYN_DEL ; Join common delete code

DPMIFN_RESTDYN_XVMIV:
	 cmp	 AGROUP:[esi].DYNHDR_FN,@DYNFN_P2L ; Izit GETP2L function code?
	 jne	 short DPMIFN_RESTDYN_XP2L ; Jump if not

; The following test is commented out because in the DPMI 0.9 spec
; the client has no way to free this mapping.
;;;;;;;;
;;;;;;;; test	 DPM_FLAG,mask $DPM_DPMITERM ; Should we tell anybody about this?
;;;;;;;; jz	 short @F	; Jump if not
;;;;;;;;
;;;;;;;; int	 01h		; Call our debugger
;;; @@:

; Free the PTEs

	 mov	 eax,AGROUP:[esi].DYNP2L_OFF ; Get offset in PGROUP of 1st PTE
	 sub	 eax,DPMIPDIR_OFF ; Less offset in PGROUP of DPMI PDIRs
				; to get offset (/4)
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	 add	 eax,LaDPMIPDIRMEM ; Plus linear address of memory mapped by
				; first DPMI page directory (/4MB)
	 or	 eax,@PTE_URP	; Mark as User/Read-write/Present
	 and	 eax,not (mask $PTE_US) ; Mark as unallocated

	 mov	 edx,AGROUP:[esi].DYNP2L_OFF ; Get offset in PGROUP of 1st PTE
	 mov	 ecx,AGROUP:[esi].DYNP2L_LEN ; Get # PTEs to free
@@:
	 mov	 PGROUP:[edx],eax ; Mark as available
	 add	 eax,CON4KB	; Skip to next PTE
	 add	 edx,4		; Skip to next PTE

	 loopd	 @B		; Jump if more PTEs to free

	 jmp	 short DPMIFN_RESTDYN_DEL ; Join common delete code

DPMIFN_RESTDYN_XP2L:
	 int	 03h		; Call our debugger (unknown function code)






DPMIFN_RESTDYN_DEL:
	 mov	 AGROUP:[esi].DYNHDR_FN,@DYNFN_DEL ; Mark as deleted
DPMIFN_RESTDYN_LOOP:
	 movzx	 eax,AGROUP:[esi].DYNHDR_LEN ; Get byte length of this entry
	 add	 esi,eax	; Skip to next entry

	 jmp	 DPMIFN_RESTDYN_NEXT ; Go around again

DPMIFN_RESTDYN_DONE:

; Deallocate dynamic save area

	 push	 DPMIDYN_SIZ	; Pass byte length
	 push	 edi		; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if no error

	 int	 03h		; Call our debugger
@@:
	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 PGROUP:[edx].DPTSS_DYN,0 ; Mark as not initialized
DPMIFN_RESTDYN_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_RESTDYN endp		; End DPMIFN_RESTDYN procedure
	 NPPROC  DPMIFN_RESTOLDPM -- Restore Data In Old PM Data Area
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore data in old PM data area

The structure of the old PM data area is

SIRBCUR
DPMI_CPIHOOK
DPMI_CPFHOOK
DPMI_CVFHOOK
PMINT_FVECS
PMINT_DVECS
PMFLT_FVECS
PMFLT_DVECS
VMFLT_FVECS
VMFLT_DVECS
LAST_DPMI_DS
LAST_DPMI_ES
LAST_DPMI_FS
LAST_DPMI_GS
I31_FLAG
DPMITYPE
DBGCTL
DBGSTA
DBGREGS

If any fields are added/deleted from this list, be sure to update
DPMIFN_SAVEOLDPM as well as the size calculations in QMAX_ARG.ASM in
the CHECK_ARGS_VALIDxx section.

|

RESTOLDPM_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
RESTOLDPM_TSS dd ?		; Offset in PGROUP of TSS to use
RESTOLDPM_FLG dw ?		; Flags:
				;   Bit 0:  1 = we're terminating
RESTOLDPM_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,esi,edi,es,fs> ; Save registers

	 mov	 es,SEL_4GB	; Get AGROUP data selector at PL0
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 fs,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  fs:IGROUP	; Tell the assembler about it

	 mov	 eax,[ebp].RESTOLDPM_TSS ; Get offset in PGROUP of TSS to use
	 mov	 esi,PGROUP:[eax].DPTSS_OLDPM ; Get linear address of old PM data area


; Restore SIRBCUR

	 test	 CPUFET_FLAG,mask $CPUFET_VME ; Is VME supported?
	 jz	 short @F	; Jump if not

	 mov	 eax,PGROUP:[eax].DPTSS_LaSIRBCUR ; Get previous address
	 mov	 LaSIRBCUR,eax	; Save as new linear address
	 add	 esi,256/8	; Skip over SIRBCUR table

	 FIXICALL PGROUP:SIRBCUR2B,DTE_CS2 ; Copy SIRBCUR values to SIRB
@@:


; Restore DPMI_CPIHOOK

	 lea	 edi,DPMI_CPIHOOK ; Get offset in PGROUP of current PM
				; interrupt hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,256/(8*4)	; Get size of table in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy from old PM data area


; Restore DPMI_CPFHOOK

	 lea	 edi,DPMI_CPFHOOK ; Get offset in PGROUP of current PM
				; fault hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,32/(8*4)	; Get size of table in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy from old PM data area


; Restore DPMI_CVFHOOK

	 lea	 edi,DPMI_CVFHOOK ; Get offset in PGROUP of current VM
				; fault hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,32/(8*4)	; Get size of table in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy from old PM data area


; If we're terminating, we have a new primary client and
; we need to copy DPMI_CxxHOOK to DPMI_PxxHOOK.

	 test	 [ebp].RESTOLDPM_FLG,@BIT0 ; Are we terminating?
	 jz	 short DPMIFN_RESTOLDPM1 ; Jump if not

	 push	 esi		; Save for a moment

	 lea	 esi,DPMI_CPIHOOK ; Get offset in PGROUP of current PM
				; interrupt hook bitmap
	 add	 esi,PRGBASE	; Get base linear address of PGROUP

	 lea	 edi,DPMI_PPIHOOK ; Get offset in PGROUP of primary PM
				; interrupt hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,256/(8*4)	; Get size of table in dwords
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy it

	 lea	 esi,DPMI_CVFHOOK ; Get offset in PGROUP of current VM
				; fault hook bitmap
	 add	 esi,PRGBASE	; Get base linear address of PGROUP

	 lea	 edi,DPMI_PVFHOOK ; Get offset in PGROUP of primary VM
				; fault hook bitmap
	 add	 edi,PRGBASE	; Get base linear address of PGROUP
	 mov	 ecx,32/(8*4)	; Get size of table in dwords
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy it

	 pop	 esi		; Restore
DPMIFN_RESTOLDPM1:

; Restore PMINT_FVECS

	 lea	 edi,IGROUP:PMINT_FVECS ; Get offset in IGROUP of PMINT_FVECS
	 add	 edi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(256/4)*(type PMINT_FVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy from old PM data area


; Restore PMINT_DVECS

	 lea	 edi,IGROUP:PMINT_DVECS ; Get offset in IGROUP of PMINT_DVECS
	 add	 edi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(256/4)*(type PMINT_DVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy from old PM data area


; Restore PMFLT_FVECS

	 lea	 edi,IGROUP:PMFLT_FVECS ; Get offset in IGROUP of PMFLT_FVECS
	 add	 edi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(32/4)*(type PMFLT_FVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy from old PM data area


; Restore PMFLT_DVECS

	 lea	 edi,IGROUP:PMFLT_DVECS ; Get offset in IGROUP of PMFLT_DVECS
	 add	 edi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(32/4)*(type PMFLT_DVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy from old PM data area


; Restore VMFLT_FVECS

	 lea	 edi,IGROUP:VMFLT_FVECS ; Get offset in IGROUP of VMFLT_FVECS
	 add	 edi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(32/4)*(type VMFLT_FVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy from old PM data area


; Restore VMFLT_DVECS

	 lea	 edi,IGROUP:VMFLT_DVECS ; Get offset in IGROUP of VMFLT_DVECS
	 add	 edi,IGRBASE	; Get base linear address of IGROUP
	 mov	 ecx,(32/4)*(type VMFLT_DVECS) ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy from old PM data area


; Restore LAST_DPMI_xS

	 lods	 AGROUP:[esi].ELO ; Get LAST_DPMI_DS value
	 mov	 LAST_DPMI_DS,ax ; Restore
	 lods	 AGROUP:[esi].ELO ; Get LAST_DPMI_ES value
	 mov	 LAST_DPMI_ES,ax ; Restore
	 lods	 AGROUP:[esi].ELO ; Get LAST_DPMI_FS value
	 mov	 LAST_DPMI_FS,ax ; Restore
	 lods	 AGROUP:[esi].ELO ; Get LAST_DPMI_GS value
	 mov	 LAST_DPMI_GS,ax ; Restore


; Restore I31_FLAG

	 lods	 AGROUP:[esi].ELO ; Get I31_FLAG value
	 mov	 I31_FLAG,ax	; Restore


; Restore DPMITYPE and DPMITYPEIG

	 lods	 AGROUP:[esi].LO ; Get DPMITYPE value
	 mov	 DPMITYPE,al	; Restore
	 mov	 DPMITYPEIG,al	; ...


; Restore DBGCTL

	 lods	 AGROUP:[esi].LO ; Get DBGCTL value
	 mov	 DBGCTL,al	; Restore


; Restore DBGSTA

	 lods	 AGROUP:[esi].LO ; Get DBGSTA value
	 mov	 DBGSTA,al	; Restore


; Restore DBGREGS

	 lea	 edi,IGROUP:DBGREGS ; Get offset in IGROUP of DBGREGS
	 add	 edi,IGRBASE	; Plus base linear address of IGROUP
	 mov	 ecx,4*(type DBGREGS)/4 ; Get size in dwords

S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy from old PM data area


; Restore DBGDR7

	 lods	 AGROUP:[esi].EDD ; Get DBGDR7 value
	 mov	 DBGDR7,eax	; Restore


; Restore DR0-3 and DR7

	 mov	 ecx,dr7	; Get debug control register

	 bt	 DBGCTL,0	; Test bit for DR0
	 jnc	 short @F	; Jump if not active

	 mov	 eax,DBGREGS[0*(type DBGREGS)] ; Get linear address
	 mov	 dr0,eax	; Restore
	 and	 ecx,not ((mask $LEN0) or (mask $RW0) or (mask $G0) or (mask $L0))
@@:
	 bt	 DBGCTL,1	; Test bit for DR1
	 jnc	 short @F	; Jump if not active

	 mov	 eax,DBGREGS[1*(type DBGREGS)] ; Get linear address
	 mov	 dr1,eax	; Restore
	 and	 ecx,not ((mask $LEN1) or (mask $RW1) or (mask $G1) or (mask $L1))
@@:
	 bt	 DBGCTL,2	; Test bit for DR2
	 jnc	 short @F	; Jump if not active

	 mov	 eax,DBGREGS[2*(type DBGREGS)] ; Get linear address
	 mov	 dr2,eax	; Restore
	 and	 ecx,not ((mask $LEN2) or (mask $RW2) or (mask $G2) or (mask $L2))
@@:
	 bt	 DBGCTL,3	; Test bit for DR3
	 jnc	 short @F	; Jump if not active

	 mov	 eax,DBGREGS[3*(type DBGREGS)] ; Get linear address
	 mov	 dr3,eax	; Restore
	 and	 ecx,not ((mask $LEN3) or (mask $RW3) or (mask $G3) or (mask $L3))
@@:
	 or	 ecx,DBGDR7	; Get active DR7 bits
	 mov	 dr7,ecx	; Tell the CPU about it

	 REGREST <fs,es,edi,esi,ecx,eax> ; Restore
	 assume  es:IGROUP,fs:nothing ; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_RESTOLDPM endp		; End DPMIFN_RESTOLDPM procedure
	 NPPROC  DPMIFN_FAULT -- Display Error Message If Fault
	 assume  ds:PGROUP,es:IGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Display error message if fault

On entry:

EDX	 =	 previous PCURTSS
SS:EBP	 ==>	 INTXX_STR

|

	 REGSAVE <eax,cx,dx,si,di,es> ; Save registers

	 test	 I31_FLAG,mask $I31_FAULT ; Did we terminate because of a fault?
	 jz	 near ptr DPMIFN_FAULT_EXIT ; Jump if not

	 mov	 es,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  es:FGROUP	; Tell the assembler about it

; Format CS:EIP into the message

	 mov	 eax,[ebp].INTXX_EIP ; Get EIP from stack
	 lea	 di,FGROUP:MSG_DPMIADDROFF ; ES:DI ==> place to put result
	 FIXICALL PGROUP:FDD2HEX,DTE_CS2 ; Convert EAX to hex at ES:DI

	 mov	 ax,[ebp].INTXX_CS ; Get CS from stack
	 lea	 di,FGROUP:MSG_DPMIADDRSEL ; ES:DI ==> place to put result
	 FIXICALL PGROUP:FDW2HEX,DTE_CS2 ; Convert AX to hex at ES:DI

	 mov	 al,':'         ; Assume VM

	 test	 [ebp].INTXX_EFL.EHI.LO,mask $VM ; In VM86 mode?
	 jnz	 short @F	; Jump if so

	 mov	 al,'|'         ; It's PM
@@:
	 mov	 MSG_DPMIADDRSEP,al ; Save as separator in message

; If we've wound back to the first TSS (PVMTSS), we might not have
; a valid stack (SS:SP) to use to reflect the INT 10hs to VM.  In
; this case, use the stack from the HPDA from old TSS.

	 mov	 eax,PVMTSS	; Get offset in PGROUP of the 1st TSS

	 cmp	 eax,PCURTSS	; Izit the current TSS?
	 jne	 short DPMIFN_FAULT1 ; Jump if not

	 push	 PGROUP:[eax].DPTSS_VMSTKSEG ; Save old SS
	 push	 PGROUP:[eax].DPTSS_VMSTKOFF ; ...     SP
	 push	 LCL_FLAG	; Save old flags

	 test	 LCL_FLAG,@LCL_DPMI ; Do we have a local HPDA?
	 jnz	 short DPMIFN_FAULT1 ; Jump if so

	 or	 LCL_FLAG,@LCL_DPMI ; Now we do

	 mov	 cx,PGROUP:[edx].DPTSS_VMSTKSEG ; Get new SS
	 mov	 PGROUP:[eax].DPTSS_VMSTKSEG,cx ; Save in VM TSS

	 mov	 cx,PGROUP:[edx].DPTSS_VMSTKOFF ; Get new SP
	 mov	 PGROUP:[eax].DPTSS_VMSTKOFF,cx ; Save in VM TSS
DPMIFN_FAULT1:

; Display DPMI fault title

@DPMIMSG_ROW equ 18h		; Starting row for DPMI message display
@DPMIMSG_COL equ 00h		; ...	   col ...

	 mov	 dh,@DPMIMSG_ROW ; Start at this row
	 mov	 dl,@DPMIMSG_COL ; Start at this col
	 push	 es		; Pass message selector
	 push	 offset FGROUP:MSG_TITLE ; Pass message offset
	 FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it

; Display specific fault error message

	 mov	 dx,-1		; Use current position
	 push	 es		; Pass message selector
	 push	 DPMIMSG	; Pass message offset
	 FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it

	 test	 DB3_FLAG,@DB3_XADDR ; Display this message?
	 jnz	 short @F	; Jump if not

; Display address

;;;;;;;; mov	 dx,-1		; Use current position
	 push	 es		; Pass message selector
	 push	 offset FGROUP:MSG_DPMIADDR ; Pass message offset
	 FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it
@@:

; Display next part of message

;;;;;;;; mov	 dx,-1		; Use current position
	 push	 es		; Pass message selector
	 push	 offset FGROUP:MSG_TITL2 ; Pass message offset
	 FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it
	 push	 es		; Pass message selector
	 push	 offset FGROUP:MSG_TITL3 ; Pass message offset
	 FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it
	 push	 es		; Pass message selector
	 push	 offset FGROUP:MSG_TITL4 ; Pass message offset
	 FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it

; Convert the application name to uppercase

	 lea	 si,FGROUP:MSG_DPMIAPPLNAME ; ES:SI ==> message to display
	 lods	 MSG_DPMIAPPLNAME.LENTXT_LEN ; Get and skip over string length
	 mov	 cx,ax		; Copy to loop counter
	 jcxz	 DPMIFN_FAULT_MSG_XAPPL ; Jump if it's empty????
DPMIFN_FAULT_MSG_NEXT:
	 lods	 MSG_DPMIAPPLNAME.LO ; Get next byte

	 cmp	 al,'a'         ; Check against lower limit
	 jb	 short @F	; Jump if too small

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short @F	; Jump if too large

	 add	 al,'A'-'a'     ; Convert to uppercase
	 mov	 FGROUP:[si-1],al ; Save back into application name
@@:
	 loop	 DPMIFN_FAULT_MSG_NEXT ; Jump if more characters to convert

; Display name of last application

;;;;;;;; mov	 dx,-1		; Use current position
	 push	 es		; Pass message selector
	 push	 offset FGROUP:MSG_DPMIAPPLNAME ; Pass message offset
	 FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it

	 jmp	 short DPMIFN_FAULT_MSG_XAPPL1 ; Join common code

DPMIFN_FAULT_MSG_XAPPL:

; Application name unknown:  tell 'em so

;;;;;;;; mov	 dx,-1		; Use current position
	 push	 es		; Pass message selector
	 push	 offset FGROUP:MSG_APPLUNK ; Pass message offset
	 FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it
DPMIFN_FAULT_MSG_XAPPL1:

; Display next part of message

;;;;;;;; mov	 dx,-1		; Use current position
	 push	 es		; Pass message selector
	 push	 offset FGROUP:MSG_TAIL ; Pass message offset
	 FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it

; Display key wait message

;;;;;;;; mov	 dx,-1		; Use current position
	 push	 es		; Pass message selector
	 push	 offset FGROUP:MSG_DPMIPRESS ; Pass message offset
	 FIXICALL PGROUP:FDISP_STR,DTE_CS2 ; Display it

; Purge the keyboard buffer and wait for a key press -- discard the key

	 FIXICALL PGROUP:FKEYWAIT,DTE_CS2 ; Wait for an acknowledgement

	 call	 DPMIFN_NEWLINE ; Start on a new line

; If we've wound back to the first TSS (PVMTSS), restore the original
; VM TSS values

	 mov	 eax,PVMTSS	; Get offset in PGROUP of the 1st TSS

	 cmp	 eax,PCURTSS	; Izit the current TSS?
	 jne	 short DPMIFN_FAULT2 ; Jump if not

	 pop	 LCL_FLAG	; Restore flags
	 pop	 PGROUP:[eax].DPTSS_VMSTKOFF ; Restore SP
	 pop	 PGROUP:[eax].DPTSS_VMSTKSEG ; ...     SS
DPMIFN_FAULT2:
DPMIFN_FAULT_EXIT:
	 REGREST <es,di,si,dx,cx,eax> ; Restore
	 assume  es:IGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_FAULT endp		; End DPMIFN_FAULT procedure

	 align	 4		; Ensure dword alignment

ICODE	 ends			; End ICODE segment

endif				; IF @OEM_DPMI

	 MEND			; End QMAX_O31 module

;' $Header:   P:/PVCS/MAX/386MAX/QMAX_IDT.ASV   1.2   30 May 1997 10:45:04   BOB  $
	 title	 QMAX_IDT -- 386MAX IDT Routines
	 page	 58,122
	 name	 QMAX_IDT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-2003 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,   public, class 'prog'
	       Program segment HICODE,dword-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned,  public, class 'ecode'
	       Program segment DEBUG, byte-aligned,   public, class 'ecode'
	       Data    segment EDATA, dword-aligned,  public, class 'edata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned,  public, class 'fixup'
	       Group SGROUP:
	       Program segment SCODE, para-aligned,   public, class 'scode'
	       Group IGROUP:
	       Program segment ICODE, dword-aligned,  public, class 'icode'
	       Data    segment IDATA, dword-aligned,  public, class 'idata'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned,  public, class 'jcode'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p

.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include 8253.INC
	 include 8255.INC
	 include 8259.INC
	 include CMOS.INC
	 include CPUFLAGS.INC
	 include INTVEC.INC
	 include DEVDRV.INC
	 include MASM5.MAC
	 include BIOSDATA.INC
	 include LOADALL.INC
	 include MSR.INC
	 include VDS.INC
	 include ALLMEM.INC
	 include KEYCALL.INC
	 include VIDCALL.INC
	 include VIDATTR.INC
	 include ASCII.INC
	 include OPCODES.INC

	 include PDTGRP.INC
	 include QMAX_CFG.INC
	 include QMAX_DTE.INC
	 include QMAX_FIL.INC
	 include QMAX_I31.INC
	 include QMAX_OEM.INC
	 include QMAX_STK.INC
	 include QMAX_SWT.INC	; For SWAT
	 include QMAX_TRC.INC
	 include QMAXDPMI.INC
	 include QMAX_TSS.INC

if DBG_TRACE
	 include DMA.INC
	 include BITFLAGS.INC
endif				; IF DBG_TRACE
.list

PGROUP	 group	 CODE,HICODE,ECODE,DEBUG,EDATA
FGROUP	 group	 FDATA
SGROUP	 group	 SCODE
IGROUP	 group	 ICODE,IDATA
JGROUP	 group	 JCODE


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 PPI_S2C:near
	 extrn	 GOREAL_LOW:near
	 extrn	 GOVM86_LOW:near
	 extrn	 DISABLE_NMI:near
	 extrn	 HARDRET:far

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 DB3_FLAG:word
	 include QMAX_DB3.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

if @OEM_WIN3
;;;;;;;; extrn	 LOWWIN3_CB:byte
endif				; IF @OEM_WIN3
	 extrn	 SWPSIZE:word
	 extrn	 PLOWSTKZ:word
	 extrn	 FARJMP_VEC:dword
	 extrn	 STKPTR:dword

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

	 extrn	 SBIOSDATA:word
	 extrn	 XBIOS_SRC:dword
	 extrn	 I13CNT:word

HICODE	 ends			; End HICODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

if @OEM_DPMI
	 extrn	 I31_FLAG:word

	 extrn	 VMM_FLAG:word
	 include QMAX_VMM.INC

	 extrn	 LaInDOS:dword

	 extrn	 SEL_DSHI:word
	 extrn	 SEL_4GB3:word
	 extrn	 SEL_DSIG3:word
	 extrn	 VM2PM_TSS:word
	 extrn	 PPL0STK_DNRM:dword
	 extrn	 PPL0STK_DERR:dword
	 extrn	 DPMITYPE:byte
	 extrn	 DPMICNT0D:word
	 extrn	 DPMICNT0E:word
	 extrn	 DPMI_HWSP:byte
	 extrn	 DPMI_HW:byte
	 extrn	 DPMI_CPIHOOK:byte
	 extrn	 DPMI_PPIHOOK:byte
	 extrn	 DPMI_CPFHOOK:byte
	 extrn	 DPMI_PVFHOOK:byte
	 extrn	 DPMIMSG:word
	 extrn	 LAST_DPMI_DS:word
	 extrn	 LAST_DPMI_ES:word
	 extrn	 LAST_DPMI_FS:word
	 extrn	 LAST_DPMI_GS:word

if @OEM_VIRTUALMEM
	 extrn	 PageFaultActive:byte
endif
endif				; IF @OEM_DPMI
	 extrn	 SEL_DS3:word
	 extrn	 SEL_DSFG3:word
	 extrn	 DESC_TAB:qword
;;;;;;;; extrn	 PGDT_LLO:fword
	 extrn	 HIMEM_CS:word
	 extrn	 OLDINT_VECS:dword,NOLDINTS:abs
	 extrn	 CON64KB:dword
	 extrn	 PPL0STK_NRM:dword
	 extrn	 PPL0STK_ERR:dword
	 extrn	 PPL0STK_MIN:dword
	 extrn	 PPL0STK_MAX:dword
	 extrn	 PVMTSS:dword
	 extrn	 PPRMTSS:dword
	 extrn	 PCURTSS:dword
	 extrn	 SWAP_SRC:dword
	 extrn	 LOWOFF:dword
;;;;;;;; extrn	 PRGPDT:dword
if @OEM_DMA
	 extrn	 DMA_CHAN:byte
endif				; IF @OEM_DMA
	 extrn	 SWATCODE:fword
	 extrn	 SWATMSG:fword
	 extrn	 MSG_APPLNAME:tbyte
	 extrn	 SAVE_EBX:dword

	 extrn	 LAST_EMSHNDL:word
	 extrn	 LOTUS_EMSHNDL:word

	 extrn	 LPMSTK_FVEC:fword

if DBG_TRACE
;;;;;;;; extrn	 DMA_ISTATE:byte
endif				; IF DBG_TRACE
	 extrn	 DSTK_HWINTS:byte
	 extrn	 DSTK_CNT:word
	 extrn	 DSTK_FLAG:byte

	 public  LaDSTK_TAB,PDSTKCOM
LaDSTK_TAB dd	 ?		; Linear address of DSTK_TAB
PDSTKCOM dd	 SGROUP:DSTKCOM ; Address of common return routine
				; The segment portion is filled in during LOADHI

	 public  SAVE_EAX,SAVE_EFL
SAVE_EAX dd	 ?		; Save area for EAX in HARDINT and INTFF
SAVE_EFL dd	 ?		; ...		EFL ...

	 public  LOWSTK_FVEC
LOWSTK_FVEC label fword 	; Pointer to low memory stack
	 dd	 ?		; 32-bit offset
	 dw	 DTE_SS 	; ...selector

	 public  LCL_SAVE_PTR
LCL_SAVE_PTR dd  ?		; Original SAVE_PTR

IDT_MAC  macro	 N
	 IDT_STR <PGROUP:INTPROC&N,DTE_CS2,,CPL0_INTR3 or CPL3,0>
	 endm			; IDT_MAC

	 public  IDT_DESC
	 align	 4		; Ensure IDT is dword-aligned for best performance
IDT_DESC label	 qword		; Interrupt descriptor table

CNT	 =	 0
.xlist
	 rept	 100h		; Define all interrupts

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 IDT_MAC %N
CNT	 =	 CNT+1

	 endm			; REPT 100h
.list
	 public  IDT_DESC_LEN
IDT_DESC_LEN equ $-IDT_DESC	; Length of the IDT


IDT_MAC2 macro	 N

	 dw	 PGROUP:INTPROC&N

	 endm			; IDT_MAC2

	 public  IDT_TAB
IDT_TAB  label	 word

.xlist
CNT	 =	 0
	 rept	 100h

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 IDT_MAC2 %N
CNT	 =	 CNT+1
	 endm			; REPT 100h
.list

	 public  LCL_DTR
LCL_DTR  df	 ?		; Local copy of GDTR and IDTR

	 public  HARDCNT
HARDCNT  dw	 0		; Hard interrupt count

	 public  HEXTABLE
HEXTABLE db	 '0123456789ABCDEF'

	 public  LAST_INTCOM,LAST_INTFLG
LAST_INTCOM dd	 ?		; Offset of bottom of last INTCOM interrupt frame
LAST_INTFLG dd	 ?		; ...and its flag

	 public  VIDMODE
VIDMODE  db	 ?		; Video mode

EDATA	 ends			; End EDATA segment


DEBUG	 segment use16 byte public 'ecode' ; Start DEBUG segment
	 assume  cs:PGROUP

	 extrn	 DW2HEX:near
	 extrn	 FDD2HEX:far

DEBUG	 ends			; End DEBUG segment


SCODE	 segment use16 para public 'scode' ; Start SCODE segment
	 assume  cs:SGROUP,ds:SGROUP

	 public  @QMAX_IDT_SCODE
@QMAX_IDT_SCODE:		; Mark module start in .MAP file

	 public  SCODE_INI
SCODE_INI label  byte

	 public  DSTK_OLDSTK,DSTK_TAB_NXTOFF
DSTK_OLDSTK dd	 ?		; Temporary save area for old SS:SP
DSTK_TAB_NXTOFF dw ?		; Next offset byte after DSTK_TAB

	 DDALIGN SCODE_INI	; Ensure on dword boundary

	 NPPROC  DSTKCOM -- Common Return Routine For DOS Stacks Handling
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:SGROUP
COMMENT|

Common return routine for DOS stacks handling

On entry:

SS:SP	 ==>	 DSTKCOM_STR
IF	 =	 0
TF	 =	 0

|

DSTKCOM_STR struc

DSTKCOM_OFF dw	 ?		; DSTK_TAB_STR entry offset
DSTKCOM_SIG dd	 @STKSIG	; Stack signature

DSTKCOM_STR ends


DSTKCOM2_STR struc

	 dw	 ?		; Caller's BP
DSTKCOM2_NXT db  (type DSTKCOM_STR) dup (?) ; The remainder of the stack

DSTKCOM2_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

; SS:BP  ==>	 DSTKCOM2_STR

	 REGSAVE <eax,bx,si>	; Save registers

	 mov	 bx,[bp].DSTKCOM2_NXT.DSTKCOM_OFF ; Get offset of DSTK_TAB_STR entry
	 mov	 eax,SGROUP:DSTK_TAB[bx].DSTK_TAB_OLDSTKVEC ; Get old SS:SP
	 mov	 DSTK_OLDSTK,eax ; Save to restore later

; Mark lower adjacent (possibly overflowed) stacks as available

DSTKCOM_NEXT:
	 mov	 SGROUP:DSTK_TAB[bx].DSTK_TAB_OLDSTKVEC,@STKAVL ; Mark as available

	 add	 bx,type DSTK_TAB_STR ; Skip to next entry

	 cmp	 bx,DSTK_TAB_NXTOFF ; Izit still in range?
	 jae	 short DSTKCOM_EXIT ; Jump if not

	 mov	 si,SGROUP:DSTK_TAB[bx].DSTK_TAB_DOSSTKVEC.VOFF ; Get TOS offset
	 mov	 eax,@STKSIG	; Get stack signature
	 xchg	 eax,SGROUP:[si-(type DSTKCOM_SIG)].EDD ; Swap signatures

	 cmp	 eax,@STKSIG	; Izit overflowed?
	 jne	 short DSTKCOM_NEXT ; Jump if so
DSTKCOM_EXIT:
	 REGREST <si,bx,eax>	; Restore

	 pop	 bp		; Restore

	 lss	 sp,DSTK_OLDSTK ; Load up old SS:SP
	 assume  ss:nothing	; Tell the assembler about it

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DSTKCOM  endp			; End DSTKCOM procedure

	 assume  ds:SGROUP	; Tell the assembler about it

	 public  SCODE_END
	 DPALIGN SCODE_INI	; Ensure on para boundary
SCODE_END label  byte		; Last byte used in segment

	 public  DSTK_TAB
DSTK_TAB label	 tbyte

; The DSTK_TAB_STR is allocated dynamically starting here
; followed by the DOS stacks.

SCODE	 ends			; End SCODE segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MSG_L01:tbyte
	 extrn	 MSG_L03:tbyte
	 extrn	 MSG_L06:tbyte
	 extrn	 MSG_L08:tbyte
	 extrn	 MSG_L0A:tbyte
	 extrn	 MSG_L0B:tbyte
	 extrn	 MSG_L0C:tbyte
	 extrn	 L0CNUM:byte
	 extrn	 L0CNUM2:byte
	 extrn	 MSG_L12:tbyte
	 extrn	 L12NUM:tbyte

if @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 MSG_NF:tbyte
	 extrn	 MSG_PRIVOP:tbyte
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 MSG_TITLE:tbyte
	 extrn	 MSG_LADR:tbyte
	 extrn	 MSG_TITL2:tbyte
	 extrn	 MSG_TITL3:tbyte
	 extrn	 MSG_TITL4:tbyte
	 extrn	 MSG_APPLUNK:tbyte
	 extrn	 MSG_TAIL:tbyte
	 extrn	 MSG_LKEY:tbyte

	 extrn	 MSG_ADDROFF:byte
	 extrn	 MSG_ADDRSEP:byte
	 extrn	 MSG_ADDRSEG:byte

	 extrn	 MSG_REBOOT:tbyte
	 extrn	 DPMIMSG_LOW:tbyte

	 public  MAXINT_VECS
MAXINT_VECS dd	 256 dup (?)	; IDT after 386MAX has initialized

	 public  LOTUS_SIGN
LOTUS_SIGN db 'Copyright (C) 1987-1990 by Rational Systems, Inc.'
LOTUS_SIGN_LEN equ $-LOTUS_SIGN ; Length of ...

if @OEM_DEBUG
	 public  INT01MSG,INT03MSG,INT06MSG,INT08MSG
	 public  INT0AMSG,INT0BMSG,INT0CMSG,INT11MSG
	 public  INT12MSG
INT01MSG db	 'INT 01 exception',0
INT03MSG db	 'INT 03 exception ',0
INT06MSG db	 'INT 06 exception ',0
INT08MSG db	 'Double Fault',0
INT0AMSG db	 'Invalid TSS Fault',0
INT0BMSG db	 'Segment Not Present',0
INT0CMSG db	 'Stack fault',0
INT11MSG db	 'Alignment Check',0
INT12MSG db	 'Machine Check',0
endif				; IF @OEM_DEBUG

FDATA	 ends			; End FDATA segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 public  @QMAX_IDT_JCODE
@QMAX_IDT_JCODE:		; Mark module start in .MAP file

	 FPPROC  INT12 -- Machine Check Interrupt
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Machine check interrupt for P5 without error code on stack.
Note that this routine is installed only if we're on a P5
so we don't need to check for that condition.

If it's not a Machine Check, continue with INTPROC12.
If we're called from VM,
   If there's a DPMI client active and the primary client has hooked
     this exception, give it a crack at it.
   Otherwise, abort.
If we're called from PM and there's a DPMI client active,
   give it a crack at this exception.
Otherwise, abort.

|


	 REGSAVE <eax,ecx,edx>	; Save registers

	 mov	 ecx,@MSR_MCADDR ; Get index for Machine Check Address
	 RDMSR			; Read MSR into EDX:EAX

	 push	 edx		; Save 'em for a moment
	 push	 eax		; ...

	 mov	 ecx,@MSR_MCTYPE ; Get index for Machine Check Type
	 RDMSR			; Read MSR into EDX:EAX

	 pop	 ecx		; Restore to EDX:ECX
	 pop	 edx		; ...

	 test	 eax,mask $MCT_CHK ; Izit a Machine Check?
	 jz	 short INT12_DONE ; Jump if not (note CF=0)

; Format the address in EDX:ECX for display

	 REGSAVE <di,es>	; Save for a moment

	 mov	 es,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  es:FGROUP	; Tell the assembler about it

	 mov	 eax,edx	; Get the value to format
	 lea	 di,L12NUM-16	; ES:DI ==> save area
	 FIXICALL PGROUP:FDD2HEX,DTE_CS2 ; Convert EAX to hex at ES:DI

	 mov	 eax,ecx	; Get the value to format
	 lea	 di,L12NUM-8	; ES:DI ==> save area
	 FIXICALL PGROUP:FDD2HEX,DTE_CS2 ; Convert EAX to hex at ES:DI

	 REGREST <es,di>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 stc			; Mark as Machine Check
INT12_DONE:
	 REGREST <edx,ecx,eax>	; Restore
	 jnc	 short INT12_ORIG ; Jump if not Machine Check

if @OEM_DPMI

; The stack is mapped by NRM_STR

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jnz	 short INT12_UGH ; Jump if so

; The stack is mapped by INTDPI_STR if we came from DPMI
; or NRM_STR if we came from MAX

	 test	 [esp].NRM_CS,mask $PL ; Izit PL0?
	 jz	 short INT12_FLTRETPM ; Jump if so (ignore it)

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 short INT12_FLTRETPM ; Jump if no DPMI clients active

	 PUSHD	 0		; Put pseudo-error code onto stack

; The stack is mapped by INTDPF_STR if we came from DPMI
; or FLT_STR if we came from MAX

	 mov	 [esp].INTDPF_INTNO,4*12h + offset PGROUP:INTPROC00Z ; Mark as INT 02h

	 FIXIJMP PGROUP:INTCOM_DPMI_FAULT,DTE_CS2 ; Join common code

INT12_FLTRETPM:
endif				; IF @OEM_DPMI
INT12_UGH:
	 PUSHD	 0		; Pseudo-error code

	 pushad 		; Save all EGP registers

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 si,4*12h	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_L12 ; Offset of message to display to user

if @OEM_DEBUG
	 lea	 di,FGROUP:INT12MSG ; Offset of message to display on screen
endif				; IF @OEM_DEBUG

	 FIXIJMP PGROUP:INTXXCOM,DTE_CS2 ; Join common error code

INT12_ORIG:
	 FIXIJMP PGROUP:INTPROC12,DTE_CS2 ; Continue with next handler

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT12	 endp			; End INT12 procedure
	 FPPROC  INT81 -- Interrupt Used by Lotus
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we're called by Lotus 1-2-3 version 3.1, preserve
all EGP registers

|

; If we're called from VM, the stack at this point is mapped by INTCOM_STR

; Note that we can't use (offset PGROUP:INTPROC81) as
; MASM 5.10 doesn't handle that correctly.

	 push	 DTE_CS2	; Pass target segment
	 assume  ds:PGROUP	; Tell the assembler about it
	 push	 offset ds:INTPROC81 ; Pass target offset
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 short LOTUS_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT81	 endp			; End INT81 procedure
	 FPPROC  INT82 -- Interrupt Used by Lotus
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we're called by Lotus 1-2-3 version 3.1, preserve
all EGP registers

|

; If we're called from VM, the stack at this point is mapped by INTCOM_STR

; Note that we can't use (offset PGROUP:INTPROC82) as
; MASM 5.10 doesn't handle that correctly.

	 push	 DTE_CS2	; Pass target segment
	 assume  ds:PGROUP	; Tell the assembler about it
	 push	 offset ds:INTPROC82 ; Pass target offset
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 short LOTUS_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT82	 endp			; End INT82 procedure
	 FPPROC  INT83 -- Interrupt Used by Lotus
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we're called by Lotus 1-2-3 version 3.1, preserve
all EGP registers

|

; If we're called from VM, the stack at this point is mapped by INTCOM_STR

; Note that we can't use (offset PGROUP:INTPROC83) as
; MASM 5.10 doesn't handle that correctly.

	 push	 DTE_CS2	; Pass target segment
	 assume  ds:PGROUP	; Tell the assembler about it
	 push	 offset ds:INTPROC83 ; Pass target offset
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 short LOTUS_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT83	 endp			; End INT83 procedure
	 FPPROC  INT84 -- Interrupt Used by Lotus
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we're called by Lotus 1-2-3 version 3.1, preserve
all EGP registers

|

; If we're called from VM, the stack at this point is mapped by INTCOM_STR

; Note that we can't use (offset PGROUP:INTPROC84) as
; MASM 5.10 doesn't handle that correctly.

	 push	 DTE_CS2	; Pass target segment
	 assume  ds:PGROUP	; Tell the assembler about it
	 push	 offset ds:INTPROC84 ; Pass target offset
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 short LOTUS_COM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT84	 endp			; End INT84 procedure
	 NPPROC  LOTUS_COM -- Common Code To Detect Lotus 1-2-3
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Common code to detect Lotus 1-2-3

|

; The stack at this point is mapped by LC1_STR

LC1_STR  struc

LC1_INT  dd	 ?		; INT xxh address
LC1_NXT  db	 (type INTCOM_STR) dup (?) ; The rest of the stack

LC1_STR  ends

	 test	 [esp].LC1_NXT.INTCOM_EFL.EHI,mask $VM ; Are we called from VM 86 mode?
	 jz	 short LOTUS_COM_EXIT ; Jump if not

	 cmp	 LOTUS_EMSHNDL,0 ; Is Lotus 1-2-3 still active?
	 je	 short LOTUS_COM_EXIT ; Jump if not

; Because of a bug in Lotus 1-2-3 Version 3.1 where they don't
; preserve the contents of the high-order word in certain 32-bit
; registers, we must do that here.

	 pushad 		; Save all EGP registers

; The stack at this point is mapped by LC2_STR

LC2_STR  struc

	 db	 (type PUSHAD_STR) dup (?) ; Caller's EGP registers
LC2_NXT  db	 (type LC1_STR) dup (?) ; The rest of the stack

LC2_STR  ends

; Simulate a 32-bit interrupt frame

; Note that we cannot use either of
;;;;;;;; push	 dword ptr (offset IGROUP:LOTUS_COM_HARDRET)
;;;;;;;; push	 dword ptr (offset cs:LOTUS_COM_HARDRET)
; as MASM 5.10 doesn't handle either form correctly.

	 pushfd 		; Pass EFL
	 PUSHD	 cs		; ...  CS
	 PUSHD	 <offset cs:LOTUS_COM_HARDRET>
	 dw	 0		; 32-bit extension for PUSHD

LC3_STR  struc

	 dd	 ?		; Return EIP
	 dw	 ?,?		; ...	 CS w/filler
	 dd	 ?		; ...	 EFL
LC3_NXT  db	 (type LC2_STR) dup (?) ; The rest of the stack

LC3_STR  ends


; Because we came from VM and the VM stack may be reused, ensure we
; protect it via LAST_INTCOM

	 assume  ss:PGROUP	; Tell the assembler about it

	 lea	 eax,[esp].LC3_NXT.LC2_NXT.LC1_NXT.INTCOM_EIP ; Get INTCOM-restartable point
	 xchg	 eax,LAST_INTCOM ; Swap with the previous one
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 eax,0		; Save previous flag
	 mov	 [esp].LC3_NXT.LC2_NXT.LC1_NXT.INTCOM_ICOMLO,ax ; Save to restore later
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [esp].LC3_NXT.LC2_NXT.LC1_NXT.INTCOM_ICOMHI,ax ; Save to restore later

	 jmp	 [esp].LC3_NXT.LC2_NXT.LC1_INT ; Join common INT xxh code

LOTUS_COM_HARDRET:

; The stack at this point is mapped by LC2_STR

	 mov	 ax,[esp].LC2_NXT.LC1_NXT.INTCOM_ICOMHI ; Get previous INTCOM-restartable point
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[esp].LC2_NXT.LC1_NXT.INTCOM_ICOMLO ; Get previous INTCOM-restartable point
	 btr	 ax,$INTCOM_VAL ; Move previous setting to CF
	 setc	 LAST_INTFLG.LO ; Move previous setting to memory
	 mov	 LAST_INTCOM,eax ; Restore original address

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [E?X+E?X*?]
; The stack at this point is mapped by LC1_STR

	 add	 esp,type LC1_INT ; Strip off INT xxh address

	 iretd			; Return to caller

LOTUS_COM_EXIT:
	 retf			; Continue with normal interrupt handler

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOTUS_COM endp			; End LOTUS_COM procedure
	 FPPROC  CHECK_LOTUS -- Check For Lotus 1-2-3
	 assume  ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check for Lotus 1-2-3 when called via VCPI DE01 call.
Actually we detect any Rational Systems DOS Extender with a
1990 copyright date.

On entry:

SS:EBP	 ==>	 INTXX_STR

On exit:

Set LOTUS_EMSHNDL if it's Lotus 1-2-3.

|

	 REGSAVE <ecx,esi,edi,ds> ; Save registers

	 mov	 ds,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  ds:FGROUP	; Tell the assembler about it

; Our recognition method is to check for the Rational Systems
; copyright string pointed to by the word at offset DS:0030h.

	 movzx	 edi,[ebp].INTXX_DS ; Get caller's DS
	 shl	 edi,4-0	; Convert from paras to bytes
	 movzx	 ecx,AGROUP:[edi+0030h].ELO ; Get word ptr at DS:0030h
	 add	 edi,ecx	; AGROUP:EDI ==> copyright string (if present)

	 lea	 esi,LOTUS_SIGN ; DS:ESI ==> Lotus 1-2-3 signature
	 mov	 ecx,LOTUS_SIGN_LEN ; ECX = # bytes in signature

    repe cmps	 LOTUS_SIGN[esi],AGROUP:[edi].LO ; Izit Lotus 1-2-3?
	 jne	 short CHECK_LOTUS_EXIT ; Jump if not

	 mov	 cx,LAST_EMSHNDL ; Get last EMS handle allocated
	 mov	 LOTUS_EMSHNDL,cx ; Save as the one for Lotus 1-2-3
CHECK_LOTUS_EXIT:
	 REGREST <ds,edi,esi,ecx> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_LOTUS endp		; End CHECK_LOTUS procedure

JCODE	 ends			; End JCODE segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

if @OEM_DPMI
	 extrn	 DPMI_SIMRET:far
	 extrn	 DPMI_INT01:far
	 extrn	 PMINTCOM:far
	 extrn	 PMFLTCOM:far
	 extrn	 VMFLTCOM:far
	 extrn	 FLTPROC_APPL:far
	 extrn	 FLTPROC_ABORT:far
	 extrn	 FLTPROC_VMFULL:far
	 extrn	 FDPMIFN_LMSW:far
	 extrn	 FDPMIFN_LPMSTK:far
endif				; IF @OEM_DPMI

ICODE	 ends			; End ICODE segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

if @OEM_DPMI
	 extrn	 PMFLT_FVECS:fword
endif				; IF @OEM_DPMI

IDATA	 ends			; End IDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_IDT_ECODE
@QMAX_IDT_ECODE:		; Mark module start in .MAP file

	 extrn	 SWAP_MEM:far
	 extrn	 WRAP_DISABLE:near
	 extrn	 WRAP_ENABLE:near
	 extrn	 FLUSH_TLB:near
if @OEM_DMA
	 extrn	 CHECK_PART:near
endif				; IF @OEM_DMA
	 extrn	 LINPHYS:near
	 extrn	 RESET_KEYB:near

if DBG_TRACE
	 extrn	 TRACE:near
endif				; IF DBG_TRACE
	 extrn	 REST_PROT:near

	 align	 4		; Ensure dword alignment
	 FPPROC  INTCOM -- Common Interrupt Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common interrupt handler for all but those handled by INTXXCOM.

On entry:

INTCOM_INTNO has the INT # times 4 + offset PGROUP:INTPROC00Z

Caller's EIP has been incremented past the instruction.

|

	 nop			; Single byte instruction for timing purposes

	 pop	 [esp].INTCOM_INTNO ; Save INT # times 4 + ...

; The following code was used as a substitute for the above instruction
; on A-step 486s which failed to handle POP [ESP+nn] correctly

;;;;;;;; mov	 [esp+2].INTCOM_INTNO,ax ; Save register
;;;;;;;; pop	 ax		; Get interrupt #
;;;;;;;; xchg	 ax,[esp].INTCOM_INTNO ; Swap with old value

if @OEM_DPMI

; See if we're called from a DPMI client (HW-DPMI, SP-DPMI, SW-DPMI)

	 cmp	 esp,PPL0STK_DNRM ; Izit a HW/SW interrupt from a DPMI client?
	 je	 near ptr INTCOM_DPMI_INT ; Jump if so
endif				; IF @OEM_DPMI

if @OEM_DPMI

; We're called from VM  (HW-VM,  SP-VM,  SW-VM)
;		 or MAX (HW-MAX, SP-MAX, SW-MAX)

; The other possibilities (EX-VM, EX-MAX, EX-DPMI) are handled
; elsewhere (INT08, INT0B, INT0C, INT0D, INT0E, INT11, INTXXCOM)

; See if there's a DPMI client active
; If so, we need to check for HW and SP interrupts which must
; be reflected to DPMI clients first.

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 near ptr INTCOM_DPMI_CHK ; Jump if so (check for HW INTs)

	 public  INTCOM_DPMI_CHKRET
INTCOM_DPMI_CHKRET:
endif				; IF @OEM_DPMI

; See if we're called from a hardware interrupt

	 test	 [esp].INTCOM_EFL.EHI.LO,mask $VM ; In VM86 mode?
	 jz	 near ptr HARDINT ; No, so it must have been a hardware interrupt

; Ensure there's room on PL3 stack for CS, IP, and FL

	 sub	 [esp].INTCOM_ESP.ELO,6 ; Make room
	 jc	 near ptr INTCOM_STKOVF ; Not enough room unless SP = 0, 2, or 4
INTCOM1:

; Save CS, IP, and FL on PL3 stack as in a real mode interrupt

	 REGSAVE <eax,ebx,edi>	; Save registers

@PUSHSIZE equ	 4+4+4		; Size on stack of PUSHed registers

; Note that the code at INTCOM_DMA uses AX so we must save it
; on the stack before jumping there

if @OEM_DMA
	 cmp	 DMA_CHAN,0	; Any DMA transfers in progress?
	 jne	 short INTCOM_DMA ; Yes, see if any have terminated
				; All segment registers clobbered
INTCOM_XDMA:
endif				; IF @OEM_DMA

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 bx,[esp+@PUSHSIZE].INTCOM_INTNO ; Get the INT # times 4 + ...
	 sub	 bx,offset PGROUP:INTPROC00Z ; Convert to origin-0, unit 4
	 movzx	 edi,[esp+@PUSHSIZE].INTCOM_SS ; Get stack segment
	 mov	 eax,AGROUP:[bx] ; Get the Segment:Offset
	 shl	 edi,4-0	; Convert from paras to bytes

	 xchg	 ax,[esp+@PUSHSIZE].INTCOM_EIP.ELO ; Swap IPs
	 movzx	 ebx,[esp+@PUSHSIZE].INTCOM_ESP.ELO ; Get caller's ESP
	 mov	 AGROUP:[edi+ebx],ax ; Save on PL3 stack

	 shr	 eax,16 	; Shift segment down to low-order

	 xchg	 ax,[esp+@PUSHSIZE].INTCOM_CS ; Swap CSs
	 inc	 bx		; Account for saved word, emulate 64KB wrap
	 inc	 bx
	 mov	 AGROUP:[edi+ebx],ax ; Save on PL3 stack

	 mov	 ax,[esp+@PUSHSIZE].INTCOM_EFL.ELO ; Get FL (as opposed to EFL)
	 inc	 bx		; Account for saved word, emulate 64KB wrap
	 inc	 bx
	 mov	 AGROUP:[edi+ebx],ax ; Save on PL3 stack

; Turn off trap, interrupt, and nested task flags in PL0 stack

	 and	 [esp+@PUSHSIZE].INTCOM_EFL.ELO,not ((mask $TF) or (mask $IF) or (mask $NT))

	 REGREST <edi,ebx,eax>	; Restore

; "Return" to real interrupt handler

	 test	 GLB_FLAG,@GLB_NMI or @GLB_I01 ; Did an NMI occur or INT 01h?
	 jnz	 near ptr IRETD_COM1 ; Yes, handle it specially
INTCOM_IRETD:
	 iretd			; No, just return as usual

	 assume  ss:nothing	; Tell the assembler about it

if @OEM_DMA
INTCOM_DMA:
	 assume  ss:PGROUP	; Tell the assembler about it

; If we're coming from VM86, save and set LAST_INTCOM

	 test	 [esp+@PUSHSIZE].INTCOM_EFL.EHI,mask $VM ; Izit VM86?
	 jz	 short @F	; Jump if not

	 lea	 eax,[esp+@PUSHSIZE].INTCOM_EIP ; Get INTCOM-restartable point
	 xchg	 eax,LAST_INTCOM ; Swap with the previous one
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 eax,0		; Save previous flag
	 mov	 [esp+@PUSHSIZE].INTCOM_ICOMLO,ax ; Save to restore later
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [esp+@PUSHSIZE].INTCOM_ICOMHI,ax ; Save to restore later
@@:
	 call	 CHECK_PART	; Check on partial DMA transfers in progress
				; ES and FS clobbered
	 cli			; Disallow interrupts

	 test	 [esp+@PUSHSIZE].INTCOM_EFL.EHI,mask $VM ; Izit VM86?
	 jz	 short @F	; Jump if not

	 mov	 ax,[esp+@PUSHSIZE].INTCOM_ICOMHI ; Get previous INTCOM-restartable point
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[esp+@PUSHSIZE].INTCOM_ICOMLO ; Get previous INTCOM-restartable point
	 btr	 ax,$INTCOM_VAL ; Move previous setting to CF
	 setc	 LAST_INTFLG.LO ; Move previous setting to memory
	 mov	 LAST_INTCOM,eax ; Restore original address
@@:
	 assume  ss:nothing	; Tell the assembler about it

	 jmp	 INTCOM_XDMA	; Join common code
endif				; IF @OEM_DMA

; Stack overflow unless SP = 0-6 or SP is on an even boundary and we're not
; debugging that case

INTCOM_STKOVF:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 cmp	 [esp].INTCOM_ESP.ELO,0-6 ; Check caller's SP for original 0
	 je	 near ptr INTCOM1 ; Jump if it's starting at the top

; The stack has wrapped and quite likely there is a bug in the application.
; However, because the 386 in real mode wraps even boundaries into the top
; of the current 64KB segment, we must do the same.  However, if the stack
; is on an odd boundary, there's no hope.

	 test	 DB2_FLAG,@DB2_XWRAP ; See if we're debugging this error
	 jnz	 short @F	; Jump if we are

	 test	 [esp].INTCOM_ESP.ELO.LO,1 ; Check for odd boundary
	 jz	 near ptr INTCOM1  ; Jump if we can white wash the bug
@@:
	 add	 [esp].INTCOM_ESP.ELO,6 ; Restore original value

	 PUSHD	 -2		; Put pseudo-error code onto stack

	 jmp	 near ptr INT0C ; Call it a stack fault


if @OEM_DPMI

; We're called from VM  (HW-VM,  SP-VM,  SW-VM)
;		 or MAX (HW-MAX, SP-MAX, SW-MAX)
; and there's a DPMI client active.
; If this is a HW or special (1Ch, 23h, 24h) interrupt,
; reflect it to the DPMI client.
; Note that 23h and 24h have their own handlers, so we skip them here
; as they have already been presented to any active DPMI clients.

INTCOM_DPMI_CHK:
	 push	 ax		; Save for a moment

	 mov	 ax,[esp+2].INTCOM_INTNO ; Get INT # times 4 + ...
	 sub	 ax,offset PGROUP:INTPROC00Z ; Convert to INT # times 4
	 shr	 ax,2-0 	; Convert from times 4 to times 1

; Check for interrupts from VM or MAX which we must handle specially.
; These include 1Ch, 23h, and 24h as well as master and slave PICs.
; Note that 23h and 24h have their own handlers, so we skip them here
; as they have already been presented to any active DPMI clients.

	 call	 IZIT_PPIHOOK	; Is INT AX hooked by the (active) primary client
				; and isn't INT 23h or 24h?
	 jnc	 short @F	; Jump if not (note CF=0)

	 bt	 DPMI_HWSP.ELO,ax ; Izit HW or SP?
	 jnc	 short @F	; Jump if not (note CF=0)

	 call	 IZIT_REFLINT	; Izit reflectable?
				; Return with CF=1 iff we can pass to client
@@:
	 pop	 ax		; Restore
	 jnc	 short @F	; Jump if not

; Reflect this HW or special interrupt from VM or MAX to the DPMI client
; The stack is mapped by INTCOM_STR if we came from VM
; or NRM_STR if we came from MAX

	 push	 @PMINTCOM_LPM	; Use LPM stack
	 FIXIJMP IGROUP:PMINTCOM,DTE_CSIG ; Jump to common code
@@:

; If this is from MAX, use a separate stack
; as LAST_INTCOM is not necessarily valid

	 test	 [esp].INTCOM_EFL.EHI.LO,mask $VM ; In VM86 mode?
	 jz	 near ptr INTCOM_DPMI_INTMAX ; Jump if not (handle as DPMI interrupt)

	 jmp	 INTCOM_DPMI_CHKRET ; Join common code



DPMI_HARDRET_STR struc

	 dd	 ?		; Return ESP
	 dw	 ?,?		; ...	 SS with filler
	 dw	 ?,?		; ...	 ES ...
	 dw	 ?,?		; ...	 DS ...
	 dw	 ?,?		; ...	 DS ...
	 dw	 ?,?		; ...	 GS ...
DPMI_HARDRET_CNT0E dw ? 	; DPMICNT0E
	 dw	 ?		; DPMICNT0D
	 dd	 ?		; LAST_INTFLG
	 dd	 ?		; LAST_INTCOM
	 df	 ?		; LPMSTK_FVEC
DPMI_HARDRET_NXT db (size INTDPI_STR) dup (?) ; The rest of the stack

DPMI_HARDRET_STR ends

DPMI_HARDRET_REST equ <DPMI_HARDRET_CNT0E> ; Strip stack to this point
				; upon return

DPMI_HARDINT_STR struc

	 dd	 ?		; Return EIP
	 dw	 ?		; ...	 CS
DPMI_HARDINT_INTNO dw ? 	; ...	 INT # times 4 + ...
DPMI_HARDINT_EFL   dd ? 	; ...	 EFL
DPMI_HARDINT_NXT db (size DPMI_HARDRET_STR) dup (?) ; The rest of the stack

DPMI_HARDINT_STR ends


; Return from DPMI HW/SW interrupt

; The stack is mapped by DPMI_HARDRET_STR

	 public  INTCOM_DPMI_HARDRET
INTCOM_DPMI_HARDRET:
	 assume  ss:PGROUP	; Tell the assembler about it

	 mov	 SAVE_EAX,eax	; Save for a moment

; Return flags to caller except for VM, RF, IOPL, IF, and TF

FLMASK	 =	 ((mask $VMHI) or (mask $RFHI) or (mask $IOPL) or (mask $IF) or (mask $TF))

	 pushfd 		; Get our flags
	 pop	 eax		; Copy to save on stack
	 and	 eax,not FLMASK ; VM=RF=IOPL=IF=TF=0
	 and	 [esp].DPMI_HARDRET_NXT.INTDPI_EFL,FLMASK ; Isolate
	 or	 [esp].DPMI_HARDRET_NXT.INTDPI_EFL,eax ; Save as caller's flags

	 and	 ax,not (mask $NT) ; NT=0 for the following IRETD

	 push	 ax		; Save on stack
	 popf			; Put into flags

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 add	 PGROUP:[eax].DPTSS_VMSTKOFF,@HPDAFRM_SIZ ; Strip off a level

	 mov	 eax,SAVE_EAX	; Restore

	 add	 esp,DPMI_HARDRET_REST ; Strip back the stack including
				; GSF, FSF, DSF, ESF, SSF, and ESP

	 REGREST <DPMICNT0E,DPMICNT0D,LAST_INTFLG,LAST_INTCOM> ; Restore

	 pop	 LPMSTK_FVEC.FOFF ; Restore
	 pop	 LPMSTK_FVEC.FSEL ; ...

if @OEM_DPMI
	 push	 PCURTSS	; Pass offset in PGROUP of current TSS
	 FIXICALL IGROUP:FDPMIFN_LMSW,DTE_CSIG ; Put MSW and INT 07h values into effect
endif				; IF @OEM_DPMI

	 iretd			; Return to interrupted code

	 assume  ss:nothing	; Tell the assembler about it


; Hardware/special/software interrupt from a DPMI client or from MAX

	 public  INTCOM_DPMI_INT
	 assume  ss:PGROUP	; Tell the assembler about it
INTCOM_DPMI_INT:

; The stack is mapped by INTDPI_STR if we came from DPMI
; or NRM_STR if we came from MAX
; Note that NRM_INTNO/INTDPI_INTNO is already filled in with the
; INT # times 4 + offset PGROUP:INTPROC00Z

; Save DPMI selectors in case we need them when the DPMI client
; handles a HW- or SP- interrupt

	 mov	 LAST_DPMI_DS,ds ; Save for later use
	 mov	 LAST_DPMI_ES,es ; ...
	 mov	 LAST_DPMI_FS,fs ; ...
	 mov	 LAST_DPMI_GS,gs ; ...

; If this is a hardware interrupt, (and we're lumping special
; interrupts in with this), use the LPM stack
; If this is a software interrupt, use the application stack

	 push	 ax		; Save for a moment

	 mov	 ax,[esp+2].NRM_INTNO ; Get INT # times 4 + ...
	 sub	 ax,offset PGROUP:INTPROC00Z ; Convert to INT # times 4
	 shr	 ax,2-0 	; Convert from times 4 to times 1

; Check for interrupts from a DPMI client which we must handle specially.
; These include 1Ch, 23h, and 24h as well as master and slave PICs.
; Note that 23h and 24h have their own handlers, so we skip them here
; as they have already been presented to any active DPMI clients.

; If it's a HW interrupt, send it to the primary client (if hooked)
; on the LPM stack.
; Otherwise, send it to the current client (if hooked) on the application
; stack.

	 bt	 DPMI_HW.ELO,ax ; Izit HW?
	 jc	 short INTCOM_DPMI_INT_HW ; Jump if so

	 call	 IZIT_CPIHOOK	; Is INT AX hooked by the (active) current client?
	 jnc	 short INTCOM_DPMI_INTRET ; Jump if not

	 mov	 ax,@PMINTCOM_NRM ; Use application stack

	 jmp	 short @F	; Join common code

INTCOM_DPMI_INT_HW:
	 call	 IZIT_PPIHOOK	; Is INT AX hooked by the (active) primary client
				; and isn't INT 23h or 24h?
	 jnc	 short INTCOM_DPMI_INTRET ; Jump if not

	 call	 IZIT_REFLINT	; Izit reflectable?
	 jnc	 short INTCOM_DPMI_INTRET ; Jump if not

	 mov	 ax,@PMINTCOM_LPM ; Use LPM stack
@@:
	 xchg	 ax,[esp]	; Push onto stack, restore old AX
	 FIXIJMP IGROUP:PMINTCOM,DTE_CSIG ; Jump to common code

INTCOM_DPMI_INTRET:
	 pop	 ax		; Restore

; If we return, the client decided to let us handle it
; We reflect it to VM86

; Save variables so we can be re-entrant

	 public  INTCOM_DPMI_INTMAX
INTCOM_DPMI_INTMAX:
	 push	 LPMSTK_FVEC.FSEL ; Save current LPM stack top
	 push	 LPMSTK_FVEC.FOFF ; ...

	 REGSAVE <LAST_INTCOM,LAST_INTFLG,DPMICNT0D,DPMICNT0E> ; Save to restore later

	 mov	 DPMICNT0D,0	; Clear 'em in case we are re-entered
	 mov	 DPMICNT0E,0	; ...

; Setup LAST_INTCOM to use the DPMI client stack in the HPDA

	 PUSHD	 0		; Pseudo-GS
	 PUSHD	 0		; ...	-FS
	 PUSHD	 0		; ...	-DS
	 PUSHD	 0		; ...	-ES

	 mov	 SAVE_EAX,eax	; Save for a moment
	 mov	 SAVE_EBX,ebx	; ...

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 push	 PGROUP:[eax].DPTSS_VMSTKSEG.EDD ; Use as SS w/filler
	 movzx	 ebx,PGROUP:[eax].DPTSS_VMSTKOFF ; Get current offset
	 push	 ebx		; Use as ESP

	 PUSHD	 0		; Return flags holder
	 PUSHD	 cs		; Return selector and INT # ... holder
	 push	 dword ptr (offset cs:INTCOM_DPMI_HARDRET) ; Return EIP

	 sub	 bx,@HPDAFRM_SIZ ; Make room for a level

	 cmp	 bx,PGROUP:[eax].DPTSS_VMSTKBOT ; Izit below the bottom?
	 jb	 near ptr INTCOM_DPMI_INTRET_VMFULL ; Jump if so

	 mov	 PGROUP:[eax].DPTSS_VMSTKOFF,bx ; Make room for a level

; The stack is mapped by DPMI_HARDINT_STR

; Set new LPM stack top for nested callers if it's active
; and we're called from PM, not PL0

	 lea	 eax,[esp].DPMI_HARDINT_NXT.DPMI_HARDRET_NXT.INTDPI_EIP ; SS:EAX ==> INTDPI_STR from PL3
	 push	 eax		; Pass the offset
	 FIXICALL IGROUP:FDPMIFN_LPMSTK,DTE_CSIG ; Save new LPM stack as appropriate

; Use same flags as caller with RF=IF=TF=0
; The caller's flag is at INTCOM_EFL

	 mov	 eax,[esp].DPMI_HARDINT_NXT.DPMI_HARDRET_NXT.INTDPI_EFL ; Get caller's flags
	 and	 eax,not ((mask $RFHI) or (mask $IF) or (mask $TF)) ; RF=IF=TF=0
	 mov	 [esp].DPMI_HARDINT_EFL,eax ; Save in return stack

; Use same INT # times 4 + ... as caller
; The caller's value for this is at INTCOM_INTNO

	 mov	 ax,[esp].DPMI_HARDINT_NXT.DPMI_HARDRET_NXT.INTCOM_INTNO ; Get INT # times 4 + ...
	 mov	 [esp].DPMI_HARDINT_INTNO,ax ; Save in return stack

	 mov	 eax,esp	; Get offset of new stack frame
	 xchg	 eax,LAST_INTCOM ; Swap with the previous one
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 eax,0		; Save previous flag
	 mov	 [esp].INTCOM_ICOMLO,ax ; Save to restore later
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [esp].INTCOM_ICOMHI,ax ; Save to restore later

	 mov	 eax,SAVE_EAX	; Restore
	 mov	 ebx,SAVE_EBX	; ...

if @OEM_DPMI
	 push	 PVMTSS 	; Pass offset in PGROUP of the 1st TSS
	 FIXICALL IGROUP:FDPMIFN_LMSW,DTE_CSIG ; Put MSW and INT 07h values into effect
endif				; IF @OEM_DPMI

	 jmp	 HARDINT	 ; It's a hardware interrupt

	 assume  ss:nothing	; Tell the assembler about it


	 assume  ss:PGROUP	; Tell the assembler about it
INTCOM_DPMI_INTRET_VMFULL:
	 add	 esp,size INTCOM_STR ; Strip

	 REGREST <DPMICNT0E,DPMICNT0D,LAST_INTFLG,LAST_INTCOM> ; Restore

	 pop	 LPMSTK_FVEC.FOFF ; Restore
	 pop	 LPMSTK_FVEC.FSEL ; ...

	 mov	 eax,SAVE_EAX	; Restore
	 mov	 ebx,SAVE_EBX	; ...

	 PUSHD	 0		; Put pseudo-error code onto stack

	 FIXIJMP IGROUP:FLTPROC_VMFULL,DTE_CSIG ; Join common error code



; A fault from a DPMI client has occurred
; The stack is mapped by INTDPF_STR if we came from DPMI
; or FLT_STR if we came from MAX.
; Note that INTDPF_INTNO is already filled in with the
; INT # times 4 + offset PGROUP:INTPROC00Z

	 public  INTCOM_DPMI_FAULT
INTCOM_DPMI_FAULT:
	 assume  ss:PGROUP	; Tell the assembler about it

; Save DPMI selectors in case we need them when the DPMI client
; handles a HW- or SP- interrupt

	 mov	 LAST_DPMI_DS,ds ; Save for later use
	 mov	 LAST_DPMI_ES,es ; ...
	 mov	 LAST_DPMI_FS,fs ; ...
	 mov	 LAST_DPMI_GS,gs ; ...

	 push	 ax		; Save for a moment

	 mov	 ax,[esp+2].INTDPF_INTNO ; Get INT # times 4 + ...
	 sub	 ax,offset PGROUP:INTPROC00Z ; Convert to INT # times 4
	 shr	 ax,2-0 	; Convert from times 4 to times 1

	 bt	 DPMI_CPFHOOK.ELO,ax ; Izit hooked by current client?
	 pop	 ax		; Restore
	 jnc	 short @F	; Jump if not

	 push	 @PMINTCOM_LPM	; Use LPM stack
	 push	 PCURTSS	; Pass offset in PGROUP of current TSS
	 FIXIJMP IGROUP:PMFLTCOM,DTE_CSIG ; Jump to common code

@@:

; The fault is not hooked by the current client -- if it's hooked as
; an interrupt, send it down the PMINTCOM chain.

	 push	 ax		; Save for a moment

	 mov	 ax,[esp+2].INTDPF_INTNO ; Get INT # times 4 + ...
	 sub	 ax,offset PGROUP:INTPROC00Z ; Convert to INT # times 4
	 shr	 ax,2-0 	; Convert from times 4 to times 1

	 bt	 DPMI_CPIHOOK.ELO,ax ; Izit hooked by current DPMI client?
	 pop	 ax		; Restore
	 jnc	 short @F	; Jump if not

	 add	 esp,size INTDPF_ERR ; Strip off the error code

	 push	 @PMINTCOM_NRM	; Use application stack
	 FIXIJMP IGROUP:PMINTCOM,DTE_CSIG ; Jump to common code
@@:
	 FIXIJMP IGROUP:FLTPROC_APPL,DTE_CSIG ; Join common code
endif				; IF @OEM_DPMI

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTCOM	 endp			; End INTCOM procedure
	 NPPROC  IZIT_REFLINT -- Is This Interrupt Reflectable
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Is this interrupt reflectable??

Because some DPMI clients don't lock their HW interrupt handlers, we
have to take special precautions:

If this is a special program (also called a bozo program), and
  Swapping is present, and
  Either we're already processing a page fault, or
	 we're inside an INT 13h call, or
	 we're inside DOS
then don't pass the INT on to the client.

On entry:

AX	 =	 interrupt #

On exit:

CF	 =	 1 if it's reflectable
	 =	 0 if not

|

	 test	 I31_FLAG,mask $I31_XMEI ; Izit one to worry about?
	 jz	 short IZIT_REFLINT1 ; Jump if not

	 test	 VMM_FLAG,@VMM_BSPRES ; Is swapping present?
	 jz	 short IZIT_REFLINT1 ; Jump if not

	 cmp	 PageFaultActive,0 ; Are we processing a page fault?
	 ja	 short IZIT_REFLINT2 ; Jump if so (note CF=0)

	 REGSAVE <eax,ds>	; Save for a moment

	 mov	 ds,SEL_DSHI	; Get high DOS memory selector
	 assume  ds:PGROUP	; Tell the assembler about it

	 cmp	 I13CNT,0	; Izit within an INT 13h call?
	 ja	 short @F	; Jump if so (note CF=0)

	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 eax,LaINDOS	; AGROUP:EAX ==> InDOS flag

	 cmp	 AGROUP:[eax].LO,0 ; Are we inside DOS?
@@:
	 REGREST <ds,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 ja	 short IZIT_REFLINT2 ; Jump if so (note CF=0)
IZIT_REFLINT1:
	 stc			; Mark as reflectable
IZIT_REFLINT2:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_REFLINT endp		; End IZIT_REFLINT procedure
	 NPPROC  IZIT_CPIHOOK -- Is An Interrupt Hooked By Active Current DPMI Client
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Is a SW interrupt hooked by an active current DPMI client?

On entry:

AX	 =	 INT #

On exit:

CF	 =	 0 if not hooked
	 =	 1 if so

|

	 bt	 DPMI_CPIHOOK.ELO,ax ; Izit hooked by current DPMI client?
	 jnc	 short IZIT_CPIHOOK_EXIT ; Jump if not (note CF=0)

	 push	 eax		; Save for a moment

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 bt	 PGROUP:[eax].DPTSS_FLAG,$DPTSS_INIT ; Izit initialized?
	 pop	 eax		; Restore
				; Return with CF=1 if initialized, 0 if not
IZIT_CPIHOOK_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_CPIHOOK endp		; End IZIT_CPIHOOK procedure
	 NPPROC  IZIT_PPIHOOK -- Is An Interrupt Hooked By Active Primary DPMI Client
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Is an interrupt hooked by an active primary DPMI client?

On entry:

AX	 =	 INT #

On exit:

CF	 =	 0 if not hooked
	 =	 1 if so

|

	 bt	 DPMI_PPIHOOK.ELO,ax ; Izit hooked by primary DPMI client?
	 jnc	 short IZIT_PPIHOOK_EXIT ; Jump if not (note CF=0)

	 cmp	 al,23h 	; Izit INT 23h?
	 je	 short IZIT_PPIHOOK_EXIT ; Jump if so (note CF=0)

	 cmp	 al,24h 	; Izit INT 24h?
	 je	 short IZIT_PPIHOOK_EXIT ; Jump if so (note CF=0)

	 push	 eax		; Save for a moment

	 mov	 eax,PPRMTSS	; Get offset in PGROUP of primary TSS

	 bt	 PGROUP:[eax].DPTSS_FLAG,$DPTSS_INIT ; Izit initialized?
	 pop	 eax		; Restore
				; Return with CF=1 if initialized, 0 if not
IZIT_PPIHOOK_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_PPIHOOK endp		; End IZIT_PPIHOOK procedure
	 NPPROC  IRETD_COM -- Common IRETD Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Common IRETD routine

Because NMI can occur while we're executing, the INT02 handler
below sets a flag and returns.	This routine tests for that
condition and if set, clears the bit, and continues processing
as if an INT 02h had just occurred.

|

	 test	 GLB_FLAG,@GLB_NMI or @GLB_TLB ; TLB flush needed or did an NMI occur?
	 jnz	 short IRETD_COM1 ; Yes, handle as if an INT 02h had occurred

	 iretd			; No, just return as usual

IRETD_COM1:
	 btr	 GLB_FLAG,$GLB_TLB ; TLB flush needed?
	 jnc	 short @F	; Jump if not

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB
@@:
	 btr	 GLB_FLAG,$GLB_NMI ; Did an NMI occur?
	 jnc	 short @F	; Jump if not

	 cli			; Ensure disabled for INT 02h handler

	 jmp	 short INTPROC02 ; Handle as if an INT 02h had just occurred

@@:
	 btr	 GLB_FLAG,$GLB_I01 ; Should we single-step next instr in VM?
	 jnc	 short @F	; Jump if not

	 push	 mask $TF	; Get TF
	 popf			; TF=1

; Note we *MUST* not insert any instructions between the
; last POPF and the following IRETD or they might get traced

@@:
	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IRETD_COM endp			; End IRETD_COM procedure
	 FPPROC  INTPROC -- Interrupt Procedures
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT_MAC  macro	 N
	 local	 LAB

	 align	 4		; Ensure dword alignment
	 .xcref  INTPROC&N
	 public  INTPROC&N
INTPROC&N:
	 call	 near ptr INTCOM ; Call common routine, w/return addr on stack

	 endm			; INT_MAC

	 align	 4		; Ensure dword alignment
	 public  INTPROC00,INTPROC00Z
INTPROC00 label  far
	 call	 near ptr INTCOM ; Call common routine, w/return addr on stack
INTPROC00Z label far		; This address is pushed by the CALL

CNT	 =	 1		; Start with next interrupt

.xlist
	 rept	 255		; Define remaining interrupts

; Extract high- and low-order digits from CNT in ASCII hex as L and H
; and catenate them as a two-character hex representation of CNT in N

H	 substr  @HEX,1+(CNT/16),1
L	 substr  @HEX,1+(CNT mod 16),1
N	 catstr  H,L

	 INT_MAC %N
CNT	 =	 CNT+1

	 endm			; REPT 100h
.list
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTPROC  endp			; End INTPROC procedure
	 FPPROC  INTXXCOM -- Common Routine For INTXX
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common routine for INT0C, INT0D, and INT0E.

On entry:

PUSHAD has been done.
DI	 =	 offset of message in FGROUP to display on screen
SI	 =	 interrupt # times 4
BX	 =	 offset of low memory message in FGROUP
SS:EBP	 ==>	 INTXX_STR

|

	 cld			; String ops forwardly
	 mov	 esp,ebp	; Cut back the stack

if @OEM_DPMI
	 mov	 [ebp].INTXX_INTNO,si ; Save interrupt # times 4 for debugging
	 add	 [ebp].INTXX_INTNO,offset PGROUP:INTPROC00Z ; Convert to other origin

; This code catches faults not otherwise handled by specific code
; which is present for VM Faults 00h-07h.  The VM Faults which
; come here include 08h-0Eh, and 12h.

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit from VM?
	 jz	 short INTXXCOM_PM ; Jump if not

; If there's a DPMI client active and the primary client has hooked
; this exception, give it a crack at it.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_PVFHOOK must be clear.

	 mov	 ax,si		; Copy INT # times 4
	 shr	 ax,2		; Divide by four to get INT #

	 bt	 DPMI_PVFHOOK.ELO,ax ; Izit hooked by primary client?
	 jnc	 short INTXXCOM_PM ; Jump if not

	 popad			; Restore

; The MAX stack is consists of (from bottom up) an error code
; followed by INTCOM_STR.

	 FIXIJMP IGROUP:VMFLTCOM,DTE_CSIG ; Jump to common code

INTXXCOM_PM:
endif				; IF @OEM_DPMI
if @OEM_DEBUG
	 test	 LCL_FLAG,@LCL_SWAT ; Is 386SWAT installed?
	 jz	 short INTXXCOM1 ; Not this time

	 movzx	 edi,di 	; Zero high-order word for SWATMSG
	 push	 [ebp].INTXX_ERR ; Pass error code
	 push	 0		; Filler for segment (can't use PUSHD immed)
	 push	 DTE_FIXUP	; Segment of error message
	 push	 edi		; Offset of ...
	 call	 SWATMSG	; Pass error message to 386SWAT

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [E?X+E?X*?]

	 add	 esp,size INTXX_ERR ; Strip off error code

	 jmp	 INT01_COMMON	; Join common debugging code

INTXXCOM1:
endif				; IF @OEM_DEBUG
if @OEM_DPMI
	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 short INTXXCOM_XDPMI ; Jump if no DPMI clients active

; If it's an INT 03h, the EIP has already been decremented
; to point to the INT 03h instruction.	Here, we need to
; increment it back 'cause the code at FLTPROC_ABORT
; will decrement it again.  The right hand giveth, ...

	 cmp	 si,4*03h	; Izit INT 03h?
	 jne	 short @F	; Jump if not

	 inc	 [ebp].INTXX_EIP ; Point past the INT 03h again
@@:

; Copy the message at FGROUP:BX to DPMIMSG_LOW

	 REGSAVE <ds,es>	; Save for a moment

	 mov	 es,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  es:FGROUP	; Tell the assembler about it

	 lea	 di,DPMIMSG_LOW ; ES:DI ==> message destin

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 si,bx		; FGROUP:SI ==> message source
	 mov	 DPMIMSG,di	; Save message offset

	 mov	 cx,FGROUP:[si].LENTXT_LEN ; Get message length
	 add	 cx,size LENTXT_LEN ; Plus the length word

S16  rep movs	 <DPMIMSG_LOW.LO[di],FGROUP:[si].LO> ; Copy to FGROUP

	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [E?X+E?X*?]
	 FIXIJMP IGROUP:FLTPROC_ABORT,DTE_CSIG ; Join common DPMI abort code

INTXXCOM_XDPMI:
endif				; IF @OEM_DPMI
	 mov	 ax,@GLB_ERR	; Error code termination

if @OEM_SYS eq @OEMSYS_HPRS
	 cmp	 bx,offset FGROUP:MSG_NF ; Izit priv op?
	 jne	 short INTXXCOM1A ; Not this time

	 or	 ax,@GLB_RC	; Mark as reason code, too
INTXXCOM1A:
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

	 jmp	 short INTXXCOM2 ; Join common code


	 public  GOREAL_REBOOT
GOREAL_REBOOT:
	 call	 SETBDAREBOOT	; Set 0040:0072 to 1234h
	 call	 SETREBOOT	; Set reboot flag in low memory

	 jmp	 short GOREAL	; Join common code


	 public  EMM2_GOREAL_HI
EMM2_GOREAL_HI:
	 lea	 bx,FGROUP:MSG_REBOOT ; Offset of user message

	 public  GOREAL
GOREAL:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

	 test	 DBG_FLAG,@DBG_RC ; Display reason code on termination?
	 jz	 short GOREAL1	; Not this time

	 mov	 ax,@GLB_RC	; Reason code termination
INTXXCOM2:
	 cli			; Disallow interrupts

	 push	 DTE_DSHI	; Get selector of high DOS memory data
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 or	 GLB_FLAG,ax	; Mark with termination code

	 test	 GLB_FLAG,@GLB_ERR or @GLB_RC ; Error or reason code?
	 jz	 short GOREAL_XRESET ; Neither, so don't reset the keyboard

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jnz	 short @F	; Yes, no need to disable

	 mov	 ah,@S2C_ENA	; Code to enable the keyboard
	 call	 PPI_S2C	; Send command AH to 8042
@@:
	 call	 RESET_KEYB	; Ensure the keyboard is reset

	 mov	 al,@EOI1	; Specific EOI for IRQ1 (the keyboard)
	 out	 @ICR,al	; Tell the 8259 to allow another keystroke

	 assume  es:nothing	; Tell the assembler about it
GOREAL_XRESET:
	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 and	 GLB_FLAG,not @GLB_ON ; Mark as OFF in high memory

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

; Display message at DS:BX to the user

	 call	 DISP_MSG	; Display it

	 assume  ds:nothing	; Tell the assembler about it
GOREAL1:
	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 es,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

; If we're on an MCA machine, disable the watchdog timer
; to avoid spurious NMI

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jz	 short @F	; Not this time

	 call	 HOUSE_DOG	; Disable watchdog timer
@@:

;;;;;;;; test	 LCL_FLAG,@LCL_LODHI ; Running in high memory?
;;;;;;;; jnz	 short GOREAL_VM86A ; Yes, skip this

; Turn off busy bit in our TSS????????????????

if @OEM_DPMI
	 mov	 bx,VM2PM_TSS	; Get current TSS selector
else
	 mov	 bx,DTE_TSS	; Get 1st TSS selector
endif				; IF @OEM_DPMI
	 and	 DESC_TAB.DESC_ACCESS[bx],not (mask $DS_BUSY)

	 call	 DISABLE_NMI	; Disable NMI

	 push	 DTE_PDT	; Get our PDT selector
	 pop	 fs		; Address it
	 assume  fs:PDTGRP	; Tell the assembler about it

	 push	 SWPSIZE	; Save for a moment

	 mov	 ax,LOWOFF.ELO	; Get top of DOS in KB
;;;;;;;; sh?	 ax,(12-2)-10	; Convert from 1KB to 4KB in dwords
	 mov	 SWPSIZE,ax	; Save as new swap size
	 xor	 eax,eax	; A convenient zero
	 mov	 SWAP_SRC,eax	; Ensure swap starts at 00000000

	 FCALL	 SWAP_MEM	; Swap slow low memory with fast high memory

	 pop	 SWPSIZE	; Restore
GOREAL_VM86A:

; Turn off trap flag in case we were running a debugger
; Turn off nested task flag just in case

	 and	 [ebp].INTXX_EFL.ELO,not ((mask $TF) or (mask $NT))

; Save our stack into low memory so that code can reference it

	 push	 DTE_DSHI	; Get selector of high DOS memory data
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 movzx	 edi,es:PLOWSTKZ ; ES:EDI ==> next available stack byte
	 mov	 ecx,size INTXX_STR ; # bytes in structure
	 sub	 edi,ecx	; ES:EDI ==> PL3 INTXX structure in low memory
	 mov	 LOWSTK_FVEC.FOFF,edi ; Save for later use

	 mov	 esi,ebp	; DS:ESI ==> PL0 stack in high memory
	 mov	 ebp,edi	; Address the stack

	 cld			; String ops forwardly
	 shr	 ecx,2-0	; Convert from bytes to dwords
S32  rep movs	 <es:[edi].EDD,ds:[esi].EDD> ; Move it there

	 test	 LCL_FLAG,@LCL_LODHI ; Running in high memory?
	 jnz	 short GOREAL_VM86B ; Yes, skip this

;;; if @OEM_WIN3
;;;
;;; ; Don't clear @GLB_ON if we're OFF from Windows 3 callback
;;; ; so we know to what state we should return the system on the
;;; ; re-enable callback
;;;
;;;	     cmp     LOWWIN3_CB,0   ; Izit Windows 3 init time or later?
;;;	     ja      short GOREAL_VM86B ; Jump if so
;;; endif			    ; IF @OEM_WIN3

; Turn off local INT 67h handler in low memory

	 test	 es:GLB_FLAG,@GLB_AUTO ; Are we AUTOing today?
	 jnz	 short @F	; Yes, no need to clear INT 67h flag

	 and	 es:GLB_FLAG,not @GLB_I67 ; Mark as no longer intercepted

	 mov	 ax,cs		; Copy current selector

	 cmp	 ax,IDT_DESC.IDT_SELECT[67h*type IDT_STR] ; Same as before?
	 jne	 short @F	; No, so don't change the offset

	 mov	 IDT_DESC.IDT_OFFLO[67h*type IDT_STR],offset PGROUP:INTPROC67
@@:
	 and	 es:GLB_FLAG,not @GLB_ON ; Mark as OFF in low memory
GOREAL_VM86B:

if @OEM_VDS

; Clear DMA services enabled bit

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:BIOSDATA	; Tell the assembler about it

	 and	 VDS[400h],not @VDS_ENA ; Mark as disabled
endif				; IF @OEM_VDS

; Transfer virtual A20 state to low memory if not Windows 3 callback

;;; if @OEM_WIN3
;;;	     cmp     LOWWIN3_CB,0   ; Izit Windows 3 init time or later?
;;;	     ja      short GOREAL_WIN3 ; Jump if so
;;; endif			    ; IF @OEM_WIN3

	 mov	 ax,GLB_FLAG	; Get global flags from high memory
	 and	 ax,@GLB_X1MB	; Isolate virtual A20 state
	 and	 es:GLB_FLAG,not @GLB_X1MB ; Clear the bit
	 or	 es:GLB_FLAG,ax ; Transfer the high memory bit to low memory

; Restore original interrupt vectors if rebooting

	 test	 es:LCL_FLAG,@LCL_RBT ; Are we rebooting?
	 jz	 short GOREAL_NOFILL ; Jump if not

; If we've relocated the XBIOS, put it back in case someone
; is depending upon it.  In fact, the IBM PS/2 Model 90/95
; does to tell it the state of the last boot.  Without this code,
; you can't call up the reference diskette on the hard disk
; via Ctrl-Alt-Ins at boot time.

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 test	 I15_FLAG,@I15_XBREL ; Izit present and relocated?
	 jz	 short WARMBOOT_NOXBIOS ; Jump if not

	 movzx	 esi,SBIOSDATA	; Get BIOS data segment
	 shl	 esi,4-0	; Convert from para to bytes

	 movzx	 eax,XBIOS_SRC.VSEG ; Get segment of original XBIOS

	 mov	 edi,eax	; Address original XBIOS

	 assume  es:BIOSDATA	; Tell the assembler about it
	 xchg	 ax,XBDA_SEG[esi] ; Swap 'em (restore old, AX = new)
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 esi,eax	; Address current XBIOS

	 shl	 esi,4-0	; Convert from para to bytes
				; ES:ESI ==> relocated XBIOS source
	 shl	 edi,4-0	; Convert from para to bytes
				; ES:EDI ==> original ...

	 movzx	 ecx,AGROUP:[esi].LO ; Get size of XBIOS in 1KB
	 shl	 ecx,10-2	; Convert from 1KB to dwords

	 cld			; String ops forwardly
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy back to where it used to be
WARMBOOT_NOXBIOS:
	 assume  es:INTVEC	; Tell the assembler about it

	 lea	 di,INT00_VEC[00h*(type INT00_VEC)] ; ES:DI ==> int vectors
	 lea	 si,OLDINT_VECS ; DS:SI ==> local copies of int vectors

; Set CX to the number of dwords to move

	 mov	 cx,NOLDINTS	; # interrupt vectors saved
	 cld			; String ops forwardly
S16  rep movs	 <INT00_VEC[di],OLDINT_VECS[si]> ; Restore original interrupt vectors

	 mov	 eax,LCL_SAVE_PTR ; Get local value of SAVE_PTR
	 lea	 di,SAVE_PTR	; ES:DI ==> SAVE_PTR
	 mov	 es:[di+400h],eax ; Save it back
GOREAL_NOFILL:
	 test	 LCL_FLAG,@LCL_LODHI ; Running in high memory?
	 jnz	 near ptr GOREAL_VM86 ; Yes, skip this
;;; GOREAL_WIN3:

; Tell the CPU to use the low linear memory GDT

;;;;;;;; LGDTD	 PGDT_LLO

	 lss	 esp,LOWSTK_FVEC ; SS:ESP ==> PL3 INTXX structure in low memory
	 assume  ss:nothing	; Tell the assembler about it

; From here on
;
; SS:EBP ==>	 INTXX_STR

; Reset interrupt counters
; Note that DS = DTE_DS here

	 mov	 eax,PPL0STK_MAX ; Get initial top of stack pointer
	 mov	 ebx,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 PGROUP:[ebx].TSS_ESP0,eax ; Restore
	 sub	 eax,size INTCOM_STR ; Back off by frame size
	 mov	 LAST_INTCOM,eax ; Save as offset of last INTCOM interrupt frame
	 and	 LAST_INTFLG,not @INTCOM_VAL ; Mark as invalid

; * Recalculate PL0STK pointers

	 call	 SET_PPL0STK	; Set PPL0STK... pointers

; Ensure all selectors are in one-to-one 64KB memory

	 mov	 ax,DTE_SS	; Use low memory stack selector
	 mov	 ds,ax
	 mov	 es,ax
	 mov	 fs,ax
	 mov	 gs,ax
	 mov	 ss,ax		; In case the B-bit is set
	 mov	 sp,sp		; Just for the fun of it
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

; Save caller's CS:IP into far jump location

	 mov	 ax,[ebp].INTXX_EIP.ELO ; Get caller's IP
	 mov	 FARJMP_VEC.VOFF,ax

	 mov	 ax,[ebp].INTXX_CS ; Get caller's CS
	 mov	 FARJMP_VEC.VSEG,ax

	 mov	 ax,[ebp].INTXX_ESP.ELO ; Get caller's SP
	 mov	 STKPTR.VOFF,ax

	 mov	 ax,[ebp].INTXX_SS ; Get caller's SS
	 mov	 STKPTR.VSEG,ax

; Call restore protected mode entry point in all API files loaded

	 call	 REST_PROT	; Call 'em

; Turn off $IOPL and $NT in low-order flags
; Turn off $VM		 in high-order flags????????????????

	 pushfd 		; Put flags onto the stack
	 and	 [esp].EDD,not ((mask $VMHI) or (mask $IOPL) or (mask $NT))
	 popfd			; ...and into EFL

	 FIXIJMP PGROUP:GOREAL_LOW,DTE_CS ; Far jump to code to enter real mode

	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

GOREAL_VM86:
	 assume  ds:PGROUP	; Tell the assembler about it

	 movzx	 eax,HIMEM_CS	; Save this value for later use

	 push	 eax		; GS with filler
	 push	 eax		; FS ...
	 push	 eax		; DS ...
	 push	 eax		; ES ...
	 push	 eax		; SS ...
	 push	 ebp		; ESP
	 push	 dword ptr ((mask $VMHI) or (@VMIOPL shl $IOPL)) ; EFL
	 push	 eax		; CS ...
	 push	 dword ptr (offset cs:GOVM86_LOW) ; EIP

	 iretd			; Return to VM86 mode

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTXXCOM endp			; End INTXXCOM procedure
	 NPPROC  DISP_MSG -- Display Message On Screen
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a message on the screen

On entry:

DS:BX	 ==>	 length byte, message to display
SS:EBP	 ==>	 INTXX_STR

|

	 REGSAVE <ax,cx,dx,si,di,es> ; Save registers

; Restore the interrupt vector table to its values after we initialized
; in case they've been clobbered

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 ds,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  ds:FGROUP	; Tell the assembler about it

	 lea	 di,INT00_VEC[00h*(type INT00_VEC)] ; ES:DI ==> int vectors
	 lea	 si,MAXINT_VECS ; DS:SI ==> local copies of int vectors
	 mov	 cx,NOLDINTS	; # interrupt vectors saved
	 cld			; String ops forwardly
S16  rep movs	 <INT00_VEC[di],MAXINT_VECS[si]> ; Restore interrupt vectors

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 es,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  es:FGROUP	; Tell the assembler about it

; Format CS:IP into the message

	 mov	 ax,[ebp].INTXX_EIP.ELO ; Get IP from stack
	 lea	 di,FGROUP:MSG_ADDROFF ; ES:DI ==> place to put result
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 mov	 ax,[ebp].INTXX_CS ; Get CS from stack
	 lea	 di,FGROUP:MSG_ADDRSEG ; ES:DI ==> place to put result
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 mov	 al,':'         ; Assume VM

	 test	 [ebp].INTXX_EFL.EHI.LO,mask $VM ; In VM86 mode?
	 jnz	 short @F	; Jump if so

	 mov	 al,'|'         ; It's PM
@@:
	 mov	 MSG_ADDRSEP,al ; Save as separator in message

; Clear the screen

	 mov	 al,VIDMODE	; Get original video mode
	 VIDCALL @SETMOD	; Set video mode

; Display title

	 mov	 dx,-1		; Use current position (should be (0,0))
	 lea	 si,FGROUP:MSG_TITLE ; ES:SI ==> message to display
	 call	 DISP_STR	; Display it

; Display main message

;;;;;;;; mov	 dx,-1		; Use current position
	 mov	 si,bx		; ES:SI ==> message to display
	 call	 DISP_STR	; Display it

	 test	 DB3_FLAG,@DB3_XADDR ; Display this message?
	 jnz	 short @F	; Jump if not

; Display address

;;;;;;;; mov	 dx,-1		; Use current position
	 lea	 si,FGROUP:MSG_LADR ; ES:SI ==> message to display
	 call	 DISP_STR	; Display it
@@:

; Display next part of message

;;;;;;;; mov	 dx,-1		; Use current position
	 lea	 si,FGROUP:MSG_TITL2 ; ES:SI ==> message to display
	 call	 DISP_STR	; Display it
	 lea	 si,FGROUP:MSG_TITL3 ; ES:SI ==> message to display
	 call	 DISP_STR	; Display it
	 lea	 si,FGROUP:MSG_TITL4 ; ES:SI ==> message to display
	 call	 DISP_STR	; Display it

; Convert the application name to uppercase

	 lea	 si,MSG_APPLNAME ; DS:SI ==> message to display
	 lods	 MSG_APPLNAME.LENTXT_LEN ; Get and skip over string length
	 mov	 cx,ax		; Copy to loop counter
	 jcxz	 DISP_MSG_XAPPL ; Jump if it's empty????
DISP_MSG_NEXT:
	 lods	 MSG_APPLNAME.LO[si] ; Get next byte

	 cmp	 al,'a'         ; Check against lower limit
	 jb	 short @F	; Jump if too small

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short @F	; Jump if too large

	 add	 al,'A'-'a'     ; Convert to uppercase
	 mov	 PGROUP:[si-1],al ; Save back into application name
@@:
	 loop	 DISP_MSG_NEXT	; Jump if more characters to convert

; Display name of last application
; (N.B. MSG_APPLNAME is saved on Int 21 4Bxx calls in QMAX_I21.  It
;  could be moved to FGROUP along with the M and K flag structures.)

	 push	 es		; Save

	 mov	 es,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

;;;;;;;; mov	 dx,-1		; Use current position
	 lea	 si,MSG_APPLNAME ; ES:SI ==> message to display
	 call	 DISP_STR	; Display it

	 pop	 es		; Restore
	 assume  es:IGROUP	; Tell the assembler

	 jmp	 short DISP_MSG_XAPPL1 ; Join common code

DISP_MSG_XAPPL:

; Application name unknown:  tell 'em so

;;;;;;;; mov	 dx,-1		; Use current position
	 lea	 si,FGROUP:MSG_APPLUNK ; ES:SI ==> message to display
	 call	 DISP_STR	; Display it
DISP_MSG_XAPPL1:

; Display next part of message

;;;;;;;; mov	 dx,-1		; Use current position
	 lea	 si,FGROUP:MSG_TAIL ; ES:SI ==> message to display
	 call	 DISP_STR	; Display it

if @OEM_SYS eq @OEMSYS_HPRS

	 test	 GLB_FLAG,@GLB_RC ; Reason code on termination?
	 jz	 short GOVM86_LOW_ERR1 ; Not this time

;;;;;;;; mov	 dx,-1		; Use current position
	 lea	 si,FGROUP:MSG_PRIVOP ; ES:SI ==> message to display
	 call	 DISP_STR	; Display it

	 jmp	 short GOVM86_LOW_ERR2 ; Join common code

GOVM86_LOW_ERR1:
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

; Display key wait message

;;;;;;;; mov	 dx,-1		; Use current position
	 lea	 si,FGROUP:MSG_LKEY ; ES:SI ==> message to display
	 call	 DISP_STR	; Display it
GOVM86_LOW_ERR2:

; Purge the keyboard buffer and wait for a key press -- discard the key

	 call	 KEYWAIT	; Wait for an acknowledgement

if @OEM_SYS eq @OEMSYS_HPRS

	 test	 GLB_FLAG,@GLB_RC ; Reason code on termination?
	 jz	 short GOVM86_LOW_ERR3 ; Not this time

	 or	 al,20h 	; Convert to lowercase

	 cmp	 al,'c'         ; Check for continue with instruction
	 je	 short GOVM86_LOW_ERR3 ; Yes, continue on

	 cmp	 al,'r'         ; Check for system restart
	 jne	 short GOVM86_LOW_ERR2 ; Unknown key

	 push	 DTE_DSHI	; Get selector of high DOS memory data
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 and	 GLB_FLAG,not @GLB_RC ; Turn off reason code in extended memory
	 and	 es:GLB_FLAG,not @GLB_RC ; Turn off reason code in high DOS
GOVM86_LOW_ERR3:
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
	 REGREST <es,di,si,dx,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MSG endp			; End DISP_MSG procedure
	 NPPROC  DISP_STR -- Display A String Through INT 10h
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a string through INT 10h.

On entry:

(DH,DL)  =	 (row,col) of start of message
		 if DX == -1, use current position
ES:SI	 ==>	 message length, message

|

	 REGSAVE <ax,bx,cx,si>	; Save registers

	 lods	 es:[si].LENTXT_LEN ; Get and skip over string length
	 mov	 cx,ax		; Copy to count register

; BH = Page #0, BL = Intense white on black

	 mov	 bx,(0 shl 8) or (@ATChigh or @ATCFwhite)

	 cmp	 dx,-1		; Use current position?
	 je	 short @F	; Jump if so

	 VIDCALL @SETPOS	; Set cursor position to (DH,DL) for page BH
@@:
	 jcxz	 DISP_STR_EXIT	; Jump if nothing to display
DISP_STR_NEXT:
	 lods	 es:[si].LO	; Get the next character

	 VIDCALL @SETTTY	; Write to screen

	 loop	 DISP_STR_NEXT	; Jump if more characters to write
DISP_STR_EXIT:
	 REGREST <si,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STR endp			; End DISP_STR procedure
	 NPPROC  KEYWAIT -- Wait For Keyboard Acknowledgement
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Purge the keyboard buffer and wait for a key press -- discard the key

On exit:

AX	 =	 last key pressed

|

KEYWAIT_NEXT:
	 KEYCALL @GETKST	; Get buffer state
	 jz	 short KEYWAIT_PAUSE ; Nothing available

	 KEYCALL @GETKEY	; Get the key

	 jmp	 KEYWAIT_NEXT	; Go around again

KEYWAIT_PAUSE:
	 KEYCALL @GETKEY	; Get the key

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

KEYWAIT  endp			; End KEYWAIT procedure
	 NPPROC  HOUSE_DOG -- Disable Watchdog Timer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable watchdog timer on MCA machine.

|

	 REGSAVE <eax,ds>	; Save registers

	 in	 al,@8255_B	; Read System Control Port B
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2
	 jmp	 short $+2

	 or	 al,mask $KEYB	; Set high-order bit to reset IRQ0
	 out	 @8255_B,al	; Reset the level for level-triggered ints

	 mov	 al,@TIMER_MSB	; R/W counter bits 0-7 only
	 out	 @8253_CTL3,al	; Tell the 8253 about it

; Reset the Watchdog timer value in the XBIOS data area

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,seg BIOSDATA ; Get segment of BIOS data area
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 eax,PRINTER_BASE[eax+(4-1)*(type PRINTER_BASE)] ; Get XBIOS base
	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 ds:[eax+0039h].LO,0 ; Zero it

	 REGREST <ds,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HOUSE_DOG endp			; End HOUSE_DOG procedure
if @OEM_DEBUG
	 align	 2		; Ensure word alignment
	 FPPROC  INT01 -- Debug Exception
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debug exception interrupt (01h) with no error code on stack.

If we're called from VM,
   If there's a DPMI client active and the primary client has hooked
     this exception, give it a crack at it.
   Otherwise, continue with INTPROC01.
If we're called from PM and there's a DPMI client active,
   give it a crack at this exception.
If we're called from PM and SWAT is active, tell 'em about it.
Otherwise, signal an exception and terminate the session.

|

if @OEM_DMA
	 test	 GLB_FLAG,@GLB_DMA ; DMA transfer in progress?
	 jnz	 near ptr INT01_IGNORE ; Yes, ignore the exception
endif				; IF @OEM_DMA

; The stack is mapped by NRM_STR

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 short INT01_PM ; Jump if not

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_PVFHOOK[01h/8],1 shl (01h mod 8) ; Izit hooked by primary client?
	 jz	 near ptr INTPROC01 ; Jump if not

	 push	 eax		; Make room for pseudo-error code
	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack
	 FIXICALL IGROUP:DPMI_INT01,DTE_CSIG ; Check on DPMI debug watchpoints
	 pop	 ebp		; Restore
	 xchg	 eax,[esp]	; Save on stack, restore original value

; The MAX stack is consists of (from bottom up) an error code
; followed by INTCOM_STR.

	 mov	 [esp].INTDPF_INTNO,4*01h + offset PGROUP:INTPROC00Z ; Mark as INT 01h

	 FIXIJMP IGROUP:VMFLTCOM,DTE_CSIG ; Jump to common code

	 assume  ds:nothing	; Tell the assembler about it

INT01_PM:

; If this exception is caused by a data breakpoint on a reference to
; data in the first megabyte by any code in MAX and SWAT is not
; loaded, then we should reflect it to VM with TF set.	For example,
; this change is needed to avoid stumbling when a Periscope user has
; set BD 0:4*nn L4 R.

	 cmp	 [esp].NRM_CS,DTE_CSIG ; Izit IGROUP?
	 je	 short @F	 ; Jump if so

	 cmp	 [esp].NRM_CS,DTE_CS2 ; Izit PGROUP?
	 jne	 short INT01_XPS ; Jump if not
@@:
	 test	 LCL_FLAG,@LCL_SWAT ; Debugger installed?
	 jnz	 short INT01_XPS ; Jump if so

	 push	 eax		; Save for a moment
	 mov	 eax,dr6	; Get debug status register
	 test	 eax,(mask $B3) or (mask $B2) or (mask $B1) or (mask $B0) ; DRn?
	 pop	 eax		; Restore
	 jz	 short INT01_XPS ; Jump if not

	 assume  ss:PGROUP	; Tell the assembler about it
	 or	 GLB_FLAG,@GLB_I01 ; Mark as single-stepping next instr in VM
	 assume  ss:nothing	; Tell the assembler about it

	 iretd			; Keep on trucking

INT01_XPS:

if @OEM_DPMI

; The stack is mapped by INTDPI_STR if we came from DPMI
; or NRM_STR if we came from MAX

	 test	 [esp].NRM_CS,mask $PL ; Izit PL0?
	 jz	 short INT01_FLTRETPM ; Jump if so (ignore it)

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 short INT01_FLTRETPM ; Jump if no DPMI clients active

	 push	 eax		; Make room for pseudo-error code
	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack
	 FIXICALL IGROUP:DPMI_INT01,DTE_CSIG ; Check on DPMI debug watchpoints
	 pop	 ebp		; Restore
	 xchg	 eax,[esp]	; Save on stack, restore original value

; The stack is mapped by INTDPF_STR if we came from DPMI
; or FLT_STR if we came from MAX

	 mov	 [esp].INTDPF_INTNO,4*01h + offset PGROUP:INTPROC00Z ; Mark as INT 01h

	 jmp	 INTCOM_DPMI_FAULT ; Join common code

INT01_FLTRETPM:
endif				; IF @OEM_DPMI

; Ensure not BD bit in DR6 causing us to signal exception

	 push	 eax		; Save for a moment

	 mov	 eax,dr6	; Get debug status register

	 test	 eax,mask $BD	; Check for cause of GD bit in DR7
	 pop	 eax		; Restore
	 jnz	 near ptr INTPROC01 ; Jump if that's the case
				; and hope that the next handler clears it

	 test	 LCL_FLAG,@LCL_SWAT ; Debugger installed?
	 jz	 short INT01_EXCEPT ; No, handle as debug exception

; Ensure switch between paging disabled and enabled relativizes
; the file load DTEs

	 public  INT01_COMMON
INT01_COMMON:
	 call	 LINPHYS	; Check 'em

; Note SWATCODE assumes the stack at this point has EIP, CS, EFL

	 call	 SWATCODE	; Display the instructions
;;;;;;;; jnc	 short INT01_IGNORE ; Continue debugging
INT01_IGNORE:

; Clear DR6 to avoid confusion on the next debug exception

	 push	 eax		; Save for a moment

	 xor	 eax,eax	; Zero the entire register
	 mov	 dr6,eax	; Clear DR6

	 pop	 eax		; Restore

	 iretd			; Continue on

INT01_EXCEPT:
	 PUSHD	 0		; Put pseudo-error code onto stack

	 pushad 		; Save all EGP registers

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 si,4*01h	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_L01 ; Offset of message to display to user

if @OEM_DEBUG
	 lea	 di,FGROUP:INT01MSG ; Offset of message to display on screen
endif				; IF @OEM_DEBUG

	 jmp	 near ptr INTXXCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT01	 endp			; End INT01 procedure
endif				; IF @OEM_DEBUG
	 align	 2		; Ensure word alignment
	 FPPROC  INT02 -- NMI Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Non-maskable interrupt (02h) with no error code on stack.

If we're called from VM,
   If there's a DPMI client active and the primary client has hooked
     this exception, give it a crack at it.
   Otherwise, continue with INTPROC02.
If we're called from PM and there's a DPMI client active,
   give it a crack at this exception.
If we're called from PM and IF=1, continue with INTPROC02.
Otherwise, then mark it for NMI when we return to VM.

|

; The stack is mapped by NRM_STR

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 short INT02_PM ; Jump if not

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_PVFHOOK[02h/8],1 shl (02h mod 8) ; Izit hooked by primary client?
	 jz	 near ptr INTPROC02 ; Jump if not

	 PUSHD	 0		; Pass pseudo-error code

; The MAX stack is consists of (from bottom up) an error code
; followed by INTCOM_STR.

	 mov	 [esp].INTDPF_INTNO,4*02h + offset PGROUP:INTPROC00Z ; Mark as INT 01h

	 FIXIJMP IGROUP:VMFLTCOM,DTE_CSIG ; Jump to common code

INT02_PM:

if @OEM_DPMI

; The stack is mapped by INTDPI_STR if we came from DPMI
; or NRM_STR if we came from MAX

	 test	 [esp].NRM_CS,mask $PL ; Izit PL0?
	 jz	 short INT02_FLTRETPM ; Jump if so (ignore it)

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 short INT02_FLTRETPM ; Jump if no DPMI clients active

	 PUSHD	 0		; Put pseudo-error code onto stack

; The stack is mapped by INTDPF_STR if we came from DPMI
; or FLT_STR if we came from MAX

	 mov	 [esp].INTDPF_INTNO,4*02h + offset PGROUP:INTPROC00Z ; Mark as INT 02h

	 jmp	 INTCOM_DPMI_FAULT ; Join common code

INT02_FLTRETPM:
endif				; IF @OEM_DPMI
	 test	 [esp].NRM_EFL.EHI,mask $IF ; Izit enabled?
	 jnz	 near ptr INTPROC02 ; Yes, continue with VM 8086 mode handler

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 or	 GLB_FLAG,@GLB_NMI ; Mark as NMI occurred

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Just keep on chugging
				; Note that this IRET allows another NMI

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT02	 endp			; End INT02 procedure
if @OEM_DEBUG
	 align	 2		; Ensure word alignment
	 FPPROC  INT03 -- Breakpoint Exception
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Breakpoint exception interrupt (03h) with no error code on stack.

If we're called from VM,
   If there's a DPMI client active and the primary client has hooked
     this exception, give it a crack at it.
   Otherwise, continue with INTPROC03.
If we're called from PM and there's a DPMI client active,
   give it a crack at this exception.
If we're called from PM and SWAT is active, tell 'em about it.
Otherwise, signal an exception and terminate the session.

|

; The stack is mapped by NRM_STR

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 short INT03_PM ; Jump if not

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_PVFHOOK[03h/8],1 shl (03h mod 8) ; Izit hooked by primary client?
	 jz	 near ptr INTPROC03 ; Jump if not

	 PUSHD	 0		; Pass pseudo-error code

; The MAX stack is consists of (from bottom up) an error code
; followed by INTCOM_STR.

	 mov	 [esp].INTDPF_INTNO,4*03h + offset PGROUP:INTPROC00Z ; Mark as INT 01h

	 FIXIJMP IGROUP:VMFLTCOM,DTE_CSIG ; Jump to common code

INT03_PM:

if @OEM_DPMI

; The stack is mapped by INTDPI_STR if we came from DPMI
; or NRM_STR if we came from MAX

	 test	 [esp].NRM_CS,mask $PL ; Izit PL0?
	 jz	 short INT03_FLTRETPM ; Jump if so (ignore it)

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 short INT03_FLTRETPM ; Jump if no DPMI clients active

	 PUSHD	 0		; Put pseudo-error code onto stack

; The stack is mapped by INTDPF_STR if we came from DPMI
; or FLT_STR if we came from MAX

	 mov	 [esp].INTDPF_INTNO,4*03h + offset PGROUP:INTPROC00Z ; Mark as INT 03h

	 jmp	 INTCOM_DPMI_FAULT ; Join common code

INT03_FLTRETPM:
endif				; IF @OEM_DPMI
	 dec	 [esp].NRM_EIP	; Backup to the breakpoint instruction

	 test	 LCL_FLAG,@LCL_SWAT ; Debugger installed?
	 jnz	 near ptr INT01_COMMON ; Jump if so

	 PUSHD	 0		; Put pseudo-error code onto stack

	 pushad 		; Save all EGP registers

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 si,4*03h	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_L03 ; Offset of message to display to user

if @OEM_DEBUG
	 lea	 di,FGROUP:INT03MSG ; Offset of message to display on screen
endif				; IF @OEM_DEBUG

	 jmp	 near ptr INTXXCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT03	 endp			; End INT03 procedure
endif				; IF @OEM_DEBUG
	 align	 2		; Ensure word alignment
	 FPPROC  INT06 -- Invalid Opcode Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we're called from VM,
   If there's a DPMI client active and the primary client has hooked
     this exception, give it a crack at it.
   Otherwise, attempt to fix the problem
   If we fail, continue with INTPROC06.
If we're called from PM and there's a DPMI client active,
   give it a crack at this exception.
Otherwise, signal an exception and terminate the session.

|

CPYCACHE macro	 NAM,CPL

	 mov	 eax,LA16.LA16_&NAM&.ARBL16_BASE.EDD ; Get caller's cache base
	 rol	 eax,8		; Bring down AR byte
	 and	 al,not (mask $DT_DPL) ; Clear the existing CPL
	 or	 al,CPL 	; Include the CPL
	 mov	 LA32.LA32_&NAM&.ARBL32_AR.HI,al ; Save in LA32 structure
	 shr	 eax,8		; Restore base, clear high-order byte
	 mov	 LA32.LA32_&NAM&.ARBL32_BASE,eax ; Save in LA32 structure
	 movzx	 eax,LA16.LA16_&NAM&.ARBL16_LIM ; Get caller's limit
	 mov	 LA32.LA32_&NAM&.ARBL32_LIM,eax ; Save in LA32 structure

	 endm			; CPYCACHE


DTECACHE macro	 NAM,SEL,CPL,DEFAR
	 local	 L1,L2

	 mov	 si,SEL 	; Get the selector
	 movzx	 esi,si 	; Ensure high-order word clear

	 lar	 eax,esi	; Get the access rights dword
	 jz	 short L1	; Jump if valid

	 mov	 eax,DEFAR shl 8 ; Use default AR byte
L1:
	 and	 ah,not (mask $DT_DPL) ; Clear the existing CPL
	 or	 ah,CPL 	; Include the CPL
	 mov	 LA32.LA32_&NAM&.ARBL32_AR,eax ; Save in LA32 structure

S16	 lsl	 <eax,esi>	; Get the segment limit
	 jz	 short L2	; Jump if valid

	 mov	 eax,CON64KB	; Use 64KB length
	 dec	 eax		; Convert from length to limit
L2:
	 mov	 LA32.LA32_&NAM&.ARBL32_LIM,eax ; Save in LA32 structure

	 mov	 al,DESC_TAB.DESC_BASE2[si] ; Get byte 2
	 mov	 ah,DESC_TAB.DESC_BASE3[si] ; Get byte 3
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,DESC_TAB.DESC_BASE01[si] ; Get bytes 0-1
	 mov	 LA32.LA32_&NAM&.ARBL32_BASE,eax ; Save in LA32 structure

	 endm			; DTECACHE

INT06STK_STR struc

INT06STK_DS  dw  ?		; Caller's DS
INT06STK_EBX dd  ?		; ...	   EBX
INT06STK_EAX dd  ?		;	   EAX
INT06STK_EIP dd  ?		;	   EIP
INT06STK_CS  dw  ?,?		;	   CS with fill
INT06STK_EFL dd  ?		;	   EFLAGS

INT06STK_STR ends

	 REGSAVE <eax,ebx,ds>	; Save registers

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	test	[esp].INT06STK_EFL.EHI.LO,mask $VM ; Izit VM86 mode?
	jz	near ptr INT06_ORIG ; No, continue with original handler

	 movzx	 eax,[esp].INT06STK_CS ; Get caller's CS
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,[esp].INT06STK_EIP.ELO ; Get caller's IP
	 add	 ebx,eax	; DS:EBX ==> caller's CS:IP

; Check for RDMSR and WRMSR opcodes

	 cmp	 AGROUP:[ebx].ELO,@OPCOD_RDMSR ; Izit RDMSR?
	 je	 short @F	 ; Jump if so

	 cmp	 AGROUP:[ebx].ELO,@OPCOD_WRMSR ; Izit WRMSR?
	 jne	 short INT06_XMSR ; Jump if not
@@:

; If these opcodes are in the system BIOS, ignore them as
; they have no meaning; otherwise, pass them on to VM.

	 cmp	 [esp].INT06STK_CS,0E000h ; Izit in system BIOS (E000)?
	 je	 short @F	; Jump if so

	 cmp	 [esp].INT06STK_CS,0F000h ; Izit in system BIOS (F000)?
	 je	 short @F	; Jump if so

	 REGREST <ds,ebx,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 INTPROC06	; Continue with original handler


@@:
	 add	 [esp].INT06STK_EIP,2 ; Skip past it

	 jmp	 short INT06_IGNORE ; Join common code

	 assume  ds:AGROUP	; Tell the assembler about it
INT06_XMSR:
	cmp	AGROUP:[ebx].ELO.LO,@OPCOD_LOCK ; Izit LOCK prefix?
	jne	short @F	; Not this time

; Emulate the LOCK prefix by ignoring it

	 inc	 [esp].INT06STK_EIP.ELO ; Skip past it
INT06_IGNORE:
	 REGREST <ds,ebx,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 IRETD_COM	; Return to caller

	 assume  ds:AGROUP	; Tell the assembler about it
@@:
	 cmp	 AGROUP:[ebx].ELO,@OPCOD_LOADALL ; Izit 286 LOADALL?
	 jne	 near ptr INT06_ORIG ; No, continue with original handler

COMMENT|

It's a 16-bit LOADALL -- emulate it.

|

	 cld			; Ensure string ops forwardly

	 push	 ss		; Setup ES for COPY_DWDD
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Make room on the stack for the LA32 structure

	 sub	 esp,size LA32_STR ; Make room
	 and	 esp,not (4-1)	; Ensure on a dword boundary
	 mov	 ebp,esp	; ES:EBP ==> LA32

LA16	 equ	 <AGROUP:[800h]>
LA32	 equ	 <[ebp]>

; Initialize the structure to zero

	 lea	 edi,LA32	; ES:EDI ==> LA32
	 xor	 eax,eax	; Clear to this value
	 mov	 cx,(size LA32_STR)/4 ; # dwords to clear
     rep stos	 PGROUP:[edi].EDD ; Clear it

; Convert the 286 LOADALL into a 386 LOADALL

; CR0

	 mov	 eax,cr0	; Get current CR0
	 mov	 ax,LA16.LA16_MSW ; Get the caller's MSW bits
	 or	 ax,mask $PE	; Ensure Protect Enabled
	 mov	 LA32.LA32_CR0,eax ; Save in LA32 structure

; TR

	 str	 LA32.LA32_TR	; Save the task register

; EFL

	 movzx	 eax,LA16.LA16_FL ; Get the caller's 16-bit flags
	 and	 ax,not (mask $IOPL) ; Clear the IOPL bits
	 or	 eax,(mask $VMHI) or (@VMIOPL shl $IOPL) ; Ensure set
	 mov	 LA32.LA32_EFL,eax ; Save in LA32 structure

; EIP

	 movzx	 eax,LA16.LA16_IP ; Get caller's IP
	 mov	 LA32.LA32_EIP,eax ; Save in LA32 structure

; LDT

	 sldt	 LA32.LA32_LDT	; Save the LDT register

; DS/SS/CS/ES

	 lea	 esi,LA16.LA16_DS ; DS:ESI ==> start of DS/SS/CS/ES in LA16
	 lea	 edi,LA32.LA32_DS ; ES:EDI ==> ...		       LA32
	 mov	 cx,4		; # registers to copy
	 call	 COPY_DWDD	; Copy and extend

; FS

	 mov	 LA32.LA32_FS,fs ; Save in LA32 structure

; GS

	 mov	 LA32.LA32_GS,gs ; Save in LA32 structure

; EDI/ESI/EBP/ESP/EBX/EDX/ECX/EAX

	 lea	 esi,LA16.LA16_DI ; DS:ESI ==> start of EDI/.../EAX in LA16
	 lea	 edi,LA32.LA32_EDI ; ES:EDI ==> ...		    in LA32
	 mov	 cx,8		; # registers to copy
	 call	 COPY_DWDD	; Copy and extend

; DR6

	 mov	 eax,dr6	; Get the debug status register
	 mov	 LA32.LA32_DR6,eax ; Save in LA32 structure

; DR7

	 mov	 eax,dr7	; Get the debug control register
	 mov	 LA32.LA32_DR7,eax ; Save in LA32 structure

; Copy common code and data descriptor caches

	 CPYCACHE ESC,CPL3	; ES cache
	 CPYCACHE CSC,CPL3	; CS cache
	 CPYCACHE SSC,CPL3	; SS cache
	 CPYCACHE DSC,CPL3	; DS cache

; Setup system descriptor caches

if @OEM_DPMI
	 mov	 bx,VM2PM_TSS	; Get current TSS selector
else
	 mov	 bx,DTE_TSS	; Get 1st TSS selector
endif				; IF @OEM_DPMI
	 and	 DESC_TAB.DESC_ACCESS[bx],not (mask $DS_BUSY)

	 DTECACHE TSSC,bx,     CPL0,CPL0_IDLE3 ; TSS cache
	 DTECACHE LDTC,0,      CPL0,CPL0_LDT   ; LDT cache
	 DTECACHE FSC, fs,     CPL3,CPL0_DATA  ; FS  cache
	 DTECACHE GSC, gs,     CPL3,CPL0_DATA  ; GS  cache

; GDT

	 SGDTD	 LCL_DTR	; Save current GDTR
	 mov	 eax,LCL_DTR.DTR_BASE ; Get base
	 mov	 LA32.LA32_GDTC.ARBL32_BASE,eax ; Save in LA32 structure
	 movzx	 eax,LCL_DTR.DTR_LIM ; Get limit
	 mov	 LA32.LA32_GDTC.ARBL32_LIM,eax ; Save in LA32 structure

; IDT

	 SIDTD	 LCL_DTR	; Save current IDTR
	 mov	 eax,LCL_DTR.DTR_BASE ; Get base
	 mov	 LA32.LA32_IDTC.ARBL32_BASE,eax ; Save in LA32 structure
	 movzx	 eax,LCL_DTR.DTR_LIM ; Get limit
	 mov	 LA32.LA32_IDTC.ARBL32_LIM,eax ; Save in LA32 structure

	 lea	 edi,LA32	; ES:EDI ==> LA32 structure
	 LOADALLD		; Emulate it

	 assume  ds:nothing,es:nothing,fs:nothing ; Tell the assembler about it
	 assume  gs:nothing,ss:nothing		  ; Tell the assembler about it
INT06_ORIG:
	 REGREST <ds,ebx,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
if @OEM_DPMI

; The stack is mapped by INTDPI_STR if we came from DPMI,
; INTCOM_STR if we came from VM, or NRM_STR if we came from MAX

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 short INT06_PM ; Jump if not

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_PVFHOOK[06h/8],1 shl (06h mod 8) ; Izit hooked by primary client?
	 jz	 short INT06_FLTRETVM ; Jump if not

	 PUSHD	 0		; Pass pseudo-error code

; The MAX stack is consists of (from bottom up) an error code
; followed by INTCOM_STR.

	 mov	 [esp].INTDPF_INTNO,4*06h + offset PGROUP:INTPROC00Z ; Mark as INT 01h

	 FIXIJMP IGROUP:VMFLTCOM,DTE_CSIG ; Jump to common code

INT06_PM:
	 test	 [esp].NRM_CS,mask $PL ; Izit PL0?
	 jz	 short INT06_FLTRETPM ; Jump if so (ignore it)

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 short INT06_FLTRETPM ; Jump if no DPMI clients active

	 PUSHD	 0		; Put pseudo-error code onto stack

; The stack is mapped by INTDPF_STR if we came from DPMI,
; or FLT_STR if we came from MAX.

	 mov	 [esp].INTDPF_INTNO,4*06h + offset PGROUP:INTPROC00Z ; Mark as INT 06h

	 jmp	 INTCOM_DPMI_FAULT ; Join common code


INT06_FLTRETPM:
INT06_FLTRETVM:
endif				; IF @OEM_DPMI
	 test	 DB2_FLAG,@DB2_I06 ; Convert to error message?
	 jz	 near ptr INTPROC06 ; No, continue with normal INT 06h handler

	 PUSHD	 0		; Put pseudo-error code onto stack

	 pushad 		; Save all EGP registers

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 si,4*06h	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_L06 ; Offset of message to display to user
if @OEM_DEBUG
	 lea	 di,FGROUP:INT06MSG ; Offset of message to display on screen
endif				; IF @OEM_DEBUG

	 jmp	 near ptr INTXXCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT06	 endp			; End INT06 procedure
	 NPPROC  COPY_DWDD -- Copy DW at DS:SI to DD at ES:DI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy CX words at DS:ESI to dwords at ES:EDI extending the word with zeros.

|

	 REGSAVE <eax,cx,si,di> ; Save registers

	 xor	 eax,eax	; Zero entire register
@@:
	 lods	 ds:[esi].ELO	; Get the word
S32	 stos	 es:[edi].EDD	; Save it as a dword
	 loop	 @B		; Jump if more words to copy

	 REGREST <di,si,cx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_DWDD endp			; End COPY_DWDD procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INT07 -- Coprocessor Not Available
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Coprocessor not available

If we're called from VM,
   If there's a DPMI client active and the primary client has hooked
     this exception, give it a crack at it.
   Otherwise, fix it and continue with INTPROC07.
If we're called from PM and there's a DPMI client active,
   give it a crack at this exception.
Otherwise, fix it (clear the TS bit in CR0) and
   continue with INTPROC07.

|

if @OEM_DPMI

; The stack is mapped by NRM_STR

	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 short INT07_PM ; Jump if not

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 test	 DPMI_PVFHOOK[07h/8],1 shl (07h mod 8) ; Izit hooked by primary client?
	 jz	 near ptr INT07_FLTRETVM ; Jump if not

	 PUSHD	 0		; Pass pseudo-error code

; The MAX stack is consists of (from bottom up) an error code
; followed by INTCOM_STR.

	 mov	 [esp].INTDPF_INTNO,4*07h + offset PGROUP:INTPROC00Z ; Mark as INT 01h

	 FIXIJMP IGROUP:VMFLTCOM,DTE_CSIG ; Jump to common code

INT07_PM:
	 test	 [esp].NRM_CS,mask $PL ; Izit PL0?
	 jz	 near ptr INT07_FLTRETPM ; Jump if so (ignore it)

; If there's a DPMI client active, give it a crack at this exception

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 je	 near ptr INT07_FLTRETPM ; Jump if no DPMI clients active

COMMENT|

Because of a bug in Rational Systems, Inc. DOS 16/M-based products,
used in conjunction with Watcom compiler, Watcom installs a fault
handler and RSI installs an interrupt handler for this event.  The
fault handler does not expect to be called and if it is called, it
terminates the program with an "Unexpected interrupt" message.  By the
way, Watcom uses VxD under Windows to overcome this bug.  To determine
what to do, we use the following heuristic (worked out in conjunction
with Sean True at RSI):

If it's an RSI-based product and a 32-bit DPMI client
  If INT 07h is hooked as a fault
    If the INT 07h fault handler has a 32-bit CS
      Signal as a fault.
    Else
      Signal as an interrupt.
  Else
    Signal as a fault (it'll be reflected as an interrupt later).
Else
  Signal as a fault.

|

	 test	 I31_FlAG,mask $I31_RSI ; Izit an RSI-based product?
	 jz	 short INT07_PM_XRSI ; Jump if not

	 cmp	 DPMITYPE,@DPMITYPE32 ; Izit a 32-bit DPMI client?
	 jne	 short INT07_PM_XRSI ; Jump if not

	 test	 DPMI_CPFHOOK[07h/8],1 shl (07h mod 8) ; Izit hooked by current client?
	 jz	 short INT07_PM_XRSI ; Jump if not

	 REGSAVE <eax,ds>	; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 lar	 eax,PMFLT_FVECS[07h*(type PMFLT_FVECS)].FSEL.EDD ; Get A/R word

	 test	 eax,(mask $DTE_B) shl 16 ; Izit a 32-bit selector?
	 REGREST <ds,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 jz	 short INT07_PM_INT ; Jump if not (signal as an interrupt)
INT07_PM_XRSI:

COMMENT|

Because of code in the Phar Lap DPMI DOS extender to overcome a bug in
Windows, they put INT 07h at the start of all their fault handlers.
This means that we might be here because of an INT 07h (CD 07) rather
than a Co-processor Not Available condition.  So distinguish these
cases, I propose that we check the code around the caller's CS:EIP.
If it is preceded by CD 07 and the code at CS:IP is not a floating
point instruction (opcode D8-DF), then we convert the INT 07h into a
software interrupt.

|

	 push	 ebp		; Prepare to address the stack
	 lea	 ebp,[esp+4]	; SS:EBP ==> INTDPI_STR

	 REGSAVE <ax,esi,ds>	; Save for a moment

	 lds	 esi,[ebp].INTDPI_EIP.EDF ; Get caller's CS:EIP
	 assume  ds:nothing	; Tell the assembler about it

	 cmp	 esi,2		; Izit too small to be preceded by CD 07?
	 jb	 short INT07_PL_EXIT ; Jump if so (note CF=1 -- continue with fault)

	 cmp	 ds:[esi-2].ELO,07CDh ; Izit INT 07h?
	 stc			; Assume not
	 jne	 short INT07_PL_EXIT ; Jump if not (note CF=1 -- continue with fault)

; Check for floating point opcode at CS|IP
; If found, continue with the INT 07h fault handler

	 cld			; String ops forwardly
INT07_PL_NEXT:
	 lods	 ds:[esi].LO	; Get next instruction byte

	 cmp	 al,@OPCOD_CS	; Izit segment override?
	 je	 short INT07_PL_NEXT ; Jump if so

	 cmp	 al,@OPCOD_DS	; Izit segment override?
	 je	 short INT07_PL_NEXT ; Jump if so

	 cmp	 al,@OPCOD_ES	; Izit segment override?
	 je	 short INT07_PL_NEXT ; Jump if so

	 cmp	 al,@OPCOD_FS	; Izit segment override?
	 je	 short INT07_PL_NEXT ; Jump if so

	 cmp	 al,@OPCOD_GS	; Izit segment override?
	 je	 short INT07_PL_NEXT ; Jump if so

	 cmp	 al,@OPCOD_SS	; Izit segment override?
	 je	 short INT07_PL_NEXT ; Jump if so

	 cmp	 al,@OPCOD_ASP	; Izit address size prefix?
	 je	 short INT07_PL_NEXT ; Jump if so

	 cmp	 al,@OPCOD_OSP	; Izit operand size prefix?
	 je	 short INT07_PL_NEXT ; Jump if so

; Check the opcode

	 cmp	 al,@OPCOD_ESC7+1 ; Izit above ESC 07h?
	 jae	 short INT07_PL_EXIT ; Jump if so (note CF=0 -- ignore the fault)

	 cmp	 al,@OPCOD_ESC0 ; Izit at or above ESC 00h?
				; CF=0 ==> it's a floating point instruction
				; CF=1 ==> not
	 cmc			; CF=1 ==> it's a floating point instruction
				; CF=0 ==> not (ignore the fault)
INT07_PL_EXIT:
	 REGREST <ds,esi,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore
	 jc	 short INT07_FLTPM ; Jump if we should continue with the fault
INT07_PM_INT:

; Treat this interrupt as a software interrupt, not a fault

	 test	 DPMI_CPIHOOK[07h/8],1 shl (07h mod 8) ; Izit hooked by current client?
	 jz	 near ptr INTPROC07 ; Jump if not

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*07h + offset PGROUP:INTPROC00Z ; Mark as INT 07h

	 push	 @PMINTCOM_NRM	; Use application stack
	 FIXIJMP IGROUP:PMINTCOM,DTE_CSIG ; Jump to common code

INT07_FLTPM:
	 PUSHD	 0		; Put pseudo-error code onto stack

; The stack is mapped by INTDPF_STR if we came from DPMI,
; or FLT_STR if we came from MAX.

	 mov	 [esp].INTDPF_INTNO,4*07h + offset PGROUP:INTPROC00Z ; Mark as INT 07h

	 jmp	 INTCOM_DPMI_FAULT ; Join common code

INT07_FLTRETPM:
INT07_FLTRETVM:
endif				; IF @OEM_DPMI
	 clts			; Clear the TS bit in CR0

	 jmp	 INTPROC07	; Continue on

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT07	 endp			; End INT07 procedure
if @OEM_DPMI
	 align	 2		; Ensure word alignment
	 FPPROC  INT08 -- Double Fault Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Double Fault (08h) with error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC08
Double Fault	 VM86	  ESP=PPL0STK_ERR	UGH
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Double Fault	 DPMI	  ESP=PPL0STK_DERR	UGH
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT
Double Fault	 PM				UGH

Note that the test for PM interrupts actually tests for CS within
descriptor table limits.  If there is an error code on the stack,
we're testing not caller's CS, but IP.  By construction, IP in our
code can never get small enough to be confused with a valid CS.

|

	 cmp	 esp,PPL0STK_NRM ; Is the stack normal?
	 je	 short INT08_DSTKCHK ; Yes, use normal interrupt processor

	 cmp	 esp,PPL0STK_ERR ; Is it a fault from VM86 mode?
	 je	 short INT08_VM86 ; Yes

if @OEM_DPMI

; See if we're called from a DPMI client

	 cmp	 esp,PPL0STK_DNRM ; Izit a HW/SW interrupt from a DPMI client?
	 je	 short INT08_DPMI_INT ; Jump if so

	 cmp	 esp,PPL0STK_DERR ; Izit a fault from a DPMI client?
	 je	 short INT08_DPMI_FAULT ; Jump if so
endif				; IF @OEM_DPMI

; We need to distinguish between HW-MAX and EX-MAX, so we test
; the R3 bit in NRM_EFL.  If it's HW-MAX, NRM_EFL contains EFL
; and that bit is always set.  If it's EX-MAX, NRM_EFL contains
; CS (a selector), and that bit is the high-order bit of CPL.
; As the host never executes at CPL2 or CPL3, that bit is always clear.

	 test	 [esp].NRM_EFL,mask $R3 ; Izit set?
	 jz	 short INT08_UGH ; No, so that's a big UGH

if @OEM_DPMI

; HW-MAX has occurred:	if there's a DPMI client active, treat it
; as a DPMI interrupt so we use the HPDA stack, not LAST_INTCOM.

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 short INT08_DPMI_INT ; Jump if so
endif				; IF @OEM_DPMI
	 mov	 [esp].NRM_INTNO,4*08h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 08h

	 jmp	 near ptr HARDINT ; It's a hardware interrupt


INT08_DSTKCHK:

; See if we should switch to our local DOS stack

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jz	 short @F	; Jump if not

	 mov	 [esp].NRM_INTNO,4*08h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 08h

; If this is a HW interrupt subject to DOS stacks, switch stacks

	 call	 DSTK_CHK	; Check it out
	 assume  ds:nothing	; Tell the assembler about it
@@:
	 jmp	 INTPROC08	; Use normal interrupt processor


if @OEM_DPMI

; A hardware interrupt from a DPMI client has occurred

INT08_DPMI_INT:

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*08h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 08h

	 jmp	 INTCOM_DPMI_INT ; Join common code


; A fault from a DPMI client has occurred

INT08_DPMI_FAULT:

; The stack is mapped by INTDPF_STR

	 mov	 [esp].INTDPF_INTNO,4*08h + offset PGROUP:INTPROC00Z ; Mark as INT 08h

	 jmp	 INTCOM_DPMI_FAULT ; Join common code

endif				; IF @OEM_DPMI

INT08_UGH:
INT08_VM86:
	 pushad 		; Save all EGP registers

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 cld			; String ops forwardly

	 mov	 si,4*08h	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_L08 ; Offset of message to display to user
if @OEM_DEBUG
	 lea	 di,FGROUP:INT08MSG ; Offset of message to display on screen
endif				; IF @OEM_DEBUG
	 jmp	 near ptr INTXXCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT08	 endp			; End INT08 procedure
endif				; IF @OEM_DPMI
	 align	 2		; Ensure word alignment
	 FPPROC  INT0A -- Invalid TSS Fault Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Invalid TSS Fault (0Ah) with error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC0A
Invalid TSS ???  VM86	  ESP=PPL0STK_ERR	UGH
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Invalid TSS ???  DPMI	  ESP=PPL0STK_DERR	UGH
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT
Invalid TSS	 PM				UGH

Note that the test for PM interrupts actually tests for CS within
descriptor table limits.  If there is an error code on the stack,
we're testing not caller's CS, but IP.  By construction, IP in our
code can never get small enough to be confused with a valid CS.

|

	 cmp	 esp,PPL0STK_NRM ; Is the stack normal?
	 je	 short INT0A_DSTKCHK ; Yes, use normal interrupt processor

	 cmp	 esp,PPL0STK_ERR ; Is it a fault from VM86 mode?
	 je	 short INT0A_VM86 ; Yes

if @OEM_DPMI

; See if we're called from a DPMI client

	 cmp	 esp,PPL0STK_DNRM ; Izit a HW/SW interrupt from a DPMI client?
	 je	 short INT0A_DPMI_INT ; Jump if so

	 cmp	 esp,PPL0STK_DERR ; Izit a fault from a DPMI client?
	 je	 short INT0A_DPMI_FAULT ; Jump if so
endif				; IF @OEM_DPMI

; We need to distinguish between HW-MAX and EX-MAX, so we test
; the R3 bit in NRM_EFL.  If it's HW-MAX, NRM_EFL contains EFL
; and that bit is always set.  If it's EX-MAX, NRM_EFL contains
; CS (a selector), and that bit is the high-order bit of CPL.
; As the host never executes at CPL2 or CPL3, that bit is always clear.

	 test	 [esp].NRM_EFL,mask $R3 ; Izit set?
	 jz	 short INT0A_UGH ; No, so that's a big UGH

if @OEM_DPMI

; HW-MAX has occurred:	if there's a DPMI client active, treat it
; as a DPMI interrupt so we use the HPDA stack, not LAST_INTCOM.

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 short INT0A_DPMI_INT ; Jump if so
endif				; IF @OEM_DPMI
	 mov	 [esp].NRM_INTNO,4*0Ah + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Ah

	 jmp	 near ptr HARDINT ; It's a hardware interrupt


INT0A_DSTKCHK:

; See if we should switch to our local DOS stack

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jz	 short @F	; Jump if not

	 mov	 [esp].NRM_INTNO,4*0Ah + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Ah

; If this is a HW interrupt subject to DOS stacks, switch stacks

	 call	 DSTK_CHK	; Check it out
	 assume  ds:nothing	; Tell the assembler about it
@@:
	 jmp	 INTPROC0A	; Use normal interrupt processor


if @OEM_DPMI

; A hardware interrupt from a DPMI client has occurred

INT0A_DPMI_INT:

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*0Ah + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Ah

	 jmp	 INTCOM_DPMI_INT ; Join common code


; A fault from a DPMI client has occurred

INT0A_DPMI_FAULT:

; The stack is mapped by INTDPF_STR

	 mov	 [esp].INTDPF_INTNO,4*0Ah + offset PGROUP:INTPROC00Z ; Mark as INT 0Ah

	 jmp	 INTCOM_DPMI_FAULT ; Join common code

endif				; IF @OEM_DPMI

INT0A_UGH:
INT0A_VM86:
	 pushad 		; Save all EGP registers

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 cld			; String ops forwardly

	 mov	 si,4*0Ah	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_L0A ; Offset of message to display to user
if @OEM_DEBUG
	 lea	 di,FGROUP:INT0AMSG ; Offset of message to display on screen
endif				; IF @OEM_DEBUG
	 jmp	 near ptr INTXXCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT0A	 endp			; End INT0A procedure
if @OEM_DPMI
	 align	 2		; Ensure word alignment
	 FPPROC  INT0B -- Segment Not Present Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Segment Not Present interrupt (0Bh) with error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC0B
Segment Overrun  VM86	  ESP=PPL0STK_ERR	UGH
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Segment Overrun  DPMI	  ESP=PPL0STK_DERR	UGH
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT
Segment Overrun  PM				UGH

Note that the test for PM interrupts actually tests for CS within
descriptor table limits.  If there is an error code on the stack,
we're testing not caller's CS, but IP.  By construction, IP in our
code can never get small enough to be confused with a valid CS.

|

	 cmp	 esp,PPL0STK_NRM ; Is the stack normal?
	 je	 short INT0B_DSTKCHK ; Yes, use normal interrupt processor

	 cmp	 esp,PPL0STK_ERR ; Is it a fault from VM86 mode?
	 je	 short INT0B_VM86 ; Yes

if @OEM_DPMI

; See if we're called from a DPMI client

	 cmp	 esp,PPL0STK_DNRM ; Izit a HW/SW interrupt from a DPMI client?
	 je	 short INT0B_DPMI_INT ; Jump if so

	 cmp	 esp,PPL0STK_DERR ; Izit a fault from a DPMI client?
	 je	 short INT0B_DPMI_FAULT ; Jump if so
endif				; IF @OEM_DPMI

; We need to distinguish between HW-MAX and EX-MAX, so we test
; the R3 bit in NRM_EFL.  If it's HW-MAX, NRM_EFL contains EFL
; and that bit is always set.  If it's EX-MAX, NRM_EFL contains
; CS (a selector), and that bit is the high-order bit of CPL.
; As the host never executes at CPL2 or CPL3, that bit is always clear.

	 test	 [esp].NRM_EFL,mask $R3 ; Izit set?
	 jz	 short INT0B_UGH ; No, so that's a big UGH

if @OEM_DPMI

; HW-MAX has occurred:	if there's a DPMI client active, treat it
; as a DPMI interrupt so we use the HPDA stack, not LAST_INTCOM.

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 short INT0B_DPMI_INT ; Jump if so
endif				; IF @OEM_DPMI
	 mov	 [esp].NRM_INTNO,4*0Bh + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Bh

	 jmp	 near ptr HARDINT ; It's a hardware interrupt


INT0B_DSTKCHK:

; See if we should switch to our local DOS stack

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jz	 short @F	; Jump if not

	 mov	 [esp].NRM_INTNO,4*0Bh + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Bh

; If this is a HW interrupt subject to DOS stacks, switch stacks

	 call	 DSTK_CHK	; Check it out
	 assume  ds:nothing	; Tell the assembler about it
@@:
	 jmp	 INTPROC0B	; Use normal interrupt processor


if @OEM_DPMI

; A hardware interrupt from a DPMI client has occurred

INT0B_DPMI_INT:

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*0Bh + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Bh

	 jmp	 INTCOM_DPMI_INT ; Join common code


; A fault from a DPMI client has occurred

INT0B_DPMI_FAULT:

; The stack is mapped by INTDPF_STR

	 mov	 [esp].INTDPF_INTNO,4*0Bh + offset PGROUP:INTPROC00Z ; Mark as INT 0Bh

	 jmp	 INTCOM_DPMI_FAULT ; Join common code

endif				; IF @OEM_DPMI

INT0B_UGH:
INT0B_VM86:
	 pushad 		; Save all EGP registers

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 cld			; String ops forwardly

	 mov	 si,4*0Bh	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_L0B ; Offset of message to display to user
if @OEM_DEBUG
	 lea	 di,FGROUP:INT0BMSG ; Offset of message to display on screen
endif				; IF @OEM_DEBUG
	 jmp	 near ptr INTXXCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT0B	 endp			; End INT0B procedure
endif				; IF @OEM_DPMI
	 align	 2		; Ensure word alignment
	 FPPROC  INT0C -- Stack Fault Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Stack fault interrupt (0Ch) with error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC0C
Stack Fault	 VM86	  ESP=PPL0STK_ERR	UGH
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Stack Fault	 DPMI	  ESP=PPL0STK_DERR	UGH
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT
Stack Fault	 PM				UGH

Note that the test for PM interrupts actually tests for CS within
descriptor table limits.  If there is an error code on the stack,
we're testing not caller's CS, but IP.  By construction, IP in our
code can never get small enough to be confused with a valid CS.

|

	 cmp	 esp,PPL0STK_NRM ; Is the stack normal?
	 je	 short INT0C_DSTKCHK ; Yes, use normal interrupt processor

	 cmp	 esp,PPL0STK_ERR ; Is it a fault from VM86 mode?
	 je	 short INT0C_VM86 ; Yes

if @OEM_DPMI

; See if we're called from a DPMI client

	 cmp	 esp,PPL0STK_DNRM ; Izit a HW/SW interrupt from a DPMI client?
	 je	 short INT0C_DPMI_INT ; Jump if so

	 cmp	 esp,PPL0STK_DERR ; Izit a fault from a DPMI client?
	 je	 short INT0C_DPMI_FAULT ; Jump if so
endif				; IF @OEM_DPMI

; We need to distinguish between HW-MAX and EX-MAX, so we test
; the R3 bit in NRM_EFL.  If it's HW-MAX, NRM_EFL contains EFL
; and that bit is always set.  If it's EX-MAX, NRM_EFL contains
; CS (a selector), and that bit is the high-order bit of CPL.
; As the host never executes at CPL2 or CPL3, that bit is always clear.

	 test	 [esp].NRM_EFL,mask $R3 ; Izit set?
	 jz	 short INT0C_UGH ; No, so that's a big UGH

if @OEM_DPMI

; HW-MAX has occurred:	if there's a DPMI client active, treat it
; as a DPMI interrupt so we use the HPDA stack, not LAST_INTCOM.

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 short INT0C_DPMI_INT ; Jump if so
endif				; IF @OEM_DPMI
	 mov	 [esp].NRM_INTNO,4*0Ch + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Ch

	 jmp	 near ptr HARDINT ; It's a hardware interrupt


INT0C_DSTKCHK:

; See if we should switch to our local DOS stack

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jz	 short @F	; Jump if not

	 mov	 [esp].NRM_INTNO,4*0Ch + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Ch

; If this is a HW interrupt subject to DOS stacks, switch stacks

	 call	 DSTK_CHK	; Check it out
	 assume  ds:nothing	; Tell the assembler about it
@@:
	 jmp	 INTPROC0C	; Use normal interrupt processor


if @OEM_DPMI

; A hardware interrupt from a DPMI client has occurred

INT0C_DPMI_INT:

; The stack is mapped by INTDPI_STR

	 mov	 [esp].INTDPI_INTNO,4*0Ch + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Ch

	 jmp	 INTCOM_DPMI_INT ; Join common code


; A fault from a DPMI client has occurred

INT0C_DPMI_FAULT:

; The stack is mapped by INTDPF_STR

	 mov	 [esp].INTDPF_INTNO,4*0Ch + offset PGROUP:INTPROC00Z ; Mark as INT 0Ch

	 jmp	 INTCOM_DPMI_FAULT ; Join common code

endif				; IF @OEM_DPMI

STACKOVF:
	 PUSHD	 0		; Put pseudo-error code onto stack
INT0C_UGH:
INT0C_VM86:
	 pushad 		; Save all EGP registers

	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 cld			; String ops forwardly

; Setup LAST_INTCOM and LAST_INTFLG to display the error message

	 test	 [ebp].INTXX_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jz	 short @F	; Jump if not

	 lea	 eax,[ebp].INTXX_EIP ; Get offset of INTCOM-restartable point
	 xchg	 eax,LAST_INTCOM ; Swap with the last one
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 eax,0		; Save previous flag
	 mov	 [ebp].INTXX_ICOMLO,ax ; Save to restore later
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_ICOMHI,ax ; Save to restore later
@@:

; Format the value of SP in the error message

	 mov	 es,SEL_DSFG3	; Get FGROUP data selector at PL3
	 assume  es:FGROUP	; Tell the assembler about it

	 mov	 ax,[ebp].INTXX_ESP.ELO ; Get the value to format
	 lea	 di,L0CNUM	; ES:DI ==> save area
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 mov	 ax,[ebp].INTXX_EBP.ELO ; Get the value to format
	 lea	 di,L0CNUM2	; ES:DI ==> save area
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 mov	 si,4*0Ch	; Interrupt # times 4
	 lea	 bx,FGROUP:MSG_L0C ; Offset of message to display to user
if @OEM_DEBUG
	 lea	 di,FGROUP:INT0CMSG ; Offset of message to display on screen
endif				; IF @OEM_DEBUG
	 jmp	 near ptr INTXXCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT0C	 endp			; End INT0C procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INT0F -- Spurious Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Spurious interrupt (0Fh) without error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC0F
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT

|

	 mov	 [esp].INTCOM_INTNO,4*0Fh + offset PGROUP:INTPROC00Z ; Mark as hardware INT 0Fh

	 jmp	 short INTNFCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT0F	 endp			; End INT0F procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INT70 -- IRQ8 Real-Time Clock Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IRQ8 Real-Time Clock interrupt (70h) without error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC70
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT

On entry:

SS:ESP	 ==>	 INTCOM_STR

|

	 mov	 [esp].INTCOM_INTNO,4*70h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 70h

	 jmp	 short INTNFCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT70	 endp			; End INT70 procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INT71 -- IRQ9 Redirect Cascade Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IRQ9 Redirect Cascade (71h) without error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC71
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT

On entry:

SS:ESP	 ==>	 INTCOM_STR

|

	 mov	 [esp].INTCOM_INTNO,4*71h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 71h

	 jmp	 short INTNFCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT71	 endp			; End INT71 procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INT72 -- IRQ10 Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IRQ10 (72h) without error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC72
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT

On entry:

SS:ESP	 ==>	 INTCOM_STR

|

	 mov	 [esp].INTCOM_INTNO,4*72h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 72h

	 jmp	 short INTNFCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT72	 endp			; End INT72 procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INT73 -- IRQ11 Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IRQ11 (73h) without error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC73
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT

On entry:

SS:ESP	 ==>	 INTCOM_STR

|

	 mov	 [esp].INTCOM_INTNO,4*73h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 73h

	 jmp	 short INTNFCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT73	 endp			; End INT73 procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INT74 -- IRQ12 Auxiliary Device Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IRQ12 Auxiliary Device (74h) without error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC74
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT

On entry:

SS:ESP	 ==>	 INTCOM_STR

|

	 mov	 [esp].INTCOM_INTNO,4*74h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 74h

	 jmp	 short INTNFCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT74	 endp			; End INT74 procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INT75 -- IRQ13 Math Coprocessor Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IRQ13 Math Coprocessor (75h) without error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC75
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT

On entry:

SS:ESP	 ==>	 INTCOM_STR

|

	 mov	 [esp].INTCOM_INTNO,4*75h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 75h

	 jmp	 short INTNFCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT75	 endp			; End INT75 procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INT76 -- IRQ14 Fixed Disk Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IRQ14 Fixed Disk (76h) without error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC76
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT

On entry:

SS:ESP	 ==>	 INTCOM_STR

|

	 mov	 [esp].INTCOM_INTNO,4*76h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 76h

	 jmp	 short INTNFCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT76	 endp			; End INT76 procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INT77 -- IRQ15 Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IRQ15 (77h) without error code on stack.

Distinguish amongst several cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hard/software	 VM86	  ESP=PPL0STK_NRM	Goto INTPROC77
Hard/software	 DPMI	  ESP=PPL0STK_DNRM	Goto HARDINT
Hard/software	 PM	  CS=[EBP].NRM_CS	Goto HARDINT

On entry:

SS:ESP	 ==>	 INTCOM_STR

|

	 mov	 [esp].INTCOM_INTNO,4*77h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 77h

	 jmp	 short INTNFCOM ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT77	 endp			; End INT77 procedure
	 align	 2		; Ensure word alignment
	 NPPROC  INTNFCOM -- Common Non-Fault Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common non-fault interrupt handler

On entry:

INTCOM_INTNO has the INT # times 4 + offset PGROUP:INTPROC00Z

Note that the test for PM interrupts actually tests for CS within
descriptor table limits.  If there is an error code on the stack,
we're testing not caller's CS, but IP.  By construction, IP in our
code can never get small enough to be confused with a valid CS.

|

	 cmp	 esp,PPL0STK_NRM ; Is the stack normal?
	 je	 short INTNFCOM_DSTKCHK ; Yes, use normal interrupt processor

if @OEM_DPMI

; See if we're called from a DPMI client

	 cmp	 esp,PPL0STK_DNRM ; Izit a HW/SW interrupt from a DPMI client?
	 je	 near ptr INTCOM_DPMI_INT ; Jump if so
endif				; IF @OEM_DPMI

if @OEM_DPMI

; HW-MAX has occurred:	if there's a DPMI client active, treat it
; as a DPMI interrupt so we use the HPDA stack, not LAST_INTCOM.

	 cmp	 DPMITYPE,@DPMITYPEXX ; Izit active?
	 jne	 near ptr INTCOM_DPMI_INT ; Jump if so
endif				; IF @OEM_DPMI
	 jmp	 near ptr HARDINT ; It's a hardware interrupt


INTNFCOM_DSTKCHK:

; See if we should switch to our local DOS stack

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jz	 short @F	; Jump if not


; If this is a HW interrupt subject to DOS stacks, switch stacks

	 call	 DSTK_CHK	; Check it out
	 assume  ds:nothing	; Tell the assembler about it
@@:
	 push	 [esp].INTCOM_INTNO ; Get INT # times 4 + ...
	 sub	 [esp].ELO,INTPROC00Z-INTPROC00 ; Back off to INTPROCxx

	 ret			; Use normal interrupt processor

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTNFCOM endp			; End INTNFCOM procedure
	 align	 2		; Ensure word alignment
	 NPPROC  HARDINT -- Handle Hardware Interrupts
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle hardware interrupts while executing in protected mode.

The stack upon entry contains

EIP
CS
INT # * 4+ offset PGROUP:INTPROC00Z
EFL

* Check for stack overflow
* Save all EGP registers on the stack
* Save all segment registers on the stack
* Check on DMA transfers
* Save local data variables
* Save ESP as new top of stack pointer
* Recalculate PL0STK pointers
* Setup stack for IRETD
* Continue with hardware interrupt handler

On entry:

IF	 =	 0 (interrupts disabled)

|

HARDINT_STR struc

; The VM 8086 stack starts here

HARDINT_VEIP dd  ?		; VM 8086  EIP
HARDINT_VCS  dw  ?		; ...	   CS
HARDINT_VINT dw  ?		; ...	   INT # times 4 + offset PGROUP:INTPROC00Z
HARDINT_VEFL dd  ?		; ...	   EFL
HARDINT_VESP dd  ?		; ...	   ESP
HARDINT_VSS dd	 ?		; ...	   SS with filler
HARDINT_VES dd	 ?		; ...	   ES ...
HARDINT_VDS dd	 ?		; ...	   DS ...
HARDINT_VFS dd	 ?		; ...	   FS ...
HARDINT_VGS dd	 ?		; ...	   GS ...

; The return stack starts here

HARDINT_ESP dd	 ?		; Caller's ESP
HARDINT_SS dw	 ?		; ...	   SS
HARDINT_GLB dw	 ?		; GLB_FLAG
HARDINT_GS dw	 ?		; Caller's GS
HARDINT_FS dw	 ?		; ...	   FS
HARDINT_ES dw	 ?		; ...	   ES
HARDINT_DS dw	 ?		; ...	   DS
HARDINT_EIP dd	 ?		; ...	   EIP
HARDINT_CS  dw	 ?		; ...	   CS
HARDINT_INTNO dw ?		; Interrupt #
HARDINT_EFL dd	 ?		; ...	   EFL

HARDINT_STR ends

; * Check for stack overflow

	 cmp	 esp,PPL0STK_MIN ; Check against local stack minimum
	 jb	 near ptr STACKOVF ; Too small, so that's a stack overflow

	 cmp	 esp,PPL0STK_MAX ; Check against local stack maximum
	 ja	 near ptr STACKOVF ; Too large, so that's a stack overflow

COMMENT|

Because of a bug in the Rational Systems DOS extender in (say) Lotus
1-2-3 Version 3.10 which trashes the high-order word of several 32-bit
registers (EAX, ECX, EDX, and ESI), we must save those values here and
restore them upon return.

|

; * Save all segment registers on the stack

	 REGSAVE <ds,es,fs,gs>	; Save all data segment registers

if @OEM_DMA

; * Check on DMA transfers

	 cmp	 DMA_CHAN,0	; Any DMA channels active?
	 je	 short @F	; Not this time

	 call	 CHECK_PART	; Check on partial DMA transfers in progress
				; ES and FS clobbered
@@:
endif				; IF @OEM_DMA

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 SAVE_EAX,eax	; Save for a moment

	 inc	 HARDCNT	; Count in another interrupt

; * Save local data variables

; Save on the stack any local data variables which might be
; overwritten while executing the hardware interrupt

	 push	 GLB_FLAG

	 call	 WRAP_ENABLE	; Ensure 1MB wrap enabled

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 push	 PGROUP:[eax].TSS_SS0  ; Save old stack selector
	 push	 PGROUP:[eax].TSS_ESP0 ; Save pointer to stack top

; * Save SS:ESP as new top of stack pointer

	 mov	 PGROUP:[eax].TSS_SS0,ss ; Save for next time
	 mov	 PGROUP:[eax].TSS_ESP0,esp ; ...

	 cli			; Disallow interrupts

; * Recalculate PL0STK pointers

	 call	 SET_PPL0STK	; Set PPL0STK... pointers

; * Setup stack for IRETD

	 mov	 eax,LAST_INTCOM ; DS:EAX ==> bottom of last INTCOM
				; interrupt frame

; Note we don't know whether or not this call interrupted a procedure
; with an error code on the stack.  Thus we can't refer to any data
; below INTCOM_EIP.

; Setup stack as if we'd been interrupted from VM86 mode

; We can't allow an interrupt during the following code in case the
; interrupt handler might trip at the point where PL0STK_ERR or PL0STK_NRM
; would be matched.

	 push	 [eax].INTCOM_GS.EDD ; GS as dword
	 push	 [eax].INTCOM_FS.EDD ; FS
	 push	 [eax].INTCOM_DS.EDD ; DS
	 push	 [eax].INTCOM_ES.EDD ; ES
	 push	 [eax].INTCOM_SS.EDD ; SS
	 push	 [eax].INTCOM_ESP ; ESP

	 PUSHD	 0		; Place holder for EFL

	 push	 HIMEM_CS.EDD	; CS with placeholder for HARDINT_VINT

	 push	 dword ptr (offset cs:HARDRET) ; EIP.ELO

; At this point, the stack is correctly modeled by HARDINT_STR
; and can be addressed through [ESP].

	 mov	 eax,[esp].HARDINT_EFL ; Get caller's flags
	 and	 eax,not ((mask $RFHI) or (mask $IOPL)); RF=IOPL=0
	 or	 eax,(mask $VMHI) or (@VMIOPL shl $IOPL) ; VM=1, IOPL=@VMIOPL
	 mov	 [esp].HARDINT_VEFL,eax ; Save on stack

	 mov	 ax,[esp].HARDINT_INTNO ; Get the INT # times 4 + ...
	 mov	 [esp].HARDINT_VINT,ax ; Save on stack

	 sub	 ax,INTPROC00Z-INTPROC00 ; Back off to the CALL
	 xchg	 eax,SAVE_EAX	; Restore

; See if we should switch to our local DOS stack

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jz	 short @F	; Jump if not

; If this is a HW interrupt subject to DOS stacks, switch stacks

	 call	 DSTK_CHK	; Check it out
	 assume  ds:nothing	; Tell the assembler about it
@@:
	 jmp	 SAVE_EAX.ELO	; Jump to common routine

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HARDINT  endp			; End HARDINT procedure
	 align	 2		; Ensure word alignment
	 FPPROC  INTFF -- Hardware Interrupt Return Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Hardware interrupt return handler (0FFh) without error code on stack.

|

if @OEM_DPMI
	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 near ptr INTPROCFF ; Jump if not (INTCOM catches DPMI calls)
endif				; IF @OEM_DPMI
	 cmp	 [esp].NRM_CS,seg PGROUP ; Check against device driver's CS
	 org	 $-2
	 public  INTFF_HIMEM_CS
INTFF_HIMEM_CS label near
	 org	 $+2
if @OEM_DPMI
	 je	 short @F	; Jump if so

; Ensure IGROUP is present

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 near ptr INTPROCFF ; Jump if so (call as VM INT FFh)

	 FIXIJMP IGROUP:DPMI_SIMRET,DTE_CSIG ; Jump if not (check on DPMI returns)
@@:
else
	 jne	 near ptr INTPROCFF ; Jump if it's just a plain old INT 0FFh
endif				; IF @OEM_DPMI

; Return point from hardware interrupt handler

	 mov	 ds,SEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 dec	 HARDCNT	; Count out another interrupt

	 mov	 SAVE_EAX,eax	; Save for a moment

; Save the return flags for the caller except for VM, RF, IOPL, IF, and TF

	 mov	 eax,[esp].NRM_EFL ; Get caller's flags
	 and	 eax,not ((mask $VMHI) or (mask $RFHI) or (mask $IOPL) or (mask $IF) or (mask $TF))
	 mov	 SAVE_EFL,eax	; Save to restore later

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 lss	 esp,PGROUP:[eax].TSS_ESP0.EDF ; Strip back the stack
				; to HARDINT_ESP
	 assume  ss:nothing	; Tell the assembler about it

	 pop	 PGROUP:[eax].TSS_ESP0 ; Restore TSS pointer
	 pop	 PGROUP:[eax].TSS_SS0  ; Restore TSS selector

	 call	 SET_PPL0STK	; Set PPL0STK... pointers

	 pop	 ax		; Get GLB_FLAG

	 and	 GLB_FLAG,not @GLB_X1MB ; Remove sensitivity flag

	 test	 ax,@GLB_1MB	; Is the 1MB wrap enabled?
	 jz	 short INTFF1	; No, disable it

	 call	 WRAP_ENABLE	; Enable 1MB wrap

	 jmp	 short INTFF2	; Join common code

INTFF1:
	 call	 WRAP_DISABLE	; Disable 1MB wrap
INTFF2:
	 mov	 GLB_FLAG,ax	; Save new GLB_FLAG

; Because some DPMI clients (pssst, it's Windows 3.10 á 2) may
; invalidate the selectors we carefully pushed onto the stack
; when we handled an interrupt so we can restore them now, we must
; VERR them and zero the invalid ones.

	 VERREST <gs,fs,es,ds>	; Restore selectors with VERR
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

; Save the return flags for the caller except for VM, IOPL, IF, and TF

	 mov	 eax,SAVE_EFL	; Get return flags
	 and	 [esp].NRM_EFL,(mask $RFHI) or (mask $IOPL) or (mask $IF) or (mask $TF)
	 or	 [esp].NRM_EFL,eax ; Save as return flags

	 mov	 eax,SAVE_EAX	; Restore

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTFF	 endp			; End INTFF procedure
	 NPPROC  SET_PPL0STK -- Setup PPL0STK Variables
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <eax,ebx>	; Save registers

	 mov	 ebx,PCURTSS	; Get offset in PGROUP of current TSS
if @OEM_DPMI
	 mov	 eax,PGROUP:[ebx].TSS_ESP0 ; Get end of stack
	 sub	 eax,size INTDPF_STR ; Get offset of DPMI error code
	 mov	 PPL0STK_DERR,eax ; Save for later use

	 add	 eax,size INTDPF_ERR ; Get offset of DPMI normal stack start
	 mov	 PPL0STK_DNRM,eax ; Save for later use
endif				; IF @OEM_DPMI
	 mov	 eax,PGROUP:[ebx].TSS_ESP0 ; Get end of stack
	 sub	 eax,(size INTXX_STR)-INTXX_ERR ; Get offset of error code
	 mov	 PPL0STK_ERR,eax ; Save for later use

	 add	 eax,size INTXX_ERR ; Get offset of normal stack start
	 mov	 PPL0STK_NRM,eax ; Save for later use

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_PPL0STK endp		; End SET_PPL0STK procedure
	 NPPROC  SETREBOOT -- Set Reboot Flag In Low Memory
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set reboot flag in low memory

|

	 push	 ds		; Save for a moment

	 push	 DTE_DSHI	; Get selector of high DOS memory data
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 or	 LCL_FLAG,@LCL_RBT ; Mark as rebooting

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETREBOOT endp			; End SETREBOOT procedure
	 NPPROC  SETBDAREBOOT -- Set Reboot Flag In Low Memory
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set reboot flag in low memory

|

	 push	 ds		; Save for a moment

	 push	 seg BIOSDATA ; Get segment of BIOS data area
	 pop	 ds		; Address it
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 mov	 RESET_FLAG,1234h ; Set flag to avoid memory test

	 pop	 ds		; Restore used reg
	 assume  ds:nothing	; Tell assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETBDAREBOOT endp			; End SETBDAREBOOT procedure
	 NPPROC  DPMI_DSTK_CHK -- DPMI DOS Stacks Check
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI reflected interrupt to VM stack check

On entry:

SS:ESP	 ==>	 INTCOM_STR

|

; See if we should switch to our local DOS stack

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jz	 short @F	; Jump if not

; If this is a HW interrupt subject to DOS stacks, switch stacks

	 call	 DSTK_CHK	; Check it out
	 assume  ds:nothing	; Tell the assembler about it
@@:
	 jmp	 INTCOM_DPMI_CHKRET ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_DSTK_CHK endp		; End DPMI_DSTK_CHK procedure
	 NPPROC  DSTK_CHK -- DOS Stacks Check
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DOS stacks check

On entry:

SS:ESP	 ==>	 DSTK_STR

On exit:

DS	 =	 SEL_4GB3

|

DSTK_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
DSTK_NXT db	 (size INTCOM_STR) dup (?) ; The remainder of the stack

DSTK_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

; Check on this interrupt only if it we're to reflect it to VM

	 test	 [ebp].DSTK_NXT.INTCOM_EFL.EHI.LO,mask $VM ; In VM86 mode?
	 jz	 near ptr DSTK_CHK_EXIT ; Jump if not

; Izit an interrupt we're interested in?

	 push	 ax		; Save for a moment

	 mov	 ax,[ebp].DSTK_NXT.INTCOM_INTNO ; Get INT # times 4 + ...
	 sub	 ax,offset PGROUP:INTPROC00Z ; Convert to INT # times 4
	 shr	 ax,2-0 	; Convert from times 4 to times 1

	 bt	 DSTK_HWINTS.ELO,ax ; Izit a selected HW interrupt?
	 pop	 ax		; Restore
	 jnc	 near ptr DSTK_CHK_EXIT ; Jump if not

; Are DOS stacks disabled either locally or globally?

	 test	 DSTK_FLAG,(mask $DSTK_GLBOFF) or (mask $DSTK_LCLOFF) ; Izit?
	 jnz	 near ptr DSTK_CHK_EXIT ; Jump if so

	 REGSAVE <eax,ebx,ecx>	; Save registers

; See if we're running on a DOS stack already:  if so, don't switch
; to another one as this might be a double allocation if a HW
; interrupt occurred in VM and was passed to a DPMI client.  Also,
; this fosters a more efficient usage of our stack space.

	 mov	 ax,PDSTKCOM.VSEG ; Get segment of DOS stacks

	 cmp	 ax,[ebp].DSTK_NXT.INTCOM_SS ; Izit the same SS?
	 je	 near ptr DSTK_CHK_UNINIT ; Jump if so

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

; Search through the structure looking for a free stack

	 mov	 ebx,LaDSTK_TAB ; Get linear address of DSTK_TAB_STR

; Because we can get HW interrupts before the DOS stacks are
; initialized, we must check LaDSTK_TAB:  if it's non-zero,
; then the stacks are initialized.

	 and	 ebx,ebx	; Izit initialized?
	 jz	 near ptr DSTK_CHK_UNINIT ; Jump if not

	 mov	 cx,DSTK_CNT	; Get total # DOS stacks we supply
DSTK_CHK_NEXT:
	 cmp	 AGROUP:[ebx].DSTK_TAB_OLDSTKVEC,@STKAVL ; Izit available?
	 je	 short DSTK_CHK_AVL ; Jump if so
DSTK_CHK_LOOP:
	 add	 ebx,type DSTK_TAB_STR ; Skip to next entry

	 loop	 DSTK_CHK_NEXT	; Jump if more entries

; No DOS stacks available, so we won't bother

	 jmp	 DSTK_CHK_UNINIT ; Join common exit code


; Because the previous stack might have overflowed into this stack,
; we check for our signature

DSTK_CHK_AVL:
	 mov	 eax,AGROUP:[ebx].DSTK_TAB_LaDOSTOP ; Get linear address of top
				; of the corresponding stack
	 sub	 eax,type DSTKCOM_STR ; Back off by one structure

	 cmp	 AGROUP:[eax].DSTKCOM_SIG,@STKSIG ; Izit still there?
	 je	 short @F	; Jump if so

; Mark the stack as having overflowed

	 mov	 AGROUP:[ebx].DSTK_TAB_OLDSTKVEC,@STKOVF ; Mark it

	 jmp	 short DSTK_CHK_LOOP ; Go around again

@@:

; Save the offset of the corresponding entry of DSTK_TAB_STR
; on the new PL3 stack

	 mov	 ecx,ebx	; Copy to convert
	 sub	 ecx,LaDSTK_TAB ; Convert to origin-0
	 mov	 AGROUP:[eax].DSTKCOM_OFF,cx ; Save for later use

; Swap the current SS:SP with the new PL3 SS:SP

	 mov	 eax,AGROUP:[ebx].DSTK_TAB_DOSSTKVEC ; Get the new SS:SP
	 sub	 ax,type DSTKCOM_STR ; Make room for structure
	 xchg	 ax,[ebp].DSTK_NXT.INTCOM_ESP.ELO ; Swap with old SP
	 sub	 ax,type IRET_STR ; Make room for IRET frame
	 mov	 AGROUP:[ebx].DSTK_TAB_OLDSTKVEC.VOFF,ax ; Save to restore later
	 shr	 eax,16 	; Shift down high-order word
	 xchg	 ax,[ebp].DSTK_NXT.INTCOM_SS ; Swap with old SS
	 mov	 AGROUP:[ebx].DSTK_TAB_OLDSTKVEC.VSEG,ax ; Save to restore later

; Address the old PL3 stack

;;;;;;;; mov	 ax,AGROUP:[ebx].DSTK_TAB_OLDSTKVEC.VSEG ; Get old SS
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,AGROUP:[ebx].DSTK_TAB_OLDSTKVEC.VOFF ; Get old SP
	 add	 ebx,eax	; Add to get linear address

; Swap the current CS:IP with the return address
; and save the old one on the old PL3 stack

	 mov	 eax,PDSTKCOM	; Get Seg:Off of return handler
	 xchg	 ax,[ebp].DSTK_NXT.INTCOM_EIP.ELO ; Swap with old IP
	 mov	 AGROUP:[ebx].IRET_IP,ax ; Save to restore later
	 shr	 eax,16 	; Shift down high-order word
	 xchg	 ax,[ebp].DSTK_NXT.INTCOM_CS ; Swap with old CS
	 mov	 AGROUP:[ebx].IRET_CS,ax ; Save to restore later

	 mov	 ax,[ebp].DSTK_NXT.INTCOM_EFL.ELO ; Get caller's flags
	 mov	 AGROUP:[ebx].IRET_FL,ax ; Save to restore later

; Upon entry to DSTKCOM, we must ensure IF=TF=0 to avoid
; being interrupted as well as traced

	 and	 ax,not ((mask $IF) or (mask $TF)) ; IF=TF=0
	 mov	 [ebp].DSTK_NXT.INTCOM_EFL.ELO,ax ; Save caller's flags
DSTK_CHK_UNINIT:
	 REGREST <ecx,ebx,eax>	; Restore
DSTK_CHK_EXIT:
	 pop	 ebp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DSTK_CHK endp			; End DSTK_CHK procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_IDT module

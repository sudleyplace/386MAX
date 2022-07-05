;' $Header:   P:/PVCS/MAX/ASQENG/GETBCRC.ASV   1.1   30 May 1997 14:58:38   BOB  $
	 title	 GETBCRC -- VCPI Program to Get BIOS CRC
	 page	 58,122
	 name	 GETBCRC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group ??????:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  dword-aligned, public, class 'data'

Link requirements:  None, standalone subroutine.

Program derived from:  INST_CRC.ASM

Original code by:  Bob Smith, September, 1988.

Modifications by:  Patrick Devlin, August, 1990.
Modifications by:  Alan C. Lindsay, August, 1990.

|
@DEBUG	 EQU	 0		; Turn off debug options

.386p
;.xlist
	 include MASM.INC
	 include VCPI.INC
	 include 386.INC
	 include PTR.INC
	 include ALLMEM.INC
	 include EMM2CALL.INC
.list


VCPICALL2 macro  FUNC		; Use except for @VCPI_DBGxxx functions
	 local	 L1,L2

ifnb	<FUNC>
	 mov	 al,FUNC	; Get subfunction
endif				; IFNB <FUNC>
	 cmp	 EMS_PRES,1	; If EMS services are present,
	 je	 short L1	; ...use INT 67h entry

	 EMMOUT  @VCPI		; Call through the back door

	 jmp	 short L2	; Join common code
L1:
	 mov	 ah,@VCPI	; VCPI major function
	 int	 67h		; Request VCPI service
L2:
	 endm			; VCPICALL2


EPM_STR  struc

EPM_CR3  dd	 ?		; New CR3
EPM_GDTP dd	 ?		; Pointer to new GDTR base
EPM_IDTP dd	 ?		; Pointer to new IDTR base
EPM_LDTR dw	 ?		; New LDTR
EPM_TR	 dw	 ?		; New TR
EPM_EXIT df	 ?		; CS:EIP of exit point

EPM_STR  ends

DGROUP	 group	DATA

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 XORLIST:word

	 public  _PMI_SEG
_PMI_SEG  dd	 ?		; Seg addr of scratch space

	 public  _BIOSCRC
_BIOSCRC  dw	 ?		; BIOS CRC

	 public  _PASYSROM
_PASYSROM dw	 0F000h 	; Physical segment of system ROM (assumes Non-MCA)

	 public  CRC_CNT,CRC_SEG
CRC_CNT  dw	 ?
CRC_SEG  dw	 ?

	 public  CON4K,CON64K,CON1M
CON4K	 dd	  4*1024	;  4K
CON64K	 dd	 64*1024	; 64K
CON1M	 dd	 1024*1024	;  1M

VDTE_STR struc

	 db	 (size DTE_STR) dup (?) ; 00-38
VCP_PMCS dq	 ?		; 40:  1st selector
VCP_PMDS dq	 ?		; 48:  2nd ...
VCP_PMES dq	 ?		; 50:  3rd ...
VCP_TR	 dq	 ?		; 58:  Task ...
VCP_4GB  dq	 ?		; 60:  All memory ...
VCP_LDT  dq	 ?		; 68:  LDT ...
VCP_VID  dq	 ?		; 70:  Video ...
VCP_SWAT dq	 30 dup (?)	; 78:  386SWAT selectors

VDTE_STR ends

	 public  LCLGDT,VCPGDT
LCLGDT	 VDTE_STR <>		; Local descriptor table for EPM
VCPGDT	 equ	 LCLGDT.VCP_PMCS ; Offset of VCPI selectors

IDTMAC	 macro	 NN
	 IDT_STR <PM_IRETD&NN&,DTE_CS,0,CPL0_INTR3,0> ; Local IDT
	 endm			; IDTMAC

	 public  LCLIDT
LCLIDT	 label	 tbyte
CNT	 =	 0
	 rept	 32
	 IDTMAC  %CNT
CNT	 =	 CNT+1
	 endm			; REPT 32

	 public  EPMTAB
EPMTAB	 EPM_STR <>		; Enter Protected Mode structure

	 public  LCLTSS
LCLTSS	 TSS_STR <>		; Local TSS

	 public  LaCODE,LaDATA,LaCR3,LaPTE,LaBIOS,RaCR3,RaPTE,PaCR3
LaCODE	 dd	 ?		; Linear address of our code segment
LaDATA	 dd	 ?		; ...			data
LaCR3	 dd	 ?		; ...			CR3
LaPTE	 dd	 ?		; ...			PTEs
LaBIOS	 dd	 ?		; ...			BIOS
RaCR3	 dd	 ?		; Relative		CR3
RaPTE	 dd	 ?		; ...			PTE
PaCR3	 dd	 ?		; Physical		CR3

	 public  EMS_PRES
EMS_PRES dw	 0		; 1 = EMS services present

if @DEBUG
	 public  DEBUG_PRES
DEBUG_PRES dw	 0		; 1 = debugger present
endif

	 public  PMI_FWD,PMI_ERR
PMI_FWD  df	 ?		; Selector:Offset to PMI code
PMI_ERR  dw	 ?		; PMI error flag

	 public  OLDESP
OLDESP	 dd	 ?		; Save area for old ESP

	 public  CODESEG,DATASEG
CODESEG  dw	 ?		; Real mode code segment
DATASEG  dw	 ?		; ...	    data

	 public  NEXTPTE,FRSTPTE
NEXTPTE  dw	 ?		; Ptr to next PTE
FRSTPTE  dw	 ?		; Offset to 1st PTE

	 public  BCRC	;;,PORT67
BCRC	 dw	 ?		; BIOS CRC

;;	 extrn	 PORT67:word
PORT67	 dw	 0F084h 	; I/O port for backdoor INT 67h access

	 public  PMSTK,PMSTKZ
PMSTK	 dw	 256 dup (?)	; Protected mode stack
PMSTKZ	 label	 word		; End of ...

	 public  PMSTK_FVEC
PMSTK_FVEC label fword
	 dw	 DGROUP:PMSTKZ,0 ; Stack ending offset
	 dw	 DTE_SS 	; Stack selector

	 public  NEXTLOC
NEXTLOC  dd	 ?		; Lin32 of next available byte

DATA	 ENDS

CODE	 segment use16 byte public 'code' ; Start CODE segment
	 assume  cs:CODE

IRETD_MAC macro  NN
	 public  PM_IRETD&NN
PM_IRETD&NN&:
	 push	 &NN
if @DEBUG
	 int	 01h		; Call our debugger
endif
	 iretd			; Return to caller
	 endm			; IRETD_MAC

CNT	 =	 0
	 rept	 32
	 IRETD_MAC %CNT
CNT	 =	 CNT+1
	 endm			; REPT 32

	 FPPROC GETBCRC 	; -- Get BIOS CRC Via VCPI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get BIOS CRC via a VCPI call.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|
	 pushad 		; Save all EGP registers
;
;?? Used to check for QMAX here, but we already know it's there.
;
	 push	 ds		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

;;;;;;;; DISPLAY "様> Setup for PMI..."

	 mov	 eax,_PMI_SEG	; Get the next available address
	 shl	 eax,4		; Convert from paras to bytes
	 mov	 NEXTLOC,eax	; Save it for later

	 call	 SETUP_PMI	; Setup the PMI
	 call	 SETUP_GDT	; Setup the GDT

if @DEBUG
; ==============================================================================
; Determine whether or not a resident debugger is present
;;;;;;;; DISPLAY "様> Debugger not present"
; ==============================================================================
endif

GETBCRC_GPMI:
;;;;;;;; DISPLAY "様> Setup for GDT..."
;;;;;;;; DISPLAY "様> Setup for TSS..."

	 call	 SETUP_TSS	; Setup the TSS

;;;;;;;; DISPLAY "様> Reading Protected Mode Interface data..."

	 lea	 si,VCPGDT	; DS:SI ==> three DTEs for PMI

	 mov	 eax,LaPTE	; Get Lin32 of PTEs

	 cmp	 eax,1024*1024	; Error if Lin32 greater than 1MB
	 jae	 near ptr GETBCRC_ERR ; Jump if in error

	 call	 LIN2SEG	; Convert Lin32 in EAX to ES:DI
	 assume  es:nothing	; Tell the assembler about it

	 mov	 FRSTPTE,di	; Save as offset of 1st PTE

	 VCPICALL2 @VCPI_GPMI	; Return with EBX=offset, DI=advanced

	 cmp	 ah,0		; Check for error
;;;;;;;; SETMSG  "Unable to read Protected Mode Interface data",ERR
	 jne	 near ptr GETBCRC_ERR ; Jump if in error

	 mov	 PMI_FWD.FOFF,ebx ; Save offset of PMI
	 mov	 PMI_FWD.FSEL,VCP_PMCS ; Save selector of PMI
	 mov	 NEXTPTE,di	; Save offset of next PTE
if @DEBUG
	 cmp	 DEBUG_PRES,1	; Is a debugger present
	 jne	 short @f	; Jump if not
	 int	 01h		; Call SWAT
@@:
endif
	 movzx	 eax,_PASYSROM	; Starting Physical loc of ROM (E000 or F000)
	 shl	 eax,4		; Convert from paras to bytes
	 mov	 cx,128/4	; CX = # PTEs (assume 128Kb BIOS)
	 mov	 CRC_CNT,2	; Number of 64Kb chunks
	 cmp	 eax,0E0000h	; Jump if assumption is correct
	 je	 short @F
	 mov	 cx,64/4	; CX = # PTE in 64Kb BIOS
	 mov	 CRC_CNT,1	; Number of 64Kb chunks

@@:
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
@@:
	 stosd			; Save next PTE
	 add	 eax,CON4K	; Skip to next PTE

	 loop	 @B		; Jump if more PTEs to initialize

	 call	 SEG2LIN	; Convert ES:DI to Lin32 at EAX

	 mov	 NEXTLOC,eax	; Save Lin32 of next available byte

; Calculate linear address of the BIOS

	 movzx	 eax,NEXTPTE	; Get offset of BIOS PTEs relative to DGROUP
	 sub	 ax,FRSTPTE	; Less offset of 1st PTE
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	 mov	 LaBIOS,eax	; Save as linear address of BIOS

	 push	 ds		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

; Setup to Enter and Exit Protected Mode

	 call	 SETUP_EPM	; Set it up

;;;;;;;; DISPLAY "様> Entering protected mode..."

	 lea	 esi,EPMTAB	; Get offset of system tables
	 add	 esi,LaDATA	; Plus base linear address
	 mov	 OLDESP,esp	; Save old stack ptr

	 mov	 PMI_ERR,0	; Start off with no error

; Ensure FS and GS are valid for shift into PM

	 xor	 ax,ax		; A valid selector
	 mov	 fs,ax		; Ensure valid
	 mov	 gs,ax		; ...

	 cli			; Disable int during mode switch

	 VCPICALL2 @VCPI_EPM	; Enter Protected Mode

	 public GETBCRC_PMON
GETBCRC_PMON:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

; Ensure no interrupts between above VCPICALL and the following LSS

	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

	 lss	 esp,PMSTK_FVEC ; SS:ESP ==> PM stack
	 assume  ss:nothing	; Tell the assembler about it

	 push	 DTE_ES 	; Get our extra data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Clear selector
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 ax,VCP_4GB	; Get our all memory selector
	 mov	 gs,ax		; Address it
	 assume  gs:AGROUP	; Tell the assembler about it

; Calculate CRC of BIOS at linear address LaBIOS

	 cld			; String ops forward

	 xor	 dx,dx		; Initialize accumulated CRC
;;;;;;;; mov	 cx,[bp].CRC_CNT ; Get count of # 64KB chunks
	 movzx	 ecx,CRC_CNT	; # of 64Kb chunks,
				; clear high word to use as dword
	 shl	 ecx,16-0	; Convert from 64KB to bytes

	 mov	 esi,LaBIOS	; Get the Lin32 address of the BIOS

CALC_CRC_NEXT:
	 lods	 AGROUP:[esi].LO ; Get next byte

	 xor	 dl,al		; XOR into low-order byte of accumulated CRC

	 xor	 bh,bh		; Zero to use as word
	 mov	 bl,dl		; Copy to index register
	 shl	 bx,1-0 	; Convert from words to bytes

	 mov	 dl,dh		; Shift down one byte
	 xor	 dh,dh		; Zero for next time
	 xor	 dx,XORLIST[bx] ; Compute polynomial residue

	 loopd	 CALC_CRC_NEXT	; Jump if more bytes in this 64KB segment
if @DEBUG
	 cmp	 DEBUG_PRES,1	; Is a debugger present
	 jne	 short @f	; Jump if not
	 int	 01h		; Call SWAT.  YOU ARE IN PROTECTED MODE.
@@:
endif
	 mov	 _BIOSCRC,dx	; Save for later use

; Return to VM86 mode

	 xor	 ax,ax		; A convenient zero
	 mov	 gs,ax		; Set to VM value

;;;;;;;; push	 DTE_ES 	; Get our extra data selector
;;;;;;;; pop	 es		; Address it
;;;;;;;; assume  es:DGROUP	; Tell the assembler about it

GETBCRC_PMEXIT:
	 PUSHD	 gs		; GS
	 PUSHD	 fs		; FS
	 push	 0		; DS filler
	 push	 DATASEG	; DS
	 push	 0		; ES filler
	 push	 DATASEG	; ES
	 push	 0		; SS filler
	 push	 DATASEG	; SS
	 push	 OLDESP 	; ESP
	 PUSHD	 -1		; EFL
	 push	 0		; CS filler
	 push	 CODESEG	; Real mode CS
	 lea	 eax,GETBCRC_PMOFF ; Get return address
	 push	 eax		; EIP

	 push	 VCP_4GB	; Get all memory selector
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,@VCPI	; Get major VCPI function code
	 mov	 al,@VCPI_EPM	; Return to VM86 mode
	 call	 PMI_FWD	; Call PMI code

GETBCRC_PMOFF:
	 assume  ds:DGROUP	; Tell the assembler about it

	 clc			; Indicate present

	 jmp	 short GETBCRC_EXIT ; Join common exit code

GETBCRC_ERR:
	 stc			; Indicate not present
GETBCRC_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

GETBCRC  endp			 ; End GETBCRC procedure
	 NPPROC  LIN2SEG	 ; -- Convert Lin32 to ES:DI
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing
COMMENT|

Convert a Lin32 address in EAX to a segment:offset in ES:DI

|

	 mov	 di,ax		; Copy into DI
	 and	 di,0Fh 	; Isolate offset
	 shr	 eax,4		; Convert bytes to paras
	 mov	 es,ax		; Move segment into ES
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

LIN2SEG  endp			; End LIN2SEG procedure
	 NPPROC  SEG2LIN	; -- Convert ES:DI to Lin32 at EAX
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing
COMMENT|

Convert ES:DI to a Lin32 at EAX

|

	 mov	 ax,es		; Convert ES:DI to Lin32
	 movzx	 eax,ax 	; Convert to 32bit value
	 shl	 eax,4		; Convert from paras to bytes
	 movzx	 edi,di 	; Zero high half of offset
	 add	 eax,edi	; Add segment to offset
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SEG2LIN  endp			; End SEG2LIN procedure
	 NPPROC  SETUP_GDT	; -- Setup The GDT
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing
COMMENT|

Setup the GDT for EPM

|
	 REGSAVE <eax,ebx>	; Save registers

; Setup local code descriptor

	 push	 LaCODE 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_CODE	; Pass access rights byte
	 push	 DTE_CS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local data descriptor

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_DS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local extra data descriptor

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_ES 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local stack descriptor

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_SS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local all memory descriptor

	 PUSHD	 0		; Pass base
	 PUSHD	 0		; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 VCP_4GB	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local TSS descriptor

	 lea	 eax,LCLTSS	; Get local TSS address
	 add	 eax,LaDATA	; Convert from relative to absolute

	 push	 eax		; Pass base
	 push	 dword ptr (size TSS_STR) ; Pass length
	 push	 CPL0_IDLE3	; Pass access rights byte
	 push	 VCP_TR 	; Pass selector
	 call	 SET_GDT	; Set the GDT

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SETUP_GDT endp			; End SETUP_GDT procedure
	 NPPROC  SETUP_TSS	; --	Setup The TSS
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing
COMMENT|

Setup the TSS for EPM

|

	 REGSAVE <eax>		; Save register

	 mov	 word ptr LCLTSS.TSS_ESP0,offset ds:PMSTKZ
	 mov	 LCLTSS.TSS_SS0,DTE_SS

	 mov	 eax,PaCR3	; Get CR3 physical address
	 mov	 LCLTSS.TSS_CR3,eax ; Save in TSS

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SETUP_TSS endp			; End SETUP_TSS procedure
	 NPPROC  SETUP_EPM	; -- Setup to Enter and Exit Protected Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing
COMMENT|

Setup to enter and exit protected mode.

|

	 REGSAVE <eax,ecx,edx,di> ; Save registers

	 mov	 CODESEG,cs	; Save for later use
	 mov	 DATASEG,ds	; Save for later use

; Setup our own CR3

	 mov	 eax,PaCR3	; Get CR3 physical address
	 mov	 EPMTAB.EPM_CR3,eax ; Save in EPMTAB

; Setup our own PDIR

	 push	 es		; Save for a moment

	 mov	 eax,LaCR3	; Get lin32 address of CR3
	 call	 LIN2SEG	; Convert Lin32 address at EAX to ES:DI
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ecx,LaPTE	; Get page talbes lin32 address
	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPICALL2 @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	 mov	 eax,edx	; Copy to output register
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
	 stosd			; Save as 1st PDE

	 mov	 ecx,LaPTE	; Get its linear address
	 add	 ecx,CON4K	; Skip to next Page Table
	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPICALL2 @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	 mov	 eax,edx	; Copy to output register
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
	 stosd			; Save as 2nd PDE

	 pop	 es		; Restore
	 assume  es:DGROUP	; Tell the assembler about it

; Setup pointer to local GDT

	 lea	 eax,LCLGDT	; Get offset
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 LCLGDT.DTE_GDT.DTR_BASE,eax ; Save as linear address of GDT
	 mov	 LCLGDT.DTE_GDT.DTR_LIM,(size VDTE_STR)-1 ; Save as limit

	 lea	 eax,LCLGDT.DTE_GDT ; Get pointer
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 EPMTAB.EPM_GDTP,eax ; Save it

; Setup pointer to local IDT
; Note that the IDT has *NOT* been filled in

	 lea	 eax,LCLIDT	; Get offset
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 LCLGDT.DTE_IDT.DTR_BASE,eax ; Save as linear address of IDT
	 mov	 LCLGDT.DTE_IDT.DTR_LIM,32*8-1 ; Save as limit

	 lea	 eax,LCLGDT.DTE_IDT ; Get pointer
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 EPMTAB.EPM_IDTP,eax ; Save it

; Setup local LDT and TR

	 mov	 EPMTAB.EPM_LDTR,0 ; Don't use one
	 mov	 EPMTAB.EPM_TR,VCP_TR ; Use local one

; Setup return address

	 mov	 word ptr EPMTAB.EPM_EXIT.FOFF,offset cs:GETBCRC_PMON
	 mov	 EPMTAB.EPM_EXIT.FSEL,DTE_CS ; Save our code selector

	 REGREST <di,edx,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SETUP_EPM endp			; End SETUP_EPM procedure
	 NPPROC  SET_GDT	; -- Set Global Descriptor Table
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing
COMMENT|

Set the blobal descriptor table.

|

SET_GDT_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
SET_GDT_DTE dw	 ?		; DTE to set
SET_GDT_ARB db	 ?,?		; Access rights byte
SET_GDT_LEN dd	 ?		; Segment length
SET_GDT_BAS dd	 ?		; Segment base

SET_GDT_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,bx,ecx>	; Save registers

	 mov	 eax,[bp].SET_GDT_BAS ; Get segment base
	 mov	 ecx,[bp].SET_GDT_LEN ; Get segment length
	 dec	 ecx		; Convert from length to limit

	 cmp	 ecx,CON1M	; Check against limit limit
	 jb	 short @F	; Jump if within range

	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 or	 ecx,(mask $DTE_G) shl 16 ; Set G-bit
@@:
	 mov	 bx,[bp].SET_GDT_DTE ; Get the DTE to set

	 mov	 LCLGDT.DESC_BASE01.EDD[bx],eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 LCLGDT.DESC_BASE3[bx],al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 LCLGDT.DESC_SEGLM0[bx],cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 LCLGDT.DESC_SEGLM1[bx],cl ; Save as data limit
;;;;;;;; ror	 ecx,16 	; Swap back

; Set access rights byte

	 mov	 al,[bp].SET_GDT_ARB ; Get it
	 mov	 LCLGDT.DESC_ACCESS[bx],al ; Set it

	 REGREST <ecx,bx,eax>	; Restore

	 pop	 bp		; Restore

	 ret	 2*2+2*4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SET_GDT  endp			; End SET_GDT procedure
	 NPPROC  SETUP_PMI	; -- Setup Get Protected Mode Interface
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing
COMMENT|

Setup Get Protected Mode Interface

|

	 REGSAVE <eax,ecx,edx>	; Save registers

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,cs		; Get our code segment
	 shl	 eax,4-0	; Convert to paras to bytes
	 mov	 LaCODE,eax	; Save as our code's linear base address

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,ds		; Get our data segment
	 shl	 eax,4-0	; Convert to paras to bytes
	 mov	 LaDATA,eax	; Save as our data's linear base address

	 mov	 eax,NEXTLOC	; Get Lin32 of next available byte
	 add	 eax,4096-1	; Round up ...
	 and	 eax,not (4096-1) ; ...to 4KB boundary
	 mov	 LaCR3,eax	; Save as linear address of CR3
	 add	 eax,CON4K	; Skip over PDIR
	 mov	 LaPTE,eax	; Save as linear address of PTEs

	 mov	 eax,LaCR3	; Get linear address
	 sub	 eax,LaDATA	; Convert from linear to relative
	 mov	 RaCR3,eax	; Save for later use

	 mov	 ecx,LaCR3	; Get linear address
	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPICALL2 @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX
	 mov	 PaCR3,edx	; Save for later use

	 mov	 eax,LaPTE	; Get linear address
	 sub	 eax,LaDATA	; Convert from linear to relative
	 mov	 RaPTE,eax	; Save for later use

	 REGREST <edx,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SETUP_PMI endp			; End SETUP_PMI procedure

CODE	 ends			; End CODE segment

	 MEND			; End GETBCRC module

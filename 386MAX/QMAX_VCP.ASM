;' $Header:   P:/PVCS/MAX/386MAX/QMAX_VCP.ASV   1.4   30 May 1997 10:46:10   BOB  $
	 title	 QMAX_VCP -- 386MAX VCP Interface
	 page	 58,122
	 name	 QMAX_VCP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include 8259.INC
	 include MASM5.MAC
	 include ALLMEM.INC
	 include OPCODES.INC
	include PnP.INC

	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAX_OEM.INC
	 include QMAX_VCP.INC

if @OEM_VCPI

PGROUP	 group	 CODE,ECODE,EDATA
IGROUP	 group	 ICODE
JGROUP	 group	 JCODE
XGROUP	 group	 XCODE


if @OEM_VIRTUALMEM
ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 extrn	 PPM_DRAIN_POOL:far

ICODE	 ends			; End ICODE segment
endif				; IF @OEM_VIRTUALMEM


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

if @OEM_DPMI
	 extrn	 SET_HWSP:far
endif				; IF @OEM_DPMI
	 extrn	 CHECK_LOTUS:far

JCODE	 ends			; End JCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 EMMSIZE:dword
	 extrn	 EXTSIZE:dword
	 extrn	 LCL_CR3:dword
	 extrn	 PRGSIZE:word
	 extrn	 PLOWSTKZ:word

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 DPM_FLAG:word
	 include QMAX_I31.INC

if @OEM_VIRTUALMEM
	 extrn	 VMM_FLAG:word
	 include QMAX_VMM.INC

	 extrn	 SEL_DSIG3:word
endif				; IF @OEM_VIRTUALMEM
if @OEM_DPMI
	 extrn	 VM2PM_TSS:word
endif				; IF @OEM_DPMI
	 extrn	 PRGBASE:dword
	 extrn	 PPDTPRG:dword
	 extrn	 PRGPDT:dword
	 extrn	 PDTLEN:dword
	 extrn	 PaMAX:dword
	 extrn	 OFFCR3:dword
	 extrn	 PPAGELINK:dword
	 extrn	 PLINKBASE:dword
	 extrn	 PPHNDLVMS:dword
	 extrn	 HP_LAST:dword
	 extrn	 LAST_INTCOM:dword
	 extrn	 LAST_INTFLG:dword
	 extrn	 EPMTAB:tbyte

	 extrn	 PPDT1MB:dword
	 extrn	 PPDT1P1MB:dword
	 extrn	 PPDTCVD:dword

	 extrn	 PGDT_LHI:fword
	 extrn	 PIDT_LHI:fword
	 extrn	 SEL_4GB:word
	 extrn	 CON4KB:dword
	 extrn	 CON1MB:dword
	 extrn	 CON4MB:dword
	 extrn	 DMA_CHAN:byte
	 extrn	 PCURTSS:dword

	 extrn	 LOTUS_EMSHNDL:word

	extrn	LaPnP_BIOS:dword
	extrn	PnP_VCPI_DIFF:dword
	extrn	PnP_SEG:word

	 public  VCPIMAX,VCPITOP
VCPIMAX  dd	 ?		; Maximum VCPI physical address
VCPITOP  dd	 ?		; Coverage in bytes of VCPI PDT usage (/4KB)

	 public  VCPIBASE,QMAX_PDE,PHAR_PDE,LAST_CR3
VCPIBASE dd	 00110000h	; VCPI PM entry point linear address
QMAX_PDE dd	 ?		; Save area for QMAX's first PDE
PHAR_PDE dd	 ?		; Save area for Phar's first PDE
LAST_CR3 dd	 -1		; Last CR3 from caller

	 public  LASTLINK
LASTLINK dw	 ?		; Address of previous link

	 public  NEWIMR1,NEWIMR2
NEWIMR1  dw	 08h		; Default master IMR base
NEWIMR2  dw	 70h		; ...	  slave

	 public  LAST_ESP
LAST_ESP dd	 ?		; Lowest ESP of VCPI0C

	 public  OLDVCPSTK_FVEC,NEWVCPSTK_FVEC
OLDVCPSTK_FVEC df ?		; Save area for old (incoming) VCPI stack
NEWVCPSTK_FVEC df ?		; New VCPI stack

	 public  VCPI_FNS
VCPI_FNS label	 word
	 dw	 PGROUP:VCPI00	; 00 = Presence detection
	 dw	 PGROUP:VCPI01	; 01 = Get protected mode interface
	 dw	 PGROUP:VCPI02	; 02 = Get maximum physical address
	 dw	 PGROUP:VCPI03	; 03 = Get # free 4KB pages
	 dw	 PGROUP:VCPI04	; 04 = Allocate a 4KB page
	 dw	 PGROUP:VCPI05	; 05 = De-allocate a 4KB page
	 dw	 PGROUP:VCPI06	; 06 = Translate linear to physical address
	 dw	 PGROUP:VCPI07	; 07 = Get CR0
	 dw	 PGROUP:VCPI08	; 08 = Get DRn
	 dw	 PGROUP:VCPI09	; 09 = Set DRn
	 dw	 PGROUP:VCPI0A	; 0A = Get interrupt vector bases
	 dw	 PGROUP:VCPI0B	; 0B = Set interrupt vector bases
	 dw	 PGROUP:VCPI0C	; 0C = Enter protected mode
VCPI_CNT equ	 ($-VCPI_FNS)/2

if @VCP_OLD
	 public  OLDVCPI_FNS
OLDVCPI_FNS label word
	 dw	 PGROUP:OLDVCPI00 ; 00 = Get protected mode interface
	 dw	 PGROUP:VCPI08	  ; 01 = Get DRn
	 dw	 PGROUP:VCPI09	  ; 02 = Set DRn
	 dw	 PGROUP:OLDVCPI03 ; 03 = Get CR0
	 dw	 PGROUP:VCPI04	  ; 04 = Allocate a 4KB page
	 dw	 PGROUP:VCPI05	  ; 05 = De-allocate a 4KB page
	 dw	 PGROUP:EMM_E84   ; 06 = unused
	 dw	 PGROUP:VCPI02	  ; 07 = Get maximum physical address
	 dw	 PGROUP:VCPI06	  ; 08 = Translate linear to physical address
	 dw	 PGROUP:VCPI0C	  ; 09 = Enter protected mode
OLDVCPI_CNT equ  ($-OLDVCPI_FNS)/2
endif				; IF @VCP_OLD

EDATA	 ends			; End EDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_VCP_XCODE
@QMAX_VCP_XCODE:		; Mark module start in .MAP file

if @OEM_VCPI
	 NPPROC  SET_VCPIVARS -- Set VCPI Variables
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set VCPI variables

On entry:

EAX	 =	 next available linear address

|

	 REGSAVE <eax,ebx,ecx>	; Save registers

COMMENT|

This PTE is used during VCPI mode switch, so it must cover
our code/data if we start below 4MB, but can't overlap
VCPIBASE + PRGSIZE * 1024.

This means that the base address is constrained to
avoid the overlap as follows:

If PRGBASE < 1.1MB + PRGSIZE * 1024,  set VCPIBASE to PRGBASE,	(Overlap)
else				      set VCPIBASE to 1.1MB

and the top copy address is constrained to provide PTE coverage at all
times as follows:

if PRGBASE < 4MB, set VCPITOP to Min (4MB, PRGBASE + PRGSIZE * 1024),
else		  set VCPITOP to VCPIBASE + PRGSIZE * 1024.
Note the value of VCPIBASE used here is as set by the earlier algorithm.

Note that we also have to avoid problems with VCPIMAX vs Phar Lap and
DOS/16M, as well as DOS/16M overflow of 64KB if too much available EMS
memory.

|

; If PRGBASE < 1.1MB + PRGSIZE * 1024,	set VCPIBASE to PRGBASE,  (Overlap)
; else					set VCPIBASE to 1.1MB

	 movzx	 eax,PRGSIZE	; Get size of program in 1KB
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 add	 eax,VCPIBASE	; Plus 1.1MB
	 mov	 ebx,PRGBASE	; Get program base

	 cmp	 eax,ebx	; Is there any overlap?
	 jbe	 short @F	; Jump if not

	 mov	 VCPIBASE,ebx	; Save as VCPI base
@@:
; if PRGBASE < 4MB, set VCPITOP to Min (4MB, PRGBASE + PRGSIZE * 1024),
; else		    set VCPITOP to VCPIBASE + PRGSIZE * 1024.

	 movzx	 eax,PRGSIZE	; Get size of program in 1KB
	 shl	 eax,10-0	; Convert from 1KB to bytes

	 cmp	 ebx,CON4MB	; Does the program start within the first PDIR?
	 jae	 short SET_VCPIVARS1 ; Jump if not

	 add	 eax,ebx	; Plus program base to get ending address

	 cmp	 eax,CON4MB	; Does it end within the first PDIR?
	 jb	 short @F	; Jump if so

	 mov	 eax,CON4MB	; Use maximum size of a PDIR
@@:
	 jmp	 short SET_VCPIVARS2 ; Join common code

SET_VCPIVARS1:
	 add	 eax,VCPIBASE	; Plus base of VCPI code/data to get ending
SET_VCPIVARS2:
	 add	 eax,4*1024-1	; Round up to 4KB
	 and	 ax,not (4*1024-1) ; ...
	 mov	 VCPITOP,eax	; Save as top of VCPI address for PTE copy

	 mov	 eax,PaMAX	; Get maximum physical address
	 mov	 VCPIMAX,eax	; Save as maximum VCPI ...

; Handle bug in Phar Lap VMM code at 8MB boundary
; Handle bug in AI Architects/Eclipse/Ergo DOS Extender when
; ceil ((VCPIMAX + 4K) / 4MB) <
; ceil (EMMSIZE + 4MB - 16KB * (ceil ((4KB * ceil (VCPIMAX/4MB) + 1) / 16KB)) / 4MB)
;      1		       2     34 	  5	      5    4	   32	   1

SET_VCPIVARS_AGAIN:
	 mov	 eax,VCPIMAX	; Get maximum VCPI address
	 add	 eax,4*1024	; Plus extra page
	 add	 eax,4*1024*1024-1 ; Round up to 4MB boundary for ceiling
	 shr	 eax,22-0	; Convert from bytes to 4MB

	 mov	 ebx,EMMSIZE	; Get size of EMS memory in 1KB
	 shl	 ebx,10-0	; Convert from 1KB to bytes
	 add	 ebx,4*1024*1024 ; Plus first 4MB PDE

	 mov	 ecx,VCPIMAX	; Get maximum VCPI address
	 add	 ecx,4*1024*1024-1 ; Round up to 4MB boundary
	 shr	 ecx,22-0	; Convert from bytes to 4MB
	 inc	 ecx		; Plus one 4KB page for PDE
				; ECX = # 4KB pages needed for CR3 and PDEs
	 shl	 ecx,12-0	; Convert from 4KB to bytes
	 add	 ecx,16*1024-1	; Round up to next 16KB boundary for ceiling
	 and	 ecx,not (16*1024-1) ; Round down to multiple of 16KB

	 sub	 ebx,ecx	; Subtract to get memory needed
	 add	 ebx,4*1024*1024-1 ; Round up to 4MB boundary
	 shr	 ebx,22-0	; Convert from bytes to 4MB

	 cmp	 eax,ebx	; Is allocated < needed?
	 jb	 short SET_VCPIVARS_SKIP ; Jump if so

	 mov	 eax,VCPITOP	; Get amount filled in VCPI PDT
	 add	 eax,VCPIMAX	; Plus maximum VCPI physical address
	 add	 eax,4*1024	; Plus magic constant

	 mov	 ebx,eax	; Copy to test
	 shr	 ebx,22-0	; Convert from bytes to 4MB
	 and	 bl,11b 	; Modulo 4

	 cmp	 bl,11b 	; Izit 3 modulo 4?
	 je	 short SET_VCPIVARS_SKIP ; Yes, skip to next 4KB

	 add	 eax,288*1024	; Check 288KB ahead

	 shr	 eax,22-0	; Convert from bytes to 4MB
	 and	 al,11b 	; Modulo 4

	 cmp	 al,11b 	; Izit 3 modulo 4?
	 jne	 short SET_VCPIVARS_EXIT ; No, so that's all
SET_VCPIVARS_SKIP:
	 add	 VCPIMAX,4*1024 ; Skip to next 4KB

	 jmp	 SET_VCPIVARS_AGAIN ; Go around again

SET_VCPIVARS_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_VCPIVARS endp		; End SET_VCPIVARS procedure
endif				; IF @OEM_VCPI

XCODE	 ends			; End XCODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_VCP_ECODE
@QMAX_VCP_ECODE:		; Mark module start in .MAP file

	 extrn	 WRAP_DISABLE:near

	 extrn	 EMM_EXIT:near
	 extrn	 EMM_E00AL:near
	 extrn	 EMM_E84:near
	 extrn	 EMM_E88:near
	 extrn	 EMM_E8A:near
	 extrn	 EMM_E8B:near
	 extrn	 EMM_E8F:near

	 extrn	 FLUSH_TLB:near

	 extrn	 INTPROC00Z:near
	 extrn	 INTPROCFE:near

	 extrn	 CHECK_PART:near

	 extrn	 ALLOCMEM:near
	 extrn	 DEALLOCMEM:near
	 extrn	 QRY_PGCNT:near

	 extrn	 ENABLE_P5:far
	 extrn	 DISABLE_P5:far
	extrn	PnP_TO_VCPI:near
	extrn	PnP_FR_VCPI:near

if @VCP_OLD
	 FPPROC  INTFE -- Old VCPI Entry Point
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Old VCPI entry point.

|

INTFE_STR struc

INTFE_EIP dd	 ?		; Caller's EIP
INTFE_CS  dw	 ?,?		;	   CS
INTFE_EFL dd	 ?		;	   EFL

INTFE_STR ends

if @OEM_DPMI
	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit VM86 mode?
	 jz	 near ptr INTPROCFE ; Jump if so (INTCOM catches DPMI calls)
endif				; IF @OEM_DPMI
	 cmp	 [esp].INTFE_CS,seg PGROUP ; Check against device driver's CS
	 org	 $-2
	 public  INTFE_HIMEM_CS
INTFE_HIMEM_CS label near
	 org	 $+2
	 jne	 near ptr INTPROCFE ; It's just a plain old INT 0FEh

	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All EGP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 [ebp].INTXX_INTNO,4*0FEh + offset PGROUP:INTPROC00Z ; Mark as INT 0FEh

	 push	 DTE_DS 	; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 DTE_DS 	; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 ecx,[ebp].INTXX_EIP ; Get offset of INTCOM-restartable point
	 xchg	 ecx,LAST_INTCOM ; Swap with previous frame offset
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 ecx,0		; Save previous flag
	 mov	 [ebp].INTXX_ICOMLO,cx ; Save it
	 shr	 ecx,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_ICOMHI,cx ; Save it

;;;;;;;; test	 DB2_FLAG,@DB2_VCPI ; Debug old VCPI?
;;;;;;;; jz	 short @F	; Not this time
;;;;;;;;
;;;;;;;; int	 01h		; Call out the SWAT team
@@:
	 cmp	 ah,0Ch 	; Check for # free pages code
	 je	 near ptr VCPI03 ; Jump if it's a match

	 cmp	 ah,10h 	; Check major function code
	 jne	 near ptr EMM_E84 ; Jump if not valid

	 cmp	 al,OLDVCPI_CNT ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 cld			; Ensure string ops forwardly

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 OLDVCPI_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTFE	 endp			; End INTFE procedure
endif				; IF @VCP_OLD
if @VCP_OLD
	 NPPROC  OLDVCPI00 -- Old VCPI V86 Mode Interface
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Old VCPI Function, AX = 1000h

VCPI V86 Mode Interface

On entry:

ES:DI3	 ==>	 4KB page table buffer
DS:SI3	 ==>	 two GDT entries

On exit:

DI	 =	 next available entry in PDE
EAX	 =	 offset of PM entry point

All registers except EBP, SS, and ESP may be destroyed.

|

	 call	 VCPI_V86MODE	; Use subroutine

	 mov	 eax,offset cs:PMOLDVCPI ; Get return value
	 mov	 [ebp].INTXX_EAX,eax ; Save offset of our entry point

	 jmp	 EMM_EXIT	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OLDVCPI00 endp			; End OLDVCPI00 procedure
endif				; IF @VCP_OLD
if @VCP_OLD
	 NPPROC  OLDVCPI03 -- Old VCPI Read CR0
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = 1003h

VCPI read CR0.

On exit:

EAX	 =	 CR0

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 eax,cr0	; Get current CR0
	 mov	 [ebp].INTXX_EAX,eax ; Return to caller

	 jmp	 EMM_EXIT	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OLDVCPI03 endp			; End OLDVCPI03 procedure
endif				; IF @VCP_OLD
	 NPPROC  EMM_VCPI -- VCPI Functions
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AH = DEh

All VCPI functions come through here.

Error return 8F if subfunction parameter invalid

All registers except EBP, SS, and ESP may be destroyed.

|

	 cmp	 al,VCPI_CNT	; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 cld			; Ensure string ops forwardly

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 VCPI_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMM_VCPI endp			; End EMM_VCPI procedure
	 NPPROC  VCPI00 -- VCPI Presence Test
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE00h

VCPI presence test

On exit:

AH	 =	 0 if present
BX	 =	 version #

All registers except EBP, SS, and ESP may be destroyed.

|

	 test	 DPM_FLAG,mask $DPM_NOVCPI ; Should we close the back door?
	 jnz	 near ptr EMM_E84 ; Jump if so

	 mov	 [ebp].INTXX_EBX.ELO,0100h ; Return version #

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI00	 endp			; End VCPI00 procedure
	 NPPROC  VCPI01 -- VCPI V86 Mode Interface
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE01h

VCPI V86 Mode Interface

On entry:

ES:DI3	 ==>	 4KB page table buffer
DS:SI3	 ==>	 three GDT entries

On exit:

AH	 =	 0 if success
DI	 =	 next available entry in PDE
EBX	 =	 offset of PM entry point

All registers except EBP, SS, and ESP may be destroyed.

|

	 call	 VCPI_V86MODE	; Use subroutine

	 mov	 [ebp].INTXX_EBX,offset cs:PMVCPI ; Save offset of our entry point

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI01	 endp			; End VCPI01 procedure
	 NPPROC  VCPI_V86MODE -- Old and New VCPI V86 Mode Interface
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Subroutine to OLDVCPI00 and VCPI01.

|

	 mov	 es,SEL_4GB	; Get our all memory selector
	 assume  es:AGROUP	; Tell the assembler about it

; Because of a bug in Lotus 1-2-3 Version 3.1 where they don't
; preserve the contents of the high-order word in certain 32-bit
; register, we must recognize them here.

	 FIXICALL JGROUP:CHECK_LOTUS,DTE_CSJG ; Check for Lotus 1-2-3

; So we accurately reflect the state of extended memory,
; re-map the first 64KB of memory above the 1MB limit into itself

	 call	 WRAP_DISABLE	; Disable the 1MB wrap

; Transfer our PDT's first four megabytes or less to caller's PDE

	 movzx	 edi,[ebp].INTXX_ES ; Get caller's ES
	 shl	 edi,4-0	; Convert from paras to bytes
	 movzx	 eax,[ebp].INTXX_EDI.ELO ; Get caller's DI
	 add	 edi,eax	; ES:EDI = 32-bit linear address
	 mov	 ebx,edi	; Save for later use

	 xor	 esi,esi	; ESI ==> start of PDT
	 mov	 ecx,VCPITOP	; Get top of VCPI PDT transfer (multiple of 4KB)

	 shr	 ecx,(12-2)-0	; Convert from bytes to 4KB in dwords
	 add	 [ebp].INTXX_EDI,ecx ; Skip over our entries in caller's table
	 shr	 ecx,12-(12-2)	; Convert from 4KB in dwords to 4KB

; Copy and remove $PTE_AV? bits from the PTEs

	 call	 COPY_PTE	; Copy and remove 'em

; Save our program's PTEs

	 mov	 cx,PRGSIZE	; Get program size in 1KB
	 add	 cx,4-1 	; Round up to 4KB
	 shr	 cx,12-10	; Convert from 1KB to 4KB
	 mov	 esi,PPDTPRG	; Get offset of PRGBASE in PDT
	 mov	 edi,VCPIBASE	; Get our program base (multiple of 4KB)
	 shr	 edi,(12-2)-0	; Convert from bytes to 4KB in dwords
	 add	 edi,ebx	; Plus base of caller's PDE

; Copy and remove $PTE_AV? bits from the PTEs

	 call	 COPY_PTE	; Copy and remove 'em

; Copy PnP BIOS PTes to immediately follow the ones we have
; already copied.  The above code doesn't concern itself with
; the extra PTEs as it never needed those before, so we need
; to do it ourselves (isn't that always the case).
; This means that the PnP BIOS is at a different offset in PGROUP than
; it is outside VCPI, so we need to calculate a differencing value.

	cmp	PnP_SEG,0	; Izit present?
	je	short VCPI_V86MODE1 ; Jump if not

	movzx	edi,[ebp].INTXX_ES ; Get caller's ES
	shl	edi,4-0 	; Convert from paras to bytes
	movzx	eax,[ebp].INTXX_EDI.ELO ; Get caller's DI (as modified above)
	add	edi,eax 	; ES:EDI = 32-bit linear address

; Calculate the PnP BIOS's new linear address

	mov	eax,edi 	; Copy current address
	sub	eax,ebx 	; Less initial address
	shl	eax,(12-2)-0	; Convert from 4KB in dwords to bytes
				; to get offset in PGROUP to PnP BIOS
	add	eax,PRGBASE	; Plus linear address of our base
	sub	eax,VCPIBASE	; Less linear address of our VCPI base
	sub	eax,LaPnP_BIOS	; Less the PnP BIOS linear address
	mov	PnP_VCPI_DIFF,eax ; Save for later use

	mov	eax,@PnP_BIOS_BEG or @PTE_URP ; Get starting physical address
				; marked as User/Read-Write/Present
	mov	ecx,@PnP_NPTES	; Get # PTEs to fill in
@@:
S32	stos	AGROUP:[edi].PDT_PTE ; Save in PDT
	add	eax,CON4KB	; Skip to next PTE

	loop	@B		; Jump if more PTEs to fill in

	add	[ebp].INTXX_EDI,@PnP_NPTES*(type PDT_PTE) ; Skip over our entries in caller's table
VCPI_V86MODE1:

; Save the global DTEs we need

	 movzx	 edi,[ebp].INTXX_DS ; Get caller's DS
	 shl	 edi,4-0	; Convert from paras to bytes
	 movzx	 eax,[ebp].INTXX_ESI.ELO ; Get caller's SI
	 add	 edi,eax	; ES:EDI = 32-bit linear address

	 mov	 eax,VCPIBASE	; Get base of our VCPI program
	 movzx	 ecx,PRGSIZE	; Get length of our program in 1KB
	 shl	 ecx,10-0	; Convert from 1KB to bytes
	 add	 ecx,PDTLEN	; Plus length of PDT in bytes
	 dec	 ecx		; Convert from length to limit
	 mov	 ebx,0*(size DESC_STR) ; EBX = selector
	 mov	 dl,0		; DL = DTE flags
	 mov	 dh,CPL0_CODE	; DH = ARB
	 call	 GDTSET 	; Setup the GDT entry

; Limit and base already set above

	 mov	 ebx,1*(size DESC_STR) ; EBX = selector
	 mov	 dl,mask $DTE_B ; DL = DTE flags
	 mov	 dh,CPL0_DATA or CPL0 ; DH = ARB
	 call	 GDTSET 	; Setup the GDT entry

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI_V86MODE endp		; End VCPI_V86MODE procedure
	 NPPROC  VCPI02 -- VCPI Maximum Physical Address
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE02h

VCPI get maximum physical memory address

On exit:

AH	 =	 0 if success
EDX	 =	 maximum physical address that can be allocated

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 eax,VCPIMAX	; Get maximum VCPI physical address
	 mov	 [ebp].INTXX_EDX,eax ; Return in caller's EDX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI02	 endp			; End VCPI02 procedure
	 NPPROC  VCPI03 -- VCPI Count Free Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE03h

VCPI get number of free 4KB pages

On exit:

AH	 =	 0 if success
EDX	 =	 # free 4KB pages

All registers except EBP, SS, and ESP may be destroyed.

|

	 call	 VCPI_COUNT	; Get free count into EDX
	 mov	 [ebp].INTXX_EDX,edx ; Return in caller's EDX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI03	 endp			; End VCPI03 procedure
	 NPPROC  VCPI04 -- VCPI Allocate A Page
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE04h

VCPI allocate a 4KB page

On exit:

AH	 =	 0 if success
EDX	 =	 physical address of allocated 4KB page

Error return 88 if none available

All registers except EBP, SS, and ESP may be destroyed.

|

	 call	 VCPI_ALLOC	; Allocate a 4KB page into EDX
	 jc	 near ptr EMM_E88 ; Jump if no more available

	 mov	 [ebp].INTXX_EDX,edx ; Save in caller's EDX

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI04	 endp			; End VCPI04 procedure
	 NPPROC  VCPI05 -- VCPI De-allocate A Page
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE05h

VCPI de-allocate a 4KB page

On entry:

EDX	 =	 physical address of allocated 4KB page

On exit:

AH	 =	 0 if success

Error return 8A if not allocated

All registers except EBP, SS, and ESP may be destroyed.

|

	 call	 VCPI_DEALLOC	; De-allocate the 4KB page in EDX
	 jc	 near ptr EMM_E8A ; Jump if we couldn't find the page

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI05	 endp			; End VCPI05 procedure
	 NPPROC  VCPI06 -- VCPI Map Linear to Physical
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE06h

VCPI map linear to physical address

On entry:

CX	 =	 linear address SHR 12

On exit:

AH	 =	 0 if success
EDX	 =	 physical address corresponding to linear address

Error return 8B if linear address is out of range.

All registers except EBP, SS, and ESP may be destroyed.

|

; So we accurately reflect the state of extended memory,
; re-map the first 64KB of memory above the 1MB limit into itself

	 call	 WRAP_DISABLE	; Disable the 1MB wrap

	 movzx	 eax,[ebp].INTXX_ECX.ELO ; Get frame value in 4KB
	 shl	 eax,12-(12-2)	; Convert from 4KB to 4KB in dwords

	 cmp	 eax,PDTLEN	; Check against length of PDT
	 jae	 near ptr EMM_E8B ; Jump if out of range

	 add	 eax,PRGPDT	; Plus offset in PGROUP of PDT
	 mov	 eax,PGROUP:[eax].PDT_PTE ; Get the corresponding PTE
	 and	 ax,mask $PTE_FRM ; Isolate the frame
	 mov	 [ebp].INTXX_EDX,eax ; Return to caller

; Note that WRAP_ENABLE is called at EMM_EXIT

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI06	 endp			; End VCPI06 procedure
	 NPPROC  VCPI07 -- VCPI Read CR0
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE07h

VCPI read CR0.

On exit:

AH	 =	 0 if success
EBX	 =	 CR0

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 eax,cr0	; Get current CR0
	 mov	 [ebp].INTXX_EBX,eax ; Return to caller

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI07	 endp			; End VCPI07 procedure
	 NPPROC  VCPI08 -- VCPI Read DRn
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE08h

VCPI read CRn.

On entry:

ES:DI	 ==>	 output array

On exit:

AH	 =	 0 if success

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 es,SEL_4GB	; Get our all memory selector
	 assume  es:AGROUP	; Tell the assembler about it

	 movzx	 eax,[ebp].INTXX_ES ; Get caller's ES
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 edi,[ebp].INTXX_EDI.ELO ; Get caller's DI
	 add	 edi,eax	; ES:EDI ==> caller's ES:DI

	 mov	 eax,dr0	; Get current DR0
S32	 stos	 AGROUP:[edi].EDD ; Save in caller's save area

	 mov	 eax,dr1	; Get current DR1
S32	 stos	 AGROUP:[edi].EDD ; Save in caller's save area

	 mov	 eax,dr2	; Get current DR2
S32	 stos	 AGROUP:[edi].EDD ; Save in caller's save area

	 mov	 eax,dr3	; Get current DR3
S32	 stos	 AGROUP:[edi].EDD ; Save in caller's save area

	 add	 edi,2*4	; Skip over DR4 and DR5

	 mov	 eax,dr6	; Get current DR6
S32	 stos	 AGROUP:[edi].EDD ; Save in caller's save area

	 mov	 eax,dr7	; Get current DR7
S32	 stos	 AGROUP:[edi].EDD ; Save in caller's save area

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI08	 endp			; End VCPI08 procedure
	 NPPROC  VCPI09 -- VCPI Load DRn
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE09h

VCPI load CRn.

On entry:

ES:DI	 ==>	 input array

On exit:

AH	 =	 0 if success

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 ds,SEL_4GB	; Get our all memory selector
	 assume  ds:AGROUP	; Tell the assembler about it

	 movzx	 eax,[ebp].INTXX_ES ; Get caller's ES
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,[ebp].INTXX_EDI.ELO ; Get caller's DI
	 add	 esi,eax	; DS:ESI ==> caller's ES:DI

	 lods	 AGROUP:[esi].EDD ; Get new DR0
	 mov	 dr0,eax	; Save in DR0

	 lods	 AGROUP:[esi].EDD ; Get new DR1
	 mov	 dr1,eax	; Save in DR1

	 lods	 AGROUP:[esi].EDD ; Get new DR2
	 mov	 dr2,eax	; Save in DR2

	 lods	 AGROUP:[esi].EDD ; Get new DR3
	 mov	 dr3,eax	; Save in DR3

	 add	 esi,2*4	; Skip over DR4 and DR5

	 lods	 AGROUP:[esi].EDD ; Get new DR6
	 mov	 dr6,eax	; Save in DR6

	 lods	 AGROUP:[esi].EDD ; Get new DR7
	 mov	 dr7,eax	; Save in DR7

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI09	 endp			; End VCPI09 procedure
	 NPPROC  VCPI0A -- VCPI Get IMR Bases
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE0Ah

VCPI get IMR bases.

On exit:

AH	 =	 0 if success
BX	 =	 master IMR base
CX	 =	 slave	IMR base

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 ax,NEWIMR1	; Get current master IMR base
	 mov	 [ebp].INTXX_EBX.ELO,ax ; Save ...

	 mov	 ax,NEWIMR2	; Get current slave  IMR base
	 mov	 [ebp].INTXX_ECX.ELO,ax ; Save ...

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI0A	 endp			; End VCPI0A procedure
	 NPPROC  VCPI0B -- VCPI Set IMR Bases
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE0Bh

VCPI set IMR bases.

On entry:

BX	 =	 master IMR base
CX	 =	 slave	IMR base

On exit:

AH	 =	 0 if success

All registers except EBP, SS, and ESP may be destroyed.

|

	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get master IMR base
	 mov	 NEWIMR1,ax	; Save for later use

	 mov	 ax,[ebp].INTXX_ECX.ELO ; ... slave
	 mov	 NEWIMR2,ax	; Save for later use

if @OEM_DPMI
	 FIXICALL JGROUP:SET_HWSP,DTE_CSJG
				; Set DPMI_HWSP values for special interrupts
endif				; IF @OEM_DPMI

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI0B	 endp			; End VCPI0B procedure
	 NPPROC  VCPI0C -- VCPI Enter Protected Mode
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI Function, AX = DE0Ch

VCPI enter protected mode

On entry:

ESI	 =	 linear address of input data structure

On exit:

AH	 =	 0 if success

All registers except EBP, SS, and ESP may be destroyed.

|

	 cli			; Disallow interrupts

if @OEM_VIRTUALMEM
	 call	 VMM_DRAIN_POOL ; Drain the pool if it's filled

	 or	 VMM_FLAG,@VMM_VCPIACTIV ; Mark for VMM as active
endif				; IF @OEM_VIRTUALMEM

	 mov	 esi,[ebp].INTXX_ESI ; GS:ESI ==> caller's EPM_STR

; Restore previous LAST_INTCOM

	 mov	 ax,[ebp].INTXX_ICOMHI ; Get previous frame offset
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_ICOMLO ; Get previous frame offset
	 btr	 ax,$INTCOM_VAL ; Move previous setting to CF
	 setc	 LAST_INTFLG.LO ; Move previous setting to memory
	 mov	 LAST_INTCOM,eax ; Restore it

	 mov	 esp,ebp	; Cut back the stack
VCPI0C_COM:
	 mov	 LAST_ESP,esp	; Save as lowest stack pointer

	 lea	 eax,[esp-256]	; Current stack top less some slop
	 mov	 NEWVCPSTK_FVEC.FOFF,eax ; Save as new stack offset

if @OEM_DPMI
	 mov	 ax,VM2PM_TSS	; Get current TSS selector
	 mov	 EPMTAB.EPM_TR,ax ; Save as our TR
endif				; IF @OEM_DPMI

	 call	 VCP_MODESUB	; Handle via subroutine

	 popad			; Restore caller's EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

; Install the caller's variables

	 mov	 ds,SEL_4GB	; Get our all memory selector
	 assume  ds:AGROUP	; Tell the assembler about it

;....... xor	 ax,ax		; A convenient zero		;.......
;....... mov	 es,ax		; ...				;.......
;....... assume  es:nothing	; Tell the assembler about it	;.......
;....... mov	 fs,ax		; ...				;.......
;....... assume  fs:nothing	; Tell the assembler about it	;.......
;....... mov	 gs,ax		; ...				;.......
;....... assume  gs:nothing	; Tell the assembler about it	;.......

; DS:ESI ==>	 caller's EPMTAB

if @OEM_DEBUG
	 test	 DB2_FLAG,@DB2_VMS ; Check out the VCPI mode switch?
	 jz	 short @F	; Not this time

	 call	 CHECK_EPM	; Validate the EPM structure
@@:
endif				; IF @OEM_DEBUG

	 FCALL	 DISABLE_P5	; Disable P5-specific features

; Because our ESP might be above 64KB and the VCPI client's
; SS might be 16-bit (B-bit clear), we need to ensure that
; the ESP we present to them is <= 64KB.  Otherwise, when we
; regain control (via the callback) we might get a mixed value
; for ESP (our high-order word, their low-order word).

	 movzx	 esp,PLOWSTKZ	; Use a value < 64KB

	 jmp	 VCPI_SET	; Set new values in system variables

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI0C	 endp			; End VCPI0C procedure
if @OEM_VIRTUALMEM
	 NPPROC  VMM_DRAIN_POOL -- Drain The VMM Pool If Filled
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Drain the VMM pool if it's filled

|

	 test	 VMM_FLAG,@VMM_MUSTDRAIN ; Do we need to drain the pool?
	 jz	 short @F	; Jump if not

	 REGSAVE <ecx,ds>	; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 mov	 ecx,-1 	; The whole enchilada
	 FIXICALL IGROUP:PPM_DRAIN_POOL,DTE_CSIG ; Release free pages in page
				; pool to us
				; Returns ECX = # pages actually released
	 REGREST <ds,ecx>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMM_DRAIN_POOL endp		; End VMM_DRAIN_POOL procedure
endif				; IF @OEM_VIRTUALMEM
if @OEM_DEBUG
	 NPPROC  CHECK_EPM -- Validate The EPM Structure
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Validate the EPM structure

On entry:

DS:ESI	 ==>	 caller's EPMTAB

|

	 REGSAVE <eax,ebx,ecx,esi> ; Save registers

; Validate CR3

	 lods	 ds:[esi].EDD	; Get CR3
;;;;;;;; mov	 cr3,eax	; Set new CR3 and flush TLB

	 mov	 cx,1		; Checkpoint #




; Validate GDTR

	 lods	 ds:[esi].EDD	; Get ptr to GDTR

	 mov	 ebx,[eax].DTR_BASE ; Save base address of GDT for later use

;;;;;;;; LGDTD	 ds:[eax].EDF	; Set new GDTR

	 mov	 cx,2		; Checkpoint #



; Note from here on we're depending upon descriptor
; caching of CS, DS, and SS.

; Validate IDTR

	 lods	 ds:[esi].EDD	; Get ptr to IDTR
;;;;;;;; LIDTD	 ds:[eax].EDF	; Set new IDTR

	 mov	 cx,3		; Checkpoint #



; Validate LDTR

	 lods	 ds:[esi].ELO	; Get LDTR
;;;;;;;; lldt	 ax		; Set new LDTR

	 and	 ax,ax		; Check for zero LDTR
	 jz	 short CHECK_EPM1 ; Jump if so

	 movzx	 eax,ax 	; Zero high-order word
	 add	 eax,ebx	; Plus base address of GDT

	 mov	 cx,4		; Checkpoint #

	 cmp	 ds:[eax].DESC_ACCESS,CPL0_LDT ; Ensure it's an LDT
	 jne	 short CHECK_EPM_ERR ; Jump if not
CHECK_EPM1:

; Validate TR

	 lods	 ds:[esi].ELO	; Get TR

	 movzx	 eax,ax 	; Get new TR
	 and	 ds:[eax+ebx].DESC_ACCESS,not (mask $DS_BUSY) ; Mark as not busy
;;;;;;;; ltr	 ax		; Set new TR

	 mov	 cx,5		; Checkpoint #

	 cmp	 ds:[eax+ebx].DESC_ACCESS,CPL0_IDLE3 ; Ensure it's a TSS
	 jne	 short CHECK_EPM_ERR ; Jump if not

; Validate return address

;;;;;;;; jmp	 ds:[esi].EDF	; Return to caller

	 movzx	 eax,ax 	; Zero high-order word
	 lods	 ds:[esi].EDD	; Get offset
	 movzx	 eax,ax 	; Zero high-order word
	 lods	 ds:[esi].ELO	; Get selector

	 mov	 al,ds:[ebx+eax].DESC_ACCESS ; Get the ARB
	 and	 al,not (mask $DC_ACC) ; Clear accessed bit

	 mov	 cx,6		; Checkpoint #

	 cmp	 al,CPL0_CODE	; Ensure it's code
	 jne	 short CHECK_EPM_ERR ; Jump if not








	 jmp	 short CHECK_EPM_EXIT ; Join common exit code

CHECK_EPM_ERR:
	 test	 LCL_FLAG,@LCL_SWAT ; Izit installed?
	 jz	 short CHECK_EPM_EXIT ; Not this time, too bad

	 int	 01h		; Call our debugger
CHECK_EPM_EXIT:
	 REGREST <esi,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EPM endp			; End CHECK_EPM procedure
endif				; IF @OEM_DEBUG
	 NPPROC  VCP_MODESUB -- VCPI Common Mode Subroutine
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI common mode switch subroutine

|

; So we accurately reflect the state of extended memory,
; re-map the first 64KB of memory above the 1MB limit into itself
; It's possible that our caller has allocated some memory in that
; region if EXTSIZE < 64

	 cmp	 EXTSIZE,64	; Is the 1MB wrap region visible to EMS?
	 jae	 short @F	; Jump if not

	 call	 WRAP_DISABLE	; Disable the 1MB wrap
@@:
	 mov	 eax,LCL_CR3	; Get current CR3
	 mov	 EPMTAB.EPM_CR3,eax ; Save in table

; Turn off busy bit in our TSS ??????

;;;;;;;; and	 DESC_TAB.DTE_TSS.DESC_ACCESS,not (mask $DS_BUSY)
;;;;;;;;	 Izit necessary??????
; Install our SWAT handlers

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 QMAX High
GDT	 =	 QMAX High
IDT	 =	 QMAX High
SS	 =	 QMAX High, QMAX's GDT
CS	 =	 QMAX High, QMAX's GDT

|

; Look up caller's PDE in the PTE to find its physical address

	 mov	 gs,SEL_4GB	; Get our all memory selector
	 assume  gs:AGROUP	; Tell the assembler about it

; Handle PnP Issues Upon Entering PM Via VCPI

	call	PnP_TO_VCPI	; Handle 'em

; If we set the high-order bit of CR3, it must be safe to extend
; the same favor to the VCPI routine
; Alas, Phar Lap's VMM uses this value as an index so we can't fix
; Errata 21 this way.

;;;;;;;; test	 LCL_CR3,@BIT31 ; Izit set?
;;;;;;;; jz	 short @F	; Not this time
;;;;;;;;
;;;;;;;; or	 AGROUP:[esi].EPM_CR3,@BIT31 ; Set it
;;:
	 mov	 eax,AGROUP:[esi].EPM_CR3 ; Get caller's CR3
	 and	 ax,mask $PTE_FRM ; Isolate the 4KB frame

	 cmp	 eax,LAST_CR3	; Same as the last time?
	 je	 short VCPI0C_XCR3 ; Yes, don't bother

	 mov	 LAST_CR3,eax	; Save for next time
	 or	 ax,@PTE_URP	; Mark as User/Read-Write/Present

@OFFSEG  equ	 0FF00h 	; Segment in PDT
@OFFPDT  equ	 @OFFSEG shr ((12-2)-4) ; Convert from paras to 4KB in dwords
@OFFBYT  equ	 <@OFFSEG shl (4-0)> ; Convert from paras to bytes

	 mov	 ebx,PRGPDT	; Get offset in PGROUP of PDT

	 push	 PGROUP:[ebx+@OFFPDT].PDT_PTE ; Save the low-order PTE
	 mov	 PGROUP:[ebx+@OFFPDT].PDT_PTE,eax  ; Put caller's CR3 in table
	 call	 FLUSH_TLB	; Flush the TLB

; Because of a bug in MASM 5.10, we can't use AGROUP: here.  If we do,
; MASM 5.10 assembles @OFFBYT as 0000F000 instead of 000FF000.	Thanks.

;;;;;;;; mov	 eax,AGROUP:[@OFFBYT] ; Get first entry in caller's PDE table
	 mov	 eax,gs:[@OFFBYT] ; Get first entry in caller's PDE table

	 pop	 PGROUP:[ebx+@OFFPDT].PDT_PTE ; Restore

	 or	 ax,@PTE_URP	; Mark as User/Read-Write/Present
	 mov	 PHAR_PDE,eax	; Save for later use
VCPI0C_XCR3:
	 mov	 eax,PHAR_PDE	; Get the PDE
	 mov	 esi,OFFCR3	; Get offset to PDE table
	 xchg	 eax,ds:[esi]	; Save as first entry in PDE
	 mov	 QMAX_PDE,eax	; Save original value
	 call	 FLUSH_TLB	; Flush the TLB

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 QMAX High
IDT	 =	 QMAX High
SS	 =	 QMAX High, QMAX's GDT
CS	 =	 QMAX High, QMAX's GDT

|

; Jump to VCPI memory code

	 FIJMP	 PGROUP:@F,DTE_VCOD ; Jump to our VCPI code selector
@@:

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 QMAX High
IDT	 =	 QMAX High
SS	 =	 QMAX High, QMAX's GDT
CS	 =	 VCPI, QMAX's GDT

|

; Transfer to stack in VCPI area

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 PGROUP:[eax].TSS_SS0,DTE_VDAT ; Save in TSS
	 mov	 ss,PGROUP:[eax].TSS_SS0 ; Address it
	 assume  ss:nothing	; Tell the assembler about it
	 nop			; Just for something to do

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 QMAX High
IDT	 =	 QMAX High
SS	 =	 VCPI, QMAX's GDT
CS	 =	 VCPI, QMAX's GDT

|

; Ensure the GDTR points to the one in VCPI memory

;....... LGDTD	 PGDT_VCP					;.......

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 VCPI
IDT	 =	 QMAX High
SS	 =	 VCPI, QMAX's GDT
CS	 =	 VCPI, QMAX's GDT

|

; Ensure the IDTR points to the one in VCPI memory

;....... LIDTD	 PIDT_VCP					;.......

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 VCPI
IDT	 =	 VCPI
SS	 =	 VCPI, QMAX's GDT
CS	 =	 VCPI, QMAX's GDT

|

; Clear ES, FS, and GS

;....... xor	 ax,ax		; A convenient zero		;.......
;....... mov	 es,ax		; Zero it			;.......
;....... assume  es:nothing	; Tell the assembler about it	;.......
;....... mov	 fs,ax		; Zero it			;.......
;....... assume  fs:nothing	; Tell the assembler about it	;.......
;....... mov	 gs,ax		; Zero it			;.......
;....... assume  gs:nothing	; Tell the assembler about it	;.......

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCP_MODESUB endp		; End VCP_MODESUB procedure
	 FPPROC  CHECK_LOTUS_OLD -- Buggy Code in Lotus 1-2-3
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
CHECK_LOTUS_OLD0 label byte
	 mov	 ax,[bp+04h]
	 mov	 ds:[0062h],ax

	 mov	 al,[bp+06h]
	 mov	 ds:[0064h],al
CHECK_LOTUS_OLDLEN equ $-CHECK_LOTUS_OLD0
	 mov	 al,[bp+07h]	; New code to fix the bug
	 mov	 ds:[0067h],al

	 mov	 cx,[bp+0Ah]	; More old code

	 push	 60h
	 pop	 ds
	 assume  ds:nothing	; Tell the assembler about it

	 ret

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_LOTUS_OLD endp		; End CHECK_LOTUS_OLD procedure
	 NPPROC  CHECK_LOTUSPF -- Check On Lotus 1-2-3 Page Fault
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on Lotus 1-2-3 Page Faults

In Lotus 1-2-3 version 3.1, if the DOS extender encounters
enough memory for it to define linear addresses above 16MB,
it encounters a bug in its own code which causes it to signal
a Page Fault when exiting.

This code checks for that condition, and if present, patches
the executable in memory to call our own routine which fixes
the problem.

Note that this code is called under control of the VCPI
client's tables.

On entry:

DF	 =	 0

|

	 REGSAVE <eax,cx,si,di,es> ; Save registers

; See if we can match a signature code at 18|1040
; (with a read-write alias using selector 0048h)

	 mov	 ax,0018h	; Get the code selector

	 verr	 ax		; Izit readable?
	 jnz	 short CHECK_LOTUSPF_EXIT ; Jump if not

	 verw	 ax		; Izit writable?
	 jz	 short CHECK_LOTUSPF_EXIT ; Jump if so

	 lsl	 eax,eax	; Get the 32-bit limit
	 jmp	 short $+2	; Avoid Errata #20

	 cmp	 eax,2000h	; Izit within limits?
	 jb	 short CHECK_LOTUSPF_EXIT ; Jump if not

	 mov	 ax,0048h	; Get the data selector

	 verr	 ax		; Izit readable?
	 jnz	 short CHECK_LOTUSPF_EXIT ; Jump if not

	 verw	 ax		; Izit writable?
	 jnz	 short CHECK_LOTUSPF_EXIT ; Jump if not

	 lsl	 eax,eax	; Get the 32-bit limit
	 jmp	 short $+2	; Avoid Errata #20

	 cmp	 eax,2000h	; Izit within limits?
	 jb	 short CHECK_LOTUSPF_EXIT ; Jump if not

	 mov	 ax,0048h	; Get the data selector
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

@LOTUS_BASE1 equ  1040h 	 ; Starting address of code to match
@LOTUS_BASE2 equ  @LOTUS_BASE1+CHECK_LOTUS_OLDLEN ; ...        patch

	 mov	 cx,CHECK_LOTUS_OLDLEN ; CX = # bytes to compare
	 mov	 di,@LOTUS_BASE1 ; Starting address in their code
	 lea	 si,CHECK_LOTUS_OLD0
    repe cmps	 CHECK_LOTUS_OLD0[si],es:[di].LO ; Duzit match?
	 jne	 short CHECK_LOTUSPF_EXIT ; Jump if not

; It's a match:  blast in a call to our code

	 mov	 es:[@LOTUS_BASE2+0].LO,@OPCOD_CALLF
	 mov	 es:[@LOTUS_BASE2+1].VOFF,offset cs:CHECK_LOTUS_OLD ; Offset
	 mov	 es:[@LOTUS_BASE2+1].VSEG,cs ; Segment
	 mov	 es:[@LOTUS_BASE2+5].LO,@OPCOD_NOP
CHECK_LOTUSPF_EXIT:
	 REGREST <es,di,si,cx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_LOTUSPF endp		; End CHECK_LOTUSPF procedure
	 FPPROC  PMVCPI -- VCPI Protected Mode Entry Point
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VCPI protected mode entry point.
Note that the stack might be Big.

On entry:

AH	 =	 function #

|

	 pushf			; Save flags

	 cld			; Ensure string ops forwardly
	 cli			; Disallow interrupts

	 cmp	 ax,0DE0Ch	; Check for Enter VM86 mode
	 je	 near ptr PMVCPI0C ; Good guess

	 cmp	 ah,0DEh	; Check major function code
	 jne	 short PMVCPI_E84 ; Jump if invalid function code

	 cmp	 LOTUS_EMSHNDL,0 ; Is Lotus 1-2-3 still active?
	 je	 short @F	; Jump if not

	 call	 CHECK_LOTUSPF	; See if we should patch the Lotus 1-2-3
@@:				; Page Fault
	 cmp	 al,03h 	; Check for Get # Free Pages
	 je	 short PMVCPI03 ; Good guess

	 cmp	 al,04h 	; Check for Allocate a 4KB Page
	 je	 short PMVCPI04 ; Good guess

	 cmp	 al,05h 	; Check for Free a Page
	 je	 short PMVCPI05 ; Good guess

	 mov	 ah,8Fh 	; Mark as invalid subfunction

	 jmp	 PMVCPI_EXIT	; Join common exit code


if @VCP_OLD
	 public  PMOLDVCPI
PMOLDVCPI:
	 pushf			; Save flags

	 cld			; Ensure string ops forwardly
	 cli			; Disallow interrupts

	 cmp	 ax,100Ah	; Check for Enter VM86 mode
	 je	 near ptr PMVCPI0C ; Good guess

	 cmp	 ah,0Ch 	; Check for Get # Free Pages
	 je	 short PMVCPI03 ; Good guess

	 cmp	 ah,10h 	; Check major function code
	 jne	 short PMVCPI_E84 ; Jump if invalid function code

	 cmp	 al,04h 	; Check for Allocate a 4KB Page
	 je	 short PMVCPI04 ; Good guess

	 cmp	 al,05h 	; Check for Free a Page
	 je	 short PMVCPI05 ; Good guess

	 mov	 ah,8Fh 	; Mark as invalid subfunction

	 jmp	 PMVCPI_EXIT	; Join common exit code
endif				; IF @VCP_OLD


PMVCPI_E84:
	 mov	 ah,84h 	; Mark as invalid function

	 jmp	 PMVCPI_EXIT	; Join common exit code


	 public  PMVCPI03
PMVCPI03:			; Get # Free Pages
	 REGSAVE <ax,ds>	; Save for a moment

	 mov	 ax,cs		; Copy code selector
	 add	 ax,size DESC_STR ; Skip to next DTE
	 mov	 ds,ax		; Address as data selector
	 assume  ds:PGROUP	; Tell the assembler about it

; In case we're called on too small a stack, switch it now
; Note that this code is never called re-entrantly

	 mov	 NEWVCPSTK_FVEC.FSEL,ax ; Save as stack selector

	 mov	 OLDVCPSTK_FVEC.FOFF,esp ; Save to restore later
	 mov	 OLDVCPSTK_FVEC.FSEL,ss ; ...

	 lss	 esp,NEWVCPSTK_FVEC ; Use new stack
	 assume  ss:nothing	; Tell the assembler about it

	 call	 VCPI_COUNT	; Get free count into EDX

	 lss	 esp,OLDVCPSTK_FVEC ; Restore old stack
	 assume  ss:nothing	; Tell the assembler about it

	 REGREST <ds,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 short PMVCPI_E00 ; Join common OK code


	 public  PMVCPI04
PMVCPI04:			; Allocate a 4KB Page
	 REGSAVE <ax,ds>	; Save for a moment

	 mov	 ax,cs		; Copy code selector
	 add	 ax,size DESC_STR ; Skip to next DTE
	 mov	 ds,ax		; Address as data selector
	 assume  ds:PGROUP	; Tell the assembler about it

; In case we're called on too small a stack, switch it now
; Note that this code is never called re-entrantly

	 mov	 NEWVCPSTK_FVEC.FSEL,ax ; Save as stack selector

	 mov	 OLDVCPSTK_FVEC.FOFF,esp ; Save to restore later
	 mov	 OLDVCPSTK_FVEC.FSEL,ss ; ...

	 lss	 esp,NEWVCPSTK_FVEC ; Use new stack
	 assume  ss:nothing	; Tell the assembler about it

	 call	 VCPI_ALLOC	; Allocate a 4KB page into EDX
				; Note CF carried for a while

	 lss	 esp,OLDVCPSTK_FVEC ; Restore old stack
	 assume  ss:nothing	; Tell the assembler about it

	 REGREST <ds,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 jnc	 short PMVCPI_E00 ; Join common OK code

	 mov	 ah,88h 	; Return error code for no more

	 jmp	 short PMVCPI_EXIT ; Join common exit code


	 public  PMVCPI05
PMVCPI05:			; Free a Page
	 REGSAVE <ax,ds>	; Save for a moment

	 mov	 ax,cs		; Copy code selector
	 add	 ax,size DESC_STR ; Skip to next DTE
	 mov	 ds,ax		; Address as data selector
	 assume  ds:PGROUP	; Tell the assembler about it

; In case we're called on too small a stack, switch it now
; Note that this code is never called re-entrantly

	 mov	 NEWVCPSTK_FVEC.FSEL,ax ; Save as stack selector

	 mov	 OLDVCPSTK_FVEC.FOFF,esp ; Save to restore later
	 mov	 OLDVCPSTK_FVEC.FSEL,ss ; ...

	 lss	 esp,NEWVCPSTK_FVEC ; Use new stack
	 assume  ss:nothing	; Tell the assembler about it

	 call	 VCPI_DEALLOC	; De-allocate the 4KB page in EDX
				; Note CF carried for a while

	 lss	 esp,OLDVCPSTK_FVEC ; Restore old stack
	 assume  ss:nothing	; Tell the assembler about it

	 REGREST <ds,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 jnc	 short PMVCPI_E00 ; Jump if successful

	 mov	 ah,8Ah 	; Jump if we couldn't find it

	 jmp	 short PMVCPI_EXIT ; Join common exit code

PMVCPI_E00:
	 mov	 ah,0		; Mark as a success
PMVCPI_EXIT:
	 popf			; Restore flags

	 RETFD			; Return to caller (32-bit)


	 public  PMVCPI0C
PMVCPI0C:			; Enter VM86 Mode

; On entry:
; DS	 =	 caller's all memory selector with B-bit set
; SS	 =	 caller's stack selector with B-bit set
; SS:ESP ==>	 INTCOM_STR preceded by a 32-bit far call return
;		 address preceded by FL.

COMMENT|

System status:

CR3	 =	 Caller
CR3[0]	 =	 Caller
GDT	 =	 Caller
IDT	 =	 Caller
LDT	 =	 Caller
SS	 =	 Caller, caller's GDT
CS	 =	 VCPI, caller's GDT

|

; Set VM and IOPL bits in VM86 stack

	 add	 esp,2*4+2	; Skip over 32-bit far call return address
				; and FL
	 mov	 [esp].INTCOM_EFL,(mask $VMHI) or (@VMIOPL shl $IOPL) ; VM=1, IOPL=@VMIOPL

; Get addressibility to data area

	 mov	 ax,cs		; Copy code selector
	 add	 ax,size DESC_STR ; Skip to next DTE
	 mov	 es,ax		; Address as data selector
	 assume  es:PGROUP	; Tell the assembler about it

; Copy current stack to local area

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,esi,edi>	; Save registers

;;;;;;;; mov	 edi,PCURTSS	; Get offset in PGROUP of current TSS
;;;;;;;; mov	 edi,PGROUP:[edi].TSS_ESP0 ; Get current top-of-stack pointer
	 mov	 edi,LAST_ESP	; Get lowest stack pointer
	 sub	 edi,256	; Give 'em room
	 mov	 ecx,size INTCOM_STR ; Get size of structure
	 sub	 edi,ecx	; Back off to start
	 mov	 esi,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 PGROUP:[esi].TSS_ESP2,edi ; Save for later use
	 lea	 esi,[ebp+4]	; SS:ESI ==> start of stack
S32  rep movs	 <es:[edi].LO,ss:[esi].LO> ; Copy to friendly territory

	 REGREST <edi,esi,ecx>	; Restore

	 pop	 ebp		; Restore

; Transfer to stack in local area

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 PGROUP:[eax].TSS_SS2,es ; Save selector
	 lss	 esp,PGROUP:[eax].TSS_ESP2.EDF ; Load SS:ESP
	 assume  ss:nothing	; Tell the assembler about it

COMMENT|

System status:

CR3	 =	 Caller
CR3[0]	 =	 VCPI
GDT	 =	 Caller
IDT	 =	 Caller
LDT	 =	 VCPI, caller's GDT
SS	 =	 VCPI, caller's GDT
CS	 =	 VCPI, caller's GDT

|

; Setup system variables

	 call	 VCPI_SET1	; Set new values in system variables
	 assume  ds:nothing,es:nothing
	 assume  fs:nothing,gs:nothing

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 VCPI
IDT	 =	 VCPI
LDT	 =	 VCPI, caller's GDT
SS	 =	 VCPI, QMAX's GDT
CS	 =	 VCPI, QMAX's GDT

|

	 FIJMP	 PGROUP:@F,DTE_CS2 ; Jump to high memory
@@:

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 VCPI
IDT	 =	 VCPI
LDT	 =	 VCPI, caller's GDT
SS	 =	 VCPI, QMAX's GDT
CS	 =	 QMAX high, QMAX's GDT

|

	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

; Ensure the GDTR points to the one in high linear memory

	 LGDTD	 PGDT_LHI

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 QMAX High
IDT	 =	 VCPI
LDT	 =	 VCPI, caller's GDT
SS	 =	 VCPI, QMAX's GDT
CS	 =	 QMAX high, QMAX's GDT

|

; Ensure the IDTR points to the one in high linear memory

	 LIDTD	 PIDT_LHI

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 QMAX High
IDT	 =	 QMAX High
LDT	 =	 VCPI, caller's GDT
SS	 =	 VCPI, QMAX's GDT
CS	 =	 QMAX high, QMAX's GDT

|

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 PGROUP:[eax].TSS_SS0,DTE_DS ; Save in TSS
	 mov	 ss,PGROUP:[eax].TSS_SS0 ; Address it
	 assume  ss:nothing	; Tell the assembler about it
	 nop			; Just for something to do

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 QMAX High
IDT	 =	 QMAX High
LDT	 =	 VCPI, caller's GDT
SS	 =	 QMAX High, QMAX's GDT
CS	 =	 QMAX High, QMAX's GDT

|

; Change to QMAX's LDT

;;;;;;;; mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS (already in EAX)
	 lldt	 PGROUP:[eax].TSS_LDT ; Restore it

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 QMAX High
IDT	 =	 QMAX High
LDT	 =	 QMAX High, QMAX's GDT
SS	 =	 QMAX High, QMAX's GDT
CS	 =	 QMAX High, QMAX's GDT

|

	 push	 esi		; Save for a moment

	 mov	 eax,QMAX_PDE	; Get original value
	 mov	 esi,OFFCR3	; Get offset to PDE table
	 mov	 ds:[esi],eax	; Save as first entry in PDE

	 pop	 esi		; Restore

	 call	 FLUSH_TLB	; Flush the TLB

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 QMAX High
GDT	 =	 QMAX High
IDT	 =	 QMAX High
LDT	 =	 QMAX High, QMAX's GDT
SS	 =	 QMAX High, QMAX's GDT
CS	 =	 QMAX High, QMAX's GDT

|

if @OEM_VIRTUALMEM
	 and	 VMM_FLAG,not @VMM_VCPIACTIV ; Mark for VMM as no longer active
endif				; IF @OEM_VIRTUALMEM

; Note that we can't call ENABLE_P5 until we're back on our own GDT.
	 FCALL	 ENABLE_P5	; Enable P5-specific features

; Handle PnP Issues Upon Returning from PM Via VCPI

	call	PnP_FR_VCPI	; Handle 'em
	assume	gs:nothing	; Tell the assembler about it

	 cmp	 DMA_CHAN,0	; Any DMA transfers in progress?
	 jne	 short @F	; Yes, see if any have terminated
				; All segment registers clobbered
	 iretd			; Return to VM86 mode
@@:
	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 lea	 eax,[esp].INTCOM_EIP ; Get INTCOM-restartable point
	 xchg	 eax,LAST_INTCOM ; Swap with the previous one
	 bts	 LAST_INTFLG,$INTCOM_VAL ; Copy previous flag and mark as valid
	 adc	 eax,0		; Save previous flag

	 call	 CHECK_PART	; Check on partial DMA transfers in progress
	 assume  es:nothing,fs:nothing ; Tell the assembler about it

	 btr	 ax,$INTCOM_VAL ; Move previous setting to CF
	 setc	 LAST_INTFLG.LO ; Move previous setting to memory
	 mov	 LAST_INTCOM,eax ; Restore original address

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 iretd			; Return to VM86 mode

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMVCPI	 endp			; End PMVCPI procedure
	 NPPROC  VCPI_COUNT -- VCPI Get Count of Free Pages
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get count of # available 4KB pages.

Note the stack might have its B-bit set, so all
explicit stack references *MUST* be 32-bit.

On exit:

EDX	 =	 # avaiable 4KB pages

|

	 REGSAVE <eax>		; Save registers

	 push	 @ALLOC_VCPI	; Pass allocation type
	 call	 QRY_PGCNT	; Return with EAX = # available 1KB

	 shr	 eax,12-10	; Convert from 1KB to 4KB
	 mov	 edx,eax	; Copy to return register

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI_COUNT endp 		; End VCPI_COUNT procedure
	 NPPROC  VCPI_ALLOC -- VCPI Allocate
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate a 4KB page.

On exit:

CF	 =	 1 if not enough memory
	 =	 0 otherwise, and
EDX	 =	 physical page allocated

|

	 REGSAVE <ebx>		; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

; Check for available memory
; If none, exit normally

	 push	 @ALLOC_VCPI	; Tell 'em what kind of memory we're allocating
	 push	 CON4KB 	; Pass # bytes to allocate
	 call	 ALLOCMEM	; Allocate 'em
				; Return with EBX = linear address of memory
	 jc	 short VCPI_ALLOC_ERR ; Jump if no memory found

; Return the corresponding physical address

	 shr	 ebx,(12-2)-0	; Convert from bytes to 4KB in dwords

; DS:EBX = address of PTEs in PDT for this 4KB page

; Check for an address in the 1MB wrap region.
; If so, use the PTEs in the CHECK_VDISK region

	 cmp	 ebx,PPDT1MB	; Izit at or above 1MB?
	 jb	 short @F	; Jump if not

	 cmp	 ebx,PPDT1P1MB	; Izit at or above 1.1MB?
	 jae	 short @F	; Jump if so

	 sub	 ebx,PPDT1MB	; Convert to origin-1MB
	 add	 ebx,PPDTCVD	; Convert to origin-CVD
@@:
	 mov	 edx,PRGPDT	; Get offset of PDT from PRGBASE
	 mov	 edx,PGROUP:[edx+ebx].PDT_PTE ; Get the physical address
	 and	 dx,mask $PTE_FRM ; Isolate the frame

	 popf			; Restore flags

	 clc			; Indicate we succeeded

	 jmp	 short VCPI_ALLOC_EXIT ; Join common exit code

VCPI_ALLOC_ERR:
	 popf			; Restore flags

	 stc			; Indicate we ran out of memory
VCPI_ALLOC_EXIT:
	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI_ALLOC endp 		; End VCPI_ALLOC procedure
	 NPPROC  VCPI_DEALLOC -- De-allocate a 4KB Page
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

De-allocate a 4KB page.

* Search through the VMS chain for this physical page
  If found, deallocate it.
  If not found, exit UGH.

On entry:

EDX	 =	 physical address of page to de-allocate

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,esi> ; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 and	 dx,(mask $PTE_FRM) ; Isolate the frame

; Search through the VMS chain for this physical page

	 mov	 ebx,PPHNDLVMS	; Get ptr to start of VMS chain
VCPI_DEALLOC_NEXT1:
	 mov	 ebx,PGROUP:[ebx].PL_NEXT ; Get pointer to next entry

	 cmp	 ebx,HP_LAST	; Check for end-of-the-chain
	 je	 near ptr VCPI_DEALLOC_ERR ; Jump if it is

; Check the four 4KB pages for EDX

	 mov	 eax,ebx	; Copy to index register
	 sub	 eax,PPAGELINK	; Convert to RPN
	 mov	 esi,eax	; Save for a moment
;;;;;;;; shl	 eax,2-2	; Convert from dword to dword index
	 add	 eax,PLINKBASE	; Plus base of PDT PTEs
	 shl	 esi,4-2	; Convert from dword to four-dword index
	 add	 esi,PGROUP:[eax] ; Plus the corresponding offset
	 add	 esi,PRGPDT	; Plus offset of PDT from PRGBASE

; PGROUP:SI = offset of PTEs in PDT for this 16KB page

	 mov	 cx,16/4	; # 4KB PTEs in a 16KB page
VCPI_DEALLOC_PTE_NEXT:
	 lods	 PGROUP:[esi].PDT_PTE ; Get the next PTE
	 and	 ax,(mask $PTE_FRM) ; Isolate the frame

	 cmp	 eax,edx	; Same PTE?
	 je	 short VCPI_DEALLOC_FND ; Jump if so

	 loop	 VCPI_DEALLOC_PTE_NEXT ; Jump if more PTEs to free

	 jmp	 short VCPI_DEALLOC_NEXT1 ; Go around again

VCPI_DEALLOC_FND:

; Calculate the corresponding linear address so we can append it
; to the XMS free chain

	 sub	 esi,type PDT_PTE ; Back off to matching PTE
	 sub	 esi,PRGPDT	; Less offset of PDT from PRGBASE

; Check for an address in the 1MB wrap region.

	 mov	 eax,PPDTCVD	; Get start of CVD region in PDT

	 cmp	 esi,eax	; Izit at or above start of CVD region?
	 jb	 short @F	; Jump if not

	 add	 eax,16*(type PDT_PTE) ; Skip to end of CVD region

	 cmp	 esi,eax	; Izit below end of CVD region?
	 jae	 short @F	; Jump if not

	 sub	 esi,PPDTCVD	; Convert to origin-1MB
	 add	 esi,PPDT1MB	; Plus start of 1MB wrap region in PDT
@@:
	 shl	 esi,(12-2)-0	; Convert from 4KB in dwords to bytes

	 push	 CON4KB 	; Pass byte length
	 push	 esi		; Pass starting linear address
	 call	 DEALLOCMEM	; Deallocate it
VCPI_DEALLOC_CLC:
	 popf			; Restore flags

	 clc			; Indicate success

	 jmp	 short VCPI_DEALLOC_EXIT ; Join common exit code

VCPI_DEALLOC_ERR:
	 popf			; Restore flags

	 stc			; Indicate we couldn't find the physical page
VCPI_DEALLOC_EXIT:
	 REGREST <esi,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI_DEALLOC endp		; End VCPI_DEALLOC procedure
	 NPPROC  VCPI_SET -- Set System Variables
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup system variables.

On entry:

DS:ESI	 ==>	 EPMTAB

On exit:

EAX	 =	 (clobbered)
DS:ESI	 ==>	 (updated)

|

; Setup CR3

	 lods	 ds:[esi].EDD	; Get CR3
	 mov	 cr3,eax	; Set new CR3 and flush TLB

; Setup GDTR

	 lods	 ds:[esi].EDD	; Get ptr to GDTR

	 push	 ebx		; Save for a moment
	 mov	 ebx,[eax].DTR_BASE ; Save base address of GDT for later use

	 LGDTD	 ds:[eax].EDF	; Set new GDTR

; Note from here on we're depending upon descriptor
; caching of CS, DS, and SS.

; Setup IDTR

	 lods	 ds:[esi].EDD	; Get ptr to IDTR

	 LIDTD	 ds:[eax].EDF	; Set new IDTR

; Setup LDTR

	 lods	 ds:[esi].ELO	; Get LDTR

	 lldt	 ax		; Set new LDTR

; Setup TR (and clear the busy bit)

	 lods	 ds:[esi].ELO	; Get TR

	 movzx	 eax,ax 	; Get new TR
	 and	 ds:[eax+ebx].DESC_ACCESS,not (mask $DS_BUSY) ; Mark as not busy
	 ltr	 ax		; Set new TR

	 pop	 ebx		; Restore

	 jmp	 ds:[esi].EDF	; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI_SET endp			; End VCPI_SET procedure
	 NPPROC  VCPI_SET1 -- Set System Variables
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup system variables.

Note the stack might have its B-bit set, so all
explicit stack references *MUST* be 32-bit.

On entry:

DS:ESI	 ==>	 EPMTAB

|

	 push	 esi		; Save for a moment

	 lea	 esi,EPMTAB	; Get local offset
	 add	 esi,VCPIBASE	; Plus our base
				; DS:ESI ==> EPMTAB

	 jmp	 VCPI_SET	; Set new values in system variables

	 public  PMVCPI0C_NEXT
PMVCPI0C_NEXT:
	 pop	 esi		; Restore

;....... push	 DTE_VDAT	; Get our data selector 	;.......
;....... pop	 ds		; Address it			;.......
;....... assume  ds:PGROUP	; Tell the assembler about it	;.......

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 VCPI
IDT	 =	 VCPI
SS	 =	 VCPI, QMAX's GDT
CS	 =	 VCPI, QMAX's GDT

|

;....... mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
;....... mov	 PGROUP:[eax].TSS_SS0,DTE_VDAT ; Save in TSS	;.......
;....... mov	 ss,PGROUP:[eax].TSS_SS0 ; Address it		;.......
;....... assume  ss:nothing	; Tell the assembler about it	;.......
;....... nop			; Just for something to do	;.......

COMMENT|

System status:

CR3	 =	 QMAX
CR3[0]	 =	 VCPI
GDT	 =	 VCPI
IDT	 =	 VCPI
SS	 =	 VCPI, QMAX's GDT
CS	 =	 VCPI, QMAX's GDT

|

; Clear out segment registers

;....... xor	 ax,ax		; A convenient zero		;.......
;....... mov	 ds,ax		; Zero it			;.......
;....... assume  ds:nothing	; Tell the assembler about it	;.......
;....... mov	 es,ax		; ...				;.......
;....... assume  es:nothing	; Tell the assembler about it	;.......
;....... mov	 fs,ax		; ...				;.......
;....... assume  fs:nothing	; Tell the assembler about it	;.......
;....... mov	 gs,ax		; ...				;.......
;....... assume  gs:nothing	; Tell the assembler about it	;.......

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VCPI_SET1 endp			; End VCPI_SET1 procedure
	 NPPROC  COPY_PTE -- Copy and Clear PTEs
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy PTes from our table into caller's
removing the $PTE_AVx bits in the process.

On entry:

CS:ESI	 ==>	 our PTEs to copy
ES:EDI	 ==>	 caller's table
ECX	 =	 # PTEs to move

|

	 REGSAVE <eax,ecx,esi,edi> ; Save registers

	 add	 esi,PRGPDT	; Plus offset in PGROUP of PDT
	 cld			; Ensure string ops forwards
@@:
	 lods	 PGROUP:[esi].PDT_PTE ; Get the PTE

; Clear available bits because Phar Lap uses them without clearing

	 and	 ax,not ((mask $PTE_AV2) or (mask $PTE_AV1) or (mask $PTE_AV0))

S32	 stos	 es:[edi].EDD	; Save into caller's table

	 loopd	 @B		; Jump if more PTEs to copy

	 REGREST <edi,esi,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_PTE endp			; End COPY_PTE procedure
	 NPPROC  GDTSET -- Set GDT Entry
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set GDT entry.

On entry:

EAX	 =	 DTE base address
ECX	 =	 DTE limit
EBX	 =	 selector
DL	 =	 DTE flags
DH	 =	 access rights byte
ES:EDI	 ==>	 GDT base address

|

	 push	 ecx		; Save for a moment

	 cmp	 ecx,CON1MB	; Check against limit limit
	 jb	 short @F	; Jump if within range

	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 or	 ecx,(mask $DTE_G) shl 16 ; Set G-bit
@@:
	 mov	 es:[edi+ebx].DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 es:[edi+ebx].DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 es:[edi+ebx].DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 or	 cl,dl		; Include any flags
	 mov	 es:[edi+ebx].DESC_SEGLM1,cl ; Save as data limit and flags
;;;;;;;; ror	 ecx,16 	; Swap back
	 mov	 es:[edi+ebx].DESC_ACCESS,dh ; Save AR byte

	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GDTSET	 endp			; End GDTSET procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment
endif				; IF @OEM_VCPI

	 MEND			; End QMAX_VCP module

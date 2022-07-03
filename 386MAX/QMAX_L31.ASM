;' $Header:   P:/PVCS/MAX/386MAX/QMAX_L31.ASV   1.2   30 May 1997 10:45:26   BOB  $
	 title	 QMAX_L31 -- 386MAX INT 31h Additional Routines
	 page	 58,122
	 name	 QMAX_L31

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-8 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'

Program derived from:  None.

Original code by:  Bob Smith, June 1991.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include ALLMEM.INC
	 include DPMI.INC
	 include MASM5.MAC
	 include DOSCALL.INC
NOVER_HTU = 1
	 include VERSION.INC

	 include QMAX_OEM.INC
	 include QMAXDPMI.INC
	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAX_I31.INC
	 include QMAX_TSS.INC
	 include QMAX_VMM.INC
.list

if @OEM_DPMI

PGROUP	 group	 CODE,ECODE,EDATA
IGROUP	 group	 LDATA,ICODE,IDATA
JGROUP	 group	 JCODE


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

if @OEM_VIRTUALMEM
	 extrn	 VMM_FLAG:word
	 extrn	 I31_FLAG:word
	 extrn	 SEL_DSIG3:word
endif				; IF @OEM_VIRTUALMEM
	 extrn	 XMSBMAP_LEN:dword
	 extrn	 SEL_4GB3:word

	 extrn	 CON1MB:dword
	 extrn	 CON1P1MB:dword

	 extrn	 CPUTYPE:byte
	 extrn	 DPMITYPE:byte

	 extrn	 NEWIMR1:word
	 extrn	 NEWIMR2:word

	 extrn	 PVMTSS:dword
	 extrn	 PCURTSS:dword
	 extrn	 VM2PM_TSS:word

	 extrn	 DPMI_IDEF:word

	 extrn	 INT07DP:qword
	 extrn	 MSW_PM:word

	 public  HostIDString
HostIDString db  '386MAX',0     ;
@HostIDLength equ $-HostIDString ; Length of ...

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_L31_ECODE
@QMAX_L31_ECODE:		; Mark module start in .MAP file

	 extrn	 QRY_PGCNT:near
	 extrn	 ALLOCMEM_SUB:near
	 extrn	 FALLOCMEM:far
	 extrn	 FDEALLOCMEM:far
	 extrn	 FXMS_MEMSPAN:far

	 FPPROC  FQRY_PGCNT -- Query Available Pages
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to QRY_PGCNT

On entry:

Same as for QRY_PGCNT

On exit:

Same as for QRY_PGCNT

|

FQRY_PGCNT_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   CS:IP
FQRY_PGCNT_TYP dw ?		; Allocation type

FQRY_PGCNT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 push	 [ebp].FQRY_PGCNT_TYP ; Pass allocation type
	 call	 QRY_PGCNT	; Return with EAX = # available 1KB
				; ...	      EDX = size of largest
	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FQRY_PGCNT endp 		; End FQRY_PGCNT procedure
	 FPPROC  FALLOCMEM_SUB -- Allocate Memory Subroutine
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to ALLOCMEM_SUB
Allocate memory at a specific address and length.

On entry:

IF	 =	 0 (interrupts disabled)

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

FALLOCMEM_SUB_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   CS:IP
FALLOCMEM_SUB_LA  dd  ? 	; Linear address to allocate
FALLOCMEM_SUB_LEN dd  ? 	; Byte length of allocate

FALLOCMEM_SUB_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 push	 [ebp].FALLOCMEM_SUB_LEN ; Pass # bytes to set
	 push	 [ebp].FALLOCMEM_SUB_LA  ; Pass starting linear address
	 call	 ALLOCMEM_SUB	; Allocate 'em
				; Return with CF significant

	 pop	 ebp		; Restore

	 ret	 4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FALLOCMEM_SUB endp		; End FALLOCMEM_SUB procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DSIG3:word
	 extrn	 ISEL_DS3:word

LDATA	 ends			; End LDATA segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

	 extrn	 DPMITYPEIG:byte

if @OEM_VIRTUALMEM
	 extrn	 PhysicalManaged:dword
	 extrn	 BSTotal:dword
	 extrn	 PhysicalInUse:dword
	 extrn	 BSInUse:dword
	 extrn	 PhysicalLocked:dword
	 extrn	 PhysicalMinUnlocked:dword
	 extrn	 PhysicalSwappable:dword
	 extrn	 LinearClientTop:dword
	 extrn	 LinearBottom:dword
	 extrn	 VirtualReserved:dword

endif				; IF @OEM_VIRTUALMEM

	 public  DBGREGS,DBGDR7
DBGREGS  dd	 4 dup (?)	; Linear addresses for DR0-3
DBGDR7	 dd	 ?		; Debug control register

	 public  DBGREGS_ACT
DBGREGS_ACT dw	 IGROUP:DPMI_DBGSET_DR0 ; Action to take to set DR0
	 dw	 IGROUP:DPMI_DBGSET_DR1 ; ...			DR1
	 dw	 IGROUP:DPMI_DBGSET_DR2 ; ...			DR2
	 dw	 IGROUP:DPMI_DBGSET_DR3 ; ...			DR3

	 public  VSAPI_MSDOS,VSAPI_386MAX
VSAPI_MSDOS dw	 PMVSAPI16_MSDOS  ; Entry points for MS-DOS VSAPI routines
	 dw	 PMVSAPI32_MSDOS
VSAPI_386MAX dw  PMVSAPI16_386MAX ; Entry points for 386MAX VSAPI routines
	 dw	 PMVSAPI32_386MAX

	 public  DBGCTL,DBGSTA
DBGCTL	 db	 0		; Debug watchpoint control bits
				; Bit n:  1 means DRn active
				;	  0 not
				; Bits 0-3 only are defined

DBGSTA	 db	 0		; Debug watchpoint status bits
				; Bit n:  1 means DRn encountered
				;	  0 not
				; Bits 0-3 only are defined

	 public  INTELCB
INTELCB  db	  87h, 04h, 24h 	; xchg	  eax,[esp]
	 db	  57h			; push	  edi
	 db	  56h			; push	  esi
	 db	  8Bh,0B5h		; mov	  esi,[ebp+xxxxxxxx]
INTELCB_F1 dd	  ?			; Four-byte fixup
	 db	  8Dh,0B6h		; lea	  esi,[esi+xxxxxxxx]
INTELCB_F2 dd	  ?			; Four-byte fixup
	 db	  66h,0B8h, 05h, 00h	; mov	  ax,0005
	 db	 0F6h,0E3h		; mul	  bl
	 db	  03h,0F0h		; add	  esi,eax
INTELCB_LEN equ  $-INTELCB	; Length of ...

IDATA	 ends			; End IDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 public  @QMAX_L31_ICODE
@QMAX_L31_ICODE:		; Mark module start in .MAP file

	 extrn	 VALID_LSEL:near
	 extrn	 GETLBASE:near
	 extrn	 SETLBASE:near
	 extrn	 CLR_LDTZERO:near
	 extrn	 INT31_ERR:near
	 extrn	 INT31_ERR_NOMEM:near
	 extrn	 INT31_ERR_NOPHYSMEM:near
	 extrn	 INT31_ERR_INVADDR:near
	 extrn	 INT31_ERR_INVHNDL:near
	 extrn	 INT31_ERR_INVVAL:near
	 extrn	 INT31_ERR_NOFNS:near
	 extrn	 INT31_ERR_NOHNDL:near
	 extrn	 INT31_CLC:near
	 extrn	 PMVSAPI16_MSDOS:abs
	 extrn	 PMVSAPI16_386MAX:abs
	 extrn	 PMVSAPI32_MSDOS:abs
	 extrn	 PMVSAPI32_386MAX:abs
	 extrn	 DPMIFN_LMSW:near
if @OEM_VIRTUALMEM
	 extrn	 VMM_MARK_CANDIDATES:near
	 extrn	 VMM_MAP_PHYSICAL:near
	 extrn	 VMM_DISCARD_PAGES:near
	 extrn	 VMM_LOCK:near
	 extrn	 VMM_UNLOCK:near
	 extrn	 VMM_ALLOC:near
	 extrn	 VMM_REALLOC:near
	 extrn	 VMM_QUERY:far
	 extrn	 VMM_SET_ATTRIBUTES:near
	 extrn	 VMM_GET_ATTRIBUTES:near
	 extrn	 VMM_MAPP2L:near
	 extrn	 VMM_UNMAPP2L:near
	 extrn	 LSM_GET_CLIENT_LIST:near
	 extrn	 LSM_QUERY:near
	 extrn	 INT31_ERR_INVSEL:near
endif				; IF @OEM_VIRTUALMEM

	 NPPROC  DPMI_GETVER -- DPMI 0.9 Function to Get Version Information
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get version information

On entry (in INTXX_STR):

AX	 =	 0400h
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
AH	 =	 major version # in binary
AL	 =	 minor ...
BX	 =	 flags:
		 Bit 0:  0 = 16-bit host
			 1 = 32-bit host
		 Bit 1:  0 = CPU returned to VM for reflected interrupts
			 1 = ...	     RM ...
		 Bit 2:  0 = virtual memory not supported
			 1 = ...	    is ...
		 Bit 3:  (reserved for historical reasons)
		 Bit 4-15:  (reserved)
CL	 =	 CPU type (02=286, 03=386, 04=486)
DH	 =	 current value of master PIC
DL	 =	 ...		  slave ...

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 [ebp].INTXX_EAX.ELO.HI,1 ; Major version # in AH
	 mov	 [ebp].INTXX_EAX.ELO.LO,0 ; Minor ...	       AL

	 mov	 [ebp].INTXX_EBX.ELO,@BIT0 ; Only bit is as 32-bit host in BX

if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_SYSINIT ; Is the VM system initialized?
	 jz	 short @F	; Jump if not

	 or	 [ebp].INTXX_EBX.ELO,@BIT2 ; Set VM capability bit
@@:
endif				; IF @OEM_VIRTUALMEM

	 mov	 al,CPUTYPE	; Get CPU type
	 mov	 [ebp].INTXX_ECX.ELO.LO,al ; Return it in CL

	 mov	 al,NEWIMR1.LO	; Get master PIC base
	 mov	 [ebp].INTXX_EDX.ELO.HI,al ; Return it in DH

	 mov	 al,NEWIMR2.LO	; Get slave  PIC base
	 mov	 [ebp].INTXX_EDX.ELO.LO,al ; Return it in DL

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETVER endp		; End DPMI_GETVER procedure
	 NPPROC  DPMI_GETCAP -- DPMI 1.0 Function to Get Host Capabilities
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to get host capabilities

On entry (in INTXX_STR):

AX	 =	 0401h
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
AX	 =	 flags:
		 Bit 0:  0 = page Access/Dirty not supported
			 1 = page Access/Dirty supported
		 Bit 1:  0 = exceptions restartability not supported
			 1 = exceptions restartability supported
		 Bit 2:  0 = device mapping not supported
			 1 = device mapping supported
		 Bit 3:  0 = conventional memory mapping not supported
			 1 = conventional memory mapping supported
		 Bit 4:  0 = demand zero fill not supported
			 1 = demand zero fill supported
		 Bit 5:  0 = write protect client not supported
			 1 = write protect client supported
		 Bit 6:  0 = write protect host not supported
			 1 = write protect host supported

CX	 =	 0
DX	 =	 0

ES:eDI	 =	 info buffer (provided by client, filled by host as follows:)

		 offset 0	host major version number
			1	host minor version number
			2	asciiz host ID string (up to 126 bytes)

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; We support:
;	page access/dirty
;	exceptions restarting (we don't support NOT restarting!)
;	device mapping
;	demand zero fill (if set in I31_FLAG)
;	conventional memory mapping
;	write protect client
;
; We do not support
;	write protect host

;		bit 76543210
	 mov	 ax,00101111b	; Basic supported items

	 test	 I31_FLAG,mask $I31_ZPD ; Are we zeroing demand pages?
	 jz	 short @F	; Jump if not

	 or	 ax,@BIT4	; Set bit if we are
@@:
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Set reg in client structure
	 xor	 ax,ax		; Make a zero
	 mov	 [ebp].INTXX_EBX.ELO,ax ; Zero client BX
	 mov	 [ebp].INTXX_ECX.ELO,ax ; Zero client CX

	 mov	 es,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 edi,[ebp].INTXX_EDI ; Get user EDI
	 IF16ZX  di		; Zero high half if 16-bit client

	 mov	 al,VERS_H-'0'  ; Get hundreds digit
S32	 stos	 es:[edi].LO	; Store in client buffer

	 mov	 ah,VERS_T-'0'  ; Get tens digit
	 mov	 al,VERS_U-'0'  ; Get units digit
	 aad			; ... (AL <- AH*10 + AL)
S32	 stos	 es:[edi].LO	; Store in client buffer

	 lea	 esi,HostIDString ; DS:ESI == host id string
	 mov	 ecx,@HostIDLength ; Get byte count
S32  rep movs	 <es:[edi].LO,HostIDString[esi]> ; Copy to client buffer

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETCAP endp		; End DPMI_GETCAP procedure
	 NPPROC  DPMI_GETFMI -- DPMI 0.9 Function to Get Free Memory Information
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get free memory information

On entry (in INTXX_STR):

AX	 =	 0500h
ES:eDI	 ==>	 caller's 48-byte buffer (mapped by DPMIFMI_STR)
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 edi,[ebp].INTXX_EDI ; Get caller's eDI
	 IF16ZX  di		; Zero to use as dword if 16-bit client

	 mov	 es,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  es:nothing	; Tell the assembler about it

	 FIXICALL IGROUP:VMM_QUERY,DTE_CSIG ; edx <- largest block in KB

	 shl	 edx,10 				; convert to bytes
	 mov	 es:[edi].DPMIFMI_LBFREE,edx		; set client struc

	 shr	 edx,@BytePage				; convert to pages
	 mov	 es:[edi].DPMIFMI_LPUNLK,edx		; store max unlock

	 mov	 eax,PhysicalManaged			; total phys pages
	 mov	 es:[edi].DPMIFMI_TPMEM2,eax		; set client struc

	 sub	 eax,PhysicalInUse			; minus in use
	 mov	 es:[edi].DPMIFMI_TPFREE,eax		; yields physical free
	 mov	 ebx,eax				; copy for calc
	 shr	 ebx,22 				; divide by 4M
	 sub	 eax,ebx				; sub for PT overhead

	 test	 VMM_FLAG,@VMM_BSPRES			; swapping?
	 jz	 short DPMI_GETFMI_SETLOCK		; jump if not

	 sub	 eax,PhysicalMinUnlocked		; excl min working set
	 ja	 short DPMI_GETFMI_SETLOCK		; jump if > 0

	 xor	 eax,eax				; nothing lockable
DPMI_GETFMI_SETLOCK:
	 mov	 ebx,es:[edi].DPMIFMI_LBFREE		; get max unlock alloc
	 shr	 ebx,@BytePage				; convert to pages

	 cmp	 eax,ebx				; can't be more than
	 jb	 short @F				;   unlocked alloc

	 mov	 eax,ebx				; set to min of two
@@:
	 push	 eax		; Save for a moment

@15MB	 equ	 (15*1024*1024)/(4*1024) ; 15MB in pages

	 test	 I31_FLAG,mask $I31_L15 ; Limit lockable page count to 15MB?
	 jz	 short @F	; Jump if not

	 cmp	 eax,@15MB	; Izit bigger?
	 jb	 short @F	; Jump if not

	 mov	 eax,@15MB	; Use maximum
@@:
	 mov	 es:[edi].DPMIFMI_LPLOCK,eax		; lockable alloc

	 pop	 eax		; Restore

	 add	 eax,PhysicalSwappable			; # swappable pages
	 mov	 es:[edi].DPMIFMI_TPUNLK,eax		; unlocked pages

	 mov	 eax,LinearClientTop			; top of LA space
	 sub	 eax,LinearBottom			; sub bottom of space
	 shr	 eax,@BytePage				; convert to pages
	 mov	 es:[edi].DPMIFMI_TPMEM1,eax		; store total LA size

	 mov	 ds,ISEL_DSIG3				; ds <- IGROUP
	 assume  ds:IGROUP				; tell asm

	 REGSAVE <edi,fs>	; Save for a moment

	 call	 LSM_GET_CLIENT_LIST			; FS:EDI <- list ptr
	 assume  fs:nothing	; Tell the assembler about it

	 call	 LSM_QUERY				; ecx <- largest

	 REGREST <fs,edi>
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 es:[edi].DPMIFMI_APFREE,ecx		; set client struc

	 mov	 eax,BSTotal				; size of swapfile
	 mov	 es:[edi].DPMIFMI_PFILE,eax		; set client struc

	 mov	 cx,length DPMIFMI_RSV ; CX = # entries
	 xor	 eax,eax	; Initialize index register
@@:
	 mov	 es:[edi+eax].DPMIFMI_RSV,-1 ; Set reserved bytes to -1

	 add	 eax,type DPMIFMI_RSV ; Skip to next entry

	 loop	 @B		; Jump if more entries to initialize

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETFMI endp		; End DPMI_GETFMI procedure
	 NPPROC  DPMIFN_GROWMEMHNDL -- Attempt To Grow The DPMI Memory Handle Table
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Attempt to grow the DPMI memory handle table.

On entry:

IF	 =	 0 (interrupts disabled)

On exit:

CF	 =	 0 if we succeeded
	 =	 1 if we didn't

|

	 push	 es		; Save selector

	 pushad 		; Save all EGP registers

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 imul	 eax,type DPMIHNDL_STR ; Convert from struc to bytes

; Round up the byte size to the next multiple of @DPMI_BOUND

	 add	 eax,@DPMI_BOUND-1 ; Round up to next
	 and	 eax,not (@DPMI_BOUND-1) ; ... boundary for ALLOCMEM
	 mov	 ecx,eax	; Copy byte size of old table (/@DPMI_BOUND)
				; Note that this value may be larger than
				; we need because it has been rounded up to
				; be a multiple of @DPMI_BOUND.

; Convert back to # handles and compare with the original value

	 push	 edx		; Save for a moment

	 xor	 edx,edx	; Zero to use EDX:EAX as a qword
	 mov	 ebx,type DPMIHNDL_STR ; Get divisor
	 div	 ebx		; Return with quotient in EAX

	 pop	 edx		; Restore

; If the new value is larger, there's room in the same memory region

	 cmp	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Izit the same?
	 ja	 short DPMIFN_GROWMEMHNDL1 ; Jump if not

; No room in the same memory handle table:  look for more memory elsewhere

	 add	 eax,@DPMI_BOUND/(type DPMIHNDL_STR) ; Add in another page's
				; worth of handles
	 imul	 eax,type DPMIHNDL_STR ; Convert from struc to bytes
	 add	 eax,@DPMI_BOUND-1 ; Round up to next
	 and	 eax,not (@DPMI_BOUND-1) ; ... boundary for ALLOCMEM
	 push	 ecx				; save for a moment
	 push	 eax				; save for a moment

	 push	 dword ptr mask $commit 	; allocation flags
	 add	 eax, @PageSize-1		; convert to pages
	 shr	 eax, @BytePage 		; complete conversion
	 push	 eax				; new size
	 add	 ecx, @PageSize-1		; convert to pages
	 shr	 ecx, @BytePage 		; complete conversion
	 push	 ecx				; old size
	 push	 PGROUP:[edx].DPTSS_LaDPMIHNDL	; starting linear address
	 call	 VMM_REALLOC			; resize the block
	 mov	 ebx, eax			; ebx <-newl linear addr

	 pop	 eax				; recall previous value
	 pop	 ecx				; recall previous value
	 or	 ebx, ebx			; ebx zero if realloc failed
	 jnz	 short @F			; jump if ok
	 stc					; signal error
	 jmp	 short DPMIFN_GROWMEMHNDL_EXIT	; Jump if no memory found
@@:

	 mov	 PGROUP:[edx].DPTSS_LaDPMIHNDL, ebx ; Set new linear address

; Convert back to total # handles

	 push	 edx		; Save for a moment

	 xor	 edx,edx	; Zero to use EDX:EAX as a qword
	 mov	 ebx,type DPMIHNDL_STR ; Get divisor
	 div	 ebx		; Return with quotient in EAX

	 pop	 edx		; Restore
DPMIFN_GROWMEMHNDL1:

COMMENT|

At this point:

DPTSS_LaDPMIHNDL    linear address of new DPMI memory handle table
DPTSS_DPMIHNDL_CNT  old DPMIHNDL_CNT
EAX	 =	    new DPMIHNDL_CNT
EDX	 =	    PCURTSS

|

; Zero the new DPMI memory handles

	 mov	 ecx,eax	; Copy new # handles
	 xchg	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Swap old and new
	 sub	 ecx,eax	; Subtract to get # extra handles
	 imul	 ecx,type DPMIHNDL_STR ; Convert from struc to bytes

	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; Get linear address of DPMI
				; memory handle table
	 imul	 eax,type DPMIHNDL_STR ; Convert from struc to bytes
	 add	 edi,eax	; Skip to start of new section

	 mov	 al,0		; Fill with this value
     rep stos	 AGROUP:[edi].LO ; Zero 'em

	 clc			; Indicate we succeeded
DPMIFN_GROWMEMHNDL_EXIT:
	 popad			; Restore all EGP registers

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_GROWMEMHNDL endp 	; End DPMIFN_GROWMEMHNDL procedure
	 NPPROC  DPMI_GETMEM -- DPMI 0.9 Function to Allocate Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to allocate memory

On entry (in INTXX_STR):

AX	 =	 0501h
BX:CX	 =	 block size in bytes
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
BX:CX	 =	 linear address of allocated block
SI:DI	 =	 memory block handle

CF	 =	 1 if not successful
AX	 =	 8012 if linear memory unavailable
	 =	 8013 if physical ...
	 =	 8014 if backing store ...
	 =	 8016 if handle unavailable
	 =	 8021 if invalid value (BX:CX = 0)

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Get and validate the block size

	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get the high-order word
	 shl	 ebx,16 	; Shift to high-order word
	 mov	 bx,[ebp].INTXX_ECX.ELO ; Get the low-order word

	 and	 ebx,ebx	; Izit zero?
	 jz	 near ptr INT31_ERR_INVVAL ; Jump if so

	 add	 ebx,@DPMI_BOUND-1 ; Round up to next
	 and	 ebx,not (@DPMI_BOUND-1) ; ...@DPMI_BOUND boundary

; Find an available memory handle

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS
DPMI_GETMEM_GROWUP:
	 mov	 ecx,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EDI ==> DPMI memory
				; handle table
	 xor	 eax,eax	; A convenient zero
@@:
	 cmp	 eax,AGROUP:[edi].DPMIHNDL_LEN ; Izit available?
	 je	 short DPMI_GETMEM1 ; Jump if so

	 add	 edi,type DPMIHNDL_STR ; Skip to next entry

	 loopd	 @B		; Jump if more handles to check

	 call	 DPMIFN_GROWMEMHNDL ; Attempt to grow DPMI memory handle struc
	 jnc	 short DPMI_GETMEM_GROWUP ; Jump if we succeeded

	 popf			; Restore flags
				; (note interrupts might become enabled)
; No handles available

	 jmp	 INT31_ERR_NOHNDL ; Join common error code

DPMI_GETMEM1:
	 mov	 AGROUP:[edi].DPMIHNDL_LEN,ebx ; Mark as in use

; See if there's enough memory

	 push	 @ALLOC_DPMI	; Tell 'em what kind of memory we're allocating
	 push	 ebx		; Pass # bytes to allocate
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
				; Return with EBX = linear address of memory
	 jc	 short DPMI_GETMEM_ERR ; Jump if no memory found

	 mov	 AGROUP:[edi].DPMIHNDL_LA,ebx ; Save for later use
	 mov	 AGROUP:[edi].DPMIHNDL_SEL,0  ; Mark as no memory selector

	 mov	 ax,VM2PM_TSS	; Get current TSS selector
	 mov	 AGROUP:[edi].DPMIHNDL_TSS,ax ; Save for later use

	 popf			; Restore flags
				; (note interrupts might become enabled)
; Return the linear address of the allocated block in BX:CX

	 mov	 [ebp].INTXX_ECX.ELO,bx ; Save the low-order word
	 shr	 ebx,16 	; Shift down to low-order word
	 mov	 [ebp].INTXX_EBX.ELO,bx ; Save the high-order word

; Return the memory block handle in SI:DI

	 mov	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 sub	 eax,ecx	; Less countdown value to get handle #
				; in origin-0, unit increments
	 mov	 [ebp].INTXX_EDI.ELO,ax ; Save the low-order word
	 shr	 eax,16 	; Shift down to low-order word
	 mov	 [ebp].INTXX_ESI.ELO,ax ; Save the high-order word

	 jmp	 INT31_CLC	; Join common exit code

DPMI_GETMEM_ERR:
	 mov	 AGROUP:[edi].DPMIHNDL_LEN,0 ; Free the handle

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 jmp	 INT31_ERR_NOMEM ; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETMEM endp		; End DPMI_GETMEM procedure
	 NPPROC  DPMI_RELMEM -- DPMI 0.9 Function to Free Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to free memory

On entry (in INTXX_STR):

AX	 =	 0502h
SI:DI	 =	 memory block handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8023 if invalid handle

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Get and validate the memory block handle

	 mov	 ax,[ebp].INTXX_ESI.ELO ; Get the high-order word
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_EDI.ELO ; Get the low-order word

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Check against total # handles
	 jae	 near ptr INT31_ERR_INVHNDL ; Jump if it's out of range

	 imul	 eax,type DPMIHNDL_STR ; Times # bytes per handle
	 add	 eax,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EAX ==> DPMI memory
				; handle table
	 mov	 edi,AGROUP:[eax].DPMIHNDL_LA ; Get the linear address
	 xor	 ecx,ecx	; Free memory value
	 xchg	 ecx,AGROUP:[eax].DPMIHNDL_LEN ; Free the handle

	 jecxz	 DPMI_RELMEM_ERR ; Jump if it's already free

; Deallocate ECX bytes at EDI

	 push	 ecx		; Pass byte length
	 push	 edi		; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
;;;;;;;; jc	 short ???	; Ignore error return

; Free the corresponding selector (if any)

	 cmp	 AGROUP:[eax].DPMIHNDL_SEL,0 ; Izit valid?
	 je	 short @F	; Jump if not

	 push	 AGROUP:[eax].DPMIHNDL_SEL ; Get the selector
	 call	 CLR_LDTZERO	; Free this LDT selector & zero selectors
;;;;;;;; jc	 short ???	; Ignore error return (error, what error?)
@@:
	 jmp	 INT31_CLC	; Join common exit code

DPMI_RELMEM_ERR:
	 jmp	 INT31_ERR_INVHNDL ; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_RELMEM endp		; End DPMI_RELMEM procedure
	 NPPROC  DPMI_MODMEM -- DPMI 0.9 Function to Resize Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to resize memory

On entry (in INTXX_STR):

AX	 =	 0503h
BX:CX	 =	 new size of block
SI:DI	 =	 memory block handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
BX:CX	 =	 new linear address of memory block
SI:DI	 =	 new handle for memory block

CF	 =	 1 if not successful
AX	 =	 8012 if linear memory unavailable
	 =	 8013 if physical ...
	 =	 8014 if backing store ...
	 =	 8016 if handle unavailable
	 =	 8021 if invalid value (BX:CX = 0)
	 =	 8023 if invalid handle (in SI:DI)

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Get and validate the memory block handle

	 mov	 ax,[ebp].INTXX_ESI.ELO ; Get the high-order word
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_EDI.ELO ; Get the low-order word

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Check against total # handles
	 jae	 near ptr INT31_ERR_INVHNDL ; Jump if it's out of range

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EDI ==> DPMI memory
				; handle table
	 imul	 eax,type DPMIHNDL_STR ; Convert to appropriate units
	 add	 edi,eax	; AGROUP:EDI ==> this handle's entry

	 mov	 esi,AGROUP:[edi].DPMIHNDL_LA ; Get linear address
	 mov	 eax,AGROUP:[edi].DPMIHNDL_LEN ; Get current length in bytes

	 mov	 dx,[ebp].INTXX_EBX.ELO ; Get high-order word of new size
	 shl	 edx,16 	; Shift to high-order word
	 mov	 dx,[ebp].INTXX_ECX.ELO ; Get low-order word of new size

	 add	 edx,@DPMI_BOUND-1 ; Round up to @DPMI_BOUND boundary
	 and	 edx,not (@DPMI_BOUND-1) ; ... (which could become 1MB)
	 jz	 near ptr INT31_ERR_INVVAL ; Jump if BX:CX == 0

COMMENT|

Register usage:

EAX	 =	 current size of this block in bytes (/@DPMI_BOUND)
EDX	 =	 new size of this block in bytes (/@DPMI_BOUND)
ESI	 ==>	 starting linear address of block
EDI	 ==>	 DPMI handle entry

|

	 call	 DPMIFN_MODMEM	; Grow or srhink the memory
	 jc	 near ptr INT31_ERR_NOMEM ; Jump if something went wrong

; Return to caller the new linear address in BX:CX
; Note that the handle # doesn't change

	 mov	 eax,AGROUP:[edi].DPMIHNDL_LA ; Get linear address
	 mov	 [ebp].INTXX_ECX.ELO,ax ; Save low-order word
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_EBX.ELO,ax ; Save high-order word

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_MODMEM endp		; End DPMI_MODMEM procedure
	 NPPROC  DPMIFN_MODMEM -- Subroutine to Modify Memory
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

EAX	 =	 current size of this block in bytes (/@DPMI_BOUND)
EDX	 =	 new size of this block in bytes (/@DPMI_BOUND)
ESI	 ==>	 starting linear address of block
EDI	 ==>	 DPMI handle entry

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

	 cmp	 eax,edx	; Compare actual vs. requested
	 jb	 short DPMIFN_MODMEM_GROW ; Jump if the block is to grow
	 je	 near ptr DPMIFN_MODMEM_CLC ; Jump if same size with EDX=new size
				; Fall through to shrink the block
; The block is to shrink in size
; Register usage:

; EAX	 =	 current size of this block in bytes (/@DPMI_BOUND)
; EDX	 =	 new size of this block ( < EAX) in bytes (/@DPMI_BOUND)
; ESI	 ==>	 starting linear address of block
; EDI	 ==>	 DPMI handle entry

	 add	 esi,edx	; Add to get base of new free entry
	 sub	 eax,edx	; Subtract to get size of free above

; Deallocate EAX bytes at ESI

	 push	 eax		; Pass byte length
	 push	 esi		; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
;;;;;;;; jc	 short ???	; Ignore error return

	 jmp	 near ptr DPMIFN_MODMEM_CLC ; Join common ending code with EDX=new size


; The block is to increase in size
; Ensure there is sufficient room above the block
; Register usage:

; EAX	 =	 current size of this block in bytes (/@DPMI_BOUND)
; EDX	 =	 new size of this block ( > EAX) in bytes (/@DPMI_BOUND)
; ESI	 ==>	 starting linear address of block
; EDI	 ==>	 DPMI handle entry

DPMIFN_MODMEM_GROW:
if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_SYSINIT ; Is the VM system initialized?
	 jz	 short @F	; Jump if not

	 shr	 eax,12-0	; Convert from bytes to 4KB
	 shr	 edx,12-0	; Convert from bytes to 4KB

	 push	 ds

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 push	 dword ptr (mask $COMMIT) ; Pass flags
	 push	 edx		; Pass new size in 4KB
	 push	 eax		; Pass current size in 4KB
	 push	 esi		; Pass starting linear address
	 call	 VMM_REALLOC	; Reallocate it - returns base in EAX

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 and	 eax,eax	; Did it fail?
	 stc			; Assume it did
	 jz	 near ptr DPMIFN_MODMEM_EXIT ; Jump if so

	 mov	 AGROUP:[edi].DPMIHNDL_LA,eax ; Save new linear address
	 shl	 edx,12-0	; Convert from 4KB to bytes

	 jmp	 short DPMIFN_MODMEM_CLC ; Join common ending code with EDX=new size

@@:
endif				; IF @OEM_VIRTUALMEM

	 add	 esi,eax	; Skip to the end of this block
	 mov	 ecx,edx	; Copy new size
	 sub	 ecx,eax	; Get increase in bytes

	 shr	 ecx,10-0	; Convert from bytes to 1KB
	 shr	 esi,10-0	; Convert from bytes to 1KB

; Check XMSBMAP for ECX adjacent free entries at ESI

	 lea	 eax,[ecx+esi]	; Skip to ending entry

	 cmp	 eax,XMSBMAP_LEN ; Ensure it's within bounds
	 ja	 short DPMIFN_MODMEM_MOVE ; Jump if too high

; Determine the span of available entries starting
; at EDI for no more than ECX entries

; Note that we use XMS2 as the allocation type to get 1KB granularity
; without physical boundary concerns.

	 push	 @ALLOC_XMS2	; Pass the allocation type
	 push	 ecx		; Pass # entries we need
	 push	 edi		; Pass starting offset into XMSBMAP
	 FIXICALL PGROUP:FXMS_MEMSPAN,DTE_CS2 ; Determine the span of available entries
				; returning EDI = # consecutive available entries

	 cmp	 edi,ecx	; Izit all available?
	 jb	 short DPMIFN_MODMEM_MOVE ; Jump if not, try moving it

	 mov	 esi,AGROUP:[edi].DPMIHNDL_LA ; Get linear address
	 mov	 eax,AGROUP:[edi].DPMIHNDL_LEN ; Get current length in bytes

	 mov	 ecx,edx	; Copy new size in bytes (/@DPMI_BOUND)
	 sub	 ecx,eax	; Get increase in bytes
	 add	 esi,eax	; Skip to the end of this block

; Allocate ECX bytes at ESI

	 push	 ecx		; Pass # bytes to set
	 push	 esi		; Pass starting linear address
	 FIXICALL PGROUP:FALLOCMEM_SUB,DTE_CS2 ; Allocate 'em
	 jnc	 short DPMIFN_MODMEM_CLC ; Jump if all went OK with EDX=new size

	 int	 03h		; Call our debugger
DPMIFN_MODMEM_CLC:
	 mov	 AGROUP:[edi].DPMIHNDL_LEN,edx ; Save as current length in bytes

	 clc			; Mark as successful

	 jmp	 DPMIFN_MODMEM_EXIT ; Join common exit code


; The block is to increase in size,
; but there's no room immediately above it
; Try to move it to another location

; EDX	 =	 new size of this block in bytes (/@DPMI_BOUND)
; EDI	 ==>	 DPMI handle entry

DPMIFN_MODMEM_MOVE:
	 pushf			; Save flags
	 cli			; Disallow interrupts

; De-allocate old memory in case there's room just below us
; Note that we're relying upon the fact that ALLOCMEM allocates
; memory from bottom up.

	 push	 AGROUP:[edi].DPMIHNDL_LEN ; Pass old byte length
	 push	 AGROUP:[edi].DPMIHNDL_LA ; Pass old starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
;;;;;;;; jc	 short ???	; Ignore error return

	 mov	 ebx,edx	; Save new size in bytes (/@DPMI_BOUND)

	 push	 @ALLOC_DPMI	; Pass allocation type
	 FIXICALL PGROUP:FQRY_PGCNT,DTE_CS2 ; Request free memory size
				; Return with EAX = # available 1KB
				; ...	      EDX = size of largest in 1KB
	 shl	 edx,10-0	; Convert from 1KB to bytes

	 cmp	 ebx,edx	; Izit big enough?
	 ja	 short DPMIFN_MODMEM_ERR ; Jump if not

	 mov	 edx,ebx	; Restore new size

; Allocate new memory

	 push	 @ALLOC_DPMI	; Tell 'em what kind of memory we're allocating
	 push	 edx		; Pass # bytes to allocate
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
				; Return with EBX = linear address of memory
	 jc	 short DPMIFN_MODMEM_ERR ; Jump if no memory found

; Copy old data to new location

	 push	 edi		; Save for a moment

	 mov	 ecx,AGROUP:[edi].DPMIHNDL_LEN ; ECX = length to move
	 mov	 esi,AGROUP:[edi].DPMIHNDL_LA ; AGROUP:ESI ==> source
	 mov	 edi,ebx	; AGROUP:EDI ==> destin

S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy to its new home

	 pop	 edi		; Restore

	 popf			; Restore
				; (note interrupts might become enabled)
; Save new handle information
; Note that the handle # doesn't change

	 mov	 AGROUP:[edi].DPMIHNDL_LA,ebx ; Save new linear address

	 jmp	 DPMIFN_MODMEM_CLC ; Join common ending code with EDX=new size


; No room anywhere

DPMIFN_MODMEM_ERR:

; Re-allocate old memory

	 push	 AGROUP:[edi].DPMIHNDL_LEN ; Pass old byte length
	 push	 AGROUP:[edi].DPMIHNDL_LA ; Pass old starting linear address
	 FIXICALL PGROUP:FALLOCMEM_SUB,DTE_CS2 ; Deallocate the memory
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
	 popf			; Restore
				; (note interrupts might become enabled)

	 stc			; Mark as in error
DPMIFN_MODMEM_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_MODMEM endp		; End DPMIFN_MODMEM procedure
	 NPPROC  DPMI_GETLMB -- DPMI 1.0 Function to Allocate Linear Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to allocate linear memory block

On entry (in INTXX_STR):

AX	 =	 0504h
EBX	 =	 desired linear address (page aligned)
ECX	 =	 size of block (bytes, must be non-zero)
EDX	 =	 flags bit 0 = 1 means committed, else uncommitted
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
EBX	 =	 linear address of allocated block
ESI	 =	 memory block handle

CF	 =	 1 if not successful
AX	 =	 8012 if linear memory unavailable
	 =	 8013 if physical ...
	 =	 8014 if backing store ...
	 =	 8016 if handle unavailable
	 =	 8021 if invalid value (ECX = 0)
	 =	 8025 if requested address is not page aligned

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Get and validate the block size

	 mov	 ebx,[ebp].INTXX_ECX ; Get the size
	 or	 ebx,ebx	; Izit zero?
	 jz	 near ptr INT31_ERR_INVVAL ; Jump if so

	 add	 ebx,@DPMI_BOUND-1 ; Round up to next
	 and	 ebx,not (@DPMI_BOUND-1) ; ...@DPMI_BOUND boundary

; Find an available memory handle

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS
DPMI_GETLMB_GROWUP:
	 mov	 ecx,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EDI ==> DPMI memory
				; handle table
	 xor	 eax,eax	; A convenient zero
@@:
	 cmp	 eax,AGROUP:[edi].DPMIHNDL_LEN ; Izit available?
	 je	 short DPMI_GETLMB1 ; Jump if so

	 add	 edi,type DPMIHNDL_STR ; Skip to next entry

	 loopd	 @B		; Jump if more handles to check

	 call	 DPMIFN_GROWMEMHNDL ; Attempt to grow DPMI memory handle struc
	 jnc	 short DPMI_GETLMB_GROWUP ; Jump if we succeeded

	 popf			; Restore flags
				; (note interrupts might become enabled)
; No handles available

	 jmp	 INT31_ERR_NOHNDL ; Join common error code

DPMI_GETLMB1:
	 mov	 AGROUP:[edi].DPMIHNDL_LEN,ebx ; Mark as in use


; See if there's enough memory

	 REGSAVE <ecx,ds>	; VMM_ALLOC needs DS=IGROUP

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it
	 mov	 eax,[ebp].INTXX_EBX ; Get requested address (or zero)
	 shr	 ebx,@BytePage	; Convert size to pages
	 xor	 ecx,ecx	; Init flags to zero

	 test	 [ebp].INTXX_EDX,@BIT0 ; Test for commit requested
	 jz	 short @F	; jump if not requested

	 mov	 ecx,mask $commit ; else request committed
@@:
	 call	 VMM_ALLOC	; try to get the memory
	 REGREST <ds,ecx>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jc	 short DPMI_GETLMB_ERR	; jump on error

	 mov	 [ebp].INTXX_EBX,eax ; Return linear address of block
	 mov	 AGROUP:[edi].DPMIHNDL_LA,eax ; Save for later use

	 mov	 AGROUP:[edi].DPMIHNDL_SEL,0 ; Mark as no memory selector

	 mov	 ax,VM2PM_TSS	; Get current TSS selector
	 mov	 AGROUP:[edi].DPMIHNDL_TSS,ax ; Save for later use

; Return the memory block handle in ESI

	 mov	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 sub	 eax,ecx	; Less countdown value to get handle #
				; in origin-0, unit increments
	 mov	 [ebp].INTXX_ESI,eax ; Save the handle

	 popf			; Restore flags

	 jmp	 INT31_CLC	; Join common exit code

DPMI_GETLMB_ERR:
	 mov	[ebp].INTXX_EAX.ELO,ax ; Return error code to caller

	 popf			; Restore flags

	 jmp	 INT31_ERR	; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETLMB endp		; End DPMI_GETLMB procedure
	 NPPROC  DPMI_MODLMB -- DPMI 1.0 Function to Resize Linear Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to resize linear memory block

On entry (in INTXX_STR):

AX	 =	 0505h
ESI	 =	 memory block handle
ECX	 =	 new size of block (bytes, must be non-zero)
EDX	 =	 flags
		   bit 0 = 1 means committed, else uncommitted
		   bit 1 = 1 means update descriptors
ES:EBX	 =	 if (bit 1 of EDX is set) selector:offset of an array
		 of selectors, 1 word (16 bits) per selector
EDI	 =	 count of selectors in array at ES:EBX

IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
EBX	 =	 new linear address of block

CF	 =	 1 if not successful
AX	 =	 8012 if linear memory unavailable
	 =	 8013 if physical ...
	 =	 8014 if backing store ...
	 =	 8021 if invalid value (ECX = 0)
	 =	 8023 if handle is invalid

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Get and validate the memory block handle

	 mov	 eax,[ebp].INTXX_ESI	; Get the handle

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Check against total # handles
	 jae	 near ptr INT31_ERR_INVHNDL ; Jump if it's out of range

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EDI ==> DPMI memory
				; handle table
	 imul	 eax,type DPMIHNDL_STR ; Convert to appropriate units
	 add	 edi,eax	; AGROUP:EDI ==> this handle's entry

	 mov	 esi,AGROUP:[edi].DPMIHNDL_LA ; Get linear address
	 mov	 eax,AGROUP:[edi].DPMIHNDL_LEN ; Get current length in bytes
	 shr	 eax, @BytePage ; convert to pages

	 mov	 edx,[ebp].INTXX_ECX	; Get new size in bytes

	 add	 edx,@DPMI_BOUND-1 ; Round up to @DPMI_BOUND boundary
	 and	 edx,not (@DPMI_BOUND-1) ; ... (which could become 1MB)
	 jz	 near ptr INT31_ERR_INVVAL ; Jump if ECX == 0

	 shr	 edx, @BytePage ; convert to pages

	 pushf			; don't interrupt reallocation
	 cli			; Don't allow interrupts

; Set up call to VMM_REALLOC

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; VMM_REALLOC needs DS=IGROUP
	 assume  ds:IGROUP	; Tell the assembler about it

	 test	 [ebp].INTXX_EDX.ELO.LO,1 ; is bit 0 of flags set?
	 jz	 short DPMI_MODLMB_UNCOMMIT; jump if not

	 push	 dword ptr mask $commit ; Ask for committed memory
	 jmp	 short @F	; Join common code

DPMI_MODLMB_UNCOMMIT:
	 push	 dword ptr 0	; Flags are zero if not committed
@@:
	 push	 edx		; New size in pages
	 push	 eax		; Old size in pages
	 push	 esi		; Linear address of block
	 call	 VMM_REALLOC	; Rets new LA in EAX or zero if fail

	 pop	 ds		; Recall saved DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 or	 eax,eax	; Did it succeed?
	 jz	 near ptr DPMI_MODLMB_NOMEM; jump if not

	 mov	 ebx,[ebp].INTXX_EBX ; Fetch user's input ebx for later
	 mov	 [ebp].INTXX_EBX,eax ; Set return value to user (new LA)

	 shl	 edx,@BytePage	; Convert new size to bytes
	 xchg	 AGROUP:[edi].DPMIHNDL_LEN,edx ; Set new length; edx<-old len
	 xchg	 AGROUP:[edi].DPMIHNDL_LA,eax ; Set linear address
				; and get old LA to eax
	 cmp	 eax,AGROUP:[edi].DPMIHNDL_LA ; Did it change?
	 je	 short DPMI_MODLMB_DONE ; Jump if not

	 test	 [ebp].INTXX_EDX.ELO.LO,2 ; Are there selectors to move?
	 jz	 short DPMI_MODLMB_DONE ; Jump if not

	 mov	 ecx,[ebp].INTXX_EDI	; get selector count
	 jecxz	 DPMI_MODLMB_DONE	; jump out if none

	 push	 fs		; Save for a moment

	 mov	 fs,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  fs:nothing	; Tell the assembler about it

; Now we have to process the array of selectors passed by the user for
; relocation.  The relevant values are:
;
;	edx				old length (bytes)
;	eax				old linear address
;	AGROUP:[edi].DPMIHNDL_LEN	new length (bytes)
;	AGROUP:[edi].DPMIHNDL_LA	new linear address
;	fs:ebx				selector array
;	[ebp].INTXX_EDI 		selector count
;
; The logic is:
;
;    foreach (selector in array)
;	if (selector valid)
;		if (expand up segment)
;			checkpoint = segment base
;		else
;			checkpoint = segment base + limit
;
;		if (old LA <= checkpoint < old LA + old length)
;			segment base += (new LA - old LA)

DPMI_MODLMB_NEXTSEL:
	 mov	 si, fs:[ebx]		; get next selector

	 push	 ecx			; free up a register
	 push	 ebx			; free up a register

	 push	 1			; see if descriptor is modifiable
	 push	 si			; and valid
	 call	 VALID_LSEL
	 jc	 DPMI_MODLMB_ADVANCE	; skip it if invalid or unmodifiable

	 mov	 ebx, eax		; ebx <- old LA of block

	 push	 si			; pass sel arg to getlbase
	 call	 GETLBASE		; returns base of segment in eax

	 lar	 cx, si 		; get segment attributes to ecx

	 test	 cx, mask $DD_EXPD	; is it expand down?
	 jz	 short @F		; jump if not

	 lsl	 ecx, esi		; get limit
	 add	 eax, ecx		; add limit to base to get checkpoint
					;   for expand down segment
@@:					; eax is checkpoint
	 xchg	 eax, ebx		; ebx<-checkpoint; eax<-old LA
	 cmp	 ebx, eax		; is checkpoint below block?
	 jb	 short DPMI_MODLMB_ADVANCE ; jump if so

	 mov	 ecx, eax		; compute top of block
	 add	 ecx, edx		; ecx <- top of block
	 cmp	 ebx, ecx		; is checkpoint above block?
	 jae	 short DPMI_MODLMB_ADVANCE ; jump if so

; We have qualified the descriptor - now reset the base

	 mov	 ecx, eax		; remember old base in ecx

	 push	 si
	 call	 GETLBASE		; get base to eax
	 sub	 eax, ecx		; subtract old base of block
	 add	 eax, AGROUP:[edi].DPMIHNDL_LA ; add new base of block

	 push	 si
	 call	 SETLBASE		; set the new base

	 mov	 eax, ecx		; restore old base to eax
DPMI_MODLMB_ADVANCE:
	 pop	ebx
	 pop	ecx			; recall count

	 add	ebx, 2			; advance to next selector

	 dec	ecx			; dec count of remaining selectors
	 jnz	DPMI_MODLMB_NEXTSEL	; get next if any left

	 pop	 fs
	 assume  fs:nothing	; Tell the assembler about it
DPMI_MODLMB_DONE:
	 popf

	 jmp	 INT31_CLC	; Join common OK code

DPMI_MODLMB_NOMEM:
	 popf

	 jmp	 INT31_ERR_NOMEM ; jump to common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_MODLMB endp		; End DPMI_MODLMB procedure
	 NPPROC  DPMI_GPGATTR -- DPMI 1.0 Function to Get Page Attributes
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to retrieve page attributes

On entry (in INTXX_STR):

AX	 =	 0506h
ESI	 =	 memory block handle
EBX	 =	 base offset in block of first page
ECX	 =	 number of pages
ES:EDX	 =	 selector offset of buffer to receive page attributes
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
EBX	 =	 new linear address of block

CF	 =	 1 if not successful
AX	 =	 8023 if handle is invalid
	 =	 8025 if linear address is invalid

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Get and validate the memory block handle

	 mov	 eax,[ebp].INTXX_ESI	; Get the handle

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Check against total # handles
	 jae	 near ptr INT31_ERR_INVHNDL ; Jump if it's out of range

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EDI ==> DPMI memory
				; handle table
	 imul	 eax,type DPMIHNDL_STR ; Convert to appropriate units
	 add	 edi,eax	; AGROUP:EDI ==> this handle's entry

; Determine if the specified pages are in the block

	 mov	 ecx,[ebp].INTXX_ECX ; get number of pages to set
	 shl	 ecx,@BytePage	; convert to bytes
	 add	 ecx,[ebp].INTXX_EBX ; add offset from block base
	 cmp	 ecx,AGROUP:[edi].DPMIHNDL_LEN ; within the block?
	 ja	 near ptr INT31_ERR_INVADDR ; jump if not

; Set up call to VMM_GET_ATTRIBUTES

	 REGSAVE <ds,fs>	; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP

	 mov	 eax,AGROUP:[edi].DPMIHNDL_LA
	 add	 eax,[ebp].INTXX_EBX ; add offset from block base
	 mov	 ebx,[ebp].INTXX_ECX ; get number of pages to set

	 mov	 fs,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 edi,[ebp].INTXX_EDX
	 IF16ZX  di,IG		; Zero to use as dword if 16-bit client
	 call	 VMM_GET_ATTRIBUTES

	 REGREST <fs,ds>	; Restore
	 assume  ds:PGROUP,fs:nothing

	 jmp	 INT31_CLC	; jump to common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GPGATTR endp		; End DPMI_GPGATTR procedure
	 NPPROC  DPMI_SPGATTR -- DPMI 1.0 Function to Set Page Attributes
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to set page attributes

On entry (in INTXX_STR):

AX	 =	 0507h
ESI	 =	 memory block handle
EBX	 =	 base offset in block of first page
ECX	 =	 number of pages
ES:EDX	 =	 selector offset of buffer containing page attributes
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
EBX	 =	 new linear address of block

CF	 =	 1 if not successful
AX	 =	 8023 if handle is invalid
	 =	 8025 if linear address is invalid
ECX	 =	 number of pages that were successfully set

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Get and validate the memory block handle

	 mov	 eax,[ebp].INTXX_ESI	; Get the handle

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Check against total # handles
	 jae	 near ptr INT31_ERR_INVHNDL ; Jump if it's out of range

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EDI ==> DPMI memory
				; handle table
	 imul	 eax,type DPMIHNDL_STR ; Convert to appropriate units
	 add	 edi,eax	; AGROUP:EDI ==> this handle's entry

; Determine if the specified pages are in the block

	 mov	 ecx,[ebp].INTXX_ECX ; get number of pages to set
	 shl	 ecx,@BytePage	; convert to bytes
	 add	 ecx,[ebp].INTXX_EBX ; add offset from block base

	 cmp	 ecx,AGROUP:[edi].DPMIHNDL_LEN ; within the block?
	 ja	 near ptr INT31_ERR_INVADDR ; jump if not

	 pushf
	 cli			; don't interrupt

; Set up call to VMM_SET_ATTRIBUTES

	 REGSAVE <ds,fs>	; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP

	 mov	 eax,AGROUP:[edi].DPMIHNDL_LA
	 add	 eax,[ebp].INTXX_EBX ; add offset from block base
	 mov	 ebx,[ebp].INTXX_ECX ; get number of pages to set

	 mov	 fs,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 edi,[ebp].INTXX_EDX
	 IF16ZX  di,IG		; Zero to use as dword if 16-bit client
	 call	 VMM_SET_ATTRIBUTES

	 REGREST <fs,ds>	; Restore
	 assume  ds:PGROUP,fs:nothing

	 popf

	 or	 ebx, ebx	; any pages left?
	 jz	 near ptr INT31_CLC

	 sub	 [ebp].INTXX_ECX, ebx	; inform client of how many were set

	 jmp	 INT31_ERR_INVVAL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_SPGATTR endp		; End DPMI_SPGATTR procedure
	 NPPROC  DPMI_MAPDEV -- DPMI 1.0 Function to Map Device in Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to map device in Memory Block

On entry (in INTXX_STR):

AX	 =	 0508h
ESI	 =	 memory block handle
EBX	 =	 base offset in block of first page
ECX	 =	 number of pages to map
EDX	 =	 physical address of device (must be page aligned)
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8003 if device address is invalid
	 =	 8023 if handle is invalid
	 =	 8025 if linear address is invalid

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Get and validate the memory block handle

	 mov	 eax,[ebp].INTXX_ESI	; Get the handle

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Check against total # handles
	 jae	 near ptr INT31_ERR_INVHNDL ; Jump if it's out of range

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EDI ==> DPMI memory
				; handle table
	 imul	 eax,type DPMIHNDL_STR ; Convert to appropriate units
	 add	 edi,eax	; AGROUP:EDI ==> this handle's entry

; Determine if the specified pages are in the block

	 mov	 ecx,[ebp].INTXX_ECX ; get number of pages to set
	 shl	 ecx,@BytePage	; convert to bytes
	 add	 ecx,[ebp].INTXX_EBX ; add offset from block base
	 cmp	 ecx,AGROUP:[edi].DPMIHNDL_LEN ; within the block?
	 ja	 near ptr INT31_ERR_INVADDR ; jump if not

	 pushf
	 cli			; don't interrupt

; Set up call to VMM_MAP_PHYSICAL

	 push	 ds		; need DS=IGROUP

	 mov	 ds,SEL_DSIG3	;
	 assume  ds:IGROUP

	 mov	 eax,AGROUP:[edi].DPMIHNDL_LA
	 add	 eax,[ebp].INTXX_EBX ; add offset from block base
	 mov	 ebx,[ebp].INTXX_EDX ; physical address
	 mov	 ecx,[ebp].INTXX_ECX ; get number of pages to map
	 xor	 edx,edx	     ; flag: map physical

	 call	 VMM_MAP_PHYSICAL
	 jc	 short DPMI_MAPDEV_FAIL

	 pop	 ds		; restore ds
	 assume  ds:PGROUP	; tell assembler

	 popf			; restore flags

	 jmp	 INT31_CLC	; join common exit code

DPMI_MAPDEV_FAIL:
	 pop	 ds		; restore ds
	 assume  ds:PGROUP	; tell assembler

	 popf			; restore flags

	 jmp	 INT31_ERR_INVADDR	; join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_MAPDEV endp		; End DPMI_MAPDEV procedure
	 NPPROC  DPMI_MAPCONV -- DPMI 1.0 Function to Map Conventional Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to map device in Memory Block

On entry (in INTXX_STR):

AX	 =	 0509h
ESI	 =	 memory block handle
EBX	 =	 base offset in block of first page
ECX	 =	 number of pages to map
EDX	 =	 linear address of conventional memory (must be page aligned)
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8003 if device address is invalid
	 =	 8023 if handle is invalid
	 =	 8025 if linear address is invalid

All other registers except EBP, FS, GS, and SS may be clobbered.

|
; Validate the linear address of the conventional memory

	 mov	 eax,[ebp].INTXX_EDX	; get conv address

	 test	 eax,(@PageSize-1)	; page aligned?
	 jnz	 near ptr INT31_ERR_INVADDR	 ; jump if not

	 cmp	 eax,CON1P1MB		; In the conventional region?
	 ja	 near ptr INT31_ERR_INVADDR ; Jump if not

; Get and validate the memory block handle

	 mov	 eax,[ebp].INTXX_ESI	; Get the handle

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Check against total # handles
	 jae	 near ptr INT31_ERR_INVHNDL ; Jump if it's out of range

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EDI ==> DPMI memory
				; handle table
	 imul	 eax,type DPMIHNDL_STR ; Convert to appropriate units
	 add	 edi,eax	; AGROUP:EDI ==> this handle's entry

; Determine if the specified pages are in the block

	 mov	 ecx,[ebp].INTXX_ECX ; get number of pages to set
	 shl	 ecx,@BytePage	; convert to bytes
	 add	 ecx,[ebp].INTXX_EBX ; add offset from block base
	 cmp	 ecx,AGROUP:[edi].DPMIHNDL_LEN ; within the block?
	 ja	 near ptr INT31_ERR_INVADDR ; jump if not

	 pushf			; save flags
	 cli			; don't interrupt

; Set up call to VMM_MAP_PHYSICAL

	 push	 ds		; need DS=IGROUP
	 mov	 ds,SEL_DSIG3	;
	 assume ds:IGROUP

	 mov	 eax,AGROUP:[edi].DPMIHNDL_LA
	 add	 eax,[ebp].INTXX_EBX ; add offset from block base
	 mov	 ebx,[ebp].INTXX_EDX ; physical address
	 mov	 ecx,[ebp].INTXX_ECX ; get number of pages to map
	 mov	 edx,1		     ; flag: map conventional
	 call	 VMM_MAP_PHYSICAL
	 jc	 short DPMI_MAPCONV_FAIL

	 pop	 ds		; restore ds
	 assume ds:PGROUP	; tell assembler
	 popf			; restore flags
	 jmp	 INT31_CLC	; join common exit code

DPMI_MAPCONV_FAIL:
	 pop	 ds		; restore ds
	 assume  ds:PGROUP	; tell assembler
	 popf			; restore flags
	 jmp	 INT31_ERR_INVADDR	; join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_MAPCONV endp		; End DPMI_MAPCONV procedure
	 NPPROC  DPMI_GETMBLKSZ -- DPMI 1.0 Function to get block size and base
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to get block size and base

On entry (in INTXX_STR):

AX	 =	 050Ah
SI:DI	 =	 memory block handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
SI:DI	 =	 size of memory block (bytes)
BX:CX	 =	 base address of memory block

CF	 =	 1 if not successful
	 =	 8023 if handle is invalid

All other registers except EBP, GS, and SS may be clobbered.

|

; Get and validate the memory block handle

	 mov	 ax,[ebp].INTXX_ESI.ELO; Get the high half of handle
	 shl	 eax, 16
	 mov	 ax,[ebp].INTXX_EDI.ELO; Get the low half of handle

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS

	 cmp	 eax,PGROUP:[edx].DPTSS_DPMIHNDL_CNT ; Check against total # handles
	 jae	 near ptr INT31_ERR_INVHNDL ; Jump if it's out of range

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PGROUP:[edx].DPTSS_LaDPMIHNDL ; AGROUP:EDI ==> DPMI memory
				; handle table
	 imul	 eax,type DPMIHNDL_STR ; Convert to appropriate units
	 add	 edi,eax	; AGROUP:EDI ==> this handle's entry

	 mov	 eax, AGROUP:[edi].DPMIHNDL_LA ; fetch base address
	 mov	 [ebp].INTXX_ECX.ELO, ax	; store low half of base
	 shr	 eax, 16
	 mov	 [ebp].INTXX_EBX.ELO, ax	; store high half of base

	 mov	 eax, AGROUP:[edi].DPMIHNDL_LEN ; fetch size
	 mov	 [ebp].INTXX_EDI.ELO, ax	; store low half of size
	 shr	 eax, 16
	 mov	 [ebp].INTXX_ESI.ELO, ax	; store high half of size

	 jmp	 INT31_CLC		; join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETMBLKSZ endp		; End DPMI_GETMBLKSZ procedure
	 NPPROC  DPMI_GETMEMI -- DPMI 1.0 Function to get memory information
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to get memory information

On entry (in INTXX_STR):

AX	 =	 050Bh
ES:EDI	 =	 buffer to receive memory information
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0

All other registers except EBP, FS, GS, and SS may be clobbered.

|
	 mov	 es,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  es:nothing	; Tell the assembler about it
	 mov	 edi,[ebp].INTXX_EDI
	 IF16ZX  di		; Zero to use as dword if 16-bit client

	 mov	 eax,PhysicalInuse		; get total physical in use
	 shl	 eax, @BytePage 		; convert to bytes
	 mov	 es:[edi].MI_physical, eax	; store in client array

	 mov	 eax,PhysicalManaged		; get total physical page count
	 shl	 eax, @BytePage 		; convert to bytes
	 mov	 ecx,BSTotal			; get backing store total
	 shl	 ecx,@BytePage			; convert to bytes
	 add	 eax,ecx			; eax <- total virtual bytes

	 mov	 ecx,PhysicalInuse		; calc virtual in use
	 add	 ecx,BSInUse			; add backstore pages in use
	 add	 ecx,VirtualReserved		; add allocated but not touched
	 shl	 ecx,@BytePage			; ecx <- total bytes in use

	 sub	 eax,ecx			; available = total - in_use

	 mov	 es:[edi].MI_virtual, ecx	; store allocated in client array
	 mov	 es:[edi].MI_virtualVM, ecx	; ...
	 mov	 es:[edi].MI_virtualClient, ecx ; ...

	 mov	 es:[edi].MI_available, eax	; store available in client array
	 mov	 es:[edi].MI_availableVM, eax	; ...
	 mov	 es:[edi].MI_availableClient,eax; ...

	 mov	 eax,PhysicalLocked		; get locked count
	 shl	 eax,@BytePage			; convert to bytes
	 mov	 es:[edi].MI_lockedClient, eax	; store in client array

	 mov	 ecx,PhysicalManaged		; calc lockable
	 shl	 ecx,@BytePage			; convert to bytes
	 sub	 ecx,eax			; lockable=managed-locked
	 mov	 es:[edi].MI_maxLockedClient,ecx; store in client array

	 mov	 eax,LinearClientTop		; top of client region
	 mov	 es:[edi].MI_highAddr, eax	; store in client array

	 FIXICALL IGROUP:VMM_QUERY,DTE_CSIG	; edx <- largest block in KB

	 shl	 edx,10 			; convert to bytes
	 mov	 es:[edi].MI_largestFree,edx	; set largest free block

	 mov	 es:[edi].MI_minAlloc, @PageSize; set minimum alloc unit
	 mov	 es:[edi].MI_allocAlign, @PageSize; set alignment unit

	 jmp	 INT31_CLC		; join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETMEMI endp		; End DPMI_GETMEMI procedure
	 NPPROC  DPMI_LOCKLINREG -- DPMI 0.9 Function to Lock a Linear Region
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to lock a linear region

On entry (in INTXX_STR):

AX	 =	 0600h
BX:CX	 =	 starting linear address of memory to lock
SI:DI	 =	 size of region to lock in bytes
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0

CF	 =	 1 if not successful
AX	 =	 8013 if physical memory unavailable
	 =	 8017 if lock count exceeded
	 =	 8025 if invalid linear address (unallocated pages)

All other registers except EBP, FS, GS, and SS may be clobbered.

|

if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_SYSINIT ; Is VMM active?
	 jz	 near ptr INT31_CLC ; Jump if not

	 push	 ds		; Save for a moment

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 call	 DPMIFN_VMADDR	; Return with EAX = starting linear address (/4KB)
				;	      EBX = size in pages
	 call	 VMM_LOCK	; Lock it
				; Return with CF signifcant and error code in AX
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jnc	 near ptr INT31_CLC ; Jump if all went OK

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save error code

	 jmp	 INT31_ERR	; Join common error exit code
else
	 jmp	 INT31_CLC	; Join common exit code
endif				; IF @OEM_VIRTUALMEM

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_LOCKLINREG endp		; End DPMI_LOCKLINREG procedure
	 NPPROC  DPMI_UNLKLINREG -- DPMI 0.9 Function to Unlock a Linear Region
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to unlock a linear region

On entry (in INTXX_STR):

AX	 =	 0601h
BX:CX	 =	 starting linear address of memory to unlock
SI:DI	 =	 size of region to unlock in bytes
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0

All other registers except EBP, FS, GS, and SS may be clobbered.

|

if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_SYSINIT ; Is VMM active?
	 jz	 near ptr INT31_CLC ; Jump if not

	 push	 ds		; Save for a moment

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 call	 DPMIFN_VMADDR	; Return with EAX = starting linear address (/4KB)
				;	      EBX = size in pages
	 call	 VMM_UNLOCK	; Unlock it
				; Return with CF signifcant and error code in AX
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jnc	 near ptr INT31_CLC ; Jump if all went OK

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save error code

	 jmp	 INT31_ERR	; Join common error exit code
else
	 jmp	 INT31_CLC	; Join common exit code
endif				; IF @OEM_VIRTUALMEM

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_UNLKLINREG endp		; End DPMI_UNLKLINREG procedure
	 NPPROC  DPMI_PAGEVM -- DPMI 0.9 Function to Mark VM Region as Pageable
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to mark a virtual mode region as pageable

On entry (in INTXX_STR):

AX	 =	 0602h
BX:CX	 =	 starting linear address of memory to unlock
SI:DI	 =	 size of region to unlock in bytes
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_PAGEVM endp		; End DPMI_PAGEVM procedure
	 NPPROC  DPMI_RLCKVM -- DPMI 0.9 Function to Relock VM Region
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to relock a VM region

On entry (in INTXX_STR):

AX	 =	 0603h
BX:CX	 =	 starting linear address of memory to unlock
SI:DI	 =	 size of region to unlock in bytes
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_RLCKVM endp		; End DPMI_RLCKVM procedure
	 NPPROC  DPMI_GETPAGESIZ -- DPMI 0.9 Function to Get Page Size
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get page size

On entry (in INTXX_STR):

AX	 =	 0604h
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0
BX:CX	 =	 page size in bytes

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Return page size as minimum size of memory which can be
; allocated through DPMI_GETMEM

	 mov	 [ebp].INTXX_ECX.ELO,@DPMI_BOUND ; It's @DPMI_BOUND
	 mov	 [ebp].INTXX_EBX.ELO,0

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETPAGESIZ endp		; End DPMI_GETPAGESIZ procedure
	 NPPROC  DPMI_PGSELUNLK -- DPMI 0.8 Function to Mark Page as Pageable
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.8 function to mark a page as pageable

On entry (in INTXX_STR):

AX	 =	 0700h
BX	 =	 selector to mark as pageable
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get the selector

	 push	 0		; Ignore modifiable check
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if something went wrong

	 push	 bx		; Pass the selector
	 call	 GETLBASE	; Return with EAX = base address from LDT

	 lsl	 ebx,ebx	; Get the segment limit
	 jmp	 short $+2	; Fix for Errata # 14 & 20

	 inc	 ebx		; Convert from limit to length
	 shr	 ebx,12-0	; Convert from bytes to 4KB

if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_BSPRES ; Is swapfile present?
	 jz	 near ptr INT31_CLC ; Jump if not

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 call	 VMM_MARK_CANDIDATES ; Mark as pageable
				; Return with CF signifcant and error code in AX
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jnc	 near ptr INT31_CLC ; Jump if all went OK

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save error code

	 jmp	 INT31_ERR	; Join common error exit code
else
	 jmp	 INT31_CLC	; Join common exit code
endif				; IF @OEM_VIRTUALMEM

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_PGSELUNLK endp		; End DPMI_PGSELUNLK procedure
	 NPPROC  DPMI_PGSELFREE -- DPMI 0.8 Function to Mark Page as Discardable
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.8 function to mark a page as discardable

On entry (in INTXX_STR):

AX	 =	 0701h
BX	 =	 selector to mark as discardable
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get the selector

	 push	 0		; Ignore modifiable check
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if something went wrong

	 push	 bx		; Pass the selector
	 call	 GETLBASE	; Return with EAX = base address from LDT

	 lsl	 ebx,ebx	; Get the segment limit
	 jmp	 short $+2	; Fix for Errata # 14 & 20

	 inc	 ebx		; Convert from limit to length

if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_BSPRES ; Is swapfile present?
	 jz	 near ptr INT31_CLC ; Jump if not

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

; Watch out - don't discard partial pages

	 add	 ebx,eax	; Add to get ending address

	 add	 eax,@PageSize-1
	 and	 eax,not (@PageSize-1) ; Round starting address up to 4KB boundary

	 and	 ebx,not (@PageSize-1) ; Round ending address down to 4KB boundary

	 sub	 ebx,eax	; Subtract to get length in bytes (/4KB)
	 shr	 ebx,@BytePage	; Convert from bytes to 4KB

	 call	 VMM_DISCARD_PAGES ; Mark as discardable
				; Return with CF signifcant and error code in AX
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jnc	 near ptr INT31_CLC ; Jump if all went OK

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save error code

	 jmp	 INT31_ERR	; Join common error exit code
else
	 jmp	 INT31_CLC	; Join common exit code
endif				; IF @OEM_VIRTUALMEM

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_PGSELFREE endp		; End DPMI_PGSELFREE procedure
	 NPPROC  DPMI_PGUNLK -- DPMI 0.9 Function to Mark Page as Pageable
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to mark a page as pageable

On entry (in INTXX_STR):

AX	 =	 0702h
BX:CX	 =	 starting linear address of pages to mark as pageable
SI:DI	 =	 size of region to unlock in bytes
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0

All other registers except EBP, FS, GS, and SS may be clobbered.

|

if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_BSPRES ; Is swapfile present?
	 jz	 near ptr INT31_CLC ; Jump if not

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 call	 DPMIFN_VMADDR	; Return with EAX = starting linear address (/4KB)
				;	      EBX = size in pages
	 call	 VMM_MARK_CANDIDATES ; Mark as pageable
				; Return with CF signifcant and error code in AX
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jnc	 near ptr INT31_CLC ; Jump if all went OK

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save error code

	 jmp	 INT31_ERR	; Join common error exit code
else
	 jmp	 INT31_CLC	; Join common exit code
endif				; IF @OEM_VIRTUALMEM

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_PGUNLK endp		; End DPMI_PGUNLK procedure
	 NPPROC  DPMI_PGFREE -- DPMI 0.9 Function to Mark Page as Discardable
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to mark a page as discardable

On entry (in INTXX_STR):

AX	 =	 0703h
BX:CX	 =	 starting linear address of pages to discard
SI:DI	 =	 size of region to discard in bytes
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0

All other registers except EBP, FS, GS, and SS may be clobbered.

|

if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_BSPRES		; Is swapfile present?
	 jz	 INT31_CLC			; jump if not

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

; Watch out - don't discard partial pages

	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get high-order word of starting LA
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get low-order word of starting LA

	 mov	 bx,[ebp].INTXX_ESI.ELO ; Get high-order word of size in bytes
	 shl	 ebx,16 	; Shift to high-order word
	 mov	 bx,[ebp].INTXX_EDI.ELO ; Get low-order word of size in bytes

	 add	 ebx,eax	; Add to get ending address

	 add	 eax,@PageSize-1
	 and	 eax,not (@PageSize-1) ; Round starting address up to 4KB boundary

	 and	 ebx,not (@PageSize-1) ; Round ending address down to 4KB boundary

	 sub	 ebx,eax	; Subtract to get length in bytes (/4KB)
	 shr	 ebx,@BytePage	; Convert from bytes to 4KB

	 call	 VMM_DISCARD_PAGES ; Mark as discardable
				; Return with CF signifcant and error code in AX
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jnc	 near ptr INT31_CLC ; Jump if all went OK

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save error code

	 jmp	 INT31_ERR	; Join common error exit code
else
	 jmp	 INT31_CLC	; Join common exit code
endif				; IF @OEM_VIRTUALMEM

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_PGFREE endp		; End DPMI_PGFREE procedure
	 NPPROC  DPMI_GETP2L -- DPMI 0.9 Function to Get Physical to Linear Mapping
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get physical to linear address mapping

On entry (in INTXX_STR):

AX	 =	 0800h
BX:CX	 =	 physical address of memory
SI:DI	 =	 size of region to map in bytes
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
BX:CX	 =	 corresponding linear address

CF	 =	 1 if not successful
AX	 =	 8003 if system integrity error (DPMI host memory region)
	 =	 8012 if linear memory unavailable (PTEs)
	 =	 8021 if invalid value (address below 1MB)

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Get and validate the physical address

	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get the high-order word
	 shl	 ebx,16 		; Shift to high-order word
	 mov	 bx,[ebp].INTXX_ECX.ELO ; Get the low-order word

	 test	 DB2_FLAG,@DB2_DPMIPHYS ; Disable the checks?
	 jnz	 short @F		; Jump if so

	 cmp	 ebx,CON1MB		; Izit below 1MB?
	 jb	 near ptr INT31_ERR_INVVAL ; Jump if so
@@:
	 mov	 edi,ebx		; Copy starting address
	 and	 di,mask $PTE_FRM	; Isolate 4KB frame

; Get the region size

	 mov	 dx,[ebp].INTXX_ESI.ELO ; Get the high-order word
	 shl	 edx,16 		; Shift to high-order word
	 mov	 dx,[ebp].INTXX_EDI.ELO ; Get the low-order word

	 add	 edx,ebx		; Edx <- top address
	 jz	 short @F		; Jump if it's just zero (that's OK)
	 jc	 near ptr INT31_ERR_NOPHYSMEM ; Jump if no memory to set up mapping
@@:
	 add	 edx,@PageSize-1	; Round up to page boundary
	 and	 dx,mask $PTE_FRM	; Complete round up
	 sub	 edx,edi		; Calc size of region in bytes
	 shr	 edx,@BytePage		; Convert to pages

	 push	 edx			; Arg: number of pages to map
	 push	 edi			; Arg: phys addr to map
	 call	 VMM_MAPP2L		; Call VMM to set up the mapping
	 jc	 INT31_ERR_NOPHYSMEM	; Jump if no memory to set up mapping
					; linear address returned in eax

; Return linear address to caller in BX:CX

	 and	 [ebp].INTXX_ECX.ELO,(@PageSize-1) ; Save low bits
	 or	 [ebp].INTXX_ECX.ELO,ax ; Save low-order word
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_EBX.ELO,ax ; Save high-order word

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETP2L endp		; End DPMI_GETP2L procedure
	 NPPROC  DPMI_RELP2L -- DPMI 1.0 Function to Release Physical to Linear Mapping
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to get physical to linear address mapping

On entry (in INTXX_STR):

AX	 =	 0801h
BX:CX	 =	 linear address of mapping
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
CF	 =	 1 if not successful
AX	 =	 8025H if no mapping at specified address

All other registers except EBP, FS, GS, and SS may be clobbered.

|
	 mov	 ax,[ebp].INTXX_EBX.ELO ; pick up high word of address
	 shl	 eax,16 		; shift it up
	 mov	 ax,[ebp].INTXX_ECX.ELO ; pick up low word of address

	 call	 VMM_UNMAPP2L		; unmap it
	 jc	 INT31_ERR_INVADDR	; jump on bad linear address

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_RELP2L endp		; End DPMI_RELP2L procedure
	 NPPROC  DPMI_INTCLI -- DPMI 0.9 Function to Get & Disable Virtual Interrupt State
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get and disable the virtual interrupt state

On entry (in INTXX_STR):

AX	 =	 0900h
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0
AL	 =	 0 if virtual interrupts were previously disabled
	 =	 1 ...					 enabled

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 btr	 [ebp].INTXX_EFL.ELO,$IF ; Disable interrupts
	 setc	 [ebp].INTXX_EAX.ELO.LO ; Set AL as appropriate

COMMENT|

Because of a bug in Intel Code Builder software, at times
they expect that the high-order word of EAX to be zero.
The circumstances under which they make this assumption are
in this code:

	 PUSH	 EAX
	 MOV	 AX,0900
	 INT	 31
	 XCHG	 EAX,[ESP]
	 PUSH	 EDI
	 PUSH	 ESI
	 MOV	 ESI,[EBP+xxxxxxxx]
	 LEA	 ESI,[ESI+xxxxxxxx]
	 MOV	 AX,0005
	 MUL	 BL
	 ADD	 ESI,EAX

If we detect this code, we should clear the high-order
word of the first dword on the PL3 stack.

|

	 test	 [ebp].INTXX_CS,mask $PL ; Izit PL0?
	 jz	 short DPMI_INTCLI_EXIT ; Jump if so

; Address caller's return CS:EIP for signature check

	 mov	 es,SEL_4GB3	; Get our all memory selector
	 assume  es:AGROUP	; Tell the assembler about it

	 push	 [ebp].INTXX_CS ; Get caller's CS
	 call	 GETLBASE	; Return with EAX = base address from LDT

	 mov	 edi,eax	; Copy to string register
	 add	 edi,[ebp].INTXX_EIP ; ES:EDI ==> caller's CS:EIP

	 lea	 esi,INTELCB	; DS:ESI ==> signature
	 mov	 ecx,INTELCB_LEN ; ECX = # bytes in signature
DPMI_INTCLI_NEXT:
	 jecxz	 DPMI_INTCLI_MATCH ; Jump if there's nothing more to compare
    repe cmps	 INTELCB[esi],AGROUP:[edi].LO ; Compare 'em
	 je	 short DPMI_INTCLI_MATCH ; Jump if it's a match

; Handle differences in the two four-byte fixup areas
; Note that ESI has been incremented past the different byte
; This means that it is in the range INTELCB_Fx[1 4].

	 cmp	 esi,offset IGROUP:INTELCB_F1[1] ; Izit in the first region?
	 jb	 short @F	; Jump if not

	 cmp	 esi,offset IGROUP:INTELCB_F1[4] ; Izit in the first region?
	 jbe	 short DPMI_INTCLI_NEXT ; Jump if so
@@:
	 cmp	 esi,offset IGROUP:INTELCB_F2[1] ; Izit in the first region?
	 jb	 short @F	; Jump if not

	 cmp	 esi,offset IGROUP:INTELCB_F2[4] ; Izit in the first region?
	 jbe	 short DPMI_INTCLI_NEXT ; Jump if so
@@:
	 jmp	 short DPMI_INTCLI_EXIT ; No match -- join common exit code


; It's a match:  zero the high-order word of the first dword on the stack

DPMI_INTCLI_MATCH:
	 les	 edi,[ebp].INTXX_ESP.EDF ; ES:EDI ==> caller's stack
	 assume  es:nothing	; Tell the assembler about it

	 IF16ZX  di,IG		; Zero to use as dword if 16-bit client

	 mov	 es:[edi].EHI,0 ; Zero it
DPMI_INTCLI_EXIT:
	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_INTCLI endp		; End DPMI_INTCLI procedure
	 NPPROC  DPMI_INTSTI -- DPMI 0.9 Function to Get & Enable Virtual Interrupt State
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get and enable the virtual interrupt state

On entry (in INTXX_STR):

AX	 =	 0901h
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0
AL	 =	 0 if virtual interrupts were previously disabled
	 =	 1 ...					 enabled

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 bts	 [ebp].INTXX_EFL.ELO,$IF ; Enable interrupts
	 setc	 [ebp].INTXX_EAX.ELO.LO ; Set AL as appropriate

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_INTSTI endp		; End DPMI_INTSTI procedure
	 NPPROC  DPMI_GETIF -- DPMI 0.9 Function to Get Virtual Interrupt State
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get the virtual interrupt state

On entry (in INTXX_STR):

AX	 =	 0902h
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0
AL	 =	 0 if virtual interrupts were previously disabled
	 =	 1 ...					 enabled

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 bt	 [ebp].INTXX_EFL.ELO,$IF ; Query interrupts
	 setc	 [ebp].INTXX_EAX.ELO.LO ; Set AL as appropriate

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETIF endp 		; End DPMI_GETIF procedure
	 FPPROC  DPMIFN_CHKVSAPI -- Check on Vendor-Specific API
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on vendor-specific API entry point.

This routine is a far procedure so it can be
called from our INT 2Fh handler (when AX=168Ah).

On exit:

ZF	 =	 1 if it's '386MAX',0 or 'MS-DOS',0
ES:eDI	 ==>	 our entry point

ZF	 =	 0 if not

|

CHKVSAPI_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   CS:IP
CHKVSAPI_FVEC df ?		; Ptr to ASCIIZ string to check

CHKVSAPI_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,bx,ds>	; Save registers

	 lds	 eax,[ebp].CHKVSAPI_FVEC ; DS:EAX ==> ASCIIZ string
	 assume  ds:nothing	; Tell the assembler about it

	 IF16ZX  ax,IG		; Zero to use as dword if 16-bit client

; To indicate that we support MS-DOS API Extensions for DPMI Hosts,
; we match the name "MS-DOS",0

	 lea	 bx,VSAPI_MSDOS ; Assume it's 'MS-DOS'

	 cmp	 ds:[eax].EDD,'D-SM' ; Izit bytes 0-3 of 'MS-DOS',0?
	 jne	 short @F	; Jump if not

	 cmp	 ds:[eax+4].ELO,'SO' ; Izit bytes 4-5 of 'MS-DOS',0?
	 jne	 short @F	; Jump if not

	 cmp	 ds:[eax+6].LO,0 ; Izit byte 6 of 'MS-DOS',0?
	 je	 short DPMIFN_CHKVSAPI_MATCH ; Jump if so
@@:
	 lea	 bx,VSAPI_386MAX ; Assume it's '386MAX'

	 cmp	 ds:[eax].EDD,'M683' ; Izit bytes 0-3 of '386MAX',0?
	 jne	 short DPMIFN_CHKVSAPI_EXIT ; Jump if not (note ZF=0)

	 cmp	 ds:[eax+4].ELO,'XA' ; Izit bytes 4-5 of '386MAX',0?
	 jne	 short DPMIFN_CHKVSAPI_EXIT ; Jump if not (note ZF=0)

	 cmp	 ds:[eax+6].LO,0 ; Izit byte 6 of '386MAX',0?
	 jne	 short DPMIFN_CHKVSAPI_EXIT ; Jump if not (note ZF=0)
DPMIFN_CHKVSAPI_MATCH:

; It's a match -- return DTE_DMIDEF:PMVSAPIxx

	 mov	 es,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 es,DPMI_IDEF	; Get our interrupt selector
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short @F	; Jump if so

	 add	 bx,type VSAPI_MSDOS ; Skip to 32-bit entry point
	 xor	 edi,edi	; Zero high-order word
@@:
	 mov	 di,IGROUP:[bx] ; ES:eDI ==> our 16/32-bit entry point

	 cmp	 eax,eax	; Set ZF=1
DPMIFN_CHKVSAPI_EXIT:
	 REGREST <ds,bx,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 6		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_CHKVSAPI endp		; End DPMIFN_CHKVSAPI procedure
	 NPPROC  DPMI_VSAPI -- DPMI 0.9 Function to Get Vendor-Specific API Entry Point
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get the vendor-specific API entry point

On entry (in INTXX_STR):

AX	 =	 0A00h
DS:eSI	 =	 Sel:Off of ASCIIZ string which identifies the DPMI host
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
ES:eDI	 =	 Sel:Off of extended API entry point

CF	 =	 1 if not successful
AX	 =	 8001 if function not supported

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 push	 [ebp-@I31BACK].I31_DS ; Pass caller's DS
	 push	 [ebp].INTXX_ESI ; Pass caller's ESI
	 FCALL	 DPMIFN_CHKVSAPI ; Izit our string?
	 assume  es:nothing	; Tell the assembler about it
	 jne	 near ptr INT31_ERR_NOFNS ; Mark as no match

	 mov	 [ebp-@I31BACK].I31_ES,es ; Return in caller's ES

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short @F	; Jump if so

	 mov	 [ebp].INTXX_EDI,edi ; Return in caller's EDI

	 jmp	 INT31_CLC	; Join common exit code

@@:
	 mov	 [ebp].INTXX_EDI.ELO,di ; Return in caller's DI

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_VSAPI endp 		; End DPMI_VSAPI procedure
	 NPPROC  DPMI_DBGSET -- DPMI 0.9 Function to Set Debug Watchpoint
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to set debug watchpoint

On entry (in INTXX_STR):

AX	 =	 0B00h
BX:CX	 =	 linear address of watchpoint
DL	 =	 size of watchpoint (1, 2, or 4)
DH	 =	 type of watchpoint
		 0 = execute
		 1 = write
		 2 = read/write
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
BX	 =	 watchpoint handle

CF	 =	 1 if not successful
AX	 =	 8016 if too many watchpoints
	 =	 8021 if invalid value (in DL or DH)
	 =	 8025 if invalid linear address (address not mapped
			 or alignment error)

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 movzx	 edx,[ebp].INTXX_EDX.ELO ; Get type (DH) and size (DL) values

; Ensure the type value is valid

	 cmp	 dh,2		; Check against maximum
	 ja	 near ptr INT31_ERR_INVVAL ; Jump if too large

; Ensure the size value is valid

	 cmp	 dx,0001h	; Izit an execute byte breakpoint?
	 je	 short DPMI_DBGSET1 ; Jump if so

	 cmp	 dh,0		; Izit an execute non-byte breakpoint?
	 je	 near ptr INT31_ERR_INVVAL ; Jump if so

	 cmp	 dl,1		; Izit byte breakpoint?
	 je	 short DPMI_DBGSET1 ; Jump if so

; From here on the address must be on at least a word boundary

	 test	 [ebp].INTXX_ECX.ELO.LO,@BIT0 ; Izit on word boundary?
	 jnz	 near ptr INT31_ERR_INVADDR ; Jump if not

	 cmp	 dl,2		; Izit word breakpoint?
	 je	 short DPMI_DBGSET1 ; Jump if so

; From here on the address must be on at least a dword boundary

	 test	 [ebp].INTXX_ECX.ELO.LO,@BIT1 ; Izit on dword boundary?
	 jnz	 near ptr INT31_ERR_INVADDR ; Jump if not

	 cmp	 dl,4		; Izit dword breakpoint?
	 jne	 near ptr INT31_ERR_INVVAL ; Jump if not
DPMI_DBGSET1:

; Find an available debug register

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 movzx	 ecx,DBGCTL	; Get debug control bits
	 xor	 cx,@BIT3 or @BIT2 or @BIT1 or @BIT0 ; Complement to use with BSF

	 bsf	 cx,cx		; Search for first available register
	 jz	 short DPMI_DBGSET_ERR ; Jump if none available
				; CL =	0 for DR0
				;    =	1     DR1
				;    =	2     DR2
				;    =	3     DR3

	 bts	 DBGCTL.ELO,cx	; Mark that register as in use

	 popf			; Restore flags
				; (note interrupts might become enabled)
; Clear the corresponding status bit

	 btr	 DBGSTA.ELO,cx	; Clear it

; Save the linear address in DBGREGS

	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get high-order of address
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get low-order of address

	 mov	 DBGREGS[ecx*(type DBGREGS)],eax ; Save it

; Return the watchpoint handle in caller's BX

	 mov	 [ebp].INTXX_EBX.ELO,cx ; Return it

; Set the linear address into DRn

	 jmp	 DBGREGS_ACT[ecx*(type DBGREGS_ACT)] ; Take appropriate action

DPMI_DBGSET_ERR:
	 popf			; Restore flags
				; (note interrupts might become enabled)
	 jmp	 INT31_ERR_NOHNDL ; Join common error code

DPMI_DBGSET_DR0:
	 mov	 dr0,eax	; Set the address

	 jmp	 short DPMI_DBGSET_COM ; Join common code

DPMI_DBGSET_DR1:
	 mov	 dr1,eax	; Set the address

	 jmp	 short DPMI_DBGSET_COM ; Join common code

DPMI_DBGSET_DR2:
	 mov	 dr2,eax	; Set the address

	 jmp	 short DPMI_DBGSET_COM ; Join common code

DPMI_DBGSET_DR3:
	 mov	 dr3,eax	; Set the address
DPMI_DBGSET_COM:

; Set the debug control bits

	 mov	 eax,dr7	; Get current debug control register

; Set both of the global and local enable bits for this debug register

	 shl	 cl,1-0 	; Convert from bits to two bits
				; CL =	0 for DR0
				;    =	2     DR1
				;    =	4     DR2
				;    =	6     DR3

	 mov	 ebx,(mask $G0) or (mask $L0) ; Get bits for DR0
	 shl	 ebx,cl 	; Shift into position

; Set both of the global and local enable of exact data breakpoint match

	 or	 ebx,(mask $GE) or (mask $LE) ; Set both global and local bits
	 or	 eax,ebx	; Set the enable bits for this register
	 or	 DBGDR7,ebx	; ...

; Set the type and size fields for this register

	 shl	 cl,2-1 	; Convert from two bits to four bits
				; CL =	0 for DR0
				;    =	4     DR1
				;    =	8     DR2
				;    = 12     DR3

; Clear the current state of this debug register's control bits

	 mov	 ebx,(mask $RW0) or (mask $LEN0) ; Get bits for DR0
	 shl	 ebx,cl 	; Shift into position
	 not	 ebx		; Complement to clear
	 and	 eax,ebx	; Clear the control bits for this register
	 and	 DBGDR7,ebx	; ...

COMMENT|

Convert the caller's type and size values into DR7-compatible format

The valid combinations are

DH  DL	  Len-R/W
 0   1	   0000
 1   1	   0001
 1   2	   0101
 1   4	   1101
 2   1	   0011
 2   2	   0111
 2   4	   1111

|

	 dec	 dl		; Convert DL = (1,2,4) to (0,1,3)

	 cmp	 dh,2		; Convert DH = (0,1,2) to (0,1,3)
	 cmc			; CF = 1 if DH = 2, 0 otherwise
	 adc	 dh,0		; DH = 2 becomes 3

; Shift bits into position for DR7
				; 000000TT000000SS
	 shl	 dh,6		; TT000000000000SS
	 rol	 dx,2		; 000000000000SSTT

	 add	 cl,$RW0	; Shift to upper half of DR7
				; CL = 16 for DR0
				;    = 20     DR1
				;    = 24     DR2
				;    = 28     DR3

	 shl	 edx,cl 	; Shift to position in DR7 for
				; the corresponding debug register
	 or	 eax,edx	; Set the control bits for this register
	 or	 DBGDR7,edx	; ...

	 mov	 dr7,eax	; Set current debug control register

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_DBGSET endp		; End DPMI_DBGSET procedure
	 NPPROC  DPMI_DBGCLR -- DPMI 0.9 Function to Clear Debug Watchpoint
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to clear debug watchpoint

On entry (in INTXX_STR):

AX	 =	 0B01h
BX	 =	 watchpoint handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8023 if invalid handle

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 mov	 cx,[ebp].INTXX_EBX.ELO ; Get watchpoint handle

	 cmp	 cx,3		; Izit above maximum value?
	 ja	 near ptr INT31_ERR_INVVAL ; Jump if so

	 btr	 DBGCTL.ELO,cx	; Clear the control bit

; Clear both of the global and local enable bits for this debug register

	 shl	 cl,1-0 	; Convert from bits to two bits
				; CL =	0 for DR0
				;    =	2     DR1
				;    =	4     DR2
				;    =	6     DR3

	 mov	 eax,dr7	; Get current debug control register

	 mov	 ebx,(mask $G0) or (mask $L0) ; Get bits for DR0
	 shl	 ebx,cl 	; Shift into position
	 not	 ebx		; Complement to clear
	 and	 eax,ebx	; Clear the enable bits for this register
	 and	 DBGDR7,ebx	; ...

; Clear the type and size fields for this register

	 shl	 cl,2-1 	; Convert from two bits to four bits
				; CL =	0 for DR0
				;    =	4     DR1
				;    =	8     DR2
				;    = 12     DR3

	 mov	 ebx,(mask $RW0) or (mask $LEN0) ; Get bits for DR0
	 shl	 ebx,cl 	; Shift into position
	 not	 ebx		; Complement to clear
	 and	 eax,ebx	; Clear the control bits for this register
	 and	 DBGDR7,ebx	; ...

	 mov	 dr7,eax	; Set current debug control register

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_DBGCLR endp		; End DPMI_DBGCLR procedure
	 NPPROC  DPMI_DBGQRY -- DPMI 0.9 Function to Query Debug Watchpoint
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to query debug watchpoint

On entry (in INTXX_STR):

AX	 =	 0B02h
BX	 =	 watchpoint handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
AX	 =	 watchpoint status
		 Bit 0:  1 if watchpoint has been encountered
			 0 if not
		 Bits 1-15:  (reserved)

CF	 =	 1 if not successful
AX	 =	 8023 if invalid handle

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get watchpoint handle

	 cmp	 ax,3		; Izit above maximum value?
	 ja	 near ptr INT31_ERR_INVVAL ; Jump if so

	 bt	 DBGSTA.ELO,ax	; Query the status bit
	 setc	 al		; Set if encountered, clear if not
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Return in caller's AX (note AH=0)

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_DBGQRY endp		; End DPMI_DBGQRY procedure
	 NPPROC  DPMI_DBGRST -- DPMI 0.9 Function to Reset Debug Watchpoint
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to reset debug watchpoint

On entry (in INTXX_STR):

AX	 =	 0B03h
BX	 =	 watchpoint handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8023 if invalid handle

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get watchpoint handle

	 cmp	 ax,3		; Izit above maximum value?
	 ja	 near ptr INT31_ERR_INVVAL ; Jump if so

	 btr	 DBGSTA.ELO,ax	; Reset the status bit

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_DBGRST endp		; End DPMI_DBGRST procedure
	 FPPROC  DPMI_INT01 -- DPMI Single-Step Exception Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI single-step exception handler
called each time there's a single-step exception

On entry:

SS:EBP	 ==>	 INT01STK_STR

On exit:

EAX	 =	 error code

The error code for an INT 01h consists of

Bits 0-3:	 from DBGSTA
Bits 4-14:	 zero
Bits 15:	 $TF from EFL
Bits 16-31:	 zero

|

INT01STK_STR struc

INT01STK_EBP dd  ?		; Caller's EBP
INT01STK_ERR dd  ?		; Pseudo-error code
INT01STK_NXT db  (size INTCOM_STR) dup (?) ; The rest of the stack

INT01STK_STR ends

	 REGSAVE <ebx,ds>	; Save registers

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

; Get the state of the debug registers (why were we called?)

	 mov	 eax,dr6	; Get debug state register

; Isolate B0-3 bits

	 and	 al,DBGCTL	; Mask with registers we're interested in
	 jz	 short DPMI_INT01_EXIT ; Jump if none active

; Check each breakpoint

	 test	 al,mask $B0	; Izit BP #0 ?
	 jz	 short @F	; Jump if not

	 mov	 ebx,dr0	; Get the linear address

	 cmp	 ebx,DBGREGS[0*(type DBGREGS)] ; Izit our boy?
	 jne	 short @F	; Jump if not

	 or	 DBGSTA,@BIT0	; Mark as encountered
@@:
	 test	 al,mask $B1	; Izit BP #1 ?
	 jz	 short @F	; Jump if not

	 mov	 ebx,dr1	; Get the linear address

	 cmp	 ebx,DBGREGS[1*(type DBGREGS)] ; Izit our boy?
	 jne	 short @F	; Jump if not

	 or	 DBGSTA,@BIT1	; Mark as encountered
@@:
	 test	 al,mask $B2	; Izit BP #2 ?
	 jz	 short @F	; Jump if not

	 mov	 ebx,dr2	; Get the linear address

	 cmp	 ebx,DBGREGS[2*(type DBGREGS)] ; Izit our boy?
	 jne	 short @F	; Jump if not

	 or	 DBGSTA,@BIT2	; Mark as encountered
@@:
	 test	 al,mask $B3	; Izit BP #3 ?
	 jz	 short @F	; Jump if not

	 mov	 ebx,dr3	; Get the linear address

	 cmp	 ebx,DBGREGS[3*(type DBGREGS)] ; Izit our boy?
	 jne	 short @F	; Jump if not

	 or	 DBGSTA,@BIT3	; Mark as encountered
@@:
	 xor	 eax,eax	; A convenient zero
	 mov	 dr6,eax	; Clear for next time
DPMI_INT01_EXIT:
	 mov	 eax,[ebp].INT01STK_NXT.INTCOM_EFL ; Get caller's EFL
	 and	 eax,mask $TF	; Isolate TF
	 shl	 eax,15-$TF	; Shift to Bit 15
	 mov	 al,DBGSTA	; Get debug status byte

	 REGREST <ds,ebx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_INT01 endp 		; End DPMI_INT01 procedure
	 NPPROC  DPMI_TSRSRV -- DPMI 1.0 Function to Install RSP
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to install a Resident Service Provider

On entry (in INTXX_STR):

AX	=	0C00h
ES:eDI	=	selector:offset of 40-byte buffer in INST_RSP_STR.

On exit:

CF	=	0 success
CF	=	1 error
AX	=	8021 bad descriptor bits
	=	8025 bad linear addresses in descriptors
	=	8015 couldn't allocate callback

|

	 FIXICALL JGROUP:FDPMI_TSRSRV,DTE_CSJG ; Code resides in JGROUP
	 jnc	 near ptr INT31_CLC ; Jump if no error

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Set error return value

	 jmp	 INT31_ERR	; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_TSRSRV endp		; End DPMI_TSRSRV procedure
	 NPPROC  DPMI_TSRXIT -- DPMI 1.0 Function to Terminate and Stay Res
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to terminate and stay resident

On entry (in INTXX_STR):

AX	=	0C01h
BL	=	return code
DX	=	number of DOS paragraphs to keep (may be zero)

|

	 FIXIJMP JGROUP:FDPMI_TSRXIT,DTE_CSJG ; Code resides in JGROUP

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_TSRXIT endp		; End DPMI_TSRXIT procedure
	 NPPROC  DPMI_GETSHR -- DPMI 1.0 Function to Allocate Shared Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to allocate shared memory

On entry (in INTXX_STR):

AX	 =	 0D00h
ES:EDI	 =	 selector:offset of shared memory allocation req struct
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8012 no linear memory
		 8013 no physical memory
		 8014 no backing store
		 8016 handle unavailable
		 8021 name too long

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 FIXICALL JGROUP:FDPMI_GETSHR,DTE_CSJG ; Code resides in JGROUP
	 jnc	 near ptr INT31_CLC ; Jump if no error

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Set error return value

	 jmp	 INT31_ERR	; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETSHR endp		; End DPMI_GETSHR procedure
	 NPPROC  DPMI_RELSHR -- DPMI 1.0 Function to Release Shared Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to allocate shared memory

On entry (in INTXX_STR):

AX	 =	 0D01h
SI:DI	 =	 selector:offset of shared memory handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8023 bad handle

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 FIXICALL JGROUP:FDPMI_RELSHR,DTE_CSJG ; Code is in JGROUP
	 jnc	 near ptr INT31_CLC ; Jump if no error

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Set error return value

	 jmp	 INT31_ERR	; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_RELSHR endp		; End DPMI_RELSHR procedure
	 NPPROC  DPMI_SERIALIZE -- DPMI 1.0 Function to Serialize on Shared Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to serialize on shared memory

On entry (in INTXX_STR):

AX	 =	 0D02h
DX	 =	 option bits
		 bit 0	=0 suspend until available =1 just return
		 bit 1	=0 exclusive serialize =1 shared serialize
SI:DI	 =	 selector:offset of shared memory handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8004 deadlock
		 8005 serialization request cancelled by function 0D03h
		 8017 lock count exceeded
		 8018 exclusize serialize failed because block is already
		      under exclusive serialization
		 8019 exclusize serialize failed because block is already
		      under shared serialization
		 8023 bad handle

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 FIXICALL JGROUP:FDPMI_SERIALIZE,DTE_CSJG ; Code is in JGROUP
	 jnc	 near ptr INT31_CLC ; Jump if no error

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Set error return value

	 jmp	 INT31_ERR	; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_SERIALIZE endp		; End DPMI_SERIALIZE procedure
	 NPPROC  DPMI_RELSERIAL -- DPMI 1.0 Function to Release Serialization
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to:

1.  Release serialization of a shared memory block
2.  Cancel a pending serialization request

On entry (in INTXX_STR):

AX	 =	 0D03h
DX	 =	 option bits
		 bit 0	=0 release an exclusive serialization
			=1 release a shared serialization
		 bit 1	=0 release serialization
			=1 cancel a pending serialization request
SI:DI	 =	 selector:offset of shared memory handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8002 invalid state
		 8023 bad handle

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 FIXICALL JGROUP:FDPMI_RELSERIAL,DTE_CSJG ; Code is in JGROUP
	 jnc	 near ptr INT31_CLC ; Jump if no error

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Set error return value

	 jmp	 INT31_ERR	; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_RELSERIAL	endp		; End DPMI_RELSERIAL procedure
	 NPPROC  DPMI_EMUGET -- DPMI 1.0 Function to Get Coprocessor Status
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to get the coprocessor status

On entry (in INTXX_STR):

AX	 =	 0E00h
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
AX	 =	 flags:  Bit 0 = 1 iff MP bit from virtual CR0 is set
			 Bit 1 = 1 iff EM ...
			 Bit 2 = 1 iff MP bit from actual CR0 is set
			 Bit 3 = 1 iff EM ...
			 Bits 4-7:  coprocessor type
				    00 = no coprocessor
				    02 = 80287
				    03 = 80387
				    04 = 80486 DX or 80487 SX
				    05-0F = reserved
			 Bits 8-15:  N/A

CF	 =	 1 if not successful

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 xor	 bx,bx		; Initialize the result
	 smsw	 ax		; Get MSW with ET bit

	 test	 LCL_FLAG,@LCL_NDPIN ; Is NDP installed?
	 jz	 short DPMI_EMUGET1 ; Jump if not

	 mov	 bx,(mask $NDPEMU_MPr) or (02h shl $NDPEMU_TYP) ; Assume 287

	 test	 ax,mask $ET	; Izit 287 or 387?
	 jz	 short DPMI_EMUGET1 ; Jump if it's a 287

	 mov	 bx,(mask $NDPEMU_MPr) or (03h shl $NDPEMU_TYP) ; Assume 387

; Distinguish between 387 and 486 DX/487 SX and 586

	 cmp	 CPUTYPE,03h	; Izit some kind of 386?
	 je	 short DPMI_EMUGET1 ; Jump if so

	 mov	 bx,(mask $NDPEMU_MPr) or (04h shl $NDPEMU_TYP) ; Assume 486 DX/487 SX

	 cmp	 CPUTYPE,04h	; Izit some kind of 486?
	 je	 short DPMI_EMUGET1 ; Jump if so

	 mov	 bx,(mask $NDPEMU_MPr) or (05h shl $NDPEMU_TYP) ; Assume 586
DPMI_EMUGET1:

; Return the host's EM and MP bits

	 mov	 ax,MSW_PM	; Get MSW for PM operation

	 test	 ax,mask $EM	; Are we emulating today?
	 jz	 short @F	; Jump if not

	 or	 bx,mask $NDPEMU_EMr ; Tell 'em we are
@@:

; Return this client's EM and MP bits

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 ax,PGROUP:[edx].DPTSS_MSW ; Get this client's MSW

	 test	 ax,mask $EM	; Is the client emulating today?
	 jz	 short @F	; Jump if not

	 or	 bx,mask $NDPEMU_EMv ; Tell the caller it's emulating
@@:
	 test	 ax,mask $MP	; Has the client enabled NDP ops?
	 jz	 short @F	; Jump if not

	 or	 bx,mask $NDPEMU_MPv ; Tell the caller it's enabled
@@:
	 mov	 [ebp].INTXX_EAX.ELO,bx ; Return as caller's AX

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_EMUGET endp		; End DPMI_EMUGET procedure
	 NPPROC  DPMI_EMUSET -- DPMI 1.0 Function to Set Coprocessor Status
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 1.0 function to set the coprocessor status

On entry (in INTXX_STR):

AX	 =	 0E01h
BX	 =	 flags:  Bit 0 = new value for MP bit virtual CR0
			 Bit 1 = ...	       EM ...
			 Bits 2-15:  N/A
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8026 (client requested disabling coprocessor on a CPU
		       which doesn't support this) (huh??)

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 ax,PGROUP:[edx].DPTSS_MSW ; Get this client's MSW
	 and	 ax,not ((mask $EM) or (mask $MP)) ; Clear the EM and MP bits

	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get new values

	 test	 bx,mask $NDPEMU_MPv ; Check new value for MP
	 jz	 short @F	; Jump if it's clear

	 or	 ax,mask $MP	; Set it
@@:
	 test	 bx,mask $NDPEMU_EMv ; Check new value for EM
	 jz	 short @F	; Jump if it's clear

	 or	 ax,mask $EM	; Set it
@@:
	 mov	 PGROUP:[edx].DPTSS_MSW,ax ; Save as client's new MSW

; If the client took responsibility for emulation, we must put
; INT07DP into the IDT.  Otherwise, we put into effect the IDT07
; entry from the first TSS.

	 mov	 eax,INT07DP.EDQLO ; Get low-order dword
	 mov	 ebx,INT07DP.EDQHI ; ... high-...

	 test	 PGROUP:[edx].DPTSS_MSW,mask $EM ; Is the client emulating?
	 jnz	 short @F	; Jump if so

	 mov	 ecx,PVMTSS	; Get offset in PGROUP of the 1st TSS
	 mov	 eax,PGROUP:[ecx].DPTSS_IDT07.EDQLO ; Get low-order dword
	 mov	 ebx,PGROUP:[ecx].DPTSS_IDT07.EDQHI ; ... high-...
@@:
	 mov	 PGROUP:[edx].DPTSS_IDT07.EDQLO,eax ; Save for later use
	 mov	 PGROUP:[edx].DPTSS_IDT07.EDQHI,ebx ; ...

	 push	 PCURTSS	; Pass offset in PGROUP of the current TSS
	 call	 DPMIFN_LMSW	; Put MSW and INT 07h values into effect

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_EMUSET endp		; End DPMI_EMUSET procedure
	 NPPROC  DPMIFN_VMADDR -- Get VM Address for DPMI Calls
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get VM address for DPMI calls

On entry:

SS:EBP	 ==>	 INTXX_STR

In INTXX_STR,

BX:CX	 =	 starting linear address of memory to unlock
SI:DI	 =	 size of region to unlock in bytes

On exit:

EAX	 =	 starting linear address rounded down (/4KB)
EBX	 =	 size in pages (rounded up)

|

	 mov	 ax,[ebp].INTXX_EBX.ELO ; Get high-order word of starting LA
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get low-order word of starting LA

	 mov	 bx,[ebp].INTXX_ESI.ELO ; Get high-order word of size in bytes
	 shl	 ebx,16 	; Shift to high-order word
	 mov	 bx,[ebp].INTXX_EDI.ELO ; Get low-order word of size in bytes

	 add	 ebx,eax	; Add to get ending address

	 and	 eax,not (4*1024-1) ; Round starting address down to 4KB boundary

	 add	 ebx,4*1024-1	; Round ending address up to 4KB boundary
	 and	 ebx,not (4*1024-1) ; ...

	 sub	 ebx,eax	; Subtract to get length in bytes (/4KB)
	 shr	 ebx,12-0	; Convert from bytes to 4KB

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_VMADDR endp		; End DPMIFN_VMADDR procedure
	 NPPROC  DPMI_LOCKSEG -- DPMI 0.8 (Windows only) Lock/Unlock Segment
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.8 (Windows only) function to lock a segment. This procedure is also
called for function 5 (unlock segment).

On entry (in INTXX_STR):

AX	 =	 0004h (lock) / 0005h (unlock)
BX	 =	 selector of segment to lock/unlock
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

All other registers except EBP, FS, GS, and SS may be clobbered.

|
	 mov	 bx, [ebp].INTXX_EBX.ELO ; bx <- selector
	 push	 0		; Ignore modifiable check
	 push	 bx
	 call	 VALID_LSEL	; validate local selector
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if something went wrong

	 push	 bx		; Pass the selector
	 call	 GETLBASE	; Return with EAX = base address from LDT

	 lsl	 ebx,ebx	; Get the segment limit
	 jmp	 short $+2	; Fix for Errata # 14 & 20

	 inc	 ebx		; Convert from limit to length
	 add	 ebx, eax	; ebx <- end address
	 add	 ebx, @PageSize ; round up to page boundary
	 and	 ebx, not (@PageSize-1) ; finish round up
	 and	 eax, not (@PageSize-1) ; round base down to page boundary
	 sub	 ebx, eax	; ebx <- byte delta
	 shr	 ebx,12-0	; Convert from bytes to 4KB

	 push	 ds		; Save for a moment

	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 cmp	 [ebp].INTXX_EAX.ELO,@DPMI_LCKSEG ; Are we locking?
	 je	 short DPMI_SEGLOCK ; Jump if so

	 call	 VMM_UNLOCK

	 jmp	 short @F

DPMI_SEGLOCK:
	 call	 VMM_LOCK
@@:
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jnc	 near ptr INT31_CLC ; Jump if all went OK

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save error code

	 jmp	 INT31_ERR	; Join common error exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_LOCKSEG endp		; End DPMI_LOCKSEG procedure
	 align	 4		; Ensure dword alignment

ICODE	 ends			; End ICODE segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 extrn	 FDPMI_GETSHR:far
	 extrn	 FDPMI_RELSHR:far
	 extrn	 FDPMI_SERIALIZE:far
	 extrn	 FDPMI_RELSERIAL:far

	 extrn	 FDPMI_TSRSRV:far
	 extrn	 FDPMI_TSRXIT:far

JCODE	 ends			; End JCODE segment
endif				; IF @OEM_DPMI

	 MEND			; End QMAX_L31 module

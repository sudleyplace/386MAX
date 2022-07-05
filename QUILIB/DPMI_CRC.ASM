; $Header:   P:/PVCS/MAX/QUILIB/DPMI_CRC.ASV   1.1   30 May 1997 12:09:00   BOB  $
	 title	 DPMI_CRC -- Get BIOS CRC in Windows (or any DPMI 0.9 host)
	 page	 58,122
	 name	 DPMI_CRC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group ??????:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  dword-aligned, public, class 'data'

Link requirements:  None, standalone subroutine.

Program derived from:  VCPI_CRC, which was derived from INST_CRC

Original code by:  Henry Groover, December 1995

|

@DEBUG	 EQU	 0		; Turn off debug options

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include DEVDRV.INC
	 include 386.INC
	 include PTR.INC
	 include ALLMEM.INC

	 include DPMI.INC

	 include BIOSCONF.INC
.list


	 @NO_UNDERBAR	equ	1


;;;.data

;;;;;;	 include CPUID.INC
; CPUID equates for byte at F000:FFFE
; This code is taken from CPUID.INC - we can't include CPUID.INC, or
; we will conflict with RAMSCAN.ASM
.xcref @CPU_PC,@CPU_XT,@CPU_JR,@CPU_AT,@CPU_XT2,@CPU_M30,@CPU_CNV,@CPU_MCA
@CPU_PC  equ	 0FFh		; IBM PC
@CPU_XT  equ	 0FEh		; IBM PC XT
@CPU_JR  equ	 0FDh		; IBM PCjr
@CPU_AT  equ	 0FCh		; IBM PC AT & PS/2 Model 50/60
@CPU_XT2 equ	 0FBh		; IBM PC XT with 256/640 system board
@CPU_M30 equ	 0FAh		; IBM PS/2 Model 30
@CPU_CNV equ	 0F9h		; IBM PC Convertible
@CPU_MCA equ	 0F8h		; IBM PS/2 MCA or ISA 386

if (@Cpu and 1000b)		; If 80386 instructions
CPUID_SEG segment use16 at 0F000h ; Start CPUID_SEG segment
else
CPUID_SEG segment at 0F000h	; Start CPUID_SEG segment
endif				; IF (@Cpu AND 1000b)

	 org	 0FFFEh
BIOSCPUID db	 ?		; The CPU's identification byte
CHKSUM	 db	 ?		; Checksum

CPUID_SEG ends			; End CPUID_SEG segment

CGROUP	 group	 CPUID_SEG

DGROUP	 group	_DATA

_DATA	 segment use16 dword public 'data' ; Start _DATA segment
	 assume  ds:DGROUP

	 extrn	 _XORLIST:word
;;;	 extrn	 _BCRC:word

_BCRC	 dw	 0

	 public  La_BIOS,ALLMEM_SEL
La_BIOS  dd	 ?		; Linear address of BIOS
ALLMEM_SEL dw ? 	; All memory selector

_DATA	 ends			; End _DATA segment

DPMI_CRC_TEXT	 segment use16 byte public 'code' ; Start CODE segment
;;;.code
	 assume  cs:DPMI_CRC_TEXT

	 FPPROC  _DPMI_Is_MCA  -- Determine If Micro Channel
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

_far int DPMI_Is_MCA( void );

Determine whether or not machine is an MCA architecture.

On exit:

AX	 =	 1 if so
	 =	 0 if not
CF	 =	 1 if read config call failed

|

	 REGSAVE <bx,cx,es>	; Save registers

; Because some device drivers don't correctly take their corresponding
; adapters out of setup mode, we do that here for all adapters.  This
; code is also present in QMAX_SYS.ASM at CHECK_MODEL_XEISA.

	 mov	 cx, 8		; # of slots
	 mov	 bl,1		; Start with slot #1
@@:
	 mov	 ax,0C402h	; Major POS function, minor to enable adapter
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 jc	 short IsMCA_ReadCfg ; Jump if not Micro Channel

	 inc	 bl		; Skip to next slot

	 loop	 @B		; Jump if more slots to enable

IsMCA_ReadCfg:
	 mov	 ah,0C0h	; Attempt to read configuration record
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc  short IsMCA_ERR	; Jump if error

	 cmp	 ah,80h 	; Check for error return
	 je	 short IsMCA_ERR ; Jump if error

	 cmp	 ah,86h 	; Check for error return
	 je	 short IsMCA_ERR ; Jump if error

	 sub	 ax,ax		; Assume it's not MCA
	 test	 es:[bx].CFG_PARMS,@CFG_MCA ; Izit a Micro Channel Architecture?
	 jz	 short IsMCA_EXIT ; Join common exit code

	 inc	 ax		; Indicate true
	 jmp	 short IsMCA_EXIT ; Join common exit code

IsMCA_ERR:
	 sub	 ax,ax		; Clear AX
	 stc			; Indicate failure

IsMCA_EXIT:
	 REGREST <es,cx,bx>	; Restore registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_DPMI_Is_MCA endp		; End _DPMI_Is_MCA procedure

	 FPPROC  _DPMI_Is_IBM  -- Determine If Genuine IBM
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

_far int DPMI_Is_IBM( void );

Determine whether or not the machine is actually made by IBM.
All IBM machines either have BASIC at F600 (Int 18h vector segment)
or support the new int 15 fn 22 call to return BASIC segment.

On exit:

AX	 =	 1 if so
	 =	 0 if not

|

; Check for IBM system:  the technique we use is to see if the segment
; for INT 18h is F600 or not.  If this fails, it may be a newer IBM machine
; so we try Int 15 function 22 (Return BASIC segment in ES).  If the carry
; flag is not cleared, it's an IBM.

	 REGSAVE <bx,cx,dx,es>	; Save registers

	 mov	 ax,@DPMI_GETVMIV ; Get VM interrupt vector
	 mov	 bl,18h 	; Interrupt vector to get
	 int	 31h		; CX:DX = segment:offset

	 cmp	 cx,0F600h	; Izit F600?
	 je	 short IsIBM_True ; If so, it's an IBM machine

	 sub	 ax,ax		; Get a zero value
	 mov	 es,ax		; Clear ES
	 assume  es:nothing	; Tell the assembler
	 stc			; Assume failure
	 mov	 ah,22h 	; Function 22 (undocumented) return BASIC in ES
	 int	 15h		; Call BIOS
	 assume  es:nothing	; Tell the assembler
	 jc	 short IsIBM_False ; Not an IBM machine

	 mov	 ax,es		; Put ES in ax for comparison
	 or	 ax,ax		; Izit nonzero?
	 jnz	 short IsIBM_True ; Value OK; must be a Midway with Basic Lite

IsIBM_False:
	 sub	 ax,ax		; Not an IBM
	 jmp	 short IsIBM_EXIT ; Join common exit code

IsIBM_True:
	 mov	 ax,1		; It is an IBM

IsIBM_EXIT:
	 REGREST <es,dx,cx,bx>	; Restore registers
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_DPMI_Is_IBM endp		; End _DPMI_Is_IBM procedure

	 FPPROC  _DPMI_Is_BCF  -- Determine if system supports BCF
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

_far int DPMI_Is_BCF( void );

Determine whether the machine is capable of BIOS compression.  Not all
machines supporting BIOS compression are MCA; IBM L40 laptop is one example.
If the processor ID (penultimate byte of BIOS) is F8, indicating 386,
and it's an IBM system, (or if any MCA machine) it supports BIOS compression.

On exit:	AX = 1	if so
		AX = 0	if not

|

	 REGSAVE <es>		; Save register

; Get a selector that maps to the BIOS segment (F000)
	 mov	 ax,@DPMI_SEG2SEL ; Convert segment in BX to selector
	 mov	 bx,seg CPUID_SEG ; Real mode BIOS segment
	 int	 31h		; AX = selector
	 jc	 short Is_XBCF	; Jump if unable to get selector

	 mov	 es,ax		; Address it
	 assume  es:CPUID_SEG ; Tell the assembler about it

	 cmp	 BIOSCPUID,@CPU_MCA ; Izit an MCA or IBM 386?
	 je	 short @F	; IBM 386 machine (not necessarily MCA)
				; All IBM 386 systems have a 128K BIOS

	 cmp	 BIOSCPUID,@CPU_AT ; Izit (possibly) a Model 30/286?
	 jne	 short Is_XBCF	; Not a Model 30/286

	 mov	 ah,0C0h	; Attempt to read configuration record
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc  short Is_XBCF	; Jump if error

	 cmp	 ah,80h 	; Check for error return
	 je	 short Is_XBCF	; Jump if error

	 cmp	 ah,86h 	; Check for error return
	 je	 short Is_XBCF	; Jump if error

	 mov	 al,es:[bx].CFG_TYPE ; Get submodel ID
	 cmp	 al,09h 	; Izit a Model 30/286?
	 je	 short @F	; Jump if so

	 cmp	 al,19h 	; Izit a PS/2 model 40SLC?
	 je	 short @F	; Jump if so

	 cmp	 al,24h 	; Izit a PS/2 model 40SX?
	 jne	 short Is_XBCF	; Jump if not

@@:
	 call	 _DPMI_Is_IBM	; Check for BASIC in ROM
	 or	 ax,ax		; If AX=1, it's an IBM
	 jnz	 short Is_BCF_EXIT ; Return Is_IBM truth value in AX

Is_XBCF:
	 call	 _DPMI_Is_MCA	; If it's ANY microchannel system, it supports
				; BIOS compression; return with AX significant.

Is_BCF_EXIT:
	 REGREST <es>		; Restore register
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_DPMI_Is_BCF endp		; End _DPMI_Is_BCF procedure


	 FPPROC _DPMI_BCRC -- Get BIOS CRC Via DPMI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get BIOS CRC via a VCPI call.
_far unsigned long DPMI_BCRC( unsigned long dwPhysAddr, unsigned long dwLen );

On entry stack contains:

Starting physical address of BIOS
Length in bytes

On exit:

AX	 =	 16-bit CRC of BIOS

DX	 =	 0 if CRC is valid
	 =	 1 if not

|

dpmi_crc_str struc

	 dw	 ?		; Caller's BP
	 dd	 ?		; Caller's CS:IP
phys_addr dd	 ?		; Starting physical address
bios_len dd	 ?		; Length in bytes

dpmi_crc_str ends

	 push	 bp		; Prepare to address stack

	 mov	 bp,sp		; Address it

	 pushad 		; Save all EGP registers

	 push	 ds		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

; Make sure we're in protected mode (not V86 mode or real mode)
	 mov	 ax,@DPMI_CPUMODE ; Get CPU mode
	 int	 2fh		; AX=0 if PM
	 or	 ax,ax		; Are we in PM?
	 jnz	 near ptr GETBCRC_ERR ; Jump if not

; Get the physical address to start with.  Note that the 800h call
; is not supposed to work for addresses under 1MB, but Windows
; uses a magic number offset for physical addresses.  So we'll
; get an address for 1MB physical then subtract 1MB and use that
; as an offset...
	 mov	 ax,@DPMI_GETP2L ; Translate physical to linear
;;;	 mov	 bx,[bp].phys_addr.EHI ; High word of physical address
;;;	 mov	 cx,[bp].phys_addr.ELO ; Low word ...
;;;	 mov	 si,[bp].bios_len.EHI ; High word of length
;;;	 mov	 di,[bp].bios_len.ELO ; Low word ...
	 mov	 bx,0010h	; High word of 1MB
	 mov	 cx,0		; Low word ...
	 mov	 si,0001h	; High word of length
	 mov	 di,0		; Low word ...
	 int	 31h		; Returns BX:CX as linear address
	 jc	 near ptr GETBCRC_ERR ; Jump if call failed

; Subtract 1MB, then add BIOS offset back in
	 shl	 ebx,16-0	; Move BX into high word of EBX
	 mov	 bx,cx		; Get low word; EBX = linear address
	 sub	 ebx,100000h	; Back off 1MB
	 jc	 near ptr GETBCRC_ERR ; Jump if underflow occurred

	 add	 ebx,[bp].phys_addr ; Add back in BIOS offset
	 mov	 La_BIOS,ebx	; Save physical address of BIOS

; Now create an all-memory selector
	 mov	 ax,@DPMI_GETLDT ; Allocate an LDT descriptor
	 mov	 cx,1		; Number of descriptors to allocate
	 int	 31h		; AX = selector
	 jc	 near ptr GETBCRC_ERR ; Jump if failed

	 mov	 ALLMEM_SEL,ax ; Save it for later

	 sub	 dx,dx		; Zero low word of base address
	 mov	 cx,dx		; Zero high word ...
	 mov	 bx,ax		; Selector to set base for
	 mov	 ax,@DPMI_SSELBAS ; Set selector base
	 int	 31h		; CF=1 if failed
	 jc	 near ptr GETBCRC_AMERR ; Jump if failed

	 mov	 dx,-1		; Set low word of selector limit
	 mov	 cx,dx		; Set high word ...
	 mov	 bx,ALLMEM_SEL ; Selector to set limit for
	 mov	 ax,@DPMI_SSELLIM ; Set selector limit
	 int	 31h		; CF=1 if failed
	 jc	 near ptr GETBCRC_AMERR ; Jump if failed

; Now address the BIOS
	 mov	 ds,ALLMEM_SEL ; Address flat address space
	 assume  ds:AGROUP	; Tell the assembler

; Calculate CRC of BIOS at linear address La_BIOS

	 cld			; String ops forward

	 xor	 dx,dx		; Initialize accumulated CRC
	 mov	 ecx,[bp].bios_len ; # of bytes
	 mov	 esi,La_BIOS	; Get the Lin32 address of the BIOS
CALC_CRC_NEXT:
	 lods	 AGROUP:[esi].LO ; Get next byte

	 xor	 dl,al		; XOR into low-order byte of accumulated CRC

	 xor	 bh,bh		; Zero to use as word
	 mov	 bl,dl		; Copy to index register
	 shl	 bx,1-0 	; Convert from words to bytes

	 mov	 dl,dh		; Shift down one byte
	 xor	 dh,dh		; Zero for next time
	 xor	 dx,_XORLIST[bx] ; Compute polynomial residue

	 loopd	 short CALC_CRC_NEXT ; Jump if more

	 mov	 _BCRC,dx	; Save for later use

	 push	 es		; Get DGROUP selector
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 ax,@DPMI_RELLDT ; Free LDT descriptor
	 mov	 bx,ALLMEM_SEL ; Selector to free
	 int	 31h		; Free it (ignore result)

	 clc			; Indicate success

	 jmp	 short GETBCRC_EXIT ; Join common exit code

GETBCRC_AMERR:
	 mov	 ax,@DPMI_RELLDT ; Free LDT descriptor
	 mov	 bx,ALLMEM_SEL ; Selector to free
	 int	 31h		; Free it (ignore result)

GETBCRC_ERR:
	 stc			; Indicate not present
GETBCRC_EXIT:
	 popad			; Restore all EGP registers

	 pop	 bp		; Restore BP

	 mov	 ax,_BCRC	; Put return value in AX, even if invalid
	 sbb	 dx,dx		; DX=-1 if error
	 neg	 dx		; DX=1 if error

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

_DPMI_BCRC endp 		; End _DPMI_BCRC procedure

DPMI_CRC_TEXT	 ends		; End CODE segment

	 MEND			; End DPMI_CRC module

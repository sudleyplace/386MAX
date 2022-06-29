;' $Header:   P:/PVCS/MAX/QUILIB/VENDINFO.ASV   1.1   30 May 1997 12:09:08   BOB  $
	 title	 VENDINFO -- Subroutines to get vendor-related info
	 page	 58,122
	 name	 VENDINFO

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1985-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  byte-aligned, public, class 'data'

Link requirements:  Link with MSC 6.0 programs

Program derived from:  BIOSCRC.ASM

Original code by:  Henry Groover, July 1991

Modifications by:  Henry Groover, October 1991

|
.286p
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include PTR.INC
	 include DIR.INC
	 include FCB.INC
	 include DOSCALL.INC
	 include 386.INC
	 include BIOSCONF.INC
	 include EMMCALL.INC
	 include CMOS.INC
	 include 8255.INC
	 include INTVEC.INC
	 include OPEN.INC
	 include IOCTL.INC
.list

%.model  &MODEL,c

	 @NO_UNDERBAR	equ	0
	 @VENDINFO_OWNR equ	1
	 include VENDINFO.INC

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

	 .data

	 public  SUB_FLAG
SUB_FLAG dw	 0		; Local flags

	 .code

	 PPROC	 Is_VM	-- Determine If Virtual Mode
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Determine whether or not we're in Virtual Mode.

On exit:

AX	 =	 1 if so
	 =	 0 if not

|

; Test PUSH SP to detect 286 and 386
	 push	 sp		; Push SP
	 pop	 ax		; Pop SP at point of PUSH SP
	 cmp	 ax,sp		; Was it decremented before or after the push?
	 mov	 ax,0		; Assume not 286 or 386, and therefore not
				; in V86 mode
	 jne	 short IZITVM_EXIT ; Isn't a 286 or 386

	 smsw	 ax		; Get machine status word
	 and	 ax,mask $PE	; Isolate Protect Enable bit
	 jz	 short IZITVM_EXIT ; Jump if not active
				; Note AX != 0 for return if in V86 mode

	 or	 SUB_FLAG,@SUB_VM ; Mark as VM active

IZITVM_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

Is_VM	endp			; End _Is_VM procedure

	 PPROC	 Is_MCA  -- Determine If Micro Channel
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Determine whether or not machine is an MCA architecture.

On exit:

AX	 =	 1 if so
	 =	 0 if not
CF	 =	 1 if read config call failed

|

	 REGSAVE <bx,cx,es>	; Save registers

	 test	 SUB_FLAG,@SUB_MCA ; Did we already pass the test?
	 jz	 short @F	; If so, we need not do it again

	 mov	 ax,1
	 jmp	 short IsMCA_EXIT ; Join common exit code

@@:
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

Is_MCA	endp			; End _Is_MCA procedure

	 PPROC	 Is_IBM  -- Determine If Genuine IBM
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

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

	 mov	 ax,seg INTVEC	; Get segment of interrupt vector table
	 mov	 es,ax		; Address it
	 assume  es:INTVEC	; Tell the assembler about it

	 cmp	 INT00_VEC[18h*(type INT00_VEC)].VSEG,0F600h ; Izit F600?
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

Is_IBM	endp			; End _Is_IBM procedure

	 PPROC	 Is_BCF  -- Determine if system supports BCF
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Determine whether the machine is capable of BIOS compression.  Not all
machines supporting BIOS compression are MCA; IBM L40 laptop is one example.
If the processor ID (penultimate byte of BIOS) is F8, indicating 386,
and it's an IBM system, (or if any MCA machine) it supports BIOS compression.

On exit:	AX = 1	if so
		AX = 0	if not

|

	 REGSAVE <es>		; Save register

	 mov	 ax,seg CGROUP	; Get segment of CGROUP
	 mov	 es,ax		; Address it
	 assume  es:CGROUP	; Tell the assembler about it

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
	 call	 Is_IBM 	; Check for BASIC in ROM
	 or	 ax,ax		; If AX=1, it's an IBM
	 jnz	 short Is_BCF_EXIT ; Return Is_IBM truth value in AX

Is_XBCF:
	 call	 Is_MCA 	; If it's ANY microchannel system, it supports
				; BIOS compression; return with AX significant.

Is_BCF_EXIT:
	 REGREST <es>		; Restore register
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

Is_BCF	endp			; End _Is_BCF procedure

	 MEND			; End VENDINFO module

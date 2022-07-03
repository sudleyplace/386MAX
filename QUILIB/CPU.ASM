;' $Header:   P:/PVCS/MAX/QUILIB/CPU.ASV   1.2   30 May 1997 12:08:58   BOB  $
	 title	 CPU -- Display Information about CPU, FPU, VCPI, etc.
	 page	 58,122
	 name	 CPU

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Microsoft conventions using .MODEL, .CODE, and .DATA directives

Link requirements:  None.

Program derived from:  RAM.ASM, dated 07/20/90.

Original code by:  William R. Lewis, 1988.

Modifications by:  Alan C. Lindsay, 1990.

	19JUL90 WRL	Add tests for 80486
			Fix bug using 80186 style shift instructions
			Fix bug preventing display of memory over 8MB
			Update source code to new style

	10AUG90 ACL	Extracted CPU, FPU, and VCPI components
			from RAM.ASM and made a C callable function.
|

.8086	; Only 8088 style instructions are allowed until we know it's bigger
.8087
.xlist
	 include MASM.INC
	 include PTR.INC
	 include 386.INC
	 include ASCII.INC
	 include DOSCALL.INC
.386
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include CPUSIG.INC
	 include CPUFET.INC
.8086
	 include IOCTL.INC
	 include VCPI.INC
	 include CPUCODES.INC
.list

	 .MODEL LARGE,PASCAL	;..so anybody can call it

	.DATA

; *** WARNING *** Changes to these values must be synchronized with
;		  CPU.H.
	 public  CPU_TYPE,VIR_FLAG,FPU_TYPE,FPU_BUG,WEI_FLAG
	 public  VCPI_VER,WIN_VER,CPUID_SUP,CPUID_FEAT,CPUID_ID
	 public  CPUID_VID
CPU_TYPE dw	 0		; Processor type
VIR_FLAG dw	 0		; > 0 if CPU in virtual mode
FPU_TYPE dw	 0		; Co-processor type
FPU_BUG  dw	 0		; Flag for 387 bug
WEI_FLAG dw	 0		; > 0 if Weitek coprocessor
VCPI_VER dw	 0		; VCPI version number
WIN_VER  dw	 0		; Windows version number
CPUID_FEAT dd	 0		; CPUID feature bits
CPUID_ID dd	 0		; CPUID family, model, stepping
CPUID_VID dd 3 dup (0)		; 'GenuineIntel'
PARM_SIZE equ ($-CPU_TYPE)	; How much
; Ok, now you can mess with things.

CPUID_SUP db	 0		; Bit 0 set if CPUID supported, bit 1 if
				; feature bits indicate built-in FPU
EMM_NAME db	 'EMMXXXX0'
EMS_FLAG db	?		; 1 if EMS present, 0 otherwise

T87	 dw	 0		; Temp storage for 8087 testing

COSINE	 dq	 0.0
K	 dq	 5.4210108624275222e-20
S	 dw	 ?
SW	 dw	 ?


	 .CODE

.386
IZIT_CPUID proc 	; Determine Support of CPUID Instruction
COMMENT|

The test for the CPUID instruction is done by attempting to set the ID
bit in the high-order word of the extended flag dword.	If that's
successful, the CPUID instruction is supported; otherwise, it's not.

On exit:

CF	 =	 1 if it's supported
	 =	 0 otherwise

|

	 push	 bp		; Save to address the stack
	 clc			; Assume it's not supported
	 pushfd 		; Save original flags
	 pushfd 		; Save temporary flags

IZIT_CPUID_STR struc

IZIT_CPUID_TMPEFL dd ?		; Temporary EFL
IZIT_CPUID_RETEFL dd ?		; Return EFL
	 dw	 ?		; Caller's BP

IZIT_CPUID_STR ends

	 mov	 bp,sp		; Address the stack
	 or	 [bp].IZIT_CPUID_TMPEFL,mask $ID ; Set ID bit
	 popfd			; Put into effect

	 pushfd 		; Put back onto the stack to test

	 test	 [bp].IZIT_CPUID_TMPEFL,mask $ID ; Izit still set?
	 jz	 short @F	; No, so it's not supported

	 or	 [bp].IZIT_CPUID_RETEFL,mask $CF ; Indicate it's supported
@@:
	 popfd			; Restore temporary flags
	 popfd			; Restore original flags
	 pop	 bp		; Restore

	 ret			; Return to caller

IZIT_CPUID endp 		; End IZIT_CPUID procedure
.8086	; Only 8088 style instructions are allowed until we know it's bigger
CHECK_CPU proc	 parms:dword	; Pointer to parameter block

	 push	 di		; Boilerplate to make C happy
	 push	 si

; Test for EMS presence

	 mov	 EMS_FLAG,0	; Start by assuming it's not.

	 mov	 ah,35h 	; Get interrupt vector
	 mov	 al,67h 	; EMM
	 int	 21h
	 mov	 di,10
	 mov	 si,offset EMM_NAME
	 mov	 cx,8
	 repe cmpsb
	 jne	 short NOEMM

	 mov	 ah,40h 	; Get EMM status
	 int	 67h		; EMM
	 or	 ah,ah
	 jnz	 short NOEMM

	 mov	 EMS_FLAG,1	; Yes it is.
NOEMM:
; Determine processor type

; The different CPU types each react a certain way to a battery of tests

; The tests are:
; (1) PUSH SP	- Does the chip push the decremented SP
; (2) SHR AL,33 - Does the chip do a MOD 32 on the shift count?
; (3) Pre-fetch queue length (8088 and V20 vs. 8086 and V30
; (4) Double prefix interrupt performance.  8088 fails on REP CS:LODSB
; (5) IOP flag buts settable on 386
; (6) Alignment Check bit sticks in EFLAGS register
; (7) CPUID bit sticks in EFLAGS register


;	8088 8086 V20 V30 80188 80186 80286 80386 80486 Pentium
; (1)					X     X     X	  X
; (2)			    X	  X	X     X     X	  X
; (3)	      X 		  X
; (4)		   X   X    X	  X	X     X     X	  X
; (5)					      X     X	  X
; (6)						    X	  X
; (7)							  X

@PE	 equ	20h		; 8087 precision bit

; Test PUSH SP to detect 286 and 386
	 push	 sp
	 pop	 ax
	 cmp	 ax,sp
	MJ ne	 NO2OR3 		; Isn't a 286 or 386

.286p	; Now we know it's at least an 80286

; Executes like 286 or 386
	 mov	 dx,CPU_80286	; Assume 286
	 mov	 ax,7000h
	 push	 ax
	 popf
	 pushf
	 pop	 ax
	 and	 ah,70h 	; Priv bits won't stick in 286
	 jnz	 @F
	 jmp	 GOTPT		; It's a 80286 part
@@:
	 mov	 dx,CPU_80386	; It's a 80386 part

.386

; It's at least a 386.  Test for 486

	 push	 eax		; Save high word of EAX
	 pushfd 		; Save original EFLAGS during 486 test

	 movzx	 esp,sp 	; Ensure high-order word clear as we're
				; using it as an index register
	 pushfd 		; Save original EFLAGS
	 or	 [esp].EHI,mask $AC ; Set Alignment Check bit
	 popfd			; Put into effect

	 pushfd 		; Move flags into EAX
	 pop	 eax		; ...
	 popfd			; Restore original flags

	 test	 eax,(mask $AC) shl 16 ; Is AC bit still set?
	 pop	 eax		; Restore high word of EAX
	 jz	 near ptr V86_TEST ; No, so it's not a 486

	 mov	 dx,CPU_80486SX ; Indicate a 486SX

; It's at least a 486SX.  Test for Pentium CPU

; Now see if the CPU supports the CPUID instruction

	 call	 IZIT_CPUID	; Duzit support the CPUID instruction?
	 jnc	 near ptr V86_TEST ; Jump if not

	 REGSAVE <eax,ebx,ecx,edx> ; Save for a moment

	 sub	 eax,eax	; Get a convenient 0
	 mov	 CPUID_FEAT,eax ; Initialize flags

;;;;;;;  sub	 eax,eax	; Function code to check for Intel
	 CPUID			; Return with EBX,EDX,ECX = 'GenuineIntel'

	 mov	 CPUID_VID[0],ebx ; Save first dword of vendor ID
	 mov	 CPUID_VID[4],edx ; Save second ...
	 mov	 CPUID_VID[8],ecx ; Save final ...

	 cmp	 ebx,'uneG'     ; Does it compare?
	 jne	 short @F	; Jump if not

	 cmp	 edx,'Ieni'     ; Next dword?
	 jne	 short @F	; Jump if not

	 cmp	 ecx,'letn'     ; Last dword?
	 jne	 short @F	; Jump if not

	 bts	 CPUID_FEAT,$CPUFET_INTEL ; Mark as Intel part
@@:
	 mov	 eax,1		; Function code to retrieve feature bits
	 CPUID			; Return with EAX = stepping info
				;	      EBX, ECX reserved
				;	      EDX = feature bits

; Save feature bits and component ID

	 and	 edx,not @CPUFET_LOCAL ; Turn off local flags
	 or	 CPUID_FEAT,edx ; Save feature bits
	 mov	 CPUID_ID,eax	; Save stepping info

	 bt	 edx,$CPUFET_NDPIN ; Is there built-in floating point?
	 adc	 CPUID_SUP,@BIT0 ; Set bit 1 if so
	 or	 CPUID_SUP,@BIT0 ; CPUID supported

	 and	 eax,mask $CPUSIG_FAM ; Isolate the family field
	 shr	 eax,$CPUSIG_FAM ; Shift to low-order

	 cmp	 al,05h 	; Izit a Pentium or later?

	 REGREST <edx,ecx,ebx,eax> ; Restore

	 jb	 short V86_TEST ; Jump if not

	 mov	 dx,CPU_PENTIUM ; Indicate a Pentium CPU

	 je	 short V86_TEST ; Jump if precisely a Pentium

	 mov	 dx,CPU_PENTPRO ; Indicate Pentium Pro

; It's at least a 386.  Test for virtual 8086 mode

.386p
V86_TEST:
	 smsw	 ax		; Get low half of CR0
	 test	 al,1		; Examine PE bit
	 setnz	 VIR_FLAG.LO	; Set if we're in V86 mode
	 jnz	 short GOTPT	; Skip SX test if V86 mode

; Not in Virtual mode, so we can check for 386SX
NOT_VIR:
	 cmp	 dx,CPU_80386
	 jne	 GOTPT		; Not 386, skip the test

	 ; Test for 386 SX

	 call	 far ptr CHECK_CPUSX
	 jmp	 short GOTPT

.8086	; Disable 80186 and better instructions

; Test SHR AL,33 to detect 186 and 188
NO2OR3:
	 mov	 dx,CPU_80188	; Assume 80188 or 80186
	 mov	 ax,0FFFFh
	 mov	 cl,33
	 shl	 ax,cl
	 jnz	 short CHK16	; It is a 18X, test pre-fetch length

; Test double prefix operation for NEC V20 and V30
	 mov	 dx,CPU_V20	; Assume NEC V20
	 mov	 cx,0FFFFh
	 push	 ax
	 push	 si
	 sti			; Ensure timer int will occur
	 sub	 al,al		; Clear ZR flag
; Double prefix (REP) (CS:) will screw up on 8088, but not on V20
; REP prefix will be lost on 8088 part, so CX will not reach 0
	 rep lods cs:BYTE PTR [si]
	 pop	 si
	 pop	 ax
	 jcxz	 short CHK16	; CX is 0 if NEC part

; All processor tests have failed, part is 8088 or 8086
	 mov	 dx,CPU_8088

; Determine bus width of lesser parts
CHK16:
	 push	 es
	 mov	 ax,cs
	 mov	 es,ax
	 std			; Backwards
	 mov	 di,offset CS:ISW5
	 mov	 al,byte ptr CS:ISW4	; STI opcode
	 mov	 cx,3
	 cli
	 rep stosb
	 cld			; 1st byte of pre-fetch
	 nop
	 nop
	 nop
	 inc	 cx		; Overlaid by STI on 8-bit part
ISW4:	 sti
ISW5:	 sti
	 pop	 es
	 jcxz	 short GOTPT	; CX is 1 on 8-bit part
	 inc	 dx		; Advance to 16-bit version

; Processor type is in DX
GOTPT:
	 mov	 CPU_TYPE,dx	; Save processor type for co-processor

NDPFLAGS record  $R4:3,$IC:1,$RC:2,$PC:2,$IEM:1,$R5:1,$PM:1,$UM:1,$OM:1,$ZM:1,$DM:1,$IM:1

; ----------------------------------------------------------------------
;
; Do math coprocessor
	 mov	 FPU_TYPE,FPU_NONE ; Assume none
;
	 cmp	 CPUID_SUP,@BIT1 or @BIT0 ; CPUID supported and built-in FPU?
	 je	 short BUILT_IN ; Jump if so

	 fninit 		; Non-wait form
	 lea	 si,T87
	 mov	 WORD PTR [si],05A5Ah	; Unlikely value
	 fnstsw  [si]		; Non-wait form
	 cmp	 BYTE PTR [si],0
	 jne	 short NOCO	; Non-zero status means no 8087
	 fnstcw  [si]		; Get control word
	 mov	 ax,[si]
	 and	 ax,0103Fh
	 cmp	 ax,0003Fh	; Check that 1's and 0's were read
	 jne	 short NOCO	; No coprocessor installed

; Coprocessor exists, figure out which kind
;
;	But First, Check for emulation
;
.286p
	 smsw	 ax		; Get low half of CR0
.8086
	 test	 ax,4		; Test bit 2
	 jz	 NO_EMULATE	; Jump if not emulating
	 mov	 ax,FPU_EMULATED ; Flag as emulated
	 ; We can't test the emulator, because it
	 ; might choke on invalid instructions (like fcos).
	 jmp	 GOTCO
;
NO_EMULATE:

	 and	 word ptr [si],not mask $IEM ; Enable interrupts (IEM=0, 8087 only)
	 fldcw	 [si]		; Reload control word
	 fdisi			; Disable interrupts (IEM=1) on 8087,
				; ignored by 80287/80387
	 fstcw	 [si]		; Save control word

	 test	 word ptr [si],mask $IEM ; Check Interrupt Enable Mask (8087 only)
	 mov	 ax,FPU_8087	; Assume coprocessor type (8087)
	 jnz	 short GOTCO	; It changed, hence NDP is an 8087

	 fldpi			; Load PI
	 DB 0D9h, 0FFh		; Cosine (fcos)
	 fstsw	 [si]
	 mov	 ax,[si]
	 fstp	 COSINE
	 cmp	 word ptr COSINE+6,0BFF0h	; -1.0E0
;
	 mov	 ax,FPU_80287	; Assume 80287
	 jne	 short GOTCO	; 80287 if not equal, 80387 if equal
	 inc	 ax		; 80387

	 cmp	 CPU_TYPE,CPU_80386 ; Izit a 386?
	 je	 short GOTCO	; Jump if so

	 mov	 ax,FPU_80387SX ; Assume 80387SX
	 cmp	 CPU_TYPE,CPU_80386SX ; Izit a 386SX?
	 je	 short GOTCO	; Jump if so

; It's a 486 or higher, or supports CPU feature bits.
BUILT_IN:
	 mov	 ax,FPU_BUILTIN ; Flag as built-in FPU

; If CPU is a 486, it's a 486DX
	 cmp	 CPU_TYPE,CPU_80486SX ; Izit an SX?
	 jne	 short GOTCO	; Jump if not

	 mov	 CPU_TYPE,CPU_80486 ; Mark as 486DX
GOTCO:
	 mov	 FPU_TYPE,ax	; Remember coprocessor type
NOCO:
	 mov	 ax,FPU_TYPE	; Get coprocessor type

	 cmp	 ax,FPU_80387	; 80387 present?
	 je	 short @F	; Jump if so

	 cmp	 ax,FPU_80387SX ; Izit the SX part?
	 jne	 short NO_387	; No chip so it can't be bad

; Test for early mask 387 bug
@@:
	 fninit 		; Reset the coprocessor
	 fld	 K		; Load 2*-64
	 fist	 S		; Store as 16-bit integer
	 fstsw	 SW		; Get status
	 mov	 ax,SW		; ... into AX
	 and	 ax,@PE 	; Did it work?
	 mov	 FPU_BUG,0	; Assume no 387 bug
	 jnz	 short @F	; This chip appears to work - skip the message

	 mov	 FPU_BUG,1	; Flag 387 bug
@@:
NO_387:

	 mov	 VCPI_VER,0		; In case
	 mov	 WIN_VER,0		; In case

; Check for Weitek coprocessor
; Don't forget that it will only be found on a 386 and
;  it can co-exist with the 387
	cmp	 CPU_TYPE,CPU_80386 ; At least a 386?
	jb	 short NO_WEI2	; Nope
.386
	push	eax

	sub	eax,eax 	; Clear high order word
	int	11h		; Return bits in high word of EAX

	bt	eax,$BIT24	; Bit 24 = present, bit 23 = active
	setc	WEI_FLAG.LO	; Set Weitek flag if present

	pop	eax
.8086
NO_WEI2:
;
;  Windows 3.0 gets upset about testing for VCPI presence.  So, we
;  check to see if Windows is up, and don't do the call if it is.
;
	 mov	 ax,1600h
	 int	 2Fh			; DOS Multiplex interrupt
	 cmp	 al,0
	 jz	 NOT_WINDOWS		; Windows not running
	 test	 al,7fh
	 jz	 NOT_WINDOWS		; Windows not running
;
	 mov	 WIN_VER,200h
	 cmp	 al,-1
	 jz	 IN_WINDOWS		; Windows 2.x running
	 cmp	 al,1h
	 jz	 IN_WINDOWS		; Windows 2.x running
	 xchg	 ah,al
	 mov	 WIN_VER,ax
	 cmp	 ah,3
	 jge	 IN_WINDOWS		; Windows 2.x running
	 mov	 WIN_VER,0
;
;	Possible additional code:
;	mov	ax,1686h
;	int	2fh
;	ax == 0 then in standard mode (?)
;
NOT_WINDOWS:
; Test for presence of VCPI host

	 cmp	 CPU_TYPE,CPU_80386	; At least a 386?
	 jb	 short NO_VCPI		; Nope

	 cmp	 EMS_FLAG,1		; EMS present?
	 jne	 short NO_VCPI		; Nope

	 VCPICALL @VCPI_PRES		; Test for VCPI control program
	 or	 ah,ah			; VCPI error?
	 jnz	 short NO_VCPI		; Jump if not there

	 mov	 VCPI_VER,bx		; Save VCPI version
NO_VCPI:

; All done.
IN_WINDOWS:
	 les	 di,parms		; Get pointer to parameter block
	 lea	 si,CPU_TYPE		; First variable in block
	 mov	 cx,PARM_SIZE			; How much to move
	 rep	 movsb			; Do it.

	 pop	 si			; Restore things for C
	 pop	 di

	 ret				; Can I have a cookie now?

CHECK_CPU endp

;
;	Separate check for 386sx cpu
;
;  It is ASSUMED that this function will only be called if the cpu
;  is known to be 386.
;
CHECK_CPUSX proc
.386p

; Test for 386 SX

	 REGSAVE <eax,ebx>	; Save for a moment

	 mov	 eax,cr0	; Get control register #0
	 mov	 ebx,eax	; Save to restore later

	 and	 eax,not (mask $ET) ; ET=0 works on DX only
	 mov	 cr0,eax	; Tell the CPU about it
	 mov	 eax,cr0	; Read it back in
	 mov	 cr0,ebx	; Restore original value

	 mov	 dx,CPU_80386	; Prep for neg return
	 test	 eax,mask $ET	; Izit sticky?
	 jz	 @F		; Jump if not
	 mov	 dx,CPU_80386SX ; Mark as 386 SX
@@:
	 REGREST <ebx,eax>	; Restore

	 mov	 ax,dx		; Return result in both AX and DX
	 ret
.8086

CHECK_CPUSX endp

	 end

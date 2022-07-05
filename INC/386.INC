;' $Header:   P:/PVCS/MAX/INC/386.INV   1.2   31 Jan 1996 12:12:46   BOB  $
;
; (C) Copyright 1987-96 Qualitas, Inc.	GNU General Public License version 3.
;
; 386.INC
;
; 386-specific macros, equates, records, and structures
;

	 include DTE.INC

; DR6 bits

if (@Cpu and 1000b)		; If 80386 instructions
.xcref DR6BITS,$DR6RSV1,$BT,$BS,$BD,$DR6RSV2,$B3,$B2,$B1,$B0
DR6BITS  record  $DR6RSV1:16,$BT:1,$BS:1,$BD:1,$DR6RSV2:9,$B3:1,$B2:1,$B1:1,$B0:1
else
.xcref DR6BITS	       ,$BT,$BS,$BD,$DR6RSV2,$B3,$B2,$B1,$B0
DR6BITS  record 	     $BT:1,$BS:1,$BD:1,$DR6RSV2:9,$B3:1,$B2:1,$B1:1,$B0:1
endif				; IF (@Cpu AND 1000b)

; DR7 bits

if (@Cpu and 1000b)		; If 80386 instructions
.xcref DR7BITS,$LEN3,$RW3,$LEN2,$RW2,$LEN1,$RW1,$LEN0,$RW0
.xcref	       $DR7RSV1,$GD,$DR7RSV2,$GE,$LE,$G3,$L3,$G2,$L2,$G1,$L1,$G0,$L0
DR7BITS  record  $LEN3:2,$RW3:2,$LEN2:2,$RW2:2,$LEN1:2,$RW1:2,$LEN0:2,$RW0:2,\
		 $DR7RSV1:2,$GD:1,$DR7RSV2:3,$GE:1,$LE:1,$G3:1,$L3:1,$G2:1,$L2:1,$G1:1,$L1:1,$G0:1,$L0:1
else
.xcref DR7BITS_HI,$LEN3,$RW3,$LEN2,$RW2,$LEN1,$RW1,$LEN0,$RW0
.xcref DR7BITS_LO,$DR7RSV1,$GD,$DR7RSV2,$GE,$LE,$G3,$L3,$G2,$L2,$G1,$L1,$G0,$L0
DR7BITS_HI record $LEN3:2,$RW3:2,$LEN2:2,$RW2:2,$LEN1:2,$RW1:2,$LEN0:2,$RW0:2
DR7BITS_LO record $DR7RSV1:2,$GD:1,$DR7RSV2:3,$GE:1,$LE:1,$G3:1,$L3:1,$G2:1,$L2:1,$G1:1,$L1:1,$G0:1,$L0:1
endif				; IF (@Cpu AND 1000b)

.xcref @DR_BYTE,@DR_WORD,@DR_DWORD
@DR_BYTE equ	 00b
@DR_WORD equ	 01b
@DR_DWORD equ	 11b

.xcref @DR_EX,@DR_WR,@DR_RW
@DR_EX	 equ	 00b
@DR_WR	 equ	 01b
@DR_RW	 equ	 11b


if (@Cpu and 1000b)		; If 80386 instructions
.xcref TR4BITS,$TR4_TAG,$TR4_WVAL,$TR4_LRU,$TR4_RVAL,$TR4_RSV
.xcref TR5BITS,$TR5_SSEL,$TR5_ESEL,$TR5_CTL
.xcref TR6BITS,$TR6_FRM,$TR6_V,$TR6_D,$TR6_DP,$TR6_U,$TR6_UP,$TR6_W,$TR6_WP,$TR6_RSV,$TR6_C
.xcref TR7BITS,$TR7_FRM,$TR7_RSV1,$TR7_HT,$TR7_REP,$TR7_RSV2
TR4BITS  record  $TR4_TAG:21, $TR4_WVAL:1, $TR4_LRU:3, $TR4_RVAL:4, $TR4_RSV:3
TR5BITS  record  $TR5_SSEL:7, $TR5_ESEL:2, $TR5_CTL:2
TR6BITS  record  $TR6_FRM:20,$TR6_V:1,$TR6_D:1,$TR6_DP:1,$TR6_U:1,$TR6_UP:1,$TR6_W:1,$TR6_WP:1,$TR6_RSV:4,$TR6_C:1
TR7BITS  record  $TR7_FRM:20,$TR7_RSV1:7,$TR7_HT:1,$TR7_REP:2,$TR7_RSV2:2
endif				; IF (@Cpu AND 1000b)

; Fault error code record

.xcref FAULTCODE,$FSEL,$FTI,$FIDT,$FEXT
FAULTCODE record $FSEL:13,$FTI:1,$FIDT:1,$FEXT:1

; Page Fault error code

.xcref PFCODE,$PF_RSV,$PF_US,$PF_RW,$PF_P
PFCODE	 record  $PF_RSV:1,$PF_US:1,$PF_RW:1,$PF_P:1

; High-order 386/486 flags

.xcref FLAGS386,$_ID,$_VIP,$_VIF,$AC,$VM,$RF
FLAGS386 record  $_ID:1,$_VIP:1,$_VIF:1,$AC:1,$VM:1,$RF:1


; CR0 flags

if (@Cpu and 1000b)		; If 80386 instructions
.xcref CR0FLAGS,$PG,$CD,$NW,$CR0RSV0,$AM,$CR0RSV1,$WP
.xcref $CR0RSV2,$NE,$ET,$TS,$EM,$MP,$PE
CR0FLAGS record  $PG:1,$CD:1,$NW:1,$CR0RSV0:10,$AM:1,$CR0RSV1:1,$WP:1,\
		 $CR0RSV2:10,$NE:1,$ET:1,$TS:1,$EM:1,$MP:1,$PE:1
else
.xcref CR0FLAGS_HI,$PG,$CD,$NW,$CR0RSV0,$AM,$CR0RSV1,$WP
.xcref CR0FLAGS_LO,$NE,$ET,$TS,$EM,$MP,$PE
CR0FLAGS_HI record $PG:1,$CD:1,$NW:1,$CR0RSV0:10,$AM:1,$CR0RSV1:1,$WP:1
CR0FLAGS_LO record $NE:1,$ET:1,$TS:1,$EM:1,$MP:1,$PE:1
PG	 equ	 80000000r
PG_PE	 equ	 80000001r
endif				; IF (@Cpu AND 1000b)


; CR3 flags

if (@Cpu and 1000b)		; If 80386 instructions
.xcref CR3FLAGS
CR3FLAGS record  $PCD:1,$PWT:1,$CR3_RSV:3
endif				; IF (@Cpu AND 1000b)


; CR4 flags

if (@Cpu and 1000b)		; If 80386 instructions
.xcref CR4FLAGS
CR4FLAGS record  $PCE:1,$PGE:1,$MCE:1,$PAE:1,$PSE:1,$DE:1,$TSD:1,$PVI:1,$VME:1
@PCE	equ	(mask $PCE)	; 0100:  Enable RDPMC for CPL>0
@PGE	equ	(mask $PGE)	; 0080:  PTE Global Extensions
@MCE	equ	(mask $MCE)	; 0040:  Machine Check Extensions
@PAE	equ	(mask $PAE)	; 0020:  Physical Address Extension
@PSE	equ	(mask $PSE)	; 0010:  Page Size Extension
@DE	equ	(mask $DE )	; 0008:  Debugging Extensions
@TSD	equ	(mask $TSD)	; 0004:  Time Stamp Disable
@PVI	equ	(mask $PVI)	; 0002:  Protected Virtual Interrupts
@VME	equ	(mask $VME)	; 0001:  Virtual Mode Extensions
endif				; IF (@Cpu AND 1000b)


; Linear address format

if (@Cpu and 1000b)		; If 80386 instructions
.xcref LAFMT_REC,$LA_DIR,$LA_PAGE,$LA_OFF
LAFMT_REC record $LA_DIR:10,$LA_PAGE:10,$LA_OFF:12
endif				; IF (@Cpu AND 1000b)


; Page Table Entry record

if (@Cpu and 1000b)		; If 80386 instructions
.xcref PTE_REC,$PTE_FRMHI,$PTE_FRM,$PTE_AV2,$PTE_AV1,$PTE_AV0,$PTE_G
.xcref	       $PTE_PS,$PTE_D,$PTE_A,$PTE_CD,$PTE_WT,$PTE_US,$PTE_RW,$PTE_P
PTE_REC  record  $PTE_FRMHI:16,$PTE_FRM:4,$PTE_AV2:1,$PTE_AV1:1,$PTE_AV0:1,$PTE_G:1,\
		 $PTE_PS:1,$PTE_D:1,$PTE_A:1,$PTE_CD:1,$PTE_WT:1,$PTE_US:1,$PTE_RW:1,$PTE_P:1
@PTE_FRM equ	 ((mask $PTE_FRMHI) or (mask $PTE_FRM))
else
.xcref PTE_REC,$PTE_FRM,$PTE_AV2,$PTE_AV1,$PTE_AV0,$PTE_G
.xcref	       $PTE_PS,$PTE_D,$PTE_A,$PTE_CD,$PTE_WT,$PTE_US,$PTE_RW,$PTE_P
PTE_REC  record  $PTE_FRM:4,$PTE_AV2:1,$PTE_AV1:1,$PTE_AV0:1,$PTE_G:1,\
		 $PTE_PS:1,$PTE_D:1,$PTE_A:1,$PTE_CD:1,$PTE_WT:1,$PTE_US:1,$PTE_RW:1,$PTE_P:1
endif				; IF (@Cpu AND 1000b)

; Combine User/Read-write/Present into one equate

.xcref @PTE_URP,@PTE_RP
@PTE_URP equ	 (mask $PTE_US) or (mask $PTE_RW) or (mask $PTE_P)

; Combine      Read-write/Present into one equate

@PTE_RP  equ			   (mask $PTE_RW) or (mask $PTE_P)

; 386 Task State Segment structure

.xcref TSS_STR,TSS_LINK,TSS_ESP0,TSS_SS0,TSS_ESP1,TSS_SS1,TSS_ESP2,TSS_SS2
.xcref TSS_CR3,TSS_EIP,TSS_EFL,TSS_EAX,TSS_ECX,TSS_EDX,TSS_EBX,TSS_ESP
.xcref TSS_EBP,TSS_ESI,TSS_EDI,TSS_ES,TSS_CS,TSS_SS,TSS_DS,TSS_FS,TSS_GS
.xcref TSS_LDT,TSS_DBG,TSS_IOMAP
TSS_STR  struc

TSS_LINK dw	 ?,0		; Back link to previous TSS (dynamic)

; The static information begins here

TSS_ESP0 dd	 ?		; ESP for PL0 stack
TSS_SS0  dw	 ?,0		; SS  for ...

TSS_ESP1 dd	 ?		; ESP for PL1 stack
TSS_SS1  dw	 ?,0		; SS  for ...

TSS_ESP2 dd	 ?		; ESP for PL2 stack
TSS_SS2  dw	 ?,0		; SS  for ...

TSS_CR3  dd	 ?		; CR3 (PDBR)

; The rest of the dynamic TSS information begins here

TSS_EIP  dd	 ?		; EIP
TSS_EFL  dd	 ?		; EFL
TSS_EAX  dd	 ?		; EAX
TSS_ECX  dd	 ?		; ECX
TSS_EDX  dd	 ?		; EDX
TSS_EBX  dd	 ?		; EBX
TSS_ESP  dd	 ?		; ESP
TSS_EBP  dd	 ?		; EBP
TSS_ESI  dd	 ?		; ESI
TSS_EDI  dd	 ?		; EDI
TSS_ES	 dw	 ?,0		; ES
TSS_CS	 dw	 ?,0		; CS
TSS_SS	 dw	 ?,0		; SS
TSS_DS	 dw	 ?,0		; DS
TSS_FS	 dw	 ?,0		; FS
TSS_GS	 dw	 ?,0		; GS
TSS_LDT  dw	 ?,0		; LDT
TSS_DBG  dw	 0		; Debug bit in low-order
TSS_IOMAP dw	 size TSS_STR	; I/O Map Base

TSS_STR  ends


; 286 Task State Segment structure

.xcref TSS2_STR,TSS2_LINK,TSS2_SP0,TSS2_SS0,TSS2_SP1,TSS2_SS1,TSS2_SP2,TSS2_SS2
.xcref TSS2_IP,TSS2_FL,TSS2_AX,TSS2_CX,TSS2_DX,TSS2_BX,TSS2_SP
.xcref TSS2_BP,TSS2_SI,TSS2_DI,TSS2_ES,TSS2_CS,TSS2_SS,TSS2_DS
.xcref TSS2_LDT
TSS2_STR struc

TSS2_LINK dw	 ?		; Back link to previous TSS (dynamic)

; The static information begins here

TSS2_SP0 dw	 ?		; SP for PL0 stack
TSS2_SS0 dw	 ?		; SS for ...

TSS2_SP1 dw	 ?		; SP for PL1 stack
TSS2_SS1 dw	 ?		; SS for ...

TSS2_SP2 dw	 ?		; SP for PL2 stack
TSS2_SS2 dw	 ?		; SS for ...

; The rest of the dynamic TSS information begins here

TSS2_IP  dw	 ?		; IP
TSS2_FL  dw	 ?		; FL
TSS2_AX  dw	 ?		; AX
TSS2_CX  dw	 ?		; CX
TSS2_DX  dw	 ?		; DX
TSS2_BX  dw	 ?		; BX
TSS2_SP  dw	 ?		; SP
TSS2_BP  dw	 ?		; BP
TSS2_SI  dw	 ?		; SI
TSS2_DI  dw	 ?		; DI
TSS2_ES  dw	 ?		; ES
TSS2_CS  dw	 ?		; CS
TSS2_SS  dw	 ?		; SS
TSS2_DS  dw	 ?		; DS
TSS2_LDT dw	 ?		; LDT

TSS2_STR ends


.xcref PUSHAD_STR,PUSHAD_EDI,PUSHAD_EDI,PUSHAD_ESI,PUSHAD_EBP
.xcref PUSHAD_ESP,PUSHAD_EBX,PUSHAD_EDX,PUSHAD_ECX,PUSHAD_EAX
PUSHAD_STR struc

PUSHAD_EDI dd	 ?
PUSHAD_ESI dd	 ?
PUSHAD_EBP dd	 ?
PUSHAD_ESP dd	 ?
PUSHAD_EBX dd	 ?
PUSHAD_EDX dd	 ?
PUSHAD_ECX dd	 ?
PUSHAD_EAX dd	 ?

PUSHAD_STR ends


.xcref LOADALL
LOADALL  macro

	 db	 0Fh,05h	; 16-bit LOADALL

	 endm			; LOADALL


.xcref LOADALLD
LOADALLD macro

	 db	 0Fh,07h	; 32-bit LOADALL

	 endm			; LOADALLD


.xcref S16
S16	 macro	 I,J,K,L,M,N,O,P

	 I J K L M N O P
if @WordSize eq 4
	 db	 67h		; Use Address Size Prefix
endif				; IF @WordSize EQ 4
	 nop			; Ensure same size NOP

	 endm			; S16


.xcref S32
S32	 macro	 I,J,K,L,M,N,O,P

	 I J K L M N O P
if @WordSize eq 2
	 db	 67h		; Use Address Size Prefix
endif				; IF @WordSize EQ 2
	 nop

	 endm			; S32


.xcref LOOPS
LOOPS	 macro	 I,J,K,L,M,N,O,P

if @WordSize eq 4
	 db	 67h		; ASP
endif				; IF @WordSize EQ 2
	 loop	 I J K L M N O P

	 endm			; LOOPS


.xcref LOOPSZ
LOOPSZ	 macro	 I,J,K,L,M,N,O,P

if @WordSize eq 4
	 db	 67h		; ASP
endif				; IF @WordSize EQ 2
	 loopz	 I J K L M N O P

	 endm			; LOOPSZ


.xcref LOOPSNZ
LOOPSNZ  macro	 I,J,K,L,M,N,O,P

if @WordSize eq 4
	 db	 67h		; ASP
endif				; IF @WordSize EQ 2
	 loopnz  I J K L M N O P

	 endm			; LOOPSNZ


if @Version LT 600
.xcref LOOPD
LOOPD	 macro	 I,J,K,L,M,N,O,P

if @WordSize eq 2
	 db	 67h		; ASP
endif				; IF @WordSize EQ 2
	 loop	 I J K L M N O P

	 endm			; LOOPD
endif				; IF @Version LT 600


if @Version LT 600
.xcref PUSHW
PUSHW	 macro	 NN

if @WordSize eq 4
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 4
	 push	 NN

	 endm			; PUSHW
endif				; IF @Version LT 600


if @Version LT 600
.xcref PUSHD
PUSHD	 macro	 NN

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 push	 NN

	 endm			; PUSHD
endif				; IF @Version LT 600


.xcref POPW
POPW	 macro	 NN

if @WordSize eq 4
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 4
	 pop	 NN

	 endm			; POPW


.xcref POPD
POPD	 macro	 NN

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 pop	 NN

	 endm			; POPD


.xcref RETFD
RETFD	 macro	 NN

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 retf	 NN

	 endm			; RETFD


.xcref RETFS
RETFS	 macro	 NN

if @WordSize eq 4
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 4
	 retf	 NN

	 endm			; RETFS


if @Version LT 600
.xcref RETD
RETD	 macro	 NN

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 retn	 NN

	 endm			; RETD
endif				; IF @Version LT 600


.xcref CALLD
CALLD	 macro	 NN

if @WordSize eq 2
	 push	 0		; High-order word of return address
endif				; IF @WordSize EQ 2
	 call	 near ptr NN

	 endm			; CALLD


.xcref FCALLD
FCALLD	 macro	 NN

	 PUSHD	 cs		; Push dword selector
	 CALLD	 NN

	 endm			; FCALLD


.xcref FINTD
FINTD	 macro	 NN

	 pushfd 		; Simulate 32-bit INT call
	 cli
	 FCALLD  NN

	 endm			; FINTD


.xcref FINT
FINT	 macro	 NN

	 pushf			; Simulate 16-bit INT call
	 cli
	 push	 cs		; Push word selector
	 call	 near ptr NN

	 endm			; FINT



if @Version LT 600
.xcref INVD
INVD	 macro

	 db	 0Fh,08h	; MASM doesn't support INVD as yet

	 endm			; INVD
endif				; IF @Version LT 600


if @Version LT 600
.xcref WBINVD
WBINVD	 macro

	 db	 0Fh,09h	; MASM doesn't support INVD as yet

	 endm			; WBINVD
endif				; IF @Version LT 600


if @Version LT 600
.xcref CPUID
CPUID	 macro

	 db	 0Fh,0A2h	; MASM doesn't support CPUID as yet

	 endm			; CPUID
endif				; IF @Version LT 600


.xcref RDTSC
RDTSC	 macro

	 db	 0Fh,031h	; MASM doesn't support RDTSC as yet

	 endm			; RDTSC


if @Version LT 600
.xcref RDMSR
RDMSR	 macro

	 db	 0Fh,032h	; MASM doesn't support RDMSR as yet

	 endm			; RDMSR
endif				; IF @Version LT 600


if @Version LT 600
.xcref WRMSR
WRMSR	 macro

	 db	 0Fh,030h	; MASM doesn't support WRMSR as yet

	 endm			; WRMSR
endif				; IF @Version LT 600


.xcref RDPMC
RDPMC	macro

	db	0Fh,033h	; MASM doesn't support RDPMC as yet

	endm			; RDPMC


.xcref SYSENTER
SYSENTER macro

	db	0Fh,034h	; MASM doesn't support SYSENTER as yet

	endm			; SYSENTER


.xcref SYSEXIT
SYSEXIT macro

	db	0Fh,035h	; MASM doesn't support SYSEXIT as yet

	endm			; SYSEXIT


.xcref CSOVR
CSOVR	 macro	 INSTR,ARGS

	 db	 2Eh		; CS:
	 INSTR	 ARGS

	 endm			; CSOVR


.xcref SGDTD
SGDTD	 macro	 I,J,K,L,M,N

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 sgdt	  I J K L M N

	 endm			; SGDTD


.xcref SIDTD
SIDTD	 macro	 I,J,K,L,M,N

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 sidt	  I J K L M N

	 endm			; SIDTD


.xcref LGDTD
LGDTD	 macro	 I,J,K,L,M,N

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 lgdt	  I J K L M N

	 endm			; LGDTD


.xcref LIDTD
LIDTD	 macro	 I,J,K,L,M,N

if @WordSize eq 2
	 db	 66h		; Use Operand Size Prefix
endif				; IF @WordSize EQ 2
	 lidt	  I J K L M N

	 endm			; LIDTD


VERREST  macro	 LIST		; Register restore macro with VERR

	 irp	 XX,<LIST>

	 VERRSUB
	 pop	 XX

	 endm			; IRP
	 endm			; VERREST


VERRSUB  macro
	 local	 L1,L2

	 verr	 [esp].ELO	; Izit valid?
	 jnz	 short L1	; Jump if not

; Alas, VERR passes not present readable selectors
; so we must check for that separately via LAR

	 push	 ax		; Save for a moment

	 lar	 ax,[esp].EHI	; Get A/R word

	 test	 ah,mask $DT_P	; Izit present?
	 pop	 ax		; Restore
	 jnz	 short L2	; Jump if so
L1:
	 mov	 [esp].ELO,0	; Zero it
L2:
	 endm			; VERRSUB

WAITINTR macro	 count
; Wait for count interrupts to occur (real mode only)

ifnb <count>
	 NTIMES  = count
else
	 NTIMES  = 1
endif

	 pushf			; Save IF

	 movzx	 esp,sp 	; Clear high word of ESP
	 sti			; Enable interrupts

	 REPT	 NTIMES
	 push	 0		; Clear top word of stack
	 add	 esp,2		; Strip from stack
@@:
	 cmp	 [esp-2].ELO,0	; Did it get clobbered?
	 je	 short @B	; Jump if not

	 endm

	 popf			; Restore

	 endm			; WAITINTR


WIN06	 macro

	 db	 0Fh,0FFh	; Signal Invalid Opcode

	 endm			; WIN06


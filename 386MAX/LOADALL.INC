;' $Header:   P:/PVCS/MAX/386MAX/LOADALL.INV   1.0   11 Aug 1995 10:56:06   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; LOADALL.INC
;
; 286 LOADALL and 386 LOADALL structures
;

LA16_STR struc			; 286 LOADALL structure

	 db	 6 dup (?)	; 800-805	None
LA16_MSW dw	 ?		; 806-807	MSW
	 db	 14 dup (?)	; 808-815	None
LA16_TR  dw	 ?		; 816-817	TR
LA16_FL  dw	 ?		; 818-819	FL
LA16_IP  dw	 ?		; 81A-81B	IP
LA16_LDT dw	 ?		; 81C-81D	LDT
LA16_DS  dw	 ?		; 81E-81F	DS
LA16_SS  dw	 ?		; 820-821	SS
LA16_CS  dw	 ?		; 822-823	CS
LA16_ES  dw	 ?		; 824-825	ES
LA16_DI  dw	 ?		; 826-827	DI
LA16_SI  dw	 ?		; 828-829	SI
LA16_BP  dw	 ?		; 82A-82B	BP
LA16_SP  dw	 ?		; 82C-82D	SP
LA16_BX  dw	 ?		; 82E-82F	BX
LA16_DX  dw	 ?		; 830-831	DX
LA16_CX  dw	 ?		; 832-833	CX
LA16_AX  dw	 ?		; 834-835	AX
LA16_ESC df	 ?		; 836-83B	ES cache
LA16_CSC df	 ?		; 83C-841	CS cache
LA16_SSC df	 ?		; 842-847	SS cache
LA16_DSC df	 ?		; 848-84D	DS cache
LA16_GDTR df	 ?		; 84E-853	GDTR
LA16_LDTC df	 ?		; 854-859	LDT cache
LA16_IDTR df	 ?		; 85A-85F	IDTR
LA16_TSSC df	 ?		; 860-865	TSS cache

LA16_STR ends



ARBL16_STR struc

ARBL16_BASE db	 3 dup (?)	; 24-bit Base
ARBL16_AR  db	 ?		; Access rights
ARBL16_LIM dw	 ?		; 16-bit Limit

ARBL16_STR ends



LA32_STR struc			; 386 LOADALL structure

LA32_CR0 dd	 ?		; 000-003	CR0
LA32_EFL dd	 ?		; 004-007	EFL
LA32_EIP dd	 ?		; 008-00B	EIP
LA32_EDI dd	 ?		; 00C-00F	EDI
LA32_ESI dd	 ?		; 010-013	ESI
LA32_EBP dd	 ?		; 014-017	EBP
LA32_ESP dd	 ?		; 018-01B	ESP
LA32_EBX dd	 ?		; 01C-01F	EBX
LA32_EDX dd	 ?		; 020-023	EDX
LA32_ECX dd	 ?		; 024-027	ECX
LA32_EAX dd	 ?		; 028-02B	EAX
LA32_DR6 dd	 ?		; 02C-02F	DR6
LA32_DR7 dd	 ?		; 030-033	DR7
LA32_TR  dw	 ?,?		; 034-037	TR
LA32_LDT dw	 ?,?		; 038-03B	LDT
LA32_GS  dw	 ?,?		; 03C-03F	GS
LA32_FS  dw	 ?,?		; 040-043	FS
LA32_DS  dw	 ?,?		; 044-047	DS
LA32_SS  dw	 ?,?		; 048-04B	SS
LA32_CS  dw	 ?,?		; 04C-04F	CS
LA32_ES  dw	 ?,?		; 050-053	ES
LA32_TSSC db	 12 dup (?)	; 054-05F	TSS:  AR, Base, Limit
LA32_IDTC db	 12 dup (?)	; 060-06B	IDT:  AR, Base, Limit
LA32_GDTC db	 12 dup (?)	; 06C-077	GDT:  AR, Base, Limit
LA32_LDTC db	 12 dup (?)	; 078-083	LDT:  AR, Base, Limit
LA32_GSC db	 12 dup (?)	; 084-08F	GS:   AR, Base, Limit
LA32_FSC db	 12 dup (?)	; 090-09B	FS:   AR, Base, Limit
LA32_DSC db	 12 dup (?)	; 09C-0A7	DS:   AR, Base, Limit
LA32_SSC db	 12 dup (?)	; 0A8-0B3	SS:   AR, Base, Limit
LA32_CSC db	 12 dup (?)	; 0B4-0BF	CS:   AR, Base, Limit
LA32_ESC db	 12 dup (?)	; 0C0-0CB	ES:   AR, Base, Limit

LA32_STR ends



ARBL32_STR struc

ARBL32_AR  dd	 ?		; Access rights
ARBL32_BASE dd	 ?		; 32-bit Base
ARBL32_LIM dd	 ?		; 32-bit Limit

ARBL32_STR ends


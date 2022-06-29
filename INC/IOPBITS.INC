;' $Header:   P:/PVCS/MAX/INC/IOPBITS.INV   1.0   05 Sep 1995 13:26:54   HENRY  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	All rights reserved.
;
; IOPBITS.INC
;
; Instruction opcode bits in MOD REG R/M and SIB formats
;

.xcref MODRM_REC,SIB_REC
MODRM_REC record $MOD:2,$REG:3,$RM:3
SIB_REC  record  $SS:2,$IND:3,$BASE:3

; $REG or $RM values when used for registers

.xcref @bx@si,@bx@di,@bp@si,@bp@di,@si,@di,@bx
@bx@si	 equ	 000b		; BX+SI
@bx@di	 equ	 001b		; BX+DI
@bp@si	 equ	 010b		; BP+SI
@bp@di	 equ	 011b		; BP+DI
@si	 equ	 100b		; SI
@di	 equ	 101b		; DI
@disp	 equ	 110b		; BP (must have at least disp8)
@bx	 equ	 111b		; BX

.xcref @BX@SI,@BX@DI,@BP@SI,@BP@DI,@SI,@DI,@BX
@BX@SI	 equ	 000b		; BX+SI
@BX@DI	 equ	 001b		; BX+DI
@BP@SI	 equ	 010b		; BP+SI
@BP@DI	 equ	 011b		; BP+DI
@SI	 equ	 100b		; SI
@DI	 equ	 101b		; DI
@DISP	 equ	 110b		; BP (must have at least disp8)
@BX	 equ	 111b		; BX

.xcref @eax,@ecx,@edx,@ebx,@esp,@ebp,@esi,@edi
@eax	 equ	 000b		; EAX
@ecx	 equ	 001b		; ECX
@edx	 equ	 010b		; EDX
@ebx	 equ	 011b		; EBX
@esp	 equ	 100b		; ESP
@ebp	 equ	 101b		; EBP
@esi	 equ	 110b		; ESI
@edi	 equ	 111b		; EDI

.xcref @EAX,@ECX,@EDX,@EBX,@ESP,@EBP,@ESI,@EDI
@EAX	 equ	 000b		; EAX
@ECX	 equ	 001b		; ECX
@EDX	 equ	 010b		; EDX
@EBX	 equ	 011b		; EBX
@ESP	 equ	 100b		; ESP
@EBP	 equ	 101b		; EBP
@ESI	 equ	 110b		; ESI
@EDI	 equ	 111b		; EDI


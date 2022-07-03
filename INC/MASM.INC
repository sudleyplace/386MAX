;' $Header:   P:/PVCS/MAX/INC/MASM.INV   1.0   05 Sep 1995 13:26:40   HENRY  $
;
; (C) Copyright 1987-94 Qualitas, Inc.	GNU General Public License version 3.
;
; MASM.INC
;
; MASM Macros
;

include  INTRNATL.INC		; Include language-specific EQUates

.xcref REGSAVE,REGREST,NPROC,NPPROC,FPROC,FPPROC,MEND,REPMOVSB,MJ,POPFF
.xcref		       PPROC,NPPROCE
.xcref FCALL,OLDINT,REPMOVSF,SMAX,SMIN,UMAX,UMIN
	 if1
REGSAVE  macro	 LIST		; Register save macro

	 irp	 XX,<LIST>
	 push	 XX
	 endm

	 endm			; REGSAVE


REGREST  macro	 LIST		; Register restore macro

	 irp	 XX,<LIST>
	 pop	 XX
	 endm

	 endm			; REGREST


NPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
@PROC	 proc	 near
	 endm			; NPROC


PPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
	 public  @PROC
@PROC	 proc
	 endm			; PPROC


NPPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
	 public  @PROC
@PROC	 proc	 near
	 endm			; NPPROC


NPPROCE  macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
	 even
	 public  @PROC
@PROC	 proc	 near
	 endm			; NPPROCE


FPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
@PROC	 proc	 far
	 endm			; FPROC


FPPROC	 macro	 @PROC,@T1,@T2,@T3,@T4,@T5,@T6,@T7,@T8,@T9,@T10
	 subttl  @PROC Procedure @T1 @T2 @T3 @T4 @T5 @T6 @T7 @T8 @T9 @T10
	 page
	 public  @PROC
@PROC	 proc	 far
	 endm			; FPPROC


MEND	 macro	 @START

	 if1
%OUT Pass 1 complete
	 else
%OUT Pass 2 complete
	 endif

	 end	 @START

	 endm			; MEND


REPMOVSB macro	 DIR
	 local	 L1,L2

	 pushf

	 ifb	 <DIR>
	 shr	 cx,1		; Move forwards
	 jnc	 L1

	 movsb
L1:
	 rep	 movsw

	 else
	 ifdif	 <DIR>,<STD>
%OUT Invalid REPMOVSB argument DIR.
	 else

	 dec	 si
	 dec	 di

	 shr	 cx,1		; Move backwards
	 jz	 L1
	 rep	 movsw
L1:
	 jnc	 L2

	 inc	 si
	 inc	 di
	 movsb
L2:
	 endif			; IFDIF
	 endif			; IFB
	 POPFF

	 endm			; REPMOVSB


REPMOVSF macro	 DIR
	 local	 L1,L2

	 ifb	 <DIR>
	 shr	 cx,1		; Move forwards
	 jnc	 L1

	 movsb
L1:
     rep movsw

	 else
	 ifdif	 <DIR>,<STD>
%OUT Invalid REPMOVSF argument DIR.
	 else

	 dec	 si
	 dec	 di

	 shr	 cx,1		; Move backwards
	 jz	 L1
     rep movsw
L1:
	 jnc	 L2

	 inc	 si
	 inc	 di
	 movsb
L2:
	 endif			; IFDIF
	 endif			; IFB

	 endm			; REPMOVSF


MJ	 macro	 CC,LAB,DEB	; Macro for long jumps
	 local	 L1

MJ_NOT	 =	 0

	 irpc	 X,<CC>
	 ifidn	 <X>,<n>
MJ_NOT	 =	 1
	 else
	 ifidn	 <X>,<N>
MJ_NOT	 =	 1
	 endif			; IFIDN
	 endif			; IFIDN
	 endm			; IRP

	 if	 MJ_NOT 	; If original jump is a NOT

	 irpc	 XX,<CC>
	 ife	 MJ_NOT
	 j&&XX	 short L1
	 else
MJ_NOT	 =	 MJ_NOT-1
	 endif			; IFE
	 endm			; IRP

	 else
	 jn&CC	 short L1
	 endif			; IF

	 ifnb	 <DEB>
	 int	 03h		;; Call debugger
	 endif			; IFNB

	 jmp	 LAB
L1:
	 endm			; MJ


SMIN	 macro	 A,B		; A <== signed minimum of A and B
	 local	 L1

	 cmp	 A,B
	 jle	 L1

	 mov	 A,B
L1:
	 endm			; SMIN


UMIN	 macro	 A,B		; A <== unsigned minimum of A and B
	 local	 L1

	 cmp	 A,B
	 jbe	 L1

	 mov	 A,B
L1:
	 endm			; UMIN


SMAX	 macro	 A,B		; A <== signed maximum of A and B
	 local	 L1

	 cmp	 A,B
	 jge	 L1

	 mov	 A,B
L1:
	 endm			; SMAX


UMAX	 macro	 A,B		; A <== unsigned maximum of A and B
	 local	 L1

	 cmp	 A,B
	 jae	 L1

	 mov	 A,B
L1:
	 endm			; UMAX


POPFF	 macro
	 local	 L1,L2

	 jmp	 short L2
L1:
	 iret
L2:
	 push	 cs
	 call	 L1

	 endm			; POPFF


OLDINT	 macro	 NN

	 pushf			;; Pass flags as in INT call
	 cli			;; Duplicate INT calling environment
	 call	 OLDINT&NN&_VEC ;; Call original interrupt handler

	 endm			;; OLDINT


FCALL	 macro	 NAME

	 push	 cs
	 call	 near ptr NAME

	 endm			; FCALL

.xcref DWALIGN
DWALIGN  macro	 OFF,BYT	; Align up to word boundary
	 local	 BYT2

ifnb <BYT>
BYT2	 equ	 BYT
else
BYT2	 equ	 0
endif

	 ALIGNCOM OFF,BYT2,2

	 endm			; DWALIGN

.xcref DDALIGN
DDALIGN  macro	 OFF,BYT	; Align up to dword boundary
	 local	 BYT2

ifnb <BYT>
BYT2	 equ	 BYT
else
BYT2	 equ	 0
endif

	 ALIGNCOM OFF,BYT2,4

	 endm			; DDALIGN

.xcref DPALIGN
DPALIGN  macro	 OFF,BYT	; Align up to para boundary
	 local	 BYT2

ifnb <BYT>
BYT2	 equ	 BYT
else
BYT2	 equ	 0
endif

	 ALIGNCOM OFF,BYT2,16

	 endm			; DPALIGN

.xcref ALIGNCOM
ALIGNCOM macro	 OFF,BYT,N	; Common alignment macro
	 local	 LBL,M

LBL	 label	 byte		; Anchor ourselves
M	 equ	 ((LBL-OFF-BYT) mod N) ; Compute difference modulo alignment
if M				; If non-zero 'cause MASM doesn't handle 0 dup
	 db	 (N-M) dup (90h) ; Spit out NOPs
endif				; IF
	 endm			; ALIGNCOM

DOT386SUB macro  CSEG,TYP

% CSEG	 ends
.386&TYP
% CSEG	 segment

	 endm			; DOT386SUB

DOT386	 macro	 TYP		; TYP is blank or p

% DOT386SUB @CurSeg,TYP

	 endm			; DOT386


LOG2	 macro	 NAM,VAL
	 local	 CNT,LVAL

;; Calculate log base 2 of VAL and store in NAM

NAM	 =	 -1		; Initialize count
LVAL	 =	 VAL

	 rept	 32		; Maximum # bits
if LVAL
NAM	 =	 NAM+1		; Count in another bit
LVAL	 =	 LVAL shr 1	; ...and shift it out
endif				; IF LVAL
	 endm			; RPT 32

	 endm			; LOG2


MTEST	 macro	 NAM,FLG
	 local	 LCL_FLG,INCBYTE

;; Convert a TEST by mask on a memory location to an
;; equivalent TEST by a narrower mask on a byte.

INCBYTE  =	 0
LCL_FLG  =	 FLG

	 rept	 4
ife (0FFh and LCL_FLG)

LCL_FLG  =	 LCL_FLG shr 8
INCBYTE  =	 INCBYTE+1

endif
	 endm			; REPT 4

	 test	 byte ptr NAM[INCBYTE],LCL_FLG

	 endm			; MTEST


	 endif			; IF1 ******************************



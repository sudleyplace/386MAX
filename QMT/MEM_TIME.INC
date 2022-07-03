;' $Header:   P:/PVCS/MAX/QMT/MEM_TIME.INV   1.0   05 Sep 1995 16:55:54   HENRY  $
;
; (C) Copyright 1988-93 Qualitas, Inc.	GNU General Public License version 3.
;
; MEM_TIME.INC
;
; Structures and equates for TIMETAB.
;

TT_STR	 struc

TT_LEN	 dd	 ?		; 00-03:  Length in bytes
TT_LBASE dd	 ?		; 04-07:  Linear base address
TT_PBASE dd	 ?		; 08-0B:  Physical base address
TT_FLAG  dw	 ?		; 0C-0D:  Flags (see @TT_xxx for equates)
TT_WIDTH dw	 ?		; 0E-0F:  Chip width (8, 16, or 32 bits)
;;;;;;;; dd	 ?		; 10-13:  Chip size (64, 256, 1024, 4096 Kb, etc.)
;;;;;;;; dd	 ?		; 14-17:  Block size (CHIP x WIDTH / 8) in bytes
;;;;;;;; dd	 ?		; 18-1B:  Next base address (scratch)
;;;;;;;; dd	 ?		; 1C-1F:  Remaining length in bytes (scratch)

TT_STR	 ends


; Equates for TIMETAB.TT_FLAG

@TT_L2P    equ	 8000h		; Linear memory needs translation to physical
@TT_UNALL  equ	 4000h		; Unallocated memory (don't test)
@TT_P2L    equ	 2000h		; Physical memory needs translation to linear
@TT_XMS    equ	 1000h		; XMS-allocated memory
@TT_DPMI   equ	 0800h		; DPMI-allocated memory
@TT_P2LERR equ	 0400h		; DPMI P2L translation error
@TT_UNLCK  equ	 0200h		; Unlock the original linear base upon exit

@TIM_PAR   equ	 -1		; Flag for parity error


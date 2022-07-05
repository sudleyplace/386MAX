;' $Header:   P:/PVCS/MAX/386MAX/QMAX_IOP.ASV   1.3   30 May 1997 10:45:20   BOB  $
	 title	 QMAX_IOP -- 386MAX I/O Port Handler
	 page	 58,122
	 name	 QMAX_IOP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Program segment NCODE, byte-aligned,  public, class 'ncode'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Program segment JCODE,	dword-aligned, public, class 'jcode'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 6845.INC
	 include 8255.INC
	 include 8259.INC
	 include DMA.INC
	 include 386.INC
	 include PTR.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include ALLMEM.INC
	 include MASM5.MAC
	 include IOTRAP.INC

	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_TRC.INC
.list

PGROUP	 group	 CODE,ECODE,EDATA,NCODE,NDATA
FGROUP	 group	 FDATA
IGROUP	 group	 LCODE
JGROUP	 group	 JCODE


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

if @OEM_SOFT
	 extrn	 CLR_BITMAP:far
	 extrn	 SET_BITMAP:far
endif				; IF @OEM_SOFT

JCODE	 ends			; End JCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

	 extrn	 PORT15:word,PORT67:word

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 CM4_FLAG:word
	 include QMAX_CM4.INC

	 extrn	 SYSROM_START:word
if @OEM_EMS
	 extrn	 NBOARDS:word
	 extrn	 PORTPMR:word
	 extrn	 PORTPMRZ:word
endif				; IF @OEM_EMS
;;;;;;;; extrn	 DMA_ISTATE:byte
;;;;;;;; extrn	 DMA_USTATE:byte
if @OEM_DMA
	 extrn	 DMA_MODE:byte
	 extrn	 DMA_IADDR:byte
	 extrn	 DMA_CHAN:byte
if @OEM_VDS
	 extrn	 DMADISCNT:dword
endif				; IF @OEM_VDS
endif				; IF @OEM_DMA

	 extrn	 PIOBIT:dword
	 extrn	 PIOTRAP:dword
	 extrn	 IOTRAP_TYP:dword
	 extrn	 DESC_TAB:qword
	 extrn	 SEL_4GB3:word

	 public  @CHECKER_LEN
@CHECKER_LEN equ 4CEh+1 	; Length of CHECKER_IN and CHECKER_OUT tables

	 public  PCHECKER_INP,PCHECKER_OUT
PCHECKER_INP dd  ?		; PGROUP offset of input port check table
PCHECKER_OUT dd  ?		; ...		   output

	 public  CHECKER_LEN
CHECKER_LEN dw	 @CHECKER_LEN	; Length in words of PCHECKER_xxx tables

	 public  @IO_LIM,IO_LIM_MASK
@IO_LIM  equ	 0400h		; Limit of I/O channel ports
				; Note that the code below depends upon
				; this value being a power of two
IO_LIM_MASK dw	 @IO_LIM-1	; Assume ISA bus

	 public  REP_FAC
REP_FAC  dw	 01h		; Repeat factor on I/O port references

if @OEM_DMA
	 public  FLIPFLOP1,FLIPFLOP2
FLIPFLOP1 db	 0		; Flip-flop for DMA controller #1
FLIPFLOP2 db	 0		; ...			       #2
endif				; IF @OEM_DMA

	 public  LAST64
LAST64	 db	 00h		; Last command sent to I/O port 64h

if @OEM_DMA
	 public  DMA_MAP,DMA_REMAP
	 even
;		 81, 82, 83, 84, 85, 86, 87, 88, 89, 8A, 8B, 8C, 8D, 8E, 8F
DMA_MAP  db	  2,  3,  1,  8,  8,  8,  0,  8,  6,  7,  5,  8,  8,  8,  4
DMA_MAP_LEN equ  $-DMA_MAP
	 even
;		  0   1   2   3   4   5   6   7   8
DMA_REMAP db	 87h,83h,81h,82h,8Fh,8Bh,89h,8Ah, ?

	 public  DMA_PMR,DMA_PMR_HI,DMA_ACT
	 even
DMA_PMR  db	 DMA_MAP_LEN dup (0) ; Save area for DMA page mapping values
DMA_PMR_HI db	 DMA_MAP_LEN dup (0) ; Save area for EISA DMA high page mapping values
DMA_ACT  db	 DMA_MAP_LEN dup (0) ; Save area for DMA out values

	 public  DMA_ADDR,DMA_CNT,DMA_FLAG
	 include QMAX_DMA.INC
	 even
DMA_ADDR dw	 8 dup (?)	; DMA address value		Ch0-7
DMA_CNT  dd	 8 dup (0)	; DMA count value (raw) 	Ch0-7
DMA_FLAG db	 8 dup (0)	; DMA flags			Ch0-7
endif				; IF @OEM_DMA

if @OEM_SOFT
	 public  CURS_DATA
CURS_DATA db	 (2*4) dup (?)	; 00 = Cursor size start	Mono/Color
				; 01 = ...	   end
				; 02 = Cursor location high register
				; 03 = ...	       low

	 public  CRT_IND
CRT_IND  db	 ?		; CRT controller index (00-03)
endif				; IF @OEM_SOFT

EDATA	 ends			; End EDATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 public  IOWRAP
IOWRAP	 db	 11111000b	; I/O wrap terminating byte
				; to catch wraps at FFFF.
				; This value ignores I/O into
				; FFFF of word or dword length.

NDATA	 ends			; End NDATA segment


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
	 assume  cs:IGROUP

	 extrn	 EMU_INT15:near

	 align	 4		; Ensure dword alignment

LCODE	 ends			; End LCODE segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MSG_WOUT:byte
;;;;;;;; extrn	 MSG_DISD:byte
;;;;;;;; extrn	 MSG_8255:byte
	 extrn	 MSG_PULSE:byte
	 extrn	 MSG_286:byte
	 extrn	 MSG_XTA20:byte
;;;;;;;; extrn	 MSG_MFG:byte
	 extrn	 MSG_SELF:byte
	 extrn	 MSG_P92:byte

FDATA	 ends			; End FDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 public  @QMAX_IOP_NCODE
@QMAX_IOP_NCODE:		; Mark module start in .MAP file

	 NPPROC  SETIOPERM -- Set I/O Permission Bits
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set I/O permission bits in the I/O map.

|

	 REGSAVE <ax,ecx,edi>	; Save registers

; Fill the CHECKER_INP and CHECKER_OUT tables with their default values

	 lea	 ax,CHECK_XINP	; Get offset of default routine for input

	 mov	 edi,PCHECKER_INP ; ES:EDI ==> CHECKER_INP table
	 movzx	 ecx,cs:CHECKER_LEN ; Get # entries in table
     rep stos	 PGROUP:[edi].ELO ; Fill it with default entries

	 lea	 ax,CHECK_XOUT	; Get offset of default routine for output

	 mov	 edi,PCHECKER_OUT ; ES:EDI ==> CHECKER_OUT table
	 movzx	 ecx,cs:CHECKER_LEN ; Get # entries in table
     rep stos	 PGROUP:[edi].ELO ; Fill it with default entries

; If we're debugging I/O wrap at FFFF, fill in special entry

	 cmp	 cs:IOWRAP,0FFh ; Are we debugging it?
	 jne	 short @F	; Jump if not

	 movzx	 ecx,cs:CHECKER_LEN ; Get # entries in table
	 dec	 cx		; Back off to the last one

	 mov	 edi,PCHECKER_INP ; ES:EDI ==> CHECKER_INP table
	 mov	 PGROUP:[edi+ecx*2].ELO,offset PGROUP:CHECK_DBG

	 mov	 edi,PCHECKER_OUT ; ES:EDI ==> CHECKER_OUT table
	 mov	 PGROUP:[edi+ecx*2].ELO,offset PGROUP:CHECK_DBG
@@:
if @OEM_SOFT
	 mov	 edi,PCHECKER_INP ; ES:EDI ==> CHECKER_INP table
	 mov	 PGROUP:[edi+3B5h*2].ELO,offset cs:CHECK3B5INP
	 mov	 PGROUP:[edi+3D5h*2].ELO,offset cs:CHECK3B5INP

	 mov	 edi,PCHECKER_OUT ; ES:EDI ==> CHECKER_OUT table
	 mov	 PGROUP:[edi+3B4h*2].ELO,offset cs:CHECK3B4OUT
	 mov	 PGROUP:[edi+3D4h*2].ELO,offset cs:CHECK3B4OUT
	 mov	 PGROUP:[edi+3B5h*2].ELO,offset cs:CHECK3B5OUT
	 mov	 PGROUP:[edi+3D5h*2].ELO,offset cs:CHECK3B5OUT
endif				; IF @OEM_SOFT

	 test	 SYS_FLAG,@SYS_QUAD386 ; Izit a Quadram 386XT?
	 jz	 short SETIOPERM_NOQUAD ; Not this time

; Set the bit for port 1F8h (A20 gate/degate)

	 push	 offset cs:CHECK1F8OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X     ; Pass offset of input ...
	 push	 1		; Repeat factor
	 push	 1F8h		; Pass port address
	 call	 SETIOBIT	; Set I/O bits
SETIOPERM_NOQUAD:

; Set I/O port bits specific to XT

;;;;;;;; test	 LCL_FLAG,@LCL_XT ; Running on an XT?
;;;;;;;; jz	 short SETIOPERM_NOXT1 ; Not this time
;;;;;;;;
; Set the bit for port 63h (8255 command port)
;;;;;;;;
;;;;;;;; push	 offset cs:CHECK63OUT ; Pass offset of output checking routine
;;;;;;;; push	 offset cs:CHECK_X    ; Pass offset of input ...
;;;;;;;; push	 REP_FAC	; Repeat factor
;;;;;;;; push	 @8255_CMD	; Pass port address
;;;;;;;; call	 SETIOBIT	; Set I/O bits
SETIOPERM_NOXT1:

; Set I/O port bits specific to an MCA-compatible machine

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jz	 short SETIOPERM_NOMCA ; Not this time

; Set the bit for port 92h (System Control Port A)

	 push	 offset cs:CHECK92OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK92INP ; Pass offset of input ...
	 push	 1		; Repeat factor
	 push	 @PS2_A 	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

if @OEM_DMA
	 test	 CMD_FLAG,@CMD_XDM ; Doing DMA?
	 jnz	 short SETIOPERM_DMAZ1 ; Not this time

; Set the bit for port 8Fh (DMA Page Register Ch4)

	 push	 offset cs:CHECK89OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK89INP ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 8Fh		; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bit for port 18h (DMA Extended Function Register)

	 push	 offset cs:CHECK18OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 1		; Repeat factor
	 push	 @DMA3_CMD	; Pass port address
	 call	 SETIOBIT	; Set I/O bits
SETIOPERM_DMAZ1:
endif				; IF @OEM_DMA
SETIOPERM_NOMCA:

; Set I/O port bits specific to JET 386

	 test	 SYS_FLAG,@SYS_JET386 ; Izit a JET386?
	 jz	 short SETIOPERM_NOJET ; Not this time

	 push	 offset cs:CHECK310OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X     ; Pass offset of input ...
	 push	 1		; Repeat factor
	 push	 310h		; Pass port address
	 call	 SETIOBIT	; Set I/O bits
SETIOPERM_NOJET:

; Set I/O port bits specific to non-XT

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jnz	 near ptr SETIOPERM_XT ; Yes, skip all this

; Set the bit(s) for port 64h (8042 keyboard controller) if FORCEA20

	 test	 CM3_FLAG,@CM3_XA20 ; Request FORCEA20?
	 jz	 short SETIOPERM_UNSH1 ; No, don't intercept I/O port 64h

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jnz	 short SETIOPERM_UNSH1 ; Yes, skip this

	 push	 offset cs:CHECK64OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 @8042_ST	; Pass port address
	 call	 SETIOBIT	; Set I/O bits
SETIOPERM_UNSH1:
if @OEM_DMA
	 test	 CMD_FLAG,@CMD_XDM ; Doing DMA?
	 jnz	 near ptr SETIOPERM_DMAZ2 ; Not this time

; Set the bits for DMA page registers 5 - 7

	 mov	 cx,3		; We'll be trapping 3 ports
	 mov	 si,5		; Index into DMA_REMAP

SETIOPERM_DMA2_NEXT:
	 movzx	 ax,DMA_REMAP[si] ; Get next PMR value

	 push	 offset cs:CHECK89OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK89INP ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Izit EISA style DMA system?
	 jz	 short @F	; Jump if not

	 mov	 ah,4h		; High Page Segment = Low page segment + 400h

	 push	 offset cs:CHECK489OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK489INP ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits
@@:
	 inc	 si		; Next PMR port value

	 loop	 SETIOPERM_DMA2_NEXT ; Do for next I/O port

; Set the bits for port 0D0h (DMA controller #2 status)

;;;;;;;; push	 offset cs:CHECKD0OUT ; Pass offset of output checking routine
;;;;;;;; push	 offset cs:CHECKD0INP ; Pass offset of input ...
;;;;;;;; push	 REP_FAC	; Repeat factor
;;;;;;;; push	 @DMA2_STAT	; Pass port address
;;;;;;;; call	 SETIOBIT	; Set I/O bits

; Set the bits for port 0D4h (16-bit I/O single bit mask register)

	 push	 offset cs:CHECKD4OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 @DMA2_SBM	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bits for port 0D6h (16-bit I/O mode register)

	 push	 offset cs:CHECKD6OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 @DMA2_MODE	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bits for port 0DEh (16-bit I/O all bits mask register)

	 push	 offset cs:CHECKDEOUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 @DMA2_MBM	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

	 test	 CM2_FLAG,@CM2_SDMA ; Doing slow DMA?
	 jz	 short SETIOPERM_DMAZ2 ; Not this time

; Set the bit for the flip-flop port

	 push	 offset cs:CHECK0COUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 @DMA1_FLIP	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bits for ports 0C0h to 0CEh on even boundaries

	 mov	 ax,0C0h	; Get I/O port for first address register
	 mov	 cx,4		; # pairs of I/O ports
SETIOPERM_SDMA1:
	 push	 offset cs:CHECKC0OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits

	 add	 ax,2		; Skip to count register

	 push	 offset cs:CHECKC2OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Izit EISA style DMA system?
	 jz	 short @F	; Jump if not

	 mov	 ah,4h		; Convert 8237 segment to EISA High Word Segment
	 push	 offset cs:CHECK4C2OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits
	 xor	 ah,ah		; Restore 8237 Compatible Segment port address
@@:

	 add	 ax,2		; Skip to next address register

	 loop	 SETIOPERM_SDMA1 ; Jump if more I/O port pairs
SETIOPERM_DMAZ2:
endif				; IF @OEM_DMA
SETIOPERM_XT:

; Set the bit for PORT15 (resident INT 15h communications path)

	 push	 offset cs:CHECK_X ; Pass offset of checking routine (none)
	 push	 offset cs:CHECK_X ; Pass offset of checking routine (none)
	 push	 1		; Repeat factor
	 push	 PORT15 	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bit for PORT67 (resident INT 67h communications path)

	 push	 offset cs:CHECK_X ; Pass offset of checking routine (none)
	 push	 offset cs:CHECK_X ; Pass offset of checking routine (none)
	 push	 1		; Repeat factor
	 push	 PORT67 	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bit(s) for port 60h (6805 keyboard) if FORCEA20

	 test	 CM3_FLAG,@CM3_XA20 ; Request FORCEA20?
	 jz	 short SETIOPERM_UNSH2 ; No, don't intercept I/O port 60h

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jnz	 short SETIOPERM_UNSH2 ; Yes, skip this

	 push	 offset cs:CHECK60OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK60INP ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 @8255_A	; Pass port address
	 call	 SETIOBIT	; Set I/O bits
SETIOPERM_UNSH2:

if @OEM_DMA

; Set the bits for port 08h (DMA Controller #1 command port).
; Note that even if we're not remapping memory for DMA, we still
; must catch the case when DMA is disabled.

;;;;;;;; push	 offset cs:CHECK08OUT ; Pass offset of output checking routine
;;;;;;;; push	 offset cs:CHECK08INP ; Pass offset of input ...
;;;;;;;; push	 REP_FAC	; Repeat factor
;;;;;;;; push	 @DMA1_STAT	; Pass port address
;;;;;;;; call	 SETIOBIT	; Set I/O bits

	 test	 CMD_FLAG,@CMD_XDM ; Doing DMA?
	 jnz	 near ptr SETIOPERM_DMAZ3 ; Not this time

; Set the bits for port 0Ah (8-bit I/O single bit mask register)

	 push	 offset cs:CHECK0AOUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 @DMA1_SBM	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bits for port 0Bh (8-bit I/O mode register)

	 push	 offset cs:CHECK0BOUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 @DMA1_MODE	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bits for port 0Fh (8-bit I/O all bits mask register)

	 push	 offset cs:CHECK0FOUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 @DMA1_MBM	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bits for DMA page registers 0 - 3

	 mov	 cx,4		; We'll be trapping 4 ports
	 xor	 si,si		; Index into DMA_REMAP

SETIOPERM_DMA1_NEXT:
	 movzx	 ax,DMA_REMAP[si] ; Get next PMR value

	 push	 offset cs:CHECK81OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK81INP ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Izit EISA style DMA system?
	 jz	 short @F	; Jump if not

	 mov	 ah,4h		; High Page Segment = Low page segment + 400h

	 push	 offset cs:CHECK481OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK481INP ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits
@@:
	 inc	 si		; Next PMR port value

	 loop	 SETIOPERM_DMA1_NEXT ; Do for next I/O port

	 test	 CM2_FLAG,@CM2_SDMA ; Doing slow DMA?
	 jz	 short SETIOPERM_DMAZ3 ; Not this time

; Set the bit for the flip-flop port

	 push	 offset cs:CHECKD8OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 @DMA2_FLIP	; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bit for port 401 (EISA DMA channel 0 count register)

	 push	 offset cs:CHECK401OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 0401h		; Pass port address
	 call	 SETIOBIT	; Set I/O bits

; Set the bits for ports 02h to 07h

	 mov	 ax,02h 	; Get I/O port for first address register
	 mov	 cx,3		; # pairs of I/O ports
SETIOPERM_SDMA2:
	 push	 offset cs:CHECK00OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits

	 inc	 ax		; Skip to count register

	 push	 offset cs:CHECK01OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Izit EISA style DMA system?
	 jz	 short @F	; Jump if not

	 mov	 ah,4h		; Convert 8237 segment to EISA High Word Segment
	 push	 offset cs:CHECK401OUT ; Pass offset of output checking routine
	 push	 offset cs:CHECK_X    ; Pass offset of input ...
	 push	 REP_FAC	; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits
	 xor	 ah,ah		; Restore 8237 Compatible Segment port address
@@:

	 inc	 ax		; Skip to next address register

	 loop	 SETIOPERM_SDMA2 ; Jump if more I/O port pairs
SETIOPERM_DMAZ3:
endif				; IF @OEM_DMA

if @OEM_EMS

; Set I/O ports for EMM functions 10 and 11
; There are 4 I/O ports per 2MB of EMS memory

	 test	 CM4_FLAG,@CM4_EMS30 ; Supporting EMS 3.0?
	 jz	 short SETIOPERM_PMRZ ; No, don't intercept these ports

	 mov	 cx,NBOARDS	; Get # 2MB "boards" in EMS system in AL

	 shl	 cx,2		; Times four I/O ports per "board"
	 jz	 short SETIOPERM_PMRZ ; No EMS memory

	 mov	 ax,PORTPMR	; Get base I/O port for PMRs
SETIOPERM_PMR:
	 push	 offset cs:CHECK_X ; Pass offset of checking routine (none)
	 push	 offset cs:CHECK_X ; Pass offset of checking routine (none)
	 push	 1		; Repeat factor
	 push	 ax		; Pass port address
	 call	 SETIOBIT	; Set I/O bits

	 inc	 ax		; Skip to next I/O port

	 loop	 SETIOPERM_PMR	; Jump if more "boards" in EMS system
SETIOPERM_PMRZ:
endif				; IF @OEM_EMS

;		       ***NOTE***
; ***********************************************************
; If I/O ports higher than @CHECKER_LEN are trapped, be sure to
; increase @CHECKER_LEN.

	 REGREST <edi,ecx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETIOPERM endp			; End SETIOPERM procedure
	 NPPROC  SETIOBIT -- Set I/O Permission Bit
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

SETIO_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; Caller's return address
SETIO_PORT   dw  ?		; I/O port to set
SETIO_REP    dw  ?		; Repeat factor
SETIO_CHKINP dw  ?		; Offset of input checking routine
SETIO_CHKOUT dw  ?		; Offset of output ...

SETIO_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ax,ebx,cx,esi> ; Save registers

	 movzx	 esi,[ebp].SETIO_PORT ; Get the I/O port address

	 cmp	 si,0F000h	; In the PORTPMR, PORT15, and PORT67 range?
	 jae	 short SETIOBIT_CHK ; Yes, skip CHECKER_xx setting

;;;;;;;; and	 si,@IO_LIM-1	; Isolate low-order bits

	 mov	 ax,[ebp].SETIO_CHKINP ; Get input checking routine offset
	 mov	 ebx,PCHECKER_INP ; DS:EBX ==> CHECKER_INP table
	 mov	 PGROUP:[esi*2+ebx],ax ; Save offset of checking routine

	 mov	 ax,[ebp].SETIO_CHKOUT ; Get output ...
	 mov	 ebx,PCHECKER_OUT ; DS:EBX ==> CHECKER_OUT table
	 mov	 PGROUP:[esi*2+ebx],ax ; Save offset of checking routine
SETIOBIT_CHK:
;;;;;;;; mov	 cl,bl		; Copy low-order bits
;;;;;;;; shr	 bx,3		; Shift to byte index
;;;;;;;; and	 cl,111b	; Isolate bit index
;;;;;;;; mov	 al,1		; Set strobe bit
;;;;;;;; shl	 al,cl		; Move into position
	 mov	 ebx,PIOBIT	; Get offset in PGROUP of I/O bit map
	 mov	 cx,[ebp].SETIO_REP ; Repeat factor for loop
SETIOBIT_LOOP:
	 bts	 PGROUP:[ebx],esi ; Set the bit

	 add	 si,@IO_LIM	; Skip to next I/O port address

	 loop	 SETIOBIT_LOOP	; Jump if more to do

	 REGREST <esi,cx,ebx,ax> ; Restore

	 pop	 ebp		; Restore

	 ret	 4*2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETIOBIT endp			; End SETIOBIT procedure

NCODE	 ends			; End NCODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_IOP_ECODE
@QMAX_IOP_ECODE:		; Mark module start in .MAP file

if @OEM_DMA
	 extrn	 CHECK_PMR:near
endif				; IF @OEM_DMA
	 extrn	 INT0D_IRETD:near
	 extrn	 EMU_INT67:near
if @OEM_EMS
	 extrn	 EMU_PORTPMRI:near
	 extrn	 EMU_PORTPMRO:near
endif				; IF @OEM_EMS
	 extrn	 GOREAL_REBOOT:near
	 extrn	 WRAP_DISABLE:near
	 extrn	 WRAP_ENABLE:near
	 extrn	 DMA_COPYALL:near

	 extrn	 $$OSP:abs

	 NPPROCE CHECK_SYSROM -- Check for Caller in System ROM
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine whether or not caller is in system ROM.

On entry:

SS:EBP	 ==>	 Caller's INTXX_STR

On exit:

JAE	 =	 1 if in system ROM
	 =	 0 if not

|

	 push	 ax		; Save for a moment

	 mov	 ax,[ebp].INTXX_CS ; Get caller's segment

	 cmp	 ax,0FFFDh	; Check for XMS segments
	 jb	 short @F	; Jump if not

	 xor	 ax,ax		; Mark as not system ROM
@@:
	 cmp	 ax,SYSROM_START ; Izit in system ROM?

	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SYSROM endp		; End CHECK_SYSROM procedure
	 NPPROCE CHECKFNS -- Check Fns for System Reset
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check on system reset possibilities

If (DX == 08h) and (AL & 04h)
then  GOREAL_REBOOT  (the DMA Controller #1 is about to be disabled)

If (DX == 0D0h) and (AL & 04h)
then  GOREAL_REBOOT  (the DMA Controller #2 is about to be disabled)

If (DX == 63h) and (AL == 99h) and (caller in System ROM)
then  GOREAL_REBOOT  (the 8255 is being initialized)

If (DX == 60h) and (LAST64 == @S2C_WOUT) and ((AL & 11b) < 11b)
then  GOREAL_REBOOT  (we're about to reset the system)

If (DX == 64h) and (AL >= 0F0h) and ((AL & 11b) < 11b)
then  GOREAL_REBOOT  (we're about to reset the system)

If (DX == 64h) and (AL == 0AAh) and (caller in System ROM)
then  GOREAL_REBOOT  (we're about to reset the system)

If (DX == 80h) and (AL == 01h) and (caller in System ROM)
then  GOREAL_REBOOT  (we're initializing the system)

If (DX == 84h) and (AL == 00h) and (caller in System ROM)
then  GOREAL_REBOOT  (we're initializing the system)

If (DX == 310h) and (AL & 80h)
then  GOREAL_REBOOT  (we're about to shift to 286 mode)

On entry:

DX	 =	 I/O port #
BX	 =	 2 * (DX & I/O wrap)
AL	 =	 output value (also called for AX and EAX)
SS:EBP	 ==>	 Caller's INTXX_STR

On exit:

CF	 =	 1 if input and we supply the value (in AL/AX/EAX)
		   or output and we do the output

|

;;;;;;;; public  CHECK08INP
;;;CK08INP:
;;;;;;;; in	 al,@DMA1_STAT	 ; Get controller #1 status
;;;;;;;;
; Save in internal state variable bits
;;;;;;;;
;;;;;;;; mov	 bl,al		; Copy to save
;;;;;;;; and	 bl,@NIB0	; Isolate TC bits
;;;;;;;; or	 DMA_ISTATE,bl	; Save for later use
;;;;;;;;
; Include previous user state variable bits
;;;;;;;;
;;;;;;;; mov	 bl,DMA_USTATE	; Get previous user state TC bits
;;;;;;;; and	 bl,@NIB0	; Isolate channels 0-3
;;;;;;;; or	 al,bl		; Include in final result
;;;;;;;;
;;;;;;;; and	 DMA_USTATE,not @NIB0 ; Clear for next time
;;;;;;;;
;;;;;;;; stc			; Indicate we're supplying the result in AL
;;;;;;;;
;;;;;;;; jmp	 CHECKFNS_EXIT	; Join common exit code
;;;;;;;;
;;;;;;;;
;;;;;;;; public  CHECKD0INP
;;;CKD0INP:
;;;;;;;; in	 al,@DMA2_STAT	; Get controller #2 status
;;;;;;;;
; Save in internal state variable bits
;;;;;;;;
;;;;;;;; mov	 bl,al		; Copy to save
;;;;;;;; shl	 bl,4		; Shift TC bits up to channels 4-7
;;;;;;;; or	 DMA_ISTATE,bl	; Save for later use
;;;;;;;;
; Include previous user state variable bits
;;;;;;;;
;;;;;;;; mov	 bl,DMA_USTATE	; Get previous user state TC bits
;;;;;;;; shr	 bl,4		; Shift down channels 4-7
;;;;;;;; or	 al,bl		; Include in final result
;;;;;;;;
;;;;;;;; and	 DMA_USTATE,not @NIB1 ; Clear for next time
;;;;;;;;
;;;;;;;; stc			; Indicate we're supplying the result in AL
;;;;;;;;
;;;;;;;; jmp	 CHECKFNS_EXIT	; Join common exit code


;;;;;;;; public  CHECK08OUT,CHECKD0OUT
;;;CK08OUT:
;;;CKD0OUT:
;;;;;;;; test	 al,@BIT2	; Disabling DMA?
;;;;;;;; jz	 short CHECKFNS_CLC0 ; No, join common exit code
;;;;;;;;
;;;;;;;; lea	 bx,FGROUP:MSG_DISD ; Reason code for disabling DMA
;;;;;;;;
;;;;;;;; jmp	 CHECKFNS_RESET ; Yes, exit VM86 mode


	 public  CHECK60OUT
CHECK60OUT:
	 test	 SYS_FLAG,@SYS_INBRDPC ; Running on an Inboard/PC?
	 jz	 short CHECKFNS_NOXT1 ; Not this time

	 test	 CM3_FLAG,@CM3_XA20 ; Controlling A20?
	 jnz	 near ptr CHECKFNS_A20 ; Yes

	 cmp	 al,0DDh	; Disabling A20?
	 lea	 bx,FGROUP:MSG_XTA20 ; Reason code for degating A20 on XT
	 je	 short CHECKFNS_RESET ; Yes, let's get out of here
CHECKFNS_NOXT1:
	 cmp	 LAST64,@S2C_WOUT ; Last 8042 command writing output port?
	 lea	 bx,FGROUP:MSG_WOUT ; Reason code for writing 8042 output port
	 je	 short CHECKFNS_TEST ; Yes
CHECKFNS_CLC0:
	 jmp	 CHECKFNS_CLC	; No, join common exit code


	 public  CHECK60INP
CHECK60INP:
	 cmp	 LAST64,@S2C_ROUT ; Last 8042 command reading output port?
	 jne	 short CHECKFNS_CLC0 ; Not this time

	 test	 CM3_FLAG,@CM3_XA20 ; Controlling A20?
	 jz	 short CHECKFNS_CLC0 ; Not this time

	 in	 al,@8255_A	; Get the current value
	 and	 al,not (mask $S2O_GATE) ; Assume it's disabled

	 test	 GLB_FLAG,@GLB_X1MB ; Check virtual A20 state
	 jz	 short CHECK60INP_EXIT ; Jump if it's disabled

	 or	 al,mask $S2O_GATE ; Mark as enabled
CHECK60INP_EXIT:
	 stc			; Indicate we're supplying the result in AL

	 jmp	 CHECKFNS_EXIT	; Join common exit code


;;;;;;;; public  CHECK63OUT
;;ECK63OUT:
;;;;;;;; cmp	 al,99h 	; Initializing 8255 on a PC or XT?
;;;;;;;; jne	 near ptr CHECKFNS_CLC ; No, join common exit code
;;;;;;;;
;;;;;;;; lea	 bx,FGROUP:MSG_8255 ; Reason code for initializing 8255
;;;;;;;;
;;;;;;;; jmp	 CHECKFNS_ROM	; See if caller is in system ROM


	 public  CHECK64OUT
CHECK64OUT:
	 mov	 LAST64,al	; Save for later use

	 lea	 bx,FGROUP:MSG_SELF ; Reason code for keyboard self-test in ROM

	 cmp	 al,@S2C_SELF	; Self test?
	 je	 short CHECKFNS_ROM ; Yes, exit if in system ROM

	 test	 SYS_FLAG,@SYS_HPRS ; Izit an HP Vectra RS?
	 jz	 short @F	; Not this time

	 lea	 bx,FGROUP:MSG_WOUT ; Reason code for writing 8042 output port

	 cmp	 al,@S2O_D20	; Izit an attempt to disable A20?
	 je	 short CHECKFNS_TEST ; Yes, check on our own status

	 cmp	 al,@S2O_E20	; Izit an attempt to enable A20?
	 je	 short CHECKFNS_TEST ; Yes, check on our own status
@@:
	 cmp	 al,@S2C_PULSE	; Pulsing output port bits?
	 jb	 short CHECKFNS_CLC ; No, join common exit code

	 lea	 bx,FGROUP:MSG_PULSE ; Reason code for pulsing 8042 output port

	 test	 al,mask $S2O_RESET ; Reset system?
	 jz	 short CHECKFNS_RESET ; Yes

	 jmp	 short CHECKFNS_CLC ; Join common code


	 public  CHECKFNS_TEST
CHECKFNS_TEST:
	 mov	 LAST64,0	; Clear last I/O port 64h command

	 test	 al,mask $S2O_RESET ; Reset system?
	 jz	 short CHECKFNS_RESET ; Yes

	 test	 CM3_FLAG,@CM3_XA20 ; Controlling A20?
	 jnz	 short CHECKFNS_A20 ; Yes

	 test	 al,mask $S2O_GATE ; Degate A20?
	 jnz	 short CHECKFNS_CLC ; No, join common exit code


	 public  CHECKFNS_RESET
CHECKFNS_RESET:
	 mov	 ax,[ebp].INTXX_OIPHI ; Get original EIP, high-order word
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_OIPLO ; Get original EIP, low-order word
	 mov	 [ebp].INTXX_EIP,eax ; Restore

	 jmp	 GOREAL_REBOOT	; Jump to code to enter real mode and reboot


	 public  CHECKFNS_A20
CHECKFNS_A20:
	 mov	 ah,mask $S2O_GATE ; Test this bit in AL
	 call	 CTRL_A20	; Check on controlling it

	 jmp	 short CHECKFNS_CLC ; Join common exit code


	 public  CHECK1F8OUT
CHECK1F8OUT:
	 test	 CM3_FLAG,@CM3_XA20 ; Controlling A20?
	 jnz	 short CHECK1F8_A20 ; Yes

	 test	 al,@BIT0	; Degating A20?
	 lea	 bx,FGROUP:MSG_XTA20 ; Reason code for degating A20 on XT
	 jz	 short CHECKFNS_RESET ; Yes

	 jmp	 short CHECKFNS_CLC ; No

CHECK1F8_A20:
	 mov	 ah,@BIT0	; Test this bit in AL
	 call	 CTRL_A20	; Check on controlling it

	 jmp	 short CHECKFNS_CLC ; No


	 public  CHECK310OUT
CHECK310OUT:
	 test	 al,@BIT7	; Shifting to 286 mode?
	 lea	 bx,FGROUP:MSG_286 ; Reason code for shifting to 286 mode
	 jnz	 short CHECKFNS_RESET ; Yes
	 jmp	 short CHECKFNS_CLC ; No

CHECKFNS_ROM:
	 call	 CHECK_SYSROM	; Is caller in system ROM?
	 jae	 short CHECKFNS_RESET ; Yes, exit VM86 mode
CHECKFNS_CLC:
	 clc			; Indicate all went well
CHECKFNS_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECKFNS endp			; End CHECKFNS procedure
	 NPPROCE CTRL_A20 -- Ensure A20 Controlled
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Ensure A20 is controlled.

On entry:

AL	 =	 output byte to A20 register (60h on AT, 01F8h on 386XT, etc.)
AH	 =	 bit to test and enable (1 = enable, 0 = disable)

|

	 test	 al,ah		; Check requested A20 state
	 jnz	 short CTRL_A20_ON ; Requested state is enabled

; A20 is being gated off, so we enable the 1MB wrap to prevent
; access to the memory in the wrap region

	 and	 GLB_FLAG,not @GLB_X1MB ; Enable the 1MB wrap
	 or	 al,ah		; Ensure actually gated on

; Re-map the first 64KB of memory above the 1MB limit back to first 64KB
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_ENABLE	; Enable the 1MB wrap

	 jmp	 short CTRL_A20_EXIT ; Join common exit code

; A20 is being gated ON, so we disable the 1MB wrap to provide
; access to the memory in the wrap region

CTRL_A20_ON:

; Re-map the first 64KB of memory above the 1MB limit into itself
; This also flushes the TLB if CF=0 on return

	 call	 WRAP_DISABLE	; Disable the 1MB wrap

	 or	 GLB_FLAG,@GLB_X1MB ; Disable the 1MB wrap
CTRL_A20_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CTRL_A20 endp			; End CTRL_A20 procedure
if @OEM_DMA
	 NPPROCE CHECK00OUT -- DMA #1 Address Register Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #1 Initial Address Register output

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 00h, 02h, 04h, or 06h

|

	 shr	 bx,1		; Shift to port index
				; Already in origin-0
	 add	 bl,FLIPFLOP1	; Plus flip-flop offset
	 xor	 FLIPFLOP1,1	; Flip it for next time, too

	 mov	 DMA_ADDR.LO[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK00OUT endp 		; End CHECK00OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROC  CHECK01OUT -- DMA #1 Count Register Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #1, initial count


On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 01h, 03h, 05h, or 07h

|

	 shr	 bx,1		; Shift to port index
	 dec	 bx		; Convert to origin-0 (00, 02, 04, 06)
	 shl	 bx,1		; BX = 00, 04, 08, 0C

	 add	 bl,FLIPFLOP1	; Plus flip-flop offset
	 xor	 FLIPFLOP1,1	; Flip it for next time, too

	 mov	 DMA_CNT.LO[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK01OUT endp 		; End CHECK01OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROC  CHECK401OUT -- EISA DMA #1 High Count Register Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #1, initial count
EISA High Word Count (bits 16-23)


On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 401h, 403h, 405h, or 407h

|

	 shr	 bx,1		; Shift to port index
	 dec	 bx		; Convert to origin-0 (400, 402, 404, 406)
	 sub	 bx,400h	; BX = 00, 02, 04, 06
	 shl	 bx,1		; BX = 00, 04, 08, 0C

	 add	 bl,FLIPFLOP1	; Plus flip-flop offset
	 xor	 FLIPFLOP1,1	; Flip it for next time, too

	 mov	 DMA_CNT.EHI.LO[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK401OUT endp		; End CHECK401OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK0AOUT -- DMA #1 Single Bit Mask Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #1 Single Bit Mask Register output

If (DX == 0Ah and !(AL & 100b))
then save address and count for channel AL & 11b.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)

|

	 movzx	 ebx,al 	; Copy to index register
	 and	 bl,mask $CH0A	; Isolate DMA channel #
;;;;;;;; shr	 bl,$CH0A	; Shift to low-order

	 test	 al,@BIT2	; Set or clear mask?
	 jz	 short BYTE_ADDRCNT ; Get address and count values for channel EBX

; Stop the DMA controller

	 out	 dx,al		; Send command to DMA SBM
	 jmp	 short $+2	; I/O delay

; Copy all of the remaining bytes of the data from
; DTE_DMA to DMA_PTR for channel BX, and clear that bit from DMA_CHAN

	 call	 DMA_COPYALL	; Copy it all
				; ES and FS clobbered
	 btr	 DMA_CHAN.ELO,bx ; Check the bit and clear it if set

	 stc			; Tell caller to skip the OUT

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK0AOUT endp 		; End CHECK0AOUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK0BOUT -- DMA Controller #1 Mode Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #1 Mode Register output

Save DMA mode and channel # for channel AL & 11b.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)

|

	 mov	 bx,ax		; Copy to index register (note AH = undefined)
	 and	 bx,mask $CH0B	; Isolate DMA channel #
	 shr	 bx,$CH0B	; Shift to low-order
	 mov	 DMA_MODE[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK0BOUT endp 		; End CHECK0BOUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK0COUT -- DMA Controller #1 Flip-flop Register Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #1 Flip-flop Register output

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 0C

|

	 mov	 FLIPFLOP1,0	; Clear the flip-flop

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK0COUT endp 		; End CHECK0COUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK0FOUT -- DMA Controller #1 All Bits Mask Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #1 All Bits Mask Register output

If (DX == 0Fh and !(AL & 1111b))
then save address and count for channel AL & 1111b.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)

|

	 movzx	 ebx,al 	; Copy to test
	 and	 bl,@BIT3 or @BIT2 or @BIT1 or @BIT0 ; Isolate bits
	 xor	 bl,@BIT3 or @BIT2 or @BIT1 or @BIT0 ; Complement for BSF

	 bsf	 bx,bx		; Get index of least significant bit
	 jz	 short CHECK0FOUT_CLC ; None, so ignore them

	 add	 bx,4		; Shift to channels 4-7

	 jmp	 BYTE_ADDRCNT	; Get address and count values for channel EBX

CHECK0FOUT_CLC:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK0FOUT endp 		; End CHECK0FOUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE BYTE_ADDRCNT -- Get Address and Count For Byte I/O
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get address and count byte I/O values for channel EBX

On entry:

EBX	 =	 DMA channel # (0, 1, 2, 3)

|

	 REGSAVE <ax,dx>	; Save registers

if @OEM_VDS
	 cmp	 DMADISCNT[ebx*4],0 ; Izit disabled?
	 jne	 short BYTE_ADDRCNT_EXIT ; Yes, skip all this
endif				; IF @OEM_VDS

	 test	 CM2_FLAG,@CM2_SDMA ; Doing slow DMA?
	 jnz	 short BYTE_ADDRCNT1 ; Yes, address and count registers set

; Disable the channel first

;;;	 mov	 al,bl		; Copy DMA channel #
;;;	 or	 al,@BIT2	; Set the disable bit
;;;	 out	 @DMA1_SBM,al	; Disable it
;;;	 jmp	 short $+2	; Drain the PIQ
;;;	 jmp	 short $+2	; Drain the PIQ
;;;	 jmp	 short $+2	; Drain the PIQ

; Get the 24-bit address from the controller

	 movzx	 dx,DMA_IADDR[bx] ; Get address I/O port
				; 0-00, 1-02, 2-04, 3-06

	 out	 @DMA1_FLIP,al	; Clear flip-flop register
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 in	 al,dx		; Get low-order of current address
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 ah,al		; Save for a moment

	 in	 al,dx		; Get high-order of current address
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 xchg	 al,ah		; Swap to save order
	 mov	 DMA_ADDR[ebx*2],ax ; Save for later use

; Get the 16-bit count from the controller

	 xor	 eax,eax	; Assume bits 16-23 are zero
	 inc	 dx		; Skip to count port

	 in	 al,dx		; Get count (bits 0-7)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 ah,al		; Save for a moment

	 in	 al,dx		; Get count (bits 8-15)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 xchg	 al,ah		; Swap to save order
	 mov	 DMA_CNT[ebx*(type DMA_CNT)],eax ; Save for later use

; Get the 8-bit EISA High Word Count segment count from the controller

	 xor	 al,al		; Assume bits 16-23 are zero

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Izit an EISA DMA system?
	 jz	 short @F	; Jump if not

	 mov	 dh,4h		; High Word Segment = Low Word Segment + 400h

	 in	 al,dx		; Get count (bits 16-23)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

; A count of 16MB is unlikely, and probably indicates a machine with a
; bug in the BIOS where the high byte of the count is not set.
	 cmp	 al,0ffh	; Izit valid?
	 cmc			; Set CF=1 if not
	 adc	 al,0		; Convert FF to 0
@@:
	 mov	 DMA_CNT[ebx*(type DMA_CNT)].EHI.LO,al ; Save count (bits 16-23)

BYTE_ADDRCNT1:
	 or	 DMA_FLAG[bx],@DMA_BYTE ; Mark as 8-bit transfer

	 call	 CHECK_PMR	; See if we need to adjust PMR values
				; Return with CF significant, but ignore
				; it for mask register
				; DS, ES, and FS may be changed
BYTE_ADDRCNT_EXIT:
	 clc			; Indicate caller should do OUT

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BYTE_ADDRCNT endp		; End BYTE_ADDRCNT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK18OUT -- MCA DMA Extended Function Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

MCA DMA Extended Function Register output

This register is programmed with commands in the upper nibble
for the DMA channel # in the lower nibble.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)

|

; If this is command @DMA3_CLRBIT, read in the address and count values
; and check on PMR remapping

	 mov	 bl,al		; Copy to test
	 and	 bl,@NIB1	; Isolate command nibble

	 cmp	 bl,@DMA3_CLRBIT ; Izit a channel enable?
	 jne	 near ptr CHECK18OUT_CLC ; No

; EBX is the byte index register (doubles as DMA channel #)

	 movzx	 ebx,al 	; Copy to test, AH = undefined
	 and	 bl,@NIB0	; Isolate channel nibble
if @OEM_VDS
	 cmp	 DMADISCNT[ebx*4],0 ; Izit disabled?
	 jne	 near ptr CHECK18OUT_CLC ; Yes, skip all this
endif				; IF @OEM_VDS

	 REGSAVE <ax>		; Save register

; Read the mode register

	 mov	 al,bl		; Copy DMA channel #
	 or	 al,@DMA3_MODE	; Mode register read
	 out	 @DMA3_CMD,al	; Tell the DMA controller about it

	 in	 al,@DMA3_DATA	; Get mode register

; Convert the extended mode bits to the 8237-compatible form

COMMENT|

	 8237-compatible		Extended Mode
----------------------------------------------------------------------
Bit 0	 Channel #, low bit		0 = I/O address is 0000h
					1 = Use programmed I/O address
Bit 1	 Channel #, high bit		(Reserved = 0)
Bit 2	 00 = Verify, 01 = Write,	0 = Verify
					1 = Transfer
Bit 3	 10 = Read,   11 = Illegal	0 = Read memory transfer
					1 = Write memory transfer
Bit 4	 0 = Disable autoinitialize	(Reserved -- must be set to 0)
	 1 = Enable ...
Bit 5	 0 = Address increment		(Reserved = 0)
	 1 = Address decrement
Bit 6	 00 = Demand, 01 = Single	0 = 8-bit transfer
					1 = 16-bit transfer
Bit 7	 10 = Block,  11 = Cascade	(Reserved = 0)

|

	 mov	 ah,al		; Save original value
	 mov	 al,bl		; Copy DMA channel #
	 and	 al,mask $CH0B	; Isolate channel bits

	 test	 ah,@BIT2	; Check for verify
	 jz	 short CHECK18OUT_VER ; Jump if it's a verify

	 test	 ah,@BIT3	; Check for read (0) vs. write (1)
	 jz	 short CHECK18OUT_READ ; Jump if it's a read
				; Fall through for write
	 or	 al,@TRANS0B_WR shl $TRANS0B ; Mark as a write transfer

	 jmp	 short @F	; Join common code

CHECK18OUT_READ:
	 or	 al,@TRANS0B_RD shl $TRANS0B ; Mark as a read transfer

	 jmp	 short @F	; Join common code

CHECK18OUT_VER:
	 or	 al,@TRANS0B_VF shl $TRANS0B ; Mark as a verify
@@:

; Leave bits 4 & 5 = 00 (disable autoinitialize, address increment)

; Leave bits 6 & 7 = 00 (demand mode)

	 mov	 DMA_MODE[bx],al ; Save mode for later use

; Set/reset @DMA_BYTE and @DMA_MCA based on @BIT6 in AH

	 test	 ah,@BIT6	; Test transfer width
	 jnz	 short CHECK18OUT_WORD ; Jump if it's a 16-bit transfer

	 or	 DMA_FLAG[bx],@DMA_BYTE ; Mark as 8-bit transfer
	 and	 DMA_FLAG[bx],not @DMA_MCA ; Marrk as count in bytes

	 jmp	 short @F	; Join common code

; The address is in bytes, the count in words

CHECK18OUT_WORD:
	 and	 DMA_FLAG[bx],not @DMA_BYTE ; Mark as 16-bit transfer
	 or	 DMA_FLAG[bx],@DMA_MCA ; Mark as count in words
@@:

; Read the 24-bit memory address

	 mov	 al,bl		; Copy DMA channel #
	 or	 al,@DMA3_RADDR ; Memory address read function
	 out	 @DMA3_CMD,al	; Tell the DMA controller about it

	 in	 al,@DMA3_DATA	; Get byte 0

	 mov	 ah,al		; Save it

	 in	 al,@DMA3_DATA	; Get byte 1

	 xchg	 al,ah		; Swap to low-high order
	 mov	 DMA_ADDR[ebx*2],ax ; Save for later use

	 in	 al,@DMA3_DATA	; Get byte 2

	 mov	 DMA_PMR[bx],al ; Save for later use

; Read the 16-bit transfer count

	 mov	 al,bl		; Copy DMA channel #
	 or	 al,@DMA3_RCNT	; Transfer count read function
	 out	 @DMA3_CMD,al	; Tell the DMA controller about it

	 in	 al,@DMA3_DATA	; Get byte 0

	 mov	 ah,al		; Save it

	 in	 al,@DMA3_DATA	; Get byte 1

	 xchg	 al,ah		; Swap to low-high order
	 mov	 DMA_CNT[ebx*(type DMA_CNT)].ELO,ax ; Save for later use

	 call	 CHECK_PMR	; See if we need to adjust PMR values
				; Return with CF significant, but ignore
				; it for function setting
				; DS, ES, and FS may be changed

	 and	 DMA_FLAG[bx],not @DMA_MCA ; Clear the flag

	 REGREST <ax>		; Restore
CHECK18OUT_CLC:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK18OUT endp 		; End CHECK18OUT procedure
endif				; IF @OEM_DMA
	 NPPROCE CHECK92OUT -- MCA System Control Port A Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

MCA System Control Port A output

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)

|

; Check for transition of reset bit from 0 to 1

	 push	 ax		; Save for a moment
	 in	 al,@PS2_A	; Get the current value
	 test	 al,mask $PS2_RESET ; Check reset value
	 pop	 ax		; Restore
	 jnz	 short @F	; Jump if it's already set

	 test	 al,mask $PS2_RESET ; Reset system?
	 lea	 bx,FGROUP:MSG_P92 ; Reason code for I/O port 92h reset
	 jnz	 near ptr CHECKFNS_RESET ; Yes
@@:
	 test	 CM3_FLAG,@CM3_XA20 ; Controlling A20?
	 jnz	 short CHECK92OUT_A20 ; Yes

	 test	 al,mask $PS2_GATE ; Degate A20?
	 jnz	 short CHECK92OUT_CLC ; No, join common exit code
CHECK92OUT_A20:
	 mov	 ah,mask $PS2_GATE ; Test this bit in AL
	 call	 CTRL_A20	; Check on controlling it
CHECK92OUT_CLC:
	 clc			; Indicate all went well
CHECK92OUT_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK92OUT endp 		; End CHECK92OUT procedure
	 NPPROCE CHECK92INP -- MCA System Control Port A Input
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

MCA System Control Port A input

On entry:

BX	 =	 2 * (DX & I/O wrap)

|

	 test	 CM3_FLAG,@CM3_XA20 ; Controlling A20?
	 jz	 short CHECK92INP_EXIT ; Not this time (note CF=0)

	 in	 al,@PS2_A	; Get the current value
	 and	 al,not (mask $PS2_GATE) ; Assume it's disabled

	 test	 GLB_FLAG,@GLB_X1MB ; Check virtual A20 state
	 jz	 short @F	; Jump if it's disabled

	 or	 al,mask $PS2_GATE ; Mark as enabled
@@:
	 stc			; Indicate we're supplying the result in AL
CHECK92INP_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK92INP endp 		; End CHECK92INP procedure
if @OEM_DMA
	 NPPROCE CHECK81OUT -- DMA Controller #1 Page Registers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Page Registers, Channels 0-3 (8-bit transfers) output

If (DX == 81h, 82h, 83h, 87h)
then launder DMA page register setting if all values present.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 Actual port value

|

	 shr	 bx,1		; Shift to port index
;;;;;;;; sub	 bx,81h 	; Convert to origin-0
	 movzx	 bx,DMA_MAP-81h[bx] ; Map to ascending order
	 mov	 DMA_PMR[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK81OUT endp 		; End CHECK81OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK81INP -- DMA Controller #1 Page Registers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Page Registers, Channels 0-3 (8-bit transfers) input

If (DX == 81h, 82h, 83h, 87h)
then launder DMA page register setting if all values present.

On entry:

BX	 =	 2 * (DX & I/O wrap)
DX	 =	 Actual port value

|

	 shr	 bx,1		; Shift to port index
;;;;;;;; sub	 bx,81h 	; Convert to origin-0
	 movzx	 bx,DMA_MAP-81h[bx] ; Map to ascending order
	 mov	 al,DMA_PMR[bx] ; Return original value

	 stc			; Indicate we supplied the result

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK81INP endp 		; End CHECK81INP procedure
	 NPPROCE CHECK481OUT -- EISA DMA Controller #1 High Page Registers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

EISA DMA High Page Registers, Channels 0-3 (8-bit transfers) output

If (DX == 481h, 482h, 483h, 487h)
then launder DMA page register setting if all values present.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 Actual port value

|

	 shr	 bx,1		; Shift to port index
;;;;;;;; sub	 bx,481h	; Convert to origin-0
	 movzx	 bx,DMA_MAP-481h[bx] ; Map to ascending order
	 mov	 DMA_PMR_HI[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK481OUT endp		; End CHECK481OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK481INP -- EISA DMA Controller #1 High Page Registers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Page Registers, Channels 0-3 (8-bit transfers) input

If (DX == 481h, 482h, 483h, 487h)
then launder DMA page register setting if all values present.

On entry:

BX	 =	 2 * (DX & I/O wrap)
DX	 =	 Actual port value

|

	 shr	 bx,1		; Shift to port index
;;;;;;;; sub	 bx,481h	; Convert to origin-0
	 movzx	 bx,DMA_MAP-481h[bx] ; Map to ascending order
	 mov	 al,DMA_PMR_HI[bx] ; Return original value

	 stc			; Indicate we supplied the result

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK481INP endp		; End CHECK481INP procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK89OUT -- DMA Controller #2 Page Registers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Page Registers, Channels 5-7 (4-7 on MCA) for 16-bit transfers output

If (DX == 89h, 8Ah, 8Bh)  (DX == 89h, 8Ah, 8Bh, 8Fh)
then launder DMA page register setting if all values present.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 Actual port value

|
	 shr	 bx,1		; Shift to port index
;;;;;;;; sub	 bx,81h 	; Convert to origin-0
	 movzx	 bx,DMA_MAP-81h[bx] ; Map to ascending order
	 mov	 DMA_PMR[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK89OUT endp 		; End CHECK89OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK89INP -- DMA Controller #2 Page Registers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Page Registers, Channels 5-7 (4-7 on MCA) for 16-bit transfers input

If (DX == 89h, 8Ah, 8Bh)  (DX == 89h, 8Ah, 8Bh, 8Fh)
then launder DMA page register setting if all values present.

On entry:

BX	 =	 2 * (DX & I/O wrap)
DX	 =	 Actual port value

|

	 shr	 bx,1		; Shift to port index
;;;;;;;; sub	 bx,81h 	; Convert to origin-0
	 movzx	 bx,DMA_MAP-81h[bx] ; Map to ascending order
	 mov	 al,DMA_PMR[bx] ; Return original value

	 stc			; Indicate we supplied the result

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK89INP endp 		; End CHECK89INP procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK489OUT -- EISA DMA Controller #2 High Page Registers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Page Registers, Channels 5-7 for 16-bit transfers output

If (DX == 489h, 48Ah, 48Bh)
then launder DMA page register setting if all values present.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 Actual port value

|

	 shr	 bx,1		; Shift to port index
;;;;;;;; sub	 bx,481h	; Convert to origin-0
	 movzx	 bx,DMA_MAP-481h[bx] ; Map to ascending order
	 mov	 DMA_PMR_HI[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK489OUT endp		; End CHECK489OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECK489INP -- EISA DMA Controller #2 High Page Registers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Page Registers, Channels 5-7 for 16-bit transfers input

If (DX == 489h, 48Ah, 48Bh)
then launder DMA page register setting if all values present.

On entry:

BX	 =	 2 * (DX & I/O wrap)
DX	 =	 Actual port value

|

	 shr	 bx,1		; Shift to port index
;;;;;;;; sub	 bx,481h	; Convert to origin-0
	 movzx	 bx,DMA_MAP-481h[bx] ; Map to ascending order
	 mov	 al,DMA_PMR_HI[bx] ; Return original value

	 stc			; Indicate we supplied the result

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK489INP endp		; End CHECK489INP procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROC  CHECKC0OUT -- DMA #2 Address Register Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #2, initial address

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 0C0h, 0C4h, 0C8h, or 0CCh

|

	 shr	 bx,1		; Shift to port index
	 sub	 bx,0C0h	; Convert to origin-0 (00, 04, 08, 0C)
	 shr	 bx,1		; BX = 00, 02, 04, 06
	 add	 bx,8		; BX = 08, 0A, 0C, 0E
	 add	 bl,FLIPFLOP2	; Plus flip-flop offset
	 xor	 FLIPFLOP2,1	; Flip it for next time, too

	 mov	 DMA_ADDR.LO[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECKC0OUT endp 		; End CHECKC0OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROC  CHECKC2OUT -- DMA #2 Count Register Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #2, initial count

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 0C2h, 0C6h, 0CAh, or 0CEh

|

	 shr	 bx,1		; Shift to port index
	 sub	 bx,0C2h	; Convert to origin-0 (00, 04, 08, 0C)
	 add	 bx,4*(type DMA_CNT) ; BX = 10, 14, 18, 1C

	 add	 bl,FLIPFLOP2	; Plus flip-flop offset
	 xor	 FLIPFLOP2,1	; Flip it for next time, too

	 mov	 DMA_CNT.LO[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECKC2OUT endp 		; End CHECKC2OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROC  CHECK4C2OUT -- EISA DMA #2 Count Register Output (High Word)
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #2, initial count
EISA High Word Count (bits 16-23)


On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 40C2h, 40C6h, 40CAh, or 40CEh

|

	 shr	 bx,1		; Shift to port index
	 sub	 bx,4C2h	; Convert to origin-0 (00, 04, 08, 0C)
	 add	 bx,4*(type DMA_CNT) ; BX = 10, 14, 18, 1C

	 add	 bl,FLIPFLOP2	; Plus flip-flop offset
	 xor	 FLIPFLOP2,1	; Flip it for next time, too

	 mov	 DMA_CNT.EHI.LO[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK4C2OUT endp		; End CHECK4C2OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECKD4OUT -- DMA Controller #2 Single Bit Mask Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #2 single bit mask register output

If (DX == 0D4h and !(AL & 11b))
then save address and count for channel AL & 11b.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)

|

	 movzx	 ebx,al 	; Copy to index register
	 and	 bl,11b 	; Isolate DMA channel #
	 add	 bl,4		; Shift to channels 4-7

	 test	 al,@BIT2	; Set or clear mask?
	 jz	 short WORD_ADDRCNT ; Get address and count values for channel EBX

; Stop the DMA controller

	 out	 dx,al		; Send command to DMA SBM
	 jmp	 short $+2	; I/O delay

; Copy all of the remaining bytes of the data from
; DTE_DMA to DMA_PTR for channel BX, and clear that bit from DMA_CHAN

	 call	 DMA_COPYALL	; Copy it all
				; ES and FS clobbered
	 btr	 DMA_CHAN.ELO,bx ; Check the bit and clear it if set

	 stc			; Tell caller to skip the OUT

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECKD4OUT endp 		; End CHECKD4OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECKD6OUT -- DMA Controller #2 Mode Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #2 Mode Register output

Save DMA mode and channel # for channel AL & 11b.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)

|

	 mov	 bx,ax		; Copy to index register (note AH = undefined)
	 and	 bx,mask $CH0B	; Isolate DMA channel #
	 shr	 bx,$CH0B	; Shift to low-order
	 add	 bx,4		; Shift to channels 4-7
	 mov	 DMA_MODE[bx],al ; Save for later use

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECKD6OUT endp 		; End CHECKD6OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECKD8OUT -- DMA Controller #2 Flip-flop Register Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #2 Flip-flop Register output

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)
DX	 =	 D8

|

	 mov	 FLIPFLOP2,0	; Clear the flip-flop

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECKD8OUT endp 		; End CHECKD8OUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE CHECKDEOUT -- DMA Controller #2 All Bits Mask Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DMA Controller #2 all bits mask register output

If (DX == 0DEh and !(AL & 1111b))
then save address and count for channel AL & 11b.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)

|

	 movzx	 ebx,al 	; Copy to test
	 and	 bl,@BIT3 or @BIT2 or @BIT1 or @BIT0 ; Isolate bits
	 xor	 bl,@BIT3 or @BIT2 or @BIT1 or @BIT0 ; Complement for BSF

	 bsf	 bx,bx		; Get index of least significant bit
	 jz	 short CHECKDEOUT_CLC ; None, so ignore them

	 add	 bx,4		; Shift to channels 4-7

	 jmp	 WORD_ADDRCNT	; Get address and count values for channel EBX

CHECKDEOUT_CLC:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECKDEOUT endp 		; End CHECKDEOUT procedure
endif				; IF @OEM_DMA
if @OEM_DMA
	 NPPROCE WORD_ADDRCNT -- Get Address and Count For Word I/O
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get address and count word I/O values for channel EBX

On entry:

EBX	 =	 DMA channel # (4, 5, 6, 7)

|

	 REGSAVE <ax,dx>	; Save registers

if @OEM_VDS
	 cmp	 DMADISCNT[ebx*4],0 ; Izit disabled?
	 jne	 short WORD_ADDRCNT_EXIT ; Yes, skip all this
endif				; IF @OEM_VDS

	 test	 CM2_FLAG,@CM2_SDMA ; Doing slow DMA?
	 jnz	 short WORD_ADDRCNT1 ; Yes, address and count registers set

; Disable the channel first

;;;	 mov	 al,bl		; Copy DMA channel #
;;;;;;;; sub	 al,4		; Convert to origin-4
;;;;;;;; or	 al,@BIT2	; Set the disable bit
;;;	 out	 @DMA2_SBM,al	; Disable it
;;;	 jmp	 short $+2	; Drain the PIQ
;;;	 jmp	 short $+2	; Drain the PIQ
;;;	 jmp	 short $+2	; Drain the PIQ

; Get the 24-bit address from the controller

	 movzx	 dx,DMA_IADDR[bx] ; Get address I/O port
				; 4-C0, 5-C4, 6-C8, 7-CC

	 out	 @DMA2_FLIP,al	; Clear flip-flop register
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 in	 al,dx		; Get low-order of current address
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 ah,al		; Save for a moment

	 in	 al,dx		; Get high-order of current address
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 xchg	 al,ah		; Swap to save order
	 mov	 DMA_ADDR[ebx*2],ax ; Save for later use

; Get the 16-bit count from the controller

	 add	 dx,2		; Skip to count port

	 in	 al,dx		; Get count (bits 0-7)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 ah,al		; Save for a moment

	 in	 al,dx		; Get count (bits 8-15)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 xchg	 al,ah		; Swap to save order
	 mov	 DMA_CNT[ebx*(type DMA_CNT)].ELO,ax ; Save for later use

; Get the 8-bit EISA High Word Count segment count from the controller

	 xor	 al,al		; Assume bits 16-23 are zero

	 test	 CM2_FLAG,@CM2_EISA_DMA ; Izit an EISA DMA system?
	 jz	 short @F	; Jump if not

	 mov	 dh,4h		; High Word Segment = Low Word Segment + 400h

	 in	 al,dx		; Get count (bits 16-23)
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ
@@:
	 mov	 DMA_CNT[ebx*(type DMA_CNT)].LO,al ; Save count (bits 16-23)

WORD_ADDRCNT1:
	 and	 DMA_FLAG[bx],not @DMA_BYTE ; Mark as 16-bit transfer

	 call	 CHECK_PMR	; See if we need to adjust PMR values
				; Return with CF significant, but ignore
				; it for mask register
				; DS, ES, and FS may be changed
WORD_ADDRCNT_EXIT:
	 clc			; Indicate caller should do OUT

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WORD_ADDRCNT endp		; End WORD_ADDRCNT procedure
endif				; IF @OEM_DMA
if @OEM_SOFT
	 NPPROCE CHECK3B4OUT -- CRT Controller Index Register Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

If (AL = 0Ah, 0Bh, 0Eh, or 0Fh)
trap the next higher I/O port.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)

|

	 cmp	 al,@VID_SIZLO	; Izit cursor size start register?
	 je	 short CHECK3B4_OUT_TRAP ; Yes, trap it

	 cmp	 al,@VID_SIZHI	; Izit cursor size end register?
	 je	 short CHECK3B4_OUT_TRAP ; Yes, trap it

	 cmp	 al,@VID_POSHI	; Izit cursor location high register?
	 je	 short CHECK3B4_OUT_TRAP0 ; Yes, trap it

	 cmp	 al,@VID_POSLO	; Izit cursor location low register?
	 jne	 short CHECK3B4_OUT_CLC ; No, skip this one
CHECK3B4_OUT_TRAP0:
	 sub	 al,2		; Convert from 0E/0F to 0C/0D
CHECK3B4_OUT_TRAP:
	 sub	 al,0Ah 	; Convert to origin-0
	 mov	 CRT_IND,al	; Save index register value (00-03)

	 movzx	 esi,bx 	; Copy 2* I/O port address
	 shr	 si,1		; Divide by two to get I/O port address
	 inc	 si		; Skip to data port address
	 FIXICALL JGROUP:SET_BITMAP,DTE_CSJG ; Set the bit

	 stc			; Tell caller to skip the OUT

	 jmp	 short CHECK3B4_OUT_EXIT ; Join common exit code

CHECK3B4_OUT_CLC:
	 clc			; Indicate caller should do OUT
CHECK3B4_OUT_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK3B4OUT endp		; End CHECK3B4OUT procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 NPPROCE CHECK3B5OUT -- CRT Controller Data Register Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Save the value for later use and clear the I/O port bit.

On entry:

AL	 =	 value to output
BX	 =	 2 * (DX & I/O wrap)

|

	 shr	 bx,1		; Divide by two to get I/O port address
	 movzx	 esi,bx 	; Copy I/O port address
	 FIXICALL JGROUP:CLR_BITMAP,DTE_CSJG ; Clear the bit

	 sub	 bx,03B5h	; Convert to origin-0, scale 0 or 3D5h-3B5h
	 shr	 bx,5-2 	; Convert from 32-bytes to 4-bytes
	 add	 bl,CRT_IND	; Add in the index register (00-03)
	 mov	 CURS_DATA[bx],al ; Save the value

	 stc			; Tell caller to skip the OUT

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK3B5OUT endp		; End CHECK3B5OUT procedure
endif				; IF @OEM_SOFT
if @OEM_SOFT
	 NPPROCE CHECK3B5INP -- CRT Controller Data Register Input
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Save the value for later use and clear the I/O port bit.

On entry:

BX	 =	 2 * (DX & I/O wrap)

|

	 shr	 bx,1		; Divide by two to get I/O port address
	 movzx	 esi,bx 	; Copy I/O port address
	 FIXICALL JGROUP:CLR_BITMAP,DTE_CSJG ; Clear the bit

	 sub	 bx,03B5h	; Convert to origin-0, scale 0 or 3D5h-3B5h
	 shr	 bx,5-2 	; Convert from 32-bytes to 4-bytes
	 add	 bl,CRT_IND	; Add in the index register (00-03)
	 mov	 al,CURS_DATA[bx] ; Get the value

	 stc			; Tell caller to skip the IN

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK3B5INP endp		; End CHECK3B5INP procedure
endif				; IF @OEM_SOFT
	 NPPROCE CHECK_X -- Default Checking Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Default checking routine

On exit:

CF	 =	 0 to tell caller to do the IN/OUT

|

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_X  endp			; End CHECK_X procedure
	 NPPROCE CHECK_XINP -- Default Checking Routine For Input
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Default checking routine for input

On entry:

DX	 =	 I/O port #
SS:EBP	 ==>	 Caller's INTXX_STR

On exit:

CF	 =	 0 to tell caller to do the IN
	 =	 1 if it's been done already
AL/AX/EAX =	 input value if the I/O was virtualized

|

; Check for I/O trapping

	 and	 IOTRAP_TYP,not @IOTRAP_OUT ; Mark as input
	 call	 CHECK_IOTRAP	; See if DX is an I/O trap port
				; Return with AL/AX/EAX and CF significant
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XINP endp 		; End CHECK_XINP procedure
	 NPPROCE CHECK_XOUT -- Default Checking Routine For Output
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Default checking routine for output

On entry:

DX	 =	 I/O port #
SS:EBP	 ==>	 Caller's INTXX_STR

On exit:

CF	 =	 0 to tell caller to do the OUT
	 =	 1 if it's been done already

|

; Check for I/O trapping

	 or	 IOTRAP_TYP,@IOTRAP_OUT ; Mark as output
	 call	 CHECK_IOTRAP	; See if DX is an I/O trap port
				; Return with CF significant
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XOUT endp 		; End CHECK_XOUT procedure
	 NPPROC  CHECK_IOTRAP -- Check For I/O Trapping
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check for I/O trapping

On entry:

DX	 =	 I/O port #
SS:EBP	 ==>	 Caller's INTXX_STR

On exit:

CF	 =	 0 to tell caller to do the IN/OUT
	 =	 1 if it's been done already
AL/AX/EAX =	 input value if the I/O was virtualized

|

	 REGSAVE <ebx,ecx,esi>	; Save registers

	 mov	 cx,@IOTRAP_MAX ; Get # I/O trap handlers

	 mov	 ebx,PIOTRAP	; Get the offset in PGROUP of I/O trap strucs

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it
CHECK_IOTRAP_NEXTSTR:
	 push	 cx		; Save outer loop counter

	 mov	 cx,PGROUP:[ebx].IOTRAP_TABCNT ; Get # table entries
	 stc			; Assume none
	 jcxz	 CHECK_IOTRAP_LOOPSTR ; Jump if none (note CF=1)

	 cmp	 dx,PGROUP:[ebx].IOTRAP_IO.ELO ; Izit in range?
	 jb	 short CHECK_IOTRAP_LOOPSTR ; Jump if not (note CF=1)

	 cmp	 PGROUP:[ebx].IOTRAP_IO.EHI,dx ; Izit in range?
	 jb	 short CHECK_IOTRAP_LOOPSTR ; Jump if not (note CF=1)

	 mov	 esi,PGROUP:[ebx].IOTRAP_LaTAB ; Get LA of handler's table
CHECK_IOTRAP_NEXTTAB:
	 cmp	 dx,AGROUP:[esi].DI_wPORT ; Duzit match the port #?
	 je	 short CHECK_IOTRAP_LOOPSTR ; Jump if so (note CF=0)

	 add	 esi,type DISPATCH_INFO ; Skip to next entry

	 loop	 CHECK_IOTRAP_NEXTTAB ; Jump if more table entries
CHECK_IOTRAP_LOOPSTR:
	 pop	 cx		; Restore outer loop counter
	 jnc	 short CHECK_IOTRAP_FOUND ; Jump if there's a match

	 add	 ebx,type IOTRAP_STR ; Skip to the next entry

	 loop	 CHECK_IOTRAP_NEXTSTR ; Jump if more strucs to check
CHECK_IOTRAP_NOTVIRT:
	 clc			; Mark as not virtualized

	 jmp	 CHECK_IOTRAP_EXIT ; Join common exit code

CHECK_IOTRAP_FOUND:

; Save the local variables so we can be re-entrant

	 push	 DESC_TAB.DTE_CSIO.EDQHI ; Save to be re-entrant
	 push	 DESC_TAB.DTE_CSIO.EDQLO ; ...
	 push	 DESC_TAB.DTE_DSIO.EDQHI ; ...
	 push	 DESC_TAB.DTE_DSIO.EDQLO ; ...

	 REGSAVE <ds,es,fs,gs>	; Save over call to I/O handler

; Setup the caller's PL0 code and data selectors

	 mov	 ecx,PGROUP:[ebx].IOTRAP_GDTCS.EDQLO ; Get low-order
	 mov	 DESC_TAB.DTE_CSIO.EDQLO,ecx ; Save into GDT
	 mov	 ecx,PGROUP:[ebx].IOTRAP_GDTCS.EDQHI ; Get high-order
	 mov	 DESC_TAB.DTE_CSIO.EDQHI,ecx ; Save into GDT

	 mov	 ecx,PGROUP:[ebx].IOTRAP_GDTDS.EDQLO ; Get low-order
	 mov	 DESC_TAB.DTE_DSIO.EDQLO,ecx ; Save into GDT
	 mov	 ecx,PGROUP:[ebx].IOTRAP_GDTDS.EDQHI ; Get high-order
	 mov	 DESC_TAB.DTE_DSIO.EDQHI,ecx ; Save into GDT

; Return the I/O trap type (input or output)

	 mov	 ecx,IOTRAP_TYP ; Get the type
	 mov	 eax,[ebp].INTXX_EAX ; Get the value if output

	 push	 DTE_DSIO	; Get caller's data selector
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 PUSHW	 cs		; Pass return selector
	 push	 word ptr (offset PGROUP:CHECK_IOTRAP_EXIT0) ; Pass return offset

	 push	 DTE_CSIO	; Pass selector
	 push	 AGROUP:[esi].DI_wOFF ; Pass offset of handler

	 retf			; Transfer control to the handler

CHECK_IOTRAP_EXIT0:
	 cli			; Disable interrupts

; Return here with EAX and CF significant

	 cmc			; Complement so CF=0 means do it ourselves

	 REGREST <gs,fs,es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

; Restore the original GDT entries so we can be re-entrant

	 pop	 DESC_TAB.DTE_DSIO.EDQLO ; ...
	 pop	 DESC_TAB.DTE_DSIO.EDQHI ; ...
	 pop	 DESC_TAB.DTE_CSIO.EDQLO ; ...
	 pop	 DESC_TAB.DTE_CSIO.EDQHI ; ...
CHECK_IOTRAP_EXIT:
	 REGREST <esi,ebx,ecx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_IOTRAP endp		; End CHECK_IOTRAP procedure
	 NPPROCE CHECK_DBG -- Debugging Checking Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Debugging checking routine

On exit:

CF	 =	 0 to tell caller to do the IN/OUT

|

	 test	 LCL_FLAG,@LCL_SWAT ; Debugger installed?
	 jz	 short @F	; No, just ignore it

	 int	 03h		; Call our debugger
@@:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DBG endp			; End CHECK_DBG procedure
	 NPPROCE CHECK_INP -- Check on Input Ports
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check on input from various ports.

On entry:

DX	 =	 I/O port #
SS:EBP	 ==>	 Caller's INTXX_STR

On exit:

CF	 =	 1 if we supply the value (in AL/AX/EAX)
AL/AX/EAX =	 value supplied
BX	 =	 undefined

|

	 cmp	 dx,@CHECKER_LEN ; Izit out of range?
	 jae	 near ptr CHECK_XINP ; Jump if so

	 movzx	 ebx,dx 	; Copy to index register
	 and	 bx,IO_LIM_MASK ; Isolate low-order bits
	 shl	 ebx,1		; Times two to index table of words
	 mov	 edi,PCHECKER_INP ; SS:EDI ==> CHECKER_INP table

; EBX = (Port value (modulo (I/O Wrap)) * 2)
;	I/O wrap is 400h for ISA (if IOWRAP), -1 for MCA and EISA
; DX  = Actual port value

	 jmp	 PGROUP:[ebx+edi].ELO ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_INP endp			; End CHECK_INP procedure
	 NPPROCE CHECK_OUT -- Check on Output Ports
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Check on output to various ports.

On entry:

DX	 =	 I/O port #
AL	 =	 output value (also called for AX and EAX)
SS:EBP	 ==>	 Caller's INTXX_STR

On exit:

CF	 =	 1 if OUT already done

|

	 cmp	 dx,@CHECKER_LEN ; Izit out of range?
	 jae	 near ptr CHECK_XOUT ; Jump if so

	 movzx	 ebx,dx 	; Copy to index register
	 and	 bx,IO_LIM_MASK ; Isolate low-order bits
	 shl	 ebx,1		; Times two to index table of words
	 mov	 edi,PCHECKER_OUT ; SS:EDI ==> CHECKER_OUT table

; EBX = (Port value (modulo (I/O Wrap)) * 2)
;	I/O wrap is 400h for ISA (if IOWRAP), -1 for MCA and EISA
; DX  = Actual port value

	 jmp	 PGROUP:[ebx+edi].ELO ; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_OUT endp			; End CHECK_OUT procedure
	 NPPROCE GP_OUTIB -- Emulate OUT nn,AL
	 assume  ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Emulate 	 OUT nn,AL

On entry:

ES:ESI	 ==>	 next instruction byte

|

	 lods	 AGROUP:[esi].LO ; Get the immediate port #

	 inc	 [ebp].INTXX_EIP.ELO ; Skip past the instruction byte
	 movzx	 dx,al		; Copy to variable I/O port register

	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Get the byte to output
	 mov	 IOTRAP_TYP,@IOTRAP_DB shl $IOTRAP_WID ; Mark as byte I/O
	 call	 CHECK_OUT	; Check on I/O port outputs, BX clobbered
				; ES and FS clobbered
	 jc	 short @F	; Jump if pages re-mapped

	 out	 dx,al		; Do it
@@:
	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GP_OUTIB endp			; End GP_OUTIB procedure
	 NPPROCE GP_OUTIW -- Emulate OUT nn,AX
	 assume  ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Emulate 	 OUT nn,AX  or
		 OUT nn,EAX

On entry:

ES:ESI	 ==>	 next instruction byte

|

	 lods	 AGROUP:[esi].LO ; Get the immediate port #

	 inc	 [ebp].INTXX_EIP.ELO ; Skip past the instruction byte
	 movzx	 dx,al		; Copy to variable I/O port register

	 mov	 eax,[ebp].INTXX_EAX ; Get the dword to output

	 test	 bx,$$OSP	; Using EAX?
	 jnz	 short GP_OUTIW1  ; Yes

	 mov	 IOTRAP_TYP,@IOTRAP_DW shl $IOTRAP_WID ; Mark as word I/O
	 call	 CHECK_OUT	; Check on I/O port outputs, BX clobbered
				; ES and FS clobbered
	 jc	 short @F	; Jump if pages re-mapped

	 out	 dx,ax		; Do it
@@:
	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

GP_OUTIW1:
	 mov	 IOTRAP_TYP,@IOTRAP_DD shl $IOTRAP_WID ; Mark as dword I/O
	 call	 CHECK_OUT	; Check on I/O port outputs, BX clobbered
				; ES and FS clobbered
	 jc	 short @F	; Jump if pages re-mapped

	 out	 dx,eax 	; Do it
@@:
	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GP_OUTIW endp			; End GP_OUTIW procedure
	 NPPROCE GP_OUTDB -- Emulate OUT DX,AL
	 assume  ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Emulate 	 OUT DX,AL

On entry:

ES:ESI	 ==>	 next instruction byte

|

	 mov	 dx,[ebp].INTXX_EDX.ELO ; Get the port #

if @OEM_EMS
	test	CM4_FLAG,@CM4_EMS30 ; Supporting EMS 3.0?
	jz	short @F	; No, don't check for these ports

	 cmp	 dx,PORTPMR	; Izit a PMR I/O port?
	 jb	 short @F	; No, too small

	 cmp	 dx,PORTPMRZ	; Check against upper limit
	 jb	 near ptr EMU_PORTPMRO ; Yes, it's within range
@@:
endif				; IF @OEM_EMS
	 cmp	 dx,PORT15	; Izit INT 15h?
	 je	 near ptr GP_OUTD15 ; Yes

	 cmp	 dx,PORT67	; Izit INT 67h?
	 je	 near ptr GP_OUTD67 ; Yes

	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Get the byte to output
	 mov	 IOTRAP_TYP,@IOTRAP_DB shl $IOTRAP_WID ; Mark as byte I/O
	 call	 CHECK_OUT	; Check on I/O port outputs, BX clobbered
				; ES and FS clobbered
	 jc	 short @F	; Jump if pages re-mapped

	 out	 dx,al		; Do it
@@:
	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GP_OUTDB endp			; End GP_OUTDB procedure
	 NPPROCE GP_OUTDW -- Emulate OUT DX,AX
	 assume  ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Emulate 	 OUT DX,AX  or
		 OUT DX,EAX

On entry:

ES:ESI	 ==>	 next instruction byte

|

	 mov	 dx,[ebp].INTXX_EDX.ELO ; Get the port #

if @OEM_EMS
	test	CM4_FLAG,@CM4_EMS30 ; Supporting EMS 3.0?
	jz	short @F	; No, don't check for these ports

	 cmp	 dx,PORTPMR	; Izit a PMR I/O port?
	 jb	 short @F	; No, too small

	 cmp	 dx,PORTPMRZ	; Check against upper limit
	 jb	 near ptr EMU_PORTPMRO ; Yes, it's within range
@@:
endif				; IF @OEM_EMS
	 cmp	 dx,PORT15	; Izit INT 15h?
	 je	 short GP_OUTD15 ; Yes

	 cmp	 dx,PORT67	; Izit INT 67h?
	 je	 short GP_OUTD67 ; Yes

	 test	 bx,$$OSP	; Using EAX?
	 jnz	 short GP_OUTDW1 ; Yes

	 mov	 ax,[ebp].INTXX_EAX.ELO ; Get the word to output
	 mov	 IOTRAP_TYP,@IOTRAP_DW shl $IOTRAP_WID ; Mark as word I/O
	 call	 CHECK_OUT	; Check on I/O port outputs, BX clobbered
				; ES and FS clobbered
	 jc	 short @F	; Jump if pages re-mapped

	 out	 dx,ax		; Do it
@@:
	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

GP_OUTDW1:
	 mov	 eax,[ebp].INTXX_EAX ; Get the dword to output
	 mov	 IOTRAP_TYP,@IOTRAP_DD shl $IOTRAP_WID ; Mark as dword I/O
	 call	 CHECK_OUT	; Check on I/O port outputs, BX clobbered
				; ES and FS clobbered
	 jc	 short @F	; Jump if pages re-mapped

	 out	 dx,eax 	; Do it
@@:
	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

GP_OUTD15:			; PORT15
	 call	 STRIP_DX	; Strip caller's DX from the stack

	 FIXIJMP IGROUP:EMU_INT15,DTE_CSIG ; Join INT 15h code

GP_OUTD67:			; PORT67
	 call	 STRIP_DX	; Strip caller's DX from the stack

	 jmp	 EMU_INT67	; Join INT 67h code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GP_OUTDW endp			; End GP_OUTDW procedure
	 NPPROC  STRIP_DX -- Strip Caller's DX from the Stack
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Strip off caller's DX from his stack

On entry:

SS:EBP	 ==>	 INTXX_STR

No registers preserved.

|

	 call	 PL3STK_DS	; Return with DS:ESI ==> caller's SS:SP
	 assume  ds:AGROUP	; Tell the assembler about it

	 lods	 AGROUP:[esi].ELO ; Get PUSHed DX from PL3 stack

	 mov	 [ebp].INTXX_EDX.ELO,ax ; Save for our local handlers
	 add	 [ebp].INTXX_ESP.ELO,2 ; Skip over PUSHed DX

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STRIP_DX endp			; End STRIP_DX procedure
	 NPPROC  PL3STK_DS -- Address PL3 Stack
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Address PL3 stack

On exit:

DS:ESI	 ==>	 PL3 caller's SS:SP

|

	 REGSAVE <eax>		; Save register

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 movzx	 eax,[ebp].INTXX_SS ; Get caller's stack segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,[ebp].INTXX_ESP.ELO ; Get caller's stack pointer
	 add	 esi,eax	; DS:ESI ==> caller's stack

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PL3STK_DS endp			; End PL3STK_DS procedure
	 NPPROCE GP_INIB -- Emulate IN AL,nn
	 assume  ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Emulate 	 IN AL,nn

On entry:

ES:ESI	 ==>	 next instruction byte

|

	 lods	 AGROUP:[esi].LO ; Get the immediate port #

	 inc	 [ebp].INTXX_EIP.ELO ; Skip past the instruction byte
	 movzx	 dx,al		; Copy to variable I/O port register

	 mov	 IOTRAP_TYP,@IOTRAP_DB shl $IOTRAP_WID ; Mark as byte I/O
	 call	 CHECK_INP	; Check on I/O port inputs, BX clobbered
	 jc	 short @F	; Jump if we supply the value

	 in	 al,dx		; Do it
@@:
	 mov	 [ebp].INTXX_EAX.ELO.LO,al ; Save the input byte

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GP_INIB  endp			; End GP_INIB procedure
	 NPPROCE GP_INIW -- Emulate IN AX,nn
	 assume  ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Emulate 	 IN AX,nn  or  IN EAX,nn

On entry:

ES:ESI	 ==>	 next instruction byte

|

	 lods	 AGROUP:[esi].LO ; Get the immediate port #

	 inc	 [ebp].INTXX_EIP.ELO ; Skip past the instruction byte
	 movzx	 dx,al		; Copy to variable I/O port register

	 test	 bx,$$OSP	; Using EAX?
	 jnz	 short GP_INIW1 ; Yes

	 mov	 IOTRAP_TYP,@IOTRAP_DW shl $IOTRAP_WID ; Mark as word I/O
	 call	 CHECK_INP	; Check on I/O port inputs, BX clobbered
	 jc	 short @F	; Jump if we supply the value

	 in	 ax,dx		; Do it
@@:
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save the input word

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

GP_INIW1:
	 mov	 IOTRAP_TYP,@IOTRAP_DD shl $IOTRAP_WID ; Mark as dword I/O
	 call	 CHECK_INP	; Check on I/O port inputs, BX clobbered
	 jc	 short @F	; Jump if we supply the value

	 in	 eax,dx 	; Do it
@@:
	 mov	 [ebp].INTXX_EAX,eax ; Save the input dword

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GP_INIW  endp			; End GP_INIW procedure
	 NPPROCE GP_INDB -- Emulate IN AL,DX
	 assume  ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Emulate 	 IN AL,DX

On entry:

ES:ESI	 ==>	 next instruction byte

|

	 mov	 dx,[ebp].INTXX_EDX.ELO ; Get the port #

if @OEM_EMS
	test	CM4_FLAG,@CM4_EMS30 ; Supporting EMS 3.0?
	jz	short @F	; No, don't check for these ports

	 cmp	 dx,PORTPMR	; Izit a PMR I/O port?
	 jb	 short @F	; No, too small

	 cmp	 dx,PORTPMRZ	; Check against upper limit
	 jb	 near ptr EMU_PORTPMRI ; Yes, it's within range
@@:
endif				; IF @OEM_EMS

	 mov	 IOTRAP_TYP,@IOTRAP_DB shl $IOTRAP_WID ; Mark as byte I/O
	 call	 CHECK_INP	; Check on I/O port inputs, BX clobbered
	 jc	 short @F	; Jump if we supply the value

	 in	 al,dx		; Do it
@@:
	 mov	 [ebp].INTXX_EAX.ELO.LO,al ; Save the input byte

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GP_INDB  endp			; End GP_INDB procedure
	 NPPROCE GP_INDW -- Emulate IN AX,DX
	 assume  ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Emulate 	 IN AX,DX  or  IN EAX,DX

On entry:

ES:ESI	 ==>	 next instruction byte

|

	 mov	 dx,[ebp].INTXX_EDX.ELO ; Get the port #

if @OEM_EMS
	test	CM4_FLAG,@CM4_EMS30 ; Supporting EMS 3.0?
	jz	short @F	; No, don't check for these ports

	 cmp	 dx,PORTPMR	; Izit a PMR I/O port?
	 jb	 short @F	; No, too small

	 cmp	 dx,PORTPMRZ	; Check against upper limit
	 jb	 near ptr EMU_PORTPMRI ; Yes, it's within range
@@:
endif				; IF @OEM_EMS
	 test	 bx,$$OSP	; Using EAX?
	 jnz	 short GP_INDW1 ; Yes

	 mov	 IOTRAP_TYP,@IOTRAP_DW shl $IOTRAP_WID ; Mark as word I/O
	 call	 CHECK_INP	; Check on I/O port inputs, BX clobbered
	 jc	 short @F	; Jump if we supply the value

	 in	 ax,dx		; Do it
@@:
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save the input word

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

GP_INDW1:
	 mov	 IOTRAP_TYP,@IOTRAP_DD shl $IOTRAP_WID ; Mark as dword I/O
	 call	 CHECK_INP	; Check on I/O port inputs, BX clobbered
	 jc	 short @F	; Jump if we supply the value

	 in	 eax,dx 	; Do it
@@:
	 mov	 [ebp].INTXX_EAX,eax ; Save the input dword

	 jmp	 INT0D_IRETD	; Return to caller at CS:IP

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GP_INDW  endp			; End GP_INDW procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_IOP module

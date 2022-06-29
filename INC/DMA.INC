;' $Header:   P:/PVCS/MAX/INC/DMA.INV   1.0   05 Sep 1995 13:26:54   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; DMA.INC
;
; Direct Memory Access equates
;

.xcref @DMA1_STAT,@DMA2_STAT
.xcref @DMA1_REQ, @DMA2_REQ
.xcref @DMA1_SBM, @DMA2_SBM
.xcref @DMA1_MODE,@DMA2_MODE
.xcref @DMA1_FLIP,@DMA2_FLIP
.xcref @DMA1_MBM, @DMA2_MBM
@DMA1_STAT equ	  08h		; Controller #1 read status register
@DMA2_STAT equ	 0D0h		; ...	     #2

@DMA1_REQ  equ	  09h		; Controller #1 request register
@DMA2_REQ  equ	 0D2h		; ...	     #2

@DMA1_SBM  equ	  0Ah		; Controller #1 single-bit mask register
@DMA2_SBM  equ	 0D4h		; ...	     #2

@DMA1_MODE equ	  0Bh		; Controller #1 mode register
@DMA2_MODE equ	 0D6h		; ...	     #2

@DMA1_FLIP equ	  0Ch		; Controller #1 flip-flop register
@DMA2_FLIP equ	 0D8h		; ...	     #2

@DMA1_MBM  equ	  0Fh		; Controller #1 multiple-bit mask register
@DMA2_MBM  equ	 0DEh		; ...	     #2

.xcref @DMA_CH0,@DMA_CH1,@DMA_CH2,@DMA_CH3
@DMA_CH0   equ	 00010000b	; DMA #1 Channel 0 state test
@DMA_CH1   equ	 00100000b	;		 1
@DMA_CH2   equ	 01000000b	;		 2
@DMA_CH3   equ	 10000000b	;		 3


; PS/2 Model 80 Extended Function I/O Ports

.xcref @DMA3_CMD,@DMA3_DATA
@DMA3_CMD  equ	 18h		; DMA type 3 command register
@DMA3_DATA equ	 1Ah		; ...	     data


; PS/2 Model 80 I/O Port 18h Commands

.xcref @DMA3_IO,@DMA3_WADDR,@DMA3_RADDR,@DMA3_WCNT,@DMA3_RCNT
.xcref @DMA3_RSTAT,@DMA3_MODE,@DMA3_ARBUS,@DMA3_SETBIT
.xcref @DMA3_CLRBIT,@DMA3_CLRALL
@DMA3_IO     equ  00h		; I/O address register
;	     equ  10h		; Reserved
@DMA3_WADDR  equ  20h		; Write memory address register
@DMA3_RADDR  equ  30h		; Read ...
@DMA3_WCNT   equ  40h		; Write transfer count register
@DMA3_RCNT   equ  50h		; Read ...
@DMA3_RSTAT  equ  60h		; Read status register
@DMA3_MODE   equ  70h		; Mode register
@DMA3_ARBUS  equ  80h		; Arbus register
@DMA3_SETBIT equ  90h		; Set single bit mask register
@DMA3_CLRBIT equ 0A0h		; Clear ...
;	     equ 0B0h		; Reserved
;	     equ 0C0h		; Reserved
@DMA3_CLRALL equ 0D0h		; Master clear
;	     equ 0E0h		; Reserved
;	     equ 0F0h		; Reserved


; 8-bit DMA Channel Registers

.xcref DMA0A_REC,DMA0B_REC
DMA0A_REC record $MASK0A:1,$CH0A:2
DMA0B_REC record $MODE0B:2,$DF0B:1,$AUTO0B:1,$TRANS0B:2,$CH0B:2

; Bit meanings in (mask $TRANS0B)

.xcref @TRANS0B_VF,@TRANS0B_WR,@TRANS0B_RD
@TRANS0B_VF equ  00b		; Verify (nothing to do)
@TRANS0B_WR equ  01b		; Write (I/O device to memory)
@TRANS0B_RD equ  10b		; Read	(memory to I/O device)

; Bit meanings in (mask $MODE0B)

.xcref @MODE0B_DMD,@MODE0B_SNG,@MODE0B_BLK,@MODE0B_CSC
@MODE0B_DMD equ  00b		; Demand mode
@MODE0B_SNG equ  01b		; Single mode
@MODE0B_BLK equ  10b		; Block mode
@MODE0B_CSC equ  11b		; Cascade mode

; DMA Page Registers

.xcref @PMR0,@PMR1,@PMR2,@PMR3,@PMR4,@PMR5,@PMR6,@PMR7,
@PMR0	 equ	 87h		; DMA channel #0 (not PC/XT)
@PMR1	 equ	 83h		; ...	      #1
@PMR2	 equ	 81h		; ...	      #2
@PMR3	 equ	 82h		; ...	      #3
@PMR4	 equ	 8Fh		; ...	      #4 (not PX/XT/AT)
@PMR5	 equ	 8Bh		; ...	      #5 (not PC/XT)
@PMR6	 equ	 89h		; ...	      #6 (not PC/XT)
@PMR7	 equ	 8Ah		; ...	      #7 (not PC/XT)


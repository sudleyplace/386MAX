;' $Header:   P:/PVCS/MAX/INC/8253.INV   1.0   05 Sep 1995 13:27:08   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; 8253.INC
;
; 8253 timer chip equates used to write to the control port (43h)
;

.xcref TIMER_REC
TIMER_REC record $TIMER_CH:2,$TIMER_FN:2,$TIMER_MODE:3,$TIMER_CNT:1

.xcref @TIMER_BIN,@TIMER_BCD,@TIMER_MODE,@TIMER_LATCH,@TIMER_MSB,@TIMER_LSB,@TIMER_LMSB,@TIMER_CH
@TIMER_BIN   equ 00000000b	; Binary counting mode
@TIMER_BCD   equ 00000001b	; BCD counting mode
@TIMER_MODE  equ 00000010b	; Mode 0 through 5
@TIMER_LATCH equ 00000000b	; Latch present counter value
@TIMER_MSB   equ 00010000b	; Read/write MSB only
@TIMER_LSB   equ 00100000b	; Read/write LSB only
@TIMER_LMSB  equ 00110000b	; Read/write LSB, then MSB
@TIMER_CH    equ 01000000b	; Program channels 0 through 2

.xcref @8253_CH0,@8253_CH1,@8253_CH2,@8253_CTL,@8253_CH3,@8253_CTL3
.xcref @8253_XCIO
@8253_CH0 equ	 40h		; Channel 0 -- 8253 timer chip ports
@8253_CH1 equ	 41h		;	  1
@8253_CH2 equ	 42h		;	  2
@8253_CTL equ	 43h		; Control port
@8253_CH3 equ	 44h		; Channel 3 counter (MCA)
@8253_CTL3 equ	 47h		; Channel 3 control (MCA)
@8253_XCIO equ	 4Fh		; Non-cached I/O port (MCA)


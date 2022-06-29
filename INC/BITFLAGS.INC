;' $Header:   P:/PVCS/MAX/INC/BITFLAGS.INV   1.0   05 Sep 1995 13:26:46   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; BITFLAGS.INC
;
; Records and equates for bit flags and nibble flags
;

if (@Cpu and 1000b)		; If 80386 instructions
.xcref @BIT31,@BIT30,@BIT29,@BIT28,@BIT27,@BIT26,@BIT25,@BIT24
.xcref @BIT23,@BIT22,@BIT21,@BIT20,@BIT19,@BIT18,@BIT17,@BIT16
@BIT31	 equ	 80000000h
@BIT30	 equ	 40000000h
@BIT29	 equ	 20000000h
@BIT28	 equ	 10000000h
@BIT27	 equ	 08000000h
@BIT26	 equ	 04000000h
@BIT25	 equ	 02000000h
@BIT24	 equ	 01000000h
@BIT23	 equ	 00800000h
@BIT22	 equ	 00400000h
@BIT21	 equ	 00200000h
@BIT20	 equ	 00100000h
@BIT19	 equ	 00080000h
@BIT18	 equ	 00040000h
@BIT17	 equ	 00020000h
@BIT16	 equ	 00010000h

BITREC0  record  $BIT31:1,$BIT30:1,$BIT29:1,$BIT28:1, \
		 $BIT27:1,$BIT26:1,$BIT25:1,$BIT24:1, \
		 $BIT23:1,$BIT22:1,$BIT21:1,$BIT20:1, \
		 $BIT19:1,$BIT18:1,$BIT17:1,$BIT16:1, \
		 $BIT15:1,$BIT14:1,$BIT13:1,$BIT12:1, \
		 $BIT11:1,$BIT10:1,$BIT09:1,$BIT08:1, \
		 $BIT07:1,$BIT06:1,$BIT05:1,$BIT04:1, \
		 $BIT03:1,$BIT02:1,$BIT01:1,$BIT00:1
else
BITREC0  record  $BIT15:1,$BIT14:1,$BIT13:1,$BIT12:1, \
		 $BIT11:1,$BIT10:1,$BIT09:1,$BIT08:1, \
		 $BIT07:1,$BIT06:1,$BIT05:1,$BIT04:1, \
		 $BIT03:1,$BIT02:1,$BIT01:1,$BIT00:1
endif				; IF (@Cpu AND 1000b)

.xcref @BIT15,@BIT14,@BIT13,@BIT12,@BIT11,@BIT10,@BIT09,@BIT08
.xcref @BIT07,@BIT06,@BIT05,@BIT04,@BIT03,@BIT02,@BIT01,@BIT00
@BIT15	 equ	 00008000h
@BIT14	 equ	 00004000h
@BIT13	 equ	 00002000h
@BIT12	 equ	 00001000h
@BIT11	 equ	 00000800h
@BIT10	 equ	 00000400h
@BIT09	 equ	 00000200h
@BIT08	 equ	 00000100h
@BIT07	 equ	 00000080h
@BIT06	 equ	 00000040h
@BIT05	 equ	 00000020h
@BIT04	 equ	 00000010h
@BIT03	 equ	 00000008h
@BIT02	 equ	 00000004h
@BIT01	 equ	 00000002h
@BIT00	 equ	 00000001h

.xcref @BIT7,@BIT6,@BIT5,@BIT4,@BIT3,@BIT2,@BIT1,@BIT0

@BIT7	 equ	 80h
@BIT6	 equ	 40h
@BIT5	 equ	 20h
@BIT4	 equ	 10h
@BIT3	 equ	 08h
@BIT2	 equ	 04h
@BIT1	 equ	 02h
@BIT0	 equ	 01h

BITREC1  record  $BIT7:1,$BIT6:1,$BIT5:1,$BIT4:1, \
		 $BIT3:1,$BIT2:1,$BIT1:1,$BIT0:1

if (@Cpu and 1000b)		; If 80386 instructions
.xcref @NIB7,@NIB6,@NIB5,@NIB4
@NIB7	 equ	 0F0000000h
@NIB6	 equ	 00F000000h
@NIB5	 equ	 000F00000h
@NIB4	 equ	 0000F0000h
endif				; IF (@Cpu AND 1000b)

.xcref @NIB3,@NIB2,@NIB1,@NIB0
@NIB3	 equ	 00000F000h
@NIB2	 equ	 000000F00h
@NIB1	 equ	 0000000F0h
@NIB0	 equ	 00000000Fh


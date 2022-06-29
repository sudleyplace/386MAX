;' $Header:   P:/PVCS/MAX/INC/SCANCODE.INV   1.1   18 Jul 1997 12:31:18   BOB  $
;
; (C) Copyright 1987-97 Qualitas, Inc.	All rights reserved.
;
; SCANCODE.INC
;
; Equates for AT keyboard make system scan codes
;

;-----------------------------------------------------------------
;				    Key
;		   System	  Position   Keyboard	 Key
;		  Scan Code 1	   84	101  Scan Code	 Name
;-----------------------------------------------------------------
@SSC_BACKQUOTE	equ  29h	;   1		DE*	 Backquote
@SSC_1		equ  02h	;   2		16	 1
@SSC_2		equ  03h	;   3		1E	 2
@SSC_3		equ  04h	;   4		26	 3
@SSC_4		equ  05h	;   5		25	 4
@SSC_5		equ  06h	;   6		2E	 5
@SSC_6		equ  07h	;   7		36	 6
@SSC_7		equ  08h	;   8		3D	 7
@SSC_8		equ  09h	;   9		3E	 8
@SSC_9		equ  0Ah	;  10		46	 9
@SSC_0		equ  0Bh	;  11		45	 0
@SSC_MINUS	equ  0Ch	;  12		4E	 Minus
@SSC_EQUAL	equ  0Dh	;  13		55	 Equal
@SSC_BSLASH	equ  2Bh	;  14		5D	 Backslash
@SSC_BACK	equ  0Eh	;  15		66	 Backspace
@SSC_TAB	equ  0Fh	;  16		0D	 Tab
@SSC_Q		equ  10h	;  17		15	 Q
@SSC_W		equ  11h	;  18		1D	 W
@SSC_E		equ  12h	;  19		24	 E
@SSC_R		equ  13h	;  20		2D	 R
@SSC_T		equ  14h	;  21		2C	 T
@SSC_Y		equ  15h	;  22		35	 Y
@SSC_U		equ  16h	;  23		3C	 U
@SSC_I		equ  17h	;  24		43	 I
@SSC_O		equ  18h	;  25		44	 O
@SSC_P		equ  19h	;  26		4D	 P
@SSC_LBR	equ  1Ah	;  27		54	 Left Bracket
@SSC_RBR	equ  1Bh	;  28		5B	 Right Bracket

@SSC_CTRL	equ  1Dh	;  30		14	 Control
@SSC_A		equ  1Eh	;  31		1C	 A
@SSC_S		equ  1Fh	;  32		1B	 S
@SSC_D		equ  20h	;  33		23	 D
@SSC_F		equ  21h	;  34		2B	 F
@SSC_G		equ  22h	;  35		34	 G
@SSC_H		equ  23h	;  36		33	 H
@SSC_J		equ  24h	;  37		3B	 J
@SSC_K		equ  25h	;  38		42	 K
@SSC_L		equ  26h	;  39		4B	 L
@SSC_SEMI	equ  27h	;  40		4C	 Semicolon
@SSC_QUOTE	equ  28h	;  41		52	 Quote

@SSC_ENTER	equ  1Ch	;  43		5A	 Enter
@SSC_LSHFT	equ  2Ah	;  44		12	 Left Shift

@SSC_Z		equ  2Ch	;  46		1A	 Z
@SSC_X		equ  2Dh	;  47		22	 X
@SSC_C		equ  2Eh	;  48		21	 C
@SSC_V		equ  2Fh	;  49		2A	 V
@SSC_B		equ  30h	;  50		32	 B
@SSC_N		equ  31h	;  51		31	 N
@SSC_M		equ  32h	;  52		3A	 M
@SSC_COMMA	equ  33h	;  53		41	 Comma
@SSC_PERIOD	equ  34h	;  54		49	 Period
@SSC_SLASH	equ  35h	;  55		4A	 Slash

@SSC_RSHFT	equ  36h	;  57		59	 Right Shift
@SSC_ALT	equ  38h	;  58		11	 Alt

@SSC_SPACE	equ  39h	;  61		29	 Space

@SSC_CAPS	equ  3Ah	;  64		58	 Caps Lock
@SSC_F2 	equ  3Ch	;  65		D6*	 F2
@SSC_F4 	equ  3Eh	;  66		DC*	 F4
@SSC_F6 	equ  40h	;  67		0B	 F6
@SSC_F8 	equ  42h	;  68		0A	 F8
@SSC_F10	equ  44h	;  69		09	 F10
@SSC_F1 	equ  3Bh	;  70		05	 F1
@SSC_F3 	equ  3Dh	;  71		04	 F3
@SSC_F5 	equ  3Fh	;  72		D3*	 F5
@SSC_F7 	equ  41h	;  73		02/83	 F7
@SSC_F9 	equ  43h	;  74		01	 F9

@SSC_ESC	equ  01h	;  90		76	 Escape
@SSC_HOME	equ  47h	;  91		6C	 Home
@SSC_LEFT	equ  4Bh	;  92		6B	 Left
@SSC_END	equ  4Fh	;  93		69	 End
@SSC_NUMLOCK	equ  45h	;  95		77	 Num Lock
@SSC_UP 	equ  48h	;  96		75	 Up
@SSC_PAD5	equ  4Ch	;  97		73	 Pad5
@SSC_DN 	equ  50h	;  98		72	 Down
@SSC_INS	equ  52h	;  99		70	 Insert
@SSC_SCROLL	equ  46h	; 100		7E	 Scroll Lock
@SSC_PGUP	equ  49h	; 101		7D	 Page Up
@SSC_RIGHT	equ  4Dh	; 102		74	 Right
@SSC_PGDN	equ  51h	; 103		7A	 Page Down
@SSC_DEL	equ  53h	; 104		71	 Delete
@SSC_SYSREQ	equ  54h	; 105		7F/84	 System Request
@SSC_PADSTAR	equ  37h	; 106		7C	 Pad Star
@SSC_PADMINUS	equ  4Ah	; 107		7B	 Pad Minus
@SSC_PADPLUS	equ  4Eh	; 108		79	 Pad Plus

@SSC_F11	equ  57h	;   -	122	D9	 F11
@SSC_F12	equ  58h	;   -	123	DA	 F12

@SSC_LWIN	equ  5Bh	;   -	???	??	 Left Windows
@SSC_RWIN	equ  5Ch	;   -	???	??	 Right ...
@SSC_AWIN	equ  5Dh	;   -	???	??	 Application

@SSC_E0 	equ 0E0h	; General marker code
@SSC_E1 	equ 0E1h	; General marker code


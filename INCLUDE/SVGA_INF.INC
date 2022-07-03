;' $Header:   P:/PVCS/MAX/INCLUDE/SVGA_INF.INV   1.0   05 Sep 1995 13:30:18   HENRY  $
;
; (C) Copyright 1991-1992 Qualitas, Inc.  GNU General Public License version 3.
;
; SVGA_INF.INC
;
; Macros and EQUates for Super VGA detection code in SVGA_INF.ASM
;

COMMENT |

Original code by: Henry Groover, April 1991

|

.xcref VENDOR_UNK, ATI, TRIDENT, VIDEO7, PARADISE, TSENG, CHIPS
.xcref GENOA, VESA, AHEAD, ORCHID, CIRRUS, S3_INC, DIAMOND
.xcref VENDOR_UNDEF
VENDOR_UNK	 EQU	0
ATI		 EQU	1
TRIDENT 	 EQU	2
VIDEO7		 EQU	3
PARADISE	 EQU	4
TSENG		 EQU	5
CHIPS		 EQU	6
GENOA		 EQU	7
VESA		 EQU	8
AHEAD		 EQU	9
ORCHID		 EQU	10
CIRRUS		 EQU	11
S3_INC		 EQU	12
DIAMOND 	 EQU	13
STB		 EQU	14
VENDOR_UNDEF	 EQU	-1

.xcref MODEL_UNK
.xcref ATI_18800, ATI_28800
.xcref TRIDENT_8800, TRIDENT_8900
.xcref VIDEO7_VEGA, VIDEO7_FASTWRITE, VIDEO7_V7VGAv5, VIDEO7_1024i
.xcref PARADISE_PVGA1a, PARADISE_WD90C00, PARADISE_WD90C10, PARADISE_WD90C11
.xcref TSENG_ET3000, TSENG_ET4000
.xcref CHIPS_82C451, CHIPS_82C452, CHIPS_82C453, CHIPS_82C455, CHIPS_82C456
.xcref VESA_OEM, VESA_128
.xcref GENOA_5000, GENOA_GVGA
.xcref AHEAD_A, AHEAD_B
.xcref S3_86C911
.xcref DIAMOND_SS
.xcref MODEL_UNDEF
MODEL_UNK	 EQU	 0
ATI_18800	 EQU	 1
 ATI_28800	 EQU	 2
TRIDENT_8800	 EQU	 1
 TRIDENT_8900	 EQU	 2
VIDEO7_VEGA	 EQU	 1
 VIDEO7_FASTWRITE EQU	 2
 VIDEO7_V7VGAv5  EQU	 3
 VIDEO7_1024i	 EQU	 4
PARADISE_PVGA1a  EQU	 1
 PARADISE_WD90C00 EQU	 2
 PARADISE_WD90C10 EQU	 3
 PARADISE_WD90C11 EQU	 4
TSENG_ET3000	 EQU	 1
 TSENG_ET4000	 EQU	 2
CHIPS_82C451	 EQU	 1
 CHIPS_82C452	 EQU	 2
 CHIPS_82C453	 EQU	 3
 CHIPS_82C455	 EQU	 4
 CHIPS_82C456	 EQU	 5
GENOA_5000	 EQU	 1
 GENOA_GVGA	 EQU	 2
VESA_OEM	 EQU	 1
 VESA_128	 EQU	 2
AHEAD_A 	 EQU	 1
 AHEAD_B	 EQU	 2
S3_86C911	 EQU	 1
DIAMOND_SS	 EQU	 1
STB_ET4000	 EQU	 1
 STB_S3 	 EQU	 2
MODEL_UNDEF	 EQU	 -1

; macros for writing to and reading from ports

@8042_ST equ	 64h		; Status port
; Delay after port I/O
IODELAY  macro
	 push	 ax
	 in	 al,@8042_ST
	 pop	 ax
	 endm		; IODELAY

; write IOBYTE to port IOADDR
OUTP	 macro	 IOADDR, IOBYTE
	 IFDIFI  <dx>, <IOADDR>
	 mov	 dx, IOADDR
	 ENDIF			; dx != IOADDR
	 IFDIFI  <al>, <IOBYTE>
	 mov	 al, IOBYTE
	 ENDIF			; al != IOBYTE
	 out	 dx, al
	 IODELAY
	 endm		; OUTP

; read AL in from IOADDR
INP	 macro	 IOADDR
	IFDIFI	 <dx>, <IOADDR>
	 mov	 dx, IOADDR
	ENDIF			; dx != IOADDR
	 in	 al, dx
	 IODELAY
	 endm		; INP

; inc DX and write IOBYTE to DX
OUTNP	 macro	 IOBYTE
	 inc	 dx
	IFDIFI	 <al>, <IOBYTE> ; al != IOBYTE
	 mov	 al, IOBYTE
	ENDIF
	 out	 dx, al
	 IODELAY
	 endm		; OUTNP

; inc DX and read AL in from DX
INNP	 macro
	 inc	 dx
	 in	 al, dx
	 IODELAY
	 endm		; INNP

; Push an immediate value
PUSHAX	 macro	 IMM16
	 mov	 ax,IMM16
	 push	 ax
	 endm		; PUSHAX

; Argument structures
CARG_STR	struc
	ourbp	dw	?	; BP saved locally on stack
if @codesize
	callret dd	?	; caller's far return address
else
	callret dw	?	; near return address
endif
	arg1w	dw	?	; WORD argument 1
CARG_STR	ends

; Vendor information pointer structures
VINFO_STR	struc
VINFO_ID	 dw	 ?	; pointer to ASCIIZ string for vendor name
VINFO_MTAB	 dw	 ?	; pointer to table of model ID pointers
VINFO_FTAB	 dw	 ?	; pointer to table of function entry points
VINFO_MLEN	 db	 ?	; highest model number for this vendor
VINFO_FLEN	 db	 ?	; highest supported function for this vendor
VINFO_STR	ends

VINFO_SHL	 equ	 3	; number of bits to shift left for equivalent
				; to multiplying by (SIZE VINFO_STR)

; Function table structure
FUNT_STR	struc
FUNT_FN0	dw	?	; Offset of function 0 entry point
FUNT_STR	ends


;' $Header:   P:/PVCS/MAX/VXD/VMAX_DBG.ASV   1.0   05 Sep 1995 17:21:08   HENRY  $
	 title	 VMAX_DBG -- Windows 3 VxD Debugging Functions
	 page	 78,130
	 name	 VMAX_DBG

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-94 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group _IGROUP:
	       Program segment _ITEXT,	dword-aligned,	use32,	public, 'ICODE'
	       Data    segment _IDATA,	dword-aligned,	use32,	public, 'ICODE'

	       Group _LGROUP:
	       Program segment _LTEXT,	dword-aligned,	use32,	public, 'CODE'
	       Data    segment _LDATA,	dword-aligned,	use32,	public, 'CODE'

	       Group _PGROUP:
	       Program segment _TEXT,	dword-aligned,	use32,	public, 'PCODE'
	       Data    segment _DATA,	dword-aligned,	use32,	public, 'PCODE'

	       Segment	       _RCODE,	word-aligned,	use16,	public, 'RCODE'

Program derived from:  None.

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK

	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include ASCII.INC
	 include MAXDEV.INC

	 include WINDEVID.INC	; From \INCLUDE
	 include SWATVXD.INC	; Define service table
	 include VMAX.INC
.list

VxD_REAL_INIT_SEG		; Begin _RCODE segment
	 assume  cs:_RCODE	; Tell the assembler

RMI_HEX  db	 '0123456789ABCDEF' ; ASCII HEX translate table

BeginProc RMI_TOHEX,PUBLIC	; Format EAX into ASCII HEX digits
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Format EAX into ASCII hex digits.

On entry:

EAX	 =	  Number to format
CX	 =	  Number of digits desired
DS:DI	 =>	  Output area for digits

|

	 REGSAVE <eax,dx,si>	; Save caller's registers

	 mov	 dx,cx		; Copy number of digits

	 shl	 cx,2		; Times 4 to get bits-per-digit
	 ror	 eax,cl 	; Rotate interesting bits around

	 mov	 cx,dx		; Restore number of digits

@@:
	 rol	 eax,4		; Move next nibble to low end
	 mov	 si,ax		; Copy to S
	 and	 si,15		; Kill everything but lowest nibble
	 mov	 dl,RMI_HEX[si] ; Form ASCII hex digit
	 mov	 [di],dl	; Store into output stream
	 inc	 di		; Bump output pointer
	 loop	 @B		; Continue with remainder of digits

	 REGREST <si,dx,eax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_TOHEX		; End RMI_TOHEX procedure

ifdef @DEBUG
	 page
BeginProc RMI_TODEC,PUBLIC	; Format AX into ASCII decimal
	 assume  ds:_RCODE, es:nothing, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Format AX into ASCII decimal digits.

On entry:

AX	 =	  Number to format
CX	 =	  Number of digits desired
DS:DI	 =>	  Output area for digits

|

	 REGSAVE <ax,bx,dx>	; Save caller's registers

	 push	 cx		; Save number of digits

	 add	 di,cx		; Bump to last digit position + 1
	 dec	 di		; DI ==> last digit

	 mov	 bx,10		; Base for conversion
@@:
	 sub	 dx,dx		; Clear for divide
	 div	 bx		; Divide by base
	 add	 dl,'0'         ; Form ASCII digit from remainder

	 mov	 [di],dl	; Store into output area
	 dec	 di		; Bump to next position (backwards)

	 loop	 @B		; Do the next digit

; Take care of leading zeroes

	 pop	 cx		; Get original # of digits

;;;;;;	 dec	 cx		; Leave at least one zero
;;;;;;
;;;;;;@@:	 inc	 di		; Advance back to last digit stored
;;;;;;	 cmp	 [di].LO,'0'    ; Is it a zero?
;;;;;;	 jne	 short @F	; No, exit loop
;;;;;;
;;;;;;	 mov	 [di].LO,' '    ; Blank out leading zero
;;;;;;
;;;;;;	 loop	 @B		; Continue
;;;;;;@@:
	 REGREST <dx,bx,ax>	; Restore caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  RMI_TODEC		; End RMI_TODEC procedure
endif				; IFDEF @DEBUG

VxD_REAL_INIT_ENDS		; End _RCODE segment
	 page
VxD_LOCKED_DATA_SEG		; Begin _LDATA segment

	 include VMAX_DBG.INC
	 public  DBG_FLAG
DBG_FLAG dw	 0		; Flags to control the debugging system

	 db	 '(C) Copyright 1990-94 Qualitas, Inc.  GNU General Public License version 3.'

VxD_LOCKED_DATA_ENDS		; End _LDATA segment
	 page
VxD_CODE_SEG			; Begin _TEXT segment
	 assume  cs:FLAT		; Tell the assembler

BeginProc DISPLAY			; Display String on Debugging Screen
COMMENT|

Input:
	DS:ESI	-->	Null-terminated string to be displayed
			CR and LF characters are not displayed

|

	 push	 esi			; Save ==> message text
	 VxDcall SWAT_Get_Version	; Is SWATVXD installed?
	 pop	 esi			; Restore ==> message text
	 jc	 short @F		; Nope

	 VxDcall SWAT_Out_Mono_String	; Display it
@@:
	 ret

EndProc  DISPLAY			; End DISPLAY procedure
	 page
BeginProc TOHEX 		; Binary to ASCII HEX Conversion
COMMENT|

Format EAX into ASCII hex digits.

On entry:

EAX	 =	  Number to format
ECX	 =	  Number of digits desired
DS:EDI	 =>	  Output area for digits

|

	 REGSAVE <eax,ecx,edx,esi> ; Save caller's registers

	 mov	 edx,ecx	; Copy number of digits
	 shl	 ecx,2		; Times 4 to get bits-per-digit
	 ror	 eax,cl 	; Rotate interesting bits around
	 mov	 ecx,edx	; Restore number of digits

@@:
	 rol	 eax,4		; Move next nibble to low end
	 mov	 si,ax		; Copy to SI
	 and	 esi,15 	; Kill everything but lowest nibble
	 mov	 dl,HEX[esi]	; Form ASCII hex digit
	 mov	 [edi],dl	; Store into output stream
	 inc	 edi		; Bump output pointer
	 loop	 @B		; Continue with remainder of digits

	 REGREST <esi,edx,ecx,eax>	; Restore caller's registers

	 ret			; Return to caller

EndProc  TOHEX			; End TOHEX procedure

ifdef @DEBUG
	 page
BeginProc SHOW_CRS		; Show the ClientRegisterStructure
	 assume  ds:FLAT, es:FLAT, fs:nothing, gs:nothing, ss:nothing
COMMENT|

Entry:
	EBP	==>	ClientRegisterStructure

|

	 REGSAVE <eax,ecx,esi,edi> ; Save caller's registers

	 mov	 ecx,8			; # of digits

	 lea	 edi,MSG_SCR_EAX	; Offset to hex display area
	 mov	 eax,[ebp].Client_EAX	; Get V86 client's EAX
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_EBX	; Offset to hex display area
	 mov	 eax,[ebp].Client_EBX	; Get V86 client's EBX
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_ECX	; Offset to hex display area
	 mov	 eax,[ebp].Client_ECX	; Get V86 client's ECX
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_EDX	; Offset to hex display area
	 mov	 eax,[ebp].Client_EDX	; Get V86 client's EDX
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_ESI	; Offset to hex display area
	 mov	 eax,[ebp].Client_ESI	; Get V86 client's ESI
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_EDI	; Offset to hex display area
	 mov	 eax,[ebp].Client_EDI	; Get V86 client's EDI
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_EBP	; Offset to hex display area
	 mov	 eax,[ebp].Client_EBP	; Get V86 client's EPX
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_ESP	; Offset to hex display area
	 mov	 eax,[ebp].Client_ESP	; Get V86 client's ESP
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_EIP	; Offset to hex display area
	 mov	 eax,[ebp].Client_EIP	; Get V86 client's EIP
	 call	 TOHEX			; Form ASCII HEX from EAX

	 mov	 ecx,4			; # of digits in segments registers

	 lea	 edi,MSG_SCR_CS 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_CS	; Get V86 client's CS
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_DS 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_DS	; Get V86 client's DS
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_ES 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_ES	; Get V86 client's ES
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_FS 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_FS	; Get V86 client's FS
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_GS 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_GS	; Get V86 client's GS
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 edi,MSG_SCR_SS 	; Offset to hex display area
	 movzx	 eax,[ebp].Client_SS	; Get V86 client's SS
	 call	 TOHEX			; Form ASCII HEX from EAX

	 lea	 esi,MSG_SCR_R1 	; Show EAX, EBX, ECX, and EDX
	 call	 DISPLAY

	 lea	 esi,MSG_SCR_R2 	; Show ESI, EDI, EBP, and ESP
	 call	 DISPLAY

	 lea	 esi,MSG_SCR_R3 	; Show DS, ES, FS, and GS
	 call	 DISPLAY

	 lea	 esi,MSG_SCR_R4 	; Show CS:EIP and SS:ESP
	 call	 DISPLAY

	 REGREST <edi,esi,ecx,eax> ; Save caller's registers

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, fs:nothing, gs:nothing, ss:nothing

EndProc  SHOW_CRS		; End SHOW_CRS procedure
endif				; IFDEF @DEBUG

VxD_CODE_ENDS			; End _TEXT segment

	 page
VxD_DATA_SEG			; Begin _DATA segment

HEX	 db	 '0123456789ABCDEF'

MSG_HEX4		db	'xxxx', 0
MSG_HEX8		db	'xxxxxxxx', 0

MSG_DUMP	db	' '
MSG_DUMP_1	db	'xxxx '
MSG_DUMP_2	db	'xxxx '
MSG_DUMP_3	db	'xxxx '
MSG_DUMP_4	db	'xxxx '
		db	0

MSG_IDT 	db	'IDTR = '
MSG_IDT_BASE	db	'xxxxxxxx '
MSG_IDT_LIM	db	'xxxx', 0

; Message text for SHOW_CRS debugging procedure

MSG_SCR_R1	db	'    EAX='
MSG_SCR_EAX	db	'xxxxxxxx  EBX='
MSG_SCR_EBX	db	'xxxxxxxx  ECX='
MSG_SCR_ECX	db	'xxxxxxxx  EDX='
MSG_SCR_EDX	db	'xxxxxxxx', 0

MSG_SCR_R2	db	'    ESI='
MSG_SCR_ESI	db	'xxxxxxxx  EDI='
MSG_SCR_EDI	db	'xxxxxxxx  EBP='
MSG_SCR_EBP	db	'xxxxxxxx', 0

MSG_SCR_R3	db	'    DS='
MSG_SCR_DS	db	'xxxx       ES='
MSG_SCR_ES	db	'xxxx       FS='
MSG_SCR_FS	db	'xxxx       GS='
MSG_SCR_GS	db	'xxxx', 0

MSG_SCR_R4	db	'    CS:EIP='
MSG_SCR_CS	db	'xxxx:'
MSG_SCR_EIP	db	'xxxxxxxx        SS:ESP='
MSG_SCR_SS	db	'xxxx:'
MSG_SCR_ESP	db	'xxxxxxxx',0

VxD_DATA_ENDS			; End _DATA segment

	 end				; End VMAX_DBG module

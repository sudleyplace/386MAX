;'$Header:   P:/PVCS/MAX/EXTRADOS/HARP_MSC.ASV   1.1   30 May 1997 11:13:16   BOB  $
	 title	 HARP_MSC -- Miscellaneous routines for HARPO
	 page	 58,122
	 name	 HARP_MSC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-7 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  dword-aligned,public, class 'data'
	       Stack   segment STACK, para-aligned, stack,  class 'stack'

|
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include VERSION.INC

	 include SEGS.INC
	 include HARPO.INC
.list


;*******************************************************************


HCODE	 segment		; Start Resident Code segment

extern	 DATASEG:word		; Our Data Segment

;--------------- Messages --------------------------

extern	 MSG_PAUSE:byte

;---------------- Miscellaneous ---------------------

	 public  HEXTABLE
HEXTABLE   db	 '0123456789ABCDEF' ; Used for display routines



;*****************************************************************************

	  NPPROC  FMT_WORD -- Format AX to Hex at ES:DI
	  assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Format AX to Hex at ES:DI

|

	  REGSAVE <ax,bx,cx,dx>  ; Save registers

	  lea	  bx,HEXTABLE	 ; DS:BX ==> translate table
	  mov	  cx,4		 ; # hex digits in a word
	  mov	  dx,ax 	 ; Copy to test
FMT_WORD1:
	  rol	  dx,1		 ; Copy the high-order digit
	  rol	  dx,1		 ; Copy the high-order digit
	  rol	  dx,1		 ; Copy the high-order digit
	  rol	  dx,1		 ; Copy the high-order digit
	  mov	  al,dl 	 ; Copy to XLAT register
	  and	  al,0Fh	 ; Isolate hex digit
	  xlat	  HEXTABLE	 ; Translate to ASCII
	  stosb 		 ; Save into output area

	  loop	  FMT_WORD1	 ; Jump if more digits to convert

	  REGREST <dx,cx,bx,ax>  ; Restore

	  ret			 ; Return to caller

	  assume  ds:nothing,es:nothing,ss:nothing

FMT_WORD endp			 ; End FMT_WORD procedure


;***************************************************************************

if @MAX6
	 NPPROC  FMT_BASE10 -- Convert From Binary to Base 10
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

FMT_BASE -- Convert the number in EAX to ASCII in base 10 storing the
low-order digit of the # at ES:DI.

On entry:
AX	 =	 Number that needs to be displayed
ES:DI	 ==>	 next byte to left of the number

Note :

Maximum Hex number is	  FFFF FFFF
	Dec ...       4,294,967,295

|

	 REGSAVE <ax,bx,cx,dx,si,bp,ds> ; Save all registers

; Initialize segment registers

	 push	 cs		; Address our non-resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

; Setup the conversion

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB
	 mov	 cx,10		; Set up BASE as decimal (Base 10)
	 mov	 bp,8		; Go through (up to) this many times

; Perform the conversion (place each byte in display)

FMT_BASE_LOOP:
	 xor	 dx,dx		; Zero high-order dword for division

	 div	 cx		; Divide (DX:AX / CX => AX Rem DX)
	 lea	 si,HEXTABLE	; Get address of table
	 add	 si,dx		; Offset into table

	 movsb			; Store in result
	 nop			; S16 macro

	 and	 ax,ax		; Check for zero quotient
	 jz	 short FMT_BASE_EXIT ; That's all folks

	 dec	 bp		; Check for last digit
	 jnz	 short FMT_BASE_LOOP ; Not done yet
FMT_BASE_EXIT:
	 popf			; Restore flags

	 REGREST <ds,bp,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FMT_BASE10 endp 		; End FMT_BASE10 procedure
endif				; IF @MAX6

;****************************************************************************

	 NPPROC  PRESSANY -- Press Any Key To Continue
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Pause to allow the user to read the error message.

|

	 REGSAVE <ax,dx,ds>	; Save registers

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ah,@STROUT	; DOS: Print String function (09h)
	 lea	 dx,MSG_PAUSE	; "Press any Key to continue" message
	 int	 21h		; Tell 'em to PAK

; Purge the keyboard buffer and wait for a key press -- discard the key

	 call	 KEYWAIT	; Wait for an acknowledgement
				; Return with key in AX

	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

PRESSANY endp			; End PRESSANY procedure


;****************************************************************************

	 NPPROC  KEYWAIT -- Wait For Keyboard Acknowledgement
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Purge the keyboard buffer and wait for a key press -- discard the key

On exit:

AX	 =	 last key pressed

|

KEYWAIT_NEXT:
	 KEYCALL @GETKST	; Get buffer state
	 jz	 short KEYWAIT_PAUSE ; Nothing available

	 KEYCALL @GETKEY	; Get the key

	 jmp	 KEYWAIT_NEXT	; Go around again

KEYWAIT_PAUSE:
	 KEYCALL @GETKEY	; Get the key

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

KEYWAIT  endp			; End KEYWAIT procedure


;****************************************************************************

HCODE	 ends			; End Resident Code segment

;****************************************************************************

HDATA	 segment		; Start Non-Resident Data segment

; These variables are all non-resident !!!


;--------------- Miscellaneous --------------------

	 public  NUMBERS_LO
NUMBERS_LO db	 '0123456789abcdef' ; Conversion table for BASE2BIN



HDATA	 ends			; End Non-Resident Data segment


;****************************************************************************

HNCODE	 segment		; Start Non-Resident CODE segment
	 assume  cs:PGROUP


;***************************************************************************

	 NPPROC  CHECK_ALTKEY -- CHECK_ALTKEY Procedure
	 assume  ds:nothing,es:nothing,ss:nothing

COMMENT |

Abort if the Alt key is pressed

On exit:
CF	=	1 if the Alt key is pressed
		0 if not

|

	 REGSAVE <ax>		; Save registers

	 KEYCALL @GETSHF	; Get shift status flags in AL

	 test	 al,mask $DCTL	; Is the Ctl key pressed?
	 jz	 short @F	; Jump if not

	 int	 03h		; Call the debugger
@@:
	 test	 al,mask $DALT	; Is the Alt key pressed?
	 jz	 CHECK_ALTKEY_EXIT ; Jump if not (Note: CF=0)

	 stc			; Indicate Alt key is pressed

CHECK_ALTKEY_EXIT:
	 REGREST <ax>		; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_ALTKEY endp		; End CHECK_ALTKEY procedure


;****************************************************************************

	 NPPROC  LOWERCASE -- Convert AL to Lowercase
	 assume  ds:nothing,es:nothing,ss:nothing

	 cmp	 al,40h 	; Test for conversion of alpha to lower case
	 jb	 short @F	; Not this time

	 or	 al,20h 	; Convert alpha to lower case
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure


;*************************************************************************

	 NPPROC  UPPERCASE -- Convert to Uppercase
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert to uppercase

On entry:
AL	 =	 ASCII value

On exit:
AL	 =	 uppercase version of input

|

	 cmp	 al,'a'         ; Check against lower limit
	 jb	 short UPPERCASE_EXIT ; Jump if too small

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short UPPERCASE_EXIT ; Jump if too large

	 add	 al,'A'-'a'     ; Convert to uppercase
UPPERCASE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

UPPERCASE endp			; End UPPERCASE procedure


;****************************************************************************

	 NPPROC  SKIP_WHITE -- Skip Over White Space
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Skip over white space and return the last
character in AL.

On entry:

DS:SI	 ==>	 command line

On exit:

DS:SI	 ==>	 command line (updated)
AL	 =	 lower case last character

|

	 lodsb			; Get the next byte

	 cmp	 al,' '         ; Check for blank
	 je	 short SKIP_WHITE ; Jump if so

	 cmp	 al,TAB 	; Check for TAB
	 je	 short SKIP_WHITE ; Jump if so

	 call	 LOWERCASE	; Convert to lowercase

	 ret			; Return to caller with next byte in AL

	 assume  ds:nothing,es:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure


;****************************************************************************

	 NPPROC  SKIP_BLACK -- Skip Over Black Space
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Skip over black space and return the last
character in AL.

On entry:

DS:SI	 ==>	 command line

On exit:

DS:SI	 ==>	 command line (updated)
AL	 =	 last character

|

@@:
	 lodsb			; Get the next byte

	 cmp	 al,' '         ; Check for above blank
	 ja	 short @B	; Jump if so

	 ret			; Return to caller with next byte in AL

	 assume  ds:nothing,es:nothing,ss:nothing

SKIP_BLACK endp 		; End SKIP_BLACK procedure


;*****************************************************************************
if 0 ;====================
	  NPPROC  FMT_BYTE -- Format AL to Hex at ES:DI
	  assume  ds:nothing,es:DGROUP,ss:nothing

	  REGSAVE <ax,bx,cx,dx>  ; Save registers

	  lea	  bx,HEXTABLE	 ; DS:BX ==> translate table
	  mov	  cx,2		 ; # hex digits in a word
	  mov	  dx,ax 	 ; Copy to test
FMT_BYTE1:
	  rol	  dl,1		 ; Copy the high-order digit
	  rol	  dl,1		 ; Copy the high-order digit
	  rol	  dl,1		 ; Copy the high-order digit
	  rol	  dl,1		 ; Copy the high-order digit
	  mov	  al,dl 	 ; Copy to XLAT register
	  and	  al,0Fh	 ; Isolate hex digit
	  xlat	  HEXTABLE	 ; Translate to ASCII
	  stosb 		 ; Save into output area

	  loop	  FMT_BYTE1	 ; Jump if more digits to convert

	  REGREST <dx,cx,bx,ax>  ; Restore

	  ret			 ; Return to caller

	  assume  ds:nothing,es:nothing,ss:nothing

FMT_BYTE endp			 ; End FMT_BYTE procedure
endif ;==============

;****************************************************************************

	 NPPROC  BASE2BIN -- Convert From Specified Base to Binary
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

BASE2BIN -- Convert the number at DS:SI in base CX to binary.
The converted # is returned in AX.

On entry:

CX	 =	 number base
DS:SI	 ==>	 input save area

On exit:

CF	 =	 1 if overflow
	 =	 0 if OK
AX	 =	 converted #

|

	 REGSAVE <bx,dx,di,es>	; Save registers

	 mov	 es,DATASEG	; Setup addressibility to DGROUP
	 assume  es:DGROUP	; Tell the assembler about it

	 xor	 bx,bx		; Zero accumulator
BASE2BIN_START:
	 lodsb			; Get next digit
	 call	 LOWERCASE	; Convert to lowercase

	 lea	 di,NUMBERS_LO	; Get address of number conversion table
	 push	 cx		; Save number base (and table length)
   repne scas	 NUMBERS_LO[di] ; Look for the character
	 pop	 cx		; Restore number base
	 jne	 short BASE2BIN_DONE ; Not one of ours

	 sub	 di,1+offset DGROUP:NUMBERS_LO ; Convert to origin 0
	 mov	 ax,bx		; Copy old to multiply by base

	 mul	 cx		; Shift over accumulated #
	 jnc	 short BASE2BIN_ADD ; Jump if within range

; Allow overflow if 'Keyword=10000'

	 dec	 dx		; Check for DX=1
	 jnz	 short BASE2BIN_OVF ; Not this time

	 and	 di,di		; Check for new digit
	 jnz	 short BASE2BIN_OVF ; Not this time

	 cmp	 BPTR ds:[si],'0' ; Check against lower range
	 jb	 short BASE2BIN_ADD ; Jump if not a digit

	 cmp	 BPTR ds:[si],'9' ; Check against upper range
	 jbe	 short BASE2BIN_OVF ; Jump if it's a digit
BASE2BIN_ADD:
	 mov	 bx,ax		; Copy back
	 add	 bx,di		; Add in new #
	 jnc	 short BASE2BIN_START ; Jump if still within range
BASE2BIN_OVF:
	 stc			; Indicate something went wrong

	 jmp	 short BASE2BIN_EXIT ; Join common exit code

BASE2BIN_DONE:
	 dec	 si		; Back off to previous character
	 mov	 ax,bx		; Place result in accumulator

	 clc			; Indicate all went well
BASE2BIN_EXIT:
	 REGREST <es,di,dx,bx>	; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller with number in AX

	 assume  ds:nothing,es:nothing,ss:nothing

BASE2BIN endp			; End BASE2BIN procedure


;****************************************************************************

DOT386
	 NPPROC  BASE2BIND -- Convert From Specified Base to Binary
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BASE2BIND -- Convert the number at DS:SI in base CX to binary.
The converted # is returned in EAX.

On entry:

CX	 =	 number base
DS:SI	 ==>	 input save area

On exit:

CF	 =	 1 if overflow
	 =	 0 if OK
EAX	 =	 converted #

|

	 REGSAVE <ebx,ecx,edx,edi,es> ; Save registers

	 mov	 es,DATASEG	; Setup addressibility to DGROUP
	 assume  es:DGROUP	; Tell the assembler about it

	 xor	 ebx,ebx	; Zero accumulator
	 movzx	 ecx,cx 	; Zero to use as dword

BASE2BIND_LOOP:
	 lodsb			; Get next digit
	 call	 LOWERCASE	; Convert to lowercase

	 lea	 edi,NUMBERS_LO ; Get address of number conversion table
	 push	 cx		; Save number base (and table length)
   repne scas	 NUMBERS_LO[di] ; Look for the character
	 pop	 cx		; Restore number base
	 jne	 BASE2BIND_DONE ; Not one of ours

	 sub	 di,1+offset DGROUP:NUMBERS_LO ; Convert to origin 0
	 mov	 eax,ebx	; Copy old to multiply by base

	 mul	 ecx		; Shift over accumulated #
	 jc	 BASE2BIND_OVF	; Jump if out of range

	 mov	 ebx,eax	; Copy back
	 add	 ebx,edi	; Add in new #
	 jnc	 BASE2BIND_LOOP ; Go around again (if within range)

BASE2BIND_OVF:
	 stc			; Indicate something went wrong

	 jmp	 BASE2BIND_EXIT ; Join common exit code

BASE2BIND_DONE:
	 dec	 si		; Back off to previous character
	 mov	 eax,ebx	; Place result in accumulator

	 clc			; Indicate all went well
BASE2BIND_EXIT:
	 REGREST <es,edi,edx,ecx,ebx> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller with number in AX

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
.8086
BASE2BIND endp			; End BASE2BIND procedure


;****************************************************************************

HNCODE	 ends			; End Non-Resident Code segment


	 END			; End HARP_MSC module




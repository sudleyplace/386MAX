;' $Header:   P:/PVCS/MISC/VCPITEST/VCP_FLAG.INV   1.1   22 Feb 1994 12:32:06   HENRY  $


; Equates for CMD_FLAG

@CMD_SWAT   equ  8000h		; Enable 386SWAT debugger
@CMD_NOXLA  equ  4000h		; Skip check for invalid linear addresses
@CMD_BACKVCPI equ 2000h 	; Use 386MAX back door VCPI services

; Since we need CMD_FLAG for this macro, this seems an appropriate
; place to define it...
VCPIBACK macro	 FN
	 local	 L1,L2

ifnb <FN>
	 mov	 ax,@VCPI*0100h + FN ; Function code into AL
else
	 mov	 ah,@VCPI	; VCPI major function
endif				; IFNB <FN>

	 test	 CMD_FLAG,@CMD_BACKVCPI ; Using back door VCPI access?
	 jnz	 short L1	; Jump if so

	 int	 67h		; Request VCPI service
	 jmp	 short L2	; Join common code

L1:
	 EMMOUT 		; Use PORT67
L2:
	 endm			; VCPIBACK



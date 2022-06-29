;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_TEST.INV   1.1   06 Aug 1992 13:18:14   HENRY  $

; Common macros

SETMSG	 macro	 TXT,CODE
	 local	 LBL

	 mov	 ERRMSG,offset cs:LBL
ifnb <CODE>
	 mov	 ERRCODE,bl
else
	 mov	 ERRCODE,-1
endif				; IFNB

TEXT	 segment byte public 'data' ; Start TEXT segment
	 assume  ss:PGROUP

LBL	 db	 BEL,'ออ> ',TXT,CR,LF,EOS

	 assume  ss:nothing

TEXT	 ends			; End TEXT segment

	 endm			; SETMSG



DISPLAY  macro	 TXT
	 local	 LBL

TEXT	 segment byte public 'data' ; Start TEXT segment
	 assume  ss:PGROUP

LBL	 db	 TXT,CR,LF,EOS

	 assume  ss:nothing

TEXT	 ends			; End TEXT segment

	 REGSAVE <ax,dx>	; Save registers

	 DOSCALL @STROUT,LBL

	 REGREST <dx,ax>	; Restore

	 endm			; DISPLAY


SETLEN	 macro	 NUM,SD,LESS_KB,LESS_BYTE,PLUS_BYTE

	 mov	 ax,HNDL&NUM&_LEN ; Get length of handle #&NUM
	 sub	 ax,LESS_KB	; Less amount in KB
	 mov	 dx,ax		; Copy to shift
	 shl	 ax,10-0	; Convert from KB to bytes
	 shr	 dx,16-(10-0)	; Convert from KB to bytes

	 sub	 ax,LESS_BYTE	; Less amount in bytes
	 sbb	 dx,0

	 add	 ax,PLUS_BYTE	; Plus amount in bytes
	 adc	 dx,0

	 mov	 EXTMOVE.EXTMOVE_&SD&OFF.ELO,ax ; Offset is DX:AX
	 mov	 EXTMOVE.EXTMOVE_&SD&OFF.EHI,dx

	 endm			; SETLEN


; Common structures

EXTMOVE_STR struc

EXTMOVE_LEN dd	 ?		; Length of move
EXTMOVE_SHNDL dw ?		; Source handle
EXTMOVE_SOFF  dd ?		; Source offset
EXTMOVE_DHNDL dw ?		; Destin handle
EXTMOVE_DOFF  dd ?		; Destin offset

EXTMOVE_STR ends


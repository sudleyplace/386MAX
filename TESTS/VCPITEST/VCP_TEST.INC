;' $Header:   P:/PVCS/MISC/VCPITEST/VCP_TEST.INV   1.1   22 Feb 1994 12:32:28   HENRY  $


; Common macros

SETMSG	 macro	 TXT,CODE
	 local	 LBL

	 mov	 ERRMSG,offset cs:LBL
ifnb <CODE>
	 mov	 ERRCODE,ah
else
	 mov	 ERRCODE,-1
endif				; IFNB

TEXT	 segment use16 byte public 'data' ; Start TEXT segment
	 assume  ss:PGROUP

LBL	 db	 BEL,'ออ> ',TXT,CR,LF,EOS

	 assume  ss:nothing

TEXT	 ends			; End TEXT segment

	 endm			; SETMSG



DISPLAY  macro	 TXT
	 local	 LBL

TEXT	 segment use16 byte public 'data' ; Start TEXT segment
	 assume  ss:PGROUP

LBL	 db	 TXT,CR,LF,EOS

	 assume  ss:nothing

TEXT	 ends			; End TEXT segment

	 REGSAVE <ax,dx>	; Save registers

	 DOSCALL @STROUT,LBL

	 REGREST <dx,ax>	; Restore

	 endm			; DISPLAY


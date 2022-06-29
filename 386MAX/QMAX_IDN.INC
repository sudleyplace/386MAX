;' $Header:   P:/PVCS/MAX/386MAX/QMAX_IDN.INV   1.1   26 Jan 1996 10:07:00   PETERJ  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_IDN.INC
;
; IDENTIFY structure and CHKIDN macro
;

; The first byte of IDENTIFY contains the # lines in the message

	 public  IDENTIFY,IDENTIFY_LEN,IDENT_CHK
IDENTIFY db	 35 dup ('0123456789')  ; Printable ASCIIZ string
IDENTIFY_LEN equ $-IDENTIFY
IDENT_CHK dw	 0		; Checksum

; An EOS follows this string in case we need to use @STROUT on it elsewhere

ifdef @RAMEXAM
	INSTPROG equ 'RSETUP'
else
	INSTPROG equ 'SETUP'
endif

	 public  MSG_XINST
ifdef LANG_GR
MSG_XINST db	 BEL,'ÍÍ> Bitte zuerst INSTALLation durchfhren.',CR,LF,EOS
else
MSG_XINST db	 BEL,'ÍÍ> You must run the ',INSTPROG,' program first.',CR,LF,EOS
endif				; IFDEF LANG_GR
MSG_XINST_LEN equ $-MSG_XINST-1 ; Length of ... (excluding EOS)


CHKIDN	 macro	 FHMSG,FHERR,PBIDMSG,PBIDLEN

COMMENT|

We're assuming that DS addresses both IDENTIFY and MSG_XINST

On exit:

CX	 =	 # lines in displayed message

|

	 REGSAVE <ax,bx,dx,si>	; Save for a moment

	 xor	 cx,cx		; Assume no lines to display

	 cmp	 IDENT_CHK,-1	; Have we been run already?
	 je	 short CHKIDN_EXIT ; Jump if not (note CF=0)

; Decrypt the string back into itself and calculate the checksum

	 lea	 si,IDENTIFY[0] ; DS:SI ==> IDN string including CR count
	 mov	 cx,IDENTIFY_LEN ; CX = # bytes in IDENTIFY including CR count
	 xor	 dx,dx		; Initialize checksum accumulator
	 xor	 ah,ah		; Zero to use as word
CHKIDN_NEXT:
	 lods	 IDENTIFY[si]	; Get next byte

	 add	 dx,ax		; Add into accumulated checksum

	 sub	 al,23h 	; Back off from magic constant
	 rol	 al,1		; Swap the nibbles
	 rol	 al,1
	 rol	 al,1
	 rol	 al,1

	 mov	 ds:[si-1],al	; Save back into string

	 loop	 CHKIDN_NEXT	; Jump if more bytes to decrypt

; Ensure checksum matches

	 cmp	 dx,IDENT_CHK	; Check 'em
	 jne	 short CHKIDN_ERR ; Jump if something is rotten

; Display the decrypted string

	 lea	 si,IDENTIFY[1] ; DS:SI ==> IDN string following CR count
ifnb <PBIDMSG>
	 mov	 PBIDMSG,si	; Save pointer to decrypted user info
endif				; PBIDMSG specified
	 mov	 cx,IDENTIFY_LEN-1 ; CX = # bytes in IDENTIFY less CR count
@@:
	 lods	 IDENTIFY[si]	; Get next byte

	 cmp	 al,0		; Izit end-of-the-line?
	 loopne  @B		; Jump if not
	 jne	 short @F	; Jump if no terminator????

	 dec	 si		; Back off to zero terminator
@@:
	 mov	 cx,si		; Copy offset of zero-terminator
	 sub	 cx,offset ds:IDENTIFY[1] ; Convert from offset to length
ifnb <PBIDMSG>
	 mov	 PBIDLEN,cx	; Save length of message
else
	 mov	 bx,FHMSG	; Use this handle
	 DOSCALL @WRITF2,IDENTIFY[1] ; Tell 'em who we think they are
endif				; PBIDMSG specified

	 xor	 ch,ch		; Zero to use as word
	 mov	 cl,IDENTIFY[0] ; Return line count

	 clc			; Indicate we succeeded

	 jmp	 short CHKIDN_MARK ; Join common exit code

CHKIDN_ERR:
	 mov	 cx,MSG_XINST_LEN ; # bytes to display
ifnb <PBIDMSG>
	 lea	 dx,MSG_XINST	; Error message
	 mov	 PBIDMSG,dx	; Save pointer to error message
	 mov	 PBIDLEN,cx	; Save length of error message
else
	 mov	 bx,FHERR	; Use this handle
	 DOSCALL @WRITF2,MSG_XINST ; Tell 'em to re-run INSTALL
endif				; PBIDMSG was specified

	 mov	 cx,1		; Return line count

	 stc			; Mark as in error
CHKIDN_MARK:
	 mov	 IDENT_CHK,-1	; Ensure we don't display this again
CHKIDN_EXIT:
	 REGREST <si,dx,bx,ax>	; Restore

	 endm			; CHKIDN


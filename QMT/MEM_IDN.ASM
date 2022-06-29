;' $Header:   P:/PVCS/MAX/QMT/MEM_IDN.ASV   1.1   10 Nov 1995 20:50:50   BOB  $
	 title	 MEM_IDN -- MEMCHK Identification Routines
	 page	 58,122
	 name	 MEM_IDN
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-95 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  byte-aligned, public, class 'data'
	       Tail    segment DATAZ, para-aligned, public, class 'dataz'
	       Tail    segment IDENT, dword-aligned,public, class 'dataz'

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include PTR.INC
	 include DOSCALL.INC
	 include MAXDEV.INC
	 include 386.INC

	 include MEM_SCRN.INC

	 include MEM_OEM.INC
.list

PGROUP	 group	 CODE
DGROUP	 group	 DATA,DATAZ,IDENT


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 W_BASE:tbyte

DATA	 ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DATAZ	 segment use16 para public 'dataz' ; Start DATAZ segment
	 assume  ds:DGROUP

	 public  MAX_FLAG
MAX_FLAG dd	 ?		; Attributes

	 include QMAX_IDN.INC

DATAZ	 ends			; End DATAZ segment


IDENT	 segment use16 dword public 'dataz' ; Start IDENT segment
	 assume  ds:DGROUP

; Note we must ensure that PIDENT is on dword boundary so it is at the
; end of the file image (this is a dword-aligned segment, so the
; LINKer pads the image out to a dword boundary).

	 public  PIDENT
PIDENT	 dd	 DGROUP:IDENTIFY ; Point to identification string

	 public  ZTAIL
ZTAIL	 label	 byte		; Next available byte

IDENT	 ends			; End IDENT segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

ifndef @RAMDEMO
	 NPPROC  CHECK_INFO -- Check IDN Information
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check and display IDN information.

On exit:

CF	 =	 0 if all went OK
	 =	 1 if something went wrong

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 CHKIDN  @STD_OUT,@STD_OUT ; Check and display all messages to
				; standard output
	 jc	 near ptr CHECK_INFO_EXIT ; Jump if something went wrong

; Compress out the leading "Serial "

	 cmp	 IDENTIFY[1].EDD,'ireS' ; Izit "Seri"?
	 jne	 short CHECK_INFO1 ; Jump if not

	 cmp	 IDENTIFY[5].EDD,'# la' ; Izit "al #"?
	 jne	 short CHECK_INFO1 ; Jump if not

	 lea	 di,IDENTIFY[1] ; ES:DI ==> destin of move
	 lea	 si,IDENTIFY[8] ; DS:SI ==> source ...
CHECK_INFO0:
	 lods	 IDENTIFY[si]	; Get next byte

; Because we display the identify line via WPUT_C, we need
; to launder any embedded CR, LF

	cmp	al,CR		; Izit a CR?
	je	short @F	; Jump if so

	cmp	al,LF		; Izit a LF?
	jne	short CHECK_INFO0A ; Jump if not
@@:
	mov	al,'-'          ; Use a substitute
CHECK_INFO0A:
S16	 stos	 IDENTIFY[di]	; Move it down

	 and	 al,al		; Izit the end?
	 jnz	 short CHECK_INFO0 ; Jump if not
CHECK_INFO1:

; Compress out the "Licensed to "

	 xor	 si,si		; Initialize index into IDENTIFY
CHECK_INFO2:
	 inc	 si		; Skip to next character

	 cmp	 IDENTIFY[si],0 ; Izit the end?
	 je	 short CHECK_INFO3 ; Jump if so

	 cmp	 IDENTIFY[si].EDD,'eciL' ; Izit "Lice"?
	 jne	 short CHECK_INFO2 ; Jump if not

	 cmp	 IDENTIFY[si+4].EDD,'desn' ; Izit "nsed"?
	 jne	 short CHECK_INFO2 ; Jump if not

	 cmp	 IDENTIFY[si+8].EDD,' ot ' ; Izit " to "?
	 jne	 short CHECK_INFO2 ; Jump if not

	 lea	 di,IDENTIFY[si] ; ES:DI ==> destin of move
	 lea	 si,IDENTIFY[si+12] ; DS:SI ==> source ...
@@:
	 lods	 IDENTIFY[si]	; Get next byte
S16	 stos	 IDENTIFY[di]	; Move it down

	 and	 al,al		; Izit the end?
	 jnz	 short @B	; Jump if not
CHECK_INFO3:

; Fill the trailing zero and following with blanks so we can display
; this in basic mode.

	 lea	 si,IDENTIFY[1] ; DS:SI ==> message to fill
	 xor	 cx,cx		; Initialize the counter
@@:
	 lods	 IDENTIFY[si]	; Get next byte
	 inc	 cx		; Count it in

	 cmp	 al,0		; Izit the end?
	 jne	 short @B	; Jump if not

	 dec	 si		; Back off to terminating zero
	 dec	 cx		; Account for it

; If there is a trailing CR,LF, zap it now

	 cmp	 DGROUP:[si-2].ELO,0A0Dh ; Izit present?
	 jne	 short @F	; Jump if not

	 mov	 DGROUP:[si-2].ELO,0000h ; Zap it
	 sub	 si,2		; Back off to terminating zero
	 sub	 cx,2		; ...
@@:
	 sub	 cx,W_BASE.NCOL ; Izit over our limit?
	 jae	 short CHECK_INFO_EXIT ; Jump if so

	 neg	 cx		; Negate to get positive length to fill
	 mov	 di,si		; ES:DI ==> tail of IDENTIFY
	 mov	 al,' '         ; Fill with this
     rep stos	 IDENTIFY[di]	; Blank the tail

	 clc			; Indicate all went well
CHECK_INFO_EXIT:
	 REGREST <di,si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_INFO endp 		; End CHECK_INFO procedure
endif

CODE	 ends			; End CODE segment

	 MEND			; End MEM_IDN module

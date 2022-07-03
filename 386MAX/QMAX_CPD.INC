;' $Header:   P:/PVCS/MAX/386MAX/QMAX_CPD.INV   1.1   04 Dec 1995 13:28:34   BOB  $
;
; (C) Copyright 1992-5 Qualitas, Inc.  GNU General Public License version 3.
;
; QMAX_CPD.INC
;
; Macros and equates for checkpoint debugging.
;

if @OEM_DEBUG

; Equates for CPD_FLAG

@CPD_MSG equ	 8000h		; Display CPD messages

; More equates

; The value of @CPDCNT is not 24 (as you might expect) because we
; don't keep track of any other text lines which might be displayed
; outside of DISP_CPDMSG such as a copyright notice or the like from
; a .LOD module.

@CPDCNT  equ	 20		; # lines to scroll before pausing

; Note that we don't use ASSUMEs in the CPD macro because
; we don't know to what group we should restore them.

CPDCOM	 macro	 TXT,FN,PAUSE
	 local	 L1

if (@Cpu and 1000b)		; If 80386 instructions
YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
else
YDATA	 segment dword public 'ydata' ; Start YDATA segment
endif
;;;;;;;; assume  ds:YGROUP

L1	 db	 TXT,CR,LF
ifnb <PAUSE>
	 db	 -1
endif				; IFNB <PAUSE>
	 db	 EOS

YDATA	 ends			; End YDATA segment

if (@Cpu and 1000b)		; If 80386 instructions
	 push	 offset YGROUP:L1 ; Pass address of message
	call	FN		; Display as message if appropriate
else
	 push	 ax		; Save for a moment

	 lea	 ax,YGROUP:L1	; Get address of message

	 push	 ax		; Pass address of message
	call	FN		; Display as message if appropriate

	 pop	 ax		; Restore
endif
	 endm			; CPDCOM


CPDPMNP  macro	 TXT

	CPDCOM	TXT,DISP_CPDMSG_PM

	 endm			; CPDPMNP


CPDPM	 macro	 TXT

	CPDCOM	TXT,DISP_CPDMSG_PM,PAUSE

	 endm			; CPDPM


CPDP	 macro	 TXT

	CPDCOM	TXT,DISP_CPDMSG,PAUSE

	 endm			; CPDP


CPD	 macro	 TXT

	CPDCOM	TXT,DISP_CPDMSG

	 endm			; CPD

endif				; IF @OEM_DEBUG


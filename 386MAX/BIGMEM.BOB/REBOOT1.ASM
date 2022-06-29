;' $Header$
	title	REBOOT1 -- Reboot The System
	page	58,122
	name	REBOOT1

COMMENT|		Module Specifications

Copyright:  (C) Copyright 2003 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned, stack,  class 'prog'
	       Program segment CODE,  byte-aligned, public, class 'prog'

Program derived from:  None.

Original code by:  Bob Smith, October, 2003.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include ASCII.INC
	include 8255.INC
	include DOS.INC
	include PTR.INC
	include 386.INC
.list

PGROUP	group	STACK,CODE


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	segment use16 byte stack 'prog' ; Start STACK segment
STACK	ends			; End STACK segment


CODE	segment use16 dword public 'prog' ; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP
.xlist
	include PSP.INC 	; Define & skip over PSP area for .COM program
.list

INITIAL:
	jmp	short REBOOT	; Join initialization code

	align	4

	public	IDT_REBOOT
IDT_REBOOT df	0		; IDT with zero limit to reboot the system

	public	MSG_COPY
MSG_COPY db	'REBOOT1  -- Version 1.00 ',CR,LF
	db	'   (C) Copyright 2003 Qualitas, Inc. '
	db	' All rights reserved.',CR,LF,EOS

	NPPROC	REBOOT -- Reboot The System
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	DOSCALL @STROUT,MSG_COPY ; Display our copyright

	call	CMD_REBOOT	; Reboot the system

	ret			; Return to DOS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REBOOT	endp			; End REBOOT procedure
	NPPROC	CMD_REBOOT -- REBOOT Command
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Reboot command
REBOOT n	where n is 0, 1, 2, 3, ... and represents the
		reboot method

Method 1 is

On entry:

DS:ESI	==>	text following command
SS:EBP	==>	FORW_STR

On exit:

CF	=	0 if no error (and we don't come back)
	=	1 otherwise

|

;;;;	     lea     si,PSP_PARM_STRING ; DS:SI ==> command line parameters
;;;; @@:
;;;;	     lods    ds:[si].LO      ; Get next character?
;;;;
;;;;	     cmp     al,' '          ; Izit white space?
;;;;	     je      short @B	     ; Jump if so
;;;;
;;;;	     cmp     al,TAB	     ; Izit white space?
;;;;	     je      short @B	     ; Jump if so
;;;;
;;;; ; Split cases
;;;;
;;;;	     cmp     al,'0'          ; Izit method #0?
;;;;	     je      short CMD_REBOOT_M0 ; Jump if so
;;;;
;;;;	     cmp     al,'1'          ; Izit method #1?
;;;;	     je      short CMD_REBOOT_M1 ; Jump if so
;;;;
;;;;	     cmp     al,'2'          ; Izit method #2?
;;;;	     je      short CMD_REBOOT_M2 ; Jump if so


; Reboot Method #1 -- Triple Fault

CMD_REBOOT_M1:
	mov	ebx,cr0 	; Get current control register
	and	ebx,not ((mask $PG) or (mask $PE)) ; Disable paging and PM
	xor	eax,eax 	; A handy zero for CR3

	LIDTD	IDT_REBOOT	; Set IDT limit to zero

	mov	ss,eax		; Generate a fault

; We should not get here...


 ; Reboot Method #0 -- 8042 I/O Port

 CMD_REBOOT_M0:
	 mov	 al,@S2C_SHUT	 ; Command for system shutdown

	 mov	 ebx,cr0	 ; Get current control register
	 and	 ebx,not ((mask $PG) or (mask $PE)) ; Disable paging and PM
	 mov	 cr0,ebx	 ; Tell the CPU about it

	 out	 @8042_ST,al	 ; Initiate system shutdown
	 hlt
	 jmp	 short $	 ; We're not going anywhere
;;;;
;;;;
;;;; ; Reboot Method #2 -- OUTs to 0CF9h
;;;;
;;;; CMD_REBOOT_M2:
;;;;	     mov     dx,0CF9h	     ; Get PCI I/O port
;;;;	     mov     al,4	     ; 1st magic number
;;;;	     out     dx,al	     ; Reset PCI
;;;;
;;;;	     mov     al,6	     ; 2nd magic number
;;;;	     out     dx,al	     ; Reset PCI
;;;;
;;;; ; We should not get here...
;;;;
;;;;	     jmp     CMD_REBOOT_M0   ; Just in case...


;;;; ; On some machines, it appears to be important that the OUT
;;;; ; instruction following the MOV into CR0 which disables Paging and
;;;; ; Protect Enable be in the prefetch queue so the CPU doesn't
;;;; ; generate another bus event.  If we flush the PIQ now, the CPU
;;;; ; fills the PIQ entirely before executing the first instruction.
;;;;
;;;; ; This technique doesn't work here as this segment is byte-aligned.
;;;;
;;;; ;;;;;;; DDALIGN @SWAT_KEY_PROG,4-2 ; Align so that MOV CR0,EBX
;;;; ;;;;;;;			     ; is on a dword boundary
;;;; ;;;;;;; jmp     short $+2	     ; Flush the prefetch instruction queue
;;;; ;;;;;;;
;;;;	     mov     cr0,ebx	     ; Tell the CPU about it
;;;;	     mov     cr3,eax	     ; No more paging
;;;;
;;;; COMMENT|
;;;;
;;;; To reboot the system, we set the IDT limit to zero and then issue an
;;;; interrupt (any interrupt).  This causes a GP Fault because the
;;;; interrupt # is beyond the IDT limit.  This then causes a Double Fault
;;;; because the GP Fault interrupt # is beyond the IDT limit.	This then
;;;; causes a Triple Fault (system reset) because the Double Fault
;;;; interrupt # is beyond the IDT limit.  This way, we don't have to
;;;; depend upon peripherals such the 8042 which might or might not work
;;;; correctly.
;;;;
;;;; |
;;;;
;;;;	     int     03h	     ; Issue an interrupt
;;;;
;;;; ; We should not get here...
;;;;
;;;;	     jmp     CMD_REBOOT_M0   ; Just in case...
;;;;
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_REBOOT endp 		; End CMD_REBOOT procedure

CODE	ends			; End CODE segment

	MEND	INITIAL 	; End REBOOT1 module

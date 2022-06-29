;' $Header:   P:/PVCS/MAX/QUILIB/VIDEOID.ASV   1.1   30 May 1997 12:09:08   BOB  $
	 TITLE	 VideoID
	 page	 58,122
	 name	 VideoID
if (@Version GE 600)
	 option  OLDSTRUCTS
endif

COMMENT|		Module Specifications

Copyright:  Copyright (c) 1990-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE.

Link requirements:  None.

Program derived from: (From "Programmer's Guide to PC & PS/2 Video Systems"
		      Listing C-1,  p513-520.

Modifications by:  Alan C. Lindsay, August 1990.

|

;
; Name: 	VideoID
;
; Function:	Detects the presence of various video subsystems and associated
;		monitors.
;
; Caller:	Microsoft C:
;
;		long VideoID(VIDstruct,nstruct);
;
;		struct {
;			char VideoSubsystem;
;			char Display;
;		} *VIDstruct[2];
;		int nstruct;
;
;		Subsystem ID values:
;			0  = (none)
;			1  = MDA
;			2  = CGA
;			3  = EGA
;			4  = MCGA
;			5  = VGA
;		       80h = HGC
;		       81h = HGC+
;		       82h = Hercules InColor
;
;		Display types:
;			0 = (none)
;			1  = MDA-compatible monochrome
;			2  = CGA-compatible color
;			3  = EGA-compatible color
;			4  = PS/2-compatible monochrome
;			5  = PS/2-compatible color
;
;		Return value:
;			Low word:  EGA Adapter memory in Kb
;			High word:  Current video mode
;
;	The values returned in VIDstruct[0].VideoSybsystem and
;	VIDstruct[0].Display indicate the currently active subsystem.
;
ARGpVID EQU	word ptr [bp+4] ; stack frame addressing
;
	.MODEL	LARGE,PASCAL
	.DATA

VIDSTRUCT	struc	; corresponds to C data structure
Video0Type	db	?	; First subsystem type
Display0Type	db	?	; Display attached to first subsystem
Video1Type	db	?	; Second subsystem type
Display1Type	db	?	; Display attached to second subsystem
VIDSTRUCT	ENDS
;
Device0 EQU	word ptr Video0Type[di]
Device1 EQU	word ptr Video1Type[di]
;
MDA	EQU	1	; Subsystem types
CGA	EQU	2
EGA	EQU	3
MCGA	EQU	4
VGA	EQU	5
HGC	EQU	80h
HGCPlus EQU	81h
InColor EQU	82h
;
MDADisplay	equ	1	; Display types
CGADisplay	equ	2
EGAColorDisplay equ	3
PS2MonoDisplay	equ	4
PS2ColorDisplay equ	5
;
TRUE	equ	1
FALSE	EQU	0
;
	.CODE
VIDEOID PROC	vidp:dword,nvid:word
;
	push	si		; Preserve caller registers
	push	di
;
; Intiialize the data structure that will contain the results
;
	lea	di,TempStruct	; DS:DI -> start of data structure
	mov	Device0,0	; Zero these variables
	mov	Device1,0
;
; Look for the various subsystems using the subroutines whose addresses are
; tabluated in TestSequence; each subroutine sets flags in TestSequence
; to incicate whether subsequent subroutines need to be called
;
	mov	EgaMem,4
	mov	byte ptr PS2flag,TRUE
	mov	byte ptr CGAflag,TRUE
	mov	byte ptr EGAflag,TRUE
	mov	byte ptr Monoflag,TRUE
;
	mov	cx,NumberOfTests
	mov	si,offset DGROUP:TestSequence
L01:
	lodsb		; AL = flag
	test	al,al
	lodsw		; AX = subroutine address
	jz	L02		; skip subroutine if flag is FALSE
;
	push	si
	push	cx
	call	ax		; Call subroutine to detect subsystem
	pop	cx
	pop	si
L02:
	loop	L01
;
; Determine which subsystem is active
;
	call	FindActive
;
; All Done, pass results back to caller
;
	mov	si,di		; DS:SI = temp structure
	les	di,vidp 	; ES:DI = caller's structure
	mov	ah,0		; Prep..
	mov	cx,nvid 	; How many items to return
	add	cx,cx		; Convert to bytes
L03:
	lodsb			; Fetch bytes, store words
	stosw
	loop	L03
;
	pop	di		; Restore caller registers
	pop	si
	mov	ax,EgaMem	; EGA memory code
	add	ax,ax		; ..times two
	lea	bx,MemTable
	add	bx,ax		; Index into table
	mov	ax,[bx] 	; Fetch memory size
	mov	dx,CurrMode	; Fetch current video mode
	ret			; ...and return
VIDEOID ENDP
;
; FindPS2
;
; This subroutine uses INT 10h function 1Ah to determine the video BIOS
; Display Combination Code (DCC) for each video subsystem present.
;
FindPS2 PROC	NEAR
;
	mov	ax,1a00h
	int	10h		; Call video BIOS for info
;
	cmp	al,1ah		; Exit if function not supported (i.e.,
	jne	L13		;  no MCGA or VGA in system)
;
; Convert BIOS DCCs into specific subsystems & displays
;
	mov	cx,bx
	xor	bh,bh		; BX = DCC for active subsystem
	or	ch,ch
	jz	L11		; Jump if only one subsystem present
;
	mov	bl,ch		; BX = inactive DCC
	add	bx,bx
	mov	ax,[bx+offset DGROUP:DCCtable]
;
	mov	Device1,ax
;
	mov	bl,cl
	xor	bh,bh		; BX = active DCC
L11:
	add	bx,bx
	mov	ax,[bx+offset DGROUP:DCCtable]
	mov	Device0,ax
;
; Reset flags for subsystems that have been ruled out
;
	mov	byte ptr CGAflag,FALSE
	mov	byte ptr EGAflag,FALSE
	mov	byte ptr Monoflag,FALSE
;
	lea	bx,Video0Type[di]	; If the BIOS reported an MDA
	cmp	byte ptr [bx],MDA
	je	L12
;
	lea	bx,Video1Type[di]
	cmp	byte ptr [bx],MDA
	jne	L13
L12:
	mov	word ptr [bx],0 	; ...Hercules can't be ruled out
	mov	byte ptr Monoflag,TRUE
L13:
	ret
FindPS2 ENDP
;
; FindEGA
;
; Look for an EGA.  This is done by making a call to an EGA BIOS function
; which doesn't exist in the default (MDA, CGA) BIOS.
;
FindEGA PROC	NEAR		; Caller:   AH = flags
				; Returns:  AH = flags
				;	    Video0Type and
				;	     Display0Type updated
;
	mov	bl,10h		; BL = 10h (return EGA info)
	mov	ah,12h		; AH = int 10h function unuber
	int	10h		; Call EGA BIOS for info
				; if EGA BIOS is present
				;  BL != 10h
				;  CL = switch setting
	cmp	bl,10h
	je	L22		; Jump if EGA BIOS not present
;
	mov	bh,0
	mov	EgaMem,bx	; Save EGA memory size
;
	mov	al,cl
	shr	al,1		; AL = switches/2
	mov	bx,offset DGROUP:EGADisplays
	xlat			; Determine display type from switches
	mov	ah,al		; AH = display type
	mov	al,EGA		; AL = subsystem type
	call	FoundDevice
;
	cmp	ah,MDADisplay
	je	L21		; Jump if EGA has a monochrome display
;
	mov	CGAflag,FALSE	; No CGA if EGA has color display
	jmp	short L22
L21:
	mov	Monoflag,FALSE	; EGA has a mono display so MDA and
L22:				;  Hercules are ruled out
	ret
;
FindEGA ENDP
;
;	FindCGA
;
;	This is done by looking for the CGA's 6845 CRTC at I/O port 3D4h.
;
FindCGA PROC	NEAR		; Returns:  VIDstruct updated
;
	mov	dx,3D4h 	; DX = CRTC address port
	call	Find6845
	jc	L31		; Jump if not present
;
	mov	al,CGA
	mov	ah,CGADisplay
	call	FoundDevice
L31:
	ret
	;
FindCGA ENDP

;
; FindMono
;
;	This is done by looking for the MDA's 6845 CRTC at I/O port 3B4h.
;  If a 6845 is found, the subroutine distinguishes between an MDA
;  and a Hercules adapter by monitoring bit 7 of the CRT Status byte.
;  This bit changes on Hercules adapters but does not change on an MDA.
;  The various Hercules adapters are identified by bits 4 through 6 of
;  the CRT status value.
;
;	001b = HGC+
;	101b = InColor card
;
FindMono PROC	NEAR		; Returns:  VIDstruct updated
;
	mov	dx,3B4h 	; DX = CRTC address port
	call	Find6845
	jc	L44		; Jump if not present
;
	mov	dl,0BAh 	; DX = 3BAh (status port)
	in	al,dx
	and	al,80h
	mov	ah,al		; AH = bit 7 (vertical sync on HGC)
;
	mov	cx,8000h	; Do this 32768 times
L41:
	in	al,dx
	and	al,80h		; Isolate bit 7
	cmp	ah,al
	loope	L41		; Wait for bit 7 to change
;
	jne	L42		; If bit 7 changed, it's a Hercules
;
	mov	al,MDA		; If bit 7 didn't change, it's an MDA
	mov	ah,MDADisplay
	call	FoundDevice
	jmp	short L44
L42:
	in	al,dx
	mov	dl,al		; DL = value from status port
	and	dl,01110000b	; Mas of bits 4 thru 6
;
	mov	ah,MDADisplay	; Assume it's a monochrome display
;
	mov	al,HGCPlus	; Look for an HGC+
	cmp	dl,00010000b
	je	L43		; Jump if it's an HGC+
;
	mov	al,HGC		; Look for an HGC
	cmp	dl,01010000b
	jne	L43
;
	mov	al,InColor	; Else, it's an InColor card
	mov	ah,EGAColorDisplay
L43:
	call	FoundDevice
L44:
	ret
;
FindMono ENDP
;
; Find 6845
;
;	This routine detects the presence of the CRTC on an MDA, CGA, or HGC.
;  The technique is to write and read register 0Fh of the chip (Cursor
;  Location Low).  If the same value is read as written, assume the chip
;  is present at the specified port address
;
Find6845 PROC	NEAR		; Caller:   DX = port addr
				; Returns:  CF set if not present
	mov	al,0Fh
	out	dx,al		; Select 6845 reg 0Fh (Cursor Low)
	inc	dx
;
	in	al,dx		; AL = current Cursor Low value
	mov	ah,al		; Preserve in AH
	mov	al,66h		; AL = arbitrary value
	out	dx,al		; Try to write to 6845
;
	mov	cx,100h
	loop	$		; Wait for 6845 to respond
;
	in	al,dx
	xchg	ah,al		; AH = returned value
				; AL = original value
	out	dx,al		; Restore original value
;
	cmp	ah,66h		; Test whether 6845 responded
	je	L52		; Jump if it did (cf is reset)
;
	stc			; Else, set carry flag if no 6845 present
L52:
	ret			; ..and return
;
Find6845 ENDP
;
; Find Active
;
;	This subroutine stores the currently active device as Device0.	The
;  current video mode determines which subsystem is active.
;
FindActive PROC NEAR
;
	mov	ah,0Fh
	int	10h		; AL = current BIOS video mode
	mov	ah,0
	mov	CurrMode,ax
;
	cmp	word ptr Device1,0
	je	L63		; Exit if only one subsystem
;
	cmp	Video0Type[di],4 ; Exit if MCGA or VGA present
	jge	L63		;  (Int 10h function 1Ah
	cmp	Video1Type[di],4 ;  already did the work)
	jge	L63
;
;	Video mode is still in ax
;
	and	al,7
	cmp	al,7		; Jump if monochrome
	je	L61		;  (mode 7 or 0Fh)
;
	cmp	Display0Type[di],MDADisplay
	jne	L63		; Exit if Display0 is color
	jmp	short L62
L61:
	cmp	Display0Type[di],MDADisplay
	je	L63		; Exit if Display0 is monochrome
L62:
	mov	ax,Device0	; Make Device0 currently active
	xchg	ax,Device1
	mov	Device0,ax
L63:
	ret			; ..and return
;
FindActive ENDP
;
; FoundDevice
;
;	This routine updates the list of subsystems.
;
FoundDevice PROC NEAR		; Caller:    AH = display #
				;	     AL = subsystem #
				; Destroys:  BX
	lea	bx,Video0Type[di]
	cmp	byte ptr [bx],0
	je	L71		; Jump if 1st subsystem
;
	lea	bx,Video1Type[di] ; Must be 2nd subsystem
L71:
	mov	[bx],ax 	; Update list entry
	ret			; ..and return
;
FoundDevice ENDP
;
	.DATA
TempStruct VIDSTRUCT <> 	; Temp storage for results
;
EGADisplays db	CGADisplay	; 0000b, 0001b (EGA switch values)
	db	EGAColorDisplay ; 0010b, 0011b
	db	MDADisplay	; 0100b, 0101b
	db	CGADisplay	; 0110b, 0111b
	db	EGAColorDisplay ; 1000b, 1001b
	db	MDADisplay	; 1010b, 1011b
;
DCCtable db	0,0		; Translate table for Int 10h func 1Ah
	db	MDA,MDADisplay
	db	CGA,CGADisplay
	db	0,0
	db	EGA,EGAColorDisplay
	db	EGA,MDADisplay
	db	0,0
	db	VGA,PS2MonoDisplay
	db	VGA,PS2ColorDisplay
	db	0,0
	db	MCGA,EGAColorDisplay
	db	MCGA,PS2MonoDisplay
	db	MCGA,PS2ColorDisplay
;
;		 0   1	  2	3   4
MemTable dw	 64, 128, 192, 256, 0
;
TestSequence LABEL byte
PS2flag db ?		; This list of flags and addresses
	dw	FindPS2 	;  determines the order in which this
				;  program looks for the various
EGAflag db	?		;  subsystems
	dw	FindEGA
;
CGAflag db	?
	dw	FindCGA
;
Monoflag db	?
	dw	FindMono
;
NumberOfTests equ ($-TestSequence)/3
;
EgaMem dw	?
CurrMode dw	?
;
	end

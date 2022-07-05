;' $Header:   P:/PVCS/MAX/QMT/MEM_SCRN.ASV   1.1   29 Jun 1998 13:05:00   BOB  $
	title	MEM_SCRN -- MEMCHK Screen Routines
	page	58,122
	name	MEM_SCRN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-1999 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	include MASM.INC
	include 386.INC
	include PTR.INC
	include MASM5.MAC
	include VIDATTR.INC
	include BITFLAGS.INC

	include MEM_BLK.INC
	include MEM_OEM.INC
	include MEM_SCRN.INC
	include MEM_SEGS.INC
.list

DATA	segment use16 dword public 'data' ; Start DATA segment
	assume	ds:DGROUP

	extrn	GL2_FLAG:word
	include MEM_GL2.INC
ifndef @RAMDEMO
	extrn	IDENTIFY:byte
endif
	extrn	VIDBASE_FVEC:fword
	extrn	DEFATTR:byte
	extrn	CPYATTR:byte
	extrn	AARATTR:byte
	extrn	KEYATTR:byte
	extrn	KEY2ATTR:byte
	extrn	SHD2ATTR:byte
	extrn	STATLATTR:byte

	extrn	W_STATL:tbyte
	extrn	W_CURPAT:tbyte

	extrn	W_PTST:tbyte
	extrn	MSG_PTSTGET:byte

	extrn	W_SCROLL:tbyte
	extrn	MSG_SCROLL:byte
	extrn	@STATLIN_SROW:abs
	extrn	@STATLIN_NCOL:abs

	extrn	MSG_ALLOC:byte
	extrn	MSG_ALLOC_LEN:abs
	extrn	MSG_CPY:byte
	extrn	MSG_QUIT:byte
	extrn	MSG_HALT:byte
	extrn	MSG_BASIC:byte
	extrn	MSG_ADV:byte
	extrn	MSG_DEC:byte
	extrn	MSG_HEX:byte
	extrn	W_CPY:tbyte
	extrn	W_AAR:tbyte
	extrn	W_KEY:tbyte
	extrn	W_MODE:tbyte
	extrn	W_BASE:tbyte

	extrn	HELP_STATE:word
	extrn	@HELP_SCREEN:abs

	public	W_TMP
W_TMP	W_STR	<>		; Temporary Window descriptor

	public	W_SHD
W_SHD	W_STR	<>		; Window descriptor used for all shadowing
				; Note that it's not re-entrant
	public	OLDSCR
	align	4
OLDSCR	dw	(@NROWS*@NCOLS) dup (?) ; Save area for old screen

	public	MSG_SHD1
MSG_SHD1 db	@NCOLS dup (?)	; Save area for SHD1 values

DATA	ends			; End DATA segment


CODE	segment use16 byte public 'prog' ; Start CODE segment
	assume	cs:PGROUP

	extrn	INCPTR:near
	extrn	DISP_MEMSCR:near
	extrn	DISP_ASKSCR:near
	extrn	DISP_STATSCR:near

	extrn	CHECK_RHELP:near

	 NPPROC  SAVE_SCR -- Save Current Screen Contents
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save the current screen contents.

This routine runs in real mode.

|

	 REGSAVE <eax,cx,si,di,ds> ; Save registers

	 mov	 eax,VIDBASE_FVEC.FOFF ; Get the screen base
	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> start of screen

	 lea	 di,OLDSCR	; ES:DI ==> save area
	 mov	 cx,@NROWS*@NCOLS ; CX = # (Char,Attr) pairs on screen
S16  rep movs	 <OLDSCR[di],ds:[si].ELO> ; Copy them to local storage

	 REGREST <ds,di,si,cx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_SCR endp			; End SAVE_SCR procedure
	 NPPROC  REST_SCR -- Restore Original Screen Contents
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore the original screen contents.

This routine runs in real mode.

|

	 REGSAVE <eax,cx,si,di,es> ; Save registers

	 mov	 eax,VIDBASE_FVEC.FOFF ; Get the screen base
	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> start of screen

	 lea	 si,OLDSCR	; DS:SI ==> save area
	 mov	 cx,@NROWS*@NCOLS ; CX = # (Char,Attr) pairs on screen
S16  rep movs	 <es:[di].ELO,OLDSCR[si]> ; Copy them to local storage

	 REGREST <es,di,si,cx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_SCR endp			; End REST_SCR procedure
	 NPPROC  VIDB_SEGOFF -- Convert VIDBASE_VEC from linear to seg:off
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert VIDBASE_VEC from a 32-bit linear address to segment:offset
so we can use protected mode screen write routines in V86 mode.

|

	 REGSAVE <eax>		; Save

	 mov	 eax,VIDBASE_FVEC.FOFF ; Get 32-bit offset of screen
	 shr	 eax,4-0	; Convert linear address to segment
	 xchg	 ax,VIDBASE_FVEC.FSEL ; Set up segment
	 mov	 VIDBASE_FVEC.FOFF,eax ; Clear offset

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VIDB_SEGOFF endp		; End VIDB_SEGOFF procedure
	 NPPROC  VIDB_LINEAR -- Restore VIDBASE_VEC to linear address
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore VIDBASE_VEC to a 32-bit linear address by converting from
segment:offset.

|

	 REGSAVE <eax>		; Save

	 movzx	 eax,VIDBASE_FVEC.FSEL ; Get segment value
	 shl	 eax,4-0	; Convert segment to linear address
	 xchg	 eax,VIDBASE_FVEC.FOFF ; Restore offset, zero EAX
	 mov	 VIDBASE_FVEC.FSEL,ax ; Clear selector

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VIDB_LINEAR endp		; End VIDB_LINEAR procedure
	 NPPROC  DISP_ALLOC -- Display Allocating Memory
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display allocating memory

|

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jnz	 short DISP_ALLOC_ADV ; Jump if so

	 push	 offset ds:MSG_PTSTGET ; Pass address of local buffer
	 push	 offset ds:W_PTST ; Pass address of window descriptor
	 call	 WPUT_C 	; Output the characters

	 jmp	 short DISP_ALLOC_EXIT ; Join common exit code

DISP_ALLOC_ADV:
	 push	 offset ds:MSG_ALLOC ; Pass address of local buffer
	 push	 MSG_ALLOC_LEN	; Pass message length in bytes
	 call	 DISP_STATL	; Display on the status line
DISP_ALLOC_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ALLOC endp 		; End DISP_ALLOC procedure
	NPPROC	DISP_SCRN -- Display The Entire Screen
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the entire screen

This routine runs in protected mode.

|

	call	DISP_CLRSCR	; Display a clear screen
	call	DISP_CPYSCR	; ...	  the copyright screen
	call	DISP_MEMSCR	; ...	      memory background screen
	call	DISP_ASKSCR	; ...	      ask ...
	call	DISP_STATSCR	; ...	      status ...
	call	DISP_MODE	; ...	      current mode
	call	DISP_BASE	; ...	      current number base

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_SCRN endp			; End DISP_SCRN procedure
	 NPPROC  DISP_CLRSCR -- Display A Clear Screen
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a clear screen

|

	 REGSAVE <ax>		; Save register

; Clear the screen to blanks with the default attribute

	 mov	 W_TMP.SROW,0	; Start at (0,0)
	 mov	 W_TMP.SCOL,0
	 mov	 W_TMP.NROW,@NROWS ; All rows
	 mov	 W_TMP.NCOL,@NCOLS ; ...all columns

	 mov	 ah,DEFATTR	; Get default attribute
	 mov	 al,' '         ; Smear a blank character
	 push	 ax		; Pass as argument
	 push	 offset ds:W_TMP ; Pass address of window descriptor
	 call	 WPUT_SCA	; Smear character and attribute

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CLRSCR endp		; End DISP_CLRSCR procedure
	 NPPROC  DISP_CPYSCR -- Display The Copyright Screen
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the copyright screen

This routine runs in protected mode.

|

	 REGSAVE <ax>		; Save register

; Display the copyright screen

	 mov	 al,CPYATTR	; Get copyright screen attribute
	 push	 ax		; Pass as attribute to smear
	 push	 offset ds:MSG_CPY ; Pass address of local buffer
	 push	 offset ds:W_CPY ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display the GNU General Public License version 3 screen's attributes

	 mov	 al,AARATTR	; Get AAR screen attribute
	 push	 ax		; Pass as attribute to smear
	 push	 offset ds:W_AAR ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

	 test	 GL2_FLAG,@GL2_ACTIV ; Are we active?
	 jnz	 short DISP_CPYSCR1 ; Jump if so

; Display the how-to-quit line

	 call	 DISP_QUIT	; Display the how-to-quit line

	 jmp	 short DISP_CPYSCR2 ; Join common code

DISP_CPYSCR1:
	 call	 DISP_HALT	; Display the how-to-halt line
DISP_CPYSCR2:

; Display a shadow below and to the right of the copyright screen

	 push	 offset ds:W_CPY ; Pass address of window descriptor
	 call	 WPUT_SHD1	; Display a type 1 shadow

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CPYSCR endp		; End DISP_CPYSCR procedure
	 NPPROC  DISP_QUIT -- Display The How-To-Quit Line
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the how-to-quit line.

|

	 push	 ax		; Save register

	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 short DISP_QUIT_EXIT ; Jump if so

	 mov	 al,KEYATTR	; Get key screen attribute
	 push	 ax		; Pass as attribute to smear
	 push	 offset ds:MSG_QUIT ; Pass address of local buffer
	 push	 offset ds:W_KEY ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

DISP_QUIT_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_QUIT endp			; End DISP_QUIT procedure
	 NPPROC  DISP_HALT -- Display The How-To-Halt Line
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the how-to-halt line.

|

	 push	 ax		; Save register

	 mov	 al,KEYATTR	; Get key screen attribute
	 push	 ax		; Pass as attribute to smear
	 push	 offset ds:MSG_HALT ; Pass address of local buffer
	 push	 offset ds:W_KEY ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_HALT endp			; End DISP_HALT procedure
	 NPPROC  DISP_MODE -- Display The Current Mode
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the current mode.

|

	 push	 ax		; Save register

	 mov	 al,KEY2ATTR	; Get key screen attribute #2
	 push	 ax		; Pass as attribute to smear

	 lea	 ax,MSG_BASIC	; Assume advanced mode:  tell 'em how
				; to get to basic
	 test	 GL2_FLAG,@GL2_ADV ; Izit in advanced mode?
	 jnz	 short @F	; Jump if so

	 lea	 ax,MSG_ADV	; Assume basic mode:  tell 'em how
				; to get to advanced
@@:
	 push	 ax		; Pass address of local buffer
	 push	 offset ds:W_MODE ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MODE endp			; End DISP_MODE procedure
	 NPPROC  DISP_BASE -- Display The Current Number Base
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the current number base.

|

	 push	 ax		; Save register

	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 short DISP_BASE_EXIT ;  Jump if so

	 test	 GL2_FLAG,@GL2_ADV ; Izit in advanced mode?
	 jnz	 short DISP_BASE2 ; Jump if so

ifndef @RAMDEMO

; In basic mode, we display the user's name and serial number

	 mov	 al,KEY2ATTR	; Get key screen attribute #2
	 push	 ax		; Pass as attribute to smear
	 push	 offset ds:IDENTIFY[1] ; Pass address of local buffer
	 push	 offset ds:W_BASE ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute
endif
	 jmp	 short DISP_BASE_EXIT ; Join common exit code

; In advanced mode we display the H/D lines

DISP_BASE2:
	 mov	 al,KEY2ATTR	; Get key screen attribute #2
	 push	 ax		; Pass as attribute to smear

	 lea	 ax,MSG_DEC	; Assume the other base is decimal

	 test	 GL2_FLAG,@GL2_HEX ; Izit in hex mode?
	 jnz	 short @F	; Jump if so

	 lea	 ax,MSG_HEX	; Assume hexadecimal base
@@:
	 push	 ax		; Pass address of local buffer
	 push	 offset ds:W_BASE ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute
DISP_BASE_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_BASE endp			; End DISP_BASE procedure
	 NPPROC  DISP_STATL -- Display A Message On The Status Line
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a message on the status line

This routine runs in protected mode.

|

STATL_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
STATL_LEN dw	 ?		; Line length in bytes
STATL_OFF dw	 ?		; Offset in DGROUP of the line

STATL_STR ends

;;;;;;;; test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
;;;;;;;; jz	 short DISP_STATL_EXIT ; Jump if not
;;;;;;;;
	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 short DISP_STATL_EXIT ;  Jump if so

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,dx,si,di,es> ; Save registers

	 call	 INCPTR 	; Skip to the next status line

	 push	 W_STATL.NCOL	; Save the # cols

	 mov	 cx,[bp].STATL_LEN ; Get the message line length in bytes
	 jcxz	 DISP_STATL_MT	; Jump if nothing to do
	 mov	 W_STATL.NCOL,cx ; Save in window descriptor

	 push	 ds		; Get DGROUP data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

; In case we switch around from advanced to basic mode and back,
; Copy the characters to the scrolling buffer

	 mov	 ax,W_STATL.SROW ; Get the starting screen row
	 sub	 ax,@STATLIN_SROW ; Minus the original row
	 mul	 W_SCROLL.NCOL	; Times # cols in scrolling window
	 shl	 ax,1		; Times two to account for char/attr
	 mov	 di,ax		; Copy to destin register
	 lea	 di,MSG_SCROLL[di] ; Plus start of buffer
	 mov	 si,[bp].STATL_OFF ; Get the message line offset in DGROUP
	 mov	 al,STATLATTR	; Get status line attribute
@@:
S16	 movs	 <MSG_SCROLL[di],DGROUP:[si].LO> ; Copy the character
S16	 stos	 MSG_SCROLL[di] ; Store the attribute
	 loop	 @B		; Jump if more characters to copy

; Pad the line with blanks

	 mov	 cx,@STATLIN_NCOL ; Get total # cols
	 sub	 cx,W_STATL.NCOL ; Less the # in this line
	 mov	 ah,al		; Copy the attribute
	 mov	 al,' '         ; Fill with blanks
     rep stos	 MSG_SCROLL[di].ELO ; Store the character/attribute

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short DISP_STATL_MT ; Jump if not

	 push	 [bp].STATL_OFF ; Pass the message line offset in DGROUP
	 push	 offset ds:W_STATL ; Pass address of window descriptor
	 call	 WPUT_C 	; Output the characters
DISP_STATL_MT:
	 pop	 W_STATL.NCOL	; Restore

	 REGREST <es,di,si,dx,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 call	 CHECK_RHELP	; Update help display if needed
DISP_STATL_EXIT:
	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STATL endp 		; End DISP_STATL procedure
	 NPPROC  DISP_STATLZ -- Display A Message On The Status Line
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a message on the status line

This routine runs in protected mode.

|

STATLZ_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
STATLZ_OFF dw	 ?		; Offset in DGROUP of a ZMSG_STR

STATLZ_STR ends

;;;;;;;; test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
;;;;;;;; jz	 short DISP_STATLZ_EXIT ; Jump if not
;;;;;;;;
	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 short DISP_STATLZ_EXIT ;  Jump if so

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,dx,si,di,es> ; Save registers

	 call	 INCPTR 	; Skip to the next status line

	 push	 W_STATL.NCOL	; Save the # cols

	 mov	 si,[bp].STATLZ_OFF ; Get the offset in DGROUP of ZMSG_STR

	 movzx	 cx,DGROUP:[si].ZMSG_LEN ; Get the message line length in bytes
	 jcxz	 DISP_STATLZ_MT ; Jump if nothing to do
	 mov	 W_STATL.NCOL,cx ; Save in window descriptor

	 push	 ds		; Get DGROUP data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

; In case we switch around from advanced to basic mode and back,
; Copy the characters to the scrolling buffer

	 mov	 ax,W_STATL.SROW ; Get the starting screen row
	 sub	 ax,@STATLIN_SROW ; Minus the original row
	 mul	 W_SCROLL.NCOL	; Times # cols in scrolling window
	 shl	 ax,1		; Times two to account for char/attr
	 mov	 di,ax		; Copy to destin register
	 lea	 di,MSG_SCROLL[di] ; Plus start of buffer

	 mov	 al,DGROUP:[si].ZMSG_ATTR ; Get the attribute to smear
	 lea	 si,DGROUP:[si].ZMSG_MSG ; Skip to the message itself

	 push	 si		; Save the offset
@@:
S16	 movs	 <MSG_SCROLL[di],DGROUP:[si].LO> ; Copy the character
S16	 stos	 MSG_SCROLL[di] ; Store the attribute
	 loop	 @B		; Jump if more characters to copy

	 pop	 si		; Restore

; Pad the line with blanks

	 mov	 cx,@STATLIN_NCOL ; Get total # cols
	 sub	 cx,W_STATL.NCOL ; Less the # in this line
	 mov	 ah,al		; Copy the attribute
	 mov	 al,' '         ; Fill with blanks
     rep stos	 MSG_SCROLL[di].ELO ; Store the character/attribute

	 mov	 al,ah		; Restore the attribute

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short DISP_STATLZ_MT ; Jump if not

	 push	 ax		; Pass the attribute
	 push	 si		; Pass the message line offset in DGROUP
	 push	 offset ds:W_STATL ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute
DISP_STATLZ_MT:
	 pop	 W_STATL.NCOL	; Restore

	 REGREST <es,di,si,dx,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 call	 CHECK_RHELP	; Update help display if needed
DISP_STATLZ_EXIT:
	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_STATLZ endp		; End DISP_STATLZ procedure
	 NPPROC  DISP_CURPAT -- Display The Current Pattern
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the current pattern.

This routine runs in protected mode.

|

CURPAT_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
CURPAT_OFF dw	 ?		; Offset in DGROUP of a ZMSG_STR

CURPAT_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx>	; Save registers

	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 short DISP_CURPAT_EXIT ;  Jump if so

	 mov	 bx,[bp].CURPAT_OFF ; Get the offset in DGROUP of ZMSG_STR

	 movzx	 ax,DGROUP:[bx].ZMSG_LEN ; Get the message line length in bytes
	 mov	 W_CURPAT.NCOL,ax ; Save in window descriptor

	 mov	 al,DGROUP:[bx].ZMSG_ATTR ; Get the attribute to smear

	 lea	 bx,DGROUP:[bx].ZMSG_MSG ; Skip to the message itself

	 push	 ax		; Pass the attribute
	 push	 bx		; Pass the message line offset in DGROUP
	 push	 offset ds:W_CURPAT ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

	 call	 CHECK_RHELP	; Update help display if needed
DISP_CURPAT_EXIT:
	 REGREST <bx,ax>	; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_CURPAT endp		; End DISP_CURPAT procedure
	 NPPROC  WSETUP -- Common Window Setup
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common window setup

On entry:

SS:BP	 ==>	 WPUT_C structure (all such Wxxx_xx structures must
				   have the xxx_xx_DESC part first)

On exit:

ES:EDI	 =	 starting offset in screen buffer
ECX	 =	 # columns in window
DX	 =	 # rows ...

|

	 REGSAVE <eax,si>	; Save registers

	 les	 edi,VIDBASE_FVEC ; ES:EDI ==> the screen
	 assume  es:nothing	; Tell the assembler about it

	 mov	 si,[bp].WPUT_C_DESC ; DS:SI ==> window descriptor

	 movzx	 eax,ds:[si].SROW ; Get the starting row
	 mov	 cx,@NCOLS*2	; Get # bytes per row
	 mul	 cx		; AX = offset in screen buffer (DX clobbered)
	 add	 edi,eax	; Add into screen base

	 movzx	 eax,ds:[si].SCOL ; Get the starting column
	 shl	 eax,1-0	; Convert from chars to bytes
	 add	 edi,eax	; Add into screen base

	 mov	 dx,ds:[si].NROW ; Get # rows
	 movzx	 ecx,ds:[si].NCOL ; Get # columns

	 REGREST <si,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WSETUP	 endp			; End WSETUP procedure
	 NPPROC  WGET_C -- Input Characters
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Input characters.

|

WGET_C_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WGET_C_DESC dw	 ?		; Offset of descriptor
WGET_C_IBUF dw	 ?		; Offset of input buffer

WGET_C_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ecx,dx,esi,edi,ds,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WGET_C_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to input
	 jz	 short WGET_C_EXIT ; Jump if no rows

	 movzx	 esi,[bp].WGET_C_IBUF ; DS:SI ==> input buffer
	 xchg	 esi,edi	; Swap the offsets

	 push	 es		; Save to swap

	 push	 ds		; Save to swap
	 pop	 es		; Restore to ES
	 assume  es:DGROUP	; Tell the assembler about it

	 pop	 ds		; Restore to DS
	 assume  ds:nothing	; Tell the assembler about it
WGET_C_NEXTROW:
	 REGSAVE <cx,esi>	; Save for a moment
WGET_C_NEXTCOL:
S32	 movs	 <es:[edi].LO,ds:[esi].LO> ; Move the next character

	 inc	 esi		; Skip over attribute

	 loop	 WGET_C_NEXTCOL ; Jump if more characters in this row

	 REGREST <esi,cx>	; Restore

	 add	 esi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WGET_C_NEXTROW ; Jump if more rows to input
WGET_C_EXIT:
	 REGREST <es,ds,edi,esi,dx,ecx> ; Restore
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WGET_C	 endp			; End WGET_C procedure
	 NPPROC  WGET_A -- Input Attributes
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Input attributes.

|

WGET_A_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WGET_A_DESC dw	 ?		; Offset of descriptor
WGET_A_IBUF dw	 ?		; Offset of output buffer

WGET_A_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ecx,dx,esi,edi,ds,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WGET_A_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to input
	 jz	 short WGET_A_EXIT ; Jump if no rows

	 movzx	 esi,[bp].WGET_A_IBUF ; DS:SI ==> input buffer
	 xchg	 esi,edi	; Swap the offsets

	 push	 es		; Save to swap

	 push	 ds		; Save to swap
	 pop	 es		; Restore to ES
	 assume  es:DGROUP	; Tell the assembler about it

	 pop	 ds		; Restore to DS
	 assume  ds:nothing	; Tell the assembler about it
WGET_A_NEXTROW:
	 REGSAVE <cx,esi>	; Save for a moment
WGET_A_NEXTCOL:
	 inc	 esi		; Skip over character

S32	 movs	 <es:[edi].LO,ds:[esi].LO> ; Move the next attribute

	 loop	 WGET_A_NEXTCOL ; Jump if more attributes in this row

	 REGREST <esi,cx>	; Restore

	 add	 esi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WGET_A_NEXTROW ; Jump if more rows to input
WGET_A_EXIT:
	 REGREST <es,ds,edi,esi,dx,ecx> ; Restore
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WGET_A	 endp			; End WGET_A procedure
	 NPPROC  WGET_CA -- Input Characters and Attributes
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Input characters and attributes

|

WGET_CA_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WGET_CA_DESC dw  ?		; Offset of descriptor
WGET_CA_IBUF dw  ?		; Offset of input buffer

WGET_CA_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ecx,dx,esi,edi,ds,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WGET_CA_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to input
	 jz	 short WGET_CA_EXIT ; Jump if no rows

	 movzx	 esi,[bp].WGET_CA_IBUF ; DS:SI ==> input buffer
	 xchg	 esi,edi	; Swap the offsets

	 push	 es		; Save to swap

	 push	 ds		; Save to swap
	 pop	 es		; Restore to ES
	 assume  es:DGROUP	; Tell the assembler about it

	 pop	 ds		; Restore to DS
	 assume  ds:nothing	; Tell the assembler about it
WGET_CA_NEXTROW:
	 REGSAVE <ecx,esi>	; Save for a moment

S32  rep movs	 <DGROUP:[edi].ELO,ds:[esi].ELO> ; Copy chars and attrs to buffer

	 REGREST <esi,ecx>	; Restore

	 add	 esi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WGET_CA_NEXTROW ; Jump if more rows to input
WGET_CA_EXIT:
	 REGREST <es,ds,edi,esi,dx,ecx> ; Restore
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WGET_CA  endp			; End WGET_CA procedure
	 NPPROC  WPUT_C -- Output Characters
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output characters.

|

WPUT_C_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_C_DESC dw	 ?		; Offset of descriptor
WPUT_C_IBUF dw	 ?		; Offset of input buffer

WPUT_C_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ecx,dx,esi,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WPUT_C_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to output
	 jz	 short WPUT_C_EXIT ; Jump if no rows

	 movzx	 esi,[bp].WPUT_C_IBUF ; DS:SI ==> input buffer
WPUT_C_NEXTROW:
	 REGSAVE <cx,edi>	; Save for a moment
WPUT_C_NEXTCOL:
S32	 movs	 <es:[edi].LO,ds:[esi].LO> ; Move the next character

	 inc	 edi		; Skip over attribute

	 loop	 WPUT_C_NEXTCOL ; Jump if more characters in this row

	 REGREST <edi,cx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WPUT_C_NEXTROW ; Jump if more rows to output
WPUT_C_EXIT:
	 REGREST <es,edi,esi,dx,ecx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_C	 endp			; End WPUT_C procedure
	 NPPROC  WPUT_CA -- Output Characters and Attributes
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output characters and attributes.

|

WPUT_CA_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_CA_DESC dw  ?		; Offset of descriptor
WPUT_CA_IBUF dw  ?		; Offset of input buffer

WPUT_CA_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ecx,dx,esi,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WPUT_CA_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to output
	 jz	 short WPUT_CA_EXIT ; Jump if no rows

	 movzx	 esi,[bp].WPUT_CA_IBUF ; DS:SI ==> input buffer
WPUT_CA_NEXTROW:
	 REGSAVE <ecx,edi>	; Save for a moment

S32  rep movs	 <es:[edi].ELO,DGROUP:[esi].ELO> ; Copy chars and attrs to screen

	 REGREST <edi,ecx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WPUT_CA_NEXTROW ; Jump if more rows to output
WPUT_CA_EXIT:
	 REGREST <es,edi,esi,dx,ecx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_CA  endp			; End WPUT_CA procedure
	 NPPROC  WPUT_A -- Output Attributes
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output attributes.

|

WPUT_A_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_A_DESC dw	 ?		; Offset of descriptor
WPUT_A_IBUF dw	 ?		; Offset of input buffer

WPUT_A_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ecx,dx,esi,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WPUT_A_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to output
	 jz	 short WPUT_A_EXIT ; Jump if no rows

	 movzx	 esi,[bp].WPUT_A_IBUF ; DS:SI ==> input buffer
WPUT_A_NEXTROW:
	 REGSAVE <cx,edi>	; Save for a moment
WPUT_A_NEXTCOL:
	 inc	 edi		; Skip over character

S32	 movs	 <es:[edi].LO,ds:[esi].LO> ; Move the next attribute

	 loop	 WPUT_A_NEXTCOL ; Jump if more attributes in this row

	 REGREST <edi,cx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WPUT_A_NEXTROW ; Jump if more rows to output
WPUT_A_EXIT:
	 REGREST <es,edi,esi,dx,ecx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_A	 endp			; End WPUT_A procedure
	 NPPROC  WPUT_ASC -- Output Attribute, Smear Character
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output attribute, smear character.

|

WPUT_ASC_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_ASC_DESC dw ?		; Offset of descriptor
WPUT_ASC_IBUF dw ?		; Offset of input buffer
WPUT_ASC_CHAR db ?,?		; Character to smear

WPUT_ASC_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,ecx,dx,esi,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WPUT_ASC_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to output
	 jz	 short WPUT_ASC_EXIT ; Jump if no rows

	 movzx	 esi,[bp].WPUT_ASC_IBUF ; DS:SI ==> input buffer
	 mov	 ah,[bp].WPUT_ASC_CHAR ; Get the character to smear
WPUT_ASC_NEXTROW:
	 REGSAVE <cx,edi>	; Save for a moment
WPUT_ASC_NEXTCOL:
	 lods	 ds:[esi].LO	; Get the next attribute to output

	 xchg	 al,ah		; Swap character and attribute
S32	 stos	 es:[edi].ELO	; Store it along with the character
	 xchg	 al,ah		; Swap character and attribute

	 loop	 WPUT_ASC_NEXTCOL ; Jump if more attributes in this row

	 REGREST <edi,cx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WPUT_ASC_NEXTROW ; Jump if more rows to output
WPUT_ASC_EXIT:
	 REGREST <es,edi,esi,dx,ecx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_ASC endp			; End WPUT_ASC procedure
	 NPPROC  WPUT_CSA -- Output Characters, Smear Attribute
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Output characters.

|

WPUT_CSA_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_CSA_DESC dw ?		; Offset of descriptor
WPUT_CSA_IBUF dw ?		; Offset of input buffer
WPUT_CSA_ATTR db ?,?		; Attribute to smear

WPUT_CSA_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,ecx,dx,esi,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WPUT_CSA_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to output
	 jz	 short WPUT_CSA_EXIT ; Jump if no rows

	 movzx	 esi,[bp].WPUT_CSA_IBUF ; DS:SI ==> input buffer
	 mov	 ah,[bp].WPUT_CSA_ATTR ; Get the attribute to smear
WPUT_CSA_NEXTROW:
	 REGSAVE <cx,edi>	; Save for a moment
WPUT_CSA_NEXTCOL:
	 lods	 ds:[esi].LO	; Get the next character to output

S32	 stos	 es:[edi].ELO	; Store it along with the attribute

	 loop	 WPUT_CSA_NEXTCOL ; Jump if more characters in this row

	 REGREST <edi,cx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WPUT_CSA_NEXTROW ; Jump if more rows to output
WPUT_CSA_EXIT:
	 REGREST <es,edi,esi,dx,ecx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_CSA endp			; End WPUT_CSA procedure
	 NPPROC  WPUT_SC -- Smear Character
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Smear character.

|

WPUT_SC_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_SC_DESC dw  ?		; Offset of descriptor
WPUT_SC_CHAR db  ?,?		; Character to smear

WPUT_SC_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,ecx,dx,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WPUT_SC_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to output
	 jz	 short WPUT_SC_EXIT ; Jump if no rows

	 mov	 al,[bp].WPUT_SC_CHAR ; Get the character to smear
WPUT_SC_NEXTROW:
	 REGSAVE <cx,edi>	; Save for a moment
@@:
S32	 stos	 es:[edi].LO	; Store character

	 inc	 edi		; Skip over attribute

	 loop	 @B		; Jump if more columns

	 REGREST <edi,cx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WPUT_SC_NEXTROW ; Jump if more rows to output
WPUT_SC_EXIT:
	 REGREST <es,edi,dx,ecx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SC  endp			; End WPUT_SC procedure
	 NPPROC  WPUT_SA -- Smear Attribute
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Smear attribute.

|

WPUT_SA_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_SA_DESC dw  ?		; Offset of descriptor
WPUT_SA_ATTR db  ?,?		; Attribute to smear

WPUT_SA_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,ecx,dx,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WPUT_SA_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to output
	 jz	 short WPUT_SA_EXIT ; Jump if no rows

	 mov	 al,[bp].WPUT_SA_ATTR ; Get the attribute to smear
WPUT_SA_NEXTROW:
	 REGSAVE <cx,edi>	; Save for a moment
@@:
	 inc	 edi		; Skip over character

S32	 stos	 es:[edi].LO	; Store attribute

	 loop	 @B		; Jump if more columns

	 REGREST <edi,cx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WPUT_SA_NEXTROW ; Jump if more rows to output
WPUT_SA_EXIT:
	 REGREST <es,edi,dx,ecx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SA  endp			; End WPUT_SA procedure
	 NPPROC  WPUT_SCA -- Smear Character and Attribute
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Smear character and attribute.

|

WPUT_SCA_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_SCA_DESC dw ?		; Offset of descriptor
WPUT_SCA_CAT dw  ?		; Character/Attribute to smear

WPUT_SCA_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,ecx,dx,edi,es> ; Save registers

	 call	 WSETUP 	; Call common window setup code
				; ES:EDI = screen offset
				; ECX	 = # columns in window
				; DX	 = # rows ...

	 jcxz	 WPUT_SCA_EXIT	; Jump if no columns

	 and	 dx,dx		; Check # rows to output
	 jz	 short WPUT_SCA_EXIT ; Jump if no rows

	 mov	 ax,[bp].WPUT_SCA_CAT ; Get the character/attribute
WPUT_SCA_NEXTROW:
	 REGSAVE <cx,edi>	; Save for a moment

     rep stos	 es:[edi].ELO	; Smear character/attribute throughout the row

	 REGREST <edi,cx>	; Restore

	 add	 edi,@NCOLS*2	; Skip to next row

	 dec	 dx		; Account for one less row
	 jnz	 WPUT_SCA_NEXTROW ; Jump if more rows to output
WPUT_SCA_EXIT:
	 REGREST <es,edi,dx,ecx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SCA endp			; End WPUT_SCA procedure
	 NPPROC  WPUT_SHD1 -- Display A Type 1 Shadow
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a type 1 shadow (outside the existing window).

|

WPUT_SHD1_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_SHD1_DESC dw ?		; Offset of descriptor

WPUT_SHD1_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,si>	; Save registers

; Display the shadow below the window

	 mov	 si,[bp].WPUT_C_DESC ; DS:SI ==> window descriptor

	 mov	 ax,ds:[si].SROW ; Get the starting row
	 add	 ax,ds:[si].NROW ; Plus # rows
	 mov	 W_SHD.SROW,ax	; Save as starting row of shadow

	 mov	 ax,ds:[si].SCOL ; Get the starting col
	 inc	 ax		; Plus one to offset to the right
	 mov	 W_SHD.SCOL,ax	; Save as starting col of shadow

	 mov	 W_SHD.NROW,1	; Save as # rows

	 mov	 ax,ds:[si].NCOL ; Get # cols
	 mov	 W_SHD.NCOL,ax	; Save as # cols

	 call	 WPUT_SHD1_SUB	; Read in attributes, set color

; Display the bottom shadow

	 mov	 al,'ß'         ; Smear an upper-half character
	 push	 ax		; Pass as character to smear
	 push	 offset ds:MSG_SHD1 ; Pass offset of local buffer
	 push	 offset ds:W_SHD ; Pass address of window descriptor
	 call	 WPUT_ASC	; Output the attributes, smear character

; Display the shadow to the right of the window

	 mov	 ax,ds:[si].SROW ; Get the starting row
	 mov	 W_SHD.SROW,ax	; Save as starting row of shadow

	 mov	 ax,ds:[si].SCOL ; Get the starting col
	 add	 ax,ds:[si].NCOL ; Plus # cols
	 mov	 W_SHD.SCOL,ax	; Save as starting col of shadow

	 mov	 ax,ds:[si].NROW ; Get # rows
	 mov	 W_SHD.NROW,ax	; Save as # rows

	 mov	 W_SHD.NCOL,1	; Save as # cols

	 call	 WPUT_SHD1_SUB	; Read in attributes, set color

	 mov	 W_SHD.NROW,1	; Save as # rows

	 mov	 al,'Ü'         ; Smear a lower-half character
	 push	 ax		; Pass as character to smear
	 push	 offset ds:MSG_SHD1 ; Pass offset of local buffer
	 push	 offset ds:W_SHD ; Pass address of window descriptor
	 call	 WPUT_ASC	; Output the attributes, smear character

	 inc	 W_SHD.SROW	; Skip to next row for full charcaters
	 mov	 ax,ds:[si].NROW ; Get # rows
	 dec	 ax		; Less one to account for above offset
	 mov	 W_SHD.NROW,ax	; Save as # rows

	 mov	 al,'Û'         ; Smear a full character
	 push	 ax		; Pass as character to smear
	 push	 offset ds:MSG_SHD1 ; Pass offset of local buffer
	 push	 offset ds:W_SHD ; Pass address of window descriptor
	 call	 WPUT_ASC	; Output the attributes, smear character

	 REGREST <si,ax>	; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SHD1 endp			; End WPUT_SHD1 procedure
	 NPPROC  WPUT_SHD1_SUB -- Read In Attributes, Set Shadow Color
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read in attributes, set shadow color

|

	 REGSAVE <ax,cx,dx,si>	; Save registers

; Read in the exising attributes

	 push	 offset ds:MSG_SHD1 ; Pass address of local buffer
	 push	 offset ds:W_SHD ; Pass address of window descriptor
	 call	 WGET_A 	; Input the attributes

; Set the foreground color of each attribute to black

	 mov	 ax,W_SHD.NROW	; Get # rows
	 mul	 W_SHD.NCOL	; Times # cols
	 mov	 cx,ax		; Copy to count register
	 jcxz	 WPUT_SHD1_SUB_EXIT ; Jump if nothing to do

	 lea	 si,MSG_SHD1	; DS:SI ==> table of attributes
@@:
	 lods	 MSG_SHD1[si]	; Get the next attribute

	 and	 al,@NIB1	; Isolate the background color
	 or	 al,@ATCFFblack ; Set the foreground to black

	 mov	 DGROUP:[si-1],al ; Save back

	 loop	 @B		; Jump if more attributes
WPUT_SHD1_SUB_EXIT:
	 REGREST <si,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SHD1_SUB endp		; End WPUT_SHD1_SUB procedure
	 NPPROC  WPUT_SHD2 -- Display A Type 2 Shadow
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display a type 2 shadow (on the edge of the existing window).

|

WPUT_SHD2_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
WPUT_SHD2_DESC dw ?		; Offset of descriptor

WPUT_SHD2_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,si>	; Save registers

; Display the shadow on the bottom line of the window

	 mov	 si,[bp].WPUT_C_DESC ; DS:SI ==> window descriptor

	 mov	 ax,ds:[si].SROW ; Get the starting row
	 add	 ax,ds:[si].NROW ; Plus # rows
	 dec	 ax		; Less one to address the last row
	 mov	 W_SHD.SROW,ax	; Save as starting row of shadow

	 mov	 ax,ds:[si].SCOL ; Get the starting col
	 inc	 ax		; Plus one to offset to the right
	 mov	 W_SHD.SCOL,ax	; Save as starting col of shadow

	 mov	 W_SHD.NROW,1	; Save as # rows

	 mov	 ax,ds:[si].NCOL ; Get # cols
	 dec	 ax		; Less one to account for above offset
	 mov	 W_SHD.NCOL,ax	; Save as # cols

	 mov	 al,SHD2ATTR	; Get type 2 shadow attribute
	 push	 ax		; Pass as attribute to smear
	 push	 offset ds:W_SHD ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

; Display the shadow on the right edge of the window

	 mov	 ax,ds:[si].SROW ; Get the starting row
	 mov	 W_SHD.SROW,ax	; Save as starting row of shadow

	 mov	 ax,ds:[si].SCOL ; Get the starting col
	 add	 ax,ds:[si].NCOL ; Plus # cols
	 dec	 ax		; Less one to address the last col
	 mov	 W_SHD.SCOL,ax	; Save as starting col of shadow

	 mov	 W_SHD.NCOL,1	; Save as # cols

	 mov	 ax,ds:[si].NROW ; Get # rows
	 mov	 W_SHD.NROW,ax	; Save as # rows

	 mov	 al,SHD2ATTR	; Get type 2 shadow attribute
	 push	 ax		; Pass as attribute to smear
	 push	 offset ds:W_SHD ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

	 REGREST <si,ax>	; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WPUT_SHD2 endp			; End WPUT_SHD2 procedure

CODE	 ends			; End CODE segment

	 MEND			; End MEM_SCRN module

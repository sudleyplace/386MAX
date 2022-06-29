;' $Header:   P:/PVCS/MAX/QUILIB/WINDOWFN.ASV   1.1   30 May 1997 12:09:08   BOB  $
	 title	 WINDOWFN -- Window Functions
	 page	 58,122
	 name	 WINDOWFN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1984-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Depends upon memory model.

Link requirements:  None, standalone object module.

Program derived from:  None.

Original code by:  Bob Smith, February 1984

Modifications by:  Patrick Devlin, December 1990
		   to adapt to Microsoft Mixed Language conventions


			Procedure Specifications

Procedure WPUT_C -- Put characters only into a window.

	 This is a subroutine to display the text defined by ARG2
	 in the window defined by ARG1.  The attributes in the
	 window are unchanged.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = address of window descriptor.
		     ARG2 = address of text to display.

	 Effects:  Display is changed within the specified window.

	 Results:  Flags destroyed, arguments popped from stack.

Procedure WPUT_A -- Put attributes only into a window.

	 This is a subroutine to display the attrs defined by ARG2
	 in the window defined by ARG1.  The text in the
	 window is unchanged.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = address of window descriptor.
		     ARG2 = address of attrs to display.

	 Effects:  Display is changed within the specified window.

	 Results:  Flags destroyed, arguments popped from stack.

Procedure WPUT_SC -- Put an immediate character byte throughout a window.
	 (SC = Smear Character)

	 This is a subroutine to set the screen's character
	 bytes within a specified window to an immediate value.
	 The text in the window is unchanged.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = address of window descriptor.
		     ARG2 = value of specified character.

	 Effects:  Characters are changed within the specified window.

	 Results:  Flags destroyed, arguments popped from stack.

Procedure WPUT_SA -- Put an immediate attribute byte throughout a window.
	 (SA = Smear Attribute)

	 This is a subroutine to set the screen's attribute
	 bytes within a specified window to an immediate value.
	 The text in the window is unchanged.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = address of window descriptor.
		     ARG2 = value of specified attribute.

	 Effects:  Attributes are changed within the specified window.

	 Results:  Flags destroyed, arguments popped from stack.

Procedure WPUT_CA -- Put text and attributes into a window.

	 This is a subroutine to set the text and attribute
	 bytes within a specified window.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = address of window descriptor.
		     ARG2 = address of text and attributes.

	 Effects:  Contents of the specified window are changed.

	 Results:  Flags destroyed, arguments popped from stack.

Procedure WPUT_SCA -- Put an immediate text and attribute word into a window.
	 (SCA = Smear Character & Attribute)

	 This is a subroutine to set the screen's text and attribute
	 bytes within a specified window to an immediate value.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = address of window descriptor.
		     ARG2 = text character and attribute byte

	 Effects:  Contents of the specified window are changed.

	 Results:  Flags destroyed, arguments popped from stack.

Procedure WPUT_CSA -- Put text and immediate attribute into a window.
	 (CSA = Character & Smear Attribute)

	 This is a subroutine to set the text and an immediate attribute
	 byte within a specified window.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = address of window descriptor.
		     ARG2 = address of text.
		     ARG3 = value of attribute to be set.

	 Effects:  Contents of the specified window are changed.

	 Results:  Flags destroyed, arguments popped from stack.

Procedure WGET_C -- Get chararacters only from a window.

	 This is a subroutine to place the text from the window
	 defined in ARG1 into the area defined by ARG2.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = address of window descriptor.
		     ARG2 = address of where to put text.

	 Effects:  None.

	 Results:  Flags destroyed, arguments popped from stack.

Procedure WGET_A -- Get attributes only from a window.

	 This is a subroutine to place the attrs from the window
	 defined in ARG1 into the area defined by ARG2.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = address of window descriptor.
		     ARG2 = address of where to put attrs.

	 Effects:  None.

	 Results:  Flags destroyed, arguments popped from stack.

Procedure WGET_CA -- Get chararacters and attributes from a window.

	 This is a subroutine to place the text and attributes from the
	 window defined in ARG1 into the area defined by ARG2.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = address of window descriptor.
		     ARG2 = address of where to put text
			    and attributes.

	 Effects:  None.

	 Results:  Flags destroyed, arguments popped from stack.

Procedure SET_MODE -- Set the video state to an 80-column screen

	 This is a subroutine to set the video state to that of an
	 80-column screen by using the BIOS INT 10h calls.

	 Assumptions:  To be called from a Microsoft C program.

	 Linkage:  Near/far call and return.

	 Arguments:  ARG1 = FAST_MODE, SLOW_MODE, or SCRUP_MODE
			    for graphics screen update.

	 Effects:  Video state is changed to 80-column screen
		   and the graphics screen update mode is set.

	 Results:  Flags destroyed, arguments popped from stack.

|
.8086
.xlist
	 include MASM.INC
	 include VIDCALL.INC
.list

%.model  &MODEL,c

;;;;;;	 include CPUID.INC
	 page
; M A C R O S

$WAIT_VR macro			; Wait for vertical retrace
	 local	 LAB
LAB:
	 in	 al,dx		; Get 6845 video status

	 test	 al,@VERT_SYNC	; Vertical retrace active?
	 jz	 LAB		; No, wait until it is

	 endm			; $WAIT_VR

$JMP_VR  macro	 LAB		; Jump if the display is in vertical retrace

	 in	 al,dx		; Get 6845 video status

	 test	 al,@VERT_SYNC	; Vertical retrace active?
	 jnz	 LAB		; Yes

	 endm			; $JMP_VR

$JMP_NVR macro	 LAB		; Jump if the display is not in vertical retrace

	 in	 al,dx		; Get 6845 video status

	 test	 al,@VERT_SYNC	; Vertical retrace active?
	 jz	 LAB		; No

	 endm			; $JMP_NVR

$WAIT_ACT macro 		; Wait until the display is active
	 local	 LAB
LAB:
	 in	 al,dx		; Get 6845 video status

	 ror	 al,1		; Display inactive?
	 jc	 LAB		; Yes, wait until it's active

	 endm			; $WAIT_ACT

$WAIT_INACT macro		; Wait until the display is inactive
	 local	 LAB
LAB:
	 in	 al,dx		; Get 6845 video status

	 ror	 al,1		; Display inactive?
	 jnc	 LAB		; No, wait until it's inactive

	 endm			; $WAIT_INACT

$GETPUTMAC macro TYP,SDAT,RDAT,SSCR,RSCR

	 sub	 sp,6*2 	; Push on [bp].NCOLS
				;	  [bp].NROWS
				;	  [bp].WSIZE
				;	  [bp].ADDRINC
				;	  [bp].VRROW
				;	  [bp].HRROW
	 mov	 bp,sp		; Address the stack

	 cld			; String ops forwardly

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save all registers

if	 @datasize
	 lds	 bx,dword ptr [bp].ARG1 ; DS:BX ==> window descriptor
	 assume  ds:nothing
else
	 mov	 bx,[bp].ARG1	; DS:BX ==> window descriptor
endif

	 mov	 ax,[bx].ROW$	; Get row offset
	 mov	 RSCR,[bx].COL$ ; Get column offset
	 mov	 dx,[bx].NROWS$ ; Get # rows in window
	 mov	 cx,[bx].NCOLS$ ; Get # columns in window

	 jcxz	 W&TYP&_EXIT0	; Exit if no cols in window

	 and	 dx,dx		; Check for no rows
	 jnz	 W&TYP&_COM1	; Continue on
W&TYP&_EXIT0:
	 jmp	 W&TYP&_EXIT	; None
W&TYP&_COM1:
	 mov	 ah,NSCR_COLS	; # screen columns
	 mul	 ah		; Is now byte offset in screen buffer
	 add	 RSCR,ax	; Add to column offset
	 shl	 RSCR,1 	; Times 2 'cause of attribute bytes

if	 @datasize
	 l&SDAT  RDAT,dword ptr [bp].ARG2 ; DS:SI or ES:DI ==> data (if not WPUT_SA)
	 assume  SDAT:nothing
else
 ifdif	  <ds>,<SDAT>
	 push	 ds		; Move data segment address
	 pop	 SDAT		; ...to ES for MOVSB
	 assume  SDAT:nothing
 endif				; IFDIF

	 mov	 RDAT,[bp].ARG2 ; DS:SI or ES:DI ==> data (if not WPUT_SA)
endif

; Setup SSCR as screen buffer segment

	 mov	 ax,SCR_SEG	; Get screen buffer address
	 add	 ah,DISP_PAGE	; Account for display page #
	 mov	 SSCR,ax	; Set screen buffer address
	 assume  SSCR:nothing

; Compute window size (rows x cols)

	 mov	 al,cl		; Copy # window columns
	 mul	 dl		; Times # window rows
	 mov	 [bp].WSIZE,ax	; Save as total # chars in window

; Compute address increment for SI or DI after processing a single window row

	 mov	 ax,word ptr NSCR_COLS ; Get # screen columns
	 sub	 ax,cx		; Less # window columns
	 shl	 ax,1		; Times 2 'cause of attribute bytes
	 mov	 [bp].ADDRINC,ax ; Save for later use

; Save # rows and cols in window

	 mov	 [bp].NROWS,dx	; Save # rows for later
	 mov	 [bp].NCOLS,cx	; Save # cols for later

; Split case between fast & slow processing routines

	 cmp	 UPD_MODE,FAST_MODE ; Check update mode
	 MJ e	 W&TYP&_FAST	; It's fast

; Slow processing routine

	 cli			; Disallow interrupts

	 cmp	 cl,NSCR_COLS	; Putting out full rows?
	 jne	 W&TYP&_PARTSLOW ; Not this time

; Full rows, slow processing routine

	 mov	 dx,@COLR_STAT	; Port address of 6845 status register

	 $JMP_VR W&TYP&_FULLSLOW3 ; Jump if we're in vertical retrace
W&TYP&_FULLSLOW:
	 mov	 cx,[bp].VRCNT	; # characters per vertical retrace

	 cmp	 cx,[bp].WSIZE	; Use the smaller of the two
	 jbe	 W&TYP&_FULLSLOW1 ; CX is no larger

	 mov	 cx,[bp].WSIZE	; Use all remaining characters
W&TYP&_FULLSLOW1:
	 jcxz	 W&TYP&_EXIT0	; Jump if none remaining

	 sub	 [bp].WSIZE,cx	; Account for them

	 call	 VERT_WAIT	; Wait for vertical retrace
W&TYP&_FULLSLOW2:
	 call	 [bp].FASTFN	; Use fast processing routine

; Process characters during horizontal retrace period

W&TYP&_FULLSLOW3:
	 mov	 cx,HRCNT	; # characters during horizontal retrace

	 cmp	 cx,[bp].WSIZE	; Use the smaller of the two
	 jbe	 W&TYP&_FULLSLOW4 ; CX is no larger

	 mov	 cx,[bp].WSIZE	; Use all remaining characters
W&TYP&_FULLSLOW4:
	 jcxz	 W&TYP&_EXIT0	; Jump if none remaining

	 sub	 [bp].WSIZE,cx	; Account for them

	 call	 [bp].SLOWFN	; Use slow processing routine

;;;;;;;; sti			; Allow interrupts again

	 jmp	 W&TYP&_FULLSLOW ; Go around again

; Partial rows, slow processing routine

W&TYP&_PARTSLOW:

; Compute how many complete window rows we can output
; during a vertical retrace period

	 mov	 ax,[bp].VRCNT	; Get normal # chars per vertical retrace
;;;;;;;; mov	 bx,[bp].NCOLS	; Get # cols in window
;;;;;;;; add	 bx,VRSLOP	; Add in slop
;;;;;;;; xor	 dx,dx		; Zero for divide
;;;;;;;; div	 bx		; Divide
	 mov	 [bp].VRROW,ax	; Save for later use

; Compute how many complete window rows we can output
; during a horizontal retrace period

	 mov	 ax,HRCNT	; Get normal # chars per horizontal retrace
;;;;;;;; mov	 bx,[bp].NCOLS	; Get # cols in window
;;;;;;;; add	 bx,HRSLOP	; Add in slop
;;;;;;;; xor	 dx,dx		; Zero for divide
;;;;;;;; div	 bx		; Divide
;;;;;;;; cmp	 ax,1		; Ensure it's at least one
;;;;;;;; adc	 ax,0		; Add in 1 if it's zero
	 mov	 [bp].HRROW,ax	; Save for later use

	 mov	 dx,@COLR_STAT	; Port address of 6845 status register

	 $JMP_VR W&TYP&_PARTSLOW3 ; Jump if we're already in vertical retrace
W&TYP&_PARTSLOW1:
	 mov	 bx,[bp].VRROW	; Get # rows to process per vertical retrace

	 call	 VERT_WAIT	; Wait for vertical retrace
;;;;;;;; $WAIT_VR		; Wait for vertical retrace
W&TYP&_PARTSLOW2:
	 mov	 cx,[bp].NCOLS	; Put out a row's worth
	 call	 [bp].SLOWFN	; Use slow processing routine
	 add	 RSCR,[bp].ADDRINC ; Skip to next row in screen buffer

	 dec	 [bp].NROWS	; One fewer row
	 jz	 W&TYP&_EXIT	; Jump if none remaining

	 dec	 bx		; One fewer row
	 jnz	 W&TYP&_PARTSLOW2 ; Jump if more remaining
W&TYP&_PARTSLOW3:
	 mov	 bx,[bp].HRROW	; Get # rows to process per horizontal retrace
W&TYP&_PARTSLOW4:
	 mov	 cx,[bp].NCOLS	; Put out a row's worth
	 call	 [bp].SLOWFN	; Use slow processing routine
	 add	 RSCR,[bp].ADDRINC ; Skip to next row in screen buffer

	 dec	 [bp].NROWS	; One fewer row
	 jz	 W&TYP&_EXIT	; Jump if none remaining

	 dec	 bx		; One fewer row
	 jnz	 W&TYP&_PARTSLOW4 ; Jump if more remaining

;;;;;;;; sti			; Allow interrupts again

	 jmp	 W&TYP&_PARTSLOW1 ; Go around again

; Fast processing routine

W&TYP&_FAST:
	 cmp	 cl,NSCR_COLS	; Putting out full rows?
	 jne	 W&TYP&_PARTFAST ; Not this time

; Full rows, fast processing routine

	 mov	 cx,[bp].WSIZE	; Get total # characters in window
	 call	 [bp].FASTFN	; Do all the work at once

	 jmp	 short W&TYP&_EXIT ; Join common exit code

; Partial rows, fast processing routine

W&TYP&_PARTFAST:
	 mov	 cx,[bp].NCOLS	; Get # columns in window

	 call	 [bp].FASTFN	; Call fast processing routine
	 add	 RSCR,[bp].ADDRINC ; Skip to next row in screen buffer

	 dec	 [bp].NROWS	; One fewer row
	 jnz	 W&TYP&_PARTFAST ; Jump if more to process
W&TYP&_EXIT:
	 sti			; Allow interrupts again

	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore 'em
	 assume  ds:nothing,es:nothing

	 add	 sp,6*2 	; Pop off [bp].NCOLS
				;	  [bp].NROWS
				;	  [bp].WSIZE
				;	  [bp].ADDRINC
				;	  [bp].VRROW
				;	  [bp].HRROW
	 ret			; Return to WPUT_/WGET_ caller

	 assume  ds:nothing,es:nothing

	 endm			; $GETPUTMAC

;;;;;;	 page
	 .data
; S T R U C T U R E S

ARGS	 struc
NCOLS	 dw	 ?		; # cols in window
NROWS	 dw	 ?		; # rows in window
WSIZE	 dw	 ?		; Window size (rows x cols)
ADDRINC  dw	 ?		; Address increment
HRROW	 dw	 ?		; # rows per horizontal retrace period
VRROW	 dw	 ?		; # rows per vertical ...
	 dw	 ?		; Local caller's return address
VRCNT	 dw	 ?		; Char count for vertical retrace period
SLOWFN	 dw	 ?		; Local slow routine
FASTFN	 dw	 ?		; Local fast routine
	 dw	 ?		; Caller's BP
if	 @codesize
	 dd	 ?		; Return address
else
	 dw	 ?		; Return address
endif
if	 @datasize
ARG1	 dd	 ?		; Address of window descriptor
ARG2	 dd	 ?		; Address of window data
else
ARG1	 dw	 ?		; Address of window descriptor
ARG2	 dw	 ?		; Address of window data
endif
ARG3	 dw	 ?		; Value of immediate attribute (for WPUT_CSA)
ARGS	 ends

SET_MODE_STR struc
	 dw	 ?		; Caller's BP
if	 @codesize
	 dd	 ?		; Return address
else
	 dw	 ?		; Return address
endif
MODE_BYTE db	 ?		; Mode byte
SET_MODE_STR ends

	 if	 0
ARGS	 struc
NCOLS	 dw	 ?		; # cols in window
NROWS	 dw	 ?		; # rows in window
WSIZE	 dw	 ?		; Window size (rows x cols)
ADDRINC  dw	 ?		; Address increment
HRROW	 dw	 ?		; # rows per horizontal retrace period
VRROW	 dw	 ?		; # rows per vertical ...
	 dw	 ?		; Local caller's return address
VRCNT	 dw	 ?		; Char count for vertical retrace period
SLOWFN	 dw	 ?		; Local slow routine
FASTFN	 dw	 ?		; Local fast routine
	 dw	 ?		; Caller's BP
	 dw	 ?		; Return address
ARG1	 dd	 ?		; Address of window descriptor
ARG2	 dd	 ?		; Address of window data
ARG3	 dw	 ?		; Value of immediate attribute (for WPUT_CSA)
ARGS	 ends

SET_MODE_STR struc
	 dw	 ?		; Caller's BP
	 dw	 ?		; Return address
MODE_BYTE db	 ?		; Mode byte
SET_MODE_STR ends
	 endif

	 if	 0
ARGS	 struc
NCOLS	 dw	 ?		; # cols in window
NROWS	 dw	 ?		; # rows in window
WSIZE	 dw	 ?		; Window size (rows x cols)
ADDRINC  dw	 ?		; Address increment
HRROW	 dw	 ?		; # rows per horizontal retrace period
VRROW	 dw	 ?		; # rows per vertical ...
	 dw	 ?		; Local caller's return address
VRCNT	 dw	 ?		; Char count for vertical retrace period
SLOWFN	 dw	 ?		; Local slow routine
FASTFN	 dw	 ?		; Local fast routine
	 dw	 ?		; Caller's BP
	 dd	 ?		; Return address
ARG1	 dw	 ?		; Address of window descriptor
ARG2	 dw	 ?		; Address of window data
ARG3	 dw	 ?		; Value of immediate attribute (for WPUT_CSA)
ARGS	 ends

SET_MODE_STR struc
	 dw	 ?		; Caller's BP
	 dd	 ?		; Return address
MODE_BYTE db	 ?		; Mode byte
SET_MODE_STR ends
	 endif

	 if	 0
ARGS	 struc
NCOLS	 dw	 ?		; # cols in window
NROWS	 dw	 ?		; # rows in window
WSIZE	 dw	 ?		; Window size (rows x cols)
ADDRINC  dw	 ?		; Address increment
HRROW	 dw	 ?		; # rows per horizontal retrace period
VRROW	 dw	 ?		; # rows per vertical ...
	 dw	 ?		; Local caller's return address
VRCNT	 dw	 ?		; Char count for vertical retrace period
SLOWFN	 dw	 ?		; Local slow routine
FASTFN	 dw	 ?		; Local fast routine
	 dw	 ?		; Caller's BP
	 dd	 ?		; Return address
ARG1	 dd	 ?		; Address of window descriptor
ARG2	 dd	 ?		; Address of window data
ARG3	 dw	 ?		; Value of immediate attribute (for WPUT_CSA)
ARGS	 ends

SET_MODE_STR struc
	 dw	 ?		; Caller's BP
	 dd	 ?		; Return address
MODE_BYTE db	 ?		; Mode byte
SET_MODE_STR ends
	 endif

WINDOW	 struc

ROW$	 dw	 ?		; Row # of upper-left corner
COL$	 dw	 ?		; Col # of   "     "
NROWS$	 dw	 ?		; # rows in the window
NCOLS$	 dw	 ?		; # columns in the window

WINDOW	 ends

@COLR_ADDR equ	 03D4h		; Address register of 6845
@COLR_STAT equ	 03DAh		; Port address for 6845 status register
@DISP_INACT equ  0001b		; Bit to test for 6845 display inactive
@VERT_SYNC  equ  1000b		; Bit to test for 6845 vertical retrace active

	 page

; Data area for following routines -- Note this area *MUST* be in
; CODE segment so it will use a CS: override; DS is used otherwise.

@WPUT_C  equ	 4+4*@datasize	    ; # argument bytes for WPUT_C
@WPUT_A  equ	 4+4*@datasize
@WPUT_SA equ	 4+2*@datasize
@WPUT_SC equ	 4+2*@datasize
@WPUT_CA equ	 4+4*@datasize
@WPUT_SCA equ	 4+2*@datasize
@WPUT_CSA equ	 6+4*@datasize
@WGET_C  equ	 4+4*@datasize
@WGET_A  equ	 4+4*@datasize
@WGET_CA equ	 4+4*@datasize

MONO_SEG equ	 0B000h 	; Segment for monochrome screen buffer
COLR_SEG equ	 0B800h 	; Segment for color screen buffer
SCR_SEG  dw	 MONO_SEG	; Screen segment

@DIR_TEST equ	 5Ah		; PGC direct mode test value
@EMU_TEST equ	 28h		; PGC emulator ...

PGC_DIR  dd	 0C60003DBh	; PGC direct   mode test byte address
PGC_EMU  dd	 0C60003D4h	; PGC emulator ...

	 public  HRCNT,VRCNT_A,VRCNT_B,VRCNT_C,VRCNT_D,VRCNT_E
HRCNT	 dw	 24		; # characters output during horizontal retrace
; Same for vertical retrace
VRCNT_A  dw	 4*80		; Type A = WPUT_C, WPUT_A, WGET_C, WGET_A
VRCNT_B  dw	 4*80		;      B = WPUT_SC, WPUT_SA
VRCNT_C  dw	 4*80		;      C = WPUT_CA, WGET_CA
VRCNT_D  dw	 4*80		;      D = WPUT_SCA
VRCNT_E  dw	 4*80		;      E = WPUT_CSA

;;;;;;;; public  HRSLOP,VRSLOP
;;HRSLOP   dw	   5		  ; Slop for horizontal retrace
;;VRSLOP   dw	   5		  ; ...      vertical

	 public  REGH_SIZ
REGH_SIZ dw	 2		; Size of Region H (in units of iterations)

	 public  NSCR_COLS,NSCR_ROWS,DISP_PAGE,CRT_MODE
NSCR_COLS db	 ?,0		; # screen columns
NSCR_ROWS db	 25,0		; # screen rows
				; (with trailing 0 so they may be used as words)
DISP_PAGE db	 ?		; Active display page
CRT_MODE  db	 ?		; CRT mode

	 public  FAST_MODE,SLOW_MODE,SCRUP_MODE
FAST_MODE equ	 0		; Flags for update modes
SLOW_MODE equ	 1
SCRUP_MODE equ	 2

	 public  GRF_MODE
GRF_MODE db	 FAST_MODE	; Save area for original graphics screen update flag
UPD_MODE db	 FAST_MODE	; Screen update mode
				; Fast for monochrome or color/graphics when
				; specified, slow otherwise

;		 0 1 2 3 4 5 6 7 8 9 A	B C D E F 10   mode in AL
MODE_TABLE db	 2,3,2,3,3,2,2,7,3,3,3,11,?,3,3,7, 3 ; Translate to this mode
MODE_TABLE_LEN equ $-MODE_TABLE ; Length of the table

	 subttl  Code Segment
	 .code
	 PPROC	 wput_c 	;-- Put Characters
;;;;;;	 assume  ds:nothing,es:nothing
	 assume  es:nothing

	 push	 bp		; Prepare to address the stack

	 lea	 bp,WPUT_C_FAST ; Address of local fast processing routine
	 push	 bp		; Put on stack

	 lea	 bp,WPUT_C_SLOW ; Address of local slow processing routine
	 push	 bp		; Put on stack

	 push	 VRCNT_A	; Use this count value for vertical retrace

	 call	 WPUT_COM	; Call common code

	 add	 sp,6		; Pop off [bp].VRCNT
				;	  [bp].SLOWFN
				;	  [bp].FASTFN
	 pop	 bp		; Restore

	 ret			; Return to caller.

;;;;;;	 assume  ds:nothing,es:nothing
	 assume  es:nothing

wput_c	 endp			; End WPUT_C procedure
	 NPROC	 WPUT_C_FAST	;-- WPUT_C Fast Processing Routine
;;;;;;	 assume  ds:nothing,es:nothing
	 assume  es:nothing

WPUT_C_FAST1:
	 movsb			; Move the next byte to the screen
	 inc	 di		; Skip over attribute byte

	 loop	 WPUT_C_FAST1	; Jump if more bytes in this row

	 ret			; Return to caller

;;;;;;	 assume  ds:nothing,es:nothing
	 assume  es:nothing

WPUT_C_FAST endp		; End WPUT_C_FAST procedure
	 NPROC	 WPUT_C_SLOW	;-- WPUT_C Slow Processing Routine
;;;;;;	 assume  ds:nothing,es:nothing
	 assume  es:nothing

WPUT_C_SLOW1:
	 $WAIT_ACT		; Wait until the display is active
	 $WAIT_INACT		; Wait until the display is inactive

	 movsb			; Move the next byte to the screen
	 inc	 di		; Skip over attribute byte

	 loop	 WPUT_C_SLOW1	; Jump if more bytes in this row

	 ret			; Return to caller

;;;;;;	 assume  ds:nothing,es:nothing
	 assume  ds:nothing,es:nothing

WPUT_C_SLOW endp		; End WPUT_C_SLOW procedure
	 PPROC	 wput_a 	;-- Put Attributes
	 assume  ds:nothing,es:nothing

	 push	 bp		; Prepare to address the stack

	 lea	 bp,WPUT_A_FAST ; Address of local fast processing routine
	 push	 bp		; Put on stack

	 lea	 bp,WPUT_A_SLOW ; Address of local slow processing routine
	 push	 bp		; Put on stack

	 push	 VRCNT_A	; Use this count value for vertical retrace

	 call	 WPUT_COM	; Call common code

	 add	 sp,6		; Pop off [bp].VRCNT
				;	  [bp].SLOWFN
				;	  [bp].FASTFN
	 pop	 bp		; Restore

	 ret			; Return to caller.

	 assume  ds:nothing,es:nothing

wput_a	 endp			; End WPUT_A procedure
	 NPROC	 WPUT_A_FAST	;-- WPUT_A Fast Processing Routine
	 assume  ds:nothing,es:nothing

WPUT_A_FAST1:
	 inc	 di		; Skip over text byte
	 movsb			; Move the next byte to the screen

	 loop	 WPUT_A_FAST1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_A_FAST endp		; End WPUT_A_FAST procedure
	 NPROC	 WPUT_A_SLOW	;-- WPUT_A Slow Processing Routine
	 assume  ds:nothing,es:nothing

WPUT_A_SLOW1:
	 inc	 di		; Skip over text byte

	 $WAIT_ACT		; Wait until the display is active
	 $WAIT_INACT		; Wait until the display is inactive

	 movsb			; Move the next byte to the screen

	 loop	 WPUT_A_SLOW1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_A_SLOW endp		; End WPUT_A_SLOW procedure
	 PPROC	 wput_sc	;-- Smear A Character
	 assume  ds:nothing,es:nothing

	 push	 bp		; Prepare to address the stack

	 lea	 bp,WPUT_SC_FAST ; Address of local fast processing routine
	 push	 bp		; Put on stack

	 lea	 bp,WPUT_SC_SLOW ; Address of local slow processing routine
	 push	 bp		; Put on stack

	 push	 VRCNT_B	; Use this count value for vertical retrace

	 call	 WPUT_COM	; Call common code

	 add	 sp,6		; Pop off [bp].VRCNT
				;	  [bp].SLOWFN
				;	  [bp].FASTFN
	 pop	 bp		; Restore

	 ret			; Return to caller.

	 assume  ds:nothing,es:nothing

WPUT_SC  endp			; End WPUT_SC procedure
	 NPROC	 WPUT_SC_FAST	;-- WPUT_SC Fast Processing Routine
	 assume  ds:nothing,es:nothing

	 mov	 al,byte ptr [bp].ARG2 ; New character
WPUT_SC_FAST1:
	 stosb			; Store the next character byte to the screen
	 inc	 di		; Skip over attr byte

	 loop	 WPUT_SC_FAST1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_SC_FAST endp		; End WPUT_SC_FAST procedure
	 NPROC	 WPUT_SC_SLOW	;-- WPUT_SC Slow Processing Routine
	 assume  ds:nothing,es:nothing

	 mov	 ah,byte ptr [bp].ARG2 ; New character
WPUT_SC_SLOW1:
	 $WAIT_ACT		; Wait until the display is active
	 $WAIT_INACT		; Wait until the display is inactive

	 mov	 al,ah		; New character
	 stosb			; Store the next character byte to the screen
	 inc	 di		; Skip over attr byte

	 loop	 WPUT_SC_SLOW1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_SC_SLOW endp		; End WPUT_SC_SLOW procedure
	 PPROC	 wput_sa	;-- Smear An Attribute
	 assume  ds:nothing,es:nothing

	 push	 bp		; Prepare to address the stack

	 lea	 bp,WPUT_SA_FAST ; Address of local fast processing routine
	 push	 bp		; Put on stack

	 lea	 bp,WPUT_SA_SLOW ; Address of local slow processing routine
	 push	 bp		; Put on stack

	 push	 VRCNT_B	; Use this count value for vertical retrace

	 call	 WPUT_COM	; Call common code

	 add	 sp,6		; Pop off [bp].VRCNT
				;	  [bp].SLOWFN
				;	  [bp].FASTFN
	 pop	 bp		; Restore

	 ret			; Return to caller.

	 assume  ds:nothing,es:nothing

wput_sa  endp			; End WPUT_SA procedure
	 NPROC	 WPUT_SA_FAST	;-- WPUT_SA Fast Processing Routine
	 assume  ds:nothing,es:nothing

	 mov	 al,byte ptr [bp].ARG2 ; New attribute
WPUT_SA_FAST1:
	 inc	 di		; Skip over text byte
	 stosb			; Store the next attribute byte to the screen

	 loop	 WPUT_SA_FAST1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_SA_FAST endp		; End WPUT_SA_FAST procedure
	 NPROC	 WPUT_SA_SLOW	;-- WPUT_SA Slow Processing Routine
	 assume  ds:nothing,es:nothing

	 mov	 ah,byte ptr [bp].ARG2 ; New attribute
WPUT_SA_SLOW1:
	 inc	 di		; Skip over text byte

	 $WAIT_ACT		; Wait until the display is active
	 $WAIT_INACT		; Wait until the display is inactive

	 mov	 al,ah		; New attribute
	 stosb			; Store the next attribute byte to the screen

	 loop	 WPUT_SA_SLOW1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_SA_SLOW endp		; End WPUT_SA_SLOW procedure
	 PPROC	 wput_ca	;-- Put Characters & Attributes
	 assume  ds:nothing,es:nothing

	 push	 bp		; Prepare to address the stack

	 lea	 bp,WPUT_CA_FAST ; Address of local fast processing routine
	 push	 bp		; Put on stack

	 lea	 bp,WPUT_CA_SLOW ; Address of local slow processing routine
	 push	 bp		; Put on stack

	 push	 VRCNT_C	; Use this count value for vertical retrace

	 call	 WPUT_COM	; Call common code

	 add	 sp,6		; Pop off [bp].VRCNT
				;	  [bp].SLOWFN
				;	  [bp].FASTFN
	 pop	 bp		; Restore

	 ret			; Return to caller.

	 assume  ds:nothing,es:nothing

wput_ca  endp			; End WPUT_CA procedure
	 NPROC	 WPUT_CA_FAST	;-- WPUT_CA Fast Processing Routine
	 assume  ds:nothing,es:nothing

     rep movsw			; Move it in one fell swoop

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_CA_FAST endp		; End WPUT_CA_FAST procedure
	 NPROC	 WPUT_CA_SLOW	;-- WPUT_CA Slow Processing Routine
	 assume  ds:nothing,es:nothing

WPUT_CA_SLOW1:
	 $WAIT_ACT		; Wait until the display is active
	 $WAIT_INACT		; Wait until the display is inactive

	 movsw			; Move it in one fell swoop

	 loop	 WPUT_CA_SLOW1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_CA_SLOW endp		; End WPUT_CA_SLOW procedure
	 PPROC	 wput_sca	;-- Smear A Character & Attribute
	 assume  ds:nothing,es:nothing

	 push	 bp		; Prepare to address the stack

	 lea	 bp,WPUT_SCA_FAST ; Address of local fast processing routine
	 push	 bp		; Put on stack

	 lea	 bp,WPUT_SCA_SLOW ; Address of local slow processing routine
	 push	 bp		; Put on stack

	 push	 VRCNT_D	; Use this count value for vertical retrace

	 call	 WPUT_COM	; Call common code

	 add	 sp,6		; Pop off [bp].VRCNT
				;	  [bp].SLOWFN
				;	  [bp].FASTFN
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

wput_sca endp			; End WPUT_SCA procedure
	 NPROC	 WPUT_SCA_FAST	;-- WPUT_SCA Fast Processing Routine
	 assume  ds:nothing,es:nothing

	 mov	 ax,word ptr [bp].ARG2 ; Get text and attribute
     rep stosw			; Move it in one fell swoop

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_SCA_FAST endp		; End WPUT_SCA_FAST procedure
	 NPROC	 WPUT_SCA_SLOW	;-- WPUT_SCA Slow Processing Routine
	 assume  ds:nothing,es:nothing

WPUT_SCA_SLOW1:
	 $WAIT_ACT		; Wait until the display is active
	 $WAIT_INACT		; Wait until the display is inactive

	 mov	 ax,word ptr [bp].ARG2 ; Get text and attribute
	 stosw			; Move it in one fell swoop

	 loop	 WPUT_SCA_SLOW1 ; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_SCA_SLOW endp		; End WPUT_SCA_SLOW procedure
	 PPROC	 wput_csa	;-- Put A Character & Smear An Attribute
	 assume  ds:nothing,es:nothing

	 push	 bp		; Prepare to address the stack

	 lea	 bp,WPUT_CSA_FAST ; Address of local fast processing routine
	 push	 bp		; Put on stack

	 lea	 bp,WPUT_CSA_SLOW ; Address of local slow processing routine
	 push	 bp		; Put on stack

	 push	 VRCNT_E	; Use this count value for vertical retrace

	 call	 WPUT_COM	; Call common code

	 add	 sp,6		; Pop off [bp].VRCNT
				;	  [bp].SLOWFN
				;	  [bp].FASTFN
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

wput_csa endp			; End WPUT_CSA procedure
	 NPROC	 WPUT_CSA_FAST	;-- WPUT_CSA Fast Processing Routine
	 assume  ds:nothing,es:nothing

	 mov	 ah,byte ptr [bp].ARG3 ; New attribute
WPUT_CSA_FAST1:
	 lodsb			; Load up the next data byte
	 stosw			; Store on screen with attribute byte

	 loop	 WPUT_CSA_FAST1 ; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_CSA_FAST endp		; End WPUT_CSA_FAST procedure
	 NPROC	 WPUT_CSA_SLOW	;-- WPUT_CSA Slow Processing Routine
	 assume  ds:nothing,es:nothing

	 mov	 ah,byte ptr [bp].ARG3 ; New attribute
WPUT_CSA_SLOW1:
	 $WAIT_ACT		; Wait until the display is active
	 $WAIT_INACT		; Wait until the display is inactive

	 lodsb			; Load up the next data byte
	 stosw			; Store on screen with attribute byte

	 loop	 WPUT_CSA_SLOW1 ; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WPUT_CSA_SLOW endp		; End WPUT_CSA_SLOW procedure
	 NPROC	 WPUT_COM	;-- Common WPUT Processing Routine
	 assume  ds:nothing,es:nothing

	 $GETPUTMAC PUT,ds,si,es,di ; Use common macro

WPUT_COM endp			; End WPUT_COM procedure
	 PPROC	 wget_c 	;-- Get Characters
	 assume  ds:nothing,es:nothing

	 push	 bp		; Save on stack

	 lea	 bp,WGET_C_FAST ; Address of local fast processing routine
	 push	 bp		; Put on stack

	 lea	 bp,WGET_C_SLOW ; Address of local slow processing routine
	 push	 bp		; Put on stack

	 push	 VRCNT_A	; Use this count value for vertical retrace

	 call	 WGET_COM	; Call common code

	 add	 sp,6		; Pop off [bp].VRCNT
				;	  [bp].SLOWFN
				;	  [bp].FASTFN
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WGET_C	 endp			; End WGET_C procedure
	 NPROC	 WGET_C_FAST	;-- WGET_C Fast Processing Routine
	 assume  ds:nothing,es:nothing

WGET_C_FAST1:
	 movsb			; Move the next byte from the screen
	 inc	 si		; Skip over attribute byte

	 loop	 WGET_C_FAST1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WGET_C_FAST endp		; End WGET_C_FAST procedure
	 NPROC	 WGET_C_SLOW	;-- WGET_C Slow Processing Routine
	 assume  ds:nothing,es:nothing

WGET_C_SLOW1:
	 $WAIT_ACT		; Wait until the display is active
	 $WAIT_INACT		; Wait until the display is inactive

	 movsb			; Move the next byte from the screen
	 inc	 si		; Skip over attribute byte

	 loop	 WGET_C_SLOW1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WGET_C_SLOW endp		; End WGET_C_SLOW procedure
	 PPROC	 wget_a 	;-- Get Attributes
	 assume  ds:nothing,es:nothing

	 push	 bp		; Save on stack

	 lea	 bp,WGET_A_FAST ; Address of local fast processing routine
	 push	 bp		; Put on stack

	 lea	 bp,WGET_A_SLOW ; Address of local slow processing routine
	 push	 bp		; Put on stack

	 push	 VRCNT_A	; Use this count value for vertical retrace

	 call	 WGET_COM	; Call common code

	 add	 sp,6		; Pop off [bp].VRCNT
				;	  [bp].SLOWFN
				;	  [bp].FASTFN
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WGET_A	 endp			; End WGET_A procedure
	 NPROC	 WGET_A_FAST	;-- WGET_A Fast Processing Routine
	 assume  ds:nothing,es:nothing

WGET_A_FAST1:
	 inc	 si		; Skip over text byte
	 movsb			; Move the next byte from the screen

	 loop	 WGET_A_FAST1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WGET_A_FAST endp		; End WGET_A_FAST procedure
	 NPROC	 WGET_A_SLOW	;-- WGET_A Slow Processing Routine
	 assume  ds:nothing,es:nothing

WGET_A_SLOW1:
	 inc	 si		; Skip over text byte

	 $WAIT_ACT		; Wait until the display is active
	 $WAIT_INACT		; Wait until the display is inactive

	 movsb			; Move the next byte from the screen

	 loop	 WGET_A_SLOW1	; Jump if more bytes in this row

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WGET_A_SLOW endp		; End WGET_A_SLOW procedure
	 PPROC	 wget_ca	;-- Get Characters & Attributes
	 assume  ds:nothing,es:nothing

WGET_CA_FAST equ WPUT_CA_FAST
WGET_CA_SLOW equ WPUT_CA_SLOW

	 push	 bp		; Save on stack

	 lea	 bp,WGET_CA_FAST ; Address of local fast processing routine
	 push	 bp		; Put on stack

	 lea	 bp,WGET_CA_SLOW ; Address of local slow processing routine
	 push	 bp		; Put on stack

	 push	 VRCNT_C	; Use this count value for vertical retrace

	 call	 WGET_COM	; Call common code

	 add	 sp,6		; Pop off [bp].VRCNT
				;	  [bp].SLOWFN
				;	  [bp].FASTFN
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

WGET_CA  endp			; End WGET_CA procedure
	 NPROC	 WGET_COM	;-- Common WGET Processing Routine
	 assume  ds:nothing,es:nothing

	 $GETPUTMAC GET,es,di,ds,si ; Use common macro

WGET_COM endp			; End WGET_COM procedure
	 NPPROC  VERT_WAIT	;-- Wait For Vertical Retrace
	 assume  ds:nothing,es:nothing
COMMENT|

The following diagram is a time chart of the screen display (not drawn to scale)

   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄ¿
   ³		 ³ ³	Within Region A, the display is active.
   ³		 ³ ³
   ³	  A	 ³H³	Within Region H, the display is inactive, in
   ³		 ³ ³	   horizontal retrace.
   ³		 ³ ³
   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄ´	Within Region U, the display is inactive, in
   ³	  U	   ³	   the area below the active area, but not in
   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´	   vertical retrace.
   ³		   ³
   ³	  V	   ³	Within Region V, the display is inactive, in
   ³		   ³	   vertical retrace.
   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

The object of this routine is to release control at the beginning
of the longest period of inactive display, that is, Region U.

The following code accomplishes that by waiting until the display
switches from active to inactive and remains inactive for REGH_SIZ
iterations.  With an appropriately chosen value for REGH_CNT, we can
ensure that we recognize and skip over all instances of Region H.

On entry:

IF	 =	 0 (interrupts disabled)

|

	 REGSAVE <ax,cx,dx>	; Save registers

	 mov	 dx,@COLR_STAT	; Port address of 6845 status register
VERT_WAIT1:
	 $WAIT_ACT		; Wait until the display is active

; At this point, the display is in Region A (active)

	 $WAIT_INACT		; Wait until the display is inactive

; At this point, the display is in Region H or U (inactive)

	 mov	 cx,REGH_SIZ	; Size of Region H in units of # iterations
VERT_WAIT2:
	 in	 al,dx		; Get 6845 video status

	 test	 al,@DISP_INACT ; Display inactive?
	 loopnz  VERT_WAIT2	; Yes, continue for CX times
	 jnz	 VERT_WAIT3	; It's still inactive

;;;;;;;; sti			; Allow interrupts again for a moment
;;;;;;;; cli			; That's long enough
	 jmp	 VERT_WAIT1	; Try again to find region U
VERT_WAIT3:

; At this point, the display is in Region U (inactive)

	 REGREST <dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

VERT_WAIT endp			; End VERT_WAIT procedure
	 PPROC	 set_mode	;-- Set Internal Video Mode
	 assume  ds:nothing,es:nothing

	 push	 bp		; Save to address the stack
	 mov	 bp,sp		; Prepare to address arguments on stack

	 REGSAVE <ax,bx>	; Save registers

	 mov	 al,[bp].MODE_BYTE ; Get screen update flag
	 mov	 GRF_MODE,al	; Save for use later

	 VIDCALL @GETINF	; Get current video state
				; AL = current video mode
				; AH = # screen columns
				; BH = active display page
	 mov	 NSCR_COLS,ah	; Save for others to use
	 mov	 DISP_PAGE,bh
	 and	 al,not 80h	; Isolate mode bits
	 mov	 CRT_MODE,al

	 cmp	 al,7		; Check for monochrome screen
	 je	 SET_MODE_MONO	; It's mono

	 mov	 ah,al		; Save for a moment

	 cmp	 al,MODE_TABLE_LEN ; Compare against maximum mode known
	 jb	 SET_MODE_XLAT	; It's within range

	 mov	 al,3		; Assume it's a color graphics mode
	 jmp	 short SET_MODE_RESET ; Join common code
SET_MODE_XLAT:
	 lea	 bx,MODE_TABLE
	 xlat	 MODE_TABLE	; Translate the mode byte in AL

	 cmp	 ah,al		; See if same before and after
	 je	 SET_MODE_COLR	; They are
SET_MODE_RESET:
	 VIDCALL @SETMOD	; Set mode (to that in AL)
				; Fall through to color/graphics code
SET_MODE_COLR:
	 mov	 SCR_SEG,COLR_SEG ; It's the color screen
	 mov	 al,GRF_MODE	; Get graphics screen update flag
	 mov	 UPD_MODE,al	; Save for use later

	 mov	 al,00h 	; Page #
	 VIDCALL @SETPAG	; Set active page

	 jmp	 short SET_MODE_COM ; Join common ending code
SET_MODE_MONO:
	 mov	 SCR_SEG,MONO_SEG ; Send text to monochrome screen buffers
	 mov	 UPD_MODE,FAST_MODE ; Save flag
SET_MODE_COM:
	 REGREST <bx,ax>	; Restore

	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

set_mode endp			; End SET_MODE procedure
	 PPROC	 reset_mode	;-- Reset Internal Video Mode
	 assume  ds:nothing,es:nothing

	 REGSAVE <ax,bx>	; Save registers

	 VIDCALL @GETINF	; Get current video state
				; AL = current video mode
				; AH = # screen columns
				; BH = active display page
	 mov	 NSCR_COLS,ah	; Save for others to use
	 mov	 DISP_PAGE,bh
	 and	 al,not 80h	; Isolate mode bits
	 mov	 CRT_MODE,al

	 cmp	 al,7		; Check for monochrome screen
	 je	 RESET_MODE_MONO ; It's mono

	 mov	 SCR_SEG,COLR_SEG ; It's the color screen
	 mov	 al,GRF_MODE	; Get graphics screen update flag
	 mov	 UPD_MODE,al	; Save for use later
	 jmp	 short RESET_MODE_COM ; Join common ending code
RESET_MODE_MONO:
	 mov	 SCR_SEG,MONO_SEG ; Send text to monochrome screen buffers
	 mov	 UPD_MODE,FAST_MODE ; Save flag
RESET_MODE_COM:
	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

reset_mode endp 		; End RESET_MODE procedure
	 PPROC	 izitega	;-- Check For Presence of EGA
	 assume  ds:nothing,es:nothing
COMMENT|

Return AX = -1 if EGA not present, otherwise
       AL =  0 if present and in color mode
	     1		      in mono mode
	     2		      in enhanced color mode
       AH = memory settings (0 = 64k, 1 = 128k, 2 = 192k, 3 = 256k)
|

	 REGSAVE <bx,cx>	; Save registers

	 mov	 bl,10h 	; Function code to return EGA information
	 mov	 bh,0FFh	; Set to value out of range
	 mov	 cl,0Fh 	; Ditto

	 VIDCALL @GETEGA	; Get EGA information
				; If EGA present, return with
				; BH = 0 if color mode, 1 if mono
				; BL = 0 (64k), 1 (128k), 2 (192k), 3 (256k)
				; CH = feature bits
				; CL = switch setting

	 mov	 ax,-1		; Assume not present

	 cmp	 bh,01h 	; Check against maximum allowed value
	 ja	 IZITEGA_EXIT	; Invalid, no EGA

	 cmp	 bl,03h 	; Check against maximum allowed value
	 ja	 IZITEGA_EXIT	; Invalid, no EGA

	 cmp	 cl,0Bh 	; Check against maximum allowed value
	 ja	 IZITEGA_EXIT	; Invalid, no EGA

	 mov	 al,bh		; Copy mode to AL
	 mov	 ah,bl		; ...and memory size to AH

	 cmp	 cl,9		; Check switch setting for enhanced color mode
	 jne	 IZITEGA_EXIT	; Not this time

	 mov	 al,2		; It's in enhanced color mode
IZITEGA_EXIT:
	 REGREST <cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

izitega  endp			; End IZITEGA procedure
	 PPROC	 izitpgc	;-- Check On Presence of PGC
	 assume  ds:nothing,es:nothing
COMMENT|

A PGC can be used in one of two ways:  directly, or emulating a CGA

Return AX = -1 if PGC not present
	  =  0 if present

|

	 REGSAVE <dx,di,es>	; Save registers

; Check on direct mode first

	 les	 di,PGC_DIR	; ES:DI ==> PGC direct mode test byte
	 mov	 al,@DIR_TEST	; Test value
	 xchg	 al,es:[di]	; Swap with original value
	 xchg	 al,es:[di]	; Swap back with original value

	 cmp	 al,@DIR_TEST	; Compare with test value
	 je	 IZITPGC_YES	; PGC is present

; Check on CGA emulation mode next

	 les	 di,PGC_EMU	; ES:DI ==> PGC emulation mode test byte
	 mov	 ah,@EMU_TEST	; Test value
	 xchg	 ah,es:[di]	; Swap with original value and latch location

	 mov	 dx,@COLR_ADDR	; CRTC controller value
	 in	 al,dx		; Get current contents
	 mov	 es:[di],ah	; Restore original value

	 cmp	 al,@EMU_TEST	; Compare with test value
	 je	 IZITPGC_YES	; PGC is present

	 mov	 ax,-1		; Mark as not present
	 jmp	 short IZITPGC_EXIT ; PGC is not present
IZITPGC_YES:
	 xor	 ax,ax		; Mark as present
IZITPGC_EXIT:
	 REGREST <es,di,dx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

izitpgc  endp			; End IZITPGC procedure
	 PPROC	 izit3270	;-- Check On Presence of 3270
	 assume  ds:nothing,es:nothing
COMMENT|

Return AX = -1 if 3270 not present
	  =  0 if present

|

	 REGSAVE <cx,dx,si,ds>	; Save registers

	 mov	 ax,3000h	; Function code for INT 10h call
	 xor	 cx,cx		; Zero both CX & DX
	 xor	 dx,dx
	 int	 10h		; Request video service

; If CX & DX are both zero, it's not a 3270

	 mov	 ds,cx		; DS:SI ==> 3270 id byte???
	 assume  ds:nothing
	 mov	 si,dx

	 mov	 ax,-1		; Assume that it's not a 3270

	 or	 dx,cx		; Check for both zero
	 jz	 IZIT3270_EXIT	; It's not a 3270

	 cmp	 byte ptr [si],-1 ; Check for 0FFh
	 je	 IZIT3270_EXIT	; It's not a 3270

	 inc	 ax		; Indicate that it's a 3270
IZIT3270_EXIT:
	 REGREST <ds,si,dx,cx>	; Restore
	 assume  ds:nothing

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

IZIT3270 endp			; End IZIT3270 procedure

;;;;	 ENDPS

	 MEND			; End WINDOWFN module

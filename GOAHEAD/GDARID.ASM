;' $Header:   P:/PVCS/MAX/GOAHEAD/GDARID.ASV   1.3   06 Feb 1996 10:52:38   BOB  $
	title	GDARID -- GDA Read Incompat Driver Functions
	page	58,122
	name	GDARID
.386p
.xlist
	include MASM.INC
	include WINDOWS.INC
	include ASCII.INC
	include 386.INC
	include PTR.INC
	include DOSCALL.INC
	include OPEN.INC

	include GDADRV.INC
	include MISCFNS.INC
.list
	extrn	GetWindowRect:far
	extrn	MoveWindow:far
	extrn	GetDesktopWindow:far
	extrn	GetWindowsDirectory:far
	extrn	GlobalAlloc:far
	extrn	GlobalFree:far
	extrn	GetProfileInt:far
	extrn	GetPrivateProfileInt:far
	extrn	GetPrivateProfileString:far
	extrn	WritePrivateProfileString:far
	extrn	DialogBoxParam:far
	extrn	EndDialog:far
	extrn	SetDlgItemText:far
	extrn	CheckRadioButton:far
	extrn	MakeProcInstance:far
	extrn	FreeProcInstance:far
	extrn	Loadstring:far

DGROUP	group	_DATA

_DATA	segment use16 dword public 'DATA' ; Start _DATA segment
	assume	ds:DGROUP

	extrn	LCL_FLAG:word

	extrn	lpDefValue:dword
	extrn	lpQMAXINIFile:dword

	public	dwGlbHeap,lpGlbHeap,nINIFile
dwGlbHeap dd	32*1024 	; Size of global heap allocation
lpGlbHeap dd	0		; Pointer to global heap
nINIFile dw	?		; # bytes read from INI file

	public	hInstance,hWnd,nRadioButton
hInstance dw	seg DGROUP	; Instance handle
hWnd	dw	0		; Pseudo-window handle
nRadioButton dw ?		; ID for checked radio button

	public	lpProg,szProg
lpProg	dd	DGROUP:szProg	; Ptr to Program name
szProg	db	'Go Ahead',0    ; Program name

	public	lpIDSect,szIDSect
	align	4
lpIDSect dd	DGROUP:szIDSect ; Ptr to Section name
szIDSect db	'Go Ahead - Incompatible Drivers',0 ; Section name

	public	lpIDCntName,szIDCntName
	align	4
lpIDCntName dd	DGROUP:szIDCntName ; Ptr to line name
szIDCntName db	'Count',0       ; Line name of "Count=" line

	public	lpIDDrvName,szIDDrvName
	align	4
lpIDDrvName dd	DGROUP:szIDDrvName ; Ptr to line name
szIDDrvName db	'Driver'        ; Line name of "DriverNNN=" line
szIDDrvName1 db 'NNN',0         ; ...

	public	lpIDDrvBuf,szIDDrvBuf
	align	4
lpIDDrvBuf dd	DGROUP:szIDDrvBuf ; Ptr to buffer
szIDDrvBuf db	128 dup (?)	; Buffer for "DriverNNN=" strings

lpStartupGrp equ lpIDDrvBuf	; Ptr to buffer
nStartupGrp equ size szIDDrvbuf ; Size of ...

	public	lpIDININame,szIDININame
	align	4
lpIDININame dd	DGROUP:szIDININame ; Ptr to ID INI filename
szIDININame db	80 dup (?)	; Buffer for ID INI filename

	public	lpIDSectName,szIDSectName,nIDSectName
	align	4
lpIDSectName dd DGROUP:szIDSectName ; Ptr to ID section name
szIDSectName db 80 dup (?)	; Buffer for ID section name
nIDSectName dw	?		; Length of ...

	public	lpIDEntryName,szIDEntryName,nIDEntryName
	align	4
lpIDEntryName dd DGROUP:szIDEntryName ; Ptr to ID entry name
szIDEntryName db 128 dup (?)	; Buffer for ID entry name
nIDEntryName dw ?		; Length of ...

	public	lpIDStrName,szIDStrName,nIDStrName
	align	4
lpIDStrName dd	DGROUP:szIDStrName ; Ptr to ID string name
szIDStrName db	128 dup (?)	; Buffer for ID string name
nIDStrName dw	?		; Length of ...

	public	lpIDTextName,szIDTextName
	align	4
lpIDTextName dd DGROUP:szIDTextName ; Ptr to ID text name
szIDTextName db 80 dup (?)	; Buffer for ID text name

	public	lpIDIgnName,szIDIgnName
	align	4
lpIDIgnName dd	DGROUP:szIDIgnName ; Ptr to line name
szIDIgnName db	'Ignore',0      ; Line name of "Ignore=" line

	public	lpIDIgnStr,szIDIgnStr
	align	4
lpIDIgnStr  dd	DGROUP:szIDIgnStr ; Ptr to string
szIDIgnStr  db	'1',0           ; String

	public	lpfnLCDlgProc
	align	4
lpfnLCDlgProc dd ?		; Ptr to dialog proc

	public	lpDlg
	align	4
lpDlg	dd	DGROUP:szGADlg	; Ptr to string:  0 = Go Ahead
	dd	DGROUP:szMSDlg	; ...		  1 = MAX Setup
	dd	DGROUP:szTBDlg	; ...		  2 = Toolbox

@MAXDLG equ	2		; Maximum dialog #

; Note that MAX Setup and Toolbox share the same dialog

	public	szGADlg,szMSDlg,szTBDlg
szGADlg db	'GADLG',0       ; Template name for Go Ahead  dialog box
szMSDlg db	'TBDLG',0       ; ...               MAX Setup ...
szTBDlg db	'TBDLG',0       ; ...               Toolbox   ...


IDC_STR struc

IDC_1ST dw	?		; First radio button
IDC_LAST dw	?		; Last	...
IDC_CHK dw	?		; Checked ...

IDC_STR ends

; The following variable is used for IDC limits

	public	wIDCLim
	align	4
wIDCLim IDC_STR <IDC_REMOVE,IDC_NOWARN,IDC_NOWARN> ; Go Ahead
	IDC_STR <IDC_NOLOAD,IDC_NOWARN,IDC_NOLOAD> ; MAX Setup
	IDC_STR <IDC_NOLOAD,IDC_NOWARN,IDC_NOLOAD> ; Toolbox

	public	lpIntlSect,szIntlSect
	align	4
lpIntlSect dd	DGROUP:szIntlSect ; Ptr to section name
szIntlSect db	'intl',0        ; Section name

	public	lpCountryName,szCountryName
	align	4
lpCountryName dd DGROUP:szCountryName ; Ptr to line name
szCountryName db 'iCountry',0   ; Line name

_DATA	ends			; End _DATA segment

;..............................................................
_TEXT	segment use16 byte public 'CODE' ; Start _TEXT segment
	assume	cs:_TEXT

	extrn	StrNICmp:near
	extrn	StrChr:near
	extrn	StrLen:near
	extrn	SkipWhite:near
	extrn	DD2DEC:near
	extrn	UpdateDrivers:near

	extrn	_InitDDE:near
	extrn	_pmShowGroup:near
	extrn	_pmDeleteItem:near
	extrn	_EndDDE:near

	NPPROC	CenterWindow -- Center The Window On The Desktop
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Center the window on the desktop

On exit:

The usual registers that W clobbers are clobbered.

|

CW_STR	struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
CW_HWND dw	?		; hWnd

CW_STR	ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

CW_LSTR struc

CW_LRECT dw	4 dup (?)	; Rectangle

CW_LSTR ends

	sub	sp,type CW_LSTR ; Make room for local structure

CWL	equ	<[bp-(type CW_LSTR)]>

; Get the handle of the desktop

	call	GetDesktopWindow ; Return AX = hWnd of desktop
	assume	es:nothing	; Tell the assembler about it

; Get the rectangle which surrounds the desktop

	push	ax		; Pass hWnd of desktop
	push	ss		; ...  segment of rect
	lea	ax,CWL.CW_LRECT ; Get offset of rect
	push	ax		; Pass ...
	call	GetWindowRect	; Fill in rectangle for window
	assume	es:nothing	; Tell the assembler about it

; The center of the desktop is
;  xPosCtr = rcWnd.left + (rcWnd.right	- rcWnd.left)/2
;  yPosCtr = rcWnd.top	+ (rcWnd.bottom - rcWnd.top )/2

	push	[bp].CW_HWND	; Pass hWnd of window to move

	mov	ax,CWL.CW_LRECT.rcright ; Get rcWnd.right
	sub	ax,CWL.CW_LRECT.rcleft ; Less rcWnd.left
	shr	ax,1		; /2
	add	ax,CWL.CW_LRECT.rcleft ; Plus rcWnd.left
	push	ax		; Pass xPosCtr

	mov	ax,CWL.CW_LRECT.rcbottom ; Get rcWnd.bottom
	sub	ax,CWL.CW_LRECT.rctop ; Less rcWnd.top
	shr	ax,1		; /2
	add	ax,CWL.CW_LRECT.rctop ; Plus rcWnd.top
	push	ax		; Pass yPosCtr

	call	MoveWindowPos	; Move a window to a centered position
	assume	es:nothing	; Tell the assembler about it

	mov	sp,bp		; Strip local struc
	pop	bp		; Restore

	ret	2		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CenterWindow endp		; End CenterWindow procedure
	NPPROC	MoveWindowPos -- Move Window To Centered Position
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Move a window to a centered position

On exit:

The usual registers that W clobbers are clobbered.

|

MWP_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
MWP_YCTR dw	?		; yPosCtr
MWP_XCTR dw	?		; xPosCtr
MWP_HWND dw	?		; hWnd

MWP_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

MWP_LSTR struc

MWP_LRECT dw	4 dup (?)	; Rectangle

MWP_LSTR ends

	sub	sp,type MWP_LSTR ; Make room for local structure

MWPL	equ	<[bp-(type MWP_LSTR)]>


; Get the rectangle which surrounds the window to move

	push	[bp].MWP_HWND	; Pass hWnd of window to move
	push	ss		; ...  segment of rect
	lea	ax,MWPL.MWP_LRECT ; Get offset of rect
	push	ax		; Pass ...
	call	GetWindowRect	; Fill in rectangle for window
	assume	es:nothing	; Tell the assembler about it

; Calculate the width and height of the window

	mov	cx,MWPL.MWP_LRECT.rcright ; Get rcWnd.right
	sub	cx,MWPL.MWP_LRECT.rcleft ; Less rcWnd.left

	mov	dx,MWPL.MWP_LRECT.rcbottom ; Get rcWnd.bottom
	sub	dx,MWPL.MWP_LRECT.rctop ; Less rcWnd.top

	push	[bp].MWP_HWND	; Pass hWnd of window to move

	mov	ax,[bp].MWP_XCTR ; Get xPosCtr
	mov	bx,cx		; Copy width
	shr	bx,1		; /2
	sub	ax,bx		; Less half the width
	push	ax		; Pass x-coord of upper left corner

	mov	ax,[bp].MWP_YCTR ; Get yPosCtr
	mov	bx,dx		; Copy height
	shr	bx,1		; /2
	sub	ax,bx		; Less half the height
	push	ax		; Pass y-coord of upper left corner

	push	cx		; ...  width
	push	dx		; ...  height

	push	FALSE		; ...  repaint flag

	call	MoveWindow	; Move window to position
	assume	es:nothing	; Tell the assembler about it

	mov	sp,bp		; Strip local struc
	pop	bp		; Restore

	ret	2+2+2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MoveWindowPos endp		; End MoveWindowPos procedure
	FPPROC	LCDlgProc -- Load Clearance Dialog Procedure
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Dialog procedure for Load Clearance

On entry:

SS:SP	==>	LC_STR (after PUSH BP)

On exit:

AX	=	return code (TRUE or FALSE)
		For WM_INITDIALOG, return TRUE if Windows should set
		  the window focus itself, or FALSE if the WM_INITDIALOG
		  code has called SetFocus.
		For all other messages, return TRUE if this message has
		  been handled, FALSE if Windows should continue its
		  processing.
		Do NOT call DefWindowProc.

|

LC_STR	struc

	dw	?		; 00:  Caller's BP
	dd	?		; 02:  ...	CS:IP
LC_lParam dd	?		; 06:  lParam
LC_wParam dw	?		; 0A:  wParam
LC_message dw	?		; 0C:  message-type
LC_hWnd dw	?		; 0E:  hWnd

LC_STR	ends

	push	ds		; This is some standard preliminary
	pop	ax		; shuffling of the registers.
	nop			;	 /
	inc	bp		;	 / (it is called the prolog code)
	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
	push	ds		;	 /

	mov	ax,seg DGROUP	; Get DGROUP data selector
	mov	ds,ax		;	 /
	assume	ds:DGROUP	;	 / (enters function with DS=_DATA)

	mov	ax,[bp].LC_message ; Get message-type.

	cmp	ax,WM_INITDIALOG ; Izit initialization time?
	je	short LC_INITDIALOG ; Jump if so

	cmp	ax,WM_COMMAND	; Izit command time?
	je	short LC_COMMAND ; Jump if so
LC_FALSE:
	mov	ax,FALSE	; Tell W we did not process this message

	jmp	LC_EXIT 	; Join common exit code
;.................................
LC_INITDIALOG:
	push	[bp].LC_hWnd	; Pass hWnd
	call	CenterWindow	; Center the window on the screen

; Display incompatible driver text

	push	[bp].LC_hWnd	; Pass hWnd
	push	IDC_DRVNAME	; ...  ID for field
	push	lpIDTextName	; ...  ptr to driver text
	call	SetDlgItemText	; Display the text

; Check the appropriate radio button

	imul	bx,[bp].LC_lParam.ELO,type IDC_STR ; Get index into wIDCLim
	mov	ax,wIDCLim[bx].IDC_CHK ; Get the checked ID
	mov	nRadioButton,ax ; Save as default state in case OK

	push	[bp].LC_hWnd	; Pass hWnd
	push	wIDCLim[bx].IDC_1ST  ; ... identifier of 1st button
	push	wIDCLim[bx].IDC_LAST ; ...		 last ...
	push	wIDCLim[bx].IDC_CHK  ; ...		 checked ...
	call	CheckRadioButton ; Check one and only one

	jmp	LC_TRUE 	; Tell 'em to call SetFocus themselves
				; for WM_INITDIALOG only
;.................................
LC_COMMAND:
	mov	ax,[bp].LC_wParam ; Get wParam

	cmp	ax,IDC_NOLOAD	; Izit below radio button range?
	jb	short @F	; Jump if so

	cmp	ax,IDC_NOWARN	; Izit above radio button range?
	ja	short @F	; Jump if so

	mov	nRadioButton,ax ; Save for later use

	jmp	LC_TRUE 	; Tell W we handled this message

@@:
	cmp	ax,IDOK 	; Izit the OK button?
	jne	short LC_FALSE	; Jump if not

	mov	ax,nRadioButton ; Get ID of checked radio button

	cmp	ax,IDC_NOLOAD	; Izit "Don't load"?
	je	near ptr END_DIALOG_FALSE ; Jump if so

	cmp	ax,IDC_REMOVE	; Izit "Uninstall"?
	je	short END_DIALOG_REMOVE ; Jump if so

	cmp	ax,IDC_NOWARN	; Izit "Load and forget"?
	jne	near ptr END_DIALOG_FALSE ; Jump if not

; Write out profile string "Ignore=1"

	push	lpIDSect	; Pass ptr to section name
	push	lpIDIgnName	; ...	      line name
	push	lpIDIgnStr	; ...	      string name
	push	lpQMAXINIFile	; ...  ptr to .INI filename
	call	WritePrivateProfileString ; Return AX = non-zero iff it worked

	jmp	short END_DIALOG_TRUE ; Join common load code


; Remove the driver from SYSTEM.INI, etc.

END_DIALOG_REMOVE:
	push	FALSE		; Pass argument to delete to "drivers=" line
	call	UpdateDrivers	; Change "drivers=" line in SYSTEM.INI [boot]
				; non-BP GP registers destroyed
	assume	es:nothing	; Tell the assembler about it
;;;;;;; jc	short ???	; Jump if not previously installed

COMMENT|

Remove from startup group

// Windows bug - we have to minimize the window first, then
//   show it, or it won't be activated!
pmShowGroup( "StartUp", 2 );
pmShowGroup( "StartUp", 1 );
pmDeleteItem( "Go Ahead" );
pmShowGroup( "StartUp", 2 );

|

COMMENT|

Get the string for the startup group

    // special case German startup group.
    nCountry = GetProfileInt( (LPSTR)"intl", (LPSTR)"iCountry", nCountry );
    if( nCountry == 49 ) {
	_fstrcpy( szStartupGroup, szDEStartupGroup );
    } else {
	_fstrcpy( szStartupGroup, szUSStartupGroup );
    }

|

	push	lpIntlSect	; Pass ptr to section name
	push	lpCountryName	; ...	      line name
	push	1		; ...	      default value (US)
	call	GetProfileInt	; Return value in AX

	cmp	ax,49		; Izit German?
	mov	ax,IDS_DE_STARTUPGRP ; Assume so
	je	short @F	; Jump if so

	mov	ax,IDS_US_STARTUPGRP ; Assume not
@@:
	push	hInstance	; Pass hInstance
	push	ax		; ...  resource ID
	push	lpStartupGrp	; ...  ptr to buffer
	push	nStartupGrp	; ...  size of ...
	call	LoadString	; Load it up

; To do this, we need to setup a DDE connection with PROGMAN

	call	_InitDDE	; Initialize the DDE system
	assume	es:nothing	; Tell the assembler about it

; Note that these functions use the C calling convention
; for argument ordering and stripping

	push	2		; Pass activate and minimize parm
	push	lpStartupGrp	; ...  ptr to startup group name
	call	_pmShowGroup	; Show the group
	assume	es:nothing	; Tell the assembler about it
	add	sp,2+4		; Strip from the stack

	push	1		; Pass activate and display parm
	push	lpStartupGrp	; ...  ptr to startup group name
	call	_pmShowGroup	; Show the group
	assume	es:nothing	; Tell the assembler about it
	add	sp,2+4		; Strip from the stack

	push	lpProg		; Pass ptr to item to delete
	call	_pmDeleteItem	; Delete the item
	add	sp,4		; Strip from the stack

	push	2		; Pass activate and minimize parm
	push	lpStartupGrp	; ...  ptr to startup group name
	call	_pmShowGroup	; Show the group
	assume	es:nothing	; Tell the assembler about it
	add	sp,2+4		; Strip from the stack

	call	_EndDDE 	; That's all folks
	assume	es:nothing	; Tell the assembler about it
END_DIALOG_FALSE:
	mov	ax,FALSE	; We're not to load

	jmp	short END_DIALOG_COM ; Join common code

END_DIALOG_TRUE:
	mov	ax,TRUE 	; We're to load
END_DIALOG_COM:
	push	[bp].LC_hWnd	; Pass hWnd
	push	ax		; ...  return value to DialogBoxParam caller
	call	EndDialog	; Remove the dialog box

	jmp	short LC_TRUE	; Join common true code
;.................................
LC_TRUE:
	mov	ax,TRUE 	; Tell Windows we processed this message
LC_EXIT:
	dec	bp		; Final standard manipulation of regs.
	dec	bp		;	 /
	mov	sp,bp		;	 / (it is called the epilog code).
	pop	ds		;	 /
	pop	bp		;	 /
	dec	bp		;	 /

	ret	10		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCDlgProc endp			; End LCDlgProc procedure
	FPPROC	GADialog -- Display Load Clearance Dialog Box
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display Load Clearance dialog box

Note that this routine uses the C calling convention.

On exit:

AX	=	TRUE if we're to load
	=	FALSE if not
All other non-BP register may be clobbered.

|

GAD_STR struc

	dw	?		; Caller's BP
	dd	?		; ...	   CS:IP
GAD_HWND dw	?		; hWnd of owner window
GAD_FLAG dw	?		; Flag:  0 = called from Go Ahead
				;	 1 = called from Setup
				;	 2 = called from Toolbox
GAD_STR ends

	push	ds		; This is some standard preliminary
	pop	ax		; shuffling of the registers.
	nop			;	 /
	inc	bp		;	 / (it is called the prolog code)
	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
	push	ds		;	 /

	mov	ax,seg DGROUP	; Get DGROUP data selector
	mov	ds,ax		;	 /
	assume	ds:DGROUP	;	 / (enters function with DS=_DATA)

	lea	ax,LCDlgProc	; Get offset of procedure
	push	cs		; Pass segment of ...
	push	ax		; ...  offset ...
	push	hInstance	; ...  hInstance
	call	MakeProcInstance ; Return DX:AX ==> thunk
	assume	es:nothing	; Tell the assembler about it

	mov	lpfnLCDlgProc.VOFF,ax ; Save for later use
	mov	lpfnLCDlgProc.VSEG,dx ; ...

	movzx	ebx,[bp].GAD_FLAG ; Get the caller's flag

	cmp	bx,@MAXDLG	; Izit too big?
	jbe	short @F	; Jump if not

	mov	bx,@MAXDLG	; Use maximum
@@:
	push	hInstance	; Pass instance handle
	push	lpDlg[ebx*(type lpDlg)] ; ...  ptr to dialog box template name
	push	[bp].GAD_HWND	; ...  handle of owner window
	push	lpfnLCDlgProc	; ... Seg:Off of function
	push	ebx		; Pass the param
	call	DialogBoxParam	; Put up the dialog box
	assume	es:nothing	; Tell the assembler about it
				; Return AX = TRUE if we're to load, FALSE otherwise
	push	ax		; Save result

	push	lpfnLCDlgProc	; ... Seg:Off of function
	call	FreeProcInstance ; Release the thunk
	assume	es:nothing	; Tell the assembler about it

	pop	ax		; Restore

	dec	bp		; Final standard manipulation of regs.
	dec	bp		;	 /
	mov	sp,bp		;	 / (it is called the epilog code).
	pop	ds		;	 /
	pop	bp		;	 /
	dec	bp		;	 /

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GADialog endp			; End GADialog procedure
	FPPROC	GALoadClear -- DLL Entry Point for Load Clearance
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DLL entry point for Load Clearance

On exit:

AX	=	TRUE if we're to load
	=	FALSE if not
All other non-BP register may be clobbered.

|

	push	ds		; This is some standard preliminary
	pop	ax		; shuffling of the registers.
	nop			;	 /
	inc	bp		;	 / (it is called the prolog code)
	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
	push	ds		;	 /

	mov	ax,seg DGROUP	; Get DGROUP data selector
	mov	ds,ax		;	 /
	assume	ds:DGROUP	;	 / (enters function with DS=_DATA)

; Read in profile section of Incompatible Drivers

	call	ReadIncompat	; Read it in
	mov	ax,TRUE 	; Assume we can load safely
	jnc	short @F	; Jump if no match

	mov	ax,FALSE	; Tell 'em not to load
@@:
	dec	bp		; Final standard manipulation of regs.
	dec	bp		;	 /
	mov	sp,bp		;	 / (it is called the epilog code).
	pop	ds		;	 /
	pop	bp		;	 /
	dec	bp		;	 /

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GALoadClear endp		; End GALoadClear procedure
	NPPROC	ParseIDLine -- Parse ID Line
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Parse an ID line of the form

filename,sectname,entryname,itemname,text

On exit:

CF	=	0 if successful
	=	1 if not

|

PIDL_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
PIDL_BUF dd	?		; Ptr to buffer

PIDL_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	push	ds		; Save register
	pusha			; Save registers

; Copy the W directory

	push	es		; Save for a moment

	push	lpIDININame	; Pass ptr to buffer
	push	size szIDININame ; ... size of buffer
	call	GetWindowsDirectory ; Return AX = # chars copied
	assume	es:nothing	; Tell the assembler about it

	pop	es		; Restore
	assume	es:DGROUP	; Tell the assembler about it

; Ensure the path ends with a backslash

	lea	di,szIDININame	; ES:DI ==> destin buffer
	add	di,ax		; Plus # chars copied
	mov	al,'\'          ; Get path separator

	cmp	al,es:[di-1]	; Izit already present?
	je	short @F	; Jump if so

	stos	es:[di].LO	; Ensure properly terminated
@@:
	lds	si,[bp].PIDL_BUF ; DS:SI == > buffer
	assume	ds:nothing	; Tell the assembler about it

; Search for the next field

	push	lpIDDrvBuf.VSEG ; Pass buffer segment
	push	si		; ...	      offset
	push	','             ; ...  character to search for
	call	StrChr		; Return with DX:AX = next occurrence (0=none)

	or	dx,ax		; Did it fail?
	stc			; Assume so
	jz	near ptr ParseIDLineExit ; Jump if so (ignore it) (note CF=1)

	mov	cx,ax		; Copy to count register
	sub	cx,si		; Subtract to get length

; Append the text to szIDININame

    rep movs	szIDININame[di],ds:[si].LO ; Copy to buffer
	mov	al,0		; Get ASCIIZ terminator
	stos	es:[di].LO	; Ensure properly terminated

	inc	si		; Skip over separator

; Search for the next field

	push	lpIDDrvBuf.VSEG ; Pass buffer segment
	push	si		; ...	      offset
	push	','             ; ...  character to search for
	call	StrChr		; Return with DX:AX = next occurrence (0=none)

	or	dx,ax		; Did it fail?
	stc			; Assume so
	jz	short ParseIDLineExit ; Jump if so (ignore the entry) (note CF=1)

	mov	cx,ax		; Copy to count register
	sub	cx,si		; Subtract to get length
	mov	nIDSectName,cx	; Save for later use

; Copy the text to szIDSectName

	lea	di,szIDSectName ; ES:DI ==> destin buffer
    rep movs	szIDSectName[di],ds:[si].LO ; Copy to buffer
	mov	al,0		; Get ASCIIZ terminator
	stos	es:[di].LO	; Ensure properly terminated

	inc	si		; Skip over separator

; Search for the next field

	push	lpIDDrvBuf.VSEG ; Pass buffer segment
	push	si		; ...	      offset
	push	','             ; ...  character to search for
	call	StrChr		; Return with DX:AX = next occurrence (0=none)

	or	dx,ax		; Did it fail?
	stc			; Assume so
	jz	short ParseIDLineExit ; Jump if so (ignore the entry) (note CF=1)

	mov	cx,ax		; Copy to count register
	sub	cx,si		; Subtract to get length
	mov	nIDEntryName,cx ; Save for later use

; Copy the text to szIDEntryName

	lea	di,szIDEntryName ; ES:DI ==> destin buffer
    rep movs	szIDEntryName[di],ds:[si].LO ; Copy to buffer
	mov	al,0		; Get ASCIIZ terminator
	stos	es:[di].LO	; Save in buffer

	inc	si		; Skip over separator

; Search for the next field

	push	lpIDDrvBuf.VSEG ; Pass buffer segment
	push	si		; ...	      offset
	push	','             ; ...  character to search for
	call	StrChr		; Return with DX:AX = next occurrence (0=none)

	or	dx,ax		; Did it fail?
	stc			; Assume so
	jz	short ParseIDLineExit ; Jump if so (ignore the entry) (note CF=1)

	mov	cx,ax		; Copy to count register
	sub	cx,si		; Subtract to get length
	mov	nIDStrName,cx	; Save for later use

; Copy the text to szIDStrName

	lea	di,szIDStrName	; ES:DI ==> destin buffer
    rep movs	szIDStrName[di],ds:[si].LO ; Copy to buffer
	mov	al,0		; Get ASCIIZ terminator
	stos	es:[di].LO	; Ensure properly terminated

	inc	si		; Skip over separator

; Get length of next field

	push	lpIDDrvBuf.VSEG ; Pass buffer segment
	push	si		; ...	      offset
	call	StrLen		; Return with AX = string length

	mov	cx,ax		; Copy to count register

; Copy the text to szIDTextName

	lea	di,szIDTextName ; ES:DI ==> destin buffer
    rep movs	szIDTextName[di],ds:[si].LO ; Copy to buffer
	mov	al,0		; Get ASCIIZ terminator
	stos	es:[di].LO	; Ensure properly terminated

	clc			; Mark as successful
ParseIDLineExit:
	popa			; Restore
	pop	ds		; ...

	pop	bp		; ...

	ret	4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ParseIDLine endp		; End ParseIDLine procedure
	NPPROC	SearchIDSEct -- Search For ID Section
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search for ID section

On exit:

ES:DI	==>	start of section (ends with double zero)
CF	=	0 section found
	=	1 not

|

SIDS_STR struc

	dw	?		; Caller's BP
	dw	?		; ...	   IP
SIDS_SECTLEN dw ?		; Length of section name
SIDS_SECT dd	?		; Ptr to ...
SIDS_BUF  dd	?		; ...	 buffer

SIDS_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax>		; Save register

	les	di,[bp].SIDS_BUF ; ES:DI ==> start of buffer
	assume	es:nothing	; Tell the assembler about it
SIDS_NEXT:
	call	SkipWhite	; Skip ES:DI over white space

	cmp	es:[di].LO,'['  ; Izit start of section?
	jne	short SIDS_LOOP ; Jump if not

	inc	di		; Skip over it

	push	es		; Pass segment of buffer
	push	di		; ...  offset ...
	push	[bp].SIDS_SECT	; ...  ptr to section name
	push	[bp].SIDS_SECTLEN ; ... length of ...
	call	StrNICmp	; Compare 'em

	and	ax,ax		; Are they equal?
	jnz	short SIDS_LOOP ; Jump if not

	add	di,[bp].SIDS_SECTLEN ; Skip over section name

	cmp	es:[di].LO,']'  ; Izit end of section?
	jnz	short SIDS_LOOP ; Jump if not

; It's a match

	call	SkipLine	; Skip ES:DI to next line
;;;;;;; jc	short ???	; Ignore error return

	push	di		; Save as return offset

; Search for the end of the section and mark it with a terminating zero

@@:
	call	SkipWhite	; Skip ES:DI over white space

	cmp	es:[di].LO,'['  ; Izit start of section?
	je	short SIDS_DONE ; Jump if so

	call	SkipLine	; Skip ES:DI to next line
	jnc	short @B	; Jump if not end of file
SIDS_DONE:
	mov	al,0		; Get terminating zero
	stos	es:[di].LO	; Mark it

	pop	di		; Restore return offset

	jmp	short SIDS_EXIT ; Join common exit code

SIDS_LOOP:
	call	SkipLine	; Skip ES:DI to next line
	jnc	short SIDS_NEXT ; Jump if not end of file
SIDS_EXIT:
	REGREST <ax>		; Restore

	pop	bp		; Restore

	ret	4+4+2		; Return to caller, popping arguments

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SearchIDSect endp		; End SearchIDSect procedure
	NPPROC	SkipLine -- Skip To next Line
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip to the next line

On entry:

ES:DI	==>	somewhere on current line

On exit:

ES:DI	==>	start of next line
CF	=	0 if successful
	=	1 if end-o-file or end-of-section

|

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax>		; Save register

	xchg	si,di		; Swap with source register
SkipLineNext:
	lods	es:[si].LO	; Get next character

	cmp	al,1		; Izit end-of-file (0)?
	jb	short SkipLineExit  ; Jump if so (note CF=1)

	cmp	al,CR		; Izit an EOL char?
	je	short SkipLineEnd ; Jump if so

	cmp	al,LF		; Izit an EOL char?
	jne	short SkipLineNext ; Jump if so

; We're staring at an EOL char -- skip over others if present

SkipLineEnd:
	lods	es:[si].LO	; Get next character

	cmp	al,CR		; Izit an EOL char?
	je	short SkipLineEnd ; Jump if so

	cmp	al,LF		; Izit an EOL char?
	je	short SkipLineEnd ; Jump if so
SkipLineExit:
	dec	si		; Back off to previous char

	xchg	si,di		; Restore

	REGREST <ax>		; Restore

	pop	bp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SkipLine endp			; End SkipLine procedure
	NPPROC	SkipPath -- Skip Over Path
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip over path

On entry:

ES:DI	==>	current line

On exit:

ES:DI	==>	after path (if any)
CF	=	0 if successful
	=	1 if no more strings

|

	REGSAVE <ax,dx> 	; Save registers

	call	SkipWhite	; Skip ES:DI over white space
	mov	dx,di		; Initialize offset of start-of-path
SkipPathNext:
	mov	al,es:[di]	; Get next character
	inc	di		; Skip over it

	cmp	al,' '          ; Izit a separator (0, CR, LF, ' ', TAB)?
	jbe	short SkipPathEnd ; Jump if so

	cmp	al,':'          ; Izit drive separator?
	jne	short @F	; Jump if not

	mov	dx,di		; Save offset of next char
@@:
	cmp	al,'\'          ; Izit a path separator?
	jne	short @F	; Jump if not

	mov	dx,di		; Save offset of next char
@@:
	jmp	SkipPathNext	; Go around again

SkipPathEnd:
	mov	di,dx		; Restore offset of start of path
	mov	al,es:[di]	; Get next character

	cmp	al,0		; Izit end-of-file?
	je	short SkipPathErr ; Jump if so

	cmp	al,CR		; Izit end-of-line?
	je	short SkipPathErr ; Jump if so

	cmp	al,LF		; Izit end-of-line?
	je	short SkipPathErr ; Jump if so

	clc			; Mark as successful

	jmp	short SkipPathExit ; Join common exit code

SkipPathErr:
	stc			; Mark as no more strings
SkipPathExit:
	REGREST <dx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SkipPath endp			; End SkipPath procedure
	NPPROC	SkipToken -- Skip To Start Of Next Token
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Skip to start of next token which is the earliest of the next
occurrence of white space (' ', TAB), line term (CR, LF), and file
term (0).

On entry:

ES:DI	==>	current line

On exit:

ES:DI	==>	start of next token

|

ST_STR	struc

ST_TOK	dw	?		; Offset of next token

ST_STR	ends

	push	bp		; Prepare to address the stack
	sub	sp,type ST_STR	; Make room for local struc
	mov	bp,sp		; Hello, Mr. Stack

	REGSAVE <ax,dx> 	; Save registers

	call	SkipWhite	; Skip ES:DI over white space

; If the smallest of StrChr (white), StrChr (EOL), and Strlen
; is StrChr (white), that's the start of the next token

	mov	[bp].ST_TOK,-1	; Initialize with identity element for MIN

	push	es		; Pass segment of line
	push	di		; ...  offset ...
	push	CR		; ...  EOL char
	call	StrChr		; Return with DX:AX = next occurrence (0=none)

	or	dx,ax		; Did it fail?
	jz	short @F	; Jump if so

	cmp	ax,[bp].ST_TOK	; Use smaller
	jae	short @F	; Jump if nothing new

	mov	[bp].ST_TOK,ax	; Save as smaller
@@:
	push	es		; Pass segment of line
	push	di		; ...  offset ...
	push	LF		; ...  EOL char
	call	StrChr		; Return with DX:AX = next occurrence (0=none)

	or	dx,ax		; Did it fail?
	jz	short @F	; Jump if so

	cmp	ax,[bp].ST_TOK	; Use smaller
	jae	short @F	; Jump if nothing new

	mov	[bp].ST_TOK,ax	; Save as smaller
@@:
	push	es		; Pass segment of line
	push	di		; ...  offset ...
	push	' '             ; ...  white space char
	call	StrChr		; Return with DX:AX = next occurrence (0=none)

	or	dx,ax		; Did it fail?
	jz	short @F	; Jump if so

	cmp	ax,[bp].ST_TOK	; Use smaller
	jae	short @F	; Jump if nothing new

	mov	[bp].ST_TOK,ax	; Save as smaller
@@:
	push	es		; Pass segment of line
	push	di		; ...  offset ...
	push	TAB		; ...  white space char
	call	StrChr		; Return with DX:AX = next occurrence (0=none)

	or	dx,ax		; Did it fail?
	jz	short @F	; Jump if so

	cmp	ax,[bp].ST_TOK	; Use smaller
	jae	short @F	; Jump if nothing new

	mov	[bp].ST_TOK,ax	; Save as smaller
@@:
	push	es		; Pass segment of line
	push	di		; ...  offset ...
	call	StrLen		; Return with AX = string length

	add	ax,di		; Plus starting address to get ending

	cmp	ax,[bp].ST_TOK	; Use smaller
	jae	short @F	; Jump if nothing new

	mov	[bp].ST_TOK,ax	; Save as smaller
@@:
	mov	di,[bp].ST_TOK	; Get the next offset

	REGREST <dx,ax> 	; Restore

	add	sp,type ST_STR	; Strip from the stack

	pop	bp		; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SkipToken endp			; End SkipToken procedure
	NPPROC	ReadIncompat -- Read In List Of Incompatible Drivers
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read in list of incompatible drivers

On Exit:

CF	=	0 if successful
	=	1 if not

|

	pusha			; Save all GP registers
	REGSAVE <es>		; Save register

	mov	ax,seg DGROUP	; Get DGROUP selector
	mov	ds,ax		; Address it
	assume	ds:DGROUP	; Tell the assembler about it

; See if we should ignore this request
; because there's an "ignore=1" in QMAX.INI's
; [Go Ahead - Incompatible Drivers] section

	push	lpIDSect	; Pass ptr to section name
	push	lpIDIgnName	; ...	      line name
	push	FALSE		; ...	      default value (don't ignore)
	push	lpQMAXINIFile	; ...  ptr to .INI filename
	call	GetPrivateProfileInt ; Return value in AX
	assume	es:nothing	; Tell the assembler about it

	cmp	ax,TRUE 	; Izit TRUE?
	je	near ptr ReadIncompatExit ; Jump if we're to ignore (note CF=0)

; Allocate memory on the global heap for the .INI file section

	push	GPTR		; Fixed memory
	push	dwGlbHeap	; # bytes to allocate
	call	GlobalAlloc	; Return with AX:0 ==> allocation (0:0 if none)

	and	ax,ax		; Did it succeed?
	jz	near ptr ReadIncompatExit ; Jump if not (note CF=0)

	mov	lpGlbHeap.VSEG,ax ; Save as local heap segment

; Read in the [Go Ahead - Incompatible Drivers] section count

	push	lpIDSect	; Pass ptr to section name
	push	lpIDCntName	; ...	      line name
	push	0		; ...	      default value (none)
	push	lpQMAXINIFile	; ...  ptr to .INI filename
	call	GetPrivateProfileInt ; Return value in AX
	assume	es:nothing	; Tell the assembler about it

	and	ax,ax		; Izit empty?
	jz	near ptr ReadIncompatExit ; Jump if so (note CF=0)

	mov	cx,ax		; Copy to count register
ReadIncompatNext:
	mov	ax,ds		; Get DGROUP selector
	mov	es,ax		; Address it
	assume	es:DGROUP	; Tell the assembler about it

; Construct the entry name of the next driver

	mov	ax,cx		; Copy the current count
	xor	dx,dx		; Zero to use DX:AX as dword

	lea	di,szIDDrvName1 ; ES:DI ==> output save area

	push	@DEC_LEFT	; Mark as left-justified
	call	DD2DEC		; Convert (DX,AX) to decimal at ES:DI,
				; return with ES:DI ==> next char
	mov	es:[di].LO,0	; Ensure properly terminated

; Read in the next [Go Ahead - Incompatible Drivers] section entry

	REGSAVE <cx,es> 	; Keep W's grubby hands away from

	push	lpIDSect	; Pass ptr to section name
	push	lpIDDrvName	; ...	      line name
	push	lpDefValue	; ...	      default string (empty)
	push	lpIDDrvBuf	; ...	      dest buffer
	push	size szIDDrvBuf ; ...  size of ...
	push	lpQMAXINIFile	; ...  ptr to .INI filename
	call	GetPrivateProfileString ; Return length in AX,
				; not counting the last zero
	assume	es:nothing	; Tell the assembler about it

	REGREST <es,cx> 	; Safe again
	assume	es:DGROUP	; Tell the assembler about it

	and	ax,ax		; Did it fail?
	jz	near ptr ReadIncompatLoop ; Jump if so

; Parse the line into its constituent parts

	push	lpIDDrvBuf	; Pass address of section name
	call	ParseIDLine	; Parse it
	jc	near ptr ReadIncompatLoop ; Jump if something went wrong

; Read in the entire .INI file

	mov	al,@OPEN_R	; Read-only attribute
	DOSCALL @OPENF2,szIDININame ; Attempt to open the file
	jc	near ptr ReadIncompatLoop ; Jump if something went wrong

	mov	bx,ax		; Copy to handle register

	REGSAVE <cx,ds> 	; Save for a moment

	mov	cx,dwGlbHeap.ELO ; Get # bytes to read
	lds	dx,lpGlbHeap	; DS:DX ==> save area on global heap
	assume	ds:nothing	; Tell the assembler about it

	DOSCALL @READF2 	; Read it all in
	REGREST <ds,cx> 	; Restore
	assume	ds:DGROUP	; Tell the assembler about it
				; Return with CF significant
	mov	nINIFile,ax	; Save # bytes read

	pushf			; Save CF
	DOSCALL @CLOSF2 	; Close it up
	popf			; Restore CF
	jc	near ptr ReadIncompatLoop ; Jump if something went wrong

; Mark the end of the INI file

	push	ds		; Save for a moment

	lds	si,lpGlbHeap	; DS:SI ==> save area on global heap
	assume	ds:nothing	; Tell the assembler about it

	add	si,nINIFile	; Plus length of file
	mov	ds:[si].LO,0	; Mark with terminating zero

	pop	ds		; Restore
	assume	ds:DGROUP	; Tell the assembler about it

; Search for the section name

	push	lpGlbHeap	; Pass address of buffer
	push	lpIDSectName	; ...		  section name
	push	nIDSectName	; ...  length of  ...
	call	SearchIDSect	; Return with ES:DI ==> section
	assume	es:nothing	; Tell the assembler about it
	jc	short ReadIncompatLoop ; Jump if something went wrong

; Loop through the lines in the section checking for an entry name match

	jmp	short ReadIncompatNextEntry ; Join common code

ReadIncompatLoopEntry:
	call	SkipLine	; Skip ES:DI to next line
	jc	short ReadIncompatLoop ; Jump if end of section
ReadIncompatNextEntry:
	call	SkipWhite	; Skip ES:DI over white space

; Check for match with entry name

	push	es		; Pass segment of buffer
	push	di		; ...  offset ...
	push	lpIDEntryName	; ...  ptr to entry name
	push	nIDEntryName	; ...  length of ...
	call	StrNICmp	; Compare 'em

	and	ax,ax		; Are they equal?
	jnz	short ReadIncompatLoopEntry ; Jump if not

	add	di,nIDEntryName ; Skip over entry name

	cmp	es:[di].LO,'='  ; Izit proper separator?
	jnz	short ReadIncompatLoopEntry ; Jump if not

	inc	di		; Skip over separator

; Loop through the strings following this entry name for an item match

ReadIncompatNextString:
	call	SkipPath	; Skip ES:DI over path
	jc	short ReadIncompatLoopEntry ; Jump if no more

; Check for match with string name

	push	es		; Pass segment of buffer
	push	di		; ...  offset ...
	push	lpIDStrName	; ...  ptr to entry name
	push	nIDStrName	; ...  length of ...
	call	StrNICmp	; Compare 'em

	and	ax,ax		; Are they equal?
	jnz	short ReadIncompatLoopString ; Jump if not

; For it to be a proper match, the next character
; must be a valid terminator (String:  ' ', TAB; Line:  CR, LF; File:  0)

	mov	bx,nIDStrName	; Get length of string name
	mov	al,es:[bx+di]	; Get next character

	cmp	al,' '          ; Izit white space?
	je	short ReadIncompatMatch ; Jump if so

	cmp	al,TAB		; Izit white space?
	je	short ReadIncompatMatch ; Jump if so

	cmp	al,CR		; Izit line terminator?
	je	short ReadIncompatMatch ; Jump if so

	cmp	al,LF		; Izit line terminator?
	je	short ReadIncompatMatch ; Jump if so

	cmp	al,0		; Izit file terminator?
	jne	short ReadIncompatLoopString ; Jump if not
ReadIncompatMatch:
	or	LCL_FLAG,@LCL_RIDDIS ; Mark as disabled due to RID

	stc			; Mark as a match

	jmp	short ReadIncompatExit ; Join common code

ReadIncompatLoopString:

; Skip to start of next token

	call	SkipToken	; Skip to start

	jmp	ReadIncompatNextString ; Go around again

ReadIncompatLoop:
;;;;;;; loop	ReadIncompatNext ; Jump if more ID entries
	dec	cx		; Count out another
	jnz	near ptr ReadIncompatNext ; Jump if more ID entries

	clc			; Mark as successful
ReadIncompatExit:
	pushf			; Save CF

	cmp	lpGlbHeap.VSEG,0 ; Izit invalid?
	je	short @F	; Jump if so

	push	lpGlbHeap.VSEG	; Pass the selector
	call	GlobalFree	; Free the global memory
@@:
	popf			; Restore CF

	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler about it
	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ReadIncompat endp		; End ReadIncompat procedure

_TEXT	ends			; End _TEXT segment

	END			; End GDARID Module

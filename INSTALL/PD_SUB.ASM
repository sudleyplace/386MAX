;' $Header:   P:/PVCS/MAX/INSTALL/PD_SUB.ASV   1.2   30 May 1997 11:27:44   BOB  $
	 title	 PD_SUB -- Subroutines to 386MAX Installation
	 page	 58,122
	 name	 PD_SUB

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1985-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  byte-aligned, public, class 'data'

Program derived from:  INST_SUB.ASM

Original code by:  Bob Smith, July, 1986.

Modifications by:  Patrick Devlin, December, 1990

|
.8086
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include PTR.INC
	 include DIR.INC
	 include FCB.INC
	 include DOSCALL.INC
	 include 386.INC
	 include BIOSCONF.INC
	 include EMMCALL.INC
	 include EMM2CALL.INC
	 include CMOS.INC
	 include 8255.INC
	 include INTVEC.INC
	 include OPEN.INC
	 include IOCTL.INC
	 include BIOSDATA.INC
	 include XBIOS.INC
	 include MAC.INC

	 include QMAX_RAM.INC
.list

%.model &MODEL,c

	 @NO_UNDERBAR	equ	0
if (ASYS and 1)
	 include BIOSCRC.INC
endif					; BlueMAX INSTALL (ASYS=1 or ASYS=11)
	 include VENDINFO.INC
	 include RAMSCAN.INC

@STRIPMGR_CB equ	 0		; We chain to STRIPMGR rather than
					; call it, so the callback code isn't
					; needed.

	 .data

	 extrn	 errno:word

	 extrn	 SUB_FLAG:word		; Local flags
	 extrn	 PORT67:word		; Port to use for MAX back door access

	 public  RAMTAB
RAMTAB	 db	 (384/4) dup (0) ; RAMSCAN table

	 public  TMPROM
TMPROM	 dw	 ?		; Temporary CMPROM for ROM_HOLES

;;;;;;;; public  POSDATA
;;;;;;;; include QMAX_POS.INC
;;;POSDATA  POSD_STR 8 dup (<0>)   ; Save area for POS data from MAX

@SECURITY_LEN equ 350

	 public  SECURITY_LEN,security_pattern,security_crc
SECURITY_LEN dw  @SECURITY_LEN
security_pattern db (@SECURITY_LEN/10) dup ('0123456789')
security_crc dw ?		; Following CRC (actually a checksum)

;;;;;;;  public  CURDIR
;;;;;;;CURDIR	 db	 80 dup (0)	; Save area for current directory
;;;;;;;  db	 0		; null terminator for 64-byte directory

if @STRIPMGR_CB
	 public  Our_SP
Our_SP	 dw	  ?		; SP to use for STRIPMGR callbacks
endif				; IF @STRIPMGR_CB

	 .code

	 public  OLDINT1C_VEC,OLDINT23_VEC,OLDINT24_VEC
OLDINT1C_VEC dd  ?		; Save area for old INT 1Ch handler
OLDINT23_VEC dd  ?		; ...			23h
OLDINT24_VEC dd  ?		; ...			24h

if @STRIPMGR_CB
	 public  Save_Stack
Save_Stack   dd  ?		; SS:SP when called from STRIPMGR.EXE

	 extrn	 do_intmsg:proc
	 extrn	 do_yesno:proc
endif				; IF @STRIPMGR_CB

	public	QEMMNAME
QEMMNAME db	'QEMM386$',0    ; Device name for QEMM

	 PPROC	 DEBUG -- Call Debugger
	 assume  ds:nothing,es:nothing,ss:nothing

	 int	 03
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DEBUG	 endp			; End DEBUG procedure

	PPROC	IZITQEMM -- Is QEMM Active
	assume	ds:nothing,es:nothing,ss:nothing
COMMENT|

Is QEMM active?

On exit:

AX	=	1 if it's active
	=	0 if not

|

	REGSAVE <bx,dx,ds>	; Save registers

	mov	ax,cs		; Copy segment of QEMMNAME
	mov	ds,ax		; Address it

	mov	al,@OPEN_R	; Open for read-only access
	DOSCALL @OPENF2,QEMMNAME ; Attempt to open the file
	jc	short IZITQEMM_ERR ; Jump if not

	mov	bx,ax		; Copy to file handle register
	mov	al,0		; Read IOCTL info
	DOSCALL @IOCTL2 	; Return IOCTL info in DX
	jc	short IZITQEMM_ERR ; Jump if something went wrong

	test	dx,@IOCTL_DEV	; Izit a device?
	jz	short IZITQEMM_ERR ; Jump if not

	mov	ax,1		; Mark as present

	jmp	short IZITQEMM_EXIT ; Join common exit code

IZITQEMM_ERR:
	xor	ax,ax		; Mark as not present
IZITQEMM_EXIT:
	REGREST <ds,dx,bx>	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,ss:nothing

IZITQEMM endp			; End IZITQEMM procedure

	 PPROC	 _RAMSCAN -- Test For Presence of RAM In High DOS Memory
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Test for presence of RAM in high DOS memory.

If 386MAX is present, ask it to do it for us.
Otherwise, do it ourselves.

On exit:

DX:AX	 ==>	 RAMSCAN structure

|

	 REGSAVE <di,bp,es>	; Save registers

	 push	 ds		; Get DGROUP segment
	 pop	 es		; Setup ES for RAMSCAN
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 MAXPRES	; Set all variables

	 test	 SUB_FLAG,@SUB_PRES ; Is 386MAX present?
	 jz	 short RAMSCAN_XPRES ; Jump if not

	 test	 SUB_FLAG,@SUB_VM ; Izit active?
	 jz	 short RAMSCAN_XPRES ; Jump if not

	 lea	 di,DGROUP:RAMTAB ; ES:DI ==> output save area
	 mov	 bp,sp		; Save stack pointer
	 EMMOUT  @EMM2_RAMSCAN	; Request RAM scan of high DOS memory
				; Return with AH = error status
	 mov	 sp,bp		; Restore

;;;;;;;; cmp	 ah,0A4h	; Check for access denied
;;;;;;;; je	 short RAMSCAN_DENY ; Jump if denied
;;;;;;;;
	 and	 ah,ah		; Check return code
	 jz	 short RAMSCAN_DONE ; Join common exit code
RAMSCAN_ERR:
	 xor	 ax,ax		; Return null address
	 xor	 dx,dx		; ...in DX:AX

	 jmp	 short RAMSCAN_EXIT ; Join common exit code


; 386MAX is not present -- do it ourselves

RAMSCAN_XPRES:
	 call	 LCL_RAMSCAN	; Use local subroutine
RAMSCAN_DONE:

; Return pointer to structure in DX:AX

	 lea	 ax,DGROUP:RAMTAB ; Get the offset into AX
	 mov	 dx,ds		; Copy segment into DX
RAMSCAN_EXIT:
	 REGREST <es,bp,di>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_RAMSCAN endp			; End _RAMSCAN procedure
	 NPPROC  LCL_RAMSCAN -- Search For RAM In High Memory
	 assume  ds:DGROUP,es:DGROUP,ss:nothing
COMMENT|

If high DOS memory or EMS page frame needed,
search for RAM in high memory and fill in MEM_MAP accordingly.

|

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save the registers

;;;;;;;; call	 SAVE_CACHE	; Save and disable the state of the
				; cache controller
				; BP = current state

	 mov	 cx,size RAMTAB ; CX = # characters in RAMTAB to fill in
	 lea	 di,DGROUP:RAMTAB ; ES:DI ==> RAMSCAN table
LCL_RAMSCAN_NEXT:
	 mov	 bx,di		; Copy starting offset+1
	 sub	 bx,offset DGROUP:RAMTAB ; Convert to origin-0
	 push	 cx		; Save for a moment
	 mov	 cl,12-4	; Shift amount between paras and 4KB
	 shl	 bx,cl		; Convert from 4KB to paras
	 pop	 cx		; Restore
	 add	 bx,0A000h	; Convert to origin-A000

	 mov	 al,0		; Assume RAM not present
	 cmp	 bx,0B000h	; Izit below the MDA region?
	 jb	 short @F	; Jump if so

	 cmp	 bx,0B800h	; Izit above the MDA region?
	 jnb	 short @F	; Jump if so

	 call	 CHECK_RAM	; Check for RAM in 512-byte block at BX:0
	 jnc	 short @F	; Jump if not RAM

	 or	 al,mask $RAM_RAM ; Mark as RAM
@@:
	 stosb			; Save in RAMSCAN table

	 loop	 LCL_RAMSCAN_NEXT ; Jump if more 4KB blocks to test

;;;;;;;; call	 REST_CACHE	; Restore state of cache controller from BP

	 REGREST <di,si,dx,cx,bx,ax> ; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LCL_RAMSCAN endp		; End LCL_RAMSCAN procedure
if @STRIPMGR_CB
	FPPROC	StripmgrOutput -- Handle STRIPMGR.EXE output
	assume	ds:nothing,es:nothing,ss:nothing
COMMENT|
Take an indirect far call from STRIPMGR.EXE with an int and a
far char * on the stack.  Set up our own stack and act according
to the int value.  If it is 0, call do_intmsg() with the char *
as an argument.  If 1, set up a yes/no dialog box with the char *
as message text.  Return the character input in AX.
|

sout_str	struc
	dd	?		; CS:IP
	dw	?		; BP
action	dw	?		; int (0 for output, 1 for input)
string	dd	?		; far char *
sout_str	ends

	push	bp		; Save caller's BP
	mov	bp,sp		; Address stack

	push	es		; Save caller's ES

	push	ds		; Save caller's DS

	mov	Save_stack.VSEG,ss ; Save caller's stack
	mov	Save_stack.VOFF,sp

	mov	ax,[bp].action	; Get action type (0 for output, 1 for input)

	les	bx,[bp].string	; Get far pointer
	assume	es:nothing	; Tell the assembler

	mov	cx,seg DGROUP	; Prepare to address DGROUP
	mov	ds,cx		; Address DGROUP with DS
	assume	ds:DGROUP	; Tell the assembler

	cli			; Nobody move
	mov	ss,cx		; Make SS == DS
	assume	ss:nothing	; Tell the assembler
	mov	sp,Our_SP	; Get safe SP for callback
	sti			; Enable interrupts

	or	ax,ax		; Izit 0, indicating output request?
	jz	short SO_output ; Jump if so

	dec	ax		; Izit 1, indicating yes/no dialog request?
	jz	short SO_input	; Jump if so

;;;;;;	jmp	short SO_unknown ; Jump if invalid

	; Display something so we don't leave them scratching their heads

SO_output:
	push	es		; Pass segment
	push	bx		; Pass offset
	call	do_intmsg	; Display message
	add	sp,2*2		; Pop words from stack

	jmp	short SO_common ; Join common exit code

SO_input:
	sub	ax,ax		; Get a zero
	push	ax		; No help wanted
	push	es		; Pass string segment
	push	bx		; Pass string offset
	call	do_yesno	; Display dialog, return 'Y' or 'N' in AX
	add	sp,2*3		; Pop 3 words from stack

SO_common:
	cli			; Nobody move
	mov	ss,Save_stack.VSEG ; Restore SS
	mov	sp,Save_stack.VOFF ; Restore SP
	sti			; Enable interrupts

	pop	ds		; Restore caller's DS (from caller's stack)
	assume	ds:nothing	; Tell the assembler

	pop	es		; Restore caller's ES
	assume	es:nothing	; Tell the assembler

	pop	bp		; Restore caller's BP
	ret			; Return to caller
	assume	ds:nothing,es:nothing,ss:nothing

StripmgrOutput	endp		; End StripmgrOutput
endif				; IF @STRIPMGR_CB

	 PPROC	 freeMB -- Check for free space on specified drive
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Check specified drive letter.  If it's not a network or removable drive
and has the minimum required free space, it's a candidate for us to put
the 386MAX directory on.  Return the available space in MB (rounded down).

On entry:
All critical errors should fail quietly.

On exit:
If network drive, removable drive, or invalid drive:
AX=0
else
AX=free space in MB
BX,CX,DX Destroyed.

|

fm_str	struc
	dw	1+@CodeSize dup (?) ; [CS:]IP
	dw	?		; BP
fm_drv	db	?,?		; 'A'..'Z' and filler
fm_str	ends

	 push	 bp		; Save caller's BP
	 mov	 bp,sp		; Address stack

	 mov	 bl,[bp].fm_drv ; Get drive letter
	 and	 bl,5fh 	; Make it uppercase
	 sub	 bl,'@'         ; A=1, B=2, etc.
	 mov	 [bp].fm_drv,bl ; Save for later

	 mov	 ax,(@IOCTL2 shl 8) or 09h ; Is drive remote?
	 DOSCALL		; Return flags in DX
	 jc	 short IC_ERR	; Jump if call failed (invalid drive)

	 test	 dx,9000h	; Izit a network drive or a SUBST drive?
	 jnz	 short IC_ERR	; Jump if so

	 test	 dx,0800h	; Is 4408 (is drive removable) suppported?
	 jz	 short NOT_REMOVABLE ; Jump if not (assume it's not removable)

	 mov	 bl,[bp].fm_drv ; Get drive letter
	 mov	 ax,(@IOCTL2 shl 8) or 08h ; Is drive removable?
	 DOSCALL		; Return AX=0 if so
	 jc	 short IC_ERR	; Jump if call failed (invalid drive)

	 or	 ax,ax		; Izit removable?
	 jz	 short IC_ERR	; Jump if so (it's not a candidate)

NOT_REMOVABLE:
	 mov	 dl,[bp].fm_drv ; Get drive to check
	 DOSCALL @FATAD3	; Get FAT info for DL
	 jc	 short IC_ERR	; Jump if call failed

	 cmp	 ax,-1		; Is the drive invalid?
	 je	 short IC_ERR	; Jump if so

; AX=sectors per cluster
; BX=available clusters
; CX=bytes per sector
	 shl	 cx,1		; shr cx,6
	 mov	 cl,ch		; ...
	 sub	 ch,ch		; Sector size in units of 128
	 mul	 cx		; AX = 128 byte units per cluster
	 mul	 bx		; DX,AX = available 128 byte units
	 mov	 bx,8*1024	; Convert to MB
	 div	 bx		; AX = available MB
	 jmp	 short IC_EXIT	; Join common exit

IC_ERR:
	 sub	 ax,ax		; Drive is removable or network
IC_EXIT:
	 pop	 bp		; Restore caller's BP

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

freeMB	 endp			; End freeMB procedure

	 PPROC	 openhigh -- Attempt to link high DOS using 5803
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Try to link arenas.  Return AX=0 if we succeed, else DOS error code.

On exit:
AX	 0 or DOS error code
BX,CX,DX Trashed

|

	 mov	 ax,@MACALG*256 + 03h ; Set arena link state to BX
	 mov	 bx,mask $LINK_HIGH ; 0001 to link
	 DOSCALL		; AX=error code if failure
	 jc	 short @F	; Jump if we failed

	 sub	 ax,ax		; Indicate success
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

openhigh endp			; End openhigh procedure

	 PPROC	 closehigh -- Attempt to close high DOS using 5803
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Try to unlink arenas.  Return AX=0 if we succeed, else DOS error code.

On exit:
AX	 0 or DOS error code
BX,CX,DX Trashed

|

	 mov	 ax,@MACALG*256 + 03h ; Set arena link state to BX
	 sub	 bx,bx		; 0000 to unlink
	 DOSCALL		; AX=error code if failure
	 jc	 short @F	; Jump if we failed

	 sub	 ax,ax		; Indicate success
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

closehigh endp			; End closehigh procedure

	 MEND			; End PD_SUB module

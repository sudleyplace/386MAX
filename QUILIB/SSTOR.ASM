;' $Header:   P:/PVCS/MAX/QUILIB/SSTOR.ASV   1.1   30 May 1997 12:09:04   BOB  $
	 title	 SSTOR - Stacker and SuperStor MASM support routines
	 page	 58,122
	 name	 SSTOR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Ungrouped:
	       Program segment xxx_TEXT, word-aligned,	public, class 'code'
	       Group DGROUP:
	       Data    segment _DATA,	 word-aligned,	public, class 'data'

Link requirements:  Callable from MSC 6+.

Program derived from:  None.

Original code by:  Henry Groover, August 1992.

Modifications by:  None.

|

.8086
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include PTR.INC
	 include DEVDRV.INC
.list

%.model  &MODEL,c

.data

	 extrn	 stackinfo:dword ; In STACKER.C

;;;;;;;  public  NULLNAME,ADDSTOR_SIG
;;;;;;;NULLNAME db	'NUL     '      ; Name of first device in chain
;;;;;;;NULLNAME_LEN equ $-NULLNAME	; Length of string to compare
;;;;;;;ADDSTOR_SIG db	'ADDSTOR'       ; Signature at offset 20h in SSTOR devices
;;;;;;;@ADDSTOR_SIGLEN equ $-ADDSTOR_SIG ; Length of string to compare

.code

	 PPROC	 stacker_present -- Determine if Stacker's present
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT |
; int stacker_present (void)

Return version*100 in AX and initialize stackinfo if we detect Stacker
is present.  Otherwise, return 0.

On entry:
nothing.

On exit:
AX	 Stacker version (unpacked BCD).
ES, BX, CX, and DX destroyed.

|

stackid_str struc		; Stacker ID structure returned by Int 25h
stackid_sig dw	 ?		; 0CDCDh
stackid_fld1 dw  ?		; Should be 1 (?)
stackid_pinfo dd ?		; Far pointer to Stacker info structure
stackid_str ends

stackinfo_str struc		; Stacker info structure (from stackid_pinfo)
stackinfo_sig dw ?		; 00: 0A55Ah
stackinfo_ver dw ?		; 02: Version * 100
	db 03Ah dup (?) 	; 04: Unknown 1
stackinfo_unit db ?		; 3E: UNIT_OFFS for IOCTL
	db 13h dup (?)		; 3F: Unknown 2
stackinfo_swapsig db 4 dup (?)	; 52: 'SWAP'
stackinfo_swapmap db 26 dup (?) ; 56: Mappings for drive numbers from 0-25
stackinfo_str ends

	 REGSAVE <si,di,bp>	; Save
	 sub	 sp,1024	; Allocate storage on stack

	 mov	 ax,0CDCDh	; Invalid drive #
	 mov	 bx,sp		; DS:BX ==> Int 25h read buffer
	 mov	 cx,1		; Number of (bogus) sectors to read
	 sub	 dx,dx		; Read sector 0 (partition boot sector)
	 mov	 ds:[bx].stackid_sig,dx ; Clear return value

	 push	 ds		; Set ES:BP for DOS 3 Int 25 bug
	 pop	 es
	 assume  es:DGROUP	; Tell the assembler

	 mov	 bp,bx

	 int	 25h		; Return with flags on stack
	 pop	 cx		; Discard flags

	 sub	 ax,ax		; Assume Stacker not present
	 mov	 bx,sp		; Address return structure
	 cmp	 ds:[bx].stackid_sig,0CDCDh ; Does signature match?
	 jne	 SPRES_EXIT	; Jump if not

	 cmp	 ds:[bx].stackid_fld1,1 ; Does this field match?
	 jne	 SPRES_EXIT	; Jump if not

	 les	 bx,ds:[bx].stackid_pinfo ; Get pointer to STACKER info structure
	 assume  es:nothing	; Tell the assembler

	 cmp	 es:[bx].stackinfo_sig,0A55Ah ; Is info structure valid?
	 jne	 SPRES_EXIT	; Jump if not

	 mov	 stackinfo.VOFF,bx ; Save offset
	 mov	 stackinfo.VSEG,es ; Save segment
	 mov	 ax,es:[bx].stackinfo_ver ; Return stacker version * 100 decimal

SPRES_EXIT:
	 add	 sp,1024	; Release stack storage
	 REGREST <bp,di,si>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

stacker_present  endp		; End stacker_present procedure
;;;;;;;  PPROC	 sstor_bdev -- Determine whether device is SSTOR
;;;;;;;  assume  ds:DGROUP,es:nothing,ss:nothing
;;;;;;;COMMENT |
;;;;;;;; int sstor_bdev (int dnum)
;;;;;;;
;;;;;;;Determine if the block device supporting the specified drive number
;;;;;;;contains the 'ADDSTOR' signature at offset 20h in the device header.
;;;;;;;Even though we can make an IOCTL read request to check for an ADDSTOR
;;;;;;;device, we want to avoid it if it doesn't look like a SuperStore drive.
;;;;;;;
;;;;;;;On entry:
;;;;;;;Drive number on stack
;;;;;;;
;;;;;;;On exit:
;;;;;;;AX=1	 Drive appears to be a SuperStor device
;;;;;;;AX=0	 Drive does not contain ADDSTOR signature
;;;;;;;ES,BX,CX, and DX destroyed.
;;;;;;;
;;;;;;;|
;;;;;;;
;;;;;;;dnum_str struc
;;;;;;;ret_ax	 dw	 ?		; Caller's AX (return value)
;;;;;;;dosver	 dw	 ?		; DOS version
;;;;;;;  ;;;;;;;dw	 ?		; Caller's BP
;;;;;;;  dw	 (1+@codesize) dup (?) ; Caller's IP or CS:IP
;;;;;;;dnum	 dw	 ?		; Drive number (0=A, 1=B, 2=C, etc.)
;;;;;;;dnum_str ends
;;;;;;;
;;;;;;;  push	 bp		; Prepare to address the stack
;;;;;;;  sub	 sp,2*2 	; Allocate space for local variables
;;;;;;;  mov	 bp,sp		; Hello, Mr. Stack
;;;;;;;
;;;;;;;  REGSAVE <si,di,ds>	; Save
;;;;;;;
;;;;;;;  mov	 [bp].ret_ax,1	; Assume success
;;;;;;;
;;;;;;;  DOSCALL @DOSVER	; Return DOS version in AX
;;;;;;;  xchg	 ah,al		; Put high byte where it belongs
;;;;;;;  mov	 [bp].dosver,ax ; Save for later
;;;;;;;
;;;;;;;  push	 ds		; Get DGROUP
;;;;;;;  pop	 es		; Save segment from GETBPB call
;;;;;;;  assume  es:DGROUP	; Tell the assembler
;;;;;;;
;;;;;;;  mov	 dx,[bp].dnum	; Get 0-based drive number
;;;;;;;  inc	 dl		; Get BPB expects it to be 1-based
;;;;;;;  DOSCALL @GETDP2	; Return DPB for drive DL in DS:BX
;;;;;;;  assume  ds:nothing	; Tell the assembler
;;;;;;;
;;;;;;;  jc	 short IOCTL_EXIT ; Jump if call failed
;;;;;;;
;;;;;;;  cmp	 al,0FFh	; Izit FF (invalid drive number)?
;;;;;;;  je	 short IOCTL_EXIT ; Jump if so
;;;;;;;
;;;;;;;  add	 bx,13h 	; Offset of device address for DOS 4+
;;;;;;;  cmp	 [bp].dosver,0400h ; Izit DOS 3?
;;;;;;;  sbb	 bx,0		; Offset for DOS versions < 4 is 12h
;;;;;;;
;;;;;;;  lds	 si,ds:[bx].EDD ; Get address of device header
;;;;;;;  assume  ds:nothing	; Tell the assembler
;;;;;;;
;;;;;;;  mov	 si,20h 	; Offset of 'ADDSTOR' signature in device segment
;;;;;;;
;;;;;;;; Note that this comparison will always fail when a program like SMARTDRV.EXE
;;;;;;;; has blasted itself into the DPB chain...
;;;;;;;  lea	 di,DGROUP:ADDSTOR_SIG ; What to compare with
;;;;;;;  mov	 cx,@ADDSTOR_SIGLEN ; Bytes to compare
;;;;;;;   repne cmps	 ds:[si].LO,ADDSTOR_SIG ; Compare 'em
;;;;;;;  jne	 short IOCTL_EXIT ; Jump if comparison failed
;;;;;;;
;;;;;;;IOCTL_TRUE:
;;;;;;;  mov	 [bp].ret_ax,1	; Indicate IOCTL support
;;;;;;;IOCTL_EXIT:
;;;;;;;  REGREST <ds,di,si>	; Restore
;;;;;;;  assume  ds:DGROUP	; Tell the assembler
;;;;;;;
;;;;;;;  mov	 ax,[bp].ret_ax ; Get return value
;;;;;;;  add	 sp,2*2 	; Free space for local variables
;;;;;;;  pop	 bp		; Restore
;;;;;;;
;;;;;;;  ret			; Return to caller
;;;;;;;
;;;;;;;  assume  ds:nothing,es:nothing,ss:nothing
;;;;;;;
;;;;;;;sstor_bdev	 endp		; End sstor_bdev procedure
;;;;;;;
	 MEND			; End SSTOR module


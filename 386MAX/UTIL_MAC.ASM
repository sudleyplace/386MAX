;' $Header:   P:/PVCS/MAX/386MAX/UTIL_MAC.ASV   1.2   30 May 1997 10:46:28   BOB  $
	 title	 UTIL_MAC -- 386MAX/MOVEIT Memory Allocation Chain Fns
	 page	 58,122
	 name	 UTIL_MAC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Data    segment UDATA,	dword-aligned, public, class 'udata'

Link requirements:  Final routine should have extension .SYS.
		    Link with VERSION.OBJ.

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include PTR.INC
	 include XMS.INC
	 include MAC.INC

	 include LOAD_SEG.INC
.list

PGROUP	 group	 DATA,UCODE,UDATA


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 LOADSEG:word

DATA	 ends			; End DATA segment


UDATA	 segment dword public 'udata' ; Start UDATA segment
	 assume  cs:PGROUP

	 public  XMSDRV_VEC
XMSDRV_VEC dd	 ?		; Save area for XMS driver address

UDATA	 ends			; End UDATA segment


UCODE	 segment byte public 'ucode' ; Start UCODE segment
	 assume  cs:PGROUP

	 NPPROC  IZITLSEG -- Is AX:0 An LSEG Entry?
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Is AX:0 an LSEG entry?

On entry:

AX	 ==>	 current MAC entry + 1

On exit:

CF	 =	 1 if so
	 =	 0 if not

|

	 REGSAVE <ax,bx,es>	; Save registers

; Search through the LSEG chain looking for a match with AX

	 mov	 bx,LOADSEG	; Get start of LSEG chain
IZITLSEG_NEXT:
	 cmp	 bx,-1		; Izit the end?
	 je	 short IZITLSEG_EXIT ; Jump if so (note CF=0)

	 cmp	 ax,bx		; Same segment?
	 je	 short IZITLSEG_FOUND ; Jump if it's a match

	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 bx,es:[0].LSEG_NEXT ; Get segment of next entry

	 jmp	 short IZITLSEG_NEXT ; Go around again

IZITLSEG_FOUND:
	 stc			; Mark as a match
IZITLSEG_EXIT:
	 REGREST <es,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

IZITLSEG endp			; End IZITLSEG procedure
	 NPPROC  CHECK_ORPHAN -- Check on Orphan LSEG Entries
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Check on orphan LSEG entries.

|

	 REGSAVE <ax,bx,dx,es>	; Save registers

; To avoid duplicate code, we trigger the same purpose code in
; the manager by attempting to allocate a large UMB entry.
; This has the effect of calling MAC_MERGE and thus CHECK_ORPHAN
; in the manager.

	 mov	 ax,4300h	; Function to determine presence
	 int	 2Fh		; Request redirector service

	 cmp	 al,80h 	; Check for presence
	 jne	 short CHECK_ORPHAN_EXIT ; Jump if not present????

; Request driver control address

	 push	 es		; Save for a moment

	 mov	 ax,4310h	; Function to get address
	 int	 2Fh		; Request redirector service
	 assume  es:nothing	; Tell the assembler about it

	 mov	 XMSDRV_VEC.VOFF,bx ; Save for later use
	 mov	 XMSDRV_VEC.VSEG,es

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 ah,@XMS_GETUMB ; Function to allocate an Upper Memory Block
	 mov	 dx,-1		; Impossible value
	 call	 XMSDRV_VEC	; Request XMS service
CHECK_ORPHAN_EXIT:
	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_ORPHAN endp		; End CHECK_ORPHAN procedure

UCODE	 ends			; End UCODE segment

	 MEND			; End UTIL_MAC module

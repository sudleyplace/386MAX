;' $Header:   P:/PVCS/MAX/386LOAD/MAPLOAD.ASV   1.1   30 May 1997 10:38:08   BOB  $
	 title	 MAPLOAD -- 386LOAD/MOVEIT Memory Map Display For TSRs
	 page	 58,122
	 name	 MAPLOAD

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment DTAIL,	para-aligned,  public, class 'zdata'
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'

Link requirements:  Final routine should have extension .SYS.
		    Link with VERSION.OBJ.

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include KEYCALL.INC
	 include MAC.INC
	 include BITFLAGS.INC
	 include PTR.INC
	 include DEVDRV.INC
	 include INTVEC.INC
.list

PGROUP	 group	 CODE,NCODE,NDATA,DTAIL,ACODE,ADATA


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 P1ST_MAC:dword

CODE	 ends			; End CODE segment


NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 AZS_ERRMAC:byte

NDATA	 ends			; End NDATA segment


DTAIL	 segment para public 'zdata' ; Start DTAIL segment
	 assume  ds:PGROUP

	 extrn	 POVR_MAC:word

DTAIL	 ends			; End DTAIL segment


ADATA	 segment dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP

	 extrn	 MSG_HDR:byte
	 extrn	 MSG_MIDDLE:byte
	 extrn	 MSG_MAPTAIL:byte

ADATA	 ends			; End ADATA segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 DISP_ERRMSG:near

NCODE	 ends			; End NCODE segment


ACODE	 segment byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

	 extrn	 ACT_MAPCMD:near
	 extrn	 ACT_MAPWIPE:near
	 extrn	 ACT_MAPDOS:near
	 extrn	 ACT_MAPSUB:near
	 extrn	 CHECK_ORPHAN:near
	 extrn	 STROUT:near

	 NPPROC  ACT_MAP -- Display Memory Map
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display memory map

|

	 REGSAVE <ax,dx,es>	; Save registers

	 lea	 dx,MSG_HDR	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 mov	 es,P1ST_MAC.EHI ; ES:0 ==> start of the MAC entries
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 P1ST_MAC.ELO,-1 ; Izit valid
	 je	 short ACT_MAP_ERRMAC ; Not this time

; Find COMMAND.COM

	 call	 ACT_MAPCMD	; Find it

; Wipe out our own environment to avoid confusion with TSRs
; which freed their environment but didn't zero the pointer

	 call	 ACT_MAPWIPE	; Free it

; Display DOS line

	 call	 ACT_MAPDOS	; Display it

; Point to next MAC entry (if not the last)

	 call	 ACT_MAPSUB	; Handle via subroutine
	 jc	 short ACT_MAP_ERRMAC ; Something went wrong

	 mov	 ax,POVR_MAC	; Get segment of first MAC entry in high DOS

	 cmp	 ax,-1		; Izit valid?
	 je	 short ACT_MAP_TAIL ; No, skip high DOS memory display

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 lea	 dx,MSG_MIDDLE	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

; Check for orphan LSEG entries

	 call	 CHECK_ORPHAN	; Check on 'em

	 call	 ACT_MAPSUB	; Handle via subroutine
	 jc	 short ACT_MAP_ERRMAC ; Something went wrong
ACT_MAP_TAIL:
	 lea	 dx,MSG_MAPTAIL ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 jmp	 short ACT_MAP_EXIT ; Join common exit code


ACT_MAP_ERRMAC:
;;;;;;;; call	 DISP_ERRMAC	; Display MAC error message

	 lea	 ax,AZS_ERRMAC	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
ACT_MAP_EXIT:
	 REGREST <es,dx,ax>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

ACT_MAP  endp			; End ACT_MAP procedure

ACODE	 ends			; End ACODE segment

	 MEND			; End MAPLOAD module

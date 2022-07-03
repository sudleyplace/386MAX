;' $Header:   P:/PVCS/MAX/386MAX/UTIL_MAP.ASV   1.3   08 Jul 1998 12:30:10   BOB  $
	 title	 UTIL_MAP -- 386MAX Utility Program -- MAP Action
	 page	 58,122
	 name	 UTIL_MAP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Data    segment DATA,	dword-aligned,	public, class 'data'
	       Program segment NCODE,	byte-aligned,	public, class 'ncode'
	       Program segment UCODE,	byte-aligned,	public, class 'ucode'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include INTVEC.INC
	 include DEVDRV.INC
	 include MAC.INC
	 include 386.INC
	 include PTR.INC

	 include QMAX_OEM.INC
.list

if @OEM_MAPMEM
PGROUP	 group	 DATA,NCODE,UCODE


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 QMAX_VER:byte
	 include QMAX_HDM.INC

	 extrn	 P1ST_MAC:dword
	 extrn	 POVR_MAC:word
	 extrn	 MSG_HDR:byte
	 extrn	 MSG_MIDDLE:byte
	 extrn	 MSG_MAPTAIL:byte

DATA	 ends			; End DATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near
	 extrn	 DISP_ERRMAC:near

NCODE	 ends			; End NCODE segment


UCODE	 segment use16 byte public 'ucode' ; Start UCODE segment
	 assume  cs:PGROUP

	 extrn	 ACT_MAPCMD:near
	 extrn	 ACT_MAPWIPE:near
	 extrn	 ACT_MAPDOS:near
	 extrn	 ACT_MAPSUB:near
	 extrn	 CHECK_ORPHAN:near

	 NPPROC  ACT_MAP -- Action To Display Memory Allocation Map
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display memory allocation chain map

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save segment registers

	 lea	 dx,MSG_HDR	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 mov	 es,P1ST_MAC.VSEG ; ES:0 ==> head of MAC
	 assume  es:nothing	; Tell the assembler

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

	 cmp	 HDM_FLAG,@HDM_OPEN ; Izit already opened up?
	 je	 short ACT_MAP_COM ; Yes, thus already displayed above

	 mov	 ax,POVR_MAC	; Get segment of first MAC entry in high DOS

	 cmp	 ax,-1		; Izit valid?
	 je	 short ACT_MAP_COM ; No, skip high DOS memory display

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 lea	 dx,MSG_MIDDLE	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

; Check for orphan LSEG entries

	 call	 CHECK_ORPHAN	; Check on 'em

	 call	 ACT_MAPSUB	; Handle via subroutine
	 jc	 short ACT_MAP_ERRMAC ; Something went wrong
ACT_MAP_COM:
	 lea	 dx,MSG_MAPTAIL ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 clc			; Indicate all went well

	 jmp	 short ACT_MAP_EXIT ; Join common exit code

ACT_MAP_ERRMAC:
	 call	 DISP_ERRMAC	; Display MAC error message
ACT_MAP_ERR:
	 stc			; Indicate something went wrong
ACT_MAP_EXIT:
	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing
	 popa			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_MAP  endp			; End ACT_MAP procedure

UCODE	 ends			; End UCODE segment
endif				; IF @OEM_MAPMEM

	 MEND			; End UTIL_MAP module

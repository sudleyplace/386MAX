;' $Header:   P:/PVCS/MAX/VXD/VMAX_NFG.ASV   1.0   05 Sep 1995 17:21:00   HENRY  $
	 title	 VMAX_NFG -- Cull List -- Program Names Never To Be Instanced
	 page	 78,130
	 name	 VMAX_NFG

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1990-92 Qualitas, Inc.  GNU General Public License version 3.

Environment:  IBM PC, tested under DOS 3.30, 3.31, 4.01, 5.00.

Segmentation:  Group _IGROUP:
	       Program segment _ITEXT,	dword-aligned,	use32,	public, 'ICODE'
	       Data    segment _IDATA,	dword-aligned,	use32,	public, 'ICODE'

	       Group _LGROUP:
	       Program segment _LTEXT,	dword-aligned,	use32,	public, 'CODE'
	       Data    segment _LDATA,	dword-aligned,	use32,	public, 'CODE'

	       Group _PGROUP:
	       Program segment _TEXT,	dword-aligned,	use32,	public, 'PCODE'
	       Data    segment _DATA,	dword-aligned,	use32,	public, 'PCODE'

	       Segment	       _RCODE,	word-aligned,	use16,	public, 'RCODE'

Link requirements:  Final routine should have extension .386 or .VXD.

Program derived from:  None.

Original code by:  William R. Lewis, July, 1990.

Modifications by:  None.

|

.386p
.xlist
	 include VMM.INC	; Fixed version of file from DDK
.list

ASCIZ	 macro	 TXT		; Macro to define ASCIZ strings

	 db	 '&TXT', 0

	 endm			; End ASCIZ macro

VxD_IDATA_SEG			; Begin _IDATA segment

; List of programs to avoid instancing

	 public  CULL_LIST
CULL_LIST label  byte

	 ASCIZ	 API1605.COM	; Self instancing test TSR

	 ASCIZ	 386BOOST.EXE
	 ASCIZ	 CACHE-AT.COM
	 ASCIZ	 CACHE-EM.COM
	 ASCIZ	 CACHE.COM
	 ASCIZ	 CACHE.EXE
	 ASCIZ	 CACHE.SYS
	 ASCIZ	 CACHE3.COM
	 ASCIZ	 CRLOAD.COM
	 ASCIZ	 DCACHE.COM
	 ASCIZ	 DSKBOOST.EXE
	 ASCIZ	 EMMBOOST.EXE
	 ASCIZ	 EMMCACHE.COM
	 ASCIZ	 EXTBOOST.EXE
	 ASCIZ	 FASTC.EXE
	 ASCIZ	 FASTE.EXE
	 ASCIZ	 FASTX.EXE
	 ASCIZ	 FASTX286.EXE
	 ASCIZ	 FASTX386.EXE
	 ASCIZ	 FP3BOOST.EXE
	 ASCIZ	 FPMBOOST.EXE
	 ASCIZ	 FPXBOOST.EXE
	 ASCIZ	 FPYBOOST.EXE
	 ASCIZ	 HYPER286.EXE
	 ASCIZ	 HYPER386.EXE
	 ASCIZ	 HYPERDKC.EXE
	 ASCIZ	 HYPERDKE.EXE
	 ASCIZ	 HYPERDKX.EXE
	 ASCIZ	 IBMCACHE.SYS
	 ASCIZ	 ICACHE.SYS
	 ASCIZ	 MCACH-AT.SYS
	 ASCIZ	 MCACH-EM.SYS
	 ASCIZ	 MCACH.SYS
	 ASCIZ	 NCACHE-F.EXE
	 ASCIZ	 NCACHE-S.EXE
	 ASCIZ	 NOW.EXE
	 ASCIZ	 PC-CACHE.COM
	 ASCIZ	 PCPFAST.EXE
	 ASCIZ	 PCPSMALL.EXE
	 ASCIZ	 QCACHE.EXE
	 ASCIZ	 QSTEP.COM
	 ASCIZ	 SMARTDRV.SYS
	 ASCIZ	 SMARTDRV.EXE
	 ASCIZ	 SUPERPCK.COM

	 db	 0			; Extra NULL terminates list

VxD_IDATA_ENDS				; End _IDATA segment

	 end				; End VMAX_VDD module

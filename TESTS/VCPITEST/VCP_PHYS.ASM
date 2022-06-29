;' $Header:   P:/PVCS/MISC/VCPITEST/VCP_PHYS.ASV   1.1   22 Feb 1994 12:19:32   HENRY  $

	 title	 VCP_PHYS -- VCPI Physical Address Test Routines
	 page	 58,122
	 name	 VCP_PHYS
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-94 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'

Link requirements:  None, standalone subroutine.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC

	 include VCP_TEST.INC
.list


PGROUP	 group	 CODE,DATA


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP


DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:nothing,es:nothing

	 NPPROC  CHECK_PHYS -- Check on Physical Address Mapping
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

Check on VCPI Physical address mapping

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers






	 clc			; Indicate present

	 jmp	 short CHECK_PHYS_EXIT ; Join common exit code

CHECK_PHYS_ERR:
	 stc			; Indicate not present
CHECK_PHYS_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_PHYS endp 		; End CHECK_PHYS procedure

CODE	 ends			; End CODE segment

	 MEND			; End VCP_PHYS module

;' $Header$
;
; (C) Copyright 1999 Qualitas, Inc.  GNU General Public License version 3.
;
; E820.INC
;
; BIOS extended memory call INT 15h, AX=0E820h structures and equates
;

MB_STR	struc

MB_BASE dq	?		; Base address
MB_LEN	dq	?		; Length in bytes
MB_TYPE dd	?		; Memory type (see @MB_xxx below)

MB_STR	ends

@MB_UNK equ	00h		; Unknown memory type
@MB_MEM equ	01h		; Memory, available to OS
@MB_RSV equ	02h		; Reserved, not available (e.g. system ROM, memory-mapped device)
@MB_REC equ	03h		; ACPI Reclaim Memory (usable by OS after reading ACPI tables)
@MB_NVS equ	04h		; ACPI NVS Memory (OS is required to save this memory between NVS sessions)
@MB_MAX equ	06h		; Unknown memory type


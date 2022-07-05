;' $Header:   P:/PVCS/MAX/INC/BUFFERS.INV   1.0   05 Sep 1995 13:27:30   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; BUFFERS.INC
;
; Disk buffer structure for DOS 3.x
;


BUFD3_STR struc 		; Disk buffer structure for DOS 3.x

BUFD3_NEXT dd	 ?		; 00-03:  Ptr to next disk buffer
				;	  Last entry has offset = FFFF
BUFD3_DRIV db	 ?		; 04-04:  Drive # (0=A, 1=B, FF=not in use)
BUFD3_FLAG db	 ?		; 05-05:  Flags
BUFD3_LSN  dw	 ?		; 06-07:  Logical sector #
BUFD3_NCOP db	 ?		; 08-08:  # copies to write (1 for non-FAT entries)
BUFD3_SOFF db	 ?		; 09-09:  Sector offset between copies if NCOP > 1
BUFD3_PDPB dd	 ?		; 0A-0D:  Ptr to Drive Parameter Block
BUFD3_RSVD dw	 ?		; 0E-0F:  (Reserved)

; The buffer data follows for 512 bytes

BUFD3_STR ends



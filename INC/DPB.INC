;' $Header:   P:/PVCS/MAX/INC/DPB.INV   1.0   05 Sep 1995 13:27:32   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; DPB.INC
;
; Drive Parameter Block structures
;

; Drive Parameter Block

DPB_STR  struc			; Drive Parameter Block for all DOS 3+ versions

DPB_DRV  db	 ?		; 00-00 Drive
DPB_UNIT db	 ?		; 01-01 Unit
DPB_BPS  dw	 ?		; 02-03 Bytes per sector
DPB_SPC  db	 ?		; 04-04 Sectors per cluster
DPB_SHF  db	 ?		; 05-05 Shift count (sector to byte modifier)
DPB_NBS  dw	 ?		; 06-07 Boot sectors
DPB_NOF  db	 ?		; 08-08 Number of FATs
DPB_NDE  dw	 ?		; 09-0A Max root directory entries
DPB_FDS  dw	 ?		; 0B-0C First data sector
DPB_MRD  dw	 ?		; 0D-0E Highest cluster number

DPB_STR  ends

DPB3_STR struc			; Drive Parameter Block for DOS 3

	 db	 (size DPB_STR) dup (?) ; Common portion of structure
; Unique to DOS version 3
DPB3_SPF db	 ?		; 0F-0F Sectors per fat
DPB3_FSD dw	 ?		; 10-11 First directory sector
DPB3_DDP dd	 ?		; 12-15 Device driver pointer
DPB3_MD  db	 ?		; 16-16 Media descriptor
DPB3_AF  db	 ?		; 17-17 Access flag
DPB3_DPP dd	 ?		; 18-1B Pointer to next DPB
DPB3_RES dd	 ?		; 1C-1F Reserved

DPB3_STR ends			; End DPB3_STR

DPB4_STR struc			; Drive Parameter Block for DOS 4 and up

	 db	 (size DPB_STR) dup (?) ; Common portion of structure
; Use for DOS version 4 and above
DPB4_SPF dw	 ?		; 0F-10 Sectors per fat
DPB4_FSD dw	 ?		; 11-12 First directory sector
DPB4_DDP dd	 ?		; 13-16 Device driver pointer
DPB4_MD  db	 ?		; 17-17 Media descriptor
DPB4_AF  db	 ?		; 18-18 Access flag (ff if not yet accessed)
DPB4_DPP dd	 ?		; 19-1C Pointer to next DPB

; Documented only for DOS version 5
DPB5_LAC dw	 ?		; 1D-1E Last allocated cluster
DPB5_NFREE dw	 ?		; 1F-20 Number of free clusters

DPB4_STR ends			; End DPB4_STR


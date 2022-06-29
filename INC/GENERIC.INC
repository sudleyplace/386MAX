;' $Header:   P:/PVCS/MAX/INC/GENERIC.INV   1.0   05 Sep 1995 13:27:12   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; GENERIC.INC
;
; Disk drive physical characteristics structures
;

; These structures are used by the DPMI translation services in QMAX_D21.ASM

TIO_STR  struc			; Track input/output structure

TIO_FN	 db	 ?		; Function code
TIO_HEAD dw	 ?		; Head #
TIO_CYL  dw	 ?		; Cylinder #
TIO_SECT dw	 ?		; Sector #
TIO_NSECT dw	 ?		; # sectors
TIO_VEC  dd	 ?		; Transfer address

TIO_STR  ends


BPB_STR  struc			; BPB Structure

BPB_BYT_SECT dw  ?		; # bytes per sector
BPB_SECT_CLUS db ?		; # sectors per cluster
BPB_RSVDSECT dw  ?		; # reserved sectors
BPB_NFAT     db  ?		; # FATs
BPB_NROOT    dw  ?		; Maximum # root entries
BPB_TOTSECT  dw  ?		; Total # sectors
BPB_MEDDESC  db  ?		; Media descriptor byte
BPB_SECT_FAT dw  ?		; # sectors per FAT
BPB_SECT_TRK dw  ?		; # sectors per track
BPB_NHEAD    dw  ?		; # heads
BPB_NHIDDEN  dd  ?		; # hidden sectors
BPB_RSVD1    dd  ?		; Reserved
BPB_RSVD2    db  6 dup (0)	; Reserved

BPB_STR  ends


TRK_STR  struc			; Track layout structure

TRK_COUNT dw	 ?		; Sector count
TRK_SECT dw	 ?		; Sector #
TRK_SIZE dw	 ?		; Sector size

TRK_STR  ends


DP_STR	 struc			; Device Parameter structure

DP_FN	 db	 ?		; Function code
DP_DEVTYPE db	 ?		; Device type
DP_DEVATTR dw	 ?		; Device attributes
DP_NCYLS dw	 ?		; # cylinders
DP_MEDIA db	 ?		; Media type
DP_BPB	 db	 (size BPB_STR) dup (?) ; BPB structure
DP_TRK	 db	 (size TRK_STR) dup (?) ; Track layout structure

DP_STR	 ends


TFV_STR  struc			; Track Format/Verify Structure

TFV_FN	 db	 ?		; Function code
TFV_HEAD dw	 ?		; Head #
TFV_CYL  dw	 ?		; Cylinder #

TFV_STR  ends


AF_STR	 struc			; Access Flag Structure

AF_FN	 db	 ?		; Function code
AF_FLAG  db	 ?		; Access flag

AF_STR	 ends



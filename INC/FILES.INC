;' $Header:   P:/PVCS/MAX/INC/FILES.INV   1.0   05 Sep 1995 13:26:58   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; FILES.INC
;
; File table structures
;

FTAB_STR struc

FTAB_NEXT dd	 ?		; Pointer to next file table
				; Last entry has offset = FFFF
FTAB_CNT  dw	 ?		; # files in this table

FTAB_STR ends


PFTAB3_STR struc		; Per file table structure for DOS 3.x

PFTAB3_NHNDL dw  ?		; 00-01:  # file handles ==> this file
PFTAB3_FMODE dw  ?		; 02-03:  File open mode (bit 15 set if FCB open)
PFTAB3_FATTR db  ?		; 04-04:  File attribute
PFTAB3_DINFO dw  ?		; 05-06:  Device info
PFTAB3_PDPB  dd  ?		; 07-0A:  Chr Dev:  Ptr to device header
				;	  Blk Dev:  Ptr to Drive Parm Block
PFTAB3_ICLUS dw  ?		; 0B-0C:  Starting cluster of file
PFTAB3_FTIME dw  ?		; 0D-0E:  Packed file time
PFTAB3_FDATE dw  ?		; 0F-10:  Packed file date
PFTAB3_FSIZE dd  ?		; 11-14:  File size in bytes
PFTAB3_FPTR  dd  ?		; 15-18:  Current offset in file
PFTAB3_LCLUS dw  ?		; 19-1A:  Relative cluster of last cluster used
PFTAB3_ACLUS dw  ?		; 1B-1C:  Absolute ...
PFTAB3_DCLUS dw  ?		; 1D-1E:  Sector # of directory entry
PFTAB3_DNUM  db  ?		; 1F-1F:  Directory entry # for this file in DCLUS
PFTAB3_FNAME db  11 dup (?)	; 20-2A:  Filename in FCB format
PFTAB3_PSFT  dd  ?		; 2B-2E:  (SHARE) ptr to prev SFT sharing same file
PFTAB3_MACH  dw  ?		; 2F-30:  (SHARE) net machine # with opened file
PFTAB3_OWNR  dw  ?		; 31-32:  PSP seg of file's owner
PFTAB3_SOFF  dw  ?		; 33-34:  (SHARE) Offset within SHARE CS of sharing rec

PFTAB3_STR ends


PFTAB4_STR struc		; Per file table structure for DOS 4.x

PFTAB4_NHNDL dw  ?		; 00-01:  # file handles ==> this file
PFTAB4_FMODE dw  ?		; 02-03:  File open mode (bit 15 set if FCB open)
PFTAB4_FATTR db  ?		; 04-04:  File attribute
PFTAB4_DINFO dw  ?		; 05-06:  Device info
PFTAB4_PDPB  dd  ?		; 07-0A:  Chr Dev:  Ptr to device header
				;	  Blk Dev:  Ptr to Drive Parm Block
PFTAB4_ICLUS dw  ?		; 0B-0C:  Starting cluster of file
PFTAB4_FTIME dw  ?		; 0D-0E:  Packed file time
PFTAB4_FDATE dw  ?		; 0F-10:  Packed file date
PFTAB4_FSIZE dd  ?		; 11-14:  File size in bytes
PFTAB4_FPTR  dd  ?		; 15-18:  Current offset in file
PFTAB4_LCLUS dw  ?		; 19-1A:  Relative cluster of last cluster used
PFTAB4_DCLUS dd  ?		; 1B-1E:  Sector # of directory entry
PFTAB4_DNUM  db  ?		; 1F-1F:  Directory entry # for this file in DCLUS

PFTAB4_FNAME db  11 dup (?)	; 20-2A:  Filename in FCB format
PFTAB4_PSFT  dd  ?		; 2B-2E:  (SHARE) ptr to prev SFT sharing same file
PFTAB4_MACH  dw  ?		; 2F-30:  (SHARE) net machine # with opened file
PFTAB4_OWNR  dw  ?		; 31-32:  PSP seg of file's owner
PFTAB4_SOFF  dw  ?		; 33-34:  (SHARE) Offset within SHARE CS of sharing rec
PFTAB4_ACLUS dw  ?		; 35-36:  Absolute cluster of last cluster used
PFTAB4_PIFS  dd  ?		; 37-3A:  Ptr to IFS driver (0 if none)

PFTAB4_STR ends


@PFTAB_DOS2 equ  0028h		; Size of PFTAB_STR for DOS 2.x
@PFTAB_DOS3 equ  (type PFTAB3_STR) ; ...		    3.x
@PFTAB_DOS4 equ  (type PFTAB4_STR) ; ...		    4.x
@PFTAB_DOS5 equ  (type PFTAB4_STR) ; ...		    5.x (same as 4.x)



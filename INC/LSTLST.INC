;' $Header:   P:/PVCS/MAX/INC/LSTLST.INV   1.0   05 Sep 1995 13:27:22   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; LSTLST.INC
;
; List of Lists structures
;


LSTLST_STR struc

LSTLST_DPB  dd	 ?		; 00-03:  Ptr to first Drive Parameter Block
LSTLST_FTAB dd	 ?		; 04-07:  Ptr to list of file tables
LSTLST_CLK  dd	 ?		; 08-0B:  Ptr to CLOCK$ device driver
LSTLST_CON  dd	 ?		; 0C-0F:  ptr to active CON device driver

LSTLST_STR ends


; DOS 3.x

LSTLST3_STR struc

LSTLST3_DPB dd	 ?		; 00-03:  Ptr to first Drive Parameter Block
LSTLST3_FTAB dd  ?		; 04-07:  Ptr to list of file tables
LSTLST3_CLK  dd  ?		; 08-0B:  Ptr to CLOCK$ device driver
LSTLST3_CON  dd  ?		; 0C-0F:  ptr to active CON device driver

LSTLST3_STR ends


; DOS 4.x

LSTLST4_STR struc

LSTLST4_DPB  dd  ?		; 00-03:  Ptr to first Drive Parameter Block
LSTLST4_FTAB dd  ?		; 04-07:  Ptr to list of file tables
LSTLST4_CLK  dd  ?		; 08-0B:  Ptr to CLOCK$ device driver
LSTLST4_CON  dd  ?		; 0C-0F:  Ptr to active CON device driver
LSTLST4_MAXBLK dw ?		; 10-11:  Maximum bytes/block of any block device
LSTLST4_DBI  dd  ?		; 12-15:  Ptr to disk buffer info
LSTLST4_CDS  dd  ?		; 16-19:  Ptr to array of current directory strucs
LSTLST4_FCB  dd  ?		; 1A-1D:  Ptr to FCB table
LSTLST4_PFCB dw  ?		; 1E-1F:  # protected FCBs (the y in FCBS=x,y)
LSTLST4_NBDEV db ?		; 20-20:  # block devices
LSTLST4_LDRIV db ?		; 21-21:  LASTDRIV value (default 5)
LSTLST4_NUL  db  18 dup (?)	; 22-33:  NUL device header
LSTLST4_JOIN db  ?		; 34-34:  # JOINed drives ???
LSTLST4_SETVER dw ?		; 35-36:  Offset within IBMDOS code of SETVER table
LSTLST4_UTIL dd  ?		; 37-3A:  Ptr to utility functions
LSTLST4_IFS  dd  ?		; 3B-3E:  Ptr to chain of IFS drivers
LSTLST4_BUFX dw  ?		; 3F-40:  The x in BUFFERS x,y
LSTLST4_BUFY dw  ?		; 41-42:  The y in BUFFERS x,y
LSTLST4_BOOT db  ?		; 43-43:  Boot drive (origin-1) (DOS 4+)
	     db  ?		; 44-44:  ???
LSTLST4_EXT  dw  ?		; 45-46:  Extended memory size in 1KB

LSTLST4_STR ends



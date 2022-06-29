;' $Header:   P:/PVCS/MAX/QMT/MEM_SCRN.INV   1.0   05 Sep 1995 16:55:58   HENRY  $
;
; (C) Copyright 1988-98 Qualitas, Inc.	All rights reserved.
;
; MEM_SCRN.INC
;
; Structures and equates for screen-related info.
;

@NROWS	 equ	 25
@NCOLS	 equ	 80

.xcref W_STR
W_STR	 struc

SROW	 dw	 ?		; Starting row
SCOL	 dw	 ?		; ...	   column
NROW	 dw	 ?		; # rows
NCOL	 dw	 ?		; # columns

W_STR	 ends


; ZMSG structure

.xcref ZMSG_STR
ZMSG_STR struc

ZMSG_LEN db	 ?		; Length of the message at XMSG_MSG in bytes
ZMSG_ATTR db	 ?		; Attribute to use
ZMSG_MSG db	 ?		; Start of the message

ZMSG_STR ends


KEYACT	 macro	 KEY,ACT


KEYSEG	 segment use16 word 'data' ; Start KEYSEG segment
	 assume  ds:DGROUP

	 dw	 @KEY_&KEY	; Define the keycode

KEYSEG	 ends			; End KEYSEG segment


ACTSEG	 segment use16 word 'data' ; Start ACTSEG segment
	 assume  ds:DGROUP

	 dw	 PGROUP:ACT	; Define the corresponding action

ACTSEG	 ends			; End ACTSEG segment

	 endm			; End KEYACT macro


MEMLIN_STR struc

	   db	' '
MEMLIN_BEG db	'________-'
MEMLIN_END db	'________      '
MEMLIN_SIZ db	'_'

MEMLIN_STR ends

MEMTOT_STR struc

	   db	'             '
MEMTOT_TOT db	'Total 12345'
MEMTOT_SIZ db	'6'

MEMTOT_STR ends


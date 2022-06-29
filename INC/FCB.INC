;' $Header:   P:/PVCS/MAX/INC/FCB.INV   1.0   05 Sep 1995 13:27:16   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; FCB.INC
;
; File Control Block structures
;

; F I L E   C O N T R O L   B L O C K

.xcref FCB_STR,FCB_DRIV,FCB_FNAM,FCB_FEXT,FCB_BLKN,FCB_LREC,FCB_SIZE
.xcref FCB_DATE,FCB_RELN,FCB_RAND
FCB_STR  struc		; File Control Block for DOS 1.1 and 2.0

FCB_DRIV db	 ?	; Drive number (0=default, 1=A, etc.)	      0
FCB_FNAM db	 'filename' ; File name                               1
FCB_FEXT db	 'ext'  ; File extension                              9
FCB_BLKN dw	 ?	; Current block number			     12
FCB_LREC dw	 80h	; Logical record size			     14
FCB_SIZE dd	 ?	; File size				     16
FCB_DATE dw	 ?	; Last change date (Y:7,M:4,D:5), 1980 base  20
	 db	 6 dup (?) ; Reserved for system use		     22
FCB_SEG  dw	 ?	; Segment of device driver		     28
	 db	 2 dup (?) ; Reserved for system use		     30
FCB_RELN db	 0	; Current relative record number in block    32
FCB_RAND dd	 ?	; Random relative record number 	     33
;								     36
FCB_STR  ends

.xcref FCB_SIZE_LO,FCB_SIZE_HI,FCB_RENM,FCB_RAND_LO,FCB_RAND_HI
FCB_SIZE_LO equ  word ptr FCB_SIZE ; High- and low-order portions
FCB_SIZE_HI equ  word ptr FCB_SIZE+2

FCB_RENM equ	 FCB_SIZE_LO+1	; FCB area for file renaming
FCB_RAND_LO equ  word ptr FCB_RAND ; High- and low-order portions
FCB_RAND_HI equ  word ptr FCB_RAND+2


; E X T E N D E D   F I L E   C O N T R O L   B L O C K

.xcref XFCB_STR,XFCB_PREF,XFCB_ATTR,XFCB_DRIV,XFCB_FNAM,XFCB_FEXT,XFCB_BLKN
.xcref XFCB_LREC,XFCB_SIZE,XFCB_DATE,XFCB_RELN,XFCB_RAND
XFCB_STR struc		; Extended File Control Block for DOS  2.x

XFCB_PREF db	 0FFh,5 dup (?) ; Extended FCB marker -- rsvd fields	0
XFCB_ATTR db	 ?	; Attribute - see DIR_ATTR_... for definitions	6
XFCB_DRIV db	 ?	; Drive number (0=default, 1=A, etc.)		7
XFCB_FNAM db	 'filename' ; File name                                 8
XFCB_FEXT db	 'ext'  ; File extension                               16
XFCB_BLKN dw	 ?	; Current block number			       19
XFCB_LREC dw	 ?	; Logical record size			       21
XFCB_SIZE dd	 ?	; File size				       23
XFCB_DATE dw	 ?	; Last change date (Y:7,M:4,D:5), 1980 base    27
	 db	 10 dup (?) ; Reserved for system use		       29
XFCB_RELN db	 ?	; Current relative record number in block      39
XFCB_RAND dd	 ?	; Random relative record number 	       40
;								       43
XFCB_STR  ends

.xcref XFCB_SIZE_LO,XFCB_SIZE_HI,XFCB_RENM,XFCB_RAND_LO,XFCB_RAND_HI
XFCB_SIZE_LO equ  word ptr XFCB_SIZE ; High- and low-order portions
XFCB_SIZE_HI equ  word ptr XFCB_SIZE+2

XFCB_RENM equ	 XFCB_SIZE_LO+1 ; FCB area for file renaming
XFCB_RAND_LO equ  word ptr XFCB_RAND ; High- and low-order portions
XFCB_RAND_HI equ  word ptr XFCB_RAND+2


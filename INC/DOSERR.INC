;' $Header:   P:/PVCS/MAX/INC/DOSERR.INV   1.0   05 Sep 1995 13:27:04   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; DOSERR.INC
;
; DOS function error codes
;

; Equates for DOS call errors

@DOSERR_XFN	 equ	1	; Invalid function number
@DOSERR_FNF	 equ	2	; File not found
@DOSERR_PNF	 equ	3	; Path not found
@DOSERR_XHNDL	 equ	4	; No handles remain
@DOSERR_XACC	 equ	5	; Access denied
@DOSERR_HNF	 equ	6	; Handle not found
@DOSERR_XMAC	 equ	7	; Memory allocation chain destroyed
@DOSERR_XMEM	 equ	8	; Insufficient memory
@DOSERR_MNF	 equ	9	; MAC not found


; Equates for Critical Error handlers (INT 24h)

@INT24_IGNORE equ  0	; Ignore the error
@INT24_RETRY  equ  1	; Retry the operation
@INT24_ABORT  equ  2	; Abort the prorgam
@INT24_FAIL   equ  3	; Fail the operation
@INT24_REFLVM equ  -1	; Reflect the error to VM

COMMENT|

For Critical Errors, AH contains a bit record whose values
and meanings are defined as follows:

$I24_CHAR	 Bit 7	1=Error occurred on character device or was the
			    result of a bad memory image of the FAT on a
			    block device.
			0=Error occurred on block device
$I24_RSVD	     6	(Reserved)
$I24_IGNORE	     5	1=Ignore allowed
			0=not
$I24_RETRY	     4	1=Retry allowed
			0=not
$I24_FAIL	     3	1=Fail allowed
			0=not
$I24_DISKAREA	     1-2  Affected disk area
			  00=DOS area
			  01=FAT
			  10=Directory
			  11=Data area
$I24_WRITE	     0	1=Error occurred during a write operation
			0=..			  read

|

I24_REC  record  $I24_CHAR:1,	  \
		 $I24_RSVD:1,	  \
		 $I24_IGNORE:1,   \
		 $I24_RETRY:1,	  \
		 $I24_FAIL:1,	  \
		 $I24_DISKAREA:2, \
		 $I24_WRITE:1


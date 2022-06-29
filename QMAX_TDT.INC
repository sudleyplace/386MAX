;' $Header:   P:/PVCS/MAX/386MAX/QMAX_TDT.INV   1.0   11 Aug 1995 10:55:46   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; QMAX_TDT.INC
;
; Extended Descriptor Table Entry structure for timings
;

TDTE_STR struc

TDTE_DUMMY dq	 ?		; 00:  First entry not accessible
TDTE_GDT  dq	 ?		; 08:  Global descriptor table
TDTE_IDT  dq	 ?		; 10:  Interrupt ...
TDTE_DS   dq	 ?		; 18:  DS ...
TDTE_ES   dq	 ?		; 20:  ES ... (used for high memory)
TDTE_SS   dq	 ?		; 28:  SS ...
TDTE_CS   dq	 ?		; 30:  CS ...
TDTE_BIOS dq	 ?		; 38:  Temporary BIOS ...
TDTE_D4GB dq	 ?		; 40:  4GB descriptor as data
;;;;_VID  dq	 ?		;   :  Video buffer descriptor
;;;;_PDT  dq	 ?		;   :  Page Descriptor Table
TDTE_LOAD dq	 (3*1) dup (?)	; 48:  Linear address of file loads
				; The 1st DTE is the code segment
				; The 2nd DTE is the data segment
				; The 3rd DTE is available (LDT?)
TDTE_STR ends


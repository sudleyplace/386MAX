;' $Header:   P:/PVCS/MAX/INC/OMF.INV   1.0   05 Sep 1995 13:27:46   HENRY  $
;
; (C) Copyright 1994-5 Qualitas, Inc.  All rights reserved.
;
; OMF.INC
;
; Object Module Format types in .OBJ and .LIB files
; * = ignored
; + = has 32-bit definition

@OMF1ST  equ	 06Eh		; The first valid OMF record

@OMF_RHEADR  equ 06Eh		; * R-module header record
@OMF_REGINT  equ 070h		; * Register initialization record
@OMF_REDATA  equ 072h		; * Relocatable enumerated data record
@OMF_RIDATA  equ 074h		; * Relocatable iterated data record
@OMF_OVLDEF  equ 076h		; * Overlay definition record
@OMF_ENDREC  equ 078h		; * End record
@OMF_BLKDEF  equ 07Ah		; * Block definition record
@OMF_BLKEND  equ 07Ch		; * Block end record
@OMF_DEBSYM  equ 07Eh		; * Debug symbols record
@OMF_THEADR  equ 080h		;   Translator header record
@OMF_LHEADR  equ 082h		;   Library module header record
@OMF_PEDATA  equ 084h		; * Physical enumerated data record
@OMF_PIDATA  equ 086h		; * Physical iterated data record
@OMF_COMENT  equ 088h		;   Comment record
@OMF_MODEND  equ 08Ah		; + Module end record
@OMF_EXTDEF  equ 08Ch		;   External names definition record
@OMF_TYPDEF  equ 08Eh		;   Type definition record
@OMF_PUBDEF  equ 090h		; + Public names definition record
@OMF_LOCSYM  equ 092h		; * Local symbols record
@OMF_LINNUM  equ 094h		; + Line numbers record
@OMF_LNAMES  equ 096h		;   List of names record
@OMF_SEGDEF  equ 098h		; + Segment definition record
@OMF_GRPDEF  equ 09Ah		;   Group definition record
@OMF_FIXUPP  equ 09Ch		; + Fixup record
@OMF_IGNORE  equ 09Eh		; * Undefined record
@OMF_LEDATA  equ 0A0h		; + Logical enumerated data record
@OMF_LIDATA  equ 0A2h		; + Logical iterated data record
@OMF_LIBHED  equ 0A4h		; * Library header record
@OMF_LIBNAM  equ 0A6h		; * Library module names record
@OMF_LIBLOC  equ 0A8h		; * Library module locations record
@OMF_LIBDIC  equ 0AAh		; * Library dictionary record
;;;;	     equ 0ACh		; * Reserved
;;;;	     equ 0AEh		; * Reserved
@OMF_COMDEF  equ 0B0h		;   Communal names definition record
@OMF_BAKPAT  equ 0B2h		; + Backpatch record
@OMF_LEXTDEF equ 0B4h		; + Local external names definition record
@OMF_LPUBDEF equ 0B6h		; + Local public names definition record
@OMF_LCOMDEF equ 0B8h		;   Local communal names definition record
@OMF_COMFIX  equ 0BAh		; + Communal fixup record
@OMF_CEXTDEF equ 0BCh		;   COMDAT external names definition record
;;;;	     equ 0BEh		; * Reserved
@OMF_SELDEF  equ 0C0h		;   Selector definition record (never implemented)
@OMF_COMDAT  equ 0C2h		; + Initialized communal data record
@OMF_LINSYM  equ 0C4h		; + Symbol line numbers record
@OMF_ALIAS   equ 0C6h		;   Alias definition record
@OMF_NBKPAT  equ 0C8h		; + Named backpatch record
@OMF_LLNAMES equ 0CAh		;   Local logical names definition record

@OMFLAST equ	 0CAh		; The last valid OMF record


; The following two types occur in .LIB files, not .OBJ files

@OMF_LIBHDR  equ 0F0h		;   Library header record
@OMF_LIBEND  equ 0F1h		;   Library end record
@OMF_LIBEXT  equ 0F2h		;   Library extended dictionary


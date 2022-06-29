;' $Header:   P:/PVCS/MAX/INSTALL/ZZTAIL.ASV   1.1   30 May 1997 11:27:44   BOB  $
	 title	 ZZTAIL -- Segment definitions to put data at end of file
	 page	 58,122
	 name	 zztail

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1985-97 Qualitas, Inc.  All rights reserved.

Segmentation:  C run-time library definitions contained in llibca!c0.asm

Link requirements:  None, standalone subroutine.

Program derived from:  None.

Original code by:  Henry Groover, August 1991.

|

.286p
.xlist
include MASM.INC
.list

DGROUP	 group	 _DATA,XIQC,STACK,DBDATA,CDATA,zztail

; Define all the run-time library segments empty so we can put ZZTAIL at the end

_DATA		segment word public	'DATA'
_DATA		ends

XIQC		segment word common	'DATA'
XIQC		ends

DBDATA		segment word common	'DATA'
DBDATA		ends

CDATA		segment word common	'DATA'
COMMENT|

The Microsoft C compiler seems to depend on a linker idiosyncrasy that
USUALLY puts 0's in this segment when no floating point code/data is
linked in.  When the right combination of circumstances conspire to
eliminate that idiosyncrasy, the compiled program will hang before
reaching _main.

__fpinit is declared in this segment in the CRT0DAT.ASM module,
with combine type common.  This will result in it overlaying another
CDATA with combine type common; a trick to determine at link time
how data gets initialized.  This segment will overlay __fpinit and
initialize it to 0, thus ensuring that the startup code does not
attempt to make a far call to some meaningless value in __fpinit.

Thanks again, Microsoft.

|
	dw	0		; Skip over 'dw 0' in crt0dat.asm
	dd	0		; Initialize __fpinit to 0
CDATA		ends

; These segments don't seem to need to be declared here
COMMENT |

XIFB		segment word public	'DATA'
XIFB		ends
XIF		segment word public	'DATA'
XIF		ends
XIFE		segment word public	'DATA'
XIFE		ends
XIB		segment word public	'DATA'
XIB		ends
XI		segment word public	'DATA'
XI		ends
XIE		segment word public	'DATA'
XIE		ends
XPB		segment word public	'DATA'
XPB		ends
XP		segment word public	'DATA'
XP		ends
XPE		segment word public	'DATA'
XPE		ends
XCB		segment word public	'DATA'
XCB		ends
XC		segment word public	'DATA'
XC		ends
XCE		segment word public	'DATA'
XCE		ends
XCFB		segment word public	'DATA'
XCFB		ends
XCF		segment word public	'DATA'
XCF		ends
XCFE		segment word public	'DATA'
XCFE		ends
EXEC		segment word public	'DATA'
EXEC		ends
CONST		segment word public	'CONST'
CONST		ends
|

; These initialized data segments need to be declared before zztail

HDR		segment word public	'MSG'
HDR		ends
MSG		segment word public	'MSG'
MSG		ends
PAD		segment word public	'MSG'
PAD		ends
EPAD		segment word public	'MSG'
EPAD		ends

; A segment name which should come AFTER all other MSG class segments.
; Note that the /Ml option MUST be used with MASM 5.1, the /Cp option
; with MASM 6.0.
zztail		segment word public	'MSG'
zztail		ends

COMMENT |
; We don't care about the BSS class segments; let'em fall as they will.
; With the exception of c_common, they are all uninitialized data and are
; not included in the file.
_BSS		segment word public	'BSS'
_BSS		ends
XOB		segment word public	'BSS'
XOB		ends
XO		segment word public	'BSS'
XO		ends
XOE		segment word public	'BSS'
XOE		ends
c_common	segment word public	'BSS'
c_common	ends
|

; We don't want to come after the stack segment, since this is not initializable
; data and is therefore not contained in the file.
STACK		segment para public	'STACK'
STACK		ends

_DATA	 segment		; Start _DATA segment
extrn	 _security_pattern:byte
_DATA	 ends

zztail	 segment		; Start zztail segment
	 assume ds:DGROUP

	 public  PIDENT
PIDENT	 dd	 DGROUP:_security_pattern ; Identification string offset

	 public  ZTAIL
ZTAIL	 label	 byte

zztail	 ends

	 MEND


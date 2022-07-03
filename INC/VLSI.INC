;' $Header:   P:/PVCS/MAX/INC/VLSI.INV   1.0   05 Sep 1995 13:27:44   HENRY  $
;
; (C) Copyright 1993 Qualitas, Inc.  GNU General Public License version 3.
;
; VLSI.INC
;
; VLSI 82C48x chipset command/data register equates and records
;

@VLSI_CMD equ	 0ECh		; VLSI chipset command I/O port
@VLSI_DAT equ	 0EDh		; ...	       data    ...

@VLSI_MISCSET equ 07h		; Miscellaneous control register
VLSIREC07 record $VLSI_SEGCEN:1,  \
		 $VLSI_TAG8:1,	  \
		 $VLSI_CWETIME:1, \
		 $VLSI_FASTRC:1,  \
		 $VLSI_CEN:1,	  \
		 $VLSI_ENPAR:1,   \
		 $VLSI_CWS_OFF:1, \
		 $VLSI_CACHCKCTL:1

@VLSI_CACHCTL equ 19h		; Cache control I/O port
VLSIREC19 record $VLSI_DBLBANK:1, \
		 $VLSI_ZWSW:1,	  \
		 $VLSI_TSIZE9:1,  \
		 $VLSI_VEN:1,	  \
		 $VLSI_DTYDIS:1,  \
		 $VLSI_CSIZE:3


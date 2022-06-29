;' $Header:   P:/PVCS/MAX/QMT/MEM_HTXT.ASV   1.0   05 Sep 1995 16:55:48   HENRY  $
	 title	 MEM_HTXT -- MEMCHK Help Text
	 page	 58,122
	 name	 MEM_HTXT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.

Segmentation:  See MEM_SEG.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC

	 include MEM_SCRN.INC
	include MEM_SEG.INC
.list

DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 @HTXT_SROW:abs
	 extrn	 @HTXT_SCOL:abs
	 extrn	 @HTXT_NCOL:abs

	 extrn	 @HNAV_NROW:abs
	 extrn	 @HOVR_NROW:abs
	 extrn	 @HTST_NROW:abs
	 extrn	 @HERR_NROW:abs
	 extrn	 @HCMD_NROW:abs

	 extrn	 @HMEM_NROW:abs
	 extrn	 @HNMI_NROW:abs
	 extrn	 @HNMIX_NROW:abs
	 extrn	 HELP_NAVTTL:byte
	 extrn	 HELP_OVRTTL:byte
	 extrn	 HELP_TSTTTL:byte
	 extrn	 HELP_ERRTTL:byte
	 extrn	 HELP_CMDTTL:byte
	 extrn	 HELP_MEMTTL:byte
	 extrn	 HELP_NMITTL:byte
	 extrn	 HELP_NMIXTTL:byte

	 public  ARR_W_HTOP
ARR_W_HTOP W_STR <@HTXT_SROW, @HTXT_SCOL, @HNAV_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HOVR_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HTST_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HERR_NROW, @HTXT_NCOL>
	 public  ARR_W_HCMD
ARR_W_HCMD label tbyte
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HCMD_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HMEM_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HNMI_NROW, @HTXT_NCOL>
	 W_STR	 <@HTXT_SROW, @HTXT_SCOL, @HNMIX_NROW,@HTXT_NCOL>

	 public  PHTOPTTL
PHTOPTTL dw	 DGROUP:HELP_NAVTTL	; Ptrs to help topic titles
	 dw	 DGROUP:HELP_OVRTTL
	 dw	 DGROUP:HELP_TSTTTL
	 dw	 DGROUP:HELP_ERRTTL
	 dw	 DGROUP:HELP_CMDTTL
	 dw	 DGROUP:HELP_MEMTTL
	 dw	 DGROUP:HELP_NMITTL
	 dw	 DGROUP:HELP_NMIXTTL

DATA	 ends			; End DATA segment

	 MEND			; End MEM_HTXT module

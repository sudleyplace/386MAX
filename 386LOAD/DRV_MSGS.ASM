;' $Header:   P:/PVCS/MAX/386LOAD/DRV_MSGS.ASV   1.1   30 May 1997 10:38:04   BOB  $
	 title	 DRV_MSGS -- 386LOAD/MOVE'EM Message Text
	 page	 58,122
	 name	 DRV_MSGS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment NDATA, dword-aligned, public, class 'ndata'

Link requirements:  Final routine should have extension .SYS.

Program derived from:  None.

Original code by:  Bob Smith, February 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include ASCII.INC

	 include LOAD_OEM.INC
.list


PGROUP	 group	 NDATA


NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 public  AZS_ARGS
if @OEM_FLEX
ifdef LANG_GR
AZS_ARGS db	 BEL,'ÍÍ> ungltige Argumente, gltig sind: DISPLAY, FLEXFRAME, GETSIZE,',CR,LF
else
AZS_ARGS db	 BEL,'ÍÍ> Invalid argument list -- use DISPLAY, FLEXFRAME, GETSIZE,',CR,LF
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
AZS_ARGS db	 BEL,'ÍÍ> ungltige Argumente, gltig sind: DISPLAY, GETSIZE,',CR,LF
else
AZS_ARGS db	 BEL,'ÍÍ> Invalid argument list -- use DISPLAY, GETSIZE,',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_FLEX
if @OEM_SYS eq @OEMSYS_3COM
ifdef LANG_GR
	 db	     '    GROUP=1 bis 9, PAUSE, PRGREG=1 bis 9, QUIET, SIZE=nnnnnn, oder',CR,LF
else
	 db	     '    GROUP=1 to 9, PAUSE, PRGREG=1 to 9, QUIET, SIZE=nnnnnn, or',CR,LF
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
	 db	     '    GROUP=1 bis 9, NOPAUSE, PRGREG=1 bis 9, QUIET, VERBOSE, SIZE=nnnnnn, oder',CR,LF
else
	 db	     '    GROUP=1 to 9, NOPAUSE, PRGREG=1 to 9, QUIET, VERBOSE, SIZE=nnnnnn, or',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_3COM
ifdef LANG_GR
	 db	     '    PROG=lw:\pfad\dateiname.erw argumente',CR,LF,0
else
	 db	     '    PROG=d:\path\filename.ext arguments',CR,LF,0
endif				; IFDEF LANG_GR

;;;if @OEM_SYS eq @OEMSYS_3COM
;;;	    public  MSG_NO3COM
;;;MSG_NO3COM db    BEL,'ÍÍ> This driver can be installed in conjunction with 3COM only.',CR,LF,EOS
;;;endif			   ; IF @OEM_SYS eq @OEMSYS_3COM

NDATA	 ends			; End NDATA segment

	 MEND			; End DRV_MSGS module

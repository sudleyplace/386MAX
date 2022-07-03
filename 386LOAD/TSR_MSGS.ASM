;' $Header:   P:/PVCS/MAX/386LOAD/TSR_MSGS.ASV   1.1   30 May 1997 10:38:14   BOB  $
	 title	 TSR_MSGS -- 386LOAD/MOVE'EM TSR Message Text
	 page	 58,122
	 name	 TSR_MSGS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'

Link requirements:  Final routine should have extension .SYS.

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include ASCII.INC

	 include LOAD_OEM.INC
.list

PGROUP	 group	 NDATA,ADATA


ADATA	 segment dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP

	 public  AZS_ARGS
if @OEM_FLEX
ifdef LANG_GR
AZS_ARGS db	 BEL,'ÕÕ> ungÅltige Argumente gefunden -- ,',CR,LF
	 db	     '    verwenden Sie DISPLAY, ENVREG=1 bis 9, ENVSAVE, FLEXFRAME,',CR,LF
else
AZS_ARGS db	 BEL,'ÕÕ> Invalid argument list -- use DISPLAY, ENVREG=1 to 9, ENVSAVE, FLEXFRAME,',CR,LF
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
AZS_ARGS db	 BEL,'ÕÕ> ungÅltige Argumente gefunden -- ,',CR,LF
	 db	     '    verwenden Sie DISPLAY, ENVREG=1 bis 9, ENVSAVE,',CR,LF
else
AZS_ARGS db	 BEL,'ÕÕ> Invalid argument list -- use DISPLAY, ENVREG=1 to 9, ENVSAVE,',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_FLEX
if @OEM_SYS eq @OEMSYS_3COM
ifdef LANG_GR
	 db	     '    GETSIZE, GROUP=1 bis 9, MAPDEV, MAPMEM, PAUSE, PRGREG=1 bis 9,',CR,LF
else
	 db	     '    GETSIZE, GROUP=1 to 9, MAPDEV, MAPMEM, NORETRY, PAUSE, PRGREG=1 to 9,',CR,LF
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
	 db	     '    GETSIZE, GROUP=1 bis 9, MAPDEV, MAPMEM, NOPAUSE, PRGREG=1 bis 9,',CR,LF
else
	 db	     '    GETSIZE, GROUP=1 to 9, MAPDEV, MAPMEM, NOPAUSE, NORETRY, PRGREG=1 to 9,',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_3COM
ifdef LANG_GR
	 db	     '    QUIET, SIZE=nnnnnn, SUMMARY, VERBOSE ',CR,LF
	 db	     '    oder PROG=lw:\pfad\dateiname.erw argumente',CR,LF,0
else
	 db	     '    QUIET, SIZE=nnnnnn, SUMMARY, VERBOSE,',CR,LF
	 db	     '    or PROG=d:\path\filename.ext arguments',CR,LF,0
endif				; IFDEF LANG_GR

	 public  AZS_XENV
ifdef LANG_GR
AZS_XENV db	 BEL,'ÕÕ> ungÅltige Umgebung.',CR,LF,0
else
AZS_XENV db	 BEL,'ÕÕ> Invalid environment.',CR,LF,0
endif				; IFDEF LANG_GR

	 public  MSG_NOT386,MSG_NOT386_LEN
ifdef LANG_GR
MSG_NOT386 db	 BEL,'ÕÕ> falscher Maschinentyp,',CR,LF
	 db	     '    benîtige einen 80386.',CR,LF
else
MSG_NOT386 db	 BEL,'ÕÕ> Wrong machine type',CR,LF
	 db	     '    Must run on an 80386.',CR,LF
endif				; IFDEF LANG_GR
MSG_NOT386_LEN equ $-MSG_NOT386

	 public  AZS_LOWFAIL
ifdef LANG_GR
AZS_LOWFAIL db	 BEL,'ÕÕ> kann nicht laden - kein Platz in LoDOS oder HiDOS.',CR,LF,0
else
AZS_LOWFAIL db	 BEL,'ÕÕ> Unable to load - no room in low or high memory.',CR,LF,0
endif				; IFDEF LANG_GR

ADATA	 ends			; End ADATA segment


NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 public  AZS_XRES
ifdef LANG_GR
AZS_XRES db	 BEL,'ÕÕ> Programm ohne residente Speicheranforderung beendet.',CR,LF,0
else
AZS_XRES db	 BEL,'ÕÕ> Program terminated without resident request.',CR,LF,0
endif				; IFDEF LANG_GR

	 public  AZS_UGHMAC
ifdef LANG_GR
AZS_UGHMAC db	 BEL,'ÕÕ> Fehler in der Speicher-Zuordnungskette nach Installation.',CR,LF
	 db	     '    Bitte starten Sie neu OHNE Speicherverwalter und',CR,LF
	 db	     '    entfernen Sie ',@OEM_LOAD,' aus obiger Zeile.',CR,LF,0
else
AZS_UGHMAC db	 BEL,'ÕÕ> Memory allocation chain error after installation.',CR,LF
	 db	     '    Reboot without memory manager and remove ',@OEM_LOAD,' from the above line.',CR,LF,0
endif				; IFDEF LANG_GR

	 public  HELP_TEXT,HELP_LEN
HELP_TEXT label byte
ifdef LANG_GR
	db	CR,LF,'LÑdt TSR Programme in HiDOS und zeigt Status residenter Programme',CR,LF
	db	CR,LF
	db	' ', @OEM_LOAD,' [Schalter]',CR,LF
	db	CR,LF
	db	'  MAPDEV   (/D)    zeigt Speicherbelegung der Einheiten-Treiber im LoDOS',CR,LF
	db	'  MAPMEM   (/M)    zeigt Info Åber geladene residente Programme',CR,LF
	db	'  SUMMARY  (/S)    zeigt Lade-Verhalten der residenten Programme',CR,LF
	db	CR,LF
else
	db	CR,LF,'Load TSR programs high and display status of resident programs',CR,LF
	db	CR,LF
	db	' ', @OEM_LOAD,' [switches]',CR,LF
	db	CR,LF
	db	'  MAPDEV   (/D)    Display memory map of device drivers in low DOS',CR,LF
	db	'  MAPMEM   (/M)    Display resident program loading information',CR,LF
	db	'  SUMMARY  (/S)    Display summary information on resident programs',CR,LF
	db	CR,LF
endif				; IFDEF LANG_GR

HELP_LEN equ	$-HELP_TEXT

NDATA	 ends			; End NDATA segment

	 MEND			; End TSR_MSGS module

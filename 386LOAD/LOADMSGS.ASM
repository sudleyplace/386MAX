;' $Header:   P:/PVCS/MAX/386LOAD/LOADMSGS.ASV   1.3   30 May 1997 10:38:06   BOB  $
	 title	 LOADMSGS -- 386MAX/MOVE'EM Common Message Text
	 page	 58,122
	 name	 LOADMSGS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment ADATA,	dword-aligned, public, class 'zdata'

Program derived from:  None.

Original code by:  Bob Smith, February 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include VERSION.INC

	 include LOAD_OEM.INC
if @OEM_BETA
	 include VERSBETA.INC
endif				; IF @OEM_BETA
.list

	 extrn	 VERSLTR1:abs	; 'a' or ' '

PGROUP	 group	 NDATA,ADATA


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 public  AZS_ERRMAC,AZS_LOADLO,AZS_NOLOAD,AZS_XHILOAD
ifdef LANG_GR
AZS_ERRMAC db	 BEL,'ÍÍ> Fehler in Speicher-Zuordnungskette.',CR,LF,0
AZS_LOADLO db	 BEL,'ÍÍ> Lade-Fehler -- installiere im LoDOS...',CR,LF,0
AZS_NOLOAD db	 BEL,'ÍÍ> Lade-Fehler -- nicht installiert.',CR,LF,0
AZS_XHILOAD db	 BEL,'ÍÍ> Diese Datei muá bei Vorhandensein einer BUSMASTER-Einheit geladen',CR,LF
	 db	     '    werden. Siehe README-Datei bei BUSMASTER-Einheiten wegen weiterer',CR,LF
	 db	     '    Informationen.',CR,LF,0
else
AZS_ERRMAC db	 BEL,'ÍÍ> Memory allocation chain error.',CR,LF,0
AZS_LOADLO db	 BEL,'ÍÍ> Load failed -- installing in low memory...',CR,LF,0
AZS_NOLOAD db	 BEL,'ÍÍ> Load failed -- not installed.',CR,LF,0
AZS_XHILOAD db	 BEL,'ÍÍ> This file must be loaded low when a Busmaster device is present.',CR,LF
	 db	     '    Consult the "Busmastering Devices" section of the README file for',CR,LF
	 db	     '    more information.',CR,LF,0
endif				; IFDEF LANG_GR

	 public  AZS_SIZELO,AZS_PRESS
ifdef LANG_GR
AZS_SIZELO db	     'ÍÍ> Programm zur automatischen Gr”áenermittlung in LoDOS geladen.',CR,LF,0
AZS_PRESS  db	     '    weiter mit beliebiger Taste...',CR,LF,0
else
AZS_SIZELO db	     'ÍÍ> Program loaded in LOW DOS memory for automatic size determination.',CR,LF,0
AZS_PRESS  db	     '    Press any key to continue.',CR,LF,0
endif				; IFDEF LANG_GR

	 public  AZS_XMAXLOW
ifdef LANG_GR
AZS_XMAXLOW db	 'ÍÍ> installiere im LoDOS.',CR,LF,0
else
AZS_XMAXLOW db	 'ÍÍ> Installing in low memory.',CR,LF,0
endif				; IFDEF LANG_GR

if @OEM_WIN3
	 public  AZS_WINERR
ifdef LANG_GR
AZS_WINERR db	 BEL,'ÍÍ> kann VxD Einsprungspunkt nicht erhalten...',CR,LF,0
else
AZS_WINERR db	 BEL,'ÍÍ> Unable to get VxD entry point...',CR,LF,0
endif				; IFDEF LANG_GR
endif				; IF @OEM_WIN3

if @OEM_PROD eq @OEMPROD_LOAD

	 public  MSG_COPY
MSG_COPY db	 CR,LF,@OEM_LOAD
	 db	 (MSG_COPY+11-$) dup (' ')      ; Fill out with blanks
	 db	 '-- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
if @OEM_BETA
	 db	 '.',BETA_H,BETA_T,BETA_U,'á'
else
	 db	 VERSLTR1	; This will normally add an extra space
endif				; IF @OEM_BETA
ifdef LANG_GR
	 db	 ' --  Ein Programm-Lader fr ',@OEM_PTEXT,CR,LF
else
	 db	 ' --  A Program Loader for ',@OEM_PTEXT,CR,LF
endif				; IFDEF LANG_GR
	 db	 '   (C) Copyright 1988-96 Qualitas, Inc.'
ifdef LANG_GR
	 db	 '  Alle Rechte vorbehalten.',CR,LF,EOS
else
	 db	 '  All rights reserved.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  AZS_XVER,AZS_NOTPRES
ifdef LANG_GR
AZS_XVER db	 BEL,'ÍÍ> Dieses Programm erfordert ',@OEM_PTEXT,' Version 5.00 oder h”her.',CR,LF,0
AZS_NOTPRES db	 BEL,'ÍÍ> ',@OEM_BASE,'.SYS-Einheiten-Treiber nicht geladen von CONFIG.SYS.',CR,LF,0
else
AZS_XVER db	 BEL,'ÍÍ> This program requires ',@OEM_PTEXT,' Version 5.00 or later.',CR,LF,0
AZS_NOTPRES db	 BEL,'ÍÍ> ',@OEM_BASE,'.SYS device driver not loaded from CONFIG.SYS.',CR,LF,0
endif				; IFDEF LANG_GR

elseif @OEM_PROD eq @OEMPROD_MOVE

	 public  MSG_COPY
MSG_COPY db	 CR,LF,@OEM_LOAD
	 db	 (MSG_COPY+11-$) dup (' ')      ; Fill out with blanks
	 db	 '-- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
if @OEM_BETA
	 db	 '.',BETA_H,BETA_T,BETA_U,'á'
endif				; IF @OEM_BETA
ifdef LANG_GR
	 db	 ' -- Ein Programm-Lader fr PCs',CR,LF
else
	 db	 ' -- A Program Loader for PCs',CR,LF
endif				; IFDEF LANG_GR
	 db	 '   (C) Copyright 1988-96 Qualitas, Inc.'
ifdef LANG_GR
	 db	 '  Alle Rechte vorbehalten.',CR,LF,EOS
else
	 db	 '  All rights reserved.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  AZS_XVER,AZS_NOTPRES
ifdef LANG_GR
AZS_XVER db	 BEL,'ÍÍ> falsche Version des ',@OEM_BASE,'.MGR wurde installiert.',CR,LF,0
AZS_NOTPRES db	 BEL,'ÍÍ> ',@OEM_BASE,'.MGR-Einheiten-Treiber nicht geladen von CONFIG.SYS.',CR,LF,0
else
AZS_XVER db	 BEL,'ÍÍ> Incorrect version of ',@OEM_BASE,'.MGR installed.',CR,LF,0
AZS_NOTPRES db	 BEL,'ÍÍ> ',@OEM_BASE,'.MGR device driver not loaded from CONFIG.SYS.',CR,LF,0
endif				; IFDEF LANG_GR

elseif @OEM_PROD eq @OEMPROD_SIMU

	 public  MSG_COPY
MSG_COPY db	 CR,LF,@OEM_LOAD
	 db	 (MSG_COPY+11-$) dup (' ')      ; Fill out with blanks
	 db	 '-- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
if @OEM_BETA
	 db	 '.',BETA_H,BETA_T,BETA_U,'á'
endif				; IF @OEM_BETA
ifdef LANG_GR
	 db	 ' -- Ein Programm-Lader fr SIMULTASK',CR,LF
else
	 db	 ' -- A Program Loader for SIMULTASK',CR,LF
endif				; IFDEF LANG_GR
	 db	 '   (C) Copyright 1988-96 Qualitas, Inc.'
ifdef LANG_GR
	 db	 '  Alle Rechte vorbehalten.',CR,LF,EOS
else
	 db	 '  All rights reserved.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  AZS_XVER,AZS_NOTPRES
ifdef LANG_GR
AZS_XVER db	 BEL,'ÍÍ> falsche Version des ',@OEM_BASE,'.MGR wurde installiert.',CR,LF,0
AZS_NOTPRES db	 BEL,'ÍÍ> ',@OEM_BASE,'.MGR-Einheiten-Treiber nicht geladen von CONFIG.SYS.',CR,LF,0
else
AZS_XVER db	 BEL,'ÍÍ> Incorrect version of ',@OEM_BASE,'.MGR installed.',CR,LF,0
AZS_NOTPRES db	 BEL,'ÍÍ> ',@OEM_BASE,'.MGR device driver not loaded from CONFIG.SYS.',CR,LF,0
endif				; IFDEF LANG_GR

				; IF @OEM_PROD eq @OEMPROD_SIMU
				; IF @OEM_PROD eq @OEMPROD_MOVE
endif				; IF @OEM_PROD eq @OEMPROD_LOAD

NDATA	 ends			; End NDATA segment


ADATA	 segment use16 dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP


	 public  AZS_XDOS,AZS_XLOW
ifdef LANG_GR
AZS_XDOS db	 BEL,'ÍÍ> Dieses Programm l„uft nur unter DOS 3.00 oder h”her.',CR,LF,0
AZS_XLOW db	 BEL,'ÍÍ> Dieses Programm kann nicht im HiDOS Speicher laufen.',CR,LF,0
else
AZS_XDOS db	 BEL,'ÍÍ> This program operates under DOS 3.00 or later only.',CR,LF,0
AZS_XLOW db	 BEL,'ÍÍ> This program cannot be executed from high DOS memory.',CR,LF,0
endif				; IFDEF LANG_GR

	 public  AZS_XHI,AZS_NOROOM,AZS_ERRMEM
	 public  AZS_FILE,AZS_EXEC
ifdef LANG_GR
AZS_XHI  db	 BEL,'ÍÍ> kein HiDOS Speicher.',CR,LF,0
AZS_NOROOM db	 BEL,'ÍÍ> kein Platz im HiDOS Speicher, erzwinge GETSIZE.',CR,LF,0
AZS_ERRMEM db	 BEL,'ÍÍ> kann den Code nicht ins HiDOS verlagern.',CR,LF,0
;;;_EXEC db	 BEL,'ÍÍ> kann die angegebene Datei nicht ausfhren.',CR,LF,0
AZS_EXEC label	 byte
AZS_FILE db	 BEL,'ÍÍ> kann die angegebene Datei nicht erreichen.',CR,LF,0
else
AZS_XHI  db	 BEL,'ÍÍ> No high DOS memory.',CR,LF,0
AZS_NOROOM db	 BEL,'ÍÍ> No room in high DOS memory, forcing GETSIZE.',CR,LF,0
AZS_ERRMEM db	 BEL,'ÍÍ> Unable to move code to high DOS memory.',CR,LF,0
;;;_EXEC db	 BEL,'ÍÍ> Unable to execute the specified file.',CR,LF,0
AZS_EXEC label	 byte
AZS_FILE db	 BEL,'ÍÍ> Unable to access the specified file.',CR,LF,0
endif				; IFDEF LANG_GR

if @OEM_FLEX
	 public  AZS_UGHEMS
ifdef LANG_GR
AZS_UGHEMS db	 BEL,'ÍÍ> Residenter Programmteil schlieát FLEXFRAME-Speicher ein!!!',CR,LF,0
else
AZS_UGHEMS db	 BEL,'ÍÍ> Resident portion of program includes FLEXFRAME memory!!!',CR,LF,0
endif				; IFDEF LANG_GR
endif				; IF @OEM_FLEX

	 public  AZS_UGHROOM
ifdef LANG_GR
AZS_UGHROOM db	 BEL,'ÍÍ> Residenter Programmteil berschreitet verfgbaren Speicherplatz!!!',CR,LF
else
AZS_UGHROOM db	 BEL,'ÍÍ> Resident portion of program exceeds available storage!!!',CR,LF,0
endif				; IFDEF LANG_GR

	 public  AZS_UGHCHG,AZS_UGHCHG1,AZS_UGHCHG2
ifdef LANG_GR
AZS_UGHCHG db	     '    Žndern Sie erst diese Zeile in "SIZE='
AZS_UGHCHG1 db	 '             ',0
AZS_UGHCHG2 db	 '", starten Sie dann neu und lassen MAXIMIZE nochmals laufen.',CR,LF,0
else
AZS_UGHCHG db	     '    Change this line to use "SIZE='
AZS_UGHCHG1 db	 '             ',0
AZS_UGHCHG2 db	 '", reboot, and re-run MAXIMIZE.',CR,LF,0
endif				; IFDEF LANG_GR

ADATA	 ends			; End ADATA segment

	 MEND			; End LOADMSGS module

#' $Header:   P:/PVCS/MAX/WINMXMZ/WINMXMZ.MAV   1.11   02 Jun 1997 14:54:34   BOB  $
#
# WINMXMZ.MAK - External makefile for WINMXMZ.EXE
#
# Copyright (C) 1995 Qualitas, Inc.  All rights reserved
#

# Default definitions overridden from the command line for builds
DEBUG = 0
MFCDBG = 0						# 1 to link CodeView stuff
CTL3DV2 = 1						# 0 = Use CTL3D.LIB; 1 = Use CTL3DV2.LIB
LOCALEXE = 0					# Copy executables to local source directory

# Get product names
!include $(MAXROOT)include\maxnames.mak

# Other definitions
PROJ = winmaxim
PDIR = WINMXMZ					# Subdirectory for project
PROJPATH = $(MAXROOT)$(PDIR)\	# Directory for this project
L = $(MAXROOT)lib\				# Catnip libraries
MODEL=L 						# Memory model to use
SYSTEM = w$(WIN)				# Four- or five-letter system abbreviation

!IF $(CTL3DV2) == 1
CTL3D = CTL3DV2
!ELSE
CTL3D = CTL3D
!ENDIF

!IF $(WIN) == 16
CFLAGS_R_WEXE = /nologo /G2 /W3 /WX /A$(MODEL) /O1 /D "NDEBUG" /DLANG_$(LANG) /GA /Gs /Z7
CFLAGS_D_WEXE = /nologo /G2 /W3 /WX /A$(MODEL) /Od /D "_DEBUG" /DLANG_$(LANG) /GA /Z7
LFLAGS_R_WEXE = /NOLOGO /NOD /PACKC:61440 /ST:12288 /ALIGN:16 /ONERR:NOEXE /M /LI
LFLAGS_D_WEXE = $(LFLAGS_R_WEXE)
LIBS_D_WEXE = $(MODEL)afxcwd libw $(MODEL)libcew commdlg shell ddeml $(CTL3D).LIB
LIBS_R_WEXE = $(MODEL)afxcw  libw $(MODEL)libcew commdlg shell ddeml $(CTL3D).LIB
R_RCDEFINES = -dNDEBUG
D_RCDEFINES = -d_DEBUG
!ELSE
!ERROR Undefined target system
!ENDIF

!IF $(DEBUG)
O = $(SYSTEM)\d\				# Debug output directory
CFLAGS = $(CFLAGS_D_WEXE)
LFLAGS = $(LFLAGS_D_WEXE)
LIBS = $(LIBS_D_WEXE)
MAPFILE = $(O)$(PROJ).map
RCDEFINES = $(D_RCDEFINES)
MFCSTLIB = $(L)$(MODEL)stumfcd.lib
!ELSE
O = $(SYSTEM)\nd\				# Non-debug output
CFLAGS = $(CFLAGS_R_WEXE)
LFLAGS = $(LFLAGS_R_WEXE)
LIBS = $(LIBS_R_WEXE)
MAPFILE = $(O)$(PROJ).map
RCDEFINES = $(R_RCDEFINES)
MFCSTLIB = $(L)$(MODEL)stumfc.lib
!ENDIF

!IF $(MFCDBG)
LFLAGS = $(LFLAGS) /CO
!ENDIF

# Visual C++ definitions
CCREATEPCHFLAG =
CPPCREATEPCHFLAG = /YcSTDAFX.H /Fp$(O)STDAFX.PCH
CUSEPCHFLAG =
CPPUSEPCHFLAG = /YuSTDAFX.H /Fp$(O)STDAFX.PCH
RCFLAGS = /nologo /r /z
RESFLAGS = /nologo /t -31
DEFFILE = WINMXMZ.DEF
OBJS_EXT =
LIBS_EXT = $(L)$(MODEL)quilibr.lib $(L)$(MODEL)stutil.lib\
			$(MFCSTLIB)
SBRS = $(O)STDAFX.SBR \
		$(O)WINMXMZ.SBR

!IF "$(LANG)" == "US"
RCNAME=winmxmz.rc
!ELSE
RCNAME=winmxmz.$(LANG)
!ENDIF


# Implicit rules.  These cover all cases except creation of .PCH files.

.c{$(O)}.obj:
	@Set INCLUDE=$(INCLUDE)
	SET CL=/c $(CFLAGS) $(CUSEPCHFLAG) /Fo$*.obj /FR$*.sbr
	$(CC) $<
	SET CL=


.cpp{$(O)}.obj:
	@Set INCLUDE=$(INCLUDE)
	SET CL=/c $(CFLAGS) $(CPPUSEPCHFLAG) /Fo$*.obj /FR$*.sbr
	$(CC) $<
	SET CL=


# Required targets for MAX.MAK

ALL:	$(O)$(PROJ).EXE $(BD)$(PROJ).EXE

BROWSE: $(O)$(PROJ).BSC

DEL:
	-rm $(O)*.*

DIR:
	vdir -c $(O)

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\winmxmz\*
VCSDIR = P:\PVCS\MAX\winmxmz\*
ALIAS ALL P:\PVCS\MAX\winmxmz\*.*,p:\pvcs\max\winmxmz\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

DEPSCAN: winmxmz.mak
	depscan *.c *.cpp *.rc *.asm >winmxmz.inc

winmxmz.mak: winmxmz.inc $(H)makefile.inc

!include winmxmz.inc
!include $(H)makefile.inc


# Project dependencies (using predefined macros)

$(O)WINMXMZ.OBJ:	WINMXMZ.CPP $(WINMXMZ_DEP)

$(O)MXDLGS.OBJ: 	MXDLGS.CPP $(MXDLGS_DEP)

$(O)SUMMARY.OBJ:	SUMMARY.CPP $(SUMMARY_DEP)

$(RCNAME):		WINMXMZ.ICO ALTICON1.ICO	QMAX.BMP

$(O)WINMXMZ.RES:	$(RCNAME) $(WINMXMZ_RCDEP)
	@Set INCLUDE=$(INCLUDE)
	$(RC) $(RCFLAGS) $(RCDEFINES) -fo$@ -dLANG_$(LANG) $(RCNAME)

$(O)STDAFX.OBJ: 	STDAFX.CPP $(STDAFX_DEP)
	@Set INCLUDE=$(INCLUDE)
	SET CL=/c $(CFLAGS) $(CPPCREATEPCHFLAG) /Fo$*.obj /FR$*.sbr
	$(CC) $(@B).cpp
	SET CL=

# Object module list.
OBJS =	$(O)STDAFX.OBJ $(O)WINMXMZ.OBJ $(O)MXDLGS.OBJ \
		$(O)SUMMARY.OBJ

# Linkage rules.  Rather than use the cutesy MSVC.BND trick to avoid
# unnecessary relinkage, we always relink when the .RES file is updated.

$(BD)$(PROJ).EXE: $(O)$(PROJ).EXE
	copy $? $@

$(O)$(PROJ).EXE::	DIR

$(DEFFILE): WINLNCH.EXE

WINLNCH.EXE: $(O)WINLNCH.EXE
	copy $(O)$(@F) $@
#	cvpack /strip $@

$(O)WINLNCH.EXE: $(O)WINLNCH.OBJ $(L)$(MODEL)MYEXECV.OBJ
#	Note: order of .OBJ linkage is IMPORTANT!  myexec must come first.
	@Set LIB=$(LIB)
	$(LD) /li /m /onerr:noexe /cp:0x400 $(L)$(MODEL)myexecv.obj+$*.obj,$@,$*.map;
	mapssf -t$(BD)$(PROJ).SSF $*.map

$(O)WINLNCH.OBJ: WINLNCH.C $(WINLNCH_DEP)
	@Set INCLUDE=$(INCLUDE)
	SET CL=/Os /AS /Z7 /Fo$*.obj
	$(CC) /c $(@B).c
	SET CL=

$(O)$(PROJ).EXE::	$(OBJS) $(OBJS_EXT) $(LIBS_EXT) $(O)WINMXMZ.RES \
		$(DEFFILE) winmxmz.mak
	echo >NUL @<<$(O)$(PROJ).CRF
$(OBJS: =+^
) +
$(OBJS_EXT)
$@
$(MAPFILE)
$(MSVC)lib\+
$(MSVC)mfc\lib\+
$(LIBS_EXT)+
$(LIBS)
$(DEFFILE);
<<KEEP
	@Set INCLUDE=$(INCLUDE)
	@Set LIB=$(LIB)
	$(LD) $(LFLAGS) @$(O)$(PROJ).CRF
	$(RC) $(RESFLAGS) $(O)WINMXMZ.RES $@

$(O)$(PROJ).BSC: $(SBRS)
	bscmake @<<
/o$@ $(SBRS)
<<


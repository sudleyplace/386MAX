# $Header:   P:/PVCS/MAX/MAXHELP/MAXHELP.MAV   1.5   30 May 1997 11:43:00   BOB  $
#
# Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3
#
# Makefile for MAXHELP.HLP and SETUP.HLP
#

# Default definitions overridden from the command line for builds
WIN = 16						# Version of Windows: 16, 32S, NT, 95
DEBUG = 1
BINDIR = $(MAXROOT)lib			# Where to copy .EXE and .DLL files
BD=$(BINDIR)\				# Destination

# Add our includes to include search path
INCLUDE = $(MAXROOT)include;$(INCLUDE)

# Get product names
!include <maxnames.mak>

# Other definitions
I = $(MAXROOT)include\			# Includes
L = $(MAXROOT)lib\				# Libraries
T = $(MAXROOT)tools\			# Build tools

.SUFFIXES: .src .bat

.src.bat:
	@Set INCLUDE=$(INCLUDE)
	cl /EP /I$(MSVC)mfc\include $< >mhtemp.bat
	batcpp <mhtemp.bat >$*.bat
	-rm mhtemp.bat

# Dependencies

ALL:	MAXHELP.HLP	\
	$(BD)MAXHELP.HLP \
	MAXHELP.HPJ	\
	MAXHELP.RTF	\
	SETUP.HLP	\
	$(BD)SETUP.HLP	 \
	SETUP.HPJ	\
	SETUP.RTF

DEL:
	-rm hlp\*.* MAXHELP.HLP SETUP.HLP
	-rm MAXHELP.HPJ MAXHELP.RTF SETUP.HPJ SETUP.RTF
	-rm MAKEHELP.BAT MAKESHLP.BAT MAKEHLP2.BAT
	-rm -f _maxhelp.hpj _setup.hpj

DIR:
	vdir -c $(O) hlp bitmaps

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\maxhelp\*
VCSDIR = P:\PVCS\MAX\maxhelp\*
ALIAS ALL P:\PVCS\MAX\maxhelp\*.*,p:\pvcs\max\maxhelp\udlocal2.bav
<<KEEP

bitmaps\pvcs.cfg: DIR
	@echo <<bitmaps\pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\maxhelp\bitmaps\*
VCSDIR = P:\PVCS\MAX\maxhelp\bitmaps\*
ALIAS ALL P:\PVCS\MAX\maxhelp\bitmaps\*.*,p:\pvcs\max\maxhelp\bitmaps\HELP0001.bmv
<<KEEP

GET: pvcs.cfg bitmaps\pvcs.cfg
	$(GETCMD) $(MAKEDIR)
	cd bitmaps
	$(GETCMD) $(MAKEDIR)\bitmaps
	cd ..

# Include dependencies
SOURCE	= maxhelp.rtf maxhelp.hpj
ALIASES = winmaxim.a$(LANG)
HEADERS =
BITMAPS = bitmaps\*.bmp

MAXHELP.HLP: makehelp.bat makehlp2.bat _maxhelp.hpj \
		$(SOURCE) $(ALIASES) $(HEADERS) $(BITMAPS)
	-if exist $@ del $@
	-if exist _$@ del _$@
	echo // MAKEHELP.BAT generated Help Map file. >hlp\MAXHELP.hmc
	$(COMSPEC) /e:2048 /c makehelp
	if not exist $@ ren _maxhelp.hlp $*.*

$(BD)MAXHELP.HLP: MAXHELP.HLP
	copy $? $@

MAXHELP.HPJ:	MAXHELP.H$(LANG)
	copy $? $@

MAXHELP.RTF:	MAXHELP.R$(LANG)
	copy $? $@

_maxhelp.hpj: _maxhelp.src
	rm -f $@
	cl /EP /DLANGALI=a$(LANG) /DLANG_$(LANG) /DINCLUDE="#include" $? >$*.tmp
	batcpp <$*.tmp >$@
	-del $*.tmp

SSOURCE  = setup.rtf setup.hpj
SALIASES =
SHEADERS =
SBITMAPS =

SETUP.HLP: makeshlp.bat _setup.hpj \
		$(SSOURCE) $(SALIASES) $(SHEADERS) $(SBITMAPS)
	-del $@
	-del _$@
	echo // MAKESHLP.BAT generated Help Map file. >hlp\SETUP.hmc
	$(COMSPEC) /e:2048 /c makeshlp
	if not exist $@ ren _setup.hlp $*.*

$(BD)SETUP.HLP: SETUP.HLP
	copy $? $@

SETUP.HPJ:	SETUP.H$(LANG)
	copy $? $@

SETUP.RTF:	SETUP.R$(LANG)
	copy $? $@

_setup.hpj: _setup.src
	rm -f $@
	cl /EP /DLANGALI=a$(LANG) /DLANG_$(LANG) /DINCLUDE="#include" $? >$*.tmp
	batcpp <$*.tmp >$@
	-del $*.tmp


# $Header:   P:/PVCS/MAX/SETUP32/SETUP16.MAV   1.0   16 Sep 1996 09:09:20   PETERJ  $
# Setup makefile
# Builds setup16.dll

!include $(MAXROOT)include\maxnames.mak

PROJNAME=SETUP16
GLOBNAME=SETUP16
PDIR=SETUP32\	# directory under $(MAXROOT)
OEM=ret 	# default OEM
OBJ=W$(WIN)
O=$(OEM)\$(OBJ)\ # define include directory for OEM-specifics
L=$(MAXROOT)lib\ # .LIB directory for product-specific libraries

BASE=SETUP16

# Define local names / options
EXENAME=$(BASE).DLL
MAPNAME=$(O)$(BASE).MAP
DEFNAME=$(PROJNAME).DEF

# Set up language and compiler macros
LINKTARG=$(O)$(EXENAME)
CBASE=/c /Fo$@
RTDEBUG=

!if "$(DEBUG)" == "1"
CFLAGS_DEBUG=/Z7 /D "DEBUG"
CLF_DEBUG=/CO
!else
CFLAGS_DEBUG=
CLF_DEBUG=
!endif

COMPNAME=MSC8
CFLAGS=$(CBASE) /AL /J /Od /Gs /GA /GEae /G2 /W3 /Zp1 $(CFLAGS_DEBUG)
CLFLAGS=/NOD /NOE /F /A:16 $(CLF_DEBUG)

CLDOSFLAGS=/NOD /NOE /F
LINKDOS=LINK $(CLDOSFLAGS)
COMP=$(CC) $(CFLAGS)

.cpp{$(O)}.obj:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include;$(MSVC)mfc\include;
    $(COMP) $<

.c{$(O)}.obj:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include;$(MSVC)mfc\include;
    $(COMP) $<

.rc{$(O)}.res:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include;$(MSVC)mfc\include;
	$(RC) -v -r -fo$@ $<

# Define local commands

# Define ALL: target
ALL : DIR $(O)$(EXENAME) $(BINDIR)$(EXENAME) $(O)$(PROJNAME).LIB

DEL:
	-rm $(O)*.*

DIR:
	vdir -c $(O)
	vdir -c $(GO)

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\cyasetup\*
VCSDIR = P:\PVCS\MAX\cyasetup\*
ALIAS ALL P:\PVCS\MAX\cyasetup\*.*,p:\pvcs\max\cyasetup\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

# Get Depscan-generated dependencies
DEPSCAN: setup16.mak
	depscan *.c *.cpp *.rc *.asm >setup16.inc

setup16.mak: setup16.inc $(H)makefile.inc

!include $(PROJNAME).inc

!if "$(SOURCEMACH)" != ""
# SOURCEMACH=\\p54c\c\max\ for example; a full MAXROOT on another machine
UPDATE: $(SOURCEMACH)$(PDIR)cyasetup.mak
	xc /n $(SOURCEMACH)$(PDIR)*.* $(MAXROOT)$(PDIR).

!endif

$(BINDIR)$(EXENAME): $(O)$(EXENAME)
	xc /r $? $@

$(O)$(PROJNAME).LIB: $(O)$(PROJNAME).DLL
	implib /nowep $@ $*.DLL

# Build setup16.dll

$(O)SETUP16.obj: setup16.c $(SETUP16_DEP)

$(O)setup16.res: setup16.rc  $(SETUP16_RCDEP)

OBJS=$(O)setup16.obj $(O)s32thk.O16

LIBS=libw llibcew shell ddeml commdlg ver
LIBS_EXT=

$(LINKTARG) : $(OBJS) setup16.mak $(O)setup16.res
    SET LIB=$(MSVC)lib;$(MSVC)mfc\lib
	$(LD) @<<$(O)$(BASE).lrf
$(OBJS: =+^
) $(CLFLAGS)
$(LINKTARG)
$(MAPNAME)/map
$(LIBS: =+^
) $(LIBS_EXT: =+^
)
$(DEFNAME);
<<KEEP
!IFDEF POSTLINKCMD
	$(POSTLINKCMD)
!ENDIF
	$(RC) -40 -v -K $(O)setup16.res $@

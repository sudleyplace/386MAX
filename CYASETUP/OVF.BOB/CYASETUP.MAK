#' $Header:   P:/PVCS/MAX/CYASETUP/CYASETUP.MAV   1.8   20 Jan 1997 08:39:04   PETERJ  $
# Setup makefile
# Builds setup.exe

!include $(MAXROOT)include\maxnames.mak

PROJNAME=CYASETUP
GLOBNAME=SETUP
CLEANNAME=EVAP.EXE
PDIR=CYASETUP\	# directory under $(MAXROOT)
OEM=ret 	# default OEM
!if "$(TLOCK)" == "1" 
OBJ=W$(WIN)TL
!else
OBJ=W$(WIN)
!endif

O=$(OEM)\$(OBJ)\ # define include directory for OEM-specifics
L=$(MAXROOT)lib\ # .LIB directory for product-specific libraries

!if "$(WIN)" == "32"
BASE=SETUP$(WIN)
!else
BASE=SETUP
!endif

# Define local names / options
EXENAME=$(BASE).EXE
MAPNAME=$(O)$(BASE).MAP
DEFNAME=$(PROJNAME).DEF

!if "$(WIN)" == "32"
MAKE32=1
!else
MAKE32=0
!endif

!if "$(TLOCK)" == "1" 
TL=$(MAXROOT)tlock$(WIN)\   #timelock dir.
TIMELOCKLIB=$(TL)tlock$(WIN)
TLFLAG=/D "TLOCK"
!else
TIMELOCKLIB=
TLFLAG=
!endif

# Set up language and compiler macros
LINKTARG=$(O)$(EXENAME)
CBASE=/c /Fo$@
RTDEBUG=

!if "$(DEBUG)" == "1"
!if $(MAKE32)
#CFLAGS_DEBUG=/Zd /Fd$*.pdb /D "DEBUG"
CFLAGS_DEBUG=/Z7 /Fd$*.pdb /D "DEBUG"
!else
CFLAGS_DEBUG=/Z7 /D "DEBUG"
!endif
!else
CFLAGS_DEBUG=
!endif

!if $(MAKE32)
COMPNAME=MSC10
CDEFS=/D "WIN32" /D "_WINDOWS"
CFLAGS=$(CBASE) /W3 /WX /Od $(CDEFS) $(CFLAGS_DEBUG) $(TLFLAG)
CLFLAGS=
# /nodefaultlib:libc$(RTDEBUG).lib
!else
COMPNAME=MSC8
CFLAGS=$(CBASE) /AL /J /Od /Gs /GA /GEae /G2 /W3 /WX /Zp1 $(CFLAGS_DEBUG) $(TLFLAG)
CLFLAGS=/NOD /NOE /F /A:16 $(CLF_DEBUG)
!endif

CLDOSFLAGS=/NOD /NOE /F
LINKDOS=LINK $(CLDOSFLAGS)
COMP=$(CC) $(CFLAGS)

.cpp{$(O)}.obj:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include
    $(COMP) $<

.rc{$(O)}.res:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include
	$(RC) -v -r $(TLFLAG) -fo$@ $<

# Define local commands

# Define ALL: target
ALL : DIR $(O)$(EXENAME) $(BINDIR)$(EXENAME)

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
DEPSCAN: cyasetup.mak
	depscan *.c *.cpp *.rc *.asm >cyasetup.inc

cyasetup.mak: cyasetup.inc $(H)makefile.inc

!include $(PROJNAME).inc

!if "$(SOURCEMACH)" != ""
# SOURCEMACH=\\p54c\c\max\ for example; a full MAXROOT on another machine
UPDATE: $(SOURCEMACH)$(PDIR)cyasetup.mak
	xc /n $(SOURCEMACH)$(PDIR)*.* $(MAXROOT)$(PDIR).

!endif

$(BINDIR)$(EXENAME): $(O)$(EXENAME)
	xc /r $? $@

# Build cyasetup.EXE

!if "$(WIN)" != "32"
$(O)evap.rc : $(O)evap.exe
    $(B2R) 1 $@ %s

$(O)epif.rc : evap.pif
    $(B2R) 1 $@ %s

$(O)evap.exe: evap.c
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include
    SET LIB=$(MSVC)lib
	cl /Fe$@ /W3 /WX /Os /AS /Fo$@ /Fm$*.map %s
!endif

$(O)PROGSPEC.obj: progspec.cpp $(PROGSPEC_DEP)

$(O)PROGLOCL.obj: proglocl.cpp $(PROGLOCL_DEP)

$(O)PSDIALOG.obj: psdialog.cpp $(PSDIALOG_DEP)

!if $(MAKE32)
$(O)cyasetup.res: cyasetup.rc $(CYASETUP_RCDEP)
!else
$(O)cyasetup.res: cyasetup.rc $(O)evap.rc $(O)epif.rc $(CYASETUP_RCDEP)
!endif

#####################################################################
!if $(MAKE32)
#####################################################################
# 32 bit link set

OBJS=$(O)progspec.obj $(O)proglocl.obj $(O)psdialog.obj $(O)cyasetup.res

LIBS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib version.lib

!if "$(TLOCK)" == "1" 
LIBS_EXT=$(L)Lstut32.lib $(L)qsetup32 $(L)dzip32.lib\
 $(L)dunzip32.lib $(TIMELOCKLIB).lib
!else
LIBS_EXT=$(L)Lstut32.lib $(L)qsetup32.lib $(L)dzip32.lib $(L)dunzip32.lib
!endif

$(LINKTARG) : $(OBJS) $(LIBS_EXT) CYASETUP.MAK
    SET LIB=$(MSVC)lib
	$(LD) @<<$(O)$(BASE).lrf
$(LIBS: =^
) $(LIBS_EXT: =^
) $(OBJS: =^
) $(CLFLAGS)
/OUT:$(LINKTARG)
/SUBSYSTEM:WINDOWS
!if "$(DEBUG)" == "1"
/PDB:$(O)SETUP32.pdb
/DEBUG:FULL
/DEBUGTYPE:BOTH
!endif
<<KEEP
!IFDEF POSTLINKCMD
	$(POSTLINKCMD)
!ENDIF
!if "$(DEBUG)" == "1"
	pedump $@
!endif

##################################################################
!else
##################################################################
# 16 bit link set

OBJS=$(O)progspec.obj $(O)proglocl.obj $(O)psdialog.obj

LIBS=libw llibcew shell ddeml commdlg ver
LIBS_EXT=$(L)Lstutil $(L)qsetup

$(LINKTARG) : $(OBJS) cyasetup.mak $(O)cyasetup.res $(L)qsetup.lib\
	      $(L)lstutil.lib $(O)evap.exe
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
	$(RC) -31 -v -K $(TLFLAG) $(O)cyasetup.res $@

##################################################################
!endif

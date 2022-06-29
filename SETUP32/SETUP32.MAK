# $Header:   P:/PVCS/MAX/SETUP32/SETUP32.MAV   1.0   16 Sep 1996 09:09:20   PETERJ  $
#
# Setup32 makefile
#
# Builds setup32.dll
#
!include $(MAXROOT)include\maxnames.mak

PROJNAME=SETUP32
PDIR=SETUP32\	# directory under $(MAXROOT)
OEM=ret 		# default OEM
OBJ=W$(WIN)
O=$(OEM)\$(OBJ)\ # define object directory for OEM-specifics
O16=$(OEM)\w16\  # define object directory for OEM-specifics
L=$(MAXROOT)lib\ # .LIB directory for product-specific libraries

BASE=SETUP32

# Define local names / options
EXENAME=$(BASE).DLL
MAPNAME=$(O)$(BASE).MAP
DEFNAME=$(PROJNAME).DEF
DEBUG=0

MAKE32=1

ASMOPTS=/coff

!if "$(DEBUG)" == "1"
CFLAGS_DEBUG=/Z7 /Fd$*.pdb /D "DEBUG"
!else
CFLAGS_DEBUG=/D "NDEBUG"
!endif

# Set up language and compiler macros
LINKTARG=$(O)$(EXENAME)
CBASE=/c /Fo$@
RTDEBUG=

COMPNAME=MSC10
CDEFS=/D "WIN32" /D "_WINDOWS"
CFLAGS=$(CBASE) /MT /W3 /GX /O2 $(CDEFS) $(CFLAGS_DEBUG)

CLFLAGS=

CLDOSFLAGS=/NOD /NOE /F
LINKDOS=LINK $(CLDOSFLAGS)
COMP=$(CC) $(CFLAGS)

.cpp{$(O)}.obj:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include
    $(COMP) $<

.rc{$(O)}.res:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;
	$(RC) -v -r -fo$@ $<

.asm{$(O)}.obj:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;
	$(C) -v -r -fo$@ $<

# Define local commands

# Define ALL: target
ALL : DIR $(O)$(EXENAME) $(BINDIR)$(EXENAME)\
	  $(O16)S32THK.O16 $(BINDIR)S32THK.O16

DEL:
	-rm $(O)*.*

DIR:
	vdir -c $(O)
	vdir -c $(O16)

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\SYSSAVER\*
VCSDIR = P:\PVCS\MAX\SETUP32\*
ALIAS ALL P:\PVCS\MAX\SETUP32\*.*,p:\pvcs\max\SETUP32\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

# Get Depscan-generated dependencies
DEPSCAN: setup32.mak
	depscan *.c *.cpp *.rc *.asm >setup32.inc

setup32.mak: setup32.inc $(H)makefile.inc

!include $(PROJNAME).inc

!if "$(SOURCEMACH)" != ""
# SOURCEMACH=\\p54c\c\max\ for example; a full MAXROOT on another machine
UPDATE: $(SOURCEMACH)$(PDIR)setup32.mak
	xc /n $(SOURCEMACH)$(PDIR)*.* $(MAXROOT)$(PDIR).

!endif

$(BINDIR)$(EXENAME): $(O)$(EXENAME)
	xc /r $? $@

$(BINDIR)S32THK.O16: $(O16)S32THK.O16
	xc /r $? $@

# Build SETUP32.DLL

$(O)S32THK.ASM: 	S32THK.THK
	$(MSVC16)BIN\thunk -t thk %s -o $@

$(O)SETVER32.obj : SETVER32.cpp $(SETVER32_DEP)

$(O)S32THK.O32:   $(O)S32THK.ASM
	ml /DIS_32 /c /W3 /nologo /coff /Fo $@ %s

$(O16)S32THK.O16: $(O)S32THK.ASM
	ml /DIS_16 /c /W3 /nologo /Fo $@ %s

# 32 bit link set

OBJS=$(O)SETVER32.obj $(O)S32THK.O32

LIBS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib version.lib\
 thunk32.lib

$(LINKTARG) : $(OBJS) $(LIBS_EXT) SETUP32.mak
    SET LIB=$(MSVC)lib
	$(LD) @<<$(O)$(BASE).lrf
$(LIBS: =^
) $(LIBS_EXT: =^
) $(OBJS: =^
) $(CLFLAGS)
/OUT:$(LINKTARG)
/DEF:$(BASE).def
/subsystem:windows
/dll
/incremental:no
/map:$(MAPNAME)
/machine:I386
!if "$(DEBUG)" == "1"
/PDB:$(O)$(BASE).pdb
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


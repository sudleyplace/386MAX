# $Header:   P:/PVCS/MAX/SETUP/SETUP.MAV   1.4   20 Jan 1997 08:36:50   PETERJ  $
#
# Setup utilities static link library
#

!include $(MAXROOT)include\maxnames.mak

# Values overridden on command line
ENV=W$(WIN)
MODEL=L
DEBUG=0
L=$(MAXROOT)lib\				# Where to copy static libraries
SBR_OPT =

!if "$(WIN)" == "32"
MAKE32=1
!else
MAKE32=0
!endif

O2=$(ENV)\d$(MODEL)\	# Output directory, debug version of MFC stuff
O=$(ENV)\nd$(MODEL)\	# Output directory, release version
ADBGFLAGS=/Zi
CDBGFLAGS=/Z7

!if $(MAKE32)
CFMODEL=L
AMODEL=LARGE
!message Flat model
!else
CFMODEL=$(MODEL)
!if "$(MODEL)" == "L"
AMODEL=LARGE
CFMODEL=Lw
!message Large model ($(MODEL))
!elseif "$(MODEL)" == "M"
AMODEL=MEDIUM
CFMODEL=Mw
!message Medium model ($(MODEL))
!elseif "$(MODEL)" == "C"
AMODEL=COMPACT
CFMODEL=Cw
!message Compact model ($(MODEL))
!elseif "$(MODEL)" == "S"
AMODEL=SMALL
CFMODEL=Sw
!message Small model ($(MODEL))
!else
!error Unknown model $(MODEL) -- should be L, M, C, or S
!endif
!endif

!if $(MAKE32)
EXENAME=QSETUP32.LIB
MAPNAME=QSETUP32.MAP
!else
EXENAME=QSETUP.LIB
MAPNAME=QSETUP.MAP
!endif

# Set up language and compiler macros
LINKTARG=$(EXENAME)
ABASE=/W2
AFLAGS=$(ABASE) /D_MODEL=$(AMODEL) $(ADBGFLAGS)

!if $(MAKE32)
CBASE=/Fo$@
CDEFS=/D "WIN32" /D "_WINDOWS"
CFLAGS=$(CBASE) /W3 /Od $(CDBGFLAGS) $(CDEFS)
!else
CFLAGS=/A$(CFMODEL) /J /Od /Gs /GA /GEae /G2 /W3 /Zp1 /nologo $(CDBGFLAGS) /D_WIN$(WIN)
!endif

CLFLAGS=/r /NOD /NOE /F /PACKC /A:16
LINK=$(LD) $(CLFLAGS)
ASM=$(AS) $(AFLAGS)

.c{$(O)}.obj:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include;$(MSVC)mfc\include;
	SET CL=/c $(CFLAGS) /Fo$*.obj $(SBR_OPT)
	$(CC) $<
	SET CL=

.cpp{$(O)}.obj:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include;$(MSVC)mfc\include;
	SET CL=/c $(CFLAGS) /Fo$*.obj $(SBR_OPT)
	$(CC) $<
	SET CL=

.cpp{$(O2)}.obj:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include;$(MSVC)mfc\include;
	SET CL=/c $(CFLAGS) /D_DEBUG /Fo$*.obj $(SBR_OPT)
	$(CC) $<
	SET CL=

.asm{$(O)}.obj:
	$(AS) $<,$*.obj $(AFLAGS);

# Define ALL: target
ALL:: DIR

# Build QSETUP.lib
ALL:: $(O)$(LINKTARG) $(L)$(LINKTARG) 

$(L)$(LINKTARG): $(O)$(LINKTARG)
	copy $? $@

DIR:
	vdir -c $(O) $(O2)

DEL:
	-rm $(O)*.* $(O2)*.*

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\setup\*
VCSDIR = P:\PVCS\MAX\setup\*
ALIAS ALL P:\PVCS\MAX\setup\*.*,p:\pvcs\max\setup\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

DEPSCAN: setup.mak
	depscan *.c *.cpp *.rc *.asm >setup.inc

setup.mak: setup.inc $(H)makefile.inc

!include setup.inc		# Local dependencies
!include $(H)makefile.inc

# .C and .CPP dependencies

$(O)setup.obj : setup.cpp $(SETUP_DEP)

$(O)SETUTIL.obj : SETUTIL.cpp $(SETUTIL_DEP)

$(O)SETDDE.obj : SETDDE.cpp $(SETDDE_DEP)

$(O)SETEXT.obj : SETEXT.cpp $(SETEXT_DEP)

$(O)SETDISP.obj : SETDISP.cpp $(SETDISP_DEP)

$(O)SETSPL.obj : SETSPL.cpp $(SETSPL_DEP)

$(O)SETUNZIP.obj : SETUNZIP.cpp $(SETUNZIP_DEP)

ALLOBJS=$(O)setup.obj $(O)SETUTIL.obj $(O)SETDDE.obj\
        $(O)setdisp.obj $(O)setext.obj $(O)setunzip.obj\
        $(O)setspl.obj $(O)setver.obj

!if $(MAKE32)

$(O)$(LINKTARG) : $(ALLOBJS) setup.mak
	-del $@
	$(LIBUTIL) /OUT:$(O)$(LINKTARG) @<<$(O)qsetup32.lrf
$(ALLOBJS)
<<KEEP


!else


$(O)$(LINKTARG) : $(ALLOBJS) setup.mak
	-del $@
	$(LIBUTIL) @<<$(O)setup.lrf
	/BATCH $@
	$(ALLOBJS: =&^
), NUL;
<<KEEP

!endif


#' $Header:   P:/PVCS/MAX/STATUTIL/STATUTIL.MAV   1.7   02 Jun 1997 14:53:32   BOB  $
#
# Miscellaneous utilities static link library
#
# This was ripped off from p:\cat\statutil.
#
# NOTE: There should be only one function per module to eliminate
# deadhead linking.  Some functions may be grouped together if
# their functionality is inseparable.
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

O2=$(ENV)\d$(MODEL)\			# Output directory, debug version of MFC stuff
O=$(ENV)\nd$(MODEL)\			# Output directory, release version
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
EXENAME=$(MODEL)STUT32.LIB
MAPNAME=$(MODEL)STUT32.MAP
MFCNAME=$(MODEL)StuM32.LIB
MFCNAMED=$(MODEL)StuM32d.LIB
!else
EXENAME=$(MODEL)STUtil.LIB
MAPNAME=$(MODEL)STUtil.MAP
MFCNAME=$(MODEL)StuMFC.LIB
MFCNAMED=$(MODEL)StuMFCd.LIB
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
CFLAGS=/A$(CFMODEL) /J /Os /Gs /GA /GEae /G2 /W3 /Zp1 /nologo $(CDBGFLAGS) /D_WIN$(WIN)
!endif

CLFLAGS=/r /NOD /NOE /F /PACKC /A:16
LINK=$(LD) $(CLFLAGS)
ASM=$(AS) $(AFLAGS)

.c{$(O)}.obj:
	SET CL=/c $(CFLAGS) /Fo$*.obj $(SBR_OPT)
	SET INCLUDE=$(INCLUDE)
	$(CC) $<
	SET CL=

.cpp{$(O)}.obj:
	SET CL=/c $(CFLAGS) /Fo$*.obj $(SBR_OPT)
	SET INCLUDE=$(INCLUDE)
	$(CC) $<
	SET CL=

.cpp{$(O2)}.obj:
	SET CL=/c $(CFLAGS) /D_DEBUG /Fo$*.obj $(SBR_OPT)
	SET INCLUDE=$(INCLUDE)
	$(CC) $<
	SET CL=

.asm{$(O)}.obj:
    SET INCLUDE=$(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include;$(MSVC)mfc\include;
	$(AS) $<,$*.obj $(AFLAGS);

# Define ALL: target
ALL:: DIR

# Build STUtil.lib and STUMFC[d].lib
ALL:: $(O)$(LINKTARG) $(L)$(LINKTARG) $(L)$(MODEL)myexecv.obj \
	  $(L)$(MODEL)iofmt.obj

!if "$(MODEL)" == "L"
ALL:: $(O)$(MFCNAME)  $(L)$(MFCNAME) \
	  $(O)$(MFCNAMED) $(L)$(MFCNAMED)
!endif

$(L)$(LINKTARG): $(O)$(LINKTARG)
	copy $? $@

$(L)$(MFCNAME): $(O)$(MFCNAME)
	copy $? $@

$(L)$(MFCNAMED): $(O)$(MFCNAMED)
	copy $? $@

DIR:
	vdir -c $(O) $(O2)

DEL:
	-rm $(O)*.* $(O2)*.*

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\statutil\*
VCSDIR = P:\PVCS\MAX\statutil\*
ALIAS ALL P:\PVCS\MAX\statutil\*.*,p:\pvcs\max\statutil\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

DEPSCAN: statutil.mak
	depscan *.c *.cpp *.rc *.asm >statutil.inc

statutil.mak: statutil.inc $(H)makefile.inc

!include statutil.inc		# Local dependencies
!include $(H)makefile.inc


# .C and .CPP dependencies

$(O)access.obj: access.cpp $(ACCESS_DEP)

$(O)ctimedt.obj: ctimedt.cpp $(CTIMEDT_DEP)

$(O)dosdir.obj: dosdir.cpp $(DOSDIR_DEP)

$(O)drivetyp.obj: drivetyp.cpp $(DRIVETYP_DEP)

$(O)fcopyver.obj: fcopyver.cpp $(FCOPYVER_DEP)

$(O)filecopy.obj: filecopy.c $(FILECOPY_DEP)

$(O)getdir.obj: getdir.cpp $(GETDIR_DEP)

$(O)gstring.obj: gstring.cpp $(GSTRING_DEP)

$(O)hash.obj: hash.c $(HASH_DEP)

$(O)iofmt.obj: iofmt.c $(IOFMT_DEP)

$(L)$(MODEL)iofmt.obj: $(O)iofmt.obj
	xc /r $? $@

$(O)istext.obj: istext.cpp $(ISTEXT_DEP)

$(O)security.obj: security.c $(SECURITY_DEP)

$(O)strstk.obj:   strstk.c $(STRSTK_DEP)

$(O)tdutil.obj: tdutil.cpp $(TDUTIL_DEP)

$(O)zopen.obj: zopen.cpp $(ZOPEN_DEP)


# Debug and non-debug versions of MFC modules

$(O)splash.obj: splash.cpp $(SPLASH_DEP)

$(O2)splash.obj: splash.cpp $(SPLASH_DEP)

$(O)centdlg.obj: centdlg.cpp $(CENTDLG_DEP)

$(O2)centdlg.obj: centdlg.cpp $(CENTDLG_DEP)

$(O)bluescr.obj: bluescr.cpp $(BLUESCR_DEP)

$(O2)bluescr.obj: bluescr.cpp $(BLUESCR_DEP)

$(O)ddx_ddv.obj: ddx_ddv.cpp $(DDX_DDV_DEP)

$(O2)ddx_ddv.obj: ddx_ddv.cpp $(DDX_DDV_DEP)

# .ASM dependencies

$(O)stkinfo.obj: stkinfo.asm $(STKINFO_ADEP)

$(L)$(MODEL)myexecv.obj: myexecv.asm $(MYEXECV_ADEP)
	@Set INCLUDE=$(INCLUDE)
	$(AS6) /c /Cp /Fo$@ myexecv.asm

ALLOBJS=	$(O)getdir.obj		$(O)dosdir.obj		$(O)hash.obj\
			$(O)access.obj		$(O)security.obj	$(O)gstring.obj\
			$(O)strstk.obj		$(O)istext.obj

!if "$(MODEL)" == "L"
ALLOBJS=$(ALLOBJS)	$(O)zopen.obj
!endif

MFCOBJS=	$(O)splash.obj		$(O)centdlg.obj 	$(O)bluescr.obj\
			$(O)ddx_ddv.obj

MFCOBJSD=	$(O2)splash.obj 	$(O2)centdlg.obj	$(O2)bluescr.obj\
			$(O2)ddx_ddv.obj

!if $(MAKE32)

# FIXME - still need to convert these
#$(O)tdutil.obj $(O)ctimedt.obj $(O)drivetyp.obj

# Not needed in Win32
#$(O)filecopy.obj

$(O)$(LINKTARG) : $(ALLOBJS) statutil.mak
	-if exist $@ del $@
	$(LIBUTIL) /OUT:$(O)$(LINKTARG) @<<$(O)statut32.lrf
$(ALLOBJS)
<<KEEP

$(O)$(MFCNAME) : $(MFCOBJS) statutil.mak
	-if exist $@ del $@
	$(LIBUTIL) /OUT:$@ @<<$(O)mfc32.lrf
$(MFCOBJS)
<<KEEP

$(O)$(MFCNAMED) : $(MFCOBJSD) statutil.mak
	-if exist $@ del $@
	$(LIBUTIL) /OUT:$@ @<<$(O)mfc32d.lrf
$(MFCOBJSD)
<<KEEP

!else

ALLOBJS=$(ALLOBJS)		$(O)stkinfo.obj 	$(O)drivetyp.obj	$(O)filecopy.obj

!if "$(MODEL)" == "L"
ALLOBJS=$(ALLOBJS)		$(O)tdutil.obj		$(O)ctimedt.obj
!endif

$(O)$(LINKTARG) : $(ALLOBJS) statutil.mak
	-if exist $@ del $@
	$(LIBUTIL) @<<$(O)statutil.lrf
	/BATCH $@
	$(ALLOBJS: =&^
), NUL;
<<KEEP

$(O)$(MFCNAME) : $(MFCOBJS) statutil.mak
	-if exist $@ del $@
	$(LIBUTIL) @<<$(O)mfc.lrf
	/BATCH $@
	$(MFCOBJS: =&^
), NUL;
<<KEEP

$(O)$(MFCNAMED) : $(MFCOBJSD) statutil.mak
	-if exist $@ del $@
	$(LIBUTIL) @<<$(O)mfcd.lrf
	/BATCH $@
	$(MFCOBJSD: =&^
), NUL;
<<KEEP

!endif


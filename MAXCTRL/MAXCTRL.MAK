# $Header:   P:/PVCS/MAX/MAXCTRL/MAXCTRL.MAV   1.15   02 Jun 1997 13:55:02   BOB  $
#
# MAXCTRL makefile
#
# Builds MAXCTRL.EXE and SETTABS.DLL
#

!include $(MAXROOT)include\maxnames.mak

OEM=ret 		# default OEM
OBJ=W$(WIN)
O=$(OEM)\$(OBJ)\ # define include directory for OEM-specifics
L=$(MAXROOT)lib\ # .LIB directory for product-specific libraries

# Define local names / options
COMPNAME=MSC8
EXENAME=TOOLBOX.EXE
MAPNAME=$(O)MAXCTRL.MAP
DEFNAME=MAXCTRL.DEF

# Set up language and compiler macros
LINKTARG=$(O)$(EXENAME)
CBASE=/c /Fo$@ /DLANG_$(LANG)
CFLAGS=$(CBASE) /AL /J /Os /Gs /GA /GEae /G2 /W3 /Zp1 /Z7
CLFLAGS=/NOD /NOE /F /A:16
CLDOSFLAGS=/NOD /NOE /F
LINK=$(LD) $(CLFLAGS)
LINKDOS=$(LD) $(CLDOSFLAGS)
COMP=$(CC) $(CFLAGS)
!IF "$(LANG)" == "US"
RCNAME=toolbox.rc
!ELSE
RCNAME=toolbox.$(LANG)
!ENDIF

# Define local commands

# Define ALL: target
ALL : DIR $(LINKTARG) $(BD)$(EXENAME) $(BD)EVAP.EXE

DEL:
	-rm $(O)*.*

DIR:
	vdir -c $(O)

DEL_RES:
    del $(O)toolbox.res

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\maxctrl\*
VCSDIR = P:\PVCS\MAX\maxctrl\*
ALIAS ALL P:\PVCS\MAX\maxctrl\*.*,p:\pvcs\max\maxctrl\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

DEPSCAN: maxctrl.mak
	depscan *.c *.cpp *.rc *.asm >maxctrl.inc

maxctrl.mak: maxctrl.inc $(H)makefile.inc

# Get Depscan-generated dependencies
!include maxctrl.inc
!include $(H)makefile.inc

$(BD)$(EXENAME): $(LINKTARG)
	xc /r $? $@

$(BD)EVAP.EXE:	$(O)EVAP.EXE
	xc /r $? $@

# Build TOOLBOX.EXE

$(O)toolbox.obj : toolbox.c $(TOOLBOX_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) toolbox.c

$(O)setupdde.obj : setupdde.c $(SETUPDDE_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) setupdde.c

$(O)misc.obj : misc.c $(MISC_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) misc.c

$(O)filecopy.obj : filecopy.c $(FILECOPY_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) filecopy.c

$(O)toolbox.res: $(RCNAME) $(TOOLBOX_RCDEP)
	@Set INCLUDE=$(INCLUDE)
	$(RC) -v -r -fo$@ -dLANG_$(LANG) $(RCNAME)

OBJS=$(O)toolbox.obj $(O)setupdde.obj $(O)filecopy.obj $(O)misc.obj
LIBS=libw llibcew ddeml toolhelp shell
LIBS_EXT=sfttabs ctl3dv2

$(LINKTARG) : $(OBJS) maxctrl.mak $(O)toolbox.res
	@Set LIB=$(LIB)
	$(LINK) @<<$(O)toolbox.lrf
$(OBJS: =+^
)
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
	$(RC) -31 -v -K $(O)toolbox.res $@


# Build EVAP.EXE

$(O)evap.obj:	evap.c $(EVAP_DEP)
	$(COMP) evap.c

OBJS=$(O)evap.obj
LIBS=llibce oldnames
LIBS_EXT=

$(O)evap.exe: $(OBJS) maxctrl.mak
	$(LINKDOS) @<<$(O)evap.lrf
$(OBJS: =+^
)
$(O)evap.exe
$(O)evap/map
$(LIBS: =+^
) $(LIBS_EXT: =+^
);
<<KEEP
!IFDEF POSTLINKCMD
	$(POSTLINKCMD)
!ENDIF


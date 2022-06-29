#' $Header:   P:/PVCS/MAX/MAXMETER/MAXMETER.MAV   1.10   02 Jun 1997 13:45:42   BOB  $
#
# Build the MAXMETER executable file

!include $(MAXROOT)include\maxnames.mak

OEM=ret 		# default OEM
OBJ=W$(WIN)
O=$(OEM)\$(OBJ)\ # define include directory for OEM-specifics
L=$(MAXROOT)lib\ # .LIB directory for product-specific libraries

# Define local names / options
COMPNAME=MSC8
EXENAME=MAXMETER.EXE
MAPNAME=$(O)MAXMETER.MAP
DEFNAME=MAXMETER.DEF

# Set up language and compiler macros
LINKTARG=$(O)$(EXENAME)
CBASE=/c /Fo$@ /DLANG_$(LANG)
CFLAGS=$(CBASE) /AS /J /Os /Gs /GA /GEae /G2 /W3 /Zp1 /Z7
CLFLAGS=/NOD /NOE /F /PACKD /PACKC /A:16
LINK=$(LD) $(CLFLAGS)
COMP=$(CC) $(CFLAGS)
!IF "$(LANG)" == "US"
RCNAME=MAXMETER.RC
!ELSE
RCNAME=MAXMETER.$(LANG)
!ENDIF

# Define local commands
LINKCMD=$(LINK) @..\maxmeter.lnk

# Define ALL: target
ALL : DIR $(LINKTARG) $(BD)$(EXENAME)

DEL:
	-rm $(O)*.*

DIR:
	vdir -c $(O)

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\maxmeter\*
VCSDIR = P:\PVCS\MAX\maxmeter\*
ALIAS ALL P:\PVCS\MAX\maxmeter\*.*,p:\pvcs\max\maxmeter\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

DEPSCAN: maxmeter.mak
	depscan *.c *.cpp *.rc *.asm >maxmdep.inc

maxmeter.mak: maxmdep.inc $(H)makefile.inc

# Get Depscan-generated dependencies
!include maxmdep.inc
!include $(H)makefile.inc

$(BD)$(EXENAME): $(LINKTARG)
	xc /r $? $@

# Build MAXMETER.EXE

$(O)maxmeter.obj : maxmeter.c $(MAXMETER_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) maxmeter.c

$(O)maxmeter.res: $(RCNAME) $(MAXMETER_RCDEP)
	@Set INCLUDE=$(INCLUDE)
	$(RC) -v -r -fo$@ -dLANG_$(LANG) $(RCNAME)

OBJS=$(O)maxmeter.obj
LIBS=libw slibcew commdlg
LIBS_EXT=ctl3dv2.lib

$(LINKTARG) : $(OBJS) maxmeter.mak $(O)maxmeter.res
	@Set LIB=$(LIB)
	$(LINK) @<<$(O)maxmeter.lrf
$(OBJS: =+^
)
$@
$(MAPNAME)/map
$(LIBS: =+^
) $(LIBS_EXT: =+^
)
$(DEFNAME);
<<KEEP
!IFDEF POSTLINKCMD
	$(POSTLINKCMD)
!ENDIF
	$(RC) -v -K -31 $(O)maxmeter.res $@


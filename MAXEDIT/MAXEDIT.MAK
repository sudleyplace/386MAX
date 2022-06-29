# $Header:   P:/PVCS/MAX/MAXEDIT/MAXEDIT.MAV   1.11   02 Jun 1997 13:52:12   BOB  $
#
# Build the MAXEDIT executable file

!include $(MAXROOT)include\maxnames.mak

OEM=ret 		# default OEM
OBJ=W$(WIN)
O=$(OEM)\$(OBJ)\ # define include directory for OEM-specifics
L=$(MAXROOT)lib\ # .LIB directory for product-specific libraries

# Define local names / options
COMPNAME=MSC8
EXENAME=MAXEDIT.EXE
MAPNAME=$(O)MAXEDIT.MAP
DEFNAME=MAXEDIT.DEF

# Set up language and compiler macros
LINKTARG=$(O)$(EXENAME)
CBASE=/c /Fo$@ /DLANG_$(LANG)
CFLAGS=$(CBASE) /AS /J /Os /Gs /GA /GEae /G2 /W3 /Zp1 /Z7
CLFLAGS=/NOD /NOE /F /PACKC /A:16
LINK=$(LD) $(CLFLAGS)
COMP=$(CC) $(CFLAGS)

!IF "$(LANG)" == "US"
RCNAME=maxedit.rc
!ELSE
RCNAME=maxedit.$(LANG)
!ENDIF

# Define local commands

# Define ALL: target
ALL : DIR $(LINKTARG) $(BD)$(EXENAME)

DEL:
	-rm $(O)*.*

DIR:
	vdir -c $(O)

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\maxedit\*
VCSDIR = P:\PVCS\MAX\maxedit\*
ALIAS ALL P:\PVCS\MAX\maxedit\*.*,p:\pvcs\max\maxedit\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

DEPSCAN: maxedit.mak
	depscan *.c *.cpp *.rc *.asm >maxedep.inc

maxedit.mak: maxedep.inc $(H)makefile.inc

# Get Depscan-generated dependencies
!include maxedep.inc
!include $(H)makefile.inc

$(BD)$(EXENAME): $(LINKTARG)
	xc /r $? $@


# Build MAXEDIT.EXE

$(O)maxedit.obj : maxedit.c $(MAXEDIT_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) maxedit.c

$(O)toolbar.obj : toolbar.c $(TOOLBAR_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) toolbar.c

$(O)maxedit.res: $(RCNAME) $(MAXEDIT_RCDEP)
	@Set INCLUDE=$(INCLUDE)
	$(RC) -v -r -fo$@ -dLANG_$(LANG) $(RCNAME)

OBJS=$(O)maxedit.obj $(O)toolbar.obj
LIBS=libw slibcew commdlg toolhelp shell
LIBS_EXT=ctl3dv2

$(LINKTARG) : $(OBJS) maxedit.mak $(O)maxedit.res
	@Set LIB=$(LIB)
	$(LINK) @<<$(O)maxedit.lrf
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
	$(RC) -31 -v -K $(O)maxedit.res $@


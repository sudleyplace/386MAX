#' $Header:   P:/PVCS/MAX/MAXSETUP/SETUP.MAV   1.19   02 Jun 1997 13:41:46   BOB  $
#
# Build the SETUP executable file

!include $(MAXROOT)include\maxnames.mak

OEM=ret 		# default OEM
OBJ=W$(WIN)
O=$(OEM)\$(OBJ)\ # define include directory for OEM-specifics
L=$(MAXROOT)lib\ # .LIB directory for product-specific libraries

# Define local names / options
COMPNAME=MSC8
EXENAME=SETUP.EXE
CLEANNAME=CLEAN.EXE
MAPNAME=$(O)SETUP.MAP
DEFNAME=SETUP.DEF
MODEL=L
CMODEL=S

# Setup language and compiler macros
LINKTARG=$(O)$(EXENAME)
CBASE=/c /Fo$@ /DLANG_$(LANG)
#CFLAGS=$(CBASE) /A$(MODEL) /J /Os /Gs /GA /GEae /G2 /W3 /Zp1 /Z7
CFLAGS=$(CBASE) /A$(MODEL) /J /Os /Gs /GA /GEae /G2 /W3 /Z7
CLFLAGS=/NOD /NOE /F /A:16 /CO
LINK=$(LD) $(CLFLAGS)
COMP=$(CC) $(CFLAGS)
!IF "$(LANG)" == "US"
RCNAME=setup.rc
!ELSE
RCNAME=setup.$(LANG)
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
REFERENCEDIR=WRITEPROTECT P:\MAX\maxsetup\*
VCSDIR = P:\PVCS\MAX\maxsetup\*
ALIAS ALL P:\PVCS\MAX\maxsetup\*.*,p:\pvcs\max\maxsetup\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

DEPSCAN: setup.mak
	depscan *.c *.cpp *.rc *.asm >setup.inc

setup.mak: setup.inc $(H)makefile.inc

!include setup.inc
!include $(H)makefile.inc

$(BD)$(EXENAME): $(LINKTARG)
	xc /r $? $@

$(BD)$(CLEANNAME): $(CLINKTARG)
	xc /r $? $@

# Build SETUP.EXE

$(O)setup.obj : setup.c $(SETUP_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) setup.c

$(O)extract.obj : extract.c $(EXTRACT_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) extract.c

$(O)setupdde.obj : setupdde.c $(SETUPDDE_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) setupdde.c

$(O)serialno.obj : serialno.c $(SERIALNO_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) serialno.c

$(O)filecopy.obj : filecopy.c $(FILECOPY_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) filecopy.c

$(O)extfile.obj : extfile.c $(EXTFILE_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) extfile.c

$(O)multi.obj : multi.c $(MULTI_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) multi.c

$(O)misc.obj : misc.c $(MISC_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) misc.c

$(O)setupdif.obj : setupdif.c $(SETUPDIF_DEP)
	@Set INCLUDE=$(INCLUDE)
	$(COMP) setupdif.c

$(RCNAME):	3DCHECK.BMP	QMAX.BMP	SETUP.ICO

$(O)setup.res: $(RCNAME) $(SETUP_RCDEP)
	@Set INCLUDE=$(INCLUDE)
	$(RC) -r -fo$@ -dLANG_$(LANG) $(RCNAME)

clean.rc: $(O)clean.exe
    Bin2rc 1 clean.rc $(O)clean.exe

$(O)setupdos.exe: setupdos.c
	@Set INCLUDE=$(INCLUDE)
	@Set LIB=$(LIB)
	$(CC) /Fe$@ /Os /AS /Zd /Fm$*.map setupdos.c

$(O)clean.exe: clean.c
	@Set INCLUDE=$(INCLUDE)
	@Set LIB=$(LIB)
	$(CC) /Fe$@ /Os /AS /Fm$*.map clean.c

OBJS=$(O)setup.obj    \
     $(O)extract.obj  \
     $(O)setupdde.obj \
     $(O)setupdif.obj \
     $(O)serialno.obj \
     $(O)extfile.obj \
     $(O)multi.obj \
     $(O)filecopy.obj \
     $(O)misc.obj     \
     $(O2)implode$(MODEL).obj
LIBS=oldnames libw $(MODEL)libcew ver ddeml commdlg toolhelp shell
LIBS_EXT=ctl3ds.lib implode.lib $(L)$(MODEL)quilibr.lib

$(LINKTARG) : $(OBJS) setup.mak $(O)setup.res $(O)setupdos.exe $(O)clean.exe
	@Set LIB=$(LIB)
	$(LINK) @<<$(O)maxsetup.lrf
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
	$(RC) -31 -v -K $(O)setup.res $@


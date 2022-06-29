#
#	Makefile for QBRAND
#
#	This makefile works with MSC 6.0, LINK a la MSC 6.0, and
#	MASM 5.1
#
#' $Header:   P:/PVCS/MAX/INSTALL/QBRAND.MAV   1.1   02 Jun 1997 14:02:24   BOB  $
#

!include $(MAXROOT)include\maxnames.mak

!IF "$(COREPROD)" == "386MAX"
VER=MAXIB		# Name of directory and of .EXE to build
ASYS=0			# Set to 0 for 386MAX INSTALL, 1 for BlueMAX INSTALL,
				# 10 for 386MAX UPDATE, 11 for BlueMAX UPDATE
!ELSE
VER=BLUIB
ASYS=1
!ENDIF

PROD=SETUPDOS		# Name of product for BINDIR
MODEL=L 		# Model to use

!IF "$(MODEL)" == "M"   # Determine MASM model flag
AMODEL=MEDIUM
!ELSE
!IF "$(MODEL)" == "C"
AMODEL=COMPACT
!ELSE
!IF "$(MODEL)" == "L"
AMODEL=LARGE
!ELSE
!ERROR Model must be M, C, or L
!ENDIF
!ENDIF
!ENDIF

U=$(MAXROOT)lib\		# UI library
A=$(U)				# UI help engine library
E=$(MAXROOT)asqeng\	# Home of MULTIME.ASM
O=$(VER)\			# version specific .OBJ, .PRO, & .EXE files
G=comn\ 			# Generic .OBJ files
M=$(MAXROOT)maximize\	# MAXIMIZE directory (with POS info)
OLDINC=$(INCLUDE)		# Old INCLUDE value
ALLINC=.;$(O);$(H);$(I);$(Q);$(INCLUDE);$(M) # Search path for .C and .ASM includes
ERRPATH=$(TOOLS)		# Path for ERROUT.COM

LFLAGS=$(CVLINK) /NOD /NOI /st:8192 /map /line /far /seg:300 /ONERR:NOEXE /PackF /PackC
LAFLAGS=/DLANG_$(LANG)
!IF "$(CVER)" == ""
CVER=600
!ENDIF
!IF "$(CVER)" == "700"
OPTFLAGS=/Oslegc
CFLAGS=/W2 /A$(MODEL) /c $(OPTFLAGS) $(LAFLAGS) /Gs
LFLAGS=$(LFLAGS):64000
!ELSE
OPTFLAGS=/Oslegc
CFLAGS=/W3 /A$(MODEL) /c $(OPTFLAGS) $(LAFLAGS) /Gs /WX /FPa
!ENDIF
CVFLAGS=/Zd
CFLAGS=$(CFLAGS) $(CVFLAGS)
AFLAGS=/DMODEL=$(AMODEL) /DBETA=$(BETA) /DASYS=$(ASYS) $(LAFLAGS) /Mx /DC$(CVER) $(CVFLAGS)
AS=masm
LIBS=$(U)$(MODEL)quilibr.lib

# .LIBs we don't know the path for
!IF "$(CVER)" == "700"
GLIBS=$(MODEL)libce.lib oldnames.lib $(MODEL)help.lib implode.lib ver$(MODEL).lib
!ELSE
GLIBS=$(MODEL)libca.lib
!ENDIF

# Define LSTMAC macro to be added to the END of MASM command lines.
# Creates assembler listing in directory $(LST)
!IFDEF LST
LSTMAC=,$(LST)\$(@B)
!ELSE
LSTMAC=
!ENDIF

.c{$(G)}.obj:
	set INCLUDE=$(ALLINC)
	$(CC) /c $(CFLAGS) $(CVFLAGS) /D$(VER) /Fo$(@R).OBJ $<
	set INCLUDE=$(OLDINC)

ALL: DIR \
     $(G)qbrand.exe

DEL:
	-rm $(O)*.* $(G)*.*

DIR:
	vdir -c $(O) $(G)

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\install\*
VCSDIR = P:\PVCS\MAX\install\*
ALIAS ALL P:\PVCS\MAX\install\*.*,p:\pvcs\max\install\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

DEPSCAN: makefile
	depscan >qbrdep.inc @<<
-s$(E)=$$(E),$(M)=$$(M)
qbrand.c
<<NOKEEP

makefile:	instdep.inc $(H)makefile.inc

!include qbrdep.inc
!include $(H)makefile.inc

$(G)qbrand.exe: $(G)qbrand.obj
    @Set INCLUDE=$(INCLUDE)
    @Set LIB=$(LIB)
    $(LD) @<<$(G)qbrand.arf
	$**
	$*.exe
	$*.map
	$(MODEL)libce oldnames $(U)$(MODEL)quilibr /MAP /LINE /NOD
	NUL.DEF
<<KEEP
    mapssf -t$* $*.map


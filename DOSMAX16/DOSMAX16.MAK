#' $Header:   P:/PVCS/MAX/DOSMAX16/DOSMAX16.MAV   1.6   02 Jun 1997 15:53:48   BOB  $
# MAKEFILE for DOSMAX16.DLL and SETEWV.EXE


# Add our includes to include search path
INCLUDE = $(MAXROOT)include;$(MAXROOT)inc;$(INCLUDE)

# Get product names
!include <maxnames.mak>

L=$(MAXROOT)TEXT\	# Directory for non-built .OBJs, .LIBs, etc.
O=RET\			# ...		.OBJs, etc.
R=			# ...		source
I=$(MAXROOT)inc\	# .INC directory
H=$(MAXROOT)include\	# .H   ...

ASM=masm
AFLAGS=/Mu

ALL: DIR \
     $(O)DOSMAX16.DLL	\
     $(BD)DOSMAX16.DLL	\
     $(O)SETEWV.EXE	\
     $(BD)SETEWV.EXE

DEL:
	-rm $(O)*.*

DIR:
	@vdir -c $(O)

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\dosmax16\*
VCSDIR = P:\PVCS\MAX\dosmax16\*
ALIAS ALL P:\PVCS\MAX\dosmax16\*.*,p:\pvcs\max\dosmax16\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

CCDLL = cl -c -ASw -Gsw2 -W3 -DSTRICT -Zi -Od -Fo$(O)

{$(R)}.c{$(O)}.obj:
   @Set INCLUDE=$(INCLUDE)
   $(CCDLL) $(R)$(@B).c

###################### D O S M A X 1 6 . D L L ########################

$(O)DOSMAX16.OBJ: $(R)DOSMAX16.C $(H)DOSMAX2.H

$(O)DOSMAX16.DLL: $(O)DOSMAX16.OBJ $(R)DOSMAX16.DEF
   @Set LIB=$(LIB)
   link @<<$(O)DOSMAX16.LRF
/nod /noe /map /co $(O)DOSMAX16.OBJ $(O2)LIBENTRY.OBJ
$@
$*
libw sdllcew pifmgr
$(R)DOSMAX16.DEF
<<KEEP

$(BD)DOSMAX16.DLL:  $(O)DOSMAX16.DLL
    xc/r $(O)DOSMAX16.DLL	$(BD)DOSMAX16.DLL


################ S E T E W V #########################################

$(O)SETEWV.OBJ: 	$(R)SETEWV.ASM
	$(ASM) $(AFLAGS) $(@B) /I. /I$(I) /DDEBUG=$(DEBUG), $(O)$(@B);

LIBS=libw ver

$(O)SETEWV.EXE: 	$(O)SETEWV.OBJ
	@Set LIB=$(LIB)
	LINK /NOLOGO /NOD /PACKC:61440 /ALIGN:16 /ONERROR:NOEXE @<<$(O)SETEWV.LRF
$(O2)nocrt0+
$*
$*
$* /map
$(LIBS: =+^
)
setewv.def
<<KEEP

$(BD)SETEWV.EXE:    $(O)SETEWV.EXE
    xc/r $(O)SETEWV.EXE $(BD)SETEWV.EXE


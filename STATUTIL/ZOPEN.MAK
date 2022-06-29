# $Header:   P:/PVCS/MAX/STATUTIL/ZOPEN.MAV   1.2   30 May 1997 12:17:46   BOB  $
#
# zopen.mak : Build CZopen testbed application
#

# Default definitions overridden from the command line for builds
WIN = 16						# Version of Windows: 16, 32S, NT, 95
DEBUG = 0
BINDIR = $(MAXROOT)lib			# Where to copy .EXE and .DLL files
BD=$(BINDIR)\				# Destination

# Add our includes to include search path
INCLUDE=$(MAXROOT)include;$(INCLUDE)
!include <qpnames.mak>

# Other definitions
PROJ = ZOPENTST
PDIR = DSMGR					# Subdirectory for project
PROJPATH = $(MAXROOT)$(PDIR)\	# Directory for this project
I = $(MAXROOT)include\			# MAX includes
L = $(MAXROOT)lib\				# Catnip libraries
MODEL=L 						# Memory model to use
SYSTEM = w$(WIN)				# Four- or five-letter system abbreviation

!IF $(WIN) == 16

CPPFLAGS=/AL /GA /G2 /W3
LINKFLAGS=/STACK:18000 /ALIGN:16 /NOD /ONERROR:NOEXE /PACKC:61440

STDLIBS=llibcew

!if "$(DEBUG)" != "0"
O = $(SYSTEM)\d\				# Debug output directory
CPPFLAGS=/D_DEBUG $(CPPFLAGS) /Od /Z7
LINKFLAGS=$(LINKFLAGS) /CODEVIEW
LIBS=$(STDLIBS)
RCDEFS=/D_DEBUG
!else
O = $(SYSTEM)\nd\				# Non-debug output directory
CPPFLAGS=/DNDEBUG $(CPPFLAGS) /O1 /Z7
LINKFLAGS=$(LINKFLAGS) /CO
LIBS=$(STDLIBS)
RCDEFS=/DNDEBUG
!endif
!ELSE
!ERROR Undefined target system
!ENDIF

CPPFLAGS=$(CPPFLAGS) /Fo$(O)

OBJS_EXT=
LIBS_EXT=$(L)dzip.lib $(L)dunzip.lib $(L)$(MODEL)stutil.lib
LIBS=$(LIBS) libw

.cpp{$(O)}.obj:
	SET CL=/c $(CFLAGS) $(CPPFLAGS)
	$(CC) $<
	SET CL=

.asm{$(O)}.obj:
	SET MASM=/Zi
	masm $<,$(O);
	SET MASM=

ALL: $(BD)$(PROJ).exe

DEL:
	-rm $(O)*.*

DIR:
	vdir -c $(O)

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\dsmgr\*
VCSDIR = P:\PVCS\MAX\dsmgr\*
ALIAS ALL P:\PVCS\MAX\dsmgr\*.*,p:\pvcs\MAX\dsmgr\dsmgr.mav
<<KEEP


GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

$(O)zopentst.obj: zopentst.cpp $(I)zopen.h


#############################################################################
# file list

OBJS=$(O)zopentst.obj

$(BD)$(PROJ).EXE: $(O)$(PROJ).EXE
	copy $? $@

#############################################################################
# Final linking

$(O)$(PROJ).EXE:: DIR
	$(MAKE) -$(MAKEFLAGS) statutil.mak

$(O)$(PROJ).exe:: $(OBJS) $(OBJS_EXT) $(LIBS_EXT) \
					zopentst.def zopen.mak
	link @<<
$(OBJS: =+^
) +
$(OBJS_EXT)
$(O)$(PROJ).exe
$(O)$(PROJ).map/MAP
$(LIBS_EXT)+
$(LIBS)
zopentst.def $(LINKFLAGS)
;
<<


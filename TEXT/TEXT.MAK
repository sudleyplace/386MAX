#' $Header:   P:/PVCS/MAX/TEXT/TEXT.MAV   1.17   30 May 1997 12:22:10   BOB  $
#
# TEXT.MAK - Makefile for text in Max 8 product
#
#


# Get global definitions
!include $(MAXROOT)include\maxnames.mak

# Note: for implicit rules to work, all unusual extensions (not .ASM, .C, etc)
# must be included in this list.
.SUFFIXES: .txt .src .cfg .dll .lib .reg .hlp .inf .exe .ico .l-- .lst .t$(LANG) .trm .$(CORECODE)$(LANG) .add .pif .qpe .ico .b-- .bat .doc .win .d$(LANG) .obj .l$(LANG) .c$(LANG) .b$(LANG) .ini .ovl

# Default definitions overridden from the command line for builds
L = $(MAXROOT)lib\				# Where to copy .LIB files
QP= $(MAXROOT)QPOPUP\		# Source for QPOPUP
BINDIR=$(MAXROOT)lib		# Destination
BD=$(BINDIR)\			# Destination
B = $(BD)			# Destination

# Other definitions
PROJ = TEXT
PDIR = $(PROJ)					# Subdirectory for project
PROJPATH = $(MAXROOT)$(PDIR)\	# Directory for this project

# Product switches
PROD_MAX8 = 1					# Default = MAX 8

# Implicit rules - let NMAKE figure out how to copy them.
.cfg{$(B)}.cfg:
	copy $< $@

.src{$(B)}.cfg:
	$(CC) /DLANG_$(LANG) /EP /C $< | $(TOOLS)collapse >$@

.reg{$(B)}.reg:
	copy $< $@

.txt{$(B)}.txt:
	copy $< $@

.lib{$(L)}.lib:
	copy $< $@

.hlp{$(B)}.hlp:
	copy $< $@

.ico{$(B)}.ico:
	copy $< $@

.inf{$(B)}.inf:
	copy $< $@

.dll{$(B)}.dll:
	copy $< $@

.exe{$(B)}.exe:
	copy $< $@

.ovl{$(B)}.ovl:
	copy $< $@

.l--{$(B)}.lst:
	copy $< $@

.b--{$(B)}.bat:
	copy $< $@

.TUS{$(B)}.trm:
	copy $< $@

.d$(LANG){$(B)}.doc:
	copy $< $@

.d$(LANG){$(B)}.dll:
	copy $< $@

.l$(LANG){$(B)}.lst:
	copy $< $@

.c$(LANG){$(B)}.cfg:
	copy $< $@

.b$(LANG){$(B)}.bat:
	copy $< $@

.$(CORECODE)$(LANG){$(B)}.add:
	copy $< $@

.$(CORECODE)$(LANG){$(B)}.doc:
	copy $< $@

.$(CORECODE)$(LANG){$(B)}.lst:
	copy $< $@

.pif{$(B)}.pif:
	copy $< $@

.qpe{$(B)}.qpe:
	copy $< $@

.win{$(B)}.win:
	copy $< $@

.obj{$(L)}.obj:
	copy $< $@

.ini{$(B)}.ini:
	copy $< $@


# Get lists of filenames
!include <textname.mak>

TEXT=
!if $(PROD_MAX8)
TEXT=$(ALLTEXT) $(ALLTEXT2)
!endif

ALL:	$(TEXT) $(LIBRARIES) $(OPTLST_NET) $(OPTLST_VERCHK)

DEL:	$(TEXT)
	!del $**

DELMGR:

DIR:

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\text\*
VCSDIR = P:\PVCS\MAX\text\*
ALIAS ALL P:\PVCS\MAX\text\*.*,p:\pvcs\max\text\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

# Files needing explicit dependency
$(B)readme.: readme.$(CORECODE)$(LANG)
	xc /r $** $@

$(B)dosmax32.dll: dosmax32.d$(LANG)
	xc /r $** $@

# This one is only needed in case of lingering STRIPMGR.XUS / STRIPMGR.UUS files
$(B)stripmgr.lst: stripmgr.LUS
	xc /r $** $@

# Files requiring special assembly

$(B)386load.cfg: 386load.cfg 386load.c$(LANG)
	-rm $@
	copy 386load.c$(LANG)+386load.cfg $@

!if "$(LANG)" == "GR"
$(B)MAXHILFE.BAT:   $(B)MAXHELP.BAT
	copy $(B)MAXHELP.BAT $(B)MAXHILFE.BAT
!endif

$(B)QUALITAS.LST:   QUALITAS.LUS
	xc /r $** $@

$(B)MAXIMIZE.TRM:   MAXIMIZE.TUS
	xc /r $** $@

$(B)QPOPUP.INF:     $(QP)QPOPUP.I$(LANG)
	xc /r $** $@


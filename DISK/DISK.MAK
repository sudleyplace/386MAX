#' $Header:   P:/PVCS/MAX/DISK/DISK.MAV   1.9   30 May 1997 11:02:04   BOB  $
#
# DISK.MAK - Makefile for disk archive
#


# Default definitions overridden from the command line for builds
BINDIR = $(MAXROOT)lib			# Where to copy .EXE and .DLL files
BD=$(BINDIR)\				# Destination
DISKSIZE = 1422 				# Disk size in KB
DISKBLOCK = 512 				# Floppy disk blocking factor
DEBUG = 1						# Set to 0 for retail builds

# Add our includes to include search path
INCLUDE = $(MAXROOT)include;$(INCLUDE)

# Get product names and version
!include <maxnames.mak>

# Other definitions
PROJ = DISK
PDIR = DISK						# Subdirectory for project
PROJPATH = $(MAXROOT)$(PDIR)\	# Directory for this project
ARCHIVE = $(COREPROD)			# Archive basename
DSIZEM = 144					# Disk size in MB * 100
DSIZECODE = 3					# 0 = 360, 1 = 1.2, 2 = 720, 3 = 1.44
COPY = xc /r					# COPY is a bad choice - no errorlevel
								# & DOS version dependent
O = tmpout\						# Temporary holding bin for stupid
								# compress program which can't take
								# multiple files in a list.
L = $(MAXROOT)lib\				# Where to copy .LIB files
I = $(MAXROOT)include\			# Catnip include files
D = $(BD)disk				    # Base for forming DISKn directories
D1 = $(D)1\						# Disk 1 destination
D2 = $(D)2\						# Disk 2 destination
D3 = $(D)3\						# Disk 3 destination
D4 = $(D)4\						# Disk 4 destination
D5 = $(D)5\						# Disk 5 destination
X = x:\apps\release\			# Disk making tools
BCF = x:\apps\release\bcf\		# Source directory for @*.BCF files

# Get text names
!include <textname.mak>

# Files to go on the disk.  These files need to be on the same line.
# We use UPDATE.EXE for size comparison, and use this line (with
# substitution of INSTALL for UPDATE) to copy files to the distribution
# diskette.
INSTFIL=$(ALLTEXT2)$(ALLBIN2)

# Order-dependent groups of files that need to be on disk 1
# Since the exact number of diskettes is unknown until we build the
# libraries and split them, we always put QDSEND.Z and version-check
# DLLs on diskette 1.
D1LSTA =$(INSTFIL)

D1LSTB =

D1LSTC =

D1COPY = $(D1LSTA) $(D1LSTB) $(D1LSTC)

ALL:	 DISK

DEL:
	-rm $(ARCHIVE).?

DIR:
	vdir -c $(D1)
	vdir -c $(D2)
	vdir -c $(D2)BCF
	vdir -c $(D3)
	vdir -c $(D4)
	vdir -c $(D5)

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\disk\*
VCSDIR = P:\PVCS\MAX\disk\*
ALIAS ALL P:\PVCS\MAX\disk\*.*,p:\pvcs\max\disk\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

DISK::
	-rm $(D1)*.*
	-rm $(D2)BCF\*.*
	-rm $(D2)*.*
	-rm $(D3)*.*
	-rm $(D4)*.*
	-rm $(D5)*.*

DISK:: DIR

DISK:: $(D1LSTA)

DISK:: $(D1LSTB)

DISK:: $(D1LSTC)

DISK:: _D1COPY

_D1COPY: $(D1COPY)
	!$(COPY) $** $(D1).
	-cvpack /strip $(D1)setup.exe
	-cvpack /strip $(D1)setupdos.ovl

DISK:: $(D1)$(ARCHIVE).1

DISK:: $(D2)disk2.

DISK:: $(D3)disk3.

DISK:: $(D4)disk4.

DISK:: $(D5)disk5.

DISK:: $(D1)disk1.
# Now update the most recent time / date
	ttouch archive*.tch $(D1)*.* $(VERSION)
	ttouch archive*.tch $(D2)*.* $(VERSION)
	ttouch archive*.tch $(D2)BCF\*.* $(VERSION)
	if exist $(ARCHIVE).3 ttouch archive*.tch $(D3)*.* $(VERSION)
	if exist $(ARCHIVE).4 ttouch archive*.tch $(D4)*.* $(VERSION)
	if exist $(ARCHIVE).5 ttouch archive*.tch $(D5)*.* $(VERSION)

DISK::
# Create a batch file to make diskettes
	echo Creating makedisk.bat components...
	type <<makedisk.p1
		@echo off
		for %%f in (a,A,b,B) do if "%%f" == "%1" goto diskok
		if not "%2" == "" goto diskok
		echo No disk or invalid drive specified.
		echo Example: %0 a
		goto end
		:diskok
		REM %2 may be a directory stem, like \clip\henry\max8\disk
		REM If so, the copy procedure is slightly different.
		if not "%2" == "" goto disk1b
		echo Put disk 1 in drive %1 and
		pause
		$(X)rm -r %1:\*.*
		$(COPY) disk1 %1:\.
		$(X)vl %1:"$(DISKLABEL) 1"
		echo Put disk 2 in drive %1 and
		pause
		$(COPY) disk2 %1:
		md %1:BCF
		$(COPY) disk2\BCF\@*.BCF %1:BCF\.
		$(X)vl %1:"$(DISKLABEL) 2"
		goto disk3

:disk1b
		$(X)rm -r %1:%21\*.*
		vdir -c %1:%21
		$(COPY) disk1 %1:%21
		$(X)rm -r %1:%22\*.*
		$(X)rm -r %1:%22\BCF\*.*
		vdir -c %1:%22\BCF\*.*
		$(COPY) disk2 %1:%22
		$(COPY) disk2\BCF\@*.BCF %1:%22\BCF\.
		goto disk3

:disk3
<<KEEP
	type <<makedisk.tmp

<<KEEP
	copy makedisk.tmp *.p4
	copy makedisk.tmp *.p5
	type <<makedisk.p3
		if not "%2" == "" goto disk3b
		echo Put disk 3 in drive %1 and
		pause
		$(COPY) disk3 %1:\.
		$(X)vl %1:"$(DISKLABEL) 3"
		goto disk4

:disk3b
		$(X)rm -r %1:%23\*.*
		vdir -c %1:%23
		$(COPY) disk3 %1:%23
		goto disk4

:disk4
<<KEEP
	type <<makedisk.p4
		if not "%2" == "" goto disk4b
		echo Put disk 4 in drive %1 and
		pause
		$(COPY) disk4 %1:
		$(X)vl %1:"$(DISKLABEL) 4"
		goto disk5

:disk4b
		$(X)rm -r %1:%24\*.*
		vdir -c %1:%24
		$(COPY) disk4 %1:%24
		goto disk5

:disk5
<<KEEP
	type <<makedisk.p5
		if not "%2" == "" goto disk5b
		echo Put disk 5 in drive %1 and
		pause
		$(COPY) disk5 %1:
		$(X)vl %1:"$(DISKLABEL) 5"
		goto end

:disk5b
		$(X)rm -r %1:%25\*.*
		vdir -c %1:%25
		$(COPY) disk5 %1:%25
		goto end
<<KEEP
	if not exist $(ARCHIVE).3 copy makedisk.tmp *.p3
	if not exist $(ARCHIVE).4 copy makedisk.tmp *.p4
	if not exist $(ARCHIVE).5 copy makedisk.tmp *.p5
	type <<makedisk.pz
:end
<<KEEP
	echo Creating $(BD)makedisk.bat
	copy makedisk.p1+makedisk.p3+makedisk.p4+makedisk.p5+makedisk.pz $(BD)makedisk.bat
	-rm makedisk.tmp makedisk.p?

$(D1)$(ARCHIVE).1: $(ARCHIVE).1
	$(COPY) $? $@
	$(COPY) $(ARCHIVE).2 $(D2).
	$(COPY) $(BCF)@*.BCF $(D2)BCF\.
	if exist $(ARCHIVE).3 $(COPY) $(ARCHIVE).3 $(D3).
	if exist $(ARCHIVE).4 $(COPY) $(ARCHIVE).4 $(D4).
	if exist $(ARCHIVE).5 $(COPY) $(ARCHIVE).5 $(D5).



$(D1)disk1.:: disk.mak $(ARCHIVE).1
	echo Two: <<$(D1)disk1.
2
<<KEEP
	if exist $(ARCHIVE).3 $(COPY) $(D3)disk3. $(D1)disk1.
	if exist $(ARCHIVE).4 $(COPY) $(D4)disk4. $(D1)disk1.
	if exist $(ARCHIVE).5 $(COPY) $(D5)disk5. $(D1)disk1.

$(D2)disk2.:: disk.mak
	echo <<$(D2)disk2.
2
<<KEEP

$(D3)disk3.:: disk.mak
	echo <<$(D3)disk3.
3
<<KEEP

$(D4)disk4.:: disk.mak
	echo <<$(D4)disk4.
4
<<KEEP

$(D5)disk5.:: disk.mak
	echo <<$(D5)disk5.
5
<<KEEP

_ARCHIVE: $(ALLTEXT) $(ALLBIN)
	!$(COPY) $** $(O).
# Save most recent date
	dir <<archive.tch
Most recent date for binaries
<<KEEP
	ttouch $(O)*.* archive.tch $(VERSION)
# Strip symbols
	-for %f in ($(O)*.exe) do cvpack /strip %f
	-for %f in ($(O)*.dll) do cvpack /strip %f
	-for %f in ($(O)*.drv) do cvpack /strip %f
# Restore touch date / time
	ttouch archive.tch $(O)*.* $(VERSION)
# Copy the files back to the source as that's where PACKAGE.CFG gets them
	$(COPY) $(O). $(BD).

_VERCHK: $(ALLTEXT2)
	!$(COPY) $** $(O)verchk
# We do NOT want to touch these as they're not our files.

_DELETE:
	-if exist $@ del $@
	-rm -r $(O)*.*
	-rm $(ARCHIVE).1 $(ARCHIVE).2 $(ARCHIVE).3 $(ARCHIVE).4 $(ARCHIVE).5 $(ARCHIVE).6
	vdir -c $(O) $(O)verchk

!IF "$(CORECODE)" == "U"
!Error Handle BCFs
!ENDIF

!IF "$(CORECODE)" == "V"
!Error Handle Move'em
!ENDIF

# Define complete dependent list
!IF "$(CORECODE)" == "U"
ALLFIL= $(ALLTEXT)	$(ALLBIN) $(BLUFIL)	$(ALLTEXT2) $(ALLBIN2)
!ELSE
ALLFIL= $(ALLTEXT)	$(ALLBIN)			$(ALLTEXT2) $(ALLBIN2)
!ENDIF

dtemp1.bat: disk.mak
	echo <<dtemp1.bat
@echo off
if "%3" == "$(COREPROD)%2.1" goto nopause
echo Insert disk for %3 and
pause
:nopause
volfilt $(X)vl %1 $(COREPROD) $(VER) >dtemp2.bat
call dtemp2
echo on
$(X)xc /r/v %3 %1:$(COREPROD).*
$(X)ntouch %1:*.* $(VER)
$(X)fmode %1:*.* /n
$(X)ff %1:
<<KEEP


package.cfg: disk.mak $(I)textname.mak $(ALLFIL) dtemp1.bat
	echo Building input file for archive builder
	@echo <<package.cfg
; This package.cfg created by disk.mak
; For further information on this file's format, see the original
; PACKAGE.CFG in p:\max\disk (package.doc).

; DO NOT make changes to this file; make changes to p:\max\disk\disk.mak
; using PVCS.

; Define disk capacity (formatted) in KB, 20-char (max) description, extension
; Note that the order of this list MUST NOT CHANGE.
DISK=360 ,360k byte 5.25",360
DISK=1213,1.2m byte 5.25",120
DISK=730,720k byte 3.5",720
DISK=1457,1.44m byte 3.5",144

; Add Version to .cfg to set the time on the files.
VERTIME=$(VER)

; List of files to put on diskette besides archive.  We use UPDATE.EXE
; because it's always slightly bigger than INSTALL.
INSTALL LIST
$(INSTFIL: =^
)
ENDL

; Product identifier, filename prefix, attribute bit
PRODUCT=386MAX,MAX,1
$(ALLBIN: =^
)
$(ALLTEXT: =^
)
ENDP			; End of product files for $(386MAX)

PRODUCT=BLUEMAX,BLU,2
$(ALLBIN: =^
)
$(ALLTEXT: =^
)
ENDP			; End of product files for $(BLUEMAX)

PRODUCT=MOVEM,MOV,4
$(ALLBIN: =^
)
ENDP			; End of product files for $(MOVEM)

; List of files common to all products
COMMON=MOVEM,386MAX,BLUEMAX
$(ALLCOMN: =^
)
ENDC			; End of common files

END			; End of PACKAGE.CFG

<<KEEP
	echo Done. (FIXME build batch files to copy diskettes)

$(ARCHIVE).1:: _DELETE

$(ARCHIVE).1:: _ARCHIVE _VERCHK

$(ARCHIVE).1:: package.cfg
	echo Compressing archive...
	-rm $(COREEXT)$(DSIZEM).?
	package /d=$(DSIZECODE) /p=$(COREPROD)
	xc /m/r $(COREEXT)$(DSIZEM).? $*.?

!if 0
_ARCHIV2: $(OPTLST) $(OPTLST_NET)
	!$(COPY) $** $(O).
# Save most recent date
	dir <<archive2.tch
Most recent date for optional binaries
<<KEEP
	ttouch $(O)*.* archive2.tch $(VERSION)
# Strip symbols
	-for %f in ($(O)*.exe) do cvpack /strip %f
	-for %f in ($(O)*.dll) do cvpack /strip %f
	-for %f in ($(O)*.drv) do cvpack /strip %f
# Restore touch date / time
	ttouch archive2.tch $(O)*.* $(VERSION)

_VERCHK2:

_DELETE2:
	-if exist $@ del $@
	-rm -r $(O)*.*
	vdir -c $(O) $(O)verchk

QDSEND.Z:: _DELETE2

QDSEND.Z:: _ARCHIV2 _VERCHK2 $(I)textname.mak
	ff/*/c	 $(O)*.* >file2.lst
	-rm -f $@
	compress -i -c $(O)*.* $@
	-rm -r $(O)*.*
!endif


# $Header:   P:/PVCS/MAX/INC/INC.MAV   1.0   05 Sep 1995 13:27:50   HENRY  $
#
# INC.MAK - Makefile for Qualitas MAX includes (MASM)
#
#


# Default definitions overridden from the command line for builds
BINDIR = $(MAXROOT)lib\			# Where to copy .EXE and .DLL files

# Other definitions
PROJ = INC
PDIR = $(PROJ)					# Subdirectory for project
PROJPATH = $(MAXROOT)$(PDIR)\	# Directory for this project

ALL:

DEL:

DIR:

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\inc\*
VCSDIR = P:\PVCS\MAX\inc\*
ALIAS ALL P:\PVCS\MAX\inc\*.*,p:\pvcs\max\inc\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)


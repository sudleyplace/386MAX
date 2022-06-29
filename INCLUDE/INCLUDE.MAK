# $Header:   P:/PVCS/MAX/INCLUDE/INCLUDE.MAV   1.0   05 Sep 1995 13:29:30   HENRY  $
#
# INCLUDE.MAK - Makefile for Qualitas MAX includes
#
#


# Default definitions overridden from the command line for builds
BINDIR = $(MAXROOT)lib\			# Where to copy .EXE and .DLL files

# Other definitions
PROJ = INCLUDE
PDIR = $(PROJ)					# Subdirectory for project
PROJPATH = $(MAXROOT)$(PDIR)\	# Directory for this project

ALL:

DEL:

DIR:

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\include\*
VCSDIR = P:\PVCS\MAX\include\*
ALIAS ALL P:\PVCS\MAX\include\*.*,p:\pvcs\max\include\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)


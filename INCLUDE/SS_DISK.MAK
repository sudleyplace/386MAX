# $Header:   P:/PVCS/MAX/INCLUDE/SS_DISK.MAV   1.1   23 May 1996 13:28:20   HENRY  $
#
# SS_DISK.MAK - Files to go in SysSaver archive and on the disk
#
# Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.
#
# This file contains the complete list of files to go in the .ZIP
# file and files to be copied directly onto the distribution disk.
# It is used by GSETUP.MAK (when invoked with the DISK target).
#
# NOTE: Spaces _are_ significant.  Ending a line with backslash
# replaces the line break and any tabs and /or spaces with a single
# space when the macro is expanded.  This is important when using
# $(macro: =exp); unexpected spaces can cause trouble.
#
# There are a lot of macros defined here for a small number of
# values, but their usage is significant.  SS_TEXT and SS_TEXT2
# comprise the entire set of files from $(MAXROOT)text that may
# need copying to $(BINDIR).  SS_DISK defines what goes on the
# disk and may include things we build as well as files from
# $(MAXROOT)text.  SS_ZIP defines what goes in the .ZIP file
# main directory.  SS_ZIPSYS defines what goes in the .ZIP file
# VER\ directory.  Unlike SS_TEXT2, it may contain files we
# build.
#
# SS_TEXT and SS_TEXT2 are used by $(MAXROOT)text\text.mak, and
# will confuse the makefile if they contain any files we are
# supposed to build.

# Volume label for distribution disk
SS_LABEL=SysSaver

# DLLs we need to have on diskette and in version check directory
SS_DISKCTLV=$(BINDIR)dunzip.dll\
	$(BINDIR)muscroll.dll

# DLLs and other files we copy from TEXT project and are needed to build
# .ZIP file
SS_TEXT=$(SS_DISKCTLV)

# Files to go on actual disk, including .ZIP file
SS_DISK=$(BINDIR)ss_set.exe\
	$(BINDIR)ss_set.hlp\
	$(BINDIR)ss_set.zip\
	$(SS_DISKCTLV)

# Files to go in .ZIP file for extraction to our directory
SS_ZIP=$(BINDIR)syssav16.exe

# Version check DLLs we copy from TEXT project
SS_TEXT2=$(BINDIR)ctl3dv2.dll\
	$(BINDIR)dzip.dll\
	$(SS_DISKCTLV)

# Files to go in .ZIP file for version check and (conditional)
# extraction to Windows system directory.
SS_ZIPSYS=$(SS_TEXT2)


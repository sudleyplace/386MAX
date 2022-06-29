#' $Header:   P:/PVCS/MAX/INCLUDE/MAXNAMES.MAV   1.11   05 Jun 1998 13:22:16   BOB  $
#
# MAXNAMES.MAK - Product names and global definitions for MAX 8
#
# Copyright (C) 1995-98 Qualitas, Inc.	All rights reserved
#

# Global Win16 / Win32 definitions
WIN = 16

# Define MSVC based on either $(MSVC16) or $(MSVC32) as appropriate
!if "$(WIN)" == "32"
!if "$(MSVC32)" == ""
!error MSVC32 not defined.
!endif
MSVC = $(MSVC32)
!else
!if "$(MSVC16)" == ""
!error MSVC16 not defined.
!endif
MSVC = $(MSVC16)
!endif

# Define PATH, INCLUDE and LIB.  If there's anything else we need, it should
# already be in the appropriate directory.  This is important to keep
# build integrity.
# Note that setting INCLUDE= makes it available to all child environments.
INCLUDE = $(MAXROOT)include;$(MAXROOT)inc;$(MSVC)include;$(MSVC)mfc\include;.
LIB = $(MSVC)lib;$(MSVC)mfc\lib;$(MAXROOT)lib
PATH = $(MSVC)bin;$(PATH)

# Define tools to use
CC = $(MSVC)bin\cl
CC16 = $(MSVC16)bin\cl
CC32 = $(MSVC32)bin\cl
CPP = $(CC)
RC = $(MSVC)bin\rc
RC16 = $(MSVC16)bin\rc
RC32 = $(MSVC32)bin\rc
LD = $(MSVC)bin\link
LD16 = $(MSVC16)bin\link
LD32 = $(MSVC32)bin\link
LIBUTIL = $(MSVC)bin\lib
LIB16UTIL = $(MSVC16)bin\lib
LIB32UTIL = $(MSVC32)bin\lib
AS = $(MAXROOT)tools\masm
AS6 = $(MAXROOT)tools\ml6
B2R = $(MAXROOT)tools\bin2rc

# Product version, major and minor combined as 1.0 = 100, 1.01 = 101,
# 2.15 = 215, etc.
VERSION = 803

# Define global defaults
LANG=US 		# US or GR
BETA=0			# 1 to include beta numbering
NET=p:\max\		# MAXROOT on network (overridden by top-level makefile)

# Define include directories
# --- These should not be overridden as they are hardwired into DEPSCAN ---
I = $(MAXROOT)inc\	# MASM .INC files
I2= $(MAXROOT)INC\	# External .INC files
H = $(MAXROOT)include\	# .H, .MAK, and some .INC files
Q = $(MAXROOT)386max\	# 386MAX-specific .INC files
O2= $(MAXROOT)lib\	# External .OBJ files
B = $(MAXROOT)lib\	# BINDIR target
BD= $(MAXROOT)lib\	# BINDIR target

!IF "$(CORECODE)" == ""
CORECODE=X			# X or U or V
!ENDIF
!IF "$(CORECODE)" == "X"
COREPROD=386MAX 	# 386MAX or BLUEMAX or MOVEM
DISKLABEL=QMAX8
COREEXT=MAX
COREBITS=1
!IF "$(BETA)" == "1"
COREEXBASE=BET
!ELSE
COREEXBASE=RET
!ENDIF
!ELSEIF "$(CORECODE)" == "U"
COREPROD=BLUEMAX
DISKLABEL=BlueMAX8
COREEXT=BLU
COREBITS=2
!IF "$(BETA)" == "1"
COREEXBASE=BLB
!ELSE
COREEXBASE=BLU
!ENDIF
!ELSEIF "$(CORECODE)" == "V"
COREPROD=MOVEM
COREEXT=MOV
COREBITS=4
!IF "$(BETA)" == "1"
COREEXBASE=MOB
!ELSE
COREEXBASE=MOV
!ENDIF
!ELSE
!ERROR Invalid CORECODE value (Use X, U, or V)
!ENDIF

BINDIR=$(MAXROOT)lib\	# Default output directory
TOOLS=$(MAXROOT)tools\	# Essential tools for build (not part of SDK)
BCF=$(MAXROOT)text\		# Directory where BCFs live
CVER=700


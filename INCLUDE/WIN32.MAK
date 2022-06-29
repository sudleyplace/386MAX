# =========================================================================
# NTWIN32.MAK - Win32 application master NMAKE definitions file for the
#               Microsoft Win32 SDK for Windows NT programming samples
# -------------------------------------------------------------------------
# This files should be included at the top of all MAKEFILEs as follows:
#  !include <ntwin32.mak>
# -------------------------------------------------------------------------
# NMAKE Options
#
# Use the table below to determine the additional options for NMAKE to
# generate various application debugging, profiling and performance tuning
# information.
#
# Application Information Type         Invoke NMAKE
# ----------------------------         ------------
# For No Debugging Info                nmake nodebug=1
# For Working Set Tuner Info           nmake tune=1
# For Call Attributed Profiling Info   nmake profile=1
#
# Note: Working Set Tuner and Call Attributed Profiling is for available
#       for the Intel x86 and Pentium systems.
#
# Note: The three options above are mutually exclusive (you may use only
#       one to compile/link the application).
#
# Note: creating the environment variables NODEBUG, TUNE, and PROFILE is an
#       alternate method to setting these options via the nmake command line.
#
# Additional NMAKE Options             Invoke NMAKE
# ----------------------------         ------------
# For No ANSI NULL Compliance          nmake no_ansi=1
# (ANSI NULL is defined as PVOID 0)
#
# =========================================================================

!IFNDEF _WIN32_MAK_
_WIN32_MAK_ = 1

# -------------------------------------------------------------------------
# Get CPU Type - exit if CPU environment variable is not defined
# -------------------------------------------------------------------------

!IF "$(CPU)" == ""
CPU = i386
!ENDIF

# Intel i386, i486, and Pentium systems
!IF "$(CPU)" == "i386"
CPUTYPE = 1
!ENDIF

# MIPS R4x000 systems
!IF "$(CPU)" == "MIPS"
CPUTYPE = 2
!ENDIF

# Digital Alpha AXP systems
!IF "$(CPU)" == "ALPHA"
CPUTYPE = 3
!ENDIF

# PPC systems
!IF "$(CPU)" == "PPC"
CPUTYPE = 4
!ENDIF

!IFNDEF CPUTYPE
!ERROR  Must specify CPU environment variable ( CPU=i386, CPU=MIPS, CPU=ALPHA, CPU=PPC)
!ENDIF

# -------------------------------------------------------------------------
# Get Target Operating System - Default to both
# -------------------------------------------------------------------------
!IFNDEF TARGETOS
TARGETOS = BOTH
!ENDIF

!IF "$(TARGETOS)" != "WINNT"
!IF "$(TARGETOS)" != "WIN95"
!IF "$(TARGETOS)" != "BOTH"
!ERROR Must specify TARGETOS environment variable (BOTH, WIN95, WINNT)
!ENDIF
!ENDIF
!ENDIF

# -------------------------------------------------------------------------
# Set Default WINVER - depends on TARGETOS
#
# Defaults to 4.0 for all applications except NT specific.
# -------------------------------------------------------------------------

!IFNDEF APPVER
!IF "$(TARGETOS)" == "WINNT"
APPVER = 3.10
!ELSE
APPVER = 4.0
!ENDIF
!ENDIF
    
!IF "$(APPVER)" != "4.0"
!IF "$(APPVER)" != "3.10"
!ERROR Must specify APPVER environment variable (4.0, 3.10)
!ENDIF
!ENDIF

# binary declarations common to all platforms
cc     = cl
rc     = rc
link   = link
implib = lib

!IF "$(TARGETOS)" == "WIN95"
hc = hcw
!ELSE
hc = hc
!ENDIF

# for compatibility with older-style makefiles
cvtobj = REM !!! CVTOBJ is no longer necessary - please remove !!!
cvtres = REM !!! CVTRES is no longer necessary - please remove !!!


# -------------------------------------------------------------------------
# Platform Dependent Compile Flags - must be specified after $(cc)
#
# Note: Debug switches are on by default for current release
#
# These switches allow for source level debugging with WinDebug for local
# and global variables.
#
# Both compilers now use the same front end - you must still define either
# _X86_, _MIPS_, _PPC_ or _ALPHA_.  These have replaced the i386, MIPS, and ALPHA
# definitions which are not ANSI compliant.
#
# Common compiler flags:
#   -c   - compile without linking
#   -W3  - Set warning level to level 3
#   -Zi  - generate debugging information
#   -Od  - disable all optimizations
#   -Ox  - use maximum optimizations
#   -Zd  - generate only public symbols and line numbers for debugging
#
# i386 specific compiler flags:
#   -Gz  - stdcall
#
# MS MIPS specific compiler flags:
#   none.
#
# -------------------------------------------------------------------------

# declarations common to all compiler options
ccommon = -c -W3 -Dtry=__try -Dexcept=__except -Dleave=__leave -Dfinally=__finally -DCRTAPI1=_cdecl -DCRTAPI2=_cdecl -nologo

!IF "$(CPU)" == "i386"
cflags = $(ccommon) -D_X86_=1
scall  = -Gz
!ELSE
!IF "$(CPU)" == "MIPS"
cflags = $(ccommon) -D_MIPS_=1
!ELSE
!IF "$(CPU)" == "PPC"
cflags = $(ccommon) -D_PPC_=1
!ELSE
!IF "$(CPU)" == "ALPHA"
cflags = $(ccommon) -D_ALPHA_=1
!ENDIF
!ENDIF
!ENDIF
scall  =
!ENDIF

!IF "$(TARGETOS)" == "WINNT"
INCLUDE = $(MSTOOLS)\h\winnt;$(INCLUDE)
LIB = $(MSTOOLS)\lib\winnt;$(LIB)
cflags = $(cflags) -D_WINNT
!ELSE
!IF "$(TARGETOS)" == "WIN95"
INCLUDE = $(MSTOOLS)\h\win95;$(INCLUDE)
LIB = $(MSTOOLS)\lib\win95;$(LIB)
cflags = $(cflags) -D_WIN95
!ENDIF
!ENDIF

cflags4 = $(cflags) -DWINVER=0x0400
!IF "$(APPVER)" == "4.0"
cflags = $(cflags) -DWINVER=0x0400
!ELSE
cflags = $(cflags) -DWINVER=0x030A
!ENDIF

!IFDEF NODEBUG
cdebug = -Ox
!ELSE
!IFDEF PROFILE
!IF "$(CPU)" == "MIPS"
cdebug = -Gh -Zd -Od
!ELSE
cdebug = -Gh -Zd -Ox
!ENDIF
!ELSE
!IFDEF TUNE
cdebug = -Gh -Zd -Ox
!ELSE
cdebug = -Z7 -Od
!ENDIF
!ENDIF
!ENDIF

# -------------------------------------------------------------------------
# Target Module & Subsystem Dependent Compile Defined Variables - must be
#   specified after $(cc)
#
# The following table indicates the various acceptable combinations of
# the C Run-Time libraries LIBC, LIBCMT, and CRTDLL respect to the creation
# of a EXE and/or DLL target object.  The appropriate compiler flag macros
# that should be used for each combination are also listed.
#
#  Link EXE    Create Exe    Link DLL    Create DLL
#    with        Using         with         Using
# ----------------------------------------------------
#  LIBC        CVARS          None        None      *
#  LIBC        CVARS          LIBC        CVARS
#  LIBC        CVARS          LIBCMT      CVARSMT
#  LIBCMT      CVARSMT        None        None      *
#  LIBCMT      CVARSMT        LIBC        CVARS
#  LIBCMT      CVARSMT        LIBCMT      CVARSMT
#  CRTDLL      CVARSDLL       None        None      *
#  CRTDLL      CVARSDLL       LIBC        CVARS
#  CRTDLL      CVARSDLL       LIBCMT      CVARSMT
#  CRTDLL      CVARSDLL       CRTDLL      CVARSDLL  *
#
# * - Denotes the Recommended Configuration
#
# When building single-threaded applications you can link your executable
# with either LIBC, LIBCMT, or CRTDLL, although LIBC will provide the best
# performance.
#
# When building multi-threaded applications, either LIBCMT or CRTDLL can
# be used as the C-Runtime library, as both are multi-thread safe.
#
# Note: Any executable which accesses a DLL linked with CRTDLL.LIB must
#       also link with CRTDLL.LIB instead of LIBC.LIB or LIBCMT.LIB.
#       When using DLLs, it is recommended that all of the modules be
#       linked with CRTDLL.LIB.
#
# Note: The macros of the form xDLL are used when linking the object with
#       the DLL version of the C Run-Time (that is, CRTDLL.LIB).  They are
#       not used when the target object is itself a DLL.
#
# -------------------------------------------------------------------------

!IFDEF NO_ANSI
noansi = -DNULL=0
!ENDIF

# for Windows applications that use the C Run-Time libraries
cvars      = -DWIN32 $(noansi) -D_WIN32
cvarsmt    = $(cvars) -D_MT
cvarsdll   = $(cvarsmt) -D_DLL

# for compatibility with older-style makefiles
cvarsmtdll   = $(cvarsmt) -D_DLL

# for POSIX applications
psxvars    = -D_POSIX_

# resource compiler
rcflags = /r
rcvars = -DWIN32 -D_WIN32 $(noansi)

!IF "$(APPVER)" == "4.0"
rcvars = $(rcvars) -DWINVER=0x0400
!else
rcvars = $(rcvars) -DWINVER=0x030A
!ENDIF

# -------------------------------------------------------------------------
# Platform Dependent Link Flags - must be specified after $(link)
#
# Note: $(DLLENTRY) should be appended to each -entry: flag on the link
#       line.
#
# Note: When creating a DLL that uses C Run-Time functions it is
#       recommended to include the entry point function of the name DllMain
#       in the DLL's source code.  Also, the MAKEFILE should include the
#       -entry:_DllMainCRTStartup$(DLLENTRY) option for the creation of
#       this DLL.  (The C Run-Time entry point _DllMainCRTStartup in turn
#       calls the DLL defined DllMain entry point.)
#
# -------------------------------------------------------------------------

# declarations common to all linker options
lcommon = /NODEFAULTLIB /INCREMENTAL:NO /PDB:NONE /RELEASE /NOLOGO

# declarations for use on Intel i386, i486, and Pentium systems
!IF "$(CPU)" == "i386"
DLLENTRY = @12
lflags   = $(lcommon) -align:0x1000
!ENDIF

# declarations for use on self hosted MIPS R4x000 systems
!IF "$(CPU)" == "MIPS"
DLLENTRY =
lflags   = $(lcommon)
!ENDIF

# declarations for use on self hosted PowerPC systems
!IF "$(CPU)" == "PPC"
DLLENTRY =
lflags   = $(lcommon)
!ENDIF

# declarations for use on self hosted Digital Alpha AXP systems
!IF "$(CPU)" == "ALPHA"
DLLENTRY =
lflags   = $(lcommon)
!ENDIF

# -------------------------------------------------------------------------
# Target Module Dependent Link Debug Flags - must be specified after $(link)
#
# These switches allow the inclusion of the necessary symbolic information
# for source level debugging with WinDebug, profiling and/or performance
# tuning.
#
# Note: Debug switches are on by default.
# -------------------------------------------------------------------------

!IFDEF NODEBUG
ldebug = /RELEASE
!ELSE
!IFDEF PROFILE
ldebug = -debug:mapped,partial -debugtype:coff
!ELSE
!IFDEF TUNE
ldebug = -debug:mapped,partial -debugtype:coff
!ELSE
ldebug = -debug:full -debugtype:cv
!ENDIF
!ENDIF
!ENDIF

# for compatibility with older-style makefiles
linkdebug = $(ldebug)

# -------------------------------------------------------------------------
# Subsystem Dependent Link Flags - must be specified after $(link)
#
# These switches allow for source level debugging with WinDebug for local
# and global variables.  They also provide the standard application type and
# entry point declarations.
# -------------------------------------------------------------------------

# for Windows applications that use the C Run-Time libraries
conlflags = $(lflags) -subsystem:console -entry:mainCRTStartup
guilflags = $(lflags) -subsystem:windows,$(APPVER) -entry:WinMainCRTStartup
dlllflags = $(lflags) -entry:_DllMainCRTStartup$(DLLENTRY) -dll

# for Windows applications which require 4.0 level API support
guilflags4 = $(lflags) -subsystem:windows,4 -entry:WinMainCRTStartup

# for POSIX applications
psxlflags = $(lflags) -subsystem:posix -entry:__PosixProcessStartup

# for compatibility with older-style makefiles
conflags  = $(conlflags)
guiflags  = $(guilflags)
psxflags  = $(psxlflags)

# -------------------------------------------------------------------------
# C Run-Time Target Module Dependent Link Libraries
#
# Below is a table which describes which libraries to use depending on the
# target module type, although the table specifically refers to Graphical
# User Interface apps, the exact same dependencies apply to Console apps.
# That is, you could replace all occurrences of 'GUI' with 'CON' in the
# following:
#
# Desired CRT  Libraries   Desired CRT  Libraries
#   Library     to link      Library     to link
#   for EXE     with EXE     for DLL     with DLL
# ----------------------------------------------------
#   LIBC       GUILIBS       None       None       *
#   LIBC       GUILIBS       LIBC       GUILIBS
#   LIBC       GUILIBS       LIBCMT     GUILIBSMT
#   LIBCMT     GUILIBSMT     None       None       *
#   LIBCMT     GUILIBSMT     LIBC       GUILIBS
#   LIBCMT     GUILIBSMT     LIBCMT     GUILIBSMT
#   CRTDLL     GUILIBSDLL    None       None       *
#   CRTDLL     GUILIBSDLL    LIBC       GUILIBS
#   CRTDLL     GUILIBSDLL    LIBCMT     GUILIBSMT
#   CRTDLL     GUILIBSDLL    CRTDLL     GUILIBSDLL *
#
# * - Recommended Configurations.
#
# Note: Any executable which accesses a DLL linked with CRTDLL.LIB must
#       also link with CRTDLL.LIB instead of LIBC.LIB or LIBCMT.LIB.
#
# Note: For POSIX applications, link with $(psxlibs).
#
# -------------------------------------------------------------------------

# These CRT Libraries assume the use of Microsoft Visual C++ 2.0 on
# x86 and MIPS platforms.  If you are using another Compiler product,
# change the libc* variable to correspond to your import library names.

!IF "$(CPU)" == "PPC"
libc = libc.lib
libcmt = libcmt.lib
libcdll = crtdll.lib

# for POSIX applications
psxlibs    = libcpsx.lib psxdll.lib psxrtl.lib

!ELSE
libc = libc.lib oldnames.lib
libcmt = libcmt.lib oldnames.lib
libcdll = msvcrt.lib oldnames.lib

# for POSIX applications
psxlibs    = libcpsx.lib psxdll.lib psxrtl.lib oldnames.lib

!ENDIF

# optional profiling and tuning libraries
!IFDEF PROFILE
optlibs = cap.lib
!ELSE
!IFDEF TUNE
optlibs = wst.lib
!ELSE
optlibs =
!ENDIF
!ENDIF

# The PPC compiler currently requires a library for 64-bit integers.
!IF "$(CPU)" == "PPC"
int64lib = int64.lib
!ELSE
int64lib =
!ENDIF


# basic subsystem specific libraries, less the C Run-Time
baselibs   = kernel32.lib $(optlibs) advapi32.lib
winlibs    = $(baselibs) user32.lib gdi32.lib comdlg32.lib winspool.lib

# for Windows applications that use the C Run-Time libraries
conlibs    = $(libc) $(baselibs)
conlibsmt  = $(libcmt) $(baselibs)
conlibsdll = $(libcdll) $(baselibs)
guilibs    = $(libc) $(winlibs)
guilibsmt  = $(libcmt) $(winlibs)
guilibsdll = $(libcdll) $(winlibs)

# for OLE applications
olelibs      = ole32.lib uuid.lib oleaut32.lib $(guilibs)
olelibsmt    = ole32.lib uuid.lib oleaut32.lib $(guilibsmt)
olelibsdll   = ole32.lib uuid.lib oleaut32.lib $(guilibsdll)

# for backward compatibility
ole2libs    = $(olelibs)
ole2libsmt  = $(olelibsmt)
ole2libsdll = $(olelibsdll)

#ENDIF _WIN32_MAK_
!ENDIF 

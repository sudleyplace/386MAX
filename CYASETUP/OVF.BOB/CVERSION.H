// $Header:   P:/PVCS/MAX/CYASETUP/CVERSION.H_V   1.14   05 May 1997 11:07:56   PETERJ  $
//
// CVERSION.H - component version info file
//
// ---------------------------------------------------------
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3
// ---------------------------------------------------------
#include <_lcldefs.h>					// Define BUILD_BETA, BUILD_ALPHA

    // Version resource definitions from DDK
#ifdef _WIN32
    #include <winver.h>			
#else
    #include <ver.h>			
#endif

#define VER_MODULE		          14
#define VER_MODULE_STR			"014"

#define VER_FILETYPE			VFT_APP
#define VER_FILESUBTYPE 		VFT2_UNKNOWN
#define VER_FILEDESCRIPTION_STR 	"Qualitas C.Y.A. Setup"
#define VER_INTERNALNAME_STR		"C.Y.A. Setup"
#define VER_ORIGINALFILENAME_STR	"CYASETUP.EXE"


// $Header:   P:/PVCS/MAX/INCLUDE/CVERSION.H_V   1.1   20 Jan 1997 08:41:08   PETERJ  $
//
// CVERSION.H - Example component version info file
//
// ---------------------------------------------------------
// Copyright (C) 1995 Qualitas, Inc.  All rights reserved
// ---------------------------------------------------------

    // Version resource definitions from DDK
#ifdef _WIN32
    #include <winver.h>			
#else
    #include <ver.h>			
#endif

#include <maxnames.h>

#define VER_MODULE					1
#define VER_MODULE_STR				"001"

#define VER_FILETYPE				VFT_APP
#define VER_FILESUBTYPE 			VFT2_UNKNOWN
#define VER_FILEDESCRIPTION_STR 	"Module description"
#define VER_INTERNALNAME_STR		"MODULE"
#define VER_ORIGINALFILENAME_STR	"MODULE.EXT"

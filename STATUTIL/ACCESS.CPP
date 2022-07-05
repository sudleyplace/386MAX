// $Header:   P:/PVCS/MAX/STATUTIL/ACCESS.CPV   1.0   04 Apr 1996 16:24:26   HENRY  $
//
// ACCESS.CPP - Windows version of C runtime _access() function
//
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3.
//

#define	STRICT
#include <windows.h>

#include <stdlib.h>
#include <io.h>

extern "C"
Access( LPCSTR lpPath, int nMode ) {

	if (!nMode) {

		OFSTRUCT of;

		return ((OpenFile( lpPath, &of, OF_EXIST ) == HFILE_ERROR) ? -1 : 0);

	} // Use OpenFile for existence check
	else {

		char szBuff[ _MAX_PATH ];

		AnsiToOem( lpPath, szBuff );

		return _access( szBuff, nMode );

	} // Convert to OEM before checking

} // Access


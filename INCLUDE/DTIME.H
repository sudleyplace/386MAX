// $Header:   P:/PVCS/MAX/INCLUDE/DTIME.H_V   1.0   04 Apr 1996 16:28:30   HENRY  $
//
// DTIME.H - DTIME definitions from CATSYM.H
//
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.
//

#ifndef _DTIME_INCLUDED
#define	_DTIME_INCLUDED

// Date/time type definitions
// Format is YYYYMMDDHHMMSS (24-hour time)
typedef char DTIME[ 14 ], *PDTIME, FAR *LPDTIME;
#define	DTIME_LEN	sizeof( DTIME)	// Length of YYYYMMDDHHMMSS
#define	DTIME_PAD	"00000000000000" // Padding for minimum working length
#define DTIME_FMTOUT "%04u%02u%02u" "%02u%02u%02u"
#define DTIME_FMTIN	"%4d%2d%2d" "%2d%2d%2d"

#define dtimecmp(d1,d2) strncmp( d1, d2, sizeof( DTIME ) )
#define _fdtimecmp(d1,d2) _fstrncmp( d1, d2, sizeof( DTIME ) )
#define _ndtimecmp(d1,d2) _nstrncmp( d1, d2, sizeof( DTIME ) )

#endif


// $Header:   P:/PVCS/MAX/INCLUDE/DRIVETYP.H_V   1.1   23 May 1996 13:27:46   HENRY  $
//
// DRIVETYP.H - Drive identification functions
//
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3.

#ifndef _DRIVETYP_INCLUDED
#define	_DRIVETYP_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

// Global function.  Returns cluster size in bytes or 0 if failed.
// Sets *lpwClustSize and *lpwSectSize.
// nDrive is 0 for default drive, 1=a:, etc.
WORD GetClustSize( WORD FAR *lpwClustSize, WORD FAR *lpwSectSize, int nDrive = 0 );

// Returns total clusters on specified drive in low word, free
// clusters in high word.  0 for default drive, 1=a:, etc.
DWORD GetFreeClust( int nDrive = 0 );

// Returns media byte or -1 if drive is invalid
int MediaByte( char drive );

#define	MEDIA_OTHER		0xf0
#define	MEDIA_HARD		0xf8
#define	MEDIA_FLOPMIN	0xf9
#define	MEDIA_FLOPMAX	0xff

// Returns drive type from DTYPE_ list
int DriveType( char drive );
enum {
	DTYPE_INVAL=0,	// Invalid drive letter
	DTYPE_FLOPPY,	// Removable
	DTYPE_CDROM,	// CD
	DTYPE_SUBST,	// Subst
	DTYPE_REMOTE,	// Network
	DTYPE_RAM,		// RAMdrive
	DTYPE_FIXED		// Hard disk
};

// Returns TRUE if drive letter ('A', 'B', 'C', etc.) is a RAM drive
BOOL IsRamDrive( char drive );

#ifdef __cplusplus
}
#endif

#endif


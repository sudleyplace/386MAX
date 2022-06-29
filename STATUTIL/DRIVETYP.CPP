// $Header:   P:/PVCS/MAX/STATUTIL/DRIVETYP.CPV   1.1   23 May 1996 13:31:08   HENRY  $
//
// DRIVETYP.CPP - Drive info functions
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//


#define	STRICT
#include <windows.h>

#include <ctype.h>
#include <stdlib.h>
#include <direct.h>

#include <drivetyp.h>

// Global function.  Returns cluster size in bytes or 0 if failed.
// Sets globals wClustSize and wSectSize.
// nDrive is 0 for default drive, 1=a:, etc.
#pragma optimize( "leg", off )
extern "C" WORD
GetClustSize( WORD FAR *lpwClustSize, WORD FAR *lpwSectSize, int nDrive /*= 0*/ ) {

	_asm {
		push ds;		// Save

		mov	dx,nDrive;	// DL = drive (0 for default)
		mov	ah,0x1c;	// Get allocation information
		int 0x21;		// AL = sects / cluster, FF if invalid drive
						// CX = bytes / sect
						// DX = total clusters
						// DS:BX ==> media ID byte
						// CF _not_ significant
		pop ds;			// Restore

		push di;		// Save

		mov	bx,0;		// Assume failure
		cmp	al,0xff;	// Is drive valid?
		je	GCS_Exit;	// Jump if not

		les	di,lpwSectSize; // Address return pointer
		mov	es:[word ptr di],cx; // Save bytes per sector

		sub	ah,ah;		// Convert byte to (unsigned) word
		mul	cx;			// DX,AX = bytes per cluster

		or	dx,dx;		// Izit bigger than 64K - 1?
		jnz	GCS_Exit;	// Jump if so

		mov	bx,ax;		// Return low word of product
		les	di,lpwClustSize; // Address return pointer
		mov	es:[word ptr di],ax; // Set global value
GCS_Exit:
		pop	di;			// Restore

		mov nDrive,bx;	// Save return value
	}

	return nDrive;

} // GetClustSize()
#pragma optimize( "", on )

// Returns total clusters on specified drive in low word, free
// clusters in high word.  0 for default drive, 1=a:, etc.
#pragma optimize( "leg", off )
extern "C" DWORD
GetFreeClust( int nDrive /*= 0*/ ) {

	DWORD dwRes = 0L;

	_asm {

		push ds;		// Save

		mov dx,nDrive;	// DL = drive or 0 for default
		mov	ah,0x36;	// Get free space
		int	0x21;		// Return AX=sect/clust, BX=free clust, CX=bytes/sect,
						// DX=total clust, CF _not_ significant

		pop	ds;			// Restore

		cmp	ax,-1;		// AX=ffff means invalid drive
		je	GFC_Exit;	// Jump if so

		mov	[word ptr dwRes+0],dx; // Total clusters in low word
		mov	[word ptr dwRes+2],bx; // Free clusters in high word
GFC_Exit:
		;
	}

	return dwRes;

} // GetFreeClust()
#pragma optimize( "", on )

// Returns media byte value if a valid drive, else -1
#pragma optimize( "leg", off )
extern "C" int
MediaByte( char drive ) {

	int res = -1;

	// Convert @ to 0, A to 1, etc.
	drive = 1 + toupper( drive ) - 'A';

	_asm {

		push ds;		// Save

		mov	ah,0x32;	// Get DPB for specific drive
		mov	dl,drive;	// Drive number
		int	0x21;		// DS:DX ==> DPB, AL=status, CF _not_ significant

		mov	dx,ds;		// Get DPB segment
		pop	ds;			// Restore

		or	al,al;		// Check status (0 if OK)
		jnz	IHD_EXIT;	// Jump if failed (invalid) or network drive

		mov	es,dx;		// Address DPB
		add	bx,0x17;	// Address media byte (DOS versions 4.0+)

		cmp	_osmajor,4;	// Izit pre-DOS 4?
		sbb	bx,0;		// Back off one byte if so

		mov	al,es:[byte ptr bx]; // Get media byte
		sub	ah,ah;		// Convert to (unsigned) word

		mov	res,ax;		// Save result
IHD_EXIT:
		;
	}

	return res;

} // MediaByte()
#pragma optimize( "", on )

// If unable to get drive info by other means, try getting current working
// directory.
int
CheckCurDir( int drive, int nRes ) {

	if (nRes == DTYPE_INVAL) {

		char szDir[ _MAX_DIR ];
		UINT wPrevErrMode = SetErrorMode( SEM_FAILCRITICALERRORS );

		if (_getdcwd( drive, szDir, sizeof( szDir ) )) {
			nRes = DTYPE_REMOTE;
		} // Got it

		SetErrorMode( wPrevErrMode );

	} // We failed

	return nRes;

} // CheckCurDir()

// Returns drive type from DTYPE_ list
#pragma optimize( "leg", off )
extern "C" int
DriveType( char drive ) {
//	DTYPE_INVAL=0,	// Invalid drive letter
//	DTYPE_FLOPPY,	// Removable
//	DTYPE_CDROM,	// CD
//	DTYPE_SUBST,	// Subst
//	DTYPE_REMOTE,	// Network
//	DTYPE_FIXED		// Hard disk

	// First try IOCTL to determine if fixed
	int IsFixed, nRes = DTYPE_INVAL;

	// Convert to A=1, etc. (@ = 0 = default drive)
	drive = toupper( drive ) - 'A' + 1;

	_asm {

		mov	bl,drive;	// Get drive number
		mov	ax,0x4408;	// IOCTL - Is drive fixed?
		int	0x21;		// CF=0 if valid, AX=1 if fixed
		jc	DRIVETYPE_EXIT; // Jump if not valid

		mov	IsFixed,ax;	// Save flag

	}

	// If not fixed, see if it's a CD-ROM
	if (!IsFixed) {

		nRes = DTYPE_FLOPPY;

		_asm {
			mov	ax,0x1500;	// Check for CD-ROM drive letters
			sub	bx,bx;
			int	0x2f;		// Return CX=start (A=0), BX=total number of drives

			or	bx,bx;		// Any CD-ROM drives?
			jz	DRIVETYPE_EXIT; // Jump if not

			or	ch,ch;		// Is the starting letter valid?
			jnz	DRIVETYPE_EXIT; // Jump if not

			inc	cx;			// Convert to origin:1

			cmp	cl,drive;	// Does it start past this drive?
			ja	DRIVETYPE_EXIT; // Jump if so

			add	cx,bx;		// Get last drive + 1
			cmp	cl,drive;	// Does it end before this drive?
			jbe	DRIVETYPE_EXIT; // Jump if so

		}

		return DTYPE_CDROM;

	} // Check for CD-ROM

	// Fixed drive - check for subst and network drives
	nRes = DTYPE_INVAL;
	WORD wBits;

	_asm {
		mov	bl,drive;	// Get drive number
		mov	ax,0x4409;	// IOCTL - Get device bits
		int	0x21;		// CF=0 if valid, DX=bits
		jc	DRIVETYPE_EXIT; // Jump if failed (???)

		mov	wBits,dx;	// Save bits for inspection

	}

	// This is used as a jump target by inline _asm code and needs
	// to be here so it's not out of range.
	if (0) {
DRIVETYPE_EXIT:
		// Try once more
		return CheckCurDir( drive, nRes );
	}

	if (wBits & 0x8000) {
		return DTYPE_SUBST;
	} // SUBST drive
	else if (wBits & 0x1000) {
		return DTYPE_REMOTE;
	} // Network drive
	else if (wBits == 0x0800 || IsRamDrive( drive + '@' )) {
		return DTYPE_RAM;
	} // RAM drive (not documented, but this should work for 386DISK and RAMDRIVE)
	else return DTYPE_FIXED;

} // DriveType()
#pragma optimize( "", on )

// Returns TRUE if drive letter ('A', 'B', 'C', etc.) is a RAM drive
#pragma optimize( "leg", off )
extern "C" BOOL
IsRamDrive( char drive ) {

	BOOL bRet = FALSE;

#pragma pack(1)
	struct {
		BYTE UseCurrentBPB:1,
			 UseTrackLayout:1,
			 _rsvd:6;
		BYTE DeviceType;	// 00 = 320K / 360K
							// 01 = 1.2MB
							// 02 = 720K
							// 03 = 8" SD
							// 04 = 8" DD
							// 05 = fixed disk
							// 06 = tape drive
							// 07 = other block device
							// 08 = read/write optical
							// 09 = 2.88M floppy
		WORD Fixed:1,	// Non-removable
			DoorLock:1,
			_rsvd2:14;
		WORD NumCylinders;
		BYTE MediaType;	// if DeviceType 01: 01 for 360K, 00 for 1.2
						// F8 for DUBLDISK, 00 for all others
		// Begin device BPB
		WORD BPS;		// Bytes per sector
		BYTE SPC;		// Sectors per cluster
		WORD ReservedSects; // Number reserved sectors at start of disk
		BYTE nFATs;		// How many FATs
		WORD nRoot;		// Number of root dir entries
		WORD TotalSects; // Total number of sectors (0 if >32MB)
		BYTE MediaID;	// FF, F8, etc.
		WORD SectsPerFAT; // Size of FAT in sectors
		WORD SectsPerTrack;
		WORD nHeads;	// Number of heads
		DWORD HiddenSectors;
		// -- DOS 4.x only --
		DWORD dwTotalSects; // Total sectors if TotalSects == 0
		BYTE _rsvd3[ 6 ];
		WORD nCylinders;
		BYTE DeviceType2; // ?? Don't know how this is related to DeviceType
		WORD wAttributes;
		BYTE _rsvd4[ 32 ]; // Extra space for growth
	} driveparms;
#pragma pack()

	// Convert to A=1, etc.
	drive = toupper( drive ) - 'A' + 1;
	int nIOCTL_supp;

	// Method 1 recommended by MS is to check the volume label.
	// Skip it for now as this could be anything.

	// Method 4 should already have been invoked before calling.
	// It is simply to check for 0x0800 returned from IOCTL 4409

	// Method 2 is to check for IOCTL subfunction 0D not supported
	// (as opposed to the driver not responding to it).
	_asm {
		push	ds;		// Save

		mov	ax,0x440d;	// Generic block IOCTL function
		mov	bl,drive;	// Drive number
		mov	cx,0x0860;	// Get drive parameters
		lea	dx,driveparms; // Address drive parameters
		int	0x21;		// Get parameters

		pop	ds;			// Restore

		mov	ax,1;		// Assume support
		sbb	ax,0;		// AX = 0 if not supported
		mov	nIOCTL_supp,ax; //

	}

	// If no support, probably a RAM drive
	if (!nIOCTL_supp) {
		return TRUE;
	} // IOCTL not supported

	// Finally, check for a single FAT
	return (driveparms.nFATs == 1);

} // IsRamDrive()
#pragma optimize( "", on )


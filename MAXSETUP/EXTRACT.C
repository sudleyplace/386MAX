// EXTRACT.C - Unzip & copy files from diskette
//   Modified for SETUP.EXE 8/95 by Rex Conn

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <direct.h>
#include <dos.h>
#include <io.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <string.h>

#include "setup.h"
#include "extfile.h"
#include "maxtime.h"
#include "messages.h"

#define word short
#define byte char

#define CMP_NONE 2

#define BCF_DISK 2

extern HINSTANCE ghInstance;

extern jmp_buf quit_env;		// shutdown jump point
extern char _far szDest[];			// Destination path
extern char _far szAutoexec[];
extern char _far szConfigSys[];
extern char _far szWinIni[];
extern char _far szSystemIni[];
extern int fCopiedSetup;
extern int fRefresh;
extern int	Overwrite;
extern BOOL	PatchPrep;
extern BOOL bHadToCopy;
extern BOOL bCleanOut;
extern LPSTR szCopyFileName;
extern LPSTR szCopyDir;
extern LPSTR szCopyProg;

extern BOOL bBCFsys;
extern BOOL bMCAsys;
extern BOOL bValidBCF;
extern WORD BIOSCRC;
extern char bcf_dest[1];
char _far szBCFSource[ _MAX_PATH + 1 ];

BOOL AddToCopyBatch( LPSTR szSaved, LPSTR szDest, LPSTR szCopyFile );
BOOL MakeCopyDir( LPSTR szDest, LPSTR lpCopyPath, LPSTR lpCopyFile );

BOOL CALLBACK __export SourceDlgProc(HWND, UINT, WPARAM, LPARAM);

extern int DrawMeter(HWND, int);
void CheckFloppy (HWND hDlg);


// Local data
BOOL bBackExists = FALSE;

int fhArchive=0, fhTarget;	// Archive file handle & dest file handle
int nDiskNumber=1, nDiskPass=1;
int nPercent = 0;
long arcbytes;			// Bytes to read from archive file
long arcCRC;			// CRC of data from archive file
unsigned long lTotalSize = 0L;
unsigned long lCopiedSize = 0L;

static char szArchiveName[80] = "";     // name of archive (*.1) file

char szBackupDir[ _MAX_PATH + 1 ] = "";

#define XBUFFSIZE	0x4000	// Size needed for explosion
#define RBUFFSIZE	0x8000	// Size needed to buffer reads
char _far *xbuff;		// Extract buffer
char	 *rbuff,*rbptr; 	// Read buffer
unsigned int rbuff_left;	// Bytes remaining in rbuff
long	 vfilepos;		// Virtual file position
int	 ParsePass;		// Times we've parsed CONFIG.SYS

BOOL BackupMAXDir( void );
void BackupFile ( LPSTR fname );

//********************************** OPEN_ARCHIVE ****************************
// Open or close archive file.
// Handle is assigned to fhArchive directly.
int open_archive (int action)
{
	if (action) {		// open file (action is extent #)
		if ((fhArchive = _lopen (szArchiveName, READ)) == HFILE_ERROR)
			return -1;
	} else if (fhArchive != 0) {		// close file
		_lclose (fhArchive);
		fhArchive = 0;	// Mark as closed
	}

	return 0;
}


//********************************** EXPLODE_IN ******************************
// Called indirectly by DCL code.  Reads data in from archive.
long vseek (long seek_off)
{
	long diff, diff2;

	// Change buffer pointers if possible, otherwise do lseek
	diff = seek_off - vfilepos;
	diff2= rbuff_left - RBUFFSIZE;

	if (diff > (long) rbuff_left || diff < (long) diff2) {
		// lseek and reset
		rbuff_left = 0;
		rbptr = rbuff;
		return (vfilepos = _llseek (fhArchive, seek_off, 0));
	}

	if (diff = (long) rbuff_left) { // move file pointer to end of buffered area
		rbuff_left = 0;
		rbptr = rbuff;
		return (vfilepos += diff);
	}

	// Handle positive and negative seeks within buffered area
	if (diff >= 0 || diff > (long) diff2) {
		rbuff_left -= (WORD) diff;
		rbptr += (WORD) diff;
		return (vfilepos += diff);
	}

	return (-1L);			// shouldn't get here
}


// Buffer read from fhArchive
unsigned int buff_read (char _far *buff, unsigned short int size)
{
	unsigned int rbuff_copy, rbuff_total = 0;

/*  return (_read (fhArchive, buff, size));  */

	do {

		if (rbuff_left) {	// Try to fill request from buffer
			rbuff_copy = min (size, rbuff_left);
			memcpy (buff, rbptr, rbuff_copy);
			rbptr += rbuff_copy;
			rbuff_left -= rbuff_copy;
			size -= rbuff_copy;
			buff += rbuff_copy;
			rbuff_total += rbuff_copy;
			vfilepos += rbuff_copy;
		}

		if (size && !rbuff_left) {	// Time to fill buffer
			rbptr = rbuff;		// Rewind buffer head
			rbuff_left = _lread (fhArchive, rbptr, RBUFFSIZE);
		}

	} while (size && rbuff_left && (rbuff_left != 0xffff));

	return ((rbuff_left == 0xffff) ? rbuff_left : rbuff_total);
}


unsigned far pascal Explode_In (char far *buff, unsigned short far *size)
{
	unsigned int bytesread;

	bytesread = buff_read (buff, *size);
	if ((long) bytesread > arcbytes)
		bytesread = (unsigned int) arcbytes;
	arcbytes -= (long) bytesread;
	if (bytesread)
		arcCRC = crc32 (buff, &bytesread, &arcCRC);

	return (bytesread);
}


void far pascal Explode_Out (char far *buff, unsigned short int far *size)
{
	unsigned byteswritten;

	byteswritten = _lwrite (fhTarget, buff, *size);
}


//********************************** DO_EXTRACT ******************************
// Transfers files from source disk to destination
// Action argument extract, if 0, specifies return size only.
// If 1, extract files and return number of bytes extracted.
// Note that we must specify a destination drive:\directory, which MUST
// end in a trailing slash or backslash.  The drive letter MUST be specified
// and must be the same as the dest_subdir drive.
// After we've extracted everything from a disk, and before we ask for
// the next disk, copy any newer or missing files from the disk (with the
// exception of 386MAX.?).

typedef struct		  /* directory entry */
{
	long next;	  /* offset of next directory entry */
	word id;	  /* product id */
	long start;	  /* offset from start of file */
	DIRTIME date;	  /* compressed date/time */
	long size;	  /* size of uncompressed file */
	long csiz;	  /* size of compressed file */
	word att;	  /* file attribute */
	byte num;	  /* extent that file is in */
	byte comp;	  /* compression format */
	char path[];	  /* path and file name (nul terminated) */
} QDIR;

typedef struct {	  /* compressed file header */
	long crc;	  /* 32 bit CRC for header */
	word dir;	  /* offset of the start of directory (0=none)*/
	word dlen;	  /* length to the dir */
	word ver;	  /* archive/compression program version */
	word fnum;	  /* number of files in the directory */
	byte num;	  /* file extent (1 relative) */
	byte ext;	  /* number of extents (1-n) */
} QFHEAD;

typedef struct _qdirlst {
	struct _qdirlst *next;	// NULL if end
	word id;		/* product id */
	long start;		/* offset from start of file */
	DIRTIME date;		/* compressed date/time */
	long size;		/* size of uncompressed file */
	long csiz;		/* size of compressed file */
	word att;		/* file attribute */
	byte num;		/* extent that file is in */
	byte comp;		/* compression format */
	char path[13];		/* file name (nul terminated) */
} QDIRSTR, *QDIRLST;


int do_extract (HWND hDlg, char *szDest)
{
	extern int BrandFile (char *);
	extern BOOL bWin95, bPrograms, bOnlineHelp, bDosReader;
	extern char _far szHelpName[];

	QFHEAD fhead;		// Disk 1 header
	QDIRLST fdir = NULL;	// Disk 1 directory (the only directory)
	QDIRLST  fprev, fcur;
    DIRTIME  ftime;
	QDIR	 *ftmp;
	auto	 QFHEAD ftemp;	// Current disk header
	int	 len;
	int uError;
    int desthandle;
    unsigned int uSize, uXSize, uRSize;
	long	 crc;		// CRC for current file (as read from archive)
    long    lTimeRes;
	unsigned int res;
	char	 szTarget[128], szBuffer[256];
    char     lpCopyFile[ 258 ];
    char     lpCopyPath[ 258 ];

	uError = SetErrorMode(SEM_NOOPENFILEERRORBOX | SEM_FAILCRITICALERRORS);

	// Set the disk number initially to one
	nDiskNumber = 1;

	// Initialize the source drive -- make sure we have disk 1 mounted
	CheckFloppy( hDlg );

	// Allocate explosion buffer (also used for directory manipulation)
	uXSize = XBUFFSIZE;
	uRSize = RBUFFSIZE;
	if ((xbuff = AllocMem (&uXSize)) == NULL || (rbuff = AllocMem (&uRSize)) == NULL) {
		longjmp(quit_env, -1);
	}

	rbuff_left = 0;

	// Open file
	if ((open_archive (nDiskNumber) == -1) || (_lread (fhArchive, &ftemp, sizeof (ftemp)) != sizeof (ftemp))) {
		MessageBox( hDlg, szMsg_ArcRE, szMsg_Error, MB_OK | MB_ICONSTOP );
		SetupYield(0);
	SetErrorMode( uError );
		longjmp( quit_env, -1 );
	}

	// We have got the first archive disk.	Read the directory into memory
	memcpy (&fhead, &ftemp, sizeof (fhead));

	if (( fhead.num != (byte) nDiskNumber) ||	// Extent mismatch
	    (fhead.dir < sizeof (fhead)) ||	// Bad dir start or no directory
	    !fhead.fnum ||			// No dir entries
	    (fhead.dlen > XBUFFSIZE)) { 	// Dir too big
		MessageBox( hDlg, szMsg_ArcDC, szMsg_Error, MB_OK | MB_ICONSTOP );
		SetupYield(0);
	SetErrorMode( uError );
		longjmp(quit_env, -1);
	}

	// Seek to start of directory
	if (_llseek (fhArchive, (long) fhead.dir, 0) == -1) {
		MessageBox( hDlg, szMsg_ArcDir, szMsg_Error, MB_OK | MB_ICONSTOP );
		SetupYield(0);
	SetErrorMode( uError );
		longjmp(quit_env, -1);
	}

	// Read entire directory into xbuff
	if (_lread (fhArchive, xbuff, fhead.dlen) == -1) {
		MessageBox( hDlg, szMsg_ArcRE, szMsg_Error, MB_OK | MB_ICONSTOP );
		SetupYield(0);
	SetErrorMode( uError );
		longjmp(quit_env, -1);
	}

	// To maximize the efficiency of our heap allocation, we allocate
	// (12-5) * number of directory entries + dir size to fdir,
	// and parcel it out as we go along.	5 is the minimum filename
	// length (README)
	uSize = (fhead.dlen + fhead.fnum * (12-5));
	fprev = fdir = (QDIRLST)AllocMem ( &uSize );

	// Walk through directory entries in memory and set up fdir list
	for ( ftmp=((QDIR *) xbuff), fcur=fdir, len = fhead.fnum; (len != 0); len--) {

	    // Since we copy sizeof (QDIRSTR) bytes, we also copy path and
	    // trailing null.
	    memcpy (fcur, ftmp, sizeof (QDIRSTR));

	    lTotalSize += fcur->size;

	    fcur->next = NULL;
	    if (fcur != fprev)
		fprev->next = fcur;
	    fprev = fcur++;

	    ftmp = (QDIR *) ((char *) ftmp + sizeof (QDIR)+ strlen (ftmp->path) + 1);
	}

	vfilepos = _llseek (fhArchive, 0L, 1);	// Get current offset
	for ( nDiskPass = nDiskNumber; (nDiskPass <= (word) fhead.ext); nDiskPass++) {

	  for (fcur = fdir; (fcur != NULL); fcur = fcur->next) {

	    if ((word)fcur->num == nDiskPass) {

	      SetupYield(0);

	      MakePath( szDest, fcur->path, szTarget );

	      // only copy files if requested
	      if ((lstrcmpi( fcur->path, "hhelp.exe" ) == 0) || (lstrcmpi( fcur->path, "maxhelp.bat" ) == 0) || (lstrcmpi( fcur->path, "hhelp.ini" ) == 0)) {
		if (bDosReader == 0)
			continue;
	      } else if (lstrcmpi( fcur->path, "maxhelp.hlp" ) == 0) {
		if (bOnlineHelp == 0)
			continue;
	      } else if ((bWin95 == 0) && ((lstrcmpi(fcur->path, "dosmax.dll") == 0) ||
			(lstrcmpi(fcur->path, "dosmax16.dll") == 0) || (lstrcmpi(fcur->path, "setewv.exe") == 0) || (lstrcmpi(fcur->path, "dosm95f.pif") == 0) || (lstrcmpi(fcur->path, "dosm95w.pif") == 0)))
		continue;
	      else if ((bWin95) && ((lstrcmpi(fcur->path, "dosmaxf.pif") == 0) || (lstrcmpi(fcur->path, "dosmaxw.pif") == 0) || (lstrcmpi(fcur->path, "qpifedit.exe") == 0)))
		continue;
	      else if (bPrograms == 0)
		continue;

	      // Change disks if necessary
	if (nDiskNumber != nDiskPass) {

	    // Close file
	    open_archive (0);
	    rbuff_left = 0;	// Reset buffer pointers & counter
	    rbptr = rbuff;
	    vfilepos = 0L;		// Reset virtual file offset
	    nDiskNumber = nDiskPass;

		// change SETUP.HLP file location
	    MakePath( szDest, "setup.hlp", szHelpName );

	    CheckFloppy ( hDlg );

	    if (open_archive (nDiskNumber) == -1) {	// Open next extent
		MessageBox( hDlg, szMsg_ArcRE, szMsg_Error, MB_OK | MB_ICONSTOP );
		SetupYield(0);
		SetErrorMode( uError );
		longjmp(quit_env, -1);
	    }
	}

	      if (vseek (fcur->start) == -1L)
		MessageBox(hDlg, szMsg_ArcExt, szMsg_Extract, MB_OK | MB_ICONSTOP);
	      rbuff_left = 0;

	      SetupYield(0);
	      if (buff_read ((char *) &crc, sizeof (crc)) == 0xffff)
		MessageBox(hDlg, szMsg_ArcBuf, szMsg_Extract, MB_OK | MB_ICONSTOP);
	      arcCRC = ~0;
	      arcbytes = fcur->csiz - 4L;

	      SetupYield(0);

	    // Check to see if file exists
	  ftime.dtime = 0L;
	  if (( desthandle = _open( szTarget, O_BINARY|O_RDONLY)) != -1 ) {
	     _dos_getftime( desthandle, &(ftime.dt.date), &(ftime.dt.time));
	     _close( desthandle);
	  } // Destination file exists

	    // newer = +Res
	    // equal = 0Res
	    // older = -Res
	  lTimeRes = (fcur->date.dtime > ftime.dtime) ? 1
		     : (fcur->date.dtime < ftime.dtime) ? -1 : 0;

		// If the Overwrite flag is set, don't overwrite existing file
		// with identical or older time/date unless PatchPrep is also
		// set.  Overwrite and PatchPrep together have the effect of
		// extracting everything.
	      if ( Overwrite && !PatchPrep && (lTimeRes <= 0) ) {
		     continue;
	  }

		// if PatchPrep is set and Overwrite is cleared...
		// don't extract if the target is missing, or if the
		// time/dates are identical.
	  if ( PatchPrep && !Overwrite &&
		     ( desthandle == -1 || ( !lTimeRes ))) {
		     continue;
	  }

		// backup if target exists and dtimes are different.
	  if(( desthandle != -1 ) && ( lTimeRes )) {
	     BackupFile( (LPSTR)(fcur->path) );
	  }

	      if ((fhTarget = _lcreat (szTarget, 0 )) == HFILE_ERROR ) {
	    MakeCopyDir( (LPSTR)szDest, (LPSTR)lpCopyPath, (LPSTR)lpCopyFile );
		// NOTE szTarget Changes here!
	    MakePath( lpCopyPath, fcur->path, szTarget );

	    if ((fhTarget = _lcreat (szTarget, 0 )) == HFILE_ERROR ) {
		MessageBox( hDlg, szMsg_Target, NULL, MB_OK | MB_ICONSTOP);
	    } else {
		AddToCopyBatch( (LPSTR)szTarget, (LPSTR)szDest, (LPSTR) lpCopyFile );
	    }
	  }

	      // display filename in Install dialog
	      AnsiUpper( szTarget );
	      wsprintf(szBuffer, "%s %s", szMsg_Xtr, szTarget );
	      SetDlgItemText( hDlg, 668, szBuffer );
	      SetupYield(0);

	      if (fcur->comp == CMP_NONE) {

		// file not compressed; just read it as-is
		while (arcbytes) {
		    if ((long) XBUFFSIZE < arcbytes)
			len = XBUFFSIZE;
		    else
			len = (int) arcbytes;
		    if ((buff_read (xbuff, len) == -1) || (_lwrite (fhTarget, xbuff, len) == -1))
			MessageBox(hDlg, szMsg_UncW, szMsg_Error, MB_OK | MB_ICONSTOP);
		    arcbytes -= (long) len;
		}

	      } else if ((res = explode (Explode_In, Explode_Out, xbuff)) || (~arcCRC != crc))
		MessageBox( hDlg, ((res) ? szMsg_BadData : szMsg_CRC ), szMsg_Error, MB_OK | MB_ICONSTOP);

	      SetupYield(0);
	      _dos_setftime (fhTarget, fcur->date.dt.date, fcur->date.dt.time);
	      _lclose( fhTarget );
	      _dos_setfileattr ( szTarget, fcur->att );
	      lCopiedSize += fcur->size;

	      nPercent = ((fCopiedSetup == 0) ? (int)((lCopiedSize * 100) / lTotalSize ) : (int)(((lCopiedSize * 75) / lTotalSize ) + 25 ));
	      DrawMeter( GetDlgItem(hDlg, IDC_METER), nPercent );
	      SetupYield(0);
	    }
	  }
	}

	open_archive (0);	// Close file
	FreeMem (xbuff);
	FreeMem (rbuff);
	FreeMem ( (char *)fdir);

	// Assumes BCF files to be on the current (last) disk
    SetupYield(0);
    if( bBCFsys && BIOSCRC && !fRefresh ) {
	char szTFile[ _MAX_PATH + 1 ];

	      // point to the bcf source file.
	      // 1/15/96 don't report an error
	wsprintf ( szTFile, "%s\\@%04X.BCF", szBCFSource, BIOSCRC);
	FileCopy( bcf_dest, szTFile );
    }

	SetErrorMode( uError );
	return 0;
}


// make sure the right floppy is in the drive
void CheckFloppy ( HWND hDlg )
{
	extern BOOL CALLBACK __export AskQuitDlgProc(HWND, UINT, WPARAM, LPARAM);
	extern HWND hParent;
	extern HINSTANCE ghInstance;
	extern char _far szSetupName[];

	int uError, nAttribute;
	char szBuffer[256];

	uError = SetErrorMode(SEM_NOOPENFILEERRORBOX | SEM_FAILCRITICALERRORS);

	if (fRefresh) {
		// look for 386MAX.n in A:
		wsprintf( szArchiveName, "A:\\386MAX.%d", nDiskNumber);
		wsprintf( szBCFSource, "A:\\BCF");
    } else {
		// look for 386MAX.n in same directory as SETUP.EXE
		lstrcpy( szBuffer, ((szArchiveName[0] == '\0') ? szSetupName : szArchiveName ));
		wsprintf( szArchiveName, "%s386MAX.%d", path_part(szBuffer), nDiskNumber);
		    // it looks like path_part returns
		    // a path with trailing backslash, so we don't need one.
		wsprintf( szBCFSource, "%sBCF", path_part(szBuffer));
	}

	for ( ; ; ) {

    _asm {
	    mov ah, 0Dh 	; reset disks
	    int 21h
	  }

		if (_dos_getfileattr( szArchiveName, &nAttribute ) != 0) {

			// we can't find the archive file, so ask the user
			//   where it is!
			DialogBox(ghInstance, MAKEINTRESOURCE(SOURCEDLGBOX), hDlg, SourceDlgProc);
			DrawMeter( GetDlgItem(hDlg, IDC_METER), nPercent );
			SetupYield(0);
			DrawMeter( GetDlgItem(hDlg, IDC_METER), nPercent );

		} else
			break;
	}

	DrawMeter( GetDlgItem(hDlg, IDC_METER), nPercent );
	SetErrorMode( uError );
	DrawMeter( GetDlgItem(hDlg, IDC_METER), nPercent );
}

//------------------------------------------------------------------
// create a Backup MAX directory
//------------------------------------------------------------------
BOOL BackupMAXDir( void )
{
	int uError;
    unsigned uCount;
	char szBuffer[ _MAX_PATH + 1 ];

    if( bBackExists )
	return TRUE;

	// make sure we've got enough room to backup 386MAX directory
	if ( (fRefresh) || (freeKB( szDest ) < 4000L))
	return FALSE;

	uError = SetErrorMode(SEM_NOOPENFILEERRORBOX | SEM_FAILCRITICALERRORS);

	// make most of the backup path...
	MakePath( szDest, "OLDMAX", szBuffer );

    for( uCount = 1; uCount <= 0xFFF; uCount++ ) {
	    // add the extension to the path.
	wsprintf( szBackupDir, "%s.%x", szBuffer, uCount );

	    // break if dir does not exist.
	if ( _access( szBackupDir,  0 ) ) {
	    break;
	}
    }

	// make the directory
	if ( ((_mkdir( szBackupDir ) == -1) && (_doserrno != 5))
	|| ( uCount > 0xFFF ))	{
		wsprintf( szBuffer,"%s \"%s\".", szMsg_BackDir, szBackupDir );
		MessageBox( 0, szBuffer, szMsg_Dir, MB_OK | MB_ICONSTOP );
	SetErrorMode( uError );
	szBackupDir[0] = '\0';
	return FALSE;
	}

	// flag dir exists.
    bBackExists = TRUE;
    SetErrorMode( uError );
    return TRUE;
}

//------------------------------------------------------------------
// Backup one file from szDest to szBackupDir by renaming it.
//------------------------------------------------------------------
void BackupFile ( LPSTR fname )
{
    char szSrc[ _MAX_PATH + 1 ];
    char szDst[ _MAX_PATH + 1 ];

	// point to the existing max dir.
    MakePath( szDest, fname, szSrc );

	// create the backup directory if it does not already exist.
    if( !bBackExists ){
	if( !BackupMAXDir() ) {
	    return;
	}
    }
	// point szDst to the backup dir\filename.
    MakePath( szBackupDir, fname, szDst );

	// make sure the source is read/write.
    if ( !_access( szSrc, 06 ) ) {
	    // if yes, then moving is faster.
	if ( !rename ( szSrc, szDst )) {
		// and we're done.
	    return;
	}
    }
	// ...else we must copy instead.
    FileCopy( szDst, szSrc );
    return;
}

//------------------------------------------------------------------

// Restore MAX directory
void RestoreMAX( void )
{
	int uError, fFval;
	char szBuffer[ _MAX_PATH + 1 ];
    char szSource[ _MAX_PATH + 1 ];
    char szTarget[ _MAX_PATH + 1 ];
	struct _find_t dir;

	if ((fRefresh) || (szBackupDir[0] == '\0'))
		return;

	uError = SetErrorMode(SEM_NOOPENFILEERRORBOX | SEM_FAILCRITICALERRORS);

	MakePath( szBackupDir, "*.*", szBuffer );
	for (fFval = 0x4E; ; fFval = 0x4F) {

		szSource[0] = '\0';
		if (FindFile( fFval, szBuffer, &dir, szSource ) == NULL)
			break;

		MakePath( szDest, fname_part(szSource), szTarget );
		FileCopy( szTarget, szSource );
		SetupYield(0);
	}

	SetErrorMode( uError );
}


// "Get source directory" dialog box
BOOL CALLBACK __export SourceDlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	extern HWND hParent;
	extern HANDLE ghInstance;
	extern char _far szHelpName[];
	char szTemp[128], szBuf[16];

	switch (uMsg) {
	case WM_INITDIALOG:
		CenterWindow( hDlg );
		AnsiUpper( szArchiveName );

		// if the source was on a floppy, prompt for a new disk
		if (szArchiveName[0] < 'C')
			wsprintf( szTemp, "%s %d. %s %d.", szMsg_InsDsk, nDiskNumber, szMsg_DskLoc, nDiskNumber );
		else
			wsprintf( szTemp, "%s %s :", szMsg_DskPath, szArchiveName );
		SetDlgItemText( hDlg, IDC_TEXT, szTemp );
		SetDlgItemText( hDlg, IDC_PATH, path_part(szArchiveName) );
		SetFocus( GetDlgItem( hDlg, IDC_PATH ) );
		return 0;

	case WM_COMMAND:

		switch (LOWORD(wParam)) {
		case IDC_CONTINUE:
			GetDlgItemText(hDlg, IDC_PATH, szTemp, 127);
			// check to see if the filename was included
			if (FindString(szTemp, "386MAX.") < 0) {
				wsprintf( szBuf, "386MAX.%d", nDiskNumber);
				MakePath( szTemp, szBuf, szArchiveName );
			} else
				lstrcpy( szArchiveName, szTemp );
			EndDialog( hDlg, 0 );
			return 0;

		case IDC_EXIT:
			if (DialogBox(ghInstance, MAKEINTRESOURCE(ASKQUITDLGBOX), hDlg, AskQuitDlgProc) == 1) {
				EndDialog( hDlg, 1 );
				longjmp( quit_env, -1 );
			}
			return 0;

		case IDC_HELP:
			WinHelp( hDlg, szHelpName, HELP_KEY, (DWORD)( (LPSTR)szHKEY_SrcDir ));
			break;
		}
	}

	return FALSE;
}

//------------------------------------------------------------------
// Makes copy directory and file and returns true.
// Also returns true if file already exists.
// Returns false if failure.
// lpCopyFile contains the batch file name and lpCopyPath contains
// the directory name.
//------------------------------------------------------------------
BOOL MakeCopyDir( LPSTR szDest, LPSTR lpCopyPath, LPSTR lpCopyFile )
{
    int nErr = 0;
    struct _find_t ft;
    HFILE hf;
    OFSTRUCT os;

    if( !bCleanOut ) {
	char szName[ _MAX_PATH+2 ];

	MakePath( szDest, szCopyProg, szName );
	if ( ExtractFileFromRes( ghInstance, ( LPCSTR ) szName, IDC_CLEAN )) {
	    bCleanOut = TRUE;
	}
    }

	// make the directory name.
    MakePath( szDest, szCopyDir, lpCopyPath );

	// search for the directory
    if( _dos_findfirst( (LPSTR)lpCopyPath, _A_SUBDIR, &ft )) {

	    // directory does not exist...make it.
	if(( nErr = _mkdir( (LPSTR)lpCopyPath )) == 0 )  {

	    memset( &os, 0, sizeof( OFSTRUCT ));

		// make the file name in the pass back buffer.
	    MakePath( lpCopyPath, szCopyFileName, lpCopyFile );

		// make the file as well.
	    if (( hf = OpenFile( lpCopyFile, &os,
				OF_READWRITE | OF_CREATE | OF_SHARE_COMPAT ))
				!= HFILE_ERROR ) {
		_lclose( hf );
	    } else {
		    // error on file open.
		    // null the filename.
		lpCopyFile[0] = '\0';
		    // Should still hold the directory name.
		    // Remove directory since the file create failed.
		_rmdir( lpCopyPath );
		lpCopyPath[0] = '\0';
		nErr = -1;
	    }
	}
    } else {
	    // the path already exists.
	    // make the file name in the pass back buffer.
	MakePath( lpCopyPath, szCopyFileName, lpCopyFile );
    }

    if( nErr ) {
	return FALSE;
    }

	// directory exists.
    return TRUE;
}

//------------------------------------------------------------------
BOOL AddToCopyBatch( LPSTR szSaved, LPSTR szDest, LPSTR szCopyFile )
{
    HFILE hf;
    OFSTRUCT os;
    char msg[ 550 ];

    bHadToCopy = TRUE;

    memset( &os, 0, sizeof( OFSTRUCT ));

    if (( hf = OpenFile( szCopyFile, &os, OF_READWRITE )) != HFILE_ERROR ) {

	wsprintf( msg, "@COPY %s %s >NUL\r\n", szSaved, szDest );
	_llseek( hf, 0L, 2 );
	_lwrite( hf, msg, strlen( msg ));

	wsprintf( msg, "@DEL %s >NUL\r\n", szSaved );
	_llseek( hf, 0L, 2 );
	_lwrite( hf, msg, strlen( msg ));

	_lclose( hf );

    return TRUE;
    }

return FALSE;
}

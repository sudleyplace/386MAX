/*' $Header:   P:/PVCS/MAX/QMT/MAKEBOOT.C_V   1.1   15 May 1997 12:47:18   BOB  $ */
/************************************************************************
 *																						*
 * (C) Copyright 1993 Qualitas, Inc.  GNU General Public License version 3.			*
 *																						*
 * MAKEBOOT.C																		*
 *																						*
 * Main source module for MAKEBOOT.COM												*
 *																						*
 ************************************************************************/

// Necessary includes

#include <share.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <io.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <fcntl.h>
#include <malloc.h>
#include <dos.h>
#include <conio.h>
#include <errno.h>
#include <direct.h>
#include <process.h>
#include <errno.h>

#include "makeboot.h"           // Setup some handy defines and typedefs

#ifndef PROTO
#include "makeboot.pro"         // Get prototypes
#endif

// Define global variables

char	cDestDrive='\0';        // target drive
char	cSYSDrive ='\0';        // optional drive where SYS can find files

int	iOldDrive=-1;				// Holds old drive (A = 1)

char	cQorF;						// Q of F for quick or full

#ifdef LANG_GR
char  static pAutoexecText[]=	// 1st part of autoexec file.
					  "@echo off\r\n"
					  "prompt $P$G\r\n"
					  "\\RAMexam.EXE ";

char  static pAutoexecText2[]= // 2nd part of autoexec file.
					  "\r\n"
					  "echo.\r\n"
					  "echo RAMexam Test abgeschlossen. Entfernen Sie die Start-Diskette und\r\n"
					  "echo drÅcken Sie STRG-ALT-ENF.\r\n";

char  static pConfigText[]=	 // CONFIG.SYS
					  "\r\n";
#else // #ifdef LANG_GR

char  static pAutoexecText[]=	// 1st part of autoexec file.
					  "@echo off\r\n"
					  "prompt $P$G\r\n"
					  "\\RAMexam.EXE ";

char  static pAutoexecText2[]= // 2nd part of autoexec file.
					  "\r\n"
					  "echo.\r\n"
					  "echo RAMexam testing completed. Please remove bootable floppy and press\r\n"
					  "echo CTRL-ALT-DEL.\r\n";

char  static pConfigText[]=	 // CONFIG.SYS
					  "\r\n";

#endif	// LANG_GR

char	azCommandCom[]="_:\\COMMAND.COM";
char	azSourceCom[256];

void main(int argc , char *argv[] )
{

// Declare locals

	char	 azSource[256]; 		// Name for source file
	char	 azDest[16]="_:\\";  // Name for dest file (A:\8.3\0)
	int	 iResp;

// Display copyright

#ifdef LANG_GR

   puts("\nMAKEBOOT -- Version 1.05 -- Erstellt eine Start-Diskette");
   puts("   (C) Copyright 1993 Qualitas, Inc.  Alle Rechte vorbehalten.");

#else

	puts("\nMAKEBOOT -- Version 1.05 -- Make A Boot Disk");
	puts("   (C) Copyright 1993 Qualitas, Inc.  GNU General Public License version 3.");

#endif

// Validate arguments

	if ( !(argc == 2 || argc == 3) )
		ShowHelp();				// showhelp exits

// Validate 1st argument

	cDestDrive = (char) toupper(argv[1][0]);	// Get the destination drive
	switch( cDestDrive )
	{
		case 'A':
	   case 'B':
			break;				// Do nothing
		default:
			ShowHelp();			// Otherwise show the help screen
	}

// Validate 2nd argument

	if ( argc == 3 )
		{
		cSYSDrive = (char) toupper(argv[2][0]); // Get the destination drive
		if ( cSYSDrive < 'A' || cSYSDrive > 'Z' )
			{

#ifdef LANG_GR

	 puts("ungÅltige Parameter");

#else  // #ifdef LANG_GR

			puts("Invalid parameters");

#endif // #ifdef LANG_GR

			ShowHelp();
			}
		}

	_dos_setvect( 0x24, CritErr );		// Setup our Crit Err Handler

// Check for RAMEXAM.EXE's presence

	if( !Exist("RAMEXAM.EXE") )                 // Is RAMEXAM.EXE in the current directory?
		{

#ifdef LANG_GR
      puts("RAMEXAM.EXE im aktuellen Verzeichnis nicht gefunden.");
      puts("Starten Sie MAKEBOOT aus dem RAMEXAM Verzeichnis.");

#else  // #ifdef LANG_GR

		puts("RAMEXAM.EXE not found in current directory.");
		puts("You must run MAKEBOOT from the RAMEXAM directory.");

#endif // #ifdef LANG_GR

		exit(3);
		}

// Check for SYS's presence

	_searchenv( "SYS.COM", "PATH", azSource);
	if ( !azSource[0] )			// No dice, check for .EXE
		_searchenv( "SYS.EXE", "PATH", azSource);

	if ( !azSource[0] )			// If SYS was not found, complain
		{

#ifdef LANG_GR

      puts("\nMAKEBOOT konnte das System nicht auf Diskette Åbertragen.\n"
	   "Das DOS SYS Programm war im Pfad nicht zu finden.");

#else

		puts("\nMAKEBOOT could not transfer a system to the floppy.\n"
		     "DOS's SYS program was not found in your path.");
#endif

		exit(4);
		}

// Get COMSPEC (if it exists)
	strcpy( azSourceCom, getenv( "COMSPEC" ) );

// Ask user if they want a quick or a full

#ifdef LANG_GR
   iResp = QueryUser(  "Mîchten Sie den Kurztest (QUICK) oder Volltest (FULL) - (Q/F) ",
	       "UngÅltige Antwort, drÅcken Sie Q fÅr QUICK, F fÅr FULL ",
	       "QF");

#define KEY_QUICK 'Q'
#define KEY_FULL  'F'

#else

	iResp = QueryUser(  "Would you like to use a QUICK or FULL test (Q/F) ",
					"Invalid response, press Q for QUICK, F for FULL ",
					"QF");

#define KEY_QUICK 'Q'
#define KEY_FULL  'F'

#endif

	if( iResp == 1 )		// Set Var for testing later
		cQorF = KEY_QUICK;
	else
		cQorF = KEY_FULL;

// Query user, and give dire warning

#ifdef LANG_GR
	printf("\nLegen Sie eine formatierte Diskette in das Laufwerk %c:.\n"
			 "ACHTUNG: Daten auf %c: werden gelîscht!\n"
			 "Weiter mit einer Taste, A fÅr Abbruch.\n", cDestDrive, cDestDrive );
#define KEY_ABORT 'A'
#else
	printf("\nPlace a formatted diskette in the %c: drive.\n"
			 "WARNING: Contents of %c: drive will be deleted.\n"
			 "Press any key to continue, A to abort.\n", cDestDrive, cDestDrive );
#define KEY_ABORT 'A'
#endif

	{
		char	c;

		c = (char) getch();

		if( toupper( c ) == KEY_ABORT )
			{
#ifdef LANG_GR
	 puts("Abbruch . . .");
#else
			puts("Aborting . . .");
#endif
			exit(2);
			}
	}


	azDest[0] = (char) cDestDrive;		// Fill in destination path
// Erase floppy

#ifdef LANG_GR
   printf("\nLîsche Daten auf Diskette in Laufwerk %c:\n", cDestDrive );
#else
	printf("\nErasing diskette in drive %c:\n", cDestDrive );
#endif
	UnlinkAll( azDest );

	if ( !cSYSDrive )							// Is SYSDrive specified?
		cSYSDrive = (char) azSource[0]; // No, make it the same as SYS's drive

	iOldDrive = (char) _getdrive(); 			// Get current drive
	_chdrive( cSYSDrive - 'A' + 1 );                // Set new default drive

// Call SYS.COM (or .EXE)

	{
		char	azDestDrive[]="_:";             // Used for spawn

#ifdef LANG_GR
      puts("AusfÅhrung SYS");
#else
		puts("Running SYS");
#endif
		azDestDrive[0] = cDestDrive;

		if ( spawnl( P_WAIT, azSource, azSource, azDestDrive, NULL ) == -1 )
			{
#ifdef LANG_GR
	 puts("\nkonnte das SYS Programm nicht ausfÅhren.");
#else
			puts("\nCould not run SYS program.");
#endif
			_chdrive( iOldDrive );		// Set default drive back
			exit(5);
			}
		printf("\n"); // DR-DOS's SYS needs this to make the screen look OK.
	}

	_chdrive( iOldDrive );		// Set default drive back

// Always copy the COMMAND.COM we found through COMSPEC

	azCommandCom[0] = cDestDrive;			// Setup File Name to copy to
	if ( !azSourceCom[0] ) {		// Was there a COMSPEC?, see if copying is necessary

		if ( !Exist( azCommandCom ) ) {  // Did SYS put a command.com there?
			_searchenv( "COMMAND.COM", "PATH", azSourceCom ); // No, Find one in the path
			if ( !azSourceCom[0] )		// Was there one in the path?
#ifdef LANG_GR
	    printf( "\nkonnte COMMAND.COM nicht finden\n");
#else
				printf( "\nCould not find COMMAND.COM\n"); // No, warn user
#endif
			} // ( !Exist( azCommandCom ) )

	} // ( !azSourceCom[0] )

	if ( azSourceCom[0] ) { 	// Have we filled this in?

		if ( Exist (azCommandCom) ) {  // If COMMAND.COM exists, make sure it is not R/O
			_dos_setfileattr( azCommandCom , _A_NORMAL ); // clear bad attribs
		}
#ifdef LANG_GR
		printf("ÅberprÅfe COMMAND.COM ");
#else
		printf("Verifying COMMAND.COM ");
#endif
		if ( !CopyFile( azSourceCom, azCommandCom ) )  // Copy the file
#ifdef LANG_GR
			printf( "\nProblem bei Kopieren von COMMAND.COM auf Diskette\n");
#else
			printf( "\nTrouble copying COMMAND.COM to diskette\n");
#endif
	}

// Copy RAMEXAM to floppy

#ifdef LANG_GR
	printf("kopiere RAMexam.EXE auf Diskette ");
#else
	printf("Copying RAMexam.EXE to floppy ");
#endif

	strcat( azDest, "RAMEXAM.EXE");
	if ( !CopyFile( "RAMEXAM.EXE" , azDest ) )
		{
#ifdef LANG_GR
	 printf( "\nProblem bei Kopieren von RAMEXAM.EXE\n");
#else
			printf( "\nTrouble copying RAMEXAM.EXE\n");
#endif
		}

#ifdef LANG_GR
   printf("erstelle %c:\\AUTOEXEC.BAT\n", cDestDrive );
#else
	printf("Creating %c:\\AUTOEXEC.BAT\n", cDestDrive );
#endif
	CreateAuto( cDestDrive );			// Create autoexec.bat

#ifdef LANG_GR
	printf("erstelle %c:\\CONFIG.SYS\n", cDestDrive );
#else
	printf("Creating %c:\\CONFIG.SYS\n", cDestDrive );
#endif
	CreateConfig( cDestDrive );		// Create config.sys

#ifdef LANG_GR
   puts("Fertig.\n\n"
	"Ihre RAMexam Start-Diskette ist nun erstellt. Starten Sie RAMexam\n"
	"von der Diskette, indem Sie diese in das Diskettenlaufwerk legen und\n"
	"STRG-ALT-ENF drÅcken.");
#else
	puts("Done.\n\n"
		  "Your RAMexam boot diskette is now ready for use. To run RAMexam from\n"
		  "the boot floppy, insert the diskette into the floppy drive and\n"
		  "press CTRL-ALT-DEL.");
#endif

}

#define ChunkSize	0x2000

int	CopyFile ( char  *pzSource , char *pzDest )
{
	unsigned	rc;
	unsigned	hSource,hDest;				// File handles
	unsigned cDesired;
	unsigned cActual;
	unsigned uValue;
	HPBYTE hpbBuffer = hpbBuffer = (HPBYTE) halloc( ChunkSize, sizeof(BYTE) );		// Allocate hugh chunk of memory

	if ( uValue = _dos_open( pzSource , O_RDONLY | SH_COMPAT , &hSource ) != 0 )
		return FALSE;

	if ( uValue = _dos_creat( pzDest , _A_NORMAL , &hDest ) != 0 )
		{
		_dos_close(hSource);
		return FALSE;
		}

	cDesired = cActual = ChunkSize;

	while ( cActual == ChunkSize )
		{
		printf(".");
		rc = _dos_read( hSource , hpbBuffer , cDesired , &cActual );
		if( rc )
			{
			close( hSource );
			close( hDest );
			return FALSE;
			}

		cDesired = cActual;
		rc	= _dos_write( hDest , hpbBuffer , cDesired , &cActual );

		if ( rc || (cDesired != cActual) )
			{
			close( hSource );
			close( hDest );
			return FALSE;
			}
		}

	_dos_close( hSource );
	_dos_close( hDest );

	printf("\n");                                           // put newline at the end of the periods.

	return TRUE;

}

// Removes a file (or files)
void UnlinkAll( char *pazPath)
{
	struct	find_t	ftFileInfo;
	unsigned	rc;
	char		azFullName[256];
	int		cFullName;

	strcpy( azFullName , pazPath );
	cFullName = strlen( azFullName );
	strcat( azFullName , "*.*" );

	rc = _dos_findfirst( azFullName ,
		_A_ARCH | _A_HIDDEN | _A_NORMAL | _A_RDONLY | _A_SUBDIR | _A_SYSTEM,
		&ftFileInfo );

	if ( rc )
		return;

	while ( !rc )
		{
		unsigned		newattrib;

		azFullName[ cFullName ] = '\0';         // Truncate name
		strcat( azFullName , ftFileInfo.name );

		if ( ftFileInfo.attrib &= _A_SUBDIR ) // remove all files from subdir
			{
			if ( ftFileInfo.name[0] != '.' )
				{
				strcat( azFullName , "\\" );
				UnlinkAll( azFullName );

				azFullName[ cFullName ] = '\0';         // Truncate name
				strcat( azFullName , ftFileInfo.name ); // put it back
				rmdir( azFullName );
				}
			}
		else
			{
			newattrib = (ftFileInfo.attrib & _A_NORMAL );
			_dos_setfileattr( azFullName , newattrib ); // clear bad attribs
			unlink( azFullName );
			}

		rc = _dos_findnext( &ftFileInfo );

		}

	return;

}

int  Exist( char *pazFileName )
{
	struct	find_t	ftFileInfo;
	unsigned	rc;

	rc = _dos_findfirst( pazFileName,
								_A_ARCH | _A_NORMAL | _A_RDONLY,
								&ftFileInfo );

	return( !rc );

}

void ShowHelp( void )
{
#ifdef LANG_GR
   puts("Syntax:  MAKEBOOT a: [c:]");
   puts("Wobei:   a: das Ziellaufwerk ist");
   puts("         c: das wahlfreie Laufwerk ist, von dem das System startet.");
#else
	puts("Syntax:  MAKEBOOT a: [c:]");
	puts("Where:   a: is the destination drive.");
	puts("         c: is the optional drive letter that you boot from.");
#endif

	exit(1);
}

void CreateAuto( char cDrive )
{
	HFILE	hDest;
	unsigned cActual,cDesired;
	char	pazAutoexec[]="_:\\AUTOEXEC.BAT";

	pazAutoexec[0] = cDrive;

	if ( _dos_creat( pazAutoexec , _A_NORMAL , &hDest ) != 0 )
		{
#ifdef LANG_GR
      printf("konnte %s nicht erstellen\n", pazAutoexec );
#else
		printf("Could not create %s\n", pazAutoexec );
#endif
		}

	_dos_write( hDest , pAutoexecText, strlen(pAutoexecText) , &cActual );

	if ( cQorF == KEY_QUICK )
		_dos_write( hDest , "QUICK=1", 7 , &cActual );
	else
		_dos_write( hDest , "FULL=1", 6, &cActual );

	_dos_write( hDest , pAutoexecText2, cDesired=strlen(pAutoexecText2) , &cActual );

	_dos_close( hDest );

}

void CreateConfig( char cDrive )
{
	HFILE	hDest;
	unsigned cActual,cDesired;
	char	pazConfig[]="_:\\CONFIG.SYS";

	pazConfig[0] = cDrive;

	if ( _dos_creat( pazConfig , _A_NORMAL , &hDest ) != 0 )
		{
#ifdef LANG_GR
      printf("konnte %s nicht erstellen\n", pazConfig );
#else
		printf("Could not create %s\n", pazConfig );
#endif
		}

	_dos_write( hDest , pConfigText, cDesired=strlen(pConfigText) , &cActual );

	_dos_close( hDest );

}


void _interrupt _far CritErr	( unsigned _es, unsigned _ds,
										  unsigned _di, unsigned _si,
				unsigned _bp, unsigned _sp,
				unsigned _bx, unsigned _dx,
				unsigned _cx, unsigned _ax,
				unsigned _ip, unsigned _cs,
				unsigned flags )
{
	char	cResp;
	char	cDrive = (char)( _ax & 0x00FF ) + (char)('A');
	WORD	RetVal = I24_TERM_PROG; // Default is to Terminate program

	if ( cDrive != cDestDrive )	// Is the error on the floppy?
		{
		if ( _ax & 0x0100 )		// Bit set if Write
			cprintf(
#ifdef LANG_GR
				"Fehler bei Lesen Laufwerk "
#else
				"Error Reading Drive "
#endif
						"%c.\r\n", cDrive ); // Since we know
		else
			cprintf(
#ifdef LANG_GR
				"Fehler bei Schreibvorgang Laufwerk "
#else
				"Error Writing Drive "
#endif
						"%c.\r\n", cDrive );

#ifdef LANG_GR
		cprintf("zurÅck zum DOS\r\n");
#else
		cprintf("Exiting to DOS\r\n");                  // Don't try to fix it
#endif
		RetVal = I24_TERM_PROG;

		}
	else if ( (_di == 0) && (_ax & 0x0100) )
		{
#ifdef LANG_GR

      cprintf("Diskette in Laufwerk %c: ist schreibgeschÅtzt.\r\n",cDrive);
      cprintf("Taste A fÅr Abbruch oder weiter mit beliebiger Taste.\r\n");

#else  // #ifdef LANG_GR

		cprintf("Diskette in drive %c: is write protected.\r\n",cDrive);
		cprintf("Press A to abort, or other key to continue.\r\n");

#endif // #ifdef LANG_GR

		cResp = (char) _dos_getch();
		cResp = (char) toupper( cResp );

		if ( cResp == 'A' )
			RetVal = I24_TERM_PROG; 	// Abort
		else
			RetVal = I24_RETRY;		// Try it again

		}
	else if ( _di & 0x0002 ) // if bit 1 is set
		{
#ifdef LANG_GR

      cprintf("Legen Sie eine Diskette in Laufwerk %c:.\r\n",cDrive );
      cprintf("Taste A fÅr Abbruch oder weiter mit beliebiger Taste.\r\n");

#else // #ifdef LANG_GR

		cprintf("Please place a floppy in drive %c:.\r\n",cDrive );
		cprintf("Press A to abort, or other key to continue.\r\n");

#endif // #ifdef LANG_GR

		cResp = (char) _dos_getch();
		cResp = (char) toupper( cResp );

		if ( cResp == 'A' )
			RetVal = I24_TERM_PROG; 	// Abort
		else
			RetVal = I24_RETRY;		// Retry the function
		}
	else
		{

#ifdef LANG_GR
		cprintf("Die Diskette in Laufwerk %c: ist beschÑdigt oder nicht formatiert.\r\n"
			"Bitte Diskette formatieren. Weiter mit beliebiger Taste.\r\n",cDrive );

      cprintf("Die Diskette in Laufwerk %c: ist beschÑdigt oder nicht formatiert.\r\n"
	 "Bitte Diskette formatieren. Weiter mit beliebiger Taste.\r\n",cDrive );

#else

		cprintf("The floppy in drive %c: is damaged or not formatted. Please\r\n"
			"reformat. Press any key to continue.\r\n",cDrive );

#endif
		cResp = (char) _dos_getch();
		RetVal = I24_TERM_PROG;
		}

	_ax = _ax & 0xFF00;		// Mask off low bytes (Drive)

	_ax = _ax | RetVal;		// OR in return value

}

// Query user displays message (arg1), and returns an int that points
// the the valid key

int QueryUser( char *pazInitMessage, char *pazRetryMessage, char *pazValidKey )
{
	char cResp;

	cprintf( "%s",pazInitMessage);

	cResp = (char) _dos_getch();
	cResp = (char) toupper( cResp );
	cprintf("%c\r\n",cResp);

	while ( !((int) strchr( pazValidKey , cResp )) )
			{
			cprintf("%s",pazRetryMessage );
			cResp = (char) _dos_getch();
			cResp = (char) toupper( cResp );
			cprintf("%c\r\n",cResp);
			}

	return( (int) ( strchr( pazValidKey, cResp ) - pazValidKey ) + 1 );
}

char _dos_getch( void )
{
	char	RetVal;

	_asm {

	mov ax,0000
	int 0x16
	mov RetVal,al

	}

	return( RetVal );

}

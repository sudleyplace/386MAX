//'$Header:   P:/PVCS/MAX/QMT/WRAPPER.C_V   1.0   05 Sep 1995 16:56:22   HENRY  $
//
// WRAPPER.C
//
// Copyright (C) 1993-94 Qualitas Inc.	GNU General Public License version 3.
//
// Program to take binary input (a .COM file) and produce MASM 5.1
// source.  Symbolic records are compiled in the .COM file to specify
// indentation and wrapping for the output MASM source.
//

#define VERSION "1.01"
#define COPYRIGHT_YEARS "1993-95"

#pragma  pack(1)
#define FAR	_far
#define NEAR	_near
#define  HUGE  _huge

#define TRUE  1
#define FALSE	0

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <io.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <fcntl.h>
#include <string.h>
#include <malloc.h>
#include <dos.h>

#include "wrapper.h"

#define  SIGNAL_CHAR 0x1B

long	hugeread( FHANDLE  hf , HPVOID hpvBuffer , long cbBuffer);
HPBYTE File2Mem( char *pszFileName, HPBYTE *phpbBuffer, long *plFileSize );
void lastsymlen ( void );
long dbCenter( char HUGE *hpString );
long dbSymbol( char HUGE *hpString );
long dbRawOut( char HUGE *hpString );
long dbOneSymbol( char HUGE *hpString );
long dbColor( char HUGE *hpString );

char	szFileName[ _MAX_DRIVE + _MAX_PATH + 8 + _MAX_EXT ];
char	szOutFile[ _MAX_DRIVE + _MAX_PATH + 8 + _MAX_EXT ];
char	szRowSym[256]="";                               // Symbol that holds the number of rows
char	szColSym[256]="";                               // Symbol that holds the number of cols
char	szSym[256]="";                                  // Symbol

char	Color = 0;			// Marks whether or not we use colors
char	CurColor = 0;			// If Color == 1, holds the current color #

int	iWidth=30,iIndent=0;		// Setup default values
char	CurrLine[256];				// Output line buffer
FILE	*fpOutFile;				// FOPEN style file pointer

void main(int argc, char *argv[] )					// Setup for parms
{
	HPBYTE	hpbInFile;				// Pointer to buffer
	long		lInFileSize;			// Size of our buffer
	long		i,IofLastSpace; 		// Positions in HUGE buffer
	int		CharPos,PosLastSpace; // Positions in CurrLine buffer
	int		CharPosCorr;			// Position in CurrLine buffer

// Check for proper params

	if((argc == 1) || argv[1][1]=='?' )                                     // If there are no args . . .
		{
		printf("WRAPPER   --  Version " VERSION " (C) Copyright " COPYRIGHT_YEARS " Qualitas, Inc.\n");
		printf("WRAPPER: \n"
				 "Syntax: WRAPPER infile[.COM] [outfile[.asm]] \n");
		exit(2);
		}

// Read infile into memory

	strcpy( szFileName , argv[1] );
	if( strchr( szFileName , '.' ) == NULL )
		strcat( szFileName , ".COM" );

	printf("Opening file: %s\n", szFileName );

// Transfer filename (file on disk) to memory

	File2Mem( szFileName, &hpbInFile, &lInFileSize );

	if ( argc == 3 )			// Was there a 2nd filename?
		strcpy( szOutFile, argv[2] );
	else
		{
		int	x;
		strcpy( szOutFile, szFileName );
		for ( x = strlen(szOutFile) ; x > 0 ; x-- )
			if ( szOutFile[x] == '.' )
				{
				szOutFile[x]='\0';
				break;
				}
		}

	if( strchr( szOutFile, '.' ) == NULL )
		strcat( szFileName , ".ASM" );

	printf("Creating file: %s\n",szOutFile);

	fpOutFile = fopen( szOutFile , "wt" );                  // Open file for writting

	CharPosCorr  = 0;			// Init some vars
	PosLastSpace = 0;			// . . .
	IofLastSpace = 0;			// . . .
	CharPos 	 = 0;			// . . .

	for ( i = 0 ; i < lInFileSize ; )
		{

			if ( hpbInFile[i] == SIGNAL_CHAR )
				switch( hpbInFile[++i] )
					{
					case 'I':               // Indent
						if ( CharPos == iIndent )
							CharPos = 0;

						iIndent = (int)hpbInFile[++i];	// Get indent value, update pointer
						i++;								// Move past Indent value in file
						break;

					case 'W':               // Set Width
						iWidth = hpbInFile[++i];	// Get indent value, update pointer
						i++;								// Move past Indent value in file
						break;

					case 'C':               // Center
					   i += dbCenter( (LPBYTE)(&hpbInFile[++i]) );
						break;

					case 'S':                                       // Symbol definition
						i += dbSymbol( (LPBYTE)(&hpbInFile[++i]) );
						break;

					case 'R':                                       // Raw Output
						i += dbRawOut( (LPBYTE)(&hpbInFile[++i]) );
						break;

					case 'O':                                       // One Symbol definition
						i += dbOneSymbol( (LPBYTE)(&hpbInFile[++i]) );
						break;

					case 'L':                                       // Color definition
						i += dbColor( (LPBYTE)(&hpbInFile[++i]) );
						break;

					case 'Z':                                       // End of text
						lastsymlen ();		// Dump row length for last text block
						szSym[0]='\0';          // Mark as unused
						szRowSym[0]='\0';
						szColSym[0]='\0';
						break;

					default:
						printf("Unknown ESCAPE sequence in input file!!\n");
						exit(5);					// Exit with error code to cancel NMAKE
					}
			else
				{

				CurrLine[CharPos] = hpbInFile[i]; // Transfer char

				switch( hpbInFile[i] )
				{
					case ' ':               // Record last space in line for future word wrap
						PosLastSpace = CharPos; // Record position in line
						IofLastSpace = i;			// Record position in buffer
						break;						// All done

					case '\'':              // If there is a '
						CurrLine[++CharPos]=hpbInFile[i]; // Write in a double '
						CharPosCorr++;						// Update the correction factor
						break;

					case 0x0D:		// CR
						IofLastSpace = 0;			// So we won't backup
						PosLastSpace = 0;			// For completness
						CurrLine[CharPos--] = '\0'; // Terminate Line
						break;

				}

				i++;								// Go to next char in buffer
				CharPos++;						// Go to next char in output stream

				if( (CharPos > iWidth+CharPosCorr ) || hpbInFile[i-1] == '\r' ) // Have we blown the width?
					{
					if ( ( hpbInFile[i] == ' ' || hpbInFile[i] == 0x0D ) && hpbInFile[i-1] != 0x0D )  // If next char is a space
						{
						i++;				   // Move over it (no leading spaces)
						IofLastSpace = 0; // It is OK not to back up
						}

					if ( IofLastSpace != 0 )	// Make sure the line had a word
						{
						i = IofLastSpace+1;		// Back up I (but after space)
						CharPos = PosLastSpace; //
						}

					while( CharPos <= (iWidth+CharPosCorr) )
						CurrLine[CharPos++]=' ';                // Blank out rest of line

					CurrLine[ CharPos ] = '\0'; // Write in a NULL

					CharPosCorr  = 0;			// Re-init some vars for next time
					PosLastSpace = 0;			// . . .
					IofLastSpace = 0;			// . . .
					CharPos 	 = 0;			// . . .

					if ( Color )				// If we're using colors, ...
					     fprintf(fpOutFile, " db %c, '%s'\n", CurColor + '0', CurrLine ); // Display Current color and Line
					else
					     fprintf(fpOutFile, " db '%s'\n", CurrLine ); // Display Line
					CurColor = 0;	// Turn it off for the next line

					if ( hpbInFile[i-1] != '\r' )
						while( CharPos < iIndent )	// Fill in indenting for next line
							CurrLine[CharPos++] = ' ';

					}

				}
		}


	exit(0);

}

void lastsymlen (void)
{
  if ( Color )		// If we're using colors
      fprintf(fpOutFile, "%s equ ($-%s)/(%s+1)\n\n",szRowSym, szSym, szColSym); // Display this line
  else
      fprintf(fpOutFile, "%s equ ($-%s)/%s\n\n",szRowSym, szSym, szColSym); // Display this line

}

long dbCenter( char HUGE *hpString )
{
	long  lLeftPad; // Get left padding
	long	i = 0;
	long	lStr=0;

	for ( lStr = 0 ; hpString[lStr]!='\0' ; lStr++ ); // Get String length
	lLeftPad = (iWidth - lStr) / 2;

	if ( Color )				// If we're using colors, ...
	     fprintf(fpOutFile, " db %c, '", CurColor + '0');
	else
	     fprintf(fpOutFile, " db '");

	for ( i = 0 ; i <= lLeftPad ; i++ ) // Print the leading blanks
		fputc(' ', fpOutFile );

	fprintf(fpOutFile, "%Fs", hpString );           // Print the string

	for ( i = lLeftPad + lStr ; i < iWidth ; i++ )
		fputc(' ', fpOutFile );

	fprintf(fpOutFile, "'\n");

	return( lStr+1 );
}

long dbRawOut( char HUGE *hpString )
{
	long	i = 0;

	fprintf(fpOutFile, "%Fs\n", hpString );         // Print the string (NULL Term)

	for ( i = 0 ; hpString[i]!='\0' ; i++ );

	return( i+1 );
}

long dbOneSymbol( char HUGE *hpString )
{
	long	i = 0;

	fprintf( fpOutFile, "\n");

	if ( (int)*szSym )    // If there was a symbol last time,
	     lastsymlen ();   // ... dump row length for last text block

	fprintf(fpOutFile, "\t public\t %Fs\n", hpString );     // Print the string (NULL Term)
	fprintf(fpOutFile, "%Fs\t label\t byte\n",hpString );           // Print symbol

	for ( i = 0 ; hpString[i]!='\0' ; i++ );

	return( i+1 );
}


long dbColor( char HUGE *hpString )
{
	Color = 1;		// Mark as using colors
	CurColor = hpString[0]; // Copy as the current color (0 = default)

	return( 1 );		// Skip over the clr
}


long dbSymbol( char HUGE *hpString )
{
	long	i=0;
	int	j=0;

	fprintf( fpOutFile, "\n");

	if ( (int)*szSym )    // If there was a symbol last time,
	     lastsymlen ();   // ... dump row length for last text block

	j = 0;
	while ( hpString[i] != '\0' )      // Skip the symbol
		szSym[j++] = hpString[i++];	  // Record SymbolName

	szSym[j] = hpString[i++];			  // Record NULL

	j = 0;
	while ( hpString[i] != '\0' )  // Skip the col def
		szColSym[j++] = hpString[i++];	  // Record RowSymbol for later

	szColSym[j] = hpString[i++];	  // Record NULL

	j = 0;
	while ( hpString[i] != '\0' )  // Skip the col def
		szRowSym[j++] = hpString[i++];	  // Record RowSymbol for later

	szRowSym[j] = hpString[i++];	  // Record NULL

	fprintf( fpOutFile, "\t public\t %s,%s,%s\n", szSym, szColSym, szRowSym);

	fprintf( fpOutFile, "%s\t label\t byte\n",szSym);               // Print symbol

	// Note: iWidth is not handled properly by WRAPPER.  If the width
	// is supposed to be 70, you get 71 columns.  The adjustment below
	// allows the equate to be set accurately.  In RAMEXAM, this is only
	// used in the ASK F1 help screen.
	fprintf( fpOutFile, "%s equ %d\n",szColSym, iWidth+1 );           // Print COL DEF

//	printf("RowSym = %s, Len of SYM = %l\n",szRowSym,i);

	return i;			// How many charactors processed
}

HPBYTE File2Mem( char *pszFileName, HPBYTE *phpbBuffer, long *plFileSize )
{
	int		hFile;					// file handle for .SYM file

	if( (hFile=open( pszFileName , O_BINARY | O_RDONLY )) == -1 ) /* Open the INFILE */
		{
		printf("\n\n%s could not be opened!\n",szFileName);
		exit(2);
		}

	if( ( *plFileSize = filelength( hFile )) == -1L )
		{
		printf("Problem determining %s's size.\n"
				 "Aborting program\n", pszFileName );
		exit(3);
		}

	*phpbBuffer = (HPBYTE) halloc( *plFileSize , sizeof(BYTE) );		// Allocate hugh chunk of memory

	if ( !*phpbBuffer )
		{
		printf("Not enough memory to read %s\n", pszFileName );

		exit(4);
		}

	if ( -1L == (hugeread( hFile , *phpbBuffer , *plFileSize )) )
		{
		printf("Problem reading %s", pszFileName );
		exit(5);
		}

	close (hFile);			// Clean up file (no need to keep it around

	return( *phpbBuffer );

}


long hugeread( FHANDLE	hf , HPVOID hpvBuffer , long cbBuffer)
{
	// reads from file handle hf into HUGE buffer for cbBuffer length
	// Returns -1L on failure (ran out of file)

	long		cbRequest = cbBuffer;
	int		rc;
	WORD		wLen;
	unsigned	wReadLen;

	while (cbBuffer)
		{
		wLen = (cbBuffer > 0x8000) ? 0x8000 : (WORD) (DWORD) cbBuffer;

		rc = _dos_read( hf , hpvBuffer , wLen, &wReadLen);
		if (rc || wReadLen != wLen) return (-1L);

		(HPBYTE) hpvBuffer += wLen;
		cbBuffer -= (long) (DWORD) wLen;
		}

	return (cbRequest);
}




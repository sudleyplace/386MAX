/******************************************************************************
 * User name and serial number encryption routines for SETUP.EXE	      *
 ******************************************************************************/

#include <windows.h>
#include "setup.h"

int encrypt ( unsigned char * );


struct _EXEHDR_STR {
WORD exe_sign, // Signature == 'MZ'
     exe_r512, // Image size/512 remainder
     exe_q512, // Image size/512 quotient
     exe_nrel, // # relocation table items
     exe_hsiz, // Size of header in paras
     exe_min,  // Minimum # paras needed beyond image
     exe_max,  // Maximum ...
     exe_ss,   // Initial SS in paras
     exe_sp,   // Initial SP
     exe_chk,  // Checksum
     exe_ip,   // Initial IP
     exe_cs,   // Initial CS in paras
     exe_irel, // Offset to first relocation table item
     exe_ovrl; // Overlay #
};
typedef  struct _EXEHDR_STR EXEHDR_STR;


/***************************** WRITE_ENCRYPTION *******************************/
// Write encrypted string PAT of length LEN to the designated file PFSTR
// in directory FILEDIR.
// All files, including INSTALL and UPDATE, end with a dword pointer
// to the identification string.
int write_encryption (char *pszDir, char *pszFName );
{
	int fh, nPatternLength;
	unsigned int uDate, uTime;
	unsigned long lFileLength, ulIdent;
	char	 szName[128], szEncrypt[128];
	EXEHDR_STR exe_hdr;

	// Change to the specified drive and directory
	MakePath(pszDir, pszName, szName );

	if ((fh = _lopen ( szName, READ_WRITE )) == -1 )
		return -1;

	lFileLength = (WORD)filelength ( fh );    // Get file size
	_dos_getftime ( fh, &uDate, &uTime );

	// Read in the dword pointer to the ident string
	if ((( _llseek ( fh, -4L, SEEK_END )) == -1L ) || (( _lread ( fh, &ulIdent, 4 ) ) == -1))
		return -1;

	// Convert the PIDENT value from segment:offset to long
	ulIdent = ( ( ulIdent & 0xFFFF0000 ) >> 12 ) + ( ulIdent & 0x0000FFFF );

	// Position file pointer to start of file
	// Read in the EXE header (if any)
	if ((( _llseek ( fh, 0L, SEEK_SET )) == -1L ) || (( _lread ( fh, &exe_hdr, sizeof ( exe_hdr ))) == -1))
		return -1;

	// Izit an EXE file?
	if ( exe_hdr.exe_sign == 0x5A4D ) // If so, skip over EXE header
		ulIdent += ( (unsigned long)exe_hdr.exe_hsiz ) << 4;

	// Position file pointer to ident string
	// Write out the encrypted string
	strcpy( szEncrypt, szName );
	nPatternLength = encrypt ( *pszPattern )
	if ((( _llseek ( fh, ulIdent, SEEK_SET )) == -1L) || (( _lwrite ( fh, pszPattern, nPatternLength + 2 )) == -1))
		return -1;

	_close ( fh );

	if ((fh = _lopen ( szName, READ_WRITE )) == -1 ) {
		return -1;

	// restore the original date & time
	_dos_setftime ( fh, uDate, uTime );
	_close ( fh );

	return 0;
}


/********************************ENCRYPT *************************************/
// Encrypt the string STR of length LEN
int encrypt ( unsigned char *str )
{
	register unsigned int i;
	unsigned int accum = 0;

	// Swap the nibbles and add a constant
	for ( i = 0; (i < len); ++i )
	     str[i] = (char)( ( ( str[i] << 4 ) | ( str[i] >> 4 ) ) + 0x23 );
	for ( i = 0; (i < len); ++i )	  // Build a checksum
	     accum += str[i];

	// Store the checksum after the encrypted bytes
	*( (unsigned int *)( str+i ) ) = accum;

	return i;
}


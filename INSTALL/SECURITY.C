/*' $Header:   P:/PVCS/MAX/INSTALL/SECURITY.C_V   1.5   02 Jan 1996 17:45:44   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * SECURITY.C								      *
 *									      *
 * User name and serial number encryption routines for INSTALL.EXE	      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>
#include <direct.h>
#include <dos.h>

#include "compile.h"
#include "common.h"
#include "extn.h"
#include "libtext.h"
#include "myalloc.h"

#define SECURITY_C
#include "instext.h"
#undef SECURITY_C

#ifndef PROTO
#include "security.pro"
#include "drve.pro"
#include "install.pro"
#include "misc.pro"
#include "scrn.pro"
#include "serialno.pro"
#include "pd_sub.pro"
#endif


//***************************** DO_ENCRYPTSRC **********************************
// Write the user's name and serial number to disk
// Note that source_subdir is always the directory we launched INSTALL.EXE
// from.
void	 do_encryptsrc ( void )
{

	 if (*user_company)		// If there's a valid company name
	 {
	     security_pattern[0] = 0x02;    // # lines in message
	     sprintf ( &security_pattern[1],
		       "%s %s\r\n%s %s - %s\r\n",
		       SERIALNUM_STR,
		       user_number,
		       LICENSEDTO,
		       user_name,
		    ///COMPANY_STR,
		       user_company
		       );
	 }
	 else
	 {
	     security_pattern[0] = 0x01;    // # lines in message
	     sprintf ( &security_pattern[1],
		       "%s %s - %s %s\r\n",
		       SERIALNUM_STR,
		       user_number,
		       LICENSEDTO,
		       user_name
		       );
	 }
	 encrypt ( security_pattern, SECURITY_LEN );
#ifndef CVDBG
	 write_encryption ( source_subdir,
			    &inst,
			    security_pattern,
			    SECURITY_LEN + SECURITY_CHK );
#endif

} // End of do_encryptsrc



//***************************** DO_ENCRYPTDEST **********************************
void	 do_encryptdest ( void )
{
int	 i;

	 do_backslash (dest_subdir);
	 for ( i = 0; i < OEM_IdentLen; i++) {
		 write_encryption ( dest_subdir,
				    &ident[0][i],
				    security_pattern,
				    SECURITY_LEN + SECURITY_CHK );
	 }

} // End do_encryptdest

/***************************** WRITE_ENCRYPTION *******************************/
// Write encrypted string PAT of length LEN to the designated file PFSTR
// in directory FILEDIR.
// All files, including INSTALL and UPDATE, end with a dword pointer
// to the identification string.
void write_encryption (char *filedir,		// Dir of file
		       FILESTRUC *pfstr,	// Ptr to file structure
		       char * pat,		// Pattern to write
		       int patlen)		// Length of ...
{
unsigned long pident;
char	 lclpfe[80];
EXEHDR_STR exe_hdr;

// Change to the specified drive and directory
	 strcpy ( lclpfe, filedir );	       // Copy drive and subdir
	 strcat ( lclpfe, pfstr->fname );	// Copy filename.ext

	 if ( -1 == ( pfstr->fhandle = open ( lclpfe, O_BINARY | O_RDWR ) ) ) {
		 do_textarg(1, lclpfe);
		 do_error(MsgUnLocate,0,FALSE);
		 return_to_dos(0);
	 } // End IF

	 pfstr->flen = (WORD)filelength ( pfstr->fhandle );    // Get file size
	 _dos_getftime ( pfstr->fhandle,
			 &pfstr->date,
			 &pfstr->time );		// Get file date & time

		 if ( -1L == ( lseek ( pfstr->fhandle, -4L, SEEK_END ) ) )
			error ( -1, MsgFilePosErr, lclpfe);

	 // Read in the dword pointer to the ident string
		 if ( -1 == ( read ( pfstr->fhandle, &pident, 4 ) ) )
			error ( -1, MsgFileRwErr, lclpfe);

	 // Convert the PIDENT value from segment:offset to long
		 pident = ( ( pident & 0xFFFF0000 ) >> 12 ) + ( pident & 0x0000FFFF );

	 // Position file pointer to start of file
		 if ( -1L == ( lseek ( pfstr->fhandle, 0L, SEEK_SET ) ) )
			error ( -1, MsgFilePosErr, lclpfe);

	 // Read in the EXE header (if any)
		 if ( -1 == ( read ( pfstr->fhandle, &exe_hdr, sizeof ( exe_hdr ) ) ) )
			error ( -1, MsgFileRwErr, lclpfe);

	 // Izit an EXE file?
		 if ( exe_hdr.exe_sign == 0x5A4D ) // If so, skip over EXE header
			pident += ( (unsigned long)exe_hdr.exe_hsiz ) << 4;

	 // Position file pointer to ident string
		 if ( -1L == ( lseek ( pfstr->fhandle, pident, SEEK_SET) ) )
			error ( -1, MsgFilePosErr, lclpfe);

// Write out the encrypted string
	 if ( -1 == ( write ( pfstr->fhandle, pat, patlen ) ) )
			error ( -1, MsgFileRwErr, lclpfe);
	 close ( pfstr->fhandle );

// Re-open the file so we can restore the original date & time
	 if ( -1 == ( pfstr->fhandle = open ( lclpfe, O_BINARY | O_RDWR ) ) ) {
		 do_textarg(1,lclpfe);
		 do_error(MsgUnLocate,0,FALSE);
		 return_to_dos(0);
	 } // End IF

	 _dos_setftime ( pfstr->fhandle, pfstr->date, pfstr->time );
	 close ( pfstr->fhandle );

} // End write_encryption


/********************************ENCRYPT *************************************/
// Encrypt the string STR of length LEN
void	 encrypt ( unsigned char *str, unsigned int len )
{
unsigned int i;
unsigned int accum = 0;

// Swap the nibbles and add a constant
	 for ( i = 0; i < len; ++i )
	     str[i] = (char)( ( ( str[i] << 4 ) | ( str[i] >> 4 ) ) + 0x23 );
	 for ( i = 0; i < len; ++i )	  // Build a checksum
	     accum += str[i];
// Store the checksum after the encrypted bytes
	 *( (unsigned int *)( str+i ) ) = accum;

} // End ENCRYPT

/********************************DECRYPT *************************************/
// Decrypt the string STR of length LEN
void	 decrypt ( unsigned char *str, unsigned int len )
{
unsigned int i;

// Sub a constant and swap the nibbles
	 for ( i = 0; i < len; ++i )
	 {
	     str[i] -= 0x23;
	     str[i] = (char)( ( str[i] << 4 ) | ( str[i] >> 4 ) );
	 }

} // End DECRYPT

//*****************************  DO_UPDATE *************************************
// This routine checks for IDed files in update_dest_subdir
// and confirms that they are valid.
// If they are valid it copies the ID string to UPDATE.EXE.
// Otherwise, it prompts the user for another subdirectory to check.
// We don't leave this routine until we find valid files,
// or the user says to continue anyway.
void	 do_update ( void )
{
int	 i;

KEYCODE key;
char security_save;

LOOP:

// Handle the possibility that the individual would like to update
// a floppy in the same drive as the update disk
	 if (!strnicmp (update_subdir, source_drive, 1) &&
		!is_fixed (*source_drive)) {
		 chk_flpydrv ( DESTDSK, OEM_CHKFILE, 1, 1);
	 }
// This loop checks for previously installed 386MAX or BlueMAX files
//	 j == 0 is 386MAX file names
//	 j == 1 is BlueMAX file names
// In order to be a valid previous installation, we need one file
//  from each column present

	 for ( i = 0; i < OEM_IdentReqLen; i++ )
		if ( read_encryption ( update_subdir, &ident[0][i]) != 0
		&&   read_encryption ( update_subdir, &ident[1][i]) != 0)
		     break;

	 if ( i < OEM_IdentReqLen ) {

		 // Returns KEY_ALTC   for "Continue",
		 //	    KEY_ALTB   for "Back",
		 //	    KEY_ESCAPE for "Exit"
		 key = do_badupd(MsgBadUpdSubdir,0);
		 if (key == KEY_ALTB)
		 {
		     get_updatedir ();
		     goto LOOP;
		 }
		 else if (key == KEY_ESCAPE)
		 {
		     reset_video();
		     exit(-1);
		 }
	 }

// ID the update file itself on the update diskette
#ifndef CVDBG
	 if (!ReInstall)
	  write_encryption ( source_subdir, &inst, security_pattern,
			    SECURITY_LEN + SECURITY_CHK );
#endif
	 strcpy ( dest_subdir, update_subdir );

} // End of do_update routine


/***************************** READ_ENCRYPTION *******************************/
// Read encrypted string PAT of length LEN from the designated file PFSTR
// in directory filedir. All files end with a dword pointer to the
// identification string.
// Return 0 if all goes well.
int	 read_encryption ( char *filedir,	// Dir of file
			   FILESTRUC *pfstr)	// Ptr to FILE
{
EXEHDR_STR exe_hdr;
unsigned long pident;
char	 lclpfe[80],
	 buffer[SECURITY_CHK+350];
static char old_security_pattern[SECURITY_CHK+350];
int	 rc = 1,
	 i;

// Copy the specified drive and directory to a local variable
// and open the file in question
	 strcpy ( lclpfe, filedir );
	 do_backslash ( lclpfe );
	 strcat ( lclpfe, pfstr->fname );
	 if ( !access ( lclpfe, 0 ) ) {
		 if ( -1 == ( pfstr->fhandle = open ( lclpfe, O_BINARY | O_RDONLY ) ) ) {
			error ( -1, MsgFileRwErr, pfstr->fname );
		 }
	 } else {
		 return ( rc );
	 }

		 if ( -1L == ( lseek ( pfstr->fhandle, -4L, SEEK_END ) ) ) {
			error ( -1, MsgFilePosErr, pfstr->fname );
		 }
		 if ( -1 == ( read ( pfstr->fhandle, &pident, 4 ) ) ) {
			error ( -1, MsgFileRwErr, pfstr->fname );
		 }
		 pident = ( ( pident & 0xFFFF0000 ) >> 12 )
			  + ( pident & 0x0000FFFF );
		 if ( -1L == ( lseek ( pfstr->fhandle, 0L, SEEK_SET ) ) ) {
			error ( -1, MsgFilePosErr, pfstr->fname );
		 }
		 if ( -1 == ( read ( pfstr->fhandle, &exe_hdr, sizeof( exe_hdr ) ) ) ) {
			error ( -1, MsgFileRwErr, pfstr->fname );
		 }
		 if ( exe_hdr.exe_sign == 0x5A4D ) {
			pident += ( (unsigned long)exe_hdr.exe_hsiz ) << 4;
		 }
		 if ( -1L == ( lseek ( pfstr->fhandle, pident, SEEK_SET ) ) ) {
			error ( -1, MsgFilePosErr, pfstr->fname );
		 }

// Read the encrypted string and close the file
	 if ( -1 == ( read ( pfstr->fhandle, buffer, SECURITY_LEN+SECURITY_CHK ) ) ) {
		 error ( -1, MsgFileRwErr, pfstr->fname );
	 }
	 close ( pfstr->fhandle );
	 if ( -1 == ( pfstr->fhandle = open ( lclpfe, O_BINARY | O_RDONLY ) ) ) {
		 error ( -1, MsgFileRwErr, pfstr->fname );
	 }
	 close ( pfstr->fhandle );

// If this is the first time through, save the string into
// old_security_pattern.  If not, compare the string in buffer
// to old_security_pattern to verify all the appropriate files
// are IDed correctly.

	if (old_security_pattern[0] != '\0')
	{
	    for ( i = 0; i < SECURITY_LEN+SECURITY_CHK
		  && buffer[i] == old_security_pattern[i];
		  i++);
	    if ( i != SECURITY_LEN+SECURITY_CHK )
		 return ( rc );
	}
	else
	    memcpy ( old_security_pattern, buffer, SECURITY_LEN+SECURITY_CHK);

	 rc = 0;
	 return ( rc );

} // End read_encryption

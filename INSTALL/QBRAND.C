/*' $Header:   P:/PVCS/MAX/INSTALL/QBRAND.C_V   1.1   11 Nov 1995 13:14:22   BOB  $ */
/****************************************************************************
 *																			*
 * (C) Copyright 1991-2003 Qualitas, Inc.  All rights reserved. 			*
 *																			*
 * QBRAND.C 																*
 *																			*
 * Standalone program for branding of programs with user information		*
 *																			*
 ***************************************************************************/

/*
 * Displays encrypted data, and also allows branding of programs outside of
 * INSTALL.
 *
 * This program's source code, object modules, listings, and map files
 * are Qualitas confidential and are NOT to be distributed.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <io.h>
#include <fcntl.h>
#include <dos.h>
#include <process.h>
#include <string.h>
#include <memory.h>

#include "commfunc.h"
#include "common.h"

#define SECURITY_LEN 350		// Length of Pattern

extern unsigned char Pattern[SECURITY_LEN];
char serial_data [81];
int force = 0;				// If true, allows encryption to be
					// re-entered.

void error (char *msg)
{
 printf ("QBRAND: %s\n", msg);
 exit (-1);
} // error ()

/********************************ENCRYPT *************************************/
// Encrypt Pattern
void	 encrypt (void)
{
unsigned int i;
unsigned int accum = 0;

// Swap the nibbles and add a constant
	 for ( i = 0; i < SECURITY_LEN; ++i )
		 Pattern[i] = (char)
			( ( (Pattern[i] << 4) | (Pattern[i] >> 4) ) + 0x23);
	 for ( i = 0; i < SECURITY_LEN; ++i )	  // Build a checksum
		 accum += (unsigned int) Pattern[i];

// Store the checksum after the encrypted bytes
	 *( (unsigned int *)( Pattern+i ) ) = accum;

} // End ENCRYPT

int process_file (char *fname)
{
 int fh,res;
 EXEHDR_STR exe_hdr;
 unsigned int date,time;
 signed long fptr;
 int valid_data;

#define SERIAL_LEN	12
#define USER_LEN	44
#define COMPANY_LEN 44
 char serialnum  [SERIAL_LEN  + 1];
 char username	 [USER_LEN	  + 1];
 char companyname[COMPANY_LEN + 1];
 char work[81];

 res = 0;
 if ((fh = open (fname, O_BINARY | O_RDWR)) == -1)
  printf ("Warning: could not open %s\n", fname);
 else {

  _dos_getftime (fh, &date, &time);

  if (lseek (fh, -((long) sizeof (fptr)), SEEK_END) == -1) {
	printf ("%s: could not seek to end\n", fname);
	goto Close_file;
  }

  if (read (fh, &fptr, sizeof (fptr)) == -1) {
	printf ("%s: could not read long ptr at end of file\n", fname);
	goto Close_file;
  }

  fptr = ( ( fptr & 0xFFFF0000L ) >> 12 ) + ( fptr & 0x0000FFFFL );

  if (lseek (fh, 0L, SEEK_SET) == -1) {
	printf ("%s: could not seek to beginning\n", fname);
	goto Close_file;
  }

  if (read (fh, &exe_hdr, sizeof (exe_hdr)) == -1) {
	printf ("%s: could not read file header\n", fname);
	goto Close_file;
  }

  if (exe_hdr.exe_sign == 0x5a4d)	// If .EXE format, skip over header
	fptr += ((unsigned long) exe_hdr.exe_hsiz) << 4;

  if (lseek (fh, fptr, SEEK_SET) == -1) {
	printf ("%s: could not seek to security location\n", fname);
	goto Close_file;
  }

  if (read (fh, Pattern, SECURITY_LEN+SECURITY_CHK) == -1) {
	printf ("%s: could not read security pattern\n", fname);
	goto Close_file;
  }

  close (fh);
  if ((fh = open (fname, O_BINARY | O_RDWR)) == -1) {
	printf ("%s: could not re-open\n", fname);
	return (0);
  }

  // See if there is already valid encrypted data there
  if (decrypt_serialno (serial_data, 80) == TRUE)
	valid_data = 1;
  else
	valid_data = 0;

  if (valid_data) {
	printf ("%s: %d line(s) of encrypted data:\n%s", fname,
		(int) *serial_data, serial_data+1);
	if (!force) {
		res = 1;
		goto Close_file;
	}
  }
  else if (strncmp (Pattern, "0123456789", 10)) {
	printf ("%s: file does not appear to have an encrypted data section\n",
		fname);
	goto Close_file;
  }

  // Ask user for data to encrypt and insert
  printf (
"                                      ____.____1__\n"
"Serial number (press ENTER to abort): ");
  *work = '\0';
  if (gets (work) == NULL || !(*work))
	goto Close_file;
  strncpy (serialnum, work, SERIAL_LEN);
  serialnum [SERIAL_LEN] = '\0';

  printf (
"                               ____.____1____.____2____.____3____.____4____\n"
"User name (%d characters max): ", USER_LEN);
  *work = '\0';
  if (gets (work) == NULL || !(*work))
	goto Close_file;
  strncpy (username, work, USER_LEN);
  username [USER_LEN] = '\0';

  printf (
"                               ____.____1____.____2____.____3____.____4____\n"
"Company name (%d chars max):   ", COMPANY_LEN);
  *work = '\0';
  if (gets (work) == NULL || !(*work))
	goto Close_file;
  strncpy (companyname, work, COMPANY_LEN);
  username [COMPANY_LEN] = '\0';

  // Ensure Pattern is initialized to 0's
  memset (Pattern, 0, sizeof(Pattern));

  // Encrypt data
  if (*companyname) 		// If there's a valid company name
	  sprintf (Pattern, "\x02Serial # %s\r\nLicensed to %s - %s\r\n",
				serialnum, username, companyname);
  else
	  sprintf (Pattern, "\x01Serial # %s - Licensed to %s\r\n",
				serialnum, username);
  encrypt ();

  // Write it out
  if (lseek (fh, fptr, SEEK_SET) == -1) {
	printf ("%s: could not seek to security location (2)\n", fname);
	goto Close_file;
  }
  if (write (fh, Pattern, SECURITY_LEN+SECURITY_CHK) == -1) {
	printf ("%s: unable to write security pattern to file\n", fname);
	goto Close_file;
  }

  // Restore file date/time
  _dos_setftime (fh, date, time);

  res = 1;

Close_file:
  close (fh);

 }

 return (res);

}

int main (int argc, char **argv)
{
 int i,fcount;

 printf ("QBRAND  v0.15   Copyright (C) 1991-2003, Qualitas, Inc.\n"
		 "                For internal use only\n");

 if (argc < 2)
	error ("No filename specified.");

 for (i=1,fcount=0; i<argc; i++) {

	if (argv[i][0] == '-' || argv[i][0] == '/')
	{
		switch (argv[i][1])
		{
			case 'f':
				force = 1;
				break;
			default:
				error ("Valid options are -f (force write)");
		}
	} else
		if (process_file (argv[i]))
			fcount++;

 }

 printf ("\n%d file(s) processed.\n", fcount);

 return (0);
} // End main ()


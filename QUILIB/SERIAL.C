/*' $Header:   P:/PVCS/MAX/QUILIB/SERIAL.C_V   1.0   05 Sep 1995 17:02:22   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * SERIAL.C								      *
 *									      *
 * Function to decode serial number and user name			      *
 *									      *
 ******************************************************************************/

#include "commdef.h"            /* Common definitions */
#include "commfunc.h"           /* Common functions */

#define SECURITY_LEN 350	/* Total bytes in security pattern */

/*
 *	Here's the important part.  This array gets filled with
 * the encrypted serial number by the INSTALL program.
 */

BYTE Pattern[] =
	/* SECURITY_LEN bytes of data space */
	"01234567890123456789012345678901234567890123456789"
	"01234567890123456789012345678901234567890123456789"
	"01234567890123456789012345678901234567890123456789"
	"01234567890123456789012345678901234567890123456789"
	"01234567890123456789012345678901234567890123456789"
	"01234567890123456789012345678901234567890123456789"
	"01234567890123456789012345678901234567890123456789"
	/* A Place for the checksum */
	"??"
	;


BOOL decrypt_serialno ( /* Decrypt the serial number string */
	char *str,	/* String returned here */
	int len )	/* Max length of string */
/* Return:  TRUE of ok, FALSE if bogus */
{
	int kk;
	WORD sum;
	BYTE *src;
	BYTE *dst;

	/* First, check the checksum */
	sum = 0;
	src = Pattern;
	for (kk = 0; kk < SECURITY_LEN; kk++) {
		sum += *src++;
	}

	if (sum != *(WORD *)src) return FALSE;

	/* Checksum ok, decrypt the string */
	src = Pattern;
	dst = str;
	for (kk = 0; kk < len; kk++) {
		/* Subtract a constant and swap the nibbles  */
		BYTE cc;

		cc = (BYTE)((*src++) - 0x23);
		*dst++ = (BYTE)((cc << 4) | (cc >> 4));
	}
	return TRUE;
}

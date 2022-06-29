/*' $Header:   P:/PVCS/MAX/QUILIB/FILEDIFF.C_V   1.1   30 May 1997 12:09:00   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * FILEDIFF.C								      *
 *									      *
 * Functions to produce a VDIFF 					      *
 *									      *
 ******************************************************************************/

/*
 * Write differences between two files to a third file
 * Returns number of lines added+deleted+changed
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <io.h>
#include <dos.h>
#include <graph.h>
#include <conio.h>
#include <stdarg.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>

#include "filediff.h"
#include "dmalloc.h"
#include "libtext.h"
#include "myalloc.h"

#define MAXLEN 256
#define MAXLINES 1024
#define MAXOVECT 8192	// Max hash values div 8
#define MAXOUTLEN	(MAXLEN+MSGOUTLEN)

// Error function - caller must make this available and the args must match
extern void error (int errcode,char *fmt,...);

// Local functions

// Local variables
int lastline1,lastline2;

//*************************** HASHSTR ************************************
// Hash a character string
long hashstr (unsigned char *s)
{
	long h=0, h1;

	while (*s) {
		h1 = h;
		h <<= 1;
		if (h1 < 0)
		 h |= 1;
		h ^= *s++;
	}

	return (h ? h : 1);

} // hashstr

//*********************** GETSET ********************************************
// Get or set specified bits in occurrence vector
unsigned char getset (unsigned char far *vector, long idx, unsigned char c, int flag)
{
	int i, j, shift;

	idx &= 0x7fff;		// Get value mod 32K
	i = (int) (idx >> 2);	// Get index into occurrence vector
	j = (int) idx - (i << 2); // Get index modulo 4
	shift = (3-j) << 1;	// Bits to shift
	if (flag)		// Replace bits
	 vector [i] = (unsigned char ) ((vector [i] & ~(0x03 << shift)) | (c << shift));

				// Return new value, right justified
	return ((unsigned char) ((vector[i] >> shift) & 0x03));
} // getset

//**************************** BUILD_HASH *********************************
// Build hash table for specified file
int build_hash (FILE *f, long far hvect[], unsigned char far ovect[])
{
 int i;
 char buff[MAXLEN+1];
 long hash;
 unsigned char bits;

 for (i=0; i < MAXLINES; i++) {
  if (fgets (buff, MAXLEN, f)) {

   // If line was truncated, ensure there is a null terminator
   buff [MAXLEN] = '\0';

   strupr (buff);		// Make it case insensitive
   hash = hashstr (buff);	// Hash it
   hvect [i] = (hash < 0 ? hash : -hash);
				// Make sure sign bit is set
   bits = getset (ovect, -hvect[i], 0, 0);
				// Get bits from occurrence vector
   if (!bits)
	getset (ovect, -hvect[i], 1, 1);
   else
    if (bits == 1)
	getset (ovect, -hvect[i], 2, 1);

  }
  else	// End of file
	return (i);
 } // for ()

 // If we got this far, file was truncated
 return (i - 1);

} // build_hash

//********************** DUMP_DIFF ***********************************
// Display changed lines
void dump_diff(FILE *f3, FILE *f1, int line1, FILE *f2, int line2)
{
	char buff[MAXLEN+1];
	int kk;

	if (line1 >= 0) {
		for (kk = lastline1; kk <= line1; kk++)
			fgets (buff, MAXLEN, f1);
		buff[MAXLEN] = '\0';    // Make sure it ends somewhere

		lastline1 = line1 + 1;
		fprintf (f3, "%s%s", /* line2>=0 ? MsgOldLine : */ MsgDelLine, buff);

	} // line1 valid

	if (line2 >= 0) {
		for (kk = lastline2; kk <= line2; kk++)
			fgets (buff, MAXLEN, f2);
		buff[MAXLEN] = '\0';    // Make sure it ends somewhere

		lastline2 = line2 + 1;
		fprintf (f3, "%s%s", /* line1>=0 ? MsgNewLine : */ MsgAddLine, buff);

	} // line2 valid
}

//********************* DUMP_COMM **********************************
// Display unchanged line
void dump_comm(FILE *f3, FILE *f1, int line)
{
	char buff[MAXLEN+1];
	int kk;

	for (kk = lastline1; kk <= line; kk++)
		fgets (buff, MAXLEN, f1);
	buff[MAXLEN] = '\0';    // Make sure it ends somewhere

	lastline1 = line + 1;
	fprintf (f3, "%s%s", MsgSameLine, buff);

}

//**************************** file_diff **********************************
// Write differences between file 1 and file 2 to file 3
// file 2 is assumed to be the new file name
int file_diff(char *file1,char *file2,char *file3)
{
	FILE *f1;
	FILE *f2;
	FILE *f3;
	unsigned char _far *occur1;
	unsigned char _far *occur2;
	long _far *hashtab1;
	long _far *hashtab2;
	int n1,n2,i,j,k,diffcnt;

	// Open files
	f1 = fopen(file1,"r");
	f2 = fopen(file2,"r");
	f3 = fopen(file3,"w");
	if (!f1 || !f2 || !f3) {
		error ( -1, MsgFileErr, file1 );
	}

	// Allocate hash tables and occurrence vectors
	occur1 = (unsigned char _far *) _dmalloc (MAXOVECT);
	occur2 = (unsigned char _far *) _dmalloc (MAXOVECT);
	_fmemset (occur1, 0, MAXOVECT);
	_fmemset (occur2, 0, MAXOVECT);
	hashtab1 = (long _far *) _dmalloc (MAXLINES * sizeof (long));
	hashtab2 = (long _far *) _dmalloc (MAXLINES * sizeof (long));
	if (!occur1 || !occur2 || !hashtab1 || !hashtab2)
		error (-1, MsgFDMallocErr);

	fprintf(f3,MsgChgsMade,file1);

	// Read and hash both files
	n1 = build_hash (f1, hashtab1, occur1);
	n2 = build_hash (f2, hashtab2, occur2);

	// Reset file pointers
	fseek (f1, 0L, SEEK_SET);
	fseek (f2, 0L, SEEK_SET);

	// Find lines that are unique in both files
	for (i = 0; i < MAXOVECT; i++)
	 occur1[i] &= occur2[i];

	// Link together matching unique lines
	for (i=0; i<n1; i++) {

		if (getset (occur1, -hashtab1[i], 0, 0) != 1)
			continue;

		for (j=0; i+j < n2 || i-j >= 0; j++) {

			if (i+j < n2 && hashtab2 [i+j] == hashtab1 [i]) {
				hashtab1 [i] = i+j;
				hashtab2 [i+j] = i;
				break;
			} // forward match

			if (i-j >= 0 && hashtab2 [i-j] == hashtab1 [i]) {
				hashtab1 [i] = i-j;
				hashtab2 [i-j] = i;
				break;
			} // backward match

		} // for (j;;)

	} // for (i;;)

	// Link first and last lines
	if (hashtab1 [0] < 0 && hashtab1 [0] == hashtab2 [0])
		hashtab1 [0] = hashtab2 [0] = 0;
	if (hashtab1 [n1-1] < 0 && hashtab1 [n1-1] == hashtab2 [n2-1]) {
		hashtab1 [n1-1] = n2-1;
		hashtab2 [n2-1] = n1-1;
	}

	// Start with linked lines and link following lines that match
	for (i = j = 0; i < n1; i++) {
		if (hashtab1 [i] >= 0)
			j = 1;
		else
		if (j) {

			if (hashtab1 [i] == hashtab2 [hashtab1 [i-1] + 1]) {
				hashtab1 [i] = hashtab1 [i-1] + 1;
				hashtab2 [hashtab1 [i]] = i;
			}
			else
				j = 0;

		} // if (j)

	} // for (i=j=0;;)

	// Now link preceding lines that match
	for (i = n1-1, j = 0; i >= 0; i--) {

		if (hashtab1 [i] >= 0)
			j = 1;
		else
		if (j) {

			if (hashtab1 [i] == hashtab2 [hashtab1 [i+1] - 1]) {
				hashtab1 [i] = hashtab1 [i+1] - 1;
				hashtab2 [hashtab1 [i]] = i;
			} else
				j = 0;

		} // if (j)

	} // for (i;;)

	// Display differences and keep track of total changes
	lastline1 = lastline2 = 0;
	for (i = j = diffcnt = 0; i < n1 && j < n2; ) {

		if (hashtab1 [i] < j && hashtab2 [j] < i) {
			dump_diff (f3, f1, i++, f2, j++);
			diffcnt++;
		}
		else if (hashtab1 [i] < j) {
			dump_diff (f3, f1, i++, f2, -1);
			diffcnt++;
		}
		else if (hashtab2 [j] < i) {
			dump_diff (f3, f1, -1, f2, j++);
			diffcnt++;
		}
		else if (hashtab1 [i] == j) {
			for (k=1; i + k < n1 && j + k < n2 &&
				 hashtab1 [i + k] == j + k; k++)
				dump_comm (f3, f1, k+i-1);
			i += k; 	// Matching lines
			j += k;
			// Dump last line of common section
			dump_comm (f3, f1, i-1);
		}
		else if (hashtab1 [i] - j <= hashtab2 [j] - i) {
			for (k=j; (long) k < hashtab1 [i]; k++)
				dump_diff (f3, f1, -1, f2, k);
			diffcnt += (k-j);
			j = (int) hashtab1 [i];
		}
		else {
			for (k=i; (long) k < hashtab2 [j]; k++)
				dump_diff (f3, f1, k, f2, -1);
			diffcnt += (k-i);
			i = (int) hashtab2[j];
		}

	} // for ()

	if (i<n1)
		for (k = i; k < n1; k++)
		 dump_diff (f3, f1, k, f2, -1);
	if (j<n2)
		for (k = j; k < n2; k++)
		 dump_diff (f3, f1, -1, f2, k);

	// Add in left over lines
	if (i<n1) diffcnt += (n1 - i);
	if (j<n2) diffcnt += (n2 - j);

	_dfree (occur1);
	_dfree (occur2);
	_dfree (hashtab1);
	_dfree (hashtab2);

	fclose (f1);
	fclose (f2);
	if (f3 != stdout) fclose (f3);

	return (diffcnt);	// number of differences found

} // file_diff()

/*' $Header:   P:/PVCS/MAX/MAXIMIZE/UTIL.C_V   1.2   26 Oct 1995 21:55:18   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * UTIL.C								      *
 *									      *
 * Small utility functions						      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

#include <commdef.h>		/* Common definitions */
#include <libtext.h>		/* Language definitions */
#include <myalloc.h>		/* Memory allocation */

#define UTIL_C		/* ..to select message text */
#include "maxtext.h"	/* MAXIMIZE message text */
#undef UTIL_C

#include "maxvar.h"

#ifndef PROTO
#include "maximize.pro"
#include "screens.pro"
#include "util.pro"
#endif /*PROTO*/

static void __leda (long num, char *s);
static void __ltoa (char *s, long num, unsigned int size);
static void memory_panic (char *name,WORD size);

/*-------------------------------------------------------------*/
/*  String compression module - eliminates leading and trailing*/
/*  whitespace, replaces multiple embedded whitespace with a   */
/*  single space, eliminates all whitespace on each side of    */
/*  special characters found (the list is in brk below).       */
/*  Returns a pointer to the compressed string. The string     */
/*  returned is on the heap and may be released with free()    */
/*-------------------------------------------------------------*/

static char *brk = "= ";

/********************************** STRCMPRSS *********************************/

/* Remove whitespace from string */
char *strcmprss (char *str)
{
	char *p;
	int len;

	str = str_mem (str);

	/* Convert tabs to blanks */
	while ((p = strchr (str, '\t'))!=0)
		*p = ' ';

	/*---------------------------------------------------------*/
	/*	Eliminate trailing white space			       */
	/*---------------------------------------------------------*/

	len = strlen (str);
	while (--len)
		if  (str[len] == ' ' || str[len] == '\t' || str[len] == '\n')
			str[len] = '\0';
		else
			break;

	/*---------------------------------------------------------*/
	/*	Replace multiple spaces with a single space	       */
	/*---------------------------------------------------------*/

	for (p = str ; *p ;)
		if (p[0] == ' '
		    && p[1] == ' ')
			strcpy (p, p + 1);
		else
			p++;

	/*---------------------------------------------------------*/
	/*	Eliminate leading space (only one at this point)       */
	/*---------------------------------------------------------*/

	if (*str == ' ')
		strcpy (str, str + 1);

	/*---------------------------------------------------------*/
	/*	Eliminate spaces on each side of special characters    */
	/*---------------------------------------------------------*/

	for (p = str ; *p ; p++)
		if (strchr (brk, p[0]) != NULL)
			if (p[1] == ' ')
				strcpy (p + 1, p + 2);

	for (p = str ; *p ; p++)
		if (p[0] == ' ')
			if (strchr (brk, p[1]) != NULL)
				strcpy (p, p + 1);

	return (str);
} /* End STRCMPRS */


static char hexd[] = "0123456789abcdef";

/********************************** SCANHEX ***********************************/
/* Convert hex to int */

char *scanhex (char *stp, WORD *addr)

{
	for (*addr = 0; isxdigit (*stp); stp++)
	{
		*addr <<= 4;		/* Shift over one hex digit */
		*addr += strchr (hexd, tolower (*stp)) - hexd;
	} /* End WHILE */

	return (stp);

} /* End SCANHEX */

/********************************** SCANLHEX **********************************/
/* Convert hex to long */

char *scanlhex (char *stp, DWORD *addr)

{
	for (*addr = 0L; isxdigit (*stp); stp++)
	{
		*addr <<= 4;		/* Shift over one hex digit */
		*addr += strchr (hexd, tolower (*stp)) - hexd;
	} /* End WHILE */

	return (stp);

} /* End SCANLHEX */

/********************************** SCANLDEC **********************************/
/* Convert decimal to long */

char *scanldec (char *stp, DWORD *addr)

{
	for (*addr = 0L; isdigit (*stp); stp++)
	{
		*addr *= 10;		/* Shift over one decimal digit */
		*addr += *stp - '0';
	} /* End WHILE */

	return (stp);

} /* End SCANLDEC */

/*------------------------------------------------*/
/*						  */
/*    lcm - compare strings			  */
/*						  */
/*    if one string is shorter than the other,	  */
/*    assume the shorter contains spaces to	  */
/*    the size of the longer string. Results	  */
/*    are as for strcmp.			  */
/*						  */
/*------------------------------------------------*/

int lcm(char *s1, char *s2)
{
	while (*s1 && *s2)
		if  (*s1 < *s2)
			return (-1);
		else if (*s1++ > *s2++)
			return (1);
	while (*s1)
		if  (*s1++ != ' ')
			return (1);
	while (*s2)
		if  (*s2++ != ' ')
			return (-1);
	return (0);
}

/************************************* FNDDEV *********************************/
/* Find beginning of filename.ext in d:\path\filename.ext */
/* FLAG = 1 to keep the file extension */
/*	= 0 to delete it */

char * fnddev (char *s, int flag)
{
	char *p;

	if (strchr (s, '\\') == NULL) {
		/* If no path separator */
		p = strchr (s, ':');            /* Try for drive separator */
		if  (p	== NULL)		/* If none, ... */
			return (stripname (s, flag)); /* return original ptr w/o invalid FID */
		return (p + 1); 		/* Otherwise, skip over drive separator */
	} /* End IF */

	for (;;) {
		/* We know there's at least one */
		p = strchr (s, '\\');           /* Search for path separator */
		if (p  == NULL) 		/* If no more, ... */
			return (stripname (s, flag)); /* return ptr after last w/o invalid FID */
		s = p + 1;			/* Otherwise, skip over and continue on */
	} /* End WHILE */

} /* End FNDDEV */

/******************************** STRIPNAME ***********************************/
/* Strip off trailing invalid file id chars */
/* The input starts with valid filename and might end with invalid */
/*   chars such as "/." etc. */

/* FLAG = 1 to keep the file extension */
/*	= 0 to delete it */

char * stripname (char *inp, int flag)
{
	BYTE *p;

	/* First, search for discontiguous invalid chars */
	p = strpbrk (inp, "\"/[]|<>+=;,.");
	if (p != NULL && ((flag == 0) || *p != '.'))
		*p = '\0';       /* Terminate the string at the first invalid char */

	/* Next, search for contiguous invalid chars (00-1F) */
	p = inp;
	while (*p) {
		if (*p < 0x1F) {
			/* Note dependence on unsigned */
			*p = '\0';    /* Zap it */
			break;
		} /* End IF */
		else p++;		/* Skip to next char */
	}
	/* Ensure the filename is no longer than 8 chars */
	p = strchr (inp, '.');  // Get ptr to extension separator (if present)
	if (p) {		// If the extension is present,
	    if ((p - inp) > 8)	// and the filename is too long
		strcpy (inp + 8, p); // Copy the tail over it
	} /* End IF */
	else
	    inp[8] = '\0';      // Just zap it

	return (inp);

} /* End STRIPNAME */

/************************************ LTOE ************************************/
/* Convert long to edited string */
char *ltoe (long num, int frac)

{
	static char to[20];
	int divs, f;
	long rem;

	to[0] = '\0';
	rem = 0;
	f = frac;
	if	(num < 0)
	{
		strcat (to, "-");
		num = -num;
	}
	if	(frac > 0)
	{
		for (divs = 10 ; frac > 1 ; frac--)
			divs *= 10;
		rem = num % divs;
		num /= divs;
	}
	__leda (num, to);
	if	(f > 0)
	{
		int slen;

		slen = strlen (to);
		to[slen] = NUM_DECIMAL; 	/* Add '.' in US */
		to[slen+1] = '\0';              /* Terminate string */
		__ltoa (to, rem, f);
	}
	return (to);
}

/*------------------------------------------*/
/*					    */
/*    __leda (Worker for ltoe)		    */
/*					    */
/*    Convert long to edited string	    */
/*    in the form 999,999,999		    */
/*    concantenated to string s.	    */
/*    The long is assumed positive.	    */
/*					    */
/*------------------------------------------*/

static void __leda (long num, char *s)

{
	long i;
	char t[8];

	i = num % 1000;
	num /= 1000;
	if (num)
	{
		int slen;

		__leda(num, s);
		slen = strlen (s);
		s[slen] = NUM_COMMA;		/* Add ',' in US */
		s[slen+1] = '\0';               /* Terminate string */
		__ltoa (s, i, 3);
	} /* End IF */
	else
	{
		_ltoa   (i, t, 10);
		strcat (s, t);
	} /* End IF */
} /* End __LEDA */

/*---------------------------------------------------------*/
/*							   */
/*    __ltoa (worker for ltoe)				   */
/*							   */
/*    Take size decimal digits from the right of a long,   */
/*    convert to an ascii string, padded on the left	   */
/*    with zeros as necessary to size, and concantenate    */
/*    to string s					   */
/*							   */
/*---------------------------------------------------------*/

static void __ltoa (char *s, long num, unsigned int size)

{
	char t[12];
	unsigned int i, divs;

	for (divs = 10, i = size ; i > 1 ; i--)
		divs *= 10;
	num = num % divs;
	t[0] = '\0';
	_ltoa (num, t, 10);
	i = strlen (t);
	for ( ; size > i ; size--)
		strcat (s, "0");
	strcat (s, t);
} /* End __LTOA */

#ifdef CHK_MALLOC
#pragma optimize("leg",off)
char *last_strmem = NULL;
WORD	gm_call_ip = 0, gm_call_cs = 0,
	sm_call_ip = 0, sm_call_cs = 0;
#endif
/***************************** GET_MEM **********************************/

void *get_mem(WORD size)
{
	void *ptr;

#ifdef CHK_MALLOC
 _asm {
	mov	ax,[bp+2];	// Get IP
	mov	gm_call_ip,ax;	// Save it
	mov	ax,[bp+4];	// Get CS
	mov	gm_call_cs,ax;	// Save it
 }
#endif
	ptr = my_malloc(size);
#ifdef CHK_MALLOC
	gm_call_ip = gm_call_cs = 0;
#endif
	if (!ptr) memory_panic("get_mem",size);
	memset(ptr,0,size);
	return ptr;
}

/***************************** STR_MEM **********************************/
void *str_mem(char *str)
{
	WORD size;
	char *ptr;

	size = strlen(str) + 1;
#ifdef CHK_MALLOC
	last_strmem = str;
 _asm {
	mov	ax,[bp+2];	// Get IP
	mov	sm_call_ip,ax;	// Save it
	mov	ax,[bp+4];	// Get CS
	mov	sm_call_cs,ax;	// Save it
 }
#endif
	ptr = my_malloc(size);
#ifdef CHK_MALLOC
	gm_call_ip = gm_call_cs = 0;
	last_strmem = NULL;
#endif
	if (!ptr) memory_panic("str_mem",size);
	memcpy(ptr,str,size);
	return ptr;
}

/***************************** FREE_MEM **********************************/

void *free_mem(void *ptr)
{
	if (ptr) {
		my_free(ptr);
	}
	else {
		if (!ptr) memory_panic("free_mem",0);
	}
	return ptr;
}

/***************************** MEMORY_PANIC ********************************/
/* No memory abort */

static void memory_panic (char *name,WORD size)
{
	cstdwind();
	/* ... failure ... aborting program.	*/
	fprintf(stderr,MsgMemFail, name, size);
	maxout (4);
} /* End memory_panic */

#define	MAXPROBUFF	256
#define SECTHDRERR	(const char *)-1L

// Get a line of maximum MAXPROBUFF length + trailing NULL.  Clobber
// trailing LF, strip ] and return pointer to start of name if section header.
// Return SECTHDRERR if EOF or other error.
const char *
IsSectHdr( FILE *pfIn, char *pszBuff ) {

	char *pszNL, *pszOB, *pszCB;

	if (fgets( pszBuff, MAXPROBUFF, pfIn )) {

		// Terminate it.  Buffer size must be MAXPROBUFF + 1
		pszBuff[ MAXPROBUFF ] = '\0';

		// Clobber trailing NL
		if (pszNL = strchr( pszBuff, '\n' )) {
			*pszNL = '\0';
		} // Found a LF

		// Look for open bracket at start
		pszOB = pszBuff + strspn( pszBuff, " \t" );
		if (*pszOB == '[') {

			// Look for following close bracket
			if (pszCB = strchr( pszOB + 1, ']' )) {

				// Terminate closing bracket
				*pszCB = '\0';

				// Return pointer to start of section name
				return pszOB + 1;

			} // Found following close bracket

		} // Found open bracket

		return NULL; // Not a section header, but read OK

	} // Read a line

	return SECTHDRERR; // Read failed completely...

} // IsSectHdr()

/***************************** WriteProfileInt ****************************/
// A simple wrapper to WriteProfile.  Works just like WritePrivateProfileInt()
// Returns nonzero if successful, else 0
int
WriteProfileInt( const char *pszSection,
				 const char *pszEntry,
				 int nValue,
				 const char *pszProfile ) {

	char szBuff[ 64 ];

	sprintf( szBuff, "%d", nValue );

	return WriteProfile( pszSection, pszEntry, szBuff, pszProfile );

} // WriteProfileInt()

/***************************** GetProfileInt ******************************/
// Simple wrapper to GetProfile.  Just like GetPrivateProfileInt().
int
GetProfileInt( const char *pszSection,
			   const char *pszEntry,
			   int nDefault,
			   const char *pszProfile ) {

	char szBuff[ 64 ];

	GetProfile( pszSection, pszEntry, "0", szBuff,
					sizeof( szBuff ) - 1, pszProfile );

	return atoi( szBuff );

} // GetProfileInt()

/***************************** WriteProfile *******************************/
// Like Windows WritePrivateProfileStr(), even with the same odd arg order...
// Returns nonzero if successful, else 0
// Note that pszValue == NULL means "find the line and delete it" whereas
// pszValue[0] == '\0' means "write entry=\n to the line"
int
WriteProfile( const char *pszSection,
			  const char *pszEntry,
			  const char *pszValue,
			  const char *pszProfile ) {

	char szBuff[ MAXPROBUFF + 1 ];
	const char *pszSect;
	char *pszEq;
	FILE *pfProf, *pfOut;
	int nFoundSect = 0, nWroteData = 0;
	char szDrive[ _MAX_PATH ], szDir[ _MAX_PATH ];

	// If pszProfile is NULL, build it
	if (!pszProfile) {
		sprintf( szBuff, "%sMAXIMIZE.INI", LoadString );
		pszProfile = szBuff;
	} // Create default

	// Get an output filename in the same directory
	_splitpath( pszProfile, szDrive, szDir, NULL, NULL );
	strcat( szDrive, szDir );
	strcat( szDrive, "%%mx_wp#.$$$" );

	// Now use szDir to store built-up profile name
	if (pszProfile == szBuff) {
		pszProfile = strcpy( szDir, szBuff );
	}

	// See if we can write to output file
	pfOut = fopen( szDrive, "w" );
	if (!pfOut) {
		return 0;
	} // Failure

	pfProf = fopen( pszProfile, "r" );
	if (pfProf) {

		while ((pszSect = IsSectHdr( pfProf, szBuff )) != SECTHDRERR) {

			if (pszSect) {

				// If we've reached the end of our section and
				// we're not deleting, create the entry now
				if (nFoundSect && !nWroteData && pszValue) {
					fprintf( pfOut, "%s=%s\n", pszEntry, pszValue );
					nWroteData = 1;
				} // Create entry

				// Restore clobbered trailing ]
				fprintf( pfOut, "%s]\n", szBuff );

				nFoundSect = !_stricmp( pszSect, pszSection );

			} // Start of new section
			else if (nFoundSect) {

				// Get entry name
				pszEq = strchr( szBuff, '=' );
				if (pszEq) {

					*pszEq++ = '\0'; // Clobber separator

					// Check for the one we're replacing
					if (!_stricmp( szBuff, pszEntry )) {

						// If already written, delete
						if (!nWroteData && pszValue) {
							fprintf( pfOut, "%s=%s\n", pszEntry, pszValue );
						} // Didn't already write it

						nWroteData = 1;

					} // Replace or delete this one
					else {
						fprintf( pfOut, "%s=%s\n", szBuff, pszEq );
					} // Dump this one

				} // Found separator
				else {
					fprintf( pfOut, "%s\n", szBuff );
				} // Write raw line

			} // Found our section
			else {
				fprintf( pfOut, "%s\n", szBuff );
			} // Other sections - copy to output

		} // Not EOF or error

		fclose( pfProf );

	} // Opened profile OK

	// If we're deleting, it doesn't matter what we did.  Success
	// can't really count unless we found and deleted the line.
	// If we didn't write or delete data, and we're writing (not deleting),
	// do it now.
	if (!nWroteData && pszValue) {

		nWroteData = 1;

		// If we didn't find our section, create it
		if (!nFoundSect) {
			fprintf( pfOut, "\n[%s]\n", pszSection );
		} // Didn't find section

		fprintf( pfOut, "%s=%s\n", pszEntry, pszValue );

	} // Write data

	// Now move file into final position
	fclose( pfOut );

	if (nWroteData) {

		_unlink( pszProfile );
		rename( szDrive, pszProfile );

	} // Made changes
	else {

		_unlink( szDrive );

	} // Delete temp file

	return nWroteData; // Success = 1, failure = 0

} // WriteProfile()

/***************************** GetProfile ********************************/
// Like Windows GetPrivateProfileStr(), same args...  Returns bytes copied
// to buffer (not including trailing NULL).  This includes the default
// argument (if one was specified).
int
GetProfile( const char *pszSection,
			const char *pszEntry,
			const char *pszDefault,
			char *pszBuff, int nBufflen,
			const char *pszProfile ) {

	char szBuff[ MAXPROBUFF + 1 ];
	const char *pszSect;
	char *pszEq;
	FILE *pfProf;
	int nFoundSect = 0;

	// If pszProfile is NULL, build it
	if (!pszProfile) {
		sprintf( szBuff, "%sMAXIMIZE.INI", LoadString );
		pszProfile = szBuff;
	} // Create default

	pfProf = fopen( pszProfile, "r" );

	if (pfProf) {

		// Get line, strip LF, return pointer if a section header (and strip [])
		while ((pszSect = IsSectHdr( pfProf, szBuff )) != SECTHDRERR) {

			if (pszSect) {

				if (nFoundSect) {
					break;
				} // End of target section

				nFoundSect = !_stricmp( pszSection, pszSect );

			} // Got a new section header
			else if (nFoundSect) {

				// Ignore comment lines, empty lines, or space
				if (!isalnum( szBuff[ 0 ] )) {
					continue;
				} // Ignore it

				pszEq = strchr( szBuff, '=' );
				if (!pszEq) {
					continue;
				} // No = found

				*pszEq++ = '\0'; // Clobber it and address value

				if (_stricmp( pszEntry, szBuff )) {
					continue;
				} // Not our entry

				// Now we have it
				fclose( pfProf );

				strncpy( pszBuff, pszEq, nBufflen );
				if (strlen( pszEq ) >= nBufflen) {
					pszBuff[ nBufflen - 1 ] = '\0';
				} // Truncation needed, terminate it

				return strlen( pszBuff );

			} // In the section we're interested in

		} // Not EOF, no error

		fclose( pfProf );

		// Since we (obviously) didn't find what we were
		// looking for, we must return the default now.
		*pszBuff = '\0';
		if (!pszDefault || !*pszDefault) {
			return 0;
		} // No default

		strncpy( pszBuff, pszDefault, nBufflen );
		pszBuff[ nBufflen - 1 ] = '\0';

		return strlen( pszBuff );

	} // Opened profile

	return 0; // Got nothing

} // GetProfile()


#ifdef CHK_MALLOC
#ifndef PROTO
void chk_free (void *ptr)
// Check to see if ptr is in heap before freeing it
{
    struct _heapinfo hi;
    int heapstatus;

#undef free
    hi._pentry = NULL;
    while( (heapstatus = _heapwalk( &hi )) == _HEAPOK ) {
	if (hi._pentry == ptr)
	 if (hi._useflag != _USEDENTRY)
		memory_panic ("Attempt to free unused entry", 0);
	 else {
		// Found a match
		free (ptr);
		return;
	 }
    }
 memory_panic ("Attempt to free entry not found in heap", 0);
}

#include <fcntl.h>
#include <io.h>
#include <sys/types.h>
#include <sys/stat.h>

char *heapstat (int s)
{
 static char buff[24];

 switch (s) {
  case _HEAPOK:
	return ("OK");
  case _HEAPEND:
	return ("End of heap");
  case _HEAPEMPTY:
	return ( "OK - empty heap" );
  case _HEAPBADPTR:
	return ( "ERROR - bad pointer to heap" );
  case _HEAPBADBEGIN:
	return ( "ERROR - bad start of heap" );
  case _HEAPBADNODE:
	return ( "ERROR - bad node in heap" );
  default:
	sprintf (buff, "Unknown (%d)", s);
	return (buff);
  }
}

void *chk_malloc (size_t s)
{
 void *p;
 int hstat;
 static int mallocdmp = 0;
 WORD call_cs,call_ip;
 char buff[100];
#undef malloc

 // Open dump file
 if (!mallocdmp) {
	mallocdmp = _open ("\\malloc.dmp", O_RDWR|O_TRUNC);
	if (mallocdmp == -1)
	 memory_panic ("Bogus! Can't _open \\malloc.dmp", s);
 }

 // Get heap status
 hstat = _heapchk ();

 _asm {
	mov	ax,[bp+2];	// Get IP
	mov	call_ip,ax;	// Save it
	mov	ax,[bp+4];	// Get CS
	mov	call_cs,ax;	// Save it
 }
 sprintf (buff, "malloc() called from %04x:%04x for %d bytes; heapchk=%s\n",
		call_cs,call_ip, s, heapstat(hstat));
 _write (mallocdmp, buff, strlen (buff));
 if (gm_call_cs || sm_call_cs) {
	sprintf (buff, " called from %s, called by %04x:%04x\n",
	 gm_call_cs ? "get_mem()" : "str_mem()",
	 gm_call_cs ? gm_call_cs : sm_call_cs,
	 gm_call_cs ? gm_call_ip : sm_call_ip);
	_write (mallocdmp, buff, strlen (buff));
 }
 if (last_strmem) {
	sprintf (buff, " str_mem:");
	strncat (buff, last_strmem, 80);
	buff[89] = '\0';
	strcat (buff, "\n");
	_write (mallocdmp, buff, strlen (buff));

}

 // Weed out disaster conditions
 switch (hstat) {
  case _HEAPBADPTR:
  case _HEAPBADBEGIN:
  case _HEAPBADNODE:
   memory_panic (heapstat (hstat), s);
 }

 p = (malloc (s));
 if (!p)
  memory_panic ("Unguarded malloc", s);

 return (p);

}
#pragma optimize("",on)
#endif		// PROTO undefined
#endif		// CHK_MALLOC defined


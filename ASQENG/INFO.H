/*' $Header:   P:/PVCS/MAX/ASQENG/INFO.H_V   1.1   01 Feb 1996 10:32:32   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * INFO.H								      *
 *									      *
 * Declarations for info functions					      *
 *									      *
 ******************************************************************************/

#ifndef INFO_INCLUDED
#define INFO_INCLUDED

/* Important!  These are defined BOTH here and in engine.h.  The definitions
 * must match. */
#ifdef TEXTWRAP
#define MAX_WIDTH 72		/* Maximum width for wrap & center */
#endif

#ifndef CODE_BASE
#define CODE_BASE     ' '       /* Encoding offset */
#endif

#ifndef IEXTRA
#define IEXTRA 2		/* How many extra bytes at front of line */
#endif

#ifndef CENTER_LINE
#define CENTER_LINE 126-CODE_BASE /* Format code to center line */
#endif

#include <commdef.h>            /* Common definitions */

void info_setbuf(		/* Set info scratch buffer (Optional) */
	LPVOID bigbuf,		/* Pointer to a big buffer if not NULL */
	WORD nbigbuf);		/* How many bytes in buffer if not 0 */
/* Return:  handle if successful, 0 if bigbuf not NULL, or -1 if error */

HANDLE info_init(void); 	/* Set up to build information block */
/* Return:  handle if successful, 0 if error, or -1 if scratch buffer available */

HANDLE info_finish(		/* Finish building information block */
	HANDLE handle); 	/* Handle to info structure */

void info_purge(		/* Purge information block */
	HANDLE handle); 	/* Handle to info structure */

WORD info_seek( 		/* Seek to position in information block */
	HANDLE handle,		/* Handle to info structure */
	int where);		/* Where to go, 0 == first line */
/* Return:  offset for use with info_fetch(), else 0 */

WORD info_fetch(		/* Fetch first/next text line */
	HANDLE handle,		/* Handle to info structure */
	WORD current,		/* Current offset in buffer */
	LPSTR str,		/* Where to return text */
	int nstr);		/* Max chars in str */
/* Return:  Offset to next line, or 0 if no more text */

int _cdecl iprintf(		/* Print information */
	HANDLE handle,		/* Handle to info structure */
	char *format,...);	/* printf() style args */

WORD _cdecl iputs(		/* Write string */
	HANDLE handle,		/* Handle to info structure */
	char *text);		/* Text string */

int info_length(		/* Return current length of text block */
	HANDLE handle); 	/* Handle to info structure */

int info_width( 		/* Return current width of text block */
	HANDLE handle); 	/* Handle to info structure */

int info_color( 		/* Set text coloring */
	HANDLE handle,		/* Handle to info structure */
	int color);		/* Coloring code */

int info_format(		/* Set text formatting columns */
	HANDLE handle,		/* Handle to info structure */
	int format);		/* Formatting code */

int _cdecl iwraptext(		/* Print wrapped text */
	HANDLE handle,		/* Handle to info structure */
	char *format1,		/* Format for first line */
	char *format2,		/* Leader for continuation lines */
	char *string,		/* String to print */
	int width,		/* Wrap width */
	int contin);		/* Flag for continuation lines */

void _cdecl ictrtext(
	HANDLE handle,		/* Handle to info structure */
	char *string,		/* String to print */
	int width);		/* Width of line */

#endif /* INFO_INCLUDED */
/* Mon Nov 26 17:05:36 1990 alan:  rwsystxt and other bugs */

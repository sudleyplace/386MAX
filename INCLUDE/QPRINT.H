/*' $Header:   P:/PVCS/MAX/INCLUDE/QPRINT.H_V   1.1   02 Jun 1997 14:37:32   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * PRINT.H								      *
 *									      *
 * Print dialog definitions						      *
 *									      *
 ******************************************************************************/

#ifndef PRINT_INCLUDED
#define PRINT_INCLUDED

#ifdef OWNER
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL
  #define GLINIT
#else
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL extern
#endif /*  OWNER  */


#include <qwindows.h>

typedef enum {
	P_EDITOR,
	P_GLOSS,
	P_HELP,
	P_MENU,
	P_QMENU,
	P_TUTOR,
	P_BROWSER,
	P_OEDITOR,
	P_LAST
} PRINTTYPE;

GLOBAL char *PrintProgramName;		/*	What to put in doheader */

int doPrintCallback(			/*	Do all printing */
	PTEXTWIN pWin,			/*	Pointer to the current text window */
	PRINTTYPE type, 		/*	What type of window this is */
	int which,				/*	which window in a given type */
	int helpNum);			/*	What help number this is */

void doPrint(				/*	Do all printing */
	PTEXTWIN pWin,			/*	Pointer to the current text window */
	PRINTTYPE type, 		/*	What type of window this is */
	int which,				/*	which window in a given type */
	int helpNum,			/*	What help number this is */
	int fromHelp ); 		/*	Were we called from help */

void print_argsubs(		/* Argument substution for print/help text */
	char *	 dst,		/* destination */
	char *	 src);		/* source */

#endif

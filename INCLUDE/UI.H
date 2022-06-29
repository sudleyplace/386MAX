/*' $Header:   P:/PVCS/MAX/INCLUDE/UI.H_V   1.1   02 Jun 1997 14:37:34   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * UI.H 								      *
 *									      *
 * This file contains all definitions that are related to the general	      *
 * User interface.							      *
 *									      *
 ******************************************************************************/

#ifndef UI_INCLUDED
#define UI_INCLUDED

#ifndef WINSUPP_INCLUDED
#include <qwindows.h>
#endif

#ifndef LIBTEXT_INCLUDED
#include <libtext.h>
#endif

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

#ifndef MAXFILELENGTH
/*	Preprocessor definitions */
#define MAXFILELENGTH (2+63+12+1)
#endif

/*	UI character definitions - This is someplace public */
#define BACKCHAR '\xdb'
#define BOTTOMCHAR '\xdc'
#define TOPCHAR '\xdf'
#define RIGHTCHAR ' '


/*	Handy place to get the parameters for the left data window */
GLOBAL WINDESC DataWin;
/*	Handy place for the right Quick help window */
GLOBAL WINDESC QuickWin;

void beep( void );
void initializeScreenInfo( BOOL snowcontrol );
void paintBackgroundScreen( void );
BOOL pressAnyKey( long delay );
void halfShadow(
	WINDESC *win ); 	/* Window descriptor */
void shadowWindow(
	WINDESC *win ); 	/* Window descriptor */

/*	Duplicate definition can be found in fileedit.c */
int fileEdit( int help, int tutor, char *name, int browseOnly, char *xtitle );

/*	From wait.c */
void killWait( void );		/*	Take down the wait box */
void sayWait( char *text ); /*	Put up the Wait for examining message */
void sayWaitWindow(	/*	Put up a message centered in a window */
	WINDESC *win,		/*	Window to work in */
	char *text );		/*	Text to write */

void setLibColors(		/* Set colors for library code */
	BOOL mono);		/* TRUE for monochrome color scheme */

int showLogo(int doit,char *which,char **lines,char *serial,void (*callback)(void));

#endif /*  UI_INCLUDED	*/

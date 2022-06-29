/*' $Header:   P:/PVCS/MAX/ASQ/SURFACE.H_V   1.0   05 Sep 1995 15:04:52   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * SURFACE.H								      *
 *									      *
 * All ASQ function definitions 					      *
 *									      *
 ******************************************************************************/

#ifndef SURFACE_INCLUDED
#define SURFACE_INCLUDED

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

#ifndef WINSUPP_INCLUDED
#include "qwindows.h"
#endif

#ifndef BUTTON_INCLUDED
#include "button.h"
#endif

#ifndef KEYBOARD_INCLUDED
#include "keyboard.h"
#endif

#ifndef QHELP_INCLUDED
#include "qhelp.h"
#endif

#ifndef MAXFILELENGTH
/*	Preprocessor definitions */
#define MAXFILELENGTH (2+63+12+1)
#endif

typedef struct {
	int working;		/*	Show the working message */
	char *title;		/*	Title to show on screen */
} DATAINFO;

typedef DATAINFO *PDATAINFO;

/*	Global data definitions that should not be translated */
GLOBAL char GrabFile[MAXFILELENGTH]
#ifdef GLINIT
= ""
#endif
;

GLOBAL char ReadFile[MAXFILELENGTH]
#ifdef GLINIT
= ""
#endif
;

GLOBAL char WriteFile[MAXFILELENGTH]
#ifdef GLINIT
= ""
#endif
;

GLOBAL char TextFile[MAXFILELENGTH]
#ifdef GLINIT
= ""
#endif
;


/*	 Function prototypes */

BOOL adf_spec(char *spec,int nspec,BOOL err);
int askFileName(		/*	Get a file name from the user */
	char *name);		/*	Place to store the name - MAXFILELENGTH long */
void asq( void );


int prerror (int err);

void quickAsq( int infoNum );	/*	Set a menu background */

KEYCODE presentData( int infoNum, int helpNum, BOOL wide );

void quickShowData( int infoNum );

BOOL sayHello( int doit );		/*	Put up initial text */

int setupRecommend( int fullWindow );
int setupTuning( int fullWindow );

void snapClear( void ); 		/*	Clear out the current snapshot */
void snapLoad( void );			/*	Get a new snap shot from a menu pick */
void snapSave( void );			/*	Dump a snapshot to disk */

#endif	 /* SURFACE_INCLUDED */

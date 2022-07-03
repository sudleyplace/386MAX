/*' $Header:   P:/PVCS/MAX/INCLUDE/SCREEN.H_V   1.1   02 Jun 1997 14:37:32   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * SCREEN.H								      *
 *									      *
 * This file contains all definitions that are related to SCREEN information  *
 *									      *
 ******************************************************************************/

#ifndef SCREEN_INCLUDED
#define SCREEN_INCLUDED


#ifndef COMMDEF_INCLUDED
#include <commdef.h>					/*	Get standard definitions */
#endif	 /* COMMDEF_INCLUDED */

#ifndef WINSUPP_INCLUDED
#include <qwindows.h>
#endif	/* WINSUPP_INCLUDED */


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

/* ScreenSize needs to be in the initialized data area (DGROUP) */
/* so we can get to it from MASM code. (MAXSUB.ASM) */
GLOBAL POINT ScreenSize
#ifdef GLINIT
= {0, 0}
#endif
;

GLOBAL enum { SCREEN_MONO, SCREEN_COLOR } ScreenType;

GLOBAL int ScreenSet
#ifdef GLINIT
= FALSE
#endif
;

GLOBAL int AdapterType;

#endif /*  SCREEN_INCLUDED	*/

/*' $Header:   P:/PVCS/MAX/MAXIMIZE/DEBUG.H_V   1.0   05 Sep 1995 16:33:20   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * DEBUG.H								      *
 *									      *
 * Debug controls header file						      *
 *									      *
 ******************************************************************************/

#ifndef DEBUG_INCLUDED
#define DEBUG_INCLUDED

/*
 *   To enable debugging code, define DEBUG on command line
 */

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

GLOBAL BOOL MCAflag	/* Flag to debug MCA code on non-MCA machines */
#ifdef GLINIT
 = FALSE
#endif
;

GLOBAL BOOL Verbose	/* Flag for verbose (debug) output */
#ifdef GLINIT
 = FALSE
#endif
;

#endif /*DEBUG_INCLUDED*/

/*' $Header:   P:/PVCS/MAX/INCLUDE/INTHELP.H_V   1.1   09 Oct 1995 14:21:18   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * INTHELP.H								      *
 *									      *
 * This file contains all definitions that are related to internal help       *
 *									      *
 ******************************************************************************/

#ifndef INTERHELP_INCLUDED
#define INTERHELP_INCLUDED

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


#define MAXLINE 256
#define CONTEXTTRIGGER '@'
#define CONTEXTOFFSET 3

GLOBAL TEXTWIN HelpTextWin;

GLOBAL WINDESC HelpWinDesc;

GLOBAL HELPTYPE HelpWinType;

GLOBAL pb compBuffer
#ifdef GLINIT
	= NULL
#endif
;

GLOBAL pb decompBuffer
#ifdef GLINIT
	= NULL
#endif
;

GLOBAL int keepIt	   /*  Dangerous solution to not changing loadhelp */
#ifdef GLINIT
 = FALSE
#endif
;

GLOBAL unsigned compSize;
GLOBAL unsigned decompSize;

GLOBAL nc thisContext	   /*  The result of the last help show */
#ifdef GLINIT
= 0
#endif
;

GLOBAL hotspot HelpHotSpot;

GLOBAL nc prevStop	   /*  The result of the previous stop lookup */
#ifdef GLINIT
= 0
#endif
;
GLOBAL nc nextStop	   /*  The result of the next stop lookup */
#ifdef GLINIT
= 0
#endif
;

GLOBAL PB lastHelpTopic
#ifdef GLINIT
 = NULL
#endif
;

#endif

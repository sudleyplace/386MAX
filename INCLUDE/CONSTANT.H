/*' $Header:   P:/PVCS/MAX/INCLUDE/CONSTANT.H_V   1.1   30 May 1997 11:24:48   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * CONSTANT.H								      *
 *									      *
 * Window functions							      *
 *									      *
 ******************************************************************************/

#ifndef constant_INCLUDED
#define constant_INCLUDED

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

GLOBAL char BLANKSTRING[1]
#ifdef GLINIT
= " "
#endif
;

#endif /*constant_INCLUDED*/

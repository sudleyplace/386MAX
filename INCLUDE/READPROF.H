/*' $Header:   P:/PVCS/MAX/INCLUDE/READPROF.H_V   1.0   05 Sep 1995 13:30:00   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * READPROF.H								      *
 *									      *
 * Data for built-in ASQ profile					      *
 *									      *
 ******************************************************************************/

#ifndef READPROF_INCLUDED
#define READPROF_INCLUDED

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

int readProfile( int first, char *line, int nline );

#endif /*READPROF_INCLUDED*/

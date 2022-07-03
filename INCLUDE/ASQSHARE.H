/*' $Header:   P:/PVCS/MAX/INCLUDE/ASQSHARE.H_V   1.0   05 Sep 1995 13:30:06   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * ASQSHARE.H								      *
 *									      *
 * This file contains data used by both MAX shell and ASQ.		      *
 *									      *
 ******************************************************************************/

#ifndef ASQSHARE_INCLUDED

#define ASQSHARE_INCLUDED

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

GLOBAL char AutoexecName[80]
#ifdef GLINIT
= "C:\\AUTOEXEC.BAT"
#endif
;

GLOBAL char ConfigName[20]
#ifdef GLINIT
= "C:\\CONFIG.SYS"
#endif
;

GLOBAL char MAXName[80]
#ifdef GLINIT
= "C:\\386MAX\\386MAX.PRO"
#endif
;

GLOBAL char ExtraDOSName[80]
#ifdef GLINIT
= {0}
#endif
;

GLOBAL char SYSININame[80]
#ifdef GLINIT
= {0}
#endif
;

#endif /* ASQSHARE_INCLUDED ... not */


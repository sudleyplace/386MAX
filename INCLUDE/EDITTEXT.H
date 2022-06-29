/*' $Header:   P:/PVCS/MAX/INCLUDE/EDITTEXT.H_V   1.0   05 Sep 1995 13:30:10   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * EDITTEXT.H								      *
 *									      *
 * Data used only for full-blown editor used in MAX shell		      *
 *									      *
 ******************************************************************************/

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

/*					  */
/* the following is for the 386 stripper  */
/*					  */

GLOBAL int PathLength;

#define DEVICE "DEVICE"
#define DEVICELEN sizeof(DEVICE)-1
GLOBAL char device[]
#ifdef GLINIT
= DEVICE
#endif
;

#define GETSIZE " GETSIZE PROG="
GLOBAL char getsize[ sizeof( GETSIZE )]
#ifdef GLINIT
= GETSIZE
#endif
;

#define LOAD386EXE "386LOAD"
GLOBAL char load386exe[ sizeof( LOAD386EXE )]
#ifdef GLINIT
= LOAD386EXE
#endif
;

#define LOAD386SYS "386LOAD.SYS"
GLOBAL char load386sys[ sizeof( LOAD386SYS )]
#ifdef GLINIT
= LOAD386SYS
#endif
;



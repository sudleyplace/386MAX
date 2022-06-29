// $Header:   P:/PVCS/MAX/MAXSETUP/MAXTIME.H_V   1.0   01 Feb 1996 11:17:32   PETERJ  $
/****************************************************************
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.	*
 * MAXTIME.H								                    *
 * Definition of TIME structures used in setup	                *
 ****************************************************************/

#ifndef MTIME_INCLUDED
#define MTIME_INCLUDED

typedef struct		  /* date/time used by _dos_[sg]etftime () */
{
	WORD time;		  /* low order WORD: packed time */
	WORD date;		  /* high order WORD: packed date */
} DOSTIME;

typedef struct		  /* bit fields used by date/time */
{
	WORD sec2	: 5;	  // Seconds div 2 (0-29)
	WORD minutes : 6;	  // Minutes (0-59)
	WORD hours	: 5;	  // Hours (0-23)
	WORD day	: 5;	  // Day of month (1-31)
	WORD month	: 4;	  // Month (1-12)
	WORD year	: 7;	  // Year-1980 (0-119)
} DOSTIMEB;

typedef union		  /* date/time represented in three ways: */
{
	unsigned long stime;	/* date/time as returned by stat (seconds
				   * elapsed since 1/1/1970) */
	unsigned long dtime;	/* date/time for comparison, DOS style */
	DOSTIME dt;		/* packed date/time (per _dos_[sg]etftime) */
	DOSTIMEB dtb;		/* date/time bit fields */
} DIRTIME;


#endif /* MTIME_INCLUDED*/


/*' $Header:   P:/PVCS/MAX/QUILIB/DATESTR.C_V   1.0   05 Sep 1995 17:02:04   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * DATESTR.C								      *
 *									      *
 * Encode date/time values						      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <time.h>

#include "commfunc.h"
#include "libtext.h"

/* Local functions */
static void ifmt(unsigned value,char *str,int n,int base,int fill);


/* Encode date value DOS-style */
char *datestr(char *str,int mm,int dd,int yyyy)
{
	int nn;

	if (yyyy < 1000) nn = 2;
	else		 nn = 4;

	/*	    0123456789.123456789. */
	strcpy(str,NATL_DATEFMT);
#ifdef LANG_GR
	ifmt(dd,str+NATL_DATEFDPOS,2,10,' ');
	ifmt(mm,str+NATL_DATEFMPOS+(mm>9?1:0),2,10,' ');
	sprintf(str+NATL_DATEFMPOS+(mm>9?3:2),"%c xxxx",str[2]);
	ifmt(yyyy,str+strlen(str)-4,nn,10,' ');
	str[strlen(str)-4+nn] = '\0';
#else
	ifmt(mm,str+NATL_DATEFMPOS,2,10,' ');
	ifmt(dd,str+NATL_DATEFDPOS,2,10,'0');
	ifmt(yyyy,str+NATL_DATEFYPOS,nn,10,' ');
	if (nn == 4) str[10] = '\0';
#endif
	return str;
}

/* Encode time value DOS-style */
char *timestr(char *str,int hh,int mm,int ss)
{
	char ampm;

	if (ss);

#ifdef TIME_FMT24
	ampm = ' ';
#else
	if (hh > 11) {
		hh -= 12;
		ampm = 'p';
	}
	else ampm = 'a';
	if (hh < 1) hh += 12;
#endif

	/*	    0123456789.123456789. */
	strcpy(str,"  :   ");

	ifmt(hh,str,2,10,' ');
	ifmt(mm,str+3,2,10,'0');
	str[5] = ampm;
	return str;
}

#pragma optimize ("l",off)      /* Possible compiler bug */
static void ifmt(unsigned value,char *str,int n,int base,int fill)
{
	unsigned i;
	int k;

	for (k = n-1; k >= 0; k--) {
		i = value % base;
		if (i > 9) {
			str[k] = (char) (i + 'A' - 10);
		}
		else	str[k] = (char) (i + '0');
		value /= base;
		if (!value) {
			k--;
			while (k >= 0) {
				str[k--] = (char) fill;
			}
			break;
		}
	}
}
#pragma optimize ("",on)

/***
 * Encode date and time format as text
 *
 * timedatefmt (time_t *thetime, char *output, datefmt, timefmt);
 *
 * datefmt is 0 for none
 *	      1 for dow month day, yyyy
 *	      2 for dow mon day, yyyy
 * timefmt is 0 for none
 *	      1 for hh:mm [am|pm]
***/

void timedatefmt (time_t *thetime, char *output, int datefmt, int timefmt)
{
 struct tm *timetmp;

 timetmp = localtime (thetime);
 if (datefmt) {
#ifdef LANG_GR
		sprintf (output, "%-3s %d. %s %04d",
			Daysofwk[timetmp->tm_wday],
			timetmp->tm_mday,
			Monthsofyr[timetmp->tm_mon],
			1900+timetmp->tm_year);
#else
	if (datefmt == 1 || !NATL_MONTH_ABBR) {
		sprintf (output, "%-3s %s %d, %04d",
			Daysofwk[timetmp->tm_wday],
			Monthsofyr[timetmp->tm_mon],
			timetmp->tm_mday,
			1900+timetmp->tm_year);
	}
	else {
		sprintf (output, "%-3s %s", Daysofwk[timetmp->tm_wday],
						Monthsofyr[timetmp->tm_mon]);
		sprintf (output+4+NATL_MONTH_ABBR, " %d, %04d",
			timetmp->tm_mday,
			1900+timetmp->tm_year);
	} /* full/partial month name */
#endif
 }
 else
	*output = '\0';

 if (timefmt) {
	if (*output)	strcat (output, "  ");
#ifdef TIME_FMT24
	sprintf (output+strlen(output)-1, "%02d:%02d",
		timetmp->tm_hour, timetmp->tm_min);
#else
	sprintf (output+strlen(output)-1, "%02d:%02d%s",
		timetmp->tm_hour % 12, timetmp->tm_min,
		AmPm[timetmp->tm_hour > 12]);
#endif
 }

} /* timedatefmt () */


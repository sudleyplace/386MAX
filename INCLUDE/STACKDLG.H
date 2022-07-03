/*' $Header:   P:/PVCS/MAX/INCLUDE/STACKDLG.H_V   1.0   05 Sep 1995 13:30:06   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1992 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * STACKDLG.H								      *
 *									      *
 * Definitions for Stacker dialog and support for manual drive compression    *
 *									      *
 ******************************************************************************/

/* Processes args immediately following /K */
void get_stackopts (char **optp);

/* Returns a pointer to a static string built of /Kabcde or \0- guaranteed */
/* to be printable. */
char *make_stackopts (void);

void get_swapparms (	char bootdrive, /* Apparent boot drive */
			char maxdrive,	/* Drive of main MAX directory */
			char *destdir,	/* 386MAX directory */
			char *dlg,	/* Dialog context name to display */
			int hlp);	/* Help index */

#ifdef OWNER
static char *SwapTypes[] = {
#ifdef LANG_GR
 "keine",
#else
 "None",
#endif
 "Stacker", "SuperStor"
};

static char *SameAsMAX =
#ifdef LANG_GR
 " (gleich)";
#else
 " (same)";
#endif

static char *DriveCMsg =
#ifdef LANG_GR
 "Laufwerk x";
#else
 "drive x";
#endif
#define DRIVECMSG (strlen(DriveCMsg)-1)

	DIALOGEDIT SwapEdit[] = { /* Fields to edit drive swapping parameters */
#ifdef LANG_GR
	{ { -13, 27, 1, 1 },	NULL /*ActualBootStr*/, 1 },
	{ { -12, 40, 1, 1 },	NULL /*CopyBootStr*/,	1 },
	{ {  -8, 39, 1, 1 },	NULL /*MaxConfigStr*/,	1 },
	{ {  -7, 44, 1, 1 },	NULL /*CopyMax1Str*/,	1 },
	{ {  -5, 11, 1, 1 },	NULL /*CopyMax2Str*/,	1 }
#else
	{ { -12, 21, 1, 1 },	NULL /*ActualBootStr*/, 1 },
	{ { -11, 44, 1, 1 },	NULL /*CopyBootStr*/,	1 },
	{ {  -7, 41, 1, 1 },	NULL /*MaxConfigStr*/,	1 },
	{ {  -6, 43, 1, 1 },	NULL /*CopyMax1Str*/,	1 },
	{ {  -5, 47, 1, 1 },	NULL /*CopyMax2Str*/,	1 }
#endif
	};

/* Positions for normal /K dialog questions 1, 2, and 3 */
/* These values are substituted in SwapEdit[0-2] */
/* Count column 0 of the help text as 2 */
#ifdef LANG_GR

#define Q1YPOS	-14
#define Q1XPOS	30
#define Q2YPOS	-8
#define Q2XPOS	34
#define Q3YPOS	-5
#define Q3XPOS	40

#else

#define Q1YPOS	-13
#define Q1XPOS	25
#define Q2YPOS	-8
#define Q2XPOS	16
#define Q3YPOS	-5
#define Q3XPOS	31

#endif

#endif


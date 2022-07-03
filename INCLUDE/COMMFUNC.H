/*' $Header:   P:/PVCS/MAX/INCLUDE/COMMFUNC.H_V   1.2   02 Jun 1997 14:37:28   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * COMMFUNC.H								      *
 *									      *
 * Common utility functions						      *
 *									      *
 ******************************************************************************/


#ifdef __cplusplus
extern "C" {
#endif

#ifndef COMMFUNC_INCLUDED
#define COMMFUNC_INCLUDED

#ifndef COMMDEF_INCLUDED
#include <commdef.h>
#endif

#ifndef _TIME_T_DEFINED
#include <time.h>
#endif

/* Define different response keys (vary according to language) */
#ifdef LANG_GR
#define RESP_YES	'J'     /* Ja   */
#define RESP_NO 	'N'     /* Nein */
#define RESP_MORE	'M'     /* Mehr */
#define RESP_CANCEL	'A'     /* Abbruch */
#define RESP_ABORT	'A'     /* Abbruch */
#define RESP_RETRY	'W'     /* Wiederholen */
#define RESP_FAIL	'F'     /* Fehler */
#define RESP_REBOOT	'R'     /* Reboot */
#define RESP_OK 	'F'     /* Fertig */
#define RESP_ALL	'A'     /* All = Alle */
#define RESP_THIS	'D'     /* This = Diese */
#define RESP_ONE	'E'     /* One = Ein(?) */
#else
#define RESP_YES	'Y'     /* Yes */
#define RESP_NO 	'N'     /* No */
#define RESP_MORE	'M'     /* More */
#define RESP_CANCEL	'C'     /* Cancel */
#define RESP_ABORT	'A'     /* Abort */
#define RESP_RETRY	'R'     /* Retry */
#define RESP_FAIL	'F'     /* Fail */
#define RESP_REBOOT	'R'     /* Reboot */
#define RESP_OK 	'O'     /* OK */
#define RESP_ALL	'A'     /* All */
#define RESP_THIS	'T'     /* This */
#define RESP_ONE	'O'     /* One */
#endif

/* Sleep the process for a fixed number of milliseconds */
void sleep(long msecs);

/* Handle print errors */
int prerror (int err);

/* Set / copy WORDs */
void wordset(LPWORD dst,WORD val,WORD nset);
void wordcpy(LPWORD dst, LPWORD src, WORD ncpy);
void wordrcpy(LPWORD dst, LPWORD src, WORD ncpy);

/* Decode a BCD integer */
unsigned short bcd_num(unsigned short num);

int pos_test(			/* Test a POS value */
	WORD posval,		/* Value to test */
	char *posstr);		/* POS switch string to compare with */

/* Remove leading and trailing white space */
int trim(char *s);
int ntrim(char *s,int n);

/* Remove trailing white space */
int trnbln (char *string);

/* Remove dirty characters from string */
void launder_string(char *name);

/* Save .EXE file name for later */
char *set_exename(char *name,char *defname);

/* Return saved .EXE file name */
char *get_exename(void);

/* Return path stem of program file name */
void get_exepath(char *path,int npath);

/* Encode date value DOS-style */
char *datestr(char *str,int mm,int dd,int yyyy);

/* Encode time value DOS-style */
char *timestr(char *str,int hh,int mm,int ss);

/* Format date/time as text */
void timedatefmt(time_t *thetime,char *output,int datefmt,int timefmt);

BOOL qmaxpres(	/* Check if 386max present */
	WORD *hmac,	/* First MAC of high DOS returned */
	WORD *lseg);	/* Start of LOADSEG chain returned */

BOOL qmovpres(	/* Check if MOVE'EM present */
	WORD *hmac,	/* First MAC of high DOS returned */
	WORD *lseg);	/* Start of LOADSEG chain returned */

int keyboard_id(void);	/* Test for ext bios + enh keyboard */
/* Return:  bit 0 == 1 for ext kb bios, bit 1 == 1 for enh keyboard */

char get_bootdrive(void);

void _cdecl inst2324(void);	/* Install INT 23 and INT 24 handlers. */
void _cdecl done2324(void);	/* Install INT 23 and INT 24 handlers. */
void _cdecl enable23(void);	/* Enables INT 23 processing. */
void _cdecl disable23(void);	/* Disables INT 23 processing. */
void _cdecl enable29(void);	/* Enables INT 29 processing. */
void _cdecl disable29(void);	/* Disables INT 29 processing. */
void _cdecl set24_resp(int resp); /* Set default response to critical error */
				/* or 0 to ask the user */

int _cdecl chkabort(void);	/* Confirm abort request */

int _cdecl display_criterr (	/* Display critical error window */
	int flag,		/* 0 = device error, 1 = disk error */
	char *aritxt);		/* Error message to display */

void _cdecl abortprep(		/* Prepare to exit program */
	int flag);		/* 0 if called thru ctrl-break */
				/* 1 if called thru critical error */

int insert_help(char *name, char **newlines, int nlines, int savechanges);

void arg_concat(	/* Concatenate args into single string */
	char *argstr,	/* Where to build arg string */
	int argc,	/* Arg count */
	char **argv);	/* Arg vector */

char *arg_token(	/* Pick off next token in arg list */
	char *argstr,	/* Pointer to current position in arg string */
	int *ntok);	/* Number of chars in token returned here */
/* Return:  Pointer to token, else NULL */

char *arg_argument(void); /* Return pointer to argument from last option */

int arg_getopt( 	/* Get next option or token */
	int argc,	/* C arg count */
	char **argv,	/* arg list */
	char *optlist); /* option/argument list or NULL to get next token */

BOOL decrypt_serialno ( /* Decrypt the serial number string */
	char *str,	/* String returned here */
	int len );	/* Max length of string */
/* Return:  TRUE of ok, FALSE if bogus */

WORD win_version(void); /* Return windows version if up */

BOOL copy(char *src, char *dst);	/* Copy a file */
BOOL orcopy(char *src, char *dst, WORD flags); /* Copy a file & combine flags */

/****************************************************************
 *  This function must be provided by the application.	It is NOT
 *  present in the libraries.  Once called, the program should
 *  issue a message and abort.
 ****************************************************************
 */

void nomem_bailout(	/* Abort due to severe lack of memory */
	int codenum);	/* Location-specific code number */

/* Functions in truename.c (for canonical pathname processing) */
char *truename_fn (			/* Convert src_path to canonical form */
	char far *dst_path,		/* in dst_path; return dst_path if */
	char far *src_path);		/* successful, otherwise NULL */
void truename (char *path);		/* Convert path to canonical form */
int truename_cmp (char *path1,		/* Convert copies of path1 and path2 */
	char *path2);			/* to canonical form & return stricmp */
void truedir (char *dir);		/* Convert '\' terminated dir name */

#endif /*COMMFUNC_INCLUDED*/

#ifdef __cplusplus
}
#endif


/***
 *' $Header:   P:/PVCS/MAX/SNAPSHOT/SNAPSHOT.C_V   1.0   05 Sep 1995 17:13:06   HENRY  $
 ***/

/**
 *	snapshot.c - Stub to execute ASQ with /P option
 *
 *ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
 *³ TRANSFERRED TO GERMAN 8-Mar-1992	      ³
 *³ see remarks on other files		      ³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <io.h>
#include <process.h>

#define ASQNAME "ASQ.EXE"

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

/* Messages used herein (grouped together for easier localization) */
#ifdef LANG_GR
#define MSG_EXECERR	"SNAPSHOT: %s nicht gefunden\n"
#else
#define MSG_EXECERR	"SNAPSHOT: %s not found\n"
#endif


char *arglist[] = {
	ASQNAME,"/P","/S",NULL,NULL,
	NULL,NULL,NULL,NULL,NULL,
	NULL,NULL,NULL,NULL,NULL
};

int main(int argc,char *argv[])
{
	int i, j, k;
	char	c;
	char	temp[256];
	char	fullpath[_MAX_PATH],
		drive[_MAX_DRIVE],
		dir[_MAX_DIR],
		fname[_MAX_FNAME],
		ext[_MAX_EXT];

	_splitpath (argv[0], drive, dir, fname, ext);
	_makepath (fullpath, drive, dir, "ASQ", ".EXE");

	for (i=1; i<sizeof(arglist)/sizeof(arglist[0]) && i < argc; i++) {

	  if (strpbrk (argv[i], " \t\"")) {
		temp[0] = '"';
		for (j=0, k=1; (c = argv[i][j]); j++) {
		  if (c == '"') temp[k++] = '\\';
		  temp[k++] = c;
		} /* For all characters in argument string */
		temp[k++] = '"';
		temp[k] = '\0';
		arglist[i+2] = strdup (temp);
	  } /* Embedded spaces; use quotes */
	  else	arglist[i+2] = argv[i];
	  /* printf ("Argv[%d]=%s\n", i, arglist[i+2]); */
	}

	/* This should not return */
	if (execv (fullpath,arglist) == -1) {
		fprintf (stderr, MSG_EXECERR, fullpath);
	}

	return (-1);

}


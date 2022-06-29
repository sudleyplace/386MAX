/*' $Header:   P:/PVCS/MAX/QUILIB/ARGSTR.C_V   1.1   13 Oct 1995 12:12:18   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * ARGSTR.C								      *
 *									      *
 * Command-line argument functions					      *
 *									      *
 ******************************************************************************/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "commfunc.h"

int optind = 1; 	/* Next argv[] to get */
FILE *optfile = NULL;	/* If !NULL, options are being _read from @file */
char optfbuff[256];	/* Line buffer for option @file */
char *optfbptr; 	/* Pointer into optfbuff */
char *lastopt = NULL;	/* Last option/argument returned */
char *ungetptr = NULL;	/* Pointer to token if arg_ungettoken () called */
char *arg_argptr;	/* Value returned by arg_argument () */

void arg_concat(	/* Concatenate args into single string */
	char *argstr,	/* Where to build arg string */
	int argc,	/* Arg count */
	char **argv)	/* Arg vector */
{
	*argstr = '\0';
	for (argc--, argv++; argc > 0 ; argc--, argv++ ) {
		char *p;

		for (p = *argv; *p; p++) {
			if (isspace(*p)) break;
		}
		if (*p) strcat(argstr,"\"");
		strcat(argstr,*argv);
		if (*p) strcat(argstr,"\"");
		if (argc > 1) strcat(argstr," ");
	}
}

char *arg_token(	/* Pick off next token in arg list */
	char *argstr,	/* Pointer to current position in arg string */
	int *ntok)	/* Number of chars in token returned here */
/* Return:  Pointer to token, else NULL */
{
	char *pp;

	/* Skip leading white space */
	while (isspace(*argstr)) argstr++;

	/* Drop anchor */
	pp = argstr;

	if (*pp == '"') {
		/* Special case for quoted string */
		argstr++;
		while (*argstr) {
			if (*argstr == '"') break;
			argstr++;
		}
		argstr++;
	}
	else {
		/* Scan for next white space or '/' or end of string */
		while (*argstr) {
			if (isspace(*argstr) || *argstr == '/') break;
			argstr++;
		}
	}
	if (ntok) *ntok = argstr-pp;
	if (argstr != pp) return pp;
	return NULL;
}

/******************** ARG_GETTOKEN () ******************************/
/* Get next token from logical command line.  All token gets are buffered;
 * if the caller decides not to accept the token, call should be
 * immediately followed by arg_ungettoken ().
 * A pointer to an internal static data area is returned.  Successive
 * calls will overwrite the previous value.
 * Both double and single quotes are processed.
 * NULL is returned when no more tokens are available.
 * Note that (quoted) tokens may not extend across physical lines
 * when using @files.
***/
char *arg_gettoken (int argc, char **argv)
{
 static char arg_return[256];
 char *quotechar, *matchquote, *temp, *temp2;

 if (optfile) { 	/* Reading options from @file */

  while (optfbptr && *optfbptr && strchr (" \t\n\r", *optfbptr))
	optfbptr++;	/* Skip whitespace */

  if (optfbptr == NULL || *optfbptr == '\0') { /* Read next line into buffer */

	temp2 = optfbuff;

	while (temp = fgets (optfbuff, sizeof (optfbuff)-1, optfile)) {
	 optfbptr = optfbuff; /* Reset line buffer pointer */
	 while (temp2 = strchr (" \t\n\r", *optfbptr))
		optfbptr++;
	 if (temp2 == NULL)
		break;
	}; /* not end of file */

	if (temp == NULL && temp2) { /* End of file and nothing in buffer */
	 fclose (optfile);
	 optfile = NULL; /* signal that file is closed */
	 return (arg_gettoken (argc, argv));
	}

  } /* needed to fill line buffer */

  /* optfbptr ==> next token */
  while (strchr (" \t\n\r", *optfbptr))
	optfbptr++;	/* Skip whitespace */

  lastopt = optfbptr;

  if (quotechar = strchr ("'\"", *lastopt)) {

	lastopt++;	/* Skip quote */

	if (temp = strchr (lastopt, *quotechar)) { /* Found its mate */
	 *temp = '\0';  /* Obliterate trailing quote */
	 optfbptr = temp + 1;
	} /* Found matching quote */

  }  /* Quoted token */

  else {

   while (!strchr (" \t\n\r", *optfbptr))
	optfbptr++;	/* Skip non-whitespace */
   *optfbptr++ = '\0';  /* Terminate *lastopt */

  }  /* Unquoted token */

 } /* Getting tokens from file */

 else if (ungetptr) {	/* Return token which was rejected */

  lastopt = ungetptr;	/* Address rejected token */
  ungetptr = NULL;	/* Clear unget pointer */

 } /* Recycling tokens */

 else if (optind < argc) { /* Text remains on command line */

  if (quotechar = strchr ("'\"", argv[optind][0])) {

	/* Matching quote may be in the same token */
	if (matchquote = strchr (temp = (argv[optind]) + 1, *quotechar)) {
	 *matchquote = '\0';    /* Truncate and ignore remainder */
	 lastopt = strcpy (arg_return, argv[optind++]);
	} /* "Token" */

	else	/* Keep grabbing till we hit the end or get a matching quote */
	 for (lastopt = strcpy (arg_return, temp), optind++;
		optind < argc; optind++) {
	  if (!temp)
		strcat (arg_return, " ");

	  if (temp = strchr (argv[optind], *quotechar)) {
		*temp = '\0';
		strcat (arg_return, argv[optind]);
		break;
	  } /* Found closing quote */

	  strcat (arg_return, argv[optind]);

	 } /* end for () */

  } /* end quote processing */

  else if (argv[optind][0] == '@') {
	strcpy (optfbuff, argv[optind++] + 1);
	optfile = fopen (optfbuff, "r");
	optfbptr = NULL;	/* Clear pointer to line buffer */
	return (arg_gettoken (argc, argv));
  } /* _open command file */

  else	/* Simple unquoted command line token */
	lastopt = strcpy (arg_return, argv[optind++]);

 } /* Text remains on command line */

 else lastopt = NULL;	/* Clear pointer used for unget */

 return (lastopt);

} /* arg_gettoken () */

/******************** ARG_UNGETTOKEN () ****************************/
/* Make last token returned by arg_gettoken () available for next
 * call to arg_gettoken ().  Only one level of unget is allowed.
***/
void arg_ungettoken (void)
{
  ungetptr = lastopt;	/* Clear if lastopt is NULL, otherwise set it */
}

/************************ ARG_ARGUMENT () ******************************/
/* Return arg_argptr as set by arg_getopt if last option returned had
 * a required argument.  To get regular tokens, use arg_gettoken ().
***/
char *arg_argument (void)
{
 return (arg_argptr);
}

/************************ ARG_GETOPT () ********************************/
/***
 * Get next option (converted to uppercase).  If argument is required,
 * set up ensuing call to arg_argument().  If required argument is
 * missing, or option is invalid, set high bit (0x8000) in return
 * value.  If end of list, return EOF.
 * If there is more on the logical command line but the next token is
 * not a command switch, return 0.
 * Parsing of options/arguments automatically handles expressions like
 * @filename, where filename contains more options and/or arguments
 * delimited by whitespace and/or newlines.  Nested @files are not
 * supported.
***/
int arg_getopt (int argc, char **argv, char *valopts)
{

 char *optemp, *temp;
 int retval;
 char valopts_cpy[256];

 arg_argptr = NULL;	/* Reset arg_argument () return value */

 /* Get a copy of valopts we can play with */
 strncpy (valopts_cpy, valopts, sizeof (valopts_cpy) - 1);
 valopts_cpy [sizeof (valopts_cpy) - 1] = '\0';
 _strupr (valopts_cpy);	/* Option list is "S[:][S[:]]..." */

 if (optemp = arg_gettoken (argc, argv)) {

  if (strchr ("-/", *optemp)) { /* it's a switch */

	/* Check to ensure it's a valid option and for required argument */
	if (temp = strchr (valopts_cpy, toupper (optemp[1]))) {
	 retval = *temp;

	 if (temp[1] == ':') {  /* argument required */

		if (optemp[2]) {			/* Argument is part */
		 arg_argptr = optemp + 2;		/* of current token */
		}	/* Argument follows switch */

		else {					/* Get next token */

		 optemp = arg_gettoken (argc, argv);	/* peek ahead */

		 if (!optemp || strchr ("-/", *optemp)) {
		  arg_ungettoken ();			/* toss it back */
		  retval |= 0x8000;		/* req'd argument missing */
		 } /* Required argument missing or next token is a switch */

		 else
		  arg_argptr = optemp;		/* set arg_argument () return */

		}				/* End argument in next token */

	 }					/* Argument required */

	 else if (optemp[2])			/* Tokens are huddled together */
		ungetptr = optemp + 2;		/* Fake an arg_ungetptr () */

	} /* Next switch is in same token */

	else {			/* Invalid switch */
	 retval = *temp | 0x8000;
	} /* Invalid switch */

	return (retval);

  } /* Token is a switch */

  else {			/* not a switch - toss it back */
	arg_ungettoken ();
	return (0);
  } /* Not a switch */

 } /* A token exists */

 else				/* Nothing else left */
	return (EOF);

} /* arg_getopt () */


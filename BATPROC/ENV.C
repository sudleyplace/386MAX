// ENV.C - Environment routines (including aliases) for BATPROC
//   (c) 1990 Rex C. Conn   All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <dos.h>
#include <fcntl.h>
#include <io.h>
#include <setjmp.h>
#include <share.h>
#include <string.h>

#include "batproc.h"

extern jmp_buf env;

unsigned char *environment;	// pointer to environment (paragraph aligned)
unsigned char *alias_list;	// pointer to alias list (paragraph aligned)


// search paths for file -- return pathname if found, NULL otherwise
char *pascal searchpaths(char *filename)
{
	extern char input_file[];
	extern int flag_4dos;

	static char fname[84];		// expanded filename
	register char *envptr = NULL, *extptr, *eptr;
	int i;

	strcpy(fname,filename);

	// no path searches if path already specified!
	if (path_part(fname) == NULL)
		envptr = envget(PATH_VAR,0);
	if (envptr == NULL)
		envptr = NULLSTR;

	// check for existing extension
	extptr = ext_part(filename);

	// search the PATH for the file
	for ( ; ; ) {

		// if no extension, try an executable one (COM, EXE, BTM, & BAT)
		if (extptr == NULL) {
			extptr = fname + strlen(fname);

			for (i = 0; (executables[i] != NULL); i++) {

				char tname1[15], tname2[15];
				char *extoff1, *extoff2;

				strcpy(extptr,executables[i]);

				// If the call is to a batch file with the
				// same basename as the input file but the
				// input file has an extension other than
				// .BAT, convert to the input file...

				strcpy (tname1, fname_part (input_file));
				strcpy (tname2, fname_part (fname));

				extoff1 = strchr (tname1, '.');
				extoff2 = strchr (tname2, '.');

				if (extoff1 && extoff2 &&
						stricmp (extoff2, ".bat")) {

				*extoff1 = '\0';
				*extoff2 = '\0';

				if (!stricmp (tname1, tname2)) {
					 strcpy(fname,input_file);
					 return fname;
				}

				} // Got a file extension

				// look for the file
				if (is_file(fname))
					return fname;
			}

#ifdef COMPAT_4DOS
			if (flag_4dos) {
				// check for user defined executable extensions
				for (eptr = environment; *eptr; eptr = next_env(eptr)) {
					if (*eptr == '.') {
						// add extension & look for filename
						sscanf(eptr,"%4[^=]",extptr);
						if (is_file(fname))
							return fname;
					}
				}
			}
#endif
			extptr = NULL;

		} else if (is_file(fname))
			return fname;

		// get next PATH argument, skipping ' ', '\t', ';', ','
		while (isdelim(*envptr))
			envptr++;

		// check for end of path
		if (*envptr == '\0')
			return NULL;

		// save next search path
		sscanf(envptr,"%68[^; \t=,]",fname);
		envptr += strlen(fname);
		mkdirname(fname,filename);
	}
}


// create or display environment variables or aliases
int set(int argc, register char **argv)
{
	extern unsigned int page_length;
	extern char *i_cmd_name;

	register char *eptr;
	char buffer[CMDBUFSIZ], *list;
	int fd, rval, alias_flag = 0;

	if (stricmp(i_cmd_name,SET_COMMAND) == 0)
		list = environment;
	else {
		alias_flag = 1;
		list = alias_list;
	}

#ifdef COMPAT_4DOS
	init_dir();
	if ((fd = switch_arg(*(++argv),"RP")) == -1)
		return ERROR_EXIT;

	if (fd & 1) {		// read environment or alias file(s)

		for (rval = 0; (rval == 0) && ((eptr = first_arg(*(++argv))) != NULL); ) {

			if ((fd = sopen(eptr,(O_RDONLY | O_BINARY),SH_DENYWR)) < 0)
				return (error(_doserrno,eptr));

			if (setjmp(env) == -1)
				rval = CTRLC;

			while ((rval == 0) && (getline(fd,buffer,MAXARGSIZ) > 0)) {

				// skip blank lines, leading whitespace, & comments
				eptr = skipspace(buffer);
				if ((*eptr) && (*eptr != ':')) {
					// create/modify a variable or alias
					rval = addenv(eptr,alias_flag);
				}
			}

			close(fd);
		}

		return rval;
	}

	if (fd & 2) {		// pause after each page
		page_length = screenrows();
		argv++;
		argc--;
	}
#endif

	if (*argv == NULL) {

		// print all the variables or aliases
		for (eptr = list; *eptr; eptr = next_env(eptr))
			more(eptr,0);

		return (((alias_flag) && (eptr == list)) ? error(ERROR_BATPROC_NO_ALIASES,NULL) : 0);
	}

	// display the current alias argument?
	if ((argc == 2) && (strchr(*argv,'=') == NULL) && (alias_flag)) {

		if ((eptr = envget(*argv,alias_flag)) == NULL)
			return (error(ERROR_BATPROC_NOT_ALIAS,*argv));

		qputslf(STDOUT,eptr);
		return 0;
	}

	// create/modify/delete a variable or alias
	return (addenv(*argv,alias_flag));
}


#ifdef COMPAT_4DOS

// remove variable(s) or alias(es)
int unset(int argc, register char **argv)
{
	extern char *i_cmd_name;

	register char *eptr;
	int alias_flag = 0, rval = 0;

	if (argc == 1)
		return (usage(UNSET_USAGE));

	if (stricmp(i_cmd_name,UNSET_COMMAND) != 0)
		alias_flag = 1;

	while (*(++argv) != NULL) {

		if (stricmp(*argv,"*") == 0) {

			// wildcard kill - null the environment or alias list
			memset(((alias_flag) ? alias_list : environment),0,2);
			break;
		}

		if ((eptr = envget(*argv,alias_flag)) == NULL)
			rval = error(((alias_flag) ? ERROR_BATPROC_NOT_ALIAS : ERROR_BATPROC_NOT_IN_ENV),*argv);

		// kill the variable/alias
		if ((argc = addenv(*argv,alias_flag)) != 0)
			rval = argc;
	}

	return rval;
}


// edit an existing environment variable or alias
int eset(int argc, register char **argv)
{
	register unsigned char *vname, *eptr;
	unsigned char envbuf[CMDBUFSIZ+82];
	int rval = 0, alias_flag = 0;

	if (argc == 1)
		return (usage(ESET_USAGE));

	while (*(++argv) != NULL) {

		// try environment variables first, then aliases
		if ((eptr = envget(*argv,0)) == NULL) {

			// check for alias editing
			if ((eptr = envget(*argv,1)) == NULL) {
				rval = error(ERROR_BATPROC_NOT_IN_ENV,*argv);
				continue;
			}
			alias_flag = 1;
		}

		// get the start of the alias or variable name
		for (vname = eptr; (vname[-1] != '\0') && (vname > ((alias_flag) ? alias_list : environment)); vname--)
			;

		strcpy(envbuf,vname);

		// echo & edit the argument
		qprintf(STDOUT,"%.*s",(eptr - vname),vname);
		egets(envbuf+(eptr-vname),MAXARGSIZ,ECHO);

		if (addenv(envbuf,alias_flag) != 0)
			rval = ERROR_EXIT;
	}

	return rval;
}

#endif


// retrieve an environment entry
char *pascal envget(char *varname, int alias_flag)
{
	register char *env, *vptr, *eptr;
	unsigned int wildflag;

	for (env = ((alias_flag) ? alias_list : environment); *env; env = next_env(env)) {

		// aliases in 4DOS allow "wher*eis" ; so collapse the '*', and
		//   only match to the length of the varname
		vptr = varname;
		wildflag = 0;

		do {

#ifdef COMPAT_4DOS
			if ((*env == '*') && (alias_flag)) {
				env++;
				if (*vptr == '*')
					vptr++;
				wildflag++;
			}
#endif

			if (((*vptr == '\0') || (*vptr == '=')) && ((*env == '=') || (wildflag)))
				return (((eptr = strchr(env,'=')) != NULL) ? ++eptr : NULL);

		} while (toupper(*env++) == toupper(*vptr++));
	}

	return NULL;
}


// add or delete an environment string (including aliases)
int pascal addenv(char *envstr, int alias_flag)
{
	extern char far *far_env;
	extern unsigned int env_size, alias_size;

	register char *eptr, *new_arg;
	char *env_arg, *env_end, *last_var, *list_start;
	int length;

	// ensure environment entry is upper case, & collapse around the "="
	for (new_arg = envstr; ((*new_arg) && (!isspace(*new_arg)) && (*new_arg != '=')); new_arg++)
		*new_arg = (unsigned char)toupper(*new_arg);

	while (isspace(*new_arg))
		strcpy(new_arg,new_arg+1);

	// check for '=', inserting it if necessary
	//   new_arg now points to the first char of the argument
	if (*new_arg == '=') {
		new_arg++;
		while (isspace(*new_arg))
			strcpy(new_arg,new_arg+1);
	} else if (*new_arg) {
		strins(new_arg,"=");
		new_arg++;
	}

	// get pointers to beginning & end of alias/environment space
	if (alias_flag) {
		list_start = alias_list;
		env_end = alias_list + (alias_size - 2);
	} else {
		list_start = environment;
		env_end = environment + (env_size - 2);
	}

	// get pointer to end of environment or alias variables
	last_var = end_of_env(list_start);

	// check for modification or deletion of existing entry
	if ((env_arg = envget(envstr,alias_flag)) != NULL) {

		// get the start of the alias or variable name
		for (eptr = env_arg; (eptr[-1] != '\0') && (eptr > list_start); eptr--)
			;

		if (*new_arg == '\0') {
			// delete an alias or environment variable
			memmove(eptr,next_env(eptr),(unsigned int)(last_var - next_env(eptr)) + 1);
		} else {

			// modify an existing alias or environment variable

			// get the relative length (vs. the old variable)
			length = strlen(new_arg) - strlen(env_arg);

			// check for out of environment space
			if ((last_var + length) >= env_end)
				return (error(ERROR_BATPROC_OUT_OF_ENV,NULL));

			// adjust the space & insert new value
			eptr = next_env(eptr);
			memmove((eptr + length),eptr,(unsigned int)(last_var - eptr) + 1);

			strcpy(env_arg,new_arg);
		}

	} else if (*new_arg != '\0') {

		// it's a new alias or environment variable
		length = strlen(envstr) + 1;

		// check for out of environment space
		if ((last_var + length) >= env_end)
			return (error(ERROR_BATPROC_OUT_OF_ENV,NULL));

		// put it at the end & add an extra null
		strcpy(last_var,envstr);
		last_var[length] = '\0';
	}

	// update the master (far) environment
	if (alias_flag == 0)
		_fmemmove(far_env,(char far *)environment,env_size - 1);

	return 0;
}


// return a pointer to the next environment variable or alias
char *pascal next_env(register char *eptr)
{
	register int i;

	if ((i = strlen(eptr)) > 0)
		i++;

	return (eptr + i);
}


// get pointer to end of environment variables or aliases
char *pascal end_of_env(char *list)
{
	register char *env;

	for (env = list; *env; env = next_env(env))
		;

	return env;
}


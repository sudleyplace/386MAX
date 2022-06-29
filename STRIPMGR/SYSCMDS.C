//' $Header:   P:/PVCS/MAX/STRIPMGR/SYSCMDS.C_V   1.0   05 Sep 1995 17:13:30   HENRY  $

// SYSCMDS.C - System commands for STRIPMGR
//   Copyright (c) 1990  Rex C. Conn  All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <direct.h>
#include <dos.h>
#include <string.h>

#include "stripmgr.h"


extern char *i_cmd_name;

static char dirstack[DIRSTACKSIZE];	// PUSHD/POPD storage area


// Change the current drive
int pascal drive(register char *dname)
{
	if (_chdrive(toupper(*dname) - 64) != 0)
		return (error(ERROR_INVALID_DRIVE,dname));

	return 0;
}


// change the current directory
int cd(int argc, register char **argv)
{
	register char *ptr;

	// if no args or arg == disk spec, print current working directory
	if ((argc == 1) || (stricmp(*(++argv)+1,":") == 0)) {

		if ((ptr = gcdir(*argv)) == NULL)
			return ERROR_EXIT;	// invalid drive

		qputslf(STDOUT,ptr);
		return 0;
	}

	return (__cd(*argv));
}


int pascal __cd(register char *dir)
{
	register char *ptr;
	char dirname[MAXFILENAME+1];

	// expand the directory name to support things like "cd ..."
	copy_filename(dirname,dir);
	if ((ptr = mkfname(dirname)) == NULL)
		return ERROR_EXIT;

	return ((chdir(ptr) == -1) ? error(_doserrno,dir) : 0);
}


// change the current disk and directory
int cdd(int argc, register char **argv)
{
	if (argc == 1)
		return (usage(CDD_USAGE));

	// if a path is specified, change to it
	if ((stricmp((*(++argv))+1,":") != 0) && (__cd(*argv) != 0))
		return ERROR_EXIT;

	// if a drive is specified, change to it
	return ((argv[0][1] == ':') ? drive(*argv) : 0);
}


// save the current directory & change to new one
int pushd(int argc, register char **argv)
{
	register char *dptr;
	char dir[68];

	if ((dptr = gcdir(NULL)) == NULL)	// get current directory
		return ERROR_EXIT;
	strcpy(dir,dptr);

	// if no arguments, just save the current directory
	if (argc == 1)
		argv[1] = dir;

	while ((strlen(dirstack) + strlen(argv[1])) >= DIRSTACKSIZE - 2) {
		// directory stack overflow - remove the oldest entry
		for (dptr = dirstack + (strlen(dirstack) - 2); (*dptr != '\n'); dptr--)
			*dptr = '\0';
	}

	// change disk and/or directory
	if (cdd(2,argv) != 0)
		return ERROR_EXIT;

	// save the previous disk & directory (dirs are separated by a LF)
	strins(dirstack,"\n");
	strins(dirstack,dir);

	return 0;
}


// POP a PUSHD directory
int popd(int argc, char **argv)
{
	register int rval;
	register char *ptr;

	if (argc > 1) {
		if (stricmp(argv[1],"*") == 0) {
			// clear directory stack
			*dirstack = '\0';
			return 0;
		}
		return (usage(POPD_USAGE));
	}

	// get the most recent directory off the stack
	if ((ptr = strchr(dirstack,'\n')) == NULL)
		return (error(ERROR_BATPROC_DIR_STACK_EMPTY,NULL));
	*ptr++ = '\0';

	// change drive and directory
	rval = (chdir(dirstack) == -1) ? error(_doserrno,dirstack) : drive(dirstack);

	// remove entry from DIRSTACK
	strcpy(dirstack,ptr);

	return rval;
}


// return or set the path in the environment
int path(int argc, register char **argv)
{
 char *argvt;

	// if no args, display the current PATH
	if (argc == 1)
		return 0;

	argvt = argv[1];
	// check for null path spec
	if (stricmp(argvt,";") == 0)
		*argvt = '\0';

	else {

	  // Find the first character not part of " \t="
	  for ( ; *argvt && strchr (" \t=", *argvt); argvt++)
		;
	  strins (argvt,"=");           // Blast it back in
	  argvt -= 4;			// Back off for "PATH"
	  strncpy (argvt, "PATH", 4);   // Blast "PATH" back in

	} // not a null PATH statement

	// add argument to environment (in upper case for Netware bug)
	return (putenv(OurStrdup(strupr(argvt))));
}


// Display/Change the BATPROC variables
int setdos(int argc, register char **argv)
{
	extern BUILTIN commands[];

	register char *arg;

	if (argc > 1) {

		while (*(++argv) != NULL) {

			arg = *argv + 2;
			argc = ((*arg == '\0') ? 0 : switch_arg(*argv,"ACEHILMNRSUVW",0x00));

			if (argc == -1)
				return ERROR_EXIT;
			if (argc == 0)
				return (error(ERROR_INVALID_PARAMETER,*argv));

			if (argc & 2)		// C - compound command separator
				cfgdos.compound = *arg;
			else if (argc & 4)	// E - escape character
				cfgdos.escapechar = *arg;
			else if (argc & 0x10) {
				// I - disable or enable internal cmds
				if ((argc = findcmd(arg+1,1)) < 0)
					return (error(ERROR_BATPROC_UNKNOWN_COMMAND,arg+1));
				else
					commands[argc].enabled = (char)((*arg == '-') ? 0 : 1);
			} else if (argc & 0x80)
				// N - noclobber (output redirection)
				cfgdos.noclobber = (char)((*arg == '0') ? 0 : 1);
			else if (argc & 0x1000) {
				// W - change switch char
				if (isalnum(*arg))
					return (error(ERROR_INVALID_PARAMETER,*argv));
				else {
					// set the switch character
					argc = *arg;
_asm {
					mov	  ax,3701h
					mov	  dx,argc
					int	  21h
}
					cfgdos.switch_char = (char)get_switchar();
				}
			}
		}
	}

	return 0;
}


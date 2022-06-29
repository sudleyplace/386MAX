//' $Header:   P:/PVCS/MAX/STRIPMGR/BATCH.C_V   1.1   02 Jun 1997 10:46:38   BOB  $

// BATCH.C - Batch file routines for BATPROC
//	 Copyright (c) 1990, 1991  Rex C. Conn for Qualitas  All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <ctype.h>
#include <direct.h>
#include <dos.h>
#include <fcntl.h>
#include <io.h>
#include <malloc.h>
#include <setjmp.h>
#include <share.h>
#include <signal.h>
#include <string.h>

#include "stripmgr.h"


static void exit_bat(void);


extern jmp_buf *pEnv;
extern void pushenv (void);
extern void popenv (void);


extern int flag_4dos;		// if != 0, then 4DOS is the command processor
extern char *i_cmd_name;	// name of current internal command
extern char MBSection[];
extern int bn;			// batch file nesting level (0 to MAXBATCH-1)
extern char iff_flag;		// flags for IFF/THEN/ELSE parsing status
extern char else_flag;
extern char endiff_flag;


unsigned int for_var = 0;	// if != 0, then parsing a FOR w/single char var
int batch_called = 0;		// If != 0, entry to batch() was via CALL
static char LDELIMS[] = "+=:[/";


// Execute a batch file (.BAT or .BTM)
int batch(register int argc, register char **argv)
{
	extern char *b_name;	// original unexpanded batch file name
	unsigned char save_iff, save_else, save_endiff;
	int i,repeat;

	// we can only nest batch files up to MAXBATCH levels deep
	if (bn >= MAXBATCH - 1)
		return (error(ERROR_BATPROC_EXCEEDED_NEST,NULL));

	// If chaining to a batch file we've already executed,
	// ignore it and skip to the next label or EOF (whichever
	// comes first)
	for (i=repeat=0; (i <= bn); i++) {
	 if (repeat = !stricmp (argv[0], bframe[i].Batch_name))
		break;
	}

	if (repeat) {

	 // Skip to next label or EOF IF we were not invoked via CALL
	 if (!batch_called) {

		int savebn, rval;
		char cmdline[MAXARGSIZ+1], *cmdptr;

		do {

		 savebn = bn;

		 bn = i;
		 if (open_batch_file() == 0) {
		  bn = savebn;
		  return (0);
		 }

		 rval = getline(bframe[bn].bfd,cmdline,MAXARGSIZ);

		 close_batch_file();

		 bn = savebn;

		 if (rval) {
		  for (cmdptr = cmdline; cmdptr && isspace(*cmdptr); cmdptr++)
			;
		  if (*cmdptr == ':')
			rval = 0;
		 } // check for label

		} while (rval);

	 } // Batch file was chained directly, not CALLed

	 return (0);	// Pretend everything was OK

	} // Batch file was executed previously

	// disable ^C during setup
	signal(SIGINT,SIG_IGN);

	// to allow nested batch files, create a batch frame containing
	//	 all the info necessary for the batch process
	bn++;

	// clear the current frame
	memset(&bframe[bn],'\0',sizeof(bframe[bn]));

	// save the fully expanded name & restore the original name
	//	 (for COMMAND.COM compatibility)
	if ((bframe[bn].Batch_name = strdup(argv[0])) == NULL) {
		bn--;		// Back out of batch file
		return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));
	}

	argv[0] = b_name;

	// save batch arguments (%0 - %argc) onto the heap
	if ((bframe[bn].Argv = (char **)malloc((argc + 1) * sizeof(char *))) == NULL) {
		bn--;		// Back out of batch file
		return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));
	}

	bframe[bn].Argv[argc] = NULL;
	do {
		argc--;
		if ((bframe[bn].Argv[argc] = strdup(argv[argc])) == NULL) {
			bn--;		// Back out of batch file
			return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));
		}
	} while (argc > 0);

	// save the IFF flag when CALLing another batch file
	save_iff = iff_flag;
	save_else = else_flag;
	save_endiff = endiff_flag;

	// clear the IFF flag before running another batch file
	iff_flag = else_flag = endiff_flag = 0;

	argc = batchcli();
	exit_bat();

	// restore the IFF flags
	iff_flag = save_iff;
	else_flag = save_else;
	endiff_flag = save_endiff;

	return argc;
}


// CALL a nested batch file (or any executable file)
// (because the CALL argument may be a .COM or .EXE, we can't just call BATCH)
int call(register int argc, char **argv)
{
	int res;

	if (argc == 1)
		return (usage(CALL_USAGE));

	batch_called = 1;		// Tell batch() entry is via CALL
	res = command(argv[1]); 	// Save result to return to caller
	batch_called = 0;		// Turn off CALL entry flag

	return (res);
}


// clean up & exit a batch file
static void exit_bat(void)
{
	register int n;

	// free the batch argument list
	free(bframe[bn].Batch_name);
	for (n = 0; bframe[bn].Argv[n] != NULL; n++)
		free(bframe[bn].Argv[n]);
	free((char *)bframe[bn].Argv);

	// point back to previous batch file (if any)
	bn--;
}


// FOR - allows iterative execution of DOS commands
int forcmd(int argc, char **argv)
{
	extern int ctrlc_flag, for_flag;

	register int fval;
	register char *arg;
	char fname[MAXFILENAME+1], *cmdline, *var, *argset, *var_arg;
	int rval = 0;
	struct find_t dir;

	// check for proper syntax
	if ((argv[1] == NULL) || (stricmp(first_arg(argv[2]),IN) != 0) || (*(argset = argv[3]) != '(') || ((cmdline = strchr(argset,')')) == NULL)) {
for_usage:
		return (usage(FOR_USAGE));
	}

	// rub out the ')', & point to the command
	*cmdline++ = '\0';
	cmdline = skipspace(cmdline);
	if (stricmp(first_arg(cmdline),DO) == 0)
		cmdline = skipspace(cmdline + strlen(DO));

	if (*cmdline == '\0')
		goto for_usage;

	// "argset" points to the variable set - save it on the heap
	//	 after doing variable expansion on the file spec
	if (NULL == (arg = malloc(CMDBUFSIZ)))
		return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));
	strcpy(arg, argset+1);
	if (var_expand(arg,1) != 0) {
		free(arg);
		return ERROR_EXIT;
	}

	// shrink it down to the minimum size
	argset = strcpy(alloca(strlen(arg)+1),arg);
	free(arg);

	// point to actual command line & do kludge to get rid of "%%"
	for (arg = cmdline; ; arg++) {
		arg = scan(arg,"%",BACK_QUOTE);
		if (*arg == '\0')
			break;
		if (*(++arg) == '%')
			strcpy(arg,arg+1);
	}

	// save the command line on the stack
	cmdline = strcpy(alloca(strlen(cmdline)+1),cmdline);

	// get variable name & save it on the stack
	for (var = first_arg(argv[1]); (*var == '%'); var++)
		;

	// set flag if FOR variable is single char (kludge for COMMAND.COM
	//	 limitation)
	for_var = (((fval = strlen(var)) == 1) ? *var : 0);
	var = strcpy(alloca(fval+82),var);
	var_arg = var + fval;

	pushenv (); // Save old jmp_buf

	for (for_flag = 1, ctrlc_flag = argc = 0, fval = FIND_FIRST; ((arg = ntharg(argset,argc)) != NULL); ) {

		// check for ^C abort
		if ((setjmp(*pEnv) == -1) || (ctrlc_flag)) {
			rval = CTRLC;
			break;
		}

		// if ARG includes * or ?, set VAR to each matching
		//	 filename from the disk
		if (strpbrk(arg,"*?") != NULL) {
			if (find_file(fval,arg,0,&dir,fname) == NULL) {
				// no more matches - get next argument
				argc++;
				fval = FIND_FIRST;
				continue;
			}
			arg = fname;
			fval = FIND_NEXT;
		} else {
			argc++;
			fval = FIND_FIRST;
		}

		// create new environment variables to expand
		sprintf(var_arg,"=%.79s",arg);
		putenv(var);

		// execute the command
		rval = command(cmdline);
		if (bframe[bn].read_offset == -1L)
			break;
	}

	popenv (); // Restore old jmp_buf

	for_var = for_flag = 0;
	*var_arg = '\0';
	putenv(var);		// remove the variable

	return rval;
}


// Call subroutine (GOSUB labelname)
int gosub_cmd(int argc, char **argv)
{
	extern int ctrlc_flag;

	register char *arg;
	long offset;
	char save_iff, save_endiff, save_else;

	// skip a leading ':' in label name
	arg = argv[1];
	if (*arg == ':')
		arg++;

	// remove a trailing :, =, and/or +
	strip_trailing(arg,LDELIMS);

	if ((bframe[bn].DOS6Flag == 0) && ((_osmajor < 6) ||
					   (MBSection[0] == '\0') ||
					(stricmp(arg,MBSection) != 0)))
		return 0;

	bframe[bn].DOS6Flag = 1;

	// save current position to RETURN to
	offset = bframe[bn].read_offset;

	// call the subroutine
	if ((argc = goto_label(arg,1)) == 0) {

		// save the IFF flags state
		save_iff = iff_flag;
		save_else = else_flag;
		save_endiff = endiff_flag;

		// clear the IFF flags
		iff_flag = else_flag = endiff_flag = 0;

		bframe[bn].gsoffset++;
		if (((argc = batchcli()) == CTRLC) || (ctrlc_flag))
			bframe[bn].read_offset = -1L;

		else if (bframe[bn].read_offset >= 0L) {

			// restore the saved file read offset
			bframe[bn].read_offset = offset;

			// restore the IFF flag
			iff_flag = save_iff;
			else_flag = save_else;
			endiff_flag = save_endiff;
		}
	}

	return argc;
}


// GOTO a label in the batch file
int goto_cmd(int argc, register char **argv)
{
	register char *arg;

	if ((argc = switch_arg(*(++argv),"I",0x00)) == 1)
		argv++;

	// skip a leading ':' in label name
	arg = *argv;
	if (*arg == ':')
		arg++;

	// remove a trailing :, =, and/or +
	strip_trailing(arg,LDELIMS);

	if ((bframe[bn].DOS6Flag == 0) && ((_osmajor < 6) ||
					   (MBSection[0] == '\0') ||
					   (stricmp(arg,MBSection) != 0)))
		return 0;

	bframe[bn].DOS6Flag = 1;

	// position file pointer & force bad return to abort multiple cmds
	if ((goto_label(arg,1) == 0) && (argc != 1)) {
		// turn off IFF flag when you do a GOTO unless a /I specified
		iff_flag = endiff_flag = else_flag = 0;
	}

	return ABORT_LINE;
}


// position the file pointer following the label line
int pascal goto_label(register char *label, int error_flag)
{
	register char *ptr;
	char line[256];

	// GOSUB / GOTO must have an argument!
	if (label == NULL)
		return USAGE_ERR;

	// make sure the file is still open
	if (open_batch_file() == 0)
		return BATCH_RETURN;

	// rewind file for search
	lseek(bframe[bn].bfd,0L,SEEK_SET);
	bframe[bn].read_offset = 0L;

	// scan for the label
	while (getline(bframe[bn].bfd,line,255) > 0) {

		// strip leading white space, & just read first word
		if (((ptr = first_arg(line)) != NULL) && (*ptr == ':') && (stricmp(label,++ptr) == 0))
			return 0;
	}

	return ERROR_EXIT;
}


// conditional IF command (including ELSE/ELSEIFF)
int ifcmd(int argc, register char **argv)
{
	extern int error_level; 	// return code of last external command

	register int condition;
	register char *argptr;
	char *arg2ptr, *tptr;
	int notflag, or_flag = 0, and_flag = 0, xor_flag = 0xFF, iff_cmd = 0;
	int DOS6IfFlag = 0;

	// test the command name (IF or IFF)
	if (strnicmp(*argv,IFF,3) == 0)
		iff_cmd = 1;

	if (argc < 3) {
if_usage:
		return (usage(iff_cmd ? IFF_USAGE : IF_USAGE));
	}

	// KLUDGE for compatibility with things like "if %1/==/ ..."
	//	 (IF[F] doesn't have any switches anyway)
	cfgdos.switch_char = 0x7F;

if_loop:
	// (re)set result condition
	condition = notflag = 0;

	if ((argptr = first_arg(*(++argv))) != NULL) {

		// check for IF NOT condition
		if (stricmp(argptr,IF_NOT) == 0) {
			notflag = 1;
			argptr = first_arg(*(++argv));
		}
	}

	if (argptr == NULL)
		goto if_usage;

	argptr = strcpy(*argv,argptr);
	if ((arg2ptr = first_arg(*(++argv))) == NULL)
		goto if_usage;

	if (stricmp(argptr,IF_EXIST) == 0) {

		// check for existence of specified file
		condition = is_file(arg2ptr);

	} else if (stricmp(argptr,IF_ISINTERNAL) == 0) {

		// check for existence of specified internal command
		condition = (findcmd(arg2ptr,0) >= 0);

	} else if ((stricmp(argptr,IF_ISDIR) == 0) || (stricmp(argptr,IF_DIREXIST) == 0)) {

		// check ready state & existence of specified directory
		//	 ("if direxist" is for DR-DOS compatibility)
		condition = is_dir(arg2ptr);

	} else if (stricmp(argptr,IF_ISLABEL) == 0) {

		// check existence of specified batch label
		if (bn >= 0) {

			long save_offset;

			save_offset = bframe[bn].read_offset;
			strcpy(*argv,arg2ptr);
			condition = (goto_label(*argv,0) == 0);
			bframe[bn].read_offset = save_offset;

			// reset file pointer
			lseek(bframe[bn].bfd,save_offset,SEEK_SET);
		}

	} else {

		arg2ptr = NULL;
		argv--;

		// check for a "=" or "==" in the middle of the first argument
		tptr = scan(argptr,"=",QUOTES);
		if (*tptr == '\0') {

			// next argument must be test type
			argv++;

			// terminate test type
			tptr = strcpy(*argv,first_arg(*argv));
		}

		if (*tptr == '=') {

			// change a "==" to a "EQ"
			arg2ptr = tptr;
			while (*arg2ptr == '=')
				*arg2ptr++ = '\0';

			tptr = EQ;
		}

		// we have to support various ERRORLEVEL constructs:
		//	 if ERRORLEVEL 5 ; if ERRORLEVEL == 5 ; if ERRORLEVEL LT 5
		if ((stricmp(argptr,IF_ERRORLEVEL) == 0) && (isdigit(*tptr))) {

			arg2ptr = tptr;
			tptr = GE;

		} else if ((arg2ptr == NULL) || (*arg2ptr == '\0')) {

			// have we got the second argument yet?
			if ((arg2ptr = first_arg(*(++argv))) == NULL)
				goto if_usage;
		}

		// check error return of previous command or do string match
		if (stricmp(argptr,IF_ERRORLEVEL) == 0)
			condition = (error_level - atoi(arg2ptr));
		else {
			// do ASCII/numeric comparison
			condition = stricmp(argptr,arg2ptr);

			// check for %CONFIG% processing
			// first strip any enclosing quotes, parentheses, etc.
			argptr = skipdelims(argptr,"\"/\\(");
			arg2ptr = skipdelims(arg2ptr,"\"/\\(");
			strip_trailing(argptr,"\"/\\)");
			strip_trailing(arg2ptr,"\"/\\)");

			if (	(_osmajor >= 6) &&
				(MBSection[0]) &&
				((stricmp(argptr,MBSection) == 0) ||
				 (stricmp(arg2ptr,MBSection) == 0)))
				DOS6IfFlag = 1;
		}

		argptr = tptr;

		// modify result based on equality test
		if (stricmp(argptr,EQ) == 0)
			condition = (condition == 0);
		else if (stricmp(argptr,GT) == 0)
			condition = (condition > 0);
		else if (stricmp(argptr,GE) == 0)
			condition = (condition >= 0);
		else if (stricmp(argptr,LT) == 0)
			condition = (condition < 0);
		else if (stricmp(argptr,LE) == 0)
			condition = (condition <= 0);
		else if ((stricmp(argptr,NE) == 0) || (stricmp(argptr,"!=") == 0))
			condition = (condition != 0);
		else
			goto if_usage;
	}

	condition ^= notflag;

	if ((argptr = first_arg(argv[1])) == NULL)
		goto if_usage;

	// if OR_FLAG != 0, a successful OR test is in progress
	// force condition to TRUE
	if (or_flag) {
		condition = 1;
		or_flag = 0;
	}

	// if XOR_FLAG != 0xFF, then an XOR test is in progress
	if (xor_flag != 0xFF) {
		condition = (condition ^ xor_flag);
		xor_flag = 0xFF;
	}

	// if AND_FLAG != 0, an unsuccessful AND test is in progress
	// force condition to FALSE
	if (and_flag) {
		condition = 0;
		and_flag = 1;
	}

	// conditional OR
	if (stricmp(IF_OR,argptr) == 0) {

		// We need to keep parsing the line, even if the last test was
		//	 true (for IFF).  Save the condition in OR_FLAG.
		or_flag = condition;

		argv++;
		goto if_loop;
	}

	// exclusive OR
	if (stricmp(IF_XOR,argptr) == 0) {

		// Continue parsing the line to get the second test value
		xor_flag = condition;

		argv++;
		goto if_loop;
	}

	// conditional AND
	if (stricmp(IF_AND,argptr) == 0) {

		// We need to keep parsing the line, even if the last test was
		//	 false (for IFF).  Save the inverse condition in AND_FLAG.
		and_flag = (condition == 0);

		argv++;
		goto if_loop;
	}

	// IFF / THEN / ELSE support
	if ((iff_cmd) && (stricmp(THEN,argptr) == 0)) {

		// increment IFF nesting flag
		// if condition is false, flag as "waiting for ELSE"
		iff_flag++;
		if (condition == 0)
			else_flag++;

		// skip THEN & see if there's another argument
		argv++;

		if (argv[1] == NULL)
			return 0;
	}

	if (argv[1] == NULL)
		goto if_usage;

	if (DOS6IfFlag) {
		if (condition) {
			bframe[bn].DOS6Flag = 1;
			condition = command(argv[1]);
		}
		return condition;
	}

	// always process the command, regardless of the test result
	return (command(argv[1]));
}


// check for IFF THEN / ELSE / ENDIFF condition
//	 (Note: STRIPMGR wants to process everything regardless of IFF state)
int pascal iff_parsing(register char *cmd_name, char *line)
{
	static char DELIMS[] = "%9[^  .\"`\\+=:<>|]";

	// if not parsing an IFF just return
	if (iff_flag == 0)
		return 0;

	// extract the command name (first argument)
	DELIMS[4] = cfgdos.compound;
	DELIMS[5] = cfgdos.switch_char;
	sscanf(cmd_name,DELIMS,cmd_name);

	// terminated IFF tests?
	if (stricmp(cmd_name,ENDIFF) == 0) {

		// drop one ENDIFF wait
		if (endiff_flag == 0) {
			iff_flag--;
			else_flag = 0;
		} else
			endiff_flag--;

		return 1;

	} else if (stricmp(cmd_name,IFF) == 0) {

		// if "waiting for ELSE" or "waiting for ENDIFF" flags set,
		//	 ignore nested IFFs
		if (else_flag)
			endiff_flag++;

	} else if ((endiff_flag == 0) && ((stricmp(cmd_name,ELSE) == 0) || (stricmp(cmd_name,ELSEIFF) == 0))) {

		// are we waiting for an ELSE[IFF]?
		if (else_flag & 0x7F) {

			// remove an ELSE or make an ELSEIFF look like an IFF
			else_flag = 0;
			strcpy(line,line+4);

			// an ELSEIFF is an implicit ENDIFF
			if (stricmp(cmd_name,ELSEIFF) == 0)
				iff_flag--;
			else if (*(skipspace(line)) != cfgdos.compound) {
				// if an ELSE doesn't have a ^, add one
				DELIMS[5] = '\0';
				strins(line,DELIMS+4);
			}

		} else
			else_flag = 0x80;	// wait for an ENDIFF
	}

	// waiting for ELSE[IFF] or ENDIFF?
	if (bframe[bn].DOS6Flag)
		return (else_flag | endiff_flag);

	// execute everything except an ENDIFF
	return 0;
}


// just a comment; ignore it
int remark(int foo, char **fop)
{
	return 0;
}


//' $Header:   P:/PVCS/MAX/BATPROC/BATCH.C_V   1.1   02 Jun 1997 12:19:02   BOB  $
//
// BATCH.C - Batch file routines for BATPROC
//   Copyright (c) 1990-93  Rex C. Conn & Qualitas   All rights reserved

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

#include "batproc.h"


static void exit_bat(void);
static int pascal goto_label(char *);


extern jmp_buf env;
extern int flag_4dos;		// if != 0, then 4DOS is active

extern char *i_cmd_name;	// name of current internal command
extern int bn;			// batch file nesting level (0 to MAXBATCH-1)

extern char iff_flag;		// flags for IFF/THEN/ELSE parsing status
extern char else_flag;
extern char endiff_flag;

extern void dump_cmdinfo(int forcedump); // from PARSER.C

unsigned int for_var = 0;	// if != 0, then parsing a FOR w/single char var

static char call_flag = 0;	// 0 for overwrite, 1 for nesting


// Execute a batch file (.BAT or .BTM)
int batch(register int argc, register char **argv)
{
	extern char *b_name;	// original unexpanded batch file name
	unsigned char save_echo, save_iff, save_endiff, save_else;

	// we can only nest batch files up to MAXBATCH levels deep
	if (bn >= MAXBATCH - 1)
		return (error(ERROR_BATPROC_EXCEEDED_NEST,NULL));

	// disable ^C during setup
	signal(SIGINT,SIG_IGN);

	// set ECHO state flag (from parent file or CFGDOS)
	save_echo = ((bn < 0) ? cfgdos.batecho : bframe[bn].echo_state);

	// disable batch file nesting unless CALL (call_flag == 1)
	if (call_flag == 0) {

		// reset old batch file to the new batch file!
		if (bn >= 0)
			exit_bat();
		else		// first batch file counts as nested
			call_flag = 1;
	}

	// to allow nested batch files, create a batch frame containing
	//   all the info necessary for the batch process
	bn++;

	// clear the current frame
	memset(&bframe[bn],'\0',sizeof(bframe[bn]));

	// save the fully expanded name & restore the original name
	//   (for COMMAND.COM compatibility)
	if (NULL == (bframe[bn].Batch_name = strdup(argv[0])))
	{   bn--;		// Back out of batch file
	    return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));
	}
	argv[0] = b_name;

	// save batch arguments (%0 - %argc) onto the heap
	if (NULL == (bframe[bn].Argv = (char **)malloc((argc + 1) * sizeof(char *))))
	{   bn--;		// Back out of batch file
	    return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));
	}
	bframe[bn].Argv[argc] = NULL;
	do {
		argc--;
		if (NULL == (bframe[bn].Argv[argc] = strdup(argv[argc])))
		{   bn--;		// Back out of batch file
		    return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));
		}
	} while (argc > 0);

	// set ECHO state (previously saved from parent file or CFGDOS)
	bframe[bn].echo_state = save_echo;

	// save the IFF flags when CALLing another batch file
	if (call_flag) {
		save_iff = iff_flag;
		save_endiff = endiff_flag;
		save_else = else_flag;
	}

	// clear the IFF flags before running another batch file
	iff_flag = endiff_flag = else_flag = 0;

	// Reset the start_line value to ffff.
	bframe[bn].start_line = 0xffff; // No lines recorded

	// if nesting, call batchcli() recursively...
	if (call_flag) {

		call_flag = 0;
		argc = batchcli();
		exit_bat();

		// restore the IFF flags
		iff_flag = save_iff;
		endiff_flag = save_endiff;
		else_flag = save_else;
	} else
		argc = ABORT_LINE;	// end any FOR processing

	return argc;
}


// CALL a nested batch file (or any executable file)
// (because the CALL argument may be a .COM or .EXE, we can't just call BATCH)
int call(register int argc, char **argv)
{
	if (argc == 1)
		return (usage(CALL_USAGE));

	call_flag = 1;
	argc = command(argv[1]);
	call_flag = 0;

	return argc;
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

#ifdef COMPAT_4DOS
	// restore saved environment
	if (bframe[bn].local_set != 0L)
		endlocal(0, NULL);
#endif

	// If any ranges remain, dump 'em now.  Ignore current line_offset.
	dump_cmdinfo (1);

	// point back to previous batch file (if any)
	bn--;
}



// echo arguments to the screen (stdout)
int echo(int argc, register char **argv)
{
	extern char verbose;		// command line echo state

	if (argc == 1)			// just inquiring about ECHO state
		qprintf(STDOUT,ECHO_IS,(bframe[bn].echo_state) ? ON : OFF);
	else if (stricmp(argv[1],OFF) == 0) {
		// disable batch file echoing
		bframe[bn].echo_state = 0;
	} else if (stricmp(argv[1],ON) == 0) {
		// enable batch file or command line echoing
		bframe[bn].echo_state = 1;
	} else {
		// print the line verbatim
		qputslf(STDOUT,*argv + (strlen(i_cmd_name) + 1));
	}

	return 0;
}


// FOR - allows iterative execution of DOS commands
int forcmd(int argc, char **argv)
{
	extern int ctrlc_flag, for_flag;

	register int fval;
	register char *arg;
	char fname[CMDBUFSIZ], *cmdline, *var, *argset, *var_arg;
	int rval = 0;
	struct find_t dir;

	// set IF / FOR flag
	bframe[bn].conditional = 1;

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
	//   after doing variable expansion on the file spec
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
	//   limitation)
	for_var = (((fval = strlen(var)) == 1) ? *var : 0);
	var = strcpy(alloca(fval+82),var);
	var_arg = var + fval;

	for (for_flag = 1, ctrlc_flag = argc = 0, fval = FIND_FIRST; ((arg = ntharg(argset,argc)) != NULL); ) {

		// check for ^C abort
		if ((setjmp(env) == -1) || (ctrlc_flag)) {
			rval = CTRLC;
			break;
		}

		// if ARG includes * or ?, set VAR to each matching
		//   filename from the disk
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
		addenv(var,0);

		// execute the command
		if (((rval = command(cmdline)) == ABORT_LINE) || (bframe[bn].read_offset == -1L))
			break;
	}

	for_var = for_flag = 0;
	*var_arg = '\0';
	addenv(var,0);		// remove the variable

	return rval;
}



// GOTO a label in the batch file
int gotocmd(int argc, char **argv)
{
	// position file pointer & force bad return to abort multiple cmds
	if (goto_label(argv[1]) == 0) {
		// turn off IFF flag when you do a GOTO
		iff_flag = endiff_flag = else_flag = 0;
	}

	return ABORT_LINE;
}


// position the file pointer following the label line
static int pascal goto_label(register char *label)
{
	register char *ptr;
	char cmdline[CMDBUFSIZ];
	int rval;

	// set IF / FOR / GOTO flag
	bframe[bn].conditional = 1;

	// GOSUB / GOTO only allowed in batch files, & must have an argument!
	if (label == NULL)
		return USAGE_ERR;

	// back to beginning of file for search
	bframe[bn].read_offset = bframe[bn].write_offset = 0L;
	bframe[bn].line_offset = bframe[bn].line_number = 0;

	// skip a leading ':' in label name
	if (*label == ':')
		label++;

	// open the batch file and scan for the label
	if (open_batch_file(O_RDONLY) == 0)
		return ERROR_EXIT;

	while ((rval = getline(bframe[bn].bfd,cmdline,MAXARGSIZ)) > 0) {

		// strip leading white space, & just read first word
		ptr = skipspace(cmdline);
		if ((*ptr == ':') && (stricmp(label,first_arg(++ptr)) == 0))
			break;

		lseek(bframe[bn].bfd,bframe[bn].read_offset,SEEK_SET);
	}

	close_batch_file();

	return ((rval > 0) ? 0 : error(ERROR_BATPROC_LABEL_NOT_FOUND,label));
}


// conditional IF command (including ELSE/ELSEIFF)
int ifcmd(int argc, register char **argv)
{
	extern int error_level; 	// return code of last external command
	extern int if_flag;
#ifdef COMPAT_4DOS
	extern char *video_type[];
#endif

	register char *argptr;
	unsigned int memsize;
	struct diskfree_t d_stat;
	struct find_t dir;
	char *arg2ptr, *tptr, *fname, kval;
	int condition = FALSE, notflag = FALSE, attrib = 0, iff_cmd = 0;
	int eqcnt = 0;
	long test = 0L, arg2val;

#ifdef COMPAT_4DOS
	// test the command name (IF or IFF)
	if (flag_4dos && strnicmp(*argv,IFF,3) == 0)
		iff_cmd = 1;
#endif

	// set IF / FOR flag
	bframe[bn].conditional = 1;

	if (argc < 3) {
if_usage:
		return (usage(iff_cmd ? IFF_USAGE : IF_USAGE));
	}

	// kludge to allow things like "if %1/==/ ..."
	cfgdos.switch_char = ' ';

	argptr = first_arg(*(++argv));

	// check for IF NOT condition
	if (stricmp(argptr,NOT) == 0) {
		notflag = TRUE;
		argptr = first_arg(*(++argv));
	}

	argptr = strcpy(*argv,argptr);
	if ((arg2ptr = first_arg(*(++argv))) == NULL)
		goto if_usage;

	if (stricmp(argptr,EXIST) == 0) {
		// check for existence of specified file
		if (is_file(arg2ptr))
			condition = TRUE;
#ifdef COMPAT_4DOS
	} else if (flag_4dos && stricmp(argptr,ISALIAS) == 0) {
		// check for existence of specified alias
		if (envget(arg2ptr,1) != NULL)
			condition = TRUE;
	} else if (flag_4dos && stricmp(argptr,ISDIR) == 0) {
		// check existence of specified directory
		if (is_dir(arg2ptr))
			condition = TRUE;
	} else if (flag_4dos && stricmp(argptr,ATTRIBUTES) == 0) {

		// check for file attribute match
		argv++;
		sscanf(*argv,"%5s",*argv);

		// kludge for getting volume label (DOS get attribute won't
		//   find it!)
		attrib = ((strchr(strupr(*argv),'V') == NULL) ? 0x117 : 0x108);
		if (find_file(FIND_FIRST,arg2ptr,attrib,&dir,NULL) == NULL)
			return (error(_doserrno,arg2ptr));

		attrib = dir.attrib;

		// get the desired test (NRHSVDA)
		for (argptr = *argv; *argptr; argptr++) {

			if (*argptr == 'N')
				condition = 0;
			else if (*argptr == 'R')
				condition |= _A_RDONLY;
			else if (*argptr == 'H')
				condition |= _A_HIDDEN;
			else if (*argptr == 'S')
				condition |= _A_SYSTEM;
			else if (*argptr == 'V')
				condition |= _A_VOLID;
			else if (*argptr == 'D')
				condition |= _A_SUBDIR;
			else if (*argptr == 'A')
				condition |= _A_ARCH;
			else
				return (error(ERROR_INVALID_PARAMETER,argptr));
		}

		condition = (condition == ((condition == 0) ? attrib : (condition & attrib)));
#endif
	} else {
		// Variable usage:
		//  ARGPTR ==> keyword (errorlevel, etc.) or string ("...")
		//  TPTR   ==> test type
		//  ARG2PTR==> next argument

		// If testing for filesize, we need to adjust the args a bit
		if (flag_4dos && stricmp(argptr,FILESIZE) == 0)
			fname = *argv;
		else
			argv--;

		// check for a "=" in the middle of the first argument
		tptr = scan(argptr,"=",QUOTES);
		if (*tptr == '\0') {
			// next argument must be test type
			argv++;
			// terminate test type
			tptr = strcpy(*argv,first_arg(*argv));
		}

		// Handle case where TPTR starts with EQ and possibly
		//  contains additional argument text
		if (*tptr == '=') {

			// change a "=", "==", etc. to "EQ"
			while (*tptr == '=') {
				*tptr++ = '\0'; // Zap the equal sign and terminate
						// ARGPTR
				eqcnt++;	// Count it in
			}

			// Handle DOS ignore of equal sign in "if errorlevel=1"
			// but otherwise syntax error with only one equal sign
			// as well as DOS/4DOS syntax error with too many equal
			// signs.
			if (eqcnt > 2
			 || (!flag_4dos
			  && stricmp(argptr,ERRORLEVEL) != 0
			  && eqcnt == 1))
			    goto if_usage;

			if (*tptr == '\0')
			    arg2ptr = first_arg(*(++argv));
			else
			    arg2ptr = tptr;	    // Point to next argument

			// Set test type based upon various conditions
			tptr = (!flag_4dos && stricmp(argptr,ERRORLEVEL) == 0)
				? GE : EQ;

		} else {

			// TPTR does not start with EQ:  check for default test
			if (isdigit(*tptr)) {
			    arg2ptr = tptr;
			    // Set test type based upon various conditions
			    tptr = (!flag_4dos && stricmp(argptr,ERRORLEVEL) == 0)
				    ? GE : EQ;
			} else {
			    if (flag_4dos)
				arg2ptr = first_arg(*(++argv));
			    else
				goto if_usage;
			}
		}

		if (arg2ptr == NULL)
		    goto if_usage;

		// We have to support various ERRORLEVEL constructs:
		//			     Same As
		//			  4DOS	   COMMAND.COM
		//   if ERRORLEVEL    5   GE 5	      GE 5
		//   if ERRORLEVEL =  5   EQ 5	      GE 5
		//   if ERRORLEVEL == 5   EQ 5	      GE 5
		//   if ERRORLEVEL LT 5   LT 5	   Syntax Error

/////////////// // Handle the case where there's no test condition
/////////////// if ((stricmp(argptr,ERRORLEVEL) == 0) && (isdigit(*arg2ptr))) {
/////////////// 	if (eqcnt == 0)
/////////////// 	    tptr = GE;
/////////////// } else if ((arg2ptr == NULL) || (*arg2ptr == '\0')) {
/////////////// 	// have we got the second argument yet?
/////////////// 	if ((arg2ptr = first_arg(*(++argv))) == NULL)
/////////////// 	    goto if_usage;
/////////////// }

		if (sscanf(arg2ptr,"%lu%c",&arg2val,&kval) == 2) {
			if (toupper(kval) == 'K')
				arg2val <<= 10;
			else if (toupper(kval) == 'M')
				arg2val <<= 20;
		}

		// check error return of previous command or do string match
		if (stricmp(argptr,ERRORLEVEL) == 0) {
			test = error_level - atoi(arg2ptr);
#ifdef COMPAT_4DOS
		} else if (flag_4dos && stricmp(argptr,FILESIZE) == 0) {

			// file size test
			if (find_file(FIND_FIRST,first_arg(fname),0x100,&dir,NULL) != NULL)
				test = dir.size - arg2val;
		} else if (flag_4dos && stricmp(argptr,DISKFREE) == 0) {
			if (_dos_getdiskfree(0,&d_stat))
				return ERROR_EXIT;
			test = (long)(d_stat.bytes_per_sector * d_stat.sectors_per_cluster) * (long)(d_stat.avail_clusters);
			test = test - arg2val;
		} else if (flag_4dos && stricmp(argptr,DOSMEM) == 0) {
			// get free DOS memory
			_dos_allocmem(0xFFF0,&memsize);
			test = memsize;
			test = (test << 4) - arg2val;
		} else if (flag_4dos && stricmp(argptr,EMS) == 0) {
			// get free expanded memory (LIM) in 16K pages
			memsize = 0;
			get_expanded(&memsize);
			test = memsize;
			test = (test << 14) - arg2val;
		} else if (flag_4dos && stricmp(argptr,EXTENDED) == 0) {
			// get free extended memory (if any) for 286's and 386's
			test = get_extended();
			test = (test << 10) - arg2val;
		} else if (flag_4dos && stricmp(argptr,XMS) == 0) {
			// get free XMS memory (if any) for 286's and 386's
			test = get_xms(&argc);
			test = (test << 10) - arg2val;
		} else if (flag_4dos && stricmp(argptr,MONITOR) == 0)
			test = stricmp((((get_video() % 2) == 0) ? MONO_MONITOR : COLOR_MONITOR), arg2ptr);
		else if (flag_4dos && stricmp(argptr,VIDEO) == 0) {
			test = stricmp(video_type[get_video()],arg2ptr);
#endif
		} else {
			// do numeric comparison on numbers & ASCII on strings
#ifdef COMPAT_4DOS
			if (flag_4dos)
			    test = ((isdigit(*argptr) && isdigit(*arg2ptr)) ? fstrcmp(argptr,arg2ptr) : stricmp(argptr,arg2ptr));
			else
#endif
			test = stricmp(argptr,arg2ptr);
		}

		if (stricmp(tptr,EQ) == 0)
			condition = (test == 0);
		else if (stricmp(tptr,GE) == 0)
			condition = (test >= 0);
#ifdef COMPAT_4DOS
		else if (flag_4dos && stricmp(tptr,GT) == 0)
			condition = (test > 0);
		else if (flag_4dos && stricmp(tptr,LT) == 0)
			condition = (test < 0);
		else if (flag_4dos && stricmp(tptr,LE) == 0)
			condition = (test <= 0);
		else if (flag_4dos && ((stricmp(tptr,NE) == 0) || (stricmp(tptr,"!=") == 0)))
			condition = (test != 0);
#endif
		else
			goto if_usage;

	}

	condition ^= notflag;

#ifdef COMPAT_4DOS

	// IFF / THEN / ELSE support
	if (flag_4dos && (iff_cmd) && (stricmp(THEN,first_arg(argv[1])) == 0)) {

		// increment IFF nesting flag
		// if condition is false, flag as "waiting for ELSE"
		iff_flag++;
		if (condition == FALSE)
			else_flag++;
		argv++;
		if (argv[1] == NULL)
			return 0;
	}

#endif

	if (argv[1] == NULL)
		goto if_usage;

	if (condition == FALSE)
		return 0;

	// set flag to indicate we're in an IF statement
	if_flag = 1;
	condition = command(argv[1]);
	if_flag = 0;

	return condition;
}


#ifdef COMPAT_4DOS

// send a block of text to the screen
int battext(int argc, char **argv)
{
	register int rval;
	char cmdline[CMDBUFSIZ];

	// open & scan the batch file until we find an ENDTEXT
	if (open_batch_file(O_RDONLY) == 0)
		return ERROR_EXIT;

	while ((rval = getline(bframe[bn].bfd,cmdline,MAXARGSIZ)) > 0) {

		if (stricmp(first_arg(cmdline),ENDTEXT) == 0)
			break;

		qputslf(STDOUT,cmdline);
		lseek(bframe[bn].bfd,bframe[bn].read_offset,SEEK_SET);
	}

	close_batch_file();

	return ((rval) ? 0 : error(ERROR_BATPROC_MISSING_ENDTEXT,NULL));
}


// make a beeping noise (optionally specifying tone & length)
int beep(int argc, char **argv)
{
	register unsigned int tone = 440, length = 2;

	do {
		if (argv[1] != NULL) {
			tone = atoi(*(++argv));
			if (argv[1] != NULL)
				length = atoi(*(++argv));
		}
		DosBeep(tone,length);

	} while (argv[1] != NULL);

	return 0;
}


// wait for the specified number of seconds
int delay(int argc, char **argv)
{
	// default to 1 second
	unsigned long delay = 1L;

	if (argc > 1)
		delay = atol(argv[1]);

	// DosBeep with a frequency < 20 Hz just counts ticks & returns
	DosBeep(0,(unsigned int)((delay * 182) / 10));

	return 0;
}


// Call subroutine (GOSUB labelname)
int gosub(register int argc, char **argv)
{
	long offset;

	// save current position to RETURN to
	offset = bframe[bn].read_offset;

	// call the subroutine
	if ((argc = goto_label(argv[1])) == 0) {

		bframe[bn].gsoffset++;
		if ((argc = batchcli()) == CTRLC)
			bframe[bn].read_offset = -1L;
		else if (bframe[bn].read_offset >= 0L)
			bframe[bn].read_offset = offset;
	}

	return argc;
}


// check for IFF THEN / ELSE / ENDIFF condition
//   (if waiting for ENDIFF or ELSE, ignore the command)
int pascal iff_parsing(register char *cmd_name, char *line)
{
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
		//   ignore nested IFFs
		if (else_flag)
			endiff_flag++;

	} else if ((endiff_flag == 0) && ((stricmp(cmd_name,ELSE) == 0) || (stricmp(cmd_name,ELSEIFF) == 0))) {

		// are we waiting for an ELSE[IFF]?
		if (else_flag & 0x7F) {

			// an ELSEIFF is an implicit ENDIFF
			if (stricmp(cmd_name,ELSEIFF) == 0)
				iff_flag--;

			// remove an ELSE or make an ELSEIFF look like an IFF
			else_flag = 0;
			strcpy(line,line+strlen(ELSE));

		} else
			else_flag = 0x80;	// wait for an ENDIFF
	}

	// waiting for ELSE[IFF] or ENDIFF?
	return (else_flag | endiff_flag);
}


// assign a single-key value to a shell variable (INKEY)
// assign a string to a shell variable (INPUT)
int inkey_input(int argc, register char **argv)
{
	register char *argptr;
	char cmdbuf[CMDBUFSIZ];
	long time_delay;

	// get the last argument & remove it from the prompt string
	argptr = argv[argc-1];
	if (*argptr != '%')
		return (usage(INKEY_INPUT_USAGE));

	*argptr++ = '\0';
	sprintf(cmdbuf,"%.80s=",argptr);

	// check for optional timeout
	if ((time_delay = switch_arg(*(++argv),"W")) == -1L)
		return ERROR_EXIT;

	if (time_delay == 1L) {
		time_delay = atol(*argv+2);
		argv++;
	} else
		time_delay = -1L;

	// print the (optional) prompt string
	if (*argv != NULL)
		qputs(STDOUT,*argv);

	// wait the (optionally) specified length of time
	if (time_delay >= 0L) {

		for (time_delay *= 18; ; time_delay--) {

			if (kbhit())
				break;

			if (time_delay == 0L) {
				if (*argv != NULL)
					crlf();
				return 0;
			}
			DosBeep(0,1);		// wait 1/18th second
		}
	}

	// get the variable
	if (stricmp(i_cmd_name,INKEY_COMMAND) == 0) {
		argc = getkey(ECHO);
		crlf();
		sprintf(cmdbuf+strlen(cmdbuf),((argc <= 0xFF) ? "%c" : "@%u"),(argc & 0xFF));
	} else
		getline(0,cmdbuf+strlen(cmdbuf),(MAXARGSIZ-strlen(cmdbuf)));

	return (addenv(cmdbuf,0));
}


// pump characters from a keyboard buffer into a program
int keystack(int argc, char **argv)
{
	register unsigned int len, arg;
	int fd, rval = 0;

	if (argc == 1)
		return (usage(KEYSTACK_USAGE));

	// Send the data to the KEYSTACK.SYS driver (device name = 4DOSSTAK)
	if ((fd = sopen("4DOSSTAK",(O_BINARY | O_WRONLY),SH_COMPAT)) < 0)
		return (error(ERROR_BATPROC_NO_KEYSTACK,NULL));

	len = strlen(argv[1]) + 1;
	arg = (unsigned int)argv[1];

	// force a file close even on ^C
	if (setjmp(env) != -1) {
_asm {
		mov	ax,4403h	; write string to the KEYSTACK device
		mov	bx,fd
		mov	cx,len
		mov	dx,arg
		int	21h
		jc	error_exit
		xor	ax,ax
error_exit:
		mov	rval,ax
}
	}
	close(fd);

	return ((rval) ? error(rval,NULL) : 0);
}


// switch a file between .BAT and .BTM types - do nothing in BATPROC
int loadbtm(int argc, register char **argv)
{
	return 0;
}


// exit batch file or cancel nested batch files
int quit(register int argc, char **argv)
{
	// QUIT a batch file or CANCEL an entire nested batch file sequence
	//   by positioning the file pointer in each file to EOF
	for (argc = ((toupper(**argv) == 'C') ? 0 : bn); (argc <= bn); argc++)
		bframe[argc].read_offset = -1L;

	// Abort the remainder of the command line & the batch file
	return ABORT_LINE;
}


// RETURN from a GOSUB
int ret(int argc, char **argv)
{
	// check for a previous GOSUB
	if (bframe[bn].gsoffset <= 0)
		return (error(ERROR_BATPROC_BAD_RETURN,NULL));

	bframe[bn].gsoffset--;

	// return a "return from nested batchcli()" code
	return BATCH_RETURN;
}


// set cursor position
int scr(int argc, register char **argv)
{
	unsigned int row, column;

	// make sure row & column are displayable on the current screen
	if ((argc < 3) || (sscanf(argv[1],"%u %u",&row,&column) != 2) || (verify_row_col(row,column) == 0))
		return (usage(SCREEN_USAGE));

	screen(row,column);

	if (argv[3] != NULL)
		qputs(STDOUT,argv[3]);

	return 0;
}


// set screen position and print a string with the specified attribute
//   directly to the screen
int scrput(int argc, register char **argv)
{
	unsigned int row, column;
	int attrib = -1;

	// make sure row & column are displayable on the current screen
	if ((argc > 6) && (sscanf(argv[1],"%u %u",&row,&column) == 2) && (verify_row_col(row,column)))
		*argv = set_colors(argv+3,&attrib);

	if ((attrib < 0) || (*argv == NULL))
		return (usage(SCRPUT_USAGE));

	qprint(row,column,attrib,*argv);

	return 0;
}


// save the current environment (restored by ENDLOCAL or end of batch file)
int setlocal(int argc, char **argv)
{
	extern unsigned int env_size, alias_size;
	unsigned int size;

	// check for environment already saved
	if (bframe[bn].local_set != NULL)
		return (error(ERROR_BATPROC_ENV_SAVED,NULL));

	// save the environment & alias list
	size = env_size + alias_size;
	if (((bframe[bn].local_set = dosmalloc(&size)) == 0L) || ((bframe[bn].local_dir = strdup(gcdir(NULL))) == NULL))
		return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));

	_fmemmove(bframe[bn].local_set,(char far *)environment,size);

	return 0;
}


// restore the disk, directory, and environment (saved by SETLOCAL)
int endlocal(int argc, char **argv)
{
	extern unsigned int env_size, alias_size;
	register int rval;

	// check for missing SETLOCAL (environment not saved)
	if (bframe[bn].local_set == NULL)
		return (error(ERROR_BATPROC_ENV_NOT_SAVED,NULL));

	signal(SIGINT,SIG_IGN);

	// restore the original drive and directory
	if ((rval = __cd(bframe[bn].local_dir)) == 0)
		rval = drive(bframe[bn].local_dir);

	free(bframe[bn].local_dir);

	// restore the environment & alias list
	_fmemmove((char far *)environment,bframe[bn].local_set,env_size+alias_size);
	dosfree(bframe[bn].local_set);
	bframe[bn].local_set = NULL;

	return rval;
}

#endif


// wait for a keystroke; display optional message
int pause(int argc, char **argv)
{
	qputs(STDOUT,(argc == 1) ? PAUSE_PROMPT : argv[1]);

	// flush the buffer & get a key
	while (kbhit())
		getkey(NO_ECHO);

	getkey(NO_ECHO);
	crlf();

	return 0;
}


// just a comment; ignore it
int remark(int argc, char **argv)
{
	return 0;
}


// shift the batch arguments upwards (-n) or downwards (+n)
int shift(register int argc, char **argv)
{
#ifdef COMPAT_4DOS
	// get shift count
	if (argc > 1)
		argc = atoi(argv[1]);

	// make sure we don't shift past the Argv[] boundaries
	for ( ; (argc < 0) && (bframe[bn].Argv_Offset > 0); bframe[bn].Argv_Offset--, argc++)
		;

	for ( ; (argc > 0) && (bframe[bn].Argv[bframe[bn].Argv_Offset] != NULL); bframe[bn].Argv_Offset++, argc--)
		;
#else
	// make sure we don't shift past the Argv[] boundaries
	if (bframe[bn].Argv[bframe[bn].Argv_Offset] != NULL)
		bframe[bn].Argv_Offset++;
#endif

	return 0;
}


//'$Header:   P:/PVCS/MAX/STRIPMGR/PARSER.C_V   1.4   02 Jun 1997 10:46:38   BOB  $

// STRIPMGR - Strips references to memory managers from CONFIG & AUTOEXEC
//	 (c) 1990-96  Rex C. Conn & Qualitas, Inc.	All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <direct.h>
#include <dos.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <io.h>
#include <malloc.h>
#include <setjmp.h>
#include <share.h>
#include <signal.h>
#include <string.h>
#include <memory.h>
#include <process.h>

#include "stripmgr.h"
#include "commdef.h"
#include "dmalloc.h"
#include "mbparse.h"


extern int pascal filecopy(char *, char *);
extern char _far *_dstrdup(char FARDATA *);
extern char *nthptr;

int scan_config(void);
int pascal update_prestrip(char *, char *);
int create_prestrip(char *);
char *pascal unique_name(char *);
void help(void);

int _far callback_mm(CONFIGLINE FARDATA *cfg);
int _far callback_dd(CONFIGLINE FARDATA *cfg);

int flag_4dos = 0;		// "4DOS is loaded" flag
int cur_disk;			// current disk drive (A=1, B=2, etc.)
int error_level = 0;		// return code for ERRORLEVEL
int bn = -1;			// current batch nest level
int ctrlc_flag = 0; 	// abort batch file flag (set by extern ^C)
int if_flag;			// in an IF call flag
int for_flag = 0;		// in a FOR call flag
int strip_flag = 0; 	// if != 0, then remove matching args
int terse_flag = 0; 	// if != 0, don't display actions
int replace_only = 0;		// if != 0, perform replacements only
				//	 (no stripping)
int MultiBootFlag = 0;		// if != 0, /A passed & processing 1 section
int count = 0;			// number of mm's found/removed from CONFIG.SYS
int sectioncount = 0;		// number of MultiConfig sections processed

char *i_cmd_name;		// name of internal command being executed
char *b_name;			// name of batch file to be executed
char iff_flag = 0;		// if != 0, then parsing an IF/THEN/ELSE
char else_flag = 0; 	// if != 0, then parsing an IF/THEN/ELSE
char endiff_flag = 0;		// if != 0, then parsing an IF/THEN/ELSE

char cmdline[CMDBUFSIZ+16] = COPYRIGHT;
char replacement[CMDBUFSIZ+16];
char PROGRAM[] = PROGNAME;		   // program name
char striplist[80] = PROGNAME ".LST";
char MBSection[130];
char MBOwnerID;
char config_sys[] = "C:\\CONFIG.SYS";
char autoexec[] = "C:\\AUTOEXEC.BAT";

// To support INSTALL, we use the undocumented /E option.  /E takes as
// a required argument a filename.	The first line of this file (if it
// exists) may contain a command to execute on exit.  Normally, it would
// be something like
// c:\386max\install.exe /Y fname
// where fname is a text file containing the previous state of INSTALL.EXE.

// The file passed as an argument to /E contains 0 or more lines in the
// following format:
// fname flag lineno
// matchtext
// [newtext]
// fname is the name of the file affected.
// flag may be:
//	  r if the line is to be removed.
//	  c if the line is to be changed.  The new text appears on the
//	following line.
// lineno is the original line number (origin:0).  This is only used
// for processing batch files.	It's always 0 for CONFIG.SYS.
// matchtext is the line to match (case sensitive).  INSTALL will rely
// on text matching, and will use its own discrimination as to MultiConfig
// sections.

// There is always an ending line in this format:
// * retflag retval
// retflag may be:
//	  f for failure, with retval=errorlevel
//	  s for success, with retval=number of lines modified.
// In reality, we always write s for success; the f may not appear, since
// failure may occur in many ways (such as Ctrl-Break) and it's safe to
// assume that if we didn't succeed, we failed.

// Note that /E fname is an undocumented option and there are certain
// caveats:
// - It should not be used with the /t or /r options
// - It implies /s
// - The filename specified must be valid and writable
// - The caller needs to specify a /A section_name in a MultiConfig
//	 environment, and is responsible for matching up the suggested
//	 deltas in the correct section.
char *EditFileChain = NULL; // Command to chain to (read from /E fname)
char *EditChainEnv[] = {	// Environment list to preserve for INSTALL
	NULL,			// Original PATH
	NULL			// End of list
};
int Editfh = -1;		// File handle for /E file (-1 == not open)

char prestrip[] = "C:\\PRESTRIP.BAT";
char start_disk[80];	// original default disk & directory
char *start_dir[26];	// default directories at startup for C: - Z:

char ConfigEnvName[100];
char prog_name[CMDBUFSIZ];
char max_name[MAXFILENAME]; // 386MAX name to NOT delete
char *memory_managers[MAXMGRS]; // known memory managers list
char *delete_list[512]; 	// programs to watch for & delete
char *dos_args; 		// pointer to start of command line

char (_far *ExternOutput) (int, char _far *) = 0L; // Pointer to external I/O

BATCHFRAME bframe[MAXBATCH];	// batch file control structure
DOS_CONFIGS cfgdos; 	// BATPROC configuration parameters

#define MAXSETJMP	10	// Maximum levels for pushenv()/popenv()
jmp_buf _Env[MAXSETJMP];	// Saved pEnv values
jmp_buf *pEnv = NULL;		// setjmp()/longjmp() stack save
int cEnv = 0;			// Current index into _Env[]


// ^C/^BREAK handler
void _cdecl break_handler (int foo)
{
	signal(SIGINT,SIG_IGN);
	ctrlc_flag = CTRLC; 	// flag batch files to abort
	if (cEnv < 0) exit (-1);	// This should never happen
	longjmp(*pEnv,-1);		// jump to setjmp()
}

// Make space for a new jmp_buf level
void pushenv (void)
{
  if (cEnv < MAXSETJMP) {
	cEnv++;
	pEnv = &_Env[cEnv];
  } // Not over the edge yet
} // pushenv ()

// Restore previous jmp_buf
void popenv (void)
{
  if (cEnv) {
	cEnv--;
	if (cEnv >= 0) pEnv = &_Env[cEnv];
	else pEnv = NULL;
  } // Not at the bottom
} // popenv ()

// temporary critical error handler
void far int_24(unsigned int deverror, unsigned int errcode, unsigned far *devhdr)
{
	_hardresume(_HARDERR_FAIL);
}


// Local functions
void chain_inst (void);

// This is the MAIN() routine for STRIPMGR - it initializes system
//	 variables, parses the startup line, and reads CONFIG.SYS, AUTOEXEC.BAT
//	 and all its children looking for memory managers
int main(int argc, char **argv)
{
	extern void init_4dos_cmds(void);
	char *arg, *program_name, *current_path, drive_name[4];
	int i, n, fd;
	int starsect;
	void (_cdecl _interrupt _far *old_24_vector)();

	// We used to reduce _amblksiz to 64 at this point.  That's too
	// small a value and causes excessive heap fragmentation in
	// growseg().  Now we just leave it at its default of 8K.

	// test to see if 4DOS is loaded
_asm {
	mov ax,0D44Dh
	mov bx,0
	int 2Fh
	cmp ax,44DDh	// Izit 4DOS?
	je	found_4dos	// It's the real thing

	mov ax,0E44Fh	// Check for NDOS
	mov bx,0
	int 2Fh
	cmp ax,44EEh	// Izit NDOS?
	jne no_4dos 	// Jump if not
}

	// If we needed any NDOS-specific stuff, this would be the
	// place to do it (NDOS.INI, NSTART.BAT, etc.)
found_4dos:
	flag_4dos = 1;

	// if we're running 4DOS, activate the 4DOS-specific commands
	init_4dos_cmds();

no_4dos:
	cfgdos.compound = '^';          // command separator (default ^)
	cfgdos.escapechar = '';        // escape character (default ^X)

	cfgdos.switch_char = (char)get_switchar();	// default switch char

	// save the start disk & directory
	strcpy(start_disk,gcdir(NULL));

	program_name = argv[0];
	memory_managers[0] = NULL;
	delete_list[0] = NULL;
	MBSection[0] = '\0';

	// get the boot disk (where CONFIG.SYS & AUTOEXEC.BAT are located)
	if (argv[1] && stricmp(argv[1]+1,":") == 0) {
		autoexec[0] = config_sys[0] = (char)toupper(argv[1][0]);
		argv++;
	} else {
		// try the current drive
		autoexec[0] = config_sys[0] = (char)(_getdrive() + 64);
	}

	// Process command line arguments
	if (argv[1] == NULL) argv++;
	else do {
		argv++;
		i = 0;

		for (n = 0; ((arg = ntharg(*argv,n)) != NULL); n++) {

			// check for switches
			if ((i = switch_arg(arg,"?HSTXRAE",0x10|0x40|0x80)) < 0 ||
					(i & 3)) goto SYNTAX_ERR;

			// strip matching lines in CONFIG.SYS & AUTOEXEC?
			if (i & 4)
				strip_flag = 1;

			// don't display actions?
			if (i & 8)
				terse_flag = 1;

			// Use far pointer to external output routine
			// It must be a decimal long integer.
			// There can be no intervening space; /X12345678
			// works, /X 12345678 doesn't.
			if (i & 0x10)
				(long)ExternOutput = atol(&arg[2]);

			// Perform replacements only; no stripping
			if (i & 0x20)
				replace_only = strip_flag = 1;

			// Multiboot section to check/strip
			if (i & 0x40) {

				if (arg[2] == '\0')
					argv++;
				else
					*argv += 2 * (n+1);
				if (!*argv || !**argv) {
SYNTAX_ERR:
					// display signon message
					qputs(STDOUT,cmdline);
					help();
				} // Required argument missing
				// Note that the section specified may not
				// be a valid section.	We'll validate it
				// in scan_config ()...
				strcpy(MBSection,*argv);
				MultiBootFlag = 1;
				break;
			}

			// Edit file
			if (i & 0x80) {

			  if (!arg[2])	argv++;
			  else *argv += 2 * (n+1);

			  if (!*argv || !**argv) goto SYNTAX_ERR;

			  // Get the filename and read the first line.
			  if ((Editfh = sopen (*argv, (O_RDWR | O_BINARY),
							SH_COMPAT)) > 0) {
				if (getline (Editfh, cmdline, MAXARGSIZ) > 0 &&
					cmdline[0]) {
				  EditFileChain = OurStrdup (cmdline);
				  sprintf (cmdline, "PATH=%s", getenv("PATH"));
				  EditChainEnv[0] = OurStrdup (cmdline);
				} // Read first line of file
				close (Editfh);
			  } // Opened /E file

			  // Reopen the file to ensure truncation
			  if ((Editfh = sopen (*argv, O_RDWR|O_TEXT|O_TRUNC|
					O_CREAT, SH_COMPAT, S_IWRITE)) != -1)
				strip_flag = 1;
			  else goto SYNTAX_ERR;
			  cmdline[0] = '\0'; // No copyright display

			} // /E filename

		}

	} while (i != 0);

	// display signon message
	qputs(STDOUT,cmdline);

	if (*argv != NULL) {

		// Check for bogus switches
		if (**argv == cfgdos.switch_char) help();

		// if ~, don't remove specified memory manager (probably 386MAX)
		if (**argv == '~') {

			// save the name of the program to keep
			strcpy(max_name,(*argv)+1);
			argv++;

		} else
			max_name[0] = '\0';

		// check if strip list was specified on command line
		if (*argv != NULL)
			strcpy(striplist,*argv);
	}

	// if no path specified, get it from the same place as STRIPMGR.EXE
	if (path_part(striplist) == NULL)
		insert_path(striplist,striplist,program_name);

	// open the list of memory manager programs and save the entries
	if ((fd = sopen(striplist,(O_RDONLY | O_BINARY), SH_COMPAT)) < 0) {
		qprintf(STDERR,CANT_OPEN,striplist);
		return 0xFF;
	}

	for (	i = n = starsect = 0;
		((i < MAXMGRS) && (getline(fd,cmdline,MAXARGSIZ) > 0)); ) {

		// ignore comment lines (beginning with : or ;)
		// Asterisk (*) is a marker for changes to be made
		// under all circumstances.  Don't add * to the memory
		// manager list, but add its lines to delete_list.
		if ((cmdline[0]) && !strchr (":;",cmdline[0])) {

			if (cmdline[0] == '*') {
				starsect = 1;
				continue;
			} // Start of * section
			else if (starsect && isspace(cmdline[0])) {
				if (!(delete_list[n++] =
					OurStrdup (skipspace(cmdline))))
								goto NOMEM_ERR;
				continue;
			} // Add directly to delete_list
			else starsect = 0; // Not in the * section

			if ((memory_managers[i] = OurStrdup(cmdline)) == NULL) {
NOMEM_ERR:
				error(ERROR_NOT_ENOUGH_MEMORY,NULL);
				break;
			}
			i++;
		}
	}

	memory_managers[i] = NULL;
	delete_list[n] = NULL;

	close(fd);

	// save old INT 24h handler
	old_24_vector = _dos_getvect(0x24);

	// Replace INT 24h handler with our own (fails offending commands).
	// We're really concerned with what's parsed during processing,
	// not what actually happens.  We run some risk of missing a batch
	// file that needs a retry or two to open it, but tough beans...
	_harderr(int_24);

	// process CONFIG.SYS
	if (scan_config() != 0) {
		count = 0xff;
		goto MAIN_EXIT;
	} // CONFIG.SYS processing failed

	// If AUTOEXEC.BAT is missing, quietly ignore it.
	// This is not ideal behavior for a command processor if a startup
	// batch file was specified and is missing, but OK for STRIPMGR.
	if (!_access( autoexec, 00 )) {

		// (re)set %CONFIG% variable to /A value, or name selected
		//	 interactively.  If more than one section processed,
		//	 MBSection is set to null, so CONFIG won't be processed
		//	 in AUTOEXEC.
		sprintf(ConfigEnvName,"CONFIG=%.90s",MBSection);
		putenv(ConfigEnvName);

		// save the startup directory on each drive, and change to root
		for (i = 0; (i < 24); i++) {

			sprintf(drive_name,"%c:\\",i+'C');
			if ((current_path = gcdir(drive_name)) != NULL) {
				start_dir[i] = OurStrdup(current_path);
				__cd(drive_name);
			} else
				start_dir[i] = NULL;
		}


		// process AUTOEXEC.BAT & its children
		command(autoexec);
		if (Editfh == -1) crlf();

		// restore the startup directories on each drive
		for (i = 0; (i < 24); i++) {
			if (start_dir[i] != NULL) {
				__cd(start_dir[i]);
				drive(start_dir[i]);
			}
		}

	} // Startup batch file exists

	// restore the start disk
	__cd(start_disk);
	drive(start_disk);

MAIN_EXIT:
	// restore original INT 24h handler
	_dos_setvect(0x24,old_24_vector);

	// Update and close the /E file
	if (Editfh != -1) {
	  qprintf (Editfh, "* s %d\n", count); // Indicate success
	  close (Editfh);
	  // If we're chaining back to INSTALL, do it now.
	  // We need to use the C execl() function.
	  if (EditFileChain) {
		chain_inst ();
	  } // Chain to INSTALL
	} // /E file exists

	// return total number of MM's found / removed
	return count;
}


// Chain to command specified in /E file
void chain_inst (void)
{
  char *arglist[20];
  int i;

  for (i=0; i<sizeof(arglist)/sizeof(arglist[0]); i++) {
	arglist[i] = strtok (i ? NULL : EditFileChain, " \t\n");
  } // Fill arglist

  execve (arglist[0], arglist, EditChainEnv); // We shouldn't come back...

  // If the call fails, things are going to look pretty screwy.  At least
  // give 'em the magic mantra to pick up and keep going...
  qprintf (STDERR, INSTALLCHNFAIL,	arglist[0],
					arglist[0], arglist[1], arglist[2]);

} // chain_inst ()

// process batch files
int batchcli(void)
{
	register int rval;

	// display batch file name we're currently processing
	if (terse_flag == 0 && Editfh == -1)
		qprintf(STDOUT,SCANNING,bframe[bn].Batch_name);

	pushenv ();

	for (ctrlc_flag = 0; ; ) {

		rval = 0;

		// reset ^C handling
		signal(SIGINT,break_handler);

		if ((setjmp(*pEnv) == -1) || (ctrlc_flag)) {

			// close batch file just in case it's still open
			close_batch_file();

			rval = CTRLC;
			break;
		}

		// open & close batch file to avoid problems w/ missing
		//	batch files or ones spanning multiple floppy disks
		if (open_batch_file() == 0)
			break;

		// get batch file input
		rval = getline(bframe[bn].bfd,cmdline,MAXARGSIZ);

		close_batch_file();

		if (rval == 0)
			break;

		// parse & execute the command.  BATCH_RETURN is a special
		//	 code sent by functions like GOSUB/RETURN to end recursion
		if (command(cmdline) == BATCH_RETURN)
			break;
	}

	popenv ();

	// report what we did & how often we did it
	if (terse_flag == 0) {
		if (Editfh == -1) {
		  qprintf(STDOUT,((strip_flag == 0) ? STATUS_DETECT :
			 STATUS_REMOVE),bframe[bn].count,bframe[bn].Batch_name);
		  if (bn > 0)
			qprintf(STDOUT,CONTINUE_SCANNING,bframe[bn-1].Batch_name);
		} // /E file not open
		count += bframe[bn].count;
	}

	return rval;
}


// open the batch file and seek to the saved offset
int open_batch_file(void)
{
	// Don't open the file again if it's already open
	if (bframe[bn].bfd > 0) return (1);

	while ((bframe[bn].bfd = sopen(bframe[bn].Batch_name,(O_RDWR | O_BINARY),SH_COMPAT)) < 0) {

		// if missing file is on fixed disk, assume worst & give up
		if (bframe[bn].Batch_name[0] > 'B') {
			error(ERROR_BATPROC_MISSING_BATCH,bframe[bn].Batch_name);
			return 0xFF;
		}

		qprintf(STDERR,INSERT_DISK,bframe[bn].Batch_name);
		qputs(STDOUT,"Press a key to continue ...");
		getkey(ECHO);
		crlf();
	}

	// seek to saved position
	lseek(bframe[bn].bfd,bframe[bn].read_offset,SEEK_SET);

	return 1;
}


// close the current batch file
void close_batch_file(void)
{
	// if it's still open, close it
	if (bframe[bn].bfd > 0) {
		close(bframe[bn].bfd);
		bframe[bn].bfd = 0;
	}
}


// get command line from console or file
int getline(int fd, register char *line, int maxsize)
{
	register int i;
	long lseekres;

	// set write offset to current file pointer position
	lseekres = lseek (fd, 0L, SEEK_CUR);
	if (bn >= 0) bframe[bn].write_offset = lseekres;

	if ((maxsize = read(fd,line,maxsize)) <= 0)
		return 0;

	// get a line and set the file pointer to the next line
	for (i = 0; ((i < maxsize) && (line[i] != EoF)); i++) {

		if ((line[i] == '\r') || (line[i] == '\n')) {
			// end line on either CR or LF
			line[i] = '\0';
			// skip a LF following a CR
			if (line[++i] == '\n')
				i++;
			break;
		}
	}

	line[((i > maxsize) ? maxsize : i)] = '\0';

	// save the next line's position
	lseekres = lseek (fd, (long) (i - maxsize), SEEK_CUR);
	if (bn >= 0) {
	  bframe[bn].read_offset = lseekres;
	  bframe[bn].line_offset = 0;
	}

	return i;
}


// Parse the command line, perform variable expansion & redirection,
//	 and execute it.
int pascal command(register char *line)
{
	static char compound[] = "^", c;
	register char *start_line;
	char andflag, orflag;
	REDIR_IO redirect;
	int rval = 0, i;

	redirect.in = 0;		// stdin redirected flag
	redirect.out = 0;		// stdout redirected flag
	redirect.err = 0;		// stderr redirected flag
	redirect.pipe_open = 0; 	// pipe active flag
	redirect.is_piped = 0;		// pipe files created flag

	if (line == cmdline)
		bframe[bn].line_length = strlen(line);

	// turn off unsafe APPENDs
	if (_osmajor >= 4) {
_asm {
		mov ax,0B706h	; get APPEND state
		int 2Fh
		and bx,1		; test for APPEND active
		jz	no_append
		and bh,11011111b	; set /PATH:OFF flag
		mov ax,0B707h
		int 2Fh
no_append:
}
	}

	// Note that there are two possible return points here
	pushenv ();

	for ( ; ; ) {

		signal(SIGINT,break_handler);

		// check for ^C (both rval & ctrlc_flag set)
		if ((ctrlc_flag == CTRLC) || (setjmp(*pEnv) == -1)) {
			rval = CTRLC;
			break;
		}

		if (rval == ABORT_LINE)
			break;

		// get the current disk (because Netware bombs the redirection
		//	 if we get it anyplace else)
		cur_disk = _getdrive();

		start_line = line;

		// check for leading '@' (no echo)
		if (*(line = skipspace(line)) == '@') {
			line = skipspace(++line);
		}

		// adjust the line offset for IF, compound commands, pipes, etc.
		if (bframe[bn].line_length > 0) {
			i = bframe[bn].line_length - strlen(line);
			bframe[bn].line_offset += i;
			bframe[bn].line_length -= i;
		}

		start_line = strcpy(cmdline,line);

		// reset switch character (things like IF clear it)
		cfgdos.switch_char = (char)get_switchar();

		// skip null lines or those beginning with REM or a label
		if ((line = first_arg(start_line)) == NULL)
			break;

		if (*line == ':')
			break;

		if (flag_4dos) {

			if (stricmp("REM",line) == 0)
			break;

			// check for ENDIFF
			if (iff_parsing(line,start_line)) {
			// ignore ENDIFF & get next command in line
			if ((line = scan(start_line,NULL,QUOTES)) == BADQUOTES)
				break;
			continue;
			}
		}

		// do variable expansion (except for certain internal commands)
		if (((i = findcmd(start_line,0)) < 0) || (commands[i].pflag != 0)) {
			if (var_expand(start_line,0) != 0) {
				rval = ERROR_EXIT;
				break;
			}
		}

		andflag = orflag = c = 0;

		// get compound command char, pipe, conditional, or EOL
		if ((line = scan(start_line,NULL,QUOTES)) == BADQUOTES)
			break;

		// terminate command & save special char (if any)
		if (*line) {
			c = *line;
			*line++ = '\0';
		}

		// process compound command char, pipe, or conditional
		if (c == '|') {

			if (*line == '|') {
				// conditional OR (a || b)
				orflag = 1;
				line++;
			}
/* We categorically ignore all redirection */
#if 0
			else {

				// must be a pipe - try to open it
				if ((rval = open_pipe(&redirect)) != 0)
					break;

				if ((flag_4dos) && (*line == '&')) {
					// |& means pipe STDERR too
					redirect.err = dup(STDERR);
					dup2(STDOUT,STDERR);
					line++;
				}
			}
#endif /* if 0 - ignore redirection */

		} else if ((c == '&') && (*line == '&')) {
			// conditional AND (a && b)
			andflag = 1;
			line++;
		}

#if 0
		// do I/O redirection except for certain internal commands
		if ((i < 0) || (commands[i].pflag != 0)) {
			if (redir(start_line,&redirect)) {
				rval = ERROR_EXIT;
				break;
			}
		}
#endif /* if 0 */

		// strip leading & trailing white space (* stops alias expansion)
		while ((isdelim(*start_line)) || (*start_line == '*'))
			strcpy(start_line,start_line+1);

		if (flag_4dos) {
			for (i = strlen(start_line); (--i >= 0) && (isspace(start_line[i])); )
				start_line[i] = '\0';
		}

		// save pointer to start of line
		dos_args = start_line;

		rval = process_cmd(start_line,line);
		line = cmdline;

		if (setjmp(*pEnv) == -1) {
			rval = CTRLC;
			break;
		}

		// if conditional command failed, skip next command
		if (((rval != 0) && andflag) || ((rval == 0) && orflag))
			line = scan(line,NULL,QUOTES);

#if 0
		// clean up redirection & check pipes
		unredir(&redirect);
#endif /* if 0 */
	}

	popenv ();

#if 0
	// clean up redirection & delete any temporary pipe files (DOS only)
	redirect.pipe_open = 0;
	unredir(&redirect);

	killpipes(&redirect);
#endif /* if 0 */

	return rval;
}


int process_cmd(register char *start_line, char *line)
{
	static char *cmd_name, *ptr;
	int rval = 0, i;

	// save the line continuation (if any) on the stack
	line = strcpy(alloca(strlen(line)+1),line);

	if (*start_line) {

		// look for a disk change request
		if ((start_line[1] == ':') && (start_line[2] == '\0'))
		rval = drive(start_line);

		else {

		// search for an internal command
		if ((i = findcmd(start_line,0)) >= 0) {
			i_cmd_name = commands[i].cmdname;
			rval = parse_line(start_line,start_line+strlen(i_cmd_name),commands[i].func,commands[i].pflag);

		} else {

			// search for external command, & set batch name pointer
			cmd_name = first_arg(start_line);
			sscanf(cmd_name,"%80[^\"`+=]",prog_name);
			b_name = cmd_name = strcpy(alloca(strlen(prog_name)+1),prog_name);

			// if not drive, internal, COM, EXE, BTM, or BAT, or a
			//	 user-defined "executable extension", return w/error

			start_line += strlen(cmd_name);

			if ((strpbrk(cmd_name,"*?") == NULL) && ((ptr = searchpaths(cmd_name)) != NULL)) {

			cmd_name = mkfname(ptr);

			ptr = ext_part(cmd_name);

			} else
			ptr = NULLSTR;

			if ((stricmp(ptr,BAT) == 0) || ((stricmp(ptr,BTM) == 0) && (flag_4dos != 0)))
			rval = parse_line(strupr(cmd_name),start_line,batch,0xFF);
			else {
			// check for removal even if we can't find the command
			rval = parse_line(strupr(cmd_name),start_line,external,1);
			}
		}
		}
	}

	strcpy(cmdline,line);

	return rval;
}


// parse the command line into Argc, Argv format
int pascal parse_line(char *cmd_name, register char *line, int (*cmd)(int, char **), register int termflag)
{
	static int Argc;		// argument count
	static char *Argv[ARGMAX];	// argument pointers
	static char *tptr, quotechar;

	// termflag arguments are:
	//	0 - no terminators or quote stripping
	//	1 - no terminators
	//	 0xFF - parse & terminate all args

	// set command / program name
	Argv[0] = cmd_name;

	line = skipspace(line);

	// loop through arguments
	for (Argc = 1; ((Argc < ARGMAX) && (*line)); Argc++)  {

		tptr = line;		// save start of argument

		while ((*line) && (isdelim(*line) == 0)) {

			if ((flag_4dos && (*line == SINGLE_QUOTE)) || (*line == DOUBLE_QUOTE)) {
			quotechar = *line;

			// strip a single quote
			if ((*line == SINGLE_QUOTE) && (termflag))
				strcpy(line,line+1);
			else
				line++;

			// arg ends after matching close quote
			while ((*line) && (*line != quotechar)) {
				// collapse any "escaped" characters
				escape_chars(line);
				if (*line)
					line++;
			}

			// strip a single quote
			if ((*line == SINGLE_QUOTE) && (termflag))
				strcpy(line,line+1);
			else if (*line)
				line++;

			} else {

			// collapse any "escaped" characters
			escape_chars(line);
			if (*line)
				line++;
			}
		}

		// terminate if termflag == 0xFF
		if ((termflag == 0xFF) && (*line != '\0'))
			*line++ = '\0';

		// update the Argv pointer
		Argv[Argc] = tptr;

		// skip delimiters for Argv[2] onwards
		while (isdelim(*line))
			line++;
	}

	Argv[Argc] = NULL;

	// call the requested function (indirectly)
	return ((*cmd)(Argc,Argv));
}


// Check to see if program / device's directory matches that of the
// memory manager for delete_list[wDLIndex].  Return 1 if matched.
int mgr_dir (int wDLIndex, char *pszPath)
{
  char fdrive[_MAX_DRIVE], fdir[_MAX_DIR], fname[_MAX_FNAME], fext[_MAX_EXT];
  register char *psz;

  _splitpath (pszPath, fdrive, fdir, fname, fext);
  psz = delete_list[wDLIndex];
  return (!stricmp (fdir, psz + strlen (psz) + 1));

} // mgr_dir ()

// It's an external program - check if it's a defined memory manager
int external(int argc, register char **argv)
{
	extern char *nthptr;

	register char *opt, *arg;
	char prog_name[80], *fname = NULL;
	int i, j, n;

	if (for_flag)
		return 0;

	sscanf(fname_part(argv[0]),"%[^.]",prog_name);

	// if we're stripping, reopen the batch file
	if ((strip_flag) && (open_batch_file() == 0))
		return ERROR_EXIT;

	// check to see if it's included in the delete list
	for (i = 0; (delete_list[i] != NULL); i++) {

		if (stricmp(prog_name,first_arg(delete_list[i])+1) == 0) {

		// Eliminate the case where ^ is the flag and the
		// directory is not the same as that of the memory
		// manager.
		if (delete_list[i][0] == '^') {
		  if (!mgr_dir (i, argv[0])) continue;
		} // ^ flag specified; check paths

		// ask user whether to delete it (unless terse mode set)
		if (strip_flag) {

			// Build replacement line
			strcpy (replacement, dos_args); // Save original
			arg = dos_args;

			// ~ means collapse partial line
			if (delete_list[i][0] == '~') {

			// remove memory manager driver path & name & any
			//	 trailing switches (which may include = as in
			//	 QEMM 8)
			ntharg(arg,1);
			remove_switches( nthptr, 0 );

			// If undocumented syntax like
			// LH /L:n,m;n2,m2 /S=filename
			// is used, strip the remaining '=' (the undocumented
			// part).
			if (*nthptr == '=') nthptr++;
			strcpy(arg,nthptr);

			// check for options to the memory manager routine
			for (j = 1; ((opt = ntharg(delete_list[i],j)) != NULL); j++) {

				// save the delete list option name
				strcpy(prog_name,opt);

				for (n = 0; ((opt = ntharg(arg,n)) != NULL); n++) {

				if (stricmp(prog_name,opt) == 0) {
					// if matched, remove this single option
					strcpy(nthptr,skipspace(nthptr+strlen(prog_name)));
					break;
				}

				if (prog_name[0] == '*') {
					// remove everything in the line up to
					//	 and including "last option"
					if (strnicmp(prog_name+1,opt,strlen(prog_name+1)) == 0) {
					strcpy(arg,nthptr+strlen(prog_name+1));
					break;
					}
				}
				}
			}

			arg = dos_args;

			} else {
			arg = NULL;
			}

			// If we're about to delete the line and /R was
			// specified, bug out
			if ((replace_only) && (arg == NULL)) {
			break;
			}

			if (terse_flag == 0) {
			if (yesno(bframe[bn].Batch_name,
				bframe[bn].write_offset, replacement,
				 ((arg) ? cmdline : (char FARDATA *) NULL),
					NULL) != YES_CHAR)
				 break;
			}

			bframe[bn].count++;

			if (Editfh != -1) break;

			// create unique copy of the batch file
			if (bframe[bn].backup == NULL &&
			!create_prestrip (bframe[bn].Batch_name)) {

			if ((bframe[bn].backup = unique_name(bframe[bn].Batch_name)) == NULL) {
				qprintf(STDERR,CANT_MAKE_BACKUP,bframe[bn].Batch_name);
				_exit(1);
			}

			// dup the batch file and update the PRESTRIP.BAT file
			filecopy(bframe[bn].backup,bframe[bn].Batch_name);
			update_prestrip(bframe[bn].Batch_name,bframe[bn].backup);
			}

			// Write changed line, or delete line
			if (arg) {
			// remove the memory manager part of the line
			rewrite_file(bframe[bn].bfd,dos_args,bframe[bn].read_offset,bframe[bn].write_offset);
			} // Line was changed
			else {
			// ! means delete entire line
			rewrite_file(bframe[bn].bfd,NULL,bframe[bn].read_offset,bframe[bn].write_offset);
			} // Line was deleted

		} else {
			// we got a match - display a prompt
			if (terse_flag == 0)
			qprintf(STDOUT,DETECT_MESSAGE,dos_args);
			bframe[bn].count++;
		} // Display only

		break;
		}
	}

	if (strip_flag) {

		// save the new read file offset
		bframe[bn].read_offset = lseek(bframe[bn].bfd,0L,SEEK_CUR);
		bframe[bn].write_offset = bframe[bn].read_offset;

		close_batch_file();
	}

	return 0;
}


// search paths for file -- return pathname if found, NULL otherwise
char *pascal searchpaths(char *filename)
{
	static char fname[84];		// expanded filename
	register char *envptr = NULL, *extptr;
	int i;

	strcpy(fname,filename);

	// no path searches if path already specified!
	if (path_part(fname) == NULL)
		envptr = getenv("PATH");
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

				strcpy(extptr,executables[i]);

				// look for the file
				if (is_file(fname))
					return fname;
			}

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


// exiting STRIPMGR is strictly VERBOTEN!
int bye(int foo, char **fop)
{
	return ERROR_EXIT;
}


int create_prestrip (char *curfile)
{
	static char *fname = NULL;

	// create unique copy of CONFIG.SYS
	if (fname == NULL) {

		// delete any lingering PRESTRIP.BAT
		remove(prestrip);

		if ((fname = unique_name(curfile)) == NULL) {
			qprintf(STDERR,CANT_MAKE_BACKUP,curfile);
			_exit(1);
		}

		// dup CONFIG.SYS and update the PRESTRIP.BAT file
		filecopy(fname,curfile);
		update_prestrip(curfile,fname);

		return (1); // PRESTRIP.BAT has been updated

	} // fname == NULL

	return (0); // Not updated

} // create_prestrip ()


// scan CONFIG.SYS for memory managers
int scan_config(void)
{
	extern void config_free(void);
	extern CONFIGLINE FARDATA *Cfg, FARDATA *CurLine;

	SECTNAME FARDATA *CurSect = NULL;
	int fd, i = 0;

	pushenv ();

	// set ^C handling
	signal(SIGINT,break_handler);

	if (setjmp(*pEnv) == -1) {
	popenv ();
	return -1;
	} // Returned from Ctrl-Break handler

	if (terse_flag == 0 && Editfh == -1)
	qprintf(STDOUT,SCANNING,config_sys);

	count = 0;

	// test for DOS 6 Multiboot
	menu_parse(config_sys[0],1);

	// Validate the Multiboot section specified via /a.  We'll ignore it
	// if it doesn't exist.
	if (MultiBootFlag && !find_sect (MBSection)) {
	MultiBootFlag = 0;
	MBSection[0] = '\0';
	} // Bogus MBSection was specified; lose it

	do {

	if (MenuCount > 0) {

		if (MultiBootFlag != 0) {

		// only process this one section
		find_sect(MBSection);
		set_current(MBSection);
		MBOwnerID = ActiveOwner;

		} else {

		// display each section & prompt whether to process
		if (i == 0)
			CurSect = FirstSect;
		else if ((CurSect == NULL) || ((CurSect = CurSect->next) == NULL))
			break;

		find_sect(CurSect->name);
		set_current(CurSect->name);
		MBOwnerID = ActiveOwner;

		if ((terse_flag == 0) && strip_flag &&
		   (yesno (NULL, 0L, CurSect->name, CurSect->text ?
				CurSect->text : CurSect->name, PROCESS_MESSAGE)
					!= YES_CHAR))
			continue;

		// if only one section processed, treat it like a "/A name"
		if (!sectioncount || !strip_flag)
			_fstrcpy(MBSection,CurSect->name);
		else
			MBSection[0] = '\0';

		sectioncount++;

		}

	} else		// no menu - treat as a "common" block
		MBOwnerID = CommonOwner;

	// 1st pass - move memory managers from INCLUDE sections
	config_parse(0,MBOwnerID,NULL,1,callback_mm);

	// 2nd pass - move DEVICE[HIGH]=, INSTALL=, etc. from INCLUDE sections
	config_parse(0,MBOwnerID,NULL,1,callback_dd);

	if (MBSection[0]) {
		// if /A, only process one section
		if (MultiBootFlag)
			break;
//		if (terse_flag == 0)	// ?? we want to do the whole thing
//			break;
		// If we're only looking, reset for the next section
		if (!strip_flag) MBSection[0] = '\0';
	}

	} while (++i < MenuCount);

	// Write the stripped CONFIG.SYS back to disk only if changes were made
	if (count && strip_flag && Editfh == -1) {

	if ((fd = sopen(config_sys,(O_WRONLY | O_TEXT | O_TRUNC | O_CREAT),SH_COMPAT,S_IREAD | S_IWRITE)) == -1) {
	// error opening CONFIG.SYS for write
	qprintf(STDERR,CANT_OPEN,config_sys);
	popenv ();
	return -1;

	} else {

	for (CurLine = Cfg; CurLine; CurLine = CurLine->next)
	 if (!CurLine->killit) {
	  if (CurLine->newline != NULL)
		  qprintf(fd, "%s%Fs\n", CurLine->remark ? "REM " : "", CurLine->newline);
	  else
		  qprintf(fd, "%s%Fs\n", CurLine->remark ? "REM " : "", CurLine->line);
	 } // Not a deleted line

	close(fd);
	} // File opened OK
	} // Changes were made to CONFIG.SYS

	// free the copy of CONFIG.SYS in memory
	config_free();

	// report what we did & how often we did it
	if (terse_flag == 0 && Editfh == -1)
	qprintf(STDOUT,((strip_flag == 0) ? STATUS_DETECT : STATUS_REMOVE),count,config_sys);

	// If section specified or no MultiBoot, use StartupBat.
	if ((!MultiBootFlag || MBSection[0]) && StartupBat[ 0 ]) {
		_fstrcpy (autoexec, StartupBat);
	} // No MultiConfig or we got a section, and a SHELL statement was found

	popenv ();

	return 0;

} // scan_config ()


// update the PRESTRIP.BAT file
int pascal update_prestrip(char *dest, char *source)
{
	int fd;

	// create or append to PRESTRIP.BAT
	if ((fd = sopen(prestrip,(O_WRONLY | O_TEXT | O_CREAT | O_APPEND), SH_COMPAT, (S_IREAD | S_IWRITE))) < 0) {
		qprintf(STDERR,CANT_OPEN,prestrip);
		return 0xFF;
	}

	pushenv ();

	// trap ^C so we can close the file
	if (setjmp(*pEnv) != -1)
		qprintf(fd,"copy %s %s\n",source,dest);

	close(fd);

	popenv ();

	return 0;
}


// generate a unique filename by removing the extension and trying
//	 combinations from .000 to .999
char *pascal unique_name(char *source)
{
	static char target[80];
	register char *ptr;
	register int i;

	// point past the extension
	strcpy(target,source);
	ptr = strrchr(target,'.') + 1;

	for (i = 1; (i <= 999); i++) {
		sprintf(ptr,"%03d",i);
		if (is_file(target) == 0)
			return target;
	}

	return NULL;
}


// display the help screen & exit
void help(void)
{
	qputs(STDOUT,
#ifdef MULTIBOOT
		((_osmajor >= 6) && (_osmajor < 10)) ? STRIPMGR_USAGE_DOS6 :
#endif
			STRIPMGR_USAGE);
	qputs(STDOUT,STRIPMGR_USAGE_2);
	_exit(1);
}


char *OurStrdup (char *s)
// strdup() doesn't behave well when called upon to make many small
// allocations with a small heap.  Use this function for permanent
// string allocation, such as reading the config file.
{
#define OURHEAPBLOCKSIZE	2048	// Bytes to allocate for strdup heap
 static char *OurSheap = NULL;
 static int OurHeapLeft = 0;

 int len;
 char *ret;

 len = strlen (s) + 1;		// Add space for trailing NULL

 if (len > OURHEAPBLOCKSIZE)	// Izit too big to handle here?
  ret = malloc (len);		// Allocate from heap

 else {

  if (len > OurHeapLeft)	// Not enough bytes left; start a new block
   OurSheap = malloc (OurHeapLeft = OURHEAPBLOCKSIZE);
  ret = OurSheap;
  OurSheap = OurSheap + len;
  OurHeapLeft -= len;

 } // Did not exceed block size

 strcpy (ret, s);

 return (ret);

} // OurStrdup ()


// Return a dynamically allocated pointer to a copy of *pszDelete.
// If *pszDelete == '^', split up pszMgrPath and append it after
// the trailing \0 in pszDelete.
char *process_dlist (char *pszMgrPath, char *pszDelete)
{
  char fdrive[_MAX_DRIVE], fdir[_MAX_DIR], fname[_MAX_FNAME], fext[_MAX_EXT];
  char *ret;

  if (*pszDelete != '^')        return (OurStrdup (pszDelete));
  else {
	_splitpath (pszMgrPath, fdrive, fdir, fname, fext);
	ret = malloc (strlen (pszDelete) + 1 + strlen (fdir) + 1);
	strcpy (ret, pszDelete);
	strcpy (ret + strlen (pszDelete) + 1, fdir);
	return (ret);
  } // Got a ^ flag entry

} // process_dlist ()

// callback routine to check for (& optionally strip) memory managers
int _far callback_mm(CONFIGLINE FARDATA *cfg)
{
	register int i;
	char *line, *opt, *ptr, *ptrnext, *start_line;
	char driver_name[128];
	char display_line[256];
	char *dlptr;
	int j, n, length;

	_fstrcpy((line = alloca(_fstrlen(cfg->line)+1)),cfg->line);
	start_line = line;
	line = skipspace (line);
	if ((*line == '[') || (cfg->processed) || (cfg->remark))
		return 0;

	sscanf(line,"%[^ \t=]%*[ \t=]%n",driver_name,&j);

	// skip past DEVICE[high]= and INSTALL=
	// This is kinda weak, but we need to handle DEVICEHIGH=EMM386.EXE
	if ((strnicmp(driver_name,"device",6) == 0) || (stricmp(driver_name,"install") == 0)) {
		line += j;
		// save the driver name
		strcpy(driver_name,fname_part(first_arg(line)));
	}

	if ((*line == '\0') || (stricmp(driver_name,max_name) == 0))
		return 0;

	// check device or install name for a memory manager
	for (i = 0; (memory_managers[i] != NULL); i++) {

		// see if name matches one in the memory managers list
		if (stricmp(driver_name,first_arg(memory_managers[i])) == 0) {

		// check for an "only delete line if next argument matches"
		// (e.g. DOS=UMB)
		if ((opt = ntharg(memory_managers[i],1)) != NULL) {

			// Perform simple case-insensitive search
			// Make sure we match complete words only
			for (ptr = line + j, length = strlen(opt); ptr && *ptr; ) {

				while ((ptrnext = strpbrk (ptr," \t,")) == ptr)
					ptr++;
				if (!strnicmp (ptr,opt,length) &&
					(!ptrnext || (int) (ptrnext-ptr) == length))
					break;
				else
					ptr = ptrnext;
			} // check for exact case-insensitive token match

			// was there a match?
			if ((ptr == NULL) || (*ptr == '\0'))
				continue;

		} // next argument match test required

		// remove the line?
		if (strip_flag) {

			// point "line" to next argument on line
			// (e.g. change DOS=UMB,HIGH to DOS=HIGH; remove
			//	DOS=UMB altogether)
			if (opt != NULL) {

			line += j;

			// remove the test argument
			strcpy(ptr,ptr+length);

			// strip leading whitespace
			strcpy(line,skipdelims(line," \t,"));

			// strip trailing whitespace
			for (n = strlen(line); ((--n >= 0) && ((isspace(line[n])) || (line[n] == ','))); )
				line[n] = '\0';

			// If there's nothing left, clobber the line
			if (!line[0]) *start_line = '\0'; // Kill it

			} else
			*start_line = '\0';             // kill the line

			// If /R(eplace only) specified, don't change
			// the memory manager line
			if (replace_only) {
			cfg->processed = 1; // Mark as skipped
			goto add_list;
			} else {

			// ask user whether to delete it (unless
			// terse mode set)
			if (terse_flag == 0) {

				if (yesno(config_sys, 0L, cfg->line,
				((opt && *line) ? start_line :
					(char FARDATA *) NULL),
					NULL) != YES_CHAR) {
// ???					count--;
					return 0;
				} // User said 'No'

			} // Not terse
			if (!(opt && *line)) cfg->killit = 1;

			} // Not a Replace only question

			cfg->processed = 2; 	// Mark as stripped

			if (Editfh == -1) (void)create_prestrip(config_sys); // Backup CONFIG.SYS

			// save the new line
			cfg->newline = _dstrdup(start_line);

		} else { // Not stripping

			// we got a match - display a prompt
			if (terse_flag == 0) {
			if (MBSection[0])
				sprintf (dlptr = display_line, "[%s] %s",
							MBSection, line);
			else	dlptr = line;
			qprintf(STDOUT,DETECT_MESSAGE, dlptr);
			} // not terse
			cfg->processed = 1; 	// Mark it as done
//			break;			// ???

		} // end if {} / else {}

		count++;
add_list:
		// add associated programs to the delete list
		for (n = 0; (delete_list[n] != NULL); n++)
			;

		// For ^ flagged programs, we append the memory manager's
		// path after the trailing \0 for use by mgr_dir().
		for ( ; (isspace(memory_managers[++i][0])); n++)
			delete_list[n] = process_dlist (first_arg (line),
						skipspace (memory_managers[i]));

		delete_list[n] = NULL;

		// tell MBPARSE to dup this line
		return 1;

		} // Matched memory manager in the delete list

	} // for (all memory managers in delete list)

	return 0;
}

// callback routine to check for (& optionally change) device & install lines
int _far callback_dd(CONFIGLINE FARDATA *cfg)
{
	register int i;
	char *line, *start_line, *opt, *ptr;
	char driver_name[128];
	char display_line[256];
	char *dlptr;
	int j, n, rval = 0;

	_fstrcpy((line = alloca(_fstrlen(cfg->line)+1)),cfg->line);
	start_line = line;

	line = skipspace(line);

	if ((*line == '[') || (cfg->processed) || (cfg->remark))
		return 0;

	sscanf(line,"%[^ \t=]%*[ \t=]%n",driver_name,&j);

	// skip past DEVICE= and INSTALL=
	if (	!stricmp(driver_name,"device") ||
		!stricmp(driver_name,"install") ||
		!stricmp (driver_name,"shell")) {
		  line += j;
		  // save the driver name
		  strcpy(driver_name,fname_part(first_arg(line)));
	}

	// We don't want to remove FILES, BUFFERS, LASTDRIVE and FCBS
	// from CONFIG.SYS...
	// They do need to be removed from AUTOEXEC.BAT in QEMM's case.
	if (*line == '\0' ||
		cfg->ID == ID_FILES ||
		cfg->ID == ID_BUFFERS ||
		cfg->ID == ID_FCBS ||
		cfg->ID == ID_STACKS ||
		cfg->ID == ID_OTHER) // LASTDRIVE and anything else
		return 0;

cbdd_again:
	// remove the extension
	sscanf(driver_name,"%[^.]",driver_name);

	// check to see if it's included in the delete list
	for (i = 0; (delete_list[i] != NULL); i++) {

		if (stricmp(driver_name,first_arg(delete_list[i])+1) == 0) {

		// ask user whether to delete it (unless terse mode set)
		if (strip_flag) {

			// move this line
			rval = 1;

			// @ means replace first arg with next arg
			// # means replace first arg with next arg, and remove
			//	  leading switches and keywords
			// ~ means collapse partial line
			// ! means delete entire line
			// ^ means delete entire line if directory matches mmgr
			if ((delete_list[i][0] == '@') || (delete_list[i][0] == '#')) {

			if ((opt = ntharg(delete_list[i],1)) != NULL) {

				strcpy(line,line+strlen(driver_name));
				strins(line,opt);

				// if "#", then replace the argument and
				//	 delete trailing switches up until
				//	 first = sign
				if (delete_list[i][0] == '#') {

					opt = skipdelims((line + strlen(opt))," \t=");
					// Only remove switches until first =
					remove_switches( opt, 1 );

					// kludge for DOS 5
					//	 "devicehigh size=4FF c:\mouse.sys"
					// Note that the syntax is different
					// for DOS 6:
					// devicehigh /L:1,n;2,m /s=foo.sys
					if (strnicmp(opt,"size=",5) == 0) {
						for (ptr = (opt + 5); (isspace(*ptr) == 0); ptr++)
							;
						*ptr = '=';
						strcpy(opt,ptr);
					}
				}

			} // Replacement arg exists

			// go back to beginning of line, to catch things like
			//	"device=386load prog=386disk"
			strcpy (driver_name,fname_part(first_arg(line)));
			goto cbdd_again;

			} // '@': Replace first arg with next

			else if (delete_list[i][0] == '~') {

			// For MAX, we strip everything up to and
			// including prog= (~386load *prog=).
			// For others, switches begin with / and
			// end with whitespace.  QEMM 8 uses switches
			// like device=loadhi /size=xxxx progname.sys

			// remove driver path & name, and following switches
			// which may include = (as in QEMM 8)
			ntharg(line,1);
			remove_switches( nthptr, 0 );
			strcpy(line,((nthptr != NULL) ? nthptr : NULLSTR));

			// check for options to the memory manager routine
			for (j = 1; ((opt = ntharg(delete_list[i],j)) != NULL); j++) {

				strcpy(driver_name,opt);

				for (n = 0; ((opt = ntharg(line,n)) != NULL); n++) {

				if (stricmp(driver_name,opt) == 0) {
					// if matched, remove this single option
					strcpy(nthptr,skipspace(nthptr+strlen(driver_name)));
					break;
				} // Option matched

				if (driver_name[0] == '*') {
					// remove everything in the line up to
					//	 and including "last option"

					if (strnicmp(driver_name+1,opt,strlen(driver_name+1)) == 0) {
					strcpy(line,nthptr+strlen(driver_name+1));
					break;
					} // Found last option

				} // '*': Replace up to last option inclusive

				} // for (all options in command line)

			} // for (options in delete list)

			// go back to beginning of line, to catch things like
			//	"device=386load prog=386disk"
			strcpy (driver_name,fname_part(first_arg(line)));
			goto cbdd_again;

			} // '~': Collapse partial line

			else if (delete_list[i][0] == '^') {

			// If the directory differs, don't strip it
			if (!mgr_dir (i, first_arg (line))) continue;

			line = start_line = NULLSTR;

			if (replace_only) {
				 cfg->processed = 1;
				 break;
			} // /R in effect

			} // '^': Delete if same directory as memory manager

			else if (delete_list[i][0] == '!') {

			line = start_line = NULLSTR;

			if (replace_only) {
				 cfg->processed = 1;
				 break;
			} // /R in effect

			} // '!': Delete entire line

		} // Stripping

		else {

			// we got a match - display a prompt
			// If it's in a MultiBoot section, indent this line
			// by  strlen ("[section_name] ").
			if (terse_flag == 0) {
			memset (display_line, ' ', sizeof(display_line)-1);
			if (MBSection[0]) {
				display_line[strlen(MBSection)+3] = '\0';
				strcat (dlptr=display_line, line);
			} // MBSection exists
			else	dlptr = line;
			qprintf(STDOUT,DETECT_MESSAGE,dlptr);
			}
			// Not terse
			cfg->processed = 1; // Mark as done
			count++;
			break;

		} // Not stripping

		} // Driver is in delete list

	} // for (all drivers in delete list)

	if (strip_flag && rval) {

		// ask user whether to delete it (unless terse mode set)
		if ((terse_flag == 0) && (cfg->processed != 2)) {

		if (yesno(config_sys, 0L, cfg->line, start_line, NULL)
				!= YES_CHAR) {
			 // flag this line as "already processed"
			 cfg->processed = 1;
			 return (0);
		} // Answered 'N'

		} // not terse and line is not already done

		if (!start_line[0]) cfg->killit = 1;
		cfg->newline = _dstrdup(start_line);
		count++;
		cfg->processed = 2; 	// Mark for reprocessing

		// Back up CONFIG.SYS
		if (Editfh == -1) (void)create_prestrip(config_sys);

	} // strip the line

	return rval;
}


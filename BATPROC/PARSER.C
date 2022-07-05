//' $Header:   P:/PVCS/MAX/BATPROC/PARSER.C_V   1.3   02 Jun 1997 12:19:04   BOB  $

// BATPROC - batch file processor for MS-DOS 3+
//   (c) 1990-96  Rex C. Conn & Qualitas, Inc.	GNU General Public License version 3

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

#include "batproc.h"


#define IGNORE_CMD '~'
#define IGNORE_CM2 '^'
#define RUN_CMD '='
#define KILL_BATCH '$'
#define MARK_LINE '>'
#define INSERT_CMD '|'


int pascal insert_batch(char *line, char *cmd);
void init_env(void);
void dump_cmdinfo(int forcedump);


int flag_4dos = 0;		// "4DOS is loaded" flag
int cur_disk;			// current disk drive (A=1, B=2, etc.)
int error_level = 0;		// return code for ERRORLEVEL
int bn = -1;			// current batch nest level
int ctrlc_flag = 0;		// abort batch file flag (set by extern ^C)
int ctty_flag = 0;		// if != 0, then CTTY from device is active
int log_flag = 0;		// if != 0, then command logging enabled
int tsrflag = 0;		// TSR return (INT 21h 31h or INT 27h) flag
int umbflag = 0;		// UMB's allocated flag
int alias_flag = 0;		// if != 0, a TSR was loaded inside an alias
int batecho = 1;		// default to ECHO ON
int for_flag = 0;		// in a FOR call flag
int if_flag = 0;		// in another command (usually IF)
//int umbfailed;		// UMB allocation failed (ignored if umbflag)
int loadhigh;			// LH / LOADHIGH in effect
#if BPDBG
int dbgfile;			// BATPROC.LOG file handle
void heap_dump (char *msg);	// Prototype for debugging routine
#endif

unsigned int env_seg;		// environment segment - used by exec()
unsigned int psp_master;	// PSP chain pointer address

unsigned int env_size;		// size of environment
unsigned int alias_size;	// size of alias list
unsigned int prev_umb;		// # of UMB's resident at startup time

char *i_cmd_name;		// name of internal command being executed
char *b_name;			// name of batch file to be executed
char iff_flag = 0;		// if != 0, then parsing an IF/THEN/ELSE
char endiff_flag = 0;		// current ENDIFF nesting level
char else_flag = 0;		// if != 0, then waiting for an ELSE/ENDIFF
char verbose = 0;		// command line ECHO ON flag

char far *far_env;		// pointer to master environment

char AUTOSTART[] = "C:\\4START";

static char cmdline[CMDBUFSIZ+16] = COPYRIGHT;
static char PROGRAM[] = "BATPROC";              // program name
static char autoexec[] = "C:\\autoexec.bat";

static char prog_name[CMDBUFSIZ];
static char autoexec_test[CMDBUFSIZ];
static char output_file[MAXFILENAME+1];
static char loader_name[MAXFILENAME+1];
static char loader_fname[16];
static char terminate_name[MAXFILENAME+1];
static char *terminate_list[MAXTERMLIST]; // ignore these filenames & abort file
static char umb_fname[MAXFILENAME+1]; // File to use for CONFIG.SYS UMB's
static char *dos_args;		// pointer to start of command line
#define MAXINPUTFILES	16	// Maximum number of input files (f1,f2,f3,f4,...)
char *input_files[ MAXINPUTFILES + 1 ]; // NULL-terminated list of input
							// files.
char input_file[MAXFILENAME+1]; // Current input file

BATCHFRAME bframe[MAXBATCH];	// batch file control structure
DOS_CONFIGS cfgdos;		// BATPROC configuration parameters

jmp_buf env;			// setjmp()/longjmp() stack save


// ^C/^BREAK handler
void __cdecl break_handler (int foo)
{
	signal(SIGINT,SIG_IGN);
	ctrlc_flag = CTRLC;		// flag batch files to abort
	setcursor(0);			// reset normal cursor shape
	disk_reset();			// reset the disks
	longjmp(env,-1);		// jump to setjmp()
}


// This is the MAIN() routine for BATPROC - it initializes system
//   variables, parses the startup line, and if it is not a transient
//   copy, handles subsequent input forever.
int main(int argc, char **argv)
{
	extern void init_4dos_cmds(void);
	int i, fd;
	char *ptr;

	// We used to reduce _amblksiz to 64 at this point.  That's too
	// small a value and causes excessive heap fragmentation in
	// growseg().  Now we just leave it at its default of 8K.

	// disable ^C's for a bit
	signal(SIGINT,SIG_IGN);

	// set the current drive
	cur_disk = _getdrive();

	set24();			// set critical error trapping

#ifdef COMPAT_4DOS

	// test to see if 4DOS is loaded
_asm {
	mov	ax,0D44Dh
	mov	bx,0
	int	2Fh
	cmp	ax,44DDh	// Izit 4DOS?
	je	found_4dos	// It's the real thing

	mov	ax,0E44Fh	// Check for NDOS
	mov	bx,0
	int	2Fh
	cmp	ax,44EEh	// Izit NDOS?
	jne	no_4dos 	// Jump if not
}

	// If we needed any NDOS-specific stuff, this would be the
	// place to do it (NDOS.INI, NSTART.BAT, etc.)
found_4dos:
	flag_4dos = 1;

	// if we're running 4DOS, activate the 4DOS-specific commands
	init_4dos_cmds();

no_4dos:
	alias_size = 1024;

	cfgdos.compound = '^';          // command separator (default ^)
	cfgdos.escapechar = '';        // escape character (default ^X)
	cfgdos.cursor_end = -1; 	// force cursor shape initialization
#endif

	cfgdos.switch_char = (char)get_switchar();	// default switch char
	cfgdos.batecho = 1;		// batch file echo (default=on)
	cfgdos.ucase = (char)(flag_4dos == 0);

	getcursor();			// get/set the cursor shape
	getcountry();			// get the international format chars

	// display signon message
	qputs(STDOUT,cmdline);
	ver(0, NULL);
	crlf();

#if BPDBG
	qputs(STDOUT,"Debugging version of BATPROC - output goes into BATPROC.LOG\n");
	if ((dbgfile = sopen("BATPROC.LOG", (O_CREAT|O_WRONLY|O_TRUNC), SH_COMPAT, S_IREAD|S_IWRITE)) < 0)
		return (error(_doserrno,PROGRAM));
	qputs(dbgfile,"--- BATPROC debugging log ---\n");
#endif

	// Get UMB count
	prev_umb = previous_umb ();

#if BPDBG
	qprintf(dbgfile,"Previous UMB count=%u\n",prev_umb);
#endif

	if (argc < 3) {
		i_cmd_name = PROGRAM;
		return (usage(BATPROC_USAGE));
	}

	// Set up null-terminated list of unqualified input filenames
	{
		char *pszTok;
		int n;

		for (pszTok = strtok( argv[ 1 ], " \t,;" ), n = 0;
			pszTok && n < MAXINPUTFILES;
			pszTok = strtok( NULL, " \t,;" ), n++) {
			input_files[ n ] = pszTok;
		} // for all input filenames
		input_files[ n ] = NULL;

	}

	terminate_list[0] = NULL;
	terminate_name[0] = '\0';

	// if second arg == "*", don't create an output file
	strcpy(output_file,argv[2]);
	if (stricmp(argv[2],"*") != 0) {

		// if no path specified, give it the same path as BATPROC.EXE
		if (path_part(output_file) == NULL)
			strins(output_file,path_part(argv[0]));

		// create the output file
		if ((fd = sopen(output_file, (O_CREAT | O_WRONLY | O_TRUNC | O_BINARY), SH_COMPAT, S_IREAD | S_IWRITE)) < 0)
			return (error(_doserrno,output_file));

		// If UMB's existed when BATPROC started up, put'em in .OUT
		// Also create a file with one line to fool MAXIMIZE
		if (prev_umb) {
			sprintf (umb_fname, "%s%s.UMB",
				path_part(output_file), PROGRAM);
			qprintf (fd, "+(%u) %s 0 0 UMB\r\n",prev_umb,umb_fname);
			close (fd);
			if ((fd = sopen (umb_fname,
				O_CREAT|O_WRONLY|O_TRUNC|O_BINARY,
				SH_COMPAT, S_IREAD|S_IWRITE)) < 0)
			     return (error (_doserrno, umb_fname));
			qprintf (fd, "UMB allocation in CONFIG.SYS:"
				      " %d blocks allocated\r\n", prev_umb);
		}

		close(fd);
	}

	if (argv[3] != NULL) {

		// get the 386LOAD name
		strcpy(loader_name,argv[3]);
		strcpy(loader_fname,fname_part(loader_name));
		if (path_part(loader_name) == NULL)
			strins(loader_name,path_part(argv[0]));

		// open the "exclude list" and save the entries
		if ((argv[4] != NULL) && (stricmp(argv[4],"NUL") != 0)) {

			strcpy(terminate_name,argv[4]);
			if (path_part(terminate_name) == NULL)
				strins(terminate_name,path_part(argv[0]));

			if ((fd = sopen(terminate_name,(O_RDONLY | O_BINARY), SH_COMPAT)) < 0)
				return (error(_doserrno,terminate_name));

#if BPDBG
	qprintf(dbgfile,"Reading %s\n",terminate_name);
	heap_dump ("before reading MAXIMIZE.TRM");
#endif
			for (i = 0; ((i < MAXTERMLIST) && (getline(fd,cmdline,MAXARGSIZ) > 0)); ) {
				ptr = skipspace(cmdline);

				if ((*ptr) && (*ptr != ':')) {

					if ((terminate_list[i] = OurStrdup(ptr)) == NULL) {
						error(ERROR_NOT_ENOUGH_MEMORY,NULL);
						break;
					}

					strupr(terminate_list[i]);
					i++;
				}
			}

			close(fd);
			terminate_list[i] = NULL;
		}
	}

#if BPDBG
	heap_dump ("after reading MAXIMIZE.TRM");
#endif

	// load environment, init env vars, & run 4START if booting
	init_env();

	// initialize TSR trapping
	init_tsr();

#if BPDBG
	heap_dump ("before reading AUTOEXEC");
#endif

	{
		int n;

		for (n = 0; input_files[ n ]; n++) {

			// get the input filename & fully qualify it
			strcpy(input_file,input_files[ n ]);
			mkfname(input_file);
#if BPDBG
			qprintf(dbgfile,"Input filename=%s\n",input_file);
#endif

			// execute the AUTOEXEC in command line
			strcpy(cmdline,input_file);

			i = command(cmdline);

		} // for all input files

	}
#if BPDBG
	heap_dump ("after reading AUTOEXEC");
#endif

	// turn off TSR trapping
	deinit_tsr();

#if BPDBG
	qprintf(dbgfile,"--- End; returning error code %d ---\n", i);
	close (dbgfile);
#endif
	// Terminate & stay resident, keeping only PSP (see EXEC.ASM;
	// interrupt handlers remain only in PSP)
	_dos_keep(i,0x10);
}

// batch file processor
int batchcli(void)
{
	register int rval;

	// if offset == -1, we processed a CANCEL or QUIT
	for (ctrlc_flag = 0; (bframe[bn].read_offset >= 0L); ) {

		rval = 0;

		// reset ^C handling
		signal(SIGINT,break_handler);

		if ((setjmp(env) == -1) || (ctrlc_flag)) {

			// close batch file just in case it's still open
			close_batch_file();

			// Got ^C internally or from an external program.
			// Reset ^C so we come back here if the user types
			//   ^C in response to the (Y/N)? prompt
			signal(SIGINT,break_handler);

			ctrlc_flag = 0;

			qputs(STDOUT,CANCEL_BATCH_JOB);

			for ( ; ; ) {

				rval = toupper(getkey(NO_ECHO));

				if (isprint(rval)) {
					qputc(STDOUT,(char)rval);
					if ((rval == YES_CHAR) || (rval == NO_CHAR) || (rval == 'A'))
						break;
					qputc(STDOUT,BS);
				}
				honk();
			}

			crlf();

			if (rval != NO_CHAR) {
				// CANCEL ALL nested batch files
				//   by setting the file pointers to EOF
				if (rval == 'A') {
					for (rval = 0; rval <= bn; rval++)
						bframe[rval].read_offset = -1L;
				}
				rval = CTRLC;
				break;
			}
			continue;
		}

		if (_osmajor == 4) {

			// emulate the DOS 4 SHELL call
			sprintf(cmdline,"%s\r",bframe[bn].Batch_name);
_asm {
			push	ds
			pop	es
			push	di
			mov	di,offset cmdline	; ES:DI = qualified batch file name
			mov	dx,offset cmdline	; DS:DX = command line buffer
			mov	ax,1902h
			int	2Fh
			pop	di
			xor	ah,ah
			mov	rval,ax 	; result code returned in AL
}
		}

		if (rval == 0xFF)
			sscanf(cmdline+2,"%[^\r]",cmdline);
		else {

			// open & close batch file to avoid problems w/ missing
			//  batch files or ones spanning multiple floppy disks
			if (open_batch_file(O_RDONLY) == 0)
				break;

			// get file input
			rval = getline(bframe[bn].bfd,cmdline,MAXARGSIZ);

			close_batch_file();

			if (rval == 0)
				break;
		}
		rval = 0;

		// parse & execute the command.  BATCH_RETURN is a special
		//   code sent by functions like GOSUB/RETURN to end recursion
		if (command(cmdline) == BATCH_RETURN)
			break;
	}

	return rval;
}


// open the batch file and seek to the saved offset
int open_batch_file(int mode)
{
	while ((bframe[bn].bfd = sopen(bframe[bn].Batch_name,(mode | O_BINARY),SH_DENYWR)) < 0) {

		// if missing file is on fixed disk, assume worst & give up
		if (bframe[bn].Batch_name[0] > 'B') {
			error(ERROR_BATPROC_MISSING_BATCH,bframe[bn].Batch_name);
			return 0;
		}

		qprintf(STDERR,INSERT_DISK,bframe[bn].Batch_name);
		pause(1,NULL);
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

	// get STDIN input (if not redirected or CTTY'd) from egets()
	if ((fd == STDIN) && (isatty(STDIN))) {
#if BPDBG
		qprintf(dbgfile,"STDIN:%s\n",line);
#endif
		return (egets(line,maxsize,COMMAND));
	}

	// set write offset to current file pointer position
	if ((bn >= 0) && (fd != STDIN) && (fd == bframe[bn].bfd))
		bframe[bn].write_offset = lseek(fd,0L,SEEK_CUR);

	if ((maxsize = read(fd,line,maxsize)) <= 0) {
#if BPDBG
		qprintf(dbgfile,"FILE[%d]:%s\n",fd,line);
#endif
		return 0;
	}

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

#if BPDBG
	qprintf(dbgfile,"FILE[%d]:%s\n",fd,line);
#endif

	// save the next line's position (we don't need to do the SEEK with
	// batch files, because they'll be closed immediately anyway)
	if ((bn >= 0) && (fd != STDIN) && (fd == bframe[bn].bfd)) {
		bframe[bn].read_offset += i;
		bframe[bn].line_number++;
		bframe[bn].line_offset = 0;
	} else
		lseek(fd,(long)(i - maxsize),SEEK_CUR);

	return i;
}


// Parse the command line, perform alias & variable expansion & redirection,
//   and execute it.
int pascal command(register char *line)
{
	static char compound[] = "^", c;
	static int i;
	register char *start_line;
	char andflag, orflag, cr_flag, echo_flag = 0;
	REDIR_IO redirect;
	int rval = 0;

	// CRLF if not a transient shell or in a batch file, and if we're
	//   not calling command() recursively
	cr_flag = (char)((bn < 0) && (line == cmdline));

	// Update start_line and end_line, and dump if necessary
	if (bn >= 0) dump_cmdinfo (0);

#if BPDBG
	qprintf(dbgfile,"command(%s)\n",line);
#endif
	redirect.in = 0;		// stdin redirected flag
	redirect.out = 0;		// stdout redirected flag
	redirect.err = 0;		// stderr redirected flag
	redirect.pipe_open = 0; 	// pipe active flag
	redirect.is_piped = 0;		// pipe files created flag

	// echo the line if ECHO is on, and at the beginning of the line
	if ((line == cmdline) && (bn >= 0))
		bframe[bn].line_length = strlen(line);

	// turn off unsafe APPENDs
	if (_osmajor == 4) {
_asm {
		mov	ax,0B706h	; get APPEND state
		int	2Fh
		and	bx,1		; test for APPEND active
		jz	no_append
		and	bh,11011111b	; set /PATH:OFF flag
		mov	ax,0B707h
		int	2Fh
no_append:
}
	}

	// Compound and piped commands are handled in separate iterations
	for ( ; ; ) {

		// update the near environment in case something modified
		//   the master environment (like Netware)
		_fmemmove((char far *)environment,far_env,env_size);

		signal(SIGINT,break_handler);

		// check for ^C (both rval & ctrlc_flag set)
		if ((ctrlc_flag == CTRLC) || (setjmp(env) == -1)) {
			rval = CTRLC;
			break;
		}

		if ((rval == ABORT_LINE) || (rval == BATCH_RETURN))
			break;

		// stupid kludge for WordPerfect Office bug ("COMMAND /C= ...")
		while (isdelim(*line) || (*line == '='))
			line++;

		// check for leading '@' (no echo)
		if (*line == '@') {
			line = skipspace(++line);
			echo_flag = 0;
		}

		// adjust the line offset for compound commands, pipes, etc.
		if ((bn >= 0) && (bframe[bn].line_length > 0)) {
			i = bframe[bn].line_length - strlen(line);
			bframe[bn].line_offset += i;
			bframe[bn].line_length -= i;
		}

		start_line = strcpy(cmdline,line);
		cfgdos.switch_char = (char)get_switchar();

#ifdef COMPAT_4DOS
		alias_flag = 0;

		if (alias_expand(start_line) != 0) {
			rval = ERROR_EXIT;
			break;
		}
#endif

		// skip null lines or those beginning with REM or a label
		if ((line = first_arg(start_line)) == NULL)
			break;

		if (*line == ':') {
			// set IF / FOR / GOTO flag
			bframe[bn].conditional = 1;
			break;
		}

		// get the current disk (because Netware bombs the redirection
		//   if we get it anyplace else)
		cur_disk = _getdrive();

#ifdef COMPAT_4DOS
		if (stricmp("REM",line) == 0) {
			// echo the REM lines if ECHO is ON
			if (echo_flag)
				qputslf(STDOUT,start_line);
			break;
		}

		// check for IF / THEN / ELSEIF / ENDIF condition
		//   (if waiting for ENDIF or ELSEIF, ignore the command)
		if (iff_parsing(line,start_line)) {

			// skip this command - look for next compound command
			//  (ignoring pipes & conditionals)
			compound[0] = cfgdos.compound;

			if ((line = scan(start_line,compound,QUOTES)) == BADQUOTES)
				break;
			if (*line)
				line++;
			continue;
		}
#endif

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

		// do the command line echoing & command logging
		if (echo_flag)
			qputslf(STDOUT,start_line);

		// process compound command char, pipe, or conditional
		if (c == '|') {

			if (*line == '|') {
				// conditional OR (a || b)
				orflag = 1;
				line++;
			} else {

				// must be a pipe - try to open it
				if ((rval = open_pipe(&redirect)) != 0)
					break;

#ifdef COMPAT_4DOS
				if ((flag_4dos) && (*line == '&')) {
					// |& means pipe STDERR too
					redirect.err = dup(STDERR);
					dup2(STDOUT,STDERR);
					line++;
				}
#endif
			}

#ifdef COMPAT_4DOS
		} else if ((c == '&') && (*line == '&')) {
			// conditional AND (a && b)
			andflag = 1;
			line++;
#endif
		}

		// do I/O redirection except for certain internal commands
		if ((i < 0) || (commands[i].pflag != 0)) {
			if (redir(start_line,&redirect)) {
				rval = ERROR_EXIT;
				break;
			}
		}

		// strip leading & trailing white space (* stops alias expansion)
		while ((isdelim(*start_line)) || (*start_line == '*'))
			strcpy(start_line,start_line+1);

#ifdef COMPAT_4DOS
		for (i = strlen(start_line); (--i >= 0) && (isspace(start_line[i])); )
			start_line[i] = '\0';
#endif

		// save pointer to start of line
		dos_args = start_line;

		// Recalculate line length after stripping redirection
		// & spaces only if this is the first time around
		if (bn >= 0 && !bframe[bn].line_length) {
			bframe[bn].line_length = strlen (start_line);
		}

		rval = process_cmd(start_line,line);
		line = cmdline;

		if (setjmp(env) == -1) {
			rval = CTRLC;
			break;
		}

		// if conditional command failed, skip next command
		if (((rval != 0) && andflag) || ((rval == 0) && orflag))
			line = scan(line,NULL,QUOTES);

		// clean up redirection & check pipes
		unredir(&redirect);

	} // End for ()

	if (cr_flag)
		crlf();

	// clean up redirection & delete any temporary pipe files (DOS only)
	redirect.pipe_open = 0;
	unredir(&redirect);

	killpipes(&redirect);

#if BPDBG
	heap_dump("on command exit");
#endif
	return rval;
}


int process_cmd(register char *start_line, char *line)
{
	static char *cmd_name, *ptr, *eptr;
	int rval = 0, i;
	char *workstr;

#if BPDBG
	qprintf (dbgfile,"process cmd %s\n",start_line);
#endif
	// save the line continuation (if any) on the stack
	line = (*line != '\0') ? strcpy(alloca(strlen(line)+1),line) : NULLSTR;

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
		    loadhigh = 0; // Assume no LH / LOADHIGH
		    if (_osmajor >= 5) {
			if (!stricmp (cmd_name, "LH") ||
			    !stricmp (cmd_name, "LOADHIGH")) {
			    loadhigh = 1; // Emulate it
			} // MS-DOS LOADHIGH
			else if (stricmp (cmd_name, "HILOAD"))
					goto NoStripHighLoad; // Not DR DOS
			start_line =
			 skipspace ((workstr = start_line) + strlen (cmd_name));
			cmd_name = first_arg (start_line);
			// Add space skipped to column number
			bframe[bn].line_offset += (int) (start_line - workstr);
		    } // MS-DOS or DR DOS 5 or higher
NoStripHighLoad:
		    sscanf(cmd_name,"%80[^\"`+=]",prog_name);
		    b_name = cmd_name = strcpy(alloca(strlen(prog_name)+1),prog_name);

		    // if not drive, internal, COM, EXE, BTM, or BAT, or a
		    //	 user-defined "executable extension", return w/error
		    if ((strpbrk(cmd_name,"*?") == NULL) && ((ptr = searchpaths(cmd_name)) != NULL)) {

#ifdef COMPAT_4DOS
			if (flag_4dos) {
				// NOTE - DOS only allows a 127
				//   character command line, so we save the
				//   full command line to the env var CMDLINE
				strins(start_line,CMDLINE);
				addenv(start_line,0);

				start_line += strlen(CMDLINE) + strlen(cmd_name);
			} else
#endif
				start_line += strlen(cmd_name);

			cmd_name = mkfname(ptr);

#ifdef COMPAT_4DOS
			if (flag_4dos) {
				// check for an "executable extension"
				ptr = ext_part(cmd_name);
				if ((eptr = envget(ptr,0)) != NULL) {
				    sprintf(cmdline,"%.*s",(MAXARGSIZ - (strlen(eptr) + strlen(cmd_name))),start_line);
				    start_line = strins(cmdline,cmd_name);
				    strins(start_line," ");
				    b_name = cmd_name = first_arg(eptr);
				    strins(start_line,eptr+strlen(cmd_name));
				    ptr = ext_part(cmd_name);
				}
			} else
#endif
				ptr = ext_part(cmd_name);

			if ((stricmp(ptr,COM) == 0) || (stricmp(ptr,EXE) == 0))
			    rval = parse_line(strupr(cmd_name),start_line,external,1);
			else if ((stricmp(ptr,BAT) == 0)
#ifdef COMPAT_4DOS
			      || ((stricmp(ptr,BTM) == 0) && flag_4dos)
#endif
			      || (stricmp(cmd_name,input_file) == 0))
			    rval = parse_line(strupr(cmd_name),start_line,batch,0xFF);
			else {
#ifdef COMPAT_4DOS
			    // If previously set, delete CMDLINE= from the environment
			    if (flag_4dos)
				addenv(CMDLINE,0);
#endif
			    goto cmd_err;
			}

#ifdef COMPAT_4DOS
			// If previously set, delete CMDLINE= from the environment
			if (flag_4dos)
			    addenv(CMDLINE,0);
#endif
		    } else
cmd_err:
			rval = (error_level = error(ERROR_BATPROC_UNKNOWN_COMMAND,cmd_name));
		}
	    }
	}

	strcpy(cmdline,line);

	return rval;
}


// Compare autoexec_test with input_file, excluding the 3rd char from the end
// Return 0 if match, 1 if not
int input_cmp (void)
{
  unsigned int len;

  if ((len = strlen (autoexec_test)) == strlen (input_file) && len > 3) {

	autoexec_test[len-3] = input_file[len-3];

	// if disk specified, it must be the same as original AUTOEXEC
	if (autoexec_test[1] == ':') {
		if (autoexec_test[0] == autoexec[0])
			mkfname(autoexec_test);
	} else
		mkfname(autoexec_test);

	return (stricmp (input_file, autoexec_test));

  } // Lengths match
  else return (1);

} // input_cmp ()

// parse the command line into Argc, Argv format
int pascal parse_line(char *cmd_name, register char *line, int (*cmd)(int, char **), register int termflag)
{
	static int Argc;		// argument count
	static char *Argv[ARGMAX];	// argument pointers
	static char *tptr, quotechar;

	// termflag arguments are:
	//	0 - no terminators or quote stripping
	//	1 - no terminators
	//   0xFF - parse & terminate all args

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

		// We're looking for input_file = d:\dir\fname.áxt and
		// the reference being d:\dir\fname.bat.
		sprintf(autoexec_test,"%.*s",(int)(line - tptr),tptr);
		if (input_cmp () == 0) {
			strcpy(tptr,line);
			strins(tptr,input_file);
		}

		// skip delimiters for Argv[2] onwards
		while (isdelim(*line))
			line++;
	}

	Argv[Argc] = NULL;

	// call the requested function (indirectly)
	return ((*cmd)(Argc,Argv));
}


// Execute an external program (.COM or .EXE) via the DOS EXEC call
int external(int argc, register char **argv)
{
	extern char *nthptr;

	register char *arg;
	char doscmdline[130], options[128], *opts;
	unsigned int dos_start, dos_end, i, j, n, opts_found;
	unsigned int opt_flag, mark_flag, dos_error;
	int output_fd;

	// Some programs don't like trailing spaces; others require leading
	//   spaces, so we have to get a bit tricky here

#if BPDBG
	qprintf(dbgfile,"external %s\n",*argv);
#endif
	// keep leading space / no leading space
	if ((arg = argv[1]) == NULL)
		arg = NULLSTR;
	else if (isspace(arg[-1]))
		arg--;

	sprintf(doscmdline," %.126s\r",arg);

	// set length of command tail
	doscmdline[0] = (unsigned char)strlen(doscmdline+2);

	mark_flag = tsrflag = opt_flag = dos_error = 0;
	// umbflag = umbfailed = 0;

	// check the "exception list" to see if we really want to run this
	// if options are specified, they must match those on the command
	//   line for the action to be taken.

	// ~ - ignore this command on a match
	// ^ - ignore this command on a match
	// = - run this command on a match
	// $ - terminate the batch file on a match
	// | - insert next argument into the batch file _before_ current line

	for (i = 0, opt_flag = 0; (terminate_list[i] != NULL); i++) {

		arg = skipspace(terminate_list[i]);

		// check for flags
		if ((*arg == IGNORE_CMD)
		 || (*arg == IGNORE_CM2)
		 || (*arg == RUN_CMD)
		 || (*arg == KILL_BATCH)) {

			opt_flag = *arg;
			arg = skipspace(++arg);

			// check for "mark line in output file" flag
			if (*arg == MARK_LINE) {
				mark_flag = 1;
				arg = skipspace(++arg);
			}
		}

		// if the command name matches one in the terminate list,
		//   check for allowable / required options
		if (stricmp(fname_part(argv[0]),first_arg(arg)) == 0) {

			for (opts_found = 1, n = 1; ((opts = ntharg(arg,n)) != NULL); n++) {

				// check for "insert a line here if everything
				//   matched" switch (|)
				if (*opts == INSERT_CMD)
					break;

				// save the argument
				sprintf(options,"%.127s",opts);

				// argv[1] points to the remainder of the command line
				for (j = 0; ((opts = ntharg(argv[1],j)) != NULL); j++) {
					if (stricmp(options,opts) == 0)
						break;
				}

				if (opts != NULL) {
					// found the specified switch
					opts_found++;
				}
			}

			// check to see if we matched up all the args
			if (opts_found == n) {

				// if we got a match and it's an INSERT_CMD
				//   option, stuff the specified command into
				//   the batch file at the beginning of the
				//   current line.  Then rewind the batch file
				//   and execute the inserted command.
				if (*opts == INSERT_CMD) {

					arg = skipspace(++nthptr);
					if (insert_batch(arg,argv[0]) == 0) {
						bframe[bn].line_number--;
						return ABORT_LINE;
					}
				}
				break;
			}
		}

		// reset the options and mark flags
		opt_flag = mark_flag = 0;
	}

	error_level = 0;

	if (opt_flag != KILL_BATCH) {

		// is this 386LOAD?  Change it to the new version
		if (stricmp(fname_part(argv[0]),loader_fname) == 0)
			argv[0] = loader_name;

		// save amount of memory BEFORE exec call
		_dos_allocmem(0xFFF0,&dos_start);

		// call the EXEC function (DOS Int 21h 4Bh)
		if ((opt_flag != IGNORE_CMD) && (opt_flag != IGNORE_CM2))
			error_level = exec(argv[0],(char far *)doscmdline,env_seg,&dos_error);

		// save amount of memory AFTER exec call
		_dos_allocmem(0xFFF0,&dos_end);
	}

	// if an option flag specified but no mark flag, don't write it out
	if ((opt_flag == 0) || (mark_flag == 1)) {

	    umbflag = new_umbs ();

	    // if tsrflag & dos memory or XMS allocated, then we've got a TSR
	    if ((stricmp(output_file,"*") != 0) && ((mark_flag)
						 || (tsrflag)
						 || (dos_start > dos_end)
						 || (umbflag > 0)
						 // || (umbfailed > 0)
						 || (stricmp(argv[0],loader_name) == 0))) {

		if (alias_flag) {
			qputs(STDERR,WARNING);
			getkey(NO_ECHO);
			crlf();
		}

		if ((output_fd = sopen(output_file, (O_WRONLY | O_APPEND | O_BINARY), SH_COMPAT, (S_IREAD | S_IWRITE))) < 0) {
			error(_doserrno,output_file);
			return BATCH_RETURN;
		}

		if (setjmp(env) == -1) {
			// aborted with a ^C
			error_level = ctrlc_flag = CTRLC;
			return CTRLC;
		}

		// is this command a special case from the terminate list?
		if (opt_flag)
			qputc(output_fd,(char)opt_flag);

		// Terminated with INT 21h 31h or INT 27h?
		if (tsrflag)
			qputc(output_fd,'@');
		else
		if (dos_start > dos_end)	// Did we lose some DOS memory?
			qputc(output_fd, '¨');

		// encountered a FOR, GOSUB, GOTO, IF or IFF statement?
		if (bframe[bn].conditional) {
			qputc(output_fd,'!');
			bframe[bn].conditional = 0;
		}

		// inside a FOR or IF / IFF statement?
		if (for_flag)
			qputc(output_fd,'*');

		if (if_flag)
			qputc(output_fd,'#');

		// did it allocate XMS UMB memory?
		if (umbflag)
			qprintf(output_fd,"+(%d)",umbflag);

		// Did it TRY to allocate XMS UMB regions and NEVER succeeded?
		// if (umbfailed && !umbflag)
		//	qprintf (output_fd, "-(%d)", umbfailed);

		// is this 386LOAD?
		if (stricmp(argv[0],loader_name) == 0)
			qprintf(output_fd,"&(%d)",error_level);

		qprintf(output_fd,"  %s  %u  %u  %s\r\n",
				  strupr(bframe[bn].Batch_name),
				  bframe[bn].line_number-1,
				  bframe[bn].line_offset,
				  (((opt_flag == IGNORE_CMD)
				 || (opt_flag == IGNORE_CM2)) ? dos_args : prog_name));


		close(output_fd);
	    }
	}

	if (opt_flag == KILL_BATCH)
		return BATCH_RETURN;

	if (error_level == -1)
		error_level = error(dos_error,argv[0]);  // couldn't execute
	else if (error_level == -CTRLC)
		error_level = ctrlc_flag = CTRLC;	// aborted with a ^C

#if BPDBG
	heap_dump ("on exit external");
#endif
	return error_level;
}


// insert the specified args into the batch file at the beginning of the
//   current line
int pascal insert_batch(char *subst, char *cmd)
{
	unsigned int buf_size, bytes_read, bytes_written;
	int rval = 0;
	char far *fptr;
	char *arg;

#if BPDBG
	qprintf(dbgfile,"Batch subst=%s, cmd=%s\n",subst,cmd);
#endif
	// if no argument, or if we've already done an insertion here, don't
	//   do it again!
	if ((arg = first_arg(subst)) == NULL)
		return ERROR_EXIT;

	subst += strlen(arg);

	// make sure the batch file has a path
	if (path_part(arg) == NULL)
		insert_path(arg,arg,terminate_name);

	if (stricmp(arg,bframe[bn].Batch_name) == 0)
		return ERROR_EXIT;

	// request memory block (64K more or less)
	buf_size = 0xFFF0;
	if ((fptr = dosmalloc(&buf_size)) == 0L)
		return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));

	if (setjmp(env) == -1)		// ^C trapping
		rval = CTRLC;
	else {

		// open the batch file again
		if (open_batch_file(O_RDWR) == 0) {
			rval = ERROR_EXIT;
			goto insert_bye;
		}

		// go back to beginning of line
		lseek(bframe[bn].bfd,bframe[bn].write_offset,SEEK_SET);

		// read & save remainder of file
		if ((rval = _dos_read(bframe[bn].bfd,fptr,buf_size,&bytes_read)) != 0) {
			rval = error(rval,bframe[bn].Batch_name);
			goto insert_bye;
		}

		// go back to beginning of line again for insert point
		// save the new read file offset
		bframe[bn].read_offset = lseek(bframe[bn].bfd,bframe[bn].write_offset,SEEK_SET);

		// insert the specified line

		// if DOS 3.3 or above, use CALL; else use COMMAND /C
		if ((_osmajor >= 4) || ((_osmajor >= 3) && (_osminor >= 3)))
			qputs(bframe[bn].bfd,"CALL");
		else
			qputs(bframe[bn].bfd,"%COMSPEC% /C");

		// add batch file, output file path & program file path
		qprintf(bframe[bn].bfd," %s%s",arg,subst);
		qprintf(bframe[bn].bfd," %s",path_part(terminate_name));
		qprintf(bframe[bn].bfd," %s ",path_part(cmd));

		// write out the saved remainder of the file
		if (((rval = _dos_write(bframe[bn].bfd,fptr,bytes_read,&bytes_written)) != 0) || (bytes_read != bytes_written)) {
			rval = error(rval,bframe[bn].Batch_name);
			goto insert_bye;
		}

		close_batch_file();

	}

insert_bye:
	dosfree(fptr);

	return rval;
}


// initialize the environment space
void init_env(void)
{
	register char *env;
	unsigned int total_size, cur_psp, alias_start, history_start;
	char far *fenvptr;
	unsigned int far *i_ptr;
	int dos_32_flag;

	// DOS 3.2 stores the master environment in a different place
	//   than every other version!!
	dos_32_flag = ((_osmajor == 3) && (_osminor >= 20) && (_osminor < 30));

	psp_master = _psp;

	// search for the master environment by searching the PSP chain
	do {
		cur_psp = psp_master;
		i_ptr = MAKEP(cur_psp,0x16);
		psp_master = *i_ptr;
	} while (psp_master != cur_psp);

	i_ptr = MAKEP(psp_master,0x2C);
	if ((*i_ptr != 0) && (dos_32_flag == 0))
		env_seg = *i_ptr;
	else {
		i_ptr = MAKEP(psp_master-1,3);
		env_seg = psp_master + *i_ptr + 1;
	}

	i_ptr = MAKEP(env_seg-1,0x03);
	env_size = ((*i_ptr) * 16);

	// set the env ptr for BATPROC to point to the master environment
	i_ptr = MAKEP(_psp,0x2C);
	*i_ptr = psp_master;

	// point to master environment
	far_env = MAKEP(env_seg,0);

	// get default disk spec for 4START & AUTOEXEC
	autoexec[0] = AUTOSTART[0] = (((env = envget("COMSPEC",0)) != NULL) ? *env : (char)(_getdrive() + 64));

#ifdef COMPAT_4DOS

	if (flag_4dos) {

		if (flag_4dos >= 3) {

			// get the size of the alias list
			if (flag_4dos == 3) {
_asm {
			mov	ax,0D44Dh
			mov	bh,2
			int	2Fh
			cmp	ax,44DDh
			jne	not_4dos
			add	bx,26
			mov	ax,es:[bx]		; start of aliases
			mov	alias_start,ax
			add	bx,4
			mov	ax,es:[bx]		; start of history
			mov	history_start,ax
not_4dos:
}
			alias_size = ((history_start - alias_start) * 16);

			}
			else /* 4.x versions use different API AND struc */ {
_asm {
			mov	ax,0D44Dh
			mov	bh,1
			int	2Fh
			cmp	ax,44DDh
			jne	not_4dos4
			mov	ax,es:[bx+16]		; length of aliases
			mov	alias_size,ax
not_4dos4:
}
			} // 4DOS v4.x

		} // 4DOS >=3.x

	} // 4DOS != 0

	total_size = env_size + alias_size + 0x10;
#else
	total_size = env_size + 0x10;

#endif

	// allocate memory & set up near pointer to history & environment
	if ((environment = (char *)malloc(total_size)) == NULL) {
		// if insufficient memory, expire horribly
		exit(error(ERROR_NOT_ENOUGH_MEMORY,NULL));
	}

#ifdef COMPAT_4DOS
	alias_list = environment + env_size;	// Set up our local alias list
#endif

	memset(environment,'\0',total_size);

	// copy the inherited environment
	fenvptr = MAKEP(env_seg,0);

	// copy the master environment
	_fmemmove((char far *)environment,fenvptr,env_size);

#ifdef COMPAT_4DOS
	// execute 4START.BAT / 4START.BTM
	if ((flag_4dos) && ((env = searchpaths(AUTOSTART)) != NULL))
		command(env);
#endif
}

char *OurStrdup (char *s)
// strdup() doesn't behave well when called upon to make many small
// allocations with a small heap.  This is meant to allocate permanent
// string copies for reading in the config file.
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

#if BPDBG
/* Reports on the status returned by _heapwalk, _heapset, or _heapchk */
void heapstat( int status )
{
    qprintf(dbgfile,"\n  Heap stat: " );
    switch( status )
    {
	case _HEAPOK:
	    qprintf(dbgfile,"OK\n" );
	    break;
	case _HEAPEMPTY:
	    qprintf(dbgfile,"OK - empty\n" );
	    break;
	case _HEAPEND:
	    qprintf(dbgfile,"OK - end of heap\n" );
	    break;
	case _HEAPBADPTR:
	    qprintf(dbgfile,"ERR- bad heap ptr\n" );
	    break;
	case _HEAPBADBEGIN:
	    qprintf(dbgfile,"ERR- bad heap start\n" );
	    break;
	case _HEAPBADNODE:
	    qprintf(dbgfile,"ERR- bad node\n" );
	    break;
    }
}

void heap_dump (char *msg)
// Walk heap and dump it
{

    struct _heapinfo hi;
    int heapstatus;

    /* Walk through entries, displaying results and checking free blocks. */
    qprintf(dbgfile,"Heap dump %s:",msg);
    hi._pentry = NULL;
    while( (heapstatus = _heapwalk( &hi )) == _HEAPOK )
    {
	qprintf(dbgfile, "\t%s block at %08lx of size %u",
		hi._useflag == _USEDENTRY ? "USED" : "FREE",
		(unsigned long) hi._pentry,
		hi._size );
    }
    heapstat( heapstatus );

}
#endif

void dump_cmdinfo (int forcedump)
{
	int output_fd;
	unsigned register int cLine = bframe[bn].line_number-1;
	unsigned int startcomp = bframe[bn].start_line;
	unsigned int endcomp = bframe[bn].end_line+1;

	if (startcomp == 0xffff) {

	  if (!forcedump) {
	    bframe[bn].start_line = bframe[bn].end_line = cLine;
	  } // We're not ignoring current line

	} // New range
	else if (!forcedump && cLine == endcomp) {

	  bframe[bn].end_line = cLine;

	} // Update end of contiguous range
	else if (forcedump || cLine > endcomp || cLine < startcomp) {

	  if (!stricmp (output_file, "*")) return;

	  if ((output_fd = sopen(output_file, (O_WRONLY | O_APPEND | O_BINARY),
				SH_COMPAT, (S_IREAD | S_IWRITE))) < 0) {
		error(_doserrno,output_file);
		return;
	  }

	  qprintf(output_fd,"%% %s  %u %u\r\n",
			  strupr(bframe[bn].Batch_name),
			  startcomp,
			  bframe[bn].end_line);

	  close(output_fd);

	  bframe[bn].start_line = bframe[bn].end_line = cLine; // Restart

	} // Dump old range and restart

} // dump_cmdinfo ()


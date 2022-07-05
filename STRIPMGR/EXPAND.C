// EXPAND.C
//   Copyright (c) 1990  Rex C. Conn  GNU General Public License version 3.
//
//   perform redirection
//   expand variables from the environment


#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <dos.h>
#include <errno.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>
#include <share.h>
#include <string.h>

#include "stripmgr.h"


extern int bn;				// current batch file number
extern int flag_4dos;

char *nthptr;				// pointer to nth arg in line

static char i_pipe[32];
static char o_pipe[32];
static char *in_pipe = i_pipe;		// current input pipe file
static char *out_pipe = o_pipe; 	// current output pipe file


// duplicate a file handle, and close the old handle
void pascal dup_handle(unsigned int old_fd, unsigned int new_fd)
{
	dup2(old_fd,new_fd);
	close(old_fd);
}


// Delete any temporary pipe files
void pascal killpipes(REDIR_IO *redirect)
{
	if (redirect->is_piped) {
		unlink(in_pipe);
		unlink(out_pipe);
		redirect->is_piped = 0;
	}
}


// Perform redirection. The command line will be terminated wherever
//   the first < or > is found.
int pascal redir(char *startline, REDIR_IO *redirect)
{
	static char delims[] = "%79[^  \t<>;,\"`+=[]]";
	register char *line, *arg;
	char fname[MAXFILENAME+1], output, append, nc;
	int fd, mode;

	delims[6] = cfgdos.switch_char;
	nc = cfgdos.noclobber;

	for (;;) {

		// check for I/O redirection (< or >)
		if ((line = scan(startline,"<>",QUOTES)) == BADQUOTES)
			return ERROR_EXIT;
		if (*line == '\0')
			return 0;
		arg = line++;		// save redirection character

		output = append = 0;

		if (*arg == '>') {

			// set "redirecting output" flag
			output = 1;

			if (*line == '>') {
				// append to output
				append = 1;
				line++;
			}

			if ((flag_4dos) && (*line == '&')) {
				// redirect stderr too (or only)
				if (*(++line) == '>') {
					line++;
					output = 2;
				} else
					output = 3;
			}

			// already have output redirection for this command?
			if ((redirect->out && (output & 1)) || (redirect->err && (output & 2)))
				return (error(ERROR_ALREADY_ASSIGNED,arg));

			if ((flag_4dos) && (*line == '!')) {
				// override NOCLOBBER
				nc = 0;
				line++;
			}

		} else {
			// already have input redirection for this command?
			if (redirect->in)
				return (error(ERROR_ALREADY_ASSIGNED,arg));
		}

		// get the file name
		line = skipspace(line);
		sscanf(line,delims,fname);

		// now rub it out
		strcpy(arg,line+strlen(fname));

		if (output) {

			// redirecting output (stdout)
			mode = O_RDWR | O_TEXT | ((append) ? O_APPEND : O_TRUNC);

			if ((is_dev(fname) == 0) && (nc)) {
				// set NOCLOBBER conditions
				if (!append)
					mode |= (O_CREAT | O_EXCL);
			} else
				mode |= O_CREAT;

			if ((fd = sopen(fname, mode, SH_COMPAT, (S_IREAD | S_IWRITE))) < 0)
				return (error((errno == EEXIST) ? ERROR_FILE_EXISTS : _doserrno, fname));

			if (append)
				lseek(fd,0L,SEEK_END);

			if (output & 1) {
				redirect->out = dup(STDOUT);
				dup2(fd,1);
			}

			if ((flag_4dos) && (output & 2)) {
				// redirecting stderr
				redirect->err = dup(STDERR);
				dup2(fd,2);
			}

			close(fd);

		} else {

			// redirecting input (stdin)
			if ((fd = sopen(fname,(O_RDONLY | O_TEXT),SH_COMPAT)) < 0)
				return (error(_doserrno,fname));

			redirect->in = dup(STDIN);
			dup_handle(fd,STDIN);

		}
	}
}


// Reset all redirection: stdin = stdout = stderr = console.
//   if DOS & a pipe is open, close it and reopen stdin to the pipe.
void pascal unredir(REDIR_IO *redirect)
{
	register int fd;
	register char *tmp;

	if (redirect->in) {
		dup_handle(redirect->in,STDIN);
		redirect->in = 0;
	}

	if (redirect->out) {
		dup_handle(redirect->out,STDOUT);
		redirect->out = 0;
	}

	if ((flag_4dos) && (redirect->err)) {
		dup_handle(redirect->err,STDERR);
		redirect->err = 0;
	}

	if (redirect->pipe_open) {

		redirect->pipe_open = 0;

		// exchange input and output names
		tmp = in_pipe;
		in_pipe = out_pipe;
		out_pipe = tmp;

		if ((fd = sopen(in_pipe,(O_RDONLY | O_TEXT),SH_COMPAT)) < 0)
			error(_doserrno,in_pipe);
		else {
			redirect->in = dup(STDIN);
			dup_handle(fd,STDIN);
		}
	}
}


// Set up output side of a pipe.
int pascal open_pipe(REDIR_IO *redirect)
{
	extern char autoexec[];
	register char *env;
	register int fd;

	// look for TMP disk area defined in environment, or default to boot
	if ((env = getenv(TEMP_DISK)) != NULL) {
		strcpy(out_pipe,env);
		strcpy(in_pipe,env);
	} else {
		// this peculiar kludge is required for Novell Netware
		memmove(in_pipe,"_:/\000_______.___",16);
		memmove(out_pipe,"_:/\000_______.___",16);
		*in_pipe = *out_pipe = autoexec[0];
		in_pipe[3] = out_pipe[3] = '\0';
	}

	mkdirname(out_pipe,(out_pipe == o_pipe) ? "p.1$$" : "p.2$$");
	mkdirname(in_pipe,(in_pipe == i_pipe) ? "p.2$$" : "p.1$$");

	if ((fd = sopen(out_pipe, (O_CREAT | O_WRONLY | O_TRUNC | O_TEXT), SH_COMPAT, (S_IREAD | S_IWRITE))) < 0)
		return (error(_doserrno,out_pipe));

	// set the "pipe active" flags
	redirect->pipe_open = redirect->is_piped = 1;

	// save STDOUT & point it to the pipe
	redirect->out = dup(STDOUT);
	dup_handle(fd,STDOUT);

	return 0;
}


// expand shell variables
int pascal var_expand(char *start_line, int recurse_flag)
{
	extern int error_level, for_var;
	extern char MBSection[];

	static int loop_ctr = 0;
	register char *vline, *var;
	char buffer[MAXARGSIZ];
	char *line, *func = NULL;
	int i, n;

	for (line = start_line; ; ) {

		// get the end of the first command & its args
		vline = scan(start_line,NULL,QUOTES);
		line = scan(line,"%",BACK_QUOTE);
		if ((line == BADQUOTES) || (vline == BADQUOTES))
			return ERROR_EXIT;

		// only do variable substitution for first command on line
		if ((*line == '\0') || (line >= vline))
			return 0;

		// strip the %
		vline = strcpy(line,line+1);
		if (*vline == '%') {
			// skip %% after stripping first one
			line++;
			continue;
		}

		// process the environment (or internal) variables
		if ((flag_4dos) && (*vline == '[')) {

			// check for explicit definition
			strcpy(vline,vline+1);

			for ( ; ((*vline) && (*vline != ']')); vline++)
				;

			if (*vline)
				strcpy(vline,vline+1);

		} else if ((bn >= 0) && (isdigit(*vline))) {
			// parse normal batch file variables (%5)
			//   or %n& variables
			if (*(++vline) == '&')
				vline++;
		} else if ((bn >= 0) && (*vline == '&')) {
			// parse batch file %& variables
			vline++;
		} else if ((flag_4dos) && ((*vline == '#') || (*vline == '?'))) {
			// %# evaluates to number of args in batch file
			// %? evaluates to exit code of last external program
			vline++;
		} else {

			// parse environment variables (%var%)
			for ( ; ((isalnum(*vline)) || (*vline == '_') || (*vline == '$')); vline++) {

				// kludge for COMMAND.COM compatibility:
				//   FOR variables may have a max length of 1!
				if ((vline == (line + 1)) && (toupper(for_var) == toupper(line[0])))
					break;

			}

			if (*vline == '%')      // skip a trailing '%'
				strcpy(vline,vline+1);

		}

		var = NULL;

		sprintf(buffer,"%.*s",(int)(vline - line),line);

		// collapse the variable spec
		strcpy(line,vline);

		// first, try expanding batch vars (%n, %&, %n&, and %#);
		if (bn >= 0) {

		    // expand %n, %&, and %n&
		    if ((isdigit(buffer[0])) || (buffer[0] == '&')) {

			// %& defaults to %1&
			i = ((buffer[0] == '&') ? 1 : atoi(buffer)) + bframe[bn].Argv_Offset;
			for (vline = buffer; isdigit(*vline); vline++)
				;

			for (n = 0; (n < i) && ((var = bframe[bn].Argv[n]) != NULL); n++)
				;

			if ((flag_4dos) && (*vline == '&')) {

				// get command tail
				for (buffer[0] = '\0'; bframe[bn].Argv[n] != NULL; n++) {
					if (buffer[0])
						strcat(buffer," ");
					strcat(buffer,bframe[bn].Argv[n]);
				}
				var = buffer;
			} else
				var = bframe[bn].Argv[n];
		    }
		}

		// check for an environment variable
		if (var == NULL)
			var = getenv(strupr(buffer));

		// insert the variable
		if (var != NULL) {
			if ((strlen(start_line) + strlen(var)) >= MAXARGSIZ)
				return (error(ERROR_BATPROC_COMMAND_TOO_LONG,NULL));
			strins(line,var);
		}
	}
}


// collapse escape characters
void pascal escape_chars(register char *line)
{
	extern int flag_4dos;

	if ((flag_4dos) && (*line == cfgdos.escapechar)) {

		strcpy(line,line+1);

		// convert C-type escape chars
		switch (*line) {
		case 'b':       // backspace
			*line = '\b';
			break;
		case 'e':       // ESC
			*line = '\033';
			break;
		case 'f':       // formfeed
			*line = '\f';
			break;
		case 'n':       // line feed
			*line = '\n';
			break;
		case 'r':       // carriage return
			*line = '\r';
		}
	}
}


// return the first argument in the line
char *pascal first_arg(char *line)
{
	return (ntharg(line,0));
}


// NTHARG returns the nth argument in the command line
//   (parsing by whitespace & switches)
char *pascal ntharg(register char *line, int index)
{
	static char buf[MAXARGSIZ+1];
	static char delims[] = "  \t,;";
	register char *ptr;

	delims[0] = cfgdos.switch_char;

	for (nthptr = NULL; (index >= 0); index--) {

		// find start of arg[i]
		while (isdelim(*line))
			line++;

		if ((line == NULL) || (*line == '\0'))
			return NULL;

		// search for next delimiter or switch character
		if ((ptr = scan((*line == cfgdos.switch_char) ? line + 1 : line,delims,QUOTES)) == BADQUOTES)
			return NULL;

		if (index == 0) {
			// this is the argument I want - copy it & return
			nthptr = line;
			sprintf(buf,"%.*s",(unsigned int)(ptr-line),line);
			return buf;
		}
		line = ptr;
	}
}


// Find the first character in LINE that is also in SEARCH.
//   Return a pointer to the matched character or EOS if no match
//   is found.	If SEARCH == NULL, just look for end of line ((which
//   could be a pipe, compound command character, or conditional)
char *pascal scan(register char *line, char *search, char *quotestr)
{
	register char quotechar;

	if (line != NULL) {

	    while (*line != '\0') {

		if (strchr(quotestr,*line) != NULL) {

			// ignore characters within quotes
			quotechar = *line;
			while (*(++line) != quotechar) {
				if (flag_4dos) {
					if (*line == cfgdos.escapechar)
						line++;
					if (!*line) {
						error(ERROR_BATPROC_NO_CLOSE_QUOTE,NULL);
						return BADQUOTES;
					}
				}
			}

		} else {

			// skip escaped characters
			if ((flag_4dos) && (*line == cfgdos.escapechar))
				line++;
			else if (search == NULL) {
				// check for pipes, compounds, or conditionals
				if ((*line == '|') || (*line == cfgdos.compound) || ((*line == '&') && (strnicmp(line-1," && ",4) == 0)))
					break;
			} else if (strchr(search,*line) != NULL)
				break;
		}

		line++;
	    }
	}

	return line;
}


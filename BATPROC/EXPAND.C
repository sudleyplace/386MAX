// EXPAND.C
//   Copyright (c) 1990  Rex C. Conn  All rights reserved.
//
//   expand command aliases (if 4DOS)
//   expand variables from the environment
//   perform redirection


#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <dos.h>
#include <errno.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>
#include <setjmp.h>
#include <share.h>
#include <string.h>

#include "batproc.h"


extern jmp_buf env;			// save table for ^C

extern int bn;				// current batch file number
extern int flag_4dos;

char *histlist; 			// pointer to base of history list
char *Hptr = NULL;			// pointer into history list
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
	char fname[CMDBUFSIZ], output, append, nc;
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

#ifdef COMPAT_4DOS
			if (*line == '&') {
				// redirect stderr too (or only)
				if (*(++line) == '>') {
					line++;
					output = 2;
				} else
					output = 3;
			}
#endif

			// already have output redirection for this command?
			if ((redirect->out && (output & 1)) || (redirect->err && (output & 2)))
				return (error(ERROR_ALREADY_ASSIGNED,arg));

#ifdef COMPAT_4DOS
			if (*line == '!') {     // override NOCLOBBER
				nc = 0;
				line++;
			}
#endif

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

#ifdef COMPAT_4DOS
			if (output & 2) {	// redirecting stderr
				redirect->err = dup(STDERR);
				dup2(fd,2);
			}
#endif

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

#ifdef COMPAT_4DOS
	if (redirect->err) {
		dup_handle(redirect->err,STDERR);
		redirect->err = 0;
	}
#endif

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
	extern char AUTOSTART[];
	register char *env;
	register int fd;

	// look for TMP disk area defined in environment, or default to boot
	if ((env = envget(TEMP_DISK,0)) != NULL) {
		strcpy(out_pipe,env);
		strcpy(in_pipe,env);
	} else {
		// this peculiar kludge is required for Novell Netware
		memmove(in_pipe,"_:/\000_______.___",16);
		memmove(out_pipe,"_:/\000_______.___",16);
		*in_pipe = *out_pipe = AUTOSTART[0];
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


#ifdef COMPAT_4DOS

// Expand aliases (first argument on the command line)
int pascal alias_expand(register char *line)
{
	extern int alias_flag;
	static char delims[] = " \"`<>=+[]|";
	register char *cptr;
	char aliasline[CMDBUFSIZ];
	char *arg, *eol, eolchar;
	int alen, argnum, loopctr, vars_exist;

	if (flag_4dos == 0)
		return 0;

	// beware of aliases with no whitespace before ^ or |
	delims[0] = cfgdos.compound;
	for (loopctr = 0; ; loopctr++) {

		vars_exist = 0;

		// parse the first command in the line
		if ((arg = first_arg(line)) == NULL)
			return 0;
		if (arg == BADQUOTES)
			return ERROR_EXIT;

		if ((cptr = strpbrk(arg,delims)) != NULL)
			*cptr = '\0';

		// search the environment for the alias
		if ((cptr = envget(arg,1)) == NULL)
			return 0;

		// look for alias loops
		if (loopctr > 10)
			return (error(ERROR_BATPROC_ALIAS_LOOP,NULL));

		alen = strlen(arg);
		strcpy(aliasline,cptr);

		// get the end of the first command & its args
		if ((eol = scan(line,NULL,QUOTES)) == BADQUOTES)
			return ERROR_EXIT;
		eolchar = *eol;
		*eol = '\0';

		// process alias arguments
		for (cptr = aliasline; *cptr; ) {

			if ((cptr = scan(cptr,"%",BACK_QUOTE)) == BADQUOTES)
				return ERROR_EXIT;

			if ((*cptr == '\0') || (cptr[1] == '\0'))
				break;

			if ((isdigit(cptr[1]) == 0) && (cptr[1] != '&')) {
				cptr++;
				continue;
			} else
				strcpy(cptr,cptr+1);

			// %& defaults to %1&
			argnum = ((*cptr == '&') ? 1 : atoi(cptr));
			while (isdigit(*cptr))
				strcpy(cptr,cptr+1);

			// flag highest arg processed
			if (argnum > vars_exist)
				vars_exist = argnum;

			// get matching argument from command line
			arg = ntharg(line,argnum);
			if (*cptr == '&') {
				// get command tail
				strcpy(cptr,cptr+1);
				arg = nthptr;
				vars_exist = 0xFF;
			}

			if (arg == NULL)
				continue;

			// expand alias line
			if ((strlen(aliasline) + strlen(arg)) >= MAXARGSIZ)
				return (error(ERROR_BATPROC_COMMAND_TOO_LONG,NULL));
			strins(cptr,arg);

			// don't try to expand the argument we just added
			cptr += strlen(arg);
		}
		*eol = eolchar;

		// check for overlength line
		if ((strlen(line) + strlen(aliasline)) >= MAXARGSIZ)
			return (error(ERROR_BATPROC_COMMAND_TOO_LONG,NULL));

		// if alias variables exist, delete command line until
		//   highest referenced command, compound command char, pipe,
		//   conditional, or EOL); else just collapse the alias name
		if (vars_exist) {
			ntharg(line,vars_exist+1);
			arg = scan(line,NULL,QUOTES);
			if ((nthptr != NULL) && (arg > nthptr)) {
				arg = nthptr;
				// preserve original whitespace (or lack)
				if (isspace(arg[-1]))
					arg--;
			}
		} else
			arg = line + alen;
		strcpy(line,arg);

		// insert the alias
		strins(line,aliasline);

		// set the "alias defined" flag
		alias_flag = 1;
	}
}

#endif


// expand shell variables
int pascal var_expand(char *start_line, int recurse_flag)
{
	extern int error_level, for_var;
#ifdef COMPAT_4DOS
	extern ANSI_COLORS colors[];
#endif

	static int loop_ctr = 0;
	register char *vline, *var;
	char buffer[MAXARGSIZ];
	char *line, *func = NULL, *start_var;
	int i, n, length;
	struct dosdate_t d_date;

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

		if ((flag_4dos) && (*vline == '@')) {
#ifdef COMPAT_4DOS

			// process the string functions (fullname, path,
			//   name, ext, substr)

			for (func = ++vline; ((*vline) && (*vline != '[')); vline++)
				;

			start_var = vline;

			// save args & call var_expand() recursively
			for (var = ++vline; ; var++, vline++) {

				// must have an opening & closing bracket!
				if ((*(var = scan(var,"]",BACK_QUOTE)) == '\0') || (*start_var != '['))
					return (error(ERROR_BATPROC_BAD_SYNTAX,line));

				// check for nested variable functions
				if ((vline = scan(vline,"[",BACK_QUOTE)) > var)
					break;
			}
			*start_var++ = '\0';
			vline = (*var) ? var + 1 : var;

			sprintf(buffer,"%.*s",(int)(var - start_var),start_var);

			// make sure we don't go "infinite loopy" here
			if (++loop_ctr > 4) {
				loop_ctr = 0;
				return (error(ERROR_BATPROC_VARIABLE_LOOP,NULL));
			}

			// set "recurse_flag" so we don't do alias expansion
			n = var_expand(buffer,1);
			loop_ctr = 0;
			if (n == ERROR_EXIT)
				return ERROR_EXIT;

			var = buffer;

			if (stricmp(func,SEARCH) == 0) {
				// search for filename (including COM,EXE,BAT,BTM)
				if ((var = searchpaths(var)) != NULL)
				    filecase(mkfname(var));
			} else if (stricmp(func,FULLNAME) == 0) {
				// return fully qualified filename
				filecase(mkfname(var));
			} else if (stricmp(func,NAME) == 0) {
				// filename
				if ((var = fname_part(var)) != NULL)
					sscanf(var,"%[^.]",var);
			} else if (stricmp(func,PATH_VAR) == 0) {
				// path part
				var = path_part(var);
			} else if (stricmp(func,EXTENSION) == 0) {
				// extension
				if (*(var = ext_part(var)) == '.')
					var++;
			} else if (stricmp(func,SUBSTR) == 0) {

				// substring - check for valid syntax
				var = scan(var,",",QUOTES);
				if (*var != ',')
					return (error(ERROR_BATPROC_BAD_SYNTAX,buffer));

				*var++ = '\0';

				if (sscanf(var,"%d,%d",&i,&n) != 2)
					return (error(ERROR_BATPROC_BAD_SYNTAX,buffer));

				var = buffer;
				length = strlen(var);

				if (n > 0)
					var += ((length > i) ? i : length);
				else {
					n = -n;
					length--;
					var += ((length > i) ? length - i : 0);
				}
				sprintf(var,"%.*s",n,var);

			} else if (stricmp(func,FILE_LINE) == 0) {

				// get line from file - check for valid syntax
				if (sscanf(var,"%*[^,],%d",&i) != 1)
					return (error(ERROR_BATPROC_BAD_SYNTAX,buffer));

				sscanf(var,"%[^,]",var);

				// read a line from the file
				if ((n = sopen(var,(O_RDONLY | O_BINARY),SH_DENYWR)) < 0)
					return (error(_doserrno,var));

				if (setjmp(env) != -1) {

					for ( ; (i >= 0); i--) {
						buffer[0] = '\0';
						if (getline(n,buffer,MAXARGSIZ) <= 0)
							break;
					}

				}
				close(n);

			} else if (stricmp(func,EVAL) == 0) {

				// calculate simple algebraic expressions
				if (evaluate(var) != 0)
					return ERROR_EXIT;

			} else if (stricmp(func,INDEX) == 0) {

				// return the index of the first part of the
				//   source string that includes the search
				//   substring
				var = scan(var,",",QUOTES);
				if (*var != ',')
					return (error(ERROR_BATPROC_BAD_SYNTAX,buffer));
				*var++ = '\0';

				// Perform simple case-insensitive search
				for (i = 0, n = strlen(var); ((buffer[i]) && (strnicmp(buffer+i,var,n) != 0)); i++)
					;
				if (buffer[i] == '\0')
					i = -1;
				sprintf(buffer,"%d",i);
				var = buffer;

			} else if (stricmp(func,UPPER) == 0) {
				// shift string to upper case
				strupr(var);

			} else if (stricmp(func,LOWER) == 0) {
				// shift string to lower case
				strlwr(var);

			} else if (stricmp(func,LENGTH) == 0) {
				// length of string
				sprintf(var,"%u",strlen(var));
			} else
				var = NULL;		// unknown function

			// collapse the function name & args
			strcpy(line,vline);
#endif

		} else {

			// process the environment (or internal) variables
			if (*vline == '[') {
#ifdef COMPAT_4DOS
				// check for explicit definition
				strcpy(vline,vline+1);

				for ( ; ((*vline) && (*vline != ']')); vline++)
					;

				if (*vline)
					strcpy(vline,vline+1);
#endif
			} else if ((bn >= 0) && (isdigit(*vline))) {
				// parse normal batch file variables (%5)
				//   or %n& variables
				if (*(++vline) == '&')
					vline++;
			} else if ((bn >= 0) && (*vline == '&')) {
				// parse batch file %& variables
				vline++;
#ifdef COMPAT_4DOS
			} else if ((*vline == '#') || (*vline == '?')) {
				// %# evaluates to number of args in batch file
				// %? evaluates to exit code of last external program
				vline++;
#endif
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
			//   then check for internal variables
			if (bn >= 0) {

			    // expand %n, %&, and %n&
			    if ((isdigit(buffer[0])) || (buffer[0] == '&')) {

				// %& defaults to %1&
				i = ((buffer[0] == '&') ? 1 : atoi(buffer)) + bframe[bn].Argv_Offset;
				for (vline = buffer; isdigit(*vline); vline++)
					;

				for (n = 0; (n < i) && ((var = bframe[bn].Argv[n]) != NULL); n++)
					;

#ifdef COMPAT_4DOS
				if (*vline == '&') {

					// get command tail
					for (buffer[0] = '\0'; bframe[bn].Argv[n] != NULL; n++) {
						if (buffer[0])
							strcat(buffer," ");
						strcat(buffer,bframe[bn].Argv[n]);
					}
					var = buffer;
				} else
#endif
					var = bframe[bn].Argv[n];

#ifdef COMPAT_4DOS
			    } else if (buffer[0] == '#') {
				// %# evaluates to number of args in batch file
				//   (after adjusting for SHIFT)
				for (n = 0; bframe[bn].Argv[n+bframe[bn].Argv_Offset] != NULL; n++)
					;
				sprintf(buffer,"%u",(n > 0) ? n - 1 : 0);
				var = buffer;
#endif
			    }
			}

			// check for an environment variable
			if ((var == NULL) && ((var = envget(buffer,0)) == NULL)) {

#ifdef COMPAT_4DOS
			    // not a batch or env var; check for 4DOS internal
			    var = buffer;

			    if (stricmp(var,"?") == 0) {
				// exit code of last external program
				sprintf(var,"%u",error_level);
			    } else if (stricmp(var,VAR_FG_COLOR) == 0) {
				get_attribute(&i,&n);
				sprintf(var,"%s %s %s",((i & 0x08) ? BRIGHT : NULLSTR),((i & 0x80) ? BLINK : NULLSTR),colors[i&0x7]);
				var = skipspace(var);
			    } else if (stricmp(var,VAR_BG_COLOR) == 0) {
				get_attribute(&i,&n);
				sprintf(var,"%s",colors[(i>>4)&0x7]);
			    } else if (stricmp(var,VAR_COLUMNS) == 0)
				sprintf(var,"%u",screencols());
			    else if (stricmp(var,VAR_ROWS) == 0)
				sprintf(var,"%u",screenrows()+1);
			    else if (stricmp(var,VAR_DOSVER) == 0) {
				// DOS version number
				sprintf(var,"%u.%u",_osmajor,_osminor);
			    } else if (stricmp(var,VAR_CPU) == 0) {
				sprintf(var,"%u",get_cpu());
			    } else if (stricmp(var,VAR_NDP) == 0) {
				sprintf(var,"%u",get_ndp());
			    } else if (stricmp(var,VAR_SHELL) == 0) {
				// shell level
				sprintf(var,"%u",0);
			    } else if (stricmp(var,VAR_CWD) == 0) {
				// current working directory
				var = gcdir(NULL);
			    } else if (stricmp(var,VAR_CWDS) == 0) {
				// cwd w/backslash guaranteed
				if ((var = gcdir(NULL)) != NULL)
					mkdirname(var,NULLSTR);
			    } else if (stricmp(var,VAR_CWP) == 0) {
				// current working directory with no drive
				if ((var = gcdir(NULL)) != NULL)
					var += 2;
			    } else if (stricmp(var,VAR_CWPS) == 0) {
				// cwd with no drive w/backslash guaranteed
				if ((var = gcdir(NULL)) != NULL) {
					var += 2;
					mkdirname(var,NULLSTR);
				}
			    } else if (stricmp(var,VAR_DISK) == 0) {
				// current disk
				if ((var = gcdir(NULL)) != NULL)
					var[1] = '\0';
			    } else if (stricmp(var,VAR_TIME) == 0) {
				// system time
				var = gtime();
			    } else if (stricmp(var,VAR_DATE) == 0) {
				// system date
				_dos_getdate(&d_date);
				d_date.year -= 1900;
				// replace leading space with a 0
				if (*(var = date_fmt(d_date.month,d_date.day,d_date.year)) == ' ')
					*var = '0';
			    } else if (stricmp(var,VAR_DOW) == 0) {
				// get the day of week (Mon, Tue, etc.)
				sscanf(gdate(),"%s",var);
			    } else
				var = NULL;	// unknown variable
#endif
			}
		}

		// insert the variable
		if (var != NULL) {

			if ((strlen(start_line) + strlen(var)) >= MAXARGSIZ)
				return (error(ERROR_BATPROC_COMMAND_TOO_LONG,NULL));
			strins(line,var);

#ifdef COMPAT_4DOS
			// kludge to allow alias expansion when variable is
			//  first arg on command line
			if ((recurse_flag == 0) && (line == start_line) && (alias_expand(start_line) != 0))
				return ERROR_EXIT;
#endif
		}
	}
}


// collapse escape characters
void pascal escape_chars(register char *line)
{
#ifdef COMPAT_4DOS
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
#endif
}


// print the command history, read it from a file, or clear it
int hist(int argc, char **argv)
{
	return 0;
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
#ifdef COMPAT_4DOS
				if (flag_4dos) {
					if (*line == cfgdos.escapechar)
						line++;
					if (!*line) {
						error(ERROR_BATPROC_NO_CLOSE_QUOTE,NULL);
						return BADQUOTES;
					}
				}
#endif
			}

		} else {

#ifdef COMPAT_4DOS
			// skip escaped characters
			if ((flag_4dos) && (*line == cfgdos.escapechar))
				line++;
			else
#endif
			if (search == NULL) {
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
// SYSCMDS.C - System commands for BATPROC
//   Copyright (c) 1990  Rex C. Conn  All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <bios.h>
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
#include <string.h>

#include "batproc.h"


static char *pascal label_name(char *);
static int pascal do_global(char *, char *, int);


extern jmp_buf env;
extern char *i_cmd_name;

#ifdef COMPAT_4DOS
static char dirstack[DIRSTACKSIZE];	// PUSHD/POPD storage area
#endif


// exiting BATPROC is strictly VERBOTEN!
int bye(int argc, char **argv)
{
	return ERROR_EXIT;
}


// print version number
int ver(int argc, char **argv)
{
	qprintf(STDOUT,"\nDOS %u.%u\n",_osmajor,_osminor);

	return 0;
}


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
	char dirname[CMDBUFSIZ];

	// expand the directory name to support things like "cd ..."
	copy_filename(dirname,dir);
	if ((ptr = mkfname(dirname)) == NULL)
		return ERROR_EXIT;

	return ((chdir(ptr) == -1) ? error(_doserrno,dir) : 0);
}


// create directory
int md(int argc, register char **argv)
{
	register int rval = 0;

	if (argc == 1)
		return (usage(MD_USAGE));

	while (*(++argv) != NULL) {
		if (mkdir(*argv) == -1)
			rval = error(_doserrno,*argv);
	}

	return rval;
}


#ifdef COMPAT_4DOS

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


// Display the directory stack created by PUSHD
int dirs(int argc, char **argv)
{
	if (*dirstack == '\0')
		return (error(ERROR_BATPROC_DIR_STACK_EMPTY,NULL));

	qputs(STDOUT,dirstack);

	return 0;
}

#endif


// remove directory
int rd(int argc, register char **argv)
{
	register int fval;
	int found, rval = 0;
	char source[CMDBUFSIZ];
	struct find_t dir;

	if (argc == 1)
		return (usage(RD_USAGE));

	while (*(++argv) != NULL) {

		for (fval = FIND_FIRST, found = 0; (find_file(fval,*argv,0x10,&dir,source) != NULL); fval = FIND_NEXT) {

			// target must be a directory & not ".." or "."
			if (((dir.attrib & _A_SUBDIR) == 0) || (*dir.name == '.'))
				continue;

			found++;

			if (rmdir(source) == -1)
				rval = error(_doserrno,source);
		}

		if ((fval == FIND_NEXT) && (found == 0))
			rval = error(ERROR_ACCESS_DENIED,*argv);
	}

	return rval;
}


// read a disk label
int pascal getlabel(register char *arg)
{
	register char *lptr;

	if ((lptr = label_name(arg)) == NULL)
		return ERROR_EXIT;

	qprintf(STDOUT,VOLUME_LABEL,toupper(*arg),lptr);

	return 0;
}


// call DOS to get the volume label
char *pascal label_name(register char *arg)
{
	static char volume_name[12];
	register int rval;
	struct {
		char flag;
		char reserved[5];
		char attribute;
		char drive;
		char filename[11];
		char unused[25];
	} volume;

	if ((arg = gcdir(arg)) == NULL)
		return NULL;

	// with MS-DOS, we have to use the extended FCB calls to get the
	//   volume label in its proper format (because people put all sorts
	//   of odd characters into the label, including multiple '.'s

	memmove(&volume,"\xFF\x0\x0\x0\x0\x0\x8\x0???????????",20);
	volume.drive = (char)(toupper(*arg) - 64);

_asm {
	mov	ah,0x1A 		; set the DTA
	lea	dx,volume
	int	0x21

	mov	ah,0x11 		; read the volume label
	lea	dx,volume
	int	0x21
	xor	ah,ah
	mov	rval,ax
}

	sprintf(volume_name,"%.11s",((rval != 0) ? UNLABELED : volume.filename));

	return volume_name;
}


// return the current volume name(s)
int volume(int argc, register char **argv)
{
	register int rval = 0;

	// if no arguments, return the label for the default disk
	if (argc == 1) {
		argv[1] = gcdir(NULL);
		argv[2] = NULL;
	}

	while (*(++argv) != NULL) {
		if (getlabel(*argv) != 0)
			rval = ERROR_EXIT;
		else
			crlf();
	}

	return rval;
}


// return or set the path in the environment
int path(int argc, register char **argv)
{
	register char *ptr;

	// if no args, display the current PATH
	if (argc == 1) {
		qputslf(STDOUT,((ptr = envget(*argv,0)) == NULL) ? NO_PATH : ptr - 5);
		return 0;
	}

	// check for null path spec
	if (stricmp(argv[1],";") == 0)
		argv[1][0] = '\0';
	else if (argv[1][0] != '=')     // kludge for "PATH\COMM"
		strins(argv[1],"=");

	// add argument to environment (in upper case for Netware bug)
	return (addenv(strupr(*argv),0));
}


// set the DOS command-line prompt
int prompt(int argc, char **argv)
{
	return (addenv(*argv,0));
}


// enable/disable ^C trapping
int setbreak(register int argc, register char **argv)
{
	if (argc == 1) {	// inquiring about break status
_asm {
		mov	ax,0x3300
		int	0x21
		mov	argc,dx
}
		qprintf(STDOUT,BREAK_IS,i_cmd_name,((argc) ? ON : OFF));
	} else {		// setting new break status
		argc = 0;
		if (argv[1][0] == '=')
			(argv[1])++;
		if (stricmp(argv[1],ON) == 0)
			argc++;
		else if (stricmp(argv[1],OFF) != 0)
			return (usage(BREAK_USAGE));
_asm {
		mov	ax,0x3301
		mov	dx,argc
		int	0x21
}
	}

	return 0;
}


// enable/disable disk verify
int verify(register int argc, register char **argv)
{
	if (argc == 1) {		// inquiring about verify status
_asm {
		mov	ah,0x54
		int	0x21
		xor	ah,ah
		mov	argc,ax
}
		qprintf(STDOUT,VERIFY_IS,i_cmd_name,((argc) ? ON : OFF));
	} else {			// setting new verify status
		argc = 0;
		if (stricmp(argv[1],ON) == 0)
			argc = 1;
		else if (stricmp(argv[1],OFF) != 0)
			return (usage(VERIFY_USAGE));
_asm {
		mov	ax,argc
		mov	ah,0x2E 	; set VERIFY state
		xor	dx,dx
		int	0x21
}
	}

	return 0;
}


#ifdef COMPAT_4DOS

// display RAM statistics
//   NOTE - Under DOS, this function is dependent upon the BIOS routines
//   Under OS/2, it only returns the free memory & env/alias/history stats
int memory(int argc, char **argv)
{
	return 0;
}


// Set the screen colors (using ANSI)
int color(int argc, register char **argv)
{
	extern ANSI_COLORS colors[];
	int attrib = -1;

	// scan the input line for the colors requested
	set_colors(argv+1,&attrib);
	if (attrib < 0)
		return (usage(COLOR_USAGE));

	qprintf(STDOUT,"\033[0;%s%s%u;%um",((attrib & 0x08) ? "1;" : NULLSTR),((attrib & 0x80) ? "5;" : NULLSTR),colors[attrib & 0x07].ansi,(colors[(attrib & 0x70) >> 4].ansi) + 10);

	return 0;
}


// display the disk status (total size, total used, & total free)
int df(int argc, register char **argv)
{
	return 0;
}


// Display/Change the BATPROC variables
int setdos(int argc, register char **argv)
{
	extern BUILTIN commands[];

	register char *arg;

	if (argc == 1) {	// display current default parameters
		qprintf(STDOUT,SETDOS_IS,cfgdos.ansi,cfgdos.compound,cfgdos.escapechar,
			cfgdos.minhist,cfgdos.inputmode,cfgdos.editmode,cfgdos.noclobber,
			((cfgdos.rows == 0) ? screenrows() + 1 : cfgdos.rows),
			cfgdos.cursor_start,cfgdos.cursor_end,
			cfgdos.ucase,cfgdos.batecho,cfgdos.switch_char);
	} else {

		while (*(++argv) != NULL) {

			arg = *argv + 2;
			argc = ((*arg == '\0') ? 0 : switch_arg(*argv,"ACEHILMNRSUVW"));

			if (argc == -1)
				return ERROR_EXIT;
			if (argc == 0)
				return (error(ERROR_INVALID_PARAMETER,*argv));

			if (argc & 1)		// A - force ANSI usage
				cfgdos.ansi = (char)((*arg == '0') ? 0 : 1);
			else if (argc & 2)	// C - compound command separator
				cfgdos.compound = *arg;
			else if (argc & 4)	// E - escape character
				cfgdos.escapechar = *arg;
			else if (argc & 8)	// H - minimum history save length
				cfgdos.minhist = atoi(arg);
			else if (argc & 0x10) {
				// I - disable or enable internal cmds
				if ((argc = findcmd(arg+1,1)) < 0)
					return (error(ERROR_BATPROC_UNKNOWN_COMMAND,arg+1));
				else
					commands[argc].enabled = (char)((*arg == '-') ? 0 : 1);
			} else if (argc & 0x20)
				// L - if 1, use INT 21 0Ah for input
				cfgdos.inputmode = (char)((*arg == '0') ? 0 : 1);
			else if (argc & 0x40)
				// M - edit mode (overstrike or insert)
				cfgdos.editmode = (char)((*arg == '0') ? 0 : 1);
			else if (argc & 0x80)
				// N - noclobber (output redirection)
				cfgdos.noclobber = (char)((*arg == '0') ? 0 : 1);
			else if (argc & 0x100)	// R - number of screen rows
				cfgdos.rows = atoi(arg);
			else if (argc & 0x200) {
				// S - cursor shape
				sscanf(arg,"%u%*1s%u",&cfgdos.cursor_start,&cfgdos.cursor_end);
				// force cursor shape change (for BAT files)
				setcursor(0);
			} else if (argc & 0x400)
				// U - upper case filename display
				cfgdos.ucase = (char)((*arg == '0') ? 0 : 1);
			else if (argc & 0x800)	// V - batch command echoing
				cfgdos.batecho = (char)((*arg == '0') ? 0 : 1);
			else if (argc & 0x1000) {
				// W - change switch char
				if (isalnum(*arg))
					return (error(ERROR_INVALID_PARAMETER,*argv));
				else {
					// set the switch character
_asm {
					mov	  ax,0x3701
					mov	  dx,[arg]
					int	  0x21
}
					cfgdos.switch_char = (char)get_switchar();
				}
			}
		}
	}

	return 0;
}


// Turn 4DOS disk, EMS, or XMS swapping on or off
int swap(int argc, char **argv)
{
	return 0;
}


// enable/disable command logging, or rename the log file
int log(int argc, char **argv)
{
	return 0;
}


// perform a command on the current directory & its subdirectories
int global(int argc, register char **argv)
{
	register char *ptr;
	char savedir[68], curdir[MAXFILENAME+1];
	char *cmdline;
	int switch_val = 0, rval;

	// save the original directory
	if ((ptr = gcdir(NULL)) == NULL)
		return ERROR_EXIT;

	strcpy(savedir,ptr);
	strcpy(curdir,ptr);

	do {
		if (*(++argv) == NULL)
			return (usage(GLOBAL_USAGE));

		// check for I(gnore) and Q(uiet) switches
		if ((argc = switch_arg(*argv,"IQ")) == -1)
			return ERROR_EXIT;
		switch_val |= argc;
	} while (argc > 0);

	cmdline = strcpy(alloca(strlen(*argv)+1),*argv);
	rval = do_global(cmdline,curdir,switch_val);

	// restore original directory
	if (setjmp(env) == -1)
		return CTRLC;
	chdir(savedir);

	return rval;
}


// pass the original command line and the current directory & execute it
static int pascal do_global(char *cmd, register char *curdir, int global_flags)
{
	register unsigned int i;
	unsigned int entries = 0;
	int rval;
	char *ptr;
	DIR_ENTRY huge *files = 0L;

	// check for /Q(uiet) switch
	if ((global_flags & 2) == 0)
		qprintf(STDOUT,GLOBAL_DIR,filecase(curdir));

	if (chdir(curdir) == -1)
		return (error(_doserrno,curdir));

	// execute the command; if a non-zero result, test for /I(gnore) switch
	if (((rval = command(cmd)) == CTRLC) || ((rval != 0) && ((global_flags & 1) == 0)))
		return rval;
	rval = 0;

	if (setjmp(env) == -1) {
		dosfree((char far *)files);
		return CTRLC;
	}

	// make new directory search name
	mkdirname(curdir,WILD_FILE);

	// search for all subdirectories in this (sub)directory
	if (srch_dir(0x10,curdir,(DIR_ENTRY huge **)&files,&entries,(DIRFLAGS_DIRS_ONLY | DIRFLAGS_RECURSE)) != 0)
		return ERROR_EXIT;

	if (files != 0L) {

		// point to filename (wildcard *.*)
		ptr = strchr(curdir,'*');

		// process directory tree recursively
		for (i = 0; (i < entries); i++) {

			sprintf(ptr,"%Fs",files[i].file_name);
			rval = do_global(cmd,curdir,global_flags);

			if (setjmp(env) == -1)
				rval = CTRLC;

			if (rval != 0)
				break;
		}

		dosfree((char far *)files);
		files = 0L;
	}

	return rval;
}


// "except" the specified files from a command
int except(int argc, char **argv)
{
	register int fval;
	register char *arg;
	char exceptlist[CMDBUFSIZ], fname[CMDBUFSIZ], *cmdlist;
	int rval = 0, attrib;
	struct find_t dir;

	if ((argv[1][0] != '(') || ((arg = strchr(argv[1],')')) == NULL) || (*(cmdlist = skipspace(arg+1)) == '\0'))
		return (usage(EXCEPT_USAGE));

	// terminate at the close paren ')'
	*arg = '\0';

	// save the exception list & do var expansion
	if (var_expand(strcpy(exceptlist,(argv[1])+1),1) != 0)
		return ERROR_EXIT;

	if (setjmp(env) == -1)
		rval = CTRLC;
	else {
		// hide away the "excepted" files
		for (argc = 0; (rval == 0) && (arg = ntharg(exceptlist,argc)) != NULL; argc++) {

			for (fval = FIND_FIRST; (find_file(fval,arg,0x10,&dir,fname) != NULL); fval = FIND_NEXT) {
				if ((rval = _dos_getfileattr(fname,&attrib)) == 0) {
					// can't set directory attribute!
					attrib &= (_A_SUBDIR ^ 0xFFFF);
					rval = _dos_setfileattr(fname,(attrib | _A_HIDDEN));
				}
				if (rval != 0) {
					error(rval,fname);
					break;
				}
			}
		}

		if (rval == 0)
			rval = command(cmdlist);

		if (setjmp(env) == -1)
			rval = CTRLC;

	}

	for (argc = 0; (arg = ntharg(exceptlist,argc)) != NULL; ) {

		// unhide all of the "excepted" files
		for (fval = FIND_FIRST; (find_file(fval,arg,0x117,&dir,fname) != NULL); fval = FIND_NEXT) {
			if (_dos_getfileattr(fname,&attrib) == 0) {
				// can't set directory attribute!
				attrib &= (_A_SUBDIR ^ 0xFFFF);
				_dos_setfileattr(fname,(attrib & (_A_HIDDEN ^ 0xFF)));
			}
		}
		argc++;
	}

	return rval;
}


// select the files for a command
int select(int argc, char **argv)
{
	return 0;
}


// display a file to the screen
int list(int argc, char **argv)
{
	return 0;
}


// Stopwatch - display # of seconds between calls
int timer(int argc, char **argv)
{
	return 0;
}

#endif


// return the current date in the format "Mon  Jan 1, 1990"
char *pascal gdate(void)
{
	extern char *daytbl[], *montbl[];
	static char str_date[18];
	struct dosdate_t d_date;

	_dos_getdate(&d_date);
	sprintf(str_date,"%s  %s %u, %4u",daytbl[(int)d_date.dayofweek],montbl[(int)d_date.month-1],(int)d_date.day,d_date.year);

	return str_date;
}


// return the current time as a string in the format "12:45:07"
char *pascal gtime(void)
{
	static char str_time[9];
	struct dostime_t d_time;

	_dos_gettime(&d_time);

	// get the time format for the default country
	getcountry();
	sprintf(str_time,"%02u%c%02u%c%02u",d_time.hour,country_info.szTimeSeparator[0],d_time.minute,country_info.szTimeSeparator[0],d_time.second);

	return str_time;
}


static char scandef[] = "%u%*1s%u%*1s%u";

// set new system date
int setdate(int argc, char **argv)
{
	extern char *dateformat[];

	unsigned int day, month, year;
	char buf[12];
	struct dosdate_t d_date;

	// get the date format for the default country
	getcountry();

	if (argc > 1) {
		// date already in command line, so don't ask for it
		sprintf(buf,"%.10s",argv[1]);
		goto got_date;
	}

	// display current date & time
	qprintf(STDOUT,"%s  %s",gdate(),gtime());

	for (;;) {

		qprintf(STDOUT,NEW_DATE,dateformat[country_info.fsDateFmt]);
		if (egets(buf,10,DATA) == 0)
			return 0;
got_date:
		year = month = day = 0;
		switch (country_info.fsDateFmt) {
		case 0: 	// USA
			sscanf(buf,scandef,&month,&day,&year);
			break;
		case 1: 	// Europe
			sscanf(buf,scandef,&day,&month,&year);
			break;
		default:	// Japan
			sscanf(buf,scandef,&year,&month,&day);
		}

		if ((d_date.year = year) < 200)
			d_date.year += 1900;
		d_date.month = (unsigned char)month;
		d_date.day = (unsigned char)day;
		if (_dos_setdate(&d_date) == 0)
			break;

		error(ERROR_BATPROC_INVALID_DATE,buf);
	}

	return 0;
}


// set new system time
int settime(int argc, char **argv)
{
	unsigned int hours, minutes, seconds;
	char buf[12], *am_pm;
	struct dostime_t d_time;

	if (argc > 1) {
		// time already in command line, so don't ask again
		sprintf(buf,"%.10s",argv[1]);
		goto got_time;
	}

	// display current date & time
	qprintf(STDOUT,"%s  %s",gdate(),gtime());

	for (;;) {

		qputs(STDOUT,NEW_TIME);
		if (egets(buf,10,DATA) == 0)
			return 0;	// quit or no change

got_time:
		hours = minutes = seconds = 0;
		sscanf(buf,scandef,&hours,&minutes,&seconds);

		// check for AM/PM syntax
		if ((am_pm = strpbrk(strupr(buf),"AP")) != NULL) {
			if ((hours == 12) && (*am_pm == 'A'))
				hours -= 12;
			else if ((*am_pm == 'P') && (hours < 12))
				hours += 12;
		}

		d_time.hour = (unsigned char)hours;
		d_time.minute = (unsigned char)minutes;
		d_time.second = (unsigned char)seconds;
		d_time.hsecond = 0;
		if (_dos_settime(&d_time) == 0)
			break;

		error(ERROR_BATPROC_INVALID_TIME,buf);
	}

	return 0;
}


// display or set the code page (only for DOS 3.3+ and OS/2)
int chcp(int argc, char **argv)
{
	register int rval = 0, cp;

	// CHCP only supported in MS-DOS 3.3 and above
	if ((_osmajor <= 3) && (_osminor < 3))
		return (error(ERROR_BATPROC_INVALID_DOS_VER,NULL));

	if (argc == 1) {
		// display current code page
_asm {
		mov	ax,0x6601
		int	0x21
		jc	error_exit
		xor	ax,ax
		mov	cp,bx
error_exit:
		mov	rval,ax
}
		if (rval)
			rval = error(rval,NULL);
		else
			qprintf(STDOUT,CODE_PAGE,cp);
	} else {
		cp = atoi(argv[1]);
_asm {
		mov	ax,0x6602
		mov	bx,cp
		int	0x21
		jc	error_exit2
		xor	ax,ax
error_exit2:
		mov	rval,ax
}
		if (rval)
			rval = error(rval,argv[1]);

	}

	return rval;
}


// Change stdin, stdout, stderr to a new device
int ctty(int argc, register char **argv)
{
	extern int ctty_flag;
	register int fd;

	// only allowed one argument, and it must be a device
	if (argc != 2)
		return (usage(CTTY_USAGE));

	if ((fd = sopen(*argv,(O_RDWR | O_TEXT),SH_DENYNO)) < 0)
		return (error(_doserrno,*argv));

	// if not console, set ctty_flag so we don't try to use egets()
	ctty_flag = stricmp(fname_part(*argv),"CON");

	// duplicate file handle into stdin, stdout, & stderr, & close original
	dup_handle(fd,0);
	dup2(0,1);
	dup2(1,2);

	return 0;
}


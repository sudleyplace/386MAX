// MISC.C - Miscellaneous support routines for BATPROC
//   (c) 1990  Rex C. Conn  All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <ctype.h>
#include <direct.h>
#include <dos.h>
#include <fcntl.h>
#include <io.h>
#include <setjmp.h>
#include <share.h>
#include <stdarg.h>
#include <string.h>

#include "batproc.h"


static int pascal wild_cmp(char *, char *);


extern jmp_buf env;

COUNTRYINFO country_info;		// international format info


// disable null pointer checking
int _nullcheck(void)
{
	return 0;
}


// flush buffers & reset disk drives
void disk_reset(void)
{
_asm {
	mov	ah,0x0D 		; reset the disks
	int	21h
}
}


// free DOS memory block
void pascal dosfree(char far *fptr)
{
	register int rval;

	if ((fptr != 0L) && ((rval = _dos_freemem(FP_SEG(fptr))) != 0))
		error(rval,NULL);
}


// allocate DOS memory
char far *pascal dosmalloc(register unsigned int *size)
{
	register unsigned int memsize;
	unsigned int segment;

	memsize = (*size + 0xF) >> 4;

	if (_dos_allocmem(memsize,&segment) != 0) {

		memsize = segment;

		// if size >= 0xFFF0, return the biggest piece we can get
		if ((*size < 0xFFF0) || (memsize < 0xFF) || (_dos_allocmem(memsize,&segment) != 0))
			segment = 0;
		else
			*size = (memsize << 4);
	}

	return (char far *)MAKEP(segment,0);
}


// grow or shrink DOS memory block
char far *pascal dosrealloc(char far *fptr, long size)
{
	unsigned int paragraphs, maxsize;

	// round paragraph size up
	paragraphs = (unsigned int)((size + 0xF) >> 4);

	if (_dos_setblock(paragraphs,FP_SEG(fptr),&maxsize) != 0) {
		dosfree(fptr);		// couldn't realloc
		fptr = 0L;
	}

	return fptr;
}


// check arg for the switch arguments - return 0 if not a switch, -1 if
//   a bad switch argument, else ORed the matching arguments (1 2 4 8 etc.)
int pascal switch_arg(register char *arg, register char *match)
{
	int i, rval = 0;
	char *ptr;

	if ((arg != NULL) && (*arg == cfgdos.switch_char)) {

		for (i = 1; (isalpha(arg[i])); i++) {

			if ((ptr = strchr(match,toupper(arg[i]))) == NULL) {
				error(ERROR_INVALID_PARAMETER,arg);
				return -1;
			} else
				rval |= (1 << (int)(ptr - match));
		}
	}

	return rval;
}


// test for delimiter (" \t,;")
int pascal isdelim(register char c)
{
	return ((c == ' ') || (c == '\t') || (c == ',') || (c == ';'));
}


// skip past leading white space and return pointer to first non-space char
char *pascal skipspace(register char *str)
{
	while (isspace(*str))
		str++;

	return str;
}


// remove whitespace on both sides of the token
void pascal collapse_whitespace(char *line, char *token)
{
	register char *arg;

	// collapse any whitespace around the token
	for (arg = line; ;) {

		if (((arg = scan(arg,token,QUOTES)) == BADQUOTES) || (*arg == '\0'))
			return;

		// collapse leading & trailing whitespace
		while (isspace(arg[-1])) {
			arg--;
			strcpy(arg,arg+1);
		}

		arg++;
		while (isspace(*arg))
			strcpy(arg,arg+1);

	}
}


// check to see if user wants filenames in upper case
char *pascal filecase(register char *filename)
{
	return ((cfgdos.ucase == 0) ? strlwr(filename) : strupr(filename));
}


// get current directory, with leading drive specifier (or NULL if error)
char *pascal gcdir(char *drive)
{
	static char current[68];
	int disk, rval;

	disk = gcdisk(drive);
	sprintf(current,"%c:\\",disk+64);

	rval = (unsigned int)(current + 3);

_asm {
	push	si
	mov	ah,0x47
	mov	dx,disk
	mov	si,rval
	int	0x21
	jc	error_exit
	xor	ax,ax
error_exit:
	mov	rval,ax
	pop	si
}

	if (rval) {
		// bad drive - format error message & return NULL
		current[2] = '\0';
		error(rval,current);
		return NULL;
	}

	return (filecase(current));
}


// return the specified (or default) drive as 1=A, 2=B, etc.
int pascal gcdisk(register char *drive)
{
	extern int cur_disk;		// default disk drive

	if ((drive != NULL) && (drive[1] == ':'))
		return (toupper(*drive) - 64);

	return cur_disk;
}


// return the path stripped of the filename (or NULL if no path)
char *pascal path_part(register char *s)
{
	static char buffer[68];

	sprintf(buffer,"%.67s",s);

	// search path backwards for beginning of filename
	for (s = buffer + strlen(buffer); (--s >= buffer); ) {

		// take care of arguments like "d:.." & "..\.."
		if ((*s == '.') && (s[1] == '.'))
			return buffer;

		if ((*s == '\\') || (*s == '/') || (*s == ':')) {
			s[1] = '\0';
			return buffer;
		}
	}

	return NULL;
}


// return the filename stripped of path & disk spec
char *pascal fname_part(register char *s)
{
	static char buf[14];
	register char *ptr;

	if ((*s) && (s[1] == ':'))      // skip disk specifier
		s += 2;

	// skip the path spec
	for (ptr = s; *s; s++) {
		if ((*s == '\\') || (*s == '/'))
			ptr = s + 1;
		else if ((*s == '.') && (s[1] == '.'))    // skip ".."
			ptr += 2;
	}

	// only allow 8 chars for filename and 3 for extension
	sscanf(ptr,"%8[^.]%*[^.]%4s",buf,buf+9);

	return (strcat(buf,buf+9));
}


// return the file extension only
char *pascal ext_part(register char *s)
{
	static char buf[5];

	// make sure extension is for filename, not directory name
	if (((s = strrchr(s,'.')) == NULL) || (strpbrk(s,"\\/:") != NULL))
		return NULL;

	sprintf(buf,"%.4s",s);

	return buf;
}


// copy a filename, max of 79 characters
void pascal copy_filename(char *target, char *source)
{
	sprintf(target,"%.79s",source);
}


// make a file name from a directory name by appending '\' (if necessary)
//   and then appending the filename
void pascal mkdirname(register char *dname, register char *fname)
{
	if (strchr("/\\:",dname[strlen(dname)-1]) == NULL)
		strcat(dname,"\\");

	strcat(dname,fname_part(fname));
}


// make a full file name including disk drive & path
char *pascal mkfname(register char *fname)
{
	register char *ptr;
	char target[MAXFILENAME+1], *source, *curdir;

	if ((source = fname) == NULL)
		return NULL;

	// check for network server names (Novell Netware or Lan Manager)
	//   (like "\\server\blahblah" or "sys:blahblah")
	if (((fname[0] == '\\') && (fname[1] == '\\')) || ((fname[1] != '\0') && (strchr(fname+2,':') != NULL))) {

		// don't do anything if it's an oddball network name - just
		//   return the filename, shifted to upper or lower case
		return (filecase(fname));

	}

	// get the current drive, & save to the target
	if ((curdir = gcdir(fname)) == NULL)
		return NULL;

	// skip the disk spec for the default directory
	curdir = strcpy(target,curdir) + 3;

	// skip the disk specification
	if ((*fname) && (fname[1] == ':'))
		fname += 2;

	// if filespec defined from the root, delete the default pathname
	if ((*fname == '\\') || (*fname == '/')) {
		fname++;
		*curdir = '\0';
	}

	// handle Netware-like CD changes (..., ...., etc.)
	while ((ptr = strstr(fname,"...")) != NULL) {

		// make sure we're not over the max length
		if ((strlen(fname) + 2) >= MAXFILENAME) {
			error(ERROR_FILE_NOT_FOUND,fname);
			return NULL;
		}
		strins(ptr+2,"\\.");
	}

	while ((*fname) && (fname != NULL)) {

		// don't strip trailing \ in directory name
		if ((ptr = strpbrk(fname,"/\\")) != NULL) {
			if ((ptr[1] != '\0') || (ptr[-1] == '.'))
				*ptr = '\0';
			ptr++;
		}

		// handle references to parent directory ("..")
		if (stricmp(fname,"..") == 0) {

			// don't delete root directory!
			if ((fname = strrchr(curdir,'\\')) == NULL)
				fname = curdir;
			*fname = '\0';

		} else if (stricmp(fname,".") != 0) {

			// append the directory or filename to the target
			if (strchr("/\\:",target[strlen(target)-1]) == NULL)
				strcat(target,"\\");
			strncat(target,fname,MAXFILENAME-strlen(target));
			target [MAXFILENAME] = '\0';

		}

		fname = ptr;
	}

	// return expanded filename, shifted to upper or lower case
	// special DOS kludge to force proper filename size (i.e.,
	//   "123456789" -> "12345678")
	insert_path(source,fname_part(target),target);

	return (filecase(source));
}


// make a filename with the supplied path & filename
void pascal insert_path(register char *target, char *source, char *path)
{
	register char *ptr;

	strcpy(target,source);
	if ((ptr = path_part(path)) != NULL)
		strins(target,ptr);
}


// return non-zero if the specified file exists
int pascal is_file(char *fname)
{
	struct find_t dir;

	return ((int)find_file(FIND_FIRST,fname,0x107,&dir,NULL));
}


// returns 1 if it's a directory, 0 otherwise
int pascal is_dir(char *fname)
{
	register char *dptr;
	char dname[MAXFILENAME+1];
	struct find_t dir;

	// build a fully-qualified path name (& fixup Netware stuff)
	dptr = strcpy(dname,fname);
	if (mkfname(dptr) == NULL)
		return 0;

	// skip the drive spec
	dptr += 2;

	// "\", "/" and "." are assumed valid directories
	if (((*dptr == '\\') || (*dptr == '/') || (*dptr == '.')) && (dptr[1] == '\0'))
		return 1;

	// it can't be a directory if it has wildcards
	if (strpbrk(dptr,"*?") == NULL) {

		// remove a trailing "\" or "/"
		dptr += (strlen(dptr) - 1);
		if ((*dptr == '\\') || (*dptr == '/'))
			*dptr = '\0';

		// try searching for it & see if it exists
		//   (can't use _dos_getfileattr() because of Netware bug)
		if (_dos_findfirst(dname,0x17,&dir) == 0)
			return (dir.attrib & _A_SUBDIR);
	}

	return 0;
}


// check if "fname" is a character device
int pascal is_dev(char *fname)
{
	register int rval, fd;

	rval = strlen(fname) - 1;

	// strip a trailing colon
	if ((rval > 1) && (fname[rval] == ':'))
		fname[rval] = '\0';

	rval = 0;

	// try opening the device(?)
	if ((fd = sopen(fname_part(fname),(O_RDONLY | O_BINARY),SH_DENYNO)) >= 0) {

		rval = isatty(fd);
		close(fd);

	}

	return rval;
}


// Find the first or next matching file
//	fflag	Find First or Find Next flag
//	arg	filename to search for
//	attrib	search attribute to use (except hi byte)
//	dir	pointer to directory structure

char *pascal find_file(int fflag, char *arg, int attrib, struct find_t *dir, char *filename)
{
	register int rval, fval = fflag;

	// We have to get tricky here because 4DOS supports extended
	//   wildcards (for example: "*m*s*.*d*").
	do {

		if ((rval = (fval == FIND_FIRST) ? _dos_findfirst(arg,(attrib & 0xFF),dir) : _dos_findnext(dir)) != 0) {
			if ((attrib <= 0xFF) && (fflag == FIND_FIRST))
				error(rval,arg);
			return NULL;
		}
		fval = FIND_NEXT;

		// check unusual wildcard matches
	} while (wild_cmp(fname_part(arg),dir->name) != 0);

	if (filename == NULL)
		return (char *)-1;

	insert_path(filename,dir->name,arg);

	return (filecase(filename));
}


// Compare filenames for wildcard matches
//	*s  matches any collection of characters in the string
//	      up to (but not including) the s.
//	 ?  matches any single character in the other string.
//   [a-z]  will be a future enhancement
static int pascal wild_cmp(register char *wname, register char *fname)
{
#ifdef COMPAT_4DOS
	register int n;

	// skip the ".." and "." (will only match on *.*)
	while (*fname == '.')
		fname++;

	while (*wname) {

		if (*wname == '*') {

			// skip past * and advance fname until a match
			//   of the characters following the * is found.
			while ((*(++wname) == '*') || (*wname == '?'))
				;

			for (n = 0; (*fname) && (*fname != '.') && (*wname != '*') && (*wname != '?'); fname++) {

				if (toupper(*wname) != toupper(*fname)) {
					fname -= n;
					wname -= n;
					n = 0;
				} else {
					wname++;
					n++;
				}
			}

		} else if (*wname == '?') {

			// ? matches any single character
			if (*fname == '.')
				break;
			wname++;
			if (*fname)
				fname++;

		} else if (toupper(*wname) == toupper(*fname)) {
			wname++;
			fname++;
		} else if ((*wname == '.') && (*fname == '\0'))
			wname++;	// no extension
		else
			break;
	}

	return (*wname - *fname);
#else
	return 0;
#endif
}


// get the country code (for date formatting)
void getcountry(void)
{

_asm {
	mov	ax,0x3800
	lea	dx,country_info
	int	0x21
}

	// PC-DOS 2.0 & 2.1 don't support the extra fields
	if (_osmajor < 3) {
		country_info.szThousandsSeparator[0] = ',';
		country_info.szDateSeparator[0] = '-';
		country_info.szTimeSeparator[0] = ':';
	}
}


// return the date, formatted appropriately by country type
char *pascal date_fmt(register int month, int day, int year)
{
	static char date[10];
	register int i;

	getcountry();

	if (country_info.fsDateFmt == 1) {

		// Europe = dd-mm-yy
		i = day;			// swap day and month
		day = month;
		month = i;

	} else if (country_info.fsDateFmt == 2) {

		// Japan = yy-mm-dd
		i = month;			// swap everything!
		month = year;
		year = day;
		day = i;
	}

	sprintf(date,"%2u%c%02u%c%02u",month,country_info.szDateSeparator[0],day,country_info.szDateSeparator[0],year);

	return date;
}


// print a CR/LF pair to STDOUT
void crlf(void)
{
	qputc(STDOUT,'\n');
}


// honk the speaker (but shorter & more pleasantly than COMMAND.COM)
void honk(void)
{
	// flush the typeahead buffer
	while (kbhit())
		bios_key();

	DosBeep(440,2);
}


// get a keystroke from STDIN, with optional echoing & ^C checking
unsigned int pascal getkey(register int eflag)
{
	register unsigned int c;

	c = ((eflag == ECHO) ? getche() : getch());

	// The new keyboards return peculiar codes for separate cursor pad
	if ((c == 0) || ((c == 0xE0) && (kbhit())))
		c = getch() + 0x100;	// get extended scan code

	return c;
}


// return a yes/no answer
int pascal yesno(register char *s)
{
	register unsigned int c;

	qprintf(STDOUT,YES_NO,s);

	for (;;) {

		c = toupper(getkey(NO_ECHO));

		if (isprint(c)) {
			qputc(STDOUT,(char)c);
			if ((c == YES_CHAR) || (c == NO_CHAR))
				break;
			qputc(STDOUT,BS);
		}

		honk();
	}
	crlf();

	return c;
}


// format a long integer by inserting commas (or other character specified by
//   country_info.szThousandsSeparator)
char *pascal comma(unsigned long num)
{
	static char buf[12];
	register char *ptr;

	sprintf(buf,"%lu",num);

	for (ptr = buf + strlen(buf); ((ptr -= 3) > buf); )
		strins(ptr,country_info.szThousandsSeparator);

	return buf;
}


// insert a string inside another one
char *pascal strins(register char *str, char *insert_str)
{
	register unsigned int inslen;

	// length of insert string
	if ((inslen = strlen(insert_str)) > 0) {
		// move original
		memmove(str+inslen,str,(strlen(str)+1));
		// insert the new string into the hole
		memmove(str,insert_str,inslen);
	}

	return (str);
}


// map character to upper case (including foreign language chars)
int _cdecl toupper(register int c)
{
	if ((c >= 'a') && (c <= 'z'))
		return (c - 32);

	// PC-DOS 2 doesn't support this function!
	if ((c >= 0x80) && (_osmajor > 2)) {
_asm {
		mov	ax,c
		call	far ptr country_info.case_map_func
		xor	ah,ah
		mov	c,ax
}
	}

	return c;
}


// write a long line to STDOUT & check for screen paging
void pascal more(char *start, int col)
{
	register char *ptr;
	register int columns;

	columns = screencols();

	if (isatty(1)) {

		for (ptr = start; (*ptr != '\0'); ) {

			// count up column position
			incr_column(*ptr,&col);

			if ((col > columns) || (*ptr++ == '\n')) {
				write(STDOUT,start,(unsigned int)(ptr - start));
				_page_break();
				start = ptr;
				col = 0;
			}
		}
	}

	write(STDOUT,start,strlen(start));
	if (col == columns)
		_page_break();
	else
		_nxtrow();
}


#ifdef COMPAT_4DOS

// scan for screen colors
char *pascal set_colors(char **argv, int *attrib)
{
	extern ANSI_COLORS colors[];
	register int i, intense = 0;
	int foreground = -1, background = -1;

	for ( ; ; ) {

		if (strnicmp(first_arg(*argv),BRIGHT,3) == 0) {
			argv++;
			intense |= 0x08;	// set intensity bit
		} else if (strnicmp(first_arg(*argv),BLINK,3) == 0) {
			argv++;
			intense |= 0x80;	// set blinking bit
		} else
			break;
	}

	for (i = 0; (i <= 7); i++) {

		// check for foreground color match
		if (strnicmp(first_arg(*argv),colors[i].shade,3) == 0)
			foreground = intense + i;

		// check for background color match
		if (strnicmp(ntharg(*argv,2),colors[i].shade,3) == 0)
			background = i;

	}

	// if foreground & background colors are valid, set the attribute
	if ((foreground >= 0) && (background >= 0))
		*attrib = foreground + (background << 4);

	return argv[3];
}

#endif


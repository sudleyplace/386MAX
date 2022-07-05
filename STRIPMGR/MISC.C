//' $Header:   P:/PVCS/MAX/STRIPMGR/MISC.C_V   1.2   30 May 1997 12:21:20   BOB  $

// MISC.C - Miscellaneous support routines for STRIPMGR
//   Copyright (c) 1990-93  Rex C. Conn & Qualitas, Inc.  GNU General Public License version 3

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <ctype.h>
#include <direct.h>
#include <dos.h>
#include <fcntl.h>
#include <io.h>
#include <share.h>
#include <stdarg.h>
#include <string.h>

#include "stripmgr.h"


static int pascal wild_cmp(char *, char *);

extern int flag_4dos;
extern int Editfh;

// extern jmp_buf env;


// disable null pointer checking
int _nullcheck(void)
{
	return 0;
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
// Bits set in argmask indicate switches that have arguments.
int pascal switch_arg(register char *arg, register char *match, int argmask)
{
	int i, rval = 0;
	char *ptr;

	if ((arg != NULL) && (*arg == cfgdos.switch_char)) {

		for (i = 1; isalpha(arg[i]) || arg[i] == '?'; i++) {

			if ((ptr = strchr(match,toupper(arg[i]))) == NULL) {
				error(ERROR_INVALID_PARAMETER,arg);
				return -1;
			} else
				rval |= (1 << (int)(ptr - match));
			if (rval & argmask) break;
		}
	}

	return rval;
}


// Remove leading switch arguments from the line
// This needs to strip leading expressions like
// [devicehigh] /L:n,m;n2,m2 /S=devname
// [LH] /L:n,m;n2,m2 /S progname
// only up to the first = sign or the first non-switch, and
// [c:\qemm8\loadhi.sys] /foo=bar devname
// only up to the first non-switch
void pascal remove_switches( register char *arg, int nUpToEq )
{
	register char *end;

	while (arg != NULL) {

		end = skipspace(arg);

		if (*end == cfgdos.switch_char) {
			while ((!nUpToEq || *end != '=') && !isspace(*end))
				end++;
		}
		else	break;

		strcpy(arg,skipspace(end));
	}
}


// test for delimiter (" \t,;")
int pascal isdelim(register char c)
{
	return ((c == ' ') || (c == '\t') || (c == ',') || (c == ';'));
}


// skip past leading delimiters and return pointer to first non-delim char
char *pascal skipdelims(char *line, char *delims)
{
	for ( ; ((*line != '\0') && (strchr(delims,*line) != NULL)); line++)
		;

	return line;
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


// strip the specified trailing characters
void pascal strip_trailing(register char *arg, char *delims)
{
	register int i;

	for (i = strlen(arg); ((--i >= 0) && (strchr(delims,arg[i]) != NULL)); )
		arg[i] = '\0';
}


// get current directory, with leading drive specifier (or NULL if error)
char *pascal gcdir(char *drive_spec)
{
	static char current[68];
	register int disk;

	disk = gcdisk(drive_spec);

	if (_getdcwd(disk,current,64) == NULL) {
		sprintf(current,"%c:",disk+64);
		error(_doserrno,current);
		return NULL;
	}

	return (current);
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

	// check for Novell Netware server names
	//   (like "\\server\blahblah" or "sys:blahblah")
	if (((fname[0] == '\\') && (fname[1] == '\\')) || (strchr(fname+2,':') != NULL)) {

		// don't do anything if it's an oddball Novell name - just
		//   return the filename
		return (fname);

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
		if (strlen(fname) >= 78) {
			error(ERROR_FILE_NOT_FOUND,fname);
			return NULL;
		}
		strins(ptr+2,"\\.");
	}

	while ((*fname) && (fname != NULL)) {

		// don't strip trailing \ in directory name
		if ((ptr = strpbrk(fname,"/\\")) != NULL) {
			if (ptr[1] != '\0')
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
	return (strcpy(source,target));
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

	return ((int)(find_file(FIND_FIRST,fname,0x107,&dir,NULL) != NULL));
}


// returns 1 if it's a directory, 0 otherwise
int pascal is_dir(char *fname)
{
	register char *dptr;
	unsigned int attrib;
	char dname[MAXFILENAME+1];

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
		if (_dos_getfileattr(dname,(unsigned int *)&attrib) == 0)
			return (attrib & _A_SUBDIR);
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
	if ((fd = sopen(fname,(O_RDONLY | O_BINARY),SH_DENYNO)) >= 0) {

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

	return (filename);
}


// Compare filenames for wildcard matches
//	*s  matches any collection of characters in the string
//	      up to (but not including) the s.
//	 ?  matches any single character in the other string.
static int pascal wild_cmp(register char *wname, register char *fname)
{
	register int n;

	if (flag_4dos == 0)
		return 0;

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
}


// print a CR/LF pair to STDOUT
void crlf(void)
{
	qputc(STDOUT,'\n');
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

// Wrap string at column specified with subsequent lines indented
// We'll look backwards up to column / 6 characters for a good place
// to break (2 spaces).
void wrap_com(char *str, int column)
{
	char *lptr, *lastbrk;
	int lcount;

	lastbrk = NULL;
	for (lptr = str, lcount = 0; *lptr; lptr++, lcount++) {

	 if (*lptr == '\n') {
		lcount = 0;
		lastbrk = NULL;
		continue;
	 } // new line

	 if (!strncmp (lptr, "  ", 2)) lastbrk = lptr;

	 if (lcount >= column) {
		if (lastbrk && ((int) (lptr-lastbrk)) <= column / 6)
				lptr = lastbrk;
		strins (lptr, INDENT_STR);	// Start new line and indent it
		lcount = INDENT_COL;		// New position
		lptr += strlen(INDENT_STR);	// Skip over what we just added
		lastbrk = NULL;
	 } // time to wrap

	} // for ()

} // wrap_com()

// return a yes/no answer - if ExternOutput is available, call parent
int pascal yesno(char *fname,		// Name of file we're processing
		long lineoff,		// Byte offset of logical line
		char FARDATA *s1,	// Original line
		char FARDATA *s2,	// What to replace with (or NULL)
		char *fmt)		// Message format to use
{
	register unsigned int c;
	char	 buff[768];
	int	removing;

	removing = !(s2 && *s2);
	if (fmt == NULL)
		fmt = (removing ? REMOVE_MESSAGE : MODIFY_MESSAGE);

	if (Editfh != -1) {
	 if (fname) {
		qprintf (Editfh, "%s %c %lu\n%Fs\n", fname,
					removing ? 'r' : 'c', lineoff, s1);
		if (!removing) qprintf (Editfh, "%Fs\n", s2);
	 } // filename specified
	 return (YES_CHAR);
	} // /E file is open
	else if (ExternOutput != NULL) {

	 sprintf (buff, fmt, s1, s2);
	 strcat (buff, YES_NO_DLG);
	 wrap_com (buff, WRAP_COL);

	 c = (*ExternOutput) (CALLBACK_YESNO, (char _far *) buff);
	 c = toupper (c);	// toupper macro would call *ExternOutput twice
	 if (c == YES_CHAR) {
	  buff [strlen (buff) - strlen (YES_NO_DLG)] = '\0';
	  qprintf (STDOUT, buff);
	 }

	} // Using input/output callback
	else {

	 sprintf (buff, fmt, s1, s2);
	 strcat (buff, YES_NO);
	 wrap_com (buff, WRAP2_COL);
	 qprintf (STDOUT, buff);

	 for ( ; ; ) {

		// get the character - if printable, display it
		// if it's not a Y or N, backspace, beep & ask again
		c = toupper(getkey(NO_ECHO));

		if (isprint(c)) {
			qputc(STDOUT,(char)c);
			if ((c == YES_CHAR) || (c == NO_CHAR))
				break;
			qputc(STDOUT,BS);
		}
		qputc(STDERR,BELL);

	 } // for (;;)

	} // ExternOutput == NULL

	crlf();

	return c;
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


// FAR string compare
int pascal fstrcmp(char far *s1, char far *s2)
{
	long sn1, sn2;

	while (*s1) {

		// this kludge sorts numeric strings (i.e., 3 before 13)
		if (isdigit(*s1) && isdigit(*s2)) {

			sn1 = sn2 = 0L;

			do {
				sn1 = (sn1 * 10) + (*s1 - '0');
			} while (isdigit(*(++s1)));

			do {
				sn2 = (sn2 * 10) + (*s2 - '0');
			} while (isdigit(*(++s2)));

			if (sn1 != sn2)
				return ((sn1 > sn2) ? 1 : -1);

		} else {

			if (toupper(*s1) != toupper(*s2))
				break;
			s1++;
			s2++;
		}
	}

	return (*s1 - *s2);
}


// delete the specified piece of the file & reset to start point
int pascal rewrite_file(int fd, char *cmd, long read_offset, long write_offset)
{
	extern int bn;

	char buffer[514];
	long save_offset;
	int size;

	// adjust for current offset in batch file line
	if (bn >= 0)
		write_offset += bframe[bn].line_offset;

	if (cmd != NULL) {
		// write out a line to the file
		save_offset = lseek(fd,write_offset,SEEK_SET);
		qprintf(fd,"%s\r\n",cmd);
		write_offset = lseek(fd,0L,SEEK_CUR);
	}

	for (save_offset = write_offset; ; ) {

		// read the next block
		lseek(fd,read_offset,SEEK_SET);
		if ((size = read(fd,buffer,512)) <= 0) {
			// truncate the file
			chsize(fd,write_offset);
			// reset to original last write position
			lseek(fd,save_offset,SEEK_SET);
			return 0;
		}

		// save position for next read
		read_offset = lseek(fd,0L,SEEK_CUR);

		// restore next write position
		lseek(fd,write_offset,SEEK_SET);

		// write out the buffer
		if (write(fd,buffer,size) != size)
			return ERROR_EXIT;

		// save next write position
		write_offset = lseek(fd,0L,SEEK_CUR);
	}
}

int get_switchar(void)
{
	int	retval;

_asm {
	mov	ax,3700h
	int	21h
	cmp	al,0FFh 	; function supported?
	jne	got_switchar
	mov	dl,'/'          ; default to forward slash
got_switchar:
	xor	ah,ah
	mov	al,dl
	mov	retval,ax
}
	return	retval;
}


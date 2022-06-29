// FILECMDS.C - File maintenance routines for BATPROC
//   Copyright (c) 1988, 1989, 1990  Rex C. Conn   All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <dos.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <io.h>
#include <memory.h>
#include <setjmp.h>
#include <share.h>
#include <string.h>

#include "batproc.h"

#define CREATE 0
#define APPEND 1

#define DEVICE_SOURCE 0x01
#define DEVICE_TARGET 0x0100

#define ASCII_SOURCE 0x01
#define BINARY_SOURCE 0x02
#define ASCII_TARGET 0x0100
#define BINARY_TARGET 0x0200


static void pascal wildname(char *, char *, char *);
static int pascal filecopy(char *, char *, int, int, int, long *);

extern jmp_buf env;
extern int flag_4dos;

static char append_flag;	// appending a file flag


// copy or append file(s)
int copy(int argc, char **argv)
{
	register int fval;
	register char *arg;
	char cmdline[CMDBUFSIZ], source_name[CMDBUFSIZ];
	char *source = cmdline, *target_name = cmdline + 82, *target = cmdline + 164;
	char verify = 0, old_verify, query = 0, modified = 0, update = 0;
	char replace = 0, quiet = 0;
	int ascii_flag = 0, devflag = 0, rval;
	int mode = CREATE, files_copied = 0;
	long append_offset = 0L;
	struct find_t dir, t_dir;

	// build a new command line, parsing for switches
	for (*cmdline = '\0', argc = 0; ((arg = ntharg(argv[1],argc)) != NULL); argc++) {

		if ((fval = switch_arg(arg,"VPRMUQAB")) == -1)
			return ERROR_EXIT;	// invalid switch

		if (fval & 1)		// verify copy
			verify = 1;

#ifdef COMPAT_4DOS

		if (flag_4dos) {

		    if (fval & 2) {		// query before copying
			query = 1;
			quiet = 0;
		}

		    if (fval & 4)	// query before replacing
			replace = 1;

		    if (fval & 8)	// only copy if source archive bit set
			modified = 1;

		    if (fval & 0x10)	// only copy if source is newer
			update = 1;

		    if (fval & 0x20) {
			// don't echo the copy
			quiet = 1;
			query = 0;
		    }
		}
#endif

		if ((fval & 0x40) || (fval & 0x80)) {
			// ASCII (/A) or Binary (/B) switch
			// remove the leading switches
			if (*cmdline == '\0') {
				ascii_flag = ((switch_arg(arg,"AB") & 1) ? ASCII_SOURCE : BINARY_SOURCE);
				continue;
			}
		} else if (fval)
			continue;

		// collapse spaces around /A, /B, and append marks (+)
		if ((*arg != cfgdos.switch_char) && (*arg != '+') && (*cmdline) && (cmdline[strlen(cmdline)-1] != '+'))
			strcat(cmdline," ");
		strcat(cmdline,arg);

	}

	// abort if no file arguments
	if (*cmdline == '\0')
		return (usage(COPY_USAGE));

	// copy the processed command line onto the original command line
	strcpy(*argv,cmdline);

	// get the target name, or "*.*" for default name
	if ((arg = strrchr(*argv,' ')) != NULL) {

		copy_filename(target,first_arg(arg));

		// check for ASCII (/A) or Binary (/B) switches
		ascii_flag |= ((switch_arg(ntharg(arg,1),"AB") & 1) ? ASCII_TARGET : BINARY_TARGET);
		*arg = '\0';            // remove target from command line

		// check target for device name
		if (is_dev(target)) {

			// set "target is device" flag
			devflag = DEVICE_TARGET;

			// can't "replace" or "update" a device!
			replace = update = 0;
		}
	} else
		strcpy(target,WILD_FILE);

	if (verify) {
		// save original VERIFY status
_asm {
		mov	ah,054h
		int	21h
		mov	old_verify,al
		mov	ax,02E01h	; set VERIFY ON
		xor	dx,dx
		int	21h
}
	}

	// if target not a char device, build full filename
	if ((devflag & DEVICE_TARGET) == 0) {
		if (mkfname(target) == NULL)
			goto copy_abort;
		if (is_dir(target))
			mkdirname(target,WILD_FILE);
	}

	// check for appending, & strip the '+'
	for (append_flag = 0, arg = *argv; ((arg = strchr(arg,'+')) != NULL); ) {

		*arg++ = ' ';

		// default for appending files is ASCII
		if ((ascii_flag & BINARY_SOURCE) == 0)
			ascii_flag |= ASCII_SOURCE;

		// can't append to a device!
		if ((devflag & DEVICE_TARGET) == 0)
			append_flag = 1;
	}

	for (rval = argc = 0; ((arg = ntharg(*argv,argc)) != NULL); argc++) {

		copy_filename(source,arg);
		devflag &= DEVICE_TARGET;	// clear "source is device" flag

		if (is_dev(source))
			devflag |= DEVICE_SOURCE;
		else {
			// if source is not a device, make a full filename
			if (mkfname(source) == NULL)
				break;
			if (is_dir(source))
				mkdirname(source,WILD_FILE);
		}

		// check for trailing ASCII (/A) or Binary (/B) switches
		if ((fval = switch_arg(ntharg(*argv,argc+1),"AB")) > 0) {
			ascii_flag = ((ascii_flag & (BINARY_TARGET | ASCII_TARGET)) | ((fval == 1) ? ASCII_SOURCE : BINARY_SOURCE));
			argc++;
		}

		for (fval = FIND_FIRST; ; fval = FIND_NEXT) {

			// if it's a device, only look for it once
			if (devflag & DEVICE_SOURCE) {
				if (fval == FIND_NEXT)
					break;
				copy_filename(source_name,source);

			} else if (find_file(fval,source,0,&dir,source_name) == NULL)
				break;

			// clear overwrite query flag
			query &= 1;

			// don't copy unmodified files
			if ((modified) && ((dir.attrib & _A_ARCH) == 0))
				continue;

			wildname(target_name,target,source_name);

#ifdef COMPAT_4DOS
			// if update flag (/U), only copy the source if the
			//   target is older or doesn't exist
			// if replace flag (/R) prompt before overwriting
			//   existing file
			if ((update || replace) && (find_file(FIND_FIRST,target_name,0,&t_dir,NULL) != NULL)) {

				if (update) {
					if ((t_dir.wr_date > dir.wr_date) || ((t_dir.wr_date == dir.wr_date) && (t_dir.wr_time >= dir.wr_time)))
						continue;
				} else		// replace
					query |= 2;
			}
#endif

			// check for special conditions w/append
			if (stricmp(source_name,target_name) == 0) {

				if (mode == APPEND) {
					// check for "copy all.lst + *.lst"
					if (stricmp(first_arg(*argv),source_name) != 0)
						rval = error(ERROR_BATPROC_CONTENTS_LOST,source_name);
				}

				if (append_flag)
					goto next_copy;
			}

			if ((quiet == 0) || (query & 2)) {

				qprintf(STDOUT,"%s =>%s %s",source_name,(mode == CREATE) ? NULLSTR : ">",target_name);

#ifdef COMPAT_4DOS
				if (query) {
					if (query & 2) {
						// if querying for replacement, don't
						//   ask if appending!
						if (mode != APPEND) {
							if (yesno(REPLACE) != YES_CHAR)
								continue;
						} else
							crlf();
					} else if (yesno(NULLSTR) != YES_CHAR)
						continue;
				} else
#endif
					crlf();
			}

			if ((rval = filecopy(target_name,source_name,mode,devflag,ascii_flag,&append_offset)) != 0)
				goto copy_abort;

			if (setjmp(env) == -1) {
				rval = CTRLC;
				goto copy_abort;
			}

			files_copied++;
next_copy:

			// if target is unambiguous file, append next file(s)
			//   if appending to wildcard, use first target name
			if (strpbrk(target,"?*") == NULL) {
				if ((devflag & DEVICE_TARGET) == 0)
					append_flag = 1;
			} else if (append_flag)
				strcpy(target,target_name);
			if (append_flag)
				mode = APPEND;
		}
	}

copy_abort:
	if (setjmp(env) == -1)
		rval = CTRLC;

	if (verify) {		// reset VERIFY flag to original state
_asm {
		mov	ah,02Eh
		mov	al,old_verify
		xor	dx,dx
		int	21h
}
	}

	qprintf(STDOUT,FILES_COPIED,files_copied);

	return rval;
}


#ifdef COMPAT_4DOS

// rename (including across directories) or relocate files
int mv(int argc, register char **argv)
{
	register char *arg;
	int fval, moved_count = 0, rval, descflag, attrib;
	char cmdline[CMDBUFSIZ], source_name[CMDBUFSIZ], save_name[CMDBUFSIZ];
	char *source = cmdline, *target_name = cmdline + 82, *target = cmdline + 164;
	char query = 0, replace = 0, quiet = 0;
	struct find_t dir;

	append_flag = 0;

	// build a new command line, parsing for switches
	for (*cmdline = '\0', argc = 0; ((arg = ntharg(argv[1],argc)) != NULL); argc++) {

		if ((fval = switch_arg(arg,"PQR")) == -1)     // invalid switch
			return ERROR_EXIT;

		if (fval & 1) { 	// query before copying
			query = 1;
			quiet = 0;
		}

		if (fval & 2) { 	// don't echo the command
			quiet = 1;
			query = 0;
		}

		if (fval & 4)		// query before replacing (overwriting)
			replace = 1;

		if (fval)
			continue;

		// collapse switches
		if (*cmdline)
			strcat(cmdline," ");
		strcat(cmdline,arg);
	}

	// abort if no file arguments
	if (*cmdline == '\0')
		return (usage(MOVE_USAGE));

	// copy the processed command line onto the original command line
	strcpy(*argv,cmdline);

	// get the target name, or "*.*" for default name
	if ((arg = strrchr(*argv,' ')) != NULL) {
		copy_filename(target,first_arg(arg));
		*arg = '\0';            // remove target from command line
	} else
		strcpy(target,WILD_FILE);

	// can't move a file to a device!
	if (is_dev(target))
		return (error(ERROR_ACCESS_DENIED,target));

	if (mkfname(target) == NULL)
		return ERROR_EXIT;

	if (is_dir(target))
		mkdirname(target,WILD_FILE);
	else if (ntharg(*argv,1) != NULL) {
		// if > 1 source arg, target must be directory!
		return (error(ERROR_PATH_NOT_FOUND,target));
	}
	save_name[0] = '\0';

	for (rval = argc = 0; ((arg = ntharg(*argv,argc)) != NULL); argc++) {

		copy_filename(source,arg);
		if (mkfname(source) == NULL)
			return ERROR_EXIT;

		// get entire contents of subdirectory
		if (is_dir(source))
			mkdirname(source,WILD_FILE);

		// expand the wildcards
		for (fval = FIND_FIRST, descflag = 0; (find_file(fval,source,0,&dir,source_name) != NULL); fval = FIND_NEXT) {

			query &= 1;
			wildname(target_name,target,source_name);

			// if replace flag (/R), query before overwriting
			//   existing file
			if ((replace) && (_dos_getfileattr(source_name,&attrib) == 0))
				query |= 2;

			if ((quiet == 0) || (query & 2)) {
				qprintf(STDOUT,"%s -> %s",source_name,target_name);
				if (query) {
					if (yesno((query & 2) ? REPLACE : NULLSTR) != YES_CHAR)
						continue;
				} else
					crlf();
			}

			// prevent destructive moves like "mv *.* test.fil"
			if (stricmp(save_name,target_name) == 0)
				return (error(ERROR_BATPROC_CANT_CREATE,target_name));

			// try a simple rename first
			if (rename(source_name,target_name) != 0) {

				// rename didn't work; try a destructive copy
				rval = filecopy(target_name,source_name,CREATE,0,0,0L);

				// reset ^C handling
				if ((rval == CTRLC) || (setjmp(env) == -1))
					return CTRLC;

				if (rval != 0)
					continue;

				if (remove(source_name))
					rval = error(_doserrno,source_name);
			}

			moved_count++;
			strcpy(save_name,target_name);

		}
	}

	disk_reset();

	qprintf(STDOUT,FILES_MOVED,moved_count);

	return rval;
}

#endif


// expand a wildcard name
void pascal wildname(register char *target, register char *source, char *template)
{
	register char *ptr;

	if ((ptr = path_part(source)) != NULL) {
		strcpy(target,ptr);
		source += strlen(ptr);
		target += strlen(ptr);
	}

	template = fname_part(template);

	while (*source) {

		if (*source == '*') {
			// insert substitute chars
			while ((*template != '.') && (*template))
				*target++ = *template++;
			while ((*source != '.') && (*source))
				source++;
		} else if (*source == '?') {
			// single char substitution
			if ((*template != '.') && (*template))
				*target++ = *template++;
			source++;
		} else if (*source == '.') {
			while ((*template) && (*template++ != '.'))
				;
			*target++ = *source++;		// copy '.'
		} else {
			*target++ = *source++;
			if ((*template != '.') && (*template))
				template++;
		}
	}

	// strip trailing '.'
	if (target[-1] == '.')
		target--;
	*target = '\0';
}


// copy from the source to the target files
//   outname = target file name
//   inname = source file name
//   mode = CREATE or APPEND
//   devflag = (0x01 - source is device, 0x0100 = target is device)
//   ascii_flag
//   append_offset = current end offset in append file
int pascal filecopy(char *outname, char *inname, int mode, register int devflag, register int ascii_flag, long *append_offset)
{
	unsigned int buf_size, bytes_read, bytes_written;
	int rval, infile = 0, outfile = 0;
	char far *segptr, far *fptr;

	// check for same name
	if (stricmp(inname,outname) == 0)
		return (error(ERROR_BATPROC_DUP_COPY,inname));

	// request memory block (64K more or less)
	buf_size = 0xFFF0;
	if ((segptr = dosmalloc(&buf_size)) == 0L)
		return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));

	if (setjmp(env) == -1) {	// ^C trapping
		rval = CTRLC;
		goto filebye;
	}

	// open input file for read
	if ((rval = _dos_open(inname,(O_RDONLY | SH_COMPAT),&infile)) != 0) {
		rval = error(rval,inname);
		goto filebye;
	}

	// if we are appending, open an existing file, otherwise create or
	//   truncate target file
	if ((rval = ((mode == APPEND) ? _dos_open(outname,(O_RDWR | SH_COMPAT),&outfile) : _dos_creat(outname,_A_NORMAL,&outfile))) != 0) {
		// DOS returns an odd error if it couldn't create the file!
		if ((mode != APPEND) && (rval == 2))
			rval = ERROR_BATPROC_CANT_CREATE;
		rval = error(rval,outname);
		goto filebye;
	}

	// if source is a character device, it MUST be read in ASCII
	if (devflag & DEVICE_SOURCE)
		ascii_flag = ((ascii_flag & (ASCII_TARGET | BINARY_TARGET)) | ASCII_SOURCE);

	if (devflag & DEVICE_TARGET) {

		// can't append to device
		mode = CREATE;

		// char devices default to ASCII copy
		if ((ascii_flag & (BINARY_SOURCE | BINARY_TARGET)) == 0)
			ascii_flag = (ASCII_TARGET | ASCII_SOURCE);
		else {
			// set raw mode for binary copy
_asm {
			mov	ax,04400h
			mov	bx,outfile
			int	21h
			xor	dh,dh
			or	dl,020h
			mov	ax,04401h
			mov	bx,outfile
			int	21h
}
		}
	}

	// if source has type but target doesn't, set target to source type
	// if target has type but source doesn't, set source to target type
	if (ascii_flag == ASCII_SOURCE)
		ascii_flag |= ASCII_TARGET;
	else if (ascii_flag == BINARY_SOURCE)
		ascii_flag |= BINARY_TARGET;
	else if (ascii_flag == ASCII_TARGET)
		ascii_flag |= ASCII_SOURCE;
	else if (ascii_flag == BINARY_TARGET)
		ascii_flag |= BINARY_SOURCE;

	if (mode == APPEND) {

		// append at EOF of the target file (we have to kludge a bit
		//   here, because some files end in ^Z and some don't, & we
		//   may be in binary mode)

		if (ascii_flag & BINARY_TARGET)
			lseek(outfile,0L,SEEK_END);
		else if (*append_offset != 0L) {
			// continuing an append - move to saved EOF in target
			lseek(outfile,*append_offset,SEEK_SET);
		} else {

		    // We should only get here if the target is ASCII, and
		    //	 the same file as the first source.  Read the file
		    //	 until EOF or we find a ^Z

		    do {
			if ((rval = _dos_read(outfile,segptr,buf_size,&bytes_read)) != 0) {
				rval = error(rval,outname);
				goto filebye;
			}

			// search for a ^Z
			if ((fptr = _fmemchr(segptr,0x1A,bytes_read)) != NULL) {

				// backup to ^Z location
				*append_offset += (fptr - segptr);
				lseek(outfile,*append_offset,SEEK_SET);
				break;
			}

			*append_offset += bytes_read;

		    } while (bytes_read == buf_size);

		}
	}

	while (buf_size != 0) {

		if ((rval = _dos_read(infile,segptr,buf_size,&bytes_read)) != 0) {
			rval = error(rval,inname);
			break;
		}

		if (ascii_flag & ASCII_SOURCE) {
			// terminate the file copy at a ^Z
			if ((fptr = _fmemchr(segptr,0x1A,bytes_read)) != NULL) {
				bytes_read = (unsigned int)(fptr - segptr);
				buf_size = 0;
			}
		}

		if (bytes_read == 0)
			buf_size = 0;

		*append_offset += bytes_read;

		// if target is ASCII, add a ^Z at EOF
		if ((ascii_flag & ASCII_TARGET) && ((buf_size == 0) || ((bytes_read < buf_size) && ((devflag & DEVICE_SOURCE) == 0)))) {
			segptr[bytes_read] = 0x1A;
			bytes_read++;
		}

		if (bytes_read == 0)
			break;

		if ((rval = _dos_write(outfile,segptr,bytes_read,&bytes_written)) != 0) {
			rval = error(rval,outname);
			goto filebye;
		}

		if (bytes_read != bytes_written) {	// error in writing
			// if writing to a device, don't expect full blocks
			if ((devflag & DEVICE_TARGET) == 0)
				rval = error(ERROR_BATPROC_WRITE_ERROR,outname);
			goto filebye;
		}
	}

	if ((mode == CREATE) && (append_flag == 0) && (devflag == 0)) {
		// set the file date & time to the same as the source
		if (_dos_getftime(infile,&bytes_written,&bytes_read) == 0)
			_dos_setftime(outfile,bytes_written,bytes_read);
	}

filebye:
	dosfree(segptr);

	if (infile > 0)
		_dos_close(infile);
	if (outfile > 0) {
		_dos_close(outfile);

		// if an error writing to the output file, delete it
		if (rval)
			remove(outname);
	}

	return rval;
}


// rename files (including to different directories) or directories
int ren(int argc, register char **argv)
{
	char fname[80], source[80], target_name[80], target[CMDBUFSIZ];
	char *arg, query = 0, quiet = 0;
	int fval, descflag, rval = 0;
	struct find_t dir;

	// check for valid number of arguments
	if (argc < 3)
		return (usage(RENAME_USAGE));

	// last argument is the target
	strcpy(target,argv[--argc]);
	argv[argc][0] = '\0';           // remove the target

	for (argc = 0; ((arg = ntharg(argv[1],argc)) != NULL); argc++) {

#ifdef COMPAT_4DOS
		if (flag_4dos) {
		    // check for rename w/query or quiet mode
		    if ((fval = switch_arg(arg,"PQ")) == -1)
			    return ERROR_EXIT;

		    // query?
		    if (fval & 1) {
			    query = 1;
			    quiet = 0;
		    }

		    // quiet mode on?
		    if (fval & 2) {
			    quiet = 1;
			    query = 0;
		    }

		    if (fval)
			    continue;
		}
#endif
		copy_filename(fname,arg);

		for (fval = FIND_FIRST, descflag = 0; (find_file(fval,fname,0x10,&dir,source) != NULL); fval = FIND_NEXT) {

			// can't rename ".." or "."
			if (*dir.name == '.')
				continue;

			wildname(target_name,target,source);

			// nasty kludge to emulate COMMAND.COM stupid
			//   renaming convention
			if ((path_part(source) != NULL) && ((dir.attrib & _A_SUBDIR) == 0) && (path_part(target_name) == NULL))
				strins(target_name,path_part(source));

			if ((mkfname(source) == NULL) || (mkfname(target_name) == NULL))
				return ERROR_EXIT;

			if (is_dir(target_name)) {
				// destination is directory; create target name
				//   (unless we're renaming directories!)
				if (!is_dir(source))
					mkdirname(target_name,source);
			}

#ifdef COMPAT_4DOS
			if (quiet == 0) {

				qprintf(STDOUT,"%s -> %s",source,target_name);
				if (query) {
					if (yesno(NULLSTR) != YES_CHAR)
						continue;
				} else
					crlf();
			}
#endif

			if (rename(source,target_name) == -1) {
				// check if error is with source or target
				rval = error(_doserrno,((_doserrno == ERROR_ACCESS_DENIED) ? target_name : source));
			}
		}
	}

	disk_reset();

	return rval;
}


// Delete file(s)
int del(int argc, char **argv)
{
	register char *arg;
	register int i;
	int rval = 0, fval;
	char fname[CMDBUFSIZ], target[CMDBUFSIZ], query = 0, quiet = 0, del_all = 0;
	struct find_t dir;

	if (argc == 1)
		return (usage(DELETE_USAGE));

#ifdef COMPAT_4DOS
	// check for switches anywhere in the line
	for (argc = 0;	((arg = ntharg(argv[1],argc)) != NULL); argc++) {

		if ((i = switch_arg(arg,"PQY")) == -1)
			return ERROR_EXIT;

		if (i & 1)		// prompt before deleting the file
			query = 1;

		if (i & 2)		// don't display deleted files
			quiet = 1;

		if (i & 4)		// don't prompt "Are you sure?"
			del_all = 1;
	}
#endif

	for (argc = 0; ((arg = ntharg(argv[1],argc)) != NULL); argc++) {

#ifdef COMPAT_4DOS
		// skip a erase w/query switch
		if (switch_arg(arg,"PQY") > 0)
			continue;
#endif

		// build the target name
		copy_filename(fname,arg);

		// if it's a directory, append the "*.*" wildcard
		if (is_dir(fname))
			mkdirname(fname,WILD_FILE);

		if (mkfname(fname) == NULL)
			return ERROR_EXIT;

		// confirm before deleting an entire directory
		//   (filename & extension == wildcards only)
		arg = fname_part(fname);
		if ((query == 0) && (del_all == 0) && (arg[strspn(arg,"*?.")] == '\0')) {
			qprintf(STDOUT,"%s : ",fname);
			if (yesno(ARE_YOU_SURE) != YES_CHAR)
				continue;
		}

		for (fval = FIND_FIRST; (find_file(fval,fname,0x10,&dir,target) != NULL); fval = FIND_NEXT) {

#ifdef COMPAT_4DOS
			if (query) {
				qputs(STDOUT,DELETE_QUERY);
				if (yesno(target) != YES_CHAR)
					continue;
			} else if (quiet == 0)
				qprintf(STDOUT,DELETING_FILE,target);
#endif

			if (remove(target))
				rval = error(_doserrno,target);
		}
	}

	disk_reset();

	return rval;
}


#ifdef COMPAT_4DOS

// change file attributes (HIDDEN, SYSTEM, READ-ONLY, and ARCHIVE)
int attrib(int argc, register char **argv)
{
	register char *arg;
	int mode = 0x07, fval, rval = 0;
	unsigned int old_attrib;
	char source[CMDBUFSIZ];
	union {
		// file attribute structure
		unsigned char attribute;
		struct {
			unsigned rdonly : 1;
			unsigned hidden : 1;
			unsigned system : 1;
			unsigned reserved : 2;
			unsigned archive : 1;
		};
	} and_mask, or_mask;
	struct find_t dir;

	if (argc == 1)
		return (usage(ATTRIB_USAGE));

	and_mask.attribute = 0x27;	// can't set VOL or DIR attribute
	or_mask.attribute = 0;

	while ((arg = *(++argv)) != NULL) {

		// check for "subdirectories too" switch
		if ((fval = switch_arg(arg,"D")) == -1)
			return ERROR_EXIT;

		if (fval & 1) {
			mode |= 0x10;
			continue;
		}

		if (*arg == '-') {

			// remove attribute (clear OR and AND bits)
			while (*(++arg)) {
				switch (toupper(*arg)) {
				case 'A':
					or_mask.archive = and_mask.archive = 0;
					break;
				case 'H':
					or_mask.hidden = and_mask.hidden = 0;
					break;
				case 'R':
					or_mask.rdonly = and_mask.rdonly = 0;
					break;
				case 'S':
					or_mask.system = and_mask.system = 0;
					break;
				default:
					return (error(ERROR_INVALID_PARAMETER,arg));
				}
			}

		} else if (*arg == '+') {

			// add attribute (set OR bits)
			while (*(++arg)) {
				switch (toupper(*arg)) {
				case 'A':
					or_mask.archive = 1;
					break;
				case 'H':
					or_mask.hidden = 1;
					break;
				case 'R':
					or_mask.rdonly = 1;
					break;
				case 'S':
					or_mask.system = 1;
					break;
				default:
					return (error(ERROR_INVALID_PARAMETER,arg));
				}
			}
		} else {

			// change attributes
			for (fval = FIND_FIRST; (find_file(fval,*argv,mode,&dir,source) != NULL); fval = FIND_NEXT) {

				// skip "." and ".."
				if (*dir.name == '.')
					continue;

				old_attrib = (dir.attrib & 0x27);
				qputs(STDOUT,show_atts(old_attrib));
				dir.attrib = (unsigned char)((old_attrib & and_mask.attribute) | or_mask.attribute);
				qprintf(STDOUT," -> %s  %s\n",show_atts(dir.attrib),source);

				// check for a change; ignore if same
				if ((old_attrib != (unsigned int)dir.attrib) && ((argc = _dos_setfileattr(source,dir.attrib)) != 0))
					rval = error(argc,source);
			}
		}
	}

	return rval;
}

#endif


char *pascal show_atts(register int attribute)
{
	static char atts[5];

	strcpy(atts,"____");
	if (attribute & _A_RDONLY)
		atts[0] = 'R';
	if (attribute & _A_HIDDEN)
		atts[1] = 'H';
	if (attribute & _A_SYSTEM)
		atts[2] = 'S';
	if (attribute & _A_ARCH)
		atts[3] = 'A';
	return atts;
}


// display file(s) to stdout
int type(int argc, char **argv)
{
	extern unsigned int page_length;

	register int fval;
	register char *source;
	char buffer[256];
	int size, rval = 0, line_flag = 0, fd, col = 0;
	long row;
	struct find_t dir;

	if (argc == 1)
		return (usage(TYPE_USAGE));

	init_dir();		// clear row & page length vars

	for (argc = 0; ((source = ntharg(argv[1],argc)) != NULL); argc++) {

#ifdef COMPAT_4DOS
		if ((fval = switch_arg(source,"LP")) == -1)
			return ERROR_EXIT;

		if (fval & 1) { 	// print the line number
			col = 7;
			line_flag = 1;
		}

		if (fval & 2)		// pause after each page
			page_length = screenrows();

		if (fval)
			continue;
#endif

		// display specified files
		for (fval = FIND_FIRST; (find_file(fval,source,0x03,&dir,buffer) != NULL); fval = FIND_NEXT) {

			if (setjmp(env) == -1) {
				close(fd);
				return CTRLC;
			}

			if ((fd = sopen(buffer,(O_BINARY | O_RDONLY),SH_DENYWR)) < 0) {
				rval = error(_doserrno,buffer);
				continue;
			}

			// output the file to stdout
			if ((line_flag) || (page_length)) {
#ifdef COMPAT_4DOS
				for (row = 1; (getline(fd,buffer,255) > 0); row++) {
					if (line_flag)
						qprintf(STDOUT,"%4lu : ",row);
					more(buffer,col);
				}
#endif
			} else {
				while ((_dos_read(fd,buffer,255,&size) == 0) && (size != 0))
					_dos_write(STDOUT,buffer,size,&size);
			}
			close(fd);
		}
	}

	return rval;
}


#ifdef COMPAT_4DOS

// y reads the standard input to standard output, then invokes TYPE
//   to put one or more files to standard output
int y(int argc, char **argv)
{
	int bytes_read;
	char c;

	while ((_dos_read(STDIN,&c,1,&bytes_read) == 0) && (bytes_read > 0) && (c != 0x1A))
		qputc(STDOUT,c);

	return ((argc > 1) ? type(argc,argv) : 0);
}


// tee copies standard input to output & puts a copy in the specified file(s)
int tee(int argc, register char **argv)
{
	register int i;
	int mode, rval = 0, files = 0, bytes_read, fd[20];
	char c, *target;

	if (argc == 1)
		return (usage(TEE_USAGE));

	if (setjmp(env) == -1)
		rval = CTRLC;
	else {

		mode = (O_WRONLY | O_CREAT | O_BINARY | O_TRUNC);

		for (argc = 0; ((target = ntharg(argv[1],argc)) != NULL) && (files < 20); argc++, files++) {

			// check for "append" switch
			if ((i = switch_arg(target,"A")) == -1)
				return ERROR_EXIT;

			if (i == 1) {
				mode = (O_WRONLY | O_CREAT | O_BINARY | O_APPEND);
				continue;
			}

			if ((fd[files] = sopen(target,mode,SH_COMPAT,(S_IREAD | S_IWRITE))) < 0) {
				rval = error(_doserrno,target);
				goto tee_bye;
			}
		}

		while ((_dos_read(STDIN,&c,1,&bytes_read) == 0) && (bytes_read > 0) && (c != 0x1A)) {
			qputc(STDOUT,c);
			for (i = 0; i < files; i++)
				qputc(fd[i],c);
		}
	}

tee_bye:
	// close the output files (this looks a bit peculiar because we
	//   have to allow for a ^C during the close(), & still close all
	//   the output files)
	while (files > 0) {
		close(fd[files-1]);
		files--;
	}

	return rval;
}

#endif


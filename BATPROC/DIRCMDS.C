// DIRCMDS.C - Directory commands for BATPROC
//   Copyright (c) 1990  Rex C. Conn  All rights reserved

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
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


static int pascal do_dir(char *, char *);
#ifdef COMPAT_4DOS
static void pascal ssort(char huge *, unsigned int, unsigned int);
static int pascal files_cmp(DIR_ENTRY huge *, DIR_ENTRY huge *);
#endif

extern jmp_buf env;
extern int flag_4dos;		// if != 0, then 4DOS is active


// files and sizes within directory tree branch
static unsigned long tree_entries, tree_size;

unsigned int page_length;	// # of rows per page

static unsigned int row;	// current row number
static unsigned int mode;	// search attribute
static unsigned int columns;	// number of columns (varies by screen size)
static unsigned int dir_flags;	// DIR flags (VSORT, RECURSE, JUSTIFY, etc.)

#ifdef COMPAT_4DOS
char sortseq[7];		// directory sort order flags (DIR & SELECT)
#endif


// initialize directory variables
void init_dir(void)
{
	row = page_length = dir_flags = 0;
	columns = 1;
	mode = 0x10;
#ifdef COMPAT_4DOS
	sortseq[0] = '\0';
	tree_size = tree_entries = 0L;
#else
	dir_flags |= DIRFLAGS_JUSTIFY;
	dir_flags |= DIRFLAGS_UPPER_CASE;
#endif
}


// display a directory list
int dir(int argc, char **argv)
{
	register char *arg, *ptr;
	char fname[MAXARGSIZ];
	int n, rval = 0;

	init_dir();			// initialize the DIR global variables
	strcpy(fname,WILD_FILE);
	argc = 0;

	// parse the arg list for append args (*.com+*.exe+*.bat) and
	//   collapse any whitespace around the "+"
	collapse_whitespace(argv[1],"+");

	do {
		arg = ntharg(argv[1],argc++);
		if (*arg == cfgdos.switch_char) {

			// point past switch character
			while (*(++arg)) {

				switch (toupper(*arg)) {
#ifdef COMPAT_4DOS
				case '1':       // single column display
				case '2':       // 2 column display
				case '4':       // 4 column display
					columns = *arg - '0';
					break;
				case 'A':       // display attributes
					dir_flags |= DIRFLAGS_ATTS_ONLY;
					break;
				case 'C':       // display in upper case
					dir_flags |= DIRFLAGS_UPPER_CASE;
					break;
				case 'D':       // recursive dir scan
					dir_flags |= DIRFLAGS_RECURSE;
					break;
				case 'F':       // files only (no dirs)
					mode &= 0x7;
					break;
				case 'H':       // include hidden & system files
					mode |= 0x7;
					break;
				case 'J':       // DOS justify filenames
					dir_flags |= DIRFLAGS_JUSTIFY;
					break;
				case 'N':       // reset DIR defaults
					init_dir();
					break;
				case 'O':       // dir sort order
					sscanf(strlwr(arg+1),"%6[eirtuz]",sortseq);
					arg += strlen(sortseq);
					break;
#endif
				case 'P':       // pause on pages
					page_length = screenrows();
					break;
#ifdef COMPAT_4DOS
				case 'Q':       // no headers, details, or summaries
					dir_flags |= DIRFLAGS_NO_HEADER;
					break;
				case 'S':       // summaries only
					dir_flags |= DIRFLAGS_SUMMARY_ONLY;
					break;
				case 'V':       // vertical sort
					dir_flags |= DIRFLAGS_VSORT;
					break;
#endif
				case 'W':       // wide screen display
					columns = (screencols() / 16);
					break;
#ifdef COMPAT_4DOS
				case 'X':       // directories only
					dir_flags |= DIRFLAGS_DIRS_ONLY;
					break;
#endif
				default:
					return (error(ERROR_INVALID_PARAMETER,arg));
				}
			}

		} else if (arg != NULL) {

			// it must be a file or directory name
			strcpy(fname,arg);

			// KLUDGE for COMMAND.COM compatibility (DIR *.c /w)
			for (n = argc; ((ptr = ntharg(argv[1],n)) != NULL); n++) {
				// check for another file spec
				if (*ptr != cfgdos.switch_char)
					goto show_dir;
			}

		} else {

show_dir:
#ifdef COMPAT_4DOS
			// put a path on the first argument
			if (flag_4dos && (ptr = strchr(fname,'+')) != NULL) {
				// save the include list
				sprintf(fname+80,"%.174s",ptr);
				*ptr = '\0';
			}
#endif
			if (mkfname(fname) != NULL) {
#ifdef COMPAT_4DOS
				if (flag_4dos && ptr != NULL)
					strcat(fname,fname+80);
#endif
				rval = do_dir(fname,NULL);
			}
		}

	} while ((rval == 0) && (arg != NULL));

	return rval;
}


static int pascal do_dir(register char *current, char *filename)
{
	register unsigned int i;
	struct diskfree_t disk_stat;
	unsigned int j, k, n, entries = 0, last_entry, v_rows, v_offset;
	int rval = 0;
	unsigned long freebytes, total = 0L, cluster_size, t_entries, t_size;
	DIR_ENTRY huge *files = 0L;	// pointer to file array in DOS memory
	char *ptr;

	// trap ^C and clean up
	if (setjmp(env) == -1) {
		dosfree((char far *)files);
		return CTRLC;
	}

	// print the volume label (unless recursing or no header wanted)
	if (((dir_flags & DIRFLAGS_NO_HEADER) == 0) && (filename == NULL)) {
		_nxtrow();
		if (getlabel(current) != 0)
			return ERROR_EXIT;
		_nxtrow();
	}

	// get stats for specified (or default) drive
	if (_dos_getdiskfree(gcdisk(current),&disk_stat) != 0)
		return (error(ERROR_INVALID_DRIVE,current));
	freebytes = (long)(disk_stat.sectors_per_cluster * disk_stat.bytes_per_sector) * (long)(disk_stat.avail_clusters);
	cluster_size = (disk_stat.bytes_per_sector * disk_stat.sectors_per_cluster);

#ifdef COMPAT_4DOS
	// save the current tree size & entries for recursive display
	t_size = tree_size;
	t_entries = tree_entries;
#endif

	if (is_dir(current))
		mkdirname(current,WILD_FILE);

	// look for match
	if (include_list(mode,current,(DIR_ENTRY huge **)&files,&entries) != 0)
		return ERROR_EXIT;

	if (files != 0L) {

		if ((dir_flags & DIRFLAGS_NO_HEADER) == 0) {
			if (filename != NULL)
				_nxtrow();
			qprintf(STDOUT," %s  %s",DIRECTORY_OF,filecase(current));
			_nxtrow();
		}

		for (n = 0, last_entry = 0, v_rows = v_offset = 0; (n < entries); n++) {

#ifdef COMPAT_4DOS
			// check for vertical sort
			if (dir_flags & DIRFLAGS_VSORT) {

				// check for new page
				if (n >= last_entry) {

					// get the last entry for previous page
					v_offset = last_entry;

					// get last entry for this page
					if ((page_length == 0) || ((last_entry += (columns * (page_length - row))) > entries))
						last_entry = entries;

					v_rows = (((last_entry - v_offset) + (columns - 1)) / columns);
				}

				i = n - v_offset;
				k = (i % columns);
				i = ((i / columns) + (k * v_rows)) + v_offset;

				// we might have uneven columns on the last page!
				if (last_entry % columns) {
					j = (last_entry % columns);
					if (k > j)
						i -= (k - j);
				}

			} else
#endif
				i = n;

			// get file size rounded to cluster size
			total += ((files[i].file_size + (cluster_size - 1)) / cluster_size) * cluster_size;

#ifdef COMPAT_4DOS
			// summaries only?
			if (dir_flags & DIRFLAGS_SUMMARY_ONLY)
				continue;
#endif

			// COMMAND.COM (or CMD.EXE) formatting requested?
			if ((dir_flags & DIRFLAGS_JUSTIFY) && (files[i].file_name[0] != '.')) {

				// patch filename for DOS-type justification
				for (k = 0; (files[i].file_name[k] != '\0'); k++) {

					if (files[i].file_name[k] == '.') {

						// move extension & pad w/blanks
						_fmemmove(files[i].file_name+8,files[i].file_name+k,5);

						for ( ; (k < 9); k++)
							files[i].file_name[k] = ' ';
						break;
					}
				}
			}

			qprintf(STDOUT,"%-13Fs",files[i].file_name);

			if ((dir_flags & DIRFLAGS_NO_HEADER) == 0) {

				if (columns <= 2) {
					qprintf(STDOUT,(files[i].attribute & _A_SUBDIR) ? DIR_LABEL : "%8lu",files[i].file_size);
					qprintf(STDOUT,"  %s  ",date_fmt(files[i].fd.file_date.months,files[i].fd.file_date.days,files[i].fd.file_date.years));
					qprintf(STDOUT,((files[i].ft.f_time == 0) ? "     " : "%2u:%02u"),files[i].ft.file_time.hours, files[i].ft.file_time.minutes);
					if (columns == 1)
						qprintf(STDOUT," %Fs",((dir_flags & DIRFLAGS_ATTS_ONLY) ? (char far *)show_atts(files[i].attribute) : files[i].file_id));
#ifdef COMPAT_4DOS
				} else if (columns == 4) {
					// display file size in Kb, Mb, or Gb
					for (ptr = DIR_FILE_SIZE; ((files[i].file_size = ((files[i].file_size + 1023) / 1024)) > 999); ptr++)
						;
					qprintf(STDOUT,(files[i].attribute & _A_SUBDIR) ? " <D>" : "%3lu%c",files[i].file_size,*ptr);
#endif
				}
			}

			// if 2 or 4 column, or wide display, add spaces
			if (((n + 1) % columns) == 0)
				_nxtrow();
			else
				qputs(STDOUT,"   ");
		}

		if (n % columns)
			_nxtrow();
#ifdef COMPAT_4DOS
		tree_entries += entries;
		tree_size += total;
#endif
	}

	// print the directory totals
	if (((dir_flags & DIRFLAGS_NO_HEADER) == 0) && ((entries != 0) || ((dir_flags & DIRFLAGS_RECURSE) == 0))) {
		qprintf(STDOUT,DIR_BYTES_IN_FILES,comma(total),entries);
		_nxtrow();
		qprintf(STDOUT,DIR_BYTES_FREE,comma(freebytes));
		_nxtrow();
	}

	dosfree((char far *)files);

	files = 0L;

#ifdef COMPAT_4DOS

	// do a recursive directory search?
	if (dir_flags & DIRFLAGS_RECURSE) {

		// save & remove filename
		ptr = path_part(current);
		if (filename == NULL) {
			filename = current + strlen(ptr);
			filename = strcpy(alloca(strlen(filename)+1),filename);
		}

		insert_path(current,WILD_FILE,ptr);
		ptr = strchr(current,'*');

		entries = 0;

		// search for subdirectories
		if (srch_dir((mode | 0x10),current,(DIR_ENTRY huge **)&files,&entries,(dir_flags | DIRFLAGS_DIRS_ONLY)) != 0)
			return ERROR_EXIT;

		if (files != 0L) {

			for (i = 0; i < entries; i++) {
				// make directory name
				sprintf(ptr,"%Fs\\%s",files[i].file_name,filename);
				if ((rval = do_dir(current,filename)) != 0)
					break;
			}

			dosfree((char far *)files);
			files = 0L;
		}

		if ((setjmp(env) == -1) || (rval == CTRLC))
			return CTRLC;

		// if we've got some entries, print a subtotal
		if (((dir_flags & DIRFLAGS_NO_HEADER) == 0) && (tree_entries > t_entries)) {

			// display size of local tree branch
			t_entries = (tree_entries - t_entries);
			t_size = (tree_size - t_size);
			strcpy(ptr,filename);

			_nxtrow();
			qprintf(STDOUT,"   %s",current);
			_nxtrow();
			qputs(STDOUT,DIR_TOTAL);
			qprintf(STDOUT,DIR_BYTES_IN_FILES,comma(t_size),t_entries);
			_nxtrow();
		}
	}
#endif

	return rval;
}


// go to next row & check for pause on page full
void _nxtrow(void)
{
	crlf();
	_page_break();
}


void _page_break(void)
{
	if (++row == page_length) {
		row = 0;
		pause(1,NULL);
	}
}


#ifdef COMPAT_4DOS

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


// compare routine for file sort
static int pascal files_cmp(DIR_ENTRY huge *a, DIR_ENTRY huge *b)
{
	register int rval = 0, sortorder;
	char *ptr, far *fptr_a, far *fptr_b;

	// 'r' sort in reverse order
	sortorder = (strchr(sortseq,'r') != NULL);

	for (ptr = sortseq; ((*ptr) && (rval == 0)); ptr++) {

		if (*ptr == 'u')                // unsorted
			return 0;

		if (*ptr == 't') {              // sort by date / time

			if ((rval = (a->fd.f_date - b->fd.f_date)) == 0)
				rval = (a->ft.f_time < b->ft.f_time) ? -1 : (a->ft.f_time > b->ft.f_time);

		} else if (*ptr == 'e') {       // extension sort

			// sort current dir (.) & root dir (..) first
			for (fptr_a = a->file_name; (*fptr_a == '.'); fptr_a++)
				;
			for (fptr_b = b->file_name; (*fptr_b == '.'); fptr_b++)
				;

			// skip to extension
			for (; *fptr_a && (*fptr_a != '.'); fptr_a++)
				;
			for (; *fptr_b && (*fptr_b != '.'); fptr_b++)
				;

			rval = fstrcmp(fptr_a,fptr_b);

		} else if (*ptr == 'z') {       // sort by filesize
			rval = ((a->file_size < b->file_size) ? -1 : (a->file_size > b->file_size));

		} else if (*ptr == 'i')         // sort by description (ID)
			rval = fstrcmp(a->file_id,b->file_id);

	}

	if (rval == 0) {

		// sort directories first
		if ((rval = ((b->attribute & _A_SUBDIR) - (a->attribute & _A_SUBDIR))) == 0)
			rval = fstrcmp(a->file_name,b->file_name);

	}

	return (sortorder) ? -rval : rval;
}


// do a Shell sort on the directory (smaller & less stack than Quicksort)
static void pascal ssort(char huge *base, unsigned int entries, unsigned int width)
{
	register char tmp;
	register int k;
	unsigned int gap, i;
	long j;
	char huge *p1, huge *p2;

	for (gap = (entries >> 1); gap > 0; gap >>= 1) {

		for (i = gap; (i < entries); i++) {

			for (j = (i - gap); (j >= 0L); j -= gap) {

				p1 = base + (j * width);
				p2 = base + ((j + gap) * width);

				if (files_cmp((DIR_ENTRY huge *)p1,(DIR_ENTRY huge *)p2) <= 0)
					break;

				for (k = width; (--k >= 0);) {
					tmp = *p1;
					*p1++ = *p2;
					*p2++ = tmp;
				}
			}
		}
	}
}

#endif


// Process an "include list" and then scan the directory for matching entries
int pascal include_list(int attrib, register char *arg, DIR_ENTRY huge **files, unsigned int *entries)
{
	register char *list_ptr = NULL;
	char filename[CMDBUFSIZ], *list_first;
	int rval = 0;

	list_first = arg;

	do {

		// check filespec for include list args (*.com+*.exe+*.bat)
		if ((list_ptr = strchr(arg,'+')) != NULL) {
			*list_ptr = '\0';

			// only the first arg can have a path!
			if (path_part(list_ptr+1) != NULL) {
				rval = error(ERROR_BATPROC_BAD_SYNTAX,list_ptr+1);
				break;
			}
		}

		// add a path from first arg (if any)
		insert_path(filename,fname_part(arg),list_first);
		if (mkfname(filename) == NULL) {
			rval = ERROR_EXIT;
			break;
		}

		// look for directory & drive names
		// if it's a directory or disk, append wildcards
		if (is_dir(filename))
			mkdirname(filename,WILD_FILE);
		else {

			// if no extension specified, add a default one
			//   else if no filename, insert a wildcard filename
			arg = strrchr(filename,'\\') + 1;

			if (ext_part(arg) == NULL)
				strcat(filename,".*");
			else if (*arg == '.')
				strins(arg,"*");
		}

		if (srch_dir(attrib,filename,files,entries,dir_flags) != 0)
			return ERROR_EXIT;

		// restore the '+' for append lists
		if (list_ptr != NULL)
			*list_ptr++ = '+';

	} while ((arg = list_ptr) != NULL);

	if (rval != 0) {
		dosfree((char far *)*files);
		return ERROR_EXIT;
	}

#ifdef COMPAT_4DOS
	// get descriptions & sort the directory entries
	if ((flag_4dos) && (*files != 0L)) {

		if (sortseq[0] != 'u')
			ssort((char huge *)*files,*entries,sizeof(DIR_ENTRY));
	}
#endif

	return 0;
}


// Read the directory and set the pointer to the saved directory array
//	attrib - search attribute
//	arg - filename/directory to search
//	fptr - pointer to address of FILES array
//	entries - pointer to ENTRIES
//	flags - directories only, recursing, & upper case

int pascal srch_dir(int attrib, char *arg, DIR_ENTRY huge **hptr, register unsigned int *entries, int flags)
{
	register int fval;
	unsigned long size;
	DIR_ENTRY huge *files;
	struct find_t dir;		// MS-DOS directory structure

	files = *hptr;
	size = (((*entries % 128) ? 1 : 0) + (*entries / 128)) * (128 * sizeof(DIR_ENTRY));

	for (fval = FIND_FIRST; ; fval = FIND_NEXT) {

		// if error, no entries & no recursion, display error & bomb
		if (find_file(fval,arg,(attrib | 0x100),&dir,NULL) == NULL) {
			if ((*entries == 0) && ((flags & DIRFLAGS_RECURSE) == 0))
				error(ERROR_FILE_NOT_FOUND,arg);
			return 0;
		}

#ifdef COMPAT_4DOS
		// check for valid subdirectory entry (excluding "." & "..")
		if ((flags & DIRFLAGS_DIRS_ONLY) && (((dir.attrib & _A_SUBDIR) == 0) || (dir.name[0] == '.')))
			continue;
#endif

		// allocate the temporary DOS memory blocks
		if ((*entries % 128) == 0) {
			size += (sizeof(DIR_ENTRY) * 128);
			files = (DIR_ENTRY huge *)((files == 0L) ? dosmalloc((unsigned int *)&size) : dosrealloc((char far *)files,size));
		}

		// set original pointer to allow cleanup on ^C
		if ((*hptr = files) == 0L)
			return (error(ERROR_NOT_ENOUGH_MEMORY,NULL));

		// directories in upper, filenames in lower case (unless
		//   overridden with /C or SETDOS /U1)

		// Also, kludge around Netware 386 bug with subdirectory sizes
		if (dir.attrib & _A_SUBDIR)
			files[*entries].file_size = 0L;
		else {
			if ((flags & DIRFLAGS_UPPER_CASE) == 0)
				filecase(dir.name);
			files[*entries].file_size = dir.size;
		}

		files[*entries].fd.f_date = dir.wr_date + (80 << 9);
		files[*entries].ft.f_time = dir.wr_time;
		files[*entries].attribute = dir.attrib;

		// save the name
		_fmemmove(files[*entries].file_name,(char far *)dir.name,13);
		files[*entries].file_id = NULLSTR;

		(*entries)++;
	}
}


// attach descriptive labels to filenames
int describe(int argc, register char **argv)
{
	return 0;
}

